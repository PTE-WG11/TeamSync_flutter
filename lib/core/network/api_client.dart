import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// API 客户端配置
/// 对接本地 8801 端口后端服务
class ApiClient {
  // 本地开发使用 localhost
  static const String _defaultBaseUrl = 'http://localhost:8801/api';
  // static const String _defaultBaseUrl = 'http://ag.changfanai.com:8801/api/';

  static const String _envBaseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static String _normalizeBaseUrl(String url) {
    if (url.isEmpty) return url;
    return url.endsWith('/') ? url : '$url/';
  }

  static String get baseUrl {
    // 1. 优先使用编译时传入的环境变量
    if (_envBaseUrl.isNotEmpty) return _normalizeBaseUrl(_envBaseUrl);

    // 2. Web 环境特殊处理
    if (kIsWeb) {
      // 生产环境（Release模式）：默认使用相对路径 /api/，由 Nginx 代理转发
      // 这样可以适应同源部署，无需硬编码域名
      if (kReleaseMode) {
        return '/api/';
      }

      // 开发环境（Debug/Profile模式）：
      // 前端通常运行在随机端口，后端在固定端口（如 8000）
      // 尝试自动构建本地后端地址
      final base = Uri.base;
      final scheme = base.scheme.isEmpty ? 'http' : base.scheme;
      final host = base.host;
      if (host.isEmpty) return _normalizeBaseUrl(_defaultBaseUrl);
      return _normalizeBaseUrl('$scheme://$host:8801/api');
      // return _normalizeBaseUrl('$scheme://$host:8000/api');  // 打包修改-生产环境是8000
    }

    // 3. 移动端/桌面端默认使用配置的地址
    return _normalizeBaseUrl(_defaultBaseUrl);
  }

  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  
  late final Dio _dio;
  
  // 用于防止多个请求同时触发刷新token导致的重复刷新问题
  bool _isRefreshing = false;
  // 存储因token刷新而排队的请求
  final List<_QueuedRequest> _queuedRequests = [];
  
  Dio get dio => _dio;
  
  // 单例模式
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  
  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    
    // 添加拦截器
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // 添加认证 token
        final token = await _getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        if (kDebugMode) {
          debugPrint('[API Request] ${options.method} ${options.path}');
          debugPrint('[API Request] Data: ${options.data}');
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        if (kDebugMode) {
          debugPrint('[API Response] ${response.statusCode} ${response.requestOptions.path}');
          debugPrint('[API Response] Data: ${response.data}');
        }
        return handler.next(response);
      },
      onError: (error, handler) async {
        if (kDebugMode) {
          debugPrint('[API Error] ${error.response?.statusCode} ${error.requestOptions.path}');
          debugPrint('[API Error] Message: ${error.message}');
          debugPrint('[API Error] Response: ${error.response?.data}');
        }
        
        // 处理 401 未授权错误 - 尝试刷新 token
        // 注意：登录、注册、刷新 token 接口的 401 不应该触发刷新逻辑
        if (error.response?.statusCode == 401) {
          final path = error.requestOptions.path;
          
          // 跳过登录相关接口的 401 错误处理
          if (_isAuthEndpoint(path)) {
            return handler.next(error);
          }
          
          final errorData = error.response?.data;
          final errorMessage = errorData is Map<String, dynamic> 
              ? errorData['detail'] ?? errorData['message'] 
              : null;
          
          // 检查是否是 token 过期导致的 401
          if (_isTokenExpiredError(errorMessage)) {
            return await _handleTokenExpired(error, handler);
          }
        }
        
        return handler.next(error);
      },
    ));
  }
  
  /// 判断请求路径是否是认证相关端点（这些端点的 401 不应该触发 token 刷新）
  bool _isAuthEndpoint(String path) {
    final authEndpoints = [
      'auth/login',
      'auth/register',
      'auth/refresh',
      'auth/logout',
    ];
    return authEndpoints.any((endpoint) => path.contains(endpoint));
  }

  /// 判断错误是否是 token 过期导致的
  bool _isTokenExpiredError(String? errorMessage) {
    if (errorMessage == null) return true; // 默认认为是token问题
    final lowerMsg = errorMessage.toLowerCase();
    return lowerMsg.contains('token') || 
           lowerMsg.contains('令牌') ||
           lowerMsg.contains('invalid') ||
           lowerMsg.contains('expired') ||
           lowerMsg.contains('unauthorized');
  }
  
  /// 处理 token 过期
  Future<void> _handleTokenExpired(
    DioException error, 
    ErrorInterceptorHandler handler,
  ) async {
    final requestOptions = error.requestOptions;
    
    // 如果正在刷新 token，将请求加入队列等待
    if (_isRefreshing) {
      _queuedRequests.add(_QueuedRequest(
        requestOptions: requestOptions,
        handler: handler,
      ));
      return;
    }
    
    // 开始刷新 token
    _isRefreshing = true;
    
    try {
      final refreshSuccess = await _refreshToken();
      
      if (refreshSuccess) {
        // 刷新成功，重试当前请求
        final newToken = await _getToken();
        requestOptions.headers['Authorization'] = 'Bearer $newToken';
        
        final response = await _dio.fetch(requestOptions);
        handler.resolve(response);
        
        // 处理排队的请求
        await _processQueuedRequests();
      } else {
        // 刷新失败，清除登录状态并抛出错误
        await _handleRefreshFailed();
        handler.reject(error);
      }
    } catch (e) {
      // 刷新过程中发生错误
      await _handleRefreshFailed();
      handler.reject(error);
    } finally {
      _isRefreshing = false;
      _queuedRequests.clear();
    }
  }
  
  /// 刷新 token
  Future<bool> _refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString(_refreshTokenKey);
      
      if (refreshToken == null || refreshToken.isEmpty) {
        if (kDebugMode) {
          debugPrint('[Token Refresh] No refresh token found');
        }
        return false;
      }
      
      if (kDebugMode) {
        debugPrint('[Token Refresh] Attempting to refresh token...');
      }
      
      // 使用新的 dio 实例避免拦截器循环
      final refreshDio = Dio(BaseOptions(
        baseUrl: baseUrl,
        headers: {'Content-Type': 'application/json'},
      ));
      
      final response = await refreshDio.post(
        _normalizePath('auth/refresh/'),
        data: {'refresh': refreshToken},
      );
      
      final responseData = response.data;
      if (responseData == null) return false;
      
      final code = responseData['code'] as int?;
      if (code != 200 && code != 201) return false;
      
      final data = responseData['data'] as Map<String, dynamic>?;
      final newAccessToken = data?['access_token'] as String?;
      final newRefreshToken = data?['refresh_token'] as String?;
      
      if (newAccessToken == null || newAccessToken.isEmpty) {
        return false;
      }
      
      // 保存新的 token
      await prefs.setString(_tokenKey, newAccessToken);
      if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
        await prefs.setString(_refreshTokenKey, newRefreshToken);
      }
      
      if (kDebugMode) {
        debugPrint('[Token Refresh] Token refreshed successfully');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Token Refresh] Failed: $e');
      }
      return false;
    }
  }
  
  /// 处理刷新失败 - 清除登录状态
  Future<void> _handleRefreshFailed() async {
    if (kDebugMode) {
      debugPrint('[Token Refresh] Refresh failed, clearing auth state');
    }
    await clearToken();
    
    // 这里可以发送一个全局事件通知应用跳转到登录页
    // 或者通过路由观察者来处理
  }
  
  /// 处理排队的请求
  Future<void> _processQueuedRequests() async {
    final newToken = await _getToken();
    
    for (final queued in _queuedRequests) {
      try {
        queued.requestOptions.headers['Authorization'] = 'Bearer $newToken';
        final response = await _dio.fetch(queued.requestOptions);
        queued.handler.resolve(response);
      } catch (e) {
        queued.handler.reject(
          DioException(
            requestOptions: queued.requestOptions,
            error: e,
          ),
        );
      }
    }
    _queuedRequests.clear();
  }
  
  /// 获取 token
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }
  
  /// 设置 token
  Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }
  
  /// 设置 refresh token
  Future<void> setRefreshToken(String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_refreshTokenKey, refreshToken);
  }
  
  /// 清除 token
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
  }
  
  String _normalizePath(String path) {
    if (path.isEmpty) return path;
    return path.startsWith('/') ? path.substring(1) : path;
  }

  /// GET 请求
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        _normalizePath(path),
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }
  
  /// POST 请求
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        _normalizePath(path),
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }
  
  /// PUT 请求
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        _normalizePath(path),
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }
  
  /// PATCH 请求
  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.patch(
        _normalizePath(path),
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }
  
  /// DELETE 请求
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        _normalizePath(path),
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }
  
  /// 错误处理
  void _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        throw ApiException('请求超时，请稍后重试');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = _parseErrorMessage(error.response?.data);
        
        // 401 错误在这里已经被拦截器处理过了，这里处理其他错误
        if (statusCode == 401) {
          throw ApiException('登录已过期，请重新登录');
        }
        throw ApiException(message ?? '请求失败 (HTTP $statusCode)');
      case DioExceptionType.connectionError:
        throw ApiException('无法连接到服务器，请检查网络连接');
      default:
        throw ApiException(error.message ?? '未知错误');
    }
  }
  
  /// 解析错误消息
  String? _parseErrorMessage(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) {
      return data['message'] ?? data['detail'] ?? data['error'];
    }
    return data.toString();
  }
}

/// 排队的请求
class _QueuedRequest {
  final RequestOptions requestOptions;
  final ErrorInterceptorHandler handler;
  
  _QueuedRequest({
    required this.requestOptions,
    required this.handler,
  });
}

/// API 异常类
class ApiException implements Exception {
  final String message;
  
  ApiException(this.message);
  
  @override
  String toString() => message;
}

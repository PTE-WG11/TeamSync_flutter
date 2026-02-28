import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/repositories/auth_repository.dart';

/// 认证仓库实现
/// 对接真实后端 API (localhost:8801/api)
class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _apiClient;

  AuthRepositoryImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  @override
  Future<LoginResult> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post(
        '/auth/login/',
        data: {
          'username': username,
          'password': password,
        },
      );

      // 后端返回格式: {code, message, data: {access_token, refresh_token, expires_at, user}}
      final responseData = response.data;
      
      if (responseData == null) {
        throw Exception('登录失败：服务器返回空数据');
      }

      // 检查返回码
      final code = responseData['code'] as int?;
      if (code != 200) {
        final message = responseData['message'] as String? ?? '登录失败';
        throw Exception(message);
      }

      // 获取 data 字段
      final data = responseData['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('登录失败：服务器返回的数据为空');
      }

      // 保存 access token 到本地
      final accessToken = data['access_token'] as String?;
      if (accessToken != null) {
        await _apiClient.setToken(accessToken);
      }

      final userData = data['user'] as Map<String, dynamic>?;
      if (userData == null) {
        throw Exception('登录失败：服务器返回的用户数据为空');
      }

      return LoginResult(
        accessToken: accessToken ?? '',
        refreshToken: data['refresh_token'] as String? ?? '',
        user: _parseUserInfo(userData),
      );
    } catch (e) {
      throw Exception('登录失败: $e');
    }
  }

  @override
  Future<RegisterResult> register({
    required String username,
    required String email,
    required String password,
    String? teamName,
    String? joinType,
  }) async {
    try {
      final response = await _apiClient.post(
        '/auth/register/',
        data: {
          'username': username,
          'email': email,
          'password': password,
          if (teamName != null) 'team_name': teamName,
          if (joinType != null) 'join_type': joinType,
        },
      );

      // 后端返回格式: {code, message, data: {id, username, email, role, team_name, join_type}}
      final responseData = response.data;
      
      if (responseData == null) {
        throw Exception('注册失败：服务器返回空数据');
      }

      // 检查返回码
      final code = responseData['code'] as int?;
      if (code != null && code != 200 && code != 201) {
        final message = responseData['message'] as String? ?? '注册失败';
        throw Exception(message);
      }

      // 获取 data 字段
      final data = responseData['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('注册失败：服务器返回的数据为空');
      }

      return RegisterResult(
        id: data['id'] as int? ?? 0,
        username: data['username'] as String? ?? '',
        email: data['email'] as String? ?? '',
        role: data['role'] as String? ?? 'visitor',
        teamName: data['team_name'] as String?,
        joinType: data['join_type'] as String? ?? 'join',
      );
    } catch (e) {
      throw Exception('注册失败: $e');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _apiClient.post('/auth/logout/');
    } catch (e) {
      // 即使请求失败也清除本地 token
    } finally {
      await _apiClient.clearToken();
    }
  }

  @override
  Future<UserInfo> getCurrentUser() async {
    try {
      final response = await _apiClient.get('/auth/me/');
      
      // 后端返回格式: {code, message, data: user}
      final responseData = response.data;
      if (responseData == null) {
        throw Exception('获取用户信息失败：服务器返回空数据');
      }

      // 获取 data 字段（用户数据）
      final data = responseData['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('获取用户信息失败：服务器返回的数据为空');
      }

      return _parseUserInfo(data);
    } catch (e) {
      throw Exception('获取用户信息失败: $e');
    }
  }

  @override
  Future<TokenRefreshResult> refreshToken(String refreshToken) async {
    try {
      final response = await _apiClient.post(
        '/auth/refresh/',
        data: {'refresh': refreshToken},
      );

      // 后端返回格式: {code, message, data: {access_token, ...}}
      final responseData = response.data;
      if (responseData == null) {
        throw Exception('刷新 token 失败：服务器返回空数据');
      }

      // 获取 data 字段
      final data = responseData['data'] as Map<String, dynamic>?;
      
      final accessToken = data?['access_token'] as String?;
      if (accessToken != null) {
        await _apiClient.setToken(accessToken);
      }

      return TokenRefreshResult(
        accessToken: accessToken ?? '',
      );
    } catch (e) {
      throw Exception('刷新 token 失败: $e');
    }
  }

  @override
  Future<VisitorStatus> checkVisitorStatus() async {
    try {
      final response = await _apiClient.get('/auth/visitor/status/');
      
      final data = response.data;
      if (data == null) {
        return VisitorStatus(isVisitor: false);
      }

      return VisitorStatus(
        isVisitor: data['is_visitor'] as bool? ?? false,
        status: data['status'] as String?,
      );
    } catch (e) {
      return VisitorStatus(isVisitor: false);
    }
  }

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _apiClient.setToken(accessToken);
    await _apiClient.setRefreshToken(refreshToken);
  }
  
  @override
  Future<void> clearTokens() async {
    await _apiClient.clearToken();
  }

  @override
  Future<UserInfo> updateCurrentUser({
    String? username,
    String? email,
    String? avatar,
  }) async {
    try {
      final response = await _apiClient.patch(
        '/auth/me/update/',
        data: {
          if (username != null) 'username': username,
          if (email != null) 'email': email,
          if (avatar != null) 'avatar': avatar,
        },
      );

      final responseData = response.data;
      if (responseData == null) {
        throw Exception('更新用户信息失败：服务器返回空数据');
      }

      final code = responseData['code'] as int?;
      if (code != 200) {
        final message = responseData['message'] as String? ?? '更新失败';
        throw Exception(message);
      }

      final data = responseData['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('更新用户信息失败：服务器返回的数据为空');
      }

      return _parseUserInfo(data);
    } catch (e) {
      throw Exception('更新用户信息失败: $e');
    }
  }

  @override
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
    required String newPasswordConfirm,
  }) async {
    try {
      final response = await _apiClient.post(
        '/auth/me/password/',
        data: {
          'old_password': oldPassword,
          'new_password': newPassword,
          'new_password_confirm': newPasswordConfirm,
        },
      );

      final responseData = response.data;
      if (responseData == null) {
        throw Exception('修改密码失败：服务器返回空数据');
      }

      final code = responseData['code'] as int?;
      if (code != 200) {
        final message = responseData['message'] as String? ?? '修改密码失败';
        throw Exception(message);
      }
    } catch (e) {
      throw Exception('修改密码失败: $e');
    }
  }

  @override
  Future<AvatarUploadResult> uploadAvatar({
    required List<int> fileBytes,
    required String fileName,
    required String mimeType,
  }) async {
    try {
      // 创建 FormData
      final formData = FormData.fromMap({
        'avatar': MultipartFile.fromBytes(
          fileBytes,
          filename: fileName,
        ),
      });

      final response = await _apiClient.post(
        '/auth/me/avatar/upload/',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      final responseData = response.data;
      if (responseData == null) {
        throw Exception('上传头像失败：服务器返回空数据');
      }

      final code = responseData['code'] as int?;
      if (code != 200) {
        final message = responseData['message'] as String? ?? '上传头像失败';
        throw Exception(message);
      }

      final data = responseData['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('上传头像失败：服务器返回的数据为空');
      }

      final avatarUrl = data['avatar'] as String?;
      if (avatarUrl == null) {
        throw Exception('上传头像失败：服务器未返回头像地址');
      }

      final userData = data['user'] as Map<String, dynamic>?;
      if (userData == null) {
        throw Exception('上传头像失败：服务器未返回用户信息');
      }

      return AvatarUploadResult(
        avatarUrl: avatarUrl,
        user: _parseUserInfo(userData),
      );
    } catch (e) {
      throw Exception('上传头像失败: $e');
    }
  }

  /// 解析用户信息
  UserInfo _parseUserInfo(Map<String, dynamic> json) {
    // 解析团队信息（后端返回 team_id 和 team_name）
    TeamInfo? teamInfo;
    final teamId = json['team_id'] as int?;
    final teamName = json['team_name'] as String?;
    if (teamId != null && teamName != null) {
      teamInfo = TeamInfo(
        id: teamId,
        name: teamName,
      );
    }

    return UserInfo(
      id: json['id'] as int? ?? 0,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'visitor',
      avatar: json['avatar'] as String?,
      team: teamInfo,
    );
  }
}

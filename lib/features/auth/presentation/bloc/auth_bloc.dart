import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// 认证 BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userRoleKey = 'user_role';
  static const String _usernameKey = 'username';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';

  final AuthRepository _authRepository;

  AuthBloc({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepositoryImpl(),
        super(AuthInitial()) {
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthCheckRequested>(_onCheckRequested);
  }

  /// 处理登录请求
  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final result = await _authRepository.login(
        username: event.username,
        password: event.password,
      );

      final user = result.user;

      // 保存到本地存储
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, result.accessToken);
      await prefs.setString(_refreshTokenKey, result.refreshToken);
      
      // 同时保存到 ApiClient
      await _authRepository.saveTokens(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
      );
      await prefs.setString(_userIdKey, user.id.toString());
      await prefs.setString(_usernameKey, user.username);
      await prefs.setString(_userEmailKey, user.email);
      await prefs.setString(_userRoleKey, user.role);

      emit(AuthAuthenticated(
        userId: user.id.toString(),
        username: user.username,
        email: user.email,
        role: _parseRole(user.role),
      ));
    } catch (e) {
      emit(AuthError(message: '登录失败: $e'));
    }
  }

  /// 处理注册请求
  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final result = await _authRepository.register(
        username: event.username,
        email: event.email,
        password: event.password,
      );

      // 注册成功后，根据后端返回的角色状态判断
      // 如果是加入现有团队，则为访客状态
      if (result.isVisitor) {
        // 保存访客信息
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userIdKey, result.id.toString());
        await prefs.setString(_usernameKey, result.username);
        await prefs.setString(_userEmailKey, result.email);
        await prefs.setString(_userRoleKey, 'visitor');

        emit(AuthAuthenticated(
          userId: result.id.toString(),
          username: result.username,
          email: result.email,
          role: UserRole.visitor,
        ));
      } else {
        // 创建团队的情况，直接作为管理员登录
        // 需要再次登录获取 token
        emit(AuthError(message: '注册成功，请登录'));
      }
    } catch (e) {
      emit(AuthError(message: '注册失败: $e'));
    }
  }

  /// 处理登出请求
  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      await _authRepository.logout();
    } catch (e) {
      // 即使请求失败也继续清除本地存储
    }

    // 清除本地存储
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    // 清除 ApiClient 中的 token
    await _authRepository.clearTokens();

    emit(AuthUnauthenticated());
  }

  /// 检查登录状态
  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);

      if (token != null && token.isNotEmpty) {
        // 有 token，尝试获取当前用户信息
        try {
          final user = await _authRepository.getCurrentUser();
          
          // 更新本地存储
          await prefs.setString(_userIdKey, user.id.toString());
          await prefs.setString(_usernameKey, user.username);
          await prefs.setString(_userEmailKey, user.email);
          await prefs.setString(_userRoleKey, user.role);

          emit(AuthAuthenticated(
            userId: user.id.toString(),
            username: user.username,
            email: user.email,
            role: _parseRole(user.role),
          ));
        } catch (e) {
          // token 可能已过期，清除本地存储
          await prefs.clear();
          emit(AuthUnauthenticated());
        }
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }

  /// 解析角色字符串为枚举
  /// 后端返回的角色: super_admin, team_admin, member, visitor
  UserRole _parseRole(String role) {
    switch (role) {
      case 'super_admin':
        return UserRole.superAdmin;
      case 'team_admin':
        return UserRole.teamAdmin;
      case 'member':
        return UserRole.member;
      case 'visitor':
        return UserRole.visitor;
      default:
        // 默认作为成员处理，避免权限不足
        return UserRole.member;
    }
  }
}

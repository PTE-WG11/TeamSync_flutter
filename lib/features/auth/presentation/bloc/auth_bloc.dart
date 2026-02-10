import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// 认证 BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  static const String _tokenKey = 'auth_token';
  static const String _userRoleKey = 'user_role';
  static const String _usernameKey = 'username';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';

  AuthBloc() : super(AuthInitial()) {
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
      // TODO: 调用登录 API
      await Future.delayed(const Duration(seconds: 1));

      final username = event.username.trim().toLowerCase();
      late final AuthAuthenticated authState;

      // 模拟登录 - 测试账号
      switch (username) {
        case 'admin':
        case 'manager':
          // 团队管理员账号
          authState = const AuthAuthenticated(
            userId: 'admin_001',
            username: '张三',
            email: 'admin@teamsync.com',
            role: UserRole.teamAdmin,
          );
          break;
        case 'member':
        case 'user':
          // 团队成员账号
          authState = const AuthAuthenticated(
            userId: 'member_001',
            username: '李四',
            email: 'member@teamsync.com',
            role: UserRole.member,
          );
          break;
        case 'visitor':
          // 访客账号
          authState = AuthAuthenticated(
            userId: 'visitor_001',
            username: event.username,
            email: 'visitor@example.com',
            role: UserRole.visitor,
          );
          break;
        default:
          // 默认作为团队成员登录
          authState = AuthAuthenticated(
            userId: 'member_${username.hashCode}',
            username: event.username,
            email: '${username}@example.com',
            role: UserRole.member,
          );
      }

      // 保存到本地存储
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, 'mock_token_${authState.userId}');
      await prefs.setString(_userIdKey, authState.userId);
      await prefs.setString(_usernameKey, authState.username);
      await prefs.setString(_userEmailKey, authState.email);
      await prefs.setString(_userRoleKey, authState.role.name);

      emit(authState);
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
      // TODO: 调用注册 API
      await Future.delayed(const Duration(seconds: 1));

      // 注册成功后自动登录为访客状态
      final authState = AuthAuthenticated(
        userId: 'visitor_${DateTime.now().millisecondsSinceEpoch}',
        username: event.username,
        email: event.email,
        role: UserRole.visitor,
      );

      // 保存到本地存储
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, 'mock_token_${authState.userId}');
      await prefs.setString(_userIdKey, authState.userId);
      await prefs.setString(_usernameKey, authState.username);
      await prefs.setString(_userEmailKey, authState.email);
      await prefs.setString(_userRoleKey, authState.role.name);

      emit(authState);
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
      // 清除本地存储
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      await Future.delayed(const Duration(milliseconds: 500));
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(message: '登出失败: $e'));
    }
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

      if (token != null) {
        final userId = prefs.getString(_userIdKey) ?? '';
        final username = prefs.getString(_usernameKey) ?? '';
        final email = prefs.getString(_userEmailKey) ?? '';
        final roleName = prefs.getString(_userRoleKey) ?? UserRole.visitor.name;
        
        final role = UserRole.values.firstWhere(
          (e) => e.name == roleName,
          orElse: () => UserRole.visitor,
        );

        emit(AuthAuthenticated(
          userId: userId,
          username: username,
          email: email,
          role: role,
        ));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }
}

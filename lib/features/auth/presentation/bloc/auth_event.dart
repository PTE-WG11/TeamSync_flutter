part of 'auth_bloc.dart';

/// 认证事件基类
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// 登录请求
class AuthLoginRequested extends AuthEvent {
  final String username;
  final String password;
  final bool rememberMe;

  const AuthLoginRequested({
    required this.username,
    required this.password,
    this.rememberMe = false,
  });

  @override
  List<Object?> get props => [username, password, rememberMe];
}

/// 注册请求
class AuthRegisterRequested extends AuthEvent {
  final String username;
  final String email;
  final String password;

  const AuthRegisterRequested({
    required this.username,
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [username, email, password];
}

/// 登出请求
class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

/// 检查登录状态
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// 用户信息更新
class AuthUserUpdated extends AuthEvent {
  final dynamic user;

  const AuthUserUpdated(this.user);

  @override
  List<Object?> get props => [user];
}

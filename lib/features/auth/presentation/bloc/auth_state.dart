part of 'auth_bloc.dart';

/// 用户角色
enum UserRole {
  superAdmin,
  teamAdmin,
  member,
  visitor,
}

/// 认证状态基类
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// 初始状态
class AuthInitial extends AuthState {}

/// 加载中
class AuthLoading extends AuthState {}

/// 已认证
class AuthAuthenticated extends AuthState {
  final String userId;
  final String username;
  final String email;
  final UserRole role;

  const AuthAuthenticated({
    required this.userId,
    required this.username,
    required this.email,
    required this.role,
  });

  bool get isVisitor => role == UserRole.visitor;
  bool get isAdmin => role == UserRole.superAdmin || role == UserRole.teamAdmin;
  bool get isMember => role == UserRole.member;
  
  String get roleDisplayName {
    switch (role) {
      case UserRole.superAdmin:
        return '超级管理员';
      case UserRole.teamAdmin:
        return '团队管理员';
      case UserRole.member:
        return '团队成员';
      case UserRole.visitor:
        return '访客';
    }
  }

  @override
  List<Object?> get props => [userId, username, email, role];
}

/// 未认证
class AuthUnauthenticated extends AuthState {}

/// 错误状态
class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object?> get props => [message];
}

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

/// 团队信息
class TeamInfo extends Equatable {
  final int id;
  final String name;

  const TeamInfo({
    required this.id,
    required this.name,
  });

  @override
  List<Object?> get props => [id, name];
}

/// 已认证
class AuthAuthenticated extends AuthState {
  final String userId;
  final String username;
  final String email;
  final UserRole role;
  final String? avatar;
  final TeamInfo? team;

  const AuthAuthenticated({
    required this.userId,
    required this.username,
    required this.email,
    required this.role,
    this.avatar,
    this.team,
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

  /// 复制并修改属性
  AuthAuthenticated copyWith({
    String? userId,
    String? username,
    String? email,
    UserRole? role,
    String? avatar,
    TeamInfo? team,
  }) {
    return AuthAuthenticated(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      avatar: avatar ?? this.avatar,
      team: team ?? this.team,
    );
  }

  @override
  List<Object?> get props => [userId, username, email, role, avatar, team];
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

/// 认证仓库接口
abstract class AuthRepository {
  /// 用户登录
  /// POST /api/auth/login/
  /// 
  /// 返回: {access, refresh, user}
  Future<LoginResult> login({
    required String username,
    required String password,
  });

  /// 用户注册
  /// POST /api/auth/register/
  /// 
  /// 返回: {id, username, email, role, team_name, join_type}
  Future<RegisterResult> register({
    required String username,
    required String email,
    required String password,
    String? teamName,
    String? joinType,
  });

  /// 用户登出
  /// POST /api/auth/logout/
  Future<void> logout();

  /// 获取当前用户信息
  /// GET /api/auth/me/
  Future<UserInfo> getCurrentUser();

  /// 刷新 token
  /// POST /api/auth/refresh/
  Future<TokenRefreshResult> refreshToken(String refreshToken);

  /// 检查访客状态
  /// GET /api/auth/visitor/status/
  Future<VisitorStatus> checkVisitorStatus();
}

/// 登录结果
class LoginResult {
  final String accessToken;
  final String refreshToken;
  final UserInfo user;

  LoginResult({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });
}

/// 注册结果
class RegisterResult {
  final int id;
  final String username;
  final String email;
  final String role;
  final String? teamName;
  final String joinType;

  RegisterResult({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.teamName,
    required this.joinType,
  });

  bool get isVisitor => role == 'visitor' || joinType == 'join';
  bool get isAdmin => role == 'team_admin';
  bool get isMember => role == 'member';
}

/// 用户信息
class UserInfo {
  final int id;
  final String username;
  final String email;
  final String role;
  final String? avatar;
  final TeamInfo? team;

  UserInfo({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.avatar,
    this.team,
  });

  bool get isVisitor => role == 'visitor';
  bool get isAdmin => role == 'team_admin';
  bool get isMember => role == 'member';
}

/// 团队信息
class TeamInfo {
  final int id;
  final String name;

  TeamInfo({
    required this.id,
    required this.name,
  });
}

/// Token 刷新结果
class TokenRefreshResult {
  final String accessToken;

  TokenRefreshResult({
    required this.accessToken,
  });
}

/// 访客状态
class VisitorStatus {
  final bool isVisitor;
  final String? status;

  VisitorStatus({
    required this.isVisitor,
    this.status,
  });
}

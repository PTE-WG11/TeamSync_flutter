import 'package:equatable/equatable.dart';

/// 团队成员实体
class TeamMember extends Equatable {
  final int id;
  final String username;
  final String email;
  final String role;
  final String roleDisplay;
  final String? avatar;
  final int taskCount;
  final DateTime createdAt;

  const TeamMember({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    required this.roleDisplay,
    this.avatar,
    required this.taskCount,
    required this.createdAt,
  });

  /// 是否为团队管理员
  bool get isTeamAdmin => role == 'team_admin';

  /// 是否为成员
  bool get isMember => role == 'member';

  @override
  List<Object?> get props => [
        id,
        username,
        email,
        role,
        roleDisplay,
        avatar,
        taskCount,
        createdAt,
      ];

  TeamMember copyWith({
    int? id,
    String? username,
    String? email,
    String? role,
    String? roleDisplay,
    String? avatar,
    int? taskCount,
    DateTime? createdAt,
  }) {
    return TeamMember(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      roleDisplay: roleDisplay ?? this.roleDisplay,
      avatar: avatar ?? this.avatar,
      taskCount: taskCount ?? this.taskCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// 团队成员筛选条件
class TeamMemberFilter extends Equatable {
  final String? role;
  final String? search;
  final String? ordering;  // 排序字段
  final int? page;         // 页码
  final int? pageSize;     // 每页数量

  const TeamMemberFilter({
    this.role,
    this.search,
    this.ordering,
    this.page,
    this.pageSize,
  });

  TeamMemberFilter copyWith({
    String? role,
    String? search,
    String? ordering,
    int? page,
    int? pageSize,
  }) {
    return TeamMemberFilter(
      role: role ?? this.role,
      search: search ?? this.search,
      ordering: ordering ?? this.ordering,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  @override
  List<Object?> get props => [role, search, ordering, page, pageSize];
}

/// 邀请成员请求
class InviteMemberRequest extends Equatable {
  final String username;
  final String role;

  const InviteMemberRequest({
    required this.username,
    this.role = 'member',
  });

  Map<String, dynamic> toJson() => {
        'username': username,
        'role': role,
      };

  @override
  List<Object?> get props => [username, role];
}

/// 修改角色请求
class UpdateRoleRequest extends Equatable {
  final String role;

  const UpdateRoleRequest({
    required this.role,
  });

  Map<String, dynamic> toJson() => {
        'role': role,
      };

  @override
  List<Object?> get props => [role];
}

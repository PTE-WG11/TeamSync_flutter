import '../../domain/entities/team_member.dart';

/// 团队成员数据模型
class TeamMemberModel extends TeamMember {
  const TeamMemberModel({
    required super.id,
    required super.username,
    required super.email,
    required super.role,
    required super.roleDisplay,
    super.avatar,
    required super.taskCount,
    required super.createdAt,
  });

  factory TeamMemberModel.fromJson(Map<String, dynamic> json) {
    return TeamMemberModel(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      roleDisplay: json['role_display'] as String,
      avatar: json['avatar'] as String?,
      taskCount: json['task_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'role': role,
      'role_display': roleDisplay,
      'avatar': avatar,
      'task_count': taskCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TeamMemberModel.fromEntity(TeamMember entity) {
    return TeamMemberModel(
      id: entity.id,
      username: entity.username,
      email: entity.email,
      role: entity.role,
      roleDisplay: entity.roleDisplay,
      avatar: entity.avatar,
      taskCount: entity.taskCount,
      createdAt: entity.createdAt,
    );
  }

  TeamMemberModel copyWithModel({
    int? id,
    String? username,
    String? email,
    String? role,
    String? roleDisplay,
    String? avatar,
    int? taskCount,
    DateTime? createdAt,
  }) {
    return TeamMemberModel(
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

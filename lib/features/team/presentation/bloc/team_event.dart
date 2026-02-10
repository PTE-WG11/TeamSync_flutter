import 'package:equatable/equatable.dart';
import '../../domain/entities/team_member.dart';

abstract class TeamEvent extends Equatable {
  const TeamEvent();

  @override
  List<Object?> get props => [];
}

/// 加载团队成员列表
class TeamMembersLoaded extends TeamEvent {
  final String? role;
  final String? search;

  const TeamMembersLoaded({
    this.role,
    this.search,
  });

  @override
  List<Object?> get props => [role, search];
}

/// 筛选角色变更
class TeamRoleFilterChanged extends TeamEvent {
  final String? role;

  const TeamRoleFilterChanged(this.role);

  @override
  List<Object?> get props => [role];
}

/// 搜索关键词变更
class TeamSearchChanged extends TeamEvent {
  final String search;

  const TeamSearchChanged(this.search);

  @override
  List<Object?> get props => [search];
}

/// 邀请成员
class TeamMemberInvited extends TeamEvent {
  final InviteMemberRequest request;

  const TeamMemberInvited(this.request);

  @override
  List<Object?> get props => [request];
}

/// 修改成员角色
class TeamMemberRoleUpdated extends TeamEvent {
  final int memberId;
  final String newRole;

  const TeamMemberRoleUpdated({
    required this.memberId,
    required this.newRole,
  });

  @override
  List<Object?> get props => [memberId, newRole];
}

/// 移除成员
class TeamMemberRemoved extends TeamEvent {
  final int memberId;

  const TeamMemberRemoved(this.memberId);

  @override
  List<Object?> get props => [memberId];
}

/// 检查用户名是否存在
class TeamUsernameChecked extends TeamEvent {
  final String username;

  const TeamUsernameChecked(this.username);

  @override
  List<Object?> get props => [username];
}

/// 清空错误状态
class TeamErrorCleared extends TeamEvent {
  const TeamErrorCleared();
}

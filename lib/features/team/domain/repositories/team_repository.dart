import '../entities/team_member.dart';

/// 团队管理仓库接口
abstract class TeamRepository {
  /// 获取团队成员列表
  /// 
  /// [filter] - 筛选条件（角色、搜索关键词）
  Future<List<TeamMember>> getTeamMembers({TeamMemberFilter? filter});

  /// 邀请成员加入团队
  /// 
  /// [request] - 邀请请求（用户名、角色）
  Future<TeamMember> inviteMember(InviteMemberRequest request);

  /// 修改成员角色
  /// 
  /// [memberId] - 成员ID
  /// [request] - 角色更新请求
  Future<TeamMember> updateMemberRole(int memberId, UpdateRoleRequest request);

  /// 移除团队成员
  /// 
  /// [memberId] - 要移除的成员ID
  Future<void> removeMember(int memberId);

  /// 检查用户名是否存在
  /// 
  /// [username] - 要检查的用户名
  Future<bool> checkUsernameExists(String username);
}

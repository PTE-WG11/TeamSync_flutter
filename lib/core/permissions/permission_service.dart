import '../../features/auth/presentation/bloc/auth_bloc.dart';

/// 权限服务
/// 集中管理所有权限检查逻辑
class PermissionService {
  final AuthBloc authBloc;

  const PermissionService(this.authBloc);

  /// 获取当前用户角色
  UserRole? get currentRole {
    final state = authBloc.state;
    if (state is AuthAuthenticated) {
      return state.role;
    }
    return null;
  }

  /// 是否为管理员
  bool get isAdmin {
    final state = authBloc.state;
    return state is AuthAuthenticated && state.isAdmin;
  }

  /// 是否为团队成员（非访客）
  bool get isTeamMember {
    final state = authBloc.state;
    return state is AuthAuthenticated && 
           (state.isMember || state.isAdmin);
  }

  /// 当前用户ID
  String? get currentUserId {
    final state = authBloc.state;
    if (state is AuthAuthenticated) {
      return state.userId;
    }
    return null;
  }

  // ==================== 项目权限 ====================

  /// 是否可以创建项目（仅管理员）
  bool get canCreateProject => isAdmin;

  /// 是否可以编辑项目（仅管理员）
  bool canEditProject(String? createdBy) => isAdmin;

  /// 是否可以删除项目（仅管理员）
  bool canDeleteProject(String? createdBy) => isAdmin;

  /// 是否可以归档项目（仅管理员）
  bool canArchiveProject(String? createdBy) => isAdmin;

  /// 是否可以管理项目成员（仅管理员）
  bool get canManageProjectMembers => isAdmin;

  // ==================== 任务权限 ====================

  /// 是否可以创建任务
  /// - 管理员：可以
  /// - 成员：如果有项目权限
  bool get canCreateTask => isTeamMember;

  /// 是否可以编辑任务
  /// - 管理员：可以
  /// - 成员：仅自己的任务
  bool canEditTask(int? assigneeId) {
    if (isAdmin) return true;
    return assigneeId?.toString() == currentUserId;
  }

  /// 是否可以删除任务（仅管理员或任务创建者）
  bool canDeleteTask(String? createdBy) => isAdmin;

  /// 是否可以创建子任务
  /// - 管理员：只能为自己负责的任务创建子任务
  /// - 成员：只能为自己负责的任务创建子任务
  bool canCreateSubTask(int? parentTaskAssigneeId) {
    final state = authBloc.state;
    if (state is! AuthAuthenticated) return false;
    
    // 只有任务的负责人可以创建子任务（无论管理员还是成员）
    return parentTaskAssigneeId?.toString() == state.userId;
  }

  // ==================== 团队权限 ====================

  /// 是否可以管理团队成员（仅管理员）
  bool get canManageTeamMembers => isAdmin;

  /// 是否可以邀请成员（仅管理员）
  bool get canInviteMembers => isAdmin;

  /// 是否可以修改成员角色（仅管理员）
  bool get canChangeMemberRole => isAdmin;

  /// 是否可以移除团队成员（仅管理员）
  bool get canRemoveMembers => isAdmin;

  // ==================== 附件权限 ====================

  /// 是否可以上传附件
  /// - 管理员：可以上传任何任务的附件
  /// - 成员：只能上传自己负责的任务的附件
  /// - 访客：不能上传
  bool canUploadAttachment(int? taskAssigneeId) {
    final state = authBloc.state;
    if (state is! AuthAuthenticated) return false;
    
    // 管理员可以上传任何任务的附件
    if (state.isAdmin) return true;
    
    // 成员只能上传自己负责的任务的附件
    if (state.isMember) {
      return taskAssigneeId?.toString() == state.userId;
    }
    
    return false;
  }

  /// 是否可以删除附件
  /// - 管理员：可以删除任何附件
  /// - 成员：只能删除自己上传的附件
  bool canDeleteAttachment(int? uploadedById) {
    final state = authBloc.state;
    if (state is! AuthAuthenticated) return false;
    
    // 管理员可以删除任何附件
    if (state.isAdmin) return true;
    
    // 成员只能删除自己上传的附件
    return uploadedById?.toString() == state.userId;
  }

  /// 是否可以下载/查看附件（团队成员都可以）
  bool get canDownloadAttachment => isTeamMember;
}

/// 全局权限检查函数（用于简化代码）
bool isCurrentUserAdmin(AuthBloc authBloc) {
  final state = authBloc.state;
  return state is AuthAuthenticated && state.isAdmin;
}

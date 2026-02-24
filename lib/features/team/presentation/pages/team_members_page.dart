import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/routes.dart';
import '../../../../config/theme.dart';
import '../../../../core/permissions/permission_widgets.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../data/repositories/team_repository_impl.dart';
import '../../domain/entities/team_member.dart';
import '../bloc/team_bloc.dart';
import '../bloc/team_event.dart';
import '../bloc/team_state.dart';
import '../widgets/invite_member_dialog.dart';

/// 团队成员管理页面
/// 仅团队管理员可访问
class TeamMembersPage extends StatelessWidget {
  const TeamMembersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TeamBloc(
        repository: TeamRepositoryImpl(),
      )..add(const TeamMembersLoaded()),
      child: const _TeamMembersView(),
    );
  }
}

class _TeamMembersView extends StatefulWidget {
  const _TeamMembersView();

  @override
  State<_TeamMembersView> createState() => _TeamMembersViewState();
}

class _TeamMembersViewState extends State<_TeamMembersView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 页面标题
            _buildHeader(context),
            const SizedBox(height: 24),
            // 统计卡片
            _buildStatsCards(),
            const SizedBox(height: 24),
            // 搜索和过滤
            _buildSearchAndFilter(),
            const SizedBox(height: 16),
            // 成员列表
            Expanded(child: _buildMembersList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final isAdmin = authState is AuthAuthenticated && authState.isAdmin;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('团队成员', style: AppTypography.h3),
            const SizedBox(height: 4),
            Text(
              isAdmin ? '管理团队成员，分配角色权限' : '查看团队成员，发起对话',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        // 仅管理员可见邀请按钮
        AdminOnly(
          child: ElevatedButton.icon(
            onPressed: () => _showInviteDialog(context),
            icon: const Icon(Icons.person_add, size: 18),
            label: const Text('邀请成员'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textInverse,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCards() {
    return BlocBuilder<TeamBloc, TeamState>(
      builder: (context, state) {
        return Row(
          children: [
            _buildStatCard(
              '总成员',
              state.totalMembers.toString(),
              Icons.people,
              AppColors.primary,
            ),
            const SizedBox(width: 16),
            _buildStatCard(
              '管理员',
              state.adminCount.toString(),
              Icons.admin_panel_settings,
              AppColors.statusInProgress,
            ),
            const SizedBox(width: 16),
            _buildStatCard(
              '普通成员',
              (state.totalMembers - state.adminCount).toString(),
              Icons.person,
              AppColors.statusPlanning,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTypography.h2.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return BlocBuilder<TeamBloc, TeamState>(
      builder: (context, state) {
        return Row(
          children: [
            // 搜索框
            Expanded(
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.divider),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '搜索用户名或邮箱...',
                    hintStyle: TextStyle(color: AppColors.textDisabled),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              context.read<TeamBloc>().add(
                                    const TeamSearchChanged(''),
                                  );
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    context.read<TeamBloc>().add(TeamSearchChanged(value));
                  },
                ),
              ),
            ),
            const SizedBox(width: 16),
            // 角色过滤
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.divider),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: state.roleFilter,
                  hint: const Text('全部角色'),
                  icon: const Icon(Icons.arrow_drop_down),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('全部角色'),
                    ),
                    DropdownMenuItem(
                      value: 'team_admin',
                      child: Row(
                        children: [
                          Icon(
                            Icons.admin_panel_settings,
                            size: 16,
                            color: AppColors.statusInProgress,
                          ),
                          const SizedBox(width: 8),
                          const Text('管理员'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'member',
                      child: Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 16,
                            color: AppColors.statusPlanning,
                          ),
                          const SizedBox(width: 8),
                          const Text('普通成员'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    context.read<TeamBloc>().add(TeamRoleFilterChanged(value));
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMembersList() {
    return BlocConsumer<TeamBloc, TeamState>(
      listener: (context, state) {
        if (state.status == TeamStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? '操作失败'),
              backgroundColor: AppColors.error,
            ),
          );
          context.read<TeamBloc>().add(const TeamErrorCleared());
        }
      },
      builder: (context, state) {
        if (state.status == TeamStatus.loading && state.members.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final members = state.filteredMembers;

        if (members.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 64,
                  color: AppColors.textDisabled,
                ),
                const SizedBox(height: 16),
                Text(
                  '暂无成员',
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (state.searchQuery.isNotEmpty || state.roleFilter != null)
                  TextButton(
                    onPressed: () {
                      _searchController.clear();
                      context.read<TeamBloc>().add(const TeamMembersLoaded());
                    },
                    child: const Text('清除筛选'),
                  ),
              ],
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: [
              // 表头
              _buildTableHeader(),
              const Divider(height: 1),
              // 列表
              Expanded(
                child: ListView.separated(
                  itemCount: members.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    return _buildMemberRow(context, members[index]);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: AppColors.background,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '成员',
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '角色',
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '任务数',
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '加入时间',
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          SizedBox(
            width: 200,
            child: Text(
              '操作',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberRow(BuildContext context, TeamMember member) {
    final authState = context.read<AuthBloc>().state;
    final isAdmin = authState is AuthAuthenticated && authState.isAdmin;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // 成员信息
          Expanded(
            flex: 2,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primaryLight,
                  backgroundImage:
                      member.avatar != null ? NetworkImage(member.avatar!) : null,
                  child: member.avatar == null
                      ? Text(
                          member.username.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.username,
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      member.email,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 角色
          Expanded(
            child: _buildRoleChip(member.role),
          ),
          // 任务数
          Expanded(
            child: Text(
              '${member.taskCount} 个任务',
              style: AppTypography.bodySmall,
            ),
          ),
          // 加入时间
          Expanded(
            flex: 2,
            child: Text(
              _formatDate(member.createdAt),
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          // 操作按钮
          SizedBox(
            width: isAdmin ? 200 : 100, // 成员显示更少按钮
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 查看任务 - 所有成员可见
                _buildActionButton(
                  icon: Icons.task_alt,
                  tooltip: '查看任务',
                  onTap: () => _viewMemberTasks(context, member),
                ),
                const SizedBox(width: 8),
                // 对话 - 所有成员可见
                _buildActionButton(
                  icon: Icons.chat_bubble_outline,
                  tooltip: '发起对话',
                  onTap: () => _startChat(context, member),
                ),
                // 以下仅管理员可见
                if (isAdmin) ...[
                  const SizedBox(width: 8),
                  // 修改角色
                  _buildActionButton(
                    icon: Icons.edit,
                    tooltip: '修改角色',
                    onTap: () => _showEditRoleDialog(context, member),
                  ),
                  const SizedBox(width: 8),
                  // 移除
                  _buildActionButton(
                    icon: Icons.person_remove,
                    tooltip: '移除成员',
                    color: AppColors.error,
                    onTap: () => _showRemoveConfirmDialog(context, member),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleChip(String role) {
    final isAdmin = role == 'team_admin';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isAdmin
            ? AppColors.statusInProgress.withOpacity(0.1)
            : AppColors.statusPlanning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        isAdmin ? '管理员' : '成员',
        style: AppTypography.caption.copyWith(
          color: isAdmin ? AppColors.statusInProgress : AppColors.statusPlanning,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 18,
            color: color ?? AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _showInviteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<TeamBloc>(),
        child: const InviteMemberDialog(),
      ),
    );
  }

  void _viewMemberTasks(BuildContext context, TeamMember member) {
    // 导航到成员任务页面
    context.go('${AppRoutes.members}/tasks/${member.id}', extra: member);
    
    // 临时提示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('查看 ${member.username} 的任务列表'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _startChat(BuildContext context, TeamMember member) {
    // TODO: 实现对话功能
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('与 ${member.username} 的对话功能开发中...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showEditRoleDialog(BuildContext context, TeamMember member) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('修改角色'),
        content: Text('将 ${member.username} 的角色修改为？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          if (member.isMember)
            ElevatedButton(
              onPressed: () {
                context.read<TeamBloc>().add(TeamMemberRoleUpdated(
                      memberId: member.id,
                      newRole: 'team_admin',
                    ));
                Navigator.pop(dialogContext);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('设为管理员'),
            ),
          if (member.isTeamAdmin)
            ElevatedButton(
              onPressed: () {
                context.read<TeamBloc>().add(TeamMemberRoleUpdated(
                      memberId: member.id,
                      newRole: 'member',
                    ));
                Navigator.pop(dialogContext);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
              ),
              child: const Text('设为普通成员'),
            ),
        ],
      ),
    );
  }

  void _showRemoveConfirmDialog(BuildContext context, TeamMember member) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('确认移除'),
        content: Text('确定要将 ${member.username} 从团队中移除吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<TeamBloc>().add(TeamMemberRemoved(member.id));
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textInverse,
            ),
            child: const Text('移除'),
          ),
        ],
      ),
    );
  }
}

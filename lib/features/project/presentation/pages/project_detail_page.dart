import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes.dart';
import '../../../../config/theme.dart';
// import '../../../../core/permissions/permission_widgets.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../task/presentation/widgets/create_task_dialog.dart';
import '../../../task/presentation/widgets/task_list_widget.dart';
import '../bloc/project_bloc.dart';
import '../bloc/project_event.dart';
import '../bloc/project_state.dart';

/// 项目详情页面
class ProjectDetailPage extends StatefulWidget {
  final int projectId;

  const ProjectDetailPage({
    super.key,
    required this.projectId,
  });

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _loadProjectDetail();
  }

  void _initTabController() {
    if (_tabController == null) {
      _tabController = TabController(length: 4, vsync: this);
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ProjectDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.projectId != widget.projectId) {
      // 延迟执行，确保 context 可用
      Future.microtask(() => _loadProjectDetail());
    }
  }

  void _loadProjectDetail() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<ProjectBloc>().add(ProjectDetailRequested(
        widget.projectId,
        userId: authState.userId,
        isAdmin: authState.isAdmin,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectBloc, ProjectState>(
      builder: (context, state) {
        return Padding(
          padding: AppSpacing.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 页面头部
              _buildHeader(state),
              const SizedBox(height: 24),
              // 页面内容
              Expanded(
                child: _buildBody(state),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 构建页面头部
  Widget _buildHeader(ProjectState state) {
    return Row(
      children: [
        IconButton(
          onPressed: () => context.go(AppRoutes.projects),
          icon: const Icon(Icons.arrow_back),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '项目详情',
            style: AppTypography.h3,
          ),
        ),
        if (state is ProjectDetailLoadSuccess) ...[
          // 创建任务按钮 - 所有团队成员都可见
          ElevatedButton.icon(
            onPressed: () => _showCreateTaskDialog(context, state.project),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('创建任务'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textInverse,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 更多操作 - 仅管理员可见
          if (state.isAdmin)
            IconButton(
              onPressed: () => _showProjectActions(state.project, state.isAdmin),
              icon: const Icon(Icons.more_vert),
            ),
        ],
      ],
    );
  }

  /// 构建页面主体
  Widget _buildBody(ProjectState state) {
    if (state is ProjectDetailLoadInProgress) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is ProjectDetailLoadFailure) {
      // 无权限访问时显示专用页面
      if (state.isForbidden) {
        return _buildForbiddenView();
      }
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              state.message,
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProjectDetail,
              child: const Text('重新加载'),
            ),
          ],
        ),
      );
    }

    if (state is ProjectDetailLoadSuccess) {
      final project = state.project;

      return RefreshIndicator(
        onRefresh: () async {
          _loadProjectDetail();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 项目信息卡片
              _buildProjectInfoCard(project),
              const SizedBox(height: 24),
              // 任务视图 Tab
              _buildTaskSection(state),
              const SizedBox(height: 24),
            ],
          ),
        ),
      );
    }

    return const Center(child: CircularProgressIndicator());
  }

  /// 构建无权限访问视图
  Widget _buildForbiddenView() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.block,
              size: 64,
              color: AppColors.error.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              '无访问权限',
              style: AppTypography.h2,
            ),
            const SizedBox(height: 16),
            Text(
              '您不是此项目的成员，无法查看项目详情',
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.projects),
              child: const Text('返回项目列表'),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建项目信息卡片
  Widget _buildProjectInfoCard(dynamic project) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildStatusBadge(project.status),
              const Spacer(),
              if (project.isArchived)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.textDisabled.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.archive_outlined,
                        size: 14,
                        color: AppColors.textDisabled,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '已归档',
                        style: AppTypography.label.copyWith(
                          color: AppColors.textDisabled,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(project.title, style: AppTypography.h2),
          const SizedBox(height: 8),
          Text(
            project.description,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          // 成员和统计信息
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 成员
              Expanded(
                flex: 2,
                child: _buildMembersPreview(project.members),
              ),
              const SizedBox(width: 24),
              // 任务统计
              Expanded(
                flex: 3,
                child: _buildTaskStatsPreview(project.taskStats),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 进度条
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: project.progress / 100,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      project.isCompleted
                          ? AppColors.success
                          : AppColors.primary,
                    ),
                    minHeight: 10,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '${project.progress.toStringAsFixed(0)}%',
                style: AppTypography.h4.copyWith(
                  color: project.isCompleted
                      ? AppColors.success
                      : AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建成员预览
  Widget _buildMembersPreview(List<dynamic> members) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '项目成员',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...members.take(5).map<Widget>((member) {
              return Tooltip(
                message: member.username,
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    member.username[0].toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }),
            if (members.length > 5)
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.background,
                child: Text(
                  '+${members.length - 5}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  /// 构建任务统计预览
  Widget _buildTaskStatsPreview(dynamic taskStats) {
    if (taskStats == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '任务统计',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildMiniStat('规划中', taskStats.planning, AppColors.statusPlanning),
            _buildMiniStat('待处理', taskStats.pending, AppColors.statusPending),
            _buildMiniStat('进行中', taskStats.inProgress, AppColors.statusInProgress),
            _buildMiniStat('已完成', taskStats.completed, AppColors.statusCompleted),
          ],
        ),
        if (taskStats.overdue > 0) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.warning_amber, color: AppColors.error, size: 16),
              const SizedBox(width: 4),
              Text(
                '逾期 ${taskStats.overdue} 个',
                style: AppTypography.caption.copyWith(color: AppColors.error),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildMiniStat(String label, int value, Color color) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$label $value',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建任务区域（Tab切换）
  Widget _buildTaskSection(ProjectDetailLoadSuccess state) {
    _initTabController();
    
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tab 标题栏
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('任务管理', style: AppTypography.h4),
                // 视图切换标签
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: TabBar(
                    controller: _tabController!,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    indicator: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    labelColor: AppColors.textInverse,
                    unselectedLabelColor: AppColors.textSecondary,
                    labelStyle: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    dividerColor: Colors.transparent,
                    padding: const EdgeInsets.all(4),
                    tabs: const [
                      Tab(text: '列表'),
                      Tab(text: '看板'),
                      Tab(text: '甘特图'),
                      Tab(text: '日历'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Tab 内容
          SizedBox(
            height: 600, // 固定高度
            child: TabBarView(
              controller: _tabController!,
              children: [
                // 列表视图
                _buildListView(state),
                // 看板视图（预留）
                _buildPlaceholderView('看板视图', Icons.view_kanban),
                // 甘特图视图（预留）
                _buildPlaceholderView('甘特图视图', Icons.timeline),
                // 日历视图（预留）
                _buildPlaceholderView('日历视图', Icons.calendar_month),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建列表视图
  Widget _buildListView(ProjectDetailLoadSuccess state) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: TaskListWidget(
        tasks: state.tasks,
        projectId: state.project.id,
        isLoading: state.tasksLoading,
        onCreateTask: () => _showCreateTaskDialog(context, state.project),
      ),
    );
  }

  /// 构建占位视图
  Widget _buildPlaceholderView(String title, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.textDisabled),
          const SizedBox(height: 16),
          Text(
            title,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '功能开发中...',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textDisabled,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建状态标签
  Widget _buildStatusBadge(String status) {
    final config = _getStatusConfig(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: config.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            config.label,
            style: AppTypography.label.copyWith(color: config.color),
          ),
        ],
      ),
    );
  }

  void _showCreateTaskDialog(BuildContext context, dynamic project) {
    showDialog(
      context: context,
      builder: (dialogContext) => CreateTaskDialog(
        projectId: project.id,
        members: project.members,
        onCreate: ({
          required String title,
          String? description,
          required int assigneeId,
          String priority = 'medium',
          DateTime? startDate,
          DateTime? endDate,
        }) {
          context.read<ProjectBloc>().add(ProjectTaskCreateRequested(
                projectId: project.id,
                title: title,
                description: description,
                assigneeId: assigneeId,
                priority: priority,
                startDate: startDate,
                endDate: endDate,
              ));
        },
      ),
    );
  }

  void _showProjectActions(dynamic project, bool isAdmin) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 仅管理员可见的操作
            if (isAdmin) ...[
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('编辑项目'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              if (!project.isArchived)
                ListTile(
                  leading: const Icon(Icons.archive_outlined),
                  title: const Text('归档项目'),
                  onTap: () {
                    Navigator.pop(context);
                    _showArchiveConfirm(project);
                  },
                ),
              if (project.isArchived)
                ListTile(
                  leading: const Icon(Icons.delete_outline,
                      color: AppColors.error),
                  title: const Text('删除项目',
                      style: TextStyle(color: AppColors.error)),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirm(project);
                  },
                ),
            ],
            // 所有成员都可见
            ListTile(
              leading: const Icon(Icons.visibility_outlined),
              title: const Text('查看项目信息'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showArchiveConfirm(dynamic project) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('归档项目', style: AppTypography.h4),
        content: Text('确定要归档项目"${project.title}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ProjectBloc>().add(
                    ProjectArchiveRequested(project.id),
                  );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('项目"${project.title}"已归档')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
            ),
            child: const Text('归档'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(dynamic project) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('删除项目', style: AppTypography.h4),
        content: Text('确定要删除项目"${project.title}"吗？此操作不可恢复！'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ProjectBloc>().add(
                    ProjectDeleteRequested(project.id),
                  );
              context.go(AppRoutes.projects);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('项目"${project.title}"已删除'),
                  backgroundColor: AppColors.error,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textInverse,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  _StatusConfig _getStatusConfig(String status) {
    switch (status) {
      case 'planning':
        return _StatusConfig(
          label: '规划中',
          color: AppColors.statusPlanning,
          backgroundColor: AppColors.statusPlanningLight,
        );
      case 'pending':
        return _StatusConfig(
          label: '待处理',
          color: AppColors.statusPending,
          backgroundColor: AppColors.statusPendingLight,
        );
      case 'in_progress':
        return _StatusConfig(
          label: '进行中',
          color: AppColors.statusInProgress,
          backgroundColor: AppColors.statusInProgressLight,
        );
      case 'completed':
        return _StatusConfig(
          label: '已完成',
          color: AppColors.statusCompleted,
          backgroundColor: AppColors.statusCompletedLight,
        );
      default:
        return _StatusConfig(
          label: '未知',
          color: AppColors.textSecondary,
          backgroundColor: AppColors.border,
        );
    }
  }
}

class _StatusConfig {
  final String label;
  final Color color;
  final Color backgroundColor;

  _StatusConfig({
    required this.label,
    required this.color,
    required this.backgroundColor,
  });
}

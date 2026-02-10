import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes.dart';
import '../../../../config/theme.dart';
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

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  @override
  void initState() {
    super.initState();
    _loadProjectDetail();
  }

  @override
  void didUpdateWidget(ProjectDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.projectId != widget.projectId) {
      _loadProjectDetail();
    }
  }

  void _loadProjectDetail() {
    context.read<ProjectBloc>().add(ProjectDetailRequested(widget.projectId));
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
              // 返回按钮 + 标题
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
          IconButton(
            onPressed: () => _showProjectActions(state.project),
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(state.message, style: AppTypography.body.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<ProjectBloc>().add(ProjectDetailRequested(widget.projectId));
              },
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
          context.read<ProjectBloc>().add(ProjectDetailRequested(widget.projectId));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 项目基本信息卡片
              _buildProjectInfoCard(project),
              const SizedBox(height: 24),
              // 任务统计卡片
              if (project.taskStats != null)
                _buildTaskStatsCard(project.taskStats!),
              const SizedBox(height: 24),
              // 成员列表
              _buildMembersCard(project),
              const SizedBox(height: 24),
              // 项目时间线
              _buildTimelineCard(project),
              const SizedBox(height: 32),
            ],
          ),
        ),
      );
    }

    return const Center(child: CircularProgressIndicator());
  }

  /// 构建项目基本信息卡片
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.textDisabled.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.archive_outlined, size: 14, color: AppColors.textDisabled),
                      const SizedBox(width: 4),
                      Text(
                        '已归档',
                        style: AppTypography.label.copyWith(color: AppColors.textDisabled),
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
            style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
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
                      project.isCompleted ? AppColors.success : AppColors.primary,
                    ),
                    minHeight: 10,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '${project.progress.toStringAsFixed(0)}%',
                style: AppTypography.h4.copyWith(
                  color: project.isCompleted ? AppColors.success : AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建任务统计卡片
  Widget _buildTaskStatsCard(dynamic taskStats) {
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
          Text('任务统计', style: AppTypography.h4),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatItem('规划中', taskStats.planning, AppColors.statusPlanning),
              _buildStatDivider(),
              _buildStatItem('待处理', taskStats.pending, AppColors.statusPending),
              _buildStatDivider(),
              _buildStatItem('进行中', taskStats.inProgress, AppColors.statusInProgress),
              _buildStatDivider(),
              _buildStatItem('已完成', taskStats.completed, AppColors.statusCompleted),
            ],
          ),
          if (taskStats.overdue > 0) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.warning_amber, color: AppColors.error, size: 20),
                const SizedBox(width: 8),
                Text(
                  '逾期任务: ${taskStats.overdue} 个',
                  style: AppTypography.body.copyWith(color: AppColors.error),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value.toString(),
            style: AppTypography.h3.copyWith(color: color),
          ),
          const SizedBox(height: 4),
          Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 40,
      color: AppColors.border,
    );
  }

  /// 构建成员卡片
  Widget _buildMembersCard(dynamic project) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('项目成员', style: AppTypography.h4),
              TextButton(
                onPressed: () {
                  // TODO: 管理成员
                },
                child: const Text('管理成员'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: project.members.map<Widget>((member) {
              return Chip(
                avatar: CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Text(
                    member.username[0],
                    style: const TextStyle(
                      color: AppColors.textInverse,
                      fontSize: 12,
                    ),
                  ),
                ),
                label: Text(member.username),
                backgroundColor: AppColors.background,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// 构建时间线卡片
  Widget _buildTimelineCard(dynamic project) {
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
          Text('项目时间线', style: AppTypography.h4),
          const SizedBox(height: 16),
          _buildTimelineItem(
            icon: Icons.play_circle_outline,
            title: '开始日期',
            date: project.startDate ?? '未设置',
            color: AppColors.primary,
          ),
          _buildTimelineConnector(),
          _buildTimelineItem(
            icon: Icons.flag_outlined,
            title: '截止日期',
            date: project.endDate ?? '未设置',
            color: AppColors.warning,
          ),
          if (project.isArchived) ...[
            _buildTimelineConnector(),
            _buildTimelineItem(
              icon: Icons.archive_outlined,
              title: '归档日期',
              date: project.archivedAt?.substring(0, 10) ?? '未知',
              color: AppColors.textDisabled,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required String title,
    required String date,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.body.copyWith(color: AppColors.textSecondary)),
              Text(date, style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineConnector() {
    return Container(
      margin: const EdgeInsets.only(left: 19),
      width: 2,
      height: 30,
      color: AppColors.border,
    );
  }

  /// 构建状态标签
  Widget _buildStatusBadge(String status) {
    final statusConfig = _getStatusConfig(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusConfig.backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusConfig.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            statusConfig.label,
            style: AppTypography.label.copyWith(color: statusConfig.color),
          ),
        ],
      ),
    );
  }

  /// 获取状态配置
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

  /// 显示项目操作菜单
  void _showProjectActions(dynamic project) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('编辑项目'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 编辑项目
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
                leading: const Icon(Icons.delete_outline, color: AppColors.error),
                title: const Text('删除项目', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirm(project);
                },
              ),
          ],
        ),
      ),
    );
  }

  /// 显示归档确认
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
              context.read<ProjectBloc>().add(ProjectArchiveRequested(project.id));
              context.read<ProjectBloc>().add(ProjectDetailRequested(widget.projectId));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('项目"${project.title}"已归档')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: const Text('归档'),
          ),
        ],
      ),
    );
  }

  /// 显示删除确认
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
              context.read<ProjectBloc>().add(ProjectDeleteRequested(project.id));
              context.go(AppRoutes.projects);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('项目"${project.title}"已删除'),
                  backgroundColor: AppColors.error,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

/// 状态配置
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

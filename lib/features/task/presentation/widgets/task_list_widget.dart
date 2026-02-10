import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import '../../domain/entities/task.dart';

/// 任务列表组件（可展开子任务）
class TaskListWidget extends StatelessWidget {
  final List<Task> tasks;
  final bool isLoading;
  final int projectId;
  final VoidCallback? onCreateTask;

  const TaskListWidget({
    super.key,
    required this.tasks,
    required this.projectId,
    this.isLoading = false,
    this.onCreateTask,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (tasks.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _TaskCard(
          task: tasks[index],
          projectId: projectId,
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_alt,
            size: 64,
            color: AppColors.textDisabled,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无任务',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击上方"创建任务"按钮添加第一个任务',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textDisabled,
            ),
          ),
        ],
      ),
    );
  }
}

/// 任务卡片（可展开显示子任务）
class _TaskCard extends StatefulWidget {
  final Task task;
  final int projectId;

  const _TaskCard({
    required this.task,
    required this.projectId,
  });

  @override
  State<_TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<_TaskCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final task = widget.task;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.divider),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 主任务信息
          _buildMainTaskHeader(task),
          // 子任务列表（可展开）
          if (_isExpanded && task.hasChildren) ...[
            const Divider(height: 1),
            _buildSubTaskList(task.children),
          ],
        ],
      ),
    );
  }

  Widget _buildMainTaskHeader(Task task) {
    return InkWell(
      onTap: task.hasChildren
          ? () => setState(() => _isExpanded = !_isExpanded)
          : null,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 第一行：状态 + 任务编号 + 操作按钮
            Row(
              children: [
                _buildStatusDot(task.status),
                const SizedBox(width: 8),
                Text(
                  task.statusDisplay,
                  style: AppTypography.caption.copyWith(
                    color: _getStatusColor(task.status),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  task.displayId,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textDisabled,
                  ),
                ),
                const Spacer(),
                // 查看按钮
                _buildActionButton(
                  icon: Icons.visibility_outlined,
                  tooltip: '查看详情',
                  onTap: () => _viewTaskDetail(task),
                ),
                const SizedBox(width: 8),
                // 添加子任务按钮
                if (task.canCreateSubTask)
                  _buildActionButton(
                    icon: Icons.add,
                    tooltip: '添加子任务',
                    onTap: () => _showCreateSubTaskDialog(task),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // 第二行：任务标题
            Text(
              task.title,
              style: AppTypography.h4.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            // 描述
            if (task.description != null && task.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                task.description!,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            // 第三行：负责人 + 截止时间 + 展开指示器
            Row(
              children: [
                // 负责人
                _buildAssigneeChip(task.assigneeName, task.assigneeAvatar),
                const SizedBox(width: 16),
                // 截止时间
                if (task.endDate != null)
                  _buildDeadlineChip(task.endDate!),
                const Spacer(),
                // 子任务数量/展开按钮
                if (task.hasChildren)
                  _buildExpandButton(task),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubTaskList(List<Task> subTasks) {
    return Container(
      color: AppColors.background.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 子任务标题栏
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Text(
                  '子任务',
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${subTasks.length}',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 子任务项
          ...subTasks.map((subTask) => _buildSubTaskItem(subTask)),
          // 收起按钮
          Padding(
            padding: const EdgeInsets.all(12),
            child: Center(
              child: TextButton.icon(
                onPressed: () => setState(() => _isExpanded = false),
                icon: const Icon(Icons.keyboard_arrow_up, size: 18),
                label: const Text('收起'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubTaskItem(Task subTask) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          _buildStatusDot(subTask.status),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subTask.title,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 14,
                      color: AppColors.textDisabled,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      subTask.assigneeName,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 状态标签
          _buildStatusChip(subTask.status),
        ],
      ),
    );
  }

  Widget _buildStatusDot(String status) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _getStatusText(status),
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildAssigneeChip(String name, String? avatar) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: AppColors.primaryLight,
          backgroundImage: avatar != null ? NetworkImage(avatar) : null,
          child: avatar == null
              ? Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 6),
        Text(
          name,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildDeadlineChip(DateTime deadline) {
    final now = DateTime.now();
    final isOverdue = deadline.isBefore(now);
    final color = isOverdue ? AppColors.error : AppColors.textSecondary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.calendar_today_outlined,
          size: 14,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          isOverdue ? '已逾期' : _formatDate(deadline),
          style: AppTypography.caption.copyWith(
            color: color,
            fontWeight: isOverdue ? FontWeight.w600 : null,
          ),
        ),
      ],
    );
  }

  Widget _buildExpandButton(Task task) {
    return InkWell(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.list,
              size: 14,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              '子任务: ${task.subtaskCount} 完成: ${task.completedSubtaskCount}',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(
            icon,
            size: 16,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'planning':
        return AppColors.statusPlanning;
      case 'pending':
        return AppColors.statusPending;
      case 'in_progress':
        return AppColors.statusInProgress;
      case 'completed':
        return AppColors.statusCompleted;
      default:
        return AppColors.textDisabled;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'planning':
        return '规划中';
      case 'pending':
        return '待处理';
      case 'in_progress':
        return '进行中';
      case 'completed':
        return '已完成';
      default:
        return '未知';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}月${date.day}日';
  }

  void _viewTaskDetail(Task task) {
    // TODO: 导航到任务详情页
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('查看任务详情: ${task.title}')),
    );
  }

  void _showCreateSubTaskDialog(Task parentTask) {
    // TODO: 显示创建子任务对话框
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('为 "${parentTask.title}" 创建子任务')),
    );
  }
}

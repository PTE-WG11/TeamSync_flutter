import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/theme.dart';
import '../../../../core/permissions/permission_service.dart';
import '../../domain/entities/task.dart';
import '../bloc/task_bloc.dart';
import '../bloc/task_event.dart';
import 'task_detail_dialog.dart';

/// 任务列表视图
/// 只显示主任务，子任务作为下拉菜单
class TaskListView extends StatelessWidget {
  final List<Task> tasks;

  const TaskListView({
    super.key,
    required this.tasks,
  });

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return _buildEmptyState();
    }

    // 筛选出主任务
    final mainTasks = tasks.where((t) => t.isMainTask).toList();

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: mainTasks.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final task = mainTasks[index];
        return _MainTaskCard(task: task);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无任务',
            style: AppTypography.h4.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '创建一个新任务开始工作吧',
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MainTaskCard extends StatelessWidget {
  final Task task;

  const _MainTaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final isExpanded = context.select(
      (TaskBloc bloc) => bloc.state.expandedTaskIds.contains(task.id),
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 主任务头部
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 左侧：展开/收起按钮 + 状态圆圈
                Column(
                  children: [
                    // 展开/收起圆圈按钮
                    if (task.hasChildren)
                      InkWell(
                        onTap: () {
                          context.read<TaskBloc>().add(TaskExpandToggled(task.id));
                        },
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isExpanded 
                                ? AppColors.primary.withValues(alpha: 0.1)
                                : AppColors.background,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isExpanded ? AppColors.primary : AppColors.divider,
                            ),
                          ),
                          child: Center(
                            child: AnimatedRotation(
                              turns: isExpanded ? 0.125 : 0,
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                Icons.arrow_drop_down,
                                size: 18,
                                color: isExpanded ? AppColors.primary : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      // 无子任务时显示状态小圆点
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _getStatusColor(task.status).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _getStatusColor(task.status),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                // 右侧：任务信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 第一行：优先级、状态标签、任务编号
                      Row(
                        children: [
                          _buildPriorityBadge(task.priority),
                          const SizedBox(width: 8),
                          _buildStatusBadge(task.status),
                          const Spacer(),
                          Text(
                            task.displayId,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // 任务标题（可点击打开详情）
                      InkWell(
                        onTap: () => _showTaskDetail(context),
                        child: Text(
                          task.title,
                          style: AppTypography.body.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (task.description != null &&
                          task.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
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
                      // 底部信息行
                      Row(
                        children: [
                          // 负责人
                          Row(
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 14,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                task.assigneeName,
                                style: AppTypography.bodySmall,
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          // 时间范围
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 14,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDateRange(task.startDate, task.endDate),
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          // 子任务数量
                          if (task.hasChildren)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.account_tree_outlined,
                                    size: 12,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${task.completedSubtaskCount}/${task.subtaskCount}',
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 子任务列表（展开时显示，缩进在主任务下方）
          if (isExpanded && task.hasChildren) ...[
            const Divider(height: 1),
            Container(
              color: AppColors.background.withValues(alpha: 0.5),
              padding: const EdgeInsets.fromLTRB(52, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: task.children.map((subTask) => _SubTaskItem(
                  subTask: subTask,
                  onToggle: () {
                    context.read<TaskBloc>().add(
                      SubTaskStatusToggled(subTask.id),
                    );
                  },
                )).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;

    switch (status) {
      case 'planning':
        color = AppColors.statusPlanning;
        label = '规划中';
        break;
      case 'pending':
        color = AppColors.statusPending;
        label = '待处理';
        break;
      case 'in_progress':
        color = AppColors.statusInProgress;
        label = '进行中';
        break;
      case 'completed':
        color = AppColors.statusCompleted;
        label = '已完成';
        break;
      default:
        color = AppColors.textSecondary;
        label = '未知';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    Color color;
    String label;

    switch (priority) {
      case 'urgent':
        color = AppColors.error;
        label = '紧急';
        break;
      case 'high':
        color = AppColors.warning;
        label = '高';
        break;
      case 'medium':
        color = AppColors.info;
        label = '中';
        break;
      case 'low':
        color = AppColors.textSecondary;
        label = '低';
        break;
      default:
        color = AppColors.textSecondary;
        label = '中';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getDueDateColor(DateTime dueDate) {
    final now = DateTime.now();
    final diff = dueDate.difference(now).inDays;

    if (diff < 0) return AppColors.error;
    if (diff <= 3) return AppColors.warning;
    return AppColors.textSecondary;
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }

  void _showTaskDetail(BuildContext context) {
    final permissionService = context.read<PermissionService>();
    showDialog(
      context: context,
      builder: (context) => TaskDetailDialog(
        task: task,
        permissionService: permissionService,
        onSubTaskStatusToggle: (subTaskId) {
          context.read<TaskBloc>().add(SubTaskStatusToggled(subTaskId));
        },
        onSubTaskCreate: ({
          required String title,
          String? description,
          String priority = 'medium',
          DateTime? startDate,
          DateTime? endDate,
        }) {
          context.read<TaskBloc>().add(SubTaskCreated(
            parentTaskId: task.id,
            request: CreateSubTaskRequest(
              title: title,
              description: description,
              priority: priority,
              startDate: startDate,
              endDate: endDate,
            ),
          ));
        },
        onEdit: (updatedTask) {
          context.read<TaskBloc>().add(TaskUpdated(
            taskId: updatedTask.id,
            request: UpdateTaskRequest(
              title: updatedTask.title,
              description: updatedTask.description,
              status: updatedTask.status,
              priority: updatedTask.priority,
              assigneeId: updatedTask.assigneeId,
              startDate: updatedTask.startDate,
              endDate: updatedTask.endDate,
            ),
          ));
        },
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
        return AppColors.textSecondary;
    }
  }

  String _formatDateRange(DateTime? start, DateTime? end) {
    if (start != null && end != null) {
      return '${start.month}/${start.day}-${end.month}/${end.day}';
    } else if (start != null) {
      return '${start.month}/${start.day}开始';
    } else if (end != null) {
      return '${end.month}/${end.day}截止';
    }
    return '无截止日期';
  }
}

/// 子任务项（带勾选按钮）
class _SubTaskItem extends StatelessWidget {
  final Task subTask;
  final VoidCallback onToggle;

  const _SubTaskItem({
    required this.subTask,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    // 子任务状态: pending -> in_progress -> completed
    final isInProgress = subTask.status == 'in_progress';
    final isCompleted = subTask.status == 'completed';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          // 勾选按钮
          InkWell(
            onTap: onToggle,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.statusCompleted
                    : isInProgress
                        ? AppColors.statusInProgress.withValues(alpha: 0.2)
                        : AppColors.background,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                  color: isCompleted
                      ? AppColors.statusCompleted
                      : isInProgress
                          ? AppColors.statusInProgress
                          : AppColors.divider,
                ),
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(
                        Icons.check,
                        size: 16,
                        color: AppColors.textInverse,
                      )
                    : isInProgress
                        ? Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.statusInProgress,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          )
                        : null,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 子任务内容
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subTask.title,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w500,
                    decoration: isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                    color: isCompleted
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                  ),
                ),
                if (subTask.description != null &&
                    subTask.description!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subTask.description!,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          // 状态标签
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _getStatusColor(subTask.status).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              _getStatusText(subTask.status),
              style: AppTypography.caption.copyWith(
                color: _getStatusColor(subTask.status),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return AppColors.statusCompleted;
      case 'in_progress':
        return AppColors.statusInProgress;
      case 'pending':
      case 'planning':
        return AppColors.statusPending;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'completed':
        return '已完成';
      case 'in_progress':
        return '进行中';
      case 'pending':
        return '待处理';
      case 'planning':
        return '规划中';
      default:
        return '规划中';
    }
  }
}

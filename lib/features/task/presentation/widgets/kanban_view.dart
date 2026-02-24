import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/theme.dart';
import '../../domain/entities/task.dart';
import '../bloc/task_bloc.dart';
import '../bloc/task_event.dart';
import 'create_subtask_dialog.dart';

/// 任务看板视图
class TaskKanbanView extends StatelessWidget {
  final List<KanbanColumn> columns;

  const TaskKanbanView({
    super.key,
    required this.columns,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: columns.asMap().entries.map((entry) {
        final index = entry.key;
        final column = entry.value;
        final isFirst = index == 0;
        final isLast = index == columns.length - 1;
        
        return Expanded(
          child: _KanbanColumnWidget(
            column: column,
            columnIndex: index,
            canAcceptFromLeft: !isFirst,
            canAcceptFromRight: !isLast,
            onTaskDropped: (taskId, newStatus) {
              context.read<TaskBloc>().add(
                TaskStatusChanged(
                  taskId: taskId,
                  status: newStatus,
                ),
              );
            },
            onCreateSubTask: (parentTask) {
              _showCreateSubTaskDialog(context, parentTask);
            },
          ),
        );
      }).toList(),
    );
  }

  void _showCreateSubTaskDialog(BuildContext context, Task parentTask) {
    showDialog(
      context: context,
      builder: (dialogContext) => CreateSubTaskDialog(
        parentTask: parentTask,
        onCreate: ({
          required String title,
          String? description,
          String priority = 'medium',
          DateTime? startDate,
          DateTime? endDate,
        }) {
          context.read<TaskBloc>().add(SubTaskCreated(
            parentTaskId: parentTask.id,
            request: CreateSubTaskRequest(
              title: title,
              description: description,
              priority: priority,
              startDate: startDate,
              endDate: endDate,
            ),
          ));
        },
      ),
    );
  }
}

class _KanbanColumnWidget extends StatelessWidget {
  final KanbanColumn column;
  final int columnIndex;
  final bool canAcceptFromLeft;
  final bool canAcceptFromRight;
  final Function(int taskId, String newStatus) onTaskDropped;
  final Function(Task parentTask) onCreateSubTask;

  const _KanbanColumnWidget({
    required this.column,
    required this.columnIndex,
    required this.canAcceptFromLeft,
    required this.canAcceptFromRight,
    required this.onTaskDropped,
    required this.onCreateSubTask,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<Task>(
      onWillAcceptWithDetails: (details) {
        // 只允许相邻状态之间的拖拽
        final sourceStatus = details.data.status;
        final targetStatus = column.id;
        
        // 检查是否是相邻状态
        return _isAdjacentStatus(sourceStatus, targetStatus);
      },
      onAcceptWithDetails: (details) {
        onTaskDropped(details.data.id, column.id);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;
        
        return Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isHovered 
                ? Color(column.color).withValues(alpha: 0.1)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: isHovered 
                ? Border.all(color: Color(column.color))
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 列标题
              _buildColumnHeader(),
              // 任务列表
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: column.tasks.length,
                  itemBuilder: (context, index) {
                    final task = column.tasks[index];
                    return _KanbanTaskCard(
                      task: task,
                      onCreateSubTask: task.isMainTask 
                          ? () => onCreateSubTask(task)
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildColumnHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(column.color).withValues(alpha: 0.1),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Color(column.color),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            column.title,
            style: AppTypography.body.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              column.tasks.length.toString(),
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 检查两个状态是否相邻（允许正向和反向流转）
  bool _isAdjacentStatus(String fromStatus, String toStatus) {
    // 状态顺序：planning -> pending -> in_progress -> completed
    final statusOrder = ['planning', 'pending', 'in_progress', 'completed'];
    final fromIndex = statusOrder.indexOf(fromStatus);
    final toIndex = statusOrder.indexOf(toStatus);
    
    if (fromIndex == -1 || toIndex == -1) return false;
    
    // 只允许相邻状态之间流转（相差1）
    return (fromIndex - toIndex).abs() == 1;
  }
}

class _KanbanTaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onCreateSubTask;

  const _KanbanTaskCard({
    required this.task,
    this.onCreateSubTask,
  });

  @override
  Widget build(BuildContext context) {
    return Draggable<Task>(
      data: task,
      feedback: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: SizedBox(
          width: 240,
          child: _buildCardContent(showActions: false),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: _buildCardContent(),
      ),
      child: _buildCardContent(),
    );
  }

  Widget _buildCardContent({bool showActions = true}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 优先级标签 + 任务类型
          Row(
            children: [
              _buildPriorityIndicator(),
              const SizedBox(width: 8),
              if (task.isSubTask)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    '子任务',
                    style: AppTypography.caption.copyWith(
                      fontSize: 10,
                      color: AppColors.primary,
                    ),
                  ),
                ),
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
          // 任务标题
          Text(
            task.title,
            style: AppTypography.body.copyWith(
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          // 底部信息
          Row(
            children: [
              // 负责人头像
              CircleAvatar(
                radius: 12,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  task.assigneeName.isNotEmpty
                      ? task.assigneeName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              // 截止日期
              if (task.endDate != null)
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: _getDueDateColor(task.endDate!),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${task.endDate!.month}/${task.endDate!.day}',
                      style: AppTypography.caption.copyWith(
                        color: _getDueDateColor(task.endDate!),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          // 创建子任务按钮（仅主任务显示）
          if (showActions && onCreateSubTask != null && task.isMainTask) ...[
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            InkWell(
              onTap: onCreateSubTask,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '创建子任务',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriorityIndicator() {
    Color color;
    switch (task.priority) {
      case 'urgent':
        color = AppColors.error;
        break;
      case 'high':
        color = AppColors.warning;
        break;
      case 'medium':
        color = AppColors.info;
        break;
      case 'low':
        color = AppColors.textSecondary;
        break;
      default:
        color = AppColors.textSecondary;
    }

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
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
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/theme.dart';
import '../../domain/entities/task.dart';
import '../bloc/task_bloc.dart';
import '../bloc/task_event.dart';
import 'kanban_task_detail_dialog.dart';
import 'claim_task_time_dialog.dart';

/// 任务看板视图
class TaskKanbanView extends StatelessWidget {
  final List<KanbanColumn> columns;

  const TaskKanbanView({
    super.key,
    required this.columns,
  });

  // 看板列最大宽度
  static const double _maxColumnWidth = 460;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final columnCount = columns.length;
        
        // 计算每个列的宽度：根据屏幕宽度和列数动态计算，但不超过最大宽度
        final calculatedWidth = screenWidth / columnCount;
        final columnWidth = calculatedWidth > _maxColumnWidth ? _maxColumnWidth : calculatedWidth;
        
        // 计算总内容宽度和剩余空间
        final totalContentWidth = columnWidth * columnCount;
        final remainingSpace = screenWidth - totalContentWidth;
        
        // 如果有剩余空间，计算间距（在列之间平均分配）
        final spacing = remainingSpace > 0 ? remainingSpace / (columnCount + 1) : 8.0;
        
        // 构建列列表
        final columnWidgets = columns.asMap().entries.map((entry) {
          final index = entry.key;
          final column = entry.value;
          final isFirst = index == 0;
          final isLast = index == columns.length - 1;
          
          return Container(
            width: columnWidth,
            margin: EdgeInsets.only(
              left: isFirst ? spacing : spacing / 2,
              right: isLast ? spacing : spacing / 2,
            ),
            child: _KanbanColumnWidget(
              column: column,
              columnIndex: index,
              canAcceptFromLeft: !isFirst,
              canAcceptFromRight: !isLast,
              onTaskDropped: (task, newStatus) {
                _handleTaskDropped(context, task, newStatus);
              },
              onViewTaskDetail: (task) {
                _showTaskDetailDialog(context, task);
              },
            ),
          );
        }).toList();
        
        // 使用 Center + SingleChildScrollView 来居中显示并支持滚动
        return Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: columnWidgets,
            ),
          ),
        );
      },
    );
  }

  /// 处理任务拖放
  void _handleTaskDropped(BuildContext context, Task task, String newStatus) {
    // 如果是从 planning 拖出到执行状态
    if (task.status == 'planning' && newStatus != 'planning') {
      // 检查是否已设置结束时间
      if (task.endDate != null) {
        // 已设置结束时间，直接领取任务
        context.read<TaskBloc>().add(
          TaskClaimed(
            taskId: task.id,
            status: newStatus,
            endDate: task.endDate!,
          ),
        );
      } else {
        // 未设置结束时间，弹出选择对话框
        _showEndDatePicker(context, task, newStatus);
      }
    } else {
      // 普通状态变更
      context.read<TaskBloc>().add(
        TaskStatusChanged(
          taskId: task.id,
          status: newStatus,
        ),
      );
    }
  }

  /// 显示认领任务时间选择对话框
  void _showEndDatePicker(BuildContext context, Task task, String newStatus) {
    showDialog(
      context: context,
      builder: (dialogContext) => ClaimTaskTimeDialog(
        onCancel: () => Navigator.pop(dialogContext),
        onConfirm: (endDate) {
          Navigator.pop(dialogContext);
          if (context.mounted) {
            // 调用领取任务接口
            context.read<TaskBloc>().add(
              TaskClaimed(
                taskId: task.id,
                status: newStatus,
                endDate: endDate,
              ),
            );
          }
        },
      ),
    );
  }

  /// 显示任务详情对话框
  void _showTaskDetailDialog(BuildContext context, Task task) {
    final taskBloc = context.read<TaskBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: taskBloc,
        child: KanbanTaskDetailDialog(
          task: task,
          onClose: () => Navigator.pop(dialogContext),
        ),
      ),
    );
  }
}

class _KanbanColumnWidget extends StatelessWidget {
  final KanbanColumn column;
  final int columnIndex;
  final bool canAcceptFromLeft;
  final bool canAcceptFromRight;
  final Function(Task task, String newStatus) onTaskDropped;
  final Function(Task task) onViewTaskDetail;

  const _KanbanColumnWidget({
    required this.column,
    required this.columnIndex,
    required this.canAcceptFromLeft,
    required this.canAcceptFromRight,
    required this.onTaskDropped,
    required this.onViewTaskDetail,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<Task>(
      onWillAcceptWithDetails: (details) {
        final sourceStatus = details.data.status.trim().toLowerCase();
        final targetStatus = column.id.trim().toLowerCase();
        return sourceStatus != targetStatus;
      },
      onAcceptWithDetails: (details) {
        onTaskDropped(details.data, column.id);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;
        
        final highlightColor = Color(column.color).withValues(alpha: 0.15);
        final borderColor = Color(column.color);

        return Container(
          decoration: BoxDecoration(
            color: isHovered 
                ? highlightColor
                : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: isHovered 
                ? Border.all(color: borderColor, width: 2.0)
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
                      onViewDetail: () => onViewTaskDetail(task),
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
}

class _KanbanTaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onViewDetail;

  const _KanbanTaskCard({
    required this.task,
    required this.onViewDetail,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Draggable<Task>(
          data: task,
          feedback: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: SizedBox(
              width: constraints.maxWidth,
              child: _buildCardContent(),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.5,
            child: _buildCardContent(),
          ),
          child: _buildCardContent(),
        );
      },
    );
  }

  Widget _buildCardContent() {
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
          // 优先级标签 + 任务类型 + 查看按钮
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
              // 查看按钮（替代原来的编号）
              InkWell(
                onTap: onViewDetail,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.visibility_outlined,
                        size: 12,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '查看',
                        style: AppTypography.caption.copyWith(
                          fontSize: 10,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
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
              // 负责人头像（无负责人时显示未分配）
              _buildAssigneeAvatar(),
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
        ],
      ),
    );
  }

  Widget _buildAssigneeAvatar() {
    // 无负责人时显示"未分配"
    if (task.assigneeId == 0 || task.assigneeName.isEmpty || task.assigneeName == '未知') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.divider),
        ),
        child: Text(
          '未分配',
          style: AppTypography.caption.copyWith(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    // 检查是否有头像 - 严格检查avatar字段
    final avatarUrl = task.assigneeAvatar;
    final hasAvatar = avatarUrl != null && avatarUrl.trim().isNotEmpty;
    final initial = task.assigneeName.isNotEmpty ? task.assigneeName[0].toUpperCase() : '?';

    if (hasAvatar) {
      // 有头像时显示头像
      return CircleAvatar(
        radius: 12,
        backgroundColor: AppColors.primaryLight,
        backgroundImage: NetworkImage(avatarUrl),
        onBackgroundImageError: (exception, stackTrace) {
          // 头像加载失败时静默处理，显示首字母
          debugPrint('头像加载失败: $avatarUrl, 错误: $exception');
        },
        child: null,
      );
    } else {
      // 无头像时显示首字母
      return CircleAvatar(
        radius: 12,
        backgroundColor: AppColors.primaryLight,
        child: Text(
          initial,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }

  Widget _buildPriorityIndicator() {
    Color color;
    String label;
    switch (task.priority) {
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
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
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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

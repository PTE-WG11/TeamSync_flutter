import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import '../../domain/entities/task.dart';
import 'task_detail_dialog.dart';
import 'create_subtask_dialog.dart';
import '../../../../core/permissions/permission_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../project/domain/entities/project.dart'; // ProjectMember

/// 任务列表组件（可展开子任务）
class TaskListWidget extends StatelessWidget {
  final List<Task> tasks;
  final bool isLoading;
  final int projectId;
  final VoidCallback? onCreateTask;
  final Function(int subTaskId) onSubTaskStatusToggle;
  final Function(int parentTaskId, {
    required String title,
    String? description,
    String priority,
    DateTime? startDate,
    DateTime? endDate,
  }) onSubTaskCreateRequest;
  final Function(Task task) onTaskEdit;
  final List<ProjectMember> members;

  const TaskListWidget({
    super.key,
    required this.tasks,
    required this.projectId,
    this.isLoading = false,
    this.onCreateTask,
    required this.onSubTaskStatusToggle,
    required this.onSubTaskCreateRequest,
    required this.onTaskEdit,
    this.members = const [],
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (tasks.isEmpty) {
      return _buildEmptyState(context);
    }

    // 只显示主任务（或者没有父任务的任务）
    final rootTasks = tasks.where((t) => t.isMainTask || t.parentId == null).toList();

    // 如果过滤后为空但原列表不为空，可能数据结构有问题，或者都是子任务
    // 这里暂时显示所有任务作为 fallback
    final displayTasks = rootTasks.isEmpty && tasks.isNotEmpty ? tasks : rootTasks;

    return ListView.separated(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(), // 允许在 NestedScrollView 中滚动
      itemCount: displayTasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _TaskCard(
          task: displayTasks[index],
          projectId: projectId,
          onSubTaskStatusToggle: onSubTaskStatusToggle,
          onSubTaskCreateRequest: onSubTaskCreateRequest,
          onTaskEdit: onTaskEdit,
          members: members,
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
  final Function(int subTaskId) onSubTaskStatusToggle;
  final Function(int parentTaskId, {
    required String title,
    String? description,
    String priority,
    DateTime? startDate,
    DateTime? endDate,
  }) onSubTaskCreateRequest;
  final Function(Task task) onTaskEdit;
  final List<ProjectMember> members;

  const _TaskCard({
    required this.task,
    required this.projectId,
    required this.onSubTaskStatusToggle,
    required this.onSubTaskCreateRequest,
    required this.onTaskEdit,
    required this.members,
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
                _buildStatusCircle(task.status),
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
          ...subTasks.map((subTask) => _SubTaskCard(
            subTask: subTask,
            onStatusToggle: widget.onSubTaskStatusToggle,
            onCreateSubTask: widget.onSubTaskCreateRequest,
            onEdit: widget.onTaskEdit,
            members: widget.members,
            onViewDetail: (task) => _viewTaskDetail(task), // 传递查看详情回调
          )),
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

  Widget _buildAssigneeChip(String name, String? avatar) {
    final hasAvatar = avatar != null && avatar.trim().isNotEmpty;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: AppColors.primaryLight,
          backgroundImage: hasAvatar ? NetworkImage(avatar) : null,
          onBackgroundImageError: hasAvatar
              ? (exception, stackTrace) {
                  debugPrint('头像加载失败: $avatar, 错误: $exception');
                }
              : null,
          child: hasAvatar
              ? null
              : Text(
                  initial,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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

  Widget _buildStatusCircle(String status) {
    Color color;
    IconData? icon;

    switch (status) {
      case 'planning':
        color = AppColors.statusPlanning;
        icon = null;
        break;
      case 'pending':
        color = AppColors.statusPending;
        icon = Icons.remove;
        break;
      case 'in_progress':
        color = AppColors.statusInProgress;
        icon = Icons.more_horiz;
        break;
      case 'completed':
        color = AppColors.statusCompleted;
        icon = Icons.check;
        break;
      default:
        color = AppColors.statusPlanning;
        icon = null;
    }

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color),
      ),
      child: icon != null
          ? Icon(icon, size: 14, color: color)
          : Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
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

  String _formatDate(DateTime date) {
    return '${date.month}月${date.day}日';
  }

  void _viewTaskDetail(Task task) {
    final permissionService = context.read<PermissionService>();
    showDialog(
      context: context,
      builder: (context) => TaskDetailDialog(
        task: task,
        permissionService: permissionService,
        onSubTaskStatusToggle: widget.onSubTaskStatusToggle,
        onSubTaskCreate: ({
          required String title,
          String? description,
          String priority = 'medium',
          DateTime? startDate,
          DateTime? endDate,
        }) {
          widget.onSubTaskCreateRequest(
            task.id,
            title: title,
            description: description,
            priority: priority,
            startDate: startDate,
            endDate: endDate,
          );
        },
        onEdit: widget.onTaskEdit,
        members: widget.members,
      ),
    );
  }

  void _showCreateSubTaskDialog(Task parentTask) {
    showDialog(
      context: context,
      builder: (context) => CreateSubTaskDialog(
        parentTask: parentTask,
        onCreate: ({
          required String title,
          String? description,
          String priority = 'medium',
          DateTime? startDate,
          DateTime? endDate,
        }) {
          widget.onSubTaskCreateRequest(
            parentTask.id,
            title: title,
            description: description,
            priority: priority,
            startDate: startDate,
            endDate: endDate,
          );
        },
      ),
    );
  }
}

/// 子任务卡片（支持递归显示）
class _SubTaskCard extends StatefulWidget {
  final Task subTask;
  final Function(int subTaskId) onStatusToggle;
  final Function(int parentTaskId, {
    required String title,
    String? description,
    String priority,
    DateTime? startDate,
    DateTime? endDate,
  }) onCreateSubTask;
  final Function(Task task) onEdit;
  final Function(Task task) onViewDetail;
  final List<ProjectMember> members;

  const _SubTaskCard({
    required this.subTask,
    required this.onStatusToggle,
    required this.onCreateSubTask,
    required this.onEdit,
    required this.onViewDetail,
    required this.members,
  });

  @override
  State<_SubTaskCard> createState() => _SubTaskCardState();
}

class _SubTaskCardState extends State<_SubTaskCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    // 检查权限：只有负责人可以编辑
    final permissionService = context.read<PermissionService>();
    final currentUserId = permissionService.currentUserId;
    final canEdit = widget.subTask.assigneeId.toString() == currentUserId;
    final hasChildren = widget.subTask.children.isNotEmpty;

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              // 展开/收起图标 (如果有子任务)
              if (hasChildren)
                InkWell(
                  onTap: () => setState(() => _isExpanded = !_isExpanded),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      _isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              else
                const SizedBox(width: 28), // 占位，保持对齐

              // 状态切换圆圈 (勾选按钮)
              InkWell(
                onTap: canEdit
                    ? () => widget.onStatusToggle(widget.subTask.id)
                    : null,
                child: _buildStatusCircle(widget.subTask.status),
              ),
              const SizedBox(width: 12),
              
              // 子任务内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.subTask.title,
                            style: AppTypography.body.copyWith(
                              fontWeight: FontWeight.w500,
                              decoration: widget.subTask.status == 'completed'
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: widget.subTask.status == 'completed'
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildPriorityChip(widget.subTask.priority),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // 子任务描述
                    if (widget.subTask.description != null && widget.subTask.description!.isNotEmpty) ...[
                      Text(
                        widget.subTask.description!,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                    ],
                    Row(
                      children: [
                        _buildSubTaskAssigneeAvatar(widget.subTask.assigneeName, widget.subTask.assigneeAvatar),
                        const SizedBox(width: 4),
                        Text(
                          widget.subTask.assigneeName,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // 操作按钮 (查看/添加子任务)
              _buildActionButton(
                icon: Icons.visibility_outlined, 
                tooltip: '查看详情',
                label: '详情',
                onTap: () => widget.onViewDetail(widget.subTask),
              ),
              const SizedBox(width: 4),

              if (widget.subTask.canCreateSubTask)
                 Tooltip(
                  message: '添加子任务',
                  child: InkWell(
                    onTap: () => _showCreateSubTaskDialog(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.add, size: 18, color: AppColors.primary),
                    ),
                  ),
                 ),

              // 状态标签
              // _buildStatusChip(widget.subTask.status),
            ],
          ),
        ),
        
        // 递归显示子任务的子任务 (孙任务)
        if (_isExpanded && hasChildren)
          Padding(
            padding: const EdgeInsets.only(left: 32), // 缩进显示层级关系
            child: Column(
              children: widget.subTask.children.map((child) => _SubTaskCard(
                subTask: child,
                onStatusToggle: widget.onStatusToggle,
                onCreateSubTask: widget.onCreateSubTask,
                onEdit: widget.onEdit,
                onViewDetail: widget.onViewDetail,
                members: widget.members,
              )).toList(),
            ),
          ),
      ],
    );
  }

  void _showCreateSubTaskDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CreateSubTaskDialog(
        parentTask: widget.subTask,
        onCreate: ({
          required String title,
          String? description,
          String priority = 'medium',
          DateTime? startDate,
          DateTime? endDate,
        }) {
          widget.onCreateSubTask(
            widget.subTask.id,
            title: title,
            description: description,
            priority: priority,
            startDate: startDate,
            endDate: endDate,
          );
        },
      ),
    );
  }

  Widget _buildStatusCircle(String status) {
    Color color;
    IconData? icon;

    switch (status) {
      case 'planning':
        color = AppColors.statusPlanning;
        icon = null;
        break;
      case 'pending':
        color = AppColors.statusPending;
        icon = Icons.remove;
        break;
      case 'in_progress':
        color = AppColors.statusInProgress;
        icon = Icons.more_horiz;
        break;
      case 'completed':
        color = AppColors.statusCompleted;
        icon = Icons.check;
        break;
      default:
        color = AppColors.statusPlanning;
        icon = null;
    }

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color),
      ),
      child: icon != null
          ? Icon(icon, size: 14, color: color)
          : Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
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

  Widget _buildPriorityChip(String priority) {
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
        color = AppColors.success;
        label = '低';
        break;
      default:
        color = AppColors.textSecondary;
        label = '无';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    String? label,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: AppColors.textSecondary,
              ),
              if (label != null) ...[
                const SizedBox(width: 2),
                Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 构建子任务负责人头像
  Widget _buildSubTaskAssigneeAvatar(String name, String? avatar) {
    final hasAvatar = avatar != null && avatar.trim().isNotEmpty;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return CircleAvatar(
      radius: 8,
      backgroundColor: AppColors.primaryLight,
      backgroundImage: hasAvatar ? NetworkImage(avatar) : null,
      child: hasAvatar
          ? null
          : Text(
              initial,
              style: const TextStyle(
                fontSize: 7,
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
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
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/theme.dart';
import '../../../../core/permissions/permission_service.dart';
import '../../../attachment/data/repositories/attachment_repository_impl.dart';
import '../../../attachment/domain/entities/attachment.dart';
import '../../../attachment/presentation/widgets/attachment_uploader.dart';
import '../../data/repositories/task_repository_impl.dart';
import '../../domain/entities/task.dart';
import 'create_subtask_dialog.dart';
import 'create_task_dialog.dart';
import '../../../project/domain/entities/project.dart'; // for ProjectMember

/// 任务详情对话框
class TaskDetailDialog extends StatefulWidget {
  final Task task;
  final PermissionService permissionService;
  final Function(Task task) onEdit; // 编辑任务回调
  final Function(int subTaskId) onSubTaskStatusToggle; // 子任务状态切换回调
  final CreateSubTaskCallback onSubTaskCreate; // 创建子任务回调
  final List<ProjectMember> members; // 成员列表，用于编辑任务时选择负责人

  const TaskDetailDialog({
    super.key,
    required this.task,
    required this.permissionService,
    required this.onEdit,
    required this.onSubTaskStatusToggle,
    required this.onSubTaskCreate,
    this.members = const [],
  });

  @override
  State<TaskDetailDialog> createState() => _TaskDetailDialogState();
}

class _TaskDetailDialogState extends State<TaskDetailDialog> {
  late List<Attachment> _attachments;

  @override
  void initState() {
    super.initState();
    // 从任务对象中获取附件列表
    _attachments = widget.task.attachments;
    // 异步加载最新任务详情（包含最新附件）
    _loadTaskDetail();
  }

  Future<void> _loadTaskDetail() async {
    try {
      final repository = TaskRepositoryImpl();
      final task = await repository.getTaskDetail(widget.task.id);
      if (mounted) {
        setState(() {
          _attachments = task.attachments;
        });
      }
    } catch (e) {
      debugPrint('加载任务详情失败: $e');
    }
  }


  /// 判断当前用户是否可以编辑主任务
  bool get _canEditMainTask {
    // 管理员可以编辑任何主任务
    if (widget.permissionService.isAdmin) return true;
    // 成员只能编辑自己负责的任务
    return widget.task.assigneeId.toString() ==
        widget.permissionService.currentUserId;
  }

  /// 判断当前用户是否可以创建子任务
  bool get _canCreateSubTask {
    // 只有任务的负责人可以创建子任务（无论管理员还是成员）
    return widget.task.assigneeId.toString() ==
        widget.permissionService.currentUserId;
  }

  /// 判断是否可以编辑子任务
  bool _canEditSubTask(Task subTask) {
    // 子任务只能由自己的负责人编辑
    return subTask.assigneeId.toString() ==
        widget.permissionService.currentUserId;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Container(
        width: 720,
        constraints: const BoxConstraints(maxHeight: 800),
        child: Column(
          children: [
            // 头部
            _buildHeader(),
            const Divider(height: 1),
            // 内容区
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 任务信息
                    _buildTaskInfo(),
                    const SizedBox(height: 24),
                    // 附件区域
                    _buildAttachmentsSection(),
                    const SizedBox(height: 24),
                    // 子任务区域
                    _buildSubTasksSection(),
                  ],
                ),
              ),
            ),
            // 底部按钮
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildStatusBadge(widget.task.status),
                    const SizedBox(width: 8),
                    _buildPriorityBadge(widget.task.priority),
                    const SizedBox(width: 8),
                    Text(
                      widget.task.displayId,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.task.title,
                  style: AppTypography.h4,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 描述
        if (widget.task.description != null &&
            widget.task.description!.isNotEmpty) ...[
          Text(
            '任务描述',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.task.description!,
            style: AppTypography.body,
          ),
          const SizedBox(height: 16),
        ],
        // 负责人
        _buildInfoRow(
          icon: Icons.person_outline,
          label: '负责人',
          value: widget.task.assigneeName,
        ),
        const SizedBox(height: 12),
        // 时间范围
        if (widget.task.startDate != null || widget.task.endDate != null)
          _buildInfoRow(
            icon: Icons.calendar_today_outlined,
            label: '时间范围',
            value: _formatDateRange(widget.task.startDate, widget.task.endDate),
          ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: AppTypography.bodySmall,
        ),
      ],
    );
  }

  String _formatDateRange(DateTime? start, DateTime? end) {
    if (start != null && end != null) {
      return '${_formatDate(start)} 至 ${_formatDate(end)}';
    } else if (start != null) {
      return '从 ${_formatDate(start)} 开始';
    } else if (end != null) {
      return '截止至 ${_formatDate(end)}';
    }
    return '未设置';
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Widget _buildAttachmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.attach_file,
                size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              '附件 (${_attachments.length})',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AttachmentUploader(
            taskId: widget.task.id,
            taskAssigneeId: widget.task.assigneeId,
            permissionService: widget.permissionService,
            repository: AttachmentRepositoryImpl(),
            existingAttachments: _attachments,
            onAttachmentsChanged: (attachments) {
              setState(() => _attachments = attachments);
            },
          ),
      ],
    );
  }

  Widget _buildSubTasksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.account_tree_outlined,
                size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              '子任务 (${widget.task.children.length})',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (_canCreateSubTask)
              TextButton.icon(
                onPressed: () => _showCreateSubTaskDialog(),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('添加子任务'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (widget.task.children.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Center(
              child: Text(
                '暂无子任务',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          )
        else
          ...widget.task.children.map((subTask) => _buildSubTaskItem(subTask)),
      ],
    );
  }

  Widget _buildSubTaskItem(Task subTask) {
    final canEdit = _canEditSubTask(subTask);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          // 状态切换圆圈
          InkWell(
            onTap: canEdit
                ? () {
                    widget.onSubTaskStatusToggle(subTask.id);
                    // 刷新当前对话框
                    setState(() {});
                  }
                : null,
            child: _buildStatusCircle(subTask.status),
          ),
          const SizedBox(width: 12),
          // 子任务内容
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subTask.title,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w500,
                    decoration: subTask.status == 'completed'
                        ? TextDecoration.lineThrough
                        : null,
                    color: subTask.status == 'completed'
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                  ),
                ),
                if (subTask.description != null &&
                    subTask.description!.isNotEmpty)
                  Text(
                    subTask.description!,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          // 负责人
          Text(
            subTask.assigneeName,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
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

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
          if (_canEditMainTask) ...[
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showEditTaskDialog();
              },
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('编辑任务'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textInverse,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showEditTaskDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateTaskDialog(
        projectId: widget.task.projectId,
        members: widget.members,
        task: widget.task,
        onCreate: ({
          required String title,
          String? description,
          required int assigneeId,
          String priority = 'medium',
          DateTime? startDate,
          DateTime? endDate,
        }) {
          // 这里虽然叫 onCreate，但对于编辑模式，我们需要调用 onEdit 回调
          // CreateTaskDialog 返回的数据结构是一样的，我们需要组装成 Task 对象
          final updatedTask = widget.task.copyWith(
            title: title,
            description: description,
            assigneeId: assigneeId,
            priority: priority,
            startDate: startDate,
            endDate: endDate,
          );
          widget.onEdit(updatedTask);
        },
      ),
    );
  }

  void _showCreateSubTaskDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateSubTaskDialog(
        parentTask: widget.task,
        onCreate: widget.onSubTaskCreate,
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
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
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
}

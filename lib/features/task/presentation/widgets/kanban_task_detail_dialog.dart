import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/theme.dart';
import '../../domain/entities/task.dart';
import '../bloc/task_bloc.dart';
import '../bloc/task_event.dart';

/// 看板任务详情对话框（支持查看和编辑）
class KanbanTaskDetailDialog extends StatefulWidget {
  final Task task;
  final VoidCallback onClose;

  const KanbanTaskDetailDialog({
    super.key,
    required this.task,
    required this.onClose,
  });

  @override
  State<KanbanTaskDetailDialog> createState() => _KanbanTaskDetailDialogState();
}

class _KanbanTaskDetailDialogState extends State<KanbanTaskDetailDialog> {
  late bool _isEditing;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late String _selectedPriority;
  late String _selectedStatus;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isSaving = false;
  bool _isDeleting = false;

  final List<Map<String, dynamic>> _priorityOptions = [
    {'value': 'urgent', 'label': '紧急', 'color': AppColors.error},
    {'value': 'high', 'label': '高', 'color': AppColors.warning},
    {'value': 'medium', 'label': '中', 'color': AppColors.info},
    {'value': 'low', 'label': '低', 'color': AppColors.textSecondary},
  ];

  final List<Map<String, dynamic>> _statusOptions = [
    {'value': 'planning', 'label': '规划中', 'color': AppColors.statusPlanning},
    {'value': 'pending', 'label': '待处理', 'color': AppColors.statusPending},
    {'value': 'in_progress', 'label': '进行中', 'color': AppColors.statusInProgress},
    {'value': 'completed', 'label': '已完成', 'color': AppColors.statusCompleted},
  ];

  @override
  void initState() {
    super.initState();
    _isEditing = false;
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(text: widget.task.description ?? '');
    _selectedPriority = widget.task.priority;
    _selectedStatus = widget.task.status;
    _startDate = widget.task.startDate;
    _endDate = widget.task.endDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        // 取消编辑时恢复原始值
        _titleController.text = widget.task.title;
        _descriptionController.text = widget.task.description ?? '';
        _selectedPriority = widget.task.priority;
        _selectedStatus = widget.task.status;
        _startDate = widget.task.startDate;
        _endDate = widget.task.endDate;
      }
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final initialDate = isStartDate ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _saveTask() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('任务标题不能为空')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final request = UpdateTaskRequest(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      priority: _selectedPriority,
      status: _selectedStatus,
      startDate: _startDate,
      endDate: _endDate,
    );

    context.read<TaskBloc>().add(
      TaskUpdated(
        taskId: widget.task.id,
        request: request,
      ),
    );

    // 延迟关闭，让 BLoC 处理完成
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        widget.onClose();
      }
    });
  }

  void _deleteTask() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除任务"${widget.task.title}"吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _confirmDelete();
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete() {
    setState(() {
      _isDeleting = true;
    });

    context.read<TaskBloc>().add(
      TaskDeleted(widget.task.id),
    );

    // 延迟关闭，让 BLoC 处理完成
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        widget.onClose();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头部
            _buildHeader(),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            // 内容区
            Flexible(
              child: SingleChildScrollView(
                child: _isEditing ? _buildEditForm() : _buildViewContent(),
              ),
            ),
            const SizedBox(height: 16),
            // 底部按钮
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: _isEditing
              ? TextField(
                  controller: _titleController,
                  style: AppTypography.h4,
                  decoration: InputDecoration(
                    hintText: '任务标题',
                    hintStyle: AppTypography.h4.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  maxLines: 2,
                )
              : Text(
                  widget.task.title,
                  style: AppTypography.h4,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
        ),
        Row(
          children: [
            if (!_isEditing) ...[
              // 编辑按钮
              IconButton(
                onPressed: _toggleEditMode,
                icon: const Icon(Icons.edit_outlined, size: 20),
                tooltip: '编辑',
              ),
              // 删除按钮
              IconButton(
                onPressed: _isDeleting ? null : _deleteTask,
                icon: _isDeleting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                tooltip: '删除',
              ),
            ],
            IconButton(
              onPressed: widget.onClose,
              icon: const Icon(Icons.close, size: 20),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildViewContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 状态 + 优先级
        Row(
          children: [
            _buildStatusBadge(widget.task.status),
            const SizedBox(width: 12),
            _buildPriorityBadge(widget.task.priority),
          ],
        ),
        const SizedBox(height: 20),
        // 信息行
        _buildInfoRow('所属项目', widget.task.project?.title ?? '未知项目'),
        _buildInfoRow('任务类型', widget.task.isMainTask ? '主任务' : '子任务'),
        _buildInfoRow(
          '负责人',
          widget.task.assigneeName.isNotEmpty ? widget.task.assigneeName : '未分配',
        ),
        _buildInfoRow(
          '创建者',
          widget.task.createdByName.isNotEmpty ? widget.task.createdByName : '未知',
        ),
        if (widget.task.startDate != null)
          _buildInfoRow('开始时间', _formatDate(widget.task.startDate!)),
        if (widget.task.endDate != null)
          _buildInfoRow('截止时间', _formatDate(widget.task.endDate!)),
        // 逾期标记（仅当 overdue 时显示）
        if (widget.task.normalFlag == 'overdue')
          _buildInfoRowWithColor('状态标记', '逾期', AppColors.error),
        _buildInfoRow('创建时间', _formatDate(widget.task.createdAt)),
        const SizedBox(height: 20),
        // 任务描述
        Text(
          '任务描述',
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Text(
            widget.task.description?.isNotEmpty == true
                ? widget.task.description!
                : '暂无描述',
            style: AppTypography.body.copyWith(
              color: widget.task.description?.isNotEmpty == true
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 优先级选择
        Text(
          '优先级',
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _priorityOptions.map((option) {
            final isSelected = _selectedPriority == option['value'];
            return ChoiceChip(
              label: Text(option['label']),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _selectedPriority = option['value'];
                });
              },
              selectedColor: (option['color'] as Color).withOpacity(0.2),
              backgroundColor: AppColors.background,
              labelStyle: TextStyle(
                color: isSelected ? option['color'] : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        // 状态选择
        Text(
          '状态',
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _statusOptions.map((option) {
            final isSelected = _selectedStatus == option['value'];
            return ChoiceChip(
              label: Text(option['label']),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _selectedStatus = option['value'];
                });
              },
              selectedColor: (option['color'] as Color).withOpacity(0.2),
              backgroundColor: AppColors.background,
              labelStyle: TextStyle(
                color: isSelected ? option['color'] : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        // 日期选择
        Row(
          children: [
            Expanded(
              child: _buildDatePickerField('开始日期', _startDate, true),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDatePickerField('截止日期', _endDate, false),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // 任务描述
        Text(
          '任务描述',
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _descriptionController,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: '请输入任务描述...',
            hintStyle: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: AppColors.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: AppColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            filled: true,
            fillColor: AppColors.background,
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePickerField(String label, DateTime? date, bool isStartDate) {
    return InkWell(
      onTap: () => _selectDate(context, isStartDate),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: date != null ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  date != null ? _formatDate(date) : '未设置',
                  style: AppTypography.bodySmall.copyWith(
                    color: date != null ? AppColors.textPrimary : AppColors.textSecondary,
                    fontWeight: date != null ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    if (_isEditing) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _isSaving ? null : _toggleEditMode,
            child: const Text('取消'),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: _isSaving ? null : _saveTask,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('保存'),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: widget.onClose,
          child: const Text('关闭'),
        ),
      ],
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
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
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
        label = priority;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRowWithColor(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

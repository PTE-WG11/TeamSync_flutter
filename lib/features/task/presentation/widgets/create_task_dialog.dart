import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import '../../../project/domain/entities/project.dart';
import '../../domain/entities/task.dart';

/// 创建任务回调
typedef CreateTaskCallback = void Function({
  required String title,
  String? description,
  required int assigneeId,
  String priority,
  DateTime? startDate,
  DateTime? endDate,
});

/// 创建任务对话框
class CreateTaskDialog extends StatefulWidget {
  final int projectId;
  final List<ProjectMember> members;
  final CreateTaskCallback onCreate;
  final Task? task; // 编辑模式下的初始任务数据

  const CreateTaskDialog({
    super.key,
    required this.projectId,
    required this.members,
    required this.onCreate,
    this.task,
  });

  @override
  State<CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends State<CreateTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  
  int? _selectedAssigneeId;
  String _selectedPriority = 'medium';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title);
    _descriptionController = TextEditingController(text: widget.task?.description);
    
    if (widget.task != null) {
      _selectedAssigneeId = widget.task!.assigneeId;
      _selectedPriority = widget.task!.priority;
      _startDate = widget.task!.startDate;
      _endDate = widget.task!.endDate;
    }
  }

  final List<Map<String, dynamic>> _priorityOptions = [
    {'value': 'urgent', 'label': '紧急', 'color': AppColors.error},
    {'value': 'high', 'label': '高', 'color': AppColors.statusPending},
    {'value': 'medium', 'label': '中', 'color': AppColors.statusInProgress},
    {'value': 'low', 'label': '低', 'color': AppColors.statusPlanning},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Container(
        width: 560,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('创建任务', style: AppTypography.h4),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // 内容区（可滚动）
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 任务标题
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: '任务标题 *',
                          hintText: '请输入任务标题',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '请输入任务标题';
                          }
                          if (value.trim().length < 2) {
                            return '标题至少2个字符';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // 任务描述
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: '任务描述',
                          hintText: '请输入任务描述（可选）',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // 负责人选择
                      _buildAssigneeSection(),
                      const SizedBox(height: 20),
                      // 优先级选择
                      _buildPrioritySection(),
                      const SizedBox(height: 20),
                      // 时间选择
                      _buildDateSection(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // 按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textInverse,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('创建任务'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssigneeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '负责人 *',
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.members.map((member) {
            final isSelected = _selectedAssigneeId == member.id;
            return InkWell(
              onTap: () => setState(() => _selectedAssigneeId = member.id),
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.divider,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMemberAvatar(member),
                    const SizedBox(width: 8),
                    Text(
                      member.username,
                      style: AppTypography.bodySmall.copyWith(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                        fontWeight:
                            isSelected ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.check_circle,
                        size: 14,
                        color: AppColors.primary,
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        if (_selectedAssigneeId == null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '请选择负责人',
              style: AppTypography.caption.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
      ],
    );
  }

  /// 构建成员头像
  Widget _buildMemberAvatar(ProjectMember member) {
    final hasAvatar = member.avatar != null && member.avatar!.trim().isNotEmpty;
    final initial = member.username.isNotEmpty ? member.username[0].toUpperCase() : '?';

    return CircleAvatar(
      radius: 12,
      backgroundColor: AppColors.primaryLight,
      backgroundImage: hasAvatar ? NetworkImage(member.avatar!) : null,
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
    );
  }

  Widget _buildPrioritySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '优先级',
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _priorityOptions.map((option) {
            final isSelected = _selectedPriority == option['value'];
            return InkWell(
              onTap: () =>
                  setState(() => _selectedPriority = option['value'] as String),
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (option['color'] as Color).withValues(alpha: 0.1)
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: isSelected
                        ? option['color'] as Color
                        : AppColors.divider,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: option['color'] as Color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      option['label'] as String,
                      style: AppTypography.bodySmall.copyWith(
                        color: isSelected
                            ? option['color'] as Color
                            : AppColors.textPrimary,
                        fontWeight:
                            isSelected ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '时间范围',
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _selectDate(isStart: true),
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
                        '开始日期',
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
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _startDate != null
                                ? _formatDate(_startDate!)
                                : '选择日期',
                            style: AppTypography.bodySmall.copyWith(
                              color: _startDate != null
                                  ? AppColors.textPrimary
                                  : AppColors.textDisabled,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.arrow_forward, size: 16, color: AppColors.textDisabled),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () => _selectDate(isStart: false),
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
                        '截止日期',
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
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _endDate != null
                                ? _formatDate(_endDate!)
                                : '选择日期',
                            style: AppTypography.bodySmall.copyWith(
                              color: _endDate != null
                                  ? AppColors.textPrimary
                                  : AppColors.textDisabled,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _selectDate({required bool isStart}) async {
    final now = DateTime.now();
    final initialDate = isStart
        ? (_startDate ?? now)
        : (_endDate ?? _startDate?.add(const Duration(days: 7)) ?? now);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.textInverse,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAssigneeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择负责人')),
      );
      return;
    }

    widget.onCreate(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      assigneeId: _selectedAssigneeId!,
      priority: _selectedPriority,
      startDate: _startDate,
      endDate: _endDate,
    );

    Navigator.pop(context);
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

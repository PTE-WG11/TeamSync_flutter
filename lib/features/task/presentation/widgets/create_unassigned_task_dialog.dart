import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import '../../../project/domain/entities/project.dart';

/// 创建无负责人任务回调
typedef CreateUnassignedTaskCallback = void Function({
  required int projectId,
  required String title,
  String? description,
  String priority,
});

/// 创建无负责人任务对话框（看板中快速创建）
class CreateUnassignedTaskDialog extends StatefulWidget {
  final List<Project> projects;
  final CreateUnassignedTaskCallback onCreate;

  const CreateUnassignedTaskDialog({
    super.key,
    required this.projects,
    required this.onCreate,
  });

  @override
  State<CreateUnassignedTaskDialog> createState() => _CreateUnassignedTaskDialogState();
}

class _CreateUnassignedTaskDialogState extends State<CreateUnassignedTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  int? _selectedProjectId;
  String _selectedPriority = 'medium';

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
        width: 480,
        constraints: const BoxConstraints(maxHeight: 600),
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
                      // 项目选择
                      _buildProjectSection(),
                      const SizedBox(height: 20),
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
                      // 优先级选择
                      _buildPrioritySection(),
                      const SizedBox(height: 12),
                      // 提示信息
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: AppColors.info,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '创建后任务状态默认为"规划中"，可在看板中拖拽领取',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.info,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildProjectSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '所属项目 *',
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: _selectedProjectId,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          hint: const Text('请选择项目'),
          items: widget.projects.map((project) {
            return DropdownMenuItem(
              value: project.id,
              child: Text(
                project.title,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedProjectId = value);
          },
          validator: (value) {
            if (value == null) {
              return '请选择项目';
            }
            return null;
          },
        ),
      ],
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
                      ? (option['color'] as Color).withOpacity(0.1)
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

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    widget.onCreate(
      projectId: _selectedProjectId!,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      priority: _selectedPriority,
    );

    Navigator.pop(context);
  }
}

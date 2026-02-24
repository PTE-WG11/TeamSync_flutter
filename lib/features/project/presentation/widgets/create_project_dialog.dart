import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../config/theme.dart';
import '../../domain/entities/project.dart';
import '../bloc/project_bloc.dart';
import '../bloc/project_event.dart';
import '../bloc/project_state.dart';

/// 创建/编辑项目弹窗
class CreateProjectDialog extends StatefulWidget {
  final dynamic project; // 如果传入 project，则为编辑模式

  const CreateProjectDialog({
    super.key,
    this.project,
  });

  @override
  State<CreateProjectDialog> createState() => _CreateProjectDialogState();
}

class _CreateProjectDialogState extends State<CreateProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  
  DateTime? _startDate;
  DateTime? _endDate;
  String _status = 'planning';
  final List<int> _selectedMemberIds = [];

  bool get isEditing => widget.project != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.project?.title ?? '');
    _descriptionController = TextEditingController(text: widget.project?.description ?? '');
    
    if (isEditing) {
      _status = widget.project.status;
      // 假设 project.startDate 和 endDate 是 DateTime 类型或 String
      // 这里需要根据实际 project 对象结构适配
      // _startDate = widget.project.startDate;
      // _endDate = widget.project.endDate;
      // _selectedMemberIds.addAll(widget.project.members.map((m) => m.id));
    }

    // 加载可用成员列表
    context.read<ProjectBloc>().add(const ProjectAvailableMembersRequested());
  }

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
        borderRadius: BorderRadius.circular(AppRadius.xxl),
      ),
      child: Container(
        width: 560,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 弹窗头部
            _buildHeader(),
            const Divider(height: 1),
            // 弹窗内容
            Flexible(
              child: BlocListener<ProjectBloc, ProjectState>(
                listenWhen: (previous, current) => 
                  current is ProjectCreateSuccess || 
                  current is ProjectCreateFailure ||
                  current is ProjectUpdateSuccess ||
                  current is ProjectUpdateFailure,
                listener: (context, state) {
                  if (state is ProjectCreateSuccess) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('项目 "${state.project.title}" 创建成功'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  } else if (state is ProjectUpdateSuccess) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('项目 "${state.project.title}" 更新成功'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                },
                child: BlocBuilder<ProjectBloc, ProjectState>(
                  builder: (context, state) {
                    if (state is ProjectCreateFormState && state.availableMembers.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    if (state is ProjectCreateFailure) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: AppColors.error),
                            const SizedBox(height: 16),
                            Text(state.message),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('关闭'),
                            ),
                          ],
                        ),
                      );
                    }

                    if (state is ProjectCreateSuccess || state is ProjectUpdateSuccess) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text(isEditing ? '更新成功，正在刷新...' : '创建成功，正在刷新...'),
                          ],
                        ),
                      );
                    }

                    final members = state is ProjectCreateFormState 
                        ? state.availableMembers 
                        : <ProjectMember>[];

                    return _buildForm(members, state is ProjectCreateFormState && state.isSubmitting);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建弹窗头部
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(isEditing ? '编辑项目' : '创建新项目', style: AppTypography.h4),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  /// 构建表单
  Widget _buildForm(List<ProjectMember> members, bool isSubmitting) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 项目名称
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: '项目名称 *',
                hintText: '请输入项目名称',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入项目名称';
                }
                if (value.length > 100) {
                  return '项目名称不能超过100个字符';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // 项目描述
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: '项目描述',
                hintText: '请输入项目描述（可选）',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            // 项目状态
            _buildStatusSelector(),
            const SizedBox(height: 16),
            // 日期选择
            Row(
              children: [
                Expanded(
                  child: _buildDatePicker(
                    label: '开始日期',
                    date: _startDate,
                    onSelect: (date) => setState(() => _startDate = date),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDatePicker(
                    label: '结束日期',
                    date: _endDate,
                    onSelect: (date) => setState(() => _endDate = date),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // 成员选择
            Text('分配成员 *', style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('至少选择1名成员', style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            _buildMemberSelector(members),
            const SizedBox(height: 24),
            // 底部按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: isSubmitting ? null : _submit,
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isEditing ? '保存修改' : '创建项目'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建状态选择器
  Widget _buildStatusSelector() {
    final statusOptions = [
      {'value': 'planning', 'label': '规划中', 'color': AppColors.statusPlanning},
      {'value': 'pending', 'label': '待处理', 'color': AppColors.statusPending},
      {'value': 'in_progress', 'label': '进行中', 'color': AppColors.statusInProgress},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('项目状态', style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          children: statusOptions.map((option) {
            final value = option['value']! as String;
            final label = option['label']! as String;
            final isSelected = _status == value;
            final color = option['color'] as Color;
            return ChoiceChip(
              label: Text(label),
              selected: isSelected,
              selectedColor: color.withValues(alpha: 0.1),
              backgroundColor: AppColors.background,
              labelStyle: TextStyle(
                color: isSelected ? color : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : null,
              ),
              side: BorderSide(
                color: isSelected ? color : AppColors.border,
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() => _status = value);
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 构建日期选择器
  Widget _buildDatePicker({
    required String label,
    required DateTime? date,
    required ValueChanged<DateTime> onSelect,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: AppColors.primary,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              onSelect(picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  date != null ? DateFormat('yyyy-MM-dd').format(date) : '选择日期',
                  style: AppTypography.body.copyWith(
                    color: date != null ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 构建成员选择器
  Widget _buildMemberSelector(List<ProjectMember> members) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: members.map((member) {
          final isSelected = _selectedMemberIds.contains(member.id);
          return FilterChip(
            label: Text(member.username),
            selected: isSelected,
            selectedColor: AppColors.primaryLight,
            checkmarkColor: AppColors.primary,
            onSelected: (selected) {
              setState(() {
                if (selected) {
                  _selectedMemberIds.add(member.id);
                } else {
                  _selectedMemberIds.remove(member.id);
                }
              });
            },
            avatar: CircleAvatar(
              radius: 12,
              backgroundColor: AppColors.primary,
              child: Text(
                member.username[0],
                style: const TextStyle(
                  color: AppColors.textInverse,
                  fontSize: 12,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 提交表单
  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedMemberIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少选择1名成员')),
      );
      return;
    }

    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final startDate = _startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : null;
    final endDate = _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : null;

    if (isEditing) {
      context.read<ProjectBloc>().add(ProjectUpdateRequested(
        projectId: widget.project.id,
        title: title,
        description: description,
        status: _status,
        startDate: startDate,
        endDate: endDate,
      ));
      // 如果成员有变更，可能需要单独调用成员更新接口，视后端实现而定
      // 这里假设 ProjectUpdateRequested 不包含成员更新，或者我们补充调用
      // context.read<ProjectBloc>().add(ProjectMembersUpdateRequested(...));
    } else {
      context.read<ProjectBloc>().add(ProjectCreateRequested(
        title: title,
        description: description,
        status: _status,
        startDate: startDate,
        endDate: endDate,
        memberIds: _selectedMemberIds,
      ));
    }
  }
}

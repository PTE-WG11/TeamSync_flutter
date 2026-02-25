import 'package:flutter/material.dart';
import '../../../../config/theme.dart';

/// 认领任务时间选择对话框
/// 选择预计完成工时（小时+分钟），自动计算结束时间
class ClaimTaskTimeDialog extends StatefulWidget {
  final VoidCallback onCancel;
  final Function(DateTime endDate) onConfirm;

  const ClaimTaskTimeDialog({
    super.key,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  State<ClaimTaskTimeDialog> createState() => _ClaimTaskTimeDialogState();
}

class _ClaimTaskTimeDialogState extends State<ClaimTaskTimeDialog> {
  int _hours = 8; // 默认8小时
  int _minutes = 0;

  // 快速选择选项
  final List<Map<String, dynamic>> _quickOptions = [
    {'label': '1小时', 'hours': 1, 'minutes': 0},
    {'label': '2小时', 'hours': 2, 'minutes': 0},
    {'label': '4小时', 'hours': 4, 'minutes': 0},
    {'label': '半天', 'hours': 4, 'minutes': 0},
    {'label': '1天', 'hours': 8, 'minutes': 0},
    {'label': '2天', 'hours': 16, 'minutes': 0},
    {'label': '3天', 'hours': 24, 'minutes': 0},
    {'label': '1周', 'hours': 40, 'minutes': 0},
  ];

  DateTime get _calculatedEndDate {
    final now = DateTime.now();
    return now.add(Duration(hours: _hours, minutes: _minutes));
  }

  String get _durationText {
    if (_hours == 0 && _minutes == 0) return '0分钟';
    if (_hours == 0) return '$_minutes分钟';
    if (_minutes == 0) return '$_hours小时';
    return '$_hours小时$_minutes分钟';
  }

  String get _endTimeText {
    final endDate = _calculatedEndDate;
    final now = DateTime.now();
    
    // 判断是否是同一天
    if (endDate.year == now.year && 
        endDate.month == now.month && 
        endDate.day == now.day) {
      return '今天 ${endDate.hour.toString().padLeft(2, '0')}:${endDate.minute.toString().padLeft(2, '0')}';
    }
    
    // 判断是否是明天
    final tomorrow = now.add(const Duration(days: 1));
    if (endDate.year == tomorrow.year && 
        endDate.month == tomorrow.month && 
        endDate.day == tomorrow.day) {
      return '明天 ${endDate.hour.toString().padLeft(2, '0')}:${endDate.minute.toString().padLeft(2, '0')}';
    }
    
    return '${endDate.month}月${endDate.day}日 ${endDate.hour.toString().padLeft(2, '0')}:${endDate.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Text(
              '认领任务',
              style: AppTypography.h4,
            ),
            const SizedBox(height: 8),
            Text(
              '设置预计完成工时，系统将自动计算结束时间',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            
            // 快速选择
            Text(
              '快速选择',
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickOptions.map((option) {
                final isSelected = _hours == option['hours'] && _minutes == option['minutes'];
                return InkWell(
                  onTap: () {
                    setState(() {
                      _hours = option['hours'] as int;
                      _minutes = option['minutes'] as int;
                    });
                  },
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.1)
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.divider,
                      ),
                    ),
                    child: Text(
                      option['label'] as String,
                      style: AppTypography.caption.copyWith(
                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            
            // 自定义时间
            Text(
              '自定义工时',
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // 小时选择
                Expanded(
                  child: _buildTimeSelector(
                    label: '小时',
                    value: _hours,
                    onChanged: (value) => setState(() => _hours = value),
                    min: 0,
                    max: 168, // 最多一周
                  ),
                ),
                const SizedBox(width: 16),
                // 分钟选择
                Expanded(
                  child: _buildTimeSelector(
                    label: '分钟',
                    value: _minutes,
                    onChanged: (value) => setState(() => _minutes = value),
                    min: 0,
                    max: 59,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // 计算结果显示
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withOpacity(0.3),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '预计用时：$_durationText',
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_outlined,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '结束时间：$_endTimeText',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // 按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: widget.onCancel,
                  child: const Text('取消'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    widget.onConfirm(_calculatedEndDate);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textInverse,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('确认领取'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector({
    required String label,
    required int value,
    required Function(int) onChanged,
    required int min,
    required int max,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              // 减少按钮
              InkWell(
                onTap: value > min
                    ? () => onChanged(value - 1)
                    : null,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(AppRadius.md),
                ),
                child: Container(
                  width: 40,
                  height: 44,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.remove,
                    size: 18,
                    color: value > min ? AppColors.textPrimary : AppColors.textDisabled,
                  ),
                ),
              ),
              // 数值显示
              Expanded(
                child: Container(
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.symmetric(
                      vertical: BorderSide(color: AppColors.divider),
                    ),
                  ),
                  child: Text(
                    value.toString().padLeft(2, '0'),
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              // 增加按钮
              InkWell(
                onTap: value < max
                    ? () => onChanged(value + 1)
                    : null,
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(AppRadius.md),
                ),
                child: Container(
                  width: 40,
                  height: 44,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.add,
                    size: 18,
                    color: value < max ? AppColors.textPrimary : AppColors.textDisabled,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

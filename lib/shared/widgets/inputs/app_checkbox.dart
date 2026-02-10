import 'package:flutter/material.dart';
import '../../../config/theme.dart';

/// 自定义复选框
class AppCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?>? onChanged;
  final String? label;

  const AppCheckbox({
    super.key,
    required this.value,
    this.onChanged,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onChanged != null ? () => onChanged!(!value) : null,
      borderRadius: BorderRadius.circular(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: AppAnimations.fast,
            curve: AppAnimations.spring,
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: value ? AppColors.primary : AppColors.surface,
              border: Border.all(
                color: value ? AppColors.primary : AppColors.border,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: value
                ? const Icon(
                    Icons.check,
                    size: 14,
                    color: AppColors.textInverse,
                  )
                : null,
          ),
          if (label != null) ...[
            const SizedBox(width: 10),
            Text(
              label!,
              style: AppTypography.body.copyWith(
                color: onChanged != null
                    ? AppColors.textPrimary
                    : AppColors.textDisabled,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

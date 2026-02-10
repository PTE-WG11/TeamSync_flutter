import 'package:flutter/material.dart';
import '../../../config/theme.dart';

/// 管理员统计卡片类型
enum AdminStatCardType {
  activeProjects,
  totalTasks,
  completionRate,
  overdueTasks,
}

/// 管理员统计卡片组件
class AdminStatCard extends StatelessWidget {
  final AdminStatCardType type;
  final dynamic value;
  final VoidCallback? onTap;

  const AdminStatCard({
    super.key,
    required this.type,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _iconBackgroundColor,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    _icon,
                    color: _accentColor,
                    size: 22,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 数值
            _buildValue(),
            const SizedBox(height: 4),
            // 标签
            Text(
              _label,
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建数值显示
  Widget _buildValue() {
    String displayValue;
      // if (value is double) {
      // displayValue = '${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)}%';
    // 只有完成率类型才显示百分号
    if (type == AdminStatCardType.completionRate && value is num) {
      final double numValue = (value as num).toDouble();
      displayValue =
          '${numValue.toStringAsFixed(numValue.truncateToDouble() == numValue ? 0 : 1)}%';
    } else {
      displayValue = value.toString();
    }

    return Text(
      displayValue,
      style: AppTypography.h2.copyWith(
        fontWeight: FontWeight.bold,
        color: _accentColor,
      ),
    );
  }

  String get _label {
    switch (type) {
      case AdminStatCardType.activeProjects:
        return '活跃项目';
      case AdminStatCardType.totalTasks:
        return '总任务数';
      case AdminStatCardType.completionRate:
        return '完成率';
      case AdminStatCardType.overdueTasks:
        return '逾期任务';
    }
  }

  Color get _accentColor {
    switch (type) {
      case AdminStatCardType.activeProjects:
        return AppColors.primary;
      case AdminStatCardType.totalTasks:
        return AppColors.info;
      case AdminStatCardType.completionRate:
        return AppColors.success;
      case AdminStatCardType.overdueTasks:
        return AppColors.error;
    }
  }

  Color get _iconBackgroundColor {
    switch (type) {
      case AdminStatCardType.activeProjects:
        return AppColors.primaryLight;
      case AdminStatCardType.totalTasks:
        return AppColors.infoLight;
      case AdminStatCardType.completionRate:
        return AppColors.successLight;
      case AdminStatCardType.overdueTasks:
        return AppColors.errorLight;
    }
  }

  IconData get _icon {
    switch (type) {
      case AdminStatCardType.activeProjects:
        return Icons.folder_open_outlined;
      case AdminStatCardType.totalTasks:
        return Icons.task_alt_outlined;
      case AdminStatCardType.completionRate:
        return Icons.trending_up_outlined;
      case AdminStatCardType.overdueTasks:
        return Icons.warning_amber_outlined;
    }
  }
}

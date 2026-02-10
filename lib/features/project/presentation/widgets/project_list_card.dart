import 'package:flutter/material.dart';

import '../../../../config/theme.dart';
import '../../domain/entities/project.dart';

/// 项目列表卡片
class ProjectListCard extends StatelessWidget {
  final Project project;
  final VoidCallback? onTap;
  final VoidCallback? onMoreTap;

  const ProjectListCard({
    super.key,
    required this.project,
    this.onTap,
    this.onMoreTap,
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
            // 顶部：状态标签 + 操作按钮
            Row(
              children: [
                _buildStatusBadge(project.status),
                const Spacer(),
                if (project.isArchived)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.textDisabled.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.archive_outlined, size: 14, color: AppColors.textDisabled),
                        const SizedBox(width: 4),
                        Text(
                          '已归档',
                          style: AppTypography.label.copyWith(
                            color: AppColors.textDisabled,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onMoreTap,
                  icon: Icon(
                    Icons.more_vert,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 项目名称
            Text(
              project.title,
              style: AppTypography.h4,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            // 项目描述
            Text(
              project.description,
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            // 进度条
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: project.progress / 100,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(
                  project.isCompleted ? AppColors.success : AppColors.primary,
                ),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            // 进度信息
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${project.progress.toStringAsFixed(0)}%',
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: project.isCompleted
                        ? AppColors.success
                        : AppColors.primary,
                  ),
                ),
                if (project.taskStats != null)
                  Text(
                    '${project.taskStats!.completed}/${project.taskStats!.total} 个任务完成',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            // 底部信息
            Row(
              children: [
                Icon(
                  Icons.people_outline,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${project.memberCount}人参与',
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.date_range,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _formatDateRange(project.startDate, project.endDate),
                    style: AppTypography.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (project.overdueTaskCount > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_amber, size: 14, color: AppColors.error),
                        const SizedBox(width: 4),
                        Text(
                          '${project.overdueTaskCount}个逾期',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建状态标签
  Widget _buildStatusBadge(String status) {
    final statusConfig = _getStatusConfig(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: statusConfig.backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: statusConfig.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            statusConfig.label,
            style: AppTypography.label.copyWith(
              color: statusConfig.color,
            ),
          ),
        ],
      ),
    );
  }

  /// 获取状态配置
  _StatusConfig _getStatusConfig(String status) {
    switch (status) {
      case 'planning':
        return _StatusConfig(
          label: '规划中',
          color: AppColors.statusPlanning,
          backgroundColor: AppColors.statusPlanningLight,
        );
      case 'pending':
        return _StatusConfig(
          label: '待处理',
          color: AppColors.statusPending,
          backgroundColor: AppColors.statusPendingLight,
        );
      case 'in_progress':
        return _StatusConfig(
          label: '进行中',
          color: AppColors.statusInProgress,
          backgroundColor: AppColors.statusInProgressLight,
        );
      case 'completed':
        return _StatusConfig(
          label: '已完成',
          color: AppColors.statusCompleted,
          backgroundColor: AppColors.statusCompletedLight,
        );
      default:
        return _StatusConfig(
          label: '未知',
          color: AppColors.textSecondary,
          backgroundColor: AppColors.border,
        );
    }
  }

  /// 格式化日期范围
  String _formatDateRange(String? startDate, String? endDate) {
    if (startDate == null || endDate == null) {
      return '未设置日期';
    }
    return '${_formatDate(startDate)} - ${_formatDate(endDate)}';
  }

  /// 格式化日期
  String _formatDate(String dateStr) {
    try {
      final parts = dateStr.split('-');
      if (parts.length >= 3) {
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);
        return '$month月${day}日';
      }
      return dateStr;
    } catch (e) {
      return dateStr;
    }
  }
}

/// 状态配置
class _StatusConfig {
  final String label;
  final Color color;
  final Color backgroundColor;

  _StatusConfig({
    required this.label,
    required this.color,
    required this.backgroundColor,
  });
}

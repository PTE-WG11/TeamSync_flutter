import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../features/dashboard/domain/entities/project_summary.dart';

/// 项目卡片组件
class ProjectCard extends StatelessWidget {
  final ProjectSummary project;
  final VoidCallback? onTap;
  final VoidCallback? onMoreTap;

  const ProjectCard({
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
                value: project.progress,
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
                  '${(project.progress * 100).toInt()}%',
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: project.isCompleted
                        ? AppColors.success
                        : AppColors.primary,
                  ),
                ),
                Text(
                  '${project.completedTasks}/${project.totalTasks} 个任务完成',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            // 底部信息：参与人数 + 日期范围
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
                    '${_formatDate(project.startDate)} - ${_formatDate(project.endDate)}',
                    style: AppTypography.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
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

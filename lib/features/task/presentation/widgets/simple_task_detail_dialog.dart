import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import '../../domain/entities/task.dart';

/// 简化版任务详情对话框（只读）
class SimpleTaskDetailDialog extends StatelessWidget {
  final Task task;
  final VoidCallback onClose;

  const SimpleTaskDetailDialog({
    super.key,
    required this.task,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Container(
        width: 560,
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头部
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: AppTypography.h4,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            // 内容区（可滚动）
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 状态 + 优先级
                    Row(
                      children: [
                        _buildStatusBadge(task.status),
                        const SizedBox(width: 12),
                        _buildPriorityBadge(task.priority),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // 信息行
                    _buildInfoRow('任务编号', task.displayId),
                    _buildInfoRow('任务类型', task.isMainTask ? '主任务' : '子任务'),
                    _buildInfoRow(
                      '负责人',
                      task.assigneeName.isNotEmpty ? task.assigneeName : '未分配',
                    ),
                    if (task.startDate != null)
                      _buildInfoRow('开始时间', _formatDate(task.startDate!)),
                    if (task.endDate != null)
                      _buildInfoRow('截止时间', _formatDate(task.endDate!)),
                    _buildInfoRow('创建时间', _formatDate(task.createdAt)),
                    const SizedBox(height: 20),
                    // 任务描述
                    if (task.description != null && task.description!.isNotEmpty) ...[
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
                          task.description!,
                          style: AppTypography.body,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 底部按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onClose,
                  child: const Text('关闭'),
                ),
              ],
            ),
          ],
        ),
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

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

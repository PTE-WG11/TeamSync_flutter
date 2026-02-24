import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import '../../domain/entities/task.dart';

/// 任务甘特图视图
class TaskGanttView extends StatelessWidget {
  final List<Task> tasks;
  final DateTimeRange? dateRange;

  const TaskGanttView({
    super.key,
    required this.tasks,
    this.dateRange,
  });

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return _buildEmptyState();
    }

    final range = dateRange ?? _calculateDefaultRange();
    final days = range.end.difference(range.start).inDays + 1;

    return Column(
      children: [
        // 时间轴头部
        _buildTimelineHeader(range, days),
        const Divider(height: 1),
        // 甘特图主体
        Expanded(
          child: Row(
            children: [
              // 左侧任务列表
              _buildTaskList(),
              const VerticalDivider(width: 1),
              // 右侧时间轴
              Expanded(
                child: _buildTimeline(range, days),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timeline_outlined,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无任务数据',
            style: AppTypography.h4.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineHeader(DateTimeRange range, int days) {
    return Container(
      height: 48,
      padding: const EdgeInsets.only(left: 200),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: days,
        itemBuilder: (context, index) {
          final date = range.start.add(Duration(days: index));
          final isToday = _isSameDay(date, DateTime.now());
          final isWeekend = date.weekday == DateTime.saturday ||
              date.weekday == DateTime.sunday;

          return Container(
            width: 50,
            decoration: BoxDecoration(
              color: isToday
                  ? AppColors.primary.withOpacity(0.1)
                  : isWeekend
                      ? AppColors.background.withOpacity(0.5)
                      : null,
              border: Border(
                right: BorderSide(color: AppColors.divider),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _getWeekdayShort(date.weekday),
                  style: AppTypography.caption.copyWith(
                    color: isToday
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontWeight: isToday ? FontWeight.w600 : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${date.day}',
                  style: AppTypography.bodySmall.copyWith(
                    color: isToday
                        ? AppColors.primary
                        : isWeekend
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                    fontWeight: isToday ? FontWeight.w600 : null,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTaskList() {
    return Container(
      width: 200,
      color: AppColors.surface,
      child: ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.divider),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: AppTypography.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusDot(task.status),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeline(DateTimeRange range, int days) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: days * 50.0,
        child: ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return _buildGanttBar(task, range, days);
          },
        ),
      ),
    );
  }

  Widget _buildGanttBar(Task task, DateTimeRange range, int totalDays) {
    if (task.startDate == null || task.endDate == null) {
      return Container(
        height: 48,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.divider),
          ),
        ),
      );
    }

    final startOffset = task.startDate!.difference(range.start).inDays;
    final duration = task.endDate!.difference(task.startDate!).inDays + 1;
    final progress = _calculateProgress(task);

    return Container(
      height: 48,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.divider),
        ),
      ),
      child: Stack(
        children: [
          // 网格背景
          Row(
            children: List.generate(
              totalDays,
              (index) => Container(
                width: 50,
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(color: AppColors.divider.withOpacity(0.5)),
                  ),
                  color: _isSameDay(
                    range.start.add(Duration(days: index)),
                    DateTime.now(),
                  )
                      ? AppColors.primary.withOpacity(0.05)
                      : null,
                ),
              ),
            ),
          ),
          // 任务条
          Positioned(
            left: startOffset * 50.0 + 4,
            top: 12,
            child: Container(
              width: duration * 50.0 - 8,
              height: 24,
              decoration: BoxDecoration(
                color: _getTaskColor(task.status).withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                  color: _getTaskColor(task.status),
                  width: 1,
                ),
              ),
              child: Stack(
                children: [
                  // 进度条
                  Container(
                    width: (duration * 50.0 - 8) * progress,
                    decoration: BoxDecoration(
                      color: _getTaskColor(task.status),
                      borderRadius: BorderRadius.horizontal(
                        left: Radius.circular(AppRadius.sm - 1),
                        right: progress >= 1
                            ? Radius.circular(AppRadius.sm - 1)
                            : Radius.zero,
                      ),
                    ),
                  ),
                  // 进度文字
                  Center(
                    child: Text(
                      '${(progress * 100).toInt()}%',
                      style: AppTypography.caption.copyWith(
                        color: progress > 0.5
                            ? AppColors.textInverse
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDot(String status) {
    Color color;
    switch (status) {
      case 'planning':
        color = AppColors.statusPlanning;
        break;
      case 'pending':
        color = AppColors.statusPending;
        break;
      case 'in_progress':
        color = AppColors.statusInProgress;
        break;
      case 'completed':
        color = AppColors.statusCompleted;
        break;
      default:
        color = AppColors.textSecondary;
    }

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Color _getTaskColor(String status) {
    switch (status) {
      case 'planning':
        return AppColors.statusPlanning;
      case 'pending':
        return AppColors.statusPending;
      case 'in_progress':
        return AppColors.statusInProgress;
      case 'completed':
        return AppColors.statusCompleted;
      default:
        return AppColors.textSecondary;
    }
  }

  double _calculateProgress(Task task) {
    if (task.isCompleted) return 1.0;
    if (task.status == 'in_progress') return 0.6;
    if (task.status == 'pending') return 0.2;
    return 0.0;
  }

  String _getWeekdayShort(int weekday) {
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    return weekdays[weekday - 1];
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTimeRange _calculateDefaultRange() {
    final now = DateTime.now();
    return DateTimeRange(
      start: now.subtract(const Duration(days: 3)),
      end: now.add(const Duration(days: 14)),
    );
  }
}

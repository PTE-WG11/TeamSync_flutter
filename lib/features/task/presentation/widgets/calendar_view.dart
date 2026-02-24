import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import '../../domain/entities/task.dart';

/// 任务日历视图
class TaskCalendarView extends StatefulWidget {
  final Map<DateTime, List<Task>> tasksByDate;

  const TaskCalendarView({
    super.key,
    required this.tasksByDate,
  });

  @override
  State<TaskCalendarView> createState() => _TaskCalendarViewState();
}

class _TaskCalendarViewState extends State<TaskCalendarView> {
  late DateTime _currentMonth;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
    _selectedDate = DateTime.now();
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(
        _currentMonth.year,
        _currentMonth.month - 1,
        1,
      );
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(
        _currentMonth.year,
        _currentMonth.month + 1,
        1,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 月份导航
        _buildMonthHeader(),
        const Divider(height: 1),
        // 星期标题
        _buildWeekdayHeader(),
        // 日历网格
        Expanded(
          child: _buildCalendarGrid(),
        ),
        const Divider(height: 1),
        // 选中日期任务列表
        _buildSelectedDateTasks(),
      ],
    );
  }

  Widget _buildMonthHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_currentMonth.year}年${_currentMonth.month}月',
            style: AppTypography.h4,
          ),
          Row(
            children: [
              IconButton(
                onPressed: _previousMonth,
                icon: const Icon(Icons.chevron_left),
                color: AppColors.textSecondary,
              ),
              IconButton(
                onPressed: _nextMonth,
                icon: const Icon(Icons.chevron_right),
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeader() {
    final weekdays = ['日', '一', '二', '三', '四', '五', '六'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.divider),
        ),
      ),
      child: Row(
        children: weekdays.map((day) {
          return Expanded(
            child: Center(
              child: Text(
                day,
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysInMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      0,
    ).day;
    final firstWeekday = firstDayOfMonth.weekday % 7;

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.2,
      ),
      itemCount: 42, // 6行 x 7列
      itemBuilder: (context, index) {
        final dayOffset = index - firstWeekday;
        final date = DateTime(
          _currentMonth.year,
          _currentMonth.month,
          dayOffset + 1,
        );

        // 判断是否在当前月份
        final isCurrentMonth = dayOffset >= 0 && dayOffset < daysInMonth;
        final isToday = _isSameDay(date, DateTime.now());
        final isSelected = _selectedDate != null && _isSameDay(date, _selectedDate!);
        final tasks = _getTasksForDate(date);
        final hasTasks = tasks.isNotEmpty;

        if (!isCurrentMonth) {
          return const SizedBox.shrink();
        }

        return InkWell(
          onTap: () {
            setState(() {
              _selectedDate = date;
            });
          },
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.1)
                  : isToday
                      ? AppColors.primaryLight
                      : null,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: isToday
                  ? Border.all(color: AppColors.primary)
                  : isSelected
                      ? Border.all(color: AppColors.primary.withOpacity(0.5))
                      : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${date.day}',
                  style: AppTypography.body.copyWith(
                    color: isToday
                        ? AppColors.primary
                        : isCurrentMonth
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                    fontWeight: isToday || isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
                if (hasTasks)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _buildTaskIndicators(tasks),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildTaskIndicators(List<Task> tasks) {
    final indicators = <Widget>[];
    final maxIndicators = 3;

    for (var i = 0; i < tasks.length && i < maxIndicators; i++) {
      indicators.add(
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: _getPriorityColor(tasks[i].priority),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      );
    }

    if (tasks.length > maxIndicators) {
      indicators.add(
        Text(
          '+',
          style: AppTypography.caption.copyWith(
            fontSize: 8,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return indicators;
  }

  Widget _buildSelectedDateTasks() {
    final tasks = _selectedDate != null
        ? _getTasksForDate(_selectedDate!)
        : <Task>[];

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _selectedDate != null
                    ? '${_selectedDate!.month}月${_selectedDate!.day}日'
                    : '选择日期',
                style: AppTypography.h4,
              ),
              const SizedBox(width: 8),
              if (tasks.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    '${tasks.length}个任务',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: tasks.isEmpty
                ? Center(
                    child: Text(
                      '该日期暂无任务',
                      style: AppTypography.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: tasks.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      return _buildTaskItem(tasks[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(Task task) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getPriorityColor(task.priority),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  task.assigneeName,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          _buildStatusBadge(task.status),
        ],
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
        label = '未知';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  List<Task> _getTasksForDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return widget.tasksByDate[normalizedDate] ?? [];
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'urgent':
        return AppColors.error;
      case 'high':
        return AppColors.warning;
      case 'medium':
        return AppColors.info;
      case 'low':
        return AppColors.textSecondary;
      default:
        return AppColors.textSecondary;
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

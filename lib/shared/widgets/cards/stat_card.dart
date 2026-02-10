import 'package:flutter/material.dart';
import '../../../config/theme.dart';

/// 统计卡片类型
enum StatCardType {
  today,
  week,
  overdue,
  completed,
}

/// 统计卡片组件
class StatCard extends StatelessWidget {
  final StatCardType type;
  final int count;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.type,
    required this.count,
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
          border: Border(
            left: BorderSide(color: _accentColor, width: 4),
          ),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AnimatedCounter(
                    count: count,
                    style: AppTypography.h1.copyWith(color: _accentColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _label,
                    style: AppTypography.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _iconBackgroundColor,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Icon(
                _icon,
                color: _accentColor,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _label {
    switch (type) {
      case StatCardType.today:
        return '今日任务';
      case StatCardType.week:
        return '本周任务';
      case StatCardType.overdue:
        return '逾期任务';
      case StatCardType.completed:
        return '已完成';
    }
  }

  Color get _accentColor {
    switch (type) {
      case StatCardType.today:
        return AppColors.primary;
      case StatCardType.week:
        return AppColors.warning;
      case StatCardType.overdue:
        return AppColors.error;
      case StatCardType.completed:
        return AppColors.success;
    }
  }

  Color get _iconBackgroundColor {
    switch (type) {
      case StatCardType.today:
        return AppColors.primaryLight;
      case StatCardType.week:
        return AppColors.warningLight;
      case StatCardType.overdue:
        return AppColors.errorLight;
      case StatCardType.completed:
        return AppColors.successLight;
    }
  }

  IconData get _icon {
    switch (type) {
      case StatCardType.today:
        return Icons.today;
      case StatCardType.week:
        return Icons.date_range;
      case StatCardType.overdue:
        return Icons.warning;
      case StatCardType.completed:
        return Icons.check_circle;
    }
  }
}

/// 数字动画组件
class _AnimatedCounter extends StatefulWidget {
  final int count;
  final TextStyle style;

  const _AnimatedCounter({
    required this.count,
    required this.style,
  });

  @override
  State<_AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<_AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = IntTween(begin: 0, end: widget.count).animate(
      CurvedAnimation(parent: _controller, curve: AppAnimations.easeOut),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(_AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.count != widget.count) {
      _animation = IntTween(begin: oldWidget.count, end: widget.count).animate(
        CurvedAnimation(parent: _controller, curve: AppAnimations.easeOut),
      );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Text(
          _animation.value.toString(),
          style: widget.style,
        );
      },
    );
  }
}

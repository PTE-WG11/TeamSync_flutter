import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../config/theme.dart';

/// 图标尺寸
enum IconSize { xs, sm, md, lg, xl }

/// 通用图标组件
class AppIcon extends StatelessWidget {
  final String name;
  final IconSize size;
  final Color? color;
  final VoidCallback? onTap;

  const AppIcon({
    super.key,
    required this.name,
    this.size = IconSize.md,
    this.color,
    this.onTap,
  });

  double get _size {
    switch (size) {
      case IconSize.xs:
        return 16;
      case IconSize.sm:
        return 20;
      case IconSize.md:
        return 24;
      case IconSize.lg:
        return 32;
      case IconSize.xl:
        return 48;
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconWidget = SvgPicture.asset(
      'assets/icons/$name.svg',
      width: _size,
      height: _size,
      colorFilter: ColorFilter.mode(
        color ?? AppColors.textPrimary,
        BlendMode.srcIn,
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_size / 2),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: iconWidget,
        ),
      );
    }

    return iconWidget;
  }
}

/// 预定义图标名称
class AppIcons {
  AppIcons._();

  // Navigation
  static const String home = 'navigation/home';
  static const String project = 'navigation/project';
  static const String calendar = 'navigation/calendar';
  static const String settings = 'navigation/settings';
  static const String logout = 'navigation/logout';

  // Task
  static const String task = 'task/task';
  static const String check = 'task/check';
  static const String clock = 'task/clock';
  static const String flag = 'task/flag';

  // Status
  static const String planning = 'status/planning';
  static const String inProgress = 'status/in_progress';
  static const String completed = 'status/completed';
  static const String overdue = 'status/overdue';

  // Action
  static const String add = 'action/add';
  static const String edit = 'action/edit';
  static const String delete = 'action/delete';
  static const String search = 'action/search';
  static const String filter = 'action/filter';
  static const String more = 'action/more';
  static const String close = 'action/close';

  // File
  static const String attachment = 'file/attachment';
  static const String upload = 'file/upload';
  static const String download = 'file/download';

  // Feedback
  static const String success = 'feedback/success';
  static const String error = 'feedback/error';
  static const String info = 'feedback/info';
}

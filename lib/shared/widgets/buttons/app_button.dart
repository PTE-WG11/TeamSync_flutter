import 'package:flutter/material.dart';
import '../../../config/theme.dart';

/// 按钮类型
enum AppButtonType {
  primary,
  secondary,
  outline,
  ghost,
  danger,
}

/// 按钮尺寸
enum AppButtonSize {
  small,
  medium,
  large,
}

/// 通用按钮组件
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final AppButtonSize size;
  final bool isLoading;
  final bool isDisabled;
  final Widget? icon;
  final bool iconAfterLabel;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.type = AppButtonType.primary,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.iconAfterLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = isDisabled || isLoading || onPressed == null;

    return MouseRegion(
      cursor: disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: AppAnimations.fast,
        child: Material(
          color: _backgroundColor(disabled),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: InkWell(
            onTap: disabled ? null : onPressed,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Container(
              height: _height,
              padding: EdgeInsets.symmetric(horizontal: _horizontalPadding),
              decoration: BoxDecoration(
                border: _border(disabled),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLoading) ...[
                    SizedBox(
                      width: _iconSize,
                      height: _iconSize,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(_loadingColor),
                      ),
                    ),
                    SizedBox(width: _iconSpacing),
                  ] else if (icon != null && !iconAfterLabel) ...[
                    IconTheme(
                      data: IconThemeData(
                        size: _iconSize,
                        color: _textColor(disabled),
                      ),
                      child: icon!,
                    ),
                    SizedBox(width: _iconSpacing),
                  ],
                  Text(
                    label,
                    style: _textStyle(disabled),
                  ),
                  if (icon != null && iconAfterLabel) ...[
                    SizedBox(width: _iconSpacing),
                    IconTheme(
                      data: IconThemeData(
                        size: _iconSize,
                        color: _textColor(disabled),
                      ),
                      child: icon!,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _backgroundColor(bool disabled) {
    if (disabled && type != AppButtonType.ghost) {
      return AppColors.border;
    }
    switch (type) {
      case AppButtonType.primary:
        return AppColors.primary;
      case AppButtonType.secondary:
        return AppColors.surface;
      case AppButtonType.outline:
        return AppColors.surface;
      case AppButtonType.ghost:
        return Colors.transparent;
      case AppButtonType.danger:
        return AppColors.error;
    }
  }

  Border? _border(bool disabled) {
    if (type == AppButtonType.outline) {
      return Border.all(
        color: disabled ? AppColors.border : AppColors.primary,
        width: 1.5,
      );
    }
    if (type == AppButtonType.secondary) {
      return Border.all(color: AppColors.border);
    }
    return null;
  }

  double get _height {
    switch (size) {
      case AppButtonSize.large:
        return 48;
      case AppButtonSize.medium:
        return 40;
      case AppButtonSize.small:
        return 32;
    }
  }

  double get _horizontalPadding {
    switch (size) {
      case AppButtonSize.large:
        return 24;
      case AppButtonSize.medium:
        return 20;
      case AppButtonSize.small:
        return 16;
    }
  }

  double get _iconSize => size == AppButtonSize.small ? 14 : 18;

  double get _iconSpacing => size == AppButtonSize.small ? 6 : 8;

  Color _textColor(bool disabled) {
    if (disabled && type != AppButtonType.ghost) {
      return AppColors.textDisabled;
    }
    switch (type) {
      case AppButtonType.primary:
      case AppButtonType.danger:
        return AppColors.textInverse;
      case AppButtonType.secondary:
        return AppColors.textPrimary;
      case AppButtonType.outline:
      case AppButtonType.ghost:
        return AppColors.primary;
    }
  }

  TextStyle _textStyle(bool disabled) {
    return AppTypography.button.copyWith(
      color: _textColor(disabled),
      fontSize: size == AppButtonSize.large ? 16 : 14,
    );
  }

  Color get _loadingColor => type == AppButtonType.primary || type == AppButtonType.danger
      ? AppColors.textInverse
      : AppColors.primary;
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

/// 基于角色显示内容的 Widget
/// 
/// 使用示例：
/// ```dart
/// AdminOnly(
///   child: ElevatedButton(...), // 只有管理员能看到
/// )
/// 
/// RoleBasedWidget(
///   adminChild: AdminDashboard(),
///   memberChild: MemberDashboard(),
///   visitorChild: VisitorPage(),
/// )
/// ```

/// 仅管理员可见
class AdminOnly extends StatelessWidget {
  final Widget child;
  final Widget? fallback;

  const AdminOnly({
    super.key,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final isAdmin = authState is AuthAuthenticated && authState.isAdmin;

    if (isAdmin) return child;
    return fallback ?? const SizedBox.shrink();
  }
}

/// 仅成员可见（不包括访客）
class MemberOnly extends StatelessWidget {
  final Widget child;
  final Widget? fallback;

  const MemberOnly({
    super.key,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final isMember = authState is AuthAuthenticated && 
                     (authState.isMember || authState.isAdmin);

    if (isMember) return child;
    return fallback ?? const SizedBox.shrink();
  }
}

/// 基于角色显示不同内容
class RoleBasedWidget extends StatelessWidget {
  final Widget? adminChild;
  final Widget? memberChild;
  final Widget? visitorChild;
  final Widget? defaultChild;

  const RoleBasedWidget({
    super.key,
    this.adminChild,
    this.memberChild,
    this.visitorChild,
    this.defaultChild,
  });

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;

    if (authState is AuthAuthenticated) {
      if (authState.isAdmin && adminChild != null) {
        return adminChild!;
      }
      if (authState.isMember && memberChild != null) {
        return memberChild!;
      }
      if (authState.isVisitor && visitorChild != null) {
        return visitorChild!;
      }
    }

    return defaultChild ?? const SizedBox.shrink();
  }
}

/// 权限包装器（用于按钮等可交互元素）
/// 无权限时显示禁用状态或隐藏
class PermissionWrapper extends StatelessWidget {
  final Widget child;
  final bool hasPermission;
  final bool showDisabled;
  final VoidCallback? onDisabledTap;

  const PermissionWrapper({
    super.key,
    required this.child,
    required this.hasPermission,
    this.showDisabled = false,
    this.onDisabledTap,
  });

  @override
  Widget build(BuildContext context) {
    if (hasPermission) return child;

    if (!showDisabled) return const SizedBox.shrink();

    // 显示禁用状态
    return AbsorbPointer(
      child: Opacity(
        opacity: 0.5,
        child: child,
      ),
    );
  }
}

/// 带权限检查的按钮
class PermissionButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final bool hasPermission;
  final String? disabledTooltip;

  const PermissionButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    required this.hasPermission,
    this.disabledTooltip,
  });

  @override
  Widget build(BuildContext context) {
    final button = icon != null
        ? ElevatedButton.icon(
            onPressed: hasPermission ? onPressed : null,
            icon: Icon(icon),
            label: Text(label),
          )
        : ElevatedButton(
            onPressed: hasPermission ? onPressed : null,
            child: Text(label),
          );

    if (!hasPermission && disabledTooltip != null) {
      return Tooltip(
        message: disabledTooltip!,
        child: button,
      );
    }

    return button;
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme.dart';

/// 侧边栏导航项
class SidebarItem {
  final String label;
  final IconData icon;
  final String route;
  final int? badge;

  const SidebarItem({
    required this.label,
    required this.icon,
    required this.route,
    this.badge,
  });
}

/// 侧边栏组件
class Sidebar extends StatelessWidget {
  final String userName;
  final String userRole;
  final String? avatar;
  final int taskCount;
  final int projectCount;
  final int overdueCount;
  final List<SidebarItem> items;
  final String currentRoute;
  final ValueChanged<String> onRouteSelected;
  final VoidCallback onLogout;

  const Sidebar({
    super.key,
    required this.userName,
    required this.userRole,
    this.avatar,
    required this.taskCount,
    required this.projectCount,
    required this.overdueCount,
    required this.items,
    required this.currentRoute,
    required this.onRouteSelected,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: AppColors.surface,
      child: Column(
        children: [
          // Logo
          Padding(
            padding: AppSpacing.sidebarPadding,
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: const Center(
                    child: Text(
                      'T',
                      style: TextStyle(
                        color: AppColors.textInverse,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'TeamSync',
                  style: AppTypography.h4,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // 用户信息
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildAvatar(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: AppTypography.body.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            userRole,
                            style: AppTypography.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat('任务', taskCount),
                    _buildStat('项目', projectCount),
                    _buildStat('逾期', overdueCount, isError: true),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // 导航菜单
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = item.route == currentRoute;
                return _buildNavItem(item, isSelected);
              },
            ),
          ),
          const Divider(height: 1),
          // 底部操作
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _buildBottomItem(
                  icon: Icons.settings_outlined,
                  label: '个人设置',
                  onTap: () => context.go('/settings'),
                ),
                const SizedBox(height: 4),
                _buildBottomItem(
                  icon: Icons.logout,
                  label: '退出登录',
                  onTap: onLogout,
                  color: AppColors.error,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, int value, {bool isError = false}) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: AppTypography.h4.copyWith(
            color: isError ? AppColors.error : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.caption,
        ),
      ],
    );
  }

  /// 构建用户头像
  Widget _buildAvatar() {
    final hasValidAvatar = avatar != null && avatar!.trim().isNotEmpty;
    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : '?';

    return CircleAvatar(
      radius: 20,
      backgroundColor: AppColors.primaryLight,
      backgroundImage: hasValidAvatar ? NetworkImage(avatar!) : null,
      child: hasValidAvatar
          ? null
          : Text(
              initial,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  Widget _buildNavItem(SidebarItem item, bool isSelected) {
    return InkWell(
      onTap: () => onRouteSelected(item.route),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : null,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          children: [
            Icon(
              item.icon,
              size: 20,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.label,
                style: AppTypography.body.copyWith(
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w500 : null,
                ),
              ),
            ),
            if (item.badge != null && item.badge! > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  item.badge! > 99 ? '99+' : item.badge.toString(),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textInverse,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: color ?? AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: AppTypography.body.copyWith(
                color: color ?? AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

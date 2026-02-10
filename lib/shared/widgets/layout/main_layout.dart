import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../config/routes.dart';
import '../../../config/theme.dart';
import '../../../features/auth/presentation/bloc/auth_bloc.dart';


/// 主布局框架
/// 包含：顶部导航栏 + 左侧边栏 + 主内容区
class MainLayout extends StatefulWidget {
  final Widget child;

  const MainLayout({
    super.key,
    required this.child,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  // 模拟数据 - 后续从API获取
  final List<Map<String, dynamic>> _projects = const [
    {'id': 1, 'name': '用户中心系统', 'status': 'in_progress'},
    {'id': 2, 'name': '电商平台重构', 'status': 'planning'},
    {'id': 3, 'name': '官网改版', 'status': 'completed'},
  ];

  final List<Map<String, dynamic>> _archivedProjects = const [
    {'id': 4, 'name': '旧官网项目', 'status': 'archived'},
  ];

  final int _unreadNotificationCount = 3;

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState : null;

    // 获取当前路由
    final location = GoRouterState.of(context).matchedLocation;

    return Scaffold(
      body: Column(
        children: [
          // 顶部导航栏
          _TopNavigationBar(
            userName: user?.username ?? '',
            userRole: user?.role.name ?? '',
            unreadNotificationCount: _unreadNotificationCount,
            currentRoute: location,
            onNotificationTap: () => context.go(AppRoutes.notifications),
            onLogout: () {
              context.read<AuthBloc>().add(const AuthLogoutRequested());
            },
          ),
          // 主体内容区
          Expanded(
            child: Row(
              children: [
                // 左侧边栏
                _Sidebar(
                  projects: _projects,
                  archivedProjects: _archivedProjects,
                  currentRoute: location,
                  onRouteSelected: (route) => context.go(route),
                ),
                // 主内容区
                Expanded(
                  child: Container(
                    color: AppColors.background,
                    child: widget.child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 顶部导航栏
/// 包含：Logo、全局导航、通知中心、用户菜单
class _TopNavigationBar extends StatelessWidget {
  final String userName;
  final String userRole;
  final int unreadNotificationCount;
  final String currentRoute;
  final VoidCallback onNotificationTap;
  final VoidCallback onLogout;

  const _TopNavigationBar({
    required this.userName,
    required this.userRole,
    required this.unreadNotificationCount,
    required this.currentRoute,
    required this.onNotificationTap,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.divider),
        ),
      ),
      child: Row(
        children: [
          // Logo
          _buildLogo(),
          const SizedBox(width: 48),
          // 全局导航
          _buildNavItem(context, '首页', AppRoutes.home),
          _buildNavItem(context, '项目', AppRoutes.projects),
          _buildNavItem(context, '团队', AppRoutes.members),
          _buildNavItem(context, '日历', AppRoutes.calendar),
          const Spacer(),
          // 通知中心
          _buildNotificationButton(),
          const SizedBox(width: 16),
          // 用户菜单
          _buildUserMenu(context),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: const Center(
            child: Text(
              'T',
              style: TextStyle(
                color: AppColors.textInverse,
                fontSize: 16,
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
    );
  }

  Widget _buildNavItem(BuildContext context, String label, String route) {
    final isSelected = currentRoute == route ||
        (route != AppRoutes.home && currentRoute.startsWith(route));

    return InkWell(
      onTap: () => context.go(route),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.body.copyWith(
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : null,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationButton() {
    return InkWell(
      onTap: onNotificationTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            child: Icon(
              Icons.notifications_outlined,
              color: AppColors.textSecondary,
              size: 22,
            ),
          ),
          if (unreadNotificationCount > 0)
            Positioned(
              right: 4,
              top: 4,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: AppColors.surface,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    unreadNotificationCount > 99
                        ? '99+'
                        : unreadNotificationCount.toString(),
                    style: const TextStyle(
                      color: AppColors.textInverse,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUserMenu(BuildContext context) {
    final displayName = userName.isNotEmpty ? userName : '用户';
    final firstChar = displayName.isNotEmpty ? displayName[0] : '?';

    return PopupMenuButton<String>(
      offset: const Offset(0, 40),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primaryLight,
            child: Text(
              firstChar.toUpperCase(),
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            displayName,
            style: AppTypography.body,
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.textSecondary,
            size: 18,
          ),
        ],
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                userRole.isNotEmpty ? userRole : '团队成员',
                style: AppTypography.caption,
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'settings',
          child: Row(
            children: [
              Icon(
                Icons.settings_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              const Text('个人设置'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              const Icon(
                Icons.logout,
                size: 18,
                color: AppColors.error,
              ),
              const SizedBox(width: 12),
              Text(
                '退出登录',
                style: TextStyle(color: AppColors.error),
              ),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'settings':
            context.go(AppRoutes.settings);
            break;
          case 'logout':
            onLogout();
            break;
        }
      },
    );
  }
}

/// 侧边栏
/// 包含：个人工作区 + 项目列表 + 归档项目
class _Sidebar extends StatelessWidget {
  final List<Map<String, dynamic>> projects;
  final List<Map<String, dynamic>> archivedProjects;
  final String currentRoute;
  final ValueChanged<String> onRouteSelected;

  const _Sidebar({
    required this.projects,
    required this.archivedProjects,
    required this.currentRoute,
    required this.onRouteSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 个人工作区
          _buildSectionTitle('我的工作'),
          _buildMenuItem(
            icon: Icons.task_alt,
            label: '我的任务',
            route: AppRoutes.home,
          ),
          _buildMenuItem(
            icon: Icons.calendar_today_outlined,
            label: '日历视图',
            route: AppRoutes.calendar,
          ),
          _buildMenuItem(
            icon: Icons.folder_outlined,
            label: '文件管理',
            route: '/files', // 占位
          ),
          const Divider(height: 32),
          // 项目列表
          _buildSectionTitle('项目'),
          ...projects.map((project) => _buildProjectItem(project)),
          const Divider(height: 32),
          // 归档项目
          _buildSectionTitle('归档项目'),
          ...archivedProjects.map((project) => _buildProjectItem(project, isArchived: true)),
          const Spacer(),
          // 底部帮助链接
          Padding(
            padding: const EdgeInsets.all(16),
            child: InkWell(
              onTap: () {},
              child: Row(
                children: [
                  Icon(
                    Icons.help_outline,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '帮助中心',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Text(
        title,
        style: AppTypography.caption.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required String route,
  }) {
    final isSelected = currentRoute == route;

    return InkWell(
      onTap: () => onRouteSelected(route),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : null,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: AppTypography.body.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w500 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectItem(Map<String, dynamic> project, {bool isArchived = false}) {
    final projectRoute = '${AppRoutes.projects}/${project['id']}';
    final isSelected = currentRoute == projectRoute;

    // 根据状态获取颜色
    Color statusColor;
    switch (project['status']) {
      case 'in_progress':
        statusColor = AppColors.statusInProgress;
        break;
      case 'planning':
        statusColor = AppColors.statusPlanning;
        break;
      case 'completed':
      case 'archived':
        statusColor = AppColors.statusCompleted;
        break;
      default:
        statusColor = AppColors.statusPlanning;
    }

    return InkWell(
      onTap: () => onRouteSelected(projectRoute),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : null,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                project['name'],
                style: AppTypography.body.copyWith(
                  color: isArchived
                      ? AppColors.textSecondary
                      : (isSelected ? AppColors.primary : AppColors.textPrimary),
                  fontWeight: isSelected ? FontWeight.w500 : null,
                  decoration: isArchived ? TextDecoration.lineThrough : null,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isArchived)
              Icon(
                Icons.archive_outlined,
                size: 14,
                color: AppColors.textDisabled,
              ),
          ],
        ),
      ),
    );
  }
}

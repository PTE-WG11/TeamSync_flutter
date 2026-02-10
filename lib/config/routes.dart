import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/dashboard/presentation/bloc/dashboard_bloc.dart';
import '../features/dashboard/presentation/pages/admin_dashboard_page.dart';
import '../features/dashboard/presentation/pages/member_dashboard_page.dart';
import '../features/project/presentation/bloc/project_bloc.dart';
import '../features/project/presentation/pages/project_detail_page.dart';
import '../features/project/presentation/pages/project_list_page.dart';
import '../features/team/presentation/pages/team_members_page.dart';
import '../shared/widgets/layout/main_layout.dart';
import 'theme.dart';

/// 路由配置类
class AppRoutes {
  AppRoutes._();

  // 路由路径常量
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/';
  static const String projects = '/projects';
  static const String projectDetail = '/projects/:id';
  static const String tasks = '/tasks';
  static const String taskDetail = '/tasks/:id';
  static const String calendar = '/calendar';
  static const String members = '/members';
  static const String settings = '/settings';
  static const String notifications = '/notifications';
  static const String visitorWaiting = '/waiting';

  /// 创建路由配置
  static GoRouter createRouter(AuthBloc authBloc) {
    return GoRouter(
      initialLocation: login,
      debugLogDiagnostics: true,
      refreshListenable: GoRouterRefreshStream(authBloc.stream),
      redirect: (context, state) {
        final authState = authBloc.state;
        final isAuthenticated = authState is AuthAuthenticated;
        final isVisitor = isAuthenticated && authState.isVisitor;
        
        final isLoginPage = state.matchedLocation == login;
        final isRegisterPage = state.matchedLocation == register;
        final isWaitingPage = state.matchedLocation == visitorWaiting;

        // 未登录且不在登录/注册页，重定向到登录
        if (!isAuthenticated && !isLoginPage && !isRegisterPage) {
          return login;
        }

        // 已登录但还在登录/注册页，重定向到首页
        if (isAuthenticated && (isLoginPage || isRegisterPage)) {
          if (isVisitor) {
            return visitorWaiting;
          }
          return home;
        }

        // 访客只能访问等待页
        if (isVisitor && !isWaitingPage) {
          return visitorWaiting;
        }

        // 非访客访问等待页，重定向到首页
        if (!isVisitor && isWaitingPage) {
          return home;
        }

        return null;
      },
      routes: [
        // 登录页
        GoRoute(
          path: login,
          name: 'login',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: LoginPage(),
          ),
        ),
        // 注册页
        GoRoute(
          path: register,
          name: 'register',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: RegisterPage(),
          ),
        ),
        // 访客等待页
        GoRoute(
          path: visitorWaiting,
          name: 'waiting',
          builder: (context, state) => const VisitorWaitingPage(),
        ),
        // 主布局包裹的页面
        ShellRoute(
          builder: (context, state, child) => BlocProvider(
            create: (context) => DashboardBloc(),
            child: MainLayout(child: child),
          ),
          routes: [
            // 首页（仪表盘）- 根据角色显示不同页面
            GoRoute(
              path: home,
              name: 'home',
              pageBuilder: (context, state) {
                final authState = context.read<AuthBloc>().state;
                final isAdmin = authState is AuthAuthenticated && authState.isAdmin;
                
                if (isAdmin) {
                  return const NoTransitionPage(
                    child: AdminDashboardPage(),
                  );
                } else {
                  // 成员首页
                  return const NoTransitionPage(
                    child: MemberDashboardPage(),
                  );
                }
              },
            ),
            // 项目列表
            GoRoute(
              path: projects,
              name: 'projects',
              pageBuilder: (context, state) => NoTransitionPage(
                child: BlocProvider(
                  create: (_) => ProjectBloc(),
                  child: const ProjectListPage(),
                ),
              ),
            ),
            // 项目详情
            GoRoute(
              path: projectDetail,
              name: 'projectDetail',
              pageBuilder: (context, state) {
                final projectId = int.parse(state.pathParameters['id']!);
                return NoTransitionPage(
                  child: BlocProvider(
                    create: (_) => ProjectBloc(),
                    child: ProjectDetailPage(projectId: projectId),
                  ),
                );
              },
            ),
            // 日历视图
            GoRoute(
              path: calendar,
              name: 'calendar',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: PlaceholderPage(title: '日历视图'),
              ),
            ),
            // 成员管理（仅管理员可访问）
            GoRoute(
              path: members,
              name: 'members',
              pageBuilder: (context, state) {
                final authState = context.read<AuthBloc>().state;
                final isAdmin = authState is AuthAuthenticated && authState.isAdmin;
                
                if (!isAdmin) {
                  // 非管理员重定向到首页
                  return const NoTransitionPage(
                    child: ForbiddenPage(),
                  );
                }
                
                return const NoTransitionPage(
                  child: TeamMembersPage(),
                );
              },
            ),
            // 设置
            GoRoute(
              path: settings,
              name: 'settings',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: PlaceholderPage(title: '个人设置'),
              ),
            ),
            // 通知中心
            GoRoute(
              path: notifications,
              name: 'notifications',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: PlaceholderPage(title: '通知中心'),
              ),
            ),
          ],
        ),
      ],
      errorBuilder: (context, state) => ErrorPage(error: state.error),
    );
  }
}

/// 用于监听Bloc状态变化的路由刷新
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// 访客等待页
class VisitorWaitingPage extends StatelessWidget {
  const VisitorWaitingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: AppColors.primary.withOpacity(0.5),
              ),
              const SizedBox(height: 24),
              Text(
                '等待团队邀请',
                style: AppTypography.h2,
              ),
              const SizedBox(height: 16),
              Text(
                '您已注册成功，请联系团队管理员将您加入团队以开始协作',
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              OutlinedButton.icon(
                onPressed: () {
                  // 重新检查邀请状态
                  context.read<AuthBloc>().add(const AuthCheckRequested());
                },
                icon: const Icon(Icons.refresh),
                label: const Text('重新检查邀请状态'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  context.read<AuthBloc>().add(const AuthLogoutRequested());
                },
                child: const Text('退出登录'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 错误页面
class ErrorPage extends StatelessWidget {
  final Exception? error;

  const ErrorPage({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              '页面不存在',
              style: AppTypography.h2,
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: AppTypography.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('返回首页'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 无权限页面
class ForbiddenPage extends StatelessWidget {
  const ForbiddenPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.block,
                size: 64,
                color: AppColors.error.withOpacity(0.5),
              ),
              const SizedBox(height: 24),
              Text(
                '无访问权限',
                style: AppTypography.h2,
              ),
              const SizedBox(height: 16),
              Text(
                '您没有权限访问此页面，请联系团队管理员',
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.home),
                child: const Text('返回首页'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 占位页面
class PlaceholderPage extends StatelessWidget {
  final String title;

  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: AppTypography.h3,
          ),
          const SizedBox(height: 8),
          Text(
            '功能开发中...',
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go(AppRoutes.home),
            child: const Text('返回首页'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'config/routes.dart';
import 'config/theme.dart';
import 'core/permissions/permission_service.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

/// 应用程序根组件
class TeamSyncApp extends StatefulWidget {
  const TeamSyncApp({super.key});

  @override
  State<TeamSyncApp> createState() => _TeamSyncAppState();
}

class _TeamSyncAppState extends State<TeamSyncApp> {
  late final AuthBloc _authBloc;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authBloc = AuthBloc()..add(const AuthCheckRequested());
    _router = AppRoutes.createRouter(_authBloc);
  }

  @override
  void dispose() {
    _authBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authBloc),
        RepositoryProvider(
          create: (context) => PermissionService(_authBloc),
        ),
      ],
      child: MaterialApp.router(
        title: 'TeamSync',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: _router,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.0),
            ),
            child: child!,
          );
        },
      ),
    );
  }
}

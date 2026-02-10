import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// 认证 BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthCheckRequested>(_onCheckRequested);
  }

  /// 处理登录请求
  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      // TODO: 调用登录 API
      await Future.delayed(const Duration(seconds: 1));

      // 模拟登录成功
      if (event.username == 'visitor') {
        emit(AuthAuthenticated(
          userId: '1',
          username: event.username,
          email: 'visitor@example.com',
          role: UserRole.visitor,
        ));
      } else {
        emit(AuthAuthenticated(
          userId: '2',
          username: event.username,
          email: '${event.username}@example.com',
          role: UserRole.member,
        ));
      }
    } catch (e) {
      emit(AuthError(message: '登录失败: $e'));
    }
  }

  /// 处理注册请求
  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      // TODO: 调用注册 API
      await Future.delayed(const Duration(seconds: 1));

      // 注册成功后自动登录为访客状态
      emit(AuthAuthenticated(
        userId: '1',
        username: event.username,
        email: event.email,
        role: UserRole.visitor,
      ));
    } catch (e) {
      emit(AuthError(message: '注册失败: $e'));
    }
  }

  /// 处理登出请求
  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      // TODO: 调用登出 API，清除本地存储
      await Future.delayed(const Duration(milliseconds: 500));
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(message: '登出失败: $e'));
    }
  }

  /// 检查登录状态
  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      // TODO: 检查本地存储的 Token
      await Future.delayed(const Duration(milliseconds: 500));

      // 模拟未登录状态
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }
}

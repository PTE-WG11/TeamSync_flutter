import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/mock_dashboard_repository.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

/// 仪表盘 BLoC
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final MockDashboardRepository _repository;

  DashboardBloc({MockDashboardRepository? repository})
      : _repository = repository ?? MockDashboardRepository(),
        super(DashboardInitial()) {
    on<DashboardDataRequested>(_onDataRequested);
    on<DashboardDataRefreshed>(_onDataRefreshed);
    on<DashboardTimeRangeChanged>(_onTimeRangeChanged);
  }

  /// 处理数据请求
  Future<void> _onDataRequested(
    DashboardDataRequested event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());

    try {
      // 默认使用"本周"数据
      const timeRange = TimeRange.week;
      
      final stats = await _repository.getDashboardStats(timeRange: timeRange);
      final projects = await _repository.getRecentProjects(timeRange: timeRange);
      final workloads = await _repository.getMemberWorkloads(timeRange: timeRange);

      emit(DashboardLoaded(
        stats: stats,
        projects: projects,
        memberWorkloads: workloads,
        timeRange: '本周',
      ));
    } catch (e) {
      emit(DashboardError(message: '加载数据失败: $e'));
    }
  }

  /// 处理刷新请求
  Future<void> _onDataRefreshed(
    DashboardDataRefreshed event,
    Emitter<DashboardState> emit,
  ) async {
    final currentState = state;
    TimeRange timeRange = TimeRange.week;
    String timeRangeLabel = '本周';
    
    if (currentState is DashboardLoaded) {
      timeRangeLabel = currentState.timeRange;
      timeRange = TimeRange.fromString(timeRangeLabel);
      // 保持当前数据显示，重新加载
      emit(DashboardLoading());
    }

    try {
      final stats = await _repository.getDashboardStats(timeRange: timeRange);
      final projects = await _repository.getRecentProjects(timeRange: timeRange);
      final workloads = await _repository.getMemberWorkloads(timeRange: timeRange);

      emit(DashboardLoaded(
        stats: stats,
        projects: projects,
        memberWorkloads: workloads,
        timeRange: timeRangeLabel,
      ));
    } catch (e) {
      emit(DashboardError(message: '刷新数据失败: $e'));
    }
  }

  /// 处理时间范围切换
  Future<void> _onTimeRangeChanged(
    DashboardTimeRangeChanged event,
    Emitter<DashboardState> emit,
  ) async {
    final currentState = state;
    if (currentState is DashboardLoaded) {
      // 切换到加载状态
      emit(DashboardLoading());
      
      try {
        // 根据时间范围字符串获取枚举值
        final timeRange = TimeRange.fromString(event.timeRange);
        
        // 重新加载该时间范围的数据
        final stats = await _repository.getDashboardStats(timeRange: timeRange);
        final projects = await _repository.getRecentProjects(timeRange: timeRange);
        final workloads = await _repository.getMemberWorkloads(timeRange: timeRange);

        emit(DashboardLoaded(
          stats: stats,
          projects: projects,
          memberWorkloads: workloads,
          timeRange: event.timeRange,
        ));
      } catch (e) {
        // 如果加载失败，恢复原状态但更新时间范围
        emit(currentState.copyWith(timeRange: event.timeRange));
      }
    }
  }
}

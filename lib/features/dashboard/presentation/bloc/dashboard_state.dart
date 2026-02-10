import 'package:equatable/equatable.dart';

import '../../domain/entities/dashboard_stats.dart';
import '../../domain/entities/member_workload.dart';
import '../../domain/entities/project_summary.dart';

/// 仪表盘状态基类
abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

/// 初始状态
class DashboardInitial extends DashboardState {}

/// 加载中
class DashboardLoading extends DashboardState {}

/// 数据加载成功
class DashboardLoaded extends DashboardState {
  /// 统计数据
  final DashboardStats stats;
  
  /// 项目列表
  final List<ProjectSummary> projects;
  
  /// 成员工作量
  final List<MemberWorkload> memberWorkloads;
  
  /// 选中时间范围
  final String timeRange;

  const DashboardLoaded({
    required this.stats,
    required this.projects,
    required this.memberWorkloads,
    this.timeRange = '本周',
  });

  /// 复制并修改
  DashboardLoaded copyWith({
    DashboardStats? stats,
    List<ProjectSummary>? projects,
    List<MemberWorkload>? memberWorkloads,
    String? timeRange,
  }) {
    return DashboardLoaded(
      stats: stats ?? this.stats,
      projects: projects ?? this.projects,
      memberWorkloads: memberWorkloads ?? this.memberWorkloads,
      timeRange: timeRange ?? this.timeRange,
    );
  }

  @override
  List<Object?> get props => [stats, projects, memberWorkloads, timeRange];
}

/// 加载失败
class DashboardError extends DashboardState {
  final String message;

  const DashboardError({required this.message});

  @override
  List<Object?> get props => [message];
}

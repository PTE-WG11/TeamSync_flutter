import 'package:equatable/equatable.dart';

/// 仪表盘统计实体
class DashboardStats extends Equatable {
  /// 活跃项目数
  final int activeProjects;
  
  /// 总任务数
  final int totalTasks;
  
  /// 完成率 (0-100)
  final double completionRate;
  
  /// 逾期任务数
  final int overdueTasks;
  
  /// 总项目数
  final int totalProjects;
  
  /// 已归档项目数
  final int archivedProjects;

  const DashboardStats({
    required this.activeProjects,
    required this.totalTasks,
    required this.completionRate,
    required this.overdueTasks,
    required this.totalProjects,
    required this.archivedProjects,
  });

  /// 空数据
  static const DashboardStats empty = DashboardStats(
    activeProjects: 0,
    totalTasks: 0,
    completionRate: 0.0,
    overdueTasks: 0,
    totalProjects: 0,
    archivedProjects: 0,
  );

  @override
  List<Object?> get props => [
        activeProjects,
        totalTasks,
        completionRate,
        overdueTasks,
        totalProjects,
        archivedProjects,
      ];
}

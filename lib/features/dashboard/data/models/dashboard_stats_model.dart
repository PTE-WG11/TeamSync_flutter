import '../../domain/entities/dashboard_stats.dart';

/// 仪表盘统计数据模型
class DashboardStatsModel extends DashboardStats {
  const DashboardStatsModel({
    required super.activeProjects,
    required super.totalTasks,
    required super.completionRate,
    required super.overdueTasks,
    required super.totalProjects,
    required super.archivedProjects,
  });

  /// 从 JSON 转换
  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return DashboardStatsModel(
      activeProjects: json['active_projects'] ?? 0,
      totalTasks: json['total_tasks'] ?? 0,
      completionRate: (json['completion_rate'] ?? 0.0).toDouble(),
      overdueTasks: json['overdue_tasks'] ?? 0,
      totalProjects: json['total_projects'] ?? 0,
      archivedProjects: json['archived_projects'] ?? 0,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'active_projects': activeProjects,
      'total_tasks': totalTasks,
      'completion_rate': completionRate,
      'overdue_tasks': overdueTasks,
      'total_projects': totalProjects,
      'archived_projects': archivedProjects,
    };
  }

  /// 从实体转换
  factory DashboardStatsModel.fromEntity(DashboardStats entity) {
    return DashboardStatsModel(
      activeProjects: entity.activeProjects,
      totalTasks: entity.totalTasks,
      completionRate: entity.completionRate,
      overdueTasks: entity.overdueTasks,
      totalProjects: entity.totalProjects,
      archivedProjects: entity.archivedProjects,
    );
  }
}

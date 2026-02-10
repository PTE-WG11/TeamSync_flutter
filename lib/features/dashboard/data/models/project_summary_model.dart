import '../../domain/entities/project_summary.dart';

/// 项目摘要数据模型
class ProjectSummaryModel extends ProjectSummary {
  const ProjectSummaryModel({
    required super.id,
    required super.title,
    required super.description,
    required super.status,
    required super.progress,
    required super.completedTasks,
    required super.totalTasks,
    required super.memberCount,
    required super.startDate,
    required super.endDate,
    super.overdueTaskCount = 0,
  });

  /// 从 JSON 转换
  factory ProjectSummaryModel.fromJson(Map<String, dynamic> json) {
    return ProjectSummaryModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'planning',
      progress: (json['progress'] ?? 0.0).toDouble(),
      completedTasks: json['completed_tasks'] ?? 0,
      totalTasks: json['total_tasks'] ?? 0,
      memberCount: json['member_count'] ?? 0,
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      overdueTaskCount: json['overdue_task_count'] ?? 0,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'progress': progress,
      'completed_tasks': completedTasks,
      'total_tasks': totalTasks,
      'member_count': memberCount,
      'start_date': startDate,
      'end_date': endDate,
      'overdue_task_count': overdueTaskCount,
    };
  }

  /// 从实体转换
  factory ProjectSummaryModel.fromEntity(ProjectSummary entity) {
    return ProjectSummaryModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      status: entity.status,
      progress: entity.progress,
      completedTasks: entity.completedTasks,
      totalTasks: entity.totalTasks,
      memberCount: entity.memberCount,
      startDate: entity.startDate,
      endDate: entity.endDate,
      overdueTaskCount: entity.overdueTaskCount,
    );
  }
}

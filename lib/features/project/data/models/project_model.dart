import '../../domain/entities/project.dart';

/// 项目成员模型
class ProjectMemberModel extends ProjectMember {
  const ProjectMemberModel({
    required super.id,
    required super.username,
    required super.role,
    super.avatar,
  });

  factory ProjectMemberModel.fromJson(Map<String, dynamic> json) {
    return ProjectMemberModel(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      role: json['role'] ?? 'member',
      avatar: json['avatar'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'role': role,
      'avatar': avatar,
    };
  }
}

/// 任务统计模型
class TaskStatsModel extends TaskStats {
  const TaskStatsModel({
    required super.total,
    required super.planning,
    required super.pending,
    required super.inProgress,
    required super.completed,
    required super.overdue,
  });

  factory TaskStatsModel.fromJson(Map<String, dynamic> json) {
    return TaskStatsModel(
      total: json['total'] ?? 0,
      planning: json['planning'] ?? 0,
      pending: json['pending'] ?? 0,
      inProgress: json['in_progress'] ?? 0,
      completed: json['completed'] ?? 0,
      overdue: json['overdue'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'planning': planning,
      'pending': pending,
      'in_progress': inProgress,
      'completed': completed,
      'overdue': overdue,
    };
  }
}

/// 项目模型
class ProjectModel extends Project {
  const ProjectModel({
    required super.id,
    required super.title,
    super.description,
    required super.status,
    required super.progress,
    super.memberCount,
    super.overdueTaskCount,
    super.isArchived,
    super.startDate,
    super.endDate,
    super.createdBy,
    super.members,
    super.taskStats,
    super.createdAt,
    super.updatedAt,
    super.archivedAt,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'planning',
      progress: (json['progress'] ?? 0.0).toDouble(),
      memberCount: json['member_count'] ?? 0,
      overdueTaskCount: json['overdue_task_count'] ?? 0,
      isArchived: json['is_archived'] ?? false,
      startDate: json['start_date'],
      endDate: json['end_date'],
      createdBy: json['created_by'] != null
          ? ProjectMemberModel.fromJson(json['created_by'])
          : null,
      members: json['members'] != null
          ? (json['members'] as List)
              .map((m) => ProjectMemberModel.fromJson(m))
              .toList()
          : const [],
      taskStats: json['task_stats'] != null
          ? TaskStatsModel.fromJson(json['task_stats'])
          : null,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      archivedAt: json['archived_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'progress': progress,
      'member_count': memberCount,
      'overdue_task_count': overdueTaskCount,
      'is_archived': isArchived,
      'start_date': startDate,
      'end_date': endDate,
      'created_by': createdBy != null
          ? ProjectMemberModel(
              id: createdBy!.id,
              username: createdBy!.username,
              role: createdBy!.role,
              avatar: createdBy!.avatar,
            ).toJson()
          : null,
      'members': members
          .map((m) => ProjectMemberModel(
                id: m.id,
                username: m.username,
                role: m.role,
                avatar: m.avatar,
              ).toJson())
          .toList(),
      'task_stats': taskStats != null
          ? TaskStatsModel(
              total: taskStats!.total,
              planning: taskStats!.planning,
              pending: taskStats!.pending,
              inProgress: taskStats!.inProgress,
              completed: taskStats!.completed,
              overdue: taskStats!.overdue,
            ).toJson()
          : null,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'archived_at': archivedAt,
    };
  }

  /// 从实体创建模型
  factory ProjectModel.fromEntity(Project entity) {
    return ProjectModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      status: entity.status,
      progress: entity.progress,
      memberCount: entity.memberCount,
      overdueTaskCount: entity.overdueTaskCount,
      isArchived: entity.isArchived,
      startDate: entity.startDate,
      endDate: entity.endDate,
      createdBy: entity.createdBy,
      members: entity.members,
      taskStats: entity.taskStats,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      archivedAt: entity.archivedAt,
    );
  }
}

/// 创建项目请求
class CreateProjectRequest {
  final String title;
  final String? description;
  final String status;
  final String? startDate;
  final String? endDate;
  final List<int> memberIds;

  const CreateProjectRequest({
    required this.title,
    this.description,
    this.status = 'planning',
    this.startDate,
    this.endDate,
    required this.memberIds,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'status': status,
      'start_date': startDate,
      'end_date': endDate,
      'member_ids': memberIds,
    };
  }
}

/// 更新项目请求
class UpdateProjectRequest {
  final String? title;
  final String? description;
  final String? status;
  final String? startDate;
  final String? endDate;

  const UpdateProjectRequest({
    this.title,
    this.description,
    this.status,
    this.startDate,
    this.endDate,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (title != null) data['title'] = title;
    if (description != null) data['description'] = description;
    if (status != null) data['status'] = status;
    if (startDate != null) data['start_date'] = startDate;
    if (endDate != null) data['end_date'] = endDate;
    return data;
  }
}

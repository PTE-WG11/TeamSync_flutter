import '../../domain/entities/task.dart';

/// 任务数据模型
class TaskModel extends Task {
  const TaskModel({
    required super.id,
    required super.projectId,
    required super.title,
    super.description,
    required super.assigneeId,
    required super.assigneeName,
    super.assigneeAvatar,
    required super.status,
    required super.priority,
    required super.level,
    super.parentId,
    super.path = '',
    super.startDate,
    super.endDate,
    required super.createdAt,
    required super.updatedAt,
    super.children = const [],
    super.subtaskCount = 0,
    super.completedSubtaskCount = 0,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as int,
      projectId: json['project_id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      assigneeId: json['assignee_id'] as int? ?? json['assignee']['id'] as int,
      assigneeName: json['assignee_name'] as String? ?? 
          (json['assignee'] as Map<String, dynamic>?)?['username'] as String? ?? 
          '未知',
      assigneeAvatar: json['assignee_avatar'] as String? ??
          (json['assignee'] as Map<String, dynamic>?)?['avatar'] as String?,
      status: json['status'] as String,
      priority: json['priority'] as String? ?? 'medium',
      level: json['level'] as int? ?? 1,
      parentId: json['parent_id'] as int?,
      path: json['path'] as String? ?? '',
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      children: (json['children'] as List<dynamic>?)
              ?.map((e) => TaskModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      subtaskCount: json['subtask_count'] as int? ?? 0,
      completedSubtaskCount: json['completed_subtask_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project_id': projectId,
      'title': title,
      'description': description,
      'assignee_id': assigneeId,
      'assignee_name': assigneeName,
      'assignee_avatar': assigneeAvatar,
      'status': status,
      'priority': priority,
      'level': level,
      'parent_id': parentId,
      'path': path,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'children': children.map((e) => (e as TaskModel).toJson()).toList(),
      'subtask_count': subtaskCount,
      'completed_subtask_count': completedSubtaskCount,
    };
  }

  factory TaskModel.fromEntity(Task entity) {
    return TaskModel(
      id: entity.id,
      projectId: entity.projectId,
      title: entity.title,
      description: entity.description,
      assigneeId: entity.assigneeId,
      assigneeName: entity.assigneeName,
      assigneeAvatar: entity.assigneeAvatar,
      status: entity.status,
      priority: entity.priority,
      level: entity.level,
      parentId: entity.parentId,
      path: entity.path,
      startDate: entity.startDate,
      endDate: entity.endDate,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      children: entity.children
          .map((e) => TaskModel.fromEntity(e))
          .toList(),
      subtaskCount: entity.subtaskCount,
      completedSubtaskCount: entity.completedSubtaskCount,
    );
  }
}

import '../../../attachment/data/models/attachment_model.dart';
import '../../../attachment/domain/entities/attachment.dart';
import '../../domain/entities/task.dart';

/// 任务项目信息数据模型
class TaskProjectInfoModel extends TaskProjectInfo {
  const TaskProjectInfoModel({
    required super.id,
    required super.title,
  });

  factory TaskProjectInfoModel.fromJson(Map<String, dynamic> json) {
    return TaskProjectInfoModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '未知项目',
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
    };
  }
}

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
    super.attachments = const [],
    super.project,
    super.normalFlag,
    super.canView = true,
    super.canEdit = false,
    super.canHaveSubtasks = false,
    super.isOverdue = false,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    // 安全获取 assignee 信息
    // assignee 可能是 int (用户ID) 或 Map (用户对象) 或 null
    final dynamic assigneeRaw = json['assignee'];
    Map<String, dynamic>? assigneeData;
    int? assigneeIdFromAssignee;
    
    if (assigneeRaw is int) {
      assigneeIdFromAssignee = assigneeRaw;
    } else if (assigneeRaw is Map<String, dynamic>) {
      assigneeData = assigneeRaw;
      assigneeIdFromAssignee = assigneeData['id'] as int?;
    }
    
    final assigneeId = json['assignee_id'] as int? ?? 
        assigneeIdFromAssignee ?? 
        0;
    final assigneeName = json['assignee_name'] as String? ?? 
        assigneeData?['username'] as String? ?? 
        assigneeData?['name'] as String? ?? 
        '';  // 空字符串表示未分配
    final assigneeAvatar = json['assignee_avatar'] as String? ??
        assigneeData?['avatar'] as String?;

    // 解析 project 信息（可能是对象或ID）
    int projectId = 0;
    TaskProjectInfoModel? projectInfo;
    final dynamic projectRaw = json['project'];
    if (projectRaw is int) {
      projectId = projectRaw;
    } else if (projectRaw is Map<String, dynamic>) {
      projectId = projectRaw['id'] as int? ?? 0;
      projectInfo = TaskProjectInfoModel.fromJson(projectRaw);
    }
    // 优先使用 project_id 字段
    projectId = json['project_id'] as int? ?? projectId;

    // 安全解析日期
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      try {
        return DateTime.parse(value as String);
      } catch (e) {
        return DateTime.now();
      }
    }

    // 提前解析 level 用于后续判断
    final level = json['level'] as int? ?? 1;

    // 解析子任务
    List<Task> children = [];
    final dynamic childrenRaw = json['children'] ?? json['subtasks'];
    if (childrenRaw is List) {
      children = childrenRaw
          .whereType<Map<String, dynamic>>()
          .map((e) => TaskModel.fromJson(e))
          .toList();
    }

    // 解析附件列表
    List<AttachmentModel> attachments = [];
    final dynamic attachmentsRaw = json['attachments'];
    if (attachmentsRaw is List) {
      attachments = attachmentsRaw
          .whereType<Map<String, dynamic>>()
          .map((e) => AttachmentModel.fromJson(e))
          .toList();
    }

    return TaskModel(
      id: json['id'] as int? ?? 0,
      projectId: projectId,
      title: json['title'] as String? ?? '未命名任务',
      description: json['description'] as String?,
      assigneeId: assigneeId,
      assigneeName: assigneeName,
      assigneeAvatar: assigneeAvatar,
      status: json['status'] as String? ?? 'planning',
      priority: json['priority'] as String? ?? 'medium',
      level: level,
      parentId: json['parent_id'] as int?,
      path: json['path'] as String? ?? '',
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null
          ? DateTime.tryParse(json['end_date'] as String)
          : null,
      createdAt: parseDateTime(json['created_at']),
      updatedAt: parseDateTime(json['updated_at']),
      children: children,
      subtaskCount: json['subtask_count'] as int? ?? children.length,
      completedSubtaskCount: json['completed_subtask_count'] as int? ?? 
          children.where((c) => c.status == 'completed').length,
      attachments: attachments,
      project: projectInfo,
      normalFlag: json['normal_flag'] as String?,
      canView: json['can_view'] as bool? ?? true,
      canEdit: json['can_edit'] as bool? ?? false,
      canHaveSubtasks: json['can_have_subtasks'] as bool? ?? (level < 3),
      isOverdue: json['is_overdue'] as bool? ?? (json['normal_flag'] == 'overdue'),
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
      'attachments': attachments.map((e) => (e as AttachmentModel).toJson()).toList(),
      'project': project?.toJson(),
      'normal_flag': normalFlag,
      'can_view': canView,
      'can_edit': canEdit,
      'can_have_subtasks': canHaveSubtasks,
      'is_overdue': isOverdue,
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
      attachments: entity.attachments
          .map((e) => AttachmentModel.fromEntity(e))
          .cast<Attachment>()
          .toList(),
      children: entity.children
          .map((e) => TaskModel.fromEntity(e))
          .toList(),
      subtaskCount: entity.subtaskCount,
      completedSubtaskCount: entity.completedSubtaskCount,
      project: entity.project != null 
          ? TaskProjectInfoModel(id: entity.project!.id, title: entity.project!.title)
          : null,
      normalFlag: entity.normalFlag,
      canView: entity.canView,
      canEdit: entity.canEdit,
      canHaveSubtasks: entity.canHaveSubtasks,
      isOverdue: entity.isOverdue,
    );
  }
}

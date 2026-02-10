import 'package:equatable/equatable.dart';

/// 任务实体（支持主任务和子任务）
class Task extends Equatable {
  final int id;
  final int projectId;
  final String title;
  final String? description;
  final int assigneeId;
  final String assigneeName;
  final String? assigneeAvatar;
  final String status;
  final String priority;
  final int level; // 1=主任务, 2=子任务, 3=孙任务
  final int? parentId;
  final String path; // 路径枚举 '/1/12/34'
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Task> children; // 子任务列表
  final int subtaskCount; // 子任务数量
  final int completedSubtaskCount; // 已完成子任务数量

  const Task({
    required this.id,
    required this.projectId,
    required this.title,
    this.description,
    required this.assigneeId,
    required this.assigneeName,
    this.assigneeAvatar,
    required this.status,
    required this.priority,
    required this.level,
    this.parentId,
    this.path = '',
    this.startDate,
    this.endDate,
    required this.createdAt,
    required this.updatedAt,
    this.children = const [],
    this.subtaskCount = 0,
    this.completedSubtaskCount = 0,
  });

  /// 是否为主任务
  bool get isMainTask => level == 1;

  /// 是否为子任务
  bool get isSubTask => level > 1;

  /// 是否可以创建子任务（层级小于3）
  bool get canCreateSubTask => level < 3;

  /// 是否已完成
  bool get isCompleted => status == 'completed';

  /// 任务编号显示
  String get displayId => '#T-$id';

  /// 优先级显示文本
  String get priorityDisplay {
    switch (priority) {
      case 'urgent':
        return '紧急';
      case 'high':
        return '高';
      case 'medium':
        return '中';
      case 'low':
        return '低';
      default:
        return '中';
    }
  }

  /// 状态显示文本
  String get statusDisplay {
    switch (status) {
      case 'planning':
        return '规划中';
      case 'pending':
        return '待处理';
      case 'in_progress':
        return '进行中';
      case 'completed':
        return '已完成';
      default:
        return '未知';
    }
  }

  /// 是否有子任务
  bool get hasChildren => children.isNotEmpty || subtaskCount > 0;

  /// 子任务进度文本
  String get subtaskProgressText =>
      '子任务: $subtaskCount 完成: $completedSubtaskCount';

  @override
  List<Object?> get props => [
        id,
        projectId,
        title,
        description,
        assigneeId,
        assigneeName,
        assigneeAvatar,
        status,
        priority,
        level,
        parentId,
        path,
        startDate,
        endDate,
        createdAt,
        updatedAt,
        children,
        subtaskCount,
        completedSubtaskCount,
      ];

  Task copyWith({
    int? id,
    int? projectId,
    String? title,
    String? description,
    int? assigneeId,
    String? assigneeName,
    String? assigneeAvatar,
    String? status,
    String? priority,
    int? level,
    int? parentId,
    String? path,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Task>? children,
    int? subtaskCount,
    int? completedSubtaskCount,
  }) {
    return Task(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      assigneeId: assigneeId ?? this.assigneeId,
      assigneeName: assigneeName ?? this.assigneeName,
      assigneeAvatar: assigneeAvatar ?? this.assigneeAvatar,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      level: level ?? this.level,
      parentId: parentId ?? this.parentId,
      path: path ?? this.path,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      children: children ?? this.children,
      subtaskCount: subtaskCount ?? this.subtaskCount,
      completedSubtaskCount:
          completedSubtaskCount ?? this.completedSubtaskCount,
    );
  }
}

/// 创建任务请求
class CreateTaskRequest extends Equatable {
  final String title;
  final String? description;
  final int assigneeId;
  final String? status;
  final String? priority;
  final DateTime? startDate;
  final DateTime? endDate;

  const CreateTaskRequest({
    required this.title,
    this.description,
    required this.assigneeId,
    this.status = 'planning',
    this.priority = 'medium',
    this.startDate,
    this.endDate,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'assignee_id': assigneeId,
        'status': status,
        'priority': priority,
        'start_date': startDate?.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
      };

  @override
  List<Object?> get props => [
        title,
        description,
        assigneeId,
        status,
        priority,
        startDate,
        endDate,
      ];
}

/// 创建子任务请求
class CreateSubTaskRequest extends Equatable {
  final String title;
  final String? description;
  final String? status;
  final String? priority;
  final DateTime? startDate;
  final DateTime? endDate;

  const CreateSubTaskRequest({
    required this.title,
    this.description,
    this.status = 'planning',
    this.priority = 'medium',
    this.startDate,
    this.endDate,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'status': status,
        'priority': priority,
        'start_date': startDate?.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
      };

  @override
  List<Object?> get props => [
        title,
        description,
        status,
        priority,
        startDate,
        endDate,
      ];
}

/// 更新任务请求
class UpdateTaskRequest extends Equatable {
  final String? title;
  final String? description;
  final String? status;
  final String? priority;
  final int? assigneeId;
  final DateTime? startDate;
  final DateTime? endDate;

  const UpdateTaskRequest({
    this.title,
    this.description,
    this.status,
    this.priority,
    this.assigneeId,
    this.startDate,
    this.endDate,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (title != null) map['title'] = title;
    if (description != null) map['description'] = description;
    if (status != null) map['status'] = status;
    if (priority != null) map['priority'] = priority;
    if (assigneeId != null) map['assignee_id'] = assigneeId;
    if (startDate != null) map['start_date'] = startDate!.toIso8601String();
    if (endDate != null) map['end_date'] = endDate!.toIso8601String();
    return map;
  }

  @override
  List<Object?> get props => [
        title,
        description,
        status,
        priority,
        assigneeId,
        startDate,
        endDate,
      ];
}

/// 任务筛选条件
class TaskFilter extends Equatable {
  final String? status;
  final String? assignee;
  final String? search;

  const TaskFilter({
    this.status,
    this.assignee,
    this.search,
  });

  TaskFilter copyWith({
    String? status,
    String? assignee,
    String? search,
  }) {
    return TaskFilter(
      status: status ?? this.status,
      assignee: assignee ?? this.assignee,
      search: search ?? this.search,
    );
  }

  @override
  List<Object?> get props => [status, assignee, search];
}

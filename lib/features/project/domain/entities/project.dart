import 'package:equatable/equatable.dart';

/// 项目成员
class ProjectMember extends Equatable {
  final int id;
  final String username;
  final String role;
  final String? avatar;

  const ProjectMember({
    required this.id,
    required this.username,
    required this.role,
    this.avatar,
  });

  @override
  List<Object?> get props => [id, username, role, avatar];
}

/// 任务统计
class TaskStats extends Equatable {
  final int total;
  final int planning;
  final int pending;
  final int inProgress;
  final int completed;
  final int overdue;

  const TaskStats({
    required this.total,
    required this.planning,
    required this.pending,
    required this.inProgress,
    required this.completed,
    required this.overdue,
  });

  @override
  List<Object?> get props => [total, planning, pending, inProgress, completed, overdue];
}

/// 项目实体
class Project extends Equatable {
  final int id;
  final String title;
  final String description;
  final String status;
  final double progress;
  final int memberCount;
  final int overdueTaskCount;
  final bool isArchived;
  final String? startDate;
  final String? endDate;
  final ProjectMember? createdBy;
  final List<ProjectMember> members;
  final TaskStats? taskStats;
  final String? createdAt;
  final String? updatedAt;
  final String? archivedAt;

  const Project({
    required this.id,
    required this.title,
    this.description = '',
    required this.status,
    required this.progress,
    this.memberCount = 0,
    this.overdueTaskCount = 0,
    this.isArchived = false,
    this.startDate,
    this.endDate,
    this.createdBy,
    this.members = const [],
    this.taskStats,
    this.createdAt,
    this.updatedAt,
    this.archivedAt,
  });

  /// 空项目
  static const empty = Project(
    id: 0,
    title: '',
    status: 'planning',
    progress: 0,
  );

  /// 获取状态显示文本
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
      case 'archived':
        return '已归档';
      default:
        return '未知';
    }
  }

  /// 是否已完成
  bool get isCompleted => status == 'completed';

  /// 是否活跃
  bool get isActive => !isArchived && (status == 'in_progress' || status == 'planning' || status == 'pending');

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        status,
        progress,
        memberCount,
        overdueTaskCount,
        isArchived,
        startDate,
        endDate,
        createdBy,
        members,
        taskStats,
        createdAt,
        updatedAt,
        archivedAt,
      ];
}

/// 项目列表筛选条件
class ProjectFilter extends Equatable {
  final String? status;
  final bool includeArchived;
  final String? search;

  const ProjectFilter({
    this.status,
    this.includeArchived = false,
    this.search,
  });

  ProjectFilter copyWith({
    String? status,
    bool? includeArchived,
    String? search,
  }) {
    return ProjectFilter(
      status: status ?? this.status,
      includeArchived: includeArchived ?? this.includeArchived,
      search: search ?? this.search,
    );
  }

  @override
  List<Object?> get props => [status, includeArchived, search];
}

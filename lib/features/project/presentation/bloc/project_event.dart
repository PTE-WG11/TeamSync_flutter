import 'package:equatable/equatable.dart';

import '../../domain/entities/project.dart';

/// 项目事件基类
abstract class ProjectEvent extends Equatable {
  const ProjectEvent();

  @override
  List<Object?> get props => [];
}

// ==================== 项目列表事件 ====================

/// 加载项目列表
class ProjectsLoadRequested extends ProjectEvent {
  final ProjectFilter filter;

  const ProjectsLoadRequested({this.filter = const ProjectFilter()});

  @override
  List<Object?> get props => [filter];
}

/// 刷新项目列表
class ProjectsRefreshRequested extends ProjectEvent {
  const ProjectsRefreshRequested();
}

/// 项目筛选条件变更
class ProjectsFilterChanged extends ProjectEvent {
  final ProjectFilter filter;

  const ProjectsFilterChanged(this.filter);

  @override
  List<Object?> get props => [filter];
}

/// 搜索关键词变更
class ProjectsSearchChanged extends ProjectEvent {
  final String search;

  const ProjectsSearchChanged(this.search);

  @override
  List<Object?> get props => [search];
}

/// 加载更多项目（分页）
class ProjectsLoadMoreRequested extends ProjectEvent {
  const ProjectsLoadMoreRequested();
}

// ==================== 单个项目事件 ====================

/// 加载项目详情
class ProjectDetailRequested extends ProjectEvent {
  final int projectId;

  const ProjectDetailRequested(this.projectId);

  @override
  List<Object?> get props => [projectId];
}

/// 清除当前项目详情
class ProjectDetailCleared extends ProjectEvent {
  const ProjectDetailCleared();
}

// ==================== 创建项目事件 ====================

/// 创建项目
class ProjectCreateRequested extends ProjectEvent {
  final String title;
  final String? description;
  final String status;
  final String? startDate;
  final String? endDate;
  final List<int> memberIds;

  const ProjectCreateRequested({
    required this.title,
    this.description,
    this.status = 'planning',
    this.startDate,
    this.endDate,
    required this.memberIds,
  });

  @override
  List<Object?> get props => [
        title,
        description,
        status,
        startDate,
        endDate,
        memberIds,
      ];
}

/// 加载可用成员列表
class ProjectAvailableMembersRequested extends ProjectEvent {
  const ProjectAvailableMembersRequested();
}

// ==================== 更新项目事件 ====================

/// 更新项目
class ProjectUpdateRequested extends ProjectEvent {
  final int projectId;
  final String? title;
  final String? description;
  final String? status;
  final String? startDate;
  final String? endDate;

  const ProjectUpdateRequested({
    required this.projectId,
    this.title,
    this.description,
    this.status,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [
        projectId,
        title,
        description,
        status,
        startDate,
        endDate,
      ];
}

/// 更新项目成员
class ProjectMembersUpdateRequested extends ProjectEvent {
  final int projectId;
  final List<int> memberIds;

  const ProjectMembersUpdateRequested({
    required this.projectId,
    required this.memberIds,
  });

  @override
  List<Object?> get props => [projectId, memberIds];
}

// ==================== 归档/删除项目事件 ====================

/// 归档项目
class ProjectArchiveRequested extends ProjectEvent {
  final int projectId;

  const ProjectArchiveRequested(this.projectId);

  @override
  List<Object?> get props => [projectId];
}

/// 删除项目
class ProjectDeleteRequested extends ProjectEvent {
  final int projectId;

  const ProjectDeleteRequested(this.projectId);

  @override
  List<Object?> get props => [projectId];
}

// ==================== 项目任务事件 ====================

/// 加载项目任务列表
class ProjectTasksLoadRequested extends ProjectEvent {
  final int projectId;
  final String view; // 'tree' | 'flat'

  const ProjectTasksLoadRequested({
    required this.projectId,
    this.view = 'tree',
  });

  @override
  List<Object?> get props => [projectId, view];
}

/// 创建任务
class ProjectTaskCreateRequested extends ProjectEvent {
  final int projectId;
  final String title;
  final String? description;
  final int assigneeId;
  final String? status;
  final String? priority;
  final DateTime? startDate;
  final DateTime? endDate;

  const ProjectTaskCreateRequested({
    required this.projectId,
    required this.title,
    this.description,
    required this.assigneeId,
    this.status = 'planning',
    this.priority = 'medium',
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [
        projectId,
        title,
        description,
        assigneeId,
        status,
        priority,
        startDate,
        endDate,
      ];
}

/// 创建子任务
class ProjectSubTaskCreateRequested extends ProjectEvent {
  final int parentTaskId;
  final String title;
  final String? description;
  final String? status;
  final String? priority;
  final DateTime? startDate;
  final DateTime? endDate;

  const ProjectSubTaskCreateRequested({
    required this.parentTaskId,
    required this.title,
    this.description,
    this.status = 'planning',
    this.priority = 'medium',
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [
        parentTaskId,
        title,
        description,
        status,
        priority,
        startDate,
        endDate,
      ];
}

/// 更新任务状态
class ProjectTaskStatusUpdateRequested extends ProjectEvent {
  final int taskId;
  final String newStatus;

  const ProjectTaskStatusUpdateRequested({
    required this.taskId,
    required this.newStatus,
  });

  @override
  List<Object?> get props => [taskId, newStatus];
}

/// 删除任务
class ProjectTaskDeleteRequested extends ProjectEvent {
  final int taskId;

  const ProjectTaskDeleteRequested(this.taskId);

  @override
  List<Object?> get props => [taskId];
}

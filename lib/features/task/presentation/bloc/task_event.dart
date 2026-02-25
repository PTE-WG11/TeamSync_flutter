import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/task.dart';

/// 任务管理事件
abstract class TaskEvent extends Equatable {
  const TaskEvent();

  @override
  List<Object?> get props => [];
}

/// 视图模式切换
class TaskViewModeChanged extends TaskEvent {
  final TaskViewMode viewMode;

  const TaskViewModeChanged(this.viewMode);

  @override
  List<Object?> get props => [viewMode];
}

/// 请求加载任务列表
class TasksLoadRequested extends TaskEvent {
  const TasksLoadRequested();
}

/// 筛选条件变更
class TaskFilterChanged extends TaskEvent {
  final TaskFilter filter;

  const TaskFilterChanged(this.filter);

  @override
  List<Object?> get props => [filter];
}

/// 项目筛选变更
class TaskProjectFilterChanged extends TaskEvent {
  final int? projectId;

  const TaskProjectFilterChanged(this.projectId);

  @override
  List<Object?> get props => [projectId];
}

/// 任务状态变更
class TaskStatusChanged extends TaskEvent {
  final int taskId;
  final String status;

  const TaskStatusChanged({
    required this.taskId,
    required this.status,
  });

  @override
  List<Object?> get props => [taskId, status];
}

/// 日期范围变更
class TaskDateRangeChanged extends TaskEvent {
  final DateTime startDate;
  final DateTime endDate;

  const TaskDateRangeChanged({
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [startDate, endDate];
}

/// 创建任务
class TaskCreated extends TaskEvent {
  final int projectId;
  final CreateTaskRequest request;

  const TaskCreated({
    required this.projectId,
    required this.request,
  });

  @override
  List<Object?> get props => [projectId, request];
}

/// 更新任务
class TaskUpdated extends TaskEvent {
  final int taskId;
  final UpdateTaskRequest request;

  const TaskUpdated({
    required this.taskId,
    required this.request,
  });

  @override
  List<Object?> get props => [taskId, request];
}

/// 删除任务
class TaskDeleted extends TaskEvent {
  final int taskId;

  const TaskDeleted(this.taskId);

  @override
  List<Object?> get props => [taskId];
}

/// 子任务状态切换（勾选按钮）
class SubTaskStatusToggled extends TaskEvent {
  final int subTaskId;

  const SubTaskStatusToggled(this.subTaskId);

  @override
  List<Object?> get props => [subTaskId];
}

/// 主任务展开/收起
class TaskExpandToggled extends TaskEvent {
  final int taskId;

  const TaskExpandToggled(this.taskId);

  @override
  List<Object?> get props => [taskId];
}

/// 请求加载子任务
class SubTasksLoadRequested extends TaskEvent {
  final int parentTaskId;

  const SubTasksLoadRequested(this.parentTaskId);

  @override
  List<Object?> get props => [parentTaskId];
}

/// 创建子任务
class SubTaskCreated extends TaskEvent {
  final int parentTaskId;
  final CreateSubTaskRequest request;

  const SubTaskCreated({
    required this.parentTaskId,
    required this.request,
  });

  @override
  List<Object?> get props => [parentTaskId, request];
}

// ==================== 看板新功能事件 ====================

/// 创建无负责人任务（看板中快速创建）
class UnassignedTaskCreated extends TaskEvent {
  final int projectId;
  final String title;
  final String? description;
  final String priority;

  const UnassignedTaskCreated({
    required this.projectId,
    required this.title,
    this.description,
    this.priority = 'medium',
  });

  @override
  List<Object?> get props => [projectId, title, description, priority];
}

/// 领取任务（从planning拖出时调用）
class TaskClaimed extends TaskEvent {
  final int taskId;
  final String status;        // pending 或 in_progress
  final DateTime endDate;

  const TaskClaimed({
    required this.taskId,
    required this.status,
    required this.endDate,
  });

  @override
  List<Object?> get props => [taskId, status, endDate];
}

/// 视图模式枚举
enum TaskViewMode {
  kanban('看板', Icons.view_column_outlined),
  list('列表', Icons.view_list_outlined),
  gantt('甘特图', Icons.timeline_outlined),
  calendar('日历', Icons.calendar_today_outlined);

  final String label;
  final IconData icon;

  const TaskViewMode(this.label, this.icon);
}

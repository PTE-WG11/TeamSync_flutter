import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/task.dart';
import 'task_bloc.dart';
import 'task_event.dart';

/// 任务状态枚举
enum TaskStatus { initial, loading, success, failure }

/// 任务管理状态
class TaskState extends Equatable {
  final TaskStatus status;
  final TaskViewMode viewMode;
  final List<Task> tasks;
  final List<KanbanColumn> kanbanColumns;
  final Map<DateTime, List<Task>> calendarTasks;
  final DateTimeRange? ganttDateRange;
  final TaskFilter? filter;
  final int? selectedProjectId;
  final int totalCount;
  final String? errorMessage;
  final Set<int> expandedTaskIds; // 展开的主任务ID列表

  const TaskState({
    this.status = TaskStatus.initial,
    this.viewMode = TaskViewMode.kanban, // 默认看板视图
    this.tasks = const [],
    this.kanbanColumns = const [],
    this.calendarTasks = const {},
    this.ganttDateRange,
    this.filter,
    this.selectedProjectId,
    this.totalCount = 0,
    this.errorMessage,
    this.expandedTaskIds = const {},
  });

  TaskState copyWith({
    TaskStatus? status,
    TaskViewMode? viewMode,
    List<Task>? tasks,
    List<KanbanColumn>? kanbanColumns,
    Map<DateTime, List<Task>>? calendarTasks,
    DateTimeRange? ganttDateRange,
    TaskFilter? filter,
    int? selectedProjectId,
    int? totalCount,
    String? errorMessage,
    Set<int>? expandedTaskIds,
  }) {
    return TaskState(
      status: status ?? this.status,
      viewMode: viewMode ?? this.viewMode,
      tasks: tasks ?? this.tasks,
      kanbanColumns: kanbanColumns ?? this.kanbanColumns,
      calendarTasks: calendarTasks ?? this.calendarTasks,
      ganttDateRange: ganttDateRange ?? this.ganttDateRange,
      filter: filter ?? this.filter,
      selectedProjectId: selectedProjectId ?? this.selectedProjectId,
      totalCount: totalCount ?? this.totalCount,
      errorMessage: errorMessage ?? this.errorMessage,
      expandedTaskIds: expandedTaskIds ?? this.expandedTaskIds,
    );
  }

  @override
  List<Object?> get props => [
        status,
        viewMode,
        tasks,
        kanbanColumns,
        calendarTasks,
        ganttDateRange,
        filter,
        selectedProjectId,
        totalCount,
        errorMessage,
        expandedTaskIds,
      ];
}

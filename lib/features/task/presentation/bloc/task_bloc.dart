import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/permissions/permission_service.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import 'task_event.dart';
import 'task_state.dart';

/// 任务管理 BLoC
class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final TaskRepository _taskRepository;

  TaskBloc({
    required TaskRepository taskRepository,
    required PermissionService permissionService,
  })  : _taskRepository = taskRepository,
        super(const TaskState()) {
    on<TaskViewModeChanged>(_onViewModeChanged);
    on<TasksLoadRequested>(_onTasksLoadRequested);
    on<TaskFilterChanged>(_onFilterChanged);
    on<TaskProjectFilterChanged>(_onProjectFilterChanged);
    on<TaskStatusChanged>(_onTaskStatusChanged);
    on<TaskDateRangeChanged>(_onDateRangeChanged);
    on<TaskCreated>(_onTaskCreated);
    on<TaskUpdated>(_onTaskUpdated);
    on<TaskDeleted>(_onTaskDeleted);
    on<TaskExpandToggled>(_onTaskExpandToggled);
    on<SubTaskStatusToggled>(_onSubTaskStatusToggled);
    on<SubTaskCreated>(_onSubTaskCreated);
  }

  /// 视图模式切换
  void _onViewModeChanged(
    TaskViewModeChanged event,
    Emitter<TaskState> emit,
  ) {
    emit(state.copyWith(viewMode: event.viewMode));
    add(const TasksLoadRequested());
  }

  /// 加载任务列表
  Future<void> _onTasksLoadRequested(
    TasksLoadRequested event,
    Emitter<TaskState> emit,
  ) async {
    emit(state.copyWith(status: TaskStatus.loading));

    try {
      switch (state.viewMode) {
        case TaskViewMode.list:
          await _loadListView(emit);
          break;
        case TaskViewMode.kanban:
          await _loadKanbanView(emit);
          break;
        case TaskViewMode.gantt:
          await _loadGanttView(emit);
          break;
        case TaskViewMode.calendar:
          await _loadCalendarView(emit);
          break;
      }
    } catch (e) {
      emit(state.copyWith(
        status: TaskStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  /// 加载列表视图数据 - 只显示主任务
  Future<void> _loadListView(Emitter<TaskState> emit) async {
    final tasks = await _taskRepository.getGlobalListTasks(filter: state.filter);
    final mainTasks = tasks.where((t) => t.isMainTask).toList();
    
    emit(state.copyWith(
      status: TaskStatus.success,
      tasks: tasks,
      totalCount: mainTasks.length,
    ));
  }

  /// 加载看板视图数据 - 显示所有任务（主任务+子任务）
  Future<void> _loadKanbanView(Emitter<TaskState> emit) async {
    final kanbanData = await _taskRepository.getGlobalKanbanTasks(filter: state.filter);
    
    // 从看板列数据中提取所有任务
    final allTasks = kanbanData.expand((col) => col.tasks).toList();
    
    // 转换为UI使用的KanbanColumn格式
    final columns = kanbanData.map((col) => KanbanColumn(
      id: col.id,
      title: col.title,
      color: _parseColor(col.color),
      tasks: col.tasks,
    )).toList();
    
    emit(state.copyWith(
      status: TaskStatus.success,
      tasks: allTasks,
      kanbanColumns: columns,
      totalCount: allTasks.length,
    ));
  }
  
  /// 解析颜色字符串为int
  int _parseColor(String? colorStr) {
    if (colorStr == null || colorStr.isEmpty) return 0xFF94A3B8;
    try {
      // 处理 #RRGGBB 格式
      if (colorStr.startsWith('#')) {
        return int.parse('FF${colorStr.substring(1)}', radix: 16);
      }
      return int.parse(colorStr);
    } catch (e) {
      return 0xFF94A3B8;
    }
  }

  /// 加载甘特图视图数据
  Future<void> _loadGanttView(Emitter<TaskState> emit) async {
    final tasks = await _taskRepository.getGlobalGanttTasks(filter: state.filter);
    
    emit(state.copyWith(
      status: TaskStatus.success,
      tasks: tasks,
      ganttDateRange: _calculateDateRange(tasks),
      totalCount: tasks.length,
    ));
  }

  /// 加载日历视图数据
  Future<void> _loadCalendarView(Emitter<TaskState> emit) async {
    final allTasks = await _taskRepository.getGlobalCalendarTasks(filter: state.filter);
    
    emit(state.copyWith(
      status: TaskStatus.success,
      tasks: allTasks,
      calendarTasks: _buildCalendarTasks(allTasks),
      totalCount: allTasks.length,
    ));
  }

  /// 筛选条件变更
  void _onFilterChanged(
    TaskFilterChanged event,
    Emitter<TaskState> emit,
  ) {
    emit(state.copyWith(filter: event.filter));
    add(const TasksLoadRequested());
  }

  /// 项目筛选变更
  void _onProjectFilterChanged(
    TaskProjectFilterChanged event,
    Emitter<TaskState> emit,
  ) {
    // 更新 filter 中的 projectId
    final currentFilter = state.filter;
    final newFilter = TaskFilter(
      status: currentFilter?.status,
      assignee: currentFilter?.assignee,
      search: currentFilter?.search,
      projectId: event.projectId,
    );
    emit(state.copyWith(
      selectedProjectId: event.projectId,
      filter: newFilter,
    ));
    add(const TasksLoadRequested());
  }

  /// 任务状态变更（看板拖拽）
  Future<void> _onTaskStatusChanged(
    TaskStatusChanged event,
    Emitter<TaskState> emit,
  ) async {
    try {
      // 获取当前任务
      final task = state.tasks.firstWhere((t) => t.id == event.taskId);
      
      // 检查状态流转是否合法（只能相邻状态流转）
      if (!_isValidStatusTransition(task.status, event.status)) {
        emit(state.copyWith(errorMessage: '无效的状态流转'));
        return;
      }

      // 更新任务状态
      await _taskRepository.updateTask(
        event.taskId,
        UpdateTaskRequest(status: event.status),
      );
      
      // 刷新数据
      add(const TasksLoadRequested());
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  /// 检查状态流转是否合法
  bool _isValidStatusTransition(String fromStatus, String toStatus) {
    // 状态顺序: planning -> pending -> in_progress -> completed
    final statusOrder = ['planning', 'pending', 'in_progress', 'completed'];
    final fromIndex = statusOrder.indexOf(fromStatus);
    final toIndex = statusOrder.indexOf(toStatus);
    
    if (fromIndex == -1 || toIndex == -1) return false;
    
    // 只允许相邻状态流转（向前或向后一步）
    return (toIndex - fromIndex).abs() == 1;
  }

  /// 子任务状态切换（勾选按钮）
  Future<void> _onSubTaskStatusToggled(
    SubTaskStatusToggled event,
    Emitter<TaskState> emit,
  ) async {
    try {
      // 递归查找子任务及其父任务
      Task? subTask;
      Task? parentTask;
      
      void findSubTask(List<Task> tasks, Task? potentialParent) {
        for (final task in tasks) {
          if (task.id == event.subTaskId) {
            subTask = task;
            parentTask = potentialParent;
            return;
          }
          if (task.children.isNotEmpty) {
            findSubTask(task.children, task);
            if (subTask != null) return;
          }
        }
      }
      
      findSubTask(state.tasks, null);

      if (subTask == null) {
        emit(state.copyWith(errorMessage: '找不到子任务'));
        return;
      }

      // 子任务状态循环: planning -> pending -> in_progress -> completed -> planning
      String newStatus;
      switch (subTask!.status) {
        case 'planning':
          newStatus = 'pending';
          break;
        case 'pending':
          newStatus = 'in_progress';
          break;
        case 'in_progress':
          newStatus = 'completed';
          break;
        case 'completed':
          newStatus = 'planning';
          break;
        default:
          newStatus = 'planning';
      }

      // 更新子任务状态
      await _taskRepository.updateTask(
        event.subTaskId,
        UpdateTaskRequest(status: newStatus),
      );

      // 检查是否需要更新父任务状态
      if (parentTask != null) {
        await _updateParentTaskIfNeeded(parentTask!);
      }

      // 刷新数据
      add(const TasksLoadRequested());
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  /// 检查并更新父任务状态
  Future<void> _updateParentTaskIfNeeded(Task parentTask) async {
    // 重新获取父任务的最新子任务状态
    final freshParent = await _taskRepository.getTaskDetail(parentTask.id);
    
    if (freshParent.children.isEmpty) return;

    // 检查所有子任务是否都已完成
    final allCompleted = freshParent.children.every((child) => 
      child.status == 'completed'
    );

    // 检查是否有进行中的子任务
    final hasInProgress = freshParent.children.any((child) => 
      child.status == 'in_progress'
    );

    String? newStatus;
    if (allCompleted) {
      newStatus = 'completed';
    } else if (hasInProgress) {
      newStatus = 'in_progress';
    }

    if (newStatus != null && newStatus != freshParent.status) {
      await _taskRepository.updateTask(
        parentTask.id,
        UpdateTaskRequest(status: newStatus),
      );
    }
  }

  /// 日期范围变更（甘特图）
  void _onDateRangeChanged(
    TaskDateRangeChanged event,
    Emitter<TaskState> emit,
  ) {
    emit(state.copyWith(
      ganttDateRange: DateTimeRange(
        start: event.startDate,
        end: event.endDate,
      ),
    ));
    add(const TasksLoadRequested());
  }

  /// 创建任务
  Future<void> _onTaskCreated(
    TaskCreated event,
    Emitter<TaskState> emit,
  ) async {
    try {
      await _taskRepository.createTask(
        event.projectId,
        event.request,
      );
      add(const TasksLoadRequested());
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  /// 创建子任务
  Future<void> _onSubTaskCreated(
    SubTaskCreated event,
    Emitter<TaskState> emit,
  ) async {
    try {
      await _taskRepository.createSubTask(
        event.parentTaskId,
        event.request,
      );
      add(const TasksLoadRequested());
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  /// 更新任务
  Future<void> _onTaskUpdated(
    TaskUpdated event,
    Emitter<TaskState> emit,
  ) async {
    try {
      await _taskRepository.updateTask(
        event.taskId,
        event.request,
      );
      add(const TasksLoadRequested());
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  /// 删除任务
  Future<void> _onTaskDeleted(
    TaskDeleted event,
    Emitter<TaskState> emit,
  ) async {
    try {
      await _taskRepository.deleteTask(event.taskId);
      add(const TasksLoadRequested());
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  /// 主任务展开/收起
  void _onTaskExpandToggled(
    TaskExpandToggled event,
    Emitter<TaskState> emit,
  ) {
    final expandedIds = Set<int>.from(state.expandedTaskIds);
    if (expandedIds.contains(event.taskId)) {
      expandedIds.remove(event.taskId);
    } else {
      expandedIds.add(event.taskId);
    }
    emit(state.copyWith(expandedTaskIds: expandedIds));
  }


  List<KanbanColumn> _buildKanbanColumns(List<Task> tasks) {
    final columns = [
      KanbanColumn(id: 'planning', title: '规划中', color: 0xFF94A3B8),
      KanbanColumn(id: 'pending', title: '待处理', color: 0xFFF59E0B),
      KanbanColumn(id: 'in_progress', title: '进行中', color: 0xFF0D9488),
      KanbanColumn(id: 'completed', title: '已完成', color: 0xFF10B981),
    ];

    for (final column in columns) {
      column.tasks.clear();
      column.tasks.addAll(
        tasks.where((t) => t.status == column.id).toList(),
      );
    }

    return columns;
  }

  DateTimeRange _calculateDateRange(List<Task> tasks) {
    if (tasks.isEmpty) {
      final now = DateTime.now();
      return DateTimeRange(
        start: now.subtract(const Duration(days: 7)),
        end: now.add(const Duration(days: 21)),
      );
    }

    DateTime? earliest;
    DateTime? latest;

    for (final task in tasks) {
      if (task.startDate != null) {
        earliest = earliest == null || task.startDate!.isBefore(earliest)
            ? task.startDate
            : earliest;
      }
      if (task.endDate != null) {
        latest = latest == null || task.endDate!.isAfter(latest)
            ? task.endDate
            : latest;
      }
    }

    return DateTimeRange(
      start: earliest ?? DateTime.now(),
      end: latest ?? DateTime.now().add(const Duration(days: 7)),
    );
  }

  Map<DateTime, List<Task>> _buildCalendarTasks(List<Task> tasks) {
    final Map<DateTime, List<Task>> result = {};
    
    for (final task in tasks) {
      if (task.endDate != null) {
        final date = DateTime(
          task.endDate!.year,
          task.endDate!.month,
          task.endDate!.day,
        );
        result.putIfAbsent(date, () => []).add(task);
      }
    }
    
    return result;
  }
}

/// 看板列数据
class KanbanColumn {
  final String id;
  final String title;
  final int color;
  final List<Task> tasks;

  KanbanColumn({
    required this.id,
    required this.title,
    required this.color,
    List<Task>? tasks,
  }) : tasks = tasks ?? [];
}

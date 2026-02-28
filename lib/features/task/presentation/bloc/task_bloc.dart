import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/permissions/permission_service.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import 'task_event.dart';
import 'task_state.dart';

/// 任务管理 BLoC
class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final TaskRepository _taskRepository;
  int? _currentUserId;

  TaskBloc({
    required TaskRepository taskRepository,
    required PermissionService permissionService,
  })  : _taskRepository = taskRepository,
        super(const TaskState()) {
    on<TaskViewModeChanged>(_onViewModeChanged);
    on<TasksLoadRequested>(_onTasksLoadRequested);
    on<TaskFilterChanged>(_onFilterChanged);
    on<TaskProjectFilterChanged>(_onProjectFilterChanged);
    on<TaskAssigneeFilterChanged>(_onAssigneeFilterChanged);
    on<TaskStatusChanged>(_onTaskStatusChanged);
    on<TaskDateRangeChanged>(_onDateRangeChanged);
    on<TaskCreated>(_onTaskCreated);
    on<TaskUpdated>(_onTaskUpdated);
    on<TaskDeleted>(_onTaskDeleted);
    on<TaskExpandToggled>(_onTaskExpandToggled);
    on<SubTaskStatusToggled>(_onSubTaskStatusToggled);
    on<SubTaskCreated>(_onSubTaskCreated);
    // 看板新功能事件
    on<UnassignedTaskCreated>(_onUnassignedTaskCreated);
    on<TaskClaimed>(_onTaskClaimed);
    
    // 加载当前用户ID
    _loadCurrentUserId();
  }
  
  /// 加载当前用户ID
  Future<void> _loadCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userIdStr = prefs.getString('user_id');
    if (userIdStr != null) {
      _currentUserId = int.tryParse(userIdStr);
    }
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
    // 确保当前用户ID已加载
    if (_currentUserId == null) {
      await _loadCurrentUserId();
    }
    
    final kanbanData = await _taskRepository.getGlobalKanbanTasks(
      filter: state.filter,
      currentUserId: _currentUserId,
    );
    
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

  /// 人员筛选变更
  void _onAssigneeFilterChanged(
    TaskAssigneeFilterChanged event,
    Emitter<TaskState> emit,
  ) {
    // 根据筛选条件设置 assignee
    String? assignee;
    if (event.assigneeFilter == 'me') {
      assignee = 'me';
    } else if (event.assigneeFilter == 'others') {
      assignee = 'others';
    } else {
      assignee = null; // 'all' 或 null
    }

    final currentFilter = state.filter;
    final newFilter = TaskFilter(
      status: currentFilter?.status,
      assignee: assignee,
      search: currentFilter?.search,
      projectId: currentFilter?.projectId,
    );
    emit(state.copyWith(
      selectedAssigneeFilter: event.assigneeFilter,
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

  bool _isValidStatusTransition(String fromStatus, String toStatus) => true;

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
  /// 注意：后端 /tasks/list/?view=tree 已返回完整树形结构，无需额外加载
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

  // ==================== 看板新功能事件处理 ====================

  /// 创建无负责人任务（看板中快速创建）
  Future<void> _onUnassignedTaskCreated(
    UnassignedTaskCreated event,
    Emitter<TaskState> emit,
  ) async {
    try {
      emit(state.copyWith(status: TaskStatus.loading));
      
      await _taskRepository.createUnassignedTask(
        projectId: event.projectId,
        title: event.title,
        description: event.description,
        priority: event.priority,
      );
      
      // 刷新数据
      add(const TasksLoadRequested());
    } catch (e) {
      emit(state.copyWith(
        status: TaskStatus.failure,
        errorMessage: '创建任务失败: $e',
      ));
    }
  }

  /// 领取任务（从planning拖出时调用）
  Future<void> _onTaskClaimed(
    TaskClaimed event,
    Emitter<TaskState> emit,
  ) async {
    try {
      emit(state.copyWith(status: TaskStatus.loading));
      
      await _taskRepository.claimTask(
        taskId: event.taskId,
        status: event.status,
        endDate: event.endDate,
      );
      
      // 刷新数据
      add(const TasksLoadRequested());
    } catch (e) {
      emit(state.copyWith(
        status: TaskStatus.failure,
        errorMessage: '领取任务失败: $e',
      ));
    }
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

import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../models/task_model.dart';

/// 任务管理 Mock 数据仓库
class MockTaskRepository implements TaskRepository {
  // Mock 数据存储
  final List<Map<String, dynamic>> _tasks = [];
  int _nextId = 1;

  MockTaskRepository() {
    _initMockData();
  }

  void _initMockData() {
    // 主任务 1 - API接口开发模块
    _tasks.add({
      'id': _nextId++,
      'project_id': 1,
      'title': 'API接口开发模块',
      'description': '完成用户管理模块的API接口开发，包括登录、注册、个人信息接口',
      'assignee_id': 2,
      'assignee_name': 'zhangsan',
      'assignee_avatar': null,
      'status': 'in_progress',
      'priority': 'high',
      'level': 1,
      'parent_id': null,
      'path': '',
      'start_date': '2026-02-10',
      'end_date': '2026-02-20',
      'created_at': '2026-02-10T08:00:00Z',
      'updated_at': '2026-02-10T08:00:00Z',
      'children': [
        {
          'id': _nextId++,
          'project_id': 1,
          'title': '设计API接口文档',
          'description': '使用Swagger设计RESTful API接口文档',
          'assignee_id': 2,
          'assignee_name': 'zhangsan',
          'assignee_avatar': null,
          'status': 'completed',
          'priority': 'high',
          'level': 2,
          'parent_id': 1,
          'path': '/1',
          'start_date': '2026-02-10',
          'end_date': '2026-02-12',
          'created_at': '2026-02-10T09:00:00Z',
          'updated_at': '2026-02-12T10:00:00Z',
          'children': [],
          'subtask_count': 0,
          'completed_subtask_count': 0,
        },
        {
          'id': _nextId++,
          'project_id': 1,
          'title': '编写用户登录接口',
          'description': '实现JWT登录认证接口',
          'assignee_id': 2,
          'assignee_name': 'zhangsan',
          'assignee_avatar': null,
          'status': 'in_progress',
          'priority': 'high',
          'level': 2,
          'parent_id': 1,
          'path': '/1',
          'start_date': '2026-02-13',
          'end_date': '2026-02-15',
          'created_at': '2026-02-13T08:00:00Z',
          'updated_at': '2026-02-13T08:00:00Z',
          'children': [],
          'subtask_count': 0,
          'completed_subtask_count': 0,
        },
        {
          'id': _nextId++,
          'project_id': 1,
          'title': '编写用户注册接口',
          'description': '实现用户注册接口，包括参数校验',
          'assignee_id': 2,
          'assignee_name': 'zhangsan',
          'assignee_avatar': null,
          'status': 'planning',
          'priority': 'medium',
          'level': 2,
          'parent_id': 1,
          'path': '/1',
          'start_date': '2026-02-16',
          'end_date': '2026-02-18',
          'created_at': '2026-02-13T09:00:00Z',
          'updated_at': '2026-02-13T09:00:00Z',
          'children': [],
          'subtask_count': 0,
          'completed_subtask_count': 0,
        },
      ],
      'subtask_count': 3,
      'completed_subtask_count': 1,
    });

    // 主任务 2 - UI设计评审
    _tasks.add({
      'id': _nextId++,
      'project_id': 1,
      'title': 'UI设计评审',
      'description': '参与用户中心系统的UI设计评审会议，提出修改建议',
      'assignee_id': 3,
      'assignee_name': 'lisi',
      'assignee_avatar': null,
      'status': 'pending',
      'priority': 'medium',
      'level': 1,
      'parent_id': null,
      'path': '',
      'start_date': '2026-02-11',
      'end_date': '2026-02-14',
      'created_at': '2026-02-11T08:00:00Z',
      'updated_at': '2026-02-11T08:00:00Z',
      'children': [
        {
          'id': _nextId++,
          'project_id': 1,
          'title': '准备设计稿',
          'description': '整理UI设计稿，准备评审材料',
          'assignee_id': 3,
          'assignee_name': 'lisi',
          'assignee_avatar': null,
          'status': 'completed',
          'priority': 'high',
          'level': 2,
          'parent_id': 2,
          'path': '/2',
          'start_date': '2026-02-11',
          'end_date': '2026-02-12',
          'created_at': '2026-02-11T09:00:00Z',
          'updated_at': '2026-02-12T10:00:00Z',
          'children': [],
          'subtask_count': 0,
          'completed_subtask_count': 0,
        },
        {
          'id': _nextId++,
          'project_id': 1,
          'title': '评审会议',
          'description': '参加UI设计评审会议',
          'assignee_id': 3,
          'assignee_name': 'lisi',
          'assignee_avatar': null,
          'status': 'pending',
          'priority': 'medium',
          'level': 2,
          'parent_id': 2,
          'path': '/2',
          'start_date': '2026-02-13',
          'end_date': '2026-02-13',
          'created_at': '2026-02-11T10:00:00Z',
          'updated_at': '2026-02-11T10:00:00Z',
          'children': [],
          'subtask_count': 0,
          'completed_subtask_count': 0,
        },
      ],
      'subtask_count': 2,
      'completed_subtask_count': 1,
    });

    // 主任务 3 - 数据库设计
    _tasks.add({
      'id': _nextId++,
      'project_id': 1,
      'title': '数据库设计',
      'description': '设计系统数据库结构，包括用户表、项目表、任务表等',
      'assignee_id': 4,
      'assignee_name': 'wangwu',
      'assignee_avatar': null,
      'status': 'planning',
      'priority': 'high',
      'level': 1,
      'parent_id': null,
      'path': '',
      'start_date': '2026-02-15',
      'end_date': '2026-02-25',
      'created_at': '2026-02-10T10:00:00Z',
      'updated_at': '2026-02-10T10:00:00Z',
      'children': [
        {
          'id': _nextId++,
          'project_id': 1,
          'title': '设计用户表',
          'description': '设计用户表结构',
          'assignee_id': 4,
          'assignee_name': 'wangwu',
          'assignee_avatar': null,
          'status': 'in_progress',
          'priority': 'high',
          'level': 2,
          'parent_id': 3,
          'path': '/3',
          'start_date': '2026-02-15',
          'end_date': '2026-02-17',
          'created_at': '2026-02-10T11:00:00Z',
          'updated_at': '2026-02-15T08:00:00Z',
          'children': [],
          'subtask_count': 0,
          'completed_subtask_count': 0,
        },
      ],
      'subtask_count': 1,
      'completed_subtask_count': 0,
    });
  }

  // 模拟网络延迟
  Future<T> _simulateDelay<T>(T data) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return data;
  }

  @override
  Future<List<Task>> getProjectTasks(
    int projectId, {
    String view = 'tree',
    TaskFilter? filter,
  }) async {
    await _simulateDelay(null);

    var tasks = _tasks
        .where((t) => t['project_id'] == projectId && t['level'] == 1)
        .map((json) => TaskModel.fromJson(json))
        .toList();

    // 应用状态过滤
    if (filter?.status != null && filter!.status!.isNotEmpty) {
      tasks = tasks.where((t) => t.status == filter.status).toList();
    }

    // 应用搜索过滤
    if (filter?.search != null && filter!.search!.isNotEmpty) {
      final searchLower = filter.search!.toLowerCase();
      tasks = tasks.where((t) {
        return t.title.toLowerCase().contains(searchLower) ||
            (t.description?.toLowerCase().contains(searchLower) ?? false);
      }).toList();
    }

    return tasks;
  }

  @override
  Future<Task> getTaskDetail(int taskId) async {
    await _simulateDelay(null);

    final task = _tasks.firstWhere(
      (t) => t['id'] == taskId,
      orElse: () => throw Exception('任务不存在'),
    );

    return TaskModel.fromJson(task);
  }

  @override
  Future<Task> createTask(int projectId, CreateTaskRequest request) async {
    await _simulateDelay(null);

    final newTask = {
      'id': _nextId++,
      'project_id': projectId,
      'title': request.title,
      'description': request.description,
      'assignee_id': request.assigneeId,
      'assignee_name': 'User${request.assigneeId}',
      'assignee_avatar': null,
      'status': request.status ?? 'planning',
      'priority': request.priority ?? 'medium',
      'level': 1,
      'parent_id': null,
      'path': '',
      'start_date': request.startDate?.toIso8601String(),
      'end_date': request.endDate?.toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'children': [],
      'subtask_count': 0,
      'completed_subtask_count': 0,
    };

    _tasks.add(newTask);

    return TaskModel.fromJson(newTask);
  }

  @override
  Future<Task> createSubTask(
    int parentTaskId,
    CreateSubTaskRequest request,
  ) async {
    await _simulateDelay(null);

    final parentIndex = _tasks.indexWhere((t) => t['id'] == parentTaskId);
    if (parentIndex == -1) {
      throw Exception('父任务不存在');
    }

    final parent = _tasks[parentIndex];
    
    // 检查层级限制
    if ((parent['level'] as int) >= 3) {
      throw Exception('已达到最大层级深度（3层）');
    }

    final newTask = {
      'id': _nextId++,
      'project_id': parent['project_id'],
      'title': request.title,
      'description': request.description,
      'assignee_id': parent['assignee_id'], // 子任务继承父任务负责人
      'assignee_name': parent['assignee_name'],
      'assignee_avatar': parent['assignee_avatar'],
      'status': request.status ?? 'planning',
      'priority': request.priority ?? 'medium',
      'level': (parent['level'] as int) + 1,
      'parent_id': parentTaskId,
      'path': '${parent['path']}/${parent['id']}',
      'start_date': request.startDate?.toIso8601String(),
      'end_date': request.endDate?.toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'children': [],
      'subtask_count': 0,
      'completed_subtask_count': 0,
    };

    _tasks.add(newTask);

    // 更新父任务的子任务数量
    final children = (parent['children'] as List<dynamic>?) ?? [];
    children.add(newTask);
    _tasks[parentIndex] = {
      ...parent,
      'children': children,
      'subtask_count': (parent['subtask_count'] as int? ?? 0) + 1,
    };

    return TaskModel.fromJson(newTask);
  }

  @override
  Future<Task> updateTask(int taskId, UpdateTaskRequest request) async {
    await _simulateDelay(null);

    final index = _tasks.indexWhere((t) => t['id'] == taskId);
    if (index == -1) {
      throw Exception('任务不存在');
    }

    final task = _tasks[index];
    
    _tasks[index] = {
      ...task,
      if (request.title != null) 'title': request.title,
      if (request.description != null) 'description': request.description,
      if (request.status != null) 'status': request.status,
      if (request.priority != null) 'priority': request.priority,
      if (request.assigneeId != null) 'assignee_id': request.assigneeId,
      if (request.startDate != null)
        'start_date': request.startDate!.toIso8601String(),
      if (request.endDate != null)
        'end_date': request.endDate!.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    return TaskModel.fromJson(_tasks[index]);
  }

  @override
  Future<void> deleteTask(int taskId) async {
    await _simulateDelay(null);

    final index = _tasks.indexWhere((t) => t['id'] == taskId);
    if (index == -1) {
      throw Exception('任务不存在');
    }

    // 递归删除子任务
    _deleteTaskWithChildren(taskId);
  }

  void _deleteTaskWithChildren(int taskId) {
    // 先删除子任务
    final children = _tasks.where((t) => t['parent_id'] == taskId).toList();
    for (final child in children) {
      _deleteTaskWithChildren(child['id'] as int);
    }
    
    // 删除当前任务
    _tasks.removeWhere((t) => t['id'] == taskId);
  }

  @override
  Future<List<TaskHistory>> getTaskHistory(int taskId) async {
    await _simulateDelay(null);

    // Mock 历史数据
    return [
      TaskHistory(
        id: 1,
        taskId: taskId,
        changedBy: 2,
        changedByName: 'zhangsan',
        fieldName: 'status',
        oldValue: 'planning',
        newValue: 'in_progress',
        changedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }
}

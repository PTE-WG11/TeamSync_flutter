import '../entities/task.dart';

/// 任务管理仓库接口
abstract class TaskRepository {
  /// 获取项目任务列表
  /// 
  /// [projectId] - 项目ID
  /// [view] - 视图类型: 'tree'(树形), 'flat'(扁平)
  /// [filter] - 筛选条件
  Future<List<Task>> getProjectTasks(
    int projectId, {
    String view = 'tree',
    TaskFilter? filter,
  });

  /// 获取任务详情
  /// 
  /// [taskId] - 任务ID
  Future<Task> getTaskDetail(int taskId);

  /// 获取子任务列表
  /// 
  /// [parentTaskId] - 父任务ID
  Future<List<Task>> getSubTasks(int parentTaskId);

  /// 创建任务（主任务）
  /// 
  /// [projectId] - 项目ID
  /// [request] - 创建请求
  Future<Task> createTask(int projectId, CreateTaskRequest request);

  /// 创建子任务
  /// 
  /// [parentTaskId] - 父任务ID
  /// [request] - 创建请求
  Future<Task> createSubTask(int parentTaskId, CreateSubTaskRequest request);

  /// 更新任务
  /// 
  /// [taskId] - 任务ID
  /// [request] - 更新请求
  Future<Task> updateTask(int taskId, UpdateTaskRequest request);

  /// 删除任务
  /// 
  /// [taskId] - 任务ID
  Future<void> deleteTask(int taskId);

  /// 获取任务变更历史
  /// 
  /// [taskId] - 任务ID
  Future<List<TaskHistory>> getTaskHistory(int taskId);

  /// 更新任务状态
  /// 
  /// [taskId] - 任务ID
  /// [request] - 状态更新请求
  Future<Task> updateTaskStatus(int taskId, UpdateTaskStatusRequest request);

  /// 获取项目任务进度统计
  /// 
  /// [projectId] - 项目ID
  Future<TaskProgressStats> getTaskProgress(int projectId);

  // ==================== 全局任务查询（跨项目）====================

  /// 获取全局列表视图数据
  /// 
  /// 数据范围：管理员返回所有任务，成员返回自己的任务
  /// [filter] - 筛选条件
  Future<List<Task>> getGlobalListTasks({TaskFilter? filter});

  /// 获取全局看板数据
  /// 
  /// 数据范围：管理员返回所有任务，成员返回自己的任务
  /// [filter] - 筛选条件
  /// 返回看板列数据（包含任务列表）
  Future<List<KanbanColumnData>> getGlobalKanbanTasks({TaskFilter? filter});

  /// 获取全局甘特图数据
  /// 
  /// 数据范围：管理员返回所有主任务，成员返回自己的主任务+子任务树
  /// [filter] - 筛选条件
  Future<List<Task>> getGlobalGanttTasks({TaskFilter? filter});

  /// 获取全局日历数据
  /// 
  /// 数据范围：管理员返回所有任务，成员返回自己的任务
  /// [filter] - 筛选条件
  Future<List<Task>> getGlobalCalendarTasks({TaskFilter? filter});
}

/// 看板列数据（后端直接返回）
class KanbanColumnData {
  final String id;
  final String title;
  final String color;
  final List<Task> tasks;

  KanbanColumnData({
    required this.id,
    required this.title,
    required this.color,
    required this.tasks,
  });
}

/// 任务变更历史
class TaskHistory {
  final int id;
  final int taskId;
  final int changedBy;
  final String changedByName;
  final String fieldName;
  final String? oldValue;
  final String? newValue;
  final DateTime changedAt;

  TaskHistory({
    required this.id,
    required this.taskId,
    required this.changedBy,
    required this.changedByName,
    required this.fieldName,
    this.oldValue,
    this.newValue,
    required this.changedAt,
  });

  /// 字段名称显示
  String get fieldNameDisplay {
    switch (fieldName) {
      case 'status':
        return '状态';
      case 'assignee':
        return '负责人';
      case 'title':
        return '标题';
      case 'description':
        return '描述';
      case 'priority':
        return '优先级';
      case 'start_date':
        return '开始日期';
      case 'end_date':
        return '截止日期';
      default:
        return fieldName;
    }
  }
}

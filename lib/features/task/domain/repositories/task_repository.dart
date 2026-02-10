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

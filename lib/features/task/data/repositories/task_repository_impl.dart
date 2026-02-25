import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../models/task_model.dart';

/// 任务管理数据仓库实现
/// 对接真实后端 API (localhost:8801/api)
class TaskRepositoryImpl implements TaskRepository {
  final ApiClient _apiClient;
  
  TaskRepositoryImpl({ApiClient? apiClient}) 
      : _apiClient = apiClient ?? ApiClient();

  @override
  Future<List<Task>> getProjectTasks(
    int projectId, {
    String view = 'tree',
    TaskFilter? filter,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'view': view,
      };
      
      if (filter?.status != null && filter!.status!.isNotEmpty) {
        queryParams['status'] = filter.status;
      }
      
      if (filter?.search != null && filter!.search!.isNotEmpty) {
        queryParams['search'] = filter.search;
      }
      
      // 使用 /api/tasks/project/{project_id}/ 端点
      final response = await _apiClient.get(
        '/tasks/project/$projectId/',
        queryParameters: queryParams,
      );
      
      // 处理不同的响应格式
      List<dynamic>? items;
      
      if (response.data is Map<String, dynamic>) {
        final responseData = response.data as Map<String, dynamic>;
        
        // 格式1: {code, message, data: {items}}
        if (responseData.containsKey('data')) {
          final data = responseData['data'];
          if (data is Map<String, dynamic>) {
            items = data['items'] as List<dynamic>?;
          } else if (data is List) {
            items = data;
          }
        } 
        // 格式2: DRF 分页格式 {count, next, previous, results}
        else if (responseData.containsKey('results')) {
          items = responseData['results'] as List<dynamic>?;
        }
      } else if (response.data is List) {
        items = response.data as List;
      }
      
      if (items == null) {
        return [];
      }
      
      // 过滤掉 null 元素并解析
      final result = <Task>[];
      for (var i = 0; i < items.length; i++) {
        final item = items[i];
        if (item == null || item is! Map<String, dynamic>) {
          continue;
        }
        try {
          result.add(TaskModel.fromJson(item));
        } catch (e) {
          // 记录解析失败的项，但继续处理其他项
          debugPrint('Task parse error at index $i: $e, data: $item');
        }
      }
      return result;
    } catch (e) {
      throw Exception('获取项目任务列表失败: $e');
    }
  }

  @override
  Future<Task> getTaskDetail(int taskId) async {
    try {
      final response = await _apiClient.get('/tasks/$taskId/');
      
      final responseData = response.data as Map<String, dynamic>?;
      if (responseData == null) {
        throw Exception('任务不存在');
      }

      // 后端返回格式: {code, message, data}
      final data = responseData['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('任务不存在');
      }

      return TaskModel.fromJson(data);
    } catch (e) {
      throw Exception('获取任务详情失败: $e');
    }
  }

  @override
  Future<List<Task>> getSubTasks(int parentTaskId) async {
    try {
      // 尝试从详情接口获取子任务
      final response = await _apiClient.get('/tasks/$parentTaskId/');
      
      final responseData = response.data as Map<String, dynamic>?;
      if (responseData == null) {
        return [];
      }

      // 后端返回格式: {code, message, data}
      final data = responseData['data'] as Map<String, dynamic>?;
      if (data == null) {
        return [];
      }

      // 尝试解析子任务列表
      final dynamic childrenRaw = data['children'] ?? data['subtasks'];
      if (childrenRaw is List) {
        return childrenRaw
            .whereType<Map<String, dynamic>>()
            .map((e) => TaskModel.fromJson(e))
            .toList();
      }
      
      return [];
    } catch (e) {
      // 获取子任务失败，返回空列表
      return [];
    }
  }

  @override
  Future<Task> createTask(int projectId, CreateTaskRequest request) async {
    try {
      final requestData = {
        'title': request.title,
        'description': request.description,
        'assignee_id': request.assigneeId,
        'status': request.status ?? 'planning',
        'priority': request.priority ?? 'medium',
        'start_date': request.startDate != null ? _formatDate(request.startDate!) : null,
        'end_date': request.endDate != null ? _formatDate(request.endDate!) : null,
      };
      
      // 使用 /api/tasks/project/{project_id}/create/ 端点
      final response = await _apiClient.post(
        '/tasks/project/$projectId/create/',
        data: requestData,
      );
      
      final responseData = response.data as Map<String, dynamic>?;
      if (responseData == null) {
        throw Exception('创建任务失败：服务器返回空数据');
      }

      // 后端返回格式: {code, message, data}
      final data = responseData['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('创建任务失败：响应数据为空');
      }

      return TaskModel.fromJson(data);
    } catch (e) {
      throw Exception('创建任务失败: $e');
    }
  }

  @override
  Future<Task> createSubTask(int parentTaskId, CreateSubTaskRequest request) async {
    try {
      final requestData = {
        'title': request.title,
        'description': request.description,
        'status': request.status ?? 'planning',
        'priority': request.priority ?? 'medium',
        'start_date': request.startDate != null ? _formatDate(request.startDate!) : null,
        'end_date': request.endDate != null ? _formatDate(request.endDate!) : null,
      };
      
      // 使用 /api/tasks/{id}/subtasks/ 端点
      final response = await _apiClient.post(
        '/tasks/$parentTaskId/subtasks/',
        data: requestData,
      );
      
      final responseData = response.data as Map<String, dynamic>?;
      if (responseData == null) {
        throw Exception('创建子任务失败：服务器返回空数据');
      }

      // 后端返回格式: {code, message, data}
      final data = responseData['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('创建子任务失败：响应数据为空');
      }

      return TaskModel.fromJson(data);
    } catch (e) {
      throw Exception('创建子任务失败: $e');
    }
  }

  @override
  Future<Task> updateTask(int taskId, UpdateTaskRequest request) async {
    try {
      final requestData = <String, dynamic>{};
      
      if (request.title != null) requestData['title'] = request.title;
      if (request.description != null) requestData['description'] = request.description;
      if (request.status != null) requestData['status'] = request.status;
      if (request.priority != null) requestData['priority'] = request.priority;
      if (request.assigneeId != null) requestData['assignee_id'] = request.assigneeId;
      if (request.startDate != null) {
        requestData['start_date'] = _formatDate(request.startDate!);
      }
      if (request.endDate != null) {
        requestData['end_date'] = _formatDate(request.endDate!);
      }
      
      // 使用 /api/tasks/{id}/update/ 端点
      final response = await _apiClient.patch(
        '/tasks/$taskId/update/',
        data: requestData,
      );
      
      final responseData = response.data as Map<String, dynamic>?;
      if (responseData == null) {
        throw Exception('更新任务失败：服务器返回空数据');
      }

      // 后端返回格式: {code, message, data}
      final data = responseData['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('更新任务失败：响应数据为空');
      }

      return TaskModel.fromJson(data);
    } catch (e) {
      throw Exception('更新任务失败: $e');
    }
  }

  @override
  Future<void> deleteTask(int taskId) async {
    try {
      // 使用 /api/tasks/{id}/delete/ 端点
      await _apiClient.delete('/tasks/$taskId/delete/');
    } catch (e) {
      throw Exception('删除任务失败: $e');
    }
  }

  @override
  Future<List<TaskHistory>> getTaskHistory(int taskId) async {
    try {
      final response = await _apiClient.get('/tasks/$taskId/history/');
      
      final responseData = response.data as Map<String, dynamic>?;
      if (responseData == null) {
        return [];
      }

      // 后端返回格式: {code, message, data: {histories}}
      final data = responseData['data'] as Map<String, dynamic>?;
      if (data == null) {
        return [];
      }
      
      final histories = data['histories'] as List<dynamic>?;
      if (histories == null) {
        return [];
      }
      
      return histories.map((json) => _parseTaskHistory(json)).toList();
    } catch (e) {
      throw Exception('获取任务历史记录失败: $e');
    }
  }
  
  @override
  Future<Task> updateTaskStatus(int taskId, UpdateTaskStatusRequest request) async {
    try {
      final requestData = {
        'status': request.status,
      };
      
      // 使用 /api/tasks/{id}/status/ 端点
      final response = await _apiClient.patch(
        '/tasks/$taskId/status/',
        data: requestData,
      );
      
      final responseData = response.data as Map<String, dynamic>?;
      if (responseData == null) {
        throw Exception('更新任务状态失败：服务器返回空数据');
      }

      // 后端返回格式: {code, message, data}
      final data = responseData['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('更新任务状态失败：响应数据为空');
      }

      return TaskModel.fromJson(data);
    } catch (e) {
      throw Exception('更新任务状态失败: $e');
    }
  }

  @override
  Future<TaskProgressStats> getTaskProgress(int projectId) async {
    try {
      // 使用 /api/tasks/project/{project_id}/progress/ 端点
      final response = await _apiClient.get('/tasks/project/$projectId/progress/');
      
      final responseData = response.data as Map<String, dynamic>?;
      if (responseData == null) {
        throw Exception('获取任务进度统计失败：服务器返回空数据');
      }

      // 后端返回格式: {code, message, data}
      final data = responseData['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('获取任务进度统计失败：响应数据为空');
      }

      return TaskProgressStats.fromJson(data);
    } catch (e) {
      throw Exception('获取任务进度统计失败: $e');
    }
  }

  // ==================== 全局任务查询（跨项目）====================

  @override
  Future<List<Task>> getGlobalListTasks({TaskFilter? filter}) async {
    // 使用 tree 视图获取嵌套的树形结构
    return _fetchGlobalTasks('/tasks/list/', filter, defaultView: 'tree');
  }

  @override
  Future<List<KanbanColumnData>> getGlobalKanbanTasks({TaskFilter? filter}) async {
    try {
      final queryParams = <String, dynamic>{};
      
      if (filter?.status != null && filter!.status!.isNotEmpty) {
        queryParams['status'] = filter.status;
      }
      
      if (filter?.search != null && filter!.search!.isNotEmpty) {
        queryParams['search'] = filter.search;
      }

      final response = await _apiClient.get(
        '/tasks/kanban/',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      
      // 看板返回格式: {code, message, data: {columns: [...]}}
      if (response.data is Map<String, dynamic>) {
        final responseData = response.data as Map<String, dynamic>;
        final data = responseData['data'] as Map<String, dynamic>?;
        final columns = data?['columns'] as List<dynamic>?;
        
        if (columns != null) {
          return columns.map((col) {
            final colMap = col as Map<String, dynamic>;
            final columnId = (colMap['id'] as String? ?? '').trim();
            final tasks = (colMap['tasks'] as List<dynamic>?)
                    ?.whereType<Map<String, dynamic>>()
                    .map((t) {
                  final status = (t['status'] as String?)?.trim();
                  if (status == null || status.isEmpty) {
                    return TaskModel.fromJson({
                      ...t,
                      'status': columnId,
                    });
                  }
                  return TaskModel.fromJson(t);
                }).toList() ??
                [];

            return KanbanColumnData(
              id: colMap['id'] as String? ?? '',
              title: colMap['title'] as String? ?? '',
              color: colMap['color'] as String? ?? '#94A3B8',
              tasks: tasks,
            );
          }).toList();
        }
      }
      
      return [];
    } catch (e) {
      throw Exception('获取看板数据失败: $e');
    }
  }

  @override
  Future<List<Task>> getGlobalGanttTasks({TaskFilter? filter}) async {
    return _fetchGlobalTasks('/tasks/gantt/', filter);
  }

  @override
  Future<List<Task>> getGlobalCalendarTasks({TaskFilter? filter}) async {
    return _fetchGlobalTasks('/tasks/calendar/', filter);
  }

  /// 通用全局任务查询方法
  Future<List<Task>> _fetchGlobalTasks(
    String endpoint,
    TaskFilter? filter, {
    String? defaultView,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      
      // 添加默认视图参数
      if (defaultView != null) {
        queryParams['view'] = defaultView;
      }
      
      if (filter?.status != null && filter!.status!.isNotEmpty) {
        queryParams['status'] = filter.status;
      }
      
      if (filter?.search != null && filter!.search!.isNotEmpty) {
        queryParams['search'] = filter.search;
      }
      
      if (filter?.projectId != null) {
        queryParams['project_id'] = filter!.projectId;
      }

      final response = await _apiClient.get(
        endpoint,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      
      // 处理不同的响应格式
      List<dynamic>? items;
      
      if (response.data is Map<String, dynamic>) {
        final responseData = response.data as Map<String, dynamic>;
        
        // 格式1: {code, message, data: {items}}
        if (responseData.containsKey('data')) {
          final data = responseData['data'];
          if (data is Map<String, dynamic>) {
            items = data['items'] as List<dynamic>?;
          } else if (data is List) {
            items = data;
          }
        } 
        // 格式2: DRF 分页格式 {count, next, previous, results}
        else if (responseData.containsKey('results')) {
          items = responseData['results'] as List<dynamic>?;
        }
      } else if (response.data is List) {
        items = response.data as List;
      }
      
      if (items == null) {
        return [];
      }
      
      // 过滤掉 null 元素并解析
      final result = <Task>[];
      for (var i = 0; i < items.length; i++) {
        final item = items[i];
        if (item == null || item is! Map<String, dynamic>) {
          continue;
        }
        try {
          result.add(TaskModel.fromJson(item));
        } catch (e) {
          debugPrint('Task parse error at index $i: $e, data: $item');
        }
      }
      return result;
    } catch (e) {
      throw Exception('获取任务列表失败: $e');
    }
  }

  TaskHistory _parseTaskHistory(Map<String, dynamic> json) {
    return TaskHistory(
      id: json['id'] as int? ?? 0,
      taskId: json['task_id'] as int? ?? 0,
      changedBy: json['changed_by'] as int? ?? 0,
      changedByName: json['changed_by_name'] as String? ?? '未知用户',
      fieldName: json['field_name'] as String? ?? '',
      oldValue: json['old_value'] as String?,
      newValue: json['new_value'] as String?,
      changedAt: DateTime.tryParse(json['changed_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

/// 格式化日期为 YYYY-MM-DD 格式
String _formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

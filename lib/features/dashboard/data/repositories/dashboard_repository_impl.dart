import '../../../../core/network/api_client.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../../domain/entities/member_workload.dart';
import '../../domain/entities/project_summary.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../models/dashboard_stats_model.dart';
import '../models/member_workload_model.dart';
import '../models/project_summary_model.dart';
import 'mock_dashboard_repository.dart';

/// 仪表盘数据仓库实现
/// 对接真实后端 API (localhost:8801/api)
class DashboardRepositoryImpl implements DashboardRepository {
  final ApiClient _apiClient;
  
  DashboardRepositoryImpl({ApiClient? apiClient}) 
      : _apiClient = apiClient ?? ApiClient();

  @override
  Future<DashboardStats> getDashboardStats({TimeRange timeRange = TimeRange.week}) async {
    try {
      // 管理员仪表盘数据
      final response = await _apiClient.get('/dashboard/admin/');
      
      // 处理不同的响应格式
      Map<String, dynamic>? data;
      
      if (response.data is Map<String, dynamic>) {
        final responseData = response.data as Map<String, dynamic>;
        
        // 格式1: {code, message, data: {...}}
        if (responseData.containsKey('data')) {
          final d = responseData['data'];
          if (d is Map<String, dynamic>) {
            data = d;
          }
        } 
        // 格式2: 直接是数据对象
        else {
          data = responseData;
        }
      }
      
      if (data == null) {
        throw Exception('获取仪表盘统计数据失败：响应数据为空');
      }

      // 根据 API 文档，返回的数据包含各种统计信息
      return DashboardStatsModel(
        activeProjects: data['active_projects'] ?? 0,
        totalTasks: data['total_tasks'] ?? 0,
        completionRate: (data['completion_rate'] ?? 0.0).toDouble(),
        overdueTasks: data['overdue_tasks'] ?? 0,
        totalProjects: data['total_projects'] ?? 0,
        archivedProjects: data['archived_projects'] ?? 0,
      );
    } catch (e) {
      throw Exception('获取仪表盘统计数据失败: $e');
    }
  }

  @override
  Future<List<ProjectSummary>> getRecentProjects({TimeRange timeRange = TimeRange.week}) async {
    try {
      // 获取项目列表
      final response = await _apiClient.get(
        '/projects/',
        queryParameters: {
          'page_size': 10,
        },
      );
      
      // 处理不同的响应格式
      List<dynamic>? items;
      
      if (response.data is Map<String, dynamic>) {
        final responseData = response.data as Map<String, dynamic>;
        
        // 格式1: {code, message, data: {items, pagination}}
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
      
      return items.map((json) => ProjectSummaryModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('获取最近项目列表失败: $e');
    }
  }

  @override
  Future<List<MemberWorkload>> getMemberWorkloads({TimeRange timeRange = TimeRange.week}) async {
    try {
      final response = await _apiClient.get('/dashboard/admin/');
      
      // 处理不同的响应格式
      Map<String, dynamic>? data;
      
      if (response.data is Map<String, dynamic>) {
        final responseData = response.data as Map<String, dynamic>;
        
        // 格式1: {code, message, data: {...}}
        if (responseData.containsKey('data')) {
          final d = responseData['data'];
          if (d is Map<String, dynamic>) {
            data = d;
          }
        } else {
          data = responseData;
        }
      }
      
      if (data == null) {
        return [];
      }

      // 根据 API 文档，member_workload 可能包含在返回数据中
      final workloads = data['member_workload'] as List<dynamic>?;
      if (workloads == null) {
        return [];
      }
      
      return workloads.map((json) => MemberWorkloadModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('获取成员工作量统计失败: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getOverdueTasks() async {
    try {
      // 从仪表盘数据中获取逾期任务
      final response = await _apiClient.get('/dashboard/admin/');
      
      // 处理不同的响应格式
      Map<String, dynamic>? data;
      
      if (response.data is Map<String, dynamic>) {
        final responseData = response.data as Map<String, dynamic>;
        
        // 格式1: {code, message, data: {...}}
        if (responseData.containsKey('data')) {
          final d = responseData['data'];
          if (d is Map<String, dynamic>) {
            data = d;
          }
        } else {
          data = responseData;
        }
      }
      
      if (data == null) {
        return [];
      }

      final overdueTasks = data['overdue_tasks_detail'] as List<dynamic>?;
      if (overdueTasks == null) {
        return [];
      }
      
      return overdueTasks.map((json) => json as Map<String, dynamic>).toList();
    } catch (e) {
      throw Exception('获取逾期任务列表失败: $e');
    }
  }
}

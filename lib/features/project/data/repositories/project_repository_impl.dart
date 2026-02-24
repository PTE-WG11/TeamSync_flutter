import '../../../../core/network/api_client.dart';
import '../../domain/entities/project.dart';
import '../../domain/repositories/project_repository.dart';
import '../models/project_model.dart';

/// 项目数据仓库实现
/// 对接真实后端 API (localhost:8801/api)
class ProjectRepositoryImpl implements ProjectRepository {
  final ApiClient _apiClient;
  
  ProjectRepositoryImpl({ApiClient? apiClient}) 
      : _apiClient = apiClient ?? ApiClient();

  @override
  Future<List<Project>> getProjects({
    String? status,
    bool includeArchived = false,
    String? search,
    int page = 1,
    int pageSize = 20,
    String? userId,
    bool isAdmin = false,
    bool isVisitor = false,
  }) async {
    // 权限过滤：访客看不到任何项目
    if (isVisitor) {
      return [];
    }
    
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };
      
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      
      final response = await _apiClient.get(
        '/projects/',
        queryParameters: queryParams,
      );
      
      // 调试：打印响应数据类型和内容
      print('[ProjectRepository] Response data type: ${response.data?.runtimeType}');
      print('[ProjectRepository] Response data: ${response.data}');
      
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
            // 格式2: {code, message, data: [...]}
            items = data;
          }
        } 
        // 格式3: DRF 分页格式 {count, next, previous, results}
        else if (responseData.containsKey('results')) {
          items = responseData['results'] as List<dynamic>?;
        }
        // 格式4: 直接是项目列表（不应该发生，但做兼容）
        else if (responseData.containsKey('id')) {
          items = [responseData];
        }
      } else if (response.data is List) {
        // 格式5: 直接返回数组
        items = response.data as List;
      }
      
      if (items == null) {
        print('[ProjectRepository] Could not parse items from response');
        return [];
      }
      
      // 过滤已归档的项目（如果需要）
      var projects = items.map((json) => ProjectModel.fromJson(json)).toList();
      
      if (!includeArchived) {
        projects = projects.where((p) => !p.isArchived).toList();
      }
      
      return projects;
    } catch (e) {
      throw Exception('获取项目列表失败: $e');
    }
  }

  @override
  Future<int> getProjectCount({
    String? status,
    bool includeArchived = false,
    String? search,
    String? userId,
    bool isAdmin = false,
    bool isVisitor = false,
  }) async {
    if (isVisitor) {
      return 0;
    }
    
    try {
      final queryParams = <String, dynamic>{};
      
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      
      final response = await _apiClient.get(
        '/projects/',
        queryParameters: queryParams,
      );
      
      // 处理不同的响应格式
      if (response.data is Map<String, dynamic>) {
        final responseData = response.data as Map<String, dynamic>;
        
        // 格式1: {code, message, data: {items, pagination}}
        if (responseData.containsKey('data')) {
          final data = responseData['data'];
          if (data is Map<String, dynamic>) {
            final pagination = data['pagination'] as Map<String, dynamic>?;
            return pagination?['total'] as int? ?? 0;
          }
        } 
        // 格式2: DRF 分页格式 {count, next, previous, results}
        else if (responseData.containsKey('count')) {
          return responseData['count'] as int? ?? 0;
        }
      }
      
      return 0;
    } catch (e) {
      throw Exception('获取项目数量失败: $e');
    }
  }

  @override
  Future<Project?> getProjectById(int id) async {
    try {
      final response = await _apiClient.get('/projects/$id/');
      
      final responseData = response.data as Map<String, dynamic>?;
      if (responseData == null) {
        return null;
      }

      // 后端返回格式: {code, message, data}
      final data = responseData['data'] as Map<String, dynamic>?;
      if (data == null) {
        return null;
      }

      return ProjectModel.fromJson(data);
    } catch (e) {
      throw Exception('获取项目详情失败: $e');
    }
  }

  @override
  Future<Project> createProject({
    required String title,
    String? description,
    String status = 'planning',
    String? startDate,
    String? endDate,
    required List<int> memberIds,
  }) async {
    try {
      final requestData = {
        'title': title,
        'description': description ?? '',
        'status': status,
        'start_date': startDate,
        'end_date': endDate,
        'member_ids': memberIds,
      };
      
      final response = await _apiClient.post(
        '/projects/',
        data: requestData,
      );
      
      final responseData = response.data as Map<String, dynamic>?;
      if (responseData == null) {
        throw Exception('创建项目失败：服务器返回空数据');
      }

      // 后端返回格式: {code, message, data}
      final data = responseData['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('创建项目失败：响应数据为空');
      }

      return ProjectModel.fromJson(data);
    } catch (e) {
      throw Exception('创建项目失败: $e');
    }
  }

  @override
  Future<Project?> updateProject(
    int id, {
    String? title,
    String? description,
    String? status,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final requestData = <String, dynamic>{};
      if (title != null) requestData['title'] = title;
      if (description != null) requestData['description'] = description;
      if (status != null) requestData['status'] = status;
      if (startDate != null) requestData['start_date'] = startDate;
      if (endDate != null) requestData['end_date'] = endDate;
      
      final response = await _apiClient.patch(
        '/projects/$id/',
        data: requestData,
      );
      
      final responseData = response.data as Map<String, dynamic>?;
      if (responseData == null) {
        return null;
      }

      // 后端返回格式: {code, message, data}
      final data = responseData['data'] as Map<String, dynamic>?;
      if (data == null) {
        return null;
      }

      return ProjectModel.fromJson(data);
    } catch (e) {
      throw Exception('更新项目失败: $e');
    }
  }

  @override
  Future<Project?> archiveProject(int id) async {
    try {
      final response = await _apiClient.patch('/projects/$id/archive/');
      
      final responseData = response.data as Map<String, dynamic>?;
      if (responseData == null) {
        return null;
      }

      // 后端返回格式: {code, message, data}
      final data = responseData['data'] as Map<String, dynamic>?;
      if (data == null) {
        return null;
      }

      return ProjectModel.fromJson(data);
    } catch (e) {
      throw Exception('归档项目失败: $e');
    }
  }

  @override
  Future<bool> deleteProject(int id) async {
    try {
      await _apiClient.delete('/projects/$id/');
      return true;
    } catch (e) {
      throw Exception('删除项目失败: $e');
    }
  }

  @override
  Future<Project?> updateProjectMembers(int id, List<int> memberIds) async {
    try {
      final response = await _apiClient.put(
        '/projects/$id/members/',
        data: {'member_ids': memberIds},
      );
      
      final responseData = response.data as Map<String, dynamic>?;
      if (responseData == null) {
        return null;
      }

      // 后端返回格式: {code, message, data}
      final data = responseData['data'] as Map<String, dynamic>?;
      if (data == null) {
        return null;
      }

      return ProjectModel.fromJson(data);
    } catch (e) {
      throw Exception('更新项目成员失败: $e');
    }
  }

  @override
  Future<bool> isUserMemberOfProject(int projectId, String? userId) async {
    if (userId == null) return false;
    
    try {
      // 获取项目详情检查用户是否是成员
      final project = await getProjectById(projectId);
      if (project == null) return false;
      
      final userIdInt = int.tryParse(userId);
      if (userIdInt == null) return false;
      
      return project.members.any((m) => m.id == userIdInt) || 
             project.createdBy?.id == userIdInt;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<ProjectMember>> getAvailableMembers() async {
    try {
      // 获取团队成员列表作为可用成员
      final response = await _apiClient.get('/team/members/');
      
      final responseData = response.data as Map<String, dynamic>?;
      if (responseData == null) {
        return [];
      }

      // 后端返回格式: {code, message, data: {items, pagination}}
      final data = responseData['data'] as Map<String, dynamic>?;
      if (data == null) {
        return [];
      }
      
      final items = data['items'] as List<dynamic>?;
      if (items == null) {
        return [];
      }
      
      // 将团队成员数据映射为项目成员
      return items.map((json) => ProjectMemberModel(
        id: json['id'] as int? ?? 0,
        username: json['username'] as String? ?? '',
        role: json['role'] as String? ?? 'member',
        avatar: json['avatar'] as String?,
      )).toList();
    } catch (e) {
      throw Exception('获取可用成员列表失败: $e');
    }
  }
}

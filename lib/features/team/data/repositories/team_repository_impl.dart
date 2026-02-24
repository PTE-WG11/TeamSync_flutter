import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/team_member.dart';
import '../../domain/repositories/team_repository.dart';
import '../models/team_member_model.dart';

/// 团队管理数据仓库实现
/// 对接真实后端 API (localhost:8801/api)
class TeamRepositoryImpl implements TeamRepository {
  final ApiClient _apiClient;
  
  TeamRepositoryImpl({ApiClient? apiClient}) 
      : _apiClient = apiClient ?? ApiClient();

  @override
  Future<List<TeamMember>> getTeamMembers({TeamMemberFilter? filter}) async {
    try {
      final queryParams = <String, dynamic>{};
      
      if (filter?.role != null && filter!.role!.isNotEmpty) {
        queryParams['role'] = filter.role;
      }
      
      if (filter?.search != null && filter!.search!.isNotEmpty) {
        queryParams['search'] = filter.search;
      }
      
      // 添加分页和排序参数
      if (filter?.ordering != null && filter!.ordering!.isNotEmpty) {
        queryParams['ordering'] = filter.ordering;
      }
      
      if (filter?.page != null && filter!.page! > 0) {
        queryParams['page'] = filter.page;
      }
      
      if (filter?.pageSize != null && filter!.pageSize! > 0) {
        queryParams['page_size'] = filter.pageSize;
      }
      
      // 使用 /api/team/members/ 端点
      final response = await _apiClient.get(
        '/team/members/',
        queryParameters: queryParams,
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
      
      // 过滤掉 null 元素并解析
      final result = <TeamMember>[];
      for (var i = 0; i < items.length; i++) {
        final item = items[i];
        if (item == null || item is! Map<String, dynamic>) {
          continue;
        }
        try {
          result.add(TeamMemberModel.fromJson(item));
        } catch (e) {
          // 记录解析失败的项，但继续处理其他项
          debugPrint('TeamMember parse error at index $i: $e');
        }
      }
      return result;
    } catch (e) {
      throw Exception('获取团队成员列表失败: $e');
    }
  }

  @override
  Future<TeamMember> inviteMember(InviteMemberRequest request) async {
    try {
      final requestData = {
        'username': request.username,
        'role': request.role,
      };
      
      // 使用 /api/team/invite/ 端点
      final response = await _apiClient.post(
        '/team/invite/',
        data: requestData,
      );
      
      final responseData = response.data as Map<String, dynamic>?;
      if (responseData == null) {
        throw Exception('邀请成员失败：服务器返回空数据');
      }

      // 后端返回格式: {code, message, data}
      final data = responseData['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('邀请成员失败：响应数据为空');
      }

      return TeamMemberModel.fromJson(data);
    } catch (e) {
      throw Exception('邀请成员失败: $e');
    }
  }

  @override
  Future<TeamMember> updateMemberRole(int memberId, UpdateRoleRequest request) async {
    try {
      final requestData = {
        'role': request.role,
      };
      
      // 使用 /api/team/members/{id}/role/ 端点
      final response = await _apiClient.patch(
        '/team/members/$memberId/role/',
        data: requestData,
      );
      
      final responseData = response.data as Map<String, dynamic>?;
      if (responseData == null) {
        throw Exception('更新成员角色失败：服务器返回空数据');
      }

      // 后端返回格式: {code, message, data}
      final data = responseData['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('更新成员角色失败：响应数据为空');
      }

      return TeamMemberModel.fromJson(data);
    } catch (e) {
      throw Exception('更新成员角色失败: $e');
    }
  }

  @override
  Future<void> removeMember(int memberId) async {
    try {
      // 使用 /api/team/members/{id}/ 端点
      await _apiClient.delete('/team/members/$memberId/');
    } catch (e) {
      throw Exception('移除成员失败: $e');
    }
  }

  @override
  Future<bool> checkUsernameExists(String username) async {
    try {
      // 使用专门的检查接口 /api/team/check-user/
      final response = await _apiClient.get(
        '/team/check-user/',
        queryParameters: {'username': username},
      );
      
      final responseData = response.data as Map<String, dynamic>?;
      if (responseData == null) {
        return false;
      }

      // 后端返回格式: {code, message, data: {exists: true, available: false, message: '...'}}
      final data = responseData['data'] as Map<String, dynamic>?;
      if (data == null) {
        return false;
      }
      
      // 检查用户是否存在且可以邀请（不在当前团队）
      final exists = data['exists'] as bool? ?? false;
      final available = data['available'] as bool? ?? false;
      
      return exists && available;
    } catch (e) {
      return false;
    }
  }
}

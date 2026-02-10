import '../../domain/entities/team_member.dart';
import '../../domain/repositories/team_repository.dart';
import '../models/team_member_model.dart';

/// 团队管理 Mock 数据仓库
class MockTeamRepository implements TeamRepository {
  // Mock 数据存储
  final List<Map<String, dynamic>> _members = [
    {
      'id': 1,
      'username': 'admin',
      'email': 'admin@teamsync.com',
      'role': 'team_admin',
      'role_display': '团队管理员',
      'avatar': null,
      'task_count': 15,
      'created_at': '2026-01-01T00:00:00Z',
    },
    {
      'id': 2,
      'username': 'zhangsan',
      'email': 'zhangsan@teamsync.com',
      'role': 'member',
      'role_display': '团队成员',
      'avatar': null,
      'task_count': 8,
      'created_at': '2026-01-15T08:00:00Z',
    },
    {
      'id': 3,
      'username': 'lisi',
      'email': 'lisi@teamsync.com',
      'role': 'member',
      'role_display': '团队成员',
      'avatar': null,
      'task_count': 12,
      'created_at': '2026-01-16T09:30:00Z',
    },
    {
      'id': 4,
      'username': 'wangwu',
      'email': 'wangwu@teamsync.com',
      'role': 'member',
      'role_display': '团队成员',
      'avatar': null,
      'task_count': 6,
      'created_at': '2026-01-20T10:00:00Z',
    },
    {
      'id': 5,
      'username': 'zhaoliu',
      'email': 'zhaoliu@teamsync.com',
      'role': 'member',
      'role_display': '团队成员',
      'avatar': null,
      'task_count': 10,
      'created_at': '2026-02-01T11:00:00Z',
    },
  ];

  // 模拟网络延迟
  Future<T> _simulateDelay<T>(T data) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return data;
  }

  @override
  Future<List<TeamMember>> getTeamMembers({TeamMemberFilter? filter}) async {
    await _simulateDelay(null);

    var members = _members.map((json) => TeamMemberModel.fromJson(json)).toList();

    // 应用角色过滤
    if (filter?.role != null && filter!.role!.isNotEmpty) {
      members = members.where((m) => m.role == filter.role).toList();
    }

    // 应用搜索过滤
    if (filter?.search != null && filter!.search!.isNotEmpty) {
      final searchLower = filter.search!.toLowerCase();
      members = members.where((m) {
        return m.username.toLowerCase().contains(searchLower) ||
            m.email.toLowerCase().contains(searchLower);
      }).toList();
    }

    // 按创建时间倒序排列
    members.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return members;
  }

  @override
  Future<TeamMember> inviteMember(InviteMemberRequest request) async {
    await _simulateDelay(null);

    // 检查用户是否已存在
    final existingIndex = _members.indexWhere(
      (m) => m['username'] == request.username,
    );
    if (existingIndex != -1) {
      throw Exception('用户已是团队成员');
    }

    // 模拟生成新成员
    final newId = _members.length + 1;
    final roleDisplay = request.role == 'team_admin' ? '团队管理员' : '团队成员';
    
    final newMember = {
      'id': newId,
      'username': request.username,
      'email': '$request.username@teamsync.com',
      'role': request.role,
      'role_display': roleDisplay,
      'avatar': null,
      'task_count': 0,
      'created_at': DateTime.now().toIso8601String(),
    };

    _members.add(newMember);

    return TeamMemberModel.fromJson(newMember);
  }

  @override
  Future<TeamMember> updateMemberRole(
    int memberId,
    UpdateRoleRequest request,
  ) async {
    await _simulateDelay(null);

    final index = _members.indexWhere((m) => m['id'] == memberId);
    if (index == -1) {
      throw Exception('成员不存在');
    }

    final roleDisplay = request.role == 'team_admin' ? '团队管理员' : '团队成员';
    
    _members[index] = {
      ..._members[index],
      'role': request.role,
      'role_display': roleDisplay,
    };

    return TeamMemberModel.fromJson(_members[index]);
  }

  @override
  Future<void> removeMember(int memberId) async {
    await _simulateDelay(null);

    final index = _members.indexWhere((m) => m['id'] == memberId);
    if (index == -1) {
      throw Exception('成员不存在');
    }

    // 检查是否至少保留一个管理员
    final member = _members[index];
    if (member['role'] == 'team_admin') {
      final adminCount = _members.where((m) => m['role'] == 'team_admin').length;
      if (adminCount <= 1) {
        throw Exception('团队至少需要保留一名管理员');
      }
    }

    _members.removeAt(index);
  }

  @override
  Future<bool> checkUsernameExists(String username) async {
    await _simulateDelay(null);
    
    // 模拟已注册的用户列表（不在团队中的用户）
    final registeredUsers = [
      'newuser1',
      'newuser2',
      'developer1',
      'designer1',
      'product_manager',
    ];

    // 检查是否在团队中
    final inTeam = _members.any((m) => m['username'] == username);
    
    // 检查是否已注册
    final isRegistered = registeredUsers.contains(username);

    return isRegistered && !inTeam;
  }
}

import '../../domain/entities/project.dart';
import '../models/project_model.dart';

/// Mock 项目数据仓库
/// 根据 REST API 接口预定义文档实现
class MockProjectRepository {
  // 内存中的项目数据
  final List<ProjectModel> _projects = [];
  int _nextId = 6;

  MockProjectRepository() {
    // 初始化一些示例数据
    _projects.addAll([
      ProjectModel(
        id: 1,
        title: 'TeamSync 开发项目',
        description: '开发新一代团队协作管理系统，包含项目管理、任务分配、进度追踪等功能模块',
        status: 'in_progress',
        progress: 65.0,
        memberCount: 8,
        overdueTaskCount: 1,
        isArchived: false,
        startDate: '2026-02-01',
        endDate: '2026-04-30',
        createdBy: const ProjectMemberModel(
          id: 1,
          username: 'admin',
          role: 'team_admin',
        ),
        members: const [
          ProjectMemberModel(id: 1, username: '张三', role: 'member'),
          ProjectMemberModel(id: 2, username: '李四', role: 'member'),
          ProjectMemberModel(id: 3, username: '王五', role: 'member'),
          ProjectMemberModel(id: 4, username: '赵六', role: 'member'),
        ],
        taskStats: const TaskStatsModel(
          total: 20,
          planning: 3,
          pending: 4,
          inProgress: 8,
          completed: 5,
          overdue: 1,
        ),
        createdAt: '2026-01-15T08:00:00Z',
        updatedAt: '2026-02-09T10:00:00Z',
      ),
      ProjectModel(
        id: 2,
        title: '官网改版项目',
        description: '公司官方网站重新设计开发，采用全新的品牌形象和用户体验设计',
        status: 'planning',
        progress: 30.0,
        memberCount: 5,
        overdueTaskCount: 0,
        isArchived: false,
        startDate: '2026-03-01',
        endDate: '2026-05-15',
        createdBy: const ProjectMemberModel(
          id: 1,
          username: 'admin',
          role: 'team_admin',
        ),
        members: const [
          ProjectMemberModel(id: 2, username: '李四', role: 'member'),
          ProjectMemberModel(id: 3, username: '王五', role: 'member'),
        ],
        taskStats: const TaskStatsModel(
          total: 15,
          planning: 10,
          pending: 3,
          inProgress: 2,
          completed: 0,
          overdue: 0,
        ),
        createdAt: '2026-01-20T08:00:00Z',
        updatedAt: '2026-02-08T10:00:00Z',
      ),
      ProjectModel(
        id: 3,
        title: '电商平台重构',
        description: '对现有电商平台进行技术架构升级，提升性能和可维护性',
        status: 'in_progress',
        progress: 45.0,
        memberCount: 6,
        overdueTaskCount: 2,
        isArchived: false,
        startDate: '2026-01-15',
        endDate: '2026-04-15',
        createdBy: const ProjectMemberModel(
          id: 1,
          username: 'admin',
          role: 'team_admin',
        ),
        members: const [
          ProjectMemberModel(id: 1, username: '张三', role: 'member'),
          ProjectMemberModel(id: 4, username: '赵六', role: 'member'),
          ProjectMemberModel(id: 5, username: '孙七', role: 'member'),
        ],
        taskStats: const TaskStatsModel(
          total: 20,
          planning: 4,
          pending: 5,
          inProgress: 6,
          completed: 5,
          overdue: 2,
        ),
        createdAt: '2026-01-10T08:00:00Z',
        updatedAt: '2026-02-09T10:00:00Z',
      ),
      ProjectModel(
        id: 4,
        title: '移动端 APP 开发',
        description: '开发 iOS 和 Android 双平台的移动端应用',
        status: 'pending',
        progress: 15.0,
        memberCount: 7,
        overdueTaskCount: 0,
        isArchived: false,
        startDate: '2026-02-15',
        endDate: '2026-06-30',
        createdBy: const ProjectMemberModel(
          id: 1,
          username: 'admin',
          role: 'team_admin',
        ),
        members: const [
          ProjectMemberModel(id: 3, username: '王五', role: 'member'),
          ProjectMemberModel(id: 4, username: '赵六', role: 'member'),
        ],
        taskStats: const TaskStatsModel(
          total: 25,
          planning: 20,
          pending: 3,
          inProgress: 2,
          completed: 0,
          overdue: 0,
        ),
        createdAt: '2026-01-25T08:00:00Z',
        updatedAt: '2026-02-07T10:00:00Z',
      ),
      ProjectModel(
        id: 5,
        title: '数据可视化系统',
        description: '构建企业级数据可视化平台，支持多维度数据分析和报表生成',
        status: 'completed',
        progress: 100.0,
        memberCount: 4,
        overdueTaskCount: 0,
        isArchived: true,
        startDate: '2026-01-01',
        endDate: '2026-02-10',
        createdBy: const ProjectMemberModel(
          id: 1,
          username: 'admin',
          role: 'team_admin',
        ),
        members: const [
          ProjectMemberModel(id: 2, username: '李四', role: 'member'),
          ProjectMemberModel(id: 5, username: '孙七', role: 'member'),
        ],
        taskStats: const TaskStatsModel(
          total: 18,
          planning: 0,
          pending: 0,
          inProgress: 0,
          completed: 18,
          overdue: 0,
        ),
        createdAt: '2025-12-15T08:00:00Z',
        updatedAt: '2026-02-10T10:00:00Z',
        archivedAt: '2026-02-10T10:00:00Z',
      ),
    ]);
  }

  /// 获取项目列表
  /// GET /projects/
  /// 
  /// [userId] - 当前用户ID，用于权限过滤（访客需要过滤，成员和管理员都能看到所有项目）
  /// [isAdmin] - 是否为管理员
  /// [isVisitor] - 是否为访客，访客看不到任何项目
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
    // await Future.delayed(const Duration(milliseconds: 500));

    var result = List<Project>.from(_projects);

    // 权限过滤：访客看不到任何项目
    if (isVisitor) {
      return [];
    }
    // 成员和管理员都能看到所有项目（根据 PRD 更新）

    // 状态过滤
    if (status != null && status.isNotEmpty) {
      result = result.where((p) => p.status == status).toList();
    }

    // 归档过滤
    if (!includeArchived) {
      result = result.where((p) => !p.isArchived).toList();
    }

    // 搜索过滤
    if (search != null && search.isNotEmpty) {
      result = result
          .where((p) =>
              p.title.toLowerCase().contains(search.toLowerCase()) ||
              p.description.toLowerCase().contains(search.toLowerCase()))
          .toList();
    }

    // 分页
    final start = (page - 1) * pageSize;
    final end = start + pageSize;
    if (start < result.length) {
      result = result.sublist(start, end > result.length ? result.length : end);
    } else {
      result = [];
    }

    return result;
  }

  /// 检查用户是否是项目成员
  Future<bool> isUserMemberOfProject(int projectId, String? userId) async {
    if (userId == null) return false;
    
    final project = await getProjectById(projectId);
    if (project == null) return false;
    
    final userIdInt = int.tryParse(userId);
    if (userIdInt == null) return false;
    
    // 检查是否是成员或创建者
    return project.members.any((m) => m.id == userIdInt) || 
           project.createdBy?.id == userIdInt;
  }

  /// 获取项目总数
  /// 
  /// [userId] - 当前用户ID，用于权限过滤
  /// [isAdmin] - 是否为管理员
  /// [isVisitor] - 是否为访客
  Future<int> getProjectCount({
    String? status,
    bool includeArchived = false,
    String? search,
    String? userId,
    bool isAdmin = false,
    bool isVisitor = false,
  }) async {
    var result = List<Project>.from(_projects);

    // 权限过滤：访客看不到任何项目
    if (isVisitor) {
      return 0;
    }
    // 成员和管理员都能看到所有项目

    if (status != null && status.isNotEmpty) {
      result = result.where((p) => p.status == status).toList();
    }

    if (!includeArchived) {
      result = result.where((p) => !p.isArchived).toList();
    }

    if (search != null && search.isNotEmpty) {
      result = result
          .where((p) =>
              p.title.toLowerCase().contains(search.toLowerCase()) ||
              p.description.toLowerCase().contains(search.toLowerCase()))
          .toList();
    }

    return result.length;
  }

  /// 获取项目详情
  /// GET /projects/{id}/
  Future<Project?> getProjectById(int id) async {
    // await Future.delayed(const Duration(milliseconds: 400));

    try {
      return _projects.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 创建项目
  /// POST /projects/
  Future<Project> createProject({
    required String title,
    String? description,
    String status = 'planning',
    String? startDate,
    String? endDate,
    required List<int> memberIds,
  }) async {
    // await Future.delayed(const Duration(milliseconds: 800));

    // 获取成员信息（模拟）
    final members = memberIds.map((id) {
      final names = ['张三', '李四', '王五', '赵六', '孙七'];
      return ProjectMemberModel(
        id: id,
        username: names[id % names.length],
        role: 'member',
      );
    }).toList();

    final newProject = ProjectModel(
      id: _nextId++,
      title: title,
      description: description ?? '',
      status: status,
      progress: 0.0,
      memberCount: members.length,
      overdueTaskCount: 0,
      isArchived: false,
      startDate: startDate,
      endDate: endDate,
      createdBy: const ProjectMemberModel(
        id: 1,
        username: 'admin',
        role: 'team_admin',
      ),
      members: members,
      taskStats: const TaskStatsModel(
        total: 0,
        planning: 0,
        pending: 0,
        inProgress: 0,
        completed: 0,
        overdue: 0,
      ),
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );

    _projects.insert(0, newProject);
    return newProject;
  }

  /// 更新项目
  /// PATCH /projects/{id}/
  Future<Project?> updateProject(
    int id, {
    String? title,
    String? description,
    String? status,
    String? startDate,
    String? endDate,
  }) async {
    // await Future.delayed(const Duration(milliseconds: 600));

    final index = _projects.indexWhere((p) => p.id == id);
    if (index == -1) return null;

    final oldProject = _projects[index];
    final updatedProject = ProjectModel(
      id: oldProject.id,
      title: title ?? oldProject.title,
      description: description ?? oldProject.description,
      status: status ?? oldProject.status,
      progress: oldProject.progress,
      memberCount: oldProject.memberCount,
      overdueTaskCount: oldProject.overdueTaskCount,
      isArchived: oldProject.isArchived,
      startDate: startDate ?? oldProject.startDate,
      endDate: endDate ?? oldProject.endDate,
      createdBy: oldProject.createdBy,
      members: oldProject.members,
      taskStats: oldProject.taskStats,
      createdAt: oldProject.createdAt,
      updatedAt: DateTime.now().toIso8601String(),
      archivedAt: oldProject.archivedAt,
    );

    _projects[index] = updatedProject;
    return updatedProject;
  }

  /// 归档项目
  /// PATCH /projects/{id}/archive/
  Future<Project?> archiveProject(int id) async {
    // await Future.delayed(const Duration(milliseconds: 500));

    final index = _projects.indexWhere((p) => p.id == id);
    if (index == -1) return null;

    final oldProject = _projects[index];
    final updatedProject = ProjectModel(
      id: oldProject.id,
      title: oldProject.title,
      description: oldProject.description,
      status: 'archived',
      progress: oldProject.progress,
      memberCount: oldProject.memberCount,
      overdueTaskCount: oldProject.overdueTaskCount,
      isArchived: true,
      startDate: oldProject.startDate,
      endDate: oldProject.endDate,
      createdBy: oldProject.createdBy,
      members: oldProject.members,
      taskStats: oldProject.taskStats,
      createdAt: oldProject.createdAt,
      updatedAt: DateTime.now().toIso8601String(),
      archivedAt: DateTime.now().toIso8601String(),
    );

    _projects[index] = updatedProject;
    return updatedProject;
  }

  /// 删除项目
  /// DELETE /projects/{id}/
  Future<bool> deleteProject(int id) async {
    // await Future.delayed(const Duration(milliseconds: 500));

    final index = _projects.indexWhere((p) => p.id == id);
    if (index == -1) return false;

    // 只能删除已归档的项目
    if (!_projects[index].isArchived) {
      throw Exception('只能删除已归档的项目');
    }

    _projects.removeAt(index);
    return true;
  }

  /// 管理项目成员
  /// PUT /projects/{id}/members/
  Future<Project?> updateProjectMembers(int id, List<int> memberIds) async {
    // await Future.delayed(const Duration(milliseconds: 600));

    final index = _projects.indexWhere((p) => p.id == id);
    if (index == -1) return null;

    final oldProject = _projects[index];
    
    // 获取成员信息
    final members = memberIds.map((id) {
      final names = ['张三', '李四', '王五', '赵六', '孙七'];
      return ProjectMemberModel(
        id: id,
        username: names[id % names.length],
        role: 'member',
      );
    }).toList();

    final updatedProject = ProjectModel(
      id: oldProject.id,
      title: oldProject.title,
      description: oldProject.description,
      status: oldProject.status,
      progress: oldProject.progress,
      memberCount: members.length,
      overdueTaskCount: oldProject.overdueTaskCount,
      isArchived: oldProject.isArchived,
      startDate: oldProject.startDate,
      endDate: oldProject.endDate,
      createdBy: oldProject.createdBy,
      members: members,
      taskStats: oldProject.taskStats,
      createdAt: oldProject.createdAt,
      updatedAt: DateTime.now().toIso8601String(),
      archivedAt: oldProject.archivedAt,
    );

    _projects[index] = updatedProject;
    return updatedProject;
  }

  /// 获取可用成员列表（用于创建项目时选择）
  Future<List<ProjectMember>> getAvailableMembers() async {
    // await Future.delayed(const Duration(milliseconds: 300));

    return const [
      ProjectMemberModel(id: 1, username: '张三', role: 'member'),
      ProjectMemberModel(id: 2, username: '李四', role: 'member'),
      ProjectMemberModel(id: 3, username: '王五', role: 'member'),
      ProjectMemberModel(id: 4, username: '赵六', role: 'member'),
      ProjectMemberModel(id: 5, username: '孙七', role: 'member'),
    ];
  }
}

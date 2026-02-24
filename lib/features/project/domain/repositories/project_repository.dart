import '../entities/project.dart';

/// 项目数据仓库接口
abstract class ProjectRepository {
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
  });

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
  });

  /// 获取项目详情
  /// GET /projects/{id}/
  Future<Project?> getProjectById(int id);

  /// 创建项目
  /// POST /projects/
  Future<Project> createProject({
    required String title,
    String? description,
    String status = 'planning',
    String? startDate,
    String? endDate,
    required List<int> memberIds,
  });

  /// 更新项目
  /// PATCH /projects/{id}/
  Future<Project?> updateProject(
    int id, {
    String? title,
    String? description,
    String? status,
    String? startDate,
    String? endDate,
  });

  /// 归档项目
  /// PATCH /projects/{id}/archive/
  Future<Project?> archiveProject(int id);

  /// 删除项目
  /// DELETE /projects/{id}/
  Future<bool> deleteProject(int id);

  /// 管理项目成员
  /// PUT /projects/{id}/members/
  Future<Project?> updateProjectMembers(int id, List<int> memberIds);

  /// 检查用户是否是项目成员
  Future<bool> isUserMemberOfProject(int projectId, String? userId);

  /// 获取可用成员列表（用于创建项目时选择）
  Future<List<ProjectMember>> getAvailableMembers();
}

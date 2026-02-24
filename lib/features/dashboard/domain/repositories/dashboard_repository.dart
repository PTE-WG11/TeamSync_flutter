import '../../data/repositories/mock_dashboard_repository.dart';
import '../entities/dashboard_stats.dart';
import '../entities/member_workload.dart';
import '../entities/project_summary.dart';

/// 仪表盘数据仓库接口
abstract class DashboardRepository {
  /// 获取仪表盘统计数据
  /// GET /dashboard/admin/
  /// 
  /// [timeRange] 时间范围，用于统计数据的计算
  Future<DashboardStats> getDashboardStats({TimeRange timeRange = TimeRange.week});

  /// 获取最近项目列表
  /// GET /projects/
  /// 
  /// [timeRange] 时间范围，用于过滤项目
  Future<List<ProjectSummary>> getRecentProjects({TimeRange timeRange = TimeRange.week});

  /// 获取成员工作量统计
  /// GET /dashboard/admin/ 中的 member_workload 部分
  /// 
  /// [timeRange] 时间范围，用于统计数据的计算
  Future<List<MemberWorkload>> getMemberWorkloads({TimeRange timeRange = TimeRange.week});

  /// 获取逾期任务预警列表
  /// 模拟逾期任务数据
  Future<List<Map<String, dynamic>>> getOverdueTasks();
}

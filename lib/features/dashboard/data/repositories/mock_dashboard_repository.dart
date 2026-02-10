import '../../domain/entities/dashboard_stats.dart';
import '../../domain/entities/member_workload.dart';
import '../../domain/entities/project_summary.dart';
import '../models/dashboard_stats_model.dart';
import '../models/member_workload_model.dart';
import '../models/project_summary_model.dart';

/// 时间范围枚举
enum TimeRange {
  today('今日'),
  week('本周'),
  month('本月'),
  quarter('本季');

  final String label;
  const TimeRange(this.label);

  /// 从字符串转换
  static TimeRange fromString(String value) {
    switch (value) {
      case '今日':
        return TimeRange.today;
      case '本周':
        return TimeRange.week;
      case '本月':
        return TimeRange.month;
      case '本季':
        return TimeRange.quarter;
      default:
        return TimeRange.week;
    }
  }
}

/// Mock 仪表盘数据仓库
/// 根据 REST API 接口预定义文档实现
class MockDashboardRepository {
  /// 获取仪表盘统计数据
  /// GET /dashboard/admin/
  /// 
  /// [timeRange] 时间范围，用于统计数据的计算
  Future<DashboardStats> getDashboardStats({TimeRange timeRange = TimeRange.week}) async {
    // 模拟网络延迟
    // await Future.delayed(const Duration(milliseconds: 500));

    // 根据时间范围返回不同的统计数据
    switch (timeRange) {
      case TimeRange.today:
        return const DashboardStatsModel(
          activeProjects: 3,
          totalTasks: 12,
          completionRate: 25.0,
          overdueTasks: 2,
          totalProjects: 5,
          archivedProjects: 0,
        );
      case TimeRange.week:
        return const DashboardStatsModel(
          activeProjects: 12,
          totalTasks: 156,
          completionRate: 87.0,
          overdueTasks: 8,
          totalProjects: 14,
          archivedProjects: 2,
        );
      case TimeRange.month:
        return const DashboardStatsModel(
          activeProjects: 15,
          totalTasks: 280,
          completionRate: 72.0,
          overdueTasks: 15,
          totalProjects: 18,
          archivedProjects: 3,
        );
      case TimeRange.quarter:
        return const DashboardStatsModel(
          activeProjects: 20,
          totalTasks: 450,
          completionRate: 65.0,
          overdueTasks: 25,
          totalProjects: 25,
          archivedProjects: 5,
        );
    }
  }

  /// 获取最近项目列表
  /// GET /projects/
  /// 
  /// [timeRange] 时间范围，用于过滤项目
  Future<List<ProjectSummary>> getRecentProjects({TimeRange timeRange = TimeRange.week}) async {
    // await Future.delayed(const Duration(milliseconds: 600));

    // 所有项目数据
    final allProjects = [
      const ProjectSummaryModel(
        id: 1,
        title: 'TeamSync 开发项目',
        description: '开发新一代团队协作管理系统，包含项目管理、任务分配、进度追踪等功能模块',
        status: 'in_progress',
        progress: 0.65,
        completedTasks: 12,
        totalTasks: 20,
        memberCount: 8,
        startDate: '2026-02-10',
        endDate: '2026-04-30',
        overdueTaskCount: 1,
      ),
      const ProjectSummaryModel(
        id: 2,
        title: '官网改版项目',
        description: '公司官方网站重新设计开发，采用全新的品牌形象和用户体验设计',
        status: 'planning',
        progress: 0.30,
        completedTasks: 5,
        totalTasks: 15,
        memberCount: 5,
        startDate: '2026-02-15',
        endDate: '2026-05-15',
        overdueTaskCount: 0,
      ),
      const ProjectSummaryModel(
        id: 3,
        title: '电商平台重构',
        description: '对现有电商平台进行技术架构升级，提升性能和可维护性',
        status: 'in_progress',
        progress: 0.45,
        completedTasks: 9,
        totalTasks: 20,
        memberCount: 6,
        startDate: '2026-02-05',
        endDate: '2026-04-15',
        overdueTaskCount: 2,
      ),
      const ProjectSummaryModel(
        id: 4,
        title: '移动端 APP 开发',
        description: '开发 iOS 和 Android 双平台的移动端应用',
        status: 'pending',
        progress: 0.15,
        completedTasks: 3,
        totalTasks: 25,
        memberCount: 7,
        startDate: '2026-02-20',
        endDate: '2026-06-30',
        overdueTaskCount: 0,
      ),
      const ProjectSummaryModel(
        id: 5,
        title: '数据可视化系统',
        description: '构建企业级数据可视化平台，支持多维度数据分析和报表生成',
        status: 'completed',
        progress: 1.0,
        completedTasks: 18,
        totalTasks: 18,
        memberCount: 4,
        startDate: '2026-02-01',
        endDate: '2026-02-08',
        overdueTaskCount: 0,
      ),
      const ProjectSummaryModel(
        id: 6,
        title: '用户反馈系统',
        description: '建立用户反馈收集和处理系统，提升用户满意度',
        status: 'in_progress',
        progress: 0.55,
        completedTasks: 8,
        totalTasks: 15,
        memberCount: 4,
        startDate: '2026-02-08',
        endDate: '2026-03-30',
        overdueTaskCount: 0,
      ),
      const ProjectSummaryModel(
        id: 7,
        title: '内部工具集',
        description: '开发提升团队效率的内部工具集合',
        status: 'planning',
        progress: 0.10,
        completedTasks: 2,
        totalTasks: 20,
        memberCount: 3,
        startDate: '2026-02-25',
        endDate: '2026-05-30',
        overdueTaskCount: 0,
      ),
    ];

    // 根据时间范围过滤项目
    return _filterProjectsByTimeRange(allProjects, timeRange);
  }

  /// 根据时间范围过滤项目
  List<ProjectSummary> _filterProjectsByTimeRange(
    List<ProjectSummary> projects,
    TimeRange timeRange,
  ) {
    final now = DateTime(2026, 2, 10); // 使用模拟的当前日期

    switch (timeRange) {
      case TimeRange.today:
        // 今日：显示今天有活动（截止日期或开始日期是今天）的项目
        return projects.where((p) {
          final startDate = DateTime.parse(p.startDate);
          final endDate = DateTime.parse(p.endDate);
          return _isSameDay(startDate, now) || 
                 _isSameDay(endDate, now) ||
                 (startDate.isBefore(now) && endDate.isAfter(now));
        }).take(3).toList();

      case TimeRange.week:
        // 本周：显示本周内的项目
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        return projects.where((p) {
          final startDate = DateTime.parse(p.startDate);
          final endDate = DateTime.parse(p.endDate);
          return (startDate.isAfter(weekStart.subtract(const Duration(days: 1))) && 
                  startDate.isBefore(weekEnd.add(const Duration(days: 1)))) ||
                 (endDate.isAfter(weekStart.subtract(const Duration(days: 1))) && 
                  endDate.isBefore(weekEnd.add(const Duration(days: 1)))) ||
                 (startDate.isBefore(weekStart) && endDate.isAfter(weekEnd));
        }).toList();

      case TimeRange.month:
        // 本月：显示本月内的项目
        return projects.where((p) {
          final startDate = DateTime.parse(p.startDate);
          final endDate = DateTime.parse(p.endDate);
          return (startDate.year == now.year && startDate.month == now.month) ||
                 (endDate.year == now.year && endDate.month == now.month) ||
                 (startDate.isBefore(DateTime(now.year, now.month, 1)) && 
                  endDate.isAfter(DateTime(now.year, now.month + 1, 0)));
        }).toList();

      case TimeRange.quarter:
        // 本季：显示本季度内的项目
        final quarterStartMonth = ((now.month - 1) ~/ 3) * 3 + 1;
        return projects.where((p) {
          final startDate = DateTime.parse(p.startDate);
          final endDate = DateTime.parse(p.endDate);
          final quarterStart = DateTime(now.year, quarterStartMonth, 1);
          final quarterEnd = DateTime(now.year, quarterStartMonth + 3, 0);
          return (startDate.isAfter(quarterStart.subtract(const Duration(days: 1))) && 
                  startDate.isBefore(quarterEnd.add(const Duration(days: 1)))) ||
                 (endDate.isAfter(quarterStart.subtract(const Duration(days: 1))) && 
                  endDate.isBefore(quarterEnd.add(const Duration(days: 1)))) ||
                 (startDate.isBefore(quarterStart) && endDate.isAfter(quarterEnd));
        }).toList();
    }
  }

  /// 判断是否为同一天
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// 获取成员工作量统计
  /// GET /dashboard/admin/ 中的 member_workload 部分
  /// 
  /// [timeRange] 时间范围，用于统计数据的计算
  Future<List<MemberWorkload>> getMemberWorkloads({TimeRange timeRange = TimeRange.week}) async {
    // await Future.delayed(const Duration(milliseconds: 400));

    // 根据时间范围返回不同的工作量数据
    switch (timeRange) {
      case TimeRange.today:
        return [
          MemberWorkloadModel(
            userId: 1,
            username: '张三',
            avatar: null,
            assignedTasks: 2,
            completedTasks: 1,
            overdueTasks: 0,
            completionRate: 50.0,
          ),
          MemberWorkloadModel(
            userId: 2,
            username: '李四',
            avatar: null,
            assignedTasks: 3,
            completedTasks: 2,
            overdueTasks: 1,
            completionRate: 66.7,
          ),
        ];
      case TimeRange.week:
        return [
          MemberWorkloadModel(
            userId: 1,
            username: '张三',
            avatar: null,
            assignedTasks: 8,
            completedTasks: 6,
            overdueTasks: 0,
            completionRate: 75.0,
          ),
          MemberWorkloadModel(
            userId: 2,
            username: '李四',
            avatar: null,
            assignedTasks: 12,
            completedTasks: 9,
            overdueTasks: 1,
            completionRate: 75.0,
          ),
          MemberWorkloadModel(
            userId: 3,
            username: '王五',
            avatar: null,
            assignedTasks: 10,
            completedTasks: 7,
            overdueTasks: 2,
            completionRate: 70.0,
          ),
          MemberWorkloadModel(
            userId: 4,
            username: '赵六',
            avatar: null,
            assignedTasks: 6,
            completedTasks: 6,
            overdueTasks: 0,
            completionRate: 100.0,
          ),
          MemberWorkloadModel(
            userId: 5,
            username: '孙七',
            avatar: null,
            assignedTasks: 9,
            completedTasks: 4,
            overdueTasks: 0,
            completionRate: 44.4,
          ),
        ];
      case TimeRange.month:
        return [
          MemberWorkloadModel(
            userId: 1,
            username: '张三',
            avatar: null,
            assignedTasks: 15,
            completedTasks: 11,
            overdueTasks: 1,
            completionRate: 73.3,
          ),
          MemberWorkloadModel(
            userId: 2,
            username: '李四',
            avatar: null,
            assignedTasks: 20,
            completedTasks: 15,
            overdueTasks: 2,
            completionRate: 75.0,
          ),
          MemberWorkloadModel(
            userId: 3,
            username: '王五',
            avatar: null,
            assignedTasks: 18,
            completedTasks: 12,
            overdueTasks: 3,
            completionRate: 66.7,
          ),
        ];
      case TimeRange.quarter:
        return [
          MemberWorkloadModel(
            userId: 1,
            username: '张三',
            avatar: null,
            assignedTasks: 25,
            completedTasks: 18,
            overdueTasks: 2,
            completionRate: 72.0,
          ),
          MemberWorkloadModel(
            userId: 2,
            username: '李四',
            avatar: null,
            assignedTasks: 30,
            completedTasks: 22,
            overdueTasks: 3,
            completionRate: 73.3,
          ),
        ];
    }
  }

  /// 获取逾期任务预警列表
  /// 模拟逾期任务数据
  Future<List<Map<String, dynamic>>> getOverdueTasks() async {
    // await Future.delayed(const Duration(milliseconds: 300));

    return [
      {
        'id': 1,
        'title': '数据库设计',
        'project': '电商平台重构',
        'assignee': '李四',
        'overdueDays': 2,
      },
      {
        'id': 2,
        'title': 'API 接口开发',
        'project': 'TeamSync 开发项目',
        'assignee': '王五',
        'overdueDays': 1,
      },
      {
        'id': 3,
        'title': 'UI 设计稿评审',
        'project': '电商平台重构',
        'assignee': '张三',
        'overdueDays': 3,
      },
    ];
  }
}

import 'package:equatable/equatable.dart';

/// 项目摘要实体
class ProjectSummary extends Equatable {
  /// 项目ID
  final int id;
  
  /// 项目名称
  final String title;
  
  /// 项目描述
  final String description;
  
  /// 项目状态 (planning, pending, in_progress, completed)
  final String status;
  
  /// 进度 (0-1)
  final double progress;
  
  /// 已完成任务数
  final int completedTasks;
  
  /// 总任务数
  final int totalTasks;
  
  /// 参与人数
  final int memberCount;
  
  /// 开始日期
  final String startDate;
  
  /// 结束日期
  final String endDate;
  
  /// 逾期任务数
  final int overdueTaskCount;

  const ProjectSummary({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.progress,
    required this.completedTasks,
    required this.totalTasks,
    required this.memberCount,
    required this.startDate,
    required this.endDate,
    this.overdueTaskCount = 0,
  });

  /// 空数据
  static const ProjectSummary empty = ProjectSummary(
    id: 0,
    title: '',
    description: '',
    status: 'planning',
    progress: 0.0,
    completedTasks: 0,
    totalTasks: 0,
    memberCount: 0,
    startDate: '',
    endDate: '',
  );

  /// 获取状态显示文本
  String get statusDisplay {
    switch (status) {
      case 'planning':
        return '规划中';
      case 'pending':
        return '待处理';
      case 'in_progress':
        return '进行中';
      case 'completed':
        return '已完成';
      default:
        return '未知';
    }
  }

  /// 是否已完成
  bool get isCompleted => status == 'completed';

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        status,
        progress,
        completedTasks,
        totalTasks,
        memberCount,
        startDate,
        endDate,
        overdueTaskCount,
      ];
}

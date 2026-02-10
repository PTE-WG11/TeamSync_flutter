import 'package:equatable/equatable.dart';

/// 成员工作量实体
class MemberWorkload extends Equatable {
  /// 用户ID
  final int userId;
  
  /// 用户名
  final String username;
  
  /// 头像URL
  final String? avatar;
  
  /// 分配的任务数
  final int assignedTasks;
  
  /// 已完成任务数
  final int completedTasks;
  
  /// 逾期任务数
  final int overdueTasks;
  
  /// 完成率 (0-100)
  final double completionRate;

  const MemberWorkload({
    required this.userId,
    required this.username,
    this.avatar,
    required this.assignedTasks,
    required this.completedTasks,
    required this.overdueTasks,
    required this.completionRate,
  });

  /// 用于 const 构造的默认值
  static const String? defaultAvatar = null;

  /// 空数据
  static const MemberWorkload empty = MemberWorkload(
    userId: 0,
    username: '',
    assignedTasks: 0,
    completedTasks: 0,
    overdueTasks: 0,
    completionRate: 0.0,
  );

  @override
  List<Object?> get props => [
        userId,
        username,
        avatar,
        assignedTasks,
        completedTasks,
        overdueTasks,
        completionRate,
      ];
}

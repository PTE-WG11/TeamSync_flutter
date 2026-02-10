import '../../domain/entities/member_workload.dart';

/// 成员工作量数据模型
class MemberWorkloadModel extends MemberWorkload {
  const MemberWorkloadModel({
    required super.userId,
    required super.username,
    required super.avatar,
    required super.assignedTasks,
    required super.completedTasks,
    required super.overdueTasks,
    required super.completionRate,
  });

  /// 从 JSON 转换
  factory MemberWorkloadModel.fromJson(Map<String, dynamic> json) {
    return MemberWorkloadModel(
      userId: json['user_id'] ?? 0,
      username: json['username'] ?? '',
      avatar: json['avatar'],
      assignedTasks: json['assigned_tasks'] ?? 0,
      completedTasks: json['completed_tasks'] ?? 0,
      overdueTasks: json['overdue_tasks'] ?? 0,
      completionRate: (json['completion_rate'] ?? 0.0).toDouble(),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'avatar': avatar,
      'assigned_tasks': assignedTasks,
      'completed_tasks': completedTasks,
      'overdue_tasks': overdueTasks,
      'completion_rate': completionRate,
    };
  }

  /// 从实体转换
  factory MemberWorkloadModel.fromEntity(MemberWorkload entity) {
    return MemberWorkloadModel(
      userId: entity.userId,
      username: entity.username,
      avatar: entity.avatar,
      assignedTasks: entity.assignedTasks,
      completedTasks: entity.completedTasks,
      overdueTasks: entity.overdueTasks,
      completionRate: entity.completionRate,
    );
  }
}

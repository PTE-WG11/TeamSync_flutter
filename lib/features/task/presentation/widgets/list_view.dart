import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/theme.dart';
import '../../../../core/permissions/permission_service.dart';
import '../../domain/entities/task.dart';
import '../bloc/task_bloc.dart';
import '../bloc/task_event.dart';
import 'task_detail_dialog.dart';

/// 任务列表视图
/// 按项目分组，展示主任务→子任务→孙任务的三层级结构
class TaskListView extends StatelessWidget {
  final List<Task> tasks;

  const TaskListView({
    super.key,
    required this.tasks,
  });

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return _buildEmptyState();
    }

    // 按项目分组构建任务树
    final projectGroups = _buildProjectTaskTree(tasks);

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: projectGroups.length,
      itemBuilder: (context, index) {
        final group = projectGroups[index];
        return _ProjectTaskGroup(
          projectId: group.projectId,
          projectName: group.projectName,
          mainTasks: group.mainTasks,
        );
      },
    );
  }

  /// 构建项目任务分组
  /// 注意：后端 /tasks/list/?view=tree 已返回完整树形结构，直接使用 children 字段
  List<_ProjectTaskGroupData> _buildProjectTaskTree(List<Task> tasks) {
    // 按项目ID分组
    final Map<int, List<Task>> groupedByProject = {};
    
    for (final task in tasks) {
      groupedByProject.putIfAbsent(task.projectId, () => []).add(task);
    }

    // 为每个项目构建任务列表
    final result = <_ProjectTaskGroupData>[];
    
    groupedByProject.forEach((projectId, projectTasks) {
      // 获取项目名称
      final projectName = projectTasks.first.project?.title ?? '项目 $projectId';
      
      // 只取主任务(level=1)，子任务已经在 children 字段中
      // 按创建时间倒序
      final mainTasks = projectTasks
          .where((t) => t.level == 1)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      result.add(_ProjectTaskGroupData(
        projectId: projectId,
        projectName: projectName,
        mainTasks: mainTasks,
      ));
    });

    // 按项目名称排序
    result.sort((a, b) => a.projectName.compareTo(b.projectName));
    return result;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无任务',
            style: AppTypography.h4.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '创建一个新任务开始工作吧',
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// 项目任务分组数据
class _ProjectTaskGroupData {
  final int projectId;
  final String projectName;
  final List<Task> mainTasks;

  _ProjectTaskGroupData({
    required this.projectId,
    required this.projectName,
    required this.mainTasks,
  });
}

/// 项目任务分组组件
class _ProjectTaskGroup extends StatelessWidget {
  final int projectId;
  final String projectName;
  final List<Task> mainTasks;

  const _ProjectTaskGroup({
    required this.projectId,
    required this.projectName,
    required this.mainTasks,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 项目标题栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppRadius.lg),
                topRight: Radius.circular(AppRadius.lg),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.folder_outlined,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    projectName,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    '${mainTasks.length} 个主任务',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 主任务列表
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: mainTasks.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _MainTaskCard(task: mainTasks[index]);
            },
          ),
        ],
      ),
    );
  }
}

/// 主任务卡片组件
class _MainTaskCard extends StatelessWidget {
  final Task task;

  const _MainTaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final isExpanded = context.select(
      (TaskBloc bloc) => bloc.state.expandedTaskIds.contains(task.id),
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 主任务头部
          _buildTaskHeader(context, isExpanded),
          // 子任务列表（展开时显示）
          if (isExpanded && task.canHaveSubtasks) ...[
            const Divider(height: 1, indent: 16, endIndent: 16),
            _buildSubTaskList(context),
          ],
        ],
      ),
    );
  }

  Widget _buildTaskHeader(BuildContext context, bool isExpanded) {
    return InkWell(
      onTap: () => _showTaskDetail(context),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 左侧：展开/收起按钮或状态指示器
            _buildLeftIndicator(context, isExpanded),
            const SizedBox(width: 12),
            // 右侧：任务信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 第一行：优先级、状态标签、逾期标记
                  Row(
                    children: [
                      _buildPriorityBadge(task.priority),
                      const SizedBox(width: 8),
                      _buildStatusBadge(task.status),
                      if (task.isOverdue) ...[
                        const SizedBox(width: 8),
                        _buildOverdueBadge(),
                      ],
                      const Spacer(),
                      Text(
                        task.displayId,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // 任务标题
                  Text(
                    task.title,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  if (task.description != null &&
                      task.description!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      task.description!,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  // 底部信息行
                  _buildTaskInfoRow(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftIndicator(BuildContext context, bool isExpanded) {
    // 后端返回的 canHaveSubtasks 字段控制是否可展开
    if (task.canHaveSubtasks) {
      return InkWell(
        onTap: () {
          context.read<TaskBloc>().add(TaskExpandToggled(task.id));
        },
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isExpanded
                ? AppColors.primary.withValues(alpha: 0.1)
                : AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: isExpanded ? AppColors.primary : AppColors.divider,
            ),
          ),
          child: Center(
            child: AnimatedRotation(
              turns: isExpanded ? 0.125 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.arrow_drop_down,
                size: 20,
                color: isExpanded ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    // 无子任务时显示状态小圆点
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: _getStatusColor(task.status).withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: _getStatusColor(task.status),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildTaskInfoRow() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        // 负责人
        _buildInfoItem(
          icon: Icons.person_outline,
          text: task.assigneeName,
        ),
        // 时间范围
        if (task.startDate != null || task.endDate != null)
          _buildInfoItem(
            icon: Icons.calendar_today_outlined,
            text: _formatDateRange(task.startDate, task.endDate),
            color: task.isOverdue ? AppColors.error : AppColors.textSecondary,
          ),
        // 子任务数量（仅可拥有子任务的任务显示）
        if (task.canHaveSubtasks)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.account_tree_outlined,
                  size: 12,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  task.hasChildren 
                      ? '${task.completedSubtaskCount}/${task.subtaskCount}'
                      : '添加',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        // 创建时间
        _buildInfoItem(
          icon: Icons.access_time,
          text: _formatCreatedAt(task.createdAt),
          color: AppColors.textSecondary.withValues(alpha: 0.7),
        ),
      ],
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String text,
    Color? color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: color ?? AppColors.textSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTypography.bodySmall.copyWith(
            color: color ?? AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSubTaskList(BuildContext context) {
    // 如果没有子任务，显示空状态
    if (task.children.isEmpty) {
      return Container(
        color: AppColors.background.withValues(alpha: 0.5),
        padding: const EdgeInsets.fromLTRB(56, 16, 16, 16),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 16,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 8),
            Text(
              '暂无子任务，点击添加子任务',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      color: AppColors.background.withValues(alpha: 0.5),
      padding: const EdgeInsets.fromLTRB(56, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: task.children.asMap().entries.map((entry) {
          final index = entry.key;
          final subTask = entry.value;
          final isLast = index == task.children.length - 1;
          
          return _SubTaskItem(
            subTask: subTask,
            level: 2,
            isLast: isLast,
            onToggle: () {
              context.read<TaskBloc>().add(
                SubTaskStatusToggled(subTask.id),
              );
            },
            onTap: () => _showSubTaskDetail(context, subTask),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    final (color, label) = switch (priority) {
      'urgent' => (AppColors.error, '紧急'),
      'high' => (AppColors.warning, '高'),
      'medium' => (AppColors.info, '中'),
      'low' => (AppColors.textSecondary, '低'),
      _ => (AppColors.textSecondary, '中'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final (color, label) = switch (status) {
      'planning' => (AppColors.statusPlanning, '规划中'),
      'pending' => (AppColors.statusPending, '待处理'),
      'in_progress' => (AppColors.statusInProgress, '进行中'),
      'completed' => (AppColors.statusCompleted, '已完成'),
      _ => (AppColors.textSecondary, '未知'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverdueBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 12,
            color: AppColors.error,
          ),
          const SizedBox(width: 4),
          Text(
            '逾期',
            style: AppTypography.caption.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    return switch (status) {
      'planning' => AppColors.statusPlanning,
      'pending' => AppColors.statusPending,
      'in_progress' => AppColors.statusInProgress,
      'completed' => AppColors.statusCompleted,
      _ => AppColors.textSecondary,
    };
  }

  String _formatDateRange(DateTime? start, DateTime? end) {
    if (start != null && end != null) {
      return '${start.month}/${start.day}-${end.month}/${end.day}';
    } else if (start != null) {
      return '${start.month}/${start.day}开始';
    } else if (end != null) {
      return '${end.month}/${end.day}截止';
    }
    return '无截止日期';
  }

  String _formatCreatedAt(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes}分钟前';
      }
      return '${diff.inHours}小时前';
    } else if (diff.inDays == 1) {
      return '昨天';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}天前';
    } else if (diff.inDays < 30) {
      return '${(diff.inDays / 7).floor()}周前';
    } else {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }

  void _showTaskDetail(BuildContext context) {
    final permissionService = context.read<PermissionService>();
    showDialog(
      context: context,
      builder: (context) => TaskDetailDialog(
        task: task,
        permissionService: permissionService,
        onSubTaskStatusToggle: (subTaskId) {
          context.read<TaskBloc>().add(SubTaskStatusToggled(subTaskId));
        },
        onSubTaskCreate: ({
          required String title,
          String? description,
          String priority = 'medium',
          DateTime? startDate,
          DateTime? endDate,
        }) {
          context.read<TaskBloc>().add(SubTaskCreated(
            parentTaskId: task.id,
            request: CreateSubTaskRequest(
              title: title,
              description: description,
              priority: priority,
              startDate: startDate,
              endDate: endDate,
            ),
          ));
        },
        onEdit: (updatedTask) {
          context.read<TaskBloc>().add(TaskUpdated(
            taskId: updatedTask.id,
            request: UpdateTaskRequest(
              title: updatedTask.title,
              description: updatedTask.description,
              status: updatedTask.status,
              priority: updatedTask.priority,
              assigneeId: updatedTask.assigneeId,
              startDate: updatedTask.startDate,
              endDate: updatedTask.endDate,
            ),
          ));
        },
      ),
    );
  }

  void _showSubTaskDetail(BuildContext context, Task subTask) {
    final permissionService = context.read<PermissionService>();
    showDialog(
      context: context,
      builder: (context) => TaskDetailDialog(
        task: subTask,
        permissionService: permissionService,
        onSubTaskStatusToggle: (grandChildId) {
          context.read<TaskBloc>().add(SubTaskStatusToggled(grandChildId));
        },
        onSubTaskCreate: ({
          required String title,
          String? description,
          String priority = 'medium',
          DateTime? startDate,
          DateTime? endDate,
        }) {
          if (subTask.canCreateSubTask) {
            context.read<TaskBloc>().add(SubTaskCreated(
              parentTaskId: subTask.id,
              request: CreateSubTaskRequest(
                title: title,
                description: description,
                priority: priority,
                startDate: startDate,
                endDate: endDate,
              ),
            ));
          }
        },
        onEdit: (updatedTask) {
          context.read<TaskBloc>().add(TaskUpdated(
            taskId: updatedTask.id,
            request: UpdateTaskRequest(
              title: updatedTask.title,
              description: updatedTask.description,
              status: updatedTask.status,
              priority: updatedTask.priority,
              assigneeId: updatedTask.assigneeId,
              startDate: updatedTask.startDate,
              endDate: updatedTask.endDate,
            ),
          ));
        },
      ),
    );
  }
}

/// 子任务项组件（支持二级和三级）
class _SubTaskItem extends StatelessWidget {
  final Task subTask;
  final int level; // 2=子任务, 3=孙任务
  final bool isLast;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  const _SubTaskItem({
    required this.subTask,
    required this.level,
    required this.isLast,
    required this.onToggle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = subTask.status == 'completed';
    final isInProgress = subTask.status == 'in_progress';
    final hasChildren = subTask.children.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                color: AppColors.divider.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                // 层级指示线
                if (level == 3)
                  Container(
                    width: 16,
                    height: 1,
                    color: AppColors.divider,
                    margin: const EdgeInsets.only(right: 8),
                  ),
                // 状态勾选按钮
                InkWell(
                  onTap: onToggle,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppColors.statusCompleted
                          : isInProgress
                              ? AppColors.statusInProgress.withValues(alpha: 0.2)
                              : AppColors.background,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(
                        color: isCompleted
                            ? AppColors.statusCompleted
                            : isInProgress
                                ? AppColors.statusInProgress
                                : AppColors.divider,
                      ),
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(
                              Icons.check,
                              size: 14,
                              color: AppColors.textInverse,
                            )
                          : isInProgress
                              ? Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: AppColors.statusInProgress,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                )
                              : null,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // 任务内容
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              subTask.title,
                              style: AppTypography.bodySmall.copyWith(
                                fontWeight: FontWeight.w500,
                                decoration: isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: isCompleted
                                    ? AppColors.textSecondary
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          // 状态标签
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(subTask.status)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Text(
                              _getStatusText(subTask.status),
                              style: AppTypography.caption.copyWith(
                                color: _getStatusColor(subTask.status),
                                fontSize: 11,
                              ),
                            ),
                          ),
                          // 逾期标记
                          if (subTask.isOverdue) ...[
                            const SizedBox(width: 6),
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 14,
                              color: AppColors.error,
                            ),
                          ],
                        ],
                      ),
                      if (subTask.description != null &&
                          subTask.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          subTask.description!,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      // 子任务信息行
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 12,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            subTask.assigneeName,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (subTask.endDate != null) ...[
                            const SizedBox(width: 12),
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 12,
                              color: subTask.isOverdue
                                  ? AppColors.error
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${subTask.endDate!.month}/${subTask.endDate!.day}',
                              style: AppTypography.caption.copyWith(
                                color: subTask.isOverdue
                                    ? AppColors.error
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                          // 孙任务数量
                          if (hasChildren) ...[
                            const SizedBox(width: 12),
                            Icon(
                              Icons.account_tree_outlined,
                              size: 12,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${subTask.completedSubtaskCount}/${subTask.subtaskCount}',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // 递归渲染孙任务（三级）
        if (hasChildren)
          Padding(
            padding: const EdgeInsets.only(left: 28, top: 8),
            child: Column(
              children: subTask.children.asMap().entries.map((entry) {
                final index = entry.key;
                final grandChild = entry.value;
                final isLastChild = index == subTask.children.length - 1;
                
                return _SubTaskItem(
                  subTask: grandChild,
                  level: 3,
                  isLast: isLastChild,
                  onToggle: () {
                    context.read<TaskBloc>().add(
                      SubTaskStatusToggled(grandChild.id),
                    );
                  },
                  onTap: () {
                    // 孙任务点击 - 可以显示详情或编辑
                    _showGrandChildDetail(context, grandChild);
                  },
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  void _showGrandChildDetail(BuildContext context, Task grandChild) {
    final permissionService = context.read<PermissionService>();
    showDialog(
      context: context,
      builder: (context) => TaskDetailDialog(
        task: grandChild,
        permissionService: permissionService,
        onSubTaskStatusToggle: (_) {},
        onSubTaskCreate: ({
          required String title,
          String? description,
          String priority = 'medium',
          DateTime? startDate,
          DateTime? endDate,
        }) {}, // 孙任务不能再创建子任务（最多3层），传入空函数
        onEdit: (updatedTask) {
          context.read<TaskBloc>().add(TaskUpdated(
            taskId: updatedTask.id,
            request: UpdateTaskRequest(
              title: updatedTask.title,
              description: updatedTask.description,
              status: updatedTask.status,
              priority: updatedTask.priority,
              assigneeId: updatedTask.assigneeId,
              startDate: updatedTask.startDate,
              endDate: updatedTask.endDate,
            ),
          ));
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    return switch (status) {
      'completed' => AppColors.statusCompleted,
      'in_progress' => AppColors.statusInProgress,
      'pending' || 'planning' => AppColors.statusPending,
      _ => AppColors.textSecondary,
    };
  }

  String _getStatusText(String status) {
    return switch (status) {
      'completed' => '已完成',
      'in_progress' => '进行中',
      'pending' => '待处理',
      'planning' => '规划中',
      _ => '规划中',
    };
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/theme.dart';
import '../../../project/data/repositories/project_repository_impl.dart';
import '../../../project/domain/entities/project.dart';
import '../bloc/task_bloc.dart';
import '../bloc/task_event.dart';
import '../bloc/task_state.dart';
import '../widgets/kanban_view.dart';
import '../widgets/list_view.dart';
import '../widgets/gantt_view.dart';
import '../widgets/calendar_view.dart';
import '../widgets/create_unassigned_task_dialog.dart';

/// 任务管理页面
/// 支持四种视图：列表、看板、甘特图、日历
class TaskManagementPage extends StatefulWidget {
  const TaskManagementPage({super.key});

  @override
  State<TaskManagementPage> createState() => _TaskManagementPageState();
}

class _TaskManagementPageState extends State<TaskManagementPage> {
  List<Project> _projects = [];
  bool _isLoadingProjects = false;

  @override
  void initState() {
    super.initState();
    _loadProjects();
    // 注意：TasksLoadRequested 事件在路由层的 BlocProvider 创建时已发送
  }

  Future<void> _loadProjects() async {
    setState(() => _isLoadingProjects = true);
    try {
      final repository = ProjectRepositoryImpl();
      final projects = await repository.getProjects();
      setState(() => _projects = projects);
    } catch (e) {
      // 忽略错误
    } finally {
      setState(() => _isLoadingProjects = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 不再创建新的 BlocProvider，使用路由层提供的 bloc
    return _TaskManagementPageContent(
      projects: _projects,
      isLoadingProjects: _isLoadingProjects,
    );
  }
}

class _TaskManagementPageContent extends StatelessWidget {
  final List<Project> projects;
  final bool isLoadingProjects;

  const _TaskManagementPageContent({
    required this.projects,
    required this.isLoadingProjects,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 整合后的头部区域：标题 + 视图切换 + 创建按钮 + 筛选
          _buildIntegratedHeader(context),
          const Divider(height: 1),
          // 任务内容区
          Expanded(
            child: BlocBuilder<TaskBloc, TaskState>(
              builder: (context, state) {
                if (state.status == TaskStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.status == TaskStatus.failure) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '加载失败: ${state.errorMessage}',
                          style: AppTypography.body,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context.read<TaskBloc>().add(const TasksLoadRequested());
                          },
                          child: const Text('重试'),
                        ),
                      ],
                    ),
                  );
                }

                // 根据视图模式显示不同内容
                switch (state.viewMode) {
                  case TaskViewMode.list:
                    return TaskListView(tasks: state.tasks);
                  case TaskViewMode.kanban:
                    return TaskKanbanView(columns: state.kanbanColumns);
                  case TaskViewMode.gantt:
                    return TaskGanttView(
                      tasks: state.tasks,
                      dateRange: state.ganttDateRange,
                    );
                  case TaskViewMode.calendar:
                    return TaskCalendarView(tasksByDate: state.calendarTasks);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 整合后的头部区域 - 更紧凑的布局
  Widget _buildIntegratedHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 第一行：标题信息 + 视图切换 + 创建按钮
          Row(
            children: [
              // 标题和任务统计
              Expanded(
                child: Row(
                  children: [
                    Text(
                      '任务管理',
                      style: AppTypography.h3,
                    ),
                    const SizedBox(width: 12),
                    BlocBuilder<TaskBloc, TaskState>(
                      builder: (context, state) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${state.totalCount} 个任务',
                            style: AppTypography.body.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              // 视图切换按钮组
              _buildCompactViewSwitcher(context),
              const SizedBox(width: 16),
              // 创建任务按钮
              ElevatedButton.icon(
                onPressed: () => _showCreateTaskDialog(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('创建任务'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textInverse,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 第二行：筛选栏
          _buildFilterBar(context),
        ],
      ),
    );
  }

  /// 紧凑的视图切换按钮
  Widget _buildCompactViewSwitcher(BuildContext context) {
    return BlocBuilder<TaskBloc, TaskState>(
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: TaskViewMode.values.map((mode) {
              final isSelected = state.viewMode == mode;
              return InkWell(
                onTap: () {
                  context.read<TaskBloc>().add(TaskViewModeChanged(mode));
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : null,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        mode.icon,
                        size: 16,
                        color: isSelected ? AppColors.textInverse : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        mode.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected ? AppColors.textInverse : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  /// 显示创建任务对话框
  void _showCreateTaskDialog(BuildContext context) {
    if (projects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('暂无可用项目，请先创建项目')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => CreateUnassignedTaskDialog(
        projects: projects,
        onCreate: ({
          required int projectId,
          required String title,
          String? description,
          String priority = 'medium',
        }) {
          context.read<TaskBloc>().add(
            UnassignedTaskCreated(
              projectId: projectId,
              title: title,
              description: description,
              priority: priority,
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    return Row(
      children: [
        // 人员筛选
        _buildAssigneeFilter(context),
      ],
    );
  }

  Widget _buildAssigneeFilter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: context.select(
            (TaskBloc bloc) => bloc.state.selectedAssigneeFilter,
          ),
          hint: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.filter_list_outlined, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              const Text('所有人员'),
            ],
          ),
          isDense: true,
          icon: Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.textSecondary),
          borderRadius: BorderRadius.circular(AppRadius.md),
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textPrimary,
          ),
          items: [
            DropdownMenuItem(
              value: null,
              child: Row(
                children: [
                  Icon(Icons.people_outline, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  const Text('所有人员'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'me',
              child: Row(
                children: [
                  Icon(Icons.person_outline, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Text('我负责的'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'others',
              child: Row(
                children: [
                  Icon(Icons.people_outline, size: 16, color: AppColors.info),
                  const SizedBox(width: 8),
                  const Text('其他成员'),
                ],
              ),
            ),
          ],
          onChanged: (value) {
            context.read<TaskBloc>().add(TaskAssigneeFilterChanged(value));
          },
        ),
      ),
    );
  }


}

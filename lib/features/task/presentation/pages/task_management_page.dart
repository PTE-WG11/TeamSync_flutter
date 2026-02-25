import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/theme.dart';
import '../../../../core/permissions/permission_service.dart';
import '../../../project/data/repositories/project_repository_impl.dart';
import '../../../project/domain/entities/project.dart';
import '../../data/repositories/task_repository_impl.dart';
import '../../domain/entities/task.dart';
import '../bloc/task_bloc.dart';
import '../bloc/task_event.dart';
import '../bloc/task_state.dart';
import '../widgets/kanban_view.dart';
import '../widgets/list_view.dart';
import '../widgets/gantt_view.dart';
import '../widgets/calendar_view.dart';

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
          // 页面标题栏
          _buildHeader(context),
          // 视图切换栏
          _buildViewSwitcher(context),
          // 筛选栏
          _buildFilterBar(context),
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '任务管理',
                  style: AppTypography.h3,
                ),
                const SizedBox(height: 4),
                BlocBuilder<TaskBloc, TaskState>(
                  builder: (context, state) {
                    return Text(
                      '共 ${state.totalCount} 个任务',
                      style: AppTypography.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildViewSwitcher(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: BlocBuilder<TaskBloc, TaskState>(
        builder: (context, state) {
          return SegmentedButton<TaskViewMode>(
            segments: TaskViewMode.values.map((mode) {
              return ButtonSegment(
                value: mode,
                label: Text(mode.label),
                icon: Icon(mode.icon, size: 18),
              );
            }).toList(),
            selected: {state.viewMode},
            onSelectionChanged: (selected) {
              context.read<TaskBloc>().add(TaskViewModeChanged(selected.first));
            },
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.primary;
                }
                return null;
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.textInverse;
                }
                return AppColors.textSecondary;
              }),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          // 项目筛选
          _buildProjectFilter(context),
          const SizedBox(width: 16),
          // 状态筛选
          _buildStatusFilter(context),
          const SizedBox(width: 16),
          // 搜索框
          Expanded(
            child: _buildSearchField(context),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectFilter(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<int?>(
        value: context.select((TaskBloc bloc) => bloc.state.selectedProjectId),
        hint: isLoadingProjects 
            ? const Text('加载中...')
            : const Text('所有项目'),
        isDense: true,
        borderRadius: BorderRadius.circular(AppRadius.md),
        items: [
          const DropdownMenuItem(
            value: null,
            child: Text('所有项目'),
          ),
          ...projects.map((project) => DropdownMenuItem(
            value: project.id,
            child: Text(
              project.title,
              overflow: TextOverflow.ellipsis,
            ),
          )),
        ],
        onChanged: (value) {
          context.read<TaskBloc>().add(TaskProjectFilterChanged(value));
        },
      ),
    );
  }

  Widget _buildStatusFilter(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String?>(
        value: context.select(
          (TaskBloc bloc) => bloc.state.filter?.status,
        ),
        hint: const Text('所有状态'),
        isDense: true,
        borderRadius: BorderRadius.circular(AppRadius.md),
        items: [
          const DropdownMenuItem(
            value: null,
            child: Text('所有状态'),
          ),
          DropdownMenuItem(
            value: 'planning',
            child: Row(
              children: [
                _buildStatusDot(AppColors.statusPlanning),
                const SizedBox(width: 8),
                const Text('规划中'),
              ],
            ),
          ),
          DropdownMenuItem(
            value: 'pending',
            child: Row(
              children: [
                _buildStatusDot(AppColors.statusPending),
                const SizedBox(width: 8),
                const Text('待处理'),
              ],
            ),
          ),
          DropdownMenuItem(
            value: 'in_progress',
            child: Row(
              children: [
                _buildStatusDot(AppColors.statusInProgress),
                const SizedBox(width: 8),
                const Text('进行中'),
              ],
            ),
          ),
          DropdownMenuItem(
            value: 'completed',
            child: Row(
              children: [
                _buildStatusDot(AppColors.statusCompleted),
                const SizedBox(width: 8),
                const Text('已完成'),
              ],
            ),
          ),
        ],
        onChanged: (value) {
          final currentFilter = context.read<TaskBloc>().state.filter;
          context.read<TaskBloc>().add(
            TaskFilterChanged(
              TaskFilter(
                status: value,
                assignee: currentFilter?.assignee,
                search: currentFilter?.search,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusDot(Color color) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: '搜索任务...',
        prefixIcon: const Icon(Icons.search, size: 20),
        isDense: true,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      onChanged: (value) {
        final currentFilter = context.read<TaskBloc>().state.filter;
        context.read<TaskBloc>().add(
          TaskFilterChanged(
            TaskFilter(
              status: currentFilter?.status,
              assignee: currentFilter?.assignee,
              search: value.isEmpty ? null : value,
            ),
          ),
        );
      },
    );
  }


}

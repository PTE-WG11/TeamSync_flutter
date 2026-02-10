import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes.dart';
import '../../../../config/theme.dart';
import '../../domain/entities/project.dart';
import '../bloc/project_bloc.dart';
import '../bloc/project_event.dart';
import '../bloc/project_state.dart';
import '../widgets/create_project_dialog.dart';
import '../widgets/project_list_card.dart';

/// 项目列表页面
class ProjectListPage extends StatefulWidget {
  const ProjectListPage({super.key});

  @override
  State<ProjectListPage> createState() => _ProjectListPageState();
}

class _ProjectListPageState extends State<ProjectListPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<ProjectBloc>().add(const ProjectsLoadRequested());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectBloc, ProjectState>(
      builder: (context, state) {
        return Padding(
          padding: AppSpacing.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 页面头部
              _buildHeader(),
              const SizedBox(height: 24),
              // 搜索和筛选栏
              _buildSearchAndFilter(state),
              const SizedBox(height: 24),
              // 项目列表
              Expanded(
                child: _buildBody(state),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 构建页面头部
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('项目管理', style: AppTypography.h3),
        ElevatedButton.icon(
          onPressed: () => _showCreateProjectDialog(),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('创建项目'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textInverse,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
    );
  }

  /// 构建搜索和筛选栏
  Widget _buildSearchAndFilter(ProjectState state) {
    final currentFilter = state is ProjectsLoadSuccess ? state.filter : const ProjectFilter();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          // 搜索框
          Expanded(
            flex: 2,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索项目名称...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: AppColors.background,
              ),
              onChanged: (value) {
                // 延迟搜索，避免频繁请求
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted && _searchController.text == value) {
                    context.read<ProjectBloc>().add(ProjectsSearchChanged(value));
                  }
                });
              },
            ),
          ),
          const SizedBox(width: 16),
          // 状态筛选
          Expanded(
            child: _buildStatusFilter(currentFilter.status),
          ),
          const SizedBox(width: 16),
          // 归档筛选
          _buildArchiveFilter(currentFilter.includeArchived),
        ],
      ),
    );
  }

  /// 构建状态筛选下拉框
  Widget _buildStatusFilter(String? currentStatus) {
    final statusOptions = [
      {'value': '', 'label': '全部状态'},
      {'value': 'planning', 'label': '规划中'},
      {'value': 'pending', 'label': '待处理'},
      {'value': 'in_progress', 'label': '进行中'},
      {'value': 'completed', 'label': '已完成'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentStatus ?? '',
          isExpanded: true,
          hint: const Text('全部状态'),
          items: statusOptions.map((option) {
            return DropdownMenuItem<String>(
              value: option['value'],
              child: Text(option['label']!),
            );
          }).toList(),
          onChanged: (value) {
            final currentState = context.read<ProjectBloc>().state;
            if (currentState is ProjectsLoadSuccess) {
              final newFilter = currentState.filter.copyWith(
                status: value?.isEmpty ?? true ? null : value,
              );
              context.read<ProjectBloc>().add(ProjectsFilterChanged(newFilter));
            }
          },
        ),
      ),
    );
  }

  /// 构建归档筛选
  Widget _buildArchiveFilter(bool includeArchived) {
    return InkWell(
      onTap: () {
        final currentState = context.read<ProjectBloc>().state;
        if (currentState is ProjectsLoadSuccess) {
          final newFilter = currentState.filter.copyWith(
            includeArchived: !includeArchived,
          );
          context.read<ProjectBloc>().add(ProjectsFilterChanged(newFilter));
        }
      },
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: includeArchived ? AppColors.primaryLight : AppColors.background,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: includeArchived ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              includeArchived ? Icons.check_box : Icons.check_box_outline_blank,
              color: includeArchived ? AppColors.primary : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              '显示归档',
              style: AppTypography.body.copyWith(
                color: includeArchived ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建页面主体
  Widget _buildBody(ProjectState state) {
    if (state is ProjectsLoadInProgress) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is ProjectsLoadFailure) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(state.message, style: AppTypography.body.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<ProjectBloc>().add(const ProjectsRefreshRequested());
              },
              child: const Text('重新加载'),
            ),
          ],
        ),
      );
    }

    if (state is ProjectsLoadSuccess) {
      if (state.projects.isEmpty) {
        return _buildEmptyState();
      }

      return RefreshIndicator(
        onRefresh: () async {
          context.read<ProjectBloc>().add(const ProjectsRefreshRequested());
        },
        child: ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: state.projects.length + (state.hasMore ? 1 : 0),
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            if (index == state.projects.length) {
              // 加载更多
              context.read<ProjectBloc>().add(const ProjectsLoadMoreRequested());
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final project = state.projects[index];
            return ProjectListCard(
              project: project,
              onTap: () => _navigateToProjectDetail(project.id),
              onMoreTap: () => _showProjectActions(project),
            );
          },
        ),
      );
    }

    return const Center(child: CircularProgressIndicator());
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open_outlined,
            size: 64,
            color: AppColors.textDisabled,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无项目',
            style: AppTypography.h4.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右上角按钮创建新项目',
            style: AppTypography.body.copyWith(color: AppColors.textDisabled),
          ),
        ],
      ),
    );
  }

  /// 跳转到项目详情
  void _navigateToProjectDetail(int projectId) {
    context.go('${AppRoutes.projects}/$projectId');
  }

  /// 显示创建项目弹窗
  void _showCreateProjectDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<ProjectBloc>(),
        child: const CreateProjectDialog(),
      ),
    ).then((_) {
      // 弹窗关闭后，刷新项目列表
      if (mounted) {
        context.read<ProjectBloc>().add(const ProjectsRefreshRequested());
      }
    });
  }

  /// 显示项目操作菜单
  void _showProjectActions(Project project) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('编辑项目'),
              onTap: () {
                Navigator.pop(context);
                _showEditProjectDialog(project);
              },
            ),
            if (!project.isArchived)
              ListTile(
                leading: const Icon(Icons.archive_outlined),
                title: const Text('归档项目'),
                onTap: () {
                  Navigator.pop(context);
                  _showArchiveConfirm(project);
                },
              ),
            if (project.isArchived)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.error),
                title: const Text('删除项目', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirm(project);
                },
              ),
          ],
        ),
      ),
    );
  }

  /// 显示编辑项目弹窗
  void _showEditProjectDialog(Project project) {
    // TODO: 实现编辑项目弹窗
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('编辑项目', style: AppTypography.h4),
        content: const Text('编辑功能开发中...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  /// 显示归档确认
  void _showArchiveConfirm(Project project) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('归档项目', style: AppTypography.h4),
        content: Text('确定要归档项目"${project.title}"吗？归档后项目将被移动到归档列表。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ProjectBloc>().add(ProjectArchiveRequested(project.id));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('项目"${project.title}"已归档')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: const Text('归档'),
          ),
        ],
      ),
    );
  }

  /// 显示删除确认
  void _showDeleteConfirm(Project project) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('删除项目', style: AppTypography.h4),
        content: Text('确定要删除项目"${project.title}"吗？此操作不可恢复！'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ProjectBloc>().add(ProjectDeleteRequested(project.id));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('项目"${project.title}"已删除'),
                  backgroundColor: AppColors.error,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

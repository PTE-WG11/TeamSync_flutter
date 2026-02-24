import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes.dart';
import '../../../../config/theme.dart';
import '../../../../shared/widgets/cards/admin_stat_card.dart';
import '../../../../shared/widgets/cards/project_card.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../../domain/entities/member_workload.dart';
import '../../domain/entities/project_summary.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';
import '../../../project/presentation/bloc/project_bloc.dart';
import '../../../project/presentation/widgets/create_project_dialog.dart';
import '../../../project/data/repositories/project_repository_impl.dart';
import '../../../task/data/repositories/task_repository_impl.dart';

/// 管理员首页仪表盘
/// 功能：项目进度卡片（所有项目）、逾期预警、快捷创建按钮
/// 
/// 线框图参考：design_img/线框设计.md - 4.1 管理员首页 - 项目仪表盘
class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  @override
  void initState() {
    super.initState();
    // 页面加载时请求数据
    context.read<DashboardBloc>().add(const DashboardDataRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        return Padding(
          padding: AppSpacing.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 页面标题 + 快捷创建按钮
              _buildHeader(),
              const SizedBox(height: 24),
              // 根据状态显示不同内容
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
        Text('项目仪表盘', style: AppTypography.h3),
        ElevatedButton.icon(
          onPressed: () {
            // TODO: 打开创建项目弹窗
            _showCreateProjectDialog();
          },
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

  /// 构建页面主体内容
  Widget _buildBody(DashboardState state) {
    if (state is DashboardLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state is DashboardError) {
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
              state.message,
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<DashboardBloc>().add(const DashboardDataRefreshed());
              },
              child: const Text('重新加载'),
            ),
          ],
        ),
      );
    }

    if (state is DashboardLoaded) {
      return RefreshIndicator(
        onRefresh: () async {
          context.read<DashboardBloc>().add(const DashboardDataRefreshed());
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 统计概览卡片
              _buildOverviewCards(state.stats),
              const SizedBox(height: 24),
              // 成员工作量统计（横向滚动）
              _buildMemberWorkloadSection(state.memberWorkloads),
              const SizedBox(height: 24),
              // 逾期预警区域
              _buildOverdueAlert(state.stats.overdueTasks),
              const SizedBox(height: 24),
              // 项目列表标题 + 时间维度切换
              _buildProjectsHeader(state.timeRange),
              const SizedBox(height: 16),
              // 项目进度卡片列表
              _buildProjectList(state.projects),
              const SizedBox(height: 32),
            ],
          ),
        ),
      );
    }

    // 初始状态，显示加载中
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  /// 统计概览卡片
  Widget _buildOverviewCards(DashboardStats stats) {
    return Row(
      children: [
        Expanded(
          child: AdminStatCard(
            type: AdminStatCardType.activeProjects,
            value: stats.activeProjects,
            onTap: () {
              // 可以跳转到项目列表并过滤活跃项目
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AdminStatCard(
            type: AdminStatCardType.totalTasks,
            value: stats.totalTasks,
            onTap: () {
              // 可以跳转到任务列表
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AdminStatCard(
            type: AdminStatCardType.completionRate,
            value: stats.completionRate,
            onTap: () {
              // 可以跳转到报表页面
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AdminStatCard(
            type: AdminStatCardType.overdueTasks,
            value: stats.overdueTasks,
            onTap: () {
              // 可以跳转到逾期任务列表
            },
          ),
        ),
      ],
    );
  }

  /// 成员工作量统计区域
  Widget _buildMemberWorkloadSection(List<MemberWorkload> workloads) {
    if (workloads.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('成员工作量', style: AppTypography.h4),
        const SizedBox(height: 12),
        Container(
          constraints: const BoxConstraints(
            minHeight: 110,
            maxHeight: 120,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: AppShadows.card,
          ),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            itemCount: workloads.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final member = workloads[index];
              return _buildMemberWorkloadItem(member);
            },
          ),
        ),
      ],
    );
  }

  /// 成员工作量项
  Widget _buildMemberWorkloadItem(MemberWorkload member) {
    final hasOverdue = member.overdueTasks > 0;

    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: hasOverdue ? AppColors.error.withOpacity(0.3) : AppColors.border,
        ),
      ),
      child: IntrinsicHeight(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 头像和用户名
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    member.username.isNotEmpty ? member.username[0] : '?',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    member.username,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            // 使用 SizedBox 替代 Spacer，避免无限高度问题
            const SizedBox(height: 12),
            // 任务统计和完成率
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${member.completedTasks}/${member.assignedTasks}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: hasOverdue
                        ? AppColors.errorLight
                        : AppColors.successLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${member.completionRate.toInt()}%',
                    style: AppTypography.caption.copyWith(
                      color: hasOverdue ? AppColors.error : AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 逾期预警区域
  Widget _buildOverdueAlert(int overdueCount) {
    if (overdueCount == 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.successLight,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppColors.success.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline, color: AppColors.success, size: 20),
            const SizedBox(width: 8),
            Text(
              '当前没有逾期任务，团队进度良好！',
              style: AppTypography.body.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.success,
              ),
            ),
          ],
        ),
      );
    }

    // // 模拟逾期任务数据
    // final overdueTasks = [
    //   _OverdueTask('数据库设计', '电商平台重构', '李四', '已逾期2天'),
    //   _OverdueTask('API 接口开发', 'TeamSync 开发项目', '王五', '已逾期1天'),
    // ];
    final overdueTasks = [
      _OverdueTask('数据库设计', '电商平台重构', '李四', '已逾期2天'),
      _OverdueTask('API 接口开发', 'TeamSync 开发项目', '王五', '已逾期1天'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber, color: AppColors.error, size: 20),
              const SizedBox(width: 8),
              Text(
                '逾期预警 (${overdueTasks.length})',
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...overdueTasks.map((task) => _buildOverdueTaskItem(task)),
        ],
      ),
    );
  }

  Widget _buildOverdueTaskItem(_OverdueTask task) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              task.taskName,
              style: AppTypography.body.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            task.projectName,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            task.assignee,
            style: AppTypography.bodySmall,
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              task.overdueTime,
              style: AppTypography.caption.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 项目列表标题
  Widget _buildProjectsHeader(String selectedTimeRange) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('最近项目', style: AppTypography.h4),
        _buildTimeRangeSelector(selectedTimeRange),
      ],
    );
  }

  /// 时间维度切换选择器
  Widget _buildTimeRangeSelector(String selectedRange) {
    final timeRanges = ['今日', '本周', '本月', '本季'];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: timeRanges.map((range) {
          final isSelected = range == selectedRange;
          return InkWell(
            onTap: () {
              context.read<DashboardBloc>().add(DashboardTimeRangeChanged(range));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : null,
                borderRadius: BorderRadius.circular(AppRadius.lg - 2),
              ),
              child: Text(
                range,
                style: AppTypography.body.copyWith(
                  color: isSelected
                      ? AppColors.textInverse
                      : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w500 : null,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 项目进度卡片列表
  Widget _buildProjectList(List<ProjectSummary> projects) {
    if (projects.isEmpty) {
      return Center(
        child: Column(
          children: [
            Icon(
              Icons.folder_outlined,
              size: 48,
              color: AppColors.textDisabled,
            ),
            const SizedBox(height: 16),
            Text(
              '暂无项目',
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: projects.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final project = projects[index];
        return ProjectCard(
          project: project,
          onTap: () {
            // 跳转到项目详情页
            context.go('${AppRoutes.projects}/${project.id}');
          },
          onMoreTap: () {
            // 显示更多操作菜单
            _showProjectActions(project);
          },
        );
      },
    );
  }

  /// 显示创建项目弹窗
  // void _showCreateProjectDialog() {
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: Text('创建新项目', style: AppTypography.h4),
  //       content: SizedBox(
  //         width: 480,
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             TextField(
  //               decoration: InputDecoration(
  //                 labelText: '项目名称',
  //                 hintText: '请输入项目名称',
  //                 border: OutlineInputBorder(
  //                   borderRadius: BorderRadius.circular(AppRadius.lg),
  //                 ),
  //               ),
  //             ),
  //             const SizedBox(height: 16),
  //             TextField(
  //               maxLines: 3,
  //               decoration: InputDecoration(
  //                 labelText: '项目描述',
  //                 hintText: '请输入项目描述',
  //                 border: OutlineInputBorder(
  //                   borderRadius: BorderRadius.circular(AppRadius.lg),
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: const Text('取消'),
  //         ),
  //         ElevatedButton(
  //           onPressed: () {
  //             Navigator.pop(context);
  //             // TODO: 调用创建项目 API
  //           },
  //           child: const Text('创建项目'),
  //         ),
  //       ],
  //     ),
  //   );
  // }
  // 2. 修改显示弹窗的方法
  void _showCreateProjectDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider(
        // 因为仪表盘本身没有 ProjectBloc，这里我们需要创建一个新的实例
        create: (context) => ProjectBloc(
          repository: ProjectRepositoryImpl(),
          taskRepository: TaskRepositoryImpl(),
        ),
        child: const CreateProjectDialog(),
      ),
    ).then((_) {
      // 弹窗关闭后，刷新仪表盘数据以显示新项目
      if (mounted) {
        context.read<DashboardBloc>().add(const DashboardDataRequested());
      }
    });
  }
  /// 显示项目操作菜单
  void _showProjectActions(ProjectSummary project) {
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
                // TODO: 打开编辑项目弹窗
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive_outlined),
              title: const Text('归档项目'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 归档项目
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text('删除项目', style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(context);
                // TODO: 删除项目确认
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// 逾期任务数据
class _OverdueTask {
  final String taskName;
  final String projectName;
  final String assignee;
  final String overdueTime;

  _OverdueTask(this.taskName, this.projectName, this.assignee, this.overdueTime);
}

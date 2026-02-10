import 'package:flutter/material.dart';
import '../../../../config/theme.dart';

/// 管理员首页仪表盘
/// 功能：项目进度卡片（所有项目）、逾期预警、快捷创建按钮
class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  // 时间维度切换
  String _selectedTimeRange = '本周';
  final List<String> _timeRanges = ['今日', '本周', '本月', '本季'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 页面标题 + 快捷创建按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('项目仪表盘', style: AppTypography.h3),
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: 创建项目
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
          ),
          const SizedBox(height: 24),
          // 统计概览卡片
          _buildOverviewCards(),
          const SizedBox(height: 32),
          // 逾期预警区域
          _buildOverdueAlert(),
          const SizedBox(height: 32),
          // 项目列表标题 + 时间维度切换
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('所有项目', style: AppTypography.h4),
              _buildTimeRangeSelector(),
            ],
          ),
          const SizedBox(height: 16),
          // 项目进度卡片列表
          Expanded(
            child: _buildProjectList(),
          ),
        ],
      ),
    );
  }

  /// 统计概览卡片
  Widget _buildOverviewCards() {
    final stats = [
      _StatData('活跃项目', '12', AppColors.primary, Icons.folder_open),
      _StatData('总任务数', '156', AppColors.info, Icons.task_alt),
      _StatData('完成率', '87%', AppColors.success, Icons.trending_up),
      _StatData('逾期任务', '8', AppColors.error, Icons.warning_amber),
    ];

    return Row(
      children: stats.map((stat) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: _buildStatCard(stat),
        ),
      )).toList(),
    );
  }

  Widget _buildStatCard(_StatData stat) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: stat.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  stat.icon,
                  color: stat.color,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            stat.value,
            style: AppTypography.h2.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            stat.label,
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// 逾期预警区域
  Widget _buildOverdueAlert() {
    final overdueTasks = [
      _OverdueTask('数据库设计', '电商平台重构', '李四', '已逾期2天'),
      _OverdueTask('API接口开发', '用户中心系统', '王五', '已逾期1天'),
    ];

    if (overdueTasks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
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
              color: AppColors.error.withValues(alpha: 0.1),
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

  /// 时间维度切换选择器
  Widget _buildTimeRangeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _timeRanges.map((range) {
          final isSelected = range == _selectedTimeRange;
          return InkWell(
            onTap: () => setState(() => _selectedTimeRange = range),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : null,
                borderRadius: BorderRadius.circular(AppRadius.lg - 2),
              ),
              child: Text(
                range,
                style: AppTypography.body.copyWith(
                  color: isSelected ? AppColors.textInverse : AppColors.textSecondary,
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
  Widget _buildProjectList() {
    final projects = [
      _ProjectData(
        id: 1,
        name: '用户中心系统',
        status: '进行中',
        statusColor: AppColors.statusInProgress,
        progress: 0.65,
        completedTasks: 12,
        totalTasks: 20,
        memberCount: 8,
        startDate: '2月1日',
        endDate: '4月30日',
        description: '开发新一代用户认证和权限管理系统...',
      ),
      _ProjectData(
        id: 2,
        name: '电商平台重构',
        status: '规划中',
        statusColor: AppColors.statusPlanning,
        progress: 0.30,
        completedTasks: 5,
        totalTasks: 15,
        memberCount: 5,
        startDate: '3月1日',
        endDate: '5月15日',
        description: '对现有电商平台进行技术架构升级...',
      ),
      _ProjectData(
        id: 3,
        name: '官网改版',
        status: '已完成',
        statusColor: AppColors.statusCompleted,
        progress: 1.0,
        completedTasks: 18,
        totalTasks: 18,
        memberCount: 4,
        startDate: '1月15日',
        endDate: '2月15日',
        description: '公司官方网站重新设计开发...',
      ),
    ];

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: projects.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _ProjectCard(project: projects[index]),
        );
      },
    );
  }
}

/// 统计数据
class _StatData {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  _StatData(this.label, this.value, this.color, this.icon);
}

/// 逾期任务数据
class _OverdueTask {
  final String taskName;
  final String projectName;
  final String assignee;
  final String overdueTime;

  _OverdueTask(this.taskName, this.projectName, this.assignee, this.overdueTime);
}

/// 项目数据
class _ProjectData {
  final int id;
  final String name;
  final String status;
  final Color statusColor;
  final double progress;
  final int completedTasks;
  final int totalTasks;
  final int memberCount;
  final String startDate;
  final String endDate;
  final String description;

  _ProjectData({
    required this.id,
    required this.name,
    required this.status,
    required this.statusColor,
    required this.progress,
    required this.completedTasks,
    required this.totalTasks,
    required this.memberCount,
    required this.startDate,
    required this.endDate,
    required this.description,
  });
}

/// 项目进度卡片
class _ProjectCard extends StatelessWidget {
  final _ProjectData project;

  const _ProjectCard({required this.project});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 状态标签
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: project.statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: project.statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      project.status,
                      style: AppTypography.label.copyWith(
                        color: project.statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // 操作按钮
              IconButton(
                onPressed: () {},
                icon: Icon(
                  Icons.more_vert,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 项目名称
          Text(project.name, style: AppTypography.h4),
          const SizedBox(height: 8),
          // 描述
          Text(
            project.description,
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          // 进度条
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: project.progress,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                project.progress == 1.0 ? AppColors.success : AppColors.primary,
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          // 进度信息
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(project.progress * 100).toInt()}%',
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: project.progress == 1.0 ? AppColors.success : AppColors.primary,
                ),
              ),
              Text(
                '${project.completedTasks}/${project.totalTasks} 个任务完成',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          // 底部信息
          Row(
            children: [
              Icon(Icons.people_outline, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                '${project.memberCount}人参与',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(width: 16),
              Icon(Icons.date_range, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                '${project.startDate} - ${project.endDate}',
                style: AppTypography.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

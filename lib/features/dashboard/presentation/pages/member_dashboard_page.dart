import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import '../../../../shared/widgets/cards/stat_card.dart';

/// 成员首页仪表盘
/// 作为主布局的子页面，不再包含自己的侧边栏和顶部导航
class MemberDashboardPage extends StatefulWidget {
  const MemberDashboardPage({super.key});

  @override
  State<MemberDashboardPage> createState() => _MemberDashboardPageState();
}

class _MemberDashboardPageState extends State<MemberDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTab = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 页面标题
          Text('我的任务', style: AppTypography.h3),
          const SizedBox(height: 24),
          // 统计卡片
          _buildStatCards(),
          const SizedBox(height: 32),
          // TabBar
          _buildTabBar(),
          const SizedBox(height: 24),
          // 任务列表标题
          Text(
            '${_getTabTitle()} (${_getTaskCount()})',
            style: AppTypography.h4,
          ),
          const SizedBox(height: 16),
          // 任务列表
          Expanded(
            child: _buildTaskList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCards() {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            type: StatCardType.today,
            count: 5,
            onTap: () => _tabController.animateTo(0),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            type: StatCardType.week,
            count: 3,
            onTap: () => _tabController.animateTo(1),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            type: StatCardType.overdue,
            count: 1,
            onTap: () => _tabController.animateTo(2),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            type: StatCardType.completed,
            count: 7,
            onTap: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        indicatorWeight: 2,
        labelStyle: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: AppTypography.body,
        tabs: const [
          Tab(text: '今日'),
          Tab(text: '本周'),
          Tab(text: '逾期'),
          Tab(text: '全部'),
        ],
      ),
    );
  }

  Widget _buildTaskList() {
    // Mock 数据
    final tasks = [
      _TaskData(
        id: 101,
        title: 'API接口开发模块',
        description: '完成用户管理模块的API接口开发，包括登录、注册、个人信息接口',
        status: '进行中',
        statusColor: AppColors.statusInProgress,
        projectName: '用户中心系统',
        deadline: '今天 18:00 截止',
        subtaskCount: 2,
        completedSubtaskCount: 1,
      ),
      _TaskData(
        id: 102,
        title: 'UI设计评审',
        description: '参与用户中心系统的UI设计评审会议，提出修改建议',
        status: '待处理',
        statusColor: AppColors.statusPending,
        projectName: '用户中心系统',
        deadline: '今天 16:00 截止',
        subtaskCount: 0,
        completedSubtaskCount: 0,
      ),
      _TaskData(
        id: 103,
        title: '需求分析文档编写',
        description: '完成用户中心系统的需求分析文档，包含功能列表和优先级',
        status: '已完成',
        statusColor: AppColors.statusCompleted,
        projectName: '用户中心系统',
        deadline: '昨天完成',
        subtaskCount: 0,
        completedSubtaskCount: 0,
      ),
    ];

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _TaskCard(task: tasks[index]),
        );
      },
    );
  }

  String _getTabTitle() {
    switch (_selectedTab) {
      case 0:
        return '今日任务';
      case 1:
        return '本周任务';
      case 2:
        return '逾期任务';
      case 3:
        return '全部任务';
      default:
        return '任务';
    }
  }

  int _getTaskCount() {
    switch (_selectedTab) {
      case 0:
        return 5;
      case 1:
        return 3;
      case 2:
        return 1;
      case 3:
        return 12;
      default:
        return 0;
    }
  }
}

/// 任务数据
class _TaskData {
  final int id;
  final String title;
  final String description;
  final String status;
  final Color statusColor;
  final String projectName;
  final String deadline;
  final int subtaskCount;
  final int completedSubtaskCount;

  _TaskData({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.statusColor,
    required this.projectName,
    required this.deadline,
    required this.subtaskCount,
    required this.completedSubtaskCount,
  });
}

/// 任务卡片
class _TaskCard extends StatelessWidget {
  final _TaskData task;

  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border(
          left: BorderSide(color: task.statusColor, width: 3),
        ),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: task.statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: task.statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      task.status,
                      style: AppTypography.label.copyWith(color: task.statusColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '#T-${task.id.toString().padLeft(3, '0')}',
                style: AppTypography.caption,
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.visibility, size: 16),
                label: const Text('查看'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: AppTypography.caption,
                ),
              ),
              const SizedBox(width: 8),
              if (task.status != '已完成')
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('子任务'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: AppTypography.caption,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(task.title, style: AppTypography.h4),
          const SizedBox(height: 8),
          Text(
            task.description,
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.folder_outlined, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(task.projectName, style: AppTypography.bodySmall),
              const SizedBox(width: 16),
              Icon(Icons.schedule, size: 16, 
                color: task.deadline.contains('逾期') ? AppColors.error : AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                task.deadline,
                style: AppTypography.bodySmall.copyWith(
                  color: task.deadline.contains('逾期') ? AppColors.error : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          if (task.subtaskCount > 0) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.list, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  '子任务: ${task.subtaskCount}  完成: ${task.completedSubtaskCount}',
                  style: AppTypography.bodySmall,
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.expand_more, size: 16),
                  label: const Text('展开'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

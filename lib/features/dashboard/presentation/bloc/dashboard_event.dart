import 'package:equatable/equatable.dart';

/// 仪表盘事件基类
abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

/// 加载仪表盘数据
class DashboardDataRequested extends DashboardEvent {
  const DashboardDataRequested();
}

/// 刷新数据
class DashboardDataRefreshed extends DashboardEvent {
  const DashboardDataRefreshed();
}

/// 切换时间范围
class DashboardTimeRangeChanged extends DashboardEvent {
  final String timeRange;

  const DashboardTimeRangeChanged(this.timeRange);

  @override
  List<Object?> get props => [timeRange];
}

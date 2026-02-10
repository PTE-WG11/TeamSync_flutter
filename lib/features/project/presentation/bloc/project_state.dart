import 'package:equatable/equatable.dart';

import '../../domain/entities/project.dart';

/// 项目状态基类
abstract class ProjectState extends Equatable {
  const ProjectState();

  @override
  List<Object?> get props => [];
}

/// 初始状态
class ProjectInitial extends ProjectState {}

// ==================== 项目列表状态 ====================

/// 项目列表加载中
class ProjectsLoadInProgress extends ProjectState {}

/// 项目列表加载成功
class ProjectsLoadSuccess extends ProjectState {
  final List<Project> projects;
  final ProjectFilter filter;
  final bool hasMore;
  final int currentPage;
  final int totalCount;

  const ProjectsLoadSuccess({
    required this.projects,
    this.filter = const ProjectFilter(),
    this.hasMore = false,
    this.currentPage = 1,
    this.totalCount = 0,
  });

  ProjectsLoadSuccess copyWith({
    List<Project>? projects,
    ProjectFilter? filter,
    bool? hasMore,
    int? currentPage,
    int? totalCount,
  }) {
    return ProjectsLoadSuccess(
      projects: projects ?? this.projects,
      filter: filter ?? this.filter,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      totalCount: totalCount ?? this.totalCount,
    );
  }

  @override
  List<Object?> get props => [
        projects,
        filter,
        hasMore,
        currentPage,
        totalCount,
      ];
}

/// 项目列表加载失败
class ProjectsLoadFailure extends ProjectState {
  final String message;

  const ProjectsLoadFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

// ==================== 项目详情状态 ====================

/// 项目详情加载中
class ProjectDetailLoadInProgress extends ProjectState {}

/// 项目详情加载成功
class ProjectDetailLoadSuccess extends ProjectState {
  final Project project;

  const ProjectDetailLoadSuccess(this.project);

  @override
  List<Object?> get props => [project];
}

/// 项目详情加载失败
class ProjectDetailLoadFailure extends ProjectState {
  final String message;

  const ProjectDetailLoadFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

// ==================== 创建项目状态 ====================

/// 创建项目表单状态
class ProjectCreateFormState extends ProjectState {
  final List<ProjectMember> availableMembers;
  final List<int> selectedMemberIds;
  final bool isSubmitting;
  final String? error;

  const ProjectCreateFormState({
    this.availableMembers = const [],
    this.selectedMemberIds = const [],
    this.isSubmitting = false,
    this.error,
  });

  ProjectCreateFormState copyWith({
    List<ProjectMember>? availableMembers,
    List<int>? selectedMemberIds,
    bool? isSubmitting,
    String? error,
  }) {
    return ProjectCreateFormState(
      availableMembers: availableMembers ?? this.availableMembers,
      selectedMemberIds: selectedMemberIds ?? this.selectedMemberIds,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
        availableMembers,
        selectedMemberIds,
        isSubmitting,
        error,
      ];
}

/// 创建项目成功
class ProjectCreateSuccess extends ProjectState {
  final Project project;

  const ProjectCreateSuccess(this.project);

  @override
  List<Object?> get props => [project];
}

/// 创建项目失败
class ProjectCreateFailure extends ProjectState {
  final String message;

  const ProjectCreateFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

// ==================== 更新项目状态 ====================

/// 更新项目进行中
class ProjectUpdateInProgress extends ProjectState {}

/// 更新项目成功
class ProjectUpdateSuccess extends ProjectState {
  final Project project;

  const ProjectUpdateSuccess(this.project);

  @override
  List<Object?> get props => [project];
}

/// 更新项目失败
class ProjectUpdateFailure extends ProjectState {
  final String message;

  const ProjectUpdateFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

// ==================== 归档/删除项目状态 ====================

/// 归档项目成功
class ProjectArchiveSuccess extends ProjectState {
  final int projectId;

  const ProjectArchiveSuccess(this.projectId);

  @override
  List<Object?> get props => [projectId];
}

/// 归档项目失败
class ProjectArchiveFailure extends ProjectState {
  final String message;

  const ProjectArchiveFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

/// 删除项目成功
class ProjectDeleteSuccess extends ProjectState {
  final int projectId;

  const ProjectDeleteSuccess(this.projectId);

  @override
  List<Object?> get props => [projectId];
}

/// 删除项目失败
class ProjectDeleteFailure extends ProjectState {
  final String message;

  const ProjectDeleteFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

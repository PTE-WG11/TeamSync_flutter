import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/mock_project_repository.dart';
import '../../domain/entities/project.dart';
import 'project_event.dart';
import 'project_state.dart';

/// 项目 BLoC
class ProjectBloc extends Bloc<ProjectEvent, ProjectState> {
  final MockProjectRepository _repository;
  static const int _pageSize = 20;

  ProjectBloc({MockProjectRepository? repository})
      : _repository = repository ?? MockProjectRepository(),
        super(ProjectInitial()) {
    on<ProjectsLoadRequested>(_onProjectsLoadRequested);
    on<ProjectsRefreshRequested>(_onProjectsRefreshRequested);
    on<ProjectsFilterChanged>(_onProjectsFilterChanged);
    on<ProjectsSearchChanged>(_onProjectsSearchChanged);
    on<ProjectsLoadMoreRequested>(_onProjectsLoadMoreRequested);
    on<ProjectDetailRequested>(_onProjectDetailRequested);
    on<ProjectDetailCleared>(_onProjectDetailCleared);
    on<ProjectCreateRequested>(_onProjectCreateRequested);
    on<ProjectAvailableMembersRequested>(_onProjectAvailableMembersRequested);
    on<ProjectUpdateRequested>(_onProjectUpdateRequested);
    on<ProjectMembersUpdateRequested>(_onProjectMembersUpdateRequested);
    on<ProjectArchiveRequested>(_onProjectArchiveRequested);
    on<ProjectDeleteRequested>(_onProjectDeleteRequested);
  }

  // ==================== 项目列表处理 ====================

  Future<void> _onProjectsLoadRequested(
    ProjectsLoadRequested event,
    Emitter<ProjectState> emit,
  ) async {
    emit(ProjectsLoadInProgress());

    try {
      final projects = await _repository.getProjects(
        status: event.filter.status,
        includeArchived: event.filter.includeArchived,
        search: event.filter.search,
        page: 1,
        pageSize: _pageSize,
      );

      final totalCount = await _repository.getProjectCount(
        status: event.filter.status,
        includeArchived: event.filter.includeArchived,
        search: event.filter.search,
      );

      emit(ProjectsLoadSuccess(
        projects: projects,
        filter: event.filter,
        hasMore: projects.length < totalCount,
        currentPage: 1,
        totalCount: totalCount,
      ));
    } catch (e) {
      emit(ProjectsLoadFailure(message: '加载项目列表失败: $e'));
    }
  }

  Future<void> _onProjectsRefreshRequested(
    ProjectsRefreshRequested event,
    Emitter<ProjectState> emit,
  ) async {
    final currentState = state;
    ProjectFilter currentFilter = const ProjectFilter();

    if (currentState is ProjectsLoadSuccess) {
      currentFilter = currentState.filter;
    }

    emit(ProjectsLoadInProgress());

    try {
      final projects = await _repository.getProjects(
        status: currentFilter.status,
        includeArchived: currentFilter.includeArchived,
        search: currentFilter.search,
        page: 1,
        pageSize: _pageSize,
      );

      final totalCount = await _repository.getProjectCount(
        status: currentFilter.status,
        includeArchived: currentFilter.includeArchived,
        search: currentFilter.search,
      );

      emit(ProjectsLoadSuccess(
        projects: projects,
        filter: currentFilter,
        hasMore: projects.length < totalCount,
        currentPage: 1,
        totalCount: totalCount,
      ));
    } catch (e) {
      emit(ProjectsLoadFailure(message: '刷新项目列表失败: $e'));
    }
  }

  Future<void> _onProjectsFilterChanged(
    ProjectsFilterChanged event,
    Emitter<ProjectState> emit,
  ) async {
    emit(ProjectsLoadInProgress());

    try {
      final projects = await _repository.getProjects(
        status: event.filter.status,
        includeArchived: event.filter.includeArchived,
        search: event.filter.search,
        page: 1,
        pageSize: _pageSize,
      );

      final totalCount = await _repository.getProjectCount(
        status: event.filter.status,
        includeArchived: event.filter.includeArchived,
        search: event.filter.search,
      );

      emit(ProjectsLoadSuccess(
        projects: projects,
        filter: event.filter,
        hasMore: projects.length < totalCount,
        currentPage: 1,
        totalCount: totalCount,
      ));
    } catch (e) {
      emit(ProjectsLoadFailure(message: '筛选项目失败: $e'));
    }
  }

  Future<void> _onProjectsSearchChanged(
    ProjectsSearchChanged event,
    Emitter<ProjectState> emit,
  ) async {
    // 搜索时更新 filter 并重新加载
    final currentState = state;
    if (currentState is ProjectsLoadSuccess) {
      final newFilter = currentState.filter.copyWith(search: event.search);
      add(ProjectsFilterChanged(newFilter));
    }
  }

  Future<void> _onProjectsLoadMoreRequested(
    ProjectsLoadMoreRequested event,
    Emitter<ProjectState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ProjectsLoadSuccess || !currentState.hasMore) {
      return;
    }

    try {
      final nextPage = currentState.currentPage + 1;
      final moreProjects = await _repository.getProjects(
        status: currentState.filter.status,
        includeArchived: currentState.filter.includeArchived,
        search: currentState.filter.search,
        page: nextPage,
        pageSize: _pageSize,
      );

      final allProjects = [...currentState.projects, ...moreProjects];

      emit(currentState.copyWith(
        projects: allProjects,
        hasMore: moreProjects.length == _pageSize,
        currentPage: nextPage,
      ));
    } catch (e) {
      // 加载更多失败时保持当前状态
    }
  }

  // ==================== 项目详情处理 ====================

  Future<void> _onProjectDetailRequested(
    ProjectDetailRequested event,
    Emitter<ProjectState> emit,
  ) async {
    emit(ProjectDetailLoadInProgress());

    try {
      final project = await _repository.getProjectById(event.projectId);

      if (project != null) {
        emit(ProjectDetailLoadSuccess(project));
      } else {
        emit(ProjectDetailLoadFailure(message: '项目不存在'));
      }
    } catch (e) {
      emit(ProjectDetailLoadFailure(message: '加载项目详情失败: $e'));
    }
  }

  void _onProjectDetailCleared(
    ProjectDetailCleared event,
    Emitter<ProjectState> emit,
  ) {
    if (state is ProjectDetailLoadSuccess) {
      emit(ProjectInitial());
    }
  }

  // ==================== 创建项目处理 ====================

  Future<void> _onProjectCreateRequested(
    ProjectCreateRequested event,
    Emitter<ProjectState> emit,
  ) async {
    emit(const ProjectCreateFormState(isSubmitting: true));

    try {
      final project = await _repository.createProject(
        title: event.title,
        description: event.description,
        status: event.status,
        startDate: event.startDate,
        endDate: event.endDate,
        memberIds: event.memberIds,
      );

      emit(ProjectCreateSuccess(project));

      // 创建成功后刷新列表
      add(const ProjectsRefreshRequested());
    } catch (e) {
      emit(ProjectCreateFailure(message: '创建项目失败: $e'));
    }
  }

  Future<void> _onProjectAvailableMembersRequested(
    ProjectAvailableMembersRequested event,
    Emitter<ProjectState> emit,
  ) async {
    try {
      final members = await _repository.getAvailableMembers();
      emit(ProjectCreateFormState(availableMembers: members));
    } catch (e) {
      emit(ProjectCreateFailure(message: '加载成员列表失败: $e'));
    }
  }

  // ==================== 更新项目处理 ====================

  Future<void> _onProjectUpdateRequested(
    ProjectUpdateRequested event,
    Emitter<ProjectState> emit,
  ) async {
    emit(ProjectUpdateInProgress());

    try {
      final project = await _repository.updateProject(
        event.projectId,
        title: event.title,
        description: event.description,
        status: event.status,
        startDate: event.startDate,
        endDate: event.endDate,
      );

      if (project != null) {
        emit(ProjectUpdateSuccess(project));
        // 更新成功后刷新列表
        add(const ProjectsRefreshRequested());
      } else {
        emit(ProjectUpdateFailure(message: '项目不存在'));
      }
    } catch (e) {
      emit(ProjectUpdateFailure(message: '更新项目失败: $e'));
    }
  }

  Future<void> _onProjectMembersUpdateRequested(
    ProjectMembersUpdateRequested event,
    Emitter<ProjectState> emit,
  ) async {
    emit(ProjectUpdateInProgress());

    try {
      final project = await _repository.updateProjectMembers(
        event.projectId,
        event.memberIds,
      );

      if (project != null) {
        emit(ProjectUpdateSuccess(project));
      } else {
        emit(ProjectUpdateFailure(message: '项目不存在'));
      }
    } catch (e) {
      emit(ProjectUpdateFailure(message: '更新项目成员失败: $e'));
    }
  }

  // ==================== 归档/删除项目处理 ====================

  Future<void> _onProjectArchiveRequested(
    ProjectArchiveRequested event,
    Emitter<ProjectState> emit,
  ) async {
    try {
      final project = await _repository.archiveProject(event.projectId);

      if (project != null) {
        emit(ProjectArchiveSuccess(event.projectId));
        // 归档成功后刷新列表
        add(const ProjectsRefreshRequested());
      } else {
        emit(ProjectArchiveFailure(message: '项目不存在'));
      }
    } catch (e) {
      emit(ProjectArchiveFailure(message: '归档项目失败: $e'));
    }
  }

  Future<void> _onProjectDeleteRequested(
    ProjectDeleteRequested event,
    Emitter<ProjectState> emit,
  ) async {
    try {
      final success = await _repository.deleteProject(event.projectId);

      if (success) {
        emit(ProjectDeleteSuccess(event.projectId));
        // 删除成功后刷新列表
        add(const ProjectsRefreshRequested());
      } else {
        emit(ProjectDeleteFailure(message: '项目不存在'));
      }
    } catch (e) {
      emit(ProjectDeleteFailure(message: '删除项目失败: $e'));
    }
  }
}

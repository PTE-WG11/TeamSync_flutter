import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/project.dart';
import '../../domain/repositories/project_repository.dart';
import '../../../task/domain/entities/task.dart';
import '../../../task/domain/repositories/task_repository.dart';
import 'project_event.dart';
import 'project_state.dart';

/// 项目 BLoC
class ProjectBloc extends Bloc<ProjectEvent, ProjectState> {
  final ProjectRepository _repository;
  final TaskRepository _taskRepository;
  static const int _pageSize = 20;

  ProjectBloc({
    required ProjectRepository repository,
    required TaskRepository taskRepository,
  })  : _repository = repository,
        _taskRepository = taskRepository,
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
    on<ProjectTasksLoadRequested>(_onProjectTasksLoadRequested);
    on<ProjectTaskCreateRequested>(_onProjectTaskCreateRequested);
    on<ProjectSubTaskCreateRequested>(_onProjectSubTaskCreateRequested);
    on<ProjectTaskStatusUpdateRequested>(_onProjectTaskStatusUpdateRequested);
    on<ProjectTaskUpdateRequested>(_onProjectTaskUpdateRequested);
    on<ProjectTaskDeleteRequested>(_onProjectTaskDeleteRequested);
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
        userId: event.userId,
        isAdmin: event.isAdmin,
        isVisitor: event.isVisitor,
      );

      final totalCount = await _repository.getProjectCount(
        status: event.filter.status,
        includeArchived: event.filter.includeArchived,
        search: event.filter.search,
        userId: event.userId,
        isAdmin: event.isAdmin,
        isVisitor: event.isVisitor,
      );

      emit(ProjectsLoadSuccess(
        projects: projects,
        filter: event.filter,
        hasMore: projects.length < totalCount,
        currentPage: 1,
        totalCount: totalCount,
        userId: event.userId,
        isAdmin: event.isAdmin,
        isVisitor: event.isVisitor,
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
    String? currentUserId;
    bool currentIsAdmin = false;
    bool currentIsVisitor = false;

    if (currentState is ProjectsLoadSuccess) {
      currentFilter = currentState.filter;
      currentUserId = currentState.userId;
      currentIsAdmin = currentState.isAdmin;
      currentIsVisitor = currentState.isVisitor;
    }

    emit(ProjectsLoadInProgress());

    try {
      final projects = await _repository.getProjects(
        status: currentFilter.status,
        includeArchived: currentFilter.includeArchived,
        search: currentFilter.search,
        page: 1,
        pageSize: _pageSize,
        userId: currentUserId,
        isAdmin: currentIsAdmin,
        isVisitor: currentIsVisitor,
      );

      final totalCount = await _repository.getProjectCount(
        status: currentFilter.status,
        includeArchived: currentFilter.includeArchived,
        search: currentFilter.search,
        userId: currentUserId,
        isAdmin: currentIsAdmin,
        isVisitor: currentIsVisitor,
      );

      emit(ProjectsLoadSuccess(
        projects: projects,
        filter: currentFilter,
        hasMore: projects.length < totalCount,
        currentPage: 1,
        totalCount: totalCount,
        userId: currentUserId,
        isAdmin: currentIsAdmin,
        isVisitor: currentIsVisitor,
      ));
    } catch (e) {
      emit(ProjectsLoadFailure(message: '刷新项目列表失败: $e'));
    }
  }

  Future<void> _onProjectsFilterChanged(
    ProjectsFilterChanged event,
    Emitter<ProjectState> emit,
  ) async {
    final currentState = state;
    String? currentUserId;
    bool currentIsAdmin = false;
    bool currentIsVisitor = false;

    if (currentState is ProjectsLoadSuccess) {
      currentUserId = currentState.userId;
      currentIsAdmin = currentState.isAdmin;
      currentIsVisitor = currentState.isVisitor;
    }

    emit(ProjectsLoadInProgress());

    try {
      final projects = await _repository.getProjects(
        status: event.filter.status,
        includeArchived: event.filter.includeArchived,
        search: event.filter.search,
        page: 1,
        pageSize: _pageSize,
        userId: currentUserId,
        isAdmin: currentIsAdmin,
        isVisitor: currentIsVisitor,
      );

      final totalCount = await _repository.getProjectCount(
        status: event.filter.status,
        includeArchived: event.filter.includeArchived,
        search: event.filter.search,
        userId: currentUserId,
        isAdmin: currentIsAdmin,
        isVisitor: currentIsVisitor,
      );

      emit(ProjectsLoadSuccess(
        projects: projects,
        filter: event.filter,
        hasMore: projects.length < totalCount,
        currentPage: 1,
        totalCount: totalCount,
        userId: currentUserId,
        isAdmin: currentIsAdmin,
        isVisitor: currentIsVisitor,
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
        userId: currentState.userId,
        isAdmin: currentState.isAdmin,
        isVisitor: currentState.isVisitor,
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

      if (project == null) {
        emit(ProjectDetailLoadFailure(message: '项目不存在'));
        return;
      }

      // 权限检查：非管理员只能访问自己参与的项目
      if (!event.isAdmin && event.userId != null) {
        final hasAccess = await _repository.isUserMemberOfProject(
          event.projectId,
          event.userId,
        );
        if (!hasAccess) {
          emit(const ProjectDetailLoadFailure(
            message: '无权限访问此项目',
            isForbidden: true,
          ));
          return;
        }
      }

      // 加载任务列表
      final tasks = await _taskRepository.getProjectTasks(event.projectId);
      emit(ProjectDetailLoadSuccess(
        project,
        tasks: tasks,
        userId: event.userId,
        isAdmin: event.isAdmin,
      ));
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

  // ==================== 项目任务处理 ====================

  Future<void> _onProjectTasksLoadRequested(
    ProjectTasksLoadRequested event,
    Emitter<ProjectState> emit,
  ) async {
    final currentState = state;
    if (currentState is ProjectDetailLoadSuccess) {
      emit(currentState.copyWith(tasksLoading: true));
    }

    try {
      final tasks = await _taskRepository.getProjectTasks(
        event.projectId,
        view: event.view,
      );

      if (state is ProjectDetailLoadSuccess) {
        final detailState = state as ProjectDetailLoadSuccess;
        emit(detailState.copyWith(
          tasks: tasks,
          tasksLoading: false,
        ));
      }
    } catch (e) {
      if (state is ProjectDetailLoadSuccess) {
        final detailState = state as ProjectDetailLoadSuccess;
        emit(detailState.copyWith(tasksLoading: false));
      }
    }
  }

  Future<void> _onProjectTaskCreateRequested(
    ProjectTaskCreateRequested event,
    Emitter<ProjectState> emit,
  ) async {
    try {
      final request = CreateTaskRequest(
        title: event.title,
        description: event.description,
        assigneeId: event.assigneeId,
        status: event.status,
        priority: event.priority,
        startDate: event.startDate,
        endDate: event.endDate,
      );

      await _taskRepository.createTask(event.projectId, request);

      // 刷新任务列表
      add(ProjectTasksLoadRequested(projectId: event.projectId));
    } catch (e) {
      // 错误处理
    }
  }

  Future<void> _onProjectSubTaskCreateRequested(
    ProjectSubTaskCreateRequested event,
    Emitter<ProjectState> emit,
  ) async {
    try {
      final request = CreateSubTaskRequest(
        title: event.title,
        description: event.description,
        status: event.status,
        priority: event.priority,
        startDate: event.startDate,
        endDate: event.endDate,
      );

      await _taskRepository.createSubTask(event.parentTaskId, request);

      // 刷新任务列表
      if (state is ProjectDetailLoadSuccess) {
        final detailState = state as ProjectDetailLoadSuccess;
        add(ProjectTasksLoadRequested(projectId: detailState.project.id));
      }
    } catch (e) {
      // 错误处理
    }
  }

  Future<void> _onProjectTaskStatusUpdateRequested(
    ProjectTaskStatusUpdateRequested event,
    Emitter<ProjectState> emit,
  ) async {
    try {
      final request = UpdateTaskRequest(status: event.newStatus);
      await _taskRepository.updateTask(event.taskId, request);

      // 刷新任务列表
      if (state is ProjectDetailLoadSuccess) {
        final detailState = state as ProjectDetailLoadSuccess;
        add(ProjectTasksLoadRequested(projectId: detailState.project.id));
      }
    } catch (e) {
      // 错误处理
    }
  }

  Future<void> _onProjectTaskUpdateRequested(
    ProjectTaskUpdateRequested event,
    Emitter<ProjectState> emit,
  ) async {
    try {
      final request = UpdateTaskRequest(
        title: event.title,
        description: event.description,
        status: event.status,
        priority: event.priority,
        assigneeId: event.assigneeId,
        startDate: event.startDate,
        endDate: event.endDate,
      );
      await _taskRepository.updateTask(event.taskId, request);

      // 刷新任务列表
      if (state is ProjectDetailLoadSuccess) {
        final detailState = state as ProjectDetailLoadSuccess;
        add(ProjectTasksLoadRequested(projectId: detailState.project.id));
      }
    } catch (e) {
      // 错误处理
    }
  }

  Future<void> _onProjectTaskDeleteRequested(
    ProjectTaskDeleteRequested event,
    Emitter<ProjectState> emit,
  ) async {
    try {
      await _taskRepository.deleteTask(event.taskId);

      // 刷新任务列表
      if (state is ProjectDetailLoadSuccess) {
        final detailState = state as ProjectDetailLoadSuccess;
        add(ProjectTasksLoadRequested(projectId: detailState.project.id));
      }
    } catch (e) {
      // 错误处理
    }
  }
}

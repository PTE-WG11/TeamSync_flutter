import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/team_member.dart';
import '../../domain/repositories/team_repository.dart';
import 'team_event.dart';
import 'team_state.dart';

class TeamBloc extends Bloc<TeamEvent, TeamState> {
  final TeamRepository _repository;

  TeamBloc({required TeamRepository repository})
      : _repository = repository,
        super(const TeamState()) {
    on<TeamMembersLoaded>(_onMembersLoaded);
    on<TeamRoleFilterChanged>(_onRoleFilterChanged);
    on<TeamSearchChanged>(_onSearchChanged);
    on<TeamMemberInvited>(_onMemberInvited);
    on<TeamMemberRoleUpdated>(_onMemberRoleUpdated);
    on<TeamMemberRemoved>(_onMemberRemoved);
    on<TeamUsernameChecked>(_onUsernameChecked);
    on<TeamErrorCleared>(_onErrorCleared);
  }

  Future<void> _onMembersLoaded(
    TeamMembersLoaded event,
    Emitter<TeamState> emit,
  ) async {
    emit(state.copyWith(status: TeamStatus.loading, clearError: true));

    try {
      final filter = TeamMemberFilter(
        role: event.role,
        search: event.search,
      );
      final members = await _repository.getTeamMembers(filter: filter);

      emit(state.copyWith(
        status: TeamStatus.success,
        members: members,
        roleFilter: event.role,
        searchQuery: event.search ?? '',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: TeamStatus.failure,
        errorMessage: '加载成员列表失败: $e',
      ));
    }
  }

  void _onRoleFilterChanged(
    TeamRoleFilterChanged event,
    Emitter<TeamState> emit,
  ) {
    emit(state.copyWith(roleFilter: event.role));
    // 重新加载数据
    add(TeamMembersLoaded(
      role: event.role,
      search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
    ));
  }

  void _onSearchChanged(
    TeamSearchChanged event,
    Emitter<TeamState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.search));
    // 本地搜索，不需要重新加载
  }

  Future<void> _onMemberInvited(
    TeamMemberInvited event,
    Emitter<TeamState> emit,
  ) async {
    emit(state.copyWith(
      inviteStatus: InviteStatus.inviting,
      clearInviteError: true,
    ));

    try {
      final member = await _repository.inviteMember(event.request);

      // 更新成员列表
      final updatedMembers = [...state.members, member];

      emit(state.copyWith(
        inviteStatus: InviteStatus.invited,
        members: updatedMembers,
        lastInvitedMember: member,
      ));

      // 延迟重置邀请状态
      await Future.delayed(const Duration(seconds: 2));
      if (!emit.isDone) {
        emit(state.copyWith(inviteStatus: InviteStatus.initial));
      }
    } catch (e) {
      emit(state.copyWith(
        inviteStatus: InviteStatus.error,
        inviteErrorMessage: '邀请失败: $e',
      ));
    }
  }

  Future<void> _onMemberRoleUpdated(
    TeamMemberRoleUpdated event,
    Emitter<TeamState> emit,
  ) async {
    emit(state.copyWith(status: TeamStatus.loading, clearError: true));

    try {
      final request = UpdateRoleRequest(role: event.newRole);
      final updatedMember = await _repository.updateMemberRole(
        event.memberId,
        request,
      );

      // 更新成员列表中的数据
      final updatedMembers = state.members.map((m) {
        return m.id == event.memberId ? updatedMember : m;
      }).toList();

      emit(state.copyWith(
        status: TeamStatus.success,
        members: updatedMembers,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: TeamStatus.failure,
        errorMessage: '修改角色失败: $e',
      ));
    }
  }

  Future<void> _onMemberRemoved(
    TeamMemberRemoved event,
    Emitter<TeamState> emit,
  ) async {
    emit(state.copyWith(status: TeamStatus.loading, clearError: true));

    try {
      await _repository.removeMember(event.memberId);

      // 从列表中移除
      final updatedMembers = state.members
          .where((m) => m.id != event.memberId)
          .toList();

      emit(state.copyWith(
        status: TeamStatus.success,
        members: updatedMembers,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: TeamStatus.failure,
        errorMessage: '移除成员失败: $e',
      ));
    }
  }

  Future<void> _onUsernameChecked(
    TeamUsernameChecked event,
    Emitter<TeamState> emit,
  ) async {
    if (event.username.isEmpty) {
      emit(state.copyWith(inviteStatus: InviteStatus.initial));
      return;
    }

    emit(state.copyWith(
      inviteStatus: InviteStatus.checking,
      clearInviteError: true,
    ));

    try {
      final exists = await _repository.checkUsernameExists(event.username);

      emit(state.copyWith(
        inviteStatus: exists ? InviteStatus.valid : InviteStatus.invalid,
      ));
    } catch (e) {
      emit(state.copyWith(
        inviteStatus: InviteStatus.error,
        inviteErrorMessage: '检查用户名失败: $e',
      ));
    }
  }

  void _onErrorCleared(
    TeamErrorCleared event,
    Emitter<TeamState> emit,
  ) {
    emit(state.copyWith(clearError: true, clearInviteError: true));
  }
}

import 'package:equatable/equatable.dart';
import '../../domain/entities/team_member.dart';

enum TeamStatus { initial, loading, success, failure }

enum InviteStatus { initial, checking, valid, invalid, inviting, invited, error }

class TeamState extends Equatable {
  final TeamStatus status;
  final List<TeamMember> members;
  final String? roleFilter;
  final String searchQuery;
  final String? errorMessage;
  
  // 邀请相关状态
  final InviteStatus inviteStatus;
  final String? inviteErrorMessage;
  final TeamMember? lastInvitedMember;

  const TeamState({
    this.status = TeamStatus.initial,
    this.members = const [],
    this.roleFilter,
    this.searchQuery = '',
    this.errorMessage,
    this.inviteStatus = InviteStatus.initial,
    this.inviteErrorMessage,
    this.lastInvitedMember,
  });

  TeamState copyWith({
    TeamStatus? status,
    List<TeamMember>? members,
    String? roleFilter,
    String? searchQuery,
    String? errorMessage,
    InviteStatus? inviteStatus,
    String? inviteErrorMessage,
    TeamMember? lastInvitedMember,
    bool clearError = false,
    bool clearInviteError = false,
  }) {
    return TeamState(
      status: status ?? this.status,
      members: members ?? this.members,
      roleFilter: roleFilter ?? this.roleFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      inviteStatus: inviteStatus ?? this.inviteStatus,
      inviteErrorMessage: clearInviteError 
          ? null 
          : (inviteErrorMessage ?? this.inviteErrorMessage),
      lastInvitedMember: lastInvitedMember ?? this.lastInvitedMember,
    );
  }

  /// 按角色过滤后的成员列表
  List<TeamMember> get filteredMembers {
    var result = members;
    
    if (roleFilter != null && roleFilter!.isNotEmpty) {
      result = result.where((m) => m.role == roleFilter).toList();
    }
    
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      result = result.where((m) {
        return m.username.toLowerCase().contains(query) ||
            m.email.toLowerCase().contains(query);
      }).toList();
    }
    
    return result;
  }

  /// 管理员列表
  List<TeamMember> get adminMembers {
    return members.where((m) => m.isTeamAdmin).toList();
  }

  /// 普通成员列表
  List<TeamMember> get normalMembers {
    return members.where((m) => m.isMember).toList();
  }

  /// 成员总数
  int get totalMembers => members.length;

  /// 管理员数量
  int get adminCount => adminMembers.length;

  @override
  List<Object?> get props => [
        status,
        members,
        roleFilter,
        searchQuery,
        errorMessage,
        inviteStatus,
        inviteErrorMessage,
        lastInvitedMember,
      ];
}

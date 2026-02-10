import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/theme.dart';
import '../../domain/entities/team_member.dart';
import '../bloc/team_bloc.dart';
import '../bloc/team_event.dart';
import '../bloc/team_state.dart';

/// 邀请成员对话框
class InviteMemberDialog extends StatefulWidget {
  const InviteMemberDialog({super.key});

  @override
  State<InviteMemberDialog> createState() => _InviteMemberDialogState();
}

class _InviteMemberDialogState extends State<InviteMemberDialog> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  String _selectedRole = 'member';
  bool _isChecking = false;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('邀请成员', style: AppTypography.h4),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '输入用户名邀请已注册用户加入团队',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              
              // 用户名输入
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: '用户名 *',
                  hintText: '请输入已注册的用户名',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide(color: AppColors.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  suffixIcon: _buildUsernameSuffix(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入用户名';
                  }
                  if (value.trim().length < 2) {
                    return '用户名至少2个字符';
                  }
                  return null;
                },
                onChanged: (value) {
                  if (value.trim().length >= 2) {
                    _debounceCheckUsername(value.trim());
                  }
                },
              ),
              
              // 用户名检查状态提示
              BlocBuilder<TeamBloc, TeamState>(
                builder: (context, state) {
                  if (state.inviteStatus == InviteStatus.checking) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '检查中...',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  if (state.inviteStatus == InviteStatus.valid) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: AppColors.statusCompleted,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '用户名有效，可以邀请',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.statusCompleted,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  if (state.inviteStatus == InviteStatus.invalid) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error,
                            size: 16,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '用户不存在或已是团队成员',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return const SizedBox.shrink();
                },
              ),
              
              const SizedBox(height: 20),
              
              // 角色选择
              Text(
                '分配角色',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildRoleOption(
                      value: 'member',
                      label: '普通成员',
                      description: '可查看和编辑分配的任务',
                      icon: Icons.person,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildRoleOption(
                      value: 'team_admin',
                      label: '管理员',
                      description: '可管理项目和团队成员',
                      icon: Icons.admin_panel_settings,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // 错误提示
              BlocBuilder<TeamBloc, TeamState>(
                builder: (context, state) {
                  if (state.inviteErrorMessage != null) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: AppColors.error.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 16,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              state.inviteErrorMessage!,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              
              // 按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 12),
                  BlocConsumer<TeamBloc, TeamState>(
                    listener: (context, state) {
                      if (state.inviteStatus == InviteStatus.invited) {
                        // 邀请成功，关闭对话框
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                '已成功邀请 ${state.lastInvitedMember?.username}'),
                            backgroundColor: AppColors.statusCompleted,
                          ),
                        );
                      }
                    },
                    builder: (context, state) {
                      final isInviting =
                          state.inviteStatus == InviteStatus.inviting;
                      final isValid =
                          state.inviteStatus == InviteStatus.valid;
                      
                      return ElevatedButton(
                        onPressed: isInviting || !isValid
                            ? null
                            : () => _handleInvite(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textInverse,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                        child: isInviting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.textInverse,
                                ),
                              )
                            : const Text('发送邀请'),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUsernameSuffix() {
    return BlocBuilder<TeamBloc, TeamState>(
      builder: (context, state) {
        if (state.inviteStatus == InviteStatus.valid) {
          return Icon(
            Icons.check_circle,
            color: AppColors.statusCompleted,
            size: 20,
          );
        }
        if (state.inviteStatus == InviteStatus.invalid) {
          return Icon(
            Icons.error,
            color: AppColors.error,
            size: 20,
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildRoleOption({
    required String value,
    required String label,
    required String description,
    required IconData icon,
  }) {
    final isSelected = _selectedRole == value;
    
    return InkWell(
      onTap: () => setState(() => _selectedRole = value),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : AppColors.background,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            // 单选指示器
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.divider,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _debounceCheckUsername(String username) {
    // 简单的防抖处理
    if (_isChecking) return;
    
    setState(() => _isChecking = true);
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        context.read<TeamBloc>().add(TeamUsernameChecked(username));
        setState(() => _isChecking = false);
      }
    });
  }

  void _handleInvite(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    final username = _usernameController.text.trim();
    final request = InviteMemberRequest(
      username: username,
      role: _selectedRole,
    );

    context.read<TeamBloc>().add(TeamMemberInvited(request));
  }
}

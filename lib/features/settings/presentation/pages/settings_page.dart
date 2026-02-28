import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/theme.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/auth/domain/repositories/auth_repository.dart';
import '../widgets/avatar_picker.dart';
import '../widgets/password_change_dialog.dart';

/// 个人设置页面
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  String? _avatarUrl;
  bool _isLoading = false;
  String? _successMessage;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState : null;
    
    _usernameController = TextEditingController(text: user?.username ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    // 确保 avatarUrl 不为空字符串
    _avatarUrl = (user?.avatar?.trim().isNotEmpty ?? false) ? user?.avatar : null;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  /// 保存用户信息
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _successMessage = null;
      _errorMessage = null;
    });

    try {
      final authRepository = context.read<AuthRepository>();
      final updatedUser = await authRepository.updateCurrentUser(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        avatar: _avatarUrl,
      );

      // 更新 AuthBloc 中的用户信息
      if (mounted) {
        context.read<AuthBloc>().add(AuthUserUpdated(updatedUser));
      }

      setState(() {
        _successMessage = '个人信息更新成功';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  /// 显示修改密码对话框
  void _showChangePasswordDialog() {
    final authRepository = context.read<AuthRepository>();
    final authState = context.read<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState : null;
    
    showDialog(
      context: context,
      builder: (context) => PasswordChangeDialog(
        authRepository: authRepository,
        username: user?.username,
        email: user?.email,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState : null;

    return Container(
      color: AppColors.background,
      child: SingleChildScrollView(
        padding: AppSpacing.pagePadding,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 页面标题
                _buildHeader(),
                const SizedBox(height: 32),

                // 成功/错误提示
                if (_successMessage != null) ...[
                  _buildAlertMessage(_successMessage!, isSuccess: true),
                  const SizedBox(height: 16),
                ],
                if (_errorMessage != null) ...[
                  _buildAlertMessage(_errorMessage!, isSuccess: false),
                  const SizedBox(height: 16),
                ],

                // 基本信息卡片
                _buildProfileCard(user),
                const SizedBox(height: 24),

                // 账户安全卡片
                _buildSecurityCard(),
                const SizedBox(height: 24),

                // 团队信息卡片
                if (user?.team != null) _buildTeamCard(user!),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: const Icon(
            Icons.settings_outlined,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '个人设置',
                style: AppTypography.h2,
              ),
              const SizedBox(height: 4),
              Text(
                '管理您的个人信息和账户安全',
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAlertMessage(String message, {required bool isSuccess}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSuccess ? AppColors.successLight : AppColors.errorLight,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isSuccess ? AppColors.success : AppColors.error,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle_outline : Icons.error_outline,
            color: isSuccess ? AppColors.success : AppColors.error,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: AppTypography.body.copyWith(
                color: isSuccess ? AppColors.success : AppColors.error,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                if (isSuccess) {
                  _successMessage = null;
                } else {
                  _errorMessage = null;
                }
              });
            },
            icon: Icon(
              Icons.close,
              color: isSuccess ? AppColors.success : AppColors.error,
              size: 18,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(AuthAuthenticated? user) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '基本信息',
                    style: AppTypography.h4,
                  ),
                ],
              ),
              const Divider(height: 32),
              
              // 头像区域
              Center(
                child: AvatarPicker(
                  avatarUrl: _avatarUrl,
                  username: _usernameController.text,
                  onAvatarChanged: (url) {
                    setState(() {
                      _avatarUrl = url;
                    });
                  },
                  authRepository: context.read<AuthRepository>(),
                ),
              ),
              const SizedBox(height: 24),

              // 用户名
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: '用户名',
                  hintText: '请输入用户名',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '用户名不能为空';
                  }
                  if (value.trim().length < 2) {
                    return '用户名至少需要2个字符';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 邮箱
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: '邮箱地址',
                  hintText: '请输入邮箱地址',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '邮箱不能为空';
                  }
                  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                  if (!emailRegex.hasMatch(value)) {
                    return '请输入有效的邮箱地址';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 角色信息（只读）
              TextFormField(
                initialValue: user?.roleDisplayName ?? '团队成员',
                enabled: false,
                decoration: const InputDecoration(
                  labelText: '角色',
                  prefixIcon: Icon(Icons.badge_outlined),
                  helperText: '角色由团队管理员分配',
                ),
              ),
              const SizedBox(height: 24),

              // 保存按钮
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveProfile,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.textInverse,
                          ),
                        )
                      : const Icon(Icons.save_outlined, size: 18),
                  label: Text(_isLoading ? '保存中...' : '保存修改'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.security_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '账户安全',
                  style: AppTypography.h4,
                ),
              ],
            ),
            const Divider(height: 32),
            
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: const Icon(
                  Icons.lock_outline,
                  color: AppColors.warning,
                  size: 20,
                ),
              ),
              title: Text(
                '修改密码',
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                '定期更换密码可以保护账户安全',
                style: AppTypography.bodySmall,
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
              ),
              onTap: _showChangePasswordDialog,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamCard(AuthAuthenticated user) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.groups_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '团队信息',
                  style: AppTypography.h4,
                ),
              ],
            ),
            const Divider(height: 32),
            
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: const Icon(
                  Icons.business_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              title: Text(
                user.team?.name ?? '未知团队',
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                '您当前所属的团队',
                style: AppTypography.bodySmall,
              ),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.infoLight,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.info,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '如需更换团队，请联系团队管理员或系统管理员',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.info,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

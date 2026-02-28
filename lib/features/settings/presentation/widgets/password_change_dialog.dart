import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import '../../../../features/auth/domain/repositories/auth_repository.dart';

/// 修改密码对话框
class PasswordChangeDialog extends StatefulWidget {
  final AuthRepository authRepository;
  final String? username;
  final String? email;
  
  const PasswordChangeDialog({
    super.key,
    required this.authRepository,
    this.username,
    this.email,
  });

  @override
  State<PasswordChangeDialog> createState() => _PasswordChangeDialogState();
}

class _PasswordChangeDialogState extends State<PasswordChangeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// 验证密码复杂度
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return '请输入新密码';
    }
    if (value.length < 8) {
      return '密码长度不能少于 8 个字符';
    }
    // 检查是否纯数字
    if (RegExp(r'^\d+$').hasMatch(value)) {
      return '密码不能完全是数字';
    }
    // 检查常见弱密码
    final commonPasswords = [
      'password',
      '12345678',
      'qwertyui',
      'abc12345',
      'admin123',
    ];
    if (commonPasswords.contains(value.toLowerCase())) {
      return '密码太常见了';
    }
    // 检查是否与用户信息相似
    if (widget.username != null && 
        value.toLowerCase().contains(widget.username!.toLowerCase())) {
      return '密码与用户信息太相似';
    }
    if (widget.email != null) {
      final emailPrefix = widget.email!.split('@')[0].toLowerCase();
      if (value.toLowerCase().contains(emailPrefix)) {
        return '密码与用户信息太相似';
      }
    }
    return null;
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.authRepository.changePassword(
        oldPassword: _oldPasswordController.text,
        newPassword: _newPasswordController.text,
        newPasswordConfirm: _confirmPasswordController.text,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: AppColors.textInverse,
                  size: 18,
                ),
                SizedBox(width: 8),
                Text('密码修改成功'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.lock_outline,
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          const Text('修改密码'),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.error,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // 旧密码
                TextFormField(
                  controller: _oldPasswordController,
                  obscureText: _obscureOldPassword,
                  decoration: InputDecoration(
                    labelText: '当前密码',
                    hintText: '请输入当前密码',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _obscureOldPassword = !_obscureOldPassword;
                        });
                      },
                      icon: Icon(
                        _obscureOldPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入当前密码';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 新密码
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: _obscureNewPassword,
                  decoration: InputDecoration(
                    labelText: '新密码',
                    hintText: '至少8位，不能纯数字',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _obscureNewPassword = !_obscureNewPassword;
                        });
                      },
                      icon: Icon(
                        _obscureNewPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: _validatePassword,
                ),
                const SizedBox(height: 8),
                
                // 密码规则提示
                Text(
                  '密码要求：8位以上，包含字母和数字，不能是常见密码',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),

                // 确认新密码
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: '确认新密码',
                    hintText: '请再次输入新密码',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请确认新密码';
                    }
                    if (value != _newPasswordController.text) {
                      return '两次新密码输入不一致';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _changePassword,
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.textInverse,
                  ),
                )
              : const Text('确认修改'),
        ),
      ],
    );
  }
}

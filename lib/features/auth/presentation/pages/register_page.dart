import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/routes.dart';
import '../../../../config/theme.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../bloc/auth_bloc.dart';

/// 注册页面
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// 处理注册
  void _handleRegister() {
    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) return;

    // 检查密码是否匹配
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = '两次输入的密码不一致');
      return;
    }

    context.read<AuthBloc>().add(AuthRegisterRequested(
          username: _usernameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          passwordConfirm: _confirmPasswordController.text,
          joinType: 'join',
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            setState(() => _errorMessage = state.message);
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return Row(
            children: [
              // 左侧说明区
              const Expanded(
                flex: 1,
                child: _LeftPanel(),
              ),
              // 右侧表单区
              Expanded(
                flex: 1,
                child: _RightPanel(
                  formKey: _formKey,
                  usernameController: _usernameController,
                  emailController: _emailController,
                  passwordController: _passwordController,
                  confirmPasswordController: _confirmPasswordController,
                  isLoading: isLoading,
                  errorMessage: _errorMessage,
                  onSubmit: _handleRegister,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 左侧说明区
class _LeftPanel extends StatelessWidget {
  const _LeftPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.all(64),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '加入TeamSync',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: AppColors.textInverse,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '注册后请联系团队管理员将您加入团队，即可开始高效协作',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.primaryLight.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 64),
          // 注册流程说明卡片
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primaryDark.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '注册流程说明',
                  style: AppTypography.h4.copyWith(
                    color: AppColors.textInverse,
                  ),
                ),
                const SizedBox(height: 20),
                _buildProcessStep('1', '注册账号成为系统用户'),
                const SizedBox(height: 12),
                _buildProcessStep('2', '登录系统等待团队邀请'),
                const SizedBox(height: 12),
                _buildProcessStep('3', '团队管理员将您加入团队'),
                const SizedBox(height: 12),
                _buildProcessStep('4', '开始协作管理项目任务'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessStep(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              number,
              style: AppTypography.label.copyWith(
                color: AppColors.textInverse,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: AppTypography.body.copyWith(
              color: AppColors.primaryLight.withOpacity(0.9),
            ),
          ),
        ),
      ],
    );
  }
}

/// 右侧表单区
class _RightPanel extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController usernameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onSubmit;

  const _RightPanel({
    required this.formKey,
    required this.usernameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.isLoading,
    this.errorMessage,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(horizontal: 80),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo Header
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            'T',
                            style: TextStyle(
                              color: AppColors.textInverse,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'TeamSync',
                        style: AppTypography.h3,
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  // 标题
                  Text('创建账号', style: AppTypography.h2),
                  const SizedBox(height: 8),
                  Text(
                    '填写以下信息注册账号',
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // 错误提示
                  if (errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: AppColors.error,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  // 表单
                  AppTextField(
                    label: '用户名',
                    hint: '请输入用户名',
                    controller: usernameController,
                    enabled: !isLoading,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '请输入用户名';
                      }
                      if (value.trim().length < 3) {
                        return '用户名至少3个字符';
                      }
                      if (value.trim().length > 20) {
                        return '用户名最多20个字符';
                      }
                      // 用户名只能包含字母、数字、下划线
                      final validUsername = RegExp(r'^[a-zA-Z0-9_]+$');
                      if (!validUsername.hasMatch(value.trim())) {
                        return '用户名只能包含字母、数字和下划线';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  AppTextField(
                    label: '邮箱',
                    hint: '请输入邮箱',
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !isLoading,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '请输入邮箱';
                      }
                      // 邮箱格式验证
                      final emailRegex = RegExp(
                        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                      );
                      if (!emailRegex.hasMatch(value.trim())) {
                        return '请输入有效的邮箱地址';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  AppTextField(
                    label: '密码',
                    hint: '至少8位字符',
                    controller: passwordController,
                    isPassword: true,
                    enabled: !isLoading,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入密码';
                      }
                      if (value.length < 8) {
                        return '密码至少8位字符';
                      }
                      if (value.length > 32) {
                        return '密码最多32位字符';
                      }
                      return null;
                    },
                  ),
                  // 密码要求提示
                  PasswordRequirements(
                    passwordController: passwordController,
                    usernameController: usernameController,
                    emailController: emailController,
                  ),
                  const SizedBox(height: 20),
                  AppTextField(
                    label: '确认密码',
                    hint: '再次输入密码',
                    controller: confirmPasswordController,
                    isPassword: true,
                    enabled: !isLoading,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请再次输入密码';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  // 注册按钮
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: AppButton(
                      label: '注册',
                      onPressed: isLoading ? null : onSubmit,
                      size: AppButtonSize.large,
                      isLoading: isLoading,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 登录链接
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '已有账号?',
                          style: AppTypography.body.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        TextButton(
                          onPressed: isLoading
                              ? null
                              : () => context.go(AppRoutes.login),
                          child: Text(
                            '立即登录',
                            style: AppTypography.body.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PasswordRequirements extends StatelessWidget {
  final TextEditingController passwordController;
  final TextEditingController usernameController;
  final TextEditingController emailController;

  const PasswordRequirements({
    super.key,
    required this.passwordController,
    required this.usernameController,
    required this.emailController,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        passwordController,
        usernameController,
        emailController,
      ]),
      builder: (context, _) {
        final password = passwordController.text;
        final username = usernameController.text;
        final email = emailController.text;

        // 如果密码为空，不显示要求或者显示默认状态（这里选择显示默认状态）
        // 只有当用户开始输入时才进行严格验证反馈，或者一直显示
        // 按照常见做法，一直显示，符合则变绿

        final hasLength = password.length >= 8;
        final isNotNumeric = password.isNotEmpty && !RegExp(r'^\d+$').hasMatch(password);
        final isNotCommon = password.isNotEmpty && !['12345678', 'password', 'admin', '123456', 'qwerty', '11111111'].contains(password.toLowerCase());
        
        bool isNotSimilar = true;
        if (password.isNotEmpty) {
           if (username.isNotEmpty && password.toLowerCase().contains(username.toLowerCase())) isNotSimilar = false;
           if (email.isNotEmpty) {
             final emailName = email.split('@')[0];
             if (emailName.isNotEmpty && password.toLowerCase().contains(emailName.toLowerCase())) isNotSimilar = false;
           }
        } else {
          // 初始状态也可以认为是 true，或者 false，视需求。
          // 这里为了引导用户，如果没输入，显示灰色，输入了再判断
          // 简化逻辑：只要不违反就是 true，初始没违反
        }
        
        // 如果密码为空，所有检查项显示灰色（默认），不显示错误
        // 这里使用 helper 来决定颜色

        return Padding(
          padding: const EdgeInsets.only(top: 8.0, left: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RequirementItem(
                valid: isNotSimilar && password.isNotEmpty,
                text: '不能与个人信息太相似',
                isActive: password.isNotEmpty,
              ),
              _RequirementItem(
                valid: hasLength,
                text: '至少包含 8 个字符',
                isActive: password.isNotEmpty,
              ),
              _RequirementItem(
                valid: isNotCommon,
                text: '不能是一个常见密码',
                isActive: password.isNotEmpty,
              ),
              _RequirementItem(
                valid: isNotNumeric,
                text: '不能全都是数字',
                isActive: password.isNotEmpty,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RequirementItem extends StatelessWidget {
  final bool valid;
  final String text;
  final bool isActive;

  const _RequirementItem({
    required this.valid,
    required this.text,
    this.isActive = true,
  });

  @override
  Widget build(BuildContext context) {
    Color color = AppColors.textSecondary;
    IconData icon = Icons.circle_outlined;

    if (isActive) {
      if (valid) {
        color = AppColors.success;
        icon = Icons.check_circle;
      } else {
        // 如果不满足，保持灰色或者变红？通常变红或者是灰色
        // 这里的需求是“提示”，所以未满足时通常是灰色或红色。
        // 为了体验，输入过程中如果是错的，可以用灰色，提交时报错。
        // 或者实时变红。
        // 简单起见：满足变绿，不满足灰色（默认），或者不满足变红（如果已经输入了）
        // 这里采用：满足变绿，不满足灰色。
        color = AppColors.textSecondary;
        icon = Icons.circle_outlined;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Text(text, style: AppTypography.bodySmall.copyWith(color: color)),
        ],
      ),
    );
  }
}

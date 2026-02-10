import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/routes.dart';
import '../../../../config/theme.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/inputs/app_checkbox.dart';
import '../bloc/auth_bloc.dart';

/// 登录页面
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// 处理登录
  void _handleLogin() {
    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) return;

    context.read<AuthBloc>().add(AuthLoginRequested(
          username: _usernameController.text.trim(),
          password: _passwordController.text,
          rememberMe: _rememberMe,
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
              // 左侧品牌区
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
                  passwordController: _passwordController,
                  rememberMe: _rememberMe,
                  isLoading: isLoading,
                  errorMessage: _errorMessage,
                  onRememberMeChanged: (value) {
                    setState(() => _rememberMe = value ?? false);
                  },
                  onSubmit: _handleLogin,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 左侧品牌区
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
          // Logo
          const Text(
            'TeamSync',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: AppColors.textInverse,
            ),
          ),
          const SizedBox(height: 24),
          // Slogan
          Text(
            '面向软件团队的高效协作管理系统',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.primaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '支持项目-任务多级分解、可视化进度追踪与精细化权限控制',
            style: AppTypography.body.copyWith(
              color: AppColors.primaryLight.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 64),
          // 功能特性列表
          _buildFeature(
            icon: Icons.folder_outlined,
            title: '项目管理',
            desc: '多级任务分解，看板/甘特图/日历视图',
          ),
          const SizedBox(height: 32),
          _buildFeature(
            icon: Icons.people_outline,
            title: '权限控制',
            desc: '基于RBAC的精细化数据隔离与脱敏',
          ),
          const SizedBox(height: 32),
          _buildFeature(
            icon: Icons.trending_up,
            title: '进度追踪',
            desc: '可视化进度聚合与实时协作',
          ),
        ],
      ),
    );
  }

  Widget _buildFeature({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primaryDark.withOpacity(0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: AppColors.textInverse,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.h4.copyWith(
                  color: AppColors.textInverse,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: AppTypography.body.copyWith(
                  color: AppColors.primaryLight.withOpacity(0.9),
                ),
              ),
            ],
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
  final TextEditingController passwordController;
  final bool rememberMe;
  final bool isLoading;
  final String? errorMessage;
  final ValueChanged<bool?> onRememberMeChanged;
  final VoidCallback onSubmit;

  const _RightPanel({
    required this.formKey,
    required this.usernameController,
    required this.passwordController,
    required this.rememberMe,
    required this.isLoading,
    this.errorMessage,
    required this.onRememberMeChanged,
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
                Text('欢迎回来', style: AppTypography.h2),
                const SizedBox(height: 8),
                Text(
                  '请登录您的账号',
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
                  label: '用户名或邮箱',
                  hint: '请输入用户名或邮箱',
                  controller: usernameController,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !isLoading,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '请输入用户名或邮箱';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                AppTextField(
                  label: '密码',
                  hint: '请输入密码',
                  controller: passwordController,
                  isPassword: true,
                  enabled: !isLoading,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入密码';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // 记住我 & 忘记密码
                Row(
                  children: [
                    AppCheckbox(
                      value: rememberMe,
                      onChanged: isLoading ? null : onRememberMeChanged,
                      label: '记住我',
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              // TODO: 忘记密码
                            },
                      child: Text(
                        '忘记密码?',
                        style: AppTypography.body.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // 登录按钮
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: AppButton(
                    label: '登录',
                    onPressed: isLoading ? null : onSubmit,
                    size: AppButtonSize.large,
                    isLoading: isLoading,
                  ),
                ),
                const SizedBox(height: 24),
                // 注册链接
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '还没有账号?',
                        style: AppTypography.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      TextButton(
                        onPressed: isLoading
                            ? null
                            : () => context.go(AppRoutes.register),
                        child: Text(
                          '注册账号',
                          style: AppTypography.body.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                // Footer
                Center(
                  child: Text.rich(
                    TextSpan(
                      text: '登录即表示您同意我们的 ',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      children: [
                        TextSpan(
                          text: '服务条款',
                          style: const TextStyle(
                            color: AppColors.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        const TextSpan(text: ' 和 '),
                        TextSpan(
                          text: '隐私政策',
                          style: const TextStyle(
                            color: AppColors.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

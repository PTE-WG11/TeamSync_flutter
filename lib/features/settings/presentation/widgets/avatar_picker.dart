import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../config/theme.dart';
import '../../../../features/auth/domain/repositories/auth_repository.dart';

/// 头像选择器组件
class AvatarPicker extends StatefulWidget {
  final String? avatarUrl;
  final String username;
  final ValueChanged<String?> onAvatarChanged;
  final AuthRepository? authRepository;

  const AvatarPicker({
    super.key,
    this.avatarUrl,
    required this.username,
    required this.onAvatarChanged,
    this.authRepository,
  });

  @override
  State<AvatarPicker> createState() => _AvatarPickerState();
}

class _AvatarPickerState extends State<AvatarPicker> {
  bool _isUploading = false;

  String get _initial {
    if (widget.username.isEmpty) return '?';
    return widget.username[0].toUpperCase();
  }

  /// 检查 URL 是否有效
  bool get _hasValidAvatar {
    if (widget.avatarUrl == null) return false;
    if (widget.avatarUrl!.isEmpty) return false;
    if (widget.avatarUrl!.trim().isEmpty) return false;
    return true;
  }

  void _showAvatarOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xxl),
        ),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '更换头像',
                style: AppTypography.h4,
              ),
              const SizedBox(height: 16),
              // 上传本地图片
              ListTile(
                leading: const Icon(Icons.upload_file_outlined),
                title: const Text('上传本地图片'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadAvatar();
                },
              ),
              // 使用随机头像
              ListTile(
                leading: const Icon(Icons.shuffle_outlined),
                title: const Text('使用随机头像'),
                onTap: () {
                  Navigator.pop(context);
                  _generateRandomAvatar();
                },
              ),
              // 删除头像
              if (_hasValidAvatar)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                  ),
                  title: Text(
                    '删除头像',
                    style: TextStyle(color: AppColors.error),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onAvatarChanged(null);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  /// 选择并上传本地图片
  Future<void> _pickAndUploadAvatar() async {
    if (widget.authRepository == null) {
      _showError('未配置上传服务，请先登录');
      return;
    }

    try {
      // 打开文件选择器
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true, // 读取文件字节
      );

      if (result == null || result.files.isEmpty) {
        return; // 用户取消了选择
      }

      final file = result.files.first;
      
      // 验证文件大小（最大 5MB）
      if (file.size > 5 * 1024 * 1024) {
        _showError('图片大小不能超过 5MB');
        return;
      }

      // 验证文件类型
      final allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
      final extension = file.extension?.toLowerCase() ?? '';
      if (!allowedExtensions.contains(extension)) {
        _showError('不支持的图片格式: $extension。仅支持: JPG, PNG, GIF, WebP');
        return;
      }

      // 获取文件字节
      final fileBytes = file.bytes;
      if (fileBytes == null) {
        _showError('读取文件失败');
        return;
      }

      // 确定 MIME 类型
      String mimeType;
      switch (extension) {
        case 'jpg':
        case 'jpeg':
          mimeType = 'image/jpeg';
          break;
        case 'png':
          mimeType = 'image/png';
          break;
        case 'gif':
          mimeType = 'image/gif';
          break;
        case 'webp':
          mimeType = 'image/webp';
          break;
        default:
          mimeType = 'image/jpeg';
      }

      setState(() {
        _isUploading = true;
      });

      // 上传头像
      final uploadResult = await widget.authRepository!.uploadAvatar(
        fileBytes: fileBytes,
        fileName: file.name,
        mimeType: mimeType,
      );

      // 上传成功，更新头像
      widget.onAvatarChanged(uploadResult.avatarUrl);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('头像上传成功'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      final errorMessage = e.toString();
      // 提取错误信息
      final message = errorMessage.contains('Exception:') 
          ? errorMessage.split('Exception:').last.trim()
          : errorMessage;
      _showError(message);
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  /// 显示错误信息
  void _showError(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 生成随机头像
  void _generateRandomAvatar() {
    // 使用 dicebear API 生成 PNG 格式的头像
    final seed = DateTime.now().millisecondsSinceEpoch;
    // 使用 robohash 或 dicebear 的 PNG 格式
    final avatarUrl = 'https://robohash.org/$seed?set=set4&size=200x200';
    
    widget.onAvatarChanged(avatarUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.border,
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: _isUploading
                    ? _buildUploadingIndicator()
                    : (_hasValidAvatar
                        ? Image.network(
                            widget.avatarUrl!,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              // 图片加载失败时显示默认头像
                              return _buildDefaultAvatar();
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              );
                            },
                          )
                        : _buildDefaultAvatar()),
              ),
            ),
            if (!_isUploading)
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: () => _showAvatarOptions(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.surface,
                        width: 2,
                      ),
                      boxShadow: AppShadows.sm,
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      color: AppColors.textInverse,
                      size: 16,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_isUploading)
          Text(
            '上传中...',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          )
        else
          TextButton(
            onPressed: () => _showAvatarOptions(context),
            child: const Text('更换头像'),
          ),
      ],
    );
  }

  Widget _buildDefaultAvatar() {
    return Center(
      child: Text(
        _initial,
        style: AppTypography.h2.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildUploadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

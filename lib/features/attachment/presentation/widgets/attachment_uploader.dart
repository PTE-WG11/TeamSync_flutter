import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../config/theme.dart';
import '../../../../core/permissions/permission_service.dart';
import '../../domain/entities/attachment.dart';
import '../../domain/repositories/attachment_repository.dart';

/// 附件上传组件
class AttachmentUploader extends StatefulWidget {
  final int taskId;
  final int? taskAssigneeId;
  final PermissionService permissionService;
  final AttachmentRepository repository;
  final List<Attachment> existingAttachments;
  final Function(List<Attachment>) onAttachmentsChanged;
  final VoidCallback? onUploadStart;
  final VoidCallback? onUploadComplete;

  const AttachmentUploader({
    super.key,
    required this.taskId,
    this.taskAssigneeId,
    required this.permissionService,
    required this.repository,
    this.existingAttachments = const [],
    required this.onAttachmentsChanged,
    this.onUploadStart,
    this.onUploadComplete,
  });

  @override
  State<AttachmentUploader> createState() => _AttachmentUploaderState();
}

class _AttachmentUploaderState extends State<AttachmentUploader> {
  bool _isUploading = false;
  double _uploadProgress = 0;
  String? _uploadStatus;

  bool get _canUpload {
    return widget.permissionService.canUploadAttachment(widget.taskAssigneeId);
  }

  Future<void> _pickAndUploadFile() async {
    if (!_canUpload) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('您没有权限上传附件')),
      );
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        withData: true,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.bytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('读取文件失败')),
        );
        return;
      }

      await _uploadFile(file.name, file.bytes!, file.extension ?? '');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('选择文件失败: $e')),
      );
    }
  }

  Future<void> _uploadFile(String fileName, Uint8List fileBytes, String extension) async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
      _uploadStatus = '准备上传...';
    });

    widget.onUploadStart?.call();

    try {
      // 1. 获取文件类型
      final fileType = _getMimeType(fileName);

      // 2. 获取上传URL
      setState(() => _uploadStatus = '获取上传链接...');
      final uploadUrlResponse = await widget.repository.getUploadUrl(
        widget.taskId,
        UploadAttachmentRequest(
          fileName: fileName,
          fileType: fileType,
          fileSize: fileBytes.length,
        ),
      );

      // 3. 上传文件到存储
      setState(() => _uploadProgress = 0.3);
      await widget.repository.uploadFileToStorage(
        uploadUrlResponse.uploadUrl,
        fileBytes.toList(),
        fileType,
      );

      // 4. 确认上传
      setState(() {
        _uploadProgress = 0.8;
        _uploadStatus = '确认上传...';
      });
      final attachment = await widget.repository.confirmUpload(
        widget.taskId,
        ConfirmAttachmentRequest(
          fileKey: uploadUrlResponse.fileKey,
          fileName: fileName,
          fileType: fileType,
          fileSize: fileBytes.length,
        ),
      );

      // 5. 更新附件列表
      setState(() => _uploadProgress = 1.0);
      final updatedAttachments = [...widget.existingAttachments, attachment];
      widget.onAttachmentsChanged(updatedAttachments);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('附件上传成功')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('上传失败: $e')),
        );
      }
    } finally {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0;
        _uploadStatus = null;
      });
      widget.onUploadComplete?.call();
    }
  }

  String _getMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'txt':
        return 'text/plain';
      case 'zip':
        return 'application/zip';
      case 'rar':
        return 'application/x-rar-compressed';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> _deleteAttachment(Attachment attachment) async {
    final canDelete = widget.permissionService.canDeleteAttachment(attachment.uploadedBy);
    if (!canDelete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('您没有权限删除此附件')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除附件 "${attachment.fileName}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await widget.repository.deleteAttachment(attachment.id);
      final updatedAttachments = widget.existingAttachments
          .where((a) => a.id != attachment.id)
          .toList();
      widget.onAttachmentsChanged(updatedAttachments);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('附件已删除')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: $e')),
        );
      }
    }
  }

  Future<void> _downloadAttachment(Attachment attachment) async {
    if (!widget.permissionService.canDownloadAttachment) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('您没有权限下载附件')),
      );
      return;
    }

    try {
      // TODO: 实现下载逻辑
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('开始下载...')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('下载失败: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 上传按钮
        if (_canUpload)
          InkWell(
            onTap: _isUploading ? null : _pickAndUploadFile,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.attach_file,
                    size: 20,
                    color: _isUploading ? AppColors.textDisabled : AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isUploading ? (_uploadStatus ?? '上传中...') : '添加附件',
                    style: AppTypography.bodySmall.copyWith(
                      color: _isUploading ? AppColors.textDisabled : AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // 上传进度
        if (_isUploading) ...[
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: _uploadProgress,
            backgroundColor: AppColors.divider,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ],

        // 附件列表
        if (widget.existingAttachments.isNotEmpty) ...[
          const SizedBox(height: 16),
          ...widget.existingAttachments.map((attachment) => _buildAttachmentItem(attachment)),
        ],
      ],
    );
  }

  Widget _buildAttachmentItem(Attachment attachment) {
    final canDelete = widget.permissionService.canDeleteAttachment(attachment.uploadedBy);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          // 文件图标
          _buildFileIcon(attachment),
          const SizedBox(width: 12),
          // 文件信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.fileName,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${attachment.fileSizeDisplay} · ${attachment.uploadedByName}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // 操作按钮
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _downloadAttachment(attachment),
                icon: const Icon(Icons.download, size: 18),
                color: AppColors.textSecondary,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              if (canDelete)
                IconButton(
                  onPressed: () => _deleteAttachment(attachment),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  color: AppColors.error,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFileIcon(Attachment attachment) {
    IconData iconData;
    Color color;

    switch (attachment.fileIcon) {
      case 'image':
        iconData = Icons.image;
        color = Colors.blue;
        break;
      case 'pdf':
        iconData = Icons.picture_as_pdf;
        color = Colors.red;
        break;
      case 'word':
        iconData = Icons.description;
        color = Colors.blue.shade700;
        break;
      case 'excel':
        iconData = Icons.table_chart;
        color = Colors.green;
        break;
      case 'ppt':
        iconData = Icons.slideshow;
        color = Colors.orange;
        break;
      case 'archive':
        iconData = Icons.folder_zip;
        color = Colors.amber;
        break;
      case 'text':
        iconData = Icons.text_snippet;
        color = Colors.grey;
        break;
      default:
        iconData = Icons.insert_drive_file;
        color = AppColors.textSecondary;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(iconData, color: color, size: 20),
    );
  }
}

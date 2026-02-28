import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../config/theme.dart';
import '../../domain/entities/document.dart';

/// 文档卡片组件
class DocumentCard extends StatelessWidget {
  final Document document;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onMoreTap;

  const DocumentCard({
    super.key,
    required this.document,
    this.isSelected = false,
    this.onTap,
    this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? AppShadows.card : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 左侧：文件图标
            _buildIcon(),
            // 右侧：内容区域
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: _getFileColor().withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Center(
          child: Icon(
            _getFileIcon(),
            size: 28,
            color: _getFileColor(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 10, 8, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题行（包含标题和更多按钮）
          Row(
            children: [
              Expanded(
                child: Text(
                  document.title,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onMoreTap != null)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onMoreTap,
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(
                      Icons.more_vert,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          // 文件类型
          Text(
            document.typeDisplayName,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 6),
          // 底部信息行：上传者 + 状态 + 大小
          Row(
            children: [
              // 上传者头像
              _buildUploaderAvatar(document.uploader),
              const SizedBox(width: 4),
              // 上传者名字
              Expanded(
                child: Text(
                  document.uploader.name,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // 状态标签
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: _getStatusColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  document.statusDisplayName,
                  style: AppTypography.caption.copyWith(
                    color: _getStatusColor(),
                    fontSize: 9,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // 文件大小
              Text(
                document.formattedFileSize,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textDisabled,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon() {
    switch (document.type) {
      case DocumentType.markdown:
        return Icons.description_outlined;
      case DocumentType.word:
        return Icons.description;
      case DocumentType.excel:
        return Icons.table_chart_outlined;
      case DocumentType.powerpoint:
        return Icons.slideshow_outlined;
      case DocumentType.pdf:
        return Icons.picture_as_pdf_outlined;
      case DocumentType.image:
        return Icons.image_outlined;
      case DocumentType.other:
        return Icons.insert_drive_file_outlined;
    }
  }

  Color _getFileColor() {
    switch (document.type) {
      case DocumentType.markdown:
        return const Color(0xFF1976D2);
      case DocumentType.word:
        return const Color(0xFF2B579A);
      case DocumentType.excel:
        return const Color(0xFF217346);
      case DocumentType.powerpoint:
        return const Color(0xFFD24726);
      case DocumentType.pdf:
        return const Color(0xFFF40F02);
      case DocumentType.image:
        return const Color(0xFFFF9800);
      case DocumentType.other:
        return AppColors.textSecondary;
    }
  }

  Color _getStatusColor() {
    switch (document.status) {
      case DocumentStatus.editable:
        return AppColors.success;
      case DocumentStatus.previewOnly:
        return AppColors.primary;
      case DocumentStatus.archived:
        return AppColors.textDisabled;
      case DocumentStatus.approved:
        return AppColors.warning;
    }
  }

  /// 构建上传者头像
  Widget _buildUploaderAvatar(Uploader uploader) {
    final hasAvatar = uploader.avatar != null && uploader.avatar!.trim().isNotEmpty;
    final initial = uploader.name.isNotEmpty ? uploader.name[0].toUpperCase() : '?';

    return CircleAvatar(
      radius: 9,
      backgroundColor: AppColors.primaryLight,
      backgroundImage: hasAvatar ? NetworkImage(uploader.avatar!) : null,
      child: hasAvatar
          ? null
          : Text(
              initial,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}

/// 文档列表项组件
class DocumentListItem extends StatelessWidget {
  final Document document;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onMoreTap;

  const DocumentListItem({
    super.key,
    required this.document,
    this.isSelected = false,
    this.onTap,
    this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : null,
          border: Border(
            bottom: BorderSide(
              color: AppColors.border,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // 文件图标
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getFileColor().withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Center(
                child: Icon(
                  _getFileIcon(),
                  size: 20,
                  color: _getFileColor(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 文件名和类型
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.title,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${document.typeDisplayName} · ${document.formattedFileSize}',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // 上传者
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      document.uploader.name.isNotEmpty
                          ? document.uploader.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      document.uploader.name,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // 更新时间
            SizedBox(
              width: 80,
              child: Text(
                _formatTime(document.updatedAt),
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            // 状态
            SizedBox(
              width: 70,
              child: _buildStatusBadge(),
            ),
            // 更多按钮
            if (onMoreTap != null)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onMoreTap,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.more_vert,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color color;
    switch (document.status) {
      case DocumentStatus.editable:
        color = AppColors.success;
        break;
      case DocumentStatus.previewOnly:
        color = AppColors.primary;
        break;
      case DocumentStatus.archived:
        color = AppColors.textDisabled;
        break;
      case DocumentStatus.approved:
        color = AppColors.warning;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        document.statusDisplayName,
        style: AppTypography.caption.copyWith(
          color: color,
          fontSize: 11,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  IconData _getFileIcon() {
    switch (document.type) {
      case DocumentType.markdown:
        return Icons.description_outlined;
      case DocumentType.word:
        return Icons.description;
      case DocumentType.excel:
        return Icons.table_chart_outlined;
      case DocumentType.powerpoint:
        return Icons.slideshow_outlined;
      case DocumentType.pdf:
        return Icons.picture_as_pdf_outlined;
      case DocumentType.image:
        return Icons.image_outlined;
      case DocumentType.other:
        return Icons.insert_drive_file_outlined;
    }
  }

  Color _getFileColor() {
    switch (document.type) {
      case DocumentType.markdown:
        return const Color(0xFF1976D2);
      case DocumentType.word:
        return const Color(0xFF2B579A);
      case DocumentType.excel:
        return const Color(0xFF217346);
      case DocumentType.powerpoint:
        return const Color(0xFFD24726);
      case DocumentType.pdf:
        return const Color(0xFFF40F02);
      case DocumentType.image:
        return const Color(0xFFFF9800);
      case DocumentType.other:
        return AppColors.textSecondary;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays < 1) {
      return '今天';
    } else if (diff.inDays < 2) {
      return '昨天';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}天前';
    } else {
      return DateFormat('MM-dd').format(time);
    }
  }
}

/// 文档操作菜单
class DocumentActionMenu extends StatelessWidget {
  final Document document;
  final VoidCallback? onEdit;
  final VoidCallback? onDownload;
  final VoidCallback? onMove;
  final VoidCallback? onDelete;

  const DocumentActionMenu({
    super.key,
    required this.document,
    this.onEdit,
    this.onDownload,
    this.onMove,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 30),
      itemBuilder: (context) => [
        if (document.isEditable)
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit_outlined, size: 18),
                SizedBox(width: 8),
                Text('编辑'),
              ],
            ),
          ),
        const PopupMenuItem(
          value: 'download',
          child: Row(
            children: [
              Icon(Icons.download_outlined, size: 18),
              SizedBox(width: 8),
              Text('下载'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'move',
          child: Row(
            children: [
              Icon(Icons.drive_file_move_outlined, size: 18),
              SizedBox(width: 8),
              Text('移动到'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
              const SizedBox(width: 8),
              Text('删除', style: TextStyle(color: AppColors.error)),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'edit':
            onEdit?.call();
            break;
          case 'download':
            onDownload?.call();
            break;
          case 'move':
            onMove?.call();
            break;
          case 'delete':
            _showDeleteConfirm(context);
            break;
        }
      },
    );
  }

  void _showDeleteConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('删除文档', style: AppTypography.h4),
        content: Text('确定要删除"${document.title}"吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              onDelete?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textInverse,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

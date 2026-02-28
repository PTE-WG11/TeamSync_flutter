import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/theme.dart';
import '../../domain/entities/document.dart';
import '../../domain/repositories/document_repository.dart';
import 'comment_section.dart';
import 'markdown_preview.dart';

/// 预览面板组件
class PreviewPanel extends StatelessWidget {
  final Document document;
  final bool isLoading;
  final VoidCallback? onClose;
  final VoidCallback? onEdit;
  final VoidCallback? onDownload;

  const PreviewPanel({
    super.key,
    required this.document,
    this.isLoading = false,
    this.onClose,
    this.onEdit,
    this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // width: 600, // 原始宽度
      width: 820, // 增加文件夹栏的宽度 (600 + 220)
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          left: BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        children: [
          // 顶部工具栏
          _buildHeader(context),
          // 分割线
          const Divider(height: 1),
          // 内容区域
          Expanded(
            child: isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(strokeWidth: 2),
                        SizedBox(height: 16),
                        Text(
                          '加载中...',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : _buildContent(context),
          ),
          // 分割线
          const Divider(height: 1),
          // 评论区
          SizedBox(
            height: 280,
            child: CommentSection(documentId: document.id),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // 编辑按钮（仅Markdown可编辑）
          if (document.isEditable)
            _buildActionButton(
              icon: Icons.edit_outlined,
              label: '编辑',
              onTap: isLoading ? null : onEdit,
            ),
          if (document.isEditable)
            const SizedBox(width: 8),
          // 下载按钮
          _buildActionButton(
            icon: Icons.download_outlined,
            label: '下载',
            onTap: isLoading ? null : onDownload,
          ),
          const SizedBox(width: 8),
          // 分享按钮
          _buildActionButton(
            icon: Icons.share_outlined,
            label: '分享',
            onTap: () {
              _showShareDialog(context);
            },
          ),
          const Spacer(),
          // 关闭按钮
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 文件预览区
          _buildPreviewArea(context),
          const SizedBox(height: 20),
          // 文件信息
          _buildFileInfo(),
        ],
      ),
    );
  }

  Widget _buildPreviewArea(BuildContext context) {
    switch (document.type) {
      case DocumentType.markdown:
        return MarkdownPreview(content: document.content ?? '');
      case DocumentType.image:
        return _buildImagePreview(context);
      case DocumentType.pdf:
        return _buildPdfPreview();
      default:
        return _buildUnsupportedPreview();
    }
  }

  Widget _buildImagePreview(BuildContext context) {
    debugPrint('[PreviewPanel] 图片预览 - document.id: ${document.id}');
    debugPrint('[PreviewPanel] 图片预览 - fileUrl: "${document.fileUrl}"');
    debugPrint('[PreviewPanel] 图片预览 - downloadUrl: "${document.downloadUrl}"');
    
    // 如果 fileUrl 不为空，直接使用
    if (document.fileUrl.isNotEmpty) {
      debugPrint('[PreviewPanel] 使用 fileUrl 加载图片');
      return _buildImageWidget(document.fileUrl);
    }
    
    // 如果 downloadUrl 不为空，使用它
    if (document.downloadUrl.isNotEmpty) {
      debugPrint('[PreviewPanel] 使用 downloadUrl 加载图片');
      return _buildImageWidget(document.downloadUrl);
    }
    
    // 否则通过接口获取下载链接
    debugPrint('[PreviewPanel] 通过接口获取图片下载链接');
    return FutureBuilder<String>(
      future: context.read<DocumentRepository>().getDownloadUrl(document.id, inline: true),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        
        if (snapshot.hasError) {
          debugPrint('[PreviewPanel] 获取下载链接失败: ${snapshot.error}');
          return _buildImageErrorWidget('获取图片链接失败: ${snapshot.error}');
        }
        
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          debugPrint('[PreviewPanel] 下载链接为空');
          return _buildImageErrorWidget('图片链接为空');
        }
        
        return _buildImageWidget(snapshot.data!);
      },
    );
  }
  
  Widget _buildImageErrorWidget(String message) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image_outlined,
              size: 48,
              color: AppColors.textDisabled,
            ),
            const SizedBox(height: 8),
            Text(
              '图片加载失败',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: AppTypography.caption.copyWith(
                color: AppColors.textDisabled,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildImageWidget(String imageUrl) {
    // 调试日志
    debugPrint('[PreviewPanel] 加载图片: $imageUrl');
    
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Image.network(
          imageUrl,
          fit: BoxFit.contain,
          // 添加跨域支持（Web 需要）
          headers: const {
            'Access-Control-Allow-Origin': '*',
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            debugPrint('[PreviewPanel] 图片加载失败: $error');
            debugPrint('[PreviewPanel] URL: $imageUrl');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.broken_image_outlined,
                    size: 48,
                    color: AppColors.textDisabled,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '图片加载失败',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '请检查网络或CORS配置',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textDisabled,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPdfPreview() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.picture_as_pdf,
            size: 64,
            color: const Color(0xFFF40F02).withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'PDF文档',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onDownload,
            icon: const Icon(Icons.download, size: 18),
            label: const Text('下载查看'),
          ),
        ],
      ),
    );
  }

  Widget _buildUnsupportedPreview() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insert_drive_file_outlined,
            size: 64,
            color: AppColors.textDisabled,
          ),
          const SizedBox(height: 16),
          Text(
            document.typeDisplayName,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '暂不支持在线预览',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textDisabled,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onDownload,
            icon: const Icon(Icons.download, size: 18),
            label: const Text('下载查看'),
          ),
        ],
      ),
    );
  }

  Widget _buildFileInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            document.title,
            style: AppTypography.h4,
          ),
          const SizedBox(height: 12),
          _buildInfoRow('文件类型', document.typeDisplayName),
          _buildInfoRow('文件大小', document.formattedFileSize),
          _buildInfoRow('版本', document.version),
          _buildInfoRow('创建时间', _formatDateTime(document.createdAt)),
          _buildInfoRow('修改时间', _formatDateTime(document.updatedAt)),
          const SizedBox(height: 12),
          // 操作按钮
          Row(
            children: [
              if (document.isPreviewable)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: 全屏预览
                    },
                    icon: const Icon(Icons.fullscreen, size: 18),
                    label: const Text('全屏查看'),
                  ),
                ),
              if (document.isPreviewable)
                const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onDownload,
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('下载原文件'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textInverse,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  void _showShareDialog(BuildContext context) {
    final shareUrl = 'https://teamsync.com/docs/${document.id}';
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('分享文档', style: AppTypography.h4),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '复制下方链接分享给团队成员',
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      shareUrl,
                      style: AppTypography.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: shareUrl));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('链接已复制')),
                      );
                    },
                    child: const Text('复制'),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime time) {
    return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} '
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

/// Markdown编辑器
class MarkdownEditor extends StatefulWidget {
  final String initialContent;
  final String title;
  final bool isNewDocument;
  final String? folderName;
  final void Function(String title, String content)? onSave;
  final VoidCallback? onCancel;

  const MarkdownEditor({
    super.key,
    required this.initialContent,
    required this.title,
    this.isNewDocument = false,
    this.folderName,
    this.onSave,
    this.onCancel,
  });

  @override
  State<MarkdownEditor> createState() => _MarkdownEditorState();
}

class _MarkdownEditorState extends State<MarkdownEditor> {
  late final TextEditingController _contentController;
  late final TextEditingController _titleController;
  bool _isPreview = false;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.initialContent);
    _titleController = TextEditingController(text: widget.isNewDocument ? '' : widget.title);
  }

  @override
  void dispose() {
    _contentController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 600,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Column(
          children: [
            // 标题栏
            _buildHeader(),
            const Divider(height: 1),
            // 工具栏
            _buildToolbar(),
            const Divider(height: 1),
            // 编辑器/预览区
            Expanded(
              child: _isPreview
                  ? MarkdownPreview(content: _contentController.text)
                  : _buildEditor(),
            ),
            const Divider(height: 1),
            // 底部按钮
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.isNewDocument ? '新建 Markdown 文档' : '编辑: ${widget.title}',
                  style: AppTypography.h4,
                ),
              ),
              IconButton(
                onPressed: widget.onCancel,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          if (widget.isNewDocument) ...[
            const SizedBox(height: 12),
            // 标题输入框
            TextField(
              controller: _titleController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '请输入文档标题',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                isDense: true,
              ),
              style: AppTypography.body,
            ),
            // 文件夹信息
            if (widget.folderName != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.folder,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '将保存到: ${widget.folderName}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _buildToolButton(Icons.format_bold, '加粗', () => _insertText('**', '**')),
          _buildToolButton(Icons.format_italic, '斜体', () => _insertText('*', '*')),
          _buildToolButton(Icons.format_list_bulleted, '列表', () => _insertText('\n- ', '')),
          _buildToolButton(Icons.format_list_numbered, '有序列表', () => _insertText('\n1. ', '')),
          _buildToolButton(Icons.code, '代码', () => _insertText('```\n', '\n```')),
          _buildToolButton(Icons.link, '链接', () => _insertText('[', '](url)')),
          const Spacer(),
          // 预览切换
          TextButton.icon(
            onPressed: () {
              setState(() {
                _isPreview = !_isPreview;
              });
            },
            icon: Icon(_isPreview ? Icons.edit : Icons.preview),
            label: Text(_isPreview ? '编辑' : '预览'),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton(IconData icon, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 20, color: AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _buildEditor() {
    return TextField(
      controller: _contentController,
      maxLines: null,
      expands: true,
      decoration: InputDecoration(
        hintText: '在此输入 Markdown 内容...',
        border: InputBorder.none,
        contentPadding: const EdgeInsets.all(16),
        hintStyle: AppTypography.body.copyWith(
          color: AppColors.textDisabled,
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: widget.onCancel,
            child: const Text('取消'),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () {
              final title = widget.isNewDocument 
                  ? _titleController.text.trim() 
                  : widget.title;
              if (title.isNotEmpty) {
                widget.onSave?.call(title, _contentController.text);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textInverse,
            ),
            child: Text(widget.isNewDocument ? '创建' : '保存'),
          ),
        ],
      ),
    );
  }

  void _insertText(String before, String after) {
    final text = _contentController.text;
    final selection = _contentController.selection;
    final selectedText = selection.textInside(text);
    
    final newText = text.replaceRange(
      selection.start,
      selection.end,
      '$before$selectedText$after',
    );
    
    _contentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selection.start + before.length + selectedText.length,
      ),
    );
  }
}

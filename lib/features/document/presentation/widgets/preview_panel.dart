import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../config/theme.dart';
import '../../domain/entities/document.dart';
import 'comment_section.dart';
import 'markdown_preview.dart';

/// 预览面板组件
class PreviewPanel extends StatelessWidget {
  final Document document;
  final VoidCallback? onClose;
  final VoidCallback? onEdit;
  final VoidCallback? onDownload;

  const PreviewPanel({
    super.key,
    required this.document,
    this.onClose,
    this.onEdit,
    this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 420,
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
            child: _buildContent(),
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
              onTap: onEdit,
            ),
          if (document.isEditable)
            const SizedBox(width: 8),
          // 下载按钮
          _buildActionButton(
            icon: Icons.download_outlined,
            label: '下载',
            onTap: onDownload,
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

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 文件预览区
          _buildPreviewArea(),
          const SizedBox(height: 20),
          // 文件信息
          _buildFileInfo(),
        ],
      ),
    );
  }

  Widget _buildPreviewArea() {
    switch (document.type) {
      case DocumentType.markdown:
        return MarkdownPreview(content: document.content ?? '');
      case DocumentType.image:
        return _buildImagePreview();
      case DocumentType.pdf:
        return _buildPdfPreview();
      default:
        return _buildUnsupportedPreview();
    }
  }

  Widget _buildImagePreview() {
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
          document.fileUrl,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
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
  final ValueChanged<String>? onSave;
  final VoidCallback? onCancel;

  const MarkdownEditor({
    super.key,
    required this.initialContent,
    required this.title,
    this.onSave,
    this.onCancel,
  });

  @override
  State<MarkdownEditor> createState() => _MarkdownEditorState();
}

class _MarkdownEditorState extends State<MarkdownEditor> {
  late final TextEditingController _controller;
  bool _isPreview = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialContent);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
                ? MarkdownPreview(content: _controller.text)
                : _buildEditor(),
          ),
          const Divider(height: 1),
          // 底部按钮
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Text('编辑: ${widget.title}', style: AppTypography.h4),
          const Spacer(),
          IconButton(
            onPressed: widget.onCancel,
            icon: const Icon(Icons.close),
          ),
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 20, color: AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _buildEditor() {
    return TextField(
      controller: _controller,
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
              widget.onSave?.call(_controller.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textInverse,
            ),
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _insertText(String before, String after) {
    final text = _controller.text;
    final selection = _controller.selection;
    final selectedText = selection.textInside(text);
    
    final newText = text.replaceRange(
      selection.start,
      selection.end,
      '$before$selectedText$after',
    );
    
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selection.start + before.length + selectedText.length,
      ),
    );
  }
}

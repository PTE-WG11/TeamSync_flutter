import 'package:flutter/material.dart';

import '../../../../config/theme.dart';

/// Markdown预览组件
class MarkdownPreview extends StatelessWidget {
  final String content;

  const MarkdownPreview({
    super.key,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    // 简单渲染Markdown
    // 生产环境建议使用 flutter_markdown 包
    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: _buildMarkdownContent(),
      ),
    );
  }

  Widget _buildMarkdownContent() {
    // 简单的Markdown解析渲染
    final lines = content.split('\n');
    final widgets = <Widget>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final widget = _parseLine(line);
      if (widget != null) {
        widgets.add(widget);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget? _parseLine(String line) {
    final trimmed = line.trim();
    
    if (trimmed.isEmpty) {
      return const SizedBox(height: 8);
    }

    // 标题
    if (trimmed.startsWith('# ')) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          trimmed.substring(2),
          style: AppTypography.h3,
        ),
      );
    }
    if (trimmed.startsWith('## ')) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          trimmed.substring(3),
          style: AppTypography.h4,
        ),
      );
    }
    if (trimmed.startsWith('### ')) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          trimmed.substring(4),
          style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
        ),
      );
    }

    // 代码块
    if (trimmed.startsWith('```')) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Text(
          trimmed.replaceAll('```', ''),
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      );
    }

    // 行内代码
    if (trimmed.contains('`')) {
      return _buildParagraphWithInlineCode(trimmed);
    }

    // 列表项
    if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
      return Padding(
        padding: const EdgeInsets.only(left: 16, bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(top: 8),
              decoration: const BoxDecoration(
                color: AppColors.textSecondary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildRichText(trimmed.substring(2)),
            ),
          ],
        ),
      );
    }

    // 表格分隔线
    if (trimmed.startsWith('|') && trimmed.contains('---')) {
      return const Divider(height: 16);
    }

    // 表格行
    if (trimmed.startsWith('|')) {
      return _buildTableRow(trimmed);
    }

    // 普通段落
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: _buildRichText(trimmed),
    );
  }

  Widget _buildParagraphWithInlineCode(String text) {
    final parts = text.split('`');
    final spans = <InlineSpan>[];

    for (int i = 0; i < parts.length; i++) {
      if (i % 2 == 0) {
        // 普通文本
        spans.add(TextSpan(
          text: parts[i],
          style: AppTypography.body.copyWith(
            color: AppColors.textSecondary,
          ),
        ));
      } else {
        // 代码
        spans.add(WidgetSpan(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              parts[i],
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: AppColors.primary,
              ),
            ),
          ),
        ));
      }
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  Widget _buildRichText(String text) {
    // 处理粗体和链接
    final spans = <InlineSpan>[];
    var currentText = text;

    // 简单的粗体处理 **text**
    final boldRegex = RegExp(r'\*\*(.*?)\*\*');
    var lastIndex = 0;

    for (final match in boldRegex.allMatches(currentText)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: currentText.substring(lastIndex, match.start),
          style: AppTypography.body.copyWith(
            color: AppColors.textSecondary,
          ),
        ));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: AppTypography.body.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ));
      lastIndex = match.end;
    }

    if (lastIndex < currentText.length) {
      spans.add(TextSpan(
        text: currentText.substring(lastIndex),
        style: AppTypography.body.copyWith(
          color: AppColors.textSecondary,
        ),
      ));
    }

    if (spans.isEmpty) {
      spans.add(TextSpan(
        text: text,
        style: AppTypography.body.copyWith(
          color: AppColors.textSecondary,
        ),
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  Widget _buildTableRow(String line) {
    final cells = line.split('|')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: cells.map((cell) {
          return Expanded(
            child: Text(
              cell,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

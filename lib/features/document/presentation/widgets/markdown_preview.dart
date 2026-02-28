import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../config/theme.dart';

/// Markdown预览组件
class MarkdownPreview extends StatelessWidget {
  final String content;
  final ScrollController? controller;

  const MarkdownPreview({
    super.key,
    required this.content,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Markdown(
        data: content,
        controller: controller,
        selectable: true,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        onTapLink: (text, href, title) {
          if (href != null) {
            _launchUrl(href);
          }
        },
        styleSheet: MarkdownStyleSheet(
          // 标题样式
          h1: AppTypography.h1,
          h2: AppTypography.h2,
          h3: AppTypography.h3,
          h4: AppTypography.h4,
          h5: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
          h6: AppTypography.body.copyWith(fontWeight: FontWeight.bold),
          
          // 正文样式
          p: AppTypography.body.copyWith(color: AppColors.textPrimary),
          strong: const TextStyle(fontWeight: FontWeight.bold),
          em: const TextStyle(fontStyle: FontStyle.italic),
          
          // 代码样式
          code: const TextStyle(
            fontFamily: 'monospace',
            backgroundColor: AppColors.background,
            color: AppColors.primary,
            fontSize: 13,
          ),
          codeblockPadding: const EdgeInsets.all(16),
          codeblockDecoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          
          // 引用样式
          blockquote: AppTypography.body.copyWith(color: AppColors.textSecondary),
          blockquoteDecoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: const Border(
              left: BorderSide(color: AppColors.primary, width: 4),
            ),
          ),
          blockquotePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          
          // 列表样式
          listBullet: const TextStyle(color: AppColors.textSecondary),
          
          // 表格样式
          tableHead: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold),
          tableBody: AppTypography.bodySmall,
          tableBorder: TableBorder.all(color: AppColors.border),
          tableCellsPadding: const EdgeInsets.all(8),
          
          // 分隔线
          horizontalRuleDecoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: AppColors.divider),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

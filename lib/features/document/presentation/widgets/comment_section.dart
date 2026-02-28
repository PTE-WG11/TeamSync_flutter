import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../config/theme.dart';
import '../../domain/entities/document_comment.dart';
import '../bloc/comment_bloc.dart';

/// 评论区组件
class CommentSection extends StatelessWidget {
  final String documentId;

  const CommentSection({
    super.key,
    required this.documentId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CommentBloc(
        repository: context.read(),
      )..add(CommentsLoadRequested(documentId: documentId)),
      child: const _CommentSectionView(),
    );
  }
}

class _CommentSectionView extends StatefulWidget {
  const _CommentSectionView();

  @override
  State<_CommentSectionView> createState() => _CommentSectionViewState();
}

class _CommentSectionViewState extends State<_CommentSectionView> {
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 标题栏
        _buildHeader(),
        const Divider(height: 1),
        // 评论列表
        Expanded(
          child: _buildCommentList(),
        ),
        const Divider(height: 1),
        // 输入框
        _buildInputArea(),
      ],
    );
  }

  Widget _buildHeader() {
    return BlocBuilder<CommentBloc, CommentState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                '文档评论',
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${state.comments.length}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              if (state.comments.length > 3)
                TextButton(
                  onPressed: () {
                    _showAllComments(context);
                  },
                  child: const Text('查看全部'),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommentList() {
    return BlocBuilder<CommentBloc, CommentState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        if (state.comments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 48,
                  color: AppColors.textDisabled,
                ),
                const SizedBox(height: 12),
                Text(
                  '暂无评论',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '第一个发表评论吧',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textDisabled,
                  ),
                ),
              ],
            ),
          );
        }

        // 只显示最近3条
        final displayComments = state.comments.length > 3
            ? state.comments.sublist(0, 3)
            : state.comments;

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: displayComments.length,
          itemBuilder: (context, index) {
            return _CommentItem(
              comment: displayComments[index],
              onDelete: () {
                context.read<CommentBloc>().add(
                  CommentDeleteRequested(displayComments[index].id),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildInputArea() {
    return BlocBuilder<CommentBloc, CommentState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  maxLines: 2,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: '添加评论...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: state.isSubmitting
                    ? null
                    : () {
                        final content = _textController.text.trim();
                        if (content.isNotEmpty) {
                          context.read<CommentBloc>().add(
                            CommentCreateRequested(content: content),
                          );
                          _textController.clear();
                        }
                      },
                icon: state.isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                color: AppColors.primary,
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAllComments(BuildContext context) {
    final state = context.read<CommentBloc>().state;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (dialogContext) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // 拖动指示器
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // 标题
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text('全部评论', style: AppTypography.h4),
                      const SizedBox(width: 8),
                      Text(
                        '(${state.comments.length})',
                        style: AppTypography.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // 评论列表
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: state.comments.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _CommentItem(
                          comment: state.comments[index],
                          onDelete: () {
                            context.read<CommentBloc>().add(
                              CommentDeleteRequested(state.comments[index].id),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// 评论项组件
class _CommentItem extends StatelessWidget {
  final DocumentComment comment;
  final VoidCallback? onDelete;

  const _CommentItem({
    required this.comment,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头像
          _buildAuthorAvatar(comment.author),
          const SizedBox(width: 12),
          // 评论内容
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.author.name,
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatTime(comment.createdAt),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textDisabled,
                      ),
                    ),
                    // 删除按钮（仅自己的评论）
                    if (onDelete != null)
                      PopupMenuButton<String>(
                        offset: const Offset(0, 20),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: AppColors.error,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '删除',
                                  style: TextStyle(color: AppColors.error),
                                ),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'delete') {
                            onDelete?.call();
                          }
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.content,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return '刚刚';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}分钟前';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}小时前';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}天前';
    } else {
      return DateFormat('MM-dd HH:mm').format(time);
    }
  }

  /// 构建评论作者头像
  Widget _buildAuthorAvatar(CommentAuthor author) {
    final hasAvatar = author.avatar != null && author.avatar!.trim().isNotEmpty;
    final initial = author.name.isNotEmpty ? author.name[0].toUpperCase() : '?';

    return CircleAvatar(
      radius: 16,
      backgroundColor: AppColors.primaryLight,
      backgroundImage: hasAvatar ? NetworkImage(author.avatar!) : null,
      child: hasAvatar
          ? null
          : Text(
              initial,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}

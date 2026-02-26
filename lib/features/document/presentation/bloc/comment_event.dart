part of 'comment_bloc.dart';

abstract class CommentEvent extends Equatable {
  const CommentEvent();

  @override
  List<Object?> get props => [];
}

/// 加载评论列表
class CommentsLoadRequested extends CommentEvent {
  final String documentId;
  final int page;
  final int pageSize;

  const CommentsLoadRequested({
    required this.documentId,
    this.page = 1,
    this.pageSize = 20,
  });

  @override
  List<Object?> get props => [documentId, page, pageSize];
}

/// 发表评论
class CommentCreateRequested extends CommentEvent {
  final String content;

  const CommentCreateRequested({
    required this.content,
  });

  @override
  List<Object?> get props => [content];
}

/// 删除评论
class CommentDeleteRequested extends CommentEvent {
  final String commentId;

  const CommentDeleteRequested(this.commentId);

  @override
  List<Object?> get props => [commentId];
}

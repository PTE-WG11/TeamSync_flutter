import 'package:equatable/equatable.dart';

/// 评论作者
class CommentAuthor extends Equatable {
  final String id;
  final String name;
  final String? avatar;

  const CommentAuthor({
    required this.id,
    required this.name,
    this.avatar,
  });

  @override
  List<Object?> get props => [id, name, avatar];
}

/// 文档评论
class DocumentComment extends Equatable {
  final String id;
  final String documentId;
  final String content;
  final CommentAuthor author;
  final DateTime createdAt;

  const DocumentComment({
    required this.id,
    required this.documentId,
    required this.content,
    required this.author,
    required this.createdAt,
  });

  DocumentComment copyWith({
    String? id,
    String? documentId,
    String? content,
    CommentAuthor? author,
    DateTime? createdAt,
  }) {
    return DocumentComment(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      content: content ?? this.content,
      author: author ?? this.author,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, documentId, content, author, createdAt];
}

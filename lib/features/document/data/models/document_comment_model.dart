import '../../domain/entities/document_comment.dart';

/// 评论数据模型
class DocumentCommentModel extends DocumentComment {
  const DocumentCommentModel({
    required super.id,
    required super.documentId,
    required super.content,
    required super.author,
    required super.createdAt,
  });

  factory DocumentCommentModel.fromJson(Map<String, dynamic> json) {
    return DocumentCommentModel(
      id: json['id'].toString(),
      documentId: (json['documentId'] ?? json['document_id'] ?? '').toString(),
      content: json['content'] as String,
      author: _parseAuthor(json['author'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['created_at'] ?? json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'document_id': documentId,
      'content': content,
      'author': {
        'id': author.id,
        'name': author.name,
        'avatar': author.avatar,
      },
      'created_at': createdAt.toIso8601String(),
    };
  }

  static CommentAuthor _parseAuthor(Map<String, dynamic> json) {
    return CommentAuthor(
      id: json['id'].toString(),
      name: json['name'] as String,
      avatar: json['avatar'] as String?,
    );
  }

  factory DocumentCommentModel.fromEntity(DocumentComment comment) {
    return DocumentCommentModel(
      id: comment.id,
      documentId: comment.documentId,
      content: comment.content,
      author: comment.author,
      createdAt: comment.createdAt,
    );
  }
}

/// 创建评论请求
class CreateCommentRequest {
  final String content;

  const CreateCommentRequest({
    required this.content,
  });

  Map<String, dynamic> toJson() {
    return {
      'content': content,
    };
  }
}

/// 评论列表响应
class CommentListResponse {
  final List<DocumentCommentModel> list;
  final int currentPage;
  final int totalPages;
  final int totalCount;

  const CommentListResponse({
    required this.list,
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
  });

  factory CommentListResponse.fromJson(Map<String, dynamic> json) {
    final listJson = json['list'] as List<dynamic>;
    return CommentListResponse(
      list: listJson.map((e) => DocumentCommentModel.fromJson(e as Map<String, dynamic>)).toList(),
      currentPage: json['currentPage'] as int? ?? 1,
      totalPages: json['totalPages'] as int? ?? 1,
      totalCount: json['totalCount'] as int? ?? listJson.length,
    );
  }
}

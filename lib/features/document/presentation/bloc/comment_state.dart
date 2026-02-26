part of 'comment_bloc.dart';

/// 评论状态
class CommentState extends Equatable {
  final List<DocumentComment> comments;
  final bool isLoading;
  final bool isSubmitting;
  final bool isDeleting;
  final String? error;
  final String? documentId;

  const CommentState({
    this.comments = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.isDeleting = false,
    this.error,
    this.documentId,
  });

  CommentState copyWith({
    List<DocumentComment>? comments,
    bool? isLoading,
    bool? isSubmitting,
    bool? isDeleting,
    String? error,
    String? documentId,
    bool clearError = false,
  }) {
    return CommentState(
      comments: comments ?? this.comments,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isDeleting: isDeleting ?? this.isDeleting,
      error: clearError ? null : error ?? this.error,
      documentId: documentId ?? this.documentId,
    );
  }

  @override
  List<Object?> get props => [
        comments,
        isLoading,
        isSubmitting,
        isDeleting,
        error,
        documentId,
      ];
}

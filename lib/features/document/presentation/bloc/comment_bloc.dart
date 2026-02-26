import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/document_comment.dart';
import '../../domain/repositories/document_repository.dart';

part 'comment_event.dart';
part 'comment_state.dart';

/// 评论Bloc
class CommentBloc extends Bloc<CommentEvent, CommentState> {
  final DocumentRepository _repository;

  CommentBloc({
    required DocumentRepository repository,
  })  : _repository = repository,
        super(const CommentState()) {
    on<CommentsLoadRequested>(_onLoadComments);
    on<CommentCreateRequested>(_onCreateComment);
    on<CommentDeleteRequested>(_onDeleteComment);
  }

  Future<void> _onLoadComments(
    CommentsLoadRequested event,
    Emitter<CommentState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final comments = await _repository.getComments(
        documentId: event.documentId,
        page: event.page,
        pageSize: event.pageSize,
      );
      emit(state.copyWith(
        isLoading: false,
        comments: comments,
        documentId: event.documentId,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onCreateComment(
    CommentCreateRequested event,
    Emitter<CommentState> emit,
  ) async {
    if (state.documentId == null) return;
    
    emit(state.copyWith(isSubmitting: true, error: null));
    try {
      final comment = await _repository.createComment(
        documentId: state.documentId!,
        content: event.content,
      );
      emit(state.copyWith(
        isSubmitting: false,
        comments: [comment, ...state.comments],
      ));
    } catch (e) {
      emit(state.copyWith(
        isSubmitting: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onDeleteComment(
    CommentDeleteRequested event,
    Emitter<CommentState> emit,
  ) async {
    emit(state.copyWith(isDeleting: true, error: null));
    try {
      await _repository.deleteComment(event.commentId);
      final updatedComments = state.comments
          .where((c) => c.id != event.commentId)
          .toList();
      emit(state.copyWith(
        isDeleting: false,
        comments: updatedComments,
      ));
    } catch (e) {
      emit(state.copyWith(
        isDeleting: false,
        error: e.toString(),
      ));
    }
  }
}

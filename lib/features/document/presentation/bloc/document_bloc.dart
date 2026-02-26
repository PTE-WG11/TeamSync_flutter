import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/document.dart';
import '../../domain/repositories/document_repository.dart';

part 'document_event.dart';
part 'document_state.dart';

// 更新Markdown文档事件（定义在页面文件中，这里导入）
class DocumentUpdateMarkdownRequested extends DocumentEvent {
  final String documentId;
  final String? title;
  final String? content;
  final bool saveAsVersion;
  final String? versionRemark;

  const DocumentUpdateMarkdownRequested({
    required this.documentId,
    this.title,
    this.content,
    this.saveAsVersion = false,
    this.versionRemark,
  });

  @override
  List<Object?> get props => [documentId, title, content, saveAsVersion, versionRemark];
}

/// 文档Bloc
class DocumentBloc extends Bloc<DocumentEvent, DocumentState> {
  final DocumentRepository _repository;
  final String _projectId;

  DocumentBloc({
    required DocumentRepository repository,
    required String projectId,
  })  : _repository = repository,
        _projectId = projectId,
        super(const DocumentState()) {
    on<DocumentsLoadRequested>(_onLoadDocuments);
    on<DocumentSearchRequested>(_onSearchDocuments);
    on<DocumentFilterByFolder>(_onFilterByFolder);
    on<DocumentFilterByType>(_onFilterByType);
    on<DocumentCreateMarkdownRequested>(_onCreateMarkdown);
    on<DocumentUploadRequested>(_onUploadFile);
    on<DocumentUploadFromBytesRequested>(_onUploadFileFromBytes);
    on<DocumentDeleteRequested>(_onDeleteDocument);
    on<DocumentMoveRequested>(_onMoveDocument);
    on<DocumentViewModeChanged>(_onViewModeChanged);
    on<DocumentSelected>(_onDocumentSelected);
    on<DocumentClearSelection>(_onClearSelection);
    on<DocumentUpdateMarkdownRequested>(_onUpdateMarkdown);
  }

  Future<void> _onLoadDocuments(
    DocumentsLoadRequested event,
    Emitter<DocumentState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final documents = await _repository.getDocuments(
        projectId: _projectId,
        folderId: state.selectedFolderId,
        type: state.filterType,
        page: event.page,
        pageSize: event.pageSize,
      );
      emit(state.copyWith(
        isLoading: false,
        documents: documents,
        currentPage: event.page,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onSearchDocuments(
    DocumentSearchRequested event,
    Emitter<DocumentState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null, searchKeyword: event.keyword));
    try {
      final documents = await _repository.searchDocuments(
        projectId: _projectId,
        keyword: event.keyword,
        type: state.filterType,
        page: event.page,
        pageSize: event.pageSize,
      );
      emit(state.copyWith(
        isLoading: false,
        documents: documents,
        currentPage: event.page,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  void _onFilterByFolder(
    DocumentFilterByFolder event,
    Emitter<DocumentState> emit,
  ) {
    emit(state.copyWith(selectedFolderId: event.folderId));
    add(const DocumentsLoadRequested());
  }

  void _onFilterByType(
    DocumentFilterByType event,
    Emitter<DocumentState> emit,
  ) {
    emit(state.copyWith(filterType: event.type));
    add(const DocumentsLoadRequested());
  }

  Future<void> _onCreateMarkdown(
    DocumentCreateMarkdownRequested event,
    Emitter<DocumentState> emit,
  ) async {
    emit(state.copyWith(isCreating: true, error: null));
    try {
      final document = await _repository.createMarkdownDocument(
        projectId: _projectId,
        title: event.title,
        folderId: event.folderId,
        content: event.content,
      );
      emit(state.copyWith(
        isCreating: false,
        documents: [document, ...state.documents],
        lastCreatedDocument: document,
      ));
    } catch (e) {
      emit(state.copyWith(
        isCreating: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onUploadFile(
    DocumentUploadRequested event,
    Emitter<DocumentState> emit,
  ) async {
    emit(state.copyWith(isUploading: true, uploadProgress: 0, error: null));
    try {
      final document = await _repository.uploadFile(
        projectId: _projectId,
        filePath: event.filePath,
        folderId: event.folderId,
        title: event.title,
      );
      emit(state.copyWith(
        isUploading: false,
        uploadProgress: 100,
        documents: [document, ...state.documents],
      ));
    } catch (e) {
      emit(state.copyWith(
        isUploading: false,
        uploadProgress: 0,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onUploadFileFromBytes(
    DocumentUploadFromBytesRequested event,
    Emitter<DocumentState> emit,
  ) async {
    emit(state.copyWith(isUploading: true, uploadProgress: 0, error: null));
    try {
      final document = await _repository.uploadFileFromBytes(
        projectId: _projectId,
        fileBytes: event.fileBytes,
        fileName: event.fileName,
        folderId: event.folderId,
        title: event.title,
      );
      emit(state.copyWith(
        isUploading: false,
        uploadProgress: 100,
        documents: [document, ...state.documents],
      ));
    } catch (e) {
      emit(state.copyWith(
        isUploading: false,
        uploadProgress: 0,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onDeleteDocument(
    DocumentDeleteRequested event,
    Emitter<DocumentState> emit,
  ) async {
    emit(state.copyWith(isDeleting: true, error: null));
    try {
      await _repository.deleteDocument(event.documentId);
      final updatedDocs = state.documents
          .where((d) => d.id != event.documentId)
          .toList();
      emit(state.copyWith(
        isDeleting: false,
        documents: updatedDocs,
        selectedDocumentId: state.selectedDocumentId == event.documentId
            ? null
            : state.selectedDocumentId,
      ));
    } catch (e) {
      emit(state.copyWith(
        isDeleting: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onMoveDocument(
    DocumentMoveRequested event,
    Emitter<DocumentState> emit,
  ) async {
    emit(state.copyWith(isMoving: true, error: null));
    try {
      final document = await _repository.moveDocument(
        documentId: event.documentId,
        folderId: event.folderId,
      );
      final updatedDocs = state.documents.map((d) {
        return d.id == event.documentId ? document : d;
      }).toList();
      emit(state.copyWith(
        isMoving: false,
        documents: updatedDocs,
      ));
    } catch (e) {
      emit(state.copyWith(
        isMoving: false,
        error: e.toString(),
      ));
    }
  }

  void _onViewModeChanged(
    DocumentViewModeChanged event,
    Emitter<DocumentState> emit,
  ) {
    emit(state.copyWith(viewMode: event.viewMode));
  }

  void _onDocumentSelected(
    DocumentSelected event,
    Emitter<DocumentState> emit,
  ) {
    emit(state.copyWith(selectedDocumentId: event.documentId));
  }

  void _onClearSelection(
    DocumentClearSelection event,
    Emitter<DocumentState> emit,
  ) {
    emit(state.copyWith(selectedDocumentId: null));
  }

  Future<void> _onUpdateMarkdown(
    DocumentUpdateMarkdownRequested event,
    Emitter<DocumentState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final document = await _repository.updateMarkdownDocument(
        documentId: event.documentId,
        title: event.title,
        content: event.content,
        saveAsVersion: event.saveAsVersion,
        versionRemark: event.versionRemark,
      );
      final updatedDocs = state.documents.map((d) {
        return d.id == event.documentId ? document : d;
      }).toList();
      emit(state.copyWith(
        isLoading: false,
        documents: updatedDocs,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }
}

part of 'document_bloc.dart';

/// 文档视图模式
enum DocumentViewMode {
  grid,
  list,
}

/// 文档状态
class DocumentState extends Equatable {
  final List<Document> documents;
  final bool isLoading;
  final bool isCreating;
  final bool isUploading;
  final bool isDeleting;
  final bool isMoving;
  final int uploadProgress;
  final String? error;
  
  // 筛选条件
  final String? selectedFolderId;
  final DocumentType? filterType;
  final String? searchKeyword;
  
  // 分页
  final int currentPage;
  final int totalPages;
  
  // 视图状态
  final DocumentViewMode viewMode;
  final String? selectedDocumentId;
  final Document? lastCreatedDocument;
  
  // 选中文档详情（包含完整内容）
  final Document? selectedDocumentDetail;
  final bool isLoadingDetail; // 是否正在加载文档详情

  const DocumentState({
    this.documents = const [],
    this.isLoading = false,
    this.isCreating = false,
    this.isUploading = false,
    this.isDeleting = false,
    this.isMoving = false,
    this.uploadProgress = 0,
    this.error,
    this.selectedFolderId,
    this.filterType,
    this.searchKeyword,
    this.currentPage = 1,
    this.totalPages = 1,
    this.viewMode = DocumentViewMode.list,
    this.selectedDocumentId,
    this.lastCreatedDocument,
    this.selectedDocumentDetail,
    this.isLoadingDetail = false,
  });

  DocumentState copyWith({
    List<Document>? documents,
    bool? isLoading,
    bool? isCreating,
    bool? isUploading,
    bool? isDeleting,
    bool? isMoving,
    int? uploadProgress,
    String? error,
    String? selectedFolderId,
    DocumentType? filterType,
    String? searchKeyword,
    int? currentPage,
    int? totalPages,
    DocumentViewMode? viewMode,
    String? selectedDocumentId,
    Document? lastCreatedDocument,
    Document? selectedDocumentDetail,
    bool? isLoadingDetail,
    bool clearError = false,
    bool clearSelectedFolder = false,
    bool clearFilterType = false,
    bool clearSearchKeyword = false,
    bool clearLastCreated = false,
    bool clearSelectedDocumentDetail = false,
  }) {
    return DocumentState(
      documents: documents ?? this.documents,
      isLoading: isLoading ?? this.isLoading,
      isCreating: isCreating ?? this.isCreating,
      isUploading: isUploading ?? this.isUploading,
      isDeleting: isDeleting ?? this.isDeleting,
      isMoving: isMoving ?? this.isMoving,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      error: clearError ? null : error ?? this.error,
      selectedFolderId: clearSelectedFolder ? null : selectedFolderId ?? this.selectedFolderId,
      filterType: clearFilterType ? null : filterType ?? this.filterType,
      searchKeyword: clearSearchKeyword ? null : searchKeyword ?? this.searchKeyword,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      viewMode: viewMode ?? this.viewMode,
      selectedDocumentId: selectedDocumentId ?? this.selectedDocumentId,
      lastCreatedDocument: clearLastCreated ? null : lastCreatedDocument ?? this.lastCreatedDocument,
      selectedDocumentDetail: clearSelectedDocumentDetail ? null : selectedDocumentDetail ?? this.selectedDocumentDetail,
      isLoadingDetail: isLoadingDetail ?? this.isLoadingDetail ?? false,
    );
  }

  @override
  List<Object?> get props => [
        documents,
        isLoading,
        isCreating,
        isUploading,
        isDeleting,
        isMoving,
        uploadProgress,
        error,
        selectedFolderId,
        filterType,
        searchKeyword,
        currentPage,
        totalPages,
        viewMode,
        selectedDocumentId,
        lastCreatedDocument,
        selectedDocumentDetail,
        isLoadingDetail,
      ];

  /// 获取选中的文档（优先返回详情，详情不存在则返回列表中的基本信息）
  Document? get selectedDocument {
    if (selectedDocumentId == null) return null;
    
    // 优先返回已加载的详情
    if (selectedDocumentDetail != null && 
        selectedDocumentDetail!.id == selectedDocumentId) {
      return selectedDocumentDetail;
    }
    
    // 返回列表中的基本信息
    try {
      return documents.firstWhere(
        (d) => d.id == selectedDocumentId,
      );
    } catch (_) {
      return null;
    }
  }
}

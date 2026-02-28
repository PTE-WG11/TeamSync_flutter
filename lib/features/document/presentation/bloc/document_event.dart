part of 'document_bloc.dart';

abstract class DocumentEvent extends Equatable {
  const DocumentEvent();

  @override
  List<Object?> get props => [];
}

/// 加载文档列表
class DocumentsLoadRequested extends DocumentEvent {
  final int page;
  final int pageSize;

  const DocumentsLoadRequested({
    this.page = 1,
    this.pageSize = 20,
  });

  @override
  List<Object?> get props => [page, pageSize];
}

/// 搜索文档
class DocumentSearchRequested extends DocumentEvent {
  final String keyword;
  final int page;
  final int pageSize;

  const DocumentSearchRequested({
    required this.keyword,
    this.page = 1,
    this.pageSize = 20,
  });

  @override
  List<Object?> get props => [keyword, page, pageSize];
}

/// 按文件夹筛选
class DocumentFilterByFolder extends DocumentEvent {
  final String? folderId;

  const DocumentFilterByFolder(this.folderId);

  @override
  List<Object?> get props => [folderId];
}

/// 按类型筛选
class DocumentFilterByType extends DocumentEvent {
  final DocumentType? type;

  const DocumentFilterByType(this.type);

  @override
  List<Object?> get props => [type];
}

/// 创建Markdown文档
class DocumentCreateMarkdownRequested extends DocumentEvent {
  final String title;
  final String? folderId;
  final String content;

  const DocumentCreateMarkdownRequested({
    required this.title,
    this.folderId,
    this.content = '',
  });

  @override
  List<Object?> get props => [title, folderId, content];
}

/// 上传文件（使用文件路径 - 适用于移动端/桌面端）
class DocumentUploadRequested extends DocumentEvent {
  final String filePath;
  final String? folderId;
  final String? title;

  const DocumentUploadRequested({
    required this.filePath,
    this.folderId,
    this.title,
  });

  @override
  List<Object?> get props => [filePath, folderId, title];
}

/// 上传文件（使用文件字节 - 适用于 Web）
class DocumentUploadFromBytesRequested extends DocumentEvent {
  final List<int> fileBytes;
  final String fileName;
  final String? folderId;
  final String? title;

  const DocumentUploadFromBytesRequested({
    required this.fileBytes,
    required this.fileName,
    this.folderId,
    this.title,
  });

  @override
  List<Object?> get props => [fileBytes, fileName, folderId, title];
}

/// 删除文档
class DocumentDeleteRequested extends DocumentEvent {
  final String documentId;

  const DocumentDeleteRequested(this.documentId);

  @override
  List<Object?> get props => [documentId];
}

/// 移动文档
class DocumentMoveRequested extends DocumentEvent {
  final String documentId;
  final String? folderId;

  const DocumentMoveRequested({
    required this.documentId,
    this.folderId,
  });

  @override
  List<Object?> get props => [documentId, folderId];
}

/// 切换视图模式
class DocumentViewModeChanged extends DocumentEvent {
  final DocumentViewMode viewMode;

  const DocumentViewModeChanged(this.viewMode);

  @override
  List<Object?> get props => [viewMode];
}

/// 选择文档
class DocumentSelected extends DocumentEvent {
  final String documentId;

  const DocumentSelected(this.documentId);

  @override
  List<Object?> get props => [documentId];
}

/// 清除选择
class DocumentClearSelection extends DocumentEvent {
  const DocumentClearSelection();
}

/// 更新Markdown文档
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

import '../../domain/entities/document.dart';

/// 文档数据模型
class DocumentModel extends Document {
  const DocumentModel({
    required super.id,
    required super.projectId,
    super.folderId,
    required super.title,
    required super.type,
    super.status = DocumentStatus.previewOnly,
    required super.fileName,
    required super.fileSize,
    required super.fileUrl,
    required super.downloadUrl,
    super.content,
    super.version = 'v1.0',
    super.versionCount = 1,
    required super.uploader,
    required super.createdAt,
    required super.updatedAt,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    // 后端返回 snake_case 字段，需要映射到 camelCase
    final uploaderJson = json['uploader'] as Map<String, dynamic>?;
    
    return DocumentModel(
      id: json['id'].toString(),  // 后端可能是 int
      projectId: json['project_id']?.toString() ?? json['projectId']?.toString() ?? '',
      folderId: json['folder_id']?.toString(),
      title: json['title'] as String? ?? '',
      type: _parseDocumentType(json['doc_type'] as String? ?? json['type'] as String? ?? 'other'),
      status: _parseDocumentStatus(json['status'] as String? ?? 'readonly'),
      fileName: json['file_name'] as String? ?? json['fileName'] as String? ?? '',
      fileSize: json['file_size'] as int? ?? json['fileSize'] as int? ?? 0,
      fileUrl: json['file_url'] as String? ?? json['fileUrl'] as String? ?? '',
      downloadUrl: json['download_url'] as String? ?? json['downloadUrl'] as String? ?? '',
      content: json['content'] as String?,
      version: json['version'] as String? ?? 'v1.0',
      versionCount: json['version_count'] as int? ?? json['versionCount'] as int? ?? 1,
      uploader: uploaderJson != null 
          ? _parseUploader(uploaderJson)
          : const Uploader(id: '', name: 'Unknown', avatar: null),
      createdAt: _parseDateTime(json['created_at']) ?? DateTime.now(),
      updatedAt: _parseDateTime(json['updated_at']) ?? DateTime.now(),
    );
  }
  
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'folderId': folderId,
      'title': title,
      'type': type.name,
      'status': status.name,
      'fileName': fileName,
      'fileSize': fileSize,
      'fileUrl': fileUrl,
      'downloadUrl': downloadUrl,
      'content': content,
      'version': version,
      'versionCount': versionCount,
      'uploader': {
        'id': uploader.id,
        'name': uploader.name,
        'avatar': uploader.avatar,
      },
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static DocumentType _parseDocumentType(String type) {
    switch (type.toLowerCase()) {
      case 'markdown':
      case 'md':
        return DocumentType.markdown;
      case 'word':
      case 'doc':
      case 'docx':
        return DocumentType.word;
      case 'excel':
      case 'xls':
      case 'xlsx':
        return DocumentType.excel;
      case 'powerpoint':
      case 'ppt':
      case 'pptx':
        return DocumentType.powerpoint;
      case 'pdf':
        return DocumentType.pdf;
      case 'image':
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return DocumentType.image;
      default:
        return DocumentType.other;
    }
  }

  static DocumentStatus _parseDocumentStatus(String status) {
    switch (status.toLowerCase()) {
      case 'editable':
        return DocumentStatus.editable;
      case 'preview_only':
      case 'previewonly':
      case 'readonly':  // 后端返回的是 readonly
        return DocumentStatus.previewOnly;
      case 'archived':
        return DocumentStatus.archived;
      case 'approved':
        return DocumentStatus.approved;
      default:
        return DocumentStatus.previewOnly;
    }
  }

  static Uploader _parseUploader(Map<String, dynamic> json) {
    return Uploader(
      id: json['id']?.toString() ?? '',  // 后端可能是 int
      name: json['name'] as String? ?? 'Unknown',
      avatar: json['avatar'] as String?,
    );
  }

  factory DocumentModel.fromEntity(Document document) {
    return DocumentModel(
      id: document.id,
      projectId: document.projectId,
      folderId: document.folderId,
      title: document.title,
      type: document.type,
      status: document.status,
      fileName: document.fileName,
      fileSize: document.fileSize,
      fileUrl: document.fileUrl,
      downloadUrl: document.downloadUrl,
      content: document.content,
      version: document.version,
      versionCount: document.versionCount,
      uploader: document.uploader,
      createdAt: document.createdAt,
      updatedAt: document.updatedAt,
    );
  }
}

/// 版本数据模型
class DocumentVersionModel extends DocumentVersion {
  const DocumentVersionModel({
    required super.version,
    required super.versionNumber,
    super.remark,
    required super.fileSize,
    required super.createdBy,
    required super.createdAt,
  });

  factory DocumentVersionModel.fromJson(Map<String, dynamic> json) {
    return DocumentVersionModel(
      version: json['version'] as String,
      versionNumber: json['versionNumber'] as int,
      remark: json['remark'] as String?,
      fileSize: json['fileSize'] as int,
      createdBy: _parseUploader(json['createdBy'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  static Uploader _parseUploader(Map<String, dynamic> json) {
    return Uploader(
      id: json['id'] as String,
      name: json['name'] as String,
      avatar: json['avatar'] as String?,
    );
  }
}

/// 统计响应
class DocumentStatisticsResponse {
  final int totalDocuments;
  final int totalSize;
  final Map<DocumentType, int> typeDistribution;
  final int recentUploads;

  const DocumentStatisticsResponse({
    required this.totalDocuments,
    required this.totalSize,
    required this.typeDistribution,
    required this.recentUploads,
  });

  factory DocumentStatisticsResponse.fromJson(Map<String, dynamic> json) {
    final typeDistJson = json['typeDistribution'] as Map<String, dynamic>;
    final typeDistribution = <DocumentType, int>{};
    typeDistJson.forEach((key, value) {
      typeDistribution[DocumentModel._parseDocumentType(key)] = value as int;
    });

    return DocumentStatisticsResponse(
      totalDocuments: json['totalDocuments'] as int,
      totalSize: json['totalSize'] as int,
      typeDistribution: typeDistribution,
      recentUploads: json['recentUploads'] as int,
    );
  }

  DocumentStatistics toEntity() {
    return DocumentStatistics(
      totalDocuments: totalDocuments,
      totalSize: totalSize,
      typeDistribution: typeDistribution,
      recentUploads: recentUploads,
    );
  }
}

/// 分页响应
class DocumentListResponse {
  final List<DocumentModel> list;
  final int currentPage;
  final int totalPages;
  final int totalCount;

  const DocumentListResponse({
    required this.list,
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
  });

  factory DocumentListResponse.fromJson(Map<String, dynamic> json) {
    final listJson = json['list'] as List<dynamic>;
    return DocumentListResponse(
      list: listJson.map((e) => DocumentModel.fromJson(e as Map<String, dynamic>)).toList(),
      currentPage: json['currentPage'] as int? ?? 1,
      totalPages: json['totalPages'] as int? ?? 1,
      totalCount: json['totalCount'] as int? ?? listJson.length,
    );
  }
}

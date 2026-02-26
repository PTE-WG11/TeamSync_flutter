import 'package:equatable/equatable.dart';

/// 文档类型
enum DocumentType {
  markdown,
  word,
  excel,
  powerpoint,
  pdf,
  image,
  other,
}

/// 文档状态
enum DocumentStatus {
  editable,      // 可编辑
  previewOnly,   // 仅预览
  archived,      // 已归档
  approved,      // 已验收
}

/// 上传者信息
class Uploader extends Equatable {
  final String id;
  final String name;
  final String? avatar;

  const Uploader({
    required this.id,
    required this.name,
    this.avatar,
  });

  @override
  List<Object?> get props => [id, name, avatar];
}

/// 文档实体
class Document extends Equatable {
  final String id;
  final String projectId;
  final String? folderId;
  final String title;
  final DocumentType type;
  final DocumentStatus status;
  final String fileName;
  final int fileSize; // 字节
  final String fileUrl;
  final String downloadUrl;
  final String? content; // Markdown内容
  final String version;
  final int versionCount;
  final Uploader uploader;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Document({
    required this.id,
    required this.projectId,
    this.folderId,
    required this.title,
    required this.type,
    this.status = DocumentStatus.previewOnly,
    required this.fileName,
    required this.fileSize,
    required this.fileUrl,
    required this.downloadUrl,
    this.content,
    this.version = 'v1.0',
    this.versionCount = 1,
    required this.uploader,
    required this.createdAt,
    required this.updatedAt,
  });

  Document copyWith({
    String? id,
    String? projectId,
    String? folderId,
    String? title,
    DocumentType? type,
    DocumentStatus? status,
    String? fileName,
    int? fileSize,
    String? fileUrl,
    String? downloadUrl,
    String? content,
    String? version,
    int? versionCount,
    Uploader? uploader,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Document(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      folderId: folderId ?? this.folderId,
      title: title ?? this.title,
      type: type ?? this.type,
      status: status ?? this.status,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      fileUrl: fileUrl ?? this.fileUrl,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      content: content ?? this.content,
      version: version ?? this.version,
      versionCount: versionCount ?? this.versionCount,
      uploader: uploader ?? this.uploader,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        projectId,
        folderId,
        title,
        type,
        status,
        fileName,
        fileSize,
        fileUrl,
        downloadUrl,
        content,
        version,
        versionCount,
        uploader,
        createdAt,
        updatedAt,
      ];

  /// 获取文件类型显示名称
  String get typeDisplayName {
    switch (type) {
      case DocumentType.markdown:
        return 'Markdown';
      case DocumentType.word:
        return 'Word';
      case DocumentType.excel:
        return 'Excel';
      case DocumentType.powerpoint:
        return 'PPT';
      case DocumentType.pdf:
        return 'PDF';
      case DocumentType.image:
        return '图片';
      case DocumentType.other:
        return '其他';
    }
  }

  /// 获取状态显示名称
  String get statusDisplayName {
    switch (status) {
      case DocumentStatus.editable:
        return '可编辑';
      case DocumentStatus.previewOnly:
        return '在线预览';
      case DocumentStatus.archived:
        return '已归档';
      case DocumentStatus.approved:
        return '已验收';
    }
  }

  /// 是否可编辑（仅Markdown且状态为editable）
  bool get isEditable => type == DocumentType.markdown && status == DocumentStatus.editable;

  /// 是否可预览
  bool get isPreviewable =>
      type == DocumentType.markdown ||
      type == DocumentType.pdf ||
      type == DocumentType.image;

  /// 格式化文件大小
  String get formattedFileSize {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else if (fileSize < 1024 * 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
}

/// 文档版本
class DocumentVersion extends Equatable {
  final String version;
  final int versionNumber;
  final String? remark;
  final int fileSize;
  final Uploader createdBy;
  final DateTime createdAt;

  const DocumentVersion({
    required this.version,
    required this.versionNumber,
    this.remark,
    required this.fileSize,
    required this.createdBy,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [version, versionNumber, remark, fileSize, createdBy, createdAt];
}

/// 文档统计
class DocumentStatistics extends Equatable {
  final int totalDocuments;
  final int totalSize;
  final Map<DocumentType, int> typeDistribution;
  final int recentUploads;

  const DocumentStatistics({
    required this.totalDocuments,
    required this.totalSize,
    required this.typeDistribution,
    required this.recentUploads,
  });

  @override
  List<Object?> get props => [totalDocuments, totalSize, typeDistribution, recentUploads];
}

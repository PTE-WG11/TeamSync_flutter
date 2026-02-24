import 'package:equatable/equatable.dart';

/// 附件实体
class Attachment extends Equatable {
  final int id;
  final int taskId;
  final String fileName;
  final String fileType;
  final int fileSize;
  final String fileKey;
  final String? url;
  final int uploadedBy;
  final String uploadedByName;
  final DateTime createdAt;

  const Attachment({
    required this.id,
    required this.taskId,
    required this.fileName,
    required this.fileType,
    required this.fileSize,
    required this.fileKey,
    this.url,
    required this.uploadedBy,
    required this.uploadedByName,
    required this.createdAt,
  });

  /// 文件大小显示（自动转换 KB/MB）
  String get fileSizeDisplay {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
  }

  /// 是否为图片
  bool get isImage => fileType.startsWith('image/');

  /// 是否为PDF
  bool get isPDF => fileType == 'application/pdf';

  /// 文件图标
  String get fileIcon {
    if (isImage) return 'image';
    if (isPDF) return 'pdf';
    if (fileType.contains('word') || fileType.contains('document')) return 'word';
    if (fileType.contains('excel') || fileType.contains('sheet')) return 'excel';
    if (fileType.contains('powerpoint') || fileType.contains('presentation')) {
      return 'ppt';
    }
    if (fileType.contains('zip') || fileType.contains('rar') || fileType.contains('7z')) {
      return 'archive';
    }
    if (fileType.contains('text')) return 'text';
    return 'file';
  }

  @override
  List<Object?> get props => [
        id,
        taskId,
        fileName,
        fileType,
        fileSize,
        fileKey,
        url,
        uploadedBy,
        uploadedByName,
        createdAt,
      ];

  Attachment copyWith({
    int? id,
    int? taskId,
    String? fileName,
    String? fileType,
    int? fileSize,
    String? fileKey,
    String? url,
    int? uploadedBy,
    String? uploadedByName,
    DateTime? createdAt,
  }) {
    return Attachment(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
      fileKey: fileKey ?? this.fileKey,
      url: url ?? this.url,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      uploadedByName: uploadedByName ?? this.uploadedByName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// 上传附件请求
class UploadAttachmentRequest extends Equatable {
  final String fileName;
  final String fileType;
  final int fileSize;

  const UploadAttachmentRequest({
    required this.fileName,
    required this.fileType,
    required this.fileSize,
  });

  Map<String, dynamic> toJson() => {
        'file_name': fileName,
        'file_type': fileType,
        'file_size': fileSize,
      };

  @override
  List<Object?> get props => [fileName, fileType, fileSize];
}

/// 上传URL响应
class UploadUrlResponse extends Equatable {
  final String uploadUrl;
  final String fileKey;
  final int expiresIn;

  const UploadUrlResponse({
    required this.uploadUrl,
    required this.fileKey,
    required this.expiresIn,
  });

  factory UploadUrlResponse.fromJson(Map<String, dynamic> json) {
    return UploadUrlResponse(
      uploadUrl: json['upload_url'] as String,
      fileKey: json['file_key'] as String,
      expiresIn: json['expires_in'] as int? ?? 300,
    );
  }

  @override
  List<Object?> get props => [uploadUrl, fileKey, expiresIn];
}

/// 确认上传请求
class ConfirmAttachmentRequest extends Equatable {
  final String fileKey;
  final String fileName;
  final String fileType;
  final int fileSize;

  const ConfirmAttachmentRequest({
    required this.fileKey,
    required this.fileName,
    required this.fileType,
    required this.fileSize,
  });

  Map<String, dynamic> toJson() => {
        'file_key': fileKey,
        'file_name': fileName,
        'file_type': fileType,
        'file_size': fileSize,
      };

  @override
  List<Object?> get props => [fileKey, fileName, fileType, fileSize];
}

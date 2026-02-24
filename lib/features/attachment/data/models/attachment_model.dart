import '../../domain/entities/attachment.dart';

/// 附件数据模型
class AttachmentModel extends Attachment {
  const AttachmentModel({
    required super.id,
    required super.taskId,
    required super.fileName,
    required super.fileType,
    required super.fileSize,
    required super.fileKey,
    super.url,
    required super.uploadedBy,
    required super.uploadedByName,
    required super.createdAt,
  });

  factory AttachmentModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      try {
        return DateTime.parse(value as String);
      } catch (e) {
        return DateTime.now();
      }
    }

    return AttachmentModel(
      id: json['id'] as int? ?? 0,
      taskId: json['task_id'] as int? ?? 0,
      fileName: json['file_name'] as String? ?? '未知文件',
      fileType: json['file_type'] as String? ?? 'application/octet-stream',
      fileSize: json['file_size'] as int? ?? 0,
      fileKey: json['file_key'] as String? ?? '',
      url: json['url'] as String?,
      uploadedBy: json['uploaded_by'] as int? ?? 0,
      uploadedByName: json['uploaded_by_name'] as String? ?? '未知用户',
      createdAt: parseDateTime(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'file_name': fileName,
      'file_type': fileType,
      'file_size': fileSize,
      'file_key': fileKey,
      'url': url,
      'uploaded_by': uploadedBy,
      'uploaded_by_name': uploadedByName,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory AttachmentModel.fromEntity(Attachment entity) {
    return AttachmentModel(
      id: entity.id,
      taskId: entity.taskId,
      fileName: entity.fileName,
      fileType: entity.fileType,
      fileSize: entity.fileSize,
      fileKey: entity.fileKey,
      url: entity.url,
      uploadedBy: entity.uploadedBy,
      uploadedByName: entity.uploadedByName,
      createdAt: entity.createdAt,
    );
  }
}

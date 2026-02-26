import '../../domain/entities/folder.dart';

/// 文件夹数据模型
class FolderModel extends Folder {
  const FolderModel({
    required super.id,
    required super.projectId,
    required super.name,
    super.parentId,
    super.sortOrder = 0,
    super.documentCount = 0,
    required super.createdAt,
    required super.createdBy,
  });

  factory FolderModel.fromJson(Map<String, dynamic> json) {
    return FolderModel(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      name: json['name'] as String,
      parentId: json['parentId'] as String?,
      sortOrder: json['sortOrder'] as int? ?? 0,
      documentCount: json['documentCount'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      createdBy: json['createdBy'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'name': name,
      'parentId': parentId,
      'sortOrder': sortOrder,
      'documentCount': documentCount,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  factory FolderModel.fromEntity(Folder folder) {
    return FolderModel(
      id: folder.id,
      projectId: folder.projectId,
      name: folder.name,
      parentId: folder.parentId,
      sortOrder: folder.sortOrder,
      documentCount: folder.documentCount,
      createdAt: folder.createdAt,
      createdBy: folder.createdBy,
    );
  }
}

/// 创建文件夹请求
class CreateFolderRequest {
  final String name;
  final String? parentId;
  final int sortOrder;

  const CreateFolderRequest({
    required this.name,
    this.parentId,
    this.sortOrder = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'parentId': parentId,
      'sortOrder': sortOrder,
    };
  }
}

/// 更新文件夹请求
class UpdateFolderRequest {
  final String? name;
  final int? sortOrder;

  const UpdateFolderRequest({
    this.name,
    this.sortOrder,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (sortOrder != null) data['sortOrder'] = sortOrder;
    return data;
  }
}

import 'package:equatable/equatable.dart';

/// 文件夹实体
class Folder extends Equatable {
  final String id;
  final String projectId;
  final String name;
  final String? parentId;
  final int sortOrder;
  final int documentCount;
  final DateTime createdAt;
  final String createdBy;

  const Folder({
    required this.id,
    required this.projectId,
    required this.name,
    this.parentId,
    this.sortOrder = 0,
    this.documentCount = 0,
    required this.createdAt,
    required this.createdBy,
  });

  Folder copyWith({
    String? id,
    String? projectId,
    String? name,
    String? parentId,
    int? sortOrder,
    int? documentCount,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return Folder(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      sortOrder: sortOrder ?? this.sortOrder,
      documentCount: documentCount ?? this.documentCount,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  @override
  List<Object?> get props => [
        id,
        projectId,
        name,
        parentId,
        sortOrder,
        documentCount,
        createdAt,
        createdBy,
      ];
}

/// 文件夹树节点（用于树形展示）
class FolderNode extends Equatable {
  final Folder folder;
  final List<FolderNode> children;
  final bool isExpanded;

  const FolderNode({
    required this.folder,
    this.children = const [],
    this.isExpanded = true,
  });

  FolderNode copyWith({
    Folder? folder,
    List<FolderNode>? children,
    bool? isExpanded,
  }) {
    return FolderNode(
      folder: folder ?? this.folder,
      children: children ?? this.children,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }

  @override
  List<Object?> get props => [folder, children, isExpanded];
}

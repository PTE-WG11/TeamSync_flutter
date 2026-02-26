part of 'folder_bloc.dart';

abstract class FolderEvent extends Equatable {
  const FolderEvent();

  @override
  List<Object?> get props => [];
}

/// 加载文件夹列表
class FoldersLoadRequested extends FolderEvent {
  const FoldersLoadRequested();
}

/// 创建文件夹
class FolderCreateRequested extends FolderEvent {
  final String name;
  final String? parentId;
  final int sortOrder;

  const FolderCreateRequested({
    required this.name,
    this.parentId,
    this.sortOrder = 0,
  });

  @override
  List<Object?> get props => [name, parentId, sortOrder];
}

/// 更新文件夹
class FolderUpdateRequested extends FolderEvent {
  final String folderId;
  final String? name;
  final int? sortOrder;

  const FolderUpdateRequested({
    required this.folderId,
    this.name,
    this.sortOrder,
  });

  @override
  List<Object?> get props => [folderId, name, sortOrder];
}

/// 删除文件夹
class FolderDeleteRequested extends FolderEvent {
  final String folderId;
  final bool force;

  const FolderDeleteRequested({
    required this.folderId,
    this.force = false,
  });

  @override
  List<Object?> get props => [folderId, force];
}

/// 切换文件夹展开状态
class FolderExpandToggled extends FolderEvent {
  final String folderId;

  const FolderExpandToggled(this.folderId);

  @override
  List<Object?> get props => [folderId];
}

/// 选择文件夹
class FolderSelectRequested extends FolderEvent {
  final String? folderId;

  const FolderSelectRequested(this.folderId);

  @override
  List<Object?> get props => [folderId];
}

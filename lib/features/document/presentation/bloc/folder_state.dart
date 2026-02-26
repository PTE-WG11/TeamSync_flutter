part of 'folder_bloc.dart';

/// 文件夹状态
class FolderState extends Equatable {
  final List<Folder> folders;
  final List<FolderNode> folderTree;
  final bool isLoading;
  final bool isCreating;
  final bool isUpdating;
  final bool isDeleting;
  final String? error;
  final String? selectedFolderId;
  final Set<String> expandedFolderIds;

  const FolderState({
    this.folders = const [],
    this.folderTree = const [],
    this.isLoading = false,
    this.isCreating = false,
    this.isUpdating = false,
    this.isDeleting = false,
    this.error,
    this.selectedFolderId,
    this.expandedFolderIds = const {},
  });

  FolderState copyWith({
    List<Folder>? folders,
    List<FolderNode>? folderTree,
    bool? isLoading,
    bool? isCreating,
    bool? isUpdating,
    bool? isDeleting,
    String? error,
    String? selectedFolderId,
    Set<String>? expandedFolderIds,
    bool clearError = false,
    bool clearSelected = false,
  }) {
    return FolderState(
      folders: folders ?? this.folders,
      folderTree: folderTree ?? this.folderTree,
      isLoading: isLoading ?? this.isLoading,
      isCreating: isCreating ?? this.isCreating,
      isUpdating: isUpdating ?? this.isUpdating,
      isDeleting: isDeleting ?? this.isDeleting,
      error: clearError ? null : error ?? this.error,
      selectedFolderId: clearSelected ? null : selectedFolderId ?? this.selectedFolderId,
      expandedFolderIds: expandedFolderIds ?? this.expandedFolderIds,
    );
  }

  @override
  List<Object?> get props => [
        folders,
        folderTree,
        isLoading,
        isCreating,
        isUpdating,
        isDeleting,
        error,
        selectedFolderId,
        expandedFolderIds,
      ];

  Folder? get selectedFolder {
    if (selectedFolderId == null) return null;
    try {
      return folders.firstWhere(
        (f) => f.id == selectedFolderId,
      );
    } catch (_) {
      return null;
    }
  }

  /// 获取文件夹路径（从根到当前）
  List<Folder> getFolderPath(String folderId) {
    final path = <Folder>[];
    String? currentId = folderId;
    
    while (currentId != null) {
      try {
        final folder = folders.firstWhere(
          (f) => f.id == currentId,
        );
        path.insert(0, folder);
        currentId = folder.parentId;
      } catch (_) {
        break;
      }
    }
    
    return path;
  }
}

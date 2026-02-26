import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/folder.dart';
import '../../domain/repositories/document_repository.dart';

part 'folder_event.dart';
part 'folder_state.dart';

/// 文件夹Bloc
class FolderBloc extends Bloc<FolderEvent, FolderState> {
  final DocumentRepository _repository;
  final String _projectId;

  FolderBloc({
    required DocumentRepository repository,
    required String projectId,
  })  : _repository = repository,
        _projectId = projectId,
        super(const FolderState()) {
    on<FoldersLoadRequested>(_onLoadFolders);
    on<FolderCreateRequested>(_onCreateFolder);
    on<FolderUpdateRequested>(_onUpdateFolder);
    on<FolderDeleteRequested>(_onDeleteFolder);
    on<FolderExpandToggled>(_onExpandToggled);
    on<FolderSelectRequested>(_onSelectFolder);
  }

  Future<void> _onLoadFolders(
    FoldersLoadRequested event,
    Emitter<FolderState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final folders = await _repository.getFolders(_projectId);
      
      // 构建文件夹树
      final folderTree = _buildFolderTree(folders);
      
      emit(state.copyWith(
        isLoading: false,
        folders: folders,
        folderTree: folderTree,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  List<FolderNode> _buildFolderTree(List<Folder> folders) {
    final Map<String?, List<Folder>> folderMap = {};
    
    // 按parentId分组
    for (final folder in folders) {
      folderMap.putIfAbsent(folder.parentId, () => []).add(folder);
    }
    
    // 递归构建树
    List<FolderNode> buildNodes(String? parentId) {
      final children = folderMap[parentId] ?? [];
      children.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      
      return children.map((folder) {
        final childNodes = buildNodes(folder.id);
        return FolderNode(
          folder: folder,
          children: childNodes,
          isExpanded: state.expandedFolderIds.contains(folder.id),
        );
      }).toList();
    }
    
    return buildNodes(null);
  }

  Future<void> _onCreateFolder(
    FolderCreateRequested event,
    Emitter<FolderState> emit,
  ) async {
    emit(state.copyWith(isCreating: true, error: null));
    try {
      final folder = await _repository.createFolder(
        projectId: _projectId,
        name: event.name,
        parentId: event.parentId,
        sortOrder: event.sortOrder,
      );
      
      final updatedFolders = [...state.folders, folder];
      final folderTree = _buildFolderTree(updatedFolders);
      
      emit(state.copyWith(
        isCreating: false,
        folders: updatedFolders,
        folderTree: folderTree,
      ));
    } catch (e) {
      emit(state.copyWith(
        isCreating: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onUpdateFolder(
    FolderUpdateRequested event,
    Emitter<FolderState> emit,
  ) async {
    emit(state.copyWith(isUpdating: true, error: null));
    try {
      final folder = await _repository.updateFolder(
        folderId: event.folderId,
        name: event.name,
        sortOrder: event.sortOrder,
      );
      
      final updatedFolders = state.folders.map((f) {
        return f.id == event.folderId ? folder : f;
      }).toList();
      final folderTree = _buildFolderTree(updatedFolders);
      
      emit(state.copyWith(
        isUpdating: false,
        folders: updatedFolders,
        folderTree: folderTree,
      ));
    } catch (e) {
      emit(state.copyWith(
        isUpdating: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onDeleteFolder(
    FolderDeleteRequested event,
    Emitter<FolderState> emit,
  ) async {
    emit(state.copyWith(isDeleting: true, error: null));
    try {
      await _repository.deleteFolder(event.folderId, force: event.force);
      
      final updatedFolders = state.folders
          .where((f) => f.id != event.folderId)
          .toList();
      final folderTree = _buildFolderTree(updatedFolders);
      
      emit(state.copyWith(
        isDeleting: false,
        folders: updatedFolders,
        folderTree: folderTree,
        selectedFolderId: state.selectedFolderId == event.folderId
            ? null
            : state.selectedFolderId,
      ));
    } catch (e) {
      emit(state.copyWith(
        isDeleting: false,
        error: e.toString(),
      ));
    }
  }

  void _onExpandToggled(
    FolderExpandToggled event,
    Emitter<FolderState> emit,
  ) {
    final expandedIds = Set<String>.from(state.expandedFolderIds);
    if (expandedIds.contains(event.folderId)) {
      expandedIds.remove(event.folderId);
    } else {
      expandedIds.add(event.folderId);
    }
    
    final folderTree = _buildFolderTree(state.folders);
    emit(state.copyWith(
      expandedFolderIds: expandedIds,
      folderTree: folderTree,
    ));
  }

  void _onSelectFolder(
    FolderSelectRequested event,
    Emitter<FolderState> emit,
  ) {
    emit(state.copyWith(selectedFolderId: event.folderId));
  }
}

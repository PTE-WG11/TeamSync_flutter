import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/theme.dart';
import '../../domain/entities/folder.dart';
import '../bloc/folder_bloc.dart';

/// 文件夹树形组件
class FolderTree extends StatelessWidget {
  final String? selectedFolderId;
  final Function(String?)? onFolderSelected;

  const FolderTree({
    super.key,
    this.selectedFolderId,
    this.onFolderSelected,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FolderBloc, FolderState>(
      builder: (context, state) {
        if (state.isLoading && state.folders.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 全部文件选项
            _buildAllFilesItem(context, state),
            const Divider(height: 1, indent: 16, endIndent: 16),
            // 文件夹树
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: state.folderTree.length,
                itemBuilder: (context, index) {
                  return _buildFolderNode(
                    context,
                    state.folderTree[index],
                    level: 0,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAllFilesItem(BuildContext context, FolderState state) {
    final isSelected = state.selectedFolderId == null;
    
    return InkWell(
      onTap: () {
        context.read<FolderBloc>().add(const FolderSelectRequested(null));
        onFolderSelected?.call(null);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : null,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Icon(
              Icons.folder_copy_outlined,
              size: 20,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '全部文件',
                style: AppTypography.body.copyWith(
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w500 : null,
                ),
              ),
            ),
            Text(
              '${state.folders.fold<int>(0, (sum, f) => sum + f.documentCount)}',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFolderNode(
    BuildContext context,
    FolderNode node, {
    required int level,
  }) {
    final isSelected = node.folder.id == selectedFolderId;
    final hasChildren = node.children.isNotEmpty;
    final isExpanded = node.isExpanded;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            context.read<FolderBloc>().add(FolderSelectRequested(node.folder.id));
            onFolderSelected?.call(node.folder.id);
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            padding: EdgeInsets.only(
              left: 12 + level * 16.0,
              right: 12,
              top: 8,
              bottom: 8,
            ),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryLight : null,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                // 展开/折叠按钮
                if (hasChildren)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      context.read<FolderBloc>().add(FolderExpandToggled(node.folder.id));
                    },
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: Icon(
                        isExpanded ? Icons.expand_more : Icons.chevron_right,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 24),
                const SizedBox(width: 4),
                // 文件夹图标
                Icon(
                  isExpanded ? Icons.folder_open : Icons.folder,
                  size: 20,
                  color: isSelected ? AppColors.primary : AppColors.warning,
                ),
                const SizedBox(width: 8),
                // 文件夹名称
                Expanded(
                  child: Text(
                    node.folder.name,
                    style: AppTypography.body.copyWith(
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w500 : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // 文档数量
                Text(
                  '${node.folder.documentCount}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        // 子文件夹
        if (hasChildren && isExpanded)
          ...node.children.map((child) => _buildFolderNode(
                context,
                child,
                level: level + 1,
              )),
      ],
    );
  }
}

/// 文件夹操作按钮
class FolderActionsButton extends StatelessWidget {
  const FolderActionsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 20),
      offset: const Offset(0, 40),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'create',
          child: Row(
            children: [
              Icon(Icons.create_new_folder_outlined, size: 18),
              SizedBox(width: 8),
              Text('新建文件夹'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'refresh',
          child: Row(
            children: [
              Icon(Icons.refresh, size: 18),
              SizedBox(width: 8),
              Text('刷新'),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'create':
            _showCreateFolderDialog(context);
            break;
          case 'refresh':
            context.read<FolderBloc>().add(const FoldersLoadRequested());
            break;
        }
      },
    );
  }

  void _showCreateFolderDialog(BuildContext context) {
    final textController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('新建文件夹', style: AppTypography.h4),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '请输入文件夹名称',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = textController.text.trim();
              if (name.isNotEmpty) {
                context.read<FolderBloc>().add(FolderCreateRequested(name: name));
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }
}

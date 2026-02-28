

import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../config/theme.dart';
import '../../data/repositories/document_repository_impl.dart';
import '../../domain/repositories/document_repository.dart';
import '../../domain/entities/document.dart';
import '../bloc/document_bloc.dart';
import '../bloc/folder_bloc.dart';
import '../widgets/document_card.dart';
import '../widgets/folder_tree.dart';
import '../widgets/preview_panel.dart';

/// 项目文档页面
class ProjectDocumentsPage extends StatelessWidget {
  final int projectId;
  final DocumentRepository? repository;

  const ProjectDocumentsPage({
    super.key,
    required this.projectId,
    this.repository,
  });

  @override
  Widget build(BuildContext context) {
    // 检查外部是否已经提供了Bloc
    DocumentBloc? documentBloc;
    FolderBloc? folderBloc;
    
    try {
      documentBloc = context.read<DocumentBloc>();
    } catch (_) {
      documentBloc = null;
    }
    
    try {
      folderBloc = context.read<FolderBloc>();
    } catch (_) {
      folderBloc = null;
    }
    
    // 如果外部已经提供了Bloc，直接使用
    if (documentBloc != null && folderBloc != null) {
      return const _ProjectDocumentsView();
    }

    // 否则创建新的Bloc
    final repo = repository ?? DocumentRepositoryImpl();
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<DocumentRepository>(
          create: (_) => repo,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => DocumentBloc(
              repository: repo,
              projectId: projectId.toString(),
            )..add(const DocumentsLoadRequested()),
          ),
          BlocProvider(
            create: (_) => FolderBloc(
              repository: repo,
              projectId: projectId.toString(),
            )..add(const FoldersLoadRequested()),
          ),
        ],
        child: const _ProjectDocumentsView(),
      ),
    );
  }
}

class _ProjectDocumentsView extends StatefulWidget {
  const _ProjectDocumentsView();

  @override
  State<_ProjectDocumentsView> createState() => _ProjectDocumentsViewState();
}

class _ProjectDocumentsViewState extends State<_ProjectDocumentsView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (context, constraints) {
          // 设置最小宽度为 1000，不足时显示滚动条
          const double minWidth = 1000;
          final bool needScroll = constraints.maxWidth < minWidth;
          
          // 从 Bloc 获取选中的文档ID
          final selectedDocumentId = context.select<DocumentBloc, String?>(
            (bloc) => bloc.state.selectedDocumentId,
          );
          
          Widget content = Row(
            children: [
              // 左侧：文件夹树
              _buildFolderPanel(),
              // 中间：文档列表
              Expanded(
                flex: 3,
                child: _buildDocumentPanel(),
              ),
              // 右侧：预览面板（选中文件时显示）
              if (selectedDocumentId != null)
                BlocBuilder<DocumentBloc, DocumentState>(
                  builder: (context, state) {
                    // 使用 selectedDocument getter 获取文档（优先返回详情）
                    final document = state.selectedDocument;
                    if (document == null) return const SizedBox.shrink();
                    
                    return PreviewPanel(
                      document: document,
                      isLoading: state.isLoadingDetail,
                      onClose: () {
                        context.read<DocumentBloc>().add(const DocumentClearSelection());
                      },
                      onEdit: document.isEditable && !state.isLoadingDetail
                          ? () => _showEditDialog(context, document)
                          : null,
                      onDownload: state.isLoadingDetail
                          ? null
                          : () => _downloadDocument(context, document),
                    );
                  },
                ),
            ],
          );
          
          // 如果宽度不足最小宽度，添加水平滚动
          if (needScroll) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: minWidth),
                child: content,
              ),
            );
          }
          
          return content;
        },
      );
  }

  Widget _buildFolderPanel() {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          right: BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        children: [
          // 标题栏
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text('文件夹', style: AppTypography.h4),
                const Spacer(),
                const FolderActionsButton(),
              ],
            ),
          ),
          const Divider(height: 1),
          // 文件夹树
          Expanded(
            child: BlocBuilder<FolderBloc, FolderState>(
              builder: (context, state) {
                return FolderTree(
                  selectedFolderId: state.selectedFolderId,
                  onFolderSelected: (folderId) {
                    context.read<DocumentBloc>().add(
                      DocumentFilterByFolder(folderId),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentPanel() {
    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          // 顶部工具栏
          _buildToolbar(),
          // 文档列表
          Expanded(
            child: _buildDocumentList(),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          // 搜索框
          Expanded(
            flex: 2,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索文档...',
                prefixIcon: const Icon(Icons.search, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  context.read<DocumentBloc>().add(
                    DocumentSearchRequested(keyword: value),
                  );
                }
              },
            ),
          ),
          const SizedBox(width: 16),
          // 视图切换
          BlocBuilder<DocumentBloc, DocumentState>(
            builder: (context, state) {
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    _buildViewButton(
                      icon: Icons.grid_view,
                      isSelected: state.viewMode == DocumentViewMode.grid,
                      onTap: () {
                        context.read<DocumentBloc>().add(
                          const DocumentViewModeChanged(DocumentViewMode.grid),
                        );
                      },
                    ),
                    _buildViewButton(
                      icon: Icons.view_list,
                      isSelected: state.viewMode == DocumentViewMode.list,
                      onTap: () {
                        context.read<DocumentBloc>().add(
                          const DocumentViewModeChanged(DocumentViewMode.list),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          // 新建按钮
          _buildActionMenu(),
        ],
      ),
    );
  }

  Widget _buildViewButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : null,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isSelected ? AppColors.textInverse : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildActionMenu() {
    return PopupMenuButton<String>(
      offset: const Offset(0, 40),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            const Icon(Icons.add, color: AppColors.textInverse, size: 18),
            const SizedBox(width: 4),
            Text(
              '新建',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textInverse,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Icon(
              Icons.arrow_drop_down,
              color: AppColors.textInverse,
              size: 18,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'markdown',
          child: Row(
            children: [
              Icon(Icons.description_outlined, size: 18),
              SizedBox(width: 8),
              Text('新建 Markdown'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'upload',
          child: Row(
            children: [
              Icon(Icons.upload_file, size: 18),
              SizedBox(width: 8),
              Text('上传文件'),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'markdown':
            _showCreateMarkdownDialog(context);
            break;
          case 'upload':
            _pickAndUploadFile(context);
            break;
        }
      },
    );
  }

  Widget _buildDocumentList() {
    return BlocBuilder<DocumentBloc, DocumentState>(
      builder: (context, state) {
        if (state.isLoading && state.documents.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.error != null && state.documents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text(
                  '加载失败',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<DocumentBloc>().add(
                      const DocumentsLoadRequested(),
                    );
                  },
                  child: const Text('重试'),
                ),
              ],
            ),
          );
        }

        if (state.documents.isEmpty) {
          return _buildEmptyView();
        }

        if (state.viewMode == DocumentViewMode.grid) {
          return _buildGridView(state);
        } else {
          return _buildListView(state);
        }
      },
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open_outlined,
            size: 64,
            color: AppColors.textDisabled,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无文档',
            style: AppTypography.h4.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右上角新建文档或上传文件',
            style: AppTypography.body.copyWith(
              color: AppColors.textDisabled,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(DocumentState state) {
    const double cardWidth = 260; // 固定卡片宽度
    const double spacing = 16; // 间距
    const double cardAspectRatio = 2.2; // 卡片宽高比（宽度/高度，现在是横向布局，所以比较扁）

    return LayoutBuilder(
      builder: (context, constraints) {
        // 根据可用宽度计算列数
        final availableWidth = constraints.maxWidth - (spacing * 2); // 减去左右padding
        final crossAxisCount = (availableWidth / (cardWidth + spacing)).floor().clamp(1, 10);

        return GridView.builder(
          padding: const EdgeInsets.all(spacing),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: cardAspectRatio,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
          ),
          itemCount: state.documents.length + 1, // +1 for create button
          itemBuilder: (context, index) {
            if (index == state.documents.length) {
              return _buildCreateCard();
            }

            final doc = state.documents[index];
            return DocumentCard(
              document: doc,
              isSelected: doc.id == state.selectedDocumentId,
              onTap: () {
                context.read<DocumentBloc>().add(DocumentSelected(doc.id));
              },
              onMoreTap: () {
                _showDocumentActions(context, doc);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildListView(DocumentState state) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: state.documents.length,
      itemBuilder: (context, index) {
        final doc = state.documents[index];
        return DocumentListItem(
          document: doc,
          isSelected: doc.id == state.selectedDocumentId,
          onTap: () {
            context.read<DocumentBloc>().add(DocumentSelected(doc.id));
          },
          onMoreTap: () {
            _showDocumentActions(context, doc);
          },
        );
      },
    );
  }

  Widget _buildCreateCard() {
    return InkWell(
      onTap: () {
        _showCreateMarkdownDialog(context);
      },
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: AppColors.border,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline,
              size: 48,
              color: AppColors.textDisabled,
            ),
            const SizedBox(height: 12),
            Text(
              '新建文档',
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '支持 Markdown',
              style: AppTypography.caption.copyWith(
                color: AppColors.textDisabled,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateMarkdownDialog(BuildContext context) {
    final folderState = context.read<FolderBloc>().state;
    final documentBloc = context.read<DocumentBloc>();

    // 直接打开编辑器，用于创建新文档
    showDialog(
      context: context,
      builder: (dialogContext) => MarkdownEditor(
        initialContent: '',
        title: '', // 空标题表示新建模式
        isNewDocument: true,
        folderName: folderState.selectedFolder?.name,
        onSave: (title, content) {
          if (title.trim().isNotEmpty) {
            documentBloc.add(
              DocumentCreateMarkdownRequested(
                title: title.trim(),
                folderId: folderState.selectedFolderId,
                content: content,
              ),
            );
          }
          Navigator.pop(dialogContext);
        },
        onCancel: () => Navigator.pop(dialogContext),
      ),
    );
  }

  Future<void> _pickAndUploadFile(BuildContext context) async {
    final folderBloc = context.read<FolderBloc>();
    final documentBloc = context.read<DocumentBloc>();
    final messenger = ScaffoldMessenger.of(context);
    
    try {
      // Web 平台需要读取 bytes
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: true, // 确保读取文件数据（Web需要）
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final folderState = folderBloc.state;

        // 判断平台：Web 使用 bytes，其他使用 path
        if (kIsWeb) {
          // Web 平台：使用 bytes
          if (file.bytes != null) {
            documentBloc.add(
              DocumentUploadFromBytesRequested(
                fileBytes: file.bytes!,
                fileName: file.name,
                folderId: folderState.selectedFolderId,
                title: file.name,
              ),
            );
          } else {
            messenger.showSnackBar(
              const SnackBar(content: Text('无法读取文件内容')),
            );
          }
        } else {
          // 移动端/桌面端：使用 path
          if (file.path != null) {
            documentBloc.add(
              DocumentUploadRequested(
                filePath: file.path!,
                folderId: folderState.selectedFolderId,
                title: file.name,
              ),
            );
          } else {
            messenger.showSnackBar(
              const SnackBar(content: Text('无法获取文件路径')),
            );
          }
        }
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('选择文件失败: $e')),
      );
    }
  }

  void _showEditDialog(BuildContext context, Document document) {
    showDialog(
      context: context,
      builder: (dialogContext) => MarkdownEditor(
        initialContent: document.content ?? '',
        title: document.title,
        onSave: (title, content) {
          context.read<DocumentBloc>().add(
            DocumentUpdateMarkdownRequested(
              documentId: document.id,
              content: content,
            ),
          );
          Navigator.pop(dialogContext);
        },
        onCancel: () => Navigator.pop(dialogContext),
      ),
    );
  }

  void _showDocumentActions(BuildContext context, Document document) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (document.isEditable)
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('编辑'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showEditDialog(context, document);
                },
              ),
            ListTile(
              leading: const Icon(Icons.download_outlined),
              title: const Text('下载'),
              onTap: () {
                Navigator.pop(sheetContext);
                _downloadDocument(context, document);
              },
            ),
            ListTile(
              leading: const Icon(Icons.drive_file_move_outlined),
              title: const Text('移动到...'),
              onTap: () {
                Navigator.pop(sheetContext);
                _showMoveDialog(context, document);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text('删除', style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(sheetContext);
                _showDeleteConfirm(context, document);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMoveDialog(BuildContext context, Document document) {
    final folderState = context.read<FolderBloc>().state;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('移动到', style: AppTypography.h4),
        content: SizedBox(
          width: 300,
          height: 300,
          child: ListView.builder(
            itemCount: folderState.folders.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return ListTile(
                  leading: const Icon(Icons.folder_copy_outlined),
                  title: const Text('根目录'),
                  selected: document.folderId == null,
                  onTap: () {
                    context.read<DocumentBloc>().add(
                      DocumentMoveRequested(
                        documentId: document.id,
                        folderId: null,
                      ),
                    );
                    Navigator.pop(dialogContext);
                  },
                );
              }
              final folder = folderState.folders[index - 1];
              return ListTile(
                leading: const Icon(Icons.folder),
                title: Text(folder.name),
                selected: folder.id == document.folderId,
                onTap: () {
                  context.read<DocumentBloc>().add(
                    DocumentMoveRequested(
                      documentId: document.id,
                      folderId: folder.id,
                    ),
                  );
                  Navigator.pop(dialogContext);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, Document document) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('删除文档', style: AppTypography.h4),
        content: Text('确定要删除"${document.title}"吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<DocumentBloc>().add(
                DocumentDeleteRequested(document.id),
              );
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textInverse,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _showDownloadSnackBar(BuildContext context, String fileName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('开始下载: $fileName'),
        action: SnackBarAction(
          label: '确定',
          onPressed: () {},
        ),
      ),
    );
  }

  /// 下载文档
  Future<void> _downloadDocument(BuildContext context, Document document) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    try {
      // Markdown 文件直接在前端生成并下载
      if (document.type == DocumentType.markdown) {
        await _downloadMarkdownFile(context, document);
        return;
      }
      
      // 显示下载中提示
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('正在获取下载链接: ${document.title}...')),
      );
      
      // 获取下载链接
      String downloadUrl;
      if (document.downloadUrl.isNotEmpty) {
        // 如果文档中已有下载链接，直接使用
        downloadUrl = document.downloadUrl;
      } else {
        // 否则调用接口获取
        final repository = context.read<DocumentRepository>();
        downloadUrl = await repository.getDownloadUrl(document.id);
      }
      
      debugPrint('[Download] 下载链接: $downloadUrl');
      
      // 打开下载链接
      final uri = Uri.parse(downloadUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('已开始下载: ${document.title}')),
        );
      } else {
        throw Exception('无法打开下载链接');
      }
    } catch (e) {
      debugPrint('[Download] 下载失败: $e');
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('下载失败: $e')),
      );
    }
  }
  
  /// 直接下载 Markdown 文件（前端生成）
  Future<void> _downloadMarkdownFile(BuildContext context, Document document) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    try {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('正在准备下载: ${document.title}...')),
      );
      
      // 获取 Markdown 内容
      final content = document.content ?? '';
      
      // 生成文件名（确保以 .md 结尾）
      String fileName = document.title;
      if (!fileName.toLowerCase().endsWith('.md')) {
        fileName = '$fileName.md';
      }
      
      // 将内容转换为字节
      final bytes = Uint8List.fromList(utf8.encode(content));
      
      // 使用 file_saver 保存文件
      await FileSaver.instance.saveFile(
        name: fileName.replaceAll('.md', ''), // file_saver 会自动添加扩展名
        bytes: bytes,
        ext: 'md',
        mimeType: MimeType.text,
      );
      
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('已保存: $fileName')),
      );
    } catch (e) {
      debugPrint('[Download] Markdown 下载失败: $e');
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('下载失败: $e')),
      );
    }
  }
}

// 事件类已在 bloc 中定义

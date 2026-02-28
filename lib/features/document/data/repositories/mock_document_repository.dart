import '../../domain/entities/document.dart';
import '../../domain/entities/document_comment.dart';
import '../../domain/entities/folder.dart';
import '../../domain/repositories/document_repository.dart';
import '../models/document_comment_model.dart';
import '../models/document_model.dart';
import '../models/folder_model.dart';

/// 模拟文档仓库实现（用于开发和测试）
class MockDocumentRepository implements DocumentRepository {
  // 模拟数据存储
  final List<FolderModel> _folders = [];
  final List<DocumentModel> _documents = [];
  final List<DocumentCommentModel> _comments = [];

  MockDocumentRepository() {
    _initMockData();
  }

  void _initMockData() {
    // 初始化文件夹数据
    _folders.addAll([
      FolderModel(
        id: 'folder_001',
        projectId: '1',
        name: '产品文档',
        sortOrder: 1,
        documentCount: 2,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        createdBy: 'user_001',
      ),
      FolderModel(
        id: 'folder_002',
        projectId: '1',
        name: '技术文档',
        sortOrder: 2,
        documentCount: 3,
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
        createdBy: 'user_001',
      ),
      FolderModel(
        id: 'folder_003',
        projectId: '1',
        name: '设计稿',
        parentId: 'folder_002',
        sortOrder: 1,
        documentCount: 1,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        createdBy: 'user_002',
      ),
    ]);

    // 初始化文档数据
    _documents.addAll([
      DocumentModel(
        id: 'doc_001',
        projectId: '1',
        folderId: 'folder_001',
        title: '产品需求文档 PRD',
        type: DocumentType.word,
        status: DocumentStatus.approved,
        fileName: 'PRD-v2.0.docx',
        fileSize: 2457600,
        fileUrl: 'https://example.com/docs/prd.docx',
        downloadUrl: 'https://example.com/docs/prd.docx?download=1',
        version: 'v2.0',
        versionCount: 5,
        uploader: const Uploader(
          id: 'user_001',
          name: '张三',
          avatar: null,
        ),
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      DocumentModel(
        id: 'doc_002',
        projectId: '1',
        folderId: 'folder_002',
        title: 'API接口设计文档',
        type: DocumentType.markdown,
        status: DocumentStatus.editable,
        fileName: 'api-design.md',
        fileSize: 15600,
        fileUrl: 'https://example.com/docs/api-design.md',
        downloadUrl: 'https://example.com/docs/api-design.md?download=1',
        content: '''# API接口设计文档

## 1. 概述
本文档描述了项目后端API接口的设计规范。

## 2. 认证
所有API请求需要在Header中携带Token：
```
Authorization: Bearer {token}
```

## 3. 接口列表

### 3.1 用户相关

#### 3.1.1 用户登录
- **URL**: `/api/v1/auth/login`
- **Method**: POST
- **Request Body**:
```json
{
  "username": "string",
  "password": "string"
}
```

## 4. 错误码
| 错误码 | 说明 |
|-------|------|
| 400 | 请求参数错误 |
| 401 | 未授权 |
| 403 | 无权限访问 |
| 500 | 服务器内部错误 |
''',
        version: 'v2.0',
        versionCount: 3,
        uploader: const Uploader(
          id: 'user_001',
          name: '张三',
          avatar: null,
        ),
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      DocumentModel(
        id: 'doc_003',
        projectId: '1',
        folderId: 'folder_003',
        title: 'UI设计规范v1.0',
        type: DocumentType.image,
        status: DocumentStatus.previewOnly,
        fileName: 'ui-design.png',
        fileSize: 12582912,
        fileUrl: 'https://picsum.photos/800/600',
        downloadUrl: 'https://picsum.photos/800/600?download=1',
        version: 'v1.0',
        versionCount: 1,
        uploader: const Uploader(
          id: 'user_002',
          name: '李四',
          avatar: null,
        ),
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
      DocumentModel(
        id: 'doc_004',
        projectId: '1',
        folderId: 'folder_002',
        title: '数据库设计文档',
        type: DocumentType.markdown,
        status: DocumentStatus.editable,
        fileName: 'db-design.md',
        fileSize: 8900,
        fileUrl: 'https://example.com/docs/db-design.md',
        downloadUrl: 'https://example.com/docs/db-design.md?download=1',
        content: '''# 数据库设计文档

## 1. 用户表 (users)

| 字段 | 类型 | 说明 |
|-----|------|------|
| id | BIGINT | 主键 |
| username | VARCHAR(50) | 用户名 |
| email | VARCHAR(100) | 邮箱 |
| created_at | TIMESTAMP | 创建时间 |

## 2. 项目表 (projects)

| 字段 | 类型 | 说明 |
|-----|------|------|
| id | BIGINT | 主键 |
| title | VARCHAR(200) | 项目标题 |
| description | TEXT | 项目描述 |
| status | VARCHAR(20) | 项目状态 |
''',
        version: 'v1.0',
        versionCount: 1,
        uploader: const Uploader(
          id: 'user_001',
          name: '张三',
          avatar: null,
        ),
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      DocumentModel(
        id: 'doc_005',
        projectId: '1',
        folderId: null,
        title: '迭代规划会议纪要',
        type: DocumentType.pdf,
        status: DocumentStatus.archived,
        fileName: 'meeting-notes.pdf',
        fileSize: 1258291,
        fileUrl: 'https://example.com/docs/meeting.pdf',
        downloadUrl: 'https://example.com/docs/meeting.pdf?download=1',
        version: 'v1.0',
        versionCount: 1,
        uploader: const Uploader(
          id: 'user_001',
          name: '张三',
          avatar: null,
        ),
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        updatedAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
      DocumentModel(
        id: 'doc_006',
        projectId: '1',
        folderId: 'folder_002',
        title: 'Bug修复测试用例集',
        type: DocumentType.excel,
        status: DocumentStatus.approved,
        fileName: 'test-cases.xlsx',
        fileSize: 876544,
        fileUrl: 'https://example.com/docs/test-cases.xlsx',
        downloadUrl: 'https://example.com/docs/test-cases.xlsx?download=1',
        version: 'v1.0',
        versionCount: 2,
        uploader: const Uploader(
          id: 'user_003',
          name: '王测试',
          avatar: null,
        ),
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ]);

    // 初始化评论数据
    _comments.addAll([
      DocumentCommentModel(
        id: 'comment_001',
        documentId: 'doc_002',
        content: '接口文档中第3部分的参数说明需要更新，已同步最新版本。',
        author: const CommentAuthor(
          id: 'user_002',
          name: 'teamAdmin',
          avatar: null,
        ),
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      DocumentCommentModel(
        id: 'comment_002',
        documentId: 'doc_002',
        content: '收到，马上修改',
        author: const CommentAuthor(
          id: 'user_001',
          name: '张三',
          avatar: null,
        ),
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ]);
  }

  @override
  Future<List<Folder>> getFolders(String projectId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _folders.where((f) => f.projectId == projectId).toList();
  }

  @override
  Future<Folder> createFolder({
    required String projectId,
    required String name,
    String? parentId,
    int sortOrder = 0,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final folder = FolderModel(
      id: 'folder_${DateTime.now().millisecondsSinceEpoch}',
      projectId: projectId,
      name: name,
      parentId: parentId,
      sortOrder: sortOrder,
      createdAt: DateTime.now(),
      createdBy: 'current_user',
    );
    _folders.add(folder);
    return folder;
  }

  @override
  Future<Folder> updateFolder({
    required String folderId,
    String? name,
    int? sortOrder,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _folders.indexWhere((f) => f.id == folderId);
    if (index == -1) throw Exception('Folder not found');
    
    final updated = _folders[index].copyWith(
      name: name ?? _folders[index].name,
      sortOrder: sortOrder ?? _folders[index].sortOrder,
    );
    _folders[index] = FolderModel(
      id: updated.id,
      projectId: updated.projectId,
      name: updated.name,
      parentId: updated.parentId,
      sortOrder: updated.sortOrder,
      documentCount: updated.documentCount,
      createdAt: updated.createdAt,
      createdBy: updated.createdBy,
    );
    return _folders[index];
  }

  @override
  Future<void> deleteFolder(String folderId, {bool force = false}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!force) {
      final hasDocuments = _documents.any((d) => d.folderId == folderId);
      if (hasDocuments) {
        throw Exception('文件夹不为空，无法删除');
      }
    }
    _folders.removeWhere((f) => f.id == folderId);
    if (force) {
      _documents.removeWhere((d) => d.folderId == folderId);
    }
  }

  @override
  Future<List<Document>> getDocuments({
    required String projectId,
    String? folderId,
    DocumentType? type,
    String? keyword,
    int page = 1,
    int pageSize = 20,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    var result = _documents.where((d) => d.projectId == projectId);
    
    if (folderId != null) {
      result = result.where((d) => d.folderId == folderId);
    }
    if (type != null) {
      result = result.where((d) => d.type == type);
    }
    if (keyword != null && keyword.isNotEmpty) {
      result = result.where((d) => 
        d.title.toLowerCase().contains(keyword.toLowerCase()));
    }
    
    // 列表不返回 content，模拟后端列表接口只返回基本信息
    return result.map((doc) => DocumentModel(
      id: doc.id,
      projectId: doc.projectId,
      folderId: doc.folderId,
      title: doc.title,
      type: doc.type,
      status: doc.status,
      fileName: doc.fileName,
      fileSize: doc.fileSize,
      fileUrl: doc.fileUrl,
      downloadUrl: doc.downloadUrl,
      content: null, // 列表不返回 content
      version: doc.version,
      versionCount: doc.versionCount,
      uploader: doc.uploader,
      createdAt: doc.createdAt,
      updatedAt: doc.updatedAt,
    )).toList();
  }

  @override
  Future<Document> getDocument(String documentId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final doc = _documents.firstWhere(
      (d) => d.id == documentId,
      orElse: () => throw Exception('Document not found'),
    );
    // 返回完整的文档信息（包括 content）
    // 对于 Markdown 类型，确保有 content
    if (doc.type == DocumentType.markdown && (doc.content == null || doc.content!.isEmpty)) {
      // 如果 content 为空，从原始数据中查找
      final originalDoc = _documents.firstWhere((d) => d.id == documentId);
      return originalDoc;
    }
    return doc;
  }

  @override
  Future<Document> createMarkdownDocument({
    required String projectId,
    required String title,
    String? folderId,
    String content = '',
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final doc = DocumentModel(
      id: 'doc_${DateTime.now().millisecondsSinceEpoch}',
      projectId: projectId,
      folderId: folderId,
      title: title,
      type: DocumentType.markdown,
      status: DocumentStatus.editable,
      fileName: '$title.md',
      fileSize: content.length,
      fileUrl: '',
      downloadUrl: '',
      content: content,
      uploader: const Uploader(
        id: 'current_user',
        name: '当前用户',
        avatar: null,
      ),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _documents.add(doc);
    return doc;
  }

  @override
  Future<Document> updateMarkdownDocument({
    required String documentId,
    String? title,
    String? content,
    bool saveAsVersion = false,
    String? versionRemark,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _documents.indexWhere((d) => d.id == documentId);
    if (index == -1) throw Exception('Document not found');
    
    final doc = _documents[index];
    String newVersion = doc.version;
    int newVersionCount = doc.versionCount;
    
    if (saveAsVersion) {
      final versionNum = doc.versionCount + 1;
      newVersion = 'v$versionNum.0';
      newVersionCount = versionNum;
    }
    
    final updated = DocumentModel(
      id: doc.id,
      projectId: doc.projectId,
      folderId: doc.folderId,
      title: title ?? doc.title,
      type: doc.type,
      status: doc.status,
      fileName: doc.fileName,
      fileSize: content?.length ?? doc.fileSize,
      fileUrl: doc.fileUrl,
      downloadUrl: doc.downloadUrl,
      content: content ?? doc.content,
      version: newVersion,
      versionCount: newVersionCount,
      uploader: doc.uploader,
      createdAt: doc.createdAt,
      updatedAt: DateTime.now(),
    );
    _documents[index] = updated;
    return updated;
  }

  @override
  Future<Document> moveDocument({
    required String documentId,
    String? folderId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _documents.indexWhere((d) => d.id == documentId);
    if (index == -1) throw Exception('Document not found');
    
    final updated = _documents[index].copyWith(folderId: folderId);
    _documents[index] = DocumentModel.fromEntity(updated);
    return _documents[index];
  }

  @override
  Future<void> deleteDocument(String documentId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _documents.removeWhere((d) => d.id == documentId);
    _comments.removeWhere((c) => c.documentId == documentId);
  }

  @override
  Future<Document> uploadFile({
    required String projectId,
    required String filePath,
    String? folderId,
    String? title,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    final fileName = filePath.split('/').last;
    final extension = fileName.split('.').last.toLowerCase();
    
    DocumentType type;
    switch (extension) {
      case 'md':
        type = DocumentType.markdown;
        break;
      case 'doc':
      case 'docx':
        type = DocumentType.word;
        break;
      case 'xls':
      case 'xlsx':
        type = DocumentType.excel;
        break;
      case 'ppt':
      case 'pptx':
        type = DocumentType.powerpoint;
        break;
      case 'pdf':
        type = DocumentType.pdf;
        break;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        type = DocumentType.image;
        break;
      default:
        type = DocumentType.other;
    }
    
    final doc = DocumentModel(
      id: 'doc_${DateTime.now().millisecondsSinceEpoch}',
      projectId: projectId,
      folderId: folderId,
      title: title ?? fileName,
      type: type,
      status: type == DocumentType.markdown 
          ? DocumentStatus.editable 
          : DocumentStatus.previewOnly,
      fileName: fileName,
      fileSize: 1024000, // 模拟1MB
      fileUrl: 'https://example.com/uploads/$fileName',
      downloadUrl: 'https://example.com/uploads/$fileName?download=1',
      uploader: const Uploader(
        id: 'current_user',
        name: '当前用户',
        avatar: null,
      ),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _documents.add(doc);
    return doc;
  }

  @override
  Future<Document> uploadFileFromBytes({
    required String projectId,
    required List<int> fileBytes,
    required String fileName,
    String? folderId,
    String? title,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    final extension = fileName.split('.').last.toLowerCase();
    
    DocumentType type;
    switch (extension) {
      case 'md':
        type = DocumentType.markdown;
        break;
      case 'doc':
      case 'docx':
        type = DocumentType.word;
        break;
      case 'xls':
      case 'xlsx':
        type = DocumentType.excel;
        break;
      case 'ppt':
      case 'pptx':
        type = DocumentType.powerpoint;
        break;
      case 'pdf':
        type = DocumentType.pdf;
        break;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        type = DocumentType.image;
        break;
      default:
        type = DocumentType.other;
    }
    
    final doc = DocumentModel(
      id: 'doc_${DateTime.now().millisecondsSinceEpoch}',
      projectId: projectId,
      folderId: folderId,
      title: title ?? fileName,
      type: type,
      status: type == DocumentType.markdown 
          ? DocumentStatus.editable 
          : DocumentStatus.previewOnly,
      fileName: fileName,
      fileSize: fileBytes.length,
      fileUrl: 'https://example.com/uploads/$fileName',
      downloadUrl: 'https://example.com/uploads/$fileName?download=1',
      uploader: const Uploader(
        id: 'current_user',
        name: '当前用户',
        avatar: null,
      ),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _documents.add(doc);
    return doc;
  }

  @override
  Future<String> getDownloadUrl(String documentId, {bool inline = false}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final doc = _documents.firstWhere(
      (d) => d.id == documentId,
      orElse: () => throw Exception('Document not found'),
    );
    return inline ? doc.fileUrl : doc.downloadUrl;
  }

  @override
  Future<List<DocumentVersion>> getDocumentVersions(String documentId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      DocumentVersion(
        version: 'v2.0',
        versionNumber: 2,
        remark: '添加错误码说明',
        fileSize: 15600,
        createdBy: const Uploader(
          id: 'user_001',
          name: '张三',
          avatar: null,
        ),
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      DocumentVersion(
        version: 'v1.0',
        versionNumber: 1,
        remark: '初始版本',
        fileSize: 12000,
        createdBy: const Uploader(
          id: 'user_001',
          name: '张三',
          avatar: null,
        ),
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
    ];
  }

  @override
  Future<Document> rollbackToVersion({
    required String documentId,
    required String version,
    String? remark,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final doc = await getDocument(documentId);
    return doc.copyWith(
      version: version,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<List<DocumentComment>> getComments({
    required String documentId,
    int page = 1,
    int pageSize = 20,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _comments
        .where((c) => c.documentId == documentId)
        .toList();
  }

  @override
  Future<DocumentComment> createComment({
    required String documentId,
    required String content,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final comment = DocumentCommentModel(
      id: 'comment_${DateTime.now().millisecondsSinceEpoch}',
      documentId: documentId,
      content: content,
      author: const CommentAuthor(
        id: 'current_user',
        name: '当前用户',
        avatar: null,
      ),
      createdAt: DateTime.now(),
    );
    _comments.add(comment);
    return comment;
  }

  @override
  Future<void> deleteComment(String commentId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _comments.removeWhere((c) => c.id == commentId);
  }

  @override
  Future<DocumentStatistics> getStatistics(String projectId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final docs = _documents.where((d) => d.projectId == projectId);
    final typeDist = <DocumentType, int>{};
    for (final doc in docs) {
      typeDist[doc.type] = (typeDist[doc.type] ?? 0) + 1;
    }
    return DocumentStatistics(
      totalDocuments: docs.length,
      totalSize: docs.fold(0, (sum, d) => sum + d.fileSize),
      typeDistribution: typeDist,
      recentUploads: docs.where((d) => 
        d.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 7)))
      ).length,
    );
  }

  @override
  Future<List<Document>> searchDocuments({
    required String projectId,
    required String keyword,
    DocumentType? type,
    int page = 1,
    int pageSize = 20,
  }) async {
    return getDocuments(
      projectId: projectId,
      type: type,
      keyword: keyword,
      page: page,
      pageSize: pageSize,
    );
  }
}

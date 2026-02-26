import '../entities/document.dart';
import '../entities/document_comment.dart';
import '../entities/folder.dart';

/// 文档仓库接口
abstract class DocumentRepository {
  // ==================== 文件夹相关 ====================
  
  /// 获取项目下的文件夹列表
  Future<List<Folder>> getFolders(String projectId);
  
  /// 创建文件夹
  Future<Folder> createFolder({
    required String projectId,
    required String name,
    String? parentId,
    int sortOrder = 0,
  });
  
  /// 更新文件夹
  Future<Folder> updateFolder({
    required String folderId,
    String? name,
    int? sortOrder,
  });
  
  /// 删除文件夹
  Future<void> deleteFolder(String folderId, {bool force = false});

  // ==================== 文档相关 ====================
  
  /// 获取文档列表
  Future<List<Document>> getDocuments({
    required String projectId,
    String? folderId,
    DocumentType? type,
    String? keyword,
    int page = 1,
    int pageSize = 20,
  });
  
  /// 获取文档详情
  Future<Document> getDocument(String documentId);
  
  /// 新建Markdown文档
  Future<Document> createMarkdownDocument({
    required String projectId,
    required String title,
    String? folderId,
    String content = '',
  });
  
  /// 编辑Markdown文档
  Future<Document> updateMarkdownDocument({
    required String documentId,
    String? title,
    String? content,
    bool saveAsVersion = false,
    String? versionRemark,
  });
  
  /// 移动文档到文件夹
  Future<Document> moveDocument({
    required String documentId,
    String? folderId,
  });
  
  /// 删除文档
  Future<void> deleteDocument(String documentId);

  // ==================== 文件上传/下载 ====================
  
  /// 上传文件（使用文件路径 - 适用于移动端/桌面端）
  Future<Document> uploadFile({
    required String projectId,
    required String filePath,
    String? folderId,
    String? title,
  });
  
  /// 上传文件（使用文件字节 - 适用于 Web）
  Future<Document> uploadFileFromBytes({
    required String projectId,
    required List<int> fileBytes,
    required String fileName,
    String? folderId,
    String? title,
  });
  
  /// 获取下载链接
  Future<String> getDownloadUrl(String documentId, {bool inline = false});

  // ==================== 版本管理 ====================
  
  /// 获取文档版本历史
  Future<List<DocumentVersion>> getDocumentVersions(String documentId);
  
  /// 回滚到指定版本
  Future<Document> rollbackToVersion({
    required String documentId,
    required String version,
    String? remark,
  });

  // ==================== 评论相关 ====================
  
  /// 获取文档评论列表
  Future<List<DocumentComment>> getComments({
    required String documentId,
    int page = 1,
    int pageSize = 20,
  });
  
  /// 发表评论
  Future<DocumentComment> createComment({
    required String documentId,
    required String content,
  });
  
  /// 删除评论
  Future<void> deleteComment(String commentId);

  // ==================== 统计/搜索 ====================
  
  /// 获取项目文档统计
  Future<DocumentStatistics> getStatistics(String projectId);
  
  /// 搜索文档
  Future<List<Document>> searchDocuments({
    required String projectId,
    required String keyword,
    DocumentType? type,
    int page = 1,
    int pageSize = 20,
  });
}

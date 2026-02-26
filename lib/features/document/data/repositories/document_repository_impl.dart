import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/document.dart';
import '../../domain/entities/document_comment.dart';
import '../../domain/entities/folder.dart';
import '../../domain/repositories/document_repository.dart';
import '../models/document_comment_model.dart';
import '../models/document_model.dart';
import '../models/folder_model.dart';

/// 上传URL响应
class UploadUrlResponse {
  final String uploadUrl;
  final String fileKey;  // 后端返回的是 file_key
  final String? fileUrl;
  final int expiresIn;

  UploadUrlResponse({
    required this.uploadUrl,
    required this.fileKey,
    this.fileUrl,
    required this.expiresIn,
  });

  factory UploadUrlResponse.fromJson(Map<String, dynamic> json) {
    return UploadUrlResponse(
      uploadUrl: json['upload_url'] as String,  // 后端是 snake_case
      fileKey: json['file_key'] as String,     // 后端是 snake_case
      fileUrl: json['file_url'] as String?,
      expiresIn: json['expires_in'] as int? ?? 300,
    );
  }
}

/// 文档仓库实现（连接真实后端）
class DocumentRepositoryImpl implements DocumentRepository {
  final ApiClient _apiClient;
  final Dio _dio;

  DocumentRepositoryImpl({ApiClient? apiClient, Dio? dio})
      : _apiClient = apiClient ?? ApiClient(),
        _dio = dio ?? Dio();

  // ==================== 文件夹相关 ====================

  @override
  Future<List<Folder>> getFolders(String projectId) async {
    try {
      final response = await _apiClient.get(
        '/projects/$projectId/folders/',
      );
      
      if (response.data['code'] == 0 || response.data['code'] == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((json) => FolderModel.fromJson(json)).toList();
      }
      throw Exception(response.data['message'] ?? '获取文件夹列表失败');
    } catch (e) {
      throw Exception('获取文件夹列表失败: $e');
    }
  }

  @override
  Future<Folder> createFolder({
    required String projectId,
    required String name,
    String? parentId,
    int sortOrder = 0,
  }) async {
    try {
      final response = await _apiClient.post(
        '/projects/$projectId/folders/',
        data: {
          'name': name,
          'parent_id': parentId,
          'sort_order': sortOrder,
        },
      );
      
      if (response.data['code'] == 0 || response.data['code'] == 200) {
        return FolderModel.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? '创建文件夹失败');
    } catch (e) {
      throw Exception('创建文件夹失败: $e');
    }
  }

  @override
  Future<Folder> updateFolder({
    required String folderId,
    String? name,
    int? sortOrder,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (sortOrder != null) data['sort_order'] = sortOrder;

      final response = await _apiClient.put(
        '/folders/$folderId/',
        data: data,
      );
      
      if (response.data['code'] == 0 || response.data['code'] == 200) {
        return FolderModel.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? '更新文件夹失败');
    } catch (e) {
      throw Exception('更新文件夹失败: $e');
    }
  }

  @override
  Future<void> deleteFolder(String folderId, {bool force = false}) async {
    try {
      final response = await _apiClient.delete(
        '/folders/$folderId/',
        queryParameters: {'force': force},
      );
      
      if (response.data['code'] != 0 && response.data['code'] != 200) {
        throw Exception(response.data['message'] ?? '删除文件夹失败');
      }
    } catch (e) {
      throw Exception('删除文件夹失败: $e');
    }
  }

  // ==================== 文档相关 ====================

  @override
  Future<List<Document>> getDocuments({
    required String projectId,
    String? folderId,
    DocumentType? type,
    String? keyword,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };
      if (folderId != null) queryParams['folder_id'] = folderId;
      if (type != null) queryParams['type'] = type.name;
      if (keyword != null && keyword.isNotEmpty) queryParams['keyword'] = keyword;

      final response = await _apiClient.get(
        '/projects/$projectId/documents/',
        queryParameters: queryParams,
      );
      
      if (response.data['code'] == 0 || response.data['code'] == 200) {
        final data = response.data['data'];
        // 处理嵌套数据结构：有些接口返回 {code, data: {list, pagination}}
        final innerData = data is Map<String, dynamic> && data.containsKey('data') 
            ? data['data'] 
            : data;
        final List<dynamic> list = innerData is List 
            ? innerData 
            : (innerData['list'] ?? []);
        return list.map((json) => DocumentModel.fromJson(json)).toList();
      }
      throw Exception(response.data['message'] ?? '获取文档列表失败');
    } catch (e) {
      throw Exception('获取文档列表失败: $e');
    }
  }

  @override
  Future<Document> getDocument(String documentId) async {
    try {
      final response = await _apiClient.get(
        '/documents/$documentId/',
      );
      
      if (response.data['code'] == 0 || response.data['code'] == 200) {
        return DocumentModel.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? '获取文档详情失败');
    } catch (e) {
      throw Exception('获取文档详情失败: $e');
    }
  }

  @override
  Future<Document> createMarkdownDocument({
    required String projectId,
    required String title,
    String? folderId,
    String content = '',
  }) async {
    try {
      final response = await _apiClient.post(
        '/projects/$projectId/documents/markdown/',
        data: {
          'title': title,
          if (folderId != null) 'folder_id': folderId,
          'content': content,
        },
      );
      
      if (response.data['code'] == 0 || response.data['code'] == 200) {
        return DocumentModel.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? '创建文档失败');
    } catch (e) {
      throw Exception('创建文档失败: $e');
    }
  }

  @override
  Future<Document> updateMarkdownDocument({
    required String documentId,
    String? title,
    String? content,
    bool saveAsVersion = false,
    String? versionRemark,
  }) async {
    try {
      final data = <String, dynamic>{
        'save_as_version': saveAsVersion,
      };
      if (title != null) data['title'] = title;
      if (content != null) data['content'] = content;
      if (versionRemark != null) data['version_remark'] = versionRemark;

      final response = await _apiClient.put(
        '/documents/$documentId/',
        data: data,
      );
      
      if (response.data['code'] == 0 || response.data['code'] == 200) {
        return DocumentModel.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? '更新文档失败');
    } catch (e) {
      throw Exception('更新文档失败: $e');
    }
  }

  @override
  Future<Document> moveDocument({
    required String documentId,
    String? folderId,
  }) async {
    try {
      final response = await _apiClient.put(
        '/api/documents/$documentId/move/',
        data: {'folder_id': folderId},
      );
      
      if (response.data['code'] == 0 || response.data['code'] == 200) {
        return DocumentModel.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? '移动文档失败');
    } catch (e) {
      throw Exception('移动文档失败: $e');
    }
  }

  @override
  Future<void> deleteDocument(String documentId) async {
    try {
      final response = await _apiClient.delete(
        '/documents/$documentId/',
      );
      
      if (response.data['code'] != 0 && response.data['code'] != 200) {
        throw Exception(response.data['message'] ?? '删除文档失败');
      }
    } catch (e) {
      throw Exception('删除文档失败: $e');
    }
  }

  // ==================== 文件上传/下载（预签名URL方式）====================

  /// 步骤1: 申请上传URL
  Future<UploadUrlResponse> _getUploadUrl({
    required String projectId,
    required String fileName,
    int? fileSize,
    String? folderId,
    String? title,
  }) async {
    try {
      final fileType = _getFileType(fileName);
      
      final response = await _apiClient.post(
        '/projects/$projectId/documents/upload-url/',
        data: {
          'file_name': fileName,
          'file_type': fileType,
          if (fileSize != null) 'file_size': fileSize,
          if (folderId != null) 'folder_id': folderId,
          if (title != null) 'title': title,
        },
      );
      
      if (response.data['code'] == 0 || response.data['code'] == 200) {
        return UploadUrlResponse.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? '获取上传链接失败');
    } catch (e) {
      throw Exception('获取上传链接失败: $e');
    }
  }
  
  /// 获取文件类型（用于后端）
  String _getFileType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'md':
        return 'markdown';
      case 'txt':
        return 'text';
      case 'pdf':
        return 'pdf';
      case 'doc':
      case 'docx':
        return 'word';
      case 'xls':
      case 'xlsx':
        return 'excel';
      case 'ppt':
      case 'pptx':
        return 'powerpoint';
      case 'jpg':
      case 'jpeg':
        return 'image';
      case 'png':
        return 'image';
      case 'gif':
        return 'image';
      case 'webp':
        return 'image';
      default:
        return 'other';
    }
  }

  /// 步骤2: 直接上传文件到存储服务（使用文件路径）
  Future<void> _uploadToStorage(String uploadUrl, String filePath) async {
    try {
      final file = File(filePath);
      final fileBytes = await file.readAsBytes();
      final fileName = filePath.split('/').last;
      
      await _uploadBytesToStorage(uploadUrl, fileBytes, fileName);
    } catch (e) {
      throw Exception('上传文件到存储服务失败: $e');
    }
  }
  
  /// 步骤2: 直接上传文件到存储服务（使用字节数据）
  Future<void> _uploadBytesToStorage(
    String uploadUrl,
    List<int> fileBytes,
    String fileName,
  ) async {
    try {
      // 根据文件扩展名确定Content-Type
      final contentType = _getContentType(fileName);
      
      debugPrint('[Upload] 开始上传文件到MinIO');
      debugPrint('[Upload] URL: $uploadUrl');
      debugPrint('[Upload] Content-Type: $contentType');
      debugPrint('[Upload] 文件大小: ${fileBytes.length} bytes');
      
      // 对于MinIO/S3预签名URL，使用Uint8List直接上传
      // 注意：预签名URL已经包含了认证信息，不需要额外headers
      final response = await _dio.put(
        uploadUrl,
        data: Uint8List.fromList(fileBytes),
        options: Options(
          headers: {
            'Content-Type': contentType,
          },
          validateStatus: (status) => true, // 接受所有状态码以便调试
          sendTimeout: const Duration(minutes: 5),
          receiveTimeout: const Duration(minutes: 5),
        ),
      );
      
      debugPrint('[Upload] 响应状态码: ${response.statusCode}');
      debugPrint('[Upload] 响应数据: ${response.data}');
      
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('文件上传失败: HTTP ${response.statusCode}, 响应: ${response.data}');
      }
      
      debugPrint('[Upload] 文件上传成功');
    } catch (e) {
      debugPrint('[Upload] 上传失败: $e');
      throw Exception('上传文件到存储服务失败: $e');
    }
  }

  /// 步骤3: 通知后端上传完成
  Future<Document> _confirmUpload({
    required String projectId,
    required String fileKey,
    required String fileName,
    required String fileType,
    required int fileSize,
    String? folderId,
    String? title,
  }) async {
    try {
      debugPrint('[Confirm] 开始确认上传完成');
      debugPrint('[Confirm] file_key: $fileKey');
      debugPrint('[Confirm] file_name: $fileName');
      debugPrint('[Confirm] file_type: $fileType');
      debugPrint('[Confirm] file_size: $fileSize');
      
      final response = await _apiClient.post(
        '/projects/$projectId/documents/confirm-upload/',
        data: {
          'file_key': fileKey,
          'file_name': fileName,
          'file_type': fileType,
          'file_size': fileSize,
          if (folderId != null) 'folder_id': folderId,
          if (title != null) 'title': title,
        },
      );
      
      debugPrint('[Confirm] 响应: ${response.data}');
      
      if (response.data['code'] == 0 || response.data['code'] == 200) {
        return DocumentModel.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? '确认上传失败');
    } catch (e) {
      throw Exception('确认上传失败: $e');
    }
  }

  /// 获取Content-Type
  String _getContentType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'md':
        return 'text/markdown';
      case 'txt':
        return 'text/plain';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }

  @override
  Future<Document> uploadFile({
    required String projectId,
    required String filePath,
    String? folderId,
    String? title,
  }) async {
    final fileName = filePath.split('/').last;
    
    // 获取文件大小
    final file = File(filePath);
    final fileSize = await file.length();
    
    // 步骤1: 申请上传URL
    final uploadInfo = await _getUploadUrl(
      projectId: projectId,
      fileName: fileName,
      fileSize: fileSize,
      folderId: folderId,
      title: title,
    );
    
    // 步骤2: 直接上传文件到存储服务
    await _uploadToStorage(uploadInfo.uploadUrl, filePath);
    
    // 步骤3: 通知后端上传完成
    return await _confirmUpload(
      projectId: projectId,
      fileKey: uploadInfo.fileKey,
      fileName: fileName,
      fileType: _getFileType(fileName),
      fileSize: fileSize,
      folderId: folderId,
      title: title ?? fileName,
    );
  }

  @override
  Future<Document> uploadFileFromBytes({
    required String projectId,
    required List<int> fileBytes,
    required String fileName,
    String? folderId,
    String? title,
  }) async {
    // 步骤1: 申请上传URL
    final uploadInfo = await _getUploadUrl(
      projectId: projectId,
      fileName: fileName,
      fileSize: fileBytes.length,
      folderId: folderId,
      title: title,
    );
    
    // 步骤2: 直接上传文件字节到存储服务
    await _uploadBytesToStorage(uploadInfo.uploadUrl, fileBytes, fileName);
    
    // 步骤3: 通知后端上传完成
    return await _confirmUpload(
      projectId: projectId,
      fileKey: uploadInfo.fileKey,
      fileName: fileName,
      fileType: _getFileType(fileName),
      fileSize: fileBytes.length,
      folderId: folderId,
      title: title ?? fileName,
    );
  }

  @override
  Future<String> getDownloadUrl(String documentId, {bool inline = false}) async {
    try {
      final response = await _apiClient.get(
        '/documents/$documentId/download/',
        queryParameters: {'inline': inline},
      );
      
      if (response.data['code'] == 0 || response.data['code'] == 200) {
        return response.data['data']['download_url'] ?? 
               response.data['data']['url'] ?? 
               response.data['data']['downloadUrl'];
      }
      throw Exception(response.data['message'] ?? '获取下载链接失败');
    } catch (e) {
      throw Exception('获取下载链接失败: $e');
    }
  }

  // ==================== 版本管理 ====================

  @override
  Future<List<DocumentVersion>> getDocumentVersions(String documentId) async {
    try {
      final response = await _apiClient.get(
        '/documents/$documentId/versions/',
      );
      
      if (response.data['code'] == 0 || response.data['code'] == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((json) => DocumentVersionModel.fromJson(json)).toList();
      }
      throw Exception(response.data['message'] ?? '获取版本历史失败');
    } catch (e) {
      throw Exception('获取版本历史失败: $e');
    }
  }

  @override
  Future<Document> rollbackToVersion({
    required String documentId,
    required String version,
    String? remark,
  }) async {
    try {
      final response = await _apiClient.post(
        '/documents/$documentId/rollback/',
        data: {
          'version': version,
          if (remark != null) 'remark': remark,
        },
      );
      
      if (response.data['code'] == 0 || response.data['code'] == 200) {
        return DocumentModel.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? '回滚版本失败');
    } catch (e) {
      throw Exception('回滚版本失败: $e');
    }
  }

  // ==================== 评论相关 ====================

  @override
  Future<List<DocumentComment>> getComments({
    required String documentId,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        '/documents/$documentId/comments/',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
        },
      );
      
      if (response.data['code'] == 0 || response.data['code'] == 200) {
        final data = response.data['data'];
        final List<dynamic> list = data is List ? data : (data['list'] ?? []);
        return list.map((json) => DocumentCommentModel.fromJson(json)).toList();
      }
      throw Exception(response.data['message'] ?? '获取评论列表失败');
    } catch (e) {
      throw Exception('获取评论列表失败: $e');
    }
  }

  @override
  Future<DocumentComment> createComment({
    required String documentId,
    required String content,
  }) async {
    try {
      final response = await _apiClient.post(
        '/documents/$documentId/comments/',
        data: {'content': content},
      );
      
      if (response.data['code'] == 0 || response.data['code'] == 200) {
        return DocumentCommentModel.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? '发表评论失败');
    } catch (e) {
      throw Exception('发表评论失败: $e');
    }
  }

  @override
  Future<void> deleteComment(String commentId) async {
    try {
      final response = await _apiClient.delete(
        '/comments/$commentId/',
      );
      
      if (response.data['code'] != 0 && response.data['code'] != 200) {
        throw Exception(response.data['message'] ?? '删除评论失败');
      }
    } catch (e) {
      throw Exception('删除评论失败: $e');
    }
  }

  // ==================== 统计/搜索 ====================

  @override
  Future<DocumentStatistics> getStatistics(String projectId) async {
    try {
      final response = await _apiClient.get(
        '/projects/$projectId/documents/statistics/',
      );
      
      if (response.data['code'] == 0 || response.data['code'] == 200) {
        return DocumentStatisticsResponse.fromJson(response.data['data']).toEntity();
      }
      throw Exception(response.data['message'] ?? '获取统计信息失败');
    } catch (e) {
      throw Exception('获取统计信息失败: $e');
    }
  }

  @override
  Future<List<Document>> searchDocuments({
    required String projectId,
    required String keyword,
    DocumentType? type,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'keyword': keyword,
        'page': page,
        'page_size': pageSize,
      };
      if (type != null) queryParams['type'] = type.name;

      final response = await _apiClient.get(
        '/projects/$projectId/documents/search/',
        queryParameters: queryParams,
      );
      
      if (response.data['code'] == 0 || response.data['code'] == 200) {
        final data = response.data['data'];
        final List<dynamic> list = data is List ? data : (data['list'] ?? []);
        return list.map((json) => DocumentModel.fromJson(json)).toList();
      }
      throw Exception(response.data['message'] ?? '搜索文档失败');
    } catch (e) {
      throw Exception('搜索文档失败: $e');
    }
  }
}

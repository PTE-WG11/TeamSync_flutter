import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/attachment.dart';
import '../../domain/repositories/attachment_repository.dart';
import '../models/attachment_model.dart';

/// 附件仓库实现
class AttachmentRepositoryImpl implements AttachmentRepository {
  final ApiClient _apiClient;

  AttachmentRepositoryImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  @override
  Future<List<Attachment>> getTaskAttachments(int taskId) async {
    try {
      final response = await _apiClient.get('/files/tasks/$taskId/attachments/');
      
      if (response.data['code'] == 200) {
        final List<dynamic> data = response.data['data'] as List<dynamic>? ?? [];
        return data
            .map((e) => AttachmentModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('获取附件列表失败: $e');
    }
  }

  @override
  Future<UploadUrlResponse> getUploadUrl(
    int taskId,
    UploadAttachmentRequest request,
  ) async {
    try {
      final response = await _apiClient.post(
        '/files/tasks/$taskId/upload-url/',
        data: request.toJson(),
      );

      if (response.data['code'] == 200) {
        return UploadUrlResponse.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
      }
      throw Exception(response.data['message'] ?? '获取上传URL失败');
    } catch (e) {
      throw Exception('获取上传URL失败: $e');
    }
  }

  @override
  Future<void> uploadFileToStorage(
    String uploadUrl,
    List<int> fileBytes,
    String fileType,
  ) async {
    try {
      // 使用 Dio 直接上传到预签名 URL（不经过 ApiClient，因为不需要认证头）
      final dio = Dio();
      await dio.put(
        uploadUrl,
        data: Stream.fromIterable(fileBytes.map((e) => [e])),
        options: Options(
          headers: {
            'Content-Type': fileType,
            'Content-Length': fileBytes.length.toString(),
          },
        ),
      );
    } catch (e) {
      throw Exception('文件上传失败: $e');
    }
  }

  @override
  Future<Attachment> confirmUpload(
    int taskId,
    ConfirmAttachmentRequest request,
  ) async {
    try {
      final response = await _apiClient.post(
        '/files/tasks/$taskId/attachments/',
        data: request.toJson(),
      );

      if (response.data['code'] == 201 || response.data['code'] == 200) {
        return AttachmentModel.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
      }
      throw Exception(response.data['message'] ?? '确认上传失败');
    } catch (e) {
      throw Exception('确认上传失败: $e');
    }
  }

  @override
  Future<String> getDownloadUrl(int attachmentId) async {
    try {
      final response = await _apiClient.get(
        '/files/attachments/$attachmentId/download-url/',
      );

      if (response.data['code'] == 200) {
        return response.data['data']['download_url'] as String;
      }
      throw Exception(response.data['message'] ?? '获取下载URL失败');
    } catch (e) {
      throw Exception('获取下载URL失败: $e');
    }
  }

  @override
  Future<void> deleteAttachment(int attachmentId) async {
    try {
      final response = await _apiClient.delete(
        '/files/attachments/$attachmentId/',
      );

      if (response.data['code'] != 200 && response.data['code'] != 204) {
        throw Exception(response.data['message'] ?? '删除附件失败');
      }
    } catch (e) {
      throw Exception('删除附件失败: $e');
    }
  }
}

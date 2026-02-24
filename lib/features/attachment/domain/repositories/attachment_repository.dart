import '../entities/attachment.dart';

/// 附件仓库接口
abstract class AttachmentRepository {
  /// 获取任务附件列表
  Future<List<Attachment>> getTaskAttachments(int taskId);

  /// 获取上传URL
  Future<UploadUrlResponse> getUploadUrl(int taskId, UploadAttachmentRequest request);

  /// 上传文件到存储（直接PUT上传）
  Future<void> uploadFileToStorage(String uploadUrl, List<int> fileBytes, String fileType);

  /// 确认上传并创建附件记录
  Future<Attachment> confirmUpload(int taskId, ConfirmAttachmentRequest request);

  /// 获取下载URL
  Future<String> getDownloadUrl(int attachmentId);

  /// 删除附件
  Future<void> deleteAttachment(int attachmentId);
}

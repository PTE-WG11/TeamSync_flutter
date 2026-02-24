# 修改记录

## 2026-02-12 任务管理和附件功能完善

### 1. 日期格式修复
**问题：** 后端要求 `YYYY-MM-DD` 格式，但前端发送了 ISO8601 格式

**修复文件：**
- `lib/features/task/domain/entities/task.dart`
  - `CreateTaskRequest.toJson()` - 日期格式改为 `YYYY-MM-DD`
  - `CreateSubTaskRequest.toJson()` - 日期格式改为 `YYYY-MM-DD`
  - `UpdateTaskRequest.toJson()` - 日期格式改为 `YYYY-MM-DD`

### 2. 权限控制完善
**新增文件：**
- `lib/core/permissions/permission_service.dart`
  - 添加 `canUploadAttachment(taskAssigneeId)` - 检查是否可以上传附件
  - 添加 `canDeleteAttachment(uploadedById)` - 检查是否可以删除附件
  - 添加 `canDownloadAttachment` - 检查是否可以下载附件
  - 添加 `canCreateSubTask(parentTaskAssigneeId)` - 检查是否可以创建子任务

**权限规则：**
| 功能 | 管理员 | 成员 | 访客 |
|------|--------|------|------|
| 上传附件 | 任何任务 | 仅自己的任务 | ❌ |
| 删除附件 | 任何附件 | 仅自己的附件 | ❌ |
| 下载附件 | ✅ | ✅ | ❌ |
| 创建子任务 | 仅自己的任务 | 仅自己的任务 | ❌ |
| 编辑主任务 | 所有字段 | 仅日期 | ❌ |

### 3. 附件管理功能
**新增文件：**
- `lib/features/attachment/domain/entities/attachment.dart` - 附件实体
- `lib/features/attachment/domain/repositories/attachment_repository.dart` - 仓库接口
- `lib/features/attachment/data/models/attachment_model.dart` - 数据模型
- `lib/features/attachment/data/repositories/attachment_repository_impl.dart` - 仓库实现
- `lib/features/attachment/presentation/widgets/attachment_uploader.dart` - 上传组件
- `lib/features/attachment/attachment.dart` - 模块导出

**依赖更新：**
- `pubspec.yaml` - 添加 `file_picker: ^8.0.0`

**上传流程：**
1. 选择文件
2. 获取预签名上传 URL (`POST /api/files/tasks/{task_id}/upload-url/`)
3. 直接上传到存储 (PUT 请求)
4. 确认上传并创建记录 (`POST /api/files/tasks/{task_id}/attachments/`)

### 4. 任务详情对话框
**新增文件：**
- `lib/features/task/presentation/widgets/task_detail_dialog.dart`
  - 展示任务完整信息
  - 附件管理（上传/下载/删除）
  - 子任务列表（带状态切换）
  - 权限控制（根据角色显示不同操作）

**使用方式：**
- 在任务列表双击任务卡片打开详情
- 或在主任务卡片上点击展开后操作

### 5. 子任务状态切换
**修改文件：**
- `lib/features/task/presentation/bloc/task_bloc.dart`
  - 状态轮换：planning → pending → in_progress → completed → planning

**UI 更新：**
- `lib/features/task/presentation/widgets/list_view.dart`
  - 子任务项显示状态圆圈
  - 点击圆圈切换状态

### 6. 子任务创建权限
**修改文件：**
- `lib/features/task/presentation/widgets/create_subtask_dialog.dart`
  - 添加权限检查：只有父任务负责人可以创建子任务
  - 无权限时显示提示并关闭对话框

### 7. API 文档更新
**修改文件：**
- `docs/API_ENDPOINTS.md`
  - 添加子任务权限说明
  - 添加任务编辑权限矩阵

## 待完成事项

### 前端
1. [ ] 实现任务编辑对话框（支持管理员编辑所有字段，成员编辑日期）
2. [ ] 实现附件下载功能（目前只有UI）
3. [ ] 任务列表项添加"查看详情"按钮（替代双击）
4. [ ] 看板视图添加任务详情支持

### 后端
1. [ ] 确认 `/api/files/tasks/{task_id}/attachments/` 接口返回附件列表
2. [ ] 确认附件上传预签名 URL 流程正常工作

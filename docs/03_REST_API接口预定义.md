# TeamSync REST API 接口预定义文档

## 📋 文档信息
- **项目名称**: TeamSync 团队协作管理系统
- **版本**: v1.0
- **协议**: RESTful API
- **认证方式**: JWT (Access Token + Refresh Token)
- **数据格式**: JSON
- **日期**: 2026-02-10

---

## 1. API 规范概述

### 1.1 基础信息

| 属性 | 说明 |
|------|------|
| **基础URL** | `https://api.teamsync.com/v1` (开发环境: `http://localhost:8000/api`) |
| **协议** | HTTPS (开发环境 HTTP) |
| **字符编码** | UTF-8 |
| **请求格式** | `application/json` |
| **响应格式** | `application/json` |

### 1.2 认证方式

所有 API 请求（除登录/注册外）需要在 Header 中携带 Access Token:

```http
Authorization: Bearer <access_token>
```

Token 过期时返回 401，需使用 Refresh Token 换取新的 Access Token。

### 1.3 通用响应格式

#### 成功响应

```json
{
  "code": 200,
  "message": "success",
  "data": { ... }
}
```

#### 错误响应

```json
{
  "code": 400,
  "message": "错误描述",
  "errors": {
    "field_name": ["错误详情"]
  }
}
```

#### 分页响应

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "items": [...],
    "pagination": {
      "page": 1,
      "page_size": 20,
      "total": 100,
      "total_pages": 5,
      "has_next": true,
      "has_previous": false
    }
  }
}
```

### 1.4 HTTP 状态码

| 状态码 | 含义 | 使用场景 |
|--------|------|---------|
| 200 | OK | 请求成功 |
| 201 | Created | 创建成功 |
| 204 | No Content | 删除成功 |
| 400 | Bad Request | 请求参数错误 |
| 401 | Unauthorized | 未认证或Token过期 |
| 403 | Forbidden | 无权限访问 |
| 404 | Not Found | 资源不存在 |
| 409 | Conflict | 资源冲突 |
| 422 | Unprocessable Entity | 业务逻辑错误 |
| 429 | Too Many Requests | 请求过于频繁 |
| 500 | Internal Server Error | 服务器内部错误 |

---

## 2. 认证模块 (Auth)

### 2.1 用户登录

**POST** `/auth/login/`

#### 请求参数

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| username | string | 是 | 用户名 |
| password | string | 是 | 密码 |

#### 请求示例

```json
{
  "username": "zhangsan",
  "password": "password123"
}
```

#### 响应示例

```json
{
  "code": 200,
  "message": "登录成功",
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIs...",
    "refresh_token": "eyJhbGciOiJIUzI1NiIs...",
    "expires_at": "2026-02-10T09:44:13Z",
    "user": {
      "id": 1,
      "username": "zhangsan",
      "email": "zhangsan@example.com",
      "role": "member",
      "avatar": "https://..."
    }
  }
}
```

---

### 2.2 Token 刷新

**POST** `/auth/refresh/`

#### 请求参数

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| refresh_token | string | 是 | 刷新令牌 |

#### 响应示例

```json
{
  "code": 200,
  "message": "刷新成功",
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIs...",
    "expires_at": "2026-02-10T09:44:13Z"
  }
}
```

---

### 2.3 用户登出

**POST** `/auth/logout/`

#### 请求头

```http
Authorization: Bearer <access_token>
```

#### 响应示例

```json
{
  "code": 200,
  "message": "登出成功",
  "data": null
}
```

---

### 2.4 获取当前用户信息

**GET** `/auth/me/`

#### 响应示例

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "id": 1,
    "username": "zhangsan",
    "email": "zhangsan@example.com",
    "role": "member",
    "role_display": "团队成员",
    "avatar": "https://...",
    "team_id": 1,
    "created_at": "2026-01-01T00:00:00Z",
    "permissions": ["view_project", "edit_own_task", ...]
  }
}
```

---

## 3. 项目管理模块 (Projects)

### 3.1 获取项目列表

**GET** `/projects/`

#### 查询参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| status | string | 否 | 状态过滤: planning, pending, in_progress, completed |
| is_archived | boolean | 否 | 是否包含归档项目，默认 false |
| search | string | 否 | 标题搜索关键词 |
| page | integer | 否 | 页码，默认 1 |
| page_size | integer | 否 | 每页数量，默认 20 |

#### 响应示例

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "items": [
      {
        "id": 1,
        "title": "电商平台重构",
        "description": "对现有电商平台进行技术重构",
        "status": "in_progress",
        "progress": 45.5,
        "member_count": 5,
        "overdue_task_count": 2,
        "is_archived": false,
        "created_by": {
          "id": 2,
          "username": "admin"
        },
        "created_at": "2026-01-15T08:00:00Z",
        "updated_at": "2026-02-09T10:00:00Z"
      }
    ],
    "pagination": {
      "page": 1,
      "page_size": 20,
      "total": 10,
      "total_pages": 1
    }
  }
}
```

---

### 3.2 创建项目

**POST** `/projects/`

> 权限：Super Admin, Team Admin

#### 请求参数

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| title | string | 是 | 项目标题，最大100字符 |
| description | string | 否 | 项目描述 |
| status | string | 否 | 状态，默认 planning |
| start_date | date | 否 | 开始日期，格式 YYYY-MM-DD |
| end_date | date | 否 | 结束日期，格式 YYYY-MM-DD |
| member_ids | array | 是 | 成员ID列表，至少1个 |

#### 请求示例

```json
{
  "title": "新官网开发",
  "description": "公司官方网站开发",
  "status": "planning",
  "start_date": "2026-02-15",
  "end_date": "2026-03-15",
  "member_ids": [1, 2, 3]
}
```

#### 响应示例

```json
{
  "code": 201,
  "message": "项目创建成功",
  "data": {
    "id": 2,
    "title": "新官网开发",
    "description": "公司官方网站开发",
    "status": "planning",
    "progress": 0,
    "is_archived": false,
    "created_by": {
      "id": 1,
      "username": "admin"
    },
    "members": [
      {"id": 1, "username": "zhangsan", "role": "member"},
      {"id": 2, "username": "lisi", "role": "member"},
      {"id": 3, "username": "wangwu", "role": "member"}
    ],
    "created_at": "2026-02-10T08:44:13Z"
  }
}
```

---

### 3.3 获取项目详情

**GET** `/projects/{id}/`

#### 响应示例

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "id": 1,
    "title": "电商平台重构",
    "description": "对现有电商平台进行技术重构",
    "status": "in_progress",
    "progress": 45.5,
    "is_archived": false,
    "start_date": "2026-01-15",
    "end_date": "2026-04-15",
    "created_by": {
      "id": 2,
      "username": "admin"
    },
    "members": [
      {"id": 1, "username": "zhangsan", "role": "member", "avatar": "..."},
      {"id": 2, "username": "lisi", "role": "member", "avatar": "..."}
    ],
    "task_stats": {
      "total": 10,
      "planning": 2,
      "pending": 3,
      "in_progress": 3,
      "completed": 2,
      "overdue": 1
    },
    "created_at": "2026-01-15T08:00:00Z",
    "updated_at": "2026-02-09T10:00:00Z"
  }
}
```

---

### 3.4 更新项目

**PATCH** `/projects/{id}/`

> 权限：Super Admin, Team Admin

#### 请求参数

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| title | string | 否 | 项目标题 |
| description | string | 否 | 项目描述 |
| status | string | 否 | 项目状态 |
| start_date | date | 否 | 开始日期 |
| end_date | date | 否 | 结束日期 |

#### 响应示例

```json
{
  "code": 200,
  "message": "项目更新成功",
  "data": {
    "id": 1,
    "title": "电商平台重构 v2",
    ...
  }
}
```

---

### 3.5 归档项目

**PATCH** `/projects/{id}/archive/`

> 权限：Super Admin, Team Admin

#### 响应示例

```json
{
  "code": 200,
  "message": "项目已归档",
  "data": {
    "id": 1,
    "is_archived": true,
    "archived_at": "2026-02-10T08:44:13Z"
  }
}
```

---

### 3.6 硬删除项目

**DELETE** `/projects/{id}/`

> 权限：Super Admin (仅可删除已归档项目)

#### 响应示例

```json
{
  "code": 204,
  "message": "项目已删除",
  "data": null
}
```

---

### 3.7 获取项目进度统计

**GET** `/projects/{id}/progress/`

> 权限：Super Admin, Team Admin

#### 响应示例

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "project_id": 1,
    "project_title": "电商平台重构",
    "overall_progress": 45.5,
    "main_tasks": {
      "total": 10,
      "completed": 4,
      "in_progress": 3,
      "pending": 2,
      "planning": 1
    },
    "member_progress": [
      {
        "user_id": 1,
        "username": "zhangsan",
        "assigned_tasks": 5,
        "completed_tasks": 3,
        "completion_rate": 60.0
      },
      {
        "user_id": 2,
        "username": "lisi",
        "assigned_tasks": 5,
        "completed_tasks": 1,
        "completion_rate": 20.0
      }
    ],
    "overdue_tasks": [
      {
        "id": 5,
        "title": "数据库设计",
        "assignee": "lisi",
        "end_date": "2026-02-05"
      }
    ]
  }
}
```

---

### 3.8 管理项目成员

**PUT** `/projects/{id}/members/`

> 权限：Super Admin, Team Admin

#### 请求参数

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| member_ids | array | 是 | 成员ID列表（覆盖式更新） |

#### 请求示例

```json
{
  "member_ids": [1, 2, 3, 4]
}
```

---

## 4. 任务管理模块 (Tasks)

### 4.1 获取任务列表

**GET** `/projects/{id}/tasks/`

#### 查询参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| view | string | 否 | 视图类型: tree(树形), flat(扁平)，默认 flat |
| assignee | string | 否 | 负责人过滤: me(当前用户), all(全部), user_id |
| status | string | 否 | 状态过滤，多个用逗号分隔 |
| level | integer | 否 | 层级过滤: 1, 2, 3 |
| search | string | 否 | 标题搜索 |

#### 响应示例 - 扁平视图

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "items": [
      {
        "id": 1,
        "title": "API设计",
        "status": "in_progress",
        "priority": "high",
        "level": 1,
        "assignee": {
          "id": 1,
          "username": "zhangsan"
        },
        "start_date": "2026-02-01",
        "end_date": "2026-02-10",
        "normal_flag": "normal",
        "can_view": true,
        "can_edit": true
      },
      {
        "id": 2,
        "title": "他人任务",
        "status": "private",
        "level": 1,
        "assignee": {
          "id": 2,
          "username": "lisi"
        },
        "can_view": false,
        "message": "该任务未分配给您，无权查看详情"
      }
    ]
  }
}
```

#### 响应示例 - 树形视图

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "items": [
      {
        "id": 1,
        "title": "API设计",
        "level": 1,
        "assignee": {"id": 1, "username": "zhangsan"},
        "children": [
          {
            "id": 3,
            "title": "用户模块API",
            "level": 2,
            "parent_id": 1,
            "children": [
              {
                "id": 4,
                "title": "登录接口",
                "level": 3,
                "parent_id": 3,
                "children": []
              }
            ]
          }
        ]
      }
    ]
  }
}
```

---

### 4.2 创建主任务

**POST** `/projects/{id}/tasks/`

> 权限：Super Admin, Team Admin

#### 请求参数

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| title | string | 是 | 任务标题，最大200字符 |
| description | string | 否 | 任务描述 |
| assignee_id | integer | 是 | 负责人ID |
| status | string | 否 | 状态，默认 planning |
| priority | string | 否 | 优先级: urgent, high, medium, low，默认 medium |
| start_date | date | 否 | 开始日期 |
| end_date | date | 否 | 结束日期 |

#### 请求示例

```json
{
  "title": "数据库设计",
  "description": "设计系统数据库结构",
  "assignee_id": 2,
  "priority": "high",
  "start_date": "2026-02-10",
  "end_date": "2026-02-15"
}
```

#### 响应示例

```json
{
  "code": 201,
  "message": "任务创建成功",
  "data": {
    "id": 5,
    "title": "数据库设计",
    "level": 1,
    "assignee": {
      "id": 2,
      "username": "lisi"
    },
    "status": "planning",
    "priority": "high",
    "start_date": "2026-02-10",
    "end_date": "2026-02-15",
    "created_at": "2026-02-10T08:44:13Z"
  }
}
```

---

### 4.3 创建子任务

**POST** `/tasks/{id}/subtasks/`

> 权限：任务负责人 (parent_task.assignee_id == current_user.id)
> 限制：父任务 level < 3

#### 请求参数

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| title | string | 是 | 任务标题 |
| description | string | 否 | 任务描述 |
| status | string | 否 | 状态，默认 planning |
| priority | string | 否 | 优先级 |
| start_date | date | 否 | 开始日期 |
| end_date | date | 否 | 结束日期 |

> 注意：子任务自动继承父任务的 assignee_id

#### 响应示例

```json
{
  "code": 201,
  "message": "子任务创建成功",
  "data": {
    "id": 6,
    "title": "用户表设计",
    "level": 2,
    "parent_id": 5,
    "path": "/5",
    "assignee": {
      "id": 2,
      "username": "lisi"
    },
    "created_at": "2026-02-10T08:44:13Z"
  }
}
```

---

### 4.4 获取任务详情

**GET** `/tasks/{id}/`

#### 响应示例 - 完整权限

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "id": 1,
    "project_id": 1,
    "title": "API设计",
    "description": "设计RESTful API接口",
    "status": "in_progress",
    "priority": "high",
    "level": 1,
    "parent_id": null,
    "path": "",
    "assignee": {
      "id": 1,
      "username": "zhangsan",
      "avatar": "https://..."
    },
    "start_date": "2026-02-01",
    "end_date": "2026-02-10",
    "normal_flag": "normal",
    "is_overdue_notified": false,
    "attachments": [
      {
        "id": 1,
        "file_name": "api_design.pdf",
        "file_type": "application/pdf",
        "file_size": 1024000,
        "url": "https://minio...",
        "uploaded_by": 1,
        "created_at": "2026-02-05T10:00:00Z"
      }
    ],
    "subtask_count": 3,
    "created_at": "2026-01-20T08:00:00Z",
    "updated_at": "2026-02-08T15:00:00Z"
  }
}
```

#### 响应示例 - 脱敏视图

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "id": 2,
    "title": "他人任务标题",
    "status": "private",
    "level": 1,
    "assignee": "🔒 私有任务",
    "can_view": false,
    "message": "该任务未分配给您，无权查看详情"
  }
}
```

---

### 4.5 更新任务

**PATCH** `/tasks/{id}/`

> 权限：管理员 或 任务负责人

#### 请求参数

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| title | string | 否 | 任务标题 |
| description | string | 否 | 任务描述 |
| status | string | 否 | 状态 |
| priority | string | 否 | 优先级 |
| assignee_id | integer | 否 | 负责人（仅管理员可修改） |
| start_date | date | 否 | 开始日期 |
| end_date | date | 否 | 结束日期 |

#### 响应示例

```json
{
  "code": 200,
  "message": "任务更新成功",
  "data": {
    "id": 1,
    "title": "API设计 v2",
    "status": "completed",
    "updated_at": "2026-02-10T08:44:13Z"
  }
}
```

---

### 4.6 删除任务

**DELETE** `/tasks/{id}/`

> 权限：Super Admin (子任务需先删除)

#### 响应示例

```json
{
  "code": 204,
  "message": "任务已删除",
  "data": null
}
```

---

### 4.7 获取任务变更历史

**GET** `/tasks/{id}/history/`

#### 响应示例

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "task_id": 1,
    "histories": [
      {
        "id": 3,
        "changed_by": {
          "id": 1,
          "username": "zhangsan"
        },
        "field_name": "status",
        "old_value": "in_progress",
        "new_value": "completed",
        "changed_at": "2026-02-10T08:44:13Z"
      },
      {
        "id": 2,
        "changed_by": {
          "id": 2,
          "username": "admin"
        },
        "field_name": "assignee_id",
        "old_value": "3",
        "new_value": "1",
        "changed_at": "2026-02-05T10:00:00Z"
      }
    ]
  }
}
```

---

## 5. 可视化数据模块 (Visualization)

### 5.1 获取甘特图数据

**GET** `/projects/{id}/gantt/`

> 权限：所有项目成员
> 数据范围：管理员返回所有主任务，成员返回自己的主任务+子任务树

#### 查询参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| start_date | date | 否 | 开始日期范围 |
| end_date | date | 否 | 结束日期范围 |
| view_mode | string | 否 | 视图模式: day(默认), week, month |

#### 响应示例

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "project_id": 1,
    "view_mode": "day",
    "date_range": {
      "start": "2026-02-01",
      "end": "2026-02-28"
    },
    "tasks": [
      {
        "id": 1,
        "title": "需求分析",
        "start": "2026-02-01",
        "end": "2026-02-05",
        "progress": 100,
        "status": "completed",
        "assignee": {
          "id": 1,
          "username": "zhangsan",
          "color": "#0D9488"
        },
        "level": 1,
        "dependencies": [],
        "children": [
          {
            "id": 3,
            "title": "用户调研",
            "start": "2026-02-01",
            "end": "2026-02-03",
            "progress": 100,
            "level": 2,
            "children": []
          }
        ]
      },
      {
        "id": 2,
        "title": "系统设计",
        "start": "2026-02-06",
        "end": "2026-02-15",
        "progress": 60,
        "status": "in_progress",
        "assignee": {
          "id": 2,
          "username": "lisi",
          "color": "#0891B2"
        },
        "level": 1,
        "children": []
      }
    ],
    "members": [
      {"id": 1, "username": "zhangsan", "color": "#0D9488"},
      {"id": 2, "username": "lisi", "color": "#0891B2"}
    ]
  }
}
```

---

### 5.2 获取看板数据

**GET** `/projects/{id}/kanban/`

#### 查询参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| assignee | string | 否 | me(我的), all(全部) |

#### 响应示例

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "project_id": 1,
    "columns": [
      {
        "id": "planning",
        "title": "规划中",
        "color": "#94A3B8",
        "tasks": [
          {
            "id": 5,
            "title": "技术选型",
            "priority": "high",
            "assignee": {"id": 1, "username": "zhangsan"},
            "end_date": "2026-02-20",
            "normal_flag": "normal"
          }
        ]
      },
      {
        "id": "pending",
        "title": "待处理",
        "color": "#F59E0B",
        "tasks": [...]
      },
      {
        "id": "in_progress",
        "title": "进行中",
        "color": "#0D9488",
        "tasks": [...]
      },
      {
        "id": "completed",
        "title": "已完成",
        "color": "#10B981",
        "tasks": [...]
      }
    ]
  }
}
```

---

### 5.3 获取日历数据

**GET** `/projects/{id}/calendar/`

#### 查询参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| year | integer | 是 | 年份 |
| month | integer | 是 | 月份 (1-12) |
| assignee | string | 否 | me(我的), all(全部) |

#### 响应示例

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "project_id": 1,
    "year": 2026,
    "month": 2,
    "days": [
      {
        "date": "2026-02-01",
        "tasks": [
          {
            "id": 1,
            "title": "需求分析",
            "status": "completed",
            "assignee": {"id": 1, "username": "zhangsan"}
          }
        ]
      },
      {
        "date": "2026-02-10",
        "tasks": [
          {
            "id": 5,
            "title": "技术选型",
            "status": "planning",
            "is_due": true
          }
        ]
      }
    ]
  }
}
```

---

### 5.4 获取成员首页统计

**GET** `/dashboard/member/`

> 权限：Member

#### 响应示例

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "today": {
      "total": 3,
      "tasks": [
        {
          "id": 1,
          "title": "API设计",
          "project": "电商平台重构",
          "status": "in_progress",
          "end_date": "2026-02-10",
          "is_overdue": false
        }
      ]
    },
    "this_week": {
      "total": 8,
      "tasks": [...]
    },
    "overdue": {
      "total": 1,
      "tasks": [
        {
          "id": 2,
          "title": "数据库设计",
          "project": "电商平台重构",
          "end_date": "2026-02-05",
          "is_overdue": true
        }
      ]
    }
  }
}
```

---

### 5.5 获取管理员仪表盘

**GET** `/dashboard/admin/`

> 权限：Super Admin, Team Admin

#### 响应示例

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "project_overview": {
      "total": 10,
      "active": 8,
      "archived": 2,
      "overdue_count": 3
    },
    "projects": [
      {
        "id": 1,
        "title": "电商平台重构",
        "progress": 45.5,
        "member_count": 5,
        "overdue_task_count": 1,
        "status": "in_progress"
      }
    ],
    "member_workload": [
      {
        "user_id": 1,
        "username": "zhangsan",
        "assigned_tasks": 5,
        "completed_tasks": 3,
        "overdue_tasks": 0
      }
    ]
  }
}
```

---

## 6. 成员管理模块 (Team)

### 6.1 获取团队成员列表

**GET** `/team/members/`

#### 查询参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| role | string | 否 | 角色过滤 |
| search | string | 否 | 用户名搜索 |

#### 响应示例

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "items": [
      {
        "id": 1,
        "username": "admin",
        "email": "admin@example.com",
        "role": "team_admin",
        "role_display": "团队管理员",
        "avatar": "https://...",
        "task_count": 10,
        "created_at": "2026-01-01T00:00:00Z"
      },
      {
        "id": 2,
        "username": "zhangsan",
        "email": "zhangsan@example.com",
        "role": "member",
        "role_display": "团队成员",
        "avatar": "https://...",
        "task_count": 5,
        "created_at": "2026-01-15T08:00:00Z"
      }
    ]
  }
}
```

---

### 6.2 邀请成员

**POST** `/team/invite/`

> 权限：Super Admin, Team Admin

#### 请求参数

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| username | string | 是 | 用户名（已注册用户） |
| role | string | 否 | 角色，默认 member |

#### 请求示例

```json
{
  "username": "newuser",
  "role": "member"
}
```

#### 响应示例 - 成功

```json
{
  "code": 200,
  "message": "邀请成功",
  "data": {
    "user_id": 5,
    "username": "newuser",
    "role": "member",
    "invited_at": "2026-02-10T08:44:13Z"
  }
}
```

#### 响应示例 - 用户不存在

```json
{
  "code": 404,
  "message": "用户不存在",
  "errors": {
    "username": ["该用户名未注册，请先注册账号"]
  }
}
```

---

### 6.3 修改成员角色

**PATCH** `/team/members/{id}/role/`

> 权限：Super Admin, Team Admin

#### 请求参数

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| role | string | 是 | 新角色: team_admin, member |

#### 响应示例

```json
{
  "code": 200,
  "message": "角色修改成功",
  "data": {
    "user_id": 2,
    "username": "zhangsan",
    "role": "team_admin",
    "updated_at": "2026-02-10T08:44:13Z"
  }
}
```

---

### 6.4 移除成员

**DELETE** `/team/members/{id}/`

> 权限：Super Admin, Team Admin

#### 响应示例

```json
{
  "code": 204,
  "message": "成员已移除",
  "data": null
}
```

---

## 7. 通知模块 (Notifications)

### 7.1 获取通知列表

**GET** `/notifications/`

#### 查询参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| is_read | boolean | 否 | 是否已读过滤 |
| page | integer | 否 | 页码 |
| page_size | integer | 否 | 每页数量 |

#### 响应示例

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "unread_count": 5,
    "items": [
      {
        "id": 1,
        "type": "task_assigned",
        "type_display": "任务分配",
        "title": "新任务分配",
        "content": "您被分配了新任务：API设计",
        "task_id": 5,
        "is_read": false,
        "created_at": "2026-02-10T08:44:13Z"
      },
      {
        "id": 2,
        "type": "status_changed",
        "type_display": "状态变更",
        "title": "任务状态变更",
        "content": "任务"数据库设计"状态变为已完成",
        "task_id": 3,
        "is_read": true,
        "created_at": "2026-02-09T15:00:00Z"
      }
    ]
  }
}
```

---

### 7.2 标记通知已读

**PATCH** `/notifications/{id}/read/`

#### 响应示例

```json
{
  "code": 200,
  "message": "已标记为已读",
  "data": {
    "id": 1,
    "is_read": true
  }
}
```

---

### 7.3 标记全部已读

**PATCH** `/notifications/read-all/`

#### 响应示例

```json
{
  "code": 200,
  "message": "全部标记为已读",
  "data": {
    "marked_count": 5
  }
}
```

---

### 7.4 删除通知

**DELETE** `/notifications/{id}/`

#### 响应示例

```json
{
  "code": 204,
  "message": "通知已删除",
  "data": null
}
```

---

## 8. 文件管理模块 (Files)

### 8.1 获取上传预签名URL

**POST** `/tasks/{id}/attachments/upload-url/`

> 权限：任务负责人

#### 请求参数

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| file_name | string | 是 | 文件名 |
| file_type | string | 是 | MIME类型 |
| file_size | integer | 是 | 文件大小(字节) |

#### 响应示例

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "upload_url": "https://minio.example.com/...",
    "file_key": "tasks/1/uuid-filename.pdf",
    "expires_in": 300
  }
}
```

> 前端使用 upload_url 直接上传文件到 MinIO

---

### 8.2 确认上传完成

**POST** `/tasks/{id}/attachments/`

> 权限：任务负责人

#### 请求参数

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| file_key | string | 是 | 上传时的file_key |
| file_name | string | 是 | 原始文件名 |
| file_type | string | 是 | MIME类型 |
| file_size | integer | 是 | 文件大小 |

#### 响应示例

```json
{
  "code": 201,
  "message": "附件上传成功",
  "data": {
    "id": 1,
    "file_name": "api_design.pdf",
    "file_type": "application/pdf",
    "file_size": 1024000,
    "url": "https://minio.example.com/...",
    "uploaded_by": {
      "id": 1,
      "username": "zhangsan"
    },
    "created_at": "2026-02-10T08:44:13Z"
  }
}
```

---

### 8.3 获取附件下载URL

**GET** `/attachments/{id}/download-url/`

#### 响应示例

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "download_url": "https://minio.example.com/...",
    "expires_in": 300
  }
}
```

---

### 8.4 删除附件

**DELETE** `/attachments/{id}/`

> 权限：上传者 或 Admin

#### 响应示例

```json
{
  "code": 204,
  "message": "附件已删除",
  "data": null
}
```

---

## 9. WebSocket 实时通信

### 9.1 连接地址

```
WS wss://api.teamsync.com/ws/notifications/
```

连接时需要在 query parameter 中传递 token:

```
wss://api.teamsync.com/ws/notifications/?token=<access_token>
```

### 9.2 消息格式

#### 客户端 → 服务端

```json
{
  "action": "subscribe",
  "channel": "project_1"
}
```

#### 服务端 → 客户端

```json
{
  "type": "notification",
  "data": {
    "id": 1,
    "type": "task_assigned",
    "title": "新任务分配",
    "content": "您被分配了新任务：API设计",
    "task_id": 5,
    "timestamp": "2026-02-10T08:44:13Z"
  }
}
```

### 9.3 消息类型

| 类型 | 说明 | 触发场景 |
|------|------|---------|
| task_assigned | 任务分配 | 创建任务时 |
| status_changed | 状态变更 | 任务状态更新 |
| due_reminder | 截止提醒 | 定时任务触发 |
| overdue | 逾期通知 | 定时任务触发 |
| member_invited | 成员邀请 | 被邀请加入团队 |

---

## 10. 错误码定义

### 10.1 业务错误码

| 错误码 | 说明 | HTTP状态 |
|--------|------|---------|
| 1001 | 用户名或密码错误 | 401 |
| 1002 | Token已过期 | 401 |
| 1003 | Token无效 | 401 |
| 2001 | 项目不存在 | 404 |
| 2002 | 项目成员已存在 | 409 |
| 2003 | 项目必须至少有一个成员 | 422 |
| 3001 | 任务不存在 | 404 |
| 3002 | 任务层级超过限制(最多3层) | 422 |
| 3003 | 无权创建子任务(非负责人) | 403 |
| 3004 | 无权查看任务详情 | 403 |
| 4001 | 用户不存在 | 404 |
| 4002 | 用户已是团队成员 | 409 |
| 5001 | 文件上传失败 | 500 |
| 5002 | 文件类型不支持 | 400 |
| 5003 | 文件大小超过限制 | 400 |

---

## 11. API 端点汇总

### 认证模块
| 方法 | 端点 | 说明 |
|------|------|------|
| POST | `/auth/login/` | 用户登录 |
| POST | `/auth/refresh/` | Token刷新 |
| POST | `/auth/logout/` | 用户登出 |
| GET | `/auth/me/` | 当前用户信息 |

### 项目管理
| 方法 | 端点 | 说明 |
|------|------|------|
| GET | `/projects/` | 项目列表 |
| POST | `/projects/` | 创建项目 |
| GET | `/projects/{id}/` | 项目详情 |
| PATCH | `/projects/{id}/` | 更新项目 |
| PATCH | `/projects/{id}/archive/` | 归档项目 |
| DELETE | `/projects/{id}/` | 硬删除项目 |
| GET | `/projects/{id}/progress/` | 项目进度 |
| PUT | `/projects/{id}/members/` | 管理成员 |

### 任务管理
| 方法 | 端点 | 说明 |
|------|------|------|
| GET | `/projects/{id}/tasks/` | 任务列表 |
| POST | `/projects/{id}/tasks/` | 创建主任务 |
| POST | `/tasks/{id}/subtasks/` | 创建子任务 |
| GET | `/tasks/{id}/` | 任务详情 |
| PATCH | `/tasks/{id}/` | 更新任务 |
| DELETE | `/tasks/{id}/` | 删除任务 |
| GET | `/tasks/{id}/history/` | 变更历史 |

### 可视化
| 方法 | 端点 | 说明 |
|------|------|------|
| GET | `/projects/{id}/gantt/` | 甘特图数据 |
| GET | `/projects/{id}/kanban/` | 看板数据 |
| GET | `/projects/{id}/calendar/` | 日历数据 |
| GET | `/dashboard/member/` | 成员首页 |
| GET | `/dashboard/admin/` | 管理员仪表盘 |

### 成员管理
| 方法 | 端点 | 说明 |
|------|------|------|
| GET | `/team/members/` | 成员列表 |
| POST | `/team/invite/` | 邀请成员 |
| PATCH | `/team/members/{id}/role/` | 修改角色 |
| DELETE | `/team/members/{id}/` | 移除成员 |

### 通知
| 方法 | 端点 | 说明 |
|------|------|------|
| GET | `/notifications/` | 通知列表 |
| PATCH | `/notifications/{id}/read/` | 标记已读 |
| PATCH | `/notifications/read-all/` | 全部已读 |
| DELETE | `/notifications/{id}/` | 删除通知 |

### 文件
| 方法 | 端点 | 说明 |
|------|------|------|
| POST | `/tasks/{id}/attachments/upload-url/` | 获取上传URL |
| POST | `/tasks/{id}/attachments/` | 确认上传 |
| GET | `/attachments/{id}/download-url/` | 获取下载URL |
| DELETE | `/attachments/{id}/` | 删除附件 |

---

## 补充接口定义（前端实现补充）

### 4.x 任务管理模块补充接口

以下接口在文档第4节已有概述，此处补充详细定义：

#### 4.8 获取项目任务列表（树形/扁平）

**GET** `/projects/{id}/tasks/`

#### 查询参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| view | string | 否 | 视图类型: `tree`(树形，默认), `flat`(扁平) |
| status | string | 否 | 状态过滤: planning, pending, in_progress, completed |
| assignee | string | 否 | 负责人过滤: `me`(当前用户), `all`(全部) |
| search | string | 否 | 标题搜索关键词 |

#### 响应示例 - 树形视图（view=tree）

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "items": [
      {
        "id": 1,
        "project_id": 1,
        "title": "API接口开发模块",
        "description": "完成用户管理模块的API接口开发",
        "assignee_id": 2,
        "assignee_name": "zhangsan",
        "assignee_avatar": null,
        "status": "in_progress",
        "priority": "high",
        "level": 1,
        "parent_id": null,
        "path": "",
        "start_date": "2026-02-10",
        "end_date": "2026-02-20",
        "created_at": "2026-02-10T08:00:00Z",
        "updated_at": "2026-02-10T08:00:00Z",
        "subtask_count": 3,
        "completed_subtask_count": 1,
        "children": [
          {
            "id": 2,
            "project_id": 1,
            "title": "设计API接口文档",
            "assignee_id": 2,
            "assignee_name": "zhangsan",
            "status": "completed",
            "priority": "high",
            "level": 2,
            "parent_id": 1,
            "path": "/1",
            "children": [],
            "subtask_count": 0,
            "completed_subtask_count": 0
          }
        ]
      }
    ]
  }
}
```

**说明**：
- `level`: 任务层级，1=主任务，2=子任务，3=孙任务
- `path`: 路径枚举，如 `/1/12` 表示该任务的上级路径
- `children`: 子任务列表（仅在树形视图且 expand=true 时返回）
- `subtask_count`: 子任务总数
- `completed_subtask_count`: 已完成子任务数

---

#### 4.9 创建任务（主任务）

**POST** `/projects/{id}/tasks/`

> 权限：Super Admin, Team Admin

#### 请求参数

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| title | string | 是 | 任务标题，最大200字符 |
| description | string | 否 | 任务描述 |
| assignee_id | integer | 是 | 负责人ID |
| status | string | 否 | 状态，默认 planning |
| priority | string | 否 | 优先级: urgent, high, medium, low，默认 medium |
| start_date | date | 否 | 开始日期，格式 YYYY-MM-DD |
| end_date | date | 否 | 结束日期，格式 YYYY-MM-DD |

#### 请求示例

```json
{
  "title": "数据库设计",
  "description": "设计系统数据库结构",
  "assignee_id": 2,
  "priority": "high",
  "start_date": "2026-02-10",
  "end_date": "2026-02-15"
}
```

#### 响应示例

```json
{
  "code": 201,
  "message": "任务创建成功",
  "data": {
    "id": 5,
    "project_id": 1,
    "title": "数据库设计",
    "description": "设计系统数据库结构",
    "assignee_id": 2,
    "assignee_name": "zhangsan",
    "status": "planning",
    "priority": "high",
    "level": 1,
    "parent_id": null,
    "path": "",
    "start_date": "2026-02-10",
    "end_date": "2026-02-15",
    "created_at": "2026-02-10T08:44:13Z",
    "updated_at": "2026-02-10T08:44:13Z",
    "subtask_count": 0,
    "completed_subtask_count": 0
  }
}
```

---

#### 4.10 创建子任务

**POST** `/tasks/{id}/subtasks/`

> 权限：任务负责人 (parent_task.assignee_id == current_user.id)
> 限制：父任务 level < 3

#### 请求参数

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| title | string | 是 | 任务标题 |
| description | string | 否 | 任务描述 |
| status | string | 否 | 状态，默认 planning |
| priority | string | 否 | 优先级 |
| start_date | date | 否 | 开始日期 |
| end_date | date | 否 | 结束日期 |

> 注意：子任务自动继承父任务的 assignee_id

#### 响应示例

```json
{
  "code": 201,
  "message": "子任务创建成功",
  "data": {
    "id": 6,
    "project_id": 1,
    "title": "用户表设计",
    "level": 2,
    "parent_id": 5,
    "path": "/5",
    "assignee_id": 2,
    "assignee_name": "zhangsan",
    "status": "planning",
    "priority": "medium",
    "created_at": "2026-02-10T08:44:13Z",
    "subtask_count": 0,
    "completed_subtask_count": 0
  }
}
```

#### 错误响应

```json
{
  "code": 422,
  "message": "已达到最大层级深度（3层）",
  "errors": {
    "level": ["父任务层级为3，无法创建子任务"]
  }
}
```

---

#### 4.11 更新任务状态

**PATCH** `/tasks/{id}/status/`

> 权限：管理员 或 任务负责人

#### 请求参数

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| status | string | 是 | 新状态: planning, pending, in_progress, completed |

#### 请求示例

```json
{
  "status": "completed"
}
```

#### 响应示例

```json
{
  "code": 200,
  "message": "状态更新成功",
  "data": {
    "id": 1,
    "status": "completed",
    "updated_at": "2026-02-10T08:44:13Z"
  }
}
```

---

#### 4.12 批量获取任务进度

**GET** `/projects/{id}/tasks/progress/`

> 用于项目详情页展示任务完成情况

#### 响应示例

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "total": 10,
    "planning": 2,
    "pending": 3,
    "in_progress": 3,
    "completed": 2,
    "overdue": 1
  }
}
```

---

## 5.6 获取全局任务看板数据（跨项目）

**GET** `/tasks/kanban/`

> 权限：所有团队成员
> 数据范围：管理员返回所有任务，成员返回自己的任务

#### 查询参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| project_id | integer | 否 | 项目过滤，不传则显示所有项目 |
| assignee | string | 否 | me(我的), all(全部)，默认 all |

#### 响应示例

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "columns": [
      {
        "id": "planning",
        "title": "规划中",
        "color": "#94A3B8",
        "tasks": [
          {
            "id": 5,
            "title": "技术选型",
            "priority": "high",
            "assignee": {"id": 1, "username": "zhangsan"},
            "project": {"id": 1, "title": "电商平台重构"},
            "end_date": "2026-02-20",
            "normal_flag": "normal"
          }
        ]
      },
      {
        "id": "pending",
        "title": "待处理",
        "color": "#F59E0B",
        "tasks": [...]
      },
      {
        "id": "in_progress",
        "title": "进行中",
        "color": "#0D9488",
        "tasks": [...]
      },
      {
        "id": "completed",
        "title": "已完成",
        "color": "#10B981",
        "tasks": [...]
      }
    ]
  }
}
```

---

## 5.7 获取全局任务列表数据（跨项目）

**GET** `/tasks/list/`

> 权限：所有团队成员
> 数据范围：管理员返回所有任务，成员返回自己的任务

#### 查询参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| project_id | integer | 否 | 项目过滤 |
| status | string | 否 | 状态过滤，多个用逗号分隔 |
| priority | string | 否 | 优先级过滤 |
| assignee | string | 否 | me(我的), all(全部) |
| search | string | 否 | 标题搜索 |
| sort_by | string | 否 | 排序字段: created_at, end_date, priority |
| sort_order | string | 否 | 排序方向: asc, desc |
| page | integer | 否 | 页码，默认 1 |
| page_size | integer | 否 | 每页数量，默认 20 |

#### 响应示例

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "items": [
      {
        "id": 1,
        "title": "API设计",
        "status": "in_progress",
        "priority": "high",
        "level": 1,
        "assignee": {"id": 1, "username": "zhangsan"},
        "project": {"id": 1, "title": "电商平台重构"},
        "start_date": "2026-02-01",
        "end_date": "2026-02-10",
        "normal_flag": "normal",
        "created_at": "2026-02-01T08:00:00Z"
      }
    ],
    "pagination": {
      "page": 1,
      "page_size": 20,
      "total": 50,
      "total_pages": 3
    }
  }
}
```

---

## 5.8 获取全局甘特图数据（跨项目）

**GET** `/tasks/gantt/`

> 权限：所有团队成员
> 数据范围：管理员返回所有主任务，成员返回自己的主任务+子任务树

#### 查询参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| project_id | integer | 否 | 项目过滤 |
| start_date | date | 否 | 开始日期范围 |
| end_date | date | 否 | 结束日期范围 |
| view_mode | string | 否 | 视图模式: day(默认), week, month |

#### 响应示例

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "view_mode": "day",
    "date_range": {
      "start": "2026-02-01",
      "end": "2026-02-28"
    },
    "tasks": [
      {
        "id": 1,
        "title": "需求分析",
        "start": "2026-02-01",
        "end": "2026-02-05",
        "progress": 100,
        "status": "completed",
        "assignee": {"id": 1, "username": "zhangsan"},
        "project": {"id": 1, "title": "电商平台重构"},
        "level": 1,
        "children": []
      }
    ],
    "projects": [
      {"id": 1, "title": "电商平台重构", "color": "#0D9488"},
      {"id": 2, "title": "官网改版", "color": "#0891B2"}
    ]
  }
}
```

---

## 5.9 获取全局日历数据（跨项目）

**GET** `/tasks/calendar/`

> 权限：所有团队成员
> 数据范围：管理员返回所有任务，成员返回自己的任务

#### 查询参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| year | integer | 是 | 年份 |
| month | integer | 是 | 月份 (1-12) |
| project_id | integer | 否 | 项目过滤 |
| assignee | string | 否 | me(我的), all(全部) |

#### 响应示例

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "year": 2026,
    "month": 2,
    "days": [
      {
        "date": "2026-02-01",
        "tasks": [
          {
            "id": 1,
            "title": "需求分析",
            "status": "completed",
            "priority": "high",
            "assignee": {"id": 1, "username": "zhangsan"},
            "project": {"id": 1, "title": "电商平台重构"}
          }
        ]
      }
    ]
  }
}
```

---

*文档版本: v1.0 | 最后更新: 2026-02-11*

### API 端点汇总补充

### 全局任务视图
| 方法 | 端点 | 说明 |
|------|------|------|
| GET | `/tasks/kanban/` | 全局看板数据 |
| GET | `/tasks/list/` | 全局列表数据 |
| GET | `/tasks/gantt/` | 全局甘特图数据 |
| GET | `/tasks/calendar/` | 全局日历数据 |

# 局域网访问配置指南

## 问题现象

- 输入局域网 IP:端口能看到请求
- 但页面空白，没有内容显示

## 原因分析

通常由以下两个原因导致：

1. **CORS 跨域限制** - 后端拒绝了来自不同源的请求
2. **Flutter Web 资源加载** - Web 应用需要从正确的 host 运行

## 解决方案

### 1. 后端 CORS 配置（关键）

#### Django 后端示例

```python
# settings.py

# 安装 django-cors-headers
# pip install django-cors-headers

INSTALLED_APPS = [
    ...
    'corsheaders',
    ...
]

MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',  # 放在最前面
    'django.middleware.common.CommonMiddleware',
    ...
]

# 开发环境：允许所有来源（不推荐用于生产）
CORS_ALLOW_ALL_ORIGINS = True

# 或者使用白名单（推荐）
CORS_ALLOWED_ORIGINS = [
    "http://localhost:8080",
    "http://127.0.0.1:8080",
    "http://10.0.0.61:8080",     # 你的局域网 IP
    "http://192.168.1.x:8080",   # 其他可能的局域网 IP
]

# 允许携带凭证（Cookie、Authorization Header）
CORS_ALLOW_CREDENTIALS = True

# 允许的 HTTP 方法
CORS_ALLOW_METHODS = [
    'GET',
    'POST',
    'PUT',
    'PATCH',
    'DELETE',
    'OPTIONS',
]

# 允许的请求头
CORS_ALLOW_HEADERS = [
    'accept',
    'accept-encoding',
    'authorization',
    'content-type',
    'dnt',
    'origin',
    'user-agent',
    'x-csrftoken',
    'x-requested-with',
]
```

#### FastAPI 后端示例

```python
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:8080",
        "http://10.0.0.61:8080",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

### 2. 前端启动方式

#### 开发环境（热重载）

```bash
# 绑定到所有网卡，允许局域网访问
flutter run -d chrome --web-port=8080 --web-hostname=0.0.0.0
```

或者使用脚本：

```bash
# Windows
.\scripts\run_web.bat

# 然后访问：
# - 本机：http://localhost:8080
# - 局域网：http://10.0.0.61:8080
```

#### 生产构建

```powershell
# 构建 Web 应用
.\scripts\build_web.ps1

# 或使用命令行指定 API 地址
flutter build web --release --dart-define=API_BASE_URL=http://10.0.0.61:8801/api
```

### 3. 部署 Web 应用

构建完成后，使用任意 Web 服务器部署：

```bash
# 进入构建目录
cd build/web

# Python 简单服务器（测试用）
python -m http.server 8080

# 或使用 Node 的 http-server
npx http-server -p 8080 --cors
```

### 4. 验证配置

打开浏览器开发者工具（F12），检查：

1. **Console 面板** - 是否有 CORS 错误
2. **Network 面板** - API 请求是否返回 200

常见问题：

```
# CORS 错误示例
Access to XMLHttpRequest at 'http://10.0.0.61:8801/api/auth/me/'
from origin 'http://10.0.0.61:8080' has been blocked by CORS policy...
```

解决方法：确保后端 `CORS_ALLOWED_ORIGINS` 包含前端地址。

## 网络检查清单

- [ ] 后端服务已启动并监听正确 IP (`0.0.0.0:8801` 或特定 IP)
- [ ] 后端 CORS 配置允许前端地址
- [ ] 防火墙允许 8801 和 8080 端口
- [ ] Flutter Web 使用 `--web-hostname=0.0.0.0` 启动
- [ ] 浏览器可以访问后端 API（直接访问 http://10.0.0.61:8801/api/auth/me/ 测试）

## 快速诊断命令

```bash
# 测试后端是否可访问
curl http://10.0.0.61:8801/api/auth/me/

# 检查本机 IP 地址
ipconfig  # Windows
ifconfig  # Linux/Mac

# 测试端口连通性
telnet 10.0.0.61 8801
```

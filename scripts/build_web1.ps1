# Flutter Web 生产构建脚本
$OutputEncoding = [System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8

param(
    [string]$ApiBaseUrl = "/api"
)

Write-Host "========================================" -ForegroundColor Green
Write-Host "   TeamSync Web 生产构建脚本" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

Write-Host "[1/4] 清理旧构建..." -ForegroundColor Yellow
flutter clean

Write-Host "[2/4] 获取依赖..." -ForegroundColor Yellow
flutter pub get

Write-Host "[3/4] 构建 Web 应用..." -ForegroundColor Yellow
Write-Host "      API地址: $ApiBaseUrl" -ForegroundColor Cyan

# 使用 dart-define 传入 API 地址
flutter build web --release --dart-define=API_BASE_URL=$ApiBaseUrl

Write-Host ""
Write-Host "[4/4] 构建完成!" -ForegroundColor Green
Write-Host ""
Write-Host "构建输出目录: build/web/" -ForegroundColor Cyan
Write-Host ""
Write-Host "部署方式:" -ForegroundColor Yellow
Write-Host "  1. 将 build/web/ 目录内容复制到 Nginx/Apache 服务器" -ForegroundColor White
Write-Host "  2. 或使用 Python 简单服务器测试:" -ForegroundColor White
Write-Host "     cd build/web; python -m http.server 8080" -ForegroundColor Gray
Write-Host ""
Write-Host "========================================" -ForegroundColor Green

Read-Host "按 Enter 键退出"

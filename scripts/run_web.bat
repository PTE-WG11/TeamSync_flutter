@echo off
chcp 65001 >nul
echo ========================================
echo   TeamSync Web 局域网启动脚本
echo ========================================
echo.

REM 设置你的局域网 IP
set LOCAL_IP=10.0.0.61
set WEB_PORT=8080

echo [1/3] 检测网络配置...
echo     后端地址: http://%LOCAL_IP%:8801
echo     前端地址: http://%LOCAL_IP%:%WEB_PORT%
echo.

echo [2/3] 启动 Flutter Web 服务...
echo     正在启动，请稍候...
echo.

REM 使用 --web-hostname 绑定到所有网卡，允许局域网访问
flutter run -d chrome --web-port=%WEB_PORT% --web-hostname=0.0.0.0

echo.
echo ========================================
echo 访问地址:
echo   本机: http://localhost:%WEB_PORT%
echo   局域网: http://%LOCAL_IP%:%WEB_PORT%
echo ========================================
pause

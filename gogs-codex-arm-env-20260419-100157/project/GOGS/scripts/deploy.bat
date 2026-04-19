@echo off
chcp 65001 >nul
setlocal

set PRESET=backend-win-msvc-release
if not "%~1"=="" set PRESET=%~1

set PROJECT_ROOT=%~dp0..
for %%I in ("%PROJECT_ROOT%") do set PROJECT_ROOT=%%~fI
set BACKEND_BINARY=%PROJECT_ROOT%\backend\build\%PRESET%\Debug\GrabSystem.exe
if /I "%PRESET:~-7%"=="release" set BACKEND_BINARY=%PROJECT_ROOT%\backend\build\%PRESET%\Release\GrabSystem.exe

set RUNTIME_ROOT=%PROJECT_ROOT%\runtime
set BACKEND_RUNTIME=%RUNTIME_ROOT%\backend
set FRONTEND_RUNTIME=%RUNTIME_ROOT%\frontend

echo ========================================
echo 抓斗作业引导及盘存系统原生部署脚本
echo ========================================
echo 后端预设: %PRESET%
echo.

if not exist "%BACKEND_BINARY%" (
    echo [错误] 未找到后端二进制: %BACKEND_BINARY%
    echo 请先执行: scripts\build-native-backend.bat %PRESET%
    exit /b 1
)

if not exist "%BACKEND_RUNTIME%\bin" mkdir "%BACKEND_RUNTIME%\bin"
if not exist "%BACKEND_RUNTIME%\config" mkdir "%BACKEND_RUNTIME%\config"
if not exist "%BACKEND_RUNTIME%\web" mkdir "%BACKEND_RUNTIME%\web"
if not exist "%RUNTIME_ROOT%\systemd" mkdir "%RUNTIME_ROOT%\systemd"
if not exist "%BACKEND_RUNTIME%\data\videos" mkdir "%BACKEND_RUNTIME%\data\videos"
if not exist "%BACKEND_RUNTIME%\data\maps" mkdir "%BACKEND_RUNTIME%\data\maps"
if not exist "%BACKEND_RUNTIME%\data\hls" mkdir "%BACKEND_RUNTIME%\data\hls"
if not exist "%BACKEND_RUNTIME%\data\mysql" mkdir "%BACKEND_RUNTIME%\data\mysql"
if not exist "%BACKEND_RUNTIME%\logs" mkdir "%BACKEND_RUNTIME%\logs"
if not exist "%FRONTEND_RUNTIME%" mkdir "%FRONTEND_RUNTIME%"

copy /Y "%BACKEND_BINARY%" "%BACKEND_RUNTIME%\bin\GrabSystem.exe" >nul

if exist "%PROJECT_ROOT%\config\config.ini" copy /Y "%PROJECT_ROOT%\config\config.ini" "%BACKEND_RUNTIME%\config\config.ini" >nul
if exist "%PROJECT_ROOT%\config\mediamtx.yml" copy /Y "%PROJECT_ROOT%\config\mediamtx.yml" "%BACKEND_RUNTIME%\config\mediamtx.yml" >nul

if exist "%PROJECT_ROOT%\frontend\dist" (
    if exist "%FRONTEND_RUNTIME%\dist" rmdir /S /Q "%FRONTEND_RUNTIME%\dist"
    xcopy "%PROJECT_ROOT%\frontend\dist" "%FRONTEND_RUNTIME%\dist" /E /I /Y >nul
    if exist "%BACKEND_RUNTIME%\web" rmdir /S /Q "%BACKEND_RUNTIME%\web"
    xcopy "%PROJECT_ROOT%\frontend\dist" "%BACKEND_RUNTIME%\web" /E /I /Y >nul
)

if exist "%PROJECT_ROOT%\deploy\systemd" (
    xcopy "%PROJECT_ROOT%\deploy\systemd" "%RUNTIME_ROOT%\systemd" /E /I /Y >nul
)

echo.
echo [成功] 原生运行目录已准备完成
echo   后端目录: %BACKEND_RUNTIME%
echo   前端目录: %FRONTEND_RUNTIME%
echo.
echo 启动后端:
echo   cd /d "%BACKEND_RUNTIME%\bin"
echo   GrabSystem.exe -c ..\config\config.ini
echo.
echo systemd 模板:
echo   %RUNTIME_ROOT%\systemd
echo.
echo 发布前端:
echo   cd /d "%FRONTEND_RUNTIME%"
echo   python -m http.server 8081
exit /b 0

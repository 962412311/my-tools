@echo off
chcp 65001 >nul
setlocal

set PRESET=backend-win-msvc-debug
if not "%~1"=="" set PRESET=%~1
set VCVARS_BAT=

echo ========================================
echo 原生 Qt 后端构建脚本
echo ========================================
echo 使用预设: %PRESET%
echo.

if "%Qt6_DIR%"=="" (
    echo [错误] 未设置 Qt6_DIR
    echo 例如: set Qt6_DIR=C:\Qt\6.2.4\msvc2019_64\lib\cmake\Qt6
    exit /b 1
)

if "%PCL_DIR%"=="" (
    echo [错误] 未设置 PCL_DIR
    echo 例如: set PCL_DIR=C:\3rdparty\PCL\cmake
    exit /b 1
)

if "%Eigen3_DIR%"=="" (
    echo [错误] 未设置 Eigen3_DIR
    echo 例如: set Eigen3_DIR=C:\3rdparty\eigen\share\eigen3\cmake
    exit /b 1
)

where cl >nul 2>nul
if errorlevel 1 (
    call :find_vcvars
    if "%VCVARS_BAT%"=="" (
        echo [错误] 未找到 vcvars64.bat，请先安装 Visual Studio C++ 构建工具
        exit /b 1
    )

    echo [信息] 检测到当前 shell 未加载 MSVC 编译环境
    echo [信息] 正在调用: %VCVARS_BAT%
    call "%VCVARS_BAT%"
    if errorlevel 1 exit /b 1
)

set BUILD_CONFIG=Debug
echo %PRESET% | findstr /I "release" >nul && set BUILD_CONFIG=Release

cmake --preset %PRESET% -DPCL_DIR="%PCL_DIR%" -DEigen3_DIR="%Eigen3_DIR%"
if errorlevel 1 exit /b 1

cmake --build --preset %PRESET% --config %BUILD_CONFIG%
if errorlevel 1 exit /b 1

echo.
echo [成功] 后端构建完成
exit /b 0

:find_vcvars
for %%F in (
    "D:\VisualStudio\IDE\VC\Auxiliary\Build\vcvars64.bat"
    "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"
    "C:\Program Files\Microsoft Visual Studio\2022\Professional\VC\Auxiliary\Build\vcvars64.bat"
    "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\VC\Auxiliary\Build\vcvars64.bat"
    "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvars64.bat"
    "C:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\VC\Auxiliary\Build\vcvars64.bat"
    "C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\VC\Auxiliary\Build\vcvars64.bat"
) do (
    if exist %%~F (
        set VCVARS_BAT=%%~F
        goto :eof
    )
)
goto :eof

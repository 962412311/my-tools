@echo off
setlocal
node "%~dp0frontend-tool.js" build
exit /b %errorlevel%

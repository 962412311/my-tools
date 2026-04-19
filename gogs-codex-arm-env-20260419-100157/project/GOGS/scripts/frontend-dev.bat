@echo off
setlocal
node "%~dp0frontend-tool.js" dev
exit /b %errorlevel%

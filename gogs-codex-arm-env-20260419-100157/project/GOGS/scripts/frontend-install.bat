@echo off
setlocal
node "%~dp0frontend-tool.js" install
exit /b %errorlevel%

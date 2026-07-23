@echo off
chcp 65001 >nul
cd /d "%~dp0"

echo Starting Vite dev server...
start /b cmd /c "npx vite"

echo Waiting for Vite to be ready on port 5173...
:waitloop
timeout /t 1 /nobreak >nul
netstat -an | findstr ":5173" | findstr "LISTENING" >nul 2>&1
if errorlevel 1 goto waitloop

echo Vite is ready! Starting Electron...
npx electron .

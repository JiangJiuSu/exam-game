@echo off
chcp 65001 >nul
title 考研游戏系统

cd /d "%~dp0"

if not exist "node_modules" (
    echo ====================================
    echo   首次运行，正在安装依赖...
    echo   这可能需要1-2分钟时间，请耐心等待。
    echo ====================================
    echo.
    npm install
    if errorlevel 1 (
        echo.
        echo ====================================
        echo   安装失败！请检查是否已安装 Node.js
        echo   下载地址: https://nodejs.org/
        echo ====================================
        pause
        exit /b 1
    )
    echo.
    echo   依赖安装完成！正在启动应用...
    echo.
)

echo 正在启动应用...
npm run electron:dev
if errorlevel 1 (
    echo.
    echo ====================================
    echo   启动失败！请检查 Node.js 是否正常
    echo ====================================
    pause
)

@echo off
chcp 65001 >nul
title 考研游戏系统

cd /d "%~dp0"

echo Setting npm mirror for China...
npm config set registry https://registry.npmmirror.com >nul 2>&1

if not exist "node_modules" (
    echo ====================================
    echo   First run: installing dependencies...
    echo   This may take 1-2 minutes.
    echo ====================================
    echo.
    npm install
    if errorlevel 1 (
        echo.
        echo ====================================
        echo   Install failed!
        echo   Please install Node.js first:
        echo   https://nodejs.org/
        echo ====================================
        pause
        exit /b 1
    )
    echo.
    echo   Dependencies installed! Starting app...
    echo.
)

echo Starting app...
npm run electron:dev
if errorlevel 1 (
    echo.
    echo ====================================
    echo   Failed to start!
    echo   Please check Node.js installation.
    echo ====================================
    pause
)

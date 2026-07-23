@echo off
chcp 65001 >nul
title 考研游戏系统

cd /d "%~dp0"

:: ============================================
:: Step 1: Check if Node.js is installed
:: ============================================
where node >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo ========================================
    echo   Node.js not found. Auto installing...
    echo   This is a one-time setup (about 1 min)
    echo ========================================
    echo.

    set "NODE_VER=v20.18.1"
    set "NODE_URL=https://nodejs.org/dist/%NODE_VER%/node-%NODE_VER%-x64.msi"
    set "NODE_MSI=%TEMP%\node-install.msi"

    echo Downloading Node.js %NODE_VER% ...
    powershell -Command "$ProgressPreference='SilentlyContinue'; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%NODE_URL%' -OutFile '%NODE_MSI%'"
    if not exist "%NODE_MSI%" (
        echo.
        echo ====================================
        echo   Download failed!
        echo   Please install Node.js manually:
        echo   https://nodejs.org/
        echo ====================================
        pause
        exit /b 1
    )

    echo Installing Node.js (silent, please wait)...
    msiexec /i "%NODE_MSI%" /passive /norestart
    if %errorlevel% neq 0 (
        echo.
        echo ====================================
        echo   Install failed!
        echo   Please install Node.js manually:
        echo   https://nodejs.org/
        echo ====================================
        pause
        exit /b 1
    )
    del "%NODE_MSI%" >nul 2>&1

    :: Refresh PATH so current session can find node
    for /f "tokens=2*" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul') do set "PATH=%%B"
    for /f "tokens=2*" %%A in ('reg query "HKCU\Environment" /v Path 2^>nul') do set "PATH=%PATH%;%%B"

    echo Node.js installed!
    echo.
)

:: ============================================
:: Step 2: Set npm mirror for China
:: ============================================
npm config set registry https://registry.npmmirror.com >nul 2>&1

:: ============================================
:: Step 3: Install project dependencies
:: ============================================
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
        echo   Install failed! Check your network.
        echo ====================================
        pause
        exit /b 1
    )
    echo.
    echo   Dependencies installed!
    echo.
)

:: ============================================
:: Step 4: Start the app
:: ============================================
echo Starting app...
npm run electron:dev
if errorlevel 1 (
    echo.
    echo ====================================
    echo   Failed to start! Check Node.js.
    echo ====================================
    pause
)

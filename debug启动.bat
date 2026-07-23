@echo off
chcp 65001 >nul
title Exam Game - Debug Mode

cd /d "%~dp0"

set "LOG=debug.log"
echo === %date% %time% === > %LOG%

:: Step 1: Check Node.js
echo [1] Checking Node.js... >> %LOG%
where node >nul 2>&1
if %errorlevel% neq 0 (
    echo [1] Node.js NOT found >> %LOG%
    echo Node.js not found. Auto installing...

    set "NODE_VER=v20.18.1"
    set "NODE_URL=https://nodejs.org/dist/%NODE_VER%/node-%NODE_VER%-x64.msi"
    set "NODE_MSI=%TEMP%\node-install.msi"

    echo [1] Downloading %NODE_URL% >> %LOG%
    powershell -Command "$ProgressPreference='SilentlyContinue'; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%NODE_URL%' -OutFile '%NODE_MSI%'"
    if not exist "%NODE_MSI%" (
        echo [1] Download FAILED >> %LOG%
        echo Download failed! Please install Node.js: https://nodejs.org/
        pause
        exit /b 1
    )

    echo [1] Installing Node.js... >> %LOG%
    msiexec /i "%NODE_MSI%" /passive /norestart
    del "%NODE_MSI%" >nul 2>&1

    for /f "tokens=2*" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul') do set "PATH=%%B"
    for /f "tokens=2*" %%A in ('reg query "HKCU\Environment" /v Path 2^>nul') do set "PATH=%PATH%;%%B"

    where node >nul 2>&1
    if %errorlevel% neq 0 (
        echo [1] Install FAILED >> %LOG%
        pause
        exit /b 1
    )
    echo [1] Node.js installed OK >> %LOG%
) else (
    for /f %%i in ('node --version') do echo [1] Node.js %%i >> %LOG%
)

:: Step 2: npm mirror
echo [2] Setting npm mirror... >> %LOG%
npm config set registry https://registry.npmmirror.com >> %LOG% 2>&1
echo [2] Done >> %LOG%

:: Step 3: Install dependencies
echo [3] Checking node_modules... >> %LOG%
if not exist "node_modules" (
    echo [3] Running npm install... >> %LOG%
    npm install >> %LOG% 2>&1
    if not exist "node_modules" (
        echo [3] npm install FAILED >> %LOG%
        pause
        exit /b 1
    )
    echo [3] npm install OK >> %LOG%
) else (
    echo [3] node_modules exists >> %LOG%
)

:: Step 4: Kill old processes
echo [4] Killing old processes... >> %LOG%
taskkill /f /im electron.exe >nul 2>&1
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :5173 ^| findstr LISTENING') do taskkill /f /pid %%a >nul 2>&1
echo [4] Done >> %LOG%

:: Step 5: Start Vite
echo [5] Starting Vite... >> %LOG%
start /b cmd /c "npx vite >vite.log 2>&1"

echo [5] Waiting for port 5173... >> %LOG%
:waitloop
timeout /t 1 /nobreak >nul
netstat -an | findstr ":5173" | findstr "LISTENING" >nul 2>&1
if errorlevel 1 goto waitloop
echo [5] Vite is ready >> %LOG%

:: Step 6: Start Electron
echo [6] Starting Electron... >> %LOG%
npx electron . >electron.log 2>&1

echo [6] Waiting 5s for Electron... >> %LOG%
timeout /t 5 /nobreak >nul
tasklist /fi "imagename eq electron.exe" /nh >> %LOG% 2>&1

echo === Done === >> %LOG%
echo.
echo Debug log saved to: %LOG%
echo Vite log: vite.log
echo Electron log: electron.log
echo.
pause

@echo off
title Smartiva Vercel Auto-Deployer
cd /d "%~dp0"

echo ===================================================
echo     Smartiva - Building and Deploying to Vercel
echo ===================================================
echo.

call npx vercel whoami >nul 2>&1
if errorlevel 1 (
    echo [!] First-time Vercel Login required.
    echo Please choose your login method below (GitHub or Email):
    echo.
    call npx vercel login
    echo.
)

echo Step 1/3: Compiling Flutter Web Production Build...
call G:\flutter\bin\flutter.bat build web --no-tree-shake-icons
if errorlevel 1 (
    echo Error building Flutter Web!
    pause
    exit /b 1
)

echo.
echo Step 2/3: Bundling Smartiva Android APK into Web...
copy /y "web\smartiva.apk" "build\web\smartiva.apk" >nul

echo.
echo Step 3/3: Uploading live to Vercel...
call npx vercel deploy "build/web" --prod

echo.
echo ===================================================
echo     SUCCESS: Smartiva is Live on Vercel!
echo ===================================================
pause
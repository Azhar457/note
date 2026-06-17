@echo off
echo ========================================
echo   Quartz 4 Deployment Script
echo ========================================
echo.
echo [1/3] Formatting files...
call npm run format
if %errorlevel% neq 0 (
    echo.
    echo ERROR: Formatting failed!
    pause
    exit /b %errorlevel%
)
echo.
echo [2/3] Building Quartz site...
call npx quartz build
if %errorlevel% neq 0 (
    echo.
    echo ERROR: Build failed!
    pause
    exit /b %errorlevel%
)
echo.
echo [3/3] Syncing to GitHub Pages...
call npx quartz sync
if %errorlevel% neq 0 (
    echo.
    echo ERROR: Sync failed!
    pause
    exit /b %errorlevel%
)
echo.
echo SUCCESS: Site deployed to Azhar457.github.io/note
echo.
pause

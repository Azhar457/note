@echo off
echo ========================================
echo   Quartz 4 Deployment Script
echo ========================================
echo.
echo [1/2] Building Quartz site...
npx quartz build
if %errorlevel% neq 0 (
    echo.
    echo ERROR: Build failed!
    pause
    exit /b %errorlevel%
)
echo.
echo [2/2] Syncing to GitHub Pages...
npx quartz sync
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

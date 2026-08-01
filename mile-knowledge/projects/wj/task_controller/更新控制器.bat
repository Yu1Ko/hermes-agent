@echo off
cd /d "%~dp0"

echo Reverting local changes...
git reset --hard HEAD

if %errorlevel% neq 0 (
    echo Failed to revert local changes.
    pause
    exit /b
)

echo Pulling latest changes from repository...
git pull origin branch-jx3

if %errorlevel% equ 0 (
    echo Update successful.
) else (
    echo Update failed.
)

pause
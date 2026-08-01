@echo off
cd /d "%~dp0"

echo Reverting local changes in submodules...
git submodule foreach --recursive git reset --hard HEAD
git submodule foreach --recursive git clean -fd

if %errorlevel% neq 0 (
    echo Failed to revert local changes in submodules.
    pause
    exit /b
)
git submodule add --force https://ngitlab.testplus.cn/tcdev/automationgroup/JX3.git  projects/JX3
git submodule add --force https://ngitlab.testplus.cn/tcdev/automationgroup/JX3.git  projects/JX3CLASSIC
echo Updating submodules...
git submodule update --init --recursive

if %errorlevel% equ 0 (
    echo Submodules updated successfully.
) else (
    echo Failed to update submodules.
)


git submodule update --remote projects/JX3
git submodule update --remote projects/JX3CLASSIC
if %errorlevel% equ 0 (
    echo Submodules updated successfully.
) else (
    echo Failed to update submodules.
)

pause
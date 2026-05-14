@echo off
cd /d "%~dp0"

echo ios设备远程控制启动  ctrl+c 终止运行
python mobile_control.py

pause
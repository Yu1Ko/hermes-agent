@echo off
cd /d "%~dp0"

echo 开始运行服务
start /b pymobiledevice3 remote tunneld

echo 开始运行控制器  ctrl+c 终止运行
python main.py

pause
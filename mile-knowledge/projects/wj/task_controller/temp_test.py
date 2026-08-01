from u3driver import AltrunUnityDriver
from u3driver import By
from u3driver import commands
import argparse
import time
import os
import uiautomator2 as u2
import pyfeishu
import importlib,sys

def convert_img(path):
    with open(path, "br") as f:
        bys = f.read()
        bys_ = bys.replace(b"\r\n",b"\n")  # 二进制流中的"\r\n" 替换为"\n"
    with open(path, "bw") as f:
        f.write(bys_)

if __name__ == "__main__":


    parser = argparse.ArgumentParser()
    parser.add_argument('-s', help="device serial")
    parser.add_argument('-a', help="apk url")
    parser.add_argument('-i', help="ip address")
    parser.add_argument('-c', help="capture screen")
    parser.add_argument('-b', help="base profiler")
    parser.add_argument('-t', help="skip install")
    parser.add_argument('-sc', help="skip case")
    parser.add_argument('-r', help="retry count")
    parser.add_argument('-p', help="platform")
    args = parser.parse_args()

    #获取设备号
    device_s = args.s or "3143681727000NJ" #one plus 7t
    args.i='10.11.232.198'

    #获取ip
    if not args.i:
        #低版本的SDK用adb shell netcfg查看IP地址
        try:
            res = os.popen(f"adb -s {device_s} shell ifconfig").read()
            ip = res.split('wlan0')[1].split('inet addr:')[1].split(' ')[0]
        except:
            res = os.popen(f'adb -s {device_s} shell netcfg').read()
            ip = res.split('wlan0')[1].split('UP')[1].split('/')[0].split()[0]
    
    else:
        ip = args.i

    # ConnectDevice(device_s, args.a, args.t == '1')
    
    # 如果想要直接连接Editor中运行的游戏，可以在第三个参数中传入正在运行Editor电脑的ip
    udriver = AltrunUnityDriver(device_s,"", ip, TCP_PORT=13000,timeout=60, log_flag=True)

    try:
        parameter={
			'u3driver':udriver,
			'device':device_s,
			"quality":'low',
			"casename":"jx1测试案例",
			"platform":"android",
			"package":"com.seasun.jxp.vn",
			"appkey":"36b87bd0",
            "project_id":"jx1pocket",
            "feishu":pyfeishu.FeiShutalkChatbot()
            }
        importlib.invalidate_caches()
        module_path = os.getcwd()
        module_path = os.path.join(module_path, "UAutoProfilerTool")

        print(module_path)
        sys.path.append(module_path)
        module = importlib.import_module('Profile_test')

        sys.path.remove(module_path)
        prof=module.Profile(parameter)
        prof.RunProfile()

        time.sleep(2000)

        prof.StopProfile(False,True,True)
        udriver.stop()
# 		time.sleep(10)
    except Exception as e:
        print('[ERROR] ', e)
    udriver.stop()



    
    
    

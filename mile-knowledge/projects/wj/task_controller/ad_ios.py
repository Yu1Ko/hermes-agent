import asyncio
import hashlib
import json
import os
import platform
import plistlib
import re
import shutil
import socket
import subprocess
import sys
import time
import traceback
import uuid
import zipfile
from urllib import request
from urllib.parse import urlparse

import aiohttp
import requests
from utils.tools import*
import wda
from PIL import Image, ImageGrab
import ctypes
from tidevice import Device
from utils.constants import SERVER_URL
from extensions import logger
import threading
import uiautomator2 as u2

# 自动化服务器
ios_change_devices = {}

# 截图上传互斥锁, 只允许一个截图上传线程
screenshot_uplock_lock = threading.Lock()


def get_ipv4_address():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        # Connect to a public DNS server (no data is actually sent)
        s.connect(("8.8.8.8", 80))
        ipv4_address = s.getsockname()[0]
    finally:
        s.close()
    return ipv4_address

def win32_get_lock_screen_status():
    u = ctypes.windll.LoadLibrary('user32.dll')
    result = u.GetForegroundWindow()
    return result  # 0表示已锁屏



def device_config(deviceID,platform):
    #设备相关配置:例如是否上传截图
    devicesname = deviceID.split(":")[0].replace('.', '') if "10." in deviceID else deviceID
    strConfigFolder=os.path.join(os.path.dirname(os.path.realpath(__file__)),"device_config")
    if not os.path.exists(strConfigFolder):
        os.makedirs(strConfigFolder)
    strConfigDir=os.path.join(strConfigFolder,f"{platform}-{devicesname}.ini")
    if not os.path.exists(strConfigDir):
        #创建配置文件
        ini_set("Local","UploadImg","1",strConfigDir)
        return True
    else:
        if ini_get("Local", "UploadImg",strConfigDir)=='0':
            return False
        return True


# 获取所有正常连接的设备  上传连接的移动设备或者自己
def GetConnecteddevices(bMobile=True):
    # print(f"开始执行cmd: adb devices")

    android_devices_list = []
    ios_devices_list = []
    pc_devices_list = [get_ipv4_address()]

    try:
        data = os_popen("adb devices")
        device_ad_list = data.split("List of devices attached")[1].splitlines()
        #logger.info(device_ad_list)
        # device_list.splitlines()

        for device in device_ad_list:
            if device.count('\t') > 0:
                device_s, status = device.split('\t')
                if status == "device":
                    android_devices_list.append(device_s)
    except Exception as e:
        #没有adb 跳过
        pass

        # print("打印tidevice")
        # data = os_popen("tidevice list")
        # ios设备未连接时popen会报错, 用subprocess替代
    try:
        result = subprocess.run(["tidevice", "list"], stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                universal_newlines=True, check=True)
        data = result.stdout
        device_ios_list = data.split("\n")
        if data.startswith("UDID"):
            if len(device_ios_list) > 1:
                device_ios_list = device_ios_list[1:-1]
            else:
                device_ios_list = []

        for device in device_ios_list:
            if device != '':
                device_s = device.split(' ')[0]
                ios_devices_list.append(device_s)
    except Exception as e:
        # 没有tidevice 跳过
        # logger.error(e)
        pass

    # print(ios_devices_list)
    # 开一个线程上传截图, 本函数应该尽快返回给上层调用
    upload_screenshot_thread = threading.Thread(target=upload_screenshot, args=(android_devices_list, ios_devices_list,pc_devices_list),
                                                daemon=True)
    upload_screenshot_thread.start()
    ret = android_devices_list + ios_devices_list + pc_devices_list
    return ret


def str_insert(str_origin, pos, str_add):
    str_list = list(str_origin)  # 字符串转list
    str_list.insert(pos, str_add)  # 在指定位置插入字符串
    str_out = ''.join(str_list)  # 空字符连接
    return str_out


def upload_screenshot(android_devices_list, ios_devices_list,pc_devices_list):
    # 先获取锁, 失败直接返回
    get_lock = screenshot_uplock_lock.acquire(blocking=False)
    if not get_lock:
        return

    logger.info(f"开始上传截图\nandroid_devices_list:{android_devices_list}, ios_devices_list:{ios_devices_list}, pc_devices_list:{pc_devices_list}")
    start = time.time()
    try:
        for device in pc_devices_list:
            ret_img("pc", device)
        # 上传截图
        for device in android_devices_list:
            ret_img("android", device)
        for device in ios_devices_list:
            ret_img("ios", device)

    except Exception as e:
        pass
    finally:
        duration = time.time() - start
        if duration < 60:
            time.sleep(60 - duration)
        logger.info(f"上传截图完成")
        # 释放锁
        screenshot_uplock_lock.release()


def capture_img(device_os, devices):
    global ios_change_devices
    if not devices:
        return
    devicesname = devices.split(":")[0].replace('.', '') if "10." in devices else devices
    #所有需要截图的功能 共用这个截图
    img_name = f"stop_{devicesname}.png"
    if device_os == "harmonyOS":
        img_name = f"stop_{devicesname}.jpeg"
    if not os.path.exists("log_file"):
        os.mkdir("log_file")
    if not os.path.exists(f"log_file/{img_name}"):
        with open(f"log_file/{img_name}", "w") as f:
            f.write("")

    try:
        if device_os == "ios":
            # cmd=f"pymobiledevice3 developer dvt screenshot log_file/{img_name} --udid {devices}"
            # pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
            wdaName='com.facebook.WebDriverAgentRunner.xctrunner'
            d=wda.USBClient(devices, port=8100, wda_bundle_id=wdaName)
            d.screenshot(os.path.join(os.getcwd(),f"log_file/{img_name}"))
            #d.close()
        elif device_os == "android":
            #adb截图会导致ocr识别失败
            # os.popen(f"adb -s {devices} shell screencap -p /sdcard/{img_name}").read()
            # os.popen(f"adb -s {devices} pull /sdcard/{img_name} log_file/{img_name}").readline()
            # if "5891ca267d43" in img_name: #不知道为什么红米4会把图片存下来，这里做个删除判断
            #     os.popen(f"adb -s {devices} shell rm /sdcard/{img_name}").read()
            d= u2.connect_usb(devices)
            d.screenshot(os.path.join(os.getcwd(),f"log_file/{img_name}"))
        elif device_os == "harmonyOS":
            os.popen(f"hdc -t {devices} shell snapshot_display -f /data/local/tmp/{img_name}").read()
            os.popen(f"hdc -t {devices} file recv /data/local/tmp/{img_name} log_file/{img_name}").readline()
        elif device_os == "pc":
            if win32_get_lock_screen_status() == 0:
                pass # 锁屏了
                #return None
            else:
                im = ImageGrab.grab()  # ！！锁屏和远程最小化会导致这里执行失败，执行失败会导致内存泄露，RAMMAP中Session Private增长。
                im.save(f"log_file/{img_name}")

    except:
        logger.info(f"截图失败{devices}_{traceback.format_exc()}")

    return f"log_file/{img_name}"



# 上传截图到前端的设备运行截图里
def ret_img(device_os, devices):

    try:
        screenshot_time = int(time.time())
        #根据配置文件判断该设备是否需要上传截图
        if not device_config(devices,device_os):
            return
        img_path = capture_img(device_os, devices)
        img_name = os.path.basename(img_path)

        if device_os == "ios":
            if devices in ios_change_devices.keys():
                devices = ios_change_devices[devices]

        response = requests.post(f"{SERVER_URL}/build/controller/upload/screenshot",
                                 files=[("file", (img_name, open(img_path, "rb").read()))],
                                 data={"runNo": devices, "timestamp": screenshot_time}, timeout=(10, 15))
        if int(json.loads(response.content)["code"]) == 10000 and device_os == "ios":
            newdevices = str_insert(devices, 8, "-")
            response = requests.post(f"{SERVER_URL}/build/controller/upload/screenshot",
                                     files=[("file", (img_name, open(img_path, "rb").read()))],
                                     data={"runNo": newdevices}, timeout=(10, 15))
            if int(json.loads(response.content)["code"]) == 200:
                ios_change_devices[devices] = newdevices
        # print(response.text)
    except:
        logger.error(f"截图上传失败{devices}_{traceback.format_exc()}")


# 使用adb远程连接
def ConnectADB(device_identifier):
    ret = os.popen(f"adb connect {device_identifier}")
    msg = ret.buffer.read().decode('utf-8')
    ret.close()
    return msg.startswith("connected")


# 安装时自动执行的点击安装脚本

def installation_package(process_lock, url, device, u):
    try:
        with process_lock:
            parsed_url = urlparse(url)
            package_name = os.path.basename(parsed_url.path)
            Gameinstaller = ""
            if (platform.system() == 'Windows'):
                print('控制器是Windows系统游戏安装包将安装在桌面')
                userprofile = os.environ.get('USERPROFILE')
                Gameinstaller = os.path.join(userprofile, 'Desktop') + "/Gameinstaller"
                # 判断目录下是否有Gameinstaller文件夹
                if not os.path.exists(Gameinstaller):
                    print("游戏安装包目录不存在，正在创建")
                    os.mkdir(Gameinstaller)
                    print("创建完成")
                else:
                    print("游戏安装包目录存在")
            elif (platform.system() == 'Linux'):
                print('控制器是Linux系统游戏安装包将安装在桌面')
                Gameinstaller = "/Gameinstaller"
                # 判断目录下是否有Gameinstaller文件夹
                if not os.path.exists(Gameinstaller):
                    print("游戏安装包目录不存在，正在创建")
                    os.mkdir(Gameinstaller)
                    print("创建完成")
                else:
                    print("游戏安装包目录存在")
            else:
                return Exception("目前不支持Windows和Linux其它系统")

            # 拉取游戏安装包
            if not os.path.exists(f"{Gameinstaller}/{package_name}"):
                response = requests.get(url)
                with open(f"{Gameinstaller}/{package_name}", 'wb') as f:
                    f.write(response.content)

        print("正在将包推送至手机/data/local/tmp/目录下")
        process = subprocess.Popen(f"adb -s {device} push -p {Gameinstaller}/{package_name} /data/local/tmp/{package_name}", shell=True)
        process.wait()  # 等待命令执行完成
        print("推送成功正在安装")
        process = subprocess.Popen(f"adb -s {device} shell pm install -t -r '/data/local/tmp/{package_name}'" ,shell=True)
        print(f"package_name:{package_name}")
        for i in range(30):
            time.sleep(3)
            if process.poll() is None:
                print("安装进行中")
                install_verify(u)
            else:
                print("安装结束")
                break
            time.sleep(2)
        system = 'grep'
        package = 'com.dragonli.projectsnow'
        cmd = f'adb -s {device} shell "pm list packages | {system} {package}"'
        packagelist = str(os_popen(cmd).replace("\n", "").replace(" ", ""))  # 拿包名
        print(f"packagelist{packagelist}")
        if packagelist.find(package) != -1:
            print("设备有该包体")
        else:
            print("设备没有该包体")

        print("安装完成检测安装包是否还遗留至手机")
        process = subprocess.Popen(f"adb -s {device} shell ls /data/local/tmp", shell=True, stdout=subprocess.PIPE)
        output, _ = process.communicate()
        output_list = output.decode("utf-8").splitlines()
        print(output_list)
        if package_name in output_list:
            print("/data/local/tmp目录下还保存着安装包\t正在删除")
            process = subprocess.Popen(f"adb -s {device} shell rm /data/local/tmp/{package_name}", shell=True,
                                       stdout=subprocess.PIPE)
            process.wait()
            print("安装包删除完成")
    except Exception:
        print("安装失败")
        return


def install_verify(u):
    print('install_verify')
    if u.exists(resourceId="com.oplus.appdetail:id/continue_install"):
        u(resourceId="com.oplus.appdetail:id/continue_install").click()
        time.sleep(5)
    if u.exists(text="无视风险安装"):
        u(text='无视风险安装').click()
    if u.exists(text="继续安装"):
        u(text='继续安装').click()
        time.sleep(5)
    if u.exists(text="完成"):
        u(text='完成').click()
    if u.exists(text="安装"):
        u(text='安装').click()

    if u.exists(text="忘记密码") or u.exists(text="忘记密码？"):
        time.sleep(2)
        u.send_keys("kingsoft123")
        time.sleep(20)
        if u.exists(text="继续安装"):
            u(text='继续安装').click()
            time.sleep(5)
        if u.exists(text="安装"):
            u(text='安装').click()
            time.sleep(5)
        if u.exists(text="确定"):
            u(text='确定').click()
            time.sleep(5)
        time.sleep(10)
        h = int(u.device_info["display"]["height"])
        if u.exists(text='退出安装'):
            h = 0.88 * h
            u.click(355, 1206)
        else:
            h = h * 0.95
        if u.exists(resourceId="com.android.packageinstaller:id/install_confirm_panel"):
            u.click(0.5, h)

    if u.exists(text='退出安装'):
        u.click(355, 1206)

    if u.exists(text="安装"):
        u(text='安装').click()
        time.sleep(1)
        if u.exists(text="安装"):
            u(text='安装').click()

    if u.exists(resourceId="com.android.packageinstaller:id/install_confirm_panel"):
        u.click(0.5, 0.95)

    if u.exists(text="安全警示"):
        u(text='允许安装').click()

    if u.exists(resourceId="com.bbk.account:id/dialog_title"):
        u(resourceId="com.android.systemui:id/back").click()


# 子线程TaskRunProcess用于处理设备的总类
class Android_IOS(object):
    target_folder = '/home/'

    def __init__(self, devices, platforms, package_url, package_info, process_lock, download_lock, wda_port,
                 task_parameters=None):
        self.system = 'findstr' if platform.system().lower() == 'windows' else 'grep'
        self.devices = devices
        self.platform = platforms
        self.wda_port = wda_port
        self.package_url = package_url
        response = requests.get(f"{SERVER_URL}/build/project/get/appkey/list")
        listappkey = json.loads(response.content.decode("utf-8"))["data"]
        package_appkey = dict()
        for appkey in listappkey:
            package_appkey[appkey["app_name"]] = appkey["appkey"]
        self.package_appkey = package_appkey
        self.package = ''
        self.activity = ''
        self.versionName = ''
        self.appkey = ''
        self.WDA_pack = 'com.facebook.WebDriverAgentRunner.xctrunner'
        self.package_info = self.GetIPAInfo(package_info, process_lock)
        self.WDA_U2 = self.INIT_wda_u2()
        self.process_lock = process_lock
        self.version = self.version() if 'tgame' in self.package_url else ''
        self.exist_on_server = False
        self.hash_name = {}
        self.task_parameters = task_parameters
        self.download_error = False
        # self.download_semaphore = None
        self.download_lock = download_lock

    # 下载安装包到本地并分析出包体信息
    def GetIPAInfo(self, packageinfo, process_lock):
        try:
            if not isinstance(packageinfo,dict):
                package_info = json.loads(packageinfo)
            else:
                package_info=packageinfo
            print('URL包体信息', package_info)
            self.package = package_info["packageName"]
            print(f"packageName:{self.package}")
            self.activity = package_info["packageActivity"]
            self.versionName = package_info["versionName"]
            self.appkey = package_info["appkey"]
            return package_info
        except Exception as e:
            traceback.print_exc()

    def wda_u2_Detect(self):
        try:
            self.WDA_U2.info
        except:
            self.WDA_U2 = self.INIT_wda_u2()

        # 结束app
    def kill_app2(self, packageName=None):
        if self.platform == 'android':
            cmd = f'adb -s {self.devices} shell am force-stop "{packageName}"'
        else:
            cmd = f'pymobiledevice3 developer dvt pkill --bundle {packageName} --udid {self.devices}'
            #cmd = f'tidevice -u {self.devices} kill {packageName}'
            # 执行一次有一定概率失败 所有执行两次
        pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
        res = pi.stdout.read()
        try:
            res = str(res, encoding='gbk')
        except:
            res = str(res, encoding='utf8')
        print(f"kill app {packageName} success res:{res}")


    # 启动app
    def start_app(self, packageName=None):
        # self.WDA_U2.app_start(packageName)
        self.nAppStartTime = int(time.time())
        ''''''
        if self.platform == 'android':
            # 根据package获取activity
            self.WDA_U2.app_start(packageName)
            '''
            cmd = f"adb -s {self.deviceId} shell dumpsys package {packageName} | {self.system} Activity"
            pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
            res = pi.stdout.read()
            try:
                res = str(res, encoding='gbk')
            except:
                res = str(res, encoding='utf8')
            self.log.info(res)
            activity = res.split('\n')[1].lstrip().split(' ')[1]
            # self.log.info(activity)
            cmd = f"adb -s {self.deviceId} shell am start -n '{activity}'"
            pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
            res = pi.stdout.read()
            try:
                res = str(res, encoding='gbk')
            except:
                res = str(res, encoding='utf8')
            self.log.info(res)
            #return res'''
        else:
            # self.keep_heart()
            # self.WDA_U2.app_start(self.packageName)
            cmd = f"pymobiledevice3 developer dvt launch {packageName} --udid {self.devices}"
            #cmd = f"tidevice -u {self.devices} launch {packageName}"
            pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
            res = pi.stdout.read()
            try:
                res = str(res, encoding='gbk')
            except:
                res = str(res, encoding='utf8')
            print(f"app_start_result:{res}")
            return res

    # ios的facebook_wda测试工具初始化、安卓的uautomator2测试工具初始化
    def INIT_wda_u2(self):
        try:
            if self.platform == 'ios':
                #self.kill_app2(self.WDA_pack)
                #启动开发者镜像服务ios>=17
                cmd = f'pymobiledevice3 mounter auto-mount --udid {self.devices}'
                pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
                time.sleep(3)
                self.start_app(self.WDA_pack)
                time.sleep(3)
                print(f'[INFO] I Will INIT WDA')
                wc = wda.USBClient(self.devices, port=8100, wda_bundle_id=self.WDA_pack)
                wc.unlock()
                print(f'[INFO] INIT WDA Succeed')
                return wc
            else:
                self.WDA_pack = ''
                print('[INFO] I Will INIT uiautomator2')
                self.unlock()
                time.sleep(1)
                if ':' in self.devices:
                    uiauto = u2.connect_adb_wifi(self.devices)
                else:
                    print(self.devices)
                    uiauto = u2.connect(self.devices)
                uiauto.info
                print('[INFO] INIT uiautomator2 Succeed')
                return uiauto
        except Exception as e:
            traceback.print_exc()
            print(f'[ERROR] Start WDA_uiautomator2 Failed')

    # 检查应用是否安装在设备上
    def FindIPA_APK(self, packages=None):
        package = self.package if packages == None else packages
        if self.platform == 'ios':
            cmd = f'tidevice -u {self.devices} applist | {self.system} {package}'
            packagelist = os_popen(cmd)
        else:
            cmd = f'adb -s {self.devices} shell "pm list packages -3 | {self.system} {package}"'
            packagelist = str(os_popen(cmd).replace("\n", "").replace(" ", ""))  # 拿包名
            print(f"packagelist{packagelist}")
        if packagelist.find(package) != -1:
            print("设备有该包体")
            return True
        else:
            print("设备没有该包体")
            return False

    # 检查应用是否在设备上运行
    def FindRunIPA_APK(self, packages=None):
        package = self.package if packages == None else packages

        if self.platform == 'ios':
            cmd = f'tidevice -u \"{self.devices}\" ps | {self.system} {self.package}'
            packages = os_popen(cmd)  # 拿包名
        else:
            cmd = f'adb -s \"{self.devices}\" shell  ps | {self.system} {self.package}'
            packages = os_popen(cmd)  # 拿包名
            print(f"{self.system} {self.package}")
        print(packages)
        if package in packages:
            return True
        else:
            return False

    # 获取设备上包名为self.package}的应用信息
    def get_info(self):
        package_info = {
            "packagename": None,
            "activity": None,
            "versionName": None}

        if self.platform == 'ios':
            cmd = f'tidevice -u {self.devices} applist | {self.system} {self.package}'
            cmd1 = None
            getappinfo = None
            with self.process_lock:
                cmd1 = f'tidevice -u \"{self.devices}\" appinfo \"{self.package}\"'
                getappinfo = eval(os_popen(cmd1))
            version = getappinfo["CFBundleShortVersionString"]
            versioncode = getappinfo["CFBundleVersion"]
            print(f"包名：{self.package}")
            packages = os_popen(cmd).replace("\n", "")  # 拿包名
            print(f"已安装包信息:{packages} {version}.{versioncode}")
            if self.package in packages:
                info = packages.split(' ')
                package_info['packagename'] = info[0]
                package_info['versionName'] = f"{version}.{versioncode}"
                return package_info
        else:
            # 获取指定应用信息
            cmd1 = None
            cmd2 = None
            cmd3 = None
            with self.process_lock:
                cmd1 = f'adb -s {self.devices} shell dumpsys package \"{self.package}\" | {self.system} version'
                cmd2 = f'adb -s {self.devices} shell dumpsys package \"{self.package}\" | {self.system} Activity'
                cmd3 = f'adb -s {self.devices} shell dumpsys package \"{self.package}\" | {self.system} versionCode'
            try:
                getversion = os_popen(cmd1)
                getversioncode = os_popen(cmd3)
                version = getversion.split('\n')[1].split('=')[-1]
                versioncode = getversioncode.split('versionCode=')[1].split(' ')[0]
            except:
                getversion = ""
                getversioncode = ""
                version = ""
                versioncode = ""
                print("版本号获取失败")
            package_info['versionName'] = f"{version}.{versioncode}"
            print(f"--------------{cmd2}")
            try:
                Activity = os_popen(cmd2)
                print(Activity)
                package_info['packagename'], package_info['activity'] = Activity.split('\n')[1].lstrip().split(' ')[
                    1].split('/')
            except:
                print("获取activity失败!")
                print(traceback.format_exc())
        print(f"包信息: {package_info}")
        return package_info

    def InitUiAuotmator(self):  # 查看设备是否连接在控制器下
        try:
            ret = GetConnecteddevices()
            if self.devices in ret:
                return True
            else:
                return False
        except Exception as e:
            print(f'[Exception] {e}')
            return False

    def CloseIPA_APK(self, package):
        if self.FindRunIPA_APK(package):
            if self.platform == 'ios':
                print(os_popen(f'pymobiledevice3 developer dvt pkill --bundle {package} --udid {self.devices}'))
                #print(os_popen(f'tidevice  -u {self.devices} kill {package}'))  # 关闭应用
            else:
                os_popen(f'adb -s {self.devices} shell am force-stop {package}')  # 关闭应用
        time.sleep(1)

    # 安装包体
    def Install_IOS_IPA(self):
        try:
            print('[INFO] I Will Install APK_IPA')
            # 安装 ipa 
            if self.platform == 'ios':
                mes = os_popen(f"tidevice -u \"{self.devices}\" install \"{self.package_url}\"")
                print(mes)
            else:
                try:
                    installation_package(self.process_lock, self.package_url, self.devices, self.WDA_U2)
                    # self.WDA_U2.app_install(self.package_url, installing_callback=install_verify)
                except:
                    self.WDA_U2 = self.INIT_wda_u2()
                    # self.WDA_U2.app_install(self.package_url, installing_callback=install_verify)
                    installation_package(self.process_lock, self.package_url, self.devices, self.WDA_U2)

                # UE4，清理UE4Game目录
                if self.package_info["projectName"] != None:
                    print(os_popen(
                        f"adb -s {self.devices} shell rm -rf /sdcard/UE4Game/{self.package_info['projectName']}"))

            print('[INFO] Install APK_IPA Succeed')
            return True
        except Exception as e:
            print('[ERROR] Install APK_IPA Failed')
            traceback.print_exc()

    # 卸载应用
    def UnInstall_IOS_IPA(self):
        if self.FindIPA_APK():
            try:
                self.CloseIPA_APK(self.package)
                if "clear_data" in self.task_parameters.keys() and self.task_parameters["clear_data"] == 1:
                    pass
                if self.platform == 'ios':
                    os_popen(f'tidevice -u {self.devices} uninstall  {self.package}')
                else:
                    os_popen(f'adb -s {self.devices} uninstall {self.package}')
                print('[INFO] UnInstall ' + self.package + ' Succeed')
                return True

            except:
                print('[ERROR] UnInstall ' + self.package + ' Failed')
        return False

    # ue4清理游戏路径内的LLM数据
    def UE4ClearLLMData(self):
        if self.platform == "ios":
            data = os_popen(
                f"tidevice -u {self.devices} fsync -B {self.package} ls /Documents/{self.package_info['projectName']}/Saved/Profiling")
            if "LLM" in data:
                print(os_popen(
                    f"tidevice -u {self.devices} fsync -B {self.package} rmtree /Documents/{self.package_info['projectName']}/Saved/Profiling/LLM"))
        else:
            LLM = os_popen(
                f"adb -s {self.devices} ls /sdcard/UE4Game/{self.package_info['projectName']}/{self.package_info['projectName']}/Saved/Profiling/LLM")
            if "No such file or directory" in LLM:
                # 没有该文件，直接跳过
                pass
            else:
                # 删除文件
                ret = os_popen(
                    f"adb -s {self.devices} shell rm -rf /sdcard/UE4Game/{self.package_info['projectName']}/{self.package_info['projectName']}/Saved/Profiling/LLM")
                print(ret)

    # ue4清理内存报告
    def UE4ClearMemReportData(self):
        if self.platform == "ios":
            data = os_popen(
                f"tidevice -u {self.devices} fsync -B {self.package} ls /Documents/{self.package_info['projectName']}/Saved/Profiling")
            if "MemReports" in data:
                print(os_popen(
                    f"tidevice -u {self.devices} fsync -B {self.package} rmtree /Documents/{self.package_info['projectName']}/Saved/Profiling/MemReports"))
        else:
            MemReports = os_popen(
                f"adb -s {self.devices} ls /sdcard/UE4Game/{self.package_info['projectName']}/{self.package_info['projectName']}/Saved/Profiling/MemReports")
            if "No such file or directory" in MemReports:
                # 没有该文件，直接跳过
                pass
            else:
                # 删除文件
                ret = os_popen(
                    f"adb -s {self.devices} shell rm -rf /sdcard/UE4Game/{self.package_info['projectName']}/{self.package_info['projectName']}/Saved/Profiling/MemReports")
                print(ret)

    # ue4清理游戏内日志
    def UE4ClearLog(self):
        if self.platform == "ios":
            data = os_popen(
                f"tidevice -u {self.devices} fsync -B {self.package} ls /Documents/{self.package_info['projectName']}/Saved")
            if "Logs" in data:
                print(os_popen(
                    f"tidevice -u {self.devices} fsync -B {self.package} rmtree /Documents/{self.package_info['projectName']}/Saved/Logs"))
        else:
            Logs = os_popen(
                f"adb -s {self.devices} ls /sdcard/UE4Game/{self.package_info['projectName']}/{self.package_info['projectName']}/Saved/Logs")
            if "No such file or directory" in Logs:
                # 没有该文件，直接跳过
                pass
            else:
                # 删除文件
                ret = os_popen(
                    f"adb -s {self.devices} shell rm -rf /sdcard/UE4Game/{self.package_info['projectName']}/{self.package_info['projectName']}/Saved/Logs")
                print(ret)

    # 确保 /sdcard/UE4Game/ProjectName 路径存在，并根据采集选项设置 UE4CommandLine.txt
    def ReBuIniInit(self, fileName):

        if self.platform == "ios":
            # IOS 不需要开启权限，但是必须要提前开过一次游戏（这里默认已经开过游戏，如已经进行过下载资源案例）
            Documents = os_popen(f"tidevice -u {self.devices} fsync -B {self.package} ls /Documents")
            if len(Documents) == 0:
                print("游戏没有启动过，无法推送 ue4commandline.txt")
                return

            print(os_popen(
                f"tidevice -u {self.devices} fsync -B {self.package} push {fileName}.ini /Documents/files/debug.ini"))


        else:

            filename = os_popen(
                f"adb -s {self.devices} shell ls /sdcard/Android/data/{self.package} | grep files")
            if filename != "UE4Game":
                os_popen(f"adb -s {self.devices} shell mkdir /sdcard/Android/data/{self.package}/files")

            ProjectDir = os_popen(
                f"adb -s {self.devices} shell ls /sdcard/Android/data/{self.package}/files | grep debug.ini")
            if ProjectDir != "debug.ini":
                os_popen(
                    f"adb -s {self.devices} push {fileName}.ini /sdcard/Android/data/{self.package}/files/debug.ini")

            # 开放应用读写 SD 卡权限
            os_popen(
                f"adb -s {self.devices} shell pm grant {self.package} android.permission.READ_EXTERNAL_STORAGE")
            os_popen(
                f"adb -s {self.devices} shell pm grant {self.package} android.permission.WRITE_EXTERNAL_STORAGE")

    # 确保 /sdcard/UE4Game/ProjectName 路径存在，并根据采集选项设置 UE4CommandLine.txt
    def UE4CommandLineInit(self, commandLineData=""):

        if self.platform == "ios":
            # IOS 不需要开启权限，但是必须要提前开过一次游戏（这里默认已经开过游戏，如已经进行过下载资源案例）
            Documents = os_popen(f"tidevice -u {self.devices} fsync -B {self.package} ls /Documents")
            if len(Documents) == 0:
                print("游戏没有启动过，无法推送 ue4commandline.txt")
                return

            with open("ue4commandline.txt", "w") as f:
                f.write(commandLineData)

            if len(commandLineData) == 0:
                print(os_popen(
                    f"tidevice -u {self.devices} fsync -B {self.package} rm /Documents/ue4commandline.txt"))
            else:
                print(os_popen(
                    f"tidevice -u {self.devices} fsync -B {self.package} push ue4commandline.txt /Documents/ue4commandline.txt"))


        else:

            UE4Game = os_popen(f"adb -s {self.devices} shell ls /sdcard/ | grep UE4Game")
            if UE4Game != "UE4Game":
                os_popen(f"adb -s {self.devices} shell mkdir /sdcard/UE4Game")

            ProjectDir = os_popen(
                f"adb -s {self.devices} shell ls /sdcard/UE4Game | grep {self.package_info['projectName']}")
            if ProjectDir != self.package_info['projectName']:
                os_popen(f"adb -s {self.devices} shell mkdir /sdcard/UE4Game/{self.package_info['projectName']}")

            # # 如果游戏已有 UE4CommandLine.txt，拉取到本地进行修改再推送到设备上
            # CommandLine = os_popen(f"adb -s {self.devices} shell ls /sdcard/UE4Game/{self.package_info['projectName']} | grep UE4CommandLine.txt")
            # if CommandLine == "UE4CommandLine.txt":
            #     os_popen(f"adb -s {self.devices} shell pull /sdcard/UE4Game/{self.package_info['projectName']}/UE4CommandLine.txt")

            # # 如果没有 UE4CommandLine.txt，直接新建空白 UE4CommandLine.txt
            # else:
            open("UE4CommandLine.txt", "w")

            data = commandLineData

            # # 根据参数修改命令行启动参数
            # with open("UE4CommandLine.txt", "r") as f:
            #     if insight == True:
            #         if data.count("-uautoprofile") == 0:
            #             data += " -uautoprofile"

            #         if data.count("-statnamedevents") == 0:
            #             data += " -statnamedevents"
            #     else:
            #         data = data.replace("-uautoprofile", "")
            #         data = data.replace("-statnamedevents", "")

            # data = data.strip()

            with open("UE4CommandLine.txt", "w") as f:
                f.write(data)

            if len(data) == 0:
                print(os_popen(
                    f"adb -s {self.devices} shell rm -rf /sdcard/UE4Game/{self.package_info['projectName']}/UE4CommandLine.txt"))


            else:
                # 将 UE4CommandLine.txt 推到目标设备上
                os_popen(
                    f"adb -s {self.devices} push UE4CommandLine.txt /sdcard/UE4Game/{self.package_info['projectName']}")

            # 开放应用读写 SD 卡权限
            os_popen(
                f"adb -s {self.devices} shell pm grant {self.package} android.permission.READ_EXTERNAL_STORAGE")
            os_popen(
                f"adb -s {self.devices} shell pm grant {self.package} android.permission.WRITE_EXTERNAL_STORAGE")

    # 运行应用
    def RunIPA(self):

        if self.FindIPA_APK():
            self.CloseIPA_APK(self.package)  # 关闭应用
            if self.platform == 'ios':
                print(os_popen(f'tidevice -u {self.devices} launch {self.package}'))
                time.sleep(20)
                # wda 点击允许
                if self.WDA_U2.alert.exists:
                    self.WDA_U2.alert.click_exists('无线局域网与蜂窝网络')
                    self.WDA_U2.alert.click_exists("允许")
                    self.WDA_U2.alert.click_exists("好")
                    self.WDA_U2.alert.click_exists("允许")
                    self.WDA_U2.alert.click_exists("好")
                    self.WDA_U2.alert.click_exists("允许")
                    self.WDA_U2.alert.click_exists("好")
                    self.WDA_U2.alert.click_exists("稍后")
                    self.WDA_U2.alert.click_exists("允许跟踪")
            else:
                if 'tgame' in self.package_url:
                    if self.task_parameters is not None:
                        if 'iscopy' in self.task_parameters and self.task_parameters['iscopy'] == 1:
                            print("使用替换方法替换资源")
                            self.ReplaceAssets()
                        else:
                            pass
                for i in range(2):
                    os_popen(f'adb -s \"{self.devices}\" shell am start \"{self.package}/{self.activity}\"')
                    time.sleep(5)
                    try:
                        self.WDA_U2.watcher('allow').when('始终允许').click()
                        self.WDA_U2.watcher('allow2').when('允许').click()
                        self.WDA_U2.watcher('allow3').when('确定').click()
                        self.WDA_U2.watcher('allow4').when('同意').click()
                        # wait and click
                        times = 20
                        while True:
                            self.WDA_U2.watcher.run()
                            times -= 1
                            if times == 0:
                                break
                            else:
                                time.sleep(0.5)
                    except Exception as e:
                        print(e)
            if self.FindRunIPA_APK():
                return True
        return False

    # 连接设备
    def ConnectDevice(self):
        try:
            print(f'[INFO] I Will Use APK_IPA File {self.package_url}')
            if not self.InitUiAuotmator():
                print('[ERROR] 设备不存在')
                return False
            if not self.FindIPA_APK():  # 是否有安装包
                print("安装ios包")
                self.Install_IOS_IPA()

            if self.FindIPA_APK():  # FindIPA_APK返回True
                print('[INFO] I Will Run IPA')
                bSucceed = self.RunIPA()  # return True
                if bSucceed:
                    print('[INFO] Run IPA Succeed')
                else:
                    print('[ERROR] Run IPA Failed')
            return bSucceed
        except Exception as e:
            traceback.print_exc()
        return False

    # 清理应用数据
    def ClearData(self):
        if self.platform == 'ios':
            self.UnInstall_IOS_IPA()
            time.sleep(10)
            self.Install_IOS_IPA()
        else:
            phone = os_popen(f'adb -s {self.devices} shell  pm clear {self.package}')
            print('清除 :', phone)
            if phone.find("Success"):
                self.UnInstall_IOS_IPA()
                time.sleep(10)
                self.Install_IOS_IPA()

    def kill_Wda(self):
        try:
            self.CloseIPA_APK(self.WDA_pack)
            list2 = []
            if platform.system().lower() == 'linux':

                self.wda_portname = os_popen(f'ps -ef | grep {str(self.wda_port)}')
                # print(self.wda_portname)
                if self.wda_portname:
                    self.wda_portname = self.wda_portname.split('\n')
                    for i in self.wda_portname:
                        if "relay" in i:
                            list2.append(i)
                    for i in list2:
                        PID = re.findall(r'\d{4,5}', i)
                        os_popen('kill -9 ' + PID[0])
                        print("wda_port " + str(PID[0]) + " killed")
            print('[INFO] Kill WDA Succeed')
        except:
            pass
        # 解锁点亮屏幕

    def unlock(self):
        if self.platform == 'android':
            os.system(f'adb -s {self.devices}  shell input keyevent 224')  # 点亮屏幕
            time.sleep(1)
            res = os_popen(f'adb -s {self.devices} shell "dumpsys deviceidle | grep mScreenOn"')
            if 'mScreenOn=false' in res:  # 当手机为息屏状态时候
                os.system(f'adb -s {self.devices}  shell input keyevent 26')
            wh = os_popen(f"adb -s {self.devices}  shell wm size")
            size = wh.replace(" ", "").replace('\n', '').split(":")[1].split("x")
            size[0] = re.sub('[^0-9]', '', size[0])
            size[1] = re.sub('[^0-9]', '', size[1])
            width, height = int(size[0]), int(size[1])
            os.system(f'adb -s {self.devices} shell input swipe {width / 2} {height * 0.8} {width / 2} {height * 0.4}')
            time.sleep(3)
            print("Are unlocked screen")
        else:
            # 电亮屏幕
            try:
                self.WDA_U2.unlock()
            except:
                pass
            time.sleep(1)
            print(self.WDA_U2.locked())
            if self.WDA_U2.locked() == False:
                print("Are unlocked screen")
            else:
                print("Are unlocked 失败")

        # 关闭屏幕

    def lock(self):
        self.CloseIPA_APK(self.package)  # 关闭应用
        if self.platform == 'android':
            if self.devices == '1d9ce083' or self.devices == 'N8K0217A20001633':
                print("VivoY79设备ATX解锁失效，所以不熄屏")
            else:
                os.system(f'adb -s {self.devices}  shell input keyevent 223')  # 熄灭屏幕
                time.sleep(1.50)
                res = os_popen(f'adb -s {self.devices} shell "dumpsys deviceidle | grep mScreenOn"')
                if 'mScreenOn=true' in res:  # 当手机为亮屏状态时
                    os.system(f'adb -s {self.devices}  shell input keyevent 26')
                print("Have lock screen")
        else:
            # 关闭屏幕
            try:
                self.WDA_U2.lock()
                time.sleep(1)
                if self.WDA_U2.locked() == True:
                    print("Have lock screen")
                else:
                    print("Have lock 失败")
            except:
                print(f"{self.devices}锁屏失败")

    # 点击指定坐标点
    def click(self, w, h):
        if self.platform == 'ios':
            size = self.WDA_U2.window_size()
            width, height = size[0], size[1]
            self.WDA_U2.click(int(width * w), int(height * h))
        else:
            wh = os_popen(f"adb -s {self.devices}  shell wm size")
            size = wh.replace(" ", "").replace('\n', '').split(":")[1].split("x")
            size = size
            width, height = int(size[0]) * w, int(size[1]) * h
            os_popen(f"adb -s  {self.devices} shell input tap {height} {width}")

    # 关闭弹窗
    def Pop_ups(self, time1):
        try:
            if self.platform == 'ios':
                while time1 <= 0:
                    if self.WDA_U2.alert.exists:
                        self.WDA_U2.alert.click(self.WDA_U2.alert.buttons())
                    time1 -= 1
                    time.sleep(0.5)
            else:
                self.WDA_U2.watcher('allow').when('始终允许').click()
                self.WDA_U2.watcher('allow2').when('允许').click()
                self.WDA_U2.watcher('allow3').when('确定').click()
                self.WDA_U2.watcher('allow3').when('确认').click()
                self.WDA_U2.watcher('allow4').when('稍后').click()
                times = time1
                while True:
                    self.WDA_U2.watcher.run()
                    times -= 1
                    if times <= 0:
                        break
                    else:
                        time.sleep(0.5)
        except Exception as e:
            print(e)
            # print(traceback.format_exc())

    def get_battery(self):
        battery = 0
        if self.platform == 'android':
            cmd = f'adb -s {self.devices}  shell "dumpsys battery | grep level"'
            battery = os_popen(cmd).split(':')[1]
        return int(battery)

    def version(self):
        # 转换出包的版本
        version = self.versionName.split('.')[0]
        return version

    def get_exist_on_server(self):
        # 检查服务器上是否存在目标版本的assets文件夹
        target_folder = Android_IOS.target_folder
        version = self.version

        folders = [
            folder
            for folder in os.listdir(target_folder)
            if os.path.isdir(os.path.join(target_folder, folder))
        ]

        exist = []
        for folder in folders:
            if version in folder:
                exist.append(folder)
            else:
                continue
        return exist

    def Check_available(self):
        # 校验地址的manifest.json是否存在
        manifest_url = self.package_url.split('packages/')[0] + 'updates/' + self.version + '.0/' + 'manifest.json'
        try:
            response = requests.get(manifest_url)
            if response.status_code == 200:
                with open('manifest.json', 'wb') as file:
                    file.write(response.content)

                with open('manifest.json', 'r') as file:
                    manifest_data = json.load(file)
                hash_name = {}
                for pak in manifest_data['paks']:
                    hash_name[pak['hash']] = pak['name']
                self.hash_name = hash_name
                return True
            else:
                return False
        except requests.exceptions.RequestException as e:
            return False

    async def download_single(self, session: aiohttp.ClientSession, url, download_folder, timeout):
        # 异步下载单个assets下的文件
        # async with semaphore:
        try:
            async with session.get(url, timeout=timeout) as response:
                file_name = url.split('/')[-1]
                file_path = os.path.join(download_folder, file_name)

                os.makedirs(os.path.dirname(file_path), exist_ok=True)

                with open(file_path, 'wb') as file:
                    response.read_timeout = 10 * 60
                    async for data in response.content.iter_chunked(1024):
                        file.write(data)
        except Exception as e:
            print(f"下载单个文件出错,将重试!!!: {e}")
            await self.download_single(session, url, download_folder, timeout)

    async def download_all(self, url, download_folder, timeout):
        # 异步下载assets全部文件
        conn = aiohttp.TCPConnector(force_close=True, ssl=False)  # 强制使用HTTP/1.1请求 3.0版本之后弃用verify_ssl

        async with aiohttp.ClientSession(connector=conn) as session:
            async with session.get(url, timeout=timeout) as response:
                html = await response.text()
                urls = [line.split('"')[1] for line in html.split('\n') if line.startswith('<a href="')]

                total_files = len(urls)
                completed_files = 0

                download_tasks = []
                for url in urls:
                    if not url.startswith("http"):
                        url = f"{response.url}{url}"
                    task = self.download_single(session, url, download_folder, timeout)
                    download_tasks.append(task)

                for task in asyncio.as_completed(download_tasks):
                    await task
                    completed_files += 1
                    progress = completed_files / total_files
                    print(f"Total progress: {progress:.1%}", end='\r')
                    sys.stdout.flush()
        print("Total progress: 100%")

    async def DownloadAssets(self):
        logger.info(f'{self.devices}-服务器资源下载中...')
        assets_url = self.package_url.split('packages/')[0] + 'updates/' + self.version + '.0/' + 'assets/'
        download_folder = Android_IOS.target_folder + self.version + '.0/'
        timeout = aiohttp.ClientTimeout(total=2 * 60 * 60)

        try:
            print(f'[INFO] I Will Download Assets File {assets_url}')
            await self.download_all(assets_url, download_folder, timeout)
            print(f'[INFO] Finished Download Assets File {assets_url}')
        except Exception as e:
            self.download_error = True
            print(f'[ERROR] Download Assets File Error! {e}')
            shutil.rmtree(download_folder)  # 清理已下载的文件
            logger.info('服务器下载资源出错，清理已下载文件完成')

    def CopyToDevices(self):
        logger.info(f'{self.devices}-在从服务器资源复制中...')
        devices_base_dir = '/storage/emulated/0/Android/data/com.dragonli.projectsnow/files/'

        server_dir = Android_IOS.target_folder + self.version + '.0'
        devices_dir = devices_base_dir + self.version + '.0'

        exist, pop_folder = False, ''
        find_devices_assets = f"adb -s {self.devices} shell find {devices_base_dir} -type d -name '*.0*'"
        # result = subprocess.run(find_devices_assets,shell=True,capture_output=True,text=True) # python3.6不支持capture_output参数
        result = subprocess.Popen(find_devices_assets, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                  universal_newlines=True)
        result.wait()
        stdout, stderr = result.communicate()
        if result.returncode == 0:
            assets_folder_list = stdout.splitlines()
            for folder in assets_folder_list:
                if self.version in folder:
                    exist = True
                else:
                    pop_folder = folder
        else:
            # 执行adb命令出错
            print('获取设备文件夹出错')
            create_dir = f"adb -s {self.devices} shell mkdir -p {devices_base_dir}"
            create_dir_result = subprocess.run(create_dir,shell=True)
            if create_dir_result.returncode == 0:
                print(f'在 {self.devices} 创建目录:{devices_base_dir}成功！！！')
            else:
                print(f'在 {self.devices} 创建目录:{devices_base_dir}失败！！！')
                return

        if exist:
            # 设备上存在文件不需要复制
            print('设备上存在文件不需要复制')
            return
        if pop_folder != '':
            # result = subprocess.run(f'adb -s {self.devices} shell rm -r {pop_folder}',shell=True,capture_output=True,text=True)   # python3.6不支持capture_output参数
            pop_folder_command = f'adb -s {self.devices} shell rm -r {pop_folder}'
            result = subprocess.Popen(pop_folder_command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                      universal_newlines=True)
            result.wait()
            if result.returncode == 0:
                print('成功删除旧版本Assets文件夹')
            else:
                # 执行adb命令出错
                print('移除旧版文件出错')
                return

        print(f'[INFO] Copy Assets File To Devices {self.devices}')
        os.system(f'adb -s {self.devices} push {server_dir}/ {devices_dir}/')
        print(f'[INFO] Copied Assets File To Devices {self.devices}')

    def ReplaceAssets(self):
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        # self.download_semaphore = asyncio.Semaphore(5, loop=loop)

        with self.download_lock:
            self.exist_on_server = self.get_exist_on_server()
            if self.exist_on_server:
                logger.info('服务器存在资源')
                pass
            else:
                logger.info('服务器不存在资源')
                if self.Check_available():
                    # manifest.json文件存在 执行下载
                    try:
                        loop.run_until_complete(self.DownloadAssets())
                    finally:
                        loop.close()
                    if self.download_error:
                        return
                    if not self.download_error:
                        self.RenameAssets()
                else:
                    # manifest.json文件不存在 资源可能不可用 不做处理
                    return
            if not self.download_error:
                self.CopyToDevices()

    def RenameAssets(self):
        print(f'[INFO] Rename Assets File')
        server_dir = Android_IOS.target_folder + self.version + '.0/'
        for hash, name in self.hash_name.items():
            old_fp = os.path.join(server_dir, hash)
            new_fp = os.path.join(server_dir, name)

            if os.path.exists(old_fp):
                os.rename(old_fp, new_fp)
        print(f'[INFO] Rename Assets File Finished')


# 封装了wda_u2类的操作方法类
class Wda_u2_operate(object):
    def __init__(self, wda_u2):
        # ios 为True android 为false
        self.ostf = True if type(wda_u2) == wda.USBClient else False
        self.wu = wda_u2

    def screenshot(self):
        self.wu.screenshot().save(f"{str(int(time.time()))}.jpg")

    def get_window_size(self):
        """获取设备分辨率"""
        return self.wu.window_size()

    def click_x_y(self, x, y):
        print("""点击坐标""")
        if x > 1:
            self.wu.click(int(x), int(y))
        else:
            self.wu.click(x, y)

    def tap_hold_x_y(self, x, y, duration=1):
        """长按坐标: duration 长按时间"""
        if self.ostf:
            self.wu.tap_hold(x, y, duration)
        else:
            self.wu.long_click(x, y, duration)

    def swipe(self, x1, y1, x2, y2):
        """滑动"""
        self.wu.swipe(x1, y1, x2, y2)

    def find_click(self, value, text_id="text") -> bool:
        """查找点击"""
        if text_id == "text":
            self.wu(text=value).click_exists(timeout=2)
            return True
        else:
            self.wu(resourceId=value).click_exists(timeout=2)
        return False

    def get_obj(self, value, text_id="text"):
        """获取文本对象"""
        if text_id == "text":
            if self.wu(text=value).exists:
                if self.ostf:
                    return self.wu(text=value).get()
                else:
                    return self.wu(text=value)
        else:
            if self.wu(resourceId=value).exists:
                if self.ostf:
                    return self.wu(resourceId=value).get()
                else:
                    return self.wu(resourceId=value)
        return False

    def find_exists(self, value, text_id="text"):
        """判断文本是否存在"""
        if text_id == "text":
            if self.wu(text=value).exists:
                return True
        else:
            if self.wu(resourceId=value).exists:
                return True
        return False

    def get_focused_text(self) -> str:
        """获取文本"""
        if self.ostf:
            return self.wu.session().active_element().get_text()
        else:
            return self.wu(focused=True).get_text()

    def set_focused_text(self, value):
        """写入文本"""
        if self.ostf:
            return self.wu.session().active_element().set_text(value)
        else:
            return self.wu(focused=True).set_text(value)

    def clear_focused_text(self):
        """清空文本"""
        if self.ostf:
            return self.wu.session().active_element().clear_text()
        else:
            self.wu.clear_text()

    def get_text(self, wu_uiele) -> str:
        """获取文本"""
        return wu_uiele.get_text()

    def set_text(self, wu_uiele, value):
        """写入文本"""
        wu_uiele.set_text(value)

    def clear_text(self, wu_uiele):
        """清空文本"""
        wu_uiele.clear_text()

    def Pop_ups(self, time):
        if self.ostf:
            while time <= 0:
                if self.wu.alert.exists:
                    self.wu.alert.click(self.wu.alert.buttons())
                time -= 1
        else:
            try:
                self.wu.watcher('allow').when('始终允许').click()
                self.wu.watcher('allow2').when('允许').click()
                self.wu.watcher('allow3').when('确定').click()
                times = time
                while True:
                    self.WDA_U2.watcher.run()
                    times -= 1
                    if times <= 0:
                        break
                    else:
                        time.sleep(0.5)
            except Exception as e:
                print(e)
if __name__ == '__main__':
    wc = wda.USBClient('00008020-001375CA2685002E', port=8100, wda_bundle_id='com.facebook.WebDriverAgentRunner.xctrunner.xctrunner')

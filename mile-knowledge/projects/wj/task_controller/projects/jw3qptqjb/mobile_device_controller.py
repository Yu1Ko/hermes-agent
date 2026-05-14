# -*- coding: utf-8 -*-
import os
import time

import wda
import logging, logging.handlers
from BaseToolFunc import *
import uiautomator2 as u2

# 子线程TaskRunProcess用于处理设备的总类
class Android_IOS(object):
    def __init__(self, deviceId,packageName,WDA_U2=None):
        self.system = 'findstr' if platform.system().lower() == 'windows' else 'grep'
        self.deviceId = deviceId
        self.packageName=packageName
        self.log=logging.getLogger(str(os.getpid()))
        self.log.info("Ini")
        #手机临时测试
        if self.deviceId=='00008110-000930A414D9801E':
            self.wdaName='com.facebook.WebDriverAgentRunner.xctrunner.xctrunner'
            #self.packageName='com.seasun.jx3'
        else:
            self.wdaName='com.facebook.WebDriverAgentRunner.xctrunner'
        if '-' in self.deviceId:
            self.platform = 'ios'
        else:
            self.platform='android'
        #初始化wda
        self.WDA_U2 = None
        self.nWDA_U2_RetryCnt = 0  # WDA和U2重连次数
        if WDA_U2 is None:
            self.ini_wda_u2()
        else:
            self.WDA_U2 = WDA_U2

        # 初始化完成后处理弹窗
        self.DealWith_Mobile_Window()
        #response = requests.get(f"{server_url}/task/get_appname_appkey")
        #listappkey = json.loads(response.content.decode("utf-8"))["data"]
        self.activity = ''
        self.strVersion = self.getAppVersion()
        self.log.info(f"AppVersion:{self.strVersion}")
        self.nAppStartTime=0
        self.nCoolTemperature=32 #冷机温度
        #设备初始化时需要清除日志
        #self.logcat_clear()

    #设备初始化完成后 需要出现处理一下弹窗
    def DealWith_Mobile_Window(self):
        self.log.info("DealWith_Mobile_Window start")
        self.keep_heart()
        if self.platform=='android':
            #self.WDA_U2.healthcheck()
            # 停止并移除所有的监控，常用于初始化
            #self.WDA_U2.watcher.reset()
            #self.WDA_U2.watcher.when('无限制').click()
            #self.WDA_U2.watcher.when('继续安装').click()
            #self.WDA_U2.watcher.when('完成').click()
            #self.WDA_U2.watcher.when('允许').click()
            # self.WDA_U2.watcher.run()
            if self.WDA_U2(text='无限制').exists:
                self.WDA_U2(text='无限制').click()
            if self.WDA_U2(text='继续安装').exists:
                self.WDA_U2(text='继续安装').click()
            if self.WDA_U2(text='稍后').exists:
                self.WDA_U2(text='稍后').click()
            if self.WDA_U2(text='完成').exists:
                self.WDA_U2(text='完成').click()
            if self.WDA_U2(text='允许').exists:
                self.WDA_U2(text='允许').click()
            if self.WDA_U2(text='知道了').exists:
                self.WDA_U2(text='知道了').click()
            if self.WDA_U2(text='自动下载').exists:
                self.WDA_U2(text='取消').click()
            if self.WDA_U2(text='文件传输').exists:
                self.WDA_U2(text='文件传输').click()
            if self.WDA_U2(text='传输文件').exists:
                self.WDA_U2(text='传输文件').click()
            # self.WDA_U2.healthcheck()
            time.sleep(2)
            # 移除所有的监控
            #self.WDA_U2.watcher.remove()
        else:
            if self.WDA_U2.alert.exists:
                self.WDA_U2.alert.click(self.WDA_U2.alert.buttons())
            time.sleep(2)
        self.log.info("DealWith_Mobile_Window End")

    #处理设备弹窗的线程
    def thread_DealWithMobileWindow(self,t_parent):
        self.log.info("thread_DealWithMobileWindow start")
        try:
            if self.platform=='android':
                self.WDA_U2.healthcheck()
                # 停止并移除所有的监控，常用于初始化
                #self.WDA_U2.watcher.reset()
                #self.WDA_U2.watcher.when('无限制').click()
                #self.WDA_U2.watcher.when('继续安装').click()
                #self.WDA_U2.watcher.when('完成').click()
                #self.WDA_U2.watcher.when('允许').click()
                while t_parent.is_alive():
                    self.wda_u2_Detect()
                    #self.WDA_U2.watcher.run()
                    if self.WDA_U2(text='无限制').exists:
                        self.WDA_U2(text='无限制').click()
                    if self.WDA_U2(text='已了解应用的风险检测结果').exists: #主要处理oppo和vivo
                        self.WDA_U2(text='已了解应用的风险检测结果').click()
                    if self.WDA_U2(text='继续安装').exists:
                        self.WDA_U2(text='继续安装').click()
                    if self.WDA_U2(text='完成').exists:
                        self.WDA_U2(text='完成').click()
                    if self.WDA_U2(text='允许').exists:
                        self.WDA_U2(text='允许').click()
                    if self.WDA_U2(text='知道了').exists:
                        self.WDA_U2(text='知道了').click()
                    if self.WDA_U2(text='无视风险安装').exists:
                        self.WDA_U2(text='无视风险安装').click()
                    #self.WDA_U2.healthcheck()
                    time.sleep(2)
                # 移除所有的监控
                #self.WDA_U2.watcher.remove()
            else:
                while t_parent.is_alive():
                    self.wda_u2_Detect()
                    if self.WDA_U2.alert.exists:
                        self.WDA_U2.alert.click(self.WDA_U2.alert.buttons())
                    time.sleep(2)
                self.WDA_U2.close()
        except Exception:
            info = traceback.format_exc()
            self.log.info(info)
        self.log.info("thread_DealWithMobileWindow end")

    def deal_with_install_exceptional_case(self,deviceId,t_parent):
        if '-' in deviceId:
            import wda
            wc = wda.USBClient(deviceId, port=8100,wda_bundle_id='com.facebook.WebDriverAgentRunner.xctrunner')
            while t_parent.is_alive():
                if wc.alert.exists:
                    strBtnName=wc.alert.buttons()[0]
                    wc.alert.click(wc.alert.buttons())
                    self.log.info(f"点击 {strBtnName}")
                time.sleep(1)
            wc.close()
        else:
            # 处理安装apk时出现的特殊情况
            d = u2.connect_usb(self.deviceId)
            # 检测设备的u2服务是否启动
            d.healthcheck()
            dic_deviceInfo = d.device_info
            # 停止并移除所有的监控，常用于初始化
            d.watcher.reset()
            d.watcher('allow_tp').when('允许').click()  # 自动点击系统弹窗,游戏可能会弹出什么提示
            d.watcher('allow_tp').when('是').click()  # 自动点击系统弹窗,游戏可能会弹出什么提示
            d.watcher.when('无限制').click()
            # 移除所有的监控
            # d.watcher.remove()

            # d.debug = True
            strBrand = dic_deviceInfo['brand'].lower()
            self.log.info(f'brand: {strBrand}')
            if strBrand == 'oppo' or strBrand == 'vivo':
                bTag = d(text='继续安装').exists
                nCount = 0
                while not bTag:
                    time.sleep(10)
                    bTag = d(text='继续安装').exists
                    nCount += 1
                    self.log.info("%s 继续安装 try %d" % (strBrand, nCount))
                self.log.info(f"{strBrand} 点击继续安装")
                time.sleep(10)
                d(text='继续安装').click()
                time.sleep(10)

                bTag = d(text='允许').exists
                nCount = 0
                while not bTag:
                    time.sleep(10)
                    bTag = d(text='允许').exists
                    nCount += 1
                    self.log.info("%s 允许 try %d" % (strBrand, nCount))
                self.log.info(f"{strBrand} 点击允许")
                d(text='允许').click()
                time.sleep(10)

    #按装app
    def install_app(self,strPackagepath,bFlag=True):
        # 处理弹窗线程
        if bFlag:
            self.log.info("install app start")
            t = threading.Thread(target=self.thread_DealWithMobileWindow, args=(threading.currentThread(),))
            t.setDaemon(True)
            t.start()
        #装包
        res=''
        if strOS == "Linux":
            strPackagepath = strPackagepath.replace('\\', os.sep)
        else:
            strPackagepath = strPackagepath.replace('/', os.sep)
        self.log.info(f'Packagepath :{strPackagepath}')
        if self.platform == 'android':
            cmd = f'adb -s {self.deviceId} install -d {strPackagepath}'
            #self.log.info(cmd)
            #self.log.info(cmd)
            pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            res = pi.stdout.read()
            ret_error = pi.stderr.readline()
            self.log.info(ret_error)
            try:
                res = str(res, encoding='gbk')
            except:
                res = str(res, encoding='utf8')

            if 'success' in res.lower():
                self.log.info(f" app install result: {res}")
            else:
                raise Exception(f"app install fail:  {res}")

        else:
            cmd = f'tidevice -u {self.deviceId} install {strPackagepath}'
            #cmd = f'pymobiledevice3 apps install {strPackagepath} --udid {self.deviceId}'
            pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            res = pi.stdout.read()
            #ret_error = pi.stderr.readline()
            try:
                res = str(res, encoding='gbk')
            except:
                res = str(res, encoding='utf8')



    # 卸载app
    def uninstall_app(self,packageName=None):
        if not packageName:
            packageName = self.packageName
        if self.platform == 'android':
            cmd = f'adb -s {self.deviceId} uninstall {packageName}'
            pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            #res = pi.stdout.read()
            #ret_error = pi.stderr.readline()
            #self.log.info(res)
            #self.log.info(ret_error)
        else:
            #cmd = f'tidevice -u {self.deviceId} uninstall {packageName}'
            #pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            cmd = f'pymobiledevice3 apps uninstall {packageName} --udid {self.deviceId}'
            pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            #res = pi.stdout.read()
            #ret_error = pi.stderr.readline()
            #self.log.info(res)
            #self.log.info(ret_error)

    #清空后台
    def clear_background(self):
        if self.platform == 'android':
            #后台窗口
            self.WDA_U2(resourceId="com.android.systemui:id/recent_apps").click()
            time.sleep(2)
            # 清除后台按钮
            self.WDA_U2(resourceId="com.android.launcher:id/btn_clear").click()
        else:
            #ios清除不了后台
            self.kill_app()

    #获取app版本号
    def getAppVersion(self):
        if not self.find_app():
            return "no app"
        if self.platform == 'android':
            return self.WDA_U2.app_info(self.packageName)["versionName"]
        else:
            '''
            cmd = f"pymobiledevice3 apps query {self.packageName} --udid {self.deviceId}"
            pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
            res = pi.stdout.read()
            try:
                res = str(res, encoding='gbk')
            except:
                res = str(res, encoding='utf8')
                dic_info=json.loads(re.sub(r'\x1b\[[0-9;]*m', '', res))
            return dic_info[self.packageName]['CFBundleShortVersionString']'''
            return "1.0.0"

            '''
            cmd = f'tidevice -u {self.deviceId} applist'
            pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
            res = pi.stdout.read()
            try:
                res = str(res, encoding='gbk')
            except:
                res = str(res, encoding='utf8')
            for strAppInfo in res.split('\r\n'):
                if self.packageName in strAppInfo:
                    return strAppInfo.split(' ')[-1]'''

    #获取电量
    def get_battery(self):
        if self.platform == 'android':
            cmd = ["adb", "-s", self.deviceId, "shell", "dumpsys", "battery"]
            output = subprocess.run(cmd, stdout=subprocess.PIPE, text=True).stdout

            level, temperature = None, None
            for line in output.splitlines():
                line = line.strip()
                if line.startswith("level:"):
                    level = int(line.split(":")[1].strip())
                elif line.startswith("temperature:"):
                    temperature = int(line.split(":")[1].strip()) / 10.0  # 转摄氏度
            return level
        else:
            cmd = f'tidevice -u {self.deviceId} battery'
            pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
            res = pi.stdout.read()
            try:
                res = str(res, encoding='gbk')
            except:
                res = str(res, encoding='utf8')
            print(res)
            for strBatteryInfo in res.split('\r\n'):
                list_BatteryInfo = strBatteryInfo.split(' ')
                strInfo = list_BatteryInfo[-1]
                if '%' in strInfo:
                    # self.log.info(strInfo)
                    return int(strInfo.split('%')[0])
            # self.log.info(res)

    #截图
    def screenshot(self,savepath):
        if self.platform == 'android':
            strDevicePath = '/sdcard/screenshot.png'
            cmd = f'adb -s {self.deviceId} shell screencap -p {strDevicePath}'
            order = f"adb -s {self.deviceId} pull {strDevicePath} {savepath}"
            pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
            res = pi.stdout.read()
            try:
                res = str(res, encoding='gbk')
            except:
                res = str(res, encoding='utf8')
            self.log.info(res)
            pi = subprocess.Popen(order, shell=True, stdout=subprocess.PIPE)
            res = pi.stdout.read()
            try:
                res = str(res, encoding='gbk')
            except:
                res = str(res, encoding='utf8')
            self.log.info(res)
        else:
            cmd = f"pymobiledevice3 developer dvt screenshot {savepath} --udid {self.deviceId}"
            pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
            res = pi.stdout.read()
            try:
                res = str(res, encoding='gbk')
            except:
                res = str(res, encoding='utf8')
            self.log.info(res)

            '''
            cmd = f'tidevice -u {self.deviceId} screenshot {savepath}'
            pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
            res = pi.stdout.read()
            try:
                res = str(res, encoding='gbk')
            except:
                res = str(res, encoding='utf8')
            self.log.info(res)'''

    def screenshot2(self,strScreenShotPath):
        self.keep_heart()
        try:
            if self.platform == 'android':
                self.WDA_U2.screenshot().save(strScreenShotPath)
            else:
                #self.screenshot(strScreenShotPath)
                self.WDA_U2.screenshot().save(strScreenShotPath)
        except Exception as e:
            info = traceback.format_exc()
            self.log.info(info)
            self.log.info("截图失败")


    #后台截图
    def switch_background(self,strScreenShotPath):
        if self.platform == 'android':
            self.WDA_U2.healthcheck()
            self.WDA_U2(resourceId="com.android.systemui:id/recent_apps").click()
            time.sleep(3)
            self.WDA_U2.screenshot().save(strScreenShotPath)
            time.sleep(3)
            self.WDA_U2(resourceId="com.android.systemui:id/recent_apps").click()
            time.sleep(1)
        else:
            self.screenshot(strScreenShotPath)
            #需要把悬浮放到右下角并且设备悬浮双击快捷键
            #w, h = self.WDA_U2.window_size()
            #self.WDA_U2.double_tap(int(w * 0.91), int(h * 0.95))
            #time.sleep(3)
            #self.WDA_U2.screenshot(strScreenShotPath)
            #time.sleep(2)
            #self.WDA_U2.healthcheck()
            #time.sleep(1)
            #self.WDA_U2.healthcheck()
            #self.WDA_U2.close()

    def logcat_clear(self,deviceId=None):
        if not deviceId:
            deviceId=self.deviceId
        if self.platform == 'android':
            cmd = f"adb -s {deviceId} logcat -c"
            pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        else:
            strTempPath = os.path.join(os.getcwd(), 'Crash')
            if filecontrol_existFileOrFolder(strTempPath):
                filecontrol_deleteFileOrFolder(strTempPath)
            filecontrol_createFolder(strTempPath)
            cmd = f"tidevice -u {deviceId} crashreport {strTempPath}"
            pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            filecontrol_deleteFileOrFolder(strTempPath)

    #检查是否crash
    def check_crash(self,packageName=None):
        if not packageName:
            packageName=self.packageName
        if self.platform == 'android':
            cmd = f"adb -s {self.deviceId} shell dumpsys activity | {self.system} {packageName}"
            pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            res = pi.stdout.read()
            try:
                res = str(res, encoding='gbk')
            except:
                res = str(res, encoding='utf8')
            for strLine in res.split('\n'):
                if 'crashed' in strLine.lower():
                    return True
            return False
        else:
            ''''''
            cmd = f"tidevice -u {self.deviceId} applist"
            strAppName = ''
            pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            res = pi.stdout.read()
            try:
                res = str(res, encoding='gbk')
            except:
                res = str(res, encoding='utf8')
            for strAppInfo in res.split('\n'):
                if packageName in strAppInfo:
                    strAppName = strAppInfo.split(' ')[1].lower()
                    break
            strTempPath = os.path.join(os.getcwd(), 'Crash')
            if filecontrol_existFileOrFolder(strTempPath):
                filecontrol_deleteFileOrFolder(strTempPath)
            filecontrol_createFolder(strTempPath)

            # 保留系统宕机原始文件
            #self.log.info("crash")
            #self.log.info(strTempPath)
            cmd = f"tidevice -u {self.deviceId} crashreport {strTempPath}"
            pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            res = pi.stdout.read()
            bCrashFlag = False
            for fileName in os.listdir(strTempPath):
                if strAppName in fileName.lower():
                    bCrashFlag = True
                    break
            return bCrashFlag

    #判断app是否处于运行状态
    def determine_runapp(self,packageName=None):
        if not packageName:
            packageName = self.packageName
        if self.platform == 'android':
            '''部分android系统会失效
            cmd = f"adb -s {self.deviceId} shell dumpsys activity activities | {self.system} mResumedActivity"
            pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            res = pi.stdout.read()
            ret_error = pi.stderr.readline()
            # self.log.info(res)
            # self.log.info(ret_error)
            try:
                res = str(res, encoding='gbk')
            except:
                res = str(res, encoding='utf8')
            if packageName in res:
                return True
            return False'''
            return self.WDA_U2.app_current()['package'] == packageName
        else:
            return self.WDA_U2.app_current()['bundleId'] == packageName

    # 获取测试机电池温度
    def mobile_get_Battery_temperature(deviceID):
        if '-' in deviceID:
            return tidevice_get_Battery_temperature(deviceID)
        else:
            return adb_get_Battery_temperature(deviceID)

    # 获取Android测试机电池温度
    def adb_get_Battery_temperature(deviceID):
        cmd = f'adb -s {deviceID} shell "dumpsys battery"'
        result = os.popen(cmd).read().split('\n')
        temperateure = ''
        for line in result:
            if ('temperature' in line):
                wendu = line.split(':')
                temperateure = int(wendu[1]) / 10.0
                break
        return round(temperateure, 1)

    # 获取IOS测试机电池温度
    def tidevice_get_Battery_temperature(UDID):
        cmd = f'tidevice -u {UDID} battery'
        with os.popen(cmd) as fp:
            bf = fp._stream.buffer.read()
        alldata = bf.decode().strip()
        dataList = alldata.split()
        temperateure = ''
        for index, value in enumerate(dataList):
            if value == '电池温度':
                temperateure = dataList[index + 1]
        result = int(temperateure.split('/')[0]) / 100.0

        return round(result, 1)


    #push文件
    def filecontrol_push(self,src, dst):
        if self.platform == 'android':
            order = f"adb -s {self.deviceId} push {src} {dst}"
            #self.log.info(order)
            pi = subprocess.Popen(order, shell=True, stdout=subprocess.PIPE)
            res = pi.stdout.read()
            try:
                res = str(res, encoding='gbk')
            except:
                res = str(res, encoding='utf8')
            # if 'error' in res:
            # raise Exception(res)
            self.log.info(res)
        else:
            order = f"tidevice -u {self.deviceId} fsync -B {self.packageName} push {src} {dst}"
            #self.log.info(order)
            pi = subprocess.Popen(order, shell=True, stdout=subprocess.PIPE)
            res = pi.stdout.read()
            try:
                res = str(res, encoding='gbk')
            except:
                res = str(res, encoding='utf8')
            # if 'error' in res:
            # raise Exception(res)
            self.log.info(res)

    #pull文件
    def filecontrol_pull(self, src, dst):
        if self.platform == 'android':
            order = f"adb -s {self.deviceId} pull {src} {dst}"
            pi = subprocess.Popen(order, shell=True, stdout=subprocess.PIPE)
            #res = pi.stdout.read()
            #try:
                #res = str(res, encoding='gbk')
            #except:
                #res = str(res, encoding='utf8')
            # if 'error' in res:
            # raise Exception(res)
            #self.log.info(res)
        else:
            order = f"tidevice -u {self.deviceId} fsync -B {self.packageName} pull {src} {dst}"
            pi = subprocess.Popen(order, shell=True, stdout=subprocess.PIPE)
            #res = pi.stdout.read()
            #try:
                #res = str(res, encoding='gbk')
            #except:
                #res = str(res, encoding='utf8')
            # if 'error' in res:
            # raise Exception(res)
            #self.log.info(res)

    #创建路径
    def filecontrol_mkdir(self,strPath):
        if self.platform == 'android':
            cmd = f"adb -s {self.deviceId} shell mkdir {strPath}"
            pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            #res = pi.stdout.read()
            #try:
                #res = str(res, encoding='gbk')
            #except:
                #res = str(res, encoding='utf8')
            #self.log.info(res)
        else:
            cmd = f"tidevice -u {self.deviceId} fsync -B {self.packageName} mkdir {strPath}"
            pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            #res = pi.stdout.read()
            #try:
                #res = str(res, encoding='gbk')
            #except:
                #res = str(res, encoding='utf8')
            #self.log.info(res)

    #创建文件夹
    def filecontrol_createFolder(self,dst):
        dst = dst.replace('\\', '/')
        if 'sdcard/Android' in dst:
            # 安卓以files文件夹为base文件夹
            strBasePath = dst[:dst.find('files') + 5]
        else:
            # ios以Documents文件夹为base文件夹
            strBasePath = dst[:dst.find('Documents') + 9]

        strMkDir = dst[len(strBasePath) + 1:]
        list_Mkdir = strMkDir.split('/')
        for dir in list_Mkdir:
            strBasePath = strBasePath + '/' + dir
            self.filecontrol_mkdir(strBasePath)

    #内置函数创建文件夹
    def __copyFileOrFolder(self,src, dst):
        if '.' in src:
            self.filecontrol_push(src, dst)
            return
        self.filecontrol_mkdir(dst)
        for file in os.listdir(src):
            self.__copyFileOrFolder(src + '/' + file, dst + '/' + file)

    #拷贝文件或文件
    def filecontrol_copyFileOrFolder(self,src, dst):
        if 'sdcard/Android' in src or '/Documents' in src :
            src = src.replace('\\', '/')
            return self.filecontrol_pull(src, dst)
        elif 'sdcard/Android' in dst or '/Documents' in dst:
            dst = dst.replace('\\', '/')
            strPath = dst[:dst.find(dst.split('/')[-1]) - 1]
            self.filecontrol_createFolder(strPath)
            self.__copyFileOrFolder(src, dst)
        else:
            raise Exception(f"{src} 或者 {dst} 有误")

    #删除文件
    def filecontrol_deleteFileOrFolder(self,strPath):
        strPath = strPath.replace('\\', '/')
        if 'sdcard/Android' in strPath:
            list_content = strPath.split('/')
            cmd = f"adb -s {self.deviceId} shell rm {strPath}"
            if '.' not in list_content[len(list_content) - 1]:
                cmd = f"adb -s {self.deviceId} shell rm -r {strPath}"
            pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            res = pi.stdout.read()
            ret_error = pi.stderr.readline()
            if 'No such file or directory' in str(ret_error, encoding='gbk'):
                return False
            else:
                return True
        else:
            list_content = strPath.split('/')
            cmd = f"tidevice -u {self.deviceId} fsync -B {self.packageName} rmtree {strPath}"
            if '.' in list_content[len(list_content) - 1]:
                cmd = f"tidevice -u {self.deviceId} fsync -B {self.packageName} rm  {strPath}"
            self.log.info(cmd)
            pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            res = pi.stdout.read()
            self.log.info(res)
            ret_error = pi.stderr.readline()
            # if remove a not exist file with have blew errror info
            #
            if 'No such file or directory' in str(ret_error, encoding='gbk'):
                return False
            else:
                return True

    #判断文件或者文件夹是否存在
    def filecontrol_existFileOrFolder(self, strPath):
        strPath=strPath.replace('\\', '/')
        if 'sdcard/Android' in strPath:
            cmd = f"adb -s {self.deviceId} shell ls {strPath}"
            # self.log.info(cmd)
            pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            res = pi.stdout.read()
            # self.log.info(res)
            ret_error = pi.stderr.readline()
            # self.log.info(ret_error)
            # ret_code = pi.returncode
            # self.log.info('filecontrol_file_exist: %s res= %s ret_code=%d ret_error=%s' % (cmd, res, 1, ret_error))
            # self.log.info('[DEBUG] %s [Res] %s' % (cmd, ret_error))
            if 'No such file or directory' in str(ret_error, encoding='gbk'):
                return False
            else:
                return True
        elif '/Documents' in strPath:
            cmd = f"tidevice -u {self.deviceId} fsync -B {self.packageName} ls {strPath}"
            # self.log.info(cmd)
            pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            res = pi.stdout.read()
            # self.log.info(res)
            ret_error = pi.stderr.readline()
            if strPath.split('/')[-1] not in str(res, encoding='gbk'):
                return False
            else:
                return True
        else:
            raise Exception(f'路径有误: {strPath}')

    def get_Battery_temperature(self):
        #获取电池温度
        if self.platform == 'android':
            cmd = f'adb -s {self.deviceId} shell "dumpsys battery"'
            result = os.popen(cmd).read().split('\n')
            temperateure = ''
            for line in result:
                if ('temperature' in line):
                    wendu = line.split(':')
                    temperateure = int(wendu[1]) / 10.0
                    break
            return round(temperateure, 1)
        else:
            cmd = f'tidevice -u {self.deviceId} battery'
            with os.popen(cmd) as fp:
                bf = fp._stream.buffer.read()
            try:
                alldata = bf.decode('utf8').strip()
            except:
                alldata = bf.decode('gbk').strip()
            dataList = alldata.split()
            temperateure = ''
            for index, value in enumerate(dataList):
                if value == '电池温度':
                    temperateure = dataList[index + 1]
            result = int(temperateure.split('/')[0]) / 100.0
            return round(result, 1)

    def device_cooling_to_temperature(self,nTemperature=None):
        #设备电池冷却至固定温度 默认32度 温度不能低于25度,-1度代表不用冷机
        if nTemperature:
            self.nCoolTemperature=nTemperature
        if self.nCoolTemperature==-1:
            return
        elif self.nCoolTemperature<25:
            self.nCoolTemperature=25
        #设置超时时长 20分钟
        # 锁屏冷机效率更高
        self.lock()
        nMaxCnt=20
        nCounter=1
        while self.get_Battery_temperature()>self.nCoolTemperature:
            time.sleep(60)
            nCounter+=1
            if nCounter>nMaxCnt:
                break
        #self.unlock()  #冷机结束后不用解锁,用例开始前会自动解锁
        self.log.info(f'cooling timer:{nCounter}分钟')

    #查找设备是否按照app
    def find_app(self,packageName=None):
        if not packageName:
            packageName = self.packageName
        if self.platform == 'android':
            cmd = f'adb -s {self.deviceId} shell "pm list packages -3 | grep {packageName}"'
            self.log.info(cmd)
            packagelist = os.popen(cmd).read().replace("\n", "")  # 拿包名
            if packagelist.split(':')[-1].strip()==packageName:
                return True
        else:
            cmd = f'tidevice -u {self.deviceId} applist | {self.system} {packageName} '
            pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
            res = pi.stdout.read()
            try:
                res = str(res, encoding='gbk')
            except:
                res = str(res, encoding='utf8')
            if res.split(' ')[0].strip()==packageName:
                return True
        return False

    def device_reboot(self):
        if self.platform == 'android':
            cmd = f"adb -s {self.deviceId} reboot"
        else:
            cmd = f"tidevice -u {self.deviceId} reboot"
        pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
        res = pi.stdout.read()
        try:
            res = str(res, encoding='gbk')
        except:
            res = str(res, encoding='utf8')
        self.log.info(f"device_reboot_result:{res}")
        time.sleep(10)
        #处理锁屏
        if self.platform == 'android':
            pass
        else:
            # 等待设备重启
            pass
            '''
            cmd = f"tidevice -u {self.deviceId} applist"
            while True:
                try:
                    pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
                    res = pi.stdout.read()
                    try:
                        res = str(res, encoding='gbk')
                    except:
                        res = str(res, encoding='utf8')
                    if self.wdaName in res:
                        break
                    time.sleep(10)
                except:
                    pass
            cmd = f"tidevice -u {self.deviceId} launch {self.wdaName}"
            pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)'''


    #启动app
    def start_app(self,packageName=None):
        if not packageName:
            packageName = self.packageName
        #self.WDA_U2.app_start(packageName)
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
            #self.keep_heart()
            #self.WDA_U2.app_start(self.packageName)
            cmd = f"pymobiledevice3 developer dvt launch {packageName} --udid {self.deviceId}"
            pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
            res = pi.stdout.read()
            try:
                res = str(res, encoding='gbk')
            except:
                res = str(res, encoding='utf8')
            print(res)
            return res

    # 启动app
    def start_app_wda(self, packageName=None):
        if not packageName:
            packageName = self.packageName
        # self.WDA_U2.app_start(packageName)
        self.nAppStartTime = int(time.time())
        self.WDA_U2.app_start(packageName)


    #结束app
    def kill_app(self,packageName=None):
        if not packageName:
            packageName = self.packageName
        if self.platform == 'android':
            cmd = f'adb -s {self.deviceId} shell am force-stop "{packageName}"'
            pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
            res = pi.stdout.read()
            try:
                res = str(res, encoding='gbk')
            except:
                res = str(res, encoding='utf8')
            self.log.info(res)
        else:
            self.keep_heart()
            self.WDA_U2.app_stop(packageName)
        self.log.info(f"kill app {packageName} success")
        '''
        cmd = f'tidevice -u {self.deviceId} kill {packageName}'
        # 执行一次有一定概率失败 所有执行两次
        pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
        time.sleep(1)
        pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
        res = pi.stdout.read()
        try:
            res = str(res, encoding='gbk')
        except:
            res = str(res, encoding='utf8')
        self.log.info(res)
        '''

        # 结束app
    def kill_app2(self, packageName=None):
        if not packageName:
            packageName = self.packageName
        if self.platform == 'android':
            cmd = f'adb -s {self.deviceId} shell am force-stop "{packageName}"'
        else:
            cmd = f'pymobiledevice3 developer dvt pkill --bundle {packageName} --udid {self.deviceId}'
            # 执行一次有一定概率失败 所有执行两次
        pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
        res = pi.stdout.read()
        try:
            res = str(res, encoding='gbk')
        except:
            res = str(res, encoding='utf8')
        self.log.info(f"kill app {packageName} success res:{res}")


    #获取设备的ip地址
    def get_address(self,deviceId=None):
        if not deviceId:
            deviceId=self.deviceId
        if self.platform == 'android':
            self.log.info("test1")
            cmd = f"adb -s {deviceId} shell ip -f inet addr|{self.system} wlan0"
            pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            res = pi.stdout.read()
            try:
                res = str(res, encoding='gbk')
            except:
                res = str(res, encoding='utf8')
            self.log.info(res)
            for strLine in res.split('\n'):
                if 'inet' in strLine:
                    return strLine.split(' ')[5].split('/')[0]
            return 'error'
        else:
            return self.WDA_U2.status()['ios']['ip']

    def Ini(self):
        pass

    # 下载安装包到本地并分析出包体信息
    def GetIPAInfo(self, packageinfo, process_lock):
        try:
            package_info = json.loads(packageinfo)
            self.log.info('URL包体信息', package_info)
            self.package = package_info["packagename"]
            self.log.info(f"self.package{self.package}")
            self.activity = package_info["activity"]
            self.versionName = package_info["versionName"]
            self.appkey = package_info["appkey"]
            return package_info
        except Exception as e:
            traceback.self.log.info_exc()


    # ios的facebook_wda测试工具初始化、安卓的uautomator2测试工具初始化
    def ini_wda_u2(self):
        try:
            if self.platform == 'ios':
                #重置wda状态  1.初始化时 2.出现3次重连失败s
                if self.nWDA_U2_RetryCnt==0 or self.nWDA_U2_RetryCnt==2:
                    #self.kill_app2(self.wdaName)
                    # 启动开发者镜像服务ios>=17
                    cmd = f'pymobiledevice3 mounter auto-mount --udid {self.deviceId}'
                    pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
                    time.sleep(1)
                    self.start_app(self.wdaName)
                    time.sleep(3)
                if self.nWDA_U2_RetryCnt == 2:
                    self.nWDA_U2_RetryCnt=1
                self.nWDA_U2_RetryCnt+=1
                self.WDA_U2 = wda.USBClient(self.deviceId, port=8100, wda_bundle_id=self.wdaName)
                #self.kill_app(self.wdaName)
                #self.WDA_U2 = wda.USBClient(self.deviceId, port=8100,wda_bundle_id=self.wdaName)
                #self.WDA_U2.deactivate()
            else:
                if ':' in self.deviceId:
                    self.WDA_U2 = u2.connect_adb_wifi(self.deviceId)
                else:
                    self.WDA_U2 = u2.connect_usb(self.deviceId)
                #self.WDA_U2.healthcheck()
            self.log.info('wda_u2 ini success')
        except Exception as e:
            info = traceback.format_exc()
            #self.ini_wda_u2()
            self.log.info(info)
            self.log.info('Start WDA_uiautomator2 Failed')

    def unIni_wda_u2(self):
        if self.platform == 'android':
            pass
        else:
            self.WDA_U2 = wda.USBClient(self.deviceId, port=8100,wda_bundle_id=self.wdaName)
            self.kill_app(self.wdaName)

    def keep_heart(self):
        try:
            if self.platform == 'ios':
                self.WDA_U2.device_info()
            else:
                self.WDA_U2.device_info
        except Exception as e:
            info = traceback.format_exc()
            self.log.info(info)
            self.log.info("keep_heart error 重启 WDA_U2")
            self.ini_wda_u2()

    def kill_Wda(self):
        try:
            self.CloseIPA_APK(self.WDA_pack)
            list2 = []
            if platform.system().lower() == 'linux':

                self.wda_portname = os.popen(f'ps -ef | grep {str(self.wda_port)}').read()
                # self.log.info(self.wda_portname)
                if self.wda_portname:
                    self.wda_portname = self.wda_portname.split('\n').strip()
                    for i in self.wda_portname:
                        if "relay" in i:
                            list2.append(i)
                    for i in list2:
                        PID = re.findall(r'\d{4,5}', i)
                        os.popen('kill -9 ' + PID[0]).read()
                        self.log.info("wda_port " + str(PID[0]) + " killed")
            self.log.info('[INFO] Kill WDA Succeed')
        except:
            pass
        # 解锁点亮屏幕

    def unlock(self):
        if self.platform == 'android':
            os.system(f'adb -s {self.deviceId}  shell input keyevent 224')  # 点亮屏幕
            time.sleep(1)
            with  os.popen(f'adb -s {self.deviceId} shell "dumpsys deviceidle | grep mScreenOn"') as p:
                res = p.read()  # 获取手机状态
            if 'mScreenOn=false' in res:  # 当手机为息屏状态时候
                os.system(f'adb -s {self.deviceId}  shell input keyevent 26')
            wh = os.popen(f"adb -s {self.deviceId}  shell wm size").read()
            size = wh.replace(" ", "").replace('\n', '').split(":")[1].split("x")
            size[0] = re.sub('[^0-9]', '', size[0])
            size[1] = re.sub('[^0-9]', '', size[1])
            width, height = int(size[0]), int(size[1])
            os.system(f'adb -s {self.deviceId} shell input swipe {width / 2} {height * 0.8} {width / 2} {height * 0.4}')
            time.sleep(3)
            self.log.info("Are unlocked screen")
        else:
            # 电亮屏幕
            try:
                self.WDA_U2.unlock()
            except:
                pass
            time.sleep(1)
            self.log.info(self.WDA_U2.locked())
            if self.WDA_U2.locked() == False:
                self.log.info("Are unlocked screen")
            else:
                self.log.info("Are unlocked 失败")

        # 关闭屏幕

    def lock(self):
        if self.platform == 'android':
            os.system(f'adb -s {self.deviceId}  shell input keyevent 223')  # 熄灭屏幕
            time.sleep(1.50)
            with  os.popen(f'adb -s {self.deviceId} shell "dumpsys deviceidle | grep mScreenOn"') as p:
                res = p.read()  # 获取手机状态
            if 'mScreenOn=true' in res:  # 当手机为亮屏状态时
                os.system(f'adb -s {self.deviceId}  shell input keyevent 26')
            self.log.info("Have lock screen")
        else:
            # 关闭屏幕
            try:
                self.WDA_U2.lock()
                time.sleep(1)
                if self.WDA_U2.locked() == True:
                    self.log.info("Have lock screen")
                else:
                    self.log.info("Have lock 失败")
            except:
                self.log.info(f"{self.deviceId}锁屏失败")

    # 点击指定坐标点
    def click(self, w, h):
        if self.platform == 'ios':
            size = self.WDA_U2.window_size()
            width, height = size[0], size[1]
            self.WDA_U2.click(int(width * w), int(height * h))
        else:
            wh = os.popen(f"adb -s {self.deviceId}  shell wm size").read()
            size = wh.replace(" ", "").replace('\n', '').split(":")[1].split("x")
            size = size
            width, height = int(size[0]) * w, int(size[1]) * h
            os.popen(f"adb -s  {self.deviceId} shell input tap {height} {width}")

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
            self.log.info(e)


    def wda_u2_Detect(self):
        try:
            self.WDA_U2.info
        except:
            self.ini_wda_u2()

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
        self.log.info("""点击坐标""")
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
                self.log.info(e)

# ver:3.6
# -*- coding: utf-8 -*-
import os
import time

from CaseCommon import *
#from PerfMonCtrl import *
from PerfeyeCtrl import *
import psutil

LOCAL_PACKAGE_VERSION_PATH = os.path.join("..", "..", "..", "xgame_package_version.ini")

from XGameSocketClient import *
class CaseJX3Client(CaseCommon):

    def __init__(self):
        CaseCommon.__init__(self)
        # self.setClientPath(clientType)
        self.listThreads_beforeStartClient = []
        self.offlineSwitch = False
        self.BIN64_NAME = 'bin64'
        self.clientPID = 0
        self.initiator_version = None
        self.exename='null'
        self.bMobile=False
        self.bPerfeyeExist=False
        # 移动端必先等perfeye获取applist后才能启动app 避免因为启动app后卡端导致获取applist失败
        self.bCanStartClient = False
        self.nClientRunTime = 0
        self.strClientUUID=None  #crasheye捕获到宕机后才会写这个UUID
        self.strClientLog=None  #本地客户日志位置
        self.strClientScreen=None   #本地存放的客户端截图
        self.bAutoLogin=True #是否需要自动登录
        self.strGuid = machine_get_guid()  #获取IQB设备的GUID 移动端设备根文件夹就是GUID 如:Android-79a0d4
        self.nClientStartTime=0 #客户端启动时间
        self.nFrame=0 #客户端默认帧率 0:使用该档画质的默认配置 根据配置文件中的FreeFrame调整
        self.bRandomAcount=True #释放使用随机账号
        self.strResource='3' #资源下载  0:下载资源  1:下载基础包 2:下载基础包+扩展包 3:TDR资源包
        self.strVersion=None #代码—资源版本
        self.nTemperature=31 #冷机温度

    def loadDataFromLocalConfig(self, dic_args):
        #获取配置文件中的相关信息
        self.pathLocalConfig = os.path.join(dic_args['pathClient'], 'LocalConfig.ini')
        self.strMachineName = ini_get('local', 'machine_id', self.pathLocalConfig)
        self.strAccount = ini_get('AutoLogin', 'account', self.pathLocalConfig)
        self.strPassword = ini_get('AutoLogin', 'password', self.pathLocalConfig)
        self.strRoleName = ini_get('AutoLogin', 'RoleName', self.pathLocalConfig)
        self.strSchool_type = ini_get('AutoLogin', 'school_type', self.pathLocalConfig)
        self.strRole_type = ini_get('AutoLogin', 'role_type', self.pathLocalConfig)
        #默认 纯阳-成男  参数列表可调整
        self.strSchool_type='纯阳'
        self.strRole_type='成男'
        self.strStepTime = ini_get('AutoLogin', 'StepTime', self.pathLocalConfig)
        self.strSwitch = ini_get('AutoLogin', 'Switch', self.pathLocalConfig)
        self.strDisplayRegion = ini_get('AutoLogin', 'szDisplayRegion', self.pathLocalConfig)
        self.strDisplayServer = ini_get('AutoLogin', 'szDisplayServer', self.pathLocalConfig)
        try:
            #部分设备没有这个标签
            self.strResource=ini_get('AutoLogin', 'Resource', self.pathLocalConfig)
        except:
            pass

        try:
            #部分设备没有这个标签
            self.bRandomAcount = bool(int(ini_get('AutoLogin', 'bRandomAcount', self.pathLocalConfig)))
        except:
            pass

        try:
            # 部分设备没有这个标签
            nTemperature=int(ini_get('perfmon_info', 'CoolTemperature', self.pathLocalConfig))
            if nTemperature>=25:
                self.nTemperature=nTemperature
        except:
            pass

        self.log.info(f'机器: {self.strMachineName}')
        #获取设备ID
        self.deviceId = ini_get('local', 'deviceId', self.pathLocalConfig)
        self.log.info(f"deviceId:{self.deviceId}")
        if self.deviceId!='localhost':
            self.bMobile = True
            if '-' not in self.deviceId:
                # 移动端-ios
                self.strClientType = 'XGame_Mobile_Android'
            else:
                # 移动端-android
                self.strClientType = 'XGame_Mobile_Ios'
        else:
            try:
                if ini_get('local', 'ClientType', self.pathLocalConfig)=='trunk':
                    self.strClientType = "XGame_PC"
                else:
                    self.strClientType = 'XGame_VK'
            except:
                self.strClientType = 'XGame_VK'
            #PC端
            # 获取设备GUID,用于协作发消息
            self.bMobile = False
            #self.strClientType='XGame_PC'

        #设置游戏客户端相关路径和参数
        self.setClientPath(self.strClientType)
        #根据用例类型设置设备冷机时间
        if self.bMobile:
            nCoolTemperature=34
            if '技能评测' in self.strCaseName:
                nCoolTemperature = 38
            elif 'Dump' in self.strCaseName:
                nCoolTemperature = -1

            try:
                nCoolTemperature =int(ini_get('perfmon_info', 'temperature', self.pathLocalConfig))
            except:
                pass
            self.mobile_device.nCoolTemperature=nCoolTemperature

        #初始化SDK
        #self.SDK = XGameSocketClient(os.path.join(os.getcwd(), 'SocketClientDLL.dll'), self.mobile_device.get_address(), 1112)

        video_name_XGame = {'1': '简约',
                            '2': '均衡',
                            '3': '电影',
                            '4': '极致'
                            }
        strSection = 'perfmon_info'
        #获取游戏客户端画质
        self.strNumVideoLevel = ini_get(strSection, 'video_level', self.pathLocalConfig)
        self.tagVideoLevel = video_name_XGame[self.strNumVideoLevel]
        #获取机器类型 Ios Android PC
        self.tagMachineType = ini_get(strSection, 'machine_type', self.pathLocalConfig)
        #检测设备类型合法性
        list_strMachineType=['Ios','Android','PC']
        if self.tagMachineType not in list_strMachineType:
            raise Exception(f"设备类型错误:{self.tagMachineType},必须为:Ios Android PC")
        #获取显卡类型
        self.tagVideoCard = ini_get(strSection, 'video_card', self.pathLocalConfig)
        self.log.info(f"tagVideoLevel:{self.tagVideoLevel},tagMachineType:{self.tagMachineType},tagVideoCard:{self.tagVideoCard}")
        #是否需要解除帧率限制
        self.freeFrame()

    def minimizWindow(self):
        if self.clientPID == 0:
            return
        dll = ctypes.cdll.LoadLibrary('WindowsCtrl.dll')
        dll.minimizWindow(self.clientPID)

    #根据游戏客户端运行时长计算冷机时间
    def countDeviceSleepTime(self):
        #PC端不需要Sleep
        #根据运行时长冷机
        if self.clientPID:
            if self.bMobile:
                nTime=int((int(time.time()) - self.nClientStartTime)/60)
                if nTime>15:
                    return 5
                else:
                    return int(nTime/3)+1
            else:
                return 0
        else:
            return 0

    def device_cooling(self,nTemperature=None,bFlag=True):
        if self.bMobile and bFlag:
            self.mobile_device.device_cooling_to_temperature(self.nTemperature)

    def _save_package_version(self,strPackageVer):
        strPackageVer=str(strPackageVer)
        self.log.info(f"保存版本号：{strPackageVer}至文件{LOCAL_PACKAGE_VERSION_PATH}")
        ini_set('Package','version',strPackageVer,LOCAL_PACKAGE_VERSION_PATH)

    def get_package_version(self):
        if not os.path.isfile(LOCAL_PACKAGE_VERSION_PATH):
            self.log.warning(f"get_version_by_file-获取版本号时，本地文件{LOCAL_PACKAGE_VERSION_PATH}不存在，无法获取版本号")
            return None
        return ini_get('Package','version',LOCAL_PACKAGE_VERSION_PATH)

    def creatFolderByShader(self,nShader, strLogPath, strImagePath, strCaseName,strMachineName):
        if nShader > 0:
            strDate = date_get_szToday()
            strBasePath = r"\\10.11.181.242\FileShare\liuzhu\JX3BVT\ShaderError"
            strCaseName = strCaseName.replace('|', '-')
            strDst=f"{strBasePath}\{strDate}\{strMachineName}\{strCaseName}"
            # print(strDst)
            if os.path.exists(strDst):
                shutil.rmtree(strDst)
            filecontrol_createFolder(strDst)
            filecontrol_copyFileOrFolder(strLogPath, strDst)
            filecontrol_copyFileOrFolder(strImagePath, strDst)
            self.log.info(f"shaderErrorCount:{nShader},path:{strDst}")
            #发送通知消息
            send_Subscriber_msg(self.strGuid,f"用例:{strCaseName} 有shader报错,赶快处理,shaderErrorCount:{nShader},截图和日志存放路径:{strDst}")


    def check_dic_args(self, dic_args):
        # 清除TempFolder文件夹 ios端有可能截图会被另外的进程锁定
        try:
            filecontrol_deleteFileOrFolder('TempFolder')
        except:
            pass
        # CaseName 用例名称
        self.strCaseName=dic_args['CaseName']
        self.version_file = dic_args.get("version_file", "xgame_package_version") #安装包版本文件
        # 设置perfeye截图时间间隔
        if 'screenshot_interval' in dic_args:
            self.nScreenshot_Interval = dic_args['screenshot_interval']
        else:
            self.nScreenshot_Interval = 0
            # 临时专项测试
            if 'testpoint' in dic_args and '-scence' in dic_args['testpoint']:
                self.nScreenshot_Interval = 4

    def setClientPath(self, strClientType):
        self.strClientType=strClientType
        self.package=None
        try:
            # 部分设备没有这个标签
            self.package = ini_get('perfmon_info', 'package', self.pathLocalConfig)
        except:
            pass
        if 'package' in self.args:
            self.package = self.args['package']

        if strClientType == 'XGame_PC':
            self.BASE_PATH = r'f:/trunk'
            if not os.path.exists(self.BASE_PATH):
                disks = psutil.disk_partitions()
                for disk in disks:
                    path = disk.mountpoint + 'trunk'
                    if os.path.exists(path):
                        self.BASE_PATH = path
                        break
            self.CLIENT_PATH = self.BASE_PATH + r'/client'
            self.SERVERLIST_PATH = self.CLIENT_PATH + r'/ui/Scheme/Case'  # serverlist.ini
            self.CLIENT_LOG_PATH = self.CLIENT_PATH + r'/logs/JX3ClientX3D'
            self.bEXP = False
            self.bPAK = False
            self.AppKey = 'jw3qptqjb'
            self.package = None
            self.BIN64_NAME='bin64_m'
            self.exename='JX3ClientX3DX64.exe'
        elif strClientType == 'XGame_VK':
            self.BASE_PATH = r'f:/SeasunGame'
            if not os.path.exists(self.BASE_PATH):
                disks = psutil.disk_partitions()
                for disk in disks:
                    path = disk.mountpoint + 'SeasunGame'
                    if os.path.exists(path):
                        self.BASE_PATH = path
                        break
            #self.CLIENT_PATH = self.BASE_PATH + r'/Game/JX3_WJ_EXP_20240227/bin/vk_exp'
            self.CLIENT_PATH = self.BASE_PATH + r'/Game/JX3_WJ_EXP/bin/vk_exp'
            self.SERVERLIST_PATH = self.CLIENT_PATH + r'/ui/Scheme/Case'  # serverlist.ini
            self.CLIENT_LOG_PATH = self.CLIENT_PATH + r'/logs/JX3ClientX3D'
            self.bEXP = True
            self.bPAK = False
            self.AppKey = 'jw3qptqjb'
            self.package = None
            self.BIN64_NAME = 'bin64_m'
            self.exename = 'JX3ClientX3DX64.exe'
        elif strClientType == 'XGame_Mobile_Android':
            if not self.package:
                self.package = 'com.seasun.jx3bvt'
            self.BASE_PATH = f'/sdcard/Android/data/{self.package}/files'
            self.CLIENT_PATH = self.BASE_PATH
            self.SERVERLIST_PATH = self.CLIENT_PATH + r'/ui/Scheme/Case'  # serverlist_m.tab
            self.CLIENT_LOG_PATH = self.CLIENT_PATH + r'/logs/JX3ClientX3D'
            self.bEXP = False
            self.bPAK = False
            self.AppKey = 'jw3qptqjb'

        elif strClientType == 'XGame_Mobile_Ios':
            if not self.package:
                self.package='com.jx3.mobile'
            self.BASE_PATH = r'/Documents'
            self.CLIENT_PATH = self.BASE_PATH
            self.SERVERLIST_PATH = self.CLIENT_PATH + r'/ui/Scheme/Case'  # serverlist_m.tab
            self.CLIENT_LOG_PATH = self.CLIENT_PATH + r'/logs/JX3ClientX3D'
            self.bEXP = False
            self.bPAK = False
            self.AppKey = 'jw3qptqjb'

            #13临时测试
            #if self.deviceId=='00008110-000A14500CBA801E':
                #self.package = 'com.seasun.jx'

        else:
            raise Exception('CaseJX3Client clientType error:{}'.format(strClientType))
        #插件路径
        self.INTERFACE_PATH = self.CLIENT_PATH + r'/mui/Lua/Interface'
        self.SEARCHPANEL_PATH = self.INTERFACE_PATH + r'/SearchPanel'
        self.log.info(strClientType)
        self.mobile_device=None
        #开启移动端设备管理
        if self.bMobile:
            from mobile_device_controller import Android_IOS
            self.mobile_device = Android_IOS(self.deviceId, self.package)
            self.log.info(f"安装包版本:{self.mobile_device.strVersion}")


    def copyPerfeye(self):
        if sys.platform.startswith('win'):
            if self.tagMachineType=='Test':
                perfeye_folder = PERFEYE_VER + '-' + self.deviceId
                perfeye_zipfile = perfeye_folder + '.zip'
                root = os.path.realpath(__file__).split('\\')[0]
                root = os.path.join(root, os.sep)
                path_local_perfeye_folder = os.path.join(root, perfeye_folder)
                if os.path.exists(path_local_perfeye_folder):
                    self.bPerfeyeExist = True
                    return
                strTempPerfeyeFolder = 'TempFolder' + os.sep + perfeye_zipfile
                perfeye_zipfile = PERFEYE_VER + '.zip'
                src = os.path.join(SERVER_TOOLS, perfeye_zipfile)
                dst = path_local_perfeye_folder
                if not filecontrol_existFileOrFolder(strTempPerfeyeFolder):
                    filecontrol_copyFileOrFolder(src, strTempPerfeyeFolder)
                f = zipfile.ZipFile(strTempPerfeyeFolder, 'r')
                for file in f.namelist():
                    print(file, 'TempFolder')
                    f.extract(file, 'TempFolder')
                filecontrol_copyFileOrFolder('TempFolder' + os.sep + PERFEYE_VER, dst)
            else:
                perfeye_folder = PERFEYE_VER
                perfeye_zipfile = perfeye_folder + '.zip'
                root = os.path.realpath(__file__).split('\\')[0]
                root = os.path.join(root, os.sep)
                path_local_perfeye = os.path.join(root, perfeye_zipfile)
                path_local_perfeye_folder = os.path.join(root, perfeye_folder)
                if os.path.exists(path_local_perfeye_folder):
                    self.bPerfeyeExist = True
                    return
                src = os.path.join(SERVER_TOOLS, perfeye_zipfile)
                dst = path_local_perfeye
                filecontrol_copyFileOrFolder(src, dst)
                f = zipfile.ZipFile(path_local_perfeye, 'r')
                first_path = f.namelist()[0].strip('/')
                if first_path != perfeye_folder:
                    os.makedirs(perfeye_folder)
                    root = path_local_perfeye_folder
                for file in f.namelist():
                    print(file, root)
                    f.extract(file, root)
            self.bPerfeyeExist = True
        self.log.info('copyPerfeye success')



    def noteSvrlistInVersionCFG(self):
        f = open(os.path.join(self.CLIENT_PATH, 'version.cfg'))
        allfile = f.read()
        if 'classic' in self.clientType:
            # replaceStr = r'Sword3.SvrListUrl=http://jx3classicv4.autoupdate.kingsoft.com/jx3classic_v4/classic_exp/serverlist/serverlist.ini'
            replaceStr = r'Sword3.SvrListUrl=http://jx3clc-autoupdate.xoyocdn.com/jx3classic_v4/classic_exp/serverlist/serverlist.ini'
        else:
            replaceStr = r'Sword3.SvrListUrl=http://jx3comm.xoyocdn.com/jx3hd/zhcn_exp/serverlist/serverlist.ini'
        allfile = allfile.replace(replaceStr, '#' + replaceStr)
        f.close()
        f = open(self.CLIENT_PATH + r'\version.cfg', 'w')
        f.write(allfile)
        f.close()

    def getClientVersion_PC(self):
        if self.bMobile:
            raise Exception("Client Type Error")
        else:
            file_version_cfg = self.CLIENT_PATH + r'\version_vk.cfg'
            strVersion=ini_get('Version', 'Sword3.version', file_version_cfg)
        if not strVersion:
            raise Exception("can not find version in version.cfg")

    def getClientVersionex(self):
        file_version_cfg = self.CLIENT_PATH + r'\version.cfg'
        return ini_get('Version', 'Sword3.versionex', file_version_cfg)

    def setDisplayOption(self, n):
        dic_level = {
            '1': 'config_1_zuijian.ini',
            '2': 'config_2_jianyue.ini',
            '3': 'config_3_junheng.ini',
            '4': 'config_4_weimei.ini',
            '5': 'config_5_gaoxiao.ini',
            '6': 'config_6_dianying.ini',
            '7': 'config_7_jizhi.ini',
            '8': 'config_8_tansuo.ini',
            '9': 'config_9_chenjin.ini'
        }
        configLevelFilePath = self.CLIENT_PATH + r'\config' + '\\' + dic_level[str(n)]
        configFilePath = self.CLIENT_PATH + '\\config.ini'
        with open(configLevelFilePath, 'r') as level_f:
            content = level_f.read()
            with open(configFilePath, 'w') as config_f:
                config_f.write(content)

    def clearUserData(self):
        strPathUserData = self.CLIENT_PATH + r'\userdata'
        filecontrol_deleteFileOrFolder(strPathUserData.decode('utf8'))

    def checkIsHaveNewClientVersion(self):
        return True

    def process_threads_beforeStartClient(self):
        threads = self.listThreads_beforeStartClient
        try:
            for t in threads:
                t.setDaemon(True)
                t.start()
        except Exception as e:
            self.log.exception(e)
            pass

    def process_threads_activeWindow(self):
        t = threading.Thread(target=self.thread_activeWindow,
                             args=(threading.currentThread(), self.clientPID,))
        t.start()


    def thread_HandleDropLineAndDeviceRemoved(self, dicSwitch, t_parent, RUN_CLIENT_LOG_PATH):
        try:
            check_file = ""
            now_file = ""
            flag = False  # 用来更新check_file
            nTimerRunMapEnd=0
            nTimerKeepHeart=0
            nTimerCheckLog=0
            nStepTime=0.2
            strDate = time.strftime(f"%Y_%m_%d", time.localtime())
            while t_parent.is_alive():
                # 检测游戏客户都端是否启动
                if not self.clientPID:
                    time.sleep(10)
                    continue
                if nTimerRunMapEnd > 0.5:
                    # 0.5秒检查一次是否跑图结束
                    nTimerRunMapEnd = 0
                    if self.bRunMapEnd:
                        self.log.info("thread_HandleDropLineAndDeviceRemoved exit")
                        break
                elif nTimerCheckLog>5:
                    nTimerCheckLog=0
                    now_file= filecontrol_getFolderLastestFile(self.CLIENT_LOG_PATH + '/' + strDate,'TempFolder')
                    #now_file = getLastLogFile(RUN_CLIENT_LOG_PATH)

                    isFound1, line1 = findStringInLog(check_file, 'DropLinePanel', line1)
                    isFound2, line2 = findStringInLog(check_file, 'device removed', line2)
                    if isFound1 or isFound2:
                        info = '游戏掉线或者设备被移除，已自动重启用例，无需手动再处理'
                        printscreen_temp_folder = './temp'
                        time.sleep(2)  # 等一下，让画面对掉线或者设备移除有显示
                        image_path = printscreen(printscreen_temp_folder)
                        send_Subscriber_msg(machine_get_guid, info, image_path)
                        self.task_reset()
                        if isFound1:
                            self.offlineSwitch = True
                        break
                elif nTimerKeepHeart > 120:
                    # 120写一条日志
                    nTimerKeepHeart = 0
                    self.log.info('CheckScreenShot heart')
                else:
                    nTimerRunMapEnd += nStepTime
                    nTimerKeepHeart += nStepTime
                    nTimerCheckLog +=nStepTime
                    time.sleep(nStepTime)

        except Exception as e:
            info = traceback.format_exc()
            self.log.error(info)


    def thread_HandleDropLine(self, dicSwitch, t_parent, old_f, RUN_CLIENT_LOG_PATH):
        try:
            line = 0
            while t_parent.is_alive():
                time.sleep(2)
                f = getLastLogFile(RUN_CLIENT_LOG_PATH)
                if f == old_f:
                    continue
                isFound, line = findStringInLog(f, '[OpenFrame DropLinePanel]', line)
                if isFound:
                    win32_kill_process('JX3Debugger.exe')  # 新调试器
                    win32_kill_process(self.exename)
                    os.chdir(WORK_PATH)
                    try:
                        MACHINE_ID = ini_get('local', 'machine_id', r'LocalConfig.ini')
                    except Exception as e:
                        MACHINE_ID = u''
                    if MACHINE_ID != "":
                        info = u'{}: 游戏掉线了'.format(MACHINE_ID)
                    else:
                        info = u'{}: 游戏掉线了'.format(machine_get_IPAddress())
                    self.log.warning(info)
                    IP = machine_get_IPAddress()
                    send_Subscriber_msg(IP, info)
                    self.offlineSwitch = True
                    break
        except Exception as e:
            info = traceback.format_exc()
            self.log.error(info)

    def thread_activeWindow(self, t_parent, nPid):

        try:
            dll = ctypes.cdll.LoadLibrary(os.path.dirname(os.path.realpath(__file__)) + r'/WindowsCtrl.dll')
            while t_parent.is_alive():
                time.sleep(1)
                dll.activeWindow(nPid)
        except Exception as e:
            info = traceback.format_exc()
            self.log.error(info)

    def thread_DealWithMobileWindow(self,t_parent):
        self.log.info("thread_DealWithMobileWindow start")
        if not self.bMobile:
            self.log.info("not mobile")
        if 'Android' in self.tagMachineType:
            import uiautomator2 as u2
            d = u2.connect_usb(self.deviceId)
            d.healthcheck()
            # 停止并移除所有的监控，常用于初始化
            #d.watcher.reset()
            #d.watcher.when('无限制').click()
            #d.watcher.when('继续安装').click()
            #d.watcher.when('完成').click()
            #d.watcher.when('允许').click()
            while t_parent.is_alive():
                #d.watcher.run()
                if d(text='无限制').exists:
                    d(text='无限制').click()
                if d(text='继续安装').exists:
                    d(text='继续安装').click()
                if d(text='完成').exists:
                    d(text='完成').click()
                if d(text='允许').exists:
                    d(text='允许').click()
                if d(text='知道了').exists:
                    d(text='知道了').click()
                #d.healthcheck()
                time.sleep(2)
            # 移除所有的监控
            #d.watcher.remove()
        else:
            import wda
            wc = wda.USBClient(self.deviceId, port=8100, wda_bundle_id='com.facebook.WebDriverAgentRunner.xctrunner')
            while t_parent.is_alive():
                if wc.alert.exists:
                    wc.alert.click(wc.alert.buttons())
                time.sleep(2)
            wc.close()
        self.log.info("thread_DealWithMobileWindow end")

    def SetMaxWindow(self, strWindowName='KGWin32App'):
        hwnd = win32gui.FindWindow(strWindowName, None)
        while not hwnd:
            self.log.info(f'FindWindow({strWindowName})')
            time.sleep(1)
            hwnd = win32gui.FindWindow(strWindowName, None)
        win32gui.ShowWindow(hwnd, win32con.SW_MAXIMIZE)


    def start_client_test(self, dic_args):
        # if self.clientType == 'PAK_EXP_classic':
        #     win32_runExe("JX3ClientX64.exe DOTNOTSTARTGAMEBYJX3CLIENT.EXE", self.CLIENT_PATH + "/" + self.BIN64_NAME)
        #     return  测试用的，注释掉
        self.log.info("start_client_test")
        if self.bMobile:
            #设备清除后台
            #self.mobile_device.clear_background()
            # 关闭app
            #mobile_kill_app(self.package,self.deviceId)
            self.mobile_device.kill_app()
            time.sleep(15)
            #ret=mobile_start_app(self.package,self.deviceId)
            #app 三次运行失败 用例执行失败
            nReStartCounter=4
            #移动端 此处等待Perfeye线程获取applist后再启动app
            while not self.bCanStartClient:
                time.sleep(1)
            for i in range(nReStartCounter):
                if i==nReStartCounter-1:
                    raise Exception(f"{nReStartCounter-1}次启动app失败,用例执行失败退出")
                elif i==nReStartCounter-2:
                    #ios端 有可能使用tidevice 启动app报错了 需要使用wda启动app
                    self.mobile_device.start_app_wda()
                if self.mobile_device.determine_runapp():
                    break
                else:
                    ret = self.mobile_device.start_app()
                    self.log.info(ret)
                    time.sleep(15)
            self.log.info(f"app start temperature:{self.mobile_device.get_Battery_temperature()}")
            self.clientPID = "mobile"
        else:
            if 'memtest' in dic_args and dic_args['memtest'] == True:
                # 修改mem_jx3hd.cmd文件里的
                root = os.path.realpath(__file__).split('\\')[0]
                CPPMEMCMD = root + '/CppMemCmd'
                exe = os.path.join(CPPMEMCMD, "mem_jx3hd.cmd")
                pp = win32_runExe_no_wait(exe, CPPMEMCMD)
                listP = win32_findProcessByName(self.exename)
                while not listP:
                    listP = win32_findProcessByName(self.exename)
                    time.sleep(1)
                p2 = listP[0]
                self.clientPID = p2.pid
                self.process_threads_activeWindow()
            else:
                path = os.path.join(self.CLIENT_PATH, self.BIN64_NAME)
                exe = os.path.join(path, self.exename)
                self.log.info(exe)
                self.log.info(path)
                pp = win32_runExe_no_wait(exe, path)
                self.clientPID = pp.pid
                self.process_threads_activeWindow() #让客户端处于顶层
                nSetMaxWindow=0
                try:
                    nSetMaxWindow=int(ini_get('perfmon_info','MaxWindow',self.pathLocalConfig))
                    if nSetMaxWindow:
                        self.SetMaxWindow()
                except:
                    pass
        self.log.info("start_client_test_success")
        self.nClientStartTime = int(time.time())

    def OpenAutoLogin(self, dic_args):
        account = dic_args['account'] if "account" in dic_args else self.strAccount
        password = dic_args['password'] if "password" in dic_args else self.strPassword
        RoleName = dic_args['RoleName'] if "RoleName" in dic_args else self.strRoleName
        school_type = dic_args['school_type'] if "school_type" in dic_args else self.strSchool_type
        role_type = dic_args['role_type'] if "role_type" in dic_args else self.strRole_type
        resource=dic_args['resource'] if "resource" in dic_args else self.strResource
        szDisplayRegion =self.strDisplayRegion
        szDisplayServer=self.strDisplayServer
        StepTime = dic_args['StepTime'] if "StepTime" in dic_args and dic_args["StepTime"] != '' else self.strStepTime
        Switch = dic_args['Switch'] if "Switch" in dic_args and dic_args["Switch"] != '' else self.strSwitch
        self.bRandomAcount=dic_args['bRandomAcount'] if 'bRandomAcount' in dic_args else self.bRandomAcount
        ''''''
        if self.tagVideoCard=='iqqoZ3':
            StepTime = '10000'
        elif self.deviceId=='cc14c592':
            #设备特殊处理
            StepTime = '4000'
        else:
            StepTime='6000'
        #StepTime = '8000'

        #是否获取不重复的账号
        if "account" not in dic_args and self.bRandomAcount:
            bRet,strAccount=xgame_generate_account()
            if bRet:
                account=strAccount
                self.strAccount=strAccount
            else:
                self.log.info(f"账号获取错误:{strAccount}")

        # TDR用例需要使用 质量-稳定52 服务器
        strCaseName = dic_args['CaseName']
        ''''''
        if 'tdr' in strCaseName.lower():
            szDisplayRegion='质量'
            szDisplayServer='TDR'
        if 'hotpoint' in self.args['testpoint']:
            szDisplayRegion = '常用'
            szDisplayServer = '互通BVT'
        #用例自定义服务器
        if "szDisplayRegion" in dic_args:
            szDisplayRegion = dic_args['szDisplayRegion']
        if "szDisplayServer" in dic_args:
            szDisplayServer = dic_args['szDisplayServer']

        if 'ip' in dic_args:
            szDisplayRegion='测试'
            szDisplayServer='自搭'

        #szDisplayRegion = '常用'
        #szDisplayServer = '互通BVT'
        self.strDisplayServer=szDisplayServer
        self.strDisplayRegion=szDisplayRegion
        self.log.info(f"account:{account},szDisplayRegion{szDisplayRegion},szDisplayServer:{szDisplayServer}")

        if not self.bAutoLogin:
            return

        # 兼容手机操作，文件先考到本地临时文件夹处理完毕再推送到目的地
        TEMP_FOLDER = 'TempFolder/Interface'
        if not os.path.exists(TEMP_FOLDER):
            filecontrol_createFolder(TEMP_FOLDER)

        #设置自动登录插件的相关信息
        strAutomationPath = 'TempFolder/Interface/AutoLogin/Automation.ini'
        ini_set('Automation', 'account', account, strAutomationPath)
        ini_set('Automation', 'password', password, strAutomationPath)
        ini_set('Automation', 'RoleName', RoleName, strAutomationPath)
        ini_set('Automation', 'school_type', school_type, strAutomationPath)
        ini_set('Automation', 'role_type', role_type, strAutomationPath)
        ini_set('Automation', 'StepTime', StepTime, strAutomationPath)
        ini_set('Automation', 'Switch', Switch, strAutomationPath)
        ini_set('Automation', 'szDisplayRegion', szDisplayRegion, strAutomationPath)
        ini_set('Automation', 'szDisplayServer', szDisplayServer, strAutomationPath)
        ini_set('Automation', 'Resource', resource, strAutomationPath)


    def clearInfoFiles(self):
        listFilesName = ['minimiz_login', 'minimiz','AutoLoginPanel']
        for fileName in listFilesName:
            uFilepath = os.path.join(self.CLIENT_PATH + LOCAL_INFO_FILE, fileName)
            logger.info(uFilepath)
            filecontrol_deleteFileOrFolder(uFilepath)

    def getClientUUID_Mobile(self):
        # 清除日志
        self.mobile_device.logcat_clear()
        # 容易造成卡顿
        ''''''
        # 判断当前游戏客户端版本是否已经获取过UUID了
        strVersionFile = 'AppVersion.ini'
        if not filecontrol_existFileOrFolder(strVersionFile):
            with open(strVersionFile, 'w') as file:
                file.write('[Main]\nversion=\nuuid=\n')
        # 如果当前安装包版本未变更,则使用记录的UUID  如果变更需要设置安装包版本 并且获取UUID
        if ini_get('Main', 'version', strVersionFile) == self.mobile_device.strVersion:
            self.strClientUUID = ini_get('Main', 'uuid', strVersionFile)
            self.log.info(f'Old ClientUUID:{self.strClientUUID}')
            return

        if self.tagMachineType == 'Android':
            cmd = 'adb -s %s logcat'
        else:
            cmd = 'tidevice -u %s syslog'
        cmd = cmd % (self.deviceId)
        self.log.info('getClientUUID_Mobile start')
        list_cmd = cmd.split(' ')
        pi = subprocess.Popen(list_cmd, shell=False, stdout=subprocess.PIPE)
        nStartTime = int(time.time())
        while True:
            # time.sleep(0.1)
            try:
                if int(time.time()) - nStartTime >= 120:
                    nStartTime = int(time.time())
                    self.log.info('getClientUUID_Mobile heart')
                res = pi.stdout.readline()
                try:
                    res = str(res, encoding='gbk')
                except:
                    res = str(res, encoding='utf8')
                #print(res)
                if res.find('Crasheye') != -1 and res.find('uuid') != -1:
                    print('test-----------------')
                    self.strClientUUID = res.split('\r\n')[0].split(' ')[-1]
                    self.log.info(f'New ClientUUID:{self.strClientUUID}')
                    ini_set('Main', 'uuid', self.strClientUUID, strVersionFile)
                    #必须找到UUID后再填app版本
                    ini_set('Main', 'version', self.mobile_device.strVersion, strVersionFile)
                    pi.terminate()
                    break
            except:
                pass
        self.log.info('getClientUUID_Mobile end')

    def freeFrame(self,SDK=None):
        # 是否解除帧率限制
        try:
            strSection = 'perfmon_info'
            strFreeFrame = ini_get(strSection, 'FreeFrame', self.pathLocalConfig)
            nFrame=int(strFreeFrame)
            if nFrame == 1:
                self.log.info("解除帧率限制")
                strSharePath=SERVER_PATH+'\XGame\config.ini'
                strLocalPath = os.path.join(os.getcwd(), 'TempFolder/config.ini')
                filecontrol_copyFileOrFolder(strSharePath, strLocalPath)
                ini_set('Main', 'FreeFrame', 1, strLocalPath)
                self.log.info(strLocalPath)
                filecontrol_copyFileOrFolder(strLocalPath, self.CLIENT_PATH, self.deviceId, self.package)
            elif nFrame>1:
                self.nFrame=nFrame
        except Exception as e:
            info = traceback.format_exc()
            if 'KeyError' not in info:
                self.log.info(info)

    def processServerlist(self, dic_args):
        TEMP_FOLDER = 'TempFolder'
        #return
        strLocalPath = TEMP_FOLDER + os.sep + 'serverlist.ini'
        filecontrol_copyFileOrFolder(SERVER_PATH + '/XGame/serverlist.ini', strLocalPath)
        if 'ip' in dic_args:
            #需要处理自驾服务器
            changeStrInFile(strLocalPath, '_ip_', dic_args['ip'])
        filecontrol_copyFileOrFolder(strLocalPath, self.SERVERLIST_PATH + '/serverlist.ini', self.deviceId,self.package)
        # 临时帮余鹏取系统符号文件到共享目录
        '''
        if self.tagMachineType == 'Android':
            dst = SERVER_PATH + f"/AndroidSytemLib/{self.deviceId}"
            if filecontrol_existFileOrFolder(dst):
                return
            else:
                list_src = ["/system/lib", "/system/lib64"]
                temp = os.path.join(TEMP_FOLDER, self.deviceId)
                if not filecontrol_existFileOrFolder(temp):
                    filecontrol_createFolder(temp)
                for src in list_src:
                    adb_pull(src, temp, self.deviceId)

                filecontrol_copyFileOrFolder(temp, dst)
        '''

    def Client_Kill(self):
        #客户端已经启动
        self.log.info('Client_Kill')
        try:
            if self.bMobile:
                self.mobile_device.kill_app()
            else:
                win32_kill_process(self.exename)
        except Exception as e:
            info = traceback.format_exc()
            self.log.info(info)
            self.log.info('Client_Kill error')

    def Client_ScreenShot(self,strScreenShotPath='TempFolder\ClientScreenShot.png'):
        strSep = os.sep
        if strSep not in strScreenShotPath:
            strSep = '/'
        strPathFolder=strScreenShotPath[:strScreenShotPath.rfind(strSep)]
        if not filecontrol_existFileOrFolder(strPathFolder):
            filecontrol_createFolder(strPathFolder)
        self.log.info(f'Client_ScreenShot:{strScreenShotPath}')
        if self.bMobile:
            if self.mobile_device:
                self.mobile_device.screenshot2(strScreenShotPath)
            else:
                self.log.info('Client_ScreenShot error: not mobile_device ')
        else:
            strPicName =strScreenShotPath.split(strSep)[-1].split('.')[0]
            def cutpicture(absolutepath):
                #获取图片名称
                with Image.open(absolutepath) as img:
                    # 获取图像大小，即宽度和高度
                    width, height = img.size
                    crop_area = (0, 0, width, height * 0.9)
                    # 裁剪图像
                    cropped_img = img.crop(crop_area)
                    # 保存裁剪后的图像
                    cropped_img.save(f'TempFolder/{strPicName}.png')
                return f'TempFolder/{strPicName}.png'
            strScreenShotPathTemp = printscreen('TempFolder')
            strScreenShotPath = cutpicture(strScreenShotPathTemp)
            filecontrol_deleteFileOrFolder(strScreenShotPathTemp)
        return strScreenShotPath

    #获取 代码版本和资源版本
    def GetVersion(self):
        try:
            if not self.strVersion:
                strVersionFilePath=os.path.join(self.CLIENT_PATH + LOCAL_INFO_FILE, 'version.ini')
                strLocalPath=os.path.join('TempFolder','version.ini')
                filecontrol_copyFileOrFolder(strVersionFilePath,strLocalPath,self.deviceId,self.package)
                strCodeVer=ini_get('Version','CodeVer',strLocalPath)
                strResourceVer = ini_get('Version', 'ResourceVer', strLocalPath)
                self.strVersion=f"{strCodeVer}-{strResourceVer}"
                self.log.info(f"代码-资源版本:{self.strVersion}")
        except Exception as e:
            info = traceback.format_exc()
            self.log.info(info)
            self.strVersion = '1.0.0'
        return self.strVersion
    
    def GetClientLog(self):
        strDate = time.strftime(f"%Y_%m_%d", time.localtime())
        self.strClientLog = filecontrol_getFolderLastestFile(self.CLIENT_LOG_PATH + '/' + strDate, 'TempFolder',self.deviceId, self.package)



    def processResoucre(self,dic_args,bClear=False,bWaitTodayRes=False):
        # 必须等待当天资源包出来后才可以执行
        strResourceVer = str(dic_args.get('resourceVer', '0'))
        strResourceServer = str(dic_args.get('resourceServer', 'bvt'))
        while bWaitTodayRes and strResourceVer=='0' and not xgame_get_resource_version(self.tagMachineType):
            self.log.info("wait today ResourceVer")
            #break
            sleep_heartbeat(2)

        list_server = ['bvt', 'exp', 'mb']
        if strResourceServer not in list_server:
            raise Exception(f'configHttpFile.ini server: {strResourceVer} error')

        if self.tagMachineType == 'Android':
            strPlatform = f'android_{strResourceServer}'
        elif self.tagMachineType == 'Ios':
            strPlatform = f'ios_{strResourceServer}'
        else:
            strPlatform = f'vk_{strResourceServer}'

        # 确认资源服务器
        source_file = self.CLIENT_PATH + '/configHttpFile.ini'
        bExpResource = dic_args.get('bExpResource', False)
        strResourceVer = str(dic_args.get('resourceVer', '0'))

        if self.tagMachineType == 'PC':
            # 需要改资源服务器类似
            filecontrol_copyFileOrFolder(SERVER_PATH + r'\XGame\version_vk.cfg',os.path.join(self.CLIENT_PATH, 'version_vk.cfg'), self.deviceId, self.package)

        strLocalPath = 'TempFolder' + os.sep + 'configHttpFile.ini'

        os.makedirs('TempFolder', exist_ok=True)
        if self.bMobile:
            if not filecontrol_existFileOrFolder(source_file,self.deviceId, self.package):
                filecontrol_copyFileOrFolder(SERVER_PATH + f'{STRSEPARATOR}XGame{STRSEPARATOR}configHttpFile.ini', strLocalPath, self.deviceId, self.package)
                ini_set('downloader', 'downloader0', strPlatform, strLocalPath)
            else:
                filecontrol_copyFileOrFolder(source_file, strLocalPath, self.deviceId, self.package)
        else:
            if not filecontrol_existFileOrFolder(source_file,self.deviceId, self.package):
                filecontrol_copyFileOrFolder(SERVER_PATH + f'{STRSEPARATOR}XGame{STRSEPARATOR}configHttpFile_PC.ini', strLocalPath, self.deviceId, self.package)
            else:
                filecontrol_copyFileOrFolder(source_file, strLocalPath, self.deviceId, self.package)
        #self.log.info(f'httpfile:{source_file}-{strLocalPath}')

        #if 'mb' in ini_get('downloader', 'downloader0', strLocalPath):
            #strResourceServer='mb'


        # 修改资源服务器
        if is_valid_ip(strResourceVer):
            #新外装测试
            if 'newExterior' in dic_args:
                ini_set('downloader', 'downloader1', strPlatform, strLocalPath)
            else:
                changeStrInFile(strLocalPath,f'downloader1={strPlatform}','')
            strPlatform='etag_self'
            ini_set('downloader', 'downloader0', strPlatform, strLocalPath)
            ini_set('etag_self','getEtagFolder',f'http://{strResourceVer}:8285/ht_etag/',strLocalPath)
            ini_set('etag_self', 'getFile', f'http://{strResourceVer}:8285/ht/', strLocalPath)
            #etag模式需要删除szCache文件夹
            #filecontrol_deleteFileOrFolder(self.CLIENT_PATH+'/zsCache', self.deviceId, self.package)
        elif strResourceVer != '0':
            # 更改游戏资源版本号
            ini_set('downloader', 'downloader0', strPlatform, strLocalPath)
            ini_set(strPlatform, 'version', strResourceVer, strLocalPath)
            ini_set(strPlatform, 'enableUpdatePkg', '0', strLocalPath)
            self.log.info(f'{strResourceVer}:resource verserion changed successfully')
        else:
            ini_set(strPlatform, 'enableUpdatePkg', '1', strLocalPath)
            if bClear:
                self.log.info(f'{strPlatform}:clear successfully')
                ini_set('downloader', 'downloader0', strPlatform, strLocalPath)
                ini_set(strPlatform, 'version', '', strLocalPath)

        #[enable]fileVersion=0  修改为1000000否者文件会被重置
        #strFileVer=ini_get('enable','fileVersion',strLocalPath)
        ini_set('enable', 'fileVersion','100000000', strLocalPath)
        self.log.info(f'{strPlatform}:resource server changed successfully')
        filecontrol_copyFileOrFolder(strLocalPath, self.CLIENT_PATH+'/configHttpFile.ini', self.deviceId, self.package)

    def teardown(self):
        # 这里写上销毁清理工作，可以让工作线程安全退出的工作
        super().teardown()
        self.log.info('CaseJx3Client_teardown start')

        # 先截一张图 再结束游戏客户端
        if not self.strClientScreen:
            strScreenShotPath = os.path.join('TempFolder', 'RunMapEndScene.png')
            self.strClientScreen=self.Client_ScreenShot(strScreenShotPath)
        self.Client_Kill()

        if self.bMobile:
            pass
        else:
            win32_kill_process('KGPK4_StreamDownloaderX64.exe')
            win32_kill_process('XLauncher.exe')
            win32_kill_process('SeasunGame.exe')
            win32_kill_process('XLauncherKernel.exe')
            win32_kill_process('XLauncherKernelClassic.exe')
        if self.clientPID and not self.strClientLog:
            #游戏客户端启动过后 结束游戏客户端后,获取日志到本地
            strDate = time.strftime(f"%Y_%m_%d", time.localtime())
            if filecontrol_existFileOrFolder(self.CLIENT_LOG_PATH+'/'+strDate):
                self.strClientLog =filecontrol_getFolderLastestFile(self.CLIENT_LOG_PATH+'/'+strDate, 'TempFolder',self.deviceId,self.package)
            else:
                self.strClientLog='null'
                self.log.info("游戏客户都没有日志产出")
        # 游戏客户端启动过后 打印app运行时长 self.nClientRunTime!=0说明app异常退出,crash线程会计算时间
        if self.clientPID and not self.nClientRunTime:
            self.nClientRunTime = int(time.time()) - self.nClientStartTime
        self.log.info(f"游戏客户端运行时长: {self.nClientRunTime} 秒,{int(self.nClientRunTime/60)}分钟")
        self.log.info('CaseJx3Client_teardown end')
        pass



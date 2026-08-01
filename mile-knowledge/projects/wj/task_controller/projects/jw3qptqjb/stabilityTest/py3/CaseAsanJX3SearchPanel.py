# -*- coding: utf-8 -*-
import sys
import os
from datetime import time
sys.path.append(os.path.dirname(os.path.realpath(__file__)))
from XGameSocketClient import *
from CaseTDR import *
from SendMsgRobot import SendMsgToRobot
from CaseXgameAsanMonitor import CaseXgameAsanMonitor
def validateCaseName(caseName):
    rstr = r"[\/\\\:\*\?\"\<\>\|]"  # '/ \ : * ? " < > |'不能存在于文件夹名或文件名中,因此替换
    new_title = re.sub(rstr, "_", caseName)  # 替换为下划线
    return new_title
class CaseAsanJX3SearchPanel(CaseTDR):
    def __init__(self):
        super().__init__()
        self.asan_monitor = CaseXgameAsanMonitor()
        self.asan_log_dir = None
        self.log_path = None
        self.asan_log_dir = None
        self.log_path = None
        self.send_msg = SendMsgToRobot("https://xz.wps.cn/api/v1/webhook/send?key=f4d0d4a6c99a13465bbced649d514797")
        self.package = 'com.seasun.jx3'
        self.exit_event = threading.Event()  # 新增终止标志
    def check_dic_args(self, dic_args):
        super().check_dic_args(dic_args)
        # 设置用例信息
        file = "CaseInfo.ini"
        ini_set('CaseInfo', 'CaseName', self.strCaseName, file)
    def clear_log(self):
        filecontrol_deleteFileOrFolder(self.CLIENT_LOG_PATH)
    def thread_CheckTaskTimeOut(self, dicSwitch, t_parent):
        self.log.info(" thread_CheckTaskTimeOut start")
        strScreenShotPath = os.path.join('TempFolder','TaskTimeOutScene.png')
        # 放入消息队列的消息内容
        strMsg = ''
        nExceptionType = 0
        #ios加200s ahead-run加300s
        nTimerOut=self.nClientRunTimeOut+200
        if self.tagMachineType=='Ios':
            nTimerOut+=200
        if 'ahead-run' in self.testpoint:
            nTimerOut+=300
        self.log.info(f'超时时间限制:{nTimerOut}')
        nStepTime=0.1
        nTimerTimeOut=0
        nTimerRunMapEnd=0
        nTimerKeepHeart=0
        while t_parent.is_alive():
            # 检测app是否启动
            if not self.clientPID:
                time.sleep(10)
                continue
            if nTimerRunMapEnd > 0.2:
                # 0.2秒检查一次是否跑图结束
                nTimerRunMapEnd = 0
                if self.bRunMapEnd:
                    self.log.info("thread_CheckTaskTimeOut exit")
                    break
            elif nTimerTimeOut > nTimerOut:
                nTimerTimeOut=0
                # 超时
                nTimerTimeOut = 0
                self.log.info(f'bRunMapEnd:{self.bRunMapEnd}')
                self.bRunMapEnd = True
                # mobile_screemshot(strScreenShotPath, self.deviceId)
                if not self.strClientScreen:
                    self.strClientScreen = self.Client_ScreenShot(strScreenShotPath)
                # 超时检查 一定发生在app运行状态
                strMsg = f'{self.strMachineName}: %s 分钟还未结束跑图用例: {self.strCaseName}，用例异常，需要查看'
                nExceptionType = ExceptionMsg.TASKTIMEOUT
                # 防止通知等待时间过长 app长时间运行导致手机发热
                # self.Client_Kill()
                # mobile_kill_app(self.package, self.deviceId)
                self.queue_ExceptionMsg.put(
                    {'exceptionType': nExceptionType, 'msg': strMsg, 'screenshotPath': strScreenShotPath})
                self.log.info(strMsg % (self.nTaskTimeOut // 60) + ": 用例超时检查线程退出 ")
                break
            elif nTimerKeepHeart > 120:
                # 120写一条日志
                nTimerKeepHeart = 0
                self.log.info('CheckTaskTimeOut heart')
            else:
                nTimerTimeOut += nStepTime
                nTimerRunMapEnd += nStepTime
                nTimerKeepHeart += nStepTime
                time.sleep(nStepTime)
    def add_thread_for_searchPanel(self, dicSwitch):
        if not self.bMobile:
            # perfeye线程
            # t = threading.Thread(target=self.thread_SearchPanelPerfEyeCtrl,
            #                      args=(dicSwitch, threading.currentThread(),))
            # self.listThreads_beforeStartClient.append(t)
            #用例超时检查线程
            t = threading.Thread(target=self.thread_CheckTaskTimeOut,
                                 args=(dicSwitch, threading.currentThread(),))
            self.listThreads_beforeStartClient.append(t)
            #异常处理线程
            t = threading.Thread(target=self.thread_DealWith_ExceptionMsg,
                                 args=(dicSwitch, threading.currentThread(),))
            self.listThreads_beforeStartClient.append(t)
            #图像处理线程
            t = threading.Thread(target=self.thread_CheckScreenShot,
                                 args=(dicSwitch, threading.currentThread(),))
            self.listThreads_beforeStartClient.append(t)
            # 游戏客户端运行状态监控与宕机线程
            t = threading.Thread(target=self.thread_CheckAppRunStateAndCrash,
                                 args=(dicSwitch, threading.currentThread(),))
            self.listThreads_beforeStartClient.append(t)
            #内存检查线程
            t = threading.Thread(target=self.asan_monitor.logcat_Asan)
            self.listThreads_beforeStartClient.append(t)
        else:
            #perfeye线程
            # t = threading.Thread(target=self.thread_SearchPanelPerfEyeCtrl,
            #                      args=(dicSwitch, threading.currentThread(),))
            # self.listThreads_beforeStartClient.append(t)
            #游戏客户端运行状态监控与宕机线程
            t = threading.Thread(target=self.thread_CheckAppRunStateAndCrash,
                                 args=(dicSwitch, threading.currentThread(),))
            self.listThreads_beforeStartClient.append(t)
            #用例超时检查和perfeye_start超时检查 线程
            t = threading.Thread(target=self.thread_CheckTaskTimeOut,
                                 args=(dicSwitch, threading.currentThread(),))
            self.listThreads_beforeStartClient.append(t)
            #异常处理线程
            t = threading.Thread(target=self.thread_DealWith_ExceptionMsg,
                                 args=(dicSwitch, threading.currentThread(),))
            self.listThreads_beforeStartClient.append(t)
            # 电量监控线程
            t = threading.Thread(target=self.thread_DeviceBatteryMonitor,
                                 args=(dicSwitch, threading.currentThread(),))
            self.listThreads_beforeStartClient.append(t)
            #图像处理线程
            t = threading.Thread(target=self.thread_CheckScreenShot,
                                 args=(dicSwitch, threading.currentThread(),))
            self.listThreads_beforeStartClient.append(t)
            # 移动端也添加内存检查线程
            t = threading.Thread(target=self.asan_monitor.logcat_Asan)
            self.listThreads_beforeStartClient.append(t)
            #处理设备弹窗
            #t = threading.Thread(target=self.mobile_device.thread_DealWithMobileWindow,
                                 #args=(threading.currentThread(),))
            #self.listThreads_beforeStartClient.append(t)
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
            # while not self.bCanStartClient:
            #     time.sleep(1)
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
    def processResoucre(self,dic_args,bClear=False,bWaitTodayRes=False):
        # 必须等待当天资源包出来后才可以执行
        strResourceVer = str(dic_args.get('resourceVer', '0'))
        strResourceServer = str(dic_args.get('resourceServer', 'bvt'))
        if 'newExterior' in dic_args:
            strResourceServer='mb'
            #外装相关需要挂version_vk.cfg包外
            filecontrol_copyFileOrFolder(SERVER_PATH + r'\XGame\version_vk.cfg',os.path.join(self.CLIENT_PATH, 'version_vk.cfg'),self.deviceId,self.package)

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

        strLocalPath = GetTEMPFOLDER() + os.sep + 'configHttpFile.ini'

        os.makedirs(GetTEMPFOLDER(), exist_ok=True)
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

        # 新外装测试 #subset测试
        if 'newExterior' not in dic_args and not 'subset_test2' in dic_args:
            changeStrInFile(strLocalPath, f'downloader1=etag_self', '',code="gbk")

        # 修改资源服务器
        if is_valid_ip(strResourceVer):
            if 'newExterior' in dic_args or 'subset_test2' in dic_args:
                ini_set('downloader', 'downloader0', strPlatform, strLocalPath)
                #先判断一下是否需要添加版本号
                strResourceVersion = str(dic_args.get('resourceVersion', '0'))
                if strResourceVersion!='0':
                    ini_set(strPlatform, 'version', strResourceVersion, strLocalPath)

                strPlatform = 'etag_self'
                ini_set('downloader', 'downloader1', strPlatform, strLocalPath)
            else:
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
        """终止所有线程并清理资源"""
        try:
            # 1. 设置终止标志（两种方式都保留）
            self.bRunMapEnd = True  # 旧版标志
            self.exit_event.set()   # 新版事件标志

            # 2. 唤醒可能阻塞在 queue.get() 的线程
            if hasattr(self, 'queue_ExceptionMsg'):
                try:
                    self.queue_ExceptionMsg.put(None)  # 发送空消息唤醒阻塞线程
                except:
                    self.log.warning("唤醒异常消息队列线程失败（队列可能已关闭）")

            # 3. 记录当前活跃线程（调试用）
            if hasattr(self, 'log'):
                active_threads = threading.enumerate()
                self.log.info(f"【终止阶段】当前活跃线程数: {len(active_threads)}")
                for t in active_threads:
                    self.log.info(f"  → {t.name} (存活: {t.is_alive()})")

            # 4. 等待线程退出（兼容旧版和新版）
            time.sleep(2)  # 留出清理时间

            # 5. 清理特定资源
            if hasattr(self, 'asan_monitor'):
                self.asan_monitor.logcat_clear()

            # 6. 调用父类清理逻辑
            super().teardown()

        except Exception as e:
            if hasattr(self, 'log'):
                self.log.error(f"teardown 执行失败: {str(e)}")
            raise

    def task_process_data(self):
        pass
    def run_local(self, dic_args):
        self.check_dic_args(dic_args)  # 处理传进来的参数
        self.log.info("处理传进来的参数完成")
        self.loadDataFromLocalConfig(dic_args)  # 读LocalConfig配置
        self.log.info("读LocalConfig配置完成")
        self.clearInfoFiles()  # 清空客户端向本用例通信的信息文件
        self.log.info("清空客户端向本用例通信的信息文件完成")
        self.processInterface(dic_args)  # 处理插件
        self.log.info("处理插件完成")
        self.OpenAutoLogin(dic_args)  # 自动登录
        self.log.info("自动登录完成")
        self.preRunToKillExe()  # 运行前清理之前没有关闭的相关程序
        self.log.info("运行前清理之前没有关闭的相关程序完成")
        self.processServerlist(dic_args)  # 处理serverlist
        self.log.info("处理serverlist完成")
        self.processResoucre(dic_args)  # 处理pakv5资源相关
        self.log.info("处理pakv5资源相关完成")
        self.processSearchPanelTab(dic_args)  # 处理运行所需的RunMap.tab
        self.log.info("处理运行所需的RunMap.tab完成")
        self.copyEnvToClient()  # 拷贝插件环境到Client
        self.log.info("拷贝插件环境到Client完成")
        self.clear_log()  # 清空日志
        self.log.info("清空日志完成")
        self.processWindows()
        self.log.info("处理分辨率完成")
        self.add_thread_for_searchPanel(dic_args)
        self.log.info("添加用例相关线程完成")
        # self.copyPerfeye()
        self.process_threads_beforeStartClient()
        self.log.info("启动用例相关线程完成")
        self.start_client_test(dic_args)
        self.log.info("启动游戏完成")
        self.task_mobile()
        self.log.info("移动端用例执行完成")
        self.task_process_data()
        self.log.info("用例数据处理完成")
def AutoRun(dic_parameters):
    global obj_test
    obj_test = CaseAsanJX3SearchPanel()
    obj_test.run_from_uauto(dic_parameters)
if __name__ == '__main__':
    obj_test = CaseAsanJX3SearchPanel()
    obj_test.run_from_IQB()
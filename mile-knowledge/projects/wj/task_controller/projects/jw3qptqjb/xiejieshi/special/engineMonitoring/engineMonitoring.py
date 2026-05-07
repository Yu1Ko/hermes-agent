import os
import time
import datetime
import shutil
import subprocess
from CaseJX3SearchPanel import CaseJX3SearchPanel
from CaseJX3Client import *
from PerfeyeCtrl import *
from HotPointMapCtrl import *
from XGameSocketClient import *


class engineMonitoring(CaseJX3SearchPanel):
    def __init__(self):
        super().__init__()  # 父类初始化
        self.isanalysisEnd = False
    def ignore_log_files(self, dir, files):
        return [f for f in files if f.endswith('.log')]
    def get_memory_size(self):
        try:
            result = subprocess.run(
                ['adb', '-s', self.deviceId, 'shell', 'cat', '/proc/meminfo'],
                capture_output=True,
                text=True,
                check=True
            )
            output = result.stdout
            # 查找总内存
            for line in output.splitlines():
                if 'MemTotal' in line:
                    mem_total_kb = int(line.split(':')[1].strip().split()[0])
                    mem_total_gb = mem_total_kb / 1024 / 1024
                    return f"{mem_total_gb:.1f}G"
            return "Unknown Memory"
        except subprocess.CalledProcessError as e:
            print(f"Error getting memory size: {e}")
            return "Unknown Memory"
    def get_cpu_model(self):
        try:
            result = subprocess.run(
                ['adb', '-s', self.deviceId, 'shell', 'cat', '/proc/cpuinfo'],
                capture_output=True,
                text=True,
                check=True
            )
            output = result.stdout
            # 查找CPU型号
            for line in output.splitlines():
                if 'Hardware' in line:
                    cpu_model = line.split(':')[1].strip()
                    return cpu_model
            return "Unknown CPU Model"
        except subprocess.CalledProcessError as e:
            print(f"Error getting CPU model: {e}")
            return "Unknown CPU Model"

    def adb_getFolderLastestFile(self, src, dst, deviceID=None):
        if deviceID:
            cmd = 'adb -s %s shell "ls -t %s | grep \'.opt$\' | head -n 1"' % (deviceID, src)
        else:
            cmd = 'adb shell "ls -t %s | grep \'.opt$\' | head -n 1"' % (src)
        pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        res = pi.stdout.read()
        try:
            res = str(res, encoding='gbk')
        except:
            res = str(res, encoding='utf8')
        res=res.split('\n')[0]
        res=res.strip()
        if not res:
            self.log.warning("No .opt file found in the specified directory.")
            return False
        src=src+'/'+res
        dst=os.path.join(dst,res)

        if deviceID:
            cmd = "adb -s %s pull %s %s" % (deviceID, src, dst)
        else:
            cmd = "adb pull %s %s" % (src, dst)
        pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
        res = pi.stdout.read()
        try:
            res = str(res, encoding='gbk')
        except:
            res = str(res, encoding='utf8')
        #print(res)
        return dst

    def adb_capture_screenshot(self, save_path, deviceID=None):
        """
        使用 adb 从指定设备捕获屏幕截图并保存到指定路径。
        """
        if deviceID:
            cmd = f'adb -s {deviceID} exec-out screencap -p'
        else:
            cmd = 'adb exec-out screencap -p'
        try:
            # 执行命令并获取输出
            with open(save_path, 'wb') as f:
                subprocess.run(cmd, stdout=f, check=True)
                self.log.info(f"Screenshot saved to {save_path}")
        except Exception as e:
            self.log.info(f"Error capturing screenshot: {e}")
            return False
        return True


    def copyToLocal(self):
        data_dir = rf".\{self.mapname}"
        os.makedirs(data_dir, exist_ok=True)
        for file in os.listdir(data_dir):
            os.remove(os.path.join(data_dir, file))   # 可能有残留的东西，先清空一下
        result = self.adb_getFolderLastestFile(self.CLIENT_PATH, data_dir, self.deviceId)
        if result:
            # 判断一下获取到的.opt时间合不合理
            self.log.info(f"optickfile:{result}")
            date_str = result.split(os.sep)[-1].strip(".opt()")
            self.log.info(f"optickfile date_str:{date_str}")
            dt = datetime.datetime.today()
            date_format = "%Y-%m-%d.%H-%M-%S"
            date_obj = dt.strptime(date_str, date_format)
            time_difference = datetime.datetime.today() - date_obj
            minutes_difference = time_difference.total_seconds() / 60
            self.log.info(f"optickfile minutes_difference:{minutes_difference}")
            if minutes_difference > 20:
                result = False
        if os.path.exists(os.path.join(GetTEMPFOLDER(), 'Optick.png')):
            shutil.copy(os.path.join(GetTEMPFOLDER(), 'Optick.png'), data_dir)   # 复制截图
        else:
            self.log.warning("No Optick.png found in TempFolder.")
            result = False
        return result, data_dir
    
    def copyToShare(self, data_dir):
        str_date = time.strftime('%Y_%m_%d', time.localtime(time.time()))
        root_path = r"\\10.11.85.148\FileShare-181-242\VKEngineOptick\每日性能监控"
        share_path = os.path.join(root_path, str_date, self.strMachineName, self.mapname)
        # os.makedirs(share_path, exist_ok=True)
        if os.path.exists(share_path):
            for file in os.listdir(share_path):
                os.remove(os.path.join(share_path, file))   # 先清空一下
            os.rmdir(share_path)
        self.log.info(f"copy to share {share_path}")
        shutil.copytree(data_dir, share_path, ignore=self.ignore_log_files)
        self.log.info(f"copy to share completed")
        return share_path
        
    def parser(self, data_dir):
        tool_dir = os.path.join(os.getcwd(), "monitor_for_vk_v1.4.exe")
        config_dir = os.path.join(os.getcwd(), "config.txt")
        tool_dir_share = r"\\10.11.85.148\FileShare-181-242\VKEngineOptick\每日性能监控\tool\monitor_for_vk_v1.4.exe"
        config_dir_share = r"\\10.11.85.148\FileShare-181-242\VKEngineOptick\每日性能监控\tool\config.txt"
        if not os.path.exists(tool_dir):
            shutil.copy(tool_dir_share, tool_dir)
        if not os.path.exists(config_dir):
            shutil.copy(config_dir_share, config_dir)
        self.log.info("start to analyze optick.")
        memsize = self.get_memory_size()
        cpu_model = self.get_cpu_model()
        # 反正引擎监控都是那几台，既然k60获取不到，直接根据deviceid来判断cpu得了
        strMachineName = self.strMachineName
        if self.deviceId=='d56771e5':
            cpu_model='Snapdragon 8+ Gen1'
            strMachineName='红米k60(d56771e5)'
        if self.deviceId == '324a3e69':
            strMachineName='小米10(324a3e69)'
        strCaseName = self.strCaseName
        if "XGame-成都|RunMap|Optick-引擎每日性能监控" in strCaseName:
            strCaseName="XGame-广都镇跑图"
        if "XGame-楚州|point|Optick-引擎每日性能监控" in strCaseName:
            strCaseName="XGame-楚州定点"
        if "XGame-成都|point|Optick-引擎每日性能监控" in strCaseName:
            strCaseName="XGame-成都定点"
        if "阵营日常" in strCaseName:
            strCaseName="XGame-阵营日常(河西翰墨)"
        self.log.info(f"analyze optick Command: monitor_for_vk_v1.4.exe {data_dir} {strMachineName} {strCaseName} {cpu_model} {memsize}")
        result = subprocess.run(['monitor_for_vk_v1.4.exe', data_dir, strMachineName, strCaseName, cpu_model, memsize], capture_output=True, text=True)

        self.log.info(f"analyze optick Output: {result.stdout}")
        self.log.info(f"analyze optick Error: {result.stderr}")
        self.log.info("analyze optick completed")


    def thread_Capture_Optick(self):
        nFrameLimit ,nTimeLimit ,nSpikeLimitMs,nMemoryLimitMb,nOptickSleep = 0,0,50,0,0
        if 'nFrameLimit' in self.args:
            nFrameLimit=int(self.args['nFrameLimit'])
        if 'nTimeLimit' in self.args:
            nTimeLimit=int(self.args['nTimeLimit'])
        if 'nSpikeLimitMs' in self.args:
            nSpikeLimitMs = int(self.args['nSpikeLimitMs'])
        if 'nMemoryLimitMb' in self.args:
            nMemoryLimitMb = int(self.args['nMemoryLimitMb'])
        if 'nOptickSleep' in self.args:
            nOptickSleep = int(self.args['nOptickSleep'])
        self.log.info("start remove old opt files")
        try:
            subprocess.run(f"adb -s {self.deviceId} shell rm {self.CLIENT_PATH}/*.opt", shell=True, check=True)
        except Exception as e:
            self.log.info(f"删除opt文件失败: {e}")    
        self.log.info(f"Capture Optick After {nOptickSleep}s")
        time.sleep(nOptickSleep)
        self.log.info("Capture Optick start")
        self.SocketClient.SetCaptureOptick_Start(nFrameLimit,nTimeLimit,nSpikeLimitMs,nMemoryLimitMb)
        strScreenShotPath = os.path.join(GetTEMPFOLDER(), 'Optick.png')
        result = self.Client_ScreenShot(strScreenShotPath, self.deviceId)
        if result:
            send_Subscriber_msg(self.strGuid, "optick开始采集", strScreenShotPath)
        else:
            send_Subscriber_msg(self.strGuid, "optick开始采集, 截图失败")

    def thread_SearchPanelPerfEyeCtrl(self, dicSwitch, t_parent):
        self.log.info("thread_SearchPanelPerfEyeCtrl start")
        try:
            if 'NoPerf' in dicSwitch:
                self.log.info("PerfMon NoPerf and thread_SearchPanelPerfEyeCtrl stop")
                return
            #本地没有perfeye 等主线程拷贝perfeye到本地
            while not self.bPerfeyeExist:
                self.log.info("wait copy perfeye")
                time.sleep(5)
            nPerfeyeErrorType=1
            bPerfeyeTest=False
            if 'PerfeyeTest' in dicSwitch:
                bPerfeyeTest=dicSwitch['PerfeyeTest']
            # self.perfeye=PerfeyeControl(deviceId=self.deviceId,bPerfeyeTest=bPerfeyeTest,strPackageName=self.package,nScreenshot_Interval=self.nScreenshot_Interval,strMachineTag=self.tagMachineType,strAppKey=self.AppKey)
            # self.perfeye.PerfeyeCreate()
            # self.perfeye.PerfeyeConnect()
            #self.perfeye=self.args['perfeye']
            self.perfeye=PerfeyeControl(deviceId=self.deviceId,bPerfeyeTest=bPerfeyeTest,strPackageName=self.package,nScreenshot_Interval=self.nScreenshot_Interval,strMachineTag=self.tagMachineType,strAppKey=self.AppKey,strOsVersion=self.args["osVersion"])
            self.perfeye.PerfeyeCreate()
            self.args['perfeyePid']=self.perfeye.PerfeyePid()
            self.perfeye.PerfeyeConnect()
            self.bCanStartClient=True
            #启动app成功后再开启采集数据
            while not self.clientPID:
                time.sleep(2)
            #time.sleep(10)
            if self.bMobile:
                strIpAddress=self.mobile_device.get_address()
            else:
                #strIpAddress=socket.gethostbyname(socket.gethostname())
                strIpAddress=machine_get_IPAddress()
            self.log.info(f"IP:{strIpAddress}")
            #临时测试
            self.log.info(f"SocketClientDLL.dll pathcwd:{os.path.join(os.path.dirname(os.path.abspath(__file__)),'SocketClientDLL.dll')}")
            self.SocketClient=XGameSocketClient(os.path.join(os.path.dirname(os.path.abspath(__file__)),'SocketClientDLL.dll'),strIpAddress,1112,self.tagMachineType)
            '''
            if self.deviceId=='43dd27e9':
                #临时设备关闭SDK
                self.SocketClient.bSwitch=False'''
            #self.SocketClient.SDK_Start()
            def CheckPerfeyeStartTimeout(t_parent):
                self.log.info("CheckPerfeyeStartTimeout start")
                #检查perfeye_start超时
                nStepTime = 10
                nTimerPerfeyeStart=time.time()
                nTimeOut=3*60
                while t_parent.is_alive():
                    if self.bPerfeyeStartTimeOutFlag:
                        time.sleep(nStepTime)
                        if time.time()-nTimerPerfeyeStart>nTimeOut:
                            self.log.info(f"CheckPerfeyeStartTimeout timeout")
                            strMsg = f'{self.strMachineName},用例: {self.strCaseName}, {nTimeOut/60} 分钟还未perfeyestart成功 设备冷机 自动重启该设备,重启用例'
                            nExceptionType = ExceptionMsg.PERF_STARTERROR
                            self.queue_ExceptionMsg.put({'exceptionType': nExceptionType, 'msg': strMsg})
                            break
                    else:
                        #perfeye.start 成功
                        self.log.info("CheckPerfeyeStartTimeout exit")
                        break
            #防止Perfeye_start超时 导致用例采集不到数据
            # if self.bMobile:
            #     t = threading.Thread(target=CheckPerfeyeStartTimeout,args=(threading.currentThread(),))
            #     t.setDaemon(True)
            #     t.start()
            '''
            if self.tagMachineType == 'Android':
                data_types = [1, 2, 3, 4, 5, 6, 8, 9,10, 11, 12, 13, 14,19,35]
                # ios端30采集截图
            elif self.tagMachineType == 'Ios':
                # 17,18,19,10001
                if not self.nScreenshot_Interval:
                    self.nScreenshot_Interval = 15
                data_types = [1,5, 8, 9, 12,17,19]
            else:
                data_types = [1, 2, 3, 4, 5, 8, 9, 11, 12, 14, 32, 33,34, 35, 36,47]'''
            self.perfeye.PerfeyeStart(self.clientPID)
            #self.perfeye.PerfeyeStart(self.clientPID,data_types,self.nScreenshot_Interval,self.bMobile)
            self.bPerfeyeStartTimeOutFlag=False #超时检查线程处理
            #登录界面获取不到数据  会卡住perfeye线程,因此使用异步线程
            #if self.tagMachineType!='Ios':
                #IOS不采集函数耗时避免游戏客户端显存不足宕机
                #self.SocketClient.PerfDataCreateAndStart()
            #等待登录界面开始
            while True:
                time.sleep(1)
                #采集optick时 不能采扩展数据
                if self.checkRecvInfoFromSearchpanel('AutoLoginPanel'):
                    if not self.bCaptureOptick:
                        self.SocketClient.PerfDataCreateAndStart()
                    break
            self.log.info("perfeye_startTime:" + str(time.time()))
            nTimerKeepHeart=0
            nTimerCheckPerfeye = 0
            nTimerRunMapEnd=0
            nCheckPerfeye=1
            bFpsTag = True
            bPerfeyeStartFlag=True
            nStepTime=0.1
            while t_parent.is_alive():
                # 解决HD hook慢导致采集数据缺失的问题
                #if 'XGame' not in self.clientType:
                    #if bFpsTag and PerfMon_getFpsForSharedMemory(self.clientPID):
                        #bFpsTag = False
                        #file = open(r'C:\RunMapResult\perfeye_ready', 'w')
                        #file.close()
                        #continue
                if nTimerRunMapEnd >= 0.2:
                    # 0.2秒检查一次是否跑图结束
                    nTimerRunMapEnd = 0
                    if self.bRunMapEnd:
                        self.log.info("thread_SearchPanelPerfEyeCtrl exit")
                        break
                elif nTimerCheckPerfeye>=nCheckPerfeye:
                    nTimerCheckPerfeye=0
                    if bPerfeyeStartFlag:
                        if self.checkRecvInfoFromSearchpanel('perfeye_start'):
                            bPerfeyeStartFlag=False
                            nPerfeyeErrorType = 2
                            if not self.bMobile:
                                vnc_disconnectall()
                            # 临时处理使用SDK关闭开关
                            self.EngineOption(dicSwitch)
                            self.RunCMD()
                            if self.bCaptureOptick:
                                # 用多线程跑
                                t = threading.Thread(target=self.thread_Capture_Optick)
                                t.setDaemon(True)
                                t.start()
                            else:
                                self.SocketClient.PerfDataSetTimeNode()

                            # 调用两次防止失效
                            self.perfeye.PerfeyeSetTimeNode()
                            self.perfeye.PerfeyeSetTimeNode()
                            self.log.info(f"perfeye_SetTimeNodeTime:{int(time.time())}")
                            # thread_IDLE_Checker = threading.Thread(target=self.fps_IDLE_Checker)
                            # thread_IDLE_Checker.setDaemon(True)
                            # thread_IDLE_Checker.start()
                    else:
                        if self.checkRecvInfoFromSearchpanel('perfeye_stop'):
                            nPerfeyeErrorType = 3
                            self.log.info(f"perfeye_StopTime:{int(time.time())}")
                            self.perfeye.PerfeyeStop()
                            if self.bCaptureOptick:
                                self.SocketClient.SetCaptureOptick_Stop()
                                data_path, data_dir = self.copyToLocal()
                                if data_path:
                                    self.parser(data_dir)
                                    self.copyToShare(data_dir)
                                    self.isanalysisEnd = True
                                else:
                                    self.log.info("get optick failed")
                                    send_Subscriber_msg(self.strGuid,f"用例:{self.strCaseName}  采集optick失败")
                                # 为了于Perfeye数据重合,SDK多取10秒数据
                                time.sleep(5)
                                self.SocketClient.PerfDataStop()
                                self.bExitGameFlag = True
                            break
                elif nTimerKeepHeart > 120:
                    self.log.info('SearchPanelPerfEyeCtrl heart')
                    nTimerKeepHeart = 0
                nTimerRunMapEnd+=nStepTime
                nTimerKeepHeart+=nStepTime
                nTimerCheckPerfeye+=nStepTime
                time.sleep(nStepTime)
            self.log.info("thread_SearchPanelPerfEyeCtrl stop")
        except Exception as e:
            info = traceback.format_exc()
            self.log.info(info)
            strMsg = f'{info}，机器: {self.strMachineName} 用例: {self.strCaseName}  冷机后'
            self.log.info(f'bRunMapEnd:{self.bRunMapEnd}')
            self.bRunMapEnd = True
            nExceptionType = ExceptionMsg.PERF_NETERROR
            self.nExceptionType=ExceptionMsg.PERF_NETERROR
            dic_msg={'exceptionType': nExceptionType, 'msg': strMsg}
            #Perfeye Start和Perfeye Stop失败 增加冷机时间
            #客户端启动后需要先结束
            self.Client_Kill()
            self.queue_ExceptionMsg.put(dic_msg)


    def task_mobile(self):

        self.nTaskTimeOut= self.nClientRunTimeOut + int(time.time() - self.nStartTimeSeconds)
        self.log.info(f"nTaskTimeOut:{self.nTaskTimeOut}")
        self.log.info('mobile wait start')
        nCount=0
        #需要检测异常检测线程发出的异常
        while 1:
            nCount+=1
            time.sleep(1)
            if nCount>120:
                self.log.info("task_mobile heart")
                nCount=0
            if self.strExceptionFlag is not None:
                raise Exception(self.strExceptionFlag)
            if self.checkRecvInfoFromSearchpanel('ExitGame') or self.bExitGameFlag:
                # 关闭app
                self.log.info(f'bRunMapEnd:{self.bRunMapEnd}')
                self.bRunMapEnd=True
                #app结束前获取截图
                if not self.strClientScreen:
                    try:
                        strScreenShotPath = os.path.join(GetTEMPFOLDER(), 'RunMapEndScene.png')
                        self.strClientScreen =self.Client_ScreenShot(strScreenShotPath)
                    except:
                        #避免因为截图失败 导致用例不能正常执行
                        pass
                #mobile_kill_app(self.package,self.deviceId)
                self.Client_Kill()
                if self.isanalysisEnd:
                    '''只有等待分析结束后 才让他退出，否则还没解析完线程结束会被自动化强行杀掉'''
                    break
        self.log.info('mobile wait end')

def AutoRun(dic_parameters):
    global obj_test
    obj_test = engineMonitoring()
    obj_test.run_from_uauto(dic_parameters)


if __name__ == '__main__':
    obj_test = engineMonitoring()
    obj_test.run_from_IQB()

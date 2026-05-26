# -*- coding: utf-8 -*-
import os
import time

from CaseJX3Client import *
from PerfeyeCtrl import *
from HotPointMapCtrl import *
#from PerfMonCtrl import *
from XGameSocketClient import *
#from mobile_device_controller import *
class CaseJX3SearchPanel(CaseJX3Client):

    def __init__(self):
        super().__init__()
        # CtrlPerfMon.__init__(self)
        self.FLY_TIME = 600
        self.DIC_MAPNAME = {}
        self.DIC_MAPTYPE={}
        with open(os.path.join(os.path.dirname(os.path.realpath(__file__)),'MapList.tab'),encoding='gbk') as f:
            for line in f:
                list_data = line.split('\t')
                if list_data[0] == 'ID':
                    continue  # 第一行跳过
                self.DIC_MAPNAME[list_data[0]] = utf8(list_data[1])
                self.DIC_MAPTYPE[list_data[0]]=utf8(list_data[8])

        '''
        self.DIC_MAPNAME_CLASSIC = {}
        with open(os.path.join(os.path.dirname(os.path.realpath(__file__)),'MapList_classic.tab'),encoding='gbk') as f:
            for line in f:
                list_data = line.split('\t')
                if list_data[0] == 'ID':
                    continue  # 第一行跳过
                self.DIC_MAPNAME_CLASSIC[list_data[0]] = utf8(list_data[1])
        '''
        self.DIC_TrafficInfo = {}
        self.MapPathData_path = 'MapPathData.tab'
        self.queue_ExceptionMsg = queue.Queue(maxsize=10)
        self.bResetFlag=False
        self.bRunMapEnd = False
        self.bExitGameFlag=False  #用于检测用例结束,部分用例不通过游戏客户端插件来判断用例是否结束
        self.bWaitLoginPanel=False #是否需要停留在登录界面 图像检测线程需根据该开关判断
        self.module_CrashReport=None #宕机检测模块
        self.bPerfeyeStartTimeOutFlag=True #perfeye_start是否超时标志
        self.bDumpCase=False #是否为宕机用例
        self.list_strCmd = [] #跑图前需要执行的Cmd指令
        self.bCaptureOptick=False
        self.nExceptionType=0 #异常类型


    def preRunToKillExe(self):
        if not self.bMobile:
            win32_kill_process('DumpReport64.exe')
            win32_kill_process('WerFault.exe')
            win32_kill_process('PerformanceTool.exe')
            win32_kill_process('PerfMon.exe')
            # win32_kill_process('Perfeye.exe')
            win32_kill_process(self.exename)

    def clearInfoFiles(self):
        super().clearInfoFiles()
        # XGame项目在插件中会自动清除用例文件
        listFilesName = ['perfeye_start', 'perfeye_stop',  'BeginRunMap', 'ExitGame']
        #游戏客户端通信文件夹
        strBasePath = self.CLIENT_PATH + LOCAL_INFO_FILE
        ''''''
        for fileName in listFilesName:
            uFilepath = os.path.join(strBasePath, fileName)
            self.log.info("clear:" + uFilepath)
            filecontrol_deleteFileOrFolder(uFilepath, self.deviceId,self.package)
        # 创建通信文件夹
        if not filecontrol_existFileOrFolder(strBasePath, self.deviceId,self.package):
            filecontrol_createFolder(strBasePath, self.deviceId,self.package)

    def checkRecvInfoFromSearchpanel(self, fileName):
        uFilepath = os.path.join(self.CLIENT_PATH + LOCAL_INFO_FILE, fileName)
        if filecontrol_existFileOrFolder(uFilepath, self.deviceId,self.package):
            self.log.info(u"find: {}".format(uFilepath))
            filecontrol_deleteFileOrFolder(uFilepath, self.deviceId,self.package)
            return True
        return False


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
            self.perfeye=PerfeyeControl(deviceId=self.deviceId,bPerfeyeTest=bPerfeyeTest,strPackageName=self.package,nScreenshot_Interval=self.nScreenshot_Interval,strMachineTag=self.tagMachineType,strAppKey=self.AppKey)
            self.perfeye.PerfeyeCreate()
            self.perfeye.PerfeyeConnect()
            self.bCanStartClient=True
            #启动app成功后再开启采集数据
            while not self.clientPID:
                time.sleep(2)
            time.sleep(10)
            if self.bMobile:
                strIpAddress=self.mobile_device.get_address()
            else:
                #strIpAddress=socket.gethostbyname(socket.gethostname())
                strIpAddress=machine_get_IPAddress()
            self.log.info(f"IP:{strIpAddress}")
            #临时测试
            self.SocketClient=XGameSocketClient(os.path.join(os.getcwd(),'SocketClientDLL.dll'),strIpAddress,1112,self.tagMachineType)
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
                            self.nExceptionType=ExceptionMsg.PERF_STARTERROR
                            self.queue_ExceptionMsg.put({'exceptionType': nExceptionType, 'msg': strMsg})
                            break
                    else:
                        #perfeye.start 成功
                        self.log.info("CheckPerfeyeStartTimeout exit")
                        break
            #防止Perfeye_start超时 导致用例采集不到数据
            if self.bMobile:
                t = threading.Thread(target=CheckPerfeyeStartTimeout,args=(threading.currentThread(),))
                t.setDaemon(True)
                t.start()
            self.perfeye.PerfeyeStart(self.clientPID)
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
                                nFrameLimit ,nTimeLimit ,nSpikeLimitMs,nMemoryLimitMb = 0,0,50,0
                                if 'nFrameLimit' in self.args:
                                    nFrameLimit=int(self.args['nFrameLimit'])
                                if 'nTimeLimit' in self.args:
                                    nTimeLimit=int(self.args['nTimeLimit'])
                                if 'nSpikeLimitMs' in self.args:
                                    nSpikeLimitMs = int(self.args['nSpikeLimitMs'])
                                if 'nMemoryLimitMb' in self.args:
                                    nMemoryLimitMb = int(self.args['nMemoryLimitMb'])

                                self.SocketClient.SetCaptureOptick_Start(nFrameLimit,nTimeLimit,nSpikeLimitMs,nMemoryLimitMb)
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
                            else:
                                # 为了于Perfeye数据重合,SDK多取10秒数据
                                time.sleep(5)
                                self.SocketClient.PerfDataStop()
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

    #跑前执行cmd 比如设置帧率等
    def RunCMD(self):
        if self.nFrame>1:
            self.list_strCmd.append(f"/cmd App_SetFrameLimitCount({self.nFrame})")
        for strCmd in self.list_strCmd:
            self.SocketClient.SendCommandToSDK(strCmd)

    def EngineOption(self,dic_args):
        #需要设置帧率限定
        if self.nFrame:
            strCMD = f'/cmd App_SetFrameLimitCount({self.nFrame})'
            #self.SocketClient.SendCommandToSDK(strCMD)
        if "sdk" in dic_args:
            nSdk = int(dic_args["sdk"])
            if nSdk == 1:
                self.SocketClient.SetEngineOption(Enum_option("EO_debug_set_gameplay_model_enable"), 0, False)
                self.SocketClient.SetEngineOption(Enum_option("EO_basic_set_shadow_quality_int"), 1, 0)
            elif nSdk == 2:
                #gi开
                self.log.info('开GI')
                self.SocketClient.SetEngineOption(Enum_option("EO_debug_set_offlinegi_enable"), 0, True)
            elif nSdk==3:
                self.SocketClient.SetEngineOption(Enum_option("EO_basic_set_shadow_quality_int"), 1, 0)
            elif nSdk==4:
                self.SocketClient.SetEngineOption(Enum_option("EO_foliage_set_render_tree_enable"),0,False)
            elif nSdk==5:
                self.SocketClient.SetEngineOption(Enum_option("EO_foliage_set_render_grass_enable"),0,False)
            elif nSdk==6:
                #关闭light
                self.SocketClient.SetEngineOption(Enum_option("EO_debug_set_point_light_enable"), 0, False)
                self.SocketClient.SetEngineOption(Enum_option("EO_debug_set_spot_light_enable"), 0, False)
            elif nSdk==7:
                # 关闭light+water
                self.SocketClient.SetEngineOption(Enum_option("EO_debug_set_point_light_enable"), 0, False)
                self.SocketClient.SetEngineOption(Enum_option("EO_debug_set_spot_light_enable"), 0, False)
                self.SocketClient.SetEngineOption(Enum_option("EO_debug_set_water_enable"), 0, False)
            elif nSdk==8:
                # 关闭water
                self.SocketClient.SetEngineOption(Enum_option("EO_debug_set_water_enable"), 0, False)
            elif nSdk==9:
                #gi关
                self.SocketClient.SetEngineOption(Enum_option("EO_debug_set_offlinegi_enable"), 0, False)
            elif nSdk==10:
                #抽帧开
                self.SocketClient.SetEngineOption(Enum_option("EO_animation_set_extract_frame_enable"),0,True)
            elif nSdk==11:
                #抽帧开
                self.SocketClient.SetEngineOption(Enum_option("EO_animation_set_extract_frame_enable"),0,False)
            elif nSdk == 12:
                #临时测试  #gi关 taa关 Fxaa开
                self.SocketClient.SetEngineOption(Enum_option("EO_debug_set_offlinegi_enable"), 0, False)
                self.SocketClient.SetEngineOption(Enum_option("EO_post_common_set_taa_enable"),0,False)
                self.SocketClient.SetEngineOption(Enum_option("EO_post_common_set_fxaa_enable"), 0, True)
            elif nSdk==13:
                self.SocketClient.SetEngineOption(Enum_option("EO_post_common_set_ray_march_fog_enable"), 0, False)
            elif nSdk==14: #taa关
                self.SocketClient.SetEngineOption(Enum_option("EO_post_common_set_taa_enable"),0,False)
            elif nSdk==15: #sspr关
                self.SocketClient.SetEngineOption(Enum_option("EO_post_common_set_sspr_enable"), 0, False)
            elif nSdk == 16:  # water关 阴影关 taa关 sspr关
                self.SocketClient.SetEngineOption(Enum_option("EO_debug_set_water_enable"), 0, False)
                self.SocketClient.SetEngineOption(Enum_option("EO_basic_set_shadow_quality_int"), 1, 0)
                self.SocketClient.SetEngineOption(Enum_option("EO_post_common_set_taa_enable"), 0, False)
                self.SocketClient.SetEngineOption(Enum_option("EO_post_common_set_sspr_enable"), 0, False)
            elif nSdk==17: #关闭oit
                self.SocketClient.SetEngineOption(Enum_option("EO_debug_set_oit_enable"), 0, False)
            elif nSdk==18: #关闭sfx特效
                self.SocketClient.SetEngineOption(Enum_option("EO_debug_set_sfx_enable"), 0, False)
            elif nSdk==19:#一之窟 boss特殊 测试
                self.SocketClient.SetEngineOption(Enum_option("EO_post_common_set_taa_enable"), 0, False)
                self.SocketClient.SetEngineOption(Enum_option("EO_post_common_set_fxaa_enable"), 0, True)
                self.SocketClient.SetEngineOption(Enum_option("EO_post_common_set_post_render_bloom_enable"), 0, False)
                self.SocketClient.SetEngineOption(Enum_option("EO_post_common_set_light_shaft_bloom_enable"), 0, False)
            self.log.info(f"EngineOption:{nSdk}")

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
        if self.strNumVideoLevel=='1':
            nTimerOut+=600
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
                self.nExceptionType=ExceptionMsg.TASKTIMEOUT
                # 防止通知等待时间过长 app长时间运行导致手机发热
                self.Client_Kill()
                # mobile_kill_app(self.package, self.deviceId)
                self.queue_ExceptionMsg.put(
                    {'exceptionType': nExceptionType, 'msg': strMsg, 'screenshotPath': strScreenShotPath})
                self.log.info(strMsg % (self.nTaskTimeOut // 60) + ": 用例超时检查线程退出 ")
                break
            elif nTimerKeepHeart > 120:
                # 120写一条日志
                nTimerKeepHeart = 0
                self.log.info('CheckTaskTimeOut heart')

            nTimerTimeOut += nStepTime
            nTimerRunMapEnd += nStepTime
            nTimerKeepHeart += nStepTime
            time.sleep(nStepTime)

    def thread_CheckScreenShot(self, dicSwitch, t_parent):
        # 放入消息队列的消息内容
        self.log.info("thread_CheckScreenShot start")
        strScreenShotPath = os.path.join('TempFolder', 'CheckScreenShot.png')
        nStepTime = 0.1
        nTimerRunMapEnd = 0
        nTimerScreenShot = 0
        nTimerKeepHeart = 0
        nBlackScreenCnt=0
        nStuckCnt=0
        strLastResult=''
        nLoginCnt=0
        nReconnectionCnt=0
        while t_parent.is_alive():
            # 检测app是否启动
            if not self.clientPID:
                time.sleep(10)
                continue
            if nTimerRunMapEnd > 0.2:
                # 0.2秒检查一次是否跑图结束
                nTimerRunMapEnd = 0
                if self.bRunMapEnd:
                    self.log.info("thread_CheckScreenShot exit")
                    break
            elif nTimerScreenShot > 60:
                nTimerScreenShot = 0
                # 60秒检查一次截图
                self.Client_ScreenShot(strScreenShotPath)
                try:
                    strResult = paddleocr(strScreenShotPath)
                    self.log.info(f"screenshot result:{strResult}")
                    if strResult != strLastResult:
                        strLastResult = strResult
                        nStuckCnt = 0
                    else:
                        nStuckCnt += 1
                        if nStuckCnt == 3:
                            nStuckCnt = 0
                            strMsg = '截图中 发现三次内容一致,请检查是否已经卡死'
                            self.log.info(strMsg)
                            send_Subscriber_msg(self.strGuid, strMsg, strScreenShotPath)
                            continue

                    # 根据图像识别结果判断异常
                    if strResult == "":
                        nBlackScreenCnt += 1
                        if nBlackScreenCnt == 3:
                            nBlackScreenCnt = 0
                            strMsg = '三次截图中 未检查到任何信息,请检查是否已经黑屏'
                            self.log.info(strMsg)
                            send_Subscriber_msg(self.strGuid, strMsg, strScreenShotPath)
                    elif '信任此电脑' in strResult:
                        #ios出现信任弹窗 会造成检测app运行失效
                        self.mobile_device.DealWith_Mobile_Window()
                        self.log.info('图像文字识别线程 处理弹窗 信任 弹窗')

                    elif '服务器断开' in strResult:
                        nExceptionType = ExceptionMsg.SERVER_DISCONNECT
                        self.nExceptionType=ExceptionMsg.SERVER_DISCONNECT
                        nSleepTime = self.countDeviceSleepTime()
                        strMsg = f'与服务器断开链接,冷机后重启用例'
                        self.bRunMapEnd = True
                        self.queue_ExceptionMsg.put(
                            {'exceptionType': nExceptionType, 'msg': strMsg, 'screenshotPath': strScreenShotPath})
                        break
                    elif '登录账号' in strResult:
                        #需要在登录界面停留
                        if self.bWaitLoginPanel:
                            continue
                        nLoginCnt += 1
                        if nLoginCnt == 6:
                            nLoginCnt = 0
                            nExceptionType = ExceptionMsg.SERVER_DISCONNECT
                            self.nExceptionType=ExceptionMsg.SERVER_DISCONNECT
                            nSleepTime = self.countDeviceSleepTime()
                            strMsg = f'卡在登录界面,冷机后重启用例'
                            self.bRunMapEnd = True
                            self.queue_ExceptionMsg.put(
                                {'exceptionType': nExceptionType, 'msg': strMsg, 'screenshotPath': strScreenShotPath})
                            break
                    elif '初始化失败' in strResult:
                        nExceptionType = ExceptionMsg.SERVER_DISCONNECT
                        self.nExceptionType= ExceptionMsg.SERVER_DISCONNECT
                        nSleepTime = self.countDeviceSleepTime()
                        strMsg = f'游戏初始化失败,冷机后重启用例'
                        self.bRunMapEnd = True
                        self.queue_ExceptionMsg.put(
                            {'exceptionType': nExceptionType, 'msg': strMsg, 'screenshotPath': strScreenShotPath})
                        break
                    elif '努力重连中' in strResult:
                        nReconnectionCnt += 1
                        if nReconnectionCnt == 3:
                            nExceptionType = ExceptionMsg.SERVER_DISCONNECT
                            self.nExceptionType=ExceptionMsg.SERVER_DISCONNECT
                            nSleepTime = self.countDeviceSleepTime()
                            strMsg = f'用例:{self.strCaseName} 游戏客户端努力重连中{nReconnectionCnt} 失败 ,冷机后钟后重启用例'
                            nReconnectionCnt = 0
                            self.bRunMapEnd = True
                            self.queue_ExceptionMsg.put(
                                {'exceptionType': nExceptionType, 'msg': strMsg, 'screenshotPath': strScreenShotPath})
                            break

                except Exception:
                    info = traceback.format_exc()
                    self.log.info(info)

            elif nTimerKeepHeart > 120:
                # 120写一条日志
                nTimerKeepHeart = 0
                self.log.info('CheckScreenShot heart')
            nTimerScreenShot += nStepTime
            nTimerRunMapEnd += nStepTime
            nTimerKeepHeart += nStepTime
            time.sleep(nStepTime)

    def thread_CheckAppRunStateAndCrash(self, dicSwitch, t_parent):
        self.log.info("thread_CheckAppRunStateAndCrash start")
        #放入消息队列的消息内容
        strMsg=''
        nExceptionType=0
        strScreenShotPath = os.path.join('TempFolder', 'CrashScene.png')
        nStepTime=0.1
        nTimerCheckCrash=0
        nTimerRunMapEnd=0
        nTimerKeepHeart=0
        while t_parent.is_alive():
            #检测app是否启动
            if not self.clientPID :
                time.sleep(10)
                continue
            if nTimerRunMapEnd>0.2:
                # 0.2秒检查一次是否跑图结束
                nTimerRunMapEnd=0
                if self.bRunMapEnd:
                    self.log.info("thread_CheckAppRunStateAndCrash exit")
                    break
            elif nTimerCheckCrash>10:
                #10秒检查一次宕机
                nTimerCheckCrash=0
                if self.bMobile:
                    # app停止运行
                    # if not mobile_determine_runapp(self.package, self.deviceId):
                    if not self.mobile_device.determine_runapp():
                        #ios出现信任窗口弹窗该api会返回False
                        strScreenShotPath = self.Client_ScreenShot(strScreenShotPath)
                        strResult = paddleocr(strScreenShotPath)
                        self.log.info(f'crash thread ScreenShot result:{strResult}')
                        if '信任此电脑' in strResult:
                            #等待截图线程处理弹窗即可
                            self.log.info('宕机检测线程 处理弹窗 信任 弹窗')
                            self.mobile_device.DealWith_Mobile_Window()
                            continue
                        # 检查是否发生宕机
                        self.nClientRunTime = int(time.time()) - self.nClientStartTime
                        # if mobile_check_crash(self.package, self.deviceId):
                        if self.mobile_device.check_crash():
                            nExceptionType = ExceptionMsg.CRASH
                            strMsg = f'{self.strMachineName}:用例: {self.strCaseName}，已经宕机，需要查看现场'
                        else:
                            strMsg = f'{self.strMachineName}:用例: {self.strCaseName}，已经闪退，需要查看现场'
                            nExceptionType = ExceptionMsg.FLASHBACK
                        self.nExceptionType=ExceptionMsg.CRASH
                        self.log.info(f'bRunMapEnd:{self.bRunMapEnd}')
                        self.bRunMapEnd = True

                        # mobile_switch_background(self.deviceId, strScreenShotPath)
                        # 会卡在这个位置
                        # self.mobile_device.switch_background(strScreenShotPath)
                        strMsg += f"\t 游戏客户端运行时长:{self.nClientRunTime} 秒"
                        if self.strClientUUID:
                            strMsg += f"\nCrasheyeUUID:{self.strClientUUID}\n"
                            # 一旦触发宕机
                        self.log.info(strMsg + ": 宕机检查线程退出 ")
                        # 需要再次启动客户端才会上传宕机报告
                        self.bCrashReport = False
                        self.queue_ExceptionMsg.put(
                            {'exceptionType': nExceptionType, 'msg': strMsg,'screenshotPath': strScreenShotPath})
                        break
                else:
                    if not win32_findProcessByPid(self.clientPID):
                        nExceptionType = ExceptionMsg.CRASH
                        self.nExceptionType = ExceptionMsg.CRASH
                        strMsg = f'{self.strMachineName}:用例: {self.strCaseName}，已经宕机，需要查看现场'
                        self.nClientRunTime = int(time.time()) - self.nClientStartTime
                        self.log.info(f'bRunMapEnd:{self.bRunMapEnd}')
                        self.bRunMapEnd = True
                        strScreenShotPath=self.Client_ScreenShot(strScreenShotPath)
                        strMsg += f"\t 游戏客户端运行时长:{self.nClientRunTime} 秒"
                        # 一旦触发宕机
                        self.log.info(strMsg + ": 宕机检查线程退出 ")
                        self.queue_ExceptionMsg.put(
                            {'exceptionType': nExceptionType, 'msg': strMsg, 'screenshotPath': strScreenShotPath})
                        break
            elif nTimerKeepHeart>120:
                # 120写一条日志
                nTimerKeepHeart=0
                self.log.info('CheckAppRunStateAndCrash heart')
            nTimerCheckCrash+=nStepTime
            nTimerRunMapEnd += nStepTime
            nTimerKeepHeart+=nStepTime
            time.sleep(nStepTime)

    def thread_DeviceBatteryMonitor(self, dicSwitch, t_parent:threading.Thread):
        if not self.bMobile:
            return
        self.log.info("thread_DeviceBatteryMonitor start")
        nTimer = 0  # 线程运行cd
        nBatteryTime = 0  # 电池电量检测时间
        nExceptionType = ExceptionMsg.BATTERY_LOW  # 异常类型
        nMinBattery = 30  # 低于此电量时停止自动化
        nExpectBattery = 50  # 预期充到多少电量
        nSleepMinute = 30  # 充电多长时间 单位分钟
        nBatteryCd = 60 * 5  # 电池电量检测时间 这里就是5分钟
        nBattery=0
        while t_parent.is_alive():
            # sleep_heartbeat(5)  # 每5分钟检测一次
            time.sleep(0.1)
            nTimer += 0.1
            nBatteryTime += 0.1
            if nTimer >= 120:
                # 每120秒 打印一次线程运行
                self.log.info('thread_DeviceBatteryMonitor heart')
                self.log.info(f'电量剩余:{nBattery}')
                nTimer = 0
            # 判断跑图是否结束，如果结束，循环结束，线程退出
            if self.bRunMapEnd:
                break
            if nBatteryTime >= nBatteryCd:
                # 每 nBatteryCd 秒检测一次当前电量
                nBattery = self.mobile_device.get_battery()
                if nBattery==0:
                    #电量获取失败
                    break
                if nBattery < nMinBattery:
                    # 电量低于{nMinBattery}%要停止自动化
                    self.bRunMapEnd = True
                    # 防止通知等待时间过长 app长时间运行导致手机发热
                    self.Client_Kill()
                    errorMsg = f'{self.strMachineName}:用例: {self.strCaseName}，检测电量低于{nMinBattery}%，停止自动化等待充电至{nExpectBattery}%'
                    self.log.warning(errorMsg)
                    self.nExceptionType=ExceptionMsg.BATTERY_LOW
                    self.queue_ExceptionMsg.put(
                        {
                            'exceptionType': nExceptionType,
                            'msg': errorMsg,
                            'sleepMinute': nSleepMinute,
                            'expectBattery': nExpectBattery
                        }
                    )
                nBatteryTime = 0
        self.log.info('thread_DeviceBatteryMonitor exit')


    def thread_DealWith_ExceptionMsg(self, dicSwitch, t_parent):
        self.log.info('thread_DealWith_ExceptionMsg start')
        strMsg = ''
        # 采用消息队列统一处理用例异常消息  只处理第一条消息
        # 消息类型:dic  必填： "exceptionType":1,'msg':发生宕机, 'screenshotPath':/TempFolder/test.png ，'sleepMinute' 睡眠多少分钟
        nTimer = 0
        while t_parent.is_alive():
            time.sleep(0.1)
            try:
                nTimer += 0.1
                if nTimer > 120:
                    self.log.info('DealWith_ExceptionMsg heart')
                    nTimer = 0
                dic_msg = self.queue_ExceptionMsg.get(block=False)
            except queue.Empty:
                continue
            except:
                info = traceback.format_exc()
                self.log.error(info)
            # 检查消息格式
            if not ('exceptionType' in dic_msg and 'msg' in dic_msg):
                strMsg = '消息格式错误，请检查消息格式'
                self.log.info("检查消息格式")
                break
            nEType = dic_msg['exceptionType']
            strMsg = dic_msg['msg']
            nWaitMinite=self.countDeviceSleepTime()
            self.log.info(f"DealWith_ExceptionMsg start Type:{nEType} msg:{strMsg}")
            # 非工作时间只通知一次
            nSendCount = 1
            if not is_workTime():
                nSendCount = 1
            # 宕机闪退合并处理
            if nEType == ExceptionMsg.CRASH or nEType == ExceptionMsg.FLASHBACK:

                # 判断宕机报告释放成功上传
                # 宕机 通知3次后没人处理 默认跳过当前用例
                # nSendCount=3

                # 闪退宕机依旧上传Perfeye数据
                try:
                    self.log.info("PerfeyeStop_dump_data")
                    self.perfeye.PerfeyeStop()
                    self.log.info("perfeye_save_dump_data")
                    subtags = '{0}|{1}|{2}|{3}|{4}|{5}'.format(self.tagVideoLevel, self.tagMachineType,
                                                               self.tagVideoCard, self.mapname, self.testpoint,
                                                               date_get_szToday())
                    self.perfeye.PerfeyeSave(subtags=subtags,BVT=False,nMaxRetransmissionCount=1,strVersion=self.GetVersion())
                except:
                    pass
                for n in range(1, nSendCount + 1):
                    strAppendMsg = f": 第{n}通知"
                    if n == nSendCount:
                        strAppendMsg = f": 正在自动获取宕机报告相关信息 请稍等5分钟"
                    # 移动端设备ID就是GUID
                    send_Subscriber_msg(self.strGuid, strMsg + strAppendMsg, dic_msg['screenshotPath'])
                # 每隔5分钟通知一次
                # 处理设备logcat存放路径
                strBasePath = r"\\10.11.85.148\FileShare-181-242\liuzhu\JX3BVT\DumpSysLog"
                cleanup_date_folders(strBasePath)
                strDumpLogPath = f"{strBasePath}\{date_get_szToday()}\{self.strMachineName}\{self.strCaseName.replace('|', '-')}"
                # 宕机防止用例日志被覆盖
                strDumpLogPath = sort_filePath(strDumpLogPath)
                self.log.info(f"strDumpLogPath:{strDumpLogPath}")
                filecontrol_createFolder(strDumpLogPath)
                self.log.info('Dump test1')
                # 参数填写错误会导致线程卡住
                # 拷贝游戏客户端日志到共享
                if not self.strClientLog:
                    # 拷贝账号信息到宕机共享
                    strAccountFileName = f'{self.strAccount}-{self.strDisplayRegion}-{self.strDisplayServer}'
                    strAccountFilePath = f'TempFolder{os.sep}{strAccountFileName}'
                    with open(strAccountFilePath, 'w') as f:
                        pass
                    filecontrol_copyFileOrFolder(strAccountFilePath, strDumpLogPath)
                    # 结束游戏客户端后,获取日志到本地
                    strDate = time.strftime(f"%Y_%m_%d", time.localtime())
                    self.strClientLog = filecontrol_getFolderLastestFile(self.CLIENT_LOG_PATH + '/' + strDate,
                                                                         'TempFolder', self.deviceId, self.package)
                    filecontrol_copyFileOrFolder(self.strClientLog, strDumpLogPath)
                self.log.info('Dump test2')
                from CrasheyeReport import CrasheyeReport
                self.module_CrashReport = CrasheyeReport(self.mobile_device, self.CLIENT_PATH, self.tagMachineType,
                                                         strServerPath=strDumpLogPath)
                self.module_CrashReport.Start()
                self.log.info('Dump test3')
                # 默认检测200s
                nTimeOut = 200
                nTimeOutStep = 5
                uTimeOutFlag = time.time() + nTimeOut
                strAppendMsg = None
                while not self.module_CrashReport.GetResult():
                    time.sleep(nTimeOutStep)
                    self.log.info(f"crashReportModel.GetResult {nTimeOutStep}s/次")
                    # 超时 则无报告产出
                    if time.time() > uTimeOutFlag:
                        strAppendMsg = f"该宕机在宕机平台无宕机报告产出 {nWaitMinite}分钟后 跳过该用例"
                        break
                # 宕机报告检查结束
                self.module_CrashReport.Stop()
                strInfo = "UUID"
                if not self.bMobile:
                    strInfo = "DumpKey"
                if not strAppendMsg:
                    strAppendMsg = f"请根据{strInfo}:{self.module_CrashReport.strClientUUID}\t 到宕机平台查找宕机报告\t {nWaitMinite}分钟后 跳过该用例"

            # strAppendMsg = r": 到\\10.11.85.148\FileShare-181-242\DumpAnalyse_XGame 查看宕机报告 冷机至}"

                send_Subscriber_msg(self.strGuid, strMsg + strAppendMsg, dic_msg['screenshotPath'])
                self.log.info(strAppendMsg)
                #sleep_heartbeat(nWaitMinite)
                self.device_cooling()

            elif nEType == ExceptionMsg.TASKTIMEOUT:
                # 用例超时 通知3次后没人处理 默认跳过当前用例
                # nSendCount=3
                for n in range(1, nSendCount + 1):
                    strAppendMsg = f": 第{n}通知"
                    strTemp = strMsg % (self.nTaskTimeOut // 60 + nWaitMinite * (n - 1))
                    if n == nSendCount:
                        strAppendMsg = f": 第{n}通知 无人处理 自动冷机后 默认跳过当前用例 "
                    send_Subscriber_msg(self.strGuid, strTemp + strAppendMsg, dic_msg['screenshotPath'])
                    self.log.info(strTemp + strAppendMsg)
                    # 每隔5分钟通知一次
                    self.device_cooling()
                    sleep_heartbeat(nWaitMinite)
                    if '-scence' in self.testpoint:
                        # 专项 超时直接重启
                        self.bResetFlag = True
                        break
            elif nEType == ExceptionMsg.PERF_NETERROR:
                # perfeye网络错误 立即重启用例 (ios端直接重启设备)
                #sleep_heartbeat(nWaitMinite)
                self.Client_Kill()
                bRebootFlag = False
                if self.tagMachineType == 'Ios' and is_workTime(nEnd=18):
                    strMsg += ' ios端重启设备'
                    bRebootFlag = True
                else:
                    strMsg += ' 重启用例'
                send_Subscriber_msg(self.strGuid, strMsg)
                self.device_cooling()
                if bRebootFlag:
                    # 先执行tearndown 避免设备重启 iqb断连导致资源不释放
                    if not self.bTeardown:
                        self.bTeardown = True
                        self.teardown()
                    self.mobile_device.device_reboot()
                self.bResetFlag = True
            elif nEType ==ExceptionMsg.PERF_STARTERROR:
                #设备冷机后 重启设备 需要先
                self.Client_Kill()
                bRebootFlag=False
                if self.tagMachineType == 'Ios' and is_workTime(nEnd=18):
                    strMsg += ' ios端重启设备'
                    bRebootFlag =True
                else:
                    strMsg += ' 重启用例'
                send_Subscriber_msg(self.strGuid, strMsg)
                self.device_cooling()
                if bRebootFlag:
                    # 先执行tearndown 避免设备重启 iqb断连导致资源不释放
                    if not self.bTeardown:
                        self.bTeardown = True
                        self.teardown()
                    self.mobile_device.device_reboot()
                self.bResetFlag = True
            elif nEType == ExceptionMsg.PERF_UPLOADERROR:
                # perfeye保存数据失败 冷机dic_msg['sleepMinute']分钟后 重启用例
                bRebootFlag = False
                if self.tagMachineType == 'Ios' and is_workTime(nEnd=18):
                    strMsg += ' ios端重启设备'
                    bRebootFlag = True
                else:
                    strMsg += ' 重启用例'
                send_Subscriber_msg(self.strGuid, strMsg)
                self.device_cooling()
                if bRebootFlag:
                    # 先执行tearndown 避免设备重启 iqb断连导致资源不释放
                    if not self.bTeardown:
                        self.bTeardown = True
                        self.teardown()
                    self.mobile_device.device_reboot()
                self.bResetFlag = True
            elif nEType == ExceptionMsg.BATTERY_LOW:
                # 设备电量过低
                nSleepMinute = dic_msg['sleepMinute']  # 每次等待充电时间 nExpectBattery
                nExpectBattery = dic_msg['expectBattery']
                # strMsg内容：检测电量低于{nMinBattery}%，停止自动化等待充电至{nExpectBattery}%'
                send_Subscriber_msg(self.strGuid, strMsg)
                nMaxWaitTime = nSleepMinute * 2  # 最大等待时间，这里用 两个nSleepMinute
                nAlreadyWaitTime = 0  # 已经等待的时间 一但超过nMaxWaitTime，则发送协作消息通知及时处理
                while True:
                    nNowBattery = self.mobile_device.get_battery()  # 当前电量
                    strMsg = f"{self.strMachineName}:已充电{nAlreadyWaitTime}分钟，当前电量{nNowBattery}%"
                    if nAlreadyWaitTime >= nMaxWaitTime and nNowBattery < nExpectBattery:
                        # 如果 充电时长超过 最大等待时间，并且当前电量小于预期电量，发送协作消息通知及时处理
                        strMsg += f"，仍小于{nExpectBattery}%，请及时处理"
                        # break
                        # 此处继续卡住等待处理或其它操作
                    elif nNowBattery >= nExpectBattery:
                        self.bResetFlag = True  # 重启自动化
                        break
                    send_Subscriber_msg(self.strGuid, strMsg)
                    nAlreadyWaitTime += nSleepMinute
                    self.log.info(f"等待充电{nSleepMinute}分钟，当前电量{nNowBattery}")
                    sleep_heartbeat(nSleepMinute)  # 等待充电

            elif nEType == ExceptionMsg.SERVER_DISCONNECT:
                # 防止通知等待时间过长 app长时间运行导致手机发热
                self.Client_Kill()
                self.nClientRunTime = int(time.time()) - self.nClientStartTime
                strMsg += f"\t 游戏客户端运行时长:{self.nClientRunTime} 秒"
                send_Subscriber_msg(self.strGuid, strMsg,dic_msg['screenshotPath'])
                #sleep_heartbeat(nWaitMinite)
                self.device_cooling()
                self.bResetFlag = True
            # 安全退出
            self.log.info(f'异常消息: {dic_msg}')
            if not self.bTeardown:
                self.bTeardown = True
                self.teardown()
            # 重启或者跳过
            if self.bResetFlag:
                self.task_reset()
            else:
                self.task_run_next()

            break
        self.log.info('thread_DealWith_ExceptionMsg Eixt')


    def thread_KillDeath(self, dicSwitch, t_parent, timeout):
        try:
            caseName = dicSwitch['CaseName']
            bBeginRunMap = False  # 用于检测searchpanel是否开启的标识
            nSearchpanelCheckTime = 60 * 10
            nNotNewLogTime = 60 * 5
            nTimeout = timeout

            while not win32_findProcessByName(self.exename):
                time.sleep(1)
            time.sleep(10)
            startTime = time.time()

            while t_parent.is_alive():
                time.sleep(1)
                if self.checkRecvInfoFromSearchpanel('BeginRunMap'):
                    bBeginRunMap = True
                elapseTime = int(time.time() - startTime)
                if elapseTime % 5 == 0:  # 每5秒输出一下信息，感知此线程还活着
                    print("KillDeath check running:" + str(elapseTime))
                if elapseTime > nTimeout:  # 条件1：检查超时时间
                    strNotice = '[func:KillDeath]{} run timeout, timeout value is {}s'.format(caseName, timeout)
                    send_Subscriber_msg(self.strGuid, strNotice)
                    if hasattr(self, 'needKillDeath') and self.needKillDeath == True:
                        break
                    nTimeout = nTimeout + 5 * 60
                if elapseTime >= nSearchpanelCheckTime and not bBeginRunMap:  # 条件2：客户端开启一段时间后还没开始跑searchpanel
                    strNotice = '[func:KillDeath]{} searchpanel not start in {}分钟'.format(caseName,
                                                                                          nSearchpanelCheckTime / 60)
                    send_Subscriber_msg(self.strGuid, strNotice)
                    if hasattr(self, 'needKillDeath') and self.needKillDeath == True:
                        break
                    nSearchpanelCheckTime = nSearchpanelCheckTime + 5 * 60
                # 条件3：一段时间客户端没有写log,这只是个警告
                lastFile = getLastLogFile(self.CLIENT_LOG_PATH)
                logTimeElapse = time.time() - os.path.getmtime(lastFile)
                if logTimeElapse > nNotNewLogTime:
                    strNotice = '[func:KillDeath]{} 客户端log没有新内容，持续了{}分钟'.format(caseName, int(logTimeElapse / 60))
                    self.log.warning(strNotice)
                    self.log.warning('last log:{}'.format(lastFile))
                    send_Subscriber_msg(self.strGuid, strNotice)
                    nNotNewLogTime = nNotNewLogTime + 5 * 60

            info = '{} runtime is {}s'.format(caseName, str(elapseTime))
            self.log.info(info)
            if elapseTime > timeout:
                info = u'{} runtime is {}s, overtime is {}s'.format(caseName, str(elapseTime),
                                                                    str(elapseTime - timeout))
                send_Subscriber_msg(self.strGuid, info)
            if hasattr(self, 'needKillDeath') and self.needKillDeath == True:
                win32_kill_process(self.exename)
        except Exception:
            info = traceback.format_exc()
            self.log.error(info)

    def thread_WindowMinimiz(self, dicSwitch, t_parent):
        try:
            file_minimiz = r'c:\RunMapResult\minimiz'
            if os.path.exists(file_minimiz):
                filecontrol_deleteFileOrFolder(file_minimiz)
            while t_parent.is_alive():
                time.sleep(0.5)
                if os.path.exists(file_minimiz):
                    self.minimizWindow()
                    filecontrol_deleteFileOrFolder(file_minimiz)
                else:
                    pass
        except Exception as e:
            info = traceback.format_exc()
            self.log.error(info)

    def processInterface(self, dic_args):
        # 拷贝Interface文件夹到本地
        TEMP_FOLDER = 'TempFolder'
        # 删除游戏客户端的插件环境 防止删除失败
        strMuiPath = self.INTERFACE_PATH
        bRet = filecontrol_deleteFileOrFolder(strMuiPath, self.deviceId, self.package)
        self.log.info(f"释放成功删除插件环境:{strMuiPath}   bRet:{bRet}")
        while filecontrol_existFileOrFolder(strMuiPath, self.deviceId, self.package):
            filecontrol_deleteFileOrFolder(strMuiPath, self.deviceId, self.package)
            self.log.info("删除游戏客户端的插件环境")
            time.sleep(1)

        def _getRunMapTypeInterfaceFolderName():
            """
            获取 跑图类型对应需要拉取 Interface的文件夹名称列表
                - 通过 self.runMapType 获取辅助插件名
                - 然后通过 共享中：{{s_iniPath}}/XGame/Interface/SearchPanel/Interface.ini 这个文件来获取对应的插件名
            """
            iniFolderPath = "/XGame/Interface/SearchPanel/Interface.ini"  # ini文件对应目录
            s_serverIniPath = SERVER_PATH + iniFolderPath  # 共享ini文件目录
            s_localIniPath = TEMP_FOLDER + iniFolderPath
            filecontrol_copyFileOrFolder(s_serverIniPath, s_localIniPath)  # 将ini 拷到本地
            try:
                folderNames = ini_get("Interface", self.runMapType, s_localIniPath)  # 通过self.runMapType获取辅助插件名
                list_Interface=[]
                if folderNames == "nil":
                    # ”“空字符分割返回空字符
                    list_Interface=[self.runMapType,"SearchPanel"]
                    #先拷贝 SearchPanel文件夹到本地会导致插件报错
                else:
                    list_Interface=folderNames.split(",") + ["SearchPanel", self.runMapType]
                if 'AutoLogin' not in list_Interface:
                    self.bAutoLogin=False
                return list_Interface
            except configparser.NoOptionError:
                raise ValueError(f"未知 runMapType 类型{traceback.format_exc()}")

        # 切换测试环境插件
        if 'env' in dic_args:
            filecontrol_copyFileOrFolder(SERVER_PATH + '/XGame/Interface' + dic_args['env'], TEMP_FOLDER + '/Interface')
        else:
            # filecontrol_copyFileOrFolder(SERVER_PATH + '/XGame/Interface', TEMP_FOLDER + '/Interface')
            copyFolderNames = _getRunMapTypeInterfaceFolderName()  # 获取要拷贝的文件夹名
            s_serverInterfacePath = SERVER_PATH + '/XGame/Interface'
            s_localInterfacePath = TEMP_FOLDER + '/Interface'
            nCopyRetryCnt=3 #拷贝重试机制
            nCopyRetryCounter=0
            for folderName in copyFolderNames:
                # 循环拷贝文件夹
                while True:
                    try:
                        filecontrol_copyFileOrFolder(s_serverInterfacePath + f"/{folderName}",s_localInterfacePath + f"/{folderName}")
                        break
                    except Exception as e:
                        nCopyRetryCounter+=1
                        time.sleep(5)
                        if nCopyRetryCounter==nCopyRetryCnt:
                            #重试3次失败
                            info = traceback.format_exc()
                            raise Exception(f"copy {s_serverInterfacePath+'/'+folderName} to {s_localInterfacePath+'/'+folderName} error:{info}")
        ini_set("Interface", "Type", self.runMapType, TEMP_FOLDER + '/Interface/SearchPanel/Interface.ini')

        #PC端会拉取GM失败 因此需要判断Lua/Debug/GM文件夹中是否有相关文件
        if not self.bMobile:
            filecontrol_copyFileOrFolder(SERVER_PATH+'/XGame/GM',self.CLIENT_PATH+'/mui/Lua/Debug/GM')

        #临时处理GPU设备锁定
        if self.strNumVideoLevel=='1' or self.strNumVideoLevel=='2':
            if filecontrol_existFileOrFolder(self.CLIENT_PATH+r'/mui/Tab'):
                filecontrol_deleteFileOrFolder(self.CLIENT_PATH+r'/mui/Tab')
            #pass
            #filecontrol_copyFileOrFolder(SERVER_PATH + '/XGame/UIDeviceModelRecommendQualityTab.xls', TEMP_FOLDER+os.sep+'UIDeviceModelRecommendQualityTab.xls')
            #filecontrol_copyFileOrFolder(TEMP_FOLDER+os.sep+'UIDeviceModelRecommendQualityTab.xls', self.CLIENT_PATH+r'/mui/Tab/UIDeviceModelRecommendQualityTab.xls', self.deviceId,self.package)
        self.log.info(self.runMapType)

    def processSearchPanelTab(self, dic_args):
        # 兼容手机操作，文件先考到本地临时文件夹处理完毕再推送到目的地
        TEMP_FOLDER = 'TempFolder'
        mapid = str(dic_args['mapid'])
        testpoint = dic_args['testpoint']
        casename = dic_args['casename']

        dic_MapName = self.DIC_MAPNAME
        # 切画质用
        nVideoLevel = int(self.strNumVideoLevel)
            # 'LOW','MID','HIGH'
        list_XGame_Quality = ['LOW', 'MID', 'HIGH','EXTREME_HIGH']
        nVideoLevel = nVideoLevel - 1
        if nVideoLevel == 0:
            nVideoLevel_temp = nVideoLevel + 1
        else:
            nVideoLevel_temp = nVideoLevel - 1
        strVideoLevel = list_XGame_Quality[nVideoLevel]
        strVideoLevel_temp = list_XGame_Quality[nVideoLevel_temp]

        with open(os.path.join(os.path.dirname(os.path.realpath(__file__)),self.MapPathData_path)) as f:
            for line in f:
                list_data = line.replace("\n", "").replace("\r", "").split('\t')
                self.DIC_TrafficInfo[list_data[0]] = (
                    list_data[1], list_data[2], list_data[3], list_data[4], list_data[5])

        # copy用例、更改字段
        #dst = os.path.join(self.SEARCHPANEL_PATH,'RunMap.tab')
        src=os.path.join(SERVER_PATH,'XGame','RunTab',casename)
        TEMP_FOLDER =os.path.join('TempFolder','Interface',self.runMapType)
        tmp = os.path.join(TEMP_FOLDER,'RunMap.tab')

        sChange = []

        #专项
        if '-77' in self.testpoint or '-scence' in self.testpoint:
            srcBody=os.path.join(SERVER_PATH,'XGame','77-Special',mapid)
            tempBody=os.path.join('TempFolder',mapid)
            filecontrol_copyFileOrFolder(srcBody, tempBody)
            srcHead=os.path.join(SERVER_PATH,'XGame','77-Special','77-Special.tab')
            tempHead=os.path.join('TempFolder','77-Special.tab')
            filecontrol_copyFileOrFolder(srcHead, tempHead)
            with open(tempBody, "r", encoding='utf8') as fBody:
                resBody = fBody.read()
                resHead = ''
                with open(tempHead, 'r', encoding='gbk') as fHead:
                    resHead = fHead.read()
                    nMapPointLen = len(resBody.split('\n'))
                    nRunMapCount=round(400/nMapPointLen)
                    #秘境地图一定时间会强制退出
                    list_map=['143','144','145','146','147','446']
                    if mapid in list_map:
                        nRunMapCount=2
                    if nRunMapCount>=2:
                        nRunMapCount=2
                    else:
                        nRunMapCount=1
                    if nRunMapCount > 1:
                        strSetRunMapCount = f'/cmd CustomRunMap.SetRunMapCount({nRunMapCount})	1	设置跑图来回次数\n'
                        strReplace = '/cmd CreateEmptyFile("CustomRunMap_start")	2	开启跑图\n'
                        resHead = resHead.replace(strReplace,strSetRunMapCount+strReplace)
                    resHead = resHead.replace('x	y	z	stay	mapid	action\n', resBody)
                    list_pos = resBody.split('\n')[1].split('\t')
                    sChange.append(['_X_', list_pos[0]])
                    sChange.append(['_Y_', list_pos[1]])
                    sChange.append(['_Z_', list_pos[2]])
                with open(tempHead, 'w', encoding='gbk') as fHead:
                    fHead.write(resHead)

            filecontrol_copyFileOrFolder(tempHead, tmp)
        else:
            nCnt=0
            #如果有RunMap.tab文件则不需要再拷贝
            while not filecontrol_existFileOrFolder(tmp):
                try:
                    filecontrol_copyFileOrFolder(src, tmp)
                    break
                except Exception as e:
                    info = traceback.format_exc()
                    self.log.info(info)
                    time.sleep(1)
                    nCnt+=1
                    if nCnt>=3:
                        raise Exception(info)
                        break

        #if 'postion' in dic_args:

        #副本切图需要传入Index
        strMapIndex=None
        if 'mapIndex' in dic_args:
            strMapIndex=str(dic_args['mapIndex'])
        else:
            strMapType=self.DIC_MAPTYPE[mapid]
            if strMapType=='0' or strMapType=='3' or strMapType=='5':
                #场景地图
                strMapIndex='1'
            elif strMapType=='4':
                #帮会地图
                strMapIndex = 'player.dwTongID'
            else:
                #副本等地图
                #strMapIndex='1'
                strMapIndex = 'player.dwID'


        sChange.append(['_mapIndex_', strMapIndex])
        sChange.append(['_mapid_', mapid])  # autofly里还有填
        # sChange.append(['_testpoint_', testpoint])
        sChange.append(['_mapname_', dic_MapName[mapid]])
        sChange.append(['_video_', strVideoLevel_temp])
        sChange.append(['_video1_', strVideoLevel])
        sChange.append(['_classicVideoLevel_', strVideoLevel])
        sChange.append(['_classicVideoLevel2_', strVideoLevel_temp])
        # sChange.append(['_date_', date_get_szToday_7()])  # today7

        if ('autofly' in testpoint) and (mapid != '1'):
            trafficID1, trafficID2, X, Y, Z = self.DIC_TrafficInfo[mapid]
            sChange.append(['_flyTime_', str(self.FLY_TIME)])
            sChange.append(['_trafficID1_', trafficID1])
            sChange.append(['_trafficID2_', trafficID2])
            sChange.append(['_X_', X])
            sChange.append(['_Y_', Y])
            sChange.append(['_Z_', Z])

        if 'multi' in testpoint:
            sChange.append(['-pid-', str(dic_args['m_pid'])])
            sChange.append(['-startID-', str(dic_args['m_index'])])

        for each_yield in sChange:
            changeStrInFile(tmp, each_yield[0], each_yield[1])

        # 跑图通用CMD命令
        list_runMapType = ["WalkExterior", "BasicRunMap", "CustomRunMap", "ShopErgodicTDR", "ShopErgodic",
                           "UITraversal", "SwitchMap","FiveSecretRealm","FlySkill","Dungeons","HotPointRunMap","HotPointRunMapOneDepth","ArenaPvP"]
        if self.runMapType in list_runMapType:
            #'/cmd UINodeControl.BtnTriggerByLable("BtnClose","跳过当前教学")	3	关闭新手教程面板',
            #设置固定视角 保证新老账号初始视角一致
            strHead = '/cmd CreateEmptyFile("BeginRunMap")	20	开始跑图\n'
            if self.bRandomAcount:
                list_info = ["/cmd UIMgr.Close(VIEW_ID.PanelHotSpotBanner)	5	首次下载游戏会出现这个弹窗",
                             "/cmd UIMgr.Close(VIEW_ID.PanelHintSelectMode)	2	操作模式",
                             "/cmd PlayerLevelUpToNew(130)	40	升级",
                             "/cmd UIMgr.Close(1705)	2	关闭升级弹窗",
                             "/cmd UIMgr.Close(1701)	2	关闭升级弹窗",
                             "/cmd UIMgr.Close(VIEW_ID.Panel130NightPop)	2	关闭升级弹窗",
                             "/cmd SetCameraStatus(1083,1,2.2,-0.1369)	1	初始化视角",
                             "/gm player.AddBuff(player.dwID,player.nLevel,3994,1,3600)	2	加隐身"]
            else:
                list_info = ["/cmd UIMgr.Close(VIEW_ID.PanelHotSpotBanner)	5	首次下载游戏会出现这个弹窗",
                             "/cmd UIMgr.Close(VIEW_ID.PanelHintSelectMode)	2	操作模式",
                             "/cmd SetCameraStatus(1083,1,2.2,-0.1369)	1	初始化视角",
                             "/gm player.AddBuff(player.dwID,player.nLevel,3994,1,3600)	2	加隐身"]
            #帮会地图特殊处理
            if mapid =='74':
                list_info.append("/gm player.AddMoney(10000,0,0)	1	加钱")
                list_info.append("/gm ApplyCreateTong(player.dwID,player.szName)	3	创建帮会")
            strInfo = strHead
            for info in list_info:
                strInfo = strInfo + info + '\n'
            changeStrInFile(tmp, strHead, strInfo)



    def GetAutoTestLog(self):
        pass

    def teardown(self):
        self.bRunMapEnd = True
        self.log.info(f'CaseJX3SearchPanel_teardown start')
        #释放宕机检测模块
        if self.module_CrashReport:
            self.module_CrashReport.ReleaseSource()
        #结束SDK
        if hasattr(self, 'SocketClient') and self.SocketClient:
            self.SocketClient.SDK_Stop()
        super().teardown()
        if not self.bMobile:
            win32_kill_process('DumpReport64.exe')
            win32_kill_process('WerFault.exe')
            win32_kill_process('PerformanceTool.exe')
            win32_kill_process('PerfMon.exe')
            win32_kill_process('IDLE_TASK_BVT.exe')
        self.log.info('testplus.kill node1')

        if hasattr(self, 'perfeye') and self.perfeye:
            self.log.info('testplus.kill node2')
            #self.testplus.kill()
            '''
            try:
                self.perfeye.PerfeyeStop()
                subtags = '{0}|{1}|{2}|{3}|{4}|{5}'.format(self.tagVideoLevel, self.tagMachineType, self.tagVideoCard,
                                                           self.mapname, self.testpoint, date_get_szToday())
                self.perfeye.PerfeyeSave(subtags=subtags,BVT=False)
            except:
                pass
            '''
            self.perfeye.PerfeyeKill()
            #此处容易阻塞
            self.log.info('testplus.kill node3')
        # 拷贝用例日志到共享
        self.Upload_Caselogs(self.strCaseName, self.strMachineName)
        self.log.info(f'CaseJX3SearchPanel_teardown end')

    def check_dic_args(self, dic_args):

        super().check_dic_args(dic_args)
        self.testpoint = dic_args['testpoint']
        #页面参数超时时间
        self.nClientRunTimeOut = int(dic_args['nTimeout'])
        #页面参数超时时间+启动app前自动化准备环境的时间
        self.nTaskTimeOut=0

        #地图ID
        self.strMapId = str(dic_args['mapid'])

        # 获取地图配置表
        self.mapname = self.DIC_MAPNAME[self.strMapId]
        # casename tab文件名称
        dic_args['casename'] = gbk(dic_args['casename'])

        self.log.info(f'用例: {self.strCaseName}')
        dic_args['Switch'] = 1
        #跑图的插件类型
        self.runMapType = dic_args['runmaptype']
        #用例指定冷机温度
        if 'nTemperature' in dic_args:
            self.nTemperature=int(dic_args['nTemperature'])

        if 'optick' in dic_args:
            self.bCaptureOptick=bool(dic_args['optick'])
            self.log.info(f"bCaptureOptick:{self.bCaptureOptick}")

    def add_thread_for_searchPanel(self, dicSwitch):
        if not self.bMobile:
            # perfeye线程
            t = threading.Thread(target=self.thread_SearchPanelPerfEyeCtrl,
                                 args=(dicSwitch, threading.currentThread(),))
            self.listThreads_beforeStartClient.append(t)

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
        else:
            #perfeye线程
            t = threading.Thread(target=self.thread_SearchPanelPerfEyeCtrl,
                                 args=(dicSwitch, threading.currentThread(),))
            self.listThreads_beforeStartClient.append(t)
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
            #处理设备弹窗
            #t = threading.Thread(target=self.mobile_device.thread_DealWithMobileWindow,
                                 #args=(threading.currentThread(),))
            #self.listThreads_beforeStartClient.append(t)


    def processWindows(self):
        #PC端需要设置全屏
        if not self.bMobile:
            strLocalPath=os.path.join(self.CLIENT_PATH,'config.ini')
            ini_set('Mobile', 'bMaximize', 1, strLocalPath)
            '''
            try:
                iniFile = self.pathLocalConfig
                window_info = 'window_info_hd'
                if 'classic' in self.clientType:
                    window_info = 'window_info_classic'
                if window_info not in ini_getSections(iniFile):
                    return
                listOptions = ini_getOptions(window_info, iniFile)
                windowConfigPath = self.CLIENT_PATH + r'/config.ini'
                for option in listOptions:
                    value = ini_get(window_info, option, iniFile)
                    ini_set('Main', option, value, windowConfigPath)
            except Exception as e:
                info = traceback.format_exc()
                self.log.error(info)'''

    def task_process_data(self):

        if not hasattr(self, 'perfeye'):
            return
        # tags = '档次|机型|配置|地图|测试点|日期'
        subtags = '{0}|{1}|{2}|{3}|{4}|{5}'.format(self.tagVideoLevel, self.tagMachineType, self.tagVideoCard,self.mapname, self.testpoint, date_get_szToday())
        self.log.info('task_process_data start')

        # 冷机时间
        nSleepMinute = self.countDeviceSleepTime()

        # with open(szTempData, 'r') as f:
        # dic_extraData = json.loads(f.read())
        dic_extraData = {}
        if self.SocketClient:
            dic_extraData = self.SocketClient.dic_dataList
        # logger.info(dic_extraData)
        try:
            nErrorshaderCount = self.SocketClient.dic_dataList["datalist"][-1]["CustomDataFloat"][
                                    "uiAllErrorShaderCnt"] + \
                                self.SocketClient.dic_dataList["datalist"][-1]["CustomDataFloat"][
                                    "uiAllMissingMaterialDefCount"]
            strDate = time.strftime(f"%Y_%m_%d", time.localtime())
            if not self.strClientLog and filecontrol_existFileOrFolder(self.CLIENT_LOG_PATH+'/'+strDate):
                # 结束游戏客户端后,获取日志到本地

                self.strClientLog = filecontrol_getFolderLastestFile(os.path.join(self.CLIENT_LOG_PATH, strDate),
                                                                     'TempFolder', self.deviceId, self.package)
                # ios获取日志是异步的因此需要等待拷贝完成 超时5秒
                nTimeOut = 5
                nTimer = 0
                while not filecontrol_existFileOrFolder(self.strClientLog):
                    time.sleep(1)
                    nTimer += 1
                    if nTimer > nTimeOut:
                        break
                self.creatFolderByShader(int(nErrorshaderCount), self.strClientLog, self.strClientScreen,self.strCaseName, self.strMachineName)

        except Exception:
            info = traceback.format_exc()
            dic_extraData = {}
            self.log.info(info)
            pass

        bRetXGameUploadData = False
        nMaxRetransmissionCount = 3  # 默认数据重传次数
        if self.bDumpCase:
            # 宕机用例数据不用重传
            nMaxRetransmissionCount = 2
        bRetXGameUploadData = self.perfeye.PerfeyeSave(subtags=subtags, extraData=dic_extraData,nMaxRetransmissionCount=nMaxRetransmissionCount,strVersion=self.GetVersion())

        if self.bCaptureOptick:
            strServerPath=f'{SERVER_PATH}{STRSEPARATOR}OptickData'
            strCaseName = self.strCaseName.replace('|', '-')
            strDst = f"{strServerPath}\{date_get_szToday()}\{self.strMachineName}\{strCaseName}"
            strDst = sort_filePath(strDst)
            if not filecontrol_existFileOrFolder(strDst):
                filecontrol_createFolder(strDst)

            return

        if not bRetXGameUploadData:
            # 如果是预跑任务就默认当然任务执行成功  如果不是等待十分钟手机冷却后再重启当前任务
            pass
            '''
            if 'ahead-run' not in self.testpoint and not self.bDumpCase:
                nExceptionType = ExceptionMsg.PERF_UPLOADERROR
                strMsg = f'保存数据失败,上传数据失败，机器: {self.strMachineName} 用例: {self.strCaseName} {nSleepMinute}分钟后重启'
                self.queue_ExceptionMsg.put(
                    {'exceptionType': nExceptionType, 'msg': strMsg})'''

        # 冷机
        if not self.bDumpCase and not 'dump' in self.testpoint.lower() and 'Dump' not in self.strCaseName:
            self.device_cooling()

        #if 'ahead-run' in self.testpoint or '-77' in self.testpoint or '-scence' in self.testpoint or '抽帧' in self.testpoint:
            #if self.bMobile:
                #sleep_heartbeat(nSleepMinute)

    def task_mobile(self):

        self.nTaskTimeOut= self.nClientRunTimeOut + int(time.time() - self.nStartTimeSeconds)
        self.log.info(f"nTaskTimeOut:{self.nTaskTimeOut}")
        self.log.info('mobile wait start')
        nCount=0
        while 1:
            nCount+=1
            time.sleep(1)
            if nCount>120:
                self.log.info("task_mobile heart")
                nCount=0
            if self.checkRecvInfoFromSearchpanel('ExitGame') or self.bExitGameFlag:
                # 关闭app
                self.log.info(f'bRunMapEnd:{self.bRunMapEnd}')
                self.bRunMapEnd=True
                #app结束前获取截图
                if not self.strClientScreen:
                    try:
                        strScreenShotPath = os.path.join('TempFolder', 'RunMapEndScene.png')
                        self.strClientScreen =self.Client_ScreenShot(strScreenShotPath)
                    except:
                        #避免因为截图失败 导致用例不能正常执行
                        pass
                #mobile_kill_app(self.package,self.deviceId)
                self.Client_Kill()
                break
        self.log.info('mobile wait end')


    def copyEnvToClient(self):
        TEMP_FOLDER='TempFolder'
        # 导入LoginMgr.lua到游戏客户端
        filecontrol_copyFileOrFolder(SERVER_PATH + '/XGame/LoginMgr.lua', TEMP_FOLDER + os.sep + 'LoginMgr.lua')
        filecontrol_copyFileOrFolder(TEMP_FOLDER + os.sep + 'LoginMgr.lua',self.CLIENT_PATH + '/mui/Lua/Logic/Login/LoginMgr.lua', self.deviceId,self.package)

        # XGame拷贝Interface文件夹
        filecontrol_copyFileOrFolder(os.path.join('TempFolder', 'Interface'), self.INTERFACE_PATH, self.deviceId,self.package)
        #临时挂包外打开商城
        #filecontrol_copyFileOrFolder(SERVER_PATH + '/XGame/AppReviewMgr.lua',self.CLIENT_PATH + '/mui/Lua/Logic/AppReviewMgr.lua', self.deviceId,self.package)
        #删除临时挂包外文件
        #filecontrol_deleteFileOrFolder(self.CLIENT_PATH + '/mui/Lua/Logic/AppReviewMgr.lua', self.deviceId,self.package)

        #临时删除 CachedShaders_mb文件夹
        #filecontrol_deleteFileOrFolder(self.CLIENT_PATH + '/CachedShaders_mb', self.deviceId,self.package)


    def run_local(self, dic_args):
        # 2022-4-21 7zip安全漏洞 临时处理
        def deleteZipChm():
            try:
                path = r'C:\Program Files\7-Zip\7-zip.chm'
                if os.path.exists(path):
                    os.remove(path)
                    info = '7-Zip chm removed successfully'
                    self.log.info(info)
                else:
                    pass
            except Exception:
                pass

        deleteZipChm()
        self.check_dic_args(dic_args)  # 处理传进来的参数
        self.loadDataFromLocalConfig(dic_args)  # 读LocalConfig配置
        self.clearInfoFiles()  # 清空客户端向本用例通信的信息文件
        self.processInterface(dic_args)  # 处理插件
        self.OpenAutoLogin(dic_args)  # 自动登录
        self.preRunToKillExe()  # 运行前清理之前没有关闭的相关程序
        self.processServerlist(dic_args)  # 处理serverlist
        self.processResoucre(dic_args)  #处理pakv5资源相关
        self.processSearchPanelTab(dic_args)  # 处理运行所需的RunMap.tab
        self.copyEnvToClient()  #拷贝插件环境到Client
        self.processWindows()
        self.add_thread_for_searchPanel(dic_args)
        self.copyPerfeye()
        self.process_threads_beforeStartClient()
        self.start_client_test(dic_args)
        self.task_mobile()
        self.task_process_data()
        # while win32_findProcessByName('PerfReporterX86.exe'):
        #     print ('wait for PerfReporterX86 closed')
        #     time.sleep(1)

if __name__ == '__main__':
    obj_test = CaseJX3SearchPanel()
    obj_test.run_from_IQB()

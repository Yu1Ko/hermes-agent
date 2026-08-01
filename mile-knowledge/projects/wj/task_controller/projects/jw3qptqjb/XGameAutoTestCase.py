# -*- coding: utf-8 -*-
import os
import time
from CaseJX3Client import *
from PerfeyeCtrl import *
from HotPointMapCtrl import *
#from PerfMonCtrl import *
from XGameSocketClient import *
from mobile_device_controller import *
class XGameAutoTestCase(CaseJX3Client):

    def __init__(self):
        super().__init__()
        # CtrlPerfMon.__init__(self)
        self.FLY_TIME = 600
        self.DIC_MAPNAME = {}
        with open(os.path.join(os.path.dirname(os.path.realpath(__file__)),'MapList.tab'),encoding='gbk') as f:
            for line in f:
                list_data = line.split('\t')
                if list_data[0] == 'ID':
                    continue  # 第一行跳过
                self.DIC_MAPNAME[list_data[0]] = utf8(list_data[1])
        self.DIC_MAPNAME_CLASSIC = {}
        with open(os.path.join(os.path.dirname(os.path.realpath(__file__)),'MapList_classic.tab'),encoding='gbk') as f:
            for line in f:
                list_data = line.split('\t')
                if list_data[0] == 'ID':
                    continue  # 第一行跳过
                self.DIC_MAPNAME_CLASSIC[list_data[0]] = utf8(list_data[1])
        self.DIC_TrafficInfo = {}
        self.MapPathData_path = 'MapPathData.tab'
        self.bRunMapEnd=False
        self.bSDKIniFlag = False
        self.queue_ExceptionMsg = queue.Queue(maxsize=10)




    def preRunToKillExe(self):
        win32_kill_process('DumpReport64.exe')
        win32_kill_process('WerFault.exe')
        win32_kill_process('PerformanceTool.exe')
        win32_kill_process('PerfMon.exe')
        # win32_kill_process('Perfeye.exe')
        win32_kill_process(self.exename)

    def clearInfoFiles(self):
        super().clearInfoFiles()
        # XGame项目在插件中会自动清除用例文件
        listFilesName = ['perfeye_start', 'perfeye_stop', 'perfeye_ready', 'perfeye', 'BeginRunMap', 'ExitGame',
                         'trewq.qwe']
        for fileName in listFilesName:
            if 'XGame' in self.clientType:
                strBasePath = self.CLIENT_PATH + LOCAL_INFO_FILE
                uFilepath = os.path.join(strBasePath, fileName)
            else:
                strBasePath = 'C:' + LOCAL_INFO_FILE
                uFilepath = os.path.join(strBasePath, fileName)
            logger.info("clear:" + uFilepath)
            filecontrol_deleteFileOrFolder(uFilepath, self.deviceId,self.package)
        # 清除TempFolder文件夹
        filecontrol_deleteFileOrFolder('TempFolder')
        # 创建通信文件夹
        if not filecontrol_existFileOrFolder(strBasePath, self.deviceId,self.package):
            filecontrol_createFolder(strBasePath, self.deviceId,self.package)

    def checkRecvInfoFromSearchpanel(self, fileName):
        if 'XGame' in self.clientType:
            uFilepath = os.path.join(self.CLIENT_PATH + LOCAL_INFO_FILE, fileName)
        else:
            uFilepath = os.path.join('C:' + LOCAL_INFO_FILE, fileName)
        if filecontrol_existFileOrFolder(uFilepath, self.deviceId,self.package):
            self.log.info(u"find: {}".format(uFilepath))
            filecontrol_deleteFileOrFolder(uFilepath, self.deviceId,self.package)
            return True
        return False

    def thread_SearchPanelPerfEyeCtrl(self, dicSwitch, t_parent):
        self.log.info("thread_SearchPanelPerfEyeCtrl start")
        self.bPerfStart=False
        self.bPerfStop=False
        try:
            if 'NoPerf' in dicSwitch:
                self.log.info("PerfMon NoPerf and thread_SearchPanelPerfEyeCtrl stop")
                return

            # pefeye标志
            if not self.bMobile:
                if not filecontrol_existFileOrFolder(r'C:\RunMapResult'):
                    filecontrol_createFolder('C:\RunMapResult')
                file = open(r'C:\RunMapResult\perfeye', 'w')
                file.close()

            self.testplus = PerfeyeCreate()
            PerfeyeConnect(self.testplus, self.deviceId,self.package)
            while not self.clientPID or not self.bSDKIniFlag:
                time.sleep(2)

            #self.SocketClient=XGameSocketClient(os.path.join(os.getcwd(),'SocketClientDLL.dll'),mobile_get_address(self.deviceId),1112)
            # 手游端游
            if self.bMobile:
                #android端 部分机器重启后会有miniperf.app弹窗
                PerfeyeStartMobile(self.testplus, self.deviceId, self.package, self.screenshot_interval)
                logger.info("perfeye_startTime:"+str(time.time()))
            else:
                time.sleep(60)
                PerfeyeStart(self.testplus, self.deviceId, self.clientPID, self.screenshot_interval)
            # 与client建立链接
            self.SDK.PerfDataCreate()
            # 与开始采集数据
            self.SDK.PerfDataStart()

            nTimer=0
            while t_parent.is_alive():
                time.sleep(0.1)
                nTimer += 0.1
                if nTimer > 120:
                    self.log.info('SearchPanelPerfEyeCtrl heart')
                    nTimer = 0
                if self.bPerfStart:
                    self.bPerfStart=False
                    if not self.bMobile:
                        vnc_disconnectall()
                    PerfeyeSetTimeNode(self.testplus, self.deviceId)
                    self.SDK.PerfDataSetTimeNode()
                    logger.info("perfeye_SetTimeNodeTime:")
                if self.bPerfStop:
                    self.bPerfStop=False
                    logger.info("perfeye_StopTime:")
                    PerfeyeStop(self.testplus, self.deviceId)
                    self.SDK.PerfDataStop()
                    #结束采集数据线程
                    break
            self.log.info("thread_SearchPanelPerfEyeCtrl stop")
        except Exception as e:
            info = traceback.format_exc()
            self.log.error(info)
            strMsg = f'{info}，机器: {self.strMachineName} 用例: {self.strCaseName}重启'
            self.log.info(f'bRunMapEnd:{self.bRunMapEnd}')
            self.bRunMapEnd = True
            nExceptionType = ExceptionMsg.PERF_NETERROR
            self.queue_ExceptionMsg.put({'exceptionType': nExceptionType, 'msg': strMsg})

    def thread_CheckTaskTimeOut(self, dicSwitch, t_parent):
        self.log.info("CheckTaskTimeOut start")
        # 放入消息队列的消息内容
        strMsg = ''
        nExceptionType = 0
        strScreenShotPath = os.path.join('TempFolder','TaskTimeOutScene.png')
        nTimerOut=self.nClientRunTimeOut
        nTimer=0
        if not self.bMobile:
            return
        self.log.info(f'超时时间:{nTimerOut}')
        while t_parent.is_alive():
            #10秒检查一次用例是否超时
            time.sleep(10)
            if self.clientPID != 'mobile':
                continue
            if self.bRunMapEnd:
                self.log.info("thread_CheckTaskTimeOut exit")
                break
            #app启动后开始计时
            nTimer += 10
            if nTimer%120==0:
                self.log.info('CheckTaskTimeOut heart')
            if nTimer > nTimerOut:
                self.log.info(f'bRunMapEnd:{self.bRunMapEnd}')
                self.bRunMapEnd=True
                #mobile_screemshot(strScreenShotPath, self.deviceId)
                self.mobile_device.screenshot2(strScreenShotPath)
                #超时检查 一定发生在app运行状态
                strMsg=f'{self.strMachineName}: %s 分钟还未结束跑图用例: {self.strCaseName}，用例异常，需要查看'
                nExceptionType=ExceptionMsg.TASKTIMEOUT
                #防止通知等待时间过长 app长时间运行导致手机发热
                self.mobile_device.kill_app()
                #mobile_kill_app(self.package, self.deviceId)
                self.queue_ExceptionMsg.put({'exceptionType': nExceptionType, 'msg': strMsg, 'screenshotPath': strScreenShotPath})
                self.log.info(strMsg%(self.nTaskTimeOut//60)+": 用例超时检查线程退出 ")
                break


    def thread_CheckAppRunStateAndCrash(self, dicSwitch, t_parent):
        if not self.bMobile:
            return
        self.log.info("thread_CheckAppRunStateAndCrash start")

        #放入消息队列的消息内容
        strMsg=''
        nExceptionType=0
        strScreenShotPath = os.path.join('TempFolder', 'CrashScene.png')
        nTimer=0
        while t_parent.is_alive():
            #10秒检查一次宕机
            time.sleep(10)
            if self.clientPID != 'mobile':
                continue
            if self.bRunMapEnd:
                self.log.info("thread_CheckAppRunStateAndCrash exit")
                break
            nTimer+=10
            if nTimer>120:
                self.log.info('CheckAppRunStateAndCrash heart')
                nTimer=0
            #app停止运行
            #if not mobile_determine_runapp(self.package, self.deviceId):
            if not self.mobile_device.determine_runapp():
                #检查是否发生宕机
                #if mobile_check_crash(self.package, self.deviceId):
                if self.mobile_device.check_crash():
                    nExceptionType=ExceptionMsg.CRASH
                    strMsg=f'{self.strMachineName}:用例: {self.strCaseName}，已经宕机，需要查看现场'
                else:
                    strMsg=f'{self.strMachineName}:用例: {self.strCaseName}，已经闪退，需要查看现场'
                    nExceptionType = ExceptionMsg.FLASHBACK
                self.log.info(f'bRunMapEnd:{self.bRunMapEnd}')
                self.bRunMapEnd = True
                #mobile_switch_background(self.deviceId, strScreenShotPath)
                self.mobile_device.switch_background(strScreenShotPath)
                self.log.info(strMsg+": 宕机检查线程退出 ")
                self.queue_ExceptionMsg.put({'exceptionType': nExceptionType, 'msg':strMsg,'screenshotPath':strScreenShotPath})
                break

    def thread_DealWith_ExceptionMsg(self, dicSwitch, t_parent):
        self.log.info('thread_DealWith_ExceptionMsg start')
        strMsg=''
        #采用消息队列统一处理用例异常消息  只处理第一条消息
        #消息类型:dic  必填： "exceptionType":1,'msg':发生宕机, 'screenshotPath':/TempFolder/test.png ，'sleepMinite' 睡眠多少分钟
        nTimer=0
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
            #检查消息格式
            if not('exceptionType' in dic_msg and 'msg' in dic_msg):
                strMsg='消息格式错误，请检查消息格式'
                self.log.info("检查消息格式")
                break
            nEType=dic_msg['exceptionType']
            strMsg=dic_msg['msg']
            bResetFlag=False
            #非工作时间只通知一次
            nSendCount = 3
            if 'Ios' in self.clientType:
                nSendCount=1
            if nEType==ExceptionMsg.CRASH:
                #宕机 通知3次后没人处理 默认跳过当前用例
                #nSendCount=3
                if not is_workTime():
                    nSendCount=1
                for n in range(1, nSendCount + 1):
                    strAppendMsg = f": 第{n}通知"
                    if n == nSendCount:
                        strAppendMsg = f": 第{n}通知 无人处理 默认跳过当前用例"
                    send_Subscriber_msg(machine_get_guid(), strMsg + strAppendMsg, dic_msg['screenshotPath'])
                    # 每隔5分钟通知一次
                    sleep_heartbeat(5)
            elif nEType==ExceptionMsg.FLASHBACK:
                #闪退 通知3次后没人处理 默认跳过当前用例
                #nSendCount=3
                if not is_workTime():
                    nSendCount=1
                for n in range(1, nSendCount + 1):
                    strAppendMsg = f": 第{n}通知"
                    if n == nSendCount:
                        strAppendMsg = f": 第{n}通知 无人处理 默认跳过当前用例"
                    send_Subscriber_msg(machine_get_guid(), strMsg + strAppendMsg, dic_msg['screenshotPath'])
                    self.log.info(strMsg + strAppendMsg)
                    # 每隔5分钟通知一次
                    sleep_heartbeat(5)
            elif nEType==ExceptionMsg.TASKTIMEOUT:
                #用例超时 通知3次后没人处理 默认跳过当前用例
                #nSendCount=3
                nWaitMinite=5
                for n in range(1, nSendCount + 1):
                    strAppendMsg = f": 第{n}通知"
                    strTemp = strMsg % (self.nTaskTimeOut//60 +nWaitMinite*(n-1))
                    if n == nSendCount:
                        strAppendMsg = f": 第{n}通知 无人处理 默认跳过当前用例"
                    send_Subscriber_msg(machine_get_guid(), strTemp + strAppendMsg, dic_msg['screenshotPath'])
                    self.log.info(strTemp + strAppendMsg)
                    # 每隔5分钟通知一次
                    sleep_heartbeat(nWaitMinite)
            elif nEType==ExceptionMsg.PERF_NETERROR:
                #perfeye网络错误 立即重启用例
                send_Subscriber_msg(machine_get_guid(),strMsg )
                bResetFlag=True
            elif nEType==ExceptionMsg.PERF_UPLOADERROR:
                #perfeye保存数据失败 冷机dic_msg['sleepMinite']分钟后 重启用例
                send_Subscriber_msg(machine_get_guid(),strMsg)
                sleep_heartbeat(dic_msg['sleepMinite'])
                bResetFlag = True

            #安全退出
            self.log.info(f'异常消息无人处理 跳过当前用例: {dic_msg}')
            self.teardown()
            #重启或者跳过
            if bResetFlag:
                self.task_reset()
            else:
                self.task_run_next()
            break
        self.log.info('thread_DealWith_ExceptionMsg Eixt')


    def thread_KillDeath(self, dicSwitch, t_parent, timeout):
        try:
            caseName = dicSwitch['CaseName']
            guid = machine_get_guid()
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
                    send_Subscriber_msg(guid, strNotice)
                    if hasattr(self, 'needKillDeath') and self.needKillDeath == True:
                        break
                    nTimeout = nTimeout + 5 * 60
                if elapseTime >= nSearchpanelCheckTime and not bBeginRunMap:  # 条件2：客户端开启一段时间后还没开始跑searchpanel
                    strNotice = '[func:KillDeath]{} searchpanel not start in {}分钟'.format(caseName,
                                                                                          nSearchpanelCheckTime / 60)
                    send_Subscriber_msg(guid, strNotice)
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
                    send_Subscriber_msg(guid, strNotice)
                    nNotNewLogTime = nNotNewLogTime + 5 * 60

            info = '{} runtime is {}s'.format(caseName, str(elapseTime))
            self.log.info(info)
            if elapseTime > timeout:
                info = u'{} runtime is {}s, overtime is {}s'.format(caseName, str(elapseTime),
                                                                    str(elapseTime - timeout))
                send_Subscriber_msg(guid, info)
            if hasattr(self, 'needKillDeath') and self.needKillDeath == True:
                win32_kill_process(self.exename)
        except Exception:
            info = traceback.format_exc()
            self.log.error(info)

    def thread_SearchPanelClientExit(self, dicSwitch, t_parent):
        try:
            while t_parent.is_alive():
                time.sleep(1)
                if self.checkRecvInfoFromSearchpanel('ExitGame'):
                    win32_kill_process(self.exename)
        except Exception as e:
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


    def processServerlist(self, dic_args):
        if 'XGame' in self.clientType:
            TEMP_FOLDER = 'TempFolder'
            filecontrol_copyFileOrFolder(SERVER_PATH + '/XGame/serverlist_m.tab',
                                         TEMP_FOLDER + '/serverlist_m.tab')
            filecontrol_copyFileOrFolder(TEMP_FOLDER + '/serverlist_m.tab',
                                         self.SERVERLIST_PATH + '/serverlist_m.tab', self.deviceId,self.package)
            if 'XGame_PC' in self.clientType:
                # XGame_PC端需解除帧率限制
                strClientConfigPath = self.CLIENT_PATH + r'/config.ini'
                ini_set('Main', 'FreeFrame', 1, strClientConfigPath)
                # if self.runMapType=='HotPointRunMap':
                # ini_set('Main', 'FreeFrame', 1, strClientConfigPath)
                # else:
                # ini_set('Main', 'FreeFrame', 0, strClientConfigPath)
                # 处理Serverlist
            return

        if self.bEXP:
            self.noteSvrlistInVersionCFG()
        if 'classic' in self.clientType:
            src = SERVER_PATH + "\\" + 'serverlist_classic.ini'
        else:  # 重制版
            # 处理serverlist
            testpoint = dic_args['testpoint']
            src = SERVER_PATH + "\\" + 'serverlist.ini'
            if 'autofly' in testpoint:
                src = SERVER_PATH + "\\" + 'serverlist2.ini'
        dst = self.SERVERLIST_PATH + r'\serverlist.ini'
        filecontrol_copyFileOrFolder(src, dst)
        if 'serverlist' in dic_args:
            szIp = dic_args['serverlist']
            changeStrInFile(dst, '10.11.68.11', szIp)
            changeStrInFile(dst, '10.11.85.6', szIp)

    def processInterface(self, dic_args):
        #只有本地路径需要考虑操作系统  server端和游戏client端 用/
        # 拷贝Interface文件夹
        TEMP_FOLDER = 'TempFolder'

        # 切换测试环境插件
        strLocalPath = os.path.join(TEMP_FOLDER, 'AutoTest')
        if not os.path.exists(strLocalPath):
            os.makedirs(strLocalPath)

        self.INTERFACE_PATH = self.CLIENT_PATH + r'/mui/Lua/AutoTest'
        # 删除游戏client插件环境
        filecontrol_deleteFileOrFolder(self.INTERFACE_PATH, self.deviceId, self.package)

        # Server端 拷贝到 Local端
        if 'env' in dic_args:
            filecontrol_copyFileOrFolder(SERVER_PATH + f'/XGame/AutoTest' + dic_args['env'], strLocalPath)
        else:
            filecontrol_copyFileOrFolder(SERVER_PATH + '/XGame/AutoTest', strLocalPath)

        # Local端 拷贝到 游戏Client端
        filecontrol_copyFileOrFolder(strLocalPath, self.INTERFACE_PATH, self.deviceId,self.package)
        # 兼容手机操作，文件先考到本地临时文件夹处理完毕再推送到目的地
        strLocalPath = os.path.join(TEMP_FOLDER, "LoginMgr.lua")
        filecontrol_copyFileOrFolder(os.path.join(SERVER_PATH, "XGame", "LoginMgrNew.lua"), strLocalPath)
        filecontrol_copyFileOrFolder(strLocalPath, self.CLIENT_PATH +os.sep+'mui/Lua/Logic/Login/LoginMgr.lua',self.deviceId, self.package)


    def processSearchPanelTab(self, dic_args):
        # 兼容手机操作，文件先考到本地临时文件夹处理完毕再推送到目的地
        TEMP_FOLDER = 'TempFolder'
        mapid = str(dic_args['mapid'])
        testpoint = dic_args['testpoint']
        casename = dic_args['casename']

        dic_MapName = self.DIC_MAPNAME
        # 切画质用
        nVideoLevel = int(self.strNumVideoLevel)
        if 'classic' in self.clientType:  # 怀旧版专用
            self.MapPathData_path = 'MapPathData_classic.tab'
            dic_MapName = self.DIC_MAPNAME_CLASSIC
            if nVideoLevel == 3:
                nVideoLevel_temp = nVideoLevel + 1
            else:
                nVideoLevel_temp = nVideoLevel - 1
            strVideoLevel = str(nVideoLevel)
            strVideoLevel_temp = str(nVideoLevel_temp)
        elif 'XGame' in self.clientType:  # 旗舰版专用
            # 'LOW','MID','HIGH'
            list_XGame_Quality = ['LOW', 'MID', 'HIGH']
            nVideoLevel = nVideoLevel - 1
            if nVideoLevel == 0:
                nVideoLevel_temp = nVideoLevel + 1
            else:
                nVideoLevel_temp = nVideoLevel - 1
            strVideoLevel = list_XGame_Quality[nVideoLevel]
            strVideoLevel_temp = list_XGame_Quality[nVideoLevel_temp]
        else:  # 重制版
            if nVideoLevel == 8:
                nVideoLevel_temp = nVideoLevel - 1
            elif nVideoLevel == 10:
                nVideoLevel_temp = 8
            else:
                nVideoLevel_temp = nVideoLevel + 1
            strVideoLevel = str(nVideoLevel)
            strVideoLevel_temp = str(nVideoLevel_temp)

        with open(os.path.join(os.path.dirname(os.path.realpath(__file__)),self.MapPathData_path)) as f:
            for line in f:
                list_data = line.replace("\n", "").replace("\r", "").split('\t')
                self.DIC_TrafficInfo[list_data[0]] = (
                    list_data[1], list_data[2], list_data[3], list_data[4], list_data[5])

        # 打开searchpanel开关 # 2022-5-19 张强提交了开关，默认打开了（移植版），不需要自动化处理了。
        # filecontrol_copyFileOrFolder(self.SEARCHPANEL_PATH + '/info.ini', TEMP_FOLDER + '/info.ini')
        # ini_set('SearchPanel', 'default', 1, TEMP_FOLDER + '/info.ini')
        # filecontrol_copyFileOrFolder(TEMP_FOLDER + '/info.ini', self.SEARCHPANEL_PATH + '/info.ini')

        # 清掉custom.ini内容，保证每个案例都是从头开始跑
        if 'XGame' not in self.clientType:
            f = open(self.SEARCHPANEL_PATH + "\\custom.ini", 'w')
            f.close()

        # copy用例、更改字段

        src=os.path.join(SERVER_SEARCHPANEL,casename)
        dst = os.path.join(self.SEARCHPANEL_PATH,'RunMap.tab')

        if 'XGame' in self.clientType:
            src=os.path.join(SERVER_PATH,'XGame','RunTab',casename)
            # dst = self.INTERFACE_PATH +'\\'+self.runMapType+'\\RunMap.tab'
            TEMP_FOLDER =os.path.join('TempFolder','Interface',self.runMapType)

        tmp = os.path.join(TEMP_FOLDER,'RunMap.tab')
        filecontrol_copyFileOrFolder(src, tmp)
        sChange = []
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
        if 'XGame' not in self.clientType:
            filecontrol_copyFileOrFolder(tmp, dst)

        # 拷贝SearchPanel.lua  XGame拷贝Interface文件夹
        if 'XGame' in self.clientType:
            filecontrol_copyFileOrFolder(os.path.join('TempFolder','Interface'), self.INTERFACE_PATH, self.deviceId,self.package)

        elif 'classic' in self.clientType:
            src = SERVER_SEARCHPANEL + r'\BVTTest_classic.lua'
            dst = self.CLIENT_PATH + r'/interface/SearchPanel/BVTTest.lua'
            filecontrol_copyFileOrFolder(src, dst)
            filecontrol_copyFileOrFolder(SERVER_MAINSCRIPT + '/VideoManagerPanel_classic.lua',
                                         self.CLIENT_PATH + '/ui/Config/Default/VideoManagerPanel.lua')
        else:
            src = SERVER_SEARCHPANEL + r'\BVTTest.lua'
            dst = self.CLIENT_PATH + r'/interface/SearchPanel/BVTTest.lua'
            filecontrol_copyFileOrFolder(src, dst)

    def teardown(self):
        self.log.info(f'CaseJX3SearchPanel_teardown start')
        self.bRunMapEnd = True
        super().teardown()
        if not self.bMobile:
            win32_kill_process('DumpReport64.exe')
            win32_kill_process('WerFault.exe')
            win32_kill_process('PerformanceTool.exe')
            win32_kill_process('PerfMon.exe')
            win32_kill_process('IDLE_TASK_BVT.exe')
        self.log.info('testplus.kill node1')
        if hasattr(self, 'testplus') and self.testplus != None:
            self.log.info('testplus.kill node2')
            self.testplus.kill()
            #此处容易阻塞
            self.log.info('testplus.kill node3')
        self.log.info(f'CaseJX3SearchPanel_teardown end')

    def check_dic_args(self, dic_args):
        super().check_dic_args(dic_args)
        self.testpoint = dic_args['testpoint']
        #页面参数超时时间
        self.nClientRunTimeOut = int(dic_args['nTimeout'])
        #页面参数超时时间+启动app前自动化准备环境的时间
        self.nTaskTimeOut=0
        # 获取地图配置表

        self.nMapId=dic_args['mapid']
        # 根据地图id获取地图名称
        if 'classic' in dic_args['clientType']:
            self.mapname = self.DIC_MAPNAME_CLASSIC[self.nMapId]
        else:
            self.mapname = self.DIC_MAPNAME[self.nMapId]

        dic_args['casename'] = gbk(dic_args['casename'])
        self.strCaseName=dic_args['CaseName']
        self.log.info(f'用例: {self.strCaseName}')
        dic_args['Switch'] = 1
        if 'XGame' in self.clientType:
            self.runMapType = dic_args['runmaptype']
            pass


    def add_thread_for_searchPanel(self, dic_args):
        dicSwitch = dic_args
        if not self.bMobile:
            old_f = getLastLogFile(self.CLIENT_LOG_PATH)
            t = threading.Thread(target=self.thread_HandleDropLine,
                                 args=(dicSwitch, threading.currentThread(), old_f, self.CLIENT_LOG_PATH,))
            self.listThreads_beforeStartClient.append(t)

            t = threading.Thread(target=self.thread_KillDeath,
                                 args=(dicSwitch, threading.currentThread(), self.nClientRunTimeOut,))
            self.listThreads_beforeStartClient.append(t)
            t = threading.Thread(target=self.thread_SearchPanelClientExit, args=(dicSwitch, threading.currentThread(),))
            self.listThreads_beforeStartClient.append(t)
            t = threading.Thread(target=self.thread_SearchPanelPerfEyeCtrl,
                                 args=(dicSwitch, threading.currentThread(),))
            self.listThreads_beforeStartClient.append(t)
            t = threading.Thread(target=self.thread_WindowMinimiz, args=(dicSwitch, threading.currentThread(),))
            self.listThreads_beforeStartClient.append(t)
        else:
            #perfeye线程
            t = threading.Thread(target=self.thread_SearchPanelPerfEyeCtrl,
                                 args=(dicSwitch, threading.currentThread(),))
            self.listThreads_beforeStartClient.append(t)
            #app运行状态监控与宕机线程
            t = threading.Thread(target=self.thread_CheckAppRunStateAndCrash,
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

            #处理设备弹窗
            #t = threading.Thread(target=self.mobile_device.thread_DealWithMobileWindow,
                                 #args=(threading.currentThread(),))
            #self.listThreads_beforeStartClient.append(t)


    def processWindows(self):
        if 'XGame' in self.clientType:
            return
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
            self.log.error(info)

    def task_process_data(self):
        if not hasattr(self, 'testplus'):
            return
        # tags = '档次|机型|配置|地图|测试点|日期'
        subtags = '{0}|{1}|{2}|{3}|{4}|{5}'.format(self.tagVideoLevel, self.tagMachineType, self.tagVideoCard,
                                                   self.mapname, self.testpoint, date_get_szToday())
        self.log.info('task_process_data start')
        if 'XGame' in self.clientType:
            #冷机时间
            nSleepMinite = self.nClientRunTimeOut // 60
            nSleepMinite = 10 if nSleepMinite > 10 else nSleepMinite
            if self.runMapType == 'HotPointRunMap':
                szFilePath = os.path.join(self.INTERFACE_PATH, self.runMapType, "Data.json")
                szTempData = os.path.join("TempFolder", "Data.json")
                filecontrol_copyFileOrFolder(szFilePath, szTempData, self.deviceId, self.package)
                szBVTVerserion = svn_get_bvt_version_xgame()[1]
                reportId = HotPointMapUpLoadData(self.AppKey, szTempData, self.tagVideoCard, self.mapname,szBVTVerserion)
                HotPointMapUpLoadImg(self.AppKey, self.mapname, reportId)
            else:
                self.log.info(self.SDK.dic_dataList)
                bRetXGameUploadData=False
                if self.bMobile:
                    bRetXGameUploadData = PerfeyeSaveXGame(self.testplus, self.deviceId, self.AppKey, subtags, self.SDK.dic_dataList)
                else:
                    bRetXGameUploadData = PerfeyeSaveXGame(self.testplus, self.deviceId, self.AppKey, subtags, self.SDK.dic_dataList)

                if not bRetXGameUploadData:
                    #如果是预跑任务就默认当然任务执行成功  如果不是等待十分钟手机冷却后再重启当前任务
                    if 'ahead-run' not in self.testpoint:
                        nExceptionType=ExceptionMsg.PERF_UPLOADERROR
                        strMsg=f'保存数据失败,上传数据失败，机器: {self.strMachineName} 用例: {self.strCaseName} {nSleepMinite}分钟后重启'
                        self.queue_ExceptionMsg.put({'exceptionType': nExceptionType, 'msg': strMsg,'sleepMinite':nSleepMinite})
            #冷机
            if 'ahead-run' in self.testpoint:
                sleep_heartbeat(nSleepMinite)

        else:
            path_PerfeyeDataSave = PerfeyeSave(self.testplus, self.deviceId, self.AppKey, subtags, self.version_PC)


    def stop_task(self):
        self.log.info('stop_task')
        self.bRunMapEnd = True
        self.mobile_device.kill_app()

    def setAutoLogin(self,dic_args):
        self.log.info("setAutoLogin")
        #设置自动登录参数
        strAccount = dic_args['account'] if "account" in dic_args else self.strAccount
        strPassword = dic_args['password'] if "password" in dic_args else self.strPassword
        strRoleName = dic_args['RoleName'] if "RoleName" in dic_args else self.strRoleName
        strSchoolType = dic_args['school_type'] if "school_type" in dic_args else self.strSchool_type
        strRoleType = dic_args['role_type'] if "role_type" in dic_args else self.strRole_type
        strStepTime = dic_args['StepTime'] if "StepTime" in dic_args and dic_args["StepTime"] != '' else self.strStepTime
        strDisplayRegion = dic_args['szDisplayRegion'] if "szDisplayRegion" in dic_args else self.strDisplayRegion
        strDisplayServer = dic_args['szDisplayServer'] if "szDisplayServer" in dic_args else self.strDisplayServer
        strSwitch = dic_args['Switch'] if "Switch" in dic_args and dic_args["Switch"] != '' else self.strSwitch
        #strCMD=f"AutoLogin.SetAutoLoginInfo({strStepTime},{strAccount},{strDisplayRegion},{strDisplayServer},{strRoleName},{strSchoolType},{strRoleType})"
        strCMD ="/cmd AutoLogin.SetAutoLoginInfo('%s','%s','%s','%s','%s','%s','%s')"%(strStepTime,strAccount,strDisplayRegion,strDisplayServer,strRoleName,strSchoolType,'')
        self.SDK.SendCommandToSDK(strCMD)


    def run_case(self):
        pass

    #确认cmd命令的返回值一定为true 或者false
    def make_sure_result(self,strCMD,bResult=True):
        bRet = True
        bRes = False
        while True:
            if bRet:
                #返回值为true结束
                if bResult:
                    if bRes:
                        break
                    else:
                        self.SDK.SendCommandToSDK(strCMD)
                        bRet = False
                else:
                    if bRes:
                        self.SDK.SendCommandToSDK(strCMD)
                        bRet = False
                    else:
                        break
            else:
                bRet, bRes = self.SDK.GetCmdRetCode(strCMD)
            time.sleep(1)

    def front_prepare(self,dic_args):

        #初始化SDK
        self.SDK = XGameSocketClient(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'SocketClientDLL.dll'),self.mobile_device.get_address(), 1112)

        self.bSDKIniFlag=True

        #确保进入了登录界面
        ''''''
        strCMD="/cmd UIMgr.IsViewOpened(VIEW_ID.PanelLogin)"
        self.make_sure_result(strCMD)

        #启动插件主控面板
        strCMD = f"/cmd AutoTestControllerSwitch.Start('{self.runMapType}')"
        self.SDK.SendCommandToSDK(strCMD)
        #收到主控面板的消息后表示主控面板启动成功
        ''''''
        while not self.SDK.dic_MessageRetCode:
            time.sleep(1)

        #设置自动登录
        self.setAutoLogin(dic_args)

    def enter_game_scene(self):
        # 确保进入了游戏场景界面
        strCMD = "/cmd AutoTestController.IsFromLoadingEnterGame()"
        self.make_sure_result(strCMD)




    def run_local(self, dic_args):
        # 2022-4-21 7zip安全漏洞 临时处理
        self.check_dic_args(dic_args)  # 处理传进来的参数
        self.loadDataFromLocalConfig(dic_args)  # 读LocalConfig配置
        #self.clearInfoFiles()  # 清空客户端向本用例通信的信息文件
        self.processInterface(dic_args)  # 处理插件
        #self.OpenAutoLogin(dic_args)  # 自动登录
        self.preRunToKillExe()  # 运行前清理之前没有关闭的相关程序
        self.processServerlist(dic_args)  # 处理serverlist
        #self.processSearchPanelTab(dic_args)  # 处理运行所需的RunMap.tab
        self.processWindows()
        self.add_thread_for_searchPanel(dic_args)
        self.copyPerfeye()
        self.process_threads_beforeStartClient()
        self.start_client_test(dic_args)
        self.front_prepare(dic_args) #跑图预处理
        self.run_case()
        self.stop_task()
        self.task_process_data()


if __name__ == '__main__':
    obj_test = XGameAutoTestCase()
    obj_test.run_from_IQB()

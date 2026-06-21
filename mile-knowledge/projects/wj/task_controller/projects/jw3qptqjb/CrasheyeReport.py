# -*- coding: utf-8 -*-
import os
import time
import threading
import traceback
import queue
from BaseToolFunc import *

class CrasheyeReport(object):
    def __init__(self, device,strClientPath=r'/sdcard/Android/data/com.seasun.jx3/files', tagMachineType='Android',strServerPath=None,strLogPath=None):
        self.log=logging.getLogger(str(os.getpid()))
        self.log.info("CrasheyeReport init start")
        self.strClientUUID = None
        self.bReportResult = False
        self.strLogPath = strLogPath or f'{GetTEMPFOLDER()}/logcat.txt'
        self.strServerLogPath=strServerPath+'\logcat.txt'
        self.strServerPath=strServerPath
        self.device=device
        self.deviceId=None
        if self.device:
            self.deviceId = device.deviceId
        self.tagMachineType = tagMachineType
        self.bThreadExitFlag = False
        self.nSleepTime = 2
        self.strClientPath=strClientPath
        self.dic_ThreadSouce={"pi":None,"cmd":None,"strLogPath":None,"strTempFilePath":None,"strClientTempFilePath":None,"app_start":None} #线程占用的资源
        self.log.info("CrasheyeReport init end")
        self.bReleaseFlag=False

    def Start(self):
        try:
            self.log.info("crashreport start")
            #暂时只支持Android
            if self.tagMachineType == 'Android' or self.tagMachineType=='Ios':
                #Android需要先push一个crasheye_debug.json空文件到 files目录启动App
                strTempFilePath=f'{GetTEMPFOLDER()}{os.sep}crasheye_debug.json'
                with open(strTempFilePath, 'w') as f:
                    pass
                self.dic_ThreadSouce['strTempFilePath'] =strTempFilePath
                filecontrol_copyFileOrFolder(strTempFilePath,f"{self.strClientPath}/crasheye_debug.json",self.device.deviceId,self.device.packageName)
                self.dic_ThreadSouce['strClientTempFilePath'] =f"{self.strClientPath}/crasheye_debug.json"

                #app启动后需要将app中的crasheye_debug.json删除
                #time.sleep(2)
                #filecontrol_deleteFileOrFolder(self.strClientPath+'/crasheye_debug.json',self.device.deviceId,self.device.packageName)
                #self.dic_ThreadSouce['strClientTempFilePath'] = None
            #开启crashreport线程
            t = threading.Thread(target=self.thread_crashreport)
            t.setDaemon(True)
            t.start()
        except Exception:
            self.bThreadExitFlag = True  # 通知子线程退出
            info = traceback.format_exc()
            self.log.error(info)

    def GetResult(self):
        return self.bReportResult

    def Stop(self):
        #线程退出后 会自动清理占用资源
        self.log.info("crashreport stop")
        self.bThreadExitFlag=True


    def killLogProcess(self, cmd):
        if self.tagMachineType == 'Android':
            win32_kill_process_by_cmd("adb.exe", szCmdLine=cmd)
        else:
            win32_kill_process_by_cmd("tidevice.exe", szCmdLine=cmd)

    def thread_crashreport(self):
        #本地临时日志路径
        self.dic_ThreadSouce['strLogPath']=self.strLogPath
        if self.tagMachineType=='PC':
            #PC直接从CrasheyeReport日志中获取Dumpkey
            strDate = time.strftime(f"%Y_%m_%d", time.localtime())
            strCrasheyeLogPath=filecontrol_getFolderLastestFile(self.strClientPath+f'/logs/CrasheyeReport/{strDate}',self.strLogPath)
            with open(self.strLogPath, "rb") as f:
                res = f.read()
                if not self.strClientUUID:
                    match = re.search(b'DumpKey=(.*)\n', res)
                    if match:
                        self.strClientUUID = str(match.group(1), encoding='gbk').strip()
                        self.bReportResult=True
            return

        elif self.tagMachineType == 'Android':
            # android端需要先清除
            #adb_logcat_clear(deviceID=self.deviceId)
            cmd = 'adb -s %s logcat'
        else:
            cmd = 'tidevice -u %s syslog'
        #00008110-001C551E2682801E
        #tidevice -u 00008110-001C551E2682801E syslog > E:\AUTO_BVT_NEW\case\liuzhu\py3\TempFolder\log.txt
        cmd = cmd % self.deviceId
        cmdToLog = cmd + " > %s" % self.strLogPath
        self.log.info(cmdToLog)
        list_cmd = cmdToLog.split(' ')
        self.dic_ThreadSouce['cmd']=cmd
        self.dic_ThreadSouce['pi'] = subprocess.Popen(list_cmd, shell=True, stdout=subprocess.PIPE)
        #先启动app 再logcat
        #启动app
        self.device.start_app()
        self.log.info('CrasheyeReport app_start')
        self.dic_ThreadSouce['app_start'] = True
        while not os.path.exists(self.strLogPath):
            time.sleep(0.5)
            pass

        nTimer=0
        nStep=0.1
        nReportCount=0
        strCrashProcessID=b''
        with open(self.strLogPath, "rb") as f:
            while True:
                try:
                    if self.bThreadExitFlag:  # 主线程要求退出
                        break
                    if nTimer>self.nSleepTime:
                        nTimer=0
                    else:
                        nTimer+=nStep
                        time.sleep(nStep)
                        continue
                    res = f.read()
                    where = f.tell()
                    if res == b'':
                        continue
                    list_bLine = res.split(b'\n')
                    for bLine in list_bLine:
                        if not self.strClientUUID:
                            match = re.search(b'Crasheye: Device UUID=(.*)', bLine)
                            if match:
                                self.strClientUUID = str(match.group(1),encoding='gbk')
                        if bLine.find(b'Response status code: 200')+1:
                            if self.tagMachineType=='Android':
                                # Android 同一进程下出现 两次Response status code: 200 才认为有宕机报告产出
                                list_strInfo=res.split(b' ')
                                #移除无效信息
                                while b'' in list_strInfo:
                                    list_strInfo.remove(b'')
                                strCrashProcessIDTemp=list_strInfo[2]
                                if strCrashProcessID!=strCrashProcessIDTemp:
                                    nReportCount = 1
                                    strCrashProcessID=strCrashProcessIDTemp
                                else:
                                    nReportCount += 1
                                    if nReportCount >= 2:
                                        self.bReportResult = True
                                        break
                            else:
                                #ios 第一次是session 第二次是 crash
                                if bLine.find(b'crash') + 1:
                                    self.bReportResult = True
                                    break

                    #发现报告退出检测
                    if self.bReportResult:
                        break
                    f.seek(where)
                except Exception:
                    info = traceback.format_exc()
                    self.log.info(info)
                    break
        self.ReleaseSource()

    #资源释放
    def ReleaseSource(self):
        if not self.bReleaseFlag:
            self.bReleaseFlag=True
            self.log.info("crashreport ReleaseSource")
            if self.dic_ThreadSouce['pi']:
                self.dic_ThreadSouce['pi'].kill()
                self.dic_ThreadSouce['pi']=None
            if self.dic_ThreadSouce['cmd']:
                self.killLogProcess(self.dic_ThreadSouce['cmd'])
                self.dic_ThreadSouce['cmd']=None
            if self.dic_ThreadSouce['strTempFilePath']:
                filecontrol_deleteFileOrFolder(self.dic_ThreadSouce['strTempFilePath'])
                self.dic_ThreadSouce['strTempFilePath']=None
            if self.dic_ThreadSouce['strClientTempFilePath']:
                filecontrol_deleteFileOrFolder(self.strClientPath+'/crasheye_debug.json',self.device.deviceId,self.device.packageName)
                self.dic_ThreadSouce['strClientTempFilePath']=None
            if self.dic_ThreadSouce['strLogPath']:
                #拷贝日志文件文件到共享
                if self.bReportResult:
                    filecontrol_copyFileOrFolder(self.dic_ThreadSouce['strLogPath'],self.strServerLogPath)
                    strTempPath=f"{GetTEMPFOLDER()}{os.sep}{self.strClientUUID}"
                    with open(strTempPath,'w') as f:
                        pass
                    filecontrol_copyFileOrFolder(strTempPath,self.strServerPath)
                    #filecontrol_deleteFileOrFolder(strTempPath)
                #filecontrol_deleteFileOrFolder(self.dic_ThreadSouce['strLogPath'])
                self.dic_ThreadSouce['strLogPath']=None
            if self.dic_ThreadSouce['app_start']:
                self.device.kill_app()


if __name__ == '__main__':
    #obj = CrasheyeReport()
    pass

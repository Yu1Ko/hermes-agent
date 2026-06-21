# -*- coding: utf-8 -*-
import os.path
import re
import time

import CaseCommon
from ftplib import FTP
from datetime import date, timedelta
from BaseToolFunc import *
from CaseJX3SearchPanel import *
import uiautomator2 as u2

class ScanFiles:
    def __init__(self, host: str, port: int, username: str, password: str, remotepath: str,filetype:str):
        self.strUsername = username
        self.strPassword = password
        self.strHost = host
        self.nHost = port
        self.strRemotepath = remotepath
        self.strFileType=filetype
        # {'strDate': '2023-03-03', 'strTime': '14:20', 'strContent': '/XGame-apk/2023-03-07/app-release-269105_jinshan_30081.apk', 'strSize': '48764449', 'strFileName': 'app-release-269105_jinshan_30081.apk'}
        self.list_allFileInfo = []
        self.list_allDirInfo = []
        self.nTraceDate = 20
        self.dic_arrangedFileInfo = {}  # key:strDate  vakue: [{},{}]
        self.list_unArrangeFileInfo = []  # [{},{}]

    def launch(self):
        """初始化FTP连接并登陆"""
        self.f = FTP()
        self.f.connect(host=self.strHost, port=self.nHost)
        self.f.login(self.strUsername, self.strPassword)

    def analyze_ftp_info(self):
        if self.strFileType=='apk':
            self.strFileDateSeparator='-'
            self.strFileInfoSeparator='_'
        else:
            self.strFileDateSeparator = '_'
            self.strFileInfoSeparator = '-'
        self.list_allFileInfo = []
        self.dic_arrangedFileInfo = {}
        self.list_unArrangeFileInfo = []
        self.__analyze_ftp_info_inner(self.strRemotepath)
        logger.info('analyze_ftp_info')

    def del_dir_by_date(self, nDateCount):
        list_save_date = []
        list_delete_date = []
        for i in range(nDateCount):
            list_save_date.append((date.today() + timedelta(days=-i)).strftime(f"%Y{self.strFileDateSeparator}%m{self.strFileDateSeparator}%d"))
        for dic_FileInfo in self.list_allFileInfo:
            print(dic_FileInfo)
            if dic_FileInfo['strDate'] not in list_save_date:
                self.deletefile(dic_FileInfo['strContent'])
                strDeleteDate = dic_FileInfo['strContent'].split('/')[2]
                if strDeleteDate not in list_delete_date:
                    list_delete_date.append(strDeleteDate)
        for strDeleteDate in list_delete_date:
            logger.info("delete date\t" + strDeleteDate)
            self.f.rmd(self.strRemotepath + '/' + strDeleteDate)


    def __analyze_ftp_info_inner(self, strRemotepath):
        """解析FTP文件系统信息行"""
        list_fileInfo = []
        logger.info(strRemotepath)
        self.f.dir(strRemotepath, list_fileInfo.append)
        for fileInfo in list_fileInfo:
            list_info = fileInfo.split(' ')
            nCount = list_info.count('')
            for i in range(nCount):
                list_info.remove('')
            if '<DIR>' in list_info[2]:
                self.__analyze_ftp_info_inner(strRemotepath + '/' + list_info[3])
            else:
                dic_content = {}
                bArrange = False
                # 根据长度判断是否已经处理过当前file了  等于1未处理
                if len(list_info[3].split(self.strFileInfoSeparator)) == 1:
                    #未处理过的文件 以文件创建的时间为基准
                    list_date = list_info[0].split('-')
                    strDate = '20' + list_date[2] + self.strFileDateSeparator + list_date[0] + self.strFileDateSeparator + list_date[1]
                    strHour = list_info[1][:2]
                    strMinutes = list_info[1][3:5]
                    if "PM" in list_info[1] and strHour != '12' and strHour != '0':
                        nHour = int(strHour)
                        nHour += 12
                        strHour = str(nHour)
                    if "AM" in list_info[1] and strHour == '12':
                        nHour = int(strHour)
                        nHour -= 12
                        strHour = str(nHour)
                    #特殊处理 避免排序错误
                    if strHour=='0':
                        strHour='00'
                    if strMinutes=='0':
                        strMinutes='00'
                    strTime = strHour + self.strFileDateSeparator + strMinutes
                else:
                    strDate = list_info[3][:-4].split(self.strFileInfoSeparator)[-2]
                    strTime = list_info[3][:-4].split(self.strFileInfoSeparator)[-1]
                    bArrange = True
                list_date = strDate.split(self.strFileDateSeparator)
                list_time = strTime.split(self.strFileDateSeparator)
                dic_content['strDate'] = strDate
                dic_content['strTime'] = strTime
                dic_content['strContent'] = strRemotepath + '/' + list_info[3]
                dic_content['strSize'] = list_info[2]
                dic_content['strFileName'] = list_info[3]
                dic_content['strVersion'] = list_info[3].split(self.strFileInfoSeparator)[0].split(self.strFileDateSeparator)[-1]
                if bArrange:
                    if strDate not in self.dic_arrangedFileInfo:
                        self.dic_arrangedFileInfo[strDate] = []
                    self.dic_arrangedFileInfo[strDate].append(dic_content)
                else:
                    self.list_unArrangeFileInfo.append(dic_content)
                self.list_allFileInfo.append(dic_content)

    def arrange_File(self):
        # 解析FTP文件目录信息
        # self.analyze_ftp_info()
        # 创建本地临时文件夹
        #apk以“-” 分割  ipa以“_”分割
        TempFolder = 'TempFolder'

        if not filecontrol_existFileOrFolder(TempFolder):
            filecontrol_createFolder(TempFolder)
        for dic_fileInfo in self.list_unArrangeFileInfo:
            # continue
            strFilePath = dic_fileInfo['strContent']
            try:
                # FTP创建存放APK文件的日期目录
                self.mkdir(self.strRemotepath + '/' + dic_fileInfo['strDate'])
            except:
                pass
            # 下载到本地再修改名称
            strNewFileName = dic_fileInfo['strFileName'][:-4] + self.strFileInfoSeparator + dic_fileInfo['strDate'] + self.strFileInfoSeparator + dic_fileInfo[
                'strTime'] + '.'+self.strFileType
            strLocalFilePath = os.path.join(TempFolder,'temp.'+self.strFileType)
            bFlag=True
            while bFlag:
                try:
                    # 从FTP上下载原始文件到本地
                    self.downloadfile(strFilePath, strLocalFilePath)
                    # 上传处理过文件名称的文件到FTP
                    self.uploadfile(self.strRemotepath + '/' + dic_fileInfo['strDate'] + '/' + strNewFileName,strLocalFilePath)
                    # 删除FTP上的原始文件
                    self.deletefile(strFilePath)
                    bFlag=False
                except:
                    time.sleep(60)
                    filecontrol_deleteFileOrFolder(strLocalFilePath)
            filecontrol_deleteFileOrFolder(strLocalFilePath)

        # 处理文件后更新文件信息
        self.analyze_ftp_info()
        logger.info('arrange_File')

        # 排序函数
        def SortByMinutes_dic(dic_info):
            return dic_info['strDate']+self.strFileInfoSeparator+dic_info['strTime']

        # 根据strDate给以处理过的文件排序
        for strDate in self.dic_arrangedFileInfo:
            list_fileInfo = self.dic_arrangedFileInfo[strDate]
            list_fileInfo.sort(reverse=True, key=SortByMinutes_dic)
        # 给全部文件排序
        self.list_allFileInfo.sort(reverse=True, key=SortByMinutes_dic)

    def downloadfile(self, remotepath, localpath):
        bufsize = 1024  # 设置缓冲块大小
        fp = open(localpath, 'wb')  # 以写模式在本地打开文件
        self.f.retrbinary('RETR ' + remotepath, fp.write, bufsize)  # 接收服务器上文件并写入本地文件
        self.f.set_debuglevel(0)  # 关闭调试
        fp.close()  # 关闭文件

    def uploadfile(self, remotepath, localpath):
        bufsize = 1024
        fp = open(localpath, 'rb')
        self.f.storbinary('STOR ' + remotepath, fp, bufsize)  # 上传文件
        self.f.set_debuglevel(0)
        fp.close()

    def mkdir(self, path):
        self.f.mkd(path)

    def deletefile(self, path):
        self.f.delete(path)

    def ini(self):
        self.analyze_ftp_info()
        self.arrange_File()

    def GetLastestFile(self):
        # 重置FTP文件信息
        dic_fileInfo = self.list_allFileInfo[0]
        logger.info(dic_fileInfo)
        TempFolder = 'TempFolder'
        if not filecontrol_existFileOrFolder(TempFolder):
            filecontrol_createFolder(TempFolder)
        self.downloadfile(dic_fileInfo['strContent'], os.path.join('TempFolder','RunMap.'+self.strFileType))

    def GetVersionFile(self,strVersion):
        # 重置FTP文件信息
        dic_fileInfo = {}
        for dic_fileInfo_temp in self.list_allFileInfo:
            if strVersion in dic_fileInfo_temp['strFileName']:
                dic_fileInfo=dic_fileInfo_temp
        logger.info(dic_fileInfo)
        TempFolder = 'TempFolder'
        if not filecontrol_existFileOrFolder(TempFolder):
            filecontrol_createFolder(TempFolder)
        if 'strFileName' not in dic_fileInfo:
            raise Exception("未找%s对应的apk信息,请检查版本号"%(strVersion))
        self.downloadfile(dic_fileInfo['strContent'], os.path.join('TempFolder','RunMap.'+self.strFileType))


    def quit(self):
        """与FTP服务器断开连接"""
        self.f.quit()


class CaseXGameGetPackage(CaseJX3SearchPanel):
    def __init__(self):
        super().__init__()


    def check_dic_args(self, dic_args):
        super().check_dic_args(dic_args)
        if 'version' in dic_args:
            self.version = dic_args['version']
        self.nSaveDateCount = 8
        if 'saveDate' in dic_args:
            self.nSaveDateCount = dic_args['saveDate']
        self.log.info("check_dic_args")
        self.file_version = str(dic_args['file_version'])
        #覆盖安装
        self.bOverlay = dic_args['overlay']

    def loadDataFromLocalConfig(self, dic_args):
        super().loadDataFromLocalConfig(dic_args)
        if self.tagMachineType=='Android':
            self.file_type = 'apk'
            self.strFileDateSeparator = '-'
            self.strFileInfoSeparator = '_'
        elif self.tagMachineType=='Ios':
            self.file_type = 'ipa'
            self.strFileDateSeparator = '_'
            self.strFileInfoSeparator = '-'
        else:
            raise Exception(f"设备类型错误:{self.tagMachineType},必须为:Ios Android")

    def get_file_info(self):
        self.sf = ScanFiles('10.11.80.122', 21, "ftp1", "ftp+123", '/XGame-'+self.file_type,self.file_type)
        self.sf.launch()
        self.sf.ini()
        dic_fileInfo = self.sf.list_allFileInfo[0]
        strDate = time.strftime(f"%Y{self.strFileDateSeparator}%m{self.strFileDateSeparator}%d", time.localtime())
        nMintes = int(time.strftime("%H", time.localtime())) * 60 + int(time.strftime("%M", time.localtime()))
        list_fileTime = dic_fileInfo['strTime'].split(self.strFileDateSeparator)
        nFileMintes = int(list_fileTime[0]) * 60 + int(list_fileTime[1])
        while strDate != dic_fileInfo['strDate']:
            time.sleep(60)
            self.log.info('fileDate:'+dic_fileInfo['strDate']+'\t'+'today:'+strDate)
            self.sf.ini()
            dic_fileInfo = self.sf.list_allFileInfo[0]
        strFilePath=os.path.join('TempFolder','RunMap.'+self.file_type)
        if filecontrol_existFileOrFolder(strFilePath):
            filecontrol_deleteFileOrFolder(strFilePath)
        if self.file_version== '0':
            self.sf.GetLastestFile()
        else:
            self.sf.GetVersionFile(self.file_version)
        self.log.info("get_apk_info")

    def del_dir_by_date(self):
        try:
            self.sf.del_dir_by_date(self.nSaveDateCount)
        except Exception as e:
            info = traceback.format_exc()
            self.log.info(info)
            if '10054' in info:
                self.sf.launch()
                self.sf.del_dir_by_date(self.nSaveDateCount)


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

    def set_package(self):
        if not self.bOverlay and self.mobile_device.find_app():
            self.mobile_device.kill_app()
            self.mobile_device.uninstall_app()
            self.log.info('uninstall_app')
        time.sleep(10)
        self.mobile_device.install_app(os.path.join(os.path.dirname(os.path.realpath(__file__)), 'TempFolder', 'RunMap.' + self.file_type),False)
        time.sleep(30)
        self.log.info('app install success')
        #mobile_install_app(os.path.join(os.path.dirname(os.path.realpath(__file__)),'TempFolder','RunMap.'+self.file_type),self.deviceId)
        #time.sleep(10)
        #self.log.info("set_package success")
        # 启动apk
        #res = mobile_start_app(self.package, self.deviceId)
        #time.sleep(60)
        # 关闭apk
        #mobile_kill_app(self.package, self.deviceId)

    def task_mobile(self):
        if not self.bMobile:
            return
        sleep_heartbeat(2)
        self.bRunMapEnd=True
        time.sleep(10)
        self.mobile_device.kill_app()
        #mobile_kill_app(self.package,self.deviceId)
        self.log.info('mobile wait end')

    def add_thread_for_searchPanel(self, dic_args):
            # perfeye线程 目前perfeye会出现连接server失败 导致用例退出
            #t = threading.Thread(target=self.thread_SearchPanelPerfEyeCtrl,
                                 #args=(dic_args, threading.currentThread(),))
            #self.listThreads_beforeStartClient.append(t)
            #app运行状态监控与宕机线程
            t = threading.Thread(target=self.thread_CheckAppRunStateAndCrash,
                                 args=(dic_args, threading.currentThread(),))
            self.listThreads_beforeStartClient.append(t)

            #用例超时检查线程
            t = threading.Thread(target=self.thread_CheckTaskTimeOut,
                                 args=(dic_args, threading.currentThread(),))
            self.listThreads_beforeStartClient.append(t)

            #异常处理线程
            t = threading.Thread(target=self.thread_DealWith_ExceptionMsg,
                                 args=(dic_args, threading.currentThread(),))
            self.listThreads_beforeStartClient.append(t)

            #处理设备弹窗
            t = threading.Thread(target=self.mobile_device.thread_DealWithMobileWindow,
                                 args=(threading.currentThread(),))
            self.listThreads_beforeStartClient.append(t)


    def run_local(self, dic_args):
        self.check_dic_args(dic_args)
        self.loadDataFromLocalConfig(dic_args)
        self.get_file_info()
        self.sf.del_dir_by_date(self.nSaveDateCount)
        self.copyPerfeye()
        self.add_thread_for_searchPanel(dic_args)
        self.process_threads_beforeStartClient()
        self.set_package()
        self.start_client_test(dic_args)
        self.task_mobile()


if __name__ == '__main__':
    oob = CaseXGameGetPackage()
    oob.run_from_IQB()
    '''
    sf = ScanFiles('10.11.80.122', 21, "ftp1", "ftp+123", '/XGame-apk')
    sf.launch()
    sf.ini()
    sf.arrange_File()
    print(sf.dic_arrangedFileInfo)
'''

# -*- coding: utf-8 -*-
import re
import time

import CaseCommon
from ftplib import FTP
from datetime import date, timedelta
from BaseToolFunc import *
from CaseJX3Client import *
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
        self.list_allFileInfo = []
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
                    # 未处理过的文件 以文件创建的时间为基准
                    list_date = list_info[0].split('-')
                    strDate = '20' + list_date[2] + self.strFileDateSeparator + list_date[
                        0] + self.strFileDateSeparator + list_date[1]
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
                    # 特殊处理 避免排序错误
                    if strHour == '0':
                        strHour = '00'
                    if strMinutes == '0':
                        strMinutes = '00'
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
                dic_content['strVersion'] = \
                list_info[3].split(self.strFileInfoSeparator)[0].split(self.strFileDateSeparator)[-1]
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
        # apk以“-” 分割  ipa以“_”分割
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
            strNewFileName = dic_fileInfo['strFileName'][:-4] + self.strFileInfoSeparator + dic_fileInfo[
                'strDate'] + self.strFileInfoSeparator + dic_fileInfo[
                                 'strTime'] + '.' + self.strFileType
            strLocalFilePath = os.path.join(TempFolder, 'temp.' + self.strFileType)
            bFlag = True
            while bFlag:
                try:
                    # 从FTP上下载原始文件到本地
                    self.downloadfile(strFilePath, strLocalFilePath)
                    # 上传处理过文件名称的文件到FTP
                    self.uploadfile(self.strRemotepath + '/' + dic_fileInfo['strDate'] + '/' + strNewFileName,
                                    strLocalFilePath)
                    # 删除FTP上的原始文件
                    self.deletefile(strFilePath)
                    bFlag = False
                except:
                    time.sleep(60)
                    filecontrol_deleteFileOrFolder(strLocalFilePath)
            filecontrol_deleteFileOrFolder(strLocalFilePath)
        # 处理文件后更新文件信息
        self.analyze_ftp_info()
        logger.info('arrange_File')

        # 排序函数
        def SortByMinutes_dic(dic_info):
            return dic_info['strDate'] + self.strFileInfoSeparator + dic_info['strTime']

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
        self.downloadfile(dic_fileInfo['strContent'], 'TempFolder/RunMap.'+self.strFileType)

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
        self.downloadfile(dic_fileInfo['strContent'], 'TempFolder/RunMap.'+self.strFileType)


    def quit(self):
        """与FTP服务器断开连接"""
        self.f.quit()


class CaseBackUpdateFtpFile(CaseJX3Client):
    def __init__(self):
        super().__init__()


    def check_dic_args(self, dic_args):
        super().check_dic_args(dic_args)
        self.nSaveDateCount = 8
        if 'saveDate' in dic_args:
            self.nSaveDateCount = dic_args['saveDate']
        self.log.info("check_dic_args")
        strClientType=dic_args['clientType']
        if 'Android' in strClientType:
            self.file_type='apk'
            self.strFileDateSeparator = '-'
            self.strFileInfoSeparator = '_'
        else:
            self.file_type='ipa'
            self.strFileDateSeparator = '_'
            self.strFileInfoSeparator = '-'

        self.sf = ScanFiles('10.11.80.122', 21, "ftp1", "ftp+123", '/XGame-' + self.file_type, self.file_type)
        self.sf.launch()

    def get_file_info(self):
        self.sf.ini()
        dic_fileInfo = self.sf.list_allFileInfo[0]
        strDate = time.strftime(f"%Y{self.strFileDateSeparator}%m{self.strFileDateSeparator}%d", time.localtime())
        nMintes = int(time.strftime("%H", time.localtime())) * 60 + int(time.strftime("%M", time.localtime()))
        list_fileTime = dic_fileInfo['strTime'].split(self.strFileDateSeparator)
        nFileMintes = int(list_fileTime[0]) * 60 + int(list_fileTime[1])
        self.log.info("get_file_info")

    def deal_with_install_exceptional_case(self,d,t_parent):
        dic_deviceInfo = d.device_info
        #d.debug = True
        if dic_deviceInfo['brand']=='OPPO':
            bTag=d(text='继续安装').exists
            nCount=0
            while not bTag:
                time.sleep(10)
                bTag = d(text='继续安装').exists
                nCount+=1
                self.log.info("oppo 继续安装 try %d"%(nCount))
            self.log.info("oppo 点击继续安装")
            time.sleep(10)
            d(text='继续安装').click()
            time.sleep(10)

            bTag = d(text='允许').exists
            nCount = 0
            while not bTag:
                time.sleep(10)
                bTag = d(text='允许').exists
                nCount+=1
                self.log.info("oppo 允许 try %d"%(nCount))
            self.log.info("oppo 点击允许")
            d(text='允许').click()
            time.sleep(10)


    def set_package(self):
        if "Android" in self.clientType:
            if adb_find_apk(self.package, self.deviceId):
                adb_uninstall_apk(self.package, self.deviceId)
                self.log.info('adb_uninstall_apk')
            time.sleep(10)
            #处理安装apk时出现的特殊情况
            d = u2.connect_usb(self.deviceId)
            t=threading.Thread(target=self.deal_with_install_exceptional_case,args=(d, threading.currentThread()))
            t.setDaemon(True)
            t.start()

            adb_install_apk(os.path.dirname(os.path.realpath(__file__)) + r'/TempFolder/RunMap.'+self.file_type, self.deviceId)
            time.sleep(10)
            # 启动apk
            res=adb_start_apk('com.seasun.jx3/com.seasungame.jx3.x3d.KActivity',self.deviceId)
            time.sleep(60)
            # 关闭apk
            adb_kill_apk(self.package,self.deviceId)
        else:
            if tidevice_find_ipa(self.package, self.deviceId):
                tidevice_uninstall_ipa(self.package, self.deviceId)
                self.log.info('tidevice_uninstall_ipa')
            time.sleep(10)
            #处理安装apk时出现的特殊情况
            #d = u2.connect_usb(self.deviceId)
            #t=threading.Thread(target=self.deal_with_install_exceptional_case,args=(d, threading.currentThread()))
            #t.setDaemon(True)
            #t.start()
            tidevice_install_ipa(os.path.dirname(os.path.realpath(__file__)) + r'/TempFolder/RunMap.'+self.file_type, self.deviceId)
            time.sleep(10)
            # 启动apk
            res=tidevice_start_ipa(self.package,self.deviceId)
            time.sleep(60)
            # 关闭apk
            tidevice_kill_ipa(self.package,self.deviceId)


    def run_local(self, dic_args):
        self.check_dic_args(dic_args)
        #self.loadDataFromLocalConfig(dic_args)
        list_fileInfo = []
        while True:
            self.get_file_info()
            self.sf.del_dir_by_date(self.nSaveDateCount)
            # 防止由于长时间未操作FTP,导致FTP链接关闭
            for i in range(60):
                self.sf.f.dir(self.sf.strRemotepath, list_fileInfo.append)
                if (time.strftime("%H", time.localtime()) == '5'):
                    for i in range(61):
                        self.sf.f.dir(self.sf.strRemotepath, list_fileInfo.append)
                        time.sleep(60)
                time.sleep(60)

if __name__ == '__main__':
    oob = CaseBackUpdateFtpFile()
    oob.run_from_IQB()

    '''
    sf = ScanFiles('10.11.80.122', 21, "ftp1", "ftp+123", '/XGame-apk')
    sf.launch()
    sf.ini()
    sf.arrange_File()
    print(sf.dic_arrangedFileInfo)
'''

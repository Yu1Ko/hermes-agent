# -*- coding: utf-8 -*-
import re
import time

import CaseCommon
from ftplib import FTP
from datetime import date, timedelta
from BaseToolFunc import *
from CaseJX3Client import *
import uiautomator2 as u2

from CaseXGameGetPackage import ScanFiles

class CaseBackUpdateFtpFile(CaseJX3Client):
    def __init__(self):
        super().__init__()

    def check_dic_args(self, dic_args):
        super().check_dic_args(dic_args)
        self.nSaveDateCount = 8
        if 'saveDate' in dic_args:
            self.nSaveDateCount = dic_args['saveDate']
        self.shareDir = "FileShare-181-242"
        if 'shareDir' in dic_args:
            self.shareDir = dic_args['shareDir']
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

        self.sf = ScanFiles('10.11.80.122', 21, "ftp1", "ftp+123", '/XGame-' + self.file_type,self.shareDir, self.file_type)
        self.sf.launch()

    def get_file_info(self):
        self.sf.ini()
        dic_fileInfo = self.sf.list_allShareFileInfo[0]
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
            res=pymobiledevice3_start_ipa(self.package,self.deviceId)
            time.sleep(60)
            # 关闭apk
            pymobiledevice3_kill_ipa(self.package,self.deviceId)


    def run_local(self, dic_args):
        self.check_dic_args(dic_args)
        #self.loadDataFromLocalConfig(dic_args)
        list_fileInfo = []
        while True:
            try:
                self.get_file_info()
                self.sf.del_dir_by_date(self.nSaveDateCount)
                # 防止由于长时间未操作FTP,导致FTP链接关闭
                for i in range(10):
                    self.sf.f.dir(self.sf.strRemotepath, list_fileInfo.append)
                    #if (time.strftime("%H", time.localtime()) == '5'):
                        #for i in range(61):
                            #self.sf.f.dir(self.sf.strRemotepath, list_fileInfo.append)
                            #time.sleep(60)
                    time.sleep(60)
            except Exception:
                info = traceback.format_exc()
                self.log.info(info)
                if 'ConnectionResetError' in info:
                    self.sf.launch()
                time.sleep(60)

    def teardown(self):
        self.log.info('CaseBackUpdateFtpFile start')
        super().teardown()
        self.log.info('CaseBackUpdateFtpFile end')

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

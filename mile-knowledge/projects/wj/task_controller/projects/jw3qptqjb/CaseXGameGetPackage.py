# -*- coding: utf-8 -*-
import ftplib
import os.path
import threading
import time

import CaseCommon
from ftplib import FTP
from datetime import date, timedelta
from BaseToolFunc import *
from CaseJX3SearchPanel import *
import uiautomator2 as u2

if strOS == "Linux":
    logger = logging.getLogger(str(os.getpid()))
    LOCAL_PACKAGE_PATH = os.path.join("LocalPackage")
else:
    logger = logging.getLogger(str(os.getpid()))
    #LOCAL_PACKAGE_PATH = os.path.join("..", "..", "..", "..", "LocalPackage")
    LOCAL_PACKAGE_PATH = os.path.join("LocalPackage")


def same_file(file_path1, file_path2):
    return os.path.getsize(file_path1) == os.path.getsize(file_path2)


def safe_copy_file(copy_file, target_path):
    """
    确保文件copy完成 并且 只支持pc

    :param copy_file: 要拷贝的文件
    :param target_path: 要拷贝至的路径
    """

    filecontrol_copyFileOrFolder(copy_file, target_path)  # 拷贝文件
    if os.path.isdir(target_path):
        # 如果是拷到目录下，凭借实际文件路径给 same_file 函数使用
        file_basename = os.path.basename(copy_file)
        target_file_path = os.path.join(target_path, file_basename)
    else:
        # 如果是拷到文件
        target_file_path = target_path
    if not os.path.isfile(target_file_path) or not same_file(copy_file, target_file_path):
        # 如果文件不存在，或者文件大小不一致，则copy失败，sleep 1分钟，递归重新copy
        time.sleep(60)
        safe_copy_file(copy_file, target_path)
    pass


def check_file_state(strStateFilePath, strFileType, bWaitCopy=False):
    #bWaitCopy:是否等待源文件写入完成
    if not filecontrol_existFileOrFolder(strStateFilePath):
        # 拷贝状态检测文件
        strServerPath = SERVER_PATH + f'{os.sep}XGame{os.sep}CopyState.ini'
        filecontrol_copyFileOrFolder(strServerPath, strStateFilePath)
    nCopyState = int(ini_get('State', strFileType, strStateFilePath))
    logger.info(f"check_file_state src:{strStateFilePath} dst:{strFileType}")
    if bWaitCopy:
        #等待文件写入完成
        while True:
            if nCopyState == 0:
                return False
            time.sleep(60)
            logger.info("等待文件源文件写入完成")
            nCopyState = int(ini_get('State', strFileType, strStateFilePath))
    if nCopyState == 1:
        return True
    return False


class ScanFiles:
    def __init__(self, host: str, port: int, username: str, password: str, remotepath: str, sharedir: str,
                 filetype: str, ):
        self.strUsername = username
        self.strPassword = password
        self.strHost = host
        self.nHost = port
        self.strRemotepath = remotepath
        self.strFileType = filetype
        self.initLogger()
        self.bStart = False
        # 根据传的共享目录名称来着选择去哪个共享处理安装包信息
        #sharedir='10.11.181.242'
        self.strSharedir = sharedir
        self.strSharePath = self.getStrSharePath_public(sharedir)
        #使用公共访问的方式会导致公共带宽被占满
        #self.uploadShareDir = ['FileShare-181-242', 'FileShare-144-44']
        #self.uploadShareDir =['10.11.181.242','10.11.144.44']
        self.uploadShareDir = ['10.11.181.242']
        # {'strDate': '2023-03-03', 'strTime': '14:20', 'strContent': '/XGame-apk/2023-03-07/app-release-269105_jinshan_30081.apk', 'strSize': '48764449', 'strFileName': 'app-release-269105.apk'}
        self.list_allFileInfo = []
        self.list_allShareFileInfo = []
        self.list_allDirInfo = []
        self.nTraceDate = 20
        self.dic_arrangedFileInfo = {}  # key:strDate  vakue: [{},{}]
        self.list_unArrangeFileInfo = []  # [{},{}]
        if self.strFileType == 'apk':
            self.strFileDateSeparator = '-'
            self.strFileInfoSeparator = '_'
        else:
            self.strFileDateSeparator = '_'
            self.strFileInfoSeparator = '-'
        self.str_temp_package_folder = os.path.join(GetWorkPath(), 'TempPackageFolder', 'RunMap.' + self.strFileType)

    def initLogger(self):
        try:
            #self.caseLogPath = initLog(self.__class__.__name__)
            self.log = logging.getLogger(str(os.getpid()))

        except Exception:
            info = traceback.format_exc()
            print(info)
            raise Exception('initLogger ERROR!!')

    def keepAlive(self):
        #连接报错,重启服务
        try:
            while True:
                self.f.voidcmd("NOOP")
                time.sleep(120)
        except:
            self.launch()
            time.sleep(60)
            pass

    def launch(self):
        """初始化FTP连接并登陆"""
        self.f = FTP()
        self.f.connect(host=self.strHost, port=self.nHost)
        self.f.login(self.strUsername, self.strPassword)
        if not self.bStart:
            self.bStart = True
            t = threading.Thread(target=self.keepAlive)
            t.setDaemon(True)
            t.start()

    def analyze_ftp_info(self):
        self.list_allFileInfo = []
        self.list_allShareFileInfo = []
        self.dic_arrangedFileInfo = {}
        self.list_unArrangeFileInfo = []
        # 解析FTP服务器上的所有文件
        self.__analyze_ftp_info_inner(self.strRemotepath)
        logger.info('analyze_ftp_info')

    def getStrSharePath(self, sharedir):
        #FileShare = r'\\10.11.85.148\%s\FTP-back\XGame-%s' % (sharedir, self.strFileType)
        FileShare = r'\\%s\FileShare\FTP-back\XGame-%s' % (sharedir, self.strFileType)
        return FileShare

    def getStrSharePath_public(self, sharedir):
        if strOS == "Linux":
            FileShare = r'/mnt/BaseShare/%s/FTP-back/XGame-%s' % (sharedir, self.strFileType)
        else:
            FileShare = r'\\10.11.85.148\%s\FTP-back\XGame-%s' % (sharedir, self.strFileType)

        return FileShare

    def analyze_share_file_info(self):
        # 共享里面的数据都是已经处理完成的,只需要根据文件名称读出来就行
        self.list_allShareFileInfo = get_package_list(self.strSharePath, self.strFileInfoSeparator,
                                                      self.strFileDateSeparator)

    # FTP服务器专用
    def del_dir_by_date(self, nDateCount):
        list_save_date = []
        list_delete_date = []
        for i in range(nDateCount):
            list_save_date.append((date.today() + timedelta(days=-i)).strftime(
                f"%Y{self.strFileDateSeparator}%m{self.strFileDateSeparator}%d"))

        # FTP删除逻辑
        '''
        for dic_FileInfo in self.list_allFileInfo:
            print(dic_FileInfo)
            if dic_FileInfo['strDate'] not in list_save_date:
                self.deletefile(dic_FileInfo['strContent'])
                strDeleteDate = dic_FileInfo['strDate']
                if strDeleteDate not in list_delete_date:
                    list_delete_date.append(strDeleteDate)
        for strDeleteDate in list_delete_date:
            logger.info("delete date\t" + strDeleteDate)
            self.f.rmd(self.strRemotepath + '/' + strDeleteDate)'''

        # 获取所有共享文件
        for share_name in self.uploadShareDir:
            share_path = self.getStrSharePath(share_name)
            share_all_file = get_package_list(share_path, self.strFileInfoSeparator, self.strFileDateSeparator)
            self.log.info(f"当前共享地址：{share_path}")
            # 共享删除逻辑
            for dic_FileInfo in share_all_file:
                print(dic_FileInfo)
                if dic_FileInfo['strDate'] not in list_save_date:
                    # 删除文件
                    self.log.info(f"删除文件：{dic_FileInfo['strContent']}")
                    filecontrol_deleteFileOrFolder(dic_FileInfo['strContent'])
                    strDeleteDate = dic_FileInfo['strDate']
                    if strDeleteDate not in list_delete_date:
                        list_delete_date.append(strDeleteDate)
            for strDeleteDate in list_delete_date:
                # 删除日期文件夹
                strDeletePath = share_path + '\\' + strDeleteDate
                self.log.info(f"删除文件：{strDeletePath}")
                filecontrol_deleteFileOrFolder(strDeletePath)

        # 删除 ftp 上的日期文件夹
        ftp_path = f"XGame-{self.strFileType}"

        ftp_folder = []
        self.f.dir(ftp_path, ftp_folder.append)
        ftp_folder = [line.split()[-1] for line in ftp_folder if '<DIR>' in line]
        for folder_name in ftp_folder:
            if folder_name not in list_save_date:
                folder_path = os.path.join(ftp_path, folder_name)
                self.log.info(f"删除ftp日期文件夹：{folder_path}")
                self.f.rmd(folder_path)

    def __analyze_ftp_info_inner(self, strRemotepath):
        """解析FTP文件系统信息行"""
        # 所有文件的相关信息都会处理完成 写入一个dic
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
        # 根据未排序的文件把文件下载到本地 根据dic_content中存储的文件信息处理

        # apk以“-” 分割  ipa以“_”分割
        TempFolder = 'TempFolderAPK_IPA'

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
                bFlag = False
                strStateFilePath = ''
                strFileNameSharePath = None
                try:
                    # 从FTP上下载原始文件到本地
                    self.downloadfile(strFilePath, strLocalFilePath)
                    # 上传处理过文件名称的文件到FTP
                    # 由于FTP服务器容量有限暂时放到共享里面管理，上传园区和港湾的共享
                    for upDir in self.uploadShareDir:
                        strFileNameSharePath = self.getStrSharePath(upDir) + '\\' + dic_fileInfo[
                            'strDate'] + '\\' + strNewFileName
                        self.log.info(f'src:{strLocalFilePath}')
                        self.log.info(f'dst:{strFileNameSharePath}')
                        if not filecontrol_existFileOrFolder(strFileNameSharePath) or not same_file(strLocalFilePath,
                                                                                                    strFileNameSharePath):
                            #写入正在拷贝的标识 防止文件推送过程中 被其它用例使用
                            strStateFilePath = r'\\%s\FileShare\FTP-back\CopyState.ini' % (upDir)
                            ini_set('State', self.strFileType, 1, strStateFilePath)
                            safe_copy_file(strLocalFilePath, strFileNameSharePath)
                            # filecontrol_copyFileOrFolder(strLocalFilePath, strFileNameSharePath)
                        # self.uploadfile(self.strRemotepath + '/' + dic_fileInfo['strDate'] + '/' + strNewFileName,strLocalFilePath)
                        if len(self.uploadShareDir) > 1:
                            #共享路径大于2 则拷贝完一个文件后就解除写入限制 因为其它共享写入很慢 避免流程卡住
                            strStateFilePath = r'\\%s\FileShare\FTP-back\CopyState.ini' % (upDir)
                            ini_set('State', self.strFileType, 0, strStateFilePath)
                    # 删除FTP上的原始文件
                    self.deletefile(strFilePath)
                except Exception:
                    info = traceback.format_exc()
                    self.log.info(info)
                    time.sleep(60)
                    filecontrol_deleteFileOrFolder(strLocalFilePath)
                    if strFileNameSharePath:
                        filecontrol_deleteFileOrFolder(strFileNameSharePath)
                        #ini_set('State', self.strFileType, 0, strStateFilePath)
            filecontrol_deleteFileOrFolder(strLocalFilePath)
        #全部待处理文件完成后 改写正在拷贝的标识 防止文件推送过程中报错 被其它用例使用
        for upDir in self.uploadShareDir:
            strStateFilePath = r'\\%s\FileShare\FTP-back\CopyState.ini' % (upDir)
            ini_set('State', self.strFileType, 0, strStateFilePath)
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
        # 更新共享文件数据
        self.analyze_share_file_info()

    def GetLastestFile(self):
        # FTP获取最新安装包
        '''
        dic_fileInfo = self.list_allFileInfo[0]
        logger.info(dic_fileInfo)
        TempFolder = 'TempFolder'
        if not filecontrol_existFileOrFolder(TempFolder):
            filecontrol_createFolder(TempFolder)
        self.downloadfile(dic_fileInfo['strContent'], os.path.join('TempFolder','RunMap.'+self.strFileType))'''
        # 共享获取最新安装包
        # 根据CopyState.ini来判断共享文件最新的包是否推送完成
        if strOS == "Linux":
            strStateFilePath = r'/mnt/BaseShare/%s/FTP-back/CopyState.ini' % (self.strSharedir)
        else:
            strStateFilePath = r'\\10.11.85.148\%s\FTP-back\CopyState.ini' % (self.strSharedir)
        check_file_state(strStateFilePath, self.strFileType, bWaitCopy=True)
        dic_fileInfo = self.list_allShareFileInfo[0]
        self.log.info(dic_fileInfo)
        TempFolder = GetTEMPFOLDER()
        if not filecontrol_existFileOrFolder(TempFolder):
            filecontrol_createFolder(TempFolder)
        # filecontrol_copyFileOrFolder(dic_fileInfo['strContent'], self.str_temp_package_folder)
        safe_copy_file(dic_fileInfo['strContent'], self.str_temp_package_folder)

    def GetVersionFile(self, strVersion):
        # FTP获取最新安装包
        '''
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
        self.downloadfile(dic_fileInfo['strContent'], os.path.join('TempFolder','RunMap.'+self.strFileType))'''

        # 共享获取最新安装包
        dic_fileInfo = {}
        for dic_fileInfo_temp in self.list_allShareFileInfo:
            if strVersion in dic_fileInfo_temp['strFileName']:
                dic_fileInfo = dic_fileInfo_temp
        logger.info(dic_fileInfo)
        TempFolder = 'TempFolder'
        if not filecontrol_existFileOrFolder(TempFolder):
            filecontrol_createFolder(TempFolder)
        if 'strFileName' not in dic_fileInfo:
            raise Exception("未找%s对应的apk信息,请检查版本号" % (strVersion))
        # filecontrol_copyFileOrFolder(dic_fileInfo['strContent'], self.str_temp_package_folder)
        safe_copy_file(dic_fileInfo['strContent'], self.str_temp_package_folder)

    def quit(self):
        """与FTP服务器断开连接"""
        if self.f:
            self.f.quit()


class CaseXGameGetPackage(CaseJX3SearchPanel):
    def __init__(self):
        super().__init__()

    def check_dic_args(self, dic_args):
        super().check_dic_args(dic_args)
        self.nSaveDateCount = dic_args.get("saveDate", 8)
        self.shareDir = dic_args.get("shareDir", "FileShare-181-242")
        self.log.info("CaseXGameGetPackage check_dic_args")
        self.file_version = str(dic_args['file_version'])
        # 覆盖安装
        self.bOverlay = dic_args['overlay']
        self.copy_local_package = dic_args.get("copyLocalPackage", True)  # 是否使用本地包，默认是
        self.strCustomPackagePath = dic_args.get("PackagePath", None)  #是否使用自定义路径的安装包

        self.nCloseTeardown = 0 # 释放通道标志

    def loadDataFromLocalConfig(self, dic_args):
        super().loadDataFromLocalConfig(dic_args)
        if self.tagMachineType == 'Android':
            self.file_type = 'apk'
            self.strFileDateSeparator = '-'
            self.strFileInfoSeparator = '_'
        elif self.tagMachineType == 'Ios':
            self.file_type = 'ipa'
            self.strFileDateSeparator = '_'
            self.strFileInfoSeparator = '-'
        else:
            raise Exception(f"设备类型错误:{self.tagMachineType},必须为:Ios Android")

        self.local_package_base_path = os.path.join(os.getcwd(),dic_args.get("localPath", LOCAL_PACKAGE_PATH))
        self.local_package_path = os.path.join(self.local_package_base_path, self.file_type)  # 本地包存放路径
        self.log.info(f"local_package_path：{self.local_package_path}")
        self.str_temp_package_folder = os.path.join(GetWorkPath(), "TempPackageFolder")
        self.strFilePath = os.path.join(self.str_temp_package_folder, 'RunMap.' + self.file_type)
        self.log.info(f"strFilePath：{self.strFilePath}")

    def get_local_packages(self):
        """获取本地所有包信息"""
        return get_package_list(self.local_package_path, self.sf.strFileInfoSeparator, self.sf.strFileDateSeparator)

    def clear_local_packages(self):
        """清理本地包，只保留一个日期最新的"""
        for package_info in self.get_local_packages()[1:]:
            # self.get_local_packages 默认是按日期最新排序，则这里除了第一个包，其它都删掉
            os.remove(package_info['strContent'])
            self.log.info(f"删除包：{package_info['strContent']}")
            pass
        pass

    def get_file_info(self):
        self.sf = ScanFiles('10.11.80.122', 21, "ftp1", "ftp+123", '/XGame-' + self.file_type, self.shareDir,
                            self.file_type)
        # 连接ftp服务器
        # self.sf.launch()
        # 分析安装包+整理所有安装包
        # self.sf.ini()
        # 访问共享报错 每隔1分钟再次访问一次
        while True:
            #保证访问共享成功
            try:
                self.sf.analyze_share_file_info()  # 获取共享所有文件信息
                dic_fileInfo = self.sf.list_allShareFileInfo[0]
                break
            except:
                pass
        #使用自定义路径
        if self.strCustomPackagePath:
            if os.path.isfile(self.strCustomPackagePath):
                #路径存在 则拷贝文件
                safe_copy_file(self.strCustomPackagePath, self.strFilePath)
            else:
                raise Exception(f"{self.strCustomPackagePath} not exist")
            return

        strDate = time.strftime(f"%Y{self.strFileDateSeparator}%m{self.strFileDateSeparator}%d", time.localtime())

        # nMintes = int(time.strftime("%H", time.localtime())) * 60 + int(time.strftime("%M", time.localtime()))
        # list_fileTime = dic_fileInfo['strTime'].split(self.strFileDateSeparator)
        # nFileMintes = int(list_fileTime[0]) * 60 + int(list_fileTime[1])
        if filecontrol_existFileOrFolder(self.str_temp_package_folder):
            self.log.info(f"删除包文件夹：{self.str_temp_package_folder}")
            filecontrol_deleteFileOrFolder(self.str_temp_package_folder)

        def get_await_file_share_package_to_local():
            """
            获取共享中，当日最新的包至本地
                - 判断共享文件夹最新包的版本和本地包版本是否一致
                - 不一致则下载共享最新的包，一致则不做处理
            """
            self.sf.analyze_share_file_info()  # 更新共享所有文件信息
            #根据CopyState.ini来判断共享文件最新的包是否推送完成
            if strOS == "Linux":
                strStateFilePath = r'/mnt/BaseShare/%s/FTP-back/CopyState.ini' % (self.shareDir)
            else:
                strStateFilePath = r'\\10.11.85.148\%s\FTP-back\CopyState.ini' % (self.shareDir)
            check_file_state(strStateFilePath, self.file_type, bWaitCopy=True)
            _dic_fileInfo = self.sf.list_allShareFileInfo[0]  # 共享文件最新的包信息
            while strDate != _dic_fileInfo['strDate']:
                self.log.info(f"正在等待共享文件夹当日的包")
                time.sleep(60)
                self.sf.analyze_share_file_info()  # 重新获取共享所有文件信息
                _dic_fileInfo = self.sf.list_allShareFileInfo[0]
            _local_packages = self.get_local_packages()
            if _local_packages:
                _local_new_package = _local_packages[0]
                if _local_new_package['strVersion'] == _dic_fileInfo['strVersion'] and same_file(
                        _dic_fileInfo['strContent'], _local_new_package['strContent']):
                    # 本地版本号和共享最新版本号一致 文件大小也一致
                    return
            #拷贝包到本地需要检测是否已经有其它用例正在拷贝 如果正在拷贝需要等待其它用例拷贝完成
            strLocalCopyStateFilePath = os.path.join(self.local_package_base_path, 'CopyState.ini')
            check_file_state(strLocalCopyStateFilePath, self.file_type, bWaitCopy=True)
            ini_set('State', self.file_type, 1, strLocalCopyStateFilePath)
            try:
                safe_copy_file(_dic_fileInfo['strContent'], self.local_package_path)
                self.nCloseTeardown = 1
            except:
                self.log.info(f"拷贝文件出现异常")
                pass
            # 当前用例拷贝共享文件到本地完成
            ini_set('State', self.file_type, 0, strLocalCopyStateFilePath)

        if self.file_version == '0':
            # 判断最新的文件的日期是否跟今天的日期一致  不一致需要等待今天的安装包推送
            # while strDate != dic_fileInfo['strDate']:
            #     time.sleep(60)
            #     self.log.info('fileDate:' + dic_fileInfo['strDate'] + '\t' + 'today:' + strDate)
            #     self.sf.ini()
            #     dic_fileInfo = self.sf.list_allShareFileInfo[0]
            # self.sf.GetLastestFile()
            if self.copy_local_package:
                # 使用本地包
                if not os.path.isdir(self.local_package_path):
                    os.makedirs(self.local_package_path)
                get_await_file_share_package_to_local()  # 获取当日最新的包，会对比共享和本地文件夹中的版本号，获取到最新的包
                local_packages = self.get_local_packages()
                local_new_package = local_packages[0]
                if not filecontrol_existFileOrFolder(self.str_temp_package_folder):
                    self.log.info(f"创建临时文件夹:{self.str_temp_package_folder}")
                    filecontrol_createFolder(self.str_temp_package_folder)
                # filecontrol_copyFileOrFolder(local_new_package['strContent'], self.strFilePath)  # 拷贝至临时文件夹
                safe_copy_file(local_new_package['strContent'], self.strFilePath)
                self.log.info(f"以拷贝本地包至临时文件夹：{local_new_package['strContent']}")
                self.file_version = local_new_package['strVersion']
                self.clear_local_packages()  # 清理本地包
            else:
                # 不使用本地包，则拉取共享当日最新包
                self.sf.GetLastestFile()
            pass
        else:
            # 填写固定版本号
            self.log.info(f"使用固定版本号:{self.file_version}")
            if self.copy_local_package:
                try:
                    file_share_package = [package for package in self.sf.list_allShareFileInfo if
                                          package['strVersion'] == self.file_version][0]
                except IndexError:
                    raise ValueError(f"在本地和共享文件夹中，均未找到版本号为{self.file_version}的安装包，请检查版本号")
                local_packages = self.get_local_packages()
                if local_packages:
                    local_new_package = local_packages[0]  # 本地最新包
                    if local_new_package['strVersion'] == self.file_version and same_file(
                            file_share_package['strContent'], local_new_package['strContent']):
                        self.log.info(f"本地包版本号一致 文件大小一致，直接使用本地包")
                        # filecontrol_copyFileOrFolder(local_new_package['strContent'], self.strFilePath)  # 拷贝至临时文件夹
                        # 等待共享到本地的文件写入完成
                        strLocalCopyStateFilePath = os.path.join(self.local_package_base_path, 'CopyState.ini')
                        check_file_state(strLocalCopyStateFilePath, self.file_type, bWaitCopy=True)
                        safe_copy_file(local_new_package['strContent'], self.strFilePath)
                        return
                # 从共享拉对应的包到本地
                self.sf.analyze_share_file_info()  # 更新共享所有文件信息

                if filecontrol_existFileOrFolder(self.local_package_path):
                    #  删除本地包，为了保持本地只有一个包
                    filecontrol_deleteFileOrFolder(self.local_package_path)
                    filecontrol_createFolder(self.local_package_path)
                else:
                    filecontrol_createFolder(self.local_package_path)

                self.log.info(f"从共享文件夹中拉取包：{file_share_package['strContent']}至：{self.local_package_path}")
                # filecontrol_copyFileOrFolder(file_share_package['strContent'], self.local_package_path)
                strLocalCopyStateFilePath = os.path.join(self.local_package_base_path, 'CopyState.ini')

                safe_copy_file(file_share_package['strContent'], self.local_package_path)

                local_packages = self.get_local_packages()
                local_new_package = local_packages[0]  # 本地最新包
                # filecontrol_copyFileOrFolder(local_new_package['strContent'], self.strFilePath)  # 拷贝至临时文件夹
                # 等待共享到本地的文件写入完成
                strLocalCopyStateFilePath = os.path.join(self.local_package_base_path, 'CopyState.ini')
                check_file_state(strLocalCopyStateFilePath, self.file_type, bWaitCopy=True)
                safe_copy_file(local_new_package['strContent'], self.strFilePath)
            else:
                # 同时不使用本地包，则不需要等待今天的包推送
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

    def deal_with_install_exceptional_case(self, deviceId, t_parent):
        if '-' in deviceId:
            import wda
            wc = wda.USBClient(deviceId, port=8100, wda_bundle_id='com.facebook.WebDriverAgentRunner.xctrunner')
            while t_parent.is_alive():
                if wc.alert.exists:
                    strBtnName = wc.alert.buttons()[0]
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
        self.mobile_device.kill_app()
        if not self.bOverlay and self.mobile_device.find_app():
            self.mobile_device.uninstall_app()
            self.log.info('uninstall_app')
        time.sleep(10)
        #os.path.dirname(os.path.realpath(__file__)) 文件路径
        #os.getcwd() 工作路径
        self.log.info(os.path.join(os.getcwd(), self.strFilePath))
        self.mobile_device.install_app(os.path.join(os.getcwd(), self.strFilePath), False)
        #self._save_package_version(self.file_version)
        time.sleep(30)
        #self.log.info('app install success')
        self.bCanStartClient = True
        # mobile_install_app(os.path.join(os.path.dirname(os.path.realpath(__file__)),'TempFolder','RunMap.'+self.file_type),self.deviceId)
        # time.sleep(10)
        # self.log.info("set_package success")
        # 启动apk
        # res = mobile_start_app(self.package, self.deviceId)
        # time.sleep(60)
        # 关闭apk
        # mobile_kill_app(self.package, self.deviceId)

    def task_mobile(self):
        if not self.bMobile:
            return

        sleep_heartbeat(2)
        self.bRunMapEnd = True
        time.sleep(10)
        self.mobile_device.kill_app()
        # 清除资源服务配置
        list_folderName = ['version_vk.cfg', 'config.ini']
        for strFolderName in list_folderName:
            filecontrol_deleteFileOrFolder(f'{self.CLIENT_PATH}/{strFolderName}', self.deviceId, self.package)
        self.processResoucre(self.args, bClear=True, bWaitTodayRes=True)  # 处理pakv5资源相关
        self.log.info('mobile wait end')

    def add_thread_for_searchPanel(self, dic_args):
        # perfeye线程 目前perfeye会出现连接server失败 导致用例退出
        # t = threading.Thread(target=self.thread_SearchPanelPerfEyeCtrl,
        # args=(dic_args, threading.currentThread(),))
        # self.listThreads_beforeStartClient.append(t)
        # app运行状态监控与宕机线程
        t = threading.Thread(target=self.thread_CheckAppRunStateAndCrash,
                             args=(dic_args, threading.currentThread(),))
        self.listThreads_beforeStartClient.append(t)

        # 用例超时检查线程
        t = threading.Thread(target=self.thread_CheckTaskTimeOut,
                             args=(dic_args, threading.currentThread(),))
        self.listThreads_beforeStartClient.append(t)

        # 异常处理线程
        t = threading.Thread(target=self.thread_DealWith_ExceptionMsg,
                             args=(dic_args, threading.currentThread(),))
        self.listThreads_beforeStartClient.append(t)

        # 处理设备弹窗
        t = threading.Thread(target=self.mobile_device.thread_DealWithMobileWindow,
                             args=(threading.currentThread(),))
        self.listThreads_beforeStartClient.append(t)

    def run_local(self, dic_args):
        self.check_dic_args(dic_args)
        self.loadDataFromLocalConfig(dic_args)
        self.get_file_info()
        # self.sf.del_dir_by_date(self.nSaveDateCount)
        # self.sf.quit()
        self.copyPerfeye()
        #self.processResoucre(dic_args)
        self.add_thread_for_searchPanel(dic_args)
        self.process_threads_beforeStartClient()
        self.set_package()
        self.start_client_test(dic_args)
        self.task_mobile()

    def teardown(self):
        self.log.info(f'CaseXGameGetPackage start')
        #解除CopyState.ini的占用
        strLocalCopyStateFilePath = os.path.join(self.local_package_base_path, 'CopyState.ini')
        ini_set('State', self.file_type, 0, strLocalCopyStateFilePath)
        # 拷贝成功才释放通道
        if self.nCloseTeardown == 1:
            super().teardown()
        self.log.info(f'CaseXGameGetPackage end')


def AutoRun(dic_parameters):
    global obj_test
    obj_test = CaseXGameGetPackage()
    obj_test.run_from_uauto(dic_parameters)


def Clear():
    obj_test.teardown()


if __name__ == '__main__':
    obj = CaseXGameGetPackage()
    obj.run_from_IQB()
    '''
    sf = ScanFiles('10.11.80.122', 21, "ftp1", "ftp+123", '/XGame-apk','apk')
    sf.launch()
    sf.ini()
    sf.del_dir_by_date(4)
    print(sf.dic_arrangedFileInfo)
    print(sf.list_allFileInfo)
    print(sf.list_allShareFileInfo)
    print('----------------')
    for l in sf.list_allShareFileInfo:
        print(l)
    print(sf.list_allFileInfo[0])

    file_type='ipa'
    strFilePath = os.path.join('TempFolder', 'RunMap.' + file_type)
    if filecontrol_existFileOrFolder(strFilePath):
        filecontrol_deleteFileOrFolder(strFilePath)
    file_version='0'
    if file_version == '0':
        sf.GetLastestFile()
    else:
        sf.GetVersionFile(file_version)'''

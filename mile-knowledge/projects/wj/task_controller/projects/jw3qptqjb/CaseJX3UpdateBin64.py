# -*- coding: utf-8 -*-

from CaseJX3SvnUpdate import *
#

class CaseJX3UpdateBin64(CaseJX3SvnUpdate):
    def __init__(self):
        super().__init__()

    def move_bin64_folder(self):
        PAKV5_CLIENT_PATH = self.CLIENT_PATH
        PAKV5_bin64 = os.path.join(PAKV5_CLIENT_PATH, 'bin64_m')
        filecontrol_deleteFileOrFolder(PAKV5_bin64)
        # while os.path.exists(PAKV5_bin64):
        #     try:
        #         os.system('rd "{0}" /S /q'.format(PAKV5_bin64))
        #     except Exception as e:
        #         self.log.exception(e)
        #     time.sleep(1)
        #结束进程 确保文件拷贝失败
        win32_kill_process('JX3ClientX3DX64.exe')
        win32_kill_process('KGPK4_StreamDownloaderX64.exe')
        win32_kill_process('SeasunGame.exe')
        win32_kill_process('JX3Debugger.exe')
        win32_kill_process('CrasheyeReport64.exe')
        shutil.copytree(self.work_path, PAKV5_bin64, ignore=shutil.ignore_patterns('.svn'))
        print('bin64 has been copied to PAKV5 client.')
        # path_shaderListUpload = os.path.join(PAKV5_bin64, 'ShaderListUpload')
        # filecontrol_deleteFileOrFolder(path_shaderListUpload)

    def KGPK4_StreamDownloader(self):
        pass
        return
        if 'classic' in self.strClientType:
            filecontrol_copyFileOrFolder(os.path.join('CaseJX3Client-Attachment', 'MainScript', 'KGPK4_StreamDownloader.classic_exp.conf'),
                                         os.path.join(self.CLIENT_PATH, self.BIN64_NAME, 'KGPK4_StreamDownloader.classic_exp.conf'))
        else:
            PAKV5_bin64 = self.CLIENT_PATH + '\\bin64'
            f = open(PAKV5_bin64 + r'\KGPK4_StreamDownloader.zhcn_exp.conf')
            allfile = f.read()
            allfile = allfile.replace(
                # 'StreamDownload.BaseUrl_0=jx3v4qqcs-miniupdate.dl.kingsoft.com/jx3hd_v4_mini/',
                'StreamDownload.BaseUrl_0=jx3v4qqcs-miniupdate.xoyocdn.com/jx3hd_v4_mini/',
                'StreamDownload.BaseUrl_0=jx3.kingsoft.net/v4/stream/jx3hd_v4_mini/'
            )
            allfile = allfile.replace('StreamDownload.BaseUrl_1=jx3v4kscs-miniupdate.xoyocdn.com/jx3hd_v4_mini/', '')
            allfile = allfile.replace('StreamDownload.BaseUrl_2=jx3v4hwcs-miniupdate.xoyocdn.com/jx3hd_v4_mini/', '')

            f.close()
            f = open(PAKV5_bin64 + r'\KGPK4_StreamDownloader.zhcn_exp.conf', 'w')
            f.write(allfile)
            f.close()

    def set_work_path(self, dic_args):
        #本地checkout库
        x = os.path.realpath(__file__)
        root = x.split('\\')[0]
        if self.strClientType == "PAK":
            self.work_path = os.path.join(root, os.sep, 'bin64_release')
            self.svnPath = 'https://xsjreposvr1.seasungame.com/svn/sword3-products/branches-rel/b_jx3_released_zhcn_hd/client/bin64'
        else:
            if self.bEXP:
                if 'classic' in  self.strClientType:
                    self.work_path = os.path.join(root, os.sep, 'bin64_classic')
                    self.svnPath = 'https://xsjreposvr4.seasungame.com/svn/sword3-products_Classic/trunk/client/bin64'
                elif 'VK' in  self.strClientType:
                    self.work_path = os.path.join(root, os.sep, 'bin64_m')
                    self.svnPath = 'https://xsjreposvr1.seasungame.com/svn/sword3-products/trunk/client/bin64_m'
                else:
                    self.work_path = os.path.join(root, os.sep, 'bin64')
                    self.svnPath = 'https://xsjreposvr1.seasungame.com/svn/sword3-products/trunk/client/bin64'

            else: #发布分支
                if 'classic' in self.strClientType:
                    self.work_path = os.path.join(root, os.sep, 'bin64_release_classic')
                else:
                    self.work_path = os.path.join(root, os.sep, 'bin64_release')
                    self.svnPath = 'https://xsjreposvr1.seasungame.com/svn/sword3-products/branches-rel/b_jx3_released_zhcn_hd/client/bin64'

    def update_todo_before(self, dic_args):
        # if os.path.exists(self.work_path):
        #     filecontrol_deleteFileOrFolder(self.work_path)
        if not os.path.exists(self.work_path):
            svn_cmd_checkout(self.svnPath, self.work_path, ver=self.ver, user=self.user, passw=self.passw)

    def update_todo_later(self, dic_args):
        self.move_bin64_folder()
        self.KGPK4_StreamDownloader()
        # 删除包外
        if self.bPAK:
            filecontrol_deleteFileOrFolder(os.path.join(self.CLIENT_PATH, 'settings'))
            filecontrol_deleteFileOrFolder(os.path.join(self.CLIENT_PATH, 'scripts'))

        # 挂一次性包外
        if "classic" not in self.strClientType and 'VK' not in  self.strClientType:
            dd = date_get_szToday()
            settings_path = os.path.join(self.CLIENT_PATH, 'settings')
            if dd == '2023-12-21':
                src = os.path.join(SERVER_PATH, 'GameWorldConstList.ini')
                dst = os.path.join(settings_path, 'GameWorldConstList.ini')
                filecontrol_copyFileOrFolder(src, dst)
        else:
            pass
            # BD画质开关处理
            #src = os.path.join(SERVER_PATH, 'videosettingvalid.txt')
            #dst = os.path.join(self.CLIENT_PATH, 'ui', 'Scheme', 'Case', 'videosettingvalid.txt')
        #filecontrol_copyFileOrFolder(src, dst)

        #缘起删除内网收集资源的dll
        if 'classic' in self.strClientType:
            filecontrol_deleteFileOrFolder(os.path.join(self.CLIENT_PATH, 'bin64', 'ResourceCollectionCheckerX64.dll'))
            filecontrol_deleteFileOrFolder(os.path.join(self.CLIENT_PATH, 'bin64', 'ResourceCollectionCheckerX64D.dll'))
        elif 'VK' in self.strClientType:
            #vk需要挂version_vk.cfg的包外
            filecontrol_copyFileOrFolder(SERVER_PATH+r'\XGame\version_vk.cfg',os.path.join(self.CLIENT_PATH,'version_vk.cfg'))
            strFolderPath=os.path.join(self.CLIENT_PATH, 'bin64_m', 'xg_200001158')
            filecontrol_createFolder(strFolderPath)
            with open(os.path.join(strFolderPath,'pc_jinshan_privacy.dat'), "w", encoding='utf8') as f:
                f.write('8000000000000')

        #挂包外 才能读取vk
        filecontrol_copyFileOrFolder(SERVER_PATH + r'\XGame\version_vk.cfg',os.path.join(self.CLIENT_PATH, 'version_vk.cfg'))
        #切换内网
        ini_set("vk_exp","getFile","http://10.11.39.60/v5/vk_exp/",os.path.join(self.CLIENT_PATH,"configHttpFile.ini"))
        #
        pass

def AutoRun(dic_parameters):
    global obj_test
    obj_test = CaseJX3UpdateBin64()
    obj_test.run_from_uauto(dic_parameters)


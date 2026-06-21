# -*- coding: utf-8 -*-

from CaseJX3SvnUpdate import *
#

class CaseJX3UpdateBin64(CaseJX3SvnUpdate):
    def __init__(self):
        super(CaseJX3UpdateBin64, self).__init__()

    def move_bin64_folder(self):
        PAKV4_CLIENT_PATH = self.CLIENT_PATH
        pakv4_bin64 = os.path.join(PAKV4_CLIENT_PATH, 'bin64')
        filecontrol_deleteFileOrFolder(pakv4_bin64)
        # while os.path.exists(pakv4_bin64):
        #     try:
        #         os.system('rd "{0}" /S /q'.format(pakv4_bin64))
        #     except Exception as e:
        #         self.log.exception(e)
        #     time.sleep(1)

        shutil.copytree(self.work_path, pakv4_bin64, ignore=shutil.ignore_patterns('.svn'))
        print('bin64 has been copied to PakV4 client.')
        # path_shaderListUpload = os.path.join(pakv4_bin64, 'ShaderListUpload')
        # filecontrol_deleteFileOrFolder(path_shaderListUpload)
        path_CachedShaders = os.path.join(self.CLIENT_PATH, 'CachedShaders')
        # filecontrol_deleteFileOrFolder(path_CachedShaders)
        path_exgidata = os.path.join(self.CLIENT_PATH, 'data', 'exgidata')
        if not os.path.exists(path_exgidata):
            src = os.path.join(SERVER_PATH, 'data', 'exgidata')
            dst = path_exgidata
            filecontrol_copyFileOrFolder(src, dst)
        # filecontrol_deleteFileOrFolder(path_exgidata)
        path_material = os.path.join(self.CLIENT_PATH, 'data', 'material')
        if not os.path.exists(path_material):
            src = os.path.join(SERVER_PATH, 'data', 'material')
            dst = path_material
            filecontrol_copyFileOrFolder(src, dst)
        # filecontrol_deleteFileOrFolder(path_material)


    def KGPK4_StreamDownloader(self):
        if 'classic' in self.clientType:
            filecontrol_copyFileOrFolder(SERVER_MAINSCRIPT + '/KGPK4_StreamDownloader.classic_exp.conf',
                                         self.CLIENT_PATH + '/' + self.BIN64_NAME + '/KGPK4_StreamDownloader.classic_exp.conf')
        else:
            pakv4_bin64 = self.CLIENT_PATH + '\\bin64'
            f = open(pakv4_bin64 + r'\KGPK4_StreamDownloader.zhcn_exp.conf')
            allfile = f.read()
            allfile = allfile.replace(
                # 'StreamDownload.BaseUrl_0=jx3v4qqcs-miniupdate.dl.kingsoft.com/jx3hd_v4_mini/',
                'StreamDownload.BaseUrl_0=jx3v4qqcs-miniupdate.xoyocdn.com/jx3hd_v4_mini/',
                'StreamDownload.BaseUrl_0=jx3.kingsoft.net/v4/stream/jx3hd_v4_mini/'
            )
            allfile = allfile.replace('StreamDownload.BaseUrl_1=jx3v4kscs-miniupdate.xoyocdn.com/jx3hd_v4_mini/', '')
            allfile = allfile.replace('StreamDownload.BaseUrl_2=jx3v4hwcs-miniupdate.xoyocdn.com/jx3hd_v4_mini/', '')

            f.close()
            f = open(pakv4_bin64 + r'\KGPK4_StreamDownloader.zhcn_exp.conf', 'w')
            f.write(allfile)
            f.close()

    def set_work_path(self, dic_args):
        #本地checkout库
        x = os.path.realpath(__file__)
        root = x.split('\\')[0]
        if self.bEXP:
            if 'classic' in  self.clientType:
                self.work_path = os.path.join(root, os.sep, 'bin64_classic')
                self.svnPath = 'https://xsjreposvr4.seasungame.com/svn/sword3-products_Classic/trunk/client/bin64'
            else:
                self.work_path = os.path.join(root, os.sep, 'bin64')
                self.svnPath = 'https://xsjreposvr1.seasungame.com/svn/sword3-products/trunk/client/bin64'
        else: #发布分支
            if 'classic' in self.clientType:
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
        pass

if __name__ == '__main__':
    oob = CaseJX3UpdateBin64()
    oob.run_from_IQB()
# coding=utf-8
from CaseJX3Client import *
from BaseToolFunc import *


class CaseJX3SvnUpdate(CaseJX3Client):
    """
    此用例为svn更新操作的基类，有需要进行svn更新的可以继承并重写此类方法
    """
    def __init__(self):
        super(CaseJX3SvnUpdate, self).__init__()
        # Todo:self.ver和self.work_path需要在子类中声明或者实现set_work_path函数
        self.ver = None
        self.work_path = None

        pass

    def set_work_path(self, dic_args):
        # Todo:可以重写方法设置self.work_path的值
        """
        可以重写方法设置self.work_path的值
        :param dic_args:
        :return:
        """
        pass

    def update_todo_before(self, dic_args):
        # Todo:可以重写方法设置更新前需要做的额外事情
        """
        可以重写方法设置更新前需要做的额外事情
        :param dic_args:
        :return:
        """
        pass

    def update_todo_later(self, dic_args):
        # Todo:可以重写方法设置更新后需要做的额外事情
        """
        可以重写方法设置更新后需要做的额外事情
        :param dic_args:
        :return:
        """
        pass

    def check_dic_args(self, dic_args):
        super().check_dic_args(dic_args)
        self.strClientType=dic_args['clientType']
        self.user = SVN_USER
        self.passw = SVN_PASS
        if 'user' in dic_args:
            self.user = dic_args['user']
        if 'passw' in dic_args:
            self.passw = dic_args['passw']
        self.ver = None
        if 'bvt' in dic_args and dic_args['bvt']:
            if 'classic' in self.strClientType:
                bvt = svn_get_bvt_version_classic()
                while not bvt:
                    self.log.info(u'等待今天BVT... 600s后自动尝试 loop...')
                    time.sleep(600)
                    bvt = svn_get_bvt_version_classic()
            elif 'XGame_VK' in self.strClientType:
                bvt = svn_get_bvt_version_xgame()
            else:
                bvt = svn_get_bvt_version()
            if bvt:
                self.ver = bvt[1]
            else:
                pass
                #raise Exception('no BVT!')
                #重制版没有bvt就算了
                # 如果有参数r，优先使用参数r版本
        if 'ver' in dic_args:
            self.ver = dic_args['ver']

    def run_local(self, dic_args):
        win32_kill_process('SeasunGame.exe')
        win32_kill_process('XLauncherKernelClassic.exe')
        win32_kill_process('KGPK4_StreamDownloaderX64.exe')
        win32_kill_process('JX3ClientX64.exe')
        self.log.info('check_dic_args')
        self.check_dic_args(dic_args)
        self.log.info('setClientPath')

        self.setClientPath(self.strClientType)  # 指定客户端位置
        self.set_work_path(dic_args)
        self.update_todo_before(dic_args)
        svn_cmd_cleanup(self.work_path)
        svn_cmd_update(self.work_path, ver = self.ver, user = self.user, passw = self.passw)
        self._save_package_version(self.ver)
        self.update_todo_later(dic_args)
        self.teardown()

    def teardown(self):
        win32_kill_process('JX3ClientX64.exe')
        win32_kill_process('KGPK4_StreamDownloaderX64.exe')
        win32_kill_process('SeasunGame.exe')
        win32_kill_process('XLauncherKernel.exe')
        win32_kill_process('XLauncherKernelClassic.exe')
        win32_kill_process('svn.exe')
        pass


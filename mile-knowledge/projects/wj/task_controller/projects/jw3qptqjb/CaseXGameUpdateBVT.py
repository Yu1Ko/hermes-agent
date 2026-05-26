# -*- coding: utf-8 -*-

from CaseJX3SvnUpdate import *
#

class CaseXGameUpdateBVT(CaseJX3SvnUpdate):
    def __init__(self):
        super(CaseXGameUpdateBVT, self).__init__()

    def set_work_path(self, dic_args):
        #本地checkout库
        self.work_path = self.CLIENT_PATH
        self.svnPath = 'https://xsjreposvr1.seasungame.com/svn/sword3-products/branches/b_jx3_dev_bd_2023-01-28/client'
        self.log.info(self.work_path)
        self.log.info(self.svnPath)

    def update_todo_before(self, dic_args):
        win32_kill_process('JX3ClientX3DX64.exe')
        win32_kill_process('JX3ClientX64.exe')
        win32_kill_process('KGPK4_StreamDownloaderX64.exe')
        win32_kill_process('SeasunGame.exe')
        pass

    def update_todo_later(self, dic_args):
        svn_cmd_revert(self.work_path)
        svn_cmd_cleanup(self.work_path)
        pass

if __name__ == '__main__':
    oob = CaseXGameUpdateBVT()
    oob.run_from_IQB()
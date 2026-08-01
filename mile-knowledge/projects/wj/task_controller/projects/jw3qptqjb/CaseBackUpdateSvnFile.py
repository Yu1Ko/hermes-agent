# -*- coding: utf-8 -*-
import re
import time

from CaseCommon import *
from datetime import date, timedelta
from BaseToolFunc import *



class CaseBackUpdateSvnFile(CaseCommon): #用例名字需要和文件名一致！ 所有用例需要继承CaseCommon类
    def __init__(self):
        CaseCommon.__init__(self)
        self.nUpdateTime=4
        self.bUpdateImmediate=True

    def update_svn_file(self):
        # 是否解除帧率限制
        list_filePath=['https://xsjreposvr1.seasungame.com/svn/sword3-products/trunk/client/config.ini',
                       'https://xsjreposvr1.seasungame.com/svn/sword3-products/trunk/client/version_vk.cfg',
                       'https://xsjreposvr1.seasungame.com/svn/sword3-products/trunk/client/mui/Lua/Debug/GM']
        try:
            self.log.info("解除帧率限制")
            strLocalPath = os.path.realpath(__file__)
            strBasePath = os.path.join(strLocalPath.split('\\')[0], os.sep, 'SVN')
            strWorkPath = os.path.join(strBasePath, date_get_szToday() + '_Update')
            strSharePath=SERVER_PATH+'\XGame'
            filecontrol_deleteFileOrFolder(strWorkPath)
            filecontrol_createFolder(strWorkPath)
            for strSVNPath in list_filePath:
                # svn_cmd_export(strSVNPath, None, strWorkPath, user=SVN_USER, passw=SVN_PASS)
                svn_cmd_export(strSVNPath, None, strWorkPath)
                strFileName = strSVNPath.split('/')[-1].strip()
                strLocalPath1 = os.path.join(strWorkPath, strFileName)
                strSharePath1 = strSharePath + f'\\{strFileName}'
                self.log.info(f'local:{strLocalPath1}')
                self.log.info(f'share:{strSharePath1}')
                filecontrol_copyFileOrFolder(strLocalPath1, strSharePath1)
        except Exception as e:
            info = traceback.format_exc()
            self.log.info(info)


    def run_local(self, dic_args):  #用例的主体（入口）函数，dic_args是从IQB平台传来的参数字典
        if self.bUpdateImmediate:
            self.update_svn_file()
        while True:
            if datetime.datetime.now().hour == self.nUpdateTime:
                self.update_svn_file()
            sleep_heartbeat(59)

if __name__ == '__main__':
    obj_test = CaseBackUpdateSvnFile()
    obj_test.run_from_IQB()



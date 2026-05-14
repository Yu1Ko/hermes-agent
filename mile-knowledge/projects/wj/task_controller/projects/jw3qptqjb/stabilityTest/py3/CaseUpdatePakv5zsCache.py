# -*- coding: utf-8 -*-
# from BaseToolFunc import *
import os
import sys

sys.path.append(os.path.dirname(sys.path[0]))
from CaseJX3SvnUpdate import *


class CaseUpdatePakv5zsCache(CaseJX3SvnUpdate):
    def __init__(self):
        super(CaseUpdatePakv5zsCache, self).__init__()
        self.tagMachineType = None
        self.PakV5_path = None

    def loadDataFromLocalConfig(self, dic_args):
        # 获取配置文件中的相关信息
        self.pathLocalConfig = os.path.join(dic_args['pathClient'], 'LocalConfig.ini')
        strSection = 'perfmon_info'
        # 获取机器类型 Ios Android PC
        self.tagMachineType = ini_get(strSection, 'machine_type', self.pathLocalConfig)
        # 检测设备类型合法性
        list_strMachineType = ['Ios', 'Android', 'PC']
        if self.tagMachineType not in list_strMachineType:
            raise Exception(f"设备类型错误:{self.tagMachineType},必须为:Ios Android PC")

    def set_work_path(self, dic_args):
        self.loadDataFromLocalConfig(dic_args)
        if 'Android' == self.tagMachineType:
            device_path = os.path.abspath(os.path.join(os.getcwd(), "../../.."))
            self.PakV5_path = device_path + r'\PakV5'
            self.work_path = self.PakV5_path
            self.svnPath = 'https://xsjreposvr1.seasungame.com/svn/sword3-products/trunk/tools/PakV5'
        elif 'PC' == self.tagMachineType:
            self.log.info("machine_type:pc")
        else:
            self.log.info("machine_type:ios")

    def update_todo_before(self, dic_args):  # 更新前需要做的额外事情
        if not os.path.exists(self.work_path):
            svn_cmd_checkout(self.svnPath, self.work_path, ver=self.ver, user=self.user, passw=self.passw)

    def update_todo_later(self, dic_args):  # 更新后
        pass


if __name__ == '__main__':
    obj = CaseUpdatePakv5zsCache()
    obj.run_from_IQB()

# -*- coding: utf-8 -*-
# from BaseToolFunc import *
import os
import sys

sys.path.append(os.path.dirname(sys.path[0]))
from CaseJX3SvnUpdate import *


class CaseUpdateXgameDebug(CaseJX3SvnUpdate):
    def __init__(self):
        super(CaseUpdateXgameDebug, self).__init__()
        self.tagMachineType = None
        self.Asan_path = None

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
            self.Asan_path = device_path + r'\Pak_Xgame_Andriod_Debug'
            self.work_path = self.Asan_path
            self.svnPath = 'svn://10.11.80.152/jx3svn/ClientTools/R3MessageMonitor/Product/Pak_Xgame_Andriod_Debug'
        elif 'PC' == self.tagMachineType:
            self.log.info("pc端Asan还有点问题，晚点在跑吧。。。")
        else:
            self.log.info("还没有ios的Asan_pak包")

    def update_todo_before(self, dic_args):  # 更新前需要做的额外事情
        if not os.path.exists(self.work_path):
            svn_cmd_checkout(self.svnPath, self.work_path, ver=self.ver, user=self.user, passw=self.passw)

    def update_todo_later(self, dic_args):  # 更新后 删掉jemallocX64.dll
        pass


if __name__ == '__main__':
    obj = CaseUpdateXgameDebug()
    obj.run_from_IQB()

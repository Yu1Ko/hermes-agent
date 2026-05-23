import os
import sys
sys.path.append(os.path.dirname(os.path.realpath(__file__)))
from CaseJX3SvnUpdate import *


class CaseXGameUpdateAsan(CaseJX3SvnUpdate):
    def __init__(self):
        super().__init__()
        self.Asan_version = None
        self.user = r"zhouxingxu"
        self.passw = r"l8G81k8t"


    def FindWorkPath(self,dic_args):
        # 相关路径
        dic_devices_data = dic_args["devices_custom"]
        #deviceId = dic_devices_data['local']['deviceId']
        deviceId = dic_args['device']
        # 获取机器类型 Ios Android PC
        tagMachineType = dic_devices_data['perfmon_info']['machine_type']
        # 检测设备类型合法性
        list_strMachineType = ['Ios', 'Android', 'PC']
        if tagMachineType not in list_strMachineType:
            raise Exception(f"设备类型错误:{tagMachineType},必须为:Ios Android PC")
        strBaseFolder = f"{tagMachineType}-{deviceId}"
        #Android-7a04353e
        strWorkPath = os.path.join(os.getcwd(), strBaseFolder)
        # 工作路径 (controller+strBaseFolder)
        # 脚本路径(原来的py3)
        strScriptPath = os.path.dirname(os.path.realpath(__file__))
        # (controller+strBaseFolder+'TempFolder')
        strTEMPFOLDER = os.path.join(strWorkPath, 'TempFolder')

        self.strWorkPath = strWorkPath


    def set_work_path(self, dic_args):
        self.FindWorkPath(dic_args)
        if 'Android' in  self.strClientType:
            self.work_path = os.path.join(self.strWorkPath, 'Pak_Xgame_Andriod_Asan')
            self.svnPath = 'svn://10.11.8.138/jx3test/Asan/Pak_Xgame_Andriod_Asan'
            self.log.info('更新svn:',self.svnPath)
        elif 'IOS' in  self.strClientType:
            self.log.info("还没有做ios的Asan_pak包")
        else:
            self.work_path = self.CLIENT_PATH + r'/bin64_Xgame_PC_Asan'
            self.svnPath = 'svn://10.11.8.138/jx3test/Asan/bin64_Xgame_PC_Asan'

    def update_todo_before(self, dic_args):  # 更新前需要做的额外事情
        self.user = r"zhouxingxu"
        self.passw = r"l8G81k8t"
        if not os.path.exists(self.work_path):
            svn_cmd_checkout(self.svnPath, self.work_path, ver=self.ver, user=self.user, passw=self.passw)
            self.log.info('checkout成功')

    def update_todo_later(self, dic_args):  # 更新后
        pass



def AutoRun(dic_parameters):
    global obj_test
    obj_test = CaseXGameUpdateAsan()
    obj_test.run_from_uauto(dic_parameters)

if __name__ == '__main__':
    obj = CaseXGameUpdateAsan()
    obj.run_from_IQB()

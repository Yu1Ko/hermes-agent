import sys
import os
import time
import datetime
import shutil
import subprocess
sys.path.append(r'../../../')
from CaseJX3SearchPanel import CaseJX3SearchPanel
from CaseJX3Client import *
from PerfeyeCtrl import *
from HotPointMapCtrl import *
from XGameSocketClient import *
import subprocess


class ADBTool(CaseJX3Client):
    def __init__(self):
        super().__init__()
        
    def run_adb_command(self, device_id, command):
        # 构建完整的 adb 命令
        full_command = f"adb -s {device_id} shell {command}"
        
        try:
            # 使用 subprocess.run 执行命令
            result = subprocess.run(full_command, shell=True, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            
            # 输出命令执行结果
            print("Command executed successfully.")
            print("Output:")
            print(result.stdout.decode('utf-8'))
        except subprocess.CalledProcessError as e:
            # 如果命令执行失败，输出错误信息
            print(f"Error executing command: {e}")
            print("Error output:")
            print(e.stderr.decode('utf-8'))

    def run_local(self, dic_args):
        self.check_dic_args(dic_args)  # 处理传进来的参数
        self.loadDataFromLocalConfig(dic_args)  # 读LocalConfig配置
        command = dic_args.get("adb_command")
        if command:
            self.run_adb_command(self.deviceId, command)
        else:
            return
        command_count = 1
        while True:
            command = dic_args.get(f"adb_command{command_count}")
            command_count += 1
            if command:
                self.run_adb_command(self.deviceId, command)
            else:
                return

        
if __name__ == '__main__':
    obj_test = ADBTool()
    obj_test.run_from_IQB()
# -*- coding: utf-8 -*-
# from BaseToolFunc import *
import os
import shutil
import subprocess
import sys

sys.path.append(os.path.dirname(sys.path[0]))
from CaseJX3SvnUpdate import *


class CaseXgameDownloadDLC(CaseJX3SvnUpdate):
    def __init__(self):
        super(CaseXgameDownloadDLC, self).__init__()
        self.version = None
        self.deviceId = None
        self.tagMachineType = None
        self.PakV5_path = None
        self.JX_BASE_PATH = r'/sdcard/Android/data/com.seasun.jx3/files'
        self.device_path = os.path.abspath(os.path.join(os.getcwd(), "../../.."))
        self.pull_dlc_path = os.path.join(self.device_path, r'PakV5\zsCache\other\pull_dlc')
        self.zsCache_path = self.pull_dlc_path + r'\zsCache'
        self.strGuid = machine_get_guid()  # 获取IQB设备的GUID 移动端设备根文件夹就是GUID 如:Android-79a0d4
        self.LaunchPakV5_cmd = None

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
        # 获取设备ID
        self.deviceId = ini_get('local', 'deviceId', self.pathLocalConfig)
        self.log.info(f'设备id:{self.deviceId}')
        # 获取资源版本
        if 'version' in dic_args:
            self.version = dic_args['version']

    def pullConfigHttpFile(self):
        self.log.info("============pull configHttpFile.ini==================")
        config_path = self.JX_BASE_PATH + r'/configHttpFile.ini'

        cmd = f"adb -s {self.deviceId} pull {config_path} {self.pull_dlc_path}"
        pi = subprocess.Popen(
            args=cmd, stdout=subprocess.PIPE,
            stderr=subprocess.PIPE)
        out, err = pi.communicate()
        print(f'pull configHttpFile.ini  out: {out}')
        print(f'pull configHttpFile.ini  err: {err}')
        self.log.info(f'pull configHttpFile.ini  out: {out}')
        self.log.info(f'pull configHttpFile.ini  err: {err}')
        if not err:
            self.log.info("============pull configHttpFile.ini Success==================")
        else:
            strMsg = f'获取配置文件失败'
            send_Subscriber_msg(self.strGuid, strMsg)
            return False

    def setVersion(self):
        if self.version:
            self.log.info("============set version==================")
            configHttpFilePath = os.path.join(self.pull_dlc_path, 'configHttpFile.ini')
            ini_set('android_bvt', 'version', self.version, configHttpFilePath)  # 修改资源版本
            self.log.info(f"修改资源版本为{self.version}")
            cmd = f"adb -s {self.deviceId} push {configHttpFilePath} {self.JX_BASE_PATH}"
            pi = subprocess.Popen(
                args=cmd, stdout=subprocess.PIPE,
                stderr=subprocess.PIPE)
            for line in iter(pi.stdout.readline, b''):
                line = line.decode('utf-8', 'ignore')
                print(line.split("\n")[0])
                self.log.info(line.split("\n")[0])
            out, err = pi.communicate()
            self.log.info("============set version Success==================")

    def downloadDLC(self):
        self.log.info("============DownloadDLC==================")
        conf_path = os.path.join(self.pull_dlc_path, 'configHttpFile.ini')
        zsCache_path = self.pull_dlc_path + r'\zsCache'
        if os.path.exists(zsCache_path):
            shutil.rmtree(zsCache_path)
        os.chdir(self.pull_dlc_path)  # 修改当前工作目录
        pullLog_path = self.pull_dlc_path + r'\pullLog.txt'
        self.log.info(f'pullLog_path  : {pullLog_path}')
        LaunchPakV5 = os.path.join(self.device_path, r"PakV5\bin\LaunchPakV5\LaunchPakV5.exe")
        if os.path.exists(pullLog_path):
            os.remove(pullLog_path)

        cmd = f'{LaunchPakV5} DownloadDLC {conf_path} 1 > {pullLog_path}'
        print(cmd)
        pi = subprocess.Popen(
            args=cmd, stdout=subprocess.PIPE,
            stderr=subprocess.PIPE)

        cmd = f'{LaunchPakV5} DownloadDLC {conf_path} 3 > {pullLog_path}'
        print(cmd)
        pi = subprocess.Popen(
            args=cmd, stdout=subprocess.PIPE,
            stderr=subprocess.PIPE)

        cmd = f'{LaunchPakV5} DownloadDLC {conf_path} 7 > {pullLog_path}'
        print(cmd)
        pi = subprocess.Popen(
            args=cmd, stdout=subprocess.PIPE,
            stderr=subprocess.PIPE)

        # for i in (1, 3, 7):
        #     cmd = f'{LaunchPakV5} DownloadDLC {conf_path} {i} > {pullLog_path}'
        #     print(cmd)
        #     pi = subprocess.Popen(
        #         args=cmd, stdout=subprocess.PIPE,
        #         stderr=subprocess.PIPE)

        for line in iter(pi.stdout.readline, b''):
            line = line.decode('utf-8', 'ignore')
            print(line.split("\n")[0])
            if "RunState : Fail" in line:
                self.log.info(f'资源下载失败')
                strMsg = f'资源下载失败'
                send_Subscriber_msg(self.strGuid, strMsg)
                return
            if "RunState : Success" in line:
                self.log.info(f'资源下载成功')
                break
        out, err = pi.communicate()
        self.LaunchPakV5_cmd = cmd  # 为了退出的时候杀死这个进程占用
        win32_kill_process_by_cmd('LaunchPakV5.exe', szCmdLine=cmd)
        self.log.info("============DownloadDLC Success==================")

    def pushCache(self):
        self.log.info("============push zsCache==================")
        print("上传资源到游戏中(push zsCache)......")
        cmd = f"adb -s {self.deviceId} push {self.zsCache_path} {self.JX_BASE_PATH}"
        pi = subprocess.Popen(
            args=cmd, stdout=subprocess.PIPE,
            stderr=subprocess.PIPE)
        for line in iter(pi.stdout.readline, b''):
            line = line.decode('utf-8', 'ignore')
            print(line.split("\n")[0])
            self.log.info(line.split("\n")[0])
        out, err = pi.communicate()
        self.log.info(f'push zsCache  out: {out}')
        self.log.info(f'push zsCache  err: {err}')
        if not err:
            self.log.info(f'资源上传成功')
            strMsg = f'已完成资源上传'
            send_Subscriber_msg(self.strGuid, strMsg)
        self.log.info("============push zsCache Success==================")

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
        self.pullConfigHttpFile()
        self.setVersion()
        self.downloadDLC()
        self.pushCache()

    def teardown(self):
        win32_kill_process_by_cmd('LaunchPakV5.exe', szCmdLine=self.LaunchPakV5_cmd)
        super().teardown()


if __name__ == '__main__':
    obj = CaseXgameDownloadDLC()
    obj.run_from_IQB()

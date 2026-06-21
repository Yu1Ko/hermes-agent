# -*- coding: utf-8 -*-
import os.path
import re
import subprocess
import time
import CaseCommon
from datetime import date, timedelta
from BaseToolFunc import *
from CaseJX3SearchPanel import *
import uiautomator2 as u2


class CaseXGameGetPakAsan(CaseJX3SearchPanel):
    def __init__(self):
        super().__init__()
        self.PakV5_path = None
        self.Asan_path = None
        self.strWorkPath = None
        self.JX_BASE_PATH = r'/sdcard/Android/data/com.seasun.jx3/files'

    def check_dic_args(self, dic_args):
        super().check_dic_args(dic_args)
        # 覆盖安装
        self.bOverlay = dic_args['overlay']

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

    def loadDataFromLocalConfig(self, dic_args):
        super().loadDataFromLocalConfig(dic_args)
        self.FindWorkPath(dic_args)
        if self.tagMachineType == 'Android':
            self.file_type = 'apk'
            self.Asan_path = self.strWorkPath + r'\Pak_Xgame_Andriod_Asan'
        elif self.tagMachineType == 'Ios':
            self.file_type = 'ipa'
        else:
            raise Exception(f"设备类型错误:{self.tagMachineType},必须为:Ios Android")

    def deal_with_install_exceptional_case(self, deviceId, t_parent):
        if '-' in deviceId:
            import wda
            wc = wda.USBClient(deviceId, port=8100, wda_bundle_id='com.facebook.WebDriverAgentRunner.xctrunner')
            while t_parent.is_alive():
                if wc.alert.exists:
                    strBtnName = wc.alert.buttons()[0]
                    wc.alert.click(wc.alert.buttons())
                    self.log.info(f"点击 {strBtnName}")
                time.sleep(1)
            wc.close()
        else:
            # 处理安装apk时出现的特殊情况
            d = u2.connect_usb(self.deviceId)
            # 检测设备的u2服务是否启动
            d.healthcheck()
            dic_deviceInfo = d.device_info
            # 停止并移除所有的监控，常用于初始化
            d.watcher.reset()
            d.watcher('allow_tp').when('允许').click()  # 自动点击系统弹窗,游戏可能会弹出什么提示
            d.watcher('allow_tp').when('是').click()  # 自动点击系统弹窗,游戏可能会弹出什么提示
            d.watcher.when('无限制').click()
            # 移除所有的监控
            # d.watcher.remove()

            # d.debug = True
            strBrand = dic_deviceInfo['brand'].lower()
            self.log.info(f'brand: {strBrand}')
            if strBrand == 'oppo' or strBrand == 'vivo':
                bTag = d(text='继续安装').exists
                nCount = 0
                while not bTag:
                    time.sleep(10)
                    bTag = d(text='继续安装').exists
                    nCount += 1
                    self.log.info("%s 继续安装 try %d" % (strBrand, nCount))
                self.log.info(f"{strBrand} 点击继续安装")
                time.sleep(10)
                d(text='继续安装').click()
                time.sleep(10)

                bTag = d(text='允许').exists
                nCount = 0
                while not bTag:
                    time.sleep(10)
                    bTag = d(text='允许').exists
                    nCount += 1
                    self.log.info("%s 允许 try %d" % (strBrand, nCount))
                self.log.info(f"{strBrand} 点击允许")
                d(text='允许').click()
                time.sleep(10)

    def set_package(self, dic_args):
        if not self.bOverlay and self.mobile_device.find_app():
            self.mobile_device.kill_app()
            self.mobile_device.uninstall_app()
            self.log.info('uninstall_app')
        time.sleep(10)
        apk_name = 'app-debug.'
        # if 'isDebug' in dic_args and dic_args['isDebug'] == True:
        #     apk_name = 'app-debug.'
        self.mobile_device.install_app(
            os.path.join(self.Asan_path,
                         apk_name + self.file_type), False)
        time.sleep(30)
        self.log.info('app install success')
        self.bCanStartClient = True
        # mobile_install_app(os.path.join(os.path.dirname(os.path.realpath(__file__)),'TempFolder','RunMap.'+self.file_type),self.deviceId)
        # time.sleep(10)
        # self.log.info("set_package success")
        # 启动apk
        # res = mobile_start_app(self.package, self.deviceId)
        # time.sleep(60)
        # 关闭apk
        # mobile_kill_app(self.package, self.deviceId)

    def task_mobile(self):
        if not self.bMobile:
            return
        sleep_heartbeat(2)
        self.bRunMapEnd = True
        time.sleep(10)
        self.mobile_device.kill_app()
        # mobile_kill_app(self.package,self.deviceId)
        self.log.info('mobile wait end')

    def add_thread_for_searchPanel(self, dic_args):
        # perfeye线程 目前perfeye会出现连接server失败 导致用例退出
        # t = threading.Thread(target=self.thread_SearchPanelPerfEyeCtrl,
        # args=(dic_args, threading.currentThread(),))
        # self.listThreads_beforeStartClient.append(t)
        # app运行状态监控与宕机线程
        t = threading.Thread(target=self.thread_CheckAppRunStateAndCrash,
                             args=(dic_args, threading.currentThread(),))
        self.listThreads_beforeStartClient.append(t)

        # 用例超时检查线程
        t = threading.Thread(target=self.thread_CheckTaskTimeOut,
                             args=(dic_args, threading.currentThread(),))
        self.listThreads_beforeStartClient.append(t)

        # 异常处理线程
        t = threading.Thread(target=self.thread_DealWith_ExceptionMsg,
                             args=(dic_args, threading.currentThread(),))
        self.listThreads_beforeStartClient.append(t)

        # 处理设备弹窗
        t = threading.Thread(target=self.mobile_device.thread_DealWithMobileWindow,
                             args=(threading.currentThread(),))
        self.listThreads_beforeStartClient.append(t)

    # 上传格子图资源
    def push_gzt_data(self):
        gzt_data = r'\\xsjqcres.kingsoft.cn\xsjqcres\xiejieshi\配置\格子图资源'
        cmd = f"adb -s {self.deviceId} push {gzt_data} {self.JX_BASE_PATH}"
        pi = subprocess.Popen(
            args=cmd, stdout=subprocess.PIPE,
            stderr=subprocess.PIPE)
        for line in iter(pi.stdout.readline, b''):
            line = line.decode('utf-8', 'ignore')
            print(line.split("\n")[0])
            self.log.info(line.split("\n")[0])
        out, err = pi.communicate()
        self.log.info(f'push  out: {out}')
        self.log.info(f'push  err: {err}')
        if not err:
            self.log.info(f'资源上传成功')
        

    def run_local(self, dic_args):
        self.check_dic_args(dic_args)
        self.loadDataFromLocalConfig(dic_args)
        self.copyPerfeye()
        self.add_thread_for_searchPanel(dic_args)
        self.process_threads_beforeStartClient()
        self.set_package(dic_args)
        self.start_client_test(dic_args)
        self.push_gzt_data()
        self.task_mobile()


def AutoRun(dic_parameters):
    global obj_test
    obj_test = CaseXGameGetPakAsan()
    obj_test.run_from_uauto(dic_parameters)


def Clear():
    obj_test.teardown()


if __name__ == '__main__':
    obj = CaseXGameGetPakAsan()
    obj.run_from_IQB()

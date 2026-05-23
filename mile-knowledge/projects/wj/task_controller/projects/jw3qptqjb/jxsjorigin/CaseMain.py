# -*- coding: utf-8 -*-

import os
import sys
import importlib
# 将父目录加入Python路径
sys.path.append(os.path.dirname(os.path.dirname(__file__)))
sys.path.append(os.path.dirname(__file__))
import runpy
import shutil

from CaseCommon import * # 现在可以正常导入
from BaseToolFunc import *
from Op import *
from mobile_device_controller import *
print(GetTEMPFOLDER())
import json
from PerfeyeCtrl import *
class CaseMain(CaseCommon):

    def __init__(self):
        super().__init__()
        self.strWeixinToolPath=None
        self.strProjectPath=None
        self.deviceId =None
        self.script_dir=os.path.dirname(os.path.abspath(__file__))
        self.mobile_device =None
        self.iniConfig=None
        self.strException=None
        self.Debug=False   #False默认自动化拉起,True则手动拉起

    def ini_parameters(self):
        self.deviceId = self.args['device']

        list_strMachineType = ['Ios', 'Android', 'PC'] #平台
        self.strMachineType=None
        for strMachineType in list_strMachineType:
            if strMachineType.lower()==self.args["platform"].lower():
                self.strMachineType=strMachineType
                break
        if not self.strMachineType:
            raise Exception(f"设备类型错误:{self.args['platform']},必须为:'Ios', 'Android', 'PC'")

        if "Debug" in self.args and self.args['Debug']:
            # 手动拉起 远程调试
            self.Debug= True

        #支付宝"com.eg.android.AlipayGphone"  微信"com.tencent.mm"
        if "package" in self.args and self.args['package']:
            self.package=self.args['package']
        else:
            if self.strMachineType=="Android":
                self.package = "com.tencent.mm"
            else:
                self.package="com.tencent.xin"
        self.mobile_device = Android_IOS(self.deviceId,self.package,self.args['wda_u2'])
        self.mobile_device.unlock()
        self.iniConfig=os.path.join(GetWorkPath(), "tool_config.ini")
        self.strCaseName=self.args['name']
        #初始化perfeye
        self.nScreenshot_Interval=2 #截图时间间隔

        self.AppKey=self.args['appKey'] #上传项目
        self.perfeye=None
        self.clientPID = None
        self.bPerfeyeStart=False
        self.bPerfeyeStop=False
        self.bPerfeyeStartSuccess=False
        self.bPerfeyeStopSuccess = False
        t = threading.Thread(target=self.thread_SearchPanelPerfEyeCtrl,args=(self.args, threading.currentThread(),))
        t.setDaemon(True)
        t.start()


    def run_local(self, dic_args):
        self.ini_parameters()
        self.update_miniapp()
        self.start_miniapp()
        self.run_case()
        pass

    def extract_final_error_traceback(self,log_file_path):
        """
        从日志文件中提取 name 为 "Final Error" 的 traceback 信息。

        参数:
            log_file_path (str): 日志文件路径。

        返回:
            str: traceback 字段内容，如果未找到则返回 None。
        """
        try:
            with open(log_file_path, 'r', encoding='utf-8') as file:
                for line in file:
                    line = line.strip()
                    if not line:
                        continue
                    try:
                        log_entry = json.loads(line)
                        print(log_entry)
                        if (log_entry.get('data', {}).get('name') == 'Final Error'):
                            return log_entry.get('data', {}).get('traceback')
                    except json.JSONDecodeError:
                        continue
        except FileNotFoundError:
            print(f"文件未找到: {log_file_path}")
        except Exception as e:
            print(f"处理文件时出错: {e}")
        return None

    def thread_SearchPanelPerfEyeCtrl(self, dicSwitch, t_parent):
        self.log.info("thread_SearchPanelPerfEyeCtrl start")
        try:
            bPerfeyeTest=False
            if 'PerfeyeTest' in dicSwitch:
                bPerfeyeTest=dicSwitch['PerfeyeTest']
            self.perfeye=PerfeyeControl(deviceId=self.deviceId,bPerfeyeTest=bPerfeyeTest,strPackageName=self.package,nScreenshot_Interval=self.nScreenshot_Interval,strMachineTag=self.strMachineType,strAppKey=self.AppKey,strOsVersion=self.args["osVersion"],Perfeye_ver="Perfeye-3.3.5-release",publicShare=True)
            self.perfeye.PerfeyeCreate()
            self.args['perfeyePid']=self.perfeye.PerfeyePid()
            self.perfeye.PerfeyeConnect()
            #self.perfeye=self.args['perfeye']
            self.bCanStartClient=True
            #启动app成功后再开启采集数据
            while not self.clientPID:
                time.sleep(2)
            time.sleep(10)
            strIpAddress=self.mobile_device.get_address()
            self.log.info(f"IP:{strIpAddress}")
            self.perfeye.PerfeyeStart(self.clientPID)
            #self.perfeye.PerfeyeStart(self.clientPID,data_types,self.nScreenshot_Interval,self.bMobile)
            self.bPerfeyeStartTimeOutFlag=False #超时检查线程处理
            self.log.info("perfeye_startTime:" + str(time.time()))
            nTimerKeepHeart=0
            nTimerCheckPerfeye = 0
            nTimerRunMapEnd=0
            nCheckPerfeye=1
            self.bPerfeyeStartSuccess=True
            nStepTime=0.1
            while t_parent.is_alive():
                # 解决HD hook慢导致采集数据缺失的问题
                if nTimerCheckPerfeye>=nCheckPerfeye:
                    nTimerCheckPerfeye=0
                    if self.bPerfeyeStart:
                        self.bPerfeyeStart=False
                         # 调用两次防止失效
                        self.perfeye.PerfeyeSetTimeNode()
                        self.log.info(f"perfeye_SetTimeNodeTime:{int(time.time())}")
                    if self.bPerfeyeStop:
                        self.bPerfeyeStop = False
                        self.log.info(f"perfeye_StopTime:{int(time.time())}")
                        self.perfeye.PerfeyeStop()
                        self.bPerfeyeStopSuccess= True
                        break
                elif nTimerKeepHeart > 120:
                    self.log.info('SearchPanelPerfEyeCtrl heart')
                    nTimerKeepHeart = 0
                nTimerRunMapEnd+=nStepTime
                nTimerKeepHeart+=nStepTime
                nTimerCheckPerfeye+=nStepTime
                time.sleep(nStepTime)
            self.log.info("thread_SearchPanelPerfEyeCtrl stop")
        except Exception as e:
            self.strExceptionFlag="perfeye_error"
            info = traceback.format_exc()
            self.log.info(info)


    def update_miniapp(self):
        #每个人配置的环境不一样因此用本地配置表的环境
        if self.Debug:
            return
        if not filecontrol_existFileOrFolder(self.iniConfig):
            with open(self.iniConfig, 'w') as f:
                pass
            ini_set("Main", "WeixinToolPath", "", self.iniConfig)
            ini_set("Main", "ProjectPath", "", self.iniConfig)
            ini_set("Main", "OpPath", "", self.iniConfig)
            raise Exception(f"请在{self.iniConfig}配置 微信开发者工具路径、项目路径、op工具路径")
        #self.strWeixinToolPath=find_files_in_folder('微信开发工具')
        self.strWeixinToolPath="E:\Tools\微信开发工具"
        self.strWeixinToolPath=ini_get("Main","WeixinToolPath",self.iniConfig)
        print(self.strWeixinToolPath)
        #self.strProjectPath = find_files_in_folder('wechat')
        self.strProjectPath=r"E:\BrowserDownLoad\minigame_1.8.9.1.174132\1.8.9\wechat"
        self.strProjectPath=ini_get("Main","ProjectPath",self.iniConfig)
        print(self.strProjectPath)
        #self.strOpPath=find_files_in_folder("op")
        self.strOpPath=r"C:\Users\kingsoft\Desktop\op"
        self.strOpPath=ini_get("Main","OpPath",self.iniConfig)
        #远程下载最新的压缩包进行更新 先空闲着
        pass

    def start_miniapp(self):
        #根据参数类型来判断释放需要自动化开启调试环境
        if self.Debug:
            # 手动拉起 远程调试
            self.log.info("手动拉起环境")
            self.clientPID = "mobile"
            pass
        else:
            #使用微信开发工具启动app
            cmd=f"{os.path.join(self.strWeixinToolPath,'cli.bat')} auto --project {self.strProjectPath} --auto-port 9420"
            pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
            res = pi.stdout.read()
            try:
                res = str(res, encoding='gbk')
            except:
                res = str(res, encoding='utf8')
            print(res)
            time.sleep(40) #需要等待开发者工具初始化
            #启动设备上面的微信
            self.mobile_device.start_app()
            time.sleep(20)
            self.clientPID = "mobile"
            #设置开发者工具在最顶层
            list_process=win32_findProcessByName("微信开发者工具.exe")
            if not list_process:
                raise Exception(f"微信开发者工具启动失败 请检查路径:{self.strProjectPath}")

            #开启远程调试模式
            strPath = os.path.join(self.script_dir, "ImageSamples", "Debug1.png")
            print(strPath)
            #启动op:
            self.strOpPath=f"{os.path.join(self.strOpPath, 'install.bat')}"
            self.log.info(f"op path:{self.strOpPath}")
            #subprocess.run(self.strOpPath, shell=True)

            t=Op()
            #text=t.get_text_coordinate("真机调试")
            text=t.get_image_coordinate_center(strPath)
            print(text.x,text.y,text.text)

            x = text.x
            y = text.y
            win32api.SetCursorPos([x, y])
            win32api.mouse_event(win32con.MOUSEEVENTF_LEFTDOWN, x, y, 0, 0)
            win32api.mouse_event(win32con.MOUSEEVENTF_LEFTUP, x, y, 0, 0)

            time.sleep(3)
            strPath=os.path.join(self.script_dir,"ImageSamples","StartDebug.png")
            text = t.get_image_coordinate_center(strPath)
            print(text.x, text.y, text.text)
            x = text.x
            y = text.y
            win32api.SetCursorPos([x, y])
            win32api.mouse_event(win32con.MOUSEEVENTF_LEFTDOWN, x, y, 0, 0)
            win32api.mouse_event(win32con.MOUSEEVENTF_LEFTUP, x, y, 0, 0)
            time.sleep(60)

        #等待设备启动APP
        #拉起微信
        pass
        #E:\Tools\微信开发工具\cli.bat auto --project E:\BrowserDownLoad\minigame_1.8.9.1.174132\1.8.9\wechat  --auto-port 9420

    def run_case(self):
        self.caseName=self.args['CaseName']
        #runpy.run_path(f"Case/{self.caseName}") #直接airtestIDE导出
        #airtest run D:\GitHubProject\jw3qptqjb\jxsjorigin\Test\untitled.air --device Android://127.0.0.1:5037/IBU8EA9XWS9HSWPF
        self.strReportFolderPath=f"{self.script_dir}\ReportData\{self.caseName}"
        self.log.info(f"strReportFolderPath:{self.strReportFolderPath}")
        #运行 任务 需等待perfeye_connect成功:
        nTimeOut=300
        nTime=time.time()
        while not self.bPerfeyeStartSuccess:
            time.sleep(1)
            if time.time()-nTime>nTimeOut:
                raise Exception("perfeye_connect timeout")
        self.bPerfeyeStart=True #perfeye Start
        nTime = time.time()
        if self.strMachineType=="Android":
            cmd=f"airtest run {self.script_dir}/Case/{self.caseName}.air --device Android://127.0.0.1:5037/{self.deviceId} --log {self.strReportFolderPath}"
        else:
            cmd=f"airtest run {self.script_dir}/Case/{self.caseName}.air --device ios:///127.0.0.1:8100/{self.deviceId} --log {self.strReportFolderPath}"
        self.log.info(cmd)
        res=os_popen(cmd)
        self.log.info(f"cmd res:{res}")
        #导出 报告
        cmd=f"airtest report {self.script_dir}/Case/{self.caseName}.air --log_root {self.strReportFolderPath} --export {self.strReportFolderPath}"
        self.log.info(cmd)
        res=os_popen(cmd)
        self.log.info(f"cmd res:{res}")
        if time.time()-nTime<10:
            time.sleep(10)
        self.bPerfeyeStop = True #perfeye Stop 确保采集时长超过10秒 否者会报错
        self.strReportDataPath=f"{self.strReportFolderPath}/{self.caseName}.log"
        self.log.info(f"strReportDataPath:{self.strReportDataPath}")
        #判断日志中是否有错误
        self.strException = self.extract_final_error_traceback(os.path.join(self.strReportDataPath,"log","log.txt"))
        #上传报告
        #airtest run D:\GitHubProject\jw3qptqjb\jxsjorigin\Case\点击电话.air --device Android://127.0.0.1:5037/IBU8EA9XWS9HSWPF --log D:\GitHubProject\jw3qptqjb\jxsjorigin\ReportData\点击电话
        #airtest report D:\GitHubProject\jw3qptqjb\jxsjorigin\Case\点击电话.air --log_root D:\GitHubProject\jw3qptqjb\jxsjorigin\ReportData\点击电话 --export D:\GitHubProject\jw3qptqjb\jxsjorigin\ReportData\点击电话
        #压缩包
        # 创建 zip 压缩包
        shutil.make_archive(self.strReportDataPath, 'zip', self.strReportDataPath)
        self.args['func_add_custom_log_file'](f"{self.strReportDataPath}.zip")
        #清除本地数据
        #filecontrol_deleteFileOrFolder(self.strReportFolderPath)

        #上传perfeye数据 确保stop成功再save否者会报错
        while not self.bPerfeyeStopSuccess:
            time.sleep(1)
        bRetXGameUploadData, data = self.perfeye.PerfeyeSave(subtags=self.strCaseName,strVersion="1.0.0")
        if bRetXGameUploadData:
            self.args["perfeyeReport"] = data

        if self.strException:
            raise Exception(self.strException)

    def teardown(self):
        # d = "d368ec0f"
        # WDA_U2 = u2.connect_usb(d)
        # print(WDA_U2.app_current()['package'])
        # # com.tencent.mm
        # WDA_U2.app_stop(WDA_U2.app_current()['package'])
        # 结束小程序
        self.log.info('CaseMain_teardown start')
        if not self.Debug:
            self.mobile_device.kill_app()
            #结束微信开发者工具
            win32_kill_process("微信开发者工具.exe")
        if hasattr(self, 'perfeye') and self.perfeye:
            self.log.info('testplus.kill node2')
            #self.testplus.kill()
            self.perfeye.PerfeyeKill()
            #此处容易阻塞
            self.log.info('testplus.kill node3')
        super().teardown()
        self.log.info('CaseMain_teardown stop')




def AutoRun(dic_parameters):
    global obj_test
    obj_test = CaseMain()
    obj_test.run_from_uauto(dic_parameters)


def paddleocrOriginal(img_path):
    with open(img_path, 'rb') as f:
        img_base64_byte = base64.b64encode(f.read())
    server_path = 'http://10.11.176.78:8000/ocr'  # 13号机不太稳定
    server_path = 'http://10.11.181.236:8765/ocr'  # 2号机
    server_path = 'http://10.11.177.218:8765/ocr'  # 马力工作机2
    r = requests.post(server_path, data=img_base64_byte, timeout=60)
    r.raise_for_status()  # 如果返回状态码不是200，则抛出异常
    res = r.json()
    print(res)
    result = res['result']

    return result


def paddleocrOriginal(img_path):
    with open(img_path, 'rb') as f:
        img_base64_byte = base64.b64encode(f.read())
    server_path = 'http://10.11.177.218:8765/ocr'  # 马力工作机2
    r = requests.post(server_path, data=img_base64_byte, timeout=60)
    r.raise_for_status()  # 如果返回状态码不是200，则抛出异常
    res = r.json()
    result = res['result']
    return result

def paddleocrOriginalV5(img_path):
    with open(img_path, 'rb') as f:
        img_base64_byte = base64.b64encode(f.read())
    server_path = 'http://10.11.176.168:8764/ocr'  # 马力工作机
    r = requests.post(server_path, data=img_base64_byte, timeout=60)
    r.raise_for_status()  # 如果返回状态码不是200，则抛出异常
    res = r.json()
    print(res)
    result = res['result']
    return result


if __name__ == '__main__':

    dic_args={'runmaptype': 'WalkExteriorTemp', 'testpoint': '绘影清光-单人-成女', 'mapid': '108', 'newExterior': 1, 'hairstyle': '', 'Exterior': '', 'HairID': 1867, 'SetId': 4066, 'role_type': '成女', 'ip': '10.11.69.178', 'resourceVer': '10.11.146.62', 'nTimeout': 6000, 'casename': 'Point_成都外装性能测试_单人.tab', 'account': {}, 'quality': 2, 'name': '11.6外装测试-绘影清光-单人-成女', 'english_name': '外装测试', 'execute_times': 1, 'retry_times': 1, 'execute_time_out': 30, 'project_id': 'jw3qptqjb', 'file_path': 'CaseExteriorTest.py', 'device_name': 'XGame-性能监控-荣耀70（均衡）-XZD03655', 'device_type': '荣耀70', 'device_unique_identifier': 'AVKYVB2B09005226', 'device_identifier': 'AVKYVB2B09005226', 'device_ip': '10.11.236.94', 'platform': 'android', 'id': 9875, 'build_id': 114156, 'build_case_id': 564316, 'device_id': 502, 'appKey': 'jw3qptqjb', 'performance': {'perfeye': {}}, 'device': 'AVKYVB2B09005226', 'osVersion': '12', 'devices_custom': {'perfmon_info': {'video_level': '2', 'machine_type': 'Android', 'video_card': '荣耀70', 'CoolTemperature': 33}, 'AutoLogin': {'account': 'qwet12', 'password': '123456', 'RoleName': '', 'school_type': '', 'role_type': '成男', 'StepTime': '10000', 'Switch': '4', 'szDisplayRegion': '质量', 'szDisplayServer': 'TDR', 'CoolTemperature': 33, 'Resource': 1}, 'skilltest': {'mapCopyIndex': 4}},  'package': 'com.seasun.jx3', 'perfeye': None, 'perfeyePid': -1}
    #AutoRun()

    strWeixinToolPath = find_files_in_folder('微信开发工具',2)
    print(strWeixinToolPath)
    # import minium
    # mini = minium.Minium({
    #     "project_path": r"E:\BrowserDownLoad\minigame_1.8.9.1.174132\1.8.9\wechat",  # 替换成你的【小程序项目目录地址】
    #     "dev_tool_path": "E:\Tools\微信开发工具\cli.bat",  # 替换成你的【开发者工具cli地址】，macOS: <安装路径>/Contents/MacOS/cli， Windows: <安装路径>/cli.bat
    # })
    # print(mini.get_system_info())

    # strWeixinToolPath=find_files_in_folder('微信开发工具')
    # print(strWeixinToolPath)
    # strProjectPath = find_files_in_folder('wechat')
    # print(strProjectPath)
    # cmd=f"{os.path.join(strWeixinToolPath,'cli.bat')} auto --project {strProjectPath} --auto-port 9420"
    #
    # cmd=r"E:\Tools\微信开发工具\cli.bat auto --project E:\BrowserDownLoad\minigame_1.8.9.1.174132\1.8.9\wechat --auto-port 9420"
    # pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
    # res = pi.stdout.read()
    # try:
    #     res = str(res, encoding='gbk')
    # except:
    #     res = str(res, encoding='utf8')
    # print(res)
    # time.sleep(40)
    # from Op import *
    # #真机调试点击
    # strPath=os.path.join(os.getcwd(),"ImageSamples","Debug1.png")
    # print(strPath)
    # #每次重启设备后需要重启这个op
    # t=Op()
    # text=t.get_image_coordinate_center(strPath)
    #
    # print(text.x,text.y,text.text)
    #
    # x = text.x
    # y = text.y
    # win32api.SetCursorPos([x, y])
    # win32api.mouse_event(win32con.MOUSEEVENTF_LEFTDOWN, x, y, 0, 0)
    # win32api.mouse_event(win32con.MOUSEEVENTF_LEFTUP, x, y, 0, 0)
    #
    # time.sleep(3)
    # strPath=os.path.join(os.getcwd(),"ImageSamples","StartDebug.png")
    # text = t.get_image_coordinate_center(strPath)
    # print(text.x, text.y, text.text)
    #
    # x = text.x
    # y = text.y
    # win32api.SetCursorPos([x, y])
    # win32api.mouse_event(win32con.MOUSEEVENTF_LEFTDOWN, x, y, 0, 0)
    # win32api.mouse_event(win32con.MOUSEEVENTF_LEFTUP, x, y, 0, 0)

    # strPath = os.path.join(os.getcwd(), "ImageSamples", "StopDebug.png")
    # text = t.get_image_coordinate_center(strPath)
    # print(text.x, text.y, text.text)
    #
    # x = text.x
    # y = text.y
    # win32api.SetCursorPos([x, y])
    # win32api.mouse_event(win32con.MOUSEEVENTF_LEFTDOWN, x, y, 0, 0)
    # win32api.mouse_event(win32con.MOUSEEVENTF_LEFTUP, x, y, 0, 0)

    import pyautogui
    import time

    print("按 Ctrl+C 结束程序")

    #paddleocrOriginal(strPath)
    #894 26
    # try:
    #     while True:
    #         x, y = pyautogui.position()
    #         print(x,y)
    #         print(f"X: {x}, Y: {y}", end="\r")  # \r 覆盖上一行
    #         time.sleep(1)
    # except KeyboardInterrupt:
    #     print("\n已退出")
    # import uiautomation as auto
    # # 获取窗口
    # window = auto.WindowControl(searchDepth=1,ClassName="Chrome_RenderWidgetHostHWND" )
    # print(window)
    # # 查找并点击按钮（按文本或AutomationId）
    # window.SetActive()
    # print(window.ProcessId)
    # button = window.ButtonControl(Name="编译")
    # if button.Exists(3):
    #     button.Click()
    # else:
    #     print("未找到按钮")

    print(os.path.dirname(os.path.dirname(__file__)))


import _thread
import ctypes
import importlib
import json
import multiprocessing
import os
import subprocess
import sys
import threading
import time
import traceback
from typing import *

import requests
import tidevice
from importlib_metadata import version

import gpu_temp
import pyfeishu
import record_android_trace
import uiautomator2 as u2
from ad_ios import Android_IOS as AdIo
from ad_ios import Wda_u2_operate as wu2
from FakeOut import FakeOut
from tp import TPlus


# 动态导入模块，需要加锁，避免同时两个项目在导入时由于 sys.path 里面添加了两个路径导致找错对应的模块
def get_module(paths, project_name, project_file_lock):
    
    print(project_name)
    print(paths)

    with project_file_lock:
        importlib.invalidate_caches()
        module_path = os.getcwd()
        module_path = os.path.join(module_path, "projects", project_name)

        print(module_path)
        sys.path.append(module_path)
        modules = []
        for path in paths:
            module = importlib.import_module(path)
            dir(module)
            modules.append(module)

        sys.path.remove(module_path)
        return modules

def get_Proflie_module(project_file_lock):
    with project_file_lock:
        importlib.invalidate_caches()
        module_path = os.getcwd()
        module_path = os.path.join(module_path, "UAutoProfilerTool")

        print(module_path)
        sys.path.append(module_path)
        module = importlib.import_module('Profile_test_new2')

        sys.path.remove(module_path)
        return module

def get_UE4_Proflie_module(project_file_lock):
    with project_file_lock:
        importlib.invalidate_caches()
        module_path = os.getcwd()
        module_path = os.path.join(module_path, "UAutoProfilerTool")

        print(module_path)
        sys.path.append(module_path)
        module = importlib.import_module('Profile_UE')

        sys.path.remove(module_path)
        return module

# 等待同步完成
# 该函数会被传入到自动化脚本里进行运行
def wait_sync_factory(task_running_id, case_id, device_id, bot,task_parameters,server_url,device_name):

    # 等待同步可以传入自定义参数，做游戏内信息同步（需要修改数据库）
    def wait_sync(args = None):
        bot.send_text(f"{device_id} 等待同步")
        while True:
            if 'team' in task_parameters.keys(): 
                response = requests.get(f"{server_url}/task_run/sync", params={
                "case_id": case_id,
                "device_id": device_id,
                "sync_args": args
            })
            else:
                response = requests.get(f"{server_url}/task_run/sync", params={
                "task_running_id": task_running_id,
                "case_id": case_id,
                "device_id": device_id,
                "sync_args": args
            })
        
            
            
            ret = json.loads(response.content)
            if ret["code"] != 200:
                # print(f"同步出错: {ret['msg']}")
                bot.send_text(f"{device_name}-{device_id} 同步出错: {ret['msg']}")
                raise Exception(f"同步出错: {ret['msg']}")
            else:
                data = ret["data"]

                # 本次同步完成
                if data["status"] == "finish":
                    bot.send_text(f"{device_name} 同步完成 {data}")
                    return {
                        "index": data["sync"],
                        "count": data["machine_count"],
                        "args": data["sync_args"]
                    }
                else:
                    print(f"等待同步: {data}")
            
            time.sleep(3)

    return wait_sync

class CaseStatus(object):
    # UNSTART = 0
    # WAITING = 1
    RUNNING = 2
    SUCCESS = 3
    FAIL = 4
    CANCEL = 5
    TIMEOUT = 7

    def __init__(self, server_url: str,task_running_id: int, task_parameters:dict, case_id:int, device_id:int, bot: pyfeishu.FeiShutalkChatbot, execute_time_out, device_s):
        self.case_status_lock = threading.Lock()
        self.server_url = server_url
        self.task_running_id= task_running_id
        self.task_parameters = task_parameters
        self.case_id = case_id
        self.device_id = device_id
        self.bot = bot
        self.execute_time_out = execute_time_out
        self.device_s = device_s
        self.status = CaseStatus.RUNNING

    
    def set_udriver(self, udriver):
        self.udriver = udriver

    def is_case_finish(self):
        with self.case_status_lock:
            return self.status != CaseStatus.RUNNING
        
    def start_check_sync(self):
        self.sync_thread = _thread.start_new_thread(self._check_sync, ())


    # 监控多人案例的同步状态是否正常
    def _check_sync(self):
        while True:
            # 案例完成，结束检查
            if self.is_case_finish():
                break
            if 'team' in self.task_parameters.keys(): 
                response = requests.get(f"{self.server_url}/task_run/sync_check", params={
                "case_id": self.case_id,
                "device_id": self.device_id
            })
            else:
                response = requests.get(f"{self.server_url}/task_run/sync_check", params={
                "task_running_id": self.task_running_id,
                "case_id": self.case_id,
                "device_id": self.device_id
            })
            
            ret = json.loads(response.content)

            # 检查出现异常
            if ret["code"] == 200:
                # 同步出现异常
                if ret["data"]["status"] == "error":
                    self.bot.send_text(f"{self.device_id} 检测出其他设备运行中同步失效 {ret['data']}")
                    # 通过断开 udriver 来使自动化脚本报错
                    self.udriver.stop()
                    break

            
            time.sleep(5)
    
    def start_check_timeout(self):
        self.timeout_thread = _thread.start_new_thread(self._check_timeout, ())

    def _check_timeout(self):
        startTime = 0
        while True:
            # 案例完成，结束检查
            if self.is_case_finish():
                break

            if startTime >= self.execute_time_out:
                print(f"{self.device_s} 案例超时")
                self.bot.send_text(f"{self.device_s} 案例超时")
                if self._change_case_status(CaseStatus.TIMEOUT):
                    self.udriver.stop()
                exit()
                break

            time.sleep(5)
            startTime += 5
    
    def _change_case_status(self, status):
        with self.case_status_lock:
            if self.status == CaseStatus.RUNNING:
                self.status = status
                return True
        return False
    
    def case_success(self):
        self._change_case_status(CaseStatus.SUCCESS)
    
    def case_fail(self):
        self._change_case_status(CaseStatus.FAIL)
    
    def upload_status(self, report_data, case_name):
        # 案例运行完成，上传结果
        if CaseStatus.SUCCESS == self.status:
            
            response = requests.post(f"{self.server_url}/task_run/case_success", json={
                "task_running_id": self.task_running_id,
                "device_id": self.device_id,
                "case_id": self.case_id,
                "report_data": str(report_data)
            })
            
            print(response.content.decode("utf-8"))
            
            # self.bot.send_text(f"案例成功{case_name}{self.device_s}")
            return True
        else:
            if CaseStatus.TIMEOUT == self.status:
                response = requests.post(f"{self.server_url}/task_run/case_timeout", json={
                    "task_running_id": self.task_running_id,
                    "device_id": self.device_id,
                    "case_id": self.case_id
                })
            
                print(response.content.decode("utf-8"))
            elif CaseStatus.FAIL == self.status:
                response = requests.post(f"{self.server_url}/task_run/case_fail", json={
                    "task_running_id": self.task_running_id,
                    "device_id": self.device_id,
                    "case_id": self.case_id
                })
            
                print(response.content.decode("utf-8"))
            # bot.send_text(f"{device_s} {case['name']} 案例失败，不再重新执行")
            print(f"{self.device_s} - {case_name} 案例失败，不再重新执行")
        return False

# TODO:确保主进程退出以后，任务子进程可以正常退出
class TaskRunProcess(multiprocessing.Process):
    def __init__(self, device_s, device_ip, platform, port, package_url,package_info,device_id,device_quality,task_running_id,task_parameters,project_id,feishu_token,project_file_lock,task_data,server_url,device_name,perfeyeport,perfeyeportlock,FinishTaskData,task_status_lock,udriver_port=13000):
        super(TaskRunProcess, self).__init__()
        self.device_s = device_s
        self.device_ip = device_ip
        self.platform = platform
        self.port = port
        self.udriver_port=udriver_port
        self.package_url = package_url
        self.package_info = package_info
        self.device_id = device_id
        self.device_quality = device_quality
        self.task_running_id = task_running_id
        self.task_parameters = task_parameters
        self.project_id = project_id
        self.feishu_token = feishu_token
        self.project_file_lock = project_file_lock
        self.task_data = task_data
        self.server_url = server_url
        self.device_name=device_name
        self.perfeyesuccessd=True
        #self.device_lock=device_lock
        self.perfeyeport=perfeyeport
        self.perfeyeportlock=perfeyeportlock
        self.FinishTaskData=FinishTaskData
        self.task_status_lock=task_status_lock
    # run 入口
    def run(self):

        try:

            log_lock = multiprocessing.Lock()
            fzhu = FakeOut(log_lock)
            sys.stdout = fzhu
            sys.stderr=fzhu
            devices=self.device_s.split(":")[0].replace ('.','') if "10." in self.device_s else self.device_s
            fzhu.add_output(threading.current_thread().ident,open(f'log_file/task{self.task_running_id}_{devices}.txt',"a+"))
            
            self.bot = pyfeishu.FeiShutalkChatbot(self.feishu_token)
            self.Android_IOS = AdIo(self.device_s, self.platform, self.package_url,self.package_info,self.project_file_lock,self.port)
            self.task_data["platform"] = self.platform
            self.task_data["package_url"] = self.package_url
            self.task_data["package_info"] = self.package_info
            self.task_data["port"] = self.port

            self.performance = {}
            self.report_data = {}

        except:
            print("任务运行子进程初始化错误")
            raise InterruptedError("任务运行子进程初始化错误")

        try:
            response = requests.get(f"https://uauto-api.testplus.cn/task_run/get_task_info", params={
                    "task_running_id": self.task_running_id
                }).json()["data"]
            self.bot.send_text(f"{self.device_name} 任务开始",response["name"],f"https://uauto2.testplus.cn/project/{self.project_id}/taskDetail?taskId={self.task_running_id}")

            # 更新项目脚本
            self.update_project_script()

            self.Android_IOS.unlock()
            self.Android_IOS.Pop_ups(10)
            if self.task_parameters != None:
                self.task_parameters = json.loads(self.task_parameters)
            # 尝试安装最新的包
            self.try_to_install_new_package()


            # 执行案例
            while True:
                

                # 获取案例信息
                #self.device_lock.acquire()
                response = requests.get(f"{self.server_url}/task_run/get_next_case", params={
                    "task_running_id": self.task_running_id,
                    "device_id": self.device_id
                })
                #self.device_lock.release()

                print(response.content.decode("utf-8"))

                case = json.loads(response.content)["data"]

                # 所有案例已完成，退出主体
                if case == None:
                    break

                # 案例间休息
                time.sleep(60)

                # 开始运行案例
                self.run_one_case(case)
            
            
            self.bot.send_text(f"{self.device_name} 任务结束")
            self.FinishTaskData.append(self.pid)
            print("任务结束")

        except:
            self.bot.send_card(f"{self.device_name}-{self.device_s} 任务出错",self.device_s,self.platform)
            self.Android_IOS.lock()
            self.FinishTaskData.append(self.pid)
            # TODO: 添加将设备改为空闲
            response = requests.post(f"{self.server_url}/device/free", json={
                "id": self.device_id
            })
            #self.device_lock.release()
            print(response.content.decode("utf-8"))

    # 更新项目脚本
    def update_project_script(self):
        with self.project_file_lock:
            ret = os.popen(f"git submodule update --remote projects/{self.project_id}").read()
            print(ret)
            return ret
    def getgamereversion(self,u3driver,udriver):
        #暂时仅jxsj3需要热更新版本号
        
        try:
            if self.project_id=="jxsj3":
                
            # 等待进入游戏
                print("更新资源中")
                while udriver.object_exist(u3driver.By.PATH,"//Main//UIMgr//UIResUpdate//PopPanel//UI//bg") or udriver.object_exist(u3driver.By.PATH,"/Main/UIMgr/UIResUpdate/PopTip/bg") or udriver.object_exist(u3driver.By.PATH,"/Main/UIMgr/UIResUpdate/PopPanel/Btn2"):
                    if udriver.object_exist(u3driver.By.PATH,"//Main/UIMgr/UIPopPanel_C/Content/Type1/Btn1"):
                        udriver.find_object(u3driver.By.PATH,"//Main/UIMgr/UIPopPanel_C/Content/Type1/Btn1").tap()
                    if udriver.object_exist(u3driver.By.PATH,"//Main/UIMgr/UIResUpdate/PopPanel/Btn2"):
                        udriver.find_object(u3driver.By.PATH,"//Main/UIMgr/UIResUpdate/PopPanel/Btn2").tap()
                    time.sleep(30)
                time.sleep(5)
                while not udriver.object_exist(u3driver.By.PATH, "//Main//UIMgr//UILogin_H//Denglu//Banben//Banbenhao"):
                    print("抓取热更新版本号")
                    time.sleep(5)
                version = udriver.find_object(u3driver.By.PATH, "//Main//UIMgr//UILogin_H//Denglu//Banben//Banbenhao").get_text()#第一次打开拿版本号
                version = version.split("/")[1]
                return version
                    # time.sleep(10)
        except Exception as e:
            print(e)
            raise e
    # 检查手机上是否已经安装对应的新包，如果已安装跳过安装，否则安装新包
    def try_to_install_new_package(self):
        # 默认后续是不需要安装的
        install_estimate = False
        # 判断是否安装这个包
        if self.Android_IOS.FindIPA_APK():
            # 获取手机里面的包信息
            existinfo=self.Android_IOS.get_info()
            # 判断两个包体版本是否相同
            if existinfo['versionName']!=self.Android_IOS.versionName:
                if "uninstall_program" in self.task_parameters:
                    if self.task_parameters["uninstall_program"] == 0:
                        print("设备包体不卸载")
                        install_estimate = True
                self.Android_IOS.UnInstall_IOS_IPA ()
        
        # 安装包体 并上传包信息到数据库
        if not self.Android_IOS.FindIPA_APK() or install_estimate:
            print("开始安装")
            self.Android_IOS.Install_IOS_IPA ()
            response = requests.post(f"{self.server_url}/task_run/upload_package_info", json={
                "task_running_id":self.task_running_id ,
                "package_info": json.dumps(self.Android_IOS.package_info)
                })
            print(response.content.decode("utf-8"))

        self.bot.send_text(f"{self.device_name} 安装的包版本: {self.Android_IOS.versionName}")
    def logupdata(self,case):
        try:
            print("日志上传ing")
            devices=self.device_s.split(":")[0].replace ('.','') if "10." in self.device_s else self.device_s
            log_filename = f"task{self.task_running_id}_{devices}.txt"
            files=[
                    ("files", (log_filename, open(f"log_file/{log_filename}", "rb")))
                ]
            start_time=time.localtime()
            filenumname=[9999999999,""]
            nextlog=True
            print(f"平台：{self.platform}")
            if "android" in self.platform:  
                try:
                    ex = Exception("没有权限")
                    dataf=os.popen(f"adb -s {self.Android_IOS.devices} shell \"cd /sdcard/Android/data/{self.Android_IOS.package}/files ; ls -l\"").read().splitlines()[1::]
                    if "Permission denied" in dataf:
                        raise ex
                    print(dataf)
                    if os.path.exists("./log_file/logbug_{devices}.txt"):
                        os.remove("./log_file/logbug_{devices}.txt")
                    os.popen(f"adb -s \"{self.Android_IOS.devices}\"  shell  \"logcat -d\" > \"./log_file/logbug_{devices}.txt\"")
                    time.sleep(20)
                    os.popen(f"adb -s \"{self.Android_IOS.devices}\"  shell  \"logcat -c\"")
                    files.append(("files",(f'auto_logbug_{self.task_running_id}.log', open(f"./log_file/logbug_{devices}.txt", "rb").read())))
                except:
                    print("获取不到设备包名路径下内容,检查连接状态和包名路径")
                    nextlog=False
                if nextlog:
                    pathlog="KGLog"
                    for file in dataf:
                        if file.split(" ")[-1]=="Logs":
                            pathlog=f"Logs/{time.strftime('%Y-%m-%d', start_time)}"
                            break
                    try:
                        dataf=os.popen(f"adb -s {self.Android_IOS.devices} shell \"cd /sdcard/Android/data/{self.Android_IOS.package}/files/{pathlog} ; ls -l\"").read().splitlines()[1::]
                        if "Permission denied" in dataf:
                            raise ex
                        if not dataf:
                            raise ex
                        for file in dataf:
                            fileturn=file.split(" ")
                            Autotime= time.mktime(time.strptime(f"{fileturn[-3]}:{fileturn[-2]}",'%Y-%m-%d:%H:%M'))
                            if abs(Autotime-time.mktime(start_time))<filenumname[0]:
                                filenumname[0]=abs(Autotime-time.mktime(start_time))
                                filenumname[1]=fileturn[-1]
                                if not fileturn[-1]:
                                    raise ex
                        print(f"adb -s \"{self.Android_IOS.devices}\" shell \"cd /sdcard/Android/data/{self.Android_IOS.package}/files/{pathlog} ; cat {filenumname[1]}\"")
                        datalog=subprocess.Popen(f"adb -s {self.Android_IOS.devices} shell \"cd /sdcard/Android/data/{self.Android_IOS.package}/files/{pathlog} ; cat {filenumname[1]}\"",stdout=subprocess.PIPE, stderr=subprocess.PIPE,shell=True)
                        files.append(("files",(f'auto_log_{self.task_running_id}.log', datalog.stdout.read())))
                    except:
                        print(f"安卓端{self.Android_IOS.package}包名log路径错误")
            elif "ios" in self.platform:  
                logPath="/Documents/KGLog"
                """获取ios机型最新的log"""
                try:
                    fileList = os.popen(
                    f"tidevice -u {devices} fsync -B {self.Android_IOS.package} ls {logPath}").read().replace("\n", "").replace("\"", "").replace("'", "\"")
                except:
                    print("ios获取log错误，检查log路径")
                    nextlog=False
                if nextlog:
                    replacedFilelist = fileList.replace("_", "").replace(".log", "")
                    replacedFilelist = json.loads(replacedFilelist)
                    fileList = json.loads(fileList)
                    maxIndex = 0
                    for index, item in enumerate(replacedFilelist):
                        if item.isdigit() == True:
                            if item > replacedFilelist[maxIndex] or not replacedFilelist[maxIndex].isdigit():
                                maxIndex = index
                    try:
                        if os.path.exists("./ioslocalcache"):
                            pass
                        else:
                            os.makedirs("./ioslocalcache")
                        print(maxIndex)
                        print(fileList[maxIndex])
                        with open(f"./ioslocalcache/{int(time.mktime(start_time))}_{devices}.txt", "wb+") as f:
                            f.write(tidevice.Device(devices).app_sync(self.Android_IOS.package).pull_content(
                                f"/Documents/KGLog/{fileList[maxIndex]}"))
                        
                        files.append(("files",(f'auto_log_{self.task_running_id}.log', open(f"./ioslocalcache/{int(time.mktime(start_time))}_{devices}.txt", "rb").read())))
                    except:
                        print("ios tidevice模块异常")
            response = requests.post(f"{self.server_url}/task_run/upload_log", files=files, data={
                    "task_running_id": self.task_running_id,
                    "device_id": self.device_id,
                    "case_id": case["id"]
                    })
            print("日志上传成功：")
            print(response.content)
        except:
            print("日志上传出错：")
            #traceback.print_exc()
    # 执行单个案例的完整流程
    def run_one_case(self,case):
        print(f"开始执行{case['name']}")
        self.bot.send_text(f"{self.device_name} 开始执行 {case['name']}")
        self.Android_IOS.wda_u2_Detect()
        self.Android_IOS.unlock()

        time.sleep(5)
        
        self.parameters = self.init_parameters(case)

        self.prepare_app()

        
        u3driver, before_runs, case_run = self.import_module(case)
        self.start_case(case, u3driver,before_runs,case_run)
        self.logupdata(case)
        # 案例完成，上传log
        
        
        #案例执行完成，锁屏
        self.Android_IOS.lock()

    # 运行游戏前准备操作
    def prepare_app(self):

        # 判断此次运行是否需要提前清理游戏数据
        if "clear_data" in self.parameters.keys() and self.parameters["clear_data"] == 1:
            self.Android_IOS.ClearData()


        # UE4 Insight 采集前提：需要提前准备 UE4CommandLine.txt，而且要确保应用在运行前拥有 SD 卡读写权限
        if self.Android_IOS.package_info["project_name"] != None:
            # insight = False
            commandLineData = ""
            # if "performance" in self.parameters.keys():
            #     collect_type = self.parameters["performance"]
            
            if "UE4CommandLine" in self.parameters.keys():
                commandLineData = self.parameters["UE4CommandLine"]

            self.Android_IOS.UE4CommandLineInit(commandLineData)
        


            if "performance" in self.parameters.keys():
                collect_type = self.parameters["performance"]

                # 如果 需要采集 LLM 数据，尝试清空LLM文件夹
                if "LLM" in collect_type:
                    self.Android_IOS.UE4ClearLLMData()


    def start_case(self,case, u3driver, before_runs, case_run):
        execute_time_out = 60 if case["execute_time_out"] == None else case["execute_time_out"]
        execute_time_out *= 60

        case_status = None

        # 开始案例，在设定的重试次数下重复运行
        for i in range(case["execute_times"]):

            
            #  初始化案例状态
            case_status = CaseStatus(self.server_url, self.task_running_id, self.task_parameters, case["id"], self.device_id, self.bot, execute_time_out, self.device_name)


            # 启动游戏
            bSucceed=self.Android_IOS.ConnectDevice()
            if bSucceed:


                try:
                    
                    # print(dir(case_run))

                    # 等待进入游戏
                    time.sleep(80)

                    if "ios" in self.platform and self.project_id=="jx1pocket":
                        self.Android_IOS.clock(0.58,0.75)
                    if self.project_id=="abyss":
                        d = u2.connect(self.device_s)
                        if  d(text="同意").exists():
                            d(text="同意").click()
                            time.sleep(20)
                        if d(text="请输入手机号").exists():
                            d(resourceId="com.bijie.bilibili:id/iv_gs_title_close").click()
                            time.sleep(20)
                    # 初始化 u3driver
                    udriver = u3driver.AltrunUnityDriver(self.device_s, "", self.device_ip, self.udriver_port, 60)

                    case_status.set_udriver(udriver)
                    # 使用列表来多线程同步案例状态
                    # case_status = []
                    # 多人案例
                    if case["execute_machine_count"] > 1:
                        # 开始监听同步问题
                        # _thread.start_new_thread(check_sync, (task_running_id,task_parameters, case["id"], device_id, udriver, case_status, bot))
                        case_status.start_check_sync()

                    #初始化采集
                    self.start_capture(udriver, case["name"])
                    if "toreversion" in self.task_parameters.keys() and self.task_parameters["toreversion"]=="true":
                        self.Android_IOS.package_info["versionName"]=self.getgamereversion(u3driver,udriver)
                    # 案例前准备
                    for before_run in before_runs:
                        try:
                            # bot.send_text(f"{device_s} 案例前操作开始 {before_run['module'].__name__} {before_run['func']}")
                            print(f"{self.device_s} 案例前操作开始 {before_run['module'].__name__} {before_run['func']}")
                            before_run["module"].__getattribute__(before_run["func"])(udriver, self.parameters)
                            
                        except Exception as e:
                            # self.bot.send_text(f"{self.device_name}-{self.device_s} 案例前操作失败 {before_run['module'].__name__} {before_run['func']}")
                            # self.bot.send_text(traceback.format_exc())
                            raise InterruptedError("案例前操作失败")
                        # before_run.AutoRun(udriver)
                    
                    # 根据任务参数进行采集
                    # start=time.time()
                    
                    # _thread.start_new_thread(check_timeout, (case_status, execute_time_out, udriver, bot, device_s))
                    case_status.start_check_timeout()

                    # 案例主体运行
                    # bot.send_text(f"{device_s} 运行案例主体")
                    print(f"{self.device_s} 运行案例主体")

                    #开始采集
                    self.run_capture()

                    case_run.AutoRun(udriver, self.parameters)

                    # 案例成功，保存采集数据
                    self.stop_capture(case["name"], save=True)
                    try:
                        udriver.stop()
                    except:
                        pass
                    if self.perfeyesuccessd:
                        case_status.case_success()
                    else:
                        case_status.case_fail()
                        self.bot.send_text(f"{self.device_name}-{self.device_s}- {case['name']} perfeye采集失败，案例无数据")
                        # case_status.append(CaseStatus.SUCCESS)
                    # change_case_status(case_status, CaseStatus.SUCCESS)
                    # 案例成功，退出重试
                    break
                    

                except Exception as e:
                    self.bot.send_card(f"{self.device_name}-{self.device_s}- {case['name']} 第 {i+1} 次失败", self.device_s, self.platform)
                    # change_case_status(case_status, CaseStatus.FAIL)
                    case_status.case_fail()

                    # 案例失败，不保存采集数据
                    self.stop_capture(case["name"], save=False)
                    

                    # 多人案例同步失败
                    if case["execute_machine_count"] > 1:
                        self.sync_fail(case["id"])
                    try:
                        udriver.stop()
                    except Exception as e:
                        pass
            else:
                self.bot.send_text(f"{self.device_name}-{self.device_s} 游戏启动失败或设备掉线")
                self.bot.ret_img(self.platform,self.device_s)
                self.Android_IOS.unlock()

                continue
    
        # 如果案例状态没有变化，则判断为未知原因的失败
        if not case_status.is_case_finish():
            case_status.case_fail()
            self.bot.send_text(f"{self.device_name}-{self.device_s}- {case['name']} 发生不明原因的错误，导致案例无法完成，检查log")

        # 更新案例状态
        if case_status != None:
            case_TF=case_status.upload_status(self.report_data, case["name"])
            if case_TF:
                if "Profile" in self.report_data:
                    url=f"http://ubox.testplus.cn/project/{self.project_id}/appKey/{self.report_data['appkey']}/detail/{self.report_data['Profile']}/summaryHome"
                    self.bot.send_text(f"{self.device_name}-深度采集成功",case['name'],url)
                elif "perfeye"in self.report_data:
                    url=f"http://perfeye.console.testplus.cn/case/{self.report_data['perfeye']}/report?appKey={self.project_id}"
                    self.bot.send_text(f"{self.device_name}-基础采集成功",case['name'],url)
                else:
                    self.bot.send_text(f"{self.device_name}-案例成功 {case['name']}")

    # 初始化当前案例运行所需参数
    def init_parameters(self, case):
        # 处理参数
        parameters = {}
        self.case_parameters = case["parameters"]
        if self.case_parameters != None:
            self.case_parameters = json.loads(self.case_parameters)

            for key in self.case_parameters.keys():
                parameters[key] = self.case_parameters[key]
            
        # 账号信息
        parameters["account"] = case["account"]
        # 画质信息
        parameters["quality"] = self.device_quality
        # WDA_U2 手机操控
        parameters["WDA_U2"] = wu2(self.Android_IOS.WDA_U2)
        # 包名
        parameters["package"] = self.Android_IOS.package
        #设备号
        parameters["device"] = self.device_s
        if self.task_parameters != None:
            
            for key in self.task_parameters.keys():
                # 如果在任务参数中的 devices 字段中设置了设备（ID）特殊参数，将会使用里面指定的特殊参数覆盖掉外层的全局参数
                if key == "devices":
                    devices = self.task_parameters[key]
                    if str(self.device_id) in devices.keys():
                        for replace_key in devices[str(self.device_id)].keys():
                            parameters[replace_key] = devices[str(self.device_id)][replace_key]
                    continue
                parameters[key] = self.task_parameters[key]


        if case["execute_machine_count"] > 1:
            parameters["wait_sync"] = wait_sync_factory(self.task_running_id, case["id"], self.device_id, self.bot,self.task_parameters, self.server_url,self.device_name)


        print(parameters)
        return parameters
    #初始化采集
    def start_capture(self, udriver, case_name):
        start = time.time()

        self.performance = {}
        self.report_data = {}
        try:

            # 开始采集
            if "performance" in self.parameters.keys():
                collect_type = self.parameters["performance"]

                # perfeye 采集
                if "perfeye" in collect_type:

                    # 检查是否有 appKey
                    if not "appKey" in self.parameters.keys():
                        raise KeyError("缺少参数 appKey，无法进行 perfeye 采集")
                        # bot.send_text("缺少参数 appKey，无法进行 perfeye 采集")
                    self.task_data["appKey"] = self.parameters["appKey"]
                    if "android" in self.platform:
                        try:
                            self.Android_IOS.WDA_U2.watcher('allow_tp').when('允许').click()#自动点击系统弹窗,游戏可能会弹出什么提示
                        except Exception as e:
                            pass
                    perfeye = TPlus.Perfeye()
                    nowport=0
                    with self.perfeyeportlock:
                        nowport=self.perfeyeport.value
                        self.perfeyeport.value+=1
                    perfeye.PreInit(self.device_s,nowport) # TODO 完善端口分配功能
                    # perfeye 使用 subprocess，当多进程被杀掉，无法自动关闭 perfeye 的子进程，将 perfeye 返回给父进程进行关闭
                    self.task_data["perfeye"] = perfeye.GetPid()

                    # bot.send_text(f"{device_s} 开始采集 perfeye")
                    print(f"{self.device_s} 初始化采集 perfeye")
                    times = 25
                    # if self.device_s=="e755fd8d":
                    #     times=30
                    if "android" in self.platform:
                        while True:
                            try:
                                self.Android_IOS.WDA_U2.watcher.run()
                            except Exception as e:
                                pass
                            times -= 1
                            if times == 0:
                                print("有弹窗,等待了---",time.time()-start)
                                break
                            else:
                                time.sleep(0.5)
                    
                    self.performance["perfeye"] = perfeye
                        
                # gpu 温度采集
                if "gpu_temp" in collect_type:
                    gpuTemp = gpu_temp.GPUTemp(self.device_ip, f"{case_name}({self.device_s})")
                    
                    # gpuTemp.start_capture()
                    battery=self.Android_IOS.get_battery()
                    self.bot.send_text(f"{self.device_name} 电量剩余 {battery}; 初始化采集 gpu_temp")
                    self.performance["gpuTemp"] = gpuTemp

                # gpu 使用详情采集
                if "perfetto" in collect_type:
                    perfetto = record_android_trace.Perfetto(self.device_s, f"{case_name}({self.device_s})")
                    # perfetto.start()
                    self.bot.send_text(f"{self.device_name} 初始化采集 perfetto")
                    self.performance["perfetto"] = perfetto

                #深度采集
                if "Profile" in collect_type and self.Android_IOS.package_info["project_name"] == None: 
                    gpath= os.path.abspath(os.path.join(os.getcwd(), "..","files"))
                    collection={}
                    if type(collect_type)==dict and collect_type["Profile"] != {} :
                        collection={'ubox': {'path': gpath}}
                        if "resource" in collect_type["Profile"]:
                            collection["resource"]={'ip': '', 'density': 150}
                        if "custom" in collect_type["Profile"]:
                            collection["custom"]={}
                    else:
                        collection={'ubox': {'path': gpath}, 'resource': {'ip': '', 'density': 150}, 'custom': {}}
                    parameter={
                        'u3driver':udriver,
                        'device':self.device_s,
                        'device_ip':self.device_ip,
                        "quality":self.device_quality,
                        "platform":self.platform,
                        "package":self.Android_IOS.package,
                        "appkey":self.Android_IOS.appkey,
                        "project_id":self.project_id,
                        "tag":"uauto-daily",
                        "switch":True,
                        "gameversion":self.Android_IOS.versionName,
                        "feil_path":gpath,
                        # "collection":{'ubox': {'path': gpath}, 'resource': {'ip': '', 'density': 15}, 'custom': {}}
                        "collection":collection
                    }
                    #重新导入Profile_test 模块
                    Profile_test=get_Proflie_module(self.project_file_lock)
                    Prof=Profile_test.Profile(parameter)
                    # Prof.RunProfile()
                    self.bot.send_text(f"{self.device_s} 初始化深度采集 Profile")

                    self.performance["Prof"] = Prof

                # UE4 Insight 采集
                if "insight" in collect_type and self.Android_IOS.package_info["project_name"] != None: 
                    
                    gpath= os.path.abspath(os.path.join(os.getcwd(), "..","files"))
                    collection={'ubox': {}}
                    parameter={
                        'u3driver':udriver,
                        'device':self.device_s,
                        'device_ip':self.device_ip,
                        "quality":self.device_quality,
                        "platform":self.platform,
                        "package":self.Android_IOS.package,
                        "appkey":self.Android_IOS.appkey,
                        "project_id":self.project_id,
                        "tag":"uauto",
                        "switch":True,
                        "gameversion":self.Android_IOS.versionName,
                        "feil_path":gpath,
                        # "collection":{'ubox': {'path': gpath}, 'resource': {'ip': '', 'density': 15}, 'custom': {}}
                        "collection":collection
                    }

                    Profile_UE4=get_UE4_Proflie_module(self.project_file_lock)
                    Insight=Profile_UE4.Profile(parameter)
                    self.performance["Insight"] = Insight

                # UE4 LLM 采集
                if "LLM" in collect_type and self.Android_IOS.package_info["project_name"] != None:
                    # 当前使用引擎内置的 LLM 进行采集，后续插件更新好后才需要操作
                    pass
            
            # 其他采集

        except Exception as e:
            self.bot.send_text(f"{self.device_name}-{self.device_s}  采集初始化失败")
            self.bot.send_text(traceback.format_exc())
     #开始采集       
    def run_capture(self):
        try:
            if "performance" in self.parameters.keys():
                collect_type = self.parameters["performance"]

                # perfeye 采集
                if "perfeye" in collect_type and "perfeye" in self.performance:
                    # TODO 参数可配置
                    self.perfeyesuccessd=True
                    perfeye = self.performance["perfeye"]
                    perfeye.Start(self.Android_IOS.package) # TODO 动态包名
                    self.parameters["Add_Label"]=perfeye.Label
                # gpu 温度采集
                if "gpu_temp" in collect_type:
                    gpuTemp=self.performance["gpuTemp"]
                    gpuTemp.start_capture()

                # gpu 使用详情采集
                if "perfetto" in collect_type:
                    perfetto = self.performance["perfetto"]
                    perfetto.start()

                #深度采集
                if "Profile" in collect_type and "Prof" in self.performance:
                    Prof = self.performance["Prof"]
                    Prof.RunProfile()

                # UE4 Insight 采集
                if "insight" in collect_type and "Insight" in self.performance:
                    Insight = self.performance["Insight"]
                    Insight.RunProfile()
                
                # UE4 LLM 采集
                if "LLM" in collect_type and "LLM" in self.performance:
                    # 当前使用引擎内置的 LLM 进行采集，后续插件更新好后才需要操作
                    pass

        except Exception as e:
            self.bot.send_text(f"{self.device_name}-{self.device_s} 采集开始失败")
            self.bot.send_text(traceback.format_exc())

    def stop_capture(self, case_name, save = True):
        # 停止采集
        try:
            if "performance" in self.parameters.keys():
                collect_type = self.parameters["performance"]

                # perfeye 采集
                if "perfeye" in collect_type and "perfeye" in self.performance:
                    # TODO 参数可配置
                    perfeye = self.performance["perfeye"]
                    ret=None
                    data=None
                    if "toreversion" in self.task_parameters.keys() and self.task_parameters["toreversion"]=="true":
                        ret,data = perfeye.Stop( f'{case_name}(' + self.device_s + ')', scenes=case_name, picture_quality=self.device_quality, do_upload=save, appKey=self.parameters["appKey"],version=self.Android_IOS.package_info["versionName"])
                    else:
                        ret,data = perfeye.Stop( f'{case_name}(' + self.device_s + ')', scenes=case_name, picture_quality=self.device_quality, do_upload=save, appKey=self.parameters["appKey"])

                    # bot.send_text(f"{device_s} perfeye 采集结束: {ret}, {data}")
                    print(f"{self.device_s} perfeye 采集结束: {ret}, {data}")
                    
                    # perfeye 结束采集后不用给主进程进行清理
                    self.task_data["perfeye"] = -1
                    if ret==False:
                        self.perfeyesuccessd=False
                    # 获取报告结果
                    if ret and save:
                        self.report_data["perfeye"] = data["result"]["report_id"]

                
                # gpu_temp
                if "gpu_temp" in collect_type and "gpuTemp" in self.performance:
                    gpuTemp = self.performance["gpuTemp"]
                    ret = gpuTemp.stop_capture()
                    # bot.send_text(f"{device_s} gpu_temp 采集结束 {ret}")
                    print(f"{self.device_s} gpu_temp 采集结束 {ret}")
                    
                    if ret != None and save:
                        self.report_data["gpu_temp"] = ret["file_path"]
                
                # perfetto
                if "perfetto" in collect_type and "perfetto" in self.performance:
                    perfetto = self.performance["perfetto"]
                    ret = perfetto.stop()
                    self.bot.send_text(f"{self.device_s} perfetto 采集结束: {ret}")
                    print(f"{self.device_s} perfetto 采集结束: {ret}")

                    if ret != None and save:
                        self.report_data["perfetto"] = ret["file_path"]

                #深度采集
                if "Profile" in collect_type and "Prof" in self.performance:
                    Prof = self.performance["Prof"]
                    Prof.StopProfile()
                    time.sleep(3)
                    switch={
                        "casename":case_name,
                        "save":False,
                        "upload":save,
                        "type":"ordinary",
                        "shiled":0
                        }
                    ret=Prof.checkProfile(switch)
                    if ret != None and save:
                        self.report_data["Profile"] = ret["uuid"]
                        self.report_data["appkey"] = self.Android_IOS.appkey
                    self.bot.send_text(f"{self.device_name} Profile 深度采集结束: {ret}")
                
                # Insight 采集
                if "insight" in collect_type and "Insight" in self.performance:
                    Insight = self.performance["Insight"]
                    Insight.StopProfile()
                    switch={
                        "casename":case_name,
                        "save":False,
                        "upload":save,
                        "type":"ordinary",
                        "shiled":0,
                        "LLM": "LLM" in collect_type,
                        "LLM_Path": f"/sdcard/UE4Game/{self.Android_IOS.package_info['project_name']}/{self.Android_IOS.package_info['project_name']}/Saved/Profiling/LLM"
                        }
                    ret=Insight.checkProfile(switch)
                    if ret != None and save:
                        self.report_data["Insight"] = ret["uuid"]
                        self.report_data["appkey"] = self.Android_IOS.appkey
                    self.bot.send_text(f"{self.device_name} Insight 深度采集结束: {ret}")
                
                # if "LLM" in collect_type:
                    

        except Exception as e:
            self.bot.send_text(f"{self.device_name}-{self.device_s}  采集结束失败")
            self.bot.send_text(traceback.format_exc())


    def import_module(self, case):
        # 动态导入模块
        # TODO: 在实际导入模块前，需要更新对应的模块代码
        case_file_path = case["file_path"]
        if case_file_path.endswith(".py"):
            case_file_path = case_file_path[:-3]
        case_file_path = case_file_path.replace("/", ".")

        module_load = [f"projects.{case['project_id']}.u3driver", f"projects.{case['project_id']}.{case_file_path}"]


        modules = get_module(module_load, self.project_id, self.project_file_lock)

        # TODO: 有些案例的准备需要运行其他案例主体，需要在参数中获取到，然后把这部分案例加载进来，并根据参数设置运行

        u3driver = modules[0]
        case_run = modules[1]

        
        # 案例前置操作需要导入的额外模块
        before_runs = []
        before_run_module_load = []

        if self.case_parameters != None and "before_run" in self.case_parameters.keys():
            for before_run_case in self.case_parameters["before_run"]:
                file_path = before_run_case["file_path"]
                if file_path.endswith(".py"):
                    file_path = file_path[:-3]
                file_path = file_path.replace("/", ".")
                before_run_module_load.append(f"projects.{case['project_id']}.{file_path}")

        before_run_modules = get_module(before_run_module_load, self.project_id, self.project_file_lock)
        
        for i, before_run_module in enumerate(before_run_modules):
            item = {
                "module": before_run_module,
                "func": self.case_parameters["before_run"][i]["func"]
            }
            before_runs.append(item)

        return u3driver, before_runs, case_run

    def sync_fail(self, case_id):
        
        
        if 'team' in self.task_parameters.keys(): 
            response = requests.post(f"{self.server_url}/task_run/sync_fail", params={
            "case_id": case_id,
            "device_id": self.device_id
        })
        else:
            response = requests.post(f"{self.server_url}/task_run/sync_fail", params={
            "task_running_id": self.task_running_id,
            "case_id": case_id,
            "device_id": self.device_id
        })
        ret = json.loads(response.content)

        return ret



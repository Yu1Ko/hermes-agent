'''
Author: 涂阳墨 tuyangmo@kingsoft.com
Date: 2023-07-13 11:29:08
LastEditors: 涂阳墨 tuyangmo@kingsoft.com
LastEditTime: 2024-08-14 10:39:43
Description: 

Copyright (c) 2023 by Seasun, All Rights Reserved. 
'''

import _thread
import asyncio
import datetime
import importlib
import json
import os
import platform
import signal
import subprocess
import sys
import threading
import time
import traceback
import aioprocessing
import ctypes
import platform

from BaseTool import ini_get

strOS = platform.system() #系统
import requests
from extensions import logger
from datetime import datetime,timedelta
import atexit
from file_sync_model import FileSyncModel

#全局替换print输出路径
import inspect
import builtins
_builtin_print = builtins.print  # 保存原生print
def my_print(*args, **kwargs):
    frame = inspect.currentframe().f_back
    filename = frame.f_code.co_filename.split('\\')[-1]
    lineno = frame.f_lineno
    now = datetime.now().strftime('%Y-%m-%d %H:%M:%S.%f')[:-3]  # 保留到毫秒
    prefix = f'[{now}] [{filename}:{lineno}]'
    _builtin_print(prefix, *args, **kwargs)   # 调用原生print

builtins.print = my_print  # 全局替换print

import CapTure
import LogManage
# from Throw_Advice import Throw_Advice
from Throw_Advice_new import Throw_Advice
import auto_rebot
from utils.tools import os_popen

from FakeOut import FakeOut
from utils.constants import SERVER_URL
from worker_process.worker_process_base import WorkerProcessBase, ProcessLockedException
#from ad_ios import Android_IOS as AdIo
#from ad_ios import Wda_u2_operate as wu2
import ad_ios
from pathlib import Path
import uiautomator2 as u2
import git_lab


# 动态导入模块，需要加锁，避免同时两个项目在导入时由于 sys.path 里面添加了两个路径导致找错对应的模块
def get_module(paths, project_name, project_file_lock, module_path_ex):

    print(project_name)
    print(paths)

    with project_file_lock:
        importlib.invalidate_caches()

        module_path = os.path.dirname(os.path.abspath(sys.argv[0]))
        sys.path.append(module_path) #task_controller
        module_path2 = os.path.dirname(os.path.join(module_path, module_path_ex))
        sys.path.append(module_path2) #task_controller\projects
        module_path3 = os.path.join(module_path, module_path_ex)
        sys.path.append(module_path3) #task_controller\projects\JX3

        # logger.info(module_path)
        # sys.path.append(module_path)
        modules = []
        for path in paths:
            module = importlib.import_module(path)
            modules.append(module)

        sys.path.remove(module_path)
        sys.path.remove(module_path2)
        sys.path.remove(module_path3)
        return modules


# 等待同步完成
# 该函数会被传入到自动化脚本里进行运行
def wait_sync_factory(task_running_id, build_case_id, device_id, bot,task_parameters,server_url,device_name):

    # 等待同步可以传入自定义参数，做游戏内信息同步（需要修改数据库）
    def wait_sync(args = None):
        bot.send_text(f"{device_id} 等待同步")
        while True:
            if 'team' in task_parameters.keys():
                response = requests.get(f"{server_url}/build/controller/sync", params={
                "buildId": task_running_id,
                "buildCaseId": build_case_id,
                "deviceId": device_id,
                "syncArgs": args
            },timeout=(10, 15))
            else:
                response = requests.get(f"{server_url}/build/controller/sync", params={
                "buildId": task_running_id,
                "buildCaseId": build_case_id,
                "deviceId": device_id,
                "syncArgs": args
            },timeout=(10, 15))

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


class TaskRunProcess(WorkerProcessBase):
    def __init__(self, process_uid, event_queue, event_queue_lock, task_run_param):
        super().__init__(process_uid, event_queue, event_queue_lock)
    #def __init__(self, process_uid, event_queue,task_run_param):
        #super().__init__(process_uid, event_queue)
        self.task_run_param = task_run_param
        self.running = False

        self._is_alive = True   # 进程是否已经停止
        logger.info("TaskRunProcess ini")

#linux------------------------------------------------
    def signal_handler(self, sig, frame):
        print("收到信号，执行清理操作并退出")
        self.clean_up()
        sys.exit(0)
#linux------------------------------------------------

    def check_process_is_alive(self):
        '''检查本进程是否仍然存活, 可以继续执行'''
        if not self._is_alive: # 已经停止的情况下直接返回
            return False
        # 向主进程询问当前状态
        try:
            self._is_alive = self.call_event("check_task_process_alive", self.task_running_id, self.get_uuid())
        except ProcessLockedException:
            logger.error("任务进程已被锁定, 进程已退出")
            self._is_alive = False
        except Exception as e:
            logger.error(f"检查任务进程是否存活失败: {e}")
        return self._is_alive

    def heartbeat(self):
        while self.running:
            try:
                response = requests.post(f"{SERVER_URL}/build/controller/device/running/heartbeat", json={
                        "buildId": self.task_running_id,
                        "deviceId": self.device_id
                    }).json()
                if response["code"] != 200:
                    logger.error(f"心跳上报失败: {response}")
                    if response["code"] == 404:
                        logger.error(f"任务 {self.task_running_id} 已被取消, 退出心跳进程")
                        self.running = False
                        break
            except Exception as e:
                logger.error(f"心跳上报失败: {e}")
            time.sleep(10)

    def clean_up(self):
        logger.info(f"进程退出, 开始清理子进程: {self.task_running_id}")
        try:
            self.running = False
            task_data = self.task_data
            bug_log_ios_pid = self.bug_log_ios_pid
            if "perfeye" in task_data.keys() and task_data["perfeye"] != -1:
                if strOS == 'Linux':
                    strCmd=f'ps -ef |grep miniperf'
                else:
                    strCmd = f'tasklist |findstr miniperf'
                logger.info(os_popen(strCmd))
                # 使用 kill 命令杀掉 perfeye 的进程
                logger.info(f"kill perfeye {task_data['perfeye']}")
                if strOS == 'Linux':
                    os_popen(f'kill -9 \"{task_data["perfeye"]}\"')
                else:
                    os_popen(f'TASKKILL /F /t /pid \"{task_data["perfeye"]}\"')

                logger.info(os_popen(strCmd))
            '''if "platform" in task_data.keys():
                platform = task_data["platform"]
                package_url = task_data["package_url"]
                package_info = task_data["package_info"]
                port = task_data["port"]
                temp_task_parameters = ""
                judge = False
                if self.task_parameters is not None:
                    try:
                        judge = isinstance(self.task_parameters, str)
                        print(f"judge类型是{judge}")
                        # print(f"self.task_parameters type is {type(self.task_parameters)}")
                        if judge:
                            temp_task_parameters = json.loads(self.task_parameters)
                    except Exception as e:
                        print(f"JSON parsing error: {e}")
                
                if self.bMobile:
                    module = importlib.reload(ad_ios)
                    adio = module.Android_IOS(self.perfeyedevice_s, platform, package_url, package_info, self.project_file_lock, self.download_lock,port,temp_task_parameters)
                    adio.CloseIPA_APK(adio.package)
                    time.sleep(3)
                    adio.lock()'''

            if self.perfeyedevice_s in bug_log_ios_pid.keys():
                killpid=bug_log_ios_pid[self.perfeyedevice_s]
                if strOS == 'Linux':
                    os_popen(f'kill -9 {killpid}')
                else:
                    os_popen(f'TASKKILL /F /t /pid {killpid}')
            #如果用例已经开启需要执行用例的tearndown


        except Exception as e:
            logger.error(f"子进程清理失败:{e}")
        self.heartbeat_thread.join()

    def init_param(self, project_file_lock, ue4_command_lock, download_lock,c):
        '''这个函数会在主进程执行, c为主进程的controller实例'''
        logger.info("init_param")
        logger.info(self.task_run_param)
        item = self.task_run_param
        device = item["device"]
        package_url = item["package_url"]
        package_info = item["package_info"]
        logger.info(package_info)
        #package_info='{"appkey": "w4sqa1fz", "packageName": "com.seasun.jx3bvt", "activity": "com.seasungame.jx3.x3d.KActivity", "versionName": "1.0.3", "projectName": null, "packageActivity": "com.seasungame.jx3.x3d.KActivity"}'
        #
        task_running_id = item["task_running_id"]
        task_parameters = item["task_parameters"]
        logger.info(task_parameters)
        logger.info(type(task_parameters))
        project_id = item["project_id"]
        feishu_token = item["feishu_token"]
        device_s = device['device_identifier']
        udriver_port = 13000
        phone_port = 31416
        otalist = ["com.oppo.ota", "com.coloros.sau", "com.oppo.otaui", "com.huawei.android.hwouc",
                "com.heytap.market"]
        # 安卓机连接电脑网络
        if (device["os"] == "android"):
            try:
                apklist = os_popen(
                    f"adb -s {device_s} shell \"pm list packages\"").splitlines()
                for apk in apklist:
                    if apk.split("package:")[-1] in otalist:
                        cancelapk = apk.split("package:")[-1]
                        os_popen(
                            f"adb -s {device_s} shell \"pm disable-user {cancelapk}\"")
            except Exception as e:
                logger.error(e)

        phone_default_port = c._share_value["phone_default_port"]
        phone_port_map = c._share_dict["phone_port_map"]
        phone_network = c._share_dict["phone_network"]

        #是否启用本地连接
        if device["ip"] == "127.0.0.1":
            ip = device["ip"]
            phone_port = phone_default_port
            phone_default_port += 1
            par=json.loads(task_parameters)
            str_deviceunique_identifier = str(device['unique_identifier'])
            if device['device_identifier'] in phone_port_map.keys():
                phone_port = phone_port_map[device['device_identifier']]
                phone_default_port -= 1
                if os.path.exists(f"phone_networking/{device_s}_netlog"):
                    p = phone_network.get(device['device_identifier'], None)
                    if p:
                        logger.info(f"正在终止设备{device['device_identifier']}的gnirehtet进程")
                        p.terminate()
                        logger.info(f"设备{device['device_identifier']}的gnirehtet进程已终止")
                        p.wait()
                        logger.info(f"设备{device['device_identifier']}的gnirehtet进程资源已回收")

            c._share_value["phone_default_port"] = phone_default_port

            # 用device['device_identifier']来做键，存储的是端口号
            if os.path.exists(f"phone_networking/{device_s}_netlog"):
                os.remove(f"phone_networking/{device_s}_netlog")
            str_phone_port = str(phone_port)
            logger.info(device["name"] + "_正在连接电脑网络")
            # 命令顺序：cd ../root/gnirehtet-linux64/文件里面执行./gnirehtet run “序列号” -d "ip" -p "端口号"
            rw = subprocess.Popen(
                args=["adb","-s",str_deviceunique_identifier, "shell", "am","start","-a","com.genymobile.gnirehtet.STOP", "-n",
                    "com.genymobile.gnirehtet/.GnirehtetActivity"
                    ],
                shell=False
            )
            time.sleep(2)
            rw.terminate()
            rw.wait()
            if strOS == 'Linux':
                cmd = os_popen(f"ps -ef |grep \"gnirehtet\" |grep \"{str_deviceunique_identifier}\"").split("\n")[0]
            else:
                cmd = os_popen(f"tasklist |findstr \"gnirehtet\" |grep \"{str_deviceunique_identifier}\"").split("\n")[0]

            if f"gnirehtet run {str_deviceunique_identifier}" in cmd:
                strcmd=cmd.split()[1]
                if strOS == 'Linux':
                    os_popen(f"kill -9 {strcmd}")
                else:
                    os_popen(f'TASKKILL /F /t /pid {strcmd}')

                # 有可能进程直接就被回收了, 这里需要做一个异常捕获
                try:
                    os.waitpid(int(strcmd), 0)
                except Exception as e:
                    pass
            #       显示已连接电脑网络
            logger.info(device["name"] + "_正在连接电脑网络")
            # 其他游戏执行连接命令  命令顺序：进入文件 cd ../root/gnirehtet-linux64/   文件里面执行 ./gnirehtet run “序列号” -p "端口号"
            # 用管道的方式去添加线程，内容存进phone_networking里了
            dnsserver="10.10.18.10"#默认的内网dns
            if "DnsServer" in par.keys():
                dnsserver=par["DnsServer"]
            rw = subprocess.Popen(
                ["./gnirehtet-rust-linux64/gnirehtet", "run", str_deviceunique_identifier, "-d", dnsserver, "-p",
                str_phone_port],
                shell=False,
                stdout=open(f"phone_networking/{device_s}_netlog", 'w'),
                stderr=open(f"phone_networking/{device_s}_netlog", 'w')
            )
            c._share_dict["phone_network"][device_s] = rw
            c._share_dict["phone_token"][device_s] = feishu_token
            if phone_default_port == phone_port:
                pass
            else:
                c._share_dict["phone_port_map"][device['device_identifier']] = phone_port
            logger.info("启动本地映射")

            udriver_port_org = c._share_value["udriver_port"]
            udriver_local_devices = c._share_dict["udriver_local_devices"]

            udriver_port = udriver_port_org
            udriver_port_org += 1
            # portresult=os_popen(f"adb forward --remove tcp:{udriverport}")
            if device['device_identifier'] in udriver_local_devices.keys():
                udriver_port = udriver_local_devices[device['device_identifier']]
                udriver_port_org -= 1
            c._share_value["udriver_port"] = udriver_port_org
            localdevicename=device['device_identifier']
            portresult = os_popen(
                f"adb -s \"{localdevicename}\" forward tcp:{udriver_port} tcp:13000")
            logger.info(f"{udriver_port} to 13000")
            if udriver_port != udriver_port:
                # udriver_local_devices[device['device_identifier']] = udriver_port
                c._share_dict["udriver_local_devices"][device['device_identifier']] = udriver_port
            logger.info(portresult)
        logger.info(device["device_identifier"])
        IOSignore=False

        #devices_list = c._share_list["connect_devices_list"]
        #if device["device_identifier"] not in devices_list:
            #IOSignore=True

        # 设置参数
        device_s = device['device_identifier']
        logger.info(device_s)
        self.perfeyedevice_s = device_s
        self.device_s=device_s.replace('-','') if IOSignore else device_s
        self.device_ip = device["ip"]
        self.platform = device["os"]
        self.osVersion=device["osVersion"]
        self.device_name=device["name"]
        self.device_type=device["model"]
        self.device_unique_identifier=device['unique_identifier']
        self.device_identifier=device['device_identifier']

        self.bMobile=False
        if self.platform == 'android' or self.platform == 'ios':
            self.bMobile=True
        self.port = device["port"]
        self.package_url = package_url
        self.package_info = package_info
        self.device_id = device["id"]
        self.device_quality = device["quality"]
        self.task_running_id = task_running_id
        self.task_parameters = task_parameters
        self.task_name=""
        self.project_id = project_id
        self.feishu_token = feishu_token
        self.project_file_lock = project_file_lock
        self.task_data = {}
        self.bug_log_ios_pid = {}
        self.server_url = SERVER_URL

        self.perfeyesuccessd=True
        self.udriver_port=udriver_port
        self.case_status=None
        self.device_parameters=device["parameters"]
        self.UE4CommandLock=ue4_command_lock
        self.task_running_status_id=None
        self.LogMan=None
        self.download_lock = download_lock
        self.execute_user = ""


    def process_run(self):
        self.running = True
        self.heartbeat_thread = CaseRunThread(target=self.heartbeat, daemon=True)
        self.heartbeat_thread.start()
        self.do_run()
        self.running = False
        self.heartbeat_thread.join()
        # FOR TEST
        # asyncio.run(self.aio_run_test())   # 兼容协程

    async def aio_run_test(self):
        '''测试用'''
        logger.info("任务开始!!")
        self.send_event("set_share_dict", "running_tasks", "test_key_process", "hello!")
        d = self.call_event("get_share_dict", "running_tasks")
        logger.info(f"任务进程--------{d}")
        self.send_event("set_share_dict", "running_tasks", "test_key_process", delete=True)
        time.sleep(10)
        d = self.call_event("get_share_dict", "running_tasks")
        logger.info(f"任务进程--准备结束------{d}")
        self.call_event("task_process_report_finish", self.task_running_id, self._uuid, "SUCCESS")
        logger.info("任务结束!!")

    def do_run(self):
        # run 入口
        logger.info(f"任务开始: {self._p.pid}")
        try:
            if(platform.system()!='Windows'):
                #linux------------------------------------------------
                signal.signal(signal.SIGINT, self.signal_handler)
                signal.signal(signal.SIGTERM, self.signal_handler)
                #linux------------------------------------------------
            atexit.register(self.clean_up)
            log_lock = aioprocessing.Lock()
            self.fzhu = FakeOut(log_lock)
            sys.stdout = self.fzhu
            sys.stderr= self.fzhu
            devices=self.device_s.split(":")[0].replace ('.','') if "10." in self.device_s else self.device_s
            if not os.path.exists("log_file"):
                os.mkdir("log_file")
            #任务（进程）开始 初始化日志文件
            file_log_path=f'log_file/task{self.task_running_id}_{devices}.txt'
            try:
                if os.path.exists(file_log_path):
                    os.remove(file_log_path)
            except:
                pass
            #fzhu:修改print输出位置
            self.fzhu.add_output(threading.current_thread().ident,open(file_log_path,"a+"))

            module=importlib.reload(auto_rebot)
            self.bot = module.FeiShutalkChatbot(eval(self.feishu_token))
            print('test------------------')
            # self.bot = pyfeishu.FeiShutalkChatbot(self.feishu_token)
            # self.bot.set_project_id(self.project_id) #飞书初始化项目id

            #初始化任务参数:
            judge = False
            if self.task_parameters is not None:
                try:
                    judge = isinstance(self.task_parameters, str)
                    print(f"judge类型是{judge}")
                    # print(f"self.task_parameters type is {type(self.task_parameters)}")
                    # print(f"self.task_parameters is {self.task_parameters}")
                    if judge:
                        self.task_parameters = json.loads(self.task_parameters)
                except Exception as e:
                    print(f"JSON parsing error: {e}")
            #移动端任务参数自定义包名
            logger.info(self.task_parameters)
            if 'package' in self.task_parameters and self.bMobile:
                if not isinstance(self.package_info, dict):
                    self.package_info = json.loads(self.package_info)
                self.package_info["packageName"]=self.task_parameters["package"]
            logger.info(self.package_info)

            #PC android ios
            module=importlib.reload(ad_ios)
            if self.bMobile:
                self.Android_IOS = module.Android_IOS(self.device_s, self.platform, self.package_url,self.package_info,self.project_file_lock,self.download_lock,self.port,self.task_parameters)
            else:
                self.Android_IOS=None
            self.task_data["platform"] = self.platform
            self.task_data["package_url"] = self.package_url
            self.task_data["package_info"] = self.package_info
            self.task_data["port"] = self.port
            module=importlib.reload(LogManage)
            self.LogMan=module.Logmanage(self.server_url,self.device_s,self.device_id,self.task_running_id,self.Android_IOS,self.device_ip, self.bug_log_ios_pid,self.device_name,self.platform)
            self.LogMan.set_projectId(self.project_id) #增加项目id变量
            self.performance = {}
            self.report_data = {}
        except:
            logger.error(f"任务运行子进程初始化错误:{traceback.format_exc()}")
            self.send_event("task_process_report_finish", self.task_running_id, self._uuid, "FAILED")
            if self.LogMan:
                self.LogMan.stop_log()
            time.sleep(3)
            raise InterruptedError("任务运行子进程初始化错误")

        logger.info(f"任务: {self.task_running_id}, {self.device_id} 子进程初始化完成")

        try:
            response = requests.get(f"{SERVER_URL}/build/controller/build/info", params={
                    "buildId": self.task_running_id
                }).json()["data"]
            self.task_name=response["name"]
            self.bot.send_text(f"{self.device_name} 任务开始",self.task_name,f"https://uauto2.testplus.cn/project/{self.project_id}/taskDetail?taskId={self.task_running_id}")

            #初始化wda已经解锁过屏幕了
            #if self.bMobile:
                #self.Android_IOS.unlock()
            logger.info("-------------1------------complete------")

            if "notifier" in self.task_parameters and self.task_parameters["notifier"] != "":
                self.execute_user = self.task_parameters["notifier"].split(",")
                print(f"检测到有通知人，更新self.execute_user->{self.execute_user}")
            logger.info(f"-------------2----task_parameters: {self.task_parameters}")

            # 更新项目脚本
            self.update_project_script()
            logger.info("-------------3------------complete------")

            # 尝试安装最新的包
            #self.try_to_install_new_package()
            #logger.info("-------------4------------complete------")
            #关闭弹窗
            #if self.bMobile:
                #self.Android_IOS.Pop_ups(5)

            #logger.info("-------------5------------complete------")
            # Throw_Advice().set_data(self.feishu_token,self.project_id,self.device_s,self.device_name,self.task_running_id,response["name"],self.Android_IOS.versionName,self.platform)

            if self.bMobile:
                Throw_Advice().set_data(eval(self.feishu_token),self.project_id,self.device_s,self.device_name,self.task_running_id,response["name"],self.Android_IOS.versionName,self.platform)
            else:
                Throw_Advice().set_data(eval(self.feishu_token), self.project_id, self.device_s, self.device_name,
                                        self.task_running_id, response["name"], '1.0.0',
                                        self.platform)

            # 执行案例
            run_status = "SUCCESS"
            while True:
                # 循环开始前先检查本进程是否已经被停止
                if self.check_process_is_alive() == False:
                    logger.info(f"任务进程已被停止, 退出任务: {self.task_running_id}, {self.device_id}")
                    run_status = "CANCEL"
                    break
                '''
                if self.bMobile:
                    try:
                        # 开始案例前获取电量，如小于10%就发消息给飞书
                        kwh = self.electric_quantity()
                        if kwh <= 90:
                            os_popen(f"adb -s {self.device_s} shell dumpsys battery set status 2")
                        if kwh <= 20:
                            text = self.device_name+" 目前手机电量为:%d%%" % (kwh)
                            self.bot.send_text(text)
                    except Exception as e:
                        print(e)
                        self.bot.send_text(self.device_name+"设备无法读取电池电量")
                else:
                    pass'''
                # 获取案例信息
                #self.device_lock.acquire()
                response = requests.get(f"{self.server_url}/build/controller/get/case", params={
                    "buildId": self.task_running_id,
                    "deviceId": self.device_id,
                    "projectId": self.project_id
                })
                #self.device_lock.release()
                logger.info(f"{self.task_running_id}, {self.device_id} 获取新case: {response.content.decode('utf-8')}")
                # print(response.content.decode("utf-8"))

                case = json.loads(response.content)["data"]

                # 所有案例已完成，退出主体
                if case == None or len(case) == 0 or case["status"] == "END":
                    logger.info(f"{self.task_running_id}, {self.device_id} 所有案例已完成，正在退出")
                    break

                if case["status"] != "DO":
                    print(f"{case['status']} sleep(60)")
                    time.sleep(60)
                    continue

                # 案例间休息
                if "sleeptime" in self.task_parameters.keys():
                    time.sleep(int(self.task_parameters["sleeptime"]))
                else:
                    #time.sleep(20)
                    pass

                # 开始运行案例
                self.run_one_case(case)

                #清除日志文件 确保每个用例只上传当前用例的日志  而不是上传整个任务(用例列表)的日志
                self.fzhu.clear_all_outputs()

            if run_status != "CANCEL":
                self.send_event("task_process_report_finish", self.task_running_id, self._uuid, run_status)
            self.bot.send_text(f"{self.device_name} 任务结束",self.task_name,f"https://uauto2.testplus.cn/project/{self.project_id}/taskDetail?taskId={self.task_running_id}")
            logger.info("任务正常结束")
            #if self.bMobile:
                #self.Android_IOS.lock()
        except Exception as e:
            logger.info(f"任务异常退出{e}, {traceback.format_exc()}")
            if type(e) != SystemExit:
                self.bot.send_text(f"{self.device_name}-{self.device_s} 任务出错")
            if self.LogMan:
                self.LogMan.stop_log()
            self.send_event("task_process_report_finish", self.task_running_id, self._uuid, "FAILED")
            # self.bot.ret_img(self.platform,self.device_s,fasong=True)
            # self.bot.send_text(traceback.format_exc())
            # self.bot.send_msg_card(traceback.format_exc(),self.platform,self.device_s)
            Throw_Advice().send_msg_card(traceback.format_exc(),self.execute_user)
            "不锁屏"
            #if self.bMobile:
                #self.Android_IOS.lock()
            # TODO: 添加将设备改为空闲
        finally:
            self.clean_up()

    # 更新项目脚本
    def update_project_script(self):
        # with self.project_file_lock:

        with self.project_file_lock:

            if "branch" in self.task_parameters:
                try:
                    self.use_new_git = True
                    self.branch = self.task_parameters["branch"]
                    self.dir_name = ""
                    gitlab = git_lab.GitLab()
                    project=gitlab.GitLabProject(gitlab.getProjectByName(self.project_id))
                    # self.branch = project.Project.default_branch
                    self.sha = ""
                    if "sha" in self.task_parameters:
                        self.sha = self.task_parameters["sha"]

                    self.local_sha = ""

                    if len(self.sha) > 0:
                        # 这里假设选择的分支是正确的，需要注意
                        self.dir_name = f"{self.branch}_{self.sha}"

                        self.local_sha = f"{self.branch}/{self.sha}"
                        project.set_sha(self.sha)

                        self.bot.send_text(f"{self.device_name} 执行代码分支: {self.branch} 提交SHA：{self.sha}")

                    else:
                        self.dir_name = self.branch
                        project.set_sha(self.branch)

                        # 如果只指定了分支名，获取对应分支最新的提交 SHA
                        branches=project.Project.branches.list()
                        for progect in branches:
                            if self.branch == progect.get_id():
                                info=progect._attrs
                                self.bot.send_text(f"{self.device_name} 执行代码分支: {self.branch} 提交SHA：{info['commit']['id']}")
                                print(info["commit"]["id"],info["commit"]["message"])
                                self.local_sha = f"{self.branch}/{info['commit']['id']}"

                                break

                    sPullPath = f'new_projects/{self.project_id}/{self.dir_name}'
                    project.pullCode(sPullPath)
                    project.set_Local_sha(sPullPath,self.local_sha)
                    return ""
                except:
                    traceback.print_exc()

            self.use_new_git = False
            # ''''''
            if self.project_id == "jw3qptqjb":
                ret = os_popen(f"git submodule update --remote projects/{self.project_id}")
                print(ret)
            else:
                #pass
                try:
                    nGit = ini_get('Update', 'git', 'clientconfig.ini')
                except:
                    info = traceback.format_exc()
                    logger.error(info)
                    nGit = "1"
                if nGit == "1":
                    ret = os_popen(
                        f"git submodule add --force https://ngitlab.testplus.cn/tcdev/automationgroup/JX3.git projects/{self.project_id}")
                    print(ret)
                    ret = os_popen(
                        f"git submodule foreach --recursive git reset --hard HEAD")
                    print(ret)
                    ret = os_popen(
                        f"git submodule foreach --recursive git clean -fd")
                    print(ret)
                    ret = os_popen(f"git submodule update --remote projects/{self.project_id}")
                    print(ret)
                else:
                    obj = FileSyncModel(f'projects/{self.project_id}')
                    obj.file_sync_model()

            return

    def getgamereversion(self,u3driver,udriver,package_info):
        #再次获取版本号

        try:
            if self.project_id=="jxsj3":
            #jxsj3需要热更新版本号
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
            else:#在没有热更新版本号时，使用安装包版本号
                return package_info
        except Exception as e:
            print(e)
            raise e
    # 检查手机上是否已经安装对应的新包，如果已安装跳过安装，否则安装新包
    # def try_to_install_new_package(self):
    #     install_estimate = False
    #     # 判断是否安装这个包
    #     if self.Android_IOS.FindIPA_APK():
    #         # 获取手机里面的包信息
    #         existinfo=self.Android_IOS.get_info()
    #         # 判断两个包体版本是否相同
    #         if existinfo['versionName']!=self.Android_IOS.versionName:
    #             if "uninstall_program" in self.task_parameters:
    #                 if self.task_parameters["uninstall_program"] == 0:
    #                     print(f"安装包版本不同, 不卸载更新: {existinfo['versionName']} <> {self.Android_IOS.versionName}")
    #                     install_estimate = True
    #                 else:
    #                     print(f"安装包版本不同, 卸载: {existinfo['versionName']} <> {self.Android_IOS.versionName}")
    #                     self.Android_IOS.UnInstall_IOS_IPA()
    #             else:
    #                 self.Android_IOS.UnInstall_IOS_IPA ()
    #
    #     # 安装包体 并上传包信息到数据库
    #     if not self.Android_IOS.FindIPA_APK() or install_estimate:
    #         self.Android_IOS.Install_IOS_IPA ()
    #         response = requests.post(f"{self.server_url}/build/package/update/package/info", json={
    #             "buildId":self.task_running_id ,
    #             "packageInfo": json.dumps(self.Android_IOS.package_info)
    #             })
    #         print(response.content.decode("utf-8"))
    #     self.bot.send_text(f"{self.device_name} 安装的包版本: {self.Android_IOS.versionName}")
    #
    #     existinfo = self.Android_IOS.get_info()
    #     if existinfo['versionName'] != self.Android_IOS.versionName:
    #         # 上步做完后在验证一遍版本是否正确(原因：dev包与shipping包资源不同无法做到替换安装)
    #         print("当前包体没更新成功需卸载安装")
    #         if "uninstall_program" in self.task_parameters:
    #             print("这里进来没有？？？")
    #             self.task_parameters.pop("uninstall_program")
    #         print(f"看这里1：{self.task_parameters}")
    #         self.Android_IOS.UnInstall_IOS_IPA()
    #         self.Android_IOS.Install_IOS_IPA()
    #         response = requests.post(f"{self.server_url}/build/package/update/package/info", json={
    #             "buildId": self.task_running_id,
    #             "packageInfo": json.dumps(self.Android_IOS.package_info)
    #         })
    #         print(response.content.decode("utf-8"))
    #         self.bot.send_text(f"{self.device_name} 安装的包版本: {self.Android_IOS.versionName}")


    # 执行单个案例的完整流程
    def run_one_case(self,case):
        print(f"开始执行{case['name']}")
        print(case)
        #添加设备系统版本
        case['osVersion']=self.osVersion
        Throw_Advice().set_casename(case['name'])
        self.bot.send_text(f"{self.device_name} 开始执行 {case['name']}")
        if self.bMobile:
            #self.Android_IOS.wda_u2_Detect()
            self.Android_IOS.unlock()
        #判断本地连接端口是否生效
        '''
        if self.udriver_port!=13000:
            localforward=os_popen(f"adb forward --list")
            isin=f"{self.device_s} tcp:{self.udriver_port} tcp 13000"
            if isin not in localforward:
                portresult = os_popen(
                    f"adb -s \"{self.device_s}\" forward tcp:{self.udriver_port} tcp:13000")
                print(portresult)
        time.sleep(5)'''

        self.parameters = self.init_parameters(case)

        #临时屏蔽
        #Throw_Advice().set_account(self.parameters["account"]) #添加账号信息
        #self.prepare_app()

        u3driver, before_runs, case_run, checkpoint = self.import_module(case)
        #用例对象
        if checkpoint != None:
            checkpoint.init_parms(self.task_running_id, self.device_id, case["build_case_id"])
        self.start_case(case, u3driver,before_runs,case_run,self.fzhu)


        #案例执行完成，锁屏
        #if self.bMobile:
            #self.Android_IOS.lock()

    # 运行游戏前准备操作
    # def prepare_app(self):
    #
    #     # 判断此次运行是否需要提前清理游戏数据
    #     if "clear_data" in self.parameters.keys() and self.parameters["clear_data"] == 1 and self.bMobile:
    #         self.Android_IOS.ClearData()
    #     # 判断此次运行是否需要注入ini文件
    #     if "RebuildIni" in self.parameters.keys() and self.parameters["RebuildIni"] == "jxsjorigin" and self.bMobile:
    #         # 导入的ini文件名
    #         fileName=self.parameters["jx0IniName"]
    #         self.Android_IOS.ReBuIniInit(fileName)
    #
    #     # UE4 Insight 采集前提：需要提前准备 UE4CommandLine.txt，而且要确保应用在运行前拥有 SD 卡读写权限
    #     if self.Android_IOS.package_info["projectName"] != None and self.bMobile:
    #         # insight = False
    #         commandLineData = ""
    #         # if "performance" in self.parameters.keys():
    #         #     collect_type = self.parameters["performance"]
    #
    #         if "UE4CommandLine" in self.parameters.keys():
    #             commandLineData = self.parameters["UE4CommandLine"]
    #             # 因为 CommandLine 中的单引号内容不会起作用，如 LLM 中的参数配置，同时由于外层参数传递时，必须要以 ' 来传输避免破坏 Json 格式，因此在内部这里做转换
    #             commandLineData = commandLineData.replace("'", '"')
    #         with self.UE4CommandLock:
    #             self.Android_IOS.UE4CommandLineInit(commandLineData)
    #
    #         if "performance" in self.parameters.keys():
    #             collect_type = self.parameters["performance"]
    #
    #             # 如果 需要采集 LLM 数据，尝试清空LLM文件夹
    #             if "LLM" in collect_type:
    #                 self.Android_IOS.UE4ClearLLMData()
    #
    #             if "memreport" in collect_type:
    #                 self.Android_IOS.UE4ClearMemReportData()
    #
    #         self.Android_IOS.UE4ClearLog()


    def start_case(self,case, u3driver, before_runs, case_run,fzhu):
        execute_time_out = 60 if case["execute_time_out"] == None else case["execute_time_out"]
        #移动端 添加冷机时长 防止超时
        if self.bMobile:
            execute_time_out=execute_time_out+180

        # 检查案例log检查模块是否存在
        IsLogCheck=False
        if hasattr(case_run, "LogCheck"):
            # 调用foo方法
            IsLogCheck=True
        # case_status = None

        # 开始案例，在设定的重试次数下重复运行
        self.LogMan.log_files = []
        self.LogMan.custom_log_files = []
        for i in range(case["retry_times"]):
            # 重置部分数据
            self.report_data = {}

            if self.bMobile:
                self.Android_IOS.wda_u2_Detect()
            self.LogMan.each_case_log_start()
            #  初始化案例状态
            self.case_status = CaseStatus(self.call_event, self.task_running_id, self.task_parameters, case["id"], self.device_id, self.bot, execute_time_out, self.device_name,fzhu,self.task_running_status_id, case["build_case_id"])
            #用于判断案例运行失败时，log是否已经上传
            uplog=True

            # 启动游戏
            #bSucceed=self.Android_IOS.ConnectDevice()
            #self.Android_IOS.Pop_ups(5)
            capture = None
            try:
                # print(dir(case_run))
                udriver = None
                self.case_status.set_udriver(udriver)
                # 使用列表来多线程同步案例状态
                # case_status = []
                # 多人案例
                if case["execute_machine_count"] > 1:
                    # 开始监听同步问题
                    # _thread.start_new_thread(check_sync, (task_running_id,task_parameters, case["id"], device_id, udriver, case_status, bot))
                    self.case_status.start_check_sync()

                # 初始化采集

                #数据采集迁移至用例


                '''
                module=importlib.reload(CapTure)

                if "screenshottime" in self.task_parameters.keys():
                    capture = module.CapTure(self, self.parameters, self.task_data, self.Android_IOS, self.perfeyedevice_s,
                                      self.device_ip, self.bot, self.device_name, self.project_id,
                                      self.project_file_lock, self.task_running_id, case["name"], self.task_parameters,
                                      int(self.task_parameters["screenshottime"]), platform=self.platform,case=case)
                else:
                    capture = module.CapTure(self, self.parameters, self.task_data, self.Android_IOS, self.perfeyedevice_s,
                                      self.device_ip, self.bot, self.device_name, self.project_id,
                                      self.project_file_lock, self.task_running_id, case["name"], self.task_parameters,
                                      case=case,platform=self.platform)'''
                print("capture对象初始化成功")
                logger.info("capture对象初始化成功")
                print("capture对象初始化成功-ttttttttttttttttttt")
                '''
                if self.bMobile:
                    strPackageName=self.Android_IOS.package
                else:
                    strPackageName = None
                self.performance = capture.start_capture(udriver, strPackageName)
                logger.info(capture)
                print(capture)'''

                # 根据任务参数进行采集
                # start=time.time()

                # 开启检测案例超时
                self.case_status.start_check_timeout = True
                # _thread.start_new_thread(check_timeout, (case_status, execute_time_out, udriver, bot, device_s))
                # self.case_status.start_check_timeout()

                # 案例主体运行
                # bot.send_text(f"{device_s} 运行案例主体")


                # 开始采集
                #采集接口临时屏蔽 只保留设置参数接口
                #-capture.all_run_capture()
                logger.info("capture.all_run_capture()")
                #-self.case_status.set_capture(capture)

                perfeye = None
                #-if "perfeye" in capture.performance:
                    #-perfeye = capture.performance["perfeye"]
                #添加用例异常出来标签
                self.parameters['perfeye']=perfeye
                self.parameters['perfeyePid']=-1 #perfeyepid
                self.parameters['func_add_custom_log_file']=self.LogMan.add_custom_log_file
                self.parameters['platform']=self.platform #PC android ios
                if self.bMobile:
                    self.parameters['wda_u2'] = self.Android_IOS.WDA_U2
                else:
                    self.parameters['wda_u2'] =None
                #用例对象 用于处理用例退出后的清理工作
                self.CaseObject=None
                self.parameters["CaseObject"]=None
                case_excute_thread = CaseRunThread(target=case_run.AutoRun, args=(self.parameters,), daemon=True)
                case_excute_thread.start()
                self.case_status.set_case_run_thread_id(case_excute_thread.ident)
                #确保用例开始运行
                timeout = 30  # 超时时间
                start_time = time.time()
                while True:
                    # 循环体
                    time.sleep(1)  # 模拟工作
                    if self.parameters["CaseObject"]:
                        self.CaseObject =self.parameters["CaseObject"]
                        print(f"获取CaseObject成功  退出:{time.time() - start_time}")
                        break

                    if time.time() - start_time > timeout:
                        print(f"获取CaseObject超时  退出:{timeout}")
                        break

                # 开启案例状态检测
                self.case_status.set_CaseObject(self.CaseObject)
                self.case_status.start_check()
                print("case_run.AutoRun")

                case_excute_thread.join(timeout=(execute_time_out + 5) * 60)
                logger.info(f"{self.device_s}, {self.task_running_status_id} 案例线程检测")
                if case_excute_thread.is_alive() or self.case_status.status == self.case_status.TIMEOUT:  # 线程没有退出或者被另一个心跳线程判定为超时
                    logger.error("案例超时, 终止脚本线程")
                    ctypes.pythonapi.PyThreadState_SetAsyncExc(ctypes.c_long(case_excute_thread.ident),ctypes.py_object(SystemExit))

                    raise Exception("案例运行超时")
                if case_excute_thread.run_exception is not None:
                    raise case_excute_thread.run_exception

                ChangeName = case_excute_thread.result
                # 根据用例执行函数的返回值来判断是否需要重启用例
                if ChangeName:
                    self.case_status.casename = ChangeName
                # 案例成功，保存采集数据  返回数据采集报告链接
                #self.report_data = capture.stop_capture(self.case_status)

                if "perfeyePid" in self.parameters:
                    self.task_data["perfeye"] = self.parameters['perfeyePid']  # 用于数据采集子进程清理
                    if "perfeyeReport" in self.parameters:
                        # {'id': 7, 'result': {'ok': True, 'data': None, 'msg': '上传数据成功', 'report_id': '694905b1b92f8f865906d53a'}}}
                        self.report_data["perfeye"] = self.parameters['perfeyeReport']["result"]["report_id"]

                if 'RenderdocReport' in self.parameters:
                    # {"OK": true, "msg": "upload done", "filename": "", "filenames": "", "reportId": 31248}
                    self.report_data["Renderdoc"] = self.parameters['RenderdocReport']["reportId"]
                    self.report_data["appkey"] = self.parameters['AppKey'] #应用ID

                if 'hotPointReport' in self.parameters:
                    self.report_data["hotPoint"]=self.parameters['hotPointReport']

                self.LogMan.log_updata(case, case_run, IsLogCheck, self.parameters)  # 案例完成，上传log
                uplog = False  # 已经上传log

                if self.perfeyesuccessd:
                    self.case_status.case_success()
                else:
                    self.case_status.case_fail()
                    self.bot.send_text(f"{self.device_name}-{self.device_s}- {case['name']} perfeye采集失败，案例无数据")
                    # self.case_status.append(CaseStatus.SUCCESS)
                # change_case_status(self.case_status, CaseStatus.SUCCESS)
                # 案例失败，退出重试
                break

            except Exception as e:
                info = traceback.format_exc()
                print(info)
                logger.info(info)
                '''
                try:
                    if not self.Android_IOS.FindRunIPA_APK(self.Android_IOS.package):  # 运行失败时的闪退检测
                        self.bot.send_text(f"{self.device_name}-{self.device_s}- {case['name']}运行中闪退")
                        # Tgame宕机通知需要另外转发
                        if Throw_Advice().project == "tgame":
                            Throw_Advice().send_msg_card(traceback.format_exc(), self.execute_user, "[19666854]")
                except:
                    pass'''

                self.bot.send_text(f"{self.device_name}-{self.device_s}- {case['name']} 第 {i + 1} 次失败")
                # self.bot.ret_img(self.platform,self.device_s,fasong=True)
                # self.bot.send_text(traceback.format_exc())
                # self.bot.send_msg_card(traceback.format_exc(), self.platform, self.device_s)
                Throw_Advice().send_msg_card(traceback.format_exc(), self.execute_user)
                #print(os_popen("ss|grep 13000"))
                # change_case_status(case_status, CaseStatus.FAIL)
                self.case_status.case_fail()

                # 案例失败，不保存采集数据
                #if capture:
                    #self.report_data = capture.stop_capture(self.case_status,save=False)
                if "perfeyePid" in self.parameters:
                    self.task_data["perfeye"] = self.parameters['perfeyePid']  # 用于数据采集子进程清理
                    if "perfeyeReport" in self.parameters:
                        #{'id': 7, 'result': {'ok': True, 'data': None, 'msg': '上传数据成功', 'report_id': '694905b1b92f8f865906d53a'}}}
                        self.report_data["perfeye"] = self.parameters['perfeyeReport']["result"]["report_id"]


                if uplog:  # 根据是否已经上传log处理
                    if case["retry_times"] < 2:
                        self.LogMan.log_updata(case)  # 案例失败，上传log
                    else:
                        self.LogMan.log_updata(case, case_run, IsLogCheck, self.parameters, retry_number=i + 1)

                # 多人案例同步失败
                if case["execute_machine_count"] > 1:
                    self.sync_fail(case["build_case_id"])
                #if self.bMobile:
                    #self.Android_IOS.CloseIPA_APK(self.Android_IOS.package)

                # self.bot.send_text(f"{self.device_name}-{self.device_s} 游戏启动失败或设备掉线")
                # self.bot.ret_img(self.platform,self.device_s,fasong=True)
                # self.bot.send_msg_card(f"{self.device_name}-{self.device_s} 游戏启动失败或设备掉线",self.platform, self.device_s)
                #Throw_Advice().send_msg_card(f"{self.device_name}-{self.device_s} 游戏启动失败或设备掉线", self.execute_user)
                #self.Android_IOS.unlock()
                #self.LogMan.stop_log()
                #continue

        # 如果案例状态没有变化，则判断为未知原因的失败
        if not self.case_status.is_case_finish():
            self.case_status.case_fail()
            self.bot.send_text(f"{self.device_name}-{self.device_s}- {case['name']} 发生不明原因的错误，导致案例无法完成，检查log")

        # 更新案例状态
        if self.case_status != None:
            if self.report_data==None:
                self.report_data={}
            case_TF=self.case_status.upload_status(self.report_data, case["name"])
            if case_TF:
                if "Profile" in self.report_data:
                    url=f"http://ubox.testplus.cn/project/{self.project_id}/appKey/{self.report_data['appkey']}/detail/{self.report_data['Profile']}/summaryHome"
                    self.bot.send_text(f"{self.device_name}-深度采集成功",case['name'],url)
                if "perfeye"in self.report_data:
                    url=f"http://perfeye.console.testplus.cn/case/{self.report_data['perfeye']}/report?appKey={self.project_id}"
                    collect_type=self.parameters["performance"]
                    print(collect_type)
                    self.bot.send_text(f"{self.device_name}-基础采集成功",case['name'],url)
                    if type(collect_type) == dict:
                        print("collect_type是字典")
                        if type(collect_type["perfeye"])==dict and ("datacompare" in collect_type["perfeye"].keys()):
                            print("提交comapre")
                            token=collect_type["perfeye"]["datacompare"]["token"]
                            cookie=collect_type["perfeye"]["datacompare"]["cookie"]
                            caseid=case["id"]
                            requests.post(f"{self.server_url}/build/compare/perfeye/add",json={
                                "case_id": caseid,
                                "device_iden":self.device_s,
                                "cookie": cookie,
                                "token": token,
                                "url": url
                            })

                    if "RLT" in self.report_data:
                        requests.post("http://10.11.66.69:7788/api/file/report/perfeye-url/update", json={
                            "reportId": self.report_data["RLT"],
                            "perfeyeUid": self.report_data["perfeye"]
                        })

                else:
                    self.bot.send_text(f"{self.device_name}-案例成功 {case['name']}")

    # 初始化当前案例运行所需参数
    def init_parameters(self, case):
        # 处理参数  覆盖优先级:任务>设备>案例
        parameters = {}
        self.case_parameters = case["parameters"]
        if self.case_parameters != None:
            if type(self.case_parameters) == str:
                self.case_parameters = json.loads(self.case_parameters)

            for key in self.case_parameters.keys():
                parameters[key] = self.case_parameters[key]

        # 账号信息
        parameters["account"] = case["account"]
        # 画质信息
        parameters["quality"] = self.device_quality
        parameters['name']=case["name"]  #案例名称
        parameters['english_name'] = case["english_name"]  # 案例标识
        parameters['execute_times'] = case["execute_times"]  # 执行次数
        parameters['retry_times'] = case["retry_times"]  # 重试次数
        parameters['execute_time_out'] = case["execute_time_out"]  # 超时时间(分)
        parameters['project_id'] = case["project_id"]  # 项目标识
        parameters['file_path'] = case["file_path"]  # 执行脚本名称

        parameters["device_name"] = self.device_name  #设备名称
        parameters['device_type'] = self.device_type  # 机型
        parameters["device_unique_identifier"] = self.device_unique_identifier #运行设备号(usb)
        parameters['device_identifier'] = self.device_identifier  # 运行时设备号(usb或wifi)
        parameters["device_ip"] = self.device_ip #设备IP
        parameters['platform'] = self.platform  # 设备平台
        parameters['id'] = case['id']  #
        parameters['build_id'] = case['build_id']  #
        parameters['build_case_id'] = case['build_case_id']  #
        parameters['device_id'] = case['device_id']  #
        parameters['appKey']=case['project_id']

        #传入飞书
        parameters["feishu_bot"] = self.bot

        #除了装包用例默认采集perfeye数据
        if parameters['file_path']=='CaseXGameGetPackage.py':
            parameters['performance']={}
        else:
            parameters['performance'] = {'perfeye': {}}

        #设备号、设备系统版本号
        parameters["device"] = self.device_s
        parameters["osVersion"] = self.osVersion

        #将device_parameters存储进parameters字典中 #设备自定义参数
        parameters["devices_custom"] = dict(json.loads(self.device_parameters)) # 字符串转字典 需要可保留不需要转可直接删除

        # WDA_U2 手机操控
        if self.bMobile:
            #module = importlib.reload(ad_ios)
            parameters["WDA_U2"] = ad_ios.Wda_u2_operate(self.Android_IOS.WDA_U2)
            # 设备自定义包名
            if 'perfmon_info' in parameters["devices_custom"] and 'package' in parameters["devices_custom"]['perfmon_info']:
                parameters["package"]=parameters["devices_custom"]['perfmon_info']['package']
                self.Android_IOS.package=parameters["package"]
            #任务参数自定义包名
            else:
                if 'package' in parameters:  #用例参数填写包名
                    self.Android_IOS.package=parameters["package"]
                else:
                    parameters["package"] = self.Android_IOS.package
        else:
            parameters["WDA_U2"]=None
            parameters["package"] =None


        if self.task_parameters is not None:

            for key in self.task_parameters.keys():
                # 如果在任务参数中的 devices 字段中设置了设备（ID）特殊参数，将会使用里面指定的特殊参数覆盖掉外层的全局参数
                if key == "devices":
                    devices = self.task_parameters[key]
                    if str(self.device_id) in devices.keys():
                        for replace_key in devices[str(self.device_id)].keys():
                            parameters[replace_key] = devices[str(self.device_id)][replace_key]
                    continue
                parameters[key] = self.task_parameters[key]

        if "task_running_status_id" in case :
            self.task_running_status_id=case["task_running_status_id"]
        if case["execute_machine_count"] > 1:
            parameters["wait_sync"] = wait_sync_factory(self.task_running_id, case["build_case_id"], self.device_id, self.bot,self.task_parameters, self.server_url,self.device_name)

        logger.info(f"parameters为{parameters}")
        print(f"parameters为{parameters}")
        return parameters

    def import_module(self, case):
        # 动态导入模块
        # TODO: 在实际导入模块前，需要更新对应的模块代码

        case_file_path = case["file_path"]
        if case_file_path.endswith(".py"):
            case_file_path = case_file_path[:-3]
        case_file_path = case_file_path.replace("/", ".")

        if self.use_new_git:
            module_load = [f"new_projects.{case['project_id']}.{self.dir_name}.u3driver", f"new_projects.{case['project_id']}.{self.dir_name}.{case_file_path}"]
            module_path_ex = os.path.join("new_projects", self.project_id, self.dir_name)
        else:
            #module_load = [f"projects.{case['project_id']}.u3driver", f"projects.{case['project_id']}.{case_file_path}"]
            module_load = [f"projects.{case['project_id']}.{case_file_path}"]
            module_path_ex = os.path.join("projects", self.project_id)

        modules = get_module(module_load, self.project_id, self.project_file_lock, module_path_ex)

        # TODO: 有些案例的准备需要运行其他案例主体，需要在参数中获取到，然后把这部分案例加载进来，并根据参数设置运行

        #u3driver = modules[0]
        #case_run = modules[1]
        u3driver = None
        case_run = modules[0]


        # 如果项目内存在 checkpoint 模块，获取 checkpoint
        ''''''
        if self.use_new_git:
            checkpoint_module_load = [f"new_projects.{case['project_id']}.{self.dir_name}.checkpoint"]
            checkpoint_path_ex = os.path.join("new_projects", self.project_id, self.dir_name)
            checkpoint_path = os.path.join(os.getcwd(), checkpoint_path_ex, "checkpoint.py")
        else:
            checkpoint_module_load = [f"projects.{case['project_id']}.checkpoint"]
            checkpoint_path_ex = os.path.join("projects", self.project_id)
            checkpoint_path = os.path.join(os.getcwd(), checkpoint_path_ex, "checkpoint.py")

        checkpoint = None
        if os.path.exists(checkpoint_path):
            checkpoint_module = get_module(checkpoint_module_load, self.project_id, self.project_file_lock, module_path_ex)
            checkpoint = checkpoint_module[0]

        # 案例前置操作需要导入的额外模块
        before_runs = []
        before_run_module_load = []

        #预处理模块调用
        if self.case_parameters != None and "before_run" in self.case_parameters.keys():
            for before_run_case in self.case_parameters["before_run"]:
                file_path = before_run_case["file_path"]
                if file_path.endswith(".py"):
                    file_path = file_path[:-3]
                file_path = file_path.replace("/", ".")

                if self.use_new_git:
                    before_run_module_load.append(f"new_projects.{case['project_id']}.{self.dir_name}.{file_path}")
                else:
                    before_run_module_load.append(f"projects.{case['project_id']}.{file_path}")


        before_run_modules = get_module(before_run_module_load, self.project_id, self.project_file_lock, module_path_ex)

        for i, before_run_module in enumerate(before_run_modules):
            item = {
                "module": before_run_module,
                "func": self.case_parameters["before_run"][i]["func"]
            }
            before_runs.append(item)

        return u3driver, before_runs, case_run, checkpoint

    def sync_fail(self, build_case_id):


        if 'team' in self.task_parameters.keys():
            response = requests.post(f"{self.server_url}/build/controller/sync/fail", params={
            "buildId": self.task_running_id,
            "buildCaseId": build_case_id,
            "deviceId": self.device_id
        })
        else:
            response = requests.post(f"{self.server_url}/build/controller/sync/fail", params={
            "buildId": self.task_running_id,
            "buildCaseId": build_case_id,
            "deviceId": self.device_id
        })
        print(f"/sync/fail: {response.content}")
        ret = json.loads(response.content)

        return ret

    # 手机电量检测并发飞书
    # def electric_quantity(self):
    #     if "android" in self.platform:
    #         battery_cmd = f"adb -s {self.Android_IOS.devices} shell dumpsys battery"
    #         output = os_popen(battery_cmd).split("\n")
    #         dict = {}
    #         for i in output:
    #             new_i = i.strip(" ").split(":")
    #             if len(new_i) == 1:
    #                 del new_i
    #             else:
    #                 key = new_i[0]
    #                 value = new_i[1]
    #                 dict[key] = value
    #         battery_remain = int(dict["level"].strip(""))
    #         return battery_remain
    #     else:
    #         p = os.popen(f"tidevice -u {self.device_s} battery")
    #         output = p.buffer.read().decode('utf-8')
    #         output = output.split()
    #         p.close()
    #         battery_remain = int(output[1].replace('%', ''))
    #         return battery_remain

class CaseStatus(object):
    UNSTART = "QUEUE"
    WAITING = "QUEUE"
    RUNNING = "RUNNING"
    SUCCESS = "SUCCESS"
    FAIL = "FAILED"
    CANCEL = "CANCEL"
    TIMEOUT = "TIMEOUT"

    def __init__(self, process_call_func,task_running_id: int, task_parameters:dict, case_id:int, device_id:int, bot: auto_rebot.FeiShutalkChatbot, execute_time_out, device_s,fzhu,task_running_status_id, build_case_id:int):
        self.case_status_lock = threading.Lock()
        self.server_url = SERVER_URL
        self.task_running_id= task_running_id
        self.task_parameters = task_parameters
        self.case_id = case_id
        self.build_case_id = build_case_id
        self.device_id = device_id
        self.bot = bot
        self.execute_time_out = execute_time_out+180  #剑网3超时由用例脚本控制
        self.device_s = device_s
        self.status = CaseStatus.RUNNING
        self.task_running_status_id=int(task_running_status_id)
        self.start_check_timeout=False
        sys.stderr=fzhu
        self.capture=None
        self.casename=""
        self._main_process_call = process_call_func
        self._case_run_thread_id = None

    def set_capture(self,capture:CapTure):
        self.capture=capture

    def set_case_run_thread_id(self, id):
        self._case_run_thread_id = id

    def set_udriver(self, udriver):
        self.udriver = udriver

    def set_CaseObject(self,CaseObject):
        self.CaseObject=CaseObject

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
                response = requests.get(f"{self.server_url}/build/controller/sync/check", params={
                "buildId": self.task_running_id,
                "buildCaseId": self.build_case_id,
                "deviceId": self.device_id
            })
            else:
                response = requests.get(f"{self.server_url}/build/controller/sync/check", params={
                "buildId": self.task_running_id,
                "buildCaseId": self.build_case_id,
                "deviceId": self.device_id
            })

            print(f"/sync/check: {response.content}")
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

    def start_check(self):
        self.timeout_thread = _thread.start_new_thread(self._check_timeout, ())

    def _check_timeout(self):
        try:
            startTime=datetime.datetime.now()
        except:
            startTime = datetime.now()
        startNumber=0
        logger.info(f"控制器超时时间:{self.execute_time_out}")
        print(f"控制器超时时间:{self.execute_time_out}")
        while True:
            # 案例完成，结束检查
            if self.is_case_finish():
                break
            if True or startNumber%6==0: # 对6取模是为了控制API访问频率
                try:
                    response = requests.get(f"{self.server_url}/build/controller/case/running/status", params={
                    "deviceCaseId": self.task_running_status_id}).json()
                    case_status=response["data"]
                    logger.info(f"{self.device_s}, {self.task_running_status_id} 当前案例状态: {case_status}")

                    if case_status==CaseStatus.RUNNING:
                        # print("案例正在执行中(正常状态)")
                        pass
                    else:
                        # WAITING状态是案例取消后又进行了重试, 这种状态下应该也结束当前案例
                        print(f"案例已经被取消 (异常状态):{self._case_run_thread_id}")
                        logger.info(f"{self.device_s}, {self.task_running_status_id} 案例取消!准备中止脚本线程")
                        self.bot.send_text(f"{self.device_s} 案例被取消了,10s 后终止案例")
                        #time.sleep(2)
                        if self._change_case_status(CaseStatus.CANCEL):
                            #self.capture.stop_capture(self,save=False)
                            #self.udriver.stop()
                            print("已发出线程终止信号 start")
                            ctypes.pythonapi.PyThreadState_SetAsyncExc(ctypes.c_long(self._case_run_thread_id), ctypes.py_object(SystemExit))
                            #等待用例清理结束
                            timeout = 30  # 超时时间
                            start_time = time.time()
                            while True:
                                # 循环体
                                time.sleep(1)  # 模拟工作
                                print(f"等待TearnDown 结束")
                                if not hasattr(self,'CaseObject') or not self.CaseObject:
                                    print("TearnDown 获取CaseObject失败  退出")
                                    break

                                if self.CaseObject.bTeardownEnd:
                                    print("TearnDown 成功 退出")
                                    break

                                if time.time() - start_time > timeout:
                                    print("TearnDown 超时 退出")
                                    break

                            logger.info("已发出线程终止信号")
                            print("已发出线程终止信号 stop")
                        break
                except Exception as e:
                    logger.error(f"监控案例状态异常: {e}, {traceback.format_exc()}")

            if self.start_check_timeout:
                #案例超时由用例控制
                try:
                    current_time = datetime.datetime.now()
                except:
                    current_time = datetime.now()
                if startTime+timedelta(minutes=self.execute_time_out)<current_time:
                    print(f"{self.device_s} 案例超时")
                    self.bot.send_text(f"{self.device_s} 案例超时")
                    if self._change_case_status(CaseStatus.TIMEOUT):
                        #self.udriver.stop()
                        #self.capture.stop_capture(self,False)
                        print("超时 已发出线程终止信号 start")
                        ctypes.pythonapi.PyThreadState_SetAsyncExc(ctypes.c_long(self._case_run_thread_id),ctypes.py_object(SystemExit))
                        # 等待用例清理结束
                        timeout = 30  # 超时时间
                        start_time = time.time()
                        while True:
                            # 循环体
                            time.sleep(1)  # 模拟工作
                            if not hasattr(self, 'CaseObject') or not self.CaseObject:
                                print("TearnDown 获取CaseObject失败  退出")
                                break

                            if self.CaseObject.bTeardownEnd:
                                print("TearnDown 成功 退出")
                                break

                            if time.time() - start_time > timeout:
                                print("TearnDown 超时 退出")
                                break

                        logger.info("超时 已发出线程终止信号")
                        print("超时 已发出线程终止信号 stop")
                        pass
                    exit()
            time.sleep(10)
            startNumber+=1

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

    def safe_dump_report_data(self, report_data):
        try:
            return json.dumps(report_data)
        except Exception as e:
            logger.error(f"dump report data error: {e}, {traceback.format_exc()}")
            return "{}"


    def upload_status(self, report_data, case_name):
        # 案例运行完成，上传结果
        if CaseStatus.SUCCESS == self.status:

            response = requests.post(f"{self.server_url}/build/controller/complete/case", json={
                "buildCaseId": self.build_case_id,
                "buildId": self.task_running_id,
                "deviceId": self.device_id,
                "caseId": self.case_id,
                "reportData": self.safe_dump_report_data(report_data),
                "status": "success",
                "errorMsg": ""
            })

            print(response.content.decode("utf-8"))
            print(f"案例成功 {case_name}-{self.device_s}")
            #self.bot.send_text(f"案例成功{case_name}{self.device_s}")
            return True
        else:
            response = requests.post(f"{self.server_url}/build/controller/complete/case", json={
                "buildCaseId": self.build_case_id,
                "buildId": self.task_running_id,
                "deviceId": self.device_id,
                "caseId": self.case_id,
                "reportData": self.safe_dump_report_data(report_data),
                "status": "fail",
                "errorMsg": self.status,
            })

            print(response.content.decode("utf-8"))
            # bot.send_text(f"{device_s} {case['name']} 案例失败，不再重新执行")
            print(f"{self.device_s} - {case_name} 案例失败，不再重新执行")

        return False

class CaseRunThread(threading.Thread):
    def run(self):
        """Method representing the thread's activity.

        You may override this method in a subclass. The standard run() method
        invokes the callable object passed to the object's constructor as the
        target argument, if any, with sequential and keyword arguments taken
        from the args and kwargs arguments, respectively.
        """
        self.result = None
        self.run_exception = None
        try:
            if self._target is not None:
                self.result = self._target(*self._args, **self._kwargs)
        except Exception as e:
            self.run_exception = e
            logger.info(e)
        finally:
            # Avoid a refcycle if the thread is running a function with
            # an argument that has a member that points to the thread.
            del self._target, self._args, self._kwargs
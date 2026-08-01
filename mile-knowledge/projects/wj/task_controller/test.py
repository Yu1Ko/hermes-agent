import _thread
import ctypes
import json
import os
import sys
import threading
import time
import trace
import traceback
# print(get_description("1 2 * * *"))
from datetime import datetime
import requests
import uiautomator2 as u2

# import win32con
# import win32gui
# from cron_descriptor import ExpressionDescriptor, get_description
# from crontab import CronTab
# from projects.jx1pocket.u3driver import AltrunUnityDriver, By


# from win32gui import *


# rlock = threading.RLock()

# def a():
#     print("a start")
#     haslock = rlock.acquire(timeout=10)
#     if haslock:
#         while True:
#             time.sleep(10)
#             print("a")
#     if haslock:
#         rlock.release()

# def b():
#     print("b start")
#     rlock.release()
#     haslock = rlock.acquire()
#     if haslock:
#         time.sleep(10)
#         print("b")
#     rlock.release()


# _thread.start_new_thread(a, ())
# time.sleep(5)
# _thread.start_new_thread(b, ())

# time.sleep(60)

class thread_with_exception(threading.Thread): 
    def __init__(self, name):
        threading.Thread.__init__(self)
        self.name = name
    def run(self): 
        # target function of the thread class 
        try: # 用try/finally 的方式处理exception，从而kill thread
            while True: 
                print('running ' + self.name) 
                time.sleep(10)
        finally: 
            print('ended') 
        
    def get_id(self): 
        # returns id of the respective thread 
        if hasattr(self, '_thread_id'): 
            return self._thread_id 
        for id, thread in threading._active.items(): 
            if thread is self: 
                return id

    def raise_exception(self): 
        thread_id = self.get_id() 
                #精髓就是这句话，给线程发过去一个exceptions，线程就那边响应完就停了
        res = ctypes.pythonapi.PyThreadState_SetAsyncExc(thread_id, 
            ctypes.py_object(SystemExit)) 
        if res > 1: 
            ctypes.pythonapi.PyThreadState_SetAsyncExc(thread_id, 0) 
            print('Exception raise failure')
    
    def is_active(self):
        # ret = False
        for id, thread in threading._active.items(): 
            if thread is self:
                return True
        return False


# t1 = thread_with_exception('Thread 1') 
# t1.start()
# time.sleep(3)

# print(t1.is_active())

# time.sleep(3)
# t1.raise_exception()

# time.sleep(1)
# print(t1.is_active())
# time.sleep(10)


import multiprocessing

# def func(number): 
# 	for i in range(1, 10): 
# 		time.sleep(0.01) 
# 		print('Processing ' + str(number) + ': prints ' + str(number*i)) 
# # list of all processes, so that they can be killed afterwards 
# all_processes = [] 
# for i in range(0, 3): 
# 	process = multiprocessing.Process(target=func, args=(i,)) 
# 	process.start() 
# 	all_processes.append(process) 
# # kill all processes after 0.03s 
# time.sleep(0.03) 
# for process in all_processes: 
# 	process.terminate() #精髓在这里



def func(number): 
    while True:
        print("running")
        time.sleep(10)
# list of all processes, so that they can be killed afterwards 

import importlib
import subprocess


def callback(path):
    print(path)


import ad_ios
import pyfeishu
from FakeOut import FakeOut
from TaskRunProcess import TaskRunProcess

task_cancel_lock = threading.Lock()
# 任务中止清理
def task_cancel(device_id, device_s, task_data, bot, process_lock):

    time.sleep(10)
    with task_cancel_lock:
        try:
            response = requests.post(f"{server_url}/device/free", json={
                "id": device_id
            })
            print(f'释放设备: {response.content.decode("utf-8")}')

            if "perfeye" in task_data.keys() and task_data["perfeye"] != -1:
                print(os.popen(f'ps -ef |grep miniperf').read())
                # 使用 kill 命令杀掉 perfeye 的进程
                os.popen(f'kill -9 {task_data["perfeye"]}').read()
                print(os.popen(f'ps -ef |grep miniperf').read())
            
            if "platform" in task_data.keys():

                platform = task_data["platform"]
                package_url = task_data["package_url"]
                package_info = task_data["package_info"]
                port = task_data["port"]
                adio = ad_ios.Android_IOS(device_s, platform, package_url, package_info, process_lock, port)
                adio.CloseIPA_APK(adio.package)
                time.sleep(3)
                adio.lock()



            bot.send_text(f"任务中止 {task_running_id}")
        except Exception as e:
            print(f"任务清理失败：{traceback.format_exc()}")
            bot.send_text(f"任务清理失败：{traceback.format_exc()}")

def task_cancel_test(running_process, device_id, device_s, task_data, bot, process_lock):
    time.sleep(10)
    
    if running_process.is_alive():
        running_process.terminate()
        running_process.join()

        task_cancel(device_id,device_s,task_data,bot, process_lock)

# 自动化服务器
server_url = "http://10.11.86.106:8000"

if __name__ == "__main__":

    bot = pyfeishu.FeiShutalkChatbot("https://open.feishu.cn/open-apis/bot/v2/hook/3c482c3d-8b12-43d2-92cc-ae4c0db92f0f")

    running_task = {}

    # 使用 Manager 管理多进程同步数据
    mgr = multiprocessing.Manager()

    log_lock = multiprocessing.Lock()


    fzhu=FakeOut(log_lock)
    old=sys.stdout
    
    zident=threading.current_thread().ident
    print(f"主线程id:{zident}")
    sys.stdout=fzhu
    sys.stderr=fzhu
    fzhu.add_output(zident,old)

    count = 0

    print(f"活动线程: {threading.enumerate()}")

    project_file_lock = multiprocessing.Lock()
    # case_status_lock = multiprocessing.Lock()

    # 开始运行后不退出，一直获取任务并执行
    try:
        while True:

            # 获取未连接的设备，并尝试重新连接
            response = requests.get(f"{server_url}/device_controller/get_disconnected_device")
            print(response.content.decode("utf-8"))
            disconnected_devices = json.loads(response.content.decode("utf-8"))["data"]
            for device in disconnected_devices:

                # 根据不同平台做不同重连处理
                if device["os"] == "android" and ':' in device["device_identifier"]:
                    ad_ios.ConnectADB(device["ip"])

            # 同步连接设备
            devices = ad_ios.GetConnecteddevices()
            response = requests.post(f"{server_url}/device_controller/heartbeat", json={
                "devices": devices
            })
            print(response.content.decode("utf-8"))

            # 检测任务是否被中止（取消）（完成）
            for task_running_id in list(running_task.keys()):
                
                running_task_list = running_task[task_running_id]

                # 检查任务是否完成
                for running_task_item in running_task_list[::]:
                    running_process = running_task_item["process"]
                    if not running_process.is_alive():
                        running_task_list.remove(running_task_item)

                # 检查任务是否被取消
                response = requests.get(f"{server_url}/task_run/running_task_is_cancel", params={
                    "task_running_id": int(task_running_id)
                })

                print(response.content.decode("utf-8"))
                ret = json.loads(response.content)

                if ret["code"] == 200:
                    
                    # 返回结果为没有下一个需要跑的案例的设备id的列表
                    finish_running_device = ret["data"]

                    if len(finish_running_device) > 0:
                        # 任务被取消，关闭运行进程
                        for running_task_item in running_task_list[::]:

                            device_id = running_task_item["device_id"]

                            if not device_id in finish_running_device:
                                continue

                            device_s = running_task_item["device_s"]
                            task_data = running_task_item["task_data"]
                            running_process = running_task_item["process"]
                            feishu_token = running_task_item["feishu_token"]

                            new_bot = pyfeishu.FeiShutalkChatbot(feishu_token)

                            task_data = dict(task_data)

                            # 延时进行清理，避免将刚完成的任务误认为是被中止的任务
                            _thread.start_new_thread(task_cancel_test, (running_process, device_id, device_s, task_data, new_bot, project_file_lock))

                            new_bot.send_text(f"开始任务清理 {device_id} {task_running_id}")
                            print(f"开始任务清理 {device_id} {task_running_id}")

                            running_task_list.remove(running_task_item)

                if len(running_task_list) == 0:
                    # 移除已完成（取消）的任务
                    running_task.pop(task_running_id)




            # 获取任务
            response = requests.get(f"{server_url}/task_run/get_contorller_task")
            print(f'新任务：{response.content.decode("utf-8")}')

            ret = json.loads(response.content)
            # print(ret["data"])
            if ret["code"]==200:
                if len(ret["data"]) > 0 :
                    print("启动新任务")

                    running_task_list = []
                    if str(ret["data"][0]["task_running_id"]) in running_task.keys():
                        running_task_list = running_task[str(ret["data"][0]["task_running_id"])]

                    for item in ret["data"]:
                        device = item["device"]
                        package_url = item["package_url"]
                        package_info=item["package_info"]
                        task_running_id = item["task_running_id"]
                        task_parameters = item["task_parameters"]
                        # task_parameters=None
                        project_id = item["project_id"]
                        feishu_token = item["feishu_token"]


                        task_data = mgr.dict()
                        
                        process = TaskRunProcess(device["device_identifier"], device["ip"], device["os"], device["port"], package_url, package_info, device["id"],device["quality"], task_running_id,task_parameters, project_id, feishu_token, project_file_lock, task_data, server_url)
                        # process = multiprocessing.Process(target=start_task, args=(
                        #     device["device_identifier"], device["ip"], device["os"], device["port"], package_url, package_info, device["id"], device["quality"], task_running_id, task_parameters, project_id, feishu_token, project_file_lock, task_data))
                        process.start() 
                        

                        # # 记录运行子进程
                        running_task_item = {
                            "process": process,
                            "task_data": task_data,
                            "device_id": device["id"],
                            "package_info": package_info,
                            "device_s": device["device_identifier"],
                            "feishu_token": feishu_token
                            # "id": new_thread.get_id()
                        }

                        running_task_list.append(running_task_item)
                    
                    running_task[str(ret["data"][0]["task_running_id"])] = running_task_list
            else:
                bot.send_text(ret["msg"])
            nowtime=str(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()))
            print(f"running_task: {running_task}")

            time.sleep(60)

    except Exception as e:
        print(f"主进程出现错误：{traceback.format_exc()}")
        bot.send_text(f"主进程出现错误：{traceback.format_exc()}")


        # 清理所有正在运行的任务
        for key in running_task:
            for item in running_task[key]:
                try:
                    device_id = item["device_id"]
                    device_s = item["device_s"]
                    task_data = item["task_data"]
                    running_process = item["process"]
                    feishu_token = item["feishu_token"]

                    new_bot = pyfeishu.FeiShutalkChatbot(feishu_token)

                    task_data = dict(task_data)

                    
                    print(f"清理任务{item}")

                    # 延时进行清理，避免将刚完成的任务误认为是被中止的任务
                    _thread.start_new_thread(task_cancel_test, (running_process, device_id, device_s, task_data, new_bot, project_file_lock))
                except:
                    print(f"任务清理失败：{item}")

        time.sleep(60)


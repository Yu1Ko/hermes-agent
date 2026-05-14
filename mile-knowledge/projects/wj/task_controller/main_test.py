import _thread
from ast import If
import copy
import json
import multiprocessing
import os
import sys
import threading
import time
import traceback
import requests
import ad_ios
from heart_sync import Heart_Sync
import pyfeishu
from FakeOut import FakeOut
from TaskRunProcess_test import TaskRunProcess

task_cancel_lock = threading.Lock()
# 任务中止清理
def task_cancel(device_id, device_s, task_data, bot, process_lock,task_run_id):

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



            bot.send_text(f"任务中止 {task_run_id}")
        except Exception as e:
            print(f"任务清理失败：{traceback.format_exc()}")
            bot.send_text(f"任务清理失败：{traceback.format_exc()}")

def task_cancel_test(running_process, device_id, device_s, task_data, bot, process_lock,task_run_id):
    time.sleep(5)
    
    if running_process.is_alive():
        running_process.terminate()
        running_process.join()

        task_cancel(device_id,device_s,task_data,bot, process_lock,task_run_id)

# 自动化服务器
server_url = "http://10.11.86.106:8000"

if __name__ == "__main__":

    bot = pyfeishu.FeiShutalkChatbot("https://open.feishu.cn/open-apis/bot/v2/hook/268abcf5-ae86-49e0-8b41-dde897101254")

    task_running_id=None
    # 使用 Manager 管理多进程同步数据
    mgr = multiprocessing.Manager()

    log_lock = multiprocessing.Lock()
    #device_lock=multiprocessing.Lock()

    fzhu=FakeOut(log_lock)
    old=sys.stdout
    running_task_list = []
    zident=threading.current_thread().ident
    print(f"主线程id:{zident}")
    sys.stdout=fzhu
    sys.stderr=fzhu
    fzhu.add_output(zident,old)

    count = 0

    print(f"活动线程: {threading.enumerate()}")
    perfeyeport=mgr.Value("i",2000)
    runingtasknum=0
    perfeyeportlock=multiprocessing.Lock()
    project_file_lock = multiprocessing.Lock()
    task_status_lock = multiprocessing.Lock()
    # case_status_lock = multiprocessing.Lock()
    response = requests.get(f"{server_url}/device_controller/reset_device_status")
    # 开始运行后不退出，一直获取任务并执行
    DisConnectData=mgr.list()
    CancelTaskData=mgr.Queue()
    RunlTaskData=mgr.Queue()
    FinishTaskData=mgr.list()
    running_task={}
    running_task_s=mgr.dict()
    process = Heart_Sync(server_url,running_task_s,DisConnectData,CancelTaskData,RunlTaskData,FinishTaskData,bot,log_lock,old,task_status_lock)
    process.start() 
    try:
        while True:

            # 获取未连接的设备，并尝试重新连接
            if DisConnectData[:]:
                for device in DisConnectData:
                # 根据不同平台做不同重连处理
                    if device["os"] == "android" and ':' in device["device_identifier"]:
                        ad_ios.ConnectADB(device["ip"])
                DisConnectData[:]=[]
            with task_status_lock:
                if FinishTaskData[:]:
                    print("任务完成")
                    print(FinishTaskData)
                    listP=list(set(FinishTaskData))
                    last_running_task=running_task.copy()
                    last_running_task_s=copy.deepcopy(running_task_s)
                    for key in running_task.keys():
                        #if key in running_task.keys():
                        # 检查任务是否完成
                        for running_task_item in running_task[key]:
                            if running_task_item["processid"] in listP:
                                last_running_task[key].remove(running_task_item)
                        for running_task_item_s in last_running_task_s[key]:
                            if running_task_item_s["processid"] in listP:
                                last_running_task_s[key].remove(running_task_item_s)
                        if len(last_running_task_s[key]) == 0:
                            # 移除已完成（取消）的任务
                            last_running_task.pop(key)
                            last_running_task_s.pop(key)
                    print(f"last_running_task_s {last_running_task_s} last_running_task {last_running_task}")
                    running_task=last_running_task.copy()
                    delpop=list(set(running_task_s.keys())-set(last_running_task_s.keys()))
                    for key in delpop:
                        running_task_s.pop(key)
                    running_task_s.update(last_running_task_s)
                    FinishTaskData[:]=[]
                    
                CancelTaskdict={}
                while CancelTaskData.empty()!=True:
                    # 返回结果为没有下一个需要跑的案例的设备id的列表
                    finish_running = CancelTaskData.get()
                    bol=True
                    for key in CancelTaskdict.keys():
                        if key==finish_running["task_running_id"]:
                            CancelTaskdict[key].extend(finish_running["data"])
                            CancelTaskdict[key]=list(set(CancelTaskdict[key]))
                            bol=False
                            break
                    if bol:
                        CancelTaskdict[finish_running["task_running_id"]]=finish_running["data"]
                for key in CancelTaskdict.keys():
                    if len(CancelTaskdict[key]) > 0 and key in running_task.keys():
                        # 任务被取消，关闭运行进程
                        running_task_list = running_task[key]
                        running_task_list_s=running_task_s[key]
                        for running_task_item in running_task_list[::]:

                            device_id = running_task_item["device_id"]
                            device_name = running_task_item["device_name"]
                            all_task_running_id=running_task_s.keys()
                            if (not device_id in CancelTaskdict[key]) or (key not in all_task_running_id):
                                continue
                            device_s = running_task_item["device_s"]
                            task_data = running_task_item["task_data"]
                            running_process = running_task_item["process"]
                            feishu_token = running_task_item["feishu_token"]

                            new_bot = pyfeishu.FeiShutalkChatbot(feishu_token)

                            task_data = dict(task_data)

                            # 延时进行清理，避免将刚完成的任务误认为是被中止的任务
                            _thread.start_new_thread(task_cancel_test, (running_process, device_id, device_s, task_data, new_bot, project_file_lock,key))

                            new_bot.send_text(f"开始任务清理 {device_name} {key}")
                            print(f"开始任务清理 {device_id} {device_name}{key}")
                            
                            running_task_list.remove(running_task_item)
                            running_task_item_s={
                            "processid": running_process.pid
                            # "id": new_thread.get_id()
                            }
                            print("任务完成")
                            #if running_task_item_s in running_task_list_s:
                            running_task_list_s.remove(running_task_item_s)
                        running_task_s.update({key:running_task_list_s})
                        if len(running_task_list_s) == 0:
                            # 移除已完成（取消）的任务
                            if key in running_task.keys():
                                running_task.pop(key)
                            if key in running_task_s.keys():
                                running_task_s.pop(key)



            print(f"allruntask {running_task}")
            # 获取任务
            RunTaskAll=[]
            while RunlTaskData.empty()!=True:
                RunTaskAll= RunlTaskData.get()

            if RunTaskAll:
                print("启动新任务")
                for item in RunTaskAll:
                    running_task_list = []
                    running_task_list_s = []
                    if str(item["task_running_id"]) in running_task_s.keys():
                        running_task_list_s=running_task_s[str(item["task_running_id"])]
                        running_task_list=running_task[str(item["task_running_id"])]
                    print(f"新任务——S{running_task_list} {running_task_list_s}")
                    device = item["device"]
                    package_url = item["package_url"]
                    package_info=item["package_info"]
                    task_running_id = item["task_running_id"]
                    task_parameters = item["task_parameters"]
                    # task_parameters=None
                    project_id = item["project_id"]
                    feishu_token = item["feishu_token"]
                    otalist=["com.oppo.ota","com.coloros.sau","com.oppo.otaui","com.huawei.android.hwouc","com.heytap.market"]
                    if(device["os"]=="android"):
                        try:
                            apklist=os.popen(f"adb -s {device['device_identifier']} shell \"pm list packages\"").read().splitlines()
                            for apk in apklist:
                                if apk.split("package:")[-1] in otalist:
                                    cancelapk=apk.split("package:")[-1]
                                    os.popen(f"adb -s {device['device_identifier']} shell \"pm disable-user {cancelapk}\"")
                        except Exception as e:
                            print(e)
                    if device["udriver_port"]!=13000 and device["ip"]=="127.0.0.1":
                        print("启动本地映射")
                        udriver_port=device["udriver_port"]
                        portresult=os.popen(f"adb -s \"{device['device_identifier']}\" forward tcp:{udriver_port} tcp:13000").read()
                        print(portresult)

                    task_data = mgr.dict()
                    if device["status"]!=1:
                        process = TaskRunProcess(device["device_identifier"], device["ip"], device["os"], device["port"], package_url, package_info, device["id"],device["quality"], task_running_id,task_parameters, project_id, feishu_token, project_file_lock, task_data, server_url,device["name"],perfeyeport,perfeyeportlock,FinishTaskData,task_status_lock,device["udriver_port"])
                    # process = multiprocessing.Process(target=start_task, args=(
                    # process = multiprocessing.Process(target=start_task, args=(
                    #     device["device_identifier"], device["ip"], device["os"], device["port"], package_url, package_info, device["id"], device["quality"], task_running_id, task_parameters, project_id, feishu_token, project_file_lock, task_data))
                        process.start() 
                    else:
                        continue

                    # # 记录运行子进程
                    running_task_item = {
                        "process": process,
                        "task_data": task_data,
                        "device_id": device["id"],
                        "package_info": package_info,
                        "device_s": device["device_identifier"],
                        "feishu_token": feishu_token,
                        "device_name": device["name"],
                        "processid": process.pid
                        # "id": new_thread.get_id()
                    }
                    running_task_item_pid = {
                        "processid": process.pid,
                        }
                    stra=str(item["task_running_id"]) 
                    print(f"创建进程：{running_task_item} {process.pid} {stra}")
                    running_task_list_s.append(running_task_item_pid)
                    running_task_list.append(running_task_item)
                    running_task[str(item["task_running_id"])] = running_task_list
                    running_task_s[str(item["task_running_id"])]=running_task_list_s
                print(f"线程添加列表 {running_task_s}\n {running_task}")
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


        while True:
            time.sleep(60)
            print(f"当前主进程线程数{threading.enumerate()}")
            if threading.enumerate() == 1:
                break


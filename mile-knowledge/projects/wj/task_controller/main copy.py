import _thread
import ctypes
import importlib
import json
import multiprocessing
import os
import sys
import threading
import time
import traceback
import ad_ios
from ad_ios import Wda_u2_operate as wu2, Android_IOS as AdIo
import requests
import gpu_temp
import pyfeishu
import record_android_trace
from FakeOut import FakeOut
from tp import TPlus


class CaseStatus(object):
    # UNSTART = 0
    # WAITING = 1
    # RUNNING = 2
    SUCCESS = 3
    FAIL = 4
    CANCEL = 5
    TIMEOUT = 7

# project_file_lock = threading.Lock()
# 需要加锁，避免同时两个项目在导入时由于 sys.path 里面添加了两个路径导致找错对应的模块
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

# 修改案例状态（由于多线程读写，需要加锁）
case_status_lock = threading.Lock()
def change_case_status(case_status: list, new_status):
    with case_status_lock:
        if len(case_status) == 0:
            case_status.append(new_status)
            return True
    
        return False

def case_finish(case_status:list):
    with case_status_lock:
        return len(case_status) > 0

# 更新项目代码
# 需要加锁，避免在更新代码的过程进行模块导入
def init_project(project_id, project_file_lock):
    with project_file_lock:
        ret = os.popen(f"git submodule update --remote projects/{project_id}").read()
        print(ret)
        return ret

# 自动化服务器
server_url = "https://uauto-api.testplus.cn"


# 等待同步完成
# 该函数会被传入到自动化脚本里进行运行
def wait_sync_factory(task_parameters,task_running_id, case_id, device_id, bot):

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
                bot.send_text(f"{device_id} 同步出错: {ret['msg']}")
                raise Exception(f"同步出错: {ret['msg']}")
            else:
                data = ret["data"]

                # 本次同步完成
                if data["status"] == "finish":
                    bot.send_text(f"{device_id} 同步完成 {data}")
                    return {
                        "index": data["sync"],
                        "count": data["machine_count"],
                        "args": data["sync_args"]
                    }
                else:
                    print(f"等待同步: {data}")
            
            time.sleep(3)

    return wait_sync


def check_sync(task_running_id, task_parameters, case_id, device_id, udriver, case_status, bot):
    while True:
        # 案例完成，结束检查
        if case_finish(case_status):
            break
        if 'team' in task_parameters.keys(): 
            response = requests.get(f"{server_url}/task_run/sync_check", params={
            "case_id": case_id,
            "device_id": device_id
        })
        else:
            response = requests.get(f"{server_url}/task_run/sync_check", params={
            "task_running_id": task_running_id,
            "case_id": case_id,
            "device_id": device_id
        })
        
        
        ret = json.loads(response.content)

        # 检查出现异常
        if ret["code"] == 200:
            # 同步出现异常
            if ret["data"]["status"] == "error":
                bot.send_text(f"{device_id} 检测出其他设备运行中同步失效 {ret['data']}")
                # 通过断开 udriver 来使自动化脚本报错
                udriver.stop()
                break

        
        time.sleep(5)

def check_timeout(case_status: list, maxTime, udriver, bot, device_s):
    
    startTime = 0
    while True:
        # 案例完成，结束检查
        if case_finish(case_status):
            break

        if startTime >= maxTime:
            print(f"{device_s} 案例超时")
            bot.send_text(f"{device_s} 案例超时")
            if change_case_status(case_status, CaseStatus.TIMEOUT):
                udriver.stop()
            break

        time.sleep(5)
        startTime += 5
        
def sync_fail(task_parameters,task_running_id, case_id, device_id):
    
    
    if 'team' in task_parameters.keys(): 
        response = requests.post(f"{server_url}/task_run/sync_fail", params={
        "case_id": case_id,
        "device_id": device_id
    })
    else:
        response = requests.post(f"{server_url}/task_run/sync_fail", params={
        "task_running_id": task_running_id,
        "case_id": case_id,
        "device_id": device_id
    })
    ret = json.loads(response.content)

    return ret


class thread_with_exception(threading.Thread): 
    def __init__(self, target, args):
        threading.Thread.__init__(self)
        self.target = target
        self.args = args
        
    def run(self): 
        # target function of the thread class 
        try: # 用try/finally 的方式处理exception，从而kill thread
            self.target(*self.args)
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

def start_task(device_s, device_ip, platform, prot, package_url,package_info, device_id, device_quality, task_running_id, task_parameters, project_id, feishu_token, project_file_lock, task_data):
    try:
        multiprocessing.current_process().pid
        log_lock = multiprocessing.Lock()
        fzhu = FakeOut(log_lock)
        sys.stdout = fzhu
        sys.stderr=fzhu
        fzhu.add_output(threading.current_thread().ident,open(f'log_file/task{task_running_id}_{device_s}.txt',"a+"))

        bot = pyfeishu.FeiShutalkChatbot(feishu_token)

        
        bot.send_text(f"{device_s} 任务 {task_running_id} 开始")

        # 更新项目代码
        update_ret = init_project(project_id, project_file_lock)
        print(f"代码更新 {project_id}: {update_ret}")
        # bot.send_text(f"代码更新 {project_id}: {update_ret}")

        print(threading.currentThread())

        #初始化设备操作
        Android_IOS = AdIo(device_s, platform, package_url,package_info,project_file_lock,prot)

        # 唤醒设备
        Android_IOS.unlock()
        # 判断是否安装这个包
        if Android_IOS.FindIPA_APK():
            # 获取手机里面的包信息
            existinfo=Android_IOS.get_info()
            # 判断两个包体版本是否相同
            if existinfo['versionName']!=Android_IOS.versionName:
                Android_IOS.UnInstall_IOS_IPA ()

        # 安装包体 并上传包信息到数据库
        if not Android_IOS.FindIPA_APK():
            Android_IOS.Install_IOS_IPA ()
            # 上传包体信息
            response = requests.post(f"{server_url}/task_run/upload_package_info", params={
                "task_running_id":task_running_id ,
                "package_info": json.dumps(Android_IOS.package_info)
                })
            print(response.content.decode("utf-8"))
        bot.send_text(f"{device_s} 安装的包版本: {Android_IOS.versionName}")
        # 启动游戏
        # if not Android_IOS.RunIPA():
        #     bot.send_text(f"{device_s}任务出错:  游戏启动失败")
        #     traceback.print_exc()

        # 获取案例信息
        response = requests.get(f"{server_url}/task_run/get_next_case", params={
            "task_running_id": task_running_id,
            "device_id": device_id
        })

        print(response.content.decode("utf-8"))

        case = json.loads(response.content)["data"]
        print(case)


        if task_parameters != None:
            task_parameters = json.loads(task_parameters)

        while case != None:

            print(f"开始执行{case['name']}")
            bot.send_text(f"{device_s} 开始执行 {case['name']}")
            Android_IOS.wda_u2_Detect()
            Android_IOS.unlock()

            time.sleep(5)

            # TODO: 需要添加错误处理
            # TODO: 多线程log区分
            # TODO: 多人同步，目前接口还没有实现
            # TODO: 将任务参数和案例参数进行合并（如果参数有同名key，任务参数覆盖案例参数），得出最终运行时需要的参数，流程中根据各个参数进行控制

            # 处理参数
            parameters = {}
            case_parameters = case["parameters"]
            if case_parameters != None:
                case_parameters = json.loads(case_parameters)

                for key in case_parameters.keys():
                    parameters[key] = case_parameters[key]
                
                # # 账号测试（非正式使用）
                # if "test_parmaters" in case_parameters.keys():
                #     for test_parmater in case_parameters["test_parmaters"]:
                #         if test_parmater["device_id"] == device_id:
                #             parameters["user"] = test_parmater["user"]
                #             parameters["server"] = test_parmater["server"]
            # 账号信息
            parameters["account"] = case["account"]
            # 画质信息
            parameters["quality"] = device_quality
            # WDA_U2 手机操控
            parameters["WDA_U2"] = wu2( Android_IOS.WDA_U2)
            # 包名
            parameters["package"] = Android_IOS.package
            if task_parameters != None:
                
                for key in task_parameters.keys():
                    # 如果在任务参数中的 devices 字段中设置了设备（ID）特殊参数，将会使用里面指定的特殊参数覆盖掉外层的全局参数
                    if key == "devices":
                        devices = task_parameters[key]
                        if str(device_id) in devices.keys():
                            for replace_key in devices[str(device_id)].keys():
                                parameters[replace_key] = devices[str(device_id)][replace_key]
                        continue
                    parameters[key] = task_parameters[key]


            if case["execute_machine_count"] > 1:
                parameters["wait_sync"] = wait_sync_factory(task_parameters,task_running_id, case["id"], device_id, bot)


            print(parameters)
            
            execute_time_out = 3600 if case["execute_time_out"] == None else case["execute_time_out"]
            
            # 判断此次运行是否需要提前清理游戏数据
            if "clear_data" in parameters.keys() and parameters["clear_data"] == 1:
                Android_IOS.ClearData()

            # 动态导入模块
            # TODO: 在实际导入模块前，需要更新对应的模块代码
            case_file_path = case["file_path"]
            if case_file_path.endswith(".py"):
                case_file_path = case_file_path[:-3]
            case_file_path = case_file_path.replace("/", ".")

            module_load = [f"projects.{case['project_id']}.u3driver", f"projects.{case['project_id']}.{case_file_path}"]


            modules = get_module(module_load, project_id, project_file_lock)

            # TODO: 有些案例的准备需要运行其他案例主体，需要在参数中获取到，然后把这部分案例加载进来，并根据参数设置运行

            u3driver = modules[0]
            case_run = modules[1]

            
            # 案例前置操作需要导入的额外模块
            before_runs = []
            before_run_module_load = []

            if case_parameters != None and "before_run" in case_parameters.keys():
                for before_run_case in case_parameters["before_run"]:
                    file_path = before_run_case["file_path"]
                    if file_path.endswith(".py"):
                        file_path = file_path[:-3]
                    file_path = file_path.replace("/", ".")
                    before_run_module_load.append(f"projects.{case['project_id']}.{file_path}")


            before_run_modules = get_module(before_run_module_load, project_id, project_file_lock)
            
            for i, before_run_module in enumerate(before_run_modules):
                item = {
                    "module": before_run_module,
                    "func": case_parameters["before_run"][i]["func"]
                }
                before_runs.append(item)

            case_success = False
            report_data = {}

            # 用于同步的案例状态
            case_status = []

            # 开始案例，在设定的重试次数下重复运行
            for i in range(case["execute_times"]):

                # 启动游戏
                bSucceed=Android_IOS.ConnectDevice()
                if bSucceed:

                    perfeye = None
                    gpuTemp = None
                    perfetto = None

                    try:
                        
                        # print(dir(case_run))

                        # 等待进入游戏
                        time.sleep(100)

                        if "ios" in platform and project_id=="jx1pocket":
                            Android_IOS.clock(0.58,0.75)
                        # 初始化 u3driver
                        udriver = u3driver.AltrunUnityDriver(device_s, "", device_ip, 13000, 10)

                        # 使用列表来多线程同步案例状态
                        case_status = []
                        # 多人案例
                        if case["execute_machine_count"] > 1:
                            # 开始监听同步问题
                            _thread.start_new_thread(check_sync, (task_running_id,task_parameters, case["id"], device_id, udriver, case_status, bot))


                        # 案例前准备
                        for before_run in before_runs:
                            try:
                                # bot.send_text(f"{device_s} 案例前操作开始 {before_run['module'].__name__} {before_run['func']}")
                                print(f"{device_s} 案例前操作开始 {before_run['module'].__name__} {before_run['func']}")
                                before_run["module"].__getattribute__(before_run["func"])(udriver, parameters)
                                
                            except Exception as e:
                                bot.send_text(f"{device_s} 案例前操作失败 {before_run['module'].__name__} {before_run['func']}")
                                bot.send_text(traceback.format_exc())
                                raise e
                            # before_run.AutoRun(udriver)
                        
                        # 根据任务参数进行采集

                        start=time.time()

                        # 开始采集
                        if "performance" in parameters.keys():
                            collect_type = parameters["performance"]

                            # perfeye 采集
                            if "perfeye" in collect_type:

                                # 检查是否有 appKey
                                if not "appKey" in parameters.keys():
                                    raise Exception("缺少参数 appKey，无法进行 perfeye 采集")
                                    # bot.send_text("缺少参数 appKey，无法进行 perfeye 采集")
                                task_data["appKey"] = parameters["appKey"]
                                if "android" in platform:
                                    try:
                                        Android_IOS.WDA_U2.watcher('allow_tp').when('允许').click()#自动点击系统弹窗,游戏可能会弹出什么提示
                                    except Exception as e:
                                        pass
                                perfeye = TPlus.Perfeye()
                                perfeye.PreInit(device_s,device_s) # TODO 完善端口分配功能
                                perfeye.Start(device_s, Android_IOS.package) # TODO 动态包名

                                # perfeye 使用 subprocess，当多进程被杀掉，无法自动关闭 perfeye 的子进程，将 perfeye 返回给父进程进行关闭
                                task_data["perfeye"] = perfeye.GetPid()

                                # bot.send_text(f"{device_s} 开始采集 perfeye")
                                print(f"{device_s} 开始采集 perfeye")
                                times = 25
                                # if self.device_s=="e755fd8d":
                                #     times=30
                                if "android" in platform:
                                    while True:
                                        try:
                                            Android_IOS.WDA_U2.watcher.run()
                                        except Exception as e:
                                            pass
                                        times -= 1
                                        if times == 0:
                                            print("有弹窗,等待了---",time.time()-start)
                                            break
                                        else:
                                            time.sleep(0.5)
                                    
                            # gpu 温度采集
                            if "gpu_temp" in collect_type:
                                gpuTemp = gpu_temp.GPUTemp()
                                gpuTemp.start_capture(device_ip, f"{case['name']}({device_s})")
                                bot.send_text(f"{device_s} 开始采集 gpu_temp")

                            # gpu 使用详情采集
                            if "perfetto" in collect_type:
                                perfetto = record_android_trace.Perfetto(device_s, f"{case['name']}({device_s})")
                                perfetto.start()
                                bot.send_text(f"{device_s} 开始采集 perfetto")

                            #深度采集
                            if "Profile" in collect_type:
                                parameter={
                                    'u3driver':udriver,
                                    'device':device_s,
                                    "quality":device_quality,
                                    "casename":case['name'],
                                    "platform":platform,
                                    "package":Android_IOS.package,
                                    "appkey":Android_IOS.appkey,
                                    "project_id":project_id,
                                    "feishu":bot
                                }
                                importlib.invalidate_caches()
                                module_path = os.getcwd()
                                module_path = os.path.join(module_path, "UAutoProfilerTool")

                                print(module_path)
                                sys.path.append(module_path)
                                module = importlib.import_module('Profile_test')

                                sys.path.remove(module_path)
                                Prof=module.Profile(parameter)
                                Prof.RunProfile()
                                bot.send_text(f"{device_s} 开始深度采集 Profile")
                            
                            # 其他采集
                        
                        _thread.start_new_thread(check_timeout, (case_status, execute_time_out, udriver, bot, device_s))

                        # 案例主体运行
                        # bot.send_text(f"{device_s} 运行案例主体")
                        print(f"{device_s} 运行案例主体")
                        case_run.AutoRun(udriver, parameters)

                        # report_data = {}
                        # 停止采集
                        try:
                            if "performance" in parameters.keys():
                                collect_type = parameters["performance"]

                                # perfeye 采集
                                if "perfeye" in collect_type and perfeye != None:
                                    # TODO 参数可配置
                                    ret,data = perfeye.Stop(device_s, f'{case["name"]}(' + device_s + ')', scenes=case["name"], picture_quality=device_quality, do_upload=True, appKey=parameters["appKey"])
                                    # bot.send_text(f"{device_s} perfeye 采集结束: {ret}, {data}")
                                    print(f"{device_s} perfeye 采集结束: {ret}, {data}")
                                    
                                    # 获取报告结果
                                    if ret:
                                        report_data["perfeye"] = data["result"]["report_id"]
                                
                                # gpu_temp
                                if "gpu_temp" in collect_type and gpuTemp != None:
                                    ret = gpuTemp.stop_capture()
                                    # bot.send_text(f"{device_s} gpu_temp 采集结束 {ret}")
                                    print(f"{device_s} gpu_temp 采集结束 {ret}")
                                    
                                    if ret != None:
                                        report_data["gpu_temp"] = ret["file_path"]
                                
                                # perfetto
                                if "perfetto" in collect_type and perfetto != None:
                                    ret = perfetto.stop()
                                    bot.send_text(f"{device_s} perfetto 采集结束: {ret}")
                                    print(f"{device_s} perfetto 采集结束: {ret}")

                                    if ret != None:
                                        report_data["perfetto"] = ret["file_path"]

                                #深度采集
                                if "Profile" in collect_type:
                                    ret=Prof.StopProfile(False,True,True)
                                    bot.send_text(f"{device_s} Profile 深度采集结束: {ret}")
                                    report_data["Profile"] = ret


                        except Exception as e:
                            bot.send_text(f"{device_s} perfeye 结束失败")
                            bot.send_text(traceback.format_exc())

                        udriver.stop()

                        # case_status.append(CaseStatus.SUCCESS)
                        change_case_status(case_status, CaseStatus.SUCCESS)
                        # 案例成功，退出重试
                        break
                        

                    except Exception as e:
                        bot.send_text(f"{device_s} {case['name']} 第 {i+1} 次失败")
                        bot.send_text(traceback.format_exc())
                        change_case_status(case_status, CaseStatus.FAIL)
                        
                        # 结束采集
                        try:
                            if "performance" in parameters.keys():
                                collect_type = parameters["performance"]

                                # perfeye 采集
                                if "perfeye" in collect_type and perfeye != None:
                                    # TODO 参数可配置
                                    ret,data = perfeye.Stop(device_s, f'{case["name"]}(' + device_s + ')', scenes=case["name"], picture_quality=device_quality, do_upload=False, appKey=parameters["appKey"])

                                    # perfeye 结束采集后不用给主进程进行清理
                                    task_data["perfeye"] = -1
                                    if not ret:
                                        bot.send_text(f"{device_s} perfeye 采集结束:{ret}, {data}")
                                    print(f"{device_s} perfeye 采集结束: {ret}, {data}")

                                # gpu_temp
                                if "gpu_temp" in collect_type and gpuTemp != None:
                                    ret = gpuTemp.stop_capture()
                                    # bot.send_text(f"{device_s} gpu_temp 采集结束 {ret}")
                                    print(f"{device_s} gpu_temp 采集结束 {ret}")
                                
                                # perfetto
                                if "perfetto" in collect_type and perfetto != None:
                                    ret = perfetto.stop()
                                    # bot.send_text(f"{device_s} perfetto 采集结束: {ret}")
                                    print(f"{device_s} perfetto 采集结束: {ret}")
                                
                                #深度采集
                                if "Profile" in collect_type:
                                    Prof.StopProfile(False,False,False)

                        except Exception as e:
                            bot.send_text(f"{device_s} 设备断连掉线")
                            bot.send_text(traceback.format_exc())

                        # 多人案例同步失败
                        if case["execute_machine_count"] > 1:
                            sync_fail(task_parameters,task_running_id, case["id"], device_id)
                        try:
                            udriver.stop()
                        except Exception as e:
                            pass
                else:
                    bot.send_text(f"{device_s} 游戏启动失败或设备掉线")
                    Android_IOS.unlock()
                    continue

            #案例执行完成，锁屏
            Android_IOS.lock()

            # 案例运行完成，上传结果
            if CaseStatus.SUCCESS in case_status:
                
                response = requests.post(f"{server_url}/task_run/case_success", params={
                    "task_running_id": task_running_id,
                    "device_id": device_id,
                    "case_id": case["id"],
                    "report_data": str(report_data)
                })
                
                print(response.content.decode("utf-8"))
                
                bot.send_text(f"案例成功{case['name']}{device_s}")
            else:
                if CaseStatus.TIMEOUT in case_status:
                    response = requests.post(f"{server_url}/task_run/case_timeout", params={
                        "task_running_id": task_running_id,
                        "device_id": device_id,
                        "case_id": case["id"]
                    })
                
                    print(response.content.decode("utf-8"))
                elif CaseStatus.FAIL in case_status:
                    response = requests.post(f"{server_url}/task_run/case_fail", params={
                        "task_running_id": task_running_id,
                        "device_id": device_id,
                        "case_id": case["id"]
                    })
                
                    print(response.content.decode("utf-8"))
                # bot.send_text(f"{device_s} {case['name']} 案例失败，不再重新执行")
                print(f"{device_s} {case['name']} 案例失败，不再重新执行")


        
            # 获取下一个案例信息
            response = requests.get(f"{server_url}/task_run/get_next_case", params={
                "task_running_id": task_running_id,
                "device_id": device_id
            })
            print(response.content.decode("utf-8"))

            case = json.loads(response.content)["data"]

            if case != None:
                # 案例间休息
                time.sleep(120)
            
        bot.send_text(f"{device_s} 任务结束")
        print("任务结束")

    except Exception as e:
        bot.send_text(f"{device_s} 任务出错")
        bot.send_text(traceback.format_exc())
        Android_IOS.lock()
        # TODO: 添加将设备改为空闲
        response = requests.post(f"{server_url}/device/free", params={
            "device_id": device_id
        })
        print(response.content.decode("utf-8"))


task_cancel_lock = threading.Lock()

# 任务中止清理
def task_cancel(device_id, device_s, task_data, bot):

    time.sleep(10)
    with task_cancel_lock:

        bot.send_text(f"任务中止 {task_running_id}")
        
        response = requests.post(f"{server_url}/device/free", params={
            "device_id": device_id
        })
        print(f'释放设备: {response.content.decode("utf-8")}')

        if "perfeye" in task_data.keys() and task_data["perfeye"] != -1:
            print(os.popen(f'ps -ef |grep miniperf').read())
            # 使用 kill 命令杀掉 perfeye 的进程
            os.popen(f'kill -9 {task_data["perfeye"]}').read()
            print(os.popen(f'ps -ef |grep miniperf').read())

# 
def task_cancel_test(running_process, device_id, device_s, task_data, bot):
    time.sleep(10)
    
    if running_process.is_alive():
        running_process.terminate()
        running_process.join()

        task_cancel(device_id,device_s,task_data,bot)
        

data = '{"performance":["perfeye"]}'

import uuid

if __name__ == "__main__":

    bot = pyfeishu.FeiShutalkChatbot("https://open.feishu.cn/open-apis/bot/v2/hook/f11cf561-e314-4fa6-adb4-883af7786599")

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
        response = requests.post(f"{server_url}/device_controller/heartbeat", params={
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
            response = requests.post(f"{server_url}/task_run/running_task_is_cancel", params={
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
                        _thread.start_new_thread(task_cancel_test, (running_process, device_id, device_s, task_data, new_bot))

                        new_bot.send_text(f"开始任务清理 {device_id} {task_running_id}")
                        print(f"开始任务清理 {device_id} {task_running_id}")

                        running_task_list.remove(running_task_item)

            if len(running_task_list) == 0:
                # 移除已完成（取消）的任务
                running_task.pop(task_running_id)




        # 获取任务
        response = requests.get(f"{server_url}/task_run/get_contorller_task")
        print(response.content.decode("utf-8"))

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
                    
                    process = multiprocessing.Process(target=start_task, args=(
                        device["device_identifier"], device["ip"], device["os"], device["port"], package_url, package_info, device["id"], device["quality"], task_running_id, task_parameters, project_id, feishu_token, project_file_lock, task_data))
                    process.start() 
                    

                    # # 记录运行子进程
                    running_task_item = {
                        "process": process,
                        "task_data": task_data,
                        "device_id": device["id"],
                        "device_s": device["device_identifier"],
                        "feishu_token": feishu_token
                        # "id": new_thread.get_id()
                    }

                    running_task_list.append(running_task_item)
                
                running_task[str(ret["data"][0]["task_running_id"])] = running_task_list
        else:
            bot.send_text(ret["msg"])
        nowtime=str(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()))
        print(f"{nowtime}: 活动线程: {threading.enumerate()}")
        print(f"running_task: {running_task}")

        time.sleep(60)

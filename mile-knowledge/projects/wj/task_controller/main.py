'''
Author: 涂阳墨 tuyangmo@kingsoft.com
Date: 2023-07-11 09:33:53
LastEditors: 涂阳墨 tuyangmo@kingsoft.com
LastEditTime: 2024-01-12 10:12:16
Description: 重构后的程序入口

Copyright (c) 2023 by Seasun, All Rights Reserved. 
'''
import asyncio
import importlib
import os
from queue import Empty
import signal
import time
import traceback
import requests
import aioprocessing
import auto_rebot
import multiprocessing
import psutil
import platform

from utils.event_defined import *
from utils.constants import *
from utils.async_tools import *
from heart_sync_new import HeartSync

from worker_process.worker_process_base import WorkerProcessBase
from extensions import logger
from utils.tools import os_popen,subprocess_Popen
import task_run_process

PERFEYE_PORT_INIT = 20000  # perfeye 初始端口号
PHONE_DEFAULT_PORT = 31416
UDRIVER_PORT = 13001


class Controller(object):
    '''
    主控制器, 创建任务进程, 处理所有进程的事件请求
    同时, 主控制器存储并控制所有公共资源, 如果其他进程需要修改公共资源, 发送事件进行修改, 不要直接用multiprocessing提供的共享变量!
    可以使用multiprocessing共享变量的情况:
    1. 只有一个进程会写入, 其他进程都是只读, 在任何时候都无需加锁的情况
    2. 你确认你的需求无法通过事件来实现, 不得不使用共享变量
    '''
    def __init__(self):
        self._event_queue = aioprocessing.AioQueue()    # 事件队列

        self._event_queue_write_lock = aioprocessing.AioLock() # 事件队列写入锁

        self._event_reponse_queue_map = {}  # 事件返回值队列映射{pid: Aioqueue()}
        self._process_uuid = 0  # 手动管理的进程id
        self._running_tasks = {} # key: taskid, value: taskdata列表, 同一个task会在多台设备上执行.
        self._terminate = False
        self._pid_map = {}
        # 进程间共享的资源, 通过get_share_ 和set_share_ 方法获取及修改
        self._share_dict = {
            "phone_network": {},
            "phone_port_map": {},
            "phone_token": {},
            "udriver_local_devices": {},
        }
        self._share_list = {
            "connect_devices_list": [],
        }
        self._share_value = {
            "perfeye_share_port": PERFEYE_PORT_INIT,
            "phone_default_port": PHONE_DEFAULT_PORT,
            "udriver_port": UDRIVER_PORT,
            "timeoutusd": None,
        }

        self._device_running = {}
        self._aio_process_mgr=aioprocessing.AioManager()
        self._project_lock = self._aio_process_mgr.Lock()
        self._ue4_lock = self._aio_process_mgr.Lock()
        self._download_lock = self._aio_process_mgr.Lock()
        #self._project_lock = aioprocessing.AioLock()
        #self._ue4_lock = aioprocessing.AioLock()
        #self._download_lock = aioprocessing.AioLock()

       # self._task_start_lock = asyncio.Lock() # 任务开始锁, 同时只会开始一个任务
        self._task_start_lock = asyncio.Lock()

    
    '''核心函数, 勿轻易修改'''
    def signal_handler(self, signum, frame):
        logger.info('Received signal %d' % signum)
        self._terminate = True
        for process in multiprocessing.active_children():
            logger.info('Terminating process %r' % process)
            process.terminate()
        logger.info("All Process terminate, exit!")
        exit(0)

    def new_process_uuid(self):
        '''新建并获取进程uuid'''
        self._process_uuid += 1
        return self._process_uuid
    
    def remove_running_task(self, task_id, process_uuid):
        if task_id in self._running_tasks:
            self._running_tasks[task_id].pop(process_uuid, None)
        self._event_reponse_queue_map.pop(process_uuid, None)
        if len(self._running_tasks[task_id]) == 0:
            self._running_tasks.pop(task_id, None)
        if len(self._running_tasks) == 0:
            # 回收所有端口
            self._share_value['perfeye_share_port'] = PERFEYE_PORT_INIT
            self._share_value['phone_default_port'] = PHONE_DEFAULT_PORT
            self._share_value['udriver_port'] = UDRIVER_PORT
    
    def new_worker_process(self, process_class, *args, **kwargs):
        '''新建一个进程'''

        process:WorkerProcessBase = process_class(self.new_process_uuid(), self._event_queue, self._event_queue_write_lock, *args, **kwargs)
        #process: WorkerProcessBase = process_class(self.new_process_uuid(), self._event_queue, *args, **kwargs)

        self._event_reponse_queue_map[process.get_uuid()] = process.get_response_queue()
        return process

    def run(self):
        '''程序入口'''
        signal.signal(signal.SIGINT, self.signal_handler)
        # 初始化共享变量
        self._aio_process_mgr = aioprocessing.AioManager()
        _ = requests.get(f"{SERVER_URL}/build/controller/reset/device/by/controller")
        self.record_pid("主进程", os.getpid())
        self._device_sync_process = self.new_worker_process(HeartSync)
        self._device_sync_process.start()
        self.record_pid("心跳进程", self._device_sync_process.pid)
        asyncio.get_event_loop().run_until_complete(self.start_event_loop())

    def record_pid(self, name, pid):
        '''记录进程pid'''
        p = psutil.Process(pid)
        self._pid_map[name] = p

    def show_current_process(self):
        '''显示当前进程信息'''
        need_remove = []
        need_clear_zombie = False
        logger.info("-------当前进程信息:")
        try:
            for name, p in self._pid_map.items():
                if p.is_running():
                    logger.info(f"进程[{name}], pid: {p.pid}, cpu占用: {p.cpu_percent()}%, 内存占用: {p.memory_percent()}%")
                    # is_running有可能在进程退出后仍然为True的情况
                    if p.status() == psutil.STATUS_ZOMBIE:
                        logger.info(f"进程[{name}]成为僵尸进程.")
                        need_clear_zombie = True
                else:
                    logger.info(f"进程[{name}]已退出.")
                    need_remove.append(name)
            for name in need_remove:
                self._pid_map.pop(name, None)
            if need_clear_zombie:
                # 调用一次该函数以清理僵尸进程
                multiprocessing.active_children()
        except Exception as e:
            logger.error(f"输出进程信息失败: {e}")
            logger.error(traceback.format_exc())

    async def show_current_process_loop(self):
        '''显示当前进程信息循环'''
        logger.info("进程监控循环启动.")
        while True:
            self.show_current_process()
            await asyncio.sleep(60)

    async def start_event_loop(self):
        '''启动事件循环'''
        asyncio.get_event_loop().create_task(self.show_current_process_loop())
        logger.info("主事件循环启动.")
        last_hearbeat_time = time.time()
        while True:
            if self._terminate:
                logger.info("主事件循环退出.")
                break
            if time.time() - last_hearbeat_time > 60:
                logger.info(f"主事件循环间隔超过60s! {time.time() - last_hearbeat_time}")
            last_hearbeat_time = time.time()
            try:
                event:Event = await self._event_queue.coro_get(timeout=10)
                logger.info(f"获取事件{event._func_name}, {event._event_id}")
                asyncio.get_event_loop().create_task(self.handle_event(event))
            except Empty:
                logger.info(f"self._event_queue: Empty")
                pass
            except Exception as e:
                logger.error(f"事件处理异常: {str(e)}")
                logger.error(traceback.format_exc())
            
    async def handle_event(self, event:Event):
        '''处理事件'''
        ret = EventResponse(event._pid, event._event_id, event._func_name)
        handle_func = getattr(self, event._func_name, None)
        start_time = time.time()
        if handle_func:
            try:
                ret._result = await handle_func(*event._args, **event._kwargs)
            except Exception as e:
                ret._code = 1
                ret._error = str(e)
                logger.error(f"handle event error: {str(e)}, event name: {event._func_name}")
                logger.error(traceback.format_exc())
        else:
            ret._code = 1
            ret._error = 'no handle func'
            logger.error("no handle func: %s", event._func_name)
        logger.info(f"event._is_call:{event._is_call},event._pid:{event._pid},event._event_id:{event._event_id}")
        if event._is_call and event._pid in self._event_reponse_queue_map:
            logger.info(f"主事件循环返回结果: {ret._result}")
            await self._event_reponse_queue_map[event._pid].coro_put(ret)
            logger.info(f"主事件循环结果入队:{event._event_id}")
        use_time = time.time() - start_time
        if use_time > 60:
            logger.error(f"事件{event._func_name}, {event._event_id}耗时 {use_time} 秒!")

    '''
    以下为事件处理函数, 需遵循的原则
    1. 必须是协程函数
    2. 不能有任何阻塞主线程的操作, 如果有, 改成异步, 如sleep改为asynio.sleep
    3. 如果你的操作所调用的阻塞接口未提供异步方法, 那么使用await asyncio.to_thread 多线程的方法执行你的操作
    '''

    # 共享变量操作事件
    async def get_share_dict(self, dict_name):
        if dict_name in self._share_dict:
            return self._share_dict[dict_name]
        else:
            raise RuntimeError(f"共享变量{dict_name}不存在!")
    
    async def set_share_dict(self, dict_name, key, value = None, delete = False):
        if dict_name in self._share_dict:
            if delete:
                self._share_dict[dict_name].pop(key, None)
            else:
                self._share_dict[dict_name][key] = value
        else:
            raise RuntimeError(f"共享变量{dict_name}不存在!")
        
    async def get_share_list(self, list_name):
        if list_name in self._share_list:
            return self._share_list[list_name]
        else:
            raise RuntimeError(f"共享变量{list_name}不存在!")

    async def set_share_list(self, list_name, list_value):
        if list_name in self._share_list:
            self._share_list[list_name] = list_value
        else:
            raise RuntimeError(f"共享变量{list_name}不存在!")
        
    async def get_share_value(self, value_name):
        if value_name in self._share_value:
            return self._share_value[value_name]
        else:
            raise RuntimeError(f"共享变量{value_name}不存在!")
    
    async def set_share_value(self, value_name, value):
        if value_name in self._share_value:
            self._share_value[value_name] = value
        else:
            raise RuntimeError(f"共享变量{value_name}不存在!")
        
    async def get_running_tasks(self):
        # 返回正在运行的任务列表, 仅返回pid
        ret = {}
        for task_id, item in list(self._running_tasks.items()):
            ret[task_id] = {}
            for uuid, task_data in list(item.items()):
                ret[task_id][uuid] = {
                    "process_pid": task_data["process_pid"],
                    "device_id": task_data["device_id"]
                }
        return ret
    
    async def get_phone_network(self):
        # 返回已连接网络信息
        ret = {}
        for device_s, p in list(self._share_dict["phone_network"].items()):
            ret[device_s] = p.pid
        return ret
    
    async def kill_phone_network(self, device_s):
        def kill_pid_and_wait(p):
            p.terminate()
            p.wait()
        p = self._share_dict["phone_network"].get(device_s, None)
        if p:
            await to_thread(kill_pid_and_wait, p)
            self._share_dict["phone_network"].pop(device_s, None)
    
    async def ping(self):
        return "pong"
        
    # 有并行风险, 做成原子操作
    async def new_perfeye_port(self):
        perfeye_port = self._share_value["perfeye_share_port"]
        self._share_value["perfeye_share_port"] += 1
        return perfeye_port
    
    async def check_task_process_alive(self, task_id, uuid):
        '''检查任务进程是否还活着'''
        if task_id not in self._running_tasks:
            return False
        task_running_dict:dict = self._running_tasks[task_id]
        if uuid not in task_running_dict:
            return False
        return True
    
    async def task_cancel(self, task_id, cancel_data):
        '''任务取消, 杀死进程, 从队列中移除, 执行清理, 释放设备'''
        logger.info(f"取消任务{task_id}, {cancel_data}")
        if not task_id in self._running_tasks:
            return False
        cancel_task_data = []
        cancel_task_uuid = []
        # 根据cancel_data里的设备id查找需要取消的具体进程
        for uuid, task_running_data in self._running_tasks[task_id].items():
            if task_running_data['device_id'] in cancel_data:
                cancel_task_data.append(task_running_data)
                cancel_task_uuid.append(uuid)
        for uuid in cancel_task_uuid:
            # 先从列表中删除
            self.remove_running_task(task_id, uuid)
        for one_cancel_task_data in cancel_task_data:
            await to_thread(self.task_cancel_runtime_data_clear,one_cancel_task_data)
        return True

    async def task_process_exitd(self, task_id, uuid):
        '''任务进程已退出, 目前就是直接从running list中移除'''
        if task_id in self._running_tasks:
            self.remove_running_task(task_id, uuid)

    async def task_start(self, task_data):
        # 加锁确保在同一时间只会启动一个任务
       async with self._task_start_lock:
        #if True:
            # 检查设备是否被占用
            device_id = task_data["device"]["id"]
            is_used, task_running_id, task_uuid, process_pid = self.check_device_in_used(device_id)
            if is_used:
                logger.info(f"设备{device_id}已被任务{task_running_id}, {task_uuid}占用, 占用进程 {process_pid}, 跳过!")
                return

            #动态更新用例任务处理模块 每个层级导入的模块都需要重置
            ''''''
            ret = subprocess_Popen(f"git reset --hard HEAD")
            #print(ret)
            logger.info(f"git reset --hard HEAD result: {ret} ")
            ret = subprocess_Popen(f"git pull origin branch-jx3")
            #print(ret)
            logger.info(f"git pull origin branch-jx3 result: {ret} ")

            #from task_run_process import TaskRunProcess
            module=importlib.reload(task_run_process)
            task_process = self.new_worker_process(module.TaskRunProcess, task_data)
            # 初始化参数, 由于有一堆阻塞操作, 因此用线程执行
            await to_thread(task_process.init_param, self._project_lock, self._ue4_lock, self._download_lock,self)
            task_process.start()
            self.record_pid(f"任务进程{task_process.task_running_id}设备{task_process.device_id}", task_process.pid)
            task_version = 0
            if "version" in task_data:
                task_version = int(task_data["version"])
            else:
                logger.info(f"任务{task_process.task_running_id}没有版本号, 默认为0")
            running_task_item = {
                "process": task_process,
                "task_data": task_process.task_data,
                "device_id": task_process.device_id,
                "package_info": task_process.package_info,
                "device_s": task_data["device"]["device_identifier"],
                "feishu_token": task_process.feishu_token,
                "device_name": task_process.device_name,
                "process_pid": task_process.pid,
                "process_uuid": task_process.get_uuid(),
                "version": task_version
            }
            task_running_id = task_process.task_running_id
            if task_running_id not in self._running_tasks:
                self._running_tasks[task_running_id] = {}
            self._running_tasks[task_running_id][task_process.get_uuid()] = running_task_item
            logger.info(f"启动新任务进程: task_id: {task_process.task_running_id}, uuid: {task_process.get_uuid()}, pid: {task_process.pid}")
    
    def check_device_in_used(self, device_id):
        '''检查设备是否已被占用'''
        for task_running_id, item in self._running_tasks.items():
            for task_uuid, item2 in item.items():
                if item2["device_id"] == device_id:
                    return (True, task_running_id, task_uuid, item2["process_pid"])
        return (False, 0, 0, 0)

    async def task_process_report_finish(self, task_running_id, process_uuid, status):
        '''任务进程上报任务完成'''
        if task_running_id not in self._running_tasks:
            return False
        task_running_dict:dict = self._running_tasks[task_running_id]
        if process_uuid not in task_running_dict:
            return False
        task_data = task_running_dict[process_uuid]
        self.remove_running_task(task_running_id, process_uuid)
        response = requests.post(f"{SERVER_URL}/build/controller/build/end", json = {
            "buildId": task_running_id,
            "deviceId": task_data["device_id"],
            "version": task_data["version"],
            "status": status
        })
        logger.info(f"任务结束, 后端返回:{response.content.decode('utf-8')}")
        logger.info("任务结束!")
        return True
    
    '''杂项函数'''
    # 任务清理
    def task_cancel_runtime_data_clear(self, cancel_task_data):
        task_process: task_run_process.TaskRunProcess = cancel_task_data["process"]
        # feishu_bot = auto_rebot.FeiShutalkChatbot(task_process.feishu_token)
        # feishu_bot.send_text(f"任务已取消, 正在清理 {task_process.task_running_id}, {task_process.device_name}")
        logger.info(f"开始任务清理: {task_process.task_running_id}, {task_process.device_id}, {task_process.device_name}")
        build_id = task_process.task_running_id
        # 杀死进程前, 锁定该进程的通信管道
        task_process.lock_event_queue()
        self._event_reponse_queue_map.pop(task_process.get_uuid(), None)
        if task_process.is_alive():
            logger.info("开始任务清理: 1")
            time.sleep(60) #60s等待任务进程自己取消结束,超时强杀
            # 目前 任务进程的task_process.case_status=None 因为进程直接通信的问题
            logger.info("开始任务清理: 11")
            # if hasattr(task_process, 'case_status'):
            #     logger.info("开始任务清理: 2")
            #     logger.info(task_process.case_status)
            #     if task_process.case_status:
            #         logger.info("开始任务清理: 3")
            # if hasattr(task_process, 'case_status') and task_process.case_status:
            #     task_process.case_status.stop_case(" task_cancel_runtime_data_clear")
            task_process.terminate()
            task_process.join(300)  # 5分钟内无法软关闭的进程, 强制结束
        if task_process.is_alive():
            logger.info(f"任务{task_process.task_running_id}进程无法软关闭, 将强制结束")
            task_process.kill()
            task_process.join()
        logger.info(f"任务{task_process.task_running_id}进程已结束")

        response = requests.post(f"{SERVER_URL}/build/controller/build/end", json={
            "buildId": build_id,
            "deviceId": cancel_task_data["device_id"],
            "version": cancel_task_data["version"],
            "status": "CANCEL"
        })
        logger.info(f"任务取消, 后端返回:{response.content.decode('utf-8')}")
        # 服务端已经不再记录设备状态了, 因此该接口无需调用
        # response = requests.post(f"{SERVER_URL}/build/controller/device/free", json = {"deviceId": task_process.device_id, "device_identifier": task_process.device_s}, timeout=(10,15))
        logger.info(f"释放设备: {response.content.decode('utf-8')}")
        logger.info(f"清理完毕, 任务中止: {task_process.task_running_id}, {task_process.device_id}, {task_process.device_name}")
        # feishu_bot.send_text(f"清理完毕, 任务中止: {task_process.task_running_id}")

        # 清理子进程
        # 这一块改为在子进程中用atexit模块实现
        

if __name__ == "__main__":
    strOS = platform.system()
    if strOS == 'Windows':
        import ctypes
        if not ctypes.windll.shell32.IsUserAnAdmin():
            logger.error("请以管理员权限运行")
            raise Exception("请以管理员权限运行")
    c = Controller()
    c.run()
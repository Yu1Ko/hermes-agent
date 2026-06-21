'''
Author: 涂阳墨 tuyangmo@kingsoft.com
Date: 2023-07-11 19:23:27
LastEditors: 涂阳墨 tuyangmo@kingsoft.com
LastEditTime: 2024-01-12 10:15:10
Description: 同步进程, 负责设备状态同步, 重连设备, 检查设备连接情况, 获取任务状态

Copyright (c) 2023 by Seasun, All Rights Reserved. 
'''
import asyncio
import datetime
import importlib
import json
import os
import subprocess
import traceback
import psutil
import requests
bHttpx = False
try:
    import requests_async
except:
    import httpx
    requests_async = httpx.AsyncClient(verify=False)
    bHttpx = True
import time
import pyfeishu
from utils.async_tools import to_thread
from worker_process.worker_process_base import WorkerProcessBase
import ad_ios
from utils.constants import *
from utils.tools import  *
from extensions import logger
import socket
from BaseTool import *

class HeartSync(WorkerProcessBase):
    def __init__(self, process_uuid, event_queue,event_queue_lock):
        super().__init__(process_uuid, event_queue, event_queue_lock)
        #super().__init__(process_uuid, event_queue)
        self._connect_devices_list = []
        self._running_tasks = {}
        self._phone_network = {}
        self._heart_sync_interval = 50
        self._device_sync_interval = 60 #控制设备上传频率(截图)
        self._heart_sync_interval_error = 30


    def process_run(self):
        time.sleep(1) # 等待主进程启动事件循环
        #开启移动端服务
        asyncio.get_event_loop().run_until_complete(self.aio_run())


    async def aio_test_run(self):
        '''测试用'''
        while True:
            logger.info("heart sync!")
            # 字典修改测试
            self.send_event("set_share_dict", "running_tasks", "test_key", "test_value")
            d = self.call_event("get_share_dict", "running_tasks")
            logger.info(f"心跳进程------------------{d}")
            self.send_event("set_share_dict", "running_tasks", "test_key", delete=True)

            # 开始任务测试
            self.send_event("task_start", {"task_running_id": 111, "content": "hello world", "device": {"device_identifier" : "abc123"}})
            await asyncio.sleep(5)
            # 取消任务测试
            logger.info("取消任务!")
            self.call_event("task_cancel", 111, ["ascdddd"])

    async def device_check_loop(self):
        #self.device_service()
        while True:
            try:
                await self.device_sync()
            except Exception as e:
                logger.error(f"设备检查异常: {e}")
                logger.error(traceback.format_exc())
            await asyncio.sleep(self._device_sync_interval)

    #开启额外服务
    def device_service(self):
        #先结束端口占用
        '''
        port = 49151
        # 查找占用端口的PID
        cmd_find = f'netstat -ano | findstr :{port}'
        output = subprocess.getoutput(cmd_find)

        for line in output.strip().splitlines():
            parts = line.split()
            if len(parts) >= 5:
                pid = parts[-1]
                # 结束进程
                kill_cmd = f'taskkill /F /PID {pid}'
                print(f"正在结束 PID {pid}")
                subprocess.call(kill_cmd, shell=True)'''
        cmd='pymobiledevice3 remote tunneld'
        pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
        pass

    async def clean_up_loop(self):
        '''清理所有父进程为1的miniperf进程'''
        while True:
            try:
                for proc in psutil.process_iter():
                    if proc.ppid() == 1 and "miniperf.app" in proc.cmdline():
                        port_number = proc.cmdline()[3].split("=")[1]
                        logger.info(f"清理miniperf进程: {proc.pid}, 端口: {port_number}")
                        proc.kill()
            except Exception as e:
                logger.error(f"清理miniperf进程异常: {e}")
                logger.error(traceback.format_exc())
            await asyncio.sleep(300)


    async def aio_run(self):
        '''主循环, 兼容异步'''
        logger.info("启动同步进程")
        # 设备同步循环, 由于延迟和主循环不一样, 单独开一个循环
        asyncio.get_event_loop().create_task(self.device_check_loop())
        # 清理miniperf进程循环
        asyncio.get_event_loop().create_task(self.clean_up_loop())
        while True:
            try:
                self.send_event("set_share_value", "timeoutusd", datetime.datetime.now())
                await self.tasks_sync()
                #await self.phone_network_check()
                # FOR TEST
                # await self.aio_test_run()
                await asyncio.sleep(self._heart_sync_interval)
            except Exception as e:
                logger.error(f"主循环异常: {e}")
                logger.error(traceback.format_exc())
                await asyncio.sleep(self._heart_sync_interval_error)

    def get_ipv4_address(self):
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        try:
            # Connect to a public DNS server (no data is actually sent)
            s.connect(("8.8.8.8", 80))
            ipv4_address = s.getsockname()[0]
        finally:
            s.close()
        return ipv4_address

    async def device_sync(self):
        '''同步设备状态, 重连设备'''
        # 此函数可能会阻塞, 需要控制超时
        try:
            '''nClientType=int(ini_get('ClientType','mobile','clientconfig.ini'))
            if nClientType==1:
                self._connect_devices_list = await asyncio.wait_for(to_thread(ad_ios.GetConnecteddevices,), timeout=120)
                self._connect_devices_list.append(self.get_ipv4_address())
            else:
                self._connect_devices_list=[self.get_ipv4_address()]'''

            module = importlib.reload(ad_ios)
            self._connect_devices_list = await asyncio.wait_for(to_thread(module.GetConnecteddevices,False), timeout=120)

            #self._connect_devices_list.append('10.11.180.112')
            logger.info(f"online device list:{self._connect_devices_list}")
        except asyncio.TimeoutError:
            logger.error("ad_ios.GetConnecteddevices 超时!")
            return
        except Exception as e:
            logger.error(f"ad_ios.GetConnecteddevices 抛出异常{e}")
            return
        
        # logger.info(f"已连接设备列表: {self._connect_devices_list}")
        if bHttpx:
            response = await requests_async.post(f"{SERVER_URL}/build/controller/controller/heartbeat", json={
                "devices": list(self._connect_devices_list)
            }, timeout=(10, 15))
        else:
            response = await requests_async.post(f"{SERVER_URL}/build/controller/controller/heartbeat", json={
            "devices": list(self._connect_devices_list)
        },timeout=(10, 15), verify=False)

        logger.info(f"成功同步设备列表: {response.content.decode('utf-8')}")
        # 向主进程报告可用设备
        self.send_event("set_share_list", "connect_devices_list", self._connect_devices_list)
        if bHttpx:
            response = await requests_async.get(f"{SERVER_URL}/build/controller/offline/devices", timeout=(10, 15))
        else:
            response = await requests_async.get(f"{SERVER_URL}/build/controller/offline/devices",timeout=(10, 15), verify=False)

        # logger.info(f"未连接设备列表: {response.content.decode('utf-8')}")
        disconnected_devices = list(json.loads(response.content.decode("utf-8"))["data"])
        logger.info(disconnected_devices)
        # 重连设备
        for device in disconnected_devices:
            if device["os"] == "android" and ":" in device["unique_identifier"]:
                logger.info(f"正在连接设备{device['unique_identifier']}")
                try:
                    ret = await asyncio.wait_for(to_thread(ad_ios.ConnectADB, device["unique_identifier"]), timeout=60)
                    if not ret:
                        logger.info(f"连接设备{device['unique_identifier']}失败")
                except Exception as e:
                    logger.error(f"连接设备{device['unique_identifier']}函数出错: {e}")

    async def tasks_sync(self):
        '''同步任务状态, 获取新任务'''
        running_tasks:dict = self.call_event("get_running_tasks")
        logger.info(f"当前任务列表: {running_tasks}")
        for task_id, task_dict in running_tasks.items():
            # 检查任务进程是否还存在
            for uuid, task_running_item in task_dict.items():
                task_process_id = task_running_item["process_pid"]
                if not proc_exist(int(task_process_id)):
                    logger.info(f"任务 {task_id}, {uuid} 进程已退出")
                    self.call_event("task_process_exitd", task_id, uuid)
                    continue
            # 检查任务是否取消
            if bHttpx:
                response = await requests_async.get(f"{SERVER_URL}/build/controller/check/cancel/devices", params={
                    "buildId": int(task_id),
                }, timeout=(10, 15))
            else:
                response = await requests_async.get(f"{SERVER_URL}/build/controller/check/cancel/devices", params={
                            "buildId": int(task_id),
                        },timeout=(10, 15), verify=False)
            ret = json.loads(response.content)
            if ret["code"] == 200:
                if len(ret["data"]) > 0:
                    logger.info(f"任务{task_id}已取消: {ret['data']}")
                    self.send_event("task_cancel", task_id, ret["data"])
        
        # 获取新任务
        # 不知道为什么这个接口无法用requests_async, 推测是旧版python的bug
        # response = requests.get(f"{SERVER_URL}/build/controller/device/startup", verify=False, timeout=(10,15))
        if bHttpx:
            response = await requests_async.get(f"{SERVER_URL}/build/controller/startup", timeout=(10,15))
        else:
            response = requests.get(f"{SERVER_URL}/build/controller/startup", verify=False, timeout=(10,15))

        if bHttpx:
            logger.info(f"获取任务: {response.content}")
            ret_code = response.status_code
            ret = json.loads(response.content)
        else:
            ret = json.loads(response.content)
            logger.info(f"获取任务: {ret}")
            ret_code = ret["code"]
        if ret_code == 200:
            if len(ret["data"]) > 0:
                for data in ret["data"]:
                    self.send_event("task_start", data)

    async def phone_network_check(self):
        '''检查设备连接状态'''
        del_net_devices=[]
        phone_network:dict = self.call_event("get_phone_network")
        logger.info(f"端口表-start{phone_network}")
        for netdevice, _ in phone_network.items():
            try:
                logger.info(f"{netdevice}检查连接\n")
                last_line = str(get_last_line(f"phone_networking/{netdevice}_netlog"))
                line_number = len(open(f"phone_networking/{netdevice}_netlog", 'rU').readlines())
                if 'Cannot start client' in last_line:
                    logger.warning(netdevice + "连接失败,正在断开连接")
                    await asyncio.sleep(3)
                    self.call_event("kill_phone_network", netdevice)
                    logger.warning(netdevice + "断开连接"+ last_line)
                    del_net_devices.append(netdevice)
                if 'Checking gnirehtet client' in last_line or "Address already in use" in last_line or "tarting relay server on port" in last_line or "Relay server started" in last_line:
                    logger.info(f"last_line -> {last_line}")
                    logger.warning(
                        netdevice + "ERROR Main: Execution error: IO error: Address already in use (os error 98)")
                    logger.warning(netdevice + "连接失败,正在断开连接")
                    await asyncio.sleep(3)
                    self.call_event("kill_phone_network", netdevice)
                    logger.warning(netdevice + "断开连接" + last_line)
                    del_net_devices.append(netdevice)
                if line_number >= 10:
                    connect_content = ["TcpConnection", "UdpConnection", "Router","Starting"]
                    judge_connect = any(connect_text in last_line for connect_text in connect_content)
                    if judge_connect == False:
                        logger.warning(netdevice + "连接失败,正在断开连接")
                        await asyncio.sleep(3)
                        rw = subprocess.Popen(
                                ["adb", "-s", netdevice, "shell", "am", "start", "-a", "com.genymobile.gnirehtet.STOP", "-n",
                                "com.genymobile.gnirehtet/.GnirehtetActivity"]
                            )
                        rw.wait()
                        self.call_event("kill_phone_network", netdevice)
                        logger.warning(netdevice + "断开连接"+ last_line)
                        del_net_devices.append(netdevice)
            except Exception as e:
                pass
        logger.info(f"端口表-end{phone_network}")
        for netdevice in del_net_devices:
            try:
                os.remove(f"phone_networking/{netdevice}_netlog")
            except Exception as e:
                logger.error(e)
                phone_token_map = self.call_event("get_share_dict", "phone_token")
                bot=pyfeishu.FeiShutalkChatbot(phone_token_map[netdevice])
                bot.send_text(f"设备号为{netdevice}的设备已不在连接状态")
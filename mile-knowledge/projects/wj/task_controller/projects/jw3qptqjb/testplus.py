import datetime
import json
import multiprocessing
import os
import subprocess
import threading
import time
import traceback

from websocket import create_connection
from BaseToolFunc import *
log_lock = multiprocessing.Lock()
class TPTClient(object):
    """TestPlus Profiler Toolkit Remote Debugging Client"""

    def __init__(self, perfeye_path=None, python_exe_path=None):
        """
        :param tpt_path: tpt client install path
        """
        self._perfeye_path = perfeye_path
        self._python_exe_path = python_exe_path
        self._process = None
        self._message_id = 0
        self._websocket = None
        self._running = False
        self._ws_end_point = None
        self._max_retries_num = 5
    def pid(self):
        """
        get subprocess pid
        :return:
        """
        if self._process:
            return self._process.pid
        else:
            return -1
    def launch(self, launch_args):
        """
        Launch a new tpt client instance
        :param launch_args: "--headless", "debugging-port=9232"
        :return:
        """
        if self._python_exe_path:
            cmd = [self._python_exe_path, "-m", "miniperf.app", *launch_args]
            print("[TPTClient] subprocess cmd %s, cwd %s, time: %s" % (str(cmd), self._perfeye_path, datetime.datetime.fromtimestamp(int(time.time())).strftime('%Y_%m_%d_%H%M%S')))
            try:
                with log_lock:
                    self._process = subprocess.Popen(cmd, cwd=self._perfeye_path, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
                    time.sleep(2)
            except subprocess.CalledProcessError:
                traceback.print_exc()
        else:
            assert self._perfeye_path.endswith("Perfeye.exe")
            cmd = [self._perfeye_path, *launch_args]
            cwd = os.path.split(self._perfeye_path)[0]
            print("[TPTClient] subprocess cmd %s, cwd %s, time: %s" % (str(cmd), cwd, datetime.datetime.fromtimestamp(int(time.time())).strftime('%Y_%m_%d_%H%M%S')))
            try:
                self._process = subprocess.Popen(cmd, cwd=cwd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
            except subprocess.CalledProcessError:
                traceback.print_exc()

        self._running = True
        self._thread = threading.Thread(target=self._thread_func)
        self._thread.start()
        return True

    def _thread_func(self):
        try:
            for line in self._process.stdout:
                if not self._running:
                    break
                # print("[subprocess] %s" % (line))
        except:
            pass
        #self._process.wait()

    def kill(self):
        """
        Kill the tpt client
        :return:
        """
        self._running = False
        if self._process:
            self._process.kill()
            self._process = None

    def set_ws_endpoint(self, ws_end_point):
        """
        set tpt websocket endpoint.
        :param ws_end_point: the remote debugging WebSocket EndPoint
        :return:
        """
        self._ws_end_point = ws_end_point
        return True

    def send_message_no_recv(self, method, params):
        """
        Send message to tpt client
        :param method: rpc method name
        :param params: rpc method params
        :return: json response by the rpc method
        """

        self._message_id += 1
        msg = json.dumps({"id": self._message_id, "method": method, "params":params})

        result = None
        retry_count = 0
        for times in range(3):
            # if retry_count > self._max_retries_num:
            #     print("Can not send_message, max_retries_num=%d" % self._max_retries_num)
            #     break

            try:
                print("Try to connect to TPT client..., retry=%d" % retry_count)
                websocket = create_connection(self._ws_end_point)
                print("[TPTClient] #%d --> SEND message, method=%s, params=%s, retry=%d" % (self._message_id, str(method), str(params), retry_count))
                websocket.send(msg)
                time.sleep(1)
                # websocket.timeout=600
                # response = websocket.recv()
                # websocket.close()
                # if response:
                #     result = json.loads(response)
                #     print("[TPTClient] #%d <-- RECV message, method=%s, response=%s" % (result['id'], str(method), str(response)))
                # print("disconnect from TPT client...")
                # if result:
                #     break
            except SystemExit as errexit:
                self.kill()
                raise errexit
            except:
                pass
                # traceback.print_exc()
            retry_count += 1
        return result


    def send_message(self, method, params,timeout=600,nMaxRetryCnt=-1):
        """
        Send message to tpt client
        :param method: rpc method name
        :param params: rpc method params
        :return: json response by the rpc method
        """
        if nMaxRetryCnt<0:
            nMaxRetryCnt=self._max_retries_num
        self._message_id += 1
        msg = json.dumps({"id": self._message_id, "method": method, "params":params})

        result = None
        retry_count = 0
        while True:
            if retry_count > nMaxRetryCnt:
                print("Can not send_message, max_retries_num=%d" % nMaxRetryCnt)
                break

            try:
                print("Try to connect to TPT client..., retry=%d" % retry_count)
                websocket = create_connection(self._ws_end_point)
                print("[TPTClient] #%d --> SEND message, method=%s, params=%s, retry=%d" % (self._message_id, str(method), str(params), retry_count))
                websocket.send(msg)
                websocket.timeout=timeout
                response = websocket.recv()
                websocket.close()
                if response:
                    result = json.loads(response)
                    print("[TPTClient] #%d <-- RECV message, method=%s, response=%s" % (result['id'], str(method), str(response)))
                print("disconnect from TPT client...")
                if result:
                    break
            except SystemExit as errexit:
                self.kill()
                raise errexit
            except:
                pass
                # traceback.print_exc()
            retry_count += 1
        return result

class Testplus(object):

    def __init__(self, perfeye_path=None, python=None):  # 开发环境需提供python_exe_path
        """
        创建TPT RPC客户端
        @param client_path 客户端安装地址, 目录下存在 run.py 或 Testplus_Profiler_Toolkit.launch.pyw
        @param extension_path 插件目录地址, 默认不需要，直接启动客户端已经安装好的插件
        @param python python.exe的路径
        """
        self._perfeye_path = perfeye_path
        self._tpt_client = TPTClient(perfeye_path, python) # type: TPTClient
        #移动端和PC端的appinfo
        self.app_info=None

    def launch(self, port, headless=True, timeout=20, attach=False):
        """
        启动TPT客户端
        @param port 远程端口
        @param timeout 超时时间
        @param headless Non-GUI模式
        @param attach Attach模式，不启动客户端，attach到已经运行的客户端上
        """
        if not attach and self._perfeye_path:
            launch_args = ["--rpc_port=%d" % port]
            if headless:
                launch_args.append("--headless")
            self._tpt_client.launch(launch_args)
        retry_time = 0
        connect_success = False
        while retry_time < timeout:
            try:
                print("Try to connect to TPT client..., retry time=%d" % retry_time)
                websocket = create_connection("ws://127.0.0.1:%d" % port)
                websocket.close()
                connect_success = True
                print("Try to connect to TPT client success")
                break
            except SystemExit as errexit:
                self.kill()
                raise errexit
            except:
                time.sleep(2)
                retry_time += 2
        assert connect_success, "Can`t connect to TPT client"
        self._tpt_client.set_ws_endpoint("ws://127.0.0.1:%d" % port)

        # response = self._tpt_client.send_message("Extension.get_extension", {
        #     "id": "cn.testplus.basicprof.beta"
        # })
        # testplus_extension = response and response['result']
        # if not testplus_extension:
        #     return False, "Testplus Extension is not exists"
        return True, None

    def kill(self):
        try:
            self._tpt_client.kill()
            #self._tpt_client.send_message("testplus.kill", {},nMaxRetryCnt=0)
        except:
            pass
        return True, None

    def get_device_list(self):
        try:
            response = self._tpt_client.send_message("testplus.get_device_list", {})  # 获取设备列表
        except BaseException as error:
            print('error', error)
            return None, "send_message exception"
        try:
            if response['result']['ok']:
                if len(response['result']['data']) > 0:
                    return response['result']['data'], 'Get device list successful'
                else:
                    return None, "No device connected"
        except BaseException as error:
            print('error', error)
            return None, "Get device list exception"

    def login(self, user, password):
        try:
            response = self._tpt_client.send_message("testplus.login", { "email": user, "password": password})
        except BaseException as error:
            print('error', error)
            return False, "send_message exception"

        if response:
            try:
                user = response['result']['user']
                error = response['result']['error']
                if error is None and user is None:
                    raise Exception("error and user is None")
                elif error is None:
                    return True, 'Login successful'
                elif user is None:
                    return False, error
            except BaseException as error:
                print('error', error)
                return False, "Login exception"
        return False, "Unknown error"

    def logout(self):
        try:
            response = self._tpt_client.send_message("testplus.logout", {})
        except BaseException as error:
            print('error', error)
            return False, "send_message exception"
        if response:
            try:
                if response['result']['result']:
                    return response['result']['result'], "Logout successful"
                else:
                    return response['result']['result'], "Logout failure"
            except BaseException as error:
                print('error', error)
                return False, "logout exception"
        return False, "unknown error"

    def get_projects(self):
        try:
            response = self._tpt_client.send_message("testplus.get_projects", {})
        except BaseException as error:
            print('error', error)
            return None, "send_message exception"
        if response:
            try:
                if response['result']['projects']:
                    return response['result']['projects'], "get_projects successful"
                else:
                    return None, "get_projects failure"
            except BaseException as error:
                print('error', error)
                return None, "get_projects exception"
        return None, "unknown error"

    def connect(self, serial,package_name=None, configs={},pid=None):

        try:
            response = self._tpt_client.send_message("testplus.connect", {"serial": serial, "configs": configs})  # 连接设备
        except BaseException as error:
            print('error', error)
            return False, "send_message exception"

        try:
            if response['result']['ok']:
                pass
                #return True, response['result']['msg']
            else:
                return False, response['result']['msg']
        except BaseException as error:
            print('error', error)
            return False, "connect exception"
        #移动端在connect(app启动前)阶段 获取appinfo
        #PC端的serial必须为localhost
        if serial!='localhost' and package_name:
            return self.get_appInfo(serial,package_name=package_name)
        else:
            return True, response['result']['msg']
        '''
        try:
            response = self._tpt_client.send_message("testplus.get_app_list", {"serial": serial})  # 获取app列表
        except SystemExit as errexit:
            self.kill()
            raise errexit
        except BaseException as error:
            print('error', error)
            return False, "send_message exception", None
        try:
            if response['result']['ok']:
                app_list = response['result']['data']
            else:
                return False, 'get_app_list exception', None
        except SystemExit as errexit:
            self.kill()
            raise errexit
        except BaseException as error:
            print('error', error)
            return False, "get_app_list exception", None
        app_info = None

        if package_name:
            for app_item in app_list:
                if app_item['packageName'] == package_name:
                    app_info = app_item
        elif pid:
            for app_item in app_list:
                if app_item['pid'] == pid:
                    app_info = app_item
        else:
            return False, "Pid or package_name required",app_info

        if app_info is None:
            return False, "Application is not exists",app_info

        try:
            if responsecon['result']['ok'] and response['result']['ok']:
                return True, responsecon['result']['msg'],app_info
            else:
                return False, responsecon['result']['msg'],app_info
        except SystemExit as errexit:
            self.kill()
            raise errexit
        except BaseException as error:
            print('error', error)
            return False, "connect exception",app_info
        '''

    def disconnect(self, serial):
        try:
            response = self._tpt_client.send_message("testplus.disconnect", {"serial": serial})  # 连接设备
        except BaseException as error:
            print('error', error)
            return False, "send_message exception"
        try:
            if response['result']['ok']:
                return True, response['result']['msg']
            else:
                return False, response['result']['msg']
        except BaseException as error:
            print('error', error)
            return False, "disconnect exception"

    def get_appInfo(self,serial,package_name=None,pid=None):
        try:
            response = self._tpt_client.send_message("testplus.get_app_list", {"serial": serial})  # 获取app列表
        except BaseException as error:
            print('error', error)
            return False, "send_message exception"

        try:
            if response['result']['ok']:
                app_list = response['result']['data']
            else:
                return False, 'get_app_list exception'
        except BaseException as error:
            print('error', error)
            return False, "get_app_list exception"

        if package_name:
            for app_item in app_list:
                if app_item['packageName'] == package_name:
                    self.app_info = app_item
                    break
        elif pid:
            for app_item in app_list:
                if app_item['pid'] == pid:
                    self.app_info = app_item
                    break
        else:
            return False, "Pid or package_name required"

        return True,self.app_info


    def start(self, serial, package_name=None, data_types=[], pid=None, screenshot_interval=2,app_info = None):
        # Step 6. 获取应用列表  此模块移到app启动前,仅现移动端
        if package_name:
            #移动端
            pass
        elif pid:
            bRet,res=self.get_appInfo(serial,pid=pid)
            if not bRet:
                return bRet,res
        else:
            return False, "Pid or package_name required"

        if self.app_info is None:
            return False, "Application is not exists"
        try:
            response = self._tpt_client.send_message("testplus.start", {
                "serial": serial,
                "app_info": self.app_info,
                "data_types": data_types,
                "screenshot_interval": screenshot_interval
            })  # 开始测试
        except BaseException as error:
            print('error', error)
            return False, "send_message exception"

        try:
            if response['result']['ok']:
                return True, 'start test'
            else:
                return False, response['result']['msg']
        except BaseException as error:
            print('error', error)
            return False, "start exception"

    def save(self, serial, case_name, report_file_path=None, need_upload=True, need_save=False, appKey=None, scenes=None, picture_quality=None, do_upload=None, version=None, extra_data=None,timeout=600):
        # for retry in range(2):
        try:
            response = self._tpt_client.send_message("testplus.save", {
                "serial": serial,
                "case_name": case_name,
                "report_file_path": report_file_path,
                "need_upload": need_upload,
                "need_save": need_save,
                "app_key": appKey,
                "scenes": scenes,
                "picture_quality": picture_quality,
                "do_upload": do_upload,
                "version": version,
                "extra_data": extra_data,
            }, timeout=timeout)  # 保存报告
        except BaseException as error:
            print('error', error)
            print(False, "send_message exception")

        try:
            if response['result']['ok']:
                return True, response
            else:
                print(False, response)
        except BaseException as error:
            print('error', error)
            print(False, "save exception")

        # print(f"perfeye第{retry}次上传失败")
        return False, "save or upload file exception"

    def stop(self, serial):
        try:
            response = self._tpt_client.send_message("testplus.stop", {
                "serial": serial,
            })  # 停止收集
        except BaseException as error:
            print('error', error)
            return False, "send_message exception"

        try:
            if response['result']['ok']:
                return True, response
            else:
                return False, response
        except BaseException as error:
            print('error', error)
            return False, "stop exception"
        
    def stop_flash_back(self, serial):
        try:
            response = self._tpt_client.send_message_no_recv("testplus.stop", {
                "serial": serial,
            })  # 停止收集
        except BaseException as error:
            print('error', error)
            return False, "send_message exception"

        try:
            if response['result']['ok']:
                return True, response
            else:
                return False, response
        except BaseException as error:
            print('error', error)
            return False, "stop exception"

    def set_standard(self, serial, test_standard):
        try:
            response = self._tpt_client.send_message("testplus.set_standard", {
                "serial": serial,
                "test_standard": test_standard
            })  # 设置测试标准
        except BaseException as error:
            print('error', error)
            return False, "send_message exception"

        try:
            if response['result']['ok']:
                return True, response['result']['msg']
            else:
                return False, response['result']['msg']
        except BaseException as error:
            print('error', error)
            return False, "set_standard exception"
    def pid(self):
        return self._tpt_client.pid()
    def add_label(self, serial, label_name):
        try:
            response = self._tpt_client.send_message("testplus.add_label", {
                "serial": serial,
                "label_name": label_name
            })
        except BaseException as error:
            print('error', error)
            return False, "send_message exception"

        try:
            if response['result']['ok']:
                return True, response['result']['msg']
            else:
                return False, response['result']['msg']
        except BaseException as error:
            print('error', error)
            return False, "set_standard exception"

    def get_last_timestamp(self, serial):
        try:
            response = self._tpt_client.send_message("testplus.get_last_timestamp", {
                "serial": serial,
            })
        except BaseException as error:
            print('error', error)
            return False, "send_message exception"

        try:
            if response['result']['ok']:
                return True, response['result']['msg']
            else:
                return False, response['result']['msg']
        except BaseException as error:
            print('error', error)
            return False, "get_last_timestamp exception"

    def start_test_case(self, serial, label_name):
        try:
            response = self._tpt_client.send_message("testplus.start_test_case", {
                "serial": serial,
            })
        except BaseException as error:
            print('error', error)
            return False, "send_message exception"

        try:
            if response['result']['ok']:
                return True, response['result']['msg']
            else:
                return False, response['result']['msg']
        except BaseException as error:
            print('error', error)
            return False, "start_test_case exception"

    def android_check_device(self, serial):
        try:
            response = self._tpt_client.send_message("testplus.android_check_device", {
                "serial": serial,
            })
        except BaseException as error:
            print('error', error)
            return False, "send_message exception"

        try:
            if response['result']['ok']:
                return True, response['result']['msg']
            else:
                return False, response['result']['msg']
        except BaseException as error:
            print('error', error)
            return False, "android_check_device exception"
import os, json
import time
import traceback
import socket
from datetime import datetime

import psutil, subprocess
import shutil
import uuid
import zipfile
import gzip
import hashlib
import logging, logging.handlers
import requests
import wget
from . import SnapshotToolConfig
from urllib import request, error

class SnapshotTool:

    def __init__(self, game_path, game_name, appkey, device_ip, parameters, platform, deviceName, game_quality,
                 localcase, daily, package_url):
        self.device_ip = device_ip
        self.game_path = game_path
        self.parameters = parameters
        self.appkey = appkey
        self.RenderdocUrl = SnapshotToolConfig.GatherToolsUrl["renderdoc"]
        self.official_rdc = SnapshotToolConfig.GatherToolsUrl["official_rdc"]
        self.toolname = "renderdoc"
        self.Snapshot_is_run = False
        self.platform = platform.upper()
        self.connectip = device_ip
        self.branch = ""
        self.version = ""
        self.deviceName = deviceName
        self.gamequality = game_quality
        self.daily = daily
        self.RenderdocConn = None
        self.casename = ""
        self.localCaseName = localcase
        if not game_name.endswith(".exe"):
            game_name += ".exe"
        self.game_name = game_name
        self.scenename = ""
        self.url = {}
        self.waitClearFile = []
        self.package_url = package_url
        self.rdc_analyze_arg = 7  # 1=gpu平台没shader数据，7=gpu平台有shader数据
        self.ProjectId = "jw3qptqjb"
        logging.basicConfig(level=logging.INFO)
        self.log = logging.getLogger(str(os.getpid()))

    def Start(self, toollist={}, branch="trunk"):
        try:
            ToolPath = os.path.join(os.path.abspath('.')[:3], "AutoTool", "AutoFiring")
            if not os.path.exists(ToolPath):
                os.makedirs(ToolPath)
            self.add_port_rule()  # 添加防火墙端口
            # Step 5. 开始测试
            self.branch = branch

            self.toolname = "renderdoc"
            # 初始化工具
            self.InitRenderdoc()
            #self.rdc_analyze_arg = 1 if "Run_Type" not in toollist["RDCapture"] else toollist["RDCapture"]["Run_Type"]
        except:
            info = traceback.format_exc()
            self.log.info(info)

    #截取快照
    def Grab(self, sceneneme, casename, version):
        self.version = version
        self.scenename = sceneneme
        casename = f"{casename}-{int(time.time())}"
        casename = casename.replace('|', '-')

        if self.toolname == "renderdoc":
            self.log.info("截取一次Renderdoc快照")
            captureMsg = {
                "method": "takecapture",
                "path": casename
            }
            self.log.info("captureMsg:"+ json.dumps(captureMsg))
            self.RenderdocConn.sendall(json.dumps(captureMsg).encode())
            data = self.RenderdocConn.recv(4096)
            self.log.info(data.decode())
            res = json.loads(data.decode())
            self.log.info(res)
            if res["OK"]:
                self.log.info(f"截取快照{casename}成功")
                renderdoc_info = {"res": res, "scene_name": sceneneme, "case_name": casename}
                if "不解析" in casename:
                    return renderdoc_info
                else:
                    return self.Renderdoc_Analyse(renderdoc_info)
            else:
                self.log.info("截取Renderdoc快照失败")
                raise Exception("截取Renderdoc快照失败——", data.decode())

    def Stop(self):
        try:
            # Step 6. 停止采集
            self.log.info("开始停止工具:Firingsrv")
            if self.toolname == "renderdoc":
                self.log.info("结束Renderdoc工具采集")
                for delete_file in self.waitClearFile:
                    if os.path.isdir(delete_file):
                        shutil.rmtree(delete_file)
                    else:
                        os.remove(delete_file)
                os.system(f"taskkill /f /t /im autoRenderdoc.exe")
            return self.url
        except Exception as e:
            info = traceback.format_exc()
            self.log.info(info)
            os.system(f"taskkill /f /t /im autoRenderdoc.exe")
            return []

    def GzipFIle(self, src_file, des_file):
        with open(src_file, 'rb') as f_in:
            with gzip.open(des_file, 'wb') as f_out:
                f_out.writelines(f_in)

    # 压缩文件夹
    def Zip_Folder(self, foder_path, output_zipPath):
        with zipfile.ZipFile(output_zipPath, 'w', zipfile.ZIP_DEFLATED) as zipf:
            for root, _, files in os.walk(foder_path):
                for file in files:
                    abs_path = os.path.join(root, file)
                    rel_path = os.path.relpath(abs_path, os.path.dirname(foder_path))
                    zipf.write(abs_path, rel_path)

    def install_official_rdc(self, dir_path):
        """ 部分设备缺少系统环境依赖，安装官方rdc工具可补全 """
        if os.path.exists(r"C:\ProgramData\Microsoft\Windows\Start Menu\Programs\RenderDoc"):
            return True
        wget.download(self.official_rdc, out=dir_path, bar=None)
        file_path = os.path.join(dir_path, wget.filename_from_url(self.official_rdc))
        command = ['msiexec', '/i', file_path, '/quiet']
        try:
            process = subprocess.Popen(command)
            process.wait()
            if process.returncode == 0:
                self.log.info("MSI 安装包启动成功")
            else:
                self.log.info(f"MSI 安装包安装失败，错误代码：{process.returncode}")
        except subprocess.CalledProcessError as e:
            self.log.info(f"MSI 安装包启动失败: {e}")

    def InitRenderdoc(self):
        #设置路径
        file_name = wget.filename_from_url(self.RenderdocUrl)
        root = os.path.join(os.path.abspath('.')[:3], "AutoTool", "AutoFiring")
        self.log.info(root)
        if not os.path.exists(root):
            os.makedirs(root)
        #安装官方工具
        self.install_official_rdc(root)
        file_path = os.path.join(root, file_name)
        #清理autoRenderdoc文件
        if self.is_process_running("autoRenderdoc.exe"):
            self.Kill_ByPort(SnapshotToolConfig.ConnectPort["renderdoc"])  # 杀一下进程
        if os.path.exists(file_path):
            # 删除文件
            os.remove(file_path)
            self.log.info(f"File {file_path} deleted successfully")
        else:
            self.log.info("The file does not exist")
        try:
            request.urlopen(self.RenderdocUrl)
        except error.HTTPError:
            self.log.info("url指向的包体不存在 404 ")
            return False
        #下载autoRenderdoc.exe
        self.log.info(f"开始下载:{file_name}")
        file_name = wget.download(self.RenderdocUrl, out=file_path, bar=None)
        self.log.info(file_name+"下载完成")

        #启动autoRenderdoc.exe
        self.log.info("初始化Renderdoc工具完毕")
        cmdstr = "cd " + root + " & start autoRenderdoc.exe auto_mode"
        self.log.info(cmdstr)
        os.system(cmdstr)
        time.sleep(5)
        self.close_win()
        isStartSuccess = False
        for i in range(20):
            pids = psutil.pids()
            for pid in pids:
                if 'autoRenderdoc.exe' in psutil.Process(pid).name():
                    self.log.info("autoRenderdoc.exe进程已打开")
                    isStartSuccess = True
                    break
            if isStartSuccess:
                break
            time.sleep(1)
        time.sleep(10)
        server_address = (SnapshotToolConfig.ConnectServers["renderdoc"][:9], SnapshotToolConfig.ConnectPort["renderdoc"])
        self.log.info(SnapshotToolConfig.ConnectServers["renderdoc"][:9])
        self.log.info(SnapshotToolConfig.ConnectPort["renderdoc"])
        client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        client_socket.connect(server_address)

        # 恢复注册vulkan debug layer
        startMsg = {
            "method": "resetVkDebugLayer",
            "path": "test"
        }
        self.log.info(f"startMsg:{json.dumps(startMsg)}")
        client_socket.sendall(json.dumps(startMsg).encode())
        data = client_socket.recv(4096)
        self.log.info(f"Receive data:{data.decode()}")

        #注册vulkan debug layer
        startMsg = {
            "method": "regVkDebugLayer",
            "path":"test"
        }
        self.log.info(f"startMsg:{json.dumps(startMsg)}")
        client_socket.sendall(json.dumps(startMsg).encode())
        data = client_socket.recv(4096)
        self.log.info(f"Receive data:{data.decode()}")

        #启动客户端
        launch_args = ""
        if self.parameters:
            launch_args = self.parameters
        startMsg = {
            "method": "startgame",
            "path": self.game_path.replace("\\", "/") + "/" + self.game_name,
            "args": f"{launch_args}"
        }
        self.log.info(f"startMsg:{json.dumps(startMsg)}")
        client_socket.sendall(json.dumps(startMsg).encode())
        data = client_socket.recv(4096)
        self.RenderdocConn = client_socket
        self.log.info("Receive data:"+data.decode())
        res = json.loads(data.decode())
        if res["OK"]:
            self.log.info("Renderdoc注入启动游戏成功")
            time.sleep(50)
        else:
            self.log.info("Renderdoc注入启动游戏失败")
            raise Exception(res)

    # 判断进程是否在运行
    def is_process_running(self, process_name):
        for proc in psutil.process_iter(['pid', 'name']):
            try:
                if process_name.lower() in proc.info['name'].lower():
                    return True
            except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
                pass
        return False

    # 通过端口杀死进程
    def Kill_ByPort(self, port):
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            if s.connect_ex(('127.0.0.1', port)) == 0:
                pid = self.find_process_by_port(port)
                if pid:
                    psutil.Process(pid).kill()

    def find_process_by_port(self, port):
        for conn in psutil.net_connections(kind='tcp'):
            if conn.laddr.port == port:
                return conn.pid
        return None

    # 替换后缀名
    def Replace_file_extension(self, file_path, new_extension):
        # 获取文件名（不带后缀）和路径
        file_name_without_extension = os.path.splitext(file_path)
        directory = os.path.dirname(file_path)
        new_file_path = os.path.join(directory, file_name_without_extension + new_extension)
        return new_file_path

    def add_port_rule(self):
        # 添加端口规则（保持原方法，可能被InitRenderdoc调用）
        pass

    def close_win(self):
        # 关闭窗口（保持原方法，可能被InitRenderdoc调用）
        pass

    def Renderdoc_Analyse(self, renderdoc_info):
        res = renderdoc_info["res"]
        casename = renderdoc_info["case_name"]
        sceneneme = renderdoc_info["scene_name"]

        stopMsg = {
            "method": "analysecapture",
            "path": res["filename"],
            "settings": {
                "Run_Type": 7 if not self.rdc_analyze_arg else self.rdc_analyze_arg,
                "Point_Name": casename
            }
        }
        self.log.info("stopMsg:"+json.dumps(stopMsg))
        self.RenderdocConn.sendall(json.dumps(stopMsg).encode())
        resdata = self.RenderdocConn.recv(4096)
        self.log.info(resdata.decode())
        res_analyze = json.loads(resdata.decode())
        if res_analyze["OK"]:
            self.log.info(f"解析一份快照成功{resdata.decode()}")
            pathUUid = uuid.uuid4().hex
            resultPath = os.path.join(os.path.abspath('.')[:3], "AutoTool", "AutoFiring", "RenderdocResult", pathUUid)
            rdcPath = os.path.join(os.path.abspath('.')[:3], "AutoTool", "AutoFiring", "RenderdocRdcFile", pathUUid)
            if not os.path.exists(resultPath):
                os.makedirs(resultPath)
            if not os.path.exists(rdcPath):
                os.makedirs(rdcPath)
            self.log.info(f"resultPath:{resultPath}")
            self.log.info(f"rdcPath:{rdcPath}")

            stopMsg = {
                "method": "uploadcapture",
                "path": res["filename"],
                "info": {
                    "appkey": self.appkey,
                    "projectId": self.ProjectId,
                    "uuid": pathUUid,
                    "model": self.deviceName + "_" + self.device_ip,  # 机型名
                    "scene_name": sceneneme,
                    "case_name": f"{casename}",
                    "tag": self.daily,
                    "data_type": "Pass&Shaders",
                    "tool_type": "Renderdoc",
                    "fileName": pathUUid + ".zip",
                    "version": self.version,
                    "branch": self.branch,
                    "channel": self.platform,
                    "buildTime": datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
                    "game_quality": self.gamequality
                }
            }
            self.log.info("stopMsg:" + json.dumps(stopMsg))
            self.RenderdocConn.sendall(json.dumps(stopMsg).encode())
            resdata = self.RenderdocConn.recv(4096)
            self.log.info(resdata.decode())
            #{"OK": true, "msg": "upload done", "filename": "", "filenames": "", "reportId": 31248}
            res_upload = json.loads(resdata.decode())
            if res_upload["OK"]:
                self.log.info("uploadcapture 上传成功")
                return res_upload
            else:
                self.log.info("uploadcapture 上传失败")
                raise Exception("uploadcapture 上传失败")


            '''
            # 结果截图移动
            shutil.move(res_analyze["filenames"]["pic"], os.path.join(resultPath, f"{pathUUid}.png"))
            # 结果json移动
            shutil.move(res_analyze["filenames"]["json_shader"], os.path.join(resultPath, f"{pathUUid}_shader.json"))
            shutil.move(res_analyze["filenames"]["json_pass"], os.path.join(resultPath, f"{pathUUid}_pass.json"))
            shutil.move(res_analyze["filenames"]["json_padr"],
                        os.path.join(resultPath, f"{pathUUid}_pass_shaders.json"))
            # 结果rdc文件移动
            NewrdcPath = os.path.join(rdcPath, f"{pathUUid}.rdc")
            self.log.info(f"new rdc path :{NewrdcPath}")
            shutil.move(res["filename"], NewrdcPath)
            # 开始压缩上传
            outPut_zip = resultPath + ".zip"
            outRdc_gzip = NewrdcPath + ".gz"
            self.Zip_Folder(resultPath, outPut_zip)
            self.GzipFIle(NewrdcPath, outRdc_gzip)
            data_param = {
                "appkey": self.appkey,
                "projectId": self.ProjectId,
                "uuid": pathUUid,
                "model": self.deviceName + "_" + self.device_ip,  # 机型名
                "sceneName": sceneneme,
                "caseName": f"{self.version}-{sceneneme}-{casename}",
                "tag": self.daily,
                "data_type": "Pass&Shaders",
                "tool_type": "Renderdoc",
                "fileName": pathUUid + ".zip",
                "version": self.version,
                "branch": self.branch,
                "channel": self.platform,
                "buildTime": datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
                "game_quality": self.gamequality
            }
            self.log.info("UploaData:" + json.dumps(data_param))
            res_post = requests.post(SnapshotToolConfig.GPU_Upload["Upload_Url"], data=json.dumps(data_param))
            self.log.info(res_post.status_code)
            self.log.info(res_post.text)
            if res_post.status_code == 200:
                res_data = json.loads(res_post.text)
                if res_data["msg"] == "success":
                    # 上传结果压缩文件
                    reportId = res_data["data"]["report_id"]
                    uploadUrl = res_data["data"]["rdc_upload_url"]
                    uploadUrl = res_data["data"]["upload_url"]
                    with open(outPut_zip, 'rb') as fs:
                        resp = requests.put(uploadUrl, data=fs)
                        self.log.info(f"File {outPut_zip} upload was successful!")
                        self.log.info("Response:"+resp.text)
                        fs.close()
                    # 上传源文件
                    uploadUrl_source = res_data["data"]["snap_upload_url"]
                    with open(outRdc_gzip, 'rb') as fs:
                        resp = requests.put(uploadUrl_source, data=fs)
                        self.log.info(f"File {outRdc_gzip} upload was successful!")
                        self.log.info("Response:", resp.text)
                        # 上传完的话请求解析
                        params = {
                            'reportId': reportId,
                            'analysis': True
                        }  # 将参数替换为实际的参数和值
                        res_get = requests.get(SnapshotToolConfig.GPU_Upload["Analyze_Url"], params=params,
                                               timeout=(60, 60))
                        if res_get.status_code == 200:
                            self.log.info(f"ReportId {reportId} Request analyze successful.")
                            self.log.info("Response:"+res_get.text)
                            # 给个分析报告链接
                            thisurl = f" http://memorycomparer.console.testplus.cn/project/ {self.ProjectId}/vk/{self.appkey}/gpu-profiler-cpu-gpu-total?branch=all&channel=all&currentStatisticId={str(reportId)}"
                            self.add_to_url("Renderdoc", thisurl)
                            # 清除缓存文件
                            self.waitClearFile.append(outPut_zip)
                            self.waitClearFile.append(outRdc_gzip)
                            self.waitClearFile.append(resultPath)
                            self.waitClearFile.append(rdcPath)
                        fs.close()
                else:
                    raise Exception("上传文件请求失败")
            else:
                raise Exception("上传文件请求失败")'''
        else:
            raise Exception("快照解析失败")

    def add_to_url(self, name, url):
        if name in self.url:
            self.url[name].append(url)
        else:
            self.url[name] = [url]

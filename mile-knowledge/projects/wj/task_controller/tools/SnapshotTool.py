import hashlib
import os,json
import time
import traceback
import uuid
import zipfile
from datetime import datetime,timedelta
from utils.constants import Memory_Upload,Minio_Config
import requests
from minio import Minio

class SnapshotTool:

    def __init__(self, project_id,appkey, device_s, platform, deviceModel, game_quality, daily,game_name,game_pid,device_ip):
        self.project_id = project_id
        self.device_ip = device_ip
        self.device_s=device_s
        self.appkey=appkey
        self.toolname=""
        self.platform=platform
        self.branch = ""
        self.requestQue = []
        self.udriver = None
        self.deviceModel = deviceModel
        self.gamequality = game_quality
        self.daily = daily
        self.casename = ""
        self.url = []
        self.unityVersion = ""
        self.game_name = game_name
        self.game_pid = game_pid
        self.report_name = []




    #获取截取快照类型
    def Start(self,tool_name):
        try:
            if not os.path.exists("memorylocalcache"):
                os.mkdir("memorylocalcache")
            if "MemProMonitor" in tool_name:
                self.toolname = "memorySnapAnalyze"  # MemoryProfiler自动解析，带监控数据
        except:
            traceback.print_exc()

    def InitUdriver(self,u3driver):
        self.udriver = u3driver
        try:
            unity_version = self.udriver.get_unity_version()
            print(f"当前unity版本为 -> {unity_version}")
            self.unityVersion = unity_version
        except:
            self.unityVersion = "2022.3.20f9" # 月影unity版本


    # 遍历目录及其子目录下的所有文件

    def RenameFiles(self, startpath: str, uid: str):
        for filename in os.listdir(startpath):
            # 通过替换字符串来修改文件名
            new_filename = filename.replace(os.path.splitext(os.path.basename(filename))[0], uid)
            # 使用os.rename()函数进行重命名
            os.rename(os.path.join(startpath, filename), os.path.join(startpath, new_filename))



    def Grab(self, case_name,report_name, version):
        if self.toolname=="memorySnapAnalyze":
            print("截取一次MemoryProfiler内存快照")
            fileuuid = uuid.uuid4().hex
            snapFilePath = os.path.join("memorylocalcache", str(fileuuid))
            if not os.path.exists(snapFilePath):
                os.mkdir(snapFilePath)
            res = self.udriver.profiling_memory()
            if type(res) != int and res["result"] == "True":
                print("截取成功")
                time.sleep(5)
                tempSnapFilePath = res["Reply_Content"]
                os.popen(f"adb -s {self.device_s} pull {tempSnapFilePath} {snapFilePath}").read()
                time.sleep(5)
                # 将时间格式化为指定的字符串格式
                formatted_time = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
                snapFileFormat = {
                    "Appkey": self.appkey,
                    "ProjectId": self.project_id,
                    "Uuid": fileuuid,
                    "Model": self.device_s + "_" + self.deviceModel,  # 机型名
                    "SceneName": case_name,  # 场景名
                    "CaseName":f"{self.device_s}-{report_name}",  # 报告名 格式是 设备序列号-版本-案例名-场景名
                    "Quality": self.gamequality,  # 游戏画质
                    "Tag": "auto-daily" if self.daily else "auto",
                    "FileName": fileuuid + ".snap.zip",  # uuid.snap
                    "BuildTime": formatted_time,  # yyyy-mm-dd hh:min:ss
                    "Version": version,
                    "Channel": self.platform,
                    "Branch": self.branch,
                    "LocalFilePath": snapFilePath + "/" + fileuuid + ".snap"  # 绝对路径 D:/uuid.snap
                }
                self.requestQue.append(snapFileFormat)  # 加入请求解析队列中，待结束案例前进行发送，停止的时候str(snapFileFormat)
                self.report_name.append(f"{self.device_s}-{report_name}") #minio上传的报告名需要同步上去
                pngFilePath = os.path.splitext(res["Reply_Content"])[0] + ".png"
                os.popen(f"adb -s {self.device_s} pull {pngFilePath} {snapFilePath}").read()
                time.sleep(5)
                # 拉取对应smaps文件
                lines = os.popen(f"adb -s {self.device_s} shell run-as {self.game_name} cat /proc/{self.game_pid}/smaps").read()
                smaps_path = os.path.join(snapFilePath,f"smaps-{self.game_pid}.smaps")
                with open(smaps_path, 'w') as f:
                    f.write(lines)
                self.RenameFiles(startpath=snapFilePath, uid=fileuuid)
                # 删除手机本地文件
                os.popen(f"adb -s {self.device_s} shell rm {tempSnapFilePath}").read()
                os.popen(f"adb -s {self.device_s} shell rm {pngFilePath}").read()
            else:
                print("截取一次MemoryProfiler快照失败")
                raise Exception("截取MemoryProfiler快照失败，请检查：", str(res))

        else:
            print("不支持的采集内存类型")


    def Replace_file_extension(self, file_path, new_extension):
        # 分离文件路径和扩展名
        base = os.path.splitext(file_path)[0]
        # 创建新的文件名
        new_file_path = f"{base}{new_extension}"
        return new_file_path


    def Stop(self):
        try:
            print("开始停止工具")
            if self.toolname == "memorySnapAnalyze":
                print("结束memoryProfiler采集")
                if self.requestQue.count != 0:
                    minio_client = Minio(Minio_Config["MINIO_HOST"], access_key=Minio_Config["MINIO_ACCESS_KEY"],
                                         secret_key=Minio_Config["MINIO_SECRET_KEY"],
                                         secure=False)
                    count = 0
                    for item in self.requestQue:
                        uploadZipPath = item["LocalFilePath"] + ".zip"
                        uploadZipPath = uploadZipPath.replace("\\", "/")
                        SnapPath = item["LocalFilePath"]
                        PngPath = self.Replace_file_extension(item["LocalFilePath"], ".png")
                        SmapsPath = self.Replace_file_extension(item["LocalFilePath"], ".smaps")
                        # 压缩文件
                        with zipfile.ZipFile(uploadZipPath, 'w', compression=zipfile.ZIP_DEFLATED) as zipf:
                            zipf.write(SnapPath, arcname=os.path.basename(SnapPath))
                            zipf.write(PngPath, arcname=os.path.basename(PngPath))
                            zipf.write(SmapsPath, arcname=os.path.basename(SmapsPath))
                        print("压缩文件成功" + uploadZipPath)
                        # 请求上传操作
                        requestData = {
                            "appkey": item["Appkey"],
                            "projectId": item["ProjectId"],
                            "uuid": item["Uuid"],
                            "model": item["Model"],
                            "sceneName": item["SceneName"],
                            "game_quality": item["Quality"],
                            "tag": item["Tag"],
                            "fileName": item["FileName"],
                            "version": item["Version"],
                            "branch": item["Branch"],
                            "channel": item["Channel"],
                            "buildTime": item["BuildTime"],
                            "caseName": item["CaseName"]
                        }
                        res = requests.post(Memory_Upload["Upload_Url"],
                                            data=json.dumps(requestData))
                        print("UploaData:" + json.dumps(requestData))
                        resJson = json.loads(res.text)
                        if "success" in resJson["msg"]:
                            print("Post Request was successful:" + res.text)
                            uploadUrl = resJson["data"]["snap_upload_url"]
                            reportid = resJson["data"]["report_id"]
                            with open(uploadZipPath, 'rb') as fs:
                                resp = requests.put(uploadUrl, data=fs)
                                if resp.text == "":
                                    print(uploadZipPath + "文件上传成功")
                                    # 请求解析....
                                    zipPathMd5 = self.get_file_md5(uploadZipPath)
                                    requestAnalyzeData = {
                                        "analysis": True,
                                        "caseid": item["Uuid"],
                                        "reportId": str(reportid),
                                        "unityVersion": self.unityVersion,
                                        "caseType": "memory-unity",
                                        "snapFile": {item["FileName"]: zipPathMd5}
                                    }
                                    print("RequestAnalyzeData:" + json.dumps(requestAnalyzeData))
                                    resAnalyze = requests.post(Memory_Upload["Analyze_Url"],
                                                               data=json.dumps(requestAnalyzeData))
                                    resJsonAnalyze = json.loads(resAnalyze.text)
                                    if "开始分析snap" in resJsonAnalyze["msg"]:
                                        print(uploadZipPath + "请求解析成功----")
                                        # 清除数据文件放在判断的时候吧
                                        formatted_time = datetime.now().strftime('%Y-%m-%d')
                                        sevenDayago = datetime.now() - timedelta(days=7)
                                        startTime = sevenDayago.strftime('%Y-%m-%d') + " 00:00:00"
                                        endTime = formatted_time + " 23:59:59"
                                        thisurl = f"http://memorycomparer.console.testplus.cn/project/{self.project_id}/vk/{self.appkey}/memory-profiler-memory-monitor?branch=all&channel=all&currentStatisticId={str(reportid)}&endTime={endTime}&startTime={startTime}"
                                        self.url.append(thisurl)
                                        # 请求解析成功的话删除本地的snap和png文件
                                        try:
                                            os.remove(PngPath)
                                            os.remove(SnapPath)
                                            os.remove(SmapsPath)
                                            print(f"删除本地{SnapPath}文件、{SmapsPath}文件和{PngPath}文件成功")
                                        except:
                                            traceback.print_exc()
                                    else:
                                        print("请求解析失败----")
                                        print(resAnalyze.text)
                                else:
                                    print(uploadZipPath + "上传失败")
                                    print(resp.text)
                            fs.close()
                            print(self.__minio_upload(minio_client,uploadZipPath,self.report_name[count]))
                            # 删除源zip文件
                            print(f"源zip文件路径 -> {uploadZipPath}")
                            os.remove(uploadZipPath)
                        else:
                            print("Post Request was failed." + res.text)
                        count += 1
            return self.url
        except Exception as e:
            traceback.print_exception(e)
            return []


    # 获取MD5值  传fileaname---uuid.snap.zip这个文件的绝对路径
    def get_file_md5(self,file_path):
        with open(file_path, "rb") as file:
            md5value = hashlib.md5(file.read()).hexdigest()
        return md5value

    def __minio_upload(self,minio_client,file_path: str, filename: str) -> str:
        with open(file_path, 'rb') as file_data:
            file_size = os.path.getsize(file_path)
            try:
                data_bucket = ""
                if self.project_id == 'yycs':
                    data_bucket = Minio_Config["yycs_snapBucket"]
                elif self.project_id == 'jxsj4':
                    data_bucket = Minio_Config["jxsj4_snapBucket"]
                else:
                    print("不支持的项目")
                minio_client.put_object(data_bucket, f"{filename}.zip", file_data, file_size)
                url = minio_client.presigned_get_object(data_bucket, f"{filename}.zip")
                if self.project_id == 'jxsj4':
                    response = requests.post(
                        f"http://10.11.67.131:8888/api/track/{self.project_id}/Android/memory-profiler",
                        json={
                            "ip": self.device_ip,
                            "casename": filename.split('-')[2],
                            "version": filename.split('-')[1],
                            "snap": f"http://{Minio_Config['MINIO_HOST']}/snapshot/{filename}.zip",
                            "tags": []
                        }, timeout=(10, 15))
                    ret = json.loads(response.content)
                    print(f"调用发送内存采集接口{ret['msg']}，内存采集接口地址为-> http://10.11.10.147:9000/snapshot/{filename}.zip")
                return url.split('?')[0]
            except Exception as err:
                print(f"上传失败，错误信息：{err}")
                return ''




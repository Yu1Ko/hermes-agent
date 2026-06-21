import json
import os
import shutil
import subprocess
import time
import traceback
import zipfile
import datetime
import requests
import tidevice
import re
import ad_ios
from extensions import logger
import chardet


class Logmanage(object):
    def __init__(self, server_url,device_s,device_id,task_running_id,Android_IOS:ad_ios.Android_IOS,device_ip, bug_log_ios_pid_dict, device_name,platform):
        self.device_s=device_s
        self.device_id=device_id
        self.task_running_id=task_running_id
        self.platform=platform
        self.Android_IOS=Android_IOS
        self.device_ip=device_ip
        self.buglogios=None
        self.server_url=server_url
        self.bug_log_ios_pid = bug_log_ios_pid_dict
        self.device_name = device_name
        self.log_files = []
        self.custom_log_files = []
        self.project_id = ""
        self.extend_file = [] #额外的日志
    def __del__(self):
        self.stop_log()

    def add_custom_log_file(self, abs_file_path):
        self.custom_log_files.append(abs_file_path)
    
    def each_case_log_start(self):
        self.stop_log()
        '''
        if self.platform=="ios":
            if not os.path.exists("ioslocalcache"):
            #     shutil.rmtree("ioslocalcache")
                os.mkdir("ioslocalcache")
            if os.path.exists(f"ioslocalcache/logbug_{self.task_running_id}_{self.device_s}.txt"):
                os.remove(f"ioslocalcache/logbug_{self.task_running_id}_{self.device_s}.txt")
            # 清理崩溃日志
            os.popen(f'tidevice -u {self.device_s} crashreport -c').read()
            self.buglogios=subprocess.Popen(["tidevice","-u",f"{self.device_s}","syslog"],stdout=open(f'ioslocalcache/logbug_{self.task_running_id}_{self.device_s}.txt',"w"))
            self.bug_log_ios_pid[self.device_s] = self.buglogios.pid'''



    def set_projectId(self,project_id):
        self.project_id = project_id

    def log_updata(self,case,case_run=None,IsLogCheck=False,parameters={},retry_number=None):
        try:
            CheckConnent=""
            self.stop_log()
            print("日志上传ing")
            devices=self.device_s.split(":")[0].replace ('.','') if "10." in self.device_s else self.device_s
            log_filename = f"task{self.task_running_id}_{devices}.txt"
            log_url = f"log_file/{log_filename}"
            # if retry_number:
            #     log_url = self.generate_backup(retry_number,log_url)
            #     self.log_files = [("files", (f"task{self.task_running_id}_{devices}_{retry_number}.txt", open(log_url, "rb")))]
            # else:
            ''''''
            self.log_files = [temp_file for temp_file in self.log_files if log_filename not in temp_file[1]]
            self.log_files.append(("files", (log_filename, open(log_url, "rb"))))
            if len(self.custom_log_files) > 0:
                for custom_log_file in self.custom_log_files:
                    custom_log_filename = os.path.basename(custom_log_file)
                    self.log_files.append(("files", (custom_log_filename, open(custom_log_file, "rb"))))
            start_time=time.localtime()
            filenumname=[9999999999,""]
            nextlog=True
            print(f"parameters:{parameters}")
            print(type(parameters))
            if "performance" in parameters:
                if "video" in parameters["performance"]:
                    print(f"开始上传视频")
                    video_url = f"/root/video/{self.task_running_id}{self.device_name}{case['english_name']}.mp4"
                    if retry_number:
                        video_url = self.generate_backup(retry_number,video_url)
                        self.log_files.append(("files", (f"{self.task_running_id}{self.device_name}{case['english_name']}_backup{retry_number}.mp4", open(video_url, 'rb'))))
                    else:
                        self.log_files.append(("files", (os.path.basename(video_url), open(video_url, 'rb'))))
                    print(f"当前视频存储在{video_url}")

            print(f"平台：{self.platform}")
            '''
            if "android" in self.platform:  
                try:
                    ex = Exception("没有权限")
                    if "No such file or directory" not in os.popen(f"adb -s {self.Android_IOS.devices} shell \"cd /sdcard/Android/data/{self.Android_IOS.package}/files\"").read():
                        dataf=os.popen(f"adb -s {self.Android_IOS.devices} shell \"cd /sdcard/Android/data/{self.Android_IOS.package}/files ; ls -l\"").read().splitlines()[1::]
                    else:
                        raise ex
                    if "Permission denied" in dataf:
                        raise ex
                    print(dataf)
                    if os.path.exists(f"./log_file/logbug_{devices}.txt"):
                        os.remove(f"./log_file/logbug_{devices}.txt")
                    os.popen(f"adb -s \"{self.Android_IOS.devices}\"  shell  \"logcat -d\" > \"./log_file/logbug_{devices}.txt\"")
                    time.sleep(20)
                    os.popen(f"adb -s \"{self.Android_IOS.devices}\"  shell  \"logcat -c\"")
                    logbug_url = f"./log_file/logbug_{devices}.txt"
                    if retry_number:
                        logbug_url = self.generate_backup(retry_number,logbug_url)
                        self.log_files.append(("files", (f'auto_logbug_{self.task_running_id}_backup{retry_number}.log', open(logbug_url, "rb").read())))
                    else:
                        self.log_files.append(("files",(f'auto_logbug_{self.task_running_id}.log', open(logbug_url, "rb").read())))
                    print("测试判断是否到达")
                    try:
                        #获取文件编码
                        source_encoding = self.detect_encoding(f"./log_file/logbug_{devices}.txt")
                        print(f"游戏日志文件编码为{source_encoding}")
                        # 读取 logcat 日志，获取 Crasheye DeviceId
                        with open(f"./log_file/logbug_{devices}.txt", "r", encoding=source_encoding) as f:
                            log_data = f.read()
                            ret = re.search("Crasheye: Device UUID=.*", log_data)
                            if ret is not None:
                                crasheye_device_id = ret.group().split("=")[1]
                                print(f"获取到 crasheye device ID：{crasheye_device_id}")
                        if self.project_id == 'jxsj4':  # 筛选有没有崩溃，有上传崩溃的input文件
                            if self.filter_log_lines(f"./log_file/logbug_{devices}.txt", f"./log_file/input_{devices}",["E CRASH","F DEBUG"]):
                                print("检测到崩溃信息，生成input文件待解析")
                                self.log_files.append(("files", (f"{devices}_{case['name']}_input.log",open(f"./log_file/input_{devices}", "rb").read())))
                                try:
                                    import auto_rebot
                                    bot = auto_rebot.FeiShutalkChatbot([19982294])
                                    bot.send_file_img('file', f"./log_file/input_{devices}")
                                except:
                                    print("发送崩溃文件失败")
                                    print(traceback.format_exc())
                    except:
                        print("读取logcat日志失败，疑似编码问题")
                        print(traceback.format_exc())
                except:
                    print("获取不到设备包名路径下内容,检查连接状态和包名路径")
                    print(traceback.format_exc())
                    nextlog=False

                # 如果是 UE4 项目，获取 Game.log 并上传日志
                if self.Android_IOS.package_info["projectName"] != None:
                    try:
                        Logs = os.popen(f"adb -s {self.device_s} ls /sdcard/UE4Game/{self.Android_IOS.package_info['projectName']}/{self.Android_IOS.package_info['projectName']}/Saved/Logs").read()
                        if "No such file or directory" in Logs:
                            # 没有该文件，直接跳过
                            pass
                        else:
                            if "Game.log" in Logs:
                                # 拉取文件并添加到上传中
                                ret = os.popen(f"adb -s {self.device_s} pull /sdcard/UE4Game/{self.Android_IOS.package_info['projectName']}/{self.Android_IOS.package_info['projectName']}/Saved/Logs/Game.log ./log_file/{self.device_ip}_{case['id']}_Game.log").read()
                                print(ret)
                                gameLog_url = f"./log_file/{self.device_ip}_{case['id']}_Game.log"
                                if retry_number:
                                    gameLog_url = self.generate_backup(retry_number,gameLog_url)
                                    self.log_files.append(("files", (f"{self.device_ip}_{case['id']}_Game_backup{retry_number}.log", open(gameLog_url, "rb").read())))
                                else:
                                    self.log_files.append(("files",(f"{self.device_ip}_{case['id']}_Game.log", open(gameLog_url, "rb").read())))
                    except:
                        traceback.print_exc()


                if nextlog:
                    print(f"进入{nextlog}")
                    pathlog="KGLog"
                    for file in dataf:
                        if file.split(" ")[-1]=="Logs":
                            pathlog=f"Logs/{time.strftime('%Y-%m-%d', start_time)}"
                            break
                        if file.split(" ")[-1]=="logs":
                            if self.project_id == 'jxsj4':
                                pathlog = f"logs/Game/{time.strftime('%Y-%m-%d', start_time)}" #剑侠世界4路径不一样，先修改
                                break
                            elif self.project_id == "jx1pocket" or self.project_id == "jxsjorigin":
                                pathlog = f"logs/Client"
                                break
                    print(f"pathlog->{pathlog}")
                    try:
                        dataf = os.popen(f"adb -s {self.Android_IOS.devices} shell \"cd /sdcard/Android/data/{self.Android_IOS.package}/files/{pathlog}\"").read().splitlines()
                        for text in dataf:
                            if 'file or directory' in text:
                                raise ex
                        dataf=os.popen(f"adb -s {self.Android_IOS.devices} shell \"cd /sdcard/Android/data/{self.Android_IOS.package}/files/{pathlog} ; ls -l\"").read().splitlines()[1::]
                        print(f"dataf->{dataf}")
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
                        result=datalog.stdout.read()
                        if retry_number:
                            self.log_files.append(("files", (f'auto_log_{self.task_running_id}_backup{retry_number}.log', result)))
                        else:
                            self.log_files.append(("files",(f'auto_log_{self.task_running_id}.log', result)))
                        CheckConnent=result
                    except:
                        traceback.print_exc()
                        print(f"安卓端{self.Android_IOS.package}包名log路径错误")
            elif "ios" in self.platform:  
                try:
                    filemoon = os.popen(f"tidevice -u {self.device_s} fsync -B {self.Android_IOS.package} ls /Documents/MallocMon/").read().replace("\n", "").replace("\"", "").replace("'", "\"").split("/")
                    if filemoon:
                        maxIndex=0
                        for index, item in enumerate(filemoon):
                            if item.isdigit() == True:
                                if item > filemoon[maxIndex] or not filemoon[maxIndex].isdigit():
                                    maxIndex = index
                        if os.path.exists("./mooncache"):
                            pass
                        else:
                            os.makedirs("./mooncache")
                        if os.path.exists(f"./mooncache/{devices}_{case['name']}"):
                            pass
                        else:
                            os.makedirs(f"./mooncache/{devices}_{case['name']}")
                        print(maxIndex)
                        print(filemoon[maxIndex])
                        os.popen(f"tidevice -u {devices} fsync -B {self.Android_IOS.package} pull /Documents/MallocMon/{filemoon[maxIndex]} ./mooncache/{devices}_{case['name']}").read()
                except Exception as e:
                    print(e)
                    pass
                tideviceonce=tidevice.Device(devices)
                dataf=tideviceonce.app_sync(self.Android_IOS.package).listdir("/Documents")
                logPath="/Documents/KGLog"
                for file in dataf:
                    if file=="Logs":
                        logPath=f"/Documents/Logs/{time.strftime('%Y-%m-%d', start_time)}"
                        break
                """获取ios机型最新的log"""
                fileList=[]
                try:
                    # 拉取崩溃日志和压缩
                    crashreport_dir = f"crashreport_{self.task_running_id}_{self.device_s}"
                    print(os.popen(f'tidevice -u {self.device_s} crashreport -k {crashreport_dir}').read())
                    
                    zip = zipfile.ZipFile(f"ioslocalcache/crashreport_{self.task_running_id}_{self.device_s}.zip", "w", zipfile.ZIP_DEFLATED)
                    for path, dirnames, filenames in os.walk(crashreport_dir):
                        fpath = path.replace(crashreport_dir, "")
                        for filename in filenames:
                            zip.write(os.path.join(path, filename), os.path.join(fpath, filename))
                    zip.close()
                    if os.path.exists(crashreport_dir):
                        shutil.rmtree(crashreport_dir)
                    else:
                        print(f"{crashreport_dir}不存在，不能rmtree")

                    zip_url = f"ioslocalcache/crashreport_{self.task_running_id}_{self.device_s}.zip"
                    if retry_number:
                        self.generate_backup(retry_number,zip_url)
                        self.log_files.append(("files", (f"crashreport_{self.task_running_id}_{self.device_s}_backup{retry_number}.zip",open(zip_url,"rb").read())))
                    else:
                        self.log_files.append(("files",(f"crashreport_{self.task_running_id}_{self.device_s}.zip", open(zip_url, "rb").read())))

                    logbug_url = f'ioslocalcache/logbug_{self.task_running_id}_{self.device_s}.txt'
                    logbug_url_utf = self.convert_file_encoding(logbug_url, 'utf-8')
                    if retry_number:
                        logbug_url_utf = self.generate_backup(retry_number,logbug_url_utf)
                        self.log_files.append(("files", (f'auto_logbug_{self.task_running_id}_backup{retry_number}.log', open(logbug_url_utf, "rb").read())))
                    else:
                        self.log_files.append(("files",(f'auto_logbug_{self.task_running_id}.log', open(logbug_url_utf, "rb").read())))
                    fileList = tideviceonce.app_sync(self.Android_IOS.package).listdir(logPath)
                except:
                    print("ios获取log错误，检查log路径")
                    print(traceback.format_exc())
                    #traceback.print_exc()


                # 如果是 UE4 项目，获取 Game.log 并上传日志
                if self.Android_IOS.package_info["projectName"] != None:
                    
                    try:
                        #将ios的log日志全部提取压缩并上传
                        check_file = tideviceonce.app_sync(self.Android_IOS.package).listdir(f"/Documents/{self.Android_IOS.package_info['projectName']}/Saved")
                        print(f"log日志压缩调试：\n\t路径：/Documents/{self.Android_IOS.package_info['projectName']}/Saved\n\t内容：{check_file}")
                        if 'Logs' in check_file:
                            file_list = tideviceonce.app_sync(self.Android_IOS.package).listdir(f"/Documents/{self.Android_IOS.package_info['projectName']}/Saved/Logs")
                            print(f"log日志压缩调试：\n\t路径：/Documents/{self.Android_IOS.package_info['projectName']}/Saved/Logs\n\t内容：{file_list}")
                            try:
                                # file_list.pop()
                                for i in file_list:
                                    if not os.path.exists(f"./log_file/{self.device_ip}_{case['english_name']}_Game"):
                                        os.makedirs(f"./log_file/{self.device_ip}_{case['english_name']}_Game")
                                    # i = i.split()[1]
                                    print(f"添加文件{i}")
                                    print(tideviceonce.app_sync(self.Android_IOS.package).pull(f"/Documents/{self.Android_IOS.package_info['projectName']}/Saved/Logs/{i}",f"./log_file/{self.device_ip}_{case['english_name']}_Game/{i}"))
                                    

                                # # 定义文件夹路径
                                folder_path = f"./log_file/{self.device_ip}_{case['english_name']}_Game"
                                # 定义压缩包名称和格式
                                zip_name = f"./log_file/{self.device_ip}_{case['english_name']}_Game"
                                # 压缩文件夹
                                shutil.make_archive(zip_name, 'zip', folder_path)
                                # 删除原有的文件夹
                                shutil.rmtree(folder_path)

                                game_url = f"./log_file/{self.device_ip}_{case['english_name']}_Game.zip"
                                if retry_number:
                                    game_url = self.generate_backup(retry_number,game_url)
                                    self.log_files.append(("files", (f"{self.device_ip}_{case['english_name']}_Game_backup{retry_number}.zip", open(game_url, "rb").read())))
                                else:
                                    self.log_files.append(("files", (f"{self.device_ip}_{case['english_name']}_Game.zip",open(game_url,"rb").read())))
                            except:
                                print('游戏启动后无log日志')



                    except:
                        traceback.print_exc()

                if nextlog:
                    maxIndex = 0
                    try:
                        print("输出fileList")
                        print(fileList)
                        replacedFilelist = [file.replace("-", "").replace("_","").replace(".log", "") for file in fileList]
                        print(replacedFilelist)
                        print("输出replacedFilelist")
                        print(replacedFilelist)
                        for index, item in enumerate(replacedFilelist):
                            item=fileList[maxIndex]
                            if item.isdigit() == True:
                                if item > replacedFilelist[maxIndex] or not replacedFilelist[maxIndex].isdigit():
                                    maxIndex = index
                    except:
                        print("获取游戏日志异常")
                        traceback.print_exc()

                    try:
                        if os.path.exists("./ioslocalcache"):
                            pass
                        else:
                            try:
                                os.makedirs("./ioslocalcache")
                            except:
                                traceback.print_exc()
                        print(maxIndex)
                        if len(fileList) > 0:
                            print("输出fileList[maxIndex]")
                            print(fileList[maxIndex])
                            with open(f"./ioslocalcache/{int(time.mktime(start_time))}_{devices}.txt", "wb+") as f:
                                f.write(tideviceonce.app_sync(self.Android_IOS.package).pull_content(
                                    f"{logPath}/{fileList[maxIndex]}"))
                        if os.path.exists(f"./ioslocalcache/{int(time.mktime(start_time))}_{devices}.txt"):
                            with open(f"./ioslocalcache/{int(time.mktime(start_time))}_{devices}.txt", "r") as f:
                                CheckConnent=f.read()
                        else:
                            print(f"ioslocalcache下没有创建对应的日志信息")


                        # 调整IOS系统日志上传 游戏日志
                        # logbug_url = f"./ioslocalcache/logbug_{self.task_running_id}_{devices}.txt"
                        if os.path.exists(f"./ioslocalcache/{int(time.mktime(start_time))}_{devices}.txt"):
                            logbug_url = f"./ioslocalcache/{int(time.mktime(start_time))}_{devices}.txt"
                            logbug_url_utf = self.convert_file_encoding(logbug_url, 'utf-8')
                            if retry_number:
                                logbug_url_utf = self.generate_backup(retry_number,logbug_url_utf)
                                self.log_files.append(("files", (f'auto_log_{self.task_running_id}_backup{retry_number}.log', open(logbug_url_utf, "rb").read())))
                            else:
                                self.log_files.append(("files",(f'auto_log_{self.task_running_id}.log', open(logbug_url_utf, "rb").read())))
                        else:
                            print(f"ios游戏日志获取失败")
                    except:
                        traceback.print_exc()
                        print("ios tidevice模块异常")
            '''

            if self.extend_file:
                for file in self.extend_file:
                    file_name = file.get('save_file')
                    save = file.get('save')
                    if os.path.exists(file_name):
                        self.log_files.append(("files", (os.path.basename(file_name), open(file_name, "rb").read())))
                        if not save:
                            os.remove(file_name)
                    else:
                        print(f"Error: File {file} does not exist")

            # 改为直接上传到S3
            # 先获取预授权地址
            try:
                file_list = [item[1][0] for item in self.log_files]
                print(f"logfiles_object:{file_list}")
                response = requests.post(f"{self.server_url}/build/logs/upload/log/presigned", json = {
                    "buildId": self.task_running_id,
                    "deviceId": self.device_id,
                    "caseId": case["id"],
                    "buildCaseId": case["build_case_id"],
                    "files": file_list
                })
                if response.status_code != 200 or response.json()["code"] != 0:
                    raise Exception(f"获取预授权地址失败: {response.content}")
                presigned_url_map = response.json()["data"]
                for item in self.log_files:
                    file_params = item[1]
                    presigned_url = presigned_url_map.get(file_params[0], None)
                    if presigned_url == None:
                        logger.error(f"{file_params[0]}, 服务器未返回预授权地址!")
                        raise Exception(f"{file_params[0]}, 服务器未返回预授权地址!")
                    response = requests.put(presigned_url, data=file_params[1])
            except Exception as e:
                # 失败改为旧上传方式
                logger.info(f"日志上传S3失败: {e}, 将直接上传至服务器")
                response = requests.post(f"{self.server_url}/build/logs/upload/logfile", files=self.log_files, data={
                        "buildId": self.task_running_id,
                        "deviceId": self.device_id,
                        "caseId": case["id"],
                        "buildCaseId": case["build_case_id"]
                        })
            finally:
                # close file handler
                for item in self.log_files:
                    try:
                        item[1][1].close()
                    except:
                        pass
                # clear custom log file
                for custom_log_file in self.custom_log_files:
                    try:
                        os.remove(custom_log_file)
                    except:
                        pass
                self.custom_log_files = []

            print(f"日志上传成功：IsLogCheck->{IsLogCheck}")
            #if IsLogCheck and case_run!=None:
                #case_run.LogCheck(CheckConnent,parameters)
            print(response.content)
        except:
            print("日志上传出错：")
            traceback.print_exc()
    def stop_log(self):
        if self.buglogios:
            self.buglogios.kill()
            self.buglogios=None
            self.bug_log_ios_pid.pop(self.device_s)

    def generate_backup(self,number,file_url,backup_url='/root/task_controller/log_file/backup'):
        file_name, file_ext = os.path.splitext(os.path.basename(file_url))
        backup_file_name = file_name + "_backup" + str(number) + file_ext
        backup_file_path = os.path.join(backup_url, backup_file_name)
        if not os.path.exists(backup_url):
            os.makedirs(backup_url)
        shutil.copyfile(file_url, backup_file_path)
        print(f"案例第{number}次失败 已重新构建新日志 -> {backup_file_path}")
        return backup_file_path

    def detect_encoding(self,filepath):
        with open(filepath, 'rb') as file:
            raw_data = file.read()
        result = chardet.detect(raw_data)
        return result['encoding']

    def convert_file_encoding(self, filepath, target_encoding = 'utf-8'):
        try:
            source_encoding = self.detect_encoding(filepath)
            print(f"{filepath} 的编码是 {source_encoding}")
            if not source_encoding:
                return filepath
            with open(filepath, 'r', encoding=source_encoding) as file:
                content = file.read()
            content = content.replace('\r\n', '\n').replace('\r', '\n')
            with open(filepath, 'w', encoding=target_encoding,  errors='replace', newline='') as file:
                file.write(content)
            return filepath
        except UnicodeDecodeError as e:
            print(f"Unicode decode error: {e}")
            raise
        except Exception as e:
            print(f"An error occurred: {e}")
            raise

    def filter_log_lines(self, input_filepath, output_filepath, keywords):  # 剑世4获取崩溃分析input文件
        try:
            # 检测输入文件的编码
            source_encoding = self.detect_encoding(input_filepath)
            print(f"编码为: {source_encoding}")
            matching_lines = []
            # 以检测到的编码模式读取文件
            with open(input_filepath, 'r', encoding=source_encoding) as infile:
                for line in infile:
                    for keyword in keywords:
                        if keyword in line:
                            # 移除前缀，只保留关键内容
                            content = line.split(f"{keyword}   : ")[1]
                            matching_lines.append(content)
                            break  # 遇到第一个匹配的关键词就跳出内层循环
            if matching_lines:
                # 将匹配的行写入输出文件
                with open(output_filepath, 'w', encoding='utf-8') as outfile:
                    for line in matching_lines:
                        outfile.write(line)
                print(f"成功生成新的日志文件：{output_filepath}")
                return True
            return False
        except Exception as e:
            print(f"An error occurred: {e}")
            return False

    def add_extend_file(self,save_file,save=True):
        self.extend_file.append({'save_file':save_file,'save':save})

if __name__ == '__main__':
    import os
    data_path = '/sdcard/Android/data/com.jxsj3.branch.dev/files/Memory-52751.snap'
    bendi = r'C:\Users\Kingsoft\Desktop\fsdownload'
    cmd = f"adb pull {data_path} {bendi}"
    os.popen(cmd)
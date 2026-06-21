import datetime
import importlib
import multiprocessing
import os
import sys
import time
import traceback
import zipfile
import requests

import ad_ios
import screen_recording
#from ad_ios import install_verify
#from ad_ios import Android_IOS as AdIo
import gpu_temp
import auto_rebot
import tp.TPlus
import record_android_trace
import json
import random

def get_Proflie_module(project_file_lock):
    with project_file_lock:
        importlib.invalidate_caches()
        module_path = os.getcwd()
        module_path = os.path.join(module_path, "UAutoProfilerTool")

        print(module_path)
        sys.path.append(module_path)
        module_path2 = os.path.join(module_path, "minicap")
        sys.path.append(module_path2)

        module = importlib.import_module('Profile_test_new2')

        sys.path.remove(module_path)
        sys.path.remove(module_path2)
        return module
def get_UE4_Proflie_module(project_file_lock):
    with project_file_lock:
        importlib.invalidate_caches()
        module_path = os.getcwd()
        module_path = os.path.join(module_path, "UAutoProfilerTool")

        print(module_path)
        sys.path.append(module_path)
        module_path2 = os.path.join(module_path, "minicap")
        sys.path.append(module_path2)

        module = importlib.import_module('Profile_UE')

        sys.path.remove(module_path)
        sys.path.remove(module_path2)
        return module
    
def get_minicap_module(project_file_lock):
    with project_file_lock:
        importlib.invalidate_caches()
        module_path = os.getcwd()
        module_path = os.path.join(module_path, "UAutoProfilerTool", "minicap")

        print(module_path)
        sys.path.append(module_path)
        module = importlib.import_module('minicap_new')
        
        sys.path.remove(module_path)
        return module
#自动化ubox采集
class ubox_custom(object):
    def __init__(self,ProfCus,case_name,bot,device_name,package_name,package_version):
        self.Prof=ProfCus
        self.isrun=False
        self.case_name=case_name
        self.bot=bot
        self.report_data={}
        self.device_name=device_name
        self.package_name=package_name
        self.package_version=package_version
    def __del__(self):
        self.capture_ubox_stop(False)
    def capture_ubox_start(self):
        self.Prof.RunProfile()
        self.isrun=True
    def capture_ubox_stop(self,save=True):
        if self.isrun:
            self.Prof.StopProfile()
            time.sleep(3)
            switch={
                "casename":self.case_name,
                "save":False,
                "upload":save,
                "type":"ordinary",
                "shiled":0
                }
            ret=self.Prof.checkProfile(switch)
            if ret != None and save:
                self.report_data["Profile"] = ret["uuid"]
            self.bot.send_text(f"{self.device_name} Profile 深度采集结束: {ret}")
            self.isrun=False
        return self.report_data
    def set_casename(self,newname):
        self.case_name=newname
    def get_packagename(self):
        return self.package_name
    def get_packageversion(self):
        return self.package_version
class CapTure(object):
    def __init__(self, task_process_instance, parameters,task_data,Android_IOS:ad_ios.Android_IOS,perfeyedevice_s,device_ip,bot:auto_rebot.FeiShutalkChatbot,device_name,project_id,project_file_lock,task_running_id,case_name,task_parameters,case,platform,screenshottime=2):
        self.parameters=parameters
        self.task_data=task_data
        self.platform=platform
        self.Android_IOS=Android_IOS
        if self.Android_IOS:
            self.bMobile=True
            self.device_s = Android_IOS.devices
            self.perfeyedevice_s = perfeyedevice_s
        else:
            self.bMobile=False
            #self.device_s = perfeyedevice_s
            self.device_s=perfeyedevice_s
            self.perfeyedevice_s='localhost' #pc端 perfeyedevice_s填localhost

        self.device_ip=device_ip
        self.bot=bot
        self.device_name=device_name
        self.device_quality=parameters["quality"]
        self.project_id=project_id
        self.project_file_lock=project_file_lock
        self.task_running_id=task_running_id
        self.case_name=case_name
        self.task_parameters=task_parameters
        self.isrun=False
        self.report_data = {}
        self.performance = {}
        self._task_process_instance = task_process_instance
        self.screenshottime=screenshottime
        self.case = case
    #初始化采集
    def start_capture(self, udriver,package_name):
        try:
            self.udriver = udriver
            self.timestart=datetime.datetime.now()
            #默认采集perfeye数据
            # 开始采集
            if "performance" in self.parameters.keys():
                collect_type = self.parameters["performance"]
                self.isrun=True
                print("performance存在")
                #print("performance存在-ttttttttttttttttttt")
                # perfeye 采集
                if "perfeye" in collect_type:
                    # 检查是否有 appKey
                    if not "appKey" in self.parameters.keys():
                        raise KeyError("缺少参数 appKey，无法进行 perfeye 采集")
                        # bot.send_text("缺少参数 appKey，无法进行 perfeye 采集")
                    self.task_data["appKey"] = self.parameters["appKey"]
                    if "android" in self.platform:
                        try:
                            self.Android_IOS.WDA_U2.watcher('allow_tp').when('允许').click()#自动点击系统弹窗,游戏可能会弹出什么提示
                            self.Android_IOS.WDA_U2.watcher('allow_tp').when('是').click()#自动点击系统弹窗,游戏可能会弹出什么提示
                            self.parameters["WDA_U2"].find_click("无限制")#自动点击系统弹窗,无限制电池优化
                        except Exception as e:
                            pass
                    #采集数据类型载入，任务参数的优先级高于设备参数
                    defdata=None
                    if "data_types" in self.parameters["devices_custom"]:
                        defdata=self.parameters["devices_custom"]["data_types"]
                    if type(collect_type)==list:
                        collect_type={k:{} for k in collect_type}
                        if defdata:
                            collect_type["perfeye"]["data_types"]=defdata
                        else:
                            collect_type["perfeye"]={"data_types":[8, 5, 12, 1, 14, 9, 3, 6, 33, 32, 2, 34, 35, 36,17,4,10,11,23,24,25]}
                    elif type(collect_type)==dict and "data_types" not in collect_type["perfeye"].keys():
                        if defdata:
                            collect_type["perfeye"]["data_types"]=defdata
                        else:
                            collect_type["perfeye"]["data_types"]=[8, 5, 12, 1, 14, 9, 3, 6, 33, 32, 2, 34, 35, 36,17,4,10,11,23,24,25]
                    from extensions import logger
                    module=importlib.reload(tp.TPlus)
                    perfeyeID=None
                    if self.project_id == 'JX3' or self.project_id == 'JX3CLASSIC':
                        import platform
                        os_version = platform.platform().lower()
                        if 'windows-7' in os_version:
                            Perfeye_ver = 'Perfeye-2.1.11-release'
                        else:
                            Perfeye_ver = 'Perfeye-2.3.1-release'
                    else:
                        Perfeye_ver = 'Perfeye-2.1.11-release'
                        # 无界 ios17|18 用新版本perfeye
                        if self.platform=='ios':
                            osVersion=self.case["osVersion"].split(".")[0]
                            if osVersion=='17' or osVersion=='18':
                                Perfeye_ver = 'Perfeye-3.1.1-release'
                                perfeyeID=self.Android_IOS.devices
                    perfeye = module.Perfeye(Perfeye_ver,perfeyeID)
                    logger.info(perfeye)
                    print(perfeye)
                    #tpt通信端口（perfeye采集端口）初始化
                    nowport=0
                    nowport=self._task_process_instance.call_event("new_perfeye_port") # 获取新的perfeye端口
                    #怀疑端口复用导致采集数据异常
                    #nowport= random.randint(10000, 60000)

                    logger.info(f"{self.device_s} 初始化采集 perfeye success  -1")
                    perfeye.set_platform(self.platform)  # 设置平台判断
                    logger.info(f"{self.device_s} 初始化采集 perfeye success  -11")
                    dic_perfeyeInitParam = {}
                    dic_perfeyeInitParam['data_types'] = collect_type["perfeye"]["data_types"]
                    # dx11=11;dx12=12;vulkan=0
                    if self.project_id == 'JX3' or self.project_id == 'JX3CLASSIC':
                        graphics_api = 11
                    else:
                        graphics_api = 0
                    dic_perfeyeInitParam['dic_configs'] = {'graphics_api': graphics_api,"old_jank_counter": False}
                    perfeye.PreInit(self.perfeyedevice_s, nowport, package_name, dic_perfeyeInitParam)  # TODO 完善端口分配功能

                    # perfeye电池优化权限解除
                    #logger.info(f"{self.device_s} 初始化采集 perfeye success  -1111")
                    try:
                        if "android" in self.platform:
                            time.sleep(3)
                            self.parameters["WDA_U2"].find_click("无限制")  # 自动点击系统弹窗,无限制电池优化
                            self.Android_IOS.WDA_U2.watcher('allow_tp').when('允许').click()  # 自动点击系统弹窗,游戏可能会弹出什么提示
                            self.Android_IOS.WDA_U2.watcher('allow_tp').when('是').click()  # 自动点击系统弹窗,游戏可能会弹出什么提示
                    except:
                        print("点击权限无限制有些问题")
                        pass
                    logger.info(f"{self.device_s} 初始化采集 perfeye success  0")
                    # perfeye 使用 subprocess，当多进程被杀掉，无法自动关闭 perfeye 的子进程，将 perfeye 返回给父进程进行关闭
                    self.task_data["perfeye"] = perfeye.GetPid()

                    self.performance["perfeye"] = perfeye
                    logger.info(f"{self.device_s} 初始化采集 perfeye success  1")

                    # bot.send_text(f"{device_s} 开始采集 perfeye")
                    print(f"{self.device_s} 初始化采集 perfeye")

                    times = 25
                    # if self.device_s=="e755fd8d":
                    #     times=30

                    tpstr = self.timestart.utcnow().strftime("%Y-%m-%d %H:%M:%S")#str类型的时间
                    tm = time.strptime(tpstr, '%Y-%m-%d %H:%M:%S')#转为时间结构体
                    timeStamp = float(time.mktime(tm))# 转为时间戳
                    if "android" in self.platform:
                        while True:
                            try:
                                self.Android_IOS.WDA_U2.watcher.run()
                            except Exception as e:
                                pass
                            times -= 1
                            if times == 0:
                                print("有弹窗,等待了---",time.time()-timeStamp)
                                break
                            else:
                                time.sleep(0.5)
                    
                    self.performance["perfeye"] = perfeye
                    logger.info(f"{self.device_s} 初始化采集 perfeye success 2")

                # gpu 温度采集
                if "gpu_temp" in collect_type:
                    gpuTemp = gpu_temp.GPUTemp(self.device_ip, f"{self.case_name}({self.device_s})")
                    
                    # gpuTemp.start_capture()
                    battery=self.Android_IOS.get_battery()
                    self.bot.send_text(f"{self.device_name} 电量剩余 {battery}; 初始化采集 gpu_temp")
                    self.performance["gpuTemp"] = gpuTemp

                # gpu 使用详情采集
                if "perfetto" in collect_type:
                    perfetto = record_android_trace.Perfetto(self.device_s, f"{self.case_name}({self.device_s})")
                    # perfetto.start()
                    self.bot.send_text(f"{self.device_name} 初始化采集 perfetto")
                    self.performance["perfetto"] = perfetto

                #深度采集 ubox不是深采，不是深采
                if "Profile" in collect_type:
                    print("进入profile判断")
                    if self.Android_IOS.package_info["projectName"] == "" or self.Android_IOS.package_info["projectName"] == None:
                        gpath = os.path.abspath(os.path.join(os.getcwd(), "..", "files"))
                        collection = {}
                        if type(collect_type) == dict and collect_type["Profile"] != {}:
                            collection = {'ubox': {'path': gpath}}
                            if "resource" in collect_type["Profile"]:
                                collection["resource"] = {'ip': '', 'density': 150}
                            if "custom" in collect_type["Profile"]:
                                collection["custom"] = {}
                        else:
                            collection = {'ubox': {'path': gpath}, 'resource': {'ip': '', 'density': 150}, 'custom': {}}
                        tag = "uauto-daily"
                        GC_Alloc_switch = "0"
                        if "GC_Alloc" in collect_type["Profile"] and str(collect_type["Profile"]["GC_Alloc"]) == "1":
                            print("开启GC.Alloc")
                            GC_Alloc_switch = "1"
                            tag = "uauto-daily_GCAlloc"
                        parameter = {
                            'u3driver': udriver,
                            'device': self.device_s,
                            'device_ip': self.device_ip,
                            "quality": self.device_quality,
                            "platform": self.platform,
                            "package": self.Android_IOS.package,
                            "appkey": self.Android_IOS.appkey,
                            "project_id": self.project_id,
                            # "tag": "uauto-daily",
                            "tag": tag,
                            "switch": True,
                            "gameversion": self.Android_IOS.versionName,
                            "feil_path": gpath,
                            # "collection":{'ubox': {'path': gpath}, 'resource': {'ip': '', 'density': 15}, 'custom': {}}
                            "collection": collection,
                            "GC_Alloc_switch": GC_Alloc_switch
                        }
                        # 重新导入Profile_test 模块
                        Profile_test = get_Proflie_module(self.project_file_lock)
                        Prof = Profile_test.Profile(parameter)
                        # Prof.RunProfile()
                        self.bot.send_text(f"{self.device_s} 初始化深度采集 Profile")

                        self.performance["Prof"] = Prof
                        if self.platform == 'android':
                            if not self.Android_IOS.FindIPA_APK("com.netease.nie.yosemite"):
                                self.Android_IOS.WDA_U2.app_install("http://10.11.145.195/uauto/Yosemite.apk",
                                                                    installing_callback=ad_ios.install_verify)
                elif "UboxCustom" in collect_type:
                    gpath= os.path.abspath(os.path.join(os.getcwd(), "..","files"))
                    collection={'ubox': {'path': gpath}}
                    if "resource" in collect_type["UboxCustom"]:
                        collection["resource"]={'ip': '', 'density': 150}
                    if "custom" in collect_type["UboxCustom"]:
                        collection["custom"]={}
                    parameter={
                        'u3driver':udriver,
                        'device':self.device_s,
                        'device_ip':self.device_ip,
                        "quality":self.device_quality,
                        "platform":self.platform,
                        "package":self.Android_IOS.package,
                        "appkey":self.Android_IOS.appkey,
                        "project_id":self.project_id,
                        "tag":"uauto-daily",
                        "switch":True,
                        "gameversion":self.Android_IOS.versionName,
                        "feil_path":gpath,
                        # "collection":{'ubox': {'path': gpath}, 'resource': {'ip': '', 'density': 15}, 'custom': {}}
                        "collection":collection
                    }
                    #重新导入Profile_test 模块
                    Profile_test=get_Proflie_module(self.project_file_lock)
                    Prof=Profile_test.Profile(parameter)
                    # Prof.RunProfile()
                    # self.bot.send_text(f"{self.device_s} 初始化深度采集 Profile")
                    self.report_data["appkey"] = self.Android_IOS.appkey
                    self.performance["ProfCustom"] = Prof
                    if self.platform =='android':
                        if not self.Android_IOS.FindIPA_APK("com.netease.nie.yosemite"):
                            self.Android_IOS.WDA_U2.app_install("http://10.11.145.195/uauto/Yosemite.apk",installing_callback=ad_ios.install_verify)
                # UE4 Insight 采集
                if "insight" in collect_type and self.Android_IOS.package_info["projectName"] != None: 
                    
                    gpath= os.path.abspath(os.path.join(os.getcwd(), "..","files"))
                    collection={'ubox': {}}
                    if "custom" in collect_type["insight"]:
                        collection["custom"] = collect_type["insight"]["custom"]
                    parameter={
                        'u3driver':udriver,
                        'device':self.device_s,
                        'device_ip':self.device_ip,
                        "quality":self.device_quality,
                        "platform":self.platform,
                        "package":self.Android_IOS.package,
                        "appkey":self.Android_IOS.appkey,
                        "project_id":self.project_id,
                        "tag":"uauto",
                        "switch":True,
                        "gameversion":self.Android_IOS.versionName,
                        "feil_path":gpath,
                        # "collection":{'ubox': {'path': gpath}, 'resource': {'ip': '', 'density': 15}, 'custom': {}}
                        "collection":collection
                    }

                    Profile_UE4=get_UE4_Proflie_module(self.project_file_lock)
                    Insight=Profile_UE4.Profile(parameter)
                    self.performance["Insight"] = Insight

                # UE4 LLM 采集
                if "LLM" in collect_type and self.Android_IOS.package_info["projectName"] != None:
                    if not "Insight" in self.performance.keys():
                        gpath= os.path.abspath(os.path.join(os.getcwd(), "..","files"))
                        collection={}
                        parameter={
                            'u3driver':udriver,
                            'device':self.device_s,
                            'device_ip':self.device_ip,
                            "quality":self.device_quality,
                            "platform":self.platform,
                            "package":self.Android_IOS.package,
                            "appkey":self.Android_IOS.appkey,
                            "project_id":self.project_id,
                            "tag":"uauto",
                            "switch":True,
                            "gameversion":self.Android_IOS.versionName,
                            "feil_path":gpath,
                            # "collection":{'ubox': {'path': gpath}, 'resource': {'ip': '', 'density': 15}, 'custom': {}}
                            "collection":collection
                        }

                        Profile_UE4=get_UE4_Proflie_module(self.project_file_lock)
                        Insight=Profile_UE4.Profile(parameter)
                        self.performance["Insight"] = Insight
                
                # UE4 memreport 采集
                if "memreport" in collect_type and self.Android_IOS.package_info["projectName"] != None:
                    if not "Insight" in self.performance.keys():
                        gpath= os.path.abspath(os.path.join(os.getcwd(), "..","files"))
                        collection={}
                        parameter={
                            'u3driver':udriver,
                            'device':self.device_s,
                            'device_ip':self.device_ip,
                            "quality":self.device_quality,
                            "platform":self.platform,
                            "package":self.Android_IOS.package,
                            "appkey":self.Android_IOS.appkey,
                            "project_id":self.project_id,
                            "tag":"uauto",
                            "switch":True,
                            "gameversion":self.Android_IOS.versionName,
                            "feil_path":gpath,
                            # "collection":{'ubox': {'path': gpath}, 'resource': {'ip': '', 'density': 15}, 'custom': {}}
                            "collection":collection
                        }

                        Profile_UE4=get_UE4_Proflie_module(self.project_file_lock)
                        Insight=Profile_UE4.Profile(parameter)
                        self.performance["Insight"] = Insight
                
                # Minicap 自定义截图采集
                if "minicap" in collect_type:
                    minicap = get_minicap_module(self.project_file_lock)
                    if "android" in self.platform:
                        Platf = minicap.Platform.ANDROID
                    elif "ios" in self.platform:
                        Platf = minicap.Platform.IOS
                    else:
                        Platf = minicap.Platform.PC
                    
                    minicap_data = []
                    def save_picture_callback(output_file):
                        minicap_data.append(output_file)
                        
                    gpath= os.path.abspath(os.path.join(os.getcwd(), "..","files"))
                    gpath = os.path.abspath(os.path.join(gpath, f"{self.task_running_id}_{self.device_ip}_{self.case_name}"))

                    interval = 2
                    if "interval" in collect_type["minicap"]:
                        interval = collect_type["minicap"]["interval"]
                    
                    Minicap = minicap.MiniCap(Platf,self.device_s,save_picture_callback,gpath,self.Android_IOS.package,interval)
                    
                    self.performance["Minicap"] = Minicap
                    self.performance["minicap_data"] = minicap_data

                if "video" in collect_type:
                    if not 'level' in self.parameters:
                        # self.parameters['level'] = self.case_name
                        self.runner = screen_recording.screen_recording(self.task_running_id,self.device_name,self.platform,self.device_s,self.case['english_name'],self.Android_IOS.WDA_U2)
                        self.parameters['video_transcribe'] = {"start": self.runner.start_video, "stop": self.runner.stop_video}
                return self.performance
            # 其他采集
            else:
                self.bot.send_text(f"performance不在self.parameters.keys()")
                print("performance不在self.parameters.keys()")

        except Exception as e:

            print(f"start_capture error: {e}, {traceback.format_exc()}")
            self.bot.send_text(f"{self.device_name}-{self.device_s}  采集初始化失败")
            self.bot.send_text(traceback.format_exc())
    #校验采集参数
    def chance_channel(self,channel):
        try:

            # 开始采集
            if "performance" in self.parameters.keys():
                collect_type = self.parameters["performance"]

                # 选定 采集参数
                if channel in collect_type:
                    return True
                else:
                    return False
        except Exception as e:

            self.bot.send_text(f"{self.device_name}-{self.device_s}  采集初始化失败")
            self.bot.send_text(traceback.format_exc())
            return False


     #开始采集       
    #开始采集
    def all_run_capture(self):
        try:
            if "performance" in self.parameters.keys():
                collect_type = self.parameters["performance"]

                # perfeye 采集
                if "perfeye" in collect_type and "perfeye" in self.performance:
                    
                    # 把打点函数通过参数传给案例，以便案例可以控制采集添加打点
                    self.parameters["perfeye_add_label"] = self.performance["perfeye"].Label

                    # TODO 参数可配置
                    self.perfeyesuccessd=True
                    perfeye = self.performance["perfeye"]
                    #perfeye.Start(self.screenshottime) # TODO 动态包名
                    if self.bMobile:
                        perfeye.set_Paramter(f'{self.case_name}(' + self.device_s + ')', scenes=self.case_name,
                                         picture_quality=self.device_quality,
                                         appKey=self.parameters["appKey"],
                                         version=self.Android_IOS.package_info["versionName"],
                                         parameters=self.parameters, Android_IOS=self.Android_IOS)
                    else:
                        perfeye.set_Paramter(f'{self.case_name}(' + self.device_s + ')', scenes=self.case_name,
                                             picture_quality=self.device_quality,
                                             appKey=self.parameters["appKey"],
                                             version='1.0.0',
                                             parameters=self.parameters)

                    #self.parameters["Add_Label"]=perfeye.Labels
                    #self.parameters["WDA_U2"].find_click("无限制")
                    self.timestart=datetime.datetime.now()

                    if "need_extra_data" in collect_type["perfeye"] and collect_type["perfeye"]["need_extra_data"] == 1:
                        self.udriver.custom_interface('callGM', '功能', '调试', 'Perfeye自定义数据', json.dumps(['1']))
                        time.sleep(10)

                # gpu 温度采集
                if "gpu_temp" in collect_type:
                    gpuTemp=self.performance["gpuTemp"]
                    gpuTemp.start_capture()

                # gpu 使用详情采集
                if "perfetto" in collect_type:
                    perfetto = self.performance["perfetto"]
                    perfetto.start()

                #深度采集
                if "Profile" in collect_type and "Prof" in self.performance:
                    Prof = self.performance["Prof"]
                    Prof.RunProfile()

                # UE4 Insight 采集
                if "insight" in collect_type and "Insight" in self.performance:
                    Insight = self.performance["Insight"]
                    Insight.RunProfile()
                
                # UE4 LLM 采集
                if "LLM" in collect_type and "LLM" in self.performance:
                    # 当前使用引擎内置的 LLM 进行采集，后续插件更新好后才需要操作
                    pass

                # UE4 memreport 采集
                if "memreport" in collect_type and "memreport" in self.performance:
                    # 当前使用案例内部的编写的 memreport 采集
                    pass
                
                # Minicap 自定义截图采集
                if "minicap" in collect_type:
                    # 把打点函数通过参数传给案例，以便案例可以控制采集添加打点
                    self.parameters["minicap_set_tag"] = self.performance["Minicap"].set_tag
                    Minicap = self.performance["Minicap"]
                    Minicap.start()

                if "video" in collect_type:
                    self.runner.start_video()
        except Exception as e:
            info=traceback.format_exc()
            print(f"all_run_capture error:{info}")
            self.bot.send_text(f"{self.device_name}-{self.device_s} 采集开始失败")
            self.bot.send_text(info)

    #析构方法，释放资源
    def __def__(self):

        self.stop_capture_in_run(False)
    #停止采集
    def stop_capture(self, case_status,save = True):
        # 停止采集
        try:
            if self.isrun and "performance" in self.parameters.keys():
                collect_type = self.parameters["performance"]
                oldcasename=self.case_name
                self.case_name=case_status.casename if case_status.casename!="" else self.case_name
                # perfeye 采集
                if "perfeye" in collect_type and "perfeye" in self.performance:
                    if "need_extra_data" in collect_type["perfeye"] and collect_type["perfeye"]["need_extra_data"] == 1:
                        self.udriver.custom_interface('callGM', '功能', '调试', 'Perfeye自定义数据', json.dumps(['0']))
                        time.sleep(30)
                    # TODO 参数可配置
                    perfeye = self.performance["perfeye"]
                    ret=None
                    data=None

                    do_upload = save
                    print(self.parameters)
                    if type(collect_type) == dict:
                        if "save" in collect_type["perfeye"]:
                            if collect_type["perfeye"]["save"] == 0:
                                print("perfeye 参数设置为该数据不标记为每日数据")
                                do_upload = False
                    IsFlashBack=False
                    '''
                    try:
                        if not self.Android_IOS.FindRunIPA_APK(self.Android_IOS.package):#闪退检测
                            IsFlashBack=True
                    except:
                        pass'''
                    #超时处理
                    nowtime=datetime.datetime.now()
                    timeout=600
                    if self.timestart+datetime.timedelta(minutes=60)>nowtime:#当案例失败，capture被销毁时,会报错
                        pass
                    elif self.timestart+datetime.timedelta(minutes=120)>nowtime:
                        timeout=1000
                    else:
                        time_difference=nowtime-self.timestart
                        timeout=int(time_difference.total_seconds()/8)
                    if "toreversion" in self.task_parameters.keys() and self.task_parameters["toreversion"]=="true":
                        ret,data = perfeye.Stop( f'{self.case_name}(' + self.device_s + ')', scenes=self.case_name, picture_quality=self.device_quality, do_upload=do_upload, appKey=self.parameters["appKey"],IsFlashBack=IsFlashBack,version=self.Android_IOS.package_info["versionName"],timeout=timeout,parameters=self.parameters,Android_IOS=self.Android_IOS)
                    else:
                        ret,data = perfeye.Stop( f'{self.case_name}(' + self.device_s + ')', scenes=self.case_name, picture_quality=self.device_quality, do_upload=do_upload, appKey=self.parameters["appKey"],IsFlashBack=IsFlashBack,timeout=timeout,parameters=self.parameters,Android_IOS=self.Android_IOS)

                    #宕机用例采集数据失败默认跳过
                    '''
                    if not ret and 'dump' in self.parameters and self.parameters['dump']:
                        self.bot.send_text(f"{self.device_name}-{self.device_s} perfeye 采集结束失败: {ret}, {data}")
                        case_status.case_fail()'''

                    # bot.send_text(f"{device_s} perfeye 采集结束: {ret}, {data}")
                    print(f"{self.device_s} perfeye 采集结束: {ret}, {data}")
                    # perfeye 结束采集后不用给主进程进行清理
                    self.task_data["perfeye"] = -1
                    if ret==False:
                        self.perfeyesuccessd=False
                    # 获取报告结果
                    if ret and save:
                        self.report_data["perfeye"] = data["result"]["report_id"]

                self.isrun=False
            return self.report_data
        except Exception as e:
            self.bot.send_text(f"{self.device_name}-{self.device_s}  采集结束失败")
            info=traceback.format_exc()
            self.bot.send_text(info)
            print(f"{self.device_name}-{self.device_s}  采集结束失败  error info:{info}")

    #开放项目脚本中的停止采集操作
    def stop_capture_in_run(self,save=True):
        try:
            if self.isrun and "performance" in self.parameters.keys():
                collect_type = self.parameters["performance"]

                # perfeye 采集
                if "perfeye" in collect_type and "perfeye" in self.performance:
                    # TODO 参数可配置
                    perfeye = self.performance["perfeye"]
                    ret=None
                    data=None

                    do_upload = save
                    print(self.parameters)
                    if type(collect_type) == dict:
                        if "save" in collect_type["perfeye"]:
                            if collect_type["perfeye"]["save"] == 0:
                                print("perfeye 参数设置为该数据不标记为每日数据")
                                do_upload = False
                    IsFlashBack=False
                    try:
                        if not self.Android_IOS.FindRunIPA_APK(self.Android_IOS.package):#闪退检测
                            IsFlashBack=True
                    except:
                        pass
                    if "toreversion" in self.task_parameters.keys() and self.task_parameters["toreversion"]=="true":
                        ret,data = perfeye.Stop( f'{self.case_name}(' + self.device_s + ')', scenes=self.case_name, picture_quality=self.device_quality, do_upload=do_upload, appKey=self.parameters["appKey"],IsFlashBack=IsFlashBack,version=self.Android_IOS.package_info["versionName"],parameters=self.parameters,Android_IOS=self.Android_IOS)
                    else:
                        ret,data = perfeye.Stop( f'{self.case_name}(' + self.device_s + ')', scenes=self.case_name, picture_quality=self.device_quality, do_upload=do_upload, appKey=self.parameters["appKey"],IsFlashBack=IsFlashBack,parameters=self.parameters,Android_IOS=self.Android_IOS)
                    if not ret:
                        self.bot.send_text(f"{self.device_name}-{self.device_s} perfeye 采集结束失败: {ret}, {data}")               
                    # bot.send_text(f"{device_s} perfeye 采集结束: {ret}, {data}")
                    print(f"{self.device_s} perfeye 采集结束: {ret}, {data}")
                    # perfeye 结束采集后不用给主进程进行清理
                    self.task_data["perfeye"] = -1
                    if ret==False:
                        self.perfeyesuccessd=False
                    # 获取报告结果
                    if ret and save:
                        self.report_data["perfeye"] = data["result"]["report_id"]

                
                # gpu_temp
                if "gpu_temp" in collect_type and "gpuTemp" in self.performance:
                    gpuTemp = self.performance["gpuTemp"]
                    ret = gpuTemp.stop_capture()
                    # bot.send_text(f"{device_s} gpu_temp 采集结束 {ret}")
                    print(f"{self.device_s} gpu_temp 采集结束 {ret}")
                    
                    if ret != None and save:
                        self.report_data["gpu_temp"] = ret["file_path"]
                
                # perfetto
                if "perfetto" in collect_type and "perfetto" in self.performance:
                    perfetto = self.performance["perfetto"]
                    ret = perfetto.stop()
                    self.bot.send_text(f"{self.device_s} perfetto 采集结束: {ret}")
                    print(f"{self.device_s} perfetto 采集结束: {ret}")

                    if ret != None and save:
                        self.report_data["perfetto"] = ret["file_path"]

                #深度采集
                if "Profile" in collect_type and "Prof" in self.performance:
                    Prof = self.performance["Prof"]
                    Prof.StopProfile()
                    time.sleep(3)
                    switch={
                        "casename":self.case_name,
                        "save":False,
                        "upload":save,
                        "type":"ordinary",
                        "shiled":0
                        }
                    ret=Prof.checkProfile(switch)
                    if ret != None and save:
                        self.report_data["Profile"] = ret["uuid"]
                        self.report_data["appkey"] = self.Android_IOS.appkey
                    self.bot.send_text(f"{self.device_name} Profile 深度采集结束: {ret}")


                # 由于目前 UE4 UBox 页面还不支持采集，深度数据非常不好获取，因此这里把 perfeye 数据的网页链接也发到 UBox 上，方便跳转查看
                
                # Insight 采集
                if "insight" in collect_type and "Insight" in self.performance:
                    Insight = self.performance["Insight"]
                    Insight.StopProfile()
                    switch={
                        "casename":self.case_name,
                        "save":False,
                        "upload":save,
                        "type":"ordinary",
                        "shiled":0,
                        "LLM": "LLM" in collect_type,
                        "LLM_Path": f"/sdcard/UE4Game/{self.Android_IOS.package_info['projectName']}/{self.Android_IOS.package_info['projectName']}/Saved/Profiling/LLM",
                        "memreport": "memreport" in collect_type,
                        "memreport_path": f"/sdcard/UE4Game/{self.Android_IOS.package_info['projectName']}/{self.Android_IOS.package_info['projectName']}/Saved/Profiling/MemReports",
                        }
                    if "perfeye" in self.report_data.keys():
                        switch["perfeye"] = f"http://perfeye.console.testplus.cn/case/{self.report_data['perfeye']}/report"
                    if "android" in self.platform:
                        switch["LLM_Path"] = f"/sdcard/UE4Game/{self.Android_IOS.package_info['projectName']}/{self.Android_IOS.package_info['projectName']}/Saved/Profiling/LLM"
                        switch["memreport_path"] = f"/sdcard/UE4Game/{self.Android_IOS.package_info['projectName']}/{self.Android_IOS.package_info['projectName']}/Saved/Profiling/MemReports"
                    elif "ios" in self.platform:
                        switch["LLM_Path"] = f"/Documents/{self.Android_IOS.package_info['projectName']}/Saved/Profiling/LLM"
                        switch["memreport_path"] = f"/Documents/{self.Android_IOS.package_info['projectName']}/Saved/Profiling/MemReports"

                    
                    ret=Insight.checkProfile(switch)
                    if ret != None and save:
                        self.report_data["Insight"] = ret["uuid"]
                        self.report_data["appkey"] = self.Android_IOS.appkey
                    self.bot.send_text(f"{self.device_name} Insight 深度采集结束: {ret}")


                elif "Insight" in self.performance:
                    
                    Insight = self.performance["Insight"]
                    switch={
                        "casename":self.case_name,
                        "save":False,
                        "upload":True, # LLM 和 memreport 忽略案例失败上传数据
                        "type":"ordinary",
                        "shiled":0,
                        "LLM": "LLM" in collect_type,
                        "LLM_Path": f"/sdcard/UE4Game/{self.Android_IOS.package_info['projectName']}/{self.Android_IOS.package_info['projectName']}/Saved/Profiling/LLM",
                        "memreport": "memreport" in collect_type,
                        "memreport_path": f"/sdcard/UE4Game/{self.Android_IOS.package_info['projectName']}/{self.Android_IOS.package_info['projectName']}/Saved/Profiling/MemReports",
                        }
                    if "perfeye" in self.report_data.keys():
                        switch["perfeye"] = f"http://perfeye.console.testplus.cn/case/{self.report_data['perfeye']}/report"
                    if "android" in self.platform:
                        switch["LLM_Path"] = f"/sdcard/UE4Game/{self.Android_IOS.package_info['projectName']}/{self.Android_IOS.package_info['projectName']}/Saved/Profiling/LLM"
                        switch["memreport_path"] = f"/sdcard/UE4Game/{self.Android_IOS.package_info['projectName']}/{self.Android_IOS.package_info['projectName']}/Saved/Profiling/MemReports"
                    elif "ios" in self.platform:
                        switch["LLM_Path"] = f"/Documents/{self.Android_IOS.package_info['projectName']}/Saved/Profiling/LLM"
                        switch["memreport_path"] = f"/Documents/{self.Android_IOS.package_info['projectName']}/Saved/Profiling/MemReports"

                    
                    
                    ret=Insight.checkProfile(switch)
                    if ret != None and save:
                        self.report_data["Insight"] = ret["uuid"]
                        self.report_data["appkey"] = self.Android_IOS.appkey
                    self.bot.send_text(f"{self.device_name} LLM 和 memreport 采集结束: {ret}")


                
                # Minicap 自定义截图采集
                if "minicap" in collect_type:
                    Minicap = self.performance["Minicap"]
                    Minicap.stop()

                    minicap_data = self.performance["minicap_data"]

                    if minicap_data != []:
                        gpath= os.path.abspath(os.path.join(os.getcwd(), "..","files"))
                        gpathzip=os.path.join(gpath,f"{self.task_running_id}_{self.device_ip}_{self.case_name}.zip")
                        zip = zipfile.ZipFile(gpathzip,"w",zipfile.ZIP_DEFLATED)#新建压缩文件
                        for itme in minicap_data:
                            fill_name=itme.split('\\')[-1]
                            zip.write(itme,fill_name)
                        zip.close()
                self.isrun=False
            return self.report_data
        except Exception as e:
            self.bot.send_text(f"{self.device_name}-{self.device_s}  采集结束失败")
            self.bot.send_text(traceback.format_exc())

    def memory_capture(self,device_model,case,udriver):
        try:
            if self.project_id == 'jxsj4':  # 剑世4自己一套内存快照采集
                file_name = f"{device_model}_{case['english_name']}"
                print(f"案例执行成功，发送自定义接口TakeSnapshot {file_name}")
                res_snap = udriver.custom_interface("TakeSnapshot", f"{file_name}")
                if "unknown" not in res_snap:
                    current_date = datetime.datetime.now().strftime("%Y_%m_%d")
                    response = requests.post(
                        f"http://10.11.67.131:8888/api/track/{self.project_id}/Android/memory-profiler",
                        json={
                            "ip": self.device_ip,
                            "casename": case["name"],
                            "version": self.Android_IOS.versionName,
                            "snap": f"http://10.11.10.147:9000/snapshot/{file_name}_{current_date}.zip",
                            "tags": []
                        }, timeout=(10, 15))
                    ret = json.loads(response.content)
                    print(f"调用发送内存采集接口{ret['msg']}，内存采集接口地址为-> http://10.11.10.147:9000/snapshot/{file_name}_{current_date}.zip")
                    return f"http://10.11.10.147:9000/snapshot/{file_name}_{current_date}.zip"
                return False
            else:  # 其它项目自己通用内存快照采集
                res = udriver.profiling_memory()
                if 'result' in res:
                    if res['result'] == "True":
                        origin_file = res['Reply_Content']
                        directory_path = os.path.dirname(origin_file)  # 获取目录
                        memory_id = os.path.basename(origin_file).split('.')[0]  # 获取文件名
                        save_file = f"./log_file/{self.device_s}_{memory_id}.snap"
                        os.popen(f"adb -s {self.device_s} pull {origin_file} {save_file}")
                        time.sleep(1)
                        os.popen(f"adb -s {self.device_s} shell rm {origin_file}")
                        os.popen(
                            f"adb -s {self.device_s} shell rm {os.path.join(directory_path, memory_id + '.png')}")
                        return save_file
                return False
        except:
            print("内存快照采集失败")
            print(traceback.format_exc())
            self.bot.send_text(f"{self.device_name}-{self.device_s}内存快照采集失败")

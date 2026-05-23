# -*- coding: utf-8 -*-
import sys
import os
import psutil
from datetime import time

sys.path.append(os.path.dirname(os.path.realpath(__file__)))

from CaseXGameCrash import *
from SendMsgRobot import *

class CaseVulkanLayerCheck(CaseXGameCrash):
    def __init__(self):
        super().__init__()
        self.saveTime = time.strftime("%Y%m%d", time.localtime())
        self.key_word = None
        self.Save_Log_Path = None
        self.strCaseName = None
        self.BIN_ASAN_PATH = None
        self.needKillDeath = None
        self.DX_LOG_PATH = None
        self.vulkan_sdk_bin_path = None
        self.vulkan_config_gui_path = None
        self.vulkan_sdk_path = None
        self.log = None
        self.initLogger()
        self.webhook = r"https://xz.wps.cn/api/v1/webhook/send?key=8ec0c8a2b134fe7a9e0c77bebe3dc79d"
        self.SenMsgRobot = SendMsgRobot(self.webhook)
        self.name = None
        self.bDumpCase=True #宕机用例
        self.FileShare_PATH = r'\\10.11.85.148\FileShare-181-242\FileShare\stabilityTest\Vulkan验证层检查日志'

    def find_folders_containing(self, target_folder, search_path):
        """
        查找包含指定文件夹的路径

        Args:
            target_folder (str): 要查找的目标文件夹名
            search_path (str): 要搜索的根目录路径

        Returns:
            full_path (str): 包含目标文件夹完整路径
        """
        full_path = None

        # 遍历目录树
        for root, dirs, files in os.walk(search_path):
            # 获取包含目标文件夹的完整路径
            full_path = os.path.join(root, target_folder)
            # 检查当前目录的子文件夹中是否包含目标文件夹
            if target_folder in dirs:
                return full_path

        return full_path

    def start_asan_message_monitor(self):
        self.BASE_R3_PATH = r'f:/R3MessageMonitor'
        if not os.path.exists(self.BASE_R3_PATH):
            disks = psutil.disk_partitions()
            for disk in disks:
                path = disk.mountpoint + 'R3MessageMonitor'
                if os.path.exists(path):
                    self.BASE_R3_PATH = path
                    break
        self.BIN_ASAN_PATH = self.BASE_R3_PATH + r'\bin'
        asan_monitor_name = "R3MessageMonitor.exe JX3ClientX3DX64.exe"
        self.log.info(self.BIN_ASAN_PATH)
        self.log.info(asan_monitor_name)
        asan_monitor_path = os.path.join(self.BIN_ASAN_PATH, asan_monitor_name)
        win32_runExe_no_wait(asan_monitor_path, self.BIN_ASAN_PATH)

    def check_process_by_name(self,process_name):
        """通过进程名检查进程是否存在"""
        for proc in psutil.process_iter(['name']):
            if proc.info['name'] == process_name:
                return True
        return False

    def start_vulkan_config_gui(self):
        if self.check_process_by_name("vkconfig-gui.exe"):
            return

        target_folder = r'Bin'
        vulkan_config_gui_name = r'vkconfig-gui.exe'
        self.vulkan_sdk_path = r'c:\VulkanSDK'
        if not os.path.exists(self.vulkan_sdk_path):
            disks = psutil.disk_partitions()
            for disk in disks:
                path = disk.mountpoint + 'VulkanSDK'
                if os.path.exists(path):
                    self.vulkan_sdk_path = path
                    break

        self.vulkan_sdk_bin_path = self.find_folders_containing(target_folder, self.vulkan_sdk_path)
        self.vulkan_config_gui_path = os.path.join(self.vulkan_sdk_bin_path, vulkan_config_gui_name)
        self.log.info(self.vulkan_config_gui_path)
        self.log.info(self.vulkan_sdk_bin_path)
        win32_runExe_no_wait(self.vulkan_config_gui_path, self.vulkan_sdk_bin_path)

    @staticmethod
    def pre_run_to_kill_vulkan_layer_check_processes():
        win32_kill_process('R3MessageMonitor.exe') #杀死VK验证层信息捕获工具
        # win32_kill_process('vkconfig-gui.exe') #杀死VK验证层检查工具，杀死工具再启动会弹出崩溃弹窗确认，因此不再强杀vkconfig-gui.exe

    @staticmethod
    def find_new_file(find_dir_path):
        """查找目录下最新的文件夹"""
        dir_lists = os.listdir(find_dir_path)
        dir_lists.sort(key=lambda fn: os.path.getmtime(find_dir_path + r"/" + fn) if not os.path.isdir(
            find_dir_path + r"/" + fn) else 0)
        new_dir_path = os.path.join(find_dir_path, dir_lists[-1])
        '''查找目录下最新的log文件'''
        new_dir = os.listdir(new_dir_path)
        new_dir.sort(key=lambda fn: os.path.getmtime(new_dir_path + r"/" + fn))
        new_log_path = os.path.join(new_dir_path, new_dir[-1])
        return new_log_path

    def find_jx3_log(self):
        new_jx3_log_path = self.find_new_file(self.CLIENT_LOG_PATH)
        return new_jx3_log_path

    def findDXLog(self):
        self.DX_LOG_PATH = self.BIN_ASAN_PATH + r'/DX_log'
        dx_log_path = self.find_new_file(self.DX_LOG_PATH)
        return dx_log_path

    def check_dic_args(self, dic_args):
        dic_args['nTimeout'] = 99999999
        self.needKillDeath = True
        super().check_dic_args(dic_args)
        # 设置用例信息
        self.strCaseName = dic_args['CaseName']  # 问题用例
        file = "CaseInfo.ini"
        ini_set('CaseInfo', 'CaseName', self.strCaseName, file)

    @staticmethod
    def filtration_log(file_path):
        with open(file_path, 'r') as f:
            file_lines = f.readlines()
        for line in file_lines:
            match = re.search(r'Validation Error(.*)', line) or re.search(r'Validation Warning(.*)', line)
            if match:
                return True
        return False

    @staticmethod
    def get_filepath_without_extension_str(filepath):
        """
        使用字符串处理获取文件路径但不包含后缀

        参数:
        filepath: 文件路径或文件名

        返回:
        不带后缀的文件名
        """
        # 获取基础文件名（去除路径）
        # if "/" in filepath:
        #     base_name = filepath.split("/")[-1]
        # elif "\\" in filepath:  # 处理Windows路径
        #     base_name = filepath.split("\\")[-1]
        # else:
        #     base_name = filepath

        # 查找最后一个点号的位置
        dot_index = filepath.rfind(".")

        # 如果没有点号或点号在开头（如隐藏文件），返回整个文件名
        if dot_index <= 0:
            return filepath

        # 返回点号之前的部分
        return filepath[:dot_index]

    @staticmethod
    def filter_lines_by_keywords(input_lines, keywords):
        """
        过滤文本行，只保留包含特定关键字的行

        参数:
        input_lines: 输入的行列表
        keywords: 要过滤的关键字列表

        返回:
        包含指定关键字的行列表
        """
        # 确保keywords是列表形式
        if isinstance(keywords, str):
            keywords = [keywords]

        # 过滤出包含任一关键字的行
        filtered_lines = [
            line for line in input_lines
            if any(keyword in line for keyword in keywords)
        ]

        return filtered_lines

    def filter_vk_layer_log_and_save(self, vk_layer_log_path):
        vk_layer_message_to_filter = ["Vulkan Loader", "KB", "VULKANHOOK", "AK Error:"]
        filtered_lines_vk_layer_log_path = self.get_filepath_without_extension_str(vk_layer_log_path) + "_filter.log"
        file_lines = []
        filtered_vk_layer_lines = []
        with open(vk_layer_log_path, 'r') as f:
            file_lines = f.readlines()
        filtered_vk_layer_lines = self.filter_lines_by_not_have_keywords(file_lines, vk_layer_message_to_filter)
        with open(filtered_lines_vk_layer_log_path, 'w') as f:
            f.writelines(filtered_vk_layer_lines)

        errmsg = f'{self.key_word}\n日志保存路径：\\{filtered_lines_vk_layer_log_path}'
        self.log.info(errmsg)
        self.SenMsgRobot.push_interactive_report(self.strMachineName, self.strCaseName, errmsg, filtered_lines_vk_layer_log_path)
        return True

    @staticmethod
    def filter_lines_by_not_have_keywords(input_lines, keywords):
        """
        过滤文本行，只保留包含特定关键字的行

        参数:
        input_lines: 输入的行列表
        keywords: 要过滤的关键字列表

        返回:
        包含指定关键字的行列表
        """
        # 确保keywords是列表形式
        if isinstance(keywords, str):
            keywords = [keywords]

        # 过滤出包含任一关键字的行
        filtered_lines = [
            line for line in input_lines
            if not any(keyword in line for keyword in keywords)
        ]

        return filtered_lines

    def check_vk_layer_log(self, dic_args):
        self.log.info("check_vk_layer_log")
        vk_layer_log_path = self.findDXLog()
        jx3_client_log_path = self.find_jx3_log()
        empty = os.stat(vk_layer_log_path).st_size == 0
        if empty:
            self.log.info("Vulkan 日志为空")
            pass
        else:
            '''存在问题：log保存到共享，并且同步信息'''
            self.strCaseName = dic_args['CaseName']  # 问题用例
            filecontrol_copyFileOrFolder(vk_layer_log_path, self.Save_Log_Path)  # 保存vk log到共享文件夹
            filecontrol_copyFileOrFolder(jx3_client_log_path, self.Save_Log_Path)  # 保存client log到共享文件夹

            filepath, fullname = os.path.split(vk_layer_log_path)
            fileshare_log_path = os.path.join(self.Save_Log_Path, fullname)

            if self.filtration_log(fileshare_log_path):
                self.filter_vk_layer_log_and_save(fileshare_log_path)

    def loadDataFromLocalConfig(self, dic_args):
        super().loadDataFromLocalConfig(dic_args)
        self.log.info(f'机器: {self.strMachineName}')
        self.key_word = "[" + machine_get_IPAddress() + "]" + "VK验证层检查"

    def processDxCache(self):
        path = r'C:\Users\{}\AppData\Local\AMD\DxCache'.format(getpass.getuser())
        if os.path.exists(path):
            try:
                filecontrol_deleteFileOrFolder(path)
            except Exception:
                info = traceback.format_exc()
                self.log.warning(info)
        path = r'C:\Users\{}\AppData\Local\NVIDIA\DXCache'.format(getpass.getuser())
        if os.path.exists(path):
            try:
                filecontrol_deleteFileOrFolder(path)
            except Exception:
                info = traceback.format_exc()
                self.log.warning(info)

    def validateCaseName(self, case_name):
        rstr = r"[\/\\\:\*\?\"\<\>\|]"  # '/ \ : * ? " < > |'不能存在于文件夹名或文件名中,因此替换
        new_title = re.sub(rstr, "_", case_name)  # 替换为下划线
        return new_title

    def create_vulkan_layer_data_save_folder(self, dic_args):
        self.log.info("create_vulkan_layer_data_save_folder")
        self.strCaseName = dic_args['CaseName']  # 问题用例
        str_case_name = self.validateCaseName(self.strCaseName)
        str_machine = self.validateCaseName(machine_get_VideoCardInfo_v2())
        log_info = {'GPUType': str_machine, 'SaveTime': self.saveTime, 'CaseName': str_case_name}  # 字典结构不妥
        self.Save_Log_Path = self.FileShare_PATH
        for key in log_info:
            self.Save_Log_Path = os.path.join(self.Save_Log_Path, log_info[key])
            if not os.path.exists(self.Save_Log_Path):
                os.makedirs(self.Save_Log_Path)  # 创建路径

    def save_vulkan_layer_data(self, dic_args):
        self.log.info("save_vulkan_layer_data")
        self.create_vulkan_layer_data_save_folder(dic_args)
        self.check_vk_layer_log(dic_args)

    def teardown(self):
        win32_kill_process('R3MessageMonitor.exe')
        #删除VK验证层工具
        super().teardown()

    def run_local(self, dic_args):
        super().run_local(dic_args)


    def run_from_uauto(self,dic_parameters):
        self.pre_run_to_kill_vulkan_layer_check_processes() #杀掉Asan信息检测工具和VK验证层检查工具
        self.start_asan_message_monitor()  #启动Asan信息检测工具
        self.start_vulkan_config_gui()   #启动VK验证层检查工具
        super().run_from_uauto(dic_parameters)  #测试上传日志功能
        self.save_vulkan_layer_data(dic_parameters)

    def processDxCache(self):
        path = r'C:\Users\{}\AppData\Local\AMD\DxCache'.format(getpass.getuser())
        if os.path.exists(path):
            try:
                filecontrol_deleteFileOrFolder(path)
            except Exception:
                info = traceback.format_exc()
                self.log.warning(info)
        path = r'C:\Users\{}\AppData\Local\NVIDIA\DXCache'.format(getpass.getuser())
        if os.path.exists(path):
            try:
                filecontrol_deleteFileOrFolder(path)
            except Exception:
                info = traceback.format_exc()
                self.log.warning(info)

    def task_process_data(self):
        #不需要处理性能数据
        pass

    def start_client_test(self, dic_args):
        # if self.clientType == 'PAK_EXP_classic':
        #     win32_runExe("JX3ClientX64.exe DOTNOTSTARTGAMEBYJX3CLIENT.EXE", self.CLIENT_PATH + "/" + self.BIN64_NAME)
        #     return  测试用的，注释掉
        self.log.info("start_client_test")
        if self.bMobile:
            # 设备清除后台
            # self.mobile_device.clear_background()
            # 关闭app
            # mobile_kill_app(self.package,self.deviceId)
            self.mobile_device.kill_app()
            time.sleep(15)
            # ret=mobile_start_app(self.package,self.deviceId)
            # app 三次运行失败 用例执行失败
            nReStartCounter = 4
            # 移动端 此处等待Perfeye线程获取applist后再启动app
            while not self.bCanStartClient:
                time.sleep(1)
            for i in range(nReStartCounter):
                if i == nReStartCounter - 1:
                    raise Exception(f"{nReStartCounter - 1}次启动app失败,用例执行失败退出")
                elif i == nReStartCounter - 2:
                    # ios端 有可能使用tidevice 启动app报错了 需要使用wda启动app
                    self.mobile_device.start_app_wda()
                if self.mobile_device.determine_runapp():
                    break
                else:
                    ret = self.mobile_device.start_app()
                    self.log.info(ret)
                    time.sleep(15)
            self.log.info(f"app start temperature:{self.mobile_device.get_Battery_temperature()}")
            self.clientPID = "mobile"
        else:
            if 'memtest' in dic_args and dic_args['memtest'] == True:
                # 修改mem_jx3hd.cmd文件里的
                root = os.path.realpath(__file__).split('\\')[0]
                CPPMEMCMD = root + '/CppMemCmd'
                exe = os.path.join(CPPMEMCMD, "mem_jx3hd.cmd")
                pp = win32_runExe_no_wait(exe, CPPMEMCMD)
                listP = win32_findProcessByName(self.exename)
                while not listP:
                    listP = win32_findProcessByName(self.exename)
                    time.sleep(1)
                p2 = listP[0]
                self.clientPID = p2.pid
                self.process_threads_activeWindow()
            else:
                path = os.path.join(self.CLIENT_PATH, self.BIN64_NAME)
                exe = os.path.join(path, self.exename)
                self.log.info(exe)
                self.log.info(path)
                pp = win32_runExe_no_wait(exe, path)
                self.clientPID = pp.pid
                self.process_threads_activeWindow()  # 让客户端处于顶层
                nSetMaxWindow = 0
                try:
                    nSetMaxWindow = dic_args["devices_custom"]['perfmon_info']['MaxWindow']
                    if nSetMaxWindow:
                        self.SetMaxWindow()
                except:
                    pass
        self.log.info("start_client_test_success")
        self.nClientStartTime = int(time.time())

def AutoRun(dic_parameters):
    global obj_test
    obj_test = CaseVulkanLayerCheck()
    obj_test.run_from_uauto(dic_parameters)


if __name__ == '__main__':
    obj_test = CaseVulkanLayerCheck()
    dic_test = {}
    dic_test['CaseName'] = "testname"
    obj_test.save_vulkan_layer_data(dic_test)


# -*- coding: utf-8 -*-
import shutil
from datetime import time
import psutil
from SendMsgRobot import *
import os
import re

import sys

sys.path.append("..\..")
from public.CaseJX3SearchPanel import *


class MemoryDetection(CaseJX3SearchPanel):
    def __init__(self):
        print(os.getcwd())
        super().__init__()
        print("<os.path.realpath1>:", os.path.realpath(__file__))
        os.chdir("..\\..\\public")  # 修改当前工作目录
        print("<os.path.realpath2>:", os.path.realpath(__file__))
        self.Save_Log_Path = None
        self.R3_LOG_PATH = None
        self.new_jx3_log_path = None
        self.JX3_LOG_PATH = None
        self.caseName = None
        self.BASE_R3_PATH = None
        self.R3ClientPID = None
        self.BIN_R3_PATH = None
        self.r3_exe_name = None
        self.BIN64_NAME = 'bin64_Asan'
        self.saveTime = time.strftime("%Y%m%d", time.localtime())
        self.FileShare_PATH = r'\\10.11.68.11\FileShare\丁水娇\R3问题日志'

    def thread_SearchPanelPerfEyeCtrl(self):
        pass

    def task_process_perfeye_data(self):
        pass

    def processSearchPanelTab(self, dic_args):
        def processTrafficInfo():
            self.DIC_TrafficInfo = {}  # 存储车夫信息
            if 'classic' in self.clientType:  # 怀旧版专用
                self.MapPathData_path = r'\MapPathData_classic.tab'
            else:
                self.MapPathData_path = r'\MapPathData.tab'

            print("GPUType：", machine_get_VideoCardInfo_v2())

            print("dirname:", os.path.dirname(os.path.realpath(__file__)))

            with open(os.path.dirname(os.path.realpath(__file__)) + self.MapPathData_path) as f:
                for line in f:
                    list_data = line.replace("\n", "").replace("\r", "").split('\t')
                    self.DIC_TrafficInfo[list_data[0]] = (
                        list_data[1], list_data[2], list_data[3], list_data[4],
                        list_data[5])  # 地图id  出发车夫  目的车夫  x y z（出发前的位置）

        nVideoLevel = int(self.strNumVideoLevel)  # 从配置文件中读取的画质等级
        if 'classic' in self.clientType:  # 怀旧版画质处理
            if nVideoLevel == 3:
                nVideoLevel_temp = nVideoLevel + 1  # 画质+1和-1处理的原因：为了让画质设置处于默认位置，防止人为修改。
            else:
                nVideoLevel_temp = nVideoLevel - 1
            strVideoLevel = str(nVideoLevel)
            strVideoLevel_temp = str(nVideoLevel_temp)
        elif 'BD' in self.clientType:
            strVideoLevel = str(nVideoLevel)
            strVideoLevel_temp = str(132)  # 统一调成BD均衡
        else:  # 重制版画质处理
            if nVideoLevel == 8:
                nVideoLevel_temp = nVideoLevel - 1
            elif nVideoLevel == 10:
                nVideoLevel_temp = 8
            else:
                nVideoLevel_temp = nVideoLevel + 1
            strVideoLevel = str(nVideoLevel)
            strVideoLevel_temp = str(nVideoLevel_temp)

        mapid = str(dic_args['mapid'])
        testpoint = dic_args['testpoint']
        casename = dic_args['casename']

        # copy用例、更改字段
        src = os.path.join('CaseJX3Client-Attachment', 'SearchPanel', casename)
        dst = os.path.join(self.SEARCHPANEL_PATH, 'RunMap.tab')
        filecontrol_copyFileOrFolder(src, dst)

        sChange = []
        sChange.append(['_mapid_', mapid])
        sChange.append(['_mapname_', self.mapname])
        sChange.append(['_video_', strVideoLevel_temp])
        sChange.append(['_video1_', strVideoLevel])
        sChange.append(['_classicVideoLevel_', strVideoLevel])
        sChange.append(['_classicVideoLevel2_', strVideoLevel_temp])

        if ('autofly' in testpoint) and (mapid != '1'):  # autofly用例的车夫信息
            processTrafficInfo()
            trafficID1, trafficID2, X, Y, Z = self.DIC_TrafficInfo[mapid]
            sChange.append(['_flyTime_', str(self.FLY_TIME)])
            sChange.append(['_trafficID1_', trafficID1])
            sChange.append(['_trafficID2_', trafficID2])
            sChange.append(['_X_', X])
            sChange.append(['_Y_', Y])
            sChange.append(['_Z_', Z])

        for each_yield in sChange:  # 修改'RunMap.tab'的内容，该文件用于控制用例运行，包括位置、画质、时间等。
            changeStrInFile(dst, each_yield[0], each_yield[1])

        # 清掉custom.ini内容，保证每个案例都是从头开始跑
        f = open(self.SEARCHPANEL_PATH + "\\custom.ini", 'w')
        f.close()

        # 拷贝SearchPanel.lua
        if 'classic' in self.clientType:
            src = os.path.join('CaseJX3Client-Attachment', 'SearchPanel', 'BVTTest_classic.lua')
            dst = os.path.join(self.CLIENT_PATH, 'interface', 'SearchPanel', 'BVTTest.lua')
            filecontrol_copyFileOrFolder(src, dst)
            filecontrol_copyFileOrFolder(
                os.path.join('CaseJX3Client-Attachment', 'MainScript', 'VideoManagerPanel_classic.lua'),
                os.path.join(self.CLIENT_PATH, 'ui', 'Config', 'Default', 'VideoManagerPanel.lua'))
        else:
            src = os.path.join('CaseJX3Client-Attachment', 'SearchPanel', 'BVTTest.lua')
            dst = os.path.join(self.CLIENT_PATH, 'interface', 'SearchPanel', 'BVTTest.lua')
            filecontrol_copyFileOrFolder(src, dst)

    def check_dic_args(self, dic_args):
        super().check_dic_args(dic_args)
        if 'classic' in dic_args['clientType']:
            self.BIN64_NAME = 'bin64_Asan_classic'
        else:
            self.BIN64_NAME = 'bin64_Asan'

    def start_r3messagemonitor(self):
        self.BASE_R3_PATH = r'f:/R3MessageMonitor'
        if not os.path.exists(self.BASE_R3_PATH):
            disks = psutil.disk_partitions()
            for disk in disks:
                path = disk.mountpoint + 'R3MessageMonitor'
                if os.path.exists(path):
                    self.BASE_R3_PATH = path
                    break

        self.BIN_R3_PATH = self.BASE_R3_PATH + r'\bin'
        r3path = self.BIN_R3_PATH
        self.r3_exe_name = "R3MessageMonitor.exe"
        r3exe = os.path.join(r3path, self.r3_exe_name)
        self.log.info(r3exe)
        self.log.info(r3path)
        r3pp = win32_runExe_no_wait(r3exe, r3path)
        self.R3ClientPID = r3pp.pid
        self.process_threads_activeWindow()

    def preRunToKillR3Exe(self):
        win32_kill_process('R3MessageMonitor.exe')

    def teardown(self, dic_args):
        # 这里写上销毁清理工作，可以让工作线程安全退出的工作
        win32_kill_process('R3MessageMonitor.exe')
        super().teardown(dic_args)

    def validateCaseName(self, caseName):
        rstr = r"[\/\\\:\*\?\"\<\>\|]"  # '/ \ : * ? " < > |'不能存在于文件夹名或文件名中,因此替换
        new_title = re.sub(rstr, "_", caseName)  # 替换为下划线
        return new_title

    def save_log_file(self, log_path):
        caseName = self.validateCaseName(self.caseName)
        mechine = self.validateCaseName(machine_get_VideoCardInfo_v2())
        R3LogInfo = {'GPUType': mechine, 'SaveTime': self.saveTime, 'CaseName': caseName}
        self.Save_Log_Path = self.FileShare_PATH
        for key in R3LogInfo:
            self.Save_Log_Path = os.path.join(self.Save_Log_Path, R3LogInfo[key])
            if not os.path.exists(self.Save_Log_Path):
                os.makedirs(self.Save_Log_Path)  # 创建路径
        shutil.copy(log_path, self.Save_Log_Path)  # 拷贝文件

    def find_new_file(self, find_dir_path):
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
        # disks = psutil.disk_partitions()
        # for disk in disks:
        #     path = disk.mountpoint + 'trunk' + '\\client\\logs\\JX3Client_2052-zhcn'
        #     if os.path.exists(path):
        #         self.JX3_LOG_PATH = path
        #         break
        new_jx3_log_path = self.find_new_file(self.CLIENT_LOG_PATH)
        return new_jx3_log_path

    def find_r3_log(self):
        self.R3_LOG_PATH = self.BIN_R3_PATH + r'/R3_log'
        r3_log_path = self.find_new_file(self.R3_LOG_PATH)
        return r3_log_path

    def check_r3_log(self, dic_args):
        r3_log_path = self.find_r3_log()
        isempty = os.stat(r3_log_path).st_size == 0
        if isempty:
            pass
        else:
            '''存在问题：log保存到共享，并且发消息到飞书'''
            self.caseName = dic_args['CaseName']  # 问题用例

            self.save_log_file(r3_log_path)  # 保存r3log到共享文件夹
            self.save_log_file(self.find_jx3_log())  # 保存jx3log到共享文件夹

            filepath, fullname = os.path.split(r3_log_path)
            fileshare_log_path = os.path.join(self.Save_Log_Path, fullname)

            errmsg = r'内存检测存在问题,r3log日志保存路径：\\' + fileshare_log_path
            push_interactive_report(machine_get_IPAddress(), self.caseName, errmsg, r3_log_path)  # 发送消息到飞书

    def run_local(self, dic_args):  # 用例的主体（入口）函数，dic_args是从IQB平台传来的参数字典
        self.preRunToKillR3Exe()  # 清理之前可能没有关闭的检测工具
        self.start_r3messagemonitor()  # 启动r3messagemonitor检测工具

        super().run_local(dic_args)

        self.check_r3_log(dic_args)  # 检查r3日志


if __name__ == '__main__':
    r3_test = MemoryDetection()
    r3_test.run_from_IQB()

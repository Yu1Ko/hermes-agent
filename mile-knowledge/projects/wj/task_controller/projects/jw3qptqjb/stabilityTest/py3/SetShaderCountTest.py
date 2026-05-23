# -*- coding: utf-8 -*-
import shutil
from datetime import time
import psutil
from SendMsgRobot import *
import os
import re
import subprocess

import sys

sys.path.append("..\..")
from public.CaseJX3SearchPanel import *


class SetShaderCountTest(CaseJX3SearchPanel):
    def __init__(self):
        self.clientPID = None
        self.Save_SetShanderCount_Path = None
        self.dir_setShaderCount = None
        self.inject_PATH = None
        print(os.getcwd())
        super().__init__()
        print("<os.path.realpath1>:", os.path.realpath(__file__))
        os.chdir("..\\..\\public")  # 修改当前工作目录
        print("<os.path.realpath2>:", os.path.realpath(__file__))
        self.Save_Log_Path = None
        self.new_jx3_log_path = None
        self.JX3_LOG_PATH = None
        self.caseName = None
        self.BASE_R3_PATH = None
        self.BIN64_NAME = 'bin64'
        self.saveTime = time.strftime("%Y%m%d", time.localtime())

    # def thread_SearchPanelPerfEyeCtrl(self):
    #     pass
    #
    # def task_process_perfeye_data(self):
    #     pass

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

    def sart_inject(self):
        self.inject_PATH = r'f:/ShaderTest'
        if not os.path.exists(self.inject_PATH):
            disks = psutil.disk_partitions()
            for disk in disks:
                path = disk.mountpoint + 'ShaderTest'
                if os.path.exists(path):
                    self.inject_PATH = path
                    break
        self.inject_PATH = self.inject_PATH + r'\inject.bat'
        print("<os.path.setshader>:", self.inject_PATH)
        os.system(self.inject_PATH)

    def validateCaseName(self, caseName):
        rstr = r"[\/\\\:\*\?\"\<\>\|]"  # '/ \ : * ? " < > |'不能存在于文件夹名或文件名中,因此替换
        new_title = re.sub(rstr, "_", caseName)  # 替换为下划线
        return new_title

    def save_setShaderCount_file(self, dic_args):
        self.dir_setShaderCount = os.path.join(self.CLIENT_PATH, 'SetShaderCount')
        if not os.path.exists(self.dir_setShaderCount):
            os.makedirs(self.dir_setShaderCount)  # 创建路径

        self.caseName = dic_args['CaseName']  # 问题用例
        caseName = self.validateCaseName(self.caseName)
        CaseInfo = {'SaveTime': self.saveTime, 'CaseName': caseName}
        self.Save_SetShanderCount_Path = self.dir_setShaderCount
        for key in CaseInfo:
            self.Save_SetShanderCount_Path = os.path.join(self.Save_SetShanderCount_Path, CaseInfo[key])
            if not os.path.exists(self.Save_SetShanderCount_Path):
                os.makedirs(self.Save_SetShanderCount_Path)  # 创建路径

        cur_time = time.strftime('%Y%m%d_%H%M%S', time.localtime())
        file_setShaderCount = os.path.join(self.CLIENT_PATH, 'SetShaderCount.txt')
        new_file_name = self.CLIENT_PATH + '\\SetShaderCount' + cur_time + '.txt'
        os.rename(file_setShaderCount, new_file_name)
        filecontrol_copyFileOrFolder(new_file_name, self.Save_SetShanderCount_Path)
        filecontrol_deleteFileOrFolder(new_file_name)



    def find_jx3_log(self):
        # disks = psutil.disk_partitions()
        # for disk in disks:
        #     path = disk.mountpoint + 'trunk' + '\\client\\logs\\JX3Client_2052-zhcn'
        #     if os.path.exists(path):
        #         self.JX3_LOG_PATH = path
        #         break
        new_jx3_log_path = self.find_new_file(self.CLIENT_LOG_PATH)
        return new_jx3_log_path

    def run_local(self, dic_args):  # 用例的主体（入口）函数，dic_args是从IQB平台传来的参数字典

        super().run_local(dic_args)
        self.save_setShaderCount_file(dic_args)  # 处理生成的setshader文件


if __name__ == '__main__':
    setshader_test = SetShaderCountTest()
    setshader_test.run_from_IQB()

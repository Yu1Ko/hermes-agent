# -*- coding: utf-8 -*-

from CaseJX3Client import *
import os
import traceback
import psutil
class CaseSleep(CaseJX3Client):
    def __init__(self):
        super().__init__()

    def run_local(self, dic_args):
        self.check_dic_args(dic_args)  # 处理传进来的参数
        self.loadDataFromLocalConfig(dic_args)  # 读LocalConfig配置
        self.device_cooling()

if __name__ == '__main__':
    obj_test = CaseSleep()
    obj_test.run_from_IQB()

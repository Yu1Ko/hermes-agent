# -*- coding: utf-8 -*-
import psutil
from CaseCommon import *
from BaseToolFunc import *


class GetClientAndOptDatePath(CaseCommon):

    def __init__(self):
        super().__init__()  # 父类初始化

    def set_client_path(self, clientType):
        if clientType == 'trunk':
            self.BASE_PATH = r'f:/trunk'
            if not os.path.exists(self.BASE_PATH):
                disks = psutil.disk_partitions()
                for disk in disks:
                    path = disk.mountpoint + 'trunk'
                    if os.path.exists(path):
                        self.BASE_PATH = path
                        break
            self.CLIENT_PATH = self.BASE_PATH + r'/client'
        elif clientType == 'trunk_classic':
            self.BASE_PATH = r'f:/trunk_classic'
            if not os.path.exists(self.BASE_PATH):
                disks = psutil.disk_partitions()
                for disk in disks:
                    path = disk.mountpoint + 'trunk_classic'
                    if os.path.exists(path):
                        self.BASE_PATH = path
                        break
            self.CLIENT_PATH = self.BASE_PATH + r'/client'

        self.clientType = clientType

    def set_opt_data_path(self):
        self.OPT_DIRPATH = os.path.join(self.CLIENT_PATH, 'opt数据')
        if not os.path.exists(self.OPT_DIRPATH):
            os.makedirs(self.OPT_DIRPATH)  # 创建路径
        self.initial_optName = ''  # 最初文件名


    def run_local(self, dic_args):
        self.set_client_path(dic_args['clientType'])  # 指定客户端位置
        self.set_opt_data_path()  # 设置"opt数据"文件夹


if __name__ == '__main__':
    obj = GetClientAndOptDatePath()
    obj.run_from_IQB()

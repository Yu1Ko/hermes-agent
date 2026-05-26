# -*- coding: utf-8 -*-
import psutil
from SendMsgRobot import push_report
from opt_data_report import OptDataReport
from GetClientAndOptDatePath import *

class AutoGetOptDataReport(GetClientAndOptDatePath):

    def __init__(self):
        super().__init__()  # 父类初始化

    def find_opt_data_path(self):
        self.OPT_DIRPATH = os.path.join(self.CLIENT_PATH, 'opt数据')

    def find_opt_path(self):

        optfile = []
        for file in os.listdir(self.OPT_DIRPATH):
            if os.path.splitext(file)[1] == '.opt':  # 查找.opt文件
                sourcefile = os.path.join(self.OPT_DIRPATH, file)  # opt路径
                optfile.append(sourcefile)
        if len(optfile) != 0:
            optfile.sort(key=lambda fn: os.path.getmtime(fn))  # 文件修改时间按升序排序
            self.opt_path = optfile[-1]
            return True
        else:
            return False


    def run_local(self, dic_args):
        self.set_client_path(dic_args['clientType'])  # 指定客户端位置
        self.find_opt_data_path()  # 找到"opt数据"文件夹
        opt_path = self.find_opt_path()
        if not opt_path:
            return
        xx = OptDataReport(self.opt_path)
        xx.run()

        push_report(machine_get_IPAddress(), 'opt报表已经生成啦')

if __name__ == '__main__':
    obj = AutoGetOptDataReport()
    obj.run_from_IQB()

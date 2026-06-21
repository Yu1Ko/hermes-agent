# -*- coding: utf-8 -*-
import psutil
from CaseCommon import *
from BaseToolFunc import *


class AutoCopyOpt(CaseCommon):
    def __init__(self):
        super().__init__()  # 父类初始化
        self.BASE_PATH = r'f:/trunk'
        if not os.path.exists(self.BASE_PATH):
            disks = psutil.disk_partitions()
            for disk in disks:
                path = disk.mountpoint + 'trunk'
                if os.path.exists(path):
                    self.BASE_PATH = path
                    break
        self.CLIENT_PATH = self.BASE_PATH + r'/client'

        self.OPT_DIRPATH = os.path.join(self.CLIENT_PATH, 'opt数据')
        if not os.path.exists(self.OPT_DIRPATH):
            os.makedirs(self.OPT_DIRPATH)  # 创建路径
        self.initial_optName = ''  # 最初文件名

    def find_new_optfile(self):
        optfile = []
        for file in os.listdir(self.CLIENT_PATH):
            if os.path.splitext(file)[1] == '.opt':  # 查找.opt文件
                sourcefile = os.path.join(self.CLIENT_PATH, file)  # opt路径
                optfile.append(sourcefile)  # ['xxx.opt','yyy.opt']
        if len(optfile) != 0:
            optfile.sort(key=lambda fn: os.path.getmtime(fn))  # 文件修改时间按升序排序
            NewOpt_FilePath = optfile[-1]
            if not os.path.isfile(NewOpt_FilePath):
                info = "%s not exist!" % (NewOpt_FilePath)
                self.log.error(info)
            else:
                fpath, self.initial_optName = os.path.split(NewOpt_FilePath)  # 分离文件名和路径
                New_FilePath = os.path.join(self.OPT_DIRPATH, self.initial_optName)
                shutil.move(NewOpt_FilePath, New_FilePath)  # 复制文件
                return New_FilePath
        else:
            return False

    def modify_opt_filename(self, dic_args):

        new_optfile = self.find_new_optfile()  # 获取最新的opt文件(最初文件名）

        if not new_optfile:
            return

        OptName = dic_args[
                      'OptName'] + self.initial_optName if "OptName" in dic_args else self.initial_optName  # 获取参数OptName的值
        new_optname = os.path.join(self.OPT_DIRPATH, OptName)  # 拼接新的文件名

        try:
            os.rename(new_optfile, new_optname)  # 修改文件名
        except Exception as e:
            self.log.error(e)

    def run_local(self, dic_args):  # 用例的主体（入口）函数，dic_args是从IQB平台传来的参数字典
        self.modify_opt_filename(dic_args)


if __name__ == '__main__':
    obj_test = AutoCopyOpt()
    obj_test.run_from_IQB()

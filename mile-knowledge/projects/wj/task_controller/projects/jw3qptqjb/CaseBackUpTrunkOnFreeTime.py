# coding=utf-8
from CaseCommon import *
from BaseToolFunc import *


class CaseBackUpTrunkOnFreeTime(CaseCommon):  # 用例名字需要和文件名一致！ 所有用例需要继承CaseCommon类

    def __init__(self):
        CaseCommon.__init__(self)  # 父类初始化

    def run_local(self, dic_args):  # 用例的主体（入口）函数，dic_args是从IQB平台传来的参数字典
        if 'h1' not in dic_args:
            h1 = 2
        else:
            h1 = dic_args['h1']
        if 'h2' not in dic_args:
            h2 = 6
        else:
            h2 = dic_args['h2']
        while 1:
            time.sleep(1)
            try:
                # 判断时间
                H = int(time.strftime("%H", time.localtime()))
                if not (h1 <= H < h2):
                    continue
                # 检查版本号

                # 更新
                # 找trunk地址 重制版
                self.CLIENT_PATH = None
                disks = psutil.disk_partitions()
                for disk in disks:
                    path = disk.mountpoint + 'trunk' + '\\client'
                    if os.path.exists(path):
                        self.CLIENT_PATH = path
                        break
                if self.CLIENT_PATH:
                    self.log.info(u'Find Trunk:{}'.format(self.CLIENT_PATH))
                    svn_cmd_cleanup(self.CLIENT_PATH)
                    svn_cmd_update(self.CLIENT_PATH)
                    svn_cmd_revert(self.CLIENT_PATH)
                    svn_cmd_cleanup(self.CLIENT_PATH)
                else:
                    self.log.warning(u'Not Find Trunk')

                # 找trunk_mobile_BD地址
                self.CLIENT_PATH = None
                disks = psutil.disk_partitions()
                for disk in disks:
                    path = disk.mountpoint + 'trunk_mobile_BD' + '\\client'
                    if os.path.exists(path):
                        self.CLIENT_PATH = path
                        break
                if not self.CLIENT_PATH:
                    self.log.warning(u'Not Find Trunk')
                    continue
                self.log.info(u'Find Trunk:{}'.format(self.CLIENT_PATH))
                svn_cmd_cleanup(self.CLIENT_PATH)
                svn_cmd_update(self.CLIENT_PATH)
                svn_cmd_revert(self.CLIENT_PATH)
                svn_cmd_cleanup(self.CLIENT_PATH)
            except Exception as e:
                info = traceback.format_exc()
                logging.error(info)


if __name__ == '__main__':
    ob = CaseBackUpTrunkOnFreeTime()
    ob.run_from_IQB()




import time
import datetime
import sys
sys.path.append(r'../../../')
from CaseJX3SearchPanel import CaseJX3SearchPanel
from CaseJX3Client import *
from PerfeyeCtrl import *
from HotPointMapCtrl import *
from XGameSocketClient import *



class wait_until_time(CaseJX3Client):
    def __init__(self):
        super().__init__()

    def wait(self, dic_args):
        while True:
            # 获取当前时间
            current_time = datetime.datetime.today()
            # 结束时间
            end_time_str = dic_args.get("end_time")
            if not end_time_str:
                self.log.info("end_time 参数未提供")
                return
            end_time = datetime.datetime.strptime(end_time_str, "%H:%M:%S").time()
            
            # 打印当前时间
            print(f"当前时间: {current_time}")
            self.log.info(f"当前时间: {current_time}")
            

            if current_time.time() > end_time:
                print(f"当前时间已超过{end_time_str}，结束循环。")
                self.log.info(f"当前时间已超过{end_time_str}，结束循环。")
                return
            
            # 等待3秒
            time.sleep(3)
            
    def run_local(self, dic_args):
        self.check_dic_args(dic_args)  # 处理传进来的参数
        self.loadDataFromLocalConfig(dic_args)  # 读LocalConfig配置
        self.wait(dic_args)

if __name__ == '__main__':
    obj_test = wait_until_time()
    obj_test.run_from_IQB()

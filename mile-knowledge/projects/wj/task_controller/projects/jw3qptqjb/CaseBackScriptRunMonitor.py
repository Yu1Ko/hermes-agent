# -*- coding: utf-8 -*-

from CaseCommon import *
import os
import traceback
import psutil


class CaseBackScriptRunMonitor(CaseCommon):
    def __init__(self):
        super().__init__()
        self.TEARDOWMFLAG = False

    def run_local(self, dic_args):
        try:
            scriptPath = dic_args["scriptPath"]  # 脚本名字
            code = dic_args["code"]  # python
            scriptName = os.path.basename(scriptPath)
            scriptDir = os.path.dirname(scriptPath)
            while 1:
                if self.TEARDOWMFLAG == True:
                    break
                time.sleep(10)
                flag = False
                for proc in psutil.process_iter():
                    try:
                        if "SYSTEM" not in proc.username():  # 除了系统的全部遍历
                            # 命令行是否相等
                            # if list_line[0] == code and list_line[1] == scriptName:
                            if scriptName in proc.cmdline() or scriptPath in proc.cmdline():
                                flag = True
                    except Exception as e:
                        pass
                # 在命令行找不到的话就重启被监控脚本
                if flag == False:
                    os.chdir(scriptDir)
                    os.system("start %s %s" % (code, scriptName))

                    self.log.info("%s not exit" % scriptName)
                    self.log.info("restart %s" % scriptName)
                    send_Subscriber_msg(
                        machine_get_IPAddress(),
                        scriptName + '已重新运行'
                    )
        except Exception:
            info = traceback.format_exc()
            self.log.error(info)

    def teardown(self, dic_args):
        # 这里写上销毁清理工作，可以让工作线程安全退出的工作
        self.TEARDOWMFLAG = True
        pass


if __name__ == '__main__':
    obj_test = CaseBackScriptRunMonitor()
    obj_test.run_from_IQB()

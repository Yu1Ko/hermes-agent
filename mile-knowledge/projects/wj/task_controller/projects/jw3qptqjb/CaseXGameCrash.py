# -*- coding: utf-8 -*-
import os.path
import time

from CaseTDR import *
import getpass

class CaseXGameCrash(CaseTDR):
    def __init__(self):
        super().__init__()
        self.name = None
        self.bDumpCase=True #宕机用例

    def process_tss(self):
        tss = self.CLIENT_PATH + r'\bin64\tss_api.dll'
        if os.path.exists(tss):
            os.remove(tss)

    def thread_PressEnterToLogin(self, dicSwitch, t_parent, old_f, RUN_CLIENT_LOG_PATH):
        pass

    def check_dic_args(self, dic_args):
        dic_args['nTimeout'] = 99999999
        self.needKillDeath = True
        super().check_dic_args(dic_args)
        #self.exename = 'JX3Debugger.exe'

    '''
    def processInterface(self, dic_args):
        #XGame临时处理
        # 拷贝Interface文件夹
        TEMP_FOLDER = 'TempFolder'
        filecontrol_deleteFileOrFolder(self.INTERFACE_PATH)
        filecontrol_copyFileOrFolder(SERVER_PATH + '/XGame/Interface', TEMP_FOLDER + '/Interface')
        ini_set("Interface","Type",self.runMapType,TEMP_FOLDER + '/Interface/SearchPanel/Interface.ini')
        self.log.info(self.runMapType)
        return
'''

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

    def start_client_test(self, dic_args):
        if not self.bMobile:
            #覆写此方法，用debugger启动剑三
            root = os.path.dirname(os.path.abspath(__file__)).split('\\')[0]
            path_config_debugger = os.path.join(root, os.sep, 'Jx3Debugger', 'config.ini')
            path_JX3Client=os.path.join(self.CLIENT_PATH,self.BIN64_NAME,self.exename)
            ini_set('Debugger', 'process_absolute_path', path_JX3Client, path_config_debugger)
            run_path = os.path.join(root, os.sep, 'Jx3Debugger')
            exe = os.path.join(run_path, 'JX3Debugger.exe')
            # 后台任务中有宕机处理脚本，如果他们没有处理完，则等待120s。
            dumpFlagFilePath1 = os.path.join(run_path, 'dumpIsProcessing')
            dumpFlagFilePath2 = os.path.join(self.CLIENT_PATH, self.BIN64_NAME, 'minidump', 'dumpIsProcessing')
            t = time.time()
            while os.path.exists(dumpFlagFilePath1) or os.path.exists(dumpFlagFilePath2):
                self.log.info('dumpIsProcessing, wait')
                time.sleep(1)
                if time.time() - t > 120:
                    info = 'time out! dumpIsProcessing'
                    self.log.info(info)
                    os._exit(0)
            pp =win32_runExe_no_wait(exe, run_path)

            #self.clientPID = pp.pid
            time.sleep(1)
            while not self.clientPID:
                try:
                    self.clientPID=win32_findProcessByName(self.exename)[0].pid
                    self.log.info(f'Client pid:{self.clientPID}')
                except:
                    self.log.info("获取 client Pid中")
                    time.sleep(1)
                    pass
            self.process_threads_activeWindow()  # 让客户都安处于顶层
            self.nClientStartTime = int(time.time())
        else:
            super().start_client_test(dic_args)

    def teardown(self):
        if not self.bMobile:
            win32_kill_process('JX3Debugger.exe')
        super().teardown()
        send_Subscriber_msg(self.strGuid, f"用例:{self.strCaseName} 运行时长: {int(self.nClientRunTime / 60)}分钟")


def AutoRun(dic_parameters):
    global obj_test
    obj_test = CaseXGameCrash()
    obj_test.run_from_uauto(dic_parameters)


if __name__ == '__main__':
    obj_test = CaseXGameCrash()
    obj_test.run_from_IQB()
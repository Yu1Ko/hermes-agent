# -*- coding: utf-8 -*-
from CaseJX3SearchPanel import *
import getpass

class CaseCrash(CaseJX3SearchPanel):
    def __init__(self):
        super().__init__()
        self.name = None


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
        self.exename = 'JX3Debugger.exe'

    def processInterface(self, dic_args):
        #XGame临时处理
        if 'XGame' in self.clientType:
            # 拷贝Interface文件夹
            TEMP_FOLDER = 'TempFolder'
            filecontrol_deleteFileOrFolder(self.INTERFACE_PATH)
            filecontrol_copyFileOrFolder(SERVER_PATH + '/XGame/Interface', TEMP_FOLDER + '/Interface')
            ini_set("Interface","Type",self.runMapType,TEMP_FOLDER + '/Interface/SearchPanel/Interface.ini')
            self.log.info(self.runMapType)
            return

        def copyInterface(plugName):
            src = os.path.join(SERVER_PATH, 'interface\\{}'.format(plugName))
            dst = os.path.join(self.INTERFACE_PATH, plugName)
            if not os.path.exists(dst):
                os.makedirs(dst)
            filecontrol_copyFileOrFolder(src, dst)
        if 'classic' in self.clientType:
            copyInterface('SwitchMap_classic')
        else:
            copyInterface('WalkExterior')
            copyInterface('SwitchMap')

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

    def run_local(self, dic_args):
        self.check_dic_args(dic_args)  # 处理传进来的参数
        self.setClientPath(dic_args['clientType'])  # 指定客户端位置
        self.process_tss()  #处理反外挂模块
        self.processDxCache()
        #临时去掉jemalloc
        jemalloc = os.path.join(self.CLIENT_PATH, 'bin64', 'jemallocX64.dll')
        filecontrol_deleteFileOrFolder(jemalloc)
        dic_args['nTimeout'] = 604800 #宕机测试，设置超长时间
        if 'classic' in self.clientType:
            src = SERVER_PATH + r'\interface\SwitchMap_classic'
        else:
            src = SERVER_PATH + r'\interface\SwitchMap'
        if 'XGame' not in self.clientType:
            dst = self.INTERFACE_PATH + r'\SwitchMap'
            filecontrol_copyFileOrFolder(src, dst)
        super().run_local(dic_args)
        self.teardown(dic_args)


    def start_client_test(self, dic_args):
        #覆写此方法，用debugger启动剑三
        root = os.path.dirname(os.path.abspath(__file__)).split('\\')[0]
        path_config_debugger = os.path.join(root, os.sep, 'Jx3Debugger', 'config.ini')
        if 'XGame' in self.clientType:
            path_JX3Client = self.CLIENT_PATH + '\\bin64\\JX3ClientX3DX64.exe'
        else:
            path_JX3Client = self.CLIENT_PATH + '\\bin64\\JX3ClientX64.exe'
        ini_set('Debugger', 'process_absolute_path', path_JX3Client, path_config_debugger)
        run_path = os.path.join(root, os.sep, 'Jx3Debugger')
        exe = os.path.join(run_path, 'JX3Debugger.exe')
        # 后台任务中有宕机处理脚本，如果他们没有处理完，则等待120s。
        dumpFlagFilePath1 = os.path.join(run_path, 'dumpIsProcessing')
        dumpFlagFilePath2 = os.path.join(self.CLIENT_PATH, 'bin64', 'minidump', 'dumpIsProcessing')
        t = time.time()
        while os.path.exists(dumpFlagFilePath1) or os.path.exists(dumpFlagFilePath2):
            self.log.info('dumpIsProcessing, wait')
            time.sleep(1)
            if time.time() - t > 120:
                info = 'time out! dumpIsProcessing'
                self.log.info(info)
                os._exit(0)
        win32_runExe(exe, run_path)


    def teardown(self, dic_args):
        win32_kill_process('JX3Debugger.exe')
        super().teardown(dic_args)




if __name__ == '__main__':
    obj_test = CaseCrash()
    obj_test.run_from_IQB()
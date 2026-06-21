# -*- coding: utf-8 -*- 

from CaseJX3Client import *
from PerfeyeCtrl import *

class CaseMinimizLogin(CaseJX3Client):

    def __init__(self):
        super().__init__()

    def thread_login_perfmonctrl(self, t_parent, old_f):
        try:
            while not win32_findProcessByName('JX3ClientX64.exe'):
                if not t_parent.isAlive():
                    return
                time.sleep(1)
            f = getLastLogFile(self.CLIENT_LOG_PATH)
            while old_f == f:
                if not t_parent.isAlive():
                    return
                time.sleep(1)
                f = getLastLogFile(self.CLIENT_LOG_PATH)
            # logger.info(f)
            line = 0
            while f:
                if not t_parent.isAlive():
                    return
                isFoundLSP,line = findStringInLog(f, 'enter LoginServerPanel',line)
                if isFoundLSP:
                    break
                time.sleep(1)

            # self.updatePerfmon()

            time.sleep(10)  #延时等待登录界面加载
            # file_minimiz_login = r'c:\RunMapResult\minimiz_login'
            # with open(file_minimiz_login, 'w') as f:
            #     pass
            self.minimizWindow()

            # perfMonCtrl_start_memtest_v3(self.clientPID, 600) #参数是截图时间间隔
            self.testplus = PerfeyeCreate()
            PerfeyeConnect(self.testplus, self.deviceId)
            PerfeyeStart(self.testplus, self.deviceId, self.clientPID)
            time.sleep(15*60) #采集数据的时长
            # perfMonCtrl_stop_v3(self.clientPID)
            PerfeyeStop(self.testplus, self.deviceId)

            if 'classic' in self.clientType:
                testpoint = 'minimiz_login_classic'
            else:
                testpoint = 'minimiz_login'
            # tags = '档次|机型|配置|地图|测试点|日期'
            subtags = '{0}|{1}|{2}|{3}|{4}|{5}'.format(self.tagVideoLevel, self.tagMachineType,
                                                       self.tagVideoCard, 'login', testpoint,
                                                       date_get_szToday_7())
            path_PerfeyeDataSave = PerfeyeSave(self.testplus, self.deviceId, self.AppKey, subtags)


            process_data_v3(self.tagVideoLevel, self.tagMachineType, self.tagVideoCard, 'login', testpoint,
                            self.CLIENT_PATH, path_PerfeyeDataSave)
            # perfMonCtrl_upload_v3(key=self.AppKey, path=path_PerfeyeDataSave)

            win32_kill_process('JX3ClientX64.exe')
        except:
            info = traceback.format_exc()
            self.log.error(info)


    def teardown(self, dic_args):
        #这里写上销毁清理工作，可以让工作线程安全退出的工作
        super().teardown(dic_args)
        file_minimiz = r'c:\RunMapResult\minimiz_login'
        filecontrol_deleteFileOrFolder(file_minimiz)
        file_minimiz = r'c:\RunMapResult\minimiz'
        filecontrol_deleteFileOrFolder(file_minimiz)


    def run_local(self, dic_args):
        self.check_dic_args(dic_args)
        self.loadDataFromLocalConfig(dic_args)
        
        self.setClientPath(dic_args['clientType'])
        self.copyPerfeye()
        file_minimiz = r'c:\RunMapResult\minimiz_login'
        filecontrol_deleteFileOrFolder(file_minimiz)
        file_minimiz = r'c:\RunMapResult\minimiz'
        filecontrol_deleteFileOrFolder(file_minimiz)

        #关自动登录
        try:
            ini_set('Automation', 'Switch', 0, self.CLIENT_PATH + '/Automation.ini')
        except Exception as e:
            pass
        
        old_f = getLastLogFile(self.CLIENT_LOG_PATH)
        t = threading.Thread(target=self.thread_login_perfmonctrl, args=(threading.currentThread(), old_f,))
        self.listThreads_beforeStartClient.append(t)
        self.process_threads_beforeStartClient()
        self.start_client_test(dic_args)


if __name__ == '__main__':
    obj_test = CaseMinimizLogin()
    obj_test.run_from_IQB()
# -*- coding: utf-8 -*- 


from CaseJX3Client import *
from PerfeyeCtrl import *

class CaseJX3Login(CaseJX3Client):

    def __init__(self):
        super().__init__()

    def thread_login_perfctrl(self, t_parent, old_f):
        try:
            ini_set('Automation', 'Switch', 3, os.path.join(self.CLIENT_PATH, 'Automation.ini'))
            while not win32_findProcessByName('JX3ClientX64.exe'):
                if not t_parent.isAlive():
                    # print 't_parent is dead'
                    return
                time.sleep(1)
                # print 'finding jx3'
            f = getLastLogFile(self.CLIENT_LOG_PATH)
            while old_f == f:
                # print old_f, f
                if not t_parent.isAlive():
                    # print 't_parent is dead'
                    return
                time.sleep(1)
                # print 'finding log'
                f = getLastLogFile(self.CLIENT_LOG_PATH)
            # logger.info(f)
            line = 0
            while f:
                if not t_parent.isAlive():
                    # print 't_parent is dead'
                    return
                isFoundLSP,line =findStringInLog(f, 'enter LoginServerPanel',line)
                if isFoundLSP:
                    break
                time.sleep(1)
                # print 'wait enter login screen'
            # print 'wait to go'
            # self.updatePerfmon()
            time.sleep(10)  #延时等待登录界面加载 最小化才执行这里，本用例是复制的CaseMinimizLogin
            # file_minimiz_login = r'c:\RunMapResult\minimiz_login'
            # with open(file_minimiz_login, 'w') as f:
            #     pass

            # perfMonCtrl_start_v3(self.clientPID, 30) # 参数是截图时间间隔
            self.testplus = PerfeyeCreate()
            PerfeyeConnect(self.testplus, self.deviceId)
            PerfeyeStart(self.testplus, self.deviceId, self.clientPID)
            time.sleep(3*60)  # 采集数据的时长
            # perfMonCtrl_stop_v3(self.clientPID)
            PerfeyeStop(self.testplus, self.deviceId)

            testpoint = 'login'
            map = '登录界面'
            # tags = '档次|机型|配置|地图|测试点|日期'
            subtags = '{0}|{1}|{2}|{3}|{4}|{5}'.format(self.tagVideoLevel, self.tagMachineType,
                                                       self.tagVideoCard, map, testpoint,
                                                       date_get_szToday_7())
            path_PerfeyeDataSave = PerfeyeSave(self.testplus, self.deviceId, self.AppKey, subtags)

            process_data_v3(self.tagVideoLevel, self.tagMachineType, self.tagVideoCard, map, testpoint,
                            self.CLIENT_PATH, path_PerfeyeDataSave)
            # perfMonCtrl_upload_v3(key=self.AppKey, path=path_PerfeyeDataSave)

            # if 'classic' in self.clientType:
            #     perfMonCtrl_process_data_ex_classic_v3('登录界面', 'login', self.CLIENT_PATH)
            # else:
            #     perfMonCtrl_process_data_ex_v3('登录界面', 'login', self.CLIENT_PATH)
            # win32_kill_process('GPU-Z.exe')
            #
            #
            # if 'classic' in self.clientType:
            #     perfMonCtrl_upload_v3(key='jx3classic')
            # else:
            #     perfMonCtrl_upload_v3()
            ini_set('Automation', 'Switch', 1, os.path.join(self.CLIENT_PATH, 'Automation.ini'))
            win32_kill_process('JX3ClientX64.exe')
        except Exception as e:
            info = traceback.format_exc()
            self.log.error(info)
            os._exit(1)


    def teardown(self, dic_args):
        #这里写上销毁清理工作，可以让工作线程安全退出的工作
        super().teardown(dic_args)
        file_minimiz = r'c:\RunMapResult\minimiz_login'
        filecontrol_deleteFileOrFolder(file_minimiz)
        file_minimiz = r'c:\RunMapResult\minimiz'
        filecontrol_deleteFileOrFolder(file_minimiz)
        ini_set('Automation', 'Switch', 1, os.path.join(self.CLIENT_PATH, 'Automation.ini'))



    def run_local(self, dic_args):
        self.check_dic_args(dic_args)
        self.setClientPath(dic_args['clientType'])
        self.clearInfoFiles()
        self.loadDataFromLocalConfig(dic_args)

        old_f = getLastLogFile(self.CLIENT_LOG_PATH)
        t = threading.Thread(target=self.thread_login_perfctrl, args=(threading.currentThread(), old_f,))
        self.listThreads_beforeStartClient.append(t)
        self.process_threads_beforeStartClient()
        self.start_client_test(dic_args)
        self.teardown(dic_args)


if __name__ == '__main__':
    obj_test = CaseJX3Login()
    obj_test.run_from_IQB()
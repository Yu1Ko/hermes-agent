# -*- coding: utf-8 -*-
# import sys
# sys.path.append('..')
from CaseJX3Client import *
from PerfeyeCtrl import *

class CaseJX3Resize(CaseJX3Client):
    def __init__(self):
        super(CaseJX3Resize, self).__init__()

    def check_dic_args(self, dic_args):
        super().check_dic_args(dic_args)
        if 'deviceId' in dic_args:
            self.deviceId = dic_args['deviceId']
        else:
            self.deviceId = 'localhost'
        
    def loadDataFromLocalConfig(self, dic_args):
        super().loadDataFromLocalConfig(dic_args)
        self.strMachineName = ini_get('local', 'machine_id', self.pathLocalConfig)
        if 'classic' in self.clientType:
            video_name = {'3': '极简',
                          '4': '简约',
                          '5': '高效',
                          '6': '经典',
                          '7': '电影'
                          }
            self.strNumVideoLevel = ini_get('perfmon_info_classic', 'video_level', self.pathLocalConfig)
            self.tagVideoLevel = video_name[self.strNumVideoLevel]
            self.tagMachineType = ini_get('perfmon_info_classic', 'machine_type', self.pathLocalConfig)
            self.tagVideoCard = ini_get('perfmon_info_classic', 'video_card', self.pathLocalConfig)
        else:
            self.tagVideoLevel = ini_get('perfmon_info', 'video_level', self.pathLocalConfig)
            self.tagMachineType = ini_get('perfmon_info', 'machine_type', self.pathLocalConfig)
            self.tagVideoCard = ini_get('perfmon_info', 'video_card', self.pathLocalConfig)

    def windows_resize(self, _win_x, _win_y, _win_width, _win_height):
        handle = win32gui.FindWindow('KGWin32App', None)
        win32gui.MoveWindow(handle, _win_x, _win_y, _win_width, _win_height, 1)

    # 在 timeLimit 秒内执行resize
    def windows_resize_in_time(self,timeLimit):
        win_width = 800
        win_height = 450
        flag_width=16
        flag_height=9
        startTime=time.time()
        while True:

            # 控制放大缩小
            win_width += flag_width
            win_height += flag_height
            if win_width >= 1920:
                flag_width=-16
            if win_height >= 1080:
                flag_height=-9
            if win_height<450:
                flag_width=16
            if win_width<800:
                flag_height=9
            self.windows_resize(30, 30, win_width, win_height)

            # 控制时间
            if (time.time()-startTime)>=timeLimit :
                break
    
    
    def thread_resize(self, t_parent, old_f):
        while not win32_findProcessByName('JX3ClientX64.exe'):
            if not t_parent.isAlive():
                return
            time.sleep(1)
        # 关闭自动登陆
        fAutomation = os.path.join(self.CLIENT_PATH, 'Automation.ini')
        if os.path.exists(fAutomation):
            ini_set('Automation', 'Switch', 0, fAutomation)
        f = getLastLogFile(self.CLIENT_LOG_PATH)
        while old_f == f:
            if not t_parent.isAlive():
                return
            time.sleep(1)
            f = getLastLogFile(self.CLIENT_LOG_PATH)
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
        # perfMonCtrl_start_v3(self.clientPID, 10)
        self.testplus = PerfeyeCreate()
        PerfeyeConnect(self.testplus, self.deviceId)
        PerfeyeStart(self.testplus, self.deviceId, self.clientPID)

        try:
            # 开始resize，执行30秒后退出
            self.windows_resize_in_time(60)
        except Exception as e:
            info = traceback.format_exc()
            self.log.error(info)

        # perfMonCtrl_stop_v3(self.clientPID)
        PerfeyeStop(self.testplus, self.deviceId)


        if 'classic' in self.clientType:
            testpoint = 'resize_classic'
        else:
            testpoint = 'resize'
        # tags = '档次|机型|配置|地图|测试点|日期'
        subtags = '{0}|{1}|{2}|{3}|{4}|{5}'.format(self.tagVideoLevel, self.tagMachineType,
                                                   self.tagVideoCard, 'login', testpoint,
                                                   date_get_szToday_7())
        path_PerfeyeDataSave = PerfeyeSave(self.testplus, self.deviceId, self.AppKey, subtags)


        process_data_v3(self.tagVideoLevel, self.tagMachineType, self.tagVideoCard, 'login', testpoint,
                        self.CLIENT_PATH, path_PerfeyeDataSave)
        # perfMonCtrl_upload_v3(key=self.AppKey, path = path_PerfeyeDataSave)

        win32_kill_process('JX3ClientX64.exe')


    def run_local(self, dic_args):
        self.check_dic_args(dic_args)
        self.setClientPath(dic_args['clientType'])
        self.loadDataFromLocalConfig(dic_args)
        old_f = getLastLogFile(self.CLIENT_LOG_PATH)
        t = threading.Thread(target=self.thread_resize, args=(threading.currentThread(), old_f,))
        self.listThreads_beforeStartClient.append(t)
        self.process_threads_beforeStartClient()
        self.start_client_test(dic_args)


if __name__ == '__main__':
    obj = CaseJX3Resize()
    obj.run_from_IQB()
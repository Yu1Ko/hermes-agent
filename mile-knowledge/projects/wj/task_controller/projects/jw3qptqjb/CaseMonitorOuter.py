# -*- coding: utf-8 -*- 
from CaseJX3Client import *
from CaseJX3SearchPanel import *
from BaseToolFunc import *
import datetime


class CaseMonitorOuter(CaseJX3SearchPanel):
    def __init__(self):
        super().__init__()

    def thread_MonitorOuter_perfmonctrl(self, t_parent, old_f):
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
            isFoundCD,line = findStringInLog(f, gbk('enter scene "成都"'),line)
            if isFoundCD:
                break
            info = 'waiting log to find chengdu'
            self.log.info(info)
            time.sleep(1)
        # self.updatePerfmon()
        time.sleep(30)  #延时等待



        time_now = datetime.datetime.now()


        while True:
            try:
                PerfeyeStart(self.testplus, self.deviceId, self.clientPID, screenshot_interval = 1800)
                last_H = time_now.hour
                while True:
                    time_now = datetime.datetime.now()
                    hour = time_now.hour
                    # print last_H
                    if hour != last_H:

                        break
                    time.sleep(60)

                PerfeyeStop(self.testplus, self.deviceId)
                # perfMonCtrl_process_data_v3(self.tagVideoLevel, self.tagMachineType, self.tagVideoCard,
                #                             '成都', 'monitor_outer_{}'.format(last_H), self.CLIENT_PATH)

                # perfMonCtrl_upload_v3()
                # tags = '档次|机型|配置|地图|测试点|日期'
                subtags = '{0}|{1}|{2}|{3}|{4}|{5}'.format(self.tagVideoLevel, self.tagMachineType,
                                                           self.tagVideoCard, '成都', 'monitor_outer_{}'.format(last_H),
                                                           date_get_szToday_7())
                path_PerfeyeDataSave = PerfeyeSave(self.testplus, self.deviceId, self.AppKey, subtags)

                # process_data_v3(self.tagVideoLevel, self.tagMachineType, self.tagVideoCard, '成都',
                #                 'monitor_outer_{}'.format(last_H),
                #                 self.CLIENT_PATH, path_PerfeyeDataSave)
                # perfMonCtrl_upload_v3(key=self.AppKey, path=path_PerfeyeDataSave)
                if hour == 7:
                    win32_kill_process('JX3ClientX64.exe')
                    break

            except Exception as e:
                info = traceback.format_exc()
                self.log.error(info)
                os._exit(1)
                break

    def check_dic_args(self, dic_args):
        dic_args['nTimeout'] = 99999999
        self.needKillDeath = True
        super().check_dic_args(dic_args)

    def add_thread_for_searchPanel(self, dic_args):
        old_f = getLastLogFile(self.CLIENT_LOG_PATH)
        t = threading.Thread(target=self.thread_MonitorOuter_perfmonctrl, args=(threading.currentThread(), old_f,))
        self.listThreads_beforeStartClient.append(t)
        super(CaseMonitorOuter, self).add_thread_for_searchPanel(dic_args)

    def processServerlist(self, dic_args):
        #do nothing
        pass

    def task_process_perfeye_data(self):
        #do nothing
        pass

if __name__ == '__main__':
    oob = CaseMonitorOuter()
    oob.run_from_IQB()


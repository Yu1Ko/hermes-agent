# -*- coding: utf-8 -*-
from CaseJX3SearchPanel import *

class CaseJX3PictureMonitor(CaseJX3SearchPanel):
    def __init__(self):
        super(CaseJX3PictureMonitor, self).__init__()
        self.listPicPath = []

    def thread_SearchPanelClientPrintScreen(self, dicSwitch, t_parent):
        try:
            appkey = 'jx3hd'
            if 'x3d' in self.clientType:
                appkey = 'jx3x3d'
            screenshot_path = os.path.join(self.CLIENT_PATH, 'ScreenShot')
            if os.path.exists(screenshot_path):
                for x in os.listdir(screenshot_path):
                    pic_path = os.path.join(screenshot_path, x)
                    filecontrol_deleteFileOrFolder(pic_path)
            while t_parent.is_alive():
                time.sleep(1)
                # x = printscreen2('C:\\RunMapResult')
                filepath = 'C:\\RunMapResult\\PrintScreen'
                if os.path.exists(filepath):
                    self.log.info('find file:{}'.format(filepath))
                    screenshot_path = os.path.join(self.CLIENT_PATH, 'ScreenShot')
                    os.remove(filepath)
                    if 'x3d' in self.clientType:
                        exe_shot = os.path.join(PERFMON_PATH_LOCAL, 'printscreen.exe')
                        cmd = '{} {}'.format(exe_shot, screenshot_path)
                        os.system(cmd)
                    # x = printscreen2('C:\\RunMapResult')
                    # if x:
                    #     self.listPicPath.append(x)
                    #     self.log.info(x)

                    if os.path.exists(screenshot_path):
                        for x in os.listdir(screenshot_path):
                            pic_path = os.path.join(screenshot_path, x)
                            self.listPicPath.append(pic_path)
                            self.log.info(pic_path)
                            break
                filepath = 'C:\\RunMapResult\\PrintScreenEnd'
                if os.path.exists(filepath):
                    self.log.info('find file:{}'.format(filepath))
                    os.remove(filepath)
                    # process data to upload
                    process_data_picmonitor(self.listPicPath, appkey, dicSwitch['testpoint'], time.strftime("%Y-%m-%d",time.localtime()))
                filepath = 'C:\\RunMapResult\\PrintScreenUp'
                if os.path.exists(filepath):
                    self.log.info('find file:{}'.format(filepath))
                    os.remove(filepath)
                    upload_new()
        except Exception as e:
            info = traceback.format_exc()
            self.log.error(info)

    def add_thread_for_searchPanel(self, dic_args):
        super(CaseJX3PictureMonitor, self).add_thread_for_searchPanel(dic_args)
        dicSwitch = dic_args

        t = threading.Thread(target=self.thread_SearchPanelClientPrintScreen, args=(dicSwitch, threading.currentThread(),))
        self.listThreads_beforeStartClient.append(t)

    def check_dic_args(self, dic_args):
        super(CaseJX3PictureMonitor, self).check_dic_args(dic_args)
        if 'mapid' not in dic_args:
            raise Exception('need arg: mapid')
        if 'SetPosition' not in dic_args:
            raise Exception('need arg: SetPosition')
        if 'SetCameraStatus' not in dic_args:
            raise Exception('need arg: SetCameraStatus')

    def processSearchPanelTab(self, dic_args):
        super(CaseJX3PictureMonitor, self).processSearchPanelTab(dic_args)
        dst = self.SEARCHPANEL_PATH + '\\RunMap.tab'
        mapid = str(dic_args['mapid'])
        SetPosition = str(dic_args['SetPosition'])
        SetCameraStatus = str(dic_args['SetCameraStatus'])
        sChange = []
        sChange.append(['_mapid_', mapid])
        sChange.append(['_SetPosition_', SetPosition])
        sChange.append(['_SetCameraStatus_', SetCameraStatus])
        for each_yield in sChange:
            changeStrInFile(dst, each_yield[0], each_yield[1])


if __name__ == '__main__':
    obj_test = CaseJX3PictureMonitor()
    obj_test.run_from_IQB()
    #os.popen("pause")
    #{'mapid': '108', 'testpoint': 'maincity', 'casename': 'CrashTest_CoinShop_new.tab'}
    pass
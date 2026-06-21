# -*- coding: utf-8 -*-
import os.path
import re
import time

import CaseCommon
from CaseXGameGetPackage import *

class CaseXGameGetPackage_pakv5(CaseXGameGetPackage):
    def __init__(self):
        super().__init__()


    def check_dic_args(self, dic_args):
        super().check_dic_args(dic_args)
        'httpVersion'








    def set_package(self):
        if not self.bOverlay and self.mobile_device.find_app():
            self.mobile_device.kill_app()
            self.mobile_device.uninstall_app()
            self.log.info('uninstall_app')
        time.sleep(10)
        self.mobile_device.install_app(os.path.join(os.path.dirname(os.path.realpath(__file__)), 'TempFolder', 'RunMap.' + self.file_type),False)
        time.sleep(30)
        self.log.info('app install success')
        self.bCanStartApp=True


        #mobile_install_app(os.path.join(os.path.dirname(os.path.realpath(__file__)),'TempFolder','RunMap.'+self.file_type),self.deviceId)
        #time.sleep(10)
        #self.log.info("set_package success")
        # 启动apk
        #res = mobile_start_app(self.package, self.deviceId)
        #time.sleep(60)
        # 关闭apk
        #mobile_kill_app(self.package, self.deviceId)

    def task_mobile(self):
        if not self.bMobile:
            return
        sleep_heartbeat(2)
        self.bRunMapEnd=True
        time.sleep(10)
        self.mobile_device.kill_app()
        #mobile_kill_app(self.package,self.deviceId)
        self.log.info('mobile wait end')



    def run_local(self, dic_args):
        self.check_dic_args(dic_args)
        self.loadDataFromLocalConfig(dic_args)
        self.get_file_info()
        self.sf.del_dir_by_date(self.nSaveDateCount)
        self.copyPerfeye()
        self.add_thread_for_searchPanel(dic_args)
        self.process_threads_beforeStartClient()
        self.set_package()
        self.start_client_test(dic_args)
        self.task_mobile()


if __name__ == '__main__':
    oob = CaseXGameGetPackage()
    oob.run_from_IQB()
    '''
    sf = ScanFiles('10.11.80.122', 21, "ftp1", "ftp+123", '/XGame-apk')
    sf.launch()
    sf.ini()
    sf.arrange_File()
    print(sf.dic_arrangedFileInfo)
'''

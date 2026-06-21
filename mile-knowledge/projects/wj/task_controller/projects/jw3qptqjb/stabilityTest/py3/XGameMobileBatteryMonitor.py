# -*- coding: utf-8 -*-
import time

from CaseCommon import *

class XGameMobileBatteryMonitor(CaseCommon):

    def __init__(self):
        CaseCommon.__init__(self)
        # CtrlPerfMon.__init__(self)

    def teardown(self):
        self.log.info(f'XGameMobileBatteryMonitor_teardown start')
        super().teardown()
        self.log.info(f'XGameMobileBatteryMonitor_teardown end')

    def check_dic_args(self,dic_args):
        if 'clientType' not in dic_args:
            raise ValueError('缺少clientType')
        else:
            self.clientType=dic_args['clientType']
            if 'mobile' in self.clientType:
                self.bMobile = True
                self.pathLocalConfig = os.path.join(dic_args['pathClient'], 'LocalConfig.ini')
                self.deviceId = ini_get('local', 'deviceId', self.pathLocalConfig)
                self.strMachineName = ini_get('local', 'machine_id', self.pathLocalConfig)
            else:
                raise ValueError('not mobile')

    def Monitor(self):
        #nCheckTime 分钟检查一次  如果电量少于30%就改为30分钟检查一次
        nCheckTime=20
        while True:
            try:
                sleep_heartbeat(nCheckTime)
                self.log.info(f"{nCheckTime}分钟 检查一次")
                nBattery=mobile_get_battery(self.deviceId)
                if nBattery<30:
                    strMsg=f'机器: {self.strMachineName} 电量低于30% , 请停止用例充电 , 电量剩余: {nBattery}重启'
                    self.log.info(strMsg)
                    strScreenShotPath = os.path.join('TempFolder','BatteryMonitorScene.png')
                    mobile_screemshot(strScreenShotPath, self.deviceId)
                    send_Subscriber_msg(machine_get_guid(), strMsg, strScreenShotPath)
                    nCheckTime=30
                else:
                    nCheckTime=20
            except:
                info = traceback.format_exc()
                self.log.error(info)

    def run_local(self, dic_args):
        self.check_dic_args(dic_args)
        self.Monitor()
        pass

if __name__ == '__main__':
    obj_test = XGameMobileBatteryMonitor()
    obj_test.run_from_IQB()

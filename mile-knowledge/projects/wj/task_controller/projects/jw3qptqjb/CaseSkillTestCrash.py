# -*- coding: utf-8 -*-
import os
import time

from CaseXGameCrash import *
class CaseSkillTest(CaseXGameCrash):

    def __init__(self):
        super().__init__()
        self.nKungfu=None
        self.nSkillID=None
        self.strMapCopyIndex=None
        self.nStepTime=30 #每个技能测试的间隔时间
        # CtrlPerfMon.__init__(self)
        #key 地图id value  左下角  右上角
    #开启技能测试
    def start_skill_test(self):
        #读取数据文件
        while not self.checkRecvInfoFromSearchpanel('skilltest_start'):
            time.sleep(10)
        strCmd="/cmd CreateEmptyFile('perfeye_start')"
        self.SocketClient.SendCommandToSDK(strCmd)

        import pandas as pd
        # 读取xlsx文件
        df = pd.read_excel('技能ID.xlsx')
        df.fillna(-1, inplace=True)
        # 转换为字典
        list_data = df.to_dict(orient='records')
        for dic_data in list_data:
            if dic_data['心法ID用于自动化通信'] == -1 or dic_data['技能ID'] == -1:
                continue
            nKungfu = int(dic_data['心法ID用于自动化通信'])
            nSkillID = int(dic_data['技能ID'])

            url = f"http://10.11.146.16:5006/SwitchSkill?kungfu={nKungfu}&skillID={nSkillID}&mapCopyIndex={self.strMapCopyIndex}"
            response = requests.request("GET", url)
            dic_res = json.loads(response.text)
            if dic_res['state'] == 1:
                pass
            else:
                raise Exception('http SwitchSkill fail')
            time.sleep(self.nStepTime)
            url = f"http://10.11.146.16:5006/logoutRobot?mapCopyIndex={self.strMapCopyIndex}"
            response = requests.request("GET", url)

        strCmd = "/cmd CreateEmptyFile('perfeye_stop')"
        self.SocketClient.SendCommandToSDK(strCmd)
        time.sleep(20)
        strCmd = "/cmd CreateEmptyFile('ExitGame')"
        self.SocketClient.SendCommandToSDK(strCmd)


    def processSearchPanelTab(self,dic_args):
        # self.nMapIndex= int(dic_args['mapIndex']) 废弃
        # 现在每台手机一个副本地图，这里mapCopyIndex是1~8任意数字，目前只支持最多8台手机，需要扩展找叶海峰
        self.strMapCopyIndex = dic_args["devices_custom"]['skilltest']['mapCopyIndex']
        if int(self.strMapCopyIndex) not in [1,2,3,4,5,6,7,8]:
            self.log.error('mapCopyIndex 配置有误')
            return

        if 'nStepTime' in dic_args:
            self.nStepTime=int(dic_args['nStepTime'])

        strSrc = os.path.join(SERVER_PATH, 'XGame', 'RunTab', dic_args['casename'])
        strTabPath=os.path.join('TempFolder','Interface',self.runMapType)
        strTabPath = os.path.join(strTabPath,'RunMap.tab')
        filecontrol_copyFileOrFolder(strSrc, strTabPath)
        changeStrInFile(strTabPath, '_mapIndex_', str(self.strMapCopyIndex))
        super().processSearchPanelTab(dic_args)

        t = threading.Thread(target=self.start_skill_test)
        t.setDaemon(True)
        t.start()


    def teardown(self):
        try:
            if self.nKungfu != None:
                url = f"http://10.11.146.16:5006/logoutRobot?mapCopyIndex={self.strMapCopyIndex}"
                response = requests.request("GET", url)
        except:
            info = traceback.format_exc()
            print(info)
        super().teardown()

if __name__ == '__main__':
    obj_test = CaseSkillTest()
    obj_test.run_from_IQB()

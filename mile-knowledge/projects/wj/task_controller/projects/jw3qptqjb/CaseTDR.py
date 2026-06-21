# -*- coding: utf-8 -*-
import os
import time

from CaseJX3SearchPanel import *
from PerfeyeCtrl import *
from HotPointMapCtrl import *
from XGameSocketClient import *
class CaseTDR(CaseJX3SearchPanel):

    def __init__(self):
        super().__init__()
        self.robot=None
        # CtrlPerfMon.__init__(self)

    def processInterface(self, dic_args):
        super().processInterface(dic_args)
        #pc端GM插件有概率会下载失败  因此需要从共享拷贝
        if not self.bMobile:
            strServerPath=SERVER_PATH+'\GM'
            filecontrol_deleteFileOrFolder(self.CLIENT_PATH+'/mui/Lua/Debug/GM')
            filecontrol_copyFileOrFolder(strServerPath,self.CLIENT_PATH+'/mui/Lua/Debug/GM')

    def processSearchPanelTab(self, dic_args):
        # 兼容手机操作，文件先考到本地临时文件夹处理完毕再推送到目的地

        #副本类型需要拷贝数据文件
        if self.runMapType=='Dungeons':
            strServerPath=SERVER_PATH+f'\XGame\RunTab\副本\{self.strMapId}.tab'
            strLocalPath=f"{GetTEMPFOLDER()}{os.sep}Interface{os.sep}{self.runMapType}{os.sep}RunMapTask.tab"
            self.log.info(f"副本特定文件处理 server:{strServerPath},local:{strLocalPath}")
            filecontrol_copyFileOrFolder(strServerPath,strLocalPath)

        super().processSearchPanelTab(dic_args)
        if 'robot' in dic_args:
            nRobotCnt=dic_args['robot']
            szName=''
            if 'robotIndex' not in dic_args:
                if nRobotCnt==0:
                    szName, nStartIndex, nEndIndex="留白",0,0
                else:
                    self.robot=TDRRobot()
                    szName, nStartIndex, nEndIndex=self.robot.mallocRobot(nRobotCnt)
            else:
                if 'robotName' in dic_args:
                    szName, nStartIndex, nEndIndex = dic_args['robotName'], int(dic_args['robotIndex']), 0
                else:
                    szName, nStartIndex, nEndIndex = "留白",int(dic_args['robotIndex']),0

            strHead = '/cmd CreateEmptyFile("BeginRunMap")	20	开始跑图\n'
            strInfo = f'/cmd RobotControl.IniRobot({nStartIndex},{nRobotCnt},"{szName}")	1	设置机器人\n'
            self.log.info(strInfo)
            tmp = os.path.join(GetTEMPFOLDER(), 'Interface', self.runMapType,'RunMap.tab')
            strInfo = strHead + strInfo
            changeStrInFile(tmp, strHead, strInfo)
            #filecontrol_copyFileOrFolder(os.path.join('TempFolder', 'Interface'), self.INTERFACE_PATH, self.deviceId,self.package)


    def teardown(self):
        self.log.info('CaseTDR_teardown start')
        #释放机器人
        if self.robot != None:
            self.robot.releaseRobot()
            #异步释放机器人 这个位置有可能卡住
            #t = threading.Thread(target=self.robot.releaseRobot)
            #t.setDaemon(True)
            #t.start()
        super().teardown()
        self.log.info('CaseTDR_teardown end')

def AutoRun(dic_parameters):
    global obj_test
    obj_test = CaseTDR()
    obj_test.run_from_uauto(dic_parameters)

'''
if __name__ == '__main__':
    obj_test = CaseTDR()
    obj_test.run_from_IQB()'''

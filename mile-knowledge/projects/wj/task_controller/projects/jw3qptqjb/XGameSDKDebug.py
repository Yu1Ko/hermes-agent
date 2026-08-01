# -*- coding: utf-8 -*-
import os.path

from CaseCommon import *
from XGameSocketClient import *

class XGameSDKDebug(CaseCommon):
    def __init__(self):
        super().__init__()

    def run_local(self, dic_args):
        #从配置文件获取deviceID
        self.pathLocalConfig = os.path.join(dic_args['pathClient'], 'LocalConfig.ini')
        self.strMachineName = ini_get('local', 'machine_id', self.pathLocalConfig)
        self.deviceId = ini_get('local', 'deviceId', self.pathLocalConfig)
        self.log.info(self.strMachineName)

        if '-' in self.deviceId:
            self.strClientPath=r'/Documents/mui/Lua/Logic/Login/LoginMgr.lua'
            self.package = 'com.jx3.mobile'
        else:
            self.strClientPath = r'/sdcard/Android/data/com.seasun.jx3/files/mui/Lua/Logic/Login/LoginMgr.lua'
            self.package = 'com.seasun.jx3'


        #获取IP地址
        strIpAddress = mobile_get_address(self.deviceId)

        #给游戏客户端安装执行cmd命令服务
        strServicePath=os.path.join(SERVER_PATH,'XGame','LoginMgrNew.lua')
        filecontrol_copyFileOrFolder(strServicePath,self.strClientPath,self.deviceId,self.package)

        #游戏客户端是否在运行
        if not mobile_determine_runapp(self.package,self.deviceId):
            self.log.info('app run error')
            return

        #初始化SDK模块
        obj = XGameSocketClient(os.path.join(os.getcwd(), 'SocketClientDLL.dll'), strIpAddress, 1112)
        # obj.PerfDataCreate()
        # obj.PerfDataStart()
        # time.sleep(2)
        #obj.SetEngineOption(EngineOption.EO_debug_set_terrain_enable, 0, True)
        time.sleep(1)
        if 'cmd' in dic_args:
            strCMD=dic_args['cmd']
            obj.SendCommandToSDK(strCMD)

        # strCMD = "/gm player.Revive()"
        # strCMD = "AutoTest"

        # time.sleep(30)
        # obj.PerfDataSetTimeNode()
        # time.sleep(5)
        # obj.PerfDataStop()
        #卸载SDK模块
        obj.SDK_Stop()
        pass


if __name__ == '__main__':
    oob = XGameSDKDebug()
    oob.run_from_IQB()


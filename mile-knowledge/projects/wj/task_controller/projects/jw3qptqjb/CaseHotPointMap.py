# -*- coding: utf-8 -*-
import os
import time

from CaseJX3SearchPanel import *
class CaseHotPointMap(CaseJX3SearchPanel):

    def __init__(self):
        super().__init__()
        self.robot=None
        # CtrlPerfMon.__init__(self)
        #key 地图id value  左下角  右上角
        self.dic_MapPosRange={
            "1":"4000,4000,8000,8000",
        }
        self.dic_MapStepSize={
            "1": "6400",
        }
        self.nHotPointType=0
        #设置地图范围 左下角+右上角  1000,1000,50000,50000
        self.strMapPosRange='0,0,0,0'
        #设备跑图间距
        self.strMapStepSize='7200'
        # #--2套方案  1重高空往下接触的第一个位置(房顶问题)    2直接设置Z坐标为0跑地宫和房子里(陷到地底的问题)
        self.strRunType="1"
        # --分支1(每格只留最差) / 分支2(保留全部)
        self.strDedupType="0"

    def check_dic_args(self, dic_args):
        super().check_dic_args(dic_args)
        #热力图20秒截图
        self.nScreenshot_Interval=20
        if 'MapPosRange' in dic_args:
            strMapPosRange=dic_args['MapPosRange']
            if len(strMapPosRange.split(','))!=4:
                raise Exception(f"地图反馈 格式错误:{strMapPosRange},请按照 1000,1000,5000,5000 的格式修改")
            self.strMapPosRange=strMapPosRange
        if 'MapStepSize' in dic_args:
            self.strMapStepSize=str(dic_args['MapStepSize'])
        #--2套方案  1重高空往下接触的第一个位置(房顶问题)    2直接设置Z坐标为0跑地宫和房子里(陷到地底的问题)
        if 'RunType' in dic_args:
            self.strRunType=str(dic_args["RunType"])
        # --分支1(每格只留最差) / 分支2(保留全部)
        if 'DedupType' in dic_args:
            self.strDedupType=str(dic_args["DedupType"])


    def processSearchPanelTab(self, dic_args):
        super().processSearchPanelTab(dic_args)
        # HotPointMap 需要控制范围
        '''
        strMapPosRange="0,0,0,0"
        if self.strMapId in self.dic_MapPosRange:
            strMapPosRange=self.dic_MapPosRange[self.strMapId]'''

        tmp = os.path.join(GetTEMPFOLDER(), 'Interface', self.runMapType, 'RunMap.tab')
        changeStrInFile(tmp, '_MapPosRange_', self.strMapPosRange)
        changeStrInFile(tmp, '_MapStepSize_', self.strMapStepSize)
        changeStrInFile(tmp, '_RunType_', self.strRunType)
        changeStrInFile(tmp, '_DedupType_', self.strDedupType)
        list_pos=self.strMapPosRange.split(',')
        changeStrInFile(tmp, '_Pos_',f"{list_pos[0]},{list_pos[1]}")

    def EngineOption(self,dic_args):
        super().EngineOption(dic_args)

        if "sdk" in dic_args:
            nSdk = dic_args["sdk"]
            self.nHotPointType=dic_args["sdk"]
            if nSdk == 3:
                # 热力图默认屏蔽NPC、阴影、doodad、depthprepass
                self.log.info(f"EngineOption type:{self.nHotPointType}")
                self.SocketClient.SetEngineOption(Enum_option("EO_debug_set_gameplay_model_enable"), 0, False)
                self.SocketClient.SetEngineOption(Enum_option("EO_basic_set_shadow_quality_int"), 1, 0)
                self.SocketClient.SetEngineOption(Enum_option("EO_basic_set_shadow_quality_int"), 1, 0)
            elif nSdk == 4:
                # 热力图默认屏蔽NPC、阴影、doodad、depthprepass 植被
                self.log.info(f"EngineOption type:{self.nHotPointType}")
                self.SocketClient.SetEngineOption(Enum_option("EO_debug_set_gameplay_model_enable"), 0, False)
                self.SocketClient.SetEngineOption(Enum_option("EO_basic_set_shadow_quality_int"), 1, 0)
                self.SocketClient.SetEngineOption(Enum_option("EO_debug_set_foliage_enable"), 0, False)


    def task_process_data(self):
        # tags = '档次|机型|配置|地图|测试点|日期'
        subtags = '{0}|{1}|{2}|{3}|{4}|{5}'.format(self.tagVideoLevel, self.tagMachineType, self.tagVideoCard,self.mapname, self.testpoint, date_get_szToday())
        self.log.info('task_process_data start')

        # 冷机时间
        nSleepMinite = self.nClientRunTimeOut // 60
        nSleepMinite = 5 if nSleepMinite > 5 else nSleepMinite
        #解除帧率临时测试
        if self.deviceId=='23a76ad5':
            nSleepMinite=10
        try:
            szFilePath = os.path.join(self.INTERFACE_PATH, self.runMapType, "Data.json")
            szTempData = os.path.join(GetTEMPFOLDER(), "Data.json")
            filecontrol_copyFileOrFolder(szFilePath, szTempData, self.deviceId, self.package)
            szBVTVerserion = self.GetVersion()
            #szBVTVerserion=self.mobile_device.strVersion
            #szBVTVerserion=get_package_version(self.tagMachineType)
            #szBVTVerserion=self.mobile_device.strVersion
            self.log.info(f"Package version:{szBVTVerserion}")
            #获取地图范围信息

            szFilePath = os.path.join(self.INTERFACE_PATH, self.runMapType, self.strMapId)
            szTempData1 = os.path.join(GetTEMPFOLDER(), self.mapname)
            filecontrol_copyFileOrFolder(szFilePath, szTempData1, self.deviceId, self.package)
            strUploadTag=''
            if self.nHotPointType==3:
                strUploadTag=f'-off-NPC|doodad|shadow-{self.testpoint}'

            
            reportId = HotPointMapUpLoadData(self.AppKey, szTempData, f"{self.tagVideoCard}_{self.tagVideoLevel}", self.mapname,szBVTVerserion,strTag=strUploadTag)
            HotPointMapUpLoadImg(self.AppKey, self.mapname, reportId)
            strReportUrl=f"https://benchmarking.testplus.cn/project/{self.AppKey}/scene?currentReportId={reportId}&deviceName={self.tagVideoCard}_{self.tagVideoLevel}&endTime={date_get_szToday()}&sceneName={self.mapname}&startTime={date_get_szToday()}"
            self.args["hotPointReport"] =strReportUrl
            self.log.info(f"strReportUrl:{strReportUrl}")
        except Exception:
            info = traceback.format_exc()
            self.log.info(info)
            send_Subscriber_msg(self.strGuid, f"用例:{self.strCaseName}:报错 请及时查看,{nSleepMinite}分钟后跳过改用例,报错信息如下:{info}")
            pass
        #先上传热力图数据再处理Perfeye数据
        # with open(szTempData, 'r') as f:
        # dic_extraData = json.loads(f.read())
        super().task_process_data()
        if 'perfeyeReport' in self.args:
            try:
                HotPointMapPerfeyeUid(reportId,self.args['perfeyeReport']["result"]["report_id"])
            except Exception:
                info = traceback.format_exc()
                self.log.info(info)

def AutoRun(dic_parameters):
    global obj_test
    obj_test = CaseHotPointMap()
    obj_test.run_from_uauto(dic_parameters)

# if __name__ == '__main__':
#     obj_test = CaseHotPointMap()
#     obj_test.run_from_IQB()

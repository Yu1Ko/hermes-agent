# -*- coding: utf-8 -*-
import os
import time

from CaseJX3SearchPanel import *
class CaseSwitchMap(CaseJX3SearchPanel):

    def __init__(self):
        super().__init__()

    def processSearchPanelTab(self,dic_args):
        super().processSearchPanelTab(dic_args)
        list_map = [
            2, 5, 6, 7, 8, 11, 15, 108, 122, 150, 151, 156, 159, 172, 193, 194, 197, 213, 239, 243, 332,
            333, 419, 445, 464, 467
            , 526, 578, 579, 582, 642, 653
        ]
        strTabPath=os.path.join('TempFolder','Interface',self.runMapType)
        strTabPath = os.path.join(strTabPath,'RunMap.tab')
        strChangeInfo=''
        strMapId=''
        strMapIdStart=None
        tuple_mapInfo=None
        for nMapId in list_map:
            strMapId=str(nMapId)
            if strMapId not in self.DIC_TrafficInfo:
                continue
            if not strMapIdStart:
                strMapIdStart=strMapId
            tuple_mapInfo=self.DIC_TrafficInfo[strMapId]
            strChangeInfo +=f'/gm player.SwitchMap({strMapId},1, {tuple_mapInfo[2]}, {tuple_mapInfo[3]}, {tuple_mapInfo[4]})	30	{self.DIC_MAPNAME[strMapId]}\n'
            strChangeInfo +=f'/cmd PlayerAutoFly({tuple_mapInfo[0]}, {tuple_mapInfo[1]})	200	AutoFly\n'
            strChangeInfo += f'/gm player.Stop()	2	玩家停止\n'
        tuple_mapInfo = self.DIC_TrafficInfo[strMapIdStart]
        strChangeInfo +=f'/gm player.SwitchMap({strMapIdStart},1, {tuple_mapInfo[2]}, {tuple_mapInfo[3]}, {tuple_mapInfo[4]})	60	{self.DIC_MAPNAME[strMapIdStart]}'
        #strChangeInfo=strChangeInfo[:strChangeInfo.rfind('\n')]
        changeStrInFile(strTabPath, '_SwitchMap_', strChangeInfo)

if __name__ == '__main__':
    obj_test = CaseSwitchMap()
    obj_test.run_from_IQB()

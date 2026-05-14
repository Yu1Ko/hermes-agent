# -*- coding: utf-8 -*-
from BaseToolFunc import *
def Create_SwitchMap_tab():
    list_map = [
        2, 5, 6, 7, 8, 11, 15, 108, 122, 150, 151, 156, 159, 172, 193, 194, 197, 213, 239, 243, 332,
        333, 419, 445, 464, 467, 526, 578, 579, 582, 642, 653
    ]
    strFilePath=r'TempFolder\SwitchMap.tab'
    dic_trafficInfo={}
    with open(os.path.join(os.path.dirname(os.path.realpath(__file__)), 'MapPathData.tab')) as f:
        for line in f:
            list_data = line.replace("\n", "").replace("\r", "").split('\t')
            dic_trafficInfo[list_data[0]] = (
                list_data[1], list_data[2], list_data[3], list_data[4], list_data[5])


    '''
    for nMapId in list_map:
        strMapId = str(nMapId)
        if strMapId not in dic_trafficInfo:
            continue
        if not strMapIdStart:
            strMapIdStart = strMapId
        tuple_mapInfo = dic_trafficInfo[strMapId]
        strChangeInfo += f'/gm player.SwitchMap({strMapId},1, {tuple_mapInfo[2]}, {tuple_mapInfo[3]}, {tuple_mapInfo[4]})	30	{self.DIC_MAPNAME[strMapId]}\n'
    '''
    '''        strChangeInfo += f'/cmd QualityMgr.SetQualityByType(GameQualityType.EXTREME_HIGH)	10	切换高画质'
        strChangeInfo += f'/cmd QualityMgr.SetQualityByType(GameQualityType.HIGH)	10	切换高画质'
        strChangeInfo +=f'/cmd QualityMgr.SetQualityByType(GameQualityType.MID)	10	切换高画质'''
    strChangeInfo=''
    for strMapId in dic_trafficInfo:
        tuple_mapInfo = dic_trafficInfo[strMapId]
        strChangeInfo += f'/gm player.SwitchMap({strMapId},1, {tuple_mapInfo[2]}, {tuple_mapInfo[3]}, {tuple_mapInfo[4]})	10	{strMapId}\n'
    with open(strFilePath, 'w', encoding='gbk') as f:
        f.write(strChangeInfo)



if __name__ == '__main__':
    Create_SwitchMap_tab()
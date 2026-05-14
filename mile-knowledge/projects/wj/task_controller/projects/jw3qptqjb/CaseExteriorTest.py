import os
import time

from CaseJX3SearchPanel import *


class CaseExteriorTest(CaseJX3SearchPanel):
    def __init__(self):
        super().__init__()
        self.AcquireSFX = None
        self.SfxCmd = None
        self.strAccessoriesId = None
        self.strAccessories = None
        self.strHairID = None
        self.strSetID = None
        self.strExterior = None
        self.strHairstyle = None

    def processSearchPanelTab(self, dic_args):
        self.bExtraData = False  # 不采集扩展数据
        if "hairstyle" in dic_args:
            self.strHairstyle = dic_args['hairstyle']
        if "Exterior" in dic_args:
            self.strExterior = dic_args['Exterior']
        if "SetId" in dic_args:
            self.strSetID = dic_args['SetId']
        if "HairID" in dic_args:
            self.strHairID = dic_args['HairID']
        if "Accessories" in dic_args:
            self.strAccessories = dic_args['Accessories']  # 饰品
        if "SfxCmd" in dic_args:
            self.SfxCmd = dic_args['SfxCmd']  # 挂件释放特效
        if "AcquireSFX" in dic_args:
            self.AcquireSFX = dic_args['AcquireSFX']  # 称号穿戴
            # 外装流程
        strHead = '/cmd CreateEmptyFile("BeginRunMap")	20	开始跑图\n'
        # RunMap.tab外装前置条件
        list_info = ["/cmd SearchExterior.InitTools()	5	初始化外装",
                     "/cmd SearchHair.InitTools()	5	初始化发型",
                     "/cmd PlayerData.GetClientPlayer().HideHat(not false)	5	关闭隐藏帽子"]
        if self.strHairstyle:
            strHairInfo = f'/cmd SearchHair.Apply_ByName_Head("{self.strHairstyle}")	5	更换发型'
            list_info.append(strHairInfo)
        if self.strExterior:
            strExteriorInfo = f'/cmd SearchExterior.Apply_ByName("{self.strExterior}",false)	5	更换外装'
            list_info.append(strExteriorInfo)
        if self.strSetID:
            strExteriorInfoSetID = f'/cmd SearchExterior.Apply("{self.strSetID}",false)	5	更换外装'
            list_info.append(strExteriorInfoSetID)
        if self.strHairID:
            strHairInfoSetID = f'/cmd SearchHair.Apply_Head("{self.strHairID}")	5	更换发型'
            list_info.append(strHairInfoSetID)
        # 是否分隔饰品
        # 装备饰品原句 player.AddPendent(饰品ID);player.SelectPendent(nSubType, 饰品ID)
        if self.strAccessories:
            if '),' in self.strAccessories:
                pairs = self.strAccessories.split('),')
                for pair in pairs:
                    # 去除多余的空格和括号
                    pair = pair.strip().replace('(', '').replace(')', '')
                    nums = pair.split(',')
                    strAccessoriesTab = f'/gm player.AddPendent({nums[1]});player.SelectPendent({nums[0]},{nums[1]})	5	添加饰品'
                    list_info.append(strAccessoriesTab)

            else:
                nums = self.strAccessories.strip('()').split(',')
                strAccessoriesTab = f'/gm player.AddPendent({nums[1]});player.SelectPendent({nums[0]},{nums[1]})	5	添加饰品'
                list_info.append(strAccessoriesTab)
        # 称号
        if self.AcquireSFX:
            strAcquireSFX = f'/gm player.AcquireSFX("{self.AcquireSFX}")	5	传递称号'
            list_info.append(strAcquireSFX)
        # 挂件释放特效
        if self.SfxCmd:
            strSfxCmd = f'/cmd CustomRunMapByData.SetSfxCmd("{self.SfxCmd}")	5	设置释放指令'
            list_info.append(strSfxCmd)
        strInfo = strHead
        for info in list_info:
            strInfo = strInfo + info + '\n'
        # 修改RunMap文件
        strSrc = os.path.join(SERVER_PATH, 'XGame', 'RunTab', dic_args['casename'])
        strTabPath = os.path.join(GetTEMPFOLDER(), 'Interface', self.runMapType)
        strTabPath = os.path.join(strTabPath, 'RunMap.tab')
        filecontrol_copyFileOrFolder(strSrc, strTabPath)
        changeStrInFile(strTabPath, strHead, strInfo)
        super().processSearchPanelTab(dic_args)

    def teardown(self):
        super().teardown()


def AutoRun(dic_parameters):
    global obj_test
    obj_test = CaseExteriorTest()
    obj_test.run_from_uauto(dic_parameters)

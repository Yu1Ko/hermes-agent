-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICoinShopBuildHairDyePage
-- Date: 2023-09-07 14:35:25
-- Desc: ?
-- ---------------------------------------------------------------------------------
local TABLE_DYEING_HAIR = {
    [1] = {
        szName = g_tStrings.STR_DYEING_BASE,
        nColorType = HAIR_CUSTOM_DYEING_TYPE.BASE_COLOR,
        tSub = {
            {nLogicType = HAIR_CUSTOM_DYEING_TYPE.BASE_ROUGHNESS, szKey = "Roughness", szName = g_tStrings.STR_BASE_DYEING_ROUGHNESS},
            {nLogicType = HAIR_CUSTOM_DYEING_TYPE.BASE_HIGHLIGHT, szKey = "Highlight", szName = g_tStrings.STR_BASE_DYEING_HIGHLIGHT},   
            {nLogicType = HAIR_CUSTOM_DYEING_TYPE.BASE_ABLEDO_COLORA, szKey = "AbledoColorA", szName = g_tStrings.STR_BASE_DYEING_ABLEDO_COLORA},
            {nLogicType = HAIR_CUSTOM_DYEING_TYPE.BASE_SPECULAR_COLORA, szKey = "SpecularColorA", szName = g_tStrings.STR_BASE_DYEING_SPECULAR_COLORA},   
        },  
    },

    [2] = {
        szName = g_tStrings.STR_DYEING_HAIR,
        nColorType = HAIR_CUSTOM_DYEING_TYPE.HAIR_COLOR,
        tSub = {
            {nLogicType = HAIR_CUSTOM_DYEING_TYPE.HAIR_ROUGHNESS, szKey = "Roughness", szName = g_tStrings.STR_HAIR_DYEING_ROUGHNESS},
            {nLogicType = HAIR_CUSTOM_DYEING_TYPE.HAIR_HIGHLIGHT, szKey = "Highlight", szName = g_tStrings.STR_HAIR_DYEING_HIGHLIGHT},
            {nLogicType = HAIR_CUSTOM_DYEING_TYPE.HAIR_ABLEDO_COLORA, szKey = "AbledoColorA", szName = g_tStrings.STR_HAIR_DYEING_ABLEDO_COLORA},
            {nLogicType = HAIR_CUSTOM_DYEING_TYPE.HAIR_SPECULAR_COLORA, szKey = "SpecularColorA", szName = g_tStrings.STR_HAIR_DYEING_SPECULAR_COLORA},
            {nLogicType = HAIR_CUSTOM_DYEING_TYPE.HAIR_ALPHA_ENHANCE, szKey = "AlphaEnhance", szName = g_tStrings.STR_HAIR_DYEING_ALPHA_ENHANCE},
        },
    },

    [3] = {
        szName = g_tStrings.STR_DYEING_DECORATION,
        nColorType = HAIR_CUSTOM_DYEING_TYPE.DECORATION_COLOR,
        tSub = {
            {nLogicType = HAIR_CUSTOM_DYEING_TYPE.DECORATION_COLORA, szKey = "ColorA", szName = g_tStrings.STR_DECORATION_DYEING_COLORA},
            {nLogicType = HAIR_CUSTOM_DYEING_TYPE.DECORATION_COLOR_STRENGTH, szKey = "ColorStrength", szName = g_tStrings.STR_DECORATION_DYEING_COLOR_STRENGTH},
        },
        bDecoration = true,
    },
}

local tRoleName =
{
    [1] = "StandardMale",
    [2] = "StandardFemale",
    [5] = "LittleBoy",
    [6] = "LittleGirl",
}

local DEFAULT_DATA          = {
    [HAIR_CUSTOM_DYEING_TYPE.BASE_ROUGHNESS]    = 20,
    [HAIR_CUSTOM_DYEING_TYPE.BASE_HIGHLIGHT]    = 0,
    [HAIR_CUSTOM_DYEING_TYPE.BASE_ABLEDO_COLORA]    = 120,
    [HAIR_CUSTOM_DYEING_TYPE.BASE_SPECULAR_COLORA]    = 120,

    [HAIR_CUSTOM_DYEING_TYPE.HAIR_ROUGHNESS]    = 20,
    [HAIR_CUSTOM_DYEING_TYPE.HAIR_HIGHLIGHT]    = 0,
    [HAIR_CUSTOM_DYEING_TYPE.HAIR_ABLEDO_COLORA]    = 120,
    [HAIR_CUSTOM_DYEING_TYPE.HAIR_SPECULAR_COLORA]    = 120,

    [HAIR_CUSTOM_DYEING_TYPE.DECORATION_COLORA]    = 127,
    [HAIR_CUSTOM_DYEING_TYPE.DECORATION_COLOR_STRENGTH]    = 127,
}

local SCROLL_STEP           = 1
local DEFAULT_DYEING_COUNT  = 5
local DEFAULT_INDEX         = 0
-----------------------------DataModel------------------------------
local DataModel             = {}

function DataModel.Init(nHair)
    DataModel.nNowHair          = nHair
    DataModel.bCustomPage       = true
    DataModel.bCaseFull         = false

    DataModel.InitBaseInfo()
    DataModel.GetInitData()
    DataModel.InitIndex()
    DataModel.InitMyCastData()
    DataModel.InitFreeInfo()
end

function DataModel.UnInit()
    for i, v in pairs(DataModel) do
		if type(v) ~= "function" then
			DataModel[i] = nil
		end
	end
end

function DataModel.IsEquipped(tData1, tData2)
    for k, v in ipairs(TABLE_DYEING_HAIR) do
        local nValue1 = tData1[v.nColorType]
        local nValue2 = tData2[v.nColorType]
        if nValue1 == nValue2 then
            if nValue1 ~= 0 then
                for _, tSubInfo in ipairs(v.tSub) do
                    local nSubValue1 = tData1[tSubInfo.nLogicType]
                    local nSubValue2 = tData2[tSubInfo.nLogicType]
                    if nSubValue1 ~= nSubValue2 then
                        return false
                    end
                end
            end
        else
            return false
        end
    end
    return true
end

function DataModel.InitBaseInfo()
    if not DataModel.tLogicDyeingInfo then
        local hDyeingManager             = GetHairCustomDyeingManager()
        if not hDyeingManager then
            return
        end
        DataModel.tLogicDyeingInfo       = hDyeingManager.GetAllDyeingInfo()
        DataModel.tLogicHairColor        = hDyeingManager.GetAllHairColor()
        DataModel.tLogicDecorationColor  = hDyeingManager.GetAllDecorationColor()
    end
    DataModel.GetDyeingDecorationColor()
    DataModel.GetDyeingHairColor()
end

function DataModel.DealWithShowHairColor()
    DataModel.tLogicShowHairColor       = {}
    for k, v in pairs(DataModel.tLogicHairColor) do
        local dwCostType                = v.nCostType
        if not kmath.is_logicbit1(DataModel.dwForbidDyeingColorMask, dwCostType) then
            DataModel.tLogicShowHairColor[dwCostType] = DataModel.tLogicShowHairColor[dwCostType] or {}
            v.nColorID                  = k
            table.insert(DataModel.tLogicShowHairColor[dwCostType], v)
        end
    end
end

function DataModel.GetDyeingDecorationColor()
    if DataModel.tTableDecorationColor then
        return
    end
    DataModel.tTableDecorationColor = {}
    local nCount                    = g_tTable.DyeingDecorationColor:GetRowCount()
	for i = 2, nCount do
		local tLine                 = g_tTable.DyeingDecorationColor:GetRow(i)
		DataModel.tTableDecorationColor[tLine.dwColorID] = tLine
	end
end

function DataModel.GetDyeingHairColor()
    if DataModel.tTableCostType then
        return
    end
    DataModel.tTableHairColor       = {}
    DataModel.tTableCostType        = {}
    local nCount                    = g_tTable.DyeingHairColor:GetRowCount()
	for i = 2, nCount do
		local tLine                 = g_tTable.DyeingHairColor:GetRow(i)
		DataModel.tTableHairColor[tLine.dwColorID] = tLine
        if not DataModel.tTableCostType[tLine.dwCostType] then
            DataModel.tTableCostType[tLine.dwCostType] = {
                szCostTypeName      = tLine.szCostTypeName,
                nTipItemType	    = tLine.nTipItemType,
                nTipItemIndex	    = tLine.nTipItemIndex,
            }
        end
	end
end

--特殊设定，在原染色的情况下默认设置装饰颜色的最大值
function DataModel.SetDecorationDataMax(tData)
    local tSub = TABLE_DYEING_HAIR[3].tSub
    for k, tInfo in pairs(tSub) do
        local nLogicType                    = tInfo.nLogicType
        local tLogicInfo                    = DataModel.tLogicDyeingInfo[nLogicType]
        local nMaxValue                     = tLogicInfo.nValueMax
        tData[nLogicType]                   = nMaxValue
    end
end

function DataModel.InitIndex()
    local hPlayer                       = GetClientPlayer()
    if not hPlayer then
        return
    end

    local hHairShopClient               = GetHairShop()
    if not hHairShopClient then
        return
    end
    DataModel.nNowDyeingIndex           = hPlayer.GetEquippedHairCustomDyeingIndex(DataModel.nNowHair) --玩家当前装备的方案
    if DataModel.nNowDyeingIndex == -1 then
        DataModel.nNowDyeingIndex = DEFAULT_INDEX
    end

    DataModel.nNowChoiceDyeingIndex     = DataModel.nNowDyeingIndex --界面选择的
    if DataModel.nNowDyeingIndex == DEFAULT_INDEX then
        DataModel.tCustomData           = clone(DataModel.tInitData)
    else
        DataModel.tCustomData           = hPlayer.GetEquippedHairCustomDyeingData(DataModel.nNowHair)
    end
    DataModel.tNowData                  = DataModel.ImportData(DataModel.tCustomData, false)
    DataModel.bDefaultIndex             = DEFAULT_INDEX == DataModel.nNowDyeingIndex
    DataModel.nRoleType                 = hPlayer.nRoleType
    local tHairPrice                    = hHairShopClient.GetHairPrice(DataModel.nRoleType, HAIR_STYLE.HAIR, DataModel.nNowHair)
    DataModel.dwForbidDyeingColorMask   = tHairPrice.dwForbidDyeingColorMask

    DataModel.DealWithShowHairColor()
end

function DataModel.GetScrollPos(nValue, nMin, nStep)
	local nPos = math.floor((nValue -  nMin) / nStep + 0.5)
	return nPos
end

function DataModel.GetInitData()
    local tInitData = {}
    for i = 0, HAIR_CUSTOM_DYEING_TYPE.TOTAL - 1 do
        tInitData[i] = 0
    end
    DataModel.tInitData = tInitData
    DataModel.tEmptyData = clone(tInitData)
    for k, v in pairs(DEFAULT_DATA) do
        DataModel.tInitData[k] = v
    end
    DataModel.tDefaultInitData = clone(tInitData)
end

function DataModel.ChoiceIndex(nIndex)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    DataModel.nNowChoiceDyeingIndex = nIndex
    local tData = ExteriorCharacter.GetHairDyeingIndexData(DataModel.nNowHair, nIndex) or DataModel.tCustomData
    DataModel.tNowData              = DataModel.ImportData(tData, false)
    -- FireUIEvent("SET_HAIR_DYEING_INDEX", DataModel.nNowHair, nIndex)
end

function DataModel.InitMyCastData()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    local tHairCustomDyeingList = hPlayer.GetHairCustomDyeingList(DataModel.nNowHair)
    if tHairCustomDyeingList and table.GetCount(tHairCustomDyeingList) == 4 then
        DataModel.bCaseFull = true
    end
end

function DataModel.InitFreeInfo()
    local bFree = false
	local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local nFreeEndTime = hPlayer.GetHairCustomDyeingFreeEndTime(DataModel.nNowHair, DataModel.nNowChoiceDyeingIndex)
    local nCurrentTime = GetCurrentTime()

    if nFreeEndTime and nFreeEndTime > nCurrentTime then
        bFree = true
        DataModel.nFreeEndTime = nFreeEndTime
    end

    DataModel.bFree = bFree
end

function DataModel.IsFree(nCostType, nColorType)
    if not DataModel.nFreeEndTime then
        return false
    end
    local hDyeingManager = GetHairCustomDyeingManager()
    if not hDyeingManager then
        return
    end
    if nColorType == HAIR_CUSTOM_DYEING_TYPE.DECORATION_COLOR or
        hDyeingManager.CheckColorCanFree(DataModel.nNowHair, DataModel.nNowDyeingIndex, nCostType) then
        return true
    end
end

function DataModel.ResetWndData(nColorType, tSub)
    DataModel.tNowData[nColorType]  = DataModel.tCustomData[nColorType]
    for _, tInfo in ipairs(tSub) do
       local nType = tInfo.nLogicType
       DataModel.tNowData[nType]  = DataModel.tCustomData[nType]
    end
end

function DataModel.RandomData()
    if not DataModel.tRandomHairColor then
        DataModel.tRandomHairColor = {}
        for nCostType, tColorList in pairs(DataModel.tLogicShowHairColor) do
            for _, tColorInfo in ipairs(tColorList) do
                local nColorID = tColorInfo.nColorID
                table.insert(DataModel.tRandomHairColor, nColorID)
            end
        end
    end

    if not DataModel.tRandomDecorationColor then
        DataModel.tRandomDecorationColor = {}
        for dwColorID, _ in pairs(DataModel.tLogicDecorationColor) do
            table.insert(DataModel.tRandomDecorationColor, dwColorID)
        end
    end

    for _, v in ipairs(TABLE_DYEING_HAIR) do
        if v.bDecoration then
            local nColorID = DataModel.tRandomDecorationColor[math.random(1, #DataModel.tRandomDecorationColor)]
            DataModel.tNowData[v.nColorType] = nColorID
            for k, tInfo in ipairs(v.tSub) do
                local tLogicInfo    = DataModel.tLogicDyeingInfo[tInfo.nLogicType]
                local nMinValue     = tLogicInfo.nValueMin
                local nMaxValue     = tLogicInfo.nValueMax
                DataModel.tNowData[tInfo.nLogicType] = math.random(nMinValue, nMaxValue)
            end
        else
            local nColorID = DataModel.tRandomHairColor[math.random(1, #DataModel.tRandomHairColor)]
            DataModel.tNowData[v.nColorType] = nColorID
            local tLogicHairColor = DataModel.tLogicHairColor[nColorID]
            for k, tInfo in ipairs(v.tSub) do
                local szMinKey = tInfo.szKey .. "_ValueMin"
                local nMinValue = tLogicHairColor[szMinKey]
                local szMaxKey = tInfo.szKey .. "_ValueMax"
                local nMaxValue = tLogicHairColor[szMaxKey]
                DataModel.tNowData[tInfo.nLogicType] = math.random(nMinValue, nMaxValue)
            end
        end
    end
end

function DataModel.IsDataChange()
   return (not DataModel.IsEquipped(DataModel.tNowData, DataModel.tCustomData)) and (not DataModel.IsEquipped(DataModel.tNowData, DataModel.tDefaultInitData))
end

function DataModel.DealWithBuyTable(tData)
    for k, v in ipairs(TABLE_DYEING_HAIR) do
        local nColorType            = v.nColorType
        if tData[nColorType] == 0 then
            for _, tInfo in ipairs(v.tSub) do
                local nLogicType = tInfo.nLogicType
                tData[nLogicType] = 0
            end
        end
    end
end

-- 统一的数据导入方法，封装版本管理和数据验证逻辑
function DataModel.ImportData(tData, bNeedCheckValid)
    if not tData then
        return nil
    end

    local tResult = clone(tData)
    DataModel.DealWithBuyTable(tResult)

    if not tResult[HAIR_CUSTOM_DYEING_TYPE.HAIR_ALPHA_ENHANCE] then
        tResult[HAIR_CUSTOM_DYEING_TYPE.HAIR_ALPHA_ENHANCE] = 0
    end

    if bNeedCheckValid then
        local hManager = GetHairCustomDyeingManager()
        if hManager then
            local bRetCode = hManager.CheckValid(tResult)
            if not bRetCode then
                return nil
            end
        end
    end

    return tResult
end

local UICoinShopBuildHairDyePage = class("UICoinShopBuildHairDyePage")

local PageListType = {
    ["MainPage"] = 1,
}

local PageType = {
    ["HairDye"]  = 1,
    ["Recommend"]  = 2,
}

local PageTogConfig = {
    {
        {szName = "发现", szIcon = "UIAtlas2_NieLian_CoinFace_FaceTab1_IconDyeingRecommend", nPageType = PageType.Recommend, },
        {szName = "染色", szIcon = "UIAtlas2_NieLian_CoinFace_FaceTab1_IconDyeing", nPageType = PageType.HairDye, },
    },
}

function UICoinShopBuildHairDyePage:OnEnter(nHairID, tbDyeData)
    if not self.bInit then
        self.nCurSelectPageListIndex = PageListType.MainPage
        self.nCurSelectPageIndex = PageType.Recommend

        self.bUseNew = true
        self.nCurSelectClass1Index = 1
        self.nCurSelectClass2Index = 1
        self.nCurSelectClass3Index = 1

        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        UIHelper.WidgetFoceDoAlign(self)
        self:InitPageTogList()
    end

    self.nHairID = nHairID
    DataModel.Init(self.nHairID)

    if tbDyeData then
        DataModel.tNowData = DataModel.ImportData(tbDyeData, false)
    end

    if DataModel.bFree then
        self.bUseNew = false
    elseif DataModel.bDefaultIndex or DataModel.bCaseFull then
        -- local szDisableTip = DataModel.bCaseFull and "您可拥有的染色方案个数已达上限" or "默认方案无法修改"
        local szDisableTip = DataModel.bCaseFull and "您可拥有的染色方案个数已达上限" or nil
        self.bUseNew = DataModel.bDefaultIndex or not DataModel.bCaseFull
        UIHelper.SetButtonState(self.BtnPriceChange, BTN_STATE.Disable, szDisableTip)
    end

    local szCaseName = self:GetName()
    if szCaseName then
        UIHelper.SetString(self.LabelCaseName, szCaseName)
        UIHelper.LayoutDoLayout(self.LayoutDyingName)
    end

    FireUIEvent("SET_SUBSET_HIDE_FLAG", EQUIPMENT_REPRESENT.HAIR_SUBSET_HIDE_MASK, 0)
    self:UpdateInfo()
    self:UpdateBtnState()
    self:UpdateCameraState(true)
    self:UpdateFreeTimer()
end

function UICoinShopBuildHairDyePage:OnExit()
    self.bInit = false
    ExteriorCharacter.ResetHairFlag()
    self:ResetModel()
    self:UpdateCameraState(false)
end

function UICoinShopBuildHairDyePage:BindUIEvent()
    UIHelper.SetToggleGroupAllowedNoSelection(self.TogGroupColorCell, false)
    UIHelper.SetToggleGroupAllowedNoSelection(self.TogGroupDefault, false)
    self.scriptScrollViewTab2 = UIHelper.GetBindScript(self.WidgetList2)
    self.scriptScrollViewTab3 = UIHelper.GetBindScript(self.WidgetList3)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnBuy, EventType.OnClick, function(btn)
        self:OnClickBuy()
    end)

    UIHelper.BindUIEvent(self.BtnBuy2, EventType.OnClick, function(btn)
        self:OnClickBuy()
    end)

    UIHelper.BindUIEvent(self.BtnEdit, EventType.OnClick, function(btn)
        self:OnClickPageTog(PageType.HairDye)

        local nSelectIndex = table.get_key(self.tbPageIndex2PageType, self.nCurSelectPageIndex) or 1
        UIHelper.SetToggleGroupSelected(self.TogGroupPage, nSelectIndex - 1)
    end)

    UIHelper.BindUIEvent(self.BtnResetSingle, EventType.OnClick, function(btn)
        local tbClass2Info = TABLE_DYEING_HAIR[self.nCurSelectClass1Index]
        local nColorType = tbClass2Info.nColorType
        local tSub = tbClass2Info.tSub

        DataModel.ResetWndData(nColorType, tSub)
        self:UpdateRightInfo()
        self:UpdateNowColor()
        self:UpdateModel()
    end)

    UIHelper.BindUIEvent(self.BtnRandom, EventType.OnClick, function(btn)
        if self.nCurSelectPageIndex ~= PageType.HairDye then
            self:OnClickPageTog(PageType.HairDye)
            local nSelectIndex = table.get_key(self.tbPageIndex2PageType, self.nCurSelectPageIndex) or 1
            UIHelper.SetToggleGroupSelected(self.TogGroupPage, nSelectIndex - 1)
        end
        self.nCurSelectClass1Index = 1
        self.nCurSelectClass2Index = 1
        self.nCurSelectClass3Index = 1
        DataModel.RandomData()
        self:UpdateInfo()
        self:UpdateCameraState(true)
        self:UpdateModel()
    end)

    UIHelper.BindUIEvent(self.BtnExport, EventType.OnClick, function ()
        HairDyeingData.ExportData(DataModel.tNowData, DataModel.nNowHair, DataModel.nRoleType)
    end)

    UIHelper.BindUIEvent(self.BtnImport, EventType.OnClick, function ()
        if Platform.IsWindows() and GetOpenFileName then
            local szPath = GetStreamAdaptiveDirPath(UIHelper.GBKToUTF8(GetFullPath("hairdyeingdatadir")))
            CPath.MakeDir(szPath)

            local szFile = GetOpenFileName(g_tStrings.STR_HAIR_DYEING_CHOOSE_FILE, g_tStrings.STR_HAIR_DYEING_CHOOSE_DAT .. "(*.dat)\0*.dat\0\0", szPath)
            Timer.AddFrame(self, 1, function ()
                if not string.is_nil(szFile) then
                    self:LoadHairDyeData(szFile)
                end
            end)
        else
            UIMgr.Open(VIEW_ID.PanelDyeingSchemeLocal, function (szFile)
                if not Platform.IsWindows() then
                    szFile = UIHelper.UTF8ToGBK(GetFullPath(szFile))
                end
                self:LoadHairDyeData(szFile)
            end)
        end
    end)

    UIHelper.BindUIEvent(self.BtnRevertAll, EventType.OnClick, function ()
        UIHelper.ShowConfirm(g_tStrings.STR_HAIR_DYEING_RESET_MSG, function ()
            self:ResetModel()
        end)
    end)

    UIHelper.BindUIEvent(self.BtnPriceChange, EventType.OnClick, function(btn)
        self.bUseNew = not self.bUseNew
        self:UpdatePriceInfo()
    end)

    UIHelper.BindUIEvent(self.BtnFaceStation, EventType.OnClick, function(btn)
        UIMgr.Close(VIEW_ID.PanelCoinShopBuildDyeing)
        ShareStationData.OpenShareStation(SHARE_DATA_TYPE.EXTERIOR)
        Timer.Add(self, 0.1, function ()
            local tExteriorFilter = {
                [EQUIPMENT_REPRESENT.HAIR_STYLE] = {DataModel.nNowHair},
                ["Color" .. EQUIPMENT_REPRESENT.HAIR_STYLE] = 1,
            }
            Event.Dispatch(EventType.OnFilterShareStationExterior, tExteriorFilter)
        end)
    end)

    UIHelper.BindUIEvent(self.TogList3LeftRight, EventType.OnClick, function()
        -- BuildFaceData.SetMeanwhileSwitch(self.nCurMeanwhile, UIHelper.GetSelected(self.TogList3LeftRight))
    end)
end

function UICoinShopBuildHairDyePage:RegEvent()
    Event.Reg(self, EventType.OnDownloadShareCodeData, function (bSuccess, szShareCode, szFilePath, nDataType)
        if nDataType ~= SHARE_DATA_TYPE.EXTERIOR then
            return
        end

        if bSuccess and ShareCodeData.szCurGetShareCode == szShareCode then
            self:LoadExteriorData(szShareCode)
        end
    end)
end

function UICoinShopBuildHairDyePage:InitPageTogList()
    local bShowRecharge = Platform.IsWindows() or (Platform.IsAndroid() and not Channel.Is_dylianyunyun())
    UIMgr.AddPrefab(PREFAB_ID.WidgetCoin, self.LayoutTongBao, CurrencyType.Coin, false, nil, bShowRecharge)
    UIHelper.LayoutDoLayout(self.LayoutTongBao)

    local tbConfigs = PageTogConfig[self.nCurSelectPageListIndex]
    self.tbPageCells = self.tbPageCells or {}
    self.tbPageIndex2PageType = self.tbPageIndex2PageType or {}
    UIHelper.HideAllChildren(self.ScrollViewTab1)
    for i, tbConfig in ipairs(tbConfigs) do
        if not self.tbPageCells[i] then
            self.tbPageCells[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetTogNieLianCoin_Part, self.ScrollViewTab1)
        end

        self.tbPageCells[i]:OnEnter(tbConfig)
        self.tbPageIndex2PageType[i] = tbConfig.nPageType
        UIHelper.SetVisible(self.tbPageCells[i]._rootNode, true)
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewTab1)
    self:RegPageTog()
end

function UICoinShopBuildHairDyePage:RegPageTog()
    UIHelper.ToggleGroupRemoveAllToggle(self.TogGroupPage)

    local tbConfigs = PageTogConfig[self.nCurSelectPageListIndex]
    for nIndex, tbConfig in ipairs(tbConfigs) do
        local tog = self.tbPageCells[nIndex].TogSelect
        UIHelper.BindUIEvent(tog, EventType.OnClick, function ()
            self:OnClickPageTog(tbConfig.nPageType)
        end)

        UIHelper.ToggleGroupAddToggle(self.TogGroupPage, tog)
        UIHelper.SetSwallowTouches(tog, false)
    end

    local nSelectIndex = table.get_key(self.tbPageIndex2PageType, self.nCurSelectPageIndex) or 1
    UIHelper.SetToggleGroupSelected(self.TogGroupPage, nSelectIndex - 1)
end

function UICoinShopBuildHairDyePage:UpdateInfo()
    self:UpdatePageInfo()
    self:UpdateClass1Info()
    self:UpdateClass2Info()
    self:UpdateRightInfo()
    self:UpdateNowColor()

    self:UpdateModleInfo()
    self:UpdateBtnState()
    self:UpdateBuyBtnState()
    self:UpdatePriceInfo()
end

function UICoinShopBuildHairDyePage:UpdateModleInfo()
    local ModleView = ExteriorCharacter.GetModel("CoinShop_View", "CoinShop")
    if not ModleView then
        return
    end

    self:UpdatePriceInfo()
    self:UpdateBuyBtnState()
end

function UICoinShopBuildHairDyePage:UpdateRoleModel()
    ExteriorCharacter.SetViewPage("Role")
    local tRepresentID = clone(ExteriorCharacter.GetRoleRes())
    local bShowWeapon = ExteriorCharacter.IsWeaponShow()
    if not bShowWeapon then
        tRepresentID = clone(tRepresentID)
        tRepresentID[EQUIPMENT_REPRESENT.WEAPON_STYLE] = 0
        tRepresentID[EQUIPMENT_REPRESENT.BIG_SWORD_STYLE] = 0
    end

    local player = g_pClientPlayer
    if player then
        local tCustomData = GetEquipCustomRepresentData(player)
        if tCustomData then
            tRepresentID.tCustomRepresentData = tCustomData
        end
    end
    FireUIEvent("EXTERIOR_CHARACTER_UPDATE", "CoinShop_View", "CoinShop", tRepresentID, false, nil, nil)
end

function UICoinShopBuildHairDyePage:UpdatePageInfo()
    self.tbClassConfig = nil
    if self.nCurSelectPageIndex == PageType.HairDye then
        self.tbClassConfig = TABLE_DYEING_HAIR
    end
end

function UICoinShopBuildHairDyePage:UpdateClass1Info()
    if not self.tbClassConfig then
        return
    end

    local tbData = {}
    local nPrefabID1 = PREFAB_ID.WidgetCoinTabCell_OldVision
    local nPrefabID2 = PREFAB_ID.WidgetLeftTabCell_Tree_Coin

    local nCostType = DataModel.tLogicDecorationColor[1]
    for i, tbConfig in ipairs(self.tbClassConfig) do
        local bShow = (not tbConfig.bDecoration) or (tbConfig.bDecoration and not kmath.is_logicbit1(DataModel.dwForbidDyeingColorMask, nCostType))
        if bShow then
            local tbItemList = {}
            tbConfig.bShowArrow = #tbItemList > 0
            table.insert(tbData, {
                tArgs = tbConfig,
                tItemList = tbItemList,
                fnSelectedCallback = function (bSelected)
                    if bSelected then
                        UIHelper.ToggleGroupRemoveAllToggle(self.TogGroupClass1)
                        local tbCells = self.scriptScrollViewTab2.tContainerList[i].scriptContainer:GetItemScript()
                        for nIndex, cell in ipairs(tbCells) do
                            cell:AddTogGroup(self.TogGroupClass1)
                        end

                        UIHelper.SetToggleGroupSelected(self.TogGroupClass1, 0)
                        self.nCurSelectClass1Index = i
                        self.nCurSelectClass2Index = 1
                        self.nCurSelectClass3Index = 1
                        self.nSelectColorTypeIndex = nil
                        self:UpdateClass2Info()
                        self:UpdateRightInfo()
                        self:UpdateNowColor()
                        self:UpdateBtnState()
                    end
                end
            })
        end
    end


    local func = function(scriptContainer, tArgs)
        local szName = tArgs.szAreaName or tArgs.szName
        UIHelper.SetString(scriptContainer.LabelTitle, szName)
        UIHelper.SetString(scriptContainer.LabelSelect, szName)
        UIHelper.SetVisible(scriptContainer.ImgNew, false)
        UIHelper.SetVisible(scriptContainer.ImgLimitedFree, tArgs.nColorType == HAIR_CUSTOM_DYEING_TYPE.DECORATION_COLOR and DataModel.bFree)

        if not scriptContainer.bAddToggleGroup then
            scriptContainer.bAddToggleGroup = true
            UIHelper.ToggleGroupAddToggle(self.TogGroupClass2, scriptContainer.ToggleSelect)
        end
    end

    UIHelper.ToggleGroupRemoveAllToggle(self.TogGroupClass2)
    self.scriptScrollViewTab2:ClearContainer()
    self.scriptScrollViewTab2:SetOuterInitSelect()
    UIHelper.SetupScrollViewTree(self.scriptScrollViewTab2,
        nPrefabID1,
        nPrefabID2,
        func, tbData, true)

    local nCurSelectIndex1 = self.nCurSelectClass1Index
    if self.nCurSelectPageIndex == PageType.Body or
        self.nCurSelectPageIndex == PageType.FaceOld then
        nCurSelectIndex1 = nCurSelectIndex1 + 1
    end

    Timer.AddFrame(self, 1, function()
        local scriptContainer = self.scriptScrollViewTab2.tContainerList[nCurSelectIndex1].scriptContainer
        if scriptContainer and scriptContainer.SetSelected then
            scriptContainer:SetSelected(true)
        end

        if self.nCurSelectPageIndex == PageType.FaceOld or
            self.nCurSelectPageIndex == PageType.MakeupOld or
            self.nCurSelectPageIndex == PageType.Body then

            UIHelper.SetToggleGroupSelected(self.TogGroupClass2, nCurSelectIndex1 - 1)
        end
    end)
end

function UICoinShopBuildHairDyePage:UpdateClass2Info()
    local tbScritpColorType = {}
    UIHelper.RemoveAllChildren(self.ScrollViewDefault)
    local tbClass2Info = TABLE_DYEING_HAIR[self.nCurSelectClass1Index]
    local nColorType = tbClass2Info.nColorType
    if tbClass2Info.bDecoration then
        self.nSelectColorTypeIndex = 1
        return
    end

	for nCostType, tColorList in pairs(DataModel.tLogicShowHairColor) do
        local tbUIInfo = {}
        local tTableColor = {0, 0, 0}
        local tBaseInfo = DataModel.tTableCostType[nCostType]
        local nCurColorID = DataModel.tNowData[nColorType]

        local bCurColorType = false
        local szColorType = tBaseInfo.szCostTypeName and UIHelper.GBKToUTF8(tBaseInfo.szCostTypeName) or ""
        for _, tColorInfo in ipairs(tColorList) do
            local nColorID = tColorInfo.nColorID
            tTableColor = DataModel.tTableHairColor[nColorID]
            if nColorID == nCurColorID then
                bCurColorType = true
                self.nSelectColorTypeIndex = nCostType
            end
        end

        tbUIInfo.szName = szColorType
        tbUIInfo.tColor = tTableColor
        tbUIInfo.fnAction = function()
            self.nSelectColorTypeIndex = nCostType
            self:UpdateRightInfo()
        end

        local scriptItem = UIHelper.AddPrefab(PREFAB_ID.WidgetBulidFaceItem_80, self.ScrollViewDefault)
        local bFree = DataModel.bFree and DataModel.IsFree(nCostType, nColorType)

        scriptItem.nCostType = nCostType
        table.insert(tbScritpColorType, scriptItem)
        scriptItem:OnEnter(11, tbUIInfo)
        UIHelper.SetVisible(scriptItem.ImgLimitedFree, bFree)

        UIHelper.ToggleGroupAddToggle(self.TogGroupDefault, scriptItem.ToggleSelect)
        if bCurColorType then
            UIHelper.SetToggleGroupSelectedToggle(self.TogGroupDefault, scriptItem.ToggleSelect)
            self.nSelectColorTypeIndex = nCostType
            self:UpdateRightInfo()
        end
	end

    if not self.nSelectColorTypeIndex then
        self.nSelectColorTypeIndex = tbScritpColorType[1].nCostType
    end
    self.tbScritpColorType = tbScritpColorType
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewDefault)
end
function UICoinShopBuildHairDyePage:UpdateRightInfo()
    UIHelper.SetVisible(self.WidgetColorAdjust, false)
    UIHelper.SetVisible(self.WidgetRecommend, false)
    UIHelper.SetVisible(self.WidgetList2, false)
    UIHelper.SetVisible(self.WidgetDefault, false)

    if self.nCurSelectPageIndex == PageType.HairDye then
        self:UpdateHairDye()
    elseif self.nCurSelectPageIndex == PageType.Recommend then
        self:UpdateRecommendRightInfo()
    end
end

function UICoinShopBuildHairDyePage:UpdateHairDye()
    UIHelper.SetVisible(self.WidgetColorAdjust, true)
    UIHelper.SetVisible(self.WidgetList2, true)
    UIHelper.SetVisible(self.WidgetDefault, true)
    self.nSelectColorID = nil
    UIHelper.RemoveAllChildren(self.ScrollViewColorList)
    UIHelper.RemoveAllChildren(self.ScrollViewAdjustCell)
    UIHelper.ToggleGroupRemoveAllToggle(self.TogGroupColorCell)
    UIHelper.SetToggleGroupAllowedNoSelection(self.TogGroupColorCell, true)
    if not self.nSelectColorTypeIndex then
        return
    end

    local tbClass2Info = TABLE_DYEING_HAIR[self.nCurSelectClass1Index]
    local nColorType = tbClass2Info.nColorType
    local bDecoration = tbClass2Info.bDecoration

    local nCurColorID = DataModel.tNowData[nColorType]
    local nCostType = self.nSelectColorTypeIndex
    local tBaseInfo = DataModel.tTableCostType[nCostType]
    local tColorList = bDecoration and DataModel.tLogicDecorationColor or DataModel.tLogicShowHairColor[nCostType]
    if not tColorList or table.is_empty(tColorList) then
        return
    end

    for k, v in ipairs(tColorList) do
        local tbUIInfo = {}
        local nColorID = bDecoration and k or v.nColorID
        local tTableColor = bDecoration and DataModel.tTableDecorationColor[nColorID] or DataModel.tTableHairColor[nColorID]
        tbUIInfo.tColor = tTableColor
        tbUIInfo.fnAction = function()
            self.nSelectColorID = nColorID
            DataModel.tNowData[nColorType] = nColorID
            self:UpdateNowColor()
            self:UpdateDetailAdjustInfo()
            self:UpdateModel()
            UIHelper.SetToggleGroupAllowedNoSelection(self.TogGroupColorCell, false)
        end

        local scriptItem = UIHelper.AddPrefab(PREFAB_ID.WidgetBulidFaceItem_80, self.ScrollViewColorList)
        UIHelper.ToggleGroupAddToggle(self.TogGroupColorCell, scriptItem.ToggleSelect)

        if nCurColorID == nColorID then
            self.nSelectColorID = nColorID
            self:UpdateDetailAdjustInfo()
            UIHelper.SetToggleGroupAllowedNoSelection(self.TogGroupColorCell, false)
            UIHelper.SetToggleGroupSelectedToggle(self.TogGroupColorCell, scriptItem.ToggleSelect)
            UIHelper.ScrollLocateToPreviewItem(self.ScrollViewColorList, scriptItem._rootNode, Locate.TO_CENTER)
        end
        scriptItem:OnEnter(11, tbUIInfo)
    end

    if not bDecoration then
        local szColorType = tBaseInfo.szCostTypeName and UIHelper.GBKToUTF8(tBaseInfo.szCostTypeName) or ""
        UIHelper.SetString(self.LabelColorTittle, szColorType.."系")
    else
        UIHelper.SetString(self.LabelColorTittle, "发饰")
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewColorList)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewAdjustCell)
    self:UpdateCostItemList()
end

function UICoinShopBuildHairDyePage:UpdateRecommendRightInfo()
    UIHelper.SetVisible(self.WidgetList2, self.nCurSelectPageIndex == PageType.Body)
    UIHelper.SetVisible(self.WidgetRecommend, true)
    UIHelper.LayoutDoLayout(self.LayoutTabList)

    local tFilter = {}
    local bOldFace = self.nCurSelectPageIndex == PageType.FaceOld
    local bBody = self.nCurSelectPageIndex == PageType.Body

    local nDataType = SHARE_DATA_TYPE.EXTERIOR
    tFilter.nRoleType = DataModel.nRoleType
    tFilter.tFilterExterior = { ["Color" .. EQUIPMENT_REPRESENT.HAIR_STYLE] = 1, [EQUIPMENT_REPRESENT.HAIR_STYLE] = self.nHairID}

    self.scriptRecommend = self.scriptRecommend or UIHelper.GetBindScript(self.WidgetRecommend)
    self.scriptRecommend:OnEnter(false, nDataType, tFilter)
end

function UICoinShopBuildHairDyePage:UpdateBtnState()
    if self.nCurSelectPageIndex == PageType.HairDye then
        UIHelper.SetVisible(self.BtnBuy, true)
        UIHelper.SetVisible(self.LayoutRightBottomBtns, false)
    else
        UIHelper.SetVisible(self.BtnBuy, false)
        UIHelper.SetVisible(self.LayoutRightBottomBtns, true)
    end

    UIHelper.LayoutDoLayout(self.LayoutBtn)
    UIHelper.LayoutDoLayout(self.LayoutRightTop)
end

function UICoinShopBuildHairDyePage:UpdateCostItemList()
    UIHelper.RemoveAllChildren(self.LayoutItemNeed)
    if not self.nSelectColorTypeIndex then
        return
    end

    local tbClass2Info = TABLE_DYEING_HAIR[self.nCurSelectClass1Index]
    local bDecoration = tbClass2Info.bDecoration
    local nCostType = self.nSelectColorTypeIndex
    local tBaseInfo = bDecoration and DataModel.tTableDecorationColor[nCostType] or DataModel.tTableCostType[nCostType]
    local nPermanentCount, nTimeLimitCount = GetHairCustomDyeingManager().GetColorItemAmountInPackage(nCostType)

    local scriptItem_Perman = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, self.LayoutItemNeed)
    local scriptItem_TimeLimit = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, self.LayoutItemNeed)
    scriptItem_Perman:SetClickNotSelected(true)
    scriptItem_TimeLimit:SetClickNotSelected(true)

    scriptItem_Perman:OnInitWithTabID(tBaseInfo.nTipItemType, tBaseInfo.nTipItemIndex, nPermanentCount)
    scriptItem_TimeLimit:OnInitWithTabID(tBaseInfo.nTipItemType, tBaseInfo.nTipItemIndex, nTimeLimitCount)
    scriptItem_Perman:ShowNowIcon(true)
    scriptItem_Perman:SetNowDesc("永久")
    scriptItem_TimeLimit:ShowNowIcon(true)
    scriptItem_TimeLimit:SetNowDesc("限时")

    scriptItem_Perman:SetClickCallback(function()
        TipsHelper.ShowItemTips(scriptItem_Perman._rootNode, tBaseInfo.nTipItemType, tBaseInfo.nTipItemIndex, false)
    end)
    scriptItem_TimeLimit:SetClickCallback(function()
        TipsHelper.ShowItemTips(scriptItem_TimeLimit._rootNode, tBaseInfo.nTipItemType, tBaseInfo.nTipItemIndex, false)
    end)
    UIHelper.LayoutDoLayout(self.LayoutItemNeed)
end

function UICoinShopBuildHairDyePage:UpdateNowColor()
    if not self.nCurSelectClass1Index then
        return
    end

    local tbClass2Info = TABLE_DYEING_HAIR[self.nCurSelectClass1Index]
    local nColorType = tbClass2Info.nColorType
    local bDecoration = tbClass2Info.bDecoration
    local nCurColorID = DataModel.tNowData[nColorType]
    local tTableColor = bDecoration and DataModel.tTableDecorationColor[nCurColorID] or DataModel.tTableHairColor[nCurColorID]
    if nCurColorID and tTableColor then
        UIHelper.SetVisible(self.ImgColor_Now, true)
        UIHelper.SetColor(self.ImgColor_Now, cc.c3b(tTableColor.nR, tTableColor.nG, tTableColor.nB))
    else
        UIHelper.SetVisible(self.ImgColor_Now, false)
    end
end

function UICoinShopBuildHairDyePage:UpdateDetailAdjustInfo()
    if not self.nCurSelectClass1Index or not self.nSelectColorID  then
        UIHelper.SetVisible(self.ScrollViewAdjustCell, false)
        return
    end

    UIHelper.RemoveAllChildren(self.ScrollViewAdjustCell)
    local tbConfig = TABLE_DYEING_HAIR[self.nCurSelectClass1Index]
    local tbDetail = tbConfig.tSub
    for _, tSubInfo in ipairs(tbDetail) do
        local nLogicType    = tSubInfo.nLogicType
        local tLogicInfo    = DataModel.tLogicDyeingInfo[nLogicType]
        local nValue        = DataModel.tNowData[nLogicType] or 0

        local nMinValue     = tLogicInfo.nValueMin
        local nMaxValue     = tLogicInfo.nValueMax
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetCoinAdjustCell, self.ScrollViewAdjustCell)
        script:OnEnter(9, {
            nValueMin = nMinValue,
            nValueMax = nMaxValue,
            nStep = SCROLL_STEP,
            szName = UIHelper.UTF8ToGBK(tSubInfo.szName),
            fnCallback = function (_, nCurrentValue)
                DataModel.tNowData[nLogicType] = nCurrentValue
                self:UpdateModel()
            end
        }, nValue)
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewAdjustCell)
end

function UICoinShopBuildHairDyePage:UpdatePriceInfo()
    UIHelper.RemoveAllChildren(self.LayoutCostItem)
    local hDyeingManager = GetHairCustomDyeingManager()
    if not hDyeingManager then
        return
    end

    local szState = self.bUseNew and "新增" or "修改"
    local tCost = {}
    local bCanFree = false
    if not DataModel.IsEquipped(DataModel.tNowData, DataModel.tEmptyData) then
        local nIndex = self.bUseNew and 0 or DataModel.nNowDyeingIndex
        tCost = hDyeingManager.GetDyeingDataCost(DataModel.tNowData, DataModel.nNowHair, nIndex)
        bCanFree = DataModel.bFree and hDyeingManager.CheckCanFree(DataModel.tNowData, DataModel.nNowHair, nIndex)
    end

    for _, dwCostType in ipairs(tCost) do
        if dwCostType == 0 then
            break
        end

        local scriptItem = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, self.LayoutCostItem)
        scriptItem:SetClickNotSelected(true)
        local dwCostBox, dwCostX = hDyeingManager.GetCostColorItemInPackage(dwCostType)
        if dwCostBox == INVENTORY_INDEX.INVALID then
            local tSellInfo = Table_GetSellDyeingItemInfo(dwCostType)
            local dwTabType = tSellInfo.dwItemType
            local dwIndex = tSellInfo.dwItemIndex
            scriptItem:OnInitWithTabID(dwTabType, dwIndex, 1)
            UIHelper.SetColor(scriptItem.LabelCount, cc.c3b(255, 0, 0))
            scriptItem:SetClickCallback(function()
                TipsHelper.ShowItemTips(scriptItem._rootNode, dwTabType, dwIndex, false)
            end)
        else
            scriptItem:OnInit(dwCostBox, dwCostX)
            UIHelper.SetVisible(scriptItem.LabelCount, true)
            UIHelper.SetString(scriptItem.LabelCount, 1)
            scriptItem:SetClickCallback(function()
                TipsHelper.ShowItemTips(scriptItem._rootNode, dwCostBox, dwCostX, true)
            end)
        end
    end

    UIHelper.SetString(self.LabelCostTittle, "预估("..szState..")：")
    UIHelper.LayoutDoLayout(self.LayoutCostItem)
    UIHelper.LayoutDoLayout(self.LayoutCost)

    UIHelper.SetVisible(self.LayoutCost, not DataModel.bFree)
    UIHelper.SetVisible(self.LayoutNotFree, DataModel.bFree and not bCanFree)
    UIHelper.SetVisible(self.LayoutFreeTime, DataModel.bFree and bCanFree)
end

function UICoinShopBuildHairDyePage:UpdateFreeTimer()
    if self.nFreeEndTimer then
        Timer.DelTimer(self, self.nFreeEndTimer)
        self.nFreeEndTimer = nil
        DataModel.InitFreeInfo()
        self:UpdateInfo()
    end

    if not DataModel.nFreeEndTime then
        return
    end

    local fnUpdateTimer = function()
        DataModel.InitFreeInfo()
        local nLeftTime = DataModel.nFreeEndTime - GetCurrentTime()
        if nLeftTime <= 0 then
            Timer.DelTimer(self, self.nFreeEndTimer)
            self.nFreeEndTimer = nil
            DataModel.InitFreeInfo()
            self:UpdateInfo()
            return
        end

        local nHour, nMinute, nSecond = TimeLib.GetTimeToHourMinuteSecond(nLeftTime)
        local szTime = string.format(g_tStrings.STR_TIME_14, nHour, nMinute, nSecond)
        UIHelper.SetRichText(self.RichTextCountDown, "<color=#FF9696>" .. szTime.."</color>")
    end

    local nLeftTime = DataModel.nFreeEndTime - GetCurrentTime()
    if nLeftTime <= 0 then
        return
    end

    self.nFreeEndTimer = Timer.AddFrameCycle(self, 5, function()
        fnUpdateTimer()
    end)
end

function UICoinShopBuildHairDyePage:UpdateBuyBtnState()
    local hDyeingManager = GetHairCustomDyeingManager()
    if not hDyeingManager then
        return
    end

    local bCanBuy = DataModel.IsDataChange()
    -- if DataModel.bFree then
    --     local bCanFree = hDyeingManager.CheckCanFree(DataModel.tNowData, DataModel.nNowHair, DataModel.nNowDyeingIndex)
    --     bCanBuy = bCanFree
    -- end
    UIHelper.SetString(self.LabelBuy, "购买")
    UIHelper.SetButtonState(self.BtnBuy, bCanBuy and BTN_STATE.Normal or BTN_STATE.Disable)
    UIHelper.SetButtonState(self.BtnBuy2, bCanBuy and BTN_STATE.Normal or BTN_STATE.Disable)
end

function UICoinShopBuildHairDyePage:UpdateCameraState(bEnter)
    if bEnter then
        ExteriorCharacter.SetCameraMode("BuildFace")
        ExteriorCharacter.ScaleToCamera("BuildFaceMin")
    else
        if ShareStationData.bOpening then
            ExteriorCharacter.SetCameraMode("ShareStation")
            ExteriorCharacter.ScaleToCamera("Max")
            return
        end
        ExteriorCharacter.SetCameraMode("Wardrobe")
        ExteriorCharacter.ScaleToCamera("Max")
    end
end

function UICoinShopBuildHairDyePage:OnChangePageList(nType)
    self.nCurSelectPageListIndex = nType
    self:InitPageTogList()
end

function UICoinShopBuildHairDyePage:OnClickPageTog(nType)
    if self.nCurSelectPageIndex == nType then
        return
    end

    self.nCurSelectPageIndex = nType
    local nSelectIndex = table.get_key(self.tbPageIndex2PageType, self.nCurSelectPageIndex) or 1
    UIHelper.SetToggleGroupSelected(self.TogGroupPage, nSelectIndex - 1)

    self.nCurSelectClass1Index = 1
    self.nCurSelectClass2Index = 1
    self.nCurSelectClass3Index = 1

    self:UpdateInfo()
    self:UpdateCameraState(true)
end

function UICoinShopBuildHairDyePage:LoadHairDyeData(szFile)
   	local tHairDyeingData, szMsg = HairDyeingData.LoadHairDyeingData(szFile)
    if not tHairDyeingData then
        return
    end

    local hManager = GetHairCustomDyeingManager()
    if not hManager then
        return
    end

    if szMsg then
        TipsHelper.ShowNormalTip(szMsg)
        return
    end

	if not tHairDyeingData then
        TipsHelper.ShowNormalTip(g_tStrings.STR_HAIR_DYEING_DATA_VAILD)
		return
	end

	if tHairDyeingData.nRoleType ~= DataModel.nRoleType then
		local szName = g_tStrings.tRoleTypeFormalName[tHairDyeingData.nRoleType]
		local szMsg = FormatString( g_tStrings.STR_HAIR_DYEING_DATA_VAILD, szName)
		TipsHelper.ShowNormalTip(szMsg)
		return
	end

    if tHairDyeingData.nHair ~= DataModel.nNowHair then
		local szName = CoinShopHair.GetHairText(tHairDyeingData.nHair)
        szName = UIHelper.GBKToUTF8(szName)
		local szMsg = FormatString( g_tStrings.STR_HAIR_DYEING_DATA_VAILD_HAIR, szName)
		TipsHelper.ShowNormalTip(szMsg)
		return
	end

    DataModel.tNowData = DataModel.ImportData(tHairDyeingData.tHairDyeing, true)
    if not DataModel.tNowData then
        TipsHelper.ShowNormalTip(g_tStrings.STR_HAIR_DYEING_INVALID_DATA)
        return
    end
    self:UpdateModel()
end

function UICoinShopBuildHairDyePage:LoadExteriorData(szShareCode)
    local tData = ShareCodeData.GetShareCodeData(szShareCode)
    if not tData then
        return
    end
    
    local hManager = GetHairCustomDyeingManager()
    if not hManager then
        return
    end

    local tExterior = tData.tExterior
    if not tExterior then
        return
    end

    local tDetail = tExterior.tDetail
    if not tDetail then
        return
    end

    local tDyeingData = tDetail[EQUIPMENT_REPRESENT.HAIR_STYLE] and tDetail[EQUIPMENT_REPRESENT.HAIR_STYLE].tDyeingData
    if not tDyeingData then
        return
    end

    DataModel.tNowData = DataModel.ImportData(tDyeingData, true)
    if not DataModel.tNowData then
        TipsHelper.ShowNormalTip(g_tStrings.STR_HAIR_DYEING_INVALID_DATA)
        return
    end
    self:UpdateModel()
end

function UICoinShopBuildHairDyePage:UpdateModel()
    FireUIEvent("SET_HAIR_DYEING_DATA", DataModel.nNowHair, DataModel.tNowData)

    self:UpdatePriceInfo()
    self:UpdateBuyBtnState()
end

function UICoinShopBuildHairDyePage:ResetModel()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    local tData = hPlayer.GetEquippedHairCustomDyeingData(DataModel.nNowHair) or DataModel.tInitData
    DataModel.tNowData = DataModel.ImportData(tData, false)
    self:UpdateModel()
end

function UICoinShopBuildHairDyePage:OnClickBuy()
    if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.EXTERIOR, "CoinShop") then
        return
    end
    
    local hDyeingManager = GetHairCustomDyeingManager()
    if not hDyeingManager then
        return
    end
    
    if DataModel.bFree then
        local bCanFree = hDyeingManager.CheckCanFree(DataModel.tNowData, DataModel.nNowHair, DataModel.nNowDyeingIndex)
        if bCanFree then
            UIHelper.ShowConfirm(g_tStrings.STR_HAIR_DYEING_FREE_DYE_CONFIRM, function()
                hDyeingManager.Buy(DataModel.tNowData, DataModel.nNowHair, DataModel.nNowDyeingIndex, {})
            end)
        else
            local script = UIHelper.ShowConfirm(g_tStrings.STR_HAIR_DYEING_CAN_NOT_FREE)
            script:HideButton("Cancel")
        end
        return
    end
    
    if self.bUseNew or DataModel.bDefaultIndex then
        local hPlayer       = GetClientPlayer()
        if not hPlayer then
            return
        end
        local nCount        = hPlayer.GetHairCustomDyeingCount(DataModel.nNowHair)
        local nBoxSize      = hPlayer.GetHairCustomDyeingBoxSize()
        local bCanNew       = nCount < nBoxSize
        if not bCanNew then
            TipsHelper.ShowNormalTip(g_tStrings.STR_HAIR_DYEING_ADD_ERROR_MSG)
            return
        end
    end
    
    UIMgr.HideView(VIEW_ID.PanelCoinShopBuildDyeing)
    if DataModel.nNowDyeingIndex == 0 then
        UIMgr.OpenSingle(false, VIEW_ID.PanelDyeingSettleAccounts, DataModel.tNowData, DataModel.nNowHair, DataModel.nNowDyeingIndex)
        return
    end
    
    UIMgr.OpenSingle(false, VIEW_ID.PanelDyeingDetail, DataModel.bDefaultIndex, DataModel.tNowData, DataModel.nNowHair, DataModel.nNowDyeingIndex)
end

function UICoinShopBuildHairDyePage:GetName()
    if not DataModel.nNowHair or not DataModel.nNowDyeingIndex then
        return ""
    end

    local szName = g_tStrings.STR_HAIR_DYEING_DEFAULT_NAME .. DataModel.nNowDyeingIndex
    if DataModel.nNowDyeingIndex == 0 then
        szName = g_tStrings.STR_HAIR_MY_DYEING_DEFAULT
    end

    if Storage.tHairDyeingName[DataModel.nNowHair] and Storage.tHairDyeingName[DataModel.nNowHair][DataModel.nNowDyeingIndex] then
        szName = Storage.tHairDyeingName[DataModel.nNowHair][DataModel.nNowDyeingIndex]
    end
    return szName
end

return UICoinShopBuildHairDyePage
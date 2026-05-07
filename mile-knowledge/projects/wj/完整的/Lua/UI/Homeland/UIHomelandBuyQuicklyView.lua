-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandBuyQuicklyView
-- Date: 2024-07-05 10:49:27
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandBuyQuicklyView = class("UIHomelandBuyQuicklyView")

local MAX_INDEX_NUM = 8
local MAX_LAND_INDEX_NUM = 8
local MAX_LAND_LEVEL = 7
local NEW_LAND_MAP_ID = 674 -- 浣花水榭
local bApplyCommunityDigestFlag = false
local EASY_BUY_STEP = {
    Main    = 1,
    Detail  = 2,
    Confirm = 3
}
local HOMELAND_AREA = {1280, 2240, 4032, 7200}
-----------------------------DataModel------------------------------
local DataModel = {}

function DataModel.Init(nMapID, nCenterID)
    nMapID = nMapID or NEW_LAND_MAP_ID
    nCenterID = nCenterID or GetCenterID()
    bApplyCommunityDigestFlag = true
    GetHomelandMgr().ApplyCommunityDigest(nMapID, nCenterID)
    DataModel.tCenterList = GetHomelandMgr().GetRelationCenter(GetCenterID())
end

function DataModel.UnInit()
    DataModel.nCurrentMapID = nil
    DataModel.nCenterID = nil
    DataModel.nMaxIndex = nil
    DataModel.nMaxPrice = nil
    DataModel.nMinPrice = nil
    DataModel.tLandInfo = nil
    DataModel.nMaxLandNum = nil
    DataModel.tIndexList = nil
    DataModel.tLandList = nil
    DataModel.bIndexNoLimit = nil
    DataModel.bLandNoLimit = nil
    DataModel.bDiscreteCopyIndex = nil
    DataModel.bDiscreteLandIndex = nil
    DataModel.nMinCopyIndex = nil
    DataModel.nMaxCopyIndex = nil
    DataModel.tAreaLandIndex = nil
end

function DataModel.Set(szName, value)
    DataModel[szName] = value
end

function DataModel.UpdateDataModel(nMapID, nCenterID)
    DataModel.nCurrentMapID = nMapID
    DataModel.nCenterID = nCenterID
    --DataModel.nMaxIndex = nTotalSize
    DataModel.nMaxPrice = 0
    DataModel.nMinPrice = 0
    DataModel.tLandInfo = Table_GetLandInfo(nMapID)
    DataModel.tLandFilter = DataModel.GetAreaIndexList()
    DataModel.nMaxLandNum = #DataModel.tLandInfo
    DataModel.tIndexList = {}
    DataModel.tLandList = {}
    DataModel.bIndexNoLimit = true
    DataModel.bLandNoLimit = false
    local tTypeSize = GetHomelandMgr().GetCommunityDigest(nMapID, nCenterID)
    DataModel.nMaxIndex = tTypeSize[COMMUNITY_RANK_TYPE.NORMAL]
    DataModel.bDiscreteCopyIndex = false
    DataModel.bDiscreteLandIndex = true
    DataModel.nMinCopyIndex = nil
    DataModel.nMaxCopyIndex = nil
    DataModel.tAreaLandIndex = {}
end

function DataModel.UpdateMaxPrice()
    DataModel.nMaxPrice = 0
    DataModel.nMinPrice = nil
    local function UpdateNum(nPrice)
        if nPrice > DataModel.nMaxPrice then
            DataModel.nMaxPrice = nPrice
        end
        DataModel.nMinPrice = DataModel.nMinPrice or nPrice
        if nPrice < DataModel.nMinPrice then
            DataModel.nMinPrice = nPrice
        end
    end

    if DataModel.bLandNoLimit then
        for i, tInfo in ipairs(DataModel.tLandInfo) do
            local nPrice = tInfo.nPrice
            UpdateNum(nPrice)
        end
    else
        local tLandIndex = DataModel.GetLandIndexList()
        for i, nLandIndex in ipairs(tLandIndex) do
            local nPrice = DataModel.tLandInfo[nLandIndex].nPrice
           UpdateNum(nPrice)
        end
    end
    DataModel.nMinPrice = DataModel.nMinPrice or 0
end

function DataModel.ChangeIndex(nIndex, bDelete)
    if bDelete then
        if DataModel.tIndexList and DataModel.tIndexList[nIndex] then
            table.remove(DataModel.tIndexList, nIndex)
        end
    else
        if #DataModel.tIndexList < MAX_INDEX_NUM then
            local bNotExist = true
            for i, nValue in ipairs(DataModel.tIndexList) do
                if nValue == nIndex then
                    bNotExist = false
                    break
                end
            end
            if bNotExist then
                table.insert(DataModel.tIndexList, nIndex)
            end
        end
    end
end

function DataModel.ChangeLand(tLandIndex)
    if table.is_empty(tLandIndex) then
        DataModel.tLandList = {}
        DataModel.UpdateMaxPrice()
        return
    end

    for nIndex, nLand in ipairs(DataModel.tLandList) do
        if not CheckIsInTable(tLandIndex, nLand) then
            table.remove(DataModel.tLandList, nIndex)
        end
    end

    for _, nLand in ipairs(tLandIndex) do
        if #DataModel.tLandList < MAX_LAND_INDEX_NUM and not CheckIsInTable(DataModel.tLandList, nLand) then
            table.insert(DataModel.tLandList, nLand)
        end
    end
    DataModel.UpdateMaxPrice()
end

function DataModel.GetCenterNameByID(dwCenterID)
    for k, v in pairs(DataModel.tCenterList) do
        if v.dwCenterID == dwCenterID then
            return v.szCenterName
        end
    end
end

function DataModel.CheckEditboxCopyIndex(nInputNum, szKey)
    local bChange = false
    if nInputNum then
        if nInputNum < 1 then
            nInputNum = 1
            bChange = true
        elseif nInputNum > DataModel.nMaxIndex then
            nInputNum = DataModel.nMaxIndex
            bChange = true
        end
        DataModel.Set(szKey, nInputNum)
    else
        DataModel.Set(szKey, nil)
        bChange = false
    end
    return bChange
end

function DataModel.GetCopyIndexList()
    local tCopyIndex = {}
    if DataModel.bDiscreteCopyIndex then
        tCopyIndex = DataModel.tIndexList
    elseif DataModel.nMinCopyIndex and DataModel.nMaxCopyIndex and DataModel.nMinCopyIndex <= DataModel.nMaxCopyIndex then
        tCopyIndex[1] = DataModel.nMinCopyIndex
        tCopyIndex[2] = DataModel.nMaxCopyIndex
    end
    return tCopyIndex
end

function DataModel.GetLandIndexList()
    local tLandIndex = {}
    if DataModel.bDiscreteLandIndex then
        tLandIndex = DataModel.tLandList
    else
        tLandIndex = DataModel.tAreaLandIndex
    end
    return tLandIndex
end

function DataModel.GetAreaIndexList()
    local tAreaIndex = {}
    for _, tInfo in pairs(DataModel.tLandInfo) do
        local nArea = tInfo.nArea
        if not tAreaIndex[nArea] then
            tAreaIndex[nArea] = {}
        end
        table.insert(tAreaIndex[nArea], tInfo.nLandIndex)
    end
    return tAreaIndex
end

function UIHomelandBuyQuicklyView:OnEnter(nMapID, nCenterID, tbHomePageData)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self:InitMoney()
        DataModel.Init(nMapID, nCenterID)
        self.bInit = true
    end
    self.tbHomePageData = tbHomePageData
    self:Init()
end

function UIHomelandBuyQuicklyView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    if self.scriptSearchResult then
        self.scriptSearchResult:OnPageExit()
    end
end

function UIHomelandBuyQuicklyView:BindUIEvent()
    UIHelper.SetTouchDownHideTips(self.TogFilterServer, false)
    UIHelper.SetTouchDownHideTips(self.TogFilterMap, false)
    UIHelper.SetTouchDownHideTips(self.ScrollViewFilterMore, false)
    UIHelper.SetToggleGroupAllowedNoSelection(self.ToggleGroupServer, false)
    UIHelper.SetToggleGroupAllowedNoSelection(self.ToggleGroupMap, false)
    UIHelper.SetToggleGroupAllowedNoSelection(self.ToggleGroupLevel, false)
    UIHelper.SetEditboxTextHorizontalAlign(self.EditSmall, TextHAlignment.CENTER)
    UIHelper.SetEditboxTextHorizontalAlign(self.EditBig, TextHAlignment.CENTER)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCloseLeft, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.TogFilterServer, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected then
            UIHelper.SetSelected(self.TogFilterMap, false)
        end
    end)

    UIHelper.BindUIEvent(self.TogFilterMap, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected then
            UIHelper.SetSelected(self.TogFilterServer, false)
        end
    end)

    UIHelper.BindUIEvent(self.TogLine, EventType.OnClick, function()
        DataModel.Set("bDiscreteCopyIndex", not UIHelper.GetSelected(self.TogLine))
        UIHelper.SetVisible(self.WidgetDeleteLineTip, table.GetCount(DataModel.tIndexList) > 0 and DataModel.bDiscreteCopyIndex)
        UIHelper.LayoutDoLayout(self.WidgetFilterLine)
        self:UpdateBuyBtn()
        self:UpdateCostMoney()
    end)

    UIHelper.BindUIEvent(self.TogShape, EventType.OnClick, function()
        DataModel.Set("bDiscreteLandIndex", UIHelper.GetSelected(self.TogShape))
        UIHelper.SetVisible(self.WidgetSelectTip, table.GetCount(DataModel.tLandList) > 0 and DataModel.bDiscreteLandIndex)
        UIHelper.LayoutDoLayout(self.WidgetFilterShape)
        self:UpdateBuyBtn()
        self:UpdateCostMoney()
    end)

    UIHelper.BindUIEvent(self.TogLine, EventType.OnSelectChanged, function(_, bSelected)
        Timer.AddFrame(self, 1, function()
            UIHelper.LayoutDoLayout(self.WidgetFilterLine)
        end)
    end)

    UIHelper.BindUIEvent(self.TogShape, EventType.OnSelectChanged, function(_, bSelected)
        Timer.AddFrame(self, 1, function()
            UIHelper.LayoutDoLayout(self.WidgetFilterShape)
        end)
    end)

    UIHelper.BindUIEvent(self.TogSelectedAll, EventType.OnSelectChanged, function(_, bSelected)
        self:SetIndexNoLimit(bSelected)
    end)

    UIHelper.BindUIEvent(self.TogSelectedAll_Shape, EventType.OnSelectChanged, function(_, bSelected)
        self:SetLandNoLimit(bSelected)
    end)

    UIHelper.BindUIEvent(self.TogDeleteLine, EventType.OnSelectChanged, function(_, bSelected)
        for _, node in ipairs(self.tbWidgetLine) do
            local scriptCell = UIHelper.GetBindScript(node)
            UIHelper.SetVisible(scriptCell.BtnDel, bSelected)
        end
    end)

    UIHelper.BindUIEvent(self.BtnNext, EventType.OnClick, function()
        self.nCurStep = EASY_BUY_STEP.Detail
        self:UpdateBreadScreen()
    end)

    UIHelper.BindUIEvent(self.BtnBack, EventType.OnClick, function()
        self.nCurStep = EASY_BUY_STEP.Detail
        self:UpdateBreadScreen()
    end)

    UIHelper.BindUIEvent(self.BtnAddShape_Big, EventType.OnClick, function()
        UIHelper.SetVisible(self.WidgetAnchorTip, true)
    end)

    UIHelper.BindUIEvent(self.BtnAddShape, EventType.OnClick, function()
        UIHelper.SetVisible(self.WidgetAnchorTip, true)
    end)

    UIHelper.BindUIEvent(self.BtnSearch, EventType.OnClick, function()
        self:SearchLand()
    end)

    UIHelper.BindUIEvent(self.BtnBuy, EventType.OnClick, function()
        self:BuyLandCheck()
    end)

    if Platform.IsWindows() then
        UIHelper.RegisterEditBoxEnded(self.EditBig, function ()
            local nInputNum = tonumber(UIHelper.GetString(self.EditBig))
            if DataModel.nMinCopyIndex and nInputNum < DataModel.nMinCopyIndex then
                nInputNum = DataModel.nMinCopyIndex
            end
            self:SetMaxCopyIndex(nInputNum)
        end)

        UIHelper.RegisterEditBoxEnded(self.EditSmall, function ()
            local nInputNum = tonumber(UIHelper.GetString(self.EditSmall))
            if DataModel.nMaxCopyIndex and nInputNum > DataModel.nMaxCopyIndex then
                nInputNum = DataModel.nMaxCopyIndex
            end
            self:SetMinCopyIndex(nInputNum)
        end)

        UIHelper.RegisterEditBoxEnded(self.EditAddLine_Big, function ()
            local nInputNum = tonumber(UIHelper.GetString(self.EditAddLine_Big))
            if nInputNum and nInputNum > 0 and nInputNum <= DataModel.nMaxIndex then
                self:ChangeIndex(nInputNum)
            end
            UIHelper.SetString(self.EditAddLine_Big, "")    -- 初始化一下，防穿帮
        end)

        UIHelper.RegisterEditBoxEnded(self.EditAddLine, function ()
            local nInputNum = tonumber(UIHelper.GetString(self.EditAddLine))
            if nInputNum and nInputNum > 0 and nInputNum <= DataModel.nMaxIndex then
                self:ChangeIndex(nInputNum)
            end
            UIHelper.SetString(self.EditAddLine, "")    -- 初始化一下，防穿帮
        end)
    else
        UIHelper.RegisterEditBoxReturn(self.EditAddLine_Big, function ()
            local nInputNum = tonumber(UIHelper.GetString(self.EditAddLine_Big))
            if nInputNum and nInputNum > 0 and nInputNum <= DataModel.nMaxIndex then
                self:ChangeIndex(nInputNum)
            end
            UIHelper.SetString(self.EditAddLine_Big, "")    -- 初始化一下，防穿帮
        end)

        UIHelper.RegisterEditBoxReturn(self.EditBig, function ()
            local nInputNum = tonumber(UIHelper.GetString(self.EditBig))
            if DataModel.nMinCopyIndex and nInputNum < DataModel.nMinCopyIndex then
                nInputNum = DataModel.nMinCopyIndex
            end
            self:SetMaxCopyIndex(nInputNum)
        end)

        UIHelper.RegisterEditBoxReturn(self.EditSmall, function ()
            local nInputNum = tonumber(UIHelper.GetString(self.EditSmall))
            if DataModel.nMaxCopyIndex and nInputNum > DataModel.nMaxCopyIndex then
                nInputNum = DataModel.nMaxCopyIndex
            end
            self:SetMinCopyIndex(nInputNum)
        end)

        UIHelper.RegisterEditBoxReturn(self.EditAddLine, function ()
            local nInputNum = tonumber(UIHelper.GetString(self.EditAddLine))
            if nInputNum and nInputNum > 0 and nInputNum <= DataModel.nMaxIndex then
                self:ChangeIndex(nInputNum)
            end
            UIHelper.SetString(self.EditAddLine, "")    -- 初始化一下，防穿帮
        end)
    end

    for index, node in ipairs(self.tbWidgetLine) do
        local scriptCell = UIHelper.GetBindScript(node)
        UIHelper.BindUIEvent(scriptCell.BtnDel, EventType.OnClick, function ()
            self:ChangeIndex(index, true)
        end)
    end

    for _, btn in ipairs(self.tbWidgetShape) do
        UIHelper.BindUIEvent(btn, EventType.OnClick, function ()
            UIHelper.SetVisible(self.WidgetAnchorTip, true)
        end)
    end

    for index, tog in ipairs(self.tbToggleShape_Area) do
        UIHelper.BindUIEvent(tog, EventType.OnClick, function ()
            local nArea = HOMELAND_AREA[index]
            DataModel.Set("tAreaLandIndex", DataModel.tLandFilter[nArea])
            self.nLastSelectAreaToggle = index
            self:UpdateBuyBtn()
            self:UpdateCostMoney()
        end)
    end
end

function UIHomelandBuyQuicklyView:RegEvent()
    Event.Reg(self, "HOME_LAND_RESULT_CODE_INT", function ()
        local nResultType = arg0
        if nResultType == HOMELAND_RESULT_CODE.APPLY_COMMUNITY_DIGEST then
            if bApplyCommunityDigestFlag then
                bApplyCommunityDigestFlag = false
                local nMapID, nCenterID = arg1, arg2
                DataModel.UpdateDataModel(nMapID, nCenterID)
                self:InitFilter()
            end
        end
    end)

    Event.Reg(self, "HOME_LAND_RESULT_CODE", function ()
        local nResultType = arg0
        if nResultType == HOMELAND_RESULT_CODE.BUY_LAND_SUCCEED then
            UIMgr.Close(self)
        end
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function ()
        UIHelper.SetSelected(self.TogFilterServer, false)
        UIHelper.SetSelected(self.TogFilterMap, false)
        UIHelper.SetVisible(self.WidgetAnchorTip, false)
    end)

    Event.Reg(self, EventType.OnFilter, function (szKey, tbInfo)
        if szKey ~= FilterDef.HomelandEasyBuyHouse.Key then
            return
        end

        self:ChangeLand(tbInfo[1])
        self:InitLandFilter(true)
    end)

    Event.Reg(self, EventType.OnClickHomelandMyHomeRankListIndex, function (nIndex)
        self.tbHomePageData.Set("nCurrentMapID", DataModel.nCurrentMapID)
        self.tbHomePageData.ApplyCommunityInfo(DataModel.nCurrentMapID, nil, DataModel.nCenterID, nIndex, true)
    end)

    Event.Reg(self, EventType.OnViewClose, function (nViewID)
        if nViewID == VIEW_ID.PanelHome then
            UIMgr.Close(self)
        end
    end)

    Event.Reg(self, EventType.OnGameNumKeyboardOpen, function(editbox)
        if editbox == self.EditBig or editbox == self.EditSmall or
            editbox == self.EditAddLine_Big or editbox == self.EditAddLine then
            UIHelper.SetEditBoxGameKeyboardRange(editbox, 1, DataModel.nMaxIndex)
        end
    end)

    Event.Reg(self, EventType.OnGameNumKeyboardChanged, function(editbox, num)
        if editbox == self.EditBig then
            local nInput = tonumber(UIHelper.GetText(self.EditBig)) or 1
            UIHelper.SetString(self.EditBig, nInput)
        elseif editbox == self.EditSmall then
            local nInput = tonumber(UIHelper.GetText(self.EditSmall)) or 1
            UIHelper.SetString(self.EditSmall, nInput)
        elseif editbox == self.EditAddLine_Big then
            UIHelper.SetVisible(self.BtnNumberAdd, not num)
        elseif editbox == self.EditAddLine then
            UIHelper.SetVisible(self.ImgAdd, not num)
        end
    end)

    Event.Reg(self, EventType.OnGameNumKeyboardConfirmed, function (editbox, nCurNum)
        if editbox == self.EditBig then
            local nInputNum = tonumber(UIHelper.GetString(self.EditBig)) or 1
            if DataModel.nMinCopyIndex and nInputNum < DataModel.nMinCopyIndex then
                nInputNum = DataModel.nMinCopyIndex
            end
            self:SetMaxCopyIndex(nInputNum)
        elseif editbox == self.EditSmall then
            local nInputNum = tonumber(UIHelper.GetString(self.EditSmall)) or 1
            if DataModel.nMaxCopyIndex and nInputNum > DataModel.nMaxCopyIndex then
                nInputNum = DataModel.nMaxCopyIndex
            end
            self:SetMinCopyIndex(nInputNum)
        elseif editbox == self.EditAddLine_Big then
            local nInputNum = tonumber(UIHelper.GetString(self.EditAddLine_Big)) or 1
            if nInputNum and nInputNum > 0 and nInputNum <= DataModel.nMaxIndex then
                self:ChangeIndex(nInputNum)
            end
            UIHelper.SetString(self.EditAddLine_Big, "")    -- 初始化一下，防穿帮
        elseif editbox == self.EditAddLine then
            local nInputNum = tonumber(UIHelper.GetString(self.EditAddLine)) or 1
            if nInputNum and nInputNum > 0 and nInputNum <= DataModel.nMaxIndex then
                self:ChangeIndex(nInputNum)
            end
            UIHelper.SetString(self.EditAddLine, "")    -- 初始化一下，防穿帮
        end
    end)
end

function UIHomelandBuyQuicklyView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
local function GetHomelandMapName(nMapID)
    local szMapName = Table_GetMapName(nMapID)
    if string.is_nil(szMapName) then
        return ""
    end

    szMapName = UIHelper.GBKToUTF8(szMapName)
    return szMapName
end

function UIHomelandBuyQuicklyView:Init()
    local nMinLevel = 1
    self.nCurStep = EASY_BUY_STEP.Main
    DataModel.Set("nMinLevel", nMinLevel)
    self:InitFilter()
    self:UpdateBreadScreen()
    self:UpdateBuyBtn()
    self:UpdateCostMoney()
end

function UIHomelandBuyQuicklyView:InitMoney()
    self.scriptCurrency = self.scriptCurrency or UIHelper.AddPrefab(PREFAB_ID.WidgetCurrency, self.LayoutMoney1)
    UIHelper.SetVisible(self.scriptCurrency.WidgetMoney3, false)
    UIHelper.SetVisible(self.scriptCurrency.WidgetMoney4, false)
    UIHelper.LayoutDoLayout(self.scriptCurrency.LayoutCurrency)
    UIHelper.SetContentSize(self.scriptCurrency._rootNode, UIHelper.GetContentSize(self.scriptCurrency.LayoutCurrency))
    UIHelper.LayoutDoLayout(self.LayoutRightTop)
end

function UIHomelandBuyQuicklyView:InitFilter()
    UIHelper.RemoveAllChildren(self.LayoutFilterSever)
    UIHelper.RemoveAllChildren(self.ScrollViewFilterMore)
    UIHelper.RemoveAllChildren(self.LayoutLevelContent)

    UIHelper.ToggleGroupRemoveAllToggle(self.ToggleGroupServer)
    UIHelper.ToggleGroupRemoveAllToggle(self.ToggleGroupMap)
    UIHelper.ToggleGroupRemoveAllToggle(self.ToggleGroupLevel)

    -- 服务器筛选
    for _, tbInfo in ipairs(DataModel.tCenterList) do
        local szCenterName = UIHelper.GBKToUTF8(tbInfo.szCenterName)
        local scriptCell = UIHelper.AddPrefab(PREFAB_ID.WidgetBuyQualityFilterCell, self.LayoutFilterSever)
        scriptCell:OnEnter(szCenterName, false, function ()
            self:SetCenter(tbInfo.dwCenterID, szCenterName)
            UIHelper.SetSelected(self.TogFilterServer, false)
        end)
        UIHelper.ToggleGroupAddToggle(self.ToggleGroupServer, scriptCell.TogTypeFilter)

        if tbInfo.dwCenterID == DataModel.nCenterID then
            self:SetCenter(tbInfo.dwCenterID, szCenterName)
            UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroupServer, scriptCell.TogTypeFilter)
        end
    end

    -- 社区地图筛选
    local tMapList = Table_GetCommunityMapList()
    for _, nMapID in ipairs(tMapList) do
        local szMapName = GetHomelandMapName(nMapID)
        local scriptCell = UIHelper.AddPrefab(PREFAB_ID.WidgetBuyQualityFilterCell, self.ScrollViewFilterMore)
        scriptCell:OnEnter(szMapName, HomelandData.IsNewCommunityMap(nMapID), function ()
            self:SetCurrentMap(nMapID, szMapName)
            UIHelper.SetSelected(self.TogFilterMap, false)
        end)
        UIHelper.ToggleGroupAddToggle(self.ToggleGroupMap, scriptCell.TogTypeFilter)

        if nMapID == DataModel.nCurrentMapID then
            self:SetCurrentMap(nMapID, szMapName)
            UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroupMap, scriptCell.TogTypeFilter)
        end
    end

    -- 社区等级
    for i = 1, MAX_LAND_LEVEL, 1 do
        local szTitle = FormatString(g_tStrings.STR_HOMELAND_EASY_BUY_MIN_LEVEL1, i)
        local scriptCell = UIHelper.AddPrefab(PREFAB_ID.WidgetTogTypeSingle_XS, self.LayoutLevelContent)
        UIHelper.SetString(scriptCell.tbLabelList[1], szTitle)
        UIHelper.ToggleGroupAddToggle(self.ToggleGroupLevel, scriptCell.tbToggleList[1])
        UIHelper.BindUIEvent(scriptCell.tbToggleList[1], EventType.OnClick, function()
            self:SetMinLevel(i)
        end)
    end

    -- 分线
    self:ChangeIndex(1, true) -- 选择社区地图后刷新一下选择分线
    UIHelper.SetSelected(self.TogLine, true)
    UIHelper.SetSelected(self.TogSelectedAll, true)
    UIHelper.SetString(self.EditSmall, "")
    UIHelper.SetString(self.EditBig, "")

    -- 房型
    self.nLastSelectArea = 1
    self:InitLandFilter()
    self:ChangeLand({})
    UIHelper.SetSelected(self.TogShape, true)
    UIHelper.SetSelected(self.TogSelectedAll_Shape, false)
    UIHelper.SetSelected(self.tbToggleShape_Area[1], true)
    UIHelper.SetVisible(self.WidgetAnchorTip, false)
    for index, tog in ipairs(self.tbToggleShape_Area) do
        UIHelper.SetSelected(tog, false)
    end

    UIHelper.SetPlaceHolder(self.EditBig, DataModel.nMaxIndex)
    UIHelper.SetString(self.LabelTip, FormatString(g_tStrings.STR_HOMELAND_EASY_BUY_MAX_LINE, DataModel.nMaxIndex))

    UIHelper.LayoutDoLayout(self.WidgetFilterLine)
    UIHelper.LayoutDoLayout(self.WidgetFilterShape)
    UIHelper.LayoutDoLayout(self.LayoutFilterSever)
    UIHelper.LayoutDoLayout(self.LayoutLevelContent)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewFilterMore)
end

function UIHomelandBuyQuicklyView:UpdateBreadScreen()
    local nBreadCount = UIHelper.GetChildrenCount(self.LayoutBreadNavi)
    if nBreadCount == self.nCurStep then
        return
    end

    UIHelper.SetVisible(self.BtnBack, false)
    UIHelper.SetVisible(self.BtnBuy, false)
    UIHelper.SetVisible(self.BtnSearch, false)
    UIHelper.SetVisible(self.BtnNext, false)
    UIHelper.SetVisible(self.BtnNextSearch, false)

    UIHelper.RemoveAllChildren(self.LayoutBreadNavi)
    UIHelper.SetVisible(self.LayoutBread1, self.nCurStep == EASY_BUY_STEP.Main)
    UIHelper.SetVisible(self.ScrollViewBread2, self.nCurStep == EASY_BUY_STEP.Detail)
    UIHelper.SetVisible(self.WidgetMoney, self.nCurStep == EASY_BUY_STEP.Detail)
    UIHelper.SetVisible(self.WidgetTime, self.nCurStep == EASY_BUY_STEP.Detail)
    UIHelper.SetVisible(self.WidgetBread, self.nCurStep ~= EASY_BUY_STEP.Confirm)
    UIHelper.SetVisible(self.WidgetResult, self.nCurStep == EASY_BUY_STEP.Confirm)
    if self.nCurStep == EASY_BUY_STEP.Main then
        UIHelper.SetVisible(self.BtnNext, true)
    elseif self.nCurStep == EASY_BUY_STEP.Detail then
        local szBuyTip = HomelandData.IsJustCanGroupBuy(DataModel.nCurrentMapID) and g_tStrings.STR_HOMELAND_EASY_BUY_TIP
            or g_tStrings.STR_HOMELAND_EASY_BUY_TIP2
        UIHelper.SetString(self.LabelTime, szBuyTip)
        UIHelper.SetVisible(self.BtnBuy, true)
        UIHelper.SetVisible(self.BtnSearch, true)
    elseif self.nCurStep == EASY_BUY_STEP.Confirm then
        UIHelper.SetVisible(self.BtnBack, true)
        UIHelper.SetVisible(self.BtnNextSearch, true)
        UIHelper.LayoutDoLayout(self.LayoutRightTop)
        return
    end

    local szMapTitle = self.nCurStep == EASY_BUY_STEP.Detail and GetHomelandMapName(DataModel.nCurrentMapID) or g_tStrings.STR_LAND_LOG_TYPE_SEARCH[1]
    local tbMenuInfo = {
        [1] = {
            szOption = szMapTitle,
            fnAction = function ()
                self.nCurStep = EASY_BUY_STEP.Main
                self:UpdateBreadScreen()
            end
        },
        [2] = {
            szOption = "分线及房型",
            fnAction = function ()
                -- do nothing
            end
        }
    }
    for i = 1, self.nCurStep, 1 do
        local scriptBread = UIHelper.AddPrefab(PREFAB_ID.WidgetBreadNaviCell, self.LayoutBreadNavi)
        scriptBread:OnEnter(tbMenuInfo[i], i <= 1, tbMenuInfo[i].fnAction)
        scriptBread:SetChecked(i < self.nCurStep)
    end
    UIHelper.LayoutDoLayout(self.WidgetBottom)
    UIHelper.LayoutDoLayout(self.LayoutRightTop)
    UIHelper.LayoutDoLayout(self.LayoutBreadNavi)
end

function UIHomelandBuyQuicklyView:InitLandFilter(bUpdate)
    local nCurLandNum = table.GetCount(DataModel.tLandList)
    local nMaxLandNum = DataModel.nMaxLandNum or 0
    local tbLandList = {}
    for i = 1, nMaxLandNum, 1 do
        table.insert(tbLandList, i.."号")
    end
    FilterDef.HomelandEasyBuyHouse[1].szTitle = string.format("房号筛选(%s/8)", nCurLandNum)
    FilterDef.HomelandEasyBuyHouse[1].tbList = tbLandList
    FilterDef.HomelandEasyBuyHouse.Reset()
    if bUpdate and self.scriptLandFilter then
        self.scriptLandFilter:OnEnter(FilterDef.HomelandEasyBuyHouse)
        for _, value in ipairs(DataModel.tLandList) do
            UIHelper.SetSelected(self.scriptLandFilter.tbCompList[1][value], true, false)
        end
        for index, tog in ipairs(self.scriptLandFilter.tbCompList[1]) do
            if #DataModel.tLandList >= MAX_LAND_INDEX_NUM and not CheckIsInTable(DataModel.tLandList, index) then
                UIHelper.SetButtonState(tog, BTN_STATE.Disable)
                UIHelper.SetEnable(tog, false)
            else
                UIHelper.SetButtonState(tog, BTN_STATE.Normal)
                UIHelper.SetEnable(tog, true)
            end
        end
        return
    end

    if self.scriptLandFilter then
        UIHelper.RemoveAllChildren(self.WidgetAnchorTip)
        self.scriptLandFilter = nil
    end
    self.scriptLandFilter = UIHelper.AddPrefab(PREFAB_ID.WidgetFiltrateTip, self.WidgetAnchorTip, FilterDef.HomelandEasyBuyHouse)
    UIHelper.SetAnchorPoint(self.scriptLandFilter._rootNode, 0.5, 0.5)
end

function UIHomelandBuyQuicklyView:UpdateBuyBtn()
    local tCopyIndex = DataModel.GetCopyIndexList() or {}
    local tLandIndex = DataModel.GetLandIndexList() or {}
    local bCanNext = (DataModel.bIndexNoLimit or not IsTableEmpty(tCopyIndex)) and
        (DataModel.bLandNoLimit or not IsTableEmpty(tLandIndex))
    UIHelper.SetNodeGray(self.BtnBuy, not bCanNext, true)
    UIHelper.SetNodeGray(self.BtnSearch, not bCanNext, true)
    UIHelper.SetEnable(self.BtnBuy, bCanNext)
    UIHelper.SetEnable(self.BtnSearch, bCanNext)
end

function UIHomelandBuyQuicklyView:UpdateCostMoney()
    DataModel.UpdateMaxPrice()

    local nMinPrice = DataModel.nMinPrice
    local nMaxPrice = DataModel.nMaxPrice
    local nMinGoldBrick, nMinGold = math.floor(nMinPrice / 10000), math.mod(nMinPrice, 10000)
    local nMaxGoldBrick, nMaxGold = math.floor(nMaxPrice / 10000), math.mod(nMaxPrice, 10000)
    local tbMoney = {
        nMinGoldBrick, nMinGold,
        nMaxGoldBrick, nMaxGold,
    }
    for index, label in ipairs(self.tbForecastMoney) do
        UIHelper.SetString(label, tbMoney[index])
    end
    UIHelper.CascadeDoLayoutDoWidget(self.LayoutMoney2, true, false)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewBread2)
end

function UIHomelandBuyQuicklyView:SetCenter(dwCenterID, szCenterName)
    if dwCenterID ~= DataModel.nCenterID then
        DataModel.Set("nCenterID", dwCenterID)
        bApplyCommunityDigestFlag = true
        GetHomelandMgr().ApplyCommunityDigest(DataModel.nCurrentMapID, DataModel.nCenterID)
    end
    UIHelper.SetString(self.LabelServerName, szCenterName)
end

function UIHomelandBuyQuicklyView:SetCurrentMap(nMapID, szMapName)
    if nMapID ~= DataModel.nCurrentMapID then
        DataModel.Set("nCurrentMapID", nMapID)
        bApplyCommunityDigestFlag = true
        GetHomelandMgr().ApplyCommunityDigest(DataModel.nCurrentMapID, DataModel.nCenterID)
    end
    UIHelper.SetString(self.LabelFilterName, szMapName)
    UIHelper.SetVisible(self.ImgNewIcon, HomelandData.IsNewCommunityMap(nMapID))
    UIHelper.LayoutDoLayout(self.LayoutName)
end

function UIHomelandBuyQuicklyView:SetMinLevel(nMinLevel)
    if nMinLevel ~= DataModel.nMinLevel then
        DataModel.Set("nMinLevel", nMinLevel)
    end
end

function UIHomelandBuyQuicklyView:SetIndexNoLimit(bLimit)
    if bLimit ~= DataModel.bIndexNoLimit then
        DataModel.Set("bIndexNoLimit", bLimit)
    end
    UIHelper.SetNodeGray(self.WidgetFilterLine, bLimit, true)
    UIHelper.SetEnable(self.WidgetFilterLine, not bLimit)
    UIHelper.SetOpacity(self.WidgetFilterLine, bLimit and 160 or 255)
    self:UpdateBuyBtn()
    self:UpdateCostMoney()
end

function UIHomelandBuyQuicklyView:SetLandNoLimit(bLimit)
    if bLimit ~= DataModel.bLandNoLimit then
        DataModel.Set("bLandNoLimit", bLimit)
        for index, tog in ipairs(self.tbToggleShape_Area) do
            UIHelper.SetSelected(tog, false)
        end
        UIHelper.SetSelected(self.tbToggleShape_Area[self.nLastSelectAreaToggle], not bLimit)
    end
    UIHelper.SetNodeGray(self.WidgetFilterShape, bLimit, true)
    UIHelper.SetEnable(self.WidgetFilterShape, not bLimit)
    UIHelper.SetOpacity(self.WidgetFilterShape, bLimit and 160 or 255)
    self:UpdateBuyBtn()
    self:UpdateCostMoney()
end

function UIHomelandBuyQuicklyView:SetMinCopyIndex(nInputNum)
    local bChange = DataModel.CheckEditboxCopyIndex(nInputNum, "nMinCopyIndex")
    UIHelper.SetString(self.EditSmall, DataModel.nMinCopyIndex)
    self:UpdateBuyBtn()
    self:UpdateCostMoney()
end

function UIHomelandBuyQuicklyView:SetMaxCopyIndex(nInputNum)
    local bChange = DataModel.CheckEditboxCopyIndex(nInputNum, "nMaxCopyIndex")
    UIHelper.SetString(self.EditBig, DataModel.nMaxCopyIndex)
    self:UpdateBuyBtn()
    self:UpdateCostMoney()
end

function UIHomelandBuyQuicklyView:ChangeIndex(nLineIndex, bDelete)
    -- 分线号选择
    DataModel.ChangeIndex(nLineIndex, bDelete)

    local nCurLineNum = table.GetCount(DataModel.tIndexList)
    UIHelper.SetVisible(self.WidgetAddLine_Big, nCurLineNum == 0)
    UIHelper.SetVisible(self.WidgetAddLine, nCurLineNum > 0 and nCurLineNum < MAX_INDEX_NUM)
    UIHelper.SetVisible(self.WidgetDeleteLineTip, nCurLineNum > 0 and DataModel.bDiscreteCopyIndex)
    for i = 1, MAX_INDEX_NUM, 1 do
        local scriptCell = UIHelper.GetBindScript(self.tbWidgetLine[i])
        if i > nCurLineNum then
            UIHelper.SetVisible(scriptCell._rootNode, false)
        else
            UIHelper.SetString(scriptCell.LabelAdd, DataModel.tIndexList[i])
            UIHelper.SetVisible(scriptCell._rootNode, DataModel.tIndexList[i] and DataModel.tIndexList[i] > 0)
        end
    end
    UIHelper.SetString(self.LabelSelectedLine, string.format("已选%s/8", nCurLineNum))
    UIHelper.LayoutDoLayout(self.WidgetLineNumber)
    UIHelper.LayoutDoLayout(self.WidgetFilterLine)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewBread2)
    self:UpdateBuyBtn()
    self:UpdateCostMoney()
end

function UIHomelandBuyQuicklyView:ChangeLand(tLandIndex)
    -- 房号选择
    DataModel.ChangeLand(tLandIndex)
    local nCurLandNum = table.GetCount(DataModel.tLandList)
    UIHelper.SetVisible(self.WidgetAddShape_Big, nCurLandNum == 0)
    UIHelper.SetVisible(self.BtnAddShape, nCurLandNum > 0 and nCurLandNum < MAX_INDEX_NUM)
    UIHelper.SetVisible(self.WidgetSelectTip, nCurLandNum > 0 and DataModel.bDiscreteLandIndex)
    for i = 1, MAX_INDEX_NUM, 1 do
        local scriptCell = UIHelper.GetBindScript(self.tbWidgetShape[i])
        if i > nCurLandNum then
            UIHelper.SetVisible(scriptCell._rootNode, false)
        else
            UIHelper.SetString(scriptCell.LabelAdd, DataModel.tLandList[i])
            UIHelper.SetVisible(scriptCell._rootNode, DataModel.tLandList[i] and DataModel.tLandList[i] > 0)
        end
    end
    UIHelper.SetString(self.LabelSelectShape, string.format("已选%s/8", nCurLandNum))
    UIHelper.LayoutDoLayout(self.WidgetShape_Number)
    UIHelper.LayoutDoLayout(self.WidgetFilterShape)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewBread2)
    self:UpdateBuyBtn()
    self:UpdateCostMoney()
end

function UIHomelandBuyQuicklyView:SearchLand()
    if not self.scriptSearchResult then
        self.scriptSearchResult = UIHelper.GetBindScript(self.WidgetResult)
    end

    local tSearch =
    {
        dwCenterID = DataModel.nCenterID,
        dwMapID = DataModel.nCurrentMapID,
        bDiscrete = DataModel.bDiscreteCopyIndex,
        tIndexList = DataModel.GetCopyIndexList(),
        tLandIndexList = DataModel.GetLandIndexList(),
        bIndexNoLimit = DataModel.bIndexNoLimit,
        bLandNoLimit = DataModel.bLandNoLimit,
        nCommunityLevel = DataModel.nMinLevel,
        nLastCommunityIndex = 0
    }
    self.nCurStep = EASY_BUY_STEP.Confirm
    self:UpdateBreadScreen()
    self.scriptSearchResult:OnEnter(tSearch)
end

function UIHomelandBuyQuicklyView:BuyLandCheck()
    if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.SHOP, "Land") then
        return
    end
    local tCopyIndex = DataModel.GetCopyIndexList()
    local tLandIndex = DataModel.GetLandIndexList()

    RemoteCallToServer("On_HomeLand_FastBuy",
    DataModel.nCenterID,
    DataModel.nCurrentMapID,
    DataModel.bDiscreteCopyIndex,
    tCopyIndex,
    tLandIndex,
    DataModel.bIndexNoLimit,
    DataModel.bLandNoLimit,
    DataModel.nMinLevel)
end

return UIHomelandBuyQuicklyView
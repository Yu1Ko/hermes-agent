-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIYinshanLineView
-- Date: 2024-03-22 10:50:09
-- Desc: PanelYinshanLine
-- ---------------------------------------------------------------------------------

local UIYinshanLineView = class("UIYinshanLineView")

local LIMIT_TIME = 5000    -- 据点信息刷新cd
local BATTLE_RANK_ID = 282 -- 大小攻防分线数量

local tMapID = -- 分线地图ID
{
    [1] = 216,
    dwCommonMapID = 656
}

-----------------------------DataModel------------------------------
local DataModel = {}

function DataModel.Init()
    DataModel.tCastleInfo   = {}
    DataModel.nSelCopyIndex = 1
    DataModel.nCopyIndexNum = 0
    DataModel.tBranchNumber = {}

    ApplyCustomRankList(BATTLE_RANK_ID)
end

function DataModel.UnInit()
    DataModel.tCastleInfo   = nil
    DataModel.nSelCopyIndex = nil
    DataModel.nCopyIndexNum = nil
    DataModel.tBranchNumber = nil
end

function DataModel.SetCastleInfo(tAllCastleInfo)
    DataModel.tCastleInfo = tAllCastleInfo
end

function DataModel.IsInCastleActivity()
    local nCurrentTime = GetCurrentTime()
    local tData = TimeToDate(nCurrentTime)

    if tData.weekday == 2 or tData.weekday == 4 then
        local bOn = ActivityData.IsActivityOn(ACTIVITY_ID.CASTLE) or UI_IsActivityOn(ACTIVITY_ID.CASTLE)
        return bOn
    end
    return false
end

function DataModel.GetCastleMapID(nCopyIndex)
    if tMapID[nCopyIndex] then
        return tMapID[nCopyIndex]
    else
        return tMapID.dwCommonMapID
    end
end

function DataModel.GetDoubleDigitCopyIndex(nCopyIndex)
    local szCopyIndex = ""
    local nEndCopyIndex = nCopyIndex
    if not tMapID[nCopyIndex] then
        nEndCopyIndex = nCopyIndex - 1
    end
    if nEndCopyIndex / 10 < 1 then
        szCopyIndex = "0" .. nEndCopyIndex
    else
        szCopyIndex = nEndCopyIndex
    end
    return szCopyIndex
end

function DataModel.UpdateBranchPlayerNum()
    local bInActivity = DataModel.IsInCastleActivity()
    if not bInActivity then
        return
    end

    local tMapNumber = GetCampPlayerCountPerMap()
    if not tMapNumber or IsTableEmpty(tMapNumber) then
        return
    end
    local tBranchNumber = {}
    for i = 1, DataModel.nCopyIndexNum do
        for _, tNumber in pairs(tMapNumber) do
            if tMapID[i] and tNumber.dwMapID == tMapID[i] then
                tBranchNumber[i] = tNumber
                break
            elseif tNumber.dwMapID == tMapID.dwCommonMapID and tNumber.nCopyIndex == i - 1 then
                tBranchNumber[i] = tNumber
                break
            end
        end
    end
    DataModel.tBranchNumber = tBranchNumber
end

function DataModel.IsPlayerLocalBranch(nBranchIndex)
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end
    local bCurBranch = false
    local hScene     = pPlayer.GetScene()
    local dwCurMapID = hScene.dwMapID
    local nCopyIndex = hScene.nCopyIndex
    if tMapID[nBranchIndex] then
        local dwBranchMapID = tMapID[nBranchIndex]
        if dwCurMapID == dwBranchMapID then
            bCurBranch = nCopyIndex == nBranchIndex
        end
    else
        local dwBranchMapID = tMapID.dwCommonMapID
        if dwCurMapID == dwBranchMapID then
            bCurBranch = nCopyIndex == nBranchIndex - 1
        end
    end
    return bCurBranch
end

-----------------------------View------------------------------

function UIYinshanLineView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    DataModel.Init()
    self:InitUI()

    RemoteCallToServer("On_Castle_GetBranchTipsRequest") --On_Camp_GetBranchInfo
end

function UIYinshanLineView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    DataModel.UnInit()
end

function UIYinshanLineView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
    UIHelper.BindUIEvent(self.ButtonClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
    UIHelper.BindUIEvent(self.BtnComplete, EventType.OnClick, function()
        if DataModel.nSelCopyIndex then
            local nSelCopyIndex = DataModel.nSelCopyIndex
            local dwMapID    = DataModel.GetCastleMapID(nSelCopyIndex)
            local szCopyName = FormatString(g_tStrings.STR_BATTLE_BRANCH_NAME, nSelCopyIndex)
            local dialog = UIHelper.ShowConfirm(FormatString(g_tStrings.STR_BATTLE_BRANCH_ENTER_MSG, szCopyName), function()
                CampData.CampTransfer(CampData.YINSHAN_MAP, nSelCopyIndex)
            end)
            dialog:SetConfirmButtonContent(g_tStrings.WORLD_MAP_TO)
            dialog:SetCancelButtonContent(g_tStrings.STR_HOTKEY_CANCEL)
        end
    end)
end

function UIYinshanLineView:RegEvent()
    Event.Reg(self, "CUSTOM_RANK_UPDATE", function(nRankListID)
        if nRankListID == BATTLE_RANK_ID then
            print("[Yinshan] CUSTOM_RANK_UPDATE", nRankListID)
            self:InitBranchTitleList()
            RemoteCallToServer("On_Castle_GetBranchTipsRequest") --申请所有分线的数据 On_Camp_GetBranchInfo
        end
    end)
    Event.Reg(self, "ON_MAP_PLAYER_COUNT_UPDATE", function()
        --print("[Yinshan] ON_MAP_PLAYER_COUNT_UPDATE")
        self:UpdateTitleList()
    end)

    Event.Reg(self, "On_Camp_GetBranchInfo", function(tAllCastleInfo)
        --print_table("[Yinshan] On_Camp_GetBranchInfo", tAllCastleInfo)
        --Request: On_Castle_GetBranchTipsRequest

        --tAllCastleInfo数据格式
        -- tAllCastleInfo = {
        -- 	[dwCastleID] = {
        -- 		nCastleState = 0, --分线是否开启，1为开启，0为不开，暂未用到
        -- 		nActivityState = 0, （城池活动状态，0为不可被攻击，1为可被攻击。活动期间有效）
        -- 		nCamp = 0, （当前阵营归属）
        -- 		nGrainState = 0, （粮仓状态，0为还没洗劫空， 1为被洗劫）
        -- 	},
        -- }
        if not tAllCastleInfo or GetTableCount(tAllCastleInfo) == 0 then
            return
        end
        if IsTableEqual(tAllCastleInfo, DataModel.tCastleInfo) then
            return
        end
        DataModel.SetCastleInfo(tAllCastleInfo)
        self:UpdateBranchDetail()
    end)
end

function UIYinshanLineView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIYinshanLineView:InitUI()
    self.tTitleScript = {}
    self.tCastleWidget = {}

    local function _getCampWidgetTable(widgetParent, szPrefix, dwCastleID, bAssertNeutral)
        assert(widgetParent)

        local tWidget = {}
        local szAssert = widgetParent:getName() .. "/" .. szPrefix .. dwCastleID
        local widgetNeutral = widgetParent:getChildByName(szPrefix .. dwCastleID .. "_N") assert(not bAssertNeutral or widgetNeutral, szAssert)
        local widgetGood    = widgetParent:getChildByName(szPrefix .. dwCastleID .. "_J") assert(widgetGood, szAssert)
        local widgetEvil    = widgetParent:getChildByName(szPrefix .. dwCastleID .. "_E") assert(widgetEvil, szAssert)
        tWidget[CAMP.NEUTRAL] = widgetNeutral
        tWidget[CAMP.GOOD] = widgetGood
        tWidget[CAMP.EVIL] = widgetEvil

        UIHelper.SetVisible(widgetNeutral, true)
        UIHelper.SetVisible(widgetGood, false)
        UIHelper.SetVisible(widgetEvil, false)

        return tWidget
    end

    local function _bindUIEvent(dwCastleID, tWidgetInfo)
        UIHelper.BindUIEvent(tWidgetInfo.togBig, EventType.OnSelectChanged, function(_, bSelected)
            self:OnCastleSelect(bSelected and dwCastleID)
        end)
    end

    local function _initCastleWidget(nIndex)
        local widgetMap    = self.WidgetCampMapYinshan:getChildByName("WidgetCampMapYinshan" .. nIndex)         assert(widgetMap,   nIndex)
        local imgMapFight  = widgetMap                :getChildByName("ImgCampMapYinshan"    .. nIndex .. "_F") assert(imgMapFight, nIndex)

        local togBig        = widgetMap:getChildByName("TogCampMapBigYinshan"   .. nIndex) assert(togBig, nIndex)
        local widgetSelect  = togBig   :getChildByName("WidgetSelectYinshan"    .. nIndex) assert(widgetSelect,  nIndex)
        local widgetBigBarn = togBig   :getChildByName("WidgetLiangcangYinshan" .. nIndex) assert(widgetBigBarn, nIndex)
        local labelNameBig  = togBig   :getChildByName("LabelNameBigYinshan"    .. nIndex) assert(labelNameBig,  nIndex)

        local tImgCampBg  = _getCampWidgetTable(widgetMap,     "ImgCampMapYinshan",      nIndex, true)
        local tImgBigBg   = _getCampWidgetTable(togBig,        "ImgBtnBgBigYinshan",     nIndex, true)
        local tImgBigBarn = _getCampWidgetTable(widgetBigBarn, "ImgBigLiangcangYinshan", nIndex)
        local tImgSelect  = _getCampWidgetTable(widgetSelect,  "ImgSelectYinshan",       nIndex, true)

        local imgBigBarn_Broke = widgetBigBarn:getChildByName("ImgBigLiangcangYinshan" .. nIndex .. "_F") assert(imgBigBarn_Broke,    nIndex)

        local tWidgetInfo = {
            widgetMap         = widgetMap,        --地图Widget
            imgMapFight       = imgMapFight,      --地图战斗
            tImgCampBg        = tImgCampBg,       --地图底色
            togBig            = togBig,           --大按钮
            tImgBigBg         = tImgBigBg,        --大按钮底色
            widgetSelect      = widgetSelect,     --选中Widget
            tImgSelect        = tImgSelect,       --大按钮-选中态底色
            widgetBigBarn     = widgetBigBarn,    --大按钮-粮仓
            tImgBigBarn       = tImgBigBarn,      --大按钮-粮仓底色
            imgBigBarn_Broke  = imgBigBarn_Broke, --大按钮-粮仓毁坏

            nIndex           = nIndex,
        }

        _bindUIEvent(nIndex, tWidgetInfo)

        --初始隐藏
        UIHelper.SetVisible(imgMapFight, false)
        UIHelper.SetVisible(togBig, false)
        UIHelper.SetVisible(widgetSelect, false)
        UIHelper.SetVisible(widgetBigBarn, false)
        UIHelper.SetVisible(imgBigBarn_Broke, false)

        --固定常亮
        UIHelper.SetSelected(togBig, true, false)
        UIHelper.SetTouchEnabled(togBig, false)

        self.tCastleWidget[nIndex] = tWidgetInfo
    end

    _initCastleWidget(1)
    _initCastleWidget(2)

    Timer.DelAllTimer(self)
    Timer.AddCycle(self, 5, function()
        RemoteCallToServer("On_Castle_GetBranchTipsRequest") --On_Camp_GetBranchInfo
    end)

    local szText = FormatString(g_tStrings.STR_PLAYER_COUNT, "0/200")
    UIHelper.SetString(self.LabelYinshanNum, szText)
end

function UIYinshanLineView:InitBranchTitleList()
    local tCopyIndexlist = GetCustomRankListByID(BATTLE_RANK_ID, 1)
    DataModel.nCopyIndexNum = tCopyIndexlist and tCopyIndexlist.nKey or 0

    self.tTitleScript = {}
    UIHelper.RemoveAllChildren(self.ScrollViewLinelist)
    for i = 1, DataModel.nCopyIndexNum do
        local nCopyIndex = i
        local scriptView = UIHelper.AddPrefab(PREFAB_ID.WidgetYinshanLineLIstTog, self.ScrollViewLinelist, nCopyIndex)
        self.tTitleScript[nCopyIndex] = scriptView
        local bSel = DataModel.nSelCopyIndex == nCopyIndex
        scriptView:SetPlayerNum(0, 200)
        scriptView:SetNowVisible(false)
        scriptView:SetSelected(bSel, false)
        scriptView:SetSelectedCallback(function(bSelected)
            if bSelected then
                self:OnSelBranchTitle(nCopyIndex)
            end
        end)
    end
    self:UpdateTitleList()
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewLinelist)
end

function UIYinshanLineView:UpdateTitleList()
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end

    DataModel.UpdateBranchPlayerNum()
    for i, scriptView in ipairs(self.tTitleScript) do
        local nCopyIndex = scriptView.nCopyIndex
        local tNumber = DataModel.tBranchNumber[nCopyIndex]
        if tNumber then
            local bCurBranch = DataModel.IsPlayerLocalBranch(nCopyIndex)
            scriptView:SetNowVisible(bCurBranch)

            local nCamp = pPlayer.nCamp
            if nCamp == CAMP.GOOD then
                scriptView:SetPlayerNum(tNumber.nGoodPlayerCount, tNumber.nMaxGoodPlayerCount)
                if scriptView:GetSelected() then
                    local szText = FormatString(g_tStrings.STR_PLAYER_COUNT, tNumber.nGoodPlayerCount .. "/" .. tNumber.nMaxGoodPlayerCount)
                    UIHelper.SetString(self.LabelYinshanNum, szText)
                end
            elseif nCamp == CAMP.EVIL then
                scriptView:SetPlayerNum(tNumber.nEvilPlayerCount, tNumber.nMaxEvilPlayerCount)
                if scriptView:GetSelected() then
                    local szText = FormatString(g_tStrings.STR_PLAYER_COUNT, tNumber.nEvilPlayerCount .. "/" .. tNumber.nMaxEvilPlayerCount)
                    UIHelper.SetString(self.LabelYinshanNum, szText)
                end
            end
        end
    end
end

function UIYinshanLineView:UpdateBranchDetail()
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end
    if not DataModel.nSelCopyIndex then
        return
    end
    local nSelCopyIndex = DataModel.nSelCopyIndex
    local szName = FormatString(g_tStrings.STR_BATTLE_BRANCH_NAME, nSelCopyIndex)
    UIHelper.SetString(self.LabelYinshanName, szName)

    if DataModel.tBranchNumber[nSelCopyIndex] then
        local tPlayerNum = DataModel.tBranchNumber[nSelCopyIndex]
        if pPlayer.nCamp == CAMP.GOOD then
            local szText = FormatString(g_tStrings.STR_PLAYER_COUNT, tPlayerNum.nGoodPlayerCount .. "/" .. tPlayerNum.nMaxGoodPlayerCount)
            UIHelper.SetString(self.LabelYinshanNum, szText)
        elseif pPlayer.nCamp == CAMP.EVIL then
            local szText = FormatString(g_tStrings.STR_PLAYER_COUNT, tPlayerNum.nEvilPlayerCount .. "/" .. tPlayerNum.nMaxEvilPlayerCount)
            UIHelper.SetString(self.LabelYinshanNum, szText)
        end
    end

    self:SetCastleInfo(1)
    self:SetCastleInfo(2)
end

function UIYinshanLineView:SetCastleInfo(nIndex)
    if not DataModel.nSelCopyIndex then
        return
    end
    local nSelCopyIndex = DataModel.nSelCopyIndex
    local dwMapID = DataModel.GetCastleMapID(nSelCopyIndex)
    local szCopyIndex = DataModel.GetDoubleDigitCopyIndex(nSelCopyIndex)
    local szCastleID = dwMapID .. nIndex .. szCopyIndex
    local dwCastleID = tonumber(szCastleID)
    if not dwCastleID or not DataModel.tCastleInfo then
        return
    end
    local tCastleInfo = DataModel.tCastleInfo[dwCastleID]
    if not tCastleInfo then
        return
    end

    local tWidgetInfo = self.tCastleWidget[nIndex]
    if not tWidgetInfo then
        return
    end

    local function _updateWidgetStateByCamp(tCampWidget, nCamp)
        UIHelper.SetVisible(tCampWidget[CAMP.NEUTRAL], nCamp == CAMP.NEUTRAL)
        UIHelper.SetVisible(tCampWidget[CAMP.GOOD], nCamp == CAMP.GOOD)
        UIHelper.SetVisible(tCampWidget[CAMP.EVIL], nCamp == CAMP.EVIL)
    end

    local bActivityOn = DataModel.IsInCastleActivity()
    local nCamp = tCastleInfo.nCamp
    local nActivityState = tCastleInfo.nActivityState

    --粮仓
    local bShowBarn = tCastleInfo.nGrainState == 0 --0可被攻击 1已毁坏
    local nBarnCamp = bActivityOn and bShowBarn and nCamp
    local bShowBrokeBarn = bActivityOn and not bShowBarn

    local tWidgetInfo = self.tCastleWidget[nIndex]
    UIHelper.SetVisible(tWidgetInfo.imgMapFight, bActivityOn and nActivityState == 1)
    UIHelper.SetVisible(tWidgetInfo.togBig, true)

    _updateWidgetStateByCamp(tWidgetInfo.tImgBigBg, nCamp)
    _updateWidgetStateByCamp(tWidgetInfo.tImgBigBarn, nBarnCamp)
    UIHelper.SetVisible(tWidgetInfo.imgBigBarn_Broke, bShowBrokeBarn)
    UIHelper.SetVisible(tWidgetInfo.widgetBigBarn, bActivityOn and bShowBarn)

    _updateWidgetStateByCamp(tWidgetInfo.tImgCampBg, nCamp)
    _updateWidgetStateByCamp(tWidgetInfo.tImgSelect, nCamp)
end

function UIYinshanLineView:OnSelBranchTitle(nCopyIndex)
    local nLastCopyIndex = DataModel.nSelCopyIndex
    local lastScriptView = self.tTitleScript[nLastCopyIndex]
    if lastScriptView then
        lastScriptView:SetSelected(false)
    end

    DataModel.nSelCopyIndex = nCopyIndex
    self:UpdateBranchDetail()
end

return UIYinshanLineView
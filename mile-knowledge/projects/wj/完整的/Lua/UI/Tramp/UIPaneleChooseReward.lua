-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPaneleChooseReward
-- Date: 2023-04-11 20:18:15
-- Desc: ?
-- ---------------------------------------------------------------------------------

local PAGE_TYPE = {
    MAP = 1,
    ITEM = 2,
    SKILL = 3,
}

local REWARD_TYPE = {
    PROP = 0,
    BUFF = 1,
}

local CONFIRM_MAP_CD_TIME = 3000 -- 确认地图间隔时间

local UIPaneleChooseReward = class("UIPaneleChooseReward")

function UIPaneleChooseReward:OnEnter(...)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    local tbArgs = {...}
    if #tbArgs == 1 then
        self.tbReward = tbArgs[1]
    else
        self:InitMapInfo(tbArgs)
    end
    self:UpdateInfo()
end

function UIPaneleChooseReward:InitMapInfo(tbArgs)
    self.tbMapInfos = tbArgs[1]
    self.nTargetType = tbArgs[2]
    self.nTargetID = tbArgs[3]
    for _, tMapInfo in ipairs(self.tbMapInfos) do
        local tLine = Table_GetVagabondCrossMapInfo(tMapInfo.nMapID)
        tMapInfo.szImgPath = tLine.szMBImagePath
        tMapInfo.nImgFrame = tLine.nImgFrame
        tMapInfo.szTip = tLine.szTip
    end
end

function UIPaneleChooseReward:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPaneleChooseReward:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnCalloff, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnOk, EventType.OnClick, function()
        if self.nMapID then
            local nNow = GetTickCount()
            if self.nLastConfirmMapTime and nNow - self.nLastConfirmMapTime < CONFIRM_MAP_CD_TIME then
                return
            end

            self.nLastConfirmMapTime = nNow

            RemoteCallToServer("On_LangKeXing_ConfirmMap", self.nMapID)
            UIMgr.Close(self)
        end
        if self.tbItemInfo then
            RemoteCallToServer("On_LangKeXing_RewardChoose", self.tbItemInfo.nRewardType, self.tbItemInfo.nID, self.tbItemInfo.nType or self.tbItemInfo.nLevel, self.tbItemInfo.nIndex)
            UIMgr.Close(self)
        end
    end)
end

function UIPaneleChooseReward:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, EventType.HideAllHoverTips, function()
        self:CloseCurTips()
    end)
end

function UIPaneleChooseReward:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPaneleChooseReward:UpdateInfo()
    UIHelper.RemoveAllChildren(self.ScrollViewMapEntranceList)
    if self.tbReward then
        for index, tbItem in ipairs(self.tbReward) do
            tbItem.nIndex = index
            if tbItem.nRewardType == REWARD_TYPE.PROP then
                UIHelper.AddPrefab(PREFAB_ID.WidgetRewardChooseOne, self.ScrollViewMapEntranceList, tbItem, self.ToggleGroup, index == 1, self)
            elseif tbItem.nRewardType == REWARD_TYPE.BUFF then
                UIHelper.AddPrefab(PREFAB_ID.WidgetSkillChooseOne, self.ScrollViewMapEntranceList, tbItem, self.ToggleGroup, index == 1, self)
            end
        end
        UIHelper.ScrollViewDoLayout(self.ScrollViewMapEntranceList)
        UIHelper.ScrollToLeft(self.ScrollViewMapEntranceList)
        UIHelper.SetSwallowTouches(self.ScrollViewMapEntranceList, false)
    else
        for index, tbMapInfo in ipairs(self.tbMapInfos) do
            local scriptView =  UIHelper.AddPrefab(PREFAB_ID.WidgetMapEntranceLKX, self.ScrollViewMapEntranceList, tbMapInfo, self.ToggleGroup, index == 1, self)
        end
        UIHelper.LayoutDoLayout(self.ScrollViewMapEntranceList)
        -- UIHelper.ScrollToLeft(self.ScrollViewMapEntranceList)
        UIHelper.SetSwallowTouches(self.ScrollViewMapEntranceList, false)
    end
    UIHelper.AddPrefab(PREFAB_ID.WidgetTaskBuff, self.WidgetTaskBuff, TimeBuffData.GetBuffList())
    Timer.AddFrame(self, 1, function()
        UIHelper.SetToggleGroupSelected(self.ToggleGroup, 0)
    end)
end

function UIPaneleChooseReward:SetMapID(nMapID)
    self.nMapID = nMapID
end

function UIPaneleChooseReward:SetItemInfo(tbItemInfo)
    self.tbItemInfo = tbItemInfo
end


function UIPaneleChooseReward:OpenTips(nPrefabID, Parent, ...)
    self:CloseCurTips()
    self.nCurPrefabID = nPrefabID
    if nPrefabID == PREFAB_ID.WidgetItemTip then
        local tbArgs = {...}
        local nTabType = tbArgs[1]
        local nTabID = tbArgs[2]
        self.scriptViewItemIcon = tbArgs[3] and tbArgs[3] or nil
        self.tips, self.tipsScriptView = TipsHelper.ShowNodeHoverTips(nPrefabID, Parent)
        self.tipsScriptView:OnInitWithTabID(nTabType, nTabID)
        self.tipsScriptView:SetBtnState({})
    else
        local tbArgs = {...}
        local szTitle = tbArgs[1]
        local szDesc = tbArgs[2]
        self.scriptViewItemIcon = tbArgs[3] and tbArgs[3] or nil
        self.CurToggle = tbArgs[4] or nil
        self.tips, self.tipsScriptView = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetMapTipsLKX, Parent, UIHelper.GBKToUTF8(szTitle), szDesc)
    end
end

function UIPaneleChooseReward:CloseCurTips()
    if self.nCurPrefabID then
        TipsHelper.DeleteHoverTips(self.nCurPrefabID)
        if self.scriptViewItemIcon then
            self.scriptViewItemIcon:RawSetSelected(false)
        end
        if self.CurToggle then
            UIHelper.SetSelected(self.CurToggle, false, false)
        end
        self.nCurPrefabID = nil
    end
end



return UIPaneleChooseReward
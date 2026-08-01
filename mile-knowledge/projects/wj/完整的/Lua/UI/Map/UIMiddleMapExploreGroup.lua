-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIMiddleMapExploreGroup
-- Date: 2025-09-25 10:55:29
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIMiddleMapExploreGroup = class("UIMiddleMapExploreGroup")

function UIMiddleMapExploreGroup:OnEnter(tInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nType        = tInfo.nType
    self.dwMapID      = tInfo.dwMapID or 0
    self.tSubTypeList = tInfo.tSubTypeList or {}
    self.nFinishCount = tInfo.nFinishCount or 0
    self.nTotalCount  = tInfo.nTotalCount or 0
    self:UpdateInfo()
end

function UIMiddleMapExploreGroup:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIMiddleMapExploreGroup:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnAward, EventType.OnClick, function()
        local bVis = UIHelper.GetVisible(self.WidgetReward)
        UIHelper.SetVisible(self.WidgetReward, not bVis)
        if self.scriptIcon then
            self.scriptIcon:SetSelected(false)
        end
        Event.Dispatch("SHOW_EXPLORE_MORE_REWARD", self.dwID, not bVis)
        if self.bCanGet then
            RemoteCallToServer("On_Explore_GetReward", self.dwID, self.dwMapID)
            return
        end
    end)
    UIHelper.SetTouchEnabled(self.WidgetReward, true)
end

function UIMiddleMapExploreGroup:RegEvent()
    Event.Reg(self, EventType.HideAllHoverTips, function()
        UIHelper.SetVisible(self.WidgetReward, false)
    end)

    Event.Reg(self, "SHOW_EXPLORE_MORE_REWARD", function(dwID, bShow)
        if not self.dwID or self.dwID ~= dwID then
            if self.scriptIcon then
                self.scriptIcon:SetSelected(false)
            end
            UIHelper.SetVisible(self.WidgetReward, false)
        end
    end)
end

function UIMiddleMapExploreGroup:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIMiddleMapExploreGroup:UpdateInfo()
    local tTypeInfo = MapHelper.GetMapExploreTypeInfo(self.nType)
    if not tTypeInfo then
        return
    end

    local szNum  = string.format("%d/%d", self.nFinishCount, self.nTotalCount)
    local szName = UIHelper.GBKToUTF8(tTypeInfo.szName)
    UIHelper.SetString(self.LabelExploreNum, szNum)
    UIHelper.SetString(self.LabelExploreTitle, szName)

    UIHelper.RemoveAllChildren(self.LayoutExplore)
    for nType, v in pairs(self.tSubTypeList) do
        local tCellInfo = {
            nType        = nType,
            nFinishCount = v.nFinishCount,
            nTotalCount  = v.nTotalCount,
        }
        local ScriptCell = UIHelper.AddPrefab(PREFAB_ID.WidgetMapExploreCell, self.LayoutExplore, tCellInfo)
    end
    UIHelper.LayoutDoLayout(self.LayoutExplore)
    
    self.tRewardList = {}
    local tReward = MapHelper.GetMapExploreReward(self.dwMapID, self.nType)
    tReward = tReward and tReward[1] or {}
    local t = SplitString(tReward.szReward, ";")
    self.dwID = tReward.dwID
    local bCanGet = self.nFinishCount >= self.nTotalCount
    local bFinish = QuestData.IsCompleted(tReward.dwQuestID)
    if not bCanGet then
        UIHelper.SetNodeGray(self.BtnAward, true, true)
    elseif not bFinish then
        UIHelper.SetVisible(self.ImgRedDot, true)
        UIHelper.SetVisible(self.LabelState, true)
        UIHelper.SetString(self.LabelState, g_tStrings.REGRESSION_STATE_CAN_HAVE)
        UIHelper.SetNodeGray(self.BtnAward, false, true)
    else
        UIHelper.SetVisible(self.ImgRedDot, false)
        UIHelper.SetVisible(self.LabelState, true)
        UIHelper.SetString(self.LabelState, g_tStrings.REGRESSION_STATE_ALL_USED)
        UIHelper.SetNodeGray(self.BtnAward, true, true)
    end
    self.bCanGet = bCanGet and not bFinish

    UIHelper.RemoveAllChildren(self.LayoutRewardList)
    for _, v in pairs(t) do
        local tItem     = SplitString(v, "_")
        local dwTabType = tonumber(tItem[1])
        local dwIndex   = tonumber(tItem[2])
        local nCount    = tonumber(tItem[3])
        local script    = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_44, self.LayoutRewardList)
        script:OnInitWithTabID(dwTabType, dwIndex, nCount)
        script:SetTouchDownHideTips(false)
        script:SetSelectChangeCallback(function(nItemID, bSelected, dwTabType, dwIndex)
            if bSelected then
                if self.scriptIcon then
                    self.scriptIcon:SetSelected(false)
                end
                local tips, scriptTip = TipsHelper.ShowItemTips(script._rootNode, dwTabType, dwIndex, false)
                self.scriptIcon = script
            else
                TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetItemTip)
                self.scriptIcon = nil
            end
        end)
    end
    UIHelper.LayoutDoLayout(self.LayoutRewardList)
    UIHelper.SetSwallowTouches(self.WidgetReward, true)
    UIHelper.SetTouchDownHideTips(self.WidgetReward, false)
end


return UIMiddleMapExploreGroup
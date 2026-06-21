-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelRoadChivalrousRightPop
-- Date: 2023-04-06 18:44:00
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPanelRoadChivalrousRightPop = class("UIPanelRoadChivalrousRightPop")

function UIPanelRoadChivalrousRightPop:OnEnter(nSubModuleID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nSubModuleID = nSubModuleID
    self.nState = RoadChivalrousData.GetSubModuleState(self.nSubModuleID)
    self:UpdateInfo()
end

function UIPanelRoadChivalrousRightPop:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelRoadChivalrousRightPop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnAnew, EventType.OnClick, function()
        RemoteCallToServer("On_DaXiaZhiLu_RestartSubModule", self.nSubModuleID)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnAccept, EventType.OnClick, function()
        RemoteCallToServer("On_DaXiaZhiLu_AcceptSubModule", self.nSubModuleID)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnGetReward, EventType.OnClick, function()
        RemoteCallToServer("On_DaXiaZhiLu_GetSubModuleGift", self.nSubModuleID)
        UIMgr.Close(self)
    end)
end

function UIPanelRoadChivalrousRightPop:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIPanelRoadChivalrousRightPop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelRoadChivalrousRightPop:UpdateInfo()
    self:UpdateInfo_Name()
    self:UpdateInfo_ScrollViewDetail()
    self:UpdateInfo_Award()
    self:UpdateInfo_BtnState()
    self:UpdateInfo_Tips()
end

function UIPanelRoadChivalrousRightPop:UpdateInfo_ScrollViewDetail()
    self:UpdateInfo_Process()
    self:UpdateInfo_LimitLevel()
    self:UpdateInfo_LimitNumber()
    self:UpdateInfo_Time()
    self:UpdateInfo_Type()

    UIHelper.ScrollViewDoLayout(self.ScrollViewDetail)
    UIHelper.ScrollToTop(self.ScrollViewDetail)
end

function UIPanelRoadChivalrousRightPop:UpdateInfo_Name()
    local szName = RoadChivalrousData.GetSubModuleName(self.nSubModuleID)
    UIHelper.SetString(self.LabelTitle, UIHelper.GBKToUTF8(szName))
end

function UIPanelRoadChivalrousRightPop:UpdateInfo_Process()
    local tbQuestID = RoadChivalrousData.GetSubModuleQuests(self.nSubModuleID)
    for index, nQuestID in ipairs(tbQuestID) do
        local szQuestName = RoadChivalrousData.GetQuestName(nQuestID)
        local bFinished = QuestData.IsFinished(nQuestID)
        UIHelper.AddPrefab(PREFAB_ID.WidgetRightPopLabel, self.LayoutTaskLabel, UIHelper.GBKToUTF8(szQuestName), bFinished)
    end
    UIHelper.LayoutDoLayout(self.LayoutTaskLabel)
    UIHelper.LayoutDoLayout(self.LayoutTask)
end

function UIPanelRoadChivalrousRightPop:UpdateInfo_LimitLevel()
    local szText = RoadChivalrousData.GetSubModuleLimitLevel(self.nSubModuleID)
    UIHelper.SetString(self.LabelLevel01, szText)
end

function UIPanelRoadChivalrousRightPop:UpdateInfo_LimitNumber()
    local szText = RoadChivalrousData.GetSubModuleLimitNumber(self.nSubModuleID)
    UIHelper.SetString(self.LabelNum01, szText)
end

function UIPanelRoadChivalrousRightPop:UpdateInfo_Time()
    local tbLimitTime = RoadChivalrousData.GetSubModuleLimitTime(self.nSubModuleID)
	local tString = {} 

	if tbLimitTime["StartTime"] == 0 and tbLimitTime["EndTime"] == 24 then
		tString = 
		{
			-- g_tStrings.STR_ROAD_CHIVALROUS_LIMIT_TIME,
			g_tStrings.CALENDER_ALL_DAY
		}
	elseif tbLimitTime["StartTime"] >= tbLimitTime["EndTime"] then
		tString = 
		{
			-- g_tStrings.STR_ROAD_CHIVALROUS_LIMIT_TIME,
			tbLimitTime["StartTime"],
			g_tStrings.STR_ROAD_CHIVALROUS_POINT,
			g_tStrings.DTR_ROAD_CHIVALROUS_TO,
			g_tStrings.STR_ROAD_CHIVALROUS_TOMORROW,
			tbLimitTime["EndTime"],
			g_tStrings.STR_ROAD_CHIVALROUS_POINT
		}
	else
		tString = 
		{
			-- g_tStrings.STR_ROAD_CHIVALROUS_LIMIT_TIME,
			tbLimitTime["StartTime"],
			g_tStrings.STR_ROAD_CHIVALROUS_POINT,
			g_tStrings.DTR_ROAD_CHIVALROUS_TO,
			tbLimitTime["EndTime"],
			g_tStrings.STR_ROAD_CHIVALROUS_POINT
		}
	end
    local szTime = table.concat(tString)
    UIHelper.SetString(self.LabelTime01, szTime)
end

function UIPanelRoadChivalrousRightPop:UpdateInfo_Type()
    local szText = RoadChivalrousData.GetSubModuleTips(self.nSubModuleID)
    UIHelper.SetString(self.LabelType01, szText)
end

function UIPanelRoadChivalrousRightPop:UpdateInfo_Award()
    local tbItemList = RoadChivalrousData.GetSubModuleReward(self.nSubModuleID)
    for index, tbItemInfo in ipairs(tbItemList) do
        local hItemInfo = GetItemInfo(tbItemInfo.nItemType, tbItemInfo.nItemIndex)
        local szName = UIHelper.GBKToUTF8(ItemData.GetItemNameByItemInfo(hItemInfo))
        local nCount = tbItemInfo.nItemNum
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetAwardItem1, self.ScrollViewAward, szName, nCount, tbItemInfo.nItemType, tbItemInfo.nItemIndex)
        script:SetClickCallback(function ()
            TipsHelper.DeleteAllHoverTips()
            local uiTips, uiItemTipScript = TipsHelper.ShowItemTips(script._rootNode, tbItemInfo.nItemType, tbItemInfo.nItemIndex)
            uiItemTipScript:SetBtnState({})
        end)
    end
    UIHelper.ScrollViewDoLayout(self.ScrollViewAward)
    UIHelper.ScrollToTop(self.ScrollViewAward)
    UIHelper.SetVisible(self.WidgetNoReward, #tbItemList == 0)
end

function UIPanelRoadChivalrousRightPop:UpdateInfo_BtnState()
    local nState = self.nState
    UIHelper.SetVisible(self.BtnAnew, nState == ROAD_CHIVALROUS_SUBMODULE_STATE.INCOMPLETED and RoadChivalrousData.SubModuleHasAccept(self.nSubModuleID))
    UIHelper.SetVisible(self.BtnAccept, not RoadChivalrousData.SubModuleHasAccept(self.nSubModuleID) and nState ~= ROAD_CHIVALROUS_SUBMODULE_STATE.INACTIVATED)
    UIHelper.SetVisible(self.BtnGetReward, nState == ROAD_CHIVALROUS_SUBMODULE_STATE.COMPLETED_NOT_GOT_REWARDS)
end

function UIPanelRoadChivalrousRightPop:UpdateInfo_Tips()
    local nState = self.nState
    UIHelper.SetVisible(self.WidgetLabelTip01, nState == ROAD_CHIVALROUS_SUBMODULE_STATE.COMPLETED_GOT_REWARDS)
    UIHelper.SetVisible(self.WidgetLabelTip, nState == ROAD_CHIVALROUS_SUBMODULE_STATE.INACTIVATED)
    if UIHelper.GetVisible(self.WidgetLabelTip) then
        local tPredecessorID = {}
        RoadChivalrousData.GetSubModuleInCompletedPressID(self.nSubModuleID, tPredecessorID)
        local szText = ""
        for index, nPredecessorID in ipairs(tPredecessorID) do
            local szName = UIHelper.GBKToUTF8(RoadChivalrousData.GetSubModuleName(nPredecessorID))
            szText = szText..szName.." "
        end
        UIHelper.SetString(self.LabelLabelTip02, szText)
    end
end

return UIPanelRoadChivalrousRightPop
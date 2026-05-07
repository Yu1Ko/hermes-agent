-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIRoadChivalrous
-- Date: 2023-04-03 16:44:44
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIRoadChivalrous = class("UIRoadChivalrous")

function UIRoadChivalrous:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:Init()
end

function UIRoadChivalrous:OnVisible()
    
end

function UIRoadChivalrous:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIRoadChivalrous:BindUIEvent()
    UIHelper.BindUIEvent(self.TogNavigation01, EventType.OnSelectChanged, function(toggle, bSelect)
        self:SetCurMode(ROAD_CHIVALROUS_MODULE_TYPE.PVE)
    end)

    UIHelper.BindUIEvent(self.TogNavigation02, EventType.OnSelectChanged, function(toggle, bSelect)
        self:SetCurMode(ROAD_CHIVALROUS_MODULE_TYPE.PVP)
    end)

    UIHelper.BindUIEvent(self.TogNavigation03, EventType.OnSelectChanged, function(toggle, bSelect)
        self:SetCurMode(ROAD_CHIVALROUS_MODULE_TYPE.PVX)
    end)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.TogReward, EventType.OnSelectChanged, function(toggle, bSelect)
        if RoadChivalrousData.GetModuleState(self.nCurMode) == ROAD_CHIVALROUS_MODULE_STATE.COMPLETED_NOT_GOT_FINAL_REWARDS then
			RemoteCallToServer("On_DaXiaZhiLu_GetModuleReward", self.nCurMode)
        else
            self:ShowOrCloseReward(bSelect)
		end
    end)
end

function UIRoadChivalrous:RegEvent()
    Event.Reg(self, "On_DaXiaZhiLu_GetSubModuleGift", function()
        self:UpdateInfo()
    end)

    Event.Reg(self, EventType.OnTouchViewBackGround, function(btn)
        self:ShowOrCloseReward(false)
    end)

    Event.Reg(self, "QUEST_ACCEPTED", function(nQuestIndex, nQuestID)
		-- self.OnAcceptOrShareQuest(nQuestID)
        TipsHelper.ShowNormalTip("任务接取成功，可在任务界面查看")
        self:UpdateInfo()
	end)

	Event.Reg(self, "SHARE_QUEST", function(nResultCode, nQuestID, dwDestPlayerID)
		-- self.OnAcceptOrShareQuest(nQuestID)
        self:UpdateInfo()
	end)

	Event.Reg(self, "QUEST_FINISHED", function(nQuestID, bForceFinish, bAssist, nAddStamina, nAddThew)
		self:UpdateInfo()
	end)
end

function UIRoadChivalrous:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end



function UIRoadChivalrous:Init()
    RoadChivalrousData.Init()
    self:SetCurMode(ROAD_CHIVALROUS_MODULE_TYPE.PVE)
    -- self:InitToggleState()
end

function UIRoadChivalrous:InitToggleState()
    UIHelper.SetSelected(self.TogNavigation01, self.nCurMode == ROAD_CHIVALROUS_MODULE_TYPE.PVE, false)
    UIHelper.SetSelected(self.TogNavigation02, self.nCurMode == ROAD_CHIVALROUS_MODULE_TYPE.PVP, false)
    UIHelper.SetSelected(self.TogNavigation03, self.nCurMode == ROAD_CHIVALROUS_MODULE_TYPE.PVX, false)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIRoadChivalrous:UpdateInfo()
    self:UpdateInfo_Progress()
    self:UpdateInfo_Graph()
end

function UIRoadChivalrous:UpdateInfo_Graph()
    RoadChivalrousData.InitSubModuleIDIndex()
    local tbContainerID = RoadChivalrousData.GetSubModuleContainer(self.nCurMode)
    UIHelper.RemoveAllChildren(self.ScrollViewRoadChivalrousCell)
    for index, nContainerID in ipairs(tbContainerID) do
        local szPrefabName = string.format("WidgetKnotCell%d", nContainerID)
        local scriptView = UIHelper.AddPrefab(PREFAB_ID[szPrefabName], self.ScrollViewRoadChivalrousCell)
        local nChildCount = scriptView:GetNodeCount()
        local tbSubModuleID = RoadChivalrousData.GetSubModuleID(nChildCount, self.nCurMode)
        scriptView:Init(tbSubModuleID)

        local nReMainSubModuleID = RoadChivalrousData.GetReMainSubModuleID(self.nCurMode)
        if nReMainSubModuleID == 0 then
            break
        end

    end
    UIHelper.UpdateMask(self.MaskRoadChivalrousCell)
    UIHelper.ScrollViewDoLayout(self.ScrollViewRoadChivalrousCell)
    UIHelper.ScrollToLeft(self.ScrollViewRoadChivalrousCell)
    UIHelper.SetSwallowTouches(self.ScrollViewRoadChivalrousCell, false)
end


function UIRoadChivalrous:UpdateInfo_Progress()
    local nState, nFinishedCount, nAllCount = RoadChivalrousData.GetModuleState(self.nCurMode)
    UIHelper.SetString(self.LabelBar, string.format(g_tStrings.RoadChivalrous.STR_PROGRESS, tostring(nFinishedCount), tostring(nAllCount)))
    UIHelper.SetProgressBarPercent(self.ProgressBar, (nFinishedCount / nAllCount) * 100)
end

function UIRoadChivalrous:ShowOrCloseReward(bShow)
    UIHelper.SetVisible(self.WidgetRewardTips, bShow)
    UIHelper.SetSelected(self.TogReward, bShow, false)
    if bShow then
        UIHelper.RemoveAllChildren(self.ScrollViewAward)
        local tbItemList = RoadChivalrousData.GetModuleReward(self.nCurMode)
	    for _, tItemInfo in ipairs(tbItemList) do
            local hItemInfo = GetItemInfo(tItemInfo.nItemType, tItemInfo.nItemIndex)
            local szName = UIHelper.GBKToUTF8(ItemData.GetItemNameByItemInfo(hItemInfo))
            local scriptView = UIHelper.AddPrefab(PREFAB_ID.WidgetAward, self.ScrollViewAward, szName, tItemInfo.nItemNum, tItemInfo.nItemType, tItemInfo.nItemIndex)
            scriptView:SetClickCallback(function(nItemType, nItemIndex)
                TipsHelper.DeleteAllHoverTips()
                local uiTips, uiItemTipScript = TipsHelper.ShowItemTips(scriptView._rootNode, nItemType, nItemIndex)
                uiItemTipScript:SetBtnState({})
            end)
        end
        UIHelper.ScrollViewDoLayout(self.ScrollViewAward)
        UIHelper.ScrollToTop(self.ScrollViewAward)
    end
end

function UIRoadChivalrous:SetCurMode(nCurMode)
    self.nCurMode = nCurMode
    self:UpdateInfo()
end

return UIRoadChivalrous
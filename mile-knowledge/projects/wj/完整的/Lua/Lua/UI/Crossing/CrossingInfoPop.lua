-- ---------------------------------------------------------------------------------
-- Author: Liu yu min
-- Name: CrossingInfoPop
-- Date: 2023-03-17 14:54:19
-- Desc: ?
-- ---------------------------------------------------------------------------------

local CrossingInfoPop = class("CrossingInfoPop")

function CrossingInfoPop:OnEnter(nLevel , tbLevelInfo)
    self.nLevel = nLevel
    self.tbLevelInfo = tbLevelInfo
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateUI()
end

function CrossingInfoPop:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function CrossingInfoPop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnReStart, EventType.OnClick, function()
        if CrossingData.nState == CrossingStateType.TestPlace then
            CrossingData.bIsWaitingOpenHint = true
            CrossingData.nCurrentLevel = self.nLevel
            if self.nLevel == self.tbLevelInfo.nCurrentLevel then
                CrossingData.nCurrentMission = self.tbLevelInfo.tCurrentLevelData.nCurrentMission
            else
                CrossingData.nCurrentMission = 1
            end
            RemoteCallToServer("On_Trial_ReStartLevel", self.nLevel )
        else
            RemoteCallToServer("On_NewTrial_ReStartLevel", self.tbLevelInfo.nType, self.nLevel)
        end
    end)

    UIHelper.BindUIEvent(self.BtnContinue, EventType.OnClick, function()
        CrossingData.bIsWaitingOpenHint = true
        CrossingData.nCurrentLevel = self.nLevel
        if self.nLevel == self.tbLevelInfo.nCurrentLevel then
            CrossingData.nCurrentMission = self.tbLevelInfo.tCurrentLevelData.nCurrentMission
        else
            CrossingData.nCurrentMission = 1
        end
        RemoteCallToServer("On_Trial_Continue")
    end)
end

function CrossingInfoPop:RegEvent()
    Event.Reg(self, EventType.HideAllHoverTips, function()
		self:ClearSelect()
	end)
end

function CrossingInfoPop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function CrossingInfoPop:UpdateUI()
    if CrossingData.nState == CrossingStateType.TestPlace then
       UIHelper.SetString(self.LabelTitle, string.format("%s  第%s层", CrossingData.CrossingTitleName, UIHelper.NumberToChinese(self.nLevel)))
        UIHelper.SetString(self.LabelRewardTitile,"可能获得奖励")
        if self.nLevel <= self.tbLevelInfo.nTopLevel then 
            if self.tbLevelInfo[self.nLevel] then
                UIHelper.SetString(self.LabelHistoryScore, self.tbLevelInfo[self.nLevel].nHistoryTotalPoint)
            else
                UIHelper.SetString(self.LabelHistoryScore, " 0 ")
            end
           
        else
            UIHelper.SetString(self.LabelHistoryScore, " 0 ")
        end	
        
        UIHelper.SetVisible(self.WidgetProgress, self.nLevel == self.tbLevelInfo.nCurrentLevel)
        if self.nLevel == self.tbLevelInfo.nCurrentLevel then
            UIHelper.SetString(self.LabelTotalScore , self.tbLevelInfo.tCurrentLevelData.nCurrentScore)
            UIHelper.SetString(self.CurrentProgress,string.format("%d/%d", self.tbLevelInfo.tCurrentLevelData.nCurrentMission, self.tbLevelInfo.tCurrentLevelData.nMaxCurrentMission))
        end
        self.nStar = 0
        if self.tbLevelInfo[self.nLevel] then 
            self.nStar = self.tbLevelInfo[self.nLevel].nStar
        end
        for key, value in pairs(self.tbPopDifficultRank) do
            UIHelper.SetVisible(value, key <= self.nStar)
        end
        UIHelper.SetActiveAndCache(self , self.LayoutRank , self.nStar > 0)
        UIHelper.LayoutDoLayout(self.LayoutRank)
        UIHelper.LayoutDoLayout(self.LayoutContent)
        
        UIHelper.SetActiveAndCache(self , self.BtnContinue , self.nLevel == self.tbLevelInfo.nCurrentLevel)
        UIHelper.SetActiveAndCache(self , self.BtnReStart , true)
        UIHelper.LayoutDoLayout(self.LayoutButton)
        self:UpdateAwardInfo(CrossingData.GetMissionAwardItemList(self.nLevel))
    elseif CrossingData.nState == CrossingStateType.SiShiLunWu then
        UIHelper.SetString(self.LabelTitle, string.format("%s  第%s层", CrossingData.SiShiTitleName, UIHelper.NumberToChinese(self.nLevel)))
        UIHelper.SetVisible(self.LayoutRank,false)
        UIHelper.SetVisible(self.LabelProgressScore,false)
        UIHelper.SetVisible(self.LabelHistoryScoreTitile,false)
        UIHelper.SetVisible(self.WidgetInfo,true)
        UIHelper.SetVisible(self.BtnContinue,false)
        UIHelper.SetString(self.LabelInfoTitile,self.tbLevelInfo.szLevelName)
        UIHelper.SetString(self.LabelRewardTitile,"首次通关奖励")
        UIHelper.SetVisible(self.BtnContinue,false)  
        UIHelper.SetVisible(self.BtnStart,false)
        UIHelper.SetVisible(self.WidgetProgress,false)
        
        UIHelper.SetVisible(self.BtnReStart,true)
        local bIsPass = self.nLevel <= self.tbLevelInfo.nTopLevel
        if bIsPass then
            UIHelper.SetString(self.CurrentProgress,g_tStrings.NEW_TRIAL_VALLEY_PASS)
        else
            UIHelper.SetString(self.CurrentProgress,g_tStrings.NEW_TRIAL_VALLEY_UN_PASS)
        end
        local configInfo = g_tTable.TrialValley:Search(self.tbLevelInfo.nType, self.nLevel)
        local szDesc =  UIHelper.GBKToUTF8(string.pure_text(configInfo.szDesc))
        UIHelper.SetString(self.LabelInfoTitile , szDesc)
        UIHelper.LayoutDoLayout(self.WidgetInfo)
        self:UpdateAwardInfo(NewTrialValley.GetMissionAwardList(self.tbLevelInfo.nType, self.nLevel))
    end

end

function CrossingInfoPop:UpdateAwardInfo(tbAwardItemList)
    local itemCount = table.get_len(tbAwardItemList)
    self.tbRewardItem = {}
    UIHelper.RemoveAllChildren(self.LayoutRewardItem)
    for k, v in pairs(tbAwardItemList) do
        local scriptItem = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.LayoutRewardItem)
        scriptItem:OnInitWithTabID(v.nType, v.nID, v.nCount)
        scriptItem:SetClickCallback(function(nTabType, nTabID)
            TipsHelper.ShowItemTips(scriptItem._rootNode, nTabType, nTabID)
        end)
        table.insert(self.tbRewardItem , scriptItem)
    end
    UIHelper.LayoutDoLayout(self.LayoutRewardItem)
end

function CrossingInfoPop:ClearSelect()
    for index, awardScript in ipairs(self.tbRewardItem) do
        UIHelper.SetSelected(awardScript.ToggleSelect, false)
    end
end

return CrossingInfoPop

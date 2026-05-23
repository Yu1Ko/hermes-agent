-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UITongJianRightTitle
-- Date: 2023-05-16 16:59:16
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UITongJianRightTitle = class("UITongJianRightTitle")

local WuLinTongJianType = {
    ["Quest"] = "任务数量",
    ["Other"] = "其他成就",
    ["Dungeon"] = "秘境通关",
    ["Reputation"] = "声望钦佩",
}

local WuLinTongJianTypeDes = {
    ["任务数量"] = "任务",
    ["其他成就"] = "成就",
    ["秘境通关"] = "秘境通关成就",
}

local WuLinTongJianRewardType = {
    ["任务数量"] = 1,
    ["其他成就"] = 3,
    ["秘境通关"] = 2,
}

function UITongJianRightTitle:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UITongJianRightTitle:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UITongJianRightTitle:BindUIEvent()

end

function UITongJianRightTitle:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UITongJianRightTitle:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITongJianRightTitle:UpdateDLCMapCell(tStageRewardInfo,szKeyText,nFinishNum,nSelectdMapID,nCurrentDLCID)
    for i = 1,tStageRewardInfo.nSize,1 do
        local rightTitleScript = UIHelper.AddPrefab(PREFAB_ID.WidgetTongJianRightTitleCell,self.LayoutTongJianRightTitleCell)

        local bVisible ,szContent, bCanRevice, bDone = false, "", false, false
        if szKeyText ~= WuLinTongJianType.Reputation then
            szContent = FormatString(g_tStrings.STR_DLC_PANEL_TITLE_CELL,tStageRewardInfo.tStageNum[i],WuLinTongJianTypeDes[szKeyText],nFinishNum,tStageRewardInfo.tStageNum[i])
            bVisible = nFinishNum >= tStageRewardInfo.tStageNum[i] -- 已完成
            local nQuestState = WulintongjianDate.GetAwardState(tStageRewardInfo.tStageQuestID[i])
            bCanRevice = bVisible and nQuestState ~= QUEST_PHASE.FINISH
            bDone = nQuestState == QUEST_PHASE.FINISH
            UIHelper.SetString(rightTitleScript.LabelCount,i == 1 and tStageRewardInfo.tStageNum[i] or (tStageRewardInfo.tStageNum[i] - tStageRewardInfo.tStageNum[i-1]))
        else
            local name = UIHelper.GBKToUTF8(Table_GetReputationForceInfo(tStageRewardInfo.tReputationID[i]).szName)
            szContent = name .. g_tStrings.STR_DLC_PANEL_REPUTATION_REWARD .. UIHelper.GBKToUTF8(tStageRewardInfo.tStageName[i])
            bVisible = nFinishNum >= tStageRewardInfo.nSize -- 已完成
            bDone = bVisible
            UIHelper.SetVisible(rightTitleScript.BtnCount,false)
        end

        UIHelper.SetString(rightTitleScript.LabelContent,szContent)
        UIHelper.SetVisible(rightTitleScript.ImgAwarded,bVisible)
        UIHelper.SetVisible(rightTitleScript.Eff_CanGetReward, bCanRevice)
        UIHelper.SetVisible(rightTitleScript.Eff_CanGetCount, bCanRevice)
        UIHelper.SetVisible(rightTitleScript.WidgetReceived1, bDone)
        UIHelper.SetVisible(rightTitleScript.WidgetReceived2, bDone)
        UIHelper.PlaySFX(rightTitleScript.Eff_CanGetReward)
        UIHelper.PlaySFX(rightTitleScript.Eff_CanGetCount)

        UIHelper.SetItemIconByIconID(rightTitleScript.ImgRaward, tStageRewardInfo.tStageIcon[i])
        UIHelper.SetVisible(rightTitleScript.BtnMap,szKeyText == WuLinTongJianType.Quest)
        UIHelper.SetVisible(rightTitleScript.BtnDetails,szKeyText ~= WuLinTongJianType.Quest)

        UIHelper.BindUIEvent(rightTitleScript.BtnRaward,EventType.OnClick,function ()
            if bCanRevice and (szKeyText ~= WuLinTongJianType.Reputation) then
                self:GetDLCAward(nCurrentDLCID, nSelectdMapID, WuLinTongJianRewardType[szKeyText], i)
                UIHelper.SetVisible(rightTitleScript.Eff_CanGetReward, false)
                UIHelper.SetVisible(rightTitleScript.Eff_CanGetCount, false)
                UIHelper.SetVisible(rightTitleScript.WidgetReceived1, true)
                UIHelper.SetVisible(rightTitleScript.WidgetReceived2, true)
            end
            if szKeyText == WuLinTongJianType.Reputation then
                if not UIMgr.IsViewOpened(VIEW_ID.PanelRenownRewordList) then
                    UIMgr.Open(VIEW_ID.PanelRenownRewordList, {dwForceID = tStageRewardInfo.tReputationID[i]})
                else
                    UIMgr.CloseWithCallBack(VIEW_ID.PanelRenownRewordList, function ()
                        UIMgr.Open(VIEW_ID.PanelRenownRewordList, {dwForceID = tStageRewardInfo.tReputationID[i]})
                    end)
                end
            else
                self:PreviewAward(tStageRewardInfo.tStageQuestID[i], rightTitleScript)
            end
        end)

        UIHelper.BindUIEvent(rightTitleScript.BtnCount,EventType.OnClick,function ()
            if bCanRevice and (szKeyText ~= WuLinTongJianType.Reputation) then
                self:GetDLCAward(nCurrentDLCID, nSelectdMapID, WuLinTongJianRewardType[szKeyText], i)
                UIHelper.SetVisible(rightTitleScript.Eff_CanGetReward, false)
                UIHelper.SetVisible(rightTitleScript.Eff_CanGetCount, false)
                UIHelper.SetVisible(rightTitleScript.WidgetReceived1, true)
                UIHelper.SetVisible(rightTitleScript.WidgetReceived2, true)
            end
            local nX,nY = UIHelper.GetWorldPosition(rightTitleScript.BtnCount)
            local nSizeW,nSizeH = UIHelper.GetContentSize(rightTitleScript.BtnCount)
            local _, scriptTips = TipsHelper.ShowClickHoverTips(PREFAB_ID.WidgetPublicLabelTips,nX-nSizeW-485,nY+nSizeH)
            scriptTips:OnEnter(g_tStrings.STR_DLC_PANEL_POINT_REWARD)
        end)

        UIHelper.BindUIEvent(rightTitleScript.BtnMap,EventType.OnClick,function ()
            self:OnClickMap(nSelectdMapID)
        end)

        UIHelper.BindUIEvent(rightTitleScript.BtnDetails,EventType.OnClick,function ()
            if szKeyText == WuLinTongJianType.Other then
                self:OnClickAchievementMianDetails(nCurrentDLCID,nSelectdMapID)
            elseif szKeyText == WuLinTongJianType.Dungeon then
                self:OnClickDungeonDetails(nCurrentDLCID,nSelectdMapID)
            elseif szKeyText == WuLinTongJianType.Reputation then
                self:OnClickReputationDetails(tStageRewardInfo.tReputationID[i])
            end
        end)
    end
end

function UITongJianRightTitle:GetDLCAward(nCurrentDLCID, nSelectdMapID, RewardType, nIndex)
    RemoteCallToServer("On_DLC_GetDLCMapReward", nCurrentDLCID, nSelectdMapID, RewardType, nIndex)
end

function UITongJianRightTitle:PreviewAward(nStageQuestID, rightTitleScript)
    local tbQuestConfig = QuestData.GetQuestConfig(nStageQuestID)
    local tbAwardList = tbQuestConfig and QuestData.GetCurQuestAwardList(tbQuestConfig.nID) or {}
    TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetRewardPreview, rightTitleScript.BtnRaward, tbAwardList, PREFAB_ID.WidgetAward, false)
end

function UITongJianRightTitle:OnClickMap(nSelectdMapID)
    UIMgr.Open(VIEW_ID.PanelMiddleMap, nSelectdMapID,0)
end

function UITongJianRightTitle:OnClickAchievementMianDetails(nCurrentDLCID,nSelectdMapID)
    local fnCustomFilterDataCallback = function()
        AchievementData.SetFilterData_m_dwADLCID(nCurrentDLCID)
        AchievementData.SetFilterData_m_dwAMapID(nSelectdMapID)
        AchievementData.SetFilterData_m_bDLCOther(true)
    end

    ---@see UIAchievementListView#OnEnter
    UIMgr.Open(VIEW_ID.PanelAchievementList, g_pClientPlayer.dwID, fnCustomFilterDataCallback)
end

function UITongJianRightTitle:OnClickDungeonDetails(nCurrentDLCID,nSelectdMapID)
    local scriptView = UIMgr.Open(VIEW_ID.PanelDungeonEntrance, {bNeedChooseFirst=false, bRecommendOnly = false})
    if scriptView then
        Timer.AddFrame(scriptView, 2, function ()
            scriptView:SetEnterMapID(nSelectdMapID)
            local tLine = Table_GetDLCInfo(nCurrentDLCID) assert(tLine)
            scriptView:SetTargetTitle(UIHelper.GBKToUTF8(tLine.szDLCName))
        end)
    end
end

function UITongJianRightTitle:OnClickReputationDetails(dwRewardForceID)
    local scriptView = UIMgr.Open(VIEW_ID.PanelRenownList)
    if scriptView then
        Timer.AddFrame(scriptView, 2, function ()
            scriptView:RedirectForceView(dwRewardForceID)
        end)
    end
end

return UITongJianRightTitle
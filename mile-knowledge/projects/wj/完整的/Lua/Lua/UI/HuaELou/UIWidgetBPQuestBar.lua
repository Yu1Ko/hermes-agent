-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetBPQuestBar
-- Date: 2022-12-23 10:55:15
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetBPQuestBar = class("UIWidgetBPQuestBar")
function UIWidgetBPQuestBar:OnEnter(tQuest)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    if tQuest then
        self:UpdateInfo(tQuest)
    end
end

function UIWidgetBPQuestBar:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetBPQuestBar:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnParticulars, EventType.OnClick, function ()
        if self.tQuest.szLink and self.tQuest.szLink ~= "" then
            Event.Dispatch("EVENT_LINK_NOTIFY", self.tQuest.szLink)
        elseif self.tQuest.szPanelLink and self.tQuest.szPanelLink ~= "" then
            Event.Dispatch("EVENT_LINK_NOTIFY", self.tQuest.szPanelLink)
        end
    end)

    UIHelper.BindUIEvent(self.BtnGo, EventType.OnClick, function ()
        self:TryTravel()
    end)

    UIHelper.BindUIEvent(self.BtnTeam, EventType.OnClick, function ()
        if self.tQuest.nRecruit then
            UIMgr.Open(VIEW_ID.PanelTeam, 1, nil, self.tQuest.nRecruit)
        end
    end)

    UIHelper.BindUIEvent(self.TogLike, EventType.OnSelectChanged, function (_, bSelected)
        Storage.HuaELou.tQuestLikeMap[self.tQuest.dwID] = bSelected
        if self.fOnLikeCallBack then self.fOnLikeCallBack() end
    end)
end

function UIWidgetBPQuestBar:RegEvent()
    Event.Reg(self, "QUEST_FINISHED", function ()
        self:UpdateInfo()
    end)

    Event.Reg(self, "SET_QUEST_STATE", function ()
        self:UpdateInfo()
    end)

    Event.Reg(self, "ON_SYNC_SET_COLLECTION", function ()
        self:UpdateInfo()
    end)

    Event.Reg(self, "PLAYER_LEVEL_UPDATE", function ()
        self:UpdateInfo()
    end)
end

function UIWidgetBPQuestBar:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetBPQuestBar:UpdateInfo(tQuest)
    self.tQuest = tQuest or self.tQuest
    local tTPLink = SplitString(tQuest.szTPLink, "_")
	self.nTPLinkID = tonumber(tTPLink[1])
	self.dwTPMapID = tonumber(tTPLink[2])
    self.szTPLink  = tQuest.szTPLink
    self.szPanelLink = tQuest.szPanelLink
    -- 更新任务描述
    local szClassName = g_tStrings.tActiveClass[tQuest.nClass]
    UIHelper.SetString(self.LabelTag, szClassName)
    UIHelper.SetSpriteFrame(self.ImgTag, ActiveClassTagImg[tQuest.nClass])

    local szQuestDesc = UIHelper.GBKToUTF8(tQuest.szQuestDesc)
    UIHelper.SetString(self.LabelDesc, szQuestDesc)

    local szQuestTypeName = HuaELouData.QuestTypeName[tQuest.szModuleName]
    UIHelper.SetString(self.LabelTitle, szClassName..szQuestTypeName)

    UIHelper.SetString(self.LabelExp, tostring(tQuest.nExpCanGet))
    UIHelper.SetString(self.LabelWishCoin, tostring(tQuest.nExpCanGet))
    -- 更新任务状态
    local nBuffFinish  = 0
    local nQuestFinish = 0
    local nFinishCount = 0
    local nMaxCount = tQuest.nMaxFinishTimes
    local szQuestID = tQuest.szQuestID
    local nBuffID = tQuest.nBuffID

    if nBuffID ~= 0 then
        local buff = Player_GetBuff(nBuffID)
        if buff then
            nBuffFinish = buff.nStackNum
        end
    end
    if szQuestID ~= "" then
        local tQuestIDs = SplitString(szQuestID, ";")
        for _, szQuest in ipairs(tQuestIDs) do
            local pPlayer = GetClientPlayer()
            local dwQuestID = tonumber(szQuest)
            local nFinishedCount, nTotalCount = pPlayer.GetRandomDailyQuestFinishedCount(dwQuestID)
            if nFinishedCount == nTotalCount then
                nQuestFinish = nQuestFinish + 1
            end
        end
    end

    nFinishCount = math.max(nBuffFinish, nQuestFinish)
    local bIsFinished = nFinishCount >= nMaxCount
    local szFinish = string.format("%d/%d", nFinishCount, nMaxCount)
    local nLimitLevel = tQuest.nLimitLevel or 0
    local szLimit = string.format("推荐等级：%d", nLimitLevel)
    local bLevelLimit = g_pClientPlayer.nLevel < nLimitLevel
    UIHelper.SetString(self.LabelFinishCount, szFinish)
    UIHelper.SetString(self.LabelRecLevelRed, szLimit)
    UIHelper.SetString(self.LabelRecLevelGreen, szLimit)
    UIHelper.SetVisible(self.LabelFinishCount, nBuffID ~= 0 or szQuestID ~= "")
    UIHelper.SetVisible(self.ImgMask, bIsFinished)
    UIHelper.SetVisible(self.ImgSealComplete, bIsFinished)
    UIHelper.SetVisible(self.LabelRecLevelRed, bLevelLimit)
    UIHelper.SetVisible(self.LabelRecLevelGreen, not bLevelLimit)
    UIHelper.SetVisible(self.WidgetRecLevel, nLimitLevel > 0 and g_pClientPlayer.nLevel < g_pClientPlayer.nMaxLevel)

    -- 更新按钮状态
    local bShowBtnGo = false
    local bShowBtnParticulars = (tQuest.szPanelLink and tQuest.szPanelLink ~= "") or (tQuest.szLink and tQuest.szLink ~= "")
    local bShowBtnRecruit = tQuest.nRecruit and tQuest.nRecruit ~= 0
    if not bIsFinished and (self.nTPLinkID or self.dwTPMapID or (tQuest.szPanelLink and tQuest.szPanelLink ~= "")) then bShowBtnGo = true end

    local scriptIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_44, self.LayoutItem)
    local dwTabType = 5
    local dwIndex = HuaELouData.WEEK_CHIPS_ITEM_INDEX
    scriptIcon:OnInitWithTabID(dwTabType, dwIndex, tQuest.nWeaponChips)
    scriptIcon:SetClickCallback(function(dwTabType, dwIndex)
            TipsHelper.DeleteAllHoverTips()
            TipsHelper.ShowItemTips(scriptIcon._rootNode, dwTabType, dwIndex)
            if UIHelper.GetSelected(scriptIcon.ToggleSelect) then
                UIHelper.SetSelected(scriptIcon.ToggleSelect, false)
            end
        end)
    UIHelper.LayoutDoLayout(self.LayoutItem)
    UIHelper.SetVisible(self.LayoutItem, HuaELouData.WEEK_CHIPS_LIMIT_VISIBLE)

    UIHelper.SetVisible(self.BtnGo, bShowBtnGo)
    UIHelper.SetVisible(self.BtnParticulars, bShowBtnParticulars)
    UIHelper.SetVisible(self.BtnTeam, bShowBtnRecruit)
    UIHelper.SetSelected(self.TogLike, Storage.HuaELou.tQuestLikeMap[self.tQuest.dwID])
end

function UIWidgetBPQuestBar:OnLinkActivity(nActivityID)
    local scriptView = UIMgr.Open(VIEW_ID.PanelActivityCalendar)
    if scriptView then
        scriptView:SetCurActivityTypeByActivityID(nActivityID)
        scriptView:SelectedActivityIndexByActivityID(nActivityID)
        scriptView:UpdateCurActiveInfo()
    end
end

function UIWidgetBPQuestBar:TryTravel()
    if self.nTPLinkID ~= 0 or self.dwTPMapID ~= 0 then
        -- if not PakDownloadMgr.UserCheckDownloadMapRes(self.dwTPMapID, nil, nil, true) then
        --     return
        -- end

        -- if HomelandData.CheckIsHomelandMapTeleportGo(self.nTPLinkID, self.dwTPMapID, nil, nil, function ()
        --         UIMgr.Close(VIEW_ID.PanelBenefits)
        --     end) then
        --     return
        -- end
        -- MapMgr.CheckTransferCDExecute(function()
        --     RemoteCallToServer("On_Teleport_Go", self.nTPLinkID, self.dwTPMapID)
        --     UIMgr.Close(VIEW_ID.PanelBenefits)
        -- end, self.dwTPMapID)
        -- MapMgr.CheckTransferCDExecute(function()
        --     RemoteCallToServer("On_Teleport_Go", self.nTPLinkID, self.dwTPMapID)
        --     UIMgr.Close(VIEW_ID.PanelBenefits)
        -- end, self.dwTPMapID)
        local tTargetList = HuaELouData.GetTargetList(nil, self.szTPLink)
        if tTargetList and not IsTableEmpty(tTargetList) then
            local  _, scriptView = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicTraceTip, self.BtnGo, TipsLayoutDir.TOP_CENTER)
            if scriptView then
                scriptView:OnEnter(tTargetList)
            end
            return
        end

        local szPanelLink = self.szPanelLink
        if szPanelLink ~= "" then
            Event.Dispatch("EVENT_LINK_NOTIFY", szPanelLink)
            return
        end
        TipsHelper.ShowNormalTip("没有可前往的地点")
    else
        Event.Dispatch("EVENT_LINK_NOTIFY", self.tQuest.szPanelLink)
    end
end

function UIWidgetBPQuestBar:SetOnLikeCallBack(fOnLikeCallBack)
    self.fOnLikeCallBack = fOnLikeCallBack
end

return UIWidgetBPQuestBar
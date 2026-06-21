-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIPvPCampJoinView
-- Date: 2023-03-01 16:32:39
-- Desc: PanelPvPCampJoin
-- ---------------------------------------------------------------------------------

local UIPvPCampJoinView = class("UIPvPCampJoinView")

local tCampMapID = {
    [CAMP.GOOD] = 25, --浩气盟
    [CAMP.EVIL] = 27, --恶人谷
}

function UIPvPCampJoinView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateCampReward(CAMP.GOOD)
    self:UpdateCampReward(CAMP.EVIL)

    RedpointHelper.PanelCamp_OnClickLevel()
    RemoteCallToServer("On_Vote_AcquireCampRecommended")
    --需手动重设一下，否则在手机端会有奇怪的拉伸问题
    UIHelper.SetTexture(self.ImgBg, "Texture/PvpBg/bg_camp.png")

    -- local tConfig = { bHideSize = true }

    -- local scriptDownload1 = UIHelper.GetBindScript(self.WidgetDownload1)
    -- local nPackID1 = PakDownloadMgr.GetMapResPackID(tCampMapID[CAMP.GOOD])
    -- scriptDownload1:OnInitWithPackID(nPackID1, tConfig)

    -- local scriptDownload2 = UIHelper.GetBindScript(self.WidgetDownload2)
    -- local nPackID2 = PakDownloadMgr.GetMapResPackID(tCampMapID[CAMP.EVIL])
    -- scriptDownload2:OnInitWithPackID(nPackID2, tConfig)

    local scriptDownload = UIHelper.GetBindScript(self.WidgetDownload1)
    local tPackIDList = PakDownloadMgr.GetPackIDListInPackTree(PACKTREE_ID.Camp)
    scriptDownload:OnInitWithPackIDList(tPackIDList)
end

function UIPvPCampJoinView:OnExit()
    self.bInit = false
    self:UnRegEvent()

    local player = GetClientPlayer()
    if not player then return end

    --旧：

    --若关闭加入阵营界面时还为中立阵营，则也将阵营界面关闭
    if not player or player.nCamp == CAMP.NEUTRAL then
        UIMgr.Close(VIEW_ID.PanelPVPCamp)
        return
    end

    --若关闭加入阵营界面时已有阵营，则刷新阵营界面显示
    local view = UIMgr.GetView(VIEW_ID.PanelPVPCamp)
    local scriptCamp = view and view.scriptView
    if scriptCamp then
        scriptCamp:UpdateInfo()
    end
end

function UIPvPCampJoinView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
    UIHelper.BindUIEvent(self.BtnJoin1, EventType.OnClick, function()
        CampData.CheckJoinCamp(CAMP.GOOD)
    end)
    UIHelper.BindUIEvent(self.BtnJoin2, EventType.OnClick, function()
        CampData.CheckJoinCamp(CAMP.EVIL)
    end)

    UIHelper.BindUIEvent(self.BtnJoin1, EventType.OnDragOut, function()
        if self.nTimerGoodOut then
            Timer.DelTimer(self, self.nTimerGoodOut)
            self.nTimerGoodOut = nil
        end
        self.nTimerGoodOut = Timer.AddFrame(self, 1, function()
            self.nTimerGoodOut = nil
            self:UpdateUIJoinCampState()
        end)
    end)

    UIHelper.BindUIEvent(self.BtnJoin2, EventType.OnDragOut, function()
        if self.nTimerEvilOut then
            Timer.DelTimer(self, self.nTimerEvilOut)
            self.nTimerEvilOut = nil
        end
        self.nTimerEvilOut = Timer.AddFrame(self, 1, function()
            self.nTimerEvilOut = nil
            self:UpdateUIJoinCampState()
        end)
    end)
end

function UIPvPCampJoinView:RegEvent()
    Event.Reg(self, EventType.HideAllHoverTips, function()
        if self.scriptIcon then
            self.scriptIcon:SetSelected(false)
        end
    end)
end

function UIPvPCampJoinView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIPvPCampJoinView:OnJoinCampClick(nCampType)
    local nCurMapID = MapHelper.GetMapID()
    if CampData.CAMP_MAP_ID[nCampType] == nCurMapID then
        CampData.bIsTracing = true
        CampData.CheckShowTrace()
        return
    end

    --浩气盟/恶人谷不能直接进入，通过找到接引人（通过任务ID）对话传送
    local dwQuestID = 20920
    local dwMapID = 6 --默认扬州
    local tMapIDs = TableQuest_GetMapIDs(dwQuestID, "quest_state", 0)
    for i, tMapData in ipairs(tMapIDs) do
        if nCurMapID == tMapData[1] then
            dwMapID = tMapData[1]
            break
        end
    end

    CampData.SetTraceNpcByQuest(dwQuestID, dwMapID, "阵营与门派接引人")
    CampData.RegisterTracing()
end

function UIPvPCampJoinView:UpdateUIJoinCampState()
    local nGoodColor = self.nRecommendCamp == CAMP.GOOD and cc.c3b(255, 255, 255) or cc.c3b(155, 155, 155)
    local nEvilColor = self.nRecommendCamp == CAMP.EVIL and cc.c3b(255, 255, 255) or cc.c3b(155, 155, 155)
    UIHelper.SetColor(self.BtnJoin1, nGoodColor)
    UIHelper.SetColor(self.BtnJoin2, nEvilColor)

    local nGoodState = self.nDisableCamp == CAMP.GOOD and BTN_STATE.Disable or BTN_STATE.Normal
    local nEvilState = self.nDisableCamp == CAMP.EVIL and BTN_STATE.Disable or BTN_STATE.Normal
    UIHelper.SetButtonState(self.BtnJoin1, nGoodState, nil, nil, false)
    UIHelper.SetButtonState(self.BtnJoin2, nEvilState, nil, nil, false)

    UIHelper.SetVisible(self.WidgetTipFull1, self.nDisableCamp == CAMP.GOOD)
    UIHelper.SetVisible(self.WidgetTipFull2, self.nDisableCamp == CAMP.EVIL)

    UIHelper.SetVisible(self.WidgetTipRight1, self.nRecommendCamp == CAMP.GOOD)
    UIHelper.SetVisible(self.WidgetTipRight2, self.nRecommendCamp == CAMP.EVIL)

    --奖励
    self:ShowCampReward(CAMP.GOOD, self.nRecommendCamp == CAMP.GOOD)
    self:ShowCampReward(CAMP.EVIL, self.nRecommendCamp == CAMP.EVIL)
end

function UIPvPCampJoinView:UpdateJoinCampState(nRecommendCamp, nDisableCamp)
    self.nRecommendCamp = nRecommendCamp
    self.nDisableCamp = nDisableCamp
    self:UpdateUIJoinCampState()
end

function UIPvPCampJoinView:GetCampReward(nCamp)
    local tJoinCampReward = Table_GetJoinCampReward()
    if not tJoinCampReward then
        return
    end

    local tRes = {}
    for i, v in pairs(tJoinCampReward) do
        if v.nCamp == nCamp then
            local t = SplitString(v.szReward, ";")
            AppendTable(tRes, t)
        end
    end
    return tRes
end

function UIPvPCampJoinView:UpdateCampReward(nCamp)
    self.tItemScript = self.tItemScript or {}
    for _, itemScript in pairs(self.tItemScript[nCamp] or {}) do
        UIHelper.RemoveFromParent(itemScript._rootNode, true)
    end
    self.tItemScript[nCamp] = {}

    local tRewardList = self:GetCampReward(nCamp)
    for i, szReward in ipairs(tRewardList) do
        local tRewardInfo = SplitString(szReward, "_")
        local szType      = tRewardInfo[1]
        local dwTabType   = tonumber(tRewardInfo[1])
        local dwID        = tonumber(tRewardInfo[2])
        local nCount      = tonumber(tRewardInfo[3])

        local itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_44, self["LayoutRewardList" .. nCamp])
        if szType == "COIN" then
            local tLine = Table_GetCalenderActivityAwardIconByID(dwID) or {}
            local szName = CurrencyNameToType[tLine.szName]
            itemScript:OnInitCurrency(szName, nCount)
        else
            itemScript:OnInitWithTabID(dwTabType, dwID)
            if nCount > 1 then
                itemScript:SetLabelCount(nCount)
            end
        end

        itemScript:SetSelectChangeCallback(function(_, bSelected)
            if bSelected then
                if self.scriptIcon then
                    self.scriptIcon:SetSelected(false)
                end
                local tips, scriptTip = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetItemTip, itemScript._rootNode)
                if szType == "COIN" then
                    local tLine = Table_GetCalenderActivityAwardIconByID(dwID) or {}
                    local szName = CurrencyNameToType[tLine.szName]
                    scriptTip:OnInitCurrency(szName, nCount)
                else
                    scriptTip:OnInitWithTabID(dwTabType, dwID)
                end
                self.scriptIcon = itemScript
            else
                TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetItemTip)
                self.scriptIcon = nil
            end
        end)
        
        table.insert(self.tItemScript[nCamp], itemScript)
    end
end

function UIPvPCampJoinView:ShowCampReward(nCamp, bShow)
    if nCamp ~= CAMP.GOOD and nCamp ~= CAMP.EVIL then
        return
    end

    UIHelper.SetVisible(self["LayoutRewardList" .. nCamp], bShow)
end

return UIPvPCampJoinView
local UIMonopolyMainView = class("UIMonopolyMainView")

local MAX_ROUND_COUNT = 20 -- 最大回合数

function UIMonopolyMainView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:InitView()
    self:UpdateInfo()
end

function UIMonopolyMainView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIMonopolyMainView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
        --BattleFieldData.LeaveBattleField()
    end)

    UIHelper.BindUIEvent(self.BtnSetting, EventType.OnClick, function ()
        TipsHelper.ShowImportantYellowTip(g_tStrings.STR_CMD_DATAPANEL_BANNED)
    end)

    UIHelper.BindUIEvent(self.BtnLog, EventType.OnClick, function ()
        TipsHelper.ShowImportantYellowTip(g_tStrings.STR_CMD_DATAPANEL_BANNED)
    end)

    UIHelper.BindUIEvent(self.BtnAnnouncement, EventType.OnClick, function ()
        TipsHelper.ShowImportantYellowTip(g_tStrings.STR_CMD_DATAPANEL_BANNED)
    end)

    UIHelper.BindUIEvent(self.BtnQuestion, EventType.OnClick, function ()
        TipsHelper.ShowImportantYellowTip(g_tStrings.STR_CMD_DATAPANEL_BANNED)
    end)

    UIHelper.BindUIEvent(self.BtnChat, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelChatSocial)
    end)

    UIHelper.BindUIEvent(self.TogVoice, EventType.OnSelectChanged, function (_, bSelected)
        TipsHelper.ShowImportantYellowTip(g_tStrings.STR_CMD_DATAPANEL_BANNED)
    end)

    UIHelper.BindUIEvent(self.TogMicrophone, EventType.OnSelectChanged, function (_, bSelected)
        TipsHelper.ShowImportantYellowTip(g_tStrings.STR_CMD_DATAPANEL_BANNED)
    end)

    UIHelper.BindUIEvent(self.ToggleLens, EventType.OnSelectChanged, function (_, bSelected)
        TipsHelper.ShowImportantYellowTip(g_tStrings.STR_CMD_DATAPANEL_BANNED)
    end)
end

function UIMonopolyMainView:RegEvent()
    UIMgr.HideLayer(UILayer.Main, {VIEW_ID.PanelRichMan})

    Event.Reg(self, EventType.OnViewClose, function (nViewID)
        if nViewID ~= VIEW_ID.PanelLoading then return end

        local player = GetClientPlayer()
        local dwMapID = player.GetMapID() or 0
        if dwMapID == 801 then return end

        UIMgr.Close(self)
    end)

    Event.Reg(self, EventType.OnMonopolySwitchSubPanels, function (tNewPanels)
        self:OnSwitchSubPanels(tNewPanels)
    end)

    Event.Reg(self, EventType.OnMonopolyCurrentPlayerChanged, function (nCurDfwIndex, bIsMyRound)
        self:UpdateRoundInfo()
    end)

    Event.Reg(self, EventType.OnMonopolyInfoRoundChanged, function (nCurDfwIndex, bIsMyRound)
        self:UpdateRoundInfo()
    end)
end

function UIMonopolyMainView:UnRegEvent()
    UIMgr.ShowLayer(UILayer.Main, {VIEW_ID.PanelRichMan})
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIMonopolyMainView:InitView()
    MonopolyData.m_nLastExchangeLaunchTime = 0
    self.tScriptPlayers = {}
    self.tSubPanels = {}

    self.scriptTimer = self.scriptTimer or UIHelper.AddPrefab(PREFAB_ID.WidgetRichManTime, self.WidgetCenterTop)
    self.scriptRightEvent = self.scriptRightEvent or UIHelper.AddPrefab(PREFAB_ID.WidgetRightEvent, self.WidgetRightEvent)
    self.scriptRightEvent:Close()
end

function UIMonopolyMainView:UpdateInfo()
    self:UpdateRoundInfo()
end

function UIMonopolyMainView:UpdateRoundInfo()
    local nCurRound = DFW_GetTableRound() or 1

    MAX_ROUND_COUNT = DFW_TABLEROUND_MAX or MAX_ROUND_COUNT
    local szRound = string.format(g_tStrings.STR_MONOPOLY_ROUND_DESC, nCurRound, MAX_ROUND_COUNT)

    local nPriceMuil = DFW_GetTablePriceMuli() or 1
    local szPriceMuil = string.format(g_tStrings.STR_MONOPOLY_PRICE_DESC, nPriceMuil)

    UIHelper.SetString(self.LabelRound, szRound)
    UIHelper.SetString(self.LabelPrices, szPriceMuil)
end

function UIMonopolyMainView:OnSwitchSubPanels(tNewPanels)
    local bMonopolyReadyArea = table.contain_value(tNewPanels, "MonopolyReadyArea")
    local bMonopolyDice = table.contain_value(tNewPanels, "MonopolyDice")

    UIHelper.SetVisible(self.WidgetReadyInfo, bMonopolyReadyArea)
    UIHelper.SetVisible(self.WidgetDice, bMonopolyDice)
end

return UIMonopolyMainView
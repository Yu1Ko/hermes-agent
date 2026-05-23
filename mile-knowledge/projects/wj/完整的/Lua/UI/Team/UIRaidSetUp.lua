-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIRaidSetUp
-- Date: 2022-11-23 20:45:16
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIRaidSetUp = class("UIRaidSetUp")

function UIRaidSetUp:OnEnter(bRoomSetUp)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.bRoomSetUp = bRoomSetUp

    self.tbTogLootModeMean = {
        [1] = PARTY_LOOT_MODE.FREE_FOR_ALL,
        [2] = PARTY_LOOT_MODE.GROUP_LOOT,
        [3] = PARTY_LOOT_MODE.BIDDING,
        [4] = PARTY_LOOT_MODE.DISTRIBUTE,
    }

    self.tbTogRollQualityMean = {
        [1] = 3,
        [2] = 2,
        [3] = 5,
        [4] = 4,
    }


    self:Reset()
end

function UIRaidSetUp:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UIRaidSetUp:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function (btn)
        local hTeam = GetClientTeam()

        if self.nSelectedLootMode ~= hTeam.nLootMode then
            hTeam.SetTeamLootMode(self.nSelectedLootMode)
        end

        if self.nSelectedRollQualilty ~= hTeam.nRollQuality then
            hTeam.SetTeamRollQuality(self.nSelectedRollQualilty)
        end

        TeamData.EnableMainCityRaidMode(self.bEnableMainCityRaidMode)
        TeamData.EnableMainCityTeamMode(self.bEnableMainCityTeamMode)

        if self.bSyncTeamFightData ~= TeamData.IsSyncTeamFightData() then
            SetTeamSkillEffectSyncOption(self.bSyncTeamFightData)
            TeamData.SetSyncTeamFightDataState(self.bSyncTeamFightData)
        end

        UIMgr.Close(VIEW_ID.PanelTeamSetUp)
    end)

    UIHelper.BindUIEvent(self.BtnReset, EventType.OnClick, function (btn)
       self:Reset()
    end)

    UIHelper.BindUIEvent(self.BtnMemberMark, EventType.OnClick, function (btn)
        UIMgr.Open(VIEW_ID.PanelMarkMemberPop)
     end)

     UIHelper.BindUIEvent(self.BtnAuctionPreset, EventType.OnClick, function (btn)
        UIMgr.Open(VIEW_ID.PanelAuctionPresetPop)
     end)

    for nIndex, tog in ipairs(self.tbTogLootMode) do
        UIHelper.BindUIEvent(tog, EventType.OnSelectChanged, function (_, bSelected)
            if bSelected then
                self.nSelectedLootMode = self.tbTogLootModeMean[nIndex]
            end
        end)
    end

    for nIndex, tog in ipairs(self.tbTogRollQuality) do
        UIHelper.BindUIEvent(tog, EventType.OnSelectChanged, function (_, bSelected)
            if bSelected then
                self.nSelectedRollQualilty = self.tbTogRollQualityMean[nIndex]
            end
        end)
    end

    UIHelper.BindUIEvent(self.TogMainCityTeam, EventType.OnSelectChanged, function (_, bSelected)
        self.bEnableMainCityTeamMode = bSelected
    end)

    UIHelper.BindUIEvent(self.TogMainCityRaid, EventType.OnSelectChanged, function(_, bSelected)
        self.bEnableMainCityRaidMode = bSelected
    end)

    UIHelper.BindUIEvent(self.BtnNotice, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelTeamNoticeEditPop, false)
    end)

    UIHelper.BindUIEvent(self.TogSyncTeamFightData, EventType.OnSelectChanged, function(_, bSelected)
        self.bSyncTeamFightData = bSelected
    end)

    UIHelper.BindUIEvent(self.BtnSyncTeamFightData, EventType.OnClick, function()
        local szTips = string.format("<color=#FEFEFE>%s</color>", g_tStrings.STR_TEAM_PARTY_SYNC)
        local tips, tipsScript = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetPublicLabelTips, self.BtnSyncTeamFightData, szTips)
        local nWidth, nHeight = UIHelper.GetContentSize(tipsScript.ImgPublicLabelTips)
        tips:SetSize(nWidth, nHeight)
        tips:UpdatePosByNode(self.BtnSyncTeamFightData)
    end)
end

function UIRaidSetUp:RegEvent()
    Event.Reg(self, "PARTY_DISBAND", function ()
        UIMgr.Close(self)
    end)

    Event.Reg(self, "PARTY_LOOT_MODE_CHANGED", function ()
        self:Reset()
    end)

    Event.Reg(self, "PARTY_ROLL_QUALITY_CHANGED", function ()
        self:Reset()
    end)
end

function UIRaidSetUp:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIRaidSetUp:Reset()
    local hTeam = GetClientTeam()
    self.nSelectedLootMode = hTeam.nLootMode
    self.nSelectedRollQualilty = hTeam.nRollQuality
    self.bEnableMainCityRaidMode = Storage.Team.bEnableMainCityRaidMode
    self.bEnableMainCityTeamMode = Storage.Team.bEnableMainCityTeamMode
    self.bSyncTeamFightData = TeamData.IsSyncTeamFightData()
    self:UpdateInfo()
end

function UIRaidSetUp:UpdateInfo()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local bSloganVisible = hPlayer.IsPartyLeader() and TeamData.IsInRaid()

    UIHelper.SetVisible(self.BtnNotice, bSloganVisible)

    local hTeam = GetClientTeam()
    local bDistribute = hTeam.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.DISTRIBUTE) == hPlayer.dwID

    UIHelper.SetVisible(self.BtnMemberMark , bDistribute)
    UIHelper.SetVisible(self.WidgetSetUpView, true)
    UIHelper.SetVisible(self.WidgetSetUpLevel, bDistribute)
    UIHelper.SetVisible(self.WidgetSetUpModel, bDistribute)
    UIHelper.SetVisible(self.BtnAuctionPreset, bDistribute)
    UIHelper.LayoutDoLayout(self.LayoutBtn)

    UIHelper.SetVisible(self.ToggleGroupTeamMode, TeamData.IsInRaid())
    UIHelper.SetVisible(self.ToggleGroupRaidMode, not TeamData.IsInRaid())
    UIHelper.SetSelected(self.TogMainCityTeam, self.bEnableMainCityTeamMode, false)
    UIHelper.SetSelected(self.TogMainCityRaid, self.bEnableMainCityRaidMode, false)
    UIHelper.LayoutDoLayout(self.WidgetSetUpView)

    UIHelper.SetSelected(self.TogSyncTeamFightData, self.bSyncTeamFightData, false)

    UIHelper.ToggleGroupRemoveToggle(self.ToggleGroupLootMode)
    for nIndex, tog in ipairs(self.tbTogLootMode) do
        UIHelper.ToggleGroupAddToggle(self.ToggleGroupLootMode, tog)
        if self.tbTogLootModeMean[nIndex] == self.nSelectedLootMode then
            UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroupLootMode, tog)
        end
    end

    UIHelper.ToggleGroupRemoveToggle(self.ToggleGroupRollQuality)
    for nIndex, tog in ipairs(self.tbTogRollQuality) do
        UIHelper.ToggleGroupAddToggle(self.ToggleGroupRollQuality, tog)
        if self.tbTogRollQualityMean[nIndex] == self.nSelectedRollQualilty then
            UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroupRollQuality, tog)
        end
    end

    UIHelper.ScrollViewDoLayout(self.ScrollView)
    UIHelper.ScrollToTop(self.ScrollView, 0)
end


function UIRaidSetUp:ScrollToBottom(bFirst)
    Timer.AddFrame(self, 1, function ()
        UIHelper.ScrollToBottom(self.ScrollView)
    end)
end

return UIRaidSetUp
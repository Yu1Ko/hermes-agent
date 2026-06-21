-- ---------------------------------------------------------------------------------
-- Name: UIPanelCampElection
-- Prefab: PanelPVPCampCampaign
-- Desc: 阵营 - 指挥竞选
-- ---------------------------------------------------------------------------------
local UIPanelCampElection = class("UIPanelCampElection")

function UIPanelCampElection:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        self.bRefresh = false
    end
    self:UpdateCurrencyInfo()
    self:UpdateInfo()
end

function UIPanelCampElection:OnExit()
    self.bInit = false
    self:UnRegEvent()

    Timer.DelTimer(self, self.nRefreshTimer)
end

function UIPanelCampElection:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnElection, EventType.OnClick, function()
        RemoteCallToServer("On_Vote_CommandSignUp")
    end)

    UIHelper.BindUIEvent(self.BtnFenghuoling, EventType.OnClick, function()
        RemoteCallToServer("On_Vote_GetVoteFlower")
    end)

    UIHelper.BindUIEvent(self.BtnReport, EventType.OnClick, function()
        local script = UIHelper.ShowConfirm(g_tStrings.STR_COMMAND_ACCUSATION, 
            function() RemoteCallToServer("On_Vote_CommandAccusation", 1) end, 
            function()  end)

        script:ShowOtherButton()
        script:SetOtherButtonClickedCallback(
            function() RemoteCallToServer("On_Vote_CommandAccusation", 0) end)

        script:SetConfirmButtonContent("是")
        script:SetCancelButtonContent("取消")
        script:SetOtherButtonContent("否")
    end)
end

function UIPanelCampElection:RegEvent()
    Event.Reg(self, "CUSTOM_RANK_UPDATE", function()
        self:UpdateList()
    end)

    Event.Reg(self, EventType.OnReceiveChat, function(szMsg)
        if szMsg.szContent == g_tStrings.STR_CAMP_NO_REPORT_AUTHORITY then
            TipsHelper.ShowNormalTip(g_tStrings.STR_CAMP_NO_REPORT_AUTHORITY)
        end
    end)

    Event.Reg(self, "LUA_ON_ACTIVITY_STATE_CHANGED_NOTIFY", function(arg0, arg1)
        if arg0 == ACTIVITY_ID.ALLOW_EDIT then
            self:ToggleAllSloganVisible(arg1)
		end
    end)
end

function UIPanelCampElection:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIPanelCampElection:UpdateCurrencyInfo()
    UIHelper.RemoveAllChildren(self.WidgetPVPMoney)
    UIHelper.AddPrefab(PREFAB_ID.WidgetCoin, self.WidgetPVPMoney, CurrencyType.Prestige)
    UIHelper.AddPrefab(PREFAB_ID.WidgetCoin, self.WidgetPVPMoney, CurrencyType.TitlePoint)

    UIHelper.LayoutDoLayout(self.WidgetPVPMoney)
end

function UIPanelCampElection:UpdateInfo()
    if g_pClientPlayer then
        if g_pClientPlayer.nCamp == 1 then
            self.m_nCamp = 216
            UIHelper.SetString(self.LabelTitle, g_tStrings.STR_COMMAND_JUSTICE_LEAGUE)
        elseif	g_pClientPlayer.nCamp == 2 then
            self.m_nCamp = 217
            UIHelper.SetString(self.LabelTitle, g_tStrings.STR_COMMAND_AVENGERS_LEAGUE)
        end
    else
        UIMgr.Close(self)
    end

    ApplyCustomRankList(self.m_nCamp)
    self.tScriptCell = require("Lua/UI/Map/Component/UIPrefabComponent"):CreateInstance()
    self.tScriptCell:Init(self.ScrollViewCampaignContent, PREFAB_ID.WidgetCampaignName)

    self.bShowSlogan = ActivityData.IsMsgEditAllowed()
end

function UIPanelCampElection:UpdateList()
    local tRankingDatas = GetCustomRankList(self.m_nCamp)
    self.nDataNum = #tRankingDatas
    if #tRankingDatas > 0 then
        UIHelper.SetVisible(self.WidgetAnchorMiddleEmptyM, false)
    else
        UIHelper.SetVisible(self.WidgetAnchorMiddleEmptyM, true)
    end

    if self.bShowSloan == nil then
        self.bShowSlogan = ActivityData.IsMsgEditAllowed()
    end

    if self.bRefresh then
        for nRank, tInfo in ipairs(tRankingDatas) do
            -- local scriptCell = UIHelper.AddPrefab(PREFAB_ID.WidgetCampaignName, self.ScrollViewCampaignContent, tInfo, nRank, self.m_nCamp)
            local scriptCell = self.tScriptCell:Alloc(nRank)
            assert(scriptCell)
            scriptCell:OnEnter(tInfo, nRank, self.m_nCamp)
            scriptCell:SetSloganVisible(self.bShowSlogan)
        end
        self.tScriptCell:Clear(#tRankingDatas + 1)
    else
        UIHelper.RemoveAllChildren(self.LayoutCampaignContent)
        for nRank, tInfo in ipairs(tRankingDatas) do
            -- local scriptCell = UIHelper.AddPrefab(PREFAB_ID.WidgetCampaignName, self.ScrollViewCampaignContent, tInfo, nRank, self.m_nCamp)
            local scriptCell = self.tScriptCell:Alloc(nRank)
            assert(scriptCell)
            scriptCell:OnEnter(tInfo, nRank, self.m_nCamp)
            scriptCell:SetSloganVisible(self.bShowSlogan)
        end
        self.tScriptCell:Clear(#tRankingDatas + 1)
        UIHelper.ScrollViewDoLayout(self.ScrollViewCampaignContent)
        UIHelper.ScrollToTop(self.ScrollViewCampaignContent)
        Timer.Add(self, 0.5, function()
            UIHelper.ScrollViewDoLayout(self.ScrollViewCampaignContent)
            UIHelper.ScrollToTop(self.ScrollViewCampaignContent)
        end)

        self.bRefresh = true
        self.nRefreshTimer = Timer.AddCycle(self, 5, function()
            self:ApplyCustomRankList()
        end)
    end
end

function UIPanelCampElection:ApplyCustomRankList()
    ApplyCustomRankList(self.m_nCamp)
end

function UIPanelCampElection:ToggleAllSloganVisible(bVisible)
    for i = 1, self.nDataNum do
        local scriptCell = self.tScriptCell:Alloc(i)
        assert(scriptCell)
        scriptCell:SetSloganVisible(bVisible)
    end
end

return UIPanelCampElection
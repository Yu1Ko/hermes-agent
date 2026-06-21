-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIArenaRankRewardView
-- Date: 2023-01-03 19:53:04
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIArenaRankRewardView = class("UIArenaRankRewardView")

function UIArenaRankRewardView:OnEnter(nArenaType)
    self.nArenaType = nArenaType

    self.tbRewardInfo = {}

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    ArenaData.GetLevelAwardInfo()
    self:UpdateCurrencyInfo()
end

function UIArenaRankRewardView:OnExit()
    self.bInit = false
end

function UIArenaRankRewardView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
    UIHelper.BindUIEvent(self.LayoutMoney, EventType.OnClick, function()
        CurrencyData.ShowCurrencyHoverTips(self.LayoutMoney, CurrencyType.Prestige)
    end)
    UIHelper.SetTouchEnabled(self.LayoutMoney, true)
end

function UIArenaRankRewardView:RegEvent()
    Event.Reg(self, "ON_JJC_LEVEL_AWARD_UPDATE", function(tbInfo, nGotLevel)
		self.tbRewardInfo = tbInfo
		self.nGotLevel = nGotLevel or 0
        self:UpdateInfo()
    end)

    Event.Reg(self, "LEVEL_AWARD_GET_SUCCESS", function()
        ArenaData.GetLevelAwardInfo()
    end)

    Event.Reg(self, EventType.OnArenaClickRewardItem, function(nType, nID)
        if not self.scriptItemTip then
            self.scriptItemTip = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetItemTip)
        end

        self.scriptItemTip:OnInitWithTabID(nType, nID)
        self.scriptItemTip:SetBtnState({})

    end)

    Event.Reg(self, EventType.OnTouchViewBackGround, function()
        if self.scriptItemTip then
            UIHelper.SetVisible(self.scriptItemTip._rootNode, false)
        end
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function()
        if self.scriptItemTip then
            UIHelper.SetVisible(self.scriptItemTip._rootNode, false)
        end
    end)
end

function UIArenaRankRewardView:UpdateInfo()
    local tbConfigs = ArenaData.GetAllLevelInfo()
    local nPlayerID = PlayerData.GetPlayerID()

    local bHadRewarCanGet = not not self.tbRewardInfo[self.nArenaType]
    local nArenaLevel = ArenaData.GetArenaLevel(nPlayerID, self.nArenaType)

    local tbInfo = {}
    local nIndex
    for i, tbConfig in ipairs(tbConfigs) do
        local bHadGet = tbConfig.level <= self.nGotLevel
        local bCanGet = tbConfig.level <= nArenaLevel

        if tbConfig.level > nArenaLevel or (bHadRewarCanGet and tbConfig.level == nArenaLevel) then
            nIndex = nIndex or i - 2
        end
        table.insert(tbInfo, {
            tbConfig.level, bCanGet, bHadGet
        })
    end

    nIndex = math.min(math.max(0, nIndex or 0), #tbConfigs - 1)

    UIHelper.RemoveAllChildren(self.ScrollViewRewardContent)
    for i, tbInfo in ipairs(tbInfo) do
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetRewardContent, self.ScrollViewRewardContent)
        script:OnEnter(self.nArenaType, table.unpack(tbInfo))
    end

    UIHelper.ScrollViewDoLayout(self.ScrollViewRewardContent)
    UIHelper.ScrollToIndex(self.ScrollViewRewardContent, nIndex or 0, 0.2, true)
    UIHelper.SetSwallowTouches(self.ScrollViewRewardContent, false)

end

function UIArenaRankRewardView:UpdateCurrencyInfo()
    UIHelper.SetString(self.LabelNum1, CurrencyData.GetCurCurrencyCount(CurrencyType.Prestige))
    UIHelper.SetString(self.LabelNum2, CurrencyData.GetCurCurrencyCount(CurrencyType.TitlePoint))
    UIHelper.LayoutDoLayout(self.LayoutMoney)
end


return UIArenaRankRewardView
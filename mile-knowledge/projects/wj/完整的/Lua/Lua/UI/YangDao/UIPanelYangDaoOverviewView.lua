-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIPanelYangDaoOverviewView
-- Date: 2026-02-26 16:04:15
-- Desc: 扬刀大会-总览界面 PanelYangDaoOverview
-- ---------------------------------------------------------------------------------

local UIPanelYangDaoOverviewView = class("UIPanelYangDaoOverviewView")

local szReturnIcon = "UIAtlas2_Public_PublicButton_PublicButton1_btn_return_Other"
local szCloseIcon = "UIAtlas2_Public_PublicButton_PublicButton1_btn_Close"

function UIPanelYangDaoOverviewView:OnEnter(nTabIndex, tPlayerStats, nSelPlayerID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        local tLevelList = ArenaTowerData.GetLevelListInfo()
        self.scriptProgress = UIHelper.AddPrefab(PREFAB_ID.WidgetPageProgress, self.WidgetPageProgressShell, tLevelList)

        if tPlayerStats then
            self.scriptBlessList = UIHelper.AddPrefab(PREFAB_ID.WidgetPageBlessList, self.WidgetPageBlessListShell)
            self.scriptBlessList:OnInitPlayerStats(tPlayerStats, nSelPlayerID)
            self.scriptBlessList:SetOutsideCloseBtnSetVisibleCallback(function(bVisible)
                UIHelper.SetVisible(self.BtnClose, bVisible)
            end)
        else
            local tBlessCardList = ArenaTowerData.GetCardListInfo()
            self.scriptBlessList = UIHelper.AddPrefab(PREFAB_ID.WidgetPageBlessList, self.WidgetPageBlessListShell, tBlessCardList)

            UIHelper.AddPrefab(PREFAB_ID.WidgetCoin, self.LayoutCoins, CurrencyType.TianJiToken)
            UIHelper.AddPrefab(PREFAB_ID.WidgetCoin, self.LayoutCoins, CurrencyType.ArenaTowerAward)
            UIHelper.CascadeDoLayoutDoWidget(UIHelper.GetParent(self.LayoutCoins), true, true)
        end
    end

    self.bPlayerStats = tPlayerStats ~= nil
    self:UpdateInfo()

    UIHelper.SetSelected(self.TogTabProgress, true)
    Timer.AddFrame(self, 1, function()
        if nTabIndex == 1 then
            UIHelper.SetSelected(self.TogTabProgress, true)
        elseif nTabIndex == 2 then
            UIHelper.SetSelected(self.TogTabBlessList, true)
        end
    end)
end

function UIPanelYangDaoOverviewView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelYangDaoOverviewView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnRule, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelBattleFieldRulesNew, BATTLE_FIELD_MAP_ID.QING_XIAO_SHAN)
    end)
    UIHelper.BindUIEvent(self.BtnQuit, EventType.OnClick, function()
        local dialog = UIHelper.ShowConfirm(g_tStrings.ARENA_TOWER_LEAVE_CONFIRM, function()
            ArenaTowerData.LeaveArenaTower()
            UIMgr.Close(self)
        end, nil, true)
    end)
    UIHelper.BindUIEvent(self.BtnChat, EventType.OnClick, function()
        ChatHelper.Chat(UI_Chat_Channel.Team)
    end)
    UIHelper.BindUIEvent(self.BtnEquipShop, EventType.OnClick, function()
        ArenaTowerData.OpenArenaTowerAwardShop()
    end)
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        if self.nLevelIndex then
            Event.Dispatch(EventType.OnArenaTowerOverviewLevelDetail, nil)
        else
            UIMgr.Close(self)
        end
    end)
    UIHelper.BindUIEvent(self.TogTabProgress, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected then
            self.selectedTog = self.TogTabProgress
            if not self.bSkipAnim then
                UIHelper.PlayAni(self.scriptProgress, self.scriptProgress.AniAll, "AniPageProgressShow")
            end
        end
    end)
    UIHelper.BindUIEvent(self.TogTabBlessList, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected then
            self.selectedTog = self.TogTabBlessList
            if not self.bSkipAnim then
                UIHelper.PlayAni(self.scriptBlessList, self.scriptBlessList.AniAll, "AniPageBlessListShow")
            end
        end
    end)
end

function UIPanelYangDaoOverviewView:RegEvent()
    Event.Reg(self, EventType.OnArenaTowerOverviewLevelDetail, function(nLevelIndex, bMapFlag)
        self.nLevelIndex = nLevelIndex
        self:UpdateDetailState()
    end)
    Event.Reg(self, EventType.OnArenaTowerDataUpdate, function()
        if self.bPlayerStats then
            return
        end
        local tBlessCardList = ArenaTowerData.GetCardListInfo()
        self.scriptBlessList.tBlessCardList = tBlessCardList
        self.scriptBlessList:UpdateBlessList()
    end)

    -- 打开规则界面的神秘bug，RegisterToggleGroup会导致选中的Toggle被取消选中，这里恢复一下
    Event.Reg(self, EventType.OnViewClose, function(nViewID)
        if nViewID == VIEW_ID.PanelBattleFieldRulesNew then
            if self.selectedTog then
                self.bSkipAnim = true
                UIHelper.SetSelected(self.selectedTog, true)
                self.bSkipAnim = false
            end
        end
    end)
    Event.Reg(self, EventType.OnWindowsSizeChanged, function()
        Timer.AddFrame(self, 4, function()
            UIHelper.LayoutDoLayout(self.LayoutBtns)
        end)
    end)
end

function UIPanelYangDaoOverviewView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIPanelYangDaoOverviewView:UpdateInfo()
    local bInArenaTowerMap = ArenaTowerData.IsInArenaTowerMap()
    UIHelper.SetVisible(self.WidgetQuit, bInArenaTowerMap and not self.bPlayerStats)
    UIHelper.SetVisible(self.WidgetEquipShop, not bInArenaTowerMap and not self.bPlayerStats)
    UIHelper.SetVisible(self.WidgetRule, not self.bPlayerStats)
    UIHelper.SetVisible(self.ImgBgTitleLine, not self.bPlayerStats)
    UIHelper.SetVisible(self.WidgetAnchorLeft, not self.bPlayerStats)
    UIHelper.SetString(self.LabelTitle, self.bPlayerStats and "查看卦象" or "挑战总览")
    UIHelper.LayoutDoLayout(self.LayoutBtns)
end

function UIPanelYangDaoOverviewView:UpdateDetailState()
    local tLevelConfig = ArenaTowerData.GetLevelConfig(self.nLevelIndex)
    if tLevelConfig then
        UIHelper.SetString(self.LabelTitle, UIHelper.GBKToUTF8(tLevelConfig.szName))
        UIHelper.SetSpriteFrame(self.ImgClose, szReturnIcon)
        UIHelper.SetVisible(self.WidgetAnchorLeft, false)
        UIHelper.SetVisible(self.WidgetAnchorTitle, false) -- 新版 改成用艺术字显示关卡名称，原来的标题隐藏
    else
        UIHelper.SetSpriteFrame(self.ImgClose, szCloseIcon)
        UIHelper.SetString(self.LabelTitle, "挑战总览")
        UIHelper.SetVisible(self.WidgetAnchorLeft, true)
        UIHelper.SetVisible(self.WidgetAnchorTitle, true)
    end
end

return UIPanelYangDaoOverviewView
-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIPanelYangDaoBlessUpgradeView
-- Date: 2026-02-28 15:27:52
-- Desc: 扬刀大会-祝福强化界面 PanelYangDaoBlessUpgrade
-- ---------------------------------------------------------------------------------

local UIPanelYangDaoBlessUpgradeView = class("UIPanelYangDaoBlessUpgradeView")

local PRICE_TEXT_COLOR = cc.c3b(255, 255, 255)
local PRICE_TEXT_COLOR_RED = cc.c3b(255, 117, 117)

function UIPanelYangDaoBlessUpgradeView:OnEnter(tEnhancedPrice)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        UIHelper.AddPrefab(PREFAB_ID.WidgetCoin, self.LayoutCoins, CurrencyType.TianJiToken)
        UIHelper.CascadeDoLayoutDoWidget(UIHelper.GetParent(self.LayoutCoins), true, true)

        self.scriptBlessList = UIHelper.GetBindScript(self.WidgetAnchorLeft)
        self.scriptBlessList:SetSelectBlessCardCallback(function(tCardData)
            self:OnSelectBlessCard(tCardData)
        end)
        self.scriptBlessList:SetClearSelectCallback(function()
            self:OnClearSelect()
        end)
    end

    self.tEnhancedPrice = tEnhancedPrice or {} -- [nStar] = nEnhancedPrice

    self:UpdateBlessCardList(true)
    self:UpdateInfo()
end

function UIPanelYangDaoBlessUpgradeView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelYangDaoBlessUpgradeView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnChat, EventType.OnClick, function()
        ChatHelper.Chat(UI_Chat_Channel.Team)
    end)
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
    UIHelper.BindUIEvent(self.TogDetailedDesc, EventType.OnSelectChanged, function(_, bSelected)
        ArenaTowerData.ShowBlessDetailDesc(bSelected)
    end)
    UIHelper.SetClickInterval(self.BtnUpgrade, 1)
    UIHelper.BindUIEvent(self.BtnUpgrade, EventType.OnClick, function()
        if not self.tSelCardData then
            return
        end

        local nEnhancedPrice = self:GetEnhancedPrice(self.tSelCardData)
        local dialog = UIHelper.ShowConfirm(string.format(g_tStrings.ARENA_TOWER_APPLY_ENHANCED_CONFIRM, tostring(nEnhancedPrice)), function()
            self:SetUpgradeBtnEnable(false)
            self.bPlayingEnhancedAni = true
            ArenaTowerData.EnhanceBless(self.nSelCardID)
        end, nil, true)
    end)
end

function UIPanelYangDaoBlessUpgradeView:RegEvent()
    Event.Reg(self, EventType.OnShowBlessDetailDesc, function()
        UIHelper.SetSelected(self.TogDetailedDesc, ArenaTowerData.bShowBlessDetailDesc, false)
    end)
    Event.Reg(self, "On_ArenaTower_ApplyEnhanced_Res", function()
        TipsHelper.ShowNormalTip("卦象赋灵成功")
        -- ArenaTowerData.bArenaTowerViewFold = false
        self:SetUpgradeBtnEnable(true)
        self:UpdateBlessCardList()

        -- 播放左移动画会移动外层Layout，需先保持右侧卡牌位置不变
        UIHelper.SetVisible(self.WidgetArrow, true)
        UIHelper.SetVisible(self.WidgetBlessCardShellLeft, true)
        UIHelper.LayoutDoLayout(self.LayoutContent)

        local function OnEnhancedAniEnd()
            self:ResetEnhancedAniState(function()
                self.bPlayingEnhancedAni = false
                UIHelper.SetVisible(self.WidgetArrow, false)
                UIHelper.SetVisible(self.WidgetBlessCardShellLeft, false)
                UIHelper.LayoutDoLayout(self.LayoutContent)
            end)
        end

        UIHelper.StopAni(self, self.AniAll, "Ani_QiangHua_ToLeft")
        UIHelper.StopAni(self, self.AniAll, "Ani_QiangHua_ToRight")
        UIHelper.PlayAni(self, self.AniAll, "Ani_QiangHua_ToLeft")
        if self.scriptBlessCardRight then
            self.scriptBlessCardRight:PlayAni(BlessCardAniEvent.OnEnhanced, OnEnhancedAniEnd)
        else
            OnEnhancedAniEnd()
        end
    end)
end

function UIPanelYangDaoBlessUpgradeView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIPanelYangDaoBlessUpgradeView:UpdateBlessCardList(bInit)
    local tBlessCardList = ArenaTowerData.GetCardListInfo()
    if not tBlessCardList then
        return
    end

    --排序，将已强化的祝福卡排到最后
    Global.SortStably(tBlessCardList, function(a, b)
        if a.bEnhanced ~= b.bEnhanced then
            return not a.bEnhanced and b.bEnhanced
        end
        if a.bCanEnhanced ~= b.bCanEnhanced then
            return a.bCanEnhanced and not b.bCanEnhanced
        end
        return true -- Global.SortStably要求等于返回true
    end)

    for _, tCardData in pairs(tBlessCardList) do
        tCardData.bEnhancedView = true
    end

    if bInit then
        Timer.AddFrame(self, 1, function()
            self.scriptBlessList:OnEnter(tBlessCardList)
        end)
    else
        self.scriptBlessList.tBlessCardList = tBlessCardList
        self.scriptBlessList:UpdateBlessList()
    end
end

function UIPanelYangDaoBlessUpgradeView:UpdateInfo()
    UIHelper.SetSelected(self.TogDetailedDesc, ArenaTowerData.bShowBlessDetailDesc, false)
    self:OnClearSelect()
end

function UIPanelYangDaoBlessUpgradeView:OnSelectBlessCard(tCardData)
    if not tCardData then
        return
    end

    self.tSelCardData = tCardData
    self.nSelCardID = tCardData.nCardID
    UIHelper.SetVisible(self.TogDetailedDesc, ArenaTowerData.CardHasShortDesc(tCardData))
    UIHelper.SetVisible(self.WidgetEmpty, false)
    self:ResetEnhancedAniState()

    local bCanEnhanced = tCardData.bCanEnhanced or false
    local bEnhanced = tCardData.bEnhanced or false

    local tEnhancedCardData = clone(tCardData)
    if bCanEnhanced and not bEnhanced then
        tEnhancedCardData.bEnhanced = true
        tEnhancedCardData.bPreview = true
        ArenaTowerData.UpdateCardDataSkillInfo(tEnhancedCardData)
        UIHelper.SetVisible(self.WidgetBottomButton, true)
        UIHelper.SetVisible(self.WidgetHintUpgraded, false)
        UIHelper.SetVisible(self.WidgetHintCantUpgrade, false)
        UIHelper.SetVisible(self.WidgetArrow, true)
        UIHelper.SetVisible(self.WidgetBlessCardShellLeft, true)

        self.scriptBlessCardLeft = self.scriptBlessCardLeft or UIHelper.AddPrefab(PREFAB_ID.WidgetBlessCardL, self.WidgetBlessCardShellLeft)
        self.scriptBlessCardLeft:OnInitLargeCard(tCardData)

        local nEnhancedPrice = self:GetEnhancedPrice(self.tSelCardData)
        local nCoinInGame, _ = ArenaTowerData.GetCoinInGameInfo()
        UIHelper.SetString(self.LabelNum, nEnhancedPrice)
        UIHelper.SetColor(self.LabelNum, nCoinInGame >= nEnhancedPrice and PRICE_TEXT_COLOR or PRICE_TEXT_COLOR_RED)
        UIHelper.LayoutDoLayout(self.LayoutCoin)

        if nCoinInGame < nEnhancedPrice then
            self:SetUpgradeBtnEnable(false, "天机筹不足")
        else
            self:SetUpgradeBtnEnable(true)
        end
    else
        UIHelper.SetVisible(self.WidgetBottomButton, false)
        UIHelper.SetVisible(self.WidgetHintUpgraded, bEnhanced)
        UIHelper.SetVisible(self.WidgetHintCantUpgrade, not bCanEnhanced)
        UIHelper.SetVisible(self.WidgetArrow, false)
        UIHelper.SetVisible(self.WidgetBlessCardShellLeft, false) -- 不可强化只显示右侧卡片
        self:SetUpgradeBtnEnable(false)
    end

    self.scriptBlessCardRight = self.scriptBlessCardRight or UIHelper.AddPrefab(PREFAB_ID.WidgetBlessCardL, self.WidgetBlessCardShellRight)
    self.scriptBlessCardRight:OnInitLargeCard(tEnhancedCardData)
    UIHelper.SetVisible(self.WidgetBlessCardShellRight, true)

    UIHelper.LayoutDoLayout(self.LayoutContent)
end

function UIPanelYangDaoBlessUpgradeView:OnClearSelect()
    UIHelper.SetVisible(self.TogDetailedDesc, false)
    UIHelper.SetVisible(self.WidgetEmpty, true)
    UIHelper.SetVisible(self.WidgetArrow, false)
    UIHelper.SetVisible(self.WidgetBlessCardShellLeft, false)
    UIHelper.SetVisible(self.WidgetBlessCardShellRight, false)
    UIHelper.LayoutDoLayout(self.LayoutContent)
    self:SetUpgradeBtnEnable(false)
    self:ResetEnhancedAniState()
    UIHelper.SetVisible(self.WidgetBottomButton, false)
    UIHelper.SetVisible(self.WidgetHintUpgraded, false)
    UIHelper.SetVisible(self.WidgetHintCantUpgrade, false)
    UIHelper.SetString(self.LabelNum, "-")
    UIHelper.SetColor(self.LabelNum, PRICE_TEXT_COLOR)
    UIHelper.LayoutDoLayout(self.LayoutCoin)
end

function UIPanelYangDaoBlessUpgradeView:ResetEnhancedAniState(fnCallback)
    UIHelper.StopAni(self, self.AniAll, "Ani_QiangHua_ToLeft")
    UIHelper.StopAni(self, self.AniAll, "Ani_QiangHua_ToRight")
    UIHelper.PlayAni(self, self.AniAll, "Ani_QiangHua_ToRight", fnCallback) -- 通过一个1帧的动画还原位置
end

function UIPanelYangDaoBlessUpgradeView:SetUpgradeBtnEnable(bEnabled, szTip)
    self.szUpgradeTip = szTip
    -- BTN_STATE没变的话SetButtonState的param不会重复生效
    UIHelper.SetButtonState(self.BtnUpgrade, bEnabled and BTN_STATE.Normal or BTN_STATE.Disable, function()
        if not string.is_nil(self.szUpgradeTip) then
            TipsHelper.ShowNormalTip(self.szUpgradeTip)
        end
    end)
end

function UIPanelYangDaoBlessUpgradeView:GetEnhancedPrice(tCardData)
    if not tCardData then
        return 0
    end

    local nEnhancedPrice = self.tEnhancedPrice[tCardData.nStar] or 0
    return nEnhancedPrice
end

return UIPanelYangDaoBlessUpgradeView
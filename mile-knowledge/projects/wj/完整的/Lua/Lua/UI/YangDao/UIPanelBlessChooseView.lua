-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIPanelBlessChooseView
-- Date: 2026-03-03 10:57:56
-- Desc: 扬刀大会-祝福选择/替换界面 PanelBlessChoose
-- ---------------------------------------------------------------------------------

local UIPanelBlessChooseView = class("UIPanelBlessChooseView")

local REFRESH_PRICE_TEXT_COLOR_GREEN = "#95FF95"
local REFRESH_PRICE_TEXT_COLOR_RED = "#FF7575"

function UIPanelBlessChooseView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        local dwTabType = ArenaTowerData.REFRESH_ITEM_ID[1]
        local dwIndex = ArenaTowerData.REFRESH_ITEM_ID[2]
        local scriptCoin = UIHelper.AddPrefab(PREFAB_ID.WidgetSingleCurrency, self.LayoutCoins, dwTabType, dwIndex, true)
        scriptCoin:SetCustomIcon(ArenaTowerData.REFRESH_ITEM_ICON_PATH)
    end

    self.tSelBlessCardList = ArenaTowerData.GetRandListInfo() -- 选择祝福卡列表
    self.tBlessCardList = ArenaTowerData.GetCardListInfo() -- 持有祝福卡列表 用于筛选主动技能
    self:UpdateInfo()
end

function UIPanelBlessChooseView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelBlessChooseView:BindUIEvent()
    UIHelper.SetClickInterval(self.BtnConfirm, 1)
    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function()
        if not self.tSelCardData or not self.lastSelectCard then
            return
        end

        if self.tSelCardData.bMainSkill and not UIHelper.GetVisible(self.WidgetAnchorSwitchSkill) then
            local tMainSkillCardList = self:GetMainSkillCardList()
            if #tMainSkillCardList >= ArenaTowerData.MAX_MAIN_SKILL_COUNT then
                UIHelper.SetVisible(self.TogDetailedDesc, false)
                UIHelper.SetVisible(self.WidgetAnchorChooseBless, false)
                UIHelper.SetVisible(self.WidgetAnchorSwitchSkill, true)
                UIHelper.SetVisible(self.WidgetRefreshButton, false)
                UIHelper.SetVisible(self.BtnReChoose, true)
                UIHelper.SetString(self.LabelName, "确定替换")
                UIHelper.LayoutDoLayout(self.LayoutBtn)
                self:UpdateConfirmBtnEnable()

                if self.lastSelectMainSkillCard then
                    self.lastSelectMainSkillCard:SetSelected(false)
                end

                UIHelper.RemoveAllChildren(self.WidgetNewSkillShell)
                local script = UIHelper.AddPrefab(PREFAB_ID.WidgetBlessCardL, self.WidgetNewSkillShell)
                script:OnInitLargeCard(self.tSelCardData)
                script:SetNewCard(true)

                UIHelper.CascadeDoLayoutDoWidget(self.WidgetSwitchSkill, true, true)
                self:UpdateBlessCardLayout()
                script:UpdateLayout()
                return
            end
        end

        self:SetBtnEnable(false)
        ArenaTowerData.ChooseBless(self.nSelCardID, self.nSelReplaceCardID)
    end)
    UIHelper.SetClickInterval(self.BtnRefresh, 1)
    UIHelper.BindUIEvent(self.BtnRefresh, EventType.OnClick, function()
        local szUseInfo
        if self.nNeedRefreshCount and self.nNeedRefreshItemCount then
            szUseInfo = string.format("%d易卦点和%d个易卦盘", self.nNeedRefreshCount, self.nNeedRefreshItemCount)
        elseif self.nNeedRefreshCount then
            szUseInfo = string.format("%d易卦点", self.nNeedRefreshCount)
        elseif self.nNeedRefreshItemCount then
            szUseInfo = string.format("%d个易卦盘", self.nNeedRefreshItemCount)
        else
            return
        end

        local szMsg = string.format(g_tStrings.ARENA_TOWER_REFRESH_BONUS_CONFIRM, szUseInfo)
        if self.nCanRefreshCount then
            szMsg = string.format("%s\n（%s%s）", szMsg, g_tStrings.ARENA_TOWER_CAN_USE_REFRESH_POINT, tostring(self.nCanRefreshCount))
        end
        local dialog = UIHelper.ShowConfirm(szMsg, function()
            ArenaTowerData.RefreshBonus()
        end, nil, true)
    end)
    UIHelper.BindUIEvent(self.BtnReChoose, EventType.OnClick, function()
        self.nSelReplaceCardID = nil
        self:OnClearSelect()
    end)
    UIHelper.BindUIEvent(self.BtnBlessList, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelYangDaoOverview, 2)
    end)
    UIHelper.BindUIEvent(self.BtnDetail, EventType.OnClick, function()
        local tElementPoint, _, _ = ArenaTowerData.GetElementPointInfo()
        UIMgr.Open(VIEW_ID.PanelElementDetailSide, tElementPoint)
    end)
    UIHelper.BindUIEvent(self.BtnFold, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
    UIHelper.BindUIEvent(self.BtnChat, EventType.OnClick, function()
        ChatHelper.Chat(UI_Chat_Channel.Team)
    end)
    UIHelper.BindUIEvent(self.TogDetailedDesc, EventType.OnSelectChanged, function(_, bSelected)
        ArenaTowerData.ShowBlessDetailDesc(bSelected)
    end)
end

function UIPanelBlessChooseView:RegEvent()
    Event.Reg(self, EventType.OnShowBlessDetailDesc, function()
        UIHelper.SetSelected(self.TogDetailedDesc, ArenaTowerData.bShowBlessDetailDesc, false)
    end)
    Event.Reg(self, "On_ArenaTower_ChooseBonus_Res", function()
        TipsHelper.ShowNormalTip("选择卦象成功")
        if self.lastSelectCard and not self.lastSelectMainSkillCard then
            self.lastSelectCard:PlayAni(BlessCardAniEvent.OnGetCard, function()
                UIMgr.Close(self)
            end)
        elseif self.lastSelectMainSkillCard then
            UIHelper.PlayAni(self, self.AniAll, "AniSwitchSkill")
            self.lastSelectMainSkillCard:OnInitLargeCard(self.tSelCardData)
            self.lastSelectMainSkillCard:PlayAni(BlessCardAniEvent.OnGetCard, function()
                UIMgr.Close(self)
            end)
        else
            UIMgr.Close(self)
        end
    end)
    Event.Reg(self, "On_ArenaTower_RefreshBonus_Res", function()
        TipsHelper.ShowNormalTip("卦象更换成功")
        self.tSelBlessCardList = ArenaTowerData.GetRandListInfo()
        self:UpdateInfo()
    end)
    Event.Reg(self, "BAG_ITEM_UPDATE", function(dwBoxIndex, dwX, bIsNewAdd)
        local player = GetClientPlayer()
        local item = ItemData.GetPlayerItem(player, dwBoxIndex, dwX)
        local dwTabType = ArenaTowerData.REFRESH_ITEM_ID[1]
        local dwIndex = ArenaTowerData.REFRESH_ITEM_ID[2]
        if item and item.dwTabType == dwTabType and item.dwIndex == dwIndex then
            self:UpdateRefreshState()
        end
    end)
end

function UIPanelBlessChooseView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIPanelBlessChooseView:UpdateInfo()
    UIHelper.SetSelected(self.TogDetailedDesc, ArenaTowerData.bShowBlessDetailDesc, false)
    self:OnClearSelect()
    self:UpdateRefreshState()

    -- 注意这里self.tLabelElement的顺序要与BlessElementType的顺序一致
    local tElementPoint, _, _ = ArenaTowerData.GetElementPointInfo()
    for _, nType in pairs(BlessElementType) do
        UIHelper.SetString(self.tLabelElement[nType], tElementPoint[nType] or 0)
    end

    self.tScriptCards = {}

    UIHelper.RemoveAllChildren(self.LayoutChooseBlessList)
    self.lastSelectCard = nil
    for _, tCardData in ipairs(self.tSelBlessCardList or {}) do
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetBlessCardL, self.LayoutChooseBlessList)
        script:OnInitLargeCard(tCardData, true)
        script:SetClickCallback(function()
            if self.lastSelectCard and self.lastSelectCard ~= script then
                self.lastSelectCard:SetSelected(false)
            end
            self.lastSelectCard = script
            self:OnSelectBlessCard(tCardData)
        end)
        table.insert(self.tScriptCards, script)
    end
    UIHelper.LayoutDoLayout(self.LayoutChooseBlessList)

    local tMainSkillCardList = self:GetMainSkillCardList()
    UIHelper.RemoveAllChildren(self.LayoutCurrentSkillList)
    self.lastSelectMainSkillCard = nil
    for _, tCardData in ipairs(tMainSkillCardList or {}) do
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetBlessCardL, self.LayoutCurrentSkillList)
        script:OnInitLargeCard(tCardData, true)
        script:SetClickCallback(function()
            if self.lastSelectMainSkillCard and self.lastSelectMainSkillCard ~= script then
                self.lastSelectMainSkillCard:SetSelected(false)
            end
            self.lastSelectMainSkillCard = script
            self:OnSelectMainSkillBlessCard(tCardData)
        end)
        table.insert(self.tScriptCards, script)
    end
    UIHelper.LayoutDoLayout(self.LayoutCurrentSkillList)
end

function UIPanelBlessChooseView:OnSelectBlessCard(tCardData)
    if not tCardData then
        return
    end

    self.tSelCardData = tCardData
    self.nSelCardID = tCardData.nCardID
    self.nSelReplaceCardID = nil
    UIHelper.SetVisible(self.TogDetailedDesc, ArenaTowerData.CardHasShortDesc(tCardData))
    UIHelper.LayoutDoLayout(self.LayoutBtn)
    self:UpdateConfirmBtnEnable()
end

function UIPanelBlessChooseView:OnSelectMainSkillBlessCard(tCardData)
    if not tCardData then
        return
    end

    self.nSelReplaceCardID = tCardData.nCardID
    UIHelper.SetVisible(self.TogDetailedDesc, ArenaTowerData.CardHasShortDesc(tCardData))
    UIHelper.LayoutDoLayout(self.LayoutBtn)
    self:UpdateConfirmBtnEnable()
end

function UIPanelBlessChooseView:OnClearSelect()
    UIHelper.SetVisible(self.TogDetailedDesc, false)
    UIHelper.SetVisible(self.WidgetAnchorChooseBless, true)
    UIHelper.SetVisible(self.WidgetAnchorSwitchSkill, false)
    UIHelper.SetVisible(self.WidgetRefreshButton, true)
    UIHelper.SetVisible(self.BtnReChoose, false)
    UIHelper.SetString(self.LabelName, "确定获得")
    UIHelper.LayoutDoLayout(self.LayoutBtn)
    self:UpdateConfirmBtnEnable()
    self:UpdateBlessCardLayout()
end

function UIPanelBlessChooseView:GetMainSkillCardList()
    if self.tMainSkillCardList then
        return self.tMainSkillCardList
    end
    self.tMainSkillCardList = {}
    for _, tCardData in ipairs(self.tBlessCardList or {}) do
        if tCardData.bMainSkill then
            table.insert(self.tMainSkillCardList, tCardData)
        end
    end
    return self.tMainSkillCardList
end

function UIPanelBlessChooseView:UpdateBlessCardLayout()
    for _, script in pairs(self.tScriptCards or {}) do
        script:UpdateLayout()
    end
end

function UIPanelBlessChooseView:UpdateRefreshState()
    local player = GetClientPlayer()
    if not player then
        return
    end

    local nFreeRefreshCount, nUseRefreshCount, nMaxRefreshCount, nRefreshItemCount = ArenaTowerData.GetRefreshCountInfo()
    local nCanRefreshCount = nMaxRefreshCount - nUseRefreshCount
    local nRefreshPrice = ArenaTowerData.BONUS_REFRESH_PRICE

    if nFreeRefreshCount > 0 then
        local szColor = nFreeRefreshCount >= nRefreshPrice and REFRESH_PRICE_TEXT_COLOR_GREEN or REFRESH_PRICE_TEXT_COLOR_RED
        local szText = string.format("免费易卦点：<color=%s>%d</c>/%d", szColor, nFreeRefreshCount, nRefreshPrice)
        UIHelper.SetRichText(self.LabelRefreshNum, szText)
        UIHelper.SetWidth(self.LabelRefreshNum, UIHelper.GetUtf8RichTextWidth(szText, 26) + 8)
        UIHelper.RichTextIgnoreContentAdaptWithSize(self.LabelRefreshNum, true)
        UIHelper.SetVisible(self.ImgRefreshIcon, false)
    else
        local szColor = nRefreshItemCount >= nRefreshPrice and REFRESH_PRICE_TEXT_COLOR_GREEN or REFRESH_PRICE_TEXT_COLOR_RED
        local szText = string.format("易卦盘：<color=%s>%d</c>/%d", szColor, nRefreshItemCount, nRefreshPrice)
        UIHelper.SetRichText(self.LabelRefreshNum, szText)
        UIHelper.SetWidth(self.LabelRefreshNum, UIHelper.GetUtf8RichTextWidth(szText, 26) + 8)
        UIHelper.RichTextIgnoreContentAdaptWithSize(self.LabelRefreshNum, true)
        UIHelper.SetVisible(self.ImgRefreshIcon, true)
    end

    local szColor = nCanRefreshCount >= nRefreshPrice and REFRESH_PRICE_TEXT_COLOR_GREEN or REFRESH_PRICE_TEXT_COLOR_RED
    local szCanRefresh = string.format("%s<color=%s>%d</c>", g_tStrings.ARENA_TOWER_CAN_USE_REFRESH_POINT, szColor, nCanRefreshCount)
    UIHelper.SetRichText(self.LabelRefreshDesc, szCanRefresh)
    UIHelper.SetWidth(self.LabelRefreshDesc, UIHelper.GetUtf8RichTextWidth(szCanRefresh, 24) + 12)
    UIHelper.RichTextIgnoreContentAdaptWithSize(self.LabelRefreshDesc, true)

    self.nNeedRefreshCount = nil
    self.nNeedRefreshItemCount = nil
    self.nCanRefreshCount = nCanRefreshCount
    if nFreeRefreshCount >= nRefreshPrice then
        self.nNeedRefreshCount = nRefreshPrice
    elseif nFreeRefreshCount > 0 and nFreeRefreshCount + nRefreshItemCount >= nRefreshPrice then
        self.nNeedRefreshCount = nFreeRefreshCount
        self.nNeedRefreshItemCount = nRefreshPrice - nFreeRefreshCount
    elseif nRefreshItemCount >= nRefreshPrice then
        self.nNeedRefreshItemCount = nRefreshPrice
    end

    if self.nNeedRefreshCount or self.nNeedRefreshItemCount then
        local bCanRefresh = nCanRefreshCount >= nRefreshPrice
        UIHelper.SetButtonState(self.BtnRefresh, bCanRefresh and BTN_STATE.Normal or BTN_STATE.Disable, "本次闯关可消耗易卦点不足")
    else
        UIHelper.SetButtonState(self.BtnRefresh, BTN_STATE.Disable, "易卦点和易卦盘不足")
    end

    UIHelper.LayoutDoLayout(self.LayoutRefreshCoin)
end

function UIPanelBlessChooseView:UpdateConfirmBtnEnable()
    local bEnabled
    if UIHelper.GetVisible(self.WidgetAnchorSwitchSkill) then
        bEnabled = self.nSelReplaceCardID ~= nil
    else
        bEnabled = self.nSelCardID ~= nil
    end
    UIHelper.SetButtonState(self.BtnConfirm, bEnabled and BTN_STATE.Normal or BTN_STATE.Disable)
end

function UIPanelBlessChooseView:SetBtnEnable(bEnabled)
    local nBtnState = bEnabled and BTN_STATE.Normal or BTN_STATE.Disable
    UIHelper.SetButtonState(self.BtnConfirm, nBtnState)
    UIHelper.SetButtonState(self.BtnRefresh, nBtnState)
    UIHelper.SetButtonState(self.BtnReChoose, nBtnState)
    UIHelper.SetButtonState(self.BtnBlessList, nBtnState)

    for _, script in pairs(self.tScriptCards or {}) do
        script:SetCanSelect(bEnabled)
    end
end

return UIPanelBlessChooseView
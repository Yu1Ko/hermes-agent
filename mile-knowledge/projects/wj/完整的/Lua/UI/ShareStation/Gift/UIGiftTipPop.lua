-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIGiftTipPop
-- Date: 2025-09-22 14:57:31
-- Desc: 打赏提示弹窗，支持 ShareStation / GlobalID / ObserveInstance / ObserveInstance_Team
-- ---------------------------------------------------------------------------------
-- UIMgr.Open(VIEW_ID.PanelSendGiftNewPop)
local UIGiftTipPop = class("UIGiftTipPop")

function UIGiftTipPop:OnEnter(nTipType, tTarget, fnSendGift)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nTipType = nTipType
    self.tTarget = tTarget or {}
    self.fnSendGift = fnSendGift

    self:UpdateTargetType()
    self:UpdateInfo()
    self:UpdateMoneyOwn()
    self:UpdateMoneyCost()
end

function UIGiftTipPop:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UIGiftTipPop:BindUIEvent()
    UIHelper.SetTouchDownHideTips(self.BtnDetail, false)
    UIHelper.SetEditboxTextHorizontalAlign(self.EditPaginate, TextHAlignment.CENTER)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnDetail, EventType.OnClick, function(btn)
        UIHelper.SetVisible(self.WidgetTip, true)
    end)

    UIHelper.BindUIEvent(self.BtnAdd, EventType.OnClick, function(btn)
        if not self.tSelected or table.is_empty(self.tSelected) then
            return
        end
        self:UpdateSelectedNum(self.tSelected.nNum + 1)
    end)

    UIHelper.BindUIEvent(self.BtnDecrease, EventType.OnClick, function(btn)
        if not self.tSelected or table.is_empty(self.tSelected) then
            return
        end
        self:UpdateSelectedNum(self.tSelected.nNum - 1)
    end)

    UIHelper.RegisterEditBoxChanged(self.EditPaginate, function()
        local szText = UIHelper.GetText(self.EditPaginate) or ""
        self:UpdateSelectedNum(tonumber(szText) or 0)
    end)

    UIHelper.BindUIEvent(self.BtnAccept, EventType.OnClick, function(btn)
        if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TRADE) then
            return
        end

        if self.fnSendGift then
            self.fnSendGift(self.tSelected)
        end
    end)
end

function UIGiftTipPop:RegEvent()
    Event.Reg(self, EventType.HideAllHoverTips, function()
        if not self.bInit then return end
        UIHelper.SetVisible(self.WidgetTip, false)
    end)

    Event.Reg(self, EventType.OnGameNumKeyboardChanged, function(editbox, nCurNum)
        if not self.bInit then return end
        if editbox ~= self.EditPaginate then return end
        self:UpdateSelectedNum(nCurNum or 0)
    end)

    Event.Reg(self, EventType.OnMemberLeaveVoiceRoom, function(szRoomID, szMemberID)
        if not self.bInit then return end
        if self.nTipType ~= TIP_TYPE.GlobalID and self.nTipType ~= TIP_TYPE.ObserveInstance then
            return
        end
        if not self.tTarget or table.is_empty(self.tTarget) then
            return
        end
        if g_pClientPlayer.GetGlobalID() == szMemberID or szMemberID == self.tTarget.szGlobalID then
            UIMgr.Close(self)
        end
    end)

    -- 团队人数变化 → 刷新人数显示和花费
    Event.Reg(self, EventType.ON_DUNGEON_OB_COMPETITOR_VARIABLE_INFO_UPDATE_UI, function()
        if self.nTipType ~= TIP_TYPE.ObserveInstance_Team then
            return
        end
        self:UpdateTeamMessage()
        self:UpdateMoneyCost()
    end)
end

function UIGiftTipPop:UnRegEvent()
    --Event.UnReg(self, EventType.ON_DUNGEON_OB_COMPETITOR_VARIABLE_INFO_UPDATE_UI)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIGiftTipPop:UpdateTargetType()
    local tbTargetType = self.tbTargetType
    if not tbTargetType then
        return
    end

    for _, node in pairs(tbTargetType) do
        UIHelper.SetVisible(node, false)
    end

    local nTipType = self.nTipType
    if nTipType == TIP_TYPE.ShareStation then
        UIHelper.SetVisible(tbTargetType[1], true)
        UIHelper.SetVisible(self.LayoutCount, true)
        UIHelper.SetVisible(self.LabelPeopleNum, false)
        self:UpdateWorkMessage()
    elseif nTipType == TIP_TYPE.GlobalID or nTipType == TIP_TYPE.ObserveInstance then
        UIHelper.SetVisible(tbTargetType[2], true)
        UIHelper.SetVisible(self.LayoutCount, true)
        UIHelper.SetVisible(self.LabelPeopleNum, false)
        self:UpdatePeopleMessage()
    elseif nTipType == TIP_TYPE.ObserveInstance_Team then
        UIHelper.SetVisible(tbTargetType[3], true)
        UIHelper.SetVisible(self.LayoutCount, true)
        UIHelper.SetVisible(self.LabelPeopleNum, true)
        self:UpdateTeamMessage()
    end
end

function UIGiftTipPop:UpdateWorkMessage()
    local tTarget = self.tTarget
    if not tTarget then
        return
    end

    local szWorkName = tTarget.szName or ""
    local szAuthorName = tTarget.szUser or ""
    UIHelper.SetString(self.LabelWorkName, szWorkName)
    UIHelper.SetString(self.LabelWorkerName, szAuthorName)
end

function UIGiftTipPop:UpdatePeopleMessage()
    local tTarget = self.tTarget
    if not tTarget or (not tTarget.szGlobalID and not tTarget.nPlayerID) then
        return
    end

    -- 设置接收者名字
    local tbInfo = RoomVoiceData.GetVoiceRoomMemberSocialInfo(tTarget.szGlobalID)
    local szName = tbInfo and UIHelper.GBKToUTF8(tbInfo.szName) or ""
    if string.is_nil(szName) and tTarget.nPlayerID then
        local player = GetPlayer(tTarget.nPlayerID)
        szName = player and UIHelper.GBKToUTF8(player.szName) or ""
    end
    UIHelper.SetString(self.LabelRecivierName, szName)

    -- 加载头像组件
    UIHelper.RemoveAllChildren(self.WidgetRoomPlayerCell)
    UIHelper.AddPrefab(PREFAB_ID.WidgetGiftReceiverCellNew, self.WidgetRoomPlayerCell, tTarget.szRoomID, {szGlobalID = tTarget.szGlobalID, nPlayerID = tTarget.nPlayerID})
end

function UIGiftTipPop:UpdateTeamMessage()
    local nTeamNum = OBDungeonData.GetPlayerNum()
    UIHelper.SetString(self.LabelPeopleNum, "x"..tostring(nTeamNum))
    UIHelper.LayoutDoLayout(self.LayoutCount)
end

function UIGiftTipPop:SetMoneyLabel(tbMoney, nTotal)
    if nTotal < 0 then
        nTotal = 0
    end
    local nZhuan = math.floor(nTotal / 10000)
    local nJin = nTotal % 10000
    UIHelper.SetString(tbMoney[1], tostring(nZhuan))
    UIHelper.SetString(tbMoney[2], tostring(nJin))
    UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)
end

function UIGiftTipPop:UpdateMoneyCost()
    if not self.tbMoneyCost then
        return
    end

    local nTotal = 0
    if self.tSelected and not table.is_empty(self.tSelected) then
        local nGold = self.tSelected.nGoldNum or 0
        local nNum = self.tSelected.nNum or 1
        nTotal = nGold * nNum

        if self.nTipType == TIP_TYPE.ObserveInstance_Team then
            local nTeamNum = OBDungeonData.GetPlayerNum()
            nTotal = nTotal * nTeamNum
        end
    end

    self:SetMoneyLabel(self.tbMoneyCost, nTotal)
end

function UIGiftTipPop:UpdateMoneyOwn()
    if not self.tbMoneyOwn then
        return
    end

    local player = GetClientPlayer()
    if not player then
        self:SetMoneyLabel(self.tbMoneyOwn, 0)
        return
    end

    local nGold = player.GetMoney().nGold or 0
    self:SetMoneyLabel(self.tbMoneyOwn, nGold)
end

function UIGiftTipPop:UpdateInfo()
    UIHelper.RemoveAllChildren(self.ScrollViewGift)

    local tInfo = Table_GetTipItemList()
    for index, tItem in ipairs(tInfo) do
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetGiftTogCell, self.ScrollViewGift)
        script:OnEnter(tItem)

        local toggle = script:GetToggle()
        UIHelper.SetToggleGroupIndex(toggle, ToggleGroupIndex.FameReward)
        UIHelper.BindUIEvent(toggle, EventType.OnSelectChanged, function(toggle, bSelected)
            if not bSelected then
                return
            end
            self.tSelected = clone(tItem)
            self:UpdateSelectedNum()
            self:UpdateBtnState()
        end)

        if index == 1 then
            UIHelper.SetSelected(toggle, true)
        end
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewGift)
    UIHelper.SetVisible(self.WidgetMainContent, true)
    self:UpdateBtnState()
end

function UIGiftTipPop:UpdateBtnState()
    local bEnable = self.tSelected and not table.is_empty(self.tSelected)
    if bEnable then
        bEnable = self.tSelected.nNum > 0
    end

    UIHelper.SetButtonState(self.BtnAccept, bEnable and BTN_STATE.Normal or BTN_STATE.Disable)
end

function UIGiftTipPop:UpdateSelectedNum(nNewNum)
    if not self.tSelected or table.is_empty(self.tSelected) then
        return
    end

    if not nNewNum or nNewNum <= 0 then
        nNewNum = 1
    end
    self.tSelected.nNum = nNewNum
    UIHelper.SetText(self.EditPaginate, tostring(nNewNum))
    self:UpdateMoneyCost()
end

return UIGiftTipPop
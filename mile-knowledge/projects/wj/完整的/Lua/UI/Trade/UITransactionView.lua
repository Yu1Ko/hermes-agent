-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UITransactionView
-- Date: 2023-02-13 09:51:27
-- Desc: PanelTransaction
-- ---------------------------------------------------------------------------------

local UITransactionView = class("UITransactionView")

local MAX_ITEM_COUNT = 7
local WARNING_TIME = 3

function UITransactionView:OnEnter(dwID)
    self.dwID = dwID

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        self.scriptBag = UIHelper.GetBindScript(self.WidgetRightBag)

        self.tbSelfItem = {}
        self.tbOtherItem = {}

        self:InitUI()

        Timer.AddFrameCycle(self, 1, function()
            self:OnUpdate()
        end)
    end

    UIMgr.HideLayer(UILayer.Main)
end

function UITransactionView:OnExit()
    self.bInit = false
    self:UnRegEvent()

    UIMgr.ShowLayer(UILayer.Main)
    FilterDef.SideBag.Reset()
    self:RemoveTips()

    UIMgr.Close(VIEW_ID.PanelChatSocial)
    if self.szOriginRuntimeChannel then
        ChatData.SetRuntimeSelectDisplayChannel(self.szOriginRuntimeChannel)
    end
    if self.szOriginMiniChannel then
        ChatData.SetMiniDisplayChannel(self.szOriginMiniChannel)
        Event.Dispatch(EventType.OnChatMiniChannelSelected, self.szOriginMiniChannel)
    end
end

function UITransactionView:OnUpdate()
    self:UpdateExitTrade()
end

function UITransactionView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function()
        self:ExitTrade()
    end)
    UIHelper.BindUIEvent(self.BtnSure, EventType.OnClick, function()
        self:CloseBag()

        local player = GetClientPlayer()
        local tLMoney = ConvertMoney(
            UIHelper.GetString(self.EditBox01R),
            UIHelper.GetString(self.EditBox02R),
            UIHelper.GetString(self.EditBox03R)
        )
        local tMoney = player.GetMoney()
        if IsRemotePlayer(player.dwID) then
            -- OutputMessage("MSG_SYS", g_tStrings.STR_MONEY_NOT_TRADE_SERVER.."\n")
            OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_MONEY_NOT_TRADE_SERVER)
        elseif MoneyOptCmp(tLMoney, tMoney) > 0  then
            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_MONEY_BUY_NOT_ENOUGH_MONEY)
            return
        end

        TradingConfirm(true)
    end)
    UIHelper.BindUIEvent(self.BtnCloseRight, EventType.OnClick, function()
        self:CloseBag()
    end)

    for i = 1, MAX_ITEM_COUNT do
        local nIndex = i
        UIHelper.BindUIEvent(self.BtnAddR[i], EventType.OnClick, function()
            self:OnSelfItemGridClick(nIndex - 1)
        end)
    end

    for i = 1, 3 do
        local nIndex = i
        local editBox = self[string.format("EditBox0%dR", nIndex)]
        UIHelper.RegisterEditBox(editBox, function(szType, _editbox)
            --2024.4.28 手机端出现了交易成功后立即弹交易失败tips的bug，怀疑是关闭界面后，不知道什么原因触发了输入框的事件，调了TradingSetMoney导致的，这里加个判断
            if not self.bInit then
                return
            end

            if szType == "began" then
                self:CloseBag()
            elseif szType == "changed" then
                self:OnEditBoxChanged(nIndex)
            end
        end)
    end
end

function UITransactionView:RegEvent()
    Event.Reg(self, EventType.OnGameNumKeyboardChanged, function(editbox, num)
        local tbEditBox = {}
        for i = 1, 3 do
            local _editbox = self[string.format("EditBox0%dR", i)]
            if _editbox == editbox then
                --self:CloseBag()
                self:OnEditBoxChanged(i)
            end
        end
    end)
    Event.Reg(self, "TRADING_UPDATE_CONFIRM", function(dwID, bConfirm)
        print("[Trade] TRADING_UPDATE_CONFIRM", dwID, bConfirm)
        if dwID == self.dwID then
            self:UpdateOtherState(bConfirm)
        elseif dwID == GetClientPlayer().dwID then
            self:UpdateSelfState(bConfirm)
        end
    end)
    Event.Reg(self, "TRADING_UPDATE_ITEM", function(dwID, dwBoxIndex, dwPosIndex, dwGridIndex)
        print("[Trade] TRADING_UPDATE_ITEM", dwID, dwBoxIndex, dwPosIndex, dwGridIndex)
        if dwID == GetClientPlayer().dwID then
            --print("[Trade] UpdateSelfItem", dwBoxIndex, dwPosIndex, dwGridIndex)
            self:UpdateSelfItem(dwBoxIndex, dwPosIndex, dwGridIndex)
        elseif dwID == self.dwID then
            --print("[Trade] UpdateOtherItem", dwBoxIndex, dwPosIndex, dwGridIndex)
            self:UpdateOtherItem(dwBoxIndex, dwPosIndex, dwGridIndex)
        end
    end)
    Event.Reg(self, "TRADING_UPDATE_MONEY", function(dwID, nGold, nSilver, nCopper)
        print("[Trade] TRADING_UPDATE_MONEY", dwID, nGold, nSilver, nCopper)
        local tMoney = PackMoney(nGold, nSilver, nCopper)
        if dwID == self.dwID then
            self:UpdateTradeOtherMoney(tMoney)
        elseif dwID == GetClientPlayer().dwID then
        end
    end)
    Event.Reg(self, "TRADING_CLOSE", function()
        print("[Trade] TRADING_CLOSE")
        self:ExitTrade(true)
    end)
    Event.Reg(self, "BAG_ITEM_UPDATE", function(nBox, nIndex, bNewAdd)
        if UIHelper.GetVisible(self.WidgetRightBag) then
            self:ShowBag() --刷新侧背包显示
        end
    end)
    Event.Reg(self, "UPDATE_FELLOWSHIP_CARD", function(tIDList)
        local hPlayer = GetPlayer(self.dwID)
        if not hPlayer then
            return
        end

        local szGlobalID = hPlayer.GetGlobalID()
        for _, id in ipairs(tIDList) do
            if id == szGlobalID then
                self:UpdateUnknownTipState()
                break
            end
        end
    end)

    --对方道具Tips关闭时 取消道具格子Toggle的选中状态
    Event.Reg(self, EventType.OnHoverTipsDeleted, function(nPrefabID)
        if nPrefabID == PREFAB_ID.WidgetItemTip and self.bShowingOtherItemTip then
            self.bShowingOtherItemTip = false
            Event.Dispatch(EventType.OnClearUICommonItemSelect)
        end
    end)

    Event.Reg(self, EventType.EmailBagItemSelected, function(nBox, nIndex, nCurCount)
        local item = ItemData.GetItemByPos(nBox, nIndex)
        if not item then
            return
        end

        self:OnItemSelect(nBox, nIndex, nCurCount)
    end)

    Event.Reg(self, EventType.OnTouchViewBackGround, function()
        self:CloseBag()
    end)

    Event.Reg(self, EventType.OnWindowsSizeChanged, function()
        self:CloseBag()
    end)

    Event.Reg(self, EventType.OnViewClose, function(nViewID)
        if nViewID == VIEW_ID.PanelChatSocial then
            ChatData.SetRuntimeSelectDisplayChannel(UI_Chat_Channel.Whisper)
        end
    end)
end

function UITransactionView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UITransactionView:InitUI()
    UIHelper.AddPrefab(PREFAB_ID.WidgetCurrency, self.LayoutCurrency)
    local scriptChat = UIHelper.AddPrefab(PREFAB_ID.WidgetMainCityMiniChat2, self.WidgetChat, MAIN_CITY_CONTROL_MODE.SIMPLE)
    UIHelper.SetVisible(scriptChat.BtnOpenSocial, false)

    UIHelper.SetVisible(self.LabelContent, false)
    UIHelper.SetVisible(self.ImgLabelChangeBg, false)

    for i = 1, MAX_ITEM_COUNT do
        UIHelper.SetVisible(self.MaskLight[i], false)
        UIHelper.SetVisible(self.ImgChange[i], false)
    end

    UIHelper.SetEnable(self.EditBox01L, false)
    UIHelper.SetEnable(self.EditBox02L, false)
    UIHelper.SetEnable(self.EditBox03L, false)

    local szPlayerName = "对方"
    if self.dwID then
        local player = GetPlayer(self.dwID)
        if player then
            szPlayerName = UIHelper.GBKToUTF8(player.szName)
            self:InitChat(player)
        end
    end
    UIHelper.SetString(self.LabelPlayer, szPlayerName)

    local hFellow = GetSocialManagerClient()
    local hPlayer = GetPlayer(self.dwID)
    if hFellow and hPlayer then
        local szGlobalID = hPlayer.GetGlobalID()
        hFellow.ApplyFellowshipCard(szGlobalID)
    end

    self:UpdateTradeOtherMoney(PackMoney(0), true)
    self:UpdateTradeSelfMoney(PackMoney(0))
    self:UpdateSelfState(false)
    self:UpdateOtherState(false)
    self:UpdateBtnSureState(false)
    self:UpdateUnknownTipState()
end

function UITransactionView:InitChat(player)
    if not player then
        return
    end

    self.szOriginRuntimeChannel = ChatData.GetRuntimeSelectDisplayChannel()
    self.szOriginMiniChannel = ChatData.GetMiniDisplayChannel()

    ChatData.SetRuntimeSelectDisplayChannel(UI_Chat_Channel.Whisper)
    ChatData.SetMiniDisplayChannel(UI_Chat_Channel.Whisper)
    Event.Dispatch(EventType.OnChatMiniChannelSelected, UI_Chat_Channel.Whisper)

    local szName = UIHelper.GBKToUTF8(player.szName)
    local dwTalkerID = player.dwID
    local dwForceID = player.dwForceID or player.nForceID
    local szGlobalID = player.GetGlobalID()
    local tbData = {szName = szName, dwTalkerID = dwTalkerID, dwForceID = dwForceID, szGlobalID = szGlobalID}

    ChatData.AddWhisper(szName, tbData)
end

function UITransactionView:UpdateExitTrade()
    local clientPlayer = GetClientPlayer()
    if not clientPlayer then
        self:ExitTrade()
        return
    end

    if clientPlayer.nMoveState == MOVE_STATE.ON_DEATH  then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tTradingResultString[TRADING_RESPOND_CODE.YOU_DEAD])
        self:ExitTrade()
        return
    end

    if IsEnemy(clientPlayer.dwID, self.dwID) then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_TRADING_ENEMY)
        self:ExitTrade()
        return
    end

    local player = GetPlayer(self.dwID)
    if not player or player.nMoveState == MOVE_STATE.ON_DEATH or not player.CanDialog(clientPlayer) then
        if player and player.nMoveState == MOVE_STATE.ON_DEATH then
            OutputMessage("MSG_SYS", g_tStrings.STR_TRADING_CANCEL)
        else
            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_TRADING_CANCEL_REASON_TOO_FAR)
        end
        self:ExitTrade()
    end
end

function UITransactionView:ExitTrade(bNotConfirm)
    if not bNotConfirm then
        TradingConfirm(false)
    end
    UIMgr.Close(self)
end

function UITransactionView:OnSelfItemGridClick(nGridIndex)
    self.nCurGridIndex = nGridIndex
    self:ShowBag()

    Timer.AddFrame(self, 1, function()
        self:UpdateSelectEffect()
    end)
end

function UITransactionView:OnEditBoxChanged(nIndex)
    local editBox = self[string.format("EditBox0%dR", nIndex)]
    UIHelper.SetString(editBox, tonumber(UIHelper.GetString(editBox)))

    local player  = GetClientPlayer()
    local tLMoney = ConvertMoney(
        UIHelper.GetString(self.EditBox01R),
        UIHelper.GetString(self.EditBox02R),
        UIHelper.GetString(self.EditBox03R)
    )
    local tMoney = player.GetMoney()
    if MoneyOptCmp(tLMoney, tMoney) > 0  then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_MONEY_BUY_NOT_ENOUGH_MONEY)
        --防止误交易，不强行改当前输入框数字
        -- local nGoldB, nGold, nSilver = UnpackMoneyEx(tMoney)
        -- UIHelper.SetString(self.EditBox01R, nGoldB)
        -- UIHelper.SetString(self.EditBox02R, nGold)
        -- UIHelper.SetString(self.EditBox03R, nSilver)
    else
        TradingSetMoney(tLMoney.nGold or 0, tLMoney.nSilver or 0, tLMoney.nCopper or 0)
    end
end

function UITransactionView:OnItemSelect(dwBoxID, dwX, dwSplitAmount)
    self:RemoveTips()

    if not IsObjectFromBag(dwBoxID) then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.TRADE_ONLY_FROM_BAG)
        return
    end

    local player = GetClientPlayer()
    local item = ItemData.GetPlayerItem(player, dwBoxID, dwX)
    if not item then
        return
    end

    if not self.nCurGridIndex then
        local nEmptyGridIndex = -1
        for i = 0, MAX_ITEM_COUNT - 1 do
            if not self.tbSelfItem[i] then
                nEmptyGridIndex = i
                break
            end
        end
        if nEmptyGridIndex >= 0 then
            self.nCurGridIndex = nEmptyGridIndex
        else
            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.TRADE_ITEM_FULL)
        end
    end

    for i = 0, MAX_ITEM_COUNT - 1 do
        if self.tbSelfItem[i] and (self.nCurGridIndex == i or self.tbSelfItem[i].dwBoxID == dwBoxID and self.tbSelfItem[i].dwX == dwX) then
            TradingDeleteItem(i)
        end
    end

    print("[Trade] Call TradingAddItem", dwBoxID, dwX, self.nCurGridIndex, dwSplitAmount)
    if item.nGenre == ITEM_GENRE.BOOK then
        TradingAddItem(dwBoxID, dwX, self.nCurGridIndex) --书籍的nBookID是存在nStackNum里的，交易书籍时，如果传了数量的话会把nBookID覆盖掉
    else
        TradingAddItem(dwBoxID, dwX, self.nCurGridIndex, dwSplitAmount)
    end
end

function UITransactionView:ShowBag()
    local player = GetClientPlayer()
    if not player then
        return
    end

    local tItemTabTypeAndIndexList = {}
    local tbBag = ItemData.GetCurrentBag()
    for _, tbItemInfo in ipairs(ItemData.GetItemList(tbBag)) do
        if tbItemInfo.hItem then
            local dwMapBanTradeItemMask = tbItemInfo.hItem.dwMapBanTradeItemMask
            local dwBanTradeItemMask = player.GetScene().dwBanTradeItemMask
            local bEnable = IsEnableTradeItem(dwMapBanTradeItemMask, dwBanTradeItemMask, tbItemInfo.hItem)
            if bEnable then
                local nCount = 0
                for _, tbItemData in pairs(self.tbSelfItem) do
                    if tbItemData.dwBoxID == tbItemInfo.nBox and tbItemData.dwX == tbItemInfo.nIndex then
                        nCount = tbItemData.dwSplitAmount
                    end
                end
                table.insert(tItemTabTypeAndIndexList, {nBox = tbItemInfo.nBox, nIndex = tbItemInfo.nIndex, nSelectedQuantity = nCount, hItem = tbItemInfo.hItem})
            end
        end
    end

    local tbFilterInfo = {}
    tbFilterInfo.Def = FilterDef.SideBag
    tbFilterInfo.tbfuncFilter = BagDef.CommonFilter

    self.scriptBag:OnInitWithBox(tItemTabTypeAndIndexList, tbFilterInfo)
    self.scriptBag:SetClickCallback(function(bSelected, nBox, nIndex)
        if bSelected then
            self:OnClickItem(nBox, nIndex)
        end
    end)
    self.scriptBag:OnInitCatogory(BagDef.CommonCatogory)
    self.scriptBag:SetCloseCallback(function()
        self:CloseBag()
    end)

    if not UIHelper.GetVisible(self.WidgetRightBag) then
        UIHelper.StopAni(self, self.AinAll, "AniMoveLeft")
        UIHelper.StopAni(self, self.AinAll, "AniMoveRight")
        UIHelper.PlayAni(self, self.AinAll, "AniMoveLeft")
    end
end

function UITransactionView:CloseBag()
    Event.Dispatch(EventType.OnClearUICommonItemSelect)
    Event.Dispatch(EventType.OnSetUIItemIconChoose, false)
    for i, v in ipairs(self.BtnAddR) do
        UIHelper.SetSelected(v, false)
    end

    if UIHelper.GetVisible(self.WidgetRightBag) then
        UIHelper.StopAni(self, self.AinAll, "AniMoveLeft")
        UIHelper.StopAni(self, self.AinAll, "AniMoveRight")
        UIHelper.PlayAni(self, self.AinAll, "AniMoveRight")
    end
end

function UITransactionView:OnClickItem(nBox, nIndex)
    local tItem = ItemData.GetItemByPos(nBox, nIndex)
    local nStackNum = ItemData.GetItemStackNum(tItem)

    local _, scriptItemTip = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetItemTip, self.WidgetItemTip, TipsLayoutDir.MIDDLE)

    local tbItemData = self.tbSelfItem[self.nCurGridIndex]
    local nCurCount = tbItemData and tbItemData.dwSplitAmount or 1

    scriptItemTip:ShowPlacementBtn(true, nStackNum, nCurCount)
    scriptItemTip:OnInit(nBox, nIndex)
end

function UITransactionView:UpdateSelfItem(dwBoxIndex, dwPosIndex, dwGridIndex)
    local node = self.WidgetGoodsR[dwGridIndex + 1] assert(node, dwGridIndex)

    local player = GetClientPlayer()
    local item = player.GetTradingItem(dwGridIndex)

    --取消原来位置道具在背包中的选择效果
    if self.tbSelfItem[dwGridIndex] then
        Event.Dispatch(EventType.OnSetUIItemIconChoose, false, self.tbSelfItem[dwGridIndex].dwBoxID, self.tbSelfItem[dwGridIndex].dwX)
    end

    if dwBoxIndex == INVENTORY_INDEX.INVALID or not item then
        UIHelper.RemoveAllChildren(node)
        self.tbSelfItem[dwGridIndex] = nil
    else
        local script = self:SetupItemContent(node, item)
        script:RegisterSelectEvent(function(bSelected)
            self:OnSelfItemGridClick(dwGridIndex)
        end)
        script:RegisterRecallEvent(function()
            TradingDeleteItem(dwGridIndex)
        end)

        local dwSplitAmount = self:GetItemNum(item)
        Event.Dispatch(EventType.OnSetUIItemIconChoose, true, dwBoxIndex, dwPosIndex, dwSplitAmount)
        self.tbSelfItem[dwGridIndex] = {
            script = script,
            dwBoxID = dwBoxIndex,
            dwX = dwPosIndex,
            dwSplitAmount = dwSplitAmount
        }

        local nEmptyGridIndex = -1
        for i = 0, MAX_ITEM_COUNT - 1 do
            if not self.tbSelfItem[i] then
                nEmptyGridIndex = i
                break
            end
        end
        if nEmptyGridIndex >= 0 then
            self.nCurGridIndex = nEmptyGridIndex
        end
    end

    self:UpdateSelectEffect()
end

function UITransactionView:UpdateOtherItem(dwBoxIndex, dwPosIndex, dwGridIndex)
    local node = self.WidgetGoodsL[dwGridIndex + 1] assert(node, dwGridIndex)

    local player = GetPlayer(self.dwID)
    local item = player.GetTradingItem(dwGridIndex)
    if dwBoxIndex == INVENTORY_INDEX.INVALID or not item then
        UIHelper.RemoveAllChildren(node)
        if self.tbOtherItem[dwGridIndex] then
            self:ShowChangeWarning(dwGridIndex)
        end
        self.tbOtherItem[dwGridIndex] = nil
    else
        local script = self:SetupItemContent(node, item)
        script:RegisterSelectEvent(function(bSelected)
            self:RemoveTips()
            local tips, tipsScriptView = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetItemTip, node)
            tipsScriptView:SetBookID(item.nBookID)
            tipsScriptView:OnInitWithTabID(item.dwTabType, item.dwIndex)
            tipsScriptView:SetBtnState({})
            self.bShowingOtherItemTip = true

            script:SetSelected(true)
        end)
        if self.tbOtherItem[dwGridIndex] then
            self:ShowChangeWarning(dwGridIndex)
        end
        self.tbOtherItem[dwGridIndex] = {
            dwBoxID = dwBoxIndex,
            dwX = dwPosIndex,
        }
    end
end

function UITransactionView:UpdateSelectEffect()
    local bShow = UIHelper.GetVisible(self.WidgetRightBag)
    for i = 0, MAX_ITEM_COUNT - 1 do
        local bSelected = i == self.nCurGridIndex
        if self.tbSelfItem[i] then
            self.tbSelfItem[i].script:SetSelected(bSelected)

            --无论是否bSelected都隐藏格子选中效果
            UIHelper.SetSelected(self.BtnAddR[i + 1], false)
        else
            UIHelper.SetSelected(self.BtnAddR[i + 1], bShow and bSelected or false)
        end
    end
end

function UITransactionView:SetupItemContent(parent, item)
    local script = UIHelper.AddPrefab(PREFAB_ID.WidgetItemWithName, parent)
    local szItemName = UIHelper.GBKToUTF8(ItemData.GetItemNameByItem(item))
    local szIconPath = UIHelper.GetIconPathByItemInfo(item)
    local color = cc.c3b(GetItemFontColorByQuality(item.nQuality, false))

    script:SetLabelItemName(szItemName)
    script:SetImgIcon(szIconPath)
    script:SetTextColor(color)
    script:SetItemQualityBg(item.nQuality)

    script:SetLableCount(self:GetItemNum(item))

    return script
end

function UITransactionView:GetItemNum(item)
    if not item then return end

    if item.nGenre == ITEM_GENRE.EQUIPMENT then
        if item.nSub == EQUIPMENT_SUB.ARROW and item.nCurrentDurability > 1 then
            return item.nCurrentDurability
        else
            return 1
        end
    else
        if item.bCanStack and item.nMaxStackNum > 1 then
            return item.nStackNum
        else
            return 1
        end
    end
end

function UITransactionView:UpdateTradeOtherMoney(tMoney, bNotLockBtn)
    local bCanTradeMoney = GetClientPlayer().GetScene().bCanTradeMoney and not IsRemotePlayer(GetClientPlayer().dwID)
    UIHelper.SetVisible(self.ImgBullion01L, bCanTradeMoney)
    UIHelper.SetVisible(self.ImgBullion02L, bCanTradeMoney)
    UIHelper.SetVisible(self.ImgBullion03L, bCanTradeMoney)
    UIHelper.SetVisible(self.ImgTradeCurrency01, bCanTradeMoney)
    UIHelper.SetVisible(self.EditBox01L, bCanTradeMoney)
    UIHelper.SetVisible(self.EditBox02L, bCanTradeMoney)
    UIHelper.SetVisible(self.EditBox03L, bCanTradeMoney)

    if bCanTradeMoney then
        local nGoldB, nGold, nSilver = UnpackMoneyEx(tMoney)
        local bChanged = false

        if  UIHelper.GetString(self.EditBox01L) ~= tostring(nGoldB) or
            UIHelper.GetString(self.EditBox02L) ~= tostring(nGold) or
            UIHelper.GetString(self.EditBox03L) ~= tostring(nSilver)
        then
            bChanged = true
        end

        UIHelper.SetString(self.EditBox01L, nGoldB)
        UIHelper.SetString(self.EditBox02L, nGold)
        UIHelper.SetString(self.EditBox03L, nSilver)
        if not bNotLockBtn and bChanged then
            self:TempLockSureBtn()
        end
    end
end

function UITransactionView:UpdateTradeSelfMoney(tMoney)
    local bCanTradeMoney = GetClientPlayer().GetScene().bCanTradeMoney and not IsRemotePlayer(GetClientPlayer().dwID)
    UIHelper.SetVisible(self.ImgBullion01R, bCanTradeMoney)
    UIHelper.SetVisible(self.ImgBullion02R, bCanTradeMoney)
    UIHelper.SetVisible(self.ImgBullion03R, bCanTradeMoney)
    UIHelper.SetVisible(self.ImgTradeCurrency02, bCanTradeMoney)
    UIHelper.SetVisible(self.EditBox01R, bCanTradeMoney)
    UIHelper.SetVisible(self.EditBox02R, bCanTradeMoney)
    UIHelper.SetVisible(self.EditBox03R, bCanTradeMoney)

    if bCanTradeMoney then
        local nGoldB, nGold, nSilver = UnpackMoneyEx(tMoney)
        UIHelper.SetString(self.EditBox01R, nGoldB)
        UIHelper.SetString(self.EditBox02R, nGold)
        UIHelper.SetString(self.EditBox03R, nSilver)
    end
end

function UITransactionView:UpdateSelfState(bConfirm)
    UIHelper.SetVisible(self.ImgFrame02, bConfirm)
    self:UpdateBtnSureState(bConfirm)
end

function UITransactionView:UpdateOtherState(bConfirm)
    UIHelper.SetVisible(self.ImgFrame01, bConfirm)
end

function UITransactionView:UpdateBtnSureState(bConfirm)
    local nState = bConfirm and BTN_STATE.Disable or BTN_STATE.Normal
    UIHelper.SetButtonState(self.BtnSure, nState)
    UIHelper.SetString(self.LabelSure, "交易")
end

function UITransactionView:UpdateUnknownTipState()
    UIHelper.SetVisible(self.LabelUnknownTips, false)
    
    local hFellow = GetSocialManagerClient()
    if not hFellow then
        return
    end

    local hPlayer = GetPlayer(self.dwID)
    if not hPlayer then
        return
    end

    local szGlobalID = hPlayer.GetGlobalID()
    local tCard = hFellow.GetFellowshipCardInfo(szGlobalID)
    if not tCard then
        return
    end
    UIHelper.SetVisible(self.LabelUnknownTips, tCard.bIsTwoWayFriend == 0)
    UIHelper.LayoutDoLayout(self.LayoutTPlayer)
end

function UITransactionView:ShowChangeWarning(nGridIndex)
    UIHelper.SetVisible(self.LabelContent, true)
    UIHelper.SetVisible(self.ImgLabelChangeBg, true)

    if nGridIndex then
        local nIndex = nGridIndex + 1
        UIHelper.SetVisible(self.ImgChange[nIndex], true)

        local anim = self.MaskLight[nIndex]
        UIHelper.SetVisible(anim, true)
        --UIHelper.PlayAni(self, anim, "AniLightLoop")

        if not self.tbAniTimerIDs then
            self.tbAniTimerIDs = {}
        end

        Timer.DelTimer(self, self.tbAniTimerIDs[nIndex])
        self.tbAniTimerIDs[nIndex] = Timer.Add(self, WARNING_TIME, function()
            self.tbAniTimerIDs[nIndex] = nil
            UIHelper.SetVisible(anim, false)
        end)
    end

    self:TempLockSureBtn()
end

function UITransactionView:TempLockSureBtn()
    self:UpdateBtnSureState(true)
    Timer.DelTimer(self, self.nWarningTimerID)

    UIHelper.SetString(self.LabelSure, string.format("交易（%d）", WARNING_TIME))
    self.nWarningTimerID = Timer.AddCountDown(self, WARNING_TIME, function(nRemain)
        UIHelper.SetString(self.LabelSure, string.format("交易（%d）", nRemain))
    end, function()
        self.nWarningTimerID = nil
        self:UpdateBtnSureState(false)
    end)
end

function UITransactionView:RemoveTips()
    if TipsHelper.IsHoverTipsExist(PREFAB_ID.WidgetItemTip) then
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetItemTip)
    end
end

return UITransactionView

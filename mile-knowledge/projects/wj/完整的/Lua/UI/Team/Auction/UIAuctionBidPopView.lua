-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIAuctionBidPopView
-- Date: 2023-02-14 20:15:33
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIAuctionBidPopView = class("UIAuctionBidPopView")

function UIAuctionBidPopView:OnEnter(tLootInfo)
    if not tLootInfo then
        return
    end
    self.scriptContentBid = UIHelper.GetBindScript(self.WidgetContentBid)
    self.scriptContentSum = UIHelper.GetBindScript(self.WidgetContentSum)
    if not self.bInit then
        self:RegGlobalEvent()
        self:RegEvent(self.scriptContentBid)
        self:RegEvent(self.scriptContentSum)
        self:BindUIEvent(self.scriptContentBid)
        self:BindUIEvent(self.scriptContentSum)
        self.bInit = true
    end
    self.scriptContentBid.tLootInfo = tLootInfo
    self.scriptContentSum.tLootInfo = tLootInfo
    self.scriptContentBid.nStep = 0
    self.scriptContentSum.nStep = 0
    self.scriptContentBid.bVisible = tLootInfo.eState == AuctionState.OnAuction
    self.scriptContentSum.bVisible = tLootInfo.eState == AuctionState.CountDown
    self:SetContentVisible(self.scriptContentBid, self.scriptContentBid.bVisible)
    self:SetContentVisible(self.scriptContentSum, self.scriptContentSum.bVisible)
    self:UpdateInfo(tLootInfo)
    self:OnUpdateTime(self.scriptContentSum)
    self.nTimerID = self.nTimerID or Timer.AddCycle(self, 1, function ()
        self:OnUpdateTime(self.scriptContentSum)
    end)
end

function UIAuctionBidPopView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UIAuctionBidPopView:BindUIEvent(scriptContent)
    UIHelper.BindUIEvent(scriptContent.BtnClose, EventType.OnClick, function ()
        self:SetContentVisible(scriptContent, false)
    end)
    UIHelper.BindUIEvent(scriptContent.BtnAdd, EventType.OnClick, function ()
        scriptContent.nStep = scriptContent.nStep + 1
        self:UpdateContentInfo(scriptContent.tLootInfo, scriptContent)
    end)
    UIHelper.BindUIEvent(scriptContent.BtnReduce, EventType.OnClick, function ()
        if scriptContent.nStep <= 0 then
            return
        end
        scriptContent.nStep = scriptContent.nStep - 1
        self:UpdateContentInfo(scriptContent.tLootInfo, scriptContent)
    end)

    UIHelper.BindUIEvent(scriptContent.BtnBid, EventType.OnClick, function ()
        local teamBidMgr = GetTeamBiddingMgr()
        if not teamBidMgr then
            return
        end
        local tBidInfo = AuctionData.GetBiddingInfo(scriptContent.tLootInfo.dwDoodadID, scriptContent.tLootInfo.nItemLootIndex)
        if not tBidInfo then
            return
        end
        
        local nBrick = tonumber(UIHelper.GetText(scriptContent.EditPriceBrick)) or 0
        local nGold = tonumber(UIHelper.GetText(scriptContent.EditPriceGold)) or 0

        local nBidPrice = nBrick * 10000 + nGold
        local nCurPrice = tBidInfo.nPrice
        local bNoBidder = tBidInfo.szDestPlayerName and tBidInfo.szDestPlayerName == ""
        if bNoBidder then nCurPrice = tBidInfo.nPrice + tBidInfo.nStepPrice end
        nBidPrice = nBidPrice + nCurPrice

        local nCode = teamBidMgr.CanBidding(scriptContent.tLootInfo.dwDoodadID, scriptContent.tLootInfo.nItemLootIndex, nBidPrice)
        if nCode == TEAM_BIDDING_START_RESULT.SUCCESS then
            local nCurrentTime = GetTickCount()
            AuctionData.tBiddingTimeMap = AuctionData.tBiddingTimeMap or {}
            AuctionData.tBiddingTimeMap[scriptContent.tLootInfo.dwDoodadID] = AuctionData.tBiddingTimeMap[scriptContent.tLootInfo.dwDoodadID] or {}
            AuctionData.tBiddingTimeMap[scriptContent.tLootInfo.dwDoodadID][scriptContent.tLootInfo.nItemLootIndex] = nCurrentTime
            
            teamBidMgr.Bidding(scriptContent.tLootInfo.dwDoodadID, scriptContent.tLootInfo.nItemLootIndex, nBidPrice)
            TipsHelper.ShowNormalTip("出价成功", false)
            AuctionData.tBiddingRecordMap[scriptContent.tLootInfo.dwDoodadID] = AuctionData.tBiddingRecordMap[scriptContent.tLootInfo.dwDoodadID] or {}
            AuctionData.tBiddingRecordMap[scriptContent.tLootInfo.dwDoodadID][scriptContent.tLootInfo.nItemLootIndex] = nBidPrice
            AuctionData.SetNeedRefresh(true)
        else
            local szMsg = g_tStrings.tTeamBiddingStartError[nCode] or "出价失败"
            TipsHelper.ShowNormalTip(szMsg, false)
        end
    end)

    UIHelper.RegisterEditBoxEnded(scriptContent.EditPriceBrick, function ()
        self:RefreshMoney(scriptContent)
    end)

    UIHelper.RegisterEditBoxEnded(scriptContent.EditPriceGold, function ()
        self:RefreshMoney(scriptContent)
    end)
end

function UIAuctionBidPopView:RegEvent(scriptContent)
    Event.Reg(scriptContent, EventType.OnGameNumKeyboardOpen, function(editbox)
        if editbox == scriptContent.EditPriceBrick then
            UIHelper.SetEditBoxGameKeyboardRange(scriptContent.EditPriceBrick, 0, 9999)
        elseif editbox == scriptContent.EditPriceGold then
            UIHelper.SetEditBoxGameKeyboardRange(scriptContent.EditPriceGold, 0, 9999)
        end        
    end)

    Event.Reg(scriptContent, EventType.OnGameNumKeyboardChanged, function(editbox, num)
        if editbox == scriptContent.EditPriceBrick then
            self:RefreshMoney(scriptContent)
        elseif editbox == scriptContent.EditPriceGold then
            self:RefreshMoney(scriptContent)
        end
    end)
end

function UIAuctionBidPopView:RegGlobalEvent()
    -- Event.Reg(self, EventType.OnTouchViewBackGround, function ()
    --     UIMgr.Close(self)
    -- end)

    Event.Reg(self.scriptContentBid, EventType.OnLootInfoChanged, function (tNewLootInfo)
        if self.scriptContentBid.tLootInfo.dwDoodadID == tNewLootInfo.dwDoodadID and self.scriptContentBid.tLootInfo.nItemLootIndex == tNewLootInfo.nItemLootIndex then
            if tNewLootInfo.eState == AuctionState.OnAuction then
                self.scriptContentBid.tLootInfo = tNewLootInfo
                self.scriptContentBid.nStep = 0
                self:UpdateContentInfo(tNewLootInfo, self.scriptContentBid)
                UIHelper.SetVisible(self.scriptContentBid.Eff_PaiTuanChuJia, false)
                Timer.AddFrame(self, 1, function ()
                    UIHelper.SetVisible(self.scriptContentBid.Eff_PaiTuanChuJia, true)
                end)
            else
                self:SetContentVisible(self.scriptContentBid, false)
            end
        end
    end)

    Event.Reg(self.scriptContentSum, EventType.OnLootInfoChanged, function (tNewLootInfo)
        if self.scriptContentSum.tLootInfo.dwDoodadID == tNewLootInfo.dwDoodadID and self.scriptContentSum.tLootInfo.nItemLootIndex == tNewLootInfo.nItemLootIndex then
            if tNewLootInfo.eState == AuctionState.CountDown then
                self.scriptContentSum.tLootInfo = tNewLootInfo
                self.scriptContentSum.nStep = 0
                self:UpdateContentInfo(tNewLootInfo, self.scriptContentSum)
                UIHelper.SetVisible(self.scriptContentSum.Eff_PaiTuanChuJia, false)
                Timer.AddFrame(self, 1, function ()
                    UIHelper.SetVisible(self.scriptContentSum.Eff_PaiTuanChuJia, true)
                end)
            else
                self:SetContentVisible(self.scriptContentSum, false)
            end
        end
    end)
end

function UIAuctionBidPopView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIAuctionBidPopView:UpdateInfo(tLootInfo)
    self:UpdateContentInfo(tLootInfo, self.scriptContentBid)
    self:UpdateContentInfo(tLootInfo, self.scriptContentSum)
end

function UIAuctionBidPopView:UpdateContentInfo(tLootInfo, scriptContent)
    local item = AuctionData.GetItem(tLootInfo.dwDoodadID, tLootInfo.nItemLootIndex)
    if not item then
        return
    end
    local tBidInfo = AuctionData.GetBiddingInfo(tLootInfo.dwDoodadID, tLootInfo.nItemLootIndex)
    if not tBidInfo then
        return
    end
    scriptContent.scriptIcon = scriptContent.scriptIcon or UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, scriptContent.WidgetItem)
    scriptContent.scriptIcon:OnInitWithTabID(item.dwTabType, item.dwIndex)
    if item.bCanStack and item.nStackNum > 0 then
        scriptContent.scriptIcon:SetLabelCount(item.nStackNum)
    end
    UIHelper.SetVisible(scriptContent.scriptIcon.WidgetSelectBG, false)
    scriptContent.scriptIcon:SetClickCallback(function (nItemType, nItemIndex)
        local _, scriptItemTip = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetItemTip, scriptContent.scriptIcon._rootNode)
        scriptItemTip:SetFunctionButtons({})
        scriptItemTip:OnInitWithItemID(scriptContent.tLootInfo.dwItemID)
    end)

    local szItemName = ItemData.GetItemNameByItem(item)
    szItemName = UIHelper.GBKToUTF8(szItemName)
    local szBidderName = "暂无"
    if tBidInfo.szDestPlayerName and #tBidInfo.szDestPlayerName > 0 then
        szBidderName = UIHelper.GBKToUTF8(tBidInfo.szDestPlayerName)
    end
    local szPrevBidderName = "暂无"
    local bHasHistoryPrice = tBidInfo.szPrePlayerName and #tBidInfo.szPrePlayerName > 0
    if bHasHistoryPrice then
        szPrevBidderName = UIHelper.GBKToUTF8(tBidInfo.szPrePlayerName)
    end
    
    UIHelper.SetTextColor(scriptContent.LabelCurrentOfferingPlayer, cc.c3b(0xD7, 0xF6, 0xFF))
    if tBidInfo.dwDestPlayerID == UI_GetClientPlayerID() then
        szBidderName = szBidderName.."(我)"
        UIHelper.SetTextColor(scriptContent.LabelCurrentOfferingPlayer, cc.c3b(0xFF, 0xE2, 0x6E))
    end
    local nCurPrice = tBidInfo.nPrice
    local bNoBidder = tBidInfo.szDestPlayerName and tBidInfo.szDestPlayerName == ""
    if bNoBidder then nCurPrice = tBidInfo.nPrice + tBidInfo.nStepPrice end
    scriptContent.nCurPrice = nCurPrice

    local szCurBrick = tostring(math.floor(nCurPrice/10000))
    local szCurGold = tostring(math.floor(nCurPrice%10000))
    local nBidPrice = scriptContent.nStep * tBidInfo.nStepPrice
    local szBidBrick = tostring(math.floor(nBidPrice/10000))
    local szBidGold = tostring(math.floor(nBidPrice%10000))
    local szPreBrick = tostring(math.floor(tBidInfo.nPrePrice/10000))
    local szPreGold = tostring(math.floor(tBidInfo.nPrePrice%10000))

    UIHelper.SetString(scriptContent.LabelItemName, szItemName)
    UIHelper.SetString(scriptContent.LabelCurrentOfferingPlayer, szBidderName)
    UIHelper.SetString(scriptContent.LabelPrevPlayerName, szPrevBidderName)
    UIHelper.SetString(scriptContent.LabelCurMoney_Zhuan, szCurBrick)
    UIHelper.SetString(scriptContent.LabelCurMoney_Jin, szCurGold)
    UIHelper.SetString(scriptContent.LabelPrevMoney_Zhuan, szPreBrick)
    UIHelper.SetString(scriptContent.LabelPrevMoney_Jin, szPreGold)
    UIHelper.SetText(scriptContent.EditPriceBrick, szBidBrick)
    UIHelper.SetText(scriptContent.EditPriceGold, szBidGold)
    
    UIHelper.SetVisible(scriptContent.LabelHistoryPrice, bHasHistoryPrice)
    UIHelper.SetVisible(scriptContent.WidgetHistoryMoney_Jin, bHasHistoryPrice)
    UIHelper.SetVisible(scriptContent.WidgetHistoryMoney_Zhuan, bHasHistoryPrice)
    UIHelper.LayoutDoLayout(scriptContent.LayoutBtns)
    UIHelper.LayoutDoLayout(scriptContent.LayoutHistoryCurrency)
    if scriptContent.nStep == 0 and not bNoBidder then
        UIHelper.SetButtonState(scriptContent.BtnBid, BTN_STATE.Disable, "请先设置新价")
    else
        UIHelper.SetButtonState(scriptContent.BtnBid, BTN_STATE.Normal)
    end

    if tLootInfo.eState == AuctionState.CountDown then
        UIHelper.SetVisible(scriptContent.Eff_ItemIcon, true)
        UIHelper.SetVisible(scriptContent.Eff_ItemName, true)
    end

    UIHelper.CascadeDoLayoutDoWidget(scriptContent.LayoutMainContent, true, true)

    self:RefreshMoney(scriptContent)
end

function UIAuctionBidPopView:RefreshMoney(scriptContent)
    local tLootInfo = scriptContent.tLootInfo
    local tBidInfo = AuctionData.GetBiddingInfo(tLootInfo.dwDoodadID, tLootInfo.nItemLootIndex)
    if not tBidInfo then
        return
    end
    local nCurPrice = tBidInfo.nPrice
    local bNoBidder = tBidInfo.szDestPlayerName and tBidInfo.szDestPlayerName == ""
    if bNoBidder then nCurPrice = tBidInfo.nPrice + tBidInfo.nStepPrice end

    local nBrick = tonumber(UIHelper.GetText(scriptContent.EditPriceBrick)) or 0
    local nGold = tonumber(UIHelper.GetText(scriptContent.EditPriceGold)) or 0
    local nPrice = nBrick * 10000 + nGold
    nCurPrice = nCurPrice + nPrice

    local nStep = math.floor(nPrice / tBidInfo.nStepPrice)
    if nStep < 0 then
        nStep = 0
    end
    scriptContent.nStep = nStep

    UIHelper.SetString(scriptContent.LabelFinalMoney_Zhuan, tostring(math.floor(nCurPrice/10000)))
    UIHelper.SetString(scriptContent.LabelFinalMoney_Jin, tostring(math.floor(nCurPrice%10000)))
    UIHelper.CascadeDoLayoutDoWidget(scriptContent.LayoutFinalCurrency, true, true)

    UIHelper.SetButtonState(scriptContent.BtnBid, BTN_STATE.Normal)
    if nCurPrice < tBidInfo.nPrice + tBidInfo.nStepPrice then
        UIHelper.SetButtonState(scriptContent.BtnBid, BTN_STATE.Disable, "金价过低")
    end
end

function UIAuctionBidPopView:OnUpdateTime(scriptContent)
    local tLootInfo = scriptContent.tLootInfo
    UIHelper.SetVisible(scriptContent.LabelCountDown, tLootInfo.eState == AuctionState.CountDown)
    if tLootInfo.eState ~= AuctionState.CountDown then return end
    local tBidInfo = AuctionData.GetBiddingInfo(tLootInfo.dwDoodadID, tLootInfo.nItemLootIndex)
    if not tBidInfo then return end

    local nLeftTime = tBidInfo.nStartTime - GetGSCurrentTime()
    UIHelper.SetString(scriptContent.LabelCountDown, string.format("倒计时：%d秒", nLeftTime))
end

function UIAuctionBidPopView:SetContentVisible(scriptContent, bVisible)
    scriptContent.bVisible = bVisible
    UIHelper.SetVisible(scriptContent._rootNode, scriptContent.bVisible)
    UIHelper.LayoutDoLayout(self.WidgetAnchorContentNew)
    if not self.scriptContentBid.bVisible and not self.scriptContentSum.bVisible then
        UIMgr.Close(self)
    end
end

function UIAuctionBidPopView:OnLootItemCountDown(tNewLootInfo)
    self.scriptContentSum.tLootInfo = tNewLootInfo
    self.scriptContentSum.bVisible = tNewLootInfo.eState == AuctionState.CountDown
    self:SetContentVisible(self.scriptContentSum, self.scriptContentSum.bVisible)
    UIHelper.CascadeDoLayoutDoWidget(self._rootNode)
end

return UIAuctionBidPopView
local UIWidgetAuctionItem = class("UIWidgetAuctionItem")


function UIWidgetAuctionItem:OnEnter(tRollInfo)
    if not tRollInfo or type(tRollInfo) == "number" then return end
    
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tLootInfo = tRollInfo.tLootInfo
    self.fCallBack = tRollInfo.fCallBack
    self:UpdateInfo(tRollInfo.tLootInfo)
end

function UIWidgetAuctionItem:OnExit()
    self.bInit = false
    Timer.DelAllTimer(self)
end

function UIWidgetAuctionItem:BindUIEvent()
    UIHelper.BindUIEvent(self.ToggleSelect, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected then
            AuctionData.bChoosedOnAuction = self.tLootInfo.eState == AuctionState.OnAuction
            self.fCallBack(false, self.tLootInfo)
        end
    end)
end

function UIWidgetAuctionItem:RegEvent()
    Event.Reg(self, EventType.OnLootInfoChanged, function (tNewLootInfo)
        if self.tLootInfo.dwDoodadID == tNewLootInfo.dwDoodadID and self.tLootInfo.nItemLootIndex == tNewLootInfo.nItemLootIndex then
            self.tLootInfo = tNewLootInfo
            self:UpdateInfo(tNewLootInfo)
        end
    end)
end

function UIWidgetAuctionItem:UpdateInfo(tLootInfo)
    if tLootInfo.dwItemID == 0 then
        self:UpdateMoneyInfo(tLootInfo)
        return
    end
    local player = GetClientPlayer()
    if not player then
        return
    end

    local itemInfo = GetItemInfo(tLootInfo.dwItemTabType, tLootInfo.dwItemIndex)
	if not itemInfo then
		return
	end
    local tDoodadInfo = AuctionData.tPickedDoodads[tLootInfo.dwDoodadID]
    if not tDoodadInfo then
        return
    end

    local bWaitAuction = tLootInfo.eState == AuctionState.WaitAuction and tDoodadInfo.nLootMode == PARTY_LOOT_MODE.BIDDING

    local szName = ItemData.GetItemNameByItemInfo(itemInfo, tLootInfo.nBookID)
    szName = UIHelper.GBKToUTF8(szName)

    local MAX_NAME_LENGTH = 5
    local nCharCount, szNewName = GetStringCharCountAndTopChars(szName, MAX_NAME_LENGTH)
    if nCharCount > MAX_NAME_LENGTH and not bWaitAuction then szName = szNewName.."..." end

    local nDiamondR, nDiamondG, nDiamondB = GetItemFontColorByQuality(itemInfo.nQuality)
    szName = GetFormatText(szName, nil, nDiamondR, nDiamondG, nDiamondB)
    UIHelper.SetRichText(self.RichTextItemName, szName)
    UIHelper.SetVisible(self.Eff_OrangeNew, itemInfo.nQuality >= 5)

    local szImagePath = UIHelper.GetIconPathByItemInfo(itemInfo)
    local bMatchMonsterBook = MonsterBookData.TABLE_OUT_SKILL_BOOK[tLootInfo.dwItemIndex] ~= nil
    UIHelper.SetTexture(self.ImgItemIcon, szImagePath)
    UIHelper.SetSpriteFrame(self.ImgPolishCountBG, ItemQualityBGColor[itemInfo.nQuality + 1])
    
    local bIsEquipment = itemInfo.nGenre == ITEM_GENRE.EQUIPMENT
    local bMatchForce = false
    local dwMatchKungfuID = 0
    local bHasOwn = false
    if bIsEquipment then
        local dwMainKungfuID = player.GetActualKungfuMountID()
        bMatchForce, dwMatchKungfuID = PlayerData.CheckMatchKungfus(tLootInfo.tKungfuMap)
        if bMatchForce then
            if TabHelper.IsHDKungfuID(dwMatchKungfuID) then dwMatchKungfuID = TabHelper.GetMobileKungfuID(dwMatchKungfuID) or 0 end
              
            local szSkillName = Table_GetSkillName(dwMatchKungfuID, 1)
            szSkillName = UIHelper.GBKToUTF8(szSkillName)
            local szMatchKungfu = string.format(g_tStrings.Auction.MATCH_KUNGFU_TAG, szSkillName)
            UIHelper.SetString(self.LabelXinFa, szMatchKungfu)
        end
        local nItemAmount = player.GetItemAmountInAllPackages()
        bHasOwn = nItemAmount > 0
    elseif bMatchMonsterBook then
        local tSkillLevel = g_pClientPlayer.GetAllSkillInCollection()
        local dwSkillID = MonsterBookData.TABLE_OUT_SKILL_BOOK[tLootInfo.dwItemIndex][1]
        local nLevel = tSkillLevel[dwSkillID]
        if nLevel and nLevel > 0 then
            UIHelper.SetString(self.LabelXinFa, string.format("已收集：%s重", g_tStrings.tChineseNumber[nLevel]))
        else
            UIHelper.SetString(self.LabelXinFa, "未收集")
        end
    end

    -- 拍卖状态
    local szPlayerName = "佚名"
    local tBidInfo = AuctionData.GetBiddingInfo(tLootInfo.dwDoodadID, tLootInfo.nItemLootIndex)
    local clientTeam = GetClientTeam()
    local dwDistributerID = clientTeam.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.DISTRIBUTE)
    local bDistributer = dwDistributerID == player.dwID
    local tbConfig = AuctionStateConfig[tLootInfo.eState]
    local bBidder = false    
    local bWaitPay = tLootInfo.eState == AuctionState.WaitPay
    local bOnAuction = tLootInfo.eState == AuctionState.OnAuction
    if tBidInfo and tBidInfo.szDestPlayerName then
        bBidder = tBidInfo.dwDestPlayerID == UI_GetClientPlayerID()
        if bBidder then
            szPlayerName = "我"
        else
            szPlayerName = UIHelper.GBKToUTF8(tBidInfo.szDestPlayerName)
        end        
    end

    if tbConfig then
        UIHelper.SetString(self.LabelStateName, tbConfig.szDesc)
        if tBidInfo and (not tBidInfo.dwDestPlayerID or tBidInfo.dwDestPlayerID <= 0) then
            UIHelper.SetString(self.LabelStateName, "起拍价")
        end
        local nCharCount, szNewName = GetStringCharCountAndTopChars(szPlayerName, MAX_NAME_LENGTH)
        if nCharCount > MAX_NAME_LENGTH then szPlayerName = szNewName.."..." end

        UIHelper.SetString(self.LabelPlayerName, szPlayerName)
        UIHelper.SetVisible(self.LabelPlayerName, not bWaitAuction and not bBidder)
        UIHelper.SetVisible(self.LabelMe, not bWaitAuction and bBidder)        
        UIHelper.LayoutDoLayout(self.LayoutState)
    end
    local bShowCurrency, nPrice = self:GetCurrencyPrice(tLootInfo)
    if bShowCurrency then
        local nBrick = math.floor(nPrice / 10000)
        local nGold = nPrice - nBrick * 10000
        UIHelper.SetString(self.LabelMoney_Zhuan, tostring(nBrick))
        UIHelper.SetString(self.LabelMoney_Jin, tostring(nGold))        
    end
    UIHelper.SetVisible(self.WidgetSuitableXinFa, (bIsEquipment and bMatchForce and not bHasOwn) or bMatchMonsterBook)
    UIHelper.SetVisible(self.WidgetOwned, bHasOwn)
    UIHelper.SetToggleGroupIndex(self.ToggleSelect, ToggleGroupIndex.AuctionDropAuctionItemList)

    UIHelper.SetVisible(self.LayoutState, tLootInfo.bNeedBidding and not bWaitAuction and not tLootInfo.bHasDistributed)
    UIHelper.SetVisible(self.WidgetFreeLoot, tLootInfo.bCanFreeLoot)
    
    UIHelper.CascadeDoLayoutDoWidget(self.LayoutCurrency, true, true)
    UIHelper.SetVisible(self.LayoutCurrency, bShowCurrency and tLootInfo.bNeedBidding)

    UIHelper.SetVisible(self.WidgetStateBeforeAuction, bWaitAuction and not tLootInfo.bCanFreeLoot)
    UIHelper.SetVisible(self.WidgetStateLockPrice,  bWaitPay and not bBidder and not tLootInfo.bCanFreeLoot)
    UIHelper.SetVisible(self.WidgetStateToBePaid,   bWaitPay and bBidder and not tLootInfo.bCanFreeLoot)
    UIHelper.SetVisible(self.WidgetStateOnAuction,  bOnAuction and not tLootInfo.bCanFreeLoot)
    UIHelper.SetVisible(self.WidgetStateSold, tLootInfo.bHasDistributed)
    UIHelper.SetVisible(self.ImgBlackMask, tLootInfo.bHasDistributed)
    
    UIHelper.SetSwallowTouches(self.ToggleSelect, false)
end

function UIWidgetAuctionItem:UpdateMoneyInfo(tLootInfo)
    local player = GetClientPlayer()
    if not player then
        return
    end

    local tDoodadInfo = AuctionData.tPickedDoodads[tLootInfo.dwDoodadID]
    if not tDoodadInfo then
        return
    end
    local szName = CurrencyType.Money
    UIHelper.SetRichText(self.RichTextItemName, szName)  

    local nPrice = tLootInfo.nMoney or 0
    local nBrick = math.floor(nPrice / 10000 / 10000)
    nPrice = nPrice - nBrick * 10000 * 10000
    local nGold = math.floor(nPrice / 10000)
    nPrice = nPrice - nGold * 10000
    local nSilver = math.floor(nPrice / 100)
    local nCopper = nPrice - nSilver * 100

    UIHelper.SetString(self.LabelMoney_Zhuan, tostring(nBrick))
    UIHelper.SetString(self.LabelMoney_Jin, tostring(nGold))
    UIHelper.SetString(self.LabelMoney_Yin, tostring(nSilver))
    UIHelper.SetString(self.LabelMoney_Tong, tostring(nCopper))

    UIHelper.SetVisible(self.WidgetMoney_Zhuan, nBrick > 0)
    UIHelper.SetVisible(self.WidgetMoney_Jin, nGold > 0)
    UIHelper.SetVisible(self.WidgetMoney_Yin, nSilver > 0)
    UIHelper.SetVisible(self.WidgetMoney_Tong, nCopper > 0)

    UIHelper.SetMoneyIcon(self.ImgItemIcon, tLootInfo.nMoney)
    UIHelper.SetSpriteFrame(self.ImgPolishCountBG, ItemQualityBGColor[6])
    UIHelper.SetVisible(self.Eff_OrangeNew, false)
    UIHelper.LayoutDoLayout(UIHelper.GetParent(self.WidgetMoney_Zhuan))

    UIHelper.SetVisible(self.LabelPlayerName, false)
    UIHelper.SetVisible(self.LabelMe, false)
    UIHelper.SetVisible(self.WidgetSuitableXinFa, false)
    UIHelper.SetVisible(self.WidgetOwned, false)
    UIHelper.SetToggleGroupIndex(self.ToggleSelect, ToggleGroupIndex.AuctionDropAuctionItemList)

    UIHelper.SetVisible(self.LayoutState, false)
    UIHelper.SetVisible(self.WidgetFreeLoot, tLootInfo.bCanFreeLoot)
    
    UIHelper.CascadeDoLayoutDoWidget(self.LayoutCurrency, true, true)
    UIHelper.SetVisible(self.LayoutCurrency, true)

    UIHelper.SetVisible(self.WidgetStateBeforeAuction, false)
    UIHelper.SetVisible(self.WidgetStateLockPrice,  false)
    UIHelper.SetVisible(self.WidgetStateToBePaid,   false)
    UIHelper.SetVisible(self.WidgetStateOnAuction,  false)    
    UIHelper.SetSwallowTouches(self.ToggleSelect, false)
end

function UIWidgetAuctionItem:SetClickCallback(fCallBack)
    self.fCallBack = fCallBack
end

function UIWidgetAuctionItem:GetCurrencyPrice(tLootInfo)
    local tBidInfo = AuctionData.GetBiddingInfo(tLootInfo.dwDoodadID, tLootInfo.nItemLootIndex)
    local bShowCurrency = tBidInfo and tBidInfo.nPrice and tLootInfo.eState ~= AuctionState.WaitAuction
    local nPrice = -1
    local nPaidMoney = 0
    if tBidInfo then
        local nCurPrice = tBidInfo.nPrice
        if tBidInfo.szDestPlayerName and tBidInfo.szDestPlayerName == "" then nCurPrice = tBidInfo.nPrice + tBidInfo.nStepPrice end
        if tBidInfo.nPaidMoney then nPaidMoney = tBidInfo.nPaidMoney end

        nPrice = nCurPrice - nPaidMoney
    end

    return bShowCurrency, nPrice
end

function UIWidgetAuctionItem:SetEmptyState(bShowEmpty)
    UIHelper.SetVisible(self.WidgetItemEmpty, bShowEmpty)
    UIHelper.SetVisible(self.WidgetItemShell, not bShowEmpty)
end

return UIWidgetAuctionItem
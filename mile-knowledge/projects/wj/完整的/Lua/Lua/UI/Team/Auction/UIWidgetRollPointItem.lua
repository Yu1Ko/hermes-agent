local UIWidgetRollPointItem = class("UIWidgetRollPointItem")


function UIWidgetRollPointItem:OnEnter(tRollInfo)
    if not tRollInfo or type(tRollInfo) == "number" then return end
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tLootInfo = tRollInfo.tLootInfo
    self.fCallBack = tRollInfo.fCallBack
    self.scriptLootList = UIMgr.GetViewScript(VIEW_ID.PanelTeamAuction)

    self:UpdateInfo(tRollInfo.tLootInfo)
    self:RefreshLeftTime()
    self:OnUpdateTime()
end

function UIWidgetRollPointItem:OnExit()
    self.bInit = false
    Timer.DelAllTimer(self)
end

function UIWidgetRollPointItem:BindUIEvent()
    UIHelper.BindUIEvent(self.ToggleSelect, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected then
            AuctionData.bChoosedOnAuction = self.tLootInfo.eState == AuctionState.OnAuction
            self.fCallBack(false, self.tLootInfo)
        end
    end)

    UIHelper.BindUIEvent(self.BtnNeed, EventType.OnClick, function ()
        self.scriptLootList:TryRollItem(self.tLootInfo, ROLL_ITEM_CHOICE.NEED)
        UIHelper.SetVisible(self.scriptLootList.scriptItemtip._rootNode, false)
    end)

    UIHelper.BindUIEvent(self.BtnGreed, EventType.OnClick, function ()
        self.scriptLootList:TryRollItem(self.tLootInfo, ROLL_ITEM_CHOICE.GREED)
        UIHelper.SetVisible(self.scriptLootList.scriptItemtip._rootNode, false)
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function ()
        self.scriptLootList:TryRollItem(self.tLootInfo, ROLL_ITEM_CHOICE.CANCEL)
        UIHelper.SetVisible(self.scriptLootList.scriptItemtip._rootNode, false)
    end)

    UIHelper.BindUIEvent(self.WidgetItem, EventType.OnClick, function ()
        if self.tLootInfo.bCanFreeLoot then
            self.fCallBack(true, self.tLootInfo)
        end
    end)
end

function UIWidgetRollPointItem:RegEvent()
    Event.Reg(self, EventType.OnLootInfoChanged, function (tNewLootInfo)
        if self.tLootInfo.dwDoodadID == tNewLootInfo.dwDoodadID and self.tLootInfo.nItemLootIndex == tNewLootInfo.nItemLootIndex and self.tLootInfo.dwItemID == tNewLootInfo.dwItemID then
            self.tLootInfo = tNewLootInfo
            self:UpdateInfo(tNewLootInfo)
            self:OnUpdateTime()
        end
    end)

    Event.Reg(self, EventType.OnAuctionLootListRedPointChanged, function ()
        local tLootInfo = self.tLootInfo
        self.bHasRedPoint = RedpointHelper.AuctionLootList_HasRedPoint(tLootInfo.dwDoodadID, tLootInfo.nItemLootIndex)
        UIHelper.SetVisible(self.WidgetPriceTakenOver, self.bHasRedPoint)
    end)

    Event.Reg(self, EventType.OnUpdateCustomizedSetList, function ()
        self:UpdateInfo(self.tLootInfo)
        self:OnUpdateTime()
    end)
end

function UIWidgetRollPointItem:OnUpdateTime()
    if not self.tLootInfo then return end

    self:RefreshCountDown()

    if self.tLootInfo.bSendFinishMsg then return end
    self:RefreshLeftTime()
    if self.tLootInfo.bIsFinished then
        if not self.tLootInfo.bSendFinishMsg then
            self.tLootInfo.bSendFinishMsg = true
            Event.Dispatch(EventType.OnRollItemTimeOut, self.tLootInfo)
        end
    end
end

function UIWidgetRollPointItem:UpdateInfo(tLootInfo)
    UIHelper.SetVisible(self.WidgetRecommendState, false)

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

    local szName = ItemData.GetItemNameByItemInfo(itemInfo, tLootInfo.nBookID)
    szName = UIHelper.GBKToUTF8(szName)
    local MAX_NAME_LENGTH = 15
    local bRecommend, szRecommendTitle = EquipCodeData.CheckIsRoleRecommendEquip(tLootInfo.dwItemTabType, tLootInfo.dwItemIndex)
    if bRecommend then MAX_NAME_LENGTH = 11 end
    UIHelper.SetVisible(self.WidgetRecommendState, bRecommend)
    UIHelper.SetString(self.LabelRecommendTitle, szRecommendTitle)
    UIHelper.LayoutDoLayout(self.WidgetRecommendState)

    local nCharCount, szNewName = GetStringCharCountAndTopChars(szName, MAX_NAME_LENGTH)
    if nCharCount > MAX_NAME_LENGTH then szName = szNewName.."..." end

    local nDiamondR, nDiamondG, nDiamondB = GetItemFontColorByQuality(itemInfo.nQuality)
    szName = GetFormatText(szName, nil, nDiamondR, nDiamondG, nDiamondB)
    UIHelper.SetRichText(self.RichTextItemName, szName)
    UIHelper.SetVisible(self.Eff_OrangeNew, itemInfo.nQuality >= 5)

    local szImagePath = UIHelper.GetIconPathByItemInfo(itemInfo)
    UIHelper.SetTexture(self.ImgItemIcon, szImagePath)
    UIHelper.SetSpriteFrame(self.ImgPolishCountBG, ItemQualityBGColor[itemInfo.nQuality + 1])

    local nCount = 1
    local item = AuctionData.GetItem(tLootInfo.dwDoodadID, tLootInfo.nItemLootIndex)
    if item then
        nCount = ItemData.GetItemStackNum(item)
    end
    UIHelper.SetString(self.LabelCount, tostring(nCount))
    UIHelper.SetVisible(self.LabelCount, nCount > 1)

    local bIsEquipment = itemInfo.nGenre == ITEM_GENRE.EQUIPMENT
    local bMatchForce = false
    local dwMatchKungfuID = 0
    local bHasOwn = false
    local bHasAbstain = tLootInfo.nChoice ~= nil
    local bMatchMonsterBook = MonsterBookData.TABLE_OUT_SKILL_BOOK[tLootInfo.dwItemIndex] ~= nil

    local nItemAmount = player.GetItemAmountInAllPackages(tLootInfo.dwItemTabType, tLootInfo.dwItemIndex)
    bHasOwn = nItemAmount > 0
    local bItemUsed = self:IsItemUsed(tLootInfo.dwItemTabType, tLootInfo.dwItemIndex, item)

    UIHelper.SetString(self.LabelOwnedNum, tostring(nItemAmount))
    UIHelper.LayoutDoLayout(self.WidgetPossess)

    if bItemUsed then
        UIHelper.SetString(self.LabelOwned, "已附魔")
    else
        UIHelper.SetString(self.LabelOwned, "已拥有")
    end

    local bCollectedMonsterBook = false
    if bIsEquipment then
        bMatchForce, dwMatchKungfuID = PlayerData.CheckMatchKungfus(tLootInfo.tKungfuMap)
        if bMatchForce then
            if TabHelper.IsHDKungfuID(dwMatchKungfuID) then dwMatchKungfuID = TabHelper.GetMobileKungfuID(dwMatchKungfuID) or 0 end

            local szSkillName = Table_GetSkillName(dwMatchKungfuID, 1)
            szSkillName = UIHelper.GBKToUTF8(szSkillName)
            local szMatchKungfu = string.format(g_tStrings.Auction.MATCH_KUNGFU_TAG, szSkillName)
            UIHelper.SetString(self.LabelXinFa, szMatchKungfu)
        end
    elseif bMatchMonsterBook then
        local tSkillLevel = g_pClientPlayer.GetAllSkillInCollection()
        local dwSkillID = MonsterBookData.TABLE_OUT_SKILL_BOOK[tLootInfo.dwItemIndex][1]
        local nLevel = tSkillLevel[dwSkillID]
        bCollectedMonsterBook = nLevel and nLevel > 0
        if bCollectedMonsterBook then
            UIHelper.SetString(self.LabelXinFa, string.format("已收集：%s重", g_tStrings.tChineseNumber[nLevel]))
        else
            UIHelper.SetString(self.LabelXinFa, "未收集")
        end
    end

    local szType1, szType2, szType3 = ItemData.GetItemTypeInfo(itemInfo, false, nil, tLootInfo.nBookID)
    local szEquipmentType = szType1
    if szType2 and #szType2 > 0 then szEquipmentType = szType2 end
    UIHelper.SetString(self.LabelEquipmentType1, szEquipmentType)
    UIHelper.SetString(self.LabelEquipmentType2, szEquipmentType)

    -- 拍卖状态
    local szPlayerName = "佚名"
    local tBidInfo = AuctionData.GetBiddingInfo(tLootInfo.dwDoodadID, tLootInfo.nItemLootIndex)
    local clientTeam = GetClientTeam()
    local dwDistributerID = clientTeam.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.DISTRIBUTE)
    local bDistributer = dwDistributerID == player.dwID
    local tbConfig = AuctionStateConfig[tLootInfo.eState]
    local bBidder = false
    local bWaitAuction = tLootInfo.eState == AuctionState.WaitAuction and tDoodadInfo.nLootMode == PARTY_LOOT_MODE.BIDDING
    local bWaitPay = tLootInfo.eState == AuctionState.WaitPay
    local bOnAuction = tLootInfo.eState == AuctionState.OnAuction
    local bCountDown = tLootInfo.eState == AuctionState.CountDown
    local bCountFinished = tLootInfo.eState == AuctionState.CountFinished
    if tBidInfo then
        bBidder = tBidInfo.dwDestPlayerID == UI_GetClientPlayerID()
        if tBidInfo.szDestPlayerName then
            if bBidder then
                szPlayerName = "我"
            else
                szPlayerName = UIHelper.GBKToUTF8(tBidInfo.szDestPlayerName)
            end
        end
        UIHelper.SetString(self.LabelNeededNum, string.format("+%d", tBidInfo.nBiddingNum))
    end

    if tbConfig then
        local szStateName = tbConfig.szDesc
        if tBidInfo and (not tBidInfo.dwDestPlayerID or tBidInfo.dwDestPlayerID <= 0) then
            szStateName = "起拍价"
        end
        local nCharCount, szNewName = GetStringCharCountAndTopChars(szPlayerName, MAX_NAME_LENGTH)
        if nCharCount > MAX_NAME_LENGTH then szPlayerName = szNewName.."..." end

        if not bWaitAuction and bBidder then
            szStateName = szStateName .. "<color=#FFe26e>我</color>"
        else
            szStateName = szStateName .. szPlayerName
        end
        UIHelper.SetRichText(self.RichTextState, szStateName)
    end
    local bShowCurrency, nPrice = self:GetCurrencyPrice(tLootInfo)
    if bShowCurrency then
        local nBrick = math.floor(nPrice / 10000)
        local nGold = nPrice - nBrick * 10000
        UIHelper.SetString(self.LabelMoney_Zhuan, tostring(nBrick))
        UIHelper.SetString(self.LabelMoney_Jin, tostring(nGold))
    end

    local bShowCollectMonsterBook = (bMatchMonsterBook and (bCollectedMonsterBook or not bHasOwn))
    UIHelper.SetVisible(self.WidgetSuitableXinFa, (bIsEquipment and bMatchForce and not bHasOwn) or bShowCollectMonsterBook)
    UIHelper.SetVisible(self.WidgetOwned, (bHasOwn and bIsEquipment) or bItemUsed)
    UIHelper.SetVisible(self.WidgetPossess, bHasOwn and not bIsEquipment and not bShowCollectMonsterBook and not bItemUsed)
    UIHelper.SetToggleGroupIndex(self.ToggleSelect, ToggleGroupIndex.AuctionDropAuctionItemList)

    UIHelper.SetVisible(self.LayoutNameState, tLootInfo.bNeedBidding and not bWaitAuction and not tLootInfo.bHasDistributed)

    UIHelper.CascadeDoLayoutDoWidget(self.LayoutCurrency, true, true)
    UIHelper.SetVisible(self.LayoutCurrency, bShowCurrency and tLootInfo.bNeedBidding)

    UIHelper.SetVisible(self.WidgetStateBeforeAuction, bWaitAuction and not tLootInfo.bCanFreeLoot)
    UIHelper.SetVisible(self.WidgetStateLockPrice,  bWaitPay and not bBidder and not tLootInfo.bCanFreeLoot)
    UIHelper.SetVisible(self.WidgetStateToBePaid,   bWaitPay and bBidder and not tLootInfo.bCanFreeLoot)
    UIHelper.SetVisible(self.WidgetStateOnAuction,  bOnAuction and not tLootInfo.bCanFreeLoot)
    UIHelper.SetVisible(self.WidgetStateSold, tLootInfo.bHasDistributed)
    UIHelper.SetVisible(self.WidgetSummingUp, bCountDown)
    UIHelper.SetVisible(self.WidgetSummedUp, bCountFinished)
    UIHelper.SetVisible(self.ImgBlackMask, tLootInfo.bHasDistributed)
    UIHelper.SetVisible(self.WidgetCanFreeLoot, tLootInfo.bCanFreeLoot)
    UIHelper.SetVisible(self.WidgetNeeded, tLootInfo.eState == AuctionState.OnAuction)
    UIHelper.SetVisible(self.LabelNeededNum, tBidInfo and tBidInfo.nBiddingNum > 0)
    UIHelper.SetVisible(self.ImgHeart, tBidInfo and tBidInfo.nBiddingNum > 0)

    self.bHasRedPoint = RedpointHelper.AuctionLootList_HasRedPoint(tLootInfo.dwDoodadID, tLootInfo.nItemLootIndex)
    UIHelper.SetVisible(self.WidgetPriceTakenOver, self.bHasRedPoint)

    self:RefreshButtons()
    if tLootInfo.bCanFreeLoot then
        UIHelper.SetString(self.LabelCanFreeLoot, "自由拾取")
    end
    UIHelper.SetToggleGroupIndex(self.ToggleSelect, ToggleGroupIndex.AuctionDropRollItemList)

    UIHelper.SetSwallowTouches(self.ToggleSelect, false)

    -- 是否推荐装备
    local bRecommend, szRecommendTitle = EquipCodeData.CheckIsRoleRecommendEquip(tLootInfo.dwItemTabType, tLootInfo.dwItemIndex)
    UIHelper.SetVisible(self.WidgetRecommendState, bRecommend)
    UIHelper.SetString(self.LabelRecommendTitle, szRecommendTitle)
    UIHelper.LayoutDoLayout(self.WidgetRecommendState)
end

function UIWidgetRollPointItem:UpdateMoneyInfo(tLootInfo)
    local player = GetClientPlayer()
    if not player then
        return
    end

    local szName = CurrencyType.Money
    UIHelper.SetRichText(self.RichTextItemName, szName)

    local nPrice = tLootInfo.nMoney or 0
    if nPrice > 0 then
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
    end

    UIHelper.SetSpriteFrame(self.ImgPolishCountBG, ItemQualityBGColor[6])
    UIHelper.SetVisible(self.Eff_OrangeNew, false)
    UIHelper.LayoutDoLayout(UIHelper.GetParent(self.WidgetMoney_Zhuan))

    UIHelper.SetVisible(self.WidgetSuitableXinFa, false)
    UIHelper.SetVisible(self.WidgetOwned, false)
    UIHelper.SetVisible(self.WidgetPossess, false)
    UIHelper.SetVisible(self.WidgetCanFreeLoot, tLootInfo.bCanFreeLoot)
    UIHelper.SetVisible(self.LayoutCurrency, true)
    UIHelper.SetVisible(self.LabelCount, false)

    UIHelper.HideAllChildren(UIHelper.GetParent(self.WidgetSummedUp))
    UIHelper.HideAllChildren(self.LayoutBottomBtns)

    UIHelper.SetVisible(self.WidgetStateSold, tLootInfo.bHasDistributed)
    UIHelper.SetVisible(self.ImgBlackMask, tLootInfo.bHasDistributed)

    UIHelper.SetRichText(self.RichTextState, "")

    if tLootInfo.bCanFreeLoot then
        UIHelper.SetString(self.LabelCanFreeLoot, "自由拾取")
    end
    UIHelper.SetToggleGroupIndex(self.ToggleSelect, ToggleGroupIndex.AuctionDropRollItemList)

    UIHelper.SetSwallowTouches(self.ToggleSelect, false)
end

function UIWidgetRollPointItem:RefreshLeftTime()
    local tLootInfo = self.tLootInfo
    local nCurLeftFrame = tLootInfo.nLeftFrame - (GetLogicFrameCount() - tLootInfo.dwStartFrame)
    local nLeftTime = nCurLeftFrame / GLOBAL.GAME_FPS

    if nLeftTime < 0 or self.tLootInfo.bHasDistributed then
        tLootInfo.nLeftFrame = 0
        nLeftTime = 0
        self.tLootInfo.bIsFinished = true
    end
    UIHelper.SetVisible(self.LabelPick, nLeftTime > 0)
    UIHelper.SetVisible(self.LabelPickCountDown, nLeftTime > 0)

    nLeftTime = math.ceil(nLeftTime)
    local szLeftTime = tostring(nLeftTime) .. g_tStrings.STR_TIME_SECOND
    if tLootInfo.szRollPoint ~= nil then szLeftTime = szLeftTime.."(等待结果)" end
    UIHelper.SetString(self.LabelPickCountDown, szLeftTime)

    local nProgress = nCurLeftFrame / tLootInfo.nRollFrame*100
    UIHelper.SetProgressBarPercent(self.WidgetCountDown, nProgress)

    UIHelper.SetVisible(self.LayoutPoint, tLootInfo.szRollPoint ~= nil)
    UIHelper.SetString(self.LabelPointNum, tLootInfo.szRollPoint)
    UIHelper.LayoutDoLayout(self.LayoutPoint)
    UIHelper.LayoutDoLayout(self.LayoutState)
end

function UIWidgetRollPointItem:RefreshCountDown()
    local tLootInfo = self.tLootInfo
    if not tLootInfo then return end

    local tBidInfo = AuctionData.GetBiddingInfo(tLootInfo.dwDoodadID, tLootInfo.nItemLootIndex)
    if not tBidInfo then return end

    local nCurTime = GetGSCurrentTime()
    local nLeftTime = tBidInfo.nStartTime - nCurTime
    local bCountDown = tLootInfo.eState == AuctionState.CountDown
    local bCountFinished = tLootInfo.eState == AuctionState.CountFinished
    if not bCountDown and not bCountFinished then
        nLeftTime = 0
    end
    UIHelper.SetVisible(self.LabelCountDown, nLeftTime > 0)
    UIHelper.SetVisible(self.LabelCountDownNum, nLeftTime > 0)

    nLeftTime = math.ceil(nLeftTime)
    local szLeftTime = tostring(nLeftTime) .. g_tStrings.STR_TIME_SECOND
    if tLootInfo.szRollPoint ~= nil then szLeftTime = szLeftTime.."(等待结算)" end
    UIHelper.SetString(self.LabelCountDownNum, szLeftTime)

    local nProgress = nLeftTime / AuctionData.AUCTION_BID_TIME_LIMIT * 100
    if nProgress < 0 then nProgress = 0 end
    UIHelper.SetProgressBarPercent(self.WidgetCountDown, nProgress)


    UIHelper.SetVisible(self.WidgetSummingUp, bCountDown)
    UIHelper.SetVisible(self.WidgetSummedUp, bCountFinished)

    UIHelper.LayoutDoLayout(self.LayoutCountDown)
end

function UIWidgetRollPointItem:RefreshButtons()
    local tLootInfo = self.tLootInfo
    local tDoodadInfo = AuctionData.tPickedDoodads[tLootInfo.dwDoodadID]
    if not tDoodadInfo then return end

    local bCanRollNeed	= g_pClientPlayer.IsBelongForceItem(tLootInfo.dwItemID)

    UIHelper.SetVisible(UIHelper.GetParent(self.BtnNeed), tLootInfo.bNeedRoll and not tLootInfo.nChoice and not tLootInfo.bHasDistributed)
    UIHelper.SetVisible(UIHelper.GetParent(self.BtnGreed), tLootInfo.bNeedRoll and not tLootInfo.nChoice and not tLootInfo.bHasDistributed)
    UIHelper.SetVisible(UIHelper.GetParent(self.BtnCancel), tLootInfo.bNeedRoll and not tLootInfo.nChoice and not tLootInfo.bHasDistributed)

    if not bCanRollNeed then
        UIHelper.SetButtonState(self.BtnNeed, BTN_STATE.Disable, "该物品并不适合您的门派")
    else
        UIHelper.SetButtonState(self.BtnNeed, BTN_STATE.Normal)
    end

    UIHelper.LayoutDoLayout(self.LayoutBottomBtns)
end

function UIWidgetRollPointItem:GetCurrencyPrice(tLootInfo)
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

function UIWidgetRollPointItem:SetClickCallback(fCallBack)
    self.fCallBack = fCallBack
end

function UIWidgetRollPointItem:IsItemUsed(dwTabType, dwTabIndex, item)
	if not item or dwTabType == ITEM_TABLE_TYPE.EQUIPMENT then
		return false
	end
	if GDAPI_GetDefaulItem(item) ~= 3 then
		return false
	end
	local player = GetClientPlayer()
	if not player then
		return false
	end
	local tEnchantInfo = CraftData.g_EnchantInfo[dwTabIndex]
	local dwEnchantID = tEnchantInfo.EnchantID
	local aEquipBoxes =
	{
		INVENTORY_INDEX.EQUIP,
		INVENTORY_INDEX.EQUIP_BACKUP1,
		INVENTORY_INDEX.EQUIP_BACKUP2,
		INVENTORY_INDEX.EQUIP_BACKUP3,
	}

	local function IsEquippedItemUsed(itemEquip)
		if not itemEquip then
			return false
		end

		if (itemEquip.dwPermanentEnchantID or 0) == dwEnchantID then
			return true
		end

		if (itemEquip.dwTemporaryEnchantID or 0) == dwEnchantID and itemEquip.GetTemporaryEnchantLeftSeconds then
			local nTime = itemEquip.GetTemporaryEnchantLeftSeconds()
			return nTime >= 0
		end

		return false
	end

	for _, dwBox in ipairs(aEquipBoxes) do
		for k, v in pairs(EquipType2ItemType) do
			local itemEquip = player.GetItem(dwBox, k)
			if IsEquippedItemUsed(itemEquip) then
				return true
			end
		end
	end
	return false
end

return UIWidgetRollPointItem
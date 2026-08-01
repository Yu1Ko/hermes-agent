local UIWidgetItemOperTips = class("UIWidgetItemOperTips")


function UIWidgetItemOperTips:OnEnter(tDoodadInfo, fCallBack)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    if not tDoodadInfo then
        return
    end

    self.fCallBack = fCallBack
    self:UpdateInfo(tDoodadInfo)
end

function UIWidgetItemOperTips:OnExit()
    self.bInit = false
end

function UIWidgetItemOperTips:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnCaiLiao, EventType.OnClick, function ()
        self.fCallBack(AuctionQuickDistributeType.Material)
    end)

    UIHelper.BindUIEvent(self.BtnSanJian, EventType.OnClick, function ()
        self.fCallBack(AuctionQuickDistributeType.SanJian)
    end)

    UIHelper.BindUIEvent(self.BtnWuPin, EventType.OnClick, function ()
        self.fCallBack(AuctionQuickDistributeType.General)
    end)
end

function UIWidgetItemOperTips:RegEvent()
    Event.Reg(self, EventType.OnLootInfoTimeOut, function (tNewLootInfo)
        if self.tDoodadInfo.nDoodadID == tNewLootInfo.dwDoodadID then
            self:UpdateInfo()
        end
    end)
end

local function IsItemSanjian(dwTabType, dwTabIndex)
	local itemInfo = GetItemInfo(dwTabType, dwTabIndex)
	assert(itemInfo)
	if itemInfo.nGenre == ITEM_GENRE.EQUIPMENT and itemInfo.nSub >= EQUIPMENT_SUB.MELEE_WEAPON and itemInfo.nSub <= EQUIPMENT_SUB.BANGLE then
		return true
	end
	return false
end

function UIWidgetItemOperTips:UpdateInfo(tDoodadInfo)
    self.tDoodadInfo = tDoodadInfo or self.tDoodadInfo
    tDoodadInfo = self.tDoodadInfo

    self.tMaterialItems = {}
	self.tSanjianItems = {}
	self.tGeneralItems = {}

    for _, tLootInfo in ipairs(tDoodadInfo.tLootItemInfoList) do
        local item = AuctionData.GetItem(tLootInfo.dwDoodadID, tLootInfo.nItemLootIndex)
        local tBidInfo = AuctionData.GetBiddingInfo(tLootInfo.dwDoodadID, tLootInfo.nItemLootIndex)
        local bNoBidder = tBidInfo and tBidInfo.szDestPlayerName and tBidInfo.szDestPlayerName == ""
        if item and not tLootInfo.bCanFreeLoot and (tLootInfo.eState == AuctionState.WaitAuction or bNoBidder) then
            local dwTabType = item.dwTabType
            local dwTabIndex = item.dwIndex
            table.insert(self.tGeneralItems, tLootInfo)
            if Table_IsSpecialItem(dwTabType, dwTabIndex) then
                table.insert(self.tMaterialItems, tLootInfo)
            end
            if IsItemSanjian(dwTabType, dwTabIndex) then
                table.insert(self.tSanjianItems, tLootInfo)
            end
        end
    end

    local szCaiLiao = string.format("所有剩余材料(%d)", #self.tMaterialItems)
    local szSanJian = string.format("所有剩余散件(%d)", #self.tSanjianItems)
    local szWuPin = string.format("所有剩余物品(%d)", #self.tGeneralItems)

    UIHelper.SetString(self.LabelOperCaiLiao, szCaiLiao)
    UIHelper.SetString(self.LabelOperSanJian, szSanJian)
    UIHelper.SetString(self.LabelOperWuPin, szWuPin)

    if #self.tMaterialItems == 0 then
        UIHelper.SetButtonState(self.BtnCaiLiao, BTN_STATE.Disable)
    else
        UIHelper.SetButtonState(self.BtnCaiLiao, BTN_STATE.Normal)
    end
    if #self.tSanjianItems == 0 then
        UIHelper.SetButtonState(self.BtnSanJian, BTN_STATE.Disable)
    else
        UIHelper.SetButtonState(self.BtnSanJian, BTN_STATE.Normal)
    end
    if #self.tGeneralItems == 0 then
        UIHelper.SetButtonState(self.BtnWuPin, BTN_STATE.Disable)
    else
        UIHelper.SetButtonState(self.BtnWuPin, BTN_STATE.Normal)
    end
end

return UIWidgetItemOperTips
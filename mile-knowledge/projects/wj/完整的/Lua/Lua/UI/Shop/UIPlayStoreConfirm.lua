local UIPlayStoreConfirm = class("UIPlayStoreConfirm")

local COUNT_DOWN_TIME = 3000 -- 高价倒计时毫秒数
function UIPlayStoreConfirm:OnEnter(nNpcID, nShopID, dwPlayerRemoteDataID, tbGoods, bNeedGray, nBuyCount, bRemind, fConfirmFunc)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo(nNpcID, nShopID, dwPlayerRemoteDataID, tbGoods, bNeedGray, nBuyCount, fConfirmFunc)
    if bRemind then
        self.dwStartTime = GetTickCount()
        self.nTimerID = self.nTimerID or Timer.AddFrameCycle(self, 5, function ()
            self:OnFrameBreathe()
        end)
    end
end

function UIPlayStoreConfirm:OnExit()
    self.bInit = false
end

function UIPlayStoreConfirm:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnOk, EventType.OnClick, function ()
        self.fConfirmFunc()
        UIMgr.Close(VIEW_ID.PanelPlayStoreConfirm)
    end)

    UIHelper.BindUIEvent(self.BtnCalloff, EventType.OnClick, function ()
        UIMgr.Close(VIEW_ID.PanelPlayStoreConfirm)
    end)
end

function UIPlayStoreConfirm:RegEvent()

end

function UIPlayStoreConfirm:OnFrameBreathe()
    if not self.dwStartTime then
        return
    end

    local nTime = GetTickCount()
	local nLiveTime = nTime - self.dwStartTime
	local nSeconds = math.floor((COUNT_DOWN_TIME - nLiveTime) / 1000 + 0.5)
	nSeconds = math.max(nSeconds, 0)

    local szText = g_tStrings.STR_HOTKEY_SURE
	if nSeconds > 0 then
		szText = FormatString(g_tStrings.MSG_BRACKET, g_tStrings.STR_HOTKEY_SURE, nSeconds)        
        UIHelper.SetButtonState(self.BtnOk, BTN_STATE.Disable) 
    else
        UIHelper.SetButtonState(self.BtnOk, BTN_STATE.Normal)
        self.dwStartTime = nil
	end
    UIHelper.SetString(self.LabelOk, szText)       
end

function UIPlayStoreConfirm:UpdateInfo(nNpcID, nShopID, dwPlayerRemoteDataID, tbGoods, bNeedGray, nBuyCount, fConfirmFunc)
    self.fConfirmFunc = fConfirmFunc

    local nStackNum = 1
    local item = ShopData.GetItemByGoods(tbGoods)
    if item.bCanStack and item.nStackNum and item.nStackNum > 1 then nStackNum = item.nStackNum end
    local itemName = ShopData.GetItemNameByGoods(tbGoods)
    itemName = UIHelper.GBKToUTF8(itemName)
    local nDiamondR, nDiamondG, nDiamondB = GetItemFontColorByQuality(item.nQuality)
    local itemName = GetFormatText(itemName, nil, nDiamondR, nDiamondG, nDiamondB)
    local szHint = string.format(g_tStrings.Shop.STR_BUY_GOODS_TIPS, itemName)
    UIHelper.SetRichText(self.LabelHint, szHint)

    local scriptCell = UIHelper.AddPrefab(PREFAB_ID.WidgetPlayStoreCell, self.WidgetPlayStoreCellParent)
    if scriptCell then
        scriptCell:OnEnter(nNpcID, nShopID, dwPlayerRemoteDataID, tbGoods, bNeedGray, nBuyCount / nStackNum)
        scriptCell:SetForbidCallBack(true)
        -- UIHelper.SetString(scriptCell.LabelCount, nBuyCount)
        if scriptCell.itemScript then
            Event.Reg(self, EventType.HideAllHoverTips, function()
                UIHelper.SetSelected(scriptCell.itemScript.ToggleSelect, false)
            end)
            scriptCell.itemScript:SetSelectEnable(true)
        end
    end
end

return UIPlayStoreConfirm
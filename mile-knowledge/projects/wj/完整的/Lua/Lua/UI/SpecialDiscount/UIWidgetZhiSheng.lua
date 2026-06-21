-- ---------------------------------------------------------------------------------
-- Author: liu yu min
-- Name: UIWidgetZhiSheng
-- Date: 2023-08-01 15:47:34
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetZhiSheng = class("UIWidgetZhiSheng")

function UIWidgetZhiSheng:OnEnter(tList, nShowIndex)
	self.tList = tList
	self.nShowIndex = nShowIndex
	if not self.bInit then
		self:RegEvent()
		self:BindUIEvent()
		self.bInit = true
	end
	self:UpdateInfo()
end

function UIWidgetZhiSheng:OnExit()
	self.bInit = false
	self:UnRegEvent()
end

function UIWidgetZhiSheng:BindUIEvent()
	UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
		Event.Dispatch("OnCloseSpecialDiscountPop")
	end)

	UIHelper.BindUIEvent(self.BtnBuy, EventType.OnClick, function()
		self:BuyBox()
	end)
end

function UIWidgetZhiSheng:RegEvent()

end

function UIWidgetZhiSheng:UnRegEvent()
	--Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetZhiSheng:UpdateInfo()
	self:UpdateCenter(self.nShowIndex)
end

function UIWidgetZhiSheng:UpdateCenter(nShowIndex)
	
	local tLine = self.tList[nShowIndex]
	local szShowTitle = GBKToUTF8(tLine.szShowTitle)
	local szTitle = GBKToUTF8(tLine.szName)
	szShowTitle = szShowTitle:gsub("%s+", "")
	local splitList = string.split(szShowTitle, "，")

	UIHelper.SetString(self.LabelSubTitle01, splitList[1])
	UIHelper.SetString(self.LabelSubTitle02, splitList[2])
	UIHelper.SetString(self.LabelBoxTitle, szTitle)
	local szTitleImg = LimitedSaleImg[tLine.szTitlePath][tLine.nTitleFrame]
	UIHelper.SetSpriteFrame(self.ImgTitle, szTitleImg)
	--价格
	self.nTotalPrice = 0
	self.nTotalOriginalPrice = 0
	if tLine.tGoods then
		self.tGoods = tLine.tGoods
	end
	for k, tGood in ipairs(tLine.tGoods) do
		local eGoodsType 	= tGood.eGoodsType
		local dwGoodsID  	= tGood.dwGoodsID
		local tInfo 		= CoinShop_GetPriceInfo(dwGoodsID, eGoodsType)
		local nPrice, nOriginalPrice = CoinShop_GetShowPrice(tInfo)
		self.nTotalPrice 		= self.nTotalPrice + nPrice
		self.nTotalOriginalPrice = self.nTotalOriginalPrice + nOriginalPrice
	end
	UIHelper.SetString(self.LabelPriceBeforeNum,self.nTotalOriginalPrice)
	UIHelper.SetString(self.LabelPriceNewNum,string.format("仅%d",self.nTotalPrice))

	--时间
	UIHelper.SetString(self.LabelTime,g_tStrings.STR_SURPLUS .. self:GetFormatTime(SpecialDiscountData.GetLeftTime(tLine.nEndTime)))
	self.nTimerID = Timer.AddCycle(self, 1, function()
		UIHelper.SetString(self.LabelTime,g_tStrings.STR_SURPLUS .. self:GetFormatTime(SpecialDiscountData.GetLeftTime(tLine.nEndTime)))
		if SpecialDiscountData.GetLeftTime(tLine.nEndTime) <= 0 then
			Timer.DelTimer(self,self.nTimerID)
			Event.Dispatch("OnCloseSpecialDiscountPop")
			BubbleMsgData.RemoveMsg("SpecialDiscountTips")
		end
    end)

	--物品
	if not self.scriptItemList then
        self.scriptItemList = {}
    end
	local tBox = SplitString(tLine.szBox, ";")
	local tbItemScript = {}
	for k, szBox in ipairs(tBox) do
		local t = SplitString(szBox, ":")
		local dwItemType = tonumber(t[1])
		local dwItemID = tonumber(t[2])
		local dwCount = tonumber(t[3])
		 
		local scriptItem = self.scriptItemList[k]
		if not scriptItem then
			scriptItem = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.ItemList[k])
			table.insert(self.scriptItemList,scriptItem)
		end
		scriptItem:OnInitWithTabID(dwItemType, dwItemID, dwCount)
		scriptItem:SetSelectMode(false)
		scriptItem:SetClearSeletedOnCloseAllHoverTips(true)
		scriptItem:SetToggleGroupIndex(ToggleGroupIndex.ReputationRewardItem)
		scriptItem:SetClickCallback(function(nTabType, nTabID)
			TipsHelper.ShowItemTips(scriptItem._rootNode, dwItemType, dwItemID)
		end)
		UIHelper.SetSwallowTouches(scriptItem.ToggleSelect, false)
		UIHelper.SetVisible(scriptItem._rootNode, true)
	end
end

function UIWidgetZhiSheng:GetFormatTime(nTime)
	local nM = math.floor(nTime / 60)
	local nS = math.floor(nTime % 60)
	local szTimeText = ""

	if nM ~= 0 then
		szTimeText= szTimeText..nM.."分"
	end

	if nS < 10 and nM ~= 0 then
		szTimeText = szTimeText.."0"
	end

	szTimeText= szTimeText..nS.."秒"

	return szTimeText
end

function UIWidgetZhiSheng:BuyBox()
	local hPlayer = GetClientPlayer()
	if not hPlayer then
		return
	end
	if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.COIN, "COIN") then
		return
	end
	if self.nTotalPrice > hPlayer.nCoin then --余额不足
		local szMessage = FormatString(g_tStrings.STR_LIMITED_SALE_TIP1,self.nTotalPrice)
		
		local confirmDialog = UIHelper.ShowConfirm(szMessage, function ()
			UIMgr.Close(VIEW_ID.PanelSpecialDiscountPop)
			UIMgr.Open(VIEW_ID.PanelTopUpMain)
		end, nil)
		confirmDialog:SetButtonContent("Confirm", g_tStrings.STR_RECHARGE)
		confirmDialog:SetButtonContent("Cancel", g_tStrings.STR_HOTKEY_CANCEL)
	else
		local szMessage = FormatString(g_tStrings.STR_LIMITED_SALE_TIP2,self.nTotalPrice)
		local confirmDialog = UIHelper.ShowConfirm(szMessage, function ()
			local tGood = self.tGoods[1]
			if tGood then
				CoinShop_BuyItem(tGood.dwGoodsID, tGood.eGoodsType, 1)
				Event.Dispatch("OnCloseSpecialDiscountPop")
				BubbleMsgData.RemoveMsg("SpecialDiscountTips")
			end
		end, nil)
	end
end

return UIWidgetZhiSheng
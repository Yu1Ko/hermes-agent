-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandBuildPendantBuyView
-- Date: 2023-12-21 20:31:51
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandBuildPendantBuyView = class("UIHomelandBuildPendantBuyView")

function UIHomelandBuildPendantBuyView:OnEnter(dwFurnitureID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.dwFurnitureID = dwFurnitureID
    self:InitCurrency()
    self:UpdateInfo()
end

function UIHomelandBuildPendantBuyView:OnExit()
    self.bInit = false
end

function UIHomelandBuildPendantBuyView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnSure, EventType.OnClick, function(btn)
        FurnitureBuy.BuyPendant(self.dwFurnitureID)
        UIMgr.Close(self)
    end)
end

function UIHomelandBuildPendantBuyView:RegEvent()
    Event.Reg(self, "SYNC_REWARDS", function ()
        self:UpdateCurreny()
    end)

    Event.Reg(self, "FACE_LIFT_VOUCHERS_CHANGE", function ()
        self:UpdateCurreny()
    end)

    Event.Reg(self, "ON_COIN_SHOP_VOUCHER_CHANGED", function ()
        self:UpdateCurreny()
    end)
end

function UIHomelandBuildPendantBuyView:InitCurrency()
    UIMgr.AddPrefab(PREFAB_ID.WidgetCoin, self.LayoutCurrency, nil, false)
    -- self.RewardsScript = UIMgr.AddPrefab(PREFAB_ID.WidgetOtherCurrency, self.LayoutCurrency)
    -- self.RewardsScript:SetCurrencyType(CurrencyType.StorePoint)
    self:UpdateCurreny()
end

function UIHomelandBuildPendantBuyView:UpdateCurreny()
    -- local nRewards = CoinShopData.GetRewards()
    -- self.RewardsScript:SetLableCount(nRewards)
    UIHelper.LayoutDoLayout(self.LayoutCurrency)
end

function UIHomelandBuildPendantBuyView:UpdateInfo()
    local pHomelandMgr = GetHomelandMgr()
	local pPlayer = GetClientPlayer()

	local tInfo =  FurnitureData.GetFurnInfoByTypeAndID(HS_FURNITURE_TYPE.PENDANT, self.dwFurnitureID)
	local tLine = FurnitureData.GetPendantInfo(tInfo.nCatg1Index, tInfo.nCatg2Index)
	local tConfig = pHomelandMgr.GetPendantConfig(self.dwFurnitureID)
	local nItemUiId = pHomelandMgr.MakeFurnitureUIID(HS_FURNITURE_TYPE.PENDANT, self.dwFurnitureID)
	local tAddInfo = FurnitureData.GetFurnAddInfo(nItemUiId)
	local szPath = tAddInfo.szPath
	local nMoney  = tConfig.nMoney
	local nNum = 1


	UIHelper.SetTexture(self.ImgIcon, UIHelper.FixDXUIImagePath(szPath))

	local szTextMoney = ""
	local tMoney = pPlayer.GetMoney()
	local nPlayerGold, nPlayerSilver, nPlayerCopper = (tMoney.nGold or 0), (tMoney.nSilver or 0), (tMoney.nCopper or 0)
	local bNotEnough = nPlayerGold < nMoney

	if bNotEnough then
		szTextMoney = GetFormatText(nMoney, nil, 255, 0, 0)
	else
		szTextMoney = GetFormatText(nMoney)
	end

	local szTextName = GetFormatText("[" .. UIHelper.GBKToUTF8(tInfo.szName) .. "]", nil, GetItemFontColorByQuality(tInfo.nQuality))

    local szTitle = UIHelper.GBKToUTF8(tLine.szTitle)
	local szDesc = string.format("你确定%s%d个%s，消耗%s<img src='UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_Jin' width='35' height='35' />吗？", szTitle, nNum, szTextName, szTextMoney)
    UIHelper.SetString(self.LabelTitle, szTitle)
    UIHelper.SetRichText(self.RichTextDesc, szDesc)
end


return UIHomelandBuildPendantBuyView
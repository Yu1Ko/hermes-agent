-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIDisConponPopItem
-- Date: 2022-12-20 18:22:08
-- Desc: ?
-- ---------------------------------------------------------------------------------

local tDigit2Texture = {
    [1] = "UIAtlas2_Shopping_Shopping1_1",
    [2] = "UIAtlas2_Shopping_Shopping1_2",
    [3] = "UIAtlas2_Shopping_Shopping1_3",
    [4] = "UIAtlas2_Shopping_Shopping1_4",
    [5] = "UIAtlas2_Shopping_Shopping1_5",
    [6] = "UIAtlas2_Shopping_Shopping1_6",
    [7] = "UIAtlas2_Shopping_Shopping1_7",
    [8] = "UIAtlas2_Shopping_Shopping1_8",
    [9] = "UIAtlas2_Shopping_Shopping1_9",
    [0] = "UIAtlas2_Shopping_Shopping1_0",
}

local UIDisConponPopItem = class("UIDisConponPopItem")

function UIDisConponPopItem:OnEnter(tbDisCoupon)
    self.tbDisCoupon = tbDisCoupon

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIDisConponPopItem:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIDisConponPopItem:BindUIEvent()
    UIHelper.BindUIEvent(self.TogSelect, EventType.OnSelectChanged, function (_, bSelected)
        if self.fnSelectedCallback then
            self.fnSelectedCallback(self.tbDisCoupon, bSelected)
        end
        -- if bSelected then
        --     CoinShopData.VisitWelfare(self.tbDisCoupon)
        -- end
    end)

    UIHelper.BindUIEvent(self.BtnSettleAccounts, EventType.OnClick, function()
        if self.fnClickCallback then
            self.fnClickCallback()
        end
    end)
end

function UIDisConponPopItem:SetSelected(bSelect, bCallback)
    if bCallback == nil then
        bCallback = true
    end
    UIHelper.SetSelected(self.TogSelect, bSelect, bCallback)
end

function UIDisConponPopItem:SetSelectedCallback(callback)
    self.fnSelectedCallback = callback
end

function UIDisConponPopItem:SetClickCallback(callback)
    self.fnClickCallback = callback
end

function UIDisConponPopItem:SetTouchEnabled(bEnable)
    UIHelper.SetTouchEnabled(self.TogSelect, bEnable)
end

function UIDisConponPopItem:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIDisConponPopItem:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIDisConponPopItem:UpdateInfo()
    UIHelper.SetString(self.LabelCount, "x" .. (self.tbDisCoupon.nCount or 1))
    UIHelper.SetString(self.LabelCountSelect, "x" .. (self.tbDisCoupon.nCount or 1))
    -- UIHelper.SetToggleGroupIndex(self.TogSelect, ToggleGroupIndex.CoinShopCheckoutDisConpon)
    if self.tbDisCoupon.nType == COIN_SHOP_DISCOUNT_TYPE.DISCOUNT then
        local szTip = UIHelper.GBKToUTF8(self.tbDisCoupon.szTipContent)
        local sz1 = szTip:match("(%d+%.?%d*)折")
        sz1 = sz1 or "1"
        local fNum = tonumber(sz1)
        local nPart = math.floor(fNum)
        local fPart = math.floor((fNum - nPart+0.05) * 10)
        for i = 1, #self.tbImgNum do
            UIHelper.SetVisible(self.tbImgNum[i], i == 1 or i == 4)
            UIHelper.SetVisible(self.tbImgNumSelect[i], i == 1 or i == 4)
        end
        UIHelper.SetSpriteFrame(self.tbImgNum[1], tDigit2Texture[nPart])
        UIHelper.SetSpriteFrame(self.tbImgNum[4], tDigit2Texture[fPart])
        UIHelper.SetVisible(self.ImgTongBao, false)
        UIHelper.SetVisible(self.ImgZhe, true)
        UIHelper.SetVisible(self.ImgDot, true)
        UIHelper.SetVisible(self.LayourReduction1, false)
        UIHelper.LayoutDoLayout(self.WidgetFullReduction)
        UIHelper.SetSpriteFrame(self.tbImgNumSelect[1], tDigit2Texture[nPart])
        UIHelper.SetSpriteFrame(self.tbImgNumSelect[4], tDigit2Texture[fPart])
        UIHelper.SetVisible(self.ImgTongBaoSelect, false)
        UIHelper.SetVisible(self.ImgZheSelect, true)
        UIHelper.SetVisible(self.ImgDotSelect, true)
        UIHelper.SetVisible(self.LayourReduction1Select, false)
        UIHelper.LayoutDoLayout(self.WidgetFullReductionSelect)
        self:UpdateCommon()
    elseif self.tbDisCoupon.nType == COIN_SHOP_DISCOUNT_TYPE.FULL_CUT then
        local szTip = UIHelper.GBKToUTF8(self.tbDisCoupon.szTipContent)
        local sz1, sz2 = szTip:match("(%d+)%D*减(%d+)")
        sz1 = sz1 or "1"
        sz2 = sz2 or "1"
        UIHelper.SetString(self.LabelFull, string.format("满%s通宝", sz1))
        UIHelper.SetString(self.LabelFullSelect, string.format("满%s通宝", sz1))
        local nIndex = 1
        for i = 1, string.len(sz2) do
            local digit =  tonumber(string.sub(sz2, i, i))
            local szPath = tDigit2Texture[digit]
            UIHelper.SetSpriteFrame(self.tbImgNum[i], szPath)
            UIHelper.SetSpriteFrame(self.tbImgNumSelect[i], szPath)
            nIndex = nIndex + 1
        end
        for i = nIndex, #self.tbImgNum do
            UIHelper.SetVisible(self.tbImgNum[i], false)
            UIHelper.SetVisible(self.tbImgNumSelect[i], false)
        end
        self:UpdateCommon()
    else
        UIHelper.SetVisible(self.LayourReduction1, false)
        UIHelper.SetVisible(self.LayourReduction2, false)
        UIHelper.SetVisible(self.LayoutDescription, false)
        UIHelper.SetVisible(self.LabelFullReduction, true)
        UIHelper.SetRichText(self.LabelFullReduction,  string.format("<color=#fff8d1>%s</color>", g_tStrings.STR_NOT_USE_WELFARE))
        UIHelper.SetVisible(self.LayourReduction1Select, false)
        UIHelper.SetVisible(self.LayourReduction2Select, false)
        UIHelper.SetVisible(self.LayoutDescriptionSelect, false)
        UIHelper.SetVisible(self.LabelFullReductionSelect, true)
        UIHelper.SetRichText(self.LabelFullReductionSelect,  string.format("<color=#ad833e>%s</color>", g_tStrings.STR_NOT_USE_WELFARE))
    end

    UIHelper.LayoutDoLayout(self.LayourReduction1)
    UIHelper.LayoutDoLayout(self.LayourReduction2)
    UIHelper.LayoutDoLayout(self.WidgetFullReduction)
    UIHelper.LayoutDoLayout(self.LayoutDescription)
    UIHelper.LayoutDoLayout(self.LayourReduction1Select)
    UIHelper.LayoutDoLayout(self.LayourReduction2Select)
    UIHelper.LayoutDoLayout(self.WidgetFullReductionSelect)
    UIHelper.LayoutDoLayout(self.LayoutDescriptionSelect)
end

function UIDisConponPopItem:UpdateCommon()
    UIHelper.SetRichText(self.LabelDesc, string.format("<color=#896431>%s</color>",  UIHelper.GBKToUTF8(self.tbDisCoupon.szDescription)))
    UIHelper.SetRichText(self.LabelDescSelect, string.format("<color=#896431>%s</color>",  UIHelper.GBKToUTF8(self.tbDisCoupon.szDescription)))

    local szExistTime = g_tStrings.EXTERIOR_HAVE_PERMANENT
    local nBeginTime = self.tbDisCoupon.nBeginTime
    local nEndTime = self.tbDisCoupon.nEndTime or -1
    if self.tbDisCoupon.nExistDuration > 0 and (nEndTime == -1 or  self.tbDisCoupon.nCreateTime + self.tbDisCoupon.nExistDuration < nEndTime) then
        nEndTime = self.tbDisCoupon.nCreateTime + self.tbDisCoupon.nExistDuration
    end
    if nBeginTime > 0 and nEndTime > 0 then
        szExistTime = FormatTime("%Y/%m/%d %H:%M", nBeginTime):sub(3) .. "-" .. FormatTime("%Y/%m/%d %H:%M", nEndTime):sub(3)
    elseif nBeginTime > 0 then
        szExistTime = FormatTime(g_tStrings.COINSHOP_WELFARE_TIME2, nBeginTime)
    elseif nEndTime > 0 then
        szExistTime = FormatTime(g_tStrings.COINSHOP_WELFARE_TIME1, nEndTime)
    end
    UIHelper.SetString(self.LabelTime, szExistTime)
    UIHelper.SetString(self.LabelTimeSelect, szExistTime)

    UIHelper.SetVisible(self.WidgetCharacterTip, true)
    if self.tbDisCoupon.bIsAccountLevel then
        UIHelper.SetSpriteFrame(self.ImgAccountLevel, "UIAtlas2_Shopping_SettleAccounts_img_zhanghao")
        UIHelper.SetString(self.LabelAccountLevel, "本服")
    else
        UIHelper.SetSpriteFrame(self.ImgAccountLevel, "UIAtlas2_Shopping_SettleAccounts_img_juese")
        UIHelper.SetString(self.LabelAccountLevel, "角色")
    end
end

function UIDisConponPopItem:SetHasRedPoint(bHas)
    UIHelper.SetVisible(self.ImgRedDot, bHas)
end

return UIDisConponPopItem
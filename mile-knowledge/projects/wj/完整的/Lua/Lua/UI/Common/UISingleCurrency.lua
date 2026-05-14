---@class UISingleCurrency
local UISingleCurrency = class("UISingleCurrency")

function UISingleCurrency:OnEnter(nCurrencyCode, nCurrencyNum, bItem, nItemCount)
    self.bItem = bItem or false
    self.nItemCount = nItemCount

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    
    if not self.bItem then
        self:UpdateInfo(nCurrencyCode, nCurrencyNum)
    else
        self:UpdateItemInfo(nCurrencyCode, nCurrencyNum)
    end    
end

function UISingleCurrency:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UISingleCurrency:BindUIEvent()
    UIHelper.BindUIEvent(self.LayoutCurrency, EventType.OnClick, function()
        if not self.bItem then
            CurrencyData.ShowCurrencyHoverTips(self.LayoutCurrency, ShopData.GetCurrencyCodeToType(self.nCurrencyCode))
        else
            TipsHelper.ShowItemTips(self.LayoutCurrency, self.dwTabType, self.dwIndex, false)
        end        
    end)
    UIHelper.SetTouchEnabled(self.LayoutCurrency, true)
end

function UISingleCurrency:RegEvent()
    if not self.bItem then
        Event.Reg(self, "UPDATE_CONTRIBUTION", function ()
            self:UpdateInfo(self.nCurrencyCode)
        end)

        Event.Reg(self, "UPDATE_PRESTIGE", function ()
            self:UpdateInfo(self.nCurrencyCode)
        end)

        Event.Reg(self, "UPDATE_JUSTICE", function ()
            self:UpdateInfo(self.nCurrencyCode)
        end)

        Event.Reg(self, "UPDATE_EXAMPRINT", function ()
            self:UpdateInfo(self.nCurrencyCode)
        end)

        Event.Reg(self, "UPDATE_ARENAAWARD", function ()
            self:UpdateInfo(self.nCurrencyCode)
        end)

        Event.Reg(self, "UPDATE_ACTIVITYAWARD", function ()
            self:UpdateInfo(self.nCurrencyCode)
        end)

        Event.Reg(self, "UPDATE_MENTORAWARD", function ()
            self:UpdateInfo(self.nCurrencyCode)
        end)

        Event.Reg(self, "UPDATE_ARCHITECTURE", function ()
            self:UpdateInfo(self.nCurrencyCode)
        end)

        Event.Reg(self, "BAG_ITEM_UPDATE", function ()
            self:UpdateInfo(self.nCurrencyCode)
        end)

        Event.Reg(self, "UPDATE_CONTRIBUTTON", function ()
            self:UpdateInfo(self.nCurrencyCode)
        end)
    else
        Event.Reg(self, "BAG_ITEM_UPDATE", function ()
            self:UpdateItemInfo(self.dwTabType, self.dwIndex)
        end)
    end
end

function UISingleCurrency:UnRegEvent()

end

function UISingleCurrency:UpdateInfo(nCurrencyCode, nCurrencyNum)
    self.nCurrencyCode = nCurrencyCode
    UIHelper.SetSpriteFrame(self.ImgCurrency, ShopData.CurrencyCode2Tex[nCurrencyCode])
    if not nCurrencyNum then
        nCurrencyNum = self:GetDefaultCurrency()
    end

    UIHelper.SetString(self.LabelCurrency, tostring(nCurrencyNum))
    UIHelper.LayoutDoLayout(self.LayoutCurrency)
    local nWidth, nHeight = UIHelper.GetContentSize(self.LayoutCurrency)
    UIHelper.SetContentSize(self._rootNode, nWidth, nHeight)
    local parent = UIHelper.GetParent(self._rootNode)
    UIHelper.LayoutDoLayout(parent)
end

function UISingleCurrency:GetDefaultCurrency()
    local player = GetClientPlayer()
    local nCurrencyNum = 0
    if self.nCurrencyCode == ShopData.CurrencyCode.Architecture then
        nCurrencyNum = player.nArchitecture
    elseif self.nCurrencyCode == ShopData.CurrencyCode.ArenaCoin then
        nCurrencyNum = player.nArenaAward
    elseif self.nCurrencyCode == ShopData.CurrencyCode.Coin then
        nCurrencyNum = player.nCoin
    elseif self.nCurrencyCode == ShopData.CurrencyCode.Justice then
        nCurrencyNum = player.nJustice
    elseif self.nCurrencyCode == ShopData.CurrencyCode.MentorValue then
        nCurrencyNum = player.nMentorAward
    elseif self.nCurrencyCode == ShopData.CurrencyCode.Prestige then
        nCurrencyNum = player.nCurrentPrestige
    elseif self.nCurrencyCode == ShopData.CurrencyCode.Contribution then
        nCurrencyNum = player.nContribution
    elseif self.nCurrencyCode == ShopData.CurrencyCode.TongFund then
        nCurrencyNum = GetTongClient().GetFundTodayRemainCanUse()
    elseif self.nCurrencyCode == ShopData.CurrencyCode.ExamPrint then
        nCurrencyNum = player.nExamPrint
    elseif self.nCurrencyCode == ShopData.CurrencyCode.WeekPoints then
        local nCurWeekPoint,_ = CurrencyData.GetCurCurrencyLimit(CurrencyType.WeekAward)
        nCurrencyNum = nCurWeekPoint
    elseif self.nCurrencyCode == ShopData.CurrencyCode.SeasonHonorXiuXian then
        nCurrencyNum = GDAPI_SH_GetMountFragmentCount(1)
    elseif self.nCurrencyCode == ShopData.CurrencyCode.SeasonHonorMiJing then
        nCurrencyNum = GDAPI_SH_GetMountFragmentCount(2)
    elseif self.nCurrencyCode == ShopData.CurrencyCode.SeasonHonorPVP then
        nCurrencyNum = GDAPI_SH_GetMountFragmentCount(3)
    end

    return nCurrencyNum
end

function UISingleCurrency:UpdateItemInfo(dwTabType, dwIndex)
    self.dwTabType = dwTabType
    self.dwIndex = dwIndex

    local tItemInfo = GetItemInfo(dwTabType, dwIndex)

    if self.szCustomIcon then
        UIHelper.ClearTexture(self.ImgCurrency)
        UIHelper.SetSpriteFrame(self.ImgCurrency, self.szCustomIcon)
    else
        local szImgPath =  UIHelper.GetIconPathByItemInfo(tItemInfo)
        UIHelper.ClearTexture(self.ImgCurrency)
        UIHelper.SetTexture(self.ImgCurrency, szImgPath)
    end

    local nStackNum = ItemData.GetItemAllStackNum(tItemInfo, false)
    if self.nItemCount then
        --- 若指定数目，则展示对应数目
        nStackNum = self.nItemCount
    end
    
    UIHelper.SetString(self.LabelCurrency, tostring(nStackNum))
    UIHelper.LayoutDoLayout(self.LayoutCurrency)
    local nWidth, nHeight = UIHelper.GetContentSize(self.LayoutCurrency)
    UIHelper.SetContentSize(self._rootNode, nWidth, nHeight)
    local parent = UIHelper.GetParent(self._rootNode)
    UIHelper.LayoutDoLayout(parent)
end

function UISingleCurrency:SetCustomIcon(szCustomIcon)
    self.szCustomIcon = szCustomIcon
    UIHelper.ClearTexture(self.ImgCurrency)
    UIHelper.SetSpriteFrame(self.ImgCurrency, szCustomIcon)
end

return UISingleCurrency
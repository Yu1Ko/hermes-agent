-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIBuildFaceTextCell
-- Date: 2023-09-20 20:12:46
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIBuildFaceTextCell = class("UIBuildFaceTextCell")

function UIBuildFaceTextCell:OnEnter(tbInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tbInfo = tbInfo
    self:UpdateInfo()
end

function UIBuildFaceTextCell:OnExit()
    self.bInit = false

    if self.nDownloadDynamicID then
        PakDownloadMgr.ReleaseDynamicPakInfo(self.nDownloadDynamicID)
        self.nDownloadDynamicID = nil
    end
end

function UIBuildFaceTextCell:BindUIEvent()
    UIHelper.BindUIEvent(self.TogHair, EventType.OnClick, function ()
        if self.funcClickCallback then
            self.funcClickCallback(self.tbInfo)
        end
    end)

    UIHelper.BindUIEvent(self.BtnEditName, EventType.OnClick, function ()
        if self.funcClickEditNameCallback then
            self.funcClickEditNameCallback(self.tbInfo)
        end
    end)

    UIHelper.BindUIEvent(self.BtnCheckCase, EventType.OnClick, function ()
        if self.funcClickCheckCaseCallback then
            self.funcClickCheckCaseCallback(self.tbInfo)
        end
    end)

    UIHelper.SetSwallowTouches(self.BtnEditName, true)
end

function UIBuildFaceTextCell:RegEvent()
    Event.Reg(self, EventType.OnEquipPakResourceDownload, function()
        self:UpdateDownload()
    end)

    Event.Reg(self, "DIS_COUPON_CHANGED", function ()
        self:UpdateInfo()
    end)
end

-- 零元购特判标签显示，key是发型ID，value是折扣券ID
local tbShowHair0YuanGou = {
    [1633] = 182,
    [1638] = 183,
}

function UIBuildFaceTextCell:UpdateInfo()
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end

    UIHelper.SetString(self.LabelHairName, self.tbInfo.szName)
    UIHelper.SetString(self.LabelNameSelected, self.tbInfo.szName)

    UIHelper.SetVisible(self.BtnEditName, not not self.tbInfo.bCanEditName)

    UIHelper.SetVisible(self.LayoutPrice1, false)
    UIHelper.SetVisible(self.LayoutPrice2, false)
    UIHelper.SetVisible(self.LayoutJiFen1, false)
    UIHelper.SetVisible(self.LayoutJiFen2, false)
    UIHelper.SetVisible(self.ImgDiscount02, false)
    UIHelper.SetVisible(self.ImgFree, false)
    UIHelper.SetVisible(self.ImgTimeLimit, false)

    if self.tbInfo.bWardrobeHair then
        local nHairID = self.tbInfo.dwID
        local tInfo = GetHairShop().GetHairPrice(BuildFaceData.nRoleType, HAIR_STYLE.HAIR, nHairID)
        local tList = pPlayer.GetHairCustomDyeingList(nHairID)
        local bCanDyeing = tInfo.bCanDyeing
        local bHaveDye = tList and not table.is_empty(tList)
        UIHelper.SetVisible(self.ImgDyeIcon, bHaveDye)
        UIHelper.SetVisible(self.BtnCheckCase, bCanDyeing)
    end

    if BuildFaceData.bPrice and self.tbInfo.bHair then
        local nHairID = BuildHairData.GetHairStyleByClassIndexValue(self.tbInfo.nClassIndex, self.tbInfo.nID)
        local tInfo = GetHairShop().GetHairPrice(BuildFaceData.nRoleType, HAIR_STYLE.HAIR, nHairID)
        if tInfo then
            local tPriceInfo = HairShop_GetPriceInfo(HAIR_STYLE.HAIR, nHairID)
            local bDis, szDisCount, szDisTime, nDisCount = CoinShop_GetDisInfo(tInfo)
            local nRewards = GetGoodsRewards_UI(HAIR_STYLE.HAIR, nHairID, bDis, nDisCount)

            local tPrice = tPriceInfo[1]
            if tPrice then
                if tPrice.nPayType == COIN_SHOP_PAY_TYPE.COIN then
                    UIHelper.SetVisible(self.LayoutPrice1, true)
                    UIHelper.SetVisible(self.LayoutPrice2, true)

                    UIHelper.SetString(self.LabelPrice1, tPrice.nDisPrice)
                    UIHelper.SetString(self.LabelPrice2, tPrice.nDisPrice)

                    UIHelper.SetString(self.LabelOriginalPrice1, tPrice.nPrice)
                    UIHelper.SetString(self.LabelOriginalPrice2, tPrice.nPrice)

                    UIHelper.SetVisible(self.LabelOriginalPrice1, tPrice.bDis)
                    UIHelper.SetVisible(self.LabelOriginalPrice2, tPrice.bDis)

                    UIHelper.LayoutDoLayout(self.LayoutPrice1)
                    UIHelper.LayoutDoLayout(self.LayoutPrice2)
                end
            end

            if nHairID and tbShowHair0YuanGou[nHairID] and CoinShopData.GetWelfare(tbShowHair0YuanGou[nHairID]) then
                UIHelper.SetVisible(self.ImgFree, true)
            end

            local szLeftTime = CoinShopHair.GetCountDownInfo(HAIR_STYLE.HAIR, nHairID)
            if not string.is_nil(szLeftTime) then
                UIHelper.SetVisible(self.ImgTimeLimit, true)
            end

            UIHelper.SetVisible(self.LayoutJiFen1, true)
            UIHelper.SetVisible(self.LayoutJiFen2, true)
            UIHelper.SetVisible(self.ImgDiscount, bDis)
            UIHelper.SetVisible(self.ImgDiscountSelected, bDis)
            UIHelper.SetString(self.LabelDiscount, szDisCount)
            UIHelper.SetString(self.LabelDiscountSelected, szDisCount)
            UIHelper.SetString(self.LabelFate, szDisTime)
            UIHelper.SetString(self.LabelFateSelected, szDisTime)


            UIHelper.SetString(self.LabelJiFen1, nRewards)
            UIHelper.SetString(self.LabelJiFen2, nRewards)

            UIHelper.LayoutDoLayout(self.LayoutJiFen1)
            UIHelper.LayoutDoLayout(self.LayoutJiFen2)
            UIHelper.LayoutDoLayout(self.LayoutContent1)
            UIHelper.LayoutDoLayout(self.LayoutContent2)
        end
    end

    UIHelper.LayoutDoLayout(self.LayoutBtn)
    UIHelper.WidgetFoceDoAlign(self)
end

function UIBuildFaceTextCell:AddTogGroup(togGroup)
    UIHelper.ToggleGroupAddToggle(togGroup, self.TogHair)
end

function UIBuildFaceTextCell:SetClickCallback(funcClickCallback)
    self.funcClickCallback = funcClickCallback
end

function UIBuildFaceTextCell:SetClickEditNameCallback(funcClickEditNameCallback)
    self.funcClickEditNameCallback = funcClickEditNameCallback
end

function UIBuildFaceTextCell:SetClickCheckCaseCallback(funcClickCheckCaseCallback)
    self.funcClickCheckCaseCallback = funcClickCheckCaseCallback
end

function UIBuildFaceTextCell:SetSelected(bSelected)
    UIHelper.SetSelected(self.TogHair, bSelected)
end

function UIBuildFaceTextCell:UpdateDownloadEquipRes(nHairID)
    if not self.WidgetDownload or not self.WidgetDownloadShell then
        return
    end

    if not PakDownloadMgr.IsEnabled() then
        return
    end

    if not g_pClientPlayer then
        return
    end

    local tEquipList, tEquipSfxList = PakEquipResData.GetPakResource(g_pClientPlayer.nRoleType, {{nSource=COIN_SHOP_GOODS_SOURCE.COIN_SHOP, dwType=COIN_SHOP_GOODS_TYPE.HAIR, dwID=nHairID}})
    self.tEquipList, self.tEquipSfxList = tEquipList, tEquipSfxList
    self:UpdateDownload()
end

function UIBuildFaceTextCell:SetRedPointVisible(bVisible)
    UIHelper.SetVisible(self.ImgRedDot, bVisible)
end

function UIBuildFaceTextCell:UpdateDownload()
    local tEquipList, tEquipSfxList = self.tEquipList, self.tEquipSfxList
    if not tEquipList or not tEquipSfxList then
        return
    end
    local tConfig = {}
    tConfig.bCoinShop = true
    tConfig.nTouchWidth, tConfig.nTouchHeight = UIHelper.GetContentSize(self.TogHair)
    local bRemoteNotExist
    self.nDownloadDynamicID, bRemoteNotExist = PakDownloadMgr.UserCheckDownloadEquipRes(g_pClientPlayer.nRoleType, tEquipList, tEquipSfxList, self.nDownloadDynamicID)
    local scriptMask = UIHelper.GetBindScript(self.WidgetDownloadShell)
    scriptMask:SetShowCondition(function ()
        return UIHelper.GetSelected(self.TogHair)
    end)
    scriptMask:SetInfo(self.nDownloadDynamicID, bRemoteNotExist, tConfig)
end

return UIBuildFaceTextCell
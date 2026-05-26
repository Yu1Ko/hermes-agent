local UIAccountsBindingRoleTips = class("UIAccountsBindingRoleTips")

--无尘丹道具ID
local mShareBagBindItemID = 29095
local mShareBagBIndItemType = 5
local m_dwGoodsID = 1735
local m_tPackageIndex = {
    INVENTORY_INDEX.PACKAGE,
    INVENTORY_INDEX.PACKAGE1,
    INVENTORY_INDEX.PACKAGE2,
    INVENTORY_INDEX.PACKAGE3,
    INVENTORY_INDEX.PACKAGE4,
    INVENTORY_INDEX.PACKAGE_MIBAO,
}

local function CheckUnBindItem()
    local itemInfo = ItemData.GetItemInfo(mShareBagBIndItemType,mShareBagBindItemID)
    local nTotalNum, nBagNum, nBankNum = ItemData.GetItemAllStackNum(itemInfo, false)
    return nResult
end

function UIAccountsBindingRoleTips:OnEnter(tPlayerSource)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        self.tPlayerSource = tPlayerSource

        UIHelper.SetTouchDownHideTips(self.BntUnbind, false)
    end

    self:UpdateInfo()
end

function UIAccountsBindingRoleTips:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIAccountsBindingRoleTips:BindUIEvent()
    UIHelper.BindUIEvent(self.BntUnbind, EventType.OnClick, function()
        self:ShowUnbindTip()
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetAccountsBindingRoleTips)
    end)
end

function UIAccountsBindingRoleTips:RegEvent()
    Event.Reg(self, "ON_ADD_SELF_TO_ACCOUNT_SHARED_NOTIFY", function()
        self:UpdateInfo()
    end)

    Event.Reg(self, "ON_REMOVE_ROLE_FROM_ACCOUNT_SHARED_NOTIFY", function()
        self:UpdateInfo()
    end)
end

function UIAccountsBindingRoleTips:UnRegEvent()

end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIAccountsBindingRoleTips:UpdateInfo()
    local tPlayerSource = self.tPlayerSource
    if not tPlayerSource then
        return
    end
    
    local bIsCurrentPlayer = tPlayerSource.dwRoleID == g_pClientPlayer.dwID
    local dwMiniAvatarID = Table_GetMiniAvatarID(tPlayerSource.dwForceID).dwMiniAvatarID

    UIHelper.RoleChange_UpdateAvatar(self.ImgAvatar, dwMiniAvatarID, nil,nil,tPlayerSource.nRoleType, tPlayerSource.dwForceID, true)
    UIHelper.SetSpriteFrame(self.ImgSchool, PlayerForceID2SchoolImg[tPlayerSource.dwForceID])
    
    UIHelper.SetString(self.LabelName, UIHelper.GBKToUTF8(tPlayerSource.szName))
    UIHelper.SetString(self.LabelLevel, tPlayerSource.nLevel .. g_tStrings.STR_LEVEL)

    UIHelper.SetVisible(self.BntUnbind, bIsCurrentPlayer)
    UIHelper.SetVisible(self.LabelUnbind01, not bIsCurrentPlayer)
end

function UIAccountsBindingRoleTips:ShowUnbindTip()
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end

    local itemInfo = ItemData.GetItemInfo(mShareBagBIndItemType,mShareBagBindItemID)
    local nTotalNum, nBagNum, nBankNum = ItemData.GetItemAllStackNum(itemInfo, false)
    print(nTotalNum, nBagNum, nBankNum)

    if pPlayer.bAccountShared then
        local dwGoodsID = m_dwGoodsID
        local eGoodsType = COIN_SHOP_GOODS_TYPE.ITEM
        local nPrice = CoinShop_GetPrice(dwGoodsID, eGoodsType)
        local hItemInfo = ItemData.GetItemInfo(mShareBagBIndItemType, mShareBagBindItemID)
        local szName = ItemData.GetItemNameByItemInfo(hItemInfo)

        if nTotalNum >= 1 then
            if nBagNum == 0 then
                OutputMessage("MSG_ANNOUNCE_NORMAL", FormatString(g_tStrings.ASP_BINDITEM_NOT_IN_BAG, UIHelper.GBKToUTF8(szName)))
            else
                local fnUseBindItem = function()
                    RemoteCallToServer("On_ShareAccData_UnBind")
                end
                local szMsg = FormatString(g_tStrings.ASP_UNBIND_BUY_SURE, UIHelper.GBKToUTF8(szName)
                , UIHelper.GBKToUTF8(pPlayer.szName))
                UIHelper.ShowConfirm(szMsg, fnUseBindItem,nil,true)
            end          
        else
            local szMsg = FormatString(g_tStrings.ASP_BINDITEM_BUY_SURE, UIHelper.GBKToUTF8(szName)
            , nPrice, UIHelper.GBKToUTF8(szName))
            local fnSureBuy = function()
                CoinShop_BuyItem(dwGoodsID, eGoodsType, 1)
            end
            UIHelper.ShowConfirm(szMsg, fnSureBuy,nil,true)
        end
    end
end

return UIAccountsBindingRoleTips
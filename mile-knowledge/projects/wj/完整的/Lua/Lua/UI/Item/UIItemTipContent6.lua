-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIItemTipContent6
-- Date: 2022-11-15 15:45:32
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIItemTipContent6 = class("UIItemTipContent6")

function UIItemTipContent6:OnEnter(tbInfo, nTabType, nTabID)
    if not tbInfo then return end

    self.tbInfo = tbInfo
    self.nTabType = nTabType
    self.nTabID = nTabID

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIItemTipContent6:OnExit()
    self.bInit = false
end

function UIItemTipContent6:BindUIEvent()

end

function UIItemTipContent6:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIItemTipContent6:UpdateInfo()
    if not self.tbInfo or table.is_empty(self.tbInfo) then
        UIHelper.SetVisible(self._rootNode, false)
    else
        local bDis = false
        local szDisCount = ""
        local szDisTime = ""
        local nDisCount = 100
        for _, tPrice in ipairs(self.tbInfo) do
            if tPrice.bDis then
                szDisCount, szDisTime, nDisCount = CoinShop_GetOneDisInfo(tPrice, tPrice.bSecondDis)
                bDis = true
                break
            end
        end
        local eGoodsType = COIN_SHOP_GOODS_TYPE.EXTERIOR
        if self.nTabType == "WeaponExterior" then
            eGoodsType = COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR
        elseif  self.nTabType == "Rewards" then
            eGoodsType = COIN_SHOP_GOODS_TYPE.ITEM
        end
        local nRewards = GetGoodsRewards_UI(eGoodsType, self.nTabID, bDis, nDisCount, nRewards)
        if not nRewards or nRewards == 0 then
            UIHelper.SetVisible(self._rootNode, false)
            return
        end

        UIHelper.SetString(self.Label_Bingjia, tostring(nRewards))

        UIHelper.LayoutDoLayout(self.LayoutGet)
        UIHelper.LayoutDoLayout(self.LayoutAttri1)
        UIHelper.SetVisible(self._rootNode, true)
    end
end


return UIItemTipContent6
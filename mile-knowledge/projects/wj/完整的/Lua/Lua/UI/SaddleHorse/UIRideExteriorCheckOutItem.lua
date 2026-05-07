-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: WidgetRideExteriorCheckOut
-- Date: 2024-03-01 17:01:14
-- Desc: ?
-- ---------------------------------------------------------------------------------

local WidgetRideExteriorCheckOut = class("WidgetRideExteriorCheckOut")

function WidgetRideExteriorCheckOut:OnEnter(tInfo, nExteriorSlot, bSet)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    
        local tExteriorInfo = nil
    if tInfo.dwExteriorID == 0 then
        local tWear = RideExteriorData.GetWearRideExterior()
        local tWear = tWear[tInfo.nExteriorSlot]
        tExteriorInfo = RideExteriorData.GetRideExteriorInfo(tWear.dwExteriorID, tInfo.bEquip)
    else
        tExteriorInfo = RideExteriorData.GetRideExteriorInfo(tInfo.dwExteriorID, tInfo.bEquip)
    end
    if not tExteriorInfo then
        return
    end
    UIHelper.RemoveAllChildren(self.WidgetItem_80)
    local ItemIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.WidgetItem_80)
    if ItemIcon then
        ItemIcon:OnInitWithRideExterior(tExteriorInfo.dwExteriorID, tInfo.bEquip, true)
    end
    UIHelper.SetString(self.LabelType, tInfo.bEquip and g_tStrings.STR_HORSE_EQUIP_EXTERIOR or g_tStrings.STR_HORSE_EXTERIOR)
    UIHelper.SetString(self.LabelName, tExteriorInfo.szName)
    UIHelper.SetString(self.LabelCostMoney, "")
    UIHelper.SetVisible(self.TogSelect, not bSet)
    UIHelper.SetVisible(self.LabelCostMoney, not bSet)
    if bSet then
        if tInfo.dwExteriorID == 0 then
            UIHelper.SetString(self.LabelState, g_tStrings.EXTERIOR_HAIRSHOP_HAVEED)
        else
            UIHelper.SetString(self.LabelState, g_tStrings.EXTERIOR_HAIRSHOP_HAVEED)
        end
    else
        UIHelper.SetString(self.LabelState, g_tStrings.EXTERIOR_NOT_HAVE)
    end
    if not bSet then
        UIHelper.SetMoneyText(self.LabelCostMoney, {nGold = tExteriorInfo.nPrice}, 25, false)
    end

    if tExteriorInfo.bOffer then
        UIHelper.SetString(self.LabelSettleAccounts, FormatString(g_tStrings.REWARDS_SHOP_DISCOUNT, tExteriorInfo.nNowDiscount / 10))
    end
    UIHelper.SetVisible(self.ImgSettleAccounts, (not bSet) and tExteriorInfo.bOffer)
    UIHelper.LayoutDoLayout(self.LayoutSettleAccounts)
end

function WidgetRideExteriorCheckOut:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
    TipsHelper.DeleteAllHoverTips()
end

function WidgetRideExteriorCheckOut:BindUIEvent()

end

function WidgetRideExteriorCheckOut:RegEvent()
    Event.Reg(self, EventType.OnWindowsSizeChanged, function (szName)
        Timer.AddFrame(self, 5, function()
            local childrens = UIHelper.GetChildren(self.LabelCostMoney)
            local fSumWidth = 0
            for _, children in ipairs(childrens) do
                local fWidth = UIHelper.GetWidth(children)
                fSumWidth = fSumWidth + fWidth
            end
            UIHelper.SetWidth(self.LabelCostMoney, fSumWidth)
        end)
    end)
end

function WidgetRideExteriorCheckOut:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function WidgetRideExteriorCheckOut:UpdateInfo()

end


return WidgetRideExteriorCheckOut
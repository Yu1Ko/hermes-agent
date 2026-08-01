-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICoinShopLotteryItem2
-- Date: 2024-09-18 15:35:36
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICoinShopLotteryItem2 = class("UICoinShopLotteryItem2")

function UICoinShopLotteryItem2:OnEnter(tGift)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tGift = tGift
    self:UpdateInfo()
end

function UICoinShopLotteryItem2:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UICoinShopLotteryItem2:BindUIEvent()

end

function UICoinShopLotteryItem2:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UICoinShopLotteryItem2:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICoinShopLotteryItem2:UpdateInfo()
    UIHelper.SetString(self.LabelNum, self.tGift.nLevel)
    if not self.itemScript then
        self.itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.WidgetItemProp)
        self.itemScript:SetClickNotSelected(true)
    end
    self.itemScript:OnInitWithTabID(self.tGift.nItemType, self.tGift.dwItemIndex, self.tGift.nNum)
    self.itemScript:SetToggleSwallowTouches(false)
    self.itemScript:SetClickCallback(function(nParam1, nParam2)
        if nParam1 and nParam2 then
            local _, itemTips = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetItemTip, self.WidgetItemProp)
            itemTips:OnInitWithTabID(self.tGift.nItemType, self.tGift.dwItemIndex)
            itemTips:SetBtnState({})
        end
    end)
end

function UICoinShopLotteryItem2:SetGet(bGet, bEffect)
    UIHelper.SetVisible(self.WidgetGot, bGet)
    if bEffect then
        UIHelper.SetVisible(self.Eff_JiFenDiuHuan, true)
    end
end

return UICoinShopLotteryItem2
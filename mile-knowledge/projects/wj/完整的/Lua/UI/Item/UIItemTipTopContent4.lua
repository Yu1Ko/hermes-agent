-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIItemTipTopContent4
-- Date: 2023-02-21 09:33:10
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIItemTipTopContent4 = class("UIItemTipTopContent4")

function UIItemTipTopContent4:OnEnter(item, bItem, szBindSource, nBookID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo(item, bItem, szBindSource, nBookID)
end

function UIItemTipTopContent4:OnExit()
    self.bInit = false
end

function UIItemTipTopContent4:BindUIEvent()

end

function UIItemTipTopContent4:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIItemTipTopContent4:UpdateInfo(item, bItem, szBindSource)
    local nQuality = item.nQuality
    local tbInfo = { ItemData.GetItemTypeInfo(item, bItem, szBindSource, nBookID) }
    for i = 1, 3, 1 do
        UIHelper.SetString(self["LabelType"..i], tbInfo[i])
        UIHelper.SetVisible(self["LabelType"..i], true)
        if string.is_nil(tbInfo[i]) then
            UIHelper.SetVisible(self["LabelType"..i], false)
        end
    end

    if nQuality <= 0 and item.nAucGenre == AUC_GENRE.CAN_NOT_AUC then
        -- 灰色品质仅显示“可交易（不可寄售）”类型
        UIHelper.SetVisible(self.LabelType1, false)
        UIHelper.SetVisible(self.WidgetRow1, true)
    else
        UIHelper.SetVisible(self.WidgetRow1, nQuality > 0)  -- 灰色品质不显示第一行物品分类
    end
    UIHelper.LayoutDoLayout(self.LayoutRow1)

    local nTotalNum, nBagNum, nBankNum, nHomelandNum, nBaiZhanNum = ItemData.GetItemAllStackNum(item, bItem)

    local itemInfo

    if bItem then
        itemInfo = GetItemInfo(item.dwTabType, item.dwIndex)
    else
        itemInfo = item
    end

    if nHomelandNum then
        UIHelper.SetString(self.LabelTitle2, "背包/仓库/家园")
        UIHelper.SetString(self.LabelNum2, string.format("%d/%d/%d", nBagNum, nBankNum, nHomelandNum))
    elseif nBaiZhanNum then
        UIHelper.SetString(self.LabelTitle2, "背包/仓库/百战")
        UIHelper.SetString(self.LabelNum2, string.format("%d/%d/%d", nBagNum, nBankNum, nBaiZhanNum))
    else
        UIHelper.SetString(self.LabelTitle2, "背包/仓库")
        UIHelper.SetString(self.LabelNum2, string.format("%d/%d", nBagNum, nBankNum))
    end
    UIHelper.LayoutDoLayout(self.LayoutRow3)

    if itemInfo.nMaxExistAmount > 1 then
        UIHelper.SetString(self.LabelNum1, string.format("%d/%d", nTotalNum, itemInfo.nMaxExistAmount))
    else
        UIHelper.SetString(self.LabelNum1, tostring(nTotalNum))
    end
    UIHelper.LayoutDoLayout(self.LayoutItemTipTopContent4)
end


return UIItemTipTopContent4
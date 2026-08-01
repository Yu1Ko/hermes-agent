-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICustomizedSetPowerUpSelectItemCell
-- Date: 2024-07-18 17:27:48
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICustomizedSetPowerUpSelectItemCell = class("UICustomizedSetPowerUpSelectItemCell")

local TipsType = {
    Strength = 1,
    Mount = 2,
    Enchant = 3,
}
function UICustomizedSetPowerUpSelectItemCell:OnEnter(nType, tbData)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nType = nType
    self.tbData = tbData
    self:UpdateInfo()
end

function UICustomizedSetPowerUpSelectItemCell:OnExit()
    self.bInit = false
end

function UICustomizedSetPowerUpSelectItemCell:BindUIEvent()
    UIHelper.BindUIEvent(self.TogType, EventType.OnClick, function(btn)
        Event.Dispatch(EventType.OnSelectCustomizedSetPowerUpSelectItemTipsCell, self.nType, self.tbData)
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetRefineInsertFilterList)
    end)
    UIHelper.SetTouchDownHideTips(self.TogType, false)
end

function UICustomizedSetPowerUpSelectItemCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UICustomizedSetPowerUpSelectItemCell:UpdateInfo()

end

function UICustomizedSetPowerUpSelectItemCell:UpdateInfo()
    UIHelper.SetVisible(self.LayoutRefineStarShell, false)
    UIHelper.SetVisible(self.WidgetInsert, false)

    if self.nType == TipsType.Strength then
        self:UpdateStrengthInfo()
    elseif self.nType == TipsType.Mount then
        self:UpdateMountInfo()
    elseif self.nType == TipsType.Enchant then
        self:UpdateEnchantInfo()
    end
end

function UICustomizedSetPowerUpSelectItemCell:UpdateStrengthInfo()
    UIHelper.SetVisible(self.LayoutRefineStarShell, true)

    for i = 1, self.tbData.nStrengthLevel, 1 do
        local cell = UIHelper.AddPrefab(PREFAB_ID.WIdgetRefineStar, self.LayoutRefineStarShell)
        UIHelper.SetVisible(cell.ImgStarLightEff, false)
    end

    UIHelper.LayoutDoLayout(self.LayoutRefineStarShell)
    UIHelper.SetSelected(self.TogType, self.tbData.nCurStrengthLevel == self.tbData.nStrengthLevel)
end

function UICustomizedSetPowerUpSelectItemCell:UpdateMountInfo()
    UIHelper.SetVisible(self.WidgetInsert, true)

    local nItemTabID = WU_XING_STONE_ITEM_ID[self.tbData.nStoneLevel]

    local itemInfo = ItemData.GetItemInfo(ITEM_TABLE_TYPE.OTHER, nItemTabID)
    local szName = ItemData.GetItemNameByItemInfo(itemInfo)
    UIHelper.SetString(self.LabelName, UIHelper.GBKToUTF8(szName))

    self.scriptIcon = self.scriptIcon or UIHelper.AddPrefab(PREFAB_ID.WidgetItem_44, self.WidgetItem44)
    self.scriptIcon:OnInitWithTabID(ITEM_TABLE_TYPE.OTHER, nItemTabID)
    self.scriptIcon:SetSelectEnable(false)
    UIHelper.SetSelected(self.TogType, self.tbData.nCurSlot == self.tbData.nStoneLevel)
end

function UICustomizedSetPowerUpSelectItemCell:UpdateEnchantInfo()

end

return UICustomizedSetPowerUpSelectItemCell
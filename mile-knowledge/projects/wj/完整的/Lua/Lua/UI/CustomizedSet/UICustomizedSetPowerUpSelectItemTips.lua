-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICustomizedSetPowerUpSelectItemTips
-- Date: 2024-07-18 17:27:35
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICustomizedSetPowerUpSelectItemTips = class("UICustomizedSetPowerUpSelectItemTips")

local TipsType = {
    Strength = 1,
    Mount = 2,
    Enchant = 3,
}
function UICustomizedSetPowerUpSelectItemTips:OnEnter(nType, tbData)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nType = nType
    self.tbData = tbData
    self:UpdateInfo()
end

function UICustomizedSetPowerUpSelectItemTips:OnExit()
    self.bInit = false
end

function UICustomizedSetPowerUpSelectItemTips:BindUIEvent()
    UIHelper.SetTouchDownHideTips(self.ScrollViewRefineInsertList, false)

end

function UICustomizedSetPowerUpSelectItemTips:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UICustomizedSetPowerUpSelectItemTips:UpdateInfo()
    if self.nType == TipsType.Strength then
        self:UpdateStrengthInfo()
    elseif self.nType == TipsType.Mount then
        self:UpdateMountInfo()
    elseif self.nType == TipsType.Enchant then
        self:UpdateEnchantInfo()
    end
end

function UICustomizedSetPowerUpSelectItemTips:UpdateStrengthInfo()
    UIHelper.HideAllChildren(self.ScrollViewRefineInsertList)
    self.tbCells = self.tbCells or {}
    for i = self.tbData.nEquipMaxLevel, 1, -1 do
        if not self.tbCells[i] then
            self.tbCells[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetRefineInsertFilterItem, self.ScrollViewRefineInsertList)
        end

        self.tbCells[i]:OnEnter(self.nType, {
            nStrengthLevel = i,
            nMaxStrengthLevel = self.tbData.nEquipMaxLevel,
            nMaxEquipBoxStrengthLevel = self.tbData.nBoxMaxLevel,
            nCurStrengthLevel = self.tbData.nCurStrengthLevel,
        })
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewRefineInsertList)
end

function UICustomizedSetPowerUpSelectItemTips:UpdateMountInfo()
    UIHelper.HideAllChildren(self.ScrollViewRefineInsertList)
    self.tbCells = self.tbCells or {}
    for i = 8, 1, -1 do
        if not self.tbCells[i] then
            self.tbCells[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetRefineInsertFilterItem, self.ScrollViewRefineInsertList)
        end

        self.tbCells[i]:OnEnter(self.nType, {nStoneLevel = i, nSlot = self.tbData.nSlot, nCurSlot = self.tbData.nCurSlot})
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewRefineInsertList)
end

function UICustomizedSetPowerUpSelectItemTips:UpdateEnchantInfo()

end


return UICustomizedSetPowerUpSelectItemTips
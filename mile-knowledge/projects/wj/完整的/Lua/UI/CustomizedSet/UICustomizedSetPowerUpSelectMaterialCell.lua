-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICustomizedSetPowerUpSelectMaterialCell
-- Date: 2024-07-29 15:50:56
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICustomizedSetPowerUpSelectMaterialCell = class("UICustomizedSetPowerUpSelectMaterialCell")

function UICustomizedSetPowerUpSelectMaterialCell:OnEnter(nItemTabID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nItemTabID = nItemTabID
    self:UpdateInfo()
end

function UICustomizedSetPowerUpSelectMaterialCell:OnExit()
    self.bInit = false
end

function UICustomizedSetPowerUpSelectMaterialCell:BindUIEvent()
    UIHelper.BindUIEvent(self.TogFilterItem, EventType.OnClick, function(btn)
        Event.Dispatch(EventType.OnSelectCustomizedSetMaterialCell, self.nItemTabID)
        UIMgr.Close(VIEW_ID.PanelPowerUpMaterialList)
    end)

end

function UICustomizedSetPowerUpSelectMaterialCell:RegEvent()
    Event.Reg(self, EventType.OnSelectCustomizedSetMaterialCell, function (nItemTabID)
        self:SetSelectedTabID(nItemTabID)
    end)
end

function UICustomizedSetPowerUpSelectMaterialCell:UpdateInfo()
    if not self.scriptIcon then
        self.scriptIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.WidgetItem80)
        self.scriptIcon:SetClickNotSelected(true)
    end

    self.scriptIcon:OnInitWithTabID(ITEM_TABLE_TYPE.OTHER, self.nItemTabID)
    self.scriptIcon:SetSelectEnable(true)
    self.scriptIcon:SetClickCallback(function()
        Timer.AddFrame(self, 1, function()
            TipsHelper.ShowItemTips(self.WidgetItem80, ITEM_TABLE_TYPE.OTHER, self.nItemTabID, false, TipsLayoutDir.LEFT_CENTER)
        end)
    end)

    local itemInfo = ItemData.GetItemInfo(ITEM_TABLE_TYPE.OTHER, self.nItemTabID)
    local szName = ItemData.GetItemNameByItem(itemInfo)
    szName = UIHelper.GBKToUTF8(szName)
    UIHelper.SetString(self.LabelName1, szName)
    UIHelper.SetString(self.LabelName2, szName)

    local szItemDesc = ItemData.GetItemDesc(itemInfo.nUiId)
    szDesc = ParseTextHelper.ParseNormalText(szItemDesc, true)
    szDesc = string.gsub(szDesc, "\n", "")
    UIHelper.SetString(self.LabelAttri1, szDesc)
    UIHelper.SetString(self.LabelAttri2, szDesc)

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollView1)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollView2)
end

function UICustomizedSetPowerUpSelectMaterialCell:SetSelectedTabID(nItemTabID)
    UIHelper.SetSelected(self.TogFilterItem, nItemTabID == self.nItemTabID)
end

return UICustomizedSetPowerUpSelectMaterialCell
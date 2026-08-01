-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIBookItem
-- Date: 2022-12-09 10:31:03
-- Desc: ?
-- ---------------------------------------------------------------------------------

---@class UIWidgetMysteryItemCell
local UIWidgetMysteryItemCell = class("UIWidgetMysteryItemCell")

function UIWidgetMysteryItemCell:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIWidgetMysteryItemCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetMysteryItemCell:BindUIEvent()

end

function UIWidgetMysteryItemCell:RegEvent()
    Event.Reg(self, EventType.OnSetUIItemIconChoose, function(bSelected, dwPendantIndex, nCount)
        if not dwPendantIndex or (dwPendantIndex == self.dwPendantIndex) then
            if bSelected then
                UIHelper.SetVisible(self.ImgChooseNum, true)
                UIHelper.SetVisible(self.LabelChooseNum, true)
                UIHelper.SetString(self.LabelChooseNum, tostring(nCount))
            else
                UIHelper.SetVisible(self.ImgChooseNum, false)
                UIHelper.SetVisible(self.LabelChooseNum, false)
            end
        end
    end)
end

function UIWidgetMysteryItemCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetMysteryItemCell:Init(dwTabType, dwIndex, dwPendantIndex)
    self.dwTabType = dwTabType
    self.dwIndex = dwIndex
    self.dwPendantIndex = dwPendantIndex
    self.nSelectGroupIndex = -1

    local itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.WidgetItem)
    itemScript:OnInitWithTabID(dwTabType, dwIndex)
    itemScript:SetSelectEnable(false)

    local tItemInfo = ItemData.GetItemInfo(dwTabType, dwIndex)
    --local bIsNewItem = ItemData.IsNewItem(tbItemInfo.hItem.dwID)
    UIHelper.SetString(self.LabelItemName, UIHelper.GBKToUTF8(tItemInfo.szName))
end

function UIWidgetMysteryItemCell:SetToggleGroup(toggleGroup)
    if self.ToggleGroup then
        UIHelper.ToggleGroupRemoveToggle(self.ToggleGroup, self.Toggle)
        self.ToggleGroup = nil
    end
    
    UIHelper.ToggleGroupAddToggle(toggleGroup, self.Toggle)
    self.ToggleGroup = toggleGroup
end

function UIWidgetMysteryItemCell:SetSelectMode(bBatch, bHideCheck)
    if self.bBatch and bBatch then
        return
    end

    if not self.bBatch and not bBatch then
        return
    end

    self.bBatch = bBatch
    UIHelper.SetVisible(self.WidgetMultiSelect, bBatch and not bHideCheck)

    if bBatch then
        UIHelper.SetToggleGroupIndex(self.Toggle, -1)
        if UIHelper.GetSelected(self.Toggle) then
            UIHelper.SetSelected(self.Toggle, false)
        end
        if self.ToggleGroup then
            UIHelper.ToggleGroupRemoveToggle(self.ToggleGroup, self.Toggle)
        end
    else
        UIHelper.SetToggleGroupIndex(self.Toggle, self.nSelectGroupIndex)
        if UIHelper.GetSelected(self.Toggle) then
            UIHelper.SetSelected(self.Toggle, false)
        end
        if self.ToggleGroup then
            UIHelper.ToggleGroupAddToggle(self.ToggleGroup, self.Toggle)
        end
    end
end

function UIWidgetMysteryItemCell:SetSelectChangeCallback(fnCallBack)
    UIHelper.BindUIEvent(self.Toggle, EventType.OnSelectChanged, fnCallBack)
end

function UIWidgetMysteryItemCell:SetEquipped(bEquipped)
    UIHelper.SetVisible(self.ImgEquipped, bEquipped)
end

function UIWidgetMysteryItemCell:SetSelected(bSelected)
    UIHelper.SetSelected(self.Toggle, bSelected, true)
end

function UIWidgetMysteryItemCell:HideBatchNum()
    UIHelper.SetVisible(self.ImgChooseNum, false)
    UIHelper.SetVisible(self.LabelChooseNum, false)
end

return UIWidgetMysteryItemCell
-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICustomizedSetPowerUpSelectWuCaiCell
-- Date: 2024-08-08 17:21:23
-- Desc: WidgetMaterialCellWuCai
-- ---------------------------------------------------------------------------------

local UICustomizedSetPowerUpSelectWuCaiCell = class("UICustomizedSetPowerUpSelectWuCaiCell")

function UICustomizedSetPowerUpSelectWuCaiCell:OnInitWithCount(szName, nCount, nMax)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.bCount = true
    local szCount = (nCount and nMax) and (nCount .. "/" .. nMax) or ""

    UIHelper.SetString(self.LabelName1, szName)
    UIHelper.SetString(self.LabelName2, szName)
    UIHelper.SetString(self.LabelCount1, szCount)
    UIHelper.SetString(self.LabelCount2, szCount)
    UIHelper.SetVisible(self.WidgetAttr, false)
    UIHelper.SetVisible(self.WidgetWuCai, false)
    UIHelper.SetVisible(self.WidgetCount, true)
    Timer.AddFrame(self, 1, function()
        UIHelper.SetSelected(self.TogFilterItem, false, false)
    end)
end

function UICustomizedSetPowerUpSelectWuCaiCell:OnEnter(tbInfo, bAttri)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.bAttri = bAttri
    self.tbInfo = tbInfo
    self:UpdateInfo()
end

function UICustomizedSetPowerUpSelectWuCaiCell:OnExit()
    self.bInit = false
end

function UICustomizedSetPowerUpSelectWuCaiCell:BindUIEvent()
    UIHelper.BindUIEvent(self.TogFilterItem, EventType.OnSelectChanged, function(_, bSelected)
        if self.funcSelectedCallback then
            self.funcSelectedCallback(bSelected)
            return
        end
    end)

    UIHelper.BindUIEvent(self.TogFilterItem, EventType.OnClick, function(btn)
        Event.Dispatch(EventType.OnSelectCustomizedSetWuCaiCell, self.tbInfo, self.bAttri)
    end)
end

function UICustomizedSetPowerUpSelectWuCaiCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UICustomizedSetPowerUpSelectWuCaiCell:UpdateInfo()
    UIHelper.SetVisible(self.WidgetAttr, self.bAttri)
    UIHelper.SetVisible(self.WidgetWuCai, not self.bAttri)

    UIHelper.SetSelected(self.TogFilterItem, false)

    if self.bAttri then
        local szAttriName = self.tbInfo.szName
        UIHelper.SetString(self.LabelAttriName1, szAttriName)
        UIHelper.SetString(self.LabelAttriName2, szAttriName)
    else
        local szItemName = self.tbInfo.szName
        UIHelper.SetString(self.LabelFilterItem1, szItemName)
        UIHelper.SetString(self.LabelFilterItem2, szItemName)

        self.scriptItem = self.scriptItem or UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, self.WidgetItem44)
        self.scriptItem:SetClickNotSelected(true)

        self.scriptItem:OnInitWithTabID(ITEM_TABLE_TYPE.OTHER, self.tbInfo.dwItemID)
        self.scriptItem:SetSelectEnable(true)
        self.scriptItem:SetClickCallback(function()
            Timer.AddFrame(self, 1, function()
                TipsHelper.ShowItemTips(self.WidgetItem44, ITEM_TABLE_TYPE.OTHER, self.tbInfo.dwItemID, false, TipsLayoutDir.LEFT_CENTER)
            end)
        end)
        UIHelper.SetSelected(self.TogFilterItem, self.tbInfo.nCurSelectItemID == self.tbInfo.dwItemID)
    end
end

function UICustomizedSetPowerUpSelectWuCaiCell:SetSelectedCallback(func)
    self.funcSelectedCallback = func
end

return UICustomizedSetPowerUpSelectWuCaiCell
-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICoinShopFilterItem
-- Date: 2022-12-23 10:36:33
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICoinShopFilterItem = class("UICoinShopFilterItem")

function UICoinShopFilterItem:OnEnter(tData)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tData = tData
    self:UpdateInfo()
end

function UICoinShopFilterItem:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UICoinShopFilterItem:BindUIEvent()
    UIHelper.BindUIEvent(self.TogPitchBg, EventType.OnSelectChanged, function(_, bSelected)
        if self.tData.nMutexID and self.tData.nMutexID > 0 then
            Event.Dispatch(EventType.OnCoinShopFilterMutexChanged, self.tData.nMutexID, bSelected)
        end
    end)
end

function UICoinShopFilterItem:RegEvent()
    Event.Reg(self, EventType.OnCoinShopFilterMutexChanged, function(nMutexID, bOn)
        if self.tData.nRelateMutexID and self.tData.nRelateMutexID == nMutexID then
            self:SetEnable(not bOn)
        end
    end)
end

function UICoinShopFilterItem:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICoinShopFilterItem:UpdateInfo()
    UIHelper.SetString(self.LabelDesc, self.tData.szOption)
    UIHelper.SetSwallowTouches(self.TogPitchBg, false)
    self:SetEnable(not self.tData.bDisable)
end

function UICoinShopFilterItem:SetEnable(bEnable)
    UIHelper.SetNodeGray(self._rootNode, not bEnable, true)
    UIHelper.SetEnable(self.TogPitchBg, bEnable)
end

return UICoinShopFilterItem
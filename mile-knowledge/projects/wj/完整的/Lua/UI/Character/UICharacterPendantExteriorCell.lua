-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICharacterPendantExteriorCell
-- Date: 2023-03-01 19:33:17
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICharacterPendantExteriorCell = class("UICharacterPendantExteriorCell")

function UICharacterPendantExteriorCell:OnEnter(tbInfo)
    self.tbInfo = tbInfo

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UICharacterPendantExteriorCell:OnExit()
    self.bInit = false
end

function UICharacterPendantExteriorCell:BindUIEvent()
    UIHelper.BindUIEvent(self.TogPreset, EventType.OnClick, function()
        if self.funcClickCallback then
            self.funcClickCallback()
        end
    end)
end

function UICharacterPendantExteriorCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UICharacterPendantExteriorCell:UpdateInfo()
    UIHelper.SetString(self.LabelPresetName, self.tbInfo.szName)
    UIHelper.SetString(self.LabelPresetName02, self.tbInfo.szName)

    self:UpdateOutfitStorageState()
end

function UICharacterPendantExteriorCell:SetClickCallback(callback)
    self.funcClickCallback = callback
end

function UICharacterPendantExteriorCell:SetSelected(bSelected)
    UIHelper.SetSelected(self.TogPreset, bSelected)
end

function UICharacterPendantExteriorCell:SetVisible(bVisible)
    UIHelper.SetVisible(self._rootNode, bVisible)
end

function UICharacterPendantExteriorCell:UpdateOutfitStorageState()
    UIHelper.SetVisible(self.ImgOnCloud, self.tbInfo.bServer)
end

return UICharacterPendantExteriorCell
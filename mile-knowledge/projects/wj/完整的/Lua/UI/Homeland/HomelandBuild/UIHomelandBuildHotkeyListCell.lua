-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandBuildHotkeyListCell
-- Date: 2024-04-10 10:39:39
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandBuildHotkeyListCell = class("UIHomelandBuildHotkeyListCell")

function UIHomelandBuildHotkeyListCell:OnEnter(tbKeys)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbKeys = tbKeys
    self:UpdateInfo()
end

function UIHomelandBuildHotkeyListCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHomelandBuildHotkeyListCell:BindUIEvent()

end

function UIHomelandBuildHotkeyListCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelandBuildHotkeyListCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHomelandBuildHotkeyListCell:UpdateInfo()
    local tbKeys = self.tbKeys
    for i, key in ipairs(tbKeys) do
        UIHelper.SetString(self["LabelTitle"..i], key.szTitle)
        UIHelper.SetRichText(self["RichTextContent"..i], key.szContent)
    end
    UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)
end


return UIHomelandBuildHotkeyListCell
-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetFilterScreenItemPermissions
-- Date: 2023-01-09 12:39:56
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetFilterScreenItemPermissions = class("UIWidgetFilterScreenItemPermissions")

function UIWidgetFilterScreenItemPermissions:OnEnter(tbInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbInfo = tbInfo
    self:UpdateInfo()
end

function UIWidgetFilterScreenItemPermissions:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetFilterScreenItemPermissions:BindUIEvent()
    
end

function UIWidgetFilterScreenItemPermissions:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetFilterScreenItemPermissions:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetFilterScreenItemPermissions:UpdateInfo()
    UIHelper.SetString(self.LabelFilterScreenItem, self.tbInfo.szName)
    UIHelper.SetString(self.LabelFilterScreenItem01, self.tbInfo.szName)
end

function UIWidgetFilterScreenItemPermissions:GetSelected()
    return UIHelper.GetSelected(self.TogFilterScreenItem)
end

function UIWidgetFilterScreenItemPermissions:GetGroupIndex()
    return self.tbInfo.nGroupIndex
end

return UIWidgetFilterScreenItemPermissions
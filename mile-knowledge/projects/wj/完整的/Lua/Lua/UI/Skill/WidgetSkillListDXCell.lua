-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetAcupointTip
-- Date: 2022-11-14 19:57:23
-- Desc: ?
-- ---------------------------------------------------------------------------------


---@class WidgetSkillListDXCell
local WidgetSkillListDXCell = class("WidgetSkillListDXCell")

function WidgetSkillListDXCell:OnEnter(dwKungFuID, nSkillID, nSkillLevel)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()

        self.dwKungFuID = dwKungFuID
        self.nSkillID = nSkillID
        self.nSkillLevel = nSkillLevel

        self:UpdateInfo()
    end
end

function WidgetSkillListDXCell:OnExit()
    self.bInit = false
    Event.UnRegAll(self)
end

function WidgetSkillListDXCell:BindUIEvent()
end

function WidgetSkillListDXCell:RegEvent()

end

function WidgetSkillListDXCell:UpdateInfo()
    
end

return WidgetSkillListDXCell

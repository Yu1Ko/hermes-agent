-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetSkillConfigurationCell
-- Date: 2022-11-23 10:01:29
-- Desc: ?
-- ---------------------------------------------------------------------------------
---@class UIWidgetCombatCommonCell
local UIWidgetCombatCommonCell = class("UIWidgetCombatCommonCell")

function UIWidgetCombatCommonCell:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        
    end
    self:UpdateInfo()
end

function UIWidgetCombatCommonCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetCombatCommonCell:BindUIEvent()

end

function UIWidgetCombatCommonCell:RegEvent()

end

function UIWidgetCombatCommonCell:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetCombatCommonCell:UpdateInfo()
 
end

return UIWidgetCombatCommonCell
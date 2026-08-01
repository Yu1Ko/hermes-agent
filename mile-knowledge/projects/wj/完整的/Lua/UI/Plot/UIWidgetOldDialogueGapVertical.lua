-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetOldDialogueGapVertical
-- Date: 2023-05-16 11:16:11
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetOldDialogueGapVertical = class("UIWidgetOldDialogueGapVertical")

function UIWidgetOldDialogueGapVertical:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIWidgetOldDialogueGapVertical:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetOldDialogueGapVertical:BindUIEvent()
    
end

function UIWidgetOldDialogueGapVertical:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetOldDialogueGapVertical:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetOldDialogueGapVertical:UpdateInfo()
    
end


return UIWidgetOldDialogueGapVertical
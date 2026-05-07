-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetOldDialogueGapHorizontal
-- Date: 2023-05-15 16:03:01
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetOldDialogueGapHorizontal = class("UIWidgetOldDialogueGapHorizontal")

function UIWidgetOldDialogueGapHorizontal:OnEnter(tbData)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIWidgetOldDialogueGapHorizontal:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetOldDialogueGapHorizontal:BindUIEvent()
    
end

function UIWidgetOldDialogueGapHorizontal:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetOldDialogueGapHorizontal:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetOldDialogueGapHorizontal:UpdateInfo()
    
end


return UIWidgetOldDialogueGapHorizontal
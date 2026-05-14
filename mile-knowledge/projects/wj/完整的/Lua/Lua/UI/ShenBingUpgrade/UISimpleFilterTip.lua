-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UISimpleFilterTip
-- Date: 2024-04-22 21:03:42
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UISimpleFilterTip = class("UISimpleFilterTip")

function UISimpleFilterTip:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UISimpleFilterTip:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UISimpleFilterTip:BindUIEvent()

end

function UISimpleFilterTip:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UISimpleFilterTip:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UISimpleFilterTip:UpdateInfo()

end


return UISimpleFilterTip
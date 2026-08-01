-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIXiaoChengWuProgressCell
-- Date: 2024-04-22 13:33:07
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIXiaoChengWuProgressCell = class("UIXiaoChengWuProgressCell")


function UIXiaoChengWuProgressCell:OnEnter(nState)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nState = nState
end

function UIXiaoChengWuProgressCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIXiaoChengWuProgressCell:BindUIEvent()

end

function UIXiaoChengWuProgressCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIXiaoChengWuProgressCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIXiaoChengWuProgressCell:UpdateInfo()

end


return UIXiaoChengWuProgressCell
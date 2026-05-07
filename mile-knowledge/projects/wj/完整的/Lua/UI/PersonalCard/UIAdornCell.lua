-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIAdornCell
-- Date: 2024-02-01 15:12:49
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIAdornCell = class("UIAdornCell")

function UIAdornCell:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIAdornCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIAdornCell:BindUIEvent()

end

function UIAdornCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIAdornCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIAdornCell:UpdateInfo()

end


return UIAdornCell
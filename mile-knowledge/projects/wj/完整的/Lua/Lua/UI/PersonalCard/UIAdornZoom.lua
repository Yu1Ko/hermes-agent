-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIAdornZoom
-- Date: 2024-02-01 16:25:07
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIAdornZoom = class("UIAdornZoom")

function UIAdornZoom:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIAdornZoom:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIAdornZoom:BindUIEvent()

end

function UIAdornZoom:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIAdornZoom:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIAdornZoom:UpdateInfo()

end


return UIAdornZoom
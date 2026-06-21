-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIJinXiuTask
-- Date: 2023-09-05 11:24:16
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIJinXiuTask = class("UIJinXiuTask")

function UIJinXiuTask:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIJinXiuTask:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIJinXiuTask:BindUIEvent()

end

function UIJinXiuTask:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIJinXiuTask:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIJinXiuTask:UpdateInfo()

end


return UIJinXiuTask
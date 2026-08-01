-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIJinXiuReward
-- Date: 2023-09-05 11:25:01
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIJinXiuReward = class("UIJinXiuReward")

function UIJinXiuReward:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIJinXiuReward:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIJinXiuReward:BindUIEvent()

end

function UIJinXiuReward:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIJinXiuReward:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIJinXiuReward:UpdateInfo()

end


return UIJinXiuReward
-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIFengYuTongZhouRewardCell
-- Date: 2024-03-29 17:24:14
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIFengYuTongZhouRewardCell = class("UIFengYuTongZhouRewardCell")

function UIFengYuTongZhouRewardCell:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIFengYuTongZhouRewardCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIFengYuTongZhouRewardCell:BindUIEvent()

end

function UIFengYuTongZhouRewardCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIFengYuTongZhouRewardCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIFengYuTongZhouRewardCell:UpdateInfo()

end


return UIFengYuTongZhouRewardCell
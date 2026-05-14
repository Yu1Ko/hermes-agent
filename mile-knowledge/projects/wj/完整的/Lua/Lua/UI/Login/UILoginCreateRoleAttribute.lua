-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UILoginCreateRoleAttribute
-- Date: 2022-12-28 14:28:13
-- Desc: ?
-- ---------------------------------------------------------------------------------

local nAnimateFrame = 10
local UILoginCreateRoleAttribute = class("UILoginCreateRoleAttribute")

function UILoginCreateRoleAttribute:OnEnter(nStarNum)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    if nStarNum then
        self.nStarNum = nStarNum
        self:UpdateInfo()
    end
end

function UILoginCreateRoleAttribute:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UILoginCreateRoleAttribute:BindUIEvent()
    
end

function UILoginCreateRoleAttribute:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UILoginCreateRoleAttribute:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UILoginCreateRoleAttribute:UpdateInfo()

    if self.nAniTimer then
        Timer.DelTimer(self, self.nAniTimer)
        self.nAniTimer = nil
    end

    local nProgressBarPercent = UIHelper.GetProgressBarPercent(self._rootNode)
    local nStep = (self.nStarNum - nProgressBarPercent) / nAnimateFrame
    self.nCurTime = 0 --当前循环了多少次
    self.nAniTimer = Timer.AddFrameCycle(self, 1, function()
        nProgressBarPercent = UIHelper.GetProgressBarPercent(self._rootNode)
        UIHelper.SetProgressBarPercent(self._rootNode, nProgressBarPercent + nStep)
        self.nCurTime = self.nCurTime + 1 
        if self.nCurTime == nAnimateFrame then
            Timer.DelTimer(self, self.nAniTimer)
            self.nAniTimer = nil
        end
    end)
end


return UILoginCreateRoleAttribute
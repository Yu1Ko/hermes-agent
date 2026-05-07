-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UITransition
-- Date: 2023-02-16 17:20:00
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UITransition = class("UITransition")

function UITransition:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        self:UpdateInfo()
    end
end

function UITransition:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UITransition:BindUIEvent()
    
end

function UITransition:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UITransition:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITransition:UpdateInfo()
    UIHelper.PlayAni(self, self.AniAll, "AniTransitionHide", function()
        Timer.AddCountDown(self, Const.FullScreenTransitionTime, function () end, function ()
            UIHelper.PlayAni(self, self.AniAll, "AniTransitionShow",function()
                UIMgr.Close(self)
            end)
        end)
    end)
end


return UITransition
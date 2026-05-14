-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIGMBuffDebugView
-- Date: 2022-12-23 10:14:31
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIGMBuffDebugView = class("UIGMBuffDebugView")

function UIGMBuffDebugView:OnEnter(tbBuffDebugFrame)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbBuffDebugFrame = tbBuffDebugFrame
    self.BuffDebugTimer = Timer.AddFrameCycle(self, 1, function ()
                                        self:UpdateInfo()
                                    end)
end

function UIGMBuffDebugView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelTimer(self, self.BuffDebugTimer)
    self.tbBuffDebugFrame.bHasView = false
end

function UIGMBuffDebugView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnBuffDebug, EventType.OnTouchMoved, function(btn, nX, nY)
        local nLocalX, nLocalY = UIHelper.ConvertToNodeSpace(UIHelper.GetParent(btn), nX, nY)
        UIHelper.SetPosition(self.BtnBuffDebug, nLocalX, nLocalY)
    end)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)
end

function UIGMBuffDebugView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIGMBuffDebugView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIGMBuffDebugView:UpdateInfo()
    self.tbBuffDebugFrame.OnFrameBreathe(self)
end


return UIGMBuffDebugView
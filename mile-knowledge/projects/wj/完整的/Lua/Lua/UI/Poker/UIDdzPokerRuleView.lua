-- ---------------------------------------------------------------------------------
-- Author: zeng zi peng
-- Name: UIDdzPokerRuleView
-- Date: 2023-08-21 16:42:34
-- Desc: 斗地主规则界面
-- ---------------------------------------------------------------------------------

local UIDdzPokerRuleView = class("UIDdzPokerRuleView")

function UIDdzPokerRuleView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UIDdzPokerRuleView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIDdzPokerRuleView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)
end

function UIDdzPokerRuleView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIDdzPokerRuleView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIDdzPokerRuleView:UpdateInfo()
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewRuleList)
end


return UIDdzPokerRuleView
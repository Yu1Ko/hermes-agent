-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelBahuangRulesLittle
-- Date: 2024-05-10 10:10:19
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPanelBahuangRulesLittle = class("UIPanelBahuangRulesLittle")

function UIPanelBahuangRulesLittle:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UIPanelBahuangRulesLittle:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelBahuangRulesLittle:BindUIEvent()
    -- UIHelper.BindUIEvent(self.)
end

function UIPanelBahuangRulesLittle:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIPanelBahuangRulesLittle:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelBahuangRulesLittle:UpdateInfo()
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewBattleRules)
end


return UIPanelBahuangRulesLittle
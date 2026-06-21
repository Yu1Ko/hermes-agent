-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetBattleFieldRules
-- Date: 2023-03-28 20:27:33
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetBattleFieldRules = class("UIWidgetBattleFieldRules")

function UIWidgetBattleFieldRules:OnEnter(szTitle, szContent)
    self.szTitle = szTitle
    self.szContent = szContent

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIWidgetBattleFieldRules:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetBattleFieldRules:BindUIEvent()
    
end

function UIWidgetBattleFieldRules:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetBattleFieldRules:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetBattleFieldRules:UpdateInfo()
    UIHelper.SetString(self.LabelBattleRulesTitle, self.szTitle)
    UIHelper.SetString(self.LabelBattleRules, self.szContent)
    --UIHelper.LayoutDoLayout(self._rootNode)
end


return UIWidgetBattleFieldRules
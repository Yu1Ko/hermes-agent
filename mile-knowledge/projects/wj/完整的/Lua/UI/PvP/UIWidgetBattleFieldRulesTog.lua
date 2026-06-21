-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIWidgetBattleFieldRulesTog
-- Date: 2023-03-28 16:15:02
-- Desc: WidgetBattleFieldRulesTog
-- ---------------------------------------------------------------------------------

local UIWidgetBattleFieldRulesTog = class("UIWidgetBattleFieldRulesTog")

function UIWidgetBattleFieldRulesTog:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIWidgetBattleFieldRulesTog:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetBattleFieldRulesTog:BindUIEvent()
    UIHelper.BindUIEvent(self.TogSelect, EventType.OnSelectChanged, function(_, bSelected)
        if self.fnSelectedCallback then
            self.fnSelectedCallback(bSelected)
        end
    end)
end

function UIWidgetBattleFieldRulesTog:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetBattleFieldRulesTog:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetBattleFieldRulesTog:SetText(szText)
    UIHelper.SetString(self.LabelNormal, szText)
    UIHelper.SetString(self.LabelUp, szText)
end

function UIWidgetBattleFieldRulesTog:SetSelectedCallback(fnSelectedCallback)
    self.fnSelectedCallback = fnSelectedCallback
end

function UIWidgetBattleFieldRulesTog:SetSelected(bSelected, bIgnoreCallback)
    UIHelper.SetSelected(self.TogSelect, bSelected, not bIgnoreCallback)
end

function UIWidgetBattleFieldRulesTog:RegisterToggleGroup(toggleGroup)
    UIHelper.ToggleGroupAddToggle(toggleGroup, self.TogSelect)
end

return UIWidgetBattleFieldRulesTog
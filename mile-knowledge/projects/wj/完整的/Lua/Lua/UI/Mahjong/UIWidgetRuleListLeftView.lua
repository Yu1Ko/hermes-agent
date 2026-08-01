-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetRuleListLeftView
-- Date: 2023-08-08 15:09:07
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetRuleListLeftView = class("UIWidgetRuleListLeftView")

function UIWidgetRuleListLeftView:OnEnter(szTitle, nIndex, scriptRule)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.szTitle = szTitle
    self.nIndex = nIndex
    self.scriptRule = scriptRule
    self:UpdateInfo()
end

function UIWidgetRuleListLeftView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetRuleListLeftView:BindUIEvent()
    UIHelper.BindUIEvent(self.TogRuleList, EventType.OnSelectChanged, function(toggle, bSelect)
        if bSelect and self.nIndex ~= 3 then
            local szText = g_tStrings.tMahjongRule[self.nIndex]
            self.scriptRule:UpdateText(szText)
        elseif bSelect and self.nIndex == 3 then
            self.scriptRule:ShowSpecialRule()
        end
    end)
end

function UIWidgetRuleListLeftView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetRuleListLeftView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetRuleListLeftView:UpdateInfo()
    UIHelper.SetString(self.LabelNormal, self.szTitle)
    UIHelper.SetString(self.LabelSelect, self.szTitle)
    if self.nIndex == 1 then
        UIHelper.SetSelected(self.TogRuleList, true)
    end
end


return UIWidgetRuleListLeftView
-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIWidgetPersonalTitleTog
-- Date: 2023-03-09 09:58:04
-- Desc: WidgetPersonalTitleTog
-- ---------------------------------------------------------------------------------

local UIWidgetPersonalTitleTog = class("UIWidgetPersonalTitleTog")

function UIWidgetPersonalTitleTog:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIWidgetPersonalTitleTog:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetPersonalTitleTog:BindUIEvent()
    UIHelper.BindUIEvent(self.TogSkill, EventType.OnSelectChanged, function(_, bSelected)
        if self.fnSelectedCallback then
            self.fnSelectedCallback(bSelected)
        end
    end)
end

function UIWidgetPersonalTitleTog:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetPersonalTitleTog:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetPersonalTitleTog:RegisterToggleGroup(toggleGroup)
    UIHelper.ToggleGroupAddToggle(toggleGroup, self.TogSkill)
end

function UIWidgetPersonalTitleTog:SetSelectedCallback(fnSelectedCallback)
    self.fnSelectedCallback = fnSelectedCallback
end

function UIWidgetPersonalTitleTog:SetText(szText)
    UIHelper.SetString(self.LabelSkillName, szText)
    UIHelper.SetString(self.LabelSelectSkillName, szText)
end

function UIWidgetPersonalTitleTog:SetNumberText(szNumber)
    UIHelper.SetString(self.LabelSkillLevel, szNumber)
    UIHelper.SetString(self.LabelSelectSkillLevel, szNumber)
end


return UIWidgetPersonalTitleTog
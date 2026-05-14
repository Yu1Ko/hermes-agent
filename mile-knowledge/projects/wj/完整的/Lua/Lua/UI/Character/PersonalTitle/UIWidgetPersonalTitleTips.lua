-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIWidgetPersonalTitleTips
-- Date: 2023-03-09 09:57:40
-- Desc: WidgetPersonalTitleTips
-- ---------------------------------------------------------------------------------

local UIWidgetPersonalTitleTips = class("UIWidgetPersonalTitleTips")

function UIWidgetPersonalTitleTips:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    UIHelper.SetSwallowTouches(self.TogPitchBg, false)
end

function UIWidgetPersonalTitleTips:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetPersonalTitleTips:BindUIEvent()
    UIHelper.BindUIEvent(self.TogPitchBg, EventType.OnSelectChanged, function(_, bSelected)
        if self.fnSelectedCallback then
            self.fnSelectedCallback(bSelected)
        end
    end)
end

function UIWidgetPersonalTitleTips:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetPersonalTitleTips:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetPersonalTitleTips:RegisterToggleGroup(toggleGroup)
    UIHelper.ToggleGroupAddToggle(toggleGroup, self.TogPitchBg)
end

function UIWidgetPersonalTitleTips:SetSelectedCallback(fnSelectedCallback)
    self.fnSelectedCallback = fnSelectedCallback
end

function UIWidgetPersonalTitleTips:SetText(szText)
    UIHelper.SetString(self.LabelContent, szText)
end


return UIWidgetPersonalTitleTips
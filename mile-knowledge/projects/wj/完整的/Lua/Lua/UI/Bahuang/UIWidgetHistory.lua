-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetHistory
-- Date: 2024-01-01 19:08:47
-- Desc: 八荒主界面生涯、战绩、技能列表等控制
-- ---------------------------------------------------------------------------------

local UIWidgetHistory = class("UIWidgetHistory")

function UIWidgetHistory:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UIWidgetHistory:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetHistory:BindUIEvent()
    UIHelper.BindUIEvent(self.ToggleGroupLeftNav, EventType.OnToggleGroupSelectedChanged, function(toggle, index)
        for nIndex, page in ipairs(self.tbPage) do
            UIHelper.SetVisible(page, nIndex == (index + 1))
        end
    end)
end

function UIWidgetHistory:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetHistory:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetHistory:UpdateInfo()
    for nIndex, toggle in ipairs(self.tbToggleLeftNav) do
        UIHelper.ToggleGroupAddToggle(self.ToggleGroupLeftNav, toggle)
    end
    UIHelper.SetToggleGroupSelected(self.ToggleGroupLeftNav, 0)
end

return UIWidgetHistory
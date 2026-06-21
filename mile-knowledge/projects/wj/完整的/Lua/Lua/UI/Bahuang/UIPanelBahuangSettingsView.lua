-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelBahuangSettingsView
-- Date: 2024-01-01 16:59:08
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPanelBahuangSettingsView = class("UIPanelBahuangSettingsView")

function UIPanelBahuangSettingsView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UIPanelBahuangSettingsView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelBahuangSettingsView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.ToggleGroupTabList, EventType.OnToggleGroupSelectedChanged, function(toggle, nIndex)
        UIHelper.SetVisible(self.WidgetAnchorLabelSetting, nIndex == 0)
        UIHelper.SetVisible(self.WidgetAnchorAutoSkillSetting, nIndex == 1)
    end)

    UIHelper.BindUIEvent(self.ToggleAutoFightSwitch, EventType.OnSelectChanged, function(_, bSelect)
        BahuangData.SetAutoCastAllSkill(bSelect)
    end)
end

function UIPanelBahuangSettingsView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIPanelBahuangSettingsView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelBahuangSettingsView:UpdateInfo()

    UIHelper.ToggleGroupAddToggle(self.ToggleGroupTabList, self.TogTabList01)
    UIHelper.ToggleGroupAddToggle(self.ToggleGroupTabList, self.TogTabList02)

    UIHelper.SetToggleGroupSelected(self.ToggleGroupTabList, 0)

    UIHelper.SetSelected(self.ToggleAutoFightSwitch, BahuangData.IsAutoCastAllSkill(), true)
end


return UIPanelBahuangSettingsView
-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetBahuangSkillSettingView
-- Date: 2024-01-02 10:15:32
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetBahuangSkillSettingView = class("UIWidgetBahuangSkillSettingView")

function UIWidgetBahuangSkillSettingView:OnEnter(tbSettingList, scriptTextSettingView, toggleGroup, nIndex)
    self.toggleGroup = toggleGroup
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbSettingList = tbSettingList
    self.scriptTextSettingView = scriptTextSettingView
    self.nIndex = nIndex
    self:UpdateInfo()
end

function UIWidgetBahuangSkillSettingView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetBahuangSkillSettingView:BindUIEvent()
    UIHelper.BindUIEvent(self.toggleGroup, EventType.OnToggleGroupSelectedChanged, function(toggle, nIndex)
        Event.Dispatch(EventType.OnSelectSkillSetting)
    end)
end

function UIWidgetBahuangSkillSettingView:RegEvent()
    Event.Reg(self, EventType.OnSelectSkillSetting, function()
        local nIndex = UIHelper.GetToggleGroupSelectedIndex(self.toggleGroup)
        UIHelper.SetVisible(self.scriptSettingSwitch._rootNode, (self.nIndex - 1) == nIndex)
        self:LayoutDolayout(nIndex)
    end)
end

function UIWidgetBahuangSkillSettingView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetBahuangSkillSettingView:UpdateInfo()
    self.scriptSettingSwitch = UIHelper.AddPrefab(PREFAB_ID.WidgetBahuangSettingSwitch, self._rootNode, PREFAB_ID.WidgetBahuangSettingTogGroup, self.tbSettingList, nil, nil, self)
    local bSelect = UIHelper.GetSelected(self.TogHideSetting)
    UIHelper.SetVisible(self.scriptSettingSwitch._rootNode, bSelect)

    UIHelper.LayoutDoLayout(self._rootNode)
    UIHelper.ToggleGroupAddToggle(self.toggleGroup, self.TogHideSetting)
    UIHelper.SetString(self.LabelSkillType, g_tStrings.STR_ROUGELIKE_SKILL_TITLE[self.nIndex])
end

function UIWidgetBahuangSkillSettingView:GetIndex()
    return self.nIndex
end

function UIWidgetBahuangSkillSettingView:LayoutDolayout(nIndex)
    UIHelper.LayoutDoLayout(self._rootNode)
    self.scriptTextSettingView:ScrollViewDoLayout(nIndex)
end


return UIWidgetBahuangSkillSettingView
-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetBahuangSettingSwitchView
-- Date: 2024-01-01 17:39:10
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetBahuangSettingSwitchView = class("UIWidgetBahuangSettingSwitchView")

function UIWidgetBahuangSettingSwitchView:OnEnter(nPrefabID, tbSettingList, szSettingName, funcSetting, scriptSkillSettingView)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nPrefabID = nPrefabID
    self.tbSettingList = tbSettingList
    self.szSettingName = szSettingName
    self.funcSetting = funcSetting
    self.scriptSkillSettingView = scriptSkillSettingView
    self:UpdateInfo()
end

function UIWidgetBahuangSettingSwitchView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetBahuangSettingSwitchView:BindUIEvent()
    UIHelper.BindUIEvent(self.ToggleFightDataSwitch, EventType.OnSelectChanged, function(_, bSelect)
        if self.funcSetting then 
            self.funcSetting(bSelect)
        end
        UIHelper.SetVisible(self.WidgetShow, not bSelect)
        self:Dolayout()

        local nIndex = self.scriptSkillSettingView:GetIndex()
        self.scriptSkillSettingView:LayoutDolayout(nIndex)
    end)
end

function UIWidgetBahuangSettingSwitchView:RegEvent()
    
end

function UIWidgetBahuangSettingSwitchView:UnRegEvent()
    
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetBahuangSettingSwitchView:UpdateInfo()
    for nIndex, tbSettingInfo in ipairs(self.tbSettingList) do
        UIHelper.AddPrefab(self.nPrefabID, self.LayoutTogGroup, tbSettingInfo)
    end
    UIHelper.SetVisible(self.WidgetShow, #self.tbSettingList ~= 0)

    if self.szSettingName then
        UIHelper.SetString(self.LabelHideAll, self.szSettingName)
    end
    self:Dolayout()
end

function UIWidgetBahuangSettingSwitchView:Dolayout()
    UIHelper.LayoutDoLayout(self.LayoutTogGroup)
    UIHelper.LayoutDoLayout(self.WidgetShow)
    UIHelper.LayoutDoLayout(self._rootNode)
end

return UIWidgetBahuangSettingSwitchView
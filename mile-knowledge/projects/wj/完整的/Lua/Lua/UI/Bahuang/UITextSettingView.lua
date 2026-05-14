-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UITextSettingView
-- Date: 2024-01-02 10:44:27
-- Desc: ?
-- ---------------------------------------------------------------------------------
local tTypeList = {
    [1] = 4,--秘术
    [2] = 2,--秘技
    [3] = 3,--绝学
}

local UITextSettingView = class("UITextSettingView")

function UITextSettingView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UITextSettingView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UITextSettingView:BindUIEvent()
    UIHelper.BindUIEvent(self.ToggleFightDataSwitch, EventType.OnSelectChanged, function(_, bSelect)
        BahuangData.SetHideSkillText(bSelect)
    end)
end

function UITextSettingView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UITextSettingView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITextSettingView:UpdateInfo()
    local tNpcNameList = BahuangData.GetNPCNameVisibleList()
    for nIndex = 1, 3 do
        local nType = tTypeList[nIndex]
        local tbList = BahuangData.GetNPCNameVisibleListByType(nType)
        UIHelper.AddPrefab(PREFAB_ID.WidgetBahuangSkillSetting, self.ScrollViewGameSettings, tbList, self, self.ToggleGroupNormal, nIndex)
    end
    
    Timer.AddFrame(self, 1, function()
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewGameSettings)
    end)
    UIHelper.SetSelected(self.ToggleFightDataSwitch, BahuangData.IsHideSkillText(), false)
end

function UITextSettingView:ScrollViewDoLayout(nIndex)
    UIHelper.ScrollViewDoLayout(self.ScrollViewGameSettings)
    if nIndex then 
        UIHelper.ScrollToIndex(self.ScrollViewGameSettings, nIndex)
    end
end


return UITextSettingView
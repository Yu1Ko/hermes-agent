-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UISkillSettingView
-- Date: 2024-01-01 20:07:04
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UISkillSettingView = class("UISkillSettingView")

function UISkillSettingView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UISkillSettingView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UISkillSettingView:BindUIEvent()
    UIHelper.BindUIEvent(self.ToggleAutoFightSwitch, EventType.OnSelectChanged, function(_, bSelect)
        UIHelper.SetVisible(self.WidgetShow, not bSelect)
        UIHelper.LayoutDoLayout(self.LayoutSkillTog)
        UIHelper.LayoutDoLayout(self.WidgetShow)
        UIHelper.LayoutDoLayout(self.WidgetAutoFightSwitch)
        BahuangData.SetAutoCastAllSkill(bSelect)
    end)

    UIHelper.BindUIEvent(self.ToggleFightDataSwitch, EventType.OnSelectChanged, function(_, bSelect)
        BahuangData.SetEnableBreakFirstSkill(bSelect)
    end)
end

function UISkillSettingView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UISkillSettingView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UISkillSettingView:UpdateInfo()
    local tbSetting = {
        {szName = "心决", funcSetting = function(nIndex, bSelect) BahuangData.SetAutoCast(nIndex, bSelect) end},
        {szName = "秘技1", funcSetting = function(nIndex, bSelect) BahuangData.SetAutoCast(nIndex, bSelect) end},
        {szName = "秘技2", funcSetting = function(nIndex, bSelect) BahuangData.SetAutoCast(nIndex, bSelect) end},
        {szName = "秘技3", funcSetting = function(nIndex, bSelect) BahuangData.SetAutoCast(nIndex, bSelect) end},
        {szName = "秘技4", funcSetting = function(nIndex, bSelect) BahuangData.SetAutoCast(nIndex, bSelect) end},
        {szName = "绝学", funcSetting = function(nIndex, bSelect) BahuangData.SetAutoCast(nIndex, bSelect) end},
    }
    for nIndex, tbSettingInfo in ipairs(tbSetting) do
        UIHelper.AddPrefab(PREFAB_ID.WidgetBahuangSettingTog, self.LayoutSkillTog, tbSettingInfo, nIndex)
    end
    UIHelper.LayoutDoLayout(self.LayoutSkillTog)
    UIHelper.LayoutDoLayout(self.WidgetShow)
    UIHelper.LayoutDoLayout(self.WidgetAutoFightSwitch)

    for nIndex, img in ipairs(self.tbSkillImage) do
        local tbSkillInfo = BahuangData.GetSkillInfoByIndex(nIndex)
        if tbSkillInfo then 
            UIHelper.SetTexture(img, TabHelper.GetSkillIconPathByIDAndLevel(tbSkillInfo.dwSkillID, tbSkillInfo.nSkillLevel), nil, function()
                UIHelper.UpdateMask(self.tbMask[nIndex])
            end)
        end
    end

    UIHelper.SetSelected(self.ToggleFightDataSwitch, BahuangData.IsEnableBreakFirstSkill(), false)
    UIHelper.SetSelected(self.ToggleAutoFightSwitch, BahuangData.IsAutoCastAllSkill(), true)
end


return UISkillSettingView
-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetMiJiBtn
-- Date: 2022-11-14 19:57:23
-- Desc: ?
-- ---------------------------------------------------------------------------------

local SPECIAL_ORDER = 11

---@class UIPanelSkillAutoSettingPop
local UIPanelSkillAutoSettingPop = class("UIPanelSkillAutoSettingPop")
local tNames = {
    "壹式",
    "贰式",
    "叁式",
    "肆式",
}
function UIPanelSkillAutoSettingPop:OnEnter(tSkillIDList, fnApply)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nSelectedIndex = 1
    self:UpdateInfo(tSkillIDList, fnApply)
end

function UIPanelSkillAutoSettingPop:OnExit()
    self.bInit = false
    Event.UnRegAll(self)
end

function UIPanelSkillAutoSettingPop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
end

function UIPanelSkillAutoSettingPop:RegEvent()

end

function UIPanelSkillAutoSettingPop:UpdateInfo(tSkillIDList, fnApply)
    UIHelper.BindUIEvent(self.BtnSkillConfiguration, EventType.OnClick, function()
        fnApply(self.nSelectedIndex)
        UIMgr.Close(self)
    end)

    for nIndex, nSkillID in ipairs(tSkillIDList) do
        local nOrder = TabHelper.GetUISkillMap(nSkillID).nAppendSkillOrder
        local szName = nOrder >= SPECIAL_ORDER and "特殊" or tNames[nIndex]
        
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetSkillCell1, self.LayoutAutoSetting)
        script:UpdateInfo(nSkillID)
        script:SetNewName(szName)
        script:SetToggleGroup(self.ToggleGroup)
        script:BindSelectFunction(function()
            --self:ShowSkillTip(script:GetToggle(), nSkillID, TipsLayoutDir.TOP_CENTER)
            self.nSelectedIndex = nIndex
        end)
    end
end

return UIPanelSkillAutoSettingPop

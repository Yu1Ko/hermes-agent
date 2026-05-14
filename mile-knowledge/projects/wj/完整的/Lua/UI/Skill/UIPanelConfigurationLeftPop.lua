-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetSkillConfigurationCell
-- Date: 2022-11-23 10:01:29
-- Desc: ?
-- ---------------------------------------------------------------------------------
---@class UIPanelConfigurationLeftPop
local UIPanelConfigurationLeftPop = class("UIPanelConfigurationLeftPop")

function UIPanelConfigurationLeftPop:OnEnter(nSlotIndex, tSkillIDList, parentScript, fnClose)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        self.nSlotIndex = nSlotIndex
        self.tSkillIDList = tSkillIDList
        self.panelSkillScript = parentScript ---@type UIPanelSkillNew
        self.fnClose = fnClose ---@type UIPanelSkillNew
    end
    self:UpdateInfo()
end

function UIPanelConfigurationLeftPop:OnExit()
    if self.fnClose then
        self.fnClose()
    end
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelConfigurationLeftPop:BindUIEvent()

end

function UIPanelConfigurationLeftPop:RegEvent()

end

function UIPanelConfigurationLeftPop:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelConfigurationLeftPop:UpdateInfo()
    if self.nSlotIndex and self.panelSkillScript then
        UIHelper.RemoveAllChildren(self.ScrollViewSkillConfiguration)
        UIHelper.ToggleGroupRemoveAllToggle(self.ToggleGroup)

        local tSkillIDList = self.tSkillIDList
        local tSelectedSkillID = {}
        for i = 1, 5, 1 do
            tSelectedSkillID[i] = self.panelSkillScript:GetShowSkill(i)
        end

        local fnFirstCallback
        local nCurrentCount = 0
        for _, nSkillID in ipairs(tSkillIDList) do
            local bSelected = table.contain_value(tSelectedSkillID, nSkillID) -- 只有未装备技能和当前槽位装备的技能会出现在列表里
            local bCurrentSkill = self.panelSkillScript:GetShowSkill(self.nSlotIndex) == nSkillID
            if not bSelected or bCurrentSkill then
                local script = UIHelper.AddPrefab(PREFAB_ID.WidgetConfigurationPopCell, self.ScrollViewSkillConfiguration, nSkillID, bCurrentSkill)
                local callback = function(_nSkillID)
                    if g_pClientPlayer and g_pClientPlayer.bFightState then
                        return TipsHelper.ShowNormalTip("战斗状态下不可更换技能")
                    end

                    if bCurrentSkill then
                        self.panelSkillScript:UnEquipSkill(self.nSlotIndex)
                    else
                        self.panelSkillScript:ChangeSkill(self.nSlotIndex, _nSkillID)
                    end
                    UIMgr.Close(self)
                end

                UIHelper.ToggleGroupAddToggle(self.ToggleGroup, script:GetToggle())

                if tSelectedSkillID[self.nSlotIndex] == nSkillID then
                    UIHelper.SetToggleGroupSelected(self.ToggleGroup, nCurrentCount)
                    fnFirstCallback = function()
                        self:ShowSkillInfoTips(nSkillID, bCurrentSkill, callback)
                    end
                end

                script:SetCallback(function(_nSkillID)
                    self:ShowSkillInfoTips(_nSkillID, bCurrentSkill, callback)
                end)

                nCurrentCount = nCurrentCount + 1
            end
        end

        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewSkillConfiguration)
        if fnFirstCallback then
            fnFirstCallback()
        else
            local tog = UIHelper.ToggleGroupGetToggleByIndex(self.ToggleGroup, 0) -- 没有装备任何技能时去除选中状态
            UIHelper.SetSelected(tog,false)
        end
    end
end

function UIPanelConfigurationLeftPop:ShowSkillInfoTips(nSkillID, bCurrentSkill, callback)
    if self.tSkillInfoTips == nil then
        self.tSkillInfoTips = UIHelper.AddPrefab(PREFAB_ID.WidgetSkillInfoTips, self.WidgetTipContent, nSkillID, bCurrentSkill, callback,
                self.panelSkillScript.nCurrentKungFuID, self.panelSkillScript.nCurrentSetID)
    else
        self.tSkillInfoTips:OnEnter(nSkillID, bCurrentSkill, callback, self.panelSkillScript.nCurrentKungFuID, self.panelSkillScript.nCurrentSetID)
    end
end

function UIPanelConfigurationLeftPop:GetToggle()
    return self.TogSkill
end

return UIPanelConfigurationLeftPop
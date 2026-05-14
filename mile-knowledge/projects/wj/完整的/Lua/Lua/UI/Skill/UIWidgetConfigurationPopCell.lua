-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetSkillConfigurationCell
-- Date: 2022-11-23 10:01:29
-- Desc: ?
-- ---------------------------------------------------------------------------------
---@class UIWidgetConfigurationPopCell
local UIWidgetConfigurationPopCell = class("UIWidgetConfigurationPopCell")

function UIWidgetConfigurationPopCell:OnEnter(nSkillID, bSelected)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        self.nSkillID = nSkillID
        self.bSelected = bSelected
    end
    self:UpdateInfo()
end

function UIWidgetConfigurationPopCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetConfigurationPopCell:BindUIEvent()

end

function UIWidgetConfigurationPopCell:RegEvent()
    Event.Reg(self, "ON_SKILL_REPLACE", function(arg0, arg1, arg2)
        --LOG.WARN("ON_SKILL_REPLACE UIPanelSkillLeftPop")
        if arg0 == self.nSkillID then
            self.nSkillID = arg1
            self:UpdateInfo()
        end
    end)
end

function UIWidgetConfigurationPopCell:UnRegEvent()
    --Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetConfigurationPopCell:UpdateInfo()
    if self.nSkillID then
        local tSkillInfo = TabHelper.GetUISkill(self.nSkillID)
        local nSkillLevel = g_pClientPlayer.GetSkillLevel(self.nSkillID)
        if not nSkillLevel or nSkillLevel == 0 then
            nSkillLevel = 1
        end

        local szLevel = "等级" .. nSkillLevel
        UIHelper.SetString(self.LabelSkillLevel, szLevel)
        UIHelper.SetString(self.LabelSelectSkillLevel, szLevel)

        UIHelper.SetString(self.LabelSkillName, tSkillInfo.szName)
        UIHelper.SetString(self.LabelSelectSkillName, tSkillInfo.szName)

        UIHelper.SetVisible(self.ImgTagBg, self.bSelected)

        UIHelper.SetTexture(self.ImgSkillIcon, TabHelper.GetSkillIconPath(self.nSkillID))
        Timer.Add(self, 0.05, function ()
            UIHelper.UpdateMask(self.MaskSkill)
        end)

        UIHelper.SetString(self.LabelSelectSkillType, tSkillInfo.szSkillDefinition)
        UIHelper.SetString(self.LabelSkillType, tSkillInfo.szSkillDefinition)
    end
end

function UIWidgetConfigurationPopCell:GetToggle()
    return self.TogSkill
end


function UIWidgetConfigurationPopCell:SetCallback(fnCallback)
    UIHelper.BindUIEvent(self.TogSkill, EventType.OnSelectChanged, function(tog,bSelected)
        if bSelected then
            fnCallback(self.nSkillID)
        end
    end)
end


return UIWidgetConfigurationPopCell
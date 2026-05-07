-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetMiJiBtn
-- Date: 2022-11-14 19:57:23
-- Desc: ?
-- ---------------------------------------------------------------------------------

---@class UIWidgetSkillAttributeCell
local UIWidgetSkillAttributeCell = class("UIWidgetSkillAttributeCell")

function UIWidgetSkillAttributeCell:OnEnter(szName, tInfo, bIsSelected)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        self.szName = szName
        self.tInfo = tInfo
        self.bIsSelected = bIsSelected
    end

    self:UpdateInfo()
end

function UIWidgetSkillAttributeCell:OnExit()
    self.bInit = false
    Event.UnRegAll(self)
end

function UIWidgetSkillAttributeCell:BindUIEvent()
end

function UIWidgetSkillAttributeCell:RegEvent()

end

function UIWidgetSkillAttributeCell:UpdateInfo()
    local szFormattedText = self.tInfo.szDescription
    local szDesc
    if self.bIsSelected then
        szDesc = string.format("<color=#ffcf65>[%s]：</color>%s", self.szName, szFormattedText)
    else
        szDesc = string.format("[%s]：%s", self.szName, szFormattedText)
    end
    UIHelper.SetRichText(self.RichText, szDesc)
end

return UIWidgetSkillAttributeCell

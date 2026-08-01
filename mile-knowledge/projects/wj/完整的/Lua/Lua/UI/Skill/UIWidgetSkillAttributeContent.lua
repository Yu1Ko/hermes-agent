-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetAcupointTip
-- Date: 2022-11-14 19:57:23
-- Desc: ?
-- ---------------------------------------------------------------------------------

---@class UIWidgetSkillAttributeContent
local UIWidgetSkillAttributeContent = class("UIWidgetSkillAttributeContent")

local szActivated = "#D7F6FF"
local szUnActivated = "#86AEB4"

function UIWidgetSkillAttributeContent:OnEnter(szDesc, index, bUseTypeOne)
    if not self.bInit and szDesc then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        self.szKeyWord = szUnActivated
        if bUseTypeOne == true then
            self.szKeyWord = szActivated
        end
        
        szDesc = SkillData.ProcessSkillPlaceholder(szDesc)

        if szDesc ~= "" then
            szDesc = string.format("<color=%s>%s</color>", self.szKeyWord, szDesc)
            UIHelper.SetRichText(self.LabelName, szDesc)
            --UIHelper.SetVisible(self.ImgRankBg, index % 2 == 1)
            UIHelper.CascadeDoLayoutDoWidget(self._rootNode,  true,true)
        else
            UIHelper.SetVisible(self._rootNode, false)
        end
    end
end

function UIWidgetSkillAttributeContent:OnExit()
    self.bInit = false
    Event.UnRegAll(self)
end

function UIWidgetSkillAttributeContent:BindUIEvent()
end

function UIWidgetSkillAttributeContent:RegEvent()

end

return UIWidgetSkillAttributeContent

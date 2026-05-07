-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetAcupointTip
-- Date: 2022-11-14 19:57:23
-- Desc: ?
-- ---------------------------------------------------------------------------------

---@class UIWidgetSkillDescContent
local UIWidgetSkillDescContent = class("UIWidgetMiJiBtn")

local nMiJiIconPath = "UIAtlas2_Public_PublicIcon_PublicIcon1_mijiIcon.png"
local nQiXueIconPath = "UIAtlas2_Public_PublicIcon_PublicIcon1_qixueIcon.png"

function UIWidgetSkillDescContent:OnEnter(szDesc, bIsMiJi,bUseTypeOne)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        self.bIsMiJi = bIsMiJi
        self.szKeyWord = self.szColor
        
        if bUseTypeOne == false and  self.szColor1 then
            self.szKeyWord = self.szColor1
        end

        if szDesc then
            self:SetData(szDesc)
        end
    end
end

function UIWidgetSkillDescContent:OnExit()
    self.bInit = false
    Event.UnRegAll(self)
end

function UIWidgetSkillDescContent:BindUIEvent()
end

function UIWidgetSkillDescContent:RegEvent()

end

function UIWidgetSkillDescContent:SetData(szDesc)
    if self.ImgIcon and self.bIsMiJi == false then
        UIHelper.SetSpriteFrame(self.ImgIcon, nQiXueIconPath)
    end

    szDesc = string.format("<color=%s>%s</color>", self.szKeyWord,szDesc)
    UIHelper.SetRichText(self.LabelDescribe, szDesc)
    --Timer.AddFrame(self,1,function()
        UIHelper.CascadeDoLayoutDoWidget(self._rootNode,true,true)
    --end)
end

function UIWidgetSkillDescContent:SetContent(szDesc)
    UIHelper.SetRichText(self.LabelDescribe, szDesc)
    UIHelper.CascadeDoLayoutDoWidget(self._rootNode,true,true)
end

return UIWidgetSkillDescContent

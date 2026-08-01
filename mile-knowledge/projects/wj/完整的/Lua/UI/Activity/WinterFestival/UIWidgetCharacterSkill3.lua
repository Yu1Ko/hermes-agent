-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetCharacterSkill3
-- Date: 2024-11-27 16:19:32
-- Desc: WidgetCharacterSkill3 门客培养 稀世神兵
-- ---------------------------------------------------------------------------------

local UIWidgetCharacterSkill3 = class("UIWidgetCharacterSkill3")

function UIWidgetCharacterSkill3:OnEnter(szRichText, szFrame)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.szRichText = szRichText
    self.szFrame = szFrame

    self:UpdateInfo()
end

function UIWidgetCharacterSkill3:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetCharacterSkill3:BindUIEvent()
    
end

function UIWidgetCharacterSkill3:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetCharacterSkill3:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetCharacterSkill3:UpdateInfo()
    UIHelper.SetRichText(self.LabelDetail, self.szRichText)
    if self.szFrame then
        UIHelper.SetTexture(self.ImgIcon1, self.szFrame)
    end

    UIHelper.LayoutDoLayout(self._rootNode)
end

return UIWidgetCharacterSkill3
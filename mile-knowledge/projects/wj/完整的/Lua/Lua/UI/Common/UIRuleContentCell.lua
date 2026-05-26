-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIRuleContentCell
-- Date: 2023-02-20 10:46:13
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIRuleContentCell = class("UIRuleContentCell")

function UIRuleContentCell:OnEnter(szContent, bSmall)
    self.szContent = szContent
    self.bSmall = bSmall

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIRuleContentCell:OnExit()
    self.bInit = false
end

function UIRuleContentCell:BindUIEvent()

end

function UIRuleContentCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIRuleContentCell:UpdateInfo()
    self.szContent = ServiceCenterData.GetServiceXmlText(self.szContent) -- 在线客服处理

    if self.bSmall then
        UIHelper.SetRichText(self.LabelContentSmall, self.szContent)
    else
        UIHelper.SetRichText(self.LabelContent, self.szContent)
    end
    UIHelper.SetVisible(self.LabelContent, not self.bSmall)
    UIHelper.SetVisible(self.LabelContentSmall, self.bSmall)
    UIHelper.LayoutDoLayout(self.LayoutContent)
end

return UIRuleContentCell
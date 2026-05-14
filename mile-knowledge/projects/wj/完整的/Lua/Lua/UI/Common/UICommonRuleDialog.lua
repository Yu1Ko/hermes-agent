-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICommonRuleDialog
-- Date: 2025-03-21 11:07:06
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICommonRuleDialog = class("UICommonRuleDialog")

function UICommonRuleDialog:OnEnter(szTitle, szTips)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.szTitle = szTitle
    self.szTips = szTips
    self:UpdateInfo()
end

function UICommonRuleDialog:OnExit()
    self.bInit = false
end

function UICommonRuleDialog:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

end

function UICommonRuleDialog:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UICommonRuleDialog:UpdateInfo()
    UIHelper.SetString(self.LabelTitle, self.szTitle)
    UIHelper.SetRichText(self.RichTextContent, self.szTips)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewArenaIntegral)
end


return UICommonRuleDialog
-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIRuleTitleCell
-- Date: 2023-02-20 10:46:13
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIRuleTitleCell = class("UIRuleTitleCell")

function UIRuleTitleCell:OnEnter(szContent)
    self.szContent = szContent

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIRuleTitleCell:OnExit()
    self.bInit = false
end

function UIRuleTitleCell:BindUIEvent()

end

function UIRuleTitleCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIRuleTitleCell:UpdateInfo()
    UIHelper.SetString(self.LabelTitle, self.szContent)

end

return UIRuleTitleCell
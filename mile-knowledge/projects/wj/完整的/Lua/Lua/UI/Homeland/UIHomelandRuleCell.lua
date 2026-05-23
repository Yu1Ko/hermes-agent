-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandRuleCell
-- Date: 2023-11-14 10:48:37
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandRuleCell = class("UIHomelandRuleCell")

function UIHomelandRuleCell:OnEnter(nLevel, tbConfig)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nLevel = nLevel
    self.tbConfig = tbConfig

    self:UpdateInfo()
end

function UIHomelandRuleCell:OnExit()
    self.bInit = false
end

function UIHomelandRuleCell:BindUIEvent()

end

function UIHomelandRuleCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelandRuleCell:UpdateInfo()
    UIHelper.SetString(self.LabelHomeLandTitle, UIHelper.GBKToUTF8(self.tbConfig.szName))
    UIHelper.SetString(self.LabelHomeLandNum, string.format("%d级", self.tbConfig.dwLevel))

    if self.nLevel >= self.tbConfig.dwLevel then
        UIHelper.SetColor(self.LabelHomeLandNum, cc.c3b(255, 226, 110))
    else
        UIHelper.SetColor(self.LabelHomeLandNum, cc.c3b(255, 28, 28))
    end
end

return UIHomelandRuleCell
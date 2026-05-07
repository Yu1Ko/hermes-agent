-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIOperationMiniTitle
-- Date: 2026-03-20
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIOperationMiniTitle = class("UIOperationMiniTitle")

function UIOperationMiniTitle:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIOperationMiniTitle:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIOperationMiniTitle:BindUIEvent()

end

function UIOperationMiniTitle:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIOperationMiniTitle:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  -------------------------------------------------------

function UIOperationMiniTitle:UpdateInfo()
    local szLabel = "小标题测试"
    local szTitleCount = "1/4"

    --UIHelper.SetSpriteFrame(self.ImgTitleBg, szTitle)
    UIHelper.SetString(self.LabelMiniTitle, szLabel)
    UIHelper.SetString(self.LabelMiniTitleCount, szTitleCount)
end

function UIOperationMiniTitle:UpdateOnlyTitle(szTitle)
    UIHelper.SetString(self.LabelMiniTitle, szTitle)
    UIHelper.SetVisible(self.LabelMiniTitle, true)
    UIHelper.SetVisible(self.LabelMiniTitleCount, false)
end

function UIOperationMiniTitle:UpdateTitleAndCount(szTitle, szTitleCount)
    UIHelper.SetString(self.LabelMiniTitle, szTitle)
    UIHelper.SetVisible(self.LabelMiniTitle, true)
    UIHelper.SetString(self.LabelMiniTitleCount, szTitleCount)
    UIHelper.SetVisible(self.LabelMiniTitleCount, true)
end

return UIOperationMiniTitle

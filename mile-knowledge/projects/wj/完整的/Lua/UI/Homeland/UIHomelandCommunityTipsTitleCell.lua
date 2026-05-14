-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandCommunityTipsTitleCell
-- Date: 2023-04-03 17:12:30
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandCommunityTipsTitleCell = class("UIHomelandCommunityTipsTitleCell")

function UIHomelandCommunityTipsTitleCell:OnEnter(szTitle)
    self.szTitle = szTitle

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIHomelandCommunityTipsTitleCell:OnExit()
    self.bInit = false
end

function UIHomelandCommunityTipsTitleCell:BindUIEvent()

end

function UIHomelandCommunityTipsTitleCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelandCommunityTipsTitleCell:UpdateInfo()
    UIHelper.SetString(self.LabelCommunityTilte, self.szTitle)
end


return UIHomelandCommunityTipsTitleCell
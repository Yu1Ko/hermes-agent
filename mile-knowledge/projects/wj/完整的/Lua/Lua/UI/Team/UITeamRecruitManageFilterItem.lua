-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UITeamRecruitManageFilterItem
-- Date: 2023-02-14 20:15:33
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UITeamRecruitManageFilterItem = class("UITeamRecruitManageFilterItem")

function UITeamRecruitManageFilterItem:OnEnter(tbConfig, fnSelect)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbConfig = tbConfig
    self.fnSelect = fnSelect
    self:UpdateInfo()
end

function UITeamRecruitManageFilterItem:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UITeamRecruitManageFilterItem:BindUIEvent()
    UIHelper.BindUIEvent(self.TogPitchBg, EventType.OnSelectChanged, function (_, bSelected)
        self.fnSelect(self, bSelected)
    end)
end

function UITeamRecruitManageFilterItem:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UITeamRecruitManageFilterItem:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITeamRecruitManageFilterItem:UpdateInfo()
    UIHelper.SetString(self.LabelDesc, self.tbConfig.szName)
    UIHelper.SetSwallowTouches(self.TogPitchBg, false)
end

function UITeamRecruitManageFilterItem:GetSelected()
    return UIHelper.GetSelected(self.TogPitchBg)
end

function UITeamRecruitManageFilterItem:SetSelected(bSelected)
    UIHelper.SetSelected(self.TogPitchBg, bSelected, false)
end

return UITeamRecruitManageFilterItem
-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UITeamRecruitTagTitle
-- Date: 2023-02-17 15:28:52
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UITeamRecruitTagTitle = class("UITeamRecruitTagTitle")

function UITeamRecruitTagTitle:OnEnter(szName)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.szName = szName
    self:UpdateInfo()
end

function UITeamRecruitTagTitle:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UITeamRecruitTagTitle:BindUIEvent()
    
end

function UITeamRecruitTagTitle:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UITeamRecruitTagTitle:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITeamRecruitTagTitle:UpdateInfo()
    UIHelper.SetString(self.LabelTitlePublic, self.szName)
end


return UITeamRecruitTagTitle
-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UITeamForceNum
-- Date: 2023-02-20 19:44:31
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UITeamForceNum = class("UITeamForceNum")

function UITeamForceNum:OnEnter(nForceID, nNum)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nForceID = nForceID
    self.nNum = nNum
    self:UpdateInfo()
end

function UITeamForceNum:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UITeamForceNum:BindUIEvent()

end

function UITeamForceNum:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UITeamForceNum:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITeamForceNum:UpdateInfo()
    UIHelper.SetSpriteFrame(self.ImgSchoolIcon, PlayerForceID2SchoolImg2[self.nForceID])
    UIHelper.SetString(self.LabeSchoolName, Table_GetForceName(self.nForceID))
    UIHelper.SetString(self.LabelSchoolNum, self.nNum)
    local imgKungfu = UIHelper.GetChildByPath(self._rootNode, "ImgBg/ImgXinFaIcon")
    UIHelper.SetVisible(imgKungfu, false)
end


return UITeamForceNum
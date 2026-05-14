-- ---------------------------------------------------------------------------------
-- Author: liu yu min
-- Name: UIChallengeSloganCell
-- Date: 2023-04-07 11:41:57
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIChallengeSloganCell = class("UIChallengeSloganCell")

function UIChallengeSloganCell:OnEnter(szSlogan,nIndex)
    self.nIndex = nIndex
    self.szSlogan = szSlogan
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIChallengeSloganCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIChallengeSloganCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnSlogan, EventType.OnClick, function()
        Event.Dispatch("Modify_Slogan",self.szSlogan,self.nIndex)
    end)

    UIHelper.SetTouchDownHideTips(self.BtnSlogan, false)
end

function UIChallengeSloganCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIChallengeSloganCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIChallengeSloganCell:UpdateInfo()
    UIHelper.SetString(self.LabelSlogan, string.format("%s", self.szSlogan))
end


return UIChallengeSloganCell
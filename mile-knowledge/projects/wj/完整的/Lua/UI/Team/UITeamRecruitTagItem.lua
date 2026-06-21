-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UITeamRecruitTagItem
-- Date: 2023-02-13 20:10:27
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UITeamRecruitTagItem = class("UITeamRecruitTagItem")

function UITeamRecruitTagItem:OnEnter(tbTag, fnClick)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbTag = tbTag
    self.fnClick = fnClick
    self:UpdateInfo()
end

function UITeamRecruitTagItem:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UITeamRecruitTagItem:BindUIEvent()
    for i = 1, 3 do
        UIHelper.BindUIEvent(self.tBtn[i], EventType.OnClick, function()
            self.fnClick(self.tbTag[i])
        end)
    end
end

function UITeamRecruitTagItem:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UITeamRecruitTagItem:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITeamRecruitTagItem:UpdateInfo()
    for i = 1, 3 do
        if self.tbTag[i] then
            UIHelper.SetString(self.tLabel[i], self.tbTag[i].text)
        end
        UIHelper.SetVisible(self.tBtn[i], self.tbTag[i] ~= nil)
        UIHelper.SetSwallowTouches(self.tBtn[i], false)
    end
end

return UITeamRecruitTagItem
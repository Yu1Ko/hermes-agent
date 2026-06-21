-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPopAddFriendView
-- Date: 2022-01-09 10:05:55
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPopAddFriendView = class("UIPopAddFriendView")

function UIPopAddFriendView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIPopAddFriendView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPopAddFriendView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function()
        local szName = UIHelper.GetString(self.EditBox)
        szName = UIHelper.UTF8ToGBK(szName)
        FellowshipData.AddFellowship(szName)

        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
end

function UIPopAddFriendView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIPopAddFriendView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIPopAddFriendView:UpdateInfo()
    --self.EditBox:setPlaceHolder(self.szTipContent)
end

return UIPopAddFriendView
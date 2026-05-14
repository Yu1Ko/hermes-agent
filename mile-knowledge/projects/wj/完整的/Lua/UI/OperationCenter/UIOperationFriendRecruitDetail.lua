-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIOperationFriendRecruitDetail
-- Date: 2026-03-25 23:15:06
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIOperationFriendRecruitDetail = class("UIOperationFriendRecruitDetail")

function UIOperationFriendRecruitDetail:OnEnter(nOperationID, nID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nOperationID = nOperationID
    self.nID = nID

    self:UpdateInfo()
end

function UIOperationFriendRecruitDetail:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIOperationFriendRecruitDetail:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnStatus, EventType.OnClick,function ()
        if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.COIN, "COIN") then
            return
        end
        local szUrl = OperationFriendRecruitData.GetAutoLoginUrl(tUrl.FriendRecallList)
        UIHelper.OpenWeb(szUrl)
    end)

    UIHelper.BindUIEvent(self.BtnInvite, EventType.OnClick,function ()
        self:SendMail()
    end)

    UIHelper.BindUIEvent(self.BtnCopy, EventType.OnClick,function ()
        local szUrl = OperationFriendRecruitData.GetAutoLoginSpecialUrl(tUrl.FriendRecallIndex)
        SetClipboard(szUrl)

        TipsHelper.ShowNormalTip(g_tStrings.STR_COPY_SUCESS)
    end)
end

function UIOperationFriendRecruitDetail:RegEvent()
    Event.Reg(self, "On_Recharge_GetFriendsPoints_CallBack", function (nLeftPoint)
        Timer.AddFrame(self, 1, function()
            self:UpdatePoint()
        end)
    end)

    Event.Reg(self, "On_Recharge_GetFriInvReward_CallBack", function (nLeftPoint)
        Timer.AddFrame(self, 1, function()
            self:UpdatePoint()
        end)
    end)
end

function UIOperationFriendRecruitDetail:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIOperationFriendRecruitDetail:UpdateInfo()
    self:UpdatePoint()
end

function UIOperationFriendRecruitDetail:UpdatePoint()
    UIHelper.SetString(self.LabelMoney, OperationFriendRecruitData.GetRecruitPoint())
    UIHelper.LayoutDoLayout(self.WidgetMoney)
end

function UIOperationFriendRecruitDetail:SendMail()
    local szMail = UIHelper.GetString(self.EditBox)

    if szMail == "" then
        OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_SENDMAIL_NULL)
        return
    end

    if not szMail:match("^%w+@%w+.%w+$") then
        OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_SENDMAIL_FAILURE)
        return
    end

    RemoteCallToServer("OnSendFriendsInviteEmail", "", szMail, "", g_tStrings.STR_FRIEND_INVITE_BACK)
    OutputMessage("MSG_ANNOUNCE_YELLOW", g_tStrings.STR_SENDMAIL_SUCESSED)
end


return UIOperationFriendRecruitDetail
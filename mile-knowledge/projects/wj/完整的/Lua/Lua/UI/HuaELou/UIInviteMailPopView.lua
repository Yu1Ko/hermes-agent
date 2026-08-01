-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIInviteMailPopView
-- Date: 2023-05-23 14:23:37
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIInviteMailPopView = class("UIInviteMailPopView")

function UIInviteMailPopView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UIInviteMailPopView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIInviteMailPopView:BindUIEvent()
    
end

function UIInviteMailPopView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnSend, EventType.OnClick, function ()
        local szCMD = UIHelper.GetString(self.EditBox)
        if szCMD ~= "" and not szCMD:match("^%w+@%w+.%w+$") then
            UIHelper.SetString(self.LabelError,g_tStrings.STR_SENDMAIL_FAILURE)
            UIHelper.SetVisible(self.LabelError,true)
        elseif szCMD == "" then
            UIHelper.SetString(self.LabelError,g_tStrings.STR_SENDMAIL_NULL)
            UIHelper.SetVisible(self.LabelError,true)
        else
            RemoteCallToServer("OnSendFriendsInviteEmail", "",  UIHelper.UTF8ToGBK(szCMD), "", UIHelper.UTF8ToGBK(g_tStrings.STR_FRIEND_INVITE_BACK))
            TipsHelper.ShowNormalTip(g_tStrings.STR_SENDMAIL_SUCESSED)
            UIMgr.Close(self)
        end
    end)

    UIHelper.RegisterEditBoxEnded(self.EditBox, function()
        local szCMD = UIHelper.GetString(self.EditBox)
        if szCMD ~= "" and not szCMD:match("^%w+@%w+.%w+$") then
            UIHelper.SetString(self.LabelError,g_tStrings.STR_SENDMAIL_FAILURE)
            UIHelper.SetVisible(self.LabelError,true)
        else
            UIHelper.SetVisible(self.LabelError,false)
        end
    end)
end

function UIInviteMailPopView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIInviteMailPopView:UpdateInfo()
    UIHelper.SetVisible(self.LabelError,false)
end


return UIInviteMailPopView
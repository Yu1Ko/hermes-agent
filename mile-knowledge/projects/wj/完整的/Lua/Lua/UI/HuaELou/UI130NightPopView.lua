-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UI130NightPopView
-- Date: 2024-10-23 15:18:17
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UI130NightPopView = class("UI130NightPopView")

function UI130NightPopView:OnEnter(dwID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.dwID = dwID
    self:InitViewInfo()
end

function UI130NightPopView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UI130NightPopView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnDetail, EventType.OnClick, function()
        if self.szLink then
            FireUIEvent("EVENT_LINK_NOTIFY", self.szLink)
            UIMgr.Close(self)
        end
    end)
end

function UI130NightPopView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UI130NightPopView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UI130NightPopView:InitViewInfo()
    local tInvitationInfo = Table_GetCustomInvitation(self.dwID)
    local szName = UI_GetClientPlayerName() or ""

    if not tInvitationInfo then
        UILog("No Invitation", self.dwID)
        return
    end

    if self.BtnDetail then
        UIHelper.SetVisible(self.BtnDetail, tInvitationInfo.szLink ~= "")
    end
    self.szLink = tInvitationInfo.szLink

    UIHelper.SetString(self.LabelName, UIHelper.GBKToUTF8(szName))
    if self.LayoutPlayerName then
        UIHelper.LayoutDoLayout(self.LayoutPlayerName)
    end
end


return UI130NightPopView
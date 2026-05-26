-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UITeamChatHint
-- Date: 2024-09-20 09:54:36
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UITeamChatHint = class("UITeamChatHint")

function UITeamChatHint:OnEnter(szChannel)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.szChannel = szChannel
    self:UpdateInfo()
end

function UITeamChatHint:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UITeamChatHint:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnChat, EventType.OnClick, function()
        local tbData = ChatHintMgr.GetTopData()
        local nChannel = tbData and tbData.nChannel
        if nChannel then
            local szUIChannel = ChatHintMgr.GetUIChannel(nChannel)
            UIMgr.Open(VIEW_ID.PanelChatSocial, 1, szUIChannel)
        else
            ChatHelper.Chat()
        end
    end)
end

function UITeamChatHint:RegEvent()
    Event.Reg(self, EventType.OnChatHintMsgUpdate, function()
        self:UpdateInfo()
    end)
end

function UITeamChatHint:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITeamChatHint:UpdateInfo()
    local nTotalLen = ChatHintMgr.GetTotalLen()
    UIHelper.SetVisible(self.WidgetRedPoint, nTotalLen > 0)
    UIHelper.SetString(self.LabelChat, (nTotalLen > 99) and "99+" or nTotalLen)
end


return UITeamChatHint
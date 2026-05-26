-- ---------------------------------------------------------------------------------
-- Author: huqing
-- Name: UIChatCopyTips
-- Date: 2023-08-02 09:57:06
-- Desc: 聊天拷贝、举报Tips
-- ---------------------------------------------------------------------------------

local DIABLE_COPY_CHANNEL_TO_TIPS =
{
    [PLAYER_TALK_CHANNEL.IDENTITY] = "萌新频道暂不支持使用复制功能",
}


local UIChatCopyTips = class("UIChatCopyTips")

function UIChatCopyTips:OnEnter(tbChatData)
    self.tbChatData = tbChatData
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    --UIHelper.SetVisible(self.WidgetCopy, false)
    UIHelper.LayoutDoLayout(self.Layout)

    UIHelper.SetButtonState(self.BtnCopy, BTN_STATE.Normal)
    local nChannel = self.tbChatData and self.tbChatData.nChannel or 0
    if ChatData.IsChannelCopyDisable(nChannel) then
        local szTips = DIABLE_COPY_CHANNEL_TO_TIPS[nChannel] or ""
        UIHelper.SetButtonState(self.BtnCopy, BTN_STATE.Disable, szTips, true)
    end
end

function UIChatCopyTips:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIChatCopyTips:BindUIEvent()
    -- TODO 聊天内容拷贝要考虑：1、表情是否是需要付费的表情，然后过滤掉
    UIHelper.BindUIEvent(self.BtnCopy, EventType.OnClick, function()
        local szContent = self.tbChatData.szContent
        local szEditText = ChatData.ConvertRichTextToEditText(szContent)
        szEditText = UIHelper.RichTextToNormal(szEditText)
        if not string.is_nil(szEditText) then
            if Platform.IsWindows() then
                SetClipboard(UTF8ToGBK(szEditText))
            end
            TipsHelper.ShowNormalTip("复制成功")
        end

        Event.Dispatch(EventType.OnChatContentCopy, szEditText)

        TipsHelper.DeleteAllHoverTips()
    end)

    UIHelper.BindUIEvent(self.BtnReport, EventType.OnClick, function()
        if not self.tbChatData then
            return
        end

        if ChatData.IsChannelReportDisable(self.tbChatData.nChannel) then
            TipsHelper.ShowNormalTip("不能举报该消息。")
            TipsHelper.DeleteAllHoverTips()
            return
        end

        if not self.tbChatData.szGlobalID and (self.tbChatData.dwTalkerID == nil or self.tbChatData.dwTalkerID == 0) then
            TipsHelper.ShowNormalTip("不能举报系统消息。")
            TipsHelper.DeleteAllHoverTips()
            return
        end

        if self.tbChatData.dwTalkerID == g_pClientPlayer.dwID or self.tbChatData.szGlobalID == g_pClientPlayer.GetGlobalID() then
            TipsHelper.ShowNormalTip("不能举报自己。")
            TipsHelper.DeleteAllHoverTips()
            return
        end

        local bIsAINpc = self.tbChatData.nChannel == CLIENT_PLAYER_TALK_CHANNEL.AINPC
        local szName = bIsAINpc and GBKToUTF8(self.tbChatData.szName) or self.tbChatData.szName
        local szContent = self.tbChatData.szContent
        if self.tbChatData.nPrefabID == PREFAB_ID.WidgetChatPlayerVoice then
            szContent = "[语音消息] "..tostring(szContent)
        end
        szContent = ChatData.ConvertRichTextToEditText(szContent)
        local szChannelName = ChatData.GetChannelNameByID(self.tbChatData.nChannel) or ""
        szContent = string.format("[%s]%s", szChannelName, szContent)

        local dwTalkerID = self.tbChatData.dwTalkerID
        local reportView = UIMgr.Open(VIEW_ID.PanelReportPop)
        reportView:UpdateReportInfo(szName , szContent ,dwTalkerID, nil , nil ,self.tbChatData.szGlobalID, self.tbChatData.nTime)
        TipsHelper.DeleteAllHoverTips()
    end)
end

function UIChatCopyTips:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIChatCopyTips:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIChatCopyTips:UpdateInfo()

end


return UIChatCopyTips
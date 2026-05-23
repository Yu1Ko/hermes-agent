-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIChatViewCell_System
-- Date: 2022-12-15 15:51:48
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIChatViewCell_System = class("UIChatViewCell_System")

function UIChatViewCell_System:OnEnter(nIndex, tbChatData)
    self.nIndex = nIndex
    self.tbChatData = tbChatData

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIChatViewCell_System:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIChatViewCell_System:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnTouch, EventType.OnClick, function()
        if UIMgr.IsOpening() then return end
        if not ChatData.GetCanShowChatCopyTips() then return end
        if self.tbChatData and self.tbChatData.nChannel == -1 then return end -- 战斗频道不弹

        --local tCursor = GetCursorPoint()
        --TipsHelper.ShowClickHoverTips(PREFAB_ID.WidgetCopy, tCursor.x, tCursor.y, self.tbChatData)
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetCopy, self.BtnTouch, TipsLayoutDir.TOP_CENTER, self.tbChatData)
    end)
end

function UIChatViewCell_System:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIChatViewCell_System:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIChatViewCell_System:UpdateInfo()
    if not self.tbChatData then return end

    local szContent = self.tbChatData.szContent
    local nChannel = self.tbChatData.nChannel
    local tbConf = ChatData.GetChatFlagConfByChannelID(nChannel)
    local nPrefabID = self.tbChatData.nPrefabID
    local nPadding = ChatData.GetCellPadding(nPrefabID)

    -- 内容
    local szTime = ChatHelper.ConvertChatTime(self.tbChatData.nTime, true, true)
    if ChatData.IsGMChannel(nChannel) or self.tbChatData.bRookieGM then
        szContent = string.format("<color=%s>%s%s</color>", UI_Chat_Color.GM, szTime, szContent)
    else
        szContent = szTime .. szContent
    end
    UIHelper.SetRichText(self.RichText, szContent)

    -- 频道
    UIHelper.SetSpriteFrame(self.ImgChannelIcon, tbConf.szChannelIcon)

    local nHeight = UIHelper.GetHeight(self.RichText) + nPadding
    UIHelper.SetHeight(self.WidgetRoot, nHeight)
    UIHelper.SetHeight(self.BtnTouch, nHeight)
    UIHelper.WidgetFoceDoAlign(self)
end


return UIChatViewCell_System
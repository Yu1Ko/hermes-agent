-- ---------------------------------------------------------------------------------
-- Author: huqing
-- Name: UIChatViewCell_Voice
-- Date: 2024-03-16 15:46:39
-- Desc: 聊天语音单元
-- ---------------------------------------------------------------------------------

local UIChatViewCell_Voice = class("UIChatViewCell_Voice")

function UIChatViewCell_Voice:OnEnter(nIndex, tbChatData)
    self.nIndex = nIndex
    self.tbChatData = tbChatData

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIChatViewCell_Voice:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIChatViewCell_Voice:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnTouch, EventType.OnClick, function()
        --if self.bIsSelf then return end
        if UIMgr.IsOpening() then return end
        if not ChatData.GetCanShowChatCopyTips() then return end

        --local tCursor = GetCursorPoint()
        --TipsHelper.ShowClickHoverTips(PREFAB_ID.WidgetCopy, tCursor.x, tCursor.y, self.tbChatData)
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetCopy, self.BtnTouch, TipsLayoutDir.TOP_CENTER, self.tbChatData)
    end)

    UIHelper.BindUIEvent(self.BtnVoice, EventType.OnClick, function()
        if string.is_nil(self.szFileID) then
            return
        end

        local szFilePath = ChatVoiceMgr.GetFilePathByFileID(self.szFileID)
        if szFilePath and ChatVoiceMgr.IsPlaying(szFilePath) then
            ChatVoiceMgr.StopPlayFile()
            self:_stopAnim()
            return
        end

        ChatVoiceMgr.PlayRecordedFileByFileID(self.szFileID)
        self:_playAnim()
    end)

    UIHelper.BindUIEvent(self.BtnCopy, EventType.OnClick, function()
        ChatHelper.SendPlayerToChat(self.szName)
    end)
end

function UIChatViewCell_Voice:RegEvent()
    Event.Reg(self, EventType.OnChatVoiceDownloadSuccessed, function(filepath, fileid)
        if string.is_nil(filepath) then
            return
        end

        ChatVoiceMgr.PlayRecordedFile(filepath)
    end)

    Event.Reg(self, EventType.OnChatVoicePlaySuccessed, function(filepath)
        local szFilePath = ChatVoiceMgr.GetFilePathByFileID(self.szFileID)
        if szFilePath == filepath then
            self:_stopAnim()
        end
    end)
end

function UIChatViewCell_Voice:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIChatViewCell_Voice:UpdateInfo()
    if not self.tbChatData then return end

    local dwTalkerID = self.tbChatData.dwTalkerID
    local szGlobalID = self.tbChatData.szGlobalID
    local szContent = self.tbChatData.szContent

    local nChannel = self.tbChatData.nChannel
    local tbConf = ChatData.GetChatFlagConfByChannelID(nChannel)
    local nPrefabID = self.tbChatData.nPrefabID
    local nPadding = ChatData.GetCellPadding(nPrefabID)
    local nTimeHeight = 24 -- 时间的高度
    local player = GetClientPlayer()
    local bIsSelf = (player and dwTalkerID == player.dwID)

    if not string.is_nil(szGlobalID) then
        bIsSelf = szGlobalID == UI_GetClientPlayerGlobalID()
    end

    local szName = bIsSelf and GBKToUTF8(player.szName) or self.tbChatData.szName
    local dwMiniAvatarID = bIsSelf and player.dwMiniAvatarID or self.tbChatData.dwMiniAvatarID
    local dwForceID = bIsSelf and player.dwForceID or self.tbChatData.dwForceID
    local nLevel = bIsSelf and player.nLevel or self.tbChatData.nLevel
    local nCamp = bIsSelf and player.nCamp or self.tbChatData.nCamp
    local nRoleType = bIsSelf and player.nRoleType or self.tbChatData.nRoleType or 2
    local dwTitleID = self.tbChatData.dwTitleID
    local bHasTitle = dwTitleID > 0

    local nVoiceDuration = self.tbChatData.tbMsg and self.tbChatData.tbMsg[1] and self.tbChatData.tbMsg[1].time
    self.szFileID = self.tbChatData.tbMsg and self.tbChatData.tbMsg[1] and self.tbChatData.tbMsg[1].fileid

    self.bIsSelf = bIsSelf

    -- 名字
    self.szName = szName
    UIHelper.SetString(self.LabelPlayerName, szName)

    -- copy
    UIHelper.SetVisible(self.WidgetCopy, not bIsSelf)

    -- 称号
    if bHasTitle then
        local tbPrefix = UIHelper.GetDesignationInfoByTitleID(dwTitleID, dwForceID)
        UIHelper.SetString(self.LabelDesignation, string.format("[%s]", tbPrefix and GBKToUTF8(tbPrefix.szName) or ""))
        UIHelper.SetColor(self.LabelDesignation, tbPrefix.tbColor)
    end
    UIHelper.SetVisible(self.LabelDesignation, bHasTitle)
    UIHelper.LayoutDoLayout(self.LayoutPlayer)

    -- 频道
    UIHelper.SetSpriteFrame(self.ImgChannelIcon, tbConf.szChannelIcon)
    UIHelper.SetString(self.LabelChannel, tbConf.szName)

    -- 等级
    UIHelper.SetString(self.LabelLevel, nLevel)
    UIHelper.SetVisible(self.LabelLevel, true)
    UIHelper.SetVisible(self.ImgBgLevel, true)

    -- School
    UIHelper.SetSpriteFrame(self.ImgSchool, PlayerForceID2SchoolImg2[dwForceID])
    UIHelper.SetVisible(self.ImgSchool, true)

    -- 头像
    if not self.scriptHead then
        UIHelper.RemoveAllChildren(self.WidgetHead)
        self.scriptHead = UIHelper.AddPrefab(PREFAB_ID.WidgetHead, self.WidgetHead, dwTalkerID)
    end

    self.scriptHead:SetHeadInfo(dwTalkerID, dwMiniAvatarID, nRoleType, dwForceID)
    self.scriptHead:SetClickCallback(function() self:OnHeadClick() end)

    -- 阵营
    CampData.SetUICampImg(self.ImgCamp, nCamp)
    UIHelper.SetVisible(self.ImgCamp, true)

    -- 时间
    local szTime = ChatHelper.ConvertChatTime(self.tbChatData.nTime)
    UIHelper.SetString(self.LabelDate, szTime)

    -- 语音
    local nTime = math.floor((nVoiceDuration or 0) / 1000)
    UIHelper.SetString(self.LabelTime, nTime.."秒")

    -- 内容
    UIHelper.SetString(self.LabelChat, szContent)

    UIHelper.SetVisible(self.LayoutContent, true)
    UIHelper.LayoutDoLayout(self.LayoutContent)
    UIHelper.SetHeight(self.WidgetRoot, UIHelper.GetHeight(self.LayoutContent) + nPadding + nTimeHeight)
    UIHelper.WidgetFoceDoAlign(self)

    -- Btn Touch
    local w, h = UIHelper.GetContentSize(self.LayoutContent)
    UIHelper.SetContentSize(self.BtnTouch, w, h - 45)
    local x, y = UIHelper.GetPosition(self.LayoutContent)
    UIHelper.SetPosition(self.BtnTouch, x, y - 45)
end

function UIChatViewCell_Voice:OnHeadClick()
    if self.bIsSelf then return end
    if not self.scriptHead then return end

    ChatTips.ShowPlayerTips(self.scriptHead._rootNode, self.tbChatData)
end

function UIChatViewCell_Voice:_playAnim()
    UIHelper.PlayAni(self, self.WidgetVoice, "AniVoiceLoop")
end

function UIChatViewCell_Voice:_stopAnim()
    UIHelper.PlayAni(self, self.WidgetVoice, "AniVoiceStop")
    UIHelper.StopAni(self, self.WidgetVoice, "AniVoiceLoop")
    --UIHelper.PlayAni(self, self.WidgetVoice, "AniVoiceStop")
end


return UIChatViewCell_Voice
-- ---------------------------------------------------------------------------------
-- Author: huqing
-- Name: UIChatViewCell_Player
-- Date: 2022-12-15 15:46:39
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIChatViewCell_Player = class("UIChatViewCell_Player")

function UIChatViewCell_Player:OnEnter(nIndex, tbChatData)
    self.nIndex = nIndex
    self.tbChatData = tbChatData

    self.nOriginalWidth = self.nOriginalWidth or UIHelper.GetWidth(self.RichTextSingleLine)
    self.tbOriginalPos = self.tbOriginalPos or {UIHelper.GetPosition(self.RichTextSingleLine)}
    self.nFontSize = self.nFontSize or self.RichTextSingleLine:getFontSize()
    self.nOriginalLayoutMulWidth = self.nOriginalLayoutMulWidth or UIHelper.GetWidth(self.LayoutContentMultiLine)

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIChatViewCell_Player:OnExit()
    self.bInit = false
    self:UnRegEvent()

    -- self.dwMiniAvatarID = nil
    -- self.nRoleType = nil
    -- self.dwForceID = nil
    self.tbChatData = nil
end

function UIChatViewCell_Player:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnTouch, EventType.OnClick, function()
        --if self.bIsSelf then return end
        if UIMgr.IsOpening() then return end
        if not ChatData.GetCanShowChatCopyTips() then return end

        -- local xxx = labelparser.parse(self.tbChatData.szOriginContent)
        -- local yyy = Base64_Decode(xxx[1].href)
        -- local zzz = JsonDecode(yyy)

        --local tCursor = GetCursorPoint()
        --TipsHelper.ShowClickHoverTips(PREFAB_ID.WidgetCopy, tCursor.x, tCursor.y, self.tbChatData)
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetCopy, self.BtnTouch, TipsLayoutDir.TOP_CENTER, self.tbChatData)
    end)

    UIHelper.BindUIEvent(self.BtnCopy, EventType.OnClick, function()
        ChatHelper.SendPlayerToChat(self.szName)
    end)
end

function UIChatViewCell_Player:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIChatViewCell_Player:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIChatViewCell_Player:UpdateInfo()
    if not self.tbChatData then return end

    local dwTalkerID = self.tbChatData.dwTalkerID
    local szGlobalID = self.tbChatData.szGlobalID
    local szContent = self.tbChatData.szContent

    local nChannel = self.tbChatData.nChannel
    local tbConf = ChatData.GetChatFlagConfByChannelID(nChannel)
    local nPrefabID = self.tbChatData.nPrefabID
    local nPadding = ChatData.GetCellPadding(nPrefabID)
    local nTimeHeight = 30 -- 时间的高度
    local player = GetClientPlayer()
    local bIsSelf = (player and dwTalkerID == player.dwID)
    local bIsRoom = nChannel == PLAYER_TALK_CHANNEL.ROOM
    local bIsWhisper = nChannel == PLAYER_TALK_CHANNEL.WHISPER
    local bIsVoiceRoom = nChannel == PLAYER_TALK_CHANNEL.VOICE_ROOM
    local bIsAINpc = nChannel == CLIENT_PLAYER_TALK_CHANNEL.AINPC

    if not string.is_nil(szGlobalID) then
        bIsSelf = szGlobalID == UI_GetClientPlayerGlobalID()
    end

    local szName = (bIsSelf and not bIsRoom and not bIsVoiceRoom) and GBKToUTF8(player.szName) or self.tbChatData.szName
    local dwMiniAvatarID = bIsSelf and player.dwMiniAvatarID or self.tbChatData.dwMiniAvatarID
    local dwForceID = bIsSelf and player.dwForceID or self.tbChatData.dwForceID or 0
    local nLevel = bIsSelf and player.nLevel or self.tbChatData.nLevel or 100
    local nCamp = bIsSelf and player.nCamp or self.tbChatData.nCamp or 0
    local nRoleType = bIsSelf and player.nRoleType or self.tbChatData.nRoleType or 2
    local dwTitleID = self.tbChatData.dwTitleID
    local bHasTitle = dwTitleID > 0
    local nTitleLen = 0
    local bSingleLine = true -- 单行标记
    local bShowTuilan = self.tbChatData.nSourceType and self.tbChatData.nSourceType == CHAT_SOURCE_TYPE.APP or false

    self.bIsSelf = bIsSelf
    self.bIsAINpc = bIsAINpc

    if bIsAINpc then
        bIsSelf = self.tbChatData.nType == CHAT_RECORD_SENDER_TYPE.PLAYER
        szName = GBKToUTF8(self.tbChatData.szName)
        dwMiniAvatarID = self.tbChatData.dwMiniAvatarID
        dwForceID = self.tbChatData.nForceID or 0
        nLevel = self.tbChatData.nLevel or 100
        nCamp = self.tbChatData.nCamp or 0
        nRoleType = self.tbChatData.nRoleType or 2
        dwTitleID = self.tbChatData.dwTitleID
        bHasTitle = dwTitleID > 0
    end

    -- 名字
    self.szName = szName
    UIHelper.SetString(self.LabelPlayerName, szName, 8)

    -- copy
    UIHelper.SetVisible(self.WidgetCopy, not bIsSelf)

    -- 称号
    if bHasTitle then
        local tbPrefix = UIHelper.GetDesignationInfoByTitleID(dwTitleID, dwForceID)
        local szTitleName = string.format("[%s]", tbPrefix and GBKToUTF8(tbPrefix.szName) or "")
        nTitleLen = UIHelper.GetUtf8Len(szTitleName)
        UIHelper.SetString(self.LabelDesignation, szTitleName)
        UIHelper.SetColor(self.LabelDesignation, tbPrefix and tbPrefix.tbColor or cc.c3b(255, 255, 255))

        if nTitleLen > 8 then
            UIHelper.SetString(self.LabelPlayerName, szName, 3)
        end
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
        self.scriptHead = UIHelper.AddPrefab(PREFAB_ID.WidgetHead, self.WidgetHead)
    end

    local bIsScrolling = ChatData.GetIsScrolling()
    if bIsScrolling or (self.dwMiniAvatarID ~= dwMiniAvatarID or self.nRoleType ~= nRoleType or self.dwForceID ~= dwForceID) then
        if bIsAINpc and not bIsSelf then
            self.scriptHead:SetHeadWithTex(self.tbChatData.szSmallAvatarImg)
        else
            self.scriptHead:SetHeadInfo(dwTalkerID, dwMiniAvatarID, nRoleType, dwForceID)
        end
    end
    self.scriptHead:SetClickCallback(function() self:OnHeadClick() end)

    --来自推栏
    UIHelper.SetVisible(self.ImgTuiLanOnline, bShowTuilan)

    self.dwMiniAvatarID = dwMiniAvatarID
    self.nRoleType = nRoleType
    self.dwForceID = dwForceID

    -- 阵营
    CampData.SetUICampImg(self.ImgCamp, nCamp, nil, true)
    UIHelper.SetVisible(self.ImgCamp, true)

    -- 时间
    local szTime = ChatHelper.ConvertChatTime(self.tbChatData.nTime)
    UIHelper.SetString(self.LabelTime, szTime)
    UIHelper.SetString(self.LabelTimeMul, szTime)

    -- 内容
    local nRichTextWidth = UIHelper.GetUtf8RichTextWidth(szContent, self.nFontSize)
    UIHelper.SetVisible(self.LayoutContentSingleLine, false)
    UIHelper.SetVisible(self.LayoutContentMultiLine, false)

    if nRichTextWidth < 180 then nRichTextWidth = 180 end -- 因为加了时间，所以要这样计算

    local layoutContent, richText
    if nRichTextWidth > (self.nOriginalWidth - 10) then -- 多行
        layoutContent = self.LayoutContentMultiLine
        richText = self.RichTextMultiLine
        bSingleLine = false
    else
        -- 如果没有中文（也不一定是中文，就是全部都是数字 字母 标点符号 制表符）
        -- if string.is_nil(string.gsub(szContent, "[a-zA-Z0-9%p%c]", "")) then
        --     nRichTextWidth = nRichTextWidth + 25
        -- else
        --     nRichTextWidth = nRichTextWidth + 25
        -- end

        nRichTextWidth = nRichTextWidth + 35

        nRichTextWidth = math.max(60, nRichTextWidth)

        layoutContent = self.LayoutContentSingleLine
        richText = self.RichTextSingleLine
        UIHelper.SetWidth(layoutContent, nRichTextWidth)
        UIHelper.SetPosition(self.RichTextSingleLine, self.tbOriginalPos[1], self.tbOriginalPos[2])
    end

    UIHelper.SetVisible(layoutContent, true)
    UIHelper.SetRichText(richText, szContent)
    UIHelper.LayoutDoLayout(layoutContent)

    -- 容错：单行情况下，如果其实高度超过2行，那就要设置一下Layout的宽度，防止背景图和文字不匹配的情况
    local nRichTextHeight = UIHelper.GetHeight(richText)
    if bSingleLine and nRichTextHeight > self.nFontSize * 2 then
        UIHelper.SetWidth(layoutContent, self.nOriginalLayoutMulWidth)
    end

    UIHelper.SetHeight(self.WidgetRoot, nRichTextHeight + nPadding + nTimeHeight)
    UIHelper.WidgetFoceDoAlign(self)

    -- Btn Touch
    local w, h = UIHelper.GetContentSize(layoutContent)
    UIHelper.SetContentSize(self.BtnTouch, w, h)
    local x, y = UIHelper.GetPosition(layoutContent)
    UIHelper.SetPosition(self.BtnTouch, x, y)

    self.nContentnWidth = nRichTextWidth
end

function UIChatViewCell_Player:OnHeadClick()
    if self.bIsSelf then return end
    if self.bIsAINpc then return end
    if not self.scriptHead then return end

    ChatTips.ShowPlayerTips(self.scriptHead._rootNode, self.tbChatData)
end


return UIChatViewCell_Player
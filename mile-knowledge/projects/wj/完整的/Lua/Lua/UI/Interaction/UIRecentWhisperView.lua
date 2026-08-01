-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIRecentWhisperView
-- Date: 2024-09-12 14:39:35
-- Desc: ?
-- ---------------------------------------------------------------------------------
local m_winOpenKeyboardTime = 0.2
local RECENT_CONTACT_MAX_NUM = 300
local COLOR =
{
    RECORD_NORMAL = cc.c3b(193, 207, 210),
    RECORD_CANCEL = cc.c3b(255, 0, 0),
}

local UIRecentWhisperView = class("UIRecentWhisperView")

function UIRecentWhisperView:OnEnter(tbSelectedPlayer, szGlobalID)
	self.tbSelectedPlayer = tbSelectedPlayer
    self.szGlobalID = szGlobalID

	self.nBVHWidth, self.nBVHHeight = UIHelper.GetContentSize(self.BtnVoiceHold)
    self.tbHistoryChatInfo = {}
	if not self.bInit then
		self:RegEvent()
		self:BindUIEvent()
		self.bInit = true
	end
	self:UpdateInfo()
end

function UIRecentWhisperView:OnExit()
	self.bInit = false
	self:UnRegEvent()
    self:UnInitScrollList()
	if not UIMgr.GetViewScript(VIEW_ID.PanelChatSocial) then
		UIMgr.Open(VIEW_ID.PanelChatSocial, 2, 1)
	end
    ChatRecentMgr.ClearNewMsg(self.tbSelectedPlayer.szGlobalID)
    Event.Dispatch(EventType.OnChatHintMsgUpdate)
end

function UIRecentWhisperView:BindUIEvent()
	UIHelper.BindUIEvent(self.BtnBack, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

	UIHelper.BindUIEvent(self.BtnEmoji, EventType.OnClick, function()
        self:ShowEmoji()
    end)

	UIHelper.BindUIEvent(self.BtnMoreMessage, EventType.OnClick,function()
        self.bIsToBottom = true
        self:ResetUnRead()
        self:UpdateInfo_UnReadCount()
        self:UpdateInfo_Content()
    end)

	UIHelper.BindUIEvent(self.BtnMic, EventType.OnClick, function()
		if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TALK, "player talk") then
            return
        end

        if not GVoiceMgr.IsMicAvail() then
            TipsHelper.ShowNormalTip("当前没有可用麦克风")
            return
        end

        local nChannelID = ChatData.GetSendChannelID(UI_Chat_Channel.Whisper)
        ChatData.SetChannelVoiceModel(nChannelID, true)

        self:UpdateVoice()
    end)

	UIHelper.BindUIEvent(self.BtnKeyboard, EventType.OnClick, function()
        local nChannelID = ChatData.GetSendChannelID(UI_Chat_Channel.Whisper)
        ChatData.SetChannelVoiceModel(nChannelID, false)

        self:UpdateVoice()
    end)

	UIHelper.BindUIEvent(self.BtnVoiceHold, EventType.OnTouchBegan, function(btn, nX, nY)
        self:StartRecording()
    end)

    UIHelper.BindUIEvent(self.BtnVoiceHold, EventType.OnTouchMoved, function(btn, nX, nY)
        local nLocalX, nLocalY = UIHelper.ConvertToNodeSpace(self.BtnVoiceHold, nX, nY)
        local bIsInHold = nLocalX >= -self.nBVHWidth/2 and nLocalX <= self.nBVHWidth/2 and nLocalY >= -self.nBVHHeight/2 and nLocalY <= self.nBVHHeight/2
        -- if nLocalX >= -self.nBVHWidth/2 and nLocalX <= self.nBVHWidth/2 and nLocalY >= -self.nBVHHeight/2 and nLocalY <= self.nBVHHeight/2 then
        --     LOG.INFO("Moved In")
        -- else
        --     LOG.INFO("Moved Out")
        -- end

        self:UpdateRecording(bIsInHold)
    end)

    UIHelper.BindUIEvent(self.BtnVoiceHold, EventType.OnTouchEnded, function(btn, nX, nY)
        self:StopRecording()
    end)

    UIHelper.BindUIEvent(self.BtnVoiceHold, EventType.OnTouchCanceled, function(btn, nX, nY)
        self:CancelRecording()
    end)

	if Platform.IsMobile() then
        local fnEditBoxSend = function(szType)
            if szType == "began" then
                self:EnterMobileInputMode()
            elseif szType == "ended" or szType == "return" then
                self:ExitMobileInputMode()
                self:SetEditBoxSendString(UIHelper.GetString(self.EditBoxSend))
            end
        end
        --UIHelper.RegisterEditBox(self.EditBoxSendNormal, function(szType) fnEditBoxSend(szType) end)
        UIHelper.RegisterEditBox(self.EditBoxSendShort, function(szType) fnEditBoxSend(szType) end)
        --self.EditBoxSendNormal:enableInputFieldHidden(false)
        self.EditBoxSendShort:enableInputFieldHidden(false)
    else
        local fnEditBoxSend = function(szType)
            if szType == "ended" then
                self:SetEditBoxSendString(UIHelper.GetString(self.EditBoxSend))
            elseif szType == "return" then
                self:Send()
            end
        end
        --UIHelper.RegisterEditBox(self.EditBoxSendNormal, function(szType) fnEditBoxSend(szType) end)
        UIHelper.RegisterEditBox(self.EditBoxSendShort, function(szType) fnEditBoxSend(szType) end)
    end

	UIHelper.BindUIEvent(self.BtnSend, EventType.OnClick, function()
        self:Send()
    end)

    --UIHelper.BindUIEvent(self.BtnShowHistory, EventType.OnClick, function()
    --    ChatRecentMgr.AddGlobalID(self.tbSelectedPlayer.szGlobalID)
    --    self.bUpdateHistory = true
    --    self:UpdateHistoryChatList()
    --end)
end

function UIRecentWhisperView:RegEvent()
	Event.Reg(self, "ON_UDPATE_RECENT_WHISPER_INFO", function (tbPlayerInfo)
		self.tbSelectedPlayer = tbPlayerInfo
		ChatRecentMgr.ClearNewMsg(tbPlayerInfo.szGlobalID)
		self:UpdateChatContent()
        --self:UpdateHistoryBtnVisible()
	end)

	--Event.Reg(self, EventType.OnChatWhisperSelected, function(szCurWhisper)
    --    self.szCurWhisper = szCurWhisper
    --    ChatData.RemoveFromWhisperUnread(szCurWhisper)
    --    self:UpdateWhisperContent()
    --end)
    Event.Reg(self, EventType.OnReceiveChat, function(tbData)
        local nChannel = tbData.nChannel
        if nChannel ~= PLAYER_TALK_CHANNEL.WHISPER then
            return
        end
        self:OnReceive(tbData)
        --玩家列表排序
        self:SortLeftPlayerInfo(tbData)
    end)

	Event.Reg(self, EventType.OnChatEmojiClosed, function()
        self:HideEmoji()
    end)

    Event.Reg(self, EventType.OnChatEmojiSelected, function(tbEmojiConf)
        self:HideEmoji()

        if not tbEmojiConf then
            return
        end

        local nID = tbEmojiConf.nID
        local szEmoji = string.format("[%s]", tbEmojiConf.szName)

        if nID == -1 then
            UIMgr.Open(VIEW_ID.PanelCollectEmoticons)
        else
            self:AppendInput(szEmoji)
        end
    end)

    Event.Reg(self, EventType.OnChatContentCopy, function(szContent)
        self:SetEditBoxSendString(szContent)
    end)

    Event.Reg(self, EventType.OnUIScrollListTouchMove, function()
        --self:UpdateHistoryBtnVisible()
        if not self.tScrollList then
            return
        end
        local nPercentage = self.tScrollList:GetPercentage()
        if nPercentage >= 1 then
            self.bIsToBottom = true
        end
    end)

    Event.Reg(self, EventType.OnUIScrollListMouseWhell, function()
    --    self:UpdateHistoryBtnVisible()
    end)

    if Channel.Is_WLColud() then
        Event.Reg(self, EventType.OnChatVoiceToTexSuccessed, function(fileid, szFilePath, nFileSize, nVoiceDuration, tbMsg)
            self:Send(tbMsg)
        end)
    else
        Event.Reg(self, EventType.OnChatVoiceRecordSuccessed, function(bStream, filepath, fileid, text, nVoiceDuration, tbMsg)
            if not bStream then return end
            self:Send(tbMsg)
        end)
    end
end

function UIRecentWhisperView:UnRegEvent()
	--Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIRecentWhisperView:UpdateInfo()
	ChatData.ResizeChatData(UI_Chat_Channel.Whisper)
	ChatData.StopSearch()
    self:UpdateLeftPlayerList()
    self:OnSelectedChannel()

	self:AppendInput()
end

function UIRecentWhisperView:UpdateLeftPlayerList()
    self.tbPlayerScriptList = {}
	local tbPlayerList = ChatRecentMgr.GetRecentWhisperPlayerList() or {}
    tbPlayerList = ChatRecentMgr.SortPlayerList(tbPlayerList)

    self.tbPlayerList = tbPlayerList
    local nIndex = 1

    if self.tbSelectedPlayer then
        tbPlayerList = self:UpdateNewRecentPlayerList(self.tbSelectedPlayer, tbPlayerList)
        self.tbPlayerList = tbPlayerList
    else
        if self.szGlobalID then
            for k, tbPlayer in pairs(tbPlayerList) do
                if tbPlayer.szGlobalID == self.szGlobalID then
                    self.tbSelectedPlayer = tbPlayer
                end
            end
        else
            self.tbSelectedPlayer = tbPlayerList[1]
        end
        Event.Dispatch(EventType.OnChatHintMsgUpdate)
    end

	for i, tbPlayerInfo in ipairs(tbPlayerList) do
        if i > RECENT_CONTACT_MAX_NUM then
            break
        end
		local bSelected = self.tbSelectedPlayer.szGlobalID == tbPlayerInfo.szGlobalID
        if bSelected then
            nIndex = i
        end
		local tbScript = UIHelper.AddPrefab(PREFAB_ID.WidgetTogWisperPlayerNew, self.ScrollViewTab, tbPlayerInfo, bSelected)
        table.insert(self.tbPlayerScriptList, tbScript)
	end

    Timer.AddFrame(self, 1, function ()
        UIHelper.ScrollToIndex(self.ScrollViewTab, nIndex - 1)
    end)

end

function UIRecentWhisperView:UpdateChatContent()
	local szName = UIHelper.GBKToUTF8(self.tbSelectedPlayer.szName)
	self:UpdateName(szName)
	self:UpdateHistoryChatInfo()
end

function UIRecentWhisperView:UpdateName(szName)

	UIHelper.SetString(self.LableWhisperName, szName)

    local tbFriendList = FellowshipData.GetFellowshipInfoList() or {}
    for i, v in ipairs(tbFriendList) do
        if v.id == self.tbSelectedPlayer.szGlobalID and v.remark then
			UIHelper.SetString(self.LableWhisperName, UIHelper.GBKToUTF8(v.remark))
            break
        end
    end
end

function UIRecentWhisperView:UpdateHistoryChatInfo()
    --self.bUpdateHistory = false
    --self.bUpdateHistory = ChatRecentMgr.IsNeedLoadHistoryChat(self.tbSelectedPlayer.szGlobalID)
    self.bUpdateHistory = true
    self:ClearCurHistoryChatInfo()
    local szName = UIHelper.GBKToUTF8(self.tbSelectedPlayer.szName)
    local szGlobalID = self.tbSelectedPlayer.szGlobalID
    self:SetCurHistoryChatInfo(szGlobalID, szName)
	self.szCurWhisper = UIHelper.GBKToUTF8(self.tbSelectedPlayer.szName)
	--ChatData.RemoveFromWhisperUnread(self.szCurWhisper)
	self:UpdateWhisperContent()
end

function UIRecentWhisperView:UpdateWhisperContent()
	if self.tScrollList == nil then
        self:InitScrollList()
    end
    self:UpdateInfo_Content()
    self:LayoutDelayShow()
end

function UIRecentWhisperView:InitScrollList()
	self:UnInitScrollList()

	self.tScrollList = UIScrollList.Create({
		listNode = self.LayoutRecentContacts,
        nReboundScale = 1,
		fnGetCellType = function(nIndex)
            return self:GetCellType(nIndex)
        end,
		fnUpdateCell = function(cell, nIndex)
			self:UpdateOneCell(cell, nIndex)
		end,
	})
end

function UIRecentWhisperView:UnInitScrollList()
	if self.tScrollList then
		self.tScrollList:Destroy()
		self.tScrollList = nil
	end
end

function UIRecentWhisperView:GetCellType(nIndex)
	local tbData
    local nPrefabID
    local szName = UIHelper.GBKToUTF8(self.tbSelectedPlayer.szName)
    local szGlobalID = self.tbSelectedPlayer.szGlobalID
    local nOffLineMsgCount = ChatRecentMgr.GetOffLineMsgCount(self.tbSelectedPlayer.szGlobalID)

    local tbHistoryChatInfo = self:GetCurHistoryChatInfo()

    if not tbHistoryChatInfo or table.is_empty(tbHistoryChatInfo) then
        local szName = UIHelper.GBKToUTF8(self.tbSelectedPlayer.szName)
        local szGlobalID = self.tbSelectedPlayer.szGlobalID
        self:SetCurHistoryChatInfo(szGlobalID, szName)
        tbHistoryChatInfo = self:GetCurHistoryChatInfo()
    end

    local nHistoryLen = table.get_len(tbHistoryChatInfo)
    local bOffLineMsgFirst = nOffLineMsgCount > 0

    if self.bUpdateHistory then     --需要加载历史消息和在线时的新消息
        if nIndex <= nHistoryLen then
            tbData = tbHistoryChatInfo[nIndex]
            nPrefabID = ChatRecentMgr.GetPrefabID(tbData.tbContentInfo.szSenderGlobalID, tbData.tbInfo)
        else
            tbData = ChatData.GetOneData(UI_Chat_Channel.Whisper, nIndex - nHistoryLen, self.szCurWhisper)
            nPrefabID = tbData.nPrefabID
        end
    else    --不需加载历史消息，加载离线时的历史消息和新消息
        if bOffLineMsgFirst and nIndex <= nOffLineMsgCount then   --离线历史消息
            tbData = tbHistoryChatInfo[nHistoryLen - nOffLineMsgCount + nIndex]
            nPrefabID = ChatRecentMgr.GetPrefabID(tbData.tbContentInfo.szSenderGlobalID, tbData.tbInfo)
        else    --新消息
            tbData = ChatData.GetOneData(UI_Chat_Channel.Whisper, nIndex - nOffLineMsgCount, self.szCurWhisper)
            nPrefabID = tbData.nPrefabID
        end
    end

    return nPrefabID
end

function UIRecentWhisperView:UpdateOneCell(cell, nIndex)
	if not cell then return end
    cell._keepmt = true
    local tbData
    local szName = UIHelper.GBKToUTF8(self.tbSelectedPlayer.szName)
    local szGlobalID = self.tbSelectedPlayer.szGlobalID
    local nOffLineMsgCount = ChatRecentMgr.GetOffLineMsgCount(self.tbSelectedPlayer.szGlobalID)

    local tbHistoryChatInfo = self:GetCurHistoryChatInfo()
    local bOffLineMsgFirst = nOffLineMsgCount > 0
    local nHistoryLen = table.get_len(tbHistoryChatInfo)
    if self.bUpdateHistory then     --需要加载历史消息和在线时的新消息
        if nIndex <= nHistoryLen then
            tbData = self:ParseChatInfo(tbHistoryChatInfo[nIndex])
        else
            tbData = ChatData.GetOneData(UI_Chat_Channel.Whisper, nIndex - nHistoryLen, self.szCurWhisper)
        end
    else    --不需加载历史消息，加载离线时的历史消息和新消息
        if bOffLineMsgFirst and nIndex <= nOffLineMsgCount then
            tbData = self:ParseChatInfo(tbHistoryChatInfo[nHistoryLen - nOffLineMsgCount + nIndex])
        else
            tbData = ChatData.GetOneData(UI_Chat_Channel.Whisper, nIndex - nOffLineMsgCount, self.szCurWhisper)
        end
    end

    cell:OnEnter(nIndex, tbData)

    self:UpdateInfo_UnReadCount()
end

function UIRecentWhisperView:UpdateInfo_UnReadCount()
	self:UpdateRange()

	local nUnReadCount = self.nCurChannelCount - self.nRangeMax

	Timer.DelTimer(self, self.nUnReadTimerID)
    local bVisible = nUnReadCount > 0
    if bVisible then
        self.nUnReadTimerID = Timer.AddFrame(self, 2, function()
            UIHelper.SetActiveAndCache(self, self.BtnMoreMessage, true)
            ChatData.SetIsScrolling(false)
        end)
    else
        UIHelper.SetActiveAndCache(self, self.BtnMoreMessage, false)
        ChatData.SetIsScrolling(true)
    end

	UIHelper.SetString(self.LabelMoreMessage, string.format(g_tStrings.STR_CHAT_UNREADMESSAGE_COUNT, nUnReadCount))
end

function UIRecentWhisperView:UpdateRange()
	if not self.tScrollList then
        self.nRangeMin = 0
        self.nRangeMax = 0
        return
    end

    local nMin, nMax = self.tScrollList:GetIndexRangeOfLoadedCells()

    if self.nRangeMin == nil then
        self.nRangeMin = nMin
    else
        if nMin < self.nRangeMin then
            self.nRangeMin = nMin
        end
    end

    if self.nRangeMax == nil then
        self.nRangeMax = nMax
    else
        if nMax > self.nRangeMax then
            self.nRangeMax = nMax
        end
    end
end

function UIRecentWhisperView:UpdateInfo_Content()
    local tbHistoryInfo = self:GetCurHistoryChatInfo()
    local nHistoryLen = table.get_len(tbHistoryInfo)
    local nOffLineMsgCount = ChatRecentMgr.GetOffLineMsgCount(self.tbSelectedPlayer.szGlobalID)
    nHistoryLen = self.bUpdateHistory and nHistoryLen or nOffLineMsgCount
	local nDataLen = ChatData.GetDataListLen(UI_Chat_Channel.Whisper, self.szCurWhisper) + nHistoryLen
    local min, max = self.tScrollList:GetIndexRangeOfLoadedCells()

    self.nCurChannelCount = nDataLen
    if self.tScrollList then
        if nDataLen == 0 then
            self.tScrollList:Reset(nDataLen) --完全重置，包括速度、位置
        else
            self.tScrollList:ResetWithStartIndex(nDataLen, nDataLen)
            --self.tScrollList:ReloadWithStartIndex(nDataLen, max) --刷新数量
        end
    end


    self:ResetUnRead()
    self:UpdateInfo_UnReadCount()
end

function UIRecentWhisperView:ResetUnRead()
	self.nRangeMin = nil
    self.nRangeMax = nil
end

function UIRecentWhisperView:LayoutDelayShow()
	UIHelper.SetOpacity(self.LayoutRecentContacts, 0)
    Timer.DelTimer(self, self.nTimerID)
    self.nTimerID = Timer.AddFrame(self, 2, function()
        UIHelper.SetOpacity(self.LayoutRecentContacts, 255)
    end)
end

function UIRecentWhisperView:ShowEmoji()
	if not self.scriptEmoji then
        self.scriptEmoji = UIHelper.AddPrefab(PREFAB_ID.WidgetChatExpression, self.WidgetChatExpression)
    else
        if self.scriptEmoji.nCurGroupID == -1 then
            self.scriptEmoji:UpdateInfo_EmojiList()
        end
    end

	UIHelper.SetVisible(self.WidgetChatExpression, true)
end

function UIRecentWhisperView:HideEmoji()
    UIHelper.SetVisible(self.WidgetChatExpression, false)
end

function UIRecentWhisperView:AppendInput(szContent)
	if string.is_nil(szContent) then
        local szMsg = ChatData.GetChatInputText(UI_Chat_Channel.Whisper)
        self:SetEditBoxSendString(szMsg)
        return
    end
    local szMsg = UIHelper.GetString(self.EditBoxSend)..szContent
    self:SetEditBoxSendString(szMsg)

    local nChannelID = ChatData.GetSendChannelID(UI_Chat_Channel.Whisper)
    ChatData.SetChannelVoiceModel(nChannelID, false)
    self:UpdateVoice()
end

function UIRecentWhisperView:SetEditBoxSendString(szContent)
	UIHelper.SetString(self.EditBoxSendShort, szContent)

    ChatData.SetChatInputText(UI_Chat_Channel.Whisper, szContent)
end

function UIRecentWhisperView:UpdateVoice()
	local nChannelID = ChatData.GetSendChannelID(UI_Chat_Channel.Whisper)
    local bVoiceMode = ChatData.IsChannelVoiceModel(nChannelID)
    local bVoiceAble = ChatData.GetChannelVoiceAble(nChannelID)
    local bSendVisible = UIHelper.GetVisible(self.WidgetSend)

	UIHelper.SetVisible(self.WidgetSendVoice, bVoiceMode and bVoiceAble and bSendVisible)

    UIHelper.SetVisible(self.BtnSend, not bVoiceMode)
    UIHelper.SetVisible(self.BtnEmoji, not bVoiceMode)
    UIHelper.SetVisible(self.BtnMic, not bVoiceMode and bVoiceAble)
    UIHelper.SetVisible(self.EditBoxSendShort, not bVoiceMode and bVoiceAble)

    self.EditBoxSend = bVoiceAble and self.EditBoxSendShort
end

function UIRecentWhisperView:StartRecording()
	if self.bIsRecording then
        return
    end

    self.bIsRecording = true
    UIHelper.SetVisible(self.WidgetVoiceHint, true)

    local nMax = math.floor(ChatData.GetRecordingMaxTime() / 1000)

    UIHelper.SetString(self.LabelRecordTime, nMax.."'")

    Timer.DelTimer(self, self.nRecordingTimerID)
    self.nRecordingTimerID = Timer.AddCountDown(self, nMax,
    function(nRemain)
        UIHelper.SetString(self.LabelRecordTime, nRemain.."'")
    end,
    function()
        ChatVoiceMgr.StopRecording()
    end)

    ChatVoiceMgr.StartRecording()
end

function UIRecentWhisperView:UpdateRecording(bIsInHold)
	UIHelper.SetVisible(self.WidgetRecord, bIsInHold)
    UIHelper.SetVisible(self.WidgetRecordCancel, not bIsInHold)

    local szHint = bIsInHold and "松开手指 发送语音" or "松开手指 取消"
    UIHelper.SetString(self.LabelRecordHint, szHint)

    local tbColor = bIsInHold and COLOR.RECORD_NORMAL or COLOR.RECORD_CANCEL
    UIHelper.SetColor(self.LabelRecordHint, tbColor)
end

function UIRecentWhisperView:StopRecording()
	if not self.bIsRecording then
        return
    end

    self.bIsRecording = false

    Timer.DelTimer(self, self.nRecordingTimerID)
    UIHelper.SetVisible(self.WidgetVoiceHint, false)

    ChatVoiceMgr.StopRecording()
end

function UIRecentWhisperView:CancelRecording()
	if not self.bIsRecording then
        return
    end

    self.bIsRecording = false

    Timer.DelTimer(self, self.nRecordingTimerID)
    UIHelper.SetVisible(self.WidgetVoiceHint, false)

    ChatVoiceMgr.CancelRecording()
end

function UIRecentWhisperView:EnterMobileInputMode()
    local nX , nY = UIHelper.GetPosition(self.WidgetSend)
    self.tbEditorBoxPos = {x = nX , y = nY}
    self.nLastCursorPosY = -100
    self.bIsMobileInputMode = true

    local bHasUpdateScrollList = false

    -- 增加定时器，监听输入框变化
    Timer.DelTimer(self, self.nInputTimerID)
    self.nInputTimerID = Timer.AddCycle(self, 0.2, function()
        -- 获取当前输入法位置
        local cursorPosition = self.EditBoxSend:getInputFieldCursorPosition()
        if self.nLastCursorPosY == cursorPosition.y then
            return
        end
        self.nLastCursorPosY = cursorPosition.y
        -- 判断是否已经关闭 或者 浮窗模式
        if math.abs(cursorPosition.y) <= 100  then
            self:ExitMobileInputMode()
        else
            local screenSize = UIHelper.GetScreenSize()
            local nScaleX , nScaleY = UIHelper.GetScreenToResolutionScale()
            local nWidgetSendHeight = UIHelper.GetHeight(self.WidgetSend)
            -- 获取新的位置坐标
            cursorPosition.y = -((screenSize.height + cursorPosition.y)/nScaleY - nWidgetSendHeight*0.5)
            UIHelper.SetPosition(self.WidgetSend, self.tbEditorBoxPos.x, cursorPosition.y)

            ---  处理聊天信息可视区域
            local nContentY = UIHelper.GetPositionY(self.LayoutRecentContacts)
            local nContentHeight = nContentY - cursorPosition.y - nWidgetSendHeight

            if not bHasUpdateScrollList then
                self:UpdateScrollList()
                bHasUpdateScrollList = true
            end
        end
    end)
end

function UIRecentWhisperView:ExitMobileInputMode()
	Timer.DelTimer(self, self.nInputTimerID)

    if self.tbEditorBoxPos then
        UIHelper.SetPosition(self.WidgetSend , self.tbEditorBoxPos.x , self.tbEditorBoxPos.y)
    end

    self.bIsMobileInputMode = false

    --self.EditBoxSend:editBoxEditingDidEnd(UIHelper.GetString(self.EditBoxSend))

    self:UpdateScrollList()
end

function UIRecentWhisperView:UpdateScrollList()
    self:InitScrollList()
    self:UpdateInfo_Content()
    --self:UpdateInfo_DoLayout()
    UIHelper.LayoutDoLayout(self.LayoutRecentContacts)
end

function UIRecentWhisperView:Send(tbSendMsg)
	self:RegKeyBoardEvent()

	do  -- 执行命令
        local szMsg = UIHelper.GetString(self.EditBoxSend)
        local bResult = ChatCommand.ParseCMD(szMsg)
        if bResult then
            self:SetEditBoxSendString("")
            return
        end
    end

	if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TALK, "player talk") then
        return
    end

	local nChannelID = ChatData.GetSendChannelID(UI_Chat_Channel.Whisper)
    local nCDTime = ChatData.GetChannelSendCDTime(nChannelID)
    if nCDTime > 0 then
        TipsHelper.ShowNormalTip(g_tStrings.tTalkError[PLAYER_TALK_ERROR.SCENE_CD])
        return
    end

    local szMsg = UIHelper.GetString(self.EditBoxSend)

	if not string.is_nil(szMsg) or (tbSendMsg and not table.is_empty(tbSendMsg)) then
        local tbMsg = tbSendMsg or ChatParser.Parse(szMsg)
        local szReceiver = UTF8ToGBK(self.szCurWhisper)
        --if self.szCurUIChannel == UI_Chat_Channel.Whisper then
        --if self.szCurWhisper then
        --    local tbData = ChatData.GetWhisperPlayerData(self.szCurWhisper)
        --    szReceiver = UTF8ToGBK(tbData and tbData.szName)
        --end
        --end

        local bResult = ChatData.Send(nChannelID, szReceiver, tbMsg)
        --LOG.ERROR(tostring(bResult))
        if bResult then
            self:SetEditBoxSendString("")
            ChatData.RecordSendTime(nChannelID)
            self:UpdateSendButton()
            ChatArgs.Clear()
        end
    end
end

function UIRecentWhisperView:RegKeyBoardEvent()
	if Platform.IsWindows() or Platform.IsMac() then
        Event.UnReg(self, EventType.OnKeyboardUp)

        Timer.Add(self, 1, function()
            Event.Reg(self, EventType.OnKeyboardUp, function(nKeyCode, szVKName)
                if nKeyCode == cc.KeyCode.KEY_ENTER then
                    Event.UnReg(self, EventType.OnKeyboardUp)
                    self:EnterInputMode()
                end
            end)
        end)
    end
end

function UIRecentWhisperView:EnterInputMode()
    if Platform.IsMobile() then return end
    if not self.EditBoxSend then return end

    local bVisible = UIHelper.GetVisible(self.EditBoxSend) and UIHelper.GetVisible(self.WidgetSend)
    local bEmpty = string.is_nil(UIHelper.GetString(self.EditBoxSend))
    -- if bVisible and not bEmpty then
    if bVisible then
        Timer.Add(self, m_winOpenKeyboardTime, function()
            self.EditBoxSend:openKeyboard()
        end)
    end
    return bVisible
end

function UIRecentWhisperView:UpdateSendButton()
    -- 更新发送按钮CD
    local nChannelID = ChatData.GetSendChannelID(UI_Chat_Channel.Whisper)
    local nCDTime = ChatData.GetChannelSendCDTime(nChannelID)

    if nCDTime > 0 then
        UIHelper.SetString(self.LabelSend, nCDTime..g_tStrings.STR_TIME_SECOND)
        UIHelper.SetButtonState(self.BtnSend, BTN_STATE.Disable, g_tStrings.tTalkError[PLAYER_TALK_ERROR.SCENE_CD])

        Timer.DelTimer(self, self.nSendBtnCDTimerID)
        self.nSendBtnCDTimerID = Timer.AddCountDown(self, nCDTime,
        function(nRemain)
            UIHelper.SetString(self.LabelSend, nRemain..g_tStrings.STR_TIME_SECOND)
        end,
        function()
            Timer.DelTimer(self, self.nSendBtnCDTimerID)
            UIHelper.SetString(self.LabelSend, "发送")
            UIHelper.SetButtonState(self.BtnSend, BTN_STATE.Normal)
        end)
    else
        Timer.DelTimer(self, self.nSendBtnCDTimerID)
        UIHelper.SetString(self.LabelSend, "发送")
        UIHelper.SetButtonState(self.BtnSend, BTN_STATE.Normal)
    end
end

function UIRecentWhisperView:OnSelectedChannel()
	ChatData.SetRuntimeSelectDisplayChannel(UI_Chat_Channel.Whisper)

	self:UpdateSendButton()
	self:UpdateVoice()
	self:UpdateScrollList()

    Event.Dispatch(EventType.OnChatViewChannelChanged, UI_Chat_Channel.Whisper)
end

function UIRecentWhisperView:OnReceive(tbData)
    if not tbData then return end
    if not tbData.tbUIChannelMap then return end
    if not tbData.tbUIChannelMap[UI_Chat_Channel.Whisper] then
        if not tbData.bBeCalled then
            return
        end
    end

    local nDataLen = ChatData.GetDataListLen(UI_Chat_Channel.Whisper, self.szCurWhisper)
    -- 如果当前频道数据太长了，就清理一下，然后滚动到最后
    if ChatData.CheckNeedResize(nDataLen) then
        ChatData.ResizeChatData(UI_Chat_Channel.Whisper)
        self:UpdateInfo_Content()
        return
    end

    local bIsSelf = PlayerData.IsSelf(tbData.dwTalkerID)
    local bIsWhisper = true
    local nPercentage = self.tScrollList:GetPercentage()
    local min, max = self.tScrollList:GetIndexRangeOfLoadedCells()

    local tbHistoryInfo = self:GetCurHistoryChatInfo()
    local nHistoryLen = table.get_len(tbHistoryInfo)
    local nOffLineMsgCount = ChatRecentMgr.GetOffLineMsgCount(self.tbSelectedPlayer.szGlobalID)
    nHistoryLen = self.bUpdateHistory and nHistoryLen or nOffLineMsgCount

    nDataLen = nDataLen + nHistoryLen
    self.nCurChannelCount = nDataLen
    self.tScrollList:ReloadWithStartIndex(nDataLen, min) --刷新数量

    --self.tScrollList:ResetWithStartIndex(nDataLen, min)

    --LOG.INFO("QH, min = %d, max = %d, total = %d, per = %f", min, max, nDataLen, nPercentage)
    --if bIsSelf or nPercentage >= 0.999 then

    if bIsSelf then
        self.nRangeMax = nDataLen
        self.tScrollList:ScrollToIndex(nDataLen)
    end

    -- 如果默认选中的就是密聊对象发来的消息，就不要显示红点了
    if not string.is_nil(self.tbSelectedPlayer.szGlobalID) then
        ChatRecentMgr.ClearNewMsg(self.tbSelectedPlayer.szGlobalID)
    end

    self:UpdateInfo_UnReadCount()
end

function UIRecentWhisperView:UpdateHistoryBtnVisible()
    local nPercentage = self.tScrollList:GetPercentage()
    local tbHistoryInfo = self:GetCurHistoryChatInfo()
    local nHistoryLen = table.get_len(tbHistoryInfo)
    --UIHelper.SetVisible(self.BtnShowHistory, nPercentage <= 0 and not self.bUpdateHistory and nHistoryLen > 0)
    --UIHelper.LayoutDoLayout(self.LayoutContent_Normal)
end

function UIRecentWhisperView:UpdateNewRecentPlayerList(tbPlayer, tbPlayerList)
    local szGlobalID = tbPlayer.szGlobalID

    for k, tbData in pairs(tbPlayerList) do
        if tbData.szGlobalID == szGlobalID then
            return tbPlayerList
        end
    end
    table.insert(tbPlayerList, tbPlayer)

    return tbPlayerList
end

function UIRecentWhisperView:UpdateHistoryChatList()
    local nDataLen = ChatData.GetDataListLen(UI_Chat_Channel.Whisper, self.szCurWhisper)
    local tbHistoryInfo = self:GetCurHistoryChatInfo()
    local nHistoryLen = table.get_len(tbHistoryInfo)
    nDataLen = nDataLen + nHistoryLen
    if nDataLen > 0 then
        --self:UpdateHistoryBtnVisible()
        self.tScrollList:ResetWithStartIndex(nDataLen, nHistoryLen) --刷新数量
    end
end

function UIRecentWhisperView:SetCurHistoryChatInfo(szGlobalID, szName)
    local tbHistoryChatInfo = ChatRecentMgr.GetContactRecentWhisperInfo(szGlobalID, szName)
    self.tbHistoryChatInfo = tbHistoryChatInfo
end

function UIRecentWhisperView:GetCurHistoryChatInfo()
    return self.tbHistoryChatInfo
end

function UIRecentWhisperView:ClearCurHistoryChatInfo()
    self.tbHistoryChatInfo = {}
end

function UIRecentWhisperView:ParseChatInfo(tbData)
    local tbInfo = tbData.tbInfo
    local tbContentInfo = tbData.tbContentInfo
    local nPrefabID = ChatRecentMgr.GetPrefabID(tbContentInfo.szSenderGlobalID, tbInfo)
    local bIsSelf = tbContentInfo.szSenderGlobalID == UI_GetClientPlayerGlobalID()

    local szContent = ""
    for k, v in ipairs(tbInfo) do
        --处理格式化文本
        if v.type == "emotion" then
            if v.id ~= -1 then
                local szEmoji = string.format("<img emojiid='%d' src='' width='30' height='30'/>", v.id)
                szContent = szContent .. szEmoji
            end
        elseif v.type == "text" then
            szContent = UIHelper.GBKToUTF8(v.text)
        end
    end

    if string.is_nil(szContent) then
        if tbInfo[1] and tbInfo[1].type == "voice" then -- 如果是语音消息 就特殊处理下
            szContent = " "
        else
            return
        end
    end

    local tbResult =
    {
        nTime = tbContentInfo.nTalkTime, dwTitleID = tbContentInfo.dwTitleID, szGlobalID = tbContentInfo.szSenderGlobalID,
        nChannel = PLAYER_TALK_CHANNEL.WHISPER, tbMsg = tbInfo, nCamp = self.tbSelectedPlayer.byCamp,
        nRoleType = self.tbSelectedPlayer.nRoleType, nLevel = self.tbSelectedPlayer.byLevel,
        dwMiniAvatarID = self.tbSelectedPlayer.dwMiniAvatarID,
        dwForceID = self.tbSelectedPlayer.byForceID, nPrefabID = nPrefabID, dwCenterID = self.tbSelectedPlayer.dwCenterID,
        szName = UIHelper.GBKToUTF8(self.tbSelectedPlayer.szName), szContent = szContent
    }

    return tbResult
end

function UIRecentWhisperView:SortLeftPlayerInfo(tbPlayer)
    if not self.tbPlayerList or table.is_empty(self.tbPlayerList) or not tbPlayer.szGlobalID then
        return
    end

    if not self.tbPlayerScriptList or table.is_empty(self.tbPlayerScriptList) then
        return
    end

    local nIndex
    local tbFirstPlayer

    if not self:IsPlayerExistContact(tbPlayer) and g_pClientPlayer.GetGlobalID() ~= tbPlayer.szGlobalID then
        local tbData = {szGlobalID = tbPlayer.szGlobalID, byCamp = tbPlayer.nCamp, byForceID = tbPlayer.dwForceID, id = tbPlayer.szGlobalID, byRoleType = tbPlayer.nRoleType, szName = UIHelper.UTF8ToGBK(tbPlayer.szName), byLevel = tbPlayer.nLevel, dwMiniAvatarID = tbPlayer.dwMiniAvatarID, dwCenterID = tbPlayer.dwCenterID}
        local tbScript = UIHelper.AddPrefab(PREFAB_ID.WidgetTogWisperPlayerNew, self.ScrollViewTab, tbData, false)
        table.insert(self.tbPlayerScriptList, tbScript)
        table.insert(self.tbPlayerList, tbData)

        Timer.AddFrame(self, 1, function ()
            UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewTab)
        end)
    end

    for i, v in ipairs(self.tbPlayerList) do
        if v.szGlobalID == tbPlayer.szGlobalID then
            nIndex = i
            tbFirstPlayer = v
            break
        end
    end

    if nIndex then
        table.remove(self.tbPlayerList, nIndex)
        table.insert(self.tbPlayerList, 1, tbFirstPlayer)

        for k, tbPlayer in ipairs(self.tbPlayerList) do
            local bSelectedPlayer = tbPlayer.szGlobalID == self.tbSelectedPlayer.szGlobalID
            self.tbPlayerScriptList[k]:UpdatePlayerInfo(tbPlayer, bSelectedPlayer)
        end
    end
end

function UIRecentWhisperView:IsPlayerExistContact(tbPlayer)
    local szGlobalID = tbPlayer.szGlobalID

    for k, v in pairs(self.tbPlayerList) do
        if v.szGlobalID == szGlobalID then
            return true
        end
    end

    return false
end

return UIRecentWhisperView
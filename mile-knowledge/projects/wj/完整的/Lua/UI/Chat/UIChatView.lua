-- ---------------------------------------------------------------------------------
-- Author: huqing
-- Name: UIChatView
-- Date: 2022-12-08 11:13:08
-- Desc: 聊天面板
-- ---------------------------------------------------------------------------------
local CONTENT_TYPE =
{
    NORMAL        = 1,
    SMALL         = 2,
    BIG           = 3,
    INPUT_MODE    = 4,
    SMALL_WHISPER = 5,
    NPC           = 6,
}

local COLOR =
{
    RECORD_NORMAL = cc.c3b(193, 207, 210),
    RECORD_CANCEL = cc.c3b(255, 0, 0),
}

local m_winOpenKeyboardTime = 0.2

local UIChatView = class("UIChatView")

function UIChatView:OnEnter(szUIChannel, szSendContent)
    szUIChannel = ChatData.GetDefaultDisplayChannel(szUIChannel)
    self.szTarUIChannel = szUIChannel
    self.szCurUIChannel = self.szTarUIChannel
    self.tbCurChannelConf = nil
    self.nChannel = PLAYER_TALK_CHANNEL.NEARBY

    self.bFirstSelected = false

    self.szCurWhisper = ChatRecentMgr.GetCurWhisperPlayerName()
    self.dwCurAINpcID = ChatAINpcMgr.GetCurAINpcID()
    self.szGlobalID = nil
    self.szLastSearchValue = ""

    self.nCurChannelCount = 0
    self.bIsToBottom = false

    self.nBVHWidth, self.nBVHHeight = UIHelper.GetContentSize(self.BtnVoiceHold)

    self.nAINpcLayoutContentHeight = self.nAINpcLayoutContentHeight or UIHelper.GetHeight(self.tbLayoutContent[CONTENT_TYPE.NPC]) or 0

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    -- Scrollview尺寸变化的时候，立即刷新
    UIHelper.SetImmediatelyDoLayoutWhenSizeChange(self.ScrollViewTab, true)

    self:ResetUnRead()
    self:UpdateInfo()
    self:AppendInput(szSendContent)
end

function UIChatView:OnExit()
    self.bInit = false
    self:UnRegEvent()

    self.nCurChannelCount = 0
    self:ResetUnRead()
    ChatData.StopSearch()
    self:UnInitScrollList()

    -- 红点反注册
    for k, v in ipairs(self.tbChannelToggle) do
        local imgRedpoint = v:getChildByName("imgRedpoint")
        RedpointMgr.UnRegisterRedpoint(imgRedpoint)
    end

    ChatData.ResizeChatData(szUIChannel)

    ChatVoiceMgr.CancelRecording()
    ChatVoiceMgr.StopPlayFile()
end

function UIChatView:InitLayoutContent(nContentHeight)
    local tbChatConf = ChatData.GetChatConfByUIChannel(self.szCurUIChannel)
    local nContentType = tbChatConf and tbChatConf.nContentType or CONTENT_TYPE.NORMAL

    if self.bIsMobileInputMode then
        nContentType = CONTENT_TYPE.INPUT_MODE
    else
        -- 如果正在查找，那就是大尺寸模式
        if ChatData.IsSearching() then
            nContentType = CONTENT_TYPE.BIG
        elseif self.szCurUIChannel == UI_Chat_Channel.AllWorld then
            if not self:CanShowAllWorldInput() then
                nContentType = CONTENT_TYPE.BIG
            end
        elseif self.szCurUIChannel == UI_Chat_Channel.Whisper then
            if ChatRecentMgr.Check_WhisperIsLocked() then
                nContentType = CONTENT_TYPE.SMALL_WHISPER
            end
        elseif self.szCurUIChannel == UI_Chat_Channel.AINpc then
            nContentType = CONTENT_TYPE.NPC
        end
    end

    self.LayoutContent = self.tbLayoutContent[nContentType]
    self.LayoutContent:setClippingEnabled(true, true) -- 聊天的Layout清除所有模版

    if nContentHeight then
        UIHelper.SetHeight(self.LayoutContent, nContentHeight)
    end

    UIHelper.SetTabVisible(self.tbLayoutContent, false)
    UIHelper.SetVisible(self.LayoutContent, true)

    self:LayoutDelayShow()
end

-- 在聊天内容较少的情况下，聊天内容要置顶显示，会出现拉一下的情况，因此这里做个延时，让LayoutContent晚点出现
function UIChatView:LayoutDelayShow()
    UIHelper.SetOpacity(self.LayoutContent, 0)
    Timer.DelTimer(self, self.nTimerID)
    self.nTimerID = Timer.AddFrame(self, 2, function()
        UIHelper.SetOpacity(self.LayoutContent, 255)
    end)
end

function UIChatView:InitScrollList(nContentHeight)
    self:UnInitScrollList()
    self:InitLayoutContent(nContentHeight)

	self.tScrollList = UIScrollList.Create({
		listNode = self.LayoutContent,
        nReboundScale = 1,
		fnGetCellType = function(nIndex)
            return self:GetCellType(nIndex)
        end,
		fnUpdateCell = function(cell, nIndex)
			self:UpdateOneCell(cell, nIndex)
		end,
	})
    --self.tScrollList:SetScrollBarEnabled(true)
end

function UIChatView:UnInitScrollList()
	if self.tScrollList then
		self.tScrollList:Destroy()
		self.tScrollList = nil
	end
end

function UIChatView:GetCellType(nIndex)
    local tbData
    local nPrefabID
    if self.szCurUIChannel == UI_Chat_Channel.Whisper then
        if not ChatRecentMgr.Check_WhisperIsLocked() then
            local nSize = ChatRecentMgr.GetContectRecentWhisperSize(self.szGlobalID)    --聊天历史长度
            local nbeCalledSize = ChatRecentMgr.GetSpecialMsgSize(self.szCurWhisper)   --不会记录到历史聊天的特殊消息长度长度
            local nCurCount = ChatRecentMgr.GetCurWhisperSize(self.szCurWhisper)    --本次聊天长度
            local nTotalSize = nSize > 0 and nSize + nbeCalledSize or nCurCount        --所有消息总长度
            local nRealHistorySize = nTotalSize - nCurCount                         --除了本次登录产生的聊天内容长度
            if nIndex <= nRealHistorySize and nSize > 0 then  --读历史消息
                tbData = ChatRecentMgr.GetContactRecentWhisperInfoByIndex(self.szGlobalID, self.szCurWhisper, nRealHistorySize - nIndex + 1 + nCurCount - nbeCalledSize)
                if tbData then
                    nPrefabID = ChatRecentMgr.GetPrefabID(tbData.tbContentInfo.szSenderGlobalID, tbData.tbInfo)
                end
            else
                tbData = ChatData.GetOneData(UI_Chat_Channel.Whisper, nIndex - nRealHistorySize, self.szCurWhisper)
                if tbData then
                    nPrefabID = tbData.nPrefabID
                end
            end
        else
            tbData = ChatData.GetOneData(UI_Chat_Channel.Whisper, nIndex, self.szCurWhisper)
            local bIsSelf = tbData.dwTalkerID == UI_GetClientPlayerID()
            if not string.is_nil(tbData.szGlobalID) then
                bIsSelf = tbData.szGlobalID == UI_GetClientPlayerGlobalID()
            end
            if (bIsSelf and not ChatRecentMgr.Check_ChatIsLocked()) or not bIsSelf then
                nPrefabID = tbData.nPrefabID
            end
        end
    elseif self.szCurUIChannel == UI_Chat_Channel.AINpc then
        tbData = ChatAINpcMgr.GetOneData(self.dwCurAINpcID, nIndex)
        if tbData then
            nPrefabID = tbData.nPrefabID
        end
    else
        tbData = ChatData.GetOneData(self.szCurUIChannel, nIndex, self.szCurWhisper)
        nPrefabID = tbData.nPrefabID
    end

    return nPrefabID
end

function UIChatView:UpdateOneCell(cell, nIndex)
    if not cell then return end
    cell._keepmt = true
    local tbData
    if self.szCurUIChannel == UI_Chat_Channel.Whisper then
        if not ChatRecentMgr.Check_WhisperIsLocked() then   --历史记录
            local nSize = ChatRecentMgr.GetContectRecentWhisperSize(self.szGlobalID)    --聊天历史长度
            local nbeCalledSize = ChatRecentMgr.GetSpecialMsgSize(self.szCurWhisper)   --点名聊天长度
            local nCurCount = ChatRecentMgr.GetCurWhisperSize(self.szCurWhisper)    --本次聊天长度
            local nTotalSize = nSize > 0 and nSize + nbeCalledSize or nCurCount                                --所有消息总长度
            local nRealHistorySize = nTotalSize - nCurCount                         --除了本次登录产生的聊天内容长度
            if nIndex <= nRealHistorySize and nSize > 0 then  --读历史消息
                tbData = ChatRecentMgr.GetContactRecentWhisperInfoByIndex(self.szGlobalID, self.szCurWhisper, nRealHistorySize - nIndex + 1 + nCurCount - nbeCalledSize)
                if tbData then
                    tbData = self:ParseChatInfo(tbData)
                end
            else
                tbData = ChatData.GetOneData(UI_Chat_Channel.Whisper, nIndex - nRealHistorySize, self.szCurWhisper)
            end
        else    --本次登录
            tbData = ChatData.GetOneData(UI_Chat_Channel.Whisper, nIndex, self.szCurWhisper)
            local bIsSelf = tbData.dwTalkerID == UI_GetClientPlayerID()
            if not string.is_nil(tbData.szGlobalID) then
                bIsSelf = tbData.szGlobalID == UI_GetClientPlayerGlobalID()
            end
            if bIsSelf and ChatRecentMgr.Check_ChatIsLocked() then
                tbData = nil
            end
        end
    elseif self.szCurUIChannel == UI_Chat_Channel.AINpc then
        tbData = ChatAINpcMgr.GetOneData(self.dwCurAINpcID, nIndex)
    else
        tbData = ChatData.GetOneData(self.szCurUIChannel, nIndex, self.szCurWhisper)
    end
    cell:OnEnter(nIndex, tbData)

    self:UpdateInfo_UnReadCount()
end

function UIChatView:UpdateRange()
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

function UIChatView:ResetUnRead()
    self.nRangeMin = nil
    self.nRangeMax = nil
    --self.bIsToBottom = true
end

function UIChatView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnSend, EventType.OnClick, function()
        self:Send()
    end)

    UIHelper.BindUIEvent(self.BtnSetting, EventType.OnClick, function()
        local tbBtnParams = {
            {
                szName = "聊天喊话",
                OnClick = function ()
                    UIMgr.Open(VIEW_ID.PanelAllShoutSetting)
                    TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipMoreOper)
                end
            },
            {
                szName = "聊天监控",
                OnClick = function()
                    UIMgr.Open(VIEW_ID.PanelChatMonitor)
                    TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipMoreOper)
                end
            },
            {
                szName = "屏蔽关键词",
                OnClick = function ()
                    UIMgr.Open(VIEW_ID.PanelGameSettings, SettingCategory.WordBlock)
                    TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipMoreOper)
                end
            },
            {
                szName = "聊天设置",
                OnClick = function ()
                    local nIndex = ChatData.GetSettingIndex(self.szCurUIChannel)
                    UIMgr.Open(VIEW_ID.PanelChatSettings, nIndex)
                    TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipMoreOper)
                end
            },
        }

        local nOffset = 10
        if ChatData.CanUseBullet() then
            local tbDanmu = {
                szName = "弹幕设置",
                OnClick = function ()
                    UIMgr.Open(VIEW_ID.PanelDanmuSetting)
                    TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipMoreOper)
                end
            }

            table.insert(tbBtnParams, 1, tbDanmu)
            nOffset = -20
        end

        APIHelper.ShowMoreOperTips(self.BtnSetting, tbBtnParams, 0, nOffset)
    end)

    local funcDoSearch = function()
        local szSearchValue = UIHelper.GetString(self.EditBoxSearch)
        szSearchValue = string.trim(szSearchValue, " ")
		--szSearchValue = string.trim(szSearchValue, g_tStrings.STR_ONE_CHINESE_SPACE)

        -- if szSearchValue == self.szLastSearchValue then
        --     return
        -- end

        if string.is_nil(szSearchValue) then
            ChatData.StopSearch()
        else
            ChatData.StartSearch(szSearchValue)
        end

        self:UpdateInfo_Content()

        self.szLastSearchValue = szSearchValue

        self:OnSelectedChannel(self.tbCurChannelConf, true)
    end
    if Platform.IsMac() then
        UIHelper.RegisterEditBoxReturn(self.EditBoxSearch, function()
            funcDoSearch()
        end)
    else
        UIHelper.RegisterEditBoxEnded(self.EditBoxSearch, function()
            funcDoSearch()
        end)
    end

    UIHelper.BindUIEvent(self.BtnMoreMessage, EventType.OnClick,function()
        self.bIsToBottom = true
        self:ResetUnRead()
        self:UpdateInfo_UnReadCount()
        self:UpdateInfo_Content()
    end)

    UIHelper.BindUIEvent(self.BtnEmptyOperater, EventType.OnClick, function()
        if self.szCurUIChannel == UI_Chat_Channel.Team then
            UIMgr.Open(VIEW_ID.PanelTeam)
        elseif self.szCurUIChannel == UI_Chat_Channel.Tong then
            TongData.OpenTongPanel()
        elseif self.szCurUIChannel == UI_Chat_Channel.Camp then
            UIMgr.Open(VIEW_ID.PanelPvPCampJoin)
        elseif self.szCurUIChannel == UI_Chat_Channel.Identity then
            JiangHuData.OnClickEntrance()
        elseif self.szCurUIChannel == UI_Chat_Channel.Room then
            UIMgr.Open(VIEW_ID.PanelTeam, 4)
        elseif self.szCurUIChannel == UI_Chat_Channel.AllWorld then
            CampData.OnClickCampPVPField()
        end

        UIMgr.Close(VIEW_ID.PanelChatSocial)
    end)

    UIHelper.BindUIEvent(self.BtnEmoji, EventType.OnClick, function()
        self:ShowEmoji()
    end)

    UIHelper.BindUIEvent(self.BtnAddChat, EventType.OnClick, function()
        local viewScript = UIMgr.OpenSingle(false, VIEW_ID.PanelChatSocial, 2)
        if viewScript then
            viewScript:OnEnter(2, 2)
        end
    end)

    UIHelper.BindUIEvent(self.BtnSwitch, EventType.OnClick, function()
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetChatSwitchTip, self.BtnSwitch, TipsLayoutDir.TOP_CENTER, UI_Chat_Switch_Type.All)
    end)

    UIHelper.BindUIEvent(self.BtnMic, EventType.OnClick, function()
        if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TALK, "player talk") then
            return
        end

        if not GVoiceMgr.IsMicAvail() then
            TipsHelper.ShowNormalTip("当前没有可用麦克风")
            return
        end

        local nChannelID = ChatData.GetSendChannelID()
        ChatData.SetChannelVoiceModel(nChannelID, true)

        self:UpdateVoice()
    end)

    UIHelper.BindUIEvent(self.BtnKeyboard, EventType.OnClick, function()
        local nChannelID = ChatData.GetSendChannelID()
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
        UIHelper.RegisterEditBox(self.EditBoxSendNormal, function(szType) fnEditBoxSend(szType) end)
        UIHelper.RegisterEditBox(self.EditBoxSendShort, function(szType) fnEditBoxSend(szType) end)
        self.EditBoxSendNormal:enableInputFieldHidden(false)
        self.EditBoxSendShort:enableInputFieldHidden(false)
    else
        local fnEditBoxSend = function(szType)
            if szType == "ended" then
                self:SetEditBoxSendString(UIHelper.GetString(self.EditBoxSend))
            elseif szType == "return" then
                self:Send()
            end
        end
        UIHelper.RegisterEditBox(self.EditBoxSendNormal, function(szType) fnEditBoxSend(szType) end)
        UIHelper.RegisterEditBox(self.EditBoxSendShort, function(szType) fnEditBoxSend(szType) end)
    end

    UIHelper.BindUIEvent(self.BtnRecentChat, EventType.OnClick, function()
        local viewScript = UIMgr.OpenSingle(false, VIEW_ID.PanelChatSocial, 2)
        if viewScript then
            viewScript:OnEnter(2, 1)
        end
    end)

    UIHelper.BindUIEvent(self.BtnAddWisperEmpty, EventType.OnClick, function()
        local viewScript = UIMgr.OpenSingle(false, VIEW_ID.PanelChatSocial, 2)
        if viewScript then
            local nSubIndex = (self.szCurUIChannel == UI_Chat_Channel.Whisper) and 2 or 4
            viewScript:OnEnter(2, nSubIndex)
        end
    end)

    UIHelper.BindUIEvent(self.BtnWhisperSetting, EventType.OnClick, function()
        local nIndex = ChatData.GetSettingIndex(UI_Chat_Channel.Whisper)
        UIMgr.Open(VIEW_ID.PanelChatSettings, nIndex)
    end)

    UIHelper.BindUIEvent(self.BtnEmojiBox, EventType.OnClick, function()
        self:HideEmoji()
    end)

    UIHelper.BindUIEvent(self.BtnEmojiKeyBoard, EventType.OnClick, function()
        if self.EditBoxSend then
            self.EditBoxSend:openKeyboard()
        end
    end)

    UIHelper.BindUIEvent(self.ScrollViewWhisper, EventType.OnChangeSliderPercent, function (_, eventType)
		if eventType == ccui.ScrollviewEventType.containerMoved then
			self:UpdateRedPointArrow()
		end
	end)


    UIHelper.BindUIEvent(self.BtnADelChat, EventType.OnClick, function ()
        if self.szGlobalID and self.szCurWhisper then
            local callback = function()
                local szTips = string.format("是否删除联系人【%s】的聊天记录？", self.szCurWhisper)
                local confirm = UIHelper.ShowConfirm(szTips, function()
                    ChatRecentMgr.DelChatHistory(self.szGlobalID, self.szCurWhisper)
                end)
            end
            if ChatRecentMgr.GetRecentLockState() then
                if BankLock.IsPhoneLock() then
                    UIMgr.OpenSingle(false, VIEW_ID.PanelLingLongMiBao, nil, callback)
                else
                    UIMgr.OpenSingle(false, VIEW_ID.PanelPasswordUnlockPop, callback)
                end
            else
                callback()
            end
        else
            TipsHelper.ShowNormalTip("当前没有可删除的联系人")
        end
	end)
end

function UIChatView:RegEvent()
    Event.Reg(self, EventType.OnWindowsSetFocus, function()
        Timer.DelTimer(self, self.nDoLayoutTimerID)
        self.nDoLayoutTimerID = Timer.AddFrame(self, 1, function()
            self:UpdateInfo_DoLayout()
        end)
    end)

    Event.Reg(self, EventType.OnReceiveChat, function(tbData, bToTop)
        self:OnReceive(tbData, bToTop)
    end)

    Event.Reg(self, EventType.OnChatEmojiClosed, function()
        self:HideEmoji()
    end)

    Event.Reg(self, EventType.OnChatEmojiSelected, function(tbEmojiConf)
        if UIMgr.IsViewOpened(VIEW_ID.PanelAllShoutSetting) then
            return
        end

        --self:HideEmoji()

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

    Event.Reg(self, EventType.OnChatWhisperSelected, function(szCurWhisper)
        local tbData = ChatData.GetWhisperPlayerData(szCurWhisper)
        if not tbData then return end
        ChatRecentMgr.ClearNewMsg(tbData.szGlobalID)
        if self.szGlobalID == tbData.szGlobalID and self.szCurWhisper == szCurWhisper then
            return
        end

        self.szCurWhisper = szCurWhisper
        ChatRecentMgr.SetCurWhisperPlayerName(szCurWhisper)

        self.szGlobalID = tbData.szGlobalID
        self:UpdateWhisperContent()
    end)

    Event.Reg(self, EventType.OnChatAINpcSelected, function(dwID)
        -- local tbData = ChatData.GetWhisperPlayerData(szCurWhisper)
        -- if not tbData then return end
        -- ChatRecentMgr.ClearNewMsg(tbData.szGlobalID)
        -- if self.szGlobalID == tbData.szGlobalID and self.szCurWhisper == szCurWhisper then
        --     return
        -- end

        -- self.szCurWhisper = szCurWhisper
        -- ChatRecentMgr.SetCurWhisperPlayerName(szCurWhisper)

        -- self.szGlobalID = tbData.szGlobalID
        self.dwCurAINpcID = dwID
        ChatAINpcMgr.SetCurAINpcID(dwID)
        self:UpdateAINpcContent()
    end)

    Event.Reg(self, EventType.OnChatWhisperDeleted, function(szName)
        if self.szCurWhisper == szName then
            self.szCurWhisper = nil
            self.szGlobalID = nil
            ChatRecentMgr.SetCurWhisperPlayerName()
        end

        self:UpdateWhisperList()
    end)

    Event.Reg(self, EventType.OnChatAINpcDeleted, function(dwID)
        if self.dwCurAINpcID == dwID then
            self.dwCurAINpcID = nil
            ChatAINpcMgr.SetCurAINpcID()
        end

        self:UpdateAINpcList()
        self:UpdateAINpcMood()
    end)

    Event.Reg(self, EventType.OnChatContentCopy, function(szContent)
        self:SetEditBoxSendString(szContent)
    end)

    Event.Reg(self, "ProcessJiangHuWord", function(tJiangHu)
        self:SendJiangHuWord(tJiangHu)
    end)

    Event.Reg(self, "SendEmotionAction", function(tEmotionAction)
        self:SendEmotionAction(tEmotionAction)
    end)

    Event.Reg(self, EventType.OnUIScrollListTouchMove, function()
        if not self.tScrollList then
            return
        end
        local nPercentage = self.tScrollList:GetPercentage()
        if nPercentage < 1 then
            self.bIsToBottom = false
        else
            self.bIsToBottom = true
        end
    end)

    Event.Reg(self, EventType.OnWindowsSizeChanged, function(width, height)
        self:HideEmoji()
        self:UpdateInfo_Bg()
        self:UpdateSwitch()

        Timer.DelTimer(self, self.nUpdateLayoutTimerID)
        self.nUpdateLayoutTimerID = Timer.AddFrame(self, 5, function()
            self:UpdateInfo_DoLayout()
        end)

        local bNowWindowsIsMinimized = (width == 0 and height == 0)
        if self.bWindowsIsMinimized and not bNowWindowsIsMinimized then
            self:UpdateInfo_Content()
        end

        self.bWindowsIsMinimized = bNowWindowsIsMinimized
    end)

    Event.Reg(self, EventType.OnChatSettingSyncServerData, function()
        self:OnEnter(self.szCurUIChannel)
        self:UpdateSendButton()
        self:UpdateVoice()
    end)

    Event.Reg(self, EventType.OnChatSettingSaved, function(bIsFromSettingView)
        if bIsFromSettingView then
            self:OnEnter(self.szCurUIChannel)
            self:UpdateSwitch()
        else
            self:UpdateSwitch()
        end

        self:UpdateSendButton()
        self:UpdateVoice()
    end)

    Event.Reg(self, EventType.OnChatSendChannelChanged, function(szUIChannel, nChannelID)
        self:UpdateSwitch()
        self:UpdateSendButton()
        self:UpdateVoice()
    end)

    Event.Reg(self, EventType.OnViewOpen, function(nViewID)
        local conf = TabHelper.GetUIViewTab(nViewID)
        if not conf then
            return
        end

        if nViewID == VIEW_ID.PanelTeach_UIPageLayer or
            nViewID == VIEW_ID.PanelTeach_UIPopupLayer or
            nViewID == VIEW_ID.PanelTeach_UIMessageBoxLayer then
            return
        end

        local szLayer = UIMgr.GetViewLayerByViewID(nViewID)
        if szLayer == UILayer.Page or
            szLayer == UILayer.Popup or
            szLayer == UILayer.MessageBox or
            szLayer == UILayer.SystemPop then
            self:CancelRecording()
        end
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

    Event.Reg(self, EventType.OnChatVoiceRecordFailed, function(bStream, filepath)
        if not bStream then return end
        self:CancelRecording()
    end)

    Event.Reg(self, EventType.OnChatUIChannelNicknameChanged, function()
        self:UpdateInfo_List_Name()
    end)

    Event.Reg(self, EventType.OnChatSyncMiniChat, function(bSync)
        self:UpdateInfo_MiniChatSyncState()
    end)

    Event.Reg(self, EventType.OnChatWhisperNameChanged, function(szOldName, szNewName)
        local szCurWhisper = ChatRecentMgr.GetCurWhisperPlayerName()
        if szCurWhisper == szOldName then
            ChatRecentMgr.SetCurWhisperPlayerName(szNewName)
        end
        self:UpdateWhisperList()
    end)

    -- 队伍被开
    Event.Reg(self, "PARTY_DELETE_MEMBER", function(dwTeamID, dwMemberID, szName, nGroupIndex)
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetChatSwitchTip)
        if self.szCurUIChannel ~= UI_Chat_Channel.Team then return end
        if g_pClientPlayer and g_pClientPlayer.dwID == dwMemberID then
            self:UpdateSwitch()
            self:UpdateSendButton()
            self:UpdateVoice()
        end
    end)

    -- 队伍解散
    Event.Reg(self, "PARTY_DISBAND", function(dwTeamID)
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetChatSwitchTip)
        if self.szCurUIChannel ~= UI_Chat_Channel.Team then return end
        self:UpdateSwitch()
        self:UpdateSendButton()
        self:UpdateVoice()
    end)

    -- 进入队伍
    Event.Reg(self, "PARTY_MESSAGE_NOTIFY", function(nCode, szName)
        if nCode == PARTY_NOTIFY_CODE.PNC_PARTY_CREATED or nCode == PARTY_NOTIFY_CODE.PNC_PARTY_JOINED then
            TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetChatSwitchTip)
            if self.szCurUIChannel ~= UI_Chat_Channel.Team then return end
            Event.Reg(self, "PARTY_UPDATE_BASE_INFO", function()
                Event.UnReg(self, "PARTY_UPDATE_BASE_INFO")
                self:UpdateSwitch()
                self:UpdateSendButton()
                self:UpdateVoice()
            end)
        end
    end)

    Event.Reg(self, EventType.OnChatWhisperMiBaoUnLockSuccessed, function()
        if self.szCurUIChannel == UI_Chat_Channel.Whisper then
            self:InitScrollList()
            self:UpdateWhisperList()
            self:UpdateInfo_WhisperHistory()

            Timer.DelTimer(self, self.nDoLayoutTimerID)
            self.nDoLayoutTimerID = Timer.AddFrame(self, 1, function()
                self:UpdateInfo_DoLayout()
            end)
        end
    end)

    self:RegKeyBoardEvent()

    -- Event.Reg(self, EventType.OnSelectChatViewChannel, function(szUIChannel, szSendContent)
    --     self:SelectChannel(szUIChannel, szSendContent)
    -- end)

    Event.Reg(self, "RECENTLY_MSG_CHANGE", function(szGlobalID)
        if self.szCurUIChannel == UI_Chat_Channel.Whisper and self.szGlobalID == szGlobalID then
            self:UpdateWhisperContent()
        end
    end)

    Event.Reg(self, EventType.OnChatMengXinShow, function(bShow)
        if not bShow and self.szCurUIChannel == UI_Chat_Channel.Identity then
            self.szTarUIChannel = UI_Chat_Channel.All
        end
        self:UpdateInfo_List()
        self:UpdateSwitch()
    end)

    Event.Reg(self, EventType.OnChatAINpcWaiting, function(bIsChatWaiting)
        self:UpdateSendButton()
    end)

    Event.Reg(self, EventType.OnChatAINpcFiltering, function(bIsChatFiltering)
        self:UpdateSendButton()
    end)

    Event.Reg(self, EventType.OnChatAINpcFetchDoneChange, function(dwNpcId)
        if self.dwCurAINpcID == dwNpcId then
            self:UpdateAINpcMood()
        end
    end)
end

function UIChatView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)

end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIChatView:UpdateInfo()
    self:UpdateInfo_List()
    self:UpdateInfo_Bg()
    self:UpdateInfo_MiniChatSyncState()
end

function UIChatView:UpdateInfo_List()
    local tbChannelList = ChatData.GetUIChannelList()
    local nLen = #tbChannelList
    local nFirstSelectIdx = nil

    self.tbUIChannelToToggleIndex = {}

    for k, v in ipairs(self.tbChannelToggle) do
        local imgRedpoint = v:getChildByName("imgRedpoint")
        local labelRedpoint = imgRedpoint and imgRedpoint:getChildByName("LabelRedPoint")
        UIHelper.SetVisible(imgRedpoint, false)
        RedpointMgr.UnRegisterRedpoint(imgRedpoint)

        local bContinue = false
        local tbOneChannel = tbChannelList[k]

        if tbOneChannel then
            if tbOneChannel.szUIChannel == UI_Chat_Channel.Identity then
                bContinue = not ChatData.bShowMXChnl
            elseif tbOneChannel.szUIChannel == UI_Chat_Channel.AINpc then
                bContinue = not ChatAINpcMgr.IsOpen()
            end
        end

        if tbOneChannel and not bContinue then
            self.tbUIChannelToToggleIndex[tbOneChannel.szUIChannel] = k

            local szName = ChatData.GetUIChannelNickName(tbOneChannel.szUIChannel)
            UIHelper.SetVisible(UIHelper.GetParent(v), true)
            UIHelper.SetString(v:getChildByName("LabelUsual"), szName)
            UIHelper.SetString(v:getChildByName("LabelUp"), szName)
            UIHelper.SetVisible(v:getChildByName("ImgTabLine"), nLen ~= k)

            -- 红点注册
            local tbRedPoints = tbOneChannel.tbRedPoints
            if not table.is_empty(tbRedPoints) then
                RedpointMgr.RegisterRedpoint(imgRedpoint, labelRedpoint, tbRedPoints)
            end

            UIHelper.BindUIEvent(v, EventType.OnSelectChanged, function(toggle, bSelected)
                if bSelected then
                    if not self.bFirstSelected or self.szCurUIChannel ~= tbOneChannel.szUIChannel then
                        self:ChangeChannelWhenOpen(tbOneChannel.szUIChannel)

                        ChatData.ResizeChatData(self.szCurUIChannel)
                        --self:SetEditBoxSendString("")
                        ChatData.StopSearch()
                        self:OnSelectedChannel(tbOneChannel)
                        self:AppendInput()
                    end

                    self.bFirstSelected = true
                end
            end)

            if tbOneChannel.szUIChannel == self.szTarUIChannel then
                nFirstSelectIdx = k
            end
        else
            UIHelper.SetVisible(UIHelper.GetParent(v), false)
        end
    end

    if nFirstSelectIdx then
        UIHelper.SetSelected(self.tbChannelToggle[nFirstSelectIdx], true)
    else
        nFirstSelectIdx = 1
        UIHelper.SetSelected(self.tbChannelToggle[nFirstSelectIdx], true)
    end

    UIHelper.ScrollViewDoLayout(self.ScrollViewTab)

    if nFirstSelectIdx < 9 then
        UIHelper.ScrollToTop(self.ScrollViewTab)
    else
        Timer.AddFrame(self, 1, function()
            UIHelper.ScrollToBottom(self.ScrollViewTab)
        end)
    end
end

function UIChatView:UpdateInfo_List_Name()
    for szUIChannel, nIndex in pairs(self.tbUIChannelToToggleIndex) do
        local tog = self.tbChannelToggle[nIndex]
        if tog then
            local szName = ChatData.GetUIChannelNickName(szUIChannel)
            UIHelper.SetString(tog:getChildByName("LabelUsual"), szName)
            UIHelper.SetString(tog:getChildByName("LabelUp"), szName)
        end
    end
end

function UIChatView:OnSelectedChannel(tbChannelConf, bForceUpdate)
    --if not bForceUpdate and self.szCurUIChannel == tbChannelConf.szUIChannel then return end

    if not bForceUpdate and tbChannelConf.szUIChannel == "UI_Channel_Tong" then
        TongData.RequestBaseData()
    end

    self.szCurUIChannel = tbChannelConf.szUIChannel
    self.tbCurChannelConf = tbChannelConf

    ChatData.SetRuntimeSelectDisplayChannel(self.szCurUIChannel)

    local bIsWhisper = self.szCurUIChannel == UI_Chat_Channel.Whisper
    local bIsAINpc = self.szCurUIChannel == UI_Chat_Channel.AINpc
    local bIsAllWorld = self.szCurUIChannel == UI_Chat_Channel.AllWorld

    -- Empty
    do
        UIHelper.SetVisible(self.WidgetEmpty, false)
        UIHelper.SetString(self.LabelEmptyDesc, "")
        UIHelper.SetVisible(self.BtnEmptyOperater, false)
        UIHelper.SetString(self.LabelEmptyOperater, "")
        UIHelper.SetVisible(self.WidgetOtherBtn, false)
        UIHelper.SetVisible(self.LayOutChatContent, true)
    end

    -- Whisper | AINpc
    do
        --UIHelper.SetVisible(self.WidgetSettingContainer, false) -- 查找隐藏
        UIHelper.SetVisible(self.WidgetSetting, not bIsWhisper and not bIsAINpc) -- 非密聊和非AI NPC显示设置按钮
        UIHelper.SetVisible(self.WidgetWhisper, bIsWhisper or bIsAINpc)
        UIHelper.SetVisible(self.WidgetWisperSetting, bIsWhisper)
        self:UpdateWhisperList()
        self:UpdateAINpcList()
        self:UpdateAINpcMood()
    end

    -- Send
    do
        if ChatData.IsSearching() then -- 查找时，不显示输入框
            UIHelper.SetVisible(self.WidgetSend, false)
        elseif bIsAllWorld then
            if not self:CanShowAllWorldInput() then -- 非跨服，全服频道不显示输入框
                UIHelper.SetVisible(self.WidgetSend, false)
            end
        else
            local bNotShowSend = self.szCurUIChannel == UI_Chat_Channel.System or self.szCurUIChannel == UI_Chat_Channel.Fight
            UIHelper.SetVisible(self.WidgetSend, not bNotShowSend)

            if bIsWhisper then
                UIHelper.SetVisible(self.WidgetSend, self.szCurWhisper ~= nil)
            end
        end
    end

    -- Search
    do
        if not bForceUpdate then
            UIHelper.SetString(self.EditBoxSearch, "")
        end
    end

    -- Switch
    do
        self:UpdateSwitch()
    end

    -- Send Button
    self:UpdateSendButton()

    -- Voice
    self:UpdateVoice()

    self:UpdateScrollList()

    Event.Dispatch(EventType.OnChatViewChannelChanged, self.szCurUIChannel)
end

function UIChatView:UpdateInfo_Content()
    local nDataLen = ChatData.GetDataListLen(self.szCurUIChannel, self.szCurWhisper)
    local nHistorySize = ChatRecentMgr.GetContectRecentWhisperSize(self.szGlobalID)

    if self.szCurUIChannel == UI_Chat_Channel.Whisper and not ChatRecentMgr.Check_WhisperIsLocked() and nHistorySize > 0 then
        nDataLen = ChatRecentMgr.GetContectRecentWhisperSize(self.szGlobalID) + ChatRecentMgr.GetSpecialMsgSize(self.szCurWhisper)
    end

    if self.tScrollList then
        if nDataLen == 0 then
            self.tScrollList:Reset(nDataLen) --完全重置，包括速度、位置
        else
            self.tScrollList:ResetWithStartIndex(nDataLen, nDataLen)
        end
    end

    self.nCurChannelCount = nDataLen

    self:ResetUnRead()
    self:UpdateInfo_UnReadCount()
    self:UpdateInfo_WhisperHistory()
end

function UIChatView:UpdateInfo_DoLayout()
    UIHelper.LayoutDoLayout(self.LayOutChatContent)

    -- LayOutChatContent 变化之后，需要刷新未读按钮的位置
    local nX, nY = UIHelper.GetPosition(self.LayOutChatContent)
    local nHeight = UIHelper.GetHeight(self.LayOutChatContent)
    UIHelper.SetPositionY(self.BtnMoreMessage, nY - nHeight + 50)
end

function UIChatView:OnReceive(tbData, bToTop)
    if self.bWindowsIsMinimized then return end

    if not tbData then return end
    if not tbData.tbUIChannelMap then return end
    if not tbData.tbUIChannelMap[self.szCurUIChannel] then
        if not tbData.bBeCalled then
            return
        end
    end

    local nDataLen = ChatData.GetDataListLen(self.szCurUIChannel, self.szCurWhisper)
    -- 如果当前频道数据太长了，就清理一下，然后滚动到最后
    if ChatData.CheckNeedResize(nDataLen) then
        ChatData.ResizeChatData(self.szCurUIChannel)
        self:UpdateInfo_Content()
        return
    end

    local bIsSelf = PlayerData.IsSelf(tbData.dwTalkerID)
    local bIsWhisper = self.szCurUIChannel == UI_Chat_Channel.Whisper
    local nPercentage = self.tScrollList:GetPercentage()
    local min, max = self.tScrollList:GetIndexRangeOfLoadedCells()
    local nHistorySize = ChatRecentMgr.GetContectRecentWhisperSize(self.szGlobalID)

    if bIsWhisper and not ChatRecentMgr.Check_WhisperIsLocked() and nHistorySize > 0 then
        nDataLen = nHistorySize + ChatRecentMgr.GetSpecialMsgSize(self.szCurWhisper)
    end

    if not bIsWhisper or (not string.is_nil(self.szCurWhisper) and self.szCurWhisper == tbData.szName) then
        self.nCurChannelCount = nDataLen

        self.tScrollList:ReloadWithStartIndex(nDataLen, min) --刷新数量

        if not bToTop and (self.bIsToBottom or bIsSelf or bIsWhisper) then
            self.tScrollList:ScrollToIndex(nDataLen)
        end
    end

    -- 如果默认选中的就是密聊对象发来的消息，就不要显示红点了
    if bIsWhisper then
        self:UpdateRedPointArrow()
        if not string.is_nil(self.szCurWhisper) and self.szCurWhisper == tbData.szName then
            --ChatData.RemoveFromWhisperUnread(self.szCurWhisper)
            local tbData = ChatData.GetWhisperPlayerData(self.szCurWhisper)
            if not tbData then return end
            ChatRecentMgr.ClearNewMsg(tbData.szGlobalID)
        else
            local nOpenDisturbTime = ChatData.CheckWhisperIsOpenDisturb()
            local bFriend = FellowshipData.IsFriend(tbData.szGlobalID)
            if bFriend or (not nOpenDisturbTime) then
                self:UpdateWhisperList(true)
            end
        end

    end

    self:UpdateInfo_UnReadCount()
end

function UIChatView:Send(tbSendMsg)
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

    local nChannelID = ChatData.GetSendChannelID()
    local nCDTime = ChatData.GetChannelSendCDTime(nChannelID)
    if nCDTime > 0 then
        TipsHelper.ShowNormalTip(g_tStrings.tTalkError[PLAYER_TALK_ERROR.SCENE_CD])
        return
    end

    local szMsg = UIHelper.GetString(self.EditBoxSend)

    if not string.is_nil(szMsg) or (tbSendMsg and not table.is_empty(tbSendMsg)) then
        local bResult = nil
        if self.szCurUIChannel == UI_Chat_Channel.AINpc then
            if string.is_nil(szMsg:gsub("^%s+", "")) then
                TipsHelper.ShowNormalTip("请输入聊天内容")
                return
            end
            --bResult = ChatAINpcMgr.Chat(self.dwCurAINpcID, szMsg)
            -- AIAgentChat 使用表情等其他标签
            local tbMsg = tbSendMsg or ChatParser.Parse(szMsg)
            bResult = ChatAINpcMgr.Chat(self.dwCurAINpcID, JsonEncode(tbMsg))
        else
            local tbMsg = tbSendMsg or ChatParser.Parse(szMsg)
            local szReceiver = nil
            if self.szCurUIChannel == UI_Chat_Channel.Whisper then
                if self.szCurWhisper then
                    local tbData = ChatData.GetWhisperPlayerData(self.szCurWhisper)
                    szReceiver = UTF8ToGBK(tbData and tbData.szName)
                end
            end

            bResult = ChatData.Send(nChannelID, szReceiver, tbMsg)
        end



        --LOG.ERROR(tostring(bResult))
        if bResult then
            self:SetEditBoxSendString("")
            ChatData.RecordSendTime(nChannelID)
            self:UpdateSendButton()
            ChatArgs.Clear(self.szCurUIChannel)
        end
    end
end

-- 刷新未读消息
function UIChatView:UpdateInfo_UnReadCount()
    self:UpdateRange()

    local nUnReadCount = self.nCurChannelCount - self.nRangeMax - 1

    Timer.DelTimer(self, self.nUnReadTimerID)
    local bVisible = nUnReadCount > 0
    if bVisible then
        self.nUnReadTimerID = Timer.AddFrame(self, 1, function()
            UIHelper.SetActiveAndCache(self, self.BtnMoreMessage, true)
            ChatData.SetIsScrolling(false)
        end)
    else
        UIHelper.SetActiveAndCache(self, self.BtnMoreMessage, false)
        ChatData.SetIsScrolling(true)
    end

    UIHelper.SetString(self.LabelMoreMessage, string.format(g_tStrings.STR_CHAT_UNREADMESSAGE_COUNT, nUnReadCount))
end

-- 聊天表情
function UIChatView:_getEmojiParentNode()
    local parent = nil
    local parentScript = UIMgr.GetViewScript(VIEW_ID.PanelChatSocial)
    if parentScript then
        parent = parentScript.WidgetChatExpression
    end

    return parent
end

function UIChatView:_getChatParentNode()
    local parent = nil
    local parentScript = UIMgr.GetViewScript(VIEW_ID.PanelChatSocial)
    if parentScript then
        parent = parentScript.WidgetChatSocial
    end

    return parent
end

function UIChatView:ShowEmoji()
    if self.bIsShowEmoji then return end

    local emojiParent = self:_getEmojiParentNode()
    if not emojiParent then return end

    if not self.scriptEmoji then
        self.scriptEmoji = UIHelper.AddPrefab(PREFAB_ID.WidgetChatExpression, emojiParent)
    else
        if self.scriptEmoji.nCurGroupID == -1 then
            self.scriptEmoji:UpdateInfo_EmojiList()
        end
    end

    self.scriptEmoji:UpdateInfoByUIChannel(self.szCurUIChannel)

    UIHelper.SetVisible(emojiParent, true)
    UIHelper.SetVisible(self.BtnEmojiBox, true)

    if Platform.IsMobile() then
        UIHelper.SetVisible(self.BtnEmojiKeyBoard, true)
        -- 因为 self.BtnEmoji 在做语音切换时候会设置Visible，所以这里不重复设置Visible，不然会冲突
        self.nBtnEmojiPosY = UIHelper.GetPositionY(self.BtnEmoji)
        UIHelper.SetPositionY(self.BtnEmoji, -99999)
    end

    -- 聊天面板抬高
    local ImgBg = self.scriptEmoji.ImgBg
    local nOffset = math.abs(UIHelper.GetPositionY(ImgBg) or 0) - (UIHelper.GetHeight(ImgBg) or 0)
    local rootHeight = (UIHelper.GetHeight(self.scriptEmoji._rootNode) or 0) / 2
    local chatParent = self:_getChatParentNode()
    UIHelper.SetPositionY(chatParent, rootHeight - nOffset)

    self.bIsShowEmoji = true
end

function UIChatView:HideEmoji()
    if not self.bIsShowEmoji then return end

    local emojiParent = self:_getEmojiParentNode()
    if not emojiParent then
        return
    end

    UIHelper.SetVisible(emojiParent, false)
    UIHelper.SetVisible(self.BtnEmojiBox, false)

    if Platform.IsMobile() then
        UIHelper.SetVisible(self.BtnEmojiKeyBoard, false)
        -- 还原
        if self.nBtnEmojiPosY then
            UIHelper.SetPositionY(self.BtnEmoji, self.nBtnEmojiPosY)
        end
    end

    -- 聊天面板降低
    local chatParent = self:_getChatParentNode()
    UIHelper.SetPositionY(chatParent, 0)

    self.bIsShowEmoji = false
end

-- 密聊
function UIChatView:UpdateWhisperList(bNotDoLayout)
    if self.szCurUIChannel ~= UI_Chat_Channel.Whisper then return end

    local children = self.ScrollViewWhisper:getChildren()
    for k, v in ipairs(children or {}) do
        if v:getTag() == 10010 then
            self.ScrollViewWhisper:removeChild(v)
        end
    end

    local bWhisperLocked = ChatRecentMgr.Check_WhisperIsLocked()
    if not bWhisperLocked then
        for i, v in pairs(Storage.ChatWhisper.tbPlayerList) do
            local tbData = ChatData.GetWhisperPlayerData(v)
            if not tbData then
                table.remove_value(Storage.ChatWhisper.tbPlayerList, v)
            end
        end
    end

    local tbPlayerIDList = clone(Storage.ChatWhisper.tbPlayerList)
    tbPlayerIDList = ChatRecentMgr.SortPlayerIDList(tbPlayerIDList)

    local nIndex = 1
    local nCount = 0
    self.szCurWhisper = ChatRecentMgr.GetCurWhisperPlayerName()
    for k, v in ipairs(tbPlayerIDList) do
        if v and ChatData.GetWhisperPlayerData(v) then
            nCount = nCount + 1

            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetTogWisperPlayer, self.ScrollViewWhisper)
            script._rootNode:setTag(10010)
            if self.szCurWhisper then
                script:OnEnter(v, self.szCurWhisper == v)
                if self.szCurWhisper == v then
                    nIndex = nCount
                end
            else
                script:OnEnter(v, nCount == 1)
            end
        end
    end

    local bIsEmpty = (nCount == 0)
    UIHelper.SetVisible(self.WidgetWisperEmpty, bIsEmpty)
    UIHelper.SetString(self.LabelAddChat, "暂无最近联系人，点击邀请好友聊天")

    if bIsEmpty and self.tScrollList then
        self.tScrollList:Reload(0)
    end

    if not bNotDoLayout then
        Timer.AddFrame(self, 1, function ()
            UIHelper.ScrollViewDoLayout(self.ScrollViewWhisper)
            if nCount > 4 then
                UIHelper.ScrollToIndex(self.ScrollViewWhisper, nIndex - 1)
            else
                UIHelper.ScrollToLeft(self.ScrollViewWhisper)
            end
            self:UpdateRedPointArrow()
        end)
    end

    UIHelper.SetVisible(self.WidgetSend, self.szCurWhisper ~= nil)
end

function UIChatView:UpdateWhisperContent()
    if self.tScrollList == nil then
        self:InitScrollList()
    end
    self:UpdateInfo_Content()
    self:LayoutDelayShow()
end

function UIChatView:UpdateAINpcContent()
    if self.tScrollList == nil then
        self:InitScrollList()
    end
    self:UpdateInfo_Content()
    self:UpdateAINpcMood()
    self:LayoutDelayShow()
end

-- AI Npc 聊天
function UIChatView:UpdateAINpcList(bNotDoLayout)
    if self.szCurUIChannel ~= UI_Chat_Channel.AINpc then return end

    local children = self.ScrollViewWhisper:getChildren()
    for k, v in ipairs(children or {}) do
        if v:getTag() == 10010 then
            self.ScrollViewWhisper:removeChild(v)
        end
    end

    local tbAINpcList = clone(Storage.ChatAINpc.tbAINpcList)

    local nIndex = 1
    local nCount = 0
    self.dwCurAINpcID = ChatAINpcMgr.GetCurAINpcID()
    for k, v in ipairs(tbAINpcList) do
        if v then
            nCount = nCount + 1

            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetTogWisperPlayer, self.ScrollViewWhisper)
            script._rootNode:setTag(10010)
            if self.dwCurAINpcID then
                script:OnEnter(v, self.dwCurAINpcID == v, true)
                if self.dwCurAINpcID == v then
                    nIndex = nCount
                end
            else
                script:OnEnter(v, nCount == 1, true)
            end
        end
    end

    local bIsEmpty = (nCount == 0)
    UIHelper.SetVisible(self.WidgetWisperEmpty, bIsEmpty)
    UIHelper.SetString(self.LabelAddChat, "暂无侠缘对话，点击邀请侠客聊天")

    if bIsEmpty and self.tScrollList then
        self.tScrollList:Reload(0)
    end

    if not bNotDoLayout then
        Timer.AddFrame(self, 1, function ()
            UIHelper.ScrollViewDoLayout(self.ScrollViewWhisper)
            if nCount > 4 then
                UIHelper.ScrollToIndex(self.ScrollViewWhisper, nIndex - 1)
            else
                UIHelper.ScrollToLeft(self.ScrollViewWhisper)
            end
        end)
    end
end

-- 心情值 + 加载更多
function UIChatView:UpdateAINpcMood()
    if self.szCurUIChannel ~= UI_Chat_Channel.AINpc then
        UIHelper.SetVisible(self.WidgetAINpc, false)
        UIHelper.SetVisible(self.ImgAI_Tip, false)
        return
    end

    local bHasNpcSelected = self.dwCurAINpcID ~= nil
    UIHelper.SetVisible(self.WidgetAINpc, bHasNpcSelected)
    UIHelper.SetVisible(self.ImgAI_Tip, bHasNpcSelected) -- AI 水印

    -- 心情值
    local nMood = ChatAINpcMgr.GetNpcMood(self.dwCurAINpcID)
    local bShowMood = ChatAINpcMgr.IsShowMood()
    UIHelper.SetString(self.LabelMood, string.format(g_tStrings.STR_NPC_MOOD, nMood))
    UIHelper.SetVisible(self.WidgetMood, bShowMood)

    -- 加载历史消息
    local bIsFetchDone = ChatAINpcMgr.IsFetchDone(self.dwCurAINpcID)
    local bShowHistory = self.dwCurAINpcID and not bIsFetchDone
    UIHelper.SetVisible(self.BtnMoreAIMsg, bShowHistory)
    UIHelper.BindUIEvent(self.BtnMoreAIMsg, EventType.OnClick, function()
        ChatAINpcMgr.FetchChatRecord(self.dwCurAINpcID)
    end)

    -- self.WidgetThinki
    UIHelper.SetSelected(self.ToggleThink, ChatAINpcMgr.IsDeepThink())
    UIHelper.BindUIEvent(self.ToggleThink, EventType.OnSelectChanged, function(toggle, bSelected)
        ChatAINpcMgr.OpenDeepThink(bSelected)
    end)

    UIHelper.LayoutDoLayout(self.LayoutAINpc)
end

function UIChatView:SendJiangHuWord(tJiangHu)
    local player = GetClientPlayer()
	if not player then
	  return
	end

    local szWhisperName = nil
    local dwTargetType, dwTargetID
    local szName, szText

    if self.szCurUIChannel == UI_Chat_Channel.Whisper then
        if self.szCurWhisper then
            local tbData = ChatData.GetWhisperPlayerData(self.szCurWhisper)
            szWhisperName = UIHelper.UTF8ToGBK(tbData and tbData.szName)
        end
    end
    local nChannelID = ChatData.GetSendChannelID()

    if not szWhisperName then
		szWhisperName = ""
		dwTargetType, dwTargetID = player.GetTarget()
	end

	if szWhisperName ~= "" then
		szName = szWhisperName
		szText = UIHelper.UTF8ToGBK(tJiangHu[3])
        szText = string.gsub(szText, "$n", szName)
    elseif dwTargetType == TARGET.PLAYER then
		local playerT = GetPlayer(dwTargetID)
		if playerT then
			szName = playerT.szName
			szText = UIHelper.UTF8ToGBK(tJiangHu[3])
            szText = string.gsub(szText, "$n", szName)
		end
	elseif dwTargetType == TARGET.NPC then
		local npcT = GetNpc(dwTargetID)
		if npcT then
			szName = npcT.szName
			szText = UIHelper.UTF8ToGBK(tJiangHu[3])
            szText = string.gsub(szText, "$n", szName)
		end
    else
        szText = UIHelper.UTF8ToGBK(tJiangHu[2])
    end

    local tWord = nil

    if ChatData.IsBulletChannel(nChannelID) then
        szText = string.gsub(szText, "$N", "")

        tWord =
        {
            {type = "emotion", id = 0},
            {type = "text", text = szText},
        }
    else
        szText = string.gsub(szText, "$N", player.szName)

        tWord =
        {
            {type = "emotion", id = 0},
            {type = "text", text = szText},
        }
    end

    Player_Talk(player, nChannelID, szWhisperName, tWord)
end

function UIChatView:SendEmotionAction(tEmotionAction)
    local player = GetClientPlayer()
	if not player then
	  return
	end

    local szWhisperName = nil
    local dwTargetType, dwTargetID
    local szName, szText

    if self.szCurUIChannel == UI_Chat_Channel.Whisper then
        if self.szCurWhisper then
            local tbData = ChatData.GetWhisperPlayerData(self.szCurWhisper)
            szWhisperName = UIHelper.UTF8ToGBK(tbData and tbData.szName)
        end
    end
    -- 要求统一发近聊
    local nChannelID = PLAYER_TALK_CHANNEL.NEARBY

    if not szWhisperName then
		szWhisperName = ""
		dwTargetType, dwTargetID = player.GetTarget()
	end

	if szWhisperName ~= "" then
		szName = szWhisperName
		szText = tEmotionAction.szTarget
        szText = string.gsub(szText, "$n", szName)
    elseif dwTargetType == TARGET.PLAYER then
		local playerT = GetPlayer(dwTargetID)
		if playerT then
			szName = playerT.szName
			szText = tEmotionAction.szTarget
            szText = string.gsub(szText, "$n", szName)
		end
	elseif dwTargetType == TARGET.NPC then
		local npcT = GetNpc(dwTargetID)
		if npcT then
			szName = npcT.szName
			szText = tEmotionAction.szTarget
            szText = string.gsub(szText, "$n", szName)
		end
    else
        szText = tEmotionAction.szNoTarget
    end

    szText = string.gsub(szText, "$N", player.szName)

    local tWord =
	{
		{type = "text", text = szText},
    }

    Player_Talk(player, nChannelID, szWhisperName, tWord)
end

function UIChatView:CanShowAllWorldInput()
    local bResult = false
    local hPVP = GetPVPFieldClient()
	if hPVP and g_pClientPlayer then
		local hScene = g_pClientPlayer.GetScene()
		if hScene and hPVP.IsPVPField(hScene.dwMapID, hScene.nCopyIndex) then
			bResult = true
		end
	end
    return bResult
end

function UIChatView:UpdateInfo_Bg()
    UIHelper.WidgetFoceDoAlignAssignNode(self, self.ImgBg)
end

function UIChatView:AppendInput(szContent)
    if string.is_nil(szContent) then
        local szMsg = ChatData.GetChatInputText(self.szCurUIChannel)
        self:SetEditBoxSendString(szMsg)
        return
    end
    local szMsg = UIHelper.GetString(self.EditBoxSend)..szContent
    self:SetEditBoxSendString(szMsg)

    local nChannelID = ChatData.GetSendChannelID()
    ChatData.SetChannelVoiceModel(nChannelID, false)
    self:UpdateVoice()
end


function UIChatView:EnterMobileInputMode()
    if self.bIsShowEmoji then return end

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
            local nContentY = UIHelper.GetPositionY(self.LayoutContent)
            local nContentHeight = nContentY - cursorPosition.y - nWidgetSendHeight

            if not bHasUpdateScrollList then
                self:UpdateScrollList(nContentHeight)
                bHasUpdateScrollList = true
            end
        end
    end)
end

function UIChatView:ExitMobileInputMode()
    if self.bIsShowEmoji then return end

    Timer.DelTimer(self, self.nInputTimerID)

    if self.tbEditorBoxPos then
        UIHelper.SetPosition(self.WidgetSend , self.tbEditorBoxPos.x , self.tbEditorBoxPos.y)
    end

    self.bIsMobileInputMode = false

    --self.EditBoxSend:editBoxEditingDidEnd(UIHelper.GetString(self.EditBoxSend))

    self:UpdateScrollList()
end

function UIChatView:UpdateScrollList(nContentHeight)
    self:InitScrollList(nContentHeight)
    self:UpdateInfo_Content()
    self:UpdateInfo_DoLayout()
end

function UIChatView:UpdateSwitch()
    local bShowSwitch = ChatData.CheckUIChannelCanSwitch(self.szCurUIChannel)
    bShowSwitch = bShowSwitch and UIHelper.GetVisible(self.WidgetSend)
    UIHelper.SetVisible(self.BtnSwitch, bShowSwitch)

    local nChannelID = ChatData.GetSendChannelID()
    local szChannelName = ChatData.GetChannelNameByID(nChannelID)
    UIHelper.SetString(self.LabelSwitch, ChatData.GetChannelNickName(szChannelName))

    local nPercent = UIHelper.GetScrollPercent(self.ScrollViewTab)
    local nHeight = bShowSwitch and UIHelper.GetCurResolutionSize().height - 90 or UIHelper.GetCurResolutionSize().height
    UIHelper.SetHeight(self.ScrollViewTab, nHeight)
    UIHelper.ScrollViewDoLayout(self.ScrollViewTab)
    --UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewTab)

    --Timer.AddFrame(self, 1, function()
        UIHelper.ScrollToPercent(self.ScrollViewTab, nPercent)
    --end)
end

function UIChatView:SelectChannel(szUIChannel, szSendContent)
    local nIndex = self.tbUIChannelToToggleIndex[szUIChannel]
    if nIndex then
        if nIndex <= 9 then
            UIHelper.ScrollToTop(self.ScrollViewTab)
        else
            UIHelper.ScrollToBottom(self.ScrollViewTab)
        end

        UIHelper.SetSelected(self.tbChannelToggle[nIndex], true)

        if not string.is_nil(szSendContent) then
            self:AppendInput(szSendContent)
        end
    end
end

function UIChatView:UpdateSendButton()
    if self.szCurUIChannel == UI_Chat_Channel.AINpc then
        local bChatWaiting = ChatAINpcMgr.IsChatWaiting()
        local bChatFiltering = ChatAINpcMgr.IsChatFiltering()
        if bChatWaiting or bChatFiltering then
            UIHelper.SetButtonState(self.BtnSend, BTN_STATE.Disable, "侠缘消息回复中，请稍候。")
        else
            UIHelper.SetButtonState(self.BtnSend, BTN_STATE.Normal)
        end
        return
    end

    -- 更新发送按钮CD
    local nChannelID = ChatData.GetSendChannelID()
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

function UIChatView:UpdateVoice()
    local nChannelID = ChatData.GetSendChannelID()
    local bVoiceMode = ChatData.IsChannelVoiceModel(nChannelID)
    local bVoiceAble = ChatData.GetChannelVoiceAble(nChannelID)

    local bSendVisible = UIHelper.GetVisible(self.WidgetSend)

    -- 如果不是双向好友，不能发语音
    -- local bIsWhisper = self.szCurUIChannel == UI_Chat_Channel.Whisper
    -- if bIsWhisper then
    --     local tbData = ChatData.GetWhisperPlayerData(self.szCurWhisper)
    --     local szGlobalID = tbData and tbData.szGlobalID or nil
    --     if not FellowshipData.IsTowWayFriend(szGlobalID) then
    --         bVoiceAble = false
    --     end
    -- end

    UIHelper.SetVisible(self.WidgetSendVoice, bVoiceMode and bVoiceAble and bSendVisible)

    UIHelper.SetVisible(self.EditBoxSendNormal, not bVoiceMode and not bVoiceAble)
    UIHelper.SetVisible(self.BtnSend, not bVoiceMode)
    UIHelper.SetVisible(self.BtnEmoji, not bVoiceMode)
    UIHelper.SetVisible(self.BtnMic, not bVoiceMode and bVoiceAble)
    UIHelper.SetVisible(self.EditBoxSendShort, not bVoiceMode and bVoiceAble)

    local bIsAINpcChannel = self.szCurUIChannel == UI_Chat_Channel.AINpc
    local nState = bIsAINpcChannel and BTN_STATE.Disable or BTN_STATE.Normal
    UIHelper.SetButtonState(self.BtnMic, nState, g_tStrings.tAIAgentChatErrorCode[AI_AGENT_CHAT_ERROR_CODE.CLOSE_FLAG], true)

    self.EditBoxSend = bVoiceAble and self.EditBoxSendShort or self.EditBoxSendNormal
end

function UIChatView:StartRecording()
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

function UIChatView:StopRecording()
    if not self.bIsRecording then
        return
    end

    self.bIsRecording = false

    Timer.DelTimer(self, self.nRecordingTimerID)
    UIHelper.SetVisible(self.WidgetVoiceHint, false)

    ChatVoiceMgr.StopRecording()
end

function UIChatView:CancelRecording()
    if not self.bIsRecording then
        return
    end

    self.bIsRecording = false

    Timer.DelTimer(self, self.nRecordingTimerID)
    UIHelper.SetVisible(self.WidgetVoiceHint, false)

    ChatVoiceMgr.CancelRecording()
end

function UIChatView:UpdateRecording(bIsInHold)
    UIHelper.SetVisible(self.WidgetRecord, bIsInHold)
    UIHelper.SetVisible(self.WidgetRecordCancel, not bIsInHold)

    local szHint = bIsInHold and "松开手指 发送语音" or "松开手指 取消"
    UIHelper.SetString(self.LabelRecordHint, szHint)

    local tbColor = bIsInHold and COLOR.RECORD_NORMAL or COLOR.RECORD_CANCEL
    UIHelper.SetColor(self.LabelRecordHint, tbColor)
end

function UIChatView:SetEditBoxSendString(szContent)
    UIHelper.SetString(self.EditBoxSendShort, szContent)
    UIHelper.SetString(self.EditBoxSendNormal, szContent)

    ChatData.SetChatInputText(self.szCurUIChannel, szContent)
end

function UIChatView:GetCurUIChannel()
    return self.szCurUIChannel
end

function UIChatView:EnterInputMode()
    if Platform.IsMobile() then return end
    if not self.EditBoxSend then return end

    -- 如果有弹窗界面，则不进入输入模式
    local nPopLen = UIMgr.GetLayerStackLength(UILayer.Popup, IGNORE_TEACH_VIEW_IDS)
    local nSysPopLen = UIMgr.GetLayerStackLength(UILayer.SystemPop, table.AddRange({ VIEW_ID.PanelDownloadBall }, IGNORE_TEACH_VIEW_IDS))
    local nMsgLen = UIMgr.GetLayerStackLength(UILayer.MessageBox, IGNORE_TEACH_VIEW_IDS)
    local nLen = nPopLen + nMsgLen + nSysPopLen
    if nLen > 0 then return end

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

-- 迷你面板的同步状态
function UIChatView:UpdateInfo_MiniChatSyncState()
    ChatHelper.Update_MiniChatSyncState(self.BtnLockTab, self.imgLockTab, self.imgLockTab1, not self.bSysBtnBinded)
    self.bSysBtnBinded = true
end

function UIChatView:RegKeyBoardEvent()
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

function UIChatView:ChangeChannelWhenOpen(szUIChannel)
    if szUIChannel == UI_Chat_Channel.Team then
        if TeamData.IsInRaid() then
            ChatData.SetSendChannelID(szUIChannel, PLAYER_TALK_CHANNEL.RAID)
        elseif TeamData.IsInParty() then
            ChatData.SetSendChannelID(szUIChannel, PLAYER_TALK_CHANNEL.TEAM)
        end
    elseif szUIChannel == UI_Chat_Channel.Tong then
        if TongData.HavePlayerJoinedTong() then
            ChatData.SetSendChannelID(szUIChannel, PLAYER_TALK_CHANNEL.TONG)
        end
    end
end

function UIChatView:ParseChatInfo(tbData)
    local tbInfo = tbData.tbInfo
    local tbContentInfo = tbData.tbContentInfo
    local nPrefabID = ChatRecentMgr.GetPrefabID(tbContentInfo.szSenderGlobalID, tbInfo)
    local bIsSelf = tbContentInfo.szSenderGlobalID == UI_GetClientPlayerGlobalID()

    local tbPlayerInfo = {}
    local tbPlayerList = ChatRecentMgr.GetRecentWhisperPlayerList()
    --local tbPlayerList = ChatRecentMgr.GetWhisperPlayerList()
    for i, v in ipairs(tbPlayerList) do
        if v.szGlobalID == self.szGlobalID then
            tbPlayerInfo = v
            break
        end
    end
    local szName = UIHelper.GBKToUTF8(tbPlayerInfo.szName)
    local nRoleType = tbPlayerInfo.byRoleType
    local byCamp = tbPlayerInfo.byCamp
    local dwMiniAvatarID = tbPlayerInfo.dwMiniAvatarID
    local byLevel = tbPlayerInfo.byLevel
    local byForceID = tbPlayerInfo.byForceID
    local dwCenterID = tbPlayerInfo.dwCenterID

    if FellowshipData.IsFriend(self.szGlobalID) then
        local tbWhisperPlayerInfo = FellowshipData.GetRoleEntryInfo(self.szGlobalID)
        if tbWhisperPlayerInfo then
            if tbWhisperPlayerInfo.szName == "" then
                szName = g_tStrings.MENTOR_DELETE_ROLE
                byCamp = 0
                dwMiniAvatarID = 0
                nRoleType = 0
                byForceID = 0
                dwCenterID = 0
                byLevel = 0
            else
                szName = UIHelper.GBKToUTF8(tbWhisperPlayerInfo.szName)
                nRoleType = tbWhisperPlayerInfo.nRoleType
                byCamp = tbWhisperPlayerInfo.nCamp
                dwMiniAvatarID = tbWhisperPlayerInfo.dwMiniAvatarID
                byLevel = tbWhisperPlayerInfo.nLevel
                byForceID = tbWhisperPlayerInfo.nForceID
                dwCenterID = tbWhisperPlayerInfo.dwCenterID
            end

        end
    end

    local szContent = ""
    for k, v in ipairs(tbInfo) do
        --处理格式化文本
        if v.type == "emotion" then
            if v.id ~= -1 then
                local szEmoji = string.format("<img emojiid='%d' src='' width='30' height='30'/>", v.id)
                szContent = szContent .. szEmoji
            end
        --elseif v.type == "text" then
        --    szContent = UIHelper.GBKToUTF8(v.text)
        else
            local bResult, szResult = ChatHelper.DecodeTalkData(v, nil, PLAYER_TALK_CHANNEL.WHISPER)
            szContent = szContent .. szResult
            --szContent = GBKToUTF8(szContent)
        end
    end

    szContent = GBKToUTF8(szContent)

    if string.is_nil(szContent) then
        if tbInfo[1] and tbInfo[1].type == "voice" then -- 如果是语音消息 就特殊处理下
            szContent = " "
        else
            szContent = " "
            LOG.TABLE(tbInfo)
        end
    end

    local tbResult =
    {
        nTime = tbContentInfo.nTalkTime, dwTitleID = tbContentInfo.dwTitleID, szGlobalID = tbContentInfo.szSenderGlobalID,
        nChannel = PLAYER_TALK_CHANNEL.WHISPER, tbMsg = tbInfo, nCamp = byCamp,
        nRoleType = nRoleType, nLevel = byLevel,
        dwMiniAvatarID = dwMiniAvatarID,
        dwForceID = byForceID, nPrefabID = nPrefabID, dwCenterID = dwCenterID,
        szName = szName, szContent = szContent
    }

    return tbResult
end

function UIChatView:CalcScrollPosX()
	local nWorldX, nWorldY = UIHelper.ConvertToWorldSpace(self.ScrollViewWhisper, 0, 0)
	self.nScrollViewX = nWorldX
end

function UIChatView:HasRedPoint()
    local bHasRedPointLeft = false
    local bHasRedPointRight = false

	self:CalcScrollPosX()

    local tbChildren = UIHelper.GetChildren(self.ScrollViewWhisper)
    if tbChildren and not table.is_empty(tbChildren) then
        for k, v in ipairs(tbChildren) do
            local tbScript = UIHelper.GetBindScript(v)
            if UIHelper.GetVisible(tbScript.imgRedPoint) then
                local nWidth = UIHelper.GetWidth(tbScript.imgRedPoint)
                local _nWorldX, _nWorldY = UIHelper.ConvertToWorldSpace(tbScript.imgRedPoint, nWidth, 0)
                if _nWorldX < self.nScrollViewX + 1 then
                    bHasRedPointLeft = true
                end
                if _nWorldX > self.nScrollViewX + UIHelper.GetWidth(self.ScrollViewWhisper) then
                    bHasRedPointRight = true
                end
            end
        end
    end

    return bHasRedPointLeft, bHasRedPointRight
end

function UIChatView:UpdateRedPointArrow()
    if self.szCurUIChannel ~= UI_Chat_Channel.Whisper then return end
	local bHasRedPointLeft, bHasRedPointRight = self:HasRedPoint()
    if bHasRedPointLeft and bHasRedPointRight then
        bHasRedPointRight = false
    end
	UIHelper.SetActiveAndCache(self, self.ImgRedPointArrowLeft, bHasRedPointLeft)
    UIHelper.SetActiveAndCache(self, self.ImgRedPointArrowRight, bHasRedPointRight)
end

-- 密聊 加载更多历史聊天记录按钮
function UIChatView:UpdateInfo_WhisperHistory()
    if self.szCurUIChannel ~= UI_Chat_Channel.Whisper then
        UIHelper.SetVisible(self.BtnShowHistory, false)
        return
    end

    local bWhisperLocked = ChatRecentMgr.Check_WhisperIsLocked()
    UIHelper.SetVisible(self.BtnShowHistory, bWhisperLocked)

    UIHelper.BindUIEvent(self.BtnShowHistory, EventType.OnClick, function()
        ChatRecentMgr.Check_WhisperIsLocked(true, function()
            if ChatRecentMgr.GetRecentLockState() then
                return
            end
            self:InitScrollList()
            self:UpdateWhisperList()
            self:UpdateInfo_WhisperHistory()
            -- self:InitScrollList()
            self:UpdateInfo_Content()

            Timer.DelTimer(self, self.nDoLayoutTimerID)
            self.nDoLayoutTimerID = Timer.AddFrame(self, 1, function()
                self:UpdateInfo_DoLayout()
            end)
        end)
    end)
end

return UIChatView
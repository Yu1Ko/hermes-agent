-- ---------------------------------------------------------------------------------
-- Author: huqing
-- Name: UIChatMini
-- Date: 2022-12-12 17:44:48
-- Desc: 主界面mini聊天面板
-- ---------------------------------------------------------------------------------

local UIChatMini = class("UIChatMini")
local tbPrefabList = {
    [1] = PREFAB_ID.WidgetChatMainCityCell2,
    [2] = PREFAB_ID.WidgetChatMainCityCell,
}

function UIChatMini:OnEnter(nMode)
    self.nMode = nMode or Storage.ControlMode.nMode
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.szCurUIChannel = ChatData.GetMiniDisplayChannel()

    self:SetToBottom(true)
    self:InitScrollList()
    self:UpdateInfo()
    --if self.nMode == MAIN_CITY_CONTROL_MODE.SIMPLE then
    --    self:UpdateNodeScale()
    --end

    if Platform.IsMobile() then
        --UIHelper.SetSwallowTouches(self.BtnChangeMini, false)
        --UIHelper.SetSwallowTouches(self.BtnOpenSocial, false)
        --UIHelper.SetSwallowTouches(self.BtnChannelOpen, false)
        UIHelper.SetSwallowTouches(self.BtnContent, false)
        UIHelper.SetSwallowTouches(self.LayoutContent, false)

        UIHelper.SetEnable(self.LayoutContent, false)
    end

    self:SaveDefaultChatBgOpacity()
end

function UIChatMini:OnExit()
    self.bInit = false
    self:UnRegEvent()
    self:UnInitScrollList()
end

function UIChatMini:InitScrollList()
    self:UnInitScrollList()

    self.LayoutContent:setClippingEnabled(true, true) -- 聊天的Layout清除所有模版

	self.tScrollList = UIScrollList.Create({
		listNode = self.LayoutContent,
        nReboundScale = 1,
		fnGetCellType = function(nIndex)
            --return PREFAB_ID.WidgetChatMainCityCell
            --if not self.nMode then
            --    self.nMode = Storage.ControlMode.nMode
            --end
            return tbPrefabList[self.nMode]
        end,
		fnUpdateCell = function(cell, nIndex)
			self:UpdateOneCell(cell, nIndex)
		end,
	})

    local w, h = UIHelper.GetContentSize(self.LayoutContent)
    UIHelper.SetContentSize(self.BtnContent, w, h)

    local x, y = UIHelper.GetPosition(self.LayoutContent)
    UIHelper.SetPosition(self.BtnContent, x, y)
end

function UIChatMini:UnInitScrollList()
	if self.tScrollList then
		self.tScrollList:Destroy()
		self.tScrollList = nil
	end
end

function UIChatMini:UpdateOneCell(cell, nIndex)
    if not cell then return end
    cell._keepmt = true

    local tbData = ChatData.GetOneData(self.szCurUIChannel, nIndex, self.szCurWhisper)
    if tbData and tbData.nPrefabID == PREFAB_ID.WidgetChatTime then
        UIHelper.SetHeight(cell._rootNode, 0)
        UIHelper.SetOpacity(cell._rootNode, 0)
        return
    end

    local nOffset = 0-- (self.nMode == MAIN_CITY_CONTROL_MODE.CLASSIC) and - 30 or 0
    cell:SetWidth(UIHelper.GetWidth(self.LayoutContent) + nOffset)
    cell:OnEnter(nIndex, tbData, self.nMode)
    UIHelper.SetOpacity(cell._rootNode, 255)
end

function UIChatMini:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnOpenChat, EventType.OnClick, function()
        ChatHelper.Chat(self.szCurUIChannel)
    end)

    UIHelper.BindUIEvent(self.BtnChangeMini, EventType.OnClick, function()
        self:ShowContent(false)
    end)

    UIHelper.BindUIEvent(self.BtnChangeNormall, EventType.OnClick, function()
        self:ShowContent(true)
    end)

    UIHelper.BindUIEvent(self.BtnChannelOpen, EventType.OnClick, function()
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetChatSwitchTip, self.BtnChannelOpen, TipsLayoutDir.TOP_CENTER, UI_Chat_Switch_Type.Mini)
    end)

    if Platform.IsWindows() or Platform.IsMac() then
        UIHelper.BindUIEvent(self.BtnContent, EventType.OnClick, function()
            ChatHelper.Chat()
        end)
    else
        UIHelper.BindUIEvent(self.BtnContent, EventType.OnTouchBegan, function(btn, nX, nY)
            self.nTouchBeganX, self.nTouchBeganY = nX, nY
            self.nTouchBeganTime = Timer.RealMStimeSinceStartup()

            Timer.DelTimer(self, self.nCTTSPVTimerID)
            UIMutexMgr.SetCanCloseTopSidePageView(false)

            if Platform.IsMobile() then ChatHelper.SetCanToggleSitDown(false) end
        end)

        UIHelper.BindUIEvent(self.BtnContent, EventType.OnTouchMoved, function(btn, nX, nY)
            if Platform.IsMobile() then
                ChatHelper.SetCanToggleSitDown(true)

                local nDeltaX, nDeltaY = nX - self.nTouchBeganX, nY - self.nTouchBeganY
                if nDeltaX > 0 or nDeltaY > 0 then
                    local player = GetClientPlayer()
                    if player and player.nMoveState == MOVE_STATE.ON_SIT then
                        ToggleSitDown()
                    end
                end
            end
        end)

        UIHelper.BindUIEvent(self.BtnContent, EventType.OnTouchEnded, function(btn, nX, nY)
            if Platform.IsMobile() then ChatHelper.SetCanToggleSitDown(true) end

            Timer.DelTimer(self, self.nCTTSPVTimerID)
            self.nCTTSPVTimerID = Timer.AddFrame(self, 1, function()
                UIMutexMgr.SetCanCloseTopSidePageView(true)
            end)

            local nDeltaX, nDeltaY = nX - self.nTouchBeganX, nY - self.nTouchBeganY
            --LOG.INFO("QH, nDeltaX = "..tostring(nDeltaX))
            --LOG.INFO("QH, nDeltaY = "..tostring(nDeltaY))
            if nDeltaX > 0 or nDeltaY > 0 then return end
            if Timer.RealMStimeSinceStartup() - self.nTouchBeganTime > 150 then return end

            ChatHelper.Chat()
        end)

        UIHelper.BindUIEvent(self.BtnContent, EventType.OnTouchCanceled, function()
            if Platform.IsMobile() then ChatHelper.SetCanToggleSitDown(true) end

            Timer.DelTimer(self, self.nCTTSPVTimerID)
            UIMutexMgr.SetCanCloseTopSidePageView(true)
        end)
    end

    UIHelper.BindUIEvent(self.BtnOpenSocial, EventType.OnClick, function()
        local bHasChatEmojiRedPoint = RedpointHelper.ChatEmotion_HasRedPoint()
        local nIndex = bHasChatEmojiRedPoint and 1 or 2
        UIMgr.Open(VIEW_ID.PanelChatSocial, nIndex)
    end)

    UIHelper.BindUIEvent(self.BtnSelectZoneLight, EventType.OnClick, function()  --进入黑框,maincity加载新的
        Event.Dispatch("ON_ENTER_SINGLENODE_CUSTOM", CUSTOM_RANGE.CHAT, CUSTOM_TYPE.CHAT, self.nCustomMode)
    end)

    UIHelper.BindUIEvent(self.BtnInfoHintNum, EventType.OnClick, function()
        local tbData = ChatHintMgr.GetTopData()
        local nChannel = tbData and tbData.nChannel
        if nChannel then
            local szUIChannel = ChatHintMgr.GetUIChannel(nChannel)
            if szUIChannel == UI_Chat_Channel.Whisper then
                ChatRecentMgr.SetCurWhisperPlayerName(tbData.szName)
                UIMgr.Open(VIEW_ID.PanelChatSocial, 1, szUIChannel)
            else
                UIMgr.Open(VIEW_ID.PanelChatSocial, 1, szUIChannel)
            end
        end
        local nOffLineLen = ChatRecentMgr.GetTotalOffLineMsgCount() --离线消息
        if nOffLineLen > 0 then
            UIMgr.Open(VIEW_ID.PanelChatSocial, 1, UI_Chat_Channel.Whisper)
        end
    end)

    UIHelper.BindUIEvent(self.BtnJumpNew, EventType.OnClick,function()
        self:SetToBottom(true)
        self:UpdateInfo_Content()
    end)
end

function UIChatMini:RegEvent()
    Event.Reg(self, EventType.OnReceiveChat, function(tbData)
        self:OnReceive(tbData)
    end)

    Event.Reg(self, "EmotionActionOpenChat", function(tEmotionData)
        self:OpenChatForEmotionAction(tEmotionData)
    end)

    Event.Reg(self, EventType.OnViewOpen, function(nViewID)
        if nViewID == VIEW_ID.PanelChatSocial or nViewID == VIEW_ID.PanelChatSocialWhisper then
            UIHelper.SetVisible(UIHelper.GetParent(self._rootNode), false)

            Event.UnReg(self, EventType.OnReceiveChat)
        end
    end)

    Event.Reg(self, EventType.OnViewClose, function(nViewID)
        if nViewID == VIEW_ID.PanelChatSocial then
            UIHelper.SetVisible(UIHelper.GetParent(self._rootNode), true)

            self.szCurUIChannel = ChatData.GetMiniDisplayChannel()
            self:SetToBottom(true)
            self:UpdateInfo_Content()

            Event.Reg(self, EventType.OnReceiveChat, function(tbData)
                self:OnReceive(tbData)
            end)
        end
    end)

    Event.Reg(self, EventType.OnChatMiniChannelSelected, function(szUIChannel)
        self:SetToBottom(true)

        self.szCurUIChannel = szUIChannel
        self:UpdateInfo_Content()
    end)

    Event.Reg(self, EventType.OnChatSyncMiniChat, function(bSync)
        if not bSync then return end

        self.szCurUIChannel = ChatData.GetMiniDisplayChannel()
        if UIHelper.GetVisible(UIHelper.GetParent(self._rootNode)) then
            self:UpdateInfo_Content()
        end
    end)

    Event.Reg(self, EventType.OnChatWhisperSelected, function(szCurWhisper)
        self.szCurWhisper = szCurWhisper
    end)

    Event.Reg(self, EventType.OnChatAINpcSelected, function(dwID)
        self.szCurAINpcID = dwID
    end)

    Event.Reg(self, EventType.OnChatHintMsgUpdate, function()
        self:UpdateInfo_HintMsg()
    end)

    Event.Reg(self, EventType.OnUIScrollListTouchMove, function()
        if Platform.IsMobile() then return end
        if not self.tScrollList then return end
        if not self.tScrollList:_IsCanDrag() then return end
        local nPercentage = self.tScrollList:GetPercentage()
        if nPercentage < 1 then
            self:SetToBottom(false)
        else
            self:SetToBottom(true)
        end
    end)

    Event.Reg(self, EventType.OnUIScrollListMouseWhell, function()
        if Platform.IsMobile() then return end
        if not self.tScrollList then return end
        if not self.tScrollList:_IsCanDrag() then return end
        local nPercentage = self.tScrollList:GetPercentage()
        if nPercentage < 1 then
            self:SetToBottom(false)
        else
            self:SetToBottom(true)
        end
    end)

    Event.Reg(self, EventType.OnWindowsSizeChanged, function(width, height)
        self:SetToBottom(true)

        local bNowWindowsIsMinimized = (width == 0 and height == 0)
        if self.bWindowsIsMinimized and not bNowWindowsIsMinimized then
            self:UpdateInfo_Content()
        end

        self.bWindowsIsMinimized = bNowWindowsIsMinimized
    end)

    --Event.Reg(self, "ON_CHANGE_FONT_SIZE", function (tbSizeType)
    --    if self.nMode == MAIN_CITY_CONTROL_MODE.SIMPLE then
    --        UIHelper.SetScale(self._rootNode, tbSizeType["nChat"], tbSizeType["nChat"])
    --    end
    --end)


    Event.Reg(self, EventType.OnSetChatBgOpacity, function(nOpacity)
        UIHelper.SetOpacity(self.ImgBg, nOpacity)
    end)
end

function UIChatMini:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIChatMini:OnReceive(tbData)
    if self.bWindowsIsMinimized then return end

    if not tbData then return end
    if not tbData.tbUIChannelMap then return end
    if not tbData.tbUIChannelMap[self.szCurUIChannel] then
        if not tbData.bBeCalled then
            return
        end
    end

    local bIsToBottom = self:IsToBottom()

    local nDataLen = ChatData.GetDataListLen(self.szCurUIChannel, self:GetWhisper())
    local min, max = self.tScrollList:GetIndexRangeOfLoadedCells()
    local nMaxCount = ChatData.GetUIChannelMaxCount(self.szCurUIChannel)

    if nDataLen >= nMaxCount and not bIsToBottom then
        --self.tScrollList:ReloadWithStartIndex(nDataLen, self.nRangeMin)
    else
        self.tScrollList:ReloadWithStartIndex(nDataLen, min) --刷新数量
    end

    --LOG.INFO("QH, min = %d, max = %d, nDataLen = %d", min, max, nDataLen)

    if bIsToBottom then
        self.tScrollList:ScrollToIndex(nDataLen)
    end
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIChatMini:UpdateInfo()
    self:UpdateInfo_Content()
end

function UIChatMini:UpdateInfo_Content()
    local nDataLen = ChatData.GetDataListLen(self.szCurUIChannel, self:GetWhisper())
    if nDataLen == 0 then
        self.tScrollList:Reset(nDataLen) --完全重置，包括速度、位置
    else
        self.tScrollList:ResetWithStartIndex(nDataLen, nDataLen)
    end
end

function UIChatMini:ShowContent(bFlag)
    UIHelper.SetVisible(self.WidgetContentChat, bFlag)
    UIHelper.SetVisible(self.BtnChangeNormall, not bFlag)
end

function UIChatMini:OpenChatForEmotionAction(tEmotionData)
    ChatHelper.Chat(self.szCurUIChannel)
    Event.Dispatch("SendEmotionAction", tEmotionData)
end

function UIChatMini:UpdateNodeScale()
    local nDevice = DEVICE_TYPE.PC
    if Platform.IsIPad() then
        nDevice = DEVICE_TYPE.PAD
    elseif Platform.IsMobile() then
        nDevice = DEVICE_TYPE.PHONE
    elseif Platform.IsWindows() or Platform.IsMac() then
        nDevice = DEVICE_TYPE.PC
        if Channel.Is_WLColud() then
            nDevice = DEVICE_TYPE.PHONE
        end
    end

    local nScale = Storage.ControlMode.tbNodeSizeType.nChat
	if nScale == 0 then
		nScale = clone(UIFontSizeTab[nDevice].nDefaultSize)
		Storage.ControlMode.Dirty()
	end
	UIHelper.SetScale(self._rootNode, nScale, nScale)
end

function UIChatMini:UpdatePrepareState(nMode, bStart)
    self:UpdateCustomNodeState(bStart and CUSTOM_BTNSTATE.ENTER or CUSTOM_BTNSTATE.COMMON)
	self.nCustomMode = nMode
end

function UIChatMini:UpdateCustomState()
    self:UpdateCustomNodeState(CUSTOM_BTNSTATE.EDIT)
end

function UIChatMini:UpdateCustomNodeState(nState)
    local szFrame = nState == CUSTOM_BTNSTATE.CONFLICT and "UIAtlas2_MainCity_MainCity1_maincitykuang3" or "UIAtlas2_MainCity_MainCity1_maincitykuang4"
    UIHelper.SetSpriteFrame(self.ImgSelectZone, szFrame)
    UIHelper.SetVisible(self.ImgSelectZone, nState == CUSTOM_BTNSTATE.CONFLICT or nState == CUSTOM_BTNSTATE.EDIT)
    UIHelper.SetVisible(self.BtnSelectZoneLight, nState == CUSTOM_BTNSTATE.ENTER or nState == CUSTOM_BTNSTATE.CONFLICT or nState == CUSTOM_BTNSTATE.OTHER)
    UIHelper.SetVisible(self.ImgSelectZoneLight, nState == CUSTOM_BTNSTATE.ENTER)
    self.nState = nState

    self.tScrollList:Reset(0)
    Event.UnReg(self, EventType.OnReceiveChat)
end

function UIChatMini:GetWhisper()
    if self.szCurUIChannel ~= UI_Chat_Channel.Whisper then
        return ""
    end

    local tbPlayerIDList = ChatData.GetWhisperPlayerIDList() or {}
    local nLen = #tbPlayerIDList

    if not string.is_nil(self.szCurWhisper) and nLen > 0 then -- and table.contain_value(tbPlayerIDList, self.szCurWhisper) then
        return self.szCurWhisper
    end

    self.szCurWhisper = tbPlayerIDList[1]
    return self.szCurWhisper
end

function UIChatMini:UpdateInfo_HintMsg()
    -- 红点提醒
    local nTotalLen = ChatHintMgr.GetTotalLen()
    local nOffLineLen = ChatRecentMgr.GetTotalOffLineMsgCount()
    UIHelper.SetVisible(self.BtnInfoHintNum, nTotalLen + nOffLineLen > 0)
    UIHelper.SetString(self.LabelInfoHintNum, (nTotalLen + nOffLineLen > 99) and 99 or nTotalLen + nOffLineLen)
    UIHelper.SetVisible(self.imgRedpointPlus, nTotalLen + nOffLineLen > 99)

    local nTopCount = ChatData.GetHintCountIsTow() and 2 or 1
    local tbDataList = ChatHintMgr.GetTopDataList(nTopCount)
    local nLen = #tbDataList
    if nLen <= 0 then
        UIHelper.SetVisible(self.LayoutInfoHint, false)
        return
    end

    UIHelper.SetVisible(self.LayoutInfoHint, true)

    if not self.scriptHintList then
        self.scriptHintList = {}
    end

    for _, script in pairs(self.scriptHintList) do
        UIHelper.SetVisible(script._rootNode, false)
    end

    local nLayoutWidth = UIHelper.GetWidth(self.LayoutInfoHint)

    for k, v in ipairs(tbDataList) do
        self.scriptHintList[k] = self.scriptHintList[k] or UIHelper.AddPrefab(PREFAB_ID.WidgetChatInfoHintCell, self.LayoutInfoHint)
        self.scriptHintList[k]:OnEnter(v, 0)--UIHelper.GetWidth(self.LayoutContent))

        local root = self.scriptHintList[k]._rootNode
        UIHelper.SetVisible(root, true)
        UIHelper.SetPositionX(root, 0)
        UIHelper.SetWidth(root, nLayoutWidth)
        UIHelper.WidgetFoceDoAlign(self.scriptHintList[k])
    end

    UIHelper.LayoutDoLayout(self.LayoutInfoHint)
end


function UIChatMini:SetToBottom(bValue)
    if Platform.IsMobile() then
        self.bIsToBottom = true
        UIHelper.SetVisible(self.BtnJumpNew, false)
        return
    end

    self.bIsToBottom = bValue
    UIHelper.SetVisible(self.BtnJumpNew, not bValue)

    if not bValue then
        UIHelper.WidgetFoceDoAlignAssignNode(self, self.BtnJumpNew)
    end
end

function UIChatMini:IsToBottom()
    return self.bIsToBottom
end

function UIChatMini:SaveDefaultChatBgOpacity()
    if not Storage.ControlMode.tbChatBgDefaultOpacity[self.nMode] then
        local nOpacity = UIHelper.GetOpacity(self.ImgBg)
        Storage.ControlMode.tbChatBgDefaultOpacity[self.nMode] = nOpacity
        Storage.ControlMode.Dirty()
    end
end

function UIChatMini:SetChatBgOpacity()
    local nMode = self.nMode or Storage.ControlMode.nMode
    local nOpacity = Storage.ControlMode.tbChatBgOpacity[nMode] or Storage.ControlMode.tbChatBgDefaultOpacity[nMode] or 75
    if nOpacity then
        UIHelper.SetOpacity(self.ImgBg, nOpacity)
    end
end


return UIChatMini
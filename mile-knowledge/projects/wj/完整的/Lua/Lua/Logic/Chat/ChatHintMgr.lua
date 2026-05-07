-- ---------------------------------------------------------------------------------
-- Author: huqing
-- Name: ChatHintMgr
-- Date: 2024-06-21 19:50:39
-- Desc: 聊天迷你面板上消息提醒管理
-- ---------------------------------------------------------------------------------

ChatHintMgr = ChatHintMgr or {className = "ChatHintMgr"}
local self = ChatHintMgr


local HINT_CHANNEL_TO_UICHANNEL = {
    [PLAYER_TALK_CHANNEL.TEAM]          = UI_Chat_Channel.Team,
    [PLAYER_TALK_CHANNEL.RAID]          = UI_Chat_Channel.Team,
    [PLAYER_TALK_CHANNEL.WHISPER]       = UI_Chat_Channel.Whisper,
    [PLAYER_TALK_CHANNEL.TONG]          = UI_Chat_Channel.Tong,
    [PLAYER_TALK_CHANNEL.TONG_ALLIANCE] = UI_Chat_Channel.Tong,
    [PLAYER_TALK_CHANNEL.ROOM]          = UI_Chat_Channel.Team,
}

local MSG_SHOW_TIME = 30 -- 消息展示时间 单位：秒
local MSG_POPED_TIME = 10 -- 被顶以后展示时间 单位：秒

self.tbDataList = {}
self.tbUIChannelCountMap = {}

function ChatHintMgr.Init()
    Event.Reg(self, EventType.OnViewOpen, function(nViewID)
        if nViewID == VIEW_ID.PanelChatSocial then
            self.bSocialIsOpen = true
        end
    end)

    Event.Reg(self, EventType.OnViewClose, function(nViewID)
        if nViewID == VIEW_ID.PanelChatSocial then
            self.bSocialIsOpen = false
            self.szChatViewSelectedUIChannel = nil
        end
    end)

    Event.Reg(self, EventType.OnChatViewChannelChanged, function(szUIChannel)
        self.szChatViewSelectedUIChannel = szUIChannel
        if szUIChannel ~= UI_Chat_Channel.Whisper then
            ChatHintMgr.RemoveDataByUIChannel(szUIChannel)
        end
    end)

    Event.Reg(self, EventType.OnChatWhisperSelected, function(szWhisper)
        ChatHintMgr.RemoveDataByUIChannel(UI_Chat_Channel.Whisper, szWhisper)
    end)

    Event.Reg(self, EventType.OnAccountLogout, function()
        self.Clear()
    end)

    Event.Reg(self, "LOADING_END", function()
        --self.Clear()
    end)

    Event.Reg(self, EventType.OnReceiveChat, function(tbData)
        if not tbData then
            return
        end

        local nPrefabID = tbData.nPrefabID
        if nPrefabID == PREFAB_ID.WidgetChatTime then
            return
        end

        local nChannel = tbData.nChannel
        local tbChannelMap = ChatData.GetHintReciveChannelMap() or {}
        if not tbChannelMap[nChannel] then
            return
        end

        local szMiniDisplatyUIChannel = ChatData.GetMiniDisplayChannel()
        local szUIChannel = HINT_CHANNEL_TO_UICHANNEL[nChannel]
        if szUIChannel == szMiniDisplatyUIChannel then
            return
        end

        -- 大的聊天面板也打开了
        if self.bSocialIsOpen and szUIChannel == self.szChatViewSelectedUIChannel then
            return
        end

        local dwTalkerID = tbData.dwTalkerID
        local szGlobalID = tbData.szGlobalID
        local bIsSelf = (dwTalkerID == UI_GetClientPlayerID())
        if not string.is_nil(szGlobalID) then
            bIsSelf = szGlobalID == UI_GetClientPlayerGlobalID()
        end
        if bIsSelf then
            return
        end

        if string.is_nil(tbData.szName) then
            return
        end

        local nOpenDisturbTime = ChatData.CheckWhisperIsOpenDisturb()
        local bFriend = FellowshipData.IsFriend(szGlobalID)
        if nOpenDisturbTime and not bFriend then   --开启免打扰下的默陌生人消息
            return
        end

        --帮会频道或同盟频道的消息在取消帮会分页的情况下不弹提示
        if (nChannel == PLAYER_TALK_CHANNEL.TONG or nChannel == PLAYER_TALK_CHANNEL.TONG_ALLIANCE) and not ChatData.IsUIChannelVisible(UI_Chat_Channel.Tong) then
            return
        end

        -- 新消息顶掉旧消息
        --table.remove(self.tbDataList, 1)

        -- 新消息来了，就把之前的消息时间都打个标记
        for k, v in ipairs(self.tbDataList) do
            v.bHasBePopedByNewHintMsg = true
        end

        local nLen = #self.tbDataList
        tbData.nHintIndex = nLen + 1
        table.insert(self.tbDataList, tbData)

        self.AddUIChannelCount(nChannel, 1)

        self.StartTimer()

        Event.Dispatch(EventType.OnChatHintMsgUpdate)
    end)
end

function ChatHintMgr.UnInit()

end

function ChatHintMgr.GetTopData()
    return self.tbDataList[1]
end

function ChatHintMgr.GetTopDataList(nTopCount)
    local tbResult = {}
    local nNow = GetCurrentTime()

    if nTopCount then
        for k, v in ipairs(self.tbDataList) do
            local nHintDisplayTime = v.nHintDisplayTime
            local bHasBePopedByNewHintMsg = v.bHasBePopedByNewHintMsg
            local nDisplayMaxTime = bHasBePopedByNewHintMsg and MSG_POPED_TIME or MSG_SHOW_TIME
            if nHintDisplayTime == nil or (nNow - nHintDisplayTime < nDisplayMaxTime) then
                local nLen = #tbResult
                if nLen < nTopCount then
                    table.insert(tbResult, v)
                end
            end
        end
    end

    return tbResult
end

function ChatHintMgr.GetTotalLen()
    return #self.tbDataList
end

function ChatHintMgr.GetCountByUIChannel(szUIChannel)
    return self.tbUIChannelCountMap[szUIChannel] or 0
end

function ChatHintMgr.Clear()
    self.tbDataList = {}
    self.tbUIChannelCountMap = {}
    self.StopTimer()
    Event.Dispatch(EventType.OnChatHintMsgUpdate)
end

function ChatHintMgr.RemoveDataByIndex(nHintIndex)
    local tbData = nil
    for k, v in ipairs(self.tbDataList) do
        if v.nHintIndex == nHintIndex then
            tbData = table.remove(self.tbDataList, k)
            break
        end
    end

    if tbData then
        local nChannel = tbData.nChannel or 0
        self.AddUIChannelCount(nChannel, -1)

        Event.Dispatch(EventType.OnChatHintMsgUpdate)
    end
end

-- 根据UI频道删除
function ChatHintMgr.RemoveDataByUIChannel(szUIChannel, szWhisper)
    local tbNewTable = {}
    local bHasChanged = false

    self.ClearUIChannelCount()

    for k, tbData in ipairs(self.tbDataList) do
        local nChannel = tbData.nChannel
        local _szUIChannel = HINT_CHANNEL_TO_UICHANNEL[nChannel]
        local bIsWhisper = szUIChannel == UI_Chat_Channel.Whisper

        local bKeepFlag = false
        if bIsWhisper then
            if _szUIChannel == UI_Chat_Channel.Whisper then
                bKeepFlag = tbData.szName ~= szWhisper
            else
                bKeepFlag = _szUIChannel ~= szUIChannel
            end
        else
            bKeepFlag = _szUIChannel ~= szUIChannel
        end

        if bKeepFlag then
            table.insert(tbNewTable, tbData)
            self.AddUIChannelCount(nChannel, 1)
        else
            bHasChanged = true
        end
    end

    if bHasChanged then
        self.tbDataList = tbNewTable
        Event.Dispatch(EventType.OnChatHintMsgUpdate)
    end
end

function ChatHintMgr.GetUIChannel(nChannel)
    return HINT_CHANNEL_TO_UICHANNEL[nChannel]
end

-- 删除到时间的
-- function ChatHintMgr.RemoveDataByTimeup()
--     local tbNewTable = {}
--     local nNow = GetCurrentTime()
--     local bHasChanged = false

--     self.ClearUIChannelCount()

--     for k, tbData in ipairs(self.tbDataList) do
--         local nHintDisplayTime = tbData.nHintDisplayTime
--         if nHintDisplayTime == nil or (nNow - nHintDisplayTime < MSG_SHOW_TIME) then
--             table.insert(tbNewTable, tbData)
--             self.AddUIChannelCount(tbData.nChannel, 1)
--         else
--             bHasChanged = true
--         end
--     end

--     if bHasChanged then
--         self.tbDataList = tbNewTable
--         Event.Dispatch(EventType.OnChatHintMsgUpdate)
--     end
-- end

function ChatHintMgr.AddUIChannelCount(nChannel, nCount)
    if not nChannel then
        return
    end

    if not nCount then
        return
    end

    local szUIChannel = HINT_CHANNEL_TO_UICHANNEL[nChannel]
    if string.is_nil(szUIChannel) then
        return
    end

    if self.tbUIChannelCountMap[szUIChannel] == nil then
        self.tbUIChannelCountMap[szUIChannel] = 0
    end

    self.tbUIChannelCountMap[szUIChannel] = self.tbUIChannelCountMap[szUIChannel] + nCount
    if self.tbUIChannelCountMap[szUIChannel] < 0 then
        self.tbUIChannelCountMap[szUIChannel] = 0
    end
end

function ChatHintMgr.ClearUIChannelCount()
    self.tbUIChannelCountMap = {}
end

function ChatHintMgr.StartTimer()
    self.StopTimer()

    self.nTimerID = Timer.AddCycle(self, 1, function()
        local nLen = #self.tbDataList
        if nLen <= 0 then
            self.StopTimer()
            return
        end

        self.Tick()
    end)
end

function ChatHintMgr.StopTimer()
    if self.nTimerID then
        Timer.DelTimer(self, self.nTimerID)
        self.nTimerID = nil
    end
end

function ChatHintMgr.Tick()
    --self.RemoveDataByTimeup()
    Event.Dispatch(EventType.OnChatHintMsgUpdate)
end


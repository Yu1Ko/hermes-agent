-- ---------------------------------------------------------------------------------
-- Author: huqing
-- Name: ChatAINpcMgr
-- Date: 2026-02-06 16:39:59
-- Desc: AI NPC 聊天管理器
-- ---------------------------------------------------------------------------------

ChatAINpcMgr = ChatAINpcMgr or {className = "ChatAINpcMgr"}
local self = ChatAINpcMgr
-------------------------------- 消息定义 --------------------------------
ChatAINpcMgr.Event = {}
ChatAINpcMgr.Event.XXX = "ChatAINpcMgr.Msg.XXX"



local STATEMENT_TITLE = "侠缘对话功能使用温馨提示"
local STATEMENT_CONTENT = [[亲爱的侠士，欢迎使用侠缘对话功能！为了让您获得更好的体验，请阅读以下内容：

一、您的输入，由您负责

您在使用本功能时，请确保输入的内容符合相关法律法规及游戏规范，共同维护健康、友善的江湖环境：

1. 不输入含有低俗、淫秽、色情、暴力、宣扬赌博、邪教、迷信、谣言，或违背社会公德的内容；
2.不输入任何违法违规信息，包括但不限于危害国家安全、散布谣言、煽动对立等内容；
3. 不发布侮辱、诽谤他人或侵犯他人合法权益的言论；
4. 不透露他人隐私信息或商业机密等敏感内容；
如发现违规行为，我们将依据游戏用户协议采取必要措施，感谢您的理解与配合。

二、AI所知，限于江湖

智能NPC的认知范围主要围绕剑网3的游戏世界观、剧情和角色设定。这意味着：
1. 您可以与侠缘交谈游戏内的剧情故事、门派设定、角色背景等相关话题；
2. 涉及现实世界、现代知识或与游戏设定无关的内容，AI可能无法准确理解或回应，请您谅解；
3. 如果对话偏离了游戏设定，AI会尝试将话题引导回来，帮助您更好地沉浸于江湖世界。

特别提醒：如果您希望NPC结束当前话题或调整对话方向，可以输入“换个话题”等关键词，它会进行反思并作出优化。
AI所生成的内容，均基于您的输入、游戏设定及相关知识库自动产生，不代表西山居官方的观点、立场或承诺。我们对生成内容的真实性、准确性和完整性不作任何保证，请您理性参考，切勿作为现实决策的依据。

若您同意以上内容，点击“接受”即可开启江湖对话；若您暂不同意，点击“拒绝”即可退出。感谢您的支持，祝您游戏愉快！
]]


-- AI NPC的聊天消息发送者类型
--[[
CHAT_RECORD_SENDER_TYPE.INVALID
CHAT_RECORD_SENDER_TYPE.SYSTEM
CHAT_RECORD_SENDER_TYPE.PLAYER
CHAT_RECORD_SENDER_TYPE.NPC
]]


self.dwCurAINpcID = nil -- 当前聊天的AI NPC ID
self.tbRecentList = {} -- 最近聊天NPC列表

-- 临时缓存，到时候走到逻辑层存储
self.tbMapMsgCache = {} -- 聊天消息缓存，key:dwNpcId, value:tbMessages

-- 未读消息
self.tbMapUnRead = {} -- key:dwNpcId, value:bool

-- 聊天历史记录
self.tbMapFetchStartFlowID = {}
self.tbMapFetchDone = {}
-- 保存到某个地方，类似这种table，确保重开界面不会消失
self.tbWaitForTextFilterResultMessage = {}

-- 聊天消息发出去了还没返回
self.bChatIsWaiting = false
-- 聊天消息正在过滤中
self.bChatIsFiltering = false
-- 功能是否开放
self.bOpen = false
-- 是否显示心情值
self.bShowMood = false
-- 是否深度思考
self.bDeepThink = false



function ChatAINpcMgr.Init()
    ChatAINpcMgr.Reset()

    Event.Reg(self, "AI_AGENT_CHAT_RESPONSE", function(dwNpcTemplateId, dwNpcId, szNpcName, szResponse)
        LOG.INFO("ChatAINpcMgr.AI_AGENT_CHAT_RESPONSE dwNpcTemplateId:%s, dwNpcId:%s, szNpcName:%s, szResponse:%s", tostring(dwNpcTemplateId), tostring(dwNpcId), tostring(GBKToUTF8(szNpcName)), tostring(GBKToUTF8(szResponse)))
        if string.is_nil(szResponse) then return end

        dwNpcId = (dwNpcId == 0) and ChatAINpcMgr.GetNpcIDByTemplateID(dwNpcTemplateId) or dwNpcId

        ChatAINpcMgr.SetChatWaiting(false, dwNpcId)
        ChatAINpcMgr.AppendMsg(dwNpcId, szResponse, CHAT_RECORD_SENDER_TYPE.NPC)
        ChatAINpcMgr.SetUnRead(dwNpcId, true)

        --local szContent = GBKToUTF8(szResponse)
        --ChatData.Append(szContent, dwNpcId, CLIENT_PLAYER_TALK_CHANNEL.AINPC)
    end)

    Event.Reg(self, "ON_AI_AGENT_CHAT_NOTIFY", function(nCode)
        LOG.INFO("ChatAINpcMgr.ON_AI_AGENT_CHAT_NOTIFY nCode:%s", tostring(nCode))

        local dwNpcId = ChatAINpcMgr.GetCurAINpcID()
        ChatAINpcMgr.SetChatWaiting(false, nil)
        ChatAINpcMgr.ShowErrorMsg(nCode, dwNpcId)
    end)

    -- 发出去的消息要先进行过滤，过滤结果通过这个事件返回
    Event.Reg(self, "ON_AI_AGENT_CHAT_TEXT_FILTER_NOTIFY", function(szClientMessageID, bPass)
        LOG.INFO("ChatAINpcMgr.ON_AI_AGENT_CHAT_TEXT_FILTER_NOTIFY szClientMessageID:%s bPass:%s", szClientMessageID, tostring(bPass))

        ChatAINpcMgr.SetChatFiltering(false)

        if bPass then
            -- 检查通过，尝试找到之前保存的消息，显示出来
            local tbMsgData = self.tbWaitForTextFilterResultMessage[szClientMessageID]
            if tbMsgData then
                local dwID = tbMsgData.dwID
                local szMessage = tbMsgData.szMessage
                local tbData = ChatAINpcMgr.AppendMsg(dwID, szMessage, CHAT_RECORD_SENDER_TYPE.PLAYER, nil, false, true)
                ChatAINpcMgr.SetChatWaiting(true, dwID)
                ChatAINpcMgr.DispatchRecive(tbData)
            else
                LOG.ERROR("ChatAINpcMgr.ON_AI_AGENT_CHAT_TEXT_FILTER_NOTIFY no wait message found for szClientMessageID:%s", szClientMessageID)
            end
        else
            -- 失败，则弹个提示之类的
            local tbMsgData = self.tbWaitForTextFilterResultMessage[szClientMessageID]
            local dwID = tbMsgData and tbMsgData.dwID or nil
            ChatAINpcMgr.ShowErrorMsg(AI_AGENT_CHAT_ERROR_CODE.TEXT_FILTER, dwID)
        end

        self.tbWaitForTextFilterResultMessage[szClientMessageID] = nil
    end)


    Event.Reg(self, "PLAYER_EXIT_GAME", function()
        ChatAINpcMgr.Reset()
    end)

    Event.Reg(self, EventType.OnAccountLogout, function()
        ChatAINpcMgr.Reset()
    end)

    Event.Reg(self, EventType.OnRoleLogin, function()
        self.bDeepThink = Storage.ChatAINpc.bDeepThink
        self.tbRecentList = Storage.ChatAINpc.tbAINpcList or {}
    end)
end

function ChatAINpcMgr.Reset()
    self.dwCurAINpcID = nil
    self.tbRecentList = {}
    self.tbMapMsgCache = {}
    self.tbMapUnRead = {}
    self.tbMapFetchStartFlowID = {}
    self.tbMapFetchDone = {}
    self.tbWaitForTextFilterResultMessage = {}
    self.bChatIsWaiting = false
    self.bChatIsFiltering = false
    self.dwChatingNpcId = nil
end

function ChatAINpcMgr.UnInit()

end

function ChatAINpcMgr.OnLogin()

end

function ChatAINpcMgr.OnFirstLoadEnd()

end

function ChatAINpcMgr.IsOpen()
    return self.bOpen
end

function ChatAINpcMgr.IsShowMood()
    return self.bShowMood
end

function ChatAINpcMgr.IsChatWaiting()
    return self.bChatIsWaiting
end

function ChatAINpcMgr.SetChatWaiting(bVal, dwNpcId)
    self.bChatIsWaiting = bVal

    dwNpcId = dwNpcId or self.dwChatingNpcId

    if dwNpcId and not self.tbMapMsgCache[dwNpcId] then
        self.tbMapMsgCache[dwNpcId] = {}
    end

    -- 保护性代码，防止服务器顺序出错了，客户端锁死，不能继续聊天
    if not dwNpcId and ChatAINpcMgr.IsChatFiltering() then
        ChatAINpcMgr.SetChatFiltering(false)
    end

    if self.bChatIsWaiting then
        local tbTimeData = {
            dwTalkerID = UI_GetClientPlayerID(),
            nChannel = CLIENT_PLAYER_TALK_CHANNEL.AINPC,
            szContent = "思考中...",
            nPrefabID = PREFAB_ID.WidgetChatTime,
            tbUIChannelMap = { [UI_Chat_Channel.AINpc] = true},
            nTime = os.time(),
        }

        if dwNpcId then
            table.insert(self.tbMapMsgCache[dwNpcId], tbTimeData)
        end

        self.dwChatingNpcId = dwNpcId

        -- 超时处理
        Timer.DelTimer(self, self.nTimeoutID)
        self.nTimeoutID = Timer.Add(self, 120, function()
            ChatAINpcMgr.SetChatWaiting(false, dwNpcId)
        end)
    else
        if dwNpcId then
            if self.tbMapMsgCache[dwNpcId] then
                local nLen = table.get_len(self.tbMapMsgCache[dwNpcId])
                local tbData = self.tbMapMsgCache[dwNpcId][nLen]
                if tbData and tbData.nPrefabID == PREFAB_ID.WidgetChatTime then
                    table.remove(self.tbMapMsgCache[dwNpcId])
                    ChatAINpcMgr.DispatchRecive(tbData)
                end
            end
        end

        self.dwChatingNpcId = nil
    end

    Event.Dispatch(EventType.OnChatAINpcWaiting, self.bChatIsWaiting)
end

function ChatAINpcMgr.IsChatFiltering()
    return self.bChatIsFiltering
end

function ChatAINpcMgr.SetChatFiltering(bVal)
    self.bChatIsFiltering = bVal

    Event.Dispatch(EventType.OnChatAINpcFiltering, bVal)
end

function ChatAINpcMgr.ShowErrorMsg(nErrorCode, dwNpcId, bAppendToHead, bNotDispatchEvent)
    local dwNpcId = dwNpcId or self.dwChatingNpcId
    if not dwNpcId then
        return
    end

    local szError = g_tStrings.tAIAgentChatErrorCode[nErrorCode]
    if string.is_nil(szError) then
        return
    end

    local szMsg = string.format("[%s]", JsonEncode({text = UIHelper.UTF8ToGBK(szError), type = "text"}))
    local nType = CHAT_RECORD_SENDER_TYPE.SYSTEM
    local nTimestamp = os.time()
    ChatAINpcMgr.AppendMsg(dwNpcId, szMsg, nType, nTimestamp, bAppendToHead, bNotDispatchEvent)


    -- local tbTimeData = {
    --     dwTalkerID     = UI_GetClientPlayerID(),
    --     nChannel       = CLIENT_PLAYER_TALK_CHANNEL.AINPC,
    --     szContent      = szMsg,
    --     nPrefabID      = PREFAB_ID.WidgetChatTime,
    --     tbUIChannelMap = { [UI_Chat_Channel.AINpc] = true},
    --     nTime          = os.time(),
    --     bIsWarringType = true,
    -- }

    -- table.insert(self.tbMapMsgCache[dwNpcId], tbTimeData)
    -- Event.Dispatch(EventType.OnReceiveChat, tbTimeData)
end

function ChatAINpcMgr.Chat(dwID, szMessage)--dwNpcTemplateId, dwNpcId, szNpcName, szMessage)
    if ChatAINpcMgr.IsChatWaiting() or ChatAINpcMgr.IsChatFiltering() then
        TipsHelper.ShowNormalTip("侠缘消息回复中，请稍候。")
        return
    end

    if not g_pClientPlayer then
        return
    end

    if not dwID and not szMessage then
        return
    end

    local tbNpcInfo = ChatAINpcMgr.GetNpcInfo(dwID)
    if not tbNpcInfo then
        return
    end

    local dwNpcTemplateId = GetNpcAssistedTemplateID(tbNpcInfo.dwID)
    local szNpcName = tbNpcInfo.szName
    local szClientMessageID = string.format("%d%04d", os.time(), math.random(1, 9999))

    -- AIAgentChat 使用表情等其他标签
    -- 如果经过ChatPrase解析后 szMessage 就是GBK格式的了，否则就是UTF8

    LOG.INFO("ChatAINpcMgr.Chat dwID:%s,  szNpcName:%s, szMessage:%s, bDeepThink:%s, szClientMessageID:%s", tostring(dwID), tostring(GBKToUTF8(szNpcName)), GBKToUTF8(szMessage), tostring(self.bDeepThink), szClientMessageID)
    g_pClientPlayer.AIAgentChat(dwNpcTemplateId, 0, szNpcName, szMessage, self.bDeepThink, szClientMessageID)

    self.tbWaitForTextFilterResultMessage[szClientMessageID] = {dwID = dwID, szMessage = szMessage}

    ChatAINpcMgr.SetChatFiltering(true)

    return true
end

function ChatAINpcMgr.AppendMsg(dwNpcId, szMessage, nType, nTimestamp, bAppendToHead, bNotDispatchEvent)
    if not dwNpcId and not szMessage then
        return
    end

    if not self.tbMapMsgCache[dwNpcId] then
        self.tbMapMsgCache[dwNpcId] = {}
    end

    local tbNpcInfo = ChatAINpcMgr.GetNpcInfo(dwNpcId)
    local szSmallAvatarImg = tbNpcInfo and tbNpcInfo.szSmallAvatarImg or ""
    local szName = tbNpcInfo and tbNpcInfo.szName or ""
    local nLevel = tbNpcInfo and tbNpcInfo.nLevel or 1
    local nForceID = tbNpcInfo and tbNpcInfo.nForceID or 0
    local nRoleType = tbNpcInfo and tbNpcInfo.nRoleType or 2
    local dwMiniAvatarID = tbNpcInfo and tbNpcInfo.dwMiniAvatarID or 0
    local nCamp = 0
    local dwTitleID = 0
    local bVoice = false
    local szGlobalID = "AI_AGENT_CHAT"

    local bIsPlayerType = nType == CHAT_RECORD_SENDER_TYPE.PLAYER
    local bIsSystemType = nType == CHAT_RECORD_SENDER_TYPE.SYSTEM
    if bIsPlayerType then
        szName = g_pClientPlayer and g_pClientPlayer.szName or ""
        nLevel = g_pClientPlayer and g_pClientPlayer.nLevel or 1
        nForceID = g_pClientPlayer and g_pClientPlayer.dwForceID or 0
        nRoleType = g_pClientPlayer and g_pClientPlayer.nRoleType or 2
        dwMiniAvatarID = g_pClientPlayer and g_pClientPlayer.dwMiniAvatarID or 0

        nCamp = g_pClientPlayer and g_pClientPlayer.nCamp or 0
        szGlobalID = UI_GetClientPlayerGlobalID()
        --dwTitleID = g_pClientPlayer and g_pClientPlayer.dwTitleID or 0
    end

    -- AIAgentChat 使用表情等其他标签
    local dwTalkerID = bIsPlayerType and g_pClientPlayer.dwID or 0
    local tbTalkData = JsonDecode(szMessage)
    local szChatContent = ChatData.Parse(dwTalkerID, CLIENT_PLAYER_TALK_CHANNEL.AINPC, false, szName, false, false, false, false, nil, nil, nil, nil, nil, nil, nil, tbTalkData)

    bVoice = tbTalkData and tbTalkData[1] and (tbTalkData[1].type == "voice")

    local tbData =
    {
        dwTalkerID = dwTalkerID,
        dwID = dwNpcId,
        szGlobalID = szGlobalID,
        szContent = szChatContent or szMessage,
        nType = nType,
        nChannel = CLIENT_PLAYER_TALK_CHANNEL.AINPC,
        nTime = nTimestamp or os.time(),
        bVoice = bVoice,
        nPrefabID = ChatAINpcMgr.GetPrefabID(nType, bVoice),
        tbUIChannelMap = { [UI_Chat_Channel.AINpc] = true},

        szSmallAvatarImg = szSmallAvatarImg,
        szName = szName,
        nLevel = nLevel,
        nForceID = nForceID,
        nRoleType = nRoleType,
        dwMiniAvatarID = dwMiniAvatarID,
        nCamp = nCamp,
        dwTitleID = dwTitleID,

        tbMsg = tbTalkData,

        bIsWarringType = bIsSystemType,
    }

    if bAppendToHead then
        table.insert(self.tbMapMsgCache[dwNpcId], 1, tbData)
    else
        table.insert(self.tbMapMsgCache[dwNpcId], tbData)
    end

    if not bNotDispatchEvent then
        ChatAINpcMgr.DispatchRecive(tbData)
    end

    return tbData
end

function ChatAINpcMgr.GetPrefabID(nType, bIsVoice)
    -- 时间消息
    -- 拉取隔断

    local bIsSelf   = (nType == CHAT_RECORD_SENDER_TYPE.PLAYER)
    local bIsNpc    = (nType == CHAT_RECORD_SENDER_TYPE.NPC)
    local bIsSystem = (nType == CHAT_RECORD_SENDER_TYPE.SYSTEM)

    local nPrefabID = PREFAB_ID.WidgetChatPlayer

    if bIsSystem then
        nPrefabID = PREFAB_ID.WidgetChatTime
    else
        if bIsVoice then
            nPrefabID = bIsSelf and PREFAB_ID.WidgetChatSelfVoice or PREFAB_ID.WidgetChatPlayerVoice
        else
            nPrefabID = bIsSelf and PREFAB_ID.WidgetChatSelf or PREFAB_ID.WidgetChatPlayer
        end
    end

    return nPrefabID
end

function ChatAINpcMgr.GetNpcMood(dwNpcId)
    return 0
end

function ChatAINpcMgr.GetDataList(dwNpcId)
    return self.tbMapMsgCache[dwNpcId] or {}
end

function ChatAINpcMgr.GetDataListLen(dwNpcId)
    local tbDataList = ChatAINpcMgr.GetDataList(dwNpcId)
    return #tbDataList
end

function ChatAINpcMgr.GetOneData(dwNpcId, nIndex)
    local tbDataList = ChatAINpcMgr.GetDataList(dwNpcId)
    if not tbDataList or nIndex < 1 or nIndex > #tbDataList then
        return nil
    end

    return tbDataList[nIndex]
end

function ChatAINpcMgr.GetNpcList()
    local tbResultList = {}
    local tbListNpc = Partner_GetAllPartnerList(nil, true, true)
    for k, v in ipairs(tbListNpc) do
        if ChatAINpcMgr.IsAIChatNpc(v.dwID) then
            table.insert(tbResultList, v)
        end
    end

    return tbResultList
end

function ChatAINpcMgr.IsAIChatNpc(dwNpcId)
    local tInfo = Table_GetPartnerNpcInfo(dwNpcId)
    local bIsAIChatNpc = tInfo and tInfo.bAIChat
    return bIsAIChatNpc
end

function ChatAINpcMgr.GetNpcInfo(dwID)
    local tbListNpc = ChatAINpcMgr.GetNpcList()
    for _, tbInfo in pairs(tbListNpc) do
        if tbInfo.dwID == dwID then
            return tbInfo
        end
    end

    return nil
end

function ChatAINpcMgr.GetNpcIDByTemplateID(dwTemplateID)
    local tbMap = PartnerData.GetNpcTemplateIDToPartnerIDMap()
    local dwNpcId = tbMap and tbMap[dwTemplateID]
    return dwNpcId
end

function ChatAINpcMgr.GetCurAINpcID()
    return self.dwCurAINpcID
end

function ChatAINpcMgr.SetCurAINpcID(dwID)
    self.dwCurAINpcID = dwID

    ChatAINpcMgr.SetUnRead(dwID, false)
end

-- 添加到最近聊天NPC列表
function ChatAINpcMgr.AddToRecentList(dwID)
    if not dwID then return end

    local bResult1 = table.remove_value(self.tbRecentList, dwID)
    table.insert(self.tbRecentList, 1, dwID)

    -- 存到本地
    local bResult2 = table.remove_value(Storage.ChatAINpc.tbAINpcList, dwID)
    table.insert(Storage.ChatAINpc.tbAINpcList, 1, dwID)
    Storage.ChatAINpc.Flush()
end

-- 从最近聊天NPC列表中移除
function ChatAINpcMgr.RemoveFromRecentList(dwID)
    if not dwID then return end

    local bResult = table.remove_value(self.tbRecentList, dwID)

    table.remove_value(Storage.ChatAINpc.tbAINpcList, dwID)
    Storage.ChatAINpc.Flush()

    ChatAINpcMgr.SetUnRead(dwID, false)
end

-- 获取最近聊天NPC列表
function ChatAINpcMgr.GetRecentList()
    return self.tbRecentList
end

-- 请求聊天记录
function ChatAINpcMgr.FetchChatRecord(dwNpcId, nStartFlowID, nRecordCount)
    if self.bIsFetching then
        return
    end

    if ChatAINpcMgr.IsFetchDone(dwNpcId) then
        TipsHelper.ShowNormalTip("没有更多历史聊天了。")
        return
    end

    local dwNpcTemplateID = GetNpcAssistedTemplateID(dwNpcId)
    local nCurNpcStartFlowID = ChatAINpcMgr.GetFetchStartFlowID(dwNpcId)
    if nCurNpcStartFlowID > 0 then
        if nCurNpcStartFlowID == 1 then
            TipsHelper.ShowNormalTip("没有更多历史聊天了。")
            ChatAINpcMgr.SetFetchDone(dwNpcId)
            return
        end

        nCurNpcStartFlowID = nCurNpcStartFlowID - 1
    end

    nStartFlowID = nStartFlowID or nCurNpcStartFlowID
    nRecordCount = nRecordCount or 10

    self.bIsFetching = true
    AIAgentChatRecordManager.FetchChatRecord(dwNpcTemplateID, nStartFlowID, nRecordCount, function(bSuccess, tRecords, szError)
        self.bIsFetching = false

        if bSuccess then
            if not tRecords then
                return
            end

            -- 如果没有了
            if table.is_empty(tRecords) then
                TipsHelper.ShowNormalTip("没有更多历史聊天了。")
                ChatAINpcMgr.SetFetchDone(dwNpcId)
                return
            end

            local tbData = nil
            local nCount = table.get_len(tRecords)
            for _, record in ipairs(tRecords) do
                if nCurNpcStartFlowID == -1 or record.nFlowID < nCurNpcStartFlowID then
                    ChatAINpcMgr.SetFetchStartFlowID(dwNpcId, record.nFlowID)
                end

                local szContent = record.szContent
                -- if record.eSender == CHAT_RECORD_SENDER_TYPE.NPC then
                --     szContent = GBKToUTF8(record.szContent)
                -- end

                -- AI Agent Error 处理
                if record.eSender == CHAT_RECORD_SENDER_TYPE.SYSTEM then
                    local tbTalkData = JsonDecode(szContent)
                    if tbTalkData and tbTalkData[1] and (tbTalkData[1].type == "agent_error") then
                        local nErrorCode = tonumber(tbTalkData[1].text) or -1
                        local szError = g_tStrings.tAIAgentChatErrorCode[nErrorCode]
                        if not string.is_nil(szError) then
                            szContent = string.format("[%s]", JsonEncode({text = UIHelper.UTF8ToGBK(szError), type = "text"}))
                        end
                    end
                end

                tbData = ChatAINpcMgr.AppendMsg(dwNpcId, szContent, record.eSender, record.nTimestamp, true, true)
            end

            if nCount > 0 and tbData then
                ChatAINpcMgr.DispatchRecive(tbData, true)
            end
        else

        end
    end)

end

function ChatAINpcMgr.IsFetchDone(dwNpcId)
    return self.tbMapFetchDone[dwNpcId]
end

function ChatAINpcMgr.SetFetchDone(dwNpcId)
    self.tbMapFetchDone[dwNpcId] = true
    Event.Dispatch(EventType.OnChatAINpcFetchDoneChange, dwNpcId)
end

function ChatAINpcMgr.GetFetchStartFlowID(dwNpcId)
    return self.tbMapFetchStartFlowID[dwNpcId] or -1
end

function ChatAINpcMgr.SetFetchStartFlowID(dwNpcId, nStartFlowID)
    self.tbMapFetchStartFlowID[dwNpcId] = nStartFlowID
end

-- 设置未读消息
function ChatAINpcMgr.SetUnRead(dwNpcId, bIsUnRead)
    -- 如果是设置成有未读，并且当前正在和这个AI NPC聊天，就不设置未读了
    if bIsUnRead == true then
        local bIsChatInAIChannel, chatScript = APIHelper.IsChatInUIChannel(UI_Chat_Channel.AINpc)
        local nCurAINpcID = ChatAINpcMgr.GetCurAINpcID()
        -- 如果当前正在和这个AI NPC聊天，就不设置未读了
        if bIsChatInAIChannel and nCurAINpcID == dwNpcId then
            return
        end
    end

    if self.tbMapUnRead[dwNpcId] then
        self.tbMapUnRead[dwNpcId] = bIsUnRead
    end

    Event.Dispatch(EventType.OnChatAINpcUnReadChange, dwNpcId, bIsUnRead)
end

function ChatAINpcMgr.HasUnRead(dwNpcId)
    local bResult = false

    if dwNpcId then
        bResult = self.tbMapUnRead[dwNpcId]
    else
        for _, bIsUnRead in pairs(self.tbMapUnRead) do
            if bIsUnRead then
                bResult = true
                break
            end
        end
    end

    return bResult
end

function ChatAINpcMgr.PrivacyPop(confirmCallback)
    local szKey = "ChatAINpcMgr_PrivacyPop"
    if APIHelper.IsDid(szKey) then
        Lib.SafeCall(confirmCallback)
        return
    end

    local script = UIMgr.Open(VIEW_ID.PanelStatementRulePop, STATEMENT_TITLE, STATEMENT_CONTENT, function()
        Lib.SafeCall(confirmCallback)
        APIHelper.Do(szKey)
    end)

    script:SetConfirmLabel("接受")
    script:SetCancelLabel("拒绝")
end

function ChatAINpcMgr.OpenDeepThink(bVal)
    self.bDeepThink = bVal

    Storage.ChatAINpc.bDeepThink = bVal
    Storage.ChatAINpc.Flush()
end

function ChatAINpcMgr.IsDeepThink()
    return self.bDeepThink
end

function ChatAINpcMgr.DispatchRecive(tbData, bTop)
    Event.Dispatch(EventType.OnReceiveChat, tbData, bTop)
end
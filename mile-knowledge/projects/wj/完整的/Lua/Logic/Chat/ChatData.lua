-- ---------------------------------------------------------------------------------
-- Author: huqing
-- Name: ChatData
-- Date: 2022-12-13 14:32:49
-- Desc: 聊天逻辑
-- ---------------------------------------------------------------------------------
local MAX_TIMESTAMP_INTERVAL = 300     -- 需要显示时间戳的间隔
local RECIVE_DELAY = 0--0.05           -- 处理每条消息的延时，避免消息来太多，处理的时候会特别卡
local APPEND_DELAY = 0--0.15           -- 处理每条消息的延时，避免消息来太多，处理的时候会特别卡
local NEED_RESIZE_COUNT = 2000         -- 当聊天主界面打开时，某个频道超过这个数时，就做一次Resize
local RECORDING_MAX_TIME = 58000       -- 录音最长时间 58秒

-- 各频道的发送频率
local CHANNEL_SEND_CD =
{
    [PLAYER_TALK_CHANNEL.WORLD]        = 60,
    [CLIENT_PLAYER_TALK_CHANNEL.AINPC] = 0,
}

-- 支持发送语音的频道
local CHANNEL_VOICE_ALBLE =
{
    [PLAYER_TALK_CHANNEL.TONG]         = true,
    [PLAYER_TALK_CHANNEL.WHISPER]      = true,
    [CLIENT_PLAYER_TALK_CHANNEL.AINPC] = true,
    [PLAYER_TALK_CHANNEL.TEAM]         = true,
    [PLAYER_TALK_CHANNEL.RAID]         = true,
    [PLAYER_TALK_CHANNEL.ROOM]         = true,
    --[PLAYER_TALK_CHANNEL.NEARBY]     = true,
}

-- 不同Channel打开不同设置Index
local UI_CHANNEL_2_SETTING_INDEX =
{
    [UI_Chat_Channel.Display]  = 1,
    [UI_Chat_Channel.All]      = 2,
    [UI_Chat_Channel.Common]   = 3,
    [UI_Chat_Channel.Whisper]  = 4,
    [UI_Chat_Channel.AINpc]    = 5,
    [UI_Chat_Channel.Team]     = 6,
    [UI_Chat_Channel.Tong]     = 7,
    [UI_Chat_Channel.Camp]     = 8,
    [UI_Chat_Channel.Identity] = 9,
    [UI_Chat_Channel.SENCE]    = 10,
    [UI_Chat_Channel.Force]    = 11,
    [UI_Chat_Channel.Other]    = 12,
    [UI_Chat_Channel.System]   = 13,
    [UI_Chat_Channel.Fight]    = 14,
    [UI_Chat_Channel.Hint]     = 15,
    [UI_Chat_Channel.NPCStory] = 16,
    [UI_Chat_Channel.Action]   = 17,
    [UI_Chat_Channel.AutoChat] = 18,
}

local CMD_CHANNEL = {
	[PLAYER_TALK_CHANNEL.NPC_SENCE]   = true,
	[PLAYER_TALK_CHANNEL.NPC_NEARBY]  = true,
	[PLAYER_TALK_CHANNEL.NPC_WHISPER] = true,
}

-- 不能举报的频道
local CHANNEL_REPORT_DISALBLE =
{
    [PLAYER_TALK_CHANNEL.GM_MESSAGE]            = true,
    [PLAYER_TALK_CHANNEL.LOCAL_SYS]             = true,
    [PLAYER_TALK_CHANNEL.GLOBAL_SYS]            = true,
    [PLAYER_TALK_CHANNEL.GM_ANNOUNCE]           = true,
    [PLAYER_TALK_CHANNEL.TO_TONG_GM_ANNOUNCE]   = true,
    [PLAYER_TALK_CHANNEL.TO_PLAYER_GM_ANNOUNCE] = true,

    [PLAYER_TALK_CHANNEL.NPC_NEARBY]            = true,
    [PLAYER_TALK_CHANNEL.NPC_PARTY]             = true,
    [PLAYER_TALK_CHANNEL.NPC_SENCE]             = true,
    [PLAYER_TALK_CHANNEL.NPC_WHISPER]           = true,
    [PLAYER_TALK_CHANNEL.NPC_SAY_TO]            = true,
    [PLAYER_TALK_CHANNEL.NPC_YELL_TO]           = true,
    [PLAYER_TALK_CHANNEL.NPC_FACE]              = true,
    [PLAYER_TALK_CHANNEL.NPC_SAY_TO_ID]         = true,
    [PLAYER_TALK_CHANNEL.NPC_SAY_TO_CAMP]       = true,
    [PLAYER_TALK_CHANNEL.STORY_NPC]             = true,
    [PLAYER_TALK_CHANNEL.STORY_NPC_YELL]        = true,
    [PLAYER_TALK_CHANNEL.STORY_NPC_WHISPER]     = true,
    [PLAYER_TALK_CHANNEL.STORY_NPC_SAY_TO]      = true,
    [PLAYER_TALK_CHANNEL.STORY_NPC_YELL_TO]     = true,
    [PLAYER_TALK_CHANNEL.SYSTEM_NOTICE]         = true,

    --[PLAYER_TALK_CHANNEL.NEARBY]    = true,
}

-- 不能复制的频道
local CHANNEL_COPY_DISALBLE =
{
    [PLAYER_TALK_CHANNEL.IDENTITY]              = true,
}

local CHANNEL_NICKNAME =
{
    ["李渡鬼域"] = "李渡",
}

-- 聊天面板UI页签对应的发送频道
local UIChannel_To_SendChannel =
{
    [UI_Chat_Channel.All]      = {nDefaultChannelID = PLAYER_TALK_CHANNEL.NEARBY, bCanSwitch = true},
    [UI_Chat_Channel.Common]   = {nDefaultChannelID = PLAYER_TALK_CHANNEL.NEARBY, bCanSwitch = true},
    [UI_Chat_Channel.Whisper]  = {nDefaultChannelID = PLAYER_TALK_CHANNEL.WHISPER, bCanSwitch = false},
    [UI_Chat_Channel.AINpc]    = {nDefaultChannelID = CLIENT_PLAYER_TALK_CHANNEL.AINPC, bCanSwitch = false},
    [UI_Chat_Channel.Team]     = {nDefaultChannelID = {PLAYER_TALK_CHANNEL.RAID, PLAYER_TALK_CHANNEL.TEAM}, bCanSwitch = true},
    [UI_Chat_Channel.Tong]     = {nDefaultChannelID = PLAYER_TALK_CHANNEL.TONG, bCanSwitch = true},
    [UI_Chat_Channel.Camp]     = {nDefaultChannelID = PLAYER_TALK_CHANNEL.CAMP, bCanSwitch = true},
    [UI_Chat_Channel.Identity] = {nDefaultChannelID = PLAYER_TALK_CHANNEL.IDENTITY, bCanSwitch = false},
    [UI_Chat_Channel.SENCE]    = {nDefaultChannelID = PLAYER_TALK_CHANNEL.SENCE, bCanSwitch = true},
    [UI_Chat_Channel.Force]    = {nDefaultChannelID = PLAYER_TALK_CHANNEL.FORCE, bCanSwitch = true},
    [UI_Chat_Channel.Other]    = {nDefaultChannelID = PLAYER_TALK_CHANNEL.NEARBY, bCanSwitch = true},
}

-- 客户端禁用的表情GroupID
local CHAT_DISABLE_EMOJI_GROUP =
{
    [17] = true, -- 弹幕表情
}


ChatData = ChatData or {className = "ChatData"}
local self = ChatData



self.tbChatData = {}            -- 存放各个频道的聊天数据
self.tbWhisperList = {}
self.tbWhisperDataMap = {}

self.tbRecvChannelMap = {}      -- 接收频道字典 self.tbRecvChannelMap[nChannel][szUIChannel] = true
self.tbSystemRewardMap = {}     -- 系统频道奖励字典 self.tbSystemRewardMap[szMsg] = true
self.tbSystemFilterKeyWords = {} -- 过滤的系统消息关键字列表
self.tbNpcStoryChannleMap = {} -- NPC剧情能接受的和不能接受的频道字典
self.tbFightMsgMap = {}        -- 战斗频道消息字典 self.tbFightMsgMap[szMsg] = true
self.tbHintReciveChannelMap = {}     -- 迷你面板频道列表 self.tbHintReciveChannelMap = {[5] = true, }
self.tbActionChannelList = {}   -- 动作表情频道列表 self.tbActionChannelList = {szUIChannel}
self.tbSettingConfigMap = {}    -- 设置字典 self.tbSettingConfigMap = {[szUIChannel][Recv] = {"近聊频道" = bDefaultSelect,"地图频道" = bDefaultSelect,}}
self.tbSettingRuntimeMap = {}   -- 设置字典，运行时的 结构和 self.tbSettingConfigMap 一样


self.tbChannelIDToFlagConfMap = {}  -- 用作显示频道背景图片和名字，没有逻辑意义
self.tbUIChannelToConfMap = {}
self.tbUIChannelToMaxCountMap = {}

self.tbRecivePendingList = {}   -- 接收 队列
self.tbAppendPendingList = {}   -- Append 队列

self.tbWhisperUnreadMap = {}    -- 密聊未读记录

self.tbChannelSendTimeMap = {} -- 聊天频道发送聊天的时间记录 {PLAYER_TALK_CHANNEL.WHISPER = 0,}

self.tbChannelVoiceModeMap = {} -- 聊天界面某个频道是否是语音模式


self.bCanShowChatCopyTips = true -- 能否显示聊天点击弹出的tips

self.tbRunTimeUIChannelToSendChannel = {} -- 运行时，聊天面板UI页签对应的选择频道

self.nOpenDisturbTime = nil   --密聊勿扰开启时间

-- 弹幕
self.tbBulletDataList = {} -- 过图是否要清掉？
self.nBulletDataMaxCount = 300 -- 最大上限处理，超过就删除前面的

-- 弹幕基础数据（对应 ui 端 DanmakuBase.lua）
self.tbBulletMap = {}         -- 地图ID -> 弹幕类型
self.tbBulletBase = {}        -- 弹幕类型 -> 配置 {tFont, tColor, tMode}
self.nBulletMapID = nil       -- 当前地图ID
self.nBulletMapType = nil     -- 当前地图的弹幕类型
self.bBulletDebug = nil       -- 是否弹幕调试模式，开启后会显示弹幕类型等信息



function ChatData.Init()
    self.InitData()

    Event.Reg(self, EventType.OnRoleLogin, function()
        self.Reset()
        self.InitSettings()

        ChatHelper.AppendLoginInfo()
    end)

    Event.Reg(self, "PLAYER_CHAT", function(...)
        local tbOneData = {...}
        tbOneData._szChatType = "PLAYER_CHAT"
        table.insert(self.tbRecivePendingList, tbOneData)

        ChatData.StartRecivePending()
    end)

    Event.Reg(self, "PLAYER_TALK", function(...)
        local tbOneData = {...}
        tbOneData._szChatType = "PLAYER_TALK"
        table.insert(self.tbRecivePendingList, tbOneData)

        ChatData.StartRecivePending()
    end)

    Event.Reg(self, "SYSTEM_NOTIFY", function(szName, nColorID, nFontType, nShowMode, bFilter, szData)
    end)

    Event.Reg(self, "OnRichTextSpriteAnim", function(nEmojiID, sprite)
        if not nEmojiID then return end
        if not sprite then return end
        if not IsUserData(sprite) then return end

        local tbEmojiConf = UIChatEmojiTab[nEmojiID]
        if not tbEmojiConf then
            return
        end

        local nSpriteAnimID = tbEmojiConf.nSpriteAnimID
        UIHelper.SetScale(sprite, 0.5, 0.5)
        UIHelper.PlaySpriteFrameAnimtion(sprite, nSpriteAnimID)
    end)

    Event.Reg(self, EventType.OnViewOpen, function(nViewID)
        if nViewID == VIEW_ID.PanelChatSocial then
            self.bChatViewIsOpen = true
            Event.Dispatch(EventType.SetNpcHeadBallonVisible, false)
        end
    end)

    Event.Reg(self, EventType.OnViewClose, function(nViewID)
        if nViewID == VIEW_ID.PanelChatSocial then
            self.bChatViewIsOpen = false
            Event.Dispatch(EventType.SetNpcHeadBallonVisible, true)
        end
    end)

    Event.Reg(self, EventType.OnChatViewChannelChanged, function(szUIChannel)
        self.szChatViewUIChannel = szUIChannel
    end)

    Event.Reg(self, "GLOBAL_ROOM_NOTIFY", function(nResultCode, szRoomID)
        if nResultCode == GLOBAL_ROOM_RESULT_CODE.SUCCESS then
            if RoomData.IsHaveRoom() then
                -- 切房间频道
                ChatData.SetSendChannelID(nil, PLAYER_TALK_CHANNEL.ROOM)
            else
                -- 切房间频道
                ChatData.SetSendChannelID(nil, ChatData.GetSendChannelID())
            end
        end
    end)

    Event.Reg(self, "GLOBAL_ROOM_CREATE", function(nResultCode, szRoomID)
        if nResultCode == GLOBAL_ROOM_RESULT_CODE.SUCCESS then
			-- 切房间频道
            ChatData.SetSendChannelID(nil, PLAYER_TALK_CHANNEL.ROOM)
        end
    end)

    Event.Reg(self, "LOADING_END", function()
        self.nBulletMapType = nil
        local player = GetClientPlayer()
        if player then
            -- 弹幕：获取当前地图的弹幕配置
            local hScene = player.GetScene()
            if hScene and hScene.nType == MAP_TYPE.DUNGEON then
                self.nBulletMapID = hScene.dwMapID
                RemoteCallToServer("On_Danmu_GetDanmuUnlockInfo")
            end
        end

        ChatData.ShowBulletView()

	    if not g_pClientPlayer or GetClientTeam().nGroupNum <= 1 then
            return
	    end

        local scene = g_pClientPlayer.GetScene()
        local bIsInDungeon = scene and scene.nType == MAP_TYPE.DUNGEON
        local bIsCrossing = CrossMgr.IsCrossing()
	    if bIsInDungeon or bIsCrossing then -- 秘境或者跨服
            -- 切团队频道
            ChatData.SetSendChannelID(nil, PLAYER_TALK_CHANNEL.RAID)
        end
    end)

    -- 弹幕：服务器下发地图弹幕配置
    Event.Reg(self, "ON_UPDATE_DANMAKU_BASE", function(dwMapID, nType, tFont, tColor, tMode)
        if not dwMapID then
            return
        end
        self.tbBulletMap[dwMapID] = nType
        if dwMapID == self.nBulletMapID then
            self.nBulletMapType = nType
        end
        if nType and tFont and tColor and tMode then
            self.tbBulletBase[nType] = {
                tFont = tFont,
                tColor = tColor,
                tMode = tMode,
            }
        end
        ChatData.ShowBulletView()
    end)

    Event.Reg(self, "SYNC_ROLE_DATA_END", function ()
        if Storage.Chat.nVersion and Storage.Chat.nVersion < ChatSetting.nVersion and ChatSetting.nVersion == 11 then
            ChatData.ResetChatSettingConfig()
        end
    end)

    Event.Reg(self, EventType.OnChatBulletSettingUpdate, function()
        ChatData.ShowBulletView()
    end)
end

function ChatData.UnInit()

end

function ChatData.InitData()
    for k, v in ipairs(UIChatTab) do
        self.tbUIChannelToConfMap[v.szUIChannel] = v
        self.tbUIChannelToMaxCountMap[v.szUIChannel] = v.nMaxCacheCount
    end

    for k, v in ipairs(UIChatDisplayFlagTab) do
        for _, nChannelID in ipairs(v.tbChannelIDs) do
            self.tbChannelIDToFlagConfMap[nChannelID] = v
        end
    end

    for k, v in ipairs(ChatSetting) do
        if IsTable(v) and v.bSettable then
            self.tbSettingConfigMap[v.szUIChannel] = {}
            for _, oneGroup in ipairs(v.tbGroupList) do
                self.tbSettingConfigMap[v.szUIChannel][oneGroup.szType] = {}
                self.tbSettingConfigMap[v.szUIChannel][oneGroup.szType].nVersion = oneGroup.nVersion
                for _, oneChannel in ipairs(oneGroup.tbChannelList) do
                    self.tbSettingConfigMap[v.szUIChannel][oneGroup.szType][oneChannel.szName] = oneChannel.bDefaultSelect
                end

                if v.szUIChannel == UI_Chat_Channel.AutoChat then
                    self.tbSettingConfigMap[v.szUIChannel][oneGroup.szType][1] = oneGroup.szDefaultText
                    self.tbSettingConfigMap[v.szUIChannel][oneGroup.szType][2] = oneGroup.tbApplyChannel
                end
            end
        end
    end
    self.tbSettingRuntimeMap = Lib.copyTab(self.tbSettingConfigMap)

    self.Reset()
    self.InitSettings()
end

function ChatData.Reset()
    self.bShowMXChnl = true -- 默认显示萌新频道
    self.nLastRecvTime = nil
    self.tbWhisperList = {}
    self.tbWhisperDataMap = {}

    self.tbChatData = {}
    self.tbWhisperUnreadMap = {}

    self.tbChannelSendTimeMap = {}

    ChatData.ClearChatInputText()
end

function ChatData.InitSettings()
    self.tbRecvChannelMap = {}
    self.tbSystemRewardMap = {}
    self.tbSystemFilterKeyWords = {}
    self.tbNpcStoryChannleMap = {}
    self.tbFightMsgMap = {}

    self.tbActionChannelList = {}
    self.tbHintReciveChannelMap = {}

    self.nOpenDisturbTime = nil

    local tbRecvRelocateMap = {}

    if ChatSetting.nVersion == 11 then
        --ChatData.ResetChatSettingConfig()
    elseif Storage.Chat.nVersion ~= ChatSetting.nVersion then
        for k, v in pairs(Storage.Chat or {}) do
            if IsTable(v) then
                Storage.Chat[k] = {}
            end
        end

        Storage.Chat.tbUIChannelNickName = {}
        Storage.Chat.nVersion = ChatSetting.nVersion
        Storage.Chat.Flush()
    end

    for szUIChannel, tbChannels in pairs(self.tbSettingRuntimeMap) do
        for szType, tbTypes in pairs(tbChannels) do
            local bNeedUpdateStorage = false
            for szName, bVal in pairs(tbTypes) do
                if Storage.Chat[szUIChannel] and szName ~= "nVersion" then
                    if Storage.Chat[szUIChannel][szType] then
                        local nStorageVersion = Storage.Chat[szUIChannel][szType].nVersion or 0
                        local nRuntimeVersion = self.tbSettingRuntimeMap[szUIChannel][szType].nVersion or 0

                        if nStorageVersion >= nRuntimeVersion then
                            if Storage.Chat[szUIChannel][szType][szName] ~= nil then
                                self.tbSettingRuntimeMap[szUIChannel][szType][szName] = Storage.Chat[szUIChannel][szType][szName]
                            end
                        else
                            bNeedUpdateStorage = true
                        end
                    end
                end
            end

            if bNeedUpdateStorage then
                Storage.Chat[szUIChannel][szType] = self.tbSettingRuntimeMap[szUIChannel][szType]
                Storage.Chat.Flush()
            end
        end

        if szUIChannel == UI_Chat_Channel.AutoChat and Storage.Chat[UI_Chat_Channel.AutoChat] then
            -- 原自动喊话改为角色级储存，如果Storage.Chat中有的话会在第一个角色登录后转到该角色的Storage.Chat_AutoShout中
            for key, tbData in pairs(Storage.Chat[UI_Chat_Channel.AutoChat]) do
                Storage.Chat_AutoShout[key] = tbData
            end
            Storage.Chat[UI_Chat_Channel.AutoChat] = nil

            Storage.Chat_AutoShout.Flush()
            Storage.Chat.Flush()
        end
    end

    local _validate = function(tbRuntime, tbOneChannel)
        local bResult = tbRuntime[tbOneChannel.szName]
        return bResult
    end

    local nLen = #ChatSetting
    for i = nLen, 1, -1 do
        local tbOneSetting = ChatSetting[i]
        local szUIChannel = tbOneSetting.szUIChannel

        for _, nChannelID in ipairs(tbOneSetting.tbRecvChannelIDs or {}) do
            if not self.tbRecvChannelMap[nChannelID] then self.tbRecvChannelMap[nChannelID] = {} end
            self.tbRecvChannelMap[nChannelID][szUIChannel] = true
        end

        if tbOneSetting.bSettable then
            local tbRuntimeRecv = self.tbSettingRuntimeMap[szUIChannel][UI_Chat_Setting_Type.Recv]
            local tbRuntimeReward = self.tbSettingRuntimeMap[szUIChannel][UI_Chat_Setting_Type.Reward]
            local tbRuntimeFilter = self.tbSettingRuntimeMap[szUIChannel][UI_Chat_Setting_Type.Filter]
            local tbRuntimeHintRecive = self.tbSettingRuntimeMap[szUIChannel][UI_Chat_Setting_Type.HintRecive]
            local tbRuntimeAction = self.tbSettingRuntimeMap[szUIChannel][UI_Chat_Setting_Type.Action]
            local tbRuntimeDisturb = self.tbSettingRuntimeMap[szUIChannel][UI_Chat_Setting_Type.Whisper_Disturb]

            for _, tbOneGroup in ipairs(tbOneSetting.tbGroupList or {}) do
                if tbOneGroup.szType == UI_Chat_Setting_Type.Recv then
                    for _, v in ipairs(tbOneGroup.tbChannelList or {}) do
                        if _validate(tbRuntimeRecv, v) then
                            if not string.is_nil(v.szRelocateUIChannel) then
                                if not tbRecvRelocateMap[v.szRelocateUIChannel] then
                                    tbRecvRelocateMap[v.szRelocateUIChannel] = {}
                                end
                                table.insert(tbRecvRelocateMap[v.szRelocateUIChannel], szUIChannel)
                            else
                                for _, nOneChannelID in ipairs(v.tbChannelIDs or {}) do
                                    if not self.tbRecvChannelMap[nOneChannelID] then self.tbRecvChannelMap[nOneChannelID] = {} end
                                    self.tbRecvChannelMap[nOneChannelID][szUIChannel] = true

                                    if szUIChannel == UI_Chat_Channel.NPCStory then
                                        self.tbNpcStoryChannleMap[nOneChannelID] = true
                                    end
                                end
                            end
                        end
                    end
                elseif tbOneGroup.szType == UI_Chat_Setting_Type.Reward then
                    for _, v in ipairs(tbOneGroup.tbChannelList or {}) do
                        if _validate(tbRuntimeReward, v) then
                            self.tbSystemRewardMap[v.szMsg] = true
                        end
                    end
                elseif tbOneGroup.szType == UI_Chat_Setting_Type.Filter then
                    for _, v in ipairs(tbOneGroup.tbChannelList or {}) do
                        if not _validate(tbRuntimeFilter, v) then
                            table.insert_tab(self.tbSystemFilterKeyWords, v.tbKeyWords)
                        end
                    end
                elseif tbOneGroup.szType == UI_Chat_Setting_Type.Fight_Others or
                        tbOneGroup.szType == UI_Chat_Setting_Type.Fight_Party or
                        tbOneGroup.szType == UI_Chat_Setting_Type.Fight_Self or
                        tbOneGroup.szType == UI_Chat_Setting_Type.Fight_Npc or
                        tbOneGroup.szType == UI_Chat_Setting_Type.Fight_Other then

                    local tbRunTime = self.tbSettingRuntimeMap[szUIChannel][tbOneGroup.szType]
                    for _, v in ipairs(tbOneGroup.tbChannelList or {}) do
                        if _validate(tbRunTime, v) then
                            self.tbFightMsgMap[v.szMsg] = true
                        end
                    end
                elseif tbOneGroup.szType == UI_Chat_Setting_Type.HintRecive then
                    for _, v in ipairs(tbOneGroup.tbChannelList or {}) do
                        if _validate(tbRuntimeHintRecive, v) then
                            for k, v in ipairs(v.tbChannelIDs or {}) do
                                self.tbHintReciveChannelMap[v] = true
                            end
                        end
                    end
                elseif tbOneGroup.szType == UI_Chat_Setting_Type.Action then
                    for _, v in ipairs(tbOneGroup.tbChannelList or {}) do
                        if _validate(tbRuntimeAction, v) then
                            table.insert(self.tbActionChannelList, v.szUIChannel)
                        end
                    end
                elseif tbOneGroup.szType == UI_Chat_Setting_Type.Whisper_Disturb then
                    for _, v in ipairs(tbOneGroup.tbChannelList or {}) do
                        if _validate(tbRuntimeDisturb, v) then
                            self.nOpenDisturbTime = GetCurrentTime()
                        end
                    end
                end
            end
        end
    end

    -- 处理接收频道的重定向问题
    for szFromUIChannel, tbToUIChannelList in pairs(tbRecvRelocateMap) do
        for _, szToUIChannel in ipairs(tbToUIChannelList) do
            for nChannelID, tbOneUIChannel in pairs(self.tbRecvChannelMap) do
                if table.contain_key(tbOneUIChannel, szFromUIChannel) then
                    tbOneUIChannel[szToUIChannel] = true
                end
            end
        end
    end

    return
end

function ChatData.StartRecivePending()
    if not RECIVE_DELAY or RECIVE_DELAY <= 0 then
        ChatData.HandleRecivePending()
        return
    end

    if self.bRecivePending then
        return
    end

    self.nRecivePendingTimerID = Timer.AddCycle(self, RECIVE_DELAY, function()
        ChatData.HandleRecivePending()
    end)

    self.bRecivePending = true
end

function ChatData.StopRecivePending()
    if not self.bRecivePending then
        return
    end

    Timer.DelTimer(self, self.nRecivePendingTimerID)
    self.bRecivePending = false
end

function ChatData.HandleRecivePending()
    local nLen = #self.tbRecivePendingList
    if nLen <= 0 then
        ChatData.StopRecivePending()
        return
    end

    local tbOneData = table.remove(self.tbRecivePendingList, 1)
    local szType = tbOneData._szChatType

    if szType == "PLAYER_CHAT" then
        local nChannel, dwTalkerID, szName, dwTitleID = tbOneData[1], tbOneData[2], tbOneData[3], tbOneData[4]
        local bGMFlag, dwFakeFellowPetTemplateID, nColourID, nFontType = tbOneData[5], tbOneData[6], tbOneData[7], tbOneData[8]
        local nShowMode, nSourceType, szGlobalID, dwMiniAvatarID = tbOneData[9], tbOneData[10], tbOneData[11], tbOneData[12]
        local dwForceID, nLevel, nCamp, nRoleType = tbOneData[13], tbOneData[14], tbOneData[15], tbOneData[16]

        -- 检查
        if not self.RecvCheck(dwTalkerID, nChannel, szName, szGlobalID) then
            return
        end

        local bEcho = (nChannel == PLAYER_TALK_CHANNEL.WHISPER and dwTalkerID == g_pClientPlayer.dwID)
        local tbTalkData = g_pClientPlayer.GetChat(nChannel, dwTalkerID) or {}
        szName = GBKToUTF8(szName)

        local szContent, szOriginContent, tbMsg, bBeCalled = self.Parse(dwTalkerID, nChannel, bEcho, szName,
            false, false, bGMFlag, false, dwTitleID, dwFakeFellowPetTemplateID,
            nColourID, nFontType, nShowMode, nSourceType, szGlobalID, tbTalkData
        )

        local tbContent = { szContent, szOriginContent, tbMsg, bBeCalled, nSourceType, nColourID, nFontType, nShowMode}
        self.Append(tbContent, dwTalkerID, nChannel, bEcho, szName, false, false, bGMFlag, false, dwTitleID, dwFakeFellowPetTemplateID, dwMiniAvatarID, dwForceID, nLevel, nCamp, nRoleType, szGlobalID)
    elseif szType == "PLAYER_TALK" then
        local dwTalkerID, nChannel, bEcho, szName = tbOneData[1], tbOneData[2], tbOneData[3], tbOneData[4]
        local bOnlyShowBallon, bSecurity, bGMAccount, bCheater = tbOneData[5], tbOneData[6], tbOneData[7], tbOneData[8]
        local dwTitleID, byVIPType, nVIPLevel, dwIdePetTemplateID = tbOneData[9], tbOneData[10], tbOneData[11], tbOneData[12]
        local szData, bFilter = tbOneData[13], tbOneData[14]

        -- 检查
        if not self.RecvCheck(dwTalkerID, nChannel, szName, nil) then
            return
        end

        szName = GBKToUTF8(szName)
        local tTalkData = ParseTalkData(szData, false) or {}
        local szContent, szOriginContent, tbMsg, bBeCalled = self.Parse(dwTalkerID, nChannel, bEcho, szName,
            bOnlyShowBallon, bSecurity, bGMAccount,
            bCheater, dwTitleID, dwIdePetTemplateID,
            nil, nil, nil, nil, nil, tTalkData
        )

        local tbContent = { szContent, szOriginContent, tbMsg, bBeCalled, nil, nil, nil, nil }
        self.Append(tbContent, dwTalkerID, nChannel, bEcho, szName, bOnlyShowBallon, bSecurity, bGMAccount, bCheater, dwTitleID, dwIdePetTemplateID)
    end
end

function ChatData.StartAppendPending()
    if not APPEND_DELAY or APPEND_DELAY <= 0 then
        ChatData.HandleAppendPending()
        return
    end

    if self.bAppendPending then
        return
    end

    self.nAppendPendingTimerID = Timer.AddCycle(self, APPEND_DELAY, function()
        ChatData.HandleAppendPending()
    end)

    self.bAppendPending = true
end

function ChatData.StopAppendPending()
    if not self.bAppendPending then
        return
    end

    Timer.DelTimer(self, self.nAppendPendingTimerID)
    self.bAppendPending = false
end

function ChatData.HandleAppendPending()
    local nLen = #self.tbAppendPendingList
    if nLen <= 0 then
        ChatData.StopAppendPending()
        return
    end

    local tbOneData = table.remove(self.tbAppendPendingList, 1)
    local szContent, dwTalkerID, nChannel, bEcho = tbOneData[1], tbOneData[2], tbOneData[3], tbOneData[4]
    local szName, bOnlyShowBallon, bSecurity, bGMAccount = tbOneData[5], tbOneData[6], tbOneData[7], tbOneData[8]
    local bCheater, dwTitleID, dwIdePetTemplateID, dwMiniAvatarID = tbOneData[9], tbOneData[10], tbOneData[11], tbOneData[12]
    local dwForceID, nLevel, nCamp, nRoleType, szGlobalID = tbOneData[13], tbOneData[14], tbOneData[15], tbOneData[16], tbOneData[17]
    local bTongMsg, bRookieGM = tbOneData[18], tbOneData[19]

    local szOriginContent = nil
    local tbMsg           = nil
    local bBeCalled       = nil  -- 是否被点名
    local nSourceType     = nil
    local nShowMode       = nil
    local nFontType       = nil
    local nColourID       = nil
    if IsTable(szContent) then
        szOriginContent = szContent[2] or ""
        tbMsg           = szContent[3]
        bBeCalled       = szContent[4]
        nSourceType     = szContent[5]
        nColourID       = szContent[6]
        nFontType       = szContent[7]
        nShowMode       = szContent[8]

        szContent       = szContent[1] or ""
    else
        szOriginContent = szContent
    end

    if string.is_nil(szContent) then
        return
    end

    szContent = string.trim(szContent, "\n")

    -- NPC头顶
    if not self.bChatViewIsOpen and ChatData.IsNPCBalloonChannel(nChannel) then
        FireUIEvent("PLAYER_SAY", szOriginContent, dwTalkerID, nChannel)
        if bOnlyShowBallon then
            return
        end
    end

    local tbUIChannelMap = self.tbRecvChannelMap[nChannel]
    if not tbUIChannelMap then
        return
    end

    local nPrefabID = ChatData.GetPrefabID(g_pClientPlayer, nChannel, dwTalkerID, szGlobalID, szName, tbMsg)

    local tbTimeData = nil
    local nNow = GetCurrentTime()
    if self.nLastRecvTime then
        if nNow - self.nLastRecvTime > MAX_TIMESTAMP_INTERVAL and nChannel ~= PLAYER_TALK_CHANNEL.WHISPER then
            tbTimeData = {
                nChannel = nChannel,
                szContent = os.date("%H:%M", nNow), --os.date("%Y/%m/%d %H:%M:%S", nNow),
                nPrefabID = PREFAB_ID.WidgetChatTime,
                tbUIChannelMap = tbUIChannelMap,
                nTime = nNow,
            }
            self.nLastRecvTime = nNow
        end
    else
        self.nLastRecvTime = nNow
    end

    local tbData = {
        dwTalkerID = dwTalkerID, nChannel = nChannel, bEcho = bEcho, szName = szName,
        bOnlyShowBallon = bOnlyShowBallon, bSecurity = bSecurity, bGMAccount = bGMAccount, bCheater = bCheater,
        dwTitleID = dwTitleID, dwIdePetTemplateID = dwIdePetTemplateID, szContent = szContent, szOriginContent = szOriginContent,
        tbMsg = tbMsg, bBeCalled = bBeCalled, nPrefabID = nPrefabID, tbUIChannelMap = tbUIChannelMap,
        nTime = nNow, dwMiniAvatarID = dwMiniAvatarID, dwForceID = dwForceID, nLevel = nLevel,
        nCamp = nCamp, nRoleType = nRoleType, szGlobalID = szGlobalID, bTongMsg = bTongMsg, bRookieGM = bRookieGM,
        nSourceType = nSourceType, nColourID = nColourID, nFontType = nFontType, nShowMode = nShowMode,
    }

    for szUIChannel, _ in pairs(tbUIChannelMap) do
        self._insertToChatList(szUIChannel, tbData, tbTimeData)
    end

    -- 被点名后，在密聊发个消息
    if bBeCalled then
        self._insertToChatList(UI_Chat_Channel.Whisper, tbData)
    end

    if tbTimeData then
        Event.Dispatch(EventType.OnReceiveChat, tbTimeData)
    end

    if ChatData.IsBulletChannel(nChannel) then
        ChatData.AddToBulletDataList(tbData)
    end

    Event.Dispatch(EventType.OnReceiveChat, tbData)
end

function ChatData._insertToChatList(szUIChannel, tbData, tbTimeData)
    if not tbData then return end
    if not self.tbUIChannelToConfMap[szUIChannel] then return end
    local szName         = tbData.szName
    local dwTalkerID     = tbData.dwTalkerID
    local bIsFriend      = true
    local dwMiniAvatarID = tbData.dwMiniAvatarID
    local nRoleType      = tbData.nRoleType
    local dwForceID      = tbData.dwForceID
    local nLevel         = tbData.nLevel
    local nCamp          = tbData.nCamp
    local szGlobalID     = tbData.szGlobalID

    if not self.tbChatData[szUIChannel] then self.tbChatData[szUIChannel] = {} end
    local tbOneChatData = self.tbChatData[szUIChannel]
    -- 最大上限处理，超过就删除前面的
    local bIsWhisper = szUIChannel == UI_Chat_Channel.Whisper
    local nLen = 0
    if not bIsWhisper then nLen = #tbOneChatData end
    local nMaxPerChannel = self.tbUIChannelToMaxCountMap[szUIChannel]

    local bNeedRemoveHead = (nLen >= nMaxPerChannel) and ((not self.bChatViewIsOpen) or (szUIChannel ~= self.szChatViewUIChannel))
    if bNeedRemoveHead then
        table.remove(tbOneChatData, 1)
    end

    local nOpenDisturbTime = ChatData.CheckWhisperIsOpenDisturb()
    local bFriend = FellowshipData.IsFriend(szGlobalID)

    local bSamePlayer = false
    local szOldWhisperName = ""
    local nCenterID = UI_GetClientPlayerCenterID()
    local szCenterName = (nCenterID > 0) and GetCenterNameByCenterID(nCenterID) or ""
    szCenterName = UIHelper.GBKToUTF8(szCenterName)

    if bIsWhisper then
        PlaySound(SOUND.UI_SOUND, g_sound.Whisper)

        local szKey = szName
        if not tbOneChatData[szKey] then
            local bHasFind = false
            for k, v in pairs(tbOneChatData) do
                local szOldGolbalID = v[1] and v[1].szGlobalID
                local szOldName = v[1] and v[1].szName

                local tbSplit = string.split(k, "·")
                local tbSplitName = string.split(szName, "·")
                if #tbSplit > 1 and tbSplit[1] == szName and tbSplit[2] == szCenterName or #tbSplitName > 1 and tbSplitName[1] == k and tbSplitName[2] == szCenterName then --该玩家与自己同服且已存在于密聊列表
                    bSamePlayer = true
                    szOldWhisperName = k
                    szOldName = szOldWhisperName
                end

                if szGlobalID == szOldGolbalID and szGlobalID ~= UI_GetClientPlayerGlobalID() or bSamePlayer then
                    tbOneChatData[szKey] = v
                    for _, tbOneWhisperData in ipairs(tbOneChatData[szKey]) do
                        tbOneWhisperData.szName = szKey
                    end
                    tbOneChatData[szOldName] = nil
                    bHasFind = true
                    break
                end
            end

            if not bHasFind then
                tbOneChatData[szKey] = {}
            end
        end

        -- 密聊超了要删除
        nLen = #tbOneChatData[szKey]
        if nLen >= nMaxPerChannel then
            table.remove(tbOneChatData[szKey], 1)
        end

        if tbTimeData then
            table.insert(tbOneChatData[szKey], tbTimeData)
        end
        table.insert(tbOneChatData[szKey], tbData)

        if szGlobalID ~= UI_GetClientPlayerGlobalID() and not (nOpenDisturbTime and not bFriend) or bSamePlayer then
            local tbPlayerData

            if bSamePlayer then
                tbPlayerData = clone(ChatData.GetWhisperPlayerData(szOldWhisperName))
                if tbPlayerData then
                    tbPlayerData.szName = szName
                end
            else
                tbPlayerData = { szName = szName, dwTalkerID = dwTalkerID, bIsFriend = true,
                                    dwMiniAvatarID = dwMiniAvatarID, nRoleType = nRoleType,
                                    dwForceID = dwForceID, nLevel = nLevel, nCamp = nCamp,
                                    szGlobalID = szGlobalID}
            end

            if tbPlayerData then
                ChatData.AddWhisper(szName, tbPlayerData)
            end
        end
    else
        if tbTimeData then
            table.insert(tbOneChatData, tbTimeData)
        end
        if not (tbData.nChannel == PLAYER_TALK_CHANNEL.WHISPER and nOpenDisturbTime and not bFriend) then
            table.insert(tbOneChatData, tbData)
        end
    end
end

function ChatData.GetRuntimeData()
    return self.tbSettingRuntimeMap
end

function ChatData.SetRuntimeData(tbData)
    if table.is_empty(tbData) then return end
    self.tbSettingRuntimeMap = tbData
end

function ChatData.SetRuntimeDataByUIChannel(szUIChannel, tbData)
    if table.is_empty(tbData) then return end
    self.tbSettingRuntimeMap[szUIChannel] = tbData
end

function ChatData.SetRuntimeData_ByServer() -- 从服务器获取
    -- tbSettingRuntimeMap[szUIChannel][szType][szName]
    local bChanged = false
    for i, tbOneSetting in ipairs(ChatSetting) do
        local szUIChannel = tbOneSetting.szUIChannel
        local bEnable, szNickname, tbSaveData = Storage_Server.GetData("ChatSetting", i)
        if bEnable and tbSaveData then
            local tbOneRuntimeData = self.tbSettingRuntimeMap[szUIChannel]
            if tbOneSetting.bCanRename then
                ChatData.SetUIChannelNickName(szUIChannel, szNickname)
            end

            for j, tbOneGroupConf in ipairs(tbOneSetting.tbGroupList) do
                local szType = tbOneGroupConf.szType
                local tbOneData = tbOneRuntimeData[szType]
                for k, tbOneConf in ipairs(tbOneGroupConf.tbChannelList) do
                    local szName = tbOneConf.szName
                    local nIndex = ChatSetting.GetChannels2IndexTab()[szName]
                    if not nIndex then
                        LOG.ERROR("[Storage_Server] Unknown chat channel: " .. szName)
                    else
                        tbOneData[szName] = tbSaveData[nIndex]
                        bChanged = true
                    end
                end
            end
        end
    end

    if bChanged then
        Event.Dispatch(EventType.OnChatSettingSyncServerData)
    end
end

function ChatData.RecoverRuntimeData(szUIChannel)
    if string.is_nil(szUIChannel) then
        self.tbSettingRuntimeMap = Lib.copyTab(self.tbSettingConfigMap)
    else
        if self.tbSettingRuntimeMap[szUIChannel] then
            local tbOneConf = self.tbSettingConfigMap[szUIChannel]
            if tbOneConf then
                self.tbSettingRuntimeMap[szUIChannel] = tbOneConf
            end
        end
    end
end

function ChatData.SaveRuntimeData()
    for szUIChannel, v in pairs(self.tbSettingRuntimeMap or {}) do
        Storage.Chat[szUIChannel] = v
    end

    Storage.Chat.Flush()
    self:InitSettings()
end

function ChatData.SaveRuntimeData_ToServer(bNeedUpdateStorage)
    -- tbSettingRuntimeMap[szUIChannel][szType][szName]
    for i, tbOneSetting in ipairs(ChatSetting) do
        local tbSaveData = {}
        local tbOneRuntimeData = self.tbSettingRuntimeMap[tbOneSetting.szUIChannel]
        local szNickname = tbOneSetting.bCanRename and ChatData.GetUIChannelNickName(tbOneSetting.szUIChannel) or ""
        for j, tbOneGroupConf in ipairs(tbOneSetting.tbGroupList) do
            local szType = tbOneGroupConf.szType
            local tbOneData = tbOneRuntimeData[szType]
            for k, tbOneConf in ipairs(tbOneGroupConf.tbChannelList or {}) do
                local szName = tbOneConf.szName
                local nIndex = ChatSetting.GetChannels2IndexTab()[szName]
                if not nIndex then
                    LOG.ERROR("[Storage_Server] Unknown chat channel: " .. szName)
                else
                    tbSaveData[nIndex] = tbOneData[szName]
                end
            end
        end
        Storage_Server.SetData("ChatSetting", i, true, szNickname, tbSaveData)
    end
    if bNeedUpdateStorage then
        ChatData.SaveRuntimeData()
    end
end

function ChatData.SyncChatSetting()
    if not GameSettingData.GetNewValue(UISettingKey.SyncChatSetting) then
        return
    end

    local bSame, bEmpty = ChatData.CheckServerDifference()

    if bEmpty then
        self.SaveRuntimeData_ToServer(false)
        return
    end

    if bSame then
        return
    end

    local dialog = UIHelper.ShowSystemConfirm("本地聊天配置与服务器存在差异，是否使用服务器配置覆盖本地配置或保留本地配置并上传到服务器？", function()
        self.SetRuntimeData_ByServer()
    end)

    dialog:ShowOtherButton()
    dialog:SetOtherButtonClickedCallback(function()
        self.SaveRuntimeData_ToServer(true)
    end)

    dialog:SetConfirmButtonContent("使用服务器配置")
    dialog:SetCancelButtonContent("取消")
    dialog:SetOtherButtonContent("上传本地配置")
end

function ChatData.GetHintReciveChannelMap()
    return self.tbHintReciveChannelMap
end

-- 消息提醒是否显示2条
function ChatData.GetHintCountIsTow()
    local bResult = false

    if Storage.Chat[UI_Chat_Channel.Hint] then
        local tbHintCount = Storage.Chat[UI_Chat_Channel.Hint][UI_Chat_Setting_Type.HintCount]
        if tbHintCount then
            for k, v in pairs(tbHintCount) do
                if k == "双条提醒" then
                    bResult = v
                    break
                end
            end
        end
    end

    return bResult
end

function ChatData.CheckSystemChannelCanRecvReward(szMsg)
    return self.tbSystemRewardMap[szMsg]
end

function ChatData.CheckFightChannelCanRecvMsg(szMsg)
    return self.tbFightMsgMap[szMsg]
end

function ChatData.OnLogin()

end

function ChatData.OnFirstLoadEnd()

end

function ChatData.Send(nChannel, szReceiver, tbMsg)
    if not g_pClientPlayer then
        return
    end
    if not tbMsg then
        return
    end
    if szReceiver == nil then
        szReceiver = ""
    end

    if not ChatData.SendCheck(nChannel) then
        return
    end

    local bResult = Player_Talk(g_pClientPlayer, nChannel, szReceiver, tbMsg)

    -- 用于触发客户端成就尝试上报时机
    FireUIEvent("ON_USE_CHAT", nChannel)

    return bResult
end

function ChatData.Parse(dwTalkerID, nChannel, bEcho, szName, bOnlyShowBallon, bSecurity, bGMAccount, bCheater, dwTitleID, dwIdePetTemplateID, nColourID, nFontType, nShowMode, nSourceType, szGlobalID, tbTalkData)

    local t = nil
    local szMsg = ""
    local szPlainText = ""
    local szLeft = ""
    local player = GetClientPlayer()
    if not player then
        return
    end

    local bUsePlainTextOnly = false
    if nChannel == PLAYER_TALK_CHANNEL.NPC_SAY_TO_ID then
        bEcho = false
        nChannel = PLAYER_TALK_CHANNEL.NPC_NEARBY
        szPlainText = g_tStrings.tNpcSentence[arg2]
        szPlainText = self.PreProcessTalkData(dwTalkerID, szPlainText)
        bUsePlainTextOnly = true
    else
        -- 判断是否是背景通讯
        t = tbTalkData or player.GetTalkData()
        if not t then
            return
        end
        if IsBgMsg(t) then
        	return ProcessBgMsg(t, nChannel, dwTalkerID, szName, bEcho)
        end
    end

    if (not bUsePlainTextOnly) and self.IsCMDChannel(nChannel) then
		local bCMD = self.ParseCMD(t)
		if bCMD then
			return
		end
	end

    local szContent = ""
    local szOriginContent = ""
    local bBeCalled = false

    if not bUsePlainTextOnly then
        t = self.PreProcessTalkData(dwTalkerID, t)
        local nFaceCount = 0
        local func, tag, plain
        for k, v in ipairs(t) do
            --处理格式化文本
            if v.type == "emotion" then
                if v.id == 0 then
                    szLeft = g_tStrings.STR_FACE .. g_tStrings.STR_COLON
                elseif v.id ~= -1 then
                    local szAlign = ChatData.IsBulletChannel(nChannel) and " align='top'" or ""
                    local szEmoji = string.format("<img emojiid='%d' src='' width='30' height='30'%s/>", v.id, szAlign)
                    szContent = szContent .. szEmoji
                end
            else
                -- 关键词屏蔽
                if not APIHelper.IsSelf(dwTalkerID) then
                    if v.type == "eventlink" then
                        if string.find(v.linkinfo, "TeamBuild/") and WordBlockMgr.HasWordBlockedInChat(GBKToUTF8(v.name), nChannel) then
                            return
                        elseif AutoShoutForbidData.NeedToFilter(v.linkinfo, nChannel, false) then
                            return
                        end
                    end
                else
                    if v.type == "eventlink" then
                        if AutoShoutForbidData.NeedToFilter(v.linkinfo, nChannel, true) then
                            return
                        end
                    end
                end

                local bResult, szResult = ChatHelper.DecodeTalkData(v, dwTalkerID, nChannel)
                szContent = szContent .. szResult

                -- 点名功能
                if nChannel ~= PLAYER_TALK_CHANNEL.WHISPER and not ChatData.IsSystemChannel(nChannel) then
                    if not bBeCalled and v.type == "name" then
                        if g_pClientPlayer then
                            if dwTalkerID ~= g_pClientPlayer.dwID and v.name == g_pClientPlayer.szName then
                                bBeCalled = true
                            end
                        end
                    end
                end
            end
        end
        szMsg = szMsg .. GetFormatText(szLeft, szFont) .. szContent
        szMsg = szMsg .. GetFormatText("\n", szFont)
        szLeft = ""
    else
        szMsg = szMsg .. GetFormatText(szLeft .. szPlainText .. "\n", szFont)
        szLeft = ""
    end

    szContent = GBKToUTF8(szContent)
    szOriginContent = szContent

    if string.is_nil(szContent) then
        if t[1] and t[1].type == "voice" then -- 如果是语音消息 就特殊处理下
            szContent = " "
        else
            return
        end
    end

    -- 关键词屏蔽
    if not APIHelper.IsSelf(dwTalkerID) then
        if WordBlockMgr.HasWordBlockedInChat(szContent, nChannel) then
            return
        end
    end

    -- 系统消息弹中间
    if nChannel == PLAYER_TALK_CHANNEL.LOCAL_SYS then
        TipsHelper.ShowNormalTip(szContent, true)
    end

    -- NPC
    if self.IsSystemChannel(nChannel) and not string.is_nil(szName) then
        szContent = string.format("%s：%s", szName, szContent)
    end

    -- 过滤
    if self.IsSystemChannel(nChannel) and Global.IsThereKeyOfShielding(szContent) then
        -- TODO filter ?
        szContent = ""
    end

    return szContent, szOriginContent, t, bBeCalled
end

function ChatData.Append(szContent, dwTalkerID, nChannel, bEcho, szName, bOnlyShowBallon, bSecurity, bGMAccount, bCheater, dwTitleID, dwIdePetTemplateID, dwMiniAvatarID, dwForceID, nLevel, nCamp, nRoleType, szGlobalID, bTongMsg, bRookieGM)
    table.insert(self.tbAppendPendingList,
                {
                    szContent, dwTalkerID, nChannel, bEcho,
                    szName, bOnlyShowBallon, bSecurity, bGMAccount,
                    bCheater, dwTitleID, dwIdePetTemplateID, dwMiniAvatarID,
                    dwForceID, nLevel, nCamp, nRoleType, szGlobalID, bTongMsg, bRookieGM
                }
    )

    ChatData.StartAppendPending()
end

function ChatData.GetDataList(szUIChannel, szCurWhisper)
    if szUIChannel == UI_Chat_Channel.AINpc then
        local dwNpcId = ChatAINpcMgr.GetCurAINpcID()
        if dwNpcId then
            return ChatAINpcMgr.GetDataList(dwNpcId)
        end
    end

    if szUIChannel ~= UI_Chat_Channel.Whisper then
        if self.IsSearching() then
            if not self.tbSearchDataList then
                self.tbSearchDataList = {}
                for k, v in ipairs(self.tbChatData[szUIChannel] or {}) do
                    local szOriginContent = v.szOriginContent
                    if szOriginContent and string.find(szOriginContent, self.szSearchValue) then
                        table.insert(self.tbSearchDataList, v)
                    end
                end
            end
            return self.tbSearchDataList
        else
            return self.tbChatData[szUIChannel]
        end
    end

    if not szCurWhisper then
        return {}
    end

    if not self.tbChatData[szUIChannel] then
        return {}
    end

    local tbWhisper = self.tbChatData[szUIChannel][szCurWhisper]
    if not tbWhisper then
        -- 如果有跨服标记 临时做法，因为逻辑会将名字截断
        -- 比如这种名字：二服红队队长12@龙争虎斗·有人赴约 会截断成 二服红队队长12@龙争虎斗·有人赴
        -- 等后面统一改成 GlobalID 的形式

        local szTempName = self.tbWhisperNameToName and self.tbWhisperNameToName[szCurWhisper] or ""
        tbWhisper = self.tbChatData[szUIChannel][szTempName]
        if tbWhisper then
            return tbWhisper
        end

        local bHasCorssFlag = string.find(szCurWhisper, "·")
        if bHasCorssFlag then
            for k, v in pairs(self.tbChatData[szUIChannel]) do
                if string.find(k, "·") then
                    if string.find(szCurWhisper, k) then
                        tbWhisper = v
                        --self.tbChatData[szUIChannel][szCurWhisper] = v
                        --self.tbChatData[szUIChannel][k] = nil

                        if not self.tbWhisperNameToName then
                            self.tbWhisperNameToName = {}
                        end

                        self.tbWhisperNameToName[szCurWhisper] = k

                        break
                    end
                end
            end
        end
    end

    return tbWhisper
end

function ChatData.GetDataListLen(szUIChannel, szCurWhisper)
    local tbDataList = ChatData.GetDataList(szUIChannel, szCurWhisper)
    local nLen = tbDataList and #tbDataList or 0
    return nLen
end

function ChatData.GetOneData(szUIChannel, nIndex, szCurWhisper)
    local tbOneChannelData = ChatData.GetDataList(szUIChannel, szCurWhisper)
    if tbOneChannelData then
        return tbOneChannelData[nIndex]
    end
    return nil
end

function ChatData.PreProcessTalkData(dwID, data)
    if type(data) == "table" then
        for k, v in ipairs(data) do
            if v.type == "text" then
                v.text = string.gsub(v.text, "\n", "")
                local _, t = GWTextEncoder_EncodeTalkData(v.text)
                if t then
                    local szText = ""
                    for key, value in ipairs(t) do
                        if value.name == "text" then
                            szText = szText .. value.context
                        elseif value.name == "AT" then
                            local bFace = false
                            if value.attribute.face then
                                bFace = true
                            end
                            Character_PlayAnimation(dwID, GetClientPlayer().dwID, tonumber(value.attribute.actionid), bFace)
                        elseif value.name == "SD" then
                            Character_PlaySound(dwID, GetClientPlayer().dwID, value.attribute.soundid, false)
                        end
                    end
                    v.text = szText
                end
            end
        end
    else
        data = string.gsub(data, "\n", "")
        local _, t = GWTextEncoder_EncodeTalkData(data)
        if t then
            local szText = ""
            for key, value in ipairs(t) do
                if value.name == "text" then
                    szText = szText .. value.context
                elseif value.name == "AT" then
                    local bFace = false
                    if value.attribute.face then
                        bFace = true
                    end
                    Character_PlayAnimation(dwID, GetClientPlayer().dwID, tonumber(value.attribute.actionid), bFace)
                elseif value.name == "SD" then
                    Character_PlaySound(dwID, GetClientPlayer().dwID, value.attribute.soundid, false)
                end
            end
            data = szText
        end
    end
    return data
end



function ChatData.SendCheck(nChannel)
    local bResult = true

    -- 帮会频道禁言判断
    if nChannel == PLAYER_TALK_CHANNEL.TONG then
        if not TongData.CanSpeakAtChat() then
            OutputMessage("MSG_RED", "你所属头衔没有在帮会频道发言的权限!")
            bResult = false
        end
    end

    return bResult
end

-- 收到聊天后的检查，看是否能显示
function ChatData.RecvCheck(dwTalkerID, nChannel, szName, szGlobalID)
    if not g_pClientPlayer then
        return false
    end

    -- 竞技场检查，策划写的代码
    if not IsModeLimitChannel(g_pClientPlayer, dwTalkerID, nChannel) then
        return false
    end

    -- 判定PlayerID是否在垃圾信息过滤清单中
    if dwTalkerID ~= 0 and dwTalkerID ~= g_pClientPlayer.dwID then
        if IsSpamID(dwTalkerID) then
            return false
        end
    end

    -- 单向好友不接收到好友频道
    if nChannel == PLAYER_TALK_CHANNEL.FRIENDS then
        if szGlobalID and szName ~= g_pClientPlayer.szName and not FellowshipData.IsFriend(szGlobalID) then
            return false
        end
    end

    -- NPC剧情频道检查
    if not ChatData.NPCStoryRecvCheck(nChannel) then
        return false
    end

    return true
end

function ChatData.GetUIChannelList()
    local tbRetList = {}

    for k, v in ipairs(UIChatTab) do
        if ChatData.IsUIChannelVisible(v.szUIChannel) then
            table.insert(tbRetList, v)
        end
    end

    return tbRetList
end

function ChatData.GetCellPadding(nPrefabID)
    if nPrefabID == PREFAB_ID.WidgetChatPlayerVoice or nPrefabID == PREFAB_ID.WidgetChatSelfVoice then
        return 66
    elseif nPrefabID == PREFAB_ID.WidgetChatPlayer or nPrefabID == PREFAB_ID.WidgetChatSelf then
        return 76
    elseif nPrefabID == PREFAB_ID.WidgetChatSystem then
        return 10
    elseif nPrefabID == PREFAB_ID.WidgetChatTime then
        return 0
    elseif nPrefabID == PREFAB_ID.WidgetChatMainCityCell or nPrefabID == PREFAB_ID.WidgetChatMainCityCell2 then
        return 4.8
    else
        return 0
    end
end

function ChatData.GetCellHeight(nPrefabID)
    if nPrefabID == PREFAB_ID.WidgetChatTime then
        return 50
    end
    return nil
end

function ChatData.AddWhisper(szName, tbData, bRecent)
    if string.is_nil(szName) then
        return
    end

    if tbData and not tbData.szGlobalID then
        tbData.szGlobalID = ChatRecentMgr.GetRecentGlobalIDByName(szName)
    end

    local szGlobalID = tbData and tbData.szGlobalID or ""

    local bWhisperNameChanged = false
    local szWhisperOldName = ""
    for k, v in pairs(self.tbWhisperDataMap) do
        -- 如果GlobalID一样，但是名字不一样的，就先把老的删掉
        if szGlobalID == v.szGlobalID and szName ~= v.szName then
            szWhisperOldName = v.szName
            table.remove_value(self.tbWhisperList, szWhisperOldName)
            self.tbWhisperDataMap[szWhisperOldName] = nil
            --ChatData.RemoveFromWhisperUnread(szWhisperOldName)
            ChatRecentMgr.ClearNewMsg(szGlobalID)

            bWhisperNameChanged = true
            break
        end
    end

    local bResult = table.remove_value(self.tbWhisperList, szName)
    table.insert(self.tbWhisperList, 1, szName)

    if (bRecent and (not Storage.ChatWhisper.bInit or ChatRecentMgr.GetOffLineMsgCount(szGlobalID) > 0)) or not bRecent then
        local bResult = table.remove_value(Storage.ChatWhisper.tbPlayerList, szName)
        table.insert(Storage.ChatWhisper.tbPlayerList, 1, szName)

        Storage.ChatWhisper.Flush()
    end

    self.tbWhisperDataMap[szName] = tbData or {["szName"] = szName}

    local dwTalkerID = tbData and tbData.dwTalkerID
    --if g_pClientPlayer and dwTalkerID ~= g_pClientPlayer.dwID then
    --    ChatData.AddToWhisperUnread(szName)
    --end

    if bWhisperNameChanged then
        Event.Dispatch(EventType.OnChatWhisperNameChanged, szWhisperOldName, szName)
    end
end

function ChatData.RemoveWhisper(szName)
    if string.is_nil(szName) then
        return
    end

    for k, v in ipairs(self.tbWhisperList) do
        if v == szName then
            table.remove(self.tbWhisperList, k)
            break
        end
    end

    for k, v in ipairs(Storage.ChatWhisper.tbPlayerList) do
        if v == szName then
            table.remove(Storage.ChatWhisper.tbPlayerList, k)
            break
        end
    end

    Storage.ChatWhisper.Flush()

    local tbData = self.GetWhisperPlayerData(szName)
    if not tbData then return end
    ChatRecentMgr.ClearNewMsg(tbData.szGlobalID)

    self.tbWhisperDataMap[szName] = nil

    --ChatData.RemoveFromWhisperUnread(szName)

end

function ChatData.GetWhisperPlayerIDList()
    return self.tbWhisperList
end

function ChatData.GetWhisperPlayerData(szName)
    if string.is_nil(szName) then
        return
    end

    return self.tbWhisperDataMap[szName]
end

function ChatData.AddToWhisperUnread(szWhisperName)
    self.tbWhisperUnreadMap[szWhisperName] = true
    Event.Dispatch(EventType.OnChatWhisperUnreadAdd, szWhisperName)
end

function ChatData.RemoveFromWhisperUnread(szWhisperName)
    self.tbWhisperUnreadMap[szWhisperName] = nil
    Event.Dispatch(EventType.OnChatWhisperUnreadRemove, szWhisperName)
end

function ChatData.HasWhisperUnread(szWhisperName)
    return self.tbWhisperUnreadMap[szWhisperName]
end

function ChatData.GetWhisperUnreadMap(szWhisperName)
    return self.tbWhisperUnreadMap
end

function ChatData.HasWhisperUnreadRedPoint()
    local bResult = false
    local tbMap = ChatData.GetWhisperUnreadMap()
    local nLen = table.get_len(tbMap)

    bResult = nLen > 0
    return bResult, nLen
end

function ChatData.GetPrefabID(player, nChannel, dwTalkerID, szGlobalID, szName, tbMsg)
    local nPrefabID = PREFAB_ID.WidgetChatSystem
    if not self.IsSystemChannel(nChannel) and player then
        if IsNumber(dwTalkerID) and dwTalkerID > 0 and not string.is_nil(szName) then
            local bIsSelf = (dwTalkerID == player.dwID)
            if not string.is_nil(szGlobalID) then
                bIsSelf = szGlobalID == UI_GetClientPlayerGlobalID()
            end
            local bIsVoice = tbMsg and tbMsg[1] and (tbMsg[1].type == "voice")
            if bIsVoice then
                nPrefabID = bIsSelf and PREFAB_ID.WidgetChatSelfVoice or PREFAB_ID.WidgetChatPlayerVoice
            else
                nPrefabID = bIsSelf and PREFAB_ID.WidgetChatSelf or PREFAB_ID.WidgetChatPlayer
            end
        end
    end

    return nPrefabID
end

function ChatData.IsSystemChannel(nChannel)
    if PLAYER_TALK_CHANNEL.FACE == nChannel or
            PLAYER_TALK_CHANNEL.GM_MESSAGE == nChannel or
            PLAYER_TALK_CHANNEL.LOCAL_SYS == nChannel or
            PLAYER_TALK_CHANNEL.GLOBAL_SYS == nChannel or
            PLAYER_TALK_CHANNEL.GM_ANNOUNCE == nChannel or
            PLAYER_TALK_CHANNEL.TO_TONG_GM_ANNOUNCE == nChannel or
            PLAYER_TALK_CHANNEL.TO_PLAYER_GM_ANNOUNCE == nChannel or
            PLAYER_TALK_CHANNEL.NPC_NEARBY == nChannel or
            PLAYER_TALK_CHANNEL.NPC_PARTY == nChannel or
            PLAYER_TALK_CHANNEL.NPC_SENCE == nChannel or
            PLAYER_TALK_CHANNEL.NPC_WHISPER == nChannel or
            PLAYER_TALK_CHANNEL.NPC_SAY_TO == nChannel or
            PLAYER_TALK_CHANNEL.NPC_YELL_TO == nChannel or
            PLAYER_TALK_CHANNEL.NPC_FACE == nChannel or
            PLAYER_TALK_CHANNEL.NPC_SAY_TO_ID == nChannel or
            PLAYER_TALK_CHANNEL.NPC_SAY_TO_CAMP == nChannel or
            PLAYER_TALK_CHANNEL.STORY_NPC == nChannel or
            PLAYER_TALK_CHANNEL.STORY_NPC_YELL == nChannel or
            PLAYER_TALK_CHANNEL.STORY_NPC_WHISPER == nChannel or
            PLAYER_TALK_CHANNEL.STORY_NPC_SAY_TO == nChannel or
            PLAYER_TALK_CHANNEL.STORY_NPC_YELL_TO == nChannel or
            PLAYER_TALK_CHANNEL.STORY_PLAYER == nChannel or
            PLAYER_TALK_CHANNEL.TONG_SYS == nChannel or
            PLAYER_TALK_CHANNEL.MENTOR == nChannel or
            PLAYER_TALK_CHANNEL.DEBUG_THREAT == nChannel or
            PLAYER_TALK_CHANNEL.SYSTEM_NOTICE == nChannel then

        return true
    end

    return false
end

function ChatData.IsGMChannel(nChannel)
    local bGMChannel = PLAYER_TALK_CHANNEL.GLOBAL_SYS == nChannel or
                        PLAYER_TALK_CHANNEL.GM_ANNOUNCE == nChannel or
                        PLAYER_TALK_CHANNEL.TO_TONG_GM_ANNOUNCE == nChannel or
                        PLAYER_TALK_CHANNEL.TO_PLAYER_GM_ANNOUNCE == nChannel

    return bGMChannel
end

function ChatData.IsBulletChannel(nChannel)
    if self.bBulletDebug then return true end
    local bBulletChannel = PLAYER_TALK_CHANNEL.JJC_BULLET_SCREEN == nChannel or
                        PLAYER_TALK_CHANNEL.CAMP_FIGHT_BULLET_SCREEN == nChannel or
                        PLAYER_TALK_CHANNEL.DUNGEON_BULLET_SCREEN == nChannel

    return bBulletChannel
end

function ChatData.IsNPCBalloonChannel(nChannel)
    local bShowPlayerBubble = GameSettingData.GetNewValue(UISettingKey.ShowPlayerDialogueBubble)
    local bShowNPCBubble = GameSettingData.GetNewValue(UISettingKey.ShowNPCDialogueBubble)

    if bShowPlayerBubble and (nChannel == PLAYER_TALK_CHANNEL.NEARBY or nChannel == PLAYER_TALK_CHANNEL.TEAM)    --新增一个近聊玩家头顶显示
    then
        return true
    end

    if bShowNPCBubble and (nChannel == PLAYER_TALK_CHANNEL.NPC_NEARBY
            or nChannel == PLAYER_TALK_CHANNEL.STORY_NPC
            or nChannel == PLAYER_TALK_CHANNEL.STORY_NPC_YELL
            or nChannel == PLAYER_TALK_CHANNEL.STORY_NPC_WHISPER
            or nChannel == PLAYER_TALK_CHANNEL.STORY_NPC_SAY_TO
            or nChannel == PLAYER_TALK_CHANNEL.NPC_SENCE
            or nChannel == PLAYER_TALK_CHANNEL.STORY_NPC_YELL_TO
            or nChannel == PLAYER_TALK_CHANNEL.STORY_PLAYER)
    then
        return true
    end

    return false
end

function ChatData.GetEmojiAllGroupInfoMap()
    if not ChatData.tbGroupMap then
        ChatData.tbGroupMap = {}
        for _, v in ipairs(UIChatEmojiTab) do
            local nGroupID = v.nGroupID
            if not ChatData.tbGroupMap[nGroupID] then
                ChatData.tbGroupMap[nGroupID] = {}
            end

            table.insert(ChatData.tbGroupMap[nGroupID], v)
        end
    end

    return ChatData.tbGroupMap
end

function ChatData.GetEmojiOneGroupInfo(nGroupID)
    local tbResult = {}
    if nGroupID == -1 then
        -- 收藏
        local tbFavorites = g_pClientPlayer and g_pClientPlayer.GetAllEmotionInFavorites() or {}
        for k, nEmojiID in ipairs(tbFavorites) do
            table.insert(tbResult, UIChatEmojiTab[nEmojiID])
        end

        table.insert(tbResult, 1, { nID = -1, szName = "收藏", nGroupID = -1, nSpriteAnimID = -1 })
    else
        local tbGroupMap = ChatData.GetEmojiAllGroupInfoMap()
        if tbGroupMap then
            tbResult = tbGroupMap[nGroupID]
        end
    end
    return tbResult or {}
end

function ChatData.GetChatEmojiGroupList(bShowFavorite)
    local tbResult = {}
    local tbEmojiGroupIDList = g_pClientPlayer.GetEmotionPackageList()
    tbEmojiGroupIDList = Lib.ReverseTable(tbEmojiGroupIDList)
    for _, nGroupID in ipairs(tbEmojiGroupIDList or {}) do
        local tbOneGroupConf = UIChatEmojiGroupTab[nGroupID]
        local bDisable = ChatData.CheckEmojiGroupDisable(nGroupID)
        if tbOneGroupConf and not bDisable then
            table.insert(tbResult, tbOneGroupConf)
        end
    end

    if bShowFavorite then
        table.insert(tbResult, 2,
                { nGroupID = -1, szGroupName = "收藏", szGroupIcon = "UIAtlas2_Chat_Chat1_icon_expression_02" })
        table.insert(tbResult, 3,
                { nGroupID = nil, szGroupName = "语言", szGroupIcon = "UIAtlas2_Chat_Chat1_icon_expression_05" })
    end

    return tbResult
end

function ChatData.SetFavoriteEmoji(nEmojiID, bFavorite)
    if not g_pClientPlayer then
        return
    end

    if not IsNumber(nEmojiID) then
        return
    end

    if bFavorite then
        g_pClientPlayer.AddEmotionToFavorites(nEmojiID)
    else
        g_pClientPlayer.RemoveEmotionFromFavorites(nEmojiID)
    end
end

function ChatData.CheckIsFavoriteEmoji(nEmojiID)
    if not g_pClientPlayer then
        return
    end

    if not IsNumber(nEmojiID) then
        return
    end

    return g_pClientPlayer.IsEmotionInFavorites(nEmojiID)
end

function ChatData.GetAllEmotionInFavorites()
    return g_pClientPlayer and g_pClientPlayer.GetAllEmotionInFavorites() or {}
end

function ChatData.GetEmotionFavoritesMaxCount()
    return g_pClientPlayer and g_pClientPlayer.GetEmotionFavoritesMaxCount() or 0
end

-- 收藏是否超出上限
function ChatData.CheckIsFavoriteOverLimit()
    local nCollected = #ChatData.GetAllEmotionInFavorites()
    local nTotal = ChatData.GetEmotionFavoritesMaxCount()
    return nCollected >= nTotal
end

function ChatData.CheckEmojiGroupDisable(nGroupID)
    return CHAT_DISABLE_EMOJI_GROUP[nGroupID]
end

function ChatData.StartSearch(szSearchValue)
    if string.is_nil(szSearchValue) then
        self.StopSearch()
        return
    end

    self.tbSearchDataList = nil
    self.szSearchValue = szSearchValue
end

function ChatData.StopSearch()
    self.szSearchValue = nil
    self.tbSearchDataList = nil
end

function ChatData.IsSearching()
    return not string.is_nil(self.szSearchValue)
end

function ChatData.GetEmojiConfByName(szEmojiName)
    local tbConf = nil

    if not self.tbMapNameToEmoji then
        self.tbMapNameToEmoji = {}
    end

    tbConf = self.tbMapNameToEmoji[szEmojiName]

    if not tbConf then
        for k, v in ipairs(UIChatEmojiTab) do
            if v.szName == szEmojiName then
                tbConf = v
                self.tbMapNameToEmoji[szEmojiName] = tbConf
                break
            end
        end
    end

    return tbConf
end

function ChatData.GetChatFlagConfByChannelID(nChannelID)
    if nChannelID == PLAYER_TALK_CHANNEL.BATTLE_FIELD_SIDE and not BattleFieldData.IsInZombieBattleFieldMap() then
        return self.tbChannelIDToFlagConfMap[PLAYER_TALK_CHANNEL.BATTLE_FIELD]
    end
    return self.tbChannelIDToFlagConfMap[nChannelID]
end

function ChatData.GetChatConfByUIChannel(szUIChannel)
    return self.tbUIChannelToConfMap[szUIChannel]
end

function ChatData.ConvertRichTextToEditText(szContent)
    local szMsg = ""

    -- 为了保证 [表情]文本[表情] 这种复制不了的问题 所以这里加了个 <div> </div> 标签
    szContent = string.format("<div>%s</div>", szContent)

    local tbParse = labelparser.parse(szContent, true)
    if tbParse then
        for k, v in ipairs(tbParse) do
            if v.labelname == "img" or v.labelname == "<img>" or string.match(v.labelname, "<img>") then
                local nEmojiID = tonumber(v.emojiid) or 0
                local tbEmojiConf = UIChatEmojiTab[nEmojiID]
                if tbEmojiConf then
                    local szEmoji = string.format("[%s]", tbEmojiConf.szName)
                    szMsg = szMsg .. szEmoji
                end
            elseif v.labelname == "div" or v.labelname == "<div>" or string.match(v.labelname, "<div>") or
                 v.labelname == "color" or v.labelname == "<color>" or string.match(v.labelname, "<color>") then
                if v.content then
                    szMsg = szMsg .. v.content
                end
            end
        end
    end

    return szMsg
end

-- 判断是否需要清理
function ChatData.CheckNeedResize(nLen)
    return nLen > NEED_RESIZE_COUNT
end

-- 如果聊天频道的数据长度超过配置的长度了，就清理下
function ChatData.ResizeChatData(szUIChannel)
    local _doResize = function(_szUIChannel)
        local tbOneChannelData = self.tbChatData[_szUIChannel]
        if tbOneChannelData then
            local nLen = #tbOneChannelData
            local nMax = self.tbUIChannelToMaxCountMap[_szUIChannel]
            if nLen > nMax then
                local tbNewChannelData = {}
                local nCount = nMax
                for i = nLen, (nLen-nMax+1), -1 do
                    tbNewChannelData[nCount] = tbOneChannelData[i]
                    nCount = nCount - 1
                end
                self.tbChatData[_szUIChannel] = tbNewChannelData
            end
        end
    end

    if string.is_nil(szUIChannel) then
        for szKey, tbOneChannelData in pairs(self.tbChatData) do
            _doResize(szKey)
        end
    else
        _doResize(szUIChannel)
    end
end

function ChatData.GetCanShowChatCopyTips()
    return self.bCanShowChatCopyTips
end

function ChatData.SetCanShowChatCopyTips(bValue)
    self.bCanShowChatCopyTips = bValue
end

function ChatData.SetRuntimeSelectDisplayChannel(szUIChannel)
    self.szRuntimeSelectDisplayChannel = szUIChannel
end

function ChatData.GetRuntimeSelectDisplayChannel()
    if ChatData.IsUIChannelVisible(self.szRuntimeSelectDisplayChannel) then
        return self.szRuntimeSelectDisplayChannel or UI_Chat_Channel.All
    end

    return UI_Chat_Channel.All
end

function ChatData.GetDefaultDisplayChannel(szUIChannel)
    if szUIChannel == nil then
        szUIChannel = ChatData.GetRuntimeSelectDisplayChannel()

        -- local bHasWhisperUnreadRedPoint = ChatData.HasWhisperUnreadRedPoint()
        -- if bHasWhisperUnreadRedPoint then
        --     szUIChannel = UI_Chat_Channel.Whisper
        -- else
        --     szUIChannel = ChatData.GetRuntimeSelectDisplayChannel()
        -- end
    else
        if not ChatData.IsUIChannelVisible(szUIChannel) then
            szUIChannel = UI_Chat_Channel.All
        end
    end

    return szUIChannel
end

function ChatData.RecordSendTime(nChannelID)
    if not IsNumber(nChannelID) then
        return
    end

    self.tbChannelSendTimeMap[nChannelID] = Timer.RealtimeSinceStartup()
end

function ChatData.GetChannelSendCDTime(nChannelID)
    local nCDTime = 0

    local nCDMax = CHANNEL_SEND_CD[nChannelID] or 0
    if nCDMax > 0 then
        local nLastSendTime = self.tbChannelSendTimeMap[nChannelID]
        if nLastSendTime then
            local nNow = Timer.RealtimeSinceStartup()
            local nRemainCDTime = nCDMax - (nNow - nLastSendTime)
            if nRemainCDTime > 0 then
                nCDTime = math.ceil(nRemainCDTime)
            end
        end
    end

    return nCDTime
end

function ChatData.GetChannelVoiceAble(nChannelID)
    return CHANNEL_VOICE_ALBLE[nChannelID]
end

function ChatData.SetChannelVoiceModel(nChannelID, bFlag)
    self.tbChannelVoiceModeMap[nChannelID] = bFlag
end

function ChatData.IsChannelVoiceModel(nChannelID)
    return self.tbChannelVoiceModeMap[nChannelID]
end

function ChatData.ClearChannelVoiceModel()
    self.tbChannelVoiceModeMap = {}
end

function ChatData.GetRecordingMaxTime()
    return RECORDING_MAX_TIME
end

function ChatData.IsCMDChannel(nChannel)
    return CMD_CHANNEL[nChannel]
end

function ChatData.ParseCMD(t)
    local bCMD = false

	local function ParseText(text)
		local _, aInfo = GWTextEncoder_Encode(text)
		for kk, vv in ipairs(aInfo) do
			if vv.name == "CMD" then
				local tAttr = vv.attribute
				if tAttr.attri0 == "PQMSG" then
					local nIndex = tonumber(tAttr.attri1)
					-- PopupRemind.Open(nIndex)
                    TipsHelper.ShowHintSFX(nIndex)
					bCMD = true
				end
			end
		end
	end

	for k, v in ipairs(t) do
		if v.type and v.type == "text" then
			if v.text then
				ParseText(v.text)
			end
		end
	end
	return bCMD
end

function ChatData.GetSettingIndex(szUIChannel)
    return UI_CHANNEL_2_SETTING_INDEX[szUIChannel] or 1
end

function ChatData.SetChatInputText(szUIChannel, szText)
    if self.tbUIChannelTextMap == nil then
        self.tbUIChannelTextMap = {}
    end

    self.tbUIChannelTextMap[szUIChannel] = szText
end

function ChatData.GetChatInputText(szUIChannel)
    return self.tbUIChannelTextMap and self.tbUIChannelTextMap[szUIChannel] or ""
end

function ChatData.ClearChatInputText()
    self.tbUIChannelTextMap = nil
end

function ChatData.GetChannelNickName(szName)
    return CHANNEL_NICKNAME[szName] or szName
end

function ChatData.IsChannelReportDisable(nChannelID)
    return CHANNEL_REPORT_DISALBLE[nChannelID]
end

function ChatData.IsChannelCopyDisable(nChannelID)
    return CHANNEL_COPY_DISALBLE[nChannelID]
end

function ChatData.IsSendChannelVisible(nChannelID)
    local bVisible = true

    -- 先判等级和成就
    local tbDisplayFlagConf = ChatData.GetChatFlagConfByChannelID(nChannelID)
    if tbDisplayFlagConf then
        local nOpenLvl = tbDisplayFlagConf.nOpenLvl
        local nOpenAcv = tbDisplayFlagConf.nOpenAcv

        if nOpenLvl > 0 then
            local nPlayerLevel = g_pClientPlayer and g_pClientPlayer.nLevel or 1
            bVisible = nPlayerLevel >= nOpenLvl
        end

        if not bVisible and nOpenAcv > 0 then
            local aAchievement = Table_GetAchievement(nOpenAcv)
            bVisible = AchievementData.IsAchievementAcquired(nOpenAcv, aAchievement)
        end
    end

    if bVisible then
        if nChannelID == PLAYER_TALK_CHANNEL.TEAM then  -- 队伍
            bVisible = TeamData.IsInParty()
        elseif nChannelID == PLAYER_TALK_CHANNEL.RAID then  -- 团队
            bVisible = TeamData.IsInRaid()
        elseif nChannelID == PLAYER_TALK_CHANNEL.BATTLE_FIELD then  -- 战场
            local bIsInArena = ArenaData.IsInArena()
            local nBFType = MapHelper.GetBattleFieldType()
            if bIsInArena or nBFType == BATTLEFIELD_MAP_TYPE.BATTLEFIELD or
            nBFType == BATTLEFIELD_MAP_TYPE.TREASUREBATTLE or nBFType == BATTLEFIELD_MAP_TYPE.ARENA_TOWER then
                bVisible = true
            else
                bVisible = false
            end
        elseif nChannelID == PLAYER_TALK_CHANNEL.BATTLE_FIELD_SIDE then  -- 李渡鬼域
            local nBFType = MapHelper.GetBattleFieldType()
            if nBFType == BATTLEFIELD_MAP_TYPE.ZOMBIEBATTLE or nBFType == BATTLEFIELD_MAP_TYPE.TONGWAR then
                bVisible = true
            else
                bVisible = false
            end
        elseif nChannelID == PLAYER_TALK_CHANNEL.TONG then  -- 帮会
            bVisible = TongData.HavePlayerJoinedTong()
        elseif nChannelID == PLAYER_TALK_CHANNEL.TONG_ALLIANCE then -- 帮会同盟
            bVisible = TongData.GetAllianceTongID() > 0
        elseif nChannelID == PLAYER_TALK_CHANNEL.ROOM then  -- 房间
            bVisible = RoomData.IsHaveRoom()
        elseif nChannelID == PLAYER_TALK_CHANNEL.ALL_WORLD_CHAT then  -- 跨服
            bVisible = PVPFieldData.IsInPVPField()
        elseif nChannelID == PLAYER_TALK_CHANNEL.IDENTITY then  -- 萌新
            --bVisible = g_pClientPlayer and g_pClientPlayer.GetPlayerIdentityManager().dwCurrentIdentityType > 0
            bVisible = self.bShowMXChnl
        elseif nChannelID == PLAYER_TALK_CHANNEL.VOICE_ROOM then    --聊天室
            local szMyRoom, szCurrentRoomID = RoomVoiceData.GetRoleVoiceRoomList()
            bVisible = szCurrentRoomID ~= "0"
        elseif nChannelID == PLAYER_TALK_CHANNEL.DUNGEON_BULLET_SCREEN then    --副本弹幕
            if self.bBulletDebug then return true end
            bVisible = ChatData.CanUseBullet() --and OBDungeonData.IsPlayerInOBDungeon()
        end
    end

    return bVisible
end

function ChatData.GetChannelNameByID(nChannelID)
    local szName = ""

    local tbDisplayFlagConf = ChatData.GetChatFlagConfByChannelID(nChannelID)
    if tbDisplayFlagConf then
        szName = tbDisplayFlagConf.szName
    end

    return szName
end

function ChatData.GetSendChannelID(szUIChannel)
    local nFirstChannelID = ChatSetting.tbSendChannelIDList[1]
    if string.is_nil(szUIChannel) then
        szUIChannel = ChatData.GetRuntimeSelectDisplayChannel()
    end

    -- 先从运行时的表里取，取不到再去配置里去取
    local nSendChannelID = self.tbRunTimeUIChannelToSendChannel[szUIChannel]
    if not nSendChannelID then
        local tbSendChannle = UIChannel_To_SendChannel[szUIChannel]
        if tbSendChannle then
            nSendChannelID = tbSendChannle.nDefaultChannelID
        end

        -- 队伍的要特殊处理，先团队，后小队，如果没有，就第一个
        if szUIChannel == UI_Chat_Channel.Team then
            for k, v in ipairs(nSendChannelID) do
                if ChatData.IsSendChannelVisible(v) then
                    nSendChannelID = v
                    break
                end
            end
            if IsTable(nSendChannelID) then
                nSendChannelID = nFirstChannelID
            end
        end
    end

    if not nSendChannelID or not ChatData.IsSendChannelVisible(nSendChannelID) then
        nSendChannelID = nFirstChannelID
    end

    return nSendChannelID
end

function ChatData.SetSendChannelID(szUIChannel, nChannelID)
    if string.is_nil(szUIChannel) then
        szUIChannel = ChatData.GetRuntimeSelectDisplayChannel()
    end

    if nChannelID <= 0 then
        return
    end

    if not ChatData.CheckUIChannelCanSwitch(szUIChannel) then
        return
    end

    if self.tbRunTimeUIChannelToSendChannel[szUIChannel] == nChannelID then
        return
    end

    self.tbRunTimeUIChannelToSendChannel[szUIChannel] = nChannelID
    Event.Dispatch(EventType.OnChatSendChannelChanged, szUIChannel, nChannelID)
end

function ChatData.CheckUIChannelCanSwitch(szUIChannel)
    local bCanSwitch = false

    local tbSendChannle = szUIChannel and UIChannel_To_SendChannel[szUIChannel]
    if tbSendChannle then
        bCanSwitch = tbSendChannle.bCanSwitch
    end

    return bCanSwitch
end

-- 获取频道的别名
function ChatData.GetUIChannelNickName(szUIChannel)
    local szName = ""

    if Storage.Chat.tbUIChannelNickName then
        szName = Storage.Chat.tbUIChannelNickName[szUIChannel]
    end

    if string.is_nil(szName) then
        local tbConf = ChatData.GetChatConfByUIChannel(szUIChannel)
        szName = tbConf and tbConf.szName or ""
    end

    return szName
end

-- 设置频道的别名
function ChatData.SetUIChannelNickName(szUIChannel, szNickname)
    if string.is_nil(szUIChannel) then return end
    if string.is_nil(szNickname) then return end

    if not Storage.Chat.tbUIChannelNickName then
        Storage.Chat.tbUIChannelNickName = {}
    end

    Storage.Chat.tbUIChannelNickName[szUIChannel] = szNickname
    Storage.Chat.Flush()

    Event.Dispatch(EventType.OnChatUIChannelNicknameChanged, szUIChannel, szNickname)
end

-- 恢复设置频道的别名，但不存档
function ChatData.RecoverUIChannelNickName(szUIChannel)
    if Storage.Chat.tbUIChannelNickName then
        Storage.Chat.tbUIChannelNickName[szUIChannel] = nil
    end

    Event.Dispatch(EventType.OnChatUIChannelNicknameChanged, szUIChannel, nil)
end

-- 设置迷你面板的频道是否和大面板同步
function ChatData.SyncMiniChat(bSync)
    Storage.Chat.bSyncMiniChat = bSync

    Storage.Chat.Flush()

    Event.Dispatch(EventType.OnChatSyncMiniChat, bSync)
end

function ChatData.IsSyncMiniChat()
    return Storage.Chat.bSyncMiniChat
end

function ChatData.GetMiniDisplayChannel()
    local szUIChannel = nil

    if ChatData.IsSyncMiniChat() then
        szUIChannel = ChatData.GetDefaultDisplayChannel()
    else
        szUIChannel = self.szRuntimeMiniDisplayChannel
        if not ChatData.IsUIChannelVisible(szUIChannel) then
            szUIChannel = UI_Chat_Channel.All
        end
    end

    return szUIChannel or UI_Chat_Channel.All
end

function ChatData.SetMiniDisplayChannel(szUIChannel)
    self.szRuntimeMiniDisplayChannel = szUIChannel

    if ChatData.IsSyncMiniChat() then
        self.szRuntimeSelectDisplayChannel = szUIChannel
    end
end

function ChatData.SetIsScrolling(bVal)
    self.bChatViewIsScrolling = bVal
end

function ChatData.GetIsScrolling()
    return self.bChatViewIsScrolling
end

function ChatData.GetUIChannelMaxCount(szUIChannel)
    return self.tbUIChannelToMaxCountMap and self.tbUIChannelToMaxCountMap[szUIChannel] or 100
end

function ChatData.IsUIChannelVisible(szUIChannel)
    if string.is_nil(szUIChannel) then
        return false
    end

    if not self.tbUIChannelToDisplayName then
        self.tbUIChannelToDisplayName = {}
    end

    local bVisible = true
    local nIndex = UI_CHANNEL_2_SETTING_INDEX[UI_Chat_Channel.Display]
    local tbSetting = ChatSetting[nIndex]
    local szName = self.tbUIChannelToDisplayName[szUIChannel]

    if string.is_nil(szName) then
        if tbSetting and tbSetting.tbGroupList then
            if tbSetting.tbGroupList[1] and tbSetting.tbGroupList[1].tbChannelList then
                for k, v in ipairs(tbSetting.tbGroupList[1].tbChannelList) do
                    if szUIChannel == v.szUIChannel then
                        szName = v.szName
                        self.tbUIChannelToDisplayName[szUIChannel] = szName
                        break
                    end
                end
            end
        end
    end

    if not string.is_nil(szName) then
        if self.tbSettingRuntimeMap then
            if self.tbSettingRuntimeMap[UI_Chat_Channel.Display] then
                if self.tbSettingRuntimeMap[UI_Chat_Channel.Display][UI_Chat_Setting_Type.Display] then
                    bVisible = self.tbSettingRuntimeMap[UI_Chat_Channel.Display][UI_Chat_Setting_Type.Display][szName]
                end
            end
        end
    end

    return bVisible
end

-- 系统消息过滤功能
function ChatData.IsSystemMsgFiltered(nChannel, szContent)
    for i = 1, #self.tbSystemFilterKeyWords do
        if string.find(szContent, self.tbSystemFilterKeyWords[i]) then
            return true
        end
    end
    return false
end

-- NPC剧情频道接收检查
function ChatData.NPCStoryRecvCheck(nChannel)
    local bResult = true

    if nChannel then
        --if self.IsSystemChannel(nChannel) then
        if self.tbNpcStoryChannleMap[nChannel] ~= nil then
            bResult = self.tbNpcStoryChannleMap[nChannel]
        end
        --end
    end

    return bResult
end

--密聊勿扰
function ChatData.CheckWhisperIsOpenDisturb()
    return self.nOpenDisturbTime
end

function ChatData.RemoveWhisperData(szUIChannel, szCurWhisper)
    if szUIChannel ~= UI_Chat_Channel.Whisper then
        return
    end

    if not szCurWhisper then
        return
    end

    if not self.tbChatData[szUIChannel] then
        return
    end

    local tbWhisper = self.tbChatData[szUIChannel][szCurWhisper]
    if tbWhisper then
        self.tbChatData[szUIChannel][szCurWhisper] = {}
    end
end

-- 系统公告是否显示烟花公告
function ChatData.IsSystemNoticeDisplayFireworks()
    local bResult = false

    if self.tbSettingRuntimeMap[UI_Chat_Channel.System] then
        local tbFilter = self.tbSettingRuntimeMap[UI_Chat_Channel.System][UI_Chat_Setting_Type.Filter]
        if tbFilter then
            bResult = tbFilter["烟花公告"]
        end
    end

    return bResult
end

-- 默认显示萌新频道
-- 登录后由服务器检测是否关闭，或在得到指导资格后由服务器检测是否显示
function ChatData.UpdateMengXinShow(bShowMX)
    if self.bShowMXChnl == bShowMX then
        return
    end

    self.bShowMXChnl = bShowMX
    Event.Dispatch(EventType.OnChatMengXinShow, bShowMX)
end

function ChatData.ResetChatSettingConfig()
    -- 不重置
    Storage.Chat.nVersion = ChatSetting.nVersion
    Storage.Chat.Flush()
    local bEnable, szNickname, tbSaveData = Storage_Server.GetData("ChatSetting", 2)
    local bEnable2, szNickname2, tbSaveData2 = Storage_Server.GetData("ChatSetting", 14)
    local bSame, bEmpty = ChatData.CheckServerDifference()
    local tbChannels2Index = ChatSetting.GetChannels2IndexTab()
    local nIndex = tbChannels2Index["单条提醒"]
    local nIndex2 = tbChannels2Index["双条提醒"]

    local function _reset()
        for k, v in pairs(Storage.Chat or {}) do
            if IsTable(v) then
                Storage.Chat[k] = {}
            end
        end

        Storage.Chat.tbUIChannelNickName = {}
        Storage.Chat.nVersion = ChatSetting.nVersion
        Storage.Chat.Flush()
        self.tbSettingRuntimeMap = Lib.copyTab(self.tbSettingConfigMap)
        --上传到本地
        ChatData.SaveRuntimeData_ToServer(false)
    end
    if (tbSaveData and (tbSaveData[nIndex] or tbSaveData[nIndex2])) or (tbSaveData2 and not (tbSaveData2[nIndex] or tbSaveData2[nIndex2])) then--Storage第二个为消息提示 标记为错
        LOG.ERROR("[Storage_Server] ChatSetting data is wrong, reset it")
        _reset()
    else
        if bEmpty then
            self.SaveRuntimeData_ToServer(false)
        else
            ChatData.SetRuntimeData_ByServer()
        end
    end
end

function ChatData.CheckServerDifference()
    local bSame = true
    local bEmpty = true
    for i, tbOneSetting in ipairs(ChatSetting) do
        local szUIChannel = tbOneSetting.szUIChannel
        local bEnable, szNickname, tbSaveData = Storage_Server.GetData("ChatSetting", i)
        if bEnable and tbSaveData then
            bEmpty = false
            local tbOneRuntimeData = self.tbSettingRuntimeMap[szUIChannel]
            if tbOneSetting.bCanRename then
                local szName = ChatData.GetUIChannelNickName(szUIChannel)
                if szNickname ~= szName then
                    bSame = false
                    break
                end
            end

            for j, tbOneGroupConf in ipairs(tbOneSetting.tbGroupList) do
                local szType = tbOneGroupConf.szType
                local tbOneData = tbOneRuntimeData[szType]
                for k, tbOneConf in ipairs(tbOneGroupConf.tbChannelList or {}) do
                    local szName = tbOneConf.szName
                    local nIndex = ChatSetting.GetChannels2IndexTab()[szName]
                    if not nIndex then
                        LOG.ERROR("[Storage_Server] Unknown chat channel: " .. szName)
                    elseif tbOneData[szName] ~= tbSaveData[nIndex] then
                        if tbOneData[szName] then
                            bSame = false
                            break
                        elseif not tbOneData[szName] and tbSaveData[nIndex] then
                            bSame = false
                            break
                        end
                    end
                end
            end
        end
    end

    return bSame, bEmpty
end

function ChatData.CanUseBullet()
    if self.bBulletDebug then return true end
    return self.nBulletMapType ~= nil
end

-- 获取当前地图弹幕类型
function ChatData.GetBulletMapType()
    return self.nBulletMapType
end

-- 获取弹幕类型对应的配置 {tFont, tColor, tMode}
function ChatData.GetBulletBaseConf(nType)
    nType = nType or self.nBulletMapType
    return nType and self.tbBulletBase[nType]
end

function ChatData.ShowBulletView()
    if not ChatData.CanUseBullet() then
        UIMgr.Close(VIEW_ID.PanelDanmu)
        self.tbBulletDataList = {}
        return
    end

    local bShow = Storage.Chat_Bullet.bOpenFlag
    if bShow then
        UIMgr.OpenSingle(false, VIEW_ID.PanelDanmu)
    else
        UIMgr.Close(VIEW_ID.PanelDanmu)
    end
end

function ChatData.AddToBulletDataList(tbData)
    if not self.tbBulletDataList then
        return
    end

    local nCount = #self.tbBulletDataList
    if nCount >= self.nBulletDataMaxCount then
        table.remove(self.tbBulletDataList, 1)
    end

    table.insert(self.tbBulletDataList, tbData)
end

function ChatData.PickOneBulletData()
    if not self.tbBulletDataList then
        return
    end

    local nCount = #self.tbBulletDataList
    if nCount <= 0 then
        return
    end

    return table.remove(self.tbBulletDataList, 1)
end
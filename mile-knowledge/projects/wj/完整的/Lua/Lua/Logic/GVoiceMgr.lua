-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: GVoiceMgr
-- Date: 2023-03-17 15:11:02
-- Desc: ?
-- ---------------------------------------------------------------------------------
local MAX_VOLUME = 150


GVoiceMgr = GVoiceMgr or {className = "GVoiceMgr"}
local self = GVoiceMgr
-------------------------------- 消息定义 --------------------------------
GVoiceMgr.Event = {}
GVoiceMgr.Event.XXX = "GVoiceMgr.Msg.XXX"


function GVoiceMgr.Init()
    self.bIsEnterGame = false -- 表示是否进入到游戏场景（登录创角这些不算）
    self.tbVoiceConfig = Table_GetVoiceTypeData()
    self.tbForbidMemberIDMap = {}
    self.bLastIsSystemTeam = false
    self.szCurRoomID = ""
    self.bApplyJoinTeamRoom = false
    self.nCurTeamIdentifty = 0

    self.RegEvent()
end

function GVoiceMgr.UnInit()
    self.UnRegEvent()
end

function GVoiceMgr.IsInitSDK()
    return self.bInitSDK
end

function GVoiceMgr.InitSDK(szGVoiceID, szAppID, szSignature)
    if not self.bInitSDK then
        self.tbForbidMemberIDMap = {}
        self.nMicState = MIC_STATE.CLOSE
        self.nSpeakerState = SPEAKER_STATE.OPEN

        self.bInitSDK = GME_Init(szGVoiceID, szAppID, szSignature)
        LOG.INFO("GVoiceMgr.InitSDK, szGVoiceID = %s, szAppID = %s, szSignature = %s, bInitSDK = %s", tostring(szGVoiceID), tostring(szAppID), tostring(szSignature), tostring(self.bInitSDK))
    end
end

function GVoiceMgr.UnInitSDK()
    self.bInitSDK = false
    self.tbForbidMemberIDMap = {}
    self.nMicState = MIC_STATE.CLOSE
    self.nSpeakerState = SPEAKER_STATE.OPEN

    self.VOIP_Off()

    GME_UnInit()
    -- self.UnRegEvent()
    LOG.INFO("GVoiceMgr.UnInitSDK")
end

-- 玩家离开队伍时的处理
function GVoiceMgr.OnLeaveParty()
    if self.IsInRoom() then
        self.ExitRoom()
    end

    self.SetMicState(MIC_STATE.CLOSE)
    self.SetSpeakerState(SPEAKER_STATE.OPEN)
    self.tbForbidMemberIDMap = {}
end

function GVoiceMgr.OnLeaderChanged(nAuthorityType)
    -- if nAuthorityType ~= TEAM_AUTHORITY_TYPE.LEADER then
    --     return false
    -- end

    -- local nMicState = self.GetMicState()
    -- if not TeamData.IsTeamLeader() and nMicState == MIC_STATE.OPEN then
    --     self.CloseMic()
    --     self.SetMicState(MIC_STATE.CLOSE)
    -- end
end

function GVoiceMgr.RegEvent()
    Event.Reg(self, "INIT_GVOICE_CONFIG", function(szGVoiceID, szAppID, szSignature)
        GVoiceMgr.InitSDK(szGVoiceID, szAppID, szSignature)
    end)

    -- 删除队友
    Event.Reg(self, "PARTY_DELETE_MEMBER", function(dwTeamID, dwMemberID, szName, nGroupIndex)
        if g_pClientPlayer and g_pClientPlayer.dwID == dwMemberID then
            self.OnLeaveParty()
        end
    end)

    -- 队伍解散
    Event.Reg(self, "PARTY_DISBAND", function(dwTeamID)
        self.OnLeaveParty()
    end)

    -- 队长改变
    Event.Reg(self, "TEAM_AUTHORITY_CHANGED", function(nAuthorityType, dwTeamID)
        self.OnLeaderChanged(nAuthorityType)
    end)

    -- 退出消息，包括小退大退
    Event.Reg(self, "PLAYER_LEAVE_GAME", function()
        LOG.INFO("GVoiceMgr, PLAYER_LEAVE_GAME")
        self.bIsEnterGame = false
        self.OnLeaveParty()
        self.UnInitSDK()
    end)

    Event.Reg(self, "PARTY_MESSAGE_NOTIFY", function(nCode, szName)
        if nCode == PARTY_NOTIFY_CODE.PNC_PARTY_CREATED or nCode == PARTY_NOTIFY_CODE.PNC_PARTY_JOINED then
            Event.Reg(self, "PARTY_UPDATE_BASE_INFO", function()
                Event.UnReg(self, "PARTY_UPDATE_BASE_INFO")
                --GVoiceMgr.TryJoinRoom()
                GVoiceMgr.OpenSpeakerCloseMic()
            end)
        end
    end)

    -- 该事件用于被动进房功能，即有一个队友语音房间，其他队友都需要自动进房
    Event.Reg(self, "ON_SET_MEMBER_GVOICE_ID", function(dwMemberID, szGVoiceID)
        LOG.INFO("GVoiceMgr.ON_SET_MEMBER_GVOICE_ID, dwMemberID = %s, szGVoiceID = %s", tostring(dwMemberID), tostring(szGVoiceID))
        if szGVoiceID ~= "" then
            GVoiceMgr.TryJoinRoom()
        end
    end)

    -- 断线重连
    Event.Reg(self, "LOADING_END", function()
        self.bIsEnterGame = true

        if not g_pClientPlayer then
            self.bLastIsSystemTeam = false
            self.ExitRoom()
            return
        end

        local bIsPlayerInTeam = TeamData.IsPlayerInTeam()
        if not bIsPlayerInTeam then
            self.bLastIsSystemTeam = false
            self.ExitRoom()
            return
        end

        -- 如果玩家在队伍里，但是不在实时语音房间，那么就强制进入实时语音房间
        if bIsPlayerInTeam and not self.IsInRoom() then
            self.nCurTeamIdentifty = 0
            self.bApplyJoinTeamRoom = false
            GVoiceMgr.TryJoinRoom()
            return
        end

        -- 如果发现语音房间ID不一样了，那就退出重进一下
        local nCurTeamIdentifty = self.GetPlayerTeamIdentify()
        if self.nCurTeamIdentifty ~= nCurTeamIdentifty then
            self.nCurTeamIdentifty = 0
            self.bApplyJoinTeamRoom = false
            GVoiceMgr.TryJoinRoom()
            return
        end
    end)

    Event.Reg(self, EventType.OnApplicationDidEnterBackground, function()
        GVoiceMgr.Pause()
    end)

    Event.Reg(self, EventType.OnApplicationWillEnterForeground, function()
        GVoiceMgr.Resume()
    end)

    Event.Reg(self, EventType.OnAccountLogout, function()
        self.bLastIsSystemTeam = false
    end)

    Event.Reg(self, "ON_CHAT_EVENT_NOTIFY", function (dwCode, dwReason, nParam1, nParam2, szParam, cszParam4)
        if dwCode == CHAT_SERVER_NOTIFY_EVENT_CODE_TYPE.TEAM then
            if dwReason == CHAT_SERVER_NOTIFY_EVENT_REASON_TYPE.BAN_JOIN_TEAM_VOICE_ROOM then
                OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.GVOICE_ROOM_MIC_ERROR_CODE[VOICE_ROOM_NOTIFY_CODE.BAN_JOIN_VOICE])
                self.bApplyJoinTeamRoom = false
                self.nCurTeamIdentifty = 0

                self.CloseMic()
                self.SetMicState(MIC_STATE.CLOSE)
            end
        end
    end)

    Event.Reg(self, EventType.OnRemoteBanInfoUpdate, function(nBanChatEndTime, nBanShowCardOperateEndTime)
        UI_SetClientPlayerBanEndTime(nBanChatEndTime)

        -- 游戏中途被禁言，强制关麦
        if UI_IsClientPlayerBaned() then
            GVoiceMgr.CloseMic()
            GVoiceMgr.SetMicState(MIC_STATE.CLOSE)
            OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.GVOICE_ROOM_MIC_ERROR_CODE[VOICE_ROOM_NOTIFY_CODE.BAN_JOIN_VOICE])
            return
        end
    end)
end

function GVoiceMgr.UnRegEvent()
    Event.UnReg(self, "PARTY_DELETE_MEMBER")
    Event.UnReg(self, "PARTY_DISBAND")
    Event.UnReg(self, "TEAM_AUTHORITY_CHANGED")
    Event.UnReg(self, "PLAYER_LEAVE_GAME")
    Event.UnReg(self, "PARTY_MESSAGE_NOTIFY")
    Event.UnReg(self, "ON_SET_MEMBER_GVOICE_ID")
    Event.UnReg(self, "LOADING_END")
end

function GVoiceMgr.GetMaxVolume()
    return MAX_VOLUME
end

-- 暂停
function GVoiceMgr.Pause()
    LOG.INFO("GVoiceMgr.Pause()")
    GME_Pause()
end

-- 恢复
function GVoiceMgr.Resume()
    LOG.INFO("GVoiceMgr.Resume()")
    GME_Resume()
end

-- 开麦
function GVoiceMgr.OpenMic()
    if UI_IsClientPlayerBaned() then
        Event.Dispatch(EventType.OnOpenMicButBaned)
        OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.GVOICE_ROOM_MIC_ERROR_CODE[VOICE_ROOM_NOTIFY_CODE.BAN_JOIN_VOICE])
        return false
    end

    LOG.INFO("GVoiceMgr.OpenMic(), szRoomID=%s", tostring(GVoiceMgr.GetCurRoomID()))
    self.VOIP_OpenMic()
    GME_OpenMic(GVoiceMgr.GetCurRoomID())

    if IsWLCloudClient() then
        SyncCloudAppMicState(true)
    end

    GVoiceMgr.TryJoinRoom()

    return true
end

-- 闭麦
function GVoiceMgr.CloseMic()
    LOG.INFO("GVoiceMgr.CloseMic()")
    self.VOIP_Off()
    GME_CloseMic(GVoiceMgr.GetCurRoomID())

    if IsWLCloudClient() then
        SyncCloudAppMicState(false)
    end
end

-- 麦克风是否打开
function GVoiceMgr.IsMicOpened()
    return GME_IsMicOpened(GVoiceMgr.GetCurRoomID())
end

-- 获得麦克风等级
function GVoiceMgr.GetMicLevel()
    return GME_GetMicLevel(GVoiceMgr.GetCurRoomID())
end

-- 设置麦克风音量 [0-1]
function GVoiceMgr.SetMicVolume(fVolume)
    if not self.bInitSDK then
        return
    end

    if GVoiceMgr.IsInRoom() then
        GME_SetMicVolume(fVolume * MAX_VOLUME)
    end

    local szCurVoiceRoomID = RoomVoiceData.GetCurVoiceRoomID()
    if szCurVoiceRoomID and GVoiceMgr.IsInRoom(szCurVoiceRoomID) then
        GME_SetMicVolume(fVolume * MAX_VOLUME, szCurVoiceRoomID)
    end
end

-- 获取麦克风音量
function GVoiceMgr.GetMicVolume()
    return (GME_GetMicVolume(GVoiceMgr.GetCurRoomID()) / MAX_VOLUME)
end

-- 设置麦克风状态 @see MIC_STATE
function GVoiceMgr.SetMicState(nState)
    self.nMicState = nState
end

-- 获取麦克风状态
function GVoiceMgr.GetMicState()
    return self.nMicState
end

-- 麦克风是否可用
function GVoiceMgr.IsMicAvail()
    if Platform.IsWindows() then
        return GME_IsMicAvail(GVoiceMgr.GetCurRoomID())
    end
    return true
end

-- 打开扬声器
function GVoiceMgr.OpenSpeaker()
    GME_OpenSpeaker(GVoiceMgr.GetCurRoomID())
end

-- 关闭扬声器
function GVoiceMgr.CloseSpeaker()
    GME_CloseSpeaker(GVoiceMgr.GetCurRoomID())
end

-- 扬声器是否打开
function GVoiceMgr.IsSpeakerOpened()
    return GME_IsSpeakerOpened(GVoiceMgr.GetCurRoomID())
end

-- 设置扬声器声音 [0-1]
function GVoiceMgr.SetSpeakerVolume(fVolume)
    if not self.bInitSDK then
        return
    end

    GME_SetSpeakerVolume(fVolume * MAX_VOLUME, GVoiceMgr.GetCurRoomID())
end

-- 获取扬声器声音
function GVoiceMgr.GetSpeakerVolume()
    return (GME_GetSpeakerVolume(GVoiceMgr.GetCurRoomID()) / MAX_VOLUME)
end

-- 设置扬声器状态
function GVoiceMgr.SetSpeakerState(nState)
    self.nSpeakerState = nState
end

-- 获取扬声器状态
function GVoiceMgr.GetSpeakerState()
    return self.nSpeakerState
end

-- 是否进入实时语音房间
function GVoiceMgr.IsInRoom(szRoomID)
    if string.is_nil(szRoomID) then
        szRoomID = GVoiceMgr.GetCurRoomID()
    end
    return GME_IsInRoom(szRoomID)
end

-- 获取当前实时语音房间的RoomID
function GVoiceMgr.GetCurRoom()
    return GME_GetCurRoom(GVoiceMgr.GetCurRoomID())
end

function GVoiceMgr.TryJoinRoom(bDoNotHandleSpeakerAndMic)
    LOG.INFO("GVoiceMgr.TryJoinRoom bDoNotHandleSpeakerAndMic=%s", tostring(bDoNotHandleSpeakerAndMic))
    if not self.IsJoinRoomShouldBeExecuted() then
        return
    end

    local hTeamClient = GetClientTeam()
    if not hTeamClient then
        return
    end

    self.nCurTeamIdentifty = self.GetPlayerTeamIdentify()
    self.bApplyJoinTeamRoom = hTeamClient.ApplyJoinVoiceRoom()

    Event.Reg(self, "JOIN_VOICE_ROOM", function(szRoomID, szSignature, bCreateRoom, bIsTeamRoom)
        LOG.INFO("GVoiceMgr.JOIN_VOICE_ROOM szRoomID=%s, bIsTeamRoom=%s", tostring(szRoomID), tostring(bIsTeamRoom))
        Event.UnReg(self, "JOIN_VOICE_ROOM")
        if bIsTeamRoom then
            GVoiceMgr.JoinRoom(bDoNotHandleSpeakerAndMic, szRoomID, szSignature)
        end
    end)

    return true
end

-- 加入实时语音的房间   异步，监听 "CLIENT_ON_JOIN_ROOM"
function GVoiceMgr.JoinRoom(bDoNotHandleSpeakerAndMic, szRoomID, szSignature)
    if not TeamData.IsPlayerInTeam() then
        return
    end

    local hTeamClient = GetClientTeam()
    if not hTeamClient then
        return
    end

    if not hTeamClient.dwTeamID or hTeamClient.dwTeamID == 0 then
        return
    end

    local nCurTeamIdentifty = self.GetPlayerTeamIdentify()
    if self.nCurTeamIdentifty ~= nCurTeamIdentifty then
        self.nCurTeamIdentifty = nCurTeamIdentifty
        self.bApplyJoinTeamRoom = hTeamClient.ApplyJoinVoiceRoom()
        return
    end

    self.InitSDK()

    -- iOS强制使用媒体音量
    if Platform.IsIos() then
        GME_SetAdvanceParams("SetForceUseMediaVol", "1")
    end

    LOG.INFO("GVoiceMgr.JoinRoom szRoomID=%s, szSignature=%s", tostring(szRoomID), tostring(szSignature))
    local bResult = GME_JoinTeamRoom(szRoomID, szSignature)
    if not bResult then
        LOG.ERROR("GVoiceMgr.JoinRoom Failed! RoomID:"..szRoomID)
    end

    Event.Reg(self, "CLIENT_ON_JOIN_ROOM", function(szOpenID, nResult, szRoomID) -- nResult 1 成功 0 失败
        Event.UnReg(self, "CLIENT_ON_JOIN_ROOM")
        LOG.INFO("GVoiceMgr.CLIENT_ON_JOIN_ROOM szOpenID=%s, szRoomID=%s", tostring(szOpenID), tostring(szRoomID))
        self.OnJoinRoom(szOpenID, nResult, szRoomID, bDoNotHandleSpeakerAndMic)
    end)
end

-- 加入实时语音房间的回调
function GVoiceMgr.OnJoinRoom(szOpenID, nResult, szRoomID, bDoNotHandleSpeakerAndMic)
    if nResult == 0 then
        LOG.ERROR("GVoiceMgr.OnJoinRoom Failed!")
        return
    end

    LOG.INFO("GVoiceMgr.OnJoinRoom Successed, szRoomID = %s", tostring(szRoomID))
    self.szCurRoomID = szRoomID

    if not TeamData.IsInParty() then return end

    -- 设置音量和变音相关
    local nVoiceType        = GVoiceMgr.GetVoiceType()
    local nMicVolume        = GetGameSoundSetting(SOUND.MIC_VOLUME).Slider
    local nSpeakerVolume    = GetGameSoundSetting(SOUND.SPEAKER_VOLUME).Slider

    self.SetMicVolume(nMicVolume)
	self.SetSpeakerVolume(nSpeakerVolume)
    self.SetVoiceType(nVoiceType)

    local speakerAndMicHandler = function()
        self.bForceSwitchSpeakerAndMic = true
        if GVoiceMgr.IsOpenSpeakerAndMic() then
            GVoiceMgr.OpenSpeakerAndMic()
        elseif GVoiceMgr.IsOpenSpeakerCloseMic() then
            GVoiceMgr.OpenSpeakerCloseMic()
        elseif GVoiceMgr.IsCloseSpeakerAndMic() then
            GVoiceMgr.CloseSpeakerAndMic()
        end
        self.bForceSwitchSpeakerAndMic = false
    end

    if not bDoNotHandleSpeakerAndMic and not self.bLastIsSystemTeam then
        speakerAndMicHandler()
    else
        if self.bLastMicIsOpened then
            self.CloseMic()
            self.SetMicState(MIC_STATE.CLOSE)

            Timer.DelTimer(self, self.nResumeTimerID2)
            self.nResumeTimerID2 = Timer.Add(self, 0.3, function()
                speakerAndMicHandler()
            end)

            self.bLastMicIsOpened = nil
        else
            speakerAndMicHandler()
        end
    end

    self.bLastIsSystemTeam = TeamData.IsSystemTeam()

    --self.EnableLoopBack(true, GVoiceMgr.GetCurRoomID())
end

-- 退出实时语音的房间 异步，监听 "CLIENT_ON_QUIT_ROOM"
function GVoiceMgr.ExitRoom(bNeedJoinNewRoom)
    if not self.IsInRoom() then return end

    if bNeedJoinNewRoom or self.bLastIsSystemTeam then
        GVoiceMgr.KeepMicState()
    end

    local bResult = GME_ExitRoom(GVoiceMgr.GetCurRoomID())
    if not bResult then
        LOG.ERROR("GVoiceMgr.ExitRoom Failed!")
    end

    Event.Reg(self, "CLIENT_ON_QUIT_ROOM", function(nResult, szRoomID) -- nResult 1 成功 0 失败
        Event.UnReg(self, "CLIENT_ON_QUIT_ROOM")
        self.VOIP_Off()
        self.OnExitRoom(nResult, szRoomID, bNeedJoinNewRoom)
    end)
end

-- 退出实时语音房间的回调
function GVoiceMgr.OnExitRoom(nResult, szRoomID, bNeedJoinNewRoom)
    if nResult == 0 then
        OutputMessage("MSG_SYS", g_tStrings.GVOICE_ON_QUIT_ROOM_FAILED)
        OG.ERROR("GVoiceMgr.OnExitRoom Failed!")
        return
    end

    LOG.INFO("GVoiceMgr.OnExitRoom Success!")

    self.bApplyJoinTeamRoom = false
    self.nCurTeamIdentifty = 0
    self.szCurRoomID = ""

    if bNeedJoinNewRoom then
        GVoiceMgr.TryJoinRoom(true)
    else
        if self.bIsEnterGame and TeamData.GetTeamID() > 0 then
            GVoiceMgr.TryJoinRoom()
        else
            OutputMessage("MSG_SYS", g_tStrings.GVOICE_ON_QUIT_ROOM)
        end
    end
end

-- 获取自己在实时语音房间的 member id
function GVoiceMgr.GetMemberID()
    return GME_GetMermberID()
end

-- 禁用队伍成员说话
function GVoiceMgr.ForbidMemberVoice(dwTeamMateMemberID, bForbid)
    local szOpenID = TeamData.GetMemberGVoiceID(dwTeamMateMemberID)
    if string.is_nil(szOpenID) then
        LOG.ERROR("GVoiceMgr.ForbidMemberVoice Failed! szOpenID is nil!")
        return
    end

    local bResult = GME_ForbidMemberVoice(szOpenID, bForbid)
    if not bResult then
        LOG.ERROR("GVoiceMgr.ForbidMemberVoice Failed!")
    end

    self.tbForbidMemberIDMap[szOpenID] = bForbid

    Event.Dispatch(EventType.OnTeamVoiceForbided, dwTeamMateMemberID)
end

-- 队伍成员是否禁言了
function GVoiceMgr.IsMemberForbid(dwTeamMateMemberID)
    local szOpenID = TeamData.GetMemberGVoiceID(dwTeamMateMemberID)
    local bResult = self.tbForbidMemberIDMap[szOpenID]
    return bResult
end

-- 队伍成员是否在实时语音房间
function GVoiceMgr.IsMemberInRoom(dwTeamMateMemberID)
    local szOpenID = TeamData.GetMemberGVoiceID(dwTeamMateMemberID)
    local bResult = (szOpenID ~= "")
    return bResult
end

-- 字符串转OpenID
function GVoiceMgr.String2OpenID(str)
    return GME_String2OpenID(str)
end

-- 开启或者关闭耳返（如果想听到自己的声音，就设置成true）
function GVoiceMgr.EnableLoopBack(bEnable)
    GME_EnableLoopBack(bEnable)
end

-- 获得声音的配置 @see "\\UI\\Scheme\\Case\\VoiceType.txt"
function GVoiceMgr.GetVoiceConfig()
    return self.tbVoiceConfig
end

-- 设置声音类型 变音 0 表示默认不变音
function GVoiceMgr.SetVoiceType(nVoiceType)
    if not self.tbVoiceConfig or not self.tbVoiceConfig[nVoiceType] then return end

    -- 如果在语音房间内，则需要传入房间ID
    local szMyRoomID, szCurrentRoomID = RoomVoiceData.GetRoleVoiceRoomList()
    if not string.is_nil(szCurrentRoomID) then
        GME_SetVoiceType(nVoiceType, szCurrentRoomID)
        return
    end

    GME_SetVoiceType(nVoiceType)
end

-- 获取声音类型 GME升级删除了12小黄人
function GVoiceMgr.GetVoiceType()
    local nVoiceType = GetGameSoundSetting(SOUND.MIC_VOLUME).VoiceType
    if nVoiceType > 11 then
        nVoiceType = 0
    end
    return nVoiceType
end

function GVoiceMgr.GetVoiceNameByType(nVoiceType)
    local tbConf = self.tbVoiceConfig and self.tbVoiceConfig[nVoiceType] or {}
    local szName = tbConf.szName or ""
    return GBKToUTF8(szName)
end

-- 获取正在说话人的 OpenID Map (怕刷，策略从C++获取)
function GVoiceMgr.GetSaying(bForceUpdate)
    -- 没有的时候取一下
    if not self.tbSaying or bForceUpdate then
        self.tbSaying = GME_GetSayings(GVoiceMgr.GetCurRoomID())
    else
        -- 有的话定期取一下
        local nNow = GetTickCount()
        if self.nLastGetSayingTime then
            if (nNow - self.nLastGetSayingTime) > 5000 then
                self.tbSaying = GME_GetSayings()
            end
        end
    end

    self.nLastGetSayingTime = nNow

    return self.tbSaying
end

-- 获取队伍成员是否在说话
function GVoiceMgr.IsMemberSaying(dwTeamMateMemberID)
    local szOpenID = TeamData.GetMemberGVoiceID(dwTeamMateMemberID)
    local tbSaying = GVoiceMgr.GetSaying(true) or {}
    return tbSaying[szOpenID]
end

-- 获得自己的OpenID
-- 经过测试发现openid冲突会出现冲突的两个人在房
-- 间内听不到任何人的声音，但别人可以听到他们俩的声音
-- 使用账号md5加账号头两个字符和长度做openid应该可以避免openid的冲突
function GVoiceMgr.GetOpenID()
    local szAccount = Login_GetAccount() or ""
    local szMix = szAccount
    local szStr = MD5(szMix) .. string.sub(szMix, 1, 2) .. string.len(szMix)
    local szOpenID = GVoiceMgr.String2OpenID(szStr)
    return szOpenID
end

function GVoiceMgr.KeepMicState()
    self.bLastMicIsOpened = self.IsMicOpened()
end

-- 移动端进入房间且开麦，压低Wwise声音
function GVoiceMgr.VOIP_OpenMic()
    if Platform.IsMobile() then
        if self.IsInRoom() then
            -- SetSoundState("VOIP_State_Dodge", "VOIP_State_Dodge_On_L1")
        end
    end
end

-- 进入房间且开麦且说话的时候
function GVoiceMgr.VOIP_Speak()
    if Platform.IsMobile() then
        if self.IsInRoom() and self.IsMicOpened() then
            if self.GetMicLevel() > 1 then
                SetSoundState("VOIP_State_Dodge", "VOIP_State_Dodge_On_L2")
            end
        end
    end
end

-- 移动端闭麦或者退出房间的时候，还原压低Wwise声音
function GVoiceMgr.VOIP_Off()
    if Platform.IsMobile() then
        SetSoundState("VOIP_State_Dodge", "VOIP_State_Dodge_Off")
    end
end

--获取麦克风列表
function GVoiceMgr.GetMicList(nRoomID)
    return GME_GetMicList(nRoomID)
end

-- 设置麦克风设备
function GVoiceMgr.SelectMic(szDeviceID)
    local szCurDeviceID = GVoiceMgr.GetCurMic()
    if szCurDeviceID and szCurDeviceID ~= szDeviceID then
        GME_SelectMic(nil, szDeviceID)
    end

    local szRoomID = RoomVoiceData.GetCurVoiceRoomID()
    if szRoomID and GVoiceMgr.IsInRoom(szRoomID) then
        GME_SelectMic(szRoomID, szDeviceID)
    end
end

-- 获取当前麦克风设备
function GVoiceMgr.GetCurMic()
    return GME_GetCurMic()
end

-- 获取扬声器列表
function GVoiceMgr.GetSpeakerList(nRoomID)
    return GME_GetSpeakerList(nRoomID)
end

-- 设置扬声器设备
function GVoiceMgr.SelectSpeaker(szDeviceID)
    local szCurDeviceID = GVoiceMgr.GetCurSpeaker()
    if szCurDeviceID and szCurDeviceID ~= szDeviceID then
        GME_SelectSpeaker(nil, szDeviceID)
    end

    local szRoomID = RoomVoiceData.GetCurVoiceRoomID()
    if szRoomID and GVoiceMgr.IsInRoom(szRoomID) then
        GME_SelectSpeaker(szRoomID, szDeviceID)
    end
end

-- 获取当前扬声器设备
function GVoiceMgr.GetCurSpeaker()
    return GME_GetCurSpeaker()
end

-- 获取麦克风列表 - 设置界面用
function GVoiceMgr.GetMicListForSetting()
    local tList = {}
    local tMicList = GVoiceMgr.GetMicList() or {}
    for _, info in ipairs(tMicList) do
        table.insert(
            tList,
            {
                szDec = info.szDeviceName,
                szDeviceID = info.szDeviceID,
                fnFunc = function()
                    GVoiceMgr.SelectMic(info.szDeviceID)
                end
            }
        )
    end

    return tList
end

-- 获取扬声器列表 - 设置界面用
function GVoiceMgr.GetSpeakerListForSetting()
    local tList = {}
    local tSpeakerList = GVoiceMgr.GetSpeakerList() or {}
    for _, info in ipairs(tSpeakerList) do
        table.insert(
            tList,
            {
                szDec = info.szDeviceName,
                szDeviceID = info.szDeviceID,
                fnFunc = function()
                    GVoiceMgr.SelectSpeaker(info.szDeviceID)
                end
            }
        )
    end

    return tList
end

-- 获取当前麦克风设备名称
function GVoiceMgr.GetCurMicName()
    local szDeviceID, szDeviceName = GVoiceMgr.GetCurMic()
    return szDeviceName or ""
end

-- 获取当前扬声器设备
function GVoiceMgr.GetCurSpeakerName()
    local szDeviceID, szDeviceName = GVoiceMgr.GetCurSpeaker()
    return szDeviceName or ""
end

 function GVoiceMgr.IsCurMic(tCompareInfo)
     local szDeviceID, szDeviceName = GVoiceMgr.GetCurMic()
     return szDeviceID and szDeviceID == tCompareInfo.szDeviceID
 end

 function GVoiceMgr.IsCurSpeaker(tCompareInfo)
     local szDeviceID, szDeviceName = GVoiceMgr.GetCurSpeaker()
     return szDeviceID and szDeviceID == tCompareInfo.szDeviceID
 end

































-- 团队语音 + 麦克风
function GVoiceMgr.OpenSpeakerAndMic()
    if not TeamData.IsInParty() then return end
    --if not self.IsInRoom() then return end

    if Platform.IsWindows() then
        if not self.IsMicAvail() then
            TipsHelper.ShowNormalTip(g_tStrings.GVOICE_MIC_UNAVIAL_STATE_TIP)
            return
        end
    else
        if not Permission.CheckPermission(Permission.Microphone) then
            if Permission.CheckHasAsked(Permission.Microphone) then
                Permission.AskForSwitchToAppPermissionSetting(Permission.Microphone)
                return
            else
                Permission.RequestUserPermission(Permission.Microphone)
                Event.Reg(self, "OnRequestPermissionCallback", function(nPermission, bResult)
                    if nPermission == Permission.Microphone then
                        Event.UnReg(self, "OnRequestPermissionCallback")
                        if bResult then
                            GVoiceMgr.OpenSpeakerAndMic()
                        end
                    end
                end)
                return
            end
        end

        -- if not Permission.CheckPermission(Permission.Microphone) then
        --     TipsHelper.ShowNormalTip(g_tStrings.GVOICE_MIC_UNAVIAL_STATE_TIP)
        --     return
        -- end
    end

    if self.GetSpeakerState() ~= SPEAKER_STATE.OPEN or self.bForceSwitchSpeakerAndMic then
        self.OpenSpeaker()
        self.SetSpeakerState(SPEAKER_STATE.OPEN)
    end

    if self.GetMicState() ~= MIC_STATE.OPEN or self.bForceSwitchSpeakerAndMic then
        local bResult = self.OpenMic()
        if bResult then
            self.SetMicState(MIC_STATE.OPEN)
        end
    end
end

-- 是否是 团队语音 + 麦克风
function GVoiceMgr.IsOpenSpeakerAndMic()
    local bSpeakerFlag = self.GetSpeakerState() == SPEAKER_STATE.OPEN
    local bMicFlag = self.GetMicState() == MIC_STATE.OPEN
    return bSpeakerFlag and bMicFlag
end

-- 仅团队语音
function GVoiceMgr.OpenSpeakerCloseMic()
    if not TeamData.IsInParty() then return end
    --if not self.IsInRoom() then return end

    if self.GetSpeakerState() ~= SPEAKER_STATE.OPEN or self.bForceSwitchSpeakerAndMic then
        self.OpenSpeaker()
        self.SetSpeakerState(SPEAKER_STATE.OPEN)
    end

    if self.GetMicState() == MIC_STATE.OPEN or self.bForceSwitchSpeakerAndMic then
        self.CloseMic()
        self.SetMicState(MIC_STATE.CLOSE)
    end
end

-- 是否是 仅团队语音
function GVoiceMgr.IsOpenSpeakerCloseMic()
    local bSpeakerFlag = self.GetSpeakerState() == SPEAKER_STATE.OPEN
    local bMicFlag = self.GetMicState() ~= MIC_STATE.OPEN
    return bSpeakerFlag and bMicFlag
end

-- 关闭所有
function GVoiceMgr.CloseSpeakerAndMic()
    if not TeamData.IsInParty() then return end
    --if not self.IsInRoom() then return end

    if self.GetSpeakerState() == SPEAKER_STATE.OPEN or self.bForceSwitchSpeakerAndMic then
        self.CloseSpeaker()
        self.SetSpeakerState(SPEAKER_STATE.CLOSE)
    end

    if self.GetMicState() == MIC_STATE.OPEN or self.bForceSwitchSpeakerAndMic then
        self.CloseMic()
        self.SetMicState(MIC_STATE.CLOSE)
    end

    GVoiceMgr.VOIP_Off()
end

-- 是否是 关闭所有
function GVoiceMgr.IsCloseSpeakerAndMic()
    local bSpeakerFlag = self.GetSpeakerState() == SPEAKER_STATE.CLOSE
    local bMicFlag = self.GetMicState() == MIC_STATE.CLOSE
    return bSpeakerFlag and bMicFlag
end


function GVoiceMgr.GetPlayerTeamIdentify()
    local hTeamClient = GetClientTeam()
    if not hTeamClient then
        return 0
    end
    return hTeamClient.dwTeamID * 1024 + GetCenterID()
end

--进房函数是否应该被执行
function GVoiceMgr.IsJoinRoomShouldBeExecuted()
    local nNow = GetTickCount()
    if self.nLastTryJoinRoomTime then
        if (nNow - self.nLastTryJoinRoomTime) <= 0 then
            return false
        end
    end

    self.nLastTryJoinRoomTime = nNow

    if self.bApplyJoinTeamRoom then
        return false
    end

    local hTeamClient = GetClientTeam()
    local hPlayer = GetClientPlayer()
    if not hTeamClient or not hPlayer then
        return false
    end

    if not hTeamClient.IsPlayerInTeam(hPlayer.dwID) then
        return false
    end

    local szRoomID = GVoiceMgr.GetPlayerTeamIdentify()
    if szRoomID == 0 then
        return false
    end

    if self.IsInRoom() then
        if self.nCurTeamIdentifty ~= szRoomID then
            self.ExitRoom(true)
        end
        return false
    end

    if self.nCurTeamIdentifty == szRoomID then
        return false
    end

    return true
end

function GVoiceMgr.GetCurRoomID()
    return self.szCurRoomID
end






































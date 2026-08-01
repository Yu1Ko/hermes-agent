-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: RoomVoiceData
-- Date: 2025-05-22 14:32:58
-- Desc: ?
-- ---------------------------------------------------------------------------------
local MAX_RECORD_COUNT = 20
local MAX_LIKE_COUNT = 10
local MAX_VOLUME = 150

RoomVoiceData = RoomVoiceData or {className = "RoomVoiceData"}
local self = RoomVoiceData
RoomVoiceData.PLAYER_VOICE_ROO_STATE = {
    InMyOwnRoom = 1,--在自己创建的房间
    InOtherRoom = 2,--在他人房间
    OwnRoomButNotInAnyRoom = 3,--有自己创建的房间但不在任何房间
}

-- 房间信息申请队列管理
local ROOM_APPLY_BATCH_SIZE = 60  -- 每批申请的房间数量
local ROOM_APPLY_INTERVAL = 1.1     -- 申请间隔（秒）
local ROOM_APPLY_MAX_PER_SECOND = 16 -- 每秒最大申请数

local tbHotRankImg = {
    [1] = function(dwPopularity)
        if dwPopularity >= 0 and dwPopularity <= 999 then
            return "UIAtlas2_VoiceRoom_VoiceRoom1_img_heat01"
        end
    end,
    [2] = function(dwPopularity)
        if dwPopularity >= 1000 and dwPopularity <= 2999 then
            return "UIAtlas2_VoiceRoom_VoiceRoom1_img_heat02"
        end
    end,
    [3] = function(dwPopularity)
        if dwPopularity >= 3000 then
            return "UIAtlas2_VoiceRoom_VoiceRoom1_img_heat03"
        end
    end,
}
-------------------------------- 消息定义 --------------------------------
RoomVoiceData.Event = {}
RoomVoiceData.Event.XXX = "RoomVoiceData.Msg.XXX"

function RoomVoiceData.Init()
    self._registerEvent()
    self.InitApplyQueue()
end

function RoomVoiceData.UnInit()
    -- 清理成员列表缓存
    self._tbMemberListCache = nil
    self.ClearApplyQueue()
end

function RoomVoiceData.OnLogin()

end

function RoomVoiceData.OnFirstLoadEnd()

end


-- 初始化申请队列
function RoomVoiceData.InitApplyQueue()
    self.tbApplyQueue = {}      -- 待申请的房间ID队列
    self.bApplyProcessing = false -- 是否正在处理申请
    self.nApplyTimerID = nil    -- 申请定时器ID
    self.tbPendingRooms = {}    -- 正在申请中的房间（避免重复申请）
end

-- 清理申请队列
function RoomVoiceData.ClearApplyQueue()
    if self.nApplyTimerID then
        Timer.DelTimer(self, self.nApplyTimerID)
        self.nApplyTimerID = nil
    end
    self.tbApplyQueue = nil
    self.bApplyProcessing = false
    self.tbPendingRooms = nil
end

-- 添加房间到申请队列
function RoomVoiceData.AddRoomsToApplyQueue(tbRoomIDs, bHighPriority)
    if not tbRoomIDs or #tbRoomIDs == 0 then
        return
    end

    if not self.tbApplyQueue then
        self.InitApplyQueue()
    end

    local tbNewRooms = {}
    for _, szRoomID in ipairs(tbRoomIDs) do
        if szRoomID and szRoomID ~= '0' and
           not self.IsRoomInQueue(szRoomID) and
           not self.tbPendingRooms[szRoomID] then
            table.insert(tbNewRooms, szRoomID)
        end
    end

    if #tbNewRooms == 0 then
        return
    end

    if bHighPriority then
        for i = #tbNewRooms, 1, -1 do
            table.insert(self.tbApplyQueue, 1, tbNewRooms[i])
        end
    else
        for _, szRoomID in ipairs(tbNewRooms) do
            table.insert(self.tbApplyQueue, szRoomID)
        end
    end

    self.ProcessApplyQueue()
end

-- 检查房间是否已在队列中
function RoomVoiceData.IsRoomInQueue(szRoomID)
    if not self.tbApplyQueue then
        return false
    end
    for _, roomID in ipairs(self.tbApplyQueue) do
        if roomID == szRoomID then
            return true
        end
    end
    return false
end

-- 处理申请队列
function RoomVoiceData.ProcessApplyQueue()
    if self.bApplyProcessing or not self.tbApplyQueue or #self.tbApplyQueue == 0 then
        return
    end

    self.bApplyProcessing = true
    self.ProcessNextBatch()

    if #self.tbApplyQueue > 0 then
        self.nApplyTimerID = Timer.AddCycle(self, ROOM_APPLY_INTERVAL, function()
            self.ProcessNextBatch()
            if #self.tbApplyQueue == 0 then
                Timer.DelTimer(self, self.nApplyTimerID)
                self.nApplyTimerID = nil
                self.bApplyProcessing = false
            end
        end)
    else
        self.bApplyProcessing = false
    end
end

function RoomVoiceData.ProcessNextBatch()
    if not self.tbApplyQueue or #self.tbApplyQueue == 0 then
        return
    end

    local nBatchSize = math.min(ROOM_APPLY_BATCH_SIZE, #self.tbApplyQueue)
    local tbCurrentBatch = {}

    for i = 1, nBatchSize do
        local szRoomID = table.remove(self.tbApplyQueue, 1)
        if szRoomID then
            table.insert(tbCurrentBatch, szRoomID)
            self.tbPendingRooms[szRoomID] = true
        end
    end

    for _, szRoomID in ipairs(tbCurrentBatch) do
        self.ApplyVoiceRoomInfoWithCallback(szRoomID, function()
            self.tbPendingRooms[szRoomID] = nil
            -- 更新推荐数据缓存
            self.tbRecommendData[szRoomID] = self.GetVoiceRoomInfo(szRoomID) or {}
        end)
    end
end

-- 带回调的房间信息申请
function RoomVoiceData.ApplyVoiceRoomInfoWithCallback(szRoomID, fnCallback)
    local VoiceRoomClient = GetVoiceRoomClient()
    if not VoiceRoomClient or szRoomID == '0' then
        if fnCallback then fnCallback() end
        return
    end

    RoomVoiceData.ApplyVoiceRoomInfo(szRoomID)
    if fnCallback then fnCallback() end
end

function RoomVoiceData.ApplyTopPopularityVoiceRoom()
    local VoiceRoomClient = GetVoiceRoomClient()
    if not VoiceRoomClient then
        return
    end
    VoiceRoomClient.ApplyTopPopularityVoiceRoom()
end

-- tbRoomList = {"roomid1", "roomid2", "0", "roomid3", "roomid4"}
-- "0" 分隔符之前为语音推荐房间，之后为直播推荐房间
function RoomVoiceData.OnGetTopPopularityVoiceRoom(tbRoomList)
    self.tbRecommendData = {}
    self.tbRecommendList = {}
    self.tbLiveStreamRecommendList = {}

    if self.nApplyTimerID then
        Timer.DelTimer(self, self.nApplyTimerID)
        self.nApplyTimerID = nil
    end
    self.bApplyProcessing = false

    if not tbRoomList or #tbRoomList == 0 then
        return
    end

    -- 以 "0" 为分隔符拆分语音推荐和直播推荐
    local tbVoiceList = {}
    local tbLiveList = {}
    local bFoundSplit = false
    for _, szRoomID in ipairs(tbRoomList) do
        if szRoomID == "0" then
            bFoundSplit = true
        elseif not bFoundSplit then
            table.insert(tbVoiceList, szRoomID)
        else
            table.insert(tbLiveList, szRoomID)
        end
    end

    self.tbRecommendList = tbVoiceList
    self.tbLiveStreamRecommendList = tbLiveList

    if #tbVoiceList > 0 then
        self.AddRoomsToApplyQueue(tbVoiceList, false)
    end
    if #tbLiveList > 0 then
        self.AddRoomsToApplyQueue(tbLiveList, false)
    end
end

function RoomVoiceData.GetTopPopularityVoiceRoom()
    return self.tbRecommendList or {}
end

function RoomVoiceData.GetTopPopularityLiveStream()
    return self.tbLiveStreamRecommendList or {}
end

function RoomVoiceData.GetTopVoiceRoomInfo(szRoomID)
    return self.tbRecommendData[szRoomID] or {}
end

function RoomVoiceData.ApplyRoomList()
    local VoiceRoomClient = GetVoiceRoomClient()
    if not VoiceRoomClient then
        return
    end
    VoiceRoomClient.ApplyRoleVoiceRoomList()
end

function RoomVoiceData.GetRoleVoiceRoomList()
    local VoiceRoomClient = GetVoiceRoomClient()
    if not VoiceRoomClient then
        return
    end
    local szMyRoomID, szCurrentRoomID = VoiceRoomClient.GetRoleVoiceRoomList()
    return szMyRoomID, szCurrentRoomID
end

function RoomVoiceData.GetCurVoiceRoomID()
    local VoiceRoomClient = GetVoiceRoomClient()
    if not VoiceRoomClient then
        return
    end

    local _, szCurrentRoomID = VoiceRoomClient.GetRoleVoiceRoomList()
    if szCurrentRoomID ~= "0" then
        return szCurrentRoomID
    end
end

function RoomVoiceData.ApplyVoiceRoomInfo(szRoomID)
    local VoiceRoomClient = GetVoiceRoomClient()
    if not VoiceRoomClient then
        return
    end
    if szRoomID ~= '0' then
        VoiceRoomClient.ApplyVoiceRoomInfo(szRoomID)
    end
end

function RoomVoiceData.DelayApplyVoiceRoomInfo(szRoomID)
    if not self.tbApplyRoomInfoTimer then
        self.tbApplyRoomInfoTimer = {}
    end
    if self.tbApplyRoomInfoTimer[szRoomID] then
        Timer.DelTimer(self, self.tbApplyRoomInfoTimer[szRoomID])
    end
    self.tbApplyRoomInfoTimer[szRoomID] = Timer.AddFrame(self, 2, function()
        self.tbApplyRoomInfoTimer[szRoomID] = nil
        self.ApplyVoiceRoomInfo(szRoomID)
    end)
end

function RoomVoiceData.GetVoiceRoomInfo(szRoomID)
    if not szRoomID or szRoomID == '0' then
        return
    end

    local VoiceRoomClient = GetVoiceRoomClient()
    if not VoiceRoomClient then
        return
    end
    return VoiceRoomClient.GetVoiceRoomInfo(szRoomID)
end


function RoomVoiceData.ApplyVoiceRoomMemberList(szRoomID)
    local VoiceRoomClient = GetVoiceRoomClient()
    if not VoiceRoomClient then
        return
    end
    VoiceRoomClient.ApplyVoiceRoomMemberList(szRoomID)

    if self._tbMemberListCache and self._tbMemberListCache[szRoomID] then
        self._tbMemberListCache[szRoomID] = nil
    end
end

function RoomVoiceData.SetVoiceRoomAdmin(szRoomID, szGlobalID, bAdmin)
    local VoiceRoomClient = GetVoiceRoomClient()
    if not VoiceRoomClient then
        return
    end
    VoiceRoomClient.SetVoiceRoomAdmin(szRoomID, szGlobalID, bAdmin)
end

function RoomVoiceData.GetAdminList(szRoomID)
    local VoiceRoomClient = GetVoiceRoomClient()
    if not VoiceRoomClient then
        return
    end
    return VoiceRoomClient.GetAdminList(szRoomID)
end

function RoomVoiceData.CheckMemberList(szRoomID, tbMemberList)
    local tbInfo = RoomVoiceData.GetVoiceRoomInfo(szRoomID)
    local tbGloabalIDList = {}
    local tbAdmin = RoomVoiceData.GetAdminList(szRoomID)
    table.insert_tab(tbGloabalIDList, tbAdmin)
    table.insert(tbGloabalIDList, tbInfo.szMasterID)
    for nIndex = #tbGloabalIDList, 1, -1 do
        local szGlobalID = tbGloabalIDList[nIndex]
        local bFind = false
        for index, tbInfo in ipairs(tbMemberList) do
            if tbInfo.szGlobalID == szGlobalID then
                bFind = true
                break
            end
        end
        if bFind then
            table.remove(tbGloabalIDList, nIndex)
        end
    end
    for nIndex, globalid in ipairs(tbGloabalIDList) do
        local tbInfo = {
            szGlobalID = globalid,
            bEnableMic = false,
            szGVoiceID = nil,
            bIsAdmin = true,
            bNotOnline = true,
        }
        table.insert(tbMemberList, 1, tbInfo)
    end
end

function RoomVoiceData.GetVoiceRoomMemberList(szRoomID)
    local VoiceRoomClient = GetVoiceRoomClient()
    if not VoiceRoomClient then
        return
    end

    -- 检查缓存，避免重复获取和排序
    if not self._tbMemberListCache then
        self._tbMemberListCache = {}
    end

    local tbCachedData = self._tbMemberListCache[szRoomID]
    local nCurrentTime = GetCurrentTime()

    -- 如果缓存存在且未过期（1秒内），直接返回缓存数据
    if tbCachedData and tbCachedData.nCacheTime and (nCurrentTime - tbCachedData.nCacheTime) < 1 then
        return clone(tbCachedData.tbMemberList) -- 返回副本避免外部修改
    end

    local tbMemberList = VoiceRoomClient.GetVoiceRoomMemberList(szRoomID)
    self.CheckMemberList(szRoomID, tbMemberList)

    if tbMemberList and  #tbMemberList > 0 then
        local tbRoomInfo = RoomVoiceData.GetVoiceRoomInfo(szRoomID)
        local tbAdminList = RoomVoiceData.GetAdminList(szRoomID)
        local szOwnerID = tbRoomInfo and tbRoomInfo.szMasterID or ""

        for _, tbMember in ipairs(tbMemberList) do
            local nPriority = 0
            local szGlobalID = tbMember.szGlobalID

            -- 权限优先级
            if szGlobalID == szOwnerID then
                nPriority = 3
            elseif tbAdminList and table.contain_value(tbAdminList, szGlobalID) then
                nPriority = 2
            end

            -- 麦克风状态优先级
            if tbMember.bEnableMic then
                nPriority = nPriority + 1
            end

            tbMember._nSortPriority = nPriority
        end

        table.sort(tbMemberList, function(a, b)
            return a._nSortPriority > b._nSortPriority
        end)
    end

    -- 缓存结果
    self._tbMemberListCache[szRoomID] = {
        tbMemberList = clone(tbMemberList),
        nCacheTime = nCurrentTime
    }

    return tbMemberList
end

function RoomVoiceData.GetVoiceMemberInfo(szRoomID, szGlobalID)
    local VoiceRoomClient = GetVoiceRoomClient()
    if not VoiceRoomClient then
        return
    end
    return VoiceRoomClient.GetVoiceMemberInfo(szRoomID, szGlobalID)
end

function RoomVoiceData.GetMaxPeopleNum(szRoomID)
    local tbInfo = self.GetVoiceRoomInfo(szRoomID)
    if not tbInfo then return 0 end

    local nCurrentTime = GetCurrentTime()
    local nRemainTime = 0
    if tbInfo.nSuperRoomTime > nCurrentTime then
        nRemainTime = tbInfo.nSuperRoomTime - nCurrentTime
    end
    local nLevelNum = GDAPI_VoiceRoomLvUpCost(tbInfo.nRoomLevel).num
    local nVIPNum = GDAPI_VoiceRoomSuperCost().num
    if nRemainTime > 0 then
        nLevelNum = nLevelNum + nVIPNum
    end
    return nLevelNum
end

function RoomVoiceData.CanOperateMic(szRoomID)
    local szMemberID = g_pClientPlayer.GetGlobalID()
    return self.CanMemberMic(szRoomID, szMemberID)
end

function RoomVoiceData.CanMemberMic(szRoomID, szMemberID)
    local tbInfo = self.GetVoiceMemberInfo(szRoomID, szMemberID)
    if not tbInfo then
        return false
    end
    local tbRoomInfo = self.GetVoiceRoomInfo(szRoomID)
    local nMicMode = tbRoomInfo and tbRoomInfo.nMicMode or VOICE_ROOM_MIC_MODE.INVALID
    if nMicMode == VOICE_ROOM_MIC_MODE.MASTER_MODE and not self.IsRoomOwner(szRoomID, szMemberID) then
        return false
    end

    if nMicMode == VOICE_ROOM_MIC_MODE.MANAGE_MODE and not tbInfo.bEnableMic and self.IsNormalMember(szRoomID, szMemberID) then
        return false
    end

   return true
end

function RoomVoiceData.GetVoiceRoomMemberCount(szRoomID)
    local tbMemberList = self.GetVoiceRoomMemberList(szRoomID)
    if not tbMemberList then
        return 0
    end
    return #tbMemberList
end

function RoomVoiceData.GetRoomMicModeByRoomID(szRoomID)
    local VoiceRoomClient = GetVoiceRoomClient()
    if not VoiceRoomClient then
        return
    end
    local tbInfo = RoomVoiceData.GetVoiceRoomInfo(szRoomID)
    if tbInfo then
        return tbInfo.nMicMode
    end
    return nil
end

function RoomVoiceData.IsNormalMember(szRoomID, szMemberID)
    return not self.IsRoomOwner(szRoomID, szMemberID) and not self.IsAdmin(szRoomID, szMemberID)
end

function RoomVoiceData.IsRoomOwner(szRoomID, szMemberID)
    local tbInfo = RoomVoiceData.GetVoiceRoomInfo(szRoomID)
    return tbInfo and tbInfo.szMasterID == szMemberID
end

function RoomVoiceData.CreateVoiceRoom(bPublic, szPassword, nMicMode, szRoomName, nCampLimitMask, nLevelLimit)
    local VoiceRoomClient = GetVoiceRoomClient()
    if not VoiceRoomClient then
        return
    end
    return VoiceRoomClient.CreateVoiceRoom(bPublic, szPassword, nMicMode, szRoomName, nCampLimitMask, nLevelLimit)
end

function RoomVoiceData.ChangeRoomDescription(szRoomID, szDescription)
    local VoiceRoomClient = GetVoiceRoomClient()
    if not VoiceRoomClient then
        return
    end
    return VoiceRoomClient.ModifyVoiceRoomDescription(szRoomID, szDescription)
end

function RoomVoiceData.ChangeRoomPassword(szRoomID, szPassword)
    local VoiceRoomClient = GetVoiceRoomClient()
    if not VoiceRoomClient then
        return
    end
    return VoiceRoomClient.ChangeRoomPassword(szRoomID, szPassword)
end

function RoomVoiceData.ChangeRoomDetailInfo(szRoomID, nMicMode, nCampLimitMask, nLevelLimit, bPublic)
    local VoiceRoomClient = GetVoiceRoomClient()
    if not VoiceRoomClient then
        return
    end
    return VoiceRoomClient.ChangeRoomDetailInfo(szRoomID, nMicMode, nCampLimitMask, nLevelLimit, bPublic)
end

function RoomVoiceData.ChangeRoomName(szRoomID, szRoomName)
    local VoiceRoomClient = GetVoiceRoomClient()
    if not VoiceRoomClient then
        return
    end
    if szRoomName == "" then
        TipsHelper.ShowNormalTip("房间名字不能为空")
        return
    end
    return VoiceRoomClient.ModifyVoiceRoomName(szRoomID, szRoomName)
end

function RoomVoiceData.ApplyVoiceMemberSocialInfo(tbGlobalID)
    local VoiceRoomClient = GetVoiceRoomClient()
    if not VoiceRoomClient then
        return
    end
    VoiceRoomClient.ApplyVoiceMemberSocialInfo(tbGlobalID)
end

function RoomVoiceData.GetVoiceRoomMemberSocialInfo(szGlobalID)
    local VoiceRoomClient = GetVoiceRoomClient()
    if not VoiceRoomClient then
        return
    end
    if not szGlobalID or szGlobalID == "0" then
        return
    end
    return VoiceRoomClient.GetVoiceRoomMemberSocialInfo(szGlobalID)
end

local ROLE_DEF
local m_role_id_flag
local m_role_rqsting_ids

local function on_rqst_role()
	GetVoiceRoomClient().ApplyVoiceMemberSocialInfo(m_role_rqsting_ids)
	m_role_rqsting_ids = nil
	m_role_id_flag = nil
end

local function get_def_roleinfo()
	if not ROLE_DEF then
		ROLE_DEF =
		{
			nRoleType = 0,
			nLevel = 0,
			nForceID = 0,
			nCamp = 0,
			dwMiniAvatarID = 0,
			szName = UIHelper.UTF8ToGBK("玩家"),
            dwCenterID = 0,
            bDefault = true,
		}
	end
	return ROLE_DEF
end

function RoomVoiceData.GetRoomMemberSocialInfo(id)
    local aRoleInfo = GetVoiceRoomClient().GetVoiceRoomMemberSocialInfo(id)
	if not aRoleInfo then
	    m_role_id_flag = m_role_id_flag or {}
	    if not m_role_id_flag[id] then
		    m_role_rqsting_ids = m_role_rqsting_ids or {}
		    table.insert(m_role_rqsting_ids, id)
		    m_role_id_flag[id] = true
		    Timer.Add(self, 0.5, on_rqst_role)
        end
	end
    return aRoleInfo or get_def_roleinfo()
end

function RoomVoiceData.ApplyJoinVoiceRoom(szRoomID, szRoomKey)
    local VoiceRoomClient = GetVoiceRoomClient()
    if not VoiceRoomClient then
        return
    end
    return VoiceRoomClient.ApplyJoinVoiceRoom(szRoomID, szRoomKey)
end

function RoomVoiceData.OperateMemberMic(szRoomID, szMemberID, bEnableMic)
    local VoiceRoomClient = GetVoiceRoomClient()
    if not VoiceRoomClient then
        return
    end
    return VoiceRoomClient.OperateMemberMic(szRoomID, szMemberID, bEnableMic)
end

function RoomVoiceData.OperateMemberListMic(szRoomID, tbMemberList, bEnableMic)
    if not tbMemberList then
        return
    end
    local nIndex = 1
    local function OperateNextMember()
        if nIndex > #tbMemberList then
            return
        end
        local szMemberID = tbMemberList[nIndex].szGlobalID
        if tbMemberList[nIndex].bEnableMic ~= bEnableMic then
            self.OperateMemberMic(szRoomID, szMemberID, bEnableMic)
        end
        nIndex = nIndex + 1
        Timer.AddFrame(self, 1, function()
            OperateNextMember()
        end)
    end
    OperateNextMember()
end

function RoomVoiceData.OperateAllMemberMic(szRoomID, bEnableMic)

    local tbRoomMember = self.GetVoiceRoomMemberList(szRoomID)
    if not tbRoomMember then
        return
    end
    self.OperateMemberListMic(szRoomID, tbRoomMember, bEnableMic)
end

function RoomVoiceData.KickOutVoiceRoomMember(szRoomID, szMemberID)
    local VoiceRoomClient = GetVoiceRoomClient()
    if not VoiceRoomClient then
        return
    end
    return VoiceRoomClient.KickOutVoiceRoomMember(szRoomID, szMemberID)
end

function RoomVoiceData.KickOutAllVoiceRoomMember(szRoomID)
     local nIndex = 1
    local tbRoomMember = self.GetVoiceRoomMemberList(szRoomID)
    if not tbRoomMember then
        return
    end
    local function OperateNextMember()
        if nIndex > #tbRoomMember then
            return
        end
        local szMemberID = tbRoomMember[nIndex].szGlobalID
        nIndex = nIndex + 1
        if not self.IsRoomOwner(szRoomID, szMemberID) then
            self.KickOutVoiceRoomMember(szRoomID, szMemberID)
        end
        Timer.AddFrame(self, 1, function()
            OperateNextMember()
        end)
    end
    OperateNextMember()
end

function RoomVoiceData.DisbandVoiceRoom(szRoomID)
    local VoiceRoomClient = GetVoiceRoomClient()
    if not VoiceRoomClient then
        return
    end
    return VoiceRoomClient.DisbandVoiceRoom(szRoomID)
end

function RoomVoiceData.ApplyVoiceRoomPermissionInfo(szRoomID)
    local VoiceRoomClient = GetVoiceRoomClient()
    if not VoiceRoomClient then
        return
    end
    return VoiceRoomClient.ApplyVoiceRoomPermissionInfo(szRoomID)
end

function RoomVoiceData.CreateRoomVoice(szRoomName, szPassword, bPublic, nMicMope, nCamp, nLevel)
    if not szRoomName or szRoomName == "" then
        TipsHelper.ShowNormalTip("请输入房间名称")
        return
    end

    if not UIHelper.IsAllChinese(szRoomName) then
        TipsHelper.ShowNormalTip("请输入中文名字")
        return
    end

    if not UIHelper.IsDigitOrAlpha(szPassword) then
        TipsHelper.ShowNormalTip("密码只能包含数字或字母")
        return
    end

    if not nMicMope then
        TipsHelper.ShowNormalTip("请选择麦克风模式")
        return
    end

    local szMyRoom, szCurrentRoomID = self.GetRoleVoiceRoomList()
    if szMyRoom == "0" and szCurrentRoomID ~= "0" then
        self.KickOutVoiceRoomMember(szCurrentRoomID, g_pClientPlayer.GetGlobalID())
    end

    if szMyRoom ~= '0' then
        TipsHelper.ShowNormalTip("当前已经创建了一个房间，不能创建新房间")
        return
    end

    local bSuccess = self.CreateVoiceRoom(bPublic, szPassword, nMicMope, szRoomName, nCamp, nLevel)
    if not bSuccess then
        TipsHelper.ShowNormalTip("创建房间失败")
    end
end

function RoomVoiceData.TryJoinRoom(szRoomID, bPwdRequired, fnCanCelFunc)

    local function JoinRoom()
        local tbRoomInfo = self.GetVoiceRoomInfo(szRoomID)
        if not tbRoomInfo then
            return
        end

        local bMyRoom = false
        local szMyRoomID, szCurRoom = self.GetRoleVoiceRoomList()
        if szMyRoomID and szMyRoomID == szRoomID then
            bMyRoom = true
        end

        local nCampLimitMask = tbRoomInfo.nCampLimitMask
        local nCamp = g_pClientPlayer.nCamp
        if not bMyRoom and not GetNumberBit(nCampLimitMask, nCamp + 1) then --判断是否在房间阵营限制内
            OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.GVOICE_ROOM_MIC_ERROR_CODE[VOICE_ROOM_NOTIFY_CODE.CAMP_LIMIT])
            OutputMessage("MSG_SYS", g_tStrings.GVOICE_ROOM_MIC_ERROR_CODE[VOICE_ROOM_NOTIFY_CODE.CAMP_LIMIT])
            return
        end

        if bPwdRequired and szRoomID ~= szMyRoomID  then--自己的房间不用设密码
            UIMgr.Open(VIEW_ID.PanelVoiceRoomPasswordPop, szRoomID)
        else
            RoomVoiceData.ApplyJoinVoiceRoom(szRoomID, "")
        end
    end

    local function JudgeJoinRoom()
        local nState = RoomVoiceData.GetPlayerRoomState()
        if nState == RoomVoiceData.PLAYER_VOICE_ROO_STATE.InMyOwnRoom or nState == RoomVoiceData.PLAYER_VOICE_ROO_STATE.InOtherRoom then
            local szMyRoomID, szCurRoom = self.GetRoleVoiceRoomList()
            if szCurRoom == szRoomID then--当前房间和访问房间是同一个
                self.JumpToRoomVoice()
                return
            end

            local tbInfo = self.GetVoiceRoomInfo(szCurRoom)
            if not tbInfo then
                JoinRoom()
                return
            end

            local szContent = string.format("已经在语音频道%s中，请先退出", UIHelper.GBKToUTF8(tbInfo.szRoomName))
            local script = UIHelper.ShowConfirm(szContent, function()
                self.fnExitRoomCallBack = function(szRoomID, szMemberID)
                    local nGLobalID = g_pClientPlayer.GetGlobalID()
                    if szRoomID == szCurRoom then
                        if nGLobalID == szMemberID then--自己退出房间
                            JoinRoom()
                            self.fnExitRoomCallBack = nil
                        end
                    end
                end
                self.KickOutVoiceRoomMember(szCurRoom, g_pClientPlayer.GetGlobalID())
            end, function()
                if fnCanCelFunc then fnCanCelFunc() end
            end)
            script:SetButtonContent("Confirm", "退出并继续")
            return
        end
        JoinRoom()
    end

    if not self.CheckShowAgreenText(JudgeJoinRoom, fnCanCelFunc) then
        return
    end
    JudgeJoinRoom()
end

function RoomVoiceData.JumpToRoomVoice(bShowTips, bAutoSelectedLiveTab)
    if not self.CheckCanShowRoomVoice() then
        TipsHelper.ShowNormalTip("需满级方可开启")
        return
    end

    -- 开了的话就先关掉
    if UIMgr.IsViewOpened(VIEW_ID.PanelChatSocial) then
        UIMgr.CloseImmediately(VIEW_ID.PanelChatSocial)
    end

    RoomVoiceData.bAutoSelectedLiveTab = bAutoSelectedLiveTab

    local function JumpToRoomVoice(script)
        if not script:IsSelected(5) then--是否选中妙音放
            script:Select(5)
        end
        if not self.nJumpTimer then
            self.nJumpTimer = Timer.AddFrame(self, 1, function()
                self.nJumpTimer = nil
                Event.Dispatch(EventType.BackToVoiceRoom)
            end)
        end
    end
    local script = UIMgr.GetViewScript(VIEW_ID.PanelChatSocial)
    if script then
        JumpToRoomVoice(script)
    else
        UIMgr.Open(VIEW_ID.PanelChatSocial, 5)
    end

    if bShowTips then
        TipsHelper.ShowNormalTip("侠士可以在语音聊天室界面查看当前正在直播的语音房间,\n或通过搜索功能筛选感兴趣的直播内容。")
    end
end

function RoomVoiceData.TryJoinMyOwnRoom(fnCanCelFunc)
    local szMyRoom = self.GetRoleVoiceRoomList()
    local tbInfo = self.GetVoiceRoomInfo(szMyRoom)
    if not tbInfo then
        self.fnTryJoinMyOwnRoom = function(szRoomID)
            if szRoomID == szMyRoom then
                local tbInfo = self.GetVoiceRoomInfo(szRoomID)
                self.TryJoinRoom(szRoomID, tbInfo.bPwdRequired, fnCanCelFunc)
                self.fnTryJoinMyOwnRoom = nil
            end
        end
        return
    end
    self.TryJoinRoom(szMyRoom, tbInfo.bPwdRequired, fnCanCelFunc)
end

function RoomVoiceData.ConfirmOperate(szCurRoomID, fnAction)
    if #self.tbOperateList ~= 0 then
        local szRoomID = szCurRoomID
        local tbInfo = RoomVoiceData.GetVoiceRoomInfo(szRoomID)
        -- if tbInfo.nMicMode == VOICE_ROOM_MIC_MODE.MANAGE_MODE then
            local script = UIHelper.ShowConfirm("对选中玩家进行操作", function()
                RoomVoiceData.OperateMemberListMic(szCurRoomID, self.tbOperateList, true)
                self.ClearOperateList()
                if fnAction then fnAction() end
            end, function()
                RoomVoiceData.OperateMemberListMic(szCurRoomID, self.tbOperateList, false)
                self.ClearOperateList()
                if fnAction then fnAction() end
            end)
            script:SetButtonContent("Cancel", "全部禁言")
            script:SetButtonContent("Confirm", "全部上麦")
        -- end
    else
        TipsHelper.ShowNormalTip("请选择成员")
    end
end

function RoomVoiceData.GetCanOperateListCount(szCurRoomID)
    local nCount = self.GetVoiceRoomMemberCount(szCurRoomID)
    if self.tbAdmin and self.tbAdmin[szCurRoomID] then
        nCount = nCount - #self.tbAdmin[szCurRoomID]
    end
    nCount = nCount - 1
    return nCount
end

function RoomVoiceData.AddOperateList(tbMember, szCurRoomID)
    if not self.tbOperateList then
        self.tbOperateList = {}
    end
    local nCount = self.GetOperateListCount()
    if nCount >= self.GetCanOperateListCount(szCurRoomID) then
        TipsHelper.ShowNormalTip("筛选已达到上限")
        return false
    end
    table.insert(self.tbOperateList, tbMember)
    Event.Dispatch(EventType.OnOperateListChange)
    return true
end

function RoomVoiceData.DelOperateList(tbMember)
    local bOk = false
    if self.tbOperateList then
        for nIndex, tbInfo in pairs(self.tbOperateList) do
            if tbInfo.szGlobalID == tbMember.szGlobalID then
                table.remove(self.tbOperateList, nIndex)
                bOk = true
                break
            end
        end
    end
    if bOk then
        Event.Dispatch(EventType.OnOperateListChange)
    end
end

function RoomVoiceData.GetOperateListCount()
    return self.tbOperateList and table.get_len(self.tbOperateList) or 0
end

function RoomVoiceData.IsInOperateList(tbMember)
    local bOk = false
    if self.tbOperateList then
        for nIndex, tbInfo in pairs(self.tbOperateList) do
            if tbInfo.szGlobalID == tbMember.szGlobalID then
                bOk = true
                break
            end
        end
    end
    return bOk
end


function RoomVoiceData.ClearOperateList()
    self.tbOperateList = {}
end

function RoomVoiceData.CheckCanShowRoomVoice()
    return g_pClientPlayer.nLevel >= 130
end

function RoomVoiceData.Report(szRoomID, szGlobalID)
    local tbInfo = {}
    local tbRoomInfo = RoomVoiceData.GetVoiceRoomInfo(szRoomID)
    local tbSocialInfo = RoomVoiceData.GetVoiceRoomMemberSocialInfo(szGlobalID)
    local tbMember = RoomVoiceData.GetVoiceMemberInfo(szRoomID, szGlobalID)
    tbInfo.szGVoiceID = tbMember and tbMember.szGVoiceID or 0
    tbInfo.szGlobalID = szGlobalID
    tbInfo.szRoomName = tbRoomInfo.szRoomName
    tbInfo.szName = UIHelper.GBKToUTF8(tbSocialInfo.szName)
    tbInfo.szRoomID = szRoomID
    UIMgr.Open(VIEW_ID.PanelTutorialCollection, ServiceCenterData.TabModleType.ReportVoiceRoom, tbInfo, 1)
end

function RoomVoiceData.CheckRoomCampLimitMask(nCampLimitMask)
    nCampLimitMask = nCampLimitMask or 0
    local bNeutralCanJoin = GetNumberBit(nCampLimitMask, CAMP.NEUTRAL + 1)
    local bGoodCanJoin = GetNumberBit(nCampLimitMask, CAMP.GOOD + 1)
    local bEvilCanJoin = GetNumberBit(nCampLimitMask, CAMP.EVIL + 1)
    return bNeutralCanJoin, bGoodCanJoin, bEvilCanJoin
end

function RoomVoiceData.GetHotRankImg(dwPopularity)
    for nIndex, fnCheck in pairs(tbHotRankImg) do
        local szImg = fnCheck(dwPopularity)
        if szImg then
            return szImg
        end
    end
end
------------------------------------------------------------------语音相关------------------------------------------------

--超级房间校验
function RoomVoiceData.CheckSuperRoom(szRoomID)
    local tbInfo = RoomVoiceData.GetVoiceRoomInfo(szRoomID)
    if tbInfo then
        local nCurrentTime = GetCurrentTime()
        local nRemainTime = 0
        if tbInfo.nSuperRoomTime > nCurrentTime then
            nRemainTime = tbInfo.nSuperRoomTime - nCurrentTime
        end
        return nRemainTime > 0
    end
    return false
end

----语音房间走的是子实例，团队语音即GVoiceMgr应该是主示例，两者对麦克风设备之类的操作应该相互独立互不影响
function RoomVoiceData.OpenMic(szRoomID)
    if UI_IsClientPlayerBaned() then
        OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.GVOICE_ROOM_MIC_ERROR_CODE[VOICE_ROOM_NOTIFY_CODE.BAN_JOIN_VOICE])
        return
    end

    if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TALK, "player talk") then
		return
	end

    -- 权限检查，没权限直接返回，有询问权限的先请求权限，权限结果回调里再打开麦克风
    if not Platform.IsWindows() then
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
                            RoomVoiceData.OpenMic(szRoomID)
                        end
                    end
                end)
                return
            end
        end
    end

    GME_OpenMic(szRoomID)

    if RoomVoiceData.CheckSuperRoom(szRoomID) then
        local nRoomType = GME_GetRoomType(szRoomID)
        if nRoomType == VOICE_ROOM_TYPE.FLUENCY then
            GME_ChangeRoomType(szRoomID, VOICE_ROOM_TYPE.STANDARD)
        end
    end

    if IsWLCloudClient() then
        SyncCloudAppMicState(true)
    end
    Event.Dispatch(EventType.OnGMEMicStateChanged)
end

function RoomVoiceData.IsMicOpen(szRoomID)
    return GME_IsMicOpened(szRoomID)
end

function RoomVoiceData.CloseMic(szRoomID)
    GME_CloseMic(szRoomID)
    if IsWLCloudClient() then
        SyncCloudAppMicState(false)
    end
    Event.Dispatch(EventType.OnGMEMicStateChanged)
end

function RoomVoiceData.OpenSpeaker(szRoomID)
    GME_OpenSpeaker(szRoomID)
    Event.Dispatch(EventType.OnGMESpeakerStateChanged)
end

function RoomVoiceData.IsSpeakerOpen(szRoomID)
    return GME_IsSpeakerOpened(szRoomID)
end

function RoomVoiceData.CloseSpeaker(szRoomID)
    GME_CloseSpeaker(szRoomID)
    Event.Dispatch(EventType.OnGMESpeakerStateChanged)
end

function RoomVoiceData.SetMicVolume(nVolume, szRoomID)
    GME_SetMicVolume(nVolume * MAX_VOLUME, szRoomID)
end

function RoomVoiceData.SetSpeakerVolume(nVolume, szRoomID)
    GME_SetSpeakerVolume(nVolume * MAX_VOLUME, szRoomID)
end

function RoomVoiceData.SetVoiceType(nVolume, szRoomID)
    GME_SetVoiceType(nVolume, szRoomID)
end

-- 获取正在说话人的 OpenID Map (怕刷，策略从C++获取)
function RoomVoiceData.GetSaying(szRoomID, bForceUpdate)
    -- 没有的时候取一下
    if not self.tbSaying then
        self.tbSaying = {}
    end

    if not self.tbSaying[szRoomID] or bForceUpdate then
        self.tbSaying[szRoomID] = GME_GetSayings(szRoomID)
    else
        -- 有的话定期取一下
        local nNow = GetTickCount()
        if self.nLastGetSayingTime then
            if (nNow - self.nLastGetSayingTime) > 5000 then
                self.tbSaying[szRoomID] = GME_GetSayings(szRoomID)
            end
        end
    end

    self.nLastGetSayingTime = nNow

    return self.tbSaying[szRoomID]
end

-- 获取队伍成员是否在说话
function RoomVoiceData.IsMemberSaying(szRoomID, szGVoiceID)
    local tbSaying = self.GetSaying(szRoomID, true)
    return tbSaying[szGVoiceID] ~= nil
end

function RoomVoiceData.IsMeSaying()
    local szMyRoom, szRoomID = self.GetRoleVoiceRoomList()
    if not szRoomID or szRoomID == '0' then
        return false
    end
    local tbInfo = self.GetVoiceMemberInfo(szRoomID, g_pClientPlayer.GetGlobalID())
    return tbInfo and self.IsMemberSaying(szRoomID, tbInfo.szGVoiceID)
end

function RoomVoiceData.HasMemberSaying()
    local szMyRoom, szRoomID = self.GetRoleVoiceRoomList()
    if not szRoomID or szRoomID == '0' then
        return false
    end
    local tbSaying = self.GetSaying(szRoomID, true)
    return table.get_len(tbSaying) > 0
end

function RoomVoiceData.JoinVoiceRoom(szRoomID, szSignature)
    GME_JOIN_VOICE_ROOM(szRoomID, szSignature)
    Event.Reg(self, "CLIENT_ON_JOIN_ROOM", function(szMemberID, bSuccess, szRoomID)
        Event.UnReg(self, "CLIENT_ON_JOIN_ROOM")
        self.OnGMEJoinRoom(szMemberID, bSuccess, szRoomID)
    end)
end

function RoomVoiceData.ExitRoom(szRoomID)
    GME_ExitRoom(szRoomID)
    Event.Reg(self, "CLIENT_ON_QUIT_ROOM", function(bSuccess, szRoomID)
        Event.UnReg(self, "CLIENT_ON_QUIT_ROOM")
        self.OnGMEExitRoom(bSuccess, szRoomID)
    end)
end

function RoomVoiceData.OnGMEExitRoom(bSuccess, szRoomID)
     if bSuccess then
        LOG.INFO("Exit Voice Room Success! RoomID:", szRoomID)
        self.ClearTipWaitingQueue()
    else
        LOG.INFO("Exit Voice Room Failed! RoomID:", szRoomID)
    end
end

function RoomVoiceData.OnGMEJoinRoom(szMemberID, bSuccess, szRoomID)
    if bSuccess then
        LOG.INFO("Join Voice Room Success! RoomID:", szRoomID, " MemberID:", szMemberID)
    else
        LOG.INFO("Join Voice Room Failed! RoomID:", szRoomID, " MemberID:", szMemberID)
    end

    -- 设置音量和变音相关
    local nVoiceType        = GVoiceMgr.GetVoiceType()
    local nMicVolume        = GetGameSoundSetting(SOUND.MIC_VOLUME).Slider
    local nSpeakerVolume    = GetGameSoundSetting(SOUND.SPEAKER_VOLUME).Slider

    self.SetMicVolume(nMicVolume, szRoomID)
	self.SetSpeakerVolume(nSpeakerVolume, szRoomID)
    self.SetVoiceType(nVoiceType, szRoomID)
end

function RoomVoiceData.GetSpeakerVolumeByUserID(nRoomID, szUserID)
    if not nRoomID or not szUserID then
        return 0
    end
    return GME_GetSpeakerVolumeByUserID(nRoomID, szUserID)
end

function RoomVoiceData.SetSpeakerVolumeByUserID(nRoomID, szUserID, nVolume)
    if not nRoomID or not szUserID then
        return
    end
    nVolume = math.max(nVolume, 0)
    nVolume = math.min(nVolume, MAX_VOLUME)
    GME_SetSpeakerVolumeByUserID(nRoomID, szUserID, nVolume)
end



function RoomVoiceData.HasMyOwnRoom()
    local szMyroom, szCurrentRoom = self.GetRoleVoiceRoomList()
    return szMyroom  ~= '0'
end


function RoomVoiceData.GetPlayerRoomState()
    local szMyroom, szCurrentRoom = self.GetRoleVoiceRoomList()
    local nType = nil
    if szMyroom ~= '0' and szCurrentRoom == '0' then
        nType = RoomVoiceData.PLAYER_VOICE_ROO_STATE.OwnRoomButNotInAnyRoom
    elseif szMyroom ~= '0' and szCurrentRoom == szMyroom then
        nType = RoomVoiceData.PLAYER_VOICE_ROO_STATE.InMyOwnRoom
    elseif szCurrentRoom ~= szMyroom then
        nType = RoomVoiceData.PLAYER_VOICE_ROO_STATE.InOtherRoom
    end
    return nType
end


function RoomVoiceData.IsAgreenRule()
    return Storage.RoomVoice.bAgreenRule
end

function RoomVoiceData.ChangeAgreenRule(bAgreen)
    Storage.RoomVoice.bAgreenRule = bAgreen
    Storage.RoomVoice.Flush()
    Event.Dispatch(EventType.OnAgreenRuleChanged)
end

function RoomVoiceData.CheckShowAgreenText(fnConfirm, fnCanCelFunc)
    if not self.IsAgreenRule() then
        self.ShowAgreenText(fnConfirm, fnCanCelFunc)
        return false
    end
    return true
end

function RoomVoiceData.ShowAgreenText(fnConfirm, fnCanCelFunc)
    -- UIHelper.ShowConfirm(g_tStrings.VOICE_ROOM_AGREEN_TEXT, function()
    --     self.ChangeAgreenRule(true)
    --     if fnConfirm then fnConfirm() end
    -- end
    -- , function ()
    --     if fnCanCelFunc then fnCanCelFunc() end
    -- end, true)

    UIMgr.Open(VIEW_ID.PanelVoiceRoomRulePop, fnConfirm, fnCanCelFunc)
end

function RoomVoiceData.IsAdmin(szRoomID, szGlobalID)
    if self.tbAdmin and self.tbAdmin[szRoomID]  then
        return table.contain_value(self.tbAdmin[szRoomID], szGlobalID)
    end
end


function RoomVoiceData.ON_SYNC_VOICE_PERMISSION_INFO(tbEnableMic, tbAdmin, szRoomID)
    if not self.tbEnableMic then
        self.tbEnableMic = {}
    end
    if not self.tbAdmin then
        self.tbAdmin = {}
    end
    self.tbEnableMic[szRoomID] = tbEnableMic
    self.tbAdmin[szRoomID] = tbAdmin
    self.UpdateMic(szRoomID)
    Event.Dispatch(EventType.ON_SYNC_VOICE_PERMISSION_INFO, tbEnableMic, tbAdmin, szRoomID)
end

function RoomVoiceData.AddRecord(szRoomID, szGlobalID, bIn)
    if not self.tbRecord then
        self.tbRecord = {}
    end
    if not self.tbRecord[szRoomID] then
        self.tbRecord[szRoomID] = {}
    end
    if #self.tbRecord[szRoomID] >= MAX_RECORD_COUNT then
        table.remove(self.tbRecord[szRoomID], 1)
    end
    local tbInfo = {szGlobalID = szGlobalID, bIn = bIn, nTime = GetCurrentTime()}
    table.insert(self.tbRecord[szRoomID], tbInfo)

    self.nRecordTimer = self.nRecordTimer or Timer.Add(self, 0.5, function()
        self.nRecordTimer = nil
        Event.Dispatch(EventType.ON_VOICE_ROOM_RECORD_UPDATE, self.tbRecord[szRoomID])
    end)
end

function RoomVoiceData.ClearRecord(szRoomID)
    if not self.tbRecord then
        return
    end
    self.tbRecord[szRoomID] = nil
end

function RoomVoiceData.GetRecord(szRoomID)
    if not self.tbRecord then
        return {}
    end
    return self.tbRecord[szRoomID] or {}
end

function RoomVoiceData.AddLike(szRoomID)
    local tbLikeList = Storage.RoomVoice.tbLikeList
    if not table.contain_value(tbLikeList, szRoomID) then
        if #tbLikeList >= MAX_LIKE_COUNT then
            table.remove(tbLikeList, 1)
        end
        Event.Dispatch(EventType.OnLikeRoomChanged)
        table.insert(tbLikeList, szRoomID)
        Storage.RoomVoice.Flush()
    end
end

function RoomVoiceData.DelLikeRoom(szRoomID)
    local tbLikeList = Storage.RoomVoice.tbLikeList
    local bHave = false
    for i = #tbLikeList, 1, -1 do
        if tbLikeList[i] == szRoomID then
            table.remove(tbLikeList, i)
            bHave = true
            break
        end
    end
    if bHave then
        Event.Dispatch(EventType.OnLikeRoomChanged)
        Storage.RoomVoice.Flush()
    end
end

function RoomVoiceData.IsListening(szRoomID)
    local szMyRoom, szCurRoomID = self.GetRoleVoiceRoomList()
    return szCurRoomID and szCurRoomID == szRoomID
end

function RoomVoiceData.GetLikeList()
    local tbLikeList = Storage.RoomVoice.tbLikeList or {}

    if self.nApplyTimerID then
        Timer.DelTimer(self, self.nApplyTimerID)
        self.nApplyTimerID = nil
    end
    self.bApplyProcessing = false

    if #tbLikeList > 0 then
        self.AddRoomsToApplyQueue(tbLikeList, true)
    end

    return tbLikeList
end

function RoomVoiceData.IsLikeRoom(szRoomID)
    local tbLikeList = Storage.RoomVoice.tbLikeList
    return table.contain_value(tbLikeList, szRoomID)
end


function RoomVoiceData.OnLeaveRoom(szRoomID, szMemberID)
    self.AddRecord(szRoomID, szMemberID, false)

    if szMemberID == g_pClientPlayer.GetGlobalID() then
        self.ExitRoom(szRoomID)
        self.ClearRecord(szRoomID)
        Event.Dispatch(EventType.OnMemberLeaveVoiceRoom, szRoomID, szMemberID)

        if self.tLiveStreamInfoMap then
            self.tLiveStreamInfoMap[szMemberID] = nil
        end
    else
        -- 房主离开房间时，刷新直播流信息
        local tbRoomInfo = self.GetVoiceRoomInfo(szRoomID)
        if tbRoomInfo and tbRoomInfo.szMasterID == szMemberID then
            self.ApplyLiveStreamInfo(szRoomID)
        end
    end

    if self.fnExitRoomCallBack then
        self.fnExitRoomCallBack(szRoomID, szMemberID)
    end

    self.nLeaveRoomTimer = self.nLeaveRoomTimer or Timer.Add(self, 0.2, function()
        self.nLeaveRoomTimer = nil
        Event.Dispatch(EventType.OnMemberLeaveVoiceRoom, szRoomID, szMemberID)
    end)
end

function RoomVoiceData.OnJoinRoom(szRoomID, szMemberID)
    self.AddRecord(szRoomID, szMemberID, true)
     if g_pClientPlayer.GetGlobalID() == szMemberID then
        self.JumpToRoomVoice()
        Event.Dispatch(EventType.OnMemberJoinVoiceRoom, szRoomID, szMemberID)
        return
    end

    self.nJoinRoomTimer = self.nJoinRoomTimer or Timer.Add(self, 0.2, function()
        self.nJoinRoomTimer = nil
        Event.Dispatch(EventType.OnMemberJoinVoiceRoom, szRoomID, szMemberID)
    end)

    RoomVoiceData.PlayMemberJoinBeep(szRoomID, szMemberID)
    RoomVoiceData.UpdateAdminSocialInfo(szRoomID, szMemberID)
end

function RoomVoiceData.OnOpenMic(szRoomID, szMemberID)
     Event.Dispatch(EventType.OnMemberMicStateChanged, szRoomID, szMemberID, true)
end

function RoomVoiceData.UpdateMic(szRoomID)
     if not self.CanOperateMic(szRoomID) and self.IsMicOpen(szRoomID) then
        self.CloseMic(szRoomID)
    end
end

function RoomVoiceData.OnDisableMic(szRoomID, szMemberID)
    if szMemberID == g_pClientPlayer.GetGlobalID() then
        self.UpdateMic(szRoomID)
    end
    Event.Dispatch(EventType.OnMemberMicStateChanged, szRoomID, szMemberID, false)
end

function RoomVoiceData.DelayApplyVoiceRoomPermissionInfo(szRoomID)
    if self.nDelayApplyPermissionTimer then
        Timer.DelTimer(self, self.nDelayApplyPermissionTimer)
    end
    self.nDelayApplyPermissionTimer = Timer.AddFrame(self, 2, function()
        self.ApplyVoiceRoomPermissionInfo(szRoomID)
    end)
end

function RoomVoiceData.OnSetAdmin(szRoomID, szMemberID)
    self.DelayApplyVoiceRoomPermissionInfo(szRoomID)--延迟拉取Permission数据，防止拉取过于频繁
end

function RoomVoiceData.OnUnSetAdmin(szRoomID, szMemberID)
    self.DelayApplyVoiceRoomPermissionInfo(szRoomID)
end

function RoomVoiceData.TalkToVoiceRoom(bEnter)
    local player = GetClientPlayer()
    if player then
        if bEnter then
            local tText = {{type = "text", text = UIHelper.UTF8ToGBK(g_tStrings.GVOICE_ROOM_ENTER_TALK)}}
            Player_Talk(player, PLAYER_TALK_CHANNEL.VOICE_ROOM, "", tText)
        else
            -- local tText = {{type = "text", text = g_tStrings.GVOICE_ROOM_LEAVE_TALK}}
            -- Player_Talk(player, PLAYER_TALK_CHANNEL.VOICE_ROOM, "", tText)
        end
    end
end

function RoomVoiceData.GetRoomSkinPath(nLevel, nRemainTime)
    local nIndex = 0
    if nRemainTime > 0 then
        nIndex = 2
    elseif nLevel > 0 then
        nIndex = 1
    end

	local tLine = g_tTable.VoiceRoomSkin:Search(nIndex)
	return tLine
end

-- 进入帮会领地弹语音房间
local TIP_VOICE_POPULARITY = 0
function RoomVoiceData.OpenTongVoiceRoom(szRoomID)
    RoomVoiceData.szApplyTongRoomID = szRoomID

    local tRoomInfo = RoomVoiceData.GetVoiceRoomInfo(szRoomID)
    if not tRoomInfo then
        RoomVoiceData.ApplyVoiceRoomInfo(szRoomID)
        return
    end

    RoomVoiceData.szApplyTongRoomID = nil
    if tRoomInfo.dwPopularity >= TIP_VOICE_POPULARITY then
        RoomVoiceData.ApplyVoiceRoomInfo(szRoomID) -- 打开前重新apply一次，以防长时间没有更新错判bPwdRequired
        UIHelper.ShowConfirm(g_tStrings.GVOICE_ROOM_TONGVOICE_CONFIRM, function()
            local tNewRoomInfo = RoomVoiceData.GetVoiceRoomInfo(szRoomID)
            RoomVoiceData.TryJoinRoom(szRoomID, tNewRoomInfo.bPwdRequired)
        end)
    end
end

function RoomVoiceData._registerEvent()
    Event.Reg(self, "VOICE_ROOM_ERROR", function(nCode)
        if arg0 == VOICE_ROOM_NOTIFY_CODE.SUCCESS then
            OutputMessage("MSG_ANNOUNCE_YELLOW", g_tStrings.GVOICE_ROOM_MIC_OPT_SUCCESS)
        elseif g_tStrings.GVOICE_ROOM_MIC_ERROR_CODE[nCode] then
            OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.GVOICE_ROOM_MIC_ERROR_CODE[nCode])
        end
        if nCode == VOICE_ROOM_NOTIFY_CODE.ROLE_BAN_ONLINE then
            UIMgr.Open(VIEW_ID.PanelLingLongMiBao, SAFE_LOCK_EFFECT_TYPE.TALK)--聊天锁没解
        end
    end)

    Event.Reg(self, "SYNC_VOICE_PERMISSION_INFO", function(tbEnableMic, tbAdmin, szRoomID)
        self.ON_SYNC_VOICE_PERMISSION_INFO(tbEnableMic, tbAdmin, szRoomID)
    end)

    Event.Reg(self, "VOICE_ROOM_MEMBER_CHANGE", function(szRoomID, szMemberID, bChangeType)
        if bChangeType == VOICE_ROOM_MEMBER_CHANGE_CODE.LEAVE_ROOM then--有人退出房间
            self.OnLeaveRoom(szRoomID, szMemberID)
        elseif bChangeType == VOICE_ROOM_MEMBER_CHANGE_CODE.JOIN_ROOM then--有人加入房间
            self.OnJoinRoom(szRoomID, szMemberID)
        elseif bChangeType == VOICE_ROOM_MEMBER_CHANGE_CODE.ENABLE_MIC then--有人上麦
            self.OnOpenMic(szRoomID, szMemberID)
        elseif bChangeType == VOICE_ROOM_MEMBER_CHANGE_CODE.DISABLE_MIC then--有人下麦
            self.OnDisableMic(szRoomID, szMemberID)
        elseif bChangeType == VOICE_ROOM_MEMBER_CHANGE_CODE.SET_ADMIN then
            self.OnSetAdmin(szRoomID, szMemberID)
        elseif bChangeType == VOICE_ROOM_MEMBER_CHANGE_CODE.UNSET_ADMIN then
            self.OnUnSetAdmin(szRoomID, szMemberID)
        end
    end)

    Event.Reg(self, "SYNC_VOICE_ROOM_INFO", function(szRoomID, bRoomExist)
        self.UpdateMic(szRoomID)
        if self.fnTryJoinMyOwnRoom then self.fnTryJoinMyOwnRoom(szRoomID) end
        Event.Dispatch(EventType.ON_SYNC_VOICE_ROOM_INFO, szRoomID, bRoomExist)


        if not self.tbRecommendData then
            self.tbRecommendData = {}
        end


        local tbRoomInfo = self.GetVoiceRoomInfo(szRoomID)
        self.tbRecommendData[szRoomID] = tbRoomInfo or {}

        if self.tbRecommendData[szRoomID] and table.is_empty(self.tbRecommendData[szRoomID]) then
            self.nDelayUpdateTopList = self.nDelayUpdateTopList or Timer.Add(self, 0.5, function()
                Event.Dispatch(EventType.OnNeedToUpdateTopRecommendList)
                self.nDelayUpdateTopList = nil
            end)
        end

        if RoomVoiceData.szApplyTongRoomID and szRoomID == RoomVoiceData.szApplyTongRoomID then
            local tRoomInfo = RoomVoiceData.GetVoiceRoomInfo(szRoomID)
            if not tRoomInfo then
                RoomVoiceData.OpenTongVoiceRoom(szRoomID)
                return
            end
            RoomVoiceData.szApplyTongRoomID = nil
            if tRoomInfo.dwPopularity >= TIP_VOICE_POPULARITY then
                UIHelper.ShowConfirm(g_tStrings.GVOICE_ROOM_TONGVOICE_CONFIRM, function()
                    RoomVoiceData.TryJoinRoom(szRoomID, tRoomInfo.bPwdRequired)
                end)
            end
        end
    end)

    Event.Reg(self, "JOIN_VOICE_ROOM", function(szRoomID, szSignature, bCreateRoom, bIsTeamRoom)
        if bIsTeamRoom then
            return
        end

        -- 创建房间也要有个进入的记录
        if bCreateRoom then
            local tbInfo = RoomVoiceData.GetVoiceRoomInfo(szRoomID)
            local szMasterID = tbInfo and tbInfo.szMasterID or ""
            if not string.is_nil(szMasterID) then
                if szMasterID == g_pClientPlayer.GetGlobalID() then
                    self.AddRecord(szRoomID, szMasterID, true)
                end
            end
        end

        --房间列表更新
        self.JoinVoiceRoom(szRoomID, szSignature)
        Event.Dispatch(EventType.ON_JOIN_VOICE_ROOM, szRoomID, szSignature, bCreateRoom, bIsTeamRoom)
        RoomVoiceData.TalkToVoiceRoom(true)
    end)

    Event.Reg(self, "SYNC_ROLE_VOICE_ROOM_LIST", function()
        Event.Dispatch(EventType.ON_SYNC_ROLE_VOICE_ROOM_LIST)
    end)

    Event.Reg(self, "DISBAND_VOICE_ROOM", function(szRoomID)
        self.ExitRoom(szRoomID)
        self.ClearRecord(szRoomID)
    end)

    -- 同步直播流信息
    Event.Reg(self, "ON_SYNC_LIVE_STREAM_INFO", function(szGlobalID, nMapID, bInLiveMap)
        if not self.tLiveStreamInfoMap then
            self.tLiveStreamInfoMap = {}
        end
        self.tLiveStreamInfoMap[szGlobalID] = {nMapID = nMapID, bInLiveMap = bInLiveMap}
        Event.Dispatch(EventType.ON_LIVE_STREAM_INFO_UPDATE)
    end)

    -- 同步直播副本角色列表（观众/主播等按类型分类）
    Event.Reg(self, "ON_SYNC_LIVE_STREAM_MAP_ROLE_LIST", function(nMemberType, tbGlobalIDs)
        if not self.tLiveStreamMapRoleList then
            self.tLiveStreamMapRoleList = {}
        end
        self.tLiveStreamMapRoleList[nMemberType] = tbGlobalIDs or {}
        Event.Dispatch(EventType.ON_LIVE_STREAM_INFO_UPDATE)
    end)

    -- 副本观战申请响应
    Event.Reg(self, "ON_APPLY_DUNGEON_OB_RESPOND", function(dwMapID, nCopyIndex, nResultCode)
        Log("RoomVoiceData ON_APPLY_DUNGEON_OB_RESPOND: dwMapID = ".. dwMapID.. ", nCopyIndex = ".. nCopyIndex.. ", nResultCode = ".. nResultCode)
        if nResultCode == 1 then
            local nCountTime = 30
            local bEnterOBTriggered = false
            local fnEnterOB = function()
                if bEnterOBTriggered then
					return
				end
                bEnterOBTriggered = true
                RemoteCallToServer("On_Dungeon_EnterOB", true, g_pClientPlayer.GetGlobalID(), dwMapID, nCopyIndex)
            end
            local szContent = g_tStrings.STR_ROOM_OWNER_JOINMAP_CONFIRM
            local scriptView = UIHelper.ShowConfirm(szContent, fnEnterOB)
            scriptView:SetConfirmNormalCountDownWithCallback(nCountTime, fnEnterOB)
        else
            if g_tStrings.tOBDungeonErrorResult[nResultCode] then
				OutputMessage("MSG_ANNOUNCE_RED",g_tStrings.tOBDungeonErrorResult[nResultCode])
			end
        end
    end)

    -- 副本观战确认响应
    Event.Reg(self, "ON_CONFIRM_DUNGEON_OB_RESPOND", function(nResultCode)
        Log("RoomVoiceData ON_CONFIRM_DUNGEON_OB_RESPOND: nResultCode = " .. tostring(nResultCode))
        if not nResultCode then
            OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_OBDUNGEON_ENTER_CONFIRM_FAILED)
        end
    end)

    Event.Reg(self, EventType.OnRemoteBanInfoUpdate, function(nBanChatEndTime, nBanShowCardOperateEndTime)
        -- 游戏中途被禁言，强制关麦
        if UI_IsClientPlayerBaned() then
            local szRoomID = RoomVoiceData.GetCurVoiceRoomID()
            if RoomVoiceData.IsMicOpen(szRoomID) then
                LOG.INFO("RoomVoiceData.EventType.OnRemoteBanInfoUpdate, close mic, szRoomID = %s", szRoomID)
                RoomVoiceData.CloseMic(szRoomID)
            end
            return
        end
    end)
end

-- 获取有效的 dwCenterID，优先使用语音房间数据，无效时使用好友系统数据
-- @param szGlobalID: 玩家的 GlobalID
-- @return dwCenterID: 有效的 CenterID，如果都无效则返回 0
-- @return bIsDefault: 是否为默认值（需要等待异步请求）
-- @return szSource: 数据来源 "voice_room" | "fellowship" | "default"
function RoomVoiceData.GetValidCenterID(szGlobalID)
    if not szGlobalID or szGlobalID == "0" then
        return 0, true, "invalid"
    end

    -- 1. 优先尝试从语音房间社交信息获取
    local tbSocialInfo = RoomVoiceData.GetVoiceRoomMemberSocialInfo(szGlobalID)
    if tbSocialInfo then
        if not tbSocialInfo.bDefault and tbSocialInfo.dwCenterID and tbSocialInfo.dwCenterID > 0 then
            return tbSocialInfo.dwCenterID, false, "voice_room"
        end
    end

    -- -- 2. 尝试从好友系统获取
    -- local tbRoleEntryInfo = FellowshipData.GetRoleEntryInfo(szGlobalID)
    -- if tbRoleEntryInfo and tbRoleEntryInfo.dwCenterID and tbRoleEntryInfo.dwCenterID > 0 then
    --     return tbRoleEntryInfo.dwCenterID, false, "fellowship"
    -- end

    return 0, true, "default"
end

-- 检查指定玩家的社交信息是否正在异步请求中
-- @param szGlobalID: 玩家的 GlobalID
-- @return bRequesting: 是否正在请求中
function RoomVoiceData.IsRequestingSocialInfo(szGlobalID)
    if not m_role_id_flag or not m_role_rqsting_ids then
        return false
    end

    -- 检查是否在请求标志中
    if m_role_id_flag[szGlobalID] then
        return true
    end

    -- 检查是否在待请求队列中
    if m_role_rqsting_ids then
        for _, id in ipairs(m_role_rqsting_ids) do
            if id == szGlobalID then
                return true
            end
        end
    end

    return false
end

-- 打赏等待队列管理
RoomVoiceData.tbTipWaitingQueue = RoomVoiceData.tbTipWaitingQueue or {}

-- 添加打赏任务到等待队列
-- @param szGlobalID: 目标玩家 GlobalID
-- @param fnCallback: 获取到有效 CenterID 后的回调函数，参数为 (dwCenterID, szSource)
-- @param fnTimeout: 超时回调函数
-- @param nTimeout: 超时时间（秒），默认 3 秒
function RoomVoiceData.AddTipWaitingTask(szGlobalID, fnCallback, fnTimeout, nTimeout)
    nTimeout = nTimeout or 3

    if not self.tbTipWaitingQueue then
        self.tbTipWaitingQueue = {}
    end

    -- 检查是否已经有有效的 CenterID
    local dwCenterID, bIsDefault, szSource = self.GetValidCenterID(szGlobalID)
    if not bIsDefault and dwCenterID > 0 then
        if fnCallback then
            fnCallback(dwCenterID, szSource)
        end
        return
    end

    -- 检查是否已有相同玩家的等待任务
    for _, tbTask in ipairs(self.tbTipWaitingQueue) do
        if tbTask.szGlobalID == szGlobalID then
            TipsHelper.ShowNormalTip("正在打赏中，请稍候...")
            return
        end
    end

    local tbTask = {
        szGlobalID = szGlobalID,
        fnCallback = fnCallback,
        fnTimeout = fnTimeout,
        nStartTime = GetCurrentTime(),
        nTimeout = nTimeout,
    }

    -- 添加到队列
    table.insert(self.tbTipWaitingQueue, tbTask)

    -- 申请社交信息
    if not self.IsRequestingSocialInfo(szGlobalID) then
        self.ApplyVoiceMemberSocialInfo({szGlobalID})
    end

    -- 同时申请好友系统信息作为备选
    -- FellowshipData.ApplyRoleEntryInfo({szGlobalID})

    if not self.nTipWaitingCheckTimer then
        self.nTipWaitingCheckTimer = Timer.AddCycle(self, 0.2, function()
            self.CheckTipWaitingQueue()
        end)
    end
end

function RoomVoiceData.CheckTipWaitingQueue()
    if not self.tbTipWaitingQueue or #self.tbTipWaitingQueue == 0 then
        if self.nTipWaitingCheckTimer then
            Timer.DelTimer(self, self.nTipWaitingCheckTimer)
            self.nTipWaitingCheckTimer = nil
        end
        return
    end

    local nCurrentTime = GetCurrentTime()
    local tbRemoveList = {}

    for nIndex, tbTask in ipairs(self.tbTipWaitingQueue) do
        local dwCenterID, bIsDefault, szSource = self.GetValidCenterID(tbTask.szGlobalID)

        -- 检查是否获取到有效数据
        if not bIsDefault and dwCenterID > 0 then
            -- 成功获取，执行回调
            if tbTask.fnCallback then
                tbTask.fnCallback(dwCenterID, szSource)
            end
            table.insert(tbRemoveList, nIndex)
        else
            -- 检查是否超时
            local nElapsed = nCurrentTime - tbTask.nStartTime
            if nElapsed >= tbTask.nTimeout then
                -- 超时，执行超时回调
                if tbTask.fnTimeout then
                    tbTask.fnTimeout()
                end
                table.insert(tbRemoveList, nIndex)
            end
        end
    end

    for i = #tbRemoveList, 1, -1 do
        table.remove(self.tbTipWaitingQueue, tbRemoveList[i])
    end
end

function RoomVoiceData.ClearTipWaitingQueue()
    if self.nTipWaitingCheckTimer then
        Timer.DelTimer(self, self.nTipWaitingCheckTimer)
        self.nTipWaitingCheckTimer = nil
    end
    self.tbTipWaitingQueue = {}
end

-- 检查指定玩家是否正在处理打赏
-- @param szGlobalID: 玩家的 GlobalID
-- @return bProcessing: 是否正在处理中
function RoomVoiceData.IsProcessingTip(szGlobalID)
    if not self.tbTipWaitingQueue then
        return false
    end

    for _, tbTask in ipairs(self.tbTipWaitingQueue) do
        if tbTask.szGlobalID == szGlobalID then
            return true
        end
    end

    return false
end

-- 切换成员进入房间的提示音状态
function RoomVoiceData.ToogleMemberJoinBeep()
    self.bMemberJoinBeep = not self.bMemberJoinBeep
end

-- 成员进入房间是否有提示音状态
function RoomVoiceData.IsMemberJoinBeep()
    return self.bMemberJoinBeep
end

-- 播放成员进入房间的提示音
function RoomVoiceData.PlayMemberJoinBeep(szRoomID, szMemberID)
    if not RoomVoiceData.IsMemberJoinBeep() then
        return
    end

    SoundMgr.PlaySound(SOUND.UI_SOUND, "UI_EnterVoiceRoom")
end

function RoomVoiceData.UpdateAdminSocialInfo(szRoomID, szMemberID)
    local tbRoomInfo = self.GetVoiceRoomInfo(szRoomID)
    local tbMemberInfo = self.GetVoiceMemberInfo(szRoomID, szMemberID)
    if (tbRoomInfo and tbRoomInfo.szMasterID == szMemberID) or (tbMemberInfo and tbMemberInfo.bIsAdmin) then
        self.ApplyVoiceMemberSocialInfo({szMemberID})
    end
end

-- 申请直播流信息
function RoomVoiceData.ApplyLiveStreamInfo(szGlobalID)
    local VoiceRoomClient = GetVoiceRoomClient()
    if not VoiceRoomClient then
        return
    end
    VoiceRoomClient.ApplyLiveStreamInfo(szGlobalID)
end

-- 获取直播流信息
function RoomVoiceData.GetLiveStreamInfo(szGlobalID)
    if not self.tLiveStreamInfoMap then
        self.tLiveStreamInfoMap = {}
    end
    return self.tLiveStreamInfoMap[szGlobalID]
end

-- 指定玩家是否已设置直播地图（nMapID 非零即视为已开播）
-- szGlobalID 为空时，自动取当前所在房间的房主 GlobalID
function RoomVoiceData.IsLiveStreamActive(szGlobalID)
    if string.is_nil(szGlobalID) then
        local _, szCurRoomID = RoomVoiceData.GetRoleVoiceRoomList()
        local tbRoomInfo = RoomVoiceData.GetVoiceRoomInfo(szCurRoomID)
        szGlobalID = tbRoomInfo and tbRoomInfo.szMasterID or nil
    end
    if string.is_nil(szGlobalID) then
        return false
    end
    local tLiveInfo = RoomVoiceData.GetLiveStreamInfo(szGlobalID)
    return tLiveInfo ~= nil and tLiveInfo.nMapID ~= nil and tLiveInfo.nMapID ~= 0
end

-- 获取当前直播副本中的观众人数（LIVE_STREAM_MEMBER_TYPE.OBSERVER 类型列表长度）
function RoomVoiceData.GetLiveAudienceCount()
    if self.tLiveStreamMapRoleList then
        local tbObservers = self.tLiveStreamMapRoleList[LIVE_STREAM_MEMBER_TYPE.OBSERVER]
        if tbObservers then
            return #tbObservers
        end
    end
    return 0
end

-- 获取指定类型的直播副本角色 GlobalID 列表
-- @param nMemberType: LIVE_STREAM_MEMBER_TYPE 枚举值（C++ 导出）；nil 表示返回所有类型合并列表
function RoomVoiceData.GetLiveStreamMapRoleList(nMemberType)
    if not self.tLiveStreamMapRoleList then
        return {}
    end
    if nMemberType ~= nil then
        return self.tLiveStreamMapRoleList[nMemberType] or {}
    end
    -- 合并所有类型
    local tbResult = {}
    for _, tbList in pairs(self.tLiveStreamMapRoleList) do
        for _, szGlobalID in ipairs(tbList) do
            tbResult[#tbResult + 1] = szGlobalID
        end
    end
    return tbResult
end

function RoomVoiceData.IsHaveRoom()
    local hPlayer = GetClientPlayer()
	if not hPlayer then
		return
	end
	local szGlobalRoomID = hPlayer.GetGlobalRoomID()
    if not szGlobalRoomID then
        return false
    end
    return true
end

-- 观看直播流
local nLastClickTrack = 0
function RoomVoiceData.WatchLiveStream(szGlobalID)
	if IsRemotePlayer(UI_GetClientPlayerID()) then
		OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_REMOTE_NOT_TIP.."\n")
		return
	end

	if RoomVoiceData.IsHaveRoom() then
		OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_OBDUNGEON_ROOM_NOT_TIP.."\n")
		return
	end

    local VoiceRoomClient = GetVoiceRoomClient()
    if not VoiceRoomClient then
        return
    end

    local dwNowTime = GetTickCount()
    if dwNowTime - nLastClickTrack > 30000 then
        MapMgr.BeforeTeleport()
        VoiceRoomClient.WatchLiveStream(szGlobalID)
        nLastClickTrack = GetTickCount()
    else
        OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_OBDUNGEON_KICKOUT_OB_TIP.."\n")
    end
end

-- 进入房间并自动观看直播
-- 进入房间成功后自动调用 WatchLiveStream
function RoomVoiceData.TryJoinRoomAndWatchLiveStream(szRoomID, bPwdRequired, szMasterID)
    if not szMasterID or szMasterID == "" then
        return
    end

    -- 注册一次性事件：进入房间成功后自动观看直播
    if not self._bWatchAfterJoin then
        self._bWatchAfterJoin = true
        Event.Reg(self, EventType.ON_JOIN_VOICE_ROOM, function()
            self._bWatchAfterJoin = nil
            self.JumpToRoomVoice()
            RoomVoiceData.WatchLiveStream(szMasterID)
        end, true)
    end

    RoomVoiceData.TryJoinRoom(szRoomID, bPwdRequired, function()
        -- 用户取消进入房间时清理一次性标记
        self._bWatchAfterJoin = nil
    end)
end

-- 设置直播流地图
function RoomVoiceData.SetLiveStreamMap(nMapID)
    local VoiceRoomClient = GetVoiceRoomClient()
    if not VoiceRoomClient then
        return
    end
    VoiceRoomClient.SetLiveStreamMap(nMapID)
end

-- 申请获取指定类型的直播地图角色列表（结果通过 ON_SYNC_LIVE_STREAM_MAP_ROLE_LIST 事件回调）
-- @param nMemberType: LIVE_STREAM_MEMBER_TYPE.STREAMER（主播）或 LIVE_STREAM_MEMBER_TYPE.OBSERVER（观众）
function RoomVoiceData.ApplyLiveStreamMapRoleList(nMemberType)
    local VoiceRoomClient = GetVoiceRoomClient()
    if not VoiceRoomClient then
        return
    end
    VoiceRoomClient.ApplyLiveStreamMapRoleList(nMemberType)
end

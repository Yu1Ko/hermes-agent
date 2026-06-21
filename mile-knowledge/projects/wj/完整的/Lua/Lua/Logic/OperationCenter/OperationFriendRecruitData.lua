-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: OperationFriendRecruitData
-- Date: 2026-03-25 16:30:16
-- Desc: ?
-- ---------------------------------------------------------------------------------

OperationFriendRecruitData = OperationFriendRecruitData or {className = "OperationFriendRecruitData"}
local self = OperationFriendRecruitData
-------------------------------- 消息定义 --------------------------------
OperationFriendRecruitData.Event = {}
OperationFriendRecruitData.Event.XXX = "OperationFriendRecruitData.Msg.XXX"

-------------------------------- 常量定义 --------------------------------
local ACT_ID = OPERACT_ID.FRIENDS_RECRUIT
local DEFAULT_DISPLAY_REWARD_INDEX = 10
local REWARD_STATE = OPERACT_REWARD_STATE

-------------------------------- 私有变量 --------------------------------
self.tRecruitRewardData = nil
self.nRecruitPoint = 0
self.nCurrentRewardIndex = nil
self.tReceivedReward = {}

-------------------------------- 私有函数 --------------------------------
local function BuildRewardData()
    local tNew = {}
    local tOld = {}
    local tList = {}

    for _, tInfo in pairs(Table_GetOperatActFRecall() or {}) do
        if tInfo.bNewProduct == 1 then
            table.insert(tNew, tInfo)
        else
            table.insert(tOld, tInfo)
        end
    end

    table.sort(tNew, function(a, b)
        return (a.dwIntergral or 0) < (b.dwIntergral or 0)
    end)

     table.sort(tOld, function(a, b)
        return (a.dwIntergral or 0) < (b.dwIntergral or 0)
    end)

    for _, tInfo in ipairs(tNew) do
        table.insert(tList, tInfo)
    end
    for _, tInfo in ipairs(tOld) do
        table.insert(tList, tInfo)
    end

    return tList
end

function OperationFriendRecruitData.InitOperation()
    HuaELouData.RegisterProcessor(ACT_ID, self)

    RemoteCallToServer("On_Recharge_GetFriendsPoints")
end

function OperationFriendRecruitData.HasRedPoint(dwID)
    return self.IsRewardCanBeReceived()
end

function OperationFriendRecruitData.EnsureInit()
    if self.tRecruitRewardData then
        return
    end

    self.tRecruitRewardData = BuildRewardData()
    self.ResetRuntimeState()
    self.RefreshReceivedReward()
end

function OperationFriendRecruitData.ResetRuntimeState(bKeepSelectedReward)
    self.SetRecruitPoint(0)
    if not bKeepSelectedReward then
        self.nCurrentRewardIndex = nil
    end
    self.tReceivedReward = {}
end

function OperationFriendRecruitData.SetRecruitPoint(nPoint)
    self.nRecruitPoint = nPoint or 0
end

function OperationFriendRecruitData.GetRecruitPoint()
    return self.nRecruitPoint or 0
end

function OperationFriendRecruitData.GetPointReward()
    local player = GetClientPlayer()
    if not player then
        return {}
    end
    return FriendsInvite_CheckRewardListForUI(player) or {}
end

function OperationFriendRecruitData.RefreshReceivedReward()
    self.tReceivedReward = self.GetPointReward()
end

function OperationFriendRecruitData.GetAllRecruitRewardData()
    self.EnsureInit()
    return self.tRecruitRewardData or {}
end

function OperationFriendRecruitData.GetRecruitRewardDataByRewardIndex(nRewardIndex)
    for _, tRewardInfo in ipairs(self.GetAllRecruitRewardData()) do
        if tRewardInfo.dwID == nRewardIndex then
            return tRewardInfo
        end
    end
    return nil
end

function OperationFriendRecruitData.GetDefaultRewardIndex()
    if self.GetRecruitRewardDataByRewardIndex(DEFAULT_DISPLAY_REWARD_INDEX) then
        return DEFAULT_DISPLAY_REWARD_INDEX
    end

    local tFirst = self.GetAllRecruitRewardData()[1]
    return tFirst and tFirst.dwID or nil
end

function OperationFriendRecruitData.GetCurrentRewardIndex()
    local nRewardIndex = self.nCurrentRewardIndex
    if nRewardIndex and self.GetRecruitRewardDataByRewardIndex(nRewardIndex) then
        return nRewardIndex
    end
    return self.GetDefaultRewardIndex()
end

function OperationFriendRecruitData.GetRewardStateByRewardIndex(nRewardIndex)
    local tRewardInfo = self.GetRecruitRewardDataByRewardIndex(nRewardIndex)
    if not tRewardInfo then
        return REWARD_STATE.NON_GET
    end

    local tGot = self.tReceivedReward or {}
    if tGot[nRewardIndex] == 1 then
        return REWARD_STATE.ALREADY_GOT
    end

    if self.GetRecruitPoint() >= (tRewardInfo.dwIntergral or 0) then
        return REWARD_STATE.CAN_GET
    end

    return REWARD_STATE.NON_GET
end

function OperationFriendRecruitData.IsRewardCanBeReceived()
    for _, tRewardInfo in ipairs(self.GetAllRecruitRewardData()) do
        if self.GetRewardStateByRewardIndex(tRewardInfo.dwID) == REWARD_STATE.CAN_GET then
            return true
        end
    end
    return false
end

function OperationFriendRecruitData.GetRewardNameCost(nRewardIndex)
    local tRewardInfo = self.GetRecruitRewardDataByRewardIndex(nRewardIndex)
    if not tRewardInfo then
        return nil, 0
    end
    return tRewardInfo.szName, tRewardInfo.dwIntergral or 0
end

function OperationFriendRecruitData.UpdateRewardInfoOfPlayer(nRewardIndex, nCost)
    if not nRewardIndex then
        return
    end

    self.tReceivedReward = self.tReceivedReward or {}
    self.tReceivedReward[nRewardIndex] = 1
    self.SetRecruitPoint(math.max(self.GetRecruitPoint() - (nCost or 0), 0))
end

function OperationFriendRecruitData.GetAutoLoginSpecialUrl(url)
    local account = Login_GetAccount()
    -- local ip = (select(7, GetUserServer()))
    local token
    local data
    local key = "kingt9Joy:8Xit"
    token = MD5(account .. key)
    data = account .. "&" .. token

    data = Base64_Encode( data )
    data = UrlEncode(data)

    url = url .. data
    return url
end

function OperationFriendRecruitData.GetAutoLoginUrl(url)
    local account = Login_GetAccount()
    -- local ip = (select(7, GetUserServer()))
    -- local code    = select(11, LoginServerList.GetSelectedServer())
    local LoginServerList = LoginMgr.GetModule(LoginModule.LOGIN_SERVERLIST)
    local tbSelectServer = LoginServerList.GetSelectServer()
    local code = tbSelectServer.szSerial
    local time    = GetCurrentTime()

    local key = "kingt9Joy:8Xit"
    local token = table.concat({account, code, time, key}, "")
    token = MD5(token)
    local data = table.concat({account, code, time, token}, "&")
    data = Base64_Encode( data )
    data = UrlEncode(data)

    url = url .. data
    return url
end

Event.Reg(self, "On_Recharge_GetFriendsPoints_CallBack", function(nLeftPoint)
    self.SetRecruitPoint(nLeftPoint)
end)

Event.Reg(self, "On_Recharge_GetFriInvReward_CallBack", function(nRewardIndex, nCost)
    self.UpdateRewardInfoOfPlayer(nRewardIndex, nCost)
end)


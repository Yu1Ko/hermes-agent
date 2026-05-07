--[[
    获取当前客户各种交互状态。
]]--

PlayerStatus = {
    -- 火把
    HuoBa     = 1,
    -- 战斗中
    Fighting  = 2,
    -- 幻境云图
    HuanJingYunTu = 3,
    -- 轻功QTE
    AutoFlyQte = 4,

    -- 竞技场3V3
    MPVP3V3 = 5,
    -- 牵手中
    HandInHand = 6,

    -- 跨服中
    CrossRealm = 7,

    --双姿态
    DoubleAttitude = 8
}

ClientPlayerStatusData = ClientPlayerStatusData or {}
local status = {}
local lastplayerID = 0
--返回true表示状态中，返回false表示不在状态中。
function ClientPlayerStatusData.CheckStatus(playerStatus)
    return status[playerStatus]
end

--返回一个table，下标是PlayerStatus，后续不断加减，有可能不一定连续。
function ClientPlayerStatusData.GetStatus()
    return status
end

function ClientPlayerStatusData.SetStatus(statuType, value)
    if not statuType or status[statuType] == nil or value == nil then return end
    if status[statuType] ~= value then
        status[statuType] = value
        UIHelper.PushEvent(UIEventType.OnClientPlayerStatusChange, statuType, value, not value)
        UIHelper.PushEvent(UIEventType.OnClientPlayerAnyStatusChange)
    end
    return status
end
function InitByPlayer(player)
    status = {}
    lastplayerID = player.dwID

    status[PlayerStatus.Fighting] = player.bFightState
    status[PlayerStatus.HuoBa] = (player:GetBuff(13960, 1) ~= nil)
    status[PlayerStatus.HuanJingYunTu] = not not UINavigateHelper.FindViewByID(VIEW_ID.NewPhoto)
    status[PlayerStatus.AutoFlyQte] = Lua2CS.IsInAutoFlyQte()
    status[PlayerStatus.MPVP3V3] = (StageData.IsMPVP() and ArenaData.GetArenaGameMode() == ARENA_GAME_MODE.Group3V3)
    status[PlayerStatus.HandInHand] = (player:GetBuff(13450, 1) ~= nil) or (player:GetBuff(13451, 1) ~= nil)
    status[PlayerStatus.CrossRealm] = Lua2CS.IsCrossRealm()

    status[PlayerStatus.DoubleAttitude] = player:HasRepresent(UIActionID.DoubleAttitude)
end

local function CheckFighting(player)
    local fightState = player.bFightState;
    if status[PlayerStatus.Fighting] ~= fightState then
        status[PlayerStatus.Fighting] = fightState
        --特定status的变化事件
        UIHelper.PushEvent(UIEventType.OnClientPlayerStatusChange, PlayerStatus.Fighting, fightState, not fightState)
        return true
    end
    return false
end

local function CheckHuoBa(player)
    local huoBa = player:GetBuff(13960, 1) ~= nil;
    if status[PlayerStatus.HuoBa] ~= huoBa then
        status[PlayerStatus.HuoBa] = huoBa
        --特定status的变化事件
        UIHelper.PushEvent(UIEventType.OnClientPlayerStatusChange, PlayerStatus.HuoBa, huoBa, not huoBa)
        return true
    end
    return false
end

local function CheckAutoFlyQte(player)
    local isInQte = Lua2CS.IsInAutoFlyQte()
    if status[PlayerStatus.AutoFlyQte] ~= isInQte then
        status[PlayerStatus.AutoFlyQte] = isInQte
        --特定status的变化事件
        UIHelper.PushEvent(UIEventType.OnClientPlayerStatusChange, PlayerStatus.AutoFlyQte, isInQte, not isInQte)
        return true
    end
    return false
end

local function CheckMPVP3V3(player)
    local IsInMPVP3V3 = StageData.IsMPVP() and ArenaData.GetArenaGameMode() == ARENA_GAME_MODE.Group3V3
    if status[PlayerStatus.MPVP3V3] ~= IsInMPVP3V3 then
        status[PlayerStatus.MPVP3V3] = IsInMPVP3V3
        --特定status的变化事件
        UIHelper.PushEvent(UIEventType.OnClientPlayerStatusChange, PlayerStatus.MPVP3V3, IsInMPVP3V3, not IsInMPVP3V3)
    end
end

local function CheckHandInHand(player)
    local inState = player:GetBuff(13450, 1) ~= nil or player:GetBuff(13451, 1) ~= nil
    if status[PlayerStatus.HandInHand] ~= inState then
        status[PlayerStatus.HandInHand] = inState
        --特定status的变化事件
        UIHelper.PushEvent(UIEventType.OnClientPlayerStatusChange, PlayerStatus.HandInHand, inState, not inState)
        return true
    end
    return false
end

local function ChecCrossRealm(player)
    local inState = Lua2CS.IsCrossRealm()
    if status[PlayerStatus.CrossRealm] ~= inState then
        status[PlayerStatus.CrossRealm] = inState
        --特定status的变化事件
        UIHelper.PushEvent(UIEventType.OnClientPlayerStatusChange, PlayerStatus.CrossRealm, inState, not inState)
        return true
    end
    return false
end

local function CheckDoubleAttitude(player)
    local isDoubleAttitude = player:HasRepresent(UIActionID.DoubleAttitude)
    if status[PlayerStatus.DoubleAttitude] ~= isDoubleAttitude then
        status[PlayerStatus.DoubleAttitude] = isDoubleAttitude
        return true
    end
    return false
end
--每帧只检查一次。事件也只发一次，
function ClientPlayerStatusData.OnUpdate()
    if JX3MWorld == nil or JX3MWorld.GetClientPlayer == nil then
        return
    end

    local player = PlayerData.GetClientPlayer()  --JX3MWorld.GetClientPlayer()
    if player == nil then
        return
    end

    if lastplayerID ~= player.dwID then
        InitByPlayer(player)
        return
    end

    local bChange = false

    bChange = bChange or CheckHuoBa(player)
    bChange = bChange or CheckFighting(player)
    bChange = bChange or CheckAutoFlyQte(player)
    bChange = bChange or CheckMPVP3V3(player)
    bChange = bChange or CheckHandInHand(player)
    bChange = bChange or ChecCrossRealm(player)

    CheckDoubleAttitude(player)

    if bChange then
        --只有有任意变化，都会触发此事件，且一帧最多发一次。 统一处理逻辑用这个，用上面的可能会导致重复执行代码。
        UIHelper.PushEvent(UIEventType.OnClientPlayerAnyStatusChange)
    end
end

--UIHelper.AddCycleTimer(ClientPlayerStatusData, 0.4, function()
--    ClientPlayerStatusData.OnUpdate()
--end)
-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: HomelandAchievement
-- Date: 2025-01-14 11:02:32
-- Desc: ?
-- ---------------------------------------------------------------------------------

HomelandAchievement = HomelandAchievement or {className = "HomelandAchievement"}
local self = HomelandAchievement
-------------------------------- 消息定义 --------------------------------
HomelandAchievement.Event = {}
HomelandAchievement.Event.XXX = "HomelandAchievement.Msg.XXX"

local REMOTE_HOMELAND_SEASON = 1085
local FURNITURE_TOTAL_SUIT_INDEX = 9
local SEASON_FURNITURE_REMOTE_DATA_START = 4
local SEASON_FURNITURE_REMOTE_DATA_END = 18
local SEASON_FURNITURE_REMOTE_DATA_LEN = 2
local TRANSITION_TIME_REMOTE_DATA_START = 21
local TRANSITION_TIME_REMOTE_DATA_END = 28
local TRANSITION_TIME_REMOTE_DATA_LEN = 1
local tbLoadExtensionsScript = {
    "scripts/Map/家园系统客户端/Include/HomelandCommon.lua",
    "scripts/Include/UIscript/UIscript_Homeland.lua",
}
for _, szPath in ipairs(tbLoadExtensionsScript) do
    LoadScriptFile(UIHelper.UTF8ToGBK(szPath), HomelandAchievement)
end

-----------------------------HomelandAchievement-----------------------------
function HomelandAchievement.UnInit()
    HomelandAchievement.tCollectProgress  = nil
    HomelandAchievement.tTransitionData   = nil
    HomelandAchievement.nCommonChip       = nil
    HomelandAchievement.nFullCollected    = nil
    HomelandAchievement.aMaxSeasonFurnitureProgress = nil
    HomelandAchievement.tUSetID           = nil
    HomelandAchievement.dwTotalSetID      = nil
    HomelandAchievement.nFurnitureScore   = 0
end

function HomelandAchievement.Init()
    local nCurTime = GetCurrentTime()
    HomelandAchievement.nFurnitureScore   = 0
    HomelandAchievement.tCollectProgress  = {}
    HomelandAchievement.tTransitionData   = {}
    HomelandAchievement.nCommonChip       = HomelandAchievement.nCommonChip or 0
    HomelandAchievement.nFullCollected    = HomelandAchievement.nFullCollected or 0
    HomelandAchievement.aMaxSeasonFurnitureProgress = HomelandAchievement.Homeland_GetSeasonFurFull()
    HomelandAchievement.tUSetID           = nil
    HomelandAchievement.dwTotalSetID      = nil
    HomelandAchievement.bTimeInterim = HomelandAchievement.Homeland_IsTimeInterim(nCurTime, IsVersionTW())

    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end
    --pPlayer.ApplySetCollection()
    HomelandAchievement.GetFurnitureSetID()

    RemoteCallToServer("On_HomeLand_GetSeasonPoints")
end

function HomelandAchievement.GetFurnitureSetID()
    local tFurnitureSet = HomelandAchievement.Homeland_GetFurnitureSet()
    HomelandAchievement.tUSetID = tFurnitureSet[1] --所有套装ID
    HomelandAchievement.dwTotalSetID = tFurnitureSet[2][1] --总套装ID
end

function HomelandAchievement.GetSeasonCollectData()
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end
    HomelandAchievement.tCollectProgress = {}
    HomelandAchievement.nCommonChip = 0
    HomelandAchievement.nFullCollected = 0
    HomelandAchievement.aMaxSeasonFurnitureProgress = HomelandAchievement.Homeland_GetSeasonFurFull()
    local nIndex = 1
    for nReadStart = SEASON_FURNITURE_REMOTE_DATA_START, SEASON_FURNITURE_REMOTE_DATA_END, SEASON_FURNITURE_REMOTE_DATA_LEN do
        local nProgress = pPlayer.GetRemoteArrayUInt(REMOTE_HOMELAND_SEASON, nReadStart, SEASON_FURNITURE_REMOTE_DATA_LEN)
        local nHigherThanMax = nProgress - HomelandAchievement.aMaxSeasonFurnitureProgress[nIndex]
        table.insert(HomelandAchievement.tCollectProgress, nProgress)
        HomelandAchievement.nCommonChip = HomelandAchievement.nCommonChip + math.max(0, nHigherThanMax)
        nIndex = nIndex + 1
        if nHigherThanMax >= 0 then
            HomelandAchievement.nFullCollected = HomelandAchievement.nFullCollected + 1
        end
    end
end

function HomelandAchievement.GetTransitionData()
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end
    HomelandAchievement.tTransitionData = {}
    for nPos = TRANSITION_TIME_REMOTE_DATA_START, TRANSITION_TIME_REMOTE_DATA_END, TRANSITION_TIME_REMOTE_DATA_LEN do
        local nTransitionData = pPlayer.GetRemoteArrayUInt(REMOTE_HOMELAND_SEASON, nPos, TRANSITION_TIME_REMOTE_DATA_LEN)
        if nTransitionData then
            table.insert(HomelandAchievement.tTransitionData, nTransitionData)
        end
    end
end

function HomelandAchievement.IsHaveFurnitureReward()
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end
    local bAllCollected = true
    HomelandAchievement.GetFurnitureSetID()
    local dwTotalSetID = HomelandAchievement.dwTotalSetID
    local tUSetID = HomelandAchievement.tUSetID
    --pPlayer.ApplySetCollection()
    for _, uSetID in ipairs(tUSetID) do
        local nCollectType = pPlayer.GetSetCollection(uSetID).eType
        local bAward = nCollectType == SET_COLLECTION_STATE_TYPE.TO_AWARD
        local bCollected = nCollectType == SET_COLLECTION_STATE_TYPE.COLLECTED
        if uSetID ~= dwTotalSetID then
            if not bCollected then
                bAllCollected = false
            end
            if bAward then
                return true
            end
        else
            if bAllCollected and bAward then
                return true
            end
        end
    end
    return false
end

function HomelandAchievement.IsAllFurnitureFullCollected()
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end
    --pPlayer.ApplySetCollection()
    HomelandAchievement.GetFurnitureSetID()
    local tUSetID = HomelandAchievement.tUSetID
    local nCollectType = pPlayer.GetSetCollection(tUSetID[FURNITURE_TOTAL_SUIT_INDEX]).eType
    if nCollectType ~= SET_COLLECTION_STATE_TYPE.COLLECTED then
        return false
    end
    return true
end

----------------------外部调用---------------------------
function HomelandAchievement.GetNormalFragment()
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end
    local nCommonChip = 0
    local aMaxSeasonFurnitureProgress = HomelandAchievement.Homeland_GetSeasonFurFull()
    local nIndex = 1
    for nReadStart = SEASON_FURNITURE_REMOTE_DATA_START, SEASON_FURNITURE_REMOTE_DATA_END, SEASON_FURNITURE_REMOTE_DATA_LEN do
        local nProgress = pPlayer.GetRemoteArrayUInt(REMOTE_HOMELAND_SEASON, nReadStart, SEASON_FURNITURE_REMOTE_DATA_LEN)
        local nHigherThanMax = nProgress - aMaxSeasonFurnitureProgress[nIndex]
        nCommonChip = nCommonChip + math.max(0, nHigherThanMax)
        nIndex = nIndex + 1
    end

    return nCommonChip
end
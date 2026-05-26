-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: AutoShoutForbidData
-- Date: 2025-03-13 11:43:59
-- Desc: ?
-- ---------------------------------------------------------------------------------

AutoShoutForbidData = AutoShoutForbidData or {className = "AutoShoutForbidData"}
local self = AutoShoutForbidData

local tbShoutTypeConfig = {
    {szTitle = "技能喊话", szFliter = "JX_OnSkillNotify"},
    {szTitle = "斩伤喊话", szFliter = "JX_OnDeathNotify"},
    {szTitle = "过图喊话", szFliter = "JX_OnEventNotify2"},
    {szTitle = "入队喊话", szFliter = "JX_OnEventNotify4"},
    {szTitle = "进帮喊话", szFliter = "JX_OnEventNotify3"},
    {szTitle = "上线喊话", szFliter = "JX_OnEventNotify1"},
    {szTitle = "屏蔽自己", szFliter = "self"},
}

local tbChannelConfig = {
    [1] = {
        szTitle = "小队频道", tbChannelID = {PLAYER_TALK_CHANNEL.TEAM},
    },
    [2] = {
        szTitle = "团队/战场", tbChannelID = {PLAYER_TALK_CHANNEL.RAID, PLAYER_TALK_CHANNEL.BATTLE_FIELD},
    },
    [3] = {
        szTitle = "帮会频道", tbChannelID = {PLAYER_TALK_CHANNEL.TONG},
    },
    [4] = {
        szTitle = "同盟频道", tbChannelID = {PLAYER_TALK_CHANNEL.TONG_ALLIANCE},
    },
}

local tbWhiteListConfig = {
    [1] = {
        szTitle = "名剑大会",
        fnFilter = function (scene)
            return scene.bIsArenaMap
        end
    },
    [2] = {
        szTitle = "战场",
        fnFilter = function (scene)
            return scene.nType == MAP_TYPE.BATTLE_FIELD
        end
    },
}

-------------------------------- 消息定义 --------------------------------
AutoShoutForbidData.Event = {}
AutoShoutForbidData.Event.XXX = "AutoShoutForbidData.Msg.XXX"

function AutoShoutForbidData.Init()
    
end

function AutoShoutForbidData.UnInit()
    
end

function AutoShoutForbidData.OnLogin()
    
end

function AutoShoutForbidData.OnFirstLoadEnd()

end

function AutoShoutForbidData.SaveShoutFilter(tbRuntimeMap)
    for key, v in pairs(tbRuntimeMap) do
        Storage.ShoutFilter[key] = v
    end

    Storage.ShoutFilter.Flush()
end

function AutoShoutForbidData.GetShoutTypeConfig()
    return tbShoutTypeConfig
end

function AutoShoutForbidData.GetChannelConfig()
    return tbChannelConfig
end

function AutoShoutForbidData.GetWhiteListConfig()
    return tbWhiteListConfig
end

function AutoShoutForbidData.NeedToFilter(szMsg, nChannel, bSelf)
    local bNeedFilter = false
    local szSource = nil
    if not string.find(szMsg, [["via":"JX"]]) then
        return bNeedFilter
    end

    szSource = string.match(szMsg, [["source":"(.-)"]])

    if string.is_nil(szSource) then
        return bNeedFilter
    end

    if AutoShoutForbidData.IsInIgnoreMap() then
        return bNeedFilter
    end

    if not AutoShoutForbidData.IsFilterSelfAutoShout() and bSelf then
        return bNeedFilter
    end

    local tbFilterChnnel = Storage.ShoutFilter.tbForbidChannel
    local tbFilterType = Storage.ShoutFilter.tbForbidType
    for key, v in pairs(tbFilterType) do
        if tbShoutTypeConfig[key].szFliter == szSource then
            bNeedFilter = true
            break
        end
        bNeedFilter = false
    end

    local player = GetClientPlayer()
    if bNeedFilter then
        if player.GetScene().nType == MAP_TYPE.BATTLE_FIELD and nChannel == PLAYER_TALK_CHANNEL.BATTLE_FIELD then
            nChannel = PLAYER_TALK_CHANNEL.RAID
        end
        bNeedFilter = table.contain_value(tbFilterChnnel, nChannel)
    end
    return bNeedFilter
end

function AutoShoutForbidData.IsFilterSelfAutoShout()
    local bFilter = Storage.ShoutFilter.tbForbidType[6]
    bFilter = bFilter or false
    return bFilter
end

function AutoShoutForbidData.IsInIgnoreMap()
    local player = GetClientPlayer()
    if not player then
        return false
    end

    local scene = player.GetScene()
    if not scene then
        return false
    end

    local tData = Storage.ShoutFilter.tbForbidMap
    for index, value in pairs(tData) do
        if tbWhiteListConfig[index] and tbWhiteListConfig[index].fnFilter then
            tbWhiteListConfig[index].fnFilter(scene)
        end
    end
end
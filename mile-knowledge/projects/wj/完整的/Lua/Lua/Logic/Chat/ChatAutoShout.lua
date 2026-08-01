-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: ChatAutoShout
-- Date: 2024-10-14 11:37:48
-- Desc: 自动喊话
-- ---------------------------------------------------------------------------------

ChatAutoShout = ChatAutoShout or {className = "ChatAutoShout"}
local self = ChatAutoShout

local SKILL_SHOUT_COLD_DOWN = 1 -- 秒
local tbSourceType = {
    Other = "JX_OnEventNotify",
    Death = "JX_OnDeathNotify",
    Skill = "JX_OnSkillNotify",
}

local tbTagList = {
    ["All"]                                 = {"self", "map", "new", "tong", "leader", "killer", "dead"},
    [UI_Chat_Setting_Type.Auto_Online]      = {"self", "map"},
    [UI_Chat_Setting_Type.Auto_Map]         = {"self", "map"},
    [UI_Chat_Setting_Type.Auto_Tong]        = {"self", "new", "tong"},
    [UI_Chat_Setting_Type.Auto_Party]       = {"self", "new", "leader"},
    [UI_Chat_Setting_Type.Auto_Skill]       = {"self", "skill", "target"},
    [UI_Chat_Setting_Type.Auto_Kill]        = {"self", "dead", "map", "tong"},
    [UI_Chat_Setting_Type.Auto_AssistKill]  = {"self", "killer", "dead", "map", "tong"},
    [UI_Chat_Setting_Type.Auto_BeKill]      = {"self", "killer", "map", "tong"},
}

local tbSkillShoutType = {
    [UI_Chat_SkillShout_Type.Other] = "其它",
    [UI_Chat_SkillShout_Type.Spell] = "读条",
    [UI_Chat_SkillShout_Type.Hit] = "命中",
    [UI_Chat_SkillShout_Type.HitReceived] = "被命中",
}

local tbForbidMapList = {
    [1] = {
        szTitle = "副本",
        fnFilter = function (scene)
            return scene.nType == MAP_TYPE.DUNGEON
        end
    },
    [2] = {
        szTitle = "战场",
        fnFilter = function (scene)
            return scene.nType == MAP_TYPE.BATTLE_FIELD
        end
    },
    [3] = {
        szTitle = "名剑大会",
        fnFilter = function (scene)
            return scene.bIsArenaMap
        end
    },
    [4] = {
        szTitle = "其他场景",
        fnFilter = function (scene)
            return scene.nType ~= MAP_TYPE.DUNGEON and scene.nType ~= MAP_TYPE.BATTLE_FIELD and not scene.bIsArenaMap
        end
    },
}

local tbApplyChannelList = {
    [0] = {
        szTitle = "不发布", tbChannelID = {},
    },
    [1] = {
        szTitle = "小队频道", tbChannelID = {PLAYER_TALK_CHANNEL.TEAM},
    },
    [2] = {
        szTitle = "团队/战场", tbChannelID = {PLAYER_TALK_CHANNEL.RAID},
    },
    [3] = {
        szTitle = "帮会频道", tbChannelID = {PLAYER_TALK_CHANNEL.TONG},
    },
    [4] = {
        szTitle = "同盟频道", tbChannelID = {PLAYER_TALK_CHANNEL.TONG_ALLIANCE},
    },
}

local tbSpecialSkillList = {
    [101971] = "锋针·悟",
    [100463] = "妙舞神扬·悟",
    [100445] = "心鼓弦·悟",
    [101978] = "涅槃重生·悟",
    [102198] = "歌尽影生·悟",
    [102334] = "杯水留影·悟",
    [102199] = "灵素还生·悟",
}

-- 策划说不需要预配，配都配了先留着
local tbSkillShoutConfig = {
    [1] =
    {
        szSkillName = "歌尽影生·悟",
        bApplied = true,
        [UI_Chat_SkillShout_Type.Spell] = "@skill正在救治@target！",
        [UI_Chat_SkillShout_Type.Hit] = "清歌寥落，曲尽影生。[@target]，魂游迷梦终需醒。",
    },

    [2] =
    {
        szSkillName = "涅槃重生·悟",
        bApplied = true,
        [UI_Chat_SkillShout_Type.Spell] = "@skill正在救治@target！",
        [UI_Chat_SkillShout_Type.Hit] = "不入轮回得重生。[@target]，魂游迷梦终需醒。",
    },

    [3] =
    {
        szSkillName = "心鼓弦·悟",
        bApplied = true,
        [UI_Chat_SkillShout_Type.Spell] = "@skill正在救治@target！",
        [UI_Chat_SkillShout_Type.Hit] = "弦牵六脉，心开天籁。[@target]，魂游迷梦终需醒。",
    },

    [4] =
    {
        szSkillName = "锋针·悟",
        bApplied = true,
        [UI_Chat_SkillShout_Type.Spell] = "@skill正在救治@target！",
        [UI_Chat_SkillShout_Type.Hit] = "第其身而锋其末。[@target]，魂游迷梦终需醒。",
    },

    [5] =
    {
        szSkillName = "灵素还生·悟",
        bApplied = true,
        [UI_Chat_SkillShout_Type.Spell] = "@skill正在救治@target！",
        [UI_Chat_SkillShout_Type.Hit] = "将子无死，尚复能来。[@target]，魂游迷梦终需醒。",
    },

    [6] =
    {
        szSkillName = "妙舞神扬·悟",
        bApplied = true,
        [UI_Chat_SkillShout_Type.Spell] = "@skill正在救治@target！",
        [UI_Chat_SkillShout_Type.Hit] = "清歌妙舞，神采飞扬。[@target]，魂游迷梦终需醒。",
    },

    [7] =
    {
        szSkillName = "杯水留影·悟",
        bApplied = true,
        [UI_Chat_SkillShout_Type.Spell] = "@skill正在救治@target！",
        [UI_Chat_SkillShout_Type.Hit] = "心清至明，映水无痕。[@target]，魂游迷梦终需醒。",
    },
}

local tbOtherShoutConfig = {
    [1] =
    {
        szType = UI_Chat_Setting_Type.Auto_Online,
        szName = "上线喊话",
        szDefaultText = "@self来到了@map[#欣喜]",
        tbApplyChannel = {},
    },
    [2] =
    {
        szType = UI_Chat_Setting_Type.Auto_Map,
        szName = "过图喊话",
        szDefaultText = "@self进入了@map[#笨猪]",
        tbApplyChannel = {},
    },
    [3] =
    {
        szType = UI_Chat_Setting_Type.Auto_Tong,
        szName = "进帮喊话",
        szDefaultText = "[#玫瑰]欢迎 @new 加入@tong[#玫瑰]",
        tbApplyChannel = {},
    },
    [4] =
    {
        szType = UI_Chat_Setting_Type.Auto_Party,
        szName = "入队喊话",
        szDefaultText = "欢迎 @new 加入@leader的队伍！[#玫瑰][#可怜]",
        tbApplyChannel = {},
    },
}

local tbDeathShoutConfig = {
    [1] =
    {
        szType = UI_Chat_Setting_Type.Auto_Kill,
        szName = "击伤喊话",
        szDefaultText = "@self 成功击伤了[@dead]",
        tbApplyChannel = {},
    },
    [2] =
    {
        szType = UI_Chat_Setting_Type.Auto_AssistKill,
        szName = "协伤喊话",
        szDefaultText = "@self 协助 @killer 击伤了[@dead]",
        tbApplyChannel = {},
    },
    [3] =
    {
        szType = UI_Chat_Setting_Type.Auto_BeKill,
        szName = "被伤喊话",
        szDefaultText = "我在 @map 被[@killer]击伤了",
        tbApplyChannel = {},
    },
}

local tbChatSettingConfig = {
    -- 技能喊话 -------------------------------------------
    Skill =
    {
        szTitleName = "技能喊话",
        tbApplyChannel = {},
        tbGroupList = {},
    },

    -- 自动喊话 -------------------------------------------
    Other =
    {
        szTitleName = "自动喊话",
        tbGroupList = {}
    },

    -- 斩伤喊话 -------------------------------------------
    Death =
    {
        szTitleName = "斩伤喊话",
        tbGroupList = {}
    },

    -- 喊话屏蔽 -------------------------------------------
    Forbid =
    {
        szTitleName = "喊话屏蔽",
        tbGroupList = {}
    },
}

for _, tbConf in ipairs(tbOtherShoutConfig) do
    table.insert(tbChatSettingConfig.Other.tbGroupList, tbConf)
end

for _, tbConf in ipairs(tbDeathShoutConfig) do
    table.insert(tbChatSettingConfig.Death.tbGroupList, tbConf)
end

-------------------------------- 消息定义 --------------------------------
-- ChatAutoShout.Event = {}

function ChatAutoShout.Init()
    self.tbSkillShoutList = {}
    self.bFirstLoadEnding = false
    self.bInTongWar = false
    ChatAutoShout.RegEvent()
end

function ChatAutoShout.UnInit()
    self.tbSkillShoutList = nil
    ChatAutoShout.UnRegEvent()
end

function ChatAutoShout.ResetFirstLoadingEnd()
    self.bFirstLoadEnding = false
    self.bInTongWar = false
end

function ChatAutoShout.RegEvent()
    Event.Reg(self, EventType.OnRoleLogin, function()
        ChatAutoShout.InitAutoShoutData()
        ChatAutoShout.InitDeathData()
        ChatAutoShout.InitSkillShoutData()
        ChatAutoShout.ResetFirstLoadingEnd()
    end)

    Event.Reg(self, EventType.OnSkillShoutSaved, function(szType)
        if szType == "tbSkillList" then
            ChatAutoShout.InitSkillShoutData()
        end
    end)

    Event.Reg(self, EventType.UILoadingFinish, function(nMapID)
        local player = g_pClientPlayer
        if not player then
            return
        end

        local dwMapID = player.GetMapID() or 0
        local szMapName = Table_GetMapName(dwMapID) or ""
        szMapName = UIHelper.GBKToUTF8(szMapName)
        if not self.bFirstLoadEnding then
            ChatAutoShout._doAutoShout(UI_Chat_Setting_Type.Auto_Online, {["map"] = szMapName})
            self.bFirstLoadEnding = true
            self.bInTongWar = TongData.IsInDeclarationState()
        else
            ChatAutoShout._doAutoShout(UI_Chat_Setting_Type.Auto_Map, {["map"] = szMapName})
        end
    end)

    Event.Reg(self, "PARTY_ADD_MEMBER", function(_, dwMemberID, nGroupIndex)
        if g_pClientPlayer and g_pClientPlayer.IsPartyLeader() then
            local team = GetClientTeam()
            local dwLeader = team.GetAuthorityInfo(1)
            local szNewMemberName = team.GetClientTeamMemberName(dwMemberID)
            local szLeaderName = team.GetClientTeamMemberName(dwLeader)
            if not dwLeader or dwLeader == 0 then
                return
            end
            szNewMemberName = UIHelper.GBKToUTF8(szNewMemberName)
            szLeaderName = UIHelper.GBKToUTF8(szLeaderName)
            ChatAutoShout._doAutoShout(UI_Chat_Setting_Type.Auto_Party, {["new"] = szNewMemberName, ["leader"] = szLeaderName})
        end
    end)

    Event.Reg(self, "TONG_MEMBER_JOIN", function(szMemberName)
        szMemberName = UIHelper.GBKToUTF8(szMemberName)
        ChatAutoShout._doAutoShout(UI_Chat_Setting_Type.Auto_Tong, {["new"] = szMemberName})
    end)

    Event.Reg(self, "UPDATE_TONG_DIPLOMACY_INFO", function ()
        self.bInTongWar = TongData.IsInDeclarationState()
	end)

    Event.Reg(self, "SYS_MSG", function(arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
        if arg0 == "UI_OME_SKILL_EFFECT_LOG" then
            if arg4 == SKILL_EFFECT_TYPE.SKILL then
                ChatAutoShout.CatchSkillLog(UI_Chat_SkillShout_Type.Hit, arg1, arg2, arg5, arg6)
            end
        elseif arg0 == "UI_OME_SKILL_CAST_LOG" then
            ChatAutoShout.CatchSkillLog(UI_Chat_SkillShout_Type.Spell, arg1, arg5, arg2, arg3, arg4)
        elseif arg0 == "UI_OME_DEATH_NOTIFY" then
            ChatAutoShout.OnDeathNotify(arg1, arg2)
        end
    end)

    Event.Reg(self, "DO_SKILL_CAST", function(dwCaster, dwSkillID, dwLevel)
        ChatAutoShout.CatchSkillLog(UI_Chat_SkillShout_Type.Other, dwCaster, nil, dwSkillID, dwLevel)
    end)
end

function ChatAutoShout.UnRegEvent()
    Event.UnRegAll(self)
end

function ChatAutoShout.InitAutoShoutData()
    if Storage.Chat_AutoShout.bInit then
        return
    end

    -- 当已经有全部的Storage.Chat_AutoShout[szType]时不初始化
    local bNeedReset = false
    local tbConf = tbChatSettingConfig.Other
    for nIndex, v in ipairs(tbConf.tbGroupList) do
        bNeedReset = Storage.Chat_AutoShout[v.szType] == nil
    end

    if bNeedReset then
        for nIndex, v in pairs(tbConf.tbGroupList) do
            Storage.Chat_AutoShout[v.szType] = {}
            Storage.Chat_AutoShout[v.szType][1] = v.szDefaultText
            Storage.Chat_AutoShout[v.szType][2] = {}
        end
    end
    Storage.Chat_AutoShout.bInit = true
    Storage.Chat_AutoShout.Dirty()
end

function ChatAutoShout.InitDeathData()
    if Storage.Chat_DeathShout.bInit then
        return
    end

    -- 当已经有全部的Storage.Chat_DeathShout[szType]时不初始化
    local bNeedReset = false
    local tbConf = tbChatSettingConfig.Death
    for nIndex, v in ipairs(tbConf.tbGroupList) do
        bNeedReset = Storage.Chat_DeathShout[v.szType] == nil
    end

    if bNeedReset then
        for nIndex, v in pairs(tbConf.tbGroupList) do
            Storage.Chat_DeathShout[v.szType] = {}
            Storage.Chat_DeathShout[v.szType][1] = v.szDefaultText
            Storage.Chat_DeathShout[v.szType][2] = {}
        end
    end
    Storage.Chat_DeathShout.bInit = true
    Storage.Chat_DeathShout.Dirty()
end

function ChatAutoShout.InitSkillShoutData()
    self.tbSkillShoutList = {}
    if not Storage.Chat_SkillShout.bInit then
        ChatAutoShout.SaveSkillShout("bInit", true)
        -- ChatAutoShout.SaveSkillShout("tbSkillList", tbSkillShoutConfig)
    end

    for _, tSkill in ipairs(Storage.Chat_SkillShout.tbSkillList) do
        self.tbSkillShoutList[tSkill.szSkillName] = clone(tSkill)
    end
end

local _fnGetSkillName = function(dwSkillID, nLevel)
    local szSkillName = tbSpecialSkillList[dwSkillID]
    if not szSkillName then
        local tSkill = TabHelper.GetUISkill(dwSkillID)
        szSkillName = tSkill and tSkill.szName or ""
        if not tSkill then
            tSkill = Table_GetSkill(dwSkillID, nLevel)
            szSkillName = tSkill and UIHelper.GBKToUTF8(tSkill.szName) or ""
        end
    end
    return szSkillName
end

function ChatAutoShout.CatchSkillLog(nType, dwCasterID, dwTargetID, dwSkillID, nLevel, nTargetType)
    local player = GetClientPlayer()
    if not player
        or (player.dwID ~= dwCasterID and player.dwID ~= dwTargetID)
    then return end

    if (nType == UI_Chat_SkillShout_Type.Other or nType == UI_Chat_SkillShout_Type.Spell)
        and dwCasterID ~= player.dwID
    then return end

    local scene = player.GetScene()
    if not scene then
        return
    end

    local tSkillInfo = TabHelper.GetUISkillMap(dwSkillID) or SkillData.GetUIDynamicSkillMap(dwSkillID, nLevel)
    local nProgressBarDirection = (tSkillInfo and tSkillInfo.nProgressBarDirection) or 0
    local nSourceSkillID = tSkillInfo and tSkillInfo.nSourceSkillID

    if nType == UI_Chat_SkillShout_Type.Spell and nProgressBarDirection == 0 then
        ChatAutoShout.CatchSkillLog(UI_Chat_SkillShout_Type.Other, dwCasterID, nil, dwSkillID, nLevel)
        return
    elseif nType == UI_Chat_SkillShout_Type.Other and nProgressBarDirection ~= 0 then
        return
    end

    local tbSkillList = self.tbSkillShoutList
    local tbChannelList = Storage.Chat_SkillShout.tbChannelList
    local tbForbidMap = Storage.Chat_SkillShout.tbForbidMapList

    if table_is_empty(tbChannelList) then
        return
    end

    for index, _ in pairs(tbForbidMap) do
        if tbForbidMapList[index].fnFilter(scene) then
            return
        end
    end

    local szSkillName = _fnGetSkillName(dwSkillID, nLevel)
    if nSourceSkillID and nSourceSkillID > 0 then
        szSkillName = _fnGetSkillName(nSourceSkillID, 1)
    end

    if not tbSkillList[szSkillName] or not tbSkillList[szSkillName].bApplied then
        return
    end

    local nShoutType = nType
    local szTargetName = player.szName
    if nType == UI_Chat_SkillShout_Type.Hit then
        if dwTargetID == player.dwID then
            local target = GetPlayer(dwCasterID) or GetNpc(dwCasterID)
            szTargetName = target.szName
            nShoutType = UI_Chat_SkillShout_Type.HitReceived
        elseif dwTargetID then
            local target = GetPlayer(dwTargetID) or GetNpc(dwTargetID)
            szTargetName = target.szName
        end
    elseif dwTargetID then
        local target = GetPlayer(dwTargetID) or GetNpc(dwTargetID)
        if target then
            szTargetName = target.szName
        end
    end

    szTargetName = UIHelper.GBKToUTF8(szTargetName)
    ChatAutoShout._doSkillShout(szSkillName, nShoutType, {["skill"] = szSkillName, ["target"] = szTargetName})
end

function ChatAutoShout.OnDeathNotify(deadID, killerID)
    local player = GetClientPlayer()
    if not player then
        return
    end

    local szShoutType
    local pDeadth = GetPlayer(deadID)
    local pKiller = GetPlayer(killerID)
    if not pDeadth then
        return
    end

    local szKiller = pKiller and UIHelper.GBKToUTF8(pKiller.szName) or g_tStrings.STR_NAME_UNKNOWN
    local szDeadPlayer = pDeadth and UIHelper.GBKToUTF8(pDeadth.szName) or g_tStrings.STR_NAME_UNKNOWN
    local szTongName = ""
    local dwMapID = player.GetMapID() or 0
    local szMapName = Table_GetMapName(dwMapID) or ""
    szMapName = UIHelper.GBKToUTF8(szMapName)

    if deadID == player.dwID then -- 被伤
        szTongName = player.dwTongID and TongData.GetName(player.dwTongID) or ""
        szShoutType = UI_Chat_Setting_Type.Auto_BeKill
        if self.bInTongWar then
            -- 帮战期间不发被杀喊话防止和系统自带被杀喊话冲突
            return
        end
    elseif killerID == player.dwID then -- 击伤
        szTongName = (pDeadth and pDeadth.dwTongID) and TongData.GetName(pDeadth.dwTongID) or ""
        szShoutType = UI_Chat_Setting_Type.Auto_Kill
    elseif IsAlly(player.dwID, killerID) and player.bFightState then
        szTongName = (pDeadth and pDeadth.dwTongID) and TongData.GetName(pDeadth.dwTongID) or ""
        szShoutType = UI_Chat_Setting_Type.Auto_AssistKill
    end

    if not string.is_nil(szShoutType) then
        szTongName = szTongName and UIHelper.GBKToUTF8(szTongName) or ""
        ChatAutoShout._doDeathShout(szShoutType, {["killer"] = szKiller, ["tong"] = szTongName, ["dead"] = szDeadPlayer, ["map"] = szMapName})
    end
end

function ChatAutoShout._AutoShoutByShoutType(tbSendChannel, tbSendText)
    local player = GetClientPlayer()
    if not player then
        return
    end

    local bResult = false
    local bTalkUnlocked = BankLock.IsPhoneLock() and player.CheckSafeLock(SAFE_LOCK_EFFECT_TYPE.TALK) or true
    if tbSendChannel and not table_is_empty(tbSendChannel) then
        for k, nID in ipairs(tbSendChannel) do
            local bCanShout = true
            if nID == PLAYER_TALK_CHANNEL.TEAM then
                bCanShout = player.IsInParty()
            elseif nID == PLAYER_TALK_CHANNEL.RAID then
                bCanShout = player.IsInParty()

                if player.GetScene().nType == MAP_TYPE.BATTLE_FIELD then
                    nID = PLAYER_TALK_CHANNEL.BATTLE_FIELD
                    bCanShout = true
                end
            elseif nID == PLAYER_TALK_CHANNEL.TONG then
                bCanShout = TongData.HavePlayerJoinedTong()
            elseif nID == PLAYER_TALK_CHANNEL.TONG_ALLIANCE then
                bCanShout = TongData.GetAllianceTongID() > 0
            end

            if bCanShout then
                if not bTalkUnlocked then -- 需要判断一下解锁
                    TipsHelper.ShowImportantRedTip("未解除聊天锁，发送自动喊话信息失败。")
                else
                    ChatData.Send(nID, nil, tbSendText)
                    bResult = true
                end
            end
        end
    end

    return bResult
end

function ChatAutoShout._parseShoutInfo(szType, tbSetting, tbParams, szSource)
    if not tbSetting or table_is_empty(tbSetting) then
        return
    end
    local szSendText = tbSetting[1]
    local tbSendChannel = tbSetting[2]
    local nIndex = 1
    for _, szTag in ipairs(tbTagList[szType]) do
        if string.find(szSendText, "@"..szTag) then
            local rel = ""
            if szTag == "self" then
                rel = UIHelper.GBKToUTF8(PlayerData.GetPlayerName())
            elseif szTag == "tong" then
                rel = tbParams[szTag] or UIHelper.GBKToUTF8(TongData.GetName())
            else
                rel = tbParams[szTag]
                nIndex = nIndex + 1
            end

            rel = rel or ""
            szSendText = string.gsub(szSendText, "@"..szTag, rel)
        end
    end

    local tbSendText = ChatParser.Parse(szSendText)
    if not tbSendText[1] or not string.is_nil(tbSendText[1].name) or tbSendText[1].type ~= "eventlink" then
        table.insert(tbSendText, 1, {
            type = "eventlink",
            name = "",
            linkinfo = JsonEncode({
                via = "JX",
                source = szSource and tostring(szSource),
            })
        })
    end
    return tbSendChannel, tbSendText
end

local fnGetSource = function(szType)
    local tbConfig = ChatAutoShout.GetConfigList("Other")
    for index, v in pairs(tbConfig.tbGroupList) do
        if v.szType == szType then
            local szSource = tbSourceType.Other..index
            return szSource
        end
    end
end

function ChatAutoShout._doAutoShout(szType, tbParams)
    local tbSetting = ChatAutoShout.GetShoutInfo(szType)
    if not tbSetting then
        return
    end

    local szSource = fnGetSource(szType)
    local tbSendChannel, tbSendText = ChatAutoShout._parseShoutInfo(szType, tbSetting, tbParams, szSource)
    ChatAutoShout._AutoShoutByShoutType(tbSendChannel, tbSendText)
end

function ChatAutoShout._doDeathShout(szType, tbParams)
    local tbRuntimeMap = Storage.Chat_DeathShout
    if not tbRuntimeMap then
        return
    end

    local tbSetting = tbRuntimeMap[szType]
    local tbSendChannel, tbSendText = ChatAutoShout._parseShoutInfo(szType, tbSetting, tbParams, tbSourceType.Death)
    ChatAutoShout._AutoShoutByShoutType(tbSendChannel, tbSendText)
end

local function _checkColdDown(nTime)
    local nCurTime = GetCurrentTime()
    return nCurTime - nTime < SKILL_SHOUT_COLD_DOWN
end

function ChatAutoShout._doSkillShout(szSkillName, nShoutType, tbParams)
    local tbSetting = {}
    local tbSkillList = self.tbSkillShoutList
    local tbChannelList = Storage.Chat_SkillShout.tbChannelList
    if not tbSkillList[szSkillName] then
        return
    end

    local nLastShoutTime = tbSkillList[szSkillName].nLastShoutTime
    local szShoutContent = tbSkillList[szSkillName][nShoutType]
    if not szShoutContent then
        return
    end

    if nLastShoutTime and _checkColdDown(nLastShoutTime) then
        return
    end

    tbSetting[1] = szShoutContent
    tbSetting[2] = tbChannelList
    if tbSetting[1] and tbSetting[2] then
        local tbSendChannel, tbSendText = ChatAutoShout._parseShoutInfo(UI_Chat_Setting_Type.Auto_Skill, tbSetting, tbParams, tbSourceType.Skill)
        local bResult = ChatAutoShout._AutoShoutByShoutType(tbSendChannel, tbSendText)
        if bResult then
            tbSkillList[szSkillName].nLastShoutTime = GetCurrentTime()
        end
    end
end

function ChatAutoShout.GetShoutInfo(szType)
    local tbRuntimeMap = Storage.Chat_AutoShout
    if not tbRuntimeMap then
        return
    end

    local tbSetting = tbRuntimeMap[szType]
    return clone(tbSetting)
end

function ChatAutoShout.GetConfigList(szType)
    if not string.is_nil(szType) and tbChatSettingConfig[szType] then
        return tbChatSettingConfig[szType]
    end

    return tbChatSettingConfig
end

function ChatAutoShout.GetTagList(szType)
    return tbTagList[szType]
end

function ChatAutoShout.GetSkillShoutType()
    return tbSkillShoutType
end

function ChatAutoShout.GetForbidMapList()
    return tbForbidMapList
end

function ChatAutoShout.GetChannelList()
    return tbApplyChannelList
end

function ChatAutoShout.GetPlayerName()
    local szPlayerName = ""
    local player = GetClientPlayer()
    if not player then
        return szPlayerName
    end

    szPlayerName = player.szName

    return UIHelper.GBKToUTF8(szPlayerName)
end

function ChatAutoShout.GetMapName()
    local szMapName = ""
    local player = GetClientPlayer()
    if not player then
        return szMapName
    end

    local nMapID = player.GetMapID()
    szMapName = Table_GetMapName(nMapID)

    return UIHelper.GBKToUTF8(szMapName)
end

function ChatAutoShout.GetSkillShoutList()
    local tbInfo = {}
    local tbSkillShoutList = {}
    if Storage.Chat_SkillShout and Storage.Chat_SkillShout.tbSkillList then
        tbSkillShoutList = clone(Storage.Chat_SkillShout.tbSkillList) or {}
    end

    for _, v in ipairs(tbSkillShoutList) do
        local tSkill = {szTitle = v.szSkillName, szShoutContent = v.szShoutContent}
        table.insert(tbInfo, tSkill)
    end

    return tbInfo
end

function ChatAutoShout.IsSpecialSkill(szName)
    for k, v in pairs(tbSpecialSkillList) do
        if v == szName then
            return true
        end
    end

    return false
end

function ChatAutoShout.SaveSkillShout(szType, param)
    if not Storage.Chat_SkillShout or Storage.Chat_SkillShout[szType] == nil then
        return
    end
    local tbSkillData = Storage.Chat_SkillShout
    tbSkillData[szType] = param

    Storage.Chat_SkillShout.Dirty()
    Event.Dispatch(EventType.OnSkillShoutSaved, szType)
end

function ChatAutoShout.CheckIsSkillNameEquiped(szSkillName)
    local bEquiped = false
    if not self.tbSkillShoutList then
        return bEquiped
    end

    bEquiped = table.contain_key(self.tbSkillShoutList, szSkillName)
    return bEquiped
end
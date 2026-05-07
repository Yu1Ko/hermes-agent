--搬运自：interface\JX\JX_0Base\JX.lua 只搬运了部分

------------------------------
--   JX插件自用基础函数库
------------------------------

JX = { className = "JX" }

JX.LoadLangPack = LoadLangPack("mui/Lua/Logic/JX/lang") -- 版本语言处理
local _L = JX.LoadLangPack

local _JX = {
    aPlayer = {},
    aNpc = {},
    aDoodad = {},
    tKungfuID = {}, -- 取过的目标心法缓存
    tTongName = {}, -- 取过的目标心法缓存
    szMsgTitle = "" -- "剑心插件" -- _L["JxMsgTitle"], -- 聊天提示专用标记
}

local math = math
local tinsert, tremove, tconcat = table.insert, table.remove, table.concat
local mfloor, msqrt, mabs, mmin, mmax, mp = math.floor, math.sqrt, math.abs, math.min, math.max, math.pi
local sgsub, sformat, ssub, slen, sfind = string.gsub, string.format, string.sub, string.len, string.find
local pairs, ipairs = pairs, ipairs
local type = type

local IsAddonBanMap = function(dwMapID)
    if Table_IsMobaBattleFieldMap(dwMapID) or
            Table_IsZombieBattleFieldMap(dwMapID) or
            Table_IsTreasureBattleFieldMap(dwMapID) or
            Table_IsPleasantGoatBattleFieldMap(dwMapID) then
        return true
    end
    return false
end

-- 聊天栏输出信息
JX.Sysmsg = function(szMsg, szHead, szType)
    szHead = szHead or _JX.szMsgTitle
    szType = szType or "MSG_SYS"
    OutputMessage(szType, szMsg .. "\n")
end

-- 公告栏输出信息
JX.SysAnnounce = function(szMsg, szHead, szColor)
    szHead = szHead or _JX.szMsgTitle
    szColor = szColor or "red"
    if type(szColor) ~= "string" then
        return
    end
    szColor = szColor:lower()
    if szColor == "red" then
        --OutputMessage("MSG_ANNOUNCE_RED", "[" .. szHead .. "]" .. szMsg)
        OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
    elseif szColor == "yellow" then
        OutputMessage("MSG_ANNOUNCE_YELLOW", szMsg)
    end
end

-- 显示密聊信息 -- 消息，发送者
JX.WriteWhisper = function(dwTalkerID, tTongMemberInfo, szMsg, szTalker, szType)
    szTalker        = szTalker or _JX.szMsgTitle
    szType          = szType or g_tStrings.STR_TALK_HEAD_WHISPER
    --local font = GetMsgFontString("MSG_WHISPER")
    --szTalker = "<text>text=" .. EncodeComponentsString("[" .. szTalker .. "]") .. font .." name=\"namelink\" eventid=515</text>"
    --szMsg = "<text>text=" .. EncodeComponentsString(szType .. szMsg .. "\n") .. font .. "</text>"
    szMsg           = szType .. szMsg .. "\n"
    --OutputMessage("MSG_WHISPER", szTalker .. szMsg, true)

    local szContent = {
        szMsg,
        szMsg,
        {
            { type = "text", text = UIHelper.UTF8ToGBK(szMsg) },
        },
        false,
    }

    local dwForceID = 0
    local nLevel    = 120
    if tTongMemberInfo then
        dwForceID = tTongMemberInfo.nForceID
        nLevel    = tTongMemberInfo.nLevel
    end

    local bTongMsg = true

    ChatData.Append(szContent, dwTalkerID, PLAYER_TALK_CHANNEL.WHISPER, false, szTalker, false, false, false,
                    false, 0, 0, 0, dwForceID, nLevel, 0, nil, nil, bTongMsg)

    PlaySound(SOUND.UI_SOUND, g_sound.Whisper)
end

-- 通过附近的玩家名字尝试返回玩家对象
JX.GetPlayerByName = function(szName)
    local aPlayer = PlayerData.GetAllPlayer()
    for _, player in pairs(aPlayer) do
        if player.szName == szName then
            return player
        end
    end
    return nil
end

-- 获取目标的心法
JX.GetKungfuMountID = function(tar)
    if not tar then
        return
    end
    local skillID = tar.GetActualKungfuMountID()
    if skillID and skillID ~= 0 then
        if not _JX.tKungfuID[tar.dwID] or _JX.tKungfuID[tar.dwID] ~= skillID then
            _JX.tKungfuID[tar.dwID] = skillID
        end
        return skillID
    end
    return _JX.tKungfuID[tar.dwID]
end

-- 获取带心法类型的玩家dwID列表 -- t[kfType] = {p1,p2,...}-- 0：大侠/其他，1：DPS，2：HPS，3：MT
JX.GetKungfuTypePlayer = function()
    local _tPlayer = {}
    for dwplayerID, player in pairs(PlayerData.GetAllPlayer()) do
        local nKFType = JX.GetKungfuType(player)
        _tPlayer[nKFType] = _tPlayer[nKFType] or {}
        tinsert(_tPlayer[nKFType], dwplayerID)
    end
    return _tPlayer
end

-- 获取带门派的玩家dwID列表 -- t[forceid] = {p1,p2,...}
JX.GetForcePlayer = function()
    local _tPlayer = {}
    local tList = Table_GetAllForceUI()
    for forceid in pairs(tList) do
        _tPlayer[forceid] = {}
    end
    for dwplayerID, player in pairs(PlayerData.GetAllPlayer()) do
        tinsert(_tPlayer[player.dwForceID], dwplayerID)
    end
    return _tPlayer
end

-- 获取同步范围内所有玩家列表[dwID]=true
--JX.aPlayer = _JX.aPlayer

-- 获取同步范围内所有NPC对象
JX.GetAllNpc = function()
    local aNpc = {}
    for k, _ in pairs(_JX.aNpc) do
        local n = GetNpc(k)
        if not n then
            _JX.aNpc[k] = nil
        else
            aNpc[k] = n
        end
    end
    return aNpc
end

-- 获取同步范围内所有NPC列表[dwID]=true
JX.aNpc = _JX.aNpc

-- 通过附近的NPCTemplateID尝试返回NPC对象
JX.GetNpcByTemplateID = function(dwTemplateID)
    local aNpc = JX.GetAllNpc()
    for _, n in pairs(aNpc) do
        if n.dwTemplateID == dwTemplateID then
            return n
        end
    end
    return nil
end

-- 通过附近的NPC名字尝试返回NPC对象
JX.GetNpcByName = function(szName)
    local aNpc = JX.GetAllNpc()
    for _, n in pairs(aNpc) do
        if n.szName == szName then
            return n
        end
    end
    return nil
end

-- 通过附近的NPC名字尝试返回最近的NPC对象
JX.GetNearbyNpcByName = function(szName)
    local aNpc = JX.GetAllNpc()
    local t = {}
    for _, n in pairs(aNpc) do
        if n.szName == szName then
            tinsert(t, n)
        end
    end
    if #t == 0 then
        return nil
    end
    local nDis = 1000000
    local rst = nil
    for _, v in ipairs(t) do
        local _nDis = JX.GetDistance(v)
        if _nDis <= nDis then
            nDis = _nDis
            rst = v
        end
    end
    return rst
end

-- 获取目标或自己的心法类型 -- 1：DPS，2：HPS，3：MT，4：大侠/其他
JX.GetKungfuType = function(tar)
    tar = tar or GetClientPlayer()
    if not tar then
        return 0
    end
    local skillID = JX.GetKungfuMountID(tar)
    local nKungfuType = GetKungfuTypeByKungfuID(skillID)
    return nKungfuType
end

-- 获取同步范围内所有Doodad对象
JX.GetAllDoodad = function()
    local aDoodad = {}
    for k, _ in pairs(_JX.aDoodad) do
        local d = GetDoodad(k)
        if not d then
            _JX.aDoodad[k] = nil
        else
            aDoodad[k] = d
        end
    end
    return aDoodad
end

-- 获取同步范围内所有Doodad列表[dwID]=true
JX.aDoodad = _JX.aDoodad

-- 通过附近的Doodad名字尝试返回Doodad对象
JX.GetDoodadByName = function(szName)
    local aDoodad = JX.GetAllDoodad()
    for _, n in pairs(aDoodad) do
        if n.szName == szName then
            return n
        end
    end
    return nil
end

-- 通过附近的Doodad名字尝试返回最近的Doodad对象
JX.GetNearbyDoodadByName = function(szName)
    local aDoodad = JX.GetAllDoodad()
    local t = {}
    for _, n in pairs(aDoodad) do
        if n.szName == szName then
            tinsert(t, n)
        end
    end
    if #t == 0 then
        return nil
    end
    local nDis = 1000000
    local rst = nil
    for _, v in ipairs(t) do
        local _nDis = JX.GetDistance(v)
        if _nDis <= nDis then
            nDis = _nDis
            rst = v
        end
    end
    return rst
end

-- 计算玩家和目标的3D距离 -- 支持传:目标对象；XYZ坐标
JX.GetDistance = function(nX, nY, nZ)
    if not nX then
        return 0
    end
    local player = GetClientPlayer()
    if not nY then
        local target = nX
        nX, nY, nZ = target.nX, target.nY, target.nZ
    end
    return mfloor(msqrt((player.nX - nX) ^ 2 + (player.nY - nY) ^ 2 + (player.nZ / 8 - nZ / 8) ^ 2)) / 64
end
-- 计算玩家和目标的2D距离 -- 支持传:目标对象；XY坐标
JX.GetDistance2D = function(nX, nY)
    if not nX then
        return 0
    end
    local player = GetClientPlayer()
    if not nY then
        local target = nX
        nX, nY = target.nX, target.nY
    end
    return mfloor(msqrt((player.nX - nX) ^ 2 + (player.nY - nY) ^ 2)) / 64
end
-- 计算两个对象之间的3D距离 -- 单位尺
JX.GetDistanceTwice = function(tar1, tar2)
    if not tar1 or not tar2 then
        return 0
    end
    return mfloor(msqrt((tar1.nX - tar2.nX) ^ 2 + (tar1.nY - tar2.nY) ^ 2 + (tar1.nZ / 8 - tar2.nZ / 8) ^ 2)) / 64
end
-- 计算两个对象之间的2D距离 -- 单位尺
JX.GetDistanceTwice2D = function(tar1, tar2)
    if not tar1 or not tar2 then
        return 0
    end
    return mfloor(msqrt((tar1.nX - tar2.nX) ^ 2 + (tar1.nY - tar2.nY) ^ 2)) / 64
end

-- 计算两个点之间的3D距离 -- 单位尺
JX.GetDistancePoint = function(nX1, nY1, nZ1, nX2, nY2, nZ2)
    if not (nX1 and nY1 and nZ1 and nX2 and nY2 and nZ2) then
        return 0
    end
    return mfloor(msqrt((nX1 - nX2) ^ 2 + (nY1 - nY2) ^ 2 + (nZ1 / 8 - nZ2 / 8) ^ 2)) / 64
end

-- 计算两个点之间的3D距离 -- 单位尺
JX.GetDistancePoint2D = function(nX1, nY1, nZ1, nX2, nY2, nZ2)
    if not (nX1 and nY1 and nZ1 and nX2 and nY2 and nZ2) then
        return 0
    end
    return mfloor(msqrt((nX1 - nX2) ^ 2 + (nY1 - nY2) ^ 2)) / 64
end

-- 是否在JJC场景
JX.IsArenaMap = function(scene)
    if not scene then
        local player = GetClientPlayer()
        if player then
            scene = player.GetScene()
        end
    end
    if scene then
        return scene.bIsArenaMap
    end
    return false
end

-- 是否战场场景
JX.IsBattleFieldMap = function(dwMapID)
    if not dwMapID then
        local player = GetClientPlayer()
        if not player then
            return false
        end
        dwMapID = player.GetMapID()
    end
    return Table_IsBattleFieldMap(dwMapID)
end

-- 是否在家园地图
JX.IsHomelandMap = function(dwMapID)
    local tHomelandID = Table_GetHomelandMapList()
    if not dwMapID then
        local player = GetClientPlayer()
        if not player then
            return false
        end
        dwMapID = player.GetMapID()
    end
    for _, v in ipairs(tHomelandID) do
        if v == dwMapID then
            return true
        end
    end
    return false
end

-- 是否是MOBA场景
JX.IsMobaBFMap = function(dwMapID)
    if not dwMapID then
        dwMapID = 0
        local player = GetClientPlayer()
        if player then
            dwMapID = player.GetMapID()
        end
    end
    return Table_IsMobaBattleFieldMap and Table_IsMobaBattleFieldMap(dwMapID)
end
-- 是否是吃鸡场景
JX.IsTreasureBFMap = function(dwMapID)
    if not dwMapID then
        dwMapID = 0
        local player = GetClientPlayer()
        if player then
            dwMapID = player.GetMapID()
        end
    end
    return Table_IsTreasureBattleFieldMap and Table_IsTreasureBattleFieldMap(dwMapID)
end
-- 是否是生化场景
JX.IsZombieBFMap = function(dwMapID)
    if not dwMapID then
        dwMapID = 0
        local player = GetClientPlayer()
        if player then
            dwMapID = player.GetMapID()
        end
    end
    return Table_IsZombieBattleFieldMap and Table_IsZombieBattleFieldMap(dwMapID)
end
-- 是否是帮会联赛场景
JX.IsTongLeagueMap = function(dwMapID)
    if not dwMapID then
        dwMapID = 0
        local player = GetClientPlayer()
        if player then
            dwMapID = player.GetMapID()
        end
    end
    return Table_IsTongWarFieldMap and Table_IsTongWarFieldMap(dwMapID)
end
-- 是否是跨服·烂柯山/跨服·河西瀚漠场景
JX.IsRemotePvpMap = function()
    local me = GetClientPlayer()
    return me and (me.GetMapID() == 627 or me.GetMapID() == 697)
end

-- 是否是精简背包类型的地图
JX.IsBoxLimitMap = function(dwMapID)
    if not dwMapID then
        dwMapID = 0
        local player = GetClientPlayer()
        if player then
            dwMapID = player.GetMapID()
        end
    end
    return UIscript_IsBoxLimitMap and UIscript_IsBoxLimitMap(dwMapID)
end
-- 是否是被ban掉插件的地图
JX.IsBanMap = function()
    if JX.IsDebugEnable() or not Table_IsTreasureBattleFieldMap then
        return false
    end
    local CPlayer = GetClientPlayer()
    local dwMapID = CPlayer and CPlayer.GetMapID()
    if not dwMapID then
        return false
    end
    return IsAddonBanMap(dwMapID)
end

-- 内网测试开关
JX.IsDebugEnable = function()
    -- if IsDebugClient() and JX.bDevelopmentMode then -- 方便内网测试
    --     return true
    -- end
    return false
end

-- 获取目标对象
JX.GetTarget = function()
    local CPlayer = GetClientPlayer()
    if not CPlayer then
        return
    end
    local _, tarID = CPlayer.GetTarget()
    if not tarID or tarID == 0 then
        return
    end
    return GetNpc(tarID) or GetPlayer(tarID)
end

-- 获取指定对象
JX.GetObject = function(dwID)
    return GetNpc(dwID) or GetPlayer(dwID) or GetDoodad(dwID)
end

JX.FirstInit = function()
    _JX.LoadFBBoss()
end

-- 加载副本BOSS列表
_JX.LoadFBBoss = function()
    _JX.tFBBossTemplateID = LoadLUAData("mui/Lua/Logic/JX/BossList_ID.jx3dat") or {}
    local nCount = g_tTable.DungeonNpc:GetRowCount()
    for i = 2, nCount do
        local tLine = g_tTable.DungeonNpc:GetRow(i)
        local dwNpcID = tLine.dwNpcID
        if dwNpcID and dwNpcID ~= "" and not _JX.tFBBossTemplateID[dwNpcID] then
            _JX.tFBBossTemplateID[dwNpcID] = true
        end
    end
    local tAddBossList = LoadLUAData("mui/Lua/Logic/JX/BossList_zhcn.jx3dat") or {}
    for _, v in pairs(tAddBossList) do
        if v.ADD and type(v.ADD) == "table" then
            for kk, _ in pairs(v.ADD) do
                _JX.tFBBossTemplateID[kk] = true
            end
        end
    end
end

-- 是否是副本BOSS
JX.IsFBBoss = function(dwTemplateID)
    return _JX.tFBBossTemplateID and _JX.tFBBossTemplateID[dwTemplateID]
end

JX.GetCurrentLife = function(obj)
    return obj.fCurrentLife64 or obj.nCurrentLife
end
JX.GetMaxLife = function(obj)
    return obj.fMaxLife64 or obj.nMaxLife
end

-- 获取指定对象的名字(通用)
JX.GetObjectName = function(obj)
    if not obj then
        return ""
    end
    local szName = obj.szName
    if IsPlayer(obj.dwID) then
        -- PLAYER
        szName = szName
    elseif JX.GetMaxLife(obj) then
        -- NPC
        if szName == "" then
            szName = Table_GetNpcTemplateName(obj.dwTemplateID)
        end
        if obj.dwEmployer and obj.dwEmployer ~= 0 and szName == Table_GetNpcTemplateName(obj.dwTemplateID) then
            local emp = GetPlayer(obj.dwEmployer)
            if not emp then
                szName = UIHelper.UTF8ToGBK(g_tStrings.STR_SOME_BODY .. g_tStrings.STR_PET_SKILL_LOG) .. obj.szName
            else
                szName = emp.szName .. UIHelper.UTF8ToGBK(g_tStrings.STR_PET_SKILL_LOG) .. obj.szName
            end
        end
    elseif obj.CanLoot then
        -- DOODAD
        if szName == "" then
            szName = Table_GetDoodadTemplateName(obj.dwTemplateID)
        end
    elseif obj.IsRepairable then
        -- ITEM
        szName = ItemData.GetItemNameByItem(obj)
    end
    if not szName then
        szName = ""
    end
    return UIHelper.GBKToUTF8(szName)
end

-- 获取tab内总个数
JX.GetTableCount = function(tTab)
    local nCount = 0
    if not tTab then
        return nCount
    end
    for _, _ in pairs(tTab) do
        nCount = nCount + 1
    end
    return nCount
end

-- 获取带帮会的玩家dwID列表 -- t[tongID] = {p1,p2,...}
JX.GetTongPlayer = function()
    local _tPlayer = {}
    for dwplayerID, player in pairs(PlayerData.GetAllPlayer()) do
        _tPlayer[player.dwTongID] = _tPlayer[player.dwTongID] or {}
        tinsert(_tPlayer[player.dwTongID], dwplayerID)
    end
    return _tPlayer
end

JX.GetTongName = function(dwTongID)
    if not dwTongID or dwTongID == 0 then
        return
    end
    if not _JX.tTongName[dwTongID] then
        _JX.tTongName[dwTongID] = GetTongClient().ApplyGetTongName(dwTongID)
    end
    return _JX.tTongName[dwTongID]
end

-- 获取带服务器前缀的玩家dwID列表 -- t[serverName] = {p1,p2,...}
JX.GetServerPlayer = function()
    local _tPlayer = {}
    for dwplayerID, player in pairs(PlayerData.GetAllPlayer()) do
        local serverName
        local szName = UIHelper.GBKToUTF8(player.szName)
        local n1, n2 = sfind(szName, '·')
        if n1 then
            serverName = ssub(szName, n2 + 1)
        end
        if serverName then
            _tPlayer[serverName] = _tPlayer[serverName] or {}
            tinsert(_tPlayer[serverName], dwplayerID)
        end
    end
    return _tPlayer
end

-- 增加小地图标记 -- nkey>100，nLeftTime单位帧0清除
JX.UpdateMiniMapMark = function(nkey, dwIndex, nX, nY, nLeftTime, nIcon)
    Event.Dispatch("ON_ENEMY_PLAYER_ENTER", nkey, dwIndex, nX, nY, nLeftTime or 16)
end

-- 判断某个频道能否发言
JX.CanTalk = function(nChannel)
    for _, v in ipairs({ 'WHISPER', 'TEAM', 'RAID', 'BATTLE_FIELD', 'NEARBY', 'TONG', 'TONG_ALLIANCE' }) do
        if nChannel == PLAYER_TALK_CHANNEL[v] then
            return true
        end
    end
    return false
end

-- 获取Talk用的当前频道
JX.GetTalkChannel = function()
    local nChannel, szName = EditBox_GetChannel()
    if nChannel == PLAYER_TALK_CHANNEL.WHISPER then
        return szName
    end
    return nChannel
end


-- 发布聊天内容 -- [频道 or 密聊的目标角色名]，聊天内容
-- szTarget       -- 密聊的目标角色名
-- szText         -- 聊天内容，（亦可为兼容 KPlayer.Talk 的 table）
-- nChannel       -- *可选* 聊天频道，PLAYER_TALK_CHANNLE.*，默认为近聊
-- bSaveDeny      -- *可选* 在聊天输入栏保留不可发言的频道内容，默认为 false
-- bPushToChatBox -- *可选* 仅推送到聊天框，默认为 false
-- 战场/团队聊天频道智能切换
JX.Talk = function(nChannel, szText, bSaveDeny, bPushToChatBox, szUUID, szSource)
    if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TALK, "player talk", true) then
        return TipsHelper.ShowNormalTip(UIHelper.GBKToUTF8(_L['chat safe locked, send failed']))
    end

    local szTarget, player = "", GetClientPlayer()
    if not nChannel and not szText then
        return
    elseif not nChannel then
        nChannel = PLAYER_TALK_CHANNEL.NEARBY
    elseif type(nChannel) == "string" then
        if not szText then
            szText = nChannel
            nChannel = PLAYER_TALK_CHANNEL.NEARBY
        else
            szTarget = nChannel
            nChannel = PLAYER_TALK_CHANNEL.WHISPER
        end
    elseif nChannel == PLAYER_TALK_CHANNEL.RAID and player.GetScene().nType == MAP_TYPE.BATTLE_FIELD then
        nChannel = PLAYER_TALK_CHANNEL.BATTLE_FIELD
    elseif nChannel == PLAYER_TALK_CHANNEL.LOCAL_SYS then
        return JX.Sysmsg(szText, '')
    elseif (nChannel == PLAYER_TALK_CHANNEL.TEAM or nChannel == PLAYER_TALK_CHANNEL.RAID) and not player.IsInParty() then
        return
    end
    local tSay = nil
    if type(szText) == "table" then
        tSay = szText
    else
        --if string.len(szText) > 150 then
        --    szText = string.sub(szText, 1, 150)
        --end
        --tSay = { { type = "text", text = szText .. "\n" } }
        tSay = ChatParser.Parse(UIHelper.GBKToUTF8(szText))
    end
    --tSay = ParseEmotionCommand(tSay, true)

    -- player.Talk(nChannel, szTarget, tSay)
    if bPushToChatBox or (bSaveDeny and not JX.CanTalk(nChannel)) then
        --local edit = Station.Lookup('Lowest2/EditBox/Edit_Input')
        --edit:ClearText()
        --for _, v in ipairs(tSay) do
        --    edit:InsertObj(v.text, v)
        --end
        --JX.SwitchChat(nChannel)
        --Station.SetFocusWindow(edit)
    else
        if not tSay[1] or tSay[1].name ~= '' or tSay[1].type ~= 'eventlink' then
            table.insert(tSay, 1, {
                type = 'eventlink',
                name = '',
                linkinfo = JsonEncode({
                    via = 'JX',
                    uuid = szUUID and tostring(szUUID),
                    source = szSource and tostring(szSource),
                })
            })
        end
        if player.CanUseNewChatSystem(nChannel) then
            player.PushChat(nChannel, szTarget, nil, nil, nil, nil, true, tSay)
            -- / GetClientPlayer().PushChat(1, "", nil, nil, nil, nil, ParseEmotionCommand({{ type = "text", text="33313\n"}}, true))
        end
    end
end

-- 判断两个Unix时间戳是否经过【每天】七点
JX.CheckPassSevenTime = function(nOldTime, nCurrentTime)
    local tTime = TimeToDate(nCurrentTime)
    local nSevenTime = DateToTime(tTime.year, tTime.month, tTime.day, 7, 0, 0)
    if tTime.hour >= 7 then
        if nOldTime < nSevenTime then
            return true
        end
    elseif nOldTime < nSevenTime - 24 * 3600 then
        return true
    end
    return false
end

do
    local BG_EVENT_LIST = {}
    ------------------------------------
    --           背景通讯            --
    ------------------------------------
    -- ON_BG_CHANNEL_MSG
    -- arg0: 消息szKey
    -- arg1: 消息来源频道
    -- arg2: 消息发布者ID
    -- arg3: 消息发布者名字
    -- arg4: 不定长参数数组数据
    ------------------------------------
    local function OnBgEvent()
        local szEvent, nChannel, dwID, szName, aParam = arg0, arg1, arg2, arg3, arg4
        if dwID ~= UI_GetClientPlayerID() and szEvent and BG_EVENT_LIST[szEvent] then
            for szKey, fnAction in pairs(BG_EVENT_LIST[szEvent]) do
                local status, err = pcall(fnAction, szEvent, dwID, szName, nChannel, unpack(aParam))
                if not status then
                    TipsHelper.ShowImportantRedTip("BG_EVENT#" .. szEvent .. "." .. szKey .. "---" .. err)
                end
            end
        end
    end
    Event.Reg(JX, "ON_BG_CHANNEL_MSG", OnBgEvent)

    -- JX.RegisterBgEvent("JX_CHECK_INSTALL", function(dwTalkerID, szTalkerName, nChannel, oData) JX.BgTalk(szTalkerName, "ASK_CURRENT_LOC", oData) end) -- 注册
    -- JX.RegisterBgEvent("JX_CHECK_INSTALL") -- 注销
    -- JX.RegisterBgEvent("JX_CHECK_INSTALL.RECEIVER_01", function(dwTalkerID, szTalkerName, nChannel, oData) JX.BgTalk(szTalkerName, "ASK_CURRENT_LOC", oData) end) -- 注册
    -- JX.RegisterBgEvent("JX_CHECK_INSTALL.RECEIVER_01") -- 注销
    JX.RegisterBgEvent = function(szEvent, fnAction)
        local szKey = nil
        local nPos = string.find(szEvent, ".")
        if nPos and nPos ~= 1 then
            szKey = ssub(szEvent, nPos + 1)
            szEvent = ssub(szEvent, 1, nPos - 1)
        end
        if fnAction then
            if not BG_EVENT_LIST[szEvent] then
                BG_EVENT_LIST[szEvent] = {}
            end
            if szKey then
                BG_EVENT_LIST[szEvent][szKey] = fnAction
            else
                tinsert(BG_EVENT_LIST[szEvent], fnAction)
            end
        else
            if szKey then
                BG_EVENT_LIST[szEvent][szKey] = nil
            else
                BG_EVENT_LIST[szEvent] = nil
            end
        end
    end

    -- JX.BgTalk(szName, szEvent, ...)
    -- JX.BgTalk(nChannel, szEvent, ...)
    JX.BgTalk = function(nChannel, szEvent, ...)
        local szTarget, me = "", GetClientPlayer()
        if not (me and nChannel) then
            return
        end
        -- channel
        if type(nChannel) == "string" then
            szTarget = nChannel
            nChannel = PLAYER_TALK_CHANNEL.WHISPER
        end
        -- auto switch battle field
        if nChannel == PLAYER_TALK_CHANNEL.RAID
                and me.GetScene().nType == MAP_TYPE.BATTLE_FIELD then
            nChannel = PLAYER_TALK_CHANNEL.BATTLE_FIELD
        end
        -- talk
        local tSay = { { type = "eventlink", name = "BG_CHANNEL_MSG", linkinfo = szEvent } }
        local tArg = { ... }
        local nCount = select("#", ...)
        for i = 1, nCount do
            tinsert(tSay, { type = "eventlink", name = "", linkinfo = var2str(tArg[i]) })
        end
        me.Talk(nChannel, szTarget, tSay)
    end
end

------------------------------
--         事件注册          --
------------------------------

-- Event.Reg(JX, "PLAYER_ENTER_SCENE", function() _JX.aPlayer[arg0] = true end)
-- Event.Reg(JX, "PLAYER_LEAVE_SCENE", function() _JX.aPlayer[arg0] = nil end)
Event.Reg(JX, "NPC_ENTER_SCENE", function()
    _JX.aNpc[arg0] = true
end)
Event.Reg(JX, "NPC_LEAVE_SCENE", function()
    _JX.aNpc[arg0] = nil
end)
Event.Reg(JX, "DOODAD_ENTER_SCENE", function()
    _JX.aDoodad[arg0] = true
end)
Event.Reg(JX, "DOODAD_LEAVE_SCENE", function()
    _JX.aDoodad[arg0] = nil
end)

function JX.OnRelaod()

end

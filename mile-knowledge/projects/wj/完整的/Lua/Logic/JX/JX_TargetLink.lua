-- 目标连线

JX_TargetLink = JX_TargetLink or {
    className = "JX_TargetLink",
    bConnect = false, -- 我与目标连线
    bTTConnect = false, -- 目标与目标连线
    nPellucidity = 30, -- 透明度百分比（0-100）
    nIndensity = 60, -- 亮度百分比（0-100）
    nLinePos = 5, -- 位置
}

--local _L = JX.LoadLangPack

local CONFIG_INDENSITY = 4 -- 最大亮度
--local kOffsetPos = {
--    [1] = {0, 0,   _L['LinkFoot']   }, -- 脚
--    [2] = {2, 20,  _L['LinkWaist']  }, -- 腰
--    [3] = {1, -23, _L['LinkBosom']  }, -- 胸
--    [4] = {1, 10,  _L['LinkHead']   }, -- 头
--    [5] = {3, 0,   _L['LinkTopName']}, -- 血条
--}

local kOffsetPos = {
    [1] = { 0, 0, 9 }, -- 脚
    [2] = { 2, 20, 9 }, -- 腰
    [3] = { 1, -23, 9 }, -- 胸
    [4] = { 1, 10, 9 }, -- 头
    [5] = { 3, 0, 9 }, -- 血条
}

-- 连线的特效ID（represent\player\other\target_lightning_connection.txt）
local kNormalSfxID = 3     -- 普通目标连线
local kEnemySfxID = 17    -- 地方目标连线
local kAllyPlayerSfxID = 18    -- 友方玩家连线
local kTargetTargetSfxID = 10    -- 目标的目标连线

-- 部分观战情况下隐藏我与目标的连线，保留目标与目标的目标连线
local fnLegal = function(player)
    ---- 吃鸡或者MOBA死亡观战队友
    if UIMgr.IsViewOpened(VIEW_ID.PanelRevive) then
        if BattleFieldData.IsInTreasureBattleFieldMap() or ArenaData.IsInArena() or BattleFieldData.IsInMobaBattleFieldMap() then
            return false
        end
    end
    --if Station.Lookup("Topmost/RevivePanel") then
    --    if JX.IsTreasureBFMap(player.GetMapID()) or JX.IsMobaBFMap(player.GetMapID()) then
    --        return false
    --    end
    --end
    --if Station.Lookup("Normal/CMDOB") then
    --    return false
    --end
    --if Station.Lookup("Normal/PVPShowPanel") then
    --    return false
    --end
    ---- MOBA观战
    --if Station.Lookup("Normal/MobaShowPanel") then
    --    return false
    --end

    --策划要求对话时隐藏两种连线
    if PlotMgr.IsInDialogue() then
        return false
    end

    -- 副本观战 OB 模式下隐藏连线
    if OBDungeonData.IsPlayerInOBDungeon() then
        return false
    end

    return true
end

function JX_TargetLink.OnRelaod()
    JX_TargetLink.RefreshLine()
end

-- 目标连线&目标的目标连线
function JX_TargetLink.ConnectLine()
    local player = g_pClientPlayer
    if not player then
        return
    end

    -- rlcmd("set target sfx connection 23508 27749 1 起始位置 起始偏移 目标位置 目标偏移 特效位置 透明度")
    local nSelfID = player.dwID
    local nTarType, nTarID = player.GetTarget()

    local bIsFocus = JX_TargetList.dwCurSelectID == nTarID -- 焦点强行连线

    -- 目标连线, 5是Doodad类型，竟然能选中doodad，神奇
    local nSfxID
    local nParam
    if (bIsFocus or JX_TargetLink.bConnect) and nTarID ~= 0 and nTarType ~= TARGET.DOODAD and fnLegal(player) then
        local nRelation = GetRelation(nSelfID, nTarID)
        nParam = nTarID
        if kmath.bit_and(nRelation, RELATION_TYPE.ENEMY) ~= 0 then
            nSfxID = kEnemySfxID
        elseif kmath.bit_and(nRelation, RELATION_TYPE.ALLY) ~= 0 and IsPlayer(nTarID) then
            nSfxID = kAllyPlayerSfxID
        elseif (bIsFocus or JX_TargetLink.bShowAll) then
            nSfxID = kNormalSfxID
        end
    end

    if nSfxID and nParam then
        rlcmd(string.format("set target sfx connection 1 %s %s %s %s %d %s %d %s %s %s",
                nSelfID, nParam, nSfxID,
                kOffsetPos[JX_TargetLink.nLinePos][1], kOffsetPos[JX_TargetLink.nLinePos][2],
                kOffsetPos[JX_TargetLink.nLinePos][1], kOffsetPos[JX_TargetLink.nLinePos][2],
                1,
                (1 - JX_TargetLink.nPellucidity / 100), (JX_TargetLink.nIndensity / 100) * CONFIG_INDENSITY
        ))
    else
        rlcmd("set target sfx connection 1 0 0 0")
    end

    -- 目标的目标连线
    local nParam2
    if JX_TargetLink.bTTConnect and nTarID ~= 0 and nTarType ~= 5 and not PlotMgr.IsInDialogue() then
        local tar = GetTargetHandle(nTarType, nTarID)
        if tar then
            local nTarTarType, nTarTarID = tar.GetTarget()
            if nTarTarID ~= 0 and nTarTarID ~= nSelfID and nTarTarID ~= tar.dwID then
                nParam2 = nTarTarID
            end
        end
    end

    if nParam2 then
        rlcmd(string.format("set target sfx connection 2 %s %s %s %s %d %s %d %s %s %s",
                nTarID, nParam2, kTargetTargetSfxID,
                kOffsetPos[JX_TargetLink.nLinePos][1], kOffsetPos[JX_TargetLink.nLinePos][2],
                kOffsetPos[JX_TargetLink.nLinePos][1], kOffsetPos[JX_TargetLink.nLinePos][2],
                1,
                (1 - JX_TargetLink.nPellucidity / 100), (JX_TargetLink.nIndensity / 100) * CONFIG_INDENSITY
        ))
    else
        rlcmd("set target sfx connection 2 0 0 0")
    end
end

-- 刷新连线，部分情况需要关掉原先连线强制重刷新
function JX_TargetLink.RefreshLine()
    if not g_pClientPlayer then
        return
    end

    JX_TargetLink.UpdateData()
    Timer.DelAllTimer(JX_TargetLink)

    JX_TargetLink.ConnectLine()
    --if JX_TargetLink.bConnect or JX_TargetLink.bTTConnect then
    Timer.AddFrameCycle(JX_TargetLink, 8, JX_TargetLink.ConnectLine) -- 焦点列表需要常驻目标连线
    --end
end

function JX_TargetLink.OnFirstLoadingEnd()
    JX_TargetLink.UpdateData()
    --if JX_TargetLink.bConnect or JX_TargetLink.bTTConnect then
    Timer.AddFrameCycle(JX_TargetLink, 8, JX_TargetLink.ConnectLine) -- 焦点列表需要常驻目标连线
    --end
end

function JX_TargetLink.UpdateData()
    local szVal = GameSettingData.GetNewValue(UISettingKey.TargetSelectionLine).szDec
    JX_TargetLink.bConnect = szVal ~= GameSettingType.TargetLink.None.szDec
    JX_TargetLink.bShowAll = szVal == GameSettingType.TargetLink.All.szDec
    JX_TargetLink.bTTConnect = GameSettingData.GetNewValue(UISettingKey.TargetOfTargetLine)
end

function JX_TargetLink.OnLoadingEnd()
end

Event.Reg(JX_TargetLink, "FIRST_LOADING_END", JX_TargetLink.OnFirstLoadingEnd)
Event.Reg(JX_TargetLink, "LOADING_END", JX_TargetLink.OnLoadingEnd)
Event.Reg(JX_TargetLink, "UPDATE_SELECT_TARGET", JX_TargetLink.ConnectLine)

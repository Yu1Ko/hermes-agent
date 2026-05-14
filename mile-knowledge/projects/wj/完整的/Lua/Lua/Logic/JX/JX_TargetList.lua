-- ---------------------------------------------------------------------------------
-- Author: luwenhao
-- Name: JX_TargetList
-- Date: 2023-12-11 17:51:58
-- Desc: 插件部分功能搬运 JX\JX_TargetList\JX_TargetList.lua
-- ---------------------------------------------------------------------------------

JX_TargetList = { className = "JX_TargetList" }
_JX_TargetList = {}

local _JX_TargetList = _JX_TargetList

JX_TargetList.bEnemyWarning = true  -- 红名报警
JX_TargetList.bSetFirstRed = false -- 设置第一个出现的红名为目标
JX_TargetList.nListClassify = 1     -- 列表显示类型，1:NPC,2:玩家,3:自定义,4:阵营活动, 5:物品
JX_TargetList.nListClassifyForce = 1     -- 列表显示类型的势力关系，1:全部,2:友好,3:敌对
JX_TargetList.bShowList = 1     -- 列表显示类型的势力关系，1:全部,2:友好,3:敌对
JX_TargetList.bDebugMode = false
JX_TargetList.bShowTopFocus = true  -- 是否显示置顶焦点
JX_TargetList.bIgnoreNpc = true -- 屏蔽指定NPC列表显示的开关
JX_TargetList.bIgnorePet = true -- 屏蔽玩家宠物的开关
JX_TargetList.bFilterFocus = false  -- 目标列表显示不包含焦点
JX_TargetList.nScaleValue = 1     -- 主界面缩放值，默认1
JX_TargetList.nSortType = 2     -- 列表排序类型，0:距离(显示血量),1:血量(显示血量),2:距离(显示距离),3:血量(显示距离)
JX_TargetList.bFootDis = true  -- 20尺以外的玩家后置
JX_TargetList.bFootDie = true  -- 20尺以外的玩家后置
JX_TargetList.nFootDis = 22    -- 后置的距离设置
JX_TargetList.bFarFocusDark = true  -- 焦点距离过远变暗
JX_TargetList.nFarFocusDis = 27    -- 焦点距离过远变暗的距离设置
JX_TargetList.bJJCHideList = true  -- JJC自动隐藏底部人数统计/附近列表
JX_TargetList.dwCurSelectID = nil -- 当前已选中的对象ID
JX_TargetList.bdoSelect = false  -- 当前是否发起选择
JX_TargetList.tCampActModList = {}    -- 阵营活动列表内需要显示的分类
JX_TargetList.bSyncTeamFocus = true   -- 同步团队焦点
JX_TargetList.bPerImg = true  -- 背景显示血量百分比
JX_TargetList.bSetLastTar = false -- 目标重新进入视野时自动选择
JX_TargetList.bMapRedDot = true  -- 小地图红点标记
JX_TargetList.bDouClickKill = true  -- 双击发布集火

JX_TargetList.bJJCFocus = true  -- JJC自动焦点敌对目标
JX_TargetList.bFocusGFBoss = true  -- 自动焦点GFBOSS及阵营任务NPC
JX_TargetList.bFocusFBBoss = true  -- 自动焦点副本BOSS
JX_TargetList.bFocusCampNpc = true  -- 自动焦点牛车/关隘/世界首领
JX_TargetList.bFocusCaption = true  -- 焦点目标的头顶名字特殊显示

_JX_TargetList._tItemListFocus = {}    -- 普通焦点控件对象
_JX_TargetList._tItemTopFocus = {}    -- 顶部焦点控件对象
_JX_TargetList.tTopFocusID = {}    -- 顶部焦点dwID表
_JX_TargetList.tTempFocusID = {}    -- 玩家临时加的焦点dwID表
_JX_TargetList.bGFObserver = false -- 大攻防观赛者模式，只显示顶部焦点及人数统计
_JX_TargetList.tTempFocusName = {} -- 活动通用临时名字缓存(神农洇大旗手等战场、铁血宝箱主人)

_JX_TargetList.IsBanMap = false
_JX_TargetList.IsInMobaMap = false
_JX_TargetList.IsBattlefieldSideMap = false -- 这里是指底部阵营人数统计需要修改为显示战场边的地图

_JX_TargetList.tPartyMark = {}    -- 标记缓存

local _L = JX.LoadLangPack

local dwLastTarID = 0     -- 上次选择的目标ID
local tCacheAll = {}    -- 所有玩家列表
local tCacheFriend = {}    -- 所有友好列表
local tCacheEnemy = {}    -- 所有敌对列表
local bEnemyWarned = false -- 是否已警告红名出现
local tTempFocusName = {}    -- 活动通用临时名字缓存(神农洇大旗手等战场、铁血宝箱主人)
local tTempCastleFlagName = {}    -- 小攻防大旗手专属临时名字缓存 存GBK

local tIgnoreNpcList = {}   -- 列表内排除的NPC

local tGFBossTemplateID = JX_CampData.GetGFBossTemplateID()
local tCastleBossTemplateID = JX_CampData.GetCastleBossTemplateID()
local tShapeShiftID = JX_CampData.GetShapeShiftID()
local IsCastleBarnNpc = JX_CampData.IsCastleBarnNpc
local IsCastleWorkshopNpc = JX_CampData.IsCastleWorkshopNpc
local IsCastleTowerNpc = JX_CampData.IsCastleTowerNpc
local IsTongLeagueNpc = JX_CampData.IsTongLeagueNpc
local tCampQuestTemplateID = JX_CampData.GetCampQuestTemplateID()

local tCampActModList = {
    [1] = { name = 'player-smallcar', default = true },
    [2] = { name = 'player-tower', default = true },
    [3] = { name = 'player-bigcar', default = true },
    [4] = { name = 'npc-bossguardian', default = false },
    [5] = { name = 'npc-castleboss', default = true },
    [6] = { name = 'npc-castlebarn', default = true },
    [7] = { name = 'npc-castleworkshop', default = true },
    [8] = { name = 'npc-castletower', default = true },
    [9] = { name = 'npc-tongleague', default = true },
}

local nGoodNum, nEvilNum, nNeturalNum, nLiveGoodNum, nLiveEvilNum, nLiveNeturalNum = 0, 0, 0, 0, 0, 0
local nSide0Num, nSide1Num, nLiveSide0Num, nLiveSide1Num = 0, 0, 0, 0

local mfloor, mceil, mmin, mmax, mpi, matan2, msqrt = math.floor, math.ceil, math.min, math.max, math.pi, math.atan2, math.sqrt
local tinsert, tconcat, tsort = table.insert, table.concat, table.sort
local sgsub, sformat, sfind = string.gsub, string.format, string.find
local pairs, ipairs = pairs, ipairs
local unpack = unpack
local MOVE_STATE_ON_DEATH = MOVE_STATE.ON_DEATH
local JX_GetDistancePoint = JX.GetDistancePoint
local JX_GetDistanceTwice = JX.GetDistanceTwice

local tMarkName = {
    _L["mk_yun"], _L["mk_jian"], _L["mk_futou"], _L["mk_gouzi"], _L["mk_honggu"],
    _L["mk_jiandao"], _L["mk_bangchui"], _L["mk_yuruyi"], _L["mk_feibiao"], _L["mk_shanzi"],
}

local function IsShieldedNpc(dwTemplateID)
    if Table_IsShieldedNpc and Table_IsShieldedNpc(dwTemplateID) then
        return true
    end
    return false
end

function JX_TargetList.Init()
    JX.FirstInit()
    JX_TargetList.RegEvent()

    for k, v in ipairs(tCampActModList) do
        if JX_TargetList.tCampActModList[k] == nil then
            JX_TargetList.tCampActModList[k] = v.default
        end
    end
    JX_TargetList.UpdateSetting()
    Timer.AddCycle(JX_TargetList, 3, JX_TargetList.OnFrameBreathe)
end

function JX_TargetList.UnInit()
    Event.UnRegAll(JX_TargetList)
    Timer.DelAllTimer(JX_TargetList)
end

function JX_TargetList.RegEvent()
    Event.Reg(JX_TargetList, EventType.OnClientPlayerLeave, function()
        tIgnoreNpcList = {} -- 小退时清空屏蔽列表
        tTempCastleFlagName = {}    -- 小攻防大旗手专属临时名字缓存
    end)

    Event.Reg(JX_TargetList, "LOADING_END", _JX_TargetList.LoadingEnd)
    Event.Reg(JX_TargetList, "UPDATE_SELECT_TARGET", function()
        if g_pClientPlayer then
            local _, dwID = g_pClientPlayer.GetTarget()
            if JX_TargetList.bdoSelect then
                JX_TargetList.dwCurSelectID = dwID
            elseif dwID ~= JX_TargetList.dwCurSelectID then
                JX_TargetList.dwCurSelectID = nil
            end

            local _, dwID = g_pClientPlayer.GetTarget()
            if JX_TargetList.bSetLastTar and dwID ~= 0 then
                dwLastTarID = dwID
            elseif JX_TargetList.bSetLastTar and dwLastTarID ~= 0 then
                -- 自己主动取消选中
                Timer.AddFrame(1, function()
                    if IsPlayerExist(dwLastTarID) then
                        dwLastTarID = 0
                    end
                end)
            end
        end
        JX_TargetList.bdoSelect = false
    end)

    Event.Reg(JX_TargetList, "PLAYER_ENTER_SCENE", function(arg0)
        _JX_TargetList.OnObjectEnter(1, arg0)
    end)
    Event.Reg(JX_TargetList, "NPC_ENTER_SCENE", function(arg0)
        _JX_TargetList.OnObjectEnter(2, arg0)
    end)

    Event.Reg(JX_TargetList, "PLAYER_LEAVE_SCENE", function(arg0)
        _JX_TargetList.OnObjectLeave(1, arg0)
    end)
    Event.Reg(JX_TargetList, "NPC_LEAVE_SCENE", function(arg0)
        _JX_TargetList.OnObjectLeave(2, arg0)
    end)

    Event.Reg(JX_TargetList, "ON_CASTLE_ACTIVITY_TIP_UPDATE", function(arg0)
        _JX_TargetList.OnCastleActivityTip(arg0)
    end)

    Event.Reg(JX_TargetList, "ON_CASTLE_END_ACTIVITY", function(arg0)
        _JX_TargetList.OnCastleActivityTip(nil, nil)
    end)

    Event.Reg(JX_TargetList, "ON_WORLD_BOX_ACTIVITY_TIP_UPDATE", function(arg0)
        _JX_TargetList.WorldBoxFocusUpdate(arg0)
        RegisterMsgMonitor(_JX_TargetList.NormalSysMsgMonitor, { "MSG_SYS" })
    end)

    Event.Reg(JX_TargetList, "ON_ACTIVITY_TIPS_CLOSE", function(arg0)
        if arg0 == 22 then
            _JX_TargetList.WorldBoxFocusUpdate(nil)
            UnRegisterMsgMonitor(_JX_TargetList.NormalSysMsgMonitor, { "MSG_SYS" })
        end
    end)
end

function JX_TargetList.OnFrameBreathe()
    local player = g_pClientPlayer
    if not player then
        return
    end
    if _JX_TargetList.IsBanMap and not _JX_TargetList.IsInMobaMap then
        return
    end

    -- 缓存&统计数据&附近目标列表刷新&统计刷新
    local meID, num, firstenemy = UI_GetClientPlayerID(), 0, nil
    nGoodNum, nEvilNum, nNeturalNum, nLiveGoodNum, nLiveEvilNum, nLiveNeturalNum = 0, 0, 0, 0, 0, 0
    nSide0Num, nSide1Num, nLiveSide0Num, nLiveSide1Num = 0, 0, 0, 0
    local tAllPlayer = PlayerData.GetAllPlayer()
    tCacheAll, tCacheFriend, tCacheEnemy = {}, {}, {}
    tCacheAll = tAllPlayer
    for k, v in pairs(tAllPlayer) do
        -- 友好目标缓存
        if IsParty(meID, k) or IsAlly(meID, k) or meID == k then
            tCacheFriend[k] = v
        end
        -- 敌对目标缓存
        if IsEnemy(meID, k) then
            tCacheEnemy[k] = v
            if v.nMoveState ~= MOVE_STATE_ON_DEATH then
                num = num + 1
                if not firstenemy and JX.GetObjectName(v) ~= "" then
                    firstenemy = v
                end
                -- 小地图红点标记
                if JX_TargetList.bMapRedDot and not _JX_TargetList.IsInMobaMap then
                    JX.UpdateMiniMapMark(101, k, v.nX, v.nY)
                end
            end
        end
        -- 阵营人数统计
        if v.nCamp == 0 then
            nNeturalNum = nNeturalNum + 1
            if v.nMoveState ~= MOVE_STATE_ON_DEATH then
                nLiveNeturalNum = nLiveNeturalNum + 1
            end
        elseif v.nCamp == 1 then
            nGoodNum = nGoodNum + 1
            if v.nMoveState ~= MOVE_STATE_ON_DEATH then
                nLiveGoodNum = nLiveGoodNum + 1
            end
        elseif v.nCamp == 2 then
            nEvilNum = nEvilNum + 1
            if v.nMoveState ~= MOVE_STATE_ON_DEATH then
                nLiveEvilNum = nLiveEvilNum + 1
            end
        end
        -- 战场边人数统计
        if v.nBattleFieldSide == 0 then
            nSide0Num = nSide0Num + 1
            if v.nMoveState ~= MOVE_STATE_ON_DEATH then
                nLiveSide0Num = nLiveSide0Num + 1
            end
        elseif v.nBattleFieldSide == 1 then
            nSide1Num = nSide1Num + 1
            if v.nMoveState ~= MOVE_STATE_ON_DEATH then
                nLiveSide1Num = nLiveSide1Num + 1
            end
        end
    end
    Event.Dispatch(EventType.OnFocusCampCountUpdate)
    -- 红名报警
    if not _JX_TargetList.IsInMobaMap then
        if num >= 1 and JX_TargetList.bEnemyWarning and not bEnemyWarned and not SceneMgr.IsLoading() then
            bEnemyWarned = true
            _JX_TargetList.EnemyWarning(firstenemy)
        elseif num == 0 and bEnemyWarned then
            bEnemyWarned = false
        end
    end
    -- -- 下面要放在缓存刷新内
    -- if not JX_TargetList.bShowMain or JX_TargetList.bMiniCheck then
    --     return
    -- end
    -- -- 列表刷新
    -- _JX_TargetList.RefreshList()
    -- -- 下方人数刷新
    -- _JX_TargetList.RefreshBootNum()

end

function JX_TargetList.IsShow()
    return GameSettingData.GetNewValue(UISettingKey.ShowFocusList)
end

function JX_TargetList.SetVisible(bVal)
    return GameSettingData.StoreNewValue(UISettingKey.ShowFocusList, bVal)
end

function JX_TargetList.GetCampNumberCount()
    return nGoodNum, nEvilNum, nNeturalNum, nLiveGoodNum, nLiveEvilNum, nLiveNeturalNum
end

function JX_TargetList.Save()
    Storage.FocusList.Flush()
end

function JX_TargetList.UpdateSetting()
    JX_TargetList.bFilterFocus = GameSettingData.GetNewValue(UISettingKey.HideAlreadyFocusedTargets)  -- 目标列表显示不包含焦点
    JX_TargetList.bFootDis = GameSettingData.GetNewValue(UISettingKey.PrioritizeNearbyTargets) -- 20尺以外的玩家后置
    JX_TargetList.nFootDis = GameSettingData.GetNewValue(UISettingKey.NearbyTargetDistance)    -- 后置的距离设置
    JX_TargetList.bFootDie = GameSettingData.GetNewValue(UISettingKey.DeprioritizeInjuredPlayers) -- 重伤后置
    JX_TargetList.bPerImg = GameSettingData.GetNewValue(UISettingKey.ShowHealthProgressBar)    -- 背景显示血量百分比

    JX_TargetList.bJJCFocus = GameSettingData.GetNewValue(UISettingKey.AutoFocusArenaOpponents)   -- JJC自动焦点敌对目标
    JX_TargetList.bFocusGFBoss = GameSettingData.GetNewValue(UISettingKey.AutoFocusFactionBoss)  -- 自动焦点GFBOSS及阵营任务NPC
    JX_TargetList.bFocusFBBoss = GameSettingData.GetNewValue(UISettingKey.AutoFocusDungeonBoss)  -- 自动焦点副本BOSS
    JX_TargetList.bFocusCampNpc = GameSettingData.GetNewValue(UISettingKey.AutoFocusWorldBoss)  -- 自动焦点牛车/关隘/世界首领
  
    JX_TargetList.bShowTopFocus = GameSettingData.GetNewValue(UISettingKey.ShowTopLockedFocus)  -- 焦点距离过远变暗
    JX_TargetList.bFarFocusDark = GameSettingData.GetNewValue(UISettingKey.DimDistantFocus)  -- 焦点距离过远变暗
    JX_TargetList.nFarFocusDis = GameSettingData.GetNewValue(UISettingKey.DimDistantFocusDistance)  -- 焦点距离过远变暗的距离设置
    JX_TargetList.bSyncTeamFocus = GameSettingData.GetNewValue(UISettingKey.ReceiveTeammateFocus)
    JX_TargetList.bDouClickKill = GameSettingData.GetNewValue(UISettingKey.QuickFocusFireAnnouncement)

    JX_TargetList.bEnemyWarning = GameSettingData.GetNewValue(UISettingKey.HostilePlayerWarning)
    JX_TargetList.bMapRedDot = GameSettingData.GetNewValue(UISettingKey.ShowHostilePlayerOnMinimap)
    JX_TargetList.bSetFirstRed = GameSettingData.GetNewValue(UISettingKey.SetHostilePlayerAsTarget)
    JX_TargetList.bSetLastTar = GameSettingData.GetNewValue(UISettingKey.AutoSelectTargetReentered)
end

function JX_TargetList.GenerateMenuConfig(dwID, szName, bIsDoodad, bOtherPlayer)
    if OBDungeonData.IsPlayerInOBDungeon() then
        return
    end

    local me = GetClientPlayer()
    local tbExtraMenuConfig = {}
    local tar = GetPlayer(dwID) or GetNpc(dwID)
    local szOriginalName = szName
    if not IsPlayer(dwID) then
        szName = "NPC_" .. szName
    end

    local bIsTop = _JX_TargetList._tItemTopFocus[dwID] ~= nil
    local bIsPermanent = Storage.FocusList._tFocusTargetData[szName] ~= nil
    local bIsFocus = (_JX_TargetList.tTempFocusID[dwID] or _JX_TargetList._tItemListFocus[dwID] ~= nil
            or bIsPermanent or bIsTop)

    if TeamData.IsInParty() and IsPlayer(dwID) then
        local szTogName = IsEnemy(me.dwID, dwID) and "集火喊话" or "救急喊话"
        table.insert(tbExtraMenuConfig, { szName = szTogName, bCloseOnClick = true, OnClick = function()
            _JX_TargetList.SetJihuoTar(dwID)
            TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipMoreOper)
        end })
    end
    
    if bIsFocus then
        table.insert(tbExtraMenuConfig, { szName = bIsPermanent and "取消永久焦点" or "取消临时焦点", bCloseOnClick = true, OnClick = function()
            if bIsPermanent then
                _JX_TargetList.ChangeFocusTable(false, 1, dwID)
            else
                _JX_TargetList.ChangeFocusTable(false, 2, dwID)
            end
            TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipMoreOper)
        end })

        if me.IsInParty() and not bIsDoodad then
            table.insert(tbExtraMenuConfig, { szName = "同步团队焦点", bCloseOnClick = true, OnClick = function()
                UIHelper.ShowConfirm("确定同步当前焦点给团队所有成员？", function()
                    if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TALK, "player talk") then
                        return
                    end
                    local sTalk = string.format("%s将焦点【%s】同步给了团队所有成员。", UIHelper.GBKToUTF8(me.szName), szOriginalName)
                    JX.Talk(PLAYER_TALK_CHANNEL.RAID, UIHelper.UTF8ToGBK(sTalk))
                    JX.BgTalk(PLAYER_TALK_CHANNEL.RAID, "JX_TEAM_SYNCFOCUS", dwID, UIHelper.UTF8ToGBK(szOriginalName))
                end)
                TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipMoreOper)
            end })
        end
    end
    if not bIsPermanent and not bIsDoodad then
        table.insert(tbExtraMenuConfig, { szName = "设为永久焦点", bCloseOnClick = true, OnClick = function()
            _JX_TargetList.ChangeFocusTable(true, 1, dwID)
            TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipMoreOper)
        end })
    end

    if not bIsFocus then
        table.insert(tbExtraMenuConfig, { szName = "设为临时焦点", bCloseOnClick = true, OnClick = function()
            _JX_TargetList.ChangeFocusTable(true, 2, dwID)
            TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipMoreOper)
        end })
    end

    if not IsPlayer(dwID) and not bIsDoodad then
        table.insert(tbExtraMenuConfig, {
            szName = "临时屏蔽NPC",
            OnClick = function()
                _JX_TargetList.AddIgnoreNpc(szOriginalName)
                TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipMoreOper)
            end,
        })

        local dropTar = GetPlayer(tar.dwDropTargetPlayerID)
        if dropTar and JX.GetObjectName(dropTar) ~= "" then
            local _tarName = JX.GetObjectName(dropTar)
            table.insert(tbExtraMenuConfig, {
                szName = "选中目标归属",
                OnClick = function()
                    JX_TargetList.bdoSelect = true -- 发起选择
                    TargetMgr.doSelectTarget(tar.dwDropTargetPlayerID, TARGET.PLAYER)
                    TipsHelper.ShowNormalTip(string.format("尝试选中当前目标归属的玩家【%s】", _tarName))
                    TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipMoreOper)
                end,
            })
        end
    end

    if bIsFocus then
        if _JX_TargetList.tTopFocusID[dwID] then
            table.insert(tbExtraMenuConfig, {
                szName = UIHelper.GBKToUTF8(_L["cancel lock focus"]),
                bCloseOnClick = true,
                OnClick = function()
                    _JX_TargetList.tTopFocusID[dwID] = nil
                    _JX_TargetList.TryDelFocus(dwID)
                    _JX_TargetList.TryAddFocus(2, tar)
                    TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipMoreOper)
                end
            })
        else
            table.insert(tbExtraMenuConfig, {
                szName = UIHelper.GBKToUTF8(_L["top lock focus"]),
                bCloseOnClick = true,
                OnClick = function()
                    if JX.GetTableCount(_JX_TargetList._tItemTopFocus) < 3 then
                        _JX_TargetList.tTopFocusID[dwID] = true
                        _JX_TargetList.TryDelFocus(dwID)
                        _JX_TargetList.TryAddFocus(1, tar)
                    else
                        TipsHelper.ShowNormalTip(UIHelper.GBKToUTF8(_L['top focus limit']))
                    end
                    TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipMoreOper)
                end
            })
        end
    end

    if bOtherPlayer then
        local tRes = {}
        for _, tBtnInfo in ipairs(tbExtraMenuConfig) do
            tBtnInfo.callback = tBtnInfo.OnClick -- 名称转换
            table.insert(tRes, 1, tBtnInfo) --由于两个面板的按钮展示顺序相反 因此需要做一个倒序列表
        end
        tbExtraMenuConfig = tRes
    end

    return tbExtraMenuConfig
end

function _JX_TargetList.LoadingEnd()
    -- nLastFocusFrame = 0
    tTempFocusName = {}
    tTempCastleFlagName = {}
    tCacheAll, tCacheFriend, tCacheEnemy = {}, {}, {} --清空缓存对象防止过图完获取到旧对象报错

    local me = GetClientPlayer()
    if not me then
        return
    end
    _JX_TargetList.IsBanMap = JX.IsBanMap()
    _JX_TargetList.IsInMobaMap = JX.IsMobaBFMap(me.GetMapID())
    _JX_TargetList.IsBattlefieldSideMap = JX.IsBattleFieldMap(me.GetMapID()) or JX.IsTongLeagueMap(me.GetMapID())

    JX_TargetList.bEnemyWarning = GameSettingData.GetNewValue(UISettingKey.NearbyHostilePlayerAlert)

    if JX.IsBattleFieldMap() then
        Event.Reg(_JX_TargetList, "PLAYER_TALK", function(...)
            local tbOneData = { ... }
            --local dwTalkerID, nChannel, bEcho, szName = tbOneData[1], tbOneData[2], tbOneData[3], tbOneData[4]
            --local bOnlyShowBallon, bSecurity, bGMAccount, bCheater = tbOneData[5], tbOneData[6], tbOneData[7], tbOneData[8]
            --local dwTitleID, byVIPType, nVIPLevel, dwIdePetTemplateID = tbOneData[9], tbOneData[10], tbOneData[11], tbOneData[12]
            local szData, bFilter = tbOneData[13], tbOneData[14]
            _JX_TargetList.BFSysMsgMonitor(szData)
        end)
    else
        Event.UnReg(_JX_TargetList, "PLAYER_TALK")
    end
end

local function GetPartyMemberFontColor()
    return 126, 126, 255
end

local function GetForceFontColor(dwPeerID, dwSelfID)
    local bInParty = false
    local player = GetClientPlayer()
    if player then
        if player.dwID == dwPeerID then
            bInParty = player.IsPlayerInMyParty(dwSelfID)
        elseif player.dwID == dwSelfID then
            bInParty = player.IsPlayerInMyParty(dwPeerID)
        end
    end

    local src = dwPeerID
    local dest = dwSelfID

    if IsPlayer(dwPeerID) and IsPlayer(dwSelfID) then
        src = dwSelfID
        dest = dwPeerID
    end

    local r, g, b
    if IsSelf(dwSelfID, dwPeerID) then
        r, g, b = 255, 255, 0
    elseif bInParty or IsParty(src, dest) then
        r, g, b = GetPartyMemberFontColor()
    elseif IsFakeAlly(dwPeerID) then
        r, g, b = 0, 200, 72
    elseif IsEnemy(src, dest) then
        if SM_IsEnable() then
            r, g, b = 255, 86, 86
        else
            r, g, b = 255, 0, 0
        end
    elseif IsNeutrality(src, dest) then
        r, g, b = 255, 255, 0
    elseif IsAlly(src, dest) then
        r, g, b = 0, 200, 72
    else
        if SM_IsEnable() then
            r, g, b = 255, 86, 86
        else
            r, g, b = 255, 0, 0
        end
    end
    return r, g, b
end

-- 红名首次出现报警&自动选定目标
function _JX_TargetList.EnemyWarning(penemy)
    local me = GetClientPlayer()
    if not me or not penemy then
        return
    end
    local dis = JX_GetDistanceTwice(me, penemy)
    if dis >= 100 then
        dis = sformat('%d', dis)
    else
        dis = sformat('%.1f', dis)
    end

    local szWarning = sformat("发现敌对侠士【%s】，距离%s尺。", JX.GetObjectName(penemy), dis)
    --OutputWarningMessage("MSG_WARNING_RED", szWarning)
    OutputMessage("MSG_ANNOUNCE_RED", szWarning)

    SoundMgr.PlaySound(SOUND.UI_SOUND, g_sound.CloseAuction)
    if JX_TargetList.bSetFirstRed then
        local _, dwTarID = me.GetTarget()
        if not me.bFightState and dwTarID == 0 then
            SetTarget(TARGET.PLAYER, penemy.dwID)
        end
    end
end

-- 根据类型，返回需求的列表显示对象
function _JX_TargetList.GetObjectByType(nListClassify)
    local tObjectList = {}
    -- 玩家
    if nListClassify == 2 then
        if JX_TargetList.nListClassifyForce == 1 then
            tObjectList = tCacheAll
        elseif JX_TargetList.nListClassifyForce == 2 then
            tObjectList = tCacheFriend
        elseif JX_TargetList.nListClassifyForce == 3 then
            tObjectList = tCacheEnemy
        end
        -- NPC
    elseif nListClassify == 1 then
        local meID = UI_GetClientPlayerID()
        local tAllNpc = JX.GetAllNpc()
        if JX_TargetList.nListClassifyForce == 1 then
            tObjectList = tAllNpc
        elseif JX_TargetList.nListClassifyForce == 2 then
            local nR, nG, nB = 0, 0, 0
            for k, v in pairs(tAllNpc) do
                nR, nG, nB = GetForceFontColor(meID, k)
                if nR == 126 and nG == 126 and nB == 255 or nR == 0 and nG == 200 and nB == 72 then
                    tObjectList[k] = v
                end
            end
        elseif JX_TargetList.nListClassifyForce == 3 then
            for k, v in pairs(tAllNpc) do
                if IsEnemy(meID, k) then
                    tObjectList[k] = v
                end
            end
        end
        --自定义
    elseif nListClassify == 3 then
        local _t
        if JX_TargetList.nListClassifyForce == 1 then
            _t = tCacheAll
        elseif JX_TargetList.nListClassifyForce == 2 then
            _t = tCacheFriend
        elseif JX_TargetList.nListClassifyForce == 3 then
            _t = tCacheEnemy
        end
        for k, v in pairs(_t) do
            if _JX_TargetList.CheckCustomMode(v) then
                tObjectList[k] = v
            end
        end
        --阵营活动
    elseif nListClassify == 4 then
        local meID = UI_GetClientPlayerID()
        local tAllNpc = JX.GetAllNpc()
        local _tP, _tN = {}, {}
        if JX_TargetList.nListClassifyForce == 1 then
            _tP = tCacheAll
            _tN = tAllNpc
        elseif JX_TargetList.nListClassifyForce == 2 then
            _tP = tCacheFriend
            local nR, nG, nB = 0, 0, 0
            for k, v in pairs(tAllNpc) do
                nR, nG, nB = GetForceFontColor(meID, k)
                if nR == 126 and nG == 126 and nB == 255 or nR == 0 and nG == 200 and nB == 72 then
                    _tN[k] = v
                end
            end
        elseif JX_TargetList.nListClassifyForce == 3 then
            _tP = tCacheEnemy
            for k, v in pairs(tAllNpc) do
                if IsEnemy(meID, k) then
                    _tN[k] = v
                end
            end
        end
        for k, v in pairs(_tP) do
            if tShapeShiftID[v.dwShapeShiftID] and JX_TargetList.tCampActModList[tShapeShiftID[v.dwShapeShiftID].class] then
                tObjectList[k] = v
            end
        end
        for k, v in pairs(_tN) do
            if tGFBossTemplateID[v.GetMapID()] and tGFBossTemplateID[v.GetMapID()][v.dwTemplateID] and JX_TargetList.tCampActModList[4] or
                    tCastleBossTemplateID[v.dwTemplateID] and JX_TargetList.tCampActModList[5] or
                    IsCastleBarnNpc(v.dwTemplateID) and JX_TargetList.tCampActModList[6] or
                    IsCastleWorkshopNpc(v.dwTemplateID) and JX_TargetList.tCampActModList[7] or
                    IsCastleTowerNpc(v.dwTemplateID) and JX_TargetList.tCampActModList[8] or
                    IsTongLeagueNpc(v.dwTemplateID) and JX_TargetList.tCampActModList[9]
            then
                tObjectList[k] = v
            end
        end
    elseif nListClassify == 5 then
        local function _CheckDoodad(doodad, player)
            if not doodad or not doodad.IsSelectable() then
                return
            end

            local func = _tDoodadCfg[doodad.nKind]
            if not func then
                return
            end
            return func(doodad, player);
        end
        local tDoodads = JX.GetAllDoodad()
        for dwID, doodad in pairs(tDoodads) do
            if doodad then
                local szType, szTitle, nFrame = _CheckDoodad(doodad, g_pClientPlayer)
                if szType and doodad.szName ~= "" then
                    tObjectList[dwID] = doodad
                end
            end
        end

        --local tDoodads = g_pClientPlayer.SearchForDoodad(6 * 64)
        if tDoodads then
            --
            --    local INTERACTIVE_TYPE = {
            --        NPC = "npc",
            --        ITEM = "item",
            --        FURNITURE = "furniture",
            --        COMPASS = "Compass",
            --        PETACTION = "PetAction",
            --        ONCE = "once", --Doodad 拾取后就消失 不需要读条的
            --        ONCE_TIME = "once_time", --Doodad 拾取后就消失 需要读条的
            --        DIALOG = "dialog", --Doodad 一直存在的
            --        WORKBENCH = "workbench", -- 工作台Doodad，点击跳转到技艺界面对应分类
            --    }
            --
            --    local doodad
            --    local szType, szTitle, nFrame
            --
            --    for k, dwID in pairs(tDoodads) do
            --        doodad = GetDoodad(dwID)
            --        if doodad then
            --            szType, szTitle, nFrame = _CheckDoodad(doodad, g_pClientPlayer)
            --            if szType and doodad.szName ~= "" then
            --                tObjectList[dwID] = doodad
            --            end
            --        end
            --    end
        end
    end
    return tObjectList
end

-- 判断自定义模式是否应该显示
function _JX_TargetList.CheckCustomMode(target)
    local _tCustomModData = Storage.FocusList._tCustomModData or {}
    local tCustom = _tCustomModData.default -- 1.名字，2.帮会，3.门派
    -- 下面三个条件是可以满足任意一个即可的，所以中间代码块不要return_false
    if tCustom[1].enable and tCustom[1].data[JX.GetObjectName(target)] == 1 then
        return true
    end

    if tCustom[2].enable and tCustom[2].data[UIHelper.GBKToUTF8(JX.GetTongName(target.dwTongID))] == 1 then
        if tCustom[2].forceFilter then
            -- 启用了过滤帮会指定门派功能
            if tCustom[2].forceData[target.dwForceID] then
                return true
            end
        else
            return true
        end
    end
    if tCustom[3].enable and tCustom[3].data[target.dwForceID] then
        return true
    end
    return false
end


-- 判断对象是否应该显示
function _JX_TargetList.ShouldShowObject(dwObID, hObject)
    if JX_TargetList.bDebugMode then
        return true
    end
    if (
            IsPlayerExist(dwObID) or
                    IsNpcExist(dwObID) and hObject.IsSelectable() and
                            (hObject.CanSeeName() or hObject.CanSeeLifeBar()) and
                            not (JX_TargetList.bIgnoreNpc and tIgnoreNpcList[JX.GetObjectName(hObject)]) and
                            not IsShieldedNpc(hObject.dwTemplateID) and
                            not (_JX_TargetList.IsInMobaMap and hObject.dwEmployer ~= 0) and -- MOBA玩家宠物&影子不显示
                            not (JX_TargetList.bIgnorePet and hObject.dwEmployer ~= 0 and not _JX_TargetList.IsBattlefieldSideMap) --非战场竞技场默认屏蔽玩家宠物
    ) and
            JX.GetObjectName(hObject) ~= ""
    then
        return true
    end
    return false
end

-- 增加&删除记录的焦点表 -- bAdd:增加/删除,(1：永久，2：临时),dwID
function _JX_TargetList.ChangeFocusTable(bAdd, nType, dwID)
    if _JX_TargetList.IsBanMap then
        return
    end
    if not nType or not dwID then
        return
    end
    local tar = JX.GetObject(dwID)
    if not tar then
        return
    end
    local szName = JX.GetObjectName(tar)
    if szName == "" then
        return
    end
    if not IsPlayer(dwID) then
        szName = "NPC_" .. szName
    end
    if nType == 1 then
        if bAdd then
            Storage.FocusList._tFocusTargetData[szName] = true
            JX_TargetList.Save()
            local nTop = 2
            if _JX_TargetList.tTopFocusID[dwID] or JX_TargetList.bJJCHideList and JX.IsArenaMap() or _JX_TargetList.bGFObserver then
                nTop = 1
            end
            _JX_TargetList.TryAddFocus(nTop, tar)
            _JX_TargetList.tTempFocusID[dwID] = nil
        else
            Storage.FocusList._tFocusTargetData[szName] = nil
            JX_TargetList.Save()
            _JX_TargetList.TryDelFocus(dwID)
            _JX_TargetList.tTopFocusID[dwID] = nil

            ---- 已在焦点列表内的同名NPC且非置顶焦点也同时移除处理
            if not IsPlayer(dwID) then
                for k in pairs(_JX_TargetList._tItemListFocus) do
                    local tar1 = GetNpc(k)
                    if tar1 and ("NPC_" .. JX.GetObjectName(tar1)) == szName then
                        _JX_TargetList.TryDelFocus(k)
                    end
                end
            end
        end
    end

    if nType == 2 then
        if bAdd then
            if not Storage.FocusList._tFocusTargetData[szName] then
                _JX_TargetList.tTempFocusID[dwID] = true
            end
            local nTop = 2
            if _JX_TargetList.tTopFocusID[dwID] or JX_TargetList.bJJCHideList and JX.IsArenaMap() or _JX_TargetList.bGFObserver then
                nTop = 1
            end
            _JX_TargetList.TryAddFocus(nTop, tar)
        else
            _JX_TargetList.tTempFocusID[dwID] = nil
            _JX_TargetList.TryDelFocus(dwID)
            _JX_TargetList.tTopFocusID[dwID] = nil
        end
    end
end

-- 尝试添加焦点对象(1：固定，2：列表), object
function _JX_TargetList.TryAddFocus(nType, object)
    if _JX_TargetList.IsBanMap then
        return
    end
    if not nType or not object then
        return
    end
    local me = GetClientPlayer()
    local dwID = object.dwID
    local nItemTopCount = JX.GetTableCount(_JX_TargetList._tItemTopFocus)

    if nType == 1 then
        --if _JX_TargetList._tItemTopFocus[dwID] then
        --    return
        --end
        --if nItemTopCount < 3 or ((JX_TargetList.bJJCHideList and JX.IsArenaMap() or _JX_TargetList.bGFObserver) and nItemTopCount < 6) then
        --    _JX_TargetList._tItemTopFocus[dwID] = 1
        --    return
        --end
    end

    if _JX_TargetList._tItemListFocus[dwID] or _JX_TargetList._tItemTopFocus[dwID] then
        return -- 列表焦点和超过上限的固定焦点
    end
    if nItemTopCount + JX.GetTableCount(_JX_TargetList._tItemListFocus) >= 6 then
        return
    end
    _JX_TargetList._tItemListFocus[dwID] = 1
end

-- 尝试删除焦点对象(1：顶部，2：普通)
function _JX_TargetList.TryDelFocus(dwID)
    if not dwID then
        return
    end
    local me = GetClientPlayer()

    if _JX_TargetList._tItemTopFocus[dwID] then
        _JX_TargetList._tItemTopFocus[dwID] = nil  -- 顶部焦点

        -- 顶部有位置了，则尝试把之前没地放的焦点置顶
        for k in pairs(_JX_TargetList._tItemListFocus) do
            if _JX_TargetList.tTopFocusID[k] then
                _JX_TargetList.TryDelFocus(k)
                _JX_TargetList.TryAddFocus(1, GetPlayer(k) or GetNpc(k))
                break
            end
        end
    end

    if _JX_TargetList._tItemListFocus[dwID] then
        _JX_TargetList._tItemListFocus[dwID] = nil  -- 普通焦点
    end
end

-- 发布附近人数统计 -- 1：阵营，2：门派，3：帮会，4：服务器
function _JX_TargetList.NoticeNearbyCount(ntype)
    if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TALK, "player talk") then
        return
    end

    local me = GetClientPlayer()
    if not me then
        return
    end
    if _JX_TargetList.IsBanMap then
        TipsHelper.ShowImportantRedTip("此场景不可用")
        return
    end
    --local text = HtmlEscapeConfig["<"]
    local text = "<"
    text = text .. UIHelper.GBKToUTF8(Table_GetMapName(me.GetMapID()))
    --local hMapName = Station.Lookup("Normal/Minimap/Wnd_Minimap/Wnd_Over", "Text_Name")
    --if hMapName then
    --    local arenaName = hMapName:GetText()
    --    if arenaName ~= Table_GetMapName(me.GetMapID()) then
    --        text = text .. "*" .. arenaName
    --    end
    --end
    --text = text .. HtmlEscapeConfig[">"] .. ":"
    text = text .. ">" .. ":"

    if ntype == 1 then
        local _tTemp = {
            "浩气:" .. nGoodNum,
            "存活:" .. nLiveGoodNum,
            "恶人:" .. nEvilNum,
            "存活:" .. nLiveEvilNum,
            "中立:" .. nNeturalNum,
            "存活:" .. nLiveNeturalNum
        }
        text = text .. tconcat(_tTemp, ",")
    elseif ntype == 2 then
        local tForcePlayer = JX.GetForcePlayer()
        local _tTemp = {}
        local tList = Table_GetAllForceUI()
        for forceid, v in pairs(tList) do
            local forcename = v.szName
            _tTemp[#_tTemp + 1] = {}
            _tTemp[#_tTemp].name = forcename
            _tTemp[#_tTemp].num = tForcePlayer[forceid] and #tForcePlayer[forceid] or 0
        end
        tsort(_tTemp, function(a, b)
            return a.num > b.num
        end)
        for i = 1, #_tTemp do
            text = text .. _tTemp[i].name .. ":" .. _tTemp[i].num
            if i ~= #_tTemp then
                text = text .. ","
            end
        end
    elseif ntype == 3 then
        local tTongPlayer = JX.GetTongPlayer()
        local _tTemp = {}
        for tongid, tplayer in pairs(tTongPlayer) do
            _tTemp[#_tTemp + 1] = {}
            _tTemp[#_tTemp].name = UIHelper.GBKToUTF8(JX.GetTongName(tongid)) or "无帮会"
            _tTemp[#_tTemp].num = #tplayer
        end
        tsort(_tTemp, function(a, b)
            return a.num > b.num
        end)
        for i = 1, #_tTemp do
            text = text .. _tTemp[i].name .. ":" .. _tTemp[i].num
            if i > 9 then
                break
            end
            if i ~= #_tTemp then
                text = text .. ","
            end
        end
    elseif ntype == 4 then
        if not JX.IsRemotePvpMap() then
            TipsHelper.ShowImportantRedTip(string.format("只能在“千里伐逐”跨服场景内使用"))
            return
        end
        text = "" --不需要所在位置，因为跨服烂柯山也没有这个功能
        local tServerPlayer = JX.GetServerPlayer()
        local _tTemp = {}
        for serverName, tplayer in pairs(tServerPlayer) do
            _tTemp[#_tTemp + 1] = {}
            _tTemp[#_tTemp].name = serverName
            _tTemp[#_tTemp].num = #tplayer
        end
        tsort(_tTemp, function(a, b)
            return a.num > b.num
        end)
        for i = 1, #_tTemp do
            text = text .. _tTemp[i].name .. ":" .. _tTemp[i].num
            if i ~= #_tTemp then
                text = text .. ","
            end
        end
    end
    local tbMsg = { { type = "text", text = UIHelper.UTF8ToGBK(text) } }
    Player_Talk(me, PLAYER_TALK_CHANNEL.NEARBY, "", tbMsg)
end

-- 焦点用EnterScene (1:player,2:npc),dwID
function _JX_TargetList.OnObjectEnter(nType, dwID, nNum)
    if not g_pClientPlayer then
        return
    end
    if nType == 1 then
        local object = GetPlayer(dwID)
        if object then
            -- 玩家时，永久焦点判断名字，临时焦点判断dwID
            local szObjectName = JX.GetObjectName(object)
            if szObjectName == "" then
                nNum = nNum or 0
                if nNum < 3 then
                    -- 只尝试取3次
                    Timer.Add(_JX_TargetList, 0.3, function()
                        _JX_TargetList.OnObjectEnter(nType, dwID, nNum)
                    end)
                end
                return
            end
            if _JX_TargetList.IsInMobaMap then
                -- MOBA不允许加焦点
            elseif JX_TargetList.bJJCFocus and JX.IsArenaMap() and IsEnemy(UI_GetClientPlayerID(), dwID) then
                -- JJC内的敌对目标自动焦点
                if JX_TargetList.bJJCHideList then
                    _JX_TargetList.TryAddFocus(1, object) -- JJC自动加到固定
                else
                    _JX_TargetList.TryAddFocus(_JX_TargetList.tTopFocusID[dwID] and 1 or 2, object) -- JJC自动加到列表
                end
            elseif _JX_TargetList.tTempFocusID[dwID] or
                    Storage.FocusList._tFocusTargetData[szObjectName] or
                    Storage.FocusList._tFocusTargetData[tostring(dwID)] or
                    _JX_TargetList.tTempFocusName[szObjectName] or
                    tTempCastleFlagName[UIHelper.UTF8ToGBK(szObjectName)]
            then
                -- 永久焦点、临时焦点、神农洇大旗、小攻防大旗
                _JX_TargetList.TryAddFocus(_JX_TargetList.tTopFocusID[dwID] and 1 or 2, object)
            end
            -- 目标再次进入视野时自动选中
            if JX_TargetList.bSetLastTar and dwLastTarID == dwID then
                local _, dwTarID = GetClientPlayer().GetTarget()
                if dwTarID == 0 then
                    SetTarget(TARGET.PLAYER, dwID)
                end
            end
        end
    elseif nType == 2 then
        local object = GetNpc(dwID)
        if object then
            -- NPC时，永久焦点判断dwTemplateID，临时焦点判断dwID
            if JX.GetObjectName(object) == "" then
                nNum = nNum or 0
                if nNum < 3 then
                    Timer.Add(_JX_TargetList, 0.3, function()
                        _JX_TargetList.OnObjectEnter(nType, dwID, nNum) -- 只尝试取3次
                    end)
                end
                return
            end
            if IsShieldedNpc(object.dwTemplateID) then
                return  -- 焦点及列表黑名单
            end
            if _JX_TargetList.IsInMobaMap then
                -- MOBA不允许加焦点
            elseif _JX_TargetList.tTempFocusID[dwID] or Storage.FocusList._tFocusTargetData["NPC_" .. JX.GetObjectName(object)] then
                -- 永久焦点或临时焦点
                _JX_TargetList.TryAddFocus(_JX_TargetList.tTopFocusID[dwID] and 1 or 2, object)
            elseif JX_TargetList.bFocusGFBoss and _JX_TargetList.IsShowGFBossID(object) then
                if _JX_TargetList.bGFObserver then
                    _JX_TargetList.TryAddFocus(1, object) -- GF观战直接加到固定
                else
                    _JX_TargetList.TryAddFocus(_JX_TargetList.tTopFocusID[dwID] and 1 or 2, object)
                end
            elseif JX_TargetList.bFocusFBBoss and JX.IsFBBoss(object.dwTemplateID) then
                _JX_TargetList.TryAddFocus(_JX_TargetList.tTopFocusID[dwID] and 1 or 2, object)
            elseif JX_TargetList.bFocusCampNpc and tCampQuestTemplateID[object.dwTemplateID] then
                _JX_TargetList.TryAddFocus(_JX_TargetList.tTopFocusID[dwID] and 1 or 2, object)
            end
        end
    end
end

-- 焦点用LeaveScene (1:player,2:npc),dwID
function _JX_TargetList.OnObjectLeave(nType, dwID)
    if _JX_TargetList._tItemTopFocus[dwID] or _JX_TargetList._tItemListFocus[dwID] then
        _JX_TargetList.TryDelFocus(dwID)
    end
end

-- 判断是否是需要显示的阵营BOSS。2021.10.28所有首领都显示，因为召唤首领返回出生点时不满血，需要玩家奶满
function _JX_TargetList.IsShowGFBossID(object)
    -- 浩气盟：初始点{9801, 84539, 1060928},撤退点{44487, 40121, 1125568},
    -- 恶人谷：初始点{32849, 8074, 1065664},撤退点{51487, 67772, 1114112},
    local dwMapID = object.GetMapID()
    if tGFBossTemplateID and tGFBossTemplateID[dwMapID] and tGFBossTemplateID[dwMapID][object.dwTemplateID] then
        if dwMapID == 25 then
            if JX_GetDistancePoint(object.nX, object.nY, object.nZ, 44487, 40121, 1125568) <= 20
                    or JX_GetDistancePoint(object.nX, object.nY, object.nZ, 9801, 84539, 1060928) <= 20
            then
                return false
            end
        elseif dwMapID == 27 then
            if JX_GetDistancePoint(object.nX, object.nY, object.nZ, 51487, 67772, 1114112) <= 20
                    or JX_GetDistancePoint(object.nX, object.nY, object.nZ, 32849, 8074, 1065664) <= 20
            then
                return false
            end
        end
        return true
    end
    return false
end

-- 根据世界公告自动焦点&标记（战场专用）
function _JX_TargetList.BFSysMsgMonitor(szMsg, nFont, bRich, r, g, b, szType)
    if bRich then
        szMsg = string.pure_text(szMsg)
    end
    if not szMsg or szMsg == "" then
        return
    end
    --神农洇
    local _, _, _, szName = sfind(szMsg, _L['(.-)s(.-)ShenNong transport success'])
    if szName then
        if tTempFocusName[szName] then
            tTempFocusName[szName] = nil
        end
        local tar = JX.GetPlayerByName(szName)
        if tar then
            if not _JX_TargetList.tTempFocusID[tar.dwID] and not Storage.FocusList._tFocusTargetData[szName] then
                _JX_TargetList.TryDelFocus(tar.dwID)
            end
        end
        return
    end
    local _, _, _, szName = sfind(szMsg, _L['(.-)s(.-)ShenNong transport lost'])
    if szName then
        if tTempFocusName[szName] then
            tTempFocusName[szName] = nil
        end
        local tar = JX.GetPlayerByName(szName)
        if tar then
            if not _JX_TargetList.tTempFocusID[tar.dwID] and not Storage.FocusList._tFocusTargetData[szName] then
                _JX_TargetList.TryDelFocus(tar.dwID)
            end
        end
        return
    end
    local _, _, _, szName = sfind(szMsg, _L['(.-)s(.-)ShenNong rob box success'])
    if szName then
        tTempFocusName[szName] = true
        local tar = JX.GetPlayerByName(szName)
        if tar then
            _JX_TargetList.TryAddFocus(2, tar)
            if JX_FastMarker then
                JX_FastMarker.SetTargetMark(tar.dwID, 1)
            end
        end
        return
    end
    --云湖天池
    local _, _, szCamp, szName = sfind(szMsg, _L['(.-)s(.-)YunHu get buff'])
    if szName then
        tTempFocusName[szName] = true
        local tar = JX.GetPlayerByName(szName)
        if tar then
            _JX_TargetList.TryAddFocus(2, tar)
        end
        return
    end
    local _, _, szCamp, szName = sfind(szMsg, _L['(.-)s(.-)YunHu remove buff'])
    if szName then
        if tTempFocusName[szName] then
            tTempFocusName[szName] = nil
        end
        local tar = JX.GetPlayerByName(szName)
        if tar then
            if not _JX_TargetList.tTempFocusID[tar.dwID] and not Storage.FocusList._tFocusTargetData[szName] then
                _JX_TargetList.TryDelFocus(tar.dwID)
            end
        end
        return
    end
    --浮香丘
    local _, _, _, szName = sfind(szMsg, _L['(.-)s(.-)FuXiangQiu transport(.-) success'])
    if szName then
        if tTempFocusName[szName] then
            tTempFocusName[szName] = nil
        end
        local tar = JX.GetPlayerByName(szName)
        if tar then
            if not _JX_TargetList.tTempFocusID[tar.dwID] and not Storage.FocusList._tFocusTargetData[szName] then
                _JX_TargetList.TryDelFocus(tar.dwID)
            end
        end
        return
    end
    local _, _, _, szName = sfind(szMsg, _L['(.-)s(.-)FuXiangQiu transport(.-) lost'])
    if szName then
        if tTempFocusName[szName] then
            tTempFocusName[szName] = nil
        end
        local tar = JX.GetPlayerByName(szName)
        if tar then
            if not _JX_TargetList.tTempFocusID[tar.dwID] and not Storage.FocusList._tFocusTargetData[szName] then
                _JX_TargetList.TryDelFocus(tar.dwID)
            end
        end
        return
    end
    local _, _, _, szName = sfind(szMsg, _L['(.-)s(.-)FuXiangQiu transport(.-) get'])
    if szName then
        tTempFocusName[szName] = true
        local tar = JX.GetPlayerByName(szName)
        if tar then
            _JX_TargetList.TryAddFocus(2, tar)
        end
        return
    end
end

-- 根据世界公告自动焦点&标记（其他地图）
function _JX_TargetList.NormalSysMsgMonitor(szMsg, nFont, bRich, r, g, b, szType)
    if bRich then
        szMsg = string.pure_text(szMsg)
    end
    if not szMsg or szMsg == "" then
        return
    end
    local _, _, _, szName, szMapName = sfind(szMsg, _L['(.-)s(.-)s(.-)TieXueBaoXiang Get'])
    if szName and szMapName then
        local dwCurMapID = UI_GetCurrentMapID()
        local szCurMapName = Table_GetMapName(dwCurMapID)
        if szCurMapName ~= szMapName then
            return
        end
        _JX_TargetList.WorldBoxFocusUpdate(szName)
        return
    end
    local _, _, szMapName = sfind(szMsg, _L['(.-)TieXueBaoXiang Lost'])
    if szMapName then
        local dwCurMapID = UI_GetCurrentMapID()
        local szCurMapName = Table_GetMapName(dwCurMapID)
        if szCurMapName ~= szMapName then
            return
        end
        _JX_TargetList.WorldBoxFocusUpdate(nil)
        return
    end
end

-- 小攻防大旗手自动焦点，通过活动小界面的事件刷新内容
function _JX_TargetList.OnCastleActivityTip(tTips)
    if not tTips then
        return
    end
    local szGBKNull = _L['null']
    local szName1, szName2 = tTips[5], tTips[11]

    -- 整个活动结束了
    if not szName1 and not szName2 then
        for k, v in pairs(tTempCastleFlagName) do
            local tar = JX.GetPlayerByName(k)
            if tar then
                if not _JX_TargetList.tTempFocusID[tar.dwID] and not Storage.FocusList._tFocusTargetData[UIHelper.GBKToUTF8(k)] then
                    _JX_TargetList.TryDelFocus(tar.dwID)
                end
            end
        end
        tTempCastleFlagName = {}
        return
    end
    if szName1 and not tTempCastleFlagName[szName1] then
        for k, v in pairs(tTempCastleFlagName) do
            if v == 1 then
                -- 把原先的1号清掉
                local tar = JX.GetPlayerByName(k)
                if tar then
                    if not _JX_TargetList.tTempFocusID[tar.dwID] and not Storage.FocusList._tFocusTargetData[UIHelper.GBKToUTF8(k)] then
                        _JX_TargetList.TryDelFocus(tar.dwID)
                    end
                end
                tTempCastleFlagName[k] = nil
                break
            end
        end
        if szName1 and szName1 ~= szGBKNull then
            tTempCastleFlagName[szName1] = 1
            local tar = JX.GetPlayerByName(szName1)
            if tar then
                _JX_TargetList.TryAddFocus(2, tar)
            end
        end
    end
    -- 可能没有2
    if szName2 and not tTempCastleFlagName[szName2] or not szName2 then
        for k, v in pairs(tTempCastleFlagName) do
            if v == 2 then
                -- 把原先的2号清掉
                local tar = JX.GetPlayerByName(k)
                if tar then
                    if not _JX_TargetList.tTempFocusID[tar.dwID] and not Storage.FocusList._tFocusTargetData[UIHelper.GBKToUTF8(k)] then
                        _JX_TargetList.TryDelFocus(tar.dwID)
                    end
                end
                tTempCastleFlagName[k] = nil
                break
            end
        end
        if szName2 and szName2 ~= szGBKNull then
            tTempCastleFlagName[szName2] = 2
            local tar = JX.GetPlayerByName(szName2)
            if tar then
                _JX_TargetList.TryAddFocus(2, tar)
            end
        end
    end
end

-- 奇宝之争自动焦点，通过活动小界面的事件或者世界公告事件
function _JX_TargetList.WorldBoxFocusUpdate(szName)
    if not szName then
        for k, v in pairs(tTempFocusName) do
            local tar = JX.GetPlayerByName(k)
            if tar then
                if not _JX_TargetList.tTempFocusID[tar.dwID] and not Storage.FocusList._tFocusTargetData[k] then
                    _JX_TargetList.TryDelFocus(tar.dwID)
                end
            end
        end
        tTempFocusName = {}
        return
    end
    if szName and not tTempFocusName[szName] then
        for k, v in pairs(tTempFocusName) do
            -- 先清一下之前的
            local tar = JX.GetPlayerByName(k)
            if tar then
                if not _JX_TargetList.tTempFocusID[tar.dwID] and not Storage.FocusList._tFocusTargetData[k] then
                    _JX_TargetList.TryDelFocus(tar.dwID)
                end
            end
            tTempFocusName[k] = nil
            break
        end
        if szName ~= _L['null'] then
            tTempFocusName[szName] = 1
            local tar = JX.GetPlayerByName(szName)
            if tar then
                _JX_TargetList.TryAddFocus(2, tar)
            end
        end
    end
end

-- 集火目标
function _JX_TargetList.SetJihuoTar(dwID)
    if not JX_TargetList.bDouClickKill then
        return
    end
    local tar = GetPlayer(dwID) or GetNpc(dwID)
    if not tar then
        return
    end
    local sTalk
    local szGBKName = UIHelper.UTF8ToGBK(JX.GetObjectName(tar))
    if not _JX_TargetList.tPartyMark[dwID] then
        sTalk = _L('PartyAction: attack target:%s', szGBKName)
        if not IsEnemy(UI_GetClientPlayerID(), dwID) then
            sTalk = _L('PartyAction: rescue target:%s', szGBKName)
        end
    else
        sTalk = _L('PartyAction: attack target:%s, marker:%s', szGBKName, tMarkName[_JX_TargetList.tPartyMark[dwID]])
        if not IsEnemy(UI_GetClientPlayerID(), dwID) then
            sTalk = _L('PartyAction: rescue target:%s, marker:%s', szGBKName, tMarkName[_JX_TargetList.tPartyMark[dwID]])
        end
    end
    local test = UIHelper.GBKToUTF8(sTalk)
    JX.Talk(PLAYER_TALK_CHANNEL.RAID, sTalk)
    JX.BgTalk(PLAYER_TALK_CHANNEL.RAID, "JX_JIHUO", dwID)
end

-- 临时屏蔽NPC
function _JX_TargetList.AddIgnoreNpc(szName)
    tIgnoreNpcList[szName] = true
end

function JX_TargetList.OnReload()
    Timer.DelAllTimer(JX_TargetList)
    Event.UnRegAll(JX_TargetList)
    JX_TargetList.Init()
end

function _JX_TargetList.OnReload()

end

JX.RegisterBgEvent("JX_TEAM_SYNCFOCUS", function(szEvent, dwTalkerID, szTalkerName, nChannel, dwID, szName)
    if JX_TargetList.bSyncTeamFocus then
        _JX_TargetList.tTempFocusID[dwID] = true -- 强行加一次，这里有可能还取不到焦点对象
        _JX_TargetList.ChangeFocusTable(true, 2, dwID)
        local szMsg = string.format(UIHelper.UTF8ToGBK("添加焦点:%s 到焦点列表成功"), szName)
        JX.Talk(PLAYER_TALK_CHANNEL.RAID, szMsg)
    end
end)
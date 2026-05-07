PartnerData         = PartnerData or { className = "PartnerData" }

---@class PartnerViewOpenType
PartnerViewOpenType = {
    Default = 0, --- 不做特殊处理，按照实际点击的tab来正常选中

    Morph = 1, --- 选中共鸣tab
    Assist = 2, --- 选中助战tab

    MorphQuickTeam = 3, --- 选中共鸣tab，然后打开快速编队界面
    AssistQuickTeam = 4, --- 选中助战tab，然后打开快速编队界面

    Travel = 5, --- 选中出行tab
}

---@class PartnerDrawState
PartnerDrawState    = {
    NotMeet = 0, --- 未结识
    InTask = 1, --- 侠缘任务中
    Meet = 2, --- 已结识
}

local self          = PartnerData

function PartnerData.Init()
    self.InitData()
    self.RegEvent()

    Timer.AddCycle(self, 0.1, function()
        if not g_pClientPlayer then
            return
        end

        if PartnerData.PartnerTravel_IsAnySlotInState(PartnerTravelState.Finished) then
            Event.Dispatch("PartnerTravelHasFinishedSlot")
        end
    end)
end

function PartnerData.UnInit()
    Event.UnRegAll(self)
    Timer.DelAllTimer(self)
end

function PartnerData.InitData()
    self.bShowMorphInMainCity = false
    self.tTravelClassToLastChooseQuestId = {}
end

function PartnerData.RegEvent()
    Event.Reg(self, EventType.OnRoleLogin, function()
        self.InitData()
    end)

    Event.Reg(self, "ON_NPC_ASSISTED_RESULT_CODE", function(nRetCode, dwAssistedID)
        if nRetCode == NPC_ASSISTED_RESULT_CODE.SUMMON_SUCCESS or nRetCode == NPC_ASSISTED_RESULT_CODE.RECALL_SUCCESS then
            Event.Dispatch("OnPartnerSummonChanged")
        end
    end)
end

PartnerData.tTipsType                = {}
PartnerData.tTipsType.nDrawFailed    = 1
PartnerData.tTipsType.nStartTask     = 2
PartnerData.tTipsType.nGetNewPartner = 3

PartnerData.tAttributeIndex          = {
    [1] = ATTRIBUTE_TYPE.MAX_LIFE_BASE, --血量
    [2] = ATTRIBUTE_TYPE.ALL_TYPE_ATTACK_POWER_BASE, --攻击
    [3] = ATTRIBUTE_TYPE.THERAPY_POWER_BASE, --治疗
    [4] = ATTRIBUTE_TYPE.ALL_TYPE_CRITICAL_STRIKE, --会心
    [5] = ATTRIBUTE_TYPE.ALL_TYPE_CRITICAL_DAMAGE_POWER_BASE, --会效等级
    [6] = ATTRIBUTE_TYPE.ALL_TYPE_OVERCOME_BASE, --破防
    [7] = ATTRIBUTE_TYPE.PHYSICS_SHIELD_BASE, --外防
    [8] = ATTRIBUTE_TYPE.MAGIC_SHIELD, --内防
    [9] = ATTRIBUTE_TYPE.TOUGHNESS_BASE, --御劲
    [10] = ATTRIBUTE_TYPE.GLOBAL_DAMAGE_FIXED_ADD, --技能伤害提高
    [11] = ATTRIBUTE_TYPE.ASSISTED_POWER_EXT_ADD, --凝神等级（百分比）
    [12] = ATTRIBUTE_TYPE.ALL_SHIELD_IGNORE_ADD, --无视防御点数
    [13] = ATTRIBUTE_TYPE.STRAIN_RATE, --无双
}

-- 主界面是否显示共鸣
PartnerData.bShowMorphInMainCity     = false
PartnerData.bEnterHero               = false

--- 共鸣能量条最大值
PartnerData.nMaxPowerNum             = 360

-- 当前玩家可见范围内的侠客NPC列表
PartnerData.tNpcList                 = {}

PartnerData.VOICE_TYPE               = {
    --- 言谈语音
    CHAT = 1,
    --- 系统语音
    FIGHT = 2,
}

--- 本次角色登录期间，某个侠客出行类别上次选择的事件ID
---@type table<number, number>
PartnerData.tTravelClassToLastChooseQuestId = {}

function PartnerData.UpdateNpcList(dwNpcID, bEnter)
    if not bEnter then
        for k, v in ipairs(PartnerData.tNpcList) do
            if v.dwNpcID == dwNpcID then
                table.remove(PartnerData.tNpcList, k)
                break
            end
        end
    else
        local tKNpc = GetNpc(dwNpcID)
        if not tKNpc or tKNpc.dwEmployer == 0 then
            return
        end

        if tKNpc.nSpecies ~= NPC_SPECIES_TYPE.NPC_ASSISTED then
            return
        end

        local bMatch = false
        for k, v in ipairs(PartnerData.tNpcList) do
            if v.dwNpcID == dwNpcID then
                bMatch = true
            end
        end
        if not bMatch then
            local tNpc    = { dwNpcID = dwNpcID, dwTemplateID = tKNpc.dwTemplateID, szName = tKNpc.szName }
            local tUIInfo = Table_GetPartnerByTemplateID(tKNpc.dwTemplateID)
            if tUIInfo then
                tNpc.dwAssistedID = tUIInfo.dwNpcID
                tNpc.szAvatarPath = tUIInfo.szAvatarPath
                tNpc.nAvatarFrame = tUIInfo.nAvatarFrame
            end
            table.insert(PartnerData.tNpcList, tNpc)
        end
    end
    PartnerData.UpdateNpcInfo(dwNpcID)

    Event.Dispatch(EventType.OnPartnerNpcListChanged)
end

function PartnerData.UpdateNpcInfo(dwNpcID)
    for _, tNpcInfo in ipairs(PartnerData.tNpcList) do
        if tNpcInfo.dwNpcID == dwNpcID then
            local tKNpc = GetNpc(tNpcInfo.dwNpcID)
            if tKNpc then
                tNpcInfo.nCurrentLife = tKNpc.nCurrentLife
                tNpcInfo.nMaxLife     = tKNpc.nMaxLife
            end
        end
    end
end

--- 当前玩家可见范围内自己队伍（或自己）的侠客NPC列表
function PartnerData.GetCurrentTeamPartnerNpcList()
    local tNpcList = {}

    for _, tNpcInfo in ipairs(PartnerData.tNpcList) do
        if PartnerData.IsPartnerNpcInMyTeam(tNpcInfo.dwNpcID) then
            table.insert(tNpcList, tNpcInfo)
        end
    end

    return tNpcList
end

--- 某个NPC是否是侠客自己或自己队伍中的
function PartnerData.IsPartnerNpcInMyTeam(dwNpcID)
    local bInMyTeam = false

    local tKNpc = GetNpc(dwNpcID)
    if tKNpc then
        if TeamData.IsInParty() then
            -- 组队情况下，判断是否是队伍中某个成员召唤的
            TeamData.Generator(function(dwID, tMemberInfo)
                if tKNpc.dwEmployer == dwID then
                    bInMyTeam = true
                end
            end)
        else
            -- 单人模式下，判断是否是当前玩家召唤的
            bInMyTeam = tKNpc.dwEmployer == UI_GetClientPlayerID()
        end
    end

    return bInMyTeam
end

--- 当前玩家可见范围内自己队友的侠客NPC列表
function PartnerData.GetMyTeammatePartnerNpcList()
    local tNpcList = {}

    if TeamData.IsInParty() then
        for _, tNpcInfo in ipairs(PartnerData.tNpcList) do
            if PartnerData.IsPartnerNpcInMyTeam(tNpcInfo.dwNpcID) then
                local tKNpc = GetNpc(tNpcInfo.dwNpcID)

                if tKNpc and tKNpc.dwEmployer ~= UI_GetClientPlayerID() then
                    table.insert(tNpcList, tNpcInfo)
                end
            end
        end
    end

    return tNpcList
end

--- 目前是否有助战侠客技能能量满了，需要按规则进行自动释放
PartnerData.bNeedAutoReleasePartnerSkill         = false
--- 当前的检查自动释放的定时器ID
PartnerData.nCheckAutoReleasePartnerSkillTimerID = nil

--- 形如 {1: {dwNpcID: 123, dwAssistedID: 9}, 2: {dwNpcID: 456, dwAssistedID: 12}
--- @return table<number, table>
function PartnerData.GetSummonedList()
    return g_pClientPlayer and g_pClientPlayer.GetSummonedList() or {}
end

--- 形如 {9, 12}
--- @return number[]
function PartnerData.GetAssistedList()
    return g_pClientPlayer and g_pClientPlayer.GetAssistedList() or {}
end

--- 形如 {9, 12}
--- @return number[]
function PartnerData.GetMorphList()
    return g_pClientPlayer and g_pClientPlayer.GetMorphList() or {}
end

--- 形如 {9, 12}
--- @return number[]
function PartnerData.GetSummonedPartnerIDList()
    local tSummonedList = PartnerData.GetSummonedList()

    local tPartnerIDList = {}
    for _, tInfo in ipairs(tSummonedList) do
        table.insert(tPartnerIDList, tInfo.dwAssistedID)
    end
    return tPartnerIDList
end

function PartnerData.UpdateData(dwAssistedID, tInfo)
    if tInfo then
        PartnerData.dwAssistedID = dwAssistedID
        PartnerData.tUIInfo      = tInfo
    end
end

function PartnerData.GetBuffCount()
    if PartnerData.tUIInfo then
        local dwBuffID = PartnerData.tUIInfo.dwBuffID
        local nBuff    = Buffer_GetStackNum(dwBuffID) or 0
        local nMaxBuff = PartnerData.tUIInfo.dwMaxPower
        return nBuff, nMaxBuff
    end
end

--- 筛选项 - 获取途径
--- nID => PartnerNpcInfo.txt nFilterWay
local tFilterWay         = {
    { nID = 1, szName = "家园", },
    { nID = 2, szName = "喝茶结交", },
    { nID = 3, szName = "活动", },
    { nID = 4, szName = "名望", },
    { nID = 5, szName = "单人", },
}

--- 筛选项 - 心法类型
--- nID => PartnerNpcInfo.txt nKungfuIndex
local tFilterKungfuIndex = {
    { nID = 1, szName = "攻击" },
    { nID = 2, szName = "防御" },
    { nID = 3, szName = "治疗" },
}

local function _ResetFilter(tFilter, nFilterIndex)
    tFilter[nFilterIndex].tbList = {}
end

local function _AppendFilter(tFilter, nFilterIndex, szName)
    table.insert(tFilter[nFilterIndex].tbList, szName)
end

function PartnerData.InitFilterDef()
    PartnerData.InitFilterDefWay()
    PartnerData.InitFilterDefKungfuIndex()
end

function PartnerData.InitFilterDefWay()
    _ResetFilter(FilterDef.Partner, FilterDef.Partner.IndexDef.Way)

    -- 获得情况
    for _, tInfo in ipairs(tFilterWay) do
        _AppendFilter(FilterDef.Partner, FilterDef.Partner.IndexDef.Way, tInfo.szName)
    end
end

function PartnerData.InitFilterDefKungfuIndex()
    _ResetFilter(FilterDef.Partner, FilterDef.Partner.IndexDef.KungfuIndex)

    -- 获得情况
    for _, tInfo in ipairs(tFilterKungfuIndex) do
        _AppendFilter(FilterDef.Partner, FilterDef.Partner.IndexDef.KungfuIndex, tInfo.szName)
    end
end

--- 侠客出行槽位筛选
function PartnerData.InitFilterDef_TravelSlot()
    FilterDef.PartnerTravelSlot.Reset()

    PartnerData.InitFilterDef_TravelSlot_QuestType()
end

--- 筛选项 - 事件类型
local tTravelSlot_Filter_DataIndex = {
    --{ nID = 1, szName = "宠物奇缘" },
}

function PartnerData.InitFilterDef_TravelSlot_QuestType()
    _ResetFilter(FilterDef.PartnerTravelSlot, FilterDef.PartnerTravelSlot.IndexDef.QuestType)

    -- 事件类型
    if table.get_len(tTravelSlot_Filter_DataIndex) == 0 then
        local tDataIndexToInfo = Table_GetPartnerTravelDataIndexToInfo()
        for nDataIndex, tInfo in pairs(tDataIndexToInfo) do
            table.insert(tTravelSlot_Filter_DataIndex, {
                nID = nDataIndex,
                szName = UIHelper.GBKToUTF8(tInfo.szClassName),
            })
        end
    end
    for _, tFilter in pairs(tTravelSlot_Filter_DataIndex) do
        _AppendFilter(FilterDef.PartnerTravelSlot, FilterDef.PartnerTravelSlot.IndexDef.QuestType, tFilter.szName)
    end
end

function PartnerData.ConvertToFilterValueList_TravelSlot_QuestType(tbFilterInfo)
    local nFilterIndex = FilterDef.PartnerTravelSlot.IndexDef.QuestType
    local tValueDefList = tTravelSlot_Filter_DataIndex

    local tSelectedValueList    = {}

    for _, nIndex in ipairs(tbFilterInfo[nFilterIndex]) do
        local tInfo = tValueDefList[nIndex]
        table.insert(tSelectedValueList, tInfo.nID)
    end

    return tSelectedValueList
end

function PartnerData.GetPartnerIDList(dwPlayerID)
    local tAllPartnerList = Partner_GetAllPartnerList(dwPlayerID)
    local tPartnerIDList  = {}

    if tAllPartnerList then
        for _, tInfo in ipairs(tAllPartnerList) do
            table.insert(tPartnerIDList, tInfo.dwID)
        end
    end

    return tPartnerIDList
end

function PartnerData.GetFilteredPartnerIDList(tbInfo, dwPlayerID)
    local tSelectedWayInfoList    = {}
    local tSelectedKungfuInfoList = {}

    for _, nIndex in ipairs(tbInfo[1]) do
        local tInfo = tFilterWay[nIndex]
        table.insert(tSelectedWayInfoList, tInfo)
    end

    for _, nIndex in ipairs(tbInfo[2]) do
        local tInfo = tFilterKungfuIndex[nIndex]
        table.insert(tSelectedKungfuInfoList, tInfo)
    end

    local bHasFilter         = #tSelectedWayInfoList ~= 0 or #tSelectedKungfuInfoList ~= 0

    local tShowPartnerIDList = {}
    local tAllPartnerList    = Partner_GetAllPartnerList(dwPlayerID)
    if tAllPartnerList then
        for _, tInfo in ipairs(tAllPartnerList) do
            local bShow = true
            if bHasFilter then
                bShow = false

                --- 获取途径
                for _, tFilterInfo in ipairs(tSelectedWayInfoList) do
                    if tInfo.nFilterWay == tFilterInfo.nID then
                        bShow = true
                        break
                    end
                end

                --- 心法类型
                local nPartnerKungfuIndex = tInfo.nKungfuIndex
                if nPartnerKungfuIndex == 4 then
                    --- 在筛选时，辅助类型也看做输出类型
                    nPartnerKungfuIndex = 1
                end
                for _, tFilterInfo in ipairs(tSelectedKungfuInfoList) do
                    if nPartnerKungfuIndex == tFilterInfo.nID then
                        bShow = true
                        break
                    end
                end
            end

            if bShow then
                table.insert(tShowPartnerIDList, tInfo.dwID)
            end
        end
    end

    return tShowPartnerIDList
end

-- 为了各个侠客界面切换时更加流程，统一处理逻辑场景，避免每个场景单独创建而切换时要卡一下
--  1. 创建
--      在进入侠客界面后，第一次遇到需要加载场景的地方进行创建，后续调用时则返回该场景。进入新界面时，旧的界面需要先将自己管理的model view使用ShowModel接口先临时隐藏，回来时再恢复
--  2. 删除
--      在侠客主界面关闭时，若场景存在则进行删除

--- 设置为true，则由 侠客模块 自行管理场景，否则将由 NpcModelView 来管理
PartnerData.bNotMgrSceneByNpcModelView = true

--- 侠客场景文件路径，所有侠客相关的预览场景都使用该路径
PartnerData.szSceneFilePath            = Const.COMMON_SCENE

--- 获取场景实例，首次调用时会新创建一个
function PartnerData.GetOrCreateScene()
    if not PartnerData.bNotMgrSceneByNpcModelView then
        return nil
    end

    if not PartnerData.m_scene then
        PartnerData.m_scene = SceneHelper.Create(PartnerData.szSceneFilePath, true, true, true)
    end

    return PartnerData.m_scene
end

function PartnerData.GetScene()
    return PartnerData.m_scene
end

--- 移除场景实例
function PartnerData.ReleaseScene()
    SceneHelper.Delete(PartnerData.m_scene)
    PartnerData.m_scene = nil
end

--- 获取侠客 NPC模板ID => 侠客ID 的映射关系
local tPartnerNpcTemplateIDToPartnerID = nil
function PartnerData.GetNpcTemplateIDToPartnerIDMap()
    if not tPartnerNpcTemplateIDToPartnerID then
        tPartnerNpcTemplateIDToPartnerID = {}

        local tAllPartner                = Table_GetAllPartnerNpcInfo()
        for _, tNpcInfo in ipairs(tAllPartner) do
            local dwNpcID                             = GetNpcAssistedTemplateID(tNpcInfo.dwID)

            tPartnerNpcTemplateIDToPartnerID[dwNpcID] = tNpcInfo.dwID
        end
    end

    return tPartnerNpcTemplateIDToPartnerID
end

--- 沈剑心首次寻访必得
function PartnerData.IsFirstDrawMustMeet(dwID)
    local bFirstDrawMustHit = false
    if dwID == TEACH_PARTNER_ID then
        local nDrawState  = GDAPI_GetHeroState(dwID)
        if nDrawState == PartnerDrawState.NotMeet then
            bFirstDrawMustHit = true
        end
    end

    return bFirstDrawMustHit
end

function PartnerData.IsPartnerNpc(dwNpcID)
    local bResult = false

    local tKNpc = GetNpc(dwNpcID)
    if tKNpc then
        -- NPC对象存在，则根据属性判断类别
        if tKNpc.dwEmployer ~= 0 and tKNpc.nSpecies == NPC_SPECIES_TYPE.NPC_ASSISTED then
            bResult = true
        end
    else
        -- 不存在则判断侠客缓存的列表中是否存在该侠客
        for k, v in ipairs(PartnerData.tNpcList) do
            if v.dwNpcID == dwNpcID then
                bResult = true
                break
            end
        end
    end

    return bResult
end

local tRequestPartnerInfoGlobalIdToTime = {}

--- 获取侠客的心法等级
function PartnerData.GetPartnerNpcKungfuLevel(dwNpcID)
    local nLevel = 0

    local tKNpc  = NpcData.GetNpc(dwNpcID)
    if tKNpc then
        nLevel             = tKNpc.nLevel

        local tUIInfo      = Table_GetPartnerByTemplateID(tKNpc.dwTemplateID)
        local dwAssistedID = tUIInfo.dwNpcID

        local tPartner     = Partner_GetPartnerInfo(dwAssistedID, tKNpc.dwEmployer)
        if tPartner then
            nLevel = tPartner.nLevel
        elseif tKNpc.dwEmployer ~= UI_GetClientPlayerID() then
            --- 如果查不到侠客数据，且该侠客不是自己召唤的，则尝试请求一下该数据
            local player = GetPlayer(tKNpc.dwEmployer)
            if player then
                local szGlobalID = player.GetGlobalID()

                local nLastRequestTime = tRequestPartnerInfoGlobalIdToTime[szGlobalID]
                local nCurrentTime = GetCurrentTime()
                if not nLastRequestTime or nCurrentTime >= nLastRequestTime + 10 then
                    --- 10秒内最多尝试请求一次，避免出现异常情况下疯狂请求
                    tRequestPartnerInfoGlobalIdToTime[szGlobalID] = nCurrentTime

                    -- 与端游一样，dwCenterID取0，只查询当前服务器
                    PeekOtherPlayerNpcAssistedSimpleList(0, szGlobalID)
                end
            end
        end
    end

    return nLevel
end

--- 是否配置了可以与侠客交互
function PartnerData.CheckPartnerInteractive(dwID)
    local bResult = true

    local npc = GetNpc(dwID)
    if npc then
        local dwTemplateID = npc.dwTemplateID
        local bPartnerNpc = false -- 助战侠客

        local tPartnerNpcIDToPartnerID = PartnerData.GetNpcTemplateIDToPartnerIDMap()
        if tPartnerNpcIDToPartnerID and tPartnerNpcIDToPartnerID[dwTemplateID] then
            bPartnerNpc = true
        end

        if bPartnerNpc then
            bResult = not Storage.QuickPetAction.bPartnerShieldAction
        end
    end

    return bResult
end

--- 副本对应最大的人数（侠客+玩家）
--- note: 可能需要定期去这个服务器脚本同步过来 scripts/Map/ACT_助战npc/include/助战npc副本特殊指令.lua
local tMap_MaxPlayer = {
    [14] = 5, --灵霄峡
    [17] = 5, --天工坊
    [18] = 5, --无盐岛
    [19] = 5, --空雾峰
    [20] = 5, --天地三才阵
    [26] = 5, --荻花宫前山
    [28] = 5, --日轮山城
    [32] = 10, --战宝迦兰
    [33] = 5, --天子峰
    [34] = 5, --风雨稻香村
    [36] = 5, --英雄天地三才阵
    [37] = 5, --英雄天工坊
    [40] = 5, --英雄荻花宫前山
    [41] = 5, --英雄无盐岛
    [42] = 5, --英雄天子峰
    [43] = 5, --英雄空雾峰
    [44] = 5, --英雄日轮山城
    [45] = 5, --英雄灵霄峡
    [46] = 25, --英雄战宝迦兰
    [47] = 5, --英雄风雨稻香村
    [51] = 5, --剑冢
    --	[53]=2,--邀星坪_夜射天狼
    --	[55]=2,--守株围场_打猎
    --	[56]=2,--困龙岭_梅花桩
    --	[57]=2,--陷空坳_宇文宝藏
    [60] = 10, --持国天王殿
    [61] = 10, --宫中神武遗迹
    [62] = 5, --英雄剑冢
    [63] = 25, --英雄宫中神武遗迹
    [64] = 25, --25人普通宫中神武遗迹
    [65] = 25, --25人普通持国天王殿
    [66] = 25, --英雄持国天王殿
    [67] = 10, --荻花宫后山
    [68] = 10, --荻花圣殿
    [69] = 10, --10人英雄荻花圣殿
    [70] = 25, --25人普通荻花圣殿
    [71] = 5, --仙踪林
    [72] = 25, --25人英雄荻花圣殿
    [73] = 10, --英雄荻花宫后山
    [75] = 5, --毒神殿
    [106] = 5, --法王窟
    [107] = 5, --无量宫
    [109] = 10, --龙渊泽
    [110] = 5, --寂灭厅
    [111] = 5, --英雄仙踪林
    [112] = 5, --英雄毒神殿
    [113] = 5, --英雄寂灭厅
    [114] = 5, --英雄无量宫
    [115] = 5, --英雄法王窟
    [116] = 5, --低级仙踪林
    [117] = 25, --25人英雄龙渊泽
    [118] = 25, --25人普通龙渊泽
    [119] = 10, --10人英雄龙渊泽
    [120] = 10, --荻花洞窟
    [123] = 5, --低级唐门密室
    [125] = 5, --唐门密室
    [126] = 25, --神剑冢
    [130] = 25, --英雄荻花洞窟
    [131] = 10, --持国天王回忆录
    [133] = 25, --25人英雄烛龙殿
    [134] = 10, --烛龙殿
    [136] = 10, --会战唐门
    [138] = 25, --25人英雄会战唐门
    [140] = 10, --南诏皇宫
    [141] = 5, --光明顶秘道
    [142] = 5, --低级光明顶秘道
    --[143]=1,--试炼之地
    --[144]=1,--试炼之地
    --[145]=1,--试炼之地
    --[146]=1,--试炼之地
    --[147]=1,--试炼之地
    [148] = 25, --英雄持国回忆录
    [155] = 25, --英雄南诏皇宫
    [157] = 5, --英雄一线天
    [160] = 10, --战宝军械库
    [161] = 5, --华清宫
    [162] = 5, --英雄华清宫
    [163] = 5, --华清宫回忆录
    [164] = 10, --大明宫
    [165] = 25, --英雄大明宫
    [167] = 5, --一线天
    [169] = 5, --流离岛
    [170] = 5, --英雄流离岛
    [171] = 25, --英雄战宝军械库
    --	[174]=2,--迷仙引
    [175] = 10, --血战天策
    [176] = 25, --英雄血战天策
    [177] = 10, --风雪稻香村
    [178] = 25, --英雄风雪稻香村
    [179] = 5, --直城门
    [182] = 10, --秦皇陵
    [183] = 25, --英雄秦皇陵
    [184] = 5, --墨家秘殿
    [187] = 5, --春明门
    [189] = 5, --藏宝洞·野人谷
    [190] = 5, --藏宝洞·夜狼山
    [191] = 10, --太原之战·夜守孤城
    [192] = 10, --太原之战·逐虎驱狼
    [195] = 5, --雁门关之役
    [196] = 5, --普通雁门关之役
    [198] = 25, --英雄太原之战·夜守孤城
    [199] = 25, --英雄太原之战·逐虎驱狼
    [200] = 5, --璨翠海厅
    [203] = 5, --天泣林
    [204] = 5, --阴山圣泉
    [205] = 25, --挑战太原之战·夜守孤城
    [206] = 25, --挑战太原之战·逐虎驱狼
    [209] = 5, --梵空禅院
    [211] = 10, --10人挑战太原之战·夜守孤城
    [212] = 10, --10人挑战太原之战·逐虎驱狼
    [218] = 5, --引仙水榭
    [219] = 5, --微山书院
    [220] = 10, --永王行宫_仙侣庭园
    [221] = 10, --永王行宫_花月别院
    [222] = 5, --挑战璨翠海厅
    [224] = 5, --英雄天泣林
    [225] = 5, --英雄微山书院
    [227] = 5, --英雄阴山圣泉
    [228] = 5, --英雄梵空禅院
    [229] = 5, --英雄引仙水榭
    [230] = 25, --英雄永王行宫_花月别院
    [231] = 25, --英雄永王行宫_仙侣庭园
    [232] = 25, --试炼永王行宫_仙侣庭园
    [233] = 25, --试炼永王行宫_花月别院
    [234] = 10, --10人挑战永王行宫_仙侣庭园
    [235] = 10, --10人挑战永王行宫_花月别院
    [236] = 25, --25人挑战永王行宫_仙侣庭园
    [237] = 25, --25人挑战永王行宫_花月别院
    [240] = 10, --上阳宫_观风殿
    [241] = 10, --上阳宫_双曜亭
    [242] = 5, --白帝水宫
    [244] = 5, --挑战白帝水宫
    --	[245]=1,--大梦迷境
    [246] = 5, --星海幻景
    --	[247]=1,--梦回稻香
    [248] = 25, --英雄上阳宫_观风殿
    [249] = 25, --英雄上阳宫_双曜亭
    [250] = 25, --试炼上阳宫_观风殿
    [251] = 25, --试炼上阳宫_双曜亭
    [256] = 5, --夕颜阁
    [257] = 5, --英雄夕颜阁
    [258] = 5, --素月清秋
    [260] = 5, --挑战夕颜阁
    [261] = 5, --天街灯市
    [262] = 5, --刀轮海厅
    [263] = 10, --风雷刀谷_锻刀厅
    [264] = 10, --风雷刀谷_千雷殿
    [270] = 25, --英雄风雷刀谷_千雷殿
    [271] = 25, --英雄风雷刀谷_锻刀厅
    [272] = 25, --帮会风雷刀谷_千雷殿
    [273] = 25, --帮会风雷刀谷_锻刀厅
    [274] = 5, --天街灯市
    [275] = 5, --挑战刀轮海厅
    [283] = 10, --狼牙堡_战兽山
    [284] = 10, --狼牙堡_燕然峰
    [285] = 5, --银雾湖
    [286] = 25, --英雄狼牙堡_战兽山
    [287] = 25, --英雄狼牙堡_燕然峰
    [288] = 25, --帮会狼牙堡_战兽山
    [289] = 25, --帮会狼牙堡_燕然峰
    [290] = 5, --挑战银雾湖
    [291] = 5, --稻香秘事
    [292] = 5, --英雄稻香秘事
    --	[293]=1,--拭剑园战场
    [295] = 5, --挑战稻香秘事
    [298] = 10, --狼牙堡·辉天堑
    [299] = 10, --狼牙堡_狼神殿
    [300] = 25, --英雄狼牙堡·辉天堑
    [301] = 25, --英雄狼牙堡·狼神殿
    [303] = 10, --历战_空雾峰
    [304] = 10, --历战_天子峰
    [305] = 10, --历战_寂灭厅
    [306] = 10, --历战_毒神殿
    [307] = 10, --历战_荻花圣殿
    [308] = 10, --历战_风雷刀谷
    [309] = 10, --历战_风雨稻香村
    [310] = 10, --历战_灵霄峡
    [311] = 10, --历战_南诏皇宫
    [312] = 10, --历战_日轮山城
    [313] = 10, --历战_天地三才阵
    [314] = 10, --历战_无盐岛
    [315] = 10, --历战_英雄风雨稻香村
    [316] = 10, --历战_荻花洞窟
    [317] = 10, --历战_烛龙殿
    [318] = 10, --历战_持国天王殿
    [323] = 25, --帮会狼牙堡_辉天堑
    [324] = 25, --帮会狼牙堡_狼神殿
    [337] = 5, --泥兰洞天
    [339] = 5, --大衍盘丝洞
    [340] = 5, --镜泊湖
    [341] = 10, --冰火岛·荒血路
    [342] = 5, --九辩馆
    [343] = 5, --英雄迷渊岛
    --	[344]=1,--浮丘岛
    [347] = 10, --冰火岛·青莲狱
    [348] = 25, --英雄冰火岛·青莲狱
    [349] = 25, --挑战冰火岛·青莲狱
    [350] = 25, --试炼冰火岛·青莲狱
    [354] = 25, --英雄冰火岛·荒血路
    [355] = 5, --英雄大衍盘丝洞
    [356] = 5, --英雄泥兰洞天
    [357] = 5, --英雄镜泊湖
    [358] = 5, --迷渊岛
    [359] = 5, --英雄九辩馆
    [360] = 25, --挑战冰火岛·荒血路
    [361] = 25, --试炼冰火岛·荒血路
    [364] = 10, --尘归海·巨冥湾
    [365] = 25, --英雄尘归海·巨冥湾
    [366] = 25, --挑战尘归海·巨冥湾
    [368] = 10, --尘归海·饕餮洞
    [369] = 25, --英雄尘归海·饕餮洞
    [370] = 25, --挑战尘归海·饕餮洞
    [406] = 5, --英雄周天屿
    [407] = 5, --挑战周天屿
    [414] = 1500, --扬州_望扬镇_家园_004
    --[421]=5,--浪客行·悬棺裂谷
    --[422]=5,--浪客行·桑珠草原
    --[423]=5,--浪客行·东水寨
    --[424]=5,--浪客行·湘竹溪
    --[425]=5,--浪客行·荒魂镇
    [426] = 10, --敖龙岛
    [427] = 25, --25人普通敖龙岛
    [428] = 25, --25人英雄敖龙岛
    [431] = 5, --玄鹤别院
    [432] = 5, --英雄玄鹤别院
    --[433]=5,--浪客行·有间客栈
    --[434]=5,--浪客行·绥梦山
    --[435]=5,--浪客行·华清宫
    --[436]=5,--浪客行·枫阳村
    --[437]=5,--浪客行·荒雪路
    --[438]=5,--浪客行·古祭坛
    --[439]=5,--浪客行·雾荧洞
    --[440]=5,--浪客行·阴风峡
    --[441]=5,--浪客行·翡翠瑶池
    --[442]=5,--浪客行·胡杨林道
    --[443]=5,--浪客行·浮景峰
    --[445]=1,--江南府邸
    --[446]=1,--试炼之地
    --	[451]=5,--雪山温泉
    [452] = 10, --范阳夜变
    [453] = 25, --25人普通范阳夜变
    [454] = 25, --25人英雄范阳夜变
    --	[461]=5,--浪客行·落樱林
    [467] = 1, --幻灵境
    [468] = 5, --剑冢惊变
    [469] = 5, --英雄剑冢惊变
    [476] = 5, --梦入集真岛
    [477] = 5, --梧桐山庄
    [478] = 5, --英雄梧桐山庄
    [479] = 5, --罗汉门
    [480] = 5, --英雄罗汉门
    [481] = 5, --英雄梦入集真岛
    [482] = 10, --达摩洞
    [483] = 25, --25人普通达摩洞
    [484] = 25, --25人英雄达摩洞
    --	[487]=1,--镜花别院
    [489] = 5, --月落三星
    [490] = 5, --英雄月落三星
    --[517]=25,--少林_乱世_修罗挑战
    [518] = 10, --白帝江关
    [519] = 25, --25人普通白帝江关
    [520] = 25, --25人英雄白帝江关
    [521] = 5, --英雄漳水南路
    [522] = 5, --挑战漳水南路
    --[527]=5,--浪客行·浮丘岛
    --[528]=5,--浪客行·桂林
    [559] = 10, --雷域大泽
    [560] = 25, --25人普通雷域大泽
    [561] = 25, --25人英雄雷域大泽
    [562] = 10, --百战异闻录
    [563] = 5, --北天药宗_武氏别院
    [564] = 5, --英雄北天药宗_武氏别院
    --[566]=1,--盘扎寨
    --	[567]=5,--原野奇踪
    [573] = 10, --河阳之战
    [574] = 25, --25人普通河阳之战
    [575] = 25, --25人英雄河阳之战
    --	[594]=10,--黑幕场地

    [586] = 10, --西津渡
    [587] = 25, --25人普通西津渡
    [588] = 25, --25人英雄西津渡
    --	[594]=10,--剧本杀测试场景02
    [596] = 5, --沃石院
    [597] = 5, --英雄沃石院
    [598] = 5, --镇海阁地井
    [599] = 5, --英雄镇海阁地井
    [606] = 5, --幽藤馆
    [607] = 5, --英雄幽藤馆
    --	[620]=1,--首领扮演范阳夜变
    [622] = 5, --江天夜宴
    [623] = 5, --英雄江天夜宴

    [636] = 10, --武狱黑牢
    [637] = 25, --武狱黑牢
    [638] = 25, --武狱黑牢
    [639] = 5, --鹿桥驿
    [640] = 5, --英雄鹿桥驿
    [644] = 5, --黄龙洞

    [648] = 10, --九老洞
    [649] = 25, --九老洞
    [650] = 25, --九老洞

    [658] = 5, --栖灵洞天
    [659] = 5, --英雄栖灵洞天

    [668] = 10, --冷龙峰
    [669] = 25, --冷龙峰
    [670] = 25, --冷龙峰
}

--- 玩家在当前地图理论上最大可召唤的侠客数目
function PartnerData.GetMaxCanSummonCount()
    local nMaxCanSummonCount = 9

    local dwCurrentMapID = g_pClientPlayer.GetMapID()

    local nMaxPlayer = tMap_MaxPlayer[dwCurrentMapID]
    if nMaxPlayer then
        local nTeamMateAndTheirPartnerCount = 0
        if TeamData.IsInParty() then
            local nTeammateCount = GetClientTeam().GetTeamSize() - 1
            local nTeammatePartnerCount = #PartnerData.GetMyTeammatePartnerNpcList()

            nTeamMateAndTheirPartnerCount = nTeammateCount + nTeammatePartnerCount
        end

        nMaxCanSummonCount = math.min(nMaxCanSummonCount, nMaxPlayer - 1 - nTeamMateAndTheirPartnerCount)
    end

    local _, nMapType    = GetMapParams(dwCurrentMapID)
    if nMapType == MAP_TYPE.NORMAL_MAP then
        -- 在主城、门派、野外场景只能召唤一位伙伴
        nMaxCanSummonCount = math.min(nMaxCanSummonCount, 1)
    end

    return nMaxCanSummonCount
end

function PartnerData.GetPartnerFightScore(dwPartnerID)
    local nFightScore = 0

    local player = g_pClientPlayer
    if player then
        nFightScore = Tool_GetAssistedScore(player, dwPartnerID)
    end

    return nFightScore
end

function PartnerData.UpdateScoreInfo(dwPlayerID, dwPartnerID, LabelFight, LayoutFight)
    local bShowFightScore = false

    if Partner_IsSelfPlayer(dwPlayerID) and Partner_GetPartnerInfo(dwPartnerID, dwPlayerID) then
        local nFightScore = PartnerData.GetPartnerFightScore(dwPartnerID)
        if nFightScore > 0 then
            UIHelper.SetString(LabelFight, math.floor(nFightScore))
            UIHelper.LayoutDoLayout(LayoutFight)

            bShowFightScore = true
        end
    end

    UIHelper.SetVisible(LayoutFight, bShowFightScore)
end

function PartnerData.IfGetHeroDailyTea()
    if not SystemOpen.IsSystemOpen(14, false) then
        -- 功能未开启
        return true
    end

    local nHeroTeaBuffID = 23728        --每日找赵云睿领取茶叶的buff记录
    if not (g_pClientPlayer and g_pClientPlayer.IsHaveBuff(nHeroTeaBuffID, 1)) then
        return false
    else
        return true
    end
end

---@class NpcAssistedLevelUpData 侠客等级配置信息
---@field nExperience number
---@field nRunSpeed number
---@field nJumpSpeed number
---@field nHitBase number
---@field nMaxLife number
---@field nFinalMaxLifeAddPercent number
---@field nStrainRate number
---@field nAttackPowerBase number
---@field nTherapyPowerBase number
---@field nCriticalStrikeBaseRate number
---@field nCriticalDamageBaseRate number
---@field nPhysicsShieldBase number
---@field nMagicShield number
---@field nToughnessBase number
---@field nAllTypeOvercomeBase number
---@field nGlobalDamageFixedAdd number
---@field nAssistedPowerExtAdd number
---@field nAllShieldIgnoreAdd number

---@return NpcAssistedLevelUpData
function PartnerData.GetNpcAssistedLevelUpData(dwAssistedID, nLevel)
    return GetNpcAssistedLevelUpData(dwAssistedID, nLevel)
end

---获取侠客出行的大类列表（升序）
---@return []number
function PartnerData.GetPartnerTravelClassList()
    local tClassList = {}

    local tClassToSubToInfo = Table_GetPartnerTravelClassToSubToInfo()
    for nClass, _ in pairs(tClassToSubToInfo) do
        table.insert(tClassList, nClass)
    end

    table.sort(tClassList)

    return tClassList
end

PartnerTravelState = {
    NotHasConfig = 1, -- 未配置
    InTravel = 2, -- 出行中
    Finished = 3, -- 已完成
    KeepConfigAfterFinished = 4, -- 已领奖，保留之前的目标和侠客配置
}

--- 返回 任务状态，任务ID，侠客列表，开始时间，持续时间
---@return number, number, number[], number, number
function PartnerData.ParseTravelQuestInfo(tQuestInfo)
    local nQuest, tHeroList, nStart, nMinute = table.unpack(tQuestInfo)

    local nCurTime                           = GetCurrentTime()

    local nQuestState

    local fnIsNilOrZero = function(val)
        return val == nil or val == 0
    end

    local fnRemoveZeroHero = function(tPartnerIDList)
        local tRes = {}
        for _, nHeroID in ipairs(tPartnerIDList) do
            if nHeroID ~= 0 then
                table.insert(tRes, nHeroID)
            end
        end
        return tRes
    end

    if fnIsNilOrZero(nQuest) then
        --- 未配置
        nQuestState = PartnerTravelState.NotHasConfig
    elseif not fnIsNilOrZero(nStart) and nCurTime < (nStart + nMinute * 60) then
        --- 出行中
        nQuestState = PartnerTravelState.InTravel
    elseif not fnIsNilOrZero(nStart) and nCurTime >= (nStart + nMinute * 60) then
        --- 已完成
        nQuestState = PartnerTravelState.Finished
    else--[[if not fnIsNilOrZero(nQuest) and fnIsNilOrZero(nStart) then]]
        --- 已领奖，保留之前的目标和侠客配置
        nQuestState = PartnerTravelState.KeepConfigAfterFinished
    end

    -- 领奖后保留的配置中，没设置的侠客位置可能会是0，将他们移除
    tHeroList = fnRemoveZeroHero(tHeroList)

    return nQuestState, nQuest, tHeroList, nStart, nMinute
end

function PartnerData.GetTravelQuestInfo(nBoard, nQuestIndex)
    local tQuestInfo                                      = GDAPI_HeroTravelGetQuestInfo(nBoard, nQuestIndex)

    return PartnerData.ParseTravelQuestInfo(tQuestInfo)
end

function PartnerData.TravelQuestHaveConfig(nBoard, nQuestIndex)
    local nQuestState = PartnerData.GetTravelQuestInfo(nBoard, nQuestIndex)

    return nQuestState ~= PartnerTravelState.NotHasConfig
end

---@class PartnerTravelRewardItem
---@field dwType number
---@field dwIndex number
---@field nCount number

---@return PartnerTravelRewardItem[]
function PartnerData.GetItemRewardList(szRewardList)
    --- 5_44429_6;5_47857_15;
    local tbRes = {}

    if not szRewardList or szRewardList == "" then
        return tbRes
    end

    local tbReward = string.split(szRewardList, ";")
    local nNum     = #tbReward
    for nIndex = 1, nNum do
        if tbReward[nIndex] ~= "" then
            local tRewardInfo     = string.split(tbReward[nIndex], "_")
            local dwType, dwIndex, nCount = tonumber(tRewardInfo[1]), tonumber(tRewardInfo[2]), tonumber(tRewardInfo[3])

            table.insert(tbRes, {
                dwType = dwType,
                dwIndex = dwIndex,
                nCount = nCount,
            })
        end
    end
    return tbRes
end

function PartnerData.GetTravelCountInfo(nDataIndex)
    local nTravelCount, nMaxCount = GDAPI_HeroTravelGetClassCount(nDataIndex)

    local tClassInfo = Table_GetPartnerTravelClassByIndex(nDataIndex)
    local szLimitType = g_tStrings.STR_PARTNER_TRAVEL_LIMIT_TYPE[tClassInfo.nLimitType]

    local szLimit = "上限详见子类别"
    if szLimitType ~= nil then
        szLimit = szLimitType .. nTravelCount .. "/" .. tClassInfo.nLimitNum
    end

    return szLimit, nTravelCount, tClassInfo.nLimitNum
end

function PartnerData.GetBoardTravelQuestClass(nBoard)
    local nQuestClass      = nil

    local tBoardToInfoList = GDAPI_HeroTravelGetAllInfo()
    local tQuestInfoList   = tBoardToInfoList[nBoard]

    for _, tQuestInfo in ipairs(tQuestInfoList) do
        local nQuestState, nQuest      = PartnerData.ParseTravelQuestInfo(tQuestInfo)

        local bNotHasConfig            = nQuestState == PartnerTravelState.NotHasConfig
        local bInTravel                = nQuestState == PartnerTravelState.InTravel
        local bFinished                = nQuestState == PartnerTravelState.Finished
        local bKeepConfigAfterFinished = nQuestState == PartnerTravelState.KeepConfigAfterFinished

        -- todo: 后面需要确认 已领奖，但配置保留的算不算，先不管
        if not bNotHasConfig then
            local tInfo = Table_GetPartnerTravelTask(nQuest)
            nQuestClass = tInfo.nClass
            break
        end
    end

    return nQuestClass
end

function PartnerData.IsBoardInTravelOrFinished(nBoard)
    local bInTravelOrFinished = false

    local tBoardToInfoList = GDAPI_HeroTravelGetAllInfo()
    local tQuestInfoList   = tBoardToInfoList[nBoard]

    for _, tQuestInfo in ipairs(tQuestInfoList) do
        local nQuestState, nQuest      = PartnerData.ParseTravelQuestInfo(tQuestInfo)

        local bNotHasConfig            = nQuestState == PartnerTravelState.NotHasConfig
        local bInTravel                = nQuestState == PartnerTravelState.InTravel
        local bFinished                = nQuestState == PartnerTravelState.Finished
        local bKeepConfigAfterFinished = nQuestState == PartnerTravelState.KeepConfigAfterFinished

        if bInTravel or bFinished then
            bInTravelOrFinished = true
            break
        end
    end

    return bInTravelOrFinished
end

function PartnerData.IsTravelBoardUnlocked(nBoard)
    local bUnlocked  = false

    local tBoardInfo = Table_GetPartnerTravelTeamInfo(nBoard)

    if tBoardInfo.dwQuestID > 0 then
        bUnlocked = QuestData.IsCompleted(tBoardInfo.dwQuestID)
    end

    return bUnlocked
end

function PartnerData.IsPartnerInTravel(dwPartnerID)
    local bPartnerInTravel = false

    local tInTravelList = self.GetInTravelPartnerIDList()
    if table.contain_value(tInTravelList, dwPartnerID) then
        bPartnerInTravel = true
    end

    return bPartnerInTravel
end

function PartnerData.GetPartnerTravelStatus(dwPartnerID)
    local nPartnerTravelStatus

    local tInTravelList = GDAPI_HeroTravelTripList()
    if tInTravelList[dwPartnerID] then
        local nInTravelType = tInTravelList[dwPartnerID]
        if nInTravelType == 0 then --已安排未出行
            nPartnerTravelStatus = PARTNER_TRAVEL_TYPE.ARRANGED
        elseif nInTravelType == 1 then --已安排已出行
            nPartnerTravelStatus = PARTNER_TRAVEL_TYPE.INTRAVEL
        end
    end

    return nPartnerTravelStatus
end

function PartnerData.PartnerTravel_IsAnySlotInState(nTargetState)
    local tBoardToInfoList = GDAPI_HeroTravelGetAllInfo()
    for nBoard, tQuestInfoList in pairs(tBoardToInfoList) do
        for nQuestIndex, tQuestInfo in ipairs(tQuestInfoList) do
            local nQuestState              = PartnerData.ParseTravelQuestInfo(tQuestInfo)

            if nQuestState == nTargetState then
                return true
            end
        end
    end

    return false
end

function PartnerData.GetInTravelPartnerIDList()
    local tList = {}

    local tBoardToInfoList = GDAPI_HeroTravelGetAllInfo()

    for nBoard, tQuestInfoList in pairs(tBoardToInfoList) do

        for _, tQuestInfo in ipairs(tQuestInfoList) do
            local nQuestState, _, tHeroList      = PartnerData.ParseTravelQuestInfo(tQuestInfo)

            local bNotHasConfig            = nQuestState == PartnerTravelState.NotHasConfig
            local bInTravel                = nQuestState == PartnerTravelState.InTravel
            local bFinished                = nQuestState == PartnerTravelState.Finished
            local bKeepConfigAfterFinished = nQuestState == PartnerTravelState.KeepConfigAfterFinished

            if (bInTravel or bFinished) then
                table.insert_tab(tList, tHeroList)
            end
        end
    end

    return tList
end

---@param tQuest PartnerTravelTask
function PartnerData.IsTravelQuestLocked(tQuest)
    local bLocked             = false

    local bAchievementLocked  = false
    local bQuestLocked        = false

    --- 奇遇类需要自己至少尝试一次
    local bAdventureTryLocked = false

    local bFameLocked        = false

    if tQuest.szPreAchievement ~= "" then
        local nAchievementID = tonumber(tQuest.szPreAchievement)
        local aAchievement   = Table_GetAchievement(nAchievementID)
        local bFinished      = AchievementData.IsAchievementAcquired(nAchievementID, aAchievement)

        if not bFinished then
            bAchievementLocked = true
        end
    end

    if tQuest.szPreQuest ~= "" then
        local nQuestID  = tonumber(tQuest.szPreQuest)

        if tQuest.dwAdventureID == 0 then
            --- 前置任务
            local bFinished = QuestData.IsCompleted(nQuestID)

            if not bFinished then
                bQuestLocked = true
            end
        else
            --- 宠物奇遇
            --- 我们之前这里的“尝试一次”，读取的是AdventureTryBook.txt的dwTotalTryCountID列的值>0，但是这个值不是很稳定。
            ---打算修改为读取PartnerTravelTask.txt的szPreQuest列的值，如果前置任务状态等于3，表示尝试过。
            bAdventureTryLocked = QuestData.GetQuestPhase(nQuestID) ~= QUEST_PHASE.FINISH

            local bHasTrigger = PartnerData.IsAdventureTriggered(tQuest.dwAdventureID)
            if bHasTrigger then
                -- 若是已经触发了，则视为已解锁，比如通过天书来触发的
                bAdventureTryLocked = false
            end
        end
    end

    if tQuest.szPreFame ~= "" then
        local nFameId  = tonumber(tQuest.szPreFame)

        local tFameInfo = FameData.GetFameInfoList()
        for _, tInfo in ipairs(tFameInfo) do
            if tInfo.dwID == nFameId then
                if tInfo.bLocked then
                    bFameLocked = true
                end
            end
        end
    end

    bLocked = bAchievementLocked or bQuestLocked or bAdventureTryLocked or bFameLocked

    return bLocked, bAchievementLocked, bQuestLocked, bAdventureTryLocked, bFameLocked
end

---@param tQuest PartnerTravelTask
function PartnerData.IsTravelQuestTriggered(tQuest)
    local bHasTrigger = false

    local bIsPet     = tQuest.dwAdventureID ~= 0
    if bIsPet then
        bHasTrigger = PartnerData.IsAdventureTriggered(tQuest.dwAdventureID)
    end

    return bHasTrigger
end

function PartnerData.IsAdventureTriggered(dwAdventureID)
    local bHasTrigger = false

    local v       = Table_GetAdventureByID(dwAdventureID)
    if v.dwStartID ~= 0 then
        local bTriFlag = g_pClientPlayer.GetAdventureFlag(v.dwStartID)
        if bTriFlag then
            bHasTrigger = true
        end
    elseif v.nStartQuestID ~= 0 then
        local nAccQuest = g_pClientPlayer.GetQuestPhase(v.nStartQuestID)
        if nAccQuest > 0 then
            bHasTrigger = true
        end
    end

    return bHasTrigger
end

--  UIAdventureView:GetAllAdvTryBook()
--  UIAdventureTryBookCell:UpdateZhenQi
--  RemoteCallToServer("On_QiYu_PetTryList", tPetTryList)
--  EventType.OnGetAdventurePetTryBook
function PartnerData.GetAdvantureInfo(dwAdventureID)
    local bHasFuYuan = false
    local szPetName  = ""
    local szCount    = ""

    local nCamp      = g_pClientPlayer.nCamp

    local v          = Table_GetAdventureByID(dwAdventureID)

    v.bCanSee        = false
    if kmath.bit_and(2 ^ nCamp, v.nCampCanSee) ~= 0 then
        v.bCanSee = true
    end

    local tBuffList = v.tBuffList or {}
    local bUpBuff   = false
    for _, tBuff in ipairs(tBuffList) do
        local bHave = Buff_Have(g_pClientPlayer, tBuff[1], tBuff[2])
        if bHave then
            bUpBuff = true
            break
        end
    end
    v.bUpBuff = bUpBuff

    if v.nClassify == 1 then
        local tTryBook, nHasFTry, bTryLess = PartnerData.GetOneAdvTryBook(g_pClientPlayer, v.dwID, true)
        if tTryBook and #tTryBook ~= 0 and v.bCanSee then
            v.tTryBook   = tTryBook
            v.nHasFTry   = nHasFTry
            v.bTryLess   = bTryLess
            v.bHasTryMax = false
            if v.nHasFTry == #v.tTryBook and (not bTryLess) then
                v.bHasTryMax = true
            end

            local tShowTry = tTryBook[1] --珍奇只有一条
            local tPet     = Table_GetFellowPet(tShowTry.dwPetID)
            v.szPetName    = tPet.szName
            v.nMapID       = tPet.nMapID
            v.tPet         = tPet
            if PartnerData.IsLuckyPet(tShowTry.dwPetID) then
                v.bUpBuff = true
            end
        end
    end

    local tTryInfo  = PartnerData.tPetAdvIdToTryInfo[dwAdventureID]

    bHasFuYuan = v.bUpBuff
    szPetName  = UIHelper.GBKToUTF8(v.szPetName)
    szCount    = tTryInfo.nHasTry .. "/" .. tTryInfo.nTryMax

    return bHasFuYuan, szPetName, szCount
end

local REMOTE_TRYBOOK = 1140

function PartnerData.GetOneAdvTryBook(player, dwID, bPet)
    local tTryBook  = Table_GetAdventureTryBook(dwID)
    local nHasFTry  = 0
    local bHaveData = true
    if (not player) or (not player.HaveRemoteData(REMOTE_TRYBOOK)) then
        bHaveData = false
    end

    local bTryLess = false
    for _, v in ipairs(tTryBook) do
        local nTryTimes = 0
        if bHaveData and not bPet then
            nTryTimes = player.GetRemoteArrayUInt(REMOTE_TRYBOOK, v.nOffset, v.nLength)
        end
        v.nHasTry = nTryTimes

        if v.nTryMax == -1 then
            bTryLess = true
        elseif v.nTryMax <= nTryTimes then
            nHasFTry = nHasFTry + 1
        end
    end
    return tTryBook, nHasFTry, bTryLess
end

function PartnerData.IsLuckyPet(dwPetIndex)
    PartnerData.InitLuckyTable()

    if self.tLuckyScore[dwPetIndex] then
        return true
    else
        return false
    end
end

function PartnerData.InitLuckyTable(bForceInit)
    if self.tLuckyScore == nil or bForceInit then
        self.tLuckyScore = {}
        local tTime      = TimeLib.GetTodayTime()
        local szMonth    = tTime.month
        local szDay      = string.format("%02d", tTime.day)
        local szDate     = szMonth .. szDay
        local tLuckyPet  = GetLuckyFellowPet(szDate)
        for _, dwLuckyPetIndex in pairs(tLuckyPet) do
            self.tLuckyScore[dwLuckyPetIndex] = true
        end
    end
end

function PartnerData.GetTravelItemCostCount(dwItemType, dwItemIndex, nBaseCount, nClassDataIndex, nClassDataIndexShowCount)
    local nCostCount = nBaseCount

    if dwItemType == ITEM_TABLE_TYPE.OTHER and dwItemIndex == 76622 then
        local tLuCaiMultiCostConfigList = PartnerData.GetTravelClassLuCaiMultiCostConfigList(nClassDataIndex)
        if table.get_len(tLuCaiMultiCostConfigList) > 0 then
            local _, nCount, nMax = PartnerData.GetTravelCountInfo(nClassDataIndex)

            for _, tConfig in ipairs(tLuCaiMultiCostConfigList) do
                if nCount + nClassDataIndexShowCount - 1 >= tConfig.nReachCount then
                    nCostCount = nBaseCount * tConfig.nMultiple
                end
            end
        end
    end

    return nCostCount
end

---@class LuCaiMultiCostConfig 路菜翻倍消耗配置
---@field nReachCount number 达到指定次数
---@field nMultiple number 翻倍倍数

--- 获取指定大类的路菜消耗翻倍配置列表
---@return LuCaiMultiCostConfig[]
function PartnerData.GetTravelClassLuCaiMultiCostConfigList(nClassDataIndex)
    ---@type LuCaiMultiCostConfig[]
    local tLuCaiMultiCostConfigList = {}

    --- szCostItemMultiCount表示到多少次数后路菜消耗需要翻多少倍，比如到10次后翻2倍，15次后翻3倍，填"10;2|15;3"
    local tClass                    = Table_GetPartnerTravelClassByIndex(nClassDataIndex)

    local tCostMultiCount           = string.split(tClass.szCostItemMultiCount, "|")
    local nNum                      = #tCostMultiCount
    if nNum > 0 then
        for nIndex = 1, nNum do
            if tCostMultiCount[nIndex] ~= "" then
                local tCost                = string.split(tCostMultiCount[nIndex], ";")
                local nExceedCount, nMulti = tonumber(tCost[1]), tonumber(tCost[2])

                table.insert(tLuCaiMultiCostConfigList, {
                    nReachCount = nExceedCount,
                    nMultiple = nMulti,
                })
            end
        end
    end

    return tLuCaiMultiCostConfigList
end

function PartnerData.CheckTravelCost(tQuestIdList)
    local tCurrencyCost = {}
    local tItemCost     = {}
    -- 当前出行事件类别第几次出现（方便计算跨越翻倍次数时的消耗）
    local tClassDataIndexShowCount = {}

    for _, nQuest in ipairs(tQuestIdList) do
        local tQuest     = Table_GetPartnerTravelTask(nQuest)
        local szCostList = tQuest.szCostList

        if not tClassDataIndexShowCount[tQuest.nDataIndex] then
            tClassDataIndexShowCount[tQuest.nDataIndex] = 0
        end
        tClassDataIndexShowCount[tQuest.nDataIndex] = tClassDataIndexShowCount[tQuest.nDataIndex] + 1

        local tReward    = SplitString(szCostList, ";")
        for _, v in pairs(tReward) do
            local tInfo                   = SplitString(v, "_")
            local dwType, dwIndex, nCount = tonumber(tInfo[1]), tonumber(tInfo[2]), tonumber(tInfo[3])
            nCount                        = nCount or 0

            if tInfo[1] ~= "COIN" then
                local szItem = string.format("%s_%s", dwType, dwIndex)
                if not tItemCost[szItem] then
                    tItemCost[szItem] = 0
                end

                local nActualCount = PartnerData.GetTravelItemCostCount(dwType, dwIndex, nCount, tQuest.nDataIndex, tClassDataIndexShowCount[tQuest.nDataIndex])

                tItemCost[szItem]  = tItemCost[szItem] + nActualCount
            else
                local tbLine = Table_GetCalenderActivityAwardIconByID(dwIndex) or {}
                local szName = CurrencyNameToType[tbLine.szName]

                if not tCurrencyCost[szName] then
                    tCurrencyCost[szName] = 0
                end

                tCurrencyCost[szName] = tCurrencyCost[szName] + nCount
            end
        end
    end

    for szCurrencyType, nCount in pairs(tCurrencyCost) do
        local nCurrency = CurrencyData.GetCurCurrencyCount(szCurrencyType)
        if nCurrency < nCount then
            TipsHelper.ShowImportantYellowTip(string.format("本次出行需%d[%s]，您的%s不足", nCount, szCurrencyType, szCurrencyType))
            return false
        end
    end

    for szItem, nCount in pairs(tItemCost) do
        local dwType, dwIndex = table.unpack(SplitString(szItem, "_"))
        dwType                = tonumber(dwType)
        dwIndex               = tonumber(dwIndex)

        local nItemCount      = PartnerData.GetItemAmountInPackage(dwType, dwIndex)
        if nItemCount < nCount then
            local ItemInfo   = GetItemInfo(dwType, dwIndex)
            local szItemName = ItemData.GetItemNameByItemInfo(ItemInfo)

            TipsHelper.ShowImportantYellowTip(string.format("本次出行需物品[%s]%d个，您的物品不足", UIHelper.GBKToUTF8(szItemName), nCount))
            return false
        end
    end

    return true
end

function PartnerData.TravelAgain(tCanTravelAgainList)
    local tQuestIdList = {}
    for _, tTravel in ipairs(tCanTravelAgainList) do
        local nQuest     = tTravel[3]

        table.insert(tQuestIdList, nQuest)
    end

    local tList = {}
    local tItemToIndex = {}
    -- 当前出行事件类别第几次出现（方便计算跨越翻倍次数时的消耗）
    local tClassDataIndexShowCount = {}

    for _, nQuest in ipairs(tQuestIdList) do
        local tQuest     = Table_GetPartnerTravelTask(nQuest)
        local szCostList = tQuest.szCostList

        if not tClassDataIndexShowCount[tQuest.nDataIndex] then
            tClassDataIndexShowCount[tQuest.nDataIndex] = 0
        end
        tClassDataIndexShowCount[tQuest.nDataIndex] = tClassDataIndexShowCount[tQuest.nDataIndex] + 1

        local tReward    = SplitString(szCostList, ";")
        for _, v in pairs(tReward) do
            local tInfo                   = SplitString(v, "_")
            local dwType, dwIndex, nCount = tonumber(tInfo[1]), tonumber(tInfo[2]), tonumber(tInfo[3])
            nCount                        = nCount or 0

            local tItem
            if tInfo[1] ~= "COIN" then
                local nActualCount = PartnerData.GetTravelItemCostCount(dwType, dwIndex, nCount, tQuest.nDataIndex, tClassDataIndexShowCount[tQuest.nDataIndex])

                tItem = {
                    dwTabType = dwType,
                    dwIndex = dwIndex,
                    nStackNum = nActualCount,
                }
            else
                local tbLine = Table_GetCalenderActivityAwardIconByID(dwIndex) or {}
                local szName = CurrencyNameToType[tbLine.szName]

                tItem = {
                    dwTabType = tInfo[1],
                    dwIndex = szName,
                    nStackNum = nCount,
                }
            end

            local szKey = string.format("%s_%s", tInfo[1], tInfo[2])
            if tItemToIndex[szKey] then
                local nIndex = tItemToIndex[szKey]
                local tExistItem = tList[nIndex]

                tExistItem.nStackNum = tExistItem.nStackNum + tItem.nStackNum
            else
                table.insert(tList, tItem)
                tItemToIndex[szKey] = #tList
            end
        end
    end

    UIHelper.ShowConfirmWithItemList("确认要再次委托出行么？\n再次委托出行消耗：", tList, function()
        UIHelper.RemoteCallToServer("On_Hero_StartTravel", tCanTravelAgainList)
    end)
end

--- 不绑定路菜
local dwUnBindLuCaiID = 76622
--- 绑定路菜
local dwBindLuCaiID = 76634

function PartnerData.GetItemAmountInPackage(dwType, dwIndex)
    local nItemCount   = ItemData.GetItemAmountInPackage(dwType, dwIndex)
    if dwType == ITEM_TABLE_TYPE.OTHER and dwIndex == dwUnBindLuCaiID then
        --- 如果是不绑定路菜，则算上绑定路菜的数目
        nItemCount = nItemCount + ItemData.GetItemAmountInPackage(ITEM_TABLE_TYPE.OTHER, dwBindLuCaiID)
    end

    return nItemCount
end

---@class TravelPetTryInfo 出行宠物尝试信息
---@field nHasTry number 已尝试次数
---@field nTryMax number 最大尝试次数

---@type table<number, TravelPetTryInfo>
--- adv => {nHasTry, nTryMax}
PartnerData.tPetAdvIdToTryInfo = {}

function PartnerData.UpdatePetTryTime(nAdvID, nTryTime)
    local v = Table_GetAdventureByID(nAdvID)

    if v.nClassify == 1 then
        local tTryBook, nHasFTry, bTryLess = PartnerData.GetOneAdvTryBook(g_pClientPlayer, v.dwID, true)
        if tTryBook and #tTryBook ~= 0 then
            v.tTryBook   = tTryBook
            v.nHasFTry   = nHasFTry
            v.bTryLess   = bTryLess
            v.bHasTryMax = false
            if v.nHasFTry == #v.tTryBook and (not bTryLess) then
                v.bHasTryMax = true
            end

            local tShowTry   = tTryBook[1]
            tShowTry.nHasTry = nTryTime
            if tShowTry.nTryMax <= tShowTry.nHasTry then
                v.nHasFTry = 1
            end
            if v.nHasFTry == #v.tTryBook then
                v.bHasTryMax = true
            end
            v.tTryBook[1]                          = tShowTry

            PartnerData.tPetAdvIdToTryInfo[nAdvID] = {
                nHasTry = tShowTry.nHasTry,
                nTryMax = tShowTry.nTryMax,
            }
        end
    end
end

function PartnerData.NeedShowLimitedTips(dwID)
    local tPartner = Partner_GetPartnerInfo(dwID)
    local tInfo = Table_GetPartnerNpcInfo(dwID)

    --- 仅在未获取侠客，且配置了限定标记时显示限定信息
    return tPartner == nil and tInfo.szLimitTip ~= ""
end

function PartnerData.GetLimitedSpriteFrame(dwID, bCell)
    local tInfo = Table_GetPartnerNpcInfo(dwID)
    if not tInfo then
        return
    end

    local szPath = tInfo.szLimitIconPath
    local nFrame = tInfo.nLimitIconFrame
    if string.is_nil(szPath) or nFrame == -1 then
        return
    end

    szPath = string.gsub(szPath, "ui/Image", "Resource")
    szPath = string.gsub(szPath, "ui\\Image", "Resource")
    szPath = string.gsub(szPath, "^[\\/]", "") -- 去掉第一个/和\\
    szPath = string.gsub(szPath, "/", "_")
    szPath = string.gsub(szPath, "\\", "_")
    szPath = string.gsub(szPath, ".UITex", "")

    szPath = szPath.."_"..nFrame
    if bCell then
        szPath = szPath.."_Cell"
    end

    szPath = UIHelper.FixDXUIImagePath(szPath)
    return szPath
end
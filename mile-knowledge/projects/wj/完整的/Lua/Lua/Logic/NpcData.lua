-- Npc模块
NpcData = NpcData or {className = "NpcData"}
local self = NpcData
local registerEvents
local getQuestState, getQuestMarkWeight, countQuestMarkWeight
-- 开启低等级任务显示?
local g_bHideQuestShowFlag = true

local kSpecies2FrameName =
{
    [NPC_SPECIES_TYPE.NPC_HUMANOID] = "UIAtlas2_Public_PublicSchool_PublicSchool_TargetFrame47 (1)",
    [NPC_SPECIES_TYPE.NPC_BEAST] = "UIAtlas2_Public_PublicSchool_PublicSchool_TargetFrame47 (2)",
    [NPC_SPECIES_TYPE.NPC_MECHANICAL] = "UIAtlas2_Public_PublicSchool_PublicSchool_TargetFrame47 (3)",
    [NPC_SPECIES_TYPE.NPC_UNDEAD] = "UIAtlas2_Public_PublicSchool_PublicSchool_TargetFrame47 (4)",
    [NPC_SPECIES_TYPE.NPC_GHOST] = "UIAtlas2_Public_PublicSchool_PublicSchool_TargetFrame47 (8)",
    [NPC_SPECIES_TYPE.NPC_PLANT] = "UIAtlas2_Public_PublicSchool_PublicSchool_TargetFrame47 (9)",
    [NPC_SPECIES_TYPE.NPC_LEGENDARY] = "UIAtlas2_Public_PublicSchool_PublicSchool_TargetFrame47 (6)",
    [NPC_SPECIES_TYPE.NPC_CRITTER] = "UIAtlas2_Public_PublicSchool_PublicSchool_TargetFrame47 (7)",
}

-- 任务类型的权重、头顶卷轴ID配置在QuestType.tab, ID表见"represent/common/global_effect.txt"
local QUEST_MARK_LEVEL = -- 任务难度等级的权重
{
    [QUEST_DIFFICULTY_LEVEL.INVALID]      = nil,
    [QUEST_DIFFICULTY_LEVEL.PROPER_LEVEL] = 3,
    [QUEST_DIFFICULTY_LEVEL.HIGH_LEVEL]   = 2,
    [QUEST_DIFFICULTY_LEVEL.HIGHER_LEVEL] = nil,
    [QUEST_DIFFICULTY_LEVEL.LOW_LEVEL]    = 3,
    [QUEST_DIFFICULTY_LEVEL.LOWER_LEVEL]  = 1,
}

local QUEST_MARK_STATE = -- 任务完成状态的权重
{
    ["finished"]      = 30,
    ["unaccept"]      = 2,
    ["notneedaccept"] = 1,
    ["accepted"]      = nil,
    ["none"]          = nil,
}

local QUEST_MARK_NEED_KILL = 59 -- see "represent/common/global_effect.txt"

local function IsSearchTypeNpc(dwNpcTypeID)
    --TODO: 如何获得小地图正在搜索的Npc
    --return Minimap.tNpcSearch[dwNpcTypeID]
    return false
end

local l_tSimplePlayerNpc = {}
local tSimplePlayerInfo = {}
local tBindNpcList = {}
local tNpcList = {}

function NpcData.Init()
    self.tNpcs = {}                  -- {npcID = pNpc, ...},  进入场景的Npc映射表
    self.tQuestNpcMap = {}           -- {{npcID, true}, ...}, 进入场景了且有任务的Npc检索表
    self.tHidenOtherEmployeeIDs = {} -- {nTemplateID = true}, 需要隐藏的其它玩家召唤物模板id映射表
    self.tHidenSelfEmployeeIDs = {} -- {nTemplateID = true}, 需要自身玩家召唤物模板id映射表

    local _, nWeightEx = Table_GetQuestAllType()
    local nDifficultWeight = countQuestMarkWeight(QUEST_DIFFICULTY_LEVEL.HIGH_LEVEL, "unaccept", nWeightEx)
    self.nWeightEx = nWeightEx
    self.nDifficultWeight = nDifficultWeight

    registerEvents()
end

function NpcData.OnNpcEnter(nNpcID)
    local pNpc = GetNpc(nNpcID)
    self.tNpcs[nNpcID] = pNpc
    OnNpcEnterScene(nNpcID, pNpc)
    Event.Dispatch(EventType.OnNpcEnterScene, nNpcID)
end

function NpcData.OnNpcLeave(nNpcID)
    self.tNpcs[nNpcID] = nil
    self.tQuestNpcMap[nNpcID] = nil
    OnNpcLeaveScene(nNpcID)
    Event.Dispatch(EventType.OnNpcLeaveScene, nNpcID)
end

function NpcData.OnReload()
    Event.UnRegAll(self)
    registerEvents()
end

---comment 获取Npc对象
---@param nNpcID number
---@return userdata
function NpcData.GetNpc(nNpcID)
    return self.tNpcs[nNpcID]
end

---comment  获取客户端场景中所有的Npc
---@return table {nNpcID = pNpc, ...}
function NpcData.GetAllNpc()
    return self.tNpcs
end

-- Npc是否拥有任务
function NpcData.HasQuest(nNpcID)
    return self.tQuestNpcMap[nNpcID]
end

function NpcData.UpdateQuestNpcBindEffect()
    local hPlayer = g_pClientPlayer
    if not hPlayer then
        return
    end

    tBindNpcList = {}
    local tQuestList = hPlayer.GetQuestList()
    for _, dwQuestID in ipairs(tQuestList) do
        local nIndex = hPlayer.GetQuestIndex(dwQuestID)
        if nIndex then
            local hQuestTrace = hPlayer.GetQuestTraceInfo(dwQuestID)
            local tQuestStringInfo = Table_GetQuestStringInfo(dwQuestID)
            if hQuestTrace and tQuestStringInfo then
                for k, v in pairs(hQuestTrace.quest_state) do
                    local szNpcList = tQuestStringInfo[string.format("szBindNPCIDList%d", k)]
                    if v.have < v.need and szNpcList ~= "" then
                        local tNpcList = SplitString(szNpcList, ";")
                        for _, szTemplateID in ipairs(tNpcList) do
                            local nTemplateID = tonumber(szTemplateID)
                            tBindNpcList[nTemplateID] = tQuestStringInfo[string.format("nEffectID%d", k)]
                        end
                    end
                end
            end
        end
    end
end

-- 更新Npc的头顶特效
-- 依赖关联任务等
function NpcData.UpdateTitleEffect(nNpcID)
    local pPlayer = g_pClientPlayer
    local pNpc = GetNpc(nNpcID)
    if not pPlayer or not pNpc then
        return
    end

    if tBindNpcList[pNpc.dwTemplateID] then
        SceneObject_SetTitleEffect(TARGET.NPC, nNpcID, tBindNpcList[pNpc.dwTemplateID])
        return
    end


    local nMarkID = 0
    local aQuestList = pNpc.GetNpcQuest()
    if not aQuestList then
        SceneObject_SetTitleEffect(TARGET.NPC, nNpcID, nMarkID)
        return
    end

    BeginSample("NpcData.UpdateTitleEffect_questlen_"..#aQuestList)
    local nWeight, nLevel, szState, nType = 0
    for _, dwQuestID in pairs(aQuestList) do
        if not QuestData.IsAdventureQuest(dwQuestID) then--奇遇任务不显示头顶特效
            local nWeightQM, nLevelQM, szStateQM, nTypeQM = getQuestMarkWeight(pNpc, pPlayer, dwQuestID)
            if nWeight < nWeightQM then
                nWeight = nWeightQM
                nLevel = nLevelQM
                szState = szStateQM
                nType = nTypeQM
            end
        end
    end
    EndSample()
    self.tQuestNpcMap[nNpcID] = nWeight > 0 or nil

    if nWeight > self.nDifficultWeight then          -- quest mark
        nMarkID = Table_GetQuestMarkID(nLevel, szState, nType)
    elseif pPlayer.IsInParty() or OBDungeonData.IsPlayerInOBDungeon() then             -- party mark
        local nPartyMark
        if OBDungeonData.IsPlayerInOBDungeon() then
            nPartyMark = GetClientTeam().GetMarkIndexExceptTeamID(nNpcID) or 0
        else
            nPartyMark = GetClientTeam().GetMarkIndex(nNpcID) or 0
        end

        if nPartyMark and PARTY_TITLE_MARK_EFFECT_LIST[nPartyMark] then
            nMarkID = PARTY_TITLE_MARK_EFFECT_LIST[nPartyMark]
        end
    else                                        -- npc type mark
        -- 因为 IsSearchTypeNpc(dwNpcTypeID) 返回 false，所以这里先注释掉
        --[[
        local tNpc = Table_GetNpc(pNpc.dwTemplateID)
        if tNpc then
            local dwNpcTypeID = tNpc.dwTypeID
            if dwNpcTypeID and IsSearchTypeNpc(dwNpcTypeID) then
                local tNpcType = Table_GetNpcType(dwNpcTypeID)
                if tNpcType and tNpcType.dwEffectID > 0 then
                    nMarkID = tNpcType.dwEffectID
                end
            end
        end
        ]]
    end

    if nWeight > 0 and nMarkID == 0 then   -- unaccept hign/lower of quest mark
        local nEasyWeight = countQuestMarkWeight(QUEST_DIFFICULTY_LEVEL.LOWER_LEVEL, "unaccept", self.nWeightEx)
        if nWeight > nEasyWeight and nWeight < self.nDifficultWeight
        or nWeight < nEasyWeight and g_bHideQuestShowFlag then
            nMarkID = Table_GetQuestMarkID(nLevel, szState, nType)
        end
    end

    if nMarkID == 0 and (NpcData.IsQuestNeedKill(pPlayer, pNpc.dwTemplateID) == true or NpcData.IsDropQuestItemNpc(pPlayer, pNpc.dwTemplateID) == true) then
        nMarkID = QUEST_MARK_NEED_KILL
    end

    SceneObject_SetTitleEffect(TARGET.NPC, nNpcID, nMarkID)
end

function NpcData.IsQuestNeedKill(pPlayer, dwNpcTemplateID)
    if not pPlayer then
        return false
    end

    local tQuestList = pPlayer.GetQuestList()
    for _, dwQuestID in pairs(tQuestList or {}) do
        local tQuestTrace = pPlayer.GetQuestTraceInfo(dwQuestID)
        if tQuestTrace then
            for _, v in ipairs(tQuestTrace.kill_npc or {}) do
                if dwNpcTemplateID == v.template_id then
                    if v.have < v.need then
                        return true
                    end
                end
            end
        end
    end

    return false
end

function NpcData.IsDropQuestItemNpc(pPlayer, dwNpcTemplateID)
    if not pPlayer then
        return false
    end

    local tQuestList = pPlayer.GetQuestList()
    for _, dwQuestID in pairs(tQuestList or {}) do
        local tQuestTrace = pPlayer.GetQuestTraceInfo(dwQuestID)
        local tQuestInfo = GetQuestInfo(dwQuestID)
        if tQuestTrace and tQuestInfo then
            for i = 1, QUEST_COUNT.QUEST_END_ITEM_COUNT do
                if tQuestInfo["dwDropItemNpcTemplateID" .. i] ~= 0 and tQuestInfo["dwDropItemNpcTemplateID" .. i] == dwNpcTemplateID then
                    for _, v in ipairs(tQuestTrace.need_item or {}) do
                        if v.type == tQuestInfo["dwEndRequireItemType" .. i]
                        and v.index == tQuestInfo["dwEndRequireItemIndex" .. i]
                        and v.need == tQuestInfo["dwEndRequireItemAmount" .. i]
                        then
                            local tItemInfo = GetItemInfo(v.type, v.index)
                            if tItemInfo.nGenre == ITEM_GENRE.BOOK then
                                v.need = 1
                            end
                            if v.have < v.need then
                                return true
                            end
                        end
                    end
                end
            end
        end
    end

    return false
end

---comment 获取Npc头像图
---@param dwID integer npc ID
---@return string szImage
function NpcData.GetNpcHeadImage(dwID)
    local npc = self.GetNpc(dwID)
    if not npc then
        -- 默认值
        return kSpecies2FrameName[NPC_SPECIES_TYPE.NPC_HUMANOID]
    end

    -- 若是敌对时
    if npc.nSpecies == NPC_SPECIES_TYPE.NPC_HUMANOID and IsEnemy(dwID, g_pClientPlayer.dwID) then
        return "UIAtlas2_Public_PublicSchool_PublicSchool_TargetFrame47 (5)"
    end

    local szFrameName = kSpecies2FrameName[npc.nSpecies] or kSpecies2FrameName[NPC_SPECIES_TYPE.NPC_HUMANOID]
    return szFrameName
end

---comment 隐藏其它玩家的召唤物
---@param nTemplateID integer npc的模板ID
---@param bHide boolean 是否隐藏（true:隐藏，false:显示）
function NpcData.HideOtherEmployee(nTemplateID, bHide)
    self.tHidenOtherEmployeeIDs[nTemplateID] = bHide or nil
    local pScene = GetClientScene()
    if not g_pClientPlayer or not pScene then
        return
    end
    local dwLocalID = g_pClientPlayer.dwID
    for id, pNpc in pairs(self.tNpcs) do
        local dwEmployer = pNpc.dwEmployer
        if dwEmployer ~= 0 and dwEmployer ~= dwLocalID and pNpc.dwTemplateID == nTemplateID then
            pScene.HideCharacter(id, bHide)
        end
    end
end

---comment 隐藏自身的召唤物
---@param nTemplateID integer npc的模板ID
---@param bHide boolean 是否隐藏（true:隐藏，false:显示）
function NpcData.HideSelfEmployee(nTemplateID, bHide)
    self.tHidenSelfEmployeeIDs[nTemplateID] = bHide or nil
    local pScene = GetClientScene()
    if not g_pClientPlayer or not pScene then
        return
    end
    local dwLocalID = g_pClientPlayer.dwID
    for id, pNpc in pairs(self.tNpcs) do
        local dwEmployer = pNpc.dwEmployer
        if dwEmployer ~= 0 and dwEmployer == dwLocalID and pNpc.dwTemplateID == nTemplateID then
            pScene.HideCharacter(id, bHide)
        end
    end
end

---comment 应用Storage.HiddenEmployees中的数据
function NpcData.UpdateEmployeeHideState()
    for szKey, bHide in pairs(Storage.HiddenEmployees.tbData) do
        local lst = EmployeeTemplateTable[szKey]
        for _, nTemplateID in ipairs(lst) do
            NpcData.HideOtherEmployee(nTemplateID, bHide)
        end
    end

    for szKey, bHide in pairs(Storage.HiddenEmployees.tbSelfData) do
        local lst = EmployeeTemplateTable[szKey]
        for _, nTemplateID in ipairs(lst) do
            NpcData.HideSelfEmployee(nTemplateID, bHide)
        end
    end
end

function NpcData.OpenEmployeeHidePanel(bSelf)
    local szName = bSelf and "隐藏自身技能召唤物" or "隐藏其他玩家技能召唤物"
    local tbData = bSelf and Storage.HiddenEmployees.tbSelfData or Storage.HiddenEmployees.tbData

    for szKey, _ in pairs(EmployeeTemplateTable) do
        if tbData[szKey] == nil then
            tbData[szKey] = false
        end
    end

    local tAllTogs = {
        {
            szLabel = "全部选中",
            bOccupyWholeLine = true, -- 占据整行
            fnGetSelected = function()
                for _, bSelected in pairs(tbData) do
                    if not bSelected then
                        return false
                    end
                end
                return true
            end,
            fnOnSelected = function(bSelected)
                for szKey, _ in pairs(tbData) do
                    tbData[szKey] = bSelected
                end
                NpcData.UpdateEmployeeHideState()
                Storage.HiddenEmployees.Dirty()
                Event.Dispatch(EventType.OnMultiTogPopRefresh)
            end
        },
    }
    for szKey, tTemplateID in pairs(EmployeeTemplateTable) do
        local hNPC = GetNpcTemplate(tTemplateID[1])
        if hNPC then
            local szTemplateName = tTemplateID.szName
            szTemplateName = string.split(szTemplateName, "·")[1]
            local tInfo = {
                szLabel = szTemplateName,
                fnGetSelected = function()
                    return tbData[szKey]
                end,
                fnOnSelected = function(bSelected)
                    tbData[szKey] = bSelected
                    NpcData.UpdateEmployeeHideState()
                    Storage.HiddenEmployees.Dirty()
                    Event.Dispatch(EventType.OnMultiTogPopRefresh)
                end
            }
            table.insert(tAllTogs, tInfo)
        end
    end

    local script = UIMgr.Open(VIEW_ID.PanelMulitiTogPop)
    script:Init(szName, tAllTogs)
end

function registerEvents()
    Event.Reg(self, "QUEST_MARK_UPDATE", function ()
        self.UpdateTitleEffect(arg0)
    end)
    Event.Reg(self, "NPC_DISPLAY_DATA_UPDATE", function ()
        self.UpdateTitleEffect(arg0)
    end)
    Event.Reg(self, "SET_MAIN_PLAYER", function (nPlayerID)
        if nPlayerID == 0 then
            self.tNpcs = {}
            self.tQuestNpcMap = {}
        else
            self.UpdateEmployeeHideState()
        end
    end)

    Event.Reg(self,"PLAYER_SAY", function(szContent, dwCharacterID, nChannel)
        if ChatData.IsNPCBalloonChannel(nChannel) then
            -- 增加了 玩家 近聊头顶显示
            -- if IsPlayer(dwCharacterID) then
            --     return
            -- end
            -- if not GetNpc(dwCharacterID) then
            --     return
            -- end
            if dwCharacterID == 0 then
                return
            end

            TipsHelper.ShowNpcHeadBalloon(dwCharacterID,szContent , nChannel)
        end
    end)

    Event.Reg(self,"NPCSpeechSoundsOpen", function(dwID)
        TipsHelper.ShowNpcSpeechSoundsBalloon(dwID)
    end)

    Event.Reg(self, "SUCCESSIVE_QUEST_FINISHED", function(nQuestID, nNextQuestID)--连续任务
		self.UpdateQuestNpcBindEffect()
	end)

    Event.Reg(self,"QUEST_ACCEPTED", function()
        self.UpdateQuestNpcBindEffect()
    end)

    Event.Reg(self,"QUEST_FAILED", function()
        self.UpdateQuestNpcBindEffect()
    end)

    Event.Reg(self,"QUEST_CANCELED", function()
        self.UpdateQuestNpcBindEffect()
    end)

    Event.Reg(self,"QUEST_FINISHED", function()
        self.UpdateQuestNpcBindEffect()
    end)

    Event.Reg(self,"SET_QUEST_STATE", function()
        self.UpdateQuestNpcBindEffect()
    end)

    Event.Reg(self,"QUEST_DATA_UPDATE", function()
        self.UpdateQuestNpcBindEffect()
    end)

    Event.Reg(self,"QUEST_LIST_UPDATE", function()
        self.UpdateQuestNpcBindEffect()
    end)

    Event.Reg(self, EventType.OnAccountLogout, function()
        self.tHidenOtherEmployeeIDs = {}
        self.tHidenSelfEmployeeIDs = {}
    end)

    Event.Reg(self, "GET_SIMPLE_PLAYER_INFO", self.OnGetSimplePlayerInfo)
end

function getQuestMarkWeight(pNpc, pPlayer, dwQuestID)
    if not pNpc or not pPlayer then
        return 0
    end

    local nLevel = pPlayer.GetQuestDiffcultyLevel(dwQuestID)
    local szState = getQuestState(pNpc, pPlayer, dwQuestID)
    local nTypeWeight, nType = QuestData.GetQuestWeight(dwQuestID)
    if QuestData.IsMainPlotQuest(dwQuestID) then
        nTypeWeight = 2000
    end
    local nTotalWeight = countQuestMarkWeight(nLevel, szState, nTypeWeight)
    return nTotalWeight, nLevel, szState, nType
end

function countQuestMarkWeight(nLevel, szState, nTypeWeight)
    local nTotalWeight = 0
    local nLevelWeight = QUEST_MARK_LEVEL[nLevel]
    local nStateWeight = QUEST_MARK_STATE[szState]
    if nLevelWeight and nStateWeight and nTypeWeight then
        nTotalWeight = nLevelWeight * 1000 + nStateWeight * 100 + nTypeWeight
    end
    return nTotalWeight
end

function getQuestState(pNpc, pPlayer, dwQuestID)
    local szState = ""
    local eCanFinish = pPlayer.CanFinishQuest(dwQuestID, TARGET.NPC, pNpc.dwID)
    local eCanAccept = pPlayer.CanAcceptQuest(dwQuestID, TARGET.NPC, pNpc.dwID)
    local hQuestInfo = GetQuestInfo(dwQuestID)

    if eCanFinish == QUEST_RESULT.SUCCESS then
        szState = "finished"
    elseif eCanAccept == QUEST_RESULT.NO_NEED_ACCEPT
        and eCanFinish ~= QUEST_RESULT.TOO_LOW_LEVEL
        and eCanFinish ~= QUEST_RESULT.PREQUEST_UNFINISHED
        and eCanFinish ~= QUEST_RESULT.ERROR_REPUTE
        and eCanFinish ~= QUEST_RESULT.ERROR_CAMP
        and eCanFinish ~= QUEST_RESULT.ERROR_GENDER
        and eCanFinish ~= QUEST_RESULT.ERROR_ROLETYPE
        and eCanFinish ~= QUEST_RESULT.ERROR_FORCE_ID
        and eCanFinish ~= QUEST_RESULT.ERROR_QUEST_STATE
        and eCanFinish ~= QUEST_RESULT.COOLDOWN
        and eCanFinish ~= QUEST_RESULT.ERROR_REPUTE then
            szState = "notneedaccept"
    elseif eCanAccept == QUEST_RESULT.SUCCESS
        and hQuestInfo.dwStartNpcTemplateID == pNpc.dwTemplateID then
            szState = "unaccept"
    elseif eCanAccept == QUEST_RESULT.ALREADY_ACCEPTED
        and hQuestInfo.dwEndNpcTemplateID == pNpc.dwTemplateID then
            szState = "accepted"
    else
        szState = "none"
    end
    return szState
end


function GetSimplePlayerNpc(dwID)
    if not l_tSimplePlayerNpc[dwID] then
        local KNpc = GetNpc(dwID)
        l_tSimplePlayerNpc[dwID] = setmetatable({}, {
            __index = function(t, key)
                return KNpc[key]
            end,
        })
    end
    return l_tSimplePlayerNpc[dwID]
end

function GetNpcSimplePlayerInfo(dwNpcID)
    return tSimplePlayerInfo[dwNpcID]
end

function OnNpcEnterScene(dwNpcID, pNpc)
    table.insert(tNpcList, dwNpcID)

    local dwEmployerID = pNpc.dwEmployer
    if IsSimplePlayer(dwNpcID) then
        local hPlayer = {}
        hPlayer.dwID = dwEmployerID
        GetSimplePlayerInfo(dwEmployerID)
        tSimplePlayerInfo[dwNpcID] = hPlayer
    end
    --regionPQPanel.OnNpcEnterScene(dwNpcID)

    -- 隐藏其它玩家的宠物 or 隐藏自身宠物
    if dwEmployerID ~= 0 and ((dwEmployerID ~= g_pClientPlayer.dwID and self.tHidenOtherEmployeeIDs[pNpc.dwTemplateID])
            or (dwEmployerID == g_pClientPlayer.dwID and self.tHidenSelfEmployeeIDs[pNpc.dwTemplateID])) then
        pNpc.GetScene().HideCharacter(dwNpcID, true)
    end
end

function OnNpcLeaveScene(dwNpcID)
    for key, value in pairs(tNpcList) do
        if value == dwNpcID then
            table.remove(tNpcList, key)
            self.tQuestNpcMap[dwNpcID] = nil
            break
        end
    end

    local hPlayer = tSimplePlayerInfo[dwNpcID]
    if hPlayer then
        tSimplePlayerInfo[dwNpcID] = nil
    end
    --regionPQPanel.OnNpcLeaveScene(dwNpcID)
end

function NpcData.OnGetSimplePlayerInfo()
    local nPlayerID = arg0
    for dwNpcID, t in pairs(tSimplePlayerInfo) do
       if t.dwID == nPlayerID then
           t.dwID 				= arg0
           t.nLevel 			= arg1
           t.nCamp 			= arg2
           t.bCampFlag 		= arg3
           t.bFightState 		= arg4
           t.dwMiniAvatarID	= arg5
           t.dwForceID 		= arg6
           t.dwMountKungfuID 	= GetMobileKungfuID(arg7)
           t.nRoleType       	= arg8
           t.szName 			= arg9
           Character_SetEmployer(dwNpcID, t.szName)
       end
   end
end

function GetNpcList()
    return tNpcList
end
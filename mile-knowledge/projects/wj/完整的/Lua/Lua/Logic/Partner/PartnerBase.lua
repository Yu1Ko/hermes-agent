-- note: 搬运自 ui/Script/PartnerBase.lua 可能需要定期与其保持同步
PartnerBase = PartnerBase or {}

local szSettingFile = "/ui/Scheme/Setting/PartnerSetting.ini"
local REMOTE_PARTNER_PRESET = 1170 --助战编队预设远程数据块ID
local REMOTE_DATA_TEAM_INDEX_POS = 0 --当前正在使用的编队序号在远程数据块中存储的位置

local _tSetting = {}

g_tPartnerData =
{
    bShowAssistSetting = true,
    bShowMorphSetting = true,
    bShowAssistBarInDungeon = true,
    bVisit = false,
    bShowDoubleCol = true,
    --bShowRecommend = true,
}
--RegisterCustomData("g_tPartnerData.bShowAssistSetting")
--RegisterCustomData("g_tPartnerData.bShowMorphSetting")
--RegisterCustomData("g_tPartnerData.bShowAssistBarInDungeon")
--RegisterCustomData("g_tPartnerData.bVisit")
--RegisterCustomData("g_tPartnerData.bShowDoubleCol")
--RegisterCustomData("g_tPartnerData.bShowRecommend")

local m_nSound = nil
local m_szSoundPath = nil
local tMoodSetting = {
    [1] = {nStart = 0, nEnd = 10, nFrame = 90},
    [2] = {nStart = 10, nEnd = 80, nFrame = 89},
    [3] = {nStart = 80, nEnd = 100, nFrame = 88},
}

--pos_x, pos_y, pos_z, look_x, look_y, look_z, yaw, fovy
local m_aCameraData = {
    [NPC_EXTERIOR_TYPE.HAIR] = {
        [1] = {-45, 160, -45, 4, 173, 4,  0, 1},         -- 标准男,  -45, 160, -45, 4, 173, 4, 0, 0.6      -25, 172, -45, -1, 170, 4,  0, 1
        [2] = {-35, 153, -54, 30, 155, 48, 0, 0.7},       -- 标准女， -15, 151, -54, 15, 156, 48, 0, 0.8
        [5] = {-25, 104, -50, 18, 105, 54, 0, 0.6},       -- 小男孩
        [6] = {-18, 103, -54, 20, 110, 55, 0, 0.6},       -- 小孩女
    },
    [NPC_EXTERIOR_TYPE.CHEST] = {
        [1] = {-127, 90, -309.88, 90, 105, 220, 0, 0.6},    -- 标准男
        [2] = {-120, 90, -276, 90, 93, 207, 0, 0.6},        -- 标准女
        [5] = {-100, 70, -200, 60, 65, 120, 0, 0.6},        -- 小男孩
        [6] = {-30, 75, -210, 20, 60, 140, 0, 0.6}          -- 小孩女
    },
}


function Partner_GetPlayer(dwPlayerID)
    local pPlayer
    if dwPlayerID and dwPlayerID ~= 0 then
        pPlayer = GetPlayer(dwPlayerID)
    else
        pPlayer = GetClientPlayer()
    end
    return pPlayer
end

function Partner_IsSelfPlayer(dwPlayerID)
    if dwPlayerID and dwPlayerID ~= UI_GetClientPlayerID() then
        return false
    end
    return true
end

function Partner_GetSimpleExp(dwExp)
    local szRet = ""
    if dwExp < 10000 then
        szRet = tostring(dwExp)
    else
        local dwNumW = math.modf(dwExp / 10000)
        local dwModK = math.fmod(dwExp, 10000)
        local dwNumK = math.modf(dwModK / 1000)
        local dwModH = math.fmod(dwModK, 1000)
        local dwNumH = math.modf(dwModH / 100)
        szRet = FormatString(g_tStrings.STR_PARTNER_EXP_PROGRESS, dwNumW, dwNumK, dwNumH)
    end
    return szRet
end

function Partner_GetUpGradeItemSetting()
    local tItem = {
        --[1] = {nType = _tSetting.dwMItemType, dwIndex = _tSetting.dwMItemIndex, dwExp = _tSetting.dwMidExp},
        --[2] = {nType = _tSetting.dwLItemType, dwIndex = _tSetting.dwLItemIndex, dwExp = _tSetting.dwLargeExp},
        [1] = {nType = 5, dwIndex = 44429, dwExp = 1000},
        [2] = {nType = 5, dwIndex = 44430, dwExp = 10000},
    }
    return tItem
end

function Partner_GetPartnerMaxLevel()
    local nMaxLevel = GetNpcAssistedMaxLevel()
    return nMaxLevel
end

function Partner_SetAssistSettingShow(bShow)
    g_tPartnerData.bShowAssistSetting = bShow
    NpcMorphBar.OpenSummon(bShow)
end

function Partner_SetMorphSettingShow(bShow)
    g_tPartnerData.bShowMorphSetting = bShow
    NpcMorphBar.OpenMorph(bShow)
end

function Partner_GetAssistSettingShow()
    return g_tPartnerData.bShowAssistSetting
end

function Partner_GetMorphSettingShow()
    return g_tPartnerData.bShowMorphSetting
end

function Partner_SetAssistBarShowInDungeon(bShow)
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end
    local scene = pPlayer.GetScene()
    if scene.nType == MAP_TYPE.DUNGEON then
        NpcMorphBar.OpenSummon(bShow and g_tPartnerData.bShowAssistSetting)
        NpcMorphBar.OpenMorph(bShow and g_tPartnerData.bShowMorphSetting)
    end
    g_tPartnerData.bShowAssistBarInDungeon = bShow
end

function Partner_GetAssistBarShowInDungeon()
    return g_tPartnerData.bShowAssistBarInDungeon
end

function Partner_SetPartnerVisited(bVisit)
    g_tPartnerData.bVisit = bVisit
end

function Partner_IsPartnerVisited()
    return g_tPartnerData.bVisit
end

function Partner_SetShowDoubleColumnList(bShow)
    g_tPartnerData.bShowDoubleCol = bShow
end

function Partner_GetShowDoubleColumnList()
    return g_tPartnerData.bShowDoubleCol
end

function Partner_SetShowRecommend(bShow)
    Storage.PartnerSetting.bShowRecommend = bShow
    Storage.PartnerSetting.Dirty()

    Event.Dispatch("OnPartnerShowRecommendChanged")
end

function Partner_GetShowRecommend()
    return Storage.PartnerSetting.bShowRecommend
end

function Partner_GetLastPlaySoundID()
    return m_nSound
end

function Partner_GetLastPlaySoundPath()
    return m_szSoundPath
end

function Partner_SetPlayingSoundID(dwSoundID)
    m_nSound = dwSoundID
end

function Partner_SetPlayingSoundPath(szSoundPath)
    m_szSoundPath = szSoundPath
end

function Partner_StopPlayingSound()
    m_nSound = nil
    m_szSoundPath = nil
end

function Partner_GetMoodSetting()
    return tMoodSetting
end


---@class PartnerInfo 侠客信息
---@field dwAssistedID number 侠客模板ID
---@field nStage number 武学境界
---@field nLevel number 心法等级
---@field dwExp number 当前等级的经验
---@field dwFSExp number 好感度经验
---@field dwStamina number 体力
---@field bEquippedExterior number 是否穿着外观


---@return PartnerInfo
function Partner_GetPartnerInfo(dwPartnerID, dwPlayerID)
    local pPlayer = Partner_GetPlayer(dwPlayerID)
    if not pPlayer then
        return
    end
    local tInfo
    if dwPartnerID ~= 0 then
        local bUnlock = pPlayer.IsHaveNpcAssisted(dwPartnerID)
        if bUnlock then
            tInfo = pPlayer.GetNpcAssistedInfo(dwPartnerID)
        end
    end
    return tInfo
end

-- 教学侠客：沈剑心，首次必得
TEACH_PARTNER_ID = 4

---@return PartnerNpcInfo[]
function Partner_GetAllPartnerList(dwPlayerID, bOnlyNotTryOut, bOnlyHave)
    local bIsSelf = Partner_IsSelfPlayer(dwPlayerID)

    ---@param tNpcInfo1 PartnerNpcInfo
    ---@param tNpcInfo2 PartnerNpcInfo
    local function fnSort(tNpcInfo1, tNpcInfo2)
        -- 排序顺序: 侠客拥有状态（已拥有>任务中>未拥有）>等级(仅已拥有时有)>稀有度>id
        if bIsSelf then
            -- 自己的侠客根据抽卡状态来判断是否拥有的顺序，区分三种状态
            if tNpcInfo1.nDrawState ~= tNpcInfo2.nDrawState then
                return tNpcInfo1.nDrawState > tNpcInfo2.nDrawState
            end
        else
            -- 他人的侠客则仅有是否拥有两种状态
            if tNpcInfo1.bHave ~= tNpcInfo2.bHave then
                return tNpcInfo1.bHave
            end
        end

        if tNpcInfo1.bHave then
            if tNpcInfo1.nLevel ~= tNpcInfo2.nLevel then
                return tNpcInfo1.nLevel > tNpcInfo2.nLevel
            end
        end

        local nQuality1 = tNpcInfo1.nQuality or 0
        local nQuality2 = tNpcInfo2.nQuality or 0
        if nQuality1 ~= nQuality2 then
            return nQuality1 > nQuality2
        end

        return tNpcInfo1.dwID < tNpcInfo2.dwID
    end
    local tRes           = {}
    local tTeachList     = {}
    local tHaveList      = {}
    local tTeachPartner
    local bShowAll       = false
    local tRawAllPartner = Table_GetAllPartnerNpcInfo()

    local tAllPartner    = {}
    for _, tNpcInfo in ipairs(tRawAllPartner) do
        local dwID     = tNpcInfo.dwID
        local tPartner = Partner_GetPartnerInfo(dwID, dwPlayerID)
        if tPartner then
            tNpcInfo.bHave             = true
            tNpcInfo.nLevel            = tPartner.nLevel
            tNpcInfo.bEquippedExterior = tPartner.bEquippedExterior
        end
        if bIsSelf then
            tNpcInfo.nDrawState = GDAPI_GetHeroState(dwID)
        end

        local bIgnored = false

        -- 已绝版的侠客，若未拥有，则不显示
        if (tNpcInfo.bOutOfPrint and not tNpcInfo.bHave) or (bOnlyNotTryOut and tNpcInfo.bTryOut) or (bOnlyHave and not tPartner) then
            bIgnored = true
        end

        if not bIgnored then
            table.insert(tAllPartner, tNpcInfo)

            if dwID == TEACH_PARTNER_ID then
                -- 没沈剑心前：打开界面只显示沈剑心+已拥有的侠缘，沈剑心放第一个
                -- 抽到沈剑心后（做不做第一步任务都算），全部开放出来
                bShowAll      = tNpcInfo.nDrawState ~= PartnerDrawState.NotMeet
                tTeachPartner = tNpcInfo
            elseif tNpcInfo.bHave then
                table.insert(tHaveList, tNpcInfo)
            end
        end
    end
    if bShowAll then
        tRes = tAllPartner
        table.sort(tRes, fnSort)
    else
        table.insert(tTeachList, tTeachPartner)
        for _, tInfo in ipairs(tHaveList) do
            table.insert(tTeachList, tInfo)
        end
        tRes = tTeachList
    end
    return tRes
end

function Partner_GetNpcModelInfo(dwID)
    local tModel = {}
    local tInfo = Table_GetPartnerNpcInfo(dwID)
    tModel.fScale = tInfo.fScaleMB
    tModel.tCamera = StringParse_PointList(tInfo.szCamera)
    tModel.nRoleType = tInfo.nRoleType
    tModel.dwOrigModelID = tInfo.dwOrigModelID
    tModel.nDefaultActID = tInfo.nDefaultActID
    tModel.bSheath = tInfo.bSheath
    return tModel
end

function Partner_GetCurrentStagePoints(dwID, dwPlayerID)
    local pPlayer = Partner_GetPlayer(dwPlayerID)
    if not pPlayer then
        return
    end
    local nTotalStagePoints = pPlayer.GetNpcAssistedStagePoint(dwID)
    local tPointsSetting = GetNpcAssistedStagePointInfo(dwID)
    local tPartnerInfo = Partner_GetPartnerInfo(dwID, dwPlayerID)
    if not tPartnerInfo then
        return 0, 0
    end
    local nStage = tPartnerInfo.nStage
    local szKey = "Stage" .. nStage
    local szNextKey = "Stage" .. nStage + 1
    if nStage == 0 then --配置表里没有Stage0，默认为0
        return nTotalStagePoints, tPointsSetting[szNextKey]
    end
    local nMaxPoints = tPointsSetting[szKey]
    local nNextStageMaxPoints = nMaxPoints
    if tPointsSetting[szNextKey] then
        nNextStageMaxPoints = tPointsSetting[szNextKey]
    end
    nTotalStagePoints = nTotalStagePoints - nMaxPoints
    nNextStageMaxPoints = nNextStageMaxPoints - nMaxPoints
    return nTotalStagePoints, nNextStageMaxPoints
end

function Partner_GetPartnerMoodImgFrame(dwPartnerID, dwPlayerID)
    local pPlayer = Partner_GetPlayer(dwPlayerID)
    if not pPlayer then
        return
    end
    local dwStamina = pPlayer.GetNpcAssistedStamina(dwPartnerID)
    local dwMaxStamina = GetMaxStamina()
    local nStaminaScale = dwStamina / dwMaxStamina * 100
    for _, tInfo in ipairs(tMoodSetting) do
        local nStart = tInfo.nStart
        local nEnd = tInfo.nEnd
        if nStaminaScale >= nStart and nStaminaScale <= nEnd then
            return tInfo.nFrame
        end
    end
    return nil
end

function Partner_GetInAssistTeamIndex(dwID)
    local player = GetClientPlayer()
    if not player then
        return
    end

    if not dwID or dwID == 0 then
        return
    end

    local tInfo = Table_GetPartnerNpcInfo(dwID)
    if not tInfo then
        return
    end

    local szName = tInfo.szName
    local tAssistList = player.GetAssistedList() or {}
    for nIndex, dwAssistID in ipairs(tAssistList) do
        if dwAssistID ~= 0 then
            if dwID == dwAssistID then
                return nIndex
            end

            local tAssistInfo = Table_GetPartnerNpcInfo(dwAssistID)
            if tAssistInfo and szName == tAssistInfo.szName then
                return nIndex
            end
        end
    end
    return nil
end

function Partner_GetCurrentPreSetIndex()
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end

    if not pPlayer.HaveRemoteData(REMOTE_PARTNER_PRESET) then
        pPlayer.ApplyRemoteData(REMOTE_PARTNER_PRESET, REMOTE_DATA_APPLY_EVENT_TYPE.CLIENT_APPLY_SERVER_CALL_BACK)
        return
    end

    return pPlayer.GetRemoteArrayUInt(REMOTE_PARTNER_PRESET, REMOTE_DATA_TEAM_INDEX_POS, 1)
end

local ENABLE_OPEN_PARTNER_LEVEL = 110
function Partner_IsLevelCanOpen(nLevel)
    if not nLevel or nLevel < ENABLE_OPEN_PARTNER_LEVEL then
        local szMsg = FormatString(g_tStrings.STR_PARTNER_LEVEL_LIMIT, ENABLE_OPEN_PARTNER_LEVEL)
        OutputMessage("MSG_SYS", szMsg)
        OutputMessage("MSG_ANNOUNCE_YELLOW", szMsg)
        return false
    end
    return true
end

---------------------------------------------------------------

--local function LoadSetting()
--    UnRegisterEvent("PARTNER_ON_OPEN", LoadSetting)
--
--    local pFile = Ini.Open(szSettingFile)
--    if not pFile then
--        return
--    end
--    local szSection = "Partner"
--    _tSetting = {}
--    _tSetting.dwMItemType = pFile:ReadInteger(szSection, "MidItemType", 0)
--    _tSetting.dwMItemIndex = pFile:ReadInteger(szSection, "MidItemIndex", 0)
--    _tSetting.dwMidExp = pFile:ReadInteger(szSection, "MidExp", 0)
--    _tSetting.dwLItemType = pFile:ReadInteger(szSection, "LargeItemType", 0)
--    _tSetting.dwLItemIndex = pFile:ReadInteger(szSection, "LargeItemIndex", 0)
--    _tSetting.dwLargeExp = pFile:ReadInteger(szSection, "LargeExp", 0)
--    pFile:Close()
--end
--
--RegisterEvent("PARTNER_ON_OPEN", LoadSetting)
--
--local function OpenCombatPanel()
--    if not g_tPartnerData.bShowAssistSetting and not g_tPartnerData.bShowMorphSetting then
--        return
--    end
--
--    NpcMorphBar.OpenSummon(g_tPartnerData.bShowAssistSetting)
--    NpcMorphBar.OpenMorph(g_tPartnerData.bShowMorphSetting)
--    Partner_SetAssistBarShowInDungeon(g_tPartnerData.bShowAssistBarInDungeon)
--end
--RegisterEvent("FIRST_LOADING_END", OpenCombatPanel)

---------------- hotkeys -----------------
function Partner_OrderAttack()
    if not NpcMorphBar.IsSummonOpen() then
        return
    end
    NpcMorphBar.OrderNpcSkill("Attack")
end

function Partner_OrderFollow()
    if not NpcMorphBar.IsSummonOpen() then
        return
    end
    NpcMorphBar.OrderNpcSkill("Follow")
end

function Partner_OrderStop()
    if not NpcMorphBar.IsSummonOpen() then
        return
    end
    NpcMorphBar.OrderNpcSkill("Stop")
end

function Partner_SummonNpcSkill(dwIndex)
    if not NpcMorphBar.IsSummonOpen() then
        return
    end

    NpcMorphBar.SummonNpcSkill(dwIndex)
end

function Partner_MorphNpc(dwType, dwIndex)
    if not NpcMorphBar.IsMorphOpen() then
        return
    end

    NpcMorphBar.MorphNpc(dwType, dwIndex)
end

function Partner_EndMorph()
    if IsModuleLoaded("NpcMorphBar") and NpcMorphBar.IsMorphOpen() then
        NpcMorphBar.EndMorph()
    end
end
---------------------------------------

function OnNpcAssistedResultCode(nRetCode, dwAssistedID)
    if nRetCode == NPC_ASSISTED_RESULT_CODE.INVALID or nRetCode == NPC_ASSISTED_RESULT_CODE.SUCCESS then
        return
    end

    if g_tStrings.tNpcAssistedSuccessNotify[nRetCode] then
        if dwAssistedID then
            local tInfo = Table_GetPartnerNpcInfo(dwAssistedID)
            if tInfo.bTryOut then
                return
            end
        end

        OutputMessage("MSG_SYS", g_tStrings.tNpcAssistedSuccessNotify[nRetCode] .. "\n")
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tNpcAssistedSuccessNotify[nRetCode] .. "\n")
        -- elseif g_tStrings.tNpcAssistedOtherNotify[nRetCode] then
        --     OutputMessage("MSG_SYS", g_tStrings.tNpcAssistedOtherNotify[nRetCode] .. "\n")
        --     OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tNpcAssistedOtherNotify[nRetCode] .. "\n")
    elseif g_tStrings.tNpcAssistedFailureNotify[nRetCode] then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tNpcAssistedFailureNotify[nRetCode] .. "\n")
    elseif g_tStrings.tNpcAssistedFailureReason[nRetCode] then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tNpcAssistedFailureReason[nRetCode] .. "\n")
    end
end

--RegisterEvent("ON_NPC_ASSISTED_RESULT_CODE", function() OnNpcAssistedResultCode(arg0, arg1) end)

local function IsOpenPartnerTeam()
    --local scene = GetClientScene()
    --local dwMapID = scene.dwMapID
    --local _, nMapType = GetMapParams(dwMapID)
    --if nMapType and nMapType == MAP_TYPE.DUNGEON then
    --    PartnerTeam.Open()
    --else
    --    PartnerTeam.Close()
    --end
    --
    --NpcMorphBar.OpenSummon(g_tPartnerData.bShowAssistSetting)
    --NpcMorphBar.OpenMorph(g_tPartnerData.bShowMorphSetting)
    --Partner_SetAssistBarShowInDungeon(g_tPartnerData.bShowAssistBarInDungeon)

    -- 单人模式
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    if hPlayer.IsHaveBuff(27901, 1) or hPlayer.IsHaveBuff(27896, 1) then
        --- 进入单人模式的时候，检查下当前侠客的分数，上报到服务器，从而方便确认是否要提示更换为更强的侠客阵容
        Partner_CountAllNpcEquipScore(false)
    end
end
Event.Reg(PartnerBase, "LOADING_END", IsOpenPartnerTeam)


---------------------------------------------------------------

local tNewAddPartnerList = {}

function Partner_NewAddPartner(dwPartnerID)
    tNewAddPartnerList[dwPartnerID] = true
end

function Partner_GetNewAddPartnerList()
    return tNewAddPartnerList
end

function Partner_IsNewAddPartner(dwPartnerID)
    return tNewAddPartnerList[dwPartnerID]
end

function Partner_UnNewAddPartnerList(dwPartnerID)
    if tNewAddPartnerList[dwPartnerID] then
        tNewAddPartnerList[dwPartnerID] = nil
    end
end

function Partner_ClearNewAddPartnerList()
    tNewAddPartnerList = {}
end

function Partner_CountAllNpcEquipScore(bConfirm)
     local player = GetClientPlayer()
     if not player then
         return
     end

     local tAllNpcEquipScore = {}
     local tPartnerList = player.GetAllNpcAssisted() or {}
     for _, dwPartnerID in ipairs(tPartnerList) do
         local nScore = 0
         --local tEquipList = player.GetNpcCurrentEquip(dwPartnerID)
         --if tEquipList and tEquipList[0] then
         --    local tEquipInfo = tEquipList[0]
         --    tEquipInfo.tBaseAttib = player.GetNpcEquipBaseAttrib(tEquipInfo.dwEquipID)
         --    tEquipInfo.tMagicAttib = player.GetNpcEquipMagicAttrib(tEquipInfo.dwEquipID)
         --    local tChangeAttib = player.GetNpcEquipChangeAttrib(tEquipInfo.dwEquipID)
         --    tEquipInfo.tChangeAttib = GetMergeNpcEquipChangeAttib(tChangeAttib)
         --    nScore = GDAPI_HeroAndEquipMacth(dwPartnerID, tEquipInfo) or 0
         --end
         table.insert(tAllNpcEquipScore, {dwPartnerID, nScore})
     end
    RemoteCallToServer("On_Partner_CountNpcScore", tAllNpcEquipScore, bConfirm) --侠客装备改版了，装备分没有意义了
end

---------------------------Exterior----------------------------
function Partner_GetEquippedRepresentID(dwPartnerID, dwPlayerID)
    local pPlayer = Partner_GetPlayer(dwPlayerID)
    if not pPlayer then
        return
    end

    local tNpcRepresentID

    local bHave  = Partner_GetPartnerInfo(dwPartnerID, dwPlayerID) ~= nil
    if bHave then
        -- 拥有侠客时调用新接口，获取包含外装的外观列表
        tNpcRepresentID = pPlayer.GetNpcAssistedRepresentID(dwPartnerID)
    else
        -- 否则使用模板中配置的id
        tNpcRepresentID = GetNpcAssistedTemplateRepresentID(dwPartnerID)
    end

    local tRepresentID = PartnerView.NPCRepresentToPlayerRepresent(tNpcRepresentID)
    return tRepresentID
end

function Partner_GetExteriorCameraData(nType, nRoleType)
    if not nType or not nRoleType or not m_aCameraData[nType] then
        return
    end
    return m_aCameraData[nType][nRoleType]
end

function Partner_UpdatePreviewRepresentID(tRepresentID, nType, dwExteriorID)
    local nRepresentIndex, dwRepresentID, nColorIndex, nColorID = GetNpcExteriorManager().NpcExteriorData2RepresentData(nType, dwExteriorID)
    local tNpcRepresentID = {}
    if nRepresentIndex then
        tNpcRepresentID[nRepresentIndex] = dwRepresentID
    end
    if nColorIndex and nColorIndex ~= -1 then
        tNpcRepresentID[nColorIndex] = nColorID
    end
    local tNewRepresentID = PartnerView.NPCRepresentToPlayerRepresent(tNpcRepresentID)
    for nIndex, nRepresentID in pairs(tNewRepresentID) do
        tRepresentID[nIndex] = nRepresentID
    end
end

function Partner_GetPreviewItemRepresentID(dwPartnerID, dwTabType, dwIndex)
    local tRepresentID = Partner_GetEquippedRepresentID(dwPartnerID)
    local pItem = GetItemInfo(dwTabType, dwIndex)
    PartnerView.PreviewItem(tRepresentID, pItem)
    return tRepresentID
end

function Partner_IsExteriorCanDressToNpc(nType, dwExteriorID, dwPlayerID)
    local pPlayer = Partner_GetPlayer(dwPlayerID)
    if not pPlayer then
        return
    end
    local bCanDressToNpc = false
    if nType == NPC_EXTERIOR_TYPE.CHEST then
        local tInfo = GetExterior().GetExteriorInfo(dwExteriorID)
        bCanDressToNpc = tInfo.bCanDressToNpc
    elseif nType == NPC_EXTERIOR_TYPE.HAIR then
        local tPriceInfo = GetHairShop().GetHairPrice(pPlayer.nRoleType, HAIR_STYLE.HAIR, dwExteriorID)
        bCanDressToNpc = tPriceInfo.bCanDressToNpc
    end
    return bCanDressToNpc
end

---@return table<number, PreviewNpcExteriorInfo> 外观类型 -> 外观信息
function Partner_GetEquippedExteriorList(dwPlayerID, dwPartnerID)
    if not dwPlayerID then
        dwPlayerID = UI_GetClientPlayerID()
    end
    local tRes = {}
    local tEquippedExterior = GetNpcExteriorManager().GetNpcEquippedExterior(dwPlayerID, dwPartnerID)
    if not tEquippedExterior then
        tEquippedExterior = {}
    end
    for nType, dwExteriorID in pairs(tEquippedExterior) do
        -- if dwExteriorID ~= 0 then
            tRes[nType] = {
                nSource = NPC_EXTERIOR_SOURCE_TYPE.NPC_HAVE,
                tData = {
                    dwType = nType,
                    dwID   = dwExteriorID
                }
            }
        -- end
    end
    return tRes
end

function Partner_OutputPartnerExteriorTip(nSource, nType, szName, tRect)
    local szTip = ""
    if szName then
        local r, g, b = GetItemFontColorByQuality(4)
        szTip = szTip .. GetFormatText(szName, 60, r, g, b)
    end
    if nType then
        szTip = szTip .. GetFormatText("\n" .. g_tStrings.STR_PARTNER_EXTERIOR_TYPE[nType], 18)
    end
    if nSource and nSource == NPC_EXTERIOR_SOURCE_TYPE.NPC_HAVE then
        szTip = szTip .. GetFormatText("\n" .. g_tStrings.STR_PARTNER_EXTERIOR_HAVE, 105)
    end
    OutputTip(szTip, 400, tRect)
end

function Partner_GetChangeExteriorFailTip(nRetCode, dwPartnerID)
    local szPartnerName = ""
    if dwPartnerID then
        local tPartnerInfo = Table_GetPartnerNpcInfo(dwPartnerID)
        szPartnerName = UIHelper.GBKToUTF8(tPartnerInfo.szName)
    end
    local szTip = ""
    local szMsg = g_tStrings.STR_PARTNER_EXTERIOR_CHANGE_TIP[nRetCode]
    if nRetCode == NPC_EXTERIOR_ERROR_CODE.NPC_ALREADY_HAVE or nRetCode == NPC_EXTERIOR_ERROR_CODE.NPC_NOT_HAVE then
        szTip = FormatString(szMsg, szPartnerName)
    else
        szTip = szMsg
    end
    return szTip
end

local function fnOnExteriorChange(dwPartnerID, dwType, dwID, nMethod)
    local szMsg = ""
    if g_tStrings.STR_PARTNER_EXTERIOR_OPERATE[nMethod] then
        local tPartnerInfo = Table_GetPartnerNpcInfo(dwPartnerID)
        local szPartnerName = tPartnerInfo.szName
        local szExteriorName = ""
        if dwType == NPC_EXTERIOR_TYPE.HAIR then
            szExteriorName = CoinShopHair.GetHairText(dwID)
        elseif dwType == NPC_EXTERIOR_TYPE.CHEST then
            local tInfo = GetExterior().GetExteriorInfo(dwID)
            local tLine = Table_GetExteriorSet(tInfo.nSet)
            szExteriorName = tLine.szSetName
        end
        szMsg = FormatString(g_tStrings.STR_PARTNER_EXTERIOR_OPERATE[nMethod], UIHelper.GBKToUTF8(szExteriorName), UIHelper.GBKToUTF8(szPartnerName))
        OutputMessage("MSG_SYS", szMsg)
        OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
    end
end

local function fnOnExteriorMessage(dwAssistedNpcID, nRetCode)
    local szMsg = g_tStrings.STR_PARTNER_EXTERIOR_CHANGE_TIP[nRetCode]
    if nRetCode == NPC_EXTERIOR_ERROR_CODE.SUCCESS then
        OutputMessage("MSG_SYS", szMsg)
        OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
    else
        OutputMessage("MSG_SYS", szMsg)
        OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
    end
end

---------------------------------------------------------------

Event.Reg(PartnerBase, "ON_CHANGE_NPC_EXTERIOR_NOTIFY", fnOnExteriorChange)
Event.Reg(PartnerBase, "ON_NPC_EXTERIOR_MESSAGE_NOTIFY", fnOnExteriorMessage)

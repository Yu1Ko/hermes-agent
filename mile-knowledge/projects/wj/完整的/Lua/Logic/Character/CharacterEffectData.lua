CharacterEffectData = CharacterEffectData or {className = "CharacterEffectData"}

local tEffectType = {
	[0] = {szType = "Star", szName = "收藏", szIcon = "UIAtlas2_Character_Accessory_Img_Liked.png", szIcon2 = "UIAtlas2_Character_Accessory_Img_Liked_T.png"},
	[1] = {szType = "Footprint", szName = "脚印", szIcon = "UIAtlas2_Character_Accessory_Img_Footprint.png", szIcon2 = "UIAtlas2_Character_Accessory_Img_Footprint_T.png"},
	[2] = {szType = "CircleBody", szName = "环身", szIcon = "UIAtlas2_Character_Accessory_Img_AroundBody.png", szIcon2 = "UIAtlas2_Character_Accessory_Img_AroundBody_T.png"},
	[3] = {szType = "LHand", szName = "左手", szIcon = "UIAtlas2_Character_Accessory_Img_HandLeft.png", szIcon2 = "UIAtlas2_Character_Accessory_Img_HandLeft_T.png"},
    [4] = {szType = "RHand", szName = "右手", szIcon = "UIAtlas2_Character_Accessory_Img_HandRight.png", szIcon2 = "UIAtlas2_Character_Accessory_Img_HandRight_T.png",},
    [5] = {szType = "KillEffect", szName = "重伤他人", szIcon = "UIAtlas2_Character_Accessory_Img_KillEffect_T.png", szIcon2 = "UIAtlas2_Character_Accessory_Img_KillEffect_T.png"},
    [6] = {szType = "KillFeed", szName = "重伤播报", szIcon = "UIAtlas2_Character_Accessory_Img_KillFeed_T.png", szIcon2 = "UIAtlas2_Character_Accessory_Img_KillFeed_T.png"},
}

local tbEffectTypeToIndex =
{
    ["Start"]      = 0,
    ["Footprint"]  = 1,
    ["CircleBody"] = 2,
    ["LHand"]      = 3,
    ["RHand"]      = 4,
    ["KillEffect"] = 5,
    ["KillFeed"]   = 6,
}

local EFFECT_TYPE_LOGIC = {
	["Footprint"]   = PLAYER_SFX_REPRESENT.FOOTPRINT,
	["CircleBody"]  = PLAYER_SFX_REPRESENT.SURROUND_BODY,
    ["LHand"]       = PLAYER_SFX_REPRESENT.LEFT_HAND,
    ["RHand"]       = PLAYER_SFX_REPRESENT.RIGHT_HAND,
}

local DEFAULT_CUSTOM_DATA = {
    fScale = 1,
    nOffsetX = 0, nOffsetY = 0, nOffsetZ = 0,
    fRotationX = 0, fRotationY = 0, fRotationZ = 0,
}

local EFFECT_PAGE_SIZE = 12
local EFFECT_STAR_LIMIT = 20
local REMOTE_PREFER_EFFECT = 1132

Event.Reg(CharacterEffectData, "ACQUIRE_SFX", function(nSFXID, bIsAcquire)
    if not nSFXID then return end
    CharacterEffectData.OnAcquireEffect(nSFXID, bIsAcquire)
end)

Event.Reg(CharacterEffectData, EventType.OnCharacterPendantSelected, function(nIndex)
    CharacterEffectData.bEffectUIIsShow = nIndex == 2
end)

function CharacterEffectData.Init(dwSelectType)
    local szType = CharacterEffectData.GetType(dwSelectType)
    CharacterEffectData.tEffectList = CharacterEffectData.tEffectList or {}
    CharacterEffectData.szEffectType = szType or "Footprint"
    CharacterEffectData.szSearch = ""
    CharacterEffectData.nEffectPage = 1
    CharacterEffectData.tEffectFilter = {0, 0}
    CharacterEffectData.UpdateEffect(CharacterEffectData.szEffectType)
    local pPlayer = GetClientPlayer()
    if not pPlayer.HaveRemoteData(REMOTE_PREFER_EFFECT) then
        pPlayer.ApplyRemoteData(REMOTE_PREFER_EFFECT)
    end
end

Event.Reg(CharacterEffectData, EventType.OnRoleLogin, function()
    CharacterEffectData.bSyncCustomEffectData = false
end)

Event.Reg(CharacterEffectData, EventType.OnClientPlayerEnter, function()
    if CharacterEffectData.SyncCustomEffectData then
        return
    end
    local szType = "CircleBody"
    local dwEffectID = CharacterEffectData.GetEffectEquipByType(szType)
    if dwEffectID then
        CharacterEffectData.CustomEffectPlayerDataToLocal(PLAYER_SFX_REPRESENT.SURROUND_BODY, dwEffectID)
    end
    CharacterEffectData.SyncCustomEffectData = true
end)

Event.Reg(CharacterEffectData, "PLAYER_SFX_CHANGE", function()
    local dwEffectID = arg0
    local tInfo = Table_GetPendantEffectInfo(dwEffectID)
    if tInfo and tInfo.szType == "CircleBody" then
        CharacterEffectData.CustomEffectSetLocalDataToPlayer(PLAYER_SFX_REPRESENT.SURROUND_BODY, dwEffectID)
    end
end)

function CharacterEffectData.UnInit()
    --Event.UnRegAll(CharacterEffectData)

    CharacterEffectData.tEffectList         = nil
    CharacterEffectData.szEffectType        = nil
    CharacterEffectData.szSearch            = nil
    CharacterEffectData.tEffectFilter       = nil
    CharacterEffectData.nEffectPage         = nil
    CharacterEffectData.nMaxEffectPage      = nil
    CharacterEffectData.tEffectFiltedList   = nil
end

function CharacterEffectData.GetType(dwSelectType)
    local tbInfo = tEffectType[dwSelectType]
    if not tbInfo then return end

	return tbInfo.szType
end

function CharacterEffectData.GetTypeInfo(dwSelectType)
    local tbInfo = tEffectType[dwSelectType]
    if not tbInfo then return end

	return tbInfo
end

function CharacterEffectData.GetEffectList(szType)
    return CharacterEffectData.tEffectList and CharacterEffectData.tEffectList[szType]
end

function CharacterEffectData.GetSelectList(nType)
    local nBegin, nEnd, tFiltedSearchList = CharacterEffectData.GetEffectIndex(CharacterEffectData.szSearch, nType)
    return nBegin, nEnd, tFiltedSearchList, CharacterEffectData.nMaxEffectPage, CharacterEffectData.nEffectPage
end

function CharacterEffectData.GetMaxShowCount()
    return EFFECT_PAGE_SIZE
end

function CharacterEffectData.GetCurrentPage()
    return CharacterEffectData.nEffectPage
end

function CharacterEffectData.UpdateEffect(szType)
    if not CharacterEffectData.tEffectList then
        CharacterEffectData.Init()
    end
    if not szType then
        szType = CharacterEffectData.szEffectType
    end
    if szType == "Star" then
        CharacterEffectData.tEffectList[szType] = CharacterEffectData.GetEffectStarList()
    elseif not CharacterEffectData.tEffectList[szType] then
        CharacterEffectData.tEffectList[szType] = Table_GetPendantEffectListByType(szType, GetClientPlayer().nRoleType)
    end
    CharacterEffectData.UpdateFilter()
end

local EFFECT_SHOW_TYPE = {
    [0] = {fnFilter = function() return true end},
	[1] = {fnFilter = function(tInfo, pPlayer) return CharacterEffectData.IsEffectAcquired(tInfo.dwEffectID, pPlayer) end},
	[2] = {fnFilter = function(tInfo, pPlayer) return not CharacterEffectData.IsEffectAcquired(tInfo.dwEffectID, pPlayer) end},
}
function CharacterEffectData.UpdateFilter(nType1, nType2)
    if nType1 then
        CharacterEffectData.tEffectFilter[1] = nType1
    end
    if nType2 then
        CharacterEffectData.tEffectFilter[2] = nType2
    end

    CharacterEffectData.tEffectFiltedList = {}
    local pPlayer = GetClientPlayer()
    local fnFilter1 = EFFECT_SHOW_TYPE[CharacterEffectData.tEffectFilter[1]].fnFilter
    local fnFilter2 = function(tInfo)
        return CharacterEffectData.tEffectFilter[2] == 0 or CharacterEffectData.tEffectFilter[2] == tInfo.nSource
    end
    local tAllList = CharacterEffectData.tEffectList[CharacterEffectData.szEffectType] or {}
    local nAcquire = 0
    for _, tInfo in pairs(tAllList) do
        if fnFilter1(tInfo, pPlayer) and fnFilter2(tInfo) then
            if CharacterEffectData.IsEffectAcquired(tInfo.dwEffectID, pPlayer) then
                nAcquire = nAcquire + 1
                table.insert(CharacterEffectData.tEffectFiltedList, nAcquire, tInfo)
            else
                table.insert(CharacterEffectData.tEffectFiltedList, tInfo)
            end
        end
    end
end

function CharacterEffectData.CountEffect(dwPart)
    local szType = CharacterEffectData.GetType(dwPart)
    local nAcquire = 0
    local pPlayer = GetClientPlayer()
    if not CharacterEffectData.tEffectList[szType] then
        CharacterEffectData.UpdateEffect(szType)
    end
    if pPlayer and CharacterEffectData.tEffectList[szType] then
        for _, tInfo in pairs(CharacterEffectData.tEffectList[szType]) do
            if CharacterEffectData.IsEffectAcquired(tInfo.dwEffectID, pPlayer) then
                nAcquire = nAcquire + 1
            end
        end
    end

    if szType == "Star" then
        return #CharacterEffectData.tEffectList[szType], EFFECT_STAR_LIMIT
    end

    return nAcquire, #CharacterEffectData.tEffectList[szType]
end

function CharacterEffectData.IsEffectAcquired(dwEffectID, pPlayer)
    pPlayer = pPlayer or GetClientPlayer()
    local bResult = false
    if dwEffectID then
        local tEffectInfo = Table_GetPendantEffectInfo(dwEffectID)
        if tEffectInfo and tEffectInfo.dwSkillSkinID ~= 0 then
            bResult = pPlayer.IsHaveSkillSkin(tEffectInfo.dwSkillSkinID)
        else
            bResult = pPlayer.IsSFXAcquired(dwEffectID)
        end
    end
    return bResult
end

function CharacterEffectData.IsEffectUsing(dwEffectID, pPlayer)
    local bResult = false
    if dwEffectID then
        local tEffectInfo = Table_GetPendantEffectInfo(dwEffectID)
        if tEffectInfo and tEffectInfo.dwSkillSkinID ~= 0 then
            bResult = pPlayer.IsSkillSkinActive(tEffectInfo.dwSkillSkinID)
        else
            bResult = pPlayer.IsEquipSFX(dwEffectID)
        end
    end
    return bResult
end

function CharacterEffectData.EquipEffect(dwEffectID)
    local pPlayer = GetClientPlayer()
    if CharacterEffectData.IsEffectAcquired(dwEffectID, pPlayer) then
        local tEffectInfo = Table_GetPendantEffectInfo(dwEffectID)
        if tEffectInfo and tEffectInfo.dwSkillSkinID ~= 0 then
            local bUsing = pPlayer.IsSkillSkinActive(tEffectInfo.dwSkillSkinID)
            if not bUsing then
                local nRetCode = pPlayer.CanActiveSkillSkin(tEffectInfo.dwSkillSkinID)
                if nRetCode == SKILL_SKIN_RESULT_CODE.SUCCESS then
                    pPlayer.ActiveSkillSkin(tEffectInfo.dwSkillSkinID)
                else
                    local szTips = g_tStrings.tSkillSkinResult[nRetCode]
                    TipsHelper.ShowImportantRedTip(szTips)
                end
            else
                pPlayer.DeactiveSkillSkin(tEffectInfo.dwSkillSkinID)
            end
        else
            pPlayer.SetCurrentSFX(dwEffectID)
        end
    end
end

function CharacterEffectData.GetEffectIndex(szSearch, nType)
    local tFiltedSearchList
    szSearch = szSearch or ""
    if szSearch == "" then
        tFiltedSearchList = clone(CharacterEffectData.tEffectFiltedList)
    else
        tFiltedSearchList = {}
        for _, tLine in pairs(CharacterEffectData.tEffectFiltedList) do
            local szName = UIHelper.GBKToUTF8(tLine.szName)
            if string.find(szName, szSearch, 1, true) then
                table.insert(tFiltedSearchList, tLine)
            end
        end
    end

    -- 排序
    if nType then
        table.sort(tFiltedSearchList, function(a, b)
            local bIsNewA = RedpointHelper.Effect_IsNew(nType, a.dwEffectID)
            local bIsNewB = RedpointHelper.Effect_IsNew(nType, b.dwEffectID)

            local bIsAcquiredA = CharacterEffectData.IsEffectAcquired(a.dwEffectID)
            local bIsAcquiredB = CharacterEffectData.IsEffectAcquired(b.dwEffectID)

            if bIsNewA == bIsNewB then
                if bIsAcquiredA == bIsAcquiredB then
                    return a.dwEffectID < b.dwEffectID
                elseif bIsAcquiredA then
                    return true
                else
                    return false
                end
            elseif bIsNewA then
                return true
            else
                return false
            end
        end)
    end

    local nBegin, nEnd = 0, 0
    local nTotal = #tFiltedSearchList

    CharacterEffectData.nMaxEffectPage = math.ceil(nTotal / EFFECT_PAGE_SIZE)
    nBegin = (CharacterEffectData.nEffectPage - 1) * EFFECT_PAGE_SIZE + 1
    nEnd = CharacterEffectData.nEffectPage * EFFECT_PAGE_SIZE
    if nEnd > nTotal then
        nEnd = nTotal
    end
    return nBegin, nEnd, tFiltedSearchList
end

function CharacterEffectData.GetEffectInfo(dwEffectID)
    if dwEffectID and CharacterEffectData.tEffectFiltedList then
        for _, tInfo in pairs(CharacterEffectData.tEffectFiltedList) do
            if tInfo.dwEffectID == dwEffectID then
                return tInfo
            end
        end
    end
end

function CharacterEffectData.IsLegelEffectPage(nTargetPage)
    return nTargetPage and nTargetPage <= CharacterEffectData.nMaxEffectPage and nTargetPage >= 1
end

function CharacterEffectData.EffectTurnPage(nStep, nTargetPage)
    local bResult = false
    if not nTargetPage and nStep then
        nTargetPage = CharacterEffectData.nEffectPage + nStep
    end
    if CharacterEffectData.IsLegelEffectPage(nTargetPage) then
        CharacterEffectData.nEffectPage = nTargetPage
        bResult = true
    end
    return bResult
end

function CharacterEffectData.GetEffectStarList()
    local tList = {}
    local pPlayer = GetClientPlayer()
    local nCount = pPlayer.GetRemoteSetSize(REMOTE_PREFER_EFFECT)
    for nIndex = 1, nCount do
        local dwEffectID = pPlayer.GetRemoteDWordArray(REMOTE_PREFER_EFFECT, nIndex - 1)
        local tInfo = Table_GetPendantEffectInfo(dwEffectID)
        table.insert(tList, tInfo)
    end
    return tList
end

function CharacterEffectData.IsPreferEffect(dwEffectID)
	local hPlayer = GetClientPlayer()
	return hPlayer.HaveRemoteSet(REMOTE_PREFER_EFFECT, dwEffectID)
end

function CharacterEffectData.OnAcquireEffect(nSFXID, bIsAcquire)
    local tbEffect = Table_GetPendantEffectInfo(nSFXID)
	if not tbEffect then
		return
	end

	local nEffectType = tbEffectTypeToIndex[tbEffect.szType]
	if not nEffectType then
		return
	end

	RedpointHelper.Effect_SetNew(nEffectType, nSFXID, bIsAcquire)
end

function CharacterEffectData.GetEffectEquipByType(szType)
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end

    local tEffectList = Table_GetPendantEffectListByType(szType, GetClientPlayer().nRoleType) or {}
    for _, tInfo in pairs(tEffectList) do
        local bUsing = CharacterEffectData.IsEffectUsing(tInfo.dwEffectID, pPlayer)
        if bUsing then
            return tInfo.dwEffectID
        end
    end
end

---------------------挂饰秘鉴通用界面配置函数-----------------------
function CharacterEffectData.SetCurrentPage(dwCurrentPage)
    CharacterEffectData.nEffectPage = dwCurrentPage
end

function CharacterEffectData.SetSelectType(dwPart)
    local szType = CharacterEffectData.GetType(dwPart)
    CharacterEffectData.szEffectType = szType or "Footprint"
    CharacterEffectData.nEffectPage = 1
    CharacterEffectData.SetSearchText("")
    CharacterEffectData.UpdateEffect(CharacterEffectData.szEffectType)
end

function CharacterEffectData.SetSearchText(szSearch)
    CharacterEffectData.szSearch = szSearch
end

function CharacterEffectData.GetSearchText()
    return CharacterEffectData.szSearch
end

function CharacterEffectData.GetCollectionProgressTips()
    local szType = CharacterEffectData.szEffectType or "Footprint"
	local nEffectType = tbEffectTypeToIndex[szType]
    local nAcquire = 0
    local pPlayer = GetClientPlayer()
    local nBegin, nEnd, tFiltedSearchList = CharacterEffectData.GetSelectList(nEffectType)

    if pPlayer and tFiltedSearchList then
        for _, tInfo in pairs(tFiltedSearchList) do
            if CharacterEffectData.IsEffectAcquired(tInfo.dwEffectID, pPlayer) then
                nAcquire = nAcquire + 1
            end
        end
    end

    if szType == "Star" then
        return EFFECT_STAR_LIMIT, #tFiltedSearchList
    end

    return #tFiltedSearchList, nAcquire
end

function CharacterEffectData.GetCollectedNum()
    local nTotalNum = EFFECT_STAR_LIMIT
	local nHaveNum = #CharacterEffectData.tEffectList["Star"]

	return nTotalNum, nHaveNum
end

function CharacterEffectData.GetCurPageInfo()
	return CharacterEffectData.nMaxEffectPage, CharacterEffectData.nEffectPage
end

function CharacterEffectData.EmptyAllFilter()
	CharacterEffectData.SetSearchText("")
    CharacterEffectData.tEffectFilter = {0, 0}
end

function CharacterEffectData.UpdateFilterList()
    CharacterEffectData.UpdateEffect(CharacterEffectData.szEffectType)
    CharacterEffectData.GetEffectIndex(CharacterEffectData.szSearch)
end

--------------------环身自定义特效--------------------
function CharacterEffectData.GetLocalCustomEffectData(nType, dwEffectID)
    if not Storage.Character.tbCustomEffectInfo[nType] then
        return
    end
    return Storage.Character.tbCustomEffectInfo[nType][dwEffectID] or DEFAULT_CUSTOM_DATA
end

function CharacterEffectData.GetLocalCustomEffectDataEx(nType, dwEffectID)
    return CharacterEffectData.GetLocalCustomEffectData(nType, dwEffectID) or DEFAULT_CUSTOM_DATA
end

function CharacterEffectData.CustomEffectSetLocalDataToPlayer(nType, dwEffectID)
    local tData = CharacterEffectData.GetLocalCustomEffectData(nType, dwEffectID)
    if tData then
        local hPlayer = GetClientPlayer()
        if not hPlayer then
            return
        end
        hPlayer.SetEquipCustomSFXData(nType, tData)
    end
end

function CharacterEffectData.CustomEffectPlayerDataToLocal(nType, dwEffectID)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    local tCustomData = hPlayer.GetEquipCustomSFXData(nType)
    CharacterEffectData.CustomEffectOnSaveToLocal(nType, dwEffectID, tCustomData)
end

function  CharacterEffectData.CustomEffectOnSaveToLocal(nType, dwEffectID, tCustomData)
    if not Storage.Character.tbCustomEffectInfo[nType] then
        Storage.Character.tbCustomEffectInfo[nType] = {}
    end
    Storage.Character.tbCustomEffectInfo[nType][dwEffectID] = tCustomData
    Storage.Character.Dirty()
end

function CharacterEffectData.GetPendantEffectListByType(nType)
    local hPlayer                   = GetClientPlayer()
    if not hPlayer then
        return
    end

    local szType                    = CharacterEffectData.GetType(nType)
    local nRoleType                 = hPlayer.nRoleType
    local nCount                    = g_tTable.PendantEffect:GetRowCount()
    local tRes                      = {}
    for i = 2, nCount do
        local tLine                 = g_tTable.PendantEffect:GetRow(i)
        --这个bHide只是为了区分不能显示的国际服特效
        if not tLine.bHide and tLine.szType == szType then
            local dwEffectID        = tLine.dwEffectID
            local nType             = CharacterEffectData.GetLogicTypeByEffectType(szType)
            if CharacterEffectData.IsEffectAcquired(dwEffectID, hPlayer) then
                if tLine.szRoleType == "" then
                    tLine.nType = nType
                    table.insert(tRes, tLine)
                else
                    local tRoleType = string.split(tLine.szRoleType, ';')
                    for _, v in pairs(tRoleType) do
                        if tonumber(v) == nRoleType then
                            tLine.nType = nType
                            table.insert(tRes, tLine)
                            break
                        end
                    end
                end
            end
        end
    end
    return tRes
end

function CharacterEffectData.IsDefaultCustomData(tInfo)
    return IsTableEqual(tInfo, DEFAULT_CUSTOM_DATA)
end

function CharacterEffectData.GetAllEffectType()
    return EFFECT_TYPE_LOGIC
end

function CharacterEffectData.GetEffectTypeByLogicType(nType)
    for k, v in pairs(EFFECT_TYPE_LOGIC) do
        if v == nType then
            return k
        end
    end
end

function CharacterEffectData.GetLogicTypeByEffectType(szType)
    return EFFECT_TYPE_LOGIC[szType]
end

function CharacterEffectData.GetEffectEquipByTypeLogic(nType)
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end
    local nEquipID = pPlayer.GetEquipSFXID(nType)
    return nEquipID
end

local EFFECT_TYPE_TABLE = {
	[PLAYER_SFX_REPRESENT.FOOTPRINT] = g_tStrings.STR_MY_EFFECT_TYPE_FOOTPRINT,
	[PLAYER_SFX_REPRESENT.SURROUND_BODY] = g_tStrings.STR_MY_EFFECT_TYPE_CIRCLEBODY,
	[PLAYER_SFX_REPRESENT.LEFT_HAND] = g_tStrings.STR_MY_EFFECT_TYPE_LHAND,
	[PLAYER_SFX_REPRESENT.RIGHT_HAND] = g_tStrings.STR_MY_EFFECT_TYPE_RHAND,
}

function CharacterEffectData.CoinShop_GetEffectTypeTable()
    return EFFECT_TYPE_TABLE
end
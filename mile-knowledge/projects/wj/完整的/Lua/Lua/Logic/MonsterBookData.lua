MonsterBookData = MonsterBookData or {className = "MonsterBookData"}
local EDGE_BAR_FRAME =
{
    [1] = "UIAtlas2_Baizhan_BaizhanMain_Img_Bar_White",     -- 白
    [2] = "UIAtlas2_Baizhan_BaizhanMain_Img_Bar_Yellow",    -- 黄
    [3] = "UIAtlas2_Baizhan_BaizhanMain_Img_Bar_Blue",      -- 蓝
    [4] = "UIAtlas2_Baizhan_BaizhanMain_Img_Bar_Green",     -- 绿
    [5] = "UIAtlas2_Baizhan_BaizhanMain_Img_Bar_Red",       -- 红
    [6] = "UIAtlas2_Baizhan_BaizhanMain_Img_Bar_Purple",    -- 紫
    [7] = "UIAtlas2_Baizhan_BaizhanMain_Img_Bar_Black",     -- 黑
}

local EDGE_COLOR_FRAME =
{
    [1] = "UIAtlas2_Baizhan_BaizhanMain_Img_Color_White",     -- 白
    [2] = "UIAtlas2_Baizhan_BaizhanMain_Img_Color_Yellow",    -- 黄
    [3] = "UIAtlas2_Baizhan_BaizhanMain_Img_Color_Blue",      -- 蓝
    [4] = "UIAtlas2_Baizhan_BaizhanMain_Img_Color_Green",     -- 绿
    [5] = "UIAtlas2_Baizhan_BaizhanMain_Img_Color_Red",       -- 红
    [6] = "UIAtlas2_Baizhan_BaizhanMain_Img_Color_Purple",    -- 紫
    [7] = "UIAtlas2_Baizhan_BaizhanMain_Img_Color_Black",     -- 黑
}

local EDGE_COLOR_FRAME_ROUND =
{
    [1] = "UIAtlas2_Baizhan_BaizhanMain_Img_Color_White_R",     -- 白
    [2] = "UIAtlas2_Baizhan_BaizhanMain_Img_Color_Yellow_R",    -- 黄
    [3] = "UIAtlas2_Baizhan_BaizhanMain_Img_Color_Blue_R",      -- 蓝
    [4] = "UIAtlas2_Baizhan_BaizhanMain_Img_Color_Green_R",     -- 绿
    [5] = "UIAtlas2_Baizhan_BaizhanMain_Img_Color_Red_R",       -- 红
    [6] = "UIAtlas2_Baizhan_BaizhanMain_Img_Color_Purple_R",    -- 紫
    [7] = "UIAtlas2_Baizhan_BaizhanMain_Img_Color_Black_R",     -- 黑
}

local EDGE_COLOR_NAME =
{
    [1] = "白色",
    [2] = "黄色",
    [3] = "蓝色",
    [4] = "绿色",
    [5] = "红色",
    [6] = "紫色",
    [7] = "黑色",
}

local DEFAULT_SKILL_MAP = {
    [28202] = true,
    [28212] = true,
    [28213] = true
}

local SURFACE_COEFFICIENT =
{
    [10080] = 2,
    [100409] = 2,
    [10448] = 1.5,
    [101125] = 1.5,
}

local tGenderCantSkill = {
	---男性禁止学习技能
	[1] = {
		[30676] = 1,
		[30687] = 1,
	},
	---女性禁止学习技能
	[2] = {
		[30604] = 1,
		[30765] = 1,
		[35136] = 1,
	}
}

local MAX_LEVEL = 8
local tBookIndex = {
    [1] = 45845,
    [2] = 50769,
    [3] = 66154,
    [4] = 75452,
}
local tInviteToPlayerBZInfo = {}
local UI_SWITCH       = true -- 外网显示百战
local UI_SWITCH_EXP   = false  -- 体服显示百战
local UI_SWITCH_DEBUG = true  -- 内网显示百战

MonsterBookData.PLAY_MAP_ID = 562   ---百战异闻录地图ID
MonsterBookData.MAX_SKILL_LEVEL = 10   ---百战武学最高技能等级
MonsterBookData.MAX_CMP_LEVEL = 8   ---百战武学可用通本提升到的最高技能等级
MonsterBookData.MAX_SCHEME_COUNT = 8   ---百战武学预设最大数量
MonsterBookData.MAX_SCHEME_NAME_SIZE = 8   ---百战武学预设名长度上限
MonsterBookData.REMOTE_SCHEME_DATA_ID = 1094 -- 百战预设数据
WAREHOUSE_NSKILL = 301      -----------百战的仓库场景自定义变量位置
MonsterBookData.ACTION_BAR_INDEX = 18 -- 百战技能栏的编号
MonsterBookData.dwLevelChoosePreQuestID1 = 25211
MonsterBookData.dwLevelChoosePreQuestID2 = 25255
MonsterBookData.dwSEInfoPreQuestID = 25208
MonsterBookData.tImpartLimitInfoMap = {
-- [传授等级] = { nNeedValue=精耐达标，nSELimitImpartLevel=精耐达标需求等级，nNoLimitImpartLevel=精耐不达标需求等级，nCost=传授内力消耗(读表获取无需填写)}
    [1] = {nNeedValue = 15000, nSELimitImpartLevel = 3, nNoLimitImpartLevel = 4, nCost = 0},
    [2] = {nNeedValue = 22000, nSELimitImpartLevel = 4, nNoLimitImpartLevel = 5, nCost = 0},
    [3] = {nNeedValue = 33000, nSELimitImpartLevel = 5, nNoLimitImpartLevel = 6, nCost = 0},
    [4] = {nNeedValue = 45000, nSELimitImpartLevel = 6, nNoLimitImpartLevel = 7, nCost = 0},
    [5] = {nNeedValue = 80000, nSELimitImpartLevel = 7, nNoLimitImpartLevel = 8, nCost = 0},
    [6] = {nNeedValue = 110000, nSELimitImpartLevel = 8, nNoLimitImpartLevel = 9, nCost = 0},
    [7] = {nNeedValue = 180000, nSELimitImpartLevel = 9, nNoLimitImpartLevel = 10, nCost = 0},
}

function MonsterBookData.Init()
    LOG.INFO("MonsterBookData.Init Start...")
    LoadScriptFile(UIHelper.UTF8ToGBK("scripts/Map/百战异闻录/include/百战异闻录外部技能常量数据.lua"), MonsterBookData)

    MonsterBookData.tLastSpiritValueMap = {}
    MonsterBookData.tLastEnduranceValueMap = {}
    MonsterBookData.tBossNameHashMap = {}
    MonsterBookData.tIn2OutSkillMap = {}
    MonsterBookData.tOut2InSkillMap = {}
    MonsterBookData.ClearActivedSkillData()
    local tSkillAll = Table_GetAllMonsterSkill()
    for nIndex, tSkill in ipairs(tSkillAll) do
        local szBossName = tSkill.szBossName
        if szBossName and not MonsterBookData.tBossNameHashMap[szBossName] then
            MonsterBookData.tBossNameHashMap[szBossName] = nIndex
        end
    end
    local tAllMonsterSkillList = Table_GetAllMonsterSkill()
    for _, tLine in ipairs(tAllMonsterSkillList) do
        MonsterBookData.tIn2OutSkillMap[tLine.dwInSkillID] = tLine.dwOutSkillID
        if tLine.dwOutSkillID > 0 then
            MonsterBookData.tOut2InSkillMap[tLine.dwOutSkillID] = tLine.dwInSkillID
        end
    end

    local tCostPoints = GDAPI_MonsterBook_GetImpartCostPoints()
    for nLevel, tInfo in ipairs(MonsterBookData.tImpartLimitInfoMap) do
        tInfo.nCost = tCostPoints[nLevel]
    end

    if not Storage.MonsterBook.tSkillPresetName or #Storage.MonsterBook.tSkillPresetName == 0 then
        for i = 1, MonsterBookData.MAX_SCHEME_COUNT do
            table.insert(Storage.MonsterBook.tSkillPresetName, string.format("预设%s", g_tStrings.tChineseNumber[i]))
        end
    end

    MonsterBookData.bInitData = true
    LOG.INFO("MonsterBookData.Init End...")
end

function MonsterBookData.UnInit()
    MonsterBookData.bInitData = false
end

function MonsterBookData.GetCanImpartLevel(nSkillLevel, nUseValue)
    for nLevel = #MonsterBookData.tImpartLimitInfoMap, 1, -1 do
        local tLimitInfo = MonsterBookData.tImpartLimitInfoMap[nLevel]
        if tLimitInfo.nNoLimitImpartLevel <= nSkillLevel or (tLimitInfo.nSELimitImpartLevel <= nSkillLevel and nUseValue >= tLimitInfo.nNeedValue) then
            return nLevel
        end
    end

    return 0
end

function MonsterBookData.ClearActivedSkillData()
    MonsterBookData.tExtendSkillList = {28202, 28212, 28213}
    MonsterBookData.tSkillStackTrace = {}
    MonsterBookData.tSkillSurfaceNumMap = {}
end

function MonsterBookData.ResetActivedSkillData()
    local tDefaultSkills = {28202, 28212, 28213}
    for i, nSkillID in ipairs(MonsterBookData.tExtendSkillList) do
        MonsterBookData.OnMonsterBookSkillChanged(nSkillID, tDefaultSkills[i], 1)
    end
end

function MonsterBookData.TryLoadCustomData()
    MonsterBookData.tCustomData = Storage.MonsterBook
end

function MonsterBookData.PreActiveSkill(dwSkillID)
    MonsterBookData.tCustomData.tActiveSkillTime[dwSkillID] = os.time()
end

function MonsterBookData.SetLastSpiritValue(dwTargetID, nNewValue)
    if not MonsterBookData.tLastSpiritValueMap[dwTargetID] then
        MonsterBookData.tLastSpiritValueMap[dwTargetID] = nNewValue
    elseif nNewValue ~= MonsterBookData.tLastSpiritValueMap[dwTargetID] then
        local nDelta = nNewValue - MonsterBookData.tLastSpiritValueMap[dwTargetID]
        MonsterBookData.tLastSpiritValueMap[dwTargetID] = nNewValue
        local dwPlayerID = GetClientPlayer().dwID
        Event.Dispatch(EventType.OnSpiritEnduranceChanged, dwPlayerID, dwTargetID, true, nDelta)
    end
end

function MonsterBookData.SetLastEnduranceValue(dwTargetID, nNewValue)
    if not MonsterBookData.tLastEnduranceValueMap[dwTargetID] then
        MonsterBookData.tLastEnduranceValueMap[dwTargetID] = nNewValue
    elseif nNewValue ~= MonsterBookData.tLastEnduranceValueMap[dwTargetID] then
        local nDelta = nNewValue - MonsterBookData.tLastEnduranceValueMap[dwTargetID]
        MonsterBookData.tLastEnduranceValueMap[dwTargetID] = nNewValue
        local dwPlayerID = GetClientPlayer().dwID
        Event.Dispatch(EventType.OnSpiritEnduranceChanged, dwPlayerID, dwTargetID, false, nDelta)
    end
end

function MonsterBookData.IsHaveActiveBook(dwSkillID, nLevel)
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end

    -- 检验通本
    local tBookInfo = Table_GetMonsterCommonBookInfo(nLevel)
    if tBookInfo then
        local nCount = pPlayer.GetItemAmountInPackage(tBookInfo.dwTabType, tBookInfo.dwItemIndex)
        if nCount > 0 then return true end
    end

    -- 检验专本
    local dwItemType = 5
    for nSkillLevel = nLevel, MonsterBookData.MAX_SKILL_LEVEL do
        local dwItemIndex = MonsterBookData.GetMonsterBookItemIndex(dwSkillID, nSkillLevel)
        local nCount = pPlayer.GetItemAmountInPackage(dwItemType, dwItemIndex)
        if nCount > 0 then return true end
    end
    return false
end

function MonsterBookData.IsHaveCommonActiveBook(nLevel)
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end
    local bHave = false
    local bReplaceHave = false
    local tBookInfo = Table_GetMonsterCommonBookInfo(nLevel)
    if tBookInfo then
        local nCount = pPlayer.GetItemAmountInPackage(tBookInfo.dwTabType, tBookInfo.dwItemIndex)
        bHave = nCount >= tBookInfo.nCostCount
        if (not bHave) and tBookInfo.dwReplaceItemIndex > 0 then
            local nDiff = tBookInfo.nCostCount - nCount
            local nCount = pPlayer.GetItemAmountInPackage(tBookInfo.dwReplaceTabType, tBookInfo.dwReplaceItemIndex)
            bReplaceHave = nCount * tBookInfo.nReplaceCount >= nDiff
        end
    end
    return bHave, bReplaceHave
end

function MonsterBookData.GetActiveBookCost(nLevel)
    local szTextNum = ""
    local szName = ""
    local tBookInfo = Table_GetMonsterCommonBookInfo(nLevel)
    if tBookInfo then
        local pItemInfo = GetItemInfo(tBookInfo.dwTabType, tBookInfo.dwItemIndex)
        szTextNum = tostring(tBookInfo.nCostCount)
        szName = UIHelper.GBKToUTF8(pItemInfo.szName)
    end
    return szTextNum, szName
end

function MonsterBookData.GetActiveBookReplaceCost(nLevel)
    local szTextNum = ""
    local szName = ""
    local szReplaceName = ""
    local tBookInfo = Table_GetMonsterCommonBookInfo(nLevel)
    if tBookInfo then
        local pItemInfo = GetItemInfo(tBookInfo.dwReplaceTabType, tBookInfo.dwReplaceItemIndex)
        local nR, nG, nB = GetItemFontColorByQuality(pItemInfo.nQuality, false)
        szTextNum = GetFormatText(tBookInfo.nReplaceCount, 163)
        szReplaceName = GetFormatText("[" .. pItemInfo.szName .. "]", 163, nR, nG, nB)
        local pItemInfo = GetItemInfo(tBookInfo.dwTabType, tBookInfo.dwItemIndex)
        local nR, nG, nB = GetItemFontColorByQuality(pItemInfo.nQuality, false)
        szName = GetFormatText("[" .. pItemInfo.szName .. "]", 163, nR, nG, nB)
    end
    return szTextNum, szName, szReplaceName
end

function MonsterBookData.GetCost(dwSkillID, bInSkill)
    local nCost = 0
    if dwSkillID and dwSkillID > 0 then
        local tInfo = Table_GetMonsterSkillInfo(dwSkillID)
        nCost = tInfo.nCost or 0
    end
    return nCost
end

function MonsterBookData.GetLevelText(nLevel)
    return FormatString(g_tStrings.MONSTER_BOOK_LEVEL, g_tStrings.STR_NUMBER[nLevel])
end

function MonsterBookData.GetEdgeColorPath(nColor)
    local szPath = EDGE_BAR_FRAME[nColor]
    local szName = EDGE_COLOR_NAME[nColor]
    return szPath, szName
end

function MonsterBookData.GetEdgeFramePath(nColor)
    local szPath = EDGE_COLOR_FRAME[nColor]
    return szPath
end

function MonsterBookData.GetEdgeRoundFramePath(nColor)
    local szPath = EDGE_COLOR_FRAME_ROUND[nColor]
    return szPath
end

function MonsterBookData.IsActiveSkill(dwSkillID)
    local bActive = false
    local tActiveList = MonsterBookData.GetActiveSkillList()
    for _, v in ipairs(tActiveList) do
        if dwSkillID == v then
            bActive = true
            break
        end
    end
    return bActive
end

function MonsterBookData.GetActiveSkillList(dwPlayerID)
    dwPlayerID = dwPlayerID or UI_GetClientPlayerID()
    local player = GetPlayer(dwPlayerID)
    if not player then return end

    local tActiveList = player.GetAllActiveSkillInCollection() or {}
    table.sort(tActiveList, MonsterBookData.SortActiveSkill)
    return tActiveList
end

function MonsterBookData.IsEmptySkill(dwSkillID, tInfo)
    local bEmpty = false
    if not dwSkillID or dwSkillID <= 0 then
        bEmpty = true
    elseif not tInfo or IsEmpty(tInfo) then
        UILog("技能在MonsterSkill.tab里不存在, dwSkillID = " .. dwSkillID)
        bEmpty = true
    elseif tInfo.bDeprecated then
        bEmpty = true
    end
    return bEmpty
end

-- 筛选技能效果/消耗/颜色/重数/传授
function MonsterBookData.GetFiltedList(nType, tSearchFilter, tSkillID, dwPlayerID)
    local pPlayer
    if dwPlayerID then
        pPlayer = GetPlayer(dwPlayerID)
    else
        pPlayer = GetClientPlayer()
    end
    if not pPlayer then
        return
    end
    nType = nType - 1
    local nCost = tSearchFilter[2] - 1 or 0
    local nColor = tSearchFilter[3] - 1 or 0
    local nLevel = tSearchFilter[4] - 1 or 0
    local tSkillLevel = pPlayer.GetAllSkillInCollection()
    local tSkillAll = {}
    if tSkillID then
        for nIndex, dwSkillID in pairs(tSkillID) do
            local tLine = Table_GetMonsterSkillInfo(dwSkillID)
            tLine.nLevel = tSkillLevel[tLine.dwOutSkillID]
            table.insert(tSkillAll, tLine)
        end
    else
        tSkillAll = Table_GetAllMonsterSkill()
        for _, tLine in pairs(tSkillAll) do
            tLine.nLevel = tSkillLevel[tLine.dwOutSkillID]
        end
    end

    local tSkillFilt = {}
    for _, tLine in pairs(tSkillAll) do
        local bAdd = true
        if tLine.bDeprecated
        or (nCost and nCost ~= 0 and nCost ~= tLine.nCost)
        or (nColor and nColor ~= 0 and nColor ~= tLine.nColor)
        or (nLevel and nLevel ~= 0 and nLevel ~= tLine.nLevel)
        then
            bAdd = false
        elseif nType and nType ~= 0 then
            local bSameType = false
            local tType = SplitString(tLine.szType, ";")
            for _, v in ipairs(tType) do
                if tonumber(v) == nType then
                    bSameType = true
                    break
                end
            end
            if bSameType == false then
                bAdd = false
            end
        end
        if bAdd then
            table.insert(tSkillFilt, tLine)
        end
    end
    return tSkillFilt
end

local function MatchString(szSrc, szDst)
    if not szDst then
        return true
    end
	local nPos = string.match(szSrc, szDst)
	if not nPos then
	   return false;
	end

	return true
end

function MonsterBookData.MatchString(szSrc, szDst)
    if not szDst then
        return true
    end
	local nPos = string.match(szSrc, szDst)
	if not nPos then
	   return false;
	end

	return true
end

-- 模糊搜索技能名/boss名
function MonsterBookData.GetSearchList(szSearch, tFiltedList)
    local tFiltedSearchList
    if szSearch == "" then
        tFiltedSearchList = clone(tFiltedList)
    else
        tFiltedSearchList = {}
        for _, tLine in pairs(tFiltedList) do
            if MatchString(tLine.szSkillName, szSearch) then
                table.insert(tFiltedSearchList, tLine)
            else
                if tLine.szBoss then
                    local szBossNameAll = tLine.szBossName
                    local tBossName = SplitString(szBossNameAll, "、")
                    for _, szBossName in pairs(tBossName) do
                        if MatchString(szBossName, szSearch) then
                            table.insert(tFiltedSearchList, tLine)
                        end
                    end
                end
            end
        end
    end
    return tFiltedSearchList
end

function MonsterBookData.SortActiveSkill(dwSkillID1, dwSkillID2)
    -- 追溯基础技能
    local dwCurSkillID = dwSkillID1
    while(dwCurSkillID) do
        dwCurSkillID = MonsterBookData.tSkillStackTrace[dwCurSkillID]
        dwSkillID1 = dwCurSkillID or dwSkillID1
    end
    dwCurSkillID = dwSkillID2
    while(dwCurSkillID) do
        dwCurSkillID = MonsterBookData.tSkillStackTrace[dwCurSkillID]
        dwSkillID2 = dwCurSkillID or dwSkillID2
    end
    -- 里技能换成表技能
    dwSkillID1 = MonsterBookData.tIn2OutSkillMap[dwSkillID1] or dwSkillID1
    dwSkillID2 = MonsterBookData.tIn2OutSkillMap[dwSkillID2] or dwSkillID2

    local nVal1 = MonsterBookData.tCustomData.tActiveSkillTime[dwSkillID1] or 0
    local nVal2 = MonsterBookData.tCustomData.tActiveSkillTime[dwSkillID2] or 0
    return nVal1 < nVal2
end

function MonsterBookData.GetActiveSkillData()
    local tSkillCollected = GetClientPlayer().GetAllSkillInCollection()
    local tActiveList = MonsterBookData.tExtendSkillList
    table.sort(tActiveList, MonsterBookData.SortActiveSkill)
    local tActiveSkillInfoList = {}
    for _, dwSkillID in ipairs(tActiveList) do
        if not DEFAULT_SKILL_MAP[dwSkillID] then
            dwSkillID = MonsterBookData.tOut2InSkillMap[dwSkillID] or dwSkillID
            local dwOutSkillID = MonsterBookData.tIn2OutSkillMap[dwSkillID] or dwSkillID
            local nLevel = tSkillCollected[dwOutSkillID] or 1
            local tSkillInfo = Table_GetMonsterSkillInfo(dwSkillID)
            local tActiveSkillInfo = {
                id = dwSkillID,
                level = nLevel,
                szImgPath = TabHelper.GetSkillIconPathByIDAndLevel(dwSkillID, nLevel),
                szImgFramePath = MonsterBookData.GetEdgeRoundFramePath(tSkillInfo.nColor),
                nSkillSurfaceNum = MonsterBookData.tSkillSurfaceNumMap[dwSkillID] or 0,
            }
            tActiveSkillInfo.callback = function()
                local player = g_pClientPlayer
                if player then
                    SkillData.SetCastPointToTargetPos()
                    local nMask = (dwSkillID * (dwSkillID % 10 + 1))
                    OnUseSkill(dwSkillID, nMask, nil, nil, true)
                end
            end
            table.insert(tActiveSkillInfoList, tActiveSkillInfo)
        end
    end

    return tActiveSkillInfoList
end

function MonsterBookData.GetBossExtraSEInfoList(pPlayer)
    local DataModel = {}
    local nSex = MonsterBookData.GetSex()
    DataModel.tBossID2SkillInfo = Table_GetMonsterSkillBossDic(nSex)
    local tSkillCollected = pPlayer.GetAllSkillInCollection()
    for _, tSkillInfoList in pairs(DataModel.tBossID2SkillInfo) do
        local nMinLevel = MonsterBookData.MAX_SKILL_LEVEL
        for _, tSkillInfo in ipairs(tSkillInfoList) do
            local dwSkillID = tSkillInfo.dwOutSkillID
            local nLevel = tSkillCollected[dwSkillID] or 0
            tSkillInfo.nCurLevel = nLevel
            nMinLevel = math.min(nMinLevel, nLevel)
        end
        tSkillInfoList.nMinLevel = nMinLevel
        tSkillInfoList.nAddOneLevelCount = 0
        for _, tSkillInfo in ipairs(tSkillInfoList) do
            if tSkillInfo.nCurLevel >= tSkillInfoList.nMinLevel + 1 then
                tSkillInfoList.nAddOneLevelCount = tSkillInfoList.nAddOneLevelCount + 1
            end
        end
    end
    DataModel.nSpirit, DataModel.nEndurance = GDAPI_SpiritEndurance_GetMaxValue(pPlayer)
    DataModel.tBookCount = {}
    for k, v in ipairs(tBookIndex) do
        local nCount = pPlayer.GetItemAmountInPackage(ITEM_TABLE_TYPE.OTHER, v)
        DataModel.tBookCount[k] = nCount
    end

    DataModel.tIntroList = Table_GetMonsterBossIntroduceInfo(nSex)
    local tSEInfoList = {}
    for _, tInfo in ipairs(DataModel.tIntroList) do
        local szBossName = UIHelper.GBKToUTF8(tInfo.szName)
        local tSkillInfoList = DataModel.tBossID2SkillInfo[tInfo.dwIndex]
        if not tSkillInfoList then
            tSkillInfoList = {}
            tSkillInfoList.nMinLevel = 0
            tSkillInfoList.nAddOneLevelCount = 0
        end
        local nDstLevel = tSkillInfoList.nMinLevel + 1
        if nDstLevel > MonsterBookData.MAX_SKILL_LEVEL then nDstLevel = MonsterBookData.MAX_SKILL_LEVEL end
        local nExtraSpiritValue, nExtraEnduranceValue = Table_GetMonsterBossSpringEndurance(tInfo.dwIndex, nDstLevel, nSex)
        local tCollectSkill = {}
        for _, tSkillInfo in ipairs(tSkillInfoList) do
            local dwSkillID = tSkillInfo.dwOutSkillID
            local nLevel = tSkillCollected[dwSkillID] or 0
            table.insert(tCollectSkill, {
                dwSkillID = tSkillInfo.dwOutSkillID,
                nLevel = nLevel or 0,
            })
        end
        local szBossNameList = string.split(szBossName, "、")
        szBossName = szBossNameList[1]
        local tSEInfo = {
            dwBossID = tInfo.dwIndex,
            szBossName = szBossName,
            nExtraSpiritValue = nExtraSpiritValue,
            nExtraEnduranceValue = nExtraEnduranceValue,
            nMinLevel = tSkillInfoList.nMinLevel,
            nCurProgress = tSkillInfoList.nAddOneLevelCount,
            nTotalProgress = #tSkillInfoList,
            tCollectSkill = tCollectSkill
        }
        table.insert(tSEInfoList, tSEInfo)
    end

    return tSEInfoList
end

function MonsterBookData.GetSex()
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return false
    end
    local nRoleType = pPlayer.nRoleType
    if nRoleType == ROLE_TYPE.STANDARD_MALE or
    nRoleType == ROLE_TYPE.STRONG_MALE or
    nRoleType == ROLE_TYPE.LITTLE_BOY then
        return 1
    else
        return 2
    end
end

function MonsterBookData.GetChooseSkillList()
    local tChooseSkill = {}
    local player = GetClientPlayer()

    local REMOTE_TOWER_SELFINSIDESKILL = 1098  --玩家个人的内部完整（全部）技能情况（这个是三个技能栏位替换完之后的信息，包括已经换成的外部技能在内的内部技能）！
    local REMOTE_TOWER_SELFINSIDESKILLINFO = {
        --内部技能分配了多少
        NSKILLNUMBER = 0
    }

    ---获取玩家临时技能
    local nInSideSkillNum = player.GetRemoteDWordArray(REMOTE_TOWER_SELFINSIDESKILL, REMOTE_TOWER_SELFINSIDESKILLINFO.NSKILLNUMBER)
    if nInSideSkillNum > 0 then
        for i = 1, nInSideSkillNum do
            local dwSkillID =  player.GetRemoteDWordArray(REMOTE_TOWER_SELFINSIDESKILL, i * 2 - 1)
            if dwSkillID ~= 0 then
                table.insert(tChooseSkill, dwSkillID)
            end
        end
    end

    return tChooseSkill
end

function MonsterBookData.OnMonsterBookSkillChanged(dwOldSkillID, dwNewSkillID, nNewSkillLevel)
    if not MonsterBookData.bIsPlaying then
        return
    end

    -- 变阶段时记录一下单向技能栈，策划许诺不会有交叉使用的技能链
    if not MonsterBookData.tSkillStackTrace[dwNewSkillID] and not DEFAULT_SKILL_MAP[dwOldSkillID] and not DEFAULT_SKILL_MAP[dwNewSkillID] then
        if not MonsterBookData.tSkillStackTrace[dwOldSkillID] or MonsterBookData.tSkillStackTrace[dwOldSkillID] ~= dwNewSkillID then
            MonsterBookData.tSkillStackTrace[dwNewSkillID] = dwOldSkillID
        end
    end

    local bChanged = false
    for i = 1, #MonsterBookData.tExtendSkillList do
        if MonsterBookData.tExtendSkillList[i] == dwOldSkillID then
            MonsterBookData.tExtendSkillList[i] = dwNewSkillID
            bChanged = true
            break
        end
    end
    if bChanged then Event.Dispatch(EventType.OnMonsterBookSkillChanged, dwOldSkillID, dwNewSkillID, nNewSkillLevel) end
end

function MonsterBookData.IsMonsterSkill(dwSkillID)
    local bIsMonsterSkill = DEFAULT_SKILL_MAP[dwSkillID] ~= nil
    bIsMonsterSkill = bIsMonsterSkill or MonsterBookData.tIn2OutSkillMap[dwSkillID] ~= nil
    bIsMonsterSkill = bIsMonsterSkill or MonsterBookData.tOut2InSkillMap[dwSkillID] ~= nil
    bIsMonsterSkill = bIsMonsterSkill or MonsterBookData.tSkillStackTrace[dwSkillID] ~= nil

    return bIsMonsterSkill
end

function MonsterBookData.IsInBaiZhanMap()
    local player = g_pClientPlayer
    if not player then return false end
    local scene = player.GetScene()
    local dwMapID = scene and scene.dwMapID or 0
    return dwMapID == MonsterBookData.PLAY_MAP_ID
end

function MonsterBookData.IsBaiZhanMap(dwMapID)
    return dwMapID == MonsterBookData.PLAY_MAP_ID
end

function MonsterBookData.CheckRemoteRoommateProgress(dwTargetMapID)
    local bRemote = IsRemotePlayer(UI_GetClientPlayerID())
    local bBZTarget = dwTargetMapID and MonsterBookData.IsBaiZhanMap(dwTargetMapID)

    if bRemote and MonsterBookData.IsInBaiZhanMap() then
        UIMgr.Open(VIEW_ID.PanelBossKillProgressPop)
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipMoreOper)
    elseif not bRemote and bBZTarget then
        OutputMessage("MSG_ANNOUNCE_YELLOW", g_tStrings.STR_OPEN_WITH_REMOTE_BAIZHAN)
    else
        UIMgr.Open(VIEW_ID.PanelRoomProgressPop)
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipMoreOper)
    end
end

function MonsterBookData.IsFinishLevelChoosePreQuest()
    local bQuestFinished = QuestData.IsFinished(MonsterBookData.dwLevelChoosePreQuestID1)
    bQuestFinished = bQuestFinished or QuestData.IsFinished(MonsterBookData.dwLevelChoosePreQuestID2)

    return bQuestFinished
end

function MonsterBookData.IsFinishSEInfoPreQuest()
    local bQuestFinished = QuestData.IsFinished(MonsterBookData.dwSEInfoPreQuestID)

    return bQuestFinished
end

function MonsterBookData.GetMonsterBookItemIndex(dwSkillID, nLevel)
    nLevel= nLevel or 1
    for dwItemIndex, tInfo in pairs(MonsterBookData.TABLE_OUT_SKILL_BOOK) do
        if tInfo[1] == dwSkillID and tInfo[2] == nLevel then
            return dwItemIndex
        end
    end
end

function MonsterBookData.IsFreeLevel(nLevel)
    return nLevel <= 50
end

function MonsterBookData.CanUpgradeSkillByItem(dwSkillID, nLevel, item)
    nLevel= nLevel or 1
    for dwItemIndex, tInfo in pairs(MonsterBookData.TABLE_OUT_SKILL_BOOK) do
        if tInfo[1] == dwSkillID and tInfo[2] > nLevel and item.dwIndex == dwItemIndex then
            return true
        end
    end
    return false
end

function MonsterBookData.ConvertSurfaceNumToPercent(nSurceNum)
    local nForceID = g_pClientPlayer and g_pClientPlayer.GetActualKungfuMount().dwSkillID
    if not nForceID then return 0 end

    local ncoefficient = SURFACE_COEFFICIENT[nForceID] or 1

    return nSurceNum / ncoefficient
end

function MonsterBookData.CheckMonsterBookInfo(dwPlayerID, dwCenterID, szGlobalID)
    if dwCenterID and dwCenterID > 0 and szGlobalID then
        tInviteToPlayerBZInfo[szGlobalID] = dwCenterID
        PeekOtherPlayerByGlobalID(dwCenterID, szGlobalID)
	else
        tInviteToPlayerBZInfo[dwPlayerID] = true
		PeekOtherPlayer(dwPlayerID)
    end

end

function MonsterBookData.IsVisible()
    if IsVersionExp() then
        return UI_SWITCH_EXP == true
    elseif IsDebugClient() then
        return UI_SWITCH_DEBUG == true
    else
        return UI_SWITCH == true
    end
end

--获取换将点
function MonsterBookData.GetReplaceRemain()
    local REMOTE_REPLACE_BOSS = 1096

    local hPlayer = GetClientPlayer()
	if not hPlayer then
		return 0
	end
	if not hPlayer.HaveRemoteData(REMOTE_REPLACE_BOSS) then
		return 0
	end
	local nReplaceRemain = hPlayer.GetRemoteDataByte(REMOTE_REPLACE_BOSS)
	if nReplaceRemain < 0 then
		nReplaceRemain = 0
	end
	return nReplaceRemain
end

--替换boss次数上限
function MonsterBookData.GetReplaceTotal()
    return 50
end

Event.Reg(MonsterBookData, "PEEK_OTHER_PLAYER", function (nResult, dwID)
    if nResult == PEEK_OTHER_PLAYER_RESPOND.SUCCESS then
        local hOther = GetPlayer(dwID)
        if not hOther then
            return
        end
        local szGlobalID = hOther.GetGlobalID()
        if tInviteToPlayerBZInfo[szGlobalID] or tInviteToPlayerBZInfo[dwID] then
            local dwCenterID = tInviteToPlayerBZInfo[szGlobalID] or GetCenterID() or 0
            UIMgr.Open(VIEW_ID.PanelBaizhanMain, 2, dwID, dwCenterID, szGlobalID)
            tInviteToPlayerBZInfo[szGlobalID] = nil
            tInviteToPlayerBZInfo[dwID] = nil
        end
    end
end)

Event.Reg(MonsterBookData, EventType.OnClientPlayerEnter, function()
    local player = g_pClientPlayer
    if player then
        if MonsterBookData.szLastPlayerName and MonsterBookData.szLastPlayerName ~= player.szName then
            MonsterBookData.UnInit()
            MonsterBookData.Init()
        end
        MonsterBookData.TryLoadCustomData()
        MonsterBookData.szLastPlayerName = player.szName
        local scene = player.GetScene()
        local dwMapID = scene and scene.dwMapID or 0
        local bPlaying = dwMapID == MonsterBookData.PLAY_MAP_ID

        if bPlaying then
            Timer.Add(MonsterBookData, 1, function ()
                Event.Dispatch(EventType.OnEnterMonsterBookScene)
            end)
        elseif MonsterBookData.bIsPlaying then -- 退出的时候清理一下数据
            MonsterBookData.tExtendSkillList = {28202, 28212, 28213}
            Event.Dispatch(EventType.OnExitMonsterBookScene)
        end
        MonsterBookData.bIsPlaying = bPlaying
        MonsterBookData.tLastSpiritValueMap = {}
        MonsterBookData.tLastEnduranceValueMap = {}
    end
end)

Event.Reg(MonsterBookData, EventType.OnViewClose, function (nViewID)
    if not g_pClientPlayer then return end
    local scene = g_pClientPlayer.GetScene()
    local dwMapID = scene and scene.dwMapID or 0
    local bPlaying = dwMapID == MonsterBookData.PLAY_MAP_ID
    if nViewID == VIEW_ID.PanelLoading then
        if bPlaying and not Storage.MonsterBook.bHasFirstEnterScene then
            Storage.MonsterBook.bHasFirstEnterScene = true
            UIMgr.Open(VIEW_ID.PanelTutorialLite, 60)
        end
        if not g_pClientPlayer.HaveRemoteData(MonsterBookData.REMOTE_SCHEME_DATA_ID) then
            g_pClientPlayer.ApplyRemoteData(MonsterBookData.REMOTE_SCHEME_DATA_ID)
        end
    end
end)

Event.Reg(MonsterBookData, "CHANGE_SKILL_ICON", function (dwOldSkillID, dwNewSkillID, dwBuffID, dwBuffLevel)
    MonsterBookData.OnMonsterBookSkillChanged(dwOldSkillID, dwNewSkillID)
end)

Event.Reg(MonsterBookData, "ON_SKILL_REPLACE", function (dwOldSkillID, dwNewSkillID, nNewSkillLevel, dwOrgSkillID)
    MonsterBookData.OnMonsterBookSkillChanged(dwOldSkillID, dwNewSkillID, nNewSkillLevel)
end)

Event.Reg(MonsterBookData, "CHANGE_SKILL_SURFACE_NUM", function (dwSkillID, nNum)
    if not MonsterBookData.bIsPlaying then
        return
    end
    MonsterBookData.tSkillSurfaceNumMap[dwSkillID] = nNum
    if MonsterBookData.IsMonsterSkill(dwSkillID) then Event.Dispatch(EventType.OnMonsterBookSkillSurfaceNumChanged, dwSkillID, nNum) end
end)

Event.Reg(MonsterBookData, EventType.OnRoleLogin, function ()
    MonsterBookData.Init()
end)

Event.Reg(MonsterBookData, EventType.OnViewOpen, function (nViewID)
    if not MonsterBookData.tCustomData then return end
    if nViewID == VIEW_ID.PanelBZTransSkill and not MonsterBookData.tCustomData.bHasFirstTransSkill then
        MonsterBookData.tCustomData.bHasFirstTransSkill = true
        Timer.AddFrame(MonsterBookData, 1, function () -- 技能没有加载出来，测试要求截屏要显示已加载的技能
            UIMgr.Open(VIEW_ID.PanelTutorialLite, 44)
        end)
    end

    if nViewID == VIEW_ID.PanelLevelChoose and not MonsterBookData.tCustomData.bHasFirstLevelChoose then
        MonsterBookData.tCustomData.bHasFirstLevelChoose = true
        UIMgr.Open(VIEW_ID.PanelTutorialLite, 39)
    end
end)
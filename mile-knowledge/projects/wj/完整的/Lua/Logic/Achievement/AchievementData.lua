AchievementData                                                = AchievementData or {}

-- ----------------------------------------------------------
-- 这部分是从端游复制过来的代码，仅做微调，为了方便维护，单独放在这个位置
-- ----------------------------------------------------------
--- 从服务器请求的排行数据缓存
AchievementData.aRanking                                       = {}

--- 从服务器请求的密档数据缓存
AchievementData.tReportInfo                                    = nil

--- 成就奖励列表
AchievementData.tGiftList                                      = {}
--- 奖励类别列表
AchievementData.tGiftType                                      = {}
--- 资历奖励列表
AchievementData.tPointAward                                    = {}

--- 成就树
AchievementData.tTree                                          = {}

---@class AchievementFilterData 成就筛选数据
---@field dwAchievementID number | nil 仅显示指定成就
---
---@field szAAchiKey string 过滤成就完成情况（all/finish/unfinish）
---@field szTRAchiKey string 过滤五甲完成情况（all/finish/unfinish）
---
---@field szAKey string 搜索条件：成就名称的关键词
---@field m_dwADLCID number | nil 搜索条件：资料片DLC id
---@field m_dwASceneID number | nil 搜索条件：场景id，对应成就配置表中的 szSceneID 场景列表 字段
---@field m_dwASceneName string 搜索条件：在筛选时选择的场景id对应的名称，因为一个场景可能对应多个名称，这里保存下用户实际选择的名称，用来展示在输入框中
---@field m_dwAMapID number | nil 搜索条件：地图id，对应成就配置表中的 dwMapID 目标地图 字段
---@field m_bDLCOther boolean | nil 搜索条件：是否是其他资料片DLC

---筛选相关的数据 - 菜单界面打开的成就界面，希望本地记录玩家的筛选，不重置
---@type AchievementFilterData
AchievementData.tFilterData = {}
---筛选相关的数据 - 其他不同途径的成就跳转，希望定向跳转对应成就，每次重置，但不影响本地记录玩家的筛选
---@type AchievementFilterData
AchievementData.tFilterDataFromOtherSystem = {}

--- 是否是从其他系统跳转到成就界面来的，用来判断使用哪份筛选数据
AchievementData.bJumpFromOtherSystem = false

function AchievementData.SetJumpFromOtherSystem(bJumpFromOtherSystem, bDoNotResetFilterData)
    AchievementData.bJumpFromOtherSystem = bJumpFromOtherSystem

    if bJumpFromOtherSystem and not bDoNotResetFilterData then
        AchievementData.InitFilterData(AchievementData.tFilterDataFromOtherSystem)
    end
end

---@param tData AchievementFilterData
function AchievementData.InitFilterData(tData)
    tData.dwAchievementID = nil
    
    tData.szAAchiKey = "all"
    tData.szTRAchiKey = "all"
    
    tData.szAKey = ""
    tData.m_dwADLCID = nil
    tData.m_dwASceneID = nil
    tData.m_dwASceneName = ""
    tData.m_dwAMapID = nil
    tData.m_bDLCOther = nil
end

---@return AchievementFilterData
function AchievementData.GetFilterData()
    if AchievementData.bJumpFromOtherSystem then
        return AchievementData.tFilterDataFromOtherSystem
    else
        return AchievementData.tFilterData
    end
end

function AchievementData.SetFilterData_dwAchievementID(dwAchievementID)
    local tData = AchievementData.GetFilterData()
    
    tData.dwAchievementID = dwAchievementID
end

function AchievementData.SetFilterData_szAAchiKey(szAAchiKey)
    local tData = AchievementData.GetFilterData()

    tData.szAAchiKey = szAAchiKey
end

function AchievementData.SetFilterData_szTRAchiKey(szTRAchiKey)
    local tData = AchievementData.GetFilterData()

    tData.szTRAchiKey = szTRAchiKey
end

function AchievementData.SetFilterData_szAKey(szAKey)
    local tData = AchievementData.GetFilterData()

    tData.szAKey = szAKey
end

function AchievementData.SetFilterData_m_dwADLCID(m_dwADLCID)
    local tData = AchievementData.GetFilterData()

    tData.m_dwADLCID = m_dwADLCID
end

--- 设置筛选项的场景ID和名称，若名称未传入，则根据中地图表（Table_GetMiddleMap）去获取第一个名称
function AchievementData.SetFilterData_m_dwASceneID_And_m_dwASceneName(m_dwASceneID, m_dwASceneName)
    local tData = AchievementData.GetFilterData()

    if m_dwASceneName == nil then
        m_dwASceneName = AchievementData.GetMiddleMapFirstName(m_dwASceneID)
    end

    tData.m_dwASceneID = m_dwASceneID
    tData.m_dwASceneName = m_dwASceneName
end

function AchievementData.GetMiddleMapFirstName(dwMapID)
    local szSceneName = ""
    
    local tMapNameList = Table_GetMiddleMap(dwMapID)
    if table.get_len(tMapNameList) then
        szSceneName = UIHelper.GBKToUTF8(tMapNameList[1])
    end
    
    return szSceneName
end

function AchievementData.SetFilterData_m_dwAMapID(m_dwAMapID)
    local tData = AchievementData.GetFilterData()

    tData.m_dwAMapID = m_dwAMapID
end

function AchievementData.SetFilterData_m_bDLCOther(m_bDLCOther)
    local tData = AchievementData.GetFilterData()

    tData.m_bDLCOther = m_bDLCOther
end

--- 成就筛选枚举-获得情况 str => str
AchievementData.FILTER_TYPE_FINISHED_STATUS_NAME_TO_ENUM_VALUE = {
    ["全部显示"] = "all",
    ["已达成"] = "finish",
    ["未达成"] = "unfinish",
}
--- 因为map不能按顺序遍历key，这里指定展示的顺序
AchievementData.FILTER_TYPE_FINISHED_STATUS_NAME_LIST          = {
    "全部显示",
    "已达成",
    "未达成",
}

--- 成就筛选枚举-资料片DLC str => int，会在后面流程动态加载，可使用 GetDlcNameToIdMap()来获取
AchievementData.FILTER_TYPE_DLC_NAME_TO_ID                     = {
}
--- 因为map不能按顺序遍历key，这里指定展示的顺序，会在后面流程动态加载，可使用 GetDlcNameList()来获取
AchievementData.FILTER_TYPE_DLC_NAME_LIST                      = {
}

--- 搜索条件：奖励类别
AchievementData.nGiftType                                      = nil
--- 搜索条件：奖励名称的关键词
AchievementData.szGiftKey                                      = ""

--- 奖励过滤条件枚举
AchievementData.GIFT_FILTER_TYPE                               = {
    All = 0, -- 全部显示
    Collected = 1, -- 已收集
    NotCollected = 2, -- 未收集
}

-- 奖励过滤条件 - 获得情况，具体值为 GIFT_FILTER_TYPE
AchievementData.tGiftFilterCollectStatus                       = { AchievementData.GIFT_FILTER_TYPE.All }
-- 奖励过滤条件 - 物品类型，具体值为 AchievementData.tGiftType 中元素的 nSub 字段值，其中全部使用 "all" 表示
AchievementData.tGiftFilterGiftType                            = { "all" }

---@type RegionMapInfo[]
--- 区域列表
AchievementData.m_tRegionList			= {}
---@type table<number, RegionMapListInfo>
--- 区域ID => 区域内的地图信息，列表元素为普通地图，tRaid和tDungeon为副本元素的列表
AchievementData.m_tMapRegion 			= {}


function AchievementData.Init()
    AchievementData.InitAllGift()
    AchievementData.InitMapFilterData()
    
    AchievementData.ResetGiftSearchAndFilter()
    
    AchievementData.InitFilterData(AchievementData.tFilterData)

    AchievementData.RegEvent()
end

function AchievementData.UnInit()

end

function AchievementData.RegEvent()
    Event.Reg(AchievementData, EventType.OnRoleLogin, function()
        AchievementData.ResetGiftSearchAndFilter()
        
        AchievementData.InitFilterData(AchievementData.tFilterData)
    end)
end


function AchievementData.ResetGiftSearchAndFilter()
    AchievementData.nGiftType                = nil
    AchievementData.szGiftKey                = ""
    AchievementData.tGiftFilterCollectStatus = { AchievementData.GIFT_FILTER_TYPE.All }
    AchievementData.tGiftFilterGiftType      = { "all" }
end

function AchievementData.HasFilter(nPanelType)
    local bHasFilter = false
    
    -- 获得情况
    if (nPanelType == ACHIEVEMENT_PANEL_TYPE.ACHIEVEMENT and AchievementData.GetFilterData().szAAchiKey ~= "all") or
            (nPanelType == ACHIEVEMENT_PANEL_TYPE.TOP_RECORD and AchievementData.GetFilterData().szTRAchiKey ~= "all")
    then
        bHasFilter = true
    end
    
    -- 版本
    if AchievementData.GetFilterData().m_dwADLCID ~= nil and not AchievementData.bJumpFromOtherSystem then
        bHasFilter = true
    end
    
    return bHasFilter
end

function AchievementData.GetNSub(itemInfo)
    local nSub, szText
    if itemInfo.nGenre == ITEM_GENRE.EQUIPMENT then
        nSub   = itemInfo.nSub
        szText = g_tStrings.tEquipTypeNameTable[itemInfo.nSub]
    elseif itemInfo.nGenre == ITEM_GENRE.BOX then
        nSub   = -1
        szText = g_tStrings.ITEM_TREASURE_BOX
    elseif itemInfo.nGenre == ITEM_GENRE.HOMELAND then
        nSub   = -2
        szText = g_tStrings.STR_REPUTATION_REWARD_ITEM_TYPE_HOMELAND
    else
        nSub   = -3
        szText = g_tStrings.STR_INTERESTING_ITEM
    end
    return nSub, szText
end

--根据关键字来筛选奖励
function AchievementData.SearchGift()
    local tSearchGift = {}
    for k, v in pairs(AchievementData.tGiftList) do
        local aAchievement = Table_GetAchievement(v.dwAchievement)
        local itemInfo     = GetItemInfo(aAchievement.dwItemType, aAchievement.dwItemID)
        local nSub         = AchievementData.GetNSub(itemInfo)
        local bTypeMatch   = false
        local bKeyMatch    = false

        if not AchievementData.nGiftType or AchievementData.nGiftType == nSub then
            bTypeMatch = true
        end

        local szItemName = UIHelper.GBKToUTF8(ItemData.GetItemNameByItemInfo(itemInfo, 1))
        if not AchievementData.szGiftKey or AchievementData.szGiftKey == "" or string.find(szItemName, AchievementData.szGiftKey) then
            bKeyMatch = true
        end

        if bTypeMatch and bKeyMatch then
            table.insert(tSearchGift, v)
        end
    end
    return tSearchGift
end

function AchievementData.AddGiftType(dwItemType, dwItemID)
    local itemInfo     = GetItemInfo(dwItemType, dwItemID)
    local nSub, szText = AchievementData.GetNSub(itemInfo)

    local bFind        = false
    for i, k in ipairs(AchievementData.tGiftType) do
        if k.szText == szText then
            bFind = true
            break
        end
    end
    if not bFind then
        local tList  = {}
        tList.nSub   = nSub
        tList.szText = szText
        table.insert(AchievementData.tGiftType, tList)
    end
end

function AchievementData.GetGift(dwAchievement, aAchievement, dwSub, dwDetail)
    if not aAchievement then
        return
    end
    local dwItemType = aAchievement.dwItemType
    local dwItemID   = aAchievement.dwItemID
    if dwItemType > 0 and dwItemID > 0 then
        local tList         = {}
        tList.dwSub         = dwSub
        tList.dwDetail      = dwDetail
        tList.dwAchievement = dwAchievement
        tList.dwItemType    = dwItemType
        tList.dwItemID      = dwItemID
        AchievementData.AddGiftType(dwItemType, dwItemID)
        return tList
    end
end

function AchievementData.AddGift(szAchievements, dwSub, dwDetail)
    for s in string.gmatch(szAchievements, "%d+") do
        local dwAchievement = tonumber(s)
        local aAchievement  = Table_GetAchievement(dwAchievement)
        local tList         = AchievementData.GetGift(dwAchievement, aAchievement, dwSub, dwDetail)
        if tList then
            table.insert(AchievementData.tGiftList, tList)
        end
        if aAchievement.szSeries then
            local tList = SplitString(aAchievement.szSeries, "|")
            for i = 2, #tList do
                local dwAchievement = tonumber(tList[i])
                local aAchievement  = Table_GetAchievement(dwAchievement)
                local tList         = AchievementData.GetGift(dwAchievement, aAchievement, dwSub, dwDetail)
                if tList then
                    table.insert(AchievementData.tGiftList, tList)
                end
            end
        end
    end
end

function AchievementData.InitAllGift()
    if #AchievementData.tGiftList > 0 then
        return
    end
    local aGeneral = g_tTable.AchievementGeneral:Search(1)
    local szSubs   = aGeneral.szSubs
    for s1 in string.gmatch(szSubs, "%d+") do
        local dwSub = tonumber(s1)
        local aSub  = g_tTable.AchievementSub:Search(dwSub)
        if aSub then
            local szDetails = aSub.szDetails
            local i         = 0
            for s2 in string.gmatch(szDetails, "%d+") do
                local dwDetail = tonumber(s2)
                local aDetail  = g_tTable.AchievementDetail:Search(dwDetail)
                AchievementData.AddGift(aDetail.szAchievements, dwSub, dwDetail)
            end

            AchievementData.AddGift(aSub.szAchievements, dwSub, nil)
        end
    end
end

function AchievementData.InitMapFilterData()
    if table.get_len(AchievementData.m_tRegionList) == 0 then
        AchievementData.m_tRegionList = WorldMap_GetRegionOfWorldmap()
    end
    if table.get_len(AchievementData.m_tMapRegion) == 0 then
        AchievementData.m_tMapRegion = Table_GetMapRegion()
    end
end

function AchievementData.IsAchievementAcquired(dwAchievement, aAchievement, dwPlayerID, bDoNotIncludeSeries)
    local hPlayer = GetClientPlayer()
    if dwPlayerID then
        hPlayer = GetPlayer(dwPlayerID)
    end

    if not hPlayer then
        return
    end

    local bMyselfFinish = hPlayer.IsAchievementAcquired(dwAchievement)
    if bMyselfFinish then
        if not bDoNotIncludeSeries and aAchievement then
            -- 同时检查系列成就
            local szSeries = aAchievement.szSeries or ""
            local tList    = SplitString(szSeries, "|")
            for _, k in ipairs(tList or {}) do
                local dwSeriesA = tonumber(k)
                local bFinish   = hPlayer.IsAchievementAcquired(dwSeriesA)
                if not bFinish then
                    return false
                end
            end
        end

        return true
    else
        return false
    end
end

function AchievementData.GetCurrentStageSeriesAchievementID(dwSeriesAchievement, dwPlayerID)
    local aSeriesAchievement       = Table_GetAchievement(dwSeriesAchievement)

    local tSeriesAchievementIDList = {}
    for s in string.gmatch(aSeriesAchievement.szSeries, "%d+") do
        local dwAchievement = tonumber(s)

        table.insert(tSeriesAchievementIDList, dwAchievement)
    end

    -- 保底返回系列成就的主成就
    local dwCurrentAchievement = dwSeriesAchievement

    for idx, dwAchievement in ipairs(tSeriesAchievementIDList) do
        local aAchievement = Table_GetAchievement(dwAchievement)
        local bFinish      = AchievementData.IsAchievementAcquired(dwAchievement, aAchievement, dwPlayerID, true)

        if not bFinish or idx == #tSeriesAchievementIDList then
            -- 返回第一个未完成的系列成就ID，或者全部已完成时返回最后一个成就ID
            dwCurrentAchievement = dwAchievement
            break
        end
    end

    return dwCurrentAchievement
end

function AchievementData.IsSameAchievementOrSeries(dwAchievement, dwAchievementToCompare)
    -- 检查 dwAchievement 是否是 dwAchievementToCompare本身，或者其系列任务之一
    if dwAchievement == dwAchievementToCompare then
        return true
    end

    local aAchievementToCompare = Table_GetAchievement(dwAchievementToCompare)
    for s in string.gmatch(aAchievementToCompare.szSeries, "%d+") do
        local dwSeriesAchievement = tonumber(s)

        if dwAchievement == dwSeriesAchievement then
            return true
        end
    end

    return false
end

function AchievementData.GetAchievementFinishCount(tAchievements, dwPlayerID, dwDLCID, szFinishStatus, dwSceneID, nCategoryType)
    local player                     = GetClientPlayer()
    local nCount, nFinish, nDLCCount = 0, 0, 0

    for i, s in ipairs(tAchievements) do
        local dwAchievement             = tonumber(s)
        local aAchievement              = Table_GetAchievement(dwAchievement)
        local bFinish                   = AchievementData.IsAchievementAcquired(dwAchievement, aAchievement, dwPlayerID)

        local bMatchCategory            = aAchievement.dwGeneral == ACHIEVEMENT_PANEL_TYPE.ACHIEVEMENT and aAchievement.dwSub == nCategoryType
        local bTopRecordShowAllCategory = aAchievement.dwGeneral == ACHIEVEMENT_PANEL_TYPE.TOP_RECORD and nCategoryType == ACHIEVEMENT_CATEGORY_TYPE.SHOW_ALL

        -- note: 端游成就的地图筛选是基于 szSceneID 这个配置项来判断，而不是 dwMapID 字段，这里与其保持一致
        local bMatchFilter              = (not dwDLCID or aAchievement.dwDLCID == dwDLCID)
                and (not ((szFinishStatus == "finish" and not bFinish) or (szFinishStatus == "unfinish" and bFinish)))
                and (not dwSceneID or AchievementData.InScenes(aAchievement.szSceneID, dwSceneID))
                and (not nCategoryType or (bMatchCategory or bTopRecordShowAllCategory))

        if bFinish and bMatchFilter then
            nFinish = nFinish + 1
        end

        nCount = nCount + 1
        if bMatchFilter then
            nDLCCount = nDLCCount + 1
        end
    end
    return nCount, nFinish, nDLCCount
end

--- 获得成就对应计数器值已完成数
function AchievementData.GetAchievementCount(dwCounterID)
    if not AchievementData.aDepend then
        AchievementData.aDepend = GetAchievementShiftTable()
    end

    local player = GetClientPlayer()
    local nCount = player.GetAchievementCount(dwCounterID)
    if not nCount or nCount == 0 then
        local dwDepend = AchievementData.aDepend[dwCounterID]
        while dwDepend do
            nCount = player.GetAchievementCount(dwDepend)
            if nCount and nCount ~= 0 then
                break
            end
            dwDepend = AchievementData.aDepend[dwDepend]
        end
    end
    return nCount or 0
end

function AchievementData.GetALLCount(dwGeneral, dwPlayerID, dwDLCID, szFinishStatus, dwMapID, nCategoryType)
    local aGeneral                            = g_tTable.AchievementGeneral:Search(dwGeneral)
    local szSubs                              = aGeneral.szSubs
    local nAllCount, nAllFinish, nAllDLCCount = 0, 0, 0
    for s in string.gmatch(szSubs, "%d+") do
        local dwSub = tonumber(s)
        local aSub  = g_tTable.AchievementSub:Search(dwSub)
        if aSub then
            local nCount, nFinish, nDLCCount = 0, 0, 0
            local szAchievements             = aSub.szAchievements
            local tAchievements              = SplitString(szAchievements, "|")
            nCount, nFinish, nDLCCount       = AchievementData.GetAchievementFinishCount(tAchievements, dwPlayerID, dwDLCID, szFinishStatus, dwMapID, nCategoryType)

            local i                          = 0
            local szDetails                  = aSub.szDetails
            for s in string.gmatch(szDetails, "%d+") do
                local dwDetail = tonumber(s)
                local aDetail  = g_tTable.AchievementDetail:Search(dwDetail)
                if aDetail then
                    local nC, nF, nDLCC        = 0, 0, 0
                    local szAchievements       = aDetail.szAchievements
                    local tAchievements        = SplitString(szAchievements, "|")
                    nC, nF, nDLCC              = AchievementData.GetAchievementFinishCount(tAchievements, dwPlayerID, dwDLCID, szFinishStatus, dwMapID, nCategoryType)
                    nCount, nFinish, nDLCCount = nCount + nC, nFinish + nF, nDLCCount + nDLCC
                end
            end
            nAllCount, nAllFinish, nAllDLCCount = nCount + nAllCount, nFinish + nAllFinish, nAllDLCCount + nDLCCount
        end
    end

    return nAllCount, nAllFinish, nAllDLCCount
end

function AchievementData.ReadPointAward()
    if #AchievementData.tPointAward > 0 then
        return
    end
    local nCount = g_tTable.AchievementProgress:GetRowCount()
    for i = 2, nCount do
        local tLine = g_tTable.AchievementProgress:GetRow(i)
        table.insert(AchievementData.tPointAward, tLine)
    end
end

--- 返回下一阶段的点数，若无更高阶段则返回nil
function AchievementData.GetNextStagePoint(nAllPoint)
    if #AchievementData.tPointAward <= 0 then
        AchievementData.ReadPointAward()
    end

    for i, tLine in ipairs(AchievementData.tPointAward) do
        if tLine.nTop > nAllPoint then
            -- 找到了第一个大于当前进度的阶段
            return tLine.nTop
        end
    end

    -- 没有更高的阶段了
    return nil
end

function AchievementData.GetCurrentStagePointAward(nAllPoint)
    return Table_FindAchievementProgress(nAllPoint)
end

function AchievementData.ReadTable()
    -- note: 为了方便后续界面中使用，下面会预先将一些包含中文的字符串转换为utf-8
    for i = 1, 2 do
        local aGeneral     = g_tTable.AchievementGeneral:Search(i)
        local tGeneral     = {}
        local szSubs       = aGeneral.szSubs
        tGeneral.dwGeneral = i
        tGeneral.szSubs    = szSubs
        tGeneral.aGeneral  = aGeneral
        for s in string.gmatch(szSubs, "%d+") do
            local tSub  = {}
            local dwSub = tonumber(s)
            local aSub  = g_tTable.AchievementSub:Search(dwSub)
            if aSub then
                local szDetails     = aSub.szDetails
                tSub.dwSub          = dwSub
                tSub.szAchievements = aSub.szAchievements or ""
                tSub.szDetails      = szDetails
                tSub.szName         = aSub.szName
                tSub.aSub           = aSub

                for s in string.gmatch(szDetails, "%d+") do
                    local tDetails = {}
                    local dwDetail = tonumber(s)
                    local aDetail  = g_tTable.AchievementDetail:Search(dwDetail)
                    if aDetail then
                        tDetails.dwDetail       = dwDetail
                        tDetails.szAchievements = aDetail.szAchievements or ""
                        tDetails.szName         = aDetail.szName
                        tDetails.aDetail        = aDetail

                        tDetails.szName         = UIHelper.GBKToUTF8(tDetails.szName)
                        table.insert(tSub, tDetails)
                    end
                end

                if aSub.szAchievements ~= "" then
                    -- 为了在bd版本的交互页面中展示，这里将大类别直属的成就也视作一组特殊的子类别，而不是像端游一样单独放在外面
                    local tDirectSubCategory          = {}
                    -- 无具体子类别的成就，在成就配置表中的子类别id为0，这里与其保持一致，方便后面筛选时条件匹配
                    tDirectSubCategory.dwDetail       = 0
                    tDirectSubCategory.szAchievements = aSub.szAchievements or ""
                    tDirectSubCategory.szName         = "其他"
                    tDirectSubCategory.aDetail        = nil
                    table.insert(tSub, tDirectSubCategory)
                end

                tSub.szName = UIHelper.GBKToUTF8(tSub.szName)
                table.insert(tGeneral, tSub)
            end
        end

        tGeneral.szName          = UIHelper.GBKToUTF8(tGeneral.szName)
        AchievementData.tTree[i] = tGeneral
    end
end

function AchievementData.GetIDs(szAchievements, szSearchKey, dwDLCID, dwMapID, bDLCOther, dwSceneID, szFilter, dwPlayerID)
    local tAchievements = {}
    for s in string.gmatch(szAchievements, "%d+") do
        local dwAchievement = tonumber(s)
        local aAchievement  = Table_GetAchievement(dwAchievement)
        local bFinish       = AchievementData.IsAchievementAcquired(dwAchievement, aAchievement, dwPlayerID)
        local szSeries      = aAchievement.szSeries
        local bFind         = false
        for s1 in string.gmatch(szSeries, "%d+") do
            local dwAchievement1 = tonumber(s1)
            local tLine          = Table_GetAchievement(dwAchievement1)
            local bFinish1       = AchievementData.IsAchievementAcquired(dwAchievement1, tLine, dwPlayerID)
            if (not szSearchKey or szSearchKey == "" or AchievementData.FindKey(dwAchievement1, szSearchKey))
                    and (not dwDLCID or tLine.dwDLCID == dwDLCID)
                    and (not dwMapID or tLine.dwMapID == dwMapID)
                    and (bDLCOther == nil or tLine.bDLCOther == bDLCOther)
                    and (not dwSceneID or AchievementData.InScenes(tLine.szSceneID, dwSceneID))
                    and (not ((szFilter == "finish" and not bFinish1) or (szFilter == "unfinish" and bFinish1)))
                    and (not AchievementData.GetFilterData().dwAchievementID or dwAchievement1 == AchievementData.GetFilterData().dwAchievementID) then
                bFind = true
                break
            end
        end
        if bFind or ((not szSearchKey or szSearchKey == "" or AchievementData.FindKey(dwAchievement, szSearchKey, aAchievement))
                and (not dwDLCID or aAchievement.dwDLCID == dwDLCID)
                and (not dwMapID or aAchievement.dwMapID == dwMapID)
                and (bDLCOther == nil or aAchievement.bDLCOther == bDLCOther)
                and (not dwSceneID or AchievementData.InScenes(aAchievement.szSceneID, dwSceneID)))
                and (not ((szFilter == "finish" and not bFinish) or (szFilter == "unfinish" and bFinish)))
                and (not AchievementData.GetFilterData().dwAchievementID or dwAchievement == AchievementData.GetFilterData().dwAchievementID) then
            table.insert(tAchievements, dwAchievement)
        end
    end
    return tAchievements
end

function AchievementData.FindKey(dwAchievement, szSearchKey, aAchievement)
    aAchievement = aAchievement or Table_GetAchievement(dwAchievement)
    local szName = UIHelper.GBKToUTF8(aAchievement.szName)
    local szDesc = UIHelper.GBKToUTF8(aAchievement.szDesc)
    if string.find(szName, szSearchKey)
            or string.find(szDesc, szSearchKey) then
        return true
    end
end

function AchievementData.InScenes(szSceneID, dwMapID)
    if not szSceneID or szSceneID == "" then
        return
    end
    local tSceneID = SplitString(szSceneID, "|")
    for j = 1, #tSceneID do
        if tonumber(tSceneID[j]) == dwMapID then
            return true
        end
    end
end

---TraverseTree
---@param nAchievementPanelType number 当前的成就类别（成就/五甲）
---@param fnGeneralCallback function 参数为：dwGeneral, nAllCount, nAllFinish
---@param fnCategoryCallback function 参数为：dwGeneral, tCategory, tCategoryAchievementIDList, nCategoryCount, nCategoryFinish
---@param fnSubCategoryCallback function 参数为：dwGeneral, tCategory, tSubCategory, tSubCategoryAchievementIDList, nSubCategoryCount, nSubCategoryFinish
---
--- tCategory格式
---     dwSub           类别ID                1
---     szName          类别名称            "杂闻"
---     szAchievements  直属于大类的成就列表  "1|2|3"
---     szDetails       子类别ID列表         "1|2|3"
---     aSub            原始读表信息          AchievementSub
---     数字索引则为各个子类别的信息
---
--- tSubCategory格式
---     dwDetail        子类别ID               1
---     szName          子类别名称           "阅历"
---     szAchievements  子类别的成就列表       "1|2|3"
---     aDetail         原始读表信息          AchievementDetail
function AchievementData.TraverseTree(nAchievementPanelType, fnGeneralCallback, fnCategoryCallback, fnSubCategoryCallback, dwPlayerID, fnCustomFilterDataCallback)
    AchievementData.EnsureTreeLoaded()

    if fnCustomFilterDataCallback then
        AchievementData.SetJumpFromOtherSystem(true)
        fnCustomFilterDataCallback()
    end

    local dwGeneral, fnGetIDs, tGeneral, dwDLCID, dwSceneID, dwMapID, bDLCOther, szSearchKey
    -- 这里与端游不同，端游中完成状态不影响类别，只影响最终展示的成就。bd版会同时影响类别部分
    local szFilter

    dwGeneral   = nAchievementPanelType
    szSearchKey = AchievementData.GetFilterData().szAKey
    fnGetIDs    = AchievementData.GetIDs
    tGeneral    = AchievementData.tTree[dwGeneral]
    dwDLCID     = AchievementData.GetFilterData().m_dwADLCID
    dwSceneID   = AchievementData.GetFilterData().m_dwASceneID
    dwMapID     = AchievementData.GetFilterData().m_dwAMapID
    bDLCOther   = AchievementData.GetFilterData().m_bDLCOther

    if nAchievementPanelType == ACHIEVEMENT_PANEL_TYPE.ACHIEVEMENT then
        szFilter = AchievementData.GetFilterData().szAAchiKey
    else
        szFilter = AchievementData.GetFilterData().szTRAchiKey
    end

    local nAllCount, nAllFinish = 0, 0
    for _, s1 in ipairs(tGeneral) do
        local tCategory                       = s1
        local bMatch                          = false

        local nCategoryCount, nCategoryFinish = 0, 0

        -- note: 类别直属的类别在构建这里遍历的成就树时，作为一个特殊的子类别来添加了，这里就不用再次处理了
        --local tCategoryAchievementIDList = fnGetIDs(tCategory.szAchievements, szSearchKey, dwDLCID, dwMapID, bDLCOther, dwSceneID, szFilter)
        --if tCategoryAchievementIDList and #tCategoryAchievementIDList > 0 then
        --    bMatch = true
        --end
        --
        ---- 部分成就会直属于一个大类别，与各个子类别中的成就合起来就是这个大类别的所有成就
        --nCategoryCount, nCategoryFinish = AchievementData.GetAchievementFinishCount(tCategoryAchievementIDList)

        local bSonClass                       = false
        for _, s2 in ipairs(tCategory) do
            local tSubCategory                  = s2
            local tSubCategoryAchievementIDList = fnGetIDs(tSubCategory.szAchievements, szSearchKey, dwDLCID, dwMapID, bDLCOther, dwSceneID, szFilter, dwPlayerID)

            if tSubCategoryAchievementIDList and #tSubCategoryAchievementIDList > 0 then
                bSonClass                                   = true

                -- 这里是各个子类别的进度信息
                local nSubCategoryCount, nSubCategoryFinish = AchievementData.GetAchievementFinishCount(tSubCategoryAchievementIDList, dwPlayerID)
                if fnSubCategoryCallback then
                    fnSubCategoryCallback(dwGeneral, tCategory, tSubCategory, tSubCategoryAchievementIDList, nSubCategoryCount, nSubCategoryFinish)
                end

                -- 更新大类别的进度
                nCategoryCount, nCategoryFinish = nCategoryCount + nSubCategoryCount, nCategoryFinish + nSubCategoryFinish
            end
        end
        if bSonClass then
            bMatch = true
        end
        if bMatch then
            if fnCategoryCallback then
                fnCategoryCallback(dwGeneral, tCategory, tCategoryAchievementIDList, nCategoryCount, nCategoryFinish)
            end

            -- 更新全部成就的进度
            nAllCount, nAllFinish = nCategoryCount + nAllCount, nCategoryFinish + nAllFinish
        end
    end

    if fnGeneralCallback then
        fnGeneralCallback(dwGeneral, nAllCount, nAllFinish)
    end
end

function AchievementData.EnsureTreeLoaded()
    if #AchievementData.tTree == 0 then
        AchievementData.ReadTable()
    end
end

---GetAchievementCountInfo
---@param szCounters string
---@return1
---@return boolean, number, number 是否找到，当前进度，最大进度
function AchievementData.GetAchievementCountInfo(szCounters)
    if not szCounters or szCounters == "" then
        return false, 0, 0
    end

    --取第一个
    local tList     = SplitString(szCounters, "|")
    local dwCounter = tonumber(tList[1])
    local aCounter  = g_tTable.AchievementCounter:Search(dwCounter)

    local bShow     = false
    local nC        = 0
    local nCMax     = 0
    if aCounter then
        nCMax = Table_GetAchievementInfo(dwCounter) or 0
        nC    = AchievementData.GetAchievementCount(dwCounter)

        bShow = true
    end

    return bShow, nC, nCMax
end

function AchievementData.TryLoadDLCList()
    if not table.is_empty(AchievementData.FILTER_TYPE_DLC_NAME_TO_ID) then
        return
    end

    -- 添加个全部版本的数据
    AchievementData.AddDLCInfo(nil, "全部版本")

    local nCount = g_tTable.DLCInfo:GetRowCount()
    for i = 2, nCount do
        local tLine     = g_tTable.DLCInfo:GetRow(i)

        local szDLCName = UIHelper.GBKToUTF8(tLine.szDLCName)
        local nDLCID    = tLine.dwDLCID

        AchievementData.AddDLCInfo(nDLCID, szDLCName)
    end
end

function AchievementData.AddDLCInfo(nDLCID, szDLCName)
    AchievementData.FILTER_TYPE_DLC_NAME_TO_ID[szDLCName] = nDLCID
    table.insert(AchievementData.FILTER_TYPE_DLC_NAME_LIST, szDLCName)
end

function AchievementData.GetDlcNameToIdMap()
    AchievementData.TryLoadDLCList()

    return AchievementData.FILTER_TYPE_DLC_NAME_TO_ID
end

function AchievementData.GetDlcNameList()
    AchievementData.TryLoadDLCList()

    return AchievementData.FILTER_TYPE_DLC_NAME_LIST
end

function AchievementData.HasPrefixOrPostfix(dwAchievementID)
    local _, _, _, nPrefix, nPostfix = Table_GetAchievementInfo(dwAchievementID)
    nPrefix, nPostfix                = nPrefix or 0, nPostfix or 0

    return nPrefix ~= 0 or nPostfix ~= 0
end

function AchievementData.InitFilterDef(dwPlayerID, nPanelType, nCategoryType)
    AchievementData.InitFilterDefFinishStatus(dwPlayerID, nPanelType, nCategoryType)
    AchievementData.InitFilterDefDLC(dwPlayerID, nPanelType, nCategoryType)
end

function AchievementData.GetFilterDef()
    if not AchievementData.bJumpFromOtherSystem then
        return FilterDef.Achievement
    else
        return FilterDef.AchievementJumpFromOtherSystem
    end
end

local function _ResetFilter(nFilterIndex)
    AchievementData.GetFilterDef()[nFilterIndex].tbList         = {}
    AchievementData.GetFilterDef()[nFilterIndex].tbProgressList = {}
end

local function _AppendFilter(nFilterIndex, szName, szProgress)
    table.insert(AchievementData.GetFilterDef()[nFilterIndex].tbList, szName)
    table.insert(AchievementData.GetFilterDef()[nFilterIndex].tbProgressList, szProgress)
end

function AchievementData.InitFilterDefFinishStatus(dwPlayerID, nPanelType, nCategoryType)
    local filter = AchievementData.GetFilterDef()
    
    _ResetFilter(filter.IndexDef.FinishStatus)

    -- 获得情况
    for nIdx, szName in ipairs(AchievementData.FILTER_TYPE_FINISHED_STATUS_NAME_LIST) do
        local szFinishStatus       = AchievementData.FILTER_TYPE_FINISHED_STATUS_NAME_TO_ENUM_VALUE[szName]
        local _, nFinished, nTotal = AchievementData.GetALLCount(nPanelType, dwPlayerID, nil, szFinishStatus, nil, nCategoryType)

        local szProgress           = string.format("(%d/%d)", nFinished, nTotal)
        if szName == "已达成" or szName == "未达成" then
            -- 已达成和未达成后面，不显示括号和进度
            szProgress = ""
        end

        _AppendFilter(filter.IndexDef.FinishStatus, szName, szProgress)
        
        -- 设置默认值
        local szFilter
        if nPanelType == ACHIEVEMENT_PANEL_TYPE.ACHIEVEMENT then
            szFilter = AchievementData.GetFilterData().szAAchiKey
        else
            szFilter = AchievementData.GetFilterData().szTRAchiKey
        end
        if szFinishStatus == szFilter then
            if not filter.tbRuntime then
                filter.tbRuntime = {}
            end
            filter.tbRuntime[filter.IndexDef.FinishStatus] = { nIdx }
        end
    end
end

function AchievementData.InitFilterDefDLC(dwPlayerID, nPanelType, nCategoryType)
    local filter = AchievementData.GetFilterDef()

    if not AchievementData.bJumpFromOtherSystem then
        _ResetFilter(filter.IndexDef.DlcId)

        -- 获得情况
        for nIdx, szName in ipairs(AchievementData.GetDlcNameList()) do
            local nDlcId               = AchievementData.GetDlcNameToIdMap()[szName]
            local _, nFinished, nTotal = AchievementData.GetALLCount(nPanelType, dwPlayerID, nDlcId, nil, nil, nCategoryType)

            _AppendFilter(filter.IndexDef.DlcId, szName, string.format("(%d/%d)", nFinished, nTotal))

            -- 设置默认值
            if nDlcId == AchievementData.GetFilterData().m_dwADLCID then
                if not filter.tbRuntime then
                    filter.tbRuntime = {}
                end
                filter.tbRuntime[filter.IndexDef.DlcId] = { nIdx }
            end
        end
    end
end

function AchievementData.ApplyFilter(tbInfo, nPanelType)
    local szFilter = AchievementData.GetSelectedFinishStatusValue(tbInfo)

    if nPanelType == ACHIEVEMENT_PANEL_TYPE.ACHIEVEMENT then
        AchievementData.SetFilterData_szAAchiKey(szFilter)
    else
        AchievementData.SetFilterData_szTRAchiKey(szFilter)
    end

    if not AchievementData.bJumpFromOtherSystem then
        AchievementData.SetFilterData_m_dwADLCID(AchievementData.GetSelectedDlcId(tbInfo))
    end
end

function AchievementData.GetSelectedFinishStatusValue(tbInfo)
    local nIndex             = tbInfo[AchievementData.GetFilterDef().IndexDef.FinishStatus][1]
    local szFinishStatusName = AchievementData.FILTER_TYPE_FINISHED_STATUS_NAME_LIST[nIndex]

    return AchievementData.FILTER_TYPE_FINISHED_STATUS_NAME_TO_ENUM_VALUE[szFinishStatusName]
end

function AchievementData.GetSelectedDlcId(tbInfo)
    local nIndex    = tbInfo[AchievementData.GetFilterDef().IndexDef.DlcId][1]
    local szDlcName = AchievementData.GetDlcNameList()[nIndex]

    return AchievementData.FILTER_TYPE_DLC_NAME_TO_ID[szDlcName]
end

function AchievementData.GetSubAchievementNameAndDesc(aSubAchievement, nNameMaxLength, nDescMaxLength)
    local szTruncation   = "…"

    -- 子成就名称最多显示 nNameMaxLength 个字，不包括溢出时补上的 …
    local szName         = UIHelper.TruncateStringReturnOnlyResult(UIHelper.GBKToUTF8(aSubAchievement.szName), nNameMaxLength + 1, szTruncation)
    local szDesc         = ""
    if aSubAchievement.szShortDesc and aSubAchievement.szShortDesc ~= "" then
        -- 若有简短描述，最多显示 nDescMaxLength 个字，不包括溢出时补上的 …
        szDesc = UIHelper.TruncateStringReturnOnlyResult(UIHelper.GBKToUTF8(aSubAchievement.szShortDesc), nDescMaxLength + 1, szTruncation)
    end

    return szName, szDesc
end

function AchievementData.GetCurrentSeriesAchievementStage(dwSeriesAchievement, dwPlayerID)
    local aSeriesAchievement       = Table_GetAchievement(dwSeriesAchievement)

    local tSeriesAchievementIDList = {}
    for s in string.gmatch(aSeriesAchievement.szSeries, "%d+") do
        local dwAchievement = tonumber(s)

        table.insert(tSeriesAchievementIDList, dwAchievement)
    end

    local nFinishNum = 0
    local dwCurrentAchievement = dwSeriesAchievement
    for idx, dwAchievement in ipairs(tSeriesAchievementIDList) do
        local aAchievement = Table_GetAchievement(dwAchievement)
        local bFinish      = AchievementData.IsAchievementAcquired(dwAchievement, aAchievement, dwPlayerID, true)

        if bFinish then
            nFinishNum = nFinishNum + 1
        elseif not bFinish or idx == #tSeriesAchievementIDList then
            dwCurrentAchievement = dwAchievement
            break
        end
    end

    return nFinishNum .. "/" .. #tSeriesAchievementIDList, dwCurrentAchievement
end

function AchievementData.GetFilterMapName()
    local szFilterMapName = "地图"
    if AchievementData.GetFilterData().m_dwASceneID ~= nil then
        szFilterMapName = AchievementData.GetFilterData().m_dwASceneName
    elseif AchievementData.bJumpFromOtherSystem and AchievementData.GetFilterData().m_dwAMapID ~= nil then
        szFilterMapName = AchievementData.GetMiddleMapFirstName(AchievementData.GetFilterData().m_dwAMapID)
    end
    
    return szFilterMapName
end 
-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: ShareStationData
-- Date: 2025-07-18 14:25:10
-- Desc: ?
-- ---------------------------------------------------------------------------------
local FACE_TYPE_2_SUFFIX = {
    [FACE_TYPE.OLD] = "dat",
    [FACE_TYPE.NEW] = "ini",
}

--不同封面尺寸
local COVER_SIZE_TYPE = {
    FACE = 0,       --捏脸
    CARD = 1,       --体型/外观/名片
    HORIZONTAL = 2, --横版
    VERTICAL = 3,   --竖版
}

local INDEX_TO_SOURCE_TYPE = {
    [1] = nil,
    [2] = "dx",
    [3] = "vk",
}

--每一页最多显示的作品数量
local SHARE_LIST_PAGE_SIZE = {
    [COVER_SIZE_TYPE.FACE] = 15,
    [COVER_SIZE_TYPE.CARD] = 12,
    [COVER_SIZE_TYPE.HORIZONTAL] = 12,
    [COVER_SIZE_TYPE.VERTICAL] = 9,
}
local COVER_PIXEL_LIMIT = {442, 442}        -- 捏脸 nWidth, nHeight
local BODY_PIXEL_LIMIT = {376, 500}         -- 体型 nWidth, nHeight
local HORIZONTAL_PIXEL_LIMIT = {1024, 576}   -- 横版 nWidth, nHeight
local VERTICAL_PIXEL_LIMIT = {324, 576}     -- 竖版 nWidth, nHeight

ShareStationData = ShareStationData or {className = "ShareStationData"}
local self = ShareStationData

function ShareStationData.GetOpenState()
    -- return IsDebugClient()
    return true
end
-------------------------------- 消息定义 --------------------------------
local NEW_FACE_SUFFIX = "ini"
local OLD_FACE_SUFFIX = "dat"
local DATA_LIST_PAGE_SIZE = 12 --每一页最多显示捏脸的数量
local MIN_SEARCH_USER_CHAR_COUNT = 2 --最少搜索作者名字字符数
local MAX_FACE_STATION_PAGE = 99 --捏脸站最多显示99页
local USER_LIST_PAGE_SIZE = 10 --作者列表一页能展示的最大数量,在VK是直接展开10个作者的作品
local MAX_COLLECT_COUNT = 50 --最多收藏捏脸的个数

local PAGE_TYPE = {
    ALL = "All",
    LIKE = "Like",
    SELF = "Self",
}

local SORT_TYPE = {
    TOTAL_HEAT = 1,
    MONTH_HEAT = 2,
    WEEK_HEAT = 3,
    NEW = 4,
}

local CREATE_RANGE = {
    [1] = "day",
    [2] = "week",
    [3] = "month",
}

-- local SHARE_OPEN_STATUS = {
--     PRIVATE = 0,
--     PUBLIC = 1,
--     FILE_ILLEGAL = 2,
--     COVER_ILLEGAL = 3,
--     INVISIBLE = 4,
--     CHECKING_TO_PRIVATE = 5,
--     CHECKING_TO_PUBLIC = 6,
--     DELETE = 7,
-- }

-----------------------------ShareStationData------------------------------
function ShareStationData.Init(nDataType, nRoleType, szSuffix, bIsLogin)
    ShareStationData.bOpening = true
    ShareStationData.nRoleType = nRoleType
    ShareStationData.szSuffix = szSuffix
    ShareStationData.bIsLogin = bIsLogin
    ShareStationData.szPageName = ""
    ShareStationData.nTotalShareCount = 0
    ShareStationData.nFilterShareCount = 0
    ShareStationData.nDataType = nDataType or SHARE_DATA_TYPE.FACE
    ShareStationData.nSubType = 0 --正在预览作品的子类型
    ShareStationData.nViewPage = 1
    ShareStationData.nPhotoSizeType = SHARE_PHOTO_SIZE_TYPE.CARD
    ShareStationData.nFilterRoleType = nRoleType
    ShareStationData.nFilterOpenState = -1
    ShareStationData.szSearch = ""
    ShareStationData.nSearchType = SHARE_SEARCH_TYPE.NAME

    -- 筛选相关
    ShareStationData.nSourceType = 3
    ShareStationData.nRangeType = 3
    ShareStationData.nPhotoMapType = 0
    ShareStationData.dwPhotoMapID = 0
    ShareStationData.bHairDyeing = false
    ShareStationData.tTag = {}
    ShareStationData.tFilterExterior = {}

    ShareStationData.bDelMode = false
    ShareStationData.tbScriptList = {}
    ShareStationData.szUseShareCode = nil
    ShareStationData.bWaitForPreview = false

    --推荐
    ShareStationData.szAllSuffix = szSuffix
    ShareStationData.tAllShareList = {}
    ShareStationData.nSortType = SORT_TYPE.TOTAL_HEAT
    ShareStationData.bSortCD = nil
    ShareStationData.nMaxPageAll = 0
    ShareStationData.tViewCodeAll = {} --不一定需要

    --收藏
    ShareStationData.szLikeSuffix = ""
    ShareStationData.tLikeShareList = {}
    ShareStationData.nLikeCount = 0
    ShareStationData.nMaxPageLike = 0
    ShareStationData.tViewCodeLike = {} --不一定需要

    --我的
    ShareStationData.szSelfSuffix = ""
    ShareStationData.nSelfCount = 0
    ShareStationData.nMaxPageSelf = 0
    ShareStationData.nUploadLimit = 0
    ShareStationData.tSelfShareList = {}
    ShareStationData.tViewCodeSelf = {} --不一定需要

    ShareStationData.bImportFail = not bIsLogin
    ShareStationData.InitSubType()
end

function ShareStationData.InitSubType()
    local nDataType = ShareStationData.nDataType
    ShareStationData.nSubType = 0
    if not ShareStationData.bIsLogin then --从商城进入
        if nDataType == SHARE_DATA_TYPE.FACE then
            if ShareStationData.szSuffix == NEW_FACE_SUFFIX then
                ShareStationData.nSubType = FACE_TYPE.NEW
            else
                ShareStationData.nSubType = FACE_TYPE.OLD
            end
        elseif nDataType == SHARE_DATA_TYPE.PHOTO then
            ShareStationData.nSubType = ShareStationData.nPhotoSizeType
        end
    else --创角界面进入
        if nDataType == SHARE_DATA_TYPE.FACE then
            local bNewFace = ShareStationData.szSuffix == NEW_FACE_SUFFIX
            if bNewFace then
                ShareStationData.nSubType = FACE_TYPE.NEW
            else
                ShareStationData.nSubType = FACE_TYPE.OLD
            end
        elseif nDataType == SHARE_DATA_TYPE.PHOTO then
            ShareStationData.nSubType = ShareStationData.nPhotoSizeType
        end
    end
    ShareStationData.nAllSubType = ShareStationData.nSubType
    ShareStationData.nLikeSubType = ShareStationData.nSubType
    ShareStationData.nSelfSubType = ShareStationData.nSubType

    local nCoverSizeType = ShareStationData.GetCoverSizeType()
    ShareStationData.nPageSize = SHARE_LIST_PAGE_SIZE[nCoverSizeType]
end

function ShareStationData.GetCoverSizeType()
    local nDataType = ShareStationData.nDataType
    local nSubType = ShareStationData.nSubType
    if nDataType == SHARE_DATA_TYPE.FACE then
        return COVER_SIZE_TYPE.FACE --捏脸
    elseif nDataType == SHARE_DATA_TYPE.BODY or nDataType == SHARE_DATA_TYPE.EXTERIOR
        or (nDataType == SHARE_DATA_TYPE.PHOTO and nSubType == SHARE_PHOTO_SIZE_TYPE.CARD) then
        return COVER_SIZE_TYPE.CARD --体型/外观/名片
    elseif nDataType == SHARE_DATA_TYPE.PHOTO and nSubType == SHARE_PHOTO_SIZE_TYPE.HORIZONTAL then
        return COVER_SIZE_TYPE.HORIZONTAL --横版
    elseif nDataType == SHARE_DATA_TYPE.PHOTO and nSubType == SHARE_PHOTO_SIZE_TYPE.VERTICAL then
        return COVER_SIZE_TYPE.VERTICAL --竖版
    end
end

function ShareStationData.UnInit()
    ShareStationData.bOpening = nil
    ShareStationData.bEnterMySelf = nil
    ShareStationData.szSuffix = nil
    ShareStationData.nRoleType = nil
    ShareStationData.nDataType = nil
    ShareStationData.nPhotoSizeType = nil
    ShareStationData.nPhotoMapType = nil
    ShareStationData.dwPhotoMapID = nil
    ShareStationData.bIsLogin = nil
    ShareStationData.szPageName = nil
    ShareStationData.nTotalShareCount = nil
    ShareStationData.nFilterShareCount = nil
    ShareStationData.nViewPage = nil
    ShareStationData.nFilterRoleType = nil
    ShareStationData.nFilterOpenState = nil
    ShareStationData.szSearch = nil
    ShareStationData.tFilterExterior = nil

    ShareStationData.szFilterAccount = nil

    ShareStationData.bDelMode = nil
    ShareStationData.szUseShareCode = nil
    ShareStationData.bWaitForPreview = nil
    ShareStationData.tDelShare = nil
    ShareStationData.labelDelManager = nil
    ShareStationData.tbScriptList = nil
    ShareStationData.togSelectAll = nil

    --推荐
    ShareStationData.szAllSuffix = nil
    ShareStationData.tAllShareList = nil
    ShareStationData.nSortType = nil
    ShareStationData.bSortCD = nil
    ShareStationData.tViewCodeAll = nil

    --收藏
    ShareStationData.szLikeSuffix = nil
    ShareStationData.tLikeShareList = nil
    ShareStationData.tViewCodeLike = nil

    --我的
    ShareStationData.szSelfSuffix = nil
    ShareStationData.nUploadLimit = nil
    ShareStationData.tSelfShareList = nil
    ShareStationData.tViewCodeSelf = {}
    -- ShareCodeData.ClearCacheData() -- 不能清空，VK没法删，因为本次开启游戏后如果有下载，后继不会再刷新其存在
end

function ShareStationData.ApplySearchUser()
    local szAccount = ShareStationData.szFilterAccount
    if not szAccount then
        return
    end

    local bIsLogin = ShareStationData.bIsLogin
    local nSortType = ShareStationData.nSortType
    local szRankType = "total" --默认选择【总热度】
    if nSortType == SORT_TYPE.NEW then
        szRankType = "new"
    end

    local nPage = ShareStationData.nViewPage

    local tFilter = {szAccount = szAccount}
    --需策划确认搜出来的脸型列表是否要区分写实/写意

    ShareCodeData.GetShareRankList(bIsLogin, ShareStationData.nDataType, nil, nPage, DATA_LIST_PAGE_SIZE, szRankType, tFilter)
end

function ShareStationData.ApplyShareStationData()
    local nDataType = ShareStationData.nDataType
    local nSortType = ShareStationData.nSortType
    local nRangeType = ShareStationData.nRangeType
    local nSourceType = ShareStationData.nSourceType
    local bHairDyeing = ShareStationData.bHairDyeing

    local szRankType = "new"
    if nSortType == SORT_TYPE.TOTAL_HEAT then
        szRankType = "total"
    elseif nSortType == SORT_TYPE.MONTH_HEAT then
        szRankType = "month"
    elseif nSortType == SORT_TYPE.WEEK_HEAT then
        szRankType = "week"
    end

    local szCreateRange = nil
    if nRangeType == SHARE_TIME_RANGE.DAY then
        szCreateRange = "-1day"
    elseif nRangeType == SHARE_TIME_RANGE.WEEK then
        szCreateRange = "-1week"
    elseif nRangeType == SHARE_TIME_RANGE.MONTH then
        szCreateRange = "-1month"
    elseif nRangeType == SHARE_TIME_RANGE.THREE_MONTH then
        szCreateRange = "-3month"
    end

    if ShareStationData.tbEventLinkInfo then
        szRankType = nil
    end

    local tFilter = {}
    local bIsLogin = ShareStationData.bIsLogin
    local nViewPage = ShareStationData.nViewPage
    local nSearchType = ShareStationData.nSearchType
    local szSearch = ShareStationData.szSearch and ShareStationData.szSearch or ""

    if szSearch == "" then --所有搜空字符串的情况都默认在搜作品
        nSearchType = SHARE_SEARCH_TYPE.NAME
    end

    tFilter.nSearchType = nSearchType
    tFilter.szSearch = szSearch
    tFilter.nRoleType = ShareStationData.nFilterRoleType
    tFilter.tTag = ShareStationData.tTag
    tFilter.szUploadSource = INDEX_TO_SOURCE_TYPE[nSourceType]

    --捏脸站
    if nDataType == SHARE_DATA_TYPE.FACE then
        tFilter.nFaceType = ShareStationData.nSubType
    elseif nDataType == SHARE_DATA_TYPE.EXTERIOR then
        if ShareStationData.tFilterExterior and not table.is_empty(ShareStationData.tFilterExterior) then
            tFilter.tFilterExterior = {}
            for nRes, v in pairs(ShareStationData.tFilterExterior) do
                tFilter.tFilterExterior[tostring(nRes)] = v
            end
        end

        if bHairDyeing then
            tFilter.tFilterExterior = tFilter.tFilterExterior or {}
            tFilter.tFilterExterior["Color" .. EQUIPMENT_REPRESENT.HAIR_STYLE] = {1} --发型染色标记
        end
        -- tJsonFilter.force_id = tFilter.dwForceID --门派筛选，暂时不做限制
    elseif nDataType == SHARE_DATA_TYPE.PHOTO then
        tFilter.nPhotoSizeType = ShareStationData.nPhotoSizeType
        tFilter.nPhotoMapType = ShareStationData.nPhotoMapType
        tFilter.dwPhotoMapID = ShareStationData.dwPhotoMapID
    end

    local nSearchLen = UIHelper.GetUtf8Len(szSearch)
    local bInvalidUserSearch = nSearchType == SHARE_SEARCH_TYPE.USER and nSearchLen < MIN_SEARCH_USER_CHAR_COUNT
    if bInvalidUserSearch then --搜作者有内容但是不到2个字的情况只做提示
        TipsHelper.ShowNormalTip(g_tStrings.STR_SHARE_STATION_INVALID_USER)
        return
    end

    if nSearchType == SHARE_SEARCH_TYPE.USER then
        ShareCodeData.GetCreatorList(bIsLogin, nDataType, ShareStationData.szSearch)
    else
        ShareCodeData.GetShareRankList(bIsLogin, nDataType, szCreateRange, nViewPage, DATA_LIST_PAGE_SIZE, szRankType, tFilter)
    end
end

function ShareStationData.SetLikeShareData(tLikeShareList) --得想办法把这个分类整理挪到ShareCodeData里去
    local nDataType = ShareStationData.nDataType
    ShareStationData.tLikeShareList = {}

    local tSubTypeList = {}
    if nDataType == SHARE_DATA_TYPE.FACE then
        tSubTypeList = FACE_TYPE
    elseif nDataType == SHARE_DATA_TYPE.PHOTO then
        tSubTypeList = SHARE_PHOTO_SIZE_TYPE
    else
        tSubTypeList = {0}
    end
    for _, nSubType in pairs(tSubTypeList) do
        ShareStationData.tLikeShareList[nSubType] = {}
    end

    ShareStationData.nLikeCount = 0
    for _, tShareData in ipairs(tLikeShareList) do
        local nSubType = tShareData.nSubType
        if nSubType then
            table.insert(ShareStationData.tLikeShareList[nSubType], tShareData)
            ShareStationData.nLikeCount = ShareStationData.nLikeCount + 1
        end
    end
end

function ShareStationData.SetSelfShareData(tSelfShareList) --得想办法把这个分类整理挪到ShareCodeData里去
    local nDataType = ShareStationData.nDataType
    ShareStationData.tSelfShareList = {}

    local tSubTypeList = {}
    if nDataType == SHARE_DATA_TYPE.FACE then
        tSubTypeList = FACE_TYPE
    elseif nDataType == SHARE_DATA_TYPE.PHOTO then
        tSubTypeList = SHARE_PHOTO_SIZE_TYPE
    else
        tSubTypeList = {0}
    end
    for _, nSubType in pairs(tSubTypeList) do
        ShareStationData.tSelfShareList[nSubType] = {}
    end

    table.sort(tSelfShareList, function(t1, t2) return t1.dwCreateTime >= t2.dwCreateTime end)

    ShareStationData.nSelfCount = 0
    for _, tShareData in ipairs(tSelfShareList) do
        local nSubType = tShareData.nSubType
        if nSubType then
            ShareStationData.tSelfShareList[nSubType] = ShareStationData.tSelfShareList[nSubType] or {}
            table.insert(ShareStationData.tSelfShareList[nSubType], tShareData)
            ShareStationData.nSelfCount = ShareStationData.nSelfCount + 1
        end
    end
end

function ShareStationData.GetLikeShareData(nSubType)
    local tData = clone(ShareStationData.tLikeShareList[nSubType]) or {}
    if ShareStationData.nSortType == SHARE_TIME_SORT_TYPE.NEW then
        table.sort(
            tData,
            function(t1, t2)
                return t1.nPos < t2.nPos
            end
        )
    else
        table.sort(
            tData,
            function(t1, t2)
                return t1.nPos > t2.nPos
            end
        )
    end
    return tData
end

function ShareStationData.GetLikeShareCount()
    local nCount = 0
    for _, tData in pairs(ShareStationData.tLikeShareList) do
        nCount = nCount + #tData
    end
    return nCount
end

function ShareStationData.GetSelfShareData(nSubType)
    local tData = clone(ShareStationData.tSelfShareList[nSubType]) or {}
    if ShareStationData.nSortType == SHARE_TIME_SORT_TYPE.NEW then
        table.sort(
            tData,
            function(t1, t2)
                return t1.nPos < t2.nPos
            end
        )
    else
        table.sort(
            tData,
            function(t1, t2)
                return t1.nPos > t2.nPos
            end
        )
    end
    return tData
end

function ShareStationData.GetFilterShareData(nDataType, tShareList)
    --所有本地筛选条目都在这里处理
    local nRoleType = ShareStationData.nFilterRoleType
    local nOpenStatus = ShareStationData.nOpenStatus
    local szUploadSource = INDEX_TO_SOURCE_TYPE[ShareStationData.nSourceType]
    local tTag = ShareStationData.tTag
    local nPhotoMapType = ShareStationData.nPhotoMapType
    local dwPhotoMapID = ShareStationData.dwPhotoMapID
    local nSearchType = ShareStationData.nSearchType
    local szSearch = ShareStationData.szSearch
    local tFilterExterior = clone(ShareStationData.tFilterExterior)
    local bHairDyeing = ShareStationData.bHairDyeing

    local tData = {}
    for _, tShareData in ipairs(tShareList) do
        local bFilterSearch = true
        if szSearch == "" then
            nSearchType = SHARE_SEARCH_TYPE.NAME --搜空字符串默认在搜作品
        end

        if nSearchType == SHARE_SEARCH_TYPE.NAME then
            bFilterSearch = szSearch == "" or string.match(tShareData.szName, szSearch) ~= nil
        elseif nSearchType == SHARE_SEARCH_TYPE.CODE then
            bFilterSearch = tShareData.szShareCode == szSearch
        elseif nSearchType == SHARE_SEARCH_TYPE.USER then
            --收藏/我的分页没有作者筛选
        end

        --其他筛选的前提是选择筛选【作品】，如果是筛选非空的【分享码】则无视以下限制
        if nSearchType == SHARE_SEARCH_TYPE.NAME or not szSearch or szSearch == "" then
            local bFilterRoleType = true
            if nRoleType and nRoleType ~= -1 then
                bFilterRoleType = tShareData.nRoleType == nRoleType
            end

            local bFilterOpenState = true
            if nOpenStatus and nOpenStatus ~= -1 then
                bFilterOpenState = tShareData.nOpenStatus == nOpenStatus
            end

            local bFilterUploadSource = true
            if szUploadSource and szUploadSource ~= "" then
                bFilterUploadSource = tShareData.szUploadSource == szUploadSource
            end

            local bFilterMap = true
            if nDataType == SHARE_DATA_TYPE.PHOTO
            and nPhotoMapType and nPhotoMapType ~= -1
            and dwPhotoMapID and dwPhotoMapID ~= -1 then
                bFilterMap = tShareData.nPhotoMapType == nPhotoMapType and tShareData.dwPhotoMapID == dwPhotoMapID
            end

            local bFilterExterior = true
            local tFilterData = tShareData.tFilterData
            if nDataType == SHARE_DATA_TYPE.EXTERIOR and tFilterData then
                -- 发型染色标记
                if bHairDyeing then
                    local szFilterHairDyeKey = "Color" .. EQUIPMENT_REPRESENT.HAIR_STYLE
                    local nHairDyeingFlag = tFilterData[szFilterHairDyeKey] or 0
                    if nHairDyeingFlag ~= 1 then
                        bFilterExterior = false
                    end
                end

                -- 外观数据
                if tFilterExterior then
                    for nSub, tRes in pairs(tFilterExterior) do
                        if not IsTableEmpty(tRes) and not table.contain_value(tRes, tFilterData[nSub]) then
                            bFilterExterior = false
                            break
                        end
                    end
                end
            end

            local bFilterTag = true
            if tTag and #tTag > 0 then
                if not tShareData.tTag or #tShareData.tTag == 0 then
                    bFilterTag = false
                else
                    for _, nTag in ipairs(tTag) do
                        if not table.contain_value(tShareData.tTag, nTag) then
                            bFilterTag = false
                            break
                        end
                    end
                end
            end

            if bFilterRoleType and bFilterOpenState and bFilterUploadSource and bFilterTag and bFilterSearch and bFilterExterior and bFilterMap then
                table.insert(tData, tShareData)
            end
        else
            if bFilterSearch then
                table.insert(tData, tShareData)
            end
        end
    end
    return tData
end

function ShareStationData.SetFilterTag(tTag)
    ShareStationData.tTag = tTag
end

function ShareStationData.SetSearchType(nSearchType)
    ShareStationData.nSearchType = nSearchType
end

function ShareStationData.SetDataType(nDataType)
    ShareStationData.nDataType = nDataType
end

function ShareStationData.SetViewPage(nPage)
    ShareStationData.nViewPage = nPage
end

function ShareStationData.IsInFilter(szPageType)
    local bInFilter = false
    local nDataType = ShareStationData.nDataType
    local nRoleType = ShareStationData.nFilterRoleType
    local nOpenStatus = ShareStationData.nFilterOpenState
    local szSearch = ShareStationData.szSearch

    local tbTag = ShareStationData.tTag
    local nSourceType = ShareStationData.nSourceType
    local nRangeType = ShareStationData.nRangeType
    local bHairDyeing = ShareStationData.bHairDyeing

    if szPageType == "Rank" then
        if nDataType == SHARE_DATA_TYPE.EXTERIOR or nDataType == SHARE_DATA_TYPE.PHOTO then
            bInFilter = nRoleType ~= -1
        else
            bInFilter = nRoleType ~= ShareStationData.nRoleType
        end
    else
        bInFilter = nRoleType ~= ShareStationData.nRoleType
    end

    if nOpenStatus ~= -1 then
        bInFilter = true
    end

    if not string.is_nil(szSearch) then
        bInFilter = true
    end

    if nSourceType ~= 1 or nRangeType ~= 1 then
        bInFilter = true
    end

    if tbTag and #tbTag > 0 then
        bInFilter = true
    end

    if bHairDyeing then
        bInFilter = true
    end

    return bInFilter
end

function ShareStationData.IsInExteriorFilter()
    local bInFilter = false
    local nDataType = ShareStationData.nDataType

    if nDataType == SHARE_DATA_TYPE.EXTERIOR then
        bInFilter = not table.is_empty(ShareStationData.tFilterExterior)
    elseif nDataType == SHARE_DATA_TYPE.PHOTO then
        bInFilter = ShareStationData.dwPhotoMapID > 0 and ShareStationData.nPhotoMapType > 0
    end
    return bInFilter
end

function ShareStationData.IsCollectShare(szShareCode)
    if not szShareCode or not ShareCodeData.tCollectDataList then
        return false
    end

    for _, tShareList in pairs(ShareCodeData.tCollectDataList) do
        for index, tInfo in ipairs(tShareList) do
            if tInfo.szShareCode == szShareCode then --按理说如果是被隐藏或者删除的数据，就不会有这个捏脸码了，待确认
                return true
            end
        end
    end
    return false
end

function ShareStationData.IsSelfShare(szShareCode)
    if not szShareCode or not ShareCodeData.tbSelfDataList then
        return false
    end
    
    for szSuffix, tList in pairs(ShareCodeData.tbSelfDataList) do
        for _, tSelfShare in ipairs(tList) do
            if szShareCode == tSelfShare.szShareCode then
                return true
            end
        end
    end
    return false
end

function ShareStationData.GetSelfShareInfo(szShareCode)
    if not szShareCode or not ShareStationData.tSelfShareList then
        return
    end
    
    for _, tList in pairs(ShareStationData.tSelfShareList) do
        for _, tSelfShare in ipairs(tList) do
            if szShareCode == tSelfShare.szShareCode then
                return tSelfShare
            end
        end
    end
end

function ShareStationData.GetCollectShareInfo(szShareCode)
    if not szShareCode or not ShareStationData.tLikeShareList then
        return
    end

    for _, tShareList in pairs(ShareStationData.tLikeShareList) do
        for index, tInfo in ipairs(tShareList) do
            if tInfo.szShareCode == szShareCode then
                return tInfo
            end
        end
    end
end

function ShareStationData.BindBatchDelManager(labelCount, togSelectAll)
    ShareStationData.tDelShare = {}
    ShareStationData.labelDelManager = labelCount
    ShareStationData.togSelectAll = togSelectAll

    local layoutDelManager = UIHelper.GetParent(labelCount)
    UIHelper.SetString(ShareStationData.labelDelManager, string.format("%d", 0))
    UIHelper.SetSelected(togSelectAll, false, false)
    if layoutDelManager then
        ShareStationData.layoutDelManager = UIHelper.GetParent(labelCount)
        UIHelper.LayoutDoLayout(ShareStationData.layoutDelManager)
    end
end

function ShareStationData.OnSelectBatchDel(tbShareData, bSelect)
    local szShareCode = tbShareData and tbShareData.szShareCode
    if not szShareCode then
        return
    end

    if bSelect and not table.contain_value(ShareStationData.tDelShare, szShareCode) then
        table.insert(ShareStationData.tDelShare, szShareCode)
    else
        table.remove_value(ShareStationData.tDelShare, szShareCode)
    end

    Timer.AddFrame(self, 1, ShareStationData.OnUpdateDelManager)
end

function ShareStationData.OnUpdateDelManager()
    if not ShareStationData.tDelShare then
        return
    end

    local nSelectedNum = table.GetCount(ShareStationData.tDelShare)
    if ShareStationData.togSelectAll then
        local bSelected = ShareStationData.tbScriptList and not table.is_empty(ShareStationData.tbScriptList)
        for _, scriptCell in ipairs(ShareStationData.tbScriptList) do
            if not scriptCell:GetSelected() then
                bSelected = false
                break
            end
        end
        UIHelper.SetSelected(ShareStationData.togSelectAll, bSelected, false)
    end

    if ShareStationData.labelDelManager then
        UIHelper.SetString(ShareStationData.labelDelManager, string.format("%d", nSelectedNum))
    end

    if ShareStationData.layoutDelManager then
        UIHelper.LayoutDoLayout(ShareStationData.layoutDelManager)
    end
end

function ShareStationData.GetStandardSize(nDataType, nPhotoSizeType)
    local nW, nH = 0, 0
    if nDataType == SHARE_DATA_TYPE.FACE then
        nW, nH = unpack(COVER_PIXEL_LIMIT)
    elseif nDataType == SHARE_DATA_TYPE.BODY or nDataType == SHARE_DATA_TYPE.EXTERIOR
        or (nDataType == SHARE_DATA_TYPE.PHOTO and nPhotoSizeType == SHARE_PHOTO_SIZE_TYPE.CARD) then
        nW, nH = unpack(BODY_PIXEL_LIMIT)
    elseif nDataType == SHARE_DATA_TYPE.PHOTO and nPhotoSizeType == SHARE_PHOTO_SIZE_TYPE.HORIZONTAL then
        nW, nH = unpack(HORIZONTAL_PIXEL_LIMIT)
    elseif nDataType == SHARE_DATA_TYPE.PHOTO and nPhotoSizeType == SHARE_PHOTO_SIZE_TYPE.VERTICAL then
        nW, nH = unpack(VERTICAL_PIXEL_LIMIT)
    end
	return nW, nH
end

function ShareStationData.GetCoverLimit()
    local nWidth, nHeight = unpack(COVER_PIXEL_LIMIT)
    return nWidth, nHeight
end

----------------------------------------------------------
function ShareStationData.OpenShareStation(nDataType, bEnterMySelf)
    -- if not ShareStationData.GetOpenState() then
    --     TipsHelper.ShowNormalTip("部分功能升级维护中，设计站暂未开放")
    --     return
    -- end

    local bCoinShopIsOpen = false
    local bShareStationIsOpen = false
    bCoinShopIsOpen = UIMgr.IsViewOpened(VIEW_ID.PanelExteriorMain, true)
    bShareStationIsOpen = UIMgr.IsViewOpened(VIEW_ID.PanelShareStation, true)
    if bShareStationIsOpen then
        return UIMgr.GetViewScript(VIEW_ID.PanelShareStation)
    end

    ShareStationData.bEnterMySelf = bEnterMySelf or nil
    if not bCoinShopIsOpen then
        UIMgr.Open(VIEW_ID.PanelExteriorMain, function()
            Event.Dispatch(EventType.OnOpenShareStation, nDataType)
        end)
        return
    end
    Event.Dispatch(EventType.OnOpenShareStation, nDataType)
end

function ShareStationData.DoUploadByType(nDataType, nPhotoSizeType, tPreviewData, tUploadInfo, fnCloseCallBack)
    if not nDataType then
        return
    end

    ShareStationData.SyncUploadFaceDecoration(nDataType, tPreviewData and tPreviewData.tFaceData or {})

    ShareStationData.tPreviewData = tPreviewData or nil
    ShareStationData.tUploadInfo = tUploadInfo or nil

    UIMgr.HideLayer(UILayer.Tips)
    Event.Dispatch(EventType.HideAllHoverTips)
    UIHelper.CaptureScreenMainPlayer(function (pRetTexture, pImage)
        UIMgr.ShowLayer(UILayer.Tips)

        if UIMgr.IsOpening() then
            ShareStationData.tPreviewData = nil
            ShareStationData.tUploadInfo = nil
            TipsHelper.ShowImportantRedTip("截图失败，请重新上传")
            fnCloseCallBack()
            if safe_check(pImage) then
                pImage:release()
            end

            if safe_check(pRetTexture) then
                pRetTexture:release()
            end
            return
        end
        UIMgr.Open(VIEW_ID.PanelFaceCoverCropping, pRetTexture, pImage, nDataType, nPhotoSizeType, tUploadInfo, fnCloseCallBack)
    end, 1, true)
end

function ShareStationData.OnClickEventLink(nDataType, szShareCode, szName, nSubType)
    if not nDataType then
        return
    end

    local szTitle = string.format(g_tStrings.STR_SHARE_STATION_EVENTLINK_TIP, szName)
    UIHelper.ShowConfirm(szTitle, function()
        ShareStationData.tbEventLinkInfo = {
            nDataType = nDataType,
            szShareCode = szShareCode,
            szName = szName,
            nSubType = nSubType,
        }
        local scriptView = ShareStationData.OpenShareStation(nDataType)
        if scriptView then
            Timer.AddFrame(self, 1, function ()
                scriptView:OnLink2Share()
            end)
        end
        UIMgr.Close(VIEW_ID.PanelChatSocial)
    end, function()
        ShareStationData.tbEventLinkInfo = nil
    end)
end

function ShareStationData.CheckShowRuleTip()
    local bShowRule = Storage.ShareStationRule.bShowRule
    if not bShowRule then
        UIMgr.Open(VIEW_ID.PanelShareStationRulePop)
    end
end

function ShareStationData.SyncUploadFaceDecoration(nDataType, tPreviewData)
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end

    if nDataType == SHARE_DATA_TYPE.FACE then
        local bDecoration = false
        if tPreviewData.bNewFace then
            local tDecoration = tPreviewData.tDecoration
            if tDecoration then
                for k, v in pairs(tDecoration) do
                    if v.nShowID and v.nShowID ~= 0 then
                        bDecoration = true
                        break
                    end
                end
            end
        else
            local nDecorationID = tPreviewData.nDecorationID
            bDecoration = nDecorationID and nDecorationID ~= 0
        end

        local bShowFlag = pPlayer.GetFaceDecorationShowFlag()
        if not bShowFlag and bDecoration then
            if tPreviewData.bNewFace then
                tPreviewData.tDecoration = {
                    [FACE_LIFT_DECORATION_TYPE.MOUTH] = {
                        nShowID = 0,
                        nColorID = 0
                    },
                    [FACE_LIFT_DECORATION_TYPE.NOSE] = {
                        nShowID = 0,
                        nColorID = 0
                    },
                }
            else
                tPreviewData.nDecorationID = 0
            end
        end
    end
end

local function _OpenSelfie(bCardMode, tData)
    SelfieTemplateBase.CancelGuildSelfiePlace()
    ShareStationData.szImportPhotoCode = tData.szShareCode
    if bCardMode then
        UIMgr.OpenSingle(false, VIEW_ID.PanelPersonalCard)
        return
    end
    UIMgr.Open(VIEW_ID.PanelCamera)
end

function ShareStationData.OnApplyPhoto(tData, bCardMode, bLocate)
    if not tData or not tData.szShareCode then
        return
    end
    local tbShareData = ShareCodeData.GetShareCodeData(tData.szShareCode)
    if not tbShareData then
        return
    end

    local szTitle = bCardMode and g_tStrings.STR_SHARE_STATION_OPEN_NAME_CARD_CONFIRM or g_tStrings.STR_SHARE_STATION_OPEN_SELFIE_CONFIRM
    local szBtnGo = g_tStrings.STR_SHARE_STATION_SELFIE_BTN
    local szBtnGoAndCollect = g_tStrings.STR_SHARE_STATION_SELFIE_COLLECT_BTN
    if bLocate then
        local szMapName = SelfieTemplateBase.GetPhotoMapName(tData.nPhotoMapType, tData.dwPhotoMapID)
        szTitle = FormatString(g_tStrings.STR_SHARE_STATION_IMPORT_PHOTO_CONFIRM, szMapName)
        szBtnGo = g_tStrings.STR_SHARE_STATION_TRACE_BTN
        szBtnGoAndCollect = g_tStrings.STR_SHARE_STATION_TRACE_COLLECT_BTN
    end

    local scriptTips = UIHelper.ShowConfirm(szTitle, function ()
        ShareCodeData.CollectData(ShareStationData.bIsLogin, ShareStationData.nDataType, tData.szShareCode)
        ShareCodeData.AddDataHeat(ShareStationData.bIsLogin, ShareStationData.nDataType, tData.szShareCode)
        UIMgr.CloseAllInLayer(UILayer.Page, {VIEW_ID.PanelPersonalCard})
        _OpenSelfie(bCardMode, tData)
        RemoteCallToServer("On_SA_SJZ", 1)
    end)

    scriptTips:ShowButton("Other")
    scriptTips:SetOtherButtonClickedCallback(function ()
        ShareCodeData.AddDataHeat(ShareStationData.bIsLogin, ShareStationData.nDataType, tData.szShareCode)
        UIMgr.CloseAllInLayer(UILayer.Page, {VIEW_ID.PanelPersonalCard})
        _OpenSelfie(bCardMode, tData)
        RemoteCallToServer("On_SA_SJZ", 1)
    end)
    
    scriptTips:SetConfirmButtonContent(szBtnGoAndCollect)
    scriptTips:SetOtherButtonContent(szBtnGo)
end
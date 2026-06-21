ShareCodeData = ShareCodeData or {className = "ShareCodeData"}

local SHARE_URL_TEST = "https://qa-jx3-sjz-api.xoyo.com"
local SHARE_URL = "https://jx3-sjz-api.xoyo.com"
local COVER_FILE_NAME = "ShareStationUploadCover.jpg"
local SHARE_CODE_FILE_PATH = "ShareStationDataDir"

local PostKey = {
    FACE_CHECK_VALID          = "SHARE_FACE_CHECK_VALID",
    GET_UPLOAD_CONFIG         = "SHARE_GET_UPLOAD_CONFIG",
    GET_FILE_UPLOAD_TOKEN     = "SHARE_GET_FILE_UPLOAD_TOKEN",
    DO_UPLOAD_DATA            = "SHARE_DO_UPLOAD_DATA",
    GET_COVER_UPLOAD_TOKEN    = "SHARE_GET_COVER_UPLOAD_TOKEN",
    DO_UPLOAD_COVER           = "SHARE_DO_UPLOAD_COVER",
    DOWNLOAD_DATA             = "SHARE_DOWNLOAD_DATA",
    DOWNLOAD_COVER            = "SHARE_DOWNLOAD_COVER", --看看能不能把下载接口合并一下，用同一个？可能不太行，封面每次下载完都要刷新的
    GET_UPLOAD_LIST           = "SHARE_GET_UPLOAD_LIST",
    GET_UPLOAD_LIST_BY_PAGING = "SHARE_GET_UPLOAD_LIST_BY_PAGING",
    GET_DATA                  = "SHARE_GET_DATA",
    DEL_DATA                  = "SHARE_DEL_DATA",
    UPLOAD_DATA_WITH_INFO     = "SHARE_UPLOAD_DATA_WITH_INFO",
    UPDATE_DATA_INFO          = "SHARE_UPDATE_DATA_INFO",
    FOLLOW                    = "SHARE_FOLLOW",
    UNFOLLOW                  = "SHARE_UNFOLLOW",
    GET_FOLLOW_LIST           = "SHARE_GET_FOLLOW_LIST",
    APPLY                     = "SHARE_APPLY",
    REPORT                    = "SHARE_REPORT",
    GET_RANK_LIST             = "SHARE_GET_RANK_LIST",
    GET_CREATOR_LIST          = "SHARE_GET_CREATOR_LIST",
    GET_RECOMMEND_LIST        = "SHARE_GET_RECOMMEND_LIST",
    GET_PACK_RECOMMEND_LIST   = "SHARE_GET_PACK_RECOMMEND_LIST",
}

local PostCode = {
    GET_UPLOAD_CONFIG         = "get_config",             --获取上传相关的基本信息
    GET_FILE_UPLOAD_TOKEN     = "get_upload_token",       --获取文件上传参数
    GET_COVER_UPLOAD_TOKEN    = "get_cover_upload_token", --获取封面上传参数
    GET_UPLOAD_LIST           = "datas_list",             --获得我上传的列表
    GET_UPLOAD_LIST_BY_PAGING = "datas_list_by_paging",   --分页获取我上传的列表
    GET_DATA                  = "get_data",               --通过分享码获得数据
    DEL_DATA                  = "del_datas",              --删除数据
    UPLOAD_DATA_WITH_INFO     = "upload_<D0>_with_info",  --上传数据
    UPDATE_DATA_INFO          = "update_<D0>_info",       --更新信息
    FOLLOW                    = "follow",                 --收藏数据
    UNFOLLOW                  = "unfollow",               --取消收藏
    GET_FOLLOW_LIST           = "follow_list",            --获取我的收藏列表
    APPLY                     = "apply",                  --应用数据增加热度
    REPORT                    = "report",                 --举报数据
    GET_RANK_LIST             = "rank_list",              --获取公开站数据列表
    GET_CREATOR_LIST          = "creator_list",           --获取认证作者列表
    GET_RECOMMEND_LIST        = "recommend_list",         --获取推荐列表
    GET_PACK_RECOMMEND_LIST   = "gift_recommend_list",    --获取礼物推荐列表
}

local PostUrl = {}
for key, value in pairs(PostCode) do
    local suffix = IsVersionExp() and "sjztf250722" or "sjz250722"
    PostUrl[key] = "/jx3/" .. suffix .. "/" .. value
end

local CURL_FACE_CHECK_VALID = "http://jx3-face.xoyo.com/face/validate" --检查图片是否包含人脸
local CURL_FACE_CHECK_VALID_TEST = "http://124.70.212.237/face/validate" --检查图片是否包含人脸

local CHECK_VALID_SUCCESS_CODE = 0                                  --检查是否包含人脸的成功返回码
local tDataType2Url = {
    [SHARE_DATA_TYPE.FACE] = "face",
    [SHARE_DATA_TYPE.BODY] = "body",
    [SHARE_DATA_TYPE.EXTERIOR] = "fashion",
    [SHARE_DATA_TYPE.PHOTO] = "photo",
}

local STATUS_SECCESS_CODE = 1
local STATUS_UPLOAD_MAX_CODE = -20104
local STATUS_LOGIN_INVALID = -14802 --登录态过期

local CHARGE_MONEY_EXT_POINT = 141
local ADD_HEAT_QUELIFIED_CHARGE_LIMIT = 360

local CHECK_TIME_CD = 50 --每个登录Token有效期为1分钟，提前一点更新防止频繁出现登录态过期的情况
local COVER_FILE_MAX_SIZE = 5 * 1024 * 1024 --上传图片的大小限制
local CACHE_DATA_MAX_SIZE = 10 * 1024 * 1024 --缓存文件夹大小限制
local FACE_TYPE_2_SUFFIX = {
    [FACE_TYPE.OLD] = "dat",
    [FACE_TYPE.NEW] = "ini",
}
local SUFFIX_2_FACE_TYPE = {
    ["dat"] = FACE_TYPE.OLD,
    ["ini"] = FACE_TYPE.NEW,
}
local ApplyLoginSignWebID = 3200

local function GetFaceTypeBySuffix(szSuffix)
    if szSuffix == "ini" then
        return FACE_TYPE.NEW
    elseif szSuffix == "dat" then
        return FACE_TYPE.OLD
    end
end

local function _GetCurrentTime(bIsLogin)
    local nTime = GetCurrentTime()
    if bIsLogin then
        nTime = os.time()
    end

    return nTime
end

local function GetShareCodeByURL(szUrl)
    local szShareCode, szSuffix = string.match(szUrl, "([^/]+)%.([a-zA-Z0-9]+)$")
    return szShareCode, szSuffix
end

local function IsShareCodeInList(tList, szShareCode)
    if not tList then
        return false
    end

    for nDataType, tTypeList in pairs(tList) do
        for nPos, v in ipairs(tTypeList) do
            if szShareCode == v.szShareCode then
                return true, nPos
            end
        end
    end
    return false
end

Event.Reg(ShareCodeData, "GAME_EXIT", function()
	ShareCodeData.ClearCacheData()
end)

function ShareCodeData.Init(bIsLogin)
    ShareCodeData.bIsLogin = bIsLogin

    Event.Reg(ShareCodeData, "WEB_SIGN_NOTIFY", function()
		if arg3 == 3 then
			ShareCodeData.OnLoginWebDataSignNotify()
            ShareCodeData.ExecuteAllFunc()
            ShareCodeData.nLastCheckTime = _GetCurrentTime(true)
		end
    end)

    Event.Reg(ShareCodeData, "ON_WEB_DATA_SIGN_NOTIFY", function()
		ShareCodeData.OnWebDataSignNotify()
        ShareCodeData.ExecuteAllFunc()
        ShareCodeData.nLastCheckTime = _GetCurrentTime(false)
    end)

    Event.Reg(ShareCodeData, "CURL_REQUEST_RESULT", function ()
		local szKey = arg0
		local bSuccess = arg1
		local szValue = arg2
		local uBufSize = arg3

        if szKey == PostKey.UPLOAD_DATA_WITH_INFO then
            ShareCodeData.bBusy = false
        end

        if szKey == PostKey.FACE_CHECK_VALID then
            local tInfo, szErrMsg = JsonDecode(szValue)
            if not tInfo then
                JustLog("[ERROE]ShareCodeData CURL_HttpPost JsonDecode Failed", szKey, tInfo, szErrMsg)
                return
            end

            local nRetCode = tInfo.code
            if nRetCode == CHECK_VALID_SUCCESS_CODE then
                Event.Dispatch(EventType.OnFaceCheckValidSuccess)
            elseif g_tStrings.tFaceCheckValid[nRetCode] then
                TipsHelper.ShowNormalTip(g_tStrings.tFaceCheckValid[nRetCode])
            end
            if ShareCodeData.szCheckValidCoverPath then
                Lib.RemoveFile(ShareCodeData.szCheckValidCoverPath)
                ShareCodeData.szCheckValidCoverPath = nil
            end
        end

        local szValidKey
        local nDataType
        for _, key in pairs(PostKey) do
            if string.match(szKey, key .. "(%d+)") then
                nDataType = tonumber(string.match(szKey, key .. "(%d+)"))
                if type(nDataType) == "number" then
                    szValidKey = key
                    break
                end
            end
        end
        if not szValidKey or not nDataType then
            return
        end

        if not bSuccess then
            LOG.ERROR("ShareCodeData CURL_REQUEST_RESULT FAILED!szKey:%s", szKey)
            return
        end

        local tInfo, szErrMsg = JsonDecode(szValue)
        if not tInfo or not IsTable(tInfo) or (tInfo.code and tInfo.code == STATUS_LOGIN_INVALID) then
            ShareCodeData.bBusy = false
            ShareCodeData.nLastCheckTime = nil
            if tInfo and tInfo.code and g_tStrings.tShareDataRetCode[tInfo.code] then
                TipsHelper.ShowNormalTip(g_tStrings.tShareDataRetCode[tInfo.code])
            end
            return
        end

        if szValidKey == PostKey.GET_UPLOAD_CONFIG then
            if tInfo and tInfo.code and tInfo.code == STATUS_SECCESS_CODE then
                if tInfo and tInfo.code and tInfo.code == 1 then
                    local tData = tInfo.data
                    if tData then
                        if not ShareCodeData.tUploadConfig then
                            ShareCodeData.tUploadConfig = {}
                        end
                        local bWhiteAccount = tData.white_list_account == 1
                        local nCount = tData.upload_count
                        local nUploadLimit = tData.up_load_max_limit
                        ShareCodeData.tUploadConfig[nDataType] = {
                            bWhiteAccount = bWhiteAccount, --是否为白名单账号
                            nCount = nCount,               --已上传总数
                            nUploadLimit = nUploadLimit,   --上传数量上限
                        }

                        if ShareCodeData.bNeedReqUploadList then
                            ShareCodeData.ReqGetUploadList(nDataType)
                            ShareCodeData.bNeedReqUploadList = nil
                        end
                    end
                    Event.Dispatch(EventType.OnGetShareStationUploadConfig, nDataType)
                elseif tInfo and tInfo.code and g_tStrings.tShareDataRetCode[tInfo.code] then
                    TipsHelper.ShowNormalTip(g_tStrings.tShareDataRetCode[tInfo.code])
                end
            end
        elseif szValidKey == PostKey.GET_RANK_LIST then
            if tInfo and tInfo.code and tInfo.code == 1 then
                local nTotalCount = tInfo.data.total_row
                local tList = tInfo.data.rank_list or {}
                local tRankList = {}
                for _, tData in ipairs(tList) do
                    local szShareCode = tData.share_id
                    local bDownloadCover = ShareCodeData.CheckCoverFileDownloaded(szShareCode)
                    if not bDownloadCover then
                        ShareCodeData.DoDownloadCover(nDataType, tData.cover, szShareCode)
                    end

                    table.insert(tRankList, ShareCodeData.GetFormatData(tData))
                end
                Event.Dispatch(EventType.OnGetShareStationList, nDataType, nTotalCount, tRankList)
            else
                TipsHelper.ShowNormalTip(g_tStrings.tShareDataRetCode[tInfo.code])
            end
        elseif szValidKey == PostKey.GET_CREATOR_LIST then
            if tInfo and tInfo.code and tInfo.code == 1 then
                local tList = tInfo.data.creator_list or {}
                local tCreatorList = {}
                for _, v in ipairs(tList) do
                    table.insert(tCreatorList, ShareCodeData.GetFormatCreatorData(v))
                end
                Event.Dispatch(EventType.OnGetShareStationCreatorList, nDataType, tCreatorList)
            else
                TipsHelper.ShowNormalTip(g_tStrings.tShareDataRetCode[tInfo.code])
            end
        elseif szValidKey == PostKey.GET_RECOMMEND_LIST then
            if tInfo and tInfo.code and tInfo.code == 1 then
                local tList = tInfo.data.recommend_list or {}
                local tRecommendList = {}
                for _, v in ipairs(tList) do
                    local szShareCode = v.share_id
                    local bDownloadCover = ShareCodeData.CheckCoverFileDownloaded(szShareCode)
                    if not bDownloadCover then
                        ShareCodeData.DoDownloadCover(nDataType, v.cover, szShareCode)
                    end
                    table.insert(tRecommendList, ShareCodeData.GetFormatData(v))
                end
                Event.Dispatch(EventType.OnGetShareStationRecommendList, nDataType, tRecommendList)
            else
                TipsHelper.ShowNormalTip(g_tStrings.tShareDataRetCode[tInfo.code])
            end
        elseif szValidKey == PostKey.GET_PACK_RECOMMEND_LIST then
            if tInfo and tInfo.code and tInfo.code == 1 then
                local tList = tInfo.data.recommend_list or {}
                local tPackRecommendList = {}
                for _, v in ipairs(tList) do
                    local szShareCode = v.share_id
                    local bDownloadCover = ShareCodeData.CheckCoverFileDownloaded(szShareCode)
                    if not bDownloadCover then
                        ShareCodeData.DoDownloadCover(nDataType, v.cover, szShareCode)
                    end
                    table.insert(tPackRecommendList, ShareCodeData.GetFormatData(v))
                end
                Event.Dispatch(EventType.OnGetShareStationRecommendList, nDataType, tPackRecommendList)
            else
                TipsHelper.ShowNormalTip(g_tStrings.tShareDataRetCode[tInfo.code])
            end
        elseif szValidKey == PostKey.GET_UPLOAD_LIST then
            if tInfo and tInfo.code and tInfo.code == STATUS_SECCESS_CODE then
                local tbData = tInfo.data.list or {}
                if not ShareCodeData.tbSelfDataList then
                    ShareCodeData.tbSelfDataList = {}
                end
                if not ShareCodeData.tDelayLoadSelfData then
                    ShareCodeData.tDelayLoadSelfData = {}
                end

                ShareCodeData.tbSelfDataList[nDataType] = {}
                ShareCodeData.tDelayLoadSelfData[nDataType] = {}

                for i, tbInfo in ipairs(tbData) do
                    local szShareCode = tbInfo.share_id
                    local _, szSuffix = ShareCodeData.GetShareCodeWithURL(tbInfo.file_link)

                    local szCoverFileLink = tbInfo.cover
                    if szCoverFileLink and szCoverFileLink ~= "" then
                        local bDownloadCover = ShareCodeData.CheckCoverFileDownloaded(szShareCode)
                        if not bDownloadCover then
                            ShareCodeData.DoDownloadCover(nDataType, tbInfo.cover, szShareCode)
                        end
                    end

                    -- local szFileLink = tbInfo.file_link
                    -- if szFileLink and szFileLink ~= "" then
                    --     ShareCodeData.DownloadData(nDataType, szShareCode, szFileLink)
                    -- end

                    --【我的】列表里没上传过的数据会缺字段，需要客户端解析文件读取
                    if tbInfo.body_type == 0 or tbInfo.name == "" then
                        local bDownloadData = ShareCodeData.CheckFileDownloaded(nDataType, szShareCode)
                        if not bDownloadData then
                            ShareCodeData.DoDownloadData(nDataType, tbInfo.file_link, szShareCode)
                            table.insert(ShareCodeData.tDelayLoadSelfData[nDataType], {szShareCode = szShareCode})
                        else
                            local tShareData = ShareCodeData.GetShareCodeData(szShareCode)
                            if not tShareData then
                                tShareData = ShareCodeData.LoadShareCodeData(nDataType, szShareCode, szSuffix)
                            end
                            if tShareData then
                                if nDataType == SHARE_DATA_TYPE.FACE then
                                    tbInfo.face_type = GetFaceTypeBySuffix(szSuffix)
                                end
                                
                                tbInfo.body_type = tShareData.nRoleType
                                tbInfo.name = tShareData.szFileName
                            end
                        end
                    end
                    tbInfo.nPos = i --用来按上传时间排序的
                    local tbData = ShareCodeData.GetFormatData(tbInfo)
                    tbData.bOwner = true
                    table.insert(ShareCodeData.tbSelfDataList[nDataType], tbData)
                end
                Event.Dispatch(EventType.OnUpdateSelfShareCodeList, nDataType, clone(ShareCodeData.tbSelfDataList[nDataType]))
            elseif tInfo and tInfo.code and g_tStrings.tShareDataRetCode[tInfo.code] then
                TipsHelper.ShowNormalTip(g_tStrings.tShareDataRetCode[tInfo.code])
            end
        elseif szValidKey == PostKey.GET_FILE_UPLOAD_TOKEN then
            if tInfo and tInfo.code and tInfo.code == 1 then
                local tData = tInfo.data
                if tData then
                    ShareCodeData.DoUploadData(nDataType, tData.action, tData.input_values)
                end
            elseif tInfo and tInfo.code and g_tStrings.tShareDataRetCode[tInfo.code] then
                TipsHelper.ShowNormalTip(g_tStrings.tShareDataRetCode[tInfo.code])
                ShareCodeData.bBusy = false
            end
        elseif szValidKey == PostKey.DO_UPLOAD_DATA then
            if tInfo and tInfo.code and tInfo.code == STATUS_SECCESS_CODE then
                local tData = tInfo.data
                if tData then
                    ShareCodeData.szUploadDataFileID = tData.file_id
                end

                if ShareCodeData.szUploadFilePath then
                    Lib.RemoveFile(ShareCodeData.szUploadFilePath)
                    ShareCodeData.szUploadFilePath = nil
                end

                if ShareCodeData.szUploadDataFileID and ShareCodeData.szUploadCoverFileID then
                    ShareCodeData.ReqUploadData(nDataType)
                    ShareCodeData.szUploadDataFileID = nil
                    ShareCodeData.szUploadCoverFileID = nil
                    ShareCodeData.nUploadDataVersion = nil
                end
            else
                TipsHelper.ShowNormalTip(g_tStrings.STR_FACE_CODE_UPLOAD_FAILED)
            end
            ShareCodeData.bBusy = false
        elseif szValidKey == PostKey.GET_COVER_UPLOAD_TOKEN then
            if tInfo and tInfo.code and tInfo.code == 1 then
                local tData = tInfo.data
                if tData then
                    ShareCodeData.szUploadCoverLink = tData.action
                    ShareCodeData.tUploadCoverToken = tData.input_values
                    if ShareCodeData.fnSaveCover then
                        ShareCodeData.fnSaveCover(function(szCoverFilePath)
                            ShareCodeData.DoUploadCover(ShareCodeData.nUploadDataType, ShareCodeData.szUploadCoverLink, ShareCodeData.tUploadCoverToken, szCoverFilePath)
                        end)
                    end
                end
            elseif tInfo and tInfo.code and g_tStrings.tShareDataRetCode[tInfo.code] then
                TipsHelper.ShowNormalTip(g_tStrings.tShareDataRetCode[tInfo.code])
            end
        elseif szValidKey == PostKey.DO_UPLOAD_COVER then
            if tInfo and tInfo.code and tInfo.code == 1 then
                local tData = tInfo.data
                if tData then
                    ShareCodeData.szUploadCoverFileID = tData.file_id
                end
                if ShareCodeData.szCoverFilePath then --清除本地封面文件
                    Lib.RemoveFile(ShareCodeData.szCoverFilePath)
                    ShareCodeData.szCoverFilePath = nil
                end

                if ShareCodeData.szUploadDataFileID and ShareCodeData.szUploadCoverFileID then --上传新作品
                    ShareCodeData.ReqUploadData(nDataType)
                    ShareCodeData.szUploadDataFileID = nil
                    ShareCodeData.szUploadCoverFileID = nil
                elseif ShareCodeData.szUpdateShareCode then --更新已有作品的封面信息
                    ShareCodeData.ReqUpdateData(nDataType)
                    ShareCodeData.szUpdateShareCode = nil
                end

                if ShareCodeData.szCoverFilePath then
                    Lib.RemoveFile(ShareCodeData.szCoverFilePath)
                    ShareCodeData.szCoverFilePath = nil
                end
            else
                TipsHelper.ShowNormalTip(g_tStrings.tShareDataRetCode[tInfo.code])
            end
            ShareCodeData.bBusy = false
        elseif szValidKey == PostKey.UPLOAD_DATA_WITH_INFO then
            if tInfo and tInfo.code and tInfo.code == 1 then
                local tData = tInfo.data
                if tData and ShareCodeData.bCopyToClip then
                    local szShareID = tostring(tData.share_id)
                    SetClipboard(szShareID)
                    TipsHelper.ShowNormalTip(g_tStrings.STR_SHARE_STATION_UPLOAD_WAIT_COPY)
                    ShareCodeData.bCopyToClip = nil
                elseif tData then
                    TipsHelper.ShowNormalTip(g_tStrings.STR_SHARE_STATION_UPLOAD_WAIT)
                end
                ShareCodeData.tUploadFileData = nil
                ShareCodeData.tUploadInfo = nil
                ShareCodeData.fnSaveCover = nil
                ShareCodeData.ReqGetConfig(nDataType)
            elseif tInfo and tInfo.code and g_tStrings.tShareDataRetCode[tInfo.code] then
                TipsHelper.ShowNormalTip(g_tStrings.tShareDataRetCode[tInfo.code])
            end
        elseif szValidKey == PostKey.UPDATE_DATA_INFO then
            if tInfo and tInfo.code and tInfo.code == 1 then
                local tData = tInfo.data
                if tData then
                    local szShareID = tostring(tData.share_id)
                    Event.Dispatch(EventType.OnUpdateShareCodeInfo, nDataType, szShareID)
                    if szShareID == ShareCodeData.szUpdateShareCode then
                        ShareCodeData.tModifyInfo = nil
                        ShareCodeData.szUpdateShareCode = nil
                    end
                end
                TipsHelper.ShowNormalTip(g_tStrings.STR_SHARE_STATION_UPDATE_INFO_SUCCESS)
                ShareCodeData.ReqGetUploadList(nDataType)
            else
                TipsHelper.ShowNormalTip(g_tStrings.tShareDataRetCode[tInfo.code])
            end
        elseif szValidKey == PostKey.GET_DATA then
            if tInfo and tInfo.code and tInfo.code == 1 then
                local tData = tInfo.data
                if tData then
                    local szShareCode = tData.share_id
                    local bHad, szSuffix = ShareCodeData.CheckFileDownloaded(nDataType, szShareCode)
                    if not bHad then
                        ShareCodeData.DoDownloadData(nDataType, tData.file_link, szShareCode)
                    else
                        if not ShareCodeData.GetShareCodeData(szShareCode) then
                            ShareCodeData.LoadShareCodeData(nDataType, szShareCode, szSuffix)
                        end
                        local szShareCodeDir = ShareCodeData.GetShareFolderDir(true)
                        local _, szSuffix = GetShareCodeByURL(tData.file_link)
                        local szFilePath = string.format("%s/%s.%s", szShareCodeDir, szShareCode, szSuffix)
                        Event.Dispatch(EventType.OnDownloadShareCodeData, bSuccess, szShareCode, szFilePath, nDataType)
                        ShareCodeData.szCurGetShareCode = nil
                    end
                end
            elseif tInfo and tInfo.code and g_tStrings.tShareDataRetCode[tInfo.code] then
                TipsHelper.ShowNormalTip(g_tStrings.tShareDataRetCode[tInfo.code])
            end
			ShareCodeData.bBusy = false
        elseif szValidKey == PostKey.DEL_DATA then
            if tInfo and tInfo.code and tInfo.code == STATUS_SECCESS_CODE then
                ShareCodeData.ReqGetConfig(nDataType)
                ShareCodeData.ReqGetUploadList(nDataType)
                TipsHelper.ShowNormalTip(g_tStrings.STR_SHARE_STATION_DELETE_SUCCESS)
                Event.Dispatch(EventType.OnDeleteShareCodeData)
            elseif tInfo and tInfo.code and g_tStrings.tShareDataRetCode[tInfo.code] then
                TipsHelper.ShowNormalTip(g_tStrings.tShareDataRetCode[tInfo.code])
            end
        elseif szValidKey == PostKey.FOLLOW then
            if tInfo and tInfo.code and tInfo.code == 1 then
                ShareCodeData.ReqGetCollectList(nDataType)
                ShareCodeData.szCollectShareCode = nil

                if UIMgr.GetView(VIEW_ID.PanelShareStation) then
                    TipsHelper.ShowNormalTip(g_tStrings.STR_SHARE_STATION_COLLECT_SUCCESS)
                else
                    TipsHelper.ShowNormalTip(g_tStrings.STR_SHARE_STATION_COLLECT_SUCCESS_2)
                end
            else
                TipsHelper.ShowNormalTip(g_tStrings.tShareDataRetCode[tInfo.code])
            end
        elseif szValidKey == PostKey.UNFOLLOW then
            if tInfo and tInfo.code and tInfo.code == 1 then
                local szShareCode = tInfo.data.share_id
                --删除本地数据 -- VK没法删，因为本次开启游戏后如果有下载，后继不会再刷新其存在
                -- local _, _, szDataFilePath = ShareCodeData.CheckFileDownloaded(nDataType, szShareCode)
                -- if szDataFilePath then
                --     Lib.RemoveFile(szDataFilePath)
                -- end

                -- local _, szCoverFilePath = ShareCodeData.CheckCoverFileDownloaded(szShareCode)
                -- if szCoverFilePath then
                --     Lib.RemoveFile(szCoverFilePath)
                -- end

                ShareCodeData.ReqGetCollectList(nDataType)
                TipsHelper.ShowNormalTip(g_tStrings.STR_SHARE_STATION_UNCOLLECT_SUCCESS)
            else
                TipsHelper.ShowNormalTip(g_tStrings.tShareDataRetCode[tInfo.code])
            end
        elseif szValidKey == PostKey.GET_FOLLOW_LIST then
            if tInfo and tInfo.code and tInfo.code == 1 then
                local tList = tInfo.data.follow_list or {}
                local tDelayLoadCover = {}
                if not ShareCodeData.tCollectDataList then
                    ShareCodeData.tCollectDataList = {}
                end
                ShareCodeData.tCollectDataList[nDataType] = {}
                for i, tDataInfo in ipairs(tList) do
                    local szShareCode = tDataInfo.share_id
                    local szCoverLink = tDataInfo.cover
                    if szShareCode and szShareCode ~= "" and szCoverLink and szCoverLink ~= "" then
                        local bDownloadCover = ShareCodeData.CheckCoverFileDownloaded(szShareCode)
                        if not bDownloadCover then
                            ShareCodeData.DoDownloadCover(nDataType, szCoverLink, szShareCode)
                            table.insert(tDelayLoadCover, szShareCode)
                        end
                    end

                    -- local szFileLink = tDataInfo.file_link
                    -- if szFileLink and szFileLink ~= "" then
                    --     ShareCodeData.DownloadData(nDataType, szShareCode, szFileLink)
                    -- end
                    tDataInfo.nPos = i --用来按收藏时间排序的

                    local tbData = ShareCodeData.GetFormatData(tDataInfo)
                    tbData.bCollect = true
                    table.insert(ShareCodeData.tCollectDataList[nDataType], tbData)
                end
                Event.Dispatch(EventType.OnUpdateCollectShareCodeList, nDataType, clone(ShareCodeData.tCollectDataList[nDataType]), tDelayLoadCover)
            else
                TipsHelper.ShowNormalTip(g_tStrings.tShareDataRetCode[tInfo.code])
            end
        -- elseif szValidKey == PostKey.DEL_BATCH_FACE then
        --     if tInfo and tInfo.code and tInfo.code == 1 then
        --         TipsHelper.ShowNormalTip("已删除云端脸型。")
        --     elseif tInfo and tInfo.code and g_tStrings.tShareDataRetCode[tInfo.code] then
        --         TipsHelper.ShowNormalTip(g_tStrings.tShareDataRetCode[tInfo.code])
        --     end
        -- elseif szValidKey == PostKey.GET_FACE_RANK_LIST then
        --     if tInfo and tInfo.code and tInfo.code == 1 then
        --         local nTotalCount = tInfo.data.total_row
        --         local tList = tInfo.data.rank_list or {}
        --         local tRankList = {}
        --         for _, tDataInfo in ipairs(tList) do
        --             local szShareCode = tDataInfo.share_id
        --             local bDownloadCover = ShareCodeData.CheckCoverFileDownloaded(szShareCode)
        --             if not bDownloadCover then
        --                 ShareCodeData.DoDownloadCover(tDataInfo.cover, szShareCode)
        --             end

        --             table.insert(tRankList, ShareCodeData.GetFormatData(tDataInfo))
        --         end
        --         Event.Dispatch(EventType.OnGetDataStationList, nTotalCount, tRankList)
        --     else
        --         TipsHelper.ShowNormalTip(g_tStrings.tShareDataRetCode[tInfo.code])
        --     end
        elseif szValidKey == PostKey.APPLY then
            -- if tInfo and tInfo.code and tInfo.code == 1 then
            --     TipsHelper.ShowNormalTip(g_tStrings.tShareDataRetCode[tInfo.code])
            -- end
        elseif szValidKey == PostKey.REPORT then
            if tInfo and tInfo.code and tInfo.code == 1 then
                TipsHelper.ShowNormalTip(g_tStrings.STR_SHARE_STATION_REPORT_SUCCESS)
            else
                TipsHelper.ShowNormalTip(g_tStrings.tShareDataRetCode[tInfo.code])
            end
        end

        -- LOG.TABLE({tInfo = tInfo, szKey = szKey})
        Event.Dispatch(EventType.OnShareCodeRsp, szValidKey, tInfo)
    end)

    Event.Reg(ShareCodeData, "CURL_DOWNLOAD_RESULT", function ()
        local szKey = arg0
		local bSuccess = arg1
        local szFilePath = ""
        if string.find(szKey, PostKey.DOWNLOAD_DATA) then
            local szFilePathID, szDataType = string.match(szKey, PostKey.DOWNLOAD_DATA .. "_(%d+)_(%d+)")
            local nDataType = tonumber(szDataType)
            if szFilePathID and ShareCodeData.tDownloadDataPath[szFilePathID] then
                szFilePath = ShareCodeData.tDownloadDataPath[szFilePathID]
            else
                return
            end

            local szShareCode, szSuffix
            if bSuccess then
                szFilePath = string.gsub(szFilePath, "\\", "/")
                szShareCode, szSuffix = ShareCodeData.GetShareCodeWithURL(szFilePath)
                local tData = ShareCodeData.LoadShareCodeData(nDataType, szShareCode, szSuffix)
                if tData then
                    local tDelayLoadSelfData = ShareCodeData.tDelayLoadSelfData
                    local bDelayLoad, nPos = IsShareCodeInList(tDelayLoadSelfData, szShareCode)
                    if bDelayLoad and ShareCodeData.tbSelfDataListSelfDataList[nDataType] then
                        for _, v in ipairs(ShareCodeData.tbSelfDataList) do
                            if v.szShareCode == szShareCode then
                                if nDataType == SHARE_DATA_TYPE.FACE then
                                    v.nFaceType = v.bNewFace and FACE_TYPE.NEW or FACE_TYPE.OLD
                                    v.nSubType = v.nFaceType
                                elseif nDataType == SHARE_DATA_TYPE.BODY then
                                    v.nSubType = 0
                                end
                                if v.bNewData then
                                    v.szSuffix = FACE_TYPE_2_SUFFIX[FACE_TYPE.NEW]
                                else
                                    v.szSuffix = FACE_TYPE_2_SUFFIX[FACE_TYPE.OLD]
                                end
                                v.nRoleType = tData.nRoleType
                                v.szDataName = tData.szFileName
                                break
                            end
                        end
                        table.remove(tDelayLoadSelfData[nDataType], nPos)
                    end

                    if not ShareCodeData.tDownloadTime then
                        ShareCodeData.tDownloadTime = ShareCodeData.GetDownloadTimeData()
                    end

                    local szFileName = szShareCode .. "." .. szSuffix
                    ShareCodeData.tDownloadTime[szFileName] = _GetCurrentTime(ShareCodeData.bIsLogin)
                    LOG.INFO("下载作品成功！szFilePath:".. tostring(szFilePath))
                end
            else
                LOG.ERROR("下载作品失败！")
            end

            if szFilePath and szShareCode then
                Event.Dispatch(EventType.OnDownloadShareCodeData, bSuccess, szShareCode, szFilePath, nDataType)
            end
            if ShareCodeData.szCurGetShareCode == szShareCode then
                ShareCodeData.szCurGetShareCode = nil
            end
        elseif string.find(szKey, PostKey.DOWNLOAD_COVER) then
            local szFilePathID, szDataType = string.match(szKey, PostKey.DOWNLOAD_COVER .. "_(%d+)_(%d+)")
            local nDataType = tonumber(szDataType)
            if szFilePathID and ShareCodeData.tbDownloadCoverPath and ShareCodeData.tbDownloadCoverPath[szFilePathID] then
                szFilePath = ShareCodeData.tbDownloadCoverPath[szFilePathID]
                szFilePath = string.gsub(szFilePath, "\\", "/")
            else
                return
            end

            local szShareCode = ShareCodeData.GetShareCodeWithURL(szFilePath)
            if not bSuccess then
                Log("[ERROR]ShareCodeData Download CoverFile Fail")
            else
                if not ShareCodeData.tDownloadTime then
                    ShareCodeData.tDownloadTime = ShareCodeData.GetDownloadTimeData()
                end

                local szFileName = szShareCode .. ".jpg"
                ShareCodeData.tDownloadTime[szFileName] = _GetCurrentTime(ShareCodeData.bIsLogin)
            end

            if szFilePath and szShareCode then
                Event.Dispatch(EventType.OnDownloadShareCodeCover, bSuccess, szShareCode, szFilePath)
            end
            if ShareCodeData.szCurGetShareCode == szShareCode then
                ShareCodeData.bBusy = false
            end
        end

    end)
end

function ShareCodeData.UnInit()
    ShareCodeData.bBusy = nil
    ShareCodeData.bIsLogin = nil
    ShareCodeData.szFileName = nil
    ShareCodeData.szFilePath = nil
    ShareCodeData.szCurGetShareCode = nil
    ShareCodeData.tUploadConfig = nil
    ShareCodeData.nLastCheckTime = nil

    -- ShareCodeData.szDefaultParam = nil
    ShareCodeData.szUploadCoverFileID = nil
    ShareCodeData.szUploadDataFileID = nil
    ShareCodeData.szCoverFileName = nil
    ShareCodeData.szCoverFilePath = nil
    ShareCodeData.tUploadInfo = nil
    ShareCodeData.tModifyInfo = nil
    ShareCodeData.szUpdateShareCode = nil
    ShareCodeData.szCollectShareCode = nil
    ShareCodeData.tbFunAction = nil
end

function ShareCodeData.GetURL()
	local bTestMode = IsDebugClient() or IsVersionExp()
    if bTestMode then
        return SHARE_URL_TEST
    end

    return SHARE_URL
end

function ShareCodeData.ExecuteAllFunc()
    if not ShareCodeData.tbFunAction then
        return
    end
    for _, v in ipairs(ShareCodeData.tbFunAction) do
        local fnAction = v[1]
        local tParams = v[2]
        if tParams and #tParams > 0 then
            fnAction(unpack(tParams))
        else
            fnAction()
        end
    end
    ShareCodeData.tbFunAction = nil
end

function ShareCodeData.CheckSignAndExecute(bLogin, fnAction, ...)
    --校验登录Token是否还在一分钟有效期内，不在的话需要重新申请
    local bLogin = bLogin or ShareCodeData.bIsLogin
    local nTime = _GetCurrentTime(bLogin)

    if not ShareCodeData.nLastCheckTime or (nTime - ShareCodeData.nLastCheckTime > CHECK_TIME_CD) or not ShareCodeData.szDefaultParam then
        if not ShareCodeData.tbFunAction then
            ShareCodeData.tbFunAction = {}
        end

        table.insert(ShareCodeData.tbFunAction, {fnAction, {...}})
        ShareCodeData.LoginAccount(bLogin)
    else
        if fnAction then
            fnAction(...) --基于现有的params来调用fnAction
        end
    end
end

function ShareCodeData.LoginAccount(bIsLogin)
    if bIsLogin then
        WebUrl.ApplyLoginSignWeb(ApplyLoginSignWebID, 3)
    else
        WebUrl.ApplySignWeb(ApplyLoginSignWebID, 2)
    end
end

function ShareCodeData.ReqGetUploadList(nDataType)
    if not nDataType then
        LOG.ERROR("ShareCodeData ReqGetUploadList nDataType is nil")
        return
    end

    if not ShareCodeData.szDefaultParam then
        LOG.ERROR("ShareCodeData.ReqGetUploadList Error! szDefaultParam is nil")
        return
    end

    local szUrl = ShareCodeData.GetURL()
    local szPostUrl = string.format("%s%s?data_type=%d&params=%s",
    szUrl,
    PostUrl.GET_UPLOAD_LIST,
    nDataType,
    ShareCodeData.szDefaultParam
    )
    CURL_HttpPost(PostKey.GET_UPLOAD_LIST .. nDataType, szPostUrl, nil, true, 60, 60)
end

function ShareCodeData.ReqGetFileUploadToken(nDataType, szSuffix)
    if not nDataType or not szSuffix then
        JustLog("ShareCodeData ReqGetFileUploadToken", nDataType, szSuffix)
        return
    end

    ShareCodeData.bBusy = true

    local szUrl = ShareCodeData.GetURL()
    local szPostUrl = string.format("%s%s?suffix=%s&data_type=%d&params=%s",
        szUrl,
        PostUrl.GET_FILE_UPLOAD_TOKEN,
        szSuffix,
        nDataType,
        ShareCodeData.szDefaultParam
    )
    CURL_HttpPost(PostKey.GET_FILE_UPLOAD_TOKEN .. nDataType, szPostUrl, nil, true, 60, 60)
end

--获取封面上传参数
function ShareCodeData.ReqGetCoverUploadToken(nDataType)
    if not nDataType then
        JustLog("ShareCodeData ReqGetCoverUploadToken nDataType", nDataType)
        return
    end

    local szUrl = ShareCodeData.GetURL()
    local szPostUrl = string.format("%s%s?data_type=%d&params=%s",
        szUrl,
        PostUrl.GET_COVER_UPLOAD_TOKEN,
        nDataType,
        ShareCodeData.szDefaultParam
    )
    CURL_HttpPost(PostKey.GET_COVER_UPLOAD_TOKEN .. nDataType, szPostUrl, nil, true, 60, 60)
end

function ShareCodeData.ReqUploadData(nDataType)
    local szDataFileID = ShareCodeData.szUploadDataFileID
    local szCoverFileID = ShareCodeData.szUploadCoverFileID
    local nVersion = ShareCodeData.nUploadDataVersion
    local tInfo = ShareCodeData.tUploadInfo
    if not nDataType or not tInfo or not szDataFileID or not szCoverFileID or not nVersion then
        JustLog("ShareCodeData ReqUploadData Fail", nDataType, szDataFileID, szCoverFileID, nVersion, tInfo)
        return
    end

    ShareCodeData.nUploadRoleType = tInfo.nRoleType --如果上传数量已达上限，用作提示

    local szUrl = ShareCodeData.GetURL()
    local szPostUrl = string.format(
        "%s%s?name=%s&desc=%s&file_id=%s&cover_file_id=%s&open_status=%d&body_type=%d&tags=%s&version=%d&upload_source=%s&params=%s",
        szUrl,
        FormatString(PostUrl.UPLOAD_DATA_WITH_INFO, tDataType2Url[nDataType]),
        UrlEncode(tInfo.szName),
        UrlEncode(tInfo.szDesc),
        szDataFileID,
        szCoverFileID,
        tInfo.nOpenStatus,
        tInfo.nRoleType,
        table.concat(tInfo.tTag, ","),
        nVersion,
        "vk",
        ShareCodeData.szDefaultParam
    )

    if nDataType == SHARE_DATA_TYPE.FACE then
        local nFaceType = GetFaceTypeBySuffix(tInfo.szSuffix)
        szPostUrl = szPostUrl .. string.format("&face_type=%d", nFaceType)
    elseif nDataType == SHARE_DATA_TYPE.EXTERIOR then
        if tInfo.dwForceID then
            szPostUrl = szPostUrl .. string.format("&force_id=%d", tInfo.dwForceID)
        end

        --防止网页和端内表格索引对不上，全部转换成字符串键值确保JsonEncode后不会有歧义
        local tFilterData = tInfo.tFilterData
        for k, v in pairs(tFilterData) do
            if IsNumber(k) then
                tFilterData[tostring(k)] = v
                tFilterData[k] = nil
            end
        end
        szPostUrl = szPostUrl .. string.format("&filter_data=%s", JsonEncode(tFilterData))
    elseif nDataType == SHARE_DATA_TYPE.PHOTO then
        if tInfo.dwForceID then
            szPostUrl = szPostUrl .. string.format("&force_id=%d", tInfo.dwForceID)
        end
        szPostUrl = szPostUrl .. string.format("&photo_map_type=%d&photo_map_id=%d&cover_size_type=%d",
            tInfo.nPhotoMapType,
            tInfo.dwPhotoMapID,
            tInfo.nPhotoSizeType
        )
    end

    CURL_HttpPost(PostKey.UPLOAD_DATA_WITH_INFO .. nDataType, szPostUrl, nil, true, 60, 60)
end

function ShareCodeData.ReqUpdateData(nDataType)
    local tModifyInfo = ShareCodeData.tModifyInfo or {}
    local szShareCode = ShareCodeData.szUpdateShareCode

    local szUrl = ShareCodeData.GetURL()
    local szPostUrl = string.format("%s%s?share_id=%s&params=%s",
        szUrl,
        FormatString(PostUrl.UPDATE_DATA_INFO, tDataType2Url[nDataType]),
        szShareCode,
        ShareCodeData.szDefaultParam
    )

    local szCoverFileID = ShareCodeData.szUploadCoverFileID
    if szCoverFileID then --带着封面的更新，说明云端上没有初始数据，需要补充
        szPostUrl = szPostUrl .. string.format("&cover_file_id=%s", szCoverFileID)

        if tModifyInfo.szName and tModifyInfo.szName ~= "" then
            szPostUrl = szPostUrl .. string.format("&name=%s", UrlEncode(tModifyInfo.szName))
        end

        if tModifyInfo.nRoleType then
            szPostUrl = szPostUrl .. string.format("&body_type=%s", tModifyInfo.nRoleType)
        end

        if tModifyInfo.nVersion then
            szPostUrl = szPostUrl .. string.format("&version=%d", tModifyInfo.nVersion)
        end

        if tModifyInfo.szUploadSource then
            szPostUrl = szPostUrl .. string.format("&upload_source=%s", tModifyInfo.szUploadSource)
        end

        if nDataType == SHARE_DATA_TYPE.FACE then
            local nFaceType = GetFaceTypeBySuffix(tModifyInfo.szSuffix)
            if nFaceType then
                szPostUrl = szPostUrl .. string.format("&face_type=%s", nFaceType)
            end
        end
    end

    if tModifyInfo.szDesc then
        szPostUrl = szPostUrl .. string.format("&desc=%s", UrlEncode(tModifyInfo.szDesc))
    end

    if tModifyInfo.nOpenStatus then
        szPostUrl = szPostUrl .. string.format("&open_status=%d", tModifyInfo.nOpenStatus)
    end

    if tModifyInfo.tTag then
        szPostUrl = szPostUrl .. string.format("&tags=%s", table.concat(tModifyInfo.tTag, ","))
    end

    CURL_HttpPost(PostKey.UPDATE_DATA_INFO .. nDataType, szPostUrl, nil, true, 60, 60)
end

function ShareCodeData.ReqGetData(nDataType, szShareCode)
    if not ShareCodeData.szDefaultParam or not szShareCode or ShareCodeData.bBusy then
        LOG.ERROR(string.format("[ERROR]ShareCodeData ReqGetData Fail:LoginParam=%s,ShareCode=%s,BusyState=%s", 
                                    ShareCodeData.szDefaultParam, szShareCode, tostring(ShareCodeData.bBusy)))
        return
    end

    if string.is_nil(szShareCode) then
        LOG.ERROR("ShareCodeData.ReqGetData Error! szShareCode is nil")
        return
    end

    if ShareCodeData.bBusy then
        return
    end

    ShareCodeData.bBusy = true

    local szUrl = ShareCodeData.GetURL()
    local szPostUrl = string.format("%s%s?data_type=%d&share_id=%s&params=%s",
        szUrl,
        PostUrl.GET_DATA,
        nDataType,
        szShareCode,
        ShareCodeData.szDefaultParam
    )
    CURL_HttpPost(PostKey.GET_DATA .. nDataType, szPostUrl, {}, true, 60, 60)
    ShareCodeData.szCurGetShareCode = szShareCode
end

function ShareCodeData.ReqDelData(nDataType, tDelList)
    if not ShareCodeData.szDefaultParam or not nDataType or not tDelList or table.is_empty(tDelList) then
        LOG.ERROR(string.format("[ERROR]ShareCodeData ReqDelData Fail:LoginParam=%s,DataType=%d,DelList=%s",
                                    ShareCodeData.szDefaultParam, nDataType, JsonEncode(tDelList)))
        return
    end

    if table.is_empty(tDelList) then
        LOG.ERROR("ShareCodeData.ReqDelData Error! tDelList is empty")
        return
    end

    local szCodeList = table.concat(tDelList, ",")
    local szUrl = ShareCodeData.GetURL()
    local szPostUrl = string.format("%s%s?data_type=%d&share_ids=%s&params=%s",
        szUrl,
        PostUrl.DEL_DATA,
        nDataType,
        szCodeList,
        ShareCodeData.szDefaultParam
    )
    CURL_HttpPost(PostKey.DEL_DATA .. nDataType, szPostUrl, {}, true, 60, 60)
end

function ShareCodeData.ReqGetConfig(nDataType)
    if not nDataType then
        JustLog("ShareCodeData ReqGetConfig nDataType", nDataType)
        return
    end

    local szUrl = ShareCodeData.GetURL()
    local szPostUrl = string.format("%s%s?data_type=%d&params=%s",
        szUrl,
        PostUrl.GET_UPLOAD_CONFIG,
        nDataType,
        ShareCodeData.szDefaultParam
    )
    CURL_HttpPost(PostKey.GET_UPLOAD_CONFIG .. nDataType, szPostUrl, nil, true, 60, 60)
end


function ShareCodeData.ReqGetDataListByPage(nDataType, nPage, nPageSize)
    if not ShareCodeData.szDefaultParam  then
        LOG.ERROR(string.format("[ERROR]ShareCodeData ReqGetDataListByPage Fail:LoginParam=%s",
                                    ShareCodeData.szDefaultParam))
        return
    end

    if not nPage or not nPageSize then
        LOG.ERROR("ShareCodeData.ReqGetDataListByPage Error! nPage or nPageSize is nil")
        return
    end

    local szUrl = ShareCodeData.GetURL()
    local szPostUrl = string.format("%s%s?data_type=%d&page=%d&page_size=%d&params=%s",
        szUrl,
        PostUrl.GET_UPLOAD_LIST_BY_PAGING,
        nDataType,
        nPage,
        nPageSize,
        ShareCodeData.szDefaultParam
    )
    CURL_HttpPost(PostKey.GET_UPLOAD_LIST_BY_PAGING, szPostUrl, {}, true, 60, 60)
end

------------------捏脸站相关----------------------
function ShareCodeData.ReqCollectData(nDataType, szShareCode, bAddHeat)
    if not nDataType or not szShareCode then
        JustLog("ShareCodeData ReqCollectData Fail", nDataType, szShareCode)
        return
    end

    ShareCodeData.szCollectShareCode = szShareCode

    local szUrl = ShareCodeData.GetURL()
    local szPostUrl = string.format("%s%s?data_type=%d&share_id=%s&inc_heat=%d&params=%s",
        szUrl,
        PostUrl.FOLLOW,
        nDataType,
        szShareCode,
        bAddHeat and 1 or 0,
        ShareCodeData.szDefaultParam
    )
    CURL_HttpPost(PostKey.FOLLOW .. nDataType, szPostUrl, nil, true, 60, 60)
end

function ShareCodeData.ReqGetCollectList(nDataType)
    if not nDataType then
        JustLog("ShareCodeData ReqGetCollectList nDataType", nDataType)
        return
    end
    local szUrl = ShareCodeData.GetURL()
    local szPostUrl = string.format("%s%s?data_type=%d&params=%s",
        szUrl,
        PostUrl.GET_FOLLOW_LIST,
        nDataType,
        ShareCodeData.szDefaultParam
    )
    CURL_HttpPost(PostKey.GET_FOLLOW_LIST .. nDataType, szPostUrl, nil, true, 60, 60)
end

function ShareCodeData.ReqUnCollectData(nDataType, szShareCode)
    if not nDataType or not szShareCode then
        JustLog("ShareCodeData ReqUnCollectData Fail", nDataType, szShareCode)
        return
    end

    local szUrl = ShareCodeData.GetURL()
    local szPostUrl = string.format("%s%s?data_type=%d&share_id=%s&params=%s",
        szUrl,
        PostUrl.UNFOLLOW,
        nDataType,
        szShareCode,
        ShareCodeData.szDefaultParam
    )
    CURL_HttpPost(PostKey.UNFOLLOW .. nDataType, szPostUrl, nil, true, 60, 60)
end

function ShareCodeData.ReqApplyData(nDataType, szShareCode)
    if not nDataType or not szShareCode then
        JustLog("ShareCodeData ReqApplyData Fail", nDataType, szShareCode)
        return
    end

    local szUrl = ShareCodeData.GetURL()
    local szPostUrl = string.format("%s%s?data_type=%d&share_id=%s&inc_heat=%d&params=%s",
        szUrl,
        PostUrl.APPLY,
        nDataType,
        szShareCode,
        1,
        ShareCodeData.szDefaultParam
    )
    CURL_HttpPost(PostKey.APPLY .. nDataType, szPostUrl, nil, true, 60, 60)
end

function ShareCodeData.ReqReportData(nDataType, szShareCode, szReportReason)
    if not nDataType or not szShareCode or not szReportReason then
        JustLog("ShareCodeData ReqReportData Fail", nDataType, szShareCode, szReportReason)
        return
    end

    local szUrl = ShareCodeData.GetURL()
    local szPostUrl = string.format("%s%s?data_type=%d&share_id=%s&reason=%s&params=%s",
        szUrl,
        PostUrl.REPORT,
        nDataType,
        szShareCode,
        UrlEncode(szReportReason),
        ShareCodeData.szDefaultParam
    )
    CURL_HttpPost(PostKey.REPORT .. nDataType, szPostUrl, nil, true, 60, 60)
end

function ShareCodeData.ReqGetShareStationData(nDataType, szCreateRange, nPage, nPageSize, szRankType, tFilter)
    if not nDataType or not nPage or not nPageSize or not szRankType then
        JustLog("ShareCodeData ReqGetShareStationData Fail", nDataType, nPage, nPageSize, szRankType, tFilter)
        return
    end

    local szUrl = ShareCodeData.GetURL()
    local szPostUrl = string.format("%s%s?params=%s",
        szUrl,
        PostUrl.GET_RANK_LIST,
        ShareCodeData.szDefaultParam
    )

    local tJsonFilter = {
        ["data_type"] = tostring(nDataType),
        ["page"] = tostring(nPage),
        ["page_size"] = tostring(nPageSize),
        ["rank_type"] = szRankType,
        ["search_filter_data"] = "",
    }

    if szCreateRange and szCreateRange ~= "" then
        tJsonFilter["create_range"] = szCreateRange
    end

    local tTypeFilter = {}
    tTypeFilter.upload_source = tFilter.szUploadSource

    if tFilter.nRoleType and tFilter.nRoleType ~= -1 then
        tTypeFilter.body_type = tFilter.nRoleType
    end

    if tFilter.szSearch and tFilter.szSearch ~= "" then
        tTypeFilter.keyword = UrlEncode(tFilter.szSearch)
    end
    if tFilter.tTag and #tFilter.tTag > 0 then
        tTypeFilter.tags = table.concat(tFilter.tTag, ",")
    end
    if tFilter.szAccount and tFilter.szAccount ~= "" then
        tTypeFilter.account = tFilter.szAccount
    end

    local nSearchType = tFilter.nSearchType
    local szSearch = tFilter.szSearch
    if nSearchType and szSearch then
        if nSearchType == SHARE_SEARCH_TYPE.NAME and szSearch ~= "" then
            tTypeFilter.name = szSearch
        elseif nSearchType == SHARE_SEARCH_TYPE.CODE and szSearch ~= "" then
            tTypeFilter.share_id = szSearch
        end
    end

    -- 其他筛选的前提是选择筛选【作品】，如果是筛选非空的【分享码】则无视以下限制
    if nSearchType == SHARE_SEARCH_TYPE.NAME or not szSearch or szSearch == "" then
        if szCreateRange and szCreateRange ~= "" then
            tJsonFilter["create_range"] = szCreateRange
        end

        if tFilter.nRoleType and tFilter.nRoleType ~= -1 then
            tTypeFilter.body_type = tFilter.nRoleType
        end

        if tFilter.szUploadSource and tFilter.szUploadSource ~= "" then
            tTypeFilter.upload_source = tFilter.szUploadSource
        end

        if tFilter.tTag and #tFilter.tTag > 0 then
            tTypeFilter.tags = table.concat(tFilter.tTag, ",")
        end

        if tFilter.szAccount and tFilter.szAccount ~= "" then
            tTypeFilter.account = tFilter.szAccount
        end

        if nDataType == SHARE_DATA_TYPE.FACE then --捏脸站
            tTypeFilter.face_type = tFilter.nFaceType
        elseif nDataType == SHARE_DATA_TYPE.EXTERIOR then
            if tFilter.tFilterExterior and not table.is_empty(tFilter.tFilterExterior) then
                -- --防止网页和端内表格索引对不上，全部转换成字符串键值确保JsonEncode后不会有歧义
                local tStrKeyFilter = {}
                local bFilterExteriorID = false
                for nRes, v in pairs(tFilter.tFilterExterior) do
                    if not bFilterExteriorID and not ShareExteriorData.IsFilterFlagKey(nRes) and type(v) == "table" then
                        for _, dwID in pairs(v) do
                            if dwID > 0 then
                                bFilterExteriorID = true
                            end
                        end
                    end

                    tStrKeyFilter[tostring(nRes)] = v
                end
                tTypeFilter.filter_data = tStrKeyFilter
            end
            -- tTypeFilter.force_id = tFilter.dwForceID --门派筛选，暂时不做限制
        elseif nDataType == SHARE_DATA_TYPE.PHOTO then
            --二期规划：拍照站筛选
            tTypeFilter.cover_size_type = tFilter.nPhotoSizeType
            if tFilter.nPhotoMapType and tFilter.nPhotoMapType ~= -1 then
                tTypeFilter.photo_map_type= tFilter.nPhotoMapType
            end
            
            if tFilter.dwPhotoMapID and tFilter.dwPhotoMapID ~= -1 then
                tTypeFilter.photo_map_id= tFilter.dwPhotoMapID
            end
        end
    end

    tJsonFilter["search_filter_data"] = tTypeFilter
    CURL_HttpPost(PostKey.GET_RANK_LIST .. nDataType, szPostUrl, JsonEncode(tJsonFilter), true, 60, 60, {"Content-Type:application/json"})
end

function ShareCodeData.ReqGetCreatorList(nDataType, szSearch)
    if not nDataType or not szSearch then
        JustLog("ShareCodeData ReqGetCreatorList Fail", nDataType, szSearch)
        return
    end

    local szUrl = ShareCodeData.GetURL()
    local szPostUrl = string.format("%s%s?data_type=%d&keyword=%s&params=%s",
        szUrl,
        PostUrl.GET_CREATOR_LIST,
        nDataType,
        UrlEncode(szSearch),
        ShareCodeData.szDefaultParam
    )
    CURL_HttpPost(PostKey.GET_CREATOR_LIST .. nDataType, szPostUrl, nil, true, 60, 60)
end

function ShareCodeData.ReqGetRecommendList(nDataType, tFilter)
    if not nDataType or not tFilter then
        JustLog("ShareCodeData ReqGetRecommendList Fail", nDataType, tFilter)
        return
    end

    local szUrl = ShareCodeData.GetURL()
    local szPostUrl = string.format("%s%s?params=%s",
        szUrl,
        PostUrl.GET_RECOMMEND_LIST,
        ShareCodeData.szDefaultParam
    )

    local tTypeFilter = {}
    local tJsonFilter = {
        ["data_type"] = tostring(nDataType),
        ["search_filter_data"] = "",
    }

    if tFilter.nRoleType and tFilter.nRoleType ~= -1 then
        tTypeFilter.body_type = tFilter.nRoleType
    end

    if nDataType == SHARE_DATA_TYPE.FACE then --捏脸站
        tTypeFilter.face_type = tFilter.nFaceType
    elseif nDataType == SHARE_DATA_TYPE.EXTERIOR then
        if tFilter.tFilterExterior and not table.is_empty(tFilter.tFilterExterior) then
            -- --防止网页和端内表格索引对不上，全部转换成字符串键值确保JsonEncode后不会有歧义
            local tStrKeyFilter = {}
            local bFilterExteriorID = false
            for nRes, v in pairs(tFilter.tFilterExterior) do
                if not bFilterExteriorID and not ShareExteriorData.IsFilterFlagKey(nRes) and type(v) == "table" then
                    for _, dwID in pairs(v) do
                        if dwID > 0 then
                            bFilterExteriorID = true
                        end
                    end
                end

                tStrKeyFilter[tostring(nRes)] = v
            end
            tTypeFilter.filter_data = tStrKeyFilter
        end
        -- tTypeFilter.force_id = tFilter.dwForceID --门派筛选，暂时不做限制
    elseif nDataType == SHARE_DATA_TYPE.PHOTO then
        --二期规划：拍照站筛选
        tTypeFilter.cover_size_type = tFilter.nPhotoSizeType
        if tFilter.nPhotoMapType and tFilter.nPhotoMapType ~= -1 then
            tTypeFilter.photo_map_type= tFilter.nPhotoMapType
        end
        
        if tFilter.dwPhotoMapID and tFilter.dwPhotoMapID ~= -1 then
            tTypeFilter.photo_map_id= tFilter.dwPhotoMapID
        end
    end

    tJsonFilter["search_filter_data"] = tTypeFilter
    CURL_HttpPost(PostKey.GET_RECOMMEND_LIST .. nDataType, szPostUrl, JsonEncode(tJsonFilter), true, 60, 60, {"Content-Type:application/json"})
end

--检查图片是否包含人脸
function ShareCodeData.ReqDataCheckValid(szFilePath)
    if not szFilePath then
        LOG.ERROR("[ERROR]ShareCodeData ReqDataCheckValid Fail")
        return
    end

    ShareCodeData.szCheckValidCoverPath = szFilePath
    local tbParams = {
		upload_file =
		{
			key = "file",
			content_type = "image/jpeg",
			file = szFilePath,
			filename = COVER_FILE_NAME,
		},
	}
	CURL_HttpPost(PostKey.FACE_CHECK_VALID, CURL_FACE_CHECK_VALID, tbParams, true, 60, 60)
end

--从云端下载封面
function ShareCodeData.DoDownloadCover(nDataType, szUrl, szShareCode)
    if not nDataType or not szUrl or not szShareCode then
        return
    end

    local szFilePath = ShareCodeData.GetCoverFilePath(szShareCode, true)
    JustLog("ShareCodeData DoDownloadCover szUrl and szFilePath", szUrl, szFilePath)

    if not ShareCodeData.tbDownloadCoverPath then
        ShareCodeData.tbDownloadCoverPath = {}
    end

    local szID = tostring(table.get_len(ShareCodeData.tbDownloadCoverPath) + 1)
    ShareCodeData.tbDownloadCoverPath[szID] = szFilePath
    CURL_DownloadFile(string.format("%s_%s_%s", PostKey.DOWNLOAD_COVER, szID, nDataType), szUrl, szFilePath, true, 60, 60)
end


function ShareCodeData.DoUploadData(nDataType, szUrl, tbUploadToken)
    if not nDataType or not szUrl or not tbUploadToken or IsTableEmpty(tbUploadToken) then
        LOG.INFO("ShareCodeData DoUploadData Fail nDataType = %s, szUrl = %s, tbUploadToken = %s",
                    tostring(nDataType), tostring(szUrl), tostring(tbUploadToken))
        return
    end

    local tData = ShareCodeData.tUploadFileData
    local tUploadInfo = ShareCodeData.tUploadInfo
    if not tData or not tUploadInfo then
        JustLog("ShareCodeData DoUploadData Invalid", tData, tUploadInfo)
        return
    end

    local szFileName = tUploadInfo.szName .. "." .. tUploadInfo.szSuffix

    local bSucc = false
    local szFilePath, nVersion
    if nDataType == SHARE_DATA_TYPE.FACE then
        if tData.bNewFace then
            szFilePath, nVersion = NewFaceData.SaveFaceData(nil, tData, tUploadInfo.nRoleType, ShareCodeData.bIsLogin)
        else
            szFilePath, nVersion = NewFaceData.SaveOldFaceData(nil, tData, tUploadInfo.nRoleType, ShareCodeData.bIsLogin)
        end
    elseif nDataType == SHARE_DATA_TYPE.BODY then
        szFilePath, nVersion = BuildBodyData.SaveBodyData(tData, tUploadInfo.nRoleType, ShareCodeData.bIsLogin)
    elseif nDataType == SHARE_DATA_TYPE.EXTERIOR then
        szFilePath, nVersion = ShareExteriorData.SaveExteriorData(tData, tUploadInfo.nRoleType)
    elseif nDataType == SHARE_DATA_TYPE.PHOTO then
        local bIsPortrait = UIHelper.GetScreenPortrait()
        szFilePath, nVersion = SelfieTemplateBase.SavePhotoData(tUploadInfo.szName, tData, tUploadInfo.nRoleType, bIsPortrait)
    end

    if Platform.IsWindows() then
		szFilePath = UIHelper.UTF8ToGBK(szFilePath)
	end

    ShareCodeData.szUploadFilePath = szFilePath
    ShareCodeData.nUploadDataVersion = nVersion

    local tParams = {
        upload_file =
		{
			key = "file",
			content_type = "application/octet-stream",
			file = szFilePath,
            filename = szFileName,
		},
        name = szFileName,
        key = tbUploadToken.key,
        token = tbUploadToken.token,
        domain = tbUploadToken.domain,
    }
    CURL_HttpPost(PostKey.DO_UPLOAD_DATA .. nDataType, szUrl, tParams, true, 60, 60)
end

--上传封面图片至云端
function ShareCodeData.DoUploadCover(nDataType, szUrl, tUploadToken, szCoverFilePath)
    if not nDataType or not szUrl or not tUploadToken or not szCoverFilePath then
        JustLog("ShareCodeData DoUploadCover Fail", nDataType, szUrl, tUploadToken, szCoverFilePath)
        return
    end

    if Platform.IsWindows() then
		szCoverFilePath = UIHelper.UTF8ToGBK(szCoverFilePath)
	end

    ShareCodeData.szCoverFilePath = szCoverFilePath
    ShareCodeData.nUploadDataType = nil
    ShareCodeData.nUploadPhotoSizeType = nil
    ShareCodeData.szUploadCoverLink = nil
    ShareCodeData.tUploadCoverToken = nil

    local tbParams = {
        upload_file =
        {
            key = "file",
            content_type = "image/jpeg",
            file = szCoverFilePath,
            filename = COVER_FILE_NAME,
        },
        key = tUploadToken.key,
        token = tUploadToken.token,
        domain = tUploadToken.domain,
    }
    CURL_HttpPost(PostKey.DO_UPLOAD_COVER .. nDataType, szUrl, tbParams, true, 60, 60)
end

function ShareCodeData.DoDownloadData(nDataType, szUrl, szShareCode)
    if not nDataType or string.is_nil(szUrl) or not szShareCode then
        JustLog("ShareCodeData DoDownloadData Fail", nDataType, szUrl, szShareCode)
        return
    end

    local _, szSuffix = GetShareCodeByURL(szUrl)
    if not szSuffix or string.is_nil(szSuffix) then
        JustLog("ShareCodeData DoDownloadData szSuffix", szSuffix)
        return
    end

    local szDataDir = ShareCodeData.GetShareFolderDir(true)
    if Platform.IsWindows() then
        szDataDir = UIHelper.UTF8ToGBK(szDataDir)
    end

    local szFilePath = string.format("%s/%s.%s", szDataDir, szShareCode, szSuffix)
    szFilePath = string.gsub(szFilePath, "\\", "/")
    JustLog("ShareCodeData DoDownloadData szUrl and szFilePath", szUrl, szFilePath)

    if not ShareCodeData.tDownloadDataPath then
        ShareCodeData.tDownloadDataPath = {}
    end

    ShareCodeData.szCurGetShareCode = szShareCode
    local szID = tostring(table.get_len(ShareCodeData.tDownloadDataPath) + 1)
    ShareCodeData.tDownloadDataPath[szID] = szFilePath
    CURL_DownloadFile(string.format("%s_%s_%s", PostKey.DOWNLOAD_DATA, szID, nDataType), szUrl, szFilePath, true, 60, 60)
end

function ShareCodeData.OnWebDataSignNotify()
    local szComment = arg6
	local dwApplyWebID = szComment:match("APPLY_WEBID_(.*)")
	if dwApplyWebID then
		dwApplyWebID = tonumber(dwApplyWebID)
        if dwApplyWebID ~= ApplyLoginSignWebID then
            return
        end
		local uSign = arg0
		local nTime = arg2
		local nZoneID = arg3
		local dwCenterID = arg4
		ShareCodeData.OnLoginAccount(dwApplyWebID, uSign, nTime, nZoneID, dwCenterID, false)
	end
end

function ShareCodeData.OnLoginWebDataSignNotify()
    local szComment = arg2
	local dwApplyWebID = szComment:match("APPLY_LOGIN_WEBID_(.*)")
	if dwApplyWebID then
		dwApplyWebID = tonumber(dwApplyWebID)
        if dwApplyWebID ~= ApplyLoginSignWebID then
            return
        end
		local uSign = arg0
		local nTime = arg1
		local nZoneID = 0
		local dwCenterID = 0
		ShareCodeData.OnLoginAccount(dwApplyWebID, uSign, nTime, nZoneID, dwCenterID, true)
	end
end

function ShareCodeData.OnLoginAccount(dwID, uSign, nTime, nZoneID, dwCenterID, bLogin)
    local dwPlayerID = 0
    local dwForceID = 0
    local szRoleName = ""
    local dwCreateTime = 0
    local szGlobalID = ""
	local szAccount = Login_GetAccount()
    local szDefaultParam

    if bLogin then
        szDefaultParam = "%d/%s//%d///////%d/%d"
	    szDefaultParam = string.format(szDefaultParam, uSign, szAccount, nTime, dwCreateTime, GetAccountType())
    else
        local player = PlayerData.GetClientPlayer()
        if player then
            dwPlayerID = player.dwID
            dwForceID = player.dwForceID
            szRoleName =  UrlEncode(UIHelper.GBKToUTF8(player.szName))
            dwCreateTime = player.GetCreateTime()
        end

        local szUserRegion, szUserSever = WebUrl.GetServerName()
        --param=sign/account/roleID/time/zoneID/centerID/测试区/测试服/门派ID/角色名称/角色创建时间/账号类型
        szDefaultParam = "%d/%s/%d/%d/%d/%d/%s/%s/%d/%s/%d/%d"
        szDefaultParam = string.format(
            szDefaultParam, uSign, szAccount, dwPlayerID, nTime, nZoneID,
            dwCenterID, UrlEncode(szUserRegion), UrlEncode(szUserSever),
            dwForceID, szRoleName, dwCreateTime, GetAccountType()
        )
    end

    ShareCodeData.szDefaultParam = szDefaultParam
    -- local szUrl = ShareCodeData.GetURL()
    -- local szPostUrl = string.format("%s%s?%s", szUrl, PostUrl.LOGIN_ACCOUNT, szDefaultParam)
    -- CURL_HttpPost(PostKey.LOGIN_ACCOUNT, szPostUrl, {}, true, 60, 60)
end

function ShareCodeData.GetFormatData(tInfo)
    local tData = {}
    local szShareCode = tInfo.share_id
    tData.szShareCode = szShareCode
    tData.szFileLink = tInfo.file_link                --数据文件下载链接
    tData.nRoleType = tInfo.body_type                 --体型
    tData.szCoverLink = tInfo.cover                   --封面下载链接
    tData.szCoverPath = ShareCodeData.GetCoverFilePath(szShareCode) --封面路径
    tData.dwCreateTime = tInfo.create_time            --上传时间
    tData.szDesc = tInfo.desc                         --描述
    tData.szName = tInfo.name                         --名字
    tData.nOpenStatus = tInfo.open_status             --作品状态，包括：公开、私密、隐藏、审核中、审核失败、已删除
    tData.nHeat = tInfo.heat                          --总热度
    tData.szUser = tInfo.user                         --作者
    tData.nVersion = tInfo.version                    --版本号
    tData.szUploadSource = tInfo.upload_source         --上传来源
    tData.nRewards = tInfo.reward                     --打赏金额
    tData.bCertified = tInfo.is_creator == 1          --是否认证
    tData.nPos = tInfo.nPos

    --风格标签
    if tInfo.tags then
        tData.tTag = StringParse_IDList(tInfo.tags)
    else
        tData.tTag = {}
    end

    if tInfo.face_type and tInfo.face_type ~= 0 then --捏脸站
        tData.nSubType = tInfo.face_type              --捏脸类型
    elseif tInfo.face_type and tInfo.face_type == 0 then
        local _, szSuffix = ShareCodeData.GetShareCodeWithURL(tInfo.file_link)
        tData.nSubType = SUFFIX_2_FACE_TYPE[szSuffix] or 0
    elseif tInfo.cover_size_type and tInfo.cover_size_type ~= 0 then --拍照站
        tData.nSubType = tInfo.cover_size_type        --封面尺寸类型
    else
        tData.nSubType = 0
    end

    --捏脸站
    tData.nFaceType = tInfo.face_type

    --搭配站
    tData.dwForceID = tInfo.force_id
    if tInfo.filter_data and type(tInfo.filter_data) == "table" then
        tData.tFilterData = {}
        for szKey, v in pairs(tInfo.filter_data) do
            if tonumber(v) then
                v = tonumber(v)
            end

            if tonumber(szKey) then
                tData.tFilterData[tonumber(szKey)] = v
            else
                tData.tFilterData[szKey] = v
            end
        end
    end

    --拍照站
    tData.nPhotoSizeType = tInfo.cover_size_type
    tData.nPhotoMapType = tInfo.photo_map_type
    tData.dwPhotoMapID = tInfo.photo_map_id

    return tData
end

function ShareCodeData.GetFormatCreatorData(tInfo, nDataType)
    local tData = {}
    tData.nDataType = nDataType                       --作品类型
    tData.szUser = tInfo.nick_name                    --作者名
    tData.szAccount = tInfo.account                   --用于搜索作者的账号
    tData.nWorksNum = tInfo.works_num                 --作品数量
    return tData
end

function ShareCodeData.GetCoverFilePath(szShareCode, bDownload)
    local szDataDir = ShareCodeData.GetShareFolderDir(bDownload)
    if Platform.IsWindows() then
        szDataDir = UIHelper.UTF8ToGBK(szDataDir)
    end
    local szFilePath = string.format("%s/%s.jpg", szDataDir, szShareCode)
    szFilePath = string.gsub(szFilePath, "\\", "/")
    return szFilePath
end

function ShareCodeData.GetShareFolderDir(bDownload)
    local szDataDir = (Platform.IsMac() and not bDownload) and SHARE_CODE_FILE_PATH or GetFullPath(SHARE_CODE_FILE_PATH)
	CPath.MakeDir(szDataDir)
    if Platform.IsWindows() then
		szDataDir = UIHelper.GBKToUTF8(szDataDir)
	end

    return szDataDir
end

function ShareCodeData.CheckCoverFileDownloaded(szShareCode)
    local szFilePath = ShareCodeData.GetCoverFilePath(szShareCode)
    if Lib.IsFileExist(szFilePath, false) then
        return true, szFilePath
    end
    return false
end

function ShareCodeData.CheckFileDownloaded(nDataType, szShareCode)
    local tbCheckSuffix = {"ini", "dat"}
    local szDataDir = ShareCodeData.GetShareFolderDir()
    if Platform.IsWindows() then
        szDataDir = UIHelper.UTF8ToGBK(szDataDir)
    end

    if nDataType == SHARE_DATA_TYPE.FACE then
        for _, szSuffix in ipairs(tbCheckSuffix) do
            local szFilePath = string.format("%s/%s.%s", szDataDir, szShareCode, szSuffix)
            szFilePath = string.gsub(szFilePath, "\\", "/")
            if Lib.IsFileExist(szFilePath, false) then
                LOG.INFO("ShareCodeData CheckData szFilePath = "..szFilePath.." size = "..Lib.GetFileSize(szFilePath))
                return true, szSuffix, szFilePath
            end
        end
    else
        local szSuffix = "dat"
        local szFilePath = string.format("%s/%s.%s", szDataDir, szShareCode, szSuffix)
        szFilePath = string.gsub(szFilePath, "\\", "/")
        if Lib.IsFileExist(szFilePath, false) then
            return true, szSuffix, szFilePath
        end
    end

    return false
end

function ShareCodeData.LoadShareCodeData(nDataType, szShareCode, szSuffix)
    if not nDataType or not szShareCode or not szSuffix then
        JustLog("ShareCodeData LoadShareCodeData", nDataType, szShareCode, szSuffix)
        return
    end

    local szDataDir = ShareCodeData.GetShareFolderDir()
    local szFilePath = string.format("%s/%s.%s", szDataDir, szShareCode, szSuffix)
    szFilePath = string.gsub(szFilePath, "\\", "/")
    if Platform.IsWindows() then
        szFilePath = UIHelper.UTF8ToGBK(szFilePath)
    end

    local tbData
    if nDataType == SHARE_DATA_TYPE.FACE then
        if szSuffix == "ini" then
            tbData = NewFaceData.LoadFaceData(szFilePath)
        elseif szSuffix == "dat" then
            tbData = NewFaceData.LoadOldFaceData(szFilePath)
        end
    elseif nDataType == SHARE_DATA_TYPE.BODY then
        tbData = BodyCodeData.LoadBodyDataByPath(szFilePath, szShareCode)
    elseif nDataType == SHARE_DATA_TYPE.EXTERIOR then
        tbData = ShareExteriorData.LoadExteriorData(szFilePath)
    elseif nDataType == SHARE_DATA_TYPE.PHOTO then
        tbData = SelfieTemplateBase.LoadPhotoData(szFilePath)
    end

    if tbData then
        ShareCodeData.SetShareCodeData(szShareCode, tbData)
    else
        LOG.INFO("ShareCodeData Load Fail -- %s", szShareCode)
        -- FireUIEvent("ON_SHARE_CODE_LOAD_FAIL", nDataType)
    end

    return tbData
end

function ShareCodeData.SetShareCodeData(szShareCode, tbData)
    ShareCodeData.tbCacheData = ShareCodeData.tbCacheData or {}
    ShareCodeData.tbCacheData[szShareCode] = tbData
    Event.Dispatch(EventType.OnUpdateShareCodeListCell, szShareCode)
end

function ShareCodeData.GetShareCodeData(szShareCode)
    ShareCodeData.tbCacheData = ShareCodeData.tbCacheData or {}
    return ShareCodeData.tbCacheData[szShareCode]
end

function ShareCodeData.GetShareCodeWithURL(szUrl)
    local szShareCode, szSuffix = string.match(szUrl, ".+/([^/]+)%.([a-zA-Z0-9]+)$")
    return szShareCode, szSuffix
end

function ShareCodeData.GetCoverFileName()
    return COVER_FILE_NAME
end

function ShareCodeData.CheckValid(szFilePath)
    if Platform.IsWindows() then
		szFilePath = UIHelper.UTF8ToGBK(szFilePath)
	end

    if not Lib.IsFileExist(szFilePath, false) then
		Log("[error]ShareCodeData CheckValid FilePath not Exist")
		return
	end

    ShareCodeData.ReqDataCheckValid(szFilePath)
end

--上传新作品
--tPreviewData: 要上传的文件内容
--tUploadInfo = {szName, szDesc, szSuffix, nOpenStatus, nRoleType}
function ShareCodeData.UploadData(bLogin, nDataType, tPreviewData, tUploadInfo, fnSaveCover, bCopyToClip)
    if not nDataType or not tPreviewData or not tUploadInfo then
        JustLog("ShareCodeData UploadData:", nDataType, tPreviewData, tUploadInfo)
        return
    end

    if ShareCodeData.bBusy then
        return g_tStrings.STR_SHARE_STATION_UPLOAD_DATA_BUSY
    end

    ShareCodeData.bBusy = true
    ShareCodeData.nUploadDataType = nDataType
    ShareCodeData.nUploadPhotoSizeType = tUploadInfo.nPhotoSizeType
    ShareCodeData.tUploadInfo = tUploadInfo
    ShareCodeData.tUploadFileData = tPreviewData
    ShareCodeData.fnSaveCover = fnSaveCover
    ShareCodeData.bCopyToClip = bCopyToClip

    local szUploadSuffix = "." .. tUploadInfo.szSuffix
    ShareCodeData.CheckSignAndExecute(bLogin, ShareCodeData.ReqGetUploadToken, nDataType, szUploadSuffix)

    return FormatString(g_tStrings.STR_SHARE_STATION_EXPROT_SUCCESS, g_tStrings.tShareStationTitle[nDataType])
end

--上传捏脸至捏脸站
function ShareCodeData.ReqGetUploadToken(nDataType, szSuffix)
    ShareCodeData.ReqGetFileUploadToken(nDataType, szSuffix)
    ShareCodeData.ReqGetCoverUploadToken(nDataType)
end

--上传封面图片(不一定需要单独的接口)
function ShareCodeData.UploadCover(bLogin, szCoverFilePath)
    ShareCodeData.CheckSignAndExecute(bLogin, ShareCodeData.ReqGetCoverUploadToken, szCoverFilePath)
end

--更新捏脸数据
function ShareCodeData.UpdateData(bLogin, nDataType, szShareCode, tModifyInfo, fnSaveCover)
    if not szShareCode then
        Log("[error]ShareCodeData UpdateData Fail")
        return
    end

    ShareCodeData.nUploadDataType = nDataType
    ShareCodeData.nUploadPhotoSizeType = tModifyInfo.nPhotoSizeType
    ShareCodeData.szUpdateShareCode = szShareCode
    ShareCodeData.tModifyInfo = tModifyInfo
    ShareCodeData.fnSaveCover = nil

    if fnSaveCover then
        ShareCodeData.fnSaveCover = fnSaveCover
        ShareCodeData.CheckSignAndExecute(bLogin, ShareCodeData.ReqGetCoverUploadToken, nDataType)
    else
        ShareCodeData.CheckSignAndExecute(bLogin, ShareCodeData.ReqUpdateData, nDataType)
    end

    return g_tStrings.STR_SHARE_STATION_UPDATE_INFO
end

--申请所有捏脸数据
function ShareCodeData.ApplySelfDataList(bLogin, nDataType)
    ShareCodeData.CheckSignAndExecute(bLogin, ShareCodeData.ReqGetUploadList, nDataType)
end

--导入数据
function ShareCodeData.ApplyData(bLogin, nDataType, szShareCode)
    if not szShareCode then
        return
    end

    if ShareCodeData.bBusy then
        return g_tStrings.STR_SHARE_DATA_IMPORT_CD
    end

    ShareCodeData.CheckSignAndExecute(bLogin, ShareCodeData.ReqGetData, nDataType, szShareCode)
    return FormatString(g_tStrings.STR_SHARE_STATION_UPLOAD_SUCCESS, g_tStrings.tShareStationTitle[nDataType])
end

--下载数据
function ShareCodeData.DownloadData(nDataType, szShareCode, szFileLink)
    local bHad, szSuffix, szFilePath = ShareCodeData.CheckFileDownloaded(nDataType, szShareCode)
    if not bHad then
        ShareCodeData.DoDownloadData(nDataType, szFileLink, szShareCode)
    else
        ShareCodeData.SetShareCodeData(szShareCode, ShareCodeData.LoadShareCodeData(nDataType, szShareCode, szSuffix))
        ShareCodeData.szCurGetShareCode = szShareCode
        Event.Dispatch(EventType.OnDownloadShareCodeData, true, szShareCode, szFilePath, nDataType)
        ShareCodeData.szCurGetShareCode = nil
    end
end

--删除云端捏脸
function ShareCodeData.ApplyDelData(bLogin, nDataType, szShareCode)
    if not szShareCode then
        return
    end
    ShareCodeData.CheckSignAndExecute(bLogin, ShareCodeData.ReqDelData, nDataType, {szShareCode})
end

--批量删除云端捏脸
function ShareCodeData.ApplyDelDataList(bLogin, nDataType, tDelList)
    if not tDelList then
        return
    end
    ShareCodeData.CheckSignAndExecute(bLogin, ShareCodeData.ReqDelData, nDataType, tDelList)
end

--获取所有数据
function ShareCodeData.GetMyDataList()
    return clone(ShareCodeData.tbSelfDataList) or {}
end

--申请账号基本信息
function ShareCodeData.ApplyAccountConfig(bLogin, nDataType, bNeedReqUploadList)
    ShareCodeData.bNeedReqUploadList = bNeedReqUploadList
    ShareCodeData.CheckSignAndExecute(bLogin, ShareCodeData.ReqGetConfig, nDataType)
end

--获取账号基本信息
function ShareCodeData.GetAccountConfig(nDataType)
    return ShareCodeData.tUploadConfig and ShareCodeData.tUploadConfig[nDataType]
end

--上传数量已达上限提示
function ShareCodeData.ShowUploadLimitMsg(nDataType, nRoleType)
    local tConfig = ShareCodeData.GetAccountConfig(nDataType)
    if not tConfig then
        LOG.ERROR("[ERROE]ShareCodeData ShowUploadLimitMsg Account Config is nil")
        return
    end

    local nUploadRoleType = nRoleType or ShareCodeData.nUploadRoleType
    if not nUploadRoleType then
        LOG.ERROR("[ERROE]ShareCodeData ShowUploadLimitMsg nUploadRoleType is nil")
        return
    end

    local nUploadLimit = tConfig.nUploadLimit
    local szDataType = g_tStrings.tShareStationTitle[nDataType]
    local szNumLimit = FormatString(g_tStrings.NUM_T_NUM, nUploadLimit, nUploadLimit)

    local szContent = FormatString(g_tStrings.STR_SHARE_STATION_UPLOAD_MAX, szDataType, szNumLimit, szDataType)
    UIHelper.ShowConfirm(szContent, function ()
        ShareStationData.OpenShareStation(nDataType, true)
    end)

    ShareCodeData.bBusy = false
end

--收藏/应用后是否加热度
local function IsQualifyToAddHeat()
    if ShareCodeData.bIsLogin then
        return false
    end

    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return false
    end

    local nChargeMoney = pPlayer.GetExtPoint(CHARGE_MONEY_EXT_POINT)
    if nChargeMoney and nChargeMoney > ADD_HEAT_QUELIFIED_CHARGE_LIMIT then
        return true
    end

    return false
end


--收藏捏脸
function ShareCodeData.CollectData(bLogin, nDataType, szShareCode)
    local bAddHeat = IsQualifyToAddHeat()
    ShareCodeData.CheckSignAndExecute(bLogin, ShareCodeData.ReqCollectData, nDataType, szShareCode, bAddHeat)
end

--获取收藏列表
function ShareCodeData.ApplyCollectList(bLogin, nDataType)
    ShareCodeData.CheckSignAndExecute(bLogin, ShareCodeData.ReqGetCollectList, nDataType)
end

--取消收藏
function ShareCodeData.UnCollectData(bLogin, nDataType, szShareCode)
    ShareCodeData.CheckSignAndExecute(bLogin, ShareCodeData.ReqUnCollectData, nDataType, szShareCode)
end

--采用数据（增加热度）
function ShareCodeData.AddDataHeat(bLogin, nDataType, szShareCode)
    if not IsQualifyToAddHeat() then
        return
    end
    ShareCodeData.CheckSignAndExecute(bLogin, ShareCodeData.ReqApplyData, nDataType, szShareCode)
end

--举报捏脸
function ShareCodeData.ReportData(bLogin, nDataType, szShareCode, szReason)
    ShareCodeData.CheckSignAndExecute(bLogin, ShareCodeData.ReqReportData, nDataType, szShareCode, szReason)
end

--获取捏脸站数据
function ShareCodeData.GetShareRankList(bLogin, nDataType, szCreateRange, nPage, nPageSize, szRankType, tFilter)
    szRankType = szRankType or "total"
    ShareCodeData.CheckSignAndExecute(bLogin, ShareCodeData.ReqGetShareStationData, nDataType, szCreateRange, nPage, nPageSize, szRankType, tFilter)
end

--获取认证作者列表
function ShareCodeData.GetCreatorList(bLogin, nDataType, szSearch)
    ShareCodeData.CheckSignAndExecute(bLogin, ShareCodeData.ReqGetCreatorList, nDataType, szSearch)
end

--获取推荐数据
function ShareCodeData.GetRecommendList(bLogin, nDataType, tFilter)
    ShareCodeData.CheckSignAndExecute(bLogin, ShareCodeData.ReqGetRecommendList, nDataType, tFilter)
end

-- tExteriorList: { [nSub] = { dwID, ... }, ... }
local function PackExteriorListToFilterMap(tExteriorList)
    local tStrKeyFilter = {}
    for nSub, tIds in pairs(tExteriorList) do
        if type(tIds) == "table" then
            tStrKeyFilter[tostring(nSub)] = tIds
        end
    end
    return tStrKeyFilter
end

function ShareCodeData.ReqGetPackRecommendList(tExteriorList)
    if not tExteriorList or table.is_empty(tExteriorList) then
        JustLog("ShareCodeData ReqGetPackRecommendList Fail", tExteriorList)
        return
    end

    local szUrl = ShareCodeData.GetURL()
    local szPostUrl = string.format("%s%s?params=%s",
        szUrl,
        PostUrl.GET_PACK_RECOMMEND_LIST,
        ShareCodeData.szDefaultParam
    )

    local tStrKeyFilter = PackExteriorListToFilterMap(tExteriorList)

    local tTypeFilter = {
        ["body_type"] = g_pClientPlayer and g_pClientPlayer.nRoleType or -1,
        ["filter_data"] = tStrKeyFilter,
    }

    local nDataType = SHARE_DATA_TYPE.EXTERIOR
    local tJsonFilter = {
        ["search_filter_data"] = tTypeFilter,
    }
    CURL_HttpPost(PostKey.GET_PACK_RECOMMEND_LIST .. nDataType, szPostUrl, JsonEncode(tJsonFilter), true, 60, 60, {"Content-Type:application/json"})
end

--获取包装扮推荐数据
function ShareCodeData.GetPackRecommendList(bLogin, tExteriorList)
    ShareCodeData.CheckSignAndExecute(bLogin, ShareCodeData.ReqGetPackRecommendList, tExteriorList)
end

--------------缓存管理---------------
function ShareCodeData.IsShareCodeInList(tList, szShareCode)
    for nDataType, tbDataType in pairs(tList) do
        for _, v in ipairs(tbDataType) do
            if szShareCode == v.szShareCode then
                return true
            end
        end
    end
    return false
end

function ShareCodeData.GetDownloadTimeFilePath()
    return SHARE_CODE_FILE_PATH .. "/downloadtime.dat"
end

function ShareCodeData.GetSuffixByFaceType(nFaceType)
    return FACE_TYPE_2_SUFFIX[nFaceType]
end

function ShareCodeData.GetDownloadTimeData()
    local szDownloadTimeFile = ShareCodeData.GetDownloadTimeFilePath()
    local tDownloadTime = {}
    if Lib.IsFileExist(szDownloadTimeFile, false) then
        local v = LoadLUAData(szDownloadTimeFile, false, true, nil, true)
        if type(v) == "table" then
            tDownloadTime = v
        end
    end
    return tDownloadTime
end

--清理缓存数据
function ShareCodeData.ClearCacheData()
    if not ShareCodeData.tbSelfDataList and not ShareCodeData.tbCollectDataList then
        return
    end

    -- 每次退出客户端时做一次缓存清理，给sharestationdir文件夹额定10MB大小的缓存空间，小于这个范围的情况下不做任何处理；超过这个范围做以下处理：
    -- 1.按照从旧到新的顺序清理文件，优先清理旧文件。
    -- 2.对每一个文件，如果属于【我的】或【收藏】列表，则跳过不清理；否则删除该文件。直到sharestationdir文件夹的大小小于10MB，或遍历完所有文件，结束本轮清理。
    --（备注）downloadtime文件维护规则：默认在下载时新增条目，如果清理时存在和管理条目对不上的数据则进行更新，以清理时的时间戳为准。时间戳相同的条目，先读到谁就先删谁。
    local szDir = ShareCodeData.GetShareFolderDir()
    local szDownloadTimeFile = ShareCodeData.GetDownloadTimeFilePath()
    local tDownloadTime = ShareCodeData.tDownloadTime or ShareCodeData.GetDownloadTimeData()
    if Platform.IsWindows() then
		szDir = UIHelper.UTF8ToGBK(szDir)
	end

    local tList = Lib.ListFiles(szDir)
    local nTotalSize = 0
    local tDelFile = {}
    local tNewDownloadTime = {}
    --计算文件夹大小，补充更新downloadtime数据
	for _, szFilePath in ipairs(tList) do
        local szFileName = string.match(szFilePath, "[^/\\]+$")
        local nSize = Lib.GetFileSize(szFilePath)
        nTotalSize = nTotalSize + nSize

        local szShareCode = string.match(szFileName, "^([^.]+)")
        if szShareCode and szShareCode ~= "downloadtime" then
            local nTime
            if not tDownloadTime[szFileName] then
                nTime = _GetCurrentTime(true)
            else
                nTime = tDownloadTime[szFileName]
            end
            tNewDownloadTime[szFileName] = nTime

            if not ShareCodeData.IsShareCodeInList(ShareCodeData.tbSelfDataList, szShareCode)
                and not ShareCodeData.IsShareCodeInList(ShareCodeData.tbCollectDataList, szShareCode) then
                table.insert(tDelFile, {szFileName = szFileName, szFilePath = szFilePath, nSize = nSize, nTime = nTime})
            end
        end
	end

    if nTotalSize <= CACHE_DATA_MAX_SIZE then
        SaveLUAData(szDownloadTimeFile, tNewDownloadTime)
        return
    end

    table.sort(tDelFile, function (t1, t2)
        return t1.nTime < t2.nTime
    end)

    for _, tData in ipairs(tDelFile) do
        Lib.RemoveFile(tData.szFilePath)
        tNewDownloadTime[tData.szFileName] = nil

        nTotalSize = nTotalSize - tData.nSize
        if nTotalSize <= CACHE_DATA_MAX_SIZE then
            break
        end
    end
    SaveLUAData(szDownloadTimeFile, tNewDownloadTime)
end

--------------缓存管理---------------

function ShareCodeData.GetCurrentTime(bIsLogin)
    return _GetCurrentTime(bIsLogin)
end
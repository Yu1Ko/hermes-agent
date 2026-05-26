FaceCodeData = FaceCodeData or {className = "FaceCodeData"}

local WEB_URL_TEST = "https://test-ws.xoyo.com"
local WEB_URL = "https://ws.xoyo.com"
local COVER_FILE_NAME = "FaceStationUploadCover.jpg"
local FACE_CODE_FILE_PATH = "facestation"

local PostKey = {
    FACE_CHECK_VALID        = "FACE_CHECK_VALID",
    LOGIN_ACCOUNT           = "LOGIN_ACCOUNT",
    GET_FACE_UPLOAD_TOKEN   = "GET_FACE_UPLOAD_TOKEN",
    -- UPLOAD_FACE             = "UPLOAD_FACE",
    DO_UPLOAD_FACE          = "DO_UPLOAD_FACE",
    DO_UPLOAD_COVER         = "DO_UPLOAD_COVER",
    GET_FACE_LIST           = "GET_FACE_LIST",
    DOWNLOAD_FACE           = "DOWNLOAD_FACE",
    DOWNLOAD_COVER          = "DOWNLOAD_COVER",
    GET_FACE                = "GET_FACE",
    DEL_FACE                = "DEL_FACE",
    DEL_BATCH_FACE          = "DEL_BATCH_FACE",
    GET_CONFIG              = "GET_CONFIG",
    FACES_LIST_BY_PAGING    = "FACES_LIST_BY_PAGING",
    GET_COVER_UPLOAD_TOKEN  = "GET_COVER_UPLOAD_TOKEN",
    UPLOAD_FACE_WITH_INFO   = "UPLOAD_FACE_WITH_INFO",
    UPDATE_FACE_INFO        = "UPDATE_FACE_INFO",
    FOLLOW_FACE             = "FOLLOW_FACE",
    GET_FOLLOW_FACE_LIST    = "GET_FOLLOW_FACE_LIST",
    UNFOLLOW_FACE           = "UNFOLLOW_FACE",
    APPLY_FACE              = "APPLY_FACE",
    REPORT_FACE             = "REPORT_FACE",
    GET_FACE_RANK_LIST      = "GET_FACE_RANK_LIST",
}

local PostCode = {
    GET_FACE_UPLOAD_TOKEN = "get_upload_token", --获取捏脸文件上传参数
    GET_FACE_LIST = "faces_list",   --获得我上传的捏脸列表
    GET_FACE = "get_face",  --获取捏脸数据的文件链接
    DEL_FACE = "del_face",  --删除捏脸数据
    DEL_BATCH_FACE  = "del_batch_face", --批量删除捏脸数据
    --以下为捏脸站新增接口
    GET_CONFIG = "get_config",  --获取上传相关的基本信息
    FACES_LIST_BY_PAGING = "faces_list_by_paging",  --分页获取我上传的捏脸列表
    GET_COVER_UPLOAD_TOKEN = "get_cover_upload_token",  --获取封面上传参数
    UPLOAD_FACE_WITH_INFO = "upload_face_with_info",    --上传捏脸信息至捏脸站
    UPDATE_FACE_INFO = "update_face_info",  --更新捏脸信息
    FOLLOW_FACE = "follow", --收藏捏脸
    GET_FOLLOW_FACE_LIST = "follow_list",   --获取我的收藏列表
    UNFOLLOW_FACE = "unfollow", --取消收藏
    APPLY_FACE = "apply",   --应用捏脸增加热度
    REPORT_FACE = "report", --举报捏脸
    GET_FACE_RANK_LIST = "rank_list",   --获取捏脸站数据列表
}
local PostUrl = {
    LOGIN_ACCOUNT           = "/core/jx3tools/get_current_account",             --获取游戏内嵌页登录用户 --暂时用不上了，改成每次调用都需要登录token和角色信息的param
}
for key, value in pairs(PostCode) do
    local suffix = "faceupload240311"
    if IsVersionExp() then
        suffix = "faceuploadtf240311"
    end
    PostUrl[key] = "/jx3/" .. suffix .. "/" .. value
end

local CURL_FACE_CHECK_VALID = "http://124.70.212.237/face/validate" --检查图片是否包含人脸
local CHECK_VALID_SUCCESS_CODE = 0 --检查是否包含人脸的成功返回码
local CHECK_TIME_CD = 50 --每个登录Token有效期为1分钟，提前一点更新防止频繁出现登录态过期的情况
local STATUS_LOGIN_INVALID = -14802 --登录态过期
local CACHE_DATA_MAX_SIZE = 10 * 1024 * 1024 --缓存文件夹大小限制
local FACE_TYPE_2_SUFFIX = {
    [FACE_TYPE.OLD] = "dat",
    [FACE_TYPE.NEW] = "ini",
}
local SUFFIX_2_FACE_TYPE = {
    ["dat"] = FACE_TYPE.OLD,
    ["ini"] = FACE_TYPE.NEW,
}
local ApplyLoginSignWebID = 3100
-- local UploadCloudKey = "FaceCodeFileUpload"
-- local DownloadCloudKey = "FaceCodeFileDownload"

local STATUS_CODE = {
    [1] = "成功",
    [0] = "系统错误",
    [-10151] = "活动未开启",
    [-10152] = "活动配置错误",
    [-10153] = "活动未开始",
    [-10154] = "活动已结束",
    [-10201] = "系统处理中",
    [-10701] = "未知驱动",
    [-14801] = "数据不合法",
    [-14802] = "登录态过期，请重新打开界面",
    [-14803] = "参数缺失",
    [-20103] = "账号不存在",
    [-20104] = "您上传的捏脸数据已达到上限",
    [-20105] = "缺少上传文件ID",
    [-20106] = "上传捏脸数据异常，请稍后再重试！",
    [-20107] = "缺少分享ID",
    [-20108] = "分享ID无效",
    [-20109] = "无效的分享ID",
    [-20110] = "文件ID无效",
    [-20111] = "文件ID已存在",
    [-20112] = "文件后缀异常",
}

Event.Reg(FaceCodeData, "PLAYER_LEAVE_GAME", function()
	FaceCodeData.ClearCacheData()
end)

function FaceCodeData.Init()
    Event.Reg(FaceCodeData, "WEB_SIGN_NOTIFY", function()
		if arg3 == 3 then
			FaceCodeData.OnLoginWebDataSignNotify()
            FaceCodeData.ExecuteAllFunc()
            FaceCodeData.bLoginRequest = false
            FaceCodeData.nLastCheckTime = os.time()
		end
    end)

    Event.Reg(FaceCodeData, "ON_WEB_DATA_SIGN_NOTIFY", function()
		FaceCodeData.OnWebDataSignNotify()
        FaceCodeData.ExecuteAllFunc()
        FaceCodeData.bLoginRequest = false
        FaceCodeData.nLastCheckTime = GetCurrentTime()
    end)

    Event.Reg(FaceCodeData, "CURL_REQUEST_RESULT", function ()
		local szKey = arg0
		local bSuccess = arg1
		local szValue = arg2
		local uBufSize = arg3

        local bVaildKey = false
        for _, key in pairs(PostKey) do
            if szKey == key then
                bVaildKey = true
                break
            end
        end
        if not bVaildKey then
            return
        end

        if szKey == PostKey.UPLOAD_FACE_WITH_INFO then
            FaceCodeData.bBusy = false
        end

        if not bSuccess then
            LOG.ERROR("FaceCodeData CURL_REQUEST_RESULT FAILED!szKey:%s", szKey)
            -- LOG.TABLE({tInfo = tInfo, szKey = szKey})
            return
        end

        local tInfo, szErrMsg = JsonDecode(szValue)

        if not tInfo or not IsTable(tInfo) or (tInfo.code and tInfo.code == STATUS_LOGIN_INVALID) then
            FaceCodeData.nLastCheckTime = nil
            TipsHelper.ShowNormalTip(STATUS_CODE[tInfo.code])
            return
        end

        if szKey == PostKey.LOGIN_ACCOUNT then
            -- FaceCodeData.szSessionID已经改成FaceCodeData.szDefaultParam
            -- local tData = tInfo.data
            -- if tData then
            --     FaceCodeData.szSessionID = tData.session_id
            -- end
        elseif szKey == PostKey.GET_FACE_LIST then
            if tInfo and tInfo.code and tInfo.code == 1 then
            local tbData = tInfo.data.list or {}
            FaceCodeData.tbSelfFaceList = {}
            FaceCodeData.tDelayLoadSelfData = {}
            for _, tbInfo in ipairs(tbData) do
                local szFaceCode = tbInfo.share_id
                local _, szSuffix = FaceCodeData.GetFaceCodeWithURL(tbInfo.file_link)

                local szCoverFileLink = tbInfo.cover
                if szCoverFileLink and szCoverFileLink ~= "" then
                    local bDownloadCover = FaceCodeData.CheckCoverFile(szFaceCode)
                    if not bDownloadCover then
                        FaceCodeData.DoDownloadCover(tbInfo.cover, szFaceCode)
                    end
                end

                --【我的】列表里没上传过的数据会缺字段，需要客户端解析文件读取
                if tbInfo.face_type == 0 or tbInfo.body_type == 0 or tbInfo.face_name == "" then
                    local bDownloadFace = FaceCodeData.CheckFaceData(szFaceCode)
                    if not bDownloadFace then
                        FaceCodeData.DoDownloadFace(tInfo.file_link, szFaceCode)
                        table.insert(FaceCodeData.tDelayLoadSelfData, szFaceCode)
                    else
                        local tFaceData = FaceCodeData.GetFaceData(szFaceCode)
                        if not tFaceData then
                            tFaceData = FaceCodeData.LoadFaceData(szFaceCode, szSuffix)
                        end
                        if tFaceData then
                            if szSuffix == "ini" then
                                tbInfo.face_type = FACE_TYPE.NEW
                            elseif szSuffix == "dat" then
                                tbInfo.face_type = FACE_TYPE.OLD
                            end
                            tbInfo.body_type = tFaceData.nRoleType
                            tbInfo.face_name = tFaceData.szFileName
                        end
                    end
                end
                local tbData = FaceCodeData.GetFormatData(tbInfo)
                tbData.bOwner = true
                table.insert(FaceCodeData.tbSelfFaceList, tbData)
            end
                Event.Dispatch(EventType.OnUpdateSelfShareCodeList)
            elseif tInfo and tInfo.code and STATUS_CODE[tInfo.code] then
                TipsHelper.ShowNormalTip(STATUS_CODE[tInfo.code])
            end
        elseif szKey == PostKey.FACE_CHECK_VALID then
            if tInfo and tInfo.code and tInfo.code == CHECK_VALID_SUCCESS_CODE then
                Event.Dispatch(EventType.OnFaceCheckValidSuccess)
            end

            if tInfo and g_tStrings.tFaceCheckValid[tInfo.code] then
                TipsHelper.ShowNormalTip(g_tStrings.tFaceCheckValid[tInfo.code])
            end
            if FaceCodeData.szCheckValidCoverPath then
                Lib.RemoveFile(FaceCodeData.szCheckValidCoverPath)
                FaceCodeData.szCheckValidCoverPath = nil
            end
        elseif szKey == PostKey.GET_FACE_UPLOAD_TOKEN then
            if tInfo and tInfo.code and tInfo.code == 1 then
                local tData = tInfo.data
                if tData then
                    FaceCodeData.DoUploadFace(tData.action, tData.input_values)
                end
            elseif tInfo and tInfo.code and STATUS_CODE[tInfo.code] then
                TipsHelper.ShowNormalTip(STATUS_CODE[tInfo.code])
            end
        elseif szKey == PostKey.GET_COVER_UPLOAD_TOKEN then
            if tInfo and tInfo.code and tInfo.code == 1 then
                local tData = tInfo.data
                if tData then
                    FaceCodeData.DoUploadCover(tData.action, tData.input_values)
                end
            elseif tInfo and tInfo.code and STATUS_CODE[tInfo.code] then
                TipsHelper.ShowNormalTip(STATUS_CODE[tInfo.code])
            end
        elseif szKey == PostKey.UPLOAD_FACE_WITH_INFO then
            if tInfo and tInfo.code and tInfo.code == 1 then
                local tData = tInfo.data
                if tData and FaceCodeData.bCopyToClip then
                    local szShareID = tostring(tData.share_id)
                    SetClipboard(szShareID)
                    TipsHelper.ShowNormalTip(g_tStrings.STR_SHARE_STATION_UPLOAD_WAIT_COPY)
                elseif tData then
                    TipsHelper.ShowNormalTip(g_tStrings.STR_SHARE_STATION_UPLOAD_WAIT)
                end
            elseif tInfo and tInfo.code and STATUS_CODE[tInfo.code] then
                TipsHelper.ShowNormalTip(STATUS_CODE[tInfo.code])
            end
        elseif szKey == PostKey.UPDATE_FACE_INFO then
            if tInfo and tInfo.code and tInfo.code == 1 then
                local tData = tInfo.data
                if tData then
                    local szShareID = tostring(tData.share_id)
                    Event.Dispatch(EventType.OnUpdateFaceCodeInfo, szShareID)
                    if szShareID == FaceCodeData.szUpdateFaceCode then
                        FaceCodeData.tModifyInfo = nil
                        FaceCodeData.szUpdateFaceCode = nil
                        FaceCodeData.szUploadCoverFileID = nil
                    end
                end
                TipsHelper.ShowNormalTip(g_tStrings.STR_SHARE_STATION_UPDATE_FACE_SUCCESS)
            else
                TipsHelper.ShowNormalTip(STATUS_CODE[tInfo.code])
            end
        elseif szKey == PostKey.DO_UPLOAD_FACE then
            if tInfo and tInfo.code and tInfo.code == 1 then
                local tData = tInfo.data
                if tData then
                    FaceCodeData.szUploadFaceFileID = tData.file_id
                    if FaceCodeData.szUploadFaceFileID and FaceCodeData.szUploadCoverFileID then
                        FaceCodeData.ReqUploadFace()
                        FaceCodeData.szUploadFaceFileID = nil
                        FaceCodeData.szUploadCoverFileID = nil
                    end
                end
            else
                TipsHelper.ShowNormalTip(g_tStrings.STR_FACE_CODE_UPLOAD_FAILED)
            end
            FaceCodeData.bBusy = false
        elseif szKey == PostKey.DO_UPLOAD_COVER then
            if tInfo and tInfo.code and tInfo.code == 1 then
                local tData = tInfo.data
                if tData then
                    FaceCodeData.szUploadCoverFileID = tData.file_id
                end
                if FaceCodeData.szUploadFaceFileID and FaceCodeData.szUploadCoverFileID then --上传新捏脸
                    FaceCodeData.ReqUploadFace()
                    FaceCodeData.szUploadFaceFileID = nil
                    FaceCodeData.szUploadCoverFileID = nil
                elseif FaceCodeData.szUpdateFaceCode then --更新已有捏脸的封面信息
                    FaceCodeData.ReqUpdateFace()
                    FaceCodeData.szUpdateFaceCode = nil
                end

                if FaceCodeData.szCoverFilePath then
                    Lib.RemoveFile(FaceCodeData.szCoverFilePath)
                    FaceCodeData.szCoverFilePath = nil
                end
            else
                TipsHelper.ShowNormalTip(STATUS_CODE[tInfo.code])
            end
            FaceCodeData.bBusy = false
        elseif szKey == PostKey.FOLLOW_FACE then
            if tInfo and tInfo.code and tInfo.code == 1 then
                Event.Dispatch(EventType.OnCollectShareCode, FaceCodeData.szCollectFaceCode)
                FaceCodeData.szCollectFaceCode = nil

                FaceCodeData.ApplyCollectList()
                TipsHelper.ShowNormalTip(g_tStrings.STR_SHARE_STATION_COLLECT_FACE_SUCCESS)
            else
                TipsHelper.ShowNormalTip(STATUS_CODE[tInfo.code])
            end
        elseif szKey == PostKey.GET_FOLLOW_FACE_LIST then
            if tInfo and tInfo.code and tInfo.code == 1 then
                local tList = tInfo.data.follow_list or {}
                local tDelayLoadCover = {}
                local tCollectData = {}
                for _, tFaceInfo in ipairs(tList) do
                    local szFaceCode = tFaceInfo.share_id
                    if szFaceCode and szFaceCode ~= "" then
                        local bDownloadCover = FaceCodeData.CheckCoverFile(szFaceCode)
                        if not bDownloadCover then
                            FaceCodeData.DoDownloadCover(tFaceInfo.cover, szFaceCode)
                            table.insert(tDelayLoadCover, szFaceCode)
                        end

                        local bHad, szSuffix = FaceCodeData.CheckFaceData(szFaceCode)
                        if not bHad then
                            FaceCodeData.DoDownloadFace(tFaceInfo.file_link, szFaceCode) --收藏的脸型好像不用全部下载下来？因为不需要解析也能取到所有的数据
                        elseif not FaceCodeData.GetFaceData(szFaceCode) then
                            local tFaceData = FaceCodeData.LoadFaceData(szFaceCode, szSuffix)
                            if not tFaceData then
                                return
                            end
                        end
                    end
                    local tbData = FaceCodeData.GetFormatData(tFaceInfo)
                    tbData.bCollect = true
                    table.insert(tCollectData, tbData)
                end
                Event.Dispatch(EventType.OnUpdateCollectShareCodeList, tCollectData, tDelayLoadCover)
            else
                TipsHelper.ShowNormalTip(STATUS_CODE[tInfo.code])
            end
        elseif szKey == PostKey.UNFOLLOW_FACE then
            if tInfo and tInfo.code and tInfo.code == 1 then
                local szFaceCode = tInfo.data.share_id
                local _, _, szFaceFilePath = FaceCodeData.CheckFaceData(szFaceCode)
                if szFaceFilePath then
                    Lib.RemoveFile(szFaceFilePath)
                end
                
                local _, szCoverFilePath = FaceCodeData.CheckCoverFile(szFaceCode)
                if szCoverFilePath then
                    Lib.RemoveFile(szCoverFilePath)
                end

                Event.Dispatch(EventType.OnUnCollectFaceCode, szFaceCode)
                FaceCodeData.ApplyCollectList()
                TipsHelper.ShowNormalTip(g_tStrings.STR_SHARE_STATION_UNCOLLECT_FACE_SUCCESS)
            else
                TipsHelper.ShowNormalTip(STATUS_CODE[tInfo.code])
            end
        elseif szKey == PostKey.GET_FACE then
            if tInfo and tInfo.code and tInfo.code == 1 then
                local tData = tInfo.data
                if tData then
                    local szFaceCode = tData.share_id
                    local bHad, szSuffix = FaceCodeData.CheckFaceData(szFaceCode)
                    if not bHad then
                        FaceCodeData.DoDownloadFace(tData.file_link, szFaceCode)
                    else
                        if not FaceCodeData.GetFaceData(szFaceCode) then
                            FaceCodeData.LoadFaceData(szFaceCode, szSuffix)
                        end
                        local szFaceDir = FaceCodeData.GetFaceFolderDir()
                        local szFilePath = string.format("%s/%s.%s", szFaceDir, tData.share_id, szSuffix)
                        Event.Dispatch(EventType.OnDownloadShareCodeData, true, tData.share_id, szFilePath)
                        FaceCodeData.szCurGetFaceCode = nil
                    end
                end
            elseif tInfo and tInfo.code and STATUS_CODE[tInfo.code] then
                TipsHelper.ShowNormalTip(STATUS_CODE[tInfo.code])
            end
			FaceCodeData.bBusy = false
        elseif szKey == PostKey.DEL_FACE then
            if tInfo and tInfo.code and tInfo.code == 1 then
                TipsHelper.ShowNormalTip("已删除云端脸型。")
            elseif tInfo and tInfo.code and STATUS_CODE[tInfo.code] then
                TipsHelper.ShowNormalTip(STATUS_CODE[tInfo.code])
            end
        elseif szKey == PostKey.DEL_BATCH_FACE then
            if tInfo and tInfo.code and tInfo.code == 1 then
                TipsHelper.ShowNormalTip("已删除云端脸型。")
            elseif tInfo and tInfo.code and STATUS_CODE[tInfo.code] then
                TipsHelper.ShowNormalTip(STATUS_CODE[tInfo.code])
            end
        elseif szKey == PostKey.GET_CONFIG then
            if tInfo and tInfo.code and tInfo.code == 1 then
                local tData = tInfo.data
                if tData then
                    local bWhiteAccount = tData.white_list_account == 1
                    local nCount = tData.upload_count
                    local nUploadLimit = tData.up_load_max_limit
                    FaceCodeData.tbFaceListConfig = {
                        bWhiteAccount = bWhiteAccount,
                        nCount = nCount,
                        nUploadLimit = nUploadLimit,
                    }
                    -- FaceCodeData.ReqGetFaceListByPage(1, nCount)
                    FaceCodeData.ReqGetFaceList()
                end
            elseif tInfo and tInfo.code and STATUS_CODE[tInfo.code] then
                TipsHelper.ShowNormalTip(STATUS_CODE[tInfo.code])
            end
        elseif szKey == PostKey.GET_FACE_RANK_LIST then
            if tInfo and tInfo.code and tInfo.code == 1 then
                local nTotalCount = tInfo.data.total_row
                local tList = tInfo.data.rank_list or {}
                local tRankList = {}
                for _, tFaceInfo in ipairs(tList) do
                    local szFaceCode = tFaceInfo.share_id
                    local bDownloadCover = FaceCodeData.CheckCoverFile(szFaceCode)
                    if not bDownloadCover then
                        FaceCodeData.DoDownloadCover(tFaceInfo.cover, szFaceCode)
                    end

                    table.insert(tRankList, FaceCodeData.GetFormatData(tFaceInfo))
                end
                Event.Dispatch(EventType.OnGetShareStationList, nTotalCount, tRankList)
            else
                TipsHelper.ShowNormalTip(STATUS_CODE[tInfo.code])
            end
        elseif szKey == PostKey.APPLY_FACE then
            -- if tInfo and tInfo.code and tInfo.code == 1 then
            --     TipsHelper.ShowNormalTip(STATUS_CODE[tInfo.code])
            -- end
        elseif szKey == PostKey.REPORT_FACE then
            if tInfo and tInfo.code and tInfo.code == 1 then
                TipsHelper.ShowNormalTip(g_tStrings.STR_SHARE_STATION_REPORT_SUCCESS)
            else
                TipsHelper.ShowNormalTip(STATUS_CODE[tInfo.code])
            end
        end

        -- LOG.TABLE({tInfo = tInfo, szKey = szKey})
        Event.Dispatch(EventType.OnFaceCodeRsp, szKey, tInfo)
    end)

    Event.Reg(FaceCodeData, "CURL_DOWNLOAD_RESULT", function ()
        local szKey = arg0
		local bSuccess = arg1
        local szFilePath = ""

        if string.find(szKey, PostKey.DOWNLOAD_FACE) then
            local nFilePathID = szKey:match(PostKey.DOWNLOAD_FACE .. "_(%d+)")
            if nFilePathID and FaceCodeData.tbDownloadFilePath[nFilePathID] then
                szFilePath = FaceCodeData.tbDownloadFilePath[nFilePathID]
            else
                return
            end

            local szFaceCode, szSuffix
            if bSuccess then
                szFilePath = string.gsub(szFilePath, "\\", "/")
                szFaceCode, szSuffix = FaceCodeData.GetFaceCodeWithURL(szFilePath)
                local tData = FaceCodeData.LoadFaceData(szFaceCode, szSuffix)
                if tData then
                    local tDelayLoadSelfData = FaceCodeData.tDelayLoadSelfData
                    if tDelayLoadSelfData and #tDelayLoadSelfData > 0 and table.contain_value(tDelayLoadSelfData, szFaceCode) then
                        for _, v in ipairs(FaceCodeData.tbSelfFaceList) do
                            if v.szFaceCode == szFaceCode then
                                if v.bNewFace then
                                    v.szSuffix = "ini"
                                else
                                    v.szSuffix = "dat"
                                end
                                v.nRoleType = tData.nRoleType
                                v.szFaceName = tData.szFileName
                                break
                            end
                        end
                        table.remove_value(tDelayLoadSelfData, szFaceCode)
                    end

                    if not FaceCodeData.tDownloadTime then
                        FaceCodeData.tDownloadTime = FaceCodeData.GetDownloadTimeData()
                    end

                    local szFileName = szFaceCode .. "." .. szSuffix
                    FaceCodeData.tDownloadTime[szFileName] = GetCurrentTime()
                    LOG.INFO("下载脸型成功！szFilePath:".. tostring(szFilePath))
                end
            else
                LOG.ERROR("下载脸型失败！")
            end

            if szFilePath and szFaceCode then
                Event.Dispatch(EventType.OnDownloadShareCodeData, bSuccess, szFaceCode, szFilePath)
            end
            if FaceCodeData.szCurGetFaceCode == szFaceCode then
                FaceCodeData.szCurGetFaceCode = nil
            end
        elseif string.find(szKey, PostKey.DOWNLOAD_COVER) then
            local szFilePathID = string.match(szKey, PostKey.DOWNLOAD_COVER .. "_(%d+)")
            if szFilePathID and FaceCodeData.tbDownloadCoverPath and FaceCodeData.tbDownloadCoverPath[szFilePathID] then
                szFilePath = FaceCodeData.tbDownloadCoverPath[szFilePathID]
                szFilePath = string.gsub(szFilePath, "\\", "/")
            else
                return
            end

            local szFaceCode = FaceCodeData.GetFaceCodeWithURL(szFilePath)
            if not bSuccess then
                Log("[ERROR]FaceCodeData Download CoverFile Fail")
            else
                if not FaceCodeData.tDownloadTime then
                    FaceCodeData.tDownloadTime = FaceCodeData.GetDownloadTimeData()
                end

                local szFileName = szFaceCode .. ".jpg"
                FaceCodeData.tDownloadTime[szFileName] = GetCurrentTime()
            end

            if szFilePath and szFaceCode then
                Event.Dispatch(EventType.OnDownloadShareCodeCover, bSuccess, szFaceCode, szFilePath)
            end
            if FaceCodeData.szCurGetFaceCode == szFaceCode then
                FaceCodeData.bBusy = false
            end
        end

    end)
end

function FaceCodeData.UnInit()
    FaceCodeData.bBusy = nil
    FaceCodeData.szFileName = nil
    FaceCodeData.szFilePath = nil
    FaceCodeData.szCurGetFaceCode = nil
    FaceCodeData.tbFaceListConfig = nil
    FaceCodeData.nLastCheckTime = nil
    FaceCodeData.bLoginRequest = nil

    FaceCodeData.szDefaultParam = nil
    FaceCodeData.szUploadCoverFileID = nil
    FaceCodeData.szUploadFaceFileID = nil
    FaceCodeData.szCoverFileName = nil
    FaceCodeData.szCoverFilePath = nil
    FaceCodeData.tFaceInfo = nil
    FaceCodeData.tModifyInfo = nil
    FaceCodeData.szUpdateFaceCode = nil
    FaceCodeData.szCollectFaceCode = nil
    FaceCodeData.tbFunAction = nil

    Event.UnReg(FaceCodeData, "WEB_SIGN_NOTIFY")
    Event.UnReg(FaceCodeData, "ON_WEB_DATA_SIGN_NOTIFY")
    Event.UnReg(FaceCodeData, "CURL_REQUEST_RESULT")
    Event.UnReg(FaceCodeData, "CURL_DOWNLOAD_RESULT")
end

function FaceCodeData.GetURL()
	local bTestMode = IsDebugClient()
    local bExp = IsVersionExp()
    if bExp then
        -- 配合体服用的专题标识：faceuploadtf240311
        return WEB_URL_TEST
    end

    if bTestMode then
        return WEB_URL
    end

    return WEB_URL
end

function FaceCodeData.ExecuteAllFunc()
    if not FaceCodeData.tbFunAction then
        return
    end
    for _, v in ipairs(FaceCodeData.tbFunAction) do
        local fnAction = v[1]
        local tParams = v[2]
        if tParams and #tParams > 0 then
            fnAction(unpack(tParams))
        else
            fnAction()
        end
    end
    FaceCodeData.tbFunAction = nil
end

function FaceCodeData.CheckSignAndExecute(bLogin, fnAction, ...)
    --校验登录Token是否还在一分钟有效期内，不在的话需要重新申请
    local nTime = GetCurrentTime()
    if bLogin then
        nTime = os.time()
    end

    if not FaceCodeData.nLastCheckTime or (nTime - FaceCodeData.nLastCheckTime > CHECK_TIME_CD) then
        if not FaceCodeData.tbFunAction then
            FaceCodeData.tbFunAction = {}
        end

        table.insert(FaceCodeData.tbFunAction, {fnAction, {...}})
        if not FaceCodeData.bLoginRequest then
            FaceCodeData.LoginAccount(bLogin)
            FaceCodeData.bLoginRequest = true
        end
    else
        if fnAction then
            fnAction(...) --基于现有的params来调用fnAction
        end
    end
end

function FaceCodeData.LoginAccount(bIsLogin)
    if bIsLogin then
        WebUrl.ApplyLoginSignWeb(ApplyLoginSignWebID, 3)
    else
        WebUrl.ApplySignWeb(ApplyLoginSignWebID, 2)
    end
end

function FaceCodeData.ReqGetFaceList()
    if not FaceCodeData.szDefaultParam then
        LOG.ERROR("FaceCodeData.ReqGetFaceList Error! szDefaultParam is nil")
        return
    end

    local szUrl = FaceCodeData.GetURL()
    local szPostUrl = string.format("%s%s?params=%s", szUrl, PostUrl.GET_FACE_LIST, FaceCodeData.szDefaultParam)
    CURL_HttpPost(PostKey.GET_FACE_LIST, szPostUrl, {}, true, 60, 60)
end

function FaceCodeData.ReqGetFaceUploadToken(szFileName, szFilePath, szSuffix)
    if not FaceCodeData.szDefaultParam then
        LOG.ERROR("FaceCodeData.ReqGetFaceUploadToken Error! szDefaultParam is nil")
        return
    end

    if string.is_nil(szFileName) then
        LOG.ERROR("FaceCodeData.ReqGetFaceUploadToken Error! szFileName is nil")
        return
    end

    if string.is_nil(szFilePath) then
        LOG.ERROR("FaceCodeData.ReqGetFaceUploadToken Error! szFilePath is nil")
        return
    end

    if string.is_nil(szSuffix) then
        LOG.ERROR("FaceCodeData.ReqGetFaceUploadToken Error! szSuffix is nil")
        return
    end

    if FaceCodeData.bBusy then
        return
    end

    FaceCodeData.bBusy = true
    FaceCodeData.szFileName = szFileName
    FaceCodeData.szFilePath = szFilePath

    local szUrl = FaceCodeData.GetURL()
    local szPostUrl = string.format("%s%s?suffix=%s&params=%s",
        szUrl,
        PostUrl.GET_FACE_UPLOAD_TOKEN,
        szSuffix,
        FaceCodeData.szDefaultParam
    )
    CURL_HttpPost(PostKey.GET_FACE_UPLOAD_TOKEN, szPostUrl, {}, true, 60, 60)
end

--获取封面上传参数
function FaceCodeData.ReqGetCoverUploadToken(szFileName, szFilePath)
    if not FaceCodeData.szDefaultParam then
        LOG.ERROR("FaceCodeData.ReqGetCoverUploadToken Error! szDefaultParam is nil")
        return
    end

    if not szFileName or not szFilePath then
        Log("[ERROR]FaceCodeData ReqGetCoverUploadToken Fail")
        return
    end

    FaceCodeData.szCoverFileName = szFileName
    FaceCodeData.szCoverFilePath = szFilePath

    local szUrl = FaceCodeData.GetURL()
    local szPostUrl = string.format("%s%s?params=%s",
        szUrl,
        PostUrl.GET_COVER_UPLOAD_TOKEN,
        FaceCodeData.szDefaultParam
    )
    CURL_HttpPost(PostKey.GET_COVER_UPLOAD_TOKEN, szPostUrl, {}, true, 60, 60)
end

function FaceCodeData.ReqUploadFace()
    local tFaceInfo = FaceCodeData.tFaceInfo
    if not tFaceInfo then
        LOG.ERROR("FaceCodeData.ReqUploadFace Error! tFaceInfo is nil")
        return
    end

    local szFaceFileID = FaceCodeData.szUploadFaceFileID
    local szCoverFileID = FaceCodeData.szUploadCoverFileID
    if not szFaceFileID or not szCoverFileID then
        LOG.ERROR(string.format("FaceCodeData.ReqUploadFace Error! szUploadFaceFileID=%s,szUploadCoverFileID=%s", tostring(szFaceFileID), tostring(szCoverFileID)))
        return
    end

    local szUrl = FaceCodeData.GetURL()
    local nFaceType = SUFFIX_2_FACE_TYPE[tFaceInfo.szSuffix]
    local szPostUrl = string.format("%s%s?file_id=%s&face_name=%s&face_desc=%s&open_status=%d&face_type=%d&body_type=%d&cover_file_id=%s&params=%s",
        szUrl,
        PostUrl.UPLOAD_FACE_WITH_INFO,
        szFaceFileID,
        UrlEncode(tFaceInfo.szFaceName),
        UrlEncode(tFaceInfo.szFaceDesc),
        tFaceInfo.nOpenStatus,
        nFaceType,
        tFaceInfo.nRoleType,
        szCoverFileID,
        FaceCodeData.szDefaultParam
    )

    CURL_HttpPost(PostKey.UPLOAD_FACE_WITH_INFO, szPostUrl, {}, true, 60, 60)
end

function FaceCodeData.ReqUpdateFace()
    local tModifyInfo = FaceCodeData.tModifyInfo or {}
    local szFaceCode = FaceCodeData.szUpdateFaceCode

    local szUrl = FaceCodeData.GetURL()
    local szPostUrl = string.format("%s%s?share_id=%s&params=%s",
        szUrl,
        PostUrl.UPDATE_FACE_INFO,
        szFaceCode,
        FaceCodeData.szDefaultParam
    )

    local szCoverFileID = FaceCodeData.szUploadCoverFileID
    if szCoverFileID then --带着封面的更新，说明云端上没有初始数据，需要传完整的数据
        szPostUrl = szPostUrl .. string.format("&cover_file_id=%s", szCoverFileID)

        if tModifyInfo.szFaceName and tModifyInfo.szFaceName ~= "" then
            szPostUrl = szPostUrl .. string.format("&face_name=%s", UrlEncode(tModifyInfo.szFaceName))
        end

        local nFaceType = SUFFIX_2_FACE_TYPE[tModifyInfo.szSuffix]
        if nFaceType then
            szPostUrl = szPostUrl .. string.format("&face_type=%s", nFaceType)
        end

        if tModifyInfo.nRoleType then
            szPostUrl = szPostUrl .. string.format("&body_type=%s", tModifyInfo.nRoleType)
        end
    end


    if tModifyInfo.szFaceDesc then
        szPostUrl = szPostUrl .. string.format("&face_desc=%s", UrlEncode(tModifyInfo.szFaceDesc))
    end

    if tModifyInfo.nOpenStatus then
        szPostUrl = szPostUrl .. string.format("&open_status=%d", tModifyInfo.nOpenStatus)
    end

    CURL_HttpPost(PostKey.UPDATE_FACE_INFO, szPostUrl, {}, true, 60, 60)
end

function FaceCodeData.ReqGetFace(szFaceCode)
    if not FaceCodeData.szDefaultParam or not szFaceCode or FaceCodeData.bBusy then
        LOG.ERROR(string.format("[ERROR]FaceCodeData ReqGetFace Fail:LoginParam=%s,FaceCode=%s,BusyState=%s", 
                                    FaceCodeData.szDefaultParam, szFaceCode, tostring(FaceCodeData.bBusy)))
        return
    end

    if string.is_nil(szFaceCode) then
        LOG.ERROR("FaceCodeData.ReqGetFace Error! szFaceCode is nil")
        return
    end

    if FaceCodeData.bBusy then
        return
    end

    FaceCodeData.bBusy = true

    local szUrl = FaceCodeData.GetURL()
    local szPostUrl = string.format("%s%s?share_id=%s&params=%s",
        szUrl,
        PostUrl.GET_FACE,
        szFaceCode,
        FaceCodeData.szDefaultParam
    )
    CURL_HttpPost(PostKey.GET_FACE, szPostUrl, {}, true, 60, 60)
    FaceCodeData.szCurGetFaceCode = szFaceCode
end

function FaceCodeData.ReqDelFace(szFaceCode)
    if not FaceCodeData.szDefaultParam or not szFaceCode then
        LOG.ERROR(string.format("[ERROR]FaceCodeData ReqGetFace Fail:LoginParam=%s,FaceCode=%s",
                                    FaceCodeData.szDefaultParam, szFaceCode))
        return
    end

    if string.is_nil(szFaceCode) then
        LOG.ERROR("FaceCodeData.ReqGetFace Error! szFaceCode is nil")
        return
    end

    local szUrl = FaceCodeData.GetURL()
    local szPostUrl = string.format("%s%s?share_id=%s&params=%s",
        szUrl,
        PostUrl.DEL_FACE,
        szFaceCode,
        FaceCodeData.szDefaultParam
    )
    CURL_HttpPost(PostKey.DEL_FACE, szPostUrl, {}, true, 60, 60)
end

function FaceCodeData.ReqDelBatchFace(tbFaceCodes)
    if not FaceCodeData.szDefaultParam  then
        LOG.ERROR(string.format("[ERROR]FaceCodeData ReqGetFace Fail:LoginParam=%s",
                                    FaceCodeData.szDefaultParam))
        return
    end

    if not tbFaceCodes or table.is_empty(tbFaceCodes) then
        LOG.ERROR("FaceCodeData.ReqGetFace Error! tbFaceCodes is nil")
        return
    end

    local nCount = #tbFaceCodes
    local szFaceCodeList = tbFaceCodes[1]
    for i = 2, nCount do
        szFaceCodeList = szFaceCodeList .. "," .. tbFaceCodes[i]
    end

    local szUrl = FaceCodeData.GetURL()
    local szPostUrl = string.format("%s%s?share_ids=%s&params=%s",
        szUrl,
        PostUrl.DEL_BATCH_FACE,
        szFaceCodeList,
        FaceCodeData.szDefaultParam
    )
    CURL_HttpPost(PostKey.DEL_BATCH_FACE, szPostUrl, {}, true, 60, 60)
end

function FaceCodeData.ReqGetConfig()
    if not FaceCodeData.szDefaultParam  then
        LOG.ERROR(string.format("[ERROR]FaceCodeData ReqGetFace Fail:LoginParam=%s",
                                    FaceCodeData.szDefaultParam))
        return
    end

    local szUrl = FaceCodeData.GetURL()
    local szPostUrl = string.format("%s%s?params=%s",
        szUrl,
        PostUrl.GET_CONFIG,
        FaceCodeData.szDefaultParam
    )
    CURL_HttpPost(PostKey.GET_CONFIG, szPostUrl, {}, true, 60, 60)
end


function FaceCodeData.ReqGetFaceListByPage(nPage, nPageSize)
    if not FaceCodeData.szDefaultParam  then
        LOG.ERROR(string.format("[ERROR]FaceCodeData ReqGetFace Fail:LoginParam=%s",
                                    FaceCodeData.szDefaultParam))
        return
    end

    if not nPage or not nPageSize then
        LOG.ERROR("FaceCodeData.ReqGetFace Error! nPage or nPageSize is nil")
        return
    end

    local szUrl = FaceCodeData.GetURL()
    local szPostUrl = string.format("%s%s?page=%d&page_size=%d&params=%s",
        szUrl,
        PostUrl.FACES_LIST_BY_PAGING,
        nPage,
        nPageSize,
        FaceCodeData.szDefaultParam
    )
    CURL_HttpPost(PostKey.FACES_LIST_BY_PAGING, szPostUrl, {}, true, 60, 60)
end

------------------捏脸站相关----------------------
function FaceCodeData.ReqCollectFace(szFaceCode)
    if not szFaceCode then
        Log("[ERROR]FaceCodeData ReqCollectFace Fail:szFaceCode")
        return
    end

    FaceCodeData.szCollectFaceCode = szFaceCode

    local szUrl = FaceCodeData.GetURL()
    local szPostUrl = string.format("%s%s?share_id=%s&params=%s",
        szUrl,
        PostUrl.FOLLOW_FACE,
        szFaceCode,
        FaceCodeData.szDefaultParam
    )
    CURL_HttpPost(PostKey.FOLLOW_FACE, szPostUrl, nil, true, 60, 60)
end

function FaceCodeData.ReqGetCollectList()
    local szUrl = FaceCodeData.GetURL()
    local szPostUrl = string.format("%s%s?params=%s",
        szUrl,
        PostUrl.GET_FOLLOW_FACE_LIST,
        FaceCodeData.szDefaultParam
    )
    CURL_HttpPost(PostKey.GET_FOLLOW_FACE_LIST, szPostUrl, nil, true, 60, 60)
end

function FaceCodeData.ReqUnCollectFace(szFaceCode)
    if not szFaceCode then
        Log("[ERROR]FaceCodeData ReqUnCollectFace Fail:szFaceCode")
        return
    end

    local szUrl = FaceCodeData.GetURL()
    local szPostUrl = string.format("%s%s?share_id=%s&params=%s",
        szUrl,
        PostUrl.UNFOLLOW_FACE,
        szFaceCode,
        FaceCodeData.szDefaultParam
    )
    CURL_HttpPost(PostKey.UNFOLLOW_FACE, szPostUrl, nil, true, 60, 60)
end

function FaceCodeData.ReqApplyFace(szFaceCode)
    if not szFaceCode then
        Log("[ERROR]FaceCodeData ReqApplyFace Fail:szFaceCode")
        return
    end

    local szUrl = FaceCodeData.GetURL()
    local szPostUrl = string.format("%s%s?share_id=%s&params=%s",
        szUrl,
        PostUrl.APPLY_FACE,
        szFaceCode,
        FaceCodeData.szDefaultParam
    )
    CURL_HttpPost(PostKey.APPLY_FACE, szPostUrl, nil, true, 60, 60)
end

function FaceCodeData.ReqReportFace(szFaceCode, szReportReason)
    if not szFaceCode or not szReportReason then
        LOG.ERROR("[ERROR]FaceCodeData ReqReportFace Fail:szFaceCode,szReportReason")
        return
    end

    local szUrl = FaceCodeData.GetURL()
    local szPostUrl = string.format("%s%s?share_id=%s&reason=%s&params=%s",
        szUrl,
        PostUrl.REPORT_FACE,
        szFaceCode,
        szReportReason,
        FaceCodeData.szDefaultParam
    )
    CURL_HttpPost(PostKey.REPORT_FACE, szPostUrl, nil, true, 60, 60)
end

function FaceCodeData.ReqGetFaceStationData(szSuffix, nRoleType, nPage, nPageSize, szRankType, szSearch)
    if not szSuffix or not nPage or not nPageSize or not szRankType then
        LOG.ERROR(string.format("[ERROR]FaceCodeData ReqGetFaceStationData Fail:szSuffix=%s,nPage=%s,nPageSize=%s,szRankType=%s,",
            tostring(szSuffix),tostring(nPage), tostring(nPageSize), tostring(szRankType)))
        return
    end

    local nFaceType = SUFFIX_2_FACE_TYPE[szSuffix]

    local szUrl = FaceCodeData.GetURL()
    local szPostUrl = string.format("%s%s?face_type=%d&page=%d&page_size=%d&rank_type=%s&params=%s",
        szUrl,
        PostUrl.GET_FACE_RANK_LIST,
        nFaceType,
        nPage or 1,
        nPageSize,
        szRankType,
        FaceCodeData.szDefaultParam
    )
    if nRoleType then
        szPostUrl = szPostUrl .. string.format("&body_type=%s", nRoleType)
    end
    if szSearch and szSearch ~= "" then
        szPostUrl = szPostUrl .. string.format("&keyword=%s", UrlEncode(szSearch))
    end
    CURL_HttpPost(PostKey.GET_FACE_RANK_LIST, szPostUrl, {}, true, 60, 60)
end

--检查图片是否包含人脸
function FaceCodeData.ReqFaceCheckValid(szFilePath)
    if not szFilePath then
        LOG.ERROR("[ERROR]FaceCodeData ReqFaceCheckValid Fail")
        return
    end

    FaceCodeData.szCheckValidCoverPath = szFilePath
    local tbParams = {
		upload_file =
		{
			key = "file",
			content_type = "image/jpeg",
			file = szFilePath,
			filename = "FaceStationUploadCover.jpg",
		},
	}
	CURL_HttpPost(PostKey.FACE_CHECK_VALID, CURL_FACE_CHECK_VALID, tbParams, true, 60, 60)
end

--从云端下载封面
function FaceCodeData.DoDownloadCover(szUrl, szFaceCode)
    if not szUrl or not szFaceCode then
        return
    end

    local szFilePath = FaceCodeData.GetCoverFilePath(szFaceCode)

    if not FaceCodeData.tbDownloadCoverPath then
        FaceCodeData.tbDownloadCoverPath = {}
    end

    local szID = tostring(table.get_len(FaceCodeData.tbDownloadCoverPath) + 1)
    FaceCodeData.tbDownloadCoverPath[szID] = szFilePath
    CURL_DownloadFile(string.format("%s_%s", PostKey.DOWNLOAD_COVER, szID), szUrl, szFilePath, true, 60, 60)
end


function FaceCodeData.DoUploadFace(szUrl, tbUploadToken)
    if string.is_nil(szUrl) then
        LOG.ERROR("FaceCodeData.DoUploadFace Error! szUrl is nil")
        return
    end

    if not tbUploadToken or table.is_empty(tbUploadToken) then
        LOG.ERROR("FaceCodeData.DoUploadFace Error! tbUploadToken is nil")
        return
    end

    -- GetFaceLiftManager().UploadCloudFile(UploadCloudKey, 1, CLOUD_SERVICE_TYPE.QINIU, CLOUD_SERVICE_PREPROCESS_TYPE.NONE,
    --     szUrl, tbUploadToken.key, tbUploadToken.token,
    --     FaceCodeData.szFileName, UIHelper.UTF8ToGBK(FaceCodeData.szFilePath),
    --     CLOUD_SERVICE_FILE_TYPE.STREAM)

    local szFilePath = FaceCodeData.szFilePath
    local tbParams = {
        upload_file =
		{
			key = "file",
			content_type = "application/octet-stream",
			file = szFilePath,
            filename = UrlEncode(FaceCodeData.szFileName),
		},
        name = UrlEncode(FaceCodeData.szFileName),
        key = tbUploadToken.key,
        token = tbUploadToken.token,
        domain = tbUploadToken.domain,
    }
    CURL_HttpPost(PostKey.DO_UPLOAD_FACE, szUrl, tbParams, true, 60, 60)
end

--上传封面图片至云端
function FaceCodeData.DoUploadCover(szUrl, tbUploadToken)
    if not szUrl then
        Log("[ERROR]FaceCodeData DoUploadCover Fail:szUrl")
        return
    end

    if not tbUploadToken or IsTableEmpty(tbUploadToken) then
        Log("[ERROR]FaceCodeData DoUploadCover Fail:tbUploadToken")
        return
    end

    local tbParams = {
        upload_file =
		{
			key = "file",
			content_type = "image/jpeg",
			file = FaceCodeData.szCoverFilePath,
            filename = FaceCodeData.szCoverFileName,
		},
        name = FaceCodeData.szCoverFileName,
        key = tbUploadToken.key,
        token = tbUploadToken.token,
        domain = tbUploadToken.domain,
    }
    CURL_HttpPost(PostKey.DO_UPLOAD_COVER, szUrl, tbParams, true, 60, 60)
end

function FaceCodeData.DoDownloadFace(szUrl, szFileName)
    if string.is_nil(szUrl) then
        LOG.ERROR("FaceCodeData.DoDownloadFace Error! szUrl is nil")
        return
    end

    if string.is_nil(szFileName) then
        LOG.ERROR("FaceCodeData.DoDownloadFace Error! szFileName is nil")
        return
    end

    local _, szSuffix = FaceCodeData.GetFaceCodeWithURL(szUrl)
    if string.is_nil(szSuffix) then
        LOG.ERROR("FaceCodeData.DoDownloadFace Error! szSuffix is nil")
        return
    end

    local szFaceDir = FaceCodeData.GetFaceFolderDir(true)
    local szFilePath = string.format("%s/%s.%s", szFaceDir, szFileName, szSuffix)
    szFilePath = string.gsub(szFilePath, "\\", "/")

    -- GetFaceLiftManager().DownloadCloudFile(DownloadCloudKey, 1, CLOUD_SERVICE_TYPE.QINIU, CLOUD_SERVICE_PREPROCESS_TYPE.NONE,
    --     szUrl, szFilePath,
    --     CLOUD_SERVICE_FILE_TYPE.STREAM)

    FaceCodeData.tbDownloadFilePath = FaceCodeData.tbDownloadFilePath or {}

    local szID = tostring(table.get_len(FaceCodeData.tbDownloadFilePath) + 1)
    FaceCodeData.tbDownloadFilePath[szID] = szFilePath
    CURL_DownloadFile(string.format("%s_%s", PostKey.DOWNLOAD_FACE, szID), szUrl, szFilePath, true, 60, 60)
end

function FaceCodeData.OnWebDataSignNotify()
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
		FaceCodeData.OnLoginAccount(dwApplyWebID, uSign, nTime, nZoneID, dwCenterID, false)
	end
end

function FaceCodeData.OnLoginWebDataSignNotify()
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
		FaceCodeData.OnLoginAccount(dwApplyWebID, uSign, nTime, nZoneID, dwCenterID, true)
	end
end

function FaceCodeData.OnLoginAccount(dwID, uSign, nTime, nZoneID, dwCenterID, bLogin)
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

    FaceCodeData.szDefaultParam = szDefaultParam
    -- local szUrl = FaceCodeData.GetURL()
    -- local szPostUrl = string.format("%s%s?%s", szUrl, PostUrl.LOGIN_ACCOUNT, szDefaultParam)
    -- CURL_HttpPost(PostKey.LOGIN_ACCOUNT, szPostUrl, {}, true, 60, 60)
end

function FaceCodeData.GetFormatData(tInfo)
    local tData = {}
    local szFaceCode = tInfo.share_id
    tData.szFaceCode = szFaceCode
    tData.nRoleType = tInfo.body_type --体型
    tData.szCoverFileLink = tInfo.cover
    tData.szCoverPath = FaceCodeData.GetCoverFilePath(szFaceCode) --封面路径
    tData.dwCreateTime = tInfo.create_time --上传时间
    tData.szFaceDesc = tInfo.face_desc --描述
    tData.szFaceName = tInfo.face_name --名字
    tData.szSuffix = FACE_TYPE_2_SUFFIX[tInfo.face_type] --类型
    tData.nHeat = tInfo.heat --总热度
    tData.nOpenStatus = tInfo.open_status --作品状态，包括：公开、私密、隐藏、审核中、审核失败、已删除
    tData.szUser = tInfo.user --作者
    tData.szFaceFileLink = tInfo.file_link --捏脸文件下载链接
    tData.dwCollectID = tInfo.id --收藏ID

    return tData
end

function FaceCodeData.GetCoverFilePath(szFaceCode)
    local szFaceDir = FaceCodeData.GetFaceFolderDir()
    local szFilePath = string.format("%s/%s.jpg", szFaceDir, szFaceCode)
    szFilePath = string.gsub(szFilePath, "\\", "/")
    return szFilePath
end

function FaceCodeData.GetFaceFolderDir(bDownload)
    local szFaceDir = (Platform.IsMac() and not bDownload) and FACE_CODE_FILE_PATH or GetFullPath(FACE_CODE_FILE_PATH)
	CPath.MakeDir(szFaceDir)

    return szFaceDir
end

function FaceCodeData.CheckCoverFile(szFaceCode)
    local szFilePath = FaceCodeData.GetCoverFilePath(szFaceCode)
    if Lib.IsFileExist(szFilePath, false) then
        return true, szFilePath
    end
    return false
end

function FaceCodeData.CheckFaceData(szFaceCode)
    local tbCheckSuffix = {"ini", "dat"}
    local szFaceDir = FaceCodeData.GetFaceFolderDir()

    for _, szSuffix in ipairs(tbCheckSuffix) do
        local szFilePath = string.format("%s/%s.%s", szFaceDir, szFaceCode, szSuffix)
        szFilePath = string.gsub(szFilePath, "\\", "/")
        if Lib.IsFileExist(szFilePath, false) then
            LOG.INFO("FaceCodeData CheckFaceData szFilePath = "..szFilePath.." size = "..Lib.GetFileSize(szFilePath))
            return true, szSuffix, szFilePath
        end
    end

    return false
end

function FaceCodeData.LoadFaceData(szFaceCode, szSuffix)
    local szFaceDir = FaceCodeData.GetFaceFolderDir()
    local szFilePath = string.format("%s/%s.%s", szFaceDir, szFaceCode, szSuffix)
    szFilePath = string.gsub(szFilePath, "\\", "/")

    local tbData
    if szSuffix == "ini" then
        tbData = NewFaceData.LoadFaceData(szFilePath)
    elseif szSuffix == "dat" then
        tbData = NewFaceData.LoadOldFaceData(szFilePath)
    end

    if tbData then
        FaceCodeData.SetFaceData(szFaceCode, tbData)
    end

    return tbData
end

function FaceCodeData.SetFaceData(szFaceCode, tbData)
    FaceCodeData.tbCacheFaceData = FaceCodeData.tbCacheFaceData or {}
    FaceCodeData.tbCacheFaceData[szFaceCode] = tbData
    Event.Dispatch(EventType.OnUpdateShareCodeListCell, szFaceCode)
end

function FaceCodeData.GetFaceData(szFaceCode)
    FaceCodeData.tbCacheFaceData = FaceCodeData.tbCacheFaceData or {}
    return FaceCodeData.tbCacheFaceData[szFaceCode]
end

function FaceCodeData.GetFaceCodeWithURL(szUrl)
    local szFaceCode, szSuffix = string.match(szUrl, ".+/([^/]+)%.([a-zA-Z0-9]+)$")
    return szFaceCode, szSuffix
end

function FaceCodeData.GetCoverFileName()
    return COVER_FILE_NAME
end

function FaceCodeData.CheckValid(szFilePath)
    if not Lib.IsFileExist(szFilePath, false) then
		Log("[error]FaceCodeData CheckValid FilePath not Exist")
		return
	end

	-- local nSize = GetUnpakFileSize(szFilePath)
	-- if nSize == 0 then
	-- 	Log("[error]FaceCodeData CheckValid File Is Empty")
	-- 	return
	-- end

	-- if nSize > COVER_FILE_MAX_SIZE then
	-- 	Log("[error]FaceCodeData CheckValid File Oversize")
	-- 	return
	-- end

    FaceCodeData.ReqFaceCheckValid(szFilePath)
end

--tFaceInfo = {szFaceName, szSuffix, szFaceDesc, nOpenStatus, nRoleType}
--上传捏脸数据
function FaceCodeData.UploadFaceData(bLogin, szFaceFilePath, szCoverFilePath, tFaceInfo, bCopyToClip)
    if not szFaceFilePath or not szCoverFilePath or not tFaceInfo then
        Log("[error]FaceCodeData UploadFaceData Fail")
        return
    end

    if FaceCodeData.bBusy then
        return g_tStrings.STR_SHARE_STATION_UPLOAD_COVER_BUSY
    end

    FaceCodeData.tFaceInfo = tFaceInfo
    FaceCodeData.bCopyToClip = bCopyToClip

    local szUploadFaceSuffix = "." .. tFaceInfo.szSuffix
    local szFaceFileName = tFaceInfo.szFaceName .. "." .. tFaceInfo.szSuffix
    local szCoverFileName = tFaceInfo.szFaceName .. ".jpg"
    FaceCodeData.CheckSignAndExecute(bLogin, FaceCodeData.UploadFaceToStation, szFaceFileName, szFaceFilePath, szCoverFileName, szCoverFilePath, szUploadFaceSuffix)

    return g_tStrings.FACE_LIFT_CLOUD_EXPROT_SUCCESS
end

--上传捏脸至捏脸站
function FaceCodeData.UploadFaceToStation(szFaceFileName, szFaceFilePath, szCoverFileName, szCoverFilePath, szSuffix)
    FaceCodeData.ReqGetFaceUploadToken(szFaceFileName, szFaceFilePath, szSuffix)
    FaceCodeData.ReqGetCoverUploadToken(szCoverFileName, szCoverFilePath)
end

--上传封面图片(不一定需要单独的接口)
function FaceCodeData.UploadCover(bLogin, szCoverFilePath)
    FaceCodeData.CheckSignAndExecute(bLogin, FaceCodeData.ReqGetCoverUploadToken, szCoverFilePath)
end

--更新捏脸数据
function FaceCodeData.UpdateFaceData(bLogin, szFaceCode, tModifyInfo, szCoverFilePath)
    if not szFaceCode then
        Log("[error]FaceCodeData UpdateFaceData Fail")
        return
    end

    FaceCodeData.szUpdateFaceCode = szFaceCode
    FaceCodeData.tModifyInfo = tModifyInfo

    if szCoverFilePath then
        local bExist, szOldCover = FaceCodeData.CheckCoverFile(szFaceCode)
        if bExist then
            Lib.RemoveFile(szOldCover)
        end

        local szCoverFileName = szFaceCode .. ".jpg"
        FaceCodeData.CheckSignAndExecute(bLogin, FaceCodeData.ReqGetCoverUploadToken, szCoverFileName, szCoverFilePath)
    else
        FaceCodeData.CheckSignAndExecute(bLogin, FaceCodeData.ReqUpdateFace)
    end

    return g_tStrings.STR_SHARE_STATION_UPDATE_FACE
end

--申请所有捏脸数据
function FaceCodeData.ApplySelfFaceDataList(bLogin)
    FaceCodeData.CheckSignAndExecute(bLogin, FaceCodeData.ReqGetFaceList)
end

--导入数据
function FaceCodeData.ApplyFaceData(bLogin, szFaceCode)
    if not szFaceCode then
        return
    end

    if FaceCodeData.bBusy then
        return g_tStrings.FACE_DATA_IMPORT_CD
    end

    FaceCodeData.CheckSignAndExecute(bLogin, FaceCodeData.ReqGetFace, szFaceCode)
    return g_tStrings.FACE_LIFT_CLOUD_UPLOAD_SUCCESS
end

--下载数据
function FaceCodeData.DownloadFaceData(bLogin, szFaceCode)
    local bHad, szSuffix = FaceCodeData.CheckFaceData(szFaceCode)
        if not bHad then
            FaceCodeData.ApplyFaceData(bLogin, szFaceCode)
        else
            FaceCodeData.SetFaceData(szFaceCode, FaceCodeData.LoadFaceData(szFaceCode, szSuffix))
            local szFaceDir = FaceCodeData.GetFaceFolderDir()
            local szFilePath = string.format("%s/%s.%s", szFaceDir, szFaceCode, szSuffix)
            FaceCodeData.szCurGetFaceCode = szFaceCode
            Event.Dispatch(EventType.OnDownloadShareCodeData, true, szFaceCode, szFilePath)
            FaceCodeData.szCurGetFaceCode = nil
        end
end

--删除云端捏脸
function FaceCodeData.ApplyDelFaceData(bLogin, szFaceCode)
    if not szFaceCode then
        return
    end
    FaceCodeData.CheckSignAndExecute(bLogin, FaceCodeData.ReqDelFace, szFaceCode)
end

--批量删除云端捏脸
function FaceCodeData.ApplyDelFaceDataList(bLogin, tDelList)
    if not tDelList then
        return
    end
    FaceCodeData.CheckSignAndExecute(bLogin, FaceCodeData.ReqDelBatchFace, tDelList)
end

--获取所有捏脸数据
function FaceCodeData.GetMyFaceDataList()
    return clone(FaceCodeData.tbSelfFaceList) or {}
end

--申请账号基本信息
function FaceCodeData.ApplyAccountConfig(bLogin, bNeedReqAllFaceList)
    FaceCodeData.bNeedReqAllFaceList = bNeedReqAllFaceList
    FaceCodeData.CheckSignAndExecute(bLogin, FaceCodeData.ReqGetConfig)
end

--获取账号基本信息
function FaceCodeData.GetAccountConfig()
    return FaceCodeData.tbFaceListConfig
end

--上传脸型数量已达上限提示
function FaceCodeData.ShowUploadLimitMsg()
    if not FaceCodeData.tbFaceListConfig then
        Log("[FaceCodeData]Get Account Config Failed!")
        return
    end

    local nUploadLimit = FaceCodeData.tbFaceListConfig.nUploadLimit
    local _, szSuffix = FaceCodeData.GetFaceCodeWithURL(FaceCodeData.szFaceFileName)
    -- local tMsg =
    -- {
    --     bModal = true,
    --     szName = "facelift_close",
    --     bVisibleWhenHideUI = true,
    --     szMessage = FormatString(g_tStrings.FACE_LIFT_CLOUD_UPLOAD_MAX, nUploadLimit, nUploadLimit),
    --     {
    --         szOption = g_tStrings.FACE_LIFT_CLOUD_CLEAN,
    --         fnAction = function()
    --             FaceStation.Open(szSuffix, FaceCodeData.nRoleType, m_bIsLogin, "Self") --打开捏脸站-"我的"分页
    --         end
    --     },
    --     { szOption = g_tStrings.STR_HOTKEY_CANCEL },
    -- }
    -- MessageBox(tMsg)

    -- if m_bIsLogin then
    --     LoginMessage.ForceClose()
    -- end

    FaceCodeData.bBusy = false
end

--收藏捏脸
function FaceCodeData.CollectFace(bLogin, szFaceCode)
    FaceCodeData.CheckSignAndExecute(bLogin, FaceCodeData.ReqCollectFace, szFaceCode)
end

--获取收藏列表
function FaceCodeData.ApplyCollectList(bLogin)
    FaceCodeData.CheckSignAndExecute(bLogin, FaceCodeData.ReqGetCollectList)
end

--取消收藏
function FaceCodeData.UnCollectFace(bLogin, szFaceCode)
    FaceCodeData.CheckSignAndExecute(bLogin, FaceCodeData.ReqUnCollectFace, szFaceCode)
end

--采用捏脸（增加热度）
function FaceCodeData.AddFaceHeat(bLogin, szFaceCode)
    FaceCodeData.CheckSignAndExecute(bLogin, FaceCodeData.ReqApplyFace, szFaceCode)
end

--举报捏脸
function FaceCodeData.ReportFace(bLogin, szFaceCode, szReason)
    FaceCodeData.CheckSignAndExecute(bLogin, FaceCodeData.ReqReportFace, szFaceCode, szReason)
end

--获取捏脸站数据
function FaceCodeData.GetFaceStationRankList(bLogin, szSuffix, nRoleType, nPage, nPageSize, szRankType, szSearch)
    szRankType = szRankType or "total"
    FaceCodeData.CheckSignAndExecute(bLogin, FaceCodeData.ReqGetFaceStationData, szSuffix, nRoleType, nPage, nPageSize, szRankType, szSearch)
end

--------------缓存管理---------------
function FaceCodeData.IsFaceCodeInList(tList, szFaceCode)
    for _, v in ipairs(tList) do
        if szFaceCode == v.szFaceCode then
            return true
        end
    end
    return false
end

function FaceCodeData.GetDownloadTimeFilePath()
    return FACE_CODE_FILE_PATH .. "/downloadtime.dat"
end

function FaceCodeData.GetDownloadTimeData()
    local szDownloadTimeFile = FaceCodeData.GetDownloadTimeFilePath()
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
function FaceCodeData.ClearCacheData()
    if not FaceCodeData.tbSelfFaceList and not FaceCodeData.tbCollectFaceList then
        return
    end

    -- 每次打开捏脸站或退出客户端时做一次缓存清理，给facestation文件夹额定10MB大小的缓存空间，小于这个范围的情况下不做任何处理；超过这个范围做以下处理：
    -- 1.按照从旧到新的顺序清理文件，优先清理旧文件。
    -- 2.对每一个文件，如果属于【我的】或【收藏】列表，则跳过不清理；否则删除该文件。直到facestation文件夹的大小小于10MB，或遍历完所有文件，结束本轮清理。
    --（备注）downloadtime文件维护规则：默认在下载时新增条目，如果清理时存在和管理条目对不上的数据则进行更新，以清理时的时间戳为准。时间戳相同的条目，先读到谁就先删谁。
    local szDir = FaceCodeData.GetFaceFolderDir()
    local szDownloadTimeFile = FaceCodeData.GetDownloadTimeFilePath()
    local tDownloadTime = FaceCodeData.tDownloadTime or FaceCodeData.GetDownloadTimeData()

    local tList = Lib.ListFiles(szDir)
    local nTotalSize = 0
    local tDelFile = {}
    local tNewDownloadTime = {}
    --计算文件夹大小，补充更新downloadtime数据
	for _, szFilePath in ipairs(tList) do
        local szFileName = string.match(szFilePath, "[^/\\]+$")
        local nSize = Lib.GetFileSize(szFilePath)
        nTotalSize = nTotalSize + nSize

        local t = SplitString(szFileName, ".")
        if t[1] ~= "downloadtime" then
            local szFaceCode = t[1]
            local nTime
            if not tDownloadTime[szFileName] then
                nTime = GetCurrentTime()
            else
                nTime = tDownloadTime[szFileName]
            end
            tNewDownloadTime[szFileName] = nTime

            if not FaceCodeData.IsFaceCodeInList(FaceCodeData.tbSelfFaceList, szFaceCode)
                and not FaceCodeData.IsFaceCodeInList(FaceCodeData.tbCollectFaceList, szFaceCode) then
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
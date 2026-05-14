MusicCodeData = MusicCodeData or {className = "MusicCodeData"}

local CURRENT_VERSION = 2
local MUSIC_URL_TEST = "https://test-ws.xoyo.com"
local MUSIC_URL = "https://ws.xoyo.com"
local ApplyLoginSignWebID = 69

local CHECK_TIME_CD = 20 * 60 * 60 --防止频繁出现登录态过期，在过期前就重新申请登录
local STATUS_SECCESS_CODE = 1
local STATUS_UPLOAD_MAX_CODE = -20104
local STATUS_LOGIN_INVALID = -14802 --登录态过期

local PostKey = {
    INSTRUMENT_LOGIN_ACCOUNT      = "INSTRUMENT_LOGIN_ACCOUNT",
    GET_INSTRUMENT_UPLOAD_TOKEN   = "GET_INSTRUMENT_UPLOAD_TOKEN",
    UPLOAD_INSTRUMENT             = "UPLOAD_INSTRUMENT",
    DO_UPLOAD_INSTRUMENT          = "DO_UPLOAD_INSTRUMENT",
    GET_INSTRUMENT_LIST           = "GET_INSTRUMENT_LIST",
    DOWNLOAD_INSTRUMENT           = "DOWNLOAD_INSTRUMENT",
    GET_INSTRUMENT                = "GET_INSTRUMENT",
    DEL_INSTRUMENT                = "DEL_INSTRUMENT",
    DEL_BATCH_INSTRUMENT          = "DEL_BATCH_INSTRUMENT",
}

local PostUrl = {
    LOGIN_ACCOUNT           = "/core/jx3tools/get_current_account",
    GET_UPLOAD_TOKEN        = "/jx3/musicupload250619/get_upload_token",
    UPLOAD_INSTRUMENT       = "/jx3/musicupload250619/upload_music",
    GET_INSTRUMENT_LIST     = "/jx3/musicupload250619/music_list",
    GET_INSTRUMENT          = "/jx3/musicupload250619/get_music",
    DEL_INSTRUMENT          = "/jx3/musicupload250619/del_music",
    DEL_BATCH_INSTRUMENT    = "/jx3/musicupload250619/del_batch_music",
}

local CURRENT_DO_TYPE = {
    UPLOAD_INSTRUMENT = 1,
    DOWNLOAD_INSTRUMENT = 2,
    DEL_INSTRUMENT = 3,
    GET_INSTRUMENT_LIST = 4,
    DEL_BATCH_INSTRUMENT = 5,
}

local Type2Args = {
    [CURRENT_DO_TYPE.UPLOAD_INSTRUMENT] = {
        szFilePath = "",
        szFileName = "",
    },
    [CURRENT_DO_TYPE.DOWNLOAD_INSTRUMENT] = {
        tNeedDownload = {},
        tNeedPlay = {},
        szCurrCode = "",
    },
    [CURRENT_DO_TYPE.DEL_INSTRUMENT] = {
        szInstrumentCode = "",
    },
    [CURRENT_DO_TYPE.DEL_BATCH_INSTRUMENT] = {
        tInstrumentCode = {},
    },
}

local STATUS_CODE = {
    [1] = "成功\n",
    [0] = "系统错误\n",
    [-10151] = "活动未开启\n",
    [-10152] = "活动配置错误\n",
    [-10153] = "活动未开始\n",
    [-10154] = "活动已结束\n",
    [-10201] = "系统处理中...\n",
    [-10701] = "未知驱动\n",
    [-14801] = "数据不合法\n",
    [-14802] = "登录态过期，请重新打开界面\n",
    [-14803] = "参数缺失\n",
    [-20103] = "账号不存在\n",
    [-20104] = "您上传的乐谱数据已达到上限\n",
    [-20105] = "缺少上传文件ID\n",
    [-20106] = "上传曲谱数据异常，请稍后再重试！\n",
    [-20107] = "缺少曲谱码\n",
    [-20108] = "曲谱码无效\n",
    [-20109] = "无效的曲谱码\n",
    [-20110] = "曲谱码文件ID无效\n",
    [-20111] = "曲谱码文件ID已存在\n",
    [-20112] = "文件后缀异常\n",
    [-20113] = "曲谱码正在审核中\n",
    [-20114] = "曲谱码不可用\n",
}

function MusicCodeData.Init()
    MusicCodeData.nCurrentDoType = 0
    MusicCodeData.szLoginAccount = nil
    MusicCodeData.nLastCheckTime = nil
    MusicCodeData.bIsLogin = false
    MusicCodeData.szSessionID = nil
    MusicCodeData.bBusy = false
    MusicCodeData.Type2Args = clone(Type2Args)
    -- Event.Reg(MusicCodeData, "WEB_SIGN_NOTIFY", function()
    --     if arg3 == 3 then
    --         MusicCodeData.OnLoginWebDataSignNotify()
    --         LOG.INFO("MusicCodeData.WEB_SIGN_NOTIFY")
    --     end
    -- end)

    -- Event.Reg(MusicCodeData, "ON_WEB_DATA_SIGN_NOTIFY", function()
    --     LOG.INFO("MusicCodeData.ON_WEB_DATA_SIGN_NOTIFY")
    --     MusicCodeData.OnWebDataSignNotify()
    -- end)

    Event.Reg(MusicCodeData, "CURL_REQUEST_RESULT", function ()
        local szKey = arg0
        local bSuccess = arg1
        local szValue = arg2

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

        if not bSuccess then
            LOG.ERROR("MusicCodeData CURL_REQUEST_RESULT FAILED!szKey:%s", szKey)
            -- LOG.TABLE({tInfo = tInfo, szKey = szKey})
            return
        end

        local tInfo, szErrMsg = JsonDecode(szValue)
        if tInfo and tInfo.code and tInfo.code == STATUS_LOGIN_INVALID then
            MusicCodeData.nLastCheckTime = nil
            LOG.ERROR("[error]InstrumentData Login State Invalid")
            TipsHelper.ShowImportantRedTip(STATUS_CODE[tInfo.code])
            return
        end

        if szKey == PostKey.INSTRUMENT_LOGIN_ACCOUNT then
            local tData = tInfo.data
            if tData then
                MusicCodeData.nLastCheckTime = GetCurrentTime()
                MusicCodeData.szSessionID = tData.session_id
                Log("InstrumentData Login Success, szSessionID:" .. MusicCodeData.szSessionID)
                if MusicCodeData.nCurrentDoType == CURRENT_DO_TYPE.UPLOAD_INSTRUMENT then
                    MusicCodeData.ReqGetUploadToken()
                elseif MusicCodeData.nCurrentDoType == CURRENT_DO_TYPE.DOWNLOAD_INSTRUMENT then
                    MusicCodeData.ReqGetInstrument()
                elseif MusicCodeData.nCurrentDoType == CURRENT_DO_TYPE.GET_INSTRUMENT_LIST then
                    MusicCodeData.ReqGetInstrumentList()
                elseif MusicCodeData.nCurrentDoType == CURRENT_DO_TYPE.DEL_INSTRUMENT then
                    MusicCodeData.ReqDeleteInstrument()
                elseif MusicCodeData.nCurrentDoType == CURRENT_DO_TYPE.DEL_BATCH_INSTRUMENT then
                    MusicCodeData.ReqDeleteBatchInstrument()
                end
            else
                MusicCodeData.nLastCheckTime = nil
                MusicCodeData.szLoginAccount = nil
                TipsHelper.ShowImportantRedTip(g_tStrings.INSTRUMENT_CLOUD_LOGIN_FAIL)
                if tInfo and tInfo.code and STATUS_CODE[tInfo.code] then
                    Log("[error]InstrumentData Login Fail, Error Code:" .. STATUS_CODE[tInfo.code])
                end
                MusicCodeData.nCurrentDoType = 0
            end
        elseif szKey == PostKey.GET_INSTRUMENT_UPLOAD_TOKEN then
            if tInfo and tInfo.code and tInfo.code == STATUS_SECCESS_CODE then
                local tData = tInfo.data
                if tData then
                    MusicCodeData.DoUploadInstrument(tData.action, tData.input_values)
                end
            else
                MusicCodeData.nCurrentDoType = 0
                if tInfo and tInfo.code and STATUS_CODE[tInfo.code] then
                    TipsHelper.ShowImportantRedTip(STATUS_CODE[tInfo.code])
                end
            end
            if tInfo and tInfo.code then
                JustLog("GET_INSTRUMENT_UPLOAD_TOKEN", tInfo.code)
            end
        elseif szKey == PostKey.DO_UPLOAD_INSTRUMENT then
            if tInfo and tInfo.code and tInfo.code == STATUS_SECCESS_CODE then
                local tData = tInfo.data
                if tData then
                    MusicCodeData.ReqUploadInstrument(tData.file_id)
                end
            else
                TipsHelper.ShowImportantRedTip(STATUS_CODE[tInfo.code])
                MusicCodeData.nCurrentDoType = 0
            end
            if tInfo and tInfo.code then
                JustLog("DO_UPLOAD_INSTRUMENT", tInfo.code)
            end
        elseif szKey == PostKey.UPLOAD_INSTRUMENT then
            if tInfo and tInfo.code and tInfo.code == STATUS_SECCESS_CODE then
                local tData = tInfo.data
                if tData then
                    local szShareID = tostring(tData.share_id)
                    SetClipboard(szShareID)
                    MusicCodeData.nCurrentDoType = 0
                    InstrumentData.ResetCloudData()
                end
                TipsHelper.ShowNormalTip(g_tStrings.STR_INSTRUMENT_CLOUD_EXPORT_FINISH)
            elseif tInfo and tInfo.code then
                MusicCodeData.nCurrentDoType = 0
                TipsHelper.ShowImportantRedTip(STATUS_CODE[tInfo.code])
            else
                MusicCodeData.nCurrentDoType = 0
            end
            if tInfo and tInfo.code then
                JustLog("UPLOAD_INSTRUMENT", tInfo.code)
            end
        elseif szKey == PostKey.GET_INSTRUMENT then
            if tInfo and tInfo.code and tInfo.code == STATUS_SECCESS_CODE then
                local tData = tInfo.data
                if tData then
                    local szInstrumentCode = tData.share_id
                    MusicCodeData.DoDownloadInstrument(tData.file_link, szInstrumentCode)
                end
            else
                MusicCodeData.nCurrentDoType = 0
            end
            if tInfo and tInfo.code then
                TipsHelper.ShowNormalTip(STATUS_CODE[tInfo.code])
            end
        elseif szKey == PostKey.GET_INSTRUMENT_LIST then
            MusicCodeData.nCurrentDoType = 0
            if tInfo and tInfo.code and tInfo.code == STATUS_SECCESS_CODE then
                local tList = tInfo.data.list or {}
                JustLog("获取列表完成", tList)
                Event.Dispatch(EventType.OnGetInstrumentList, tList)
            end
            if tInfo and tInfo.code then
                JustLog("GET_INSTRUMENT_LIST", tInfo.code)
            end
        elseif szKey == PostKey.DEL_INSTRUMENT then
            if tInfo and tInfo.code and tInfo.code == 1 then
                TipsHelper.ShowNormalTip("删除完成。")
                InstrumentData.ResetCloudData()
            elseif tInfo and tInfo.code and STATUS_CODE[tInfo.code] then
                TipsHelper.ShowNormalTip(STATUS_CODE[tInfo.code])
            end
            MusicCodeData.nCurrentDoType = 0
        elseif szKey == PostKey.DEL_BATCH_INSTRUMENT then
            if tInfo and tInfo.code and tInfo.code == 1 then
                TipsHelper.ShowNormalTip("批量删除完成。")
                InstrumentData.ResetCloudData()
            elseif tInfo and tInfo.code and STATUS_CODE[tInfo.code] then
                TipsHelper.ShowNormalTip(STATUS_CODE[tInfo.code])
            end
            MusicCodeData.nCurrentDoType = 0
        end

        -- LOG.TABLE({tInfo = tInfo, szKey = szKey})
        Event.Dispatch(EventType.OnInstrumentCodeRsp, szKey, tInfo)
    end)

    Event.Reg(MusicCodeData, "CURL_DOWNLOAD_RESULT", function ()
        local szKey = arg0
        local bSuccess = arg1
        local szInstrumentCode = string.match(szKey, PostKey.DOWNLOAD_INSTRUMENT .. "_(%w+)")
        JustLog("OnUrlDownloadResult", bSuccess, szKey, szInstrumentCode, MusicCodeData.Type2Args[CURRENT_DO_TYPE.DOWNLOAD_INSTRUMENT].tNeedDownload)
        local tNeed = MusicCodeData.Type2Args[CURRENT_DO_TYPE.DOWNLOAD_INSTRUMENT].tNeedDownload
        if tNeed[szInstrumentCode] then
            if bSuccess then
                local bNeedPlay = MusicCodeData.Type2Args[CURRENT_DO_TYPE.DOWNLOAD_INSTRUMENT].tNeedPlay[szInstrumentCode]
                Event.Dispatch(EventType.OnDownloadMusicCodeData, szInstrumentCode, bNeedPlay)
                MusicCodeData.Type2Args[CURRENT_DO_TYPE.DOWNLOAD_INSTRUMENT].tNeedPlay[szInstrumentCode] = nil
            end
            tNeed[szInstrumentCode] = nil
            local bHasNeed = false
            for _, bNeed in pairs(tNeed) do
                if bNeed then
                    bHasNeed = true
                    break
                end
            end
            if not bHasNeed then
                MusicCodeData.nCurrentDoType = 0
            end
        end
        JustLog("OnUrlDownloadResult End", MusicCodeData.nCurrentDoType)
    end)
end

function MusicCodeData.UnInit()
    MusicCodeData.bBusy = nil
    MusicCodeData.szSessionID = nil
    MusicCodeData.nCurrentDoType = nil
    MusicCodeData.szLoginAccount = nil
    MusicCodeData.nLastCheckTime = nil
    MusicCodeData.bIsLogin = false
    MusicCodeData.Type2Args = nil

    Event.UnRegAll(MusicCodeData)
end

function MusicCodeData.GetURL()
    local bTestMode = IsDebugClient()
    if bTestMode then
        return MUSIC_URL_TEST
    end

    return MUSIC_URL
end

function MusicCodeData.LoginAccount()
    WebUrl.ApplySignWeb(ApplyLoginSignWebID, 2)
end

function MusicCodeData.ReqGetInstrumentList()
    if not MusicCodeData.szSessionID then
        LOG.ERROR("MusicCodeData.ReqGetInstrumentList Error! szSessionID is nil")
        return
    end

    if MusicCodeData.nCurrentDoType ~= CURRENT_DO_TYPE.GET_INSTRUMENT_LIST then
        return
    end

    local szUrl = MusicCodeData.GetURL()
    local szPostUrl = string.format("%s%s?session_id=%s", szUrl, PostUrl.GET_INSTRUMENT_LIST, MusicCodeData.szSessionID)
    LOG.INFO("MusicCodeData.GetInstrumentList：%s", szPostUrl)
    CURL_HttpPost(PostKey.GET_INSTRUMENT_LIST, szPostUrl, {}, true, 60, 60, {["Content-Type"]="application/json"})
end

function MusicCodeData.ReqDeleteInstrument()
    if not MusicCodeData.szSessionID then
        LOG.ERROR("MusicCodeData.ReqDeleteInstrument Error! szSessionID is nil")
        return
    end

    if MusicCodeData.nCurrentDoType ~= CURRENT_DO_TYPE.DEL_INSTRUMENT then
        return
    end

    local szInstrumentCode = MusicCodeData.Type2Args[MusicCodeData.nCurrentDoType].szInstrumentCode
    if not szInstrumentCode then
        return
    end

    local szUrl = MusicCodeData.GetURL()
    local szPostUrl = string.format("%s%s?session_id=%s&share_id=%s", szUrl, PostUrl.DEL_INSTRUMENT, MusicCodeData.szSessionID, szInstrumentCode)
    LOG.INFO("MusicCodeData.DeleteInstrument：%s", szPostUrl)
    CURL_HttpPost(PostKey.DEL_INSTRUMENT, szPostUrl, {}, true, 60, 60, {["Content-Type"]="application/json"})
end

function MusicCodeData.ReqDeleteBatchInstrument()
    if not MusicCodeData.szSessionID then
        LOG.ERROR("MusicCodeData.ReqDeleteBatchInstrument Error! szSessionID is nil")
        return
    end

    if MusicCodeData.nCurrentDoType ~= CURRENT_DO_TYPE.DEL_BATCH_INSTRUMENT then
        return
    end

    local tInstrumentCode = MusicCodeData.Type2Args[MusicCodeData.nCurrentDoType].tInstrumentCode
    if not tInstrumentCode or table.is_empty(tInstrumentCode) then
        return
    end

    local szInstrumentCodes = table.concat(tInstrumentCode, ",")
    local szUrl = MusicCodeData.GetURL()
    local szPostUrl = string.format("%s%s?session_id=%s&share_ids=%s", szUrl, PostUrl.DEL_BATCH_INSTRUMENT, MusicCodeData.szSessionID, szInstrumentCodes)
    CURL_HttpPost(PostKey.DEL_BATCH_INSTRUMENT, szPostUrl, {}, true, 60, 60, {["Content-Type"]="application/json"})
end

function MusicCodeData.ReqGetUploadToken()
    if not MusicCodeData.szSessionID then
        LOG.ERROR("MusicCodeData.ReqGetUploadToken Error! szSessionID is nil")
        return
    end

    if (MusicCodeData.nCurrentDoType ~= CURRENT_DO_TYPE.UPLOAD_INSTRUMENT) or (not MusicCodeData.Type2Args[MusicCodeData.nCurrentDoType].szFilePath) then
        LOG.ERROR("[error]ReqGetUploadToken:", MusicCodeData.szSessionID, MusicCodeData.nCurrentDoType, MusicCodeData.Type2Args[MusicCodeData.nCurrentDoType].szFilePath)
        return
    end

    local szUrl = MusicCodeData.GetURL()
    local szPostUrl = string.format("%s%s?session_id=%s&suffix=%s",
        szUrl,
        PostUrl.GET_UPLOAD_TOKEN,
        MusicCodeData.szSessionID,
        ".dat")
    LOG.INFO("MusicCodeData.GetUploadToken：%s", szPostUrl)
    CURL_HttpPost(PostKey.GET_INSTRUMENT_UPLOAD_TOKEN, szPostUrl, {}, true, 60, 60, {["Content-Type"]="application/json"})
end

function MusicCodeData.ReqUploadInstrument(szFileID)
    if not MusicCodeData.szSessionID then
        LOG.ERROR("MusicCodeData.ReqUploadInstrument Error! szSessionID is nil")
        return
    end

    if not szFileID then
        LOG.ERROR("MusicCodeData.ReqUploadInstrument Error! szFileID is nil")
        return
    end

    if MusicCodeData.nCurrentDoType ~= CURRENT_DO_TYPE.UPLOAD_INSTRUMENT then
        return
    end

    local szUrl = MusicCodeData.GetURL()
    local szPostUrl = string.format("%s%s?session_id=%s&file_id=%s",
        szUrl,
        PostUrl.UPLOAD_INSTRUMENT,
        MusicCodeData.szSessionID,
        szFileID)
    LOG.INFO("MusicCodeData.UploadInstrument：%s", szPostUrl)
    CURL_HttpPost(PostKey.UPLOAD_INSTRUMENT, szPostUrl, {}, true, 60, 60, {["Content-Type"]="application/json"})
end

function MusicCodeData.ReqGetInstrument()
    if not MusicCodeData.szSessionID then
        LOG.ERROR("MusicCodeData.ReqGetInstrument Error! szSessionID is nil")
        return
    end

    if MusicCodeData.nCurrentDoType ~= CURRENT_DO_TYPE.DOWNLOAD_INSTRUMENT then
        return
    end

    local szInstrumentCode = MusicCodeData.Type2Args[MusicCodeData.nCurrentDoType].szCurrCode
    if not szInstrumentCode then
        return
    end

    local szUrl = MusicCodeData.GetURL()
    local szPostUrl = string.format("%s%s?session_id=%s&share_id=%s",
        szUrl,
        PostUrl.GET_INSTRUMENT,
        MusicCodeData.szSessionID,
        szInstrumentCode)
    LOG.INFO("MusicCodeData.GetInstrument：%s", szPostUrl)
    CURL_HttpPost(PostKey.GET_INSTRUMENT, szPostUrl, {}, true, 60, 60, {["Content-Type"]="application/json"})
end

function MusicCodeData.ReqDelInstrument(szInstrumentCode)
    if not MusicCodeData.szSessionID then
        LOG.ERROR("MusicCodeData.ReqGetInstrument Error! szSessionID is nil")
        return
    end

    if string.is_nil(szInstrumentCode) then
        LOG.ERROR("MusicCodeData.ReqGetInstrument Error! szInstrumentCode is nil")
        return
    end

    local szUrl = MusicCodeData.GetURL()
    local szPostUrl = string.format("%s%s?session_id=%s&share_id=%s",
        szUrl,
        PostUrl.DEL_INSTRUMENT,
        MusicCodeData.szSessionID,
        szInstrumentCode)
    LOG.INFO("MusicCodeData.DelInstrument：%s", szPostUrl)
    CURL_HttpPost(PostKey.DEL_INSTRUMENT, szPostUrl, {}, true, 60, 60, {["Content-Type"]="application/json"})
end

function MusicCodeData.ReqDelBatchInstrument(tbInstrumentCodes)
    if not MusicCodeData.szSessionID then
        LOG.ERROR("MusicCodeData.ReqGetInstrument Error! szSessionID is nil")
        return
    end

    if not tbInstrumentCodes or table.is_empty(tbInstrumentCodes) then
        LOG.ERROR("MusicCodeData.ReqGetInstrument Error! tbInstrumentCodes is nil")
        return
    end

    local nCount = #tbInstrumentCodes
    local szInstrumentCodeList = tbInstrumentCodes[1]
    for i = 2, nCount do
        szInstrumentCodeList = szInstrumentCodeList .. "," .. tbInstrumentCodes[i]
    end

    local szUrl = MusicCodeData.GetURL()
    local szPostUrl = string.format("%s%s?session_id=%s&share_ids=%s",
        szUrl,
        PostUrl.DEL_BATCH_INSTRUMENT,
        MusicCodeData.szSessionID,
        szInstrumentCodeList)
    LOG.INFO("MusicCodeData.DelBatchInstrument：%s", szPostUrl)
    CURL_HttpPost(PostKey.DEL_BATCH_INSTRUMENT, szPostUrl, {}, true, 60, 60, {["Content-Type"]="application/json"})
end

function MusicCodeData.ReqGetConfig()
    if not MusicCodeData.szSessionID then
        LOG.ERROR("MusicCodeData.ReqGetConfig Error! szSessionID is nil")
        return
    end

    local szUrl = MusicCodeData.GetURL()
    local szPostUrl = string.format("%s%s?session_id=%s",
        szUrl,
        PostUrl.GET_CONFIG,
        MusicCodeData.szSessionID)
    LOG.INFO("MusicCodeData.DelGetConfig：%s", szPostUrl)
    CURL_HttpPost(PostKey.GET_CONFIG, szPostUrl, {}, true, 60, 60, {["Content-Type"]="application/json"})
end

function MusicCodeData.DoUploadInstrument(szUrl, tbUploadToken)
    if string.is_nil(szUrl) then
        LOG.ERROR("MusicCodeData.DoUploadInstrument Error! szUrl is nil")
        return
    end

    if not tbUploadToken or table.is_empty(tbUploadToken) then
        LOG.ERROR("MusicCodeData.DoUploadInstrument Error! tbUploadToken is nil")
        return
    end

    if MusicCodeData.nCurrentDoType ~= CURRENT_DO_TYPE.UPLOAD_INSTRUMENT then
        return
    end

    local szFilePath = UIHelper.UTF8ToGBK(MusicCodeData.Type2Args[MusicCodeData.nCurrentDoType].szFilePath)
    if not Platform.IsWindows() then
        szFilePath = MusicCodeData.Type2Args[MusicCodeData.nCurrentDoType].szFilePath
    end

    local szFileName = MusicCodeData.GetFileNameByPath(szFilePath)
    local tbParams = {
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
    CURL_HttpPost(PostKey.DO_UPLOAD_INSTRUMENT, szUrl, tbParams, true, 60, 60, {["Content-Type"]="application/json"})
end

function MusicCodeData.DoDownloadInstrument(szUrl, szInstrumentCode)
    if string.is_nil(szUrl) then
        LOG.ERROR("MusicCodeData.DoDownloadInstrument Error! szUrl is nil")
        return
    end

    if MusicCodeData.nCurrentDoType ~= CURRENT_DO_TYPE.DOWNLOAD_INSTRUMENT then
        return
    end

    if string.is_nil(szInstrumentCode) then
        LOG.ERROR("MusicCodeData.DoDownloadInstrument Error! szInstrumentCode is nil")
        return
    end

    local _, szSuffix = MusicCodeData.GetInstrumentCodeWithURL(szUrl)
    if string.is_nil(szSuffix) then
        LOG.ERROR("MusicCodeData.DoDownloadInstrument Error! szSuffix is nil")
        return
    end

    local szInstrumentDir = MusicCodeData.GetInstrumentFolderDir(true)
    local szFilePath = string.format("%s/%s.%s", szInstrumentDir, szInstrumentCode, szSuffix)
    szFilePath = string.gsub(szFilePath, "\\", "/")

    CURL_DownloadFile(string.format("%s_%s", PostKey.DOWNLOAD_INSTRUMENT, szInstrumentCode), szUrl, szFilePath, true, 60, 60)
end

function MusicCodeData.OnWebDataSignNotify()
    local szComment = arg6
    local dwApplyWebID = szComment:match("APPLY_WEBID_(.*)")
    if dwApplyWebID then
        dwApplyWebID = tonumber(dwApplyWebID)
        local uSign = arg0
        local nTime = arg2
        local nZoneID = arg3
        local dwCenterID = arg4
        MusicCodeData.OnLoginAccount(dwApplyWebID, uSign, nTime, nZoneID, dwCenterID, false)
    end
end

function MusicCodeData.OnLoginWebDataSignNotify()
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
        MusicCodeData.OnLoginAccount(dwApplyWebID, uSign, nTime, nZoneID, dwCenterID, true)
    end
end

function MusicCodeData.OnLoginAccount(dwID, uSign, nTime, nZoneID, dwCenterID, bLogin)
    local dwPlayerID = 0
    local dwForceID = 0
    local szRoleName = ""
    local dwCreateTime = 0
    local szGlobalID = ""
    local szAccount = Login_GetAccount()
    local szDefaultParam

    if bLogin then
        --假如没登录，传的params只需要sign/account//time///////角色创建时间/账号类型
        szDefaultParam = "params=%d/%s//%d///////%d/%d"
        szDefaultParam = string.format(szDefaultParam, uSign, szAccount, nTime, dwCreateTime, GetAccountType())
    else
        local player = PlayerData.GetClientPlayer()
        if player then
            dwPlayerID = player.dwID
            dwForceID = player.dwForceID
            szRoleName =  UrlEncode(UIHelper.GBKToUTF8(player.szName))
            dwCreateTime = player.GetCreateTime()
            szGlobalID = player.GetGlobalID()
        end

        local szUserRegion, szUserSever = WebUrl.GetServerName()
        --param=sign/account/roleID/time/zoneID/centerID/测试区/测试服/门派ID/角色名称/角色创建时间/账号类型
        szDefaultParam = "params=%d/%s/%d/%d/%d/%d/%s/%s/%d/%s/%d/%d"
        szDefaultParam = string.format(
            szDefaultParam, uSign, szAccount, dwPlayerID, nTime, nZoneID,
            dwCenterID, UrlEncode(szUserRegion), UrlEncode(szUserSever),
            dwForceID, szRoleName, dwCreateTime, GetAccountType()
        )
    end

    MusicCodeData.szLoginAccount = szAccount
    MusicCodeData.szDefaultParam = szDefaultParam

    local nValidateCheckType = 1 --是否开启区服校验（内网不开启）
    if IsDebugClient() then
        nValidateCheckType = 0
    end

    local szUrl = MusicCodeData.GetURL()
    local szPostUrl = string.format("%s%s?%s&validate_zone_server=%d", szUrl, PostUrl.LOGIN_ACCOUNT, szDefaultParam, nValidateCheckType)
    LOG.INFO("MusicCodeData.OnLoginAccount：%s", szPostUrl)
    CURL_HttpPost(PostKey.INSTRUMENT_LOGIN_ACCOUNT, szPostUrl, {}, true, 60, 60, {["Content-Type"]="application/json"})
end

function MusicCodeData.GetInstrumentFolderDir(bDownload)
    local szInstrumentDir = (Platform.IsMac() and not bDownload) and "InstrumentDir" or UIHelper.GBKToUTF8(GetFullPath("InstrumentDir"))
    CPath.MakeDir(szInstrumentDir)

    return szInstrumentDir
end

function MusicCodeData.CheckInstrumentData(szInstrumentCode)
    local tbCheckSuffix = {"dat"}
    local szInstrumentDir = MusicCodeData.GetInstrumentFolderDir()

    for _, szSuffix in ipairs(tbCheckSuffix) do
        local szFilePath = string.format("%s/%s.%s", szInstrumentDir, szInstrumentCode, szSuffix)
        szFilePath = string.gsub(szFilePath, "\\", "/")
        if Lib.IsFileExist(szFilePath) then
            return true, szSuffix
        end
    end

    return false
end

function MusicCodeData.SetInstrumentData(szInstrumentCode, tbData)
    MusicCodeData.tbCacheInstrumentData = MusicCodeData.tbCacheInstrumentData or {}
    MusicCodeData.tbCacheInstrumentData[szInstrumentCode] = tbData
    Event.Dispatch(EventType.OnUpdateInstrumentCodeListCell, szInstrumentCode)
end

function MusicCodeData.GetInstrumentData(szInstrumentCode)
    MusicCodeData.tbCacheInstrumentData = MusicCodeData.tbCacheInstrumentData or {}
    return MusicCodeData.tbCacheInstrumentData[szInstrumentCode]
end

function MusicCodeData.GetInstrumentCodeWithURL(szUrl)
    local szInstrumentCode, szSuffix = string.match(szUrl, ".+/([^/]+)%.([a-zA-Z0-9]+)$")
    return szInstrumentCode, szSuffix
end

function MusicCodeData.GetLocalFilePath()
    local szPath = GetStreamAdaptiveDirPath(UIHelper.GBKToUTF8(GetFullPath("InstrumentDir")))
    CPath.MakeDir(szPath)
    local szFile = GetOpenFileName(g_tStrings.STR_INSTRUMENT_CHOOSE_FILE, g_tStrings.STR_INSTRUMENT_CLOUD_FILE .. "(*.dat)\0*.dat\0\0", szPath)
    local bFileExist = IsUnpakFileExist(szFile)
    local nSize = GetUnpakFileSize(szFile)
    if bFileExist and nSize ~= 0 then
        return szFile
    end
end

-----------------IO--------------------------

function MusicCodeData.FileUpload(szFilePath)
    local nTime = GetCurrentTime()
    local szAccount = Login_GetAccount()
    MusicCodeData.nCurrentDoType = CURRENT_DO_TYPE.UPLOAD_INSTRUMENT
    MusicCodeData.Type2Args[CURRENT_DO_TYPE.UPLOAD_INSTRUMENT].szFilePath = szFilePath
    if not szAccount or not MusicCodeData.szLoginAccount or szAccount ~= MusicCodeData.szLoginAccount then
        MusicCodeData.LoginAccount()
        return
    end
    if not MusicCodeData.nLastCheckTime or (nTime - MusicCodeData.nLastCheckTime > CHECK_TIME_CD) then
        MusicCodeData.LoginAccount()
        return
    end

    MusicCodeData.ReqGetUploadToken()
end

function MusicCodeData.FileDownload(szCode, bNeedPlay)
    local szFilePath = MusicCodeData.GetDownloadFilePath(szCode)
    if MusicCodeData.CheckInstrumentData(szCode) then
        Event.Dispatch(EventType.OnDownloadMusicCodeData, szCode, bNeedPlay)
        return
    end

    local nTime = GetCurrentTime()
    local szAccount = Login_GetAccount()
    MusicCodeData.nCurrentDoType = CURRENT_DO_TYPE.DOWNLOAD_INSTRUMENT
    MusicCodeData.Type2Args[CURRENT_DO_TYPE.DOWNLOAD_INSTRUMENT].szCurrCode = szCode
    local tNeed = MusicCodeData.Type2Args[CURRENT_DO_TYPE.DOWNLOAD_INSTRUMENT].tNeedDownload
    tNeed[szCode] = true
    if bNeedPlay then
        MusicCodeData.Type2Args[CURRENT_DO_TYPE.DOWNLOAD_INSTRUMENT].tNeedPlay[szCode] = true
    end
    if not szAccount or not MusicCodeData.szLoginAccount or szAccount ~= MusicCodeData.szLoginAccount then
        MusicCodeData.LoginAccount()
        return
    end
    if not MusicCodeData.nLastCheckTime or (nTime - MusicCodeData.nLastCheckTime > CHECK_TIME_CD) then
        MusicCodeData.LoginAccount()
        return
    end

    MusicCodeData.ReqGetInstrument()
end

function MusicCodeData.GetInstrumentList()
    local nTime = GetCurrentTime()
    local szAccount = Login_GetAccount()
    MusicCodeData.nCurrentDoType = CURRENT_DO_TYPE.GET_INSTRUMENT_LIST
    if not szAccount or not MusicCodeData.szLoginAccount or szAccount ~= MusicCodeData.szLoginAccount then
        MusicCodeData.LoginAccount()
        return
    end
    if not MusicCodeData.nLastCheckTime or (nTime - MusicCodeData.nLastCheckTime > CHECK_TIME_CD) then
        MusicCodeData.LoginAccount()
        return
    end
    MusicCodeData.ReqGetInstrumentList()
end

function MusicCodeData.DeleteInstrument(szCode)
    local nTime = GetCurrentTime()
    local szAccount = Login_GetAccount()
    MusicCodeData.nCurrentDoType = CURRENT_DO_TYPE.DEL_INSTRUMENT
    MusicCodeData.Type2Args[CURRENT_DO_TYPE.DEL_INSTRUMENT].szInstrumentCode = szCode
    if not szAccount or not MusicCodeData.szLoginAccount or szAccount ~= MusicCodeData.szLoginAccount then
        MusicCodeData.LoginAccount()
        return
    end
    if not MusicCodeData.nLastCheckTime or (nTime - MusicCodeData.nLastCheckTime > CHECK_TIME_CD) then
        MusicCodeData.LoginAccount()
        return
    end

    MusicCodeData.ReqDeleteInstrument()
end


function MusicCodeData.DeletBatchInstrument(tCode)
    local nTime = GetCurrentTime()
    local szAccount = Login_GetAccount()
    MusicCodeData.nCurrentDoType = CURRENT_DO_TYPE.DEL_BATCH_INSTRUMENT
    MusicCodeData.Type2Args[CURRENT_DO_TYPE.DEL_BATCH_INSTRUMENT].tInstrumentCode = tCode
    if not szAccount or not MusicCodeData.szLoginAccount or szAccount ~= MusicCodeData.szLoginAccount then
        MusicCodeData.LoginAccount()
        return
    end
    if not MusicCodeData.nLastCheckTime or (nTime - MusicCodeData.nLastCheckTime > CHECK_TIME_CD) then
        MusicCodeData.LoginAccount()
        return
    end
    MusicCodeData.ReqDeleteBatchInstrument()
end

function MusicCodeData.LoadLocalInstrument()
    UILog("LoadLocalInstrument")
    local szPath = MusicCodeData.GetLocalFilePath()
    return szPath
end

-- 文件处理
function MusicCodeData.FileProcess(szPath)
    JustLog("FileProcess szPath", szPath)
    local tInstrumentData = LoadLUAData(szPath, false, true, nil, true)
    if not tInstrumentData or not tInstrumentData.nVersion or tInstrumentData.nVersion > CURRENT_VERSION then
        return
    end

    if tInstrumentData.nVersion == 1 then
        tInstrumentData.szType = "sanxian"
    end

    return tInstrumentData
end

function MusicCodeData.GetCurrentTimeFilePath()
    local szPath = GetStreamAdaptiveDirPath(UIHelper.GBKToUTF8(GetFullPath("InstrumentDir")))
    CPath.MakeDir(szPath)
    local tTime = TimeToDate(GetCurrentTime())
    local szTime = string.format("%d%02d%02d-%02d%02d%02d", tTime.year, tTime.month, tTime.day, tTime.hour, tTime.minute, tTime.second)
    local szFilePath = szPath .. "/Instrument" .. "_" .. szTime .. ".dat"
    return szFilePath
end

function MusicCodeData.GetDownloadFilePath(szInstrumentCode)
    local szInstrumentDir = GetStreamAdaptiveDirPath(UIHelper.GBKToUTF8(GetFullPath("InstrumentDir")))
    CPath.MakeDir(szInstrumentDir)
    local szFilePath = string.format("%s/%s.%s", szInstrumentDir, szInstrumentCode, "dat")
    szFilePath = string.gsub(szFilePath, "\\", "/")
    return szFilePath
end

function MusicCodeData.GetFileNameByCode(szCode)
    local szFilePath = MusicCodeData.GetDownloadFilePath(szCode)
    if not Lib.IsFileExist(szFilePath) then
        return
    end
    local tData = MusicCodeData.FileProcess(szFilePath)
    if tData and tData.szFileName then
        return UIHelper.UTF8ToGBK(tData.szFileName)
    end
    return ""
end

function MusicCodeData.GetFileNameByPath(szFilePath)
    if not Lib.IsFileExist(szFilePath) then
        return
    end
    local tData = MusicCodeData.FileProcess(szFilePath)
    if tData and tData.szFileName then
        return tData.szFileName
    end
    return ""
end

function MusicCodeData.GetCurFileVersion()
    return CURRENT_VERSION
end
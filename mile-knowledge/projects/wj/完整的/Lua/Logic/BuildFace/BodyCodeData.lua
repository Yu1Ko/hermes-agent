BodyCodeData = BodyCodeData or {className = "BodyCodeData"}

local WEB_URL_TEST = "https://test-ws.xoyo.com"
local WEB_URL = "https://ws.xoyo.com"

local PostKey = {
    LOGIN_ACCOUNT           = "LOGIN_ACCOUNT",
    GET_BODY_UPLOAD_TOKEN   = "GET_BODY_UPLOAD_TOKEN",
    UPLOAD_BODY             = "UPLOAD_BODY",
    DO_UPLOAD_BODY          = "DO_UPLOAD_BODY",
    GET_BODY_LIST           = "GET_BODY_LIST",
    DOWNLOAD_BODY           = "DOWNLOAD_BODY",
    GET_BODY                = "GET_BODY",
    DEL_BODY                = "DEL_BODY",
    DEL_BATCH_BODY          = "DEL_BATCH_BODY",
}

local PostUrl = {
    LOGIN_ACCOUNT           = "/core/jx3tools/get_current_account",
    GET_BODY_UPLOAD_TOKEN   = "/jx3/bodyupload240607/get_upload_token",
    UPLOAD_BODY             = "/jx3/bodyupload240607/upload_body",
    GET_BODY_LIST           = "/jx3/bodyupload240607/bodys_list",
    GET_BODY                = "/jx3/bodyupload240607/get_body",
    DEL_BODY                = "/jx3/bodyupload240607/del_body",
    DEL_BATCH_BODY          = "/jx3/bodyupload240607/del_batch_body",
}

local ApplyLoginSignWebID = 3101
-- local UploadCloudKey = "BodyCodeFileUpload"
-- local DownloadCloudKey = "BodyCodeFileDownload"

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
    [-20104] = "您上传的体型数据已达到上限",
    [-20105] = "缺少上传文件ID",
    [-20106] = "网络异常，请稍后再重试！",
    [-20107] = "缺少分享ID",
    [-20108] = "分享ID无效",
    [-20109] = "无效的分享ID",
    [-20110] = "文件ID无效",
    [-20111] = "文件ID已存在",
    [-20112] = "文件后缀异常",
}

function BodyCodeData.Init()
    Event.Reg(BodyCodeData, "WEB_SIGN_NOTIFY", function()
		if arg3 == 3 then
			BodyCodeData.OnLoginWebDataSignNotify()
		end
    end)

    Event.Reg(BodyCodeData, "ON_WEB_DATA_SIGN_NOTIFY", function()
		BodyCodeData.OnWebDataSignNotify()
    end)

    Event.Reg(BodyCodeData, "CURL_REQUEST_RESULT", function ()
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

        if szKey == PostKey.UPLOAD_BODY then
            BodyCodeData.bBusy = false
        end

        if not bSuccess then
            LOG.ERROR("BodyCodeData CURL_REQUEST_RESULT FAILED!szKey:%s", szKey)
            return
        end

        local tInfo, szErrMsg = JsonDecode(szValue)
        -- LOG.TABLE(tInfo)
        if szKey == PostKey.LOGIN_ACCOUNT then
            local tData = tInfo.data
            if tData then
                BodyCodeData.szSessionID = tData.session_id
            end
        elseif szKey == PostKey.GET_BODY_LIST then
            if tInfo and tInfo.code and tInfo.code == 1 then
                local tbData = tInfo.data.list or {}
                BodyCodeData.tbBodyList = {}
                for _, tbInfo in ipairs(tbData) do
                    local bHad, szSuffix = BodyCodeData.CheckBodyData(tbInfo.share_id)
                    if not bHad then
                        BodyCodeData.DoDownloadBody(tbInfo.file_link, tbInfo.share_id)
                    elseif not BodyCodeData.GetBodyData(tbInfo.share_id) then
                        BodyCodeData.LoadBodyData(tbInfo.share_id, szSuffix)
                    end

                    local _, szSuffix1 = BodyCodeData.GetBodyCodeWithURL(tbInfo.file_link)
                    table.insert(BodyCodeData.tbBodyList, {
                        szBodyCode = tbInfo.share_id,
                        szSuffix = szSuffix1,
                    })
                end

                Event.Dispatch(EventType.OnUpdateBodyCodeList)
            elseif tInfo and tInfo.code and STATUS_CODE[tInfo.code] then
                TipsHelper.ShowNormalTip(STATUS_CODE[tInfo.code])
            end
        elseif szKey == PostKey.GET_BODY_UPLOAD_TOKEN then
            if tInfo and tInfo.code and tInfo.code == 1 then
                local tData = tInfo.data
                if tData then
                    BodyCodeData.DoUploadBody(tData.action, tData.input_values)
                end
            elseif tInfo and tInfo.code and STATUS_CODE[tInfo.code] then
                TipsHelper.ShowNormalTip(STATUS_CODE[tInfo.code])
                BodyCodeData.bBusy = false
            end
        elseif szKey == PostKey.UPLOAD_BODY then
            if tInfo and tInfo.code and tInfo.code == 1 then
                local tData = tInfo.data
                if tData then
                    SetClipboard(tData.share_id)
                end
                TipsHelper.ShowNormalTip("上传成功，并已复制体型分享码至剪切板")
            elseif tInfo and tInfo.code and STATUS_CODE[tInfo.code] then
                TipsHelper.ShowNormalTip(STATUS_CODE[tInfo.code])
            end
        elseif szKey == PostKey.DO_UPLOAD_BODY then
            if tInfo and tInfo.code and tInfo.code == 1 then
                local tData = tInfo.data
                if tData then
                    BodyCodeData.ReqUploadBody(tData.file_id)
                end
            else
                TipsHelper.ShowNormalTip(g_tStrings.STR_BODY_CODE_UPLOAD_FAILED)
            end
			BodyCodeData.bBusy = false
        elseif szKey == PostKey.GET_BODY then
            if tInfo and tInfo.code and tInfo.code == 1 then
                local tData = tInfo.data
                if tData then
                    local bHad, szSuffix = BodyCodeData.CheckBodyData(tData.share_id)
                    if not bHad then
                        BodyCodeData.DoDownloadBody(tData.file_link, tData.share_id)
                    else
                        local szBodyDir = BodyCodeData.GetBodyFolderDir()
                        local szFilePath = string.format("%s/%s.%s", szBodyDir, tData.share_id, szSuffix)
                        Event.Dispatch(EventType.OnDownloadBodyCodeData, true, tData.share_id, szFilePath)
                        BodyCodeData.szCurGetBodyCode = nil
                    end
                end
            elseif tInfo and tInfo.code and STATUS_CODE[tInfo.code] then
                TipsHelper.ShowNormalTip(STATUS_CODE[tInfo.code])
            end
			BodyCodeData.bBusy = false
        elseif szKey == PostKey.DEL_BODY then
            if tInfo and tInfo.code and tInfo.code == 1 then
                TipsHelper.ShowNormalTip("已删除云端体型。")
            elseif tInfo and tInfo.code and STATUS_CODE[tInfo.code] then
                TipsHelper.ShowNormalTip(STATUS_CODE[tInfo.code])
            end
        elseif szKey == PostKey.DEL_BATCH_BODY then
            if tInfo and tInfo.code and tInfo.code == 1 then
                TipsHelper.ShowNormalTip("已删除云端体型。")
            elseif tInfo and tInfo.code and STATUS_CODE[tInfo.code] then
                TipsHelper.ShowNormalTip(STATUS_CODE[tInfo.code])
            end
        end

        -- LOG.TABLE({tInfo = tInfo, szKey = szKey})
        Event.Dispatch(EventType.OnBodyCodeRsp, szKey, tInfo)
    end)

    Event.Reg(BodyCodeData, "CURL_DOWNLOAD_RESULT", function ()
        local szKey = arg0
		local bSuccess = arg1

        if not string.find(szKey, PostKey.DOWNLOAD_BODY) then
            return
        end

        local szFilePath = ""
        local nFilePathID = szKey:match(PostKey.DOWNLOAD_BODY .. "_(.*)")

        if nFilePathID and BodyCodeData.tbDownloadFilePath[nFilePathID] then
            szFilePath = BodyCodeData.tbDownloadFilePath[nFilePathID]
        else
            return
        end

        local szBodyCode, szSuffix
        if bSuccess then
			LOG.INFO("下载体型成功！szFilePath:".. tostring(szFilePath))
            szBodyCode, szSuffix = BodyCodeData.GetBodyCodeWithURL(szFilePath)
            BodyCodeData.LoadBodyData(szBodyCode, szSuffix)
		else
			LOG.ERROR("下载体型失败！")
		end

        if szFilePath and szBodyCode then
            Event.Dispatch(EventType.OnDownloadBodyCodeData, bSuccess, szBodyCode, szFilePath)
        end
        if BodyCodeData.szCurGetBodyCode == szBodyCode then
            BodyCodeData.szCurGetBodyCode = nil
        end
    end)
end

function BodyCodeData.UnInit()
    BodyCodeData.bBusy = nil
    BodyCodeData.szSessionID = nil
    BodyCodeData.szFileName = nil
    BodyCodeData.szFilePath = nil
    BodyCodeData.szCurGetBodyCode = nil

    Event.UnRegAll(BodyCodeData)
end

function BodyCodeData.GetURL()
	local bTestMode = IsDebugClient()
    if bTestMode then
        return WEB_URL_TEST
    end

    return WEB_URL
end

function BodyCodeData.LoginAccount(bIsLogin)
    if bIsLogin then
        WebUrl.ApplyLoginSignWeb(ApplyLoginSignWebID, 3)
    else
        WebUrl.ApplySignWeb(ApplyLoginSignWebID, WEB_DATA_SIGN_RQST.LOGIN)
    end
end

function BodyCodeData.ReqGetBodyList()
    if not BodyCodeData.szSessionID then
        LOG.ERROR("BodyCodeData.ReqGetBodyList Error! szSessionID is nil")
        return
    end

    local szUrl = BodyCodeData.GetURL()
    local szPostUrl = string.format("%s%s?session_id=%s", szUrl, PostUrl.GET_BODY_LIST, BodyCodeData.szSessionID)
    CURL_HttpPost(PostKey.GET_BODY_LIST, szPostUrl, {}, true, 60, 60, {["Content-Type"]="application/json"})
end

function BodyCodeData.ReqGetUploadToken(szFileName, szFilePath, szSuffix)
    if not BodyCodeData.szSessionID then
        LOG.ERROR("BodyCodeData.ReqGetUploadToken Error! szSessionID is nil")
        return
    end

    if string.is_nil(szFileName) then
        LOG.ERROR("BodyCodeData.ReqGetUploadToken Error! szFileName is nil")
        return
    end

    if string.is_nil(szFilePath) then
        LOG.ERROR("BodyCodeData.ReqGetUploadToken Error! szFilePath is nil")
        return
    end

    if string.is_nil(szSuffix) then
        LOG.ERROR("BodyCodeData.ReqGetUploadToken Error! szSuffix is nil")
        return
    end

    if BodyCodeData.bBusy then
        return
    end

    BodyCodeData.bBusy = true
    BodyCodeData.szFileName = szFileName .. szSuffix
    BodyCodeData.szFilePath = szFilePath

    local szUrl = BodyCodeData.GetURL()
    local szPostUrl = string.format("%s%s?session_id=%s&suffix=%s",
        szUrl,
        PostUrl.GET_BODY_UPLOAD_TOKEN,
        BodyCodeData.szSessionID,
        szSuffix)
    CURL_HttpPost(PostKey.GET_BODY_UPLOAD_TOKEN, szPostUrl, {}, true, 60, 60, {["Content-Type"]="application/json"})
end

function BodyCodeData.ReqUploadBody(szFileID)
    if not BodyCodeData.szSessionID then
        LOG.ERROR("BodyCodeData.ReqUploadBody Error! szSessionID is nil")
        return
    end

    if not szFileID then
        LOG.ERROR("BodyCodeData.ReqUploadBody Error! szFileID is nil")
        return
    end

    local szUrl = BodyCodeData.GetURL()
    local szPostUrl = string.format("%s%s?session_id=%s&file_id=%s",
        szUrl,
        PostUrl.UPLOAD_BODY,
        BodyCodeData.szSessionID,
        szFileID)

    CURL_HttpPost(PostKey.UPLOAD_BODY, szPostUrl, {}, true, 60, 60, {["Content-Type"]="application/json"})
end

function BodyCodeData.ReqGetBody(szBodyCode)
    if not BodyCodeData.szSessionID then
        LOG.ERROR("BodyCodeData.ReqGetBody Error! szSessionID is nil")
        return
    end

    if string.is_nil(szBodyCode) then
        LOG.ERROR("BodyCodeData.ReqGetBody Error! szBodyCode is nil")
        return
    end

    if BodyCodeData.bBusy then
        return
    end

    BodyCodeData.bBusy = true

    local szUrl = BodyCodeData.GetURL()
    local szPostUrl = string.format("%s%s?session_id=%s&share_id=%s",
        szUrl,
        PostUrl.GET_BODY,
        BodyCodeData.szSessionID,
        szBodyCode)
    CURL_HttpPost(PostKey.GET_BODY, szPostUrl, {}, true, 60, 60, {["Content-Type"]="application/json"})
    BodyCodeData.szCurGetBodyCode = szBodyCode
end

function BodyCodeData.ReqDelBody(szBodyCode)
    if not BodyCodeData.szSessionID then
        LOG.ERROR("BodyCodeData.ReqGetBody Error! szSessionID is nil")
        return
    end

    if string.is_nil(szBodyCode) then
        LOG.ERROR("BodyCodeData.ReqGetBody Error! szBodyCode is nil")
        return
    end

    local szUrl = BodyCodeData.GetURL()
    local szPostUrl = string.format("%s%s?session_id=%s&share_id=%s",
        szUrl,
        PostUrl.DEL_BODY,
        BodyCodeData.szSessionID,
        szBodyCode)
    CURL_HttpPost(PostKey.DEL_BODY, szPostUrl, {}, true, 60, 60, {["Content-Type"]="application/json"})
end

function BodyCodeData.ReqDelBatchBody(tbBodyCodes)
    if not BodyCodeData.szSessionID then
        LOG.ERROR("BodyCodeData.ReqGetBody Error! szSessionID is nil")
        return
    end

    if not tbBodyCodes or table.is_empty(tbBodyCodes) then
        LOG.ERROR("BodyCodeData.ReqGetBody Error! tbBodyCodes is nil")
        return
    end

    local nCount = #tbBodyCodes
    local szBodyCodeList = tbBodyCodes[1]
    for i = 2, nCount do
        szBodyCodeList = szBodyCodeList .. "," .. tbBodyCodes[i]
    end

    local szUrl = BodyCodeData.GetURL()
    local szPostUrl = string.format("%s%s?session_id=%s&share_ids=%s",
        szUrl,
        PostUrl.DEL_BATCH_BODY,
        BodyCodeData.szSessionID,
        szBodyCodeList)
    CURL_HttpPost(PostKey.DEL_BATCH_BODY, szPostUrl, {}, true, 60, 60, {["Content-Type"]="application/json"})
end


function BodyCodeData.DoUploadBody(szUrl, tbUploadToken)
    if string.is_nil(szUrl) then
        LOG.ERROR("BodyCodeData.DoUploadBody Error! szUrl is nil")
        return
    end

    if not tbUploadToken or table.is_empty(tbUploadToken) then
        LOG.ERROR("BodyCodeData.DoUploadBody Error! tbUploadToken is nil")
        return
    end

    -- GetBodyLiftManager().UploadCloudFile(UploadCloudKey, 1, CLOUD_SERVICE_TYPE.QINIU, CLOUD_SERVICE_PREPROCESS_TYPE.NONE,
    --     szUrl, tbUploadToken.key, tbUploadToken.token,
    --     BodyCodeData.szFileName, UIHelper.UTF8ToGBK(BodyCodeData.szFilePath),
    --     CLOUD_SERVICE_FILE_TYPE.STREAM)

    local szFilePath = UIHelper.UTF8ToGBK(BodyCodeData.szFilePath)
    if not Platform.IsWindows() then
        szFilePath = BodyCodeData.szFilePath
    end
    local tbParams = {
        upload_file =
		{
			key = "file",
			content_type = "application/octet-stream",
			file = szFilePath,
            filename = BodyCodeData.szFileName,
		},
        name = BodyCodeData.szFileName,
        key = tbUploadToken.key,
        token = tbUploadToken.token,
        domain = tbUploadToken.domain,
    }
    CURL_HttpPost(PostKey.DO_UPLOAD_BODY, szUrl, tbParams, true, 60, 60, {["Content-Type"]="application/json"})
end

function BodyCodeData.DoDownloadBody(szUrl, szFileName)
    if string.is_nil(szUrl) then
        LOG.ERROR("BodyCodeData.DoDownloadBody Error! szUrl is nil")
        return
    end

    if string.is_nil(szFileName) then
        LOG.ERROR("BodyCodeData.DoDownloadBody Error! szFileName is nil")
        return
    end

    local _, szSuffix = BodyCodeData.GetBodyCodeWithURL(szUrl)
    if string.is_nil(szSuffix) then
        LOG.ERROR("BodyCodeData.DoDownloadBody Error! szSuffix is nil")
        return
    end

    local szBodyDir = BodyCodeData.GetBodyFolderDir(true)
    local szFilePath = string.format("%s/%s.%s", szBodyDir, szFileName, szSuffix)
    szFilePath = string.gsub(szFilePath, "\\", "/")

    -- GetBodyLiftManager().DownloadCloudFile(DownloadCloudKey, 1, CLOUD_SERVICE_TYPE.QINIU, CLOUD_SERVICE_PREPROCESS_TYPE.NONE,
    --     szUrl, szFilePath,
    --     CLOUD_SERVICE_FILE_TYPE.STREAM)

    BodyCodeData.tbDownloadFilePath = BodyCodeData.tbDownloadFilePath or {}

    local szID = tostring(table.get_len(BodyCodeData.tbDownloadFilePath) + 1)
    BodyCodeData.tbDownloadFilePath[szID] = szFilePath
    CURL_DownloadFile(string.format("%s_%s", PostKey.DOWNLOAD_BODY, szID), szUrl, szFilePath, true, 60, 60)
end

function BodyCodeData.OnWebDataSignNotify()
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
		BodyCodeData.OnLoginAccount(dwApplyWebID, uSign, nTime, nZoneID, dwCenterID, false)
	end
end

function BodyCodeData.OnLoginWebDataSignNotify()
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
		BodyCodeData.OnLoginAccount(dwApplyWebID, uSign, nTime, nZoneID, dwCenterID, true)
	end
end

function BodyCodeData.OnLoginAccount(dwID, uSign, nTime, nZoneID, dwCenterID, bLogin)
    local dwPlayerID = 0
    local dwForceID = 0
    local szRoleName = ""
    local dwCreateTime = 0
    local szGlobalID = ""
	local szAccount = Login_GetAccount()
    local szDefaultParam

    if bLogin then
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

    BodyCodeData.szDefaultParam = szDefaultParam
    local szUrl = BodyCodeData.GetURL()
    local szPostUrl = string.format("%s%s?%s", szUrl, PostUrl.LOGIN_ACCOUNT, szDefaultParam)
    CURL_HttpPost(PostKey.LOGIN_ACCOUNT, szPostUrl, {}, true, 60, 60, {["Content-Type"]="application/json"})
end

function BodyCodeData.GetBodyFolderDir(bDownload)
    local szBodyDir = (Platform.IsMac() and not bDownload) and "newfacedata/facecode" or GetFullPath("newfacedata/facecode")
	CPath.MakeDir(szBodyDir)

    return szBodyDir
end

function BodyCodeData.CheckBodyData(szBodyCode)
    local tbCheckSuffix = {"dat"}
    local szBodyDir = BodyCodeData.GetBodyFolderDir()

    for _, szSuffix in ipairs(tbCheckSuffix) do
        local szFilePath = string.format("%s/%s.%s", szBodyDir, szBodyCode, szSuffix)
        szFilePath = string.gsub(szFilePath, "\\", "/")
        if Lib.IsFileExist(szFilePath) then
            return true, szSuffix
        end
    end

    return false
end

function BodyCodeData.LoadBodyData(szBodyCode, szSuffix)
    local szBodyDir = BodyCodeData.GetBodyFolderDir()
    local szFilePath = string.format("%s/%s.%s", szBodyDir, szBodyCode, szSuffix)
    szFilePath = string.gsub(szFilePath, "\\", "/")

    local tbData
    local bRet = false
    if szSuffix == "dat" then
        tbData = BuildBodyData.LoadBodyData(szFilePath)
    end

    if tbData then
        BodyCodeData.SetBodyData(szBodyCode, tbData)
        bRet = true
    end

    return bRet
end

function BodyCodeData.LoadBodyDataByPath(szFilePath, szBodyCode)
    if not szFilePath then
        return false
    end

    szFilePath = string.gsub(szFilePath, "\\", "/")

    local tbData
    local bRet = false
    tbData = BuildBodyData.LoadBodyData(szFilePath)

    if tbData then
        BodyCodeData.SetBodyData(szBodyCode, tbData)
        bRet = true
    end

    return tbData
end

function BodyCodeData.SetBodyData(szBodyCode, tbData)
    BodyCodeData.tbCacheBodyData = BodyCodeData.tbCacheBodyData or {}
    BodyCodeData.tbCacheBodyData[szBodyCode] = tbData
    Event.Dispatch(EventType.OnUpdateBodyCodeListCell, szBodyCode)
end

function BodyCodeData.GetBodyData(szBodyCode)
    BodyCodeData.tbCacheBodyData = BodyCodeData.tbCacheBodyData or {}
    return BodyCodeData.tbCacheBodyData[szBodyCode]
end

function BodyCodeData.GetBodyCodeWithURL(szUrl)
    local szBodyCode, szSuffix = string.match(szUrl, ".+/([^/]+)%.([a-zA-Z0-9]+)$")
    return szBodyCode, szSuffix
end
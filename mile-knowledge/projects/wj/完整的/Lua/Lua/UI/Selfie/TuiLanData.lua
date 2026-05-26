TuiLanData = TuiLanData or {className = "TuiLanData"}
local self = TuiLanData
local RESIZE_SCALE = 0.5
local MAX_RETRY_TIMES = 3


local DataModel = 
{
	nCntOfIsBindedReq = 0,
	szCipher = "",
	szCompressedPicPath = "",
	bIsUploading = false,
	bIsUploadingPicShouldBeCompressed = false,
	szUploadUrl = "",
	szUploadToken = "",
	szUploadKey = "",
	nFreeSpace = 0,
	szUploadPicPath = "",
	szCurrentSelectedImagePath = "",
}

TuiLanData.szShareExcuteTip = "正在分享推栏中"
TuiLanData.szShareDialogContent = "确定将图片分享至推栏App相册吗？"
TuiLanData.szShareSuccessTip = "该图片已分享至推栏APP"

function TuiLanData.Init()
	TuiLanData.StartRegCurlRequest()
end

function TuiLanData.UnInit()
	Event.UnRegAll(TuiLanData)
end

function TuiLanData.StartRegCurlRequest()
    Event.Reg(TuiLanData, "ON_WEB_DATA_SIGN_NOTIFY", function()
		local szComment = arg6
        if szComment == "REQUEST_FOR_TUILAN_IS_BINDED" then
            TuiLanData.OnIsBindRequestCallBack()
        elseif szComment == "REQUEST_FOR_TUILAN_PHPOTO_TOKEN" then
            TuiLanData.OnPhotoRequestCallBack()
        end
    end)

	Event.Reg(TuiLanData, "CURL_REQUEST_RESULT", function ()
		local szKey = arg0
		local bSuccess = arg1
		local szValue = arg2
		local uBufSize = arg3
		if szKey == "request_tuilan_is_bound" then
			TuiLanData.on_request_tuilan_is_bound(bSuccess, szValue, uBufSize)
		elseif szKey == "request_photo_token" then
			TuiLanData.on_photo_token_request(bSuccess, szValue, uBufSize)
		elseif szKey == "qiniucloud_upload" then
			TuiLanData.on_qiniucloud_upload(bSuccess, szValue, uBufSize)
		end
	end)

    Event.Reg(TuiLanData, "RESIZE_IMAGE_FINISHED", function ()
		local bResizeuccess = arg0
		local szSrcFilePath = arg1
		local szDstFilePath = arg2
		local fDestScale = arg3

        local szUploadPicPath = TuiLanData.GetUploadPicPath()
        if not szUploadPicPath then
            return
        end
        
        local szUploadPicName = CPath.GetFileName(szUploadPicPath)
        if string.find(StringLowerW(szSrcFilePath), StringLowerW(szUploadPicName)) then
            TuiLanData.SetCompressedPicPath(szDstFilePath)
            TuiLanData.SetUploadPicPath(szDstFilePath)
            if TuiLanData.CheckBeforeUploadPic(szDstFilePath) then
                TuiLanData.CurlUploadImage(szDstFilePath)
            end
        end
	end)
end

function TuiLanData.EndRegCurlRequest()
	Event.UnReg(TuiLanData, "CURL_REQUEST_RESULT")
	Event.UnReg(TuiLanData, "ON_WEB_DATA_SIGN_NOTIFY")
    Event.UnReg(TuiLanData, "RESIZE_IMAGE_FINISHED")
end

------------------------请求是否绑定---------------------------
function TuiLanData.request_tuilan_is_bound()
	local pPlayer = GetClientPlayer()
	if not pPlayer then
		return
	end

	pPlayer.ApplyWebDataSign(WEB_DATA_SIGN_RQST.LOGIN, "REQUEST_FOR_TUILAN_IS_BINDED")
end


function TuiLanData.OnIsBindRequestCallBack()
	local szCipherParam = TuiLanData.GenerateCipher()
	if not szCipherParam then
		return
	end
	TuiLanData.SetCipher(szCipherParam)
	TuiLanData.CurlIsBound()
end

function TuiLanData.CurlIsBound()
	local szCipherParam = TuiLanData.GetCipher()
	local content = {
		cipher = szCipherParam,
	}
	CURL_HttpPost("request_tuilan_is_bound", tUrl.TuiLanBindStatus, content, true, 60)
end

function TuiLanData.on_request_tuilan_is_bound(success, buff, size)
	local info = JsonDecode(buff)
	if not success or not info then
		TuiLanData.EndUploadPic(false, g_tStrings.tTuiLan.SHARE_FAIL)
		return
	end
	if not success or info.code ~= 0 then
		local nCntOfIsBindedReq = TuiLanData.GetCntOfIsBindedReq()
		if nCntOfIsBindedReq < MAX_RETRY_TIMES then
			TuiLanData.CurlIsBound()
			TuiLanData.SetCntOfIsBindedReq(nCntOfIsBindedReq + 1)
		else
			TuiLanData.SetCntOfIsBindedReq(0)
			FireInUIEvent("ON_IS_BIND_NOTIFY", SNS_BINDED_CODE.REQUEST_FAILED)
		end
	else
		TuiLanData.SetCntOfIsBindedReq(0)
		if not info.data.bound then
			FireInUIEvent("ON_IS_BIND_NOTIFY", SNS_BINDED_CODE.NOT_BINDED)
		else
			FireInUIEvent("ON_IS_BIND_NOTIFY", SNS_BINDED_CODE.BINDED)
		end
	end

end
---------------------请求上传图片的云存储信息---------------------------
function TuiLanData.request_photo_token(bShouldBeCompressed, szImagePath)
	if Platform.IsWindows() then
		szImagePath = UIHelper.UTF8ToGBK(szImagePath)
	end
	local pPlayer = GetClientPlayer()
	if not pPlayer then
		return
	end    
	TuiLanData.SetCurrentSelectedImagePath(szImagePath)
	TuiLanData.SetIsUploading(true)
	TuiLanData.SetIsUploadingPicShouldBeCompressed(bShouldBeCompressed)
	pPlayer.ApplyWebDataSign(WEB_DATA_SIGN_RQST.LOGIN, "REQUEST_FOR_TUILAN_PHPOTO_TOKEN")
end

function TuiLanData.OnPhotoRequestCallBack()
	local tMapInfo = TuiLanData.GetPlayerMapInfo()
	if not tMapInfo then
		TuiLanData.EndUploadPic(false, g_tStrings.tTuiLan.NOT_MAP_INFO)
		return
	end

	local szCipherParam = TuiLanData.GenerateCipher()
	if not szCipherParam then
		TuiLanData.EndUploadPic(false, g_tStrings.tTuiLan.NOT_TOKEN)
		return
	end
	TuiLanData.SetCipher(szCipherParam)
	local content = {
		mapName = tMapInfo.szMapName,
		coordinateX = tMapInfo.szX,
		coordinateY = tMapInfo.szY,
		coordinateZ = tMapInfo.szZ,
		cipher = szCipherParam,
		mapId = tMapInfo.szMapID,
		mapArea = tMapInfo.szMapAreaName,
	}
	TuiLanData.SetUploadPicPath(TuiLanData.GetCurrentSelectedImagePath())
	CURL_HttpPost("request_photo_token", tUrl.TuiLanForToken, content, true, 60)
end

function TuiLanData.on_photo_token_request(success, buff, size)
	local info = JsonDecode(buff)
	if not success or not info then
		TuiLanData.EndUploadPic(false, g_tStrings.tTuiLan.SHARE_FAIL)
		return
	end
	if info.code ~= 0 then
		TuiLanData.EndUploadPic(false, g_tStrings.tTuiLan[info.code])
		return
	end

	TuiLanData.SetUploadToken(info.data.uploadKey)
	TuiLanData.SetUploadKey(info.data.key)
	TuiLanData.SetUploadUrl(info.data.uploadUrl)
	TuiLanData.SetServerFreeSpace(info.data.freeSpace)

	local szOrgImagePath 		= TuiLanData.GetUploadPicPath()
	local bShouldBeCompressed 	= TuiLanData.GetIsUploadingPicShouldBeCompressed()

	if bShouldBeCompressed then
		local tInfo 		= string.split(szOrgImagePath, ".")
		Image_ResizeImageFile(szOrgImagePath, tInfo[1] .. "_scale." .. tInfo[2], RESIZE_SCALE)
		return
	end
	if TuiLanData.CheckBeforeUploadPic(szOrgImagePath) then
		TuiLanData.CurlUploadImage(szOrgImagePath) 
	end
end
-- 上传到云存储
function TuiLanData.CurlUploadImage(szPicPath)
	local szUrl = TuiLanData.GetUploadUrl()
	local szUploadToken = TuiLanData.GetUploadToken()
	local szUploadKey = TuiLanData.GetUploadKey()
	if  (not szUrl or "" == szUrl) and
		(not szUploadToken or "" == szUploadToken) and
		(not szUploadKey or "" == szUploadKey)
	then
		TuiLanData.SetIsUploading(false)
		return
	end
    local szFilePath = string.gsub(szPicPath, "\\", "/")
    local dir, name = szFilePath:match("(.*/)(.*)")
	local tHttpBody = {
		upload_file =
		{
			key = "file",
			content_type = "image/png",
			file = szFilePath,
            filename = name,
		},
		token = szUploadToken,
		key = szUploadKey,
	}

	CURL_HttpPost("qiniucloud_upload", szUrl, tHttpBody, true, 60)
end

function TuiLanData.EndUploadPic(bSuccess, szAnnounce)
	if bSuccess then
		OutputMessage("MSG_ANNOUNCE_YELLOW" , szAnnounce)
		OutputMessage("MSG_SYS" , szAnnounce .. "\n")
	else
		OutputMessage("MSG_ANNOUNCE_RED" , szAnnounce)
		OutputMessage("MSG_SYS" , szAnnounce .. "\n")
	end
	TuiLanData.ClearUploadFlag()
    if bSuccess then
        TipsHelper.ShowNormalTip("发布成功，可前往推栏APP\"我的-内容管理-相册\"中查看") 
    end
	FireUIEvent("ON_QINIUYUN_UPLOAD_FINISHED", bSuccess)
end

function TuiLanData.on_qiniucloud_upload(success, buff, size)
    local info = JsonDecode(buff)
	if not success or not info then
		TuiLanData.EndUploadPic(false, g_tStrings.tTuiLan.SHARE_FAIL)
		return
	end
	-- local szImageFullPath = GetFullPath(TuiLanData.GetCompressedPicPath())

	-- if Lib.IsPNGFileExist(szImageFullPath) then
	-- 	TuiLanData.CPath.DelFile(szImageFullPath)
	-- end

	if info.success then
		TuiLanData.EndUploadPic(true, g_tStrings.tTuiLan.SHARE_SUCCESS)
	else
		TuiLanData.EndUploadPic(false, g_tStrings.tTuiLan.SHARE_FAIL)
	end
end


function TuiLanData.GenerateCipher()
	local uSign = arg0
	local dwType = arg1
	local nTime = arg2
	local nZoneID = arg3
	local dwCenterID = arg4
	local szComment = arg6

	if dwType ~= WEB_DATA_SIGN_RQST.LOGIN then 
		return 
	end

	local pPlayer = GetClientPlayer()
	if not pPlayer then
		return 
	end

	local szAccount = Login_GetAccount()
	local szName = pPlayer.szName
	local dwID = pPlayer.dwID
	local dwForceID = pPlayer.dwForceID

    local szUserRegion, szUserSever = TuiLanData.GetServerName()
	local szCipherParam = "%d/%s/%d/%d/%d/%d/%s/%s/%d/%s/%d/%s"

	szCipherParam = string.format(
		szCipherParam, uSign, szAccount, dwID, nTime, nZoneID,
		dwCenterID, szUserRegion, szUserSever, dwForceID, szName, nTime, GetAccountType()
	)

	return szCipherParam
end

function TuiLanData.GetServerName()
	local szUserRegion, szUserSever = "", ""
    local tbRecentLoginData = Storage.RecentLogin.tbServer
    local nMaxTime, tbRecentLogin = 0, nil
    for szKey, tbLogin in pairs(tbRecentLoginData) do
        if tbLogin.nTime >= nMaxTime then
            nMaxTime = tbLogin.nTime
            tbRecentLogin = tbLogin
        end
    end

	if tbRecentLogin then
		szUserRegion, szUserSever = tbRecentLogin.szRegion, tbRecentLogin.szServer
	end

    return szUserRegion, szUserSever
end

function TuiLanData.ClearUploadFlag()
	TuiLanData.SetIsUploading(false)
	TuiLanData.SetIsUploadingPicShouldBeCompressed(nil)
	TuiLanData.SetUploadToken(nil)
	TuiLanData.SetUploadKey(nil)
	TuiLanData.SetUploadUrl(nil)
	TuiLanData.SetServerFreeSpace(nil)
	TuiLanData.SetUploadPicPath(nil)
	TuiLanData.SetCompressedPicPath(nil)
	TuiLanData.SetCurrentSelectedImagePath("")
end


----------------------Get & Set-----------------------
function TuiLanData.SetCipher(szCipher)
	DataModel.szCipher = szCipher
end

function TuiLanData.GetCipher()
	return DataModel.szCipher
end

function TuiLanData.SetCntOfIsBindedReq(nCntOfIsBindedReq)
	DataModel.nCntOfIsBindedReq = nCntOfIsBindedReq
end

function TuiLanData.GetCntOfIsBindedReq()
	return DataModel.nCntOfIsBindedReq or 0
end

function TuiLanData.SetUploadKey(szToken)
	DataModel.szUploadKey = szToken
end

function TuiLanData.GetUploadKey()
	return DataModel.szUploadKey
end

function TuiLanData.SetUploadToken(szToken)
	DataModel.szUploadToken = szToken
end

function TuiLanData.GetUploadToken()
	return DataModel.szUploadToken
end

function TuiLanData.SetUploadUrl(szUrl)
	DataModel.szUploadUrl = szUrl
end

function TuiLanData.GetUploadUrl()
	return DataModel.szUploadUrl
end

function TuiLanData.SetUploadPicPath(szImagePath)
	DataModel.szUploadPicPath = szImagePath
end

function TuiLanData.GetUploadPicPath()
	return DataModel.szUploadPicPath
end

function TuiLanData.GetCompressedPicPath()
	return DataModel.szCompressedPicPath
end

function TuiLanData.SetCompressedPicPath(szCompressedPicPath)
	DataModel.szCompressedPicPath = szCompressedPicPath
end

function TuiLanData.SetIsUploading(bIsUploading)
	DataModel.bIsUploading = bIsUploading
end

function TuiLanData.SetIsUploadingPicShouldBeCompressed(bIsUploadingPicShouldBeCompressed)
	DataModel.bIsUploadingPicShouldBeCompressed = bIsUploadingPicShouldBeCompressed
end

function TuiLanData.GetIsUploadingPicShouldBeCompressed()
	return DataModel.bIsUploadingPicShouldBeCompressed
end

function TuiLanData.SetServerFreeSpace(nFreeSpace)
	DataModel.nFreeSpace = nFreeSpace
end

function TuiLanData.GetServerFreeSpace()
	return DataModel.nFreeSpace
end

function TuiLanData.SetCurrentSelectedImagePath(szImagePath)
	DataModel.szCurrentSelectedImagePath = szImagePath
end

function TuiLanData.GetCurrentSelectedImagePath()
	return DataModel.szCurrentSelectedImagePath
end
------------------------------------------------------------
function TuiLanData.CheckBeforeUploadPic(szPicPath)
	if not Lib.IsPNGFileExist(szPicPath) then
		TuiLanData.EndUploadPic(false, g_tStrings.tTuiLan.NOT_EXIST)
		return false
	end

	local nSize =  Lib.GetFileSize(szPicPath)
	if  nSize > TuiLanData.GetServerFreeSpace() then	
		-- if szPicPath ==  TuiLanData.GetCompressedPicPath()  then
        --     Lib.RemoveFile(szPicPath)
		-- end
		TuiLanData.ClearUploadFlag()
		TuiLanData.EndUploadPic(false, g_tStrings.tTuiLan.NOT_ENOUGH_SPACE)
		return false
	end
	return true
end 
function TuiLanData.GetPlayerMapInfo()
	local pPlayer = GetClientPlayer()
	if not pPlayer then
		return
	end
	local tInfo = {}
	tInfo.dwMapID = pPlayer.GetMapID()
	tInfo.szMapName = UIHelper.GBKToUTF8(Table_GetMapName(tInfo.dwMapID))
	tInfo.szX, tInfo.szY, tInfo.szZ = tostring(pPlayer.nX), tostring(pPlayer.nY), tostring(pPlayer.nZ)
	tInfo.szMapID = tostring(tInfo.dwMapID)
	tInfo.nMapAreaID = QuestData.GetAreaID()
	tInfo.szMapAreaName = UIHelper.GBKToUTF8(MapHelper.GetMapAreaName(tInfo.dwMapID, tInfo.nMapAreaID))
	return tInfo
end
---------------------推栏相关 End-----------------------------
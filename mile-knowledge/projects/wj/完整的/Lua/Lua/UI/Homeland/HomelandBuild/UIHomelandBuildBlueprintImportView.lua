-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandBuildBlueprintImportView
-- Date: 2023-06-06 10:53:38
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandBuildBlueprintImportView = class("UIHomelandBuildBlueprintImportView")

-- 常量
local szKeyForGetBlpBasicInfo = "HomelandAskForBlpBasicInfo"
local szUrlForGetBlpBasicInfo_Test = "http://120.92.151.103/gamegw/home-blueprint/query-by-code"
local szUrlForGetBlpBasicInfo = "https://gdca-blueprint-api.xoyo.com/gamegw/home-blueprint/query-by-code"

local szKeyForAskForDownloadBlpUrl = "HomelandAskForDownloadBlpUrl"
--local szKeyForDownloadBlp = "HomelandOfficialBlp.blueprintx"
local szUrlForDownloadBlp_Test = "http://120.92.151.103/gamegw/home-blueprint/get-file-download-url"
local szUrlForDownloadBlp = "https://gdca-blueprint-api.xoyo.com/gamegw/home-blueprint/get-file-download-url"

local szDownloadCloudKeyForBlp = "HomelandOfficialBlpFile"
local szWebDataSign = "HomelandAskForDownloadBlpCipher"

function UIHomelandBuildBlueprintImportView:OnEnter()
    if not self.bInit then
		self.m_bBusy = false
		self.m_szBlpID = nil
		self.m_szAuthorName = nil
		self.m_szBlpName = nil
		self.m_szDownloadFilePath = nil

        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIHomelandBuildBlueprintImportView:OnExit()
    self.bInit = false
end

function UIHomelandBuildBlueprintImportView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnWebSite, EventType.OnClick, function ()
        Homeland_VisitWebBlps()
    end)

    UIHelper.BindUIEvent(self.BtnInput, EventType.OnClick, function ()
        if self.m_bBusy then
            TipsHelper.ShowNormalTip(g_tStrings.STR_HOMELAND_BUSY_DOWNLOADING_BLP)
            return
        end

        self.m_szBlpID = UIHelper.GetText(self.EditBox)
        self:AskForCipher()

        self.m_bBusy = true
    end)

	if Platform.IsWindows() or Platform.IsMac() then
        UIHelper.RegisterEditBoxEnded(self.EditBox, function(_editbox)
			local nLen = string.getCharLen(UIHelper.GetText(self.EditBox))
			UIHelper.SetString(self.LabelLimit, string.format("%d/%d", nLen, 22))
        end)
    else
		UIHelper.RegisterEditBoxReturn(self.EditBox, function(_editbox)
			local nLen = string.getCharLen(UIHelper.GetText(self.EditBox))
			UIHelper.SetString(self.LabelLimit, string.format("%d/%d", nLen, 22))
        end)
    end
end

function UIHomelandBuildBlueprintImportView:RegEvent()
    Event.Reg(self, "CURL_REQUEST_RESULT", function ()
        local szKey = arg0
		local bSuccess = arg1
		local szValue = arg2
		local uBufSize = arg3

		if szKey == szKeyForGetBlpBasicInfo then
			if bSuccess then
				local tInfo, szErrMsg = JsonDecode(szValue)
				if tInfo.data and tInfo.data ~= "" then
					--DownloadOfficialBlueprint(tInfo.data)
					local data = tInfo.data
					self.m_szAuthorName = UIHelper.UTF8ToGBK(data.nickname)
					self.m_szBlpName = UIHelper.UTF8ToGBK(data.title)
					self:AskForDownloadUrl()
				else
					LOG.ERROR("请求的官方蓝图的基本信息为空！szErrMsg :%s", tostring(szErrMsg))
					TipsHelper.ShowNormalTip(g_tStrings.STR_HOMELAND_ASK_FOR_BLP_BASIC_INFO_FAILED)
					self.m_bBusy = false
				end
			else
				LOG.ERROR("申请欲下载的官方蓝图的基本信息失败！")
                TipsHelper.ShowNormalTip(g_tStrings.STR_HOMELAND_ASK_FOR_BLP_BASIC_INFO_FAILED)
				self.m_bBusy = false
			end
		elseif szKey == szKeyForAskForDownloadBlpUrl then
			if bSuccess then
				local tInfo, szErrMsg = JsonDecode(szValue)
				if tInfo.data and tInfo.data ~= "" then
					self:DownloadOfficialBlueprint(tInfo.data)
				else
					LOG.ERROR("得到的下载蓝图的URL为空！szErrMsg :%s", tostring(szErrMsg))
                    TipsHelper.ShowNormalTip(g_tStrings.STR_HOMELAND_ASK_FOR_DOWNLOAD_BLP_URL_FAILED)
					self.m_bBusy = false
				end
			else
				LOG.ERROR("申请获得欲下载蓝图的URL失败！")
                TipsHelper.ShowNormalTip(g_tStrings.STR_HOMELAND_ASK_FOR_DOWNLOAD_BLP_URL_FAILED)
				self.m_bBusy = false
			end
		end
    end)

    Event.Reg(self, "ON_DOWNLOAD_CLOUD_FILE", function ()
        local szUIEvent = arg0
		local dwCustomValue = arg1
		local bSuccess = arg2 ~= 0
		local nRetCode = arg3
		LOG.INFO("=== 响应了事件 ON_DOWNLOAD_CLOUD_FILE，各个参数是：")
		if bSuccess then
			if nRetCode == 0 then
				if szUIEvent == szDownloadCloudKeyForBlp then
					LOG.INFO("下载官方蓝图成功！")
					self:OnDownloadOfficialBlpSuccess(self.m_szDownloadFilePath)
				end
			else
				LOG.ERROR("下载官方蓝图失败！ error code: " .. tostring(nRetCode))
                TipsHelper.ShowNormalTip(g_tStrings.STR_HOMELAND_DOWNLOAD_BLP_FAILED)
				self.m_bBusy = false
			end
		else
			LOG.ERROR("下载官方蓝图失败！")
            TipsHelper.ShowNormalTip(g_tStrings.STR_HOMELAND_DOWNLOAD_BLP_FAILED)
            self.m_bBusy = false
		end
    end)

	Event.Reg(self, "ON_WEB_DATA_SIGN_NOTIFY", function ()
        local szOrderSN                 = arg6
		local dwType 					= arg1
		if not (dwType == WEB_DATA_SIGN_RQST.LOGIN and szOrderSN == szWebDataSign) then
			return
		end

		local uSign                     = arg0
		local dwType 					= arg1
		local nTime                     = arg2
		local nZoneID                   = arg3
		local dwCenterID                = arg4
		local bIsFirstWebPhoneVerified  = arg5
		local szOrderSN                 = arg6

		local szCipher = Homeland_GenerateCipher(uSign, dwType, nTime, nZoneID, dwCenterID)
		Log("==== Blueprint szCipher === " .. tostring(szCipher))
		self.szCipher = szCipher
		self:AskForDownloadUrl()
    end)
end

function UIHomelandBuildBlueprintImportView:UpdateInfo()

end

function UIHomelandBuildBlueprintImportView:AskForBlpBasicInfo()
    local szUrl = (IsDebugClient() or IsVersionExp()) and szUrlForGetBlpBasicInfo_Test or szUrlForGetBlpBasicInfo
	local tData = {code=self.m_szBlpID}
	CURL_HttpPost(szKeyForGetBlpBasicInfo, szUrl, JsonEncode(tData), true, 60, 60, {["Content-Type"]="application/json"})
end

function UIHomelandBuildBlueprintImportView:AskForDownloadUrl()
    local szUrl = (IsDebugClient() or IsVersionExp()) and szUrlForDownloadBlp_Test or szUrlForDownloadBlp
	local tData = {fileDownloadCode=self.m_szBlpID, cipher = self.szCipher}
	CURL_HttpPost(szKeyForAskForDownloadBlpUrl, szUrl, JsonEncode(tData), true, 60, 60, {["Content-Type"]="application/json"}) -- 最后一个参数也可以是 {"Content-Type: application/x-www-form-urlencoded"}
end

function UIHomelandBuildBlueprintImportView:AskForCipher()
	local pPlayer = GetClientPlayer()
	if not pPlayer then
		return
	end
	pPlayer.ApplyWebDataSign(WEB_DATA_SIGN_RQST.LOGIN, szWebDataSign)
end

function UIHomelandBuildBlueprintImportView:OnDownloadOfficialBlpSuccess(szDownloadFilePath)
	local szMsg = FormatString(g_tStrings.STR_HOMELAND_DOWNLOAD_BLP_SUCCESS, Homeland_GetPathForDisplay(self:GetDownloadFolder()))

	local dialog = UIHelper.ShowConfirm(szMsg, function ()
        if not HLBOp_Check.Check() then
			return
		end
		LOG.INFO("LoadWebFileBlueprint %s", tostring(szDownloadFilePath))
		HLBOp_Blueprint.LoadWebFileBlueprint(szDownloadFilePath)
		UIMgr.Close(self)
    end)
    dialog:SetButtonContent("Confirm", g_tStrings.STR_HOMELAND_LOAD_DOWNLOADED_BLUEPRINT_FILE)

	self.m_bBusy = false
end

function UIHomelandBuildBlueprintImportView:GetDownloadFolder()
	local szBlueprintSaveFolder = Homeland_GetExportedBlpFolder()
	szBlueprintSaveFolder = szBlueprintSaveFolder .. "Official/"
	return szBlueprintSaveFolder
end

function UIHomelandBuildBlueprintImportView:DownloadOfficialBlueprint(szDownloadUrl)
	local szBlueprintSaveFolder = self:GetDownloadFolder()
	local szFileName = self.m_szBlpID
	CPath.MakeDir(szBlueprintSaveFolder)

	local szFilePath = szBlueprintSaveFolder .. szFileName .. ".blueprintx"

	self.m_szDownloadFilePath = szFilePath
	GetHomelandMgr().DownloadCloudFile(szDownloadCloudKeyForBlp, 1, CLOUD_SERVICE_TYPE.QINIU, CLOUD_SERVICE_PREPROCESS_TYPE.COMPRESS,
			szDownloadUrl, GetFullPath(szFilePath),
			CLOUD_SERVICE_FILE_TYPE.STREAM)
end


return UIHomelandBuildBlueprintImportView
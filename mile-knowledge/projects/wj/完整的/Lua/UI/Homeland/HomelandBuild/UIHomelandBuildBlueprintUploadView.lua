-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandBuildBlueprintUploadView
-- Date: 2023-06-06 17:44:30
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandBuildBlueprintUploadView = class("UIHomelandBuildBlueprintUploadView")

local MAX_TAG_NUM = 5
local _TAG_DELIMITER = ";"

local szKeyForUploadBlp = "HomelandUploadBlp"
local szUrlForUploadBlp_Test = "http://120.92.151.103/gamegw/home-blueprint/upload-keys"
local szUrlForUploadBlp = "https://gdca-blueprint-api.xoyo.com/gamegw/home-blueprint/upload-keys"

local szWebDataSign = "REQUEST_FOR_UPLOAD_BLUEPRINT"

local szUploadCloudKeyForBlp = "HomelandOfficialBlpFile"
local szUploadCloudKeyForPic = "HomelandOfficialBlpPic"

function UIHomelandBuildBlueprintUploadView:OnEnter(szFilePath, pRetTexture)
	self.szFilePath = szFilePath
	self.pRetTexture = pRetTexture

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tbTag = {}
	self:InitTagList()
    self:UpdateInfo()
end

function UIHomelandBuildBlueprintUploadView:OnExit()
    self.bInit = false
end

function UIHomelandBuildBlueprintUploadView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnUpload, EventType.OnClick, function ()
		if not HLBOp_Check.Check() then
			return
		end
		if self.m_bBusy then
			HLBView_Message.Show(g_tStrings.STR_HOMELAND_BUSY_UPLOADING_BLP, 3)
		else
			local bUplaod = true
			HLBOp_Blueprint.ExportBlueprint(bUplaod)
			self.m_bBusy = true
		end
    end)

    if Platform.IsWindows() or Platform.IsMac() then
		UIHelper.RegisterEditBoxEnded(self.EditBoxName, function(_editbox)
			local nLen = UIHelper.GetUtf8Len(UIHelper.GetText(self.EditBoxName))
			if nLen > 20 then
				nLen = 20
				UIHelper.SetText(self.EditBoxName, UIHelper.GetUtf8SubString(UIHelper.GetText(self.EditBoxName), 1, 20))
			end
			UIHelper.SetString(self.LabelLimit, string.format("%d/%d", nLen, 20))
        end)
    else
		UIHelper.RegisterEditBoxReturn(self.EditBoxName, function(_editbox)
			local nLen = UIHelper.GetUtf8Len(UIHelper.GetText(self.EditBoxName))
			if nLen > 20 then
				nLen = 20
				UIHelper.SetText(self.EditBoxName, UIHelper.GetUtf8SubString(UIHelper.GetText(self.EditBoxName), 1, 20))
			end
			UIHelper.SetString(self.LabelLimit, string.format("%d/%d", nLen, 20))
        end)
    end

	UIHelper.SetSwallowTouches(self.ScrollViewTag, false)
end

function UIHomelandBuildBlueprintUploadView:RegEvent()
	Event.Reg(self, EventType.OnSelectUploadBlueprintTagCell, function (szTag, bAdd)
		if bAdd then
			self:AddTag(szTag)
		else
			table.remove_value(self.tbTag, szTag)
			self:UpdateTagInfo()
		end

		for index, scriptList in ipairs(self.tbTagList) do
			scriptList:IsFullSelected(self.tbTag)
		end
	end)

    Event.Reg(self, "ON_WEB_DATA_SIGN_NOTIFY", function ()
		local uSign                     = arg0
		local dwType 					= arg1
		local nTime                     = arg2
		local nZoneID                   = arg3
		local dwCenterID                = arg4
		local bIsFirstWebPhoneVerified  = arg5
		local szOrderSN                 = arg6

		local player = GetClientPlayer()
		if not player then
			return
		end

		if not (dwType == WEB_DATA_SIGN_RQST.LOGIN and szOrderSN == szWebDataSign) then
			return
		end

		local szCipher = self:GenerateCipher(uSign, dwType, nTime, nZoneID, dwCenterID)
		Log("==== szCipher == " .. tostring(szCipher))
		self:UploadBlueprint(szCipher)
    end)

    Event.Reg(self, "CURL_REQUEST_RESULT", function ()
		local szKey = arg0
		local bSuccess = arg1
		local szValue = arg2
		local uBufSize = arg3

		if szKey == szKeyForUploadBlp then
			if bSuccess then
				local tInfo, szErrMsg = JsonDecode(szValue)
				local tData = tInfo.data
				if tData then
					local szName = UIHelper.GetText(self.EditBoxName)

					-- 上传蓝图文件
					GetHomelandMgr().UploadCloudFile(szUploadCloudKeyForBlp, 1, CLOUD_SERVICE_TYPE.QINIU, CLOUD_SERVICE_PREPROCESS_TYPE.COMPRESS,
							tData.fileUploadKey.uploadUrl, tData.fileUploadKey.key, tData.fileUploadKey.uploadKey,
							szName, self.m_szBlpPath,
							CLOUD_SERVICE_FILE_TYPE.STREAM)

					-- 上传截图文件
					GetHomelandMgr().UploadCloudFile(szUploadCloudKeyForPic, 1, CLOUD_SERVICE_TYPE.QINIU, CLOUD_SERVICE_PREPROCESS_TYPE.NONE,
							tData.picUploadKey.uploadUrl, tData.picUploadKey.key, tData.picUploadKey.uploadKey,
							szName,
							self.szFilePath,
							CLOUD_SERVICE_FILE_TYPE.IMAGE)
				else
					LOG.ERROR("无有效的data数据！ szErrMsg == " .. tostring(szErrMsg))
					LOG.TABLE(tInfo)

					TipsHelper.ShowNormalTip(g_tStrings.STR_HOMELAND_ASK_FOR_UPLOAD_BLP_URL_FAILED_2)

					self.m_bBusy = false
				end
			else
				TipsHelper.ShowNormalTip(g_tStrings.STR_HOMELAND_ASK_FOR_UPLOAD_BLP_URL_FAILED_1)
				self.m_bBusy = false
			end
		end
    end)

    Event.Reg(self, "ON_UPLOAD_CLOUD_FILE", function ()
		local szUIEvent = arg0
		local dwCustomValue = arg1
		local bSuccess = arg2 ~= 0
		local nRetCode = arg3
		local szBlpID = arg4
		LOG.INFO("=== 响应了事件 ON_UPLOAD_CLOUD_FILE，各个参数是：")
		LOG.TABLE({szUIEvent = szUIEvent, dwCustomValue = dwCustomValue, bSuccess = bSuccess, nRetCode = nRetCode, szBlpID = szBlpID})
		if bSuccess then
			if nRetCode == 0 then
				if szUIEvent == szUploadCloudKeyForBlp then
					self.m_bBlpUploadToCloudSuccess = true
					self.m_szBlpID = szBlpID
				elseif szUIEvent == szUploadCloudKeyForPic then
					self.m_bPicUploadToCloudSuccess = true
				end

				if self.m_bBlpUploadToCloudSuccess and self.m_bPicUploadToCloudSuccess then
					self:OnUploadBlpSuccess(self.m_szBlpID)
				end
			else
				LOG.ERROR("====上传蓝图到官网失败！ error code: " .. tostring(nRetCode))
				local szMsg = g_tStrings.STR_HOMELAND_UPLOAD_BLP_FAILED
				local szErr = g_tStrings.tStrHomelandUploadBlpFailure[nRetCode]
				if szErr then
					szMsg = szMsg .. g_tStrings.STR_PREV_PARENTHESES .. szErr .. g_tStrings.STR_END_PARENTHESES
				end
				TipsHelper.ShowNormalTip(szMsg)
				self.m_bBusy = false
			end
		else
			LOG.ERROR("==== 上传蓝图到官网失败！")
			TipsHelper.ShowNormalTip(g_tStrings.STR_HOMELAND_UPLOAD_BLP_FAILED)
			self.m_bBusy = false
		end
    end)

    Event.Reg(self, "LUA_HOMELAND_UPLOAD_BLUEPRINT_PATH", function ()
		local szPathOfGeneratedBlpForUpload = arg0
		self.m_szBlpPath = szPathOfGeneratedBlpForUpload
		GetClientPlayer().ApplyWebDataSign(WEB_DATA_SIGN_RQST.LOGIN, szWebDataSign)
    end)
end

function UIHomelandBuildBlueprintUploadView:UpdateInfo()
    self:UpdateTagInfo()
    self:UpdateScreenShotInfo()
end

function UIHomelandBuildBlueprintUploadView:InitTagList()
	if self.bInitTagList then
		return
	end
	self.tbTagList = {}

	local tInfo = FurnitureData.GetAllBlueprintTagInfos()
	for k, tbTagList in pairs(tInfo) do
		local tCatgInfo = FurnitureData.GetAllBlueprintTagCatgInfo(k)
		local szTypeName = UIHelper.GBKToUTF8(tCatgInfo.szName)
		local script = UIHelper.AddPrefab(PREFAB_ID.WidgetTagListSubtitle, self.ScrollViewTagList)
		script:OnEnter(szTypeName, tbTagList)
		table.insert(self.tbTagList, script)
	end

	UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewTagList)
	self.bInitTagList = true
end

function UIHomelandBuildBlueprintUploadView:UpdateScreenShotInfo()
	if not safe_check(self.pRetTexture) then
        return
    end

	UIHelper.SetTextureWithBlur(self.ImgCover, self.pRetTexture, false, 0, 0)
end

function UIHomelandBuildBlueprintUploadView:UpdateTagInfo()
	UIHelper.RemoveAllChildren(self.ScrollViewTagChoice)

	for nIndex, szTag in pairs(self.tbTag) do
		local script = UIHelper.AddPrefab(PREFAB_ID.WidgetTagCell, self.ScrollViewTagChoice)
		script:OnEnter(nIndex, {szName = szTag})
		script:TagDoLayout()
		UIHelper.SetCanSelect(script.TogCell, false, nil, false)
		UIHelper.SetEnable(script.TogCell, false)
	end

	UIHelper.SetVisible(self.LabelDefaultUp, #self.tbTag <= 0)
	UIHelper.SetVisible(self.LabelDefaultNormal, #self.tbTag <= 0)
	UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewTagChoice)
end

function UIHomelandBuildBlueprintUploadView:AddTag(szTag)
    if string.is_nil(szTag) then
        return
    end

    if #self.tbTag > MAX_TAG_NUM then
        return
    end

    local szTag, bThisCleared = self:GetAdjustedLabel(szTag)
    if bThisCleared then
		OutputMessage("MSG_ANNOUNCE_NORMAL", FormatString(g_tStrings.STR_HOMELAND_BLUEPRINT_TAG_INVALID, _TAG_DELIMITER))
		return
	end

    table.insert(self.tbTag, szTag)

    self:UpdateTagInfo()
end

function UIHomelandBuildBlueprintUploadView:UploadBlueprint(szCipher)
	local pHlMgr = GetHomelandMgr()
	if not pHlMgr then
		return
	end
	local szTags = ""

	local bIsAnyTagCleared = false
    for i, szTag in ipairs(self.tbTag) do
        if i > 1 then
            szTags = szTags .. _TAG_DELIMITER .. szTag
        else
            szTags = szTags .. szTag
        end
    end

	local bTestMode = IsDebugClient() or IsVersionExp()
	local szUrl = (bTestMode and szUrlForUploadBlp_Test) or szUrlForUploadBlp

	local scene = GetClientScene()
	local dwCurMapID, nCurCopyIndex = scene.dwMapID, scene.nCopyIndex

	local szMapName
	local nLandIndex
	local nMapLine
	local szHomeSkin = ""
	local nMode = HLBOp_Main.GetBuildMode()
	if nMode == BUILD_MODE.COMMUNITY or nMode == BUILD_MODE.PRIVATE then
		nLandIndex = pHlMgr.GetNowLandIndex()
		szMapName = Table_GetMapName(dwCurMapID)
		if pHlMgr.IsPrivateHomeMap(dwCurMapID) then
			local tCurLandInfo = pHlMgr.GetCurPrivateHomeInfo()
			local tInfo = Table_GetPrivateHomeSkin(dwCurMapID, tCurLandInfo.dwSkinID)
			if tInfo and tInfo.szSkinName then
				szHomeSkin = tInfo.szSkinName
			end
			nMapLine = 0
		else
			local tInfo = pHlMgr.GetCommunityInfo(dwCurMapID, nCurCopyIndex)
			nMapLine = tInfo.nIndex
		end
	else -- 设计场模式
		nLandIndex = 0

		for _, v in pairs(g_tStrings.tHomelandDesignScene) do
			if v[1] == HLBOp_Enter.GetSceneID() then
				local szSceneName = v[2]
				szMapName = g_tStrings.STR_HOMELAND_DESIGN_YARD_NAME_PREFIX .. szSceneName
				break
			end
		end
		nMapLine = 0
	end

	local nTotalNumberOnLand, nMaxRequiredLevel = self:GetTotalMdlNumAndMaxReqLevel()

	local tHttpData = {}
	tHttpData["cipher"] = szCipher
	tHttpData["globalRoleId"] = GetClientPlayer().GetGlobalID()
	tHttpData["title"] = UIHelper.GetText(self.EditBoxName)
	tHttpData["tags"] = UIHelper.GBKToUTF8(szTags)
	tHttpData["homeNum"] = nLandIndex
	tHttpData["homeArea"] = HLBOp_Enter.GetLandSize()
	tHttpData["homeLevel"] = nMaxRequiredLevel
	tHttpData["mapName"] = UIHelper.GBKToUTF8(szMapName)
	tHttpData["mapLine"] = nMapLine
	tHttpData["furnitureCount"] = nTotalNumberOnLand
	tHttpData["homeSkin"] = UIHelper.GBKToUTF8(szHomeSkin)

	local dwRecordInfo = pHlMgr.BuildGetRecordInfo()
	tHttpData["record"] = dwRecordInfo

	Log("==== tHttpData ==")
	LOG.TABLE(tHttpData)

	CURL_HttpPost(szKeyForUploadBlp, szUrl,
		JsonEncode(tHttpData), true, 60, 60, {[1] = "Content-Type:application/json"}) -- 最后一个参数也可能是 {"Content-Type: application/x-www-form-urlencoded"}
end

function UIHomelandBuildBlueprintUploadView:GenerateCipher(uSign, dwType, nTime, nZoneID, dwCenterID)
	if dwType ~= WEB_DATA_SIGN_RQST.LOGIN then
		return
	end

	local pPlayer = GetClientPlayer()
	if not pPlayer then
		return
	end

	local szAccount = Login_GetAccount()
	local szName = UIHelper.GBKToUTF8(pPlayer.szName)
	local dwID = pPlayer.dwID
	local dwForceID = pPlayer.dwForceID

	local szUserRegion, szUserSever = self:GetServerName()

	local szCipherParam = "%d/%s/%d/%d/%d/%d/%s/%s/%d/%s/%d/%s"

	szCipherParam = string.format(
			szCipherParam, uSign, szAccount, dwID, nTime, nZoneID,
			dwCenterID, szUserRegion, szUserSever, dwForceID, szName, nTime, GetAccountType()
	)

	return szCipherParam
end

function UIHomelandBuildBlueprintUploadView:GetTrimmedString(szStr)
	return (string.gsub(szStr, "^%s*(.-)%s*$", "%1"))
end

function UIHomelandBuildBlueprintUploadView:RemoveInvalidChars(szStr)
	return (string.gsub(szStr, "[%\\/:*?\"<>|]", ""))
end

function UIHomelandBuildBlueprintUploadView:GetAdjustedLabel(szLabel)
	local bCleared = false

	local szTrimmedLabel = self:GetTrimmedString(szLabel)
	if string.find(szTrimmedLabel, _TAG_DELIMITER, 0, true) then
		szTrimmedLabel = ""
		bCleared = true
	else
		-- Do nothing
	end

	return szTrimmedLabel, bCleared
end

function UIHomelandBuildBlueprintUploadView:GetTotalMdlNumAndMaxReqLevel()
	local nTotalCount = 0
	local nRequiredLevel = 1
	local hlMgr = GetHomelandMgr()
	local tAllCatgInfos = FurnitureData.GetAllCatgInfos()
	local nCatg1, nCatg2
	for nCatg1Index, tCatg1 in ipairs(tAllCatgInfos) do
		for nCatg2Index, tCatg2 in ipairs(tCatg1) do
			if nCatg2Index ~= 0 then
				local nCount = hlMgr.BuildGetCategoryCount(nCatg1Index, nCatg2Index)
				nTotalCount = nTotalCount + nCount
			end
		end
	end
	local _, tFurnInfo, _ = FurnitureData.GetAllFurniturnInfos()
	for dwModelID, tInfo in pairs(tFurnInfo) do
		if tInfo.nFurnitureType == HS_FURNITURE_TYPE.FURNITURE or tInfo.nFurnitureType == HS_FURNITURE_TYPE.PENDANT then
			local nCount = hlMgr.BuildGetOnLandFurniture(tInfo.nFurnitureType, tInfo.dwFurnitureID)
			if nCount > 0 then
				local nLevelLimit = 1
				local tConfig
				if tInfo.nFurnitureType == HS_FURNITURE_TYPE.FURNITURE then
					tConfig = hlMgr.GetFurnitureConfig(tInfo.dwFurnitureID)
					nLevelLimit = tConfig.nLevelLimit or 1
				elseif tInfo.nFurnitureType == HS_FURNITURE_TYPE.PENDANT then
					tConfig = hlMgr.GetPendantConfig(tInfo.dwFurnitureID)
					nLevelLimit = tConfig.nLevelLimit or 1
				end
				nRequiredLevel = math.max(nLevelLimit, nRequiredLevel)
			end
		end
	end
	return nTotalCount, nRequiredLevel
end

function UIHomelandBuildBlueprintUploadView:OnUploadBlpSuccess(szBlpID)
	local szMsg = g_tStrings.STR_HOMELAND_UPLOAD_BLP_SUCCESS
	-- local fnCopy = function() -- 调用时界面已关闭，所以需要从外部传入
	-- 	SetDataToClip(szBlpID)
	-- end
	-- local tMsg =
	-- {
	-- 	bModal = true,
	-- 	szName = "homeland_OfficialBlpUploadSuccess",
	-- 	bVisibleWhenHideUI = true,
	-- 	szMessage = szMsg,
	-- 	{szOption = g_tStrings.STR_HOTKEY_SURE},
	-- 	{szOption = g_tStrings.STR_HOMELAND_COPY_BLUEPRINT_ID, fnAction = fnCopy},
	-- }
	-- MessageBox(tMsg)
	TipsHelper.ShowNormalTip(szMsg)
	UIMgr.Close(self)
end

function UIHomelandBuildBlueprintUploadView:GetServerName()
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

return UIHomelandBuildBlueprintUploadView
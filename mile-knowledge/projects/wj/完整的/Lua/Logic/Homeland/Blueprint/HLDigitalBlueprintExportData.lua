
HLDigitalBlueprintExportData = HLDigitalBlueprintExportData or {}

local self = HLDigitalBlueprintExportData
--------------------- Data Definitions -------------------------------
local INI_FILE = "ui/Config/Default/Homeland/BuildingView/HLBView_DigitalBlueprintExport.ini"
local TREE_PATH = "Normal1/HLBView_DigitalBlueprintExport"
local FRAME_NAME = "HLBView_DigitalBlueprintExport"

local szKeyForUploadBlp = "HomelandUploadDigitalBlp"
local szUrlForUploadBlp_Test = "http://120.92.151.103/gamegw/home-blueprint/replica-upload-keys"
local szUrlForUploadBlp = "https://gdca-blueprint-api.xoyo.com/gamegw/home-blueprint/replica-upload-keys"

local szWebDataSign = "REQUEST_FOR_UPLOAD_DIGITAL_BLUEPRINT"

local function GetAPIURL()
	if IsDebugClient() or IsVersionExp() then
		return szUrlForUploadBlp_Test
	else
		return szUrlForUploadBlp
	end
end

--------------------- Frame Event Callbacks --------------------------
function HLDigitalBlueprintExportData.Init()
	self.InitData()
	self.RegEvent()

	if self.m_bBusy then
		TipsHelper.ShowNormalTip(g_tStrings.STR_HOMELAND_BUSY_UPLOADING_BLP)
	else
		HLBOp_Blueprint.SaveDigitalBlueprint()
		self.m_bBusy = true
	end
end

function HLDigitalBlueprintExportData.UnInit()
	Event.UnRegAll(self)
	self.UnInitData()
end

function HLDigitalBlueprintExportData.RegEvent()
	Event.Reg(self, "ON_WEB_DATA_SIGN_NOTIFY", function ()
		self.OnWebDataSignNotify(this)
	end)

	Event.Reg(self, "CURL_REQUEST_RESULT", function ()
		local szKey = arg0
		local bSuccess = arg1
		local szValue = arg2
		local uBufSize = arg3
		if szKey == szKeyForUploadBlp then
			if bSuccess then
				local tInfo, szErrMsg = JsonDecode(szValue)
				Homeland_Log("tInfo, szErrMsg", tInfo, szErrMsg)
				if type(tInfo) == "table" and tInfo.code and tInfo.code == 0 then
					local tData = tInfo.data
					-- 上传蓝图文件
					local bResult = GetHomelandMgr().UploadDigitalBlp(HLBOp_Enter.GetCode(), tData.fileUploadKey.key, tData.fileUploadKey.uploadKey, "DigitalBlueprint", tData.fileUploadKey.uploadUrl)
					Homeland_Log("UploadDigitalBlp", HLBOp_Enter.GetCode(), tData.fileUploadKey.key, tData.fileUploadKey.uploadKey, "DigitalBlueprint", tData.fileUploadKey.uploadUrl, bResult)
				else
					LOG.ERROR("【ERROR】 无有效的data数据！ szErrMsg == " .. tostring(szErrMsg))
					Homeland_Log(tInfo)
					self.m_bBusy = false
					TipsHelper.ShowNormalTip(g_tStrings.STR_HOMELAND_UPLOAD_BLP_FAILED)
				end
			else
				TipsHelper.ShowNormalTip(g_tStrings.STR_HOMELAND_ASK_FOR_UPLOAD_BLP_URL_FAILED_1)
				self.m_bBusy = false
			end
		end
	end)

	Event.Reg(self, "ON_UPLOAD_DIGITAL_BLP", function ()
		local bSuccess = (arg0 == 1)
		local nResultCode = arg1
		local szCode = arg2
		Homeland_Log("ON_UPLOAD_DIGITAL_BLP", bSuccess, nResultCode, szCode)
		self.m_bBusy = false
		if not bSuccess then
			TipsHelper.ShowNormalTip(g_tStrings.STR_HOMELAND_UPLOAD_BLP_FAILED)
		else
			TipsHelper.ShowNormalTip(g_tStrings.STR_HOMELAND_UPLOAD_BLP_SUCCESS)
		end
	end)

	Event.Reg(self, "LUA_HOMELAND_UPLOAD_BLUEPRINT_PATH", function ()
		local szPathOfGeneratedBlpForUpload = arg0
		self.SetBlpPath(szPathOfGeneratedBlpForUpload)
		GetClientPlayer().ApplyWebDataSign(WEB_DATA_SIGN_RQST.LOGIN, szWebDataSign)
	end)
end

--------------------- Event Helper Functions -------------------------
function HLDigitalBlueprintExportData.OnWebDataSignNotify(hFrame)
	local uSign                     = arg0
	local dwType = arg1
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

	local szCipher = Homeland_GenerateCipher(uSign, dwType, nTime, nZoneID, dwCenterID)
	LOG.INFO("==== szCipher == " .. tostring(szCipher))
	self.UploadDigitalBlueprint(szCipher)
end

--------------------- Data-related Functions -------------------------
function HLDigitalBlueprintExportData.InitData()
	self.m_szBlpPath = nil
	self.m_bBusy = false
end

function HLDigitalBlueprintExportData.UnInitData()
	self.m_szBlpPath = nil
	self.m_bBusy = false
end
--------------------- Logic-related Functions ------------------------

function HLDigitalBlueprintExportData.UploadDigitalBlueprint(szCipher)
	local tHttpData = {}
	tHttpData["cipher"] = szCipher
	tHttpData["globalRoleId"] = GetClientPlayer().GetGlobalID()
	tHttpData["digitalCode"] = HLBOp_Enter.GetCode()

	local szUrl = GetAPIURL()
	LOG.INFO("==== tHttpData ==")
	Homeland_Log(tHttpData)

	CURL_HttpPost(szKeyForUploadBlp, szUrl,
		JsonEncode(tHttpData), true, 60, 60, { [1] = "Content-Type:application/json"})
end

--------------------- Global Event Handlers --------------------------
function HLDigitalBlueprintExportData.SetBlpPath(szBlpPath)
	self.m_szBlpPath = szBlpPath
end

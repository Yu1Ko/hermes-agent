-- ---------------------------------------------------------------------------------
-- Author: zeng zi peng
-- Name: ServiceCenterData
-- Date: 2023-06-19 16:50:05
-- Desc: 客服中心数据管理
-- ---------------------------------------------------------------------------------

ServiceCenterData = ServiceCenterData or {className = "ServiceCenterData"}
local self = ServiceCenterData
-------------------------------- 消息定义 --------------------------------
ServiceCenterData.Event = {}
ServiceCenterData.Event.XXX = "ServiceCenterData.Msg.XXX"
ServiceCenterData.GameMasterReportUrl="http://infoc.xoyo.com/BugReport/Jx3/receive_info_exp.do"
-- 安全分数
local nSafeScore = 0
local tScores =
{
	["email"] 		= 5,
	["phone"] 		= 20,
	["safelock"] 	= 15,
	["martixlock"] 	= 15,
	["phonelock"] 	= 50,
	["tokenlock"] 	= 50,
}
-- 标签模式类型
ServiceCenterData.TabModleType =
{
	AccountSafe = 1,
	EquipmentFound = 2,
	FeeBug = 3,
	Proposal = 4,
	InformScript = 5,
	Other = 6,
	ReportVoiceRoom = 7,
}
ServiceCenterData.SafeReminder = {
	nCount = 0,
	nSecurityState = 0,
}
ServiceCenterData.tbRedPointIDs = 
{
	4301
}

local SERVICE_HREF_FLAG = "GoServiceHelp"

function ServiceCenterData.Init()
	Event.Reg(self, "FIRST_LOADING_END", function()
        self:ResetGetPlayerSafeScore()
    end)

	Event.Reg(self, "SYNC_PASSWORD_SUCCESS_TO_GM", function()
        self:ResetGetPlayerSafeScore()
    end)

	Event.Reg(self, "ON_ACCOUNT_SECURITY_USER_UNLOCK_FAILED", function(nResultCode)
		ServiceCenterData.SafeReminder.nCount = ServiceCenterData.SafeReminder.nCount + 1
		if nResultCode == 0 then
			TipsHelper.ShowNormalTip(g_tStrings.SAFE_REMINDER_CONFIRM_FAILED)
		elseif nResultCode == 2 then
			TipsHelper.ShowNormalTip(g_tStrings.SAFE_REMINDER_ID_CONFIREM_LIMITED)
		end
	end)

	Event.Reg(self, "ON_ACCOUNT_SECURITY_STATE_CHANGE", function()
		ServiceCenterData.SafeReminder.nSecurityState = arg0
		if not UIMgr.GetView(VIEW_ID.PanelAccountWarning) then
			UIMgr.Open(VIEW_ID.PanelAccountWarning)
		else
			local script = UIMgr.GetViewScript(VIEW_ID.PanelAccountWarning)
			script:UpdateInfo()
		end
		if ServiceCenterData.SafeReminder.nSecurityState == ACCOUNT_SECURITY_STATE.SAFE then
			TipsHelper.ShowNormalTip("解锁成功，账号异常解除，可正常使用！")
			UIMgr.Close(VIEW_ID.PanelUnlockAccount)
		end
	end)

	Event.Reg(self, "ON_LAST_LOGIN_ACCOUNT_SECURITY_NOTIFY", function()
		local nLoginTime = arg0
		local szCity = UIHelper.GBKToUTF8(arg1)
		if UIMgr.GetView(VIEW_ID.PanelAccountWarning) then
			UIMgr.Close(VIEW_ID.PanelAccountWarning)
		end
		UIMgr.Open(VIEW_ID.PanelAccountWarning, true,nLoginTime,szCity)
	end)

	Event.Reg(self, "ON_ASAPPLY_SENDVERITY_RESPOND", function()
		TipsHelper.ShowNormalTip(g_tStrings.tAccountSendSms[arg0])
	end)
end

function ServiceCenterData.UnInit()
    Event.UnRegAll(self)
end

function ServiceCenterData.OnLogin()

end

function ServiceCenterData.OnFirstLoadEnd()

end

function ServiceCenterData:GetSafeScore()
	return nSafeScore
end

function ServiceCenterData:SetSafeScore(nScore)
	nSafeScore = nScore
end

function ServiceCenterData:ResetGetPlayerSafeScore()
    local bBindEmail = self:IsEMailBind()
	nSafeScore = 0
	if bBindEmail then
		nSafeScore = nSafeScore + tScores["email"]
	end

	local bBindPhone = self:IsPhoneBind()
	if bBindPhone then
		nSafeScore = nSafeScore + tScores["phone"]
	end

	local bBindSafeLock = self:IsSafeLockBind()
	if bBindSafeLock then
		nSafeScore = nSafeScore + tScores["safelock"]
	end

	local bMibaoType = self:GetMibaoMode()
	if bMibaoType == PASSPOD_MODE.MATRIX then
		nSafeScore = nSafeScore + tScores["martixlock"]
	elseif bMibaoType == PASSPOD_MODE.PHONE then
		nSafeScore = nSafeScore + tScores["phonelock"]
	elseif bMibaoType == PASSPOD_MODE.TOKEN then
		nSafeScore = nSafeScore + tScores["tokenlock"]
	end
	Event.Dispatch("SYNC_SAFE_SCORE", nSafeScore)
end

function ServiceCenterData:IsEMailBind()
	local hPlayer = GetClientPlayer()
	local bBindEmail = hPlayer.GetAccountSafeBindFlag(ACCOUNT_SAFE_BIND_TYPE.BIND_EMAIL)
	if bBindEmail then
		return true
	else
		return false
	end
end

function ServiceCenterData:IsPhoneBind()
	local hPlayer = GetClientPlayer()
	local bBindPhone = hPlayer.GetAccountSafeBindFlag(ACCOUNT_SAFE_BIND_TYPE.BIND_PHONE)
	if bBindPhone then
		return true
	else
		return false
	end
end

function ServiceCenterData:IsSafeLockBind()
	local hPlayer = GetClientPlayer()
	local bBindSafeLock = hPlayer.GetSafeLockBindFlag()
	if bBindSafeLock then
		return true
	else
		return false
	end
end

function ServiceCenterData:GetMibaoMode()
	local hPlayer = GetClientPlayer()
	return hPlayer.nMibaoMode
end

function ServiceCenterData.FillBasicInfo(szType, t)
	local _, szVersion = GetVersion()
	local player = GetClientPlayer()
	local tbServer = LoginMgr.GetModule(LoginModule.LOGIN_SERVERLIST).GetSelectServer()
	t["Type"]      = szType
	t["Version"]   = szVersion
	t["Account"]   = Login_GetAccount()
	t["Region"]    = UIHelper.UTF8ToGBK(tbServer.szRegion)
	t["Server"]    = UIHelper.UTF8ToGBK(tbServer.szRealServer)
	t["ServerList"]= tostring(tbServer.szIP)..":"..tostring(tbServer.nPort)
	t["RoleName"]  = player.szName
	t["Level"]     = player.nLevel
	t["MapName"]   = Table_GetMapName(player.GetMapID())
	t["x"]         = player.nX
	t["y"]         = player.nY
	t["z"]         = player.nZ
	t["ForceName"] = UIHelper.UTF8ToGBK(Table_GetForceName(player.dwForceID))
	t["CampName"]  = UIHelper.UTF8ToGBK(g_tStrings.STR_CAMP_TITLE[player.nCamp])
end

function ServiceCenterData.SendDataToGMWEB(szPrefix, tAllParam , bIsAndroid , bIsIos)
	local nParamNumber = 0
	local szMsg = ""
	local szParam = ""
	for _, tParam in ipairs(tAllParam) do
		if tParam.szName ~= "Server" and tParam.szName ~= "RoleName" then
			szParam = szParam .. tParam.szName .. ":" .. tParam.szValue .. ";"
			nParamNumber = nParamNumber + 1
		end
	end
	szMsg = "[" .. szPrefix .. "]" .. "ParamNum:" .. nParamNumber .. ";" .. szParam
	-- 增加一条平台显示
	szMsg = UIHelper.UTF8ToGBK(szMsg)
	SendGmMessage(szMsg)
end

function ServiceCenterData.GetGameMasterReportUrl(bIsAndroid , bIsIos)
	local url = "http://infoc.xoyo.com/BugReport/Jx3/receive_info_exp_win.do"
	if Platform.IsAndroid() or bIsAndroid then
		url = "http://infoc.xoyo.com/BugReport/Jx3/receive_info_exp_android.do"
	elseif Platform.IsIos() or bIsIos then
		url = "http://infoc.xoyo.com/BugReport/Jx3/receive_info_exp_ios.do"
	end
	return url
end

---------------------------------------装备找回-------------------------------------
ServiceCenterData.nLastSearchTime = nil


---------------------------------------在线客服-------------------------------------
---comment 打开在线客服网页
function ServiceCenterData.OpenServiceWeb()
    -- local szUrl = ""
    -- if Platform.IsWindows() or Platform.IsMac() then
    --     szUrl = tUrl.ServiceCenter_VK_PC
    -- else
    --     szUrl = tUrl.ServiceCenter_VK_Mobile
    -- end

    -- if not string.is_nil(szUrl) then
    --     UIHelper.OpenWeb(szUrl)
    -- end

	if Platform.IsWindows() or Platform.IsMac() then
		WebUrl.OpenByID(WEBURL_ID.WEB_CHATBOT_VK)
	else
		WebUrl.OpenByID(WEBURL_ID.WEB_CHATBOT_VK_MOBILE)
	end
end

---comment 获取带有xml超链接的“在线客服”文本
---@param szText string|nil 可传入带有“在线客服”的文本，将返回处理后的文本
---@return string szService
function ServiceCenterData.GetServiceXmlText(szText)
    if szText and not string.find(szText, "在线客服") then
        return szText   -- 不包含在线客服，直接返回
    end

    szText = szText or ""
    local szService = string.format("<href=%s><color=#95FF95><u>在线客服</u></color></a>", SERVICE_HREF_FLAG)

    if not string.is_nil(szText) then
        szText = string.gsub(szText, "在线客服", szService)
        szService = szText
    end
    return szService
end
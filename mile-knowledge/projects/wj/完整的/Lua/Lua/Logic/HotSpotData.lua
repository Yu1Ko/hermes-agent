-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: HotSpotData
-- Date: 2023-06-15 11:04:24
-- Desc: ?
-- ---------------------------------------------------------------------------------

HotSpotData = HotSpotData or {className = "HotSpotData"}
local self = HotSpotData
-------------------------------- 消息定义 --------------------------------
HotSpotData.Event = {}
HotSpotData.Event.XXX = "HotSpotData.Msg.XXX"
local WebCareerCfg = "https://jx3comm.xoyocdn.com/jx3gc/zhcn/login_ad/WebCareerCfg.ini"
local WebCareerCfg_Exp = "http://jx3comm.xoyocdn.com/jx3gc/zhcnhd_exp/login_ad/WebCareerCfg.ini"--体服路径
local m_bShowRandom           = false
local bPopVersionUp           = false
local szWebCareerEventFile    = nil
local szWebCareerTabFile      = nil
local szWebCareerTabMBFile	  = nil
local nMode                   = nil
local m_szSetPopID            = nil
-- local m_DeimuraQuests         = {12198, 12151, 12160, 12161, 12162, 12163, 12164, 12165, 12166, 12167, 12338, 14417, 15977, 18948, 20517,
-- 21922, 23718, 23718, 25058, 26288, 30056}
local nShowHotSpotLevel = 106


local tWebCareerEventTitle =
{
	{f = "i", t = "nID"},
	{f = "s", t = "szName"},
	{f = "s", t = "szTitle"},
	{f = "s", t = "szIntroduction"},
	{f = "s", t = "szTab"},
	{f = "s", t = "szVKTab"},
	{f = "i", t = "nMode"},
	{f = "s", t = "szServer"},
	{f = "s", t = "szClient"},
}

local tWebCareerTabTitle =
{
	{f = "i", t = "nTabID"},
	{f = "s", t = "szName"},
	{f = "s", t = "szTitle"},
	{f = "s", t = "szImageURL"},
	{f = "s", t = "szInPakPath"},
	{f = "i", t = "szInPakFrame"},
	{f = "s", t = "szUrl"},
	{f = "s", t = "szLink"},
}

local tWebCareerTabMBTitle =
{
	{f = "i", t = "nTabID"},
	{f = "s", t = "szLink"},
	{f = "b", t = "bSHow"},
}

local function GetDownloadEXPPath()
	local path = GetJX3TempPath() .. "ExpHotSpot\\"
	if not Lib.IsFileExist(path) then
		CPath.MakeDir(path)
	end
	return path
end

local function GetDownloadPath(szName)
	if bExp == nil then
		bExp = IsVersionExp()
	end

	-- 因为移动端不支持 文件名为非ktx后缀的图片文件（但是格式支持），因此这里改一下名字
	if not Platform.IsWindows() then
		local nLen = string.len(szName)
		local szExt = szName:sub(-4, -1)
		if szExt == ".png" then
			szName = szName:sub(1, -5) .. ".mpng"
		end
	end

	if bExp then
		return GetDownloadEXPPath() .. szName, "temp/"..szName
	else
		return UIHelper.UTF8ToGBK(GetJX3TempPath())..szName, "temp/"..szName
	end
end

local function GetImageSuffix(szImageURL)
	szImageURL = string.gsub(szImageURL, "%.", ",")
	local tTable = string.split(szImageURL, ",")
	local nCount = #tTable
	if nCount >= 1 then
		return tTable[nCount]
	end
end

local function GetImageName(tLine)
	local szSuffix = GetImageSuffix(tLine.szImageURL) or "jpg"
	return "WebCareerJpg" .. tLine.nTabID .. "." .. szSuffix
end

local function IsAssignClient(szClient)
	local bIsWegame 		= WG_IsEnable()

	if szClient == "" then
		return true
	elseif szClient == "Wegame" and bIsWegame then
		return true
	elseif szClient == "NotWegame" and not bIsWegame then
		return true
	end
	return false
end


function HotSpotData.Init()
	self.nCount = 0
	self.nImgCount = 0

    self._registerEvent()

	-- 游戏最开始就预先去下载配置文件
	self.DownloadWebCareerCfg()
end

function HotSpotData.UnInit()

end

function HotSpotData.OnLogin()

end

function HotSpotData.OnFirstLoadEnd()

end

function HotSpotData.DownloadWebCareerCfg()
	local szUrl = Version.IsEXP() and WebCareerCfg_Exp or WebCareerCfg
    local szPath = GetDownloadPath("WebCareerCfg.ini")
    CURL_DownloadFile("WebCareerCfg.ini", szUrl, szPath, true, 120)
end

function HotSpotData.DownloadCareerEvent(szEventUrl, szTabUrl, szTabMBUrl)
	if not szEventUrl or szEventUrl == "" then
		return
	end

	if not szTabUrl or szTabUrl == "" then
		return
	end

	if not szTabMBUrl or szTabMBUrl == "" then
		return
	end
	self.tWebCareerEvent = nil
	self.tWebCareerTab = nil

	CURL_DownloadFile("WebCareerEvent.txt", szEventUrl,	GetDownloadPath("WebCareerEvent.txt"), true, 120)
	CURL_DownloadFile("WebCareerTab.txt", 	szTabUrl, GetDownloadPath("WebCareerTab.txt"), 	true, 120)
	CURL_DownloadFile("WebCareerTabMB.txt", szTabMBUrl, GetDownloadPath("WebCareerTabMB.txt"), true, 120)
	--DelayCall(500, function() LoadWebCareerInfo(GetDownloadPath("WebCareerEvent.txt"), GetDownloadPath("WebCareerTab.txt")) end)
end

function HotSpotData.LoadWebCareerInfo(szWebCareerEventFile, szWebCareerTabFile, szWebCareerTabMBFile)
	if not self.bWebRegister then
        RegisterUITable("WebCareerEvent", szWebCareerEventFile, tWebCareerEventTitle)
    	RegisterUITable("WebCareerTab", szWebCareerTabFile, tWebCareerTabTitle)
		RegisterUITable("WebCareerTabMB", szWebCareerTabMBFile, tWebCareerTabMBTitle)
        self.bWebRegister = true
    end
    self.tWebCareerEvent = {}
    local nCount = g_tTable.WebCareerEvent:GetRowCount()
    for i = 2, nCount do --row 1 for default
    	local tLine = g_tTable.WebCareerEvent:GetRow(i)
		tLine.tTab = ParseCareerEventTab(tLine.szVKTab)
    	self.tWebCareerEvent[tLine.nID] = tLine
    end

 	self.tWebCareerTab = {}
 	if not g_tTable.WebCareerTab then
 		return
 	end
	self.nGetIamgeCount = 0
    nCount = g_tTable.WebCareerTab:GetRowCount()
	local fVersion = self.tWebCareerData and self.tWebCareerData.fVersion or 0
    for i = 2, nCount do --row 1 for default
		local tLine = clone(g_tTable.WebCareerTab:GetRow(i))
		if tLine.nTabID > 0 then
			tLine.tContent = {}
			local szImageURL = tLine["szImageURL"]
			if szImageURL ~= "" then
				local szRequest = GetImageName(tLine)
				local szLocalFile, szLocalFileShort = GetDownloadPath(szRequest)
				local bLocalExist = Lib.IsFileExist(Platform.IsMac() and szLocalFileShort or szLocalFile)
				Storage.HotSpotGlobal.fWebVersion = Storage.HotSpotGlobal.fWebVersion or 1
				local bVersionUp = math.abs(Storage.HotSpotGlobal.fWebVersion - fVersion) > 0.00001

				if not bLocalExist or bVersionUp then
					CURL_DownloadFile(szRequest, szImageURL, szLocalFile, true, 120)
				else
					tLine.szImage = Platform.IsMac() and szLocalFileShort or szLocalFile
				end
			end
			local tLineMB = g_tTable.WebCareerTabMB:Search(tLine.nTabID)
			tLine.bShow = tLineMB and tLineMB.bSHow or false
			tLine.szLink = tLineMB and tLineMB.szLink or ""
			self.tWebCareerTab[tLine.nTabID] = tLine
		end
    end
    Storage.HotSpotGlobal.fWebVersion = fVersion
	Storage.HotSpotGlobal.Flush()
    FireUIEvent("LOAD_WEB_CAREER_INFO")
end


function HotSpotData.OnConfigRequest(szFilePath)
    local hWebCareerCfg = Ini.Open(szFilePath)
	local fVersion = hWebCareerCfg:ReadFloat("Total", "Version", 0)

    if not self.tWebCareerData then
        self.tWebCareerData = {}
    end
	self.tWebCareerData.fVersion = fVersion
	self.tWebCareerData.szEventUrl = hWebCareerCfg:ReadString("Total", "WebCareerEventUrl", "")
	self.tWebCareerData.szTabUrl = hWebCareerCfg:ReadString("Total", "WebCareerTabUrl", "")
	self.tWebCareerData.szTabMBUrl = hWebCareerCfg:ReadString("Total", "WebCareerTabMBUrl", "")
	self.DownloadCareerEvent(self.tWebCareerData.szEventUrl, self.tWebCareerData.szTabUrl, self.tWebCareerData.szTabMBUrl)
	local fPopVersion = hWebCareerCfg:ReadFloat("Total", "PopVersion", 0)
	local szPopID = hWebCareerCfg:ReadString("Total", "PopID", "")
	local fPopLevel = hWebCareerCfg:ReadFloat("Total", "PopLevel", 0)
	local bNotShow = hWebCareerCfg:ReadInteger("Total", "bNotShow", 0) ~= 0
	local bAlwaysShow = hWebCareerCfg:ReadInteger("Total", "bAlwaysShow", 0) ~= 0
	local bRandom = hWebCareerCfg:ReadInteger("Total", "bRandom", 0) ~= 0
	local nCurLevel = 1--g_pClientPlayer.nLevel
	hWebCareerCfg:Close()
	if nCurLevel < fPopLevel then
		self.tWebCareerData.fPopLevel = fPopLevel
	end
	self.tWebCareerData.fPopVersion = fPopVersion
	self.tWebCareerData.szPopID = m_szSetPopID or szPopID
	self.tWebCareerData.bNotShow = bNotShow
	m_bShowRandom = bRandom
	bPopVersionUp = (not bNotShow and math.abs(fPopVersion - Storage.HotSpotRole.fPopVersion) > 0.00001) or bAlwaysShow
end


function HotSpotData.GetCenterIndex()
	if m_bShowRandom then
		return math.random(1, self.nImgCount)
	else
		return 1
	end
end

function HotSpotData.GetEvent(nID)
	local tEvent = {}
	if self.tWebCareerEvent then
		tEvent = self.tWebCareerEvent[nID]
	end
	return tEvent
end

function HotSpotData.GetCareerData()
	return self.tWebCareerData
end

function HotSpotData.GetTab(nTabID)
	local tCareerTab = {}
	if self.tWebCareerTab then
		tCareerTab = self.tWebCareerTab[nTabID]
	end
	return tCareerTab
end

function HotSpotData.GetTabCount(tTab)
    local nImgCount = 0
    local nCount = 0
    if tTab then
        for k, v in pairs(tTab) do
            local tTabID = self.GetTab(v)
            if (tTabID.szImage or tTabID.szInPakPath ~= "") and tTabID.bShow then
                nImgCount 	= nImgCount + 1
            end
            nCount = nCount + 1
        end
    end
    return nCount, nImgCount
end

function HotSpotData.GetImageCountByPopID(nPopID)
	local tEvent = self.GetEvent(nPopID)
    if not tEvent then
        return
    end
	local nCount, nImageCount = self.GetTabCount(tEvent.tTab)
	return nImageCount
end

function HotSpotData.GetDefaultPopID()
	return self.tWebCareerData and self.tWebCareerData.fPopID or 0
end



function HotSpotData.OnUrlData()
    if not arg1 then
		return
	end

	local path, szShortPath = GetDownloadPath(arg0)
	if arg0 == "WebCareerCfg.ini" then
		local szConfigPath = Platform.IsMac() and szShortPath or path
		self.OnConfigRequest(szConfigPath)
	elseif arg0 == "WebCareerEvent.txt" or arg0 == "WebCareerTab.txt" or arg0 == "WebCareerTabMB.txt" then
		if arg0 == "WebCareerEvent.txt" then
			szWebCareerEventFile = Platform.IsWindows() and path or szShortPath
		elseif arg0 == "WebCareerTab.txt" then
			szWebCareerTabFile = Platform.IsWindows() and path or szShortPath
		elseif arg0 == "WebCareerTabMB.txt" then
			szWebCareerTabMBFile = Platform.IsWindows() and path or szShortPath
		end
		if szWebCareerEventFile and szWebCareerTabFile and szWebCareerTabMBFile then
			self.LoadWebCareerInfo(szWebCareerEventFile, szWebCareerTabFile, szWebCareerTabMBFile)
		end
	else
		local szTab, szSuffixName = string.match(arg0, "WebCareerJpg([%d]+)\.([%a]+)")
		if szTab and szSuffixName and self.tWebCareerTab then
			local nTabID = tonumber(szTab)
			local tTab = self.tWebCareerTab[nTabID]
			if GetImageSuffix(tTab.szImageURL) == szSuffixName then
				tTab.szImage = Platform.IsMac() and szShortPath or path
			end
		end

		if not self.nGetIamgeCount then self.nGetIamgeCount = 0 end
		self.nGetIamgeCount = self.nGetIamgeCount + 1
		local nTotalCount = self.tWebCareerTab and table.get_len(self.tWebCareerTab) or 0
		if nTotalCount == self.nGetIamgeCount then
			self.UpdateImageCount()
			Event.Dispatch(EventType.RefreshHotSpotData)
			self.nGetIamgeCount = 0
		end
	end
end

function HotSpotData.UpdateImageCount()
	local fPopID = self.tWebCareerData and self.tWebCareerData.fPopID
	if fPopID then
		local tEvent = self.GetEvent(fPopID)
		if tEvent then
			local nCount, nImgCount = self.GetTabCount(tEvent.tTab)
			self.nCount = nCount
			self.nImgCount = nImgCount
		end
	end
end

function HotSpotData.SetPopID(szPopID)
	m_szSetPopID = tostring(szPopID)
end

function HotSpotData.CheckCanOpen()
	if AppReviewMgr.IsReview() then
		return false
	end

	-- 手游这边就还是不让它每次都弹，限制一天内弹一次
	if APIHelper.IsDidToday("HotSpotDataPop") then
		return false
	end

	if UIMgr.GetView(VIEW_ID.PanelHotSpotBanner) then
		return
	end

	if not g_pClientPlayer or g_pClientPlayer.nLevel < (nShowHotSpotLevel or 0) then
		return false
	end

	if (self.nImgCount and self.nImgCount < 1) or (self.nCount and self.nCount < 1) then
        return false
    end

	local bOpen = true
	for nIndex, nViewID in ipairs(HOTSPOT_VIEW_LIST) do
		if UIMgr.IsViewVisible(nViewID) then
			bOpen = false
			break
		end
	end

	return bOpen
end

function HotSpotData.RefreshImage()
	if not HotSpotData.CanRefresh() then
		return
	end

	self.nGetIamgeCount = 0
	for nIndex, tbTab in pairs(self.tWebCareerTab or {}) do
		local szImageURL = tbTab["szImageURL"]
		if szImageURL ~= "" then
			local szRequest = GetImageName(tbTab)
			local szLocalFile = GetDownloadPath(szRequest)
			CURL_DownloadFile(szRequest, szImageURL, szLocalFile, true, 120)
		end
	end

	self.nLastRefreshTime = GetCurrentTime()
end

-- 做个时间限制（5分钟），一方面怕请求时间太长，一方面怕一直刷会拉曝服务器
function HotSpotData.CanRefresh()
	local nNow = GetCurrentTime()
	if nNow - (self.nLastRefreshTime or 0) < 300 then
		return false
	end

	return true
end

function HotSpotData.AutoOpenHotSpotBanner()
	if self.CheckCanOpen() then
		APIHelper.DoToday("HotSpotDataPop")
		UIMgr.Open(VIEW_ID.PanelHotSpotBanner)
	end
end

function HotSpotData._registerEvent()
    Event.Reg(self, "LOADING_END", function()
		if not self.bHasAutoOpen then
			self.AutoOpenHotSpotBanner()

			Storage.HotSpotRole.fPopVersion = self.tWebCareerData and self.tWebCareerData.fPopVersion or 0
			Storage.HotSpotRole.Dirty()

			self.bHasAutoOpen = true
		end
    end)

	Event.Reg(self, EventType.OnAccountLogout, function()
		self.bHasAutoOpen = false
	end)

	-- 在这里处理相关逻辑，因为要用到服务列表
	Event.Reg(self, EventType.OnRoleLogin, function()
		if self.tWebCareerData and self.tWebCareerData.szPopID then
			local tPopID = SplitString(self.tWebCareerData.szPopID, "|")
			local LoginServerList = LoginMgr.GetModule(LoginModule.LOGIN_SERVERLIST)
			local tbSelectServer = LoginServerList.GetSelectServer()
			-- local szUserServer = select(6, GetUserServer())
			local szUserServer = tbSelectServer and UIHelper.UTF8ToGBK(tbSelectServer.szRealServer) or ""--数据互通主服务器名
			for _, fPopID in ipairs(tPopID or {}) do
				fPopID = tonumber(fPopID)
				local tInfo = self.tWebCareerEvent and self.tWebCareerEvent[fPopID]
				if tInfo and (tInfo.szServer == "" or string.match(szUserServer, tInfo.szServer)) and (tInfo.szClient == "" or IsAssignClient(tInfo.szClient)) then
					self.tWebCareerData.fPopID = fPopID
					break
				end
			end

			self.UpdateImageCount()
		end
	end)
    Event.Reg(self, "CURL_DOWNLOAD_RESULT", function()
        self.OnUrlData()
    end)

end


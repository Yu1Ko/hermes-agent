-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIPVPFieldView
-- Date: 2023-08-11 10:34:56
-- Desc: 千里伐逐 + JX插件相关功能 跨服Boss进度监控 client\interface\JX\JX_Battle\JX_CrossGateBoss.lua
-- Prefab: PanelQianLiFaZhu
-- ---------------------------------------------------------------------------------
local NEW_SERVER_TYPE = 2
local REFRESH_CD = 300              --刷新界面的间隔
local SERVER_TOTAL_RANK_NUM = 3     --参与排名的服务器数量
local SERVER_TOTAL_FIELD_NUM = 1    --据点数量

local nDataLengthPerServer = 10
local DATA_DOUBLE_INDEX = 1023 --双倍分线的数据位
local DATA_DOUBLE_INDEX2 = 1022 --双倍分线的数据位（新服）

local SERVER_CROWDED_DEGREE = {
    NORMAL  = 1,
    BUSY    = 2,
    CROWDED = 3
}

local PAGE = {
    BATTLE = 1,
    BOSS   = 2
}

local BOSS_PAGE = {
    ZhengRong = 1,  --峥嵘
    ZhenWu = 2      --真武
}

local tActivityID = {867, 868} --世界Boss狂欢夜活动ID

-----------------------------DataModel------------------------------
local DataModel = {}

function DataModel.Init()
    DataModel.nMyServer     = -1
    DataModel.nCurServer    = -1
    DataModel.nSelServer    = -1
    DataModel.nSelBossSer   = -1
    DataModel.nCDCount 	    = REFRESH_CD
    DataModel.nSelStandHold = -1
    DataModel.tServerInfo   = {}
    DataModel.tBossInfo     = {}
    DataModel.bFirstOpen    = true
    DataModel.nSelPage      = PAGE.BATTLE
    DataModel.nSelBossPage  = BOSS_PAGE.ZhengRong
    DataModel.bFreshServer  = nil

    DataModel.SetMyServer()
    DataModel.UpdatePlayerCurrentServer()
    DataModel.SetSelStandHold(1)
    DataModel.ApplyPVPServerData()

end

function DataModel.UnInit()
    DataModel.nMyServer     = nil
    DataModel.nCurServer    = nil
    DataModel.nSelServer    = nil
    DataModel.nSelBossSer   = nil
    DataModel.nCDCount 	    = nil
    DataModel.nSelStandHold = nil
    DataModel.tServerInfo   = nil
    DataModel.tBossInfo     = nil
    DataModel.bFirstOpen    = nil
    DataModel.nSelPage      = nil
    DataModel.nSelBossPage  = nil
    DataModel.bFreshServer  = nil
end

function DataModel.SetSelServer(nIndex)
    DataModel.nSelServer = nIndex
end

function DataModel.GetSelServer()
    return DataModel.nSelServer
end

function DataModel.SetSelBossServer(nIndex)
    DataModel.nSelBossSer = nIndex
end

function DataModel.GetSelBossServer()
    return DataModel.nSelBossSer
end

function DataModel.SetCurServer(nIndex)
    DataModel.nCurServer = nIndex
end

function DataModel.GetCurServer()
    return DataModel.nCurServer
end

function DataModel.IsFirstOpened()
    return DataModel.bFirstOpen
end

function DataModel.SetPanelOpenedState()
    DataModel.bFirstOpen = false
end

function DataModel.SetSelPage(nPage)
    DataModel.nSelPage = nPage
end

function DataModel.GetSelPage()
    return DataModel.nSelPage
end

function DataModel.SetSelBossPage(nPage)
    DataModel.nSelBossPage = nPage
end

function DataModel.GetSelBossPage()
    return DataModel.nSelBossPage
end

function DataModel.GetCurBossName(nPage)
    local szBossName = ""
    local nTime = GetCurrentTime()
    local tBossList = Table_GetSwitchServerBossInfo(nPage)
    if tBossList then
        for _, tBoss in ipairs(tBossList) do
            if nTime >= tBoss.nOpenTime and nTime < tBoss.nEndTime then
                szBossName = tBoss.szName
                break
            end
        end
    end
    return szBossName
end

function DataModel.ApplyPVPServerData()
    local hPVPFieldClient = GetPVPFieldClient()
    hPVPFieldClient.ApplyPVPFieldBulletin()
end

function DataModel.UpdatePlayerCurrentServer()
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end
    local tAllFieldInfo = Table_GetAllSwitchServerFieldInfo()
    local dwCurMapID = pPlayer.GetMapID()
    local nCurServer = -1
    for _, tInfo in ipairs(tAllFieldInfo) do
        if tInfo.dwMapID == dwCurMapID then
            local hScene = pPlayer.GetScene()
            nCurServer = hScene.nCopyIndex
            break
        end
    end
    if nCurServer == -1 then
        nCurServer = DataModel.nMyServer
    end
    DataModel.SetCurServer(nCurServer)

    local tServerInfo = Table_GetSwitchServerInfo(nCurServer)
    if tServerInfo and tServerInfo.bBoss then
        DataModel.SetSelBossServer(nCurServer)
    else
        DataModel.SetSelServer(nCurServer)
    end
end

function DataModel.GetPassTimeText(nTime)
    local szTime = g_tStrings.STR_NONE
    if nTime and nTime ~= 0 then
        local t = TimeToDate(nTime)
	    local szMinute = string.format("%02d", t.minute)
        szTime = FormatString(g_tStrings.STR_TIME_6, t.year, t.month, t.day, t.hour, szMinute)
    end
    return szTime
end

function DataModel.SetSelStandHold(nStandID)
    DataModel.nSelStandHold = nStandID
end

function DataModel.GetSelStandHold()
    return DataModel.nSelStandHold
end

function DataModel.GetStandHoldMapID(nIndex)
    local tFieldInfo = Table_GetSwitchServerFieldInfo(nIndex)
    if not tFieldInfo then
        return
    end
    local dwMapID = tFieldInfo.dwMapID
    return dwMapID
end

function DataModel.SetMyServer()
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end
    local dwCenterID
    if IsRemotePlayer(pPlayer.dwID) then
        dwCenterID = UI_GetClientPlayerCenterID()
    else
        dwCenterID = GetCenterID()
    end

    local nFreshType = GetCenterFreshTypeByCenterID(dwCenterID)
    if nFreshType ~= 0 then
        DataModel.bFreshServer = nFreshType == NEW_SERVER_TYPE
    end

    local tAllServerInfo = Table_GetAllSwitchServerInfo()
    for _, tInfo in ipairs(tAllServerInfo) do
        if dwCenterID == tInfo.dwCenterID then
            DataModel.nMyServer = tInfo.nIndex
            break
        end
    end
end

function DataModel.IsMyServer(nIndex)
    local nMyServer = DataModel.nMyServer
    return nMyServer == nIndex
end


function DataModel.SortListByPeopleCount(tAllServerInfo)
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end

    local nMyCamp = pPlayer.nCamp

    local function fnSort(t1, t2)
        if t1.nCamp == nMyCamp and t2.nCamp == nMyCamp then
            if t1.nPeopleCount == t2.nPeopleCount then
                return t1.nCopyIndex < t2.nCopyIndex
            else
                return t1.nPeopleCount > t2.nPeopleCount
            end
        elseif t1.nCamp == nMyCamp and t2.nCamp ~= nMyCamp then
            return true
        elseif t1.nCamp ~= nMyCamp and t2.nCamp == nMyCamp then
            return false
        else
            return t1.nCopyIndex < t2.nCopyIndex
        end
    end
    if nMyCamp ~= CAMP.NEUTRAL then
        if not tAllServerInfo then
            return
        end
        table.sort(tAllServerInfo, fnSort)
    end

    for nPos, tInfo in ipairs(tAllServerInfo) do
        if DataModel.IsMyServer(tInfo.nCopyIndex) then
            table.remove(tAllServerInfo, nPos)
            table.insert(tAllServerInfo, 1, tInfo)
            break
        end
    end
end

function DataModel.InitServerInfo()
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end

    local bInFreshServer = DataModel.IsFreshServerPlayer()
    local tAllServerInfo = DataModel.ThePassFight_GetInfo(pPlayer)
    local tBattleServerList = {}
    local tBossServerList = {}
    for nIndex, tInfo in ipairs(tAllServerInfo) do
        local tServerInfo = Table_GetSwitchServerInfo(nIndex)
        if tServerInfo then
            local nFreshType = GetCenterFreshTypeByCenterID(tServerInfo.dwCenterID)
            if nFreshType == 0 then
                return
            end
            tInfo.nOpenTime = tServerInfo.nOpenTime
            tInfo.szBossName = DataModel.GetCurBossName(tServerInfo.nBossPage)
            tInfo.szBindCenter = tServerInfo.szBindCenter
            if (bInFreshServer and nFreshType == NEW_SERVER_TYPE) or (not bInFreshServer and nFreshType ~= NEW_SERVER_TYPE) then
                if tServerInfo.bBoss then
                    local nBossPage = tServerInfo.nBossPage
                    if not tBossServerList[nBossPage] then
                        tBossServerList[nBossPage] = {}
                    end
                    table.insert(tBossServerList[nBossPage], tInfo)
                else

                    table.insert(tBattleServerList, tInfo)
                end
            end
        end
    end
    DataModel.SortListByPeopleCount(tBattleServerList)
    DataModel.tServerInfo = tBattleServerList
    DataModel.tBossInfo = tBossServerList
    FireUIEvent("SWITCH_SERVER_INIT_INFO", DataModel.tServerInfo)
end

function DataModel.UpdateServerInfo()
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end
    local tAllServerInfo = DataModel.ThePassFight_GetInfo(pPlayer)
    if not DataModel.tServerInfo then
        return
    end
    for i = 1, #DataModel.tServerInfo do --只改数据不改位置
        local tOrigInfo = DataModel.tServerInfo[i]
        local nIndex = tOrigInfo.nCopyIndex
        local nOpenTime = tOrigInfo.nOpenTime
        local szBossName = tOrigInfo.szBossName
        local szBindCenter = tOrigInfo.szBindCenter
        local tGetInfo = tAllServerInfo[nIndex]
        if tGetInfo then
            DataModel.tServerInfo[i] = tGetInfo
            DataModel.tServerInfo[i].nOpenTime = nOpenTime
            DataModel.tServerInfo[i].szBossName = szBossName
            DataModel.tServerInfo[i].szBindCenter = szBindCenter
        end
    end
    DataModel.SortListByPeopleCount(DataModel.tServerInfo)

    if not DataModel.tBossInfo then
        return
    end
    for _, tPageInfo in pairs(DataModel.tBossInfo) do
        for _, tInfo in pairs(tPageInfo) do
            local nIndex = tInfo.nCopyIndex
            local tGetInfo = tAllServerInfo[nIndex]
            if tGetInfo then
                tInfo.nPeopleCount = tGetInfo.nPeopleCount
            end
        end
    end
end

function DataModel.IsBossActivityOpened()
    local bOpen = false
    for _, dwActivityID in pairs(tActivityID) do
        if ActivityData.IsActivityOn(dwActivityID) or UI_IsActivityOn(dwActivityID) then
            bOpen = true
            break
        end
    end
    return bOpen
end

function DataModel.GetBossLife(nLife)
    local szBossLife = ""
    if not DataModel.IsBossActivityOpened() then
        return szBossLife
    end
    if nLife then
        if nLife < 1 then
            szBossLife = g_tStrings.STR_SWITCH_SERVER_BOSS_DEAD
        else
            szBossLife = nLife .. "%"
        end
    else
        szBossLife = g_tStrings.STR_SWITCH_SERVER_BOSS_DEAD
    end
    return szBossLife
end


function DataModel.ThePassFight_GetInfo(player)
	local PVPFieldClient = GetPVPFieldClient()
	local tInfo = {}
	local tBulletinData = PVPFieldClient.GetBulletinData()
	local nDoubleServerCopyIndex = DataModel.GetDataThePassFigh(tBulletinData, DATA_DOUBLE_INDEX, 1)
    local nDoubleServerCopyIndex2 = DataModel.GetDataThePassFigh(tBulletinData, DATA_DOUBLE_INDEX2, 1)
	local nCurTime = GetCurrentTime()
	--这是一份初始化数据
	for nCopyIndex = 1, PVPFieldClient.GetPVPFieldMapInfoCount() do
		local nOffset = (nCopyIndex - 1) * nDataLengthPerServer
		local nPassTime = DataModel.GetDataThePassFigh(tBulletinData, nOffset + 3, 4) --保护期时间，超过3小时传0
		if nCurTime >= nPassTime then
			nPassTime = 0
		end
		local nCamp = player.nCamp
		local nPeopleCount = DataModel.GetDataThePassFigh(tBulletinData, nOffset + 1, 1)
		if nCamp == 0 then
			nPeopleCount = DataModel.GetValueThePassFigh(nPeopleCount, 3) + 1
		elseif nCamp == 1 then
			nPeopleCount = DataModel.GetValueThePassFigh(nPeopleCount, 2) + 1
		elseif nCamp == 2 then
			nPeopleCount = DataModel.GetValueThePassFigh(nPeopleCount, 1) + 1
		end
		local nBossLife = DataModel.GetDataThePassFigh(tBulletinData, nOffset + 7, 1)	--世界boss血量百分比
		if nCopyIndex >= 31 and nCopyIndex <= 62 then
			tInfo[nCopyIndex] = {
				nPeopleCount = nPeopleCount,	--DataModel.GetDataThePassFigh(tBulletinData, nOffset + 1, 1), --人数检测 界面红黄绿状态
				nCopyIndex = nCopyIndex,
				nBossLife = nBossLife,
                nPassTime = nPassTime,
                nCamp = DataModel.GetDataThePassFigh(tBulletinData, nOffset, 1),
			}
		else
			tInfo[nCopyIndex] = {
				nCamp = DataModel.GetDataThePassFigh(tBulletinData, nOffset, 1), --当前分线所属阵营
				nPeopleCount = nPeopleCount,	--DataModel.GetDataThePassFigh(tBulletinData, nOffset + 1, 1), --人数检测 界面红黄绿状态
				nFriendServer = DataModel.GetDataThePassFigh(tBulletinData, nOffset + 2, 1), --友好服
				nPassTime = nPassTime, --保护期界面时间
				bDoubleServer = (nDoubleServerCopyIndex == nCopyIndex) or (nDoubleServerCopyIndex2 == nCopyIndex), --双倍服
				nCopyIndex = nCopyIndex,
				nBossLife = nBossLife
			}
		end
	end
	return tInfo
end

function DataModel.GetDataThePassFigh(tBulletinData, nOffset, nLength)
	if nLength == 1 then
		return tBulletinData.GetCustomUnsigned1(nOffset)
	elseif nLength == 2 then
		return tBulletinData.GetCustomUnsigned2(nOffset)
	elseif nLength == 4 then
		return tBulletinData.GetCustomUnsigned4(nOffset)
	end
end

function DataModel.GetValueThePassFigh(value, bit)
	if bit <= 0 then
		return
	end
	return  math.floor((value % (10 ^ bit)) / (10 ^ (bit - 1)))
end

function DataModel.IsFreshServerPlayer()
    return DataModel.bFreshServer
end

-- ----------------------------------------------------------

---@class UIPVPFieldView
local UIPVPFieldView = class("UIPVPFieldView")

-- local SERVER_COUNT = 15
local REFRESH_COUNT = 60 * 60

function UIPVPFieldView:OnEnter(bSelectBossPage)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        Timer.AddFrameCycle(self, 1, function()
            self:OnUpdate()
        end)
    end

    -- self.nFrameCount = 0
    self.tServerList = {}
    self.bTimeDown = false

    DataModel.Init()
    self:InitUI()

    --TODO RemoteCommand.On_OpenSwitchServerPanel

    -- self:RefreshServerInfo(true)
    UIHelper.SetSwallowTouches(self.ScrollViewServerList1, false)
    UIHelper.SetSwallowTouches(self.ScrollViewServerList2, false)

    if bSelectBossPage then
        -- fixme: 这里直接打开boss页后，点回千里伐逐页，服务器列表会是空的，往下拉一下才会出来，并且会不停上下滚动
        UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroupNavigation, self.TogNavigation02)
        self:ClickBossPage()
    end
end

function UIPVPFieldView:OnExit()
    self.bInit = false
    self:UnRegEvent()

    DataModel.UnInit()
end

function UIPVPFieldView:OnUpdate()
    if DataModel.nCDCount then
		if DataModel.nCDCount == 0 then
			DataModel.nCDCount = REFRESH_CD
            DataModel.ApplyPVPServerData()
		else
			DataModel.nCDCount = DataModel.nCDCount - 1
		end
	end

    -- self.nFrameCount = self.nFrameCount + 1
    -- if self.nFrameCount >= 16 then
    --     self:RefreshServerInfo()
    -- end
end

function UIPVPFieldView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnExamine, EventType.OnClick, function()

        local bInPVPField = PVPFieldData.IsInPVPField()
        if not bInPVPField then
            local nSelStandHold = DataModel.GetSelStandHold()
            local dwMapID = DataModel.GetStandHoldMapID(nSelStandHold)
            local nSelPage = DataModel.GetSelPage()
            local nSelServer
            if nSelPage == PAGE.BATTLE then
                nSelServer = DataModel.GetSelServer()
            elseif nSelPage == PAGE.BOSS then
                nSelServer = DataModel.GetSelBossServer()
            else
                return
            end
            if not nSelServer then
                return
            end

            local szServerName = GetPVPFieldClient().GetPVPFieldBindCenter(dwMapID, nSelServer)
            local szContent = FormatString(g_tStrings.STR_SWITCH_SERVER_CONFIRM, UIHelper.GBKToUTF8(szServerName), Table_GetSwitchServerMapName())

            local function enterCrossServerMap()
                MapMgr.CampCrossServerTeleport(dwMapID, nSelServer)
                UIMgr.Close(VIEW_ID.PanelQianLiFaZhu) --self
                UIMgr.Close(VIEW_ID.PanelPVPCamp)
            end

            --地图资源下载检测拦截
            if not PakDownloadMgr.UserCheckDownloadMapRes(dwMapID, enterCrossServerMap, "地图资源文件下载完成，" .. szContent) then
                return
            end

            UIHelper.ShowConfirm(szContent, enterCrossServerMap)
        else
            UIMgr.Close(self)
            UIMgr.Close(VIEW_ID.PanelPVPCamp)
            PVPFieldData.LeavePVPField()
        end


    end)

    UIHelper.BindUIEvent(self.TogNavigation01, EventType.OnClick, function()
        local bSelect = UIHelper.GetSelected(self.TogNavigation01)
        if bSelect then
            self:OnActivePage(PAGE.BATTLE)
        end
    end)

    UIHelper.BindUIEvent(self.TogNavigation02, EventType.OnClick, function()
        self:ClickBossPage()
    end)

    UIHelper.BindUIEvent(self.TogTabList01, EventType.OnSelectChanged, function(_, bSelect)
        if bSelect then
            self:OnSelectBossPage(BOSS_PAGE.ZhengRong)
        end
    end)

    UIHelper.BindUIEvent(self.TogTabList02, EventType.OnSelectChanged, function(_, bSelect)
        if bSelect then
            self:OnSelectBossPage(BOSS_PAGE.ZhenWu)
        end
    end)

    UIHelper.BindUIEvent(self.BtnDetailFriendServer, EventType.OnClick, function()
        local bVis = UIHelper.GetVisible(self.WidgetFriendSeverTip)
        UIHelper.SetVisible(self.WidgetFriendSeverTip, not bVis)
    end)

    UIHelper.BindUIEvent(self.BtnDetailServerMsg, EventType.OnClick, function()
        local bVis = UIHelper.GetVisible(self.WidgetSeverMessageTip)
        UIHelper.SetVisible(self.WidgetSeverMessageTip, not bVis)
    end)

    UIHelper.BindUIEvent(self.BtnGrade, EventType.OnClick, function()
        -- local bDown = UIHelper.GetOpacity(self.ImgDown)
        self.bTimeDown = not self.bTimeDown
        self:UpdateSortType()
        self:UpdateServerList(true)
    end)
end


function UIPVPFieldView:RegEvent()
    Event.Reg(self, "ON_PVP_FIELD_BULLETIN_NOTIFY", function()
        local bFirstOpen = DataModel.IsFirstOpened()
        if bFirstOpen then
            DataModel.InitServerInfo()
        else
            DataModel.UpdateServerInfo()
        end
		self:UpdateInfo()
        DataModel.SetPanelOpenedState()
    end)
    Event.Reg(self, "On_GetRestAvailableZhanJie", function(nRestZhanJie)
        self:SetRestAvailableZhanJie(nRestZhanJie)
    end)

    Event.Reg(self, EventType.OnTouchViewBackGround, function(scriptView)
        UIHelper.SetVisible(self.WidgetSeverMessageTip, false)
        UIHelper.SetVisible(self.WidgetFriendSeverTip, false)
    end)
end

function UIPVPFieldView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIPVPFieldView:InitUI()
    UIHelper.ToggleGroupAddToggle(self.ToggleGroupNavigation, self.TogNavigation01)
    UIHelper.ToggleGroupAddToggle(self.ToggleGroupNavigation, self.TogNavigation02)
    UIHelper.SetClickInterval(self.TogNavigation02, 0)
    UIHelper.ToggleGroupAddToggle(self.ToggleGroupTab, self.TogTabList01)
    UIHelper.ToggleGroupAddToggle(self.ToggleGroupTab, self.TogTabList02)
    UIHelper.SetVisible(self.ImgDown, false)
    UIHelper.SetVisible(self.ImgUp, false)
    UIHelper.SetTouchEnabled(self.BtnGrade, false)
    RemoteCallToServer("On_CrossServer_TitlePoint") --return: On_GetRestAvailableZhanJie
end

function UIPVPFieldView:UpdateInfo(bForceRefresh)
    local nSelPage = DataModel.GetSelPage()
    self:UpdateServerInfoType()
    if nSelPage == PAGE.BATTLE then
        self:UpdateServerList(bForceRefresh)
    elseif nSelPage == PAGE.BOSS then
        self:UpdateBossServerList(bForceRefresh)
    else
        return
    end
    self:UpdateSortType()
    self:UpdateServerListType()
    self:UpdateMapBtnState()

    --资源下载Widget
    local nSelStandHold = DataModel.GetSelStandHold()
    if not nSelStandHold then
        UIHelper.SetVisible(self.WidgetDownload, false)
        return
    end

    local scriptDownload = UIHelper.GetBindScript(self.WidgetDownload)
    local dwMapID = DataModel.GetStandHoldMapID(nSelStandHold)
    local nPackID = PakDownloadMgr.GetMapResPackID(dwMapID)
    scriptDownload:OnInitWithPackID(nPackID)
    UIHelper.SetVisible(self.WidgetDownload, true)
end

function UIPVPFieldView:OnActivePage(nPage)
    DataModel.SetSelPage(nPage)
    self:UpdateInfo(true)
    if nPage == PAGE.BATTLE then
        RemoteCallToServer("On_CrossServer_TitlePoint") --return: On_GetRestAvailableZhanJie
    end
end

function UIPVPFieldView:UpdateSortType()
    UIHelper.SetOpacity(self.ImgDown, self.bTimeDown and 255 or 70)
    UIHelper.SetOpacity(self.ImgUp, self.bTimeDown and 70 or 255)
end

function UIPVPFieldView:UpdateServerListType()
    local nSelPage = DataModel.GetSelPage()
    UIHelper.SetVisible(self.WidgetServerList1, nSelPage == PAGE.BATTLE)
    UIHelper.SetVisible(self.WidgetServerList2, nSelPage == PAGE.BOSS)
    UIHelper.SetVisible(self.WidgetAnchorLeft, nSelPage == PAGE.BOSS)

    if nSelPage == PAGE.BOSS then
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewTab)
    end
end

function UIPVPFieldView:UpdateServerInfoType()
    local nSelPage = DataModel.GetSelPage()
    UIHelper.SetVisible(self.LabelBossMessage1, nSelPage == PAGE.BOSS)
    UIHelper.SetVisible(self.LabelBossMessage2, nSelPage == PAGE.BOSS)

    UIHelper.SetVisible(self.WidgetSeverMessage1, nSelPage == PAGE.BATTLE)
    UIHelper.SetVisible(self.WidgetSeverMessage2, nSelPage == PAGE.BATTLE)
    UIHelper.SetVisible(self.WidgetSeverMessage3, nSelPage == PAGE.BATTLE)
    UIHelper.SetVisible(self.WidgetSeverTime, nSelPage == PAGE.BATTLE)
    UIHelper.SetVisible(self.WidgetSeverFriend, false)
    UIHelper.SetVisible(self.WidgetSeverProtect, nSelPage == PAGE.BATTLE)
    UIHelper.SetVisible(self.WidgetSeverForm, nSelPage == PAGE.BATTLE)
    UIHelper.SetVisible(self.LabelServerMessage2, nSelPage == PAGE.BATTLE)
end

function UIPVPFieldView:UpdateServerList(bForceSort)
    local bActivityOpened = DataModel.IsBossActivityOpened()
    local tInfo = DataModel.tServerInfo
    if not tInfo then
        return
    end

    local bFreshUI = bForceSort or DataModel.IsFirstOpened()

    self.tServerList = {}
    UIHelper.RemoveAllChildren(self.ScrollViewServerList1)

    -- local funcSort = function(l ,r)
    --     if self.bTimeDown then
    --         return l.nPassTime > r.nPassTime
    --     else
    --         return l.nPassTime < r.nPassTime
    --     end
    -- end

    -- if bFreshUI then
    --     table.sort(tInfo, funcSort)
    -- end

    for _, tServer in ipairs(tInfo) do
        local tData = {}

        local nIndex = tServer.nCopyIndex
        tData.nIndex = nIndex
        tData.szBossLife = DataModel.GetBossLife(tServer.nBossLife)
        tData.bBossOpen = DataModel.IsBossActivityOpened()
        tData.nBossLife = tServer.nBossLife
        tData.szName = tServer.szBindCenter --服务器名称

        local nCurServer = DataModel.GetCurServer()
        tData.bCurServer = nIndex == nCurServer --玩家所在服务器标记
        tData.bMyServer = DataModel.IsMyServer(nIndex) --本服标记
        tData.nCamp = tServer.nCamp --阵营标记
        tData.nCrowdedDegree = tServer.nPeopleCount --拥挤标记 SERVER_CROWDED_DEGREE.XXX
        tData.bDoubleServer = tServer.bDoubleServer --双倍

        local nPassTime = tServer.nPassTime
        tData.bProtection = nPassTime and nPassTime ~= 0 --保护期
        tData.nPassTime = nPassTime
        tData.bSel = DataModel.GetSelServer() == nIndex

        if bActivityOpened and tServer.szBossName and tServer.szBossName ~= "" then
            tData.szBossName = UIHelper.GBKToUTF8(tServer.szBossName)
        end


        local nSelServer = DataModel.GetSelServer()
        if nSelServer == -1 then
            self:OnChangeSelServer(tData)
        end

        if DataModel.GetSelServer() == nIndex then
            self:UpdateServerInfo(tData, bFreshUI)
        end


        local scriptView = UIMgr.AddPrefab(PREFAB_ID.WidgetQLFZServer, self.ScrollViewServerList1, tData, self)

        self:UpdateServerItemState(tData)

        table.insert(self.tServerList, tData)
    end

    if bFreshUI then
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewServerList1)
    end
end

function UIPVPFieldView:UpdateBossServerList(bForceRefresh)
    local nBossPage = DataModel.GetSelBossPage()
    local tInfo = DataModel.tBossInfo[nBossPage]
    if not tInfo then
        return
    end

    local bFreshUI = bForceRefresh or DataModel.IsFirstOpened()

    UIHelper.RemoveAllChildren(self.ScrollViewServerList2)

    for _, tServer in ipairs(tInfo) do
        local tData = {}

        local nIndex = tServer.nCopyIndex
        tData.nIndex = nIndex
        tData.szBossLife = DataModel.GetBossLife(tServer.nBossLife)
        tData.bBossOpen = DataModel.IsBossActivityOpened()
        tData.nBossLife = tServer.nBossLife
        tData.szName = tServer.szBindCenter --服务器名称

        local nCurServer = DataModel.GetCurServer()
        tData.bCurServer = nIndex == nCurServer --玩家所在服务器标记
        tData.nCrowdedDegree = tServer.nPeopleCount --拥挤标记 SERVER_CROWDED_DEGREE.XXX
        tData.bSel = DataModel.GetSelBossServer() == nIndex

        local nSelServer = DataModel.GetSelBossServer()
        if nSelServer == -1 then
            -- DataModel.SetSelBossServer(nIndex)
            -- nSelServer = nIndex
            self:OnChangeSelBossServer(tData)
        end
        if nIndex == nSelServer then
            self:UpdateBossServerInfo(tData)
        end

        local scriptView = UIMgr.AddPrefab(PREFAB_ID.WidgetBossServer, self.ScrollViewServerList2, tData, self)
        self:UpdateBossServerItemState(tData)
    end

    if bFreshUI then
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewServerList2)
    end
end

function UIPVPFieldView:UpdateMapBtnState()
    --进入地图/离开地图 按钮状态
    local bSwitchServer = PVPFieldData.IsInPVPField()
    -- hBtnEnterMap:Show(not bSwitchServer)
    -- hBtnLeaveMap:Show(bSwitchServer)
    UIHelper.SetString(self.LabelExamine, bSwitchServer and "离开地图" or "前往地图")
end

--根据当前选中服务器，更新UI信息
function UIPVPFieldView:UpdateServerInfo(tData, bFreshUI)
    local nSelServer = tData.nIndex

    local tServerInfo = Table_GetSwitchServerInfo(nSelServer)
    local szServerName = UIHelper.GBKToUTF8(tServerInfo.szBindCenter)

    local t = TimeToDate(tServerInfo.nOpenTime)
    local szOpenTime = FormatString(g_tStrings.STR_TIME_1, t.year, t.month, t.day)


    local tbMessage = self:GetServerMessage(szServerName)
    for nIndex, szText in ipairs(tbMessage) do
        UIHelper.SetString(self.tbLabelMessage[nIndex], szText)
    end

    --TODO

    UIHelper.SetString(self.LabelNormal02, szServerName)

    local szOpenTime = g_tStrings.STR_OPENSERVER_TIME.."<color=#AED9E0>"..t.year.."/"..t.month.."/"..t.day.."</color>"
    UIHelper.SetRichText(self.LabelSeverTime, szOpenTime)


    local szPassTime = DataModel.GetPassTimeText(tData.nPassTime)
    UIHelper.SetRichText(self.LabelServerProtect, g_tStrings.STR_PROTECT_TIME.."<color=#AED9E0>"..szPassTime.."</color>")

    UIHelper.SetString(self.LabelServerMessage2, UIHelper.GBKToUTF8(tServerInfo.szContent))

    -- local szLife = DataModel.GetBossLife(tServerInfo.nBossLife)
    local szBossName = tData.szBossName
    local szBossLife = DataModel.GetBossLife(tData.nBossLife)

    UIHelper.SetVisible(self.LabelBossMessage1, szBossName ~= nil)
    UIHelper.SetVisible(self.LabelBossMessage2, szBossLife and szBossLife ~= "")

    if szBossName then
        UIHelper.SetRichText(self.LabelBossMessage1, "当前等级首领：" .. szBossName)
    end

    if szBossLife and szBossLife ~= "" then
        UIHelper.SetRichText(self.LabelBossMessage2, "当前首领剩余血量：" .. szBossLife)
    end


    if bFreshUI then
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewBossMessage)
    end
    UIHelper.SetSwallowTouches(self.ScrollViewBossMessage, false)

end

--更新Item状态
function UIPVPFieldView:UpdateServerItemState(tData)

end

function UIPVPFieldView:UpdateBossServerInfo(tData)
    local nSelServer = tData.nIndex
    DataModel.SetSelBossServer(nSelServer)

    local tServerInfo = Table_GetSwitchServerInfo(nSelServer)
    local szSelBossServer = UIHelper.GBKToUTF8(tServerInfo.szBindCenter)
    local szBossName = UIHelper.GBKToUTF8(DataModel.GetCurBossName(tServerInfo.nBossPage))
    local szBossLife = DataModel.GetBossLife(tData.nBossLife)

    local szBossName = "<color=#fffaa3>"..g_tStrings.STR_REGRESSION_BOSS.."</color>"..szBossName
    UIHelper.SetRichText(self.LabelBossMessage1, szBossName)

    local szHP = "<color=#fffaa3>"..g_tStrings.STR_BOSS_HP.."</color>"..szBossLife
    UIHelper.SetRichText(self.LabelBossMessage2, szHP)

    UIHelper.SetString(self.LabelNormal02, UIHelper.GBKToUTF8(tData.szName))

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewBossMessage)
end


function UIPVPFieldView:UpdateBossServerItemState(tData)
    self:UpdateServerItemState(tData)
end

function UIPVPFieldView:GetSelServerData(nIndex)
    for key, tbInfo in pairs(DataModel.tServerInfo) do
        if tbInfo.nCopyIndex == nIndex then
            return tbInfo
        end
    end
    return nil
end

function UIPVPFieldView:OnChangeSelServer(tData)
    local nLastSelServer = DataModel.GetSelServer()
    if not nLastSelServer then
        return
    end
    local nSelServer = tData.nIndex
    if nLastSelServer == nSelServer then
        return
    end

    local tbLastData = self:GetSelServerData(nLastSelServer)
    if tbLastData then
        tbLastData.bSel = false
    end


    DataModel.SetSelServer(nSelServer)
    --TODO
    -- if hLastServer then
    --     hLastServer.bSel = false
    --     self:UpdateServerItemState(hLastServer)
    -- end
    tData.bSel = true
    self:UpdateServerItemState(tData)
    self:UpdateServerInfo(tData, true)
end

function UIPVPFieldView:OnChangeSelBossServer(tData)
    local nLastSelServer = DataModel.GetSelBossServer()
    if not nLastSelServer then
        return
    end
    local nSelServer = tData.nIndex
    if nLastSelServer == nSelServer then
        return
    end
    --TODO
    -- if hLastServer then
    --     hLastServer.bSel = false
    --     self:UpdateBossServerItemState(hLastServer)
    -- end
    DataModel.SetSelBossServer(nSelServer)
    tData.bSel = true
    self:UpdateBossServerItemState(tData)
    self:UpdateBossServerInfo(tData)
end

function UIPVPFieldView:OnSelectBossPage(nBossPage)
    local nCurBossPage = DataModel.GetSelBossPage()
    if nCurBossPage ~= nBossPage then
        DataModel.SetSelBossPage(nBossPage)
        self:UpdateBossServerList(true)
    end
end


function UIPVPFieldView:OnEnterMapClick()
    local nSelStandHold = DataModel.GetSelStandHold()
    if not nSelStandHold then
        return
    end
    local dwMapID = DataModel.GetStandHoldMapID(nSelStandHold)
    local nSelPage = DataModel.GetSelPage()
    local nSelServer
    if nSelPage == PAGE.BATTLE then
        nSelServer = DataModel.GetSelServer()
    elseif nSelPage == PAGE.BOSS then
        nSelServer = DataModel.GetSelBossServer()
    else
        return
    end
    if not nSelServer then
        return
    end
    local szServerName = UIHelper.GBKToUTF8(GetPVPFieldClient().GetPVPFieldBindCenter(dwMapID, nSelServer))
    local szMessage = FormatString(g_tStrings.STR_SWITCH_SERVER_CONFIRM, szServerName)
    local dialog = UIHelper.ShowConfirm(szMessage, function()
        RemoteCallToServer("On_CrossServer_Transfer", dwMapID, nSelServer)
    end)
    dialog:SetButtonContent("Confirm", g_tStrings.WORLD_MAP_TO)
    dialog:SetButtonContent("Cancel", g_tStrings.STR_HOTKEY_CANCEL)
end

function UIPVPFieldView:SetRestAvailableZhanJie(nRestZhanJie)
    local szRestZhanJie = "<color=#fffaa3>"..nRestZhanJie.."</color>"
    local szContent = string.format(g_tStrings.STR_BATTLE_RANK, szRestZhanJie)
    UIHelper.SetRichText(self.LabelNum, szContent)
end

function UIPVPFieldView:IsCeaseFireTime(nTime)
    local nCurrentTime = GetCurrentTime()
    local tDate
    if nTime then
        if nTime > nCurrentTime then -- 凌晨刚打完时，根据保护期时间计算是否休战
            tDate = TimeToDate(nTime)
        end
    end
    if not tDate then
        tDate = TimeToDate(nCurrentTime) -- 上午12点前则根据当前时间判断是否休战
    end
    return (tDate.hour >= 3 and tDate.hour <= 11)
end

-- 刷新监控列表的信息
function UIPVPFieldView:RefreshServerInfo(bInit)
    local tCrossMsg = PVPFieldData.GetCrossMsg()
    local nCurrentTime = GetCurrentTime()
    local player = GetClientPlayer()
    if not player then
        return
    end

    local function fnSort(tInfo1, tInfo2)
        if tInfo1.nPassTime == tInfo2.nPassTime then
            if tInfo1.nOpenTime == tInfo2.nOpenTime then
                return tInfo1.nCopyIndex > tInfo2.nCopyIndex
            else
                return tInfo1.nOpenTime > tInfo2.nOpenTime --新服在前
            end
        else
            return tInfo1.nPassTime < tInfo2.nPassTime
        end
    end

    --改成在同一页显示所有信息，优先自身阵营排序
    local tCamp
    local nCamp = player.nCamp
    if nCamp == CAMP.GOOD or nCamp == CAMP.NEUTRAL then
        tCamp = {CAMP.GOOD, CAMP.EVIL}
    else
        tCamp = {CAMP.EVIL, CAMP.GOOD}
    end

    local tInfoList = {}
    for _, nCamp in ipairs(tCamp) do
        local tTemp = {}
        for szServer, tInfo in pairs(tCrossMsg) do
            --占领已经超过N分钟就清空占领信息
            if tInfo["nBossTime3"] and tInfo["nBossTime3"] ~= 0 and tInfo["nBossTime3"] < nCurrentTime - REFRESH_COUNT then
                for i = 1, 3 do
                    tInfo["nLastBossTime"..i] = tInfo["nBossTime"..i]
                    tInfo["nBossTime"..i] = 0
                end
                tInfo.nCurrentBoss = 0
                tInfo.nOccupyCamp = 0
                tInfo.nRefreshTime = nCurrentTime
            end
            if tInfo.nCamp ~= nCamp and tInfo.nOccupyCamp == 0 or tInfo.nOccupyCamp == nCamp then
                table.insert(tTemp, tInfo)
            end
        end
        table.sort(tTemp, fnSort)

        for _, tInfo in ipairs(tTemp) do
            table.insert(tInfoList, tInfo)
        end
    end

    local nChildCount = UIHelper.GetChildrenCount(self.ScrollViewXXX) --TODO
    if bInit or #tInfoList ~= nChildCount then

        UIHelper.RemoveAllChildren(self.ScrollViewXXX) --TODO
        for i = 1, #tInfoList do
            --TODO AddPrefab
        end

        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewXXX)
    end

    -- 刷新保护期和拾取倒计时
    for i = 1, #tInfoList do
        local szServer = UIHelper.GBKToUTF8(tInfoList[i].szServer)
        --TODO BindUIEvent

        local tInfo = tCrossMsg[szServer]
        local tBossInfo = {}
        for j = 1, 3 do
            local szBoss = j .. "."
            if j <= tInfo.nCurrentBoss then
                szBoss = szBoss .. "本轮击退时间:"
                if tInfo["nBossTime"..j] > 0 then
                    szBoss = szBoss .. self:GetTimeString(tInfo["nBossTime"..j])
                else
                    szBoss = szBoss .. "未监控到"
                end
                local nLeft = 180 - (GetCurrentTime() - tInfo["nBossTime"..j])
                if nLeft > 0 then
                    szBoss = szBoss .. ", 拾取倒计时:" .. nLeft
                end
            else
                szBoss = szBoss .. "本轮未击退"
                if tInfo["nLastBossTime"..j] and tInfo["nLastBossTime"..j] > 0 then
                    local t = TimeToDate(tInfo["nLastBossTime"..j])
                    local szTime = FormatString("<D0>/<D1>/<D2> <D3>:<D4>:<D5>", t.hour, t.minute, t.second, t.year, t.month, t.day)
                    szBoss = szBoss .. ", 上轮击退时间:" .. szTime
                end
            end
            tBossInfo[j] = szBoss
        end
        local tData = self:GetServerDataByName(tInfoList[i].szServer)
        if tData then
            tData.tBossInfo = tBossInfo
        end

        local nLeftSec = tInfo.nPassTime
        if nLeftSec ~= 0 then
            nLeftSec = math.max(nLeftSec - nCurrentTime, 0)
        end
        local bSelfMap = false
        if MapHelper.IsRemotePvpMap() then -- 跨服-烂柯山/跨服-河西瀚漠
            local scene = player.GetScene()
            if scene and scene.nCopyIndex == tInfo.nCopyIndex then
                bSelfMap = true
            end
        end
        if bSelfMap then
            --hServer:SetFontColor(255, 255, 0)
        else
            --hServer:SetFontColor(255, 255, 255)
        end
        if tInfo.nCurrentBoss == 3 then
            nLeftSec = "已占领"
        elseif self:IsCeaseFireTime(tInfo.nPassTime) then
            nLeftSec = "停战期"
        elseif nLeftSec ~= 0 then
            nLeftSec = self:GetTimeString(nLeftSec)
        elseif tInfo.nCurrentBoss < 3 then
            nLeftSec = "争夺中"
        end
        --hProtect:SetText(nLeftSec)

        for i = 1, 3 do
            if i > tInfo.nCurrentBoss then
                UIHelper.SetProgressBarPercent(self.XXX, 100) --TODO
            else
                local nLeft = 180 - (nCurrentTime - tInfo["nBossTime"..i])
                local fP = math.max(0, nLeft / 180) * 100
                UIHelper.SetProgressBarPercent(self.XXX, fP) --TODO
            end
        end
    end
end

function UIPVPFieldView:GetTimeString(nTime)
    local nH, nM, nS = TimeLib.GetTimeToHourMinuteSecond(nTime)
    nH = nH < 10 and "0"..tostring(nH) or tostring(nH)
    nM = nM < 10 and "0"..tostring(nM) or tostring(nM)
    nS = nS < 10 and "0"..tostring(nS) or tostring(nS)
    return table.concat({nH, nM, nS}, ":")
end

function UIPVPFieldView:GetFormatTime(nTime)
	local t = TimeToDate(nTime)
    local nH, nM, nS = t.hour, t.minute, t.second
	nH = nH < 10 and "0"..tostring(nH) or tostring(nH)
    nM = nM < 10 and "0"..tostring(nM) or tostring(nM)
    nS = nS < 10 and "0"..tostring(nS) or tostring(nS)
    return table.concat({nH, nM, nS}, ":")
end

function UIPVPFieldView:GetServerDataByName(szServer) --GBK
    for _, tData in pairs(self.tServerList or {}) do
        if tData.szName == szServer then
            return tData
        end
    end
end

function UIPVPFieldView:GetServerMessage(szServerName) --GBK
    local tCrossMsg = PVPFieldData.GetCrossMsg()
    local tbCrossData = tCrossMsg[szServerName]
    local tbRes = {}
    for j = 1, 3 do
        local szBoss = j .. "."
        if j <= tbCrossData.nCurrentBoss then
            szBoss = szBoss .. "本轮击退时间:"
            if tbCrossData["nBossTime"..j] > 0 then
                szBoss = szBoss .. self:GetFormatTime(tbCrossData["nBossTime"..j])
            else
                szBoss = szBoss .. "未监控到"
            end
            local nLeft = 180 - (GetCurrentTime() - tbCrossData["nBossTime"..j])
            if nLeft > 0 then
                szBoss = "拾取倒计时:" .. nLeft
            end
        else
            szBoss = "本轮未击退"
            if tbCrossData["nLastBossTime"..j] and tbCrossData["nLastBossTime"..j] > 0 then
                local t = TimeToDate(tbCrossData["nLastBossTime"..j])
                local szTime = FormatString("<D0>:<D1>:<D2> <D3>/<D4>/<D5>", t.hour, t.minute, t.second, t.year, t.month, t.day)
                szBoss = "上轮击退时间:" .. szTime
            end
        end
        local szCamp = ""
        if tbCrossData.nCamp == CAMP.NEUTRAL then
            szCamp = "中立阵营"
        elseif tbCrossData.nCamp == CAMP.EVIL then
            szCamp = "归属恶人谷"
        elseif tbCrossData.nCamp == CAMP.GOOD then
            szCamp = "归属浩气盟"
        end
        local szText = szCamp.."\n"..szBoss
        table.insert(tbRes, szText)
    end
    return tbRes
end

function UIPVPFieldView:ClickBossPage()
    local bSelect = UIHelper.GetSelected(self.TogNavigation02)
    if bSelect then
        if DataModel.IsBossActivityOpened() then
            self:OnActivePage(PAGE.BOSS)
        else
            UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroupNavigation, self.TogNavigation01)
            -- TipsHelper.ShowNormalTip(g_tStrings.STR_SWITCH_SERVER_BOSS_TIME)
            TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips, self.TogNavigation02, TipsLayoutDir.TOP_CENTER, g_tStrings.STR_SWITCH_SERVER_BOSS_TIME)
        end
    end
end

return UIPVPFieldView
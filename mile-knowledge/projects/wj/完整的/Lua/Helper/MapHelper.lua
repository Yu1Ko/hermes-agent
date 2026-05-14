MapHelper = {}
local self = MapHelper

MAP_TYPE_STR = {
    ARENA               = "ARENA",              --竞技场
    BATTLE_FIELD        = "BATTLE_FIELD",       --战场
    BIRTH               = "BIRTH",              --出生点 稻香村
    CAMP                = "CAMP",
    CITY                = "CITY",
    DUNGEON             = "DUNGEON",            --副本（秘境）
    NORMAL              = "NORMAL",
    OLD_CITY            = "OLD_CITY",
    OLD_VILLAGE         = "OLD_VILLAGE",
    OTHER               = "OTHER",
    RAID                = "RAID",               --团战副本
    SCHOOL              = "SCHOOL",
    TEST                = "TEST",
    TONG                = "TONG",
    TONG_BATTLE_FIELD   = "TONG_BATTLE_FIELD",
}

BATTLE_FIELD_MAP_ID = {
	SHEN_NONG_YIN 			= 38, --神农洇
	JIU_GONG_QI_GU 			= 48, --九宫棋谷
	XI_FENG_GU_DAO 			= 50, --西风古道
	YUN_HU_TIAN_DI 			= 52, --云湖天地
	SAN_GUO_GU_ZHAN_CHANG 	= 135, --三国古战场
	FU_XIANG_QIU 			= 186, --浮香丘
	LONG_MEN_JUE_JING       = 296, --龙门绝境
	CANG_MING_JUE_JING      = 410, --沧溟绝境
	BAI_LONG_JUE_JING       = 512, --白龙绝境
	TIAN_YUAN_JUE_JING      = 532, --天原绝境
    XUE_YU_GUAN_CHENG       = 712, --雪域关城
    QING_XIAO_SHAN          = 790, --擎霄山
}

--跨服地图ID
REMOTE_PVP_MAP_ID_LKS = 627 --跨服-烂柯山
REMOTE_PVP_MAP_ID_HXHM = 697 --跨服-河西瀚漠

-- 中地图图标类型
local MIDDLE_MAP_ICON_TYPE =
{
    CRAFT = 1,
    TAG = 2,
    QUEST = 3,
    NPC_CATALOGUE = 4,
}

local tRemotePvpMap = { REMOTE_PVP_MAP_ID_LKS, REMOTE_PVP_MAP_ID_HXHM }

local MIDDLEMAP_INDEX_COUNT = 8

-- Def.lua:
-- BATTLEFIELD_MAP_TYPE =
-- {
-- 	BATTLEFIELD = 0,
-- 	TONGBATTLE = 1,
-- 	NEWCOMERBATTLE = 3,
-- 	TREASUREBATTLE = 4,
-- 	ZOMBIEBATTLE = 5,
-- 	MOBABATTLE = 6,
-- 	FBBATTLE = 7,
-- 	TONGWAR = 8,
-- 	PLEASANTGOAT = 9,
-- }

-- 地图白名单
local tMapWhiteList = nil



local m_dwMapID

local m_tbMapParams
local m_szMapTypeStr
local m_nBattleFieldType
local m_tWhiteMap = nil
local PEEK_EXPLORE_CD = 8   --取伊丽川远程数据块CD

MapHelper.MAX_TAG_COUNT = 10

local function CheckRemoteData(hPlayer, nDataID, nDataPos)
    if not hPlayer or not nDataID or (nDataID ~= -1 and not nDataPos) then
        return false
    end

    if nDataID == -1 then
        return true
    end
    return hPlayer.GetRemoteBitArray(nDataID, nDataPos)
end

function MapHelper.Init()
    self.RegEvent()

    self.tbMiddleMapInfo = {}
    self.tbMiddleMapArea = {}
    self.tbMiddleMapNpc = {}
    self.tbMiddleMapDoodad = {}
	self.tbMiddleMapCraftGuide = {}
    self.tbMiddleMapLoad = {}
    self.tbMapResourcePath = {}
    self.tbMainMap = {}
    self.tbMapExploreData = {}
    self.tbMapExploreTypeInfo = {}
    self.tbMapExploreReward = {}
    self._initWhiteMap()
    self._initMapResourcePath()
	self._initMapNewType()
end

function MapHelper.UnInit()
    Event.UnRegAll(self)
    Timer.DelAllTimer(self)

    m_dwMapID = nil
    m_tbMapParams = nil
    m_szMapTypeStr = nil
    m_nBattleFieldType = nil
end

function MapHelper.RegEvent()
    Event.Reg(self, "ON_FIELD_MARK_STATE_UPDATE", function(tFieldMark)
        if not g_pClientPlayer then
            return
        end

        local dwMapID = g_pClientPlayer.GetMapID()

        MapHelper.dwFieldMapID = dwMapID
        MapHelper.tFieldMark = tFieldMark
    end)

    -- 返回角色选择界面时清理活动符号数据
    Event.Reg(self, "PLAYER_LEAVE_GAME", function()
        MapHelper.dwActivitySymbolMapID = nil
        MapHelper.dwActivitySymbolSymbol = nil
        MapHelper.nLastSymbolTime = nil
    end)
end

-------------------------------- Public --------------------------------

function MapHelper.GetMapID()
	local player = GetClientPlayer()
	if player then
		return player.GetMapID()
	end
	return 0
end

function MapHelper.GetMapTypeStr(dwMapID)
    if dwMapID then
        return self._getMapTypeStr(dwMapID)
    end
    self._updateMapInfo()
    return m_szMapTypeStr
end

--[[
    return tbMapParams = {
        szDir                       = aMapParams[1],
        nType                       = aMapParams[2],
        nMaxPlayerCount             = aMapParams[3],
        nLimitTimes                 = aMapParams[4],
        nCampType                   = aMapParams[5],
        nMapCostVigor               = aMapParams[6],
        bManualReset                = aMapParams[7],
        bIsDungeonRoleProgressMap   = aMapParams[8],
        bCanSprint                  = aMapParams[9],
    }
--]]
function MapHelper.GetMapParams(dwMapID)
    if dwMapID then
        return self._getMapParams(dwMapID)
    end
    self._updateMapInfo()
    return m_tbMapParams
end

function MapHelper.IsRemotePvpMap(dwMapID)
    dwMapID = dwMapID or self.GetMapID()
    return table.contain_value(tRemotePvpMap, dwMapID)
end

function MapHelper.IsInBattleField(dwMapID)
    return self.GetBattleFieldType(dwMapID) ~= nil
end

-- return BATTLEFIELD_MAP_TYPE.XXX
function MapHelper.GetBattleFieldType(dwMapID)
    if dwMapID then
        return self._getBattleFieldType(dwMapID)
    end
    self._updateMapInfo()
    return m_nBattleFieldType
end

function MapHelper.GetMapMiddleMapIndex(dwMapID, nArea)
	MapHelper.InitMiddleMapInfo(dwMapID)
	if self.tbMiddleMapArea[dwMapID] and self.tbMiddleMapArea[dwMapID][nArea] then
		return self.tbMiddleMapArea[dwMapID][nArea].middlemap
	end
	return 0
end

function MapHelper.GetMapAreaBgMusic(dwMapID, nArea)
	MapHelper.InitMiddleMapInfo(dwMapID)
	if self.tbMiddleMapArea[dwMapID] and self.tbMiddleMapArea[dwMapID][nArea] then
		return self.tbMiddleMapArea[dwMapID][nArea].backgroundmusic
	end
	return ""
end

function MapHelper.GetMapAreaName(dwMapID, nArea)
	MapHelper.InitMiddleMapInfo(dwMapID)
	if self.tbMiddleMapArea[dwMapID] and self.tbMiddleMapArea[dwMapID][nArea] then
		return self.tbMiddleMapArea[dwMapID][nArea].name
	end
	return ""
end

local function ParsePosition(szPosition)
    local tPoint = {}
    for szX, szY, szZ in string.gmatch(szPosition, "([%d]+),([%d]+),([%d]+);?") do
        local nX = tonumber(szX)
        local nY = tonumber(szY)
        local nZ = tonumber(szZ)
        table.insert(tPoint, {nX, nY, nZ})
    end

    return tPoint
end

function MapHelper.InitMiddleMapInfo(nMapID)
    if nMapID and self.tbMiddleMapLoad[nMapID] then
        return self.tbMiddleMapInfo[nMapID], self.tbMiddleMapArea[nMapID], self.tbMiddleMapNpc[nMapID], self.tbMiddleMapCraftGuide[nMapID], self.tbMiddleMapDoodad[nMapID]
    end

    local dwMainMapID = MapHelper.GetMainMap(nMapID)
    if dwMainMapID and dwMainMapID ~= nMapID then
        MapHelper.InitMiddleMapInfo(dwMainMapID)
    end

    local szPath = MapMgr.GetMapParams_UIEx(nMapID)
    local ini = Ini.Open(szPath .. "minimap_mb\\config.ini")
    local tMapName = Table_GetMiddleMap(nMapID)

    local aInfo = {}
    local aNpc = {}
    local aArea = {}
    local aDoodad = {}

    if ini then
        for i = 0, MIDDLEMAP_INDEX_COUNT do
            local szSection = string.format("middlemap%d", i)
            if ini:IsSectionExist(szSection) then
                local t = {}
                t.name = GBKToUTF8(tMapName[i + 1])
				t.image = ini:ReadString(szSection, "image", "")
				t.width = ini:ReadInteger(szSection, "width", 1024)
				t.height = ini:ReadInteger(szSection, "height", 1024)
				t.scale = ini:ReadFloat(szSection, "scale", 0.001)
				t.startx = ini:ReadFloat(szSection, "startx", 0)
				t.starty = ini:ReadFloat(szSection, "starty", 0)
				t.showleftx = ini:ReadFloat(szSection, "showleftx", 0)
				t.showlefty = ini:ReadFloat(szSection, "showlefty", 0)
				t.showrightx = ini:ReadFloat(szSection, "showrightx", 0)
				t.showrighty = ini:ReadFloat(szSection, "showrighty", 0)
				t.activityId = ini:ReadInteger(szSection, "activityId", 0)
                t.color = ini:ReadString(szSection, "color", "")
				aInfo[i] = t
            end
        end
    end

    local tAreaTitle =
	{
		{f="i", t="id"},
		{f="s", t="name"},
		{f="i", t="middlemap"},
		{f="p", t="backgroundmusic"},
		{f="i", t="type"},
		{f="i", t="x"},
		{f="i", t="y"},
		{f="i", t="z"},
		{f="i", t="show"},
		{f="i", t="fullscreensfx"},
	}
	local tArea = KG_Table.Load(szPath.."minimap_mb\\area.tab", tAreaTitle, 0)
	if tArea then
		local t = {}
		local nRowCount = tArea:GetRowCount()
		for nRow = 2, nRowCount do
			local tRow = tArea:GetRow(nRow)

			local id = tRow.id
			local szName = tRow.name
			local nMiddlemap = tRow.middlemap
			local szBackgroundmusic = tRow.backgroundmusic
			local nType = tRow.type
			local nX = tRow.x
			local nY = tRow.y
			local nZ = tRow.z
			local nShow = tRow.show
			local nFullscreensfx = tRow.fullscreensfx
			t[id] = {name = szName, middlemap = nMiddlemap, backgroundmusic = szBackgroundmusic, type = nType, x = nX, y = nY, z = nZ, bShow = not nShow or nShow ~= 0, fullscreensfx = nFullscreensfx}
		end
		aArea = t
		tArea = nil
	else
		local tabR = Tab.Open(szPath.."minimap_mb\\area.tab")
		if tabR then
			local t = {}
			local nRow = tabR:GetHeight()
			for i = 2, nRow, 1 do
				local id = tabR:GetInteger(i, "id", 0)
				local szName = tabR:GetString(i, "name", "")
				local nMiddlemap = tabR:GetInteger(i, "middlemap", 0)
				local szBackgroundmusic = tabR:GetString(i, "backgroundmusic", "")
				local nType = tabR:GetInteger(i, "type", 0)
				local nX = tabR:GetInteger(i, "x", 0)
				local nY = tabR:GetInteger(i, "y", 0)
				local nZ = tabR:GetInteger(i, "z", 0)
				local nShow = tabR:GetInteger(i, "show", 1)
			    local nFullscreensfx = tabR:GetInteger(i, "fullscreensfx", 0)
				nX = nX or 0
				nY = nY or 0
				t[id] = {name = szName, middlemap = nMiddlemap, backgroundmusic = szBackgroundmusic, type = nType, x = nX, y = nY, z = nZ, bShow = not nShow or nShow ~= 0, fullscreensfx = nFullscreensfx}
			end
			aArea = t
			tabR:Close()
		end
	end

    local tNpcTitle =
	{
		{f="i", t="id"},
        {f="i", t="npcid"},
		{f="i", t="middlemap"},
		{f="s", t="kind"},
		{f="i", t="type"},
		{f="s", t="position"},
		{f="i", t="defaultcheck"},
		{f="i", t="npctype"},
		{f="i", t="activityid"},
		{f="i", t="opactivityid"},
		{f="s", t="newordername"},
	}
	local tNpc = KG_Table.Load(szPath .. "minimap_mb\\npc.tab", tNpcTitle, 0--[[FILE_OPEN_MODE.NORMAL]])
	if tNpc then
		local t = {}
		local nRowCount = tNpc:GetRowCount()
        local tIDMap = {}
		for nRow = 2, nRowCount do
			local tRow = tNpc:GetRow(nRow)

			local nID = tRow.id
            local nNpcID = tRow.npcid
			local nMiddlemap = tRow.middlemap
			local szKind = GBKToUTF8(tRow.kind)
			local nType = tRow.type
            local tPoint = ParsePosition(tRow.position)
			local bDefaultCheck = tRow.defaultcheck and tRow.defaultcheck ~= 0
			local nNpcType = tRow.npctype
			local dwActivityID = tRow.activityid
			local szOrderName = GBKToUTF8(tRow.newordername)
			--活动开启时，该配置项不显示
			local dwNotDisplayActivityID = tRow.opactivityid
            if nNpcID == 0 then
                table.insert(t, {id = nID, middlemap = nMiddlemap, type = nType, kind = szKind, defaultcheck = bDefaultCheck, group ={ }, dwActivityID = dwActivityID, dwNotDisplayActivityID = dwNotDisplayActivityID})
                tIDMap[nID] = #t
            else
                local nIndex = tIDMap[nID]
                local tNpcGroup = t[nIndex].group
                table.insert(tNpcGroup, {
					nNpcID = nNpcID, tPoint = tPoint, nNpcType = nNpcType, szKind = szKind, dwActivityID = dwActivityID,
					dwNotDisplayActivityID = dwNotDisplayActivityID, szOrderName = szOrderName
				})
            end
		end
		aNpc = t
		tNpc = nil
	else
		local tabR = Tab.Open(szPath .. "minimap_mb\\npc.tab")
		if tabR then
			local t = {}
            local tIDMap = {}
			local nRow = tabR:GetHeight()
			for i = 3, nRow, 1 do
				local nID = tabR:GetInteger(i, "id", 0)
                local nNpcID = tabR:GetInteger(i, "npcid", 0)
				local nMiddlemap = tabR:GetInteger(i, "middlemap", 0)
				local nType = tabR:GetInteger(i, "type", 0)
				local szKind = GBKToUTF8(tabR:GetString(i, "kind", ""))
                local szPosition = tabR:GetString(i, "position", "")
                local tPoint = ParsePosition(szPosition)
				local nDefaultCheck = tabR:GetInteger(i, "defaultcheck", 0)
				local bDefaultCheck = nDefaultCheck and nDefaultCheck ~= 0
				local nNpcType = tabR:GetInteger(i, "npctype", 0)
				local nActivityID = tabR:GetInteger(i, "activityid", 0)
                if nNpcID == 0 then
                    table.insert(t, {id = nID, middlemap = nMiddlemap, type = nType, kind = szKind, defaultcheck = bDefaultCheck, group={}})
                    tIDMap[nID] = #t
                else
                    local nIndex = tIDMap[nID]
                    local tNpcGroup = t[nIndex].group
                    table.insert(tNpcGroup, {nNpcId = nNpcID, tPoint = tPoint, nNpcType = nNpcType, szKind = szKind})
                end
			end
			aNpc = t
			tabR:Close()
		end
	end

    local tDoodadTitle =
    {
		{f="i", t="id"},
		{f="i", t="doodadid"},
		{f="i", t="middlemap"},
		{f="s", t="kind"},
		{f="i", t="type"},
		{f="s", t="position"},
		{f="i", t="defaultcheck"},
		{f="i", t="doodadtype"},
    }

	local szFile = szPath .. "minimap_mb\\doodad.tab"
	local tDoodad = KG_Table.Load(szFile, tDoodadTitle, 0)
    local tIDMap = {}
	if tDoodad then
        local t = {}
		local nRowCount = tDoodad:GetRowCount()
		for nRow = 2, nRowCount do
			local tRow = tDoodad:GetRow(nRow)
			local nID = tRow.id
			local nDoodadID = tRow.doodadid
			local nMiddlemap = tRow.middlemap
			local szKind = GBKToUTF8(tRow.kind)
			local nType = tRow.type
			local tPoint = ParsePosition(tRow.position)
			local bDefaultCheck = tRow.defaultcheck and tRow.defaultcheck ~= 0
			local nDoodadType = tRow.doodadtype
			if nDoodadID == 0 then
				table.insert(t, {id = nID, middlemap = nMiddlemap, type = nType, kind = szKind, defaultcheck = bDefaultCheck, group ={ }})
				tIDMap[nID] = #t
			else
				local nIndex = tIDMap[nID]
				local tDoodadGroup = t[nIndex].group
				if nDoodadType ~= 2 then
					table.insert(tDoodadGroup, {id = nID, nDoodadID = nDoodadID, tPoint = tPoint, nDoodadType = nDoodadType, szKind = szKind})
				end
			end
		end
		aDoodad = t
		tDoodad = nil
    else
        local tabR = Tab.Open(szFile)
		if tabR then
			local t = {}
			local nRow = tabR:GetHeight()
			for i = 2, nRow, 1 do
				-- local tRow = tDoodad:GetRow(nRow)
                local nID = tabR:GetInteger(i, "id", 0)
                local nDoodadID = tabR:GetInteger(i, "doodadid", 0)
                local nMiddlemap = tabR:GetInteger(i, "middlemap", 0)
                local szKind = GBKToUTF8(tabR:GetString(i, "kind", ""))
                local nType = tabR:GetInteger(i, "type", 0)
                local szPosition = tabR:GetString(i, "position", "")
                local tPoint = ParsePosition(szPosition)
                local nDefaultCheck = tabR:GetInteger(i, "defaultcheck", 0)
                local bDefaultCheck = nDefaultCheck and nDefaultCheck ~= 0
                local nDoodadType = tabR:GetInteger(i, "doodadtype", 0)
                if nDoodadID == 0 then
                    table.insert(t, {id = nID, middlemap = nMiddlemap, type = nType, kind = szKind, defaultcheck = bDefaultCheck, group ={ }})
                    tIDMap[nID] = #t
                else
                    local nIndex = tIDMap[nID]
                    local tDoodadGroup = t[nIndex].group
                    if nDoodadType ~= 2 then
                        table.insert(tDoodadGroup, {id = nID, nDoodadID = nDoodadID, tPoint = tPoint, nDoodadType = nDoodadType, szKind = szKind})
                    end
                end
			end
			aDoodad = t
			tabR:Close()
		end
    end

    self.tbMiddleMapInfo[nMapID] = aInfo
    self.tbMiddleMapArea[nMapID] = aArea
    self.tbMiddleMapNpc[nMapID] = aNpc
    self.tbMiddleMapDoodad[nMapID] = aDoodad
    self.tbMiddleMapLoad[nMapID] = true
	self.tbMiddleMapCraftGuide[nMapID] = CraftData.Craft_GetGuidePosList(nMapID, 0) or {}


	return self.tbMiddleMapInfo[nMapID], self.tbMiddleMapArea[nMapID], self.tbMiddleMapNpc[nMapID], self.tbMiddleMapCraftGuide[nMapID], self.tbMiddleMapDoodad[nMapID]
end

function MapHelper.InitTrafficInfo(nMapID, nTrafficID)
    local player = GetClientPlayer()
    if not player then
        return
    end
    local szPath, nMapType = MapMgr.GetMapParams_UIEx(nMapID)
    local tTrafficNodeTitle =
    {
        {f="i", t="dwTrafficID"},
        {f="s", t="szName"},
        {f="i", t="nX"},
        {f="i", t="nY"},
        {f="i", t="nZ"},
        {f="i", t="nType"},
        {f="i", t="dwCityID"}
    }
    local tTrafficNodeFile = KG_Table.Load(szPath .. "minimap_mb\\trafficnode.tab", tTrafficNodeTitle, 0)
    if not tTrafficNodeFile then
        return
    end
    local tTransferNode = {}
    local nCount = tTrafficNodeFile:GetRowCount()
    for i = 2, nCount do
        local tNode = clone(tTrafficNodeFile:GetRow(i))
        tNode.szName = GBKToUTF8(tNode.szName)
        table.insert(tTransferNode, tNode)
    end

    local tTrafficLineTitle =
    {
        {f="i", t="dwTrafficID1"},
        {f="i", t="dwTrafficID2"},
        {f="i", t="dwNodeID"},
        {f="i", t="dwCityID"},
        {f="i", t="nCamp"},
    }
    local tTrafficNode = {}
    local tTrafficLineFile = KG_Table.Load(szPath .. "minimap_mb\\trafficline.tab", tTrafficLineTitle, 0)
    if nTrafficID and tTrafficLineFile then
        local nCount = tTrafficNodeFile:GetRowCount()
        for i = 2, nCount do
            local tNode = clone(tTrafficNodeFile:GetRow(i))
            tNode.szName = GBKToUTF8(tNode.szName)
            tNode.bDisable = false
            if tNode.dwTrafficID ~= nTrafficID then
                local tLine = tTrafficLineFile:Search(nTrafficID, tNode.dwTrafficID)
                if not tLine then
                    tNode.bDisable = true
                else
                    if tLine.nCamp ~= CAMP.NEUTRAL and player.nCamp ~= tLine.nCamp then
                        tNode.bDisable = true
                    end
                    tNode.dwNodeID = tLine.dwNodeID
                    tNode.dwCityID = tLine.dwCityID
                end
            end
            table.insert(tTrafficNode, tNode)
        end
    end

    return tTransferNode, tTrafficNode
end

--野外/主城/门派/秘境/其它
function MapHelper.GetMapNewType(dwMapID)
	if self.tbMapNewType[dwMapID] then
		return self.tbMapNewType[dwMapID]
	end
	return "其它"
end

function MapHelper.IsMapOpen(nMapID)
    local bResult = true

    if m_tWhiteMap ~= nil and not table.is_empty(m_tWhiteMap) then
        bResult = m_tWhiteMap[nMapID]
    end

    return bResult
end

function MapHelper.IsMapSwitchServer(nMapID)
    if not self.tbSwitchServerMap then
        self.tbSwitchServerMap = {}
        local tbSwitchServer = Table_GetAllSwitchServerFieldInfo()
        for _, tLine in ipairs(tbSwitchServer) do
            self.tbSwitchServerMap[tLine.dwMapID] = true
        end
    end
    return self.tbSwitchServerMap[nMapID] == true
end

-------------------------------- Private --------------------------------

function MapHelper._initMapNewType()
	self.tbMapNewType = {}

	for i, tLine in ipairs(UIWorldMapCityTab) do
        self.tbMapNewType[tLine.nMapID] = tLine.szType
    end

    for i, tLine in ipairs(UIWorldMapCopyTab) do
		self.tbMapNewType[tLine.nMapID] = "秘境"
    end
end

function MapHelper._initWhiteMap()
    if not tMapWhiteList or table.is_empty(tMapWhiteList) then
        return
    end

    m_tWhiteMap = {}
    for _, nMapID in ipairs(tMapWhiteList) do
        m_tWhiteMap[nMapID] = true
    end
end

function MapHelper._InitExtraWhiteMap()
    if not tMapWhiteList or table.is_empty(tMapWhiteList) or not m_tWhiteMap then
        return
    end

    --若有多张地图使用同样的资源，则将这些资源对应的地图ID也纳入白名单

    local tPakCheckList = {}
    for nPackID, tInfo in pairs(PakDownloadMgr.GetPakInfoList() or {}) do
        if tInfo.tPakList and tInfo.tPakList[1] ~= nPackID and PakDownloadMgr.IsMapRes(nPackID) then
            tPakCheckList[nPackID] = tInfo.tPakList[1]
        end
    end

    for _, nMapID in ipairs(tMapWhiteList) do

        local function _addWhiteMap(nPackID)
            local nExtraMapID = nPackID - 800000
            if not m_tWhiteMap[nExtraMapID] then
                m_tWhiteMap[nExtraMapID] = true
                print("[PakDownloadMgr] AddExtraWhiteMapID", nMapID, nExtraMapID)
            end
        end

        --策划需求 重复资源地图 额外添加白名单
        local nPackID = PakDownloadMgr.GetMapResPackID(nMapID)
        local nPakGroupID = tPakCheckList[nPackID]
        if nPakGroupID and nPackID ~= nPakGroupID then
            _addWhiteMap(nPakGroupID)
        end

        for nCurPackID, nPakGroupID in pairs(tPakCheckList) do
            if nPakGroupID == nPackID then
                _addWhiteMap(nCurPackID)
            end
        end
    end
end

function MapHelper._initMapResourcePath()
    self.tbMapResourcePath = {}
    local nCount = g_tTable.MapList:GetRowCount()
    for i = 2, nCount do
        local tLine = g_tTable.MapList:GetRow(i)
        local dwMapID = tLine.nID
        local szDir = dwMapID and select(1, GetMapParams(dwMapID))
        if szDir then
            szDir = string.gsub(szDir, "/", "\\")
            if not self.tbMapResourcePath[szDir] then
                self.tbMapResourcePath[szDir] = dwMapID
            end
        end
    end
end

function MapHelper.GetMapIDByResourcePath(szDir)
    if not szDir then
        return
    end

    szDir = string.gsub(szDir, "/", "\\")
    return self.tbMapResourcePath and self.tbMapResourcePath[szDir]
end

--根据家园地图ID和皮肤ID，通过对比使用的资源路径，返回所用资源的地图ID，用于下载
function MapHelper.GetHomelandSkinResMapID(dwMapID, dwSkinID)
    local hHomeland = GetHomelandMgr()
    if not hHomeland then
        return
    end

    if not dwMapID or not dwSkinID then
        return
    end

    if dwSkinID <= 0 then
        return
    end

    local uMapSkinID = hHomeland.GetMapSkinID(dwMapID, dwSkinID)
    local tSkinConfig = hHomeland.GetPrivateHomeSkinConfig(uMapSkinID)
    if not tSkinConfig then
        return
    end

    return self.GetMapIDByResourcePath(tSkinConfig.szResourceDir)
end

local tApplyRemoteData = {}
--获取地图探索状态
function MapHelper.GetMapExploreState(tInfo)
    if not tInfo then
        return MAP_EXPLORE_STATE.NOT_EXPLORE
    end

    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return MAP_EXPLORE_STATE.NOT_EXPLORE
    end

    local tUnlockData = SplitString(tInfo.szUnlockData, "_")
    local tFinishData = SplitString(tInfo.szFinishData, "_")
    local tRewardData = SplitString(tInfo.szRewardData, "_")
    local nUnlockID, nUnlockPos = tonumber(tUnlockData[1]), tonumber(tUnlockData[2])
    local nFinishID, nFinishPos = tonumber(tFinishData[1]), tonumber(tFinishData[2])
    local nRewardID, nRewardPos = tonumber(tRewardData[1]), tonumber(tRewardData[2])
    local nCurTime = GetCurrentTime()
    local t = {nUnlockID, nFinishID, nRewardID}

    for _,v in pairs(t) do
        if v and v ~= -1 and not hPlayer.HaveRemoteData(v) then
            if not tApplyRemoteData[v] or nCurTime - tApplyRemoteData[v] >= PEEK_EXPLORE_CD then
                tApplyRemoteData[v] = nCurTime
                hPlayer.ApplyRemoteData(v)
            end
            return MAP_EXPLORE_STATE.NOT_EXPLORE
        end
    end

    if CheckRemoteData(hPlayer, nRewardID, nRewardPos) then
        return MAP_EXPLORE_STATE.REWARD
    elseif CheckRemoteData(hPlayer, nFinishID, nFinishPos) then
        return MAP_EXPLORE_STATE.FINISH
    elseif CheckRemoteData(hPlayer, nUnlockID, nUnlockPos) then
        return MAP_EXPLORE_STATE.EXPLORE
    else
        return MAP_EXPLORE_STATE.NOT_EXPLORE
    end
end

function MapHelper.GetMapExploreInfo(dwMapID)
    if not dwMapID then
        return {}
    end

    if not self.tbMapExploreData[dwMapID] then
        self.tbMapExploreData[dwMapID] = Table_GetMapExploreInfo(dwMapID)
    end

    local tRes = {}
    for _,v in pairs(self.tbMapExploreData[dwMapID]) do
        local nState = MapHelper.GetMapExploreState(v)
        if not tRes[v.nType] then
            tRes[v.nType] = {}
        end

        if not tRes[v.nType][v.nSubType] then
            tRes[v.nType][v.nSubType] = {}
        end
        v.nState = nState
        table.insert(tRes[v.nType][v.nSubType], v)
    end
    return tRes
end

function MapHelper.GetMapExploreTypeInfo(nType)
    if not self.tbMapExploreTypeInfo or IsTableEmpty(self.tbMapExploreTypeInfo) then
        self.tbMapExploreTypeInfo = Table_GetAllMapExploreType()
    end
    return self.tbMapExploreTypeInfo[nType]
end

function MapHelper.GetMapExploreReward(dwMapID, nType)
    if not dwMapID or not nType then
        return {}
    end
    if not self.tbMapExploreReward[dwMapID] then
        self.tbMapExploreReward[dwMapID] = Table_GetMapExploreReward(dwMapID)
    end
    return self.tbMapExploreReward[dwMapID][nType] or {}
end

--获取主地图MapID
function MapHelper.GetMainMap(dwMapID)
    if not dwMapID or dwMapID == 0 then
        return dwMapID
    end
    if self.tbMainMap[dwMapID] then
        return self.tbMainMap[dwMapID]
    end
    local dwMainMapID = GetMainMapID(dwMapID)
    if dwMainMapID ~= 0 then
        self.tbMainMap[dwMapID] = dwMainMapID
        return dwMainMapID
    end
    self.tbMainMap[dwMapID] = dwMapID
    return dwMapID
end

function MapHelper._updateMapInfo()
    local dwMapID = self.GetMapID()

    if dwMapID == m_dwMapID then
        return
    end
    m_dwMapID = dwMapID

    m_tbMapParams = self._getMapParams(dwMapID)
    m_szMapTypeStr = self._getMapTypeStr(dwMapID)
    m_nBattleFieldType = self._getBattleFieldType(dwMapID)
end

function MapHelper._getBattleFieldType(dwMapID)
	local dwMapID = BattleFieldData.GetBattleFieldFatherID(dwMapID)
	if not dwMapID then
		return
	end
    local tbBFMap = g_tTable.BattleField:Search(dwMapID)
    return tbBFMap and tbBFMap.nType
end

function MapHelper._getMapTypeStr(dwMapID)
    local tbMap = g_tTable.MapList:Search(dwMapID)
    return tbMap and tbMap.szType
end

function MapHelper._getMapParams(dwMapID)
    local aMapParams = {GetMapParams(dwMapID)}
    local tbMapParams = {
        szDir                       = aMapParams[1],
        nType                       = aMapParams[2],
        nMaxPlayerCount             = aMapParams[3],
        nLimitTimes                 = aMapParams[4],
        nCampType                   = aMapParams[5],
        nMapCostVigor               = aMapParams[6],
        bManualReset                = aMapParams[7],
        bIsDungeonRoleProgressMap   = aMapParams[8],
        bCanSprint                  = aMapParams[9],
    }
    return tbMapParams
end







function MapHelper.GetMiddleMapCraftIconTab(nIconID)
    local tbCraftIconTab = UIMiddleMapIconTab[MIDDLE_MAP_ICON_TYPE.CRAFT][nIconID]
    return tbCraftIconTab
end

function MapHelper.GetMiddleMapTagIconTab(nIconID)
    local tbTagIconTab = UIMiddleMapIconTab[MIDDLE_MAP_ICON_TYPE.TAG][nIconID]
    return tbTagIconTab
end

function MapHelper.GetMiddleMapQuestIconTab(nQuestType, nQuestState)
    local tbQuestIconTabList = UIMiddleMapIconTab[MIDDLE_MAP_ICON_TYPE.QUEST]
    for k, v in ipairs(tbQuestIconTabList) do
        if v.nQuestType == nQuestType and v.nQuestState == nQuestState then
            return v
        end
    end

    return nil
end

function MapHelper.GetMiddleMapNpcCatalogueIconTab(nIconID)
    local tbNpcCatalogueIconTab = UIMiddleMapIconTab[MIDDLE_MAP_ICON_TYPE.NPC_CATALOGUE][nIconID]
    return tbNpcCatalogueIconTab
end
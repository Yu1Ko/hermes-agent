CharacterIdleActionData = CharacterIdleActionData or {className = "CharacterIdleActionData"}

local self = CharacterIdleActionData

local szPreviewImgPath = "mui/Resource/item_pic/IdleAction_%s_%s.png"

local tDefaultAni = {
    [PLAYER_IDLE_ACTION_DISPLAY_TYPE.SCENE]     = "StandardNew",
    [PLAYER_IDLE_ACTION_DISPLAY_TYPE.LOGIN]     = "Standard",
    [PLAYER_IDLE_ACTION_DISPLAY_TYPE.C_PANEL]   = "Idle",
    [PLAYER_IDLE_ACTION_DISPLAY_TYPE.COIN_SHOP] = "StandardNew",
}

local tIdleActionType = {
	[0] = {szType = "MainScene", szName = "主场景", szIcon = "UIAtlas2_Character_Accessory_Img_Footprint.png", szIcon2 = "UIAtlas2_Character_Accessory_Img_Pose_T.png"},
	[1] = {szType = "RoleSelection", szName = "角色选择", szIcon = "UIAtlas2_Character_Accessory_Img_AroundBody.png", szIcon2 = "UIAtlas2_Character_Accessory_Img_Pose_T.png"},
	[2] = {szType = "RoleMain", szName = "角色面板", szIcon = "UIAtlas2_Character_Accessory_Img_HandLeft.png", szIcon2 = "UIAtlas2_Character_Accessory_Img_Pose_T.png"},
    [3] = {szType = "Shopping", szName = "商城", szIcon = "UIAtlas2_Character_Accessory_Img_HandRight.png", szIcon2 = "UIAtlas2_Character_Accessory_Img_Pose_T.png",},
}

local tbIdleActionTypeToIndex =
{
    ["MainScene"] = 0,
    ["RoleSelection"] = 1,
    ["RoleMain"] = 2,
    ["Shopping"] = 3,
}

local tBodyTypeMap = {  --根据玩家体型快速生成路径
	[1]  = "M2",
	[2]  = "F2",
	[3]  = "M3",
	[4]  = "F3",
	[5]  = "M1",
	[6]  = "F1",
}

local IDLE_PAGE_SIZE = 12
local IDLE_STAR_LIMIT = 20
local REMOTE_PREFER_ROLEAVATAR  = 1171 --收藏远程数据块
local EACH_PAGE_MAX_COUNT 		= 9
local PREFER_REMOTE_DATA_START 	= 0
local PREFER_REMOTE_DATA_END 	= 3
local PREFER_REMOTE_DATA_LEN 	= 1

function CharacterIdleActionData.GetDefaultAni(nType)
    return tDefaultAni[nType]
end

local tView =
{
	EQUIPMENT_REPRESENT.FACE_STYLE,
    EQUIPMENT_REPRESENT.HAIR_STYLE,
}

--逻辑上的0表示没有设置，UI加的一个默认
local tDefault = {
	dwID 			= 0,
	bHave 			= true,
	szActionName 	= UIHelper.UTF8ToGBK(g_tStrings.STR_PLAYER_IDLE_ACTION_DEFAULT),
	bShowOnlyHave  	= false,
}

Event.Reg(self, "ON_CHANGE_PLAYER_IDLE_ACTION_NOTIFY", function()
	if arg1 == PLAYER_IDLE_ACTION_METHOD.ADD then
        local dwID = arg0
		RedpointHelper.IdleAction_SetNew(dwID, true)
	end
end)

function CharacterIdleActionData.Init(nType)
	local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    self.nIdleActionPage 		= 1
	self.nType 					= nType or PLAYER_IDLE_ACTION_DISPLAY_TYPE.SCENE
	self.nRoleType 				= hPlayer.nRoleType
	self.UpdateCollectionData()
	self.SortIdleAction(true)
	self.FilterList()

    -- MiniScene相关
	-- CharacterIdleActionData.GetRepresent(hPlayer)
	-- CharacterIdleActionData.GetCameraData()
end

function CharacterIdleActionData.UnInit()
    self.nIdleActionPage 		= nil
	self.tCollection 			= nil
	self.nType 					= nil
	self.bEnableCollect 		= nil
	self.nRoleType 				= nil
	self.aCameraData			= nil
	self.aRepresent            	= nil
	self.tOriginalList			= nil
	self.tGainWayMenu			= nil
	self.nActionCount 			= nil
	self.tIdleActionList 		= nil
	self.tFilterIdleActionList 	= nil
	self.nFilterActionCount 	= nil
	self.nFilterHave 			= nil
	self.nFilterGainWay 		= nil
	self.nSearch				= nil
	self.szSearchText			= nil
end

function CharacterIdleActionData.GetRepresent(hPlayer)
    self.aRepresent            	= {}
	local tRepresentID 					= hPlayer.GetRepresentID()
    for i = 0, EQUIPMENT_REPRESENT.TOTAL do
        self.aRepresent[i] = 0
    end
	for _, nRepresentSub in ipairs(tView) do
        self.aRepresent[nRepresentSub] = tRepresentID[nRepresentSub]
    end
    local bUseLiftedFace                = hPlayer.bEquipLiftedFace
    local tFaceData                     = hPlayer.GetEquipLiftedFaceData()
    self.aRepresent.bUseLiftedFace = bUseLiftedFace
    self.aRepresent.tFaceData      = tFaceData
end

function CharacterIdleActionData.GetCameraData()
	if self.aCameraData then
		return self.aCameraData
	end
	local tEnv = {}
	LoadScriptFile("ui/string/roleviewdata.lua", tEnv)
	self.aCameraData = tEnv.g_tRolePostureView
end

function CharacterIdleActionData.InitGainWayMenu()
	local tSearchList = {}
	for _, tInfo in ipairs(self.tOriginalList) do
		local dwItemType = tInfo.dwItemType
		local dwItemIndex = tInfo.dwItemID
		if dwItemType and dwItemType ~= 0 and dwItemIndex and dwItemIndex ~= 0 then
			local tSearchIndex = ItemSource_GetSearchIndexList(dwItemType, dwItemIndex)
			for nIndex, _ in pairs(tSearchIndex) do
				if not tSearchList[nIndex] then
					tSearchList[nIndex] = true
				end
			end
		end
	end

	local tGainWayMenu = {}
	for nIndex, _ in pairs(tSearchList) do
		table.insert(tGainWayMenu, nIndex)
	end
	table.sort(tGainWayMenu)
	self.tGainWayMenu = tGainWayMenu
end

function CharacterIdleActionData.GetAllIdleAction(bRefresh)
	local hPlayer = GetClientPlayer()
	if not hPlayer then
		return
	end
	if self.tOriginalList and (not bRefresh) then
		return self.tOriginalList
	end
	local tRes 			= {}
	local nRow 			= g_tTable.IdleAction:GetRowCount()
	for i = 2, nRow do
		local tLine 	= clone(g_tTable.IdleAction:GetRow(i))
		if tLine then
			local bHave = hPlayer.IsHaveIdleAction(tLine.dwID)
			if (not tLine.bShowOnlyHave) or (tLine.bShowOnlyHave and bHave) then
				tLine.bHave = bHave
				table.insert(tRes, tLine)
			end
		end
	end
	self.tOriginalList 	= tRes
	self.InitGainWayMenu()
	return tRes
end

function CharacterIdleActionData.UpdateCollectionData()
	self.bEnableCollect = false
	local pPlayer = GetClientPlayer()
	if not pPlayer then
		return
	end

	local dwPlayerID = pPlayer.dwID
	if IsRemotePlayer(dwPlayerID) then
		self.tCollection 		= {}
		self.bEnableCollect 	= true
		return
	end

	if not pPlayer.HaveRemoteData(REMOTE_PREFER_ROLEAVATAR) then
		pPlayer.ApplyRemoteData(REMOTE_PREFER_ROLEAVATAR)
		return
	end

	local tCollection = {}
	for i = PREFER_REMOTE_DATA_START, PREFER_REMOTE_DATA_END, PREFER_REMOTE_DATA_LEN do
		local dwActionID = pPlayer.GetRemoteArrayUInt(REMOTE_PREFER_ROLEAVATAR, i, PREFER_REMOTE_DATA_LEN)
		if dwActionID and dwActionID ~= 0 then
			tCollection[dwActionID] = true
		end
	end
	self.tCollection 	= tCollection
	self.bEnableCollect 	= true
end

function CharacterIdleActionData.SortIdleAction(bRefresh)
	if not self.bEnableCollect then
		return
	end
	local function fnDegree(a, b)
		if self.tCollection[a.dwID] == self.tCollection[b.dwID] then
			if a.bHave == b.bHave then
				return a.dwID > b.dwID
			elseif a.bHave then
				return true
			else
				return false
			end
		elseif self.tCollection[a.dwID] then
			return true
		else
			return false
		end
	end

	local tRes 					= clone(self.GetAllIdleAction(bRefresh))
	table.sort(tRes, fnDegree)
	-- local tDefault 				= self.GetDefaultInfo()
	-- table.insert(tRes, 1, tDefault)
	self.nActionCount 		= #tRes
	self.tIdleActionList 	= tRes
end

function CharacterIdleActionData.UpdateIdleAction(dwID)
	local hPlayer = GetClientPlayer()
	if not hPlayer then
		return
	end
	for k, v in pairs(self.tOriginalList) do
		if v.dwID == dwID then
			local bHave = hPlayer.IsHaveIdleAction(dwID)
			v.bHave = bHave
			return
		end
	end
end

function CharacterIdleActionData.IsFilteredGainWay(tInfo)
	local dwItemType 		= tInfo.dwItemType
	local dwItemIndex 		= tInfo.dwItemID
	local nFilterGainWay 	= self.nFilterGainWay
	if dwItemType and dwItemType ~= 0 and dwItemIndex and dwItemIndex ~= 0 then
		local tSearchIndex = ItemSource_GetSearchIndexList(dwItemType, dwItemIndex)
		if tSearchIndex and tSearchIndex[nFilterGainWay] then
			return true
		end
	end
	return false
end

function CharacterIdleActionData.FilterList()
	if not self.bEnableCollect then
		return
	end
	local tHaveList = {}
	if (not self.nFilterHave) or (self.nFilterHave == 0) then
		tHaveList = self.tIdleActionList
	else
		for k, v in ipairs(self.tIdleActionList) do
			if (self.nFilterHave == 1 and v.bHave) or (self.nFilterHave == 2 and not v.bHave) then
				table.insert(tHaveList, v)
			end
		end
	end

	local tGainWayList = {}
	if (not self.nFilterGainWay) or (self.nFilterGainWay == 0) then
		tGainWayList = tHaveList
	else
		for k, v in ipairs(tHaveList) do
			if self.IsFilteredGainWay(v) then
				table.insert(tGainWayList, v)
			end
		end
	end

	local tSearchList = {}
	if (not self.szSearchText) or (self.szSearchText == "") then
		tSearchList = tGainWayList
	else
		for k, v in ipairs(tGainWayList) do
			if string.find(v.szActionName, UIHelper.UTF8ToGBK(self.szSearchText)) then
				table.insert(tSearchList, v)
			end
		end
	end
	self.tFilterIdleActionList = tSearchList
	self.nFilterActionCount = #self.tFilterIdleActionList
end

function CharacterIdleActionData.GetIdleActionList()
    local tbRes = {}
	local nStart = (self.nIdleActionPage - 1) * EACH_PAGE_MAX_COUNT + 1
	for i = 0, EACH_PAGE_MAX_COUNT - 1, 1 do
        local nIndex = nStart + i
        local tbInfo = self.tFilterIdleActionList and self.tFilterIdleActionList[nIndex]
        if tbInfo then
			if self.tCollection and self.tCollection[tbInfo.dwID] then
				tbInfo.bCollect = true
			end
            table.insert(tbRes, tbInfo)
        end
    end

    return tbRes
end

function CharacterIdleActionData.GetPage(nID)
	if not self.tFilterIdleActionList then
		return 1
	end
	for k, v in ipairs(self.tFilterIdleActionList) do
		if nID == v.dwID then
			return math.ceil(k / EACH_PAGE_MAX_COUNT)
		end
	end
	return 1
end

function CharacterIdleActionData.PlayBindIdleAction(nType)
    -- PLAYER_IDLE_ACTION_DISPLAY_TYPE.SCENE
	local player = GetClientPlayer()
	if not player then
		return
	end
	local dwIdleActionID = player.GetDisplayIdleAction(nType) or 0
    local dwRepresentID = CharacterIdleActionData.GetActionRepresentID(dwIdleActionID)

	rlcmd(string.format("set local offline idle action id %d", dwRepresentID))
end

function CharacterIdleActionData.GetActionRepresentID(dwActionID, dwRepresentID, hIdleActionSettings)
    if not dwRepresentID then
        if dwActionID == 0 then
            dwRepresentID = 0
        else
            if not hIdleActionSettings then
                hIdleActionSettings = GetPlayerIdleActionSettings()
            end
            local tInfo = hIdleActionSettings.GetPriceInfo(dwActionID)
            if not tInfo then
                return
            end
            dwRepresentID = tInfo.dwRepresentID
        end
    end
    return dwRepresentID
end

function CharacterIdleActionData.GetPreviewImgByID(dwActionID, nRoleType)
	local roleTypeInfo_Get = tBodyTypeMap[nRoleType]

	local szPath = string.format(szPreviewImgPath, dwActionID, roleTypeInfo_Get)
	if not Lib.IsFileExist(szPath) then
		return
	end

	return szPath
end

-------------------------------------------------------------
function CharacterIdleActionData.SetFilterHave(nFilterHave)
	self.nFilterHave = nFilterHave
end

function CharacterIdleActionData.SetFilterGainWay(nFilterIndex)
	if nFilterIndex == 0 then
		self.nFilterGainWay = 0
		return
	end

	for nIndex, nGainWayType in ipairs(self.tGainWayMenu) do
		if g_tStrings.tItemSourceName[nGainWayType] and nIndex == nFilterIndex then
			self.nFilterGainWay = nGainWayType
		end
	end
end

function CharacterIdleActionData.GetCurrentPage()
    return self.nIdleActionPage
end

function CharacterIdleActionData.GetCurSelectedType()
    return self.nType
end

function CharacterIdleActionData.GetDefaultInfo()
    return clone(tDefault)
end

function CharacterIdleActionData.GetIdleActionNew()
    return RedpointHelper.IdleAction_HasRedpoint()
end

function CharacterIdleActionData.GetIdleActionIsNew(nActID)
    return RedpointHelper.IdleAction_IsNew(nActID)
end

function CharacterIdleActionData.ClearIdleActionNew()
    RedpointHelper.IdleAction_ClearAll()
end

function CharacterIdleActionData.GetType(dwSelectType)
    local tbInfo = tIdleActionType[dwSelectType]
    if not tbInfo then return end

	return tbInfo.szType
end

function CharacterIdleActionData.GetTypeInfo(dwSelectType)
    local tbInfo = tIdleActionType[dwSelectType]
    if not tbInfo then return end

	return tbInfo
end

function CharacterIdleActionData.IsEquipedAction(dwSelectType)
	local bEquip = false
	local player = GetClientPlayer()
	dwSelectType = dwSelectType or CharacterIdleActionData.GetCurSelectedType()

	if not player then
		return bEquip
	end

	local dwCurIdleActionID = player.GetDisplayIdleAction(dwSelectType)
    bEquip = dwCurIdleActionID > 0
	return bEquip
end

---------------------挂饰秘鉴通用界面配置函数-----------------------
function CharacterIdleActionData.SetCurrentPage(dwCurrentPage)
	self.nIdleActionPage = dwCurrentPage
end

function CharacterIdleActionData.SetSelectType(nType)
    self.nType = nType
end

function CharacterIdleActionData.SetSearchText(szSearchText)
    self.szSearchText = szSearchText
end

function CharacterIdleActionData.GetSearchText()
    return self.szSearchText
end

function CharacterIdleActionData.GetCollectionProgressTips()
    local nTotalNum = #self.tIdleActionList
	local nHaveNum = 0
	for k, v in ipairs(self.tIdleActionList) do
		if v.bHave then
			nHaveNum = nHaveNum + 1
		end
	end
	return nTotalNum, nHaveNum
end

function CharacterIdleActionData.GetCurPageInfo()
    local nTotalPage = math.ceil(#self.tFilterIdleActionList / EACH_PAGE_MAX_COUNT)
	return nTotalPage, self.nIdleActionPage
end

function CharacterIdleActionData.EmptyAllFilter()
	CharacterIdleActionData.SetSearchText("")
	CharacterIdleActionData.SetFilterHave(0)
	CharacterIdleActionData.SetFilterGainWay(0)
end

function CharacterIdleActionData.UpdateFilterList()
	CharacterIdleActionData.FilterList()
end

function CharacterIdleActionData.GetFilterMenu()
	local tFilter = FilterDef.Accessory_IdleAction

	local tGainWayList = tFilter[2].tbList
	for _, nGainWayType in ipairs(self.tGainWayMenu) do
		local szName = g_tStrings.tItemSourceName[nGainWayType]
		if szName and not table.contain_value(tGainWayList, szName) then
			table.insert(tGainWayList, g_tStrings.tItemSourceName[nGainWayType])
		end
	end

	return tFilter
end
---------------------挂饰秘鉴通用界面配置函数-----------------------

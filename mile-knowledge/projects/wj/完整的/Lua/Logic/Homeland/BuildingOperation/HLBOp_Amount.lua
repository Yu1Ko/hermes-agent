
NewModule("HLBOp_Amount")

m_tTempStore = {}
m_tPreStoreFlowerBrush = {}
m_tPreStoreFloorBrush = {}
m_tAllObjectIDInfo = {}
m_bInRequestConsumption = false -- 较卡标记一下
m_bInGetAllObject = false

---表现UserData----
local REQUEST_TYPE = {
	ENTER_BUILDING = 1,
	REFRESH = 2,
	REFRESH_INT = 3,
	REFRESH_FLOWER = 4,
	REFRESH_FLOOR = 5,
}

---潜规则----
--因为每次申请数据都是以收到地表刷数据消息为结尾 故在收到此消息时做界面更新

local function LoadFurnitureByModelID(tStore, hlMgr)
	for k, v in ipairs(tStore) do
		local nModelID, nModelAmount = v.nModelID, v.nModelAmount
		local nFurnitureType, nFurnitureID = FurnitureData.GetFurnTypeAndIDByModelID(nModelID)
		if nFurnitureID then
			hlMgr.BuildLoadFurniture(nFurnitureType, nFurnitureID, nModelAmount)
		end
	end
end

local function AddFurnitureByModelID(tStore, hlMgr)
	for k, v in ipairs(tStore) do
		local nModelID, nModelAmount = v.nModelID, v.nModelAmount
		local nFurnitureType, nFurnitureID = FurnitureData.GetFurnTypeAndIDByModelID(nModelID)
		if nFurnitureID then
			hlMgr.BuildAddFurniture(nFurnitureType, nFurnitureID, nModelAmount)
		end
	end
end

local function LoadBrushByModelID(tStore, hlMgr)
	for k, v in ipairs(tStore) do
		local nModelID, nModelAmount = v.nModelID, 1
		local nFurnitureType, nFurnitureID = FurnitureData.GetFurnTypeAndIDByModelID(nModelID)
		local nNowAmount = hlMgr.BuildGetOnLandFurniture(nFurnitureType, nFurnitureID)
		if nNowAmount == 0 and nFurnitureID then
			hlMgr.BuildLoadFurniture(nFurnitureType, nFurnitureID, nModelAmount)
		end
	end
end

local function AddBrushByModelID(tStore, hlMgr)
	for k, v in ipairs(tStore) do
		local nModelID, nModelAmount = v.nModelID, 1
		if nModelID ~= 0 then
			local nFurnitureType, nFurnitureID = FurnitureData.GetFurnTypeAndIDByModelID(nModelID)
			local nNowAmount = hlMgr.BuildGetOnLandFurniture(nFurnitureType, nFurnitureID)
			if nNowAmount == 0 and nFurnitureID then
				hlMgr.BuildAddFurniture(nFurnitureType, nFurnitureID, nModelAmount)
			end
		end
	end
end

---------------------------发送消息v--------------------------
-- Enter之后调用
function LoadLandData(nLevel, nLandIndex, nVersion)
	local hlMgr = GetHomelandMgr()
	local tConfig = Homeland_GetModeConfig(HLBOp_Main.GetBuildMode())
	local bResult
	if not tConfig.bDesign then
		bResult = hlMgr.BuildReset(nLevel, nLandIndex, nVersion)
	else
		bResult = hlMgr.BuildReset(nLevel, nLandIndex, nVersion, HOMELAND_BUILD_ERROR_CODE.STORGE_LACK)
	end
	Homeland_Log("BuildReset", nLevel, nLandIndex, nVersion, bResult)
	if bResult then
		RequestAllObject()
		RequestConsumption(REQUEST_TYPE.ENTER_BUILDING)
		RequestInteractInfo(REQUEST_TYPE.ENTER_BUILDING)
		RequestFlowerBrush(REQUEST_TYPE.ENTER_BUILDING)
		RequestFloorBrush(REQUEST_TYPE.ENTER_BUILDING)
	end
end

function LandBuildReset(nLevel, nLandIndex, nVersion)
	local hlMgr = GetHomelandMgr()
	local tConfig = Homeland_GetModeConfig(HLBOp_Main.GetBuildMode())
	local bResult
	if not tConfig.bDesign then
		bResult = hlMgr.BuildReset(nLevel, nLandIndex, nVersion)
	else
		bResult = hlMgr.BuildReset(nLevel, nLandIndex, nVersion, HOMELAND_BUILD_ERROR_CODE.STORGE_LACK)
	end
end

function RefreshLandData()
	local hlMgr = GetHomelandMgr()
	Homeland_Log("RefreshLandData")
	RequestAllObject()
	RequestConsumption(REQUEST_TYPE.REFRESH)
	RequestInteractInfo(REQUEST_TYPE.REFRESH)
	RequestFlowerBrush(REQUEST_TYPE.REFRESH)
	RequestFloorBrush(REQUEST_TYPE.REFRESH)
end

function RefreshCustomBrushData()
	Homeland_Log("RefreshCustomBrushData")
	RequestFlowerBrush(REQUEST_TYPE.REFRESH)
	RequestFloorBrush(REQUEST_TYPE.REFRESH)
end

function ChangeLandData(tStore)
	local hlMgr = GetHomelandMgr()
	Homeland_Log("ChangeLandData")
	RequestAllObject()
	RefreshInteractInfo()
	RefreshFlowerBrush()
	RefreshFloorBrush()
	AddFurnitureByModelID(tStore, hlMgr)
	FireUIEvent("LUA_HOMELAND_UPDATE_LANDDATA")
end

function ChangeLandDataFromReplace(dwSrcModelID, dwDstModelID, nAmount)
	local hlMgr = GetHomelandMgr()
	Homeland_Log("ChangeLandDataFromReplace")
	RequestAllObject()
	local tStore = {{nModelID = dwSrcModelID, nModelAmount = -nAmount}}
	AddFurnitureByModelID(tStore, hlMgr)
	local tStore = {{nModelID = dwDstModelID, nModelAmount = nAmount}}
	AddFurnitureByModelID(tStore, hlMgr)
	hlMgr.ChangeModule(dwSrcModelID, -nAmount)
	hlMgr.ChangeModule(dwDstModelID, nAmount)
	FireUIEvent("LUA_HOMELAND_UPDATE_LANDDATA")
end

function RefreshInteractInfo()
	Log("RequestInteractInfo")
	RequestInteractInfo(REQUEST_TYPE.REFRESH_INT)
end

function RefreshFlowerBrush()
	Log("RefreshFlowerBrush")
	RequestFlowerBrush(REQUEST_TYPE.REFRESH_FLOWER)
end

function RefreshFloorBrush()
	Log("RefreshFloorBrush")
	RequestFloorBrush(REQUEST_TYPE.REFRESH_FLOOR)
end

function RequestConsumption(nType)
	local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.GET_ALL_CONSUMPTION, nType)
	if bResult then
		m_bInRequestConsumption = true
	end
	Homeland_Log("发送HOMELAND_BUILD_OP.GET_ALL_CONSUMPTION", bResult)
end

function RequestInteractInfo(nType)
	local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.INTERACTABLE_OBJS, nType)
	Homeland_Log("发送HOMELAND_BUILD_OP.INTERACTABLE_OBJS", bResult)
end

function RequestFlowerBrush(nType)
	local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.GET_FOLIAGE_COVER_ID, nType)
	Homeland_Log("发送HOMELAND_BUILD_OP.GET_FOLIAGE_COVER_ID", bResult)
end

function RequestFloorBrush(nType)
	local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.GET_APPLIQUE_ID, nType)
	Homeland_Log("发送HOMELAND_BUILD_OP.GET_APPLIQUE_ID", bResult)
end

function RequestAllObject()
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.GET_ALL_OBJECT, 0)
	if bResult then
		m_bInGetAllObject = true
	end
    Homeland_Log("发送HOMELAND_BUILD_OP.GET_ALL_OBJECT", bResult)
end

function OnEvent(szEvent)
	if szEvent == "HOMELAND_CALL_RESULT" then
		local eOperationType = arg0
		if eOperationType == HOMELAND_BUILD_OP.GET_ALL_CONSUMPTION then
			OnRequestConsumptionResult()
		elseif eOperationType == HOMELAND_BUILD_OP.INTERACTABLE_OBJS then
			OnRequestInteractInfoResult()
		elseif eOperationType == HOMELAND_BUILD_OP.GET_FOLIAGE_COVER_ID then
			OnRequestFlowerBrushResult()
		elseif eOperationType == HOMELAND_BUILD_OP.GET_APPLIQUE_ID then
			OnRequestFloorBrushResult()
		elseif eOperationType == HOMELAND_BUILD_OP.GET_ALL_OBJECT then
			OnRequestAllObjectResult()
		end
	end
end

---------------------------接收消息v--------------------------

function OnRequestConsumptionResult()
	local nUserData = arg1
	local nPhase = arg2

	if nPhase == 0 then
		local bResult = Homeland_ToBoolean(arg3)
		m_tTempStore = {}
		Homeland_Log("OnRequestConsumptionResult nPhase 0", bResult, nUserData)
	elseif nPhase == 1 then
		Homeland_StoreConsumption(m_tTempStore)
	elseif nPhase == 2 then
		local hlMgr = GetHomelandMgr()
		if nUserData == REQUEST_TYPE.ENTER_BUILDING then
			LoadFurnitureByModelID(m_tTempStore, hlMgr)
		elseif nUserData == REQUEST_TYPE.REFRESH then
			hlMgr.BuildClearLandFurniture()
			AddFurnitureByModelID(m_tTempStore, hlMgr)
		end
		m_tTempStore = {}
		m_bInRequestConsumption = false
	end
end

function OnRequestInteractInfoResult()
	local nUserData = arg1
	local tInteractMdlInfo = clone(arg2)
	--{{[nModelid] = nAmount}, ...}

	Homeland_Log("OnRequestInteractInfoResult", nUserData)
	local hlMgr = GetHomelandMgr()
	if nUserData == REQUEST_TYPE.ENTER_BUILDING then
		for k, v in pairs(tInteractMdlInfo) do
			local nModelID, nModelAmount = k, v
			hlMgr.LoadModule(nModelID, nModelAmount)
		end
	elseif nUserData == REQUEST_TYPE.REFRESH_INT or nUserData == REQUEST_TYPE.REFRESH then
		hlMgr.BuildClearLandModule()
		for k, v in pairs(tInteractMdlInfo) do
			local nModelID, nModelAmount = k, v
			hlMgr.ChangeModule(nModelID, nModelAmount)
		end
	end
	FireUIEvent("LUA_HOMELAND_UPDATE_INTERACTABLE")
	if hlMgr.IsSDSizeExceedLimit() or hlMgr.IsLandObjectSizeExceedLimit() then
		local szInfo = ""
		if hlMgr.IsSDSizeExceedLimit() then
			szInfo = g_tStrings.STR_HOMELAND_SD_SIZE_LIMIT_REACHED
		elseif hlMgr.IsLandObjectSizeExceedLimit() then
			szInfo = g_tStrings.STR_HOMELAND_INS_SIZE_LIMIT_REACHED
		end

		local scriptView = UIHelper.ShowConfirm(szInfo)
		scriptView:HideButton("Cancel")
		FireUIEvent("LUA_HOMELAND_INTERACTABLE_ERROR")
	end
end

function OnRequestFlowerBrushResult()
	local nUserData = arg1
	local nPhase = arg2

	if nPhase == 0 then
		local bResult = Homeland_ToBoolean(arg3)
		m_tTempStore = {}
		Homeland_Log("OnRequestFlowerBrushResult nPhase 0", bResult, nUserData)
	elseif nPhase == 1 then
		Homeland_StoreConsumption(m_tTempStore)
	elseif nPhase == 2 then
		-- 表现原因 可能存在多个
		local hlMgr = GetHomelandMgr()
		if nUserData == REQUEST_TYPE.ENTER_BUILDING then
			LoadBrushByModelID(m_tTempStore, hlMgr)
		elseif nUserData == REQUEST_TYPE.REFRESH_FLOWER or nUserData == REQUEST_TYPE.REFRESH then
			hlMgr.BuildClearLandFoliageBrush()
			AddBrushByModelID(m_tTempStore, hlMgr)
		end
		m_tPreStoreFlowerBrush = m_tTempStore
		m_tTempStore = {}
	end
end

function OnRequestFloorBrushResult()
	local nUserData = arg1
	local bResult = Homeland_ToBoolean(arg2)
	local tFloorBrushID = clone({	{nModelID = arg3, nModelAmount = 1},
									{nModelID = arg4, nModelAmount = 1},
									{nModelID = arg5, nModelAmount = 1}})

	if not bResult then
		return
	end

	Homeland_Log("OnRequestFloorBrushResult", bResult, nUserData)

	local hlMgr = GetHomelandMgr()
	if nUserData == REQUEST_TYPE.ENTER_BUILDING then
		LoadBrushByModelID(tFloorBrushID, hlMgr)
	elseif nUserData == REQUEST_TYPE.REFRESH_FLOOR or nUserData == REQUEST_TYPE.REFRESH then
		hlMgr.BuildClearLandAppliqueBrush()
		AddBrushByModelID(tFloorBrushID, hlMgr)
	end
	FireUIEvent("LUA_HOMELAND_UPDATE_LANDDATA")
	m_tPreStoreFloorBrush = tFloorBrushID
end

function OnRequestAllObjectResult()
	local nResult = arg2
	local bResult = Homeland_ToBoolean(nResult)
	Homeland_Log("OnRequestAllObjectResult", bResult)
	m_tAllObjectIDInfo = Homeland_GetAllObject()
	m_bInGetAllObject = false
end

---------------------------API v--------------------------
function GetModelIDByObjID(dwObjID)
	return m_tAllObjectIDInfo[dwObjID]
end

function GetFloorBrushInfo()
	local tTemp = {}
	for i = 1, #m_tPreStoreFloorBrush do
		local nModelID = m_tPreStoreFloorBrush[i].nModelID
		local nModelAmount = m_tPreStoreFloorBrush[i].nModelAmount
		if nModelID ~= 0 and (not tTemp[nModelID]) then
			tTemp[nModelID] = 1
		end
	end
	local tPreStoreFloorBrush = {}
	for k, v in pairs(tTemp) do
		table.insert(tPreStoreFloorBrush, {nModelID = k, nModelAmount = v})
	end
	return tPreStoreFloorBrush
end

function GetRawFloorBrushInfo()
	return m_tPreStoreFloorBrush
end

function GetFlowerBrushInfo()
	--会存在相同的 或 nModelID==0 合并
	local tTemp = {}
	for i = 1, #m_tPreStoreFlowerBrush do
		local nModelID = m_tPreStoreFlowerBrush[i].nModelID
		local nModelAmount = m_tPreStoreFlowerBrush[i].nModelAmount
		if nModelID ~= 0 and (not tTemp[nModelID]) then
			tTemp[nModelID] = 1
		end
	end
	m_tPreStoreFlowerBrush = {}
	for k, v in pairs(tTemp) do
		table.insert(m_tPreStoreFlowerBrush, {nModelID = k, nModelAmount = v})
	end
	return m_tPreStoreFlowerBrush
end

function GetAllObjIDInfo()
	return m_tAllObjectIDInfo
end

function Init()
	m_tTempStore = {}
	m_tPreStoreFlowerBrush = {}
	m_tPreStoreFloorBrush = {}
	m_tAllObjectIDInfo = {}
	m_bInRequestConsumption = false
end

function UnInit()
	m_tTempStore = nil
	m_tPreStoreFlowerBrush = nil
	m_tPreStoreFloorBrush = nil
	m_tAllObjectIDInfo = nil
	m_bInRequestConsumption = nil
	local hlMgr = GetHomelandMgr()
	local bResult = hlMgr.BuildClear()
	Homeland_Log("BuildClear UnInit", bResult)
end
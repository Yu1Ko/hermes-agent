-- Author:  Jiang Zhenghao
-- Date:    2020-12-10
-- Version: 1.0
-- Desc:    家园物件处理脚本，用于交互等
-- Comment: 引用了策划脚本 \scripts\Map\家园系统客户端\include\Home_LandObjectInteraction.lua
----------------------------------------------------------------------

LandObject = LandObject or {className = "LandObject"}

local tinsert = table.insert
local tconcat = table.concat

local m_dwObjID = 0
local m_nLandIndex = 0
local m_nInstID = 0 -- 尝试交互的物件的实例ID（未必交互成功）
local m_bInInteraction = false -- 目前的判断只在Slot类型下有效（非Slot类型的交互是一次性的）
local m_dwObjPosX = 0 --> 重要要改为在鼠标移入的时候就获取
local m_dwObjPosY = 0
local m_dwObjPosZ = 0
local m_dwRepresentID = 0 -- 被交互物件的表现ID
local m_nMinMaxInteractDist = 0 --> 重要； 简单遍历配置数据后得到的最大交互距离的最小值（仅用于鼠标移入时判断是否距离过远使用）
local m_dwTPPosX = 0 --传送家具传送目的地
local m_dwTPPosY = 0
local m_dwTPPosZ = 0

local m_nInteractingType = nil
local m_nWaitingSlots = 0
local m_aSlotInfoList =
{
	--[[
	{
		nPosition=nPosition,
		nValue=nValue,
		szName=szName,
		bForPanel=bForPanel,
		nMaxInteractDist=nMaxInteractDist,
		nX=nX, nY=nY, nZ=nZ, fAngle=fAngle,
	},
	--]]
}

local m_tSlotTransformReqInfo =
{
	--[dwCallID] = {nLandIndex, nInstID, nSlotIndex},
}

local m_tSlotInfo = nil
--[[
{
	nPosition=nPosition,
	nValue=nValue,
	szName=szName,
	bForPanel=bForPanel,
	nX=nX, nY=nY, nZ=nZ, fAngle=fAngle,
}
--]]

local m_tNonSlotInfo =
{
	--nPosition=nPosition,
	--nValue=nValue,
	--szName=szName,
	--nMaxInteractDist=nMaxInteractDist,
	--bForPanel=bForPanel,
}

local m_dwCallID = 0

------ 测试用
local m_bShowInteractMenu = false
local m_bShowLog = false

local function _ShowOnelinedLog(...)
	local aParams = { ... }
	local argc = select("#", ...)
	local strLog = "("
	for i = 1, argc do
		strLog = strLog .. tostring(aParams[i])
		if i < argc then
			strLog = strLog .. ", "
		end
	end
	strLog = strLog .. ")"
	LOG.INFO(strLog)
end

local function _ShowOnelinedLog_Dev(...)
	if m_bShowLog then
		_ShowOnelinedLog(...)
	end
end

local function _Output(...)
	if m_bShowLog then
		LOG.INFO(...)
	end
end

-------------- BEGIN: 通用函数 --------------
local function _GetNewCallID()
	m_dwCallID = m_dwCallID + 1
	return m_dwCallID
end

local function _GetBaseIdAndInstID(dwObjID) -- 重要；考虑放到C++里
	local denominator = math.pow(2, 32)
	local nLandIndex = math.floor(dwObjID/(denominator))
	local nInstID = dwObjID - nLandIndex * denominator
	return nLandIndex, nInstID
end

local function _FireShowPanelEvent(bBySlot, dwMapID, nCopyIndex)
	if not dwMapID then
		local scene = GetClientScene()
		dwMapID, nCopyIndex = scene.dwMapID, scene.nCopyIndex
	end
	local nPosition, nMaxInteractDist
	if bBySlot then
		nPosition = m_tSlotInfo.nPosition
		nMaxInteractDist = m_tSlotInfo.nMaxInteractDist
	else
		nPosition = m_tNonSlotInfo.nPosition
		nMaxInteractDist = m_tNonSlotInfo.nMaxInteractDist
	end

	if UIMgr.IsViewOpened(VIEW_ID.PanelItemInteractionList) then
		return
	end

	local nFurnitureType, nFurnitureID = FurnitureData.GetFurnTypeAndIDByModelID(m_dwRepresentID)
	FireUIEvent("SHOW_HOMELAND_MINIGAME_PANEL",	dwMapID, nCopyIndex, m_nLandIndex, m_nInteractingType, nPosition, m_nInstID, {m_dwRepresentID, nFurnitureType, nFurnitureID},
			{m_dwObjPosX, m_dwObjPosY, m_dwObjPosZ, nMaxInteractDist, m_dwTPPosX, m_dwTPPosY, m_dwTPPosZ})
	Log("=== 刚发送了事件 SHOW_HOMELAND_MINIGAME_PANEL，参数是：")
	UILog_Dev(dwMapID, nCopyIndex, m_nLandIndex, m_nInteractingType, nPosition, m_nInstID, nFurnitureType, nFurnitureID)
end

LoadScriptFile(UIHelper.UTF8ToGBK("scripts/Map/家园系统客户端/Include/Home_LandObjectInteraction.lua"), LandObject)

-- 一个表现ID优先对应一个或多个Slot类型数据，若无则对应一个非Slot类型数据
local function Table_GetLOInteractionInfoList(dwReprID)
	_ShowOnelinedLog_Dev("==== 调用了函数 Table_GetLOInteractionInfoList()，参数是： " .. tostring(dwReprID), "堆栈： " .. tostring(debug.traceback()))

	local tLandObjectInteraction = LandObject.Home_GetLandObjectInteraction()
	local aInteractionInfos = tLandObjectInteraction[dwReprID] or {}
	if aInteractionInfos.fnDetermine then
		local fnDetermine = aInteractionInfos.fnDetermine
		if type(fnDetermine) == "function" then
			local scene = GetClientScene()
			local dwMapID, nCopyIndex = scene.dwMapID, scene.nCopyIndex
			local aInfoIndices = fnDetermine(dwMapID, nCopyIndex, m_nLandIndex, m_nInstID)
			if type(aInfoIndices) == "table" then
				local aResults = {}
				for _, nTheInfoIndex in ipairs(aInfoIndices) do
					if 0 < nTheInfoIndex and nTheInfoIndex <= #aInteractionInfos then
						table.insert(aResults, aInteractionInfos[nTheInfoIndex])
					end
				end
				aInteractionInfos = aResults
			elseif type(aInfoIndices) == "number" then
				local nInfoIndex = aInfoIndices
				if 0 < nInfoIndex and nInfoIndex <= #aInteractionInfos then
					aInteractionInfos = {aInteractionInfos[nInfoIndex]}
				else
					aInteractionInfos = {}
				end
			end
		end
	end
	local pPlayer = GetClientPlayer()
	local nPlayerX, nPlayerY, nPlayerZ = pPlayer.nX, pPlayer.nY, pPlayer.nZ
	local aRes = {}

	_ShowOnelinedLog_Dev("==== nPlayerX, nPlayerY, nPlayerZ ==")
	_ShowOnelinedLog_Dev(nPlayerX, nPlayerY, nPlayerZ)

	_ShowOnelinedLog_Dev("==== m_dwObjPosX, m_dwObjPosY, m_dwObjPosZ ==")
	_ShowOnelinedLog_Dev(m_dwObjPosX, m_dwObjPosY, m_dwObjPosZ)

	_ShowOnelinedLog_Dev("==== 得到的 aInteractionInfos ==")
	_Output(aInteractionInfos)

	for _, tInfo in ipairs(aInteractionInfos) do -- 考虑优化————先取出第一个元素，再从第二个元素开始遍历
		local szType = tInfo.szType
		if szType == "Slot" then
			if IsTableEmpty(aRes) then
				table.insert(aRes, tInfo)
			else
				local t = aRes[#aRes]
				if t.szType == "Slot" then
					table.insert(aRes, tInfo)
				else
					Log("ERROR！ 家园交互UI配置表中，表现ID： " .. tostring(dwReprID) .. " 对应的数据混合了Slot类型和非Slot类型，舍弃后者！") --> 重要；其实这是正常情况

					aRes = {}
					table.insert(aRes, tInfo)
				end
			end
		else
			if IsTableEmpty(aRes) then
				_ShowOnelinedLog_Dev("==== tInfo.nMaxInteractDist == " .. tostring(tInfo.nMaxInteractDist))
				if not LandObject_IsObjTooFarFromPlayer({m_dwObjPosX, m_dwObjPosY, m_dwObjPosZ}, {nPlayerX, nPlayerY, nPlayerZ},
						tInfo.nMaxInteractDist) then
					table.insert(aRes, tInfo)
				end
			else
				local t = aRes[#aRes]
				if t.szType == "Slot" then
					-- Do nothing
				else
					Log("ERROR！ 家园交互UI配置表中，表现ID： " .. tostring(dwReprID) .. " 对应了多个非Slot类型数据，只保留第一个！")

					-- Do nothing
				end
			end
		end
	end

	_ShowOnelinedLog_Dev("==== 最后筛选出来的 aRes ==")
	_Output(aRes)

	return aRes
end

local function _GetDataTypeAndPos(dwReprID, nIndex)
	local nDataType, nDataPos = nil, nil
	local tLandObjectInteraction = LandObject.Home_GetLandObjectInteraction()
	if not tLandObjectInteraction then
		return nDataType, nDataPos
	end

	local aInteractionInfos = tLandObjectInteraction[dwReprID]
	if not aInteractionInfos then
		return nDataType, nDataPos
	end

	local aInfo = aInteractionInfos[nIndex]
	if not aInfo then
		return nDataType, nDataPos
	end

	local szType = aInfo.szType
	nDataPos = aInfo.nPosition

	if szType == "SdEightDword" then
		nDataType = LAND_OBJECT_TYPE.SD_EIGHT_DWORD_SCRIPT
	elseif szType == "SdFourDword" then
		nDataType = LAND_OBJECT_TYPE.SD_FOUR_DWORD_SCRIPT
	elseif szType == "SdTwoDword" then
		nDataType = LAND_OBJECT_TYPE.SD_TWO_DWORD_SCRIPT
	elseif szType == "FourDword" then
		nDataType = LAND_OBJECT_TYPE.FOUR_DWORD_SCRIPT
	elseif szType == "State" then
		nDataType = LAND_OBJECT_TYPE.STATE
	elseif szType == "BoolState" then
		nDataType = LAND_OBJECT_TYPE.BOOL_STATE
	end
	return nDataType, nDataPos
end

function LandObject_GetLandObjectInteractionInfo(nLandIndex, nInstID, dwReprID, nInteractIndex)
	-- 单独获取家具交互相关数据，不触发交互
	local tData = {}
	local scene = GetClientScene()
	if not scene then
		return tData
	end

	local pHomelandMgr = GetHomelandMgr()
	if not pHomelandMgr then
		return tData
	end

	local dwMapID, nCopyIndex = scene.dwMapID, scene.nCopyIndex
	local nDataType, nDataPos = _GetDataTypeAndPos(dwReprID, nInteractIndex or 1)
	if not nDataType or not nDataPos then
		return tData
	end

	tData.dwMapID 		= dwMapID
	tData.nCopyIndex 	= nCopyIndex
	tData.nLandIndex 	= nLandIndex
	tData.nDataType 	= nDataType
	tData.nDataPos 		= nDataPos
	tData.nFurnitureInstanceID = nInstID

	local tParam = {}
	local nGameID = HomelandCommon.LandObject_GetFurniture2GameID(dwReprID)

	if nDataType == LAND_OBJECT_TYPE.SD_EIGHT_DWORD_SCRIPT then
		tParam = pHomelandMgr.GetSDEightDwordScript(dwMapID, nCopyIndex, nLandIndex, nInstID, nDataPos)
	elseif nDataType == LAND_OBJECT_TYPE.SD_FOUR_DWORD_SCRIPT then
		tParam = pHomelandMgr.GetSDFourDwordScript(dwMapID, nCopyIndex, nLandIndex, nInstID, nDataPos)
	elseif nDataType == LAND_OBJECT_TYPE.SD_TWO_DWORD_SCRIPT then
		tParam = pHomelandMgr.GetSDTwoDwordScript(dwMapID, nCopyIndex, nLandIndex, nInstID, nDataPos)
	elseif nDataType == LAND_OBJECT_TYPE.FOUR_DWORD_SCRIPT then
		tParam = pHomelandMgr.GetFourDwordScript(dwMapID, nCopyIndex, nLandIndex, nInstID, nDataPos)
	end

	if tParam then
		tData.tParam = tParam
		if tParam[1] then
			tData.nGameState = pHomelandMgr.GetDWORDValueByuint8(tParam[1], 0)
			local dwIndex = pHomelandMgr.GetDWORDValueByuint16(tParam[1], 2)
			local dwType = pHomelandMgr.GetDWORDValueByuint8(tParam[1], 1)
			if dwIndex and dwIndex > 0 then
				tData.tModule1Item = {dwTabType = dwType, dwIndex = dwIndex}
			end
		end

		if tParam[2] then
			if nGameID == 7 then
				tData.nTime = tParam[2]
			elseif nGameID == 19 and tData.nGameState == 2 then	-- 鱼池养鱼可打捞
				tData.nFishNum = pHomelandMgr.GetDWORDValueByuint8(tParam[2], 0)
				tData.nShareFishNum = pHomelandMgr.GetDWORDValueByuint8(tParam[2], 1)
			end
		end

		if nGameID == 20 then
			local dwWeaponID1 = pHomelandMgr.GetDWORDValueByuint16(tParam[2], 0)
			local dwWeaponID2 = pHomelandMgr.GetDWORDValueByuint16(tParam[3], 0)
			tData.tWeaponList = {dwWeaponID1, dwWeaponID2}
		end
	end
	return tData
end

-------------- END: 通用函数 ----------------

--需要攻击返回false，否则返回true
function InteractLandObjectByLandIndexAndInstID(nLandIndex, nInstID) -- 重要
	_ShowOnelinedLog_Dev("(nLandIndex == " .. tostring(nLandIndex) .. ", nInstID == " .. tostring(nInstID) .. ")")

	if m_bInInteraction and not (nLandIndex == m_nLandIndex and nInstID == m_nInstID) then
		_ShowOnelinedLog_Dev("需要先退出另一个物件的交互，才能进行当前交互")
		return true -- 需要先退出交互，才能进行下一个交互
	end

	--m_dwObjID = dwObjID -- 可能需要
	m_nLandIndex = nLandIndex
	m_nInstID = nInstID

	if nLandIndex == 0 then
		Log("ERROR! 该物件对应的地基Index无效！")
		return true
	end

	m_dwRepresentID = 0
	Homeland_SendMessage(HOMELAND_BUILD_OP.GET_INTERACTION_OBJECT_INFO, nLandIndex, nInstID, nInstID) --> 需要做点手脚
	return true
end

--需要攻击返回false，否则返回true
function InteractLandObject(dwObjID, bFromAutoSearch)
	_ShowOnelinedLog_Dev("=== 进入函数 InteractLandObject()，家园物件ID： " .. tostring(dwObjID))
	local nLandIndex, nInstID = _GetBaseIdAndInstID(dwObjID)
	local bReady = GetHomelandMgr().IsLandReady(nLandIndex)
	if bReady then
		return InteractLandObjectByLandIndexAndInstID(nLandIndex, nInstID)
	else
		if not bFromAutoSearch then
			local dialog = UIHelper.ShowConfirm(g_tStrings.STR_HOMELAND_LAND_DATA_NOT_READY)
        	dialog:HideButton("Cancel")
		end
		return true
	end
end


function LandObject_ChangeCursorWhenOver(dwObjID)
	if IsCursorInExclusiveMode() then
		return
	end

	Cursor.Switch(CURSOR.SPEAK)
end

function OutputLandObjectTip(dwObjID)
	local t = {}
	-- 调试信息
	if IsCtrlKeyDown() then
		local nLandIndex, nInstID = _GetBaseIdAndInstID(dwObjID)
		tinsert(t, GetFormatText(g_tStrings.DEBUG_INFO_ITEM_TIP, 102))
		tinsert(t, GetFormatText(FormatString("\n" .. g_tStrings.TIP_FURNITURE_UID, dwObjID), 102))
		tinsert(t, GetFormatText(FormatString(g_tStrings.TIP_FURNITURE_ID, nInstID), 102))

		local x, y = Cursor.GetPos()
		local w, h = 40, 40
		local Rect = {x, y, w, h}
		OutputTip(tconcat(t), 345, Rect)
	end
end

----------------------------------------------------------------------

local function fnOnQuitInteraction() --> 重要； 其他类型的交互应该也需要调用这个
	_ShowOnelinedLog_Dev("调用了 fnOnQuitInteraction()，堆栈： " .. tostring(debug.traceback()))

	m_bInInteraction = false
	m_dwObjID = 0
	m_nLandIndex = 0
	m_nInstID = 0
	m_tSlotInfo = nil
	m_dwRepresentID = 0
	m_nInteractingType = nil
	m_tNonSlotInfo = {}
end

local function fnOnOperateHomelandObject()
	_ShowOnelinedLog_Dev("==== 响应了事件 HOME_LAND_OPERATE_OBJECT")
	local dwOperatorPlayerID, dwMapID, nCopyIndex, nLandIndex, dwInstID, nType, nPosition = arg0, arg1, arg2, arg3, arg4, arg5, arg6
	if dwOperatorPlayerID == UI_GetClientPlayerID() then
		if nType == LAND_OBJECT_TYPE.BOOL_STATE then
			local res = GetHomelandMgr().GetLOBoolState(dwMapID, nCopyIndex, nLandIndex, dwInstID, nPosition)
			_ShowOnelinedLog_Dev(("收到事件时，调用函数 GetHomelandMgr().GetLOBoolState(%d, %d, %d, %d, %d)的结果是: "):format(dwMapID,
					nCopyIndex, nLandIndex, dwInstID, nPosition) .. tostring(res))
		elseif nType == LAND_OBJECT_TYPE.SLOT then
			-- 重要； 要考虑 m_nLandIndex、m_nInstID 或 m_tSlotInfo 不存在的情况（这时候应该是发生在交互状态下断线重连时）
			if nLandIndex == m_nLandIndex and dwInstID == m_nInstID and m_tSlotInfo and m_tSlotInfo.nPosition == nPosition then
				_ShowOnelinedLog_Dev("=== 自己操作了地基内 " .. tostring(dwInstID) .. " 号物件的SLOT")
				_ShowOnelinedLog_Dev(nLandIndex, dwInstID, nPosition)
				local nSlotState, dwPlayerID = GetHomelandMgr().GetLOSlot(dwMapID, nCopyIndex, nLandIndex, dwInstID, nPosition)
				_ShowOnelinedLog_Dev("====== 下面是调用GetLOSlot()的结果：")
				_ShowOnelinedLog_Dev("(nSlotState == " .. tostring(nSlotState) .. ", dwPlayerID == " .. tostring(dwPlayerID) .. ")")
				if nSlotState == 0 then
					fnOnQuitInteraction()
				end
			else
				_ShowOnelinedLog("=== 自己操作了地基内 " .. tostring(dwInstID) .. " 号物件的SLOT")
				_ShowOnelinedLog(nLandIndex, dwInstID, nPosition)
				Log("=== 但并不是自己所关心的")
			end
		end
	end
end

local function fnGetInteractionData()
	local player = GetClientPlayer()
	local nPlayerX, nPlayerY, nPlayerZ = player.nX, player.nY, player.nZ
	local aInfoList = Table_GetLOInteractionInfoList(m_dwRepresentID)

	if IsTableEmpty(aInfoList) then
		return false
	else
		local tFirstInfo = aInfoList[1]
		local szFirstType = tFirstInfo.szType
		if szFirstType == "Slot" then
			m_nInteractingType = LAND_OBJECT_TYPE.SLOT

			local function _GetInteractionInfoByPosition(nPosition)
				for _, tInfo in ipairs(aInfoList) do
					if tInfo.nPosition == nPosition then
						return tInfo
					end
				end
				return nil
			end

			-- 先筛选掉距离过远的
			for nIndex, tSlotInfo in ipairs_r(m_aSlotInfoList) do
				local nPosition = tSlotInfo.nPosition
				local tInteractionInfo = _GetInteractionInfoByPosition(nPosition)
				if tInteractionInfo and (not LandObject_IsObjTooFarFromPlayer({nPlayerX, nPlayerY, nPlayerZ},
					{tSlotInfo.nX, tSlotInfo.nY,tSlotInfo.nZ}, tInteractionInfo.nMaxInteractDist)) then
					tSlotInfo.nValue = tInteractionInfo.nValue
					tSlotInfo.szName = tInteractionInfo.szName
					tSlotInfo.bForPanel = tInteractionInfo.bForPanel
				else
					table.remove(m_aSlotInfoList, nIndex)
				end
			end
		else
			if szFirstType == "State" then
				m_nInteractingType = LAND_OBJECT_TYPE.STATE
			elseif szFirstType == "BoolState" then
				m_nInteractingType = LAND_OBJECT_TYPE.BOOL_STATE
			elseif szFirstType == "FourDword" then
				m_nInteractingType = LAND_OBJECT_TYPE.FOUR_DWORD_SCRIPT
			elseif szFirstType == "SdTwoDword" then
				m_nInteractingType = LAND_OBJECT_TYPE.SD_TWO_DWORD_SCRIPT
			elseif szFirstType == "SdFourDword" then
				m_nInteractingType = LAND_OBJECT_TYPE.SD_FOUR_DWORD_SCRIPT
			elseif szFirstType == "SdEightDword" then
				m_nInteractingType = LAND_OBJECT_TYPE.SD_EIGHT_DWORD_SCRIPT
			else
				return false
			end

			m_tNonSlotInfo =
			{
				nPosition=tFirstInfo.nPosition,
				nValue=tFirstInfo.nValue,
				szName=tFirstInfo.szName,
				nMaxInteractDist=tFirstInfo.nMaxInteractDist,
				bForPanel=tFirstInfo.bForPanel}
		end
	end

	if m_nInteractingType == LAND_OBJECT_TYPE.SLOT then
		_ShowOnelinedLog_Dev("==== m_tSlotInfo 即将被重置为 nil")
		_ShowOnelinedLog_Dev("==== 此时 m_aSlotInfoList == ")
		_Output(m_aSlotInfoList)
		m_tSlotInfo = nil

		table.sort(m_aSlotInfoList, function(tInfoL, tInfoR)
			local nDistSquareL = (tInfoL.nX - nPlayerX) * (tInfoL.nX - nPlayerX) + (tInfoL.nY - nPlayerY) * (tInfoL.nY - nPlayerY)
					+ (tInfoL.nZ - nPlayerZ) * (tInfoL.nZ - nPlayerZ)
			local nDistSquareR = (tInfoR.nX - nPlayerX) * (tInfoR.nX - nPlayerX) + (tInfoR.nY - nPlayerY) * (tInfoR.nY - nPlayerY)
					+ (tInfoR.nZ - nPlayerZ) * (tInfoR.nZ - nPlayerZ)
			return nDistSquareL < nDistSquareR
		end)

		local hlMgr = GetHomelandMgr()
		local scene = GetClientScene()
		local dwMapID, nCopyIndex = scene.dwMapID, scene.nCopyIndex
		for _, t in ipairs(m_aSlotInfoList) do
			_ShowOnelinedLog_Dev("==== 调用 CanSetPosition()，参数是： ")
			_ShowOnelinedLog_Dev(t.nX, t.nY, t.nZ)
			local bCanSet, nRetZ = hlMgr.CanSetPosition(t.nX, t.nY, t.nZ)
			if bCanSet then
				local nSlotState, dwPlayerID = hlMgr.GetLOSlot(dwMapID, nCopyIndex, m_nLandIndex, m_nInstID, t.nPosition)
				if dwPlayerID and dwPlayerID ~= 0 then
					Log("=== INFO: 交互物件已被其他玩家(id: " .. tostring(dwPlayerID) .. ")占据！")
					if dwPlayerID == UI_GetClientPlayerID() then
						if not m_bInInteraction then -- 重要；临时这样，兴许有更好的办法
							_ShowOnelinedLog_Dev("--即将调用ChangSlot，效果是取消交互，参数是：")
							_ShowOnelinedLog_Dev("nInstID: ", m_nInstID, "nPosition", t.nPosition)
							hlMgr.ChangeLOSlot(m_nInstID, 0, 0, t.nPosition)
							RemoteCallToServer("On_LO_LeaveInteraction", m_nLandIndex, m_nInstID, t.nPosition, 0, m_dwRepresentID)

							Log("=== 占据位置的竟然是自己！于是强制取消交互")
							OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_HOMELAND_OBJECT_DELAY_INTERACTION)

							bCanSet = false
						else
							-- bCanSet = true
						end
					elseif not GetPlayer(dwPlayerID) then
						_ShowOnelinedLog_Dev("nInstID: ", m_nInstID, "nPosition", t.nPosition)
						hlMgr.ChangeLOSlot(m_nInstID, 0, 0, t.nPosition)
						Log("=== 占据位置的是不存在的玩家！于是强制取消交互")
						OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_HOMELAND_OBJECT_DELAY_INTERACTION)

						bCanSet = false
					else
						bCanSet = false
					end
				else
					-- Do nothing
				end

				if bCanSet then -- 没有别的玩家占据，或者占据的是自己且处于交互状态
					_ShowOnelinedLog_Dev("== nRetZ == " .. tostring(nRetZ))
					m_tSlotInfo = clone(t)
					m_tSlotInfo.nZ = nRetZ
					_ShowOnelinedLog_Dev("=== m_tSlotInfo  信息是：")
					_Output(m_tSlotInfo)

					break
				end
			end
		end
	else
		-- Do nothing
	end

	return true
end

local function fnShowInteractionMenu()
	if not fnGetInteractionData() then --> 重要； 或者考虑在这个时候把 m_nInteractingType 等数据重置？
		return
	end

	if UIMgr.IsViewOpened(VIEW_ID.PanelItemInteractionList) then
		return
	end

	local scene = GetClientScene()
	local dwMapID, nCopyIndex = scene.dwMapID, scene.nCopyIndex
	local hlMgr = GetHomelandMgr()

	local fnAction
	local szActionName
	if m_nInteractingType == LAND_OBJECT_TYPE.SLOT then
		if m_tSlotInfo then
			local nValue, dwPlayerID
			local bCancelAction = false
			if not m_bInInteraction then
				nValue = m_tSlotInfo.nValue
				dwPlayerID = UI_GetClientPlayerID()
				szActionName = m_tSlotInfo.szName
			else
				nValue = 0
				dwPlayerID = 0
				szActionName = "取消交互"

				bCancelAction = true
			end

			fnAction = function()
				_ShowOnelinedLog_Dev("-- 即将在右键交互的时候调用 ChangeLOSlot()，参数是：")
				_Output({nInstID=m_nInstID, nValue=nValue, dwPlayerID=dwPlayerID, nPosition=m_tSlotInfo.nPosition})
				hlMgr.ChangeLOSlot(m_nInstID, nValue, dwPlayerID, m_tSlotInfo.nPosition)
				_ShowOnelinedLog_Dev("=== 调用了函数 GetHomelandMgr().ChangeLOSlot()，参数列表：")
				_ShowOnelinedLog_Dev(m_nInstID, nValue, dwPlayerID, m_tSlotInfo.nPosition)

				if bCancelAction then
					RemoteCallToServer("On_LO_LeaveInteraction", m_nLandIndex, m_nInstID, m_tSlotInfo.nPosition, 0, m_dwRepresentID)
				end
			end
		else
			Log("=== INFO: 家园物件取不到可达的Slot数据信息！")
			return
		end
	elseif m_nInteractingType == LAND_OBJECT_TYPE.STATE then
		if m_tNonSlotInfo then
			szActionName = m_tNonSlotInfo.szName
			fnAction = function()
				hlMgr.ChangeLOState(m_nInstID, m_tNonSlotInfo.nValue, m_tNonSlotInfo.nPosition)
				_ShowOnelinedLog_Dev("=== 调用了函数 GetHomelandMgr().ChangeLOState()，参数列表：")
				_ShowOnelinedLog_Dev(m_nInstID, m_tNonSlotInfo.nValue, m_tNonSlotInfo.nPosition)

				if m_tNonSlotInfo.bForPanel then
					_FireShowPanelEvent(false, dwMapID, nCopyIndex)
				end
			end
		else
			Log("=== INFO: 家园物件取不到合法的State类型数据信息！")
			return
		end
	elseif m_nInteractingType == LAND_OBJECT_TYPE.BOOL_STATE then
		if m_tNonSlotInfo then
			szActionName = m_tNonSlotInfo.szName
			fnAction = function()
				local nValue = hlMgr.GetLOBoolState(dwMapID, nCopyIndex, m_nLandIndex, m_nInstID, m_tNonSlotInfo.nPosition)
				if nValue == 1 then
					hlMgr.ChangeLOBoolState(m_nInstID, 0, m_tNonSlotInfo.nPosition)
					Log("=== INFO: 第二次交互时，将操作 BoolState 交互数据解释为取消交互")
				else
					hlMgr.ChangeLOBoolState(m_nInstID, m_tNonSlotInfo.nValue, m_tNonSlotInfo.nPosition)
					_ShowOnelinedLog_Dev("=== 调用了函数 GetHomelandMgr().ChangeLOBoolState()，参数列表：")
					_ShowOnelinedLog_Dev(m_nInstID, m_tNonSlotInfo.nValue, m_tNonSlotInfo.nPosition)
					if m_tNonSlotInfo.bForPanel then
						_FireShowPanelEvent(false, dwMapID, nCopyIndex)
					end
				end
			end
		else
			Log("=== INFO: 家园物件取不到合法的BoolState类型数据信息！")
			return
		end
	elseif m_nInteractingType == LAND_OBJECT_TYPE.FOUR_DWORD_SCRIPT then
		Log("=== fnShowInteractionMenu()中， m_nInteractingType == LAND_OBJECT_TYPE.FOUR_DWORD_SCRIPT")
		if m_tNonSlotInfo then
			szActionName = m_tNonSlotInfo.szName
			fnAction = function()
				if m_tNonSlotInfo.bForPanel then
					_FireShowPanelEvent(false, dwMapID, nCopyIndex)
				end
			end
		else
			Log("=== INFO: 家园物件取不到合法的 FOUR_DWORD_SCRIPT 类型数据信息！")
			return
		end
	elseif m_nInteractingType == LAND_OBJECT_TYPE.SD_TWO_DWORD_SCRIPT then
		Log("=== fnShowInteractionMenu()中， m_nInteractingType == LAND_OBJECT_TYPE.SD_TWO_DWORD_SCRIPT")
		if m_tNonSlotInfo then
			szActionName = m_tNonSlotInfo.szName
			fnAction = function()
				if m_tNonSlotInfo.bForPanel then
					_FireShowPanelEvent(false, dwMapID, nCopyIndex)
				end
			end
		else
			Log("=== INFO: 家园物件取不到合法的 SD_TWO_DWORD_SCRIPT 类型数据信息！")
			return
		end
	elseif m_nInteractingType == LAND_OBJECT_TYPE.SD_FOUR_DWORD_SCRIPT then
		Log("=== fnShowInteractionMenu()中， m_nInteractingType == LAND_OBJECT_TYPE.SD_FOUR_DWORD_SCRIPT")
		if m_tNonSlotInfo then
			szActionName = m_tNonSlotInfo.szName
			fnAction = function()
				if m_tNonSlotInfo.bForPanel then
					_FireShowPanelEvent(false, dwMapID, nCopyIndex)
				end
			end
		else
			Log("=== INFO: 家园物件取不到合法的 SD_FOUR_DWORD_SCRIPT 类型数据信息！")
			return
		end
	elseif m_nInteractingType == LAND_OBJECT_TYPE.SD_EIGHT_DWORD_SCRIPT then
		Log("=== fnShowInteractionMenu()中， m_nInteractingType == LAND_OBJECT_TYPE.SD_EIGHT_DWORD_SCRIPT")
		if m_tNonSlotInfo then
			szActionName = m_tNonSlotInfo.szName
			fnAction = function()
				if m_tNonSlotInfo.bForPanel then
					_FireShowPanelEvent(false, dwMapID, nCopyIndex)
				end
			end
		else
			Log("=== INFO: 家园物件取不到合法的 SD_EIGHT_DWORD_SCRIPT 类型数据信息！")
			return
		end
	end

	if fnAction then
		if m_bShowInteractMenu then
			local nCursorX, nCursorY = Cursor.GetPos()
			local tMenu =
			{
				nMiniWidth = 60,
				x = nCursorX,
				y = nCursorY,
				fnAutoClose = function() return false end,
			}

			local tMenuItem =
			{
				szOption = szActionName,
				fnAction = fnAction,
			}
			table.insert(tMenu, tMenuItem)

			PopupMenu(tMenu)
		else
			fnAction()
		end
	end
end

local function fnOnGetRepresentID()
	local aInfoList = Table_GetLOInteractionInfoList(m_dwRepresentID)

	if IsTableEmpty(aInfoList) then
		return
	else
		local tFirstInfo = aInfoList[1]
		local szFirstType = tFirstInfo.szType
		if szFirstType == "Slot" then
			local scene = GetClientScene()
			local dwMapID, nCopyIndex = scene.dwMapID, scene.nCopyIndex
			local hlMgr = GetHomelandMgr()
			local nSlotCnt = hlMgr.GetLandObjectCount(dwMapID, nCopyIndex, m_nLandIndex, m_nInstID, LAND_OBJECT_TYPE.SLOT)

			m_aSlotInfoList = {}
			if nSlotCnt > 0 then
				m_nWaitingSlots = nSlotCnt

				for nSlotIndex = 1, nSlotCnt do
					local dwCallID = _GetNewCallID()
					m_tSlotTransformReqInfo[dwCallID] = {m_nLandIndex, m_nInstID, nSlotIndex}
					Homeland_SendMessage(HOMELAND_BUILD_OP.GET_SLOT_TRANSFORM, m_nLandIndex, m_nInstID, nSlotIndex, dwCallID)
				end
			else
				m_nWaitingSlots = 0
				Log("=== 该家园物件的Slot数量是0！")
			end
			return true
		else
			-- Do nothing
			return false
		end
	end
end

local function fnOnGetCallResult()
	local eOperationType = arg0
	local userdata = arg1
	if eOperationType == HOMELAND_BUILD_OP.GET_SLOT_TRANSFORM then
		_ShowOnelinedLog_Dev("==== 对应 HOMELAND_BUILD_OP.GET_SLOT_TRANSFORM 的userdata == " .. tostring(userdata))
		local dwCallID = userdata
		if m_tSlotTransformReqInfo[dwCallID] then
			local nLandIndex, nInstID, nSlotIndex = m_tSlotTransformReqInfo[dwCallID][1], m_tSlotTransformReqInfo[dwCallID][2],
				m_tSlotTransformReqInfo[dwCallID][3]
			if nLandIndex == m_nLandIndex and nInstID == m_nInstID then
				local bResult, nSlotX, nSlotY, nSlotZ, fAngle = arg2, arg3, arg4, arg5, arg6
				m_nWaitingSlots = m_nWaitingSlots - 1

				if bResult then
					table.insert(m_aSlotInfoList, { nPosition=nSlotIndex,nX= nSlotX,nY= nSlotY,nZ= nSlotZ,fAngle=fAngle})
				else
					Log("ERROR! 取不到 " .. tostring(nSlotIndex) .. " 号Slot的位置信息！")
				end
				if m_nWaitingSlots == 0 and m_dwRepresentID ~= 0 then
					fnShowInteractionMenu()
				end
			end
		end
	elseif eOperationType == HOMELAND_BUILD_OP.GET_INTERACTION_OBJECT_INFO then
		_ShowOnelinedLog_Dev("==== 对应 HOMELAND_BUILD_OP.GET_INTERACTION_OBJECT_INFO 的 userdata == " .. tostring(userdata))
		if userdata == m_nInstID then
			local bResult, dwReprID, dwGroupID = arg2, arg3, arg4
			_ShowOnelinedLog_Dev("== 其余参数： " .. tostring(bResult), dwReprID, dwGroupID)
			if bResult then
				m_dwRepresentID = dwReprID

				m_dwObjPosX, m_dwObjPosY, m_dwObjPosZ = arg5, arg6, arg7

				--传送家具附带传送坐标
				local eTransCheckCode = arg14
				if eTransCheckCode == 1 then
					OutputWarningMessage("MSG_NOTICE_RED", g_tStrings.STR_TRANS_COORDINATE_ERROR)
					return
				elseif eTransCheckCode == 2 then
					m_dwTPPosX, m_dwTPPosY, m_dwTPPosZ = arg15, arg16, arg17
				end
				--if m_nWaitingSlots == 0 then -- 重要：这时候还没有去申请Slot位置信息，所以必然成立； 先注释掉，以后正式化
				--fnShowInteractionMenu() --> 包含从未申请过Slot位置信息、和在这之前已经申请完毕Slot位置信息两种情形
				--else
				if not fnOnGetRepresentID() then --> 临时这么写
					fnShowInteractionMenu()
				end
				--end
			else
				Log("ERROR! 未能获得交互家具(实例ID: " .. tostring(m_nInstID) .. ")的 GET_INTERACTION_OBJECT_INFO 数据！")
			end
		end
	end
end

local function fnOnSlotIn()
	local dwBaseID, nInstID, nPosition, dwPlayerID = arg0, arg1, arg2, arg3
	_ShowOnelinedLog_Dev("==== 响应了事件 SlotIn，参数是:")
	_ShowOnelinedLog_Dev(dwBaseID, nInstID, nPosition)
	if dwPlayerID == UI_GetClientPlayerID() and dwBaseID == m_nLandIndex and nInstID == m_nInstID then
		_ShowOnelinedLog_Dev("=== SlotIn成功，序号：" .. tostring(nPosition))
		if m_tSlotInfo and m_tSlotInfo.nPosition == nPosition then
			local scene = GetClientScene()
			local dwMapID, nCopyIndex = scene.dwMapID, scene.nCopyIndex
			GetHomelandMgr().SetPosition(m_tSlotInfo.nX, m_tSlotInfo.nY, m_tSlotInfo.nZ)
			_ShowOnelinedLog_Dev("=== 调用了 SetPosition()，参数列表：")
			_ShowOnelinedLog_Dev(m_tSlotInfo.nX, m_tSlotInfo.nY, m_tSlotInfo.nZ)
			TurnTo(m_tSlotInfo.fAngle)
			_ShowOnelinedLog_Dev("=== 要转到的角度是： " .. tostring(m_tSlotInfo.fAngle))

			m_bInInteraction = true
			_ShowOnelinedLog_Dev("=== m_bInInteraction 被设为了 true")

			if m_tSlotInfo.bForPanel then
				_FireShowPanelEvent(true, dwMapID, nCopyIndex)
			end

			RemoteCallToServer("On_LO_EnterInteraction", dwBaseID, nInstID, nPosition, m_tSlotInfo.nValue, m_dwRepresentID)
		else
			Log("=== 忽略掉此SlotIn事件")
		end
	end
end

-- return false 表示提前执行了 fnOnQuitInteraction()
local function fnQuitInteraction()
	_ShowOnelinedLog_Dev("=== 调用了函数 fnQuitInteraction()， 堆栈是： " .. tostring(debug.traceback()))
	if m_tSlotInfo then
		local nPosition = m_tSlotInfo.nPosition
		_ShowOnelinedLog_Dev("-- 即将在取消交互的时候调用 ChangeLOSlot(), m_nInstID == ", m_nInstID, ", nPosition == ", nPosition)
		if not GetHomelandMgr().ChangeLOSlot(m_nInstID, 0, 0, nPosition) then -- 这时候收不到回调事件（可能是由于此时玩家位置在地基之外），只能立即处理
			fnOnQuitInteraction()
			return false
		end
		_ShowOnelinedLog_Dev("=== 尝试取消交互，调用了函数 ChangeLOSlot()，参数列表：")
		_ShowOnelinedLog_Dev(m_nInstID, 0, 0, nPosition)

		RemoteCallToServer("On_LO_LeaveInteraction", m_nLandIndex, m_nInstID, nPosition, 0, m_dwRepresentID)
	end
	return true
end

--[[
local function fnQuitNonSlotInteraction() -- 应该是要有的吧（不过据说没有；先准备着）
	local scene = GetClientScene()
	local dwMapID, nCopyIndex = scene.dwMapID, scene.nCopyIndex
	if m_nInteractingType == LAND_OBJECT_TYPE.STATE then
		GetHomelandMgr().ChangeLOState(m_nInstID, 0, m_tNonSlotInfo.nPosition)
		_ShowOnelinedLog_Dev("=== 尝试取消交互，调用了函数 ChangeLOState()，参数列表：")
		_ShowOnelinedLog_Dev(m_nInstID, 0, m_tNonSlotInfo.nPosition)
	elseif m_nInteractingType == LAND_OBJECT_TYPE.BOOL_STATE then
		GetHomelandMgr().ChangeLOBoolState(m_nInstID, 0, m_tNonSlotInfo.nPosition)
		_ShowOnelinedLog_Dev("=== 尝试取消交互，调用了函数 ChangeLOBoolState()，参数列表：")
		_ShowOnelinedLog_Dev(m_nInstID, 0, m_tNonSlotInfo.nPosition)
	end
end
--]]

local function fnOnChangeLOData()
	local dwPlayerID, nLandIndex, dwInstID, nDataType, nPosition, nValue = arg0, arg1, arg2, arg3, arg4, arg5
	--local scene = GetClientScene()
	--local dwMapID, nCopyIndex = scene.dwMapID, scene.nCopyIndex
	local hlMgr = GetHomelandMgr()
	if dwPlayerID == UI_GetClientPlayerID() and nLandIndex == m_nLandIndex and dwInstID == m_nInstID then
		if nDataType == LAND_OBJECT_TYPE.SLOT then
			_ShowOnelinedLog_Dev("=== 响应了事件 CALL_FOR_CHANGE_LO_DATA，类型是 SLOT")
			if m_tSlotInfo then
				if nPosition == m_tSlotInfo.nPosition and nValue == 0 then
					if not fnQuitInteraction() then
						return
					end
				else
					_ShowOnelinedLog_Dev("--- 服务端脚本要求调用 ChangeLOSlot()，参数是：")
					_Output({nInstID=m_nInstID, nValue=nValue, dwPlayerID=dwPlayerID, nPosition=nPosition})
					hlMgr.ChangeLOSlot(m_nInstID, nValue, dwPlayerID, nPosition)
				end

				_ShowOnelinedLog_Dev("即将把Slot位置设置为： " .. tostring(nPosition))
				m_tSlotInfo.nPosition = nPosition
				_ShowOnelinedLog_Dev("并把Slot的数值设置为： " .. tostring(nValue))
				m_tSlotInfo.nValue = nValue
			else
				--Log("=== 忽略掉此 CALL_FOR_CHANGE_LO_DATA 事件")
			end
		elseif nDataType == LAND_OBJECT_TYPE.STATE then
			if m_tNonSlotInfo then
				hlMgr.ChangeLOState(m_nInstID, m_tNonSlotInfo.nValue, m_tNonSlotInfo.nPosition)
				_ShowOnelinedLog_Dev("=== 调用了函数 GetHomelandMgr().ChangeLOState()，参数列表：")
				_ShowOnelinedLog_Dev(m_nInstID, m_tNonSlotInfo.nValue, m_tNonSlotInfo.nPosition)
			end
		elseif nDataType == LAND_OBJECT_TYPE.BOOL_STATE then
			if m_tNonSlotInfo then
				if nPosition == m_tNonSlotInfo.nPosition and nValue == 0 then
					fnQuitInteraction()
				else
					hlMgr.ChangeLOBoolState(m_nInstID, m_tNonSlotInfo.nValue, m_tNonSlotInfo.nPosition)
				end
				_ShowOnelinedLog_Dev("=== 调用了函数 GetHomelandMgr().ChangeLOBoolState()，参数列表：")
				_ShowOnelinedLog_Dev(m_nInstID, m_tNonSlotInfo.nValue, m_tNonSlotInfo.nPosition)
			end
		elseif nDataType == LAND_OBJECT_TYPE.FOUR_DWORD_SCRIPT then
			if m_tNonSlotInfo then
				-- Do nothing
			end
		elseif nDataType == LAND_OBJECT_TYPE.SD_TWO_DWORD_SCRIPT then
			if m_tNonSlotInfo then
				-- Do nothing
			end
		elseif nDataType == LAND_OBJECT_TYPE.SD_FOUR_DWORD_SCRIPT then
			if m_tNonSlotInfo then
				-- Do nothing
			end
		elseif nDataType == LAND_OBJECT_TYPE.SD_EIGHT_DWORD_SCRIPT then
			if m_tNonSlotInfo then
				-- Do nothing
			end
		end
	end
end

local function fnOnSlotOut()
	local dwBaseID, nInstID, nSlotIndex, dwPlayerID = arg0, arg1, arg2, arg3
	_ShowOnelinedLog_Dev("==== 响应了事件 SlotOut，参数是:")
	_ShowOnelinedLog_Dev(dwBaseID, nInstID, nSlotIndex) -- 重要
	if dwPlayerID == UI_GetClientPlayerID() and dwBaseID == m_nLandIndex and nInstID == m_nInstID then
		_ShowOnelinedLog_Dev("=== 收到了事件 SlotOut，即将与第" .. tostring(nSlotIndex) .. "号Slot停止交互！")

		if m_tSlotInfo and m_tSlotInfo.nPosition == nSlotIndex then
			fnQuitInteraction() -- 可能不会用到
		else
			Log("=== 忽略掉此 SlotOut 事件")
		end
	end
end

local function fnForceQuitInteraction()
	if m_bInInteraction then
		fnQuitInteraction()
		fnOnQuitInteraction()
	end
end

local function fnOnHomeRetCodeInt()
	local nRetCode = arg0
	if nRetCode == HOMELAND_RESULT_CODE.PLAYER_MOVE then
		local bIsInMyLand, nLandIndex = arg1 ~= 0, arg2
		if nLandIndex > 0 then
			--Log("=== 进入了地基")
			fnOnQuitInteraction() -- 当交互的家具在地基之外时，可能无法正常退出交互状态，故在此打补丁
		else
			--Log("=== 离开了地基")
		end
	end
end

local function fnOnLeaveScene()
	--[[
		重要：
		1. 感觉最好让逻辑那边来做这样的处理（包括在离开地图、瞬间移动以及可能的退出游戏时），比如加一个开关告诉逻辑
		2. 真要坚持让UI来处理，那么还需要让逻辑加上保底措施，即————若某玩家离开了交互物体、但却未能成功地调用停止交互的接口，
			那么其他的玩家尝试交互时，需要能够成功地交互，比如说当目前占据着数据位的玩家已经不在物件附近时，则将对应玩家的数据强制清除
			（但是这又会涉及到函数 GetLOSlot()，难道要让逻辑在这个函数的判断里做清除数据的事情？）
	--]]
	local player = GetClientPlayer()
	if not player or player.dwID == arg0 then
		fnForceQuitInteraction()

		m_tSlotTransformReqInfo = {}
	end
end

Event.Reg(LandObject, "HOME_LAND_OPERATE_OBJECT", fnOnOperateHomelandObject)
Event.Reg(LandObject, "CALL_FOR_CHANGE_LO_DATA", fnOnChangeLOData)

Event.Reg(LandObject, "SlotIn", fnOnSlotIn)
Event.Reg(LandObject, "SlotOut", fnOnSlotOut)

Event.Reg(LandObject, "HOME_LAND_RESULT_CODE_INT", fnOnHomeRetCodeInt)

Event.Reg(LandObject, EventType.OnClientPlayerLeave, fnOnLeaveScene)

----------------------------- 对外接口 ----------------------------------


function LandObject_GetObjIDFromLandIndexAndInstID(nLandIndex, nInstID)
	local bignumber = math.pow(2, 32)
	return nLandIndex * bignumber + nInstID
end

function LandObject_GetLandIndexAndInstIDFromObjID(dwObjID)
	return _GetBaseIdAndInstID(dwObjID)
end

-- vObjPos: {x1, y1, z1};
-- vPlayerPos: {x2, y2, z2};
-- nMaxDist: 单位：cm
-- 除以64，得到"尺"，也就是"米"
function LandObject_IsObjTooFarFromPlayer(vObjPos, vPlayerPos, nMaxDist)
	return GetLogicDist(vObjPos, vPlayerPos) / 64 > nMaxDist / 100
end

local m_tRemoteData ={
	nLandIndex = 0,
	nInstID = 0,
	dwNpcID = 0,
	nSlotIndex = 0,
	nActionID = 0,
	dwBeginCallIDForGetSlotInfo = -1,
	dwEndCallIDForGetSlotInfo = -1,

	tAllSlotInfoForRemote =
	{
		--[nSlotIndex] = {x, y, z, angle},
	},
}

local function _fnOnGetCallResult()
	local eOperationType = arg0
	local userdata = arg1
	if eOperationType == HOMELAND_BUILD_OP.GET_SLOT_TRANSFORM then
		local dwCallID = userdata
		if dwCallID >= m_tRemoteData.dwBeginCallIDForGetSlotInfo and dwCallID <= m_tRemoteData.dwEndCallIDForGetSlotInfo then
			if dwCallID == m_tRemoteData.dwBeginCallIDForGetSlotInfo then
				m_tRemoteData.tAllSlotInfoForRemote = {}
			end

			if m_tSlotTransformReqInfo[dwCallID] then
				local nLandIndex, nInstID, nSlotIndex = m_tSlotTransformReqInfo[dwCallID][1], m_tSlotTransformReqInfo[dwCallID][2],
				m_tSlotTransformReqInfo[dwCallID][3]
				local bResult, nSlotX, nSlotY, nSlotZ, fAngle = arg2, arg3, arg4, arg5, arg6
				if bResult then
					m_tRemoteData.tAllSlotInfoForRemote[nSlotIndex] = { nSlotX, nSlotY, nSlotZ, fAngle}
				else
					Log("ERROR! 取不到 " .. tostring(nSlotIndex) .. " 号Slot的位置信息！")
				end
			end

			if dwCallID == m_tRemoteData.dwEndCallIDForGetSlotInfo then
				RemoteCallToServer("On_NPCServant_GetSlotInfo", m_tRemoteData.tAllSlotInfoForRemote, m_tRemoteData.nLandIndex,
						m_tRemoteData.nInstID, m_tRemoteData.dwNpcID, m_tRemoteData.nSlotIndex, m_tRemoteData.nActionID)
				m_tRemoteData.nLandIndex = 0
				m_tRemoteData.nInstID = 0
				m_tRemoteData.dwNpcID = 0
				m_tRemoteData.nSlotIndex = 0
				m_tRemoteData.nActionID = 0
			end
		end
	end
	fnOnGetCallResult()
end

Event.Reg(LandObject, "HOMELAND_CALL_RESULT", _fnOnGetCallResult)

function LandObject_RequestAllSlotTransformInfo(nLandIndex, nInstID, dwNpcID, nSlotIndex, nActionID)
	m_tRemoteData.nLandIndex = nLandIndex
	m_tRemoteData.nInstID = nInstID
	m_tRemoteData.dwNpcID = dwNpcID
	m_tRemoteData.nSlotIndex = nSlotIndex
	m_tRemoteData.nActionID = nActionID

	local hlMgr = GetHomelandMgr()
	local scene = GetClientScene()
	local dwMapID, nCopyIndex = scene.dwMapID, scene.nCopyIndex
	local nSlotCnt = hlMgr.GetLandObjectCount(dwMapID, nCopyIndex, nLandIndex, nInstID, LAND_OBJECT_TYPE.SLOT)

	for nTheSlotIndex = 1, nSlotCnt do
		local dwCallID = _GetNewCallID()
		if nTheSlotIndex == 1 then
			m_tRemoteData.dwBeginCallIDForGetSlotInfo = dwCallID
		end
		if nTheSlotIndex == nSlotCnt then
			m_tRemoteData.dwEndCallIDForGetSlotInfo = dwCallID
		end

		m_tSlotTransformReqInfo[dwCallID] = { nLandIndex,nInstID,nTheSlotIndex }
		Homeland_SendMessage(HOMELAND_BUILD_OP.GET_SLOT_TRANSFORM, nLandIndex, nInstID, nTheSlotIndex, dwCallID)
	end
end

function LandObject_GetObjectTPPos(nLandIndex, nInstID)
	if nLandIndex == m_nLandIndex and nInstID == m_nInstID then
		RemoteCallToServer("On_HomeLand_DelayTransmit", m_dwTPPosX, m_dwTPPosY, m_dwTPPosZ)
	end
end
----------------------------- 测试用 ----------------------------------

_G.ShowOnelinedLog = _ShowOnelinedLog_Dev

function LandObject_EnableLog(bEnable)
	m_bShowLog = bEnable
end

function LandObject_EnableMenu(bEnable)
	m_bShowInteractMenu = bEnable
end

function LandObject_IsInInteraction()
	return m_bInInteraction
end

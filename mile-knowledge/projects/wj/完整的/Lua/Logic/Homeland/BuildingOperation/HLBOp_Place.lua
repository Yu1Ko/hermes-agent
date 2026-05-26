
NewModule("HLBOp_Place")


m_bStartPlace = false --是不是开始移动了
m_bPrePlaceSuccess = false --上一次放置的位置是不是合法
m_tAddConsumption = {} --用于更新数量

--CREATE_ITEM--
m_nCreateObjID = 0
m_nRotateAngle = 0

--BLUEPRINT_PART--
m_nBlueprintObjID = 0

--MOVE_ITEM--
m_nMoveObjID = 0

--COPY--
m_nCopyObjID = 0

---表现UserData----
local PLACE_TYPE = {
	CREATE_ITEM = 1,
	BLUEPRINT_PART = 2,
	MOVE_ITEM = 3,
	COPY = 4
}

local END_TYPE = {
    CANCEL = 5,
}

---------------------------发送消息v--------------------------
function CreateItem(nModelID)
	HLBOp_Step.StartOneStep("CreateItem")

	m_nCreateObjID = 0
	m_tAddConsumption = {}

	local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.CREATE, nModelID, PLACE_TYPE.CREATE_ITEM)
	Homeland_Log("发送HOMELAND_BUILD_OP.CREATE", nModelID, bResult)
	if bResult then
		m_tAddConsumption = {{nModelID = nModelID, nModelAmount = 1}}
	end
end

function StartItemPlace(dwObjID)
	HLBOp_Select.ClearSelect()
	HLBOp_Select.SetItemSelect(dwObjID) --勾边
	m_bPrePlaceSuccess = false
	m_nCreateObjID = dwObjID
	m_nMoveObjID = dwObjID
	local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.START_PLACE, dwObjID, PLACE_TYPE.CREATE_ITEM)
	Homeland_Log("发送HOMELAND_BUILD_OP.START_PLACE Item", dwObjID, bResult)

	local nCenterX, nCenterY = Homeland_GetCenterScreenPosInPixels()
	Homeland_SendMessage(HOMELAND_BUILD_OP.PLACE, dwObjID, nCenterX, nCenterY, 0)
end

function StartCopyPlace(dwObjID, tAddConsumption)
	HLBOp_Select.ClearSelect()
	HLBOp_Select.SetItemSelect(dwObjID) --勾边
	m_bPrePlaceSuccess = false
	m_nCopyObjID = dwObjID
	m_nMoveObjID = dwObjID
	m_tAddConsumption = tAddConsumption
	local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.START_PLACE, dwObjID, PLACE_TYPE.COPY)
	Homeland_Log("发送HOMELAND_BUILD_OP.START_PLACE Copy", dwObjID, bResult)
end

function StartBlueprintPartPlace(dwObjID, tAddConsumption)
	HLBOp_Select.ClearSelect()
	HLBOp_Select.SetItemSelect(dwObjID) --勾边
	m_bPrePlaceSuccess = false
	m_nBlueprintObjID = dwObjID
	m_tAddConsumption = tAddConsumption
	local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.START_PLACE, dwObjID, PLACE_TYPE.BLUEPRINT_PART)
	Homeland_Log("发送HOMELAND_BUILD_OP.START_PLACE BlueprintPart", dwObjID, bResult)

	local nCenterX, nCenterY = Homeland_GetCenterScreenPosInPixels()
	Homeland_SendMessage(HOMELAND_BUILD_OP.PLACE, dwObjID, nCenterX, nCenterY, 0)
end

function StartMoveItem(dwObjID)
	HLBOp_Rotate.BackObjAngle(dwObjID)
	FireUIEvent("LUA_HOMELAND_CLOSE_ITEMOP")
	HLBOp_Step.StartOneStep("MoveItem")
	m_bPrePlaceSuccess = false
	m_nMoveObjID = dwObjID
	local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.START_PLACE, dwObjID, PLACE_TYPE.MOVE_ITEM)
	Homeland_Log("发送HOMELAND_BUILD_OP.START_PLACE MOVE", dwObjID, bResult)
end

function MoveObjPosByCursor()
	local nCursorX, nCursorY = Homeland_GetTouchingPosInPixels()
	local nObjID = 0
	if m_nCreateObjID ~= 0 then
		nObjID = m_nCreateObjID
	elseif m_nBlueprintObjID ~= 0 then
		nObjID = m_nBlueprintObjID
	elseif m_nCopyObjID ~= 0 then
		nObjID = m_nCopyObjID
	elseif m_nMoveObjID ~= 0 then
		nObjID = m_nMoveObjID
	end
	local bSuccess = Homeland_SendMessage(HOMELAND_BUILD_OP.PLACE, nObjID, nCursorX, nCursorY, 0)
end

function ConfirmPlace()
	if m_bStartPlace and m_bPrePlaceSuccess then
		if m_nBlueprintObjID ~= 0 then
			HLBOp_Main.SetModified(true)
			EndPlace(m_nBlueprintObjID, PLACE_TYPE.BLUEPRINT_PART, true)
			HLBOp_Step.EndOneStep()
		elseif m_nCreateObjID ~= 0 then
			HLBOp_Main.SetModified(true)
			EndPlace(m_nCreateObjID, PLACE_TYPE.CREATE_ITEM, true)
			HLBOp_Step.EndOneStep()
		elseif m_nCopyObjID ~= 0 then
			HLBOp_Main.SetModified(true)
			EndPlace(m_nCopyObjID, PLACE_TYPE.COPY, true)
			HLBOp_Step.EndOneStep()
		elseif m_nMoveObjID ~= 0 then
			HLBOp_Main.SetModified(true)
			EndPlace(m_nCreateObjID, PLACE_TYPE.MOVE_ITEM, true)
			HLBOp_Step.EndOneStep()
		end
	elseif m_bStartPlace and (not m_bPrePlaceSuccess) then
		HLBView_Message.Show(g_tStrings.STR_HOMELAND_BUILDING_CANT_PLACE_OBJECT_HERE, 3)
	end
end

function CancelPlace()
	if m_bStartPlace then
		if m_nBlueprintObjID ~= 0 then
			EndPlace(m_nBlueprintObjID, END_TYPE.CANCEL, false)
			HLBOp_Step.ClearCurStep()
		elseif m_nCreateObjID ~= 0 then
			EndPlace(m_nCreateObjID, END_TYPE.CANCEL, false)
			HLBOp_Step.ClearCurStep()
		elseif m_nMoveObjID ~= 0 then
			EndPlace(m_nMoveObjID, END_TYPE.CANCEL, false)
			HLBOp_Step.ClearCurStep()
		elseif m_nCopyObjID ~= 0 then
			EndPlace(m_nCopyObjID, END_TYPE.CANCEL, false)
			HLBOp_Step.ClearCurStep()
		end
	end
end

function EndPlace(dwObjID, nType, bSuccess)
	local nSuccess = bSuccess and 1 or 0
	m_bStartPlace = false
	local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.END_PLACE, dwObjID, nSuccess, nType)
	Homeland_Log("发送HOMELAND_BUILD_OP.END_PLACE", dwObjID, nSuccess, bResult, nType)
	HLBOp_Select.ClearSelect()
end

function OnEvent(szEvent)
	if szEvent == "HOMELAND_CALL_RESULT" then
		local eOperationType = arg0
		if eOperationType == HOMELAND_BUILD_OP.CREATE then
			OnCreateItemResult()
		elseif eOperationType == HOMELAND_BUILD_OP.START_PLACE then
			OnStartPlaceResult()
		elseif eOperationType == HOMELAND_BUILD_OP.PLACE then
			OnMovePlaceResult()
		elseif eOperationType == HOMELAND_BUILD_OP.END_PLACE then
			OnEndPlaceResult()
		end
	elseif szEvent == "LUA_HOMELAND_INTERACTABLE_ERROR" then
        OnInteractError()
	end
end

---------------------------接收消息v--------------------------

function OnCreateItemResult()
	local nUserData = arg1
	local bResult = Homeland_ToBoolean(arg2)
	local dwObjID = arg3
	Homeland_Log("收到HOMELAND_BUILD_OP.CREATE", dwObjID, bResult, nUserData)

	if not bResult then
		m_tAddConsumption = {}
		m_nCreateObjID = 0
		return
	end
	if nUserData == PLACE_TYPE.CREATE_ITEM then
		StartItemPlace(dwObjID)
		HLBOp_Amount.RefreshInteractInfo() --检查存盘数据溢出
	end
end

function OnStartPlaceResult()
	local nUserData = arg1
	local bResult = Homeland_ToBoolean(arg2)
	Homeland_Log("收到HOMELAND_BUILD_OP.START_PLACE", bResult, nUserData)

	if not bResult then
		m_bStartPlace = false
		m_bPrePlaceSuccess = false
		m_nCreateObjID = 0
		m_nCopyObjID = 0
		if m_nMoveObjID ~= 0 then
			HLBOp_Step.EndOneStep()
		end
		m_nMoveObjID = 0
		HLBView_Message.Show(g_tStrings.STR_HOMELAND_BUILDING_CANT_PICK_UP_ITEM, 3)
		return
	end

	if nUserData == PLACE_TYPE.CREATE_ITEM then
		m_bStartPlace = true
	elseif nUserData == PLACE_TYPE.BLUEPRINT_PART then
		m_bStartPlace = true
	elseif nUserData == PLACE_TYPE.MOVE_ITEM then
		m_bStartPlace = true
	elseif nUserData == PLACE_TYPE.COPY then
		m_bStartPlace = true
	end
end

function OnMovePlaceResult()
	local nUserData = arg1
	local nResult = arg2 -- 适用于大部分，但有些并非如此
	local bResult = Homeland_ToBoolean(nResult)
	m_bPrePlaceSuccess = bResult
end

function OnEndPlaceResult()
	local nUserData = arg1
	local nPhase = arg2
	if nPhase == 0 then
		local bResult = Homeland_ToBoolean(arg3)
		Homeland_Log("收到HOMELAND_BUILD_OP.END_PLACE", nUserData, bResult)
		if not bResult then
			m_tAddConsumption = {}
		end
		m_nRotateAngle = nil
	elseif nPhase == 1 then
		UILog("不会走入")
	elseif nPhase == 2 then
		local dwObjID = 0
		local dwModelID = 0
		if nUserData == PLACE_TYPE.CREATE_ITEM or nUserData == PLACE_TYPE.COPY then
			if HLBOp_Check.CheckAdd(m_tAddConsumption) then
				Homeland_Log("OnEndPlaceResult")
				dwModelID = m_tAddConsumption[1].nModelID
				FireHelpEvent("OnFurniturePlace", m_tAddConsumption[1].nModelID)
			end
			HLBOp_Amount.ChangeLandData(m_tAddConsumption)
		end
		if nUserData == PLACE_TYPE.BLUEPRINT_PART then
			HLBOp_Amount.ChangeLandData(m_tAddConsumption)
		end
		if nUserData == PLACE_TYPE.CREATE_ITEM then
			dwObjID = m_nCreateObjID
		elseif nUserData == PLACE_TYPE.COPY then
			dwObjID = m_nCopyObjID
		end
		-- if dwObjID ~=0 then
		-- 	HLBOp_Select.SetItemSelect(dwObjID)
		-- end
		m_nBlueprintObjID = 0
		m_nCreateObjID = 0
		m_nCopyObjID = 0
		m_nMoveObjID = 0
		m_bStartPlace = false
		m_tAddConsumption = {}
		if (nUserData == PLACE_TYPE.CREATE_ITEM or nUserData == PLACE_TYPE.COPY) and dwObjID ~= 0 and dwModelID ~= 0 then
			local tInfo = FurnitureData.GetFurnInfoByModelID(dwModelID)
			if tInfo then
				local nNum = GetHomelandMgr().BuildGetFurnitureCanUse(tInfo.nFurnitureType, tInfo.dwFurnitureID)
				local nMode = HLBOp_Main.GetBuildMode()
				if nMode == BUILD_MODE.DESIGN or nNum > 0 then
					HLBOp_Select.ClearSelect()
					-- HLBOp_Select.SetItemSelect(dwObjID)
					-- 移动端不需要自动复制
					-- HLBOp_SingleItemOp.CopyInPlace(dwModelID)
				end
			end
		end
	end
end

---------------------------API v--------------------------
function OnFrameBreathe()
	if m_bStartPlace and HLBOp_Main.GetMoveObjEnabled() then
		MoveObjPosByCursor()
	end
end

function OnInteractError()
	CancelPlace()
end
function GetBlueprintObjID()
	return m_nBlueprintObjID
end
function IsMoveObj()
	return m_nMoveObjID ~= 0
end

function Init()
	m_bStartPlace = false
	m_bPrePlaceSuccess = false
	m_tAddConsumption = {}
	m_nCreateObjID = 0
	m_nBlueprintObjID = 0
	m_nMoveObjID = 0
	m_nCopyObjID = 0
	m_nRotateAngle = nil
end

function UnInit()
	m_bStartPlace = nil
	m_bPrePlaceSuccess = nil
	m_tAddConsumption = nil
	m_nCreateObjID = nil
	m_nBlueprintObjID = nil
	m_nMoveObjID = nil
	m_nCopyObjID = nil
	m_nRotateAngle = nil
end



NewModule("HLBOp_MultiItemOp")
m_tTempStore = {}

---表现UserData----
local START_TYPE = {
    MOVE = 1,
}

local END_TYPE = {
    MOVE = 1,
    CANCEL = 2,
}

local COPY_TYPE = {
    BATCH = 2,
}

local REPLACE_TYPE = { --会和别的脚本冲突
    MULTI = 2,
}

local BATCH_DESTROY_TYPE = {
    UPDATE_DATA = 1,
    NO_UPDATE_DATA = 2,
}

m_bMoveMulti = false
m_bPrePlaceSuccess = false
m_tAddConsumption = {}
m_tReplaceInfo = {}

---------------------------发送消息v--------------------------
function StartMove()
    local tSelectObjs = HLBOp_Select.GetSelectInfo()
    for i = 1, #tSelectObjs do
        local dwModelID = HLBOp_Amount.GetModelIDByObjID(tSelectObjs[i])
        if FurnitureData.IsAutoBottomBrush(dwModelID) then
            HLBView_Message.Show(g_tStrings.STR_HOMELAND_BUILDING_CANT_MOVE_MULTI_ITEMS, 3)
            return
        end
    end
    HLBOp_Step.StartOneStep("MoveMultiObj")
    FireUIEvent("LUA_HOMELAND_CLOSE_ITEMOP")
    local nCursorX, nCursorY = Homeland_GetTouchingPosInPixels()
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.START_MULTI_EDIT, nCursorX, nCursorY, START_TYPE.MOVE)
    HLBOp_Other.SetGridAlignment(false)
    Homeland_Log("发送HOMELAND_BUILD_OP.START_MULTI_EDIT", bResult)
end

function StartCopyMove()
    --记录一下消耗
    local tObjIDs = HLBOp_Select.GetSelectInfo()
    m_tAddConsumption = {}
    for i = 1, #tObjIDs do
        table.insert(m_tAddConsumption, {dwObjID = tObjIDs[i], nModelAmount = 1})
    end

    local nCursorX, nCursorY = Homeland_GetCursorPosInPixels()
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.START_MULTI_EDIT, nCursorX, nCursorY, START_TYPE.MOVE)
    HLBOp_Other.SetGridAlignment(false)
    Homeland_Log("发送HOMELAND_BUILD_OP.START_MULTI_EDIT", bResult)
end

function Move(nX, nY)
    local nCursorX, nCursorY = Homeland_GetCursorPosInPixelsByPos(nX, nY)
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.MULTI_PLACE, nCursorX, nCursorY, 0)
end

function ConfirmPlace()
    if m_bMoveMulti and m_bPrePlaceSuccess then
        HLBOp_Main.SetModified(true)
        local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.END_MULTI_EDIT, END_TYPE.MOVE)
        Homeland_Log("发送HOMELAND_BUILD_OP.END_MULTI_EDIT", bResult)
        HLBOp_Other.SetGridAlignment(g_HomelandBuildingData.bGridAlignEnabled)
        local tModelCount = {}
        for i = 1, #m_tAddConsumption do
            local tInfo = m_tAddConsumption[i]
            local nModelID = HLBOp_Amount.GetModelIDByObjID(tInfo.dwObjID)
            if not tModelCount[nModelID] then
                tModelCount[nModelID] = 0
            end
            tModelCount[nModelID] = tModelCount[nModelID] + 1
        end
        m_tAddConsumption = {}
        for k, v in pairs(tModelCount) do
            table.insert(m_tAddConsumption, {nModelID = k, nModelAmount = v})
        end
        if HLBOp_Check.CheckAdd(m_tAddConsumption) then
            Homeland_Log("ConfirmPlace")
        end
        HLBOp_Amount.ChangeLandData(m_tAddConsumption)
        HLBOp_Step.EndOneStep()
        m_tAddConsumption = {}
        m_bMoveMulti = false
    elseif m_bMoveMulti and (not m_bPrePlaceSuccess) then
		HLBView_Message.Show(g_tStrings.STR_HOMELAND_BUILDING_CANT_PLACE_OBJECT_HERE, 3)
    end
end

function CancelPlace()
    if m_bMoveMulti then
        local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.END_MULTI_EDIT, END_TYPE.CANCEL)
        HLBOp_Other.SetGridAlignment(g_HomelandBuildingData.bGridAlignEnabled)
        Homeland_Log("发送HOMELAND_BUILD_OP.END_MULTI_EDIT", bResult)
        m_bMoveMulti = false
        m_tAddConsumption = {}
        HLBOp_Step.ClearCurStep()
    end
end

function Destroy()
    HLBOp_Main.SetModified(true)
    HLBOp_Step.StartOneStep("DestroyMultiObj")
    -- local nCursorX, nCursorY = Homeland_GetCursorPosInPixels()
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.BATCH_DESTROY, BATCH_DESTROY_TYPE.UPDATE_DATA)
    Homeland_Log("发送HOMELAND_BUILD_OP.BATCH_DESTROY UPDATE_DATA", bResult)
    HLBOp_Step.EndOneStep()
    HLBOp_Select.ClearSelect()
end

function DestroyWithoutUpdateData()
    HLBOp_Main.SetModified(true)
    HLBOp_Step.StartOneStep("DestroyMultiObj")
    -- local nCursorX, nCursorY = Homeland_GetCursorPosInPixels()
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.BATCH_DESTROY, BATCH_DESTROY_TYPE.NO_UPDATE_DATA)
    Homeland_Log("发送HOMELAND_BUILD_OP.BATCH_DESTROY NO_UPDATE_DATA", bResult)
    HLBOp_Step.EndOneStep()
    HLBOp_Select.ClearSelect()
end

function Copy()
    HLBOp_Step.StartOneStep("CopyMultiObj")
    local nCursorX, nCursorY = Homeland_GetCenterScreenPosInPixels()
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.COPY, nCursorX, nCursorY, COPY_TYPE.BATCH)
end

function Replace(dwSrcModelID, dwDstModelID)
    HLBOp_Main.SetModified(true)
    HLBOp_Step.StartOneStep("ReplaceMulti")
    local nInAll = 1
    m_tReplaceInfo = {dwSrcModelID = dwSrcModelID, dwDstModelID = dwDstModelID}
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.SWITCH_RLID, dwSrcModelID, dwDstModelID, nInAll, REPLACE_TYPE.MULTI)
    Homeland_Log("发送HOMELAND_BUILD_OP.SWITCH_RLID", dwSrcModelID, dwDstModelID, nInAll, bResult)
    HLBOp_Step.EndOneStep()
end

function Dye(nColorIndex)
    HLBOp_Main.SetModified(true)
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.MULTI_SET_DETAIL, nColorIndex, 0)
    Homeland_Log("发送HOMELAND_BUILD_OP.MULTI_SET_DETAIL", nColorIndex, bResult)
end

function Scale(fScale)
    HLBOp_Main.SetModified(true)
    local tObjIDs = HLBOp_Select.GetSelectInfo()
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.MULTI_SCALE, fScale, 0)
    Homeland_Log("发送HOMELAND_BUILD_OP.MULTI_SCALE", fScale, bResult)
end

function OnEvent(szEvent)
	if szEvent == "HOMELAND_CALL_RESULT" then
		local eOperationType = arg0
		if eOperationType == HOMELAND_BUILD_OP.START_MULTI_EDIT then
            OnStartMultiEditResult()
        elseif eOperationType == HOMELAND_BUILD_OP.MULTI_PLACE then
            OnMultiPlaceResult()
        elseif eOperationType == HOMELAND_BUILD_OP.END_MULTI_EDIT then

        elseif eOperationType == HOMELAND_BUILD_OP.BATCH_DESTROY then
            OnBatchDestroyResult()
        elseif eOperationType == HOMELAND_BUILD_OP.COPY then
            OnCopyResult()
        elseif eOperationType == HOMELAND_BUILD_OP.SWITCH_RLID then
            OnReplaceResult()
        elseif eOperationType == HOMELAND_BUILD_OP.MULTI_SET_DETAIL then
            OnDyeResult()
        elseif eOperationType == HOMELAND_BUILD_OP.MULTI_SCALE then
            OnScaleResult()
		end
    elseif szEvent == "LUA_HOMELAND_INTERACTABLE_ERROR" then
        OnInteractError()
	end
end

---------------------------接收消息v--------------------------
function OnStartMultiEditResult()
    local nUserData = arg1
	local nResult = arg2
    local bResult = Homeland_ToBoolean(nResult)
    if not bResult then
        return
    end

    if nUserData == START_TYPE.MOVE then
        m_bMoveMulti = true
    end
end

function OnMultiPlaceResult()
    local nUserData = arg1
	local nResCode = arg2
    local nSameWithLastTime = 1
	local bSuccess = (nResCode == 0)
    if nResCode ~= nSameWithLastTime then
        m_bPrePlaceSuccess = bSuccess
    end
end

function OnBatchDestroyResult()
    local nUserData = arg1
	local nPhase = arg2
    if nPhase == 0 then
		local bResult = Homeland_ToBoolean(arg3)
		Homeland_Log("收到HOMELAND_BUILD_OP.BATCH_DESTROY", bResult)
        m_tTempStore = {}
	elseif nPhase == 1 then
        local bDel = true
        Homeland_StoreConsumption(m_tTempStore, bDel)
	elseif nPhase == 2 then
        Homeland_Log("OnBatchDestroyResult")
        if nUserData == BATCH_DESTROY_TYPE.UPDATE_DATA then
            HLBOp_Amount.ChangeLandData(m_tTempStore)
            HLBOp_Group.RequestAllGroupIDs()
        end
        m_tTempStore = {}
	end
end

function OnCopyResult()
    local nUserData = arg1
	local nPhase = arg2
    if nPhase == 0 then
		local nResCode = arg3
		local bResult = nResCode == 0
		Homeland_Log("收到HOMELAND_BUILD_OP.COPY", bResult)
        local szErrorMsg = g_tStrings.tHomelandCopyErrorString[nResCode]
        if szErrorMsg then
            HLBView_Message.Show(szErrorMsg, 3)
        end
        m_tTempStore = {}
	elseif nPhase == 1 then
        Homeland_StoreObjID(m_tTempStore)
	elseif nPhase == 2 then
        if nUserData == COPY_TYPE.BATCH then
            HLBOp_Select.SetOutLine(m_tTempStore)
            StartCopyMove()
            HLBOp_Amount.RefreshInteractInfo()
            HLBOp_Amount.RequestAllObject()
        end
        m_tTempStore = {}
	end
end

function OnReplaceResult()
	local nUserData = arg1
	local nReplaceResCode = arg2
    local bResult = (nReplaceResCode == 0)
    local nSwitchedCount = arg3
    if nUserData ~= REPLACE_TYPE.MULTI then
        return
    end
    Homeland_Log("收到HOMELAND_BUILD_OP.SWITCH_RLID", bResult, nSwitchedCount)
    if not bResult then
        local szErrorMsg = g_tStrings.tHomelandSwitchRLIDErrorString[nReplaceResCode]
        if szErrorMsg then
            HLBView_Message.Show(szErrorMsg, 3)
        end
        return
    end
    FireUIEvent("LUA_HOMELAND_REPLACE_SUCCESS")
    if nUserData == REPLACE_TYPE.MULTI and nSwitchedCount > 0 then
        Homeland_Log("OnReplaceResult")
        HLBOp_Amount.ChangeLandDataFromReplace(m_tReplaceInfo.dwSrcModelID, m_tReplaceInfo.dwDstModelID, nSwitchedCount)
        m_tReplaceInfo = {}
    end
end

function OnDyeResult()
    local nUserData = arg1
	local nResult = arg2
    local bResult = Homeland_ToBoolean(nResult)
    Homeland_Log("收到HOMELAND_BUILD_OP.MULTI_SET_DETAIL", bResult)
end

function OnScaleResult()
    local nResult = arg2
	local bResult = Homeland_ToBoolean(nResult)
    Homeland_Log("收到HOMELAND_BUILD_OP.MULTI_SCALE", bResult)
end

---------------------------API v--------------------------
function OnFrameBreathe()
    if m_bMoveMulti and HLBOp_Main.GetMoveObjEnabled() then
        if HomelandBuildData.GetInputType() == HLB_INPUT_TYPE.MAK then
            local tCursor = GetViewCursorPoint()
            Move(tCursor.x, tCursor.y)
        end
    end
end

function OnInteractError()
    CancelPlace()
end

function IsMoveObj()
    return m_bMoveMulti
end

function SetMoveObj(bMove)
    m_bMoveMulti = bMove
end

function Init()
    m_bMoveMulti = false
    m_bPrePlaceSuccess = false
    m_tAddConsumption = {}
    m_tReplaceInfo = {}
end

function UnInit()
    m_bMoveMulti = nil
    m_bPrePlaceSuccess = nil
    m_tAddConsumption = nil
    m_tReplaceInfo = nil
end


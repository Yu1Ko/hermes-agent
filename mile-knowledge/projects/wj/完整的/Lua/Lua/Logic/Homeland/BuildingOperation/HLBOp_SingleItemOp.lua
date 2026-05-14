
NewModule("HLBOp_SingleItemOp")

local COPY_TYPE = {
    NORMAL = 1,
}

local REPLACE_TYPE = {
    SINGLE = 1
}

local DESTROY_TYPE = {
    NORMAL = 1,
}

m_tTempStore = {}
m_tReplaceInfo = {}
m_tAddConsumption = {}
---------------------------发送消息v--------------------------
function Destroy(dwObjID)
    HLBOp_Main.SetModified(true)
    HLBOp_Step.StartOneStep("DestroyObj")
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.DESTROY, dwObjID, DESTROY_TYPE.NORMAL)
    Homeland_Log("发送HOMELAND_BUILD_OP.DESTROY", dwObjID, bResult)
    HLBOp_Step.EndOneStep()
    HLBOp_Select.ClearSelect()
end

function Copy()
    local tSelectObjs = HLBOp_Select.GetSelectInfo()
    if #tSelectObjs == 1 then
        HLBOp_Rotate.BackObjAngle(tSelectObjs[1])
    end
    HLBOp_Step.StartOneStep("CopyObj")
    --记录一下消耗
    local tObjIDs = HLBOp_Select.GetSelectInfo()
    m_tAddConsumption = {}
    for i = 1, #tObjIDs do
        table.insert(m_tAddConsumption, {nModelID = HLBOp_Amount.GetModelIDByObjID(tObjIDs[i]), nModelAmount = 1})
    end
    local nCursorX, nCursorY = Homeland_GetCenterScreenPosInPixels()
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.COPY, nCursorX, nCursorY, COPY_TYPE.NORMAL)
    Homeland_Log("发送HOMELAND_BUILD_OP.COPY", bResult)
end

function CopyInPlace(dwModelID)
    local tSelectObjs = HLBOp_Select.GetSelectInfo()
    if #tSelectObjs == 1 then
        HLBOp_Rotate.BackObjAngle(tSelectObjs[1])
    end
    HLBOp_Step.StartOneStep("CopyObj")
    --记录一下消耗
    local tObjIDs = HLBOp_Select.GetSelectInfo()
    m_tAddConsumption = {{nModelID = dwModelID, nModelAmount = 1}}
    local nCursorX, nCursorY = Homeland_GetCenterScreenPosInPixels()
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.COPY, nCursorX, nCursorY, COPY_TYPE.NORMAL)
    Homeland_Log("发送HOMELAND_BUILD_OP.COPY", bResult)
end

function Replace(dwSrcModelID, dwDstModelID)
    HLBOp_Main.SetModified(true)
    HLBOp_Step.StartOneStep("ReplaceSingle")
    local nInAll = 0
    m_tReplaceInfo = {dwSrcModelID = dwSrcModelID, dwDstModelID = dwDstModelID}
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.SWITCH_RLID, dwSrcModelID, dwDstModelID, nInAll, REPLACE_TYPE.SINGLE)
    Homeland_Log("发送HOMELAND_BUILD_OP.SWITCH_RLID", dwSrcModelID, dwDstModelID, nInAll, bResult)
    HLBOp_Step.EndOneStep()
end

function Scale(fScale, nType)
    HLBOp_Main.SetModified(true)
    local tObjIDs = HLBOp_Select.GetSelectInfo()
    local nCurType = HOMELAND_SCALE_TYPE.NORMAL
    if nType then
        nCurType = nType
    end
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.SCALE, tObjIDs[1], fScale, 0, nCurType, tObjIDs[1])
    Homeland_Log("发送HOMELAND_BUILD_OP.SCALE", tObjIDs[1], fScale, bResult)
end

function Dye(nColorIndex)
    HLBOp_Main.SetModified(true)
    local tObjIDs = HLBOp_Select.GetSelectInfo()
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.SET_DETAIL, tObjIDs[1], nColorIndex, tObjIDs[1])
    Homeland_Log("发送HOMELAND_BUILD_OP.SET_DETAIL", tObjIDs[1], nColorIndex, bResult)
end

function SetObjLocalPos(nType, nPos)
    HLBOp_Main.SetModified(true)
    local tObjIDs = HLBOp_Select.GetSelectInfo()
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.SET_OBJ_LOCAL_POS, tObjIDs[1], nType, nPos, tObjIDs[1])
    Homeland_Log("发送HOMELAND_BUILD_OP.SET_OBJ_LOCAL_POS", tObjIDs[1], nType, nPos, bResult)
end

function OnEvent(szEvent)
	if szEvent == "HOMELAND_CALL_RESULT" then
		local eOperationType = arg0
		if eOperationType == HOMELAND_BUILD_OP.DESTROY then
            OnDestroyResult()
        elseif eOperationType == HOMELAND_BUILD_OP.COPY then
            OnCopyResult()
        elseif eOperationType == HOMELAND_BUILD_OP.SWITCH_RLID then
            OnReplaceResult()
        elseif eOperationType == HOMELAND_BUILD_OP.SCALE then
            OnScaleResult()
        elseif eOperationType == HOMELAND_BUILD_OP.SET_DETAIL then
            OnDyeResult()
        elseif eOperationType == HOMELAND_BUILD_OP.SET_OBJ_LOCAL_POS then
            OnSetObjLocalPosResult()
		end
    elseif szEvent == "LUA_HOMELAND_INTERACTABLE_ERROR" then
        OnInteractError()
	end
end

---------------------------接收消息v--------------------------
function OnDestroyResult()
    local nUserData = arg1
	local nPhase = arg2
    if nPhase == 0 then
		local bResult = Homeland_ToBoolean(arg3)
		Homeland_Log("收到HOMELAND_BUILD_OP.DESTROY", bResult)
        m_tTempStore = {}
	elseif nPhase == 1 then
        local bDel = true
        Homeland_StoreConsumption(m_tTempStore, bDel)
	elseif nPhase == 2 then
        Homeland_Log("OnDestroyResult")
        if nUserData == DESTROY_TYPE.NORMAL then
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
        if nUserData == COPY_TYPE.NORMAL then
            if #m_tTempStore > 0 then
                HLBOp_Place.StartCopyPlace(m_tTempStore[1], m_tAddConsumption)
                HLBOp_Amount.RefreshInteractInfo()
            end
        end
        m_tTempStore = {}
	end
end

function OnReplaceResult()
	local nUserData = arg1
    local nReplaceResCode = arg2
    local bResult = (nReplaceResCode == 0)
    local nSwitchedCount = arg3
    if nUserData ~= REPLACE_TYPE.SINGLE then
        return
    end

    Homeland_Log("收到HOMELAND_BUILD_OP.SWITCH_RLID", bResult)
    if not bResult then
        local szErrorMsg = g_tStrings.tHomelandSwitchRLIDErrorString[nReplaceResCode]
        if szErrorMsg then
            HLBView_Message.Show(szErrorMsg, 3)
        end
        return
    end
    FireUIEvent("LUA_HOMELAND_REPLACE_SUCCESS")
    if nUserData == REPLACE_TYPE.SINGLE and nSwitchedCount > 0 then
        Homeland_Log("OnReplaceResult")
        HLBOp_Amount.ChangeLandDataFromReplace(m_tReplaceInfo.dwSrcModelID, m_tReplaceInfo.dwDstModelID, nSwitchedCount)
        m_tReplaceInfo = {}
    end
end

function OnScaleResult()
    local nUserData = arg1
    local nScaleResCode = arg2
    local bResult = (nScaleResCode == 0)
    Homeland_Log("收到HOMELAND_BUILD_OP.SCALE", bResult)
    if not bResult then
        local szErrorMsg = g_tStrings.tHomelandScaleErrorString[nScaleResCode]
        if szErrorMsg then
            HLBView_Message.Show(szErrorMsg, 1)
        end
        return
    end
    local dwObjID = nUserData
    HLBOp_Other.GetObjectInfo(dwObjID)
end

function OnDyeResult()
    local nUserData = arg1
    local bResult = Homeland_ToBoolean(arg2)
    Homeland_Log("收到HOMELAND_BUILD_OP.SET_DETAIL", bResult)
    if not bResult then
        return
    end
    local dwObjID = nUserData
    HLBOp_Other.GetObjectInfo(dwObjID)
end

function OnSetObjLocalPosResult()
    local nUserData = arg1
    local bResult = Homeland_ToBoolean(arg2)
    Homeland_Log("收到HOMELAND_BUILD_OP.SET_OBJ_LOCAL_POS", bResult)
    if not bResult then
        return
    end
    local dwObjID = nUserData
    HLBOp_Other.GetObjectInfo(dwObjID)
end

---------------------------API v--------------------------

function OnInteractError()

end

function Init()
    m_tTempStore = {}
end

function UnInit()
    m_tTempStore = nil
end


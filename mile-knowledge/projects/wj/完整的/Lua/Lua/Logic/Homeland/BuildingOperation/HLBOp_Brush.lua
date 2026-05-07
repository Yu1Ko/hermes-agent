
NewModule("HLBOp_Brush")

---表现UserData---- 和HLBOp_Bottom共享
local CREATE_TYPE = {
    NORMAL = 1,
    BOTTOM = 2,
    USE_BOTTOM = 3,
}

local START_TYPE = {
    NORMAL = 1,
    USE_BOTTOM = 2,
}

local END_TYPE = {
    NORMAL = 1,
    CANCEL = 2,
    USE_BOTTOM = 3,
}

m_dwModelID = 0
m_bMoveBrush = false
m_tTempStore = {}
---------------------------发送消息v--------------------------
function SetBottomCount(nCount)
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.SET_AUTO_BOTTOM_BRUSH_COUNT, nCount, 0)
    Homeland_Log("发送HOMELAND_BUILD_OP.SET_AUTO_BOTTOM_BRUSH_COUNT", nCount, bResult)
end

function CreateBrush(dwModelID)
    local nFill = 0
    local nAvailableBrushCount = 40
    ClearData()

    m_dwModelID = dwModelID
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.CREATE_BRUSH, dwModelID, nFill, nAvailableBrushCount, CREATE_TYPE.NORMAL)
    Homeland_Log("发送HOMELAND_BUILD_OP.CREATE BRUSH", dwModelID, nFill, nAvailableBrushCount, bResult)
    SetBottomCount(0)

    FireUIEvent("LUA_HOMELAND_CREATE_BRUSH")
end

function MoveBrush()
    local nCursorX, nCursorY = Homeland_GetTouchingPosInPixels()
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.MOVE_BRUSH, nCursorX, nCursorY, 0)
end

function StartBrush()
    if m_bMoveBrush then
        HLBOp_Step.StartOneStep("StartBrush")
        local nCursorX, nCursorY = Homeland_GetTouchingPosInPixels()
        local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.START_BRUSH, nCursorX, nCursorY, START_TYPE.NORMAL)
        Homeland_Log("发送HOMELAND_BUILD_OP.START_BRUSH NORMAL", bResult)
    end
end

function EndBrush()
    if m_bMoveBrush then
        HLBOp_Main.SetModified(true)
        local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.END_BRUSH, END_TYPE.NORMAL)
        Homeland_Log("发送HOMELAND_BUILD_OP.END_BRUSH NORMAL", bResult)
        HLBOp_Step.EndOneStep()
    end
end

function EndBrushWithFail()
    if m_bMoveBrush then
        local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.END_BRUSH, END_TYPE.CANCEL)
        Homeland_Log("发送HOMELAND_BUILD_OP.END_BRUSH Fail", bResult)
        ClearData()
        FireUIEvent("LUA_HOMELAND_END_BRUSH")
    end
end

function CancelBrush()
    if m_bMoveBrush then
        local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.END_BRUSH, END_TYPE.CANCEL)
        Homeland_Log("发送HOMELAND_BUILD_OP.END_BRUSH CANCEL", bResult)
        FireUIEvent("LUA_HOMELAND_END_BRUSH")
    end
end

function IsMoveBrush()
    return m_bMoveBrush
end

function OnEvent(szEvent)
	if szEvent == "HOMELAND_CALL_RESULT" then
		local eOperationType = arg0
		if eOperationType == HOMELAND_BUILD_OP.CREATE_BRUSH then
            OnCreateBrushResult()
        elseif eOperationType == HOMELAND_BUILD_OP.MOVE_BRUSH then

        elseif eOperationType == HOMELAND_BUILD_OP.START_BRUSH then
            OnStartBrushResult()
        elseif eOperationType == HOMELAND_BUILD_OP.END_BRUSH then
            OnEndBrushResult()
		end
	end
end

---------------------------接收消息v--------------------------
function OnCreateBrushResult()
    local nUserData = arg1
	local nResult = arg2
	local bResult = Homeland_ToBoolean(nResult)
    Homeland_Log("收到HOMELAND_BUILD_OP.CREATE", nUserData, bResult)
    if not bResult then
        return
    end
    if nUserData == END_TYPE.NORMAL then
        m_bMoveBrush = true
    end
end

function OnStartBrushResult()
    local nUserData = arg1
	local nResult = arg2
	local bResult = Homeland_ToBoolean(nResult)
    Homeland_Log("收到HOMELAND_BUILD_OP.START_BRUSH", nUserData, bResult)

    if not bResult and nUserData == START_TYPE.NORMAL then
        EndBrushWithFail()
        m_bMoveBrush = false
        local scriptView = UIHelper.ShowConfirm(g_tStrings.STR_HOMELAND_BUILDING_START_BRUSH_FAILED)
        scriptView:HideButton("Cancel")
        return
    end
end

function OnEndBrushResult()
    local nUserData = arg1
    local nPhase = arg2
    if nPhase == 0 then
        local bResult = Homeland_ToBoolean(arg3)
        Homeland_Log("收到HOMELAND_BUILD_OP.END_BRUSH", nUserData, bResult)
        m_tTempStore = {}
	elseif nPhase == 1 then
        Homeland_StoreConsumption(m_tTempStore)
    elseif nPhase == 2 then
        local bAddSuccess = false
        if nUserData == END_TYPE.NORMAL then
            if HLBOp_Check.CheckAdd(m_tTempStore) then
                bAddSuccess = true
                Homeland_Log("OnEndBrushResult")
                local aModelIDs = {}
                for i = 1, #m_tTempStore do
                    table.insert(aModelIDs, m_tTempStore[i].nModelID)
                end
                FireHelpEvent("OnFurnitureBrushEnd", aModelIDs)
            end
            HLBOp_Amount.ChangeLandData(m_tTempStore)
        end
        if nUserData == END_TYPE.NORMAL then
            if bAddSuccess then
                CreateBrush(m_dwModelID)
            else
                EndBrushWithFail()
            end
        elseif nUserData == END_TYPE.CANCEL then
            ClearData()
        end
	end
end

---------------------------API v--------------------------
function OnFrameBreathe()
	if m_bMoveBrush and HLBOp_Main.GetMoveObjEnabled() then
        MoveBrush()
	end
end

function ClearData()
    Init()
end

function Init()
    m_dwModelID = 0
    m_bMoveBrush = false
    m_tTempStore = {}
end

function UnInit()
    m_dwModelID = 0
    m_bMoveBrush = nil
    m_tTempStore = nil
end


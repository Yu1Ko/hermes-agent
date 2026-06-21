
NewModule("HLBOp_CustomBrush")

---表现UserData----
local CREATE_TYPE = {
    CLEAR = 2,
    WIPE_ALL = 3,
}

local END_TYPE = {
    MOVE = 1,
    CANCEL = 2,
}

m_bStartMove = false
m_tCacheInfo = {}
m_bPreMoveSuccess = false

function CreateFlowerBrush(tInfo)
    local bResult = Homeland_SendMessage(unpack(tInfo))
    m_tCacheInfo = tInfo
    Homeland_Log("发送HOMELAND_BUILD_OP.USE_FOLIAGE_COVER_BRUSH", tInfo, bResult)
end

function CreateFloorBrush(tInfo)
    local bResult = Homeland_SendMessage(unpack(tInfo))
    m_tCacheInfo = tInfo
    Homeland_Log("发送HOMELAND_BUILD_OP.USE_APPLIQUE_BRUSH", tInfo)
end

function StartCustomBrush()
    if m_bStartMove and m_bPreMoveSuccess then
        local nCursorX, nCursorY = Homeland_GetTouchingPosInPixels()
        HLBOp_Main.SetModified(true)
        local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.START_CUSTOM_BRUSH, nCursorX, nCursorY, 0)
        Homeland_Log("发送HOMELAND_BUILD_OP.START_CUSTOM_BRUSH")
    elseif m_bStartMove and (not m_bPreMoveSuccess) then
    end
end

function MoveCustomBrush()
    if m_bStartMove then
        local nCursorX, nCursorY = Homeland_GetTouchingPosInPixels()
        local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.MOVE_CUSTOM_BRUSH, nCursorX, nCursorY, 0)
    end
end

function EndCustomBrush()
    if m_bStartMove then
        local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.END_CUSTOM_BRUSH, END_TYPE.MOVE)
        Homeland_Log("发送HOMELAND_BUILD_OP.END_CUSTOM_BRUSH MOVE", bResult)
    end
end

function CancelCustomBrush()
    if m_bStartMove then
        local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.END_CUSTOM_BRUSH, END_TYPE.CANCEL)
        Homeland_Log("发送HOMELAND_BUILD_OP.END_CUSTOM_BRUSH CANCEL", bResult)
    end
end

function CancelCustomBrushWithClear()
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.END_CUSTOM_BRUSH, END_TYPE.CANCEL)
    Homeland_Log("发送HOMELAND_BUILD_OP.END_CUSTOM_BRUSH CANCEL WithClear", bResult)
end

function DelSingleFlowerBrush(nFlowerBrushID)
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.CLEAR_FOLIAGE_COVER, nFlowerBrushID, 0)
    Homeland_Log("发送HOMELAND_BUILD_OP.CLEAR_FOLIAGE_COVER", nFlowerBrushID, bResult)
    HLBOp_Main.SetModified(true)
	HLBOp_Amount.RefreshCustomBrushData()
end

function DelFloorBrush(tFloorBrushID)
    if #tFloorBrushID == 0 then
		return
	end
	local tFloorBrushInfo = clone(HLBOp_Amount.GetRawFloorBrushInfo())
	for i = 1, #tFloorBrushInfo do
		for j = 1, #tFloorBrushID do
            local dwModelID = tFloorBrushInfo[i].nModelID
			if dwModelID == tFloorBrushID[j] then
				tFloorBrushInfo[i].nModelID = 0
			end
		end
	end
    --把ID置为0地上会取消
	local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.USE_APPLIQUE_BRUSH,
        1, tFloorBrushInfo[1].nModelID, 1, 4, tFloorBrushInfo[2].nModelID, 1, 4, tFloorBrushInfo[3].nModelID, 1, 4, CREATE_TYPE.CLEAR)
    Homeland_Log("发送HOMELAND_BUILD_OP.USE_APPLIQUE_BRUSH DelFloorBrush", tFloorBrushID, bResult)
end

function FullFillCustomBrush()
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.FULL_FILL_CUSTOM_BRUSH, 0)
    Homeland_Log("发送HOMELAND_BUILD_OP.FULL_FILL_CUSTOM_BRUSH", bResult)
end

function WipeAllFloorBrush()
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.USE_APPLIQUE_BRUSH, 1, 0, 1, 4, 0, 1, 4, 0, 1, 4, CREATE_TYPE.WIPE_ALL)
    Homeland_Log("发送HOMELAND_BUILD_OP.USE_APPLIQUE_BRUSH", bResult)
end

function OnEvent(szEvent)
	if szEvent == "HOMELAND_CALL_RESULT" then
		local eOperationType = arg0
		if eOperationType == HOMELAND_BUILD_OP.USE_FOLIAGE_COVER_BRUSH then
            OnCreateFlowerBrushResult()
        elseif eOperationType == HOMELAND_BUILD_OP.USE_APPLIQUE_BRUSH then
            OnCreateFloorBrushResult()
        elseif eOperationType == HOMELAND_BUILD_OP.START_CUSTOM_BRUSH then
            OnStartBrushResult()
        elseif eOperationType == HOMELAND_BUILD_OP.MOVE_CUSTOM_BRUSH then
            OnMoveBrushResult()
        elseif eOperationType == HOMELAND_BUILD_OP.END_CUSTOM_BRUSH then
            OnEndBrushResult()
        elseif eOperationType == HOMELAND_BUILD_OP.CLEAR_FOLIAGE_COVER then
            OnClearFlowerResult()
        elseif eOperationType == HOMELAND_BUILD_OP.FULL_FILL_CUSTOM_BRUSH then
            OnFullFillCustomBrushResult()
		end
	end
end

function OnCreateFlowerBrushResult()
	local nUserData = arg1
	local bResult = Homeland_ToBoolean(arg2)
    Homeland_Log("收到HOMELAND_BUILD_OP.USE_FOLIAGE_COVER_BRUSH", bResult)
    if not bResult then
        return
    end
    FireUIEvent("LUA_HOMELAND_CREATE_CUSTOM_BRUSH")
    m_bStartMove = true
end

function OnCreateFloorBrushResult()
    local nUserData = arg1
	local bResult = Homeland_ToBoolean(arg2)
    Homeland_Log("收到HOMELAND_BUILD_OP.USE_APPLIQUE_BRUSH", bResult)
    if nUserData == CREATE_TYPE.CLEAR then
        CancelCustomBrushWithClear()
        HLBOp_Main.SetModified(true)
        HLBOp_Amount.RefreshCustomBrushData()
    elseif nUserData == CREATE_TYPE.WIPE_ALL then
        HLBOp_Main.SetModified(true)
        HLBOp_Amount.RefreshCustomBrushData()
    else
        FireUIEvent("LUA_HOMELAND_CREATE_CUSTOM_BRUSH")
        m_bStartMove = true
    end
end

function OnStartBrushResult()
    local nUserData = arg1
	local bResult = Homeland_ToBoolean(arg2)
    Homeland_Log("收到HOMELAND_BUILD_OP.START_CUSTOM_BRUSH", bResult)
end

function OnMoveBrushResult()
    local nUserData = arg1
	local bResult = Homeland_ToBoolean(arg2)
    local bSuccess = Homeland_ToBoolean(arg3)
    m_bPreMoveSuccess = bSuccess
end

function OnEndBrushResult()
    local nUserData = arg1
	local bResult = Homeland_ToBoolean(arg2)
    Homeland_Log("收到HOMELAND_BUILD_OP.END_CUSTOM_BRUSH", bResult, nUserData)

    if not bResult then
        return
    end

    m_bStartMove = false
    if nUserData == END_TYPE.MOVE then
        if m_tCacheInfo[1] == HOMELAND_BUILD_OP.USE_FOLIAGE_COVER_BRUSH then
            CreateFlowerBrush(m_tCacheInfo)
        elseif m_tCacheInfo[1] == HOMELAND_BUILD_OP.USE_APPLIQUE_BRUSH then
            CreateFloorBrush(m_tCacheInfo)
        else
            m_tCacheInfo = {}
        end
        HLBOp_Amount.RefreshCustomBrushData()
    elseif nUserData == END_TYPE.CANCEL then
        FireUIEvent("LUA_HOMELAND_CANCEL_CUSTOM_BRUSH")
        --m_tCacheInfo = {}
    end
end

function OnClearFlowerResult()
    local nUserData = arg1
	local bResult = Homeland_ToBoolean(arg2)
    Homeland_Log("收到HOMELAND_BUILD_OP.CLEAR_FOLIAGE_COVER", bResult)
    if bResult then
        HLBOp_Main.SetModified(true)
        HLBOp_Amount.RefreshCustomBrushData()
    end
end

function OnFullFillCustomBrushResult()
    local nUserData = arg1
	local bResult = Homeland_ToBoolean(arg2)
    Homeland_Log("收到HOMELAND_BUILD_OP.FULL_FILL_CUSTOM_BRUSH", bResult)
    if bResult then
        HLBOp_Main.SetModified(true)
        HLBOp_Amount.RefreshCustomBrushData()
    end
end

function HasPickedCustomBrush()
    return m_bStartMove
end

function OnFrameBreathe()
    if m_bStartMove then
        MoveCustomBrush()
    end
end

function Init()
    m_bStartMove = false
    m_tCacheInfo = {}
    m_bPreMoveSuccess = false
end

function UnInit()
    m_bStartMove = nil
    m_tCacheInfo = nil
    m_bPreMoveSuccess = nil
end
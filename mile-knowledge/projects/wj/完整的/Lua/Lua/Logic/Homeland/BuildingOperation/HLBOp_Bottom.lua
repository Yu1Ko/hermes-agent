
NewModule("HLBOp_Bottom")

---表现UserData----和HLBOp_Brush共享
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

local AUTO_BOTTOM_TIME = 400 --ms
local MAX_BOTTOM_COUNT = 10

m_bMoveBottom = false

m_bCreateBottom = false
m_bAutoBottomBrush = false
m_nLastBottomTime = 0
m_dwModelID = 0
m_nBottomCount = 0

---------------------------发送消息v--------------------------
function SetBottomCount(nCount)
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.SET_AUTO_BOTTOM_BRUSH_COUNT, nCount, 0)
    Homeland_Log("发送HOMELAND_BUILD_OP.SET_AUTO_BOTTOM_BRUSH_COUNT", nCount, bResult)
end

function CreateBottom(dwModelID)
    local nFill = 0
    local nAvailableBrushCount = 40
    ClearData()

    m_dwModelID = dwModelID
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.CREATE_BRUSH, dwModelID, nFill, nAvailableBrushCount, CREATE_TYPE.BOTTOM)
    Homeland_Log("发送HOMELAND_BUILD_OP.CREATE BOTTOM", dwModelID, nFill, nAvailableBrushCount, bResult)
    SetBottomCount(0)
    SetBottomCount(15)

    FireUIEvent("LUA_HOMELAND_CREATE_BOTTOM")
end

function MoveBottom()
    local nCursorX, nCursorY = Homeland_GetCursorPosInPixels()
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.MOVE_BRUSH, nCursorX, nCursorY, 0)
end

function CancelBottom()
    if m_bMoveBottom then
        local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.END_BRUSH, END_TYPE.CANCEL)
        Homeland_Log("发送HOMELAND_BUILD_OP.END_BRUSH CANCEL", bResult)
        FireUIEvent("LUA_HOMELAND_END_BOTTOM")
    end
end

function CreateBottomInUse()
    local nFill = 0
    local nAvailableBrushCount = 40
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.CREATE_BRUSH, m_dwModelID, nFill, nAvailableBrushCount, CREATE_TYPE.USE_BOTTOM)
    Homeland_Log("发送HOMELAND_BUILD_OP.CREATE INUSE", m_dwModelID, nFill, nAvailableBrushCount, bResult)
end

function StartBottomInUse()
    if m_bCreateBottom then
        local nCursorX, nCursorY = Homeland_GetCursorPosInPixels()
        local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.START_BRUSH, nCursorX, nCursorY, START_TYPE.USE_BOTTOM)
        Homeland_Log("发送HOMELAND_BUILD_OP.START_BRUSH USE_BOTTOM", bResult)
    end
end

function EndBottomInUse()
    if m_bCreateBottom then
        HLBOp_Main.SetModified(true)
        local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.END_BRUSH, END_TYPE.USE_BOTTOM)
        Homeland_Log("发送HOMELAND_BUILD_OP.END Bottom", bResult)
    end
end

function StartBottom()
    if m_bCreateBottom then
        m_nLastBottomTime = 0
        m_nBottomCount = 0
        m_bAutoBottomBrush = true
        m_bMoveBottom = false
        HLBOp_Step.StartOneStep("StartBottom")
        FireUIEvent("LUA_HOMELAND_LAYERS_OPEN")
        AutoBottom()
    end
end

function EndBottom()
    if m_bCreateBottom then
        FireUIEvent("LUA_HOMELAND_LAYERS_CLOSE")
        HLBOp_Step.EndOneStep()
        m_bAutoBottomBrush = false
        local tStore = {{nModelID = m_dwModelID, nModelAmount = m_nBottomCount}}
        if HLBOp_Check.CheckAdd(tStore) then
            CreateBottom(m_dwModelID)
        else
            EndBottomWithFail()
        end
        HLBOp_Amount.ChangeLandData(tStore)
        m_nBottomCount = 0
        m_bCreateBottom = false
    end
end

function EndBottomWithFail()
    if m_bCreateBottom then
        m_bAutoBottomBrush = false
        m_nBottomCount = 0
        ClearData()
        FireUIEvent("LUA_HOMELAND_END_BOTTOM")
    end
end

function AutoBottom()
    if m_bAutoBottomBrush then
        local nTime = GetTickCount()
        if m_nLastBottomTime + AUTO_BOTTOM_TIME < nTime and m_nBottomCount < MAX_BOTTOM_COUNT then
            m_nLastBottomTime = nTime
            CreateBottomInUse()
        end
    end
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
    elseif szEvent == "LUA_HOMELAND_INTERACTABLE_ERROR" then
        OnInteractError()
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

    if nUserData == CREATE_TYPE.BOTTOM then
        m_bMoveBottom = true
        m_bCreateBottom = true
    elseif nUserData == CREATE_TYPE.USE_BOTTOM then
        StartBottomInUse()
    end
end

function OnStartBrushResult()
    local nUserData = arg1
	local nResult = arg2
	local bResult = Homeland_ToBoolean(nResult)
    Homeland_Log("收到HOMELAND_BUILD_OP.START_BRUSH", nUserData, bResult)

    if not bResult then
        m_bMoveBottom = false
        return
    end

    if nUserData == START_TYPE.USE_BOTTOM then
        m_nBottomCount = m_nBottomCount + 1
        MoveBottom()
        EndBottomInUse()
    end
end

function OnEndBrushResult()
    local nUserData = arg1
    local nPhase = arg2
    if nPhase == 0 then
        local bResult = Homeland_ToBoolean(arg3)
        Homeland_Log("收到HOMELAND_BUILD_OP.END_BRUSH", nUserData, bResult)
	elseif nPhase == 1 then

    elseif nPhase == 2 then
        if nUserData == END_TYPE.CANCEL then
            ClearData()
        elseif nUserData == END_TYPE.USE_BOTTOM then
            FireHelpEvent("OnFurnitureBrushEnd", {m_dwModelID})
            FireUIEvent("LUA_HOMELAND_LAYERS_UPDATE", m_nBottomCount)
        end
	end
end

---------------------------API v--------------------------
function OnFrameBreathe()
	if m_bMoveBottom then
        MoveBottom()
	end
    if m_bAutoBottomBrush then
        AutoBottom()
    end
end

function OnInteractError()
    EndBottom()
end

function ClearData()
    Init()
end

function Init()
    m_bMoveBottom = false
    m_bCreateBottom = false
    m_bAutoBottomBrush = false
    m_nLastBottomTime = 0
    m_dwModelID = 0
    m_nBottomCount = 0
end

function UnInit()
    m_bMoveBottom = nil
    m_bCreateBottom = nil
    m_bAutoBottomBrush = nil
    m_nLastBottomTime = nil
    m_dwModelID = nil
    m_nBottomCount = nil
end



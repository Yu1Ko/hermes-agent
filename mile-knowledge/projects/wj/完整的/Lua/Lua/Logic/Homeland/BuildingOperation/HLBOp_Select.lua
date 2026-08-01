
NewModule("HLBOp_Select")

---表现UserData----

local GET_ITEMS_TYPE = {
    NORMAL = 1,
    CTRL = 2,
}

local SELECT_RLID_TYPE = {
    NORMAL = 1,
    NO_OUTLINE = 2,
}

m_tTempStore = {}
m_tSelectObjs = {}
m_tPreOutLine = {} --时序

---------------------------发送消息v--------------------------
function SelectScreen()
    ClearSelect()
    local nCursorX, nCursorY = Homeland_GetCursorPosInPixels()
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.GET_ITEMS, nCursorX, nCursorY, GET_ITEMS_TYPE.NORMAL)
    Homeland_Log("发送HOMELAND_BUILD_OP.GET_ITEMS NORMAL", bResult)
end

function SelectScreenInCtrl()
    local nCursorX, nCursorY = Homeland_GetCursorPosInPixels()
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.GET_ITEMS, nCursorX, nCursorY, GET_ITEMS_TYPE.CTRL)
    Homeland_Log("发送HOMELAND_BUILD_OP.GET_ITEMS CTRL", bResult)
end

function SelectRec(nBeginPosX, nBeginPosY, nEndPosX, nEndPosY)
    ClearSelect()
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.DRAG_OVER_SELECT, nBeginPosX, nBeginPosY, nEndPosX, nEndPosY, 0)
    Homeland_Log("发送HOMELAND_BUILD_OP.DRAG_OVER_SELECT", bResult)
end

function SelectAll()
    ClearSelect()
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.SELECT_ALL, 0)
    Homeland_Log("发送HOMELAND_BUILD_OP.SELECT_ALL", bResult)
end

function SetItemSelect(nObjID)
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.SET_SELECTED, nObjID, nObjID)
    Homeland_Log("发送HOMELAND_BUILD_OP.SET_SELECTED ITEM", nObjID, bResult)
end

function ClearSelect()
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.SET_SELECTED, 0, 0)
    Homeland_Log("发送HOMELAND_BUILD_OP.SET_SELECTED CLEAR", bResult)
end

function SelectModelItem(dwModelID)
    ClearSelect()
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.SELECT_BY_RLID, dwModelID, SELECT_RLID_TYPE.NORMAL)
    Homeland_Log("发送HOMELAND_BUILD_OP.SELECT_BY_RLID NORMAL", dwModelID, bResult)
end

function SelectModelItemWithoutOutline(dwModelID)
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.SELECT_BY_RLID, dwModelID, SELECT_RLID_TYPE.NO_OUTLINE)
    Homeland_Log("发送HOMELAND_BUILD_OP.SELECT_BY_RLID NO_OUTLINE", dwModelID, bResult)
end

function SelectOneGroup(dwGroupID)
    ClearSelect()
    local tObjIDs = HLBOp_Group.GetGroupInfo(dwGroupID)
    for i = 1, #tObjIDs do
        SetCtrlSelect(tObjIDs[i])
    end
end

function SetCtrlSelect(nObjID)
    ClearOutLine()
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.SET_CTRL_SELECTED, nObjID, 0)
    Homeland_Log("发送HOMELAND_BUILD_OP.SET_CTRL_SELECTED", nObjID, bResult)
end

function ClearOutLine()
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.CLEAR_ALL_OUTLINE, 0)
    Homeland_Log("发送HOMELAND_BUILD_OP.CLEAR_ALL_OUTLINE", bResult)
end

function SetOutLine(tObjID)
    local nSet = 0
    for i = 1, #m_tPreOutLine do
        local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.SET_OUTLINE, m_tPreOutLine[i], nSet, 0)
    end
    nSet = 1
    SetSelectInfo(tObjID)
    for i = 1, #tObjID do
        local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.SET_OUTLINE, tObjID[i], nSet, 0)
    end
    m_tPreOutLine = tObjID
end

function OnEvent(szEvent)
	if szEvent == "HOMELAND_CALL_RESULT" then
		local eOperationType = arg0
        if eOperationType == HOMELAND_BUILD_OP.GET_ITEMS then
            OnGetItemsResult()
		elseif eOperationType == HOMELAND_BUILD_OP.SET_SELECTED then
			OnSetSelectResult()
        elseif eOperationType == HOMELAND_BUILD_OP.SELECT_BY_RLID then
            OnSelectByRLIDResult()
        elseif eOperationType == HOMELAND_BUILD_OP.SET_CTRL_SELECTED then
            OnSetCtrlSelectResult()
        elseif eOperationType == HOMELAND_BUILD_OP.DRAG_OVER_SELECT then
            OnDargOverSelectResult()
        elseif eOperationType == HOMELAND_BUILD_OP.SELECT_ALL then
            OnSelectAllResult()
		end
	end
end

---------------------------接收消息v--------------------------
function OnGetItemsResult()
    local nUserData = arg1
    local dwObjID = arg2
    if dwObjID == 0 then
        HLBOp_Place.ConfirmPlace()
        HLBOp_MultiItemOp.ConfirmPlace()
        ClearSelect()
        HLBOp_Place.CancelPlace()
        HLBOp_MultiItemOp.CancelPlace()
        SetSelectInfo({})
        return
    end
    local dwModelID = arg3
    if nUserData == GET_ITEMS_TYPE.NORMAL then
        Homeland_Log("收到HOMELAND_BUILD_OP.GET_ITEMS NORMAL", dwObjID)
        local dwGroupID = HLBOp_Group.GetGroupID(dwObjID)
        if dwGroupID then
            SelectOneGroup(dwGroupID)
        else
            SetItemSelect(dwObjID)
        end
    elseif nUserData == GET_ITEMS_TYPE.CTRL then
        if m_tSelectObjs.bSingle then
            ClearSelect()
        end
        Homeland_Log("收到HOMELAND_BUILD_OP.GET_ITEMS CTRL", dwObjID)
        local dwGroupID = HLBOp_Group.GetGroupID(dwObjID)
        if dwGroupID then
            local tObjIDs = HLBOp_Group.GetGroupInfo(dwGroupID)
            for i = 1, #tObjIDs do
                SetCtrlSelect(tObjIDs[i])
            end
        else
            SetCtrlSelect(dwObjID)
        end
    end
end

function OnSetSelectResult()
    local nUserData = arg1
    local bResult = Homeland_ToBoolean(arg2)
    Homeland_Log("收到HOMELAND_BUILD_OP.SET_SELECTED", bResult)
    if not bResult then
        HLBView_Message.Show(g_tStrings.STR_HOMELAND_BUILDING_CANT_SELECT_OBJECT, 1)
        return
    end
    local dwObjID = nUserData
    if dwObjID ~= 0 then
        local tObjIDs = {dwObjID}
        tObjIDs.bSingle = true
        SetSelectInfo(tObjIDs)
    else
        SetSelectInfo({})
    end
end

function OnSelectByRLIDResult()
    local nUserData = arg1
    local nPhase = arg2
    if nPhase == 0 then
        local bResult = Homeland_ToBoolean(arg3)
        Homeland_Log("收到HOMELAND_BUILD_OP.SELECT_BY_RLID", bResult)
        m_tTempStore = {}
    elseif nPhase == 1 then
        Homeland_StoreObjID(m_tTempStore)
    elseif nPhase == 2 then
        if nUserData == SELECT_RLID_TYPE.NORMAL then
            SetOutLine(m_tTempStore)
        end
        m_tTempStore = {}
    end
end

function OnSetCtrlSelectResult()
    local nUserData = arg1
    local nPhase = arg2
    if nPhase == 0 then
        local bResult = Homeland_ToBoolean(arg3)
        Homeland_Log("收到HOMELAND_BUILD_OP.SET_CTRL_SELECTED", bResult)
        m_tTempStore = {}
    elseif nPhase == 1 then
        Homeland_StoreObjID(m_tTempStore)
    elseif nPhase == 2 then
        SetOutLine(m_tTempStore)
        m_tTempStore = {}
    end
end

function OnDargOverSelectResult()
    local nUserData = arg1
    local nPhase = arg2
    if nPhase == 0 then
        local bResult = Homeland_ToBoolean(arg3)
        Homeland_Log("收到HOMELAND_BUILD_OP.DRAG_OVER_SELECT", bResult)
        m_tTempStore = {}
    elseif nPhase == 1 then
        Homeland_StoreObjID(m_tTempStore)
    elseif nPhase == 2 then
        local tAddObjs = {}
        for i = 1, #m_tTempStore do
            local dwGroupID = HLBOp_Group.GetGroupID(m_tTempStore[i])
            if dwGroupID then
                local tObjIDs = HLBOp_Group.GetGroupInfo(dwGroupID)
                for j = 1, #tObjIDs do
                    if not tAddObjs[tObjIDs[j]] and (not CheckIsInTable(m_tTempStore, tObjIDs[j])) then
                        tAddObjs[tObjIDs[j]] = 1
                    end
                end
            end
        end
        if next(tAddObjs) then
            for k, v in pairs(tAddObjs) do
                SetCtrlSelect(k)
            end
        else
            SetOutLine(m_tTempStore)
        end
        m_tTempStore = {}
    end
end

function OnSelectAllResult()
    local nUserData = arg1
    local nPhase = arg2
    if nPhase == 0 then
        local bResult = Homeland_ToBoolean(arg3)
        Homeland_Log("收到HOMELAND_BUILD_OP.SELECT_ALL", bResult)
        m_tTempStore = {}
    elseif nPhase == 1 then
        Homeland_StoreObjID(m_tTempStore)
    elseif nPhase == 2 then
        SetOutLine(m_tTempStore)
        m_tTempStore = {}
    end
end

---------------------------API v--------------------------
function SetSelectInfo(tObjID)
    if #tObjID == 0 then
        HLBOp_Rotate.BackObjAngle(m_tSelectObjs[1])
    end
    m_tSelectObjs = tObjID
    FireUIEvent("LUA_HOMELAND_SELECT_CHANGE")
end

function GetSelectInfo()
    return m_tSelectObjs
end

function Init()
    m_tTempStore = {}
    m_tSelectObjs = {}
    m_tPreOutLine = {}
end

function UnInit()
    m_tTempStore = nil
    m_tSelectObjs = nil
    m_tPreOutLine = nil
end
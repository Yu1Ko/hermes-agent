
NewModule("HLBOp_Group")

m_tGroupInfo = {}
m_tTempStore = {}

---------------------------发送消息v--------------------------
function GroupSelectObj()
    local tDestroyGroup = {}
    local tSelectObjs = HLBOp_Select.GetSelectInfo()
    for i = 1, #tSelectObjs do
        local dwObjID = tSelectObjs[i]
        local dwGroupID = HLBOp_Group.GetGroupID(dwObjID)
        if dwGroupID and (not CheckIsInTable(tDestroyGroup, dwObjID)) then
            table.insert(tDestroyGroup, dwGroupID)
        end
    end
    for i = 1, #tDestroyGroup do
        DestroyGroup(tDestroyGroup[i])
    end
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.PACKUP_MODEL_GROUP, 0)
    Homeland_Log("发送HOMELAND_BUILD_OP.PACKUP_MODEL_GROUP", bResult)
end

function RequestGroupObjIDs(dwGroupID)
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.UNPACK_MODEL_GROUP, dwGroupID, dwGroupID)
    Homeland_Log("发送HOMELAND_BUILD_OP.UNPACK_MODEL_GROUP", dwGroupID, bResult)
end

function DestroyGroup(dwGroupID)
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.DESTROY_MODEL_GROUP, dwGroupID, dwGroupID)
    Homeland_Log("发送HOMELAND_BUILD_OP.DESTROY_MODEL_GROUP", dwGroupID, bResult)
end

function RequestAllGroupIDs()
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.GET_ALL_MODEL_GROUP_IDS, dwGroupID)
    Homeland_Log("发送HOMELAND_BUILD_OP.GET_ALL_MODEL_GROUP_IDS", bResult)
end

function OnEvent(szEvent)
	if szEvent == "HOMELAND_CALL_RESULT" then
		local eOperationType = arg0
		if eOperationType == HOMELAND_BUILD_OP.PACKUP_MODEL_GROUP then
            OnPackupResult()
        elseif eOperationType == HOMELAND_BUILD_OP.UNPACK_MODEL_GROUP then
            OnUnpackResult()
        elseif eOperationType == HOMELAND_BUILD_OP.DESTROY_MODEL_GROUP then
            OnDestroyGroupResult()
        elseif eOperationType == HOMELAND_BUILD_OP.GET_ALL_MODEL_GROUP_IDS then
            OnGetAllGroupIDs()
		end
	end
end

---------------------------接收消息v--------------------------
function OnPackupResult()
    local nUserData = arg1
	local nResult = arg2 -- 适用于大部分，但有些并非如此
	local bResult = Homeland_ToBoolean(nResult)
    local dwGroupID = arg3
    Homeland_Log("收到HOMELAND_BUILD_OP.PACKUP_MODEL_GROUP", dwGroupID, bResult)
    m_tGroupInfo[dwGroupID] = {}
    RequestGroupObjIDs(dwGroupID)
end

function OnUnpackResult()
    local nUserData = arg1
	local nPhase = arg2
    if nPhase == 0 then
        local bResult = Homeland_ToBoolean(arg3)
        Homeland_Log("收到HOMELAND_BUILD_OP.UNPACK_MODEL_GROUP", bResult)
        m_tTempStore = {}
    elseif nPhase == 1 then
        Homeland_StoreObjID(m_tTempStore)
    elseif nPhase == 2 then
        local dwGroupID = nUserData
        m_tGroupInfo[dwGroupID] = m_tTempStore
        m_tTempStore = {}
        FireUIEvent("LUA_HOMELAND_GROUP_CHANGE")
    end
end

function OnDestroyGroupResult()
    local nUserData = arg1
	local nResult = arg2 -- 适用于大部分，但有些并非如此
	local bResult = Homeland_ToBoolean(nResult)
    local dwGroupID = nUserData
    Homeland_Log("收到HOMELAND_BUILD_OP.DESTROY_MODEL_GROUP", dwGroupID, bResult)
    m_tGroupInfo[dwGroupID] = nil
    FireUIEvent("LUA_HOMELAND_GROUP_CHANGE")
end

function OnGetAllGroupIDs()
    local nUserData = arg1
	local nPhase = arg2
    if nPhase == 0 then
        local bResult = Homeland_ToBoolean(arg3)
        Homeland_Log("收到HOMELAND_BUILD_OP.UNPACK_MODEL_GROUP", bResult)
        m_tTempStore = {}
    elseif nPhase == 1 then
        Homeland_StoreObjID(m_tTempStore) --GroupIDs
    elseif nPhase == 2 then
        m_tGroupInfo = {}
        for i = 1, #m_tTempStore do
            local dwGroupID = m_tTempStore[i]
            RequestGroupObjIDs(dwGroupID)
        end
        m_tTempStore = {}
    end
end

---------------------------API v--------------------------
function GetGroupID(dwObjID)
    for k, v in pairs(m_tGroupInfo) do
        local tObjIDs = v
        for i = 1, #tObjIDs do
            if tObjIDs[i] == dwObjID then
                return k
            end
        end
    end
    return nil
end

function GetGroupInfo(dwGroupID)
    return m_tGroupInfo[dwGroupID]
end

function GetAllGroupIDs()
    local aIDs = {}
	for dwGroupID, _ in pairs(m_tGroupInfo) do
		table.insert(aIDs, dwGroupID)
	end
	return aIDs
end

function Init()
    m_tGroupInfo = {}
    m_tTempStore = {}
end

function UnInit()
    m_tGroupInfo = nil
    m_tTempStore = nil
end


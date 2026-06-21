
NewModule("HLBOp_Exit")

---表现UserData----
local EXIT_TYPE = {
	NORAML = 1,
}

m_fnActionBeforeExit = nil
m_bHaveBeyondObject = false

---------------------------发送消息v--------------------------

function DoExit()
    BuildEnd()
    local nMode = HLBOp_Main.GetBuildMode()
    local tConfig = Homeland_GetModeConfig(nMode)
    Homeland_ServerLog(nMode, HOMELAND_LOG_NUM.EXIT_BUILDING)
    if tConfig.bDesign then
        local nSceneID = HLBOp_Enter.GetSceneID()
        local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.EXIT_NEW_SCENE, nSceneID) --没有返回事件
        Homeland_Log("DoExit 发送HOMELAND_BUILD_OP.EXIT_NEW_SCENE", nSceneID, bResult)
        local dwMapID, nCopyIndex = Homeland_GetMapAndCopyIndex()
        local hlMgr = GetHomelandMgr()
        if hlMgr.IsPrivateHomeMap(dwMapID) then
            DoStartSublandInDesign()
        end
        local fnAction = m_fnActionBeforeExit
        HLBOp_Main.Exit()
	if fnAction then
            Homeland_Log("DO fnActionBeforeExit")
            fnAction()
        end
    else
        local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.EXIT, EXIT_TYPE.NORAML)
        Homeland_Log("DoExit 发送HOMELAND_BUILD_OP.EXIT", bResult)
    end
    --一些选中特效需要提前关闭
    -- HLBView_AreaManagement.Close()
end

function BuildEnd()
    local hlMgr = GetHomelandMgr()
    hlMgr.BuildEnd()
    local tConfig = Homeland_GetModeConfig(HLBOp_Main.GetBuildMode())
    if not tConfig.bDesign then
        hlMgr.BuildLock(HLBOp_Enter.GetLandIndex(), HOMELAND_BUILD_LOCK_TYPE.UNLOCK)
        Homeland_Log("结束建造 BuildLock 参数：", HLBOp_Enter.GetLandIndex(), HOMELAND_BUILD_LOCK_TYPE.UNLOCK)
    end
end

function DoStartSublandInDesign()
    local dwMapID, nCopyIndex = Homeland_GetMapAndCopyIndex()
    local hlMgr = GetHomelandMgr()
    local nMaxLandIndex = hlMgr.GetMaxMainLandIndex(dwMapID)
    for i = 1, nMaxLandIndex do
        local nLandIndex = i
        local nMaxIndex = hlMgr.GetMaxSubLandIndex(dwMapID, nLandIndex)
        local tInfo = hlMgr.GetHLLandInfo(nLandIndex)
        if tInfo then
            local uDemolishSubLand = tInfo.uDemolishSubLand
            local szMainName = hlMgr.GetLandName(nLandIndex)
            local tLandInfo = {HOMELAND_BUILD_OP.HOMELAND_START_SUBLAND, szMainName, nMaxIndex}
            for i = 1, nMaxIndex do
                table.insert(tLandInfo, hlMgr.GetLandName(nLandIndex, i))
                local nNotCanBuild = (not GetNumberBit(uDemolishSubLand, i)) and 1 or 0
                table.insert(tLandInfo, nNotCanBuild)
            end
            table.insert(tLandInfo, 0)
            Homeland_SendMessage(unpack(tLandInfo))
            Homeland_Log("DoStartSublandInDesign 发送HOMELAND_BUILD_OP.HOMELAND_START_SUBLAND", tLandInfo, bResult)
        end
    end
end

function DoStartSubland()
    local hlMgr = GetHomelandMgr()
    local dwMapID, nCopyIndex, nLandIndex = HLBOp_Enter.GetLandMapInfo()
    local nMaxIndex = hlMgr.GetMaxSubLandIndex(dwMapID, nLandIndex)
    local tInfo = hlMgr.GetHLLandInfo(nLandIndex)
    if tInfo then
        local uDemolishSubLand = tInfo.uDemolishSubLand
        local szMainName = hlMgr.GetLandName(nLandIndex)
        local tLandInfo = {HOMELAND_BUILD_OP.HOMELAND_START_SUBLAND, szMainName, nMaxIndex}
        for i = 1, nMaxIndex do
            table.insert(tLandInfo, hlMgr.GetLandName(nLandIndex, i))
            local nNotCanBuild = (not GetNumberBit(uDemolishSubLand, i)) and 1 or 0
            table.insert(tLandInfo, nNotCanBuild)
        end
        table.insert(tLandInfo, 0)
        local bResult = Homeland_SendMessage(unpack(tLandInfo))
        Homeland_Log("DoStartSubland 发送HOMELAND_BUILD_OP.HOMELAND_START_SUBLAND", tLandInfo, bResult)
    end
end

function RemoveBakFile()
    local hlMgr = GetHomelandMgr()
    hlMgr.RemoveBakFile(HLBOp_Enter.GetLandIndex())
end
---------------------------接收消息v--------------------------
function OnEvent(szEvent)
    if szEvent == "HOMELAND_CALL_RESULT" then
        local eOperationType = arg0
        if eOperationType == HOMELAND_BUILD_OP.EXIT then
            OnExitResult()
        elseif eOperationType == HOMELAND_BUILD_OP.HOMELAND_START_SUBLAND then
            OnStartSublandResult()
        end
    end
end

function OnExitResult()
    local nUserData = arg1
	local bResult = Homeland_ToBoolean(arg2)
    Homeland_Log("收到HOMELAND_BUILD_OP.EXIT", bResult, nUserData)
    local fnAction = m_fnActionBeforeExit
    if bResult then
        if nUserData == EXIT_TYPE.NORAML then
            local tConfig = Homeland_GetModeConfig(HLBOp_Main.GetBuildMode())
            if tConfig.bPrivate then
                DoStartSubland()
            end
            HLBOp_Main.Exit()
        end
    else
        HLBOp_Main.Exit()
    end
    if fnAction then
        Homeland_Log("DO fnActionBeforeExit")
        fnAction()
    end
end

local eStartSubLand = {
    SUCCESS = 0,
    FAIL = 1,
    INEDIT = 2,
}
function OnStartSublandResult()
    local nUserData = arg1
	local nResult = arg2
	if nResult == eStartSubLand.INEDIT then
        --DoGetBeyondObject()
    else
        Homeland_Log("收到HOMELAND_BUILD_OP.HOMELAND_START_SUBLAND", nResult == eStartSubLand.SUCCESS and "成功" or "失败", nResult)
	end
end

function SetActionBeforeExit(fnAction)
    m_fnActionBeforeExit = fnAction
end
function Init()
    m_bHaveBeyondObject = false
    m_fnActionBeforeExit = nil
end

function UnInit()
    m_bHaveBeyondObject = nil
    m_fnActionBeforeExit = nil
end

NewModule("HLBOp_Save")

---表现UserData----
local SAVE_TYPE = {
	NORAML = 1,
    AUTO = 2,
    DEMOLISH = 3,
    QUIT = 4,
    GET_FILE_LIMIT = 5,
}

m_dwLastAutoSaveTime = 0
m_bApplyBak = false
m_nDemolishSubLand = 0
m_bDoDemolish = false
m_nWaitForApplyingFailTimerID = nil
m_nMatchRate = 0
m_nLastGetFileLimitTime = 0
m_bInDigitalSaving = false

local AUTO_SAVE_TIME_INTERVAL = 2 * 60 -- 自动保存时间间隔，单位：秒

function GetGeneratedSdkPath()
	return "homeland/" .. GetClientPlayer().GetGlobalID() .. "/uploadsdk.sdk"
end

function GetCheckFileFolder()
	return "homeland/" .. GetClientPlayer().GetGlobalID() .. "/"
end

function GetGeneratedSdkFilename()
	return "uploadsdk.sdk"
end

function GetCheckFileName()
    return "checkfile"
end

function GetLastGetLimitTime()
    return m_nLastGetFileLimitTime
end

function GetReEnterCD()
    local tConfig = Homeland_GetModeConfig(HLBOp_Main.GetBuildMode())
    if tConfig and tConfig.bPrivate then
        return 9
    elseif tConfig and not tConfig.bDesign then
        return 5
    else
        return 9
	end
end

---------------------------发送消息 或调用接口 v--------------------------
function DoGetMatchRateAndSave()
    if not HLBOp_Check.CheckSave() then
        return
    end

    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.GLOBAL_BP_VALUE, SAVE_TYPE.NORAML)
    Homeland_Log("DoSave 发送HOMELAND_BUILD_OP.GLOBAL_BP_VALUE", SAVE_TYPE.NORAML, bResult)
end

function DoGetMatchRateAndSaveAndQuit()
    if not HLBOp_Check.CheckSave() then
        return
    end

    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.GLOBAL_BP_VALUE, SAVE_TYPE.QUIT)
    Homeland_Log("DoSave 发送HOMELAND_BUILD_OP.GLOBAL_BP_VALUE", SAVE_TYPE.QUIT, bResult)
end

function DoSave()
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.SAVE, GetFullPath(GetGeneratedSdkPath()), SAVE_TYPE.NORAML)
    Homeland_Log("DoSave 发送HOMELAND_BUILD_OP.SAVE", GetFullPath(GetGeneratedSdkPath()), bResult)
    if bResult then
        HLBView_Message.Show(g_tStrings.STR_HOMELAND_BUILDING_IN_SAVE, 3)
    else
        HLBView_Message.Show(g_tStrings.STR_HOMELAND_SD_SIZE_LIMIT_REACHED_REMIND_3, 3)
    end
end

function DoSaveAndQuit()
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.SAVE, GetFullPath(GetGeneratedSdkPath()), SAVE_TYPE.QUIT)
    Homeland_Log("DoSave 发送HOMELAND_BUILD_OP.SAVE", GetFullPath(GetGeneratedSdkPath()), bResult)
    if bResult then
        HLBView_Message.Show(g_tStrings.STR_HOMELAND_BUILDING_IN_SAVE, 3)
    else
        HLBView_Message.Show(g_tStrings.STR_HOMELAND_SD_SIZE_LIMIT_REACHED_REMIND_3, 3)
    end
end

function DoSaveDemolish()
    if HLBOp_Check.CheckSave() then
        return
    end

    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.SAVE, GetFullPath(GetGeneratedSdkPath()), SAVE_TYPE.DEMOLISH)
    Homeland_Log("DoSave 发送HOMELAND_BUILD_OP.SAVE DoSaveDemolish", GetFullPath(GetGeneratedSdkPath()), bResult)
    if bResult then
        HLBView_Message.Show(g_tStrings.STR_HOMELAND_BUILDING_IN_SAVE, 3)
    else
        HLBView_Message.Show(g_tStrings.STR_HOMELAND_SD_SIZE_LIMIT_REACHED_REMIND_3, 3)
    end
end

function DoAutoSave()
    if HLBOp_Enter.IsDigitalBlueprint() then
        return
    end
    if not HLBOp_Check.CheckAutoSave() then
        return
    end

    local bResult
    local tConfig = Homeland_GetModeConfig(HLBOp_Main.GetBuildMode())
    if tConfig.bDesign then
        HLBOp_Blueprint.AutoSaveBlueprint()
        bResult = true
    else
        bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.SAVE, GetFullPath(HLBOp_Enter.GetBakFilePath()), SAVE_TYPE.AUTO)
        Homeland_Log("DoAutoSave 发送HOMELAND_BUILD_OP.SAVE", GetFullPath(HLBOp_Enter.GetBakFilePath()), bResult)
    end

    if bResult then
        HLBView_Message.Show(g_tStrings.STR_HOMELAND_BUILDING_IN_AUTO_SAVE, 1)
    else
        HLBView_Message.Show(g_tStrings.STR_HOMELAND_SD_SIZE_LIMIT_REACHED_REMIND_3, 3)
    end
end

function DoGetSDKFileLimit()
    if not HLBOp_Check.CheckSDKFileLimit() then
        return
    end
    CPath.MakeDir(GetCheckFileFolder())
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.SAVE, GetFullPath(GetCheckFileFolder() .. GetCheckFileName()), SAVE_TYPE.GET_FILE_LIMIT)
    Homeland_Log("DoGetSDKFileLimit 发送HOMELAND_BUILD_OP.SAVE GET_FILE_LIMIT", GetFullPath(GetCheckFileFolder() .. GetCheckFileName()), bResult)
    m_nLastGetFileLimitTime = GetCurrentTime()
end

function DoApplyBak(szLandID, szPath)
    local homelandMgr = GetHomelandMgr()
    m_bApplyBak = true
    HLBOp_Blueprint.ClearBlueprintInfo()
    homelandMgr.ApplyBuilding(szLandID, szPath)
    -- HouseFastPanel.AddBuildCD(GetReEnterCD())
    Event.Dispatch(EventType.OnHomelandAddBuildCD)
    Homeland_Log("DoApplyBak ApplyBuilding", szLandID, szPath)

    if m_nWaitForApplyingFailTimerID then
        Timer.DelTimer(HLBOp_Save, m_nWaitForApplyingFailTimerID)
        m_nWaitForApplyingFailTimerID = nil
    end
    m_nWaitForApplyingFailTimerID = Timer.Add(HLBOp_Save, 1, function ()
        TipsHelper.ShowNormalTip(g_tStrings.STR_HOMELAND_BUILDING_APPLY_MAY_FAIL)
    end)
end

function DoApplyBuilding()
    HLBOp_Select.ClearSelect()
    if Lib.IsFileExist(GetGeneratedSdkPath()) then
        local homelandMgr = GetHomelandMgr()
        HLBOp_Main.SetModified(false)
        if HLBOp_Enter.IsDigitalBlueprint() then
            Homeland_Log("ApplyBuildingWithCode", HLBOp_Enter.GetLandID(), GetGeneratedSdkFilename(), HLBOp_Enter.GetCode(), m_nMatchRate, HLBOp_Enter.GetAppliedReplace())
            m_bInDigitalSaving = true
            FireUIEvent("LUA_DIGITAL_SAVING_UPDATE")
            if HLBOp_Enter.GetAppliedReplace() then
                homelandMgr.ApplyBuilding(HLBOp_Enter.GetLandID(), GetGeneratedSdkFilename(), HLBOp_Enter.GetCode(), 0)
            else
                homelandMgr.ApplyBuilding(HLBOp_Enter.GetLandID(), GetGeneratedSdkFilename(), HLBOp_Enter.GetCode(), m_nMatchRate)
            end
        else
            Homeland_Log("ApplyBuilding", HLBOp_Enter.GetLandID(), GetGeneratedSdkFilename())
            homelandMgr.ApplyBuilding(HLBOp_Enter.GetLandID(), GetGeneratedSdkFilename())
        end
        -- HouseFastPanel.AddBuildCD(GetReEnterCD())
        Event.Dispatch(EventType.OnHomelandAddBuildCD)
        Homeland_Log("DoApplyBuilding ApplyBuilding", HLBOp_Enter.GetLandID(), GetGeneratedSdkFilename())
        -- 按钮CD

        if m_nWaitForApplyingFailTimerID then
            Timer.DelTimer(HLBOp_Save, m_nWaitForApplyingFailTimerID)
            m_nWaitForApplyingFailTimerID = nil
        end
        m_nWaitForApplyingFailTimerID = Timer.Add(HLBOp_Save, 1, function ()
            TipsHelper.ShowNormalTip(g_tStrings.STR_HOMELAND_BUILDING_APPLY_MAY_FAIL)
        end)
    else
        LOG.INFO("DoApplyBuilding 不存在文件")
    end
end

function DoDemolish(nDemolishSubLand)
    local tConfig = Homeland_GetModeConfig(HLBOp_Main.GetBuildMode())
	if not tConfig or not tConfig.bPrivate then
        return
	end
    HLBOp_Main.SetModified(false)
    m_nDemolishSubLand = nDemolishSubLand
    m_bDoDemolish = true
    local pHlMgr = GetHomelandMgr()
    local dwCurMapID, nCurCopyIndex = Homeland_GetMapAndCopyIndex()
    local nLandIndex = HLBOp_Enter.GetLandIndex()
    local nMaxSubLandIndex = pHlMgr.GetMaxSubLandIndex(dwCurMapID, nLandIndex)
    for i = 1, nMaxSubLandIndex do
        local bNotCanBuild = not GetNumberBit(nDemolishSubLand, i)
        local nNotCanBuild = bNotCanBuild and 1 or 0
        local nSublandIndex = i - 1
        Homeland_SendMessage(HOMELAND_BUILD_OP.HOMELAND_LOCK_SUBLAND, nSublandIndex, nNotCanBuild, 0)
        Homeland_Log("HOMELAND_LOCK_SUBLAND", nSublandIndex,nNotCanBuild)
    end
    DoSaveDemolish()
end

function DoApplyDemolish()
    HLBOp_Select.ClearSelect()
    if Lib.IsFileExist(GetGeneratedSdkPath()) then
        local homelandMgr = GetHomelandMgr()
		homelandMgr.ApplyDemolishSubLand(HLBOp_Enter.GetLandIndex(), m_nDemolishSubLand, GetGeneratedSdkFilename())
        Event.Dispatch(EventType.OnHomelandAddBuildCD)
        m_nDemolishSubLand = 0
    else
        LOG.INFO("DoApplyDemolish 不存在文件")
    end
end

function DoApplyUninstall(szCode)
    if HLBOp_Enter.IsDigitalBlueprint() then
        Homeland_Log("ApplyUninstallBlp szCode", HLBOp_Enter.GetLandID(), szCode)
        GetHomelandMgr().ApplyUninstallBlp(HLBOp_Enter.GetLandID(), szCode)
        -- HouseFastPanel.AddBuildCD(HLBOp_Save.GetReEnterCD())
        Event.Dispatch(EventType.OnHomelandAddBuildCD)
        HLBOp_Exit.DoExit()
    end
end

function OnEvent(szEvent)
    if szEvent == "HOME_LAND_RESULT_CODE" then
        local nRetCode = arg0
        if nRetCode == HOMELAND_RESULT_CODE.TASK_BUILDING_SUCCEED then
            OnApplyBuildingSuccess()
        elseif nRetCode == HOMELAND_RESULT_CODE.TASK_FAILED_BUILDING or
            nRetCode == HOMELAND_RESULT_CODE.TASK_REFUND_BEGIN then
            if m_nWaitForApplyingFailTimerID then
                Timer.DelTimer(HLBOp_Save, m_nWaitForApplyingFailTimerID)
                m_nWaitForApplyingFailTimerID = nil
            end
        elseif nRetCode == HOMELAND_RESULT_CODE.DEMOLISH_SUB_LAND_SUCCEED then
            Timer.Add(HLBOp_Save, 2, function ()
                HLBOp_Exit.DoExit()
                Event.Dispatch(EventType.OnHomelandAddBuildCD)
            end)
            -- HouseFastPanel.AddBuildCD(GetReEnterCD())
        end
    elseif szEvent == "HOMELAND_CALL_RESULT" then
        local eOperationType = arg0
        if eOperationType == HOMELAND_BUILD_OP.SAVE then
            OnSaveResult()
        elseif eOperationType == HOMELAND_BUILD_OP.GLOBAL_BP_VALUE then
            OnGetMatchRateResult()
        end
    end
end

---------------------------接收消息v--------------------------

function OnSaveResult()
    local nUserData = arg1
	local bResult = Homeland_ToBoolean(arg2)
    Homeland_Log("收到HOMELAND_BUILD_OP.SAVE", bResult)
    if bResult then
        if nUserData == SAVE_TYPE.NORAML then
            DoApplyBuilding()
        elseif nUserData == SAVE_TYPE.DEMOLISH then
            DoApplyDemolish()
        elseif nUserData == SAVE_TYPE.QUIT then
            DoApplyBuilding()
            HLBOp_Exit.DoExit()
        end
    end
    if nUserData == SAVE_TYPE.GET_FILE_LIMIT then
        FireUIEvent("LUA_HOMELAND_UPDATE_FILE_LIMIT", bResult)
    end
end

function OnApplyBuildingSuccess()
    LOG.INFO("收到HOMELAND_RESULT_CODE.TASK_BUILDING_SUCCEED")
    if m_nWaitForApplyingFailTimerID then
        Timer.DelTimer(HLBOp_Save, m_nWaitForApplyingFailTimerID)
        m_nWaitForApplyingFailTimerID = nil
    end
	m_bInDigitalSaving = false
    FireUIEvent("LUA_DIGITAL_SAVING_UPDATE")
    if m_bApplyBak then
        m_bApplyBak = false
        HLBOp_Enter.StartBuilding()
    end
end

function OnGetMatchRateResult()
    local fRate = arg1
    local nUserData = arg2
    m_nMatchRate = math.floor(fRate * 100)
    Homeland_Log("MatchRate", m_nMatchRate, nUserData)
    if nUserData == SAVE_TYPE.NORAML or nUserData == SAVE_TYPE.QUIT then
        local nIndex, nOffset = HLBOp_Blueprint.GetBlueprintInfo()
        if m_nMatchRate > 0 and nIndex > 0 and (not HLBOp_Enter.IsTenant()) then
            Homeland_Log("On_HomeLand_BlProgress", nIndex, nOffset, m_nMatchRate)
            RemoteCallToServer("On_HomeLand_BlProgress", nIndex, nOffset, m_nMatchRate)
        end
    end
    if nUserData == SAVE_TYPE.NORAML then
        DoSave()
    elseif nUserData == SAVE_TYPE.QUIT then
        DoSaveAndQuit()
    end
end

---------------------------API v--------------------------

function IsInDigitalSaving()
    return m_bInDigitalSaving
end

function IsInDemolishSaving()
    return m_bDoDemolish
end

function OnFrameBreathe()
    local dwCurTime = GetCurrentTime()
    if m_dwLastAutoSaveTime and dwCurTime - m_dwLastAutoSaveTime >= AUTO_SAVE_TIME_INTERVAL then
        DoAutoSave()
        m_dwLastAutoSaveTime = dwCurTime
    end
end

function Init()
    m_nDemolishSubLand = 0
    m_dwLastAutoSaveTime = 0
    m_bApplyBak = false
    m_bDoDemolish = false
    m_nMatchRate = 0
    m_bInDigitalSaving = false
end

function UnInit()
    m_nDemolishSubLand = nil
    m_dwLastAutoSaveTime = nil
    m_bApplyBak = nil
    m_bDoDemolish = false
    m_nMatchRate = nil
    m_bInDigitalSaving = false
    if m_nWaitForApplyingFailTimerID then
        Timer.DelTimer(HLBOp_Save, m_nWaitForApplyingFailTimerID)
        m_nWaitForApplyingFailTimerID = nil
    end
end

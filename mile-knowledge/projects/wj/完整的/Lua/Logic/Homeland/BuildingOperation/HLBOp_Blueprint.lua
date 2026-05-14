
NewModule("HLBOp_Blueprint")

---表现UserData----
local LOAD_TYPE = {
	NORMAL = 1,
    MOVE = 2,
    PART = 3,
}

local SAVE_TYPE = {
    NORMAL = 1,
    PART = 2,
    UPLOAD = 3,
    AUTO = 4,
    EXIT = 5,
}

local SUCCESS = 0
local SUCCESS_TO_LOAD = 7
local FAIL_BEYOND = 2

m_szFile = "" --蓝图文件路径

--NORMAL--
m_nStartLoadRes = -1  --开始Load蓝图
m_bHaveBeyondObject = false --有没有超过边界的物件
m_tTempStore = {}

--MOVE--
m_bMoveBlueprint = false --移动的蓝图
m_bPreMoveBigBlpRes = false --上一次移动蓝图是不是成功

--PART--
m_dwMovePartObjID = 0 --局部蓝图的ObjID


--SAVE--
m_szSavePath = ""

m_bInLoadBlueprint = false


--数字蓝图
m_szTempCode = ""
m_bTempReplace = false
--本地蓝图
m_nTempBluePrintIndex = 0
m_nTempBluePrintOffset = 0
m_nBluePrintIndex = 0
m_nBluePrintOffset = 0

--数据上报用 记录普通蓝图码
m_szNormalCode = nil

---------------------------发送消息v--------------------------
function GetLocalFilePath()
    local szFile = GetOpenFileName(g_tStrings.STR_HOMELAND_CHOOSE_BLUEPRINT_FILE, g_tStrings.STR_HOMELAND_BLUEPRINT_FILE_NAME ..
        "\0*.blueprint;*.blueprintx*\0\0", Homeland_GetExportedBlpFolder())
    local bFileExist = IsUnpakFileExist(szFile)
    local nSize = GetUnpakFileSize(szFile)
    if bFileExist and nSize ~= 0 then
        return szFile
    end
end

function LoadLocalFileBlueprint()
    local szFile = GetLocalFilePath()
    if not szFile then
        return
    end
    QueryIsGlobalBlueprint(szFile)
end

function ShowMsgInLoadBlueprint()
    UIHelper.ShowConfirm(g_tStrings.STR_HOMELAND_BUILDING_LOAD_BLUEPRINT_IN_DIGITAL_ERROR, function ()
        local hlMgr = GetHomelandMgr()
        local szCodeInLand = hlMgr.GetDigitalBlpSN()
        HLBOp_Save.DoApplyUninstall(szCodeInLand)
    end)
end

function LoadWebFileBlueprint(szFile, szCode)
    if not Lib.IsFileExist(szFile) then
        return
    end
    HLBOp_Select.ClearSelect()
    m_szNormalCode = szCode
    StartLoadBlueprint(szFile)
    m_nTempBluePrintIndex = 0
    m_nTempBluePrintOffset = 0
end

function LoadUIFileBlueprint(szFile)
    if not Lib.IsFileExist(szFile) then
        return
    end
    local _, tFileInfo = FurnitureData.GetAllBlueprintInfos()
    local tInfo = tFileInfo[szFile]
    HLBOp_Select.ClearSelect()
    StartLoadBlueprint(szFile)
    if tInfo then
        m_nTempBluePrintIndex = tInfo.nIndex
        m_nTempBluePrintOffset = tInfo.nRemoteOffset
    end
end

function ConfirmMoveBlueprintPos()
    if m_bMoveBlueprint then
        if m_bPreMoveBigBlpRes then
            LoadMoveBlueprint()
        else
            HLBView_Message.Show(g_tStrings.STR_HOMELAND_BUILDING_CANT_PLACE_OBJECT_HERE, 3)
        end
    end
end

function CancelMoveBlueprint()
    if m_bMoveBlueprint then
        m_szTempCode = ""
        m_bTempReplace = false
        ClearBlueprintInfo()
        EndMoveLoadBlueprint()
    end
end

function IsMoveBlueprint()
    return m_bMoveBlueprint
end

function ExportBlueprint(bUpload, dwObjID, bExit)
    local tConfig = Homeland_GetModeConfig(HLBOp_Main.GetBuildMode())
    local szBlueprintSaveFolder = Homeland_GetExportedBlpFolder()
    if Platform.IsWindows() then
		szBlueprintSaveFolder = UIHelper.UTF8ToGBK(szBlueprintSaveFolder)
    end
    CPath.MakeDir(szBlueprintSaveFolder)

    local szFileName
    local szPostfix = ".blueprintx"
    if dwObjID then
        szFileName = "homelandblueprint"
    elseif not tConfig.bDesign then
        szFileName = tConfig.szFileName
    elseif tConfig.bDesign then
        szFileName = tConfig.szFileName
        szPostfix = szPostfix .. HLBOp_Enter.GetLevel()
    end
    local tTime = TimeToDate(GetCurrentTime())
    local szTime = string.format("%d%02d%02d-%02d%02d%02d", tTime.year, tTime.month, tTime.day, tTime.hour, tTime.minute, tTime.second)
    local szFilePath = szBlueprintSaveFolder .. szFileName .. "_" .. szTime
    szFilePath = Homeland_AdjustFilePath(szFilePath, szPostfix)

    if bUpload then
        SaveLoadBlueprint(szFilePath)
    elseif dwObjID then
        SavePartBlueprint(szFilePath, dwObjID)
    else
        if bExit then
            SaveBlueprintBeforeExit(szFilePath)
        else
            SaveBlueprint(szFilePath)
        end
    end
end

function AutoSaveBlueprint()
    local tConfig = Homeland_GetModeConfig(HLBOp_Main.GetBuildMode())
    if not tConfig.bDesign then
        return
    end
    local szBlueprintSaveFolder = Homeland_GetExportedBlpFolder()
    CPath.MakeDir(szBlueprintSaveFolder)
    local szMapName = ""
    local szPostfix = ".blueprintx"
    for _, v in pairs(g_tStrings.tHomelandDesignScene) do
        if v[1] == HLBOp_Enter.GetDesignYardSceneIndex() then
            szMapName = v[2]
            break
        end
    end
    local szFileName
    szFileName = szBlueprintSaveFolder .. "homelanddesignbak_" .. UIHelper.UTF8ToGBK(szMapName) .. "-" .. HLBOp_Enter.GetLandSize() .. szPostfix .. HLBOp_Enter.GetLevel()
    Homeland_AdjustFilePath(szFileName, szPostfix)
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.SAVE_BLUEPRINT, GetFullPath(szFileName), 0, false, SAVE_TYPE.AUTO)
    m_szSavePath = szFileName
    Homeland_Log("发送HOMELAND_BUILD_OP.SAVE_BLUEPRINT NORMAL", GetFullPath(szFileName), bResult)
end

function QueryIsGlobalBlueprint(szFile)
    m_szFile = szFile
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.QUERY_BLUEPRINT_IS_GLOBAL, m_szFile, LOAD_TYPE.NORMAL)
    Homeland_Log("发送HOMELAND_BUILD_OP.QUERY_BLUEPRINT_IS_GLOBAL NORMAL", m_szFile, bResult)
end

function StartLoadBlueprint(szFile)
    ClearData()
    HLBOp_Step.StartOneStep("LoadBlueprint")
    m_szTempCode = ""
    m_bTempReplace = false
    m_szFile = szFile
    local bWithVersion = false
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.START_LOAD_BLUEPRINT, m_szFile, bWithVersion, LOAD_TYPE.NORMAL)
    Homeland_Log("发送HOMELAND_BUILD_OP.START_LOAD_BLUEPRINT NORMAL", UIHelper.GBKToUTF8(m_szFile), bWithVersion, bResult)
end

function StartLoadDigitalBlueprint()
    ClearData()
    HLBOp_Step.StartOneStep("LoadBlueprint")
    m_szFile = ""
    ClearBlueprintInfo()
    local bWithVersion = false
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.START_LOAD_BLUEPRINT, m_szFile, bWithVersion, LOAD_TYPE.NORMAL)
    Homeland_Log("发送HOMELAND_BUILD_OP.START_LOAD_BLUEPRINT DIGITAL", m_szFile, bWithVersion, bResult)
end

function LoadNormalBlueprint()
    HLBOp_Main.SetModified(true)
    m_nStartLoadRes = -1
    m_tTempStore = {}
    m_dwMovePartObjID = 0

    local bWithVersion = false
    local bInstallLandBlueprint = true
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.LOAD_BLUEPRINT,
        m_szFile, bInstallLandBlueprint, bWithVersion, LOAD_TYPE.NORMAL)
    if bResult then
        m_bInLoadBlueprint = true
    end
    Homeland_Log("发送HOMELAND_BUILD_OP.LOAD_BLUEPRINT NORMAL OR DIGITAL", m_szFile, bInstallLandBlueprint, bWithVersion, bResult, LOAD_TYPE.NORMAL)
end

function LoadMoveBlueprint()
    HLBOp_Main.SetModified(true)
    m_nStartLoadRes = -1
    m_tTempStore = {}
    m_dwMovePartObjID = 0

    local bWithVersion = false
    local bInstallLandBlueprint = true
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.LOAD_BLUEPRINT,
        m_szFile, bInstallLandBlueprint, bWithVersion, LOAD_TYPE.MOVE)
    if bResult then
        m_bInLoadBlueprint = true
    end
    Homeland_Log("发送HOMELAND_BUILD_OP.LOAD_BLUEPRINT MOVE", m_szFile, bInstallLandBlueprint, bWithVersion, bResult, LOAD_TYPE.MOVE)
end

function MoveLoadBlueprint()
    local nCursorX, nCursorY = Homeland_GetCursorPosInPixels()
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.MOVE_LOAD_BLUEPRINT, nCursorX, nCursorY, LOAD_TYPE.MOVE)
end

function EndNormalLoadBlueprint()
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.END_LOAD_BLUEPRINT, LOAD_TYPE.NORMAL)
    Homeland_Log("发送HOMELAND_BUILD_OP.END_LOAD_BLUEPRINT", bResult, LOAD_TYPE.NORMAL)
    HLBOp_Step.EndOneStep()
end

function EndPartLoadBlueprint()
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.END_LOAD_BLUEPRINT, LOAD_TYPE.PART)
    Homeland_Log("发送HOMELAND_BUILD_OP.END_LOAD_BLUEPRINT", bResult, LOAD_TYPE.PART)
end

function EndMoveLoadBlueprint()
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.END_LOAD_BLUEPRINT, LOAD_TYPE.MOVE)
    Homeland_Log("发送HOMELAND_BUILD_OP.END_LOAD_BLUEPRINT", bResult, LOAD_TYPE.MOVE)
    HLBOp_Step.EndOneStep()
end

function GetBeyondObject(nType)
    m_bHaveBeyondObject = false
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.GET_BEYOND_OBJECT, nType)
    Homeland_Log("发送HOMELAND_BUILD_OP.GET_BEYOND_OBJECT", bResult)
end

function DestroyBeyondObject(nType)
    HLBOp_Main.SetModified(true)
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.DESTROY_BEYOND_OBJECT, nType)
    Homeland_Log("发送HOMELAND_BUILD_OP.DESTROY_BEYOND_OBJECT", bResult)

    TipsHelper.ShowNormalTip(g_tStrings.STR_HOMELAND_BUILDING_DESTROY_BRYOND_OBJECT)
end

function SaveLoadBlueprint(szPath)
    HLBOp_Step.ClearStep()
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.SAVE_BLUEPRINT, GetFullPath(szPath), 0, false, SAVE_TYPE.UPLOAD)
    m_szSavePath = szPath
    Homeland_Log("发送HOMELAND_BUILD_OP.SAVE_BLUEPRINT UPLOAD", GetFullPath(szPath), bResult)
end

function SaveDigitalBlueprint()
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.SAVE_BLUEPRINT, "", 0, false, SAVE_TYPE.UPLOAD)
    m_szSavePath = ""
    Homeland_Log("发送HOMELAND_BUILD_OP.SAVE_BLUEPRINT DIGITAL", "", bResult)
end

function SaveBlueprint(szPath)
    local nMode = HLBOp_Main.GetBuildMode()
    Homeland_ServerLog(nMode, HOMELAND_LOG_NUM.EXPORT_BLUEP)
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.SAVE_BLUEPRINT, GetFullPath(szPath), 0, false, SAVE_TYPE.NORMAL)
    m_szSavePath = szPath
    Homeland_Log("发送HOMELAND_BUILD_OP.SAVE_BLUEPRINT NORMAL", GetFullPath(szPath), bResult)
end

function SaveBlueprintBeforeExit(szPath)
    local nMode = HLBOp_Main.GetBuildMode()
    Homeland_ServerLog(nMode, HOMELAND_LOG_NUM.EXPORT_BLUEP)
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.SAVE_BLUEPRINT, GetFullPath(szPath), 0, false, SAVE_TYPE.EXIT)
    m_szSavePath = szPath
    Homeland_Log("发送HOMELAND_BUILD_OP.SAVE_BLUEPRINT NORMAL", GetFullPath(szPath), bResult)
end

function SavePartBlueprint(szPath, dwObjID)
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.SAVE_BLUEPRINT, GetFullPath(szPath), dwObjID, false, SAVE_TYPE.PART)
    m_szSavePath = szPath
    Homeland_Log("发送HOMELAND_BUILD_OP.SAVE_BLUEPRINT PART", GetFullPath(szPath), dwObjID, bResult)
end

function RotationBlueprint()
    if m_bMoveBlueprint then
        local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.ROTATION_LOADBLUEPRINT, 0)
        Homeland_Log("发送HOMELAND_BUILD_OP.ROTATION_LOADBLUEPRINT", bResult)
    end
end

function OnEvent(szEvent)
	if szEvent == "HOMELAND_CALL_RESULT" then
		local eOperationType = arg0
		if eOperationType == HOMELAND_BUILD_OP.START_LOAD_BLUEPRINT then
			OnStartLoadBlueprintResult()
		elseif eOperationType == HOMELAND_BUILD_OP.LOAD_BLUEPRINT then
			OnLoadBlueprintResult()
		elseif eOperationType == HOMELAND_BUILD_OP.MOVE_LOAD_BLUEPRINT then
			OnMoveLoadBlueprintRes()
		elseif eOperationType == HOMELAND_BUILD_OP.END_LOAD_BLUEPRINT then
            OnEndLoadBlueprintResult()
        elseif eOperationType == HOMELAND_BUILD_OP.GET_BEYOND_OBJECT then
            OnGetBeyondObjectResult()
        elseif eOperationType == HOMELAND_BUILD_OP.DESTROY_BEYOND_OBJECT then
            OnDestroyBeyondObjectResult()
        elseif eOperationType == HOMELAND_BUILD_OP.SAVE_BLUEPRINT then
            OnSaveBlueprintResult()
        elseif eOperationType == HOMELAND_BUILD_OP.ROTATION_LOADBLUEPRINT then
            local nCursorX, nCursorY = Homeland_GetCenterScreenPosInPixels()
            Homeland_SendMessage(HOMELAND_BUILD_OP.MOVE_LOAD_BLUEPRINT, nCursorX, nCursorY, LOAD_TYPE.MOVE)
        elseif eOperationType == HOMELAND_BUILD_OP.LOAD_LOADBLUEPRINT_PROGRESS then
            OnLoadBlueprintProgress()
        elseif eOperationType == HOMELAND_BUILD_OP.BLUEPRINT_DATA then
            OnLoadDigitalBlueprint()
        elseif eOperationType == HOMELAND_BUILD_OP.QUERY_BLUEPRINT_IS_GLOBAL then
            OnQueryIsGlobalBlueprint()
		end
    elseif szEvent == "LUA_HOMELAND_INTERACTABLE_ERROR" then
        OnInteractError()
	end
end

---------------------------接收消息v--------------------------

function OnStartLoadBlueprintResult()
    local nUserData = arg1
    local nPhase = arg2
    if nPhase == 0 then
        Homeland_Log("收到HOMELAND_BUILD_OP.START_LOAD_BLUEPRINT", nUserData, arg3)
        if nUserData == LOAD_TYPE.NORMAL then
            m_nStartLoadRes = arg3
        end
    elseif nPhase == 1 then
        --暂不需要
    elseif nPhase == 2 then
        local nMode = HLBOp_Main.GetBuildMode()
        Homeland_ServerLog(nMode, HOMELAND_LOG_NUM.IMPORT_BLUEP, m_szNormalCode)
        m_szNormalCode = nil
        if nUserData == LOAD_TYPE.NORMAL then
            if m_nStartLoadRes == SUCCESS then
                HLBOp_Amount.RefreshLandData()
                HLBOp_Group.RequestAllGroupIDs()
                m_bMoveBlueprint = true
                FireUIEvent("LUA_HOMELAND_START_LOAD_BLUEPRINT")

                local nCursorX, nCursorY = Homeland_GetCenterScreenPosInPixels()
                Homeland_SendMessage(HOMELAND_BUILD_OP.MOVE_LOAD_BLUEPRINT, nCursorX, nCursorY, LOAD_TYPE.MOVE)
            elseif m_nStartLoadRes == SUCCESS_TO_LOAD then
                LoadNormalBlueprint()
            elseif m_nStartLoadRes == FAIL_BEYOND then
                local szErrMsg = g_tStrings.tHomelandLoadBlueprintErrorString[m_nStartLoadRes]
                HLBView_Message.Show(szErrMsg, 3)
                FireUIEvent("LUA_HOMELAND_END_LOAD_BLUEPRINT")
            end
        end
        m_nStartLoadRes = -1
    end
end

function OnLoadBlueprintResult()
    local nUserData = arg1
    local nPhase = arg2
    if nPhase == 0 then
        local nSaveErrCode = arg3
        local dwObjID = arg4
        Homeland_Log("收到HOMELAND_BUILD_OP.LOAD_BLUEPRINT", nUserData, arg3, arg4)
        if nSaveErrCode == 0 and dwObjID ~= 0 then
            m_dwMovePartObjID = dwObjID
        elseif dwObjID == 0 then
            local szErrMsg = g_tStrings.tHomelandLoadBlueprintErrorString[nSaveErrCode]
            if szErrMsg then
                HLBView_Message.Show(szErrMsg, 3)
                m_bInLoadBlueprint = false
            end
        end
        m_tTempStore = {}
    elseif nPhase == 1 then
        local nDataCnt = arg3
		local dwObjID, dwModelID
		for i = 1, nDataCnt do
			dwObjID, dwModelID = _G["arg" .. (2+2*i)], _G["arg" .. (3+2*i)]
            table.insert(m_tTempStore, {nModelID = dwModelID, nModelAmount = 1})
		end
    elseif nPhase == 2 then
        if m_dwMovePartObjID == 0 then
            m_nBluePrintIndex = m_nTempBluePrintIndex
            m_nBluePrintOffset = m_nTempBluePrintOffset
            Homeland_Log("m_nBluePrintIndex, m_nBluePrintOffset", m_nBluePrintIndex, m_nBluePrintOffset)
        end
        if nUserData == LOAD_TYPE.NORMAL then
            if m_dwMovePartObjID ~= 0 then
                EndPartLoadBlueprint()
                HLBOp_Amount.RefreshInteractInfo()
                local tCount = {}
                for i = 1, #m_tTempStore do
                    local nModelID = m_tTempStore[i].nModelID
                    local nAmount = m_tTempStore[i].nModelAmount
                    if not tCount[nModelID] then
                        tCount[nModelID] = 0
                    end
                    tCount[nModelID] = tCount[nModelID] + nAmount
                end
                m_tTempStore = {}
                for k, v in pairs(tCount) do
                    table.insert(m_tTempStore, {nModelID = k, nModelAmount = v})
                end
                HLBOp_Place.StartBlueprintPartPlace(m_dwMovePartObjID, m_tTempStore)
            else
                HLBOp_Step.ClearStep()
                HLBOp_Amount.RefreshLandData()
                EndNormalLoadBlueprint()
                GetBeyondObject(nUserData)
                FireUIEvent("LUA_HOMELAND_FRESH_ITEM_LIST")
            end
        elseif nUserData == LOAD_TYPE.MOVE then
            HLBOp_Step.ClearStep()
            m_bMoveBlueprint = false
            m_bPreMoveBigBlpRes = false
            HLBOp_Amount.RefreshLandData()
            EndMoveLoadBlueprint()
            GetBeyondObject(nUserData)
            FireUIEvent("LUA_HOMELAND_FRESH_ITEM_LIST")
        end
        m_bInLoadBlueprint = false
        m_tTempStore = {}
    end
end

function OnEndLoadBlueprintResult()
    local nUserData = arg1
    local nResult = arg2
    local bResult = Homeland_ToBoolean(nResult)
    Homeland_Log("收到HOMELAND_BUILD_OP.END_LOAD_BLUEPRINT", nUserData, bResult)
    if bResult then
        if m_dwMovePartObjID == 0 and (nUserData == LOAD_TYPE.MOVE or nUserData == LOAD_TYPE.NORMAL) then
            GetBeyondObject(nUserData)
        end

        if m_szTempCode ~= "" and (nUserData == LOAD_TYPE.MOVE or nUserData == LOAD_TYPE.NORMAL) then
            HLBOp_Enter.SetCode(m_szTempCode)
            HLBOp_Enter.SetAppliedReplace(m_bTempReplace)
        elseif nUserData ~= LOAD_TYPE.PART then
            HLBOp_Enter.SetCode("")
            HLBOp_Enter.SetAppliedReplace(false)
        end

        if nUserData ~= LOAD_TYPE.PART then
            local nMode = HLBOp_Main.GetBuildMode()
            Homeland_ServerLog(nMode, HOMELAND_LOG_NUM.IMPORT_BLUEP_SUCCESS, HLBOp_Enter.IsDigitalBlueprint(), m_szTempCode)
        end
    end
    ClearData()
    FireUIEvent("LUA_HOMELAND_END_LOAD_BLUEPRINT")
end

function OnMoveLoadBlueprintRes()
    local nUserData = arg1
    local nResult = arg2
    local bResult = Homeland_ToBoolean(nResult)
    if nUserData == LOAD_TYPE.MOVE then
        m_bPreMoveBigBlpRes = bResult
    end
end

function OnGetBeyondObjectResult()
    local nUserData = arg1
    local nPhase = arg2
    if nPhase == 0 then
        local bResult = Homeland_ToBoolean(arg3)
    elseif nPhase == 1 then
        local nDataCnt = arg3 / 2
        if nDataCnt > math.floor(nDataCnt) then
            nDataCnt = math.floor(nDataCnt)
        end
        if nDataCnt > 0 then
			m_bHaveBeyondObject = true
		end
    elseif nPhase == 2 then
        Homeland_Log("收到HOMELAND_BUILD_OP.GET_BEYOND_OBJECT nPhase == 2", nUserData, m_bHaveBeyondObject)
        if nUserData == LOAD_TYPE.NORMAL or nUserData == LOAD_TYPE.MOVE then
            if m_bHaveBeyondObject then
                DestroyBeyondObject(nUserData)
            end
        end
        m_bHaveBeyondObject = false
    end
end

function OnDestroyBeyondObjectResult()
    local nUserData = arg1
    local nPhase = arg2
    if nPhase == 0 then
        local bResult = Homeland_ToBoolean(arg3)
        Homeland_Log("收到HOMELAND_BUILD_OP.DESTROY_BEYOND_OBJECT", nUserData, bResult)
        m_tTempStore = {}
    elseif nPhase == 1 then
        local bDel = true
        Homeland_StoreConsumption(m_tTempStore, bDel)
    elseif nPhase == 2 then
        if nUserData == LOAD_TYPE.NORMAL or nUserData == LOAD_TYPE.MOVE then
            Homeland_Log("OnDestroyBeyondObjectResult")
            HLBOp_Amount.ChangeLandData(m_tTempStore)
            FireUIEvent("LUA_HOMELAND_FRESH_ITEM_LIST")
            m_tTempStore = {}
        end
    end
end

function OnSaveBlueprintResult()
    local nUserData = arg1
    local nSaveErrCode = arg2
    local bResult = nSaveErrCode == 0
    Homeland_Log("收到HOMELAND_BUILD_OP.SAVE_BLUEPRINT", nUserData, bResult)
    if not bResult then
        local szErrorMsg = g_tStrings.tHomelandSaveBlueprintErrorString[nSaveErrCode]
        if szErrorMsg then
            if nUserData == SAVE_TYPE.PART then
                local tSelectObjs = HLBOp_Select.GetSelectInfo()
                for i = 1, #tSelectObjs do
                    local dwModelID = HLBOp_Amount.GetModelIDByObjID(tSelectObjs[i])
                    if FurnitureData.IsAutoBottomBrush(dwModelID) then
                        szErrorMsg = szErrorMsg .. g_tStrings.STR_FULL_STOP .. g_tStrings.STR_HOMELAND_BUILDING_CHECK_EXPORT_INCLUDING_BASEMENT
                        break
                    end
                end
            end
            HLBView_Message.Show(szErrorMsg, 3)
        end
        return
    end
    if nUserData == SAVE_TYPE.NORMAL or nUserData == SAVE_TYPE.PART or nUserData == SAVE_TYPE.EXIT then
        local fnOpenFolder = function()
            local szFolder = Homeland_GetExportedBlpFolder()
            if Platform.IsWindows() then
                szFolder = UIHelper.UTF8ToGBK(szFolder)
            end
            OpenFolder(szFolder)
        end

        local szPath = string.gsub(m_szSavePath, "\\", "/")
        local szMsg = FormatString(g_tStrings.STR_HOMELAND_SAVE_AS_BLUEPRINT_FILE_SUCCEED, szPath)

        if Platform.IsWindows() then
            szMsg = FormatString(g_tStrings.STR_HOMELAND_SAVE_AS_BLUEPRINT_FILE_SUCCEED, UIHelper.GBKToUTF8(szPath))
            local dialog = UIHelper.ShowConfirm(szMsg, fnOpenFolder)
            dialog:SetButtonContent("Confirm", g_tStrings.FACE_OPEN_FLODER)
        else
            local scriptView = UIHelper.ShowConfirm(szMsg)
            scriptView:HideButton("Cancel")
        end

        if nUserData == SAVE_TYPE.EXIT then
            HLBOp_Exit.DoExit()
        end
    elseif nUserData == SAVE_TYPE.UPLOAD then
        FireUIEvent("LUA_HOMELAND_UPLOAD_BLUEPRINT_PATH", m_szSavePath)
    end
end

function OnLoadBlueprintProgress()
    if not UIMgr.GetView(VIEW_ID.PanelDesignFieldLoading) then
        UIMgr.Open(VIEW_ID.PanelDesignFieldLoading)
    end
    FireUIEvent("LUA_HOMELAND_UPDATE_LOADBAR", arg1)
end

function OnLoadDigitalBlueprint()
    OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_HOMELAND_BUILDING_DOWNLOAD_SUCCESS)
    local szCode = arg3
    m_szTempCode = szCode
    local bReplace = (arg4 == 2)
    m_bTempReplace = bReplace
    Homeland_Log("m_szTempCode", m_szTempCode, bReplace)
    StartLoadDigitalBlueprint()
end

function OnQueryIsGlobalBlueprint()
    local nUserData = arg1
    local bResult = (arg2 == 1)
    Homeland_Log("收到HOMELAND_BUILD_OP.QUERY_BLUEPRINT_IS_GLOBAL", nUserData, bResult)
    FireUIEvent("LUA_HOMELAND_CLOSE_IMPORT_TIP")
    HLBOp_Select.ClearSelect()
    StartLoadBlueprint(m_szFile)
    m_nTempBluePrintIndex = 0
    m_nTempBluePrintOffset = 0
end
---------------------------API v--------------------------
function OnFrameBreathe()
	if m_bMoveBlueprint and HLBOp_Main.GetMoveObjEnabled() then
        MoveLoadBlueprint()
	end
end

function OnInteractError()

end

function ClearData()
    m_szFile = ""
    m_nStartLoadRes = -1
    m_bMoveBlueprint = false
    m_bHaveBeyondObject = false
    m_bPreMoveBigBlpRes = false
    m_dwMovePartObjID = 0
    m_bInLoadBlueprint = false
    m_tTempStore = {}
end

function ClearBlueprintInfo()
    m_nTempBluePrintIndex = 0
    m_nTempBluePrintOffset = 0
    m_nBluePrintIndex = 0
    m_nBluePrintOffset = 0
end

function GetBlueprintInfo()
    return m_nBluePrintIndex, m_nBluePrintOffset
end

function GetInLoadBlueprint()
    return m_bInLoadBlueprint
end

function Init()
    m_szFile = ""
    m_nStartLoadRes = -1
    m_bMoveBlueprint = false
    m_bHaveBeyondObject = false
    m_bPreMoveBigBlpRes = false
    m_dwMovePartObjID = 0
    m_bInLoadBlueprint = false
    m_tTempStore = {}
    m_szTempCode = ""
    m_bTempReplace = false
    m_nTempBluePrintIndex = 0
    m_nTempBluePrintOffset = 0
    m_nBluePrintIndex = 0
    m_nBluePrintOffset = 0
    m_szNormalCode = nil
end

function UnInit()
    m_szFile = nil
    m_nStartLoadRes = nil
    m_bMoveBlueprint = nil
    m_bHaveBeyondObject = nil
    m_bPreMoveBigBlpRes = nil
    m_dwMovePartObjID = nil
    m_bInLoadBlueprint = nil
    m_tTempStore = nil
    m_szTempCode = nil
    m_bTempReplace = false
    m_nTempBluePrintIndex = 0
    m_nTempBluePrintOffset = 0
    m_nBluePrintIndex = 0
    m_nBluePrintOffset = 0
    m_szNormalCode = nil
end

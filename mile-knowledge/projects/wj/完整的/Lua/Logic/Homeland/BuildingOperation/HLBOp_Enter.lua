NewModule("HLBOp_Enter")

m_dwMapID = 0
m_nCopyIndex = 0
m_nLandIndex = 0
m_bInCohabit = false
m_bIsTenant = false
m_szLandID = ""
m_szLandName = ""
m_nHistoryVer = 0
m_szDownloadedSdkPath = ""
m_szBakFilePath = ""
m_nLandLevel = 1
m_bInBuilding = false --保存结束后会收到HOME_LAND_START_BUILDING 屏蔽
m_szCode = "" --数字蓝图码
m_bReplaceNow = false -- 当前地上是不是数字蓝图副本
m_bReadyStartBuilding = false

--设计场
m_nDesignYardSceneIndex = 0
m_nDesignYardLength = 0
m_nDesignYardWidth = 0
m_dwSceneIdForDesign = -1
m_bDesignPrivateHome = false

local WAIT_START_BUILD_TIME = 8 --秒

local function GetSdkFolder()
	return "homeland/" .. GetClientPlayer().GetGlobalID()
end

local function ShowErrorMsg(szMsg)
    local szPath = Homeland_GetPathForDisplay(GetFullPath(GetSdkFolder()))
    szPath = UIHelper.GBKToUTF8(szPath)
    local dialog = UIHelper.ShowConfirm(FormatString(g_tStrings.STR_HOMELAND_BUILDING_ENTER_FAILED, szMsg, szPath), function ()
        HLBOp_Main.Exit()
    end, function ()
        HLBOp_Main.Exit()
        Lib.RemoveDirectory(szPath.."\\maps")
        local ret = Lib.RemoveDirectory(szPath)
        local dialog1 = UIHelper.ShowConfirm("清除缓存成功，请重新登录游戏再尝试进入建造模式", function ()
            Global.BackToLogin(true)
        end)
        dialog1:HideButton("Cancel")
    end)
    dialog:SetCancelButtonContent("清除缓存")
end

local function ShowErrorByDownload()
    RemoteCallToServer("On_HomeLand_BuildError", m_nLandIndex, "Download Error")
    ShowErrorMsg(g_tStrings.STR_HOMELAND_BUILDING_ENTER_FAILED_BY_DOWNLOAD)
end
local function ShowErrorByEnter()
    RemoteCallToServer("On_HomeLand_BuildError", m_nLandIndex, "Enter Error")
    ShowErrorMsg(g_tStrings.STR_HOMELAND_BUILDING_ENTER_FAILED_BY_ENTER)
end
local function ShowErrorByLoad()
    RemoteCallToServer("On_HomeLand_BuildError", m_nLandIndex, "Load Error")
    ShowErrorMsg(g_tStrings.STR_HOMELAND_BUILDING_ENTER_FAILED_BY_LOAD)
end
local function ShowErrorByOwner()
    RemoteCallToServer("On_HomeLand_BuildError", m_nLandIndex, "Owner Error")
    ShowErrorMsg(g_tStrings.STR_HOMELAND_BUILDING_ENTER_FAILED_BY_OWNER)
end
---------------------------发送消息 或调用接口 v--------------------------
function GetDigitalInfo()
    local hlMgr = GetHomelandMgr()
    local szCode = hlMgr.GetDigitalBlpSN()
    Homeland_Log("Enter szCode", szCode)
    SetCode(szCode)
end


function Enter()
    local tConfig = Homeland_GetModeConfig(HLBOp_Main.GetBuildMode())
    local hlMgr = GetHomelandMgr()

    if not tConfig.bDesign then
        m_nLandIndex = hlMgr.GetNowLandIndex()
        m_dwMapID, m_nCopyIndex = Homeland_GetMapAndCopyIndex()
        assert(m_nLandIndex ~= 0, "取到LandIndex为0")
        --之后流程优化一下
        UpdateCohabit()
        UpdateTenant()
        UpdateLevel()
        Homeland_Log("开始进入建造 BuildLock 参数：", m_nLandIndex, HOMELAND_BUILD_LOCK_TYPE.LOCK)
        hlMgr.BuildLock(m_nLandIndex, HOMELAND_BUILD_LOCK_TYPE.LOCK)
    else
        StartLocalBuilding()
        ApplyInfoInDesign()
        EnterBuilding()
    end
end

function ApplyInfo()
    Homeland_Log("ApplyInfo")
    local hlMgr = GetHomelandMgr()
    hlMgr.ApplyMyLandInfo(m_nLandIndex) --更新共居
    hlMgr.ApplyHLLandInfo(m_nLandIndex) --更新是不是租客
	hlMgr.ApplyLandInfo(m_dwMapID, m_nCopyIndex, m_nLandIndex) --为之后的Get做准备
end

function ApplyInfoInDesign()
    local hlMgr = GetHomelandMgr()
	local dwMapID, nCopyIndex = Homeland_GetMapAndCopyIndex()
	if hlMgr.IsPrivateHomeMap(dwMapID) then
		local nMaxIndex = hlMgr.GetMaxMainLandIndex(dwMapID)
		for i = 1, nMaxIndex do
			hlMgr.ApplyHLLandInfo(dwMapID, nCopyIndex, i)
		end
	end
end

function StartBuilding()  --开始建造或回滚版本
    local hlMgr = GetHomelandMgr()
    local bResult = false
    bResult = hlMgr.CheckStartBuilding(m_nLandIndex, m_nHistoryVer)
    Homeland_Log("检测是否能不能进入建造CheckStartBuilding, 返回", m_nLandIndex, m_nHistoryVer, bResult)
    if bResult then
        hlMgr.StartBuilding(m_nLandIndex, m_nHistoryVer)
        RemoteCallToServer("On_HomeLand_Build") --完成成就
    else
        TipsHelper.ShowNormalTip(g_tStrings.STR_HOMELAND_BUILDING_ENTER_WAIT)
        HLBOp_Main.Exit()
    end
end

function StartLocalBuilding()
    local hlMgr = GetHomelandMgr()
    hlMgr.StartLocalBuilding()
end

function EnterBuilding()
    CameraMgr.Zoom(1.0) -- 需要在进入建造之前调用, 先重置镜头状态
	rlcmd(("homeland -range offset %f %f %f"):format(5000, 10000, 5000)) -- 需要在进入建造之前调用

    local nMode = HLBOp_Main.GetBuildMode()
    local tConfig = Homeland_GetModeConfig(nMode)
    local bResult = false

    if not tConfig.bDesign then
        HLBOp_Amount.LandBuildReset(m_nLandLevel, m_nLandIndex, m_nHistoryVer)
        local hlMgr = GetHomelandMgr()
        local szCode = hlMgr.GetDigitalBlpSN()
        local nIsDigital = 0
        if szCode ~= "" then
            nIsDigital = 1
        end
        LOG.TABLE({m_szLandName = m_szLandName, m_szDownloadedSdkPath = m_szDownloadedSdkPath, nIsDigital = nIsDigital})
        bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.ENTER, m_szLandName, m_szDownloadedSdkPath, nIsDigital, 0)
        Homeland_Log("发送HOMELAND_BUILD_OP.ENTER", m_szLandName, m_szDownloadedSdkPath, bResult)
    elseif tConfig.bTest then
        bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.ENTER, "", "", 0)
    elseif tConfig.bDesign then
        bResult, m_dwSceneIdForDesign = Homeland_SendMessage(HOMELAND_BUILD_OP.ENTER_NEW_SCENE, m_nDesignYardSceneIndex, m_nDesignYardLength, m_nDesignYardWidth)
        Homeland_Log("发送HOMELAND_BUILD_OP.ENTER_NEW_SCENE", m_nDesignYardSceneIndex, m_nDesignYardLength, m_nDesignYardWidth, bResult, m_dwSceneIdForDesign) --没有返回事件
        m_bInBuilding = true
        HLBOp_Amount.LoadLandData(m_nLandLevel, m_nLandIndex, m_nHistoryVer)
        HLBOp_Group.RequestAllGroupIDs()
        HLBOp_Other.InitBaseboard()
        -- HLBView_Main.Open()

        UIMgr.CloseAllInLayer(UILayer.Page)
        UIHelper.BlackMaskEnter(VIEW_ID.PanelConstructionMain1, function ()
            UIMgr.Open(VIEW_ID.PanelConstructionMain1)
            HLBOp_Camera.UpdateCamMoveSpeed()
        end)
    end

    if not bResult then
        ShowErrorByEnter()
    end

    Homeland_ServerLog(nMode, HOMELAND_LOG_NUM.ENTER_BUILDING)
end

function OnEvent(szEvent)
    if szEvent == "HOME_LAND_RESULT_CODE" then
        local nRetCode = arg0
        if nRetCode == HOMELAND_RESULT_CODE.LAND_BUILD_LOCK_SUCCEED then
            OnHomelandLockSuccessRes()
        elseif nRetCode == HOMELAND_RESULT_CODE.LAND_BUILD_LOCK_FAILED then
            OnHomelandLockFailRes()
        elseif nRetCode == HOMELAND_RESULT_CODE.DELAY_START_BUILDING then
            OnHomelandDelayStartBuildingRes()
        end
    elseif szEvent == "HOME_LAND_RESULT_CODE_INT" then
        local nRetCode = arg0
        if nRetCode == HOMELAND_RESULT_CODE.APPLY_HLLAND_INFO then
            OnHomelandApplyHLLandRes()
        elseif nRetCode == HOMELAND_RESULT_CODE.APPLY_MY_LAND_INFO_RESPOND then
            OnHomeladApplyMyLandRes()
        end
    elseif szEvent == "HOME_LAND_START_BUILDING" then
        OnHomelandStartBuilding()
    elseif szEvent == "HOMELAND_CALL_RESULT" then
        local eOperationType = arg0
        if eOperationType == HOMELAND_BUILD_OP.ENTER then
            OnEnterBuildingResult()
        end
    end
end

---------------------------接收消息v-------------------------

function OnHomelandLockSuccessRes()
    Homeland_Log("收到HOMELAND_RESULT_CODE.LAND_BUILD_LOCK_SUCCEED")
    local hlMgr = GetHomelandMgr()
    m_szLandID = hlMgr.GetLandID(m_dwMapID, m_nCopyIndex, m_nLandIndex)
    m_szLandName = hlMgr.GetLandName(m_nLandIndex)
    ApplyInfo()
    m_nHistoryVer = 0
    m_bReadyStartBuilding = true
end

function OnHomelandLockFailRes()
    Homeland_Log("收到HOMELAND_RESULT_CODE.LAND_BUILD_LOCK_FAILED, 退出")
    HLBOp_Main.Exit()
end

function OnHomeladApplyMyLandRes()
    local dwMapID, nCopyIndex, nLandIndex = arg1, arg2, arg3
    if m_dwMapID == dwMapID and m_nCopyIndex == nCopyIndex and m_nLandIndex == nLandIndex then
        UpdateCohabit()
    end

    if m_bReadyStartBuilding then
        m_bReadyStartBuilding = false
        StartBuilding()
    end
end

function OnHomelandApplyHLLandRes()
    local dwMapID, nCopyIndex, nLandIndex = arg1, arg2, arg3
    if m_dwMapID == dwMapID and m_nCopyIndex == nCopyIndex and m_nLandIndex == nLandIndex then
        UpdateTenant()
        UpdateLevel()
    end
end

function OnHomelandStartBuilding()
    local bSuccess = arg0
    local nLandIndex = arg1
    local szDownloadedSdkPath = arg2
    local bHasBakFile = Homeland_ToBoolean(arg3)
    local szBakFilePath = arg4
    local bHasBakBlueprint = Homeland_ToBoolean(arg5)
    local szBakBlueprintFile = arg6
    local bSync = arg7
    Homeland_Log("收到事件HOME_LAND_START_BUILDING, 返回", arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7)
    if nLandIndex ~= m_nLandIndex then
        if m_nLandIndex then
            ShowErrorByOwner()
        end
        return
    end
    m_szBakFilePath = szBakFilePath
    local hlMgr = GetHomelandMgr()

    if m_bInBuilding then
        if bSuccess then
            --与共居家具提取有关
            local nLandLevel, nLandIndex, nVerIndex = HLBOp_Enter.GetLevel(), HLBOp_Enter.GetLandIndex(), HLBOp_Enter.GetHistoryVer()
            HLBOp_Amount.LoadLandData(nLandLevel, nLandIndex, nVerIndex)
        end
        return
    end

    if bSuccess and (not bSync) then --等待SDK文件下载完
        StartBuilding()
        return
    end

    if not bSuccess and (not bSync) then
        ShowErrorByDownload()
        return
    end

    if bSuccess then
        local function fnEnter()
            m_szDownloadedSdkPath = Platform.IsMac() and szDownloadedSdkPath or GetFullPath(szDownloadedSdkPath)
            m_bInBuilding = true
            EnterBuilding()
        end

        if bHasBakFile then
            local function fnAction()
                HLBOp_Save.DoApplyBak(m_szLandID, CPath.GetFileName(m_szBakFilePath) .. ".bak")
            end

            local dialog = UIHelper.ShowConfirm(g_tStrings.STR_HOMELAND_BUILDING_START_FROM_BAK_SDK_CONFIRM, fnAction, fnEnter)
            dialog:SetButtonContent("Confirm", "恢复")
            dialog:SetButtonContent("Cancel", "放弃并进入")
        else
            fnEnter()
        end
    end
end

function OnHomelandDelayStartBuildingRes()
    Homeland_Log("收到HOMELAND_RESULT_CODE.DELAY_START_BUILDING")
    local dialog = UIHelper.ShowConfirm(g_tStrings.STR_HOMELAND_NEED_DELAY_START_BUILDING, function ()
        local bResult = false
        local hlMgr = GetHomelandMgr()
        bResult = hlMgr.CheckStartBuilding(m_nLandIndex, m_nHistoryVer)
        if bResult then
            StartBuilding()
        else
            OnHomelandDelayStartBuildingRes()
        end
    end, function ()
        HLBOp_Main.Exit()
        UIMgr.Close(VIEW_ID.PanelConstructionMain)
    end)

    dialog:SetButtonContent("Confirm", g_tStrings.STR_HOMELAND_RETRY_START_BUILDING)
    dialog:SetButtonContent("Cancel", g_tStrings.STR_CANCEL)
end

function OnEnterBuildingResult()
    local bResult = Homeland_ToBoolean(arg2)
    Homeland_Log("收到HOMELAND_BUILD_OP.ENTER", bResult)
    if bResult then
        HLBOp_Amount.LoadLandData(m_nLandLevel, m_nLandIndex, m_nHistoryVer)
        GetDigitalInfo()
        HLBOp_Group.RequestAllGroupIDs()
        HLBOp_Other.InitBaseboard()
        -- HLBView_Main.Open()
        if not UIMgr.GetView(VIEW_ID.PanelConstructionMain) then
            UIMgr.Open(VIEW_ID.PanelConstructionMain)
        end
        m_nHistoryVer = 0
    else
        ShowErrorByLoad()
    end
end

---------------------------API v--------------------------
function UpdateCohabit()
    local tBaseInfo = GetHomelandMgr().GetLandAlliedBaseInfo(m_nLandIndex)
    assert(tBaseInfo, "GetLandAlliedBaseInfo共居信息取到为nil")
    m_bInCohabit = tBaseInfo and tBaseInfo.Count > 0
    Homeland_Log("m_bInCohabit", m_bInCohabit)
end

function UpdateTenant()
    local tInfo = GetHomelandMgr().GetHLLandInfo(m_nLandIndex)
    m_bIsTenant = tInfo.dwOwnerID ~= GetClientPlayer().dwID
    Homeland_Log("m_bIsTenant", m_bInCohabit)
end

function UpdateLevel()
    local tInfo = GetHomelandMgr().GetHLLandInfo(m_nLandIndex)
    m_nLandLevel = tInfo.nLevel
    Homeland_Log("m_nLandLevel", m_nLandLevel)
end

function GetSceneID()
    return m_dwSceneIdForDesign
end

function GetLevel()
    return m_nLandLevel
end

function GetLandIndex()
    return m_nLandIndex
end

function GetLandMapInfo()
    return m_dwMapID, m_nCopyIndex, m_nLandIndex
end

function IsTenant()
    return m_bIsTenant
end

function IsCohabit()
    return m_bInCohabit
end

function IsDesignPrivateHome()
    return m_bDesignPrivateHome
end

function GetLandID()
    return m_szLandID
end

function GetBakFilePath()
    return m_szBakFilePath
end

function GetHistoryVer(nIndex)
    return m_nHistoryVer
end

function SetCode(szCode)
    m_szCode = szCode
    Homeland_Log("当前地上蓝图码 m_szCode", m_szCode)
    if IsDigitalBlueprint() then
        OutputMessage("MSG_SYS", g_tStrings.STR_HOMELAND_BUILDING_CLOSE_AUTO_SAVE)
    else
        OutputMessage("MSG_SYS", g_tStrings.STR_HOMELAND_BUILDING_OPEN_AUTO_SAVE)
    end
end

function GetCode()
    return m_szCode
end

function IsDigitalBlueprint()
    return (m_szCode ~= "")
end

function IsDigitalBlueprintInLand()
	local szCodeInLand = GetCode()--当前地上是不是数字蓝图
    return (szCodeInLand ~= "")
end

function GetLandSize()
    local tConfig = Homeland_GetModeConfig(HLBOp_Main.GetBuildMode())
	if not tConfig.bDesign then
		local dwCurMapID, nCurCopyIndex = Homeland_GetMapAndCopyIndex()
		local tLandUIInfo = Table_GetMapLandInfo(dwCurMapID, m_nLandIndex)
		return tLandUIInfo.nArea
	elseif tConfig.bDesign then
		return m_nDesignYardLength * m_nDesignYardWidth
    elseif tConfig.bTest then
		return 0
	end
end

function SetAppliedReplace(bReplace)
    m_bReplaceNow = bReplace
end

function GetAppliedReplace()
    return m_bReplaceNow
end

function SetLevel(nLevel)
    m_nLandLevel = nLevel
end

function SetDesignInfo(nDesignYardSceneIndex, nDesignYardLength, nDesignYardWidth, bPrivateHome)
    if nDesignYardSceneIndex then
        m_nDesignYardSceneIndex = nDesignYardSceneIndex
    end
    if nDesignYardLength then
        m_nDesignYardLength = nDesignYardLength
    end
    if nDesignYardWidth then
        m_nDesignYardWidth = nDesignYardWidth
    end
    if bPrivateHome then
        m_bDesignPrivateHome = bPrivateHome
    end
end

function GetArea()
    local bPrivate, nArea = false, 1280
    local nMode = HLBOp_Main.GetBuildMode()
    local tConfig = Homeland_GetModeConfig(nMode)

    if nMode == BUILD_MODE.COMMUNITY then
        local tLine = Table_GetMapLandInfo(m_dwMapID, m_nLandIndex)
        nArea = tLine.nArea
        return false, nArea
    elseif nMode == BUILD_MODE.PRIVATE then
        local tLine = Table_GetMapLandInfo(m_dwMapID, m_nLandIndex)
        nArea = tLine.nArea
        return true, nArea
    elseif nMode == BUILD_MODE.DESIGN then
        return m_bDesignPrivateHome, m_nDesignYardLength * m_nDesignYardWidth
    end
end

function GetDesignYardSceneIndex()
    return m_nDesignYardSceneIndex
end

function SetInBuilding(bIn)
    m_bInBuilding = bIn
end

function OnFrameBreathe()
    if m_bInCohabit and GetLogicFrameCount() % (25 * GLOBAL.GAME_FPS) == 0 then
		GetHomelandMgr().BuildLock(m_nLandIndex, HOMELAND_BUILD_LOCK_TYPE.KEEP_LOCK)
	end
end

function Init()
    m_dwMapID = 0
    m_nCopyIndex = 0
    m_nLandIndex = 0
    m_bInCohabit = false
    m_bIsTenant = false
    m_szLandID = ""
    m_szLandName = ""
    m_nHistoryVer = 0
    m_szDownloadedSdkPath = ""
    m_szBakFilePath = ""
    m_nLandLevel = 1
    m_bInBuilding = false
    m_bIsDigital = false
    m_szCode = ""
    m_bReplaceNow = false
    m_bReadyStartBuilding = false

    --设计场
    m_nDesignYardSceneIndex = 0
    m_nDesignYardLength = 0
    m_nDesignYardWidth = 0
    m_bDesignPrivateHome = false
    m_dwSceneIdForDesign = -1
end

function UnInit()
    m_dwMapID = nil
    m_nCopyIndex = nil
    m_nLandIndex = nil
    m_bInCohabit = nil
    m_bIsTenant = nil
    m_szLandID = nil
    m_szLandName = nil
    m_nHistoryVer = nil
    m_szDownloadedSdkPath = nil
    m_szBakFilePath = nil
    m_nLandLevel = nil
    m_bInBuilding = nil
    m_bIsDigital = nil
    m_szCode = ""
    m_bReplaceNow = false
    m_bReadyStartBuilding = false

    --设计场
    m_nDesignYardSceneIndex = nil
    m_nDesignYardLength = nil
    m_nDesignYardWidth = nil
    m_bDesignPrivateHome = nil
    m_dwSceneIdForDesign = nil
end
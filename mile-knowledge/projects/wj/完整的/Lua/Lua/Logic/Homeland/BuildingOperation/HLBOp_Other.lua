
NewModule("HLBOp_Other")

local INIT_TIME = 1
local INIT_WEATHER = 1

m_tObjPos = {} --{[dwObjID] = {}}
m_tObjYaw = {} --{[dwObjID] = {}}
m_tObjPosInfo = {} --{[dwObjID] = {}}
m_nLastFocusMode = 0
m_nCamViewIndex = 0

local GET_POSTION_TYPE = {
	NORMAL = 1,
}

---------------------------发送消息v--------------------------
function TurnBase()
    HLBOp_Main.SetModified(true)
    HLBOp_Step.StartOneStep("TurnBase")
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.TURN_BASE, 0)
    Homeland_Log("发送HOMELAND_BUILD_OP.TURN_BASE", bResult)
    HLBOp_Step.EndOneStep()
end

function GetModelPostion(dwObjID)
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.GET_MODEL_POSITION, dwObjID, GET_POSTION_TYPE.NORMAL)
end

function GetModelRotation(dwObjID)
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.GET_MODEL_ROTATION, dwObjID, dwObjID)
end

function GetObjectInfo(dwObjID)
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.GET_OBJECT_INFO, dwObjID, dwObjID)
    Homeland_Log("发送HOMELAND_BUILD_OP.GET_OBJECT_INFO", dwObjID, bResult)
end

function RemoveBasebord(dwObjID)
    local dwModelID = HLBOp_Amount.GetModelIDByObjID(dwObjID)
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.REMOVE_BASEBOARD, dwObjID, dwModelID)
    Homeland_Log("发送HOMELAND_BUILD_OP.REMOVE_BASEBOARD", dwObjID, bResult)
end

function ScreenShot360()
	local szShotFolder = Homeland_GetExportedShot360Folder()
    CPath.MakeDir(szShotFolder)
    local szPostfix = ".png"
	local szFileName = "HomelandShot"
	local tTime = TimeToDate(GetCurrentTime())
    local szTime = string.format("%d%02d%02d-%02d%02d%02d", tTime.year, tTime.month, tTime.day, tTime.hour, tTime.minute, tTime.second)
    local szFilePath = szShotFolder .. szFileName .. "_" .. szTime .. szPostfix

	if PanoramagramScreenShot(szFilePath, 2048, 0) ~= nil then
		TipsHelper.ShowNormalTip(g_tStrings.STR_HOMELAND_BUILDING_SHOT_360)
        end
	end

function MechanismReverse(dwObjID)
	local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.REVERSE_TRANSMIT_POINT, dwObjID, dwObjID)
    Homeland_Log("HOMELAND_BUILD_OP.REVERSE_TRANSMIT_POINT", dwObjID, bResult)
	HLBOp_Main.SetModified(true)
end

function OnEvent(szEvent)
	if szEvent == "HOMELAND_CALL_RESULT" then
		local eOperationType = arg0
		if eOperationType == HOMELAND_BUILD_OP.TURN_BASE then
            OnTurnBaseResult()
        elseif eOperationType == HOMELAND_BUILD_OP.GET_MODEL_POSITION then
            OnGetModelPostionResult()
        elseif eOperationType == HOMELAND_BUILD_OP.GET_OBJECT_INFO then
            OnGetObjectInfoResult()
        elseif eOperationType == HOMELAND_BUILD_OP.REMOVE_BASEBOARD then
            OnRemoveBasebord()
        elseif eOperationType == HOMELAND_BUILD_OP.GET_MODEL_ROTATION then
            OnGetModelRotationResult()
		elseif eOperationType == HOMELAND_BUILD_OP.REVERSE_TRANSMIT_POINT then
			OnMechanismReverseResult()
		end
	end
end

---------------------------接收消息v--------------------------
function OnTurnBaseResult()
    local nUserData = arg1
    local nResult = arg2
    local bResult = Homeland_ToBoolean(nResult)
    Homeland_Log("收到HOMELAND_BUILD_OP.TURN_BASE", bResult)
    if bResult then
        HLBView_Message.Show(g_tStrings.STR_HOMELAND_BUILDING_TURN_BASE_SUCCESS, 3)
    else
        HLBView_Message.Show(g_tStrings.STR_HOMELAND_BUILDING_TURN_BASE_FAILED, 3)
    end
end

function OnGetModelPostionResult()
    local nUserData = arg1
    local nResult = arg2
    local bResult = Homeland_ToBoolean(nResult)
    if not bResult then
        return
    end
    local fX, fY, fZ = arg3, arg4, arg5
	local fScreenX, fScreenY = arg6, arg7
    local dwObjID = arg8
	if nUserData == GET_POSTION_TYPE.NORMAL then
		m_tObjPos = {[dwObjID] = {fX = fX, fY = fY, fZ = fZ, fScreenX = fScreenX, fScreenY = fScreenY}}
    	FireUIEvent("LUA_HOMELAND_UPDATE_ITEMOP_SHOW")
	end
end

local function IsNan(v)
	return tostring(v) == tostring(0/0)
end

function OnGetObjectInfoResult()
    local nUserData = arg1
    local nResult = arg2
    local bResult = Homeland_ToBoolean(nResult)
    Homeland_Log("收到HOMELAND_BUILD_OP.GET_OBJECT_INFO", bResult)

    if not bResult then
        return
    end

    local nObjID = nUserData
    local dwModelID = arg3
	local fPitch = arg4
    local fYaw = arg5
	local fRoll = arg6
    local fXScale = arg7
	local fYScale = arg8
	local fZScale = arg9
	local fYPos = arg10
    local nColorIndex = arg11
    m_tObjPosInfo = {[nObjID] = {dwModelID = dwModelID, fPitch = fPitch, fYaw = fYaw, fRoll = fRoll,
		fXScale = fXScale, fYScale = fYScale, fZScale = fZScale, fYPos = fYPos, nColorIndex = nColorIndex}}
    FireUIEvent("LUA_HOMELAND_UPDATE_ITEMOP_INFO")
end

function OnRemoveBasebord()
    local nUserData = arg1
    local nResult = arg2
    local bResult = Homeland_ToBoolean(nResult)
    local dwModelID = nUserData
    Homeland_Log("收到HOMELAND_BUILD_OP.REMOVE_BASEBOARD", bResult)
    if not bResult then
        HLBView_Message.Show(g_tStrings.STR_HOMELAND_REMOVE_BASEBOARD_FAILED, 3)
        return
    end
    local tAddConsumption = {{nModelID = dwModelID, nModelAmount = -1}}

    --回撤删除步骤
    Homeland_SendMessage(HOMELAND_BUILD_OP.REMOVE_OPERATION, 2, 0)

    HLBOp_Amount.ChangeLandData(tAddConsumption)
    HLBOp_Group.RequestAllGroupIDs()

	local scriptView = UIHelper.ShowConfirm(g_tStrings.STR_HOMELAND_REMOVE_BASEBOARD_SUCCESS)
	scriptView:HideButton("Cancel")

end

function OnGetModelRotationResult()
    local nUserData = arg1
    local nResult = arg2
    local bResult = Homeland_ToBoolean(nResult)
    if not bResult then
        return
    end
    local dwObjID = nUserData
    local fPitch = GetRoundedNumber(arg3 * 180 / math.pi)
	local fYaw = GetRoundedNumber(arg4 * 180 / math.pi)
	local fRoll = GetRoundedNumber(arg5 * 180 / math.pi)
    m_tObjYaw = {[dwObjID] = {fPitch = fPitch, fYaw = fYaw, fRoll = fRoll}}
end

function OnMechanismReverseResult()
	local nUserData = arg1
	local nResult = arg2
	local bResult = Homeland_ToBoolean(nResult)
	Homeland_Log("收到HOMELAND_BUILD_OP.REVERSE_TRANSMIT_POINT", bResult)
	if not bResult then
		HLBView_Message.Show(g_tStrings.STR_HOMELAND_BUILDING_REVERSE_MECHANISM_ERROR, 3)
	end
end

---------------------------API v--------------------------
function GetOneObjectScreenPos(dwObjID)
    if not m_tObjPos[dwObjID] then
        return nil
    end
    return m_tObjPos[dwObjID].fScreenX, m_tObjPos[dwObjID].fScreenY
end

function GetOneObjectYaw(dwObjID)
    if not m_tObjYaw[dwObjID] then
        return 0
    end
    return m_tObjYaw[dwObjID].fYaw
end

function GetOneObjectInfo(dwObjID)
    return m_tObjPosInfo[dwObjID]
end

function SwitchWeather(nTime, nWeather)
	if nTime and nWeather then
		local szEnvironment = Table_GetHomelandEnvironment(nTime, nWeather)
		rlcmd("reset environment " .. szEnvironment)
	end
end

function UnInitWeather()
    rlcmd("reset environment")
    rlcmd("reset local dynamic weather idx")

	SelfieData.ResetFilterFromStorage(true)
end

function InitWeather()
    SwitchWeather(INIT_TIME, INIT_WEATHER)

	KG3DEngine.SetPostRenderChromaticAberrationEnable(false)
    KG3DEngine.SetPostRenderFilterChromaticAberration(0)
end

function InitGrid()
    local nShow = g_HomelandBuildingData.bShowGrid and 1 or 0
    rlcmd("homeland -girds " .. nShow)
end

function SetGrid(bShow)
    local nShow = bShow and 1 or 0
    rlcmd("homeland -girds " .. nShow)
end

function InitGridAlignment()
    local nEnable = g_HomelandBuildingData.bGridAlignEnabled and 1 or 0
	rlcmd("homeland -force alignment " .. nEnable)
end

function SetGridAlignment(bEnable)
	local nEnable = bEnable and 1 or 0
	rlcmd("homeland -force alignment " .. nEnable)
end

function InitBaseboard()
    local nShow = g_HomelandBuildingData.bShowBaseboards and 1 or 0
    Homeland_SendMessage(HOMELAND_BUILD_OP.SHOW_ALL_BASEBOARDS, nShow, 0)
end

function SetBaseboard(bShow)
    local nShow = bShow and 1 or 0
    Homeland_SendMessage(HOMELAND_BUILD_OP.SHOW_ALL_BASEBOARDS, nShow, 0)
end

function InitMultiSelectBasement()
    local nEnable = g_HomelandBuildingData.bEnableMultiSelectBasement and 0 or 1
    rlcmd("homeland -ingore basement dragover " .. nEnable)
end

function SetMultiSelectBasement(bEnable)
    local nEnable = bEnable and 0 or 1
    rlcmd("homeland -ingore basement dragover " .. nEnable)
end

function EnableSmartBrush(bEnable)
    local nEnable = bEnable and 1 or 0
    rlcmd("homeland -smart brush " .. nEnable)
end

function FocusObject(dwObjID, nRotateAngle)
	if not nRotateAngle then
		if m_nLastFocusMode == 0 then
			rlcmd(("homeland -focus %d %d %d %f"):format(dwObjID, 0, -45, 2)) -- 第四个参数表示物体尺寸的倍数
			m_nLastFocusMode = 1
		else
			rlcmd(("homeland -focus %d %d %d %f"):format(dwObjID, 0, -90, 2)) -- 第四个参数表示物体尺寸的倍数
			m_nLastFocusMode = 0
		end
	else
		rlcmd(("homeland -focus %d %d %d %f"):format(dwObjID, 0, nRotateAngle, 2))
	end
end

function NextCameraMode()
	SwitchCamView(1)
end

function PrevCameraMode()
	SwitchCamView(-1)
end

function ResetCameraMode()
	m_nCamViewIndex = nil
	Event.Dispatch(EventType.OnHomelandResetCameraMode)
end

function GetCameraModeDesc()
	if m_nCamViewIndex == 1 then
		return "俯视"
	else
		return "默认"
	end
end

function SwitchCamView(nStep)
	if m_nCamViewIndex == nil then
		m_nCamViewIndex = 1
	else
    	m_nCamViewIndex = m_nCamViewIndex + (nStep or 1)
	end

	if m_nCamViewIndex < 0 then
		m_nCamViewIndex = 1
	end

	if m_nCamViewIndex > 1 then
		m_nCamViewIndex = 0
	end

    if m_nCamViewIndex == 0 then
		rlcmd("set homeland camera mode 400 -23")
	else
		rlcmd("set homeland camera mode 4000 -90")
	end
end

function SetCamView(nIndex)
	m_nCamViewIndex = nIndex

	if m_nCamViewIndex == 0 then
		rlcmd("set homeland camera mode 400 -23")
	else
		rlcmd("set homeland camera mode 4000 -90")
	end
end
function Init()
    InitWeather()
    InitGrid()
    InitGridAlignment()
    InitMultiSelectBasement()
    m_tObjPos= {}
    m_tObjPosInfo = {}
    m_tObjYaw = {}
    m_nLastFocusMode = 0
    m_nCamViewIndex = 0
end

function UnInit()
    UnInitWeather()
    m_tObjPos = nil
    m_tObjPosInfo = nil
    m_tObjYaw = nil
    m_nLastFocusMode = nil
    m_nCamViewIndex = nil
end

-----------------------物件列表相关-------------------------------------
local function _GetExportedErrorListFolder()
	return UIHelper.GBKToUTF8(GetStreamAdaptiveDirPath(GetFullPath("homelanddir") .. "/errorList/"))
end

local function _GetExportedObjListFolder()
	return UIHelper.GBKToUTF8(GetStreamAdaptiveDirPath(GetFullPath("homelanddir") .. "/furniturelist/"))
end

local function GetFurnitureArchitectureByModelID(dwModelID)
	local tLine = FurnitureData.GetFurnInfoByModelID(dwModelID)
	if tLine then
		local tConfig
		local bSpecialBuy = false
		if tLine.nFurnitureType == HS_FURNITURE_TYPE.FURNITURE then
			tConfig = GetHomelandMgr().GetFurnitureConfig(tLine.dwFurnitureID)
			bSpecialBuy = FurnitureBuy.IsSpecialFurnitrueCanBuy(tLine.dwFurnitureID)
		elseif tLine.nFurnitureType == HS_FURNITURE_TYPE.PENDANT then
			tConfig = GetHomelandMgr().GetPendantConfig(tLine.dwFurnitureID)
		end

		if tConfig and tConfig.nArchitecture and tConfig.nArchitecture > 0 then
			return tConfig.nArchitecture
		end
		if tConfig and tConfig.nReBuyCost and tConfig.nReBuyCost > 0 and bSpecialBuy then
			return tConfig.nReBuyCost
		end
	end
	return nil
end

-- szErrType: "CanBuy"/"GetSpecial"/"CatgOverflow"/"LevelOverflow"
local function _GenerateExportedErrorListContent(szErrType, tErrorList)
	local hlMgr = GetHomelandMgr()
	local szContent = ""
	local szBriefLandInfo = ""
	local scene = GetClientScene()
	local dwCurMapID, nCurCopyIndex = scene.dwMapID, scene.nCopyIndex
	local szMapName, nMapLine, nLandIndex
	local pHlMgr = GetHomelandMgr()
	local tConfig = Homeland_GetModeConfig(HLBOp_Main.GetBuildMode())
	if not tConfig.bDesign then
		nLandIndex = pHlMgr.GetNowLandIndex()
		szMapName = Table_GetMapName(dwCurMapID)
		if pHlMgr.IsPrivateHomeMap(dwCurMapID) then
			nMapLine = 0
		else
			nMapLine = pHlMgr.GetCommunityInfo(dwCurMapID, nCurCopyIndex).nIndex
		end
	else -- 设计场模式
		nLandIndex = 0

		for _, v in pairs(g_tStrings.tHomelandDesignScene) do
			if v[1] == HLBOp_Enter.GetDesignYardSceneIndex() then
				local szSceneName = v[2]
				szMapName = g_tStrings.STR_HOMELAND_DESIGN_YARD_NAME_PREFIX .. szSceneName
				break
			end
		end

		nMapLine = 0
	end

	szBriefLandInfo = FormatString(UIHelper.UTF8ToGBK(g_tStrings.STR_HOMELAND_ERROR_LIST_EXPORT_FILE_DESC_LAND_INFO), szMapName, nMapLine, nLandIndex,
		HLBOp_Enter.GetLevel())

	if szErrType == "CanArchBuy" then
		local t = tErrorList.tCanArchBuy
		if t then
			local szLine = ""
			local dwModelID, tUIInfo
			local nCatg1, nCatg2, tCatg1UIInfo, tCatg2UIInfo
			local szCatg1Name, szCatg2Name
			local nLackedNum
			for nIndex, tOneInfo in pairs(t) do
				szLine = ""
				dwModelID = tOneInfo.dwModelID
				tUIInfo = FurnitureData.GetFurnInfoByModelID(dwModelID)
				if tUIInfo then
					nCatg1 = tUIInfo.nCatg1Index
					nCatg2 = tUIInfo.nCatg2Index
					tCatg1UIInfo = FurnitureData.GetCatg1Info(nCatg1)
					tCatg2UIInfo = FurnitureData.GetCatg2Info(nCatg1, nCatg2)
					szCatg1Name = tCatg1UIInfo and tCatg1UIInfo.szName or "?"
					szCatg2Name = tCatg2UIInfo and tCatg2UIInfo.szName or "??"

					szLine = szLine .. (tUIInfo and tUIInfo.szName or "UNKNOWN")
					szLine = szLine .. "\t" .. szCatg1Name
					szLine = szLine .. "\t" .. szCatg2Name

					nLackedNum = tOneInfo.nNum
					szLine = szLine .. "\t" .. tostring(nLackedNum)
					szLine = szLine .. "\t" .. tostring((GetFurnitureArchitectureByModelID(dwModelID) or 0) * nLackedNum)

					if szContent == "" then
						szContent = szContent .. szLine
					else
						szContent = szContent .. "\n" .. szLine
					end
				end
			end

			if szContent ~= "" then
				local szTitle = FormatString(UIHelper.UTF8ToGBK(g_tStrings.STR_HOMELAND_ERROR_LIST_EXPORT_FILE_DESC_CAN_BUY), szBriefLandInfo) .. "\n"
						.. UIHelper.UTF8ToGBK(g_tStrings.STR_HOMELAND_ERROR_LIST_EXPORT_FILE_TITLE_OBJ_NAME) .. "\t"
						.. UIHelper.UTF8ToGBK(g_tStrings.STR_HOMELAND_ERROR_LIST_EXPORT_FILE_TITLE_CATG1) .. "\t"
						.. UIHelper.UTF8ToGBK(g_tStrings.STR_HOMELAND_ERROR_LIST_EXPORT_FILE_TITLE_CATG2) .. "\t"
						.. UIHelper.UTF8ToGBK(g_tStrings.STR_HOMELAND_ERROR_LIST_EXPORT_FILE_TITLE_LACK_NUM) .. "\t"
						.. UIHelper.UTF8ToGBK(g_tStrings.STR_HOMELAND_ERROR_LIST_EXPORT_FILE_TITLE_ARCHITECTURE)
				szContent = szTitle .. "\n" .. szContent
			end
		end
	elseif szErrType == "CanCoinBuy" then
		local t = tErrorList.tCanCoinBuy
		if t then
			local szLine = ""
			local dwModelID, tUIInfo
			local nCatg1, nCatg2, tCatg1UIInfo, tCatg2UIInfo
			local szCatg1Name, szCatg2Name
			local nLackedNum
			for nIndex, tOneInfo in pairs(t) do
				szLine = ""
				dwModelID = tOneInfo.dwModelID
				tUIInfo = FurnitureData.GetFurnInfoByModelID(dwModelID)
				if tUIInfo then
					nCatg1 = tUIInfo.nCatg1Index
					nCatg2 = tUIInfo.nCatg2Index
					tCatg1UIInfo = FurnitureData.GetCatg1Info(nCatg1)
					tCatg2UIInfo = FurnitureData.GetCatg2Info(nCatg1, nCatg2)
					szCatg1Name = tCatg1UIInfo and tCatg1UIInfo.szName or "?"
					szCatg2Name = tCatg2UIInfo and tCatg2UIInfo.szName or "??"

					szLine = szLine .. (tUIInfo and tUIInfo.szName or "UNKNOWN")
					szLine = szLine .. "\t" .. szCatg1Name
					szLine = szLine .. "\t" .. szCatg2Name

					nLackedNum = tOneInfo.nNum
					szLine = szLine .. "\t" .. tostring(nLackedNum)
					szLine = szLine .. "\t" .. tostring((GetFurnitureArchitectureByModelID(dwModelID) or 0) * nLackedNum)

					if szContent == "" then
						szContent = szContent .. szLine
					else
						szContent = szContent .. "\n" .. szLine
					end
				end
			end

			if szContent ~= "" then
				local szTitle = FormatString(UIHelper.UTF8ToGBK(g_tStrings.STR_HOMELAND_ERROR_LIST_EXPORT_FILE_DESC_CAN_BUY), szBriefLandInfo) .. "\n"
						.. UIHelper.UTF8ToGBK(g_tStrings.STR_HOMELAND_ERROR_LIST_EXPORT_FILE_TITLE_OBJ_NAME) .. "\t"
						.. UIHelper.UTF8ToGBK(g_tStrings.STR_HOMELAND_ERROR_LIST_EXPORT_FILE_TITLE_CATG1) .. "\t"
						.. UIHelper.UTF8ToGBK(g_tStrings.STR_HOMELAND_ERROR_LIST_EXPORT_FILE_TITLE_CATG2) .. "\t"
						.. UIHelper.UTF8ToGBK(g_tStrings.STR_HOMELAND_ERROR_LIST_EXPORT_FILE_TITLE_LACK_NUM) .. "\t"
						.. UIHelper.UTF8ToGBK(g_tStrings.STR_HOMELAND_ERROR_LIST_EXPORT_FILE_TITLE_ARCHITECTURE)
				szContent = szTitle .. "\n" .. szContent
			end
		end
	elseif szErrType == "GetSpecial" then
		local t = tErrorList.tGetSpecial
		if t then
			local szLine = ""
			local dwModelID, tUIInfo
			local nCatg1, nCatg2, tCatg1UIInfo, tCatg2UIInfo
			local szCatg1Name, szCatg2Name
			local nFurnitureType, dwFurnitureID
			local dwUIFurnitureID, tItemAddInfo
			local szSource
			local nLackedNum
			for nIndex, tOneInfo in pairs(t) do
				szLine = ""
				dwModelID = tOneInfo.dwModelID
				tUIInfo = FurnitureData.GetFurnInfoByModelID(dwModelID)
				if tUIInfo then
					nCatg1 = tUIInfo.nCatg1Index
					nCatg2 = tUIInfo.nCatg2Index
					tCatg1UIInfo = FurnitureData.GetCatg1Info(nCatg1)
					tCatg2UIInfo = FurnitureData.GetCatg2Info(nCatg1, nCatg2)
					szCatg1Name = tCatg1UIInfo and tCatg1UIInfo.szName or "?"
					szCatg2Name = tCatg2UIInfo and tCatg2UIInfo.szName or "??"

					szLine = szLine .. (tUIInfo and tUIInfo.szName or "UNKNOWN")
					szLine = szLine .. "\t" .. szCatg1Name
					szLine = szLine .. "\t" .. szCatg2Name

					nFurnitureType, dwFurnitureID = tUIInfo.nFurnitureType, tUIInfo.dwFurnitureID
					dwUIFurnitureID = hlMgr.MakeFurnitureUIID(nFurnitureType, dwFurnitureID)
					tItemAddInfo = Table_GetFurnitureAddInfo(dwUIFurnitureID)
					szSource = tItemAddInfo and tItemAddInfo.szSource or "???"

					szLine = szLine .. "\t" .. szSource

					nLackedNum = tOneInfo.nNum
					szLine = szLine .. "\t" .. tostring(nLackedNum)

					if szContent == "" then
						szContent = szContent .. szLine
					else
						szContent = szContent .. "\n" .. szLine
					end

				end
			end

			if szContent ~= "" then
				local szTitle = FormatString(UIHelper.UTF8ToGBK(g_tStrings.STR_HOMELAND_ERROR_LIST_EXPORT_FILE_DESC_GET_SPECIAL), szBriefLandInfo) .. "\n"
						.. UIHelper.UTF8ToGBK(g_tStrings.STR_HOMELAND_ERROR_LIST_EXPORT_FILE_TITLE_OBJ_NAME) .. "\t"
						.. UIHelper.UTF8ToGBK(g_tStrings.STR_HOMELAND_ERROR_LIST_EXPORT_FILE_TITLE_CATG1) .. "\t"
						.. UIHelper.UTF8ToGBK(g_tStrings.STR_HOMELAND_ERROR_LIST_EXPORT_FILE_TITLE_CATG2) .. "\t"
						.. UIHelper.UTF8ToGBK(g_tStrings.STR_HOMELAND_ERROR_LIST_EXPORT_FILE_TITLE_SOURCE) .. "\t"
						.. UIHelper.UTF8ToGBK(g_tStrings.STR_HOMELAND_ERROR_LIST_EXPORT_FILE_TITLE_LACK_NUM)
				szContent = szTitle .. "\n" .. szContent
			end
		end
	elseif szErrType == "SpecialArchBuy" then
		local t = tErrorList.tSpecialArchBuy
		if t then
			local szLine = ""
			local dwModelID, tUIInfo
			local nCatg1, nCatg2, tCatg1UIInfo, tCatg2UIInfo
			local szCatg1Name, szCatg2Name
			local nFurnitureType, dwFurnitureID
			local dwUIFurnitureID, tItemAddInfo
			local szSource
			local nLackedNum
			local nGold
			for nIndex, tOneInfo in pairs(t) do
				szLine = ""
				dwModelID = tOneInfo.dwModelID
				tUIInfo = FurnitureData.GetFurnInfoByModelID(dwModelID)
				if tUIInfo then
					nCatg1 = tUIInfo.nCatg1Index
					nCatg2 = tUIInfo.nCatg2Index
					tCatg1UIInfo = FurnitureData.GetCatg1Info(nCatg1)
					tCatg2UIInfo = FurnitureData.GetCatg2Info(nCatg1, nCatg2)
					szCatg1Name = tCatg1UIInfo and tCatg1UIInfo.szName or "?"
					szCatg2Name = tCatg2UIInfo and tCatg2UIInfo.szName or "??"

					szLine = szLine .. (tUIInfo and tUIInfo.szName or "UNKNOWN")
					szLine = szLine .. "\t" .. szCatg1Name
					szLine = szLine .. "\t" .. szCatg2Name

					nFurnitureType, dwFurnitureID = tUIInfo.nFurnitureType, tUIInfo.dwFurnitureID
					dwUIFurnitureID = hlMgr.MakeFurnitureUIID(nFurnitureType, dwFurnitureID)
					tItemAddInfo = Table_GetFurnitureAddInfo(dwUIFurnitureID)
					szSource = tItemAddInfo and tItemAddInfo.szSource or "???"

					szLine = szLine .. "\t" .. szSource

					nLackedNum = tOneInfo.nNum
					szLine = szLine .. "\t" .. tostring(nLackedNum)

					nGold = tOneInfo.nGold
					szLine = szLine .. "\t" .. tostring(nGold)

					if szContent == "" then
						szContent = szContent .. szLine
					else
						szContent = szContent .. "\n" .. szLine
					end
				end
			end

			if szContent ~= "" then
				local szTitle = FormatString(UIHelper.UTF8ToGBK(g_tStrings.STR_HOMELAND_ERROR_LIST_EXPORT_FILE_DESC_GET_SPECIAL_CAN_BUY), szBriefLandInfo) .. "\n"
						.. UIHelper.UTF8ToGBK(g_tStrings.STR_HOMELAND_ERROR_LIST_EXPORT_FILE_TITLE_OBJ_NAME) .. "\t"
						.. UIHelper.UTF8ToGBK(g_tStrings.STR_HOMELAND_ERROR_LIST_EXPORT_FILE_TITLE_CATG1) .. "\t"
						.. UIHelper.UTF8ToGBK(g_tStrings.STR_HOMELAND_ERROR_LIST_EXPORT_FILE_TITLE_CATG2) .. "\t"
						.. UIHelper.UTF8ToGBK(g_tStrings.STR_HOMELAND_ERROR_LIST_EXPORT_FILE_TITLE_SOURCE) .. "\t"
						.. UIHelper.UTF8ToGBK(g_tStrings.STR_HOMELAND_ERROR_LIST_EXPORT_FILE_TITLE_LACK_NUM) .. "\t"
						.. UIHelper.UTF8ToGBK(g_tStrings.STR_HOMELAND_ARCHITECTURE_POINTS)
				szContent = szTitle .. "\n" .. szContent
			end
		end
	elseif szErrType == "CatgOverflow" then
		local t = tErrorList.tCatgOverflow
		if t then
			for nIndex, tOneInfo in pairs(t) do
				local szLine = ""
				local nCatg1, nCatg2, tCatg1UIInfo, tCatg2UIInfo
				local szCatg1Name, szCatg2Name
				nCatg1, nCatg2 = tOneInfo.nCatg1, tOneInfo.nCatg2
				if nCatg1 then
					tCatg1UIInfo = FurnitureData.GetCatg1Info(nCatg1)
				end
				if nCatg1 and nCatg2 then
					tCatg2UIInfo = FurnitureData.GetCatg2Info(nCatg1, nCatg2)
				end
				szCatg1Name = tCatg1UIInfo and tCatg1UIInfo.szName or "?"
				szCatg2Name = tCatg2UIInfo and tCatg2UIInfo.szName or "??"

				local szInfo = ""
				if tOneInfo.szInfo and tOneInfo.szName then
					szInfo = tOneInfo.szName .. " " .. tOneInfo.szInfo
				end

				szLine = szLine .. szCatg1Name
				szLine = szLine .. "\t" .. szCatg2Name

				szLine = szLine .. "\t" .. tostring(tOneInfo.nUsedCount)
				szLine = szLine .. "\t" .. tostring(tOneInfo.nLimitAmount)
				szLine = szLine .. "\t" .. tostring(tOneInfo.nNeedLevel or szInfo)

				if szContent == "" then
					szContent = szContent .. szLine
				else
					szContent = szContent .. "\n" .. szLine
				end
			end

			if szContent ~= "" then
				local szTitle = FormatString(UIHelper.UTF8ToGBK(g_tStrings.STR_HOMELAND_ERROR_LIST_EXPORT_FILE_DESC_CATG_OVERFLOW), szBriefLandInfo) .. "\n"
						.. UIHelper.UTF8ToGBK(g_tStrings.STR_HOMELAND_ERROR_LIST_EXPORT_FILE_TITLE_CATG1) .. "\t"
						.. UIHelper.UTF8ToGBK(g_tStrings.STR_HOMELAND_ERROR_LIST_EXPORT_FILE_TITLE_CATG2) .. "\t"
						.. UIHelper.UTF8ToGBK(g_tStrings.STR_HOMELAND_ERROR_LIST_EXPORT_FILE_TITLE_CATG_CUR_NUM) .. "\t"
						.. UIHelper.UTF8ToGBK(g_tStrings.STR_HOMELAND_ERROR_LIST_EXPORT_FILE_TITLE_CATG_LIMIT_NUM) .. "\t"
						.. UIHelper.UTF8ToGBK(g_tStrings.STR_HOMELAND_ERROR_LIST_EXPORT_FILE_TITLE_MIN_LEVEL_FOR_CATG)
				szContent = szTitle .. "\n" .. szContent
			end
		end
	elseif szErrType == "LevelOverflow" then
		local t = tErrorList.tLevelOverflow
		if t then
			local szLine = ""
			local dwModelID, tUIInfo
			local nCatg1, nCatg2, tCatg1UIInfo, tCatg2UIInfo
			local szCatg1Name, szCatg2Name
			local nRequiredLevel
			for nIndex, tOneInfo in pairs(t) do
				szLine = ""
				dwModelID = tOneInfo.dwModelID
				tUIInfo = FurnitureData.GetFurnInfoByModelID(dwModelID)
				if tUIInfo then
					nCatg1 = tUIInfo.nCatg1Index
					nCatg2 = tUIInfo.nCatg2Index
					tCatg1UIInfo = FurnitureData.GetCatg1Info(nCatg1)
					tCatg2UIInfo = FurnitureData.GetCatg2Info(nCatg1, nCatg2)
					szCatg1Name = tCatg1UIInfo and tCatg1UIInfo.szName or "?"
					szCatg2Name = tCatg2UIInfo and tCatg2UIInfo.szName or "??"

					szLine = szLine .. (tUIInfo and tUIInfo.szName or "UNKNOWN")
					szLine = szLine .. "\t" .. szCatg1Name
					szLine = szLine .. "\t" .. szCatg2Name

					szLine = szLine .. "\t" .. tostring(tOneInfo.nTotalNum)

					nRequiredLevel = tOneInfo.nLevelLimit
					szLine = szLine .. "\t" .. tostring(nRequiredLevel)

					if szContent == "" then
						szContent = szContent .. szLine
					else
						szContent = szContent .. "\n" .. szLine
					end
				end
			end

			if szContent ~= "" then
				local szTitle = FormatString(UIHelper.UTF8ToGBK(g_tStrings.STR_HOMELAND_ERROR_LIST_EXPORT_FILE_DESC_LEVEL_OVERFLOW), szBriefLandInfo) .. "\n"
						.. UIHelper.UTF8ToGBK(g_tStrings.STR_HOMELAND_ERROR_LIST_EXPORT_FILE_TITLE_OBJ_NAME) .. "\t"
						.. UIHelper.UTF8ToGBK(g_tStrings.STR_HOMELAND_ERROR_LIST_EXPORT_FILE_TITLE_CATG1) .. "\t"
						.. UIHelper.UTF8ToGBK(g_tStrings.STR_HOMELAND_ERROR_LIST_EXPORT_FILE_TITLE_CATG2) .. "\t"
						.. UIHelper.UTF8ToGBK(g_tStrings.STR_HOMELAND_ERROR_LIST_EXPORT_FILE_TITLE_ITEM_NUM) .. "\t"
						.. UIHelper.UTF8ToGBK(g_tStrings.STR_HOMELAND_ERROR_LIST_EXPORT_FILE_TITLE_REQUIRED_LEVEL)
				szContent = szTitle .. "\n" .. szContent
			end
		end
	else
		-- Do nothing.
	end
	return szContent
end


-- 作用：导出当前全体问题物件列表信息到文件里
function ExportAllErrorList(tErrorList)
	local i, folder, file = 0, _GetExportedErrorListFolder()
	local gbkFolder = UIHelper.UTF8ToGBK(folder)
	CPath.MakeDir(gbkFolder)

	local aErrorTypes = {"CanArchBuy", "CanCoinBuy", "SpecialArchBuy", "GetSpecial", "CatgOverflow", "LevelOverflow"}
	for _, szErrType in ipairs(aErrorTypes) do
		local dt = TimeToDate(GetCurrentTime())
		local nYear, nMonth, nDay, nHour, nMinute, nSecond = dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second
		local szFilePrefix = folder .. "ErrorList (" .. szErrType .. ")_"
		file = szFilePrefix .. ("%04d-%02d-%02d_%02d-%02d-%02d.txt"):format(nYear, nMonth, nDay, nHour, nMinute, nSecond)
		-- 先简单处理，不考虑文件名重复

		local szContent = _GenerateExportedErrorListContent(szErrType, tErrorList)
		if szContent ~= "" then
			local szText = szContent
			SaveDataToFile(szText, file)
		end
	end

	folder = string.gsub(folder, "\\", "/")
	local szMsg = FormatString(g_tStrings.STR_HOMELAND_ERROR_LIST_EXPORT_FILE_SUCCESS, folder)
	local scriptView = UIHelper.ShowConfirm(szMsg)
	scriptView:HideButton("Cancel")
end

local function GetTotalConsume()
	local function AddModel(tTable, nCatg1, nCatg2, dwModelID, nCount)
        if not tTable[nCatg1] then
            tTable[nCatg1] = {}
        end
        if not tTable[nCatg1][nCatg2] then
            tTable[nCatg1][nCatg2] = {}
        end
		tTable[nCatg1][nCatg2][dwModelID] = nCount
    end
	local tAllConsumeInfo = {}
	local hlMgr = GetHomelandMgr()
	local _, tFurnInfo, _ = FurnitureData.GetAllFurniturnInfos()
	for dwModelID, tInfo in pairs(tFurnInfo) do
		if tInfo.nFurnitureType == HS_FURNITURE_TYPE.FURNITURE or tInfo.nFurnitureType == HS_FURNITURE_TYPE.PENDANT then
			local nCount = hlMgr.BuildGetOnLandFurniture(tInfo.nFurnitureType, tInfo.dwFurnitureID)
			if nCount > 0 then
				AddModel(tAllConsumeInfo, tInfo.nCatg1Index, tInfo.nCatg2Index, dwModelID, nCount)
			end
		end
	end
	return tAllConsumeInfo
end

local function _GenerateExportedObjListContent(nCatg1, nCatg2)
	local CUSTOM_BRUSH_CATG1_INDEX = 6
	local FLOWER_BRUSH_CATG2_INDEX = 1
	local FLOOR_BRUSH_CATG2_INDEX = 2
	local tAllConsumeInfo = GetTotalConsume()
	local szContent = ""
	if nCatg1 > 0 and nCatg2 > 0 then
		local t = {}
		if nCatg1 == CUSTOM_BRUSH_CATG1_INDEX and nCatg2 == FLOWER_BRUSH_CATG2_INDEX then
			local tFlowerBrushInfo = HLBOp_Amount.GetFlowerBrushInfo()
			for i = 1, #tFlowerBrushInfo do
				t[tFlowerBrushInfo[i].nModelID] = 1
			end
		elseif nCatg1 == CUSTOM_BRUSH_CATG1_INDEX and nCatg2 == FLOOR_BRUSH_CATG2_INDEX then
			local tFloorBrushInfo = HLBOp_Amount.GetFloorBrushInfo()
			for i = 1, #tFloorBrushInfo do
				t[tFloorBrushInfo[i].nModelID] = 1
			end
		else
			t = tAllConsumeInfo[nCatg1] and tAllConsumeInfo[nCatg1][nCatg2]
		end
		if t then
			local nNumInCatg = 0
			for dwModelID, nAmount in pairs(t) do
				nNumInCatg = nNumInCatg + nAmount
			end
			local szMinRequiredLandLevelForCatgNum
			local nMaxLandLevel = HOMELAND_MAX_LEVEL
			local hlMgr = GetHomelandMgr()
			local tLevelConfig, nLimitAmount, nPrevLimitAmount
			for nLevel = nMaxLandLevel, 1, -1 do
				tLevelConfig = hlMgr.GetLevelFurnitureConfig(nCatg1, nCatg2, nLevel)
				nLimitAmount = tLevelConfig and tLevelConfig.LimCount or 0

				if nLevel == nMaxLandLevel and nLimitAmount > 0 and nLimitAmount < nNumInCatg then
					szMinRequiredLandLevelForCatgNum = tostring(nMaxLandLevel) .. "+"
					break
				end

				if nLevel > 1 then
					tLevelConfig = hlMgr.GetLevelFurnitureConfig(nCatg1, nCatg2, nLevel - 1)
					nPrevLimitAmount = tLevelConfig and tLevelConfig.LimCount or 0

					if (nPrevLimitAmount > 0 and nPrevLimitAmount < nNumInCatg) and (nLimitAmount > 0 and nLimitAmount >= nNumInCatg) then
						szMinRequiredLandLevelForCatgNum = tostring(nLevel)
						break
					end
				else
					szMinRequiredLandLevelForCatgNum = tostring(nLevel)
					break
				end
			end

			local szLine = ""
			local tUIInfo
			local tCatg1UIInfo, tCatg2UIInfo
			tCatg1UIInfo = FurnitureData.GetCatg1Info(nCatg1)
			tCatg2UIInfo = FurnitureData.GetCatg2Info(nCatg1, nCatg2)
			local szCatg1Name = tCatg1UIInfo and tCatg1UIInfo.szName or "?"
			local szCatg2Name = tCatg2UIInfo and tCatg2UIInfo.szName or "??"
			local nFurnitureType, dwFurnitureID
			local tFurnitureConfig, dwUIFurnitureID, tFurnAddInfo
			local szSource, nRequiredLevel
			for dwModelID, nAmount in pairs(t) do
				szLine = ""
				tUIInfo = FurnitureData.GetFurnInfoByModelID(dwModelID)
				szLine = szLine .. (tUIInfo and tUIInfo.szName or "UNKNOWN")
				szLine = szLine .. "\t" .. szCatg1Name
				szLine = szLine .. "\t" .. szCatg2Name

				nFurnitureType, dwFurnitureID = tUIInfo.nFurnitureType, tUIInfo.dwFurnitureID
				dwUIFurnitureID = hlMgr.MakeFurnitureUIID(nFurnitureType, dwFurnitureID)
				tFurnAddInfo = Table_GetFurnitureAddInfo(dwUIFurnitureID)
				szSource = tFurnAddInfo and tFurnAddInfo.szSource or "???"

				szLine = szLine .. "\t" .. szSource

				szLine = szLine .. "\t" .. tostring(nAmount)

				szLine = szLine .. "\t" .. tostring((GetFurnitureArchitectureByModelID(dwModelID) or 0) * nAmount)

				if nFurnitureType == HS_FURNITURE_TYPE.FURNITURE then
					tFurnitureConfig = hlMgr.GetFurnitureConfig(dwFurnitureID)
				elseif nFurnitureType == HS_FURNITURE_TYPE.PENDANT then
					tFurnitureConfig = hlMgr.GetPendantConfig(dwFurnitureID)
				elseif nFurnitureType == HS_FURNITURE_TYPE.FOLIAGE_BRUSH then
					tFurnitureConfig = hlMgr.GetFoliageBrushConfig(dwFurnitureID)
				elseif nFurnitureType == HS_FURNITURE_TYPE.APPLIQUE_BRUSH then
					tFurnitureConfig = hlMgr.GetAppliqueBrushConfig(dwFurnitureID)
				end
				nRequiredLevel = tFurnitureConfig.nLevelLimit or 0
				szLine = szLine .. "\t" .. tostring(nRequiredLevel)

				szLine = szLine .. "\t" .. tostring(szMinRequiredLandLevelForCatgNum)

				if szContent == "" then
					szContent = szContent .. szLine
				else
					szContent = szContent .. "\n" .. szLine
				end
			end
		end
	elseif nCatg1 > 0 then
		local t = tAllConsumeInfo[nCatg1]
		if t then
			for nCatg2Index, _ in pairs(t) do
				local szTemp = _GenerateExportedObjListContent(nCatg1, nCatg2Index)
				if szTemp ~= "" then
					if szContent == "" then
						szContent = szContent .. szTemp
					else
						szContent = szContent .. "\n" .. szTemp
					end
				end
			end
		end
		if nCatg1 == BRUSH_CATG then
			local szTemp = _GenerateExportedObjListContent(CUSTOM_BRUSH_CATG1_INDEX, FLOWER_BRUSH_CATG2_INDEX)
			if szTemp ~= "" then
				if szContent == "" then
					szContent = szContent .. szTemp
				else
					szContent = szContent .. "\n" .. szTemp
				end
			end
			local szTemp = _GenerateExportedObjListContent(CUSTOM_BRUSH_CATG1_INDEX, FLOOR_BRUSH_CATG2_INDEX)
			if szTemp ~= "" then
				if szContent == "" then
					szContent = szContent .. szTemp
				else
					szContent = szContent .. "\n" .. szTemp
				end
			end
		end
	else -- nCatg1 <= 0 and nCatg2 <= 0
		for nCatg1Index, tCatg1NumberInfo in pairs(tAllConsumeInfo) do
			for nCatg2Index, _ in pairs(tCatg1NumberInfo) do
				local szTemp = _GenerateExportedObjListContent(nCatg1Index, nCatg2Index)
				if szTemp ~= "" then
					if szContent == "" then
						szContent = szContent .. szTemp
					else
						szContent = szContent .. "\n" .. szTemp
					end
				end
			end
		end
		local szTemp = _GenerateExportedObjListContent(CUSTOM_BRUSH_CATG1_INDEX, FLOWER_BRUSH_CATG2_INDEX)
		if szTemp ~= "" then
			if szContent == "" then
				szContent = szContent .. szTemp
			else
				szContent = szContent .. "\n" .. szTemp
			end
		end
		local szTemp = _GenerateExportedObjListContent(CUSTOM_BRUSH_CATG1_INDEX, FLOOR_BRUSH_CATG2_INDEX)
		if szTemp ~= "" then
			if szContent == "" then
				szContent = szContent .. szTemp
			else
				szContent = szContent .. "\n" .. szTemp
			end
		end
	end
	return szContent
end

function ExportObjectList(nCatg1, nCatg2)
	nCatg1 = nCatg1 or -1
	nCatg2 = nCatg2 or -1

	local i, folder, file = 0, _GetExportedObjListFolder()
	local gbkFolder = UIHelper.UTF8ToGBK(folder)
	CPath.MakeDir(gbkFolder)

	local szCatgNameInTitle = ""
	if nCatg1 > 0 and nCatg2 > 0 then
		local tCatg1UIInfo, tCatg2UIInfo
		tCatg1UIInfo = FurnitureData.GetCatg1Info(nCatg1)
		tCatg2UIInfo = FurnitureData.GetCatg2Info(nCatg1, nCatg2)
		local szCatg1Name = tCatg1UIInfo and tCatg1UIInfo.szName or "?"
		local szCatg2Name = tCatg2UIInfo and tCatg2UIInfo.szName or "??"
		szCatgNameInTitle = szCatg1Name .. g_tStrings.STR_CONNECT .. szCatg2Name
	elseif nCatg1 > 0 then
		local tCatg1UIInfo = FurnitureData.GetCatg1Info(nCatg1)
		szCatgNameInTitle = g_tStrings.STR_HOMELAND_OBJ_LIST_EXPORT_FILE_NAME_CATG_TOTAL .. (tCatg1UIInfo and tCatg1UIInfo.szName or "?")
	else
		szCatgNameInTitle = g_tStrings.STR_HOMELAND_OBJ_LIST_EXPORT_FILE_NAME_CATG_TOTAL
	end

	local dt = TimeToDate(GetCurrentTime())
	local nYear, nMonth, nDay, nHour, nMinute, nSecond = dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second
	local szFilePrefix = folder .. ("FurnitureList(%s)_"):format(szCatgNameInTitle)
	file = szFilePrefix .. ("%04d-%02d-%02d_%02d-%02d-%02d.txt"):format(nYear, nMonth, nDay, nHour, nMinute, nSecond)
	if Lib.IsFileExist(file) then
		repeat
			file, i = szFilePrefix .. ("%04d-%02d-%02d_%02d-%02d-%02d-%03d.txt"):format(
					nYear, nMonth, nDay, nHour, nMinute, nSecond, i), i + 1
		until not Lib.IsFileExist(file)
	end

	local szTitles = g_tStrings.STR_HOMELAND_OBJ_LIST_EXPORT_FILE_TITLE_1 .. "\t" .. g_tStrings.STR_HOMELAND_OBJ_LIST_EXPORT_FILE_TITLE_2 ..
			"\t" .. g_tStrings.STR_HOMELAND_OBJ_LIST_EXPORT_FILE_TITLE_3 .. "\t" .. g_tStrings.STR_HOMELAND_OBJ_LIST_EXPORT_FILE_TITLE_4 ..
			"\t" .. g_tStrings.STR_HOMELAND_OBJ_LIST_EXPORT_FILE_TITLE_5 .. "\t" .. g_tStrings.STR_HOMELAND_OBJ_LIST_EXPORT_FILE_TITLE_6 ..
			"\t" .. g_tStrings.STR_HOMELAND_OBJ_LIST_EXPORT_FILE_TITLE_7 .. "\t" .. g_tStrings.STR_HOMELAND_OBJ_LIST_EXPORT_FILE_TITLE_8

	local szContent = _GenerateExportedObjListContent(nCatg1, nCatg2)
	local szText = UIHelper.UTF8ToGBK(szTitles) .. "\n" .. szContent

	SaveDataToFile(szText, file)

	file = string.gsub(file, "\\", "/")
	local szMsg = FormatString(g_tStrings.STR_HOMELAND_OBJ_LIST_EXPORT_FILE_SUCCESS, file)
	local scriptView = UIHelper.ShowConfirm(szMsg)
	scriptView:HideButton("Cancel")
end

function GetErrorList()
    local tErrorList = {}
	local hlMgr = GetHomelandMgr()
	local tConfig = Homeland_GetModeConfig(HLBOp_Main.GetBuildMode())

	tErrorList["Level"] = {}
	tErrorList["CatgOverflow"] = {}
	tErrorList["ItemOverflow"] = {}
	tErrorList["PendantOverflow"] = {}
	tErrorList["ItemShort"] = {}
	tErrorList["PendantShort"] = {}
	tErrorList["BrushShort"] = {}

	local tResult =	hlMgr.BuildCheckAllFurniture()

	for _, tInfo in pairs(tResult) do
		local eResult = tInfo.nResult
		if eResult == HOMELAND_BUILD_ERROR_CODE.LEGAL then --OK
		elseif eResult == HOMELAND_BUILD_ERROR_CODE.STORGE_SPILL then -- 溢出仓库数量
		elseif eResult == HOMELAND_BUILD_ERROR_CODE.STORGE_LACK then -- 普通家具数量不足
			local dwFurnitureID = tInfo.nID
			local dwModelID = FurnitureData.GetModelIDByTypeAndID(HS_FURNITURE_TYPE.FURNITURE, dwFurnitureID)
			if dwModelID then
				tErrorList["ItemShort"][dwModelID] = tInfo.nErrorData1
			end
		elseif eResult == HOMELAND_BUILD_ERROR_CODE.PENDANT_AMOUNT_ERROR then -- 挂件数量错误
			local dwPendantID = tInfo.nID
			local dwModelID = FurnitureData.GetModelIDByTypeAndID(HS_FURNITURE_TYPE.PENDANT, dwPendantID)
			if dwModelID then
				local nOverCount = hlMgr.BuildGetOnLandFurniture(HS_FURNITURE_TYPE.PENDANT, dwPendantID) - 1
				if nOverCount > 0 then
					tErrorList["PendantOverflow"][dwModelID] = nOverCount
				else
					if not tConfig.bDesign then
						if not CheckIsInTable(tErrorList["PendantShort"], dwModelID) then
							table.insert(tErrorList["PendantShort"], dwModelID)
						end
					end
				end
			end
		elseif eResult == HOMELAND_BUILD_ERROR_CODE.PENDANT_NOT_ACQUIRE then -- 挂件未获得
			if not tConfig.bDesign then
				local dwPendantID = tInfo.nID
				local dwModelID = FurnitureData.GetModelIDByTypeAndID(HS_FURNITURE_TYPE.PENDANT, dwPendantID)
				if dwModelID then
					if not CheckIsInTable(tErrorList["PendantShort"], dwModelID) then
						table.insert(tErrorList["PendantShort"], dwModelID)
					end
				end
			end
		elseif eResult == HOMELAND_BUILD_ERROR_CODE.LEVEL_LIMIT then -- 超出等级限制
			local dwFurnitureID = tInfo.nID
			local dwModelID = FurnitureData.GetModelIDByTypeAndID(HS_FURNITURE_TYPE.FURNITURE, dwFurnitureID)
			if dwModelID then
				table.insert(tErrorList["Level"], dwModelID)
			end
		elseif eResult == HOMELAND_BUILD_ERROR_CODE.AMOUNT_LIMIT then -- 超出摆放上限
			local dwFurnitureID = tInfo.nID
			local dwModelID = FurnitureData.GetModelIDByTypeAndID(HS_FURNITURE_TYPE.FURNITURE, dwFurnitureID)
			if dwModelID then
				tErrorList["ItemOverflow"][dwModelID] = tInfo.nErrorData1
			end
		elseif eResult == HOMELAND_BUILD_ERROR_CODE.INTERACTION_ERROR then -- 交互家具过多
			Log("=== 交互家具过多：")
		elseif eResult == HOMELAND_BUILD_ERROR_CODE.APPLIQUE_BURSH_NOT_ACQUIRE or --刷子未拥有
			eResult == HOMELAND_BUILD_ERROR_CODE.FOLIAGE_BURSH_NOT_ACQUIRE then
			local dwModelID = FurnitureData.GetModelIDByTypeAndID(tInfo.nFurnitureType, tInfo.nID)
			if dwModelID then
				tErrorList["BrushShort"][dwModelID] = tInfo.nErrorData1
			end
		end
	end

	local aCatgOverflowInfo = hlMgr.BuildCheckCategory()
	for _, tInfo in pairs(aCatgOverflowInfo) do
		table.insert(tErrorList["CatgOverflow"], {tInfo.Category1, tInfo.Category2, tInfo.Count})
	end

	if IsTableEmpty(tErrorList["Level"]) then
		tErrorList["Level"] = nil
	end
	if IsTableEmpty(tErrorList["CatgOverflow"]) then
		tErrorList["CatgOverflow"] = nil
	end
	if IsTableEmpty(tErrorList["ItemOverflow"]) then
		tErrorList["ItemOverflow"] = nil
	end
	if IsTableEmpty(tErrorList["PendantOverflow"]) then
		tErrorList["PendantOverflow"] = nil
	end
	if IsTableEmpty(tErrorList["ItemShort"]) then
		tErrorList["ItemShort"] = nil
	end
	if IsTableEmpty(tErrorList["PendantShort"]) then
		tErrorList["PendantShort"] = nil
	end
	if IsTableEmpty(tErrorList["BrushShort"]) then
		tErrorList["BrushShort"] = nil
	end

	return tErrorList
end


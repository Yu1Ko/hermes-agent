HomelandBuildData = HomelandBuildData or {className = "HomelandBuildData"}
local self = HomelandBuildData

function HomelandBuildData.Init()
	self.nLastChangeSkinTime = 0
	self.tbCurSelectedInfo = nil
	self.ResetWeather()
    self.RegEvent()
end

function HomelandBuildData.UnInit()
	self.nLastChangeSkinTime = 0
	self.tbCurSelectedInfo = nil
end

function HomelandBuildData.RegEvent()
	Event.Reg(HomelandBuildData, "SCENE_END_LOAD", function(nSceneID)
		self.tbCurSelectedInfo = nil
    end)

	Event.Reg(HomelandBuildData, "LOGIN_NOTIFY", function(nEvent)
		if nEvent == LOGIN.REQUEST_LOGIN_GAME_SUCCESS then
			self.tbCurSelectedInfo = nil
		end
    end)

	Event.Reg(HomelandBuildData, "HELP_EVENT", function(szEvent, ...)
		if szEvent == "OnFurniturePlace" then
			HomelandBuildData.OnFurniturePlace(...)
		elseif szEvent == "OnFurnitureBrushEnd" then
			HomelandBuildData.OnFurnitureBrushEnd(...)
		end
    end)

	Event.Reg(HomelandBuildData, "HOME_LAND_RESULT_CODE", function()
		local nRetCode = arg0
		if nRetCode == HOMELAND_RESULT_CODE.APPLY_ESTATE_SUCCEED then
			local hlMgr = GetHomelandMgr()
			local aAllMyLandInfos = hlMgr.GetAllMyLand()
			local dwCurrMapID, nCurrCopyIndex, nCurrLandIndex = HomelandBuildData.GetMapInfo()
			local szCurLandID = hlMgr.GetLandID(dwCurrMapID, nCurrCopyIndex, nCurrLandIndex)
			local hPlayer = GetClientPlayer()
			local hScene = hPlayer.GetScene()
			if hScene.nType == MAP_TYPE.HOMELAND then
				local t = FindTableValueByKey(aAllMyLandInfos, "uLandID", szCurLandID)
				if t then
					Event.Dispatch(EventType.OnUpdateHomelandEntranceState, true)
				else
					Event.Dispatch(EventType.OnUpdateHomelandEntranceState, true)
				end
			end
		end
    end)

	Event.Reg(HomelandBuildData, "HOMELAND_CALL_RESULT", function()
		local nRetCode = arg0
		if nRetCode == HOMELAND_BUILD_OP.ENTER then
			self.ResetWeather()
		end
    end)

	Event.Reg(HomelandBuildData, "HOME_LAND_RESULT_CODE_INT", function()
        local nResultType = arg0
		if nResultType == HOMELAND_RESULT_CODE.APPLY_LAND_INFO then --获取地块属性信息
			Event.Dispatch("OnUpdateHomelandRedPoint")
		elseif nResultType == HOMELAND_RESULT_CODE.APPLY_LEVEL_UP then --是否可以升级
			Event.Dispatch("OnUpdateHomelandRedPoint")
		end
    end)

	Event.Reg(HomelandBuildData, "REMOTE_HL_OVERVIEW_EVENT", function ()
        Event.Dispatch("OnUpdateHomelandRedPoint")
    end)
end

function HomelandBuildData.GetInputType()
	local nInputType = HLB_INPUT_TYPE.MAK
	if Channel.IsCloud() then
		nInputType = HLB_INPUT_TYPE.TOUCH
	elseif Platform.IsMobile() then
		nInputType = HLB_INPUT_TYPE.TOUCH
	end

	return nInputType
end

function HomelandBuildData.GetHomelandMgrObj()
	if not self.pHomelandMgr then
		self.pHomelandMgr = GetHomelandMgr()
	end
	return self.pHomelandMgr
end

function HomelandBuildData.GetMapInfo()
	local scene = GetClientScene()
	local nLandIndex = self.GetHomelandMgrObj().GetNowLandIndex()
	return scene.dwMapID, scene.nCopyIndex, nLandIndex
end

function HomelandBuildData.CheckIsMyLand(dwMapID, nCopyIndex, nLandIndex)
	local bMyLand = self.GetHomelandMgrObj().IsMyLand(dwMapID, nCopyIndex, nLandIndex)
	if not bMyLand then
		OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_HOUSE_GO_HOME_TIP)
	end
	return bMyLand
end

function HomelandBuildData.CheckMyLandIsUnLock(dwMapID, nCopyIndex, nLandIndex)
	local bUnLocked = true
	local pHlMgr = self.GetHomelandMgrObj()
	if pHlMgr and pHlMgr.IsPrivateHomeMap(dwMapID) then
		local tInfo = pHlMgr.GetHLLandInfo(nLandIndex)
		if tInfo and tInfo.uUnlockSubLand == 0 then
			bUnLocked = false
		end
		if not bUnLocked then
			OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_HOUSE_UNLOCK_TIP)
		end
	end
	return bUnLocked
end

function HomelandBuildData.SetCurSelectedInfo(tbInfo)
	self.tbCurSelectedInfo = tbInfo
end

function HomelandBuildData.GetCurSelectedInfo()
	return self.tbCurSelectedInfo
end

function HomelandBuildData.GetSDKFileLimitPercentage()
	local fPercentage = 0

	local hlMgr = GetHomelandMgr()
	local szPath = HLBOp_Save.GetCheckFileName()
	local nMode = HLBOp_Main.GetBuildMode()
	local bPrivateHome = false
	if nMode == BUILD_MODE.PRIVATE then
		bPrivateHome = true
	elseif nMode == BUILD_MODE.DESIGN then
		bPrivateHome = HLBOp_Enter.IsDesignPrivateHome()
	end
	local nUncompressSize, nUncompressLimit, nCompressSize, nCompressLimit = hlMgr.GetSDKFileLimit(bPrivateHome, szPath)

	local fUncompress, fCompress = 0, 0

	if nCompressLimit ~= 0 then
		fCompress = nCompressSize / nCompressLimit
	end

	if nUncompressLimit ~= 0 then
		fUncompress = nUncompressSize / nUncompressLimit
	end

	fPercentage = fUncompress > fCompress and fUncompress or fCompress

	return fPercentage
end

function HomelandBuildData.GetLandObjectPercentage()
	local fPercentage = 0

	local hlMgr = GetHomelandMgr()
	local nCurrentLandObjectSize, nLandObjectSizeLimit = hlMgr.GetLandObjectSize()
	fPercentage = nCurrentLandObjectSize / nLandObjectSizeLimit

	return fPercentage
end

function HomelandBuildData.GetSaveFurniturePercentage()
	local fPercentage = 0

	local hlMgr = GetHomelandMgr()
	local nCurrentSDSize, nSDSizeLimit = hlMgr.GetSDSize()
	fPercentage = nCurrentSDSize / nSDSizeLimit

	return fPercentage
end

function HomelandBuildData.SetWeather(nCurWeather, nCurTime)
	self.tbCurWeather = {nCurWeather, nCurTime}
end

function HomelandBuildData.GetWeather(nIndex)
	return self.tbCurWeather[nIndex]
end

function HomelandBuildData.ResetWeather()
	self.tbCurWeather = {1, 1}
end

function HomelandBuildData.CallToServer(szValiableList)
	local  tValiable = string.split(szValiableList, "|")
    if tValiable[1] and tValiable[1] == "On_OPEN_PANEL" then
        if tValiable[2] then
            RemoteCallToServer("On_OPEN_PANEL", tValiable[2], tValiable[3])
        end
    elseif tValiable[2] then
		RemoteCallToServer(tValiable[1], tValiable[2])
    else
        RemoteCallToServer(tValiable[1])
    end
end

function HomelandBuildData.OnFurniturePlace(dwModelID)
	-- 摆放单人床
	if ((dwModelID == 1603) and (GetClientPlayer() and GetClientPlayer().GetQuestIndex(21701) or GetClientPlayer() and GetClientPlayer().GetQuestIndex(24284))) then
		HomelandBuildData.CallToServer("On_HomeLand_SuccessBuild|1603")
		return
	end
	-- 摆放花盆
	if ((dwModelID == 6788) and (GetClientPlayer() and GetClientPlayer().GetQuestIndex(24290) or GetClientPlayer() and GetClientPlayer().GetQuestIndex(21611))) then
		HomelandBuildData.CallToServer("On_HomeLand_SuccessBuild|6788")
		return
	end
	-- 摆放宠物窝
	if ((dwModelID == 8082) and (GetClientPlayer() and GetClientPlayer().GetQuestIndex(24292))) then
		HomelandBuildData.CallToServer("On_HomeLand_SuccessBuild|8082")
		return
	end
	-- 摆放鱼池
	if ((dwModelID == 13910) and (GetClientPlayer() and GetClientPlayer().GetQuestIndex(24288))) then
		HomelandBuildData.CallToServer("On_HomeLand_SuccessBuild|13910")
		return
	end
	-- 摆放
	if ((GetClientPlayer() and GetClientPlayer().GetQuestIndex(21701) and dwModelID == 201) and true) then
		HomelandBuildData.CallToServer("On_HomeLand_SuccessBuild|201")
		return
	end
	if ((GetClientPlayer() and GetClientPlayer().GetQuestIndex(21701) and dwModelID == 6740) and true) then
		HomelandBuildData.CallToServer("On_HomeLand_SuccessBuild|6740")
		return
	end
	if ((GetClientPlayer() and GetClientPlayer().GetQuestIndex(21701) and dwModelID == 191) and true) then
		HomelandBuildData.CallToServer("On_HomeLand_SuccessBuild|191")
		return
	end
	if ((GetClientPlayer() and GetClientPlayer().GetQuestIndex(21701) and dwModelID == 189) and true) then
		HomelandBuildData.CallToServer("On_HomeLand_SuccessBuild|189")
		return
	end
	if ((GetClientPlayer() and GetClientPlayer().GetQuestIndex(21701) and dwModelID == 190) and true) then
		HomelandBuildData.CallToServer("On_HomeLand_SuccessBuild|190")
		return
	end
	if ((GetClientPlayer() and GetClientPlayer().GetQuestIndex(21611) and dwModelID == 7251) and true) then
		HomelandBuildData.CallToServer("On_HomeLand_SuccessBuild|7251")
		return
	end
	if ((GetClientPlayer() and GetClientPlayer().GetQuestIndex(21611) and dwModelID == 6785) and true) then
		HomelandBuildData.CallToServer("On_HomeLand_SuccessBuild|6785")
		return
	end
	if ((GetClientPlayer() and GetClientPlayer().GetQuestIndex(21611) and dwModelID == 7246) and true) then
		HomelandBuildData.CallToServer("On_HomeLand_SuccessBuild|7246")
		return
	end
end

function HomelandBuildData.CanDestroyGroup(aObjIDs)
	local bCanDestroyGroup = false
	local dwObjID = aObjIDs[1]
	local dwGroupID = HLBOp_Group.GetGroupID(dwObjID)
	if dwGroupID then
		bCanDestroyGroup = true
		for i = 2, #aObjIDs do
			local dwObjID = aObjIDs[i]
			local dwGID = HLBOp_Group.GetGroupID(dwObjID)
			if dwGID ~= dwGroupID then
				bCanDestroyGroup = false
				break
			end
		end
	end
	return bCanDestroyGroup, dwGroupID
end

function HomelandBuildData.IsOpenDesignEnableMap(nMapID)
    local _, nMapType, _, _, nCampType = GetMapParams(nMapID)
    if (nMapType == MAP_TYPE.NORMAL_MAP or nMapType == MAP_TYPE.HOMELAND) and nCampType == MAP_CAMP_TYPE.ALL_PROTECT then
        return true
    end
    return false
end

function HomelandBuildData.OpenAsDesign(tDesignInfo)
	local player = PlayerData.GetClientPlayer()
	if not player then
		return
	end
	local nMapID  = player.GetMapID()
	if HomelandBuildData.IsOpenDesignEnableMap(nMapID) and not player.bFightState then
		if tDesignInfo.nLevel > 0 and tDesignInfo.nLevel <= HOMELAND_MAX_LEVEL then
			HLBOp_Main.Enter(BUILD_MODE.DESIGN, tDesignInfo)
		end
	else
		OutputMessage("MSG_SYS", g_tStrings.STR_CANT_ENTER_DESIGN_MODE)
		OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_CANT_ENTER_DESIGN_MODE)
	end
end

function HomelandBuildData.GetLockerItemNum(dwItemID)
	local pPlayer = GetClientPlayer()
	if not pPlayer then
		return
	end

	if not pPlayer.RemoteDataAutodownFinish() then
		return
	end

	local tInfo = Table_GetHomelandLockerInfoByItem(dwItemID)
	if tInfo then
		local tFilter = HomelandMiniGameData.tFilterCheck[tInfo.dwClassType]
		local nCount = pPlayer.GetRemoteArrayUInt(tFilter.DATAMANAGE, tFilter.ITEMSTART + (tInfo.dwDataIndex - 1) * tFilter.BYTE_NUM, tFilter.BYTE_NUM)
		if nCount then
			return nCount
		end
	end
end

--摆放家具笔刷
function HomelandBuildData.OnFurnitureBrushEnd(aModelIDs)
	--摆放地下室
	if CheckIsInTable(aModelIDs, 74) then
		HomelandBuildData.CallToServer("On_HomeLand_SuccessBuild|74")
		return
	end
	if CheckIsInTable(aModelIDs, 82) then
		HomelandBuildData.CallToServer("On_HomeLand_SuccessBuild|82")
		return
	end
	if CheckIsInTable(aModelIDs, 83) then
		HomelandBuildData.CallToServer("On_HomeLand_SuccessBuild|83")
		return
	end
	if CheckIsInTable(aModelIDs, 84) then
		HomelandBuildData.CallToServer("On_HomeLand_SuccessBuild|84")
		return
	end
	if CheckIsInTable(aModelIDs, 113) then
		HomelandBuildData.CallToServer("On_HomeLand_SuccessBuild|113")
		return
	end
	if CheckIsInTable(aModelIDs, 114) then
		HomelandBuildData.CallToServer("On_HomeLand_SuccessBuild|114")
		return
	end
end

function HomelandBuildData.GetServerName()
	local szUserRegion, szUserSever = "", ""
    local tbRecentLoginData = Storage.RecentLogin.tbServer
    local nMaxTime, tbRecentLogin = 0, nil
    for szKey, tbLogin in pairs(tbRecentLoginData) do
        if tbLogin.nTime >= nMaxTime then
            nMaxTime = tbLogin.nTime
            tbRecentLogin = tbLogin
        end
    end

	if tbRecentLogin then
		szUserRegion, szUserSever = tbRecentLogin.szRegion, tbRecentLogin.szServer
	end

    return szUserRegion, szUserSever
end

HousePlayPanel = HousePlayPanel or {}
function HousePlayPanel.Open(tData)
	-- if tData.nGameID == 20 then
	-- 	-- WEAPONS_DISPLAY
	-- 	-- WeaponsDisplay.Open(tData)
	-- 	return
	-- end

	if not HomelandMiniGameData.CheckCanOpenFrame(tData.tPosInfo) then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_HOMELAND_DISTANCE)
		return
    end

	if not HomelandData.CheckNowLandState() then
		TipsHelper.ShowNormalTip(g_tStrings.STR_HOMELAND_POS_WARNING)
		return
	end

	if tData.nGameID == 3 or tData.nGameID == 11 then
		local script = UIMgr.GetViewScript(VIEW_ID.PanelHomeRecipe)
		if script then
			script:OnEnter(tData)
		else
			UIMgr.Open(VIEW_ID.PanelHomeRecipe, tData)
		end
	else
		local script = UIMgr.GetViewScript(VIEW_ID.PanelHomeInteract)
		if script then
			script:OnEnter(tData)
		else
			UIMgr.Open(VIEW_ID.PanelHomeInteract, tData)
		end
	end
end
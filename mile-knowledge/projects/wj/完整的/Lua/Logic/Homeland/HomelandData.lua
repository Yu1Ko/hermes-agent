HomelandData = HomelandData or {className = "HomelandData"}
local self = HomelandData
local RECIPE_ID = 5199
local RECIPE_LEVEL = 1

function HomelandData.Init()
    self.RegEvent()
	self.bShowHomelandEntrance = false
	self.bNewHomelandLogMsg = false
end

function HomelandData.UnInit()
	if self.nRedDotCheckTimer then
		Timer.DelTimer(self, self.nRedDotCheckTimer)
		self.nRedDotCheckTimer = nil
	end

	self.bShowHomelandEntrance = false
	self.bNewHomelandLogMsg = false
end

function HomelandData.RegEvent()
	Event.Reg(HomelandData, EventType.OnUpdateHomelandEntranceState, function (bShow)
		self.bShowHomelandEntrance = bShow
	end)

	-- Event.Reg(HomelandData, "SCENE_END_LOAD", function(nSceneID)
		-- self.CheckExitHomelandSence()
    -- end)

	Event.Reg(HomelandData, "ON_SYNC_SET_COLLECTION", function ()
		HomelandData._ShowSetCollectionRedDot()
	end)

	Event.Reg(HomelandData, "UPDATE_HOMELAND_RECORD", function()
		-- 使用家具时会必定触发这个事件，但是不一定触发ON_SYNC_SET_COLLECTION
		HomelandData._ShowSetCollectionRedDot()
    end)

	Event.Reg(HomelandData, "SYSTEM_NOTIFY", function()
		-- 家园日志红点
		if arg3 == 0 then
			self.bNewHomelandLogMsg = true
			if UIMgr.GetView(VIEW_ID.PanelHome) then	-- 仅通知界面刷新
				Event.Dispatch("OnUpdateHomelandRedPoint")
			end
		end
    end)

	Event.Reg(HomelandData, "LOGIN_NOTIFY", function(nEvent)
		if nEvent == LOGIN.REQUEST_LOGIN_GAME_SUCCESS then
			self.bShowHomelandEntrance = false
		end
    end)

	Event.Reg(HomelandData, "HOME_LAND_RESULT_CODE_INT", function()
		if arg0 == HOMELAND_RESULT_CODE.APPLY_LAND_CARD_RESPOND and arg1 ~= UI_GetClientPlayerID() then
			if arg2 == 0 and arg3 == 0 and arg4 == 0 then
				local hPlayer = GetPlayer(arg1)
				if hPlayer then
					local szMsg = FormatString(g_tStrings.LOOKUP_LAND_ERROR, UIHelper.GBKToUTF8(hPlayer.szName))
					TipsHelper.ShowNormalTip(szMsg)
				end
			else
				UIMgr.Open(VIEW_ID.PanelHome, 1, arg2, arg3, arg4)
			end
		end
    end)
end

function HomelandData._ShowSetCollectionRedDot()
	if self.nRedDotCheckTimer then	-- 处理批量购买家具时重复触发
		Timer.DelTimer(self, self.nRedDotCheckTimer)
		self.nRedDotCheckTimer = nil
	end

	self.nRedDotCheckTimer = Timer.Add(self, 0.5, function ()
		Event.Dispatch(EventType.OnHomelandShowSetRedDot)
	end)
end

function HomelandData.OpenHomelandPanel(nPageIndex)
	local function _DelayOpenView()
		Timer.AddFrame(self, 3, function ()
			if UIMgr.IsCloseing() and UIMgr.nCloseingViewID == VIEW_ID.PanelHome then
				_DelayOpenView()
				return
			end
			UIMgr.OpenSingle(true, VIEW_ID.PanelHome, nPageIndex)
		end)
	end

	if UIMgr.GetView(VIEW_ID.PanelHome) then
		UIMgr.Close(VIEW_ID.PanelHome)
		_DelayOpenView()
	else
		UIMgr.Open(VIEW_ID.PanelHome, nPageIndex)
	end
end

function HomelandData.OpenHomeOverviewPanel(tLinkIndex)
	local nPageLen = UIMgr.GetLayerStackLength(UILayer.Page, IGNORE_VIEW_IDS)
	local nPopLen = UIMgr.GetLayerStackLength(UILayer.Popup)
	local nMsgBoxLen = UIMgr.GetLayerStackLength(UILayer.MessageBox)

	if UIMgr.IsViewOpened(VIEW_ID.PanelHomeOverview) then
		return
	elseif nPageLen > 0 or nPopLen > 0 or nMsgBoxLen > 0 then
		UIMgr.CloseAllInLayer(UILayer.Page)
		UIMgr.CloseAllInLayer(UILayer.Popup)
		UIMgr.CloseAllInLayer(UILayer.MessageBox)
	end
	UIMgr.Open(VIEW_ID.PanelHomeOverview, tLinkIndex)
end

function HomelandData.IsNewHomelandLog()
	return self.bNewHomelandLogMsg
end

function HomelandData.IsShowHomelandEntrance()
	return self.bShowHomelandEntrance
end

function HomelandData.IsPrivateHome(nMapID)
	local hlMgr = GetHomelandMgr()
	if hlMgr then
		return hlMgr.IsPrivateHomeMap(nMapID)
	end
	return false
end

function HomelandData.IsHomelandCommunityMap(dwMapID)
	if not dwMapID then
		local scene = GetClientScene()
		dwMapID = scene.dwMapID
	end
	local _, nMapType = GetMapParams(dwMapID)
	if nMapType == MAP_TYPE.HOMELAND then
		return true
	end
	return false
end

function HomelandData.IsHomelandMap(nMapID)
	local tTable = GetHomelandMgr().GetHomelandMapList()
	if HomelandData.IsPrivateHome(nMapID) then
		return true
	end
	for k, v in pairs(tTable) do
		if v.MapID == nMapID then
			return true
		end
	end

	return false
end

function HomelandData.CheckIsHomelandMapTeleportGo(nLinkID, nMapID, nActivityID, nMapCopyIndex, funcCallBack)
	if HomelandData.IsHomelandMap(nMapID) then
		local bCD, _ = MapMgr.GetTransferSkillInfo()
		local bSafeCity = GDAPI_Homeland_SafeCity()
		if not bCD or bSafeCity then
			RemoteCallToServer("On_Teleport_Go", nLinkID, nMapID, nActivityID, nMapCopyIndex)
			if funcCallBack and IsFunction(funcCallBack) then
				funcCallBack()
			end
		else
			MapMgr.CheckTransferCDExecute(function()
				RemoteCallToServer("On_Teleport_Go", nLinkID, nMapID, nActivityID, nMapCopyIndex)
				if funcCallBack and IsFunction(funcCallBack) then
					funcCallBack()
				end
			end)
		end
		return true
	end

	return false
end

function HomelandData.GoPrivateLand(nMapID, nCopyIndex, dwSkinID, nFlag, nLandIndex, nAreaIndex)
	MapMgr.BeforeTeleport()
	local bSafeCity = GDAPI_Homeland_SafeCity()
    local bTransSkillCheck = HomelandData.OnTransToHomelandMap(dwConfirmEnterMapID)
	local funcBack = function()
		if bTransSkillCheck then
			RemoteCallToServer("On_HomeLand_GoPrivateLand", nMapID, nCopyIndex, dwSkinID, nFlag)
		else
			MapMgr.CheckTransferCDExecute(function()
				if nLandIndex then
					RemoteCallToServer("On_HomeLand_GoPrivateLand", nMapID, nCopyIndex, dwSkinID, nFlag, nLandIndex, nAreaIndex)
				else
					RemoteCallToServer("On_HomeLand_GoPrivateLand", nMapID, nCopyIndex, dwSkinID, nFlag)
				end
			end)
		end
	end

	if not bSafeCity then
		funcBack()
	else
		if nLandIndex then
			RemoteCallToServer("On_HomeLand_GoPrivateLand", nMapID, nCopyIndex, dwSkinID, nFlag, nLandIndex, nAreaIndex)
		else
			RemoteCallToServer("On_HomeLand_GoPrivateLand", nMapID, nCopyIndex, dwSkinID, nFlag)
		end
	end
end

function HomelandData.BackToLand(nMapID, nCopyIndex, nLandIndex)
	MapMgr.BeforeTeleport()
	local bSafeCity = GDAPI_Homeland_SafeCity()
	local dwMapID = HomelandBuildData.GetMapInfo()
	if bSafeCity or nMapID == dwMapID then
		RemoteCallToServer("On_HomeLand_BackToLand", nMapID, nCopyIndex, nLandIndex)
		return
	end

	MapMgr.CheckTransferCDExecute(function()
		RemoteCallToServer("On_HomeLand_BackToLand", nMapID, nCopyIndex, nLandIndex)
	end)
end

function HomelandData.SetHomelandLogMsg()
	self.bNewHomelandLogMsg = false
end

function HomelandData.IsGroupBuy(dwMapID)
	local tTable = GetHomelandMgr().GetHomelandMapList()
	for k, v in pairs(tTable) do
		if v.MapID == dwMapID then
			if v.IsGroupon == 1 then
				return true
			end
		end
	end

	return false
end

function HomelandData.IsJustCanGroupBuy(dwMapID)
	return dwMapID ~= 674
end

function HomelandData.IsNewCommunityMap(dwMapID)
	return dwMapID == 674
end

function HomelandData.IsNowPrivateHomeMap()
	local scene = GetClientScene()
    local pHlMgr = GetHomelandMgr()
	if not scene or not pHlMgr then
		return false
	end
    local dwCurMapID = scene.dwMapID

	return pHlMgr.IsPrivateHomeMap(dwCurMapID)
end

function HomelandData.GetNowLandInfo()
	local scene = GetClientScene()
	local _dwMapID = scene.dwMapID
	local _nCopyIndex = scene.nCopyIndex
	local nLandIndex = GetHomelandMgr().GetNowLandIndex()
	return _dwMapID, _nCopyIndex, nLandIndex
end

function HomelandData.CheckNowLandState()
	local pHlMgr = GetHomelandMgr()
    local _, _, nLandIndex = self.GetNowLandInfo()
	local tLandInfo = pHlMgr.GetHLLandInfo(nLandIndex) or {}
	if nLandIndex > 0 and tLandInfo.dwOwnerID > 0 then
		return true
	end

	return false
end

function HomelandData.GetAllMyLandInfo()
	local pHomelandMgr = GetHomelandMgr()
	if not pHomelandMgr then
		return
	end

	local tLandHash = pHomelandMgr.GetAllMyLand()
	local aAllMyOwnHomeData = {}
	local aAllPrivateHomeData = {}
	local aAllMyCohabitedHomeData = {}
	for _, tHash in ipairs(tLandHash) do
		local nMapID, nCopyIndex, nLandIndex = pHomelandMgr.ConvertLandID(tHash.uLandID)
		if tHash.bAllied then
			table.insert(aAllMyCohabitedHomeData, {nMapID = nMapID, nCopyIndex = nCopyIndex, nLandIndex = nLandIndex})
		elseif not tHash.bPrivateLand then
			local tCommunityInfo = pHomelandMgr.GetCommunityInfo(nMapID, nCopyIndex) or {}
			table.insert(aAllMyOwnHomeData, {nMapID = nMapID, nCopyIndex = nCopyIndex, nLandIndex = nLandIndex, nIndex = tCommunityInfo.nIndex})
		end
	end

	local tPrivateHash = pHomelandMgr.GetAllMyPrivateHome() --{}或{{szPrivateHomeID, dwMapID,nCopyIndex},{...}}
	for _, tHash in ipairs(tPrivateHash) do
		-- 获取SkinID前需要GetHomelandMgr().ApplyPrivateHomeInfo(nMapID, nCopyIndex)
		local tPrivateInfo = pHomelandMgr.GetPrivateHomeInfo(tHash.dwMapID, tHash.nCopyIndex) or {}
		table.insert(aAllPrivateHomeData, {nMapID = tHash.dwMapID, nCopyIndex = tHash.nCopyIndex, nSkinID = tPrivateInfo.dwSkinID})
	end

	return aAllMyOwnHomeData, aAllPrivateHomeData, aAllMyCohabitedHomeData
end
function HomelandData.Homeland_GetHomeName(nMapID, nLandIndex)
	return UIHelper.GBKToUTF8(Table_GetMapName(nMapID)) .. tostring(nLandIndex) .. g_tStrings.STR_HOMELAND_NUMBER
end

function HomelandData.Homeland_GetHLLandInfo()
	local pHlMgr = GetHomelandMgr()
	assert(pHlMgr)

	local nLandIndex = pHlMgr.GetNowLandIndex()
	return pHlMgr.GetHLLandInfo(nLandIndex)
end

function HomelandData.TryTransferToFurniture(nFurnitureType, nCatg1, nCatg2, nSubgroup)
	local pHlMgr = GetHomelandMgr()
	local nCount
	local nLandIndex = pHlMgr.GetNowLandIndex()
	if nLandIndex == 0 then
		nCount = 0
	else
		nCount = pHlMgr.GetCategoryCount(nLandIndex, nFurnitureType)
	end
	if nLandIndex == 0 then
		OutputMessage("MSG_ANNOUNCE_YELLOW", g_tStrings.STR_HOMELAND_OVERVIEW_NEED_BACK)
	elseif nCount > 0 then
		RemoteCallToServer("On_HomeLand_TransmitByFurType", nLandIndex, nFurnitureType)
		Event.Dispatch(EventType.OnTryTransferToFurniture)
	elseif nCatg1 and nCatg2 and nSubgroup then
		if HomelandData.CheckIsMyCommunityHome() or HomelandData.CheckIsMyPriviteHome() then
			UIHelper.ShowConfirm(g_tStrings.STR_HOMELAND_OVERVIEW_ENTER_TIPS, function ()
				UIMgr.Close(VIEW_ID.PanelHomeOverview)
				Timer.Add(self, 1, function ()
					if HomelandData.IsPrivateHome(GetClientScene().dwMapID) then
						HLBOp_Main.Enter(BUILD_MODE.PRIVATE)
					else
						HLBOp_Main.Enter(BUILD_MODE.COMMUNITY)
					end
					-- 建造有延迟，但是这之后打开的界面只有建造，所以用OneShotEvent来跳转到对应家具
					Event.Reg(self, EventType.OnViewOpen, function (nViewID)
						if nViewID == VIEW_ID.PanelConstructionMain then
							Event.Dispatch(EventType.OnGotoHomelandFurnitureListOneItem, nCatg1, nCatg2, nSubgroup)
						end
					end, true)
				end)
			end)
		end
	else
		OutputMessage("MSG_ANNOUNCE_YELLOW", g_tStrings.STR_HOMELAND_OVERVIEW_NO_FURNITURE)
	end
end

function HomelandData.CheckExitHomelandSence()
    local hPlayer = GetClientPlayer()
	local hScene = hPlayer.GetScene()
	if self.bShowHomelandEntrance and hScene.nType ~= MAP_TYPE.HOMELAND then
		self.bShowHomelandEntrance = false
		Event.Dispatch(EventType.OnUpdateHomelandEntranceState, false)
	end
end

function HomelandData.CheckIsMyPriviteHome()
	local pHlMgr = GetHomelandMgr()
	if not pHlMgr then
		return
	end

    local dwMapID, nCopyIndex, nLandIndex = HomelandBuildData.GetMapInfo()
	if not HomelandData.IsPrivateHome(dwMapID) then
		return false
	end
    local bIsMyLand = pHlMgr.IsMyLand(dwMapID, nCopyIndex, nLandIndex)
	return bIsMyLand
end

function HomelandData.CheckIsMyCommunityHome()
	local pHlMgr = GetHomelandMgr()
	if not pHlMgr then
		return false
	end

    local dwMapID, nCopyIndex, nLandIndex = HomelandBuildData.GetMapInfo()
	if not HomelandData.IsHomelandCommunityMap(dwMapID) then
		return false
	end
	local tLandInfo = pHlMgr.GetHLLandInfo(nLandIndex) or {}
	local bIsHouseOwner = tLandInfo.dwOwnerID and tLandInfo.dwOwnerID == GetClientPlayer().dwID
    local bIsMyLand = pHlMgr.IsMyLand(dwMapID, nCopyIndex, nLandIndex)
	return bIsHouseOwner and bIsMyLand
end

function HomelandData.OnTransToHomelandMap(dwMapID)
	local hPlayer = GetClientPlayer()
	if not hPlayer then
		return false
	end

	local bIsHomelandMap = dwMapID and self.IsHomelandMap(dwMapID) or true

	-- 帮会“一念千里”二级天工特判，不用等待神行CD
	local IsSkillRecipeExist = hPlayer.IsSkillRecipeExist(RECIPE_ID, RECIPE_LEVEL)

	return bIsHomelandMap and IsSkillRecipeExist
end

function HomelandData.BackCommunityHome(dwMapID, nCopyIndex, nLandIndex)
	local hPlayer = GetClientPlayer()
	if not hPlayer then
		return
	end

	local bSafeCity = GDAPI_Homeland_SafeCity()
	if not bSafeCity and MapMgr.GetTransferSkillInfo() and not hPlayer.IsSkillRecipeExist(RECIPE_ID, RECIPE_LEVEL) then
		MapMgr.CheckTransferCDExecute(function()
			RemoteCallToServer("On_HomeLand_BackToLand", dwMapID, nCopyIndex, nLandIndex)
        end, dwMapID)
		return
	end
	RemoteCallToServer("On_HomeLand_BackToLand", dwMapID, nCopyIndex, nLandIndex)
end

function HomelandData.GetFurnitureGameInfo(dwMapID, nCopyIndex, nLandIndex, nFurnitureInstanceID, nDataPos)
	local pHomelandMgr = GetHomelandMgr()
	if not pHomelandMgr then
		return
	end

	local tdata = {}
	tdata.dwMapID = dwMapID
	tdata.nCopyIndex = nCopyIndex
	tdata.nLandIndex = nLandIndex
	tdata.nDataPos = nDataPos or 1
	tdata.nFurnitureInstanceID = nFurnitureInstanceID
	local tParam = {}
	if nDataType == LAND_OBJECT_TYPE.SD_EIGHT_DWORD_SCRIPT then
		tParam = pHomelandMgr.GetSDEightDwordScript(dwMapID, nCopyIndex, nLandIndex, nFurnitureInstanceID, nDataPos or 1)
	elseif nDataType == LAND_OBJECT_TYPE.SD_FOUR_DWORD_SCRIPT then
		tParam = pHomelandMgr.GetSDFourDwordScript(dwMapID, nCopyIndex, nLandIndex, nFurnitureInstanceID, nDataPos or 1)
	elseif nDataType == LAND_OBJECT_TYPE.SD_TWO_DWORD_SCRIPT then
		tParam = pHomelandMgr.GetSDTwoDwordScript(dwMapID, nCopyIndex, nLandIndex, nFurnitureInstanceID, nDataPos or 1)
	elseif nDataType == LAND_OBJECT_TYPE.FOUR_DWORD_SCRIPT then
		tParam = pHomelandMgr.GetFourDwordScript(dwMapID, nCopyIndex, nLandIndex, nFurnitureInstanceID, nDataPos or 1)
	end

	if tParam then
		if tParam[1] then
			tdata.nGameState = pHomelandMgr.GetDWORDValueByuint8(tParam[1], 0)
			local dwIndex = pHomelandMgr.GetDWORDValueByuint16(tParam[1], 2)
			local dwType = pHomelandMgr.GetDWORDValueByuint8(tParam[1], 1)
			if dwIndex and dwIndex > 0 then
				tdata.tModule1Item = {dwTabType = dwType, dwIndex = dwIndex}
			end
		end
	end
	return tdata
end

function HomelandData.IsFurnitureSetCanAward()
	local player = GetClientPlayer()
	if not player then
		return false
	end

	local tOrigTable = Table_GetAllFurnitureSetInfo()
	local nRowCount = tOrigTable:GetRowCount()
	local tLine, dwSetID
	for i = 2, nRowCount do
		tLine 	= tOrigTable:GetRow(i)
		dwSetID = tLine.dwSetID
		if dwSetID > 0 then
			local tInfo = player.GetSetCollection(dwSetID)
			local eCollectType = tInfo.eType
			if eCollectType == SET_COLLECTION_STATE_TYPE.TO_AWARD then
				return true
			end
		end
	end

	return false
end

function HomelandData.SetIsHomelandEditing(bIsHomelandEditing)
	local pGameScene = SceneMgr.GetGameScene()
	if pGameScene and pGameScene.SetIsHomelandEditing then
		pGameScene:SetIsHomelandEditing(bIsHomelandEditing)
	end
end
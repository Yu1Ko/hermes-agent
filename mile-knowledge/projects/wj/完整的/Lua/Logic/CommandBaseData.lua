-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: CommandBaseData
-- Date: 2024-04-15 10:28:43
-- Desc: ?
-- ---------------------------------------------------------------------------------

CommandBaseData = CommandBaseData or {className = "CommandBaseData"}
local self = CommandBaseData
local Model = {}
local DEFAULT_LIMIT = 2
local HURT_LEVEL_DATA_OFFSET = 21   --策划tCommanderBoardValue中，Boss易伤等级数据相对于HP数据的偏移
local EFFECT_PER_HURT_LEVEL = 30    --每1层易伤等级，效果增加30%
-------------------------------- 消息定义 --------------------------------
CommandBaseData.Event = {}
CommandBaseData.Event.XXX = "CommandBaseData.Msg.XXX"


local tRankingTypes = {
	214,
	215,
}



local REFRESH_TIME = 5

local COMMMANDER_ID_INDEX = 21
--必须和MiddleMapCommandNpc.txt表的boss被攻击配置信息一致
local ID_OF_BOSS_BE_ATTACTED_TABLE_INFO = 21

function CommandBaseData.Init()
    self._registerEvent()
    self.InitConductorData()
end

function CommandBaseData.UnInit()

end

function CommandBaseData.OnLogin()

end

function CommandBaseData.OnFirstLoadEnd()

end


function CommandBaseData.SetRoleType(nRoleType)
    self.nRoleType = nRoleType
end

function CommandBaseData.SetRoleLevel(nRoleLevel)
    self.nRoleLevel = nRoleLevel
end

function CommandBaseData.GetRoleType()
    return self.nRoleType
end

function CommandBaseData.GetRoleLevel()
    return self.nRoleLevel
end

function CommandBaseData.GetCommanderId()
    return Model.GetInstruction(COMMMANDER_ID_INDEX)
end

function CommandBaseData.IsCommanderExisted()
    return (0 ~= self.GetCommanderId())
end

-- 通用的指挥功能活动判断
local function IsCommandActOn()
	local hPlayer = g_pClientPlayer
	if not hPlayer then
		return false
	end
    local dwMapID = hPlayer.GetMapID()
	-- if IsVersionExp() or GetServerIP() == "127.0.0.1" then -- 体服活动用
		-- if dwMapID == 25 or dwMapID == 27 then
			-- return true
		-- end
	-- end

	if (IsActivityOn(479) and dwMapID == 25) or (IsActivityOn(494) and dwMapID == 27) then
		return true
	end

	return false
end

function CommandBaseData.IsCommanderMeetCondition()
    if  self.nRoleType == COMMAND_MODE_PLAYER_ROLE.SUPREME_COMMANDER and IsCommandActOn() then --and buff 不在马上
    -- if  self.nRoleType == COMMAND_MODE_PLAYER_ROLE.SUPREME_COMMANDER and ( ( dwMapID == 25) or (  dwMapID == 27) ) then
        return true
    else
        return false
    end
end

function CommandBaseData.IsViceCommanderMeetCondition()
    if self.nRoleType == COMMAND_MODE_PLAYER_ROLE.VICE_COMMANDER and IsCommandActOn() then --and buff 不在马上
    -- if  self.nRoleType == COMMAND_MODE_PLAYER_ROLE.VICE_COMMANDER and  ( (dwMapID == 25) or (  dwMapID == 27) ) then
        return true
    else
        return false
    end
end

function CommandBaseData.IsCommander()
    return self.nRoleType == COMMAND_MODE_PLAYER_ROLE.SUPREME_COMMANDER
end

function CommandBaseData.IsViceCommander()
    return self.nRoleType == COMMAND_MODE_PLAYER_ROLE.VICE_COMMANDER
end

function CommandBaseData.IsCommandModeCanBeEntered()
    local hPlayer = g_pClientPlayer
    if not hPlayer then
        return false
    end
    local bRet    = false
    local nCamp   = hPlayer.nCamp
    --浩气和恶人地图id
    if CampOBBaseData.IsObPlayer() or (IsCommandActOn() and (nCamp == CAMP.GOOD or nCamp == CAMP.EVIL)) then
        bRet = true
    end

    return bRet
end

function CommandBaseData.IsGFModeCanBeEntered()
    local hPlayer = g_pClientPlayer
    if not hPlayer then
        return false
    end
    local bRet    = false
    local nCamp   = hPlayer.nCamp
	local dwMapID = hPlayer.GetMapID()
    --浩气和恶人地图id
    if (dwMapID == 25 or dwMapID == 27) and (nCamp == CAMP.GOOD or nCamp == CAMP.EVIL) then
        bRet = true
    end

    return bRet
end

local function TimerFunction()
    if IsRemotePlayer(UI_GetClientPlayerID()) then
        return
    end

    if (not self.IsCommandModeCanBeEntered()) and (not self.IsGFModeCanBeEntered()) then
        return
    end

    local CP = GetCampPlantManager()
    if not CP then
        return
    end

    if CampOBBaseData.IsObPlayer() then
       CP.ApplyInstruction(CAMP.GOOD)
       CP.ApplyInstruction(CAMP.EVIL)
    else
       CP.ApplyInstruction()
    end
end

function CommandBaseData.IsBreatheCallOpened()
    return self.m_bIsBreatheCallOpened
end

function CommandBaseData.SetIsBreatheCallOpened(bOpened)
    self.m_bIsBreatheCallOpened = bOpened
end

function CommandBaseData.OpenBreatheCall()
    if self.IsBreatheCallOpened() or ((not self.IsCommandModeCanBeEntered()) and (not self.IsGFModeCanBeEntered())) then
        return
    end

    self.CloseBreatheCall()
    self.nBreathCallTimer = Timer.AddCycle(self, REFRESH_TIME, function()
        TimerFunction()
    end)

    self.SetIsBreatheCallOpened(true)
end

function CommandBaseData.CloseBreatheCall()

    if self.nBreathCallTimer then
        Timer.DelTimer(self, self.nBreathCallTimer)
        self.nBreathCallTimer = nil
    end

    Model.bIsBoardDataRefreshed = false
    self.SetIsBreatheCallOpened(false)
end

function CommandBaseData.SetSyncBoardInfo(tBoradInfo, nCamp)
    if not Model.tSyncBoardInfo then
        Model.tSyncBoardInfo = {}
        Model.tSyncBoardInfo[CAMP.GOOD] = {}
        Model.tSyncBoardInfo[CAMP.EVIL] = {}
        Model.tSyncBoardInfo[CAMP.NEUTRAL] = {}
    end

    Model.tSyncBoardInfo[nCamp] = tBoradInfo
end

function CommandBaseData.GetSyncBoardInfo(nCamp)
    if not Model.tSyncBoardInfo then
        -- Model.GetAllBoardInfo(nCamp)
        Model.tSyncBoardInfo = {}
        Model.tSyncBoardInfo[CAMP.GOOD] = {}
        Model.tSyncBoardInfo[CAMP.EVIL] = {}
        Model.tSyncBoardInfo[CAMP.NEUTRAL] = {}
    end
    return Model.tSyncBoardInfo[nCamp]
end

function Model.GetNPCTableInfo()
    if not Model.tNPCTableInfo then
        Model.tNPCTableInfo = Table_GetMiddleMapCommandNpc()
    end
    return Model.tNPCTableInfo
end

function Model.SetCampOfLogicData(nCamp)
    Model.nCampOfLogicData = nCamp
end

function Model.GetCampOfLogicData()
    return Model.nCampOfLogicData
end

function Model.GetInstruction(nIndex)
    local CP = GetCampPlantManager()
    if not CP then
        return 0
    end
    local nData = 0
    if CampOBBaseData.IsObPlayer() then
        local nCamp = Model.GetCampOfLogicData()
        nData = CP.GetInstruction(nIndex, nCamp)
    else
        nData = CP.GetInstruction(nIndex)
    end
    return nData
end

function Model.GetAllBoardInfo(nCamp)
    local tBoradInfo   = {}
    tBoradInfo.tFlag   = {}
    tBoradInfo.tArrow  = {}
    tBoradInfo.tGather = {}
    tBoradInfo.tCar = {}
    tBoradInfo.tNPC = {}

    local CP = GetCampPlantManager()
    if not CP then
        return
    end

    --从服务端获取数据
    local nMaxArrowIndex = 71 + 5 * COMMAND_BOARD.MAX_ARROW - 1
    for i = 71, nMaxArrowIndex ,5
    do
        local tRecord = {}
        tRecord.nType = Model.GetInstruction(i)
        tRecord.nX = Model.GetInstruction(i + 1)
        tRecord.nY = Model.GetInstruction(i + 2)
        tRecord.nEndX = Model.GetInstruction(i + 3)
        tRecord.nEndY = Model.GetInstruction(i + 4)

        if 0 ~=  tRecord.nType then
            table.insert(tBoradInfo.tArrow , tRecord)
        end
    end

    local nMaxFlagIndex = 146 + 3 * COMMAND_BOARD.MAX_MARK - 1
    for i = 146, nMaxFlagIndex ,3
    do
        local tRecord = {}
        tRecord.nType = Model.GetInstruction(i)
        tRecord.nX = Model.GetInstruction(i + 1)
        tRecord.nY = Model.GetInstruction(i + 2)

        if 0 ~= tRecord.nType then
            table.insert(tBoradInfo.tFlag, tRecord)
        end
    end

    local nStartGatherIndex = 176
    local tRecord = {}
    tRecord.nType = Model.GetInstruction(nStartGatherIndex)
    tRecord.nX = Model.GetInstruction(nStartGatherIndex + 1)
    tRecord.nY = Model.GetInstruction(nStartGatherIndex + 2)
    if 0 ~= tRecord.nType then
        table.insert(tBoradInfo.tGather, tRecord)
    end

    tBoradInfo.tCar = Model.GetCarInfo()
    tBoradInfo.tNPC = Model.GetNPCInfo()
    tBoradInfo.tNPCBeAttacked = Model.GetNpcBeAttackedInfo()

    self.SetSyncBoardInfo(tBoradInfo, nCamp)
end

function Model.GetAllBoardNpcInfo()
    if (not self.IsCommandModeCanBeEntered()) and (not self.IsGFModeCanBeEntered()) then
        return
    end
    local tBoardNPCInfo  = Model.GetNPCInfo()
    local tNPCBeAttacked = Model.GetNpcBeAttackedInfo()

    if CampOBBaseData.IsObPlayer() then
        local tGoodBoardSyncInfo = self.GetSyncBoardInfo(CAMP.GOOD)
        tGoodBoardSyncInfo.tNPC = tBoardNPCInfo
        tGoodBoardSyncInfo.tNPCBeAttacked = tNPCBeAttacked
        self.SetSyncBoardInfo(tGoodBoardSyncInfo, CAMP.GOOD)

        local tEvilBoardSyncInfo = self.GetSyncBoardInfo(CAMP.EVIL)
        tEvilBoardSyncInfo.tNPC = tBoardNPCInfo
        tEvilBoardSyncInfo.tNPCBeAttacked = tNPCBeAttacked
        self.SetSyncBoardInfo(tEvilBoardSyncInfo, CAMP.EVIL)
    else
        local hPlayer= g_pClientPlayer
        if not hPlayer then
            return
        end
        local tBoardSyncInfo = self.GetSyncBoardInfo(hPlayer.nCamp)
        tBoardSyncInfo.tNPC = tBoardNPCInfo
        tBoardSyncInfo.tNPCBeAttacked = tNPCBeAttacked
        self.SetSyncBoardInfo(tBoardSyncInfo, hPlayer.nCamp)
    end

end

function Model.GetCarInfo()
    local CP = GetCampPlantManager()
    if not CP then
        return
    end
    local tCarInfo = {}
    local nMaxCarIndex = 41 + 3 * COMMAND_BOARD.MAX_CAR - 1
    for i = 41, nMaxCarIndex ,3
    do
        local tRecord = {}
        tRecord.nCarId = Model.GetInstruction(i)
        tRecord.nX = Model.GetInstruction(i + 1)
        tRecord.nY = Model.GetInstruction(i + 2)

        if 0 ~= tRecord.nCarId then
            table.insert(tCarInfo, tRecord)
        end
    end

    return tCarInfo
end

--获取npc被攻击的信息，坑，该信息并不是附着在npc信息上的
function Model.GetNpcBeAttackedInfo()
    local tResult       = {}
    local tNPCTableInfo = Model.GetNPCTableInfo()
    local nMapMarkType  = tNPCTableInfo[ID_OF_BOSS_BE_ATTACTED_TABLE_INFO].nNPCDataType

    local player = g_pClientPlayer
    if not player then
        return {}
    end

    local tData  = player.GetMapMark()
    local nCount = #tData

    for i=1, nCount, 1 do
		local tMarkD   = tData[i]
        if tMarkD.nType == nMapMarkType then
            table.insert(tResult, tMarkD)
        end
	end

    return tResult
end

function Model.GetNPCInfo()
    local CP = GetCampPlantManager()
    if not CP then
        return
    end
    local tResult = {}

    local tNPCTableInfo = Model.GetNPCTableInfo()
    for _, tLineNPCInfo in ipairs(tNPCTableInfo) do
        local tRecord = tLineNPCInfo
        if tLineNPCInfo.nServerDataIndex ~= 0 then
            tRecord.nHpPercentage = Model.GetInstruction(tLineNPCInfo.nServerDataIndex)

            --易伤值
            local tInfo = Table_GetHeatMapAreaInfoByPQ(tRecord.nNPCDataType)
            if tInfo and tInfo.nType == HEAT_MAP_AREA.BOSS then
                local nHurtLevel = Model.GetInstruction(tLineNPCInfo.nServerDataIndex + HURT_LEVEL_DATA_OFFSET)
                if nHurtLevel > 0 then
                    tRecord.nHurtEffect = EFFECT_PER_HURT_LEVEL
                else
                    tRecord.nHurtEffect = 0
                end
            end
            tResult[tRecord.nNPCDataType] = tRecord
        elseif tLineNPCInfo.bShow == 1 then
            tResult[tRecord.nNPCDataType] = tRecord
        end
    end

    local player = g_pClientPlayer
    local tData = player.GetMapMark()
    local nCntOfPaintedNPC = 0
    local nNumOfNPC = #tNPCTableInfo
    local nCount = #tData

    local tPlayerMapMarkType = {}

    for i=1, nCount, 1 do
        if nCntOfPaintedNPC >= nNumOfNPC then
            break
        end
		local tMarkD   = tData[i]
        local tNPCInfo = tResult[tMarkD.nType]
        tPlayerMapMarkType[tMarkD.nType] = true
        if tNPCInfo then
            tNPCInfo.nX = tMarkD.nX
            tNPCInfo.nY = tMarkD.nY

            tResult[tMarkD.nType] = tNPCInfo
            nCntOfPaintedNPC = nCntOfPaintedNPC + 1
        end
	end

    local tMapDynamicData = MapMgr.Table_GetMapDynamicData()
    --上一次获取的GetMapMark需要清空,顺便添加图像数据
    for nNPCDataType, tCommandModeNpcData in pairs(tResult) do
        tCommandModeNpcData.szMobileImage = MapMgr.GetMapDynamicImage(nNPCDataType)
        tCommandModeNpcData.szTip = tMapDynamicData[nNPCDataType].szTip
        if not tPlayerMapMarkType[nNPCDataType] then
            tCommandModeNpcData.nX = nil
            tCommandModeNpcData.nY = nil
        end
    end

    return tResult
end


function CommandBaseData.IsBoardDataRefreshed()
    return Model.bIsBoardDataRefreshed
end

local function OnBoardDataRefresh(nCamp)
    Model.GetAllBoardInfo(nCamp)
    Model.bIsBoardDataRefreshed = true
    FireUIEvent("BOARD_INFO_HAS_BEEN_UPDATED")
end

function CommandBaseData._registerEvent()
    Event.Reg(self, "ON_CAMP_PLANT_APPLY_INSTRUCTION_RESPOND", function()
        if (not self.IsCommandModeCanBeEntered()) and (not self.IsGFModeCanBeEntered())then
            return
        end
        local nCamp = arg0
        Model.SetCampOfLogicData(nCamp)
        OnBoardDataRefresh(nCamp)
    end)

    Event.Reg(self, "ON_MAP_MARK_UPDATE", function()
        if (not self.IsCommandModeCanBeEntered()) and (not self.IsGFModeCanBeEntered())then
            return
        end
        Model.GetAllBoardNpcInfo()
        FireUIEvent("BOARD_NPC_INFO_HAS_BEEN_UPDATED")
    end)

    Event.Reg(self, "PLAYER_BECOME_CAMP_OB", function()
        if (not self.IsCommandModeCanBeEntered()) and (not self.IsGFModeCanBeEntered())then
            return
        end
        Model.GetAllBoardNpcInfo()
    end)

    Event.Reg(self, EventType.OnClientPlayerEnter, function()
        if not self.IsCommandModeCanBeEntered() and not self.IsGFModeCanBeEntered() then
            self.CloseBreatheCall()
        else
            self.OpenBreatheCall()
        end
    end)

    Event.Reg(self, "LOADING_END", function()
        self.UpdateRoleType()
    end)

    Event.Reg(self, "ON_CAMP_PLANT_APPLY_COMMANDER_INFO_RESPOND", function()
        if not self.bUpdateRoleType then return end
        local ENUM_CMD_RIGHT = {
            VICE_COMMANDER_1 = 1,
            VICE_COMMANDER_2 = 2,
            VICE_COMMANDER_3 = 3,
            SUPREME_COMMANDER = 4,
        }
        local hPlayer = g_pClientPlayer
        local CP = GetCampPlantManager()

        local tInfo = CP.GetDeputyInfo(0, hPlayer.dwID)
        if tInfo["DeputyInfo"][0] < ENUM_CMD_RIGHT.SUPREME_COMMANDER then
            self.SetRoleType(COMMAND_MODE_PLAYER_ROLE.VICE_COMMANDER)
            self.SetRoleLevel(tInfo["DeputyInfo"][0])
        elseif tInfo["DeputyInfo"][0] == ENUM_CMD_RIGHT.SUPREME_COMMANDER then
            self.SetRoleType(COMMAND_MODE_PLAYER_ROLE.SUPREME_COMMANDER)
        end
        CommandBaseData.ControlBtn()
        self.bUpdateRoleType = false
    end)
end

--更新指挥
function CommandBaseData.UpdateRoleType()
    self.SetRoleType(nil)
    local hPlayer = g_pClientPlayer
	if hPlayer.nCamp ~= CAMP.NEUTRAL then
		if hPlayer.HaveRemoteData(REMOTE_DATA.COMMANDER_FLAG) and hPlayer.GetRemoteDataBit(REMOTE_DATA.COMMANDER_FLAG , 0) then
			self.SetRoleType(COMMAND_MODE_PLAYER_ROLE.SUPREME_COMMANDER)
            CommandBaseData.ControlBtn()
		else
			local dwMapID = hPlayer.GetMapID()
			if dwMapID == 25 or dwMapID== 27 then
				local CP = GetCampPlantManager()
				CP.ApplyCommanerInfo()
                self.bUpdateRoleType = true
			end
		end
    end
end


function CommandBaseData.InitConductorData()
    self.tbCastleList = {}

    self.tGoodsInitSetting = {  -- 物资固定数据
        [1] = {dwID = 24799, nMoney = 110, nMaxCount = 40, nMaxUseCount = 25}, -- 大车 tBigCar
        [2] = {dwID = 24017, nMoney = 30, nMaxCount = 100,}, --小车 tSmallCar
        [3] = {dwID = 30796, nMoney = 40, nMaxCount = 65 }, -- tKey
        [4] = {dwID = 28697, nMoney = 17, nMaxCount = 100, }, -- tStone
    }
    self.tGoodsTypeToName = {
        g_tStrings.STR_COMMAND_BIGCAR,
        g_tStrings.STR_COMMAND_SMALLCAR,
        g_tStrings.STR_COMMAND_KEY,
        g_tStrings.STR_COMMAND_STONE,
    }
    self.tGoodsSetting = {} -- 物资动态数据 nBuy--已买，nAllot--已分配, bCanBuy--是否可买
    self.tGoodsAllot = {} -- 分配物资的信息

    self.tPlayerInfo = {}
    self.tPlayerIDInMemberList = {}

    self.tbGangRankList = {}
    self.tbTongIDtoIndex = {}
    self.tbOrderNumInWhiteList = {}
end

function CommandBaseData.SetMoney(nMoney)
    self.nMoney = nMoney
end

function CommandBaseData.GetMoney()
    return self.nMoney
end

function CommandBaseData.GetCoreTongList()
    local CP = GetCampPlantManager()
    local tbWhiteTongID = {}
    local nWhiteGangCount = CP.GetListCount(0, CUSTOM_RECORDING_PLAYER_DATA_TYPE.TONG_LIST)
    for i = 0, nWhiteGangCount - 1 do
        table.insert(tbWhiteTongID, CP.GetTong(0, i))
    end
    return tbWhiteTongID
end

function CommandBaseData.GetTongRankList()
    self.tbGangRankList = GetCustomRankList(tRankingTypes[g_pClientPlayer.nCamp])
    self.MapRankingList()
end

function CommandBaseData.MapRankingList()
	for k, tInfo in ipairs(self.tbGangRankList) do
		if k <= 50 then
			self.tbTongIDtoIndex[tInfo.dwID] = k
		end
	end
end

function CommandBaseData.GetTongDataByID(nTongID)
    return self.tbGangRankList[self.tbTongIDtoIndex[nTongID]]
end

function CommandBaseData.GetGangRankList()
    return self.tbGangRankList
end

function CommandBaseData.InitCastleInfo()
    if self.tbCastleImgInfo then
        return
    end
    self.tbCastleImgInfo = {}

    tbImgInfo = Table_GetCastleImgInfo()
    for _, tInfo in ipairs(tbImgInfo) do
        self.tbCastleImgInfo[tInfo.szName] = {}
        -- self.tbCastleImgInfo[tInfo.szName].szPath = tInfo.szPath
        -- self.tbCastleImgInfo[tInfo.szName].nFrame = tInfo.nFrame
    end
end

function CommandBaseData.GetTongCastleInfoByName(szName)
    CommandBaseData.InitCastleInfo()
    return self.tbCastleImgInfo[szName]
end

function CommandBaseData.SetCastleList(tbCastleLsit)
    self.tbCastleList = tbCastleLsit
end

function CommandBaseData.GetCastleNameByID(nTongID)
    if not self.tbCastleList then return nil end
    return self.tbCastleList[nTongID]
end

function CommandBaseData.AddDeleteTong(nTongID)
    if not self.tbDeleteTong then
        self.tbDeleteTong = {}
    end
    table.insert(self.tbDeleteTong, nTongID)
end

function CommandBaseData.RemoveDeleteTong(nTongID)
    if not self.tbDeleteTong then return end
    for nIndex, dwTongID in ipairs(self.tbDeleteTong) do
        if dwTongID == nTongID then
            table.remove(self.tbDeleteTong, nIndex)
            break
        end
    end
end

function CommandBaseData.DeleteTong()
    if not self.tbDeleteTong or #self.tbDeleteTong == 0 then return end

    local nTongID = table.remove(self.tbDeleteTong)
    if nTongID then
        RemoteCallToServer("On_Camp_GFDelVipTong", nTongID)
    end

    if self.nTimerDelete then
        Timer.DelTimer(self, self.nTimerDelete)
        self.nTimerDelete = nil
    end

    self.nTimerDelete = Timer.Add(self, 0.2, function()
        self.DeleteTong()
        self.nTimerDelete = nil
    end)
end

function CommandBaseData.AddNewTong(nTongID)
    if not self.tbNewTong then
        self.tbNewTong = {}
    end
    local tbInfo = CommandBaseData.GetTongDataByID(nTongID)
    table.insert(self.tbNewTong, {["dwTongID"] = nTongID, ["szName"] = tbInfo.szTongName})
end

function CommandBaseData.DeleteNewTong(nTongID)
    if not self.tbNewTong then return end
    for nIndex, dwTongID in ipairs(self.tbNewTong) do
        if dwTongID == nTongID then
            table.remove(self.tbNewTong, nIndex)
            break
        end
    end
end

function CommandBaseData.RemoteAddNewTong()
    if not self.tbNewTong or #self.tbNewTong == 0 then return end
    RemoteCallToServer("On_Camp_GFAddVipTong", self.tbNewTong)
end

function CommandBaseData.UpdateRight(nRightLevel)
    if nRightLevel == 4 then
		self.SetRoleType(COMMAND_MODE_PLAYER_ROLE.SUPREME_COMMANDER)
	else
		self.SetRoleType(COMMAND_MODE_PLAYER_ROLE.VICE_COMMANDER)
		self.SetRoleLevel(nRightLevel)
	end
end

function CommandBaseData.InitManagerList(bForceUpdate)

    if (not self.tPlayerInfo or not table.is_empty(self.tPlayerInfo)) and not bForceUpdate then
        return
    end

    self.tPlayerIDInMemberList = {}

    local CP = GetCampPlantManager()
	local tPlayerIDWithoutStirngInfo = {}
	local nManagerPlayerCount = CP.GetListCount(0, CUSTOM_RECORDING_PLAYER_DATA_TYPE.DEPUTY_LIST)
	for i = 0, nManagerPlayerCount - 1 do
		local tNumberInfo = CP.GetDeputy(0, i)
		self.tPlayerIDInMemberList[tNumberInfo.dwDeputyID] = true
		if self.tPlayerInfo[tNumberInfo.dwDeputyID] == nil then
			self.tPlayerInfo[tNumberInfo.dwDeputyID] = {}
			self.tPlayerInfo[tNumberInfo.dwDeputyID].tNumberInfo = tNumberInfo
		else
			self.tPlayerInfo[tNumberInfo.dwDeputyID].tNumberInfo = tNumberInfo
		end

		if tNumberInfo.dwDeputyID == g_pClientPlayer.dwID then
			local nRightLevel = tNumberInfo["DeputyInfo"][0]
			self.UpdateRight(nRightLevel)

		end


		if self.tPlayerInfo[tNumberInfo.dwDeputyID].tStringInfo == nil then
			table.insert(tPlayerIDWithoutStirngInfo, tNumberInfo.dwDeputyID)
		end
	end

	if #tPlayerIDWithoutStirngInfo == 0 then
		FireUIEvent("CMDSETTING_MEMBER_CHANGE")
	else
		RemoteCallToServer("On_Camp_GFGetMemberInfo", tPlayerIDWithoutStirngInfo, "CommandBaseData.GetPlayerInfoById")
	end
end

function CommandBaseData.GetPlayerInfoById(tbInfo)
    for dwID, value in pairs(tbInfo) do
		self.tPlayerInfo[dwID].tStringInfo = value
	end

    FireUIEvent("CMDSETTING_MEMBER_CHANGE")
end

function CommandBaseData.GetPlayerSortedInfo()
    local tSortedInfo = {}
	for dwID, tAllInfo in pairs(self.tPlayerInfo) do
		if self.tPlayerIDInMemberList[dwID] == true then
			if tAllInfo.tNumberInfo.DeputyInfo[5] == 1 then
				table.insert(tSortedInfo, 1, tAllInfo)
			else
				table.insert(tSortedInfo, tAllInfo)
			end
		end
	end

    return tSortedInfo

end

function CommandBaseData.SetGoodsIndex(nIndex)
    self.nGoodsIndex = nIndex
end

function CommandBaseData.GetGoodsIndex()
    return self.nGoodsIndex
end

function CommandBaseData.ClearGoodsAllotInfo()
    self.tGoodsAllot = {}
end

function CommandBaseData.SetGoodsAllotInfo(dwPlayerID, tInfo)
    self.tGoodsAllot[dwPlayerID] = tInfo
end

function CommandBaseData.GetGoodsAllotInfo()
    return self.tGoodsAllot
end

function CommandBaseData.GetGoodsAllotCount()
    local nNum = 0
    for _, tInfo in pairs(self.tGoodsAllot) do
        if tInfo.nAddCount ~= 0 then
            nNum = nNum + tInfo.nAddCount
        end
    end
    return nNum
end

function CommandBaseData.ClearPlayerInfo()
    self.tPlayerInfo = {}
end

--阵营管理添加人员列表数据
function CommandBaseData.InitPlayerDataList()
    self.tFriendGroup     = {}  --好友列表
    self.tGuildMemberList = {}  --帮会成员列表
    self.tCampInfo        = {}  --帮会成员阵营信息，由服务端脚本接口提供

    self.UpdateDateModel()
end

function CommandBaseData.SetGuildMemberCampInfo(tCampInfo)
    self.tCampInfo = tCampInfo
end

function CommandBaseData.GetFriendList()
    local hPlayer = g_pClientPlayer
    local tbMemberList = {}
    if self.tFriendGroup then
        for i, tGroup in pairs(self.tFriendGroup) do
            for j, tPlayer in pairs(tGroup.tFriendList) do
                if tPlayer.nCamp == hPlayer.nCamp and self.tPlayerIDInMemberList[tPlayer.id] ~= true and tPlayer.nLevel == hPlayer.nMaxLevel then
                    table.insert(tbMemberList, tPlayer)
                end
            end
        end
    end
    return tbMemberList
end

function CommandBaseData.GetGuildMemberList()
    local hClientPlayer = g_pClientPlayer
    local tbMemberList = {}
    if self.tGuildMemberList then
        for i, tPlayer in pairs(self.tGuildMemberList) do
            if hClientPlayer.nCamp == self.tCampInfo[tPlayer.id] and hClientPlayer.dwID ~= tPlayer.id and self.tPlayerIDInMemberList[tPlayer.id] ~= true and tPlayer.nLevel == hClientPlayer.nMaxLevel then
                table.insert(tbMemberList, tPlayer)
            end
        end
    end
    return tbMemberList
end

function CommandBaseData.UpdateDateModel()
    self.UpdateFriendGroup()
    self.UpdateGuildMemberList()
end

function CommandBaseData.UpdateFriendGroup()
    local SocialClient = GetSocialManagerClient()

    self.tFriendGroup = SocialClient.GetFellowshipGroupInfo()
    table.insert(self.tFriendGroup, 1, {id = 0, name = g_tStrings.STR_FRIEND_GOOF_FRIEND})
    for _, tGroup in pairs(self.tFriendGroup) do
        self.UpdateFriendsInGroup(SocialClient, tGroup)
    end
end

function CommandBaseData.UpdateFriendsInGroup(SocialClient, tGroup)
    local tFriendList = SocialClient.GetFellowshipInfo(tGroup.id) or {}

    local tGroupFriendList = {}
    for _, tPlayer in pairs(tFriendList) do
        if not FellowshipData.IsRemoteFriend(tPlayer.id) then
            tPlayer.szName = FellowshipData.GetRoleEntryInfo(tPlayer.id).szName
            tPlayer.nForceID = FellowshipData.GetRoleEntryInfo(tPlayer.id).nForceID
            tPlayer.nCamp = FellowshipData.GetRoleEntryInfo(tPlayer.id).nCamp
            tPlayer.nLimit = DEFAULT_LIMIT
            tPlayer.nLevel = FellowshipData.GetRoleEntryInfo(tPlayer.id).nLevel
            tPlayer.gid = tPlayer.id
            tPlayer.id = FellowshipData.GetRoleEntryInfo(tPlayer.gid).dwPlayerID
            table.insert(tGroupFriendList, tPlayer)
        end
    end
    tGroup.tFriendList = tGroupFriendList
end

function CommandBaseData.UpdateGuildMemberList()
    local pGuild = GetTongClient()
    local tPlayerID = pGuild.GetMemberList(true, "level", false, -1, -1)

    for i, nPlayerID in pairs(tPlayerID) do
        self.tGuildMemberList[i] = pGuild.GetMemberInfo(nPlayerID)
        self.tGuildMemberList[i].nLimit = DEFAULT_LIMIT
        self.tGuildMemberList[i].id = nPlayerID
    end

    RemoteCallToServer("On_Camp_GFGetCampInTong", self.GetGuildMemberPlayerIDList())
end

function CommandBaseData.GetGuildMemberPlayerIDList()
    local tPlayerIDList  = {}
    for i, tPlayer in pairs(self.tGuildMemberList) do
        table.insert(tPlayerIDList, tPlayer.dwID)
    end
    return tPlayerIDList
end


-- MiniMap开启 begin
function CommandBaseData.ControlBtn()

    local hPlayer = g_pClientPlayer

    if not hPlayer then
        return
    end

    if CommandBaseData.IsCommander() then
		if not IsRemotePlayer(hPlayer.dwID) then
			CommandBaseData.ShowBtn()
		else
			CommandBaseData.HideBtn()
		end
		return
	end

	if CommandBaseData.IsViceCommander() then
		local dwMapID = hPlayer.GetMapID()
		if dwMapID == 25 or dwMapID == 27 then
			CommandBaseData.ShowBtn()
		else
			CommandBaseData.HideBtn()
		end
		return
	end

    CommandBaseData.HideBtn()
end

function CommandBaseData.ShowBtn()
    BubbleMsgData.PushMsgWithType("CommandBaseData",{
        szTitle = "",
        szBarTitle = "",
        nBarTime = 0,
        szContent = "",
        szAction = function ()
            UIMgr.Open(VIEW_ID.PanelCampConductor)
        end,
        bShowMainCityIcon = true
    })
end

function CommandBaseData.HideBtn()
    BubbleMsgData.RemoveMsg("CommandBaseData")
end


-- MiniMap开启 end
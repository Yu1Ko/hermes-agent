-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: CampOBBaseData
-- Date: 2024-04-15 10:09:48
-- Desc: ?
-- ---------------------------------------------------------------------------------

CampOBBaseData = CampOBBaseData or {className = "CampOBBaseData"}
local self = CampOBBaseData

local Model = {}
local REFRESH_TIME = 1

-------------------------------- 消息定义 --------------------------------
CampOBBaseData.Event = {}
CampOBBaseData.Event.XXX = "CampOBBaseData.Msg.XXX"

function CampOBBaseData.Init()
    self._registerEvent()
end

function CampOBBaseData.UnInit()
    
end

function CampOBBaseData.OnLogin()
    
end

function CampOBBaseData.OnFirstLoadEnd()
    
end


----------------------------------工具函数------------------------------------------
function CampOBBaseData.IsObPlayer()
	return Model.bIsObPlayer
end

function CampOBBaseData.IsInObMode()
	return Model.bIsInObMode
end
-----------------------------------------------------------------------------------
----------------------------------Model-------------------------------------------
function Model.SetLogicDataBeforeRemote(tLogicData)
	Model.tLogicDataBeforeRemote = tLogicData
end

function Model.GetLogicDataBeforeRemote()
	return Model.tLogicDataBeforeRemote
end

function Model.SetIsObPlayer(bIsObPlayer)
	Model.bIsObPlayer = bIsObPlayer
end

function Model.SetIsInObMode(bIsInObMode)
	Model.bIsInObMode = bIsInObMode
end

function Model.CampType2LogicCampType(nCampType)
	local eLogicCampType = CUSTOM_RECORDING_PLAYER_DATA_TYPE.OB_EVIL_LIST
	if nCampType == CAMP.GOOD then
		eLogicCampType = CUSTOM_RECORDING_PLAYER_DATA_TYPE.OB_GOOD_LIST
	end
	
	return eLogicCampType
end

function Model.GetLogicCommanderInfoList(nCampType)
    local CP = GetCampPlantManager()
    if not CP then
        return
    end

	local tResult = {}
	local eLogicCampType = Model.CampType2LogicCampType(nCampType)

	local nPlayerCnt = CP.GetListCount(0, eLogicCampType)
	local nSteps = nPlayerCnt - 1
	for i=0, nSteps  do
		local tRecord =  CP.GetOBListPlayer(eLogicCampType, i)

		local nPlayerID  = tRecord.dwPlayerID
		tResult[nPlayerID] 	   = {}
		tResult[nPlayerID].nHp = tRecord.PlayerInfo[0]
		tResult[nPlayerID].nX = tRecord.PlayerInfo[1]
		tResult[nPlayerID].nY = tRecord.PlayerInfo[2]
		tResult[nPlayerID].nMaxHp = tRecord.PlayerInfo[3]
		tResult[nPlayerID].bOnline = tRecord.PlayerInfo[4]
		tResult[nPlayerID].bAlive = tRecord.PlayerInfo[5]
		tResult[nPlayerID].bIsCommander = (i == 0)
		tResult[nPlayerID].nCamp = nCampType
		tResult[nPlayerID].dwPlayerID = nPlayerID
		tResult[nPlayerID].nIndex = i + 1
	end
	return tResult
end

function Model.GetLogicCommanderIDListByCamp(nCampType)
	local CP = GetCampPlantManager()
    if not CP then
        return
    end
	local tResult = {}
	local eLogicCampType = Model.CampType2LogicCampType(nCampType)
	local nPlayerCnt = CP.GetListCount(0, eLogicCampType)
	local nSteps = nPlayerCnt - 1
	for i=0, nSteps do
		local tRecord = CP.GetOBListPlayer(eLogicCampType, i)
		local nPlayerID  = tRecord.dwPlayerID
		tResult[nPlayerID] = true
	end
	return tResult
end

--通过id比较两个commander_list里面的成员是否有变化
function Model.CompareAllCommanderList(tList1, tList2)
	if not tList1 or not tList2 then
		return false
	end
	local bRetCode					= false

	local tFirstGoodCommanderList 	= tList1[CAMP.GOOD]
	local tFirstEvilCommanderList	= tList1[CAMP.EVIL]	
	local tSecGoodCommanderList 	= tList2[CAMP.GOOD]
	local tSecEvilCommanderList 	= tList2[CAMP.EVIL]

	local bGoodCode 				= table.get_len(tFirstGoodCommanderList) == table.get_len(tSecGoodCommanderList)
	local bEvilCode					= table.get_len(tFirstEvilCommanderList) == table.get_len(tSecEvilCommanderList)

	for nId, _ in pairs(tFirstGoodCommanderList) do
		if not tSecGoodCommanderList[nId] then
			bGoodCode = false
			break
		end
	end
	for nId, _ in pairs(tFirstEvilCommanderList) do
		if not tSecEvilCommanderList[nId] then
			bEvilCode = false
			break
		end
	end

	bRetCode = (bGoodCode and bEvilCode)
	return bRetCode
end

function Model.MergeLogicDataAndRemoteData(tLogicData, tRemoteData)
	local tGoodLogicData = tLogicData[CAMP.GOOD]
	local tEvilLogicData = tLogicData[CAMP.EVIL]
	local tGoodRemoteData = tRemoteData[CAMP.GOOD]
	local tEvilRemoteData = tRemoteData[CAMP.EVIL]
	
	for nCommanderID, tCommanderInfo in pairs(tGoodLogicData) do
		if tGoodRemoteData[nCommanderID] then 
			tCommanderInfo.szName 		= tGoodRemoteData[nCommanderID].szName 	
			tCommanderInfo.nForceID 	= tGoodRemoteData[nCommanderID].nForceID
		end
	end

	for nCommanderID, tCommanderInfo in pairs(tEvilLogicData) do
		if tEvilRemoteData[nCommanderID] then 
			tCommanderInfo.szName 		= tEvilRemoteData[nCommanderID].szName 	
			tCommanderInfo.nForceID 	= tEvilRemoteData[nCommanderID].nForceID
		end
	end

	return tLogicData
end

function Model.SetOldCommanderIDList(tNewAllCommanderIdList)
	Model.tOldCommanderIDList = tNewAllCommanderIdList
end

function Model.GetOldCommanderIDList()
	return Model.tOldCommanderIDList
end

function Model.SetAllCommanderInfoList(tAllCommanderInfoList)
	Model.tAllCommanderInfoList = tAllCommanderInfoList
end

function Model.GetAllCommanderInfoList()
	return Model.tAllCommanderInfoList
end

-------------------------------数据获取接口-------------------------------------------

function CampOBBaseData.OnRemoteDataReturn(tList)
	local tLogicCommanderInfoList = Model.GetLogicDataBeforeRemote()

	tLogicCommanderInfoList = Model.MergeLogicDataAndRemoteData(tLogicCommanderInfoList, tList)
	Model.SetAllCommanderInfoList(tLogicCommanderInfoList)
	FireUIEvent("ON_CAMP_OB_PLAYER_INFO_RETURN")
end



function CampOBBaseData.GetCampSkillCoolDownTime()
	local CP = GetCampPlantManager()
	local tResult = {}
	local tCampSkill = Table_GetCampSkill()
	local i = 0
	for _, tSkill in ipairs(tCampSkill) do
		tResult[tSkill.dwSkillID] = CP.GetOBGlobalData(i)
		i = i + 1
	end
	return tResult
end

function CampOBBaseData.GetCampTopBarNumData()
	local tResult 		= {}
	local tBossNum 		= {}
	local tReviveNum 	= {}
	local CP = GetCampPlantManager()
	tBossNum[CAMP.GOOD] = CP.GetOBGlobalData(10)
	tBossNum[CAMP.EVIL] = CP.GetOBGlobalData(11)
	tReviveNum[CAMP.GOOD] = CP.GetOBGlobalData(12)
	tReviveNum[CAMP.EVIL] = CP.GetOBGlobalData(13)

	tResult.tBossNum = tBossNum
	tResult.tReviveNum = tReviveNum

	return tResult
end

--函数名 : GetCommanderList
--函数描述 : 获取OB关注的指挥列表的所有信息
--参数列表 : 空
--返回值 :  bNewestData:第一个返回值， 数据是否为最新的有效数据
--		   tList:OB关注的指挥列表的所有信息
function CampOBBaseData.GetCommanderList()
	local tOldAllCommanderInfoList = Model.GetAllCommanderInfoList()
	local tNewAllCommanderIdList = {}
	tNewAllCommanderIdList[CAMP.GOOD] = Model.GetLogicCommanderIDListByCamp(CAMP.GOOD)
	tNewAllCommanderIdList[CAMP.EVIL] = Model.GetLogicCommanderIDListByCamp(CAMP.EVIL)
	local tLogicData = {}
	tLogicData[CAMP.GOOD] = Model.GetLogicCommanderInfoList(CAMP.GOOD)
	tLogicData[CAMP.EVIL] = Model.GetLogicCommanderInfoList(CAMP.EVIL)

	if Model.CompareAllCommanderList(tOldAllCommanderInfoList, tNewAllCommanderIdList) then
		--关注人员没变化，但信息可能有变化
		tLogicData = Model.MergeLogicDataAndRemoteData(tLogicData, tOldAllCommanderInfoList)
		Model.SetAllCommanderInfoList(tLogicData)
	else
		--关注人员变化
		if not table.is_empty(tNewAllCommanderIdList[CAMP.GOOD]) or not table.is_empty(tNewAllCommanderIdList[CAMP.EVIL]) then
			Model.SetLogicDataBeforeRemote(tLogicData)
			if not Model.CompareAllCommanderList(Model.GetOldCommanderIDList(), tNewAllCommanderIdList) then
				Model.SetOldCommanderIDList(tNewAllCommanderIdList)
				RemoteCallToServer("On_Camp_OBGFGetPlayerInfo", tNewAllCommanderIdList)
			end
		end
		return false, tOldAllCommanderInfoList
	end
	return true, tLogicData
end

function CampOBBaseData.SetCampOfBoardInfo(nCamp)
	Model.nCamp = nCamp
end

function CampOBBaseData.SwitchBoardInfoByCamp(nCamp)
	-- BattleFieldMap.UpdateBoardInfoByCamp(nCamp)
	-- MiddleMapCommand.UpdateBoardInfoByCamp(nCamp)
end

function CampOBBaseData.GetCampOfBoardInfo()
	return Model.nCamp
end

local function TimerFunction()
	local CP = GetCampPlantManager()
    if not CP then
        return
	end
	
	CP.ApplyOBData()
end

function CampOBBaseData.Open()
	Model.SetIsObPlayer(true)
	Model.SetIsInObMode(true)
	self.SetCampOfBoardInfo(CAMP.GOOD)
    self._startTimer()
	-- Station.Hide()
	-- Station.EnterShowMode("CampOB")

	-- CampOB.Open()
	-- CMDOB.Open()
	FireUIEvent("PLAYER_BECOME_CAMP_OB")
end

function CampOBBaseData.IsOpened()
	return self.IsInObMode()
end



function CampOBBaseData.Close()
	if not self.IsOpened() then
		return
	end
	--通知服务端关闭ob
	RemoteCallToServer("On_Camp_OBGFClosePanel")
	Model.SetIsObPlayer(false)
	Model.SetIsInObMode(false)

	-- BreatheCall("CAMP_OB_BASE_APPLY", false)
    self._stopTimer()

	-- CampOB.Close()
	-- CMDOB.Close()

	local pPlayer = g_pClientPlayer
	if pPlayer then
		self.SetCampOfBoardInfo(pPlayer.nCamp)
	end

	FireUIEvent("CAMP_OB_BECOME_PLAYER")
	-- Station.BackOrExitShowMode()
	-- Station.Show()
	
	-- if not bDisableSound then
	-- 	PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
	-- end
end

function CampOBBaseData._onMiddleMapOpen()
	if not self.IsObPlayer() and not self.bSetCampInfo then
		local player = g_pClientPlayer 
		if not player then return end
		self.SetCampOfBoardInfo(player.nCamp)
		self.bSetCampInfo = true
	end
end

function CampOBBaseData._startTimer()
    self.nTimer = Timer.AddCycle(self, REFRESH_TIME, function()
        TimerFunction()
    end)
end

function CampOBBaseData._stopTimer()
    if self.nTimer then 
        Timer.DelTimer(self, self.nTimer)
        self.nTimer = nil
    end
end

function CampOBBaseData._registerEvent()
    Event.Reg(self, "ON_CAMP_PLANT_APPLY_OB_GLOBAL_DATA_RESPOND", function()
    
    end)

    Event.Reg(self, "ON_CAMP_PLANT_APPLY_OB_LIST_DATA_RESPOND", function()
    
    end)

	Event.Reg(self, EventType.OnViewOpen, function(nViewID)
		if nViewID == VIEW_ID.PanelMiddleMap then
			self._onMiddleMapOpen()
		end
	end)
end

HomelandMiniGameData = HomelandMiniGameData or {}
local self = HomelandMiniGameData

local _PET_ITEM_TYPE = 1
local _OTHER_ITEM_TYPE = 8
local _BTN_COST_TYPE =
{
	--NO_COST = 0,
	FOR_COST = 1, -- 定价按钮
	SHOW_COST_TIP_FIRST = 2, -- 点击后需要先提示付费使用
	FOR_PASSWORD = 3,	--设置密码
	SHOW_PW_TIP = 4,    --解密，传送使用
}
local GameID2FurniturnType = {
    --家园种植
    [2] = 12,
    [13] = 12,

	--藏酒
	[7] = 22,
}
local GameID2FurniturnModelID = {
    --家园种植
    [2] = {6788, 6789, 8952, 8953, 8954, 12521, 13444},
    [13] = {6788, 6789, 8952, 8953, 8954, 12521, 13444},
}
local tPetHouseState = {
	[1] = "安置",
	[2] = "准备出行",
	[3] = "出行",
	[4] = "归来",
}

local tBrewState = {
	[1] = "今朝醉",
	[2] = "六日醉",
	[3] = "旬又三",
	[4] = "醉月香",
	[5] = "藏百日",
}

local tFilterCheck =
{
	[0] = {
		szCheck = "CheckBox_All",
	},
	[1] = {
		szCheck    = "CheckBox_Plant",
		DATAMANAGE = 1064,
		ITEMSTART  = 2,
		BYTE_NUM   = 2,
	},
	[2] = {
		szCheck    = "CheckBox_Cereals",
		DATAMANAGE = 1065,
		ITEMSTART  = 0,
		BYTE_NUM   = 2,
	},
	[3] = {
		szCheck    = "CheckBox_Pet",
		DATAMANAGE = 1112,
		ITEMSTART  = 0,
		BYTE_NUM   = 1,
	},
	[4] = {
		szCheck    = "CheckBox_Fish",
		DATAMANAGE = 1109,
		ITEMSTART  = 0,
		BYTE_NUM   = 2,
	},
	[5] = {
		szCheck    = "CheckBox_Perfume",
		DATAMANAGE = 1153,
		ITEMSTART  = 0,
		BYTE_NUM   = 1,
	},
	[6] = {
		szCheck    = "CheckBox_HouseKeep",
		DATAMANAGE = 1155,
		ITEMSTART  = 0,
		BYTE_NUM   = 2,
	},
	[7] = {
		szCheck    = "CheckBox_ShopKeeper",
		DATAMANAGE = 1157,
		ITEMSTART  = 0,
		BYTE_NUM   = 1,
	},
}

HomelandMiniGameData.tFilterCheck = tFilterCheck
function HomelandMiniGameData.OnInit()
    ---- 逻辑相关数据
	self.tSlotSelectionItem = --存每个选择的道具
	{
		-- [nSlotID] = tItem, --> {dwTabType=dwTabType, dwIndex=dwIndex, nStackNum=nStackNum} -- 注意：有的dwIndex字段本身也是一个table（存疑）
	}

	-- 重要：加上解释
	self.tData =
	{
		--[[
			nGameID = 3,
			nGameState = 1,
			bSaveHistory = true/false, -- 重要：考虑剥离出去
			aBtns =
			{
				{nID=nID, szName=szName, nCostType=0/1/2, szShortcutKey=szShortcutKey, nPosRelX=nPosRelX, nPosRelY=nPosRelY},
				...,
			},
			tModule1 = {},
			tModule2 = {},
			tModule1Item = {},
			szTip = "", -- 重要： 放这里有些奇怪
		--]]
	}
	self.nCost = nil -- 单位：金币
end

function HomelandMiniGameData.UnInit()
	Timer.DelAllTimer(self)
	self.AutoTimerID = nil
end

local m_bShowLog = false
local function CanShowLog()
    return m_bShowLog
end

function HomelandMiniGameData.Reset()
    if CanShowLog() then
		LOG.INFO("==== 调用了函数 HomelandMiniGameData.ResetData()")
	end

	-- 重要：其他的不需要清空吗？
	self.tSlotSelectionItem = {}
	self.nCost = nil
	self.hCurSelectionBox = nil
	self.hCurSelectionBoxNum = nil
	self.aAllTxtBtnActions = nil
end

function HomelandMiniGameData.GetModule1SlotItemInfo()
	local tSlot = self.tData.tModule1.tSlot
	return tSlot and self.tSlotSelectionItem[tSlot.nID] or nil
end

-- 重要： 使用参数
function HomelandMiniGameData.FormatGameData(tData)
	if CanShowLog() then
		LOG.INFO("==== 调用了函数 HomelandMiniGameData.FormatGameData()")
	end
	if not self.tSlotSelectionItem then
		return
	end

	local tTemp = {0, 0, 0, 0, 0, 0, 0}
	local tItem = self.GetModule1SlotItemInfo()
	if tItem then
		tTemp[1] = self.SetDwordValueByUInt(tItem)
		self.SetHistorySelectionItem(1, tItem)
	end

	local nKey = 2 -- 重要：为何从2开始？

	for _, tMod in pairs(self.tData.tModule2) do
		for k, v in pairs(tMod.tSlots) do
			tItem = self.tSlotSelectionItem[v.nID]
			if tItem then
				tTemp[nKey] = self.SetDwordValueByUInt(tItem)
			end
			self.SetHistorySelectionItem(nKey, tItem)
			nKey = nKey + 1
		end
	end

	if CanShowLog() then
		LOG.INFO("==== 最终得到的数据是：")
		UILog_Dev2(tTemp)
	end
	return tTemp[1], tTemp[2], tTemp[3], tTemp[4], tTemp[5], tTemp[6], tTemp[7]
end

function HomelandMiniGameData.AddItemToSlot(tSlot, tItem)
	if CanShowLog() then
		LOG.INFO("==== 调用了函数 HomelandMiniGameData.AddItemToSlot()，参数：")
		UILog_Dev2(tSlot, tItem)
	end

	if tSlot.nItemMaxNum ~= 0 and tSlot.nItemMaxNum < tItem.nStackNum then
		OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_HOUSE_NUM_TIP)
		return false
	end

	--local tItemElem = clone(tItem) -- 重要：不能对副本进行操作，因为 tSlotSelectionItem 里保存的是对象本身而非其副本（有些奇怪，可能要改进写法）
	self.tSlotSelectionItem = self.tSlotSelectionItem or {}
	tItem.bMeet = tSlot.nItemMinNum <= tItem.nStackNum
	self.tSlotSelectionItem[tSlot.nID] = tItem

	if CanShowLog() then
		LOG.INFO("==== 调用成功！")
	end
	return true
end

function HomelandMiniGameData.GetBtnCostType(nBtnID) -- 可能不需要这个函数……
	local aBtns = self.tData.aBtns
	local t = FindTableValueByKey(aBtns, "nID", nBtnID)
	if t then
		return t.nCostType
	end
	return nil
end

-- 重要： nIndex 表示什么？
function HomelandMiniGameData.SetHistorySelectionItem(nIndex, tData)
	if CanShowLog() then
		LOG.INFO("==== 调用了函数 HomelandMiniGameData.SetHistorySelectionItem()，参数：")
		UILog_Dev2(nIndex, tData)
	end
	if not self.tData.bSaveHistory then
		if CanShowLog() then
			LOG.INFO("==== 不保存历史数据，直接无视掉")
		end
		return
	end
	local nGameID = self.tData.nGameID
	local nGameState = self.tData.nGameState

	if not Storage.HomeLandBuild.tHistorySelectionItem[nGameID] then
		Storage.HomeLandBuild.tHistorySelectionItem[nGameID] = {}
	end

	if not Storage.HomeLandBuild.tHistorySelectionItem[nGameID][nGameState] then
		Storage.HomeLandBuild.tHistorySelectionItem[nGameID][nGameState] = {}
	end

	if CanShowLog() then
		LOG.INFO("==== 数据添加成功")
	end
	Storage.HomeLandBuild.tHistorySelectionItem[nGameID][nGameState][nIndex] = tData
	Storage.HomeLandBuild.Dirty()
end

local tPetTypeToIndex = {        -- 宠物类型转换成筛选索引
	[1] = 2, --两栖动物
	[2] = 3, --禽鸟（小）宠物
	[3] = 4, --走兽（肉食类）宠物
	[4] = 5, --机甲宠物
	[5] = 6, --啮齿类宠物
	[6] = 7, --畜牧类宠物
	[7] = 3, --禽鸟（大）宠物
	[8] = 8, --异类宠物
}
function HomelandMiniGameData.FilterPet(tBoxType)
	if CanShowLog() then
		LOG.INFO("==== 调用了函数 HomelandMiniGameData.FilterPet()")
	end
	if not tBoxType then
		if CanShowLog() then
			LOG.INFO("==== 未传入参数，无视掉！")
		end
		return
	end
	local tTemp = {}
	local tPetList = self.GetExistingFellowPetIndices()

	local tbFilter = FilterDef.HomelandPet.GetRunTime()
	for _, nPetID in pairs(tPetList) do
		local nBoxType = HomelandEventHandler.LandObject_GetBoxTypeByItem(_PET_ITEM_TYPE, nPetID)
		if tBoxType[nBoxType] then
			if not tbFilter or (tbFilter[1] and tbFilter[1][1] and (tbFilter[1][1] == 1 or tPetTypeToIndex[nBoxType] == tbFilter[1][1]))then
				table.insert(tTemp, nPetID)
			end
		end
	end
	if CanShowLog() then
		LOG.INFO("==== 最终得到的宠物index列表是：")
		UILog_Dev2(tTemp)
	end
	return tTemp
end

function HomelandMiniGameData.FilterPendantPet(tBoxType)
	if CanShowLog() then
		LOG.INFO("==== 调用了函数 HomelandMiniGameData.FilterPendantPet()")
	end
	if not tBoxType then
		if CanShowLog() then
			LOG.INFO("==== 未传入参数，无视掉！")
		end
		return
	end
	local tTemp = {}
	local player = GetClientPlayer()
	if not player then
		return
	end

	local tPendantPet = player.GetAllPendentPetData() or {}
	for _, nPendantPetID in pairs(tPendantPet) do -- 重要：其实元素不是ID
		if nPendantPetID then
			local nBoxType = HomelandEventHandler.LandObject_GetBoxTypeByItem(_OTHER_ITEM_TYPE, nPendantPetID.dwItemIndex) -- dwIndex
			if tBoxType[nBoxType] then
				table.insert(tTemp, nPendantPetID)
			end
		end
	end
	if CanShowLog() then
		LOG.INFO("==== 最终得到的挂宠列表是：")
		UILog_Dev2(tTemp)
	end
	return tTemp
end

function HomelandMiniGameData.FilterHorse(tBoxType)
	if CanShowLog() then
		LOG.INFO("==== 调用了函数 HomelandMiniGameData.FilterHorse()")
	end
	if not tBoxType then
		if CanShowLog() then
			LOG.INFO("==== 未传入参数，无视掉！")
		end
		return
	end

	local tTemp = {}
	local tHorseList = self.GetExistingHorses()
	for _, tbInfo in pairs(tHorseList) do
		if tbInfo and tbInfo.item then
			local nBoxType = HomelandEventHandler.LandObject_GetBoxTypeByItem(_OTHER_ITEM_TYPE, tbInfo.item.dwIndex)
			-- 筛选
			if tBoxType[nBoxType] then
				table.insert(tTemp, tbInfo)
			end
		end
	end
	if CanShowLog() then
		LOG.INFO("==== 最终得到的坐骑对象列表是：")
		UILog_Dev2(tTemp)
	end
	return tTemp
end

---------------- 通用数据处理

-- 获取玩家身上的马匹
function HomelandMiniGameData.GetExistingHorses()
	if CanShowLog() then
		LOG.INFO("==== 调用了函数 HomelandMiniGameData.GetExistingHorses()")
	end
	local nMaxHorses = GLOBAL.HORSE_PACKAGE_SIZE
	local aHorsePets ={}  -- 马匹

	for i = 0, nMaxHorses - 1 do
		local oneHorseItem = ItemData.GetItemByPos(INVENTORY_INDEX.HORSE, i)
		if oneHorseItem then
			table.insert(aHorsePets, {item = oneHorseItem, nBox = INVENTORY_INDEX.HORSE, nIndex = i})
		end
	end
	if CanShowLog() then
		LOG.INFO("==== 最终得到的坐骑对象列表是：")
		UILog_Dev2(aHorsePets)
	end
	return aHorsePets
end

-- 获取玩家身上的宠物
function HomelandMiniGameData.GetExistingFellowPetIndices()
	if CanShowLog() then
		LOG.INFO("==== 调用了函数 HomelandMiniGameData.GetExistingFellowPetIndices()")
	end
	local pPlayer = GetClientPlayer()
	local tPetList = pPlayer.GetExistFellowPetIndexs()
	if CanShowLog() then
		LOG.INFO("==== 最终得到的宠物index列表是：")
		UILog_Dev2(tPetList)
	end
	return tPetList
end

---------------- UI配置数据相关

function HomelandMiniGameData.GetModuleUIInfo(nModuleID)
	if CanShowLog() then
		LOG.INFO("==== 调用了函数 HomelandMiniGameData.GetModuleUIInfo()，参数：")
		UILog_Dev2(nModuleID)
	end
	local tGameMode = Table_GetTableHomelandMiniGameMode(nModuleID)
	local tTemp = {}
	if tGameMode then
		tTemp.szTitle = tGameMode.szName
		tTemp.tSlots = self.GetSlotsUIInfo(tGameMode.tSlotID)
	end
	if CanShowLog() then
		LOG.INFO("==== 返回的数据：")
		UILog_Dev2(tTemp)
	end
	return tTemp
end

function HomelandMiniGameData.GetSlotsUIInfo(aSlotIDs)
	if CanShowLog() then
		LOG.INFO("==== 调用了函数 HomelandMiniGameData.GetSlotsUIInfo()，参数：")
		UILog_Dev2(aSlotIDs)
	end
	local tSlots = {}
	local tGameSlot
	for k, nSlotID in pairs(aSlotIDs or {}) do
		tGameSlot = Table_GetTableHomelandMiniGameSlot(nSlotID)
		if tGameSlot then
			table.insert(tSlots, tGameSlot)
		end
	end
	if CanShowLog() then
		LOG.INFO("==== 最终得到的数据：")
		UILog_Dev2(tSlots)
	end
	return tSlots
end

---------------- 逻辑相关

function HomelandMiniGameData.CheckSlotState(aConditionSlots)
	if CanShowLog() then
		LOG.INFO("==== 调用了函数 HomelandMiniGameData.CheckSlotState()，参数：")
		UILog_Dev2(aConditionSlots)
	end
	local bFinished = true
	self.tSlotSelectionItem = self.tSlotSelectionItem or {}
	local tSlot = nil
	for k, nSlotID in pairs(aConditionSlots or {}) do
		-- 重要： 提取常量
		if nSlotID == 28  then -- or nSlotID == 29
			local nSlotTypeID = self.GetModuleUIInfo(nSlotID) -- 重要：变量名字要改（另外要求传入moduleID，为何传入的却是SlotID？）
			if nSlotTypeID  and nSlotTypeID.tSlots and nSlotTypeID.tSlots[1].nID then
				tSlot = self.tSlotSelectionItem[nSlotTypeID.tSlots[1].nID]
			else
				tSlot = nil
			end
		else
			tSlot = self.tSlotSelectionItem[nSlotID]
		end

		if not tSlot or not tSlot.bMeet then
			bFinished = false
			break
		end
	end
	if CanShowLog() then
		LOG.INFO("==== 最终的结果是：" .. tostring(bFinished))
	end
	return bFinished
end

function HomelandMiniGameData.GetItemCommonDataFromUIItem(tItem)
	local dwTabType, nStackNum, dwIndex
	local nSlotType = tItem.nSlotType
	if nSlotType == PETS_SCREE_TYPE.ORDINARYPET then
		if CanShowLog() then
			LOG.INFO("==== 进入了第一个分支")
		end
		dwTabType = tItem.dwTabType
		nStackNum = tItem.nStackNum
		dwIndex = tItem.dwIndex
	elseif nSlotType == PETS_SCREE_TYPE.HANGUPPET then
		if CanShowLog() then
			LOG.INFO("==== 进入了第二个分支")
		end
		dwTabType = tItem.dwTabType
		nStackNum = tItem.nStackNum
		dwIndex = tItem.dwIndex
	elseif nSlotType == PETS_SCREE_TYPE.ORDINARYMOUNT then
		if CanShowLog() then
			LOG.INFO("==== 进入了第三个分支")
		end
		dwTabType = tItem.dwTabType
		nStackNum = tItem.nStackNum
		dwIndex = tItem.dwIndex
	else
		if CanShowLog() then
			LOG.INFO("==== 进入了第四个分支")
		end
		dwTabType = tItem.dwTabType
		nStackNum = tItem.nStackNum
		dwIndex = tItem.dwIndex
	end
	return dwTabType, nStackNum, dwIndex
end

-- 重要：神奇的 dwValue ...
function HomelandMiniGameData.SetDwordValueByUInt(tItem)
	if CanShowLog() then
		LOG.INFO("==== 调用了函数 HomelandMiniGameData.SetDwordValueByUInt()，参数：")
		UILog_Dev2(tItem)
	end
	local pHlMgr = GetHomelandMgr()
	local dwValue = 0

	local dwTabType, nStackNum, dwIndex = self.GetItemCommonDataFromUIItem(tItem)

	dwValue = pHlMgr.SetDWORDValueByuint8(dwValue, 0, dwTabType)  --主道具type
	dwValue = pHlMgr.SetDWORDValueByuint8(dwValue, 1, nStackNum)  --主道具数量
	dwValue = pHlMgr.SetDWORDValueByuint16(dwValue, 2, dwIndex)   --主道具ID

	if CanShowLog() then
		LOG.INFO("==== 最终的 dwValue == " .. tostring(dwValue))
	end
	return dwValue
end

--[[
	家具小玩法通用界面数据解析成这个格式
	tHouseGame =
	{
		nGame = 1,
		nGameState = 1,
		szTitle = "xx1",
		szTip = "",
		tModule1 = {szTitle="xx2", tSlot={}, szInfo="", nCountdownType=0, szCountdownTip="", nTime=10},
		tModule2 =
		{
			[1] =
			{
				szTitle="xx3",
				tSlots=
				{
					{nID=1, nItemType=1, szName="**", nItemMinNum=1, nItemMaxNum=2},
					...,
				}
			},
		},
		tBtn =
		{
			[1]={szName="按钮1", tCondition={},},
			...,
		},
	}
--]]
function HomelandMiniGameData.ParseMinGameData(tData)
	-- 下面是测试用数据
	--[[
	tData = {}
	tData.nGameID = 3
	tData.nGameState = 0
	tData.szInfo = "<text>text=\"养猫"
	tData.nTime = GetCurrentTime() + 10
	--tData.tModule1Item = {dwTabType = 5, dwIndex = 116}  --dwTabType = 8, dwIndex = 20074 dwIndex = 288
	tData.nGameState = 0
	--]]
	-------------------------

	if not tData then
		return
	end
	if CanShowLog() then
		LOG.INFO("==== 调用了函数 HomelandMiniGameData.ParseMinGameData()")
		LOG.INFO("==== ↓↓↓↓ 这是参数 tData 内容的开始")
		for k, v in pairs(tData) do
			LOG.INFO("====== key: " .. tostring(k))
			LOG.INFO("====== value: ")
			UILog_Dev2(v)
		end
		LOG.INFO("==== ↑↑↑↑ 这是参数 tData 内容的结束")
	end
	local tTemp = {nGameID = tData.nGameID, nGameState = tData.nGameState or 0, tModule1Item = tData.tModule1Item}
	tTemp.dwMapID = tData.dwMapID
	tTemp.nCopyIndex = tData.nCopyIndex
	tTemp.nLandIndex = tData.nLandIndex
	tTemp.nDataType = tData.nDataType
	tTemp.nDataPos = tData.nDataPos
	tTemp.nFurnitureInstanceID = tData.nFurnitureInstanceID
	tTemp.nFurnitureType = tData.nFurnitureType
	tTemp.nFurnitureID = tData.nFurnitureID
	tTemp.dwRepresentID = tData.dwRepresentID
	tTemp.tPosInfo = tData.tPosInfo

	--local tGameSlot = {}
	local tGameInfo = Table_GetTableHomelandMiniGameInfo(tTemp.nGameID, tTemp.nGameState)
	assert(tGameInfo, string.format("--Table_HomelandMiniGameInfo == nil nGameID:%d nGameState:%d--", tTemp.nGameID, tTemp.nGameState))
	if not tGameInfo then
		return
	end
	tTemp.szTitle = tGameInfo.szTitle
	tTemp.szTip = tGameInfo.szTip
	tTemp.bSaveHistory = tGameInfo.bSaveHistory
	tTemp.tModule1 = {}
	tTemp.tModule1.nCountdownType = tGameInfo.nCountdownType
	tTemp.tModule1.szCountdownTip = tGameInfo.szCountdownTip
	tTemp.tModule1.szInfo = tData.szInfo
	tTemp.tModule1.nTime = tData.nTime

	local nModuleID
	if tGameInfo.tModuleID[1] then
		nModuleID = tGameInfo.tModuleID[1]
		local tModule = self.GetModuleUIInfo(nModuleID)
		tTemp.tModule1.nModuleID = nModuleID
		tTemp.tModule1.szTitle = tModule.szTitle
		tTemp.tModule1.tSlot = tModule.tSlots[1]
	end

	tTemp.tModule2 = {}
	local nLength = #tGameInfo.tModuleID
	for i = 2, nLength do
		nModuleID = tGameInfo.tModuleID[i]
		local tModule = self.GetModuleUIInfo(nModuleID)
		if tModule then
			if tData.HousePlayGameHorseList and #tData.HousePlayGameHorseList > 0 then
				for k,v in pairs(tModule.tSlots) do
					if v.nType == PETS_SCREE_TYPE.ORDINARYMOUNT then
						v.nHorseBoxId = tData.HousePlayGameHorseList[k]
					end
				end
			end
			tModule.nModuleID = nModuleID
			table.insert(tTemp.tModule2, tModule)
		end
	end

	tTemp.aBtns = {}
	for _, nBtnID in pairs(tGameInfo.tBtnID or {}) do
		local tBtnData = Table_GetTableHomelandMiniGameBtn(nBtnID)
		if tBtnData then
			table.insert(tTemp.aBtns, tBtnData)
		end
	end

	tTemp.tDisableBtn = {}
	for nBtnID, _ in pairs(tGameInfo.tDisableBtn or {}) do
		table.insert(tTemp.tDisableBtn, nBtnID)
	end

	if CanShowLog() then
		LOG.INFO("==== ↓↓↓↓ 这是返回值 tTemp 内容的开始")
		for k, v in pairs(tTemp) do
			LOG.INFO("====== key: " .. tostring(k))
			LOG.INFO("====== value: ")
			UILog_Dev2(v)
		end
		LOG.INFO("==== ↑↑↑↑ 这是返回值 tTemp 内容的结束")
	end

	return tTemp
end

function HomelandMiniGameData.GetMiniGameCost()
	local tData = self.tData
	local nCost = HomelandEventHandler.LandObject_GetCostFromSDWordInfo(tData.dwMapID, tData.nCopyIndex, tData.nLandIndex,
			tData.nDataType, tData.nDataPos,
			tData.nFurnitureInstanceID, tData.nFurnitureType, tData.nFurnitureID,
			tData.tPosInfo, tData.nGameID, tData.nGameState)
	return nCost or 0
end

function HomelandMiniGameData.GetBrewStateByTime(nCostTime)
	local szString = ""
	local nCurrentTime = GetCurrentTime()
	local nCostDay = math.floor((nCurrentTime - nCostTime) / 86400)
	if nCostDay >= 1 and nCostDay < 6 then
		szString = tBrewState[1]
	elseif nCostDay >= 6 and nCostDay < 13 then
		szString = tBrewState[2]
	elseif nCostDay >= 13 and nCostDay < 30 then
		szString = tBrewState[3]
	elseif nCostDay >= 30 and nCostDay < 90 then
		szString = tBrewState[4]
	elseif nCostDay >= 90 then
		szString = tBrewState[5]
	end
	return szString
end

function HomelandMiniGameData.CheckCanOpenFrame(tPosInfo)
	if CanShowLog() then
		LOG.INFO("====== 调用了函数 CheckCanOpenFrame()，参数：")
		UILog_Dev2(tPosInfo)
	end

	if not tPosInfo or not tPosInfo[1] then
		return true
	end
	local player = GetClientPlayer()
	if not player then
		return
	end
	local dwObjPosX = tPosInfo[1]
	local dwObjPosY = tPosInfo[2]
	local dwObjPosZ = tPosInfo[3]
	local nMaxInteractDist = tPosInfo[4]

	local bCanShow = LandObject_IsObjTooFarFromPlayer({dwObjPosX, dwObjPosY, dwObjPosZ}, {player.nX, player.nY, player.nZ},
			nMaxInteractDist)
	return not bCanShow
end

function HomelandMiniGameData.GameProtocol(nBtnID, nCostType, bClose)
	if CanShowLog() then
		Log("====== 调用了函数 GameProtocol()，参数： ")
		UILog_Dev2(nBtnID, nCostType)
	end

	local tData = self.tData
	if not tData then
		return
	end
	local dwValue2, dwValue3, dwValue4, dwValue5, dwValue6, dwValue7, dwValue8 = self.FormatGameData()

	local pHlMgr = GetHomelandMgr()
	if nCostType == _BTN_COST_TYPE.FOR_COST then
		dwValue8 = self.nCost
	elseif nCostType == _BTN_COST_TYPE.FOR_PASSWORD or nCostType == _BTN_COST_TYPE.SHOW_PW_TIP then
		dwValue8 = 0
		dwValue8 = pHlMgr.SetDWORDValueByuint8(dwValue8, 0, self.nPWD1)
		dwValue8 = pHlMgr.SetDWORDValueByuint8(dwValue8, 1, self.nPWD2)
		dwValue8 = pHlMgr.SetDWORDValueByuint8(dwValue8, 2, self.nPWD3)
		dwValue8 = pHlMgr.SetDWORDValueByuint8(dwValue8, 3, self.nPWD4)
	end

	--传送坐标----------
	if tData.nGameID == 17 then
		local nInstID = tData.nFurnitureInstanceID
		local tPosInfo = tData.tPosInfo
		dwValue4 = nInstID
		dwValue5, dwValue6, dwValue7 = tPosInfo[5], tPosInfo[6], tPosInfo[7]
	end
	------------------------------------
	local dwValue1 = 0
	dwValue1 = pHlMgr.SetDWORDValueByuint8(dwValue1, 0, tData.nGameState) --游戏状态
	dwValue1 = pHlMgr.SetDWORDValueByuint8(dwValue1, 1, tData.nGameID)   --游戏类型ID
	dwValue1 = pHlMgr.SetDWORDValueByuint8(dwValue1, 2, nBtnID)         --按键ID

	-- 对于定价按钮， 先通过UI输入框得到数字，赋值给 dwValue8，然后走与下面一样的流程

	if tData.nDataType == LAND_OBJECT_TYPE.SD_EIGHT_DWORD_SCRIPT then
		pHlMgr.CallSDEightDwordScript(tData.nFurnitureInstanceID, tData.nDataPos, dwValue1, dwValue2, dwValue3, dwValue4, dwValue5, dwValue6, dwValue7, dwValue8)
	elseif tData.nDataType == LAND_OBJECT_TYPE.SD_FOUR_DWORD_SCRIPT then
		pHlMgr.CallSDFourDwordScript(tData.nFurnitureInstanceID, tData.nDataPos, dwValue1, dwValue2, dwValue3, dwValue4, dwValue5, dwValue6, dwValue7, dwValue8)
	elseif tData.nDataType == LAND_OBJECT_TYPE.SD_TWO_DWORD_SCRIPT then
		pHlMgr.CallSDTwoDwordScript(tData.nFurnitureInstanceID, tData.nDataPos, dwValue1, dwValue2, dwValue3, dwValue4, dwValue5, dwValue6, dwValue7, dwValue8)
	elseif tData.nDataType == LAND_OBJECT_TYPE.FOUR_DWORD_SCRIPT then
		pHlMgr.CallFourDwordScript(tData.nFurnitureInstanceID, tData.nDataPos, dwValue1, dwValue2, dwValue3, dwValue4, dwValue5, dwValue6, dwValue7, dwValue8)
	end

	if bClose then
		UIMgr.Close(VIEW_ID.PanelHomeInteract)
	end
end

function HomelandMiniGameData.GetAllFurniturnInsByType()
    -- FurnitureData.GetFurnTypeAndIDByModelID(self.tData)
    local pHlMgr = GetHomelandMgr()
    local tFurn = {}
    local dwCurModelID = self.tData.dwRepresentID
    local nFurnitureType = GameID2FurniturnType[self.tData.nGameID]
	local tbGameTypeModelIDList = GameID2FurniturnModelID[self.tData.nGameID]
    local nCount = pHlMgr.GetCategoryCount(self.tData.nLandIndex, nFurnitureType)
    for i = 1, nCount do
		local tbObjInfo = pHlMgr.GetLOByCategory(self.tData.nLandIndex, nFurnitureType, i) or {}
		if tbObjInfo.nModuleID == dwCurModelID then
			table.insert(tFurn, tbObjInfo)
		elseif tbGameTypeModelIDList and table.contain_value(tbGameTypeModelIDList, tbObjInfo.nModuleID) then
			table.insert(tFurn, tbObjInfo)
		end
    end
    return tFurn
end

function HomelandMiniGameData.GetPetType()
	for k,v in pairs(self.tSlotSelectionItem) do
		if self.tSlotSelectionItem[k] then
			local dwTabType, dwIndex = GetItemIndexByFellowPetIndex(v.dwIndex)
			local item = GetItemInfo(dwTabType, dwIndex)
			if item then
				if item.nSub == EQUIPMENT_SUB.PET then
					return HomelandEventHandler.LandObject_GetBoxTypeByItem(_PET_ITEM_TYPE, v.dwIndex)
				else
					return HomelandEventHandler.LandObject_GetBoxTypeByItem(v.dwTabType, v.dwIndex)
				end
			end
		end
	end
	return false
end

function HomelandMiniGameData.GetPetHouseState(nGameID, nGameState)
	local szState = ""
	if (nGameID ~= 1 and nGameID ~= 4 and nGameID ~= 5 and nGameID ~= 6 and nGameID ~= 18) then
		return szState
	end
	local szState = tPetHouseState[nGameState] or ""
	return szState
end

function HomelandMiniGameData.GetFurniturnGameStateByInstanceID(nFurnitureInstanceID)
	local pHomelandMgr = GetHomelandMgr()
	local nDataType = self.tData.nDataType
	local tParam = {}
	if nDataType == LAND_OBJECT_TYPE.SD_EIGHT_DWORD_SCRIPT then
		tParam = pHomelandMgr.GetSDEightDwordScript(self.tData.dwMapID, self.tData.nCopyIndex, self.tData.nLandIndex, nFurnitureInstanceID, self.tData.nDataPos)
	elseif nDataType == LAND_OBJECT_TYPE.SD_FOUR_DWORD_SCRIPT then
		tParam = pHomelandMgr.GetSDFourDwordScript(self.tData.dwMapID, self.tData.nCopyIndex, self.tData.nLandIndex, nFurnitureInstanceID, self.tData.nDataPos)
	elseif nDataType == LAND_OBJECT_TYPE.SD_TWO_DWORD_SCRIPT then
		tParam = pHomelandMgr.GetSDTwoDwordScript(self.tData.dwMapID, self.tData.nCopyIndex, self.tData.nLandIndex, nFurnitureInstanceID, self.tData.nDataPos)
	elseif nDataType == LAND_OBJECT_TYPE.FOUR_DWORD_SCRIPT then
		tParam = pHomelandMgr.GetFourDwordScript(self.tData.dwMapID, self.tData.nCopyIndex, self.tData.nLandIndex, nFurnitureInstanceID, self.tData.nDataPos)
	end
	if tParam then
		return pHomelandMgr.GetDWORDValueByuint8(tParam[1], 0)
	end
end

local function IsSeedingGame(nGameID)
	return nGameID == 2 or nGameID == 13
end

--一键交互所有同类型家具
function HomelandMiniGameData.SeedingAllFurniture(nBtnID, nCostType, bClose)
	if CanShowLog() then
		Log("====== 调用了函数 GameProtocol()，参数： ")
		UILog_Dev2(nBtnID, nCostType)
	end

	local tData = self.tData
	if not tData then
		return
	end
	local dwValue2, dwValue3, dwValue4, dwValue5, dwValue6, dwValue7, dwValue8 = self.FormatGameData()
	local pHlMgr = GetHomelandMgr()
	if nCostType == _BTN_COST_TYPE.FOR_COST then
		dwValue8 = self.nCost
	elseif nCostType == _BTN_COST_TYPE.FOR_PASSWORD or nCostType == _BTN_COST_TYPE.SHOW_PW_TIP then
		dwValue8 = 0
		dwValue8 = pHlMgr.SetDWORDValueByuint8(dwValue8, 0, self.nPWD1)
		dwValue8 = pHlMgr.SetDWORDValueByuint8(dwValue8, 1, self.nPWD2)
		dwValue8 = pHlMgr.SetDWORDValueByuint8(dwValue8, 2, self.nPWD3)
		dwValue8 = pHlMgr.SetDWORDValueByuint8(dwValue8, 3, self.nPWD4)
	end

	--传送坐标----------
	if tData.nGameID == 17 then
		local nInstID = tData.nFurnitureInstanceID
		local tPosInfo = tData.tPosInfo
		dwValue4 = nInstID
		dwValue5, dwValue6, dwValue7 = tPosInfo[5], tPosInfo[6], tPosInfo[7]
	end
	------------------------------------
	local dwValue1 = 0
	dwValue1 = pHlMgr.SetDWORDValueByuint8(dwValue1, 0, tData.nGameState) --游戏状态
	dwValue1 = pHlMgr.SetDWORDValueByuint8(dwValue1, 1, tData.nGameID)   --游戏类型ID
	dwValue1 = pHlMgr.SetDWORDValueByuint8(dwValue1, 2, nBtnID)         --按键ID

	-- 对于定价按钮， 先通过UI输入框得到数字，赋值给 dwValue8，然后走与下面一样的流程
	local tbAllFurniturn = HomelandMiniGameData.GetAllFurniturnInsByType()
	local nCount = #tbAllFurniturn
	local nIndex = 1
	self.AutoTimerID = Timer.AddCycle(self, 0.1, function ()
		local tbFurniture = tbAllFurniturn[nIndex]
		local nGameState = HomelandMiniGameData.GetFurniturnGameStateByInstanceID(tbFurniture.nInstanceID)
		local function _doGameProtocol()
			if tData.nDataType == LAND_OBJECT_TYPE.SD_EIGHT_DWORD_SCRIPT then
				pHlMgr.CallSDEightDwordScript(tbFurniture.nInstanceID, tData.nDataPos, dwValue1, dwValue2, dwValue3, dwValue4, dwValue5, dwValue6, dwValue7, dwValue8)
			elseif tData.nDataType == LAND_OBJECT_TYPE.SD_FOUR_DWORD_SCRIPT then
				pHlMgr.CallSDFourDwordScript(tbFurniture.nInstanceID, tData.nDataPos, dwValue1, dwValue2, dwValue3, dwValue4, dwValue5, dwValue6, dwValue7, dwValue8)
			elseif tData.nDataType == LAND_OBJECT_TYPE.SD_TWO_DWORD_SCRIPT then
				pHlMgr.CallSDTwoDwordScript(tbFurniture.nInstanceID, tData.nDataPos, dwValue1, dwValue2, dwValue3, dwValue4, dwValue5, dwValue6, dwValue7, dwValue8)
			elseif tData.nDataType == LAND_OBJECT_TYPE.FOUR_DWORD_SCRIPT then
				pHlMgr.CallFourDwordScript(tbFurniture.nInstanceID, tData.nDataPos, dwValue1, dwValue2, dwValue3, dwValue4, dwValue5, dwValue6, dwValue7, dwValue8)
			end
		end

		if IsSeedingGame(tData.nGameID) and nGameState > 1 and nGameState < 6 then
			_doGameProtocol()	-- 种植的照料事件放一起
		elseif nGameState == tData.nGameState then
			_doGameProtocol()
		end

		nIndex = nIndex + 1
		if nIndex > nCount then
			Timer.DelTimer(self, self.AutoTimerID)
			self.AutoTimerID = nil
		end
	end)

	if bClose then
		UIMgr.Close(VIEW_ID.PanelHomeInteract)
	end
end
HouseKeeperData = HouseKeeperData or {}
local self = HouseKeeperData

local m_tData = {}
local REMOTE_CALL_INTERVAL = 1000 --单位，ms

function HouseKeeperData.OnInit(tHouseKeeperData)
    local tDataFromTable = Table_GetTableHouseKeeper()
	local tSingleDataFromTable = tDataFromTable[tHouseKeeperData.ServantID] or tDataFromTable[0]
	local tMergedData = HouseKeeperData.MergeHouseKeeperData(tHouseKeeperData, tSingleDataFromTable)
	HouseKeeperData.SetHouseKeeperData(tMergedData)

	HouseKeeperData.ProcessHouseKeeperData()
end

function HouseKeeperData.UnInit()

end

function HouseKeeperData.Reset()

end

function HouseKeeperData.RemoteCall(szName, ...)
	if not m_tData.tRemoteCallLastCalled then
		m_tData.tRemoteCallLastCalled  = {}
	end

	local nCurStamp = GetTickCount()
	if m_tData.tRemoteCallLastCalled[szName] then
		if nCurStamp - m_tData.tRemoteCallLastCalled[szName] < REMOTE_CALL_INTERVAL then
			OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.szTooOften)
			return
		end
	end
	m_tData.tRemoteCallLastCalled[szName] = nCurStamp

	RemoteCallToServer(szName, ...)
end

function HouseKeeperData.GetHouseKeeperData()
	return m_tData.tHouseKeeperData
end

function HouseKeeperData.SetHouseKeeperData(tConfig)
	m_tData.tHouseKeeperData = tConfig
end

function HouseKeeperData.GetFrame()
	return m_tData.hFrame
end

function HouseKeeperData.GetSkillData()
	if not m_tData.tSkillData then
		HouseKeeperData.SetSkillData(Table_GetTableHouseKeeperSkill())
	end
	return m_tData.tSkillData
end

function HouseKeeperData.SetSkillData(tSkillData)
	m_tData.tSkillData = tSkillData
end

function HouseKeeperData.ProcessHouseKeeperData()
	local tHouseKeeperData = HouseKeeperData.GetHouseKeeperData()
	local tAvatarFrame = {}
	if tHouseKeeperData.szAvatarFrame then
		tAvatarFrame = SplitString(tHouseKeeperData.szAvatarFrame, ";")
	end

	tHouseKeeperData.tAvatarFrame = tAvatarFrame
end

function HouseKeeperData.MergeHouseKeeperData(tHouseKeeperData, tDataBeMerged)
	for k,v in pairs(tDataBeMerged) do
		tHouseKeeperData[k] = v
	end
	return tHouseKeeperData
end

function HouseKeeperData.InitData(tHouseKeeperData)
	local tDataFromTable = Table_GetTableHouseKeeper()
	local tSingleDataFromTable = tDataFromTable[tHouseKeeperData.ServantID] or tDataFromTable[0]
	local tMergedData = HouseKeeperData.MergeHouseKeeperData(tHouseKeeperData, tSingleDataFromTable)
	HouseKeeperData.SetHouseKeeperData(tMergedData)

	HouseKeeperData.ProcessHouseKeeperData()

end

function HouseKeeperData.IsUICanBeOperated()
	local tHKData = HouseKeeperData.GetHouseKeeperData()
	local bRet = false
	if tHKData and tHKData.bEditable then
		bRet = true
	end
	return bRet
end

function HouseKeeperData.SetSkillIDInBox(hBox, nSkillID)
	hBox.nSkillID = nSkillID
end

function HouseKeeperData.GetSkillIDInBox(hBox)
	return hBox.nSkillID
end

function HouseKeeperData.LoadableSkill2ItemInfo(tLoadableSkill)
	local tItemType, tItemIndex = {}, {}
	local tAllSkillInfo = HouseKeeperData.GetSkillData()

	for _, tInfo in ipairs(tLoadableSkill) do
		local szBoxInfo = tAllSkillInfo[tInfo[1]].szBoxInfo
		local tBoxInfo = SplitString(szBoxInfo, "_")
		local nType = tonumber(tBoxInfo[1])
		local nIndex = tonumber(tBoxInfo[2])
		table.insert(tItemType, nType)
		table.insert(tItemIndex, nIndex)
	end

	return tItemType, tItemIndex
end

function HouseKeeperData.GetSMPopMenuConfigOfSmallBag()
	local tHKData = HouseKeeperData.GetHouseKeeperData()
	local nHKDataServantID = tHKData.ServantID

	local tPopupmenuConfig = {
		{
			szOption = g_tStrings.tToturTitle.Equip,
			fnAction = function(tChoiceInfo)
				local nSkillID = HouseKeeper.GetSkillIDByItemInfo(tChoiceInfo.hBox.dwType, tChoiceInfo.hBox.dwIndex)

				if HouseKeeperData.GetOldSkillIDInReplace() then
					local nSkillIDBeReplaced = HouseKeeperData.GetOldSkillIDInReplace()
					HouseKeeperData.SetOldSkillIDInReplace(nil)
					HouseKeeperData.RemoteCall("On_NPCServant_SwitchSkill", tChoiceInfo.nServantID, nSkillIDBeReplaced, nSkillID)
				else
					HouseKeeperData.RemoteCall("On_NPCServant_LoadSkill", tChoiceInfo.nServantID, nSkillID)
				end

				SmallBagPanel.Close()
			end,
			nServantID = nHKDataServantID,
		},
	}

	local tUpgradeMenuChoice = HouseKeeperData.GetUpgradeSkillConfigOfSMPopupMenu()
	table.insert(tPopupmenuConfig, tUpgradeMenuChoice)

	return tPopupmenuConfig
end

function HouseKeeperData.ConstructSmallBagCofig()
	local tHKData = HouseKeeperData.GetHouseKeeperData()
	local tLoadableSkill = tHKData.tLoadableSkill

	local tItemType, tItemIndex = HouseKeeperData.LoadableSkill2ItemInfo(tLoadableSkill)
	local tMenuChoice = HouseKeeperData.GetSMPopMenuConfigOfSmallBag()
	local tBag = {
        tItemIndex  = tItemIndex,
        tItemType   = tItemType,
        szTitle     = g_tStrings.szPleaseLoadSkill,       -- 操作提示
        tMenuChoice = tMenuChoice,      -- 弹出菜单操作项
    }

	return tBag
end

function HouseKeeperData.GetUpgradeSkillConfigOfSMPopupMenu(hBox)
	local tHKData = HouseKeeperData.GetHouseKeeperData()
	local nHKDataServantID = tHKData.ServantID
	local tMenuChoice = {
		szOption = g_tStrings.szUpgrade,
		fnAction = function(tChoiceInfo)
			local nSkillID = HouseKeeperData.GetSkillIDInBox(tChoiceInfo.hBox)
			if not nSkillID then
				nSkillID = HouseKeeper.GetSkillIDByItemInfo(tChoiceInfo.hBox.dwType, tChoiceInfo.hBox.dwIndex)
			end

			HouseKeeperData.RemoteCall("On_NPCServant_LevelUpSkill", tChoiceInfo.nServantID, nSkillID)
		end,
		nServantID = nHKDataServantID
	}
	if hBox then
		tMenuChoice.hBox = hBox
	end

	return tMenuChoice
end

function HouseKeeperData.GetUseSkillConfigOfSMPopupMenu(hBox)
	local tHKData = HouseKeeperData.GetHouseKeeperData()
	local nHKDataServantID = tHKData.ServantID

	local tMenuChoice = {
		szOption = g_tStrings.USE,
		fnAction = function(tChoiceInfo)
			local nSkillID = HouseKeeperData.GetSkillIDInBox(hBox)
			HouseKeeperData.RemoteCall("On_NPCServant_UseSkill", tChoiceInfo.nServantID, nSkillID)
		end,
		nServantID = nHKDataServantID,
	}
	return tMenuChoice
end

function HouseKeeperData.SetOldSkillIDInReplace(nSkillID)
	m_tData.nOldSkillIDInReplace = nSkillID
end

function HouseKeeperData.GetOldSkillIDInReplace()
	return m_tData.nOldSkillIDInReplace
end

--格式为{1,0}, --技能ID，技能等级
function HouseKeeperData.RemoveFromLoadableSkill(tOldSkillInfo)
	local tHKData = HouseKeeperData.GetHouseKeeperData()
	local tLoadableSkill = tHKData.tLoadableSkill
	local nIndex = nil
	for k, tSkillInfo in ipairs(tLoadableSkill) do
		if tSkillInfo[1] == tOldSkillInfo[1] then
			nIndex = k
			break
		end
	end

	if nIndex then
		table.remove(tLoadableSkill, nIndex)
	end
end

function HouseKeeperData.Add2LoadableSkill(tNewSkillInfo)
	local tHKData = HouseKeeperData.GetHouseKeeperData()
	local tLoadableSkill = tHKData.tLoadableSkill

	table.insert(tLoadableSkill, tNewSkillInfo)
end

function HouseKeeperData.GetMaxLevelOfHK()
	return #g_tStrings.tHouseKeeperLevel
end

function HouseKeeperData.GetCurrentServantID()
	local tHKData = HouseKeeperData.GetHouseKeeperData()
	if not tHKData then
		return nil
	end
	return tHKData.ServantID
end

function HouseKeeperData.RemoteCallCheckThenAction(ServantID, bSuccess)
	local bRet = false
	if bSuccess then
		local nCurrentServantID = HouseKeeperData.GetCurrentServantID()
		if nCurrentServantID and nCurrentServantID == ServantID then
			bRet = true
		end
	end
	return bRet
end

local function TraverseAndUpdateSkillLevel(tSkill, nSkillID, nNewLevel)
	for k, tSkillInfo in ipairs(tSkill) do
		if tSkillInfo[1] == nSkillID then
			tSkillInfo[2] = nNewLevel
			return true
		end
	end
	return false
end
-- tCurrentSkill = {{1,0},{2,1}},--当前装备的几个技能的数据。“当前装备技能数”由这个表大小决定。单个技能数据表的参数依次是：技能ID，技能等级
-- 	tStaticSkill = {{{1,0},{2,1}},--常驻技能表，所有格式与tCurrentSkill 一致。
-- 	tLoadableSkill={{{1,0},{2,1}} 管家可装备技能表 ,所有格式与tCurrentSkill 一致。
function HouseKeeperData.UpdateLevelBySkillID(nSkillID, nNewLevel)
	local tHKData = HouseKeeperData.GetHouseKeeperData()
	local bRet = false

	local tCurrentSkill = tHKData.tCurrentSkill
	local tStaticSkill = tHKData.tStaticSkill
	local tLoadableSkill = tHKData.tLoadableSkill
	bRet = TraverseAndUpdateSkillLevel(tCurrentSkill, nSkillID, nNewLevel)
	if bRet then
		Event.Dispatch(EventType.OnUpdateHouseKeeperData)
		return
	end

	bRet = TraverseAndUpdateSkillLevel(tStaticSkill, nSkillID, nNewLevel)
	if bRet then
		Event.Dispatch(EventType.OnUpdateHouseKeeperData)
		return
	end
	TraverseAndUpdateSkillLevel(tLoadableSkill, nSkillID, nNewLevel)
end

function HouseKeeperData.UnloadSkillBySkillID(nSkillID)
	local tHKData = HouseKeeperData.GetHouseKeeperData()
	local nIndex = 0

	local tCurrentSkill = tHKData.tCurrentSkill
	for k, tSkillInfo in ipairs(tCurrentSkill) do
		if tSkillInfo[1] == nSkillID then
			nIndex = k
			break
		end
	end
	HouseKeeperData.Add2LoadableSkill(tCurrentSkill[nIndex])
	table.remove(tCurrentSkill, nIndex)

	Event.Dispatch(EventType.OnUpdateHouseKeeperData)
	return nIndex
end

function HouseKeeperData.LoadSkillBySkillID(nSkillID, nSkillIndex)
	local tHKData = HouseKeeperData.GetHouseKeeperData()
	local tNewSkill
	local tLoadable = tHKData.tLoadableSkill
	for k, tSkillInfo in ipairs(tLoadable) do
		if tSkillInfo[1] == nSkillID then
			tNewSkill = tSkillInfo
			break
		end
	end
	HouseKeeperData.RemoveFromLoadableSkill(tNewSkill)

	if tNewSkill then
		if nSkillIndex then
			table.insert(tHKData.tCurrentSkill, nSkillIndex, tNewSkill)
		else
			table.insert(tHKData.tCurrentSkill, tNewSkill)
		end

		Event.Dispatch(EventType.OnUpdateHouseKeeperData)
	end
end

function HouseKeeperData.ReplaceSkillBySkillID(nOldSkillID, nNewSkillID)
	local nSkillIndex = HouseKeeperData.UnloadSkillBySkillID(nOldSkillID)
	HouseKeeperData.LoadSkillBySkillID(nNewSkillID, nSkillIndex)
end

function HouseKeeperData.ResetTalentBySkillID(nSkillID)
	local tHKData = HouseKeeperData.GetHouseKeeperData()
	tHKData.GiftSkillID = nSkillID

	Event.Dispatch(EventType.OnUpdateHouseKeeperData)
end

function HouseKeeperData.GetSkillIDByItemInfo(dwTabType, dwIndex)
	local nSkillID = 0
	local szBoxString = dwTabType .. "_" .. dwIndex
	local tAllSkillData = HouseKeeperData.GetSkillData()
	for k, tSingleSkillData in pairs(tAllSkillData) do
		if szBoxString == tSingleSkillData.szBoxInfo then
			nSkillID = tSingleSkillData.dwID
			break
		end
	end
	return nSkillID
end

function HouseKeeperData.UpgradeServant(tUpdatedServantData)
	local tHouseKeeperData = HouseKeeperData.GetHouseKeeperData()
	local tMergedData = HouseKeeperData.MergeHouseKeeperData(tHouseKeeperData, tUpdatedServantData)
	HouseKeeperData.SetHouseKeeperData(tMergedData)

	Event.Dispatch(EventType.OnUpdateHouseKeeperData)
	-- View.PlayUpgradeSFX(hFrame)
end
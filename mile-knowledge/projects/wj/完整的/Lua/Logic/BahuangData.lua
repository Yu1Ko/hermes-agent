-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: BahuangData
-- Date: 2024-01-01 19:14:48
-- Desc: ?
-- ---------------------------------------------------------------------------------

BahuangData = BahuangData or {className = "BahuangData"}
local self = BahuangData
-------------------------------- 消息定义 --------------------------------
BahuangData.Event = {}
BahuangData.Event.XXX = "BahuangData.Msg.XXX"
BahuangData.nBahuangIDMap = 995
local REMOTE_EIGHTWASTESLASTRECORD = 1145
local ROUGE_BELONGKUNGFU_ID = 64291
local tbSkillNum = {
    [1] = 1, --心决
    [2] = 4, --秘技
    [3] = 1, --绝学
    [4] = 6, --秘术
}
local _FPS = 0

function BahuangData.Init()
    self._initData()
    self._registerEvent()
end

function BahuangData.UnInit()

end

function BahuangData.OnLogin()

end

function BahuangData.OnFirstLoadEnd()

end

function BahuangData.GetMaxSceneLevel()
    local hPlayer = g_pClientPlayer
	if not hPlayer then
		return
	end

	if IsRemotePlayer(hPlayer.dwID) then
		return
	end

	local tData = GDAPI_GetEightWastesPlayerData(hPlayer)
	local nSceneLevel = tData.nSceneLevel

	return nSceneLevel > 0 and nSceneLevel or 1
end

function BahuangData.GetActiveSkillRemoteData()
    -- if self.tbActiveSkillRemoteData then
    --     return self.tbActiveSkillRemoteData
    -- end
    self.tbActiveSkillRemoteData = self._getActiveSkillRemoteDataByType("Active")--数据可能会变动，不能缓存
    return self.tbActiveSkillRemoteData
end

function BahuangData.GetPassiveSkillRemoteData()
    -- if self.tbPassiveSkillRemoteData then
    --     return self.tbPassiveSkillRemoteData
    -- end
    self.tbPassiveSkillRemoteData = self._getActiveSkillRemoteDataByType("Passive")--数据可能会变动，不能缓存
    return self.tbPassiveSkillRemoteData
end

function BahuangData.GetUltimateSkillRemoteData()
    -- if self.tbUltimateSkillRemoteData then
    --     return self.tbUltimateSkillRemoteData
    -- end
    self.tbUltimateSkillRemoteData = self._getActiveSkillRemoteDataByType("Finisher")--数据可能会变动，不能缓存
    return self.tbUltimateSkillRemoteData
end

function BahuangData.GetExpProgressData()

    local hPlayer = g_pClientPlayer
    if not hPlayer then
        return {}
    end

    if IsRemotePlayer(hPlayer.dwID) then
		return {}
	end

    tbExpData = {}
    local tData = GDAPI_GetEightWastesPlayerData(hPlayer)
    tbExpData.nLevel = tData.nLevel
    tbExpData.nMaxLevel = tData.nMaxLevel
    tbExpData.nExp = tData.nExp
    tbExpData.nMaxExp = tData.nMaxExp

    return tbExpData
end

function BahuangData.GetExpLevelAwardInfo()
    local tbLevelList = GetEightWastesRemoteConfig().tLevelList
    return tbLevelList
end

function BahuangData.GetLevelBuffID()
    local nBuffID = GetEightWastesRemoteConfig().nBuffID
    return nBuffID
end

function BahuangData.GetTotalDataInfo()

    local hPlayer = g_pClientPlayer
    if not hPlayer then
        return {}
    end

    if IsRemotePlayer(hPlayer.dwID) then
		return {}
	end

    local tbTotalData = {}
    local dwSkillID = GetEightWastesPlayerInitSKill(hPlayer)
    local dwKungfuID = hPlayer.GetKungfuMountID()
    tbTotalData.tInitSkill = {dwSkillID = dwSkillID, dwLevel = 1}
    tbTotalData.dwForceID = hPlayer.dwForceID

    local tData = GDAPI_GetEightWastesPlayerData(hPlayer)

    tbTotalData.nPlayNum = tData.nPlayNum
    tbTotalData.nSoloClear = tData.nSoloClear
    tbTotalData.nTeamClear = tData.nTeamClear
    tbTotalData.nKillNum = tData.nKillNum
    tbTotalData.nBossNum = tData.nBossNum
    tbTotalData.nAltarNum = tData.nAltarNum
    tbTotalData.nGainNum = tData.nGainNum
    tbTotalData.nSceneChest = tData.nSceneChest

    return tbTotalData
end

function BahuangData.GetPointAccrue()
    return GetEightWastesPointAccrue()
end

function BahuangData.GetCurrentCommonAwardLevel()
    local hPlayer = g_pClientPlayer
	if not hPlayer then
		return
	end
    local tbPointAccrue = GetEightWastesPointAccrue()
    local tbEightWastesRemoteIndex = GetEightWastesPlayerRemoteIndex()
    local nPoint = hPlayer.GetRemoteArrayUInt(REMOTE_EIGHTWASTESLASTRECORD, tbEightWastesRemoteIndex.nPointAccrue[1], tbEightWastesRemoteIndex.nPointAccrue[2])

    local nCurrentLevel = 0
	for i = 1, #tbPointAccrue.tPoint do
		if nPoint >= tbPointAccrue.tPoint[i] then
			nCurrentLevel = i
		end
	end
    return nCurrentLevel
end

function BahuangData.GetCommonAwardList()
    local tbAwardItemList = GetEightWastesAwardItemList()
	return tbAwardItemList[1]
end

function BahuangData.GetNPCNameVisibleList()
    if self.tbNPCNameVisibleList then
        return self.tbNPCNameVisibleList
    end
    self.tbNPCNameVisibleList = Table_GetNPCNameVisibleList(BahuangData.nBahuangIDMap)
    return self.tbNPCNameVisibleList
end

function BahuangData.GetNPCNameVisibleListByType(nType)
    local tbNPCNameVisibleList = self.GetNPCNameVisibleList()
    local tbList = tbNPCNameVisibleList[nType]
    if tbList then
        local tbRes = {}
        for nIndex, tbInfo in ipairs(tbList) do
            if not tbSettingList then tbSettingList = {} end
            local tbSettingInfo = {}
            tbSettingInfo.funcSetting = function(bSelect)
                self.ChangeNPCNameState(tbInfo.dwTemplateID, bSelect)
            end
            tbSettingInfo.szName = UIHelper.GBKToUTF8(Table_GetSkillName(tbInfo.nSkillID, 1))
            tbSettingInfo.bVisible = Storage.BaHuang.tbNpcNameSetting[tbInfo.dwTemplateID]
            table.insert(tbSettingList, tbSettingInfo)
            if nIndex % 4 == 0 or nIndex == #tbList then
                table.insert(tbRes, tbSettingList)
                tbSettingList = nil
            end
        end
        return tbRes
    end
    return nil
end

function BahuangData.IsNpcNameSettingListEmpty()
    local bEmpty = true
    for dwTemplateID, bVisible in pairs(Storage.BaHuang.tbNpcNameSetting) do
        bEmpty = false
        break
    end
    return bEmpty
end

function BahuangData.OnLoadingEnd()

    if self.IsNpcNameSettingListEmpty() then --还没有存储数据时加载默认的数据
        local tbNpcNameList = self.GetNPCNameVisibleList()
        if not tbNpcNameList then
            return
        end

        for _,tList in pairs(tbNpcNameList) do
            for _,tInfo in pairs(tList) do
                Storage.BaHuang.tbNpcNameSetting[tInfo.dwTemplateID] = tInfo.bDefaultVisible
            end
        end
        Storage.BaHuang.Dirty()
    end
    self._updateChangeNPCNameState()
end

function BahuangData.ChangeNPCNameState(dwTemplateID, bShow)

    local bShowNow = Storage.BaHuang.tbNpcNameSetting[dwTemplateID]
    if bShowNow and bShowNow == bShow then return end

    Storage.BaHuang.tbNpcNameSetting[dwTemplateID] = bShow
    Storage.BaHuang.Dirty()
    self._updateChangeNPCNameState()
end


function BahuangData.GetBangSkillListByIndex(nIndex)
    return self.tbBankList and self.tbBankList[nIndex] or nil
end

function BahuangData.GetBangSkillListLength()
    return self.tbBankList and #self.tbBankList or 0
end

function BahuangData.GetSkillList()
    return self.tbSkillList
end

function BahuangData.GetSkillByTypeAndIndex(nType, nIndex)
    if not self.tbSkillList then return end
    if not self.tbSkillList[nType] then return end
    return self.tbSkillList[nType][nIndex]
end

function BahuangData._clearBahuangSkillList()
    self.tbSkillList = {}
    self.tbBankList = {}
end

function BahuangData.OnGetSkillList(tbSkillList)
    self._updateBankSkillList(tbSkillList)
    self._updateSkillList(tbSkillList)
    Event.Dispatch(EventType.OnGetSkillList)
end

--是否在八荒地图中
function BahuangData.IsInBaHuangMap()
    if not g_pClientPlayer then return false end
    local scene = g_pClientPlayer.GetScene()
    return scene.dwMapID == BahuangData.nBahuangIDMap
end

function BahuangData.StartShowTip(nTime)
    if nTime ~= nil then

        local function PlayTip(nTime)
            local szText = g_tStrings.MSG_INSTANCES_BANISH1 .. tostring(nTime) .. g_tStrings.MSG_INSTANCES_BANISH2
            TipsHelper.ShowNormalTip(szText)
        end
        
        self.StopShowTip()

        PlayTip(nTime)
        self.nTipTimer = Timer.AddCycle(self, 3, function()
            nTime = nTime - 3
            if nTime < 0 then
                self.StopShowTip()
                return
            end
            PlayTip(nTime)
        end)
    end
end

function BahuangData.StopShowTip()
    if self.nTipTimer then
        Timer.DelTimer(self, self.nTipTimer)
        self.nTipTimer = nil
    end
end

function BahuangData.SetAutoCast(nIndex, bAuto)
    Storage.BaHuang.tbAutoCastList[nIndex] = bAuto
    Storage.BaHuang.Dirty()
end

function BahuangData.IsAutoCast(nIndex)
    return Storage.BaHuang.tbAutoCastList[nIndex] and Storage.BaHuang.tbAutoCastList[nIndex] == true
end

function BahuangData.SetAutoCastAllSkill(bAutoCastAllSkill)
    Storage.BaHuang.bAutoCastAllSkill = bAutoCastAllSkill
    Storage.BaHuang.Dirty()
end

function BahuangData.IsAutoCastAllSkill()
    return Storage.BaHuang.bAutoCastAllSkill 
end

function BahuangData.DeleteSkill(nType, nSkillID, bShowConfirm)
    if bShowConfirm then
        local script = UIHelper.ShowConfirm("你确定丢弃此技能吗？", function(bShowDropConfirm)
            RemoteCallToServer("On_EightWastes_ForgetSkill", nSkillID, nType, true)
            BahuangData.SetShowDropConfirm(not bShowDropConfirm)
        end, function(bShowDropConfirm)
            BahuangData.SetShowDropConfirm(not bShowDropConfirm)
        end)
        script:ShowTogOption("下次不再提示", not self.bShowDropConfirm)
        script:SetTogSelectedFunc(function(bSelected)
            self.SetShowDropConfirm(not bSelected)
        end)
    else
        RemoteCallToServer("On_EightWastes_ForgetSkill", nSkillID, nType, true)
    end
end

function BahuangData.GetSkillInfoByIndex(nIndex)
    if nIndex == 1 then return self.GetSkillByTypeAndIndex(1, 1) end
    if nIndex >= 2 and nIndex <= 5 then return self.GetSkillByTypeAndIndex(2, nIndex - 1) end
    if nIndex == 6 then return self.GetSkillByTypeAndIndex(3, 1) end
    return nil
end

function BahuangData.EnterBahuangDynamic()
    self.IsInBahuang = true
    self.StartTimer()
    SprintData.SetViewState(false, true)
    self.SetShowRedPoint(true)
    Event.Dispatch(EventType.OnEnterBahuangDynamic)
end

function BahuangData.ExitBahuangDynamic()
    self.IsInBahuang = false
    self.ClearBattleInfoList()
    -- self.ClearSkillTip()
    self.StopTimer()
    SprintData.SetViewState(true, true)
    Event.Dispatch(EventType.OnLeaveBahuangDynamic)
end

function BahuangData.IsInBahuangDynamic()
    if not self.IsInBahuang then return false end
    return self.IsInBahuang
end

--自动释放技能tip太频繁，因此这里控制一下，防止排队的tip太多到八荒外还在弹
function BahuangData.AddSkillTip(szMsg)
    if not self.nTipCount then self.nTipCount = 0 end
    if self.nTipCount > 0  then
        self.AddSkillTipToCache(szMsg)
        return 
    end
    self.ShowSkillTip(szMsg)
end

function BahuangData.AddSkillTipToCache(szMsg)
    if not self.tbSkillTip then self.tbSkillTip = {} end
    table.insert(self.tbSkillTip, szMsg)
end


function BahuangData.ShowSkillTip(szMsg)
    self.nTipCount = self.nTipCount + 1
    TipsHelper.ShowNormalTip(szMsg, false, function()
        self.nTipCount = self.nTipCount - 1
        if self.tbSkillTip and #self.tbSkillTip > 0 then
            local szMsg = table.remove(self.tbSkillTip, 1)
            self.ShowSkillTip(szMsg)
        end
    end)
end

function BahuangData.ClearSkillTip()
    self.tbSkillTip = {}
end

function BahuangData.StartTimer()
    self.StopTimer()
    self.nTimer = Timer.AddFrameCycle(self, 3, function()
        self._onTimer()
    end)
end

function BahuangData.StopTimer()
    if self.nTimer then
        Timer.DelTimer(self, self.nTimer)
        self.nTimer = nil
    end
end

function BahuangData.GetSkillTypeAndIndexBySkillInfo(tbSKillInfo)
    for nType, tbSKillList in pairs(self.tbSkillList) do
        for nIndex, tbSKill in ipairs(tbSKillList) do
            if tbSKill == tbSKillInfo then
                return nType, nIndex
            end
        end
    end
    return nil, nil
end

function BahuangData.SetEnableBreakFirstSkill(bEnableBreakFirstSkill)
    Storage.BaHuang.bEnableBreakFirstSkill = bEnableBreakFirstSkill
    Storage.BaHuang.Dirty()
end

function BahuangData.IsEnableBreakFirstSkill()
    return Storage.BaHuang.bEnableBreakFirstSkill
end

function BahuangData.SetHideSkillText(bHideSkillText)
    Storage.BaHuang.bHideSkillText = bHideSkillText
    Storage.BaHuang.Dirty()
end

function BahuangData.IsHideSkillText()
    return Storage.BaHuang.bHideSkillText
end

function BahuangData.IsSchoolSkill(dwSkillID, dwLevel)
	local tSkill = GetSkill(dwSkillID, dwLevel)
	local bSchoolSkill = tSkill and tSkill.dwBelongKungfu == ROUGE_BELONGKUNGFU_ID
	return bSchoolSkill
end


function BahuangData.CheckBreakFirstPrepareSkill(dwSkillID, dwSkillLevel)
    local bEnableBreakFirstSkill = Storage.BaHuang.bEnableBreakFirstSkill
	local tbPrepareSkill = TipsHelper.GetProgressBarSkillInfo()
	if not tbPrepareSkill then
		return true
	end

	local bShcoolSkill = self.IsSchoolSkill(dwSkillID, dwSkillLevel)
	local bPrepareSchoolSkill = self.IsSchoolSkill(tbPrepareSkill.dwSkillID, tbPrepareSkill.dwSkillLevel)

	if bPrepareSchoolSkill and bEnableBreakFirstSkill and not bShcoolSkill then
		return true
	end

	return false
end



function BahuangData.ExChangeSkill(script1, script2, nIndex1, nIndex2)

    if not self.CheckIsSameTypeBySlot(nIndex1, nIndex2) then
        TipsHelper.ShowNormalTip("交换的技能需是同一类型")
        return false
    end
 
    local tbSKillInfo1 = script1:GetSkillInfo()
    local tbSKillInfo2 = script2:GetSkillInfo()
    if not tbSKillInfo1 and not tbSKillInfo2 then
        return false
    end

    local nType1, nIndex1 = self.ConvertToTypeAndIndex(nIndex1)
    local nType2, nIndex2 = self.ConvertToTypeAndIndex(nIndex2)
    self.tbSkillList[nType1][nIndex1] = tbSKillInfo2
    self.tbLastSkillList[nType1][nIndex1] = tbSKillInfo2

    self.tbSkillList[nType2][nIndex2] = tbSKillInfo1
    self.tbLastSkillList[nType2][nIndex2] = tbSKillInfo1

    Event.Dispatch(EventType.OnExChangeBahuangSkill)
    return true
end

function BahuangData.CheckIsSameTypeBySlot(nIndex1, nIndex2)
    if nIndex1 == 1 or nIndex1 == 6 or nIndex2 == 1 or nIndex2 == 6 then
        return false
    end 
    return true
end

function BahuangData.IsShowRedPoint()
    if not self.bShowRedPoint then return false end
    return self.bShowRedPoint
end

function BahuangData.SetShowRedPoint(bShowRedPoint)
    self.bShowRedPoint = bShowRedPoint
    Event.Dispatch(EventType.SetBaHuangSkillRedPoint)
end

function BahuangData.ConvertToTypeAndIndex(nIndex)
    if nIndex == 1 then return 1, 1 end
    if nIndex == 6 then return 3, 1 end
    return 2, nIndex - 1
end

function BahuangData.OnLearnSkill(nType, nSkillID)
    if not nType or not nSkillID or nType < 4 then
		return
	end

	local nLearnCount = 0
	local tList = self.tbSkillList[4]
	if tList then
		nLearnCount = #tList
	end

	if nType == 5 and nLearnCount >= tbSkillNum[4] then
		OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_ROUGE_LEARN_SKILL_ERROR_TIP)
		return
	end

	if nType == 4 then
		RemoteCallToServer("On_EightWastes_ForgetSkill", nSkillID, nType, false)
	elseif nType == 5 then
		RemoteCallToServer("On_EightWastes_LearnSkill", nSkillID, nType)
	end
end

function BahuangData.UpdateBattleInfoList(szInfoType, tbInfo)
    if not self.tbBattleInfo then self.tbBattleInfo = {} end
    if not self.tbBattleInfo[szInfoType] then self.tbBattleInfo[szInfoType] = {} end
    self.tbBattleInfo[szInfoType] = tbInfo
    Event.Dispatch(EventType.OnUpdateBattleInfoList, szInfoType)
end

function BahuangData.ClearBattleInfoList()
    self.tbBattleInfo = {}
    Event.Dispatch(EventType.OnClearBattleInfo)
end

function BahuangData.OnLastGameDataUpdate(tbData)
    tbData.nPlayerNum = tbData.nPlayerNum or 1
    self.tbLastData = tbData
    local tSkillList = {}
    for _, tInfo in ipairs(tbData.tSkillList) do
        if not tSkillList[tInfo[3]] then
            tSkillList[tInfo[3]] = {}
        end

        table.insert(tSkillList[tInfo[3]], {dwSkillID = tInfo[1], nSkillLevel = tInfo[2]})
    end

    self.tbLastSkillList = tSkillList

    Event.Dispatch(EventType.OnLastGameDataUpdate)
end

function BahuangData.GetLastGameData()
    return self.tbLastData
end

function BahuangData.IsNeverPlayedGame()
    if self.tbLastData then
        return self.tbLastData.nPassTime == 0
    end
    return true
end

function BahuangData.GetLastSkillList()
    return self.tbLastSkillList
end


function BahuangData.GetBattleInfoByType(szInfoType)
    return self.tbBattleInfo and self.tbBattleInfo[szInfoType] or nil
end

function BahuangData.IsShowDropConfirm()
    return self.bShowDropConfirm
end

function BahuangData.SetShowDropConfirm(bShowDropConfirm)
    self.bShowDropConfirm = bShowDropConfirm
end

function BahuangData._updateBankSkillList(tbSkillList)
    if not g_pClientPlayer then return end
    self.tbBankList = {}
    for _,v in ipairs(tbSkillList) do
		v.nType = v.nKungIDIndex

		if v.nType >= 4 then
			local nLevel = g_pClientPlayer.GetSkillLevel(v.dwSkillID)
			if not nLevel or nLevel == 0 then
				v.nType = 5
			else
				v.nType = 4
			end
			table.insert(self.tbBankList,v)

            --教学 获得八荒技能
            FireHelpEvent("OnAddBaHuangSkill", v.dwSkillID, v.nType)
		end
    end
end

function BahuangData._updateSkillList(tbSkillList)
    if not g_pClientPlayer then return end
    self.tbSkillList = {}
    local tSkillList = {}
    for _,v in ipairs(tbSkillList) do
        v.nSkillID = v.dwSkillID
		v.nType = v.nKungIDIndex

		if v.nType >= 4 then
			local nLevel = g_pClientPlayer.GetSkillLevel(v.dwSkillID)
			if not nLevel or nLevel == 0 then
				v.nType = 5
			else
				v.nType = 4
			end
		end

        if not self.tbSkillList[v.nType] then self.tbSkillList[v.nType] = {} end

        local bHave = false
		if v.nType < 4 then
            if not self.tbLastSkillList then self.tbLastSkillList = {} end
			if not self.tbLastSkillList[v.nType] then
				self.tbLastSkillList[v.nType] = {}
			end

			for i,tLast in pairs(self.tbLastSkillList[v.nType]) do
				if tLast.dwSkillID == v.dwSkillID then
					self.tbSkillList[v.nType][i] = v
					self.tbLastSkillList[v.nType][i] = v
					bHave = true
					break
				end
			end

			if not tSkillList[v.nType] then
				tSkillList[v.nType] = {}
			end

			if not bHave then
				table.insert(tSkillList[v.nType],v)
			end
		else
			table.insert(self.tbSkillList[v.nType],v)
            
            --教学 获得八荒技能
            FireHelpEvent("OnAddBaHuangSkill", v.dwSkillID, v.nType)
		end

    end


    for nType = 1, #tbSkillNum - 1 do
		for nIndex = 1, tbSkillNum[nType] do
			local tInfo = tSkillList[nType] and tSkillList[nType][1] or nil
			if not tInfo then
				break
			end

			if not self.tbSkillList[nType][nIndex] then
				self.tbSkillList[nType][nIndex] = tInfo
				self.tbLastSkillList[nType][nIndex] = tInfo
				table.remove(tSkillList[nType],1)

                --教学 获得八荒技能
                FireHelpEvent("OnAddBaHuangSkill", tInfo.dwSkillID, tInfo.nType)
			end
		end
	end


end



function BahuangData._getActiveSkillRemoteDataByType(szType)
    local hPlayer = g_pClientPlayer
    if not hPlayer then
        return
    end

    if IsRemotePlayer(hPlayer.dwID) then
		return
	end
    local tbResult = GDAPI_GetSkillRemoteData(hPlayer, szType)
    return tbResult
end


function BahuangData._updateChangeNPCNameState()
    local tSetting = {}
    for dwTemplateID, bVisible in pairs(Storage.BaHuang.tbNpcNameSetting) do
        if not bVisible then
            table.insert(tSetting, dwTemplateID)
        end
    end
    NPC_SetNameDisable(#tSetting, tSetting)
end

function BahuangData._initData()
    self.bShowDropConfirm = true
end

function BahuangData._registerEvent()
    Event.Reg(self, "FIRST_LOADING_END", function()
        self.OnLoadingEnd()
    end)
    Event.Reg(self, "LOADING_END", function()
        if not g_pClientPlayer then return end
        local scene = g_pClientPlayer.GetScene()
        if scene.dwMapID == BahuangData.nBahuangIDMap then
            self._updateChangeNPCNameState()--进入八荒时使npc名字显示相关设置生效，和端游在地图内设置有些不同
            RemoteCallToServer("On_EightWastes_GetReviveNum")
            RemoteCallToServer("On_EightWastes_GetLastTime")
            RemoteCallToServer("On_EightWastes_GetConfigList")
        else
            self._clearBahuangSkillList()
        end
    end)

    Event.Reg(self, "ON_SYNC_SCENE_TEMP_CUSTOM_DATA", function()
        if self.IsInBaHuangMap() then
            local tbKillCount = GDAPI_GetEightWastesKillData(g_pClientPlayer)
            self.UpdateBattleInfoList("nKillCount", tbKillCount.nKillCount)
            self.UpdateBattleInfoList("nKillBossNum", tbKillCount.nKillBossCount)
        end
    end)

    Event.Reg(self, "SYS_MSG", function(szMsg, nBanishCode, nBanishTime)
        if szMsg == "UI_OME_BANISH_PLAYER" then
			if not self.IsInBaHuangMap() then
				return
			end
            if nBanishCode ~= BANISH_CODE.CANCEL_BANISH then
                BahuangData.StartShowTip(nBanishTime)
            else
                BahuangData.StopShowTip()
            end
        end
    end)

end


function BahuangData._updateAutoCastSkill()
    if not g_pClientPlayer then return end
    _FPS = _FPS > 0 and _FPS - 1 or 0

    local tbAutoCastSkill = Storage.BaHuang.tbAutoCastList
    if Storage.BaHuang.bAutoCastAllSkill then
        tbAutoCastSkill = {true, true, true, true, true, true}
    end

    for nIndex = 6, 1, -1 do
        local tbSKillInfo = self.GetSkillInfoByIndex(nIndex)
        if tbSKillInfo then
            local nOldSkillID = tbSKillInfo.dwSkillID
            local nSkillID = GetMultiStageSkillCanCastID(tbSKillInfo.nSkillID)
            if nSkillID ~= nOldSkillID then
                tbSKillInfo.dwSkillID = nSkillID--dwsKillID：实际正在用的技能id，nSkillID：原始技能id
                Event.Dispatch(EventType.OnChangeMultiStageSkill, nOldSkillID, tbSKillInfo)
            end
        end
    end

    for nIndex = 6, 1, -1 do
        local bAutoCast = nIndex <= #tbAutoCastSkill and tbAutoCastSkill[nIndex] == true or false
        if bAutoCast then
            local tbSKillInfo = self.GetSkillInfoByIndex(nIndex)
            if tbSKillInfo then
                local dwSkillID = tbSKillInfo.dwSkillID
                local dwSkillLevel = tbSKillInfo.nSkillLevel
                local _, nLeft, nTotal, nCount, nMaxCount, bIsRecharge, bPublicCD = SkillData.GetSkillCDProcess(g_pClientPlayer,
                dwSkillID)
                local bCanBreak = self.CheckBreakFirstPrepareSkill(dwSkillID, dwSkillLevel)
                local bCanCast = false
                if not TipsHelper.IsProgressBarShow() then
                    bCanCast =  _FPS <= 0
                else
                    bCanCast = bCanBreak
                end
                if (not (nLeft and nLeft > 0)) and bCanCast then
                    local skill = GetSkill(dwSkillID, dwSkillLevel)
                    if skill and (skill.bHoardSkill or skill.bIsChannelSkill or skill.nPrepareFrames > 0) then
                        OnUseSkill(dwSkillID, dwSkillID * (dwSkillID % 10 + 1) , nil, true, nil, true)
                        _FPS = 2
                    else
                        OnUseSkill(dwSkillID, dwSkillID * (dwSkillID % 10 + 1) , nil, nil, nil, true)
                    end
                    if nIndex == 6 then
                        _FPS = 6--绝学
                    end
                end
            end
        end
    end


end

function BahuangData._onTimer()
    self._updateAutoCastSkill()
end

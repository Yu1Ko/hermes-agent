-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: ToyBoxData
-- Date: 2023-04-18 19:17:09
-- Desc: ?
-- ---------------------------------------------------------------------------------

ToyBoxData = ToyBoxData or {}
local self = ToyBoxData

self.tAddToy = nil
-------------------------------- 消息定义 --------------------------------
ToyBoxData.Event = {}
ToyBoxData.Event.XXX = "ToyBoxData.Msg.XXX"

--------------ToyType---------------------

self.TOY_TYPE = {
	NORMAL = 1,
	COUNT = 2,
	LEVEL = 3,
	COMPOSITE = 4,
}

self.tbActionToy = {}

Event.Reg(ToyBoxData, EventType.OnRoleLogin, function()
	ToyBoxData.ClearActionToyList()
end)

Event.Reg(ToyBoxData, EventType.OnClientPlayerEnter, function()
	Event.Dispatch(EventType.UpdateActionToySkillState)
end)

function ToyBoxData.Init()
	if self.bInit then
		return
	end
	self.bInit = true
    self.tToyBoxInfo = Table_GetToyBoxInfo()
    self.bSourceAll = true
    self.tSelectSource = {}
    self.bDLCAll = true
    self.tSelectDLC = {}
    self.tSourceFilter = {}
    self.bTypeAll = true
    self.tSelectType = {}
    self.tHaveFilter = {}
    self.nHaveNum = 0
    self.tDefaultAnchor = {}
    self.tDLCName = Table_GetDLCName()
    self.szChooseHave = g_tStrings.STR_TOYBOX_ALL

	local lst = self.tDLCName
	for i = 1, #lst do
		lst[i] = UIHelper.GBKToUTF8(lst[i])
	end
	FilterDef.ToyBox[2].tbList = lst

	local tHaveFilter =
	{
		g_tStrings.STR_TOYBOX_ALL,
		g_tStrings.STR_TOYBOX_HAVE,
		g_tStrings.STR_TOYBOX_NOT_HAVE,
	}
    self.tHaveFilter = tHaveFilter
    local tSourceFilter =
    {
        [g_tStrings.STR_TOYBOX_GETWAY] = {},
        [g_tStrings.STR_TOYBOX_DLC] = {},
        [g_tStrings.STR_TOYBOX_TYPE] = {},
    }

    for k, v in ipairs(g_tStrings.tToyBoxFilterName) do
        tSourceFilter[g_tStrings.STR_TOYBOX_GETWAY][k] = v
        self.tSelectSource[k] = true
    end
    for k, v in ipairs(self.tDLCName) do
		table.insert(tSourceFilter[g_tStrings.STR_TOYBOX_DLC], v)
		self.tSelectDLC[k] = true
	end
	for k, v in ipairs(g_tStrings.tToyBoxTypeName) do
		tSourceFilter[g_tStrings.STR_TOYBOX_TYPE][k] = v
		self.tSelectType[k] = true
	end
	self.tSourceFilter = tSourceFilter
end

function ToyBoxData.UnInit()
	self.bInit = nil
    self.tToyBoxInfo = nil
	self.bSourceAll = nil
	self.tSelectSource = nil
	self.bDLCAll = nil
	self.tSelectDLC = nil
	self.tSourceFilter = nil
	self.tHaveFilter = nil
	self.nHaveNum = nil
	self.tDefaultAnchor = nil
	self.tDLCName = nil
end

function ToyBoxData.ResetFilter()
	for k, v in ipairs(g_tStrings.tToyBoxFilterName) do
		self.tSelectSource[k] = true
	end
	for k, v in ipairs(self.tDLCName) do
		self.tSelectDLC[k] = true
	end
	for k, v in ipairs(g_tStrings.tToyBoxTypeName) do
		self.tSelectType[k] = true
	end
end

function ToyBoxData.OnLogin()

end

function ToyBoxData.OnFirstLoadEnd()

end

function ToyBoxData.UpdateStatus()
    local pPlayer = GetClientPlayer()
	if not pPlayer then
		return
	end

	if not pPlayer.RemoteDataAutodownFinish() then
		OutputMessage("MSG_SYS", g_tStrings.STR_TOYBOX_ERROR_MSG)
		--Close()
        UIMgr.Close(VIEW_ID.PanelQuickOperationBagNormal)
		return
	end

	local tLevel = {}
	self.nHaveNum = 0
	for k, v in pairs(self.tToyBoxInfo) do
		if ToyBoxData.GDAPI_IsToyHave(pPlayer, v.dwID, v.nCountDataIndex) then
			self.tToyBoxInfo[k].bIsHave = true
			self.nHaveNum = self.nHaveNum + 1
			local nLevelGroup = v.nLevelGroup
			if nLevelGroup ~= 0 and (not tLevel[nLevelGroup]) then
				tLevel[nLevelGroup] = true
			end
			if v.nToyType == self.TOY_TYPE.COUNT then
				v.nCount = GDAPI_GetToyUseCount(pPlayer, v.dwID, v.nCountDataIndex)
			end
		end
		if self.tAddToy and self.tAddToy[v.dwID] then
			self.tToyBoxInfo[k].bIsFirst = true
		end
	end

	local nSub = 0
	for k, v in ipairs(tLevel) do
		for kk, vv in pairs(self.tToyBoxInfo) do
			if vv.bIsHave and vv.nLevelGroup == k then
				nSub = nSub + 1
			end
		end
		nSub = nSub - 1
	end
	self.nHaveNum = self.nHaveNum - nSub
end

function ToyBoxData.GetShowBoxInfo(szText, szChooseHave)
    local tTemp = {}
	for k, v in pairs(self.tToyBoxInfo) do
		if self.Condition(v, szText, szChooseHave, self.tSelectSource, self.tSelectDLC, self.tSelectType) then
			table.insert(tTemp, v)
		end
	end
	--等级
	local tLevelItemInfo = {}
	for k, v in ipairs(tTemp) do
		local nLevelGroup = v.nLevelGroup
		if nLevelGroup > 0 then
			local tInfo = tLevelItemInfo[nLevelGroup]
			if not tInfo or (v.bIsHave and tInfo.nLevelGroup == nLevelGroup and tInfo.dwID < v.dwID) then
				tLevelItemInfo[nLevelGroup] = v
			end
		end
	end


    for kk, vv in ipairs(tTemp) do
        vv.bIgnore = false
    end

	--merge
	local tShowBoxInfo = {}
	for k, v in pairs(tLevelItemInfo) do
		for kk, vv in ipairs(tTemp) do
			if vv.nLevelGroup == k then
				tTemp[kk].bIgnore = true
			end
		end
		table.insert(tShowBoxInfo, v)
	end

	for k, v in pairs(tTemp) do
		if not v.bIgnore then
			table.insert(tShowBoxInfo, v)
		end
	end
	table.sort(tShowBoxInfo, function(tA, tB)
		return tA.dwID < tB.dwID
	end)

	return tShowBoxInfo
end

function ToyBoxData.MaxLevelID(nLevelGroup)
	local nMaxID = 0
	for k, v in pairs(self.tToyBoxInfo) do
		if v.nLevelGroup == nLevelGroup then
			nMaxID = math.max(nMaxID, v.dwID)
		end
	end
	return nMaxID
end

function ToyBoxData.Condition(tLine, szSearch, szChooseHave, tSelectSource, tSelectDLC, tSelectType)
	if szSearch ~= "" and (not string.find(tLine.szName, szSearch)) then
		return false
	end
	if szChooseHave ~= g_tStrings.STR_TOYBOX_ALL then
		if szChooseHave == g_tStrings.STR_TOYBOX_NOT_HAVE then
			if tLine.bIsHave then return false end
		else
			if not tLine.bIsHave then return false end
		end
	end

	if not tSelectDLC[tLine.dwDLCID] then
		return false
	end

	for k, v in ipairs(tSelectType) do
		if (not v) and tLine.nToyType == k then
			return false
		end
	end

	for k, v in ipairs(tSelectSource) do
		if v and string.find(tLine.szFilter, k) then
			return true
		end
	end
	return false
end

function ToyBoxData.GetGetWayTipsDesc(tbBoxInfo)
	local szTipContent = ""
	local renderIndex = 0
    if tbBoxInfo.dwMapID ~= 0 then
        local mapInfo = g_tTable.MapList:Search(tbBoxInfo.dwMapID)
        if mapInfo then
            renderIndex = renderIndex + 1
            if renderIndex > 1 then
                szTipContent = szTipContent .."\n"
            end
            szTipContent = szTipContent..string.format("%s   %s", "地图",UIHelper.GBKToUTF8(mapInfo.szName))
        end
    end
    if tbBoxInfo.dwQuestID ~= 0 then
        local questInfo = QuestData.GetQuestConfig(tbBoxInfo.dwQuestID)
        if questInfo then
            renderIndex = renderIndex + 1
            if renderIndex > 1 then
                szTipContent = szTipContent .."\n"
            end
            szTipContent = szTipContent..string.format("%s   %s", "任务",UIHelper.GBKToUTF8(questInfo.szName))
        end
    end
    if tbBoxInfo.dwAchievementID ~= 0 then
        local acInfo = Table_GetAchievement(tbBoxInfo.dwAchievementID)
        if acInfo then
            renderIndex = renderIndex + 1
            if renderIndex > 1 then
                szTipContent = szTipContent .."\n"
            end
            szTipContent = szTipContent..string.format("%s   %s", "成就",UIHelper.GBKToUTF8(acInfo.szName))
        end
    end
    if tbBoxInfo.szShop ~= "" then
        renderIndex = renderIndex + 1
        if renderIndex > 1 then
            szTipContent = szTipContent .."\n"
        end
        szTipContent = szTipContent..string.format("%s   %s", UIHelper.GBKToUTF8(tbBoxInfo.szShop),"")
    end

	return szTipContent
end

local REMOTE_TOY_BOX_CONSUME = 1129
local REMOTE_TOY_BOX = 1066
function ToyBoxData.GDAPI_IsToyHave(player, dwID, dwCountDataIndex)
    --因为在两个数据块里的位置（dwid和那个dwCountDataIndex）都给了，所以不需要
	if dwCountDataIndex > 0 then
		if not player.HaveRemoteData(REMOTE_TOY_BOX_CONSUME) then
			return false
		end
		local nCount = player.GetRemoteArrayUInt(REMOTE_TOY_BOX_CONSUME, dwCountDataIndex, 1)--1129对应位置玩具存的次数,1块存一个玩具的次数

		if nCount > 0 then--取可消耗的次数
			return true --还有剩余次数！
		end

	else
		if not player.HaveRemoteData(REMOTE_TOY_BOX) then
			return false
		end
		if player.GetRemoteBitArray(REMOTE_TOY_BOX, dwID) then--这个表示存在1066的第几位
			return true--如果有
		end

	end
	return false --无
end

-- ----------------------------------------------------------
-- 特殊玩具玉铃颂春
-- ----------------------------------------------------------

function ToyBoxData.StampInit(tInfo, nPage)
    if not nPage or nPage == 0 then
        nPage = 1
    end

    ToyBoxData.nCurrentPage = nPage
    ToyBoxData.tStampInfo   = tInfo
end

function ToyBoxData.GetStampInfo(nCurrentPage)
    if ToyBoxData.tStampInfo then
        return DataModel.tStampInfo[nCurrentPage]
    end
end

function ToyBoxData.GetHaveToyNum()
	local nHaveNum = 0
	if g_pClientPlayer then
		for k, v in pairs(self.tToyBoxInfo) do
			if ToyBoxData.GDAPI_IsToyHave(g_pClientPlayer, v.dwID, v.nCountDataIndex) then
				nHaveNum = nHaveNum + 1
			end
		end
	end
	return nHaveNum
end

function ToyBoxData.UseToySkill(boxInfo, fnCallBack, fnActionCallBack)
    --使用玩具
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end

	local skill = GetSkill(boxInfo.nSkillID, boxInfo.nSkillLevel)
	local nMode = skill.nCastMode
	if nMode and (nMode == SKILL_CAST_MODE.POINT_AREA or nMode == SKILL_CAST_MODE.POINT) then	--加入动态技能球
		if fnActionCallBack then
			fnActionCallBack()
		end
		ToyBoxData.AddActionToy(boxInfo.dwID)
	else
		local hasBuff = GetClientPlayer().IsHaveBuff(boxInfo.nbuff, boxInfo.nbuffLevel)
		if hasBuff then
			local buffList = BuffMgr.GetVisibleBuff(GetClientPlayer())
			for i, buffInfo in ipairs(buffList) do
				if buffInfo.dwID == boxInfo.nbuff then
					GetClientPlayer().CancelBuff(buffInfo.nIndex)
					fnCallBack()
					break
				end
			end
		else
			if (boxInfo.bIsHave and boxInfo.nToyType ~= ToyBoxData.TOY_TYPE.COUNT) then
				--SkillData.CastSkill(pPlayer,boxInfo.nSkillID, boxInfo.nSkillLevel)
				local bSelfAsTarget = true
				local result = CastSkill(boxInfo.nSkillID, boxInfo.nSkillLevel, bSelfAsTarget)
				if result == SKILL_RESULT_CODE.SUCCESS then
					fnCallBack()
				end
			end
		end
	end
end

function ToyBoxData.GetActionToyList()
	return self.tbActionToy
end

function ToyBoxData.AddActionToy(dwID)
	if table.contain_value(self.tbActionToy, dwID) then
		TipsHelper.ShowNormalTip("该玩具已添加到动态技能栏")
		return
	end

	table.insert(self.tbActionToy, dwID)
	Event.Dispatch(EventType.UpdateActionToySkillState)
end

function ToyBoxData.RemoveActionToy(dwID)
	local bResult = table.remove_value(self.tbActionToy, dwID)
	if bResult then
		Event.Dispatch(EventType.UpdateActionToySkillState)
	end
end

function ToyBoxData.ClearActionToyList()
	self.tbActionToy = {}
end

function ToyBoxData.IsToyInActionBar(dwID)
	return table.contain_value(self.tbActionToy, dwID)
end
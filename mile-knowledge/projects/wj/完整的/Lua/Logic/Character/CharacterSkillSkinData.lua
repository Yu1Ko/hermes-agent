-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: CharacterSkillSkinData
-- Date: 2024-10-23 20:00:09
-- Desc: ?
-- ---------------------------------------------------------------------------------
---@class CharacterSkillSkinData
CharacterSkillSkinData = CharacterSkillSkinData or {className = "CharacterSkillSkinData"}

local self = CharacterSkillSkinData

local EACH_PAGE_MAX_COUNT 		= 9
local MAX_SKIN_LIKE_NUM 		= 20
local DX_FUYAO_SKILL_ID = 9002	-- dx端扶摇id
local tbSkillList = {
	[0] = 0,		-- 表示收藏页面
	[1] = 17,       -- 打坐
	[2] = 34,       -- 虹气长空
	[3] = 81,       -- 神行千里
    [4] = 100004,   -- 扶摇
	[5] = 608,      -- 自绝经脉
	[6] = 35,       -- 传功
}
local tbSkinItemList = (function()
	local t = {}
	for _, tbSkillInfo in pairs(UISkillSkinTab) do
		for _, tbInfo in pairs(tbSkillInfo) do
			t[tbInfo["nItemIndex"]] = tbInfo
		end
	end
	return t
end)()

Event.Reg(self, EventType.OnClientPlayerEnter, function()
	local tbCurSkinCollect = {}
	for _, dwSkillID in ipairs(tbSkillList) do
		local bFuYao = dwSkillID == 100004
		local dwSkinGroup = Table_GetSkillSkinGroup(bFuYao and DX_FUYAO_SKILL_ID or dwSkillID)
		if dwSkinGroup then
			local tAllSkin = GetSkillSkinByGroupID(dwSkinGroup)
			for _, dwSkinID in ipairs(tAllSkin) do
				local bHave = self.IsHaveSkillSkin(dwSkinID)
				if bHave then
					tbCurSkinCollect[dwSkinID] = true
				end
			end
		end
	end

	self.tbCurSkinCollect = tbCurSkinCollect
end)

Event.Reg(self, "ON_UPDATE_SKILL_SKIN", function(nPlayerID)
	if nPlayerID ~= PlayerData.GetPlayerID() then
		return
	end

	local tbCurSkinCollect = {}
	for _, dwSkillID in ipairs(tbSkillList) do
		local bFuYao = dwSkillID == 100004
		local dwSkinGroup = Table_GetSkillSkinGroup(bFuYao and DX_FUYAO_SKILL_ID or dwSkillID)
		local tAllSkin = GetSkillSkinByGroupID(dwSkinGroup)
		for _, dwSkinID in ipairs(tAllSkin) do
			local bHave = self.IsHaveSkillSkin(dwSkinID)
			tbCurSkinCollect[dwSkinID] = bHave
			if bHave and self.tbCurSkinCollect[dwSkinID] ~= bHave then
				RedpointHelper.SkillSkin_SetNew(dwSkinID, true)
			end
		end
	end
	self.tbCurSkinCollect = tbCurSkinCollect
end)

function CharacterSkillSkinData.GetGroupID(nSkillID)
    local bFuYao = nSkillID == 100004
	return Table_GetSkillSkinGroup(bFuYao and DX_FUYAO_SKILL_ID or nSkillID)
end

function CharacterSkillSkinData.GetSkinItemList()
    return tbSkinItemList
end

function CharacterSkillSkinData.GetSkinItemIndex(nSkillID, nSkinID)
	local nItemIndex
    if UISkillSkinTab[nSkillID] and UISkillSkinTab[nSkillID][nSkinID] then
        nItemIndex = UISkillSkinTab[nSkillID][nSkinID]["nItemIndex"]
    end
	return nItemIndex
end

---------------------界面相关------------------------
function CharacterSkillSkinData.Init()
    self.nSkillSkinPage = 1
    self.dwSelectType = 1
	self.tSkillSkinList = {}
	self.tAllSkinList = {}
	self.UpdateLikeInfo()

    for _, nSkillID in pairs(tbSkillList) do
		self.tAllSkinList[nSkillID] = {}
		local bFuYao = nSkillID == 100004
		local dwSkinGroup = Table_GetSkillSkinGroup(bFuYao and DX_FUYAO_SKILL_ID or nSkillID)
		local tbAllSkin = GetSkillSkinByGroupID(dwSkinGroup)

		for index, nSkinID in ipairs(tbAllSkin) do
			local bHave = self.IsHaveSkillSkin(nSkinID)
			table.insert(self.tAllSkinList[nSkillID], {nSkillID = nSkillID, nSkinID = nSkinID, bHave = bHave})
		end
    end

	self.EmptyAllFilter()
	self.SortSkillSkin()
	self.FilterList()
end

function CharacterSkillSkinData.UnInit()
	self.szSearchText = nil
    self.dwSelectType = nil
	self.nSkillSkinPage = nil
	self.nFilterSkinCount = nil
	self.nFilterHave = 0
	self.tSkillSkinList = nil
	self.tAllSkinList = nil
	self.tSkillSkinList = nil
	self.tFilterSkillSkinList = nil
end

function CharacterSkillSkinData.UpdateLikeInfo(bUpdateCheck)
	local tbSkillSkinLike = {}
	self.tbSkillSkinLike = {}

	for i = 1, MAX_SKIN_LIKE_NUM, 1 do
		local nLikeSkinID = Storage_Server.GetData("SkillSkinLike", i)
		if nLikeSkinID and nLikeSkinID > 0 then
			tbSkillSkinLike[i] = nLikeSkinID
		end
	end

	for _, nSkinID in pairs(tbSkillSkinLike) do
		self.tbSkillSkinLike[nSkinID] = true
	end

	if bUpdateCheck then
		Event.Dispatch(EventType.OnUpdateSkillSkinLike)
	end
end

function CharacterSkillSkinData.SortSkillSkin()
	local function fnDegree(a, b)
		if self.tbSkillSkinLike[a.nSkinID] == self.tbSkillSkinLike[b.nSkinID] then
			if a.bHave == b.bHave then
				return a.nSkinID > b.nSkinID
			elseif a.bHave then
				return true
			else
				return false
			end
		elseif self.tbSkillSkinLike[a.nSkinID] then
			return true
		else
			return false
		end
	end

	local tRes = {}
	if self.dwSelectType == 0 then
		for nSkinID, _ in pairs(self.tbSkillSkinLike) do
			if nSkinID and nSkinID > 0 then
				local nSkillID = Table_GetSkillSkinInfo(nSkinID).dwSkillID
				local bHave = self.IsHaveSkillSkin(nSkinID)
				table.insert(tRes, {nSkillID = nSkillID, nSkinID = nSkinID, bHave = bHave})
			end
		end
	else
		tRes = clone(self.tAllSkinList[tbSkillList[self.dwSelectType]])
	end

	if tRes == nil then
        tRes = {}
    end

	table.sort(tRes, fnDegree)

	if self.dwSelectType ~= 0 then	-- 收藏不显示默认
		local tbConfSkin = {nSkillID = self.GetSkillID(), bConfSkin = true, szName = "默认", bHave = true}
		table.insert(tRes, 1, tbConfSkin)
	end

	self.tSkillSkinList = tRes
end

function CharacterSkillSkinData.GetSkinInfo(dwSkinID)
	local tSkin = Table_GetSkillSkinInfo(dwSkinID)
    return tSkin
end

function CharacterSkillSkinData.FilterList()
	local tHaveList = {}
	if (not self.nFilterHave) or (self.nFilterHave == 0) then
		tHaveList = self.tSkillSkinList
	else
		for _, tbSkinInfo in pairs(self.tSkillSkinList) do
			if (self.nFilterHave == 1 and tbSkinInfo.bHave) or (self.nFilterHave == 2 and not tbSkinInfo.bHave) then
				table.insert(tHaveList, tbSkinInfo)
			end
		end
	end

	local tSearchList = {}
	if (not self.szSearchText) or (self.szSearchText == "") then
		tSearchList = tHaveList
	else
		for k, tbSkinInfo in ipairs(tHaveList) do
			local dwSkinID = tbSkinInfo.nSkinID
			local tSkin = self.GetSkinInfo(dwSkinID)
			local szSkinName = tbSkinInfo.szName and UIHelper.UTF8ToGBK(tbSkinInfo.szName) or tSkin.szName
			if string.find(UIHelper.GBKToUTF8(szSkinName), self.szSearchText) then
				table.insert(tSearchList, tbSkinInfo)
			end
		end
	end

	self.tFilterSkillSkinList = tSearchList
	self.nFilterSkinCount = #self.tFilterSkillSkinList
	for _, tbSkinInfo in ipairs(tSearchList) do
		if tbSkinInfo.bConfSkin then
			self.nFilterSkinCount = #self.tFilterSkillSkinList - 1
			break
		end
	end
end

function CharacterSkillSkinData.GetSkillID(nIndex)
	nIndex = nIndex or self.dwSelectType
	if not nIndex then
		return
	end
	return tbSkillList[nIndex]
end

function CharacterSkillSkinData.IsHaveSkillSkin(nSkinID)
	local pPlayer = GetClientPlayer()
	if not pPlayer then
		return
	end

	return pPlayer.IsHaveSkillSkin(nSkinID)
end

function CharacterSkillSkinData.SetFilterHave(nFilterHave)
	self.nFilterHave = nFilterHave
end

function CharacterSkillSkinData.GetSkillSkinList()
    local tbRes = {}
	local nStart = (self.nSkillSkinPage - 1) * EACH_PAGE_MAX_COUNT + 1
	for i = 0, EACH_PAGE_MAX_COUNT - 1, 1 do
        local nIndex = nStart + i
        local tbInfo = self.tFilterSkillSkinList and self.tFilterSkillSkinList[nIndex]
        if tbInfo then
            table.insert(tbRes, tbInfo)
        end
    end

    return tbRes
end

-----------------------收藏相关-------------------------
function CharacterSkillSkinData.GetSkinLike(nSkinID)
    if not self.tbSkillSkinLike then
		self.UpdateLikeInfo()
	end

	return self.tbSkillSkinLike[nSkinID]
end

function CharacterSkillSkinData.SetSkinLike(nSkinID, bDel)
	local bChange = false
	for i = 1, MAX_SKIN_LIKE_NUM, 1 do
		local nLikeSkinID = Storage_Server.GetData("SkillSkinLike", i)
		if bDel then
			if nLikeSkinID == nSkinID then
				Storage_Server.SetData("SkillSkinLike", i, nil)
				bChange = true
			end
		else
			if not nLikeSkinID or nLikeSkinID <= 0 then
				Storage_Server.SetData("SkillSkinLike", i, nSkinID)
				bChange = true
			end
		end

		if bChange then
			self.UpdateLikeInfo(true)
			return
		end
	end

	TipsHelper.ShowNormalTip("已达到收藏上限")
end

---------------------挂饰秘鉴通用界面配置函数-----------------------

function CharacterSkillSkinData.SetCurrentPage(dwCurrentPage)
    CharacterSkillSkinData.dwCurrentPage = dwCurrentPage
end

function CharacterSkillSkinData.SetSelectType(dwPart)
    CharacterSkillSkinData.dwSelectType = dwPart
    CharacterSkillSkinData.EmptyAllFilter()
end

function CharacterSkillSkinData.SetSearchText(szSearchText)
    CharacterSkillSkinData.szSearchText = szSearchText
end

function CharacterSkillSkinData.GetSearchText()
    return CharacterSkillSkinData.szSearchText
end

function CharacterSkillSkinData.GetCollectionProgressTips()
    local nTotalNum = self.nFilterSkinCount
	local nHaveNum = 0
	for _, tbInfo in pairs(self.tFilterSkillSkinList) do
		if tbInfo.bHave and not tbInfo.bConfSkin then
			nHaveNum = nHaveNum + 1
		end
	end
	return nTotalNum, nHaveNum
end

function CharacterSkillSkinData.GetCollectedNum()
    local nTotalNum = MAX_SKIN_LIKE_NUM
	local nHaveNum = table.get_len(self.tbSkillSkinLike)

	return nTotalNum, nHaveNum
end

function CharacterSkillSkinData.GetCurPageInfo()
    local nTotalPage = math.ceil(#self.tFilterSkillSkinList / EACH_PAGE_MAX_COUNT)
	return nTotalPage, self.nSkillSkinPage
end

function CharacterSkillSkinData.EmptyAllFilter()
	CharacterSkillSkinData.szSearchText = ""
	CharacterSkillSkinData.nFilterHave = 0
end

function CharacterSkillSkinData.UpdateFilterList()
	self.SortSkillSkin()
	self.FilterList()
end
-----------------------------Quest-------------------------------

local function RegisterQuestND(dwMapID, tQuestND, szTitle)
	local szPath = tQuestND.Path .. dwMapID .. ".txt"
	if not IsUITableRegister(szTitle) then
		RegisterUITable(szTitle, szPath, tQuestND.Title, tQuestND.KeyNum)
	end

	return cc.FileUtils:getInstance():isFileExist(szPath)
end

local function Quest_ParseRegion(szData)
	local tRegion = SplitString(szData, ";")
	local tPoint
	local tPoints = {}
	local tColor
	local tLineColor

	for k, v in pairs(tRegion) do
		tPoint = SplitString(v, ",")
		if k == 1 then
			tColor = {tonumber(tPoint[1]), tonumber(tPoint[2]), tonumber(tPoint[3]), tonumber(tPoint[4])}
			if #tPoint == 8 then
				tLineColor = {tonumber(tPoint[5]), tonumber(tPoint[6]), tonumber(tPoint[7]), tonumber(tPoint[8])}
			end
		else
			tPoint[1], tPoint[2], tPoint[3] = tonumber(tPoint[1]), tonumber(tPoint[2]), tonumber(tPoint[3])
			table.insert(tPoints, tPoint)
		end
	end
	tPoints.tColor = tColor
	tPoints.tLineColor = tLineColor
	return tPoints
end

local function Quest_ParseRegions(szType, szData)
	local text = string.sub(szType, 2)
	if not text then
		return
	end

	local t = SplitString(text, "|")
	local dwMapID  = t[1]
	local dwAreaId = t[2]

	if not dwMapID then
		return
	end

	dwMapID = tonumber(dwMapID)
	if dwAreaId then
		dwAreaId = tonumber(dwAreaId)
	end
	t = SplitString(szData, "|")
	local tRegion = {}
	local tColor, tPoints
	for _, v in ipairs(t) do
		tPoints = Quest_ParseRegion(v)
		table.insert(tRegion, tPoints)
	end

	return dwMapID, dwAreaId, tRegion
end

local function Quest_ParseFrame(szData)
	local szFrame, szSource = string.match(szData, "([%d]+)|([%d,;]+)")
	if szFrame and szFrame ~= "" and szSource and szSource ~= "" then
		return szSource, tonumber(szFrame)
	end
	return szData;
end

local function Quest_MarkDataIndex(szType, tParam)
	if not tParam.tData.tIndex[szType] then
		tParam.tData.tIndex[szType] = tParam.nIndex
		tParam.nIndex = tParam.nIndex + 1
	end
end

function Quest_GetNDInfo(szType, dwMapID, dwObject, nAreaID)
	local tQuestPos = nil
	local dwIdentityVisiableID = nil
	if szType == "N" then
		local szTitle = "QuestNpc" .. dwMapID
		local nRetCode = RegisterQuestND(dwMapID, g_tQuestNpc, szTitle)
		if not nRetCode then
			return
		end
		local npc = GetNpcTemplate(dwObject)
		if not npc then return end
		dwIdentityVisiableID = npc.dwIdentityVisiableID
		tQuestPos = g_tTable[szTitle]:Search(dwObject, nAreaID)
		if not tQuestPos and nAreaID ~= 0 then
			tQuestPos = g_tTable[szTitle]:Search(dwObject, 0)
		end

		-- tQuestPos = g_tTable.QuestNpc:Search(dwObject, dwMapID, nAreaID)
		-- if not tQuestPos and nAreaID ~= 0 then
		-- 	tQuestPos = g_tTable.QuestNpc:Search(dwObject, dwMapID, 0)
		-- end
	else
		local doodad = GetDoodadTemplate(dwObject)
		if not doodad then return end
		local szTitle = "QuestDoodad" .. dwMapID
		dwIdentityVisiableID = doodad.dwIdentityVisiableID
		local nRetCode = RegisterQuestND(dwMapID, g_tQuestDoodad, szTitle)
		if not nRetCode then
			return
		end
		tQuestPos = g_tTable[szTitle]:Search(dwObject, nAreaID)
		if not tQuestPos and nAreaID ~= 0 then
			tQuestPos = g_tTable[szTitle]:Search(dwObject, 0)
		end

		-- tQuestPos = g_tTable.QuestDoodad:Search(dwObject, dwMapID, nAreaID)
		-- if not tQuestPos and nAreaID ~= 0 then
		-- 	tQuestPos = g_tTable.QuestDoodad:Search(dwObject, dwMapID, 0)
		-- end
	end
	return tQuestPos, dwIdentityVisiableID
end

local function Quest_GetNDPositions(szType, dwMapID, dwObject, nAreaID)
	local tQuestPos, dwIdentityVisiableID = Quest_GetNDInfo(szType, dwMapID, dwObject, nAreaID)
	if tQuestPos and tQuestPos.szPositions ~= "" then
		return StringParse_Numbers(tQuestPos.szPositions), dwIdentityVisiableID, tQuestPos.dwActivityID
	end
end

local function Quest_GetNDData(szType, szData, tParam)
	local dwMapID, nAreaID, tPointList, tOrderMapID, tFlagID = tParam.dwMapID, tParam.nAreaID, tParam.tData["ND"], tParam.tOrderMapID, tParam.tFlagID

	local nFrame
	szData, nFrame = Quest_ParseFrame(szData)

	local dwObject, dwID
	local tData = StringParse_Numbers(szData)
	for _, tInfo in ipairs(tData) do
		dwObject = tInfo[2]
		dwID     = tInfo[1]
		if dwMapID == 0 or dwMapID == dwID then
			local tPositions, dwIdentityVisiableID, dwActivityID = Quest_GetNDPositions(szType, dwID, dwObject, nAreaID)
			if tPositions then
				tPointList[dwID] = tPointList[dwID] or {}
				Quest_MarkDataIndex("ND", tParam)

				for _, tPos in ipairs(tPositions) do
					table.insert(tPointList[dwID], {tPos[1], tPos[2], tPos[3], dwObject, nFrame, szType, dwIdentityVisiableID, dwActivityID})
				end

				if tOrderMapID and not tFlagID[dwID] then
					table.insert(tOrderMapID, {dwID, dwActivityID})
					tFlagID[dwID] = true
				end
			end
		end
	end
end

local function Quest_GetPData(szType, szData, tParam)
	local dwMapID, tPointList, tOrderMapID, tFlagID = tParam.dwMapID, tParam.tData["P"], tParam.tOrderMapID, tParam.tFlagID

	local nAreaID = 0
	if #szType > 1 then
		nAreaID  = tonumber(string.sub(szType, 2))
	end

	local dwID, nFrame, t
	szData, nFrame = Quest_ParseFrame(szData)

	local tData = StringParse_Numbers(szData)
	for _, tPos in ipairs(tData) do
		dwID = tPos[1]
		if dwMapID == 0 or dwID == dwMapID then
			tPointList[dwID] = tPointList[dwID] or {}
			tPointList[dwID][nAreaID] = tPointList[dwID][nAreaID] or {}
			Quest_MarkDataIndex("P", tParam)

			table.insert(tPointList[dwID][nAreaID], {tPos[2], tPos[3], tPos[4], nil, nFrame, "P"} )
			if tOrderMapID and not tFlagID[dwID] then
				table.insert(tOrderMapID, {dwID, -1})
				tFlagID[dwID] = true
			end
		end
	end
end

local function Quest_GetRData(szType, szData, tParam)
	local dwMapID, tPointList, tOrderMapID, tFlagID = tParam.dwMapID, tParam.tData["R"], tParam.tOrderMapID, tParam.tFlagID

	local dwID, nAreaID, tRegions = Quest_ParseRegions(szType, szData)
	nAreaID = nAreaID or 0
	if dwID and (dwMapID == 0 or dwID == dwMapID)  then
		tPointList[ dwID ] = tPointList[ dwID ] or {}
		tPointList[ dwID ][ nAreaID ] = tRegions

		Quest_MarkDataIndex("R", tParam)

		if tOrderMapID and not tFlagID[ dwID ] then
			table.insert(tOrderMapID, {dwID,-1})
			tFlagID[ dwID ] = true
		end
	end
end

local function Quest_GetFData(szData, tParam)
	if tParam.dwFollowTemplateID then
		return
	end

	local dwTemplateID = tonumber(string.match(szData, "(%d+)"))
	if dwTemplateID then
		tParam.dwFollowTemplateID = dwTemplateID
	end
end

local function Quest_GetPoint(szPointList, dwMapID, nAreaID, bGetOrderMapID)
	local tData = { ND = {}, P = {}, R = {}, tIndex={} }
	local tParam = {
		dwMapID = dwMapID or 0,
		nAreaID = nAreaID or 0,
		nIndex = 1,
		tData = tData,
		tOrderMapID = tOrderMapID,
		tFlagID = tFlagID,
		dwFollowTemplateID = nil,
	}

	if bGetOrderMapID then
		tParam.tOrderMapID, tParam.tFlagID = {}, {}
	end

	for szType, szData in string.gmatch(szPointList, "<(%a[%d|]*) ([%d,;|]+)>") do
		if szType == "N" or szType == "D" then	-- npc
			Quest_GetNDData(szType, szData, tParam)

		elseif string.sub(szType, 1,1) == "P" then	-- postion
			Quest_GetPData(szType, szData, tParam)

		elseif string.sub(szType, 1,1) == "R" then
			Quest_GetRData(szType, szData, tParam)
		elseif szType == "F" then
			Quest_GetFData(szData, tParam)
		else
			Log("[UI DEBUG] Error Quest Point Type: " .. tostring(szType))
		end
	end

	local tRes
	for type, index in pairs(tData.tIndex) do
		tRes = tRes or {}
		tRes[index] = tData[type]
		tRes[index].type = type
	end
	return tRes, tParam.tOrderMapID, tParam.dwFollowTemplateID
end

local function Quest_GetNDMap(szType, szData, tRetMapID)
	szData = Quest_ParseFrame(szData)
	local dwObject, dwID
	local tData = StringParse_Numbers(szData)
	for _, tInfo in ipairs(tData) do
		dwObject = tInfo[2]
		dwID     = tInfo[1]
		local tInfo = Quest_GetNDInfo(szType, dwID, dwObject, 0)
		if tInfo then
			tRetMapID[dwID] = {dwID, tInfo.dwActivityID}
		end
	end
end

local function Quest_GetPMap(szType, szData, tRetMapID)
	local nAreaID = 0
	if #szType > 1 then
		nAreaID  = tonumber(string.sub(szType, 2))
	end

	local dwID, nFrame, t
	szData, nFrame = Quest_ParseFrame(szData)

	local tData = StringParse_Numbers(szData)
	for _, tPos in ipairs(tData) do
		dwID = tPos[1]
		tRetMapID[dwID] = {dwID, -1}
	end
end

local function Quest_GetRMap(szType, szData, tRetMapID)
	local dwID, nAreaID, tRegions = Quest_ParseRegions(szType, szData)
	tRetMapID[dwID] = {dwID, -1}
end

local function Quest_GetMapIDs(dwQuestID, szType, nIndex)
	local tQuestTrace 	= GetClientPlayer().GetQuestTraceInfo(dwQuestID)
	if not tQuestTrace then
		return
	end

	local szPosInfo = Table_GetQuestPosInfo(dwQuestID, szType, nIndex)
	if not szPosInfo then
		return
	end

	local tMapID = {}
	for szType, szData in string.gmatch(szPosInfo, "<(%a[%d|]*) ([%d,;|]+)>") do
		if szType == "N" or szType == "D" then	-- npc
			Quest_GetNDMap(szType, szData, tMapID)

		elseif string.sub(szType, 1,1) == "P" then	-- postion
			Quest_GetPMap(szType, szData, tMapID)

		elseif string.sub(szType, 1,1) == "R" then
			Quest_GetRMap(szType, szData, tMapID)
		elseif szType == "F" then
			-- F only provides dynamic follow metadata and does not contribute map IDs.
		else
			Log("[UI DEBUG] Error Quest Point Type: " .. tostring(szType))
		end
	end

	local tRetMapID = {}
	for k, v in pairs(tMapID) do
		table.insert(tRetMapID, v)
	end
	return tRetMapID
end

local m_tQuestPoints = {}
local m_tQuestFollowTemplates = {}
local m_dwIdentityVisiableID = nil

local function TableQuest_GetAllPoint(dwQuestID, szType, nIndex) -- 未被使用
	local tQuestTrace 	= GetClientPlayer().GetQuestTraceInfo(dwQuestID)
	if not tQuestTrace then
		return
	end

	local key = string.format("%s_%s_%d", dwQuestID, (szType or ""), (nIndex or 0))
	local tData, tMapID, dwFollowTemplateID
	if not m_tQuestPoints[key] then
		local szPosInfo = Table_GetQuestPosInfo(dwQuestID, szType, nIndex)
		if not szPosInfo then
			return
		end

		tData, tMapID, dwFollowTemplateID = Quest_GetPoint(szPosInfo, 0, 0, true)
		m_tQuestPoints[key] = {tData, tMapID}
		m_tQuestFollowTemplates[key] = dwFollowTemplateID
	else
		tData, tMapID = m_tQuestPoints[key][1], m_tQuestPoints[key][2]
		dwFollowTemplateID = m_tQuestFollowTemplates[key]
	end
	return tData, tMapID, dwFollowTemplateID
end

local function Quest_GetCachePoint(dwQuestID, szType, nIndex, dwMapID, nAreaID)
	local key = string.format("%s_%s_%d_%d", dwQuestID, (szType or ""), (nIndex or 0), dwMapID)
	local tData, tMapID, dwFollowTemplateID
	if not m_tQuestPoints[key] then
		local szPosInfo = Table_GetQuestPosInfo(dwQuestID, szType, nIndex)
		if not szPosInfo then
			return
		end

		tData, tMapID, dwFollowTemplateID = Quest_GetPoint(szPosInfo, dwMapID, nAreaID, true)
		m_tQuestPoints[key] = tData
		m_tQuestFollowTemplates[key] = dwFollowTemplateID
	else
		tData = m_tQuestPoints[key]
		dwFollowTemplateID = m_tQuestFollowTemplates[key]
	end
	return tData, tMapID, dwFollowTemplateID
end

--[[
tData =
{
	[1] = {
		type = "R",
		[dwMapID] = {
			[AreaID] = {--regions
				[1] = { {point, point} }, --region
				[2] = {}, --region
			}
		}
	}
	[2] = {
		type="P",
		[dwMapID] = {
			[AreaID] = {--points
				[1] = {}, --point
				[2] = {}, --point
			}
		}
	}
	[3]	 = {
		type="ND",
		[dwMapID] = {--points
			[1] = {}, --point
			[2] = {}, --point
		}
	}
}
]]
function TableQuest_GetPoint(dwQuestID, szType, nIndex, dwMapID, nAreaID)
	local tData = Quest_GetCachePoint(dwQuestID, szType, nIndex, dwMapID, nAreaID)
	if not tData then
		return nil
	end
	--[[
	{
		{type = "R",  {{region}, {region}}-regions
		{type = "P",  {{Point}, {Point}} -Points
		{type = "ND", {{Point}, {Point}} -Points
	}
	]]
	local t, tRes
	for k, v in ipairs(tData) do
		if v[dwMapID] then
			if v.type == "ND" then
				t = v[dwMapID]
			else
				t = (v[dwMapID][nAreaID] or v[dwMapID][0])
			end

			if t then
				t.type = v.type
				tRes = tRes or {}
				table.insert(tRes, t)
			end
		end
	end

	return tRes, tMapID
end

function TableQuest_GetRegions(dwQuestID, szType, nIndex, dwMapID, nAreaID, bclone)
	local tData = TableQuest_GetPoint(dwQuestID, szType, nIndex, dwMapID, nAreaID)
	if not tData then
		return
	end

	for _, v in ipairs(tData) do
		if v.type == "R" then
			if bclone then
				return clone(v)
			else
				return v
			end
		end
	end
end

function TableQuest_IsHavePoint(dwQuestID, szType, nIndex, dwMapID, nAreaID)
	local tData = Quest_GetCachePoint(dwQuestID, szType, nIndex, dwMapID, nAreaID)
	if not tData then
		return
	end

	if dwMapID == 0 then
		return (tData ~= nil)
	end

	for k, v in ipairs(tData) do
		if v[dwMapID] then
			return true
		end
	end
end

function TableQuest_GetFirstPoint(dwQuestID, szType, nIndex, dwMapID, nAreaID)
	local tData = Quest_GetCachePoint(dwQuestID, szType, nIndex, dwMapID, nAreaID)
	if not tData then
		return
	end

	local t
	for _, v in ipairs(tData) do
		for dwID in pairs(v) do
			if dwMapID == 0 or dwID == dwMapID then
				if v.type == "ND" then
					t = v[dwID]
					return t[1], t, v.type
				elseif v.type == "P" then
					t = (v[dwID][nAreaID] or v[dwID][0])
					return t[1], t, v.type
				elseif v.type == "R" then
					t = (v[dwID][nAreaID] or v[dwID][0])
					return t[1][1], t, v.type
				end
			end
		end
	end
end

function TableQuest_GetFirstFollowTemplate(dwQuestID, szType, nIndex, dwMapID, nAreaID)
	if not dwMapID then
		return
	end
	local _, _, dwFollowTemplateID = Quest_GetCachePoint(dwQuestID, szType, nIndex, dwMapID, nAreaID)
	return dwFollowTemplateID
end

function TableQuest_GetMapIDs(dwQuestID, szType, nIndex)
	local tMapID = Quest_GetMapIDs(dwQuestID, szType, nIndex)
	return tMapID
end

local function Quest_MakeMinimapRegionMask(szType, nStateIndex, nIndex)
	--dwQuestID  99999
	--item -->1 100099999
	--npc -->2  200099999
	--state index -- >1100-1900 / 2100-2900
	--nIndex 00
	if szType == "kill_npc" then
		return (20000 + nStateIndex * 1000 + nIndex)

	elseif szType == "need_item" then
		return (10000 + nStateIndex * 1000 + nIndex)
	end
end

function Quest_MakeMinimapRegionID(dwQuestID, szType, nStateIndex, nIndex)
	--dwQuestID 0--99999
	if szType == "kill_npc" then
		return Quest_MakeMinimapRegionMask(szType, nStateIndex, nIndex) * 100000 + dwQuestID

	elseif szType == "need_item" then
		return Quest_MakeMinimapRegionMask(szType, nStateIndex, nIndex) * 100000 + dwQuestID
	end
end

function Quest_MinimapRegionIDToQuestID(dwRegionID)
	dwRegionID = dwRegionID - math.floor(dwRegionID / 100000) * 100000
	return dwRegionID
end


function GetQuestTipIconAndFont(dwQuestID, hPlayer)
	local nFrame, nFont = 0, 0
	local nDifficult = hPlayer.GetQuestDiffcultyLevel(dwQuestID)
	if nDifficult == QUEST_DIFFICULTY_LEVEL.PROPER_LEVEL then
		nFrame, nFont = 2, 136	-- 黄
	elseif nDifficult == QUEST_DIFFICULTY_LEVEL.HIGH_LEVEL then
		nFrame, nFont = 5, 158	-- 橙
	elseif nDifficult == QUEST_DIFFICULTY_LEVEL.HIGHER_LEVEL then
		nFrame, nFont = 1, 102	-- 红
	elseif nDifficult == QUEST_DIFFICULTY_LEVEL.LOW_LEVEL then
		nFrame, nFont = 4, 80	-- 绿
	elseif nDifficult == QUEST_DIFFICULTY_LEVEL.LOWER_LEVEL then
		nFrame, nFont = 3, 61	-- 灰
	else
		nFrame, nFont = 2, 136	-- 黄
	end
	return nFrame, nFont
end

function OutputQuestTip(dwQuestID, Rect, bLink)
	local player = GetClientPlayer()
    local questInfo = GetQuestInfo(dwQuestID)
    local tQuestStringInfo = Table_GetQuestStringInfo(dwQuestID)
    local questTrace = player.GetQuestTraceInfo(dwQuestID)
    if not questInfo then
    	Log("get questInfo failed when OutputQuestTip\n")
    	return
    end

    local _, nFont = GetQuestTipIconAndFont(dwQuestID, player)

	local szTip = "<Text>text="..EncodeComponentsString(tQuestStringInfo.szName.."\n").." font="..nFont.." </text>"



	if player.GetQuestState(dwQuestID) == QUEST_STATE.FINISHED then
		szTip = szTip.."<Text>text="..EncodeComponentsString(g_tStrings.STR_QUEST_FINISHED.."\n").." font=106 </text>"
	else
		szTip = szTip.."<Text>text="..EncodeComponentsString(g_tStrings.STR_QUEST_UNFINISHED.."\n").." font=102 </text>"
	end

	local szQuestClass = Table_GetQuestClass(questInfo.dwQuestClassID)
	szTip = szTip.."<Text>text="..EncodeComponentsString(szQuestClass.."\n").." font=106 </text>"
    szTip = szTip.."<Text>text="..EncodeComponentsString(g_tStrings.TIP_START_LEVEL..questInfo.nMinLevel.."\n").." font=106 </text>"

    local bStart = false
    if questInfo.dwStartNpcTemplateID ~= 0 then
    	szTip = szTip.."<Text>text="..EncodeComponentsString(g_tStrings.TIP_START..Table_GetNpcTemplateName(questInfo.dwStartNpcTemplateID)).." font=106 </text>"
    	bStart = true
    elseif questInfo.dwStartItemType ~= 0 and questInfo.dwStartItemIndex ~= 0 then
    	local itemInfo = GetItemInfo(questInfo.dwStartItemType, questInfo.dwStartItemIndex)
    	if itemInfo then
    		szTip = szTip.."<Text>text="..EncodeComponentsString(g_tStrings.TIP_START..ItemData.GetItemNameByItemInfo(itemInfo)..g_tStrings.TIP_ITEM).." font=106 </text>"
    		bStart = true
    	end
    end

    local tQuestPosInfo = nil
    if bStart or questInfo.dwEndNpcTemplateID ~= 0 then
    	tQuestPosInfo = Table_GetQuestPosInfo(dwQuestID, "all")
    end

    if bStart then
    	if tQuestPosInfo and tQuestPosInfo.szAccept ~= "" then
    		szTip = szTip.."<image>w=24 h=24 path=\"ui/Image/QuestPanel/QuestPanel.UITex\" frame=13 eventid=341 name=\"accept\" </image>"
    	end
		szTip = szTip.."<text>text=\"\\\n\" font=106 </text>"
	end


    if questInfo.dwEndNpcTemplateID ~= 0 then
    	szTip = szTip .. GetFormatText(g_tStrings.TIP_END .. Table_GetNpcTemplateName(questInfo.dwEndNpcTemplateID), 106)
		if tQuestPosInfo and tQuestPosInfo.szFinish ~= "" then
			szTip = szTip.."<image>w=24 h=24 path=\"ui/Image/QuestPanel/QuestPanel.UITex\" frame=13 eventid=341 name=\"finish\" </image>"
		end
		szTip = szTip.."<text>text=\"\\\n\" font=106 </text>"
    end

    local szPrev = ""
    local nCount = 0
	for i = 1, 4, 1 do
    	if questInfo["dwPrequestID"..i] ~= 0 then
			local qPrev = GetQuestInfo(questInfo["dwPrequestID"..i])
			if not qPrev.bHungUp and qPrev.nLevel < 255 then
				local tPrevQuestStringInfo = Table_GetQuestStringInfo(questInfo["dwPrequestID"..i])
				if tPrevQuestStringInfo then
					szPrev = szPrev.."<Text>text="..EncodeComponentsString("["..tPrevQuestStringInfo.szName.."]\n").." font="..nFont..
					" eventid=341 name=\"prev\" script=\"this.dwQuestID = "..questInfo["dwPrequestID"..i].."\" </text>"
					nCount = nCount + 1
				end
			end
    	end
	end
	if nCount > 0 then
		local szPrevTitle = g_tStrings.TIP_PREQUEST
		if nCount > 1 then
	    	if questInfo.bPrequestLogic then
	    		szPrevTitle = g_tStrings.TIP_PREQUEST_ALL_FINISHED
	    	else
	    		szPrevTitle = g_tStrings.TIP_PREQUEST_ONE_OF
	    	end
	    end
		szTip = szTip.."<Text>text="..EncodeComponentsString(szPrevTitle).." font=100 </text>"..szPrev
	end

	szTip = szTip.."<Text>text="..EncodeComponentsString(g_tStrings.TIP_QUEST_TARGET).." font=100 </text>"

    OutputTip(szTip, 345, Rect, nil, bLink, "quest"..dwQuestID)
    local handle = GetTipHandle(bLink, "quest"..dwQuestID)

    local img = handle:Lookup("accept")
    if img then
    	img:SetFrame(36)
    	img.dwQuestID = dwQuestID
    	img.OnItemMouseEnter = function()
    		local x, y = this:GetAbsPos()
    		local w, h = this:GetSize()
    		OutputTip("<Text>text="..EncodeComponentsString(g_tStrings.QUEST_LOOKUP_ACCEPT_PLACE).." font=100 </text>", 345, {x, y, w, h})
    		this:SetFrame(37)
    	end
    	img.OnItemMouseLeave = function()
    		HideTip()
    		this:SetFrame(36)
    	end
    	img.OnItemLButtonClick = function()
				OnMarkQuestTarget(this.dwQuestID, "accept", 0)
    	end
    end

    local img = handle:Lookup("finish")
    if img then
    	img:SetFrame(32)
    	img.dwQuestID = dwQuestID
    	img.OnItemMouseEnter = function()
    		local x, y = this:GetAbsPos()
    		local w, h = this:GetSize()
    		OutputTip("<Text>text="..EncodeComponentsString(g_tStrings.QUEST_LOOKUP_FINISH_PLACE).." font=100 </text>", 345, {x, y, w, h})
    		this:SetFrame(33)
    	end
    	img.OnItemMouseLeave = function()
    		this:SetFrame(32)
    	end
    	img.OnItemLButtonClick = function()
				OnMarkQuestTarget(this.dwQuestID, "finish", 0)
    	end
    end

    local text = handle:Lookup("prev")
    if text then
    	text.OnItemLButtonClick = function()
			local x, y = this:GetAbsPos()
			local w, h = this:GetSize()
			OutputQuestTip(this.dwQuestID, {x, y, w, h},true)
		end
    end

    local szObjective = tQuestStringInfo.szObjective
	QuestAcceptPanel.EncodeString(handle, szObjective .."\n", 162)

	if questInfo.nFinishTime ~= 0 then
		local szTime = ""
		local h, m, s = GetTimeToHourMinuteSecond(questInfo.nFinishTime)
		if h > 0 then
			szTime = szTime..h..g_tStrings.STR_BUFF_H_TIME_H
		end
		if h > 0 or m > 0 then
			szTime = szTime..m..g_tStrings.STR_BUFF_H_TIME_M_SHORT
		end
		szTime = szTime..s..g_tStrings.STR_BUFF_H_TIME_S
		handle:AppendItemFromString("<text>text="..EncodeComponentsString(g_tStrings.STR_TWO_CHINESE_SPACE..g_tStrings.STR_QUEST_TIME_LIMIT..szTime.."\n").."font=0</text>")
	end

	local MarkQuestTrace = function(hHandle, dwQuestID, szType, nIndex)
		if Table_GetQuestPosInfo(dwQuestID, szType, nIndex) then
			hHandle:AppendItemFromString(GetFormatImage("ui/Image/QuestPanel/QuestPanel.UITex", 40, 35, 24, 341))
			local hImage = hHandle:Lookup(handle:GetItemCount() - 1)
			hImage.dwQuestID = dwQuestID
			hImage.nIndex = nIndex
			hImage.szType = szType
			hImage.OnItemMouseEnter = function()
				this:SetFrame(41)
				local x, y = this:GetAbsPos()
	    		local w, h = this:GetSize()
	    		local szTip = GetFormatText(g_tStrings.QUEST_LOOKUP_TARGET, 100)
	    		OutputTip(szTip, 345, {x, y, w, h})
			end

			hImage.OnItemMouseLeave = function()
				this:SetFrame(40)
			end

			hImage.OnItemLButtonClick = function()
				OnMarkQuestTarget(this.dwQuestID, this.szType, this.nIndex)
			end
		end
	end

	for i = 1, 8, 1 do
		if questInfo["nQuestValue"..i] ~= 0 then
			local szName = tQuestStringInfo["szQuestValueStr" .. i]
			handle:AppendItemFromString(GetFormatText(g_tStrings.STR_TWO_CHINESE_SPACE .. szName .. ": " .. questInfo["nQuestValue"..i], 60))
			MarkQuestTrace(handle, dwQuestID, "quest_state", i - 1)
			handle:AppendItemFromString(GetFormatText("\n"))
		end
	end

	for i = 1, 4, 1 do
		if questInfo["dwKillNpcTemplateID"..i] ~= 0 then
			handle:AppendItemFromString("<text>text="..EncodeComponentsString(
				g_tStrings.STR_TWO_CHINESE_SPACE..Table_GetNpcTemplateName(questInfo["dwKillNpcTemplateID"..i])..": "..questInfo["dwKillNpcAmount"..i]).."font=60</text>")
			MarkQuestTrace(handle, dwQuestID, "kill_npc", i - 1)
			handle:AppendItemFromString(GetFormatText("\n"))
		end
	end

	for i = 1, QUEST_COUNT.QUEST_END_ITEM_COUNT, 1 do
		local dwTab, dwIndex = questInfo["dwEndRequireItemType"..i], questInfo["dwEndRequireItemIndex"..i]
		if dwTab ~= 0 and dwIndex ~= 0 then
			local bHave = false
			for j = 1, i - 1, 1 do
				if questInfo["dwEndRequireItemType"..j] == dwTab and questInfo["dwEndRequireItemIndex"..j] == dwIndex then
					bHave = true
					break
				end
			end
			if not bHave then
				local itemInfo = GetItemInfo(dwTab, dwIndex)
				handle:AppendItemFromString("<text>text="..EncodeComponentsString(
					g_tStrings.STR_TWO_CHINESE_SPACE..ItemData.GetItemNameByItemInfo(itemInfo)..": "..questInfo["dwEndRequireItemAmount"..i]).."font=60</text>")
				MarkQuestTrace(handle, dwQuestID, "need_item", i - 1)
				handle:AppendItemFromString(GetFormatText("\n"))
			end
		end
	end

	QuestAcceptPanel.UpdateHortation(handle, questInfo, false, false, true)

    OutputTip("", 345, Rect, nil, bLink, "quest"..dwQuestID, true)
end

function OutputDLCQuestTip(dwQuestID, Rect, bLink, nStageNumber, nCurrentNumber)
	local questInfo = GetQuestInfo(dwQuestID)
	local szTip = GetFormatText(FormatString(g_tStrings.STR_DLC_PANEL_STAGE_REWARD_TIP, nStageNumber, nCurrentNumber))
	OutputTip(szTip, 400, Rect, nil, bLink, "quest"..dwQuestID)
	local handle = GetTipHandle(bLink, "quest"..dwQuestID)
	QuestAcceptPanel.UpdateHortation(handle, questInfo, false, false, true, nil, nil, true)
	OutputTip("", 400, Rect, nil, bLink, "quest"..dwQuestID, true)
end

function GetQuestSimpleText(dwQuestID, bTip, bRaid)
	local FONT_QUEST_NAME = 59
	local szText = ""
	local hPlayer = GetClientPlayer()
	if not hPlayer then
		return szText
	end
	local tQuestTrace = hPlayer.GetQuestTraceInfo(dwQuestID)
	local tQuestStringInfo = Table_GetQuestStringInfo(dwQuestID)
	if bTip then
		szText = GetFormatText("[" .. tQuestStringInfo.szName .. "]", FONT_QUEST_NAME)
	else
		szText = GetFormatText(tQuestStringInfo.szName, FONT_QUEST_NAME)
	end

	if bRaid then
		return szText
	end

	local szState = ""
	if tQuestTrace.finish then
		szState = g_tStrings.STR_QUEST_QUEST_CAN_FINISH
	elseif tQuestTrace.fail then
		szState = g_tStrings.STR_QUEST_QUEST_WAS_FAILED
	elseif tQuestStringInfo.szQuestDiff then
		local szDifficulty = tQuestStringInfo.szQuestDiff
		if szDifficulty ~= "" then
			szDifficulty = g_tStrings.STR_BRACKET_LEFT..szDifficulty..g_tStrings.STR_BRACKET_RIGHT
		end
		szState = szDifficulty
	end
	szText = szText .. GetFormatText(szState .. "\n", nFont)
	if tQuestTrace.finish then
		return szText
	end

	if tQuestTrace.time then
		local nTime = tQuestTrace.time
		if tQuestTrace.fail then
			nTime = 0
		end
		local szTime = GetTimeText(nTime)
		szText = szText .. GetFormatText(g_tStrings.STR_TWO_CHINESE_SPACE..g_tStrings.STR_QUEST_TIME_LIMIT..szTime.."\n")
	end

	for k, v in pairs(tQuestTrace.quest_state) do
		if v.have < v.need then
			local szName = tQuestStringInfo["szQuestValueStr" .. (v.i + 1)]
			local szTarget = g_tStrings.STR_TWO_CHINESE_SPACE..szName..": "..v.have.."/"..v.need
			szText = szText ..  GetFormatText(szTarget .. "\n", FONT_QUEST_TARGET_NOT_FINISH)
		end
	end

	local bKillNpc = false
	for k, v in pairs(tQuestTrace.kill_npc) do
		if v.have < v.need then
			local szName = Table_GetNpcTemplateName(v.template_id)
			if not szName or szName == "" then
				szName = "Unknown Npc"
			end
			local szTarget = g_tStrings.STR_TWO_CHINESE_SPACE.. szName ..": "..v.have.."/"..v.need
			szText = szText ..  GetFormatText(szTarget .. "\n", FONT_QUEST_TARGET_NOT_FINISH)
		end
	end

	for k, v in pairs(tQuestTrace.need_item) do
		local itemInfo = GetItemInfo(v.type, v.index)
		local nBookID = v.need
		if itemInfo.nGenre == ITEM_GENRE.BOOK then
			v.need = 1
		end
		if v.have < v.need then
			local szName = "Unknown Item"
			if itemInfo then
				szName = ItemData.GetItemNameByItemInfo(itemInfo, nBookID)
			end
			local szTarget = g_tStrings.STR_TWO_CHINESE_SPACE.. szName ..": "..v.have.."/"..v.need
			szText = szText ..  GetFormatText(szTarget .. "\n", FONT_QUEST_TARGET_NOT_FINISH)
		end
	end

	return szText
end

local function AddTable(tTable, tAdd)
	for i, nQuesIndex in pairs(tAdd) do
		table.insert(tTable, nQuesIndex)
	end
end

function GetQuestTree()
	local pPlayer = GetClientPlayer()
	if not pPlayer then
		return
	end

	local tDLCQuest, tClassQuest = {}, {}
	local aQuest = pPlayer.GetQuestTree()
	for _, tQuest in pairs(aQuest) do
		for i, nQuesIndex in pairs(tQuest) do
			local dwQuestID = pPlayer.GetQuestID(nQuesIndex)
			if Table_IsActivityPanelQuest(dwQuestID) then --任务不在任务面板显示，只在活动日历显示
				tQuest[i] = nil
			end
		end
	end
	for dwClassID, tQuest in pairs(aQuest) do
		local tLine = g_tTable.QuestClass:Search(dwClassID)
		if tLine and tLine.dwMapID ~= 0 and tLine.dwDLCID ~= 0 then
			local dwDLCID = tLine.dwDLCID
			local dwMapID = tLine.dwMapID
			tDLCQuest[dwDLCID] = tDLCQuest[dwDLCID] or {}
			tDLCQuest[dwDLCID][dwMapID] = tDLCQuest[dwDLCID][dwMapID] or {}
			AddTable(tDLCQuest[dwDLCID][dwMapID], tQuest)
		else
			tClassQuest[dwClassID] = tClassQuest[dwClassID] or {}
			AddTable(tClassQuest[dwClassID], tQuest)
		end
	end
	return tDLCQuest, tClassQuest
end

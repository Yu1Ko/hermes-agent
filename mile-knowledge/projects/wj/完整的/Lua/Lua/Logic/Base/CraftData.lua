if not CraftData then CraftData = {className = "CraftData"} end

CraftData.CraftDoodadNavigation = {
	[1] = {nLinkIDList = {2692}, szName = "采金"},
	[2] = {nLinkIDList = {2693}, szName = "神农"},
	[3] = {nLinkIDList = {2694}, szName = "庖丁"},
    [6] = {nLinkIDList = {816,818}, szName = "铸造"},
    [7] = {nLinkIDList = {809,810}, szName = "医术"},
    [4] = {nLinkIDList = {803,804,805,806}, szName = "烹饪"},
	[5] = {nLinkIDList = {811,814}, szName = "缝纫"},
	[15] = {nLinkIDList = {2669,2670,2671}, szName = "梓匠"},
}

CRAFT_PANEL = {
    Collect     = 1,    -- 采集
    Foundry     = 2,    -- 铸造
    Medical     = 3,    -- 医术
    Cooking     = 4,    -- 烹饪
    Sewing      = 5,    -- 缝纫
    Carpentry   = 6,    -- 梓匠
    Demosticate = 7,    -- 驯养
}

CRAFT_TYPE = {
    Mine        = 1,    -- 采金
    Gather      = 2,    -- 神农
    Dissect     = 3,    -- 庖丁
    Foundry     = 4,    -- 铸造
    Medical     = 5,    -- 医术
    Cooking     = 6,    -- 烹饪
    Sewing      = 7,    -- 缝纫
    Carpentry   = 8,    -- 梓匠
    Demosticate = 9,    -- 驯养
}

UICraftMainButtonTab = {
    [CRAFT_TYPE.Mine] = {
        szName = "采金",
        nProfessionID = 1,
		nCraftPanelID = CRAFT_PANEL.Collect,
        szIconPath = "UIAtlas2_Life_Life2_Icon_CaiJin",
		szTraceIcon = "UIAtlas2_Public_PublicIcon_PublicIcon1_btn_mineral",
        fCallCack = function ()
            UIMgr.Open(VIEW_ID.PanelLifePage, {
                nDefaultCraftPanel = CRAFT_PANEL.Collect,
                nDefaultProfessionID = 1,
            })
        end
    },
    [CRAFT_TYPE.Gather] = {
        szName = "神农",
        nProfessionID = 2,
		nCraftPanelID = CRAFT_PANEL.Collect,
        szIconPath = "UIAtlas2_Life_Life2_Icon_ShenNong",
		szTraceIcon = "UIAtlas2_Public_PublicIcon_PublicIcon1_btn_herb",
        fCallCack = function ()
            UIMgr.Open(VIEW_ID.PanelLifePage, {
                nDefaultCraftPanel = CRAFT_PANEL.Collect,
                nDefaultProfessionID = 2,
            })
        end
    },
    [CRAFT_TYPE.Dissect] = {
        szName = "庖丁",
        nProfessionID = 3,
		nCraftPanelID = CRAFT_PANEL.Collect,
        szIconPath = "UIAtlas2_Life_Life2_Icon_PaoDing",
		szTraceIcon = "UIAtlas2_Public_PublicIcon_PublicIcon1_icon_paoding",
        fCallCack = function ()
            UIMgr.Open(VIEW_ID.PanelLifePage, {
                nDefaultCraftPanel = CRAFT_PANEL.Collect,
                nDefaultProfessionID = 3,
            })
        end
    },
    [CRAFT_TYPE.Foundry] = {
        szName = "铸造",
        nProfessionID = 6,
		nCraftPanelID = CRAFT_PANEL.Foundry,
        szIconPath = "UIAtlas2_Life_Life2_Icon_ZhuZao",
        fCallCack = function ()
            UIMgr.Open(VIEW_ID.PanelLifePage, {
                nDefaultCraftPanel = CRAFT_PANEL.Foundry,
                nDefaultProfessionID = 6,
            })
        end
    },
    [CRAFT_TYPE.Medical] = {
        szName = "医术",
        nProfessionID = 7,
		nCraftPanelID = CRAFT_PANEL.Medical,
        szIconPath = "UIAtlas2_Life_Life2_Icon_YiShu",
        fCallCack = function ()
            UIMgr.Open(VIEW_ID.PanelLifePage, {
                nDefaultCraftPanel = CRAFT_PANEL.Medical,
                nDefaultProfessionID = 7,
            })
        end
    },
    [CRAFT_TYPE.Cooking] = {
        szName = "烹饪",
        nProfessionID = 4,
		nCraftPanelID = CRAFT_PANEL.Cooking,
        szIconPath = "UIAtlas2_Life_Life2_Icon_PengRen",
        fCallCack = function ()
            UIMgr.Open(VIEW_ID.PanelLifePage, {
                nDefaultCraftPanel = CRAFT_PANEL.Cooking,
                nDefaultProfessionID = 4,
            })
        end
    },
    [CRAFT_TYPE.Sewing] = {
        szName = "缝纫",
        nProfessionID = 5,
		nCraftPanelID = CRAFT_PANEL.Sewing,
        szIconPath = "UIAtlas2_Life_Life2_Icon_FengRen",
        fCallCack = function ()
            UIMgr.Open(VIEW_ID.PanelLifePage, {
                nDefaultCraftPanel = CRAFT_PANEL.Sewing,
                nDefaultProfessionID = 5,
            })
        end
    },
    [CRAFT_TYPE.Carpentry] = {
        szName = "梓匠",
        nProfessionID = 15,
		nCraftPanelID = CRAFT_PANEL.Carpentry,
        szIconPath = "UIAtlas2_Life_Life2_Icon_ZiJiang",
        fCallCack = function ()
            UIMgr.Open(VIEW_ID.PanelLifePage, {
                nDefaultCraftPanel = CRAFT_PANEL.Carpentry,
                nDefaultProfessionID = 15,
            })
        end
    },
    [CRAFT_TYPE.Demosticate] = {
        szName = "驯养",
		nCraftPanelID = CRAFT_PANEL.Demosticate,
        szIconPath = "UIAtlas2_Life_Life2_Icon_XunYang",
        fCallCack = function ()
            UIMgr.Open(VIEW_ID.PanelLifePage, {
                nDefaultCraftPanel = CRAFT_PANEL.Demosticate,
            })
        end
    },
}

CraftData.CraftID2CraftPanelID = {
	[1] = CRAFT_PANEL.Collect,
	[2] = CRAFT_PANEL.Collect,
	[3] = CRAFT_PANEL.Collect,
	[4] = CRAFT_PANEL.Cooking,
	[5] = CRAFT_PANEL.Sewing,
	[6] = CRAFT_PANEL.Foundry,
	[7] = CRAFT_PANEL.Medical,
	[15] = CRAFT_PANEL.Carpentry,
}

CraftData.tCustomData = {
	bAutoSelectLearned = false, -- 吴鹏要求玩家首次登录自动设置成已学会
}

function CraftData.Init()
	local szPath = "scripts/Craft/Include/CraftData.ls"
	LoadScriptFile(szPath, CraftData)

	CraftData.InitCollectTable()
end

-- 构建工作台Doodad模板ID到ProfessionID的映射
function CraftData.InitCraftDoodadTemplateID2ProfessionID()
	if CraftData.bInitCraftDoodad then
		return
	end
	local player = g_pClientPlayer
	if not player then
		return
	end
	CraftData.CraftDoodadTemplateID2ProfessionID = {}
	for dwProfessionID,_ in pairs(CraftData.CraftDoodadNavigation) do
		local tRecipeList = player.GetRecipe(dwProfessionID)
		for _, tInfo in ipairs(tRecipeList) do
			local recipe = GetRecipe(tInfo.CraftID, tInfo.RecipeID)
			if recipe then
				CraftData.CraftDoodadTemplateID2ProfessionID[recipe.dwRequireDoodadID] = dwProfessionID
			end
		end
	end

	CraftData.bInitCraftDoodad = true
end

function CraftData.Craft_GetGuideNpcMap(dwTemplateID)
	local tInfo = Table_GetCraftNpcInfo(dwTemplateID)
	if tInfo and tInfo.dwMapID > 0 then
		return tInfo.dwMapID
	end
end

function CraftData.Craft_GetGuideDoodadMap(dwTemplateID)
	local tMapList = {}
	local tInfo = Table_GetCraftDoodadInfo(dwTemplateID)
	if tInfo then
		for i = 1, 3 do
			local szKey = "dwMapID" .. i
			if tInfo[szKey] > 0 then
				table.insert(tMapList, tInfo[szKey])
			end
		end
	end
	return tMapList
end

function CraftData.Craft_GetDoodadPos(dwMapID, dwTemplateID)
	local tSourcePos = Quest_GetNDInfo("D", dwMapID, dwTemplateID, 0)
	if not tSourcePos then
		return
	end
	local tPos = StringParse_Numbers(tSourcePos.szPositions)
	if tPos and #tPos > 0 then
		return tPos[1]
	end
end

function CraftData.Craft_GetNpcPos(dwMapID, dwTemplateID)
	local tSourcePos = Quest_GetNDInfo("N", dwMapID, dwTemplateID, 0)
	if not tSourcePos then
		return
	end
	local tPos = StringParse_Numbers(tSourcePos.szPositions)
	if tPos and #tPos > 0 then
		return tPos[1]
	end
end

function CraftData.RegisterTablePath(dwMapID, szTitle, tPath, szSuffix)
	local szPath = tPath.Path .. dwMapID .. szSuffix
	local bExist = IsFileExist(szPath)

	if bExist and not IsUITableRegister(szTitle) then
        RegisterUITable(szTitle, szPath, tPath.Title)
    end

	return bExist
end

local function RegisterCraftGuidePos(dwMapID, szTitle, szTitleDoodad, szTitleNpc) -- 策划希望坐标数据沿用任务追踪表
	local bIsCraftGuideExist = CraftData.RegisterTablePath(dwMapID, szTitle, g_tCraftMapGuide, ".tab")
	local bIsQuestDoodadExist = CraftData.RegisterTablePath(dwMapID, szTitleDoodad, g_tQuestDoodad, ".txt")
	local bIsQuestNpcExist = CraftData.RegisterTablePath(dwMapID, szTitleNpc, g_tQuestNpc, ".txt")

	return bIsCraftGuideExist, bIsQuestDoodadExist, bIsQuestNpcExist
end

function CraftData.Craft_GetGuidePosList(dwMapID, nAreaID)
    local szTitle = "CraftMapGuide" .. dwMapID
    local szTitleDoodad = "QuestDoodad" .. dwMapID
	local szTitleNpc = "QuestNpc" .. dwMapID

    local bIsCraftGuideExist, bIsQuestDoodadExist, bIsQuestNpcExist = RegisterCraftGuidePos(dwMapID, szTitle, szTitleDoodad, szTitleNpc)
	if not bIsCraftGuideExist or not bIsQuestDoodadExist or not bIsQuestNpcExist then
        return
    end

    local tCraftMapGuide = g_tTable[szTitle]
    local tQuestDoodadPos = g_tTable[szTitleDoodad]
	local tQuestNpcPos = g_tTable[szTitleNpc]
    if not tCraftMapGuide or not tQuestDoodadPos or not tQuestNpcPos then
        return
    end

    local tResults = {}
    local nRow = tCraftMapGuide:GetRowCount()
    for i = 2, nRow do
        local tLine = tCraftMapGuide:GetRow(i)
        local dwTemplateID = tLine.dwTemplateID
        nAreaID = nAreaID or 0
		if tLine.bNpc then
			local tQuestPos = tQuestNpcPos:Search(dwTemplateID, nAreaID)
			if tQuestPos and tQuestPos.szPositions ~= "" then
				local tResultPos = StringParse_Numbers(tQuestPos.szPositions)
				local tInfo = Table_GetCraftNpcInfo(tLine.dwTemplateID)
				local szName = Table_GetNpcTemplateName(tLine.dwTemplateID)
				table.insert(tResults, {
					dwID = tInfo.dwTemplateID,
					nCraftID = tInfo.nCraftID,
					szName = tInfo.szName,
					nTemplateType = tInfo.nTemplateType,
					nAreaID = tLine.nAreaID,
					tPos = tResultPos,
					bNpc = true,
					szKey = tInfo.dwTemplateID .. "_1"
				})
			end
		else
			local tQuestPos = tQuestDoodadPos:Search(dwTemplateID, nAreaID)
			if tQuestPos and tQuestPos.szPositions ~= "" then
				local tResultPos = StringParse_Numbers(tQuestPos.szPositions)
				local tInfo = Table_GetCraftDoodadInfo(tLine.dwTemplateID)
				local szName = Table_GetDoodadName(tLine.dwTemplateID, 0)
				table.insert(tResults, {
					dwID = tInfo.dwTemplateID,
					nCraftID = tInfo.nCraftID,
					szName = szName,
					nTemplateType = tInfo.nTemplateType,
					nAreaID = tLine.nAreaID,
					tPos = tResultPos,
					bNpc = false,
					szKey = tInfo.dwTemplateID .. "_0"
				})
			end
		end
    end
    return tResults
end

function CraftData.CreateQuestTips(szLinkArg)
	local szQuestID, szLink = szLinkArg:match("(%w+)/(%w+)")
	local dwQuestID = tonumber(szQuestID)
	local bLink = tonumber(szLink) == 1
	-- UIMgr.Open(VIEW_ID.PanelSentTaskDetails, dwQuestID)
	UIMgr.OpenSingleWithOnEnter(false, VIEW_ID.PanelSentTaskDetails, dwQuestID)
end

function CraftData.CraftMarkNpc(szLinkArg)
    local szMapID, szTemplateID = szLinkArg:match("(%w+)/(%w+)")
    local dwMapID = tonumber(szMapID)
    local dwTemplateID = tonumber(szTemplateID)
    local szNpcName = Table_GetNpcTemplateName(dwTemplateID)
    szNpcName = UIHelper.GBKToUTF8(szNpcName)
    local tPos = CraftData.Craft_GetNpcPos(dwMapID, dwTemplateID)

    local tInfo = Table_GetCraftNpcInfo(dwTemplateID)
    if tInfo then
		local tbConfig = UICraftMainButtonTab[tInfo.nCraftID]
        MapMgr.AddCraftInfo(dwTemplateID, tInfo.nCraftID)
        MapMgr.SetShowCraft(true)
		MapMgr.SetTracePoint(szNpcName, dwMapID, tPos, nil, tbConfig.szTraceIcon)
    else
        MapMgr.SetShowCraft(false)
		MapMgr.SetTracePoint(szNpcName, dwMapID, tPos)
    end

    UIMgr.Open(VIEW_ID.PanelMiddleMap, dwMapID, 0)
end

function CraftData.CraftOpenFacture(szLinkArg)
	local szCraftID, szRecipeID = szLinkArg:match("(%w+)/(%w+)")
	local dwCraftID = tonumber(szCraftID) or 0
	local dwRecipeID = tonumber(szRecipeID) or 0
	local Craft = GetCraft(dwCraftID)
	local nCraftPanelID = CraftData.CraftID2CraftPanelID[dwCraftID] or 1
	local tParam = {
		nDefaultCraftPanel = nCraftPanelID,
		nDefaultProfessionID = Craft.ProfessionID,
		dwCraftID = dwCraftID,
		dwRecipeID = dwRecipeID
	}
	local nTopViewID = UIMgr.GetLayerTopViewID(UILayer.Page)
	local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelLifePage)
	if not scriptView then
		UIMgr.Open(VIEW_ID.PanelLifePage, tParam)
	elseif nTopViewID == VIEW_ID.PanelLifePage then
		scriptView:OnEnter(tParam)
	else
		UIMgr.CloseWithCallBack(VIEW_ID.PanelLifePage, function ()
			UIMgr.Open(VIEW_ID.PanelLifePage, tParam)
		end)
	end
end

function CraftData.CraftMarkDoodad(szLinkArg)
	local szMapID, szTemplateID = szLinkArg:match("(%w+)/(%w+)")
	local dwMapID = tonumber(szMapID)
	local dwTemplateID = tonumber(szTemplateID)
	local szDoodadName = Table_GetDoodadName(dwTemplateID, 0)
	szDoodadName = UIHelper.GBKToUTF8(szDoodadName)
	local tPos = CraftData.Craft_GetDoodadPos(dwMapID, dwTemplateID)

	local tInfo = Table_GetCraftDoodadInfo(dwTemplateID)
    if tInfo then
        MapMgr.AddCraftInfo(dwTemplateID, tInfo.nCraftID)
        MapMgr.SetShowCraft(true)
    else
        MapMgr.SetShowCraft(false)
    end

	local tbConfig = tInfo and UICraftMainButtonTab[tInfo.nCraftID] or {}
	MapMgr.SetTracePoint(szDoodadName, dwMapID, tPos, nil, tbConfig.szTraceIcon)
	UIMgr.Open(VIEW_ID.PanelMiddleMap, dwMapID, 0)
end

function CraftData.OpenMiddleMap(szLinkArg)
	local szMapID, _ = szLinkArg:match("(%w+)/(%w+)")
	local dwMapID = tonumber(szMapID)
	UIMgr.Open(VIEW_ID.PanelMiddleMap, dwMapID, 0)
end

function CraftData.OpenDungeonBossView(szLinkArg)
	local szMapID, szBossIndex = szLinkArg:match("(%w+)/(%w+)")
	local dwMapID = tonumber(szMapID) or tonumber(szLinkArg)
	local dwBossIndex = tonumber(szBossIndex)
	local tDungeonInfo = Table_GetDungeonInfo(dwMapID)
	local tRecord = {
		dwMapID = dwMapID,
		szName = tDungeonInfo.szOtherName,
		--dwDefaultBossIndex = dwBossIndex,
	}

	if not UIMgr.IsViewOpened(VIEW_ID.PanelDungeonInfo, true) then
		UIMgr.Open(VIEW_ID.PanelDungeonInfo, tRecord)
	else
		UIMgr.CloseWithCallBack(VIEW_ID.PanelDungeonInfo, function ()
			UIMgr.Open(VIEW_ID.PanelDungeonInfo, tRecord)
		end)
	end
end

function CraftData.OpenDungeonEntranceView(szLinkArg)
	local szMapID, szBossIndex = szLinkArg:match("(%w+)/(%w+)")
	local dwMapID = tonumber(szMapID) or tonumber(szLinkArg)
	local tRecord = {
		dwTargetMapID = dwMapID,
		bRecommendOnly = false,
		bNeedChooseFirst = false
	}

	if not UIMgr.IsViewOpened(VIEW_ID.PanelDungeonEntrance, true) then
		UIMgr.Open(VIEW_ID.PanelDungeonEntrance, tRecord)
	else
		UIMgr.CloseWithCallBack(VIEW_ID.PanelDungeonEntrance, function ()
			UIMgr.Open(VIEW_ID.PanelDungeonEntrance, tRecord)
		end)
	end
end

function CraftData.ParseSource(szSource)
	local tSource = {}
	local tTemp =  SplitString(szSource, ";")
	for _, v in ipairs(tTemp) do
		local t = SplitString(v, "-")
		local dwParam1 =  tonumber(t[1] or "")
		local dwParam2 =  tonumber(t[2] or "")
		table.insert(tSource, {dwParam1, dwParam2})
	end
	return tSource
end

function CraftData.OpenSingleBookView(nBookID, nSegmentID)
	local player = GetClientPlayer()
	if not player then
		return
	end
	local tLine = g_tTable.BookSegment:Search(nBookID, nSegmentID)
	if not tLine then
		return
	end

	local tSourceMap = SplitString(tLine.szSourceMap, ";")
	local tAchievement = SplitString(tLine.szAchievement, ";")
	local tDoodad = CraftData.ParseSource(tLine.szSourceDoodad)
	local tNpc = CraftData.ParseSource(tLine.szSourceNpc)
	local tBoss = CraftData.ParseSource(rotLinew.szSourceBoss)
	local tQuests = SplitString(tLine.szSourceQuest, ";")

	local tBook = {
		tQuests         = tQuests,
		tSourceNpc      = tNpc,
		tSourceMap      = tSourceMap,
		tDoodad         = tDoodad,
		tBoss           = tBoss,
		tAchievement    = tAchievement,
	}
	local bIsBookMemorized = player.IsBookMemorized(nBookID, nSegmentID)
	if bIsBookMemorized then
		UIMgr.Open(VIEW_ID.PanelBookInfo, nBookID, nSegmentID, tBook, function ()
		end)
	else
		local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelBookInfo)
		if scriptView == nil then
			scriptView = UIMgr.Open(VIEW_ID.PanelBookInfo)
		end
		scriptView:OnEnterUnreadBook(nBookID, nSegmentID, tBook, function ()
		end)
	end
end

function CraftData.OpenManufactureViewWithDoodadTemplateID(dwDoodadTemplateID)
	local dwProfessionID = CraftData.CraftDoodadTemplateID2ProfessionID[dwDoodadTemplateID]
	if not dwProfessionID then
		return
	end

	UIMgr.Open(VIEW_ID.PanelLifePage, {
		nDefaultCraftPanel = CRAFT_PANEL.Collect,
		nDefaultProfessionID = dwProfessionID
	})
end

function CraftData.BookNameOptimize(szName)
	szName = string.gsub(szName, "【", "︻")
    szName = string.gsub(szName, "】", "︼")
	szName = string.gsub(szName, "（", "︵")
    szName = string.gsub(szName, "）", "︶")
    szName = string.gsub(szName, "“", "﹁")
    szName = string.gsub(szName, "”", "﹂")
	szName = string.gsub(szName, "%[", "﹁")
    szName = string.gsub(szName, "%]", "﹂")
	szName = string.gsub(szName, "：", "‥")
	return szName
end

function CraftData.ParseSourceCollect(szSource)
	local tResult = {}
	local szCraftID, szSource = string.match(szSource, "([%d]+)|([%d,;]+)")
	if szCraftID and szSource then
		tResult = SplitString(szSource, ";")
		tResult.dwCraftID = tonumber(szCraftID)
	end

	return tResult
end

function CraftData.Item_SortSource(tSource)
	local dwCurrentMapID = UI_GetCurrentMapID()
	local tResult = {}
	for k, v in ipairs(tSource) do
		local dwMapID
		if type(v) == "table" then
			dwMapID = tonumber(v[1])
		else
			dwMapID = tonumber(v)
		end
		local nSort = 1
		if dwMapID == dwCurrentMapID then
			nSort = 2
		end
		table.insert(tResult, {nIndex = k, nSort = nSort, Value = v})
	end
	local fnSort = function(a, b)
		if a.nSort == b.nSort then
			return a.nIndex < b.nIndex
		end

		return a.nSort > b.nSort
	end
	table.sort(tResult, fnSort)

	return tResult
end

function CraftData.GetSourceProduceInfoList(tProduce, nMapLimitCount)
	if #tProduce <= 0 then
		return
	end

	local tInfoList = {}
	local dwCraftID = tProduce.dwCraftID
	for k, dwRecipeID in ipairs(tProduce) do
		if nMapLimitCount and k > nMapLimitCount then
			break
		end
		local szRecipeName = Table_GetRecipeName(dwCraftID, dwRecipeID)
		if szRecipeName then
			local szText = string.format("[%s]", szRecipeName)
			local szLinkInfo = string.format("Craft/%d/%d", dwCraftID, dwRecipeID)
			table.insert(tInfoList, {
				szText = szText,
				szLinkInfo = szLinkInfo,
			})
		end
	end

	return tInfoList
end

function CraftData.GetSourceCollectDInfoList(tSourceCollectD, nMapLimitCount)
	if #tSourceCollectD <= 0 then
		return
	end

	local tInfoList = {}
	for k, v in ipairs(tSourceCollectD) do
		local dwTemplateID = tonumber(v)
		local tMapList = CraftData.Craft_GetGuideDoodadMap(dwTemplateID)

		local tResult = CraftData.Item_SortSource(tMapList)
		for k1, v1 in ipairs(tResult) do
			if nMapLimitCount and k1 > nMapLimitCount then
				break
			end
			local dwMapID = v1.Value
			if dwMapID then
				local szMapName = Table_GetMapName(dwMapID)
				szMapName = UIHelper.GBKToUTF8(szMapName)
				if szMapName then
					local szText = "["..szMapName .. "]"
					local szLinkInfo = string.format("CraftMarkCollectD/%d/%d", dwMapID, dwTemplateID)
					table.insert(tInfoList, {
						dwMapID = dwMapID,
						dwDoodadTemplateID = dwTemplateID,
						szText = szText,
						szLinkInfo = szLinkInfo,
					})
				end
			end
		end
	end
	return tInfoList
end

function CraftData.GetSourceCollectNInfoList(tSourceCollectN, nMapLimitCount)
	if #tSourceCollectN <= 0 then
		return
	end

	local tInfoList = {}
	local tResult = CraftData.Item_SortSource(tSourceCollectN)
	for k, v in ipairs(tResult) do
		if nMapLimitCount and k > nMapLimitCount then
			break
		end
		local Value = v.Value
		local dwMapID = Value[1]
		local dwTemplateID = tonumber(Value[2])
		if dwMapID and dwTemplateID then
			local szNpcName = Table_GetNpcTemplateName(dwTemplateID)
			local szMapName = Table_GetMapName(dwMapID)
			szNpcName = UIHelper.GBKToUTF8(szNpcName)
			szMapName = UIHelper.GBKToUTF8(szMapName)
			local szText = string.format("[%s](%s)", szNpcName, szMapName)
			local szLinkInfo = string.format("CraftMarkCollectN/%d/%d", dwMapID, dwTemplateID)
			table.insert(tInfoList, {
				dwMapID = dwMapID,
				szText = szText,
				szLinkInfo = szLinkInfo,
			})
		end
	end
	return tInfoList
end

local function RegisterTablePath(dwMapID, szTitle, tPath, szSuffix)
	local szPath = tPath.Path .. dwMapID .. szSuffix
	local bExist = IsFileExist(szPath)

	if bExist and not IsUITableRegister(szTitle) then
        RegisterUITable(szTitle, szPath, tPath.Title)
    end

	return bExist
end

function CraftData.InitCollectTable()
	CraftData.tbCollectTable = {}

    local tRecommendMap = {}
	local tbKey = {
		[5] = "ItemSourceList_5",
		[8] = "ItemSourceList_8",
		[10] = "ItemSourceList_10",
	}

	for dwTabType, key in pairs(tbKey) do
		if not IsUITableRegister(key) then
			RegisterUITable(key, g_tItemSourceList.Path .. dwTabType .. ".txt", g_tItemSourceList.Title)
		end

		local nCount = g_tTable[key]:GetRowCount()
		for i = 2, nCount do
			local tItemSource = g_tTable[key]:GetRow(i)
			if #tItemSource.szSourceProduce > 0 or #tItemSource.szSourceCollectD > 0 or #tItemSource.szSourceCollectN > 0 then
				local tItemInfo = GetItemInfo(tItemSource.dwItemType, tItemSource.dwItemIndex)
				local tSourceProduce = CraftData.ParseSourceCollect(tItemSource.szSourceProduce)
				local tSourceCollectD = CraftData.ParseSourceCollect(tItemSource.szSourceCollectD)
				local tCollectN = CraftData.ParseSourceCollect(tItemSource.szSourceCollectN)
				local tSourceCollectN = {}
				for _, v in ipairs(tCollectN) do
					local dwTemplateID = v
					local dwMapID = CraftData.Craft_GetGuideNpcMap(dwTemplateID)
					table.insert(tSourceCollectN, {dwMapID, dwTemplateID})
				end
				tSourceCollectN.dwCraftID = tCollectN.dwCraftID
				local tSource = {
					szName = UIHelper.GBKToUTF8(tItemInfo.szName),
					dwItemType = tItemSource.dwItemType,
					dwItemIndex = tItemSource.dwItemIndex,
					tAllDoodadTemplateIDMap = {},
					tAllMapIDMap = {},

					tProduceInfoList = CraftData.GetSourceProduceInfoList(tSourceProduce),
					tCollectDInfoList = CraftData.GetSourceCollectDInfoList(tSourceCollectD),
					tCollectNInfoList = CraftData.GetSourceCollectNInfoList(tSourceCollectN),
				}
				for _, tInfo in ipairs(tSource.tCollectDInfoList) do
					tSource.tAllMapIDMap[tInfo.dwMapID] = true
					tRecommendMap[tInfo.dwMapID] = true
					tInfo.bRecommend = true
					tSource.tAllDoodadTemplateIDMap[tInfo.dwDoodadTemplateID] = true
				end
				for idx, tInfo in ipairs(tSource.tCollectNInfoList) do
					if idx > 3 then
						break
					end
					tInfo.bRecommend = true
				end
				local itemInfo = ItemData.GetItemInfo(tItemSource.dwItemType, tItemSource.dwItemIndex)
				if itemInfo then
					tSource.nCraftItemID = itemInfo.nUiId
					tSource.szDesc = UIHelper.GBKToUTF8(Table_GetItemDesc(itemInfo.nUiId))
					tSource.szDesc = string.pure_text(tSource.szDesc or "")
				end
				tSource.dwCraftID = tSourceProduce.dwCraftID or tSourceCollectD.dwCraftID or tSourceCollectN.dwCraftID
				CraftData.tbCollectTable[tSource.dwCraftID] = CraftData.tbCollectTable[tSource.dwCraftID] or {}
				table.insert(CraftData.tbCollectTable[tSource.dwCraftID], tSource)
			end
		end
	end

	for _, dwMapID in ipairs(Table_GetAllMapIDs()) do
		local szTitle = "CraftMapGuide" .. dwMapID
		if RegisterTablePath(dwMapID, szTitle, g_tCraftMapGuide, ".tab") then
			local nCount = g_tTable[szTitle]:GetRowCount()
			for i = 2, nCount do
				local tLine = g_tTable[szTitle]:GetRow(i)
				local dwTemplateID = tLine.dwTemplateID
				if dwTemplateID and not tLine.bNpc then
					local nCraftID = Table_GetCraftDoodadID(dwTemplateID)
					if nCraftID then
						for _, tSource in ipairs(CraftData.tbCollectTable[nCraftID]) do
							if not tSource.tAllMapIDMap[dwMapID] and tSource.tAllDoodadTemplateIDMap[dwTemplateID] then
								tSource.tAllMapIDMap[dwMapID] = true
								local szMapName = Table_GetMapName(dwMapID)
								szMapName = UIHelper.GBKToUTF8(szMapName)
								local tExtraCollectDInfo = {
									dwMapID = dwMapID,
									dwDoodadTemplateID = dwTemplateID,
									szText = string.format("[%s]", szMapName),
									szLinkInfo = string.format("CraftMarkCollectD/%d/%d", dwMapID, dwTemplateID)
								}
								table.insert(tSource.tCollectDInfoList, tExtraCollectDInfo)
							end
						end
					end
				end
			end
		end
	end
end

Event.Reg(CraftData, EventType.OnClientPlayerEnter, function()
	CraftData.InitCraftDoodadTemplateID2ProfessionID()
end)

Event.Reg(CraftData, EventType.OnRoleLogin, function()
	CraftData.szLastReadSearchKey = nil
	FilterDef.SelfRead.Reset()
end)

Event.Reg(CraftData, "DO_CUSTOM_OTACTION_PROGRESS", function()--神行读进度条关闭界面
	UIMgr.Close(VIEW_ID.PanelLifePage)
	UIMgr.Close(VIEW_ID.PanelLifeMain)
	UIMgr.Close(VIEW_ID.PanelSystemMenu)
	UIMgr.Close(VIEW_ID.PanelGongZhanSide)
	UIMgr.Close(VIEW_ID.PanelOperationCenter)

end)

CustomData.Register(CustomDataType.Role, "CraftData", CraftData.tCustomData)
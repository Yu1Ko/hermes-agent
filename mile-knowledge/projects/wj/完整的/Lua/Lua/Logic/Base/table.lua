-- UI table 对外接口
require("Lua/Logic/Base/table_mgr.lua")

local tTableFile = g_tTableFile

local BATTLE_FIELD_GROUP_COUNT = 4
local BATTLE_FIELD_PQOPTIONICON_COUNT = 4
local PQOBJECTIVE_COUNT = 8
local SUGGEST_QUEST_AREA_COUNT = 22
local SUGGEST_COPY_COUNT = 20
local SUGGEST_BATTLE_FIELD_COUNT = 10
local CAREER_MAP_LIMIT_COUNT = 5
local CAREER_TAP_COUNT = 8
local CAREER_IMAGE_COUNT = 3
local PET_SKILL_COUNT = 15
local PUPPET_SKILL_COUNT = 8
local TEACH_SKILL_QIXUE_RECOMMEND = 6
local DODGE_SKILL_COUNT = 6

local tAllSceneQuest = nil
local tAllSceneQuestFormated = nil
local tMapNPCToQuest = nil
local tAllSceneFieldPQ = {}
local tAllSkillRecipeMap = {}
local tEnchantTipShow = nil
local Log = LOG.ERROR

---comment 注册ui表到table_defs中
---@param szKey string 表名
---@param szPath string 路径
---@param tTitle table 标题列表
---@param nKeyNum integer|nil 键值数量
function RegisterUITable(szKey, szPath, tTitle, nKeyNum)
	if tTableFile[szKey] then
		Log("table file szKey = " .. szKey .. " is aleady Exist, please check")
	else
		tTableFile[szKey] = {}
	end

	tTableFile[szKey].KeyNum = nKeyNum
	tTableFile[szKey].Path = szPath
	tTableFile[szKey].Title = tTitle
end

---comment 替换table_defs定义的ui表
---@param szKey string 表名
---@param szPath string 路径
---@param tTitle table 标题列表
---@param nKeyNum integer|nil 键值数量
function ReplaceUITable(szKey, szPath, tTitle, nKeyNum)
	g_tTable[szKey] = nil	-- 清理已经加载的表

	tTableFile[szKey] = {	-- 覆盖表配置
		nKeyNum = nKeyNum,
		Path = szPath,
		Title = tTitle,
	}
end

---comment UI表是否已经注册
---@param szKey string 表名
---@return boolean
function IsUITableRegister(szKey)
	if tTableFile[szKey] then
		return true
	end
	return false
end

if IsDebugClient() then
	GetBinTableTitle = function(szKey)
	 	if tTableFile[szKey] then
	 		return tTableFile[szKey].Title
	 	end
	end
end

--------------------------------------------------------------------------------------------------------
local function GetTempDir(bNotExistThenMake)
	local fileUtil = cc.FileUtils:getInstance()
	local wp = fileUtil:getWritablePath()
	local dirPath = string.format("%s%s", wp, "temp")

	if bNotExistThenMake then
		if fileUtil:isDirectoryExist(dirPath) then
			fileUtil:createDirectory(dirPath)
		end
	end

	return dirPath
end

local function ParsePointList(szPoint)
	local tList = {}
	for szIndex in string.gmatch(szPoint, "([%d-]+)") do
		local nPoint = tonumber(szIndex)
		table.insert(tList, nPoint)
	end
	return tList
end

local function ParseIDList(szList)	-- x;y;z
	local tList = {}
	for s in string.gmatch(szList, "%d+") do
		local dwID = tonumber(s)
		if dwID then
			table.insert(tList, dwID)
		end
	end
	return tList
end

function StringParse_Numbers(szNumberList)	-- 23,544;234,345,342,334;
	local tNumberList = {}
	for szData in string.gmatch(szNumberList, "([%d,]+);?") do
		local tNumber = {}
		for szNumber in string.gmatch(szData, "(%d+),?") do
			table.insert(tNumber, tonumber(szNumber))
		end
		table.insert(tNumberList, tNumber)
	end
	return tNumberList
end

----------------Sound-------------------
function Table_SetSound()
	_G.g_sound = {}
	local sound = g_tTable.sound

	if not sound then
		return
	end

	local nCount = sound:GetRowCount()
	for i = 1, nCount do
		local tLine = g_tTable.sound:GetRow(i)
		_G.g_sound[tLine.szName] = tLine.szPath
	end
end

Table_SetSound()

----------------fmt获取文件type-------------------
function Table_GetStructTypeList(szTableName)
	local szFmtText = ""
	if tTableFile[szTableName] then
		for _, tTitle in pairs(tTableFile[szTableName].Title) do
			szFmtText = szFmtText .. tTitle.f
		end
		return szFmtText, tTableFile[szTableName].Path
	end
	return
end

-------------------- Item ------------------------
local function ParseSource(szSource)
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

local function ParseSourceCollect(szSource)
	local tResult = {}
	local szCraftID, szSource = string.match(szSource, "([%d]+)|([%d,;]+)")
	if szCraftID and szSource then
		tResult = SplitString(szSource, ";")
		tResult.dwCraftID = tonumber(szCraftID)
	end

	return tResult
end

local function GetGuideNpcMap(dwTemplateID)	--Craft_GetGuideNpcMap(dwTemplateID)
	local tInfo = Table_GetCraftNpcInfo(dwTemplateID)
	if tInfo and tInfo.dwMapID > 0 then
		return tInfo.dwMapID
	end
end

function Table_GetItemIconID(nUIID, bBig)
	local nIconID = -1
	local tItem = g_tTable.Item:Search(nUIID)
	if tItem then
		if bBig and tItem.dwBigIconID ~= 0 then
			nIconID = tItem.dwBigIconID
		else
			nIconID = tItem.dwIconID
		end
	end
	return nIconID
end

function Table_GetItemName(nUIID)
	local szName = ""
	local tItem = g_tTable.Item:Search(nUIID)
	if tItem then
		szName = tItem.szName
	end

	return szName
end

function Table_GetItemDesc(nUIID)
	local szDesc = ""
	local tItem = g_tTable.Item:Search(nUIID)
	if tItem then
		if tItem.szDesc ~= "" and tItem.szMobileDesc ~= "" then
			szDesc = tItem.szMobileDesc
		else
			szDesc = tItem.szDesc
		end
	end

	return szDesc
end

function Table_GetItemSoundID(nUIID)
	local nSoundID = -1
	local tItem = g_tTable.Item:Search(nUIID)
	if tItem then
		nSoundID = tItem.dwSoundID
	end
	return nSoundID
end

function Table_GetItemCanMutiUse(nUIID)
	local bCanMutiUse = false
	local tItem = g_tTable.Item:Search(nUIID)
	if tItem then
		bCanMutiUse = tItem.bCanMutiUse
	end

	return bCanMutiUse
end

function Table_GetItemInfo(nUIID)
	local tItem = g_tTable.Item:Search(nUIID)
	return tItem
end

function Table_GetItemIconInfo(dwIconID)
	local tItemIcon = g_tTable.ItemIcon:Search(dwIconID)
	if tItemIcon and not tItemIcon.bHandled then
		if not string.is_nil(tItemIcon.MobileFileName) then
			tItemIcon.FileName = string.gsub(tItemIcon.MobileFileName, "\\", "/")
		else
			tItemIcon.FileName = string.gsub(tItemIcon.FileName, "\\", "/")

			-- 将 .uitex后缀改成.png后缀
			local nEndIndex = #tItemIcon.FileName - 5
			tItemIcon.FileName = tItemIcon.FileName:sub(1, nEndIndex) .. "png"
		end

		tItemIcon.bHandled = true
	end
	return tItemIcon
end

function Table_GetItemLargeIconPath(dwIconID)
	local itemIconInfo = Table_GetItemIconInfo(dwIconID)
	if itemIconInfo then
		local szFileName_Large = string.gsub(itemIconInfo.FileName_Large, "\\", "/")
		if string.is_nil(szFileName_Large) then return "" end
		szFileName_Large = replaceExtension(szFileName_Large, "png")

		if not string.find(szFileName_Large, "Resource/icon/") then
			szFileName_Large = "Resource/icon/" .. szFileName_Large
		end
	end

	return szFileName_Large or ""
end

function Table_GetItemLargeIconPathByItemUiId(nItemUiId)
	local nItemIconID = Table_GetItemIconID(nItemUiId)
	return Table_GetItemLargeIconPath(nItemIconID)
end

-- 迭代器形式获取使用物品目标物品列表
function Table_GetUseItemTargetItemListIter(dwTabType, dwIndex)
	return tab_range(g_tTable.UseItemTargetItem_Mobile, {dwTabType, dwIndex})
end

function Table_GetBigBagSubFilter(nClass)
	local tRes = {}
	local nCount = g_tTable.BigBagFilterSetting:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.BigBagFilterSetting:GetRow(i)
		if tLine and tLine.nClass == nClass and tLine.nSub ~= 0 then
			table.insert(tRes, tLine)
		end
	end
	return tRes
end

function Table_GetBigBagFilterTag(nClass, nSub)
	nSub = nSub or 0

	local nFilterTag
	local tLine = g_tTable.BigBagFilterSetting:Search(nClass, nSub)
	if tLine then
		nFilterTag = tLine.nFilterTag
	end
	return nFilterTag
end

function Table_GetItemSourceList(szTabName, dwItemType, dwItemIndex, tLine)
	if not tLine and (not szTabName or not dwItemType or not dwItemIndex) then
		return
	end

	if not tLine and dwItemType ~= 5 and dwItemType ~= 6 and dwItemType ~= 7 and dwItemType ~= 8 and dwItemType ~= 10 then
		return
	end

	local tSource = nil
	tLine = tLine or g_tTable[szTabName]:Search(dwItemType, dwItemIndex)
	if tLine then
		local tSourceProduce = ParseSourceCollect(tLine.szSourceProduce)
		local tSourceCollectD = ParseSourceCollect(tLine.szSourceCollectD)
		local tCollectN = ParseSourceCollect(tLine.szSourceCollectN)
		local tBoss = ParseSource(tLine.szSourceBoss)
		local tNpc = ParseSource(tLine.szSourceNpc)
		local tItems = ParseSource(tLine.szSourceItem)
		local tQuests = SplitString(tLine.szSourceQuest, ";")
		local bTrades = tLine.bSourceTrade
		local tActivity = SplitString(tLine.szSourceActivity, ";")
		local tShop = SplitString(tLine.szSourceShop, ";")
		local tCoinShop = SplitString(tLine.szSourceCoinShop, ";")
		local tReputation = SplitString(tLine.szSourceReputation, ";")
		local tAchievement = SplitString(tLine.szSourceAchievement, ";")
		local tAdventure = SplitString(tLine.szSourceAdventure, ";")
		local tLinkItem = ParseSource(tLine.szLinkItem)
		local tFunction = SplitString(tLine.szUIFunction, "|")
		local tEventLink = SplitString(tLine.szUILink, "|")

		local tSourceCollectN = {}
		for _, v in ipairs(tCollectN) do
			local dwTemplateID = v
			local dwMapID = GetGuideNpcMap(dwTemplateID)
			table.insert(tSourceCollectN, {dwMapID, dwTemplateID})
		end
		tSourceCollectN.dwCraftID = tCollectN.dwCraftID
		tSource = {
			tSourceProduce = tSourceProduce,
			tSourceCollectD = tSourceCollectD,
			tSourceCollectN = tSourceCollectN,
			tBoss = tBoss,
			tSourceNpc  = tNpc,
			tItems = tItems,
			tQuests = tQuests,
			bTrades = bTrades,
			tActivity = tActivity,
			tShop = tShop,
			tCoinShop = tCoinShop,
			tReputation = tReputation,
			tAchievement = tAchievement,
			tAdventure = tAdventure,
			tLinkItem = tLinkItem,
			tFunction = tFunction,
			tEventLink = tEventLink,
		}
	end
	return tSource
end

function Table_GetGoldTeamNeed(nType, nItemID)
	if (not nType) or (not nItemID) then
		LOG.TABLE({"nType or nItemID is nil", nType, nItemID})
	end
	if type(nType) ~= "number" then
		LOG.TABLE({"nType is not a number", nType})
	end
	if type(nItemID) ~= "number" then
		LOG.TABLE({"nItemID is not a number", nItemID})
	end

    local tLine = g_tTable.GoldTeamNeed:Search(nType, nItemID)
	if tLine then
		local tKungfuIDs = ParseIDList(tLine.szKungfuIDs)
		tLine.tKungfuIDs = tKungfuIDs
	end
	return tLine
end

---------------------- skill -------------------

function Table_GetSkillSkinGroup(dwID)
	local tSkilSkin = nil

	tSkilSkin = g_tTable.SkillSkin:Search(dwID)

	if tSkilSkin then
		return tSkilSkin.dwSkinGroupID
	end
end

function Table_GetSkillSkinInfo(dwSkinID)
	local tSkin = nil

	tSkin = g_tTable.SkillSkinInfo:Search(dwSkinID)

	return tSkin
end

function Table_GetSkillSkinPreivew(dwSkinID)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    local tItems = {}
    local nCount = g_tTable.SkillSkinPreview:GetRowCount()
    local nRoleType = hPlayer.nRoleType
    for i = 2, nCount do
        local tLine = g_tTable.SkillSkinPreview:GetRow(i)
        if tLine.dwSkinID == dwSkinID and (tLine.nRoleType == 0 or tLine.nRoleType == nRoleType) then --nRoleType0表示所有体型通用
            table.insert(tItems, tLine)
        end
    end
    return tItems
end

function Table_GetSkillRecipe(dwID, dwLevel)
	local tSkillRecipe = nil

	tSkillRecipe = g_tTable.SkillRecipe:Search(dwID, dwLevel)

	if not tSkillRecipe then
		dwLevel = 0
		tSkillRecipe = g_tTable.SkillRecipe:Search(dwID, dwLevel)
	end

	return tSkillRecipe
end

local function Table_LoadAllSkillRecipe()
	local tSkillRecipe = nil
	local tab = g_tTable.SkillRecipe
	local nRow = tab:GetRowCount()
	for i = 2, nRow do
		tSkillRecipe = tab:GetRow(i)
		if tSkillRecipe.dwSkillID > 0 then
			if not tAllSkillRecipeMap[tSkillRecipe.dwSkillID] then
				tAllSkillRecipeMap[tSkillRecipe.dwSkillID] = {}
			end
			table.insert(tAllSkillRecipeMap[tSkillRecipe.dwSkillID], {recipe_id = tSkillRecipe.dwID, recipe_level = tSkillRecipe.dwLevel})
		end
	end
end

--技能B复用技能A的秘籍
function Table_GetSkillRecipeMirror(dwSkillID)
	local tSkillMirror = g_tTable.SkillRecipeMirror:Search(dwSkillID)
	if tSkillMirror then
		return tSkillMirror.dwSkillIDSRC
	else
		return nil
	end
end

function Table_GetSkillRecipeMirrorSrc(dwDstSkillID)
	local nCount = g_tTable.SkillRecipeMirror:GetRowCount()
	for i = 1, nCount do
		tSkillRecipeMirror = g_tTable.SkillRecipeMirror:GetRow(i)
		if tSkillRecipeMirror and tSkillRecipeMirror.dwSkillIDSRC == dwDstSkillID then
			return tSkillRecipeMirror.dwMirrorSkillID
		end
	end
	return nil
end

function Table_GetRecipeList(dwSkillID)
	if IsTableEmpty(tAllSkillRecipeMap) then
		Table_LoadAllSkillRecipe()
	end
	return tAllSkillRecipeMap[dwSkillID]
end

function Table_GetSkillSkinGroup(dwID)
	local tSkilSkin = nil

	tSkilSkin = g_tTable.SkillSkin:Search(dwID)

	if tSkilSkin then
		return tSkilSkin.dwSkinGroupID
	end

end

function Table_GetSkillSkinInfo(dwSkinID)
	local tSkin = nil

	tSkin = g_tTable.SkillSkinInfo:Search(dwSkinID)

	return tSkin
end

local g_tSkillCache = {}
local g_nSkillCacheCount = 0
local g_bSkillCacheOn = false
local MAX_SKILL_CACHE = 150

function Debug_TableSkillCache()
	Output("skill cache:"..g_nSkillCacheCount)
end

local function GetSkillEx(dwSkillID, dwSkillLevel)
	local tSkill = nil
	if dwSkillLevel then
		tSkill = g_tTable.Skill:Search(dwSkillID, dwSkillLevel)
		if not tSkill then
			tSkill = g_tTable.Skill:Search(dwSkillID, 0)
		end
	else
		tSkill = g_tTable.Skill:Search(dwSkillID)
	end

	if tSkill then
		if tSkill.szBuff ~= "" then
			tSkill.tBuff = ParseIDList(tSkill.szBuff)
		end
		if tSkill.szDebuff ~= "" then
			tSkill.tDebuff = ParseIDList(tSkill.szDebuff)
		end
		if tSkill.szSkillRelyOnShow ~= "" then
			tSkill.tSkillRelyOnShow = ParseIDList(tSkill.szSkillRelyOnShow)
		end

		if tSkill.szSkillRelyOnNotShow ~= "" then
			tSkill.tSkillRelyOnNotShow = ParseIDList(tSkill.szSkillRelyOnNotShow)
		end
	end
	return tSkill
end

function Table_GetSkill(dwSkillID, dwSkillLevel)
	if not dwSkillID or tonumber(dwSkillID) == 0 then
		return
	end

	if not g_bSkillCacheOn then
		return GetSkillEx(dwSkillID, dwSkillLevel)
	end

	local szKey = dwSkillID.."_"..tostring(dwSkillLevel)
	if not g_tSkillCache[szKey] then
		if g_nSkillCacheCount > MAX_SKILL_CACHE then
			g_tSkillCache = {}
			g_nSkillCacheCount = 0
			Log("skill cache beyond "..MAX_SKILL_CACHE.." !!")
		end

		g_tSkillCache[szKey] = GetSkillEx(dwSkillID, dwSkillLevel)
		if not g_tSkillCache[szKey] then
			g_tSkillCache[szKey] = -1
			--[[Output("g_tSkillCache name:"..tostring(dwSkillID).."_"..tostring(dwSkillLevel))
		else
			Output("g_tSkillCache name:"..g_tSkillCache[szKey].szName.." dwID: "..tostring(dwSkillID).."_"..tostring(dwSkillLevel))
			]]
		end
		g_nSkillCacheCount = g_nSkillCacheCount + 1
	end

	if g_tSkillCache[szKey] == -1 then
		return
	end
	return g_tSkillCache[szKey]
end

function Table_IsLegalSkillName(szSkillName)
	local bFlag = false
	local nCount = g_tTable.Skill:GetRowCount()
	for i = 1, nCount do
		local tLine = g_tTable.Skill:GetRow(i)
		local szText = UIHelper.GBKToUTF8(tLine.szName)
		if szSkillName == szText then
			bFlag = true
			break
		end
	end

	return bFlag
end

function Table_IsBlackListSkill(dwSkillID, dwSkillLevel)
	local tSkill = Table_GetSkill(dwSkillID, dwSkillLevel)
	if tSkill then
		return tSkill.bBlackList
	end
end

function Table_GetSkillIconID(dwSkillID, dwSkillLevel)
	local nIconID = 14659 --大侠心法的图标，因为预创建角色没有心法导致一系列的bug，所以改成默认是这个
	local tSkill = Table_GetSkill(dwSkillID, dwSkillLevel)
	if tSkill then
		nIconID = tSkill.dwIconID
	end
	return nIconID
end

function Table_GetSkillRecipe(dwRecipeID)
	local tSkillSchool = g_tTable.SkillRecipe:Search(dwRecipeID)
	if tSkillSchool then
		return tSkillSchool
	end
	return nil
end
---------------------- skill belong school -------------------

local _tBelongSchool = nil
local _tSchoolList = nil

local function GetBelongSchoolList()
	if _tBelongSchool then
		return _tBelongSchool
	end

	_tBelongSchool = {}
	_tSchoolList = {}
	local nCount = g_tTable.SkillBelongSchool:GetRowCount()
	for i = 1, nCount do
		local tLine = g_tTable.SkillBelongSchool:GetRow(i)
		if tLine then
			_tBelongSchool[tLine.dwBelongSchool] = tLine
			local tList = ParseIDList(tLine.szSchool)
			for _, v in ipairs(tList) do
				_tSchoolList[v] = tLine
			end
		end
	end
	return _tBelongSchool
end

local function GetSchoolList()
	if _tSchoolList then
		return _tSchoolList
	end

	GetBelongSchoolList()
	return _tSchoolList
end

function Table_GetSkillSchoolName(dwBelongSchool, bTurnUTF8)
	local szName = ""
	local tLine = Table_GetSkillSchoolInfo(dwBelongSchool)
	if tLine then
		szName = tLine.szName
	end

	if bTurnUTF8 then
		szName = UIHelper.GBKToUTF8(szName)
	end
	return szName
end


function Table_GetSkillSchoolInfo(dwBelongSchool)
	local tBelongSchool = GetBelongSchoolList()
	local tLine = tBelongSchool[dwBelongSchool]

	return tLine
end

function Table_GetSchoolImage(dwSchoolID)
	local tSchoolList = GetSchoolList()
	local tLine = tSchoolList[dwSchoolID]
	if tLine then
		return tLine.szSchoolImage, tLine.nSchoolFrame
	end
end

function Table_GetSchoolColor(dwSchoolID)
	local tColor = {}
	local tSchoolList = GetSchoolList()
	local tLine = tSchoolList[dwSchoolID]
	if tLine then
		local t = SplitString(tLine.szColor, ";")
		for k, v in ipairs(t) do
			table.insert(tColor, tonumber(v))
		end
	end

	return tColor
end

function Table_GetSkillSchoolIDByName(szName)
	local tBelongSchool = GetBelongSchoolList()

	for k, v in pairs(tBelongSchool) do
		if v and v.szName == szName then
			return v.dwBelongSchool
		end
	end
end
---------------------- skill belong school -------------------

function Table_IsSkillFormation(dwSkillID, dwSkillLevel)
	local bFormation = false

	local tSkill = Table_GetSkill(dwSkillID, dwSkillLevel)
	if tSkill and tSkill.bFormation ~= 0 then
		bFormation = true
	end

	return bFormation
end

function Table_IsSkillFormationCaster(dwSkillID, dwSkillLevel)
	local bFormationCaster = false

	local tSkill = Table_GetSkill(dwSkillID, dwSkillLevel)
	if tSkill and tSkill.bFormationCaster ~= 0 then
		bFormationCaster = true
	end

	return bFormationCaster
end

function Table_GetSkillDecoration(dwSkillID, dwSkillLevel)
	local szName, nDecoration = ""
	if dwSkillID and dwSkillLevel then
		local tSkill = Table_GetSkill(dwSkillID, dwSkillLevel)
		if tSkill then
			nDecoration = tSkill.nDecoration
		end
	end
	if nDecoration then
		szName = g_tStrings.SKILL_VALUE_DECORATION[nDecoration]
	end
	return szName, nDecoration
end

function Table_GetSkillName(dwSkillID, dwSkillLevel)
	local szName = ""

	local tSkill = nil

	tSkill = Table_GetSkill(dwSkillID, dwSkillLevel)

	if tSkill then
		szName = tSkill.szName
	end

	return szName
end

function Table_GetSkillOTActionShowType(dwSkillID, dwSkillLevel)
	local nOTActionShowType = 0
	--0：可打断技能才显示读条 1：强制显示读条  2：强制不显示读条

	local tSkill = nil

	tSkill = Table_GetSkill(dwSkillID, dwSkillLevel)

	if tSkill then
		nOTActionShowType = tSkill.nOTActionShowType
	end

	return nOTActionShowType
end

function Table_GetSkillDesc(dwSkillID, dwSkillLevel)
	local szDesc = ""

	local tSkill = Table_GetSkill(dwSkillID, dwSkillLevel)

	if tSkill then
		szDesc = tSkill.szDesc
	end

	return szDesc
end

function Table_GetSkillShortDesc(dwSkillID, dwSkillLevel)
	local szShortDesc = ""

	local tSkill = Table_GetSkill(dwSkillID, dwSkillLevel)

	if tSkill then
		szShortDesc = tSkill.szShortDesc
	end

	return szShortDesc
end

function Table_GetSkillSimpleDesc(dwSkillID, dwSkillLevel)
	local szShortDesc = ""

	local tSkill = Table_GetSkill(dwSkillID, dwSkillLevel)

	if tSkill then
		szShortDesc = tSkill.szSimpleDesc
	end

	return szShortDesc
end

function Table_GetSkillSpecialDesc(dwSkillID, dwSkillLevel)
	local szSpecialDesc = ""

	local tSkill = Table_GetSkill(dwSkillID, dwSkillLevel)

	if tSkill then
		szSpecialDesc = tSkill.szSpecialDesc
	end

	return szSpecialDesc
end

function Table_GetSkillKungfuDesc(dwSkillID, dwSkillLevel)
	local szDesc = ""

	local tSkill = Table_GetSkill(dwSkillID, dwSkillLevel)

	if tSkill then
		szDesc = tSkill.szKungfuDesc
	end

	return szDesc
end

function Table_GetSkillSortOrder(dwSkillID, dwSkillLevel)
	local fOrder = 0

	local tSkill = Table_GetSkill(dwSkillID, dwSkillLevel)

	if tSkill then
		fOrder = tSkill.fSortOrder
	end

	return fOrder
end

function Table_IsSkillShow(dwSkillID, dwSkillLevel)
	local bShow = false

	if not dwSkillLevel then
		dwSkillLevel = 0
	end

	local tSkill = Table_GetSkill(dwSkillID, dwSkillLevel)

	if tSkill and tSkill.bShow ~= 0 then
		bShow = true
	end

	return bShow
end

function Table_IsSkillCombatShow(dwSkillID, dwSkillLevel)
	local bCombatShow = false

	if not dwSkillLevel then
		dwSkillLevel = 0
	end

	local tSkill = Table_GetSkill(dwSkillID, dwSkillLevel)

	if tSkill and tSkill.bCombatShow ~= 0 then
		bCombatShow = true
	end

	return bCombatShow
end

function Table_GetSkillPracticeID(dwSkillID, dwSkillLevel)
	local dwPracticeID = 0

	if not dwSkillLevel then
		dwSkillLevel = 0
	end

	local tSkill = Table_GetSkill(dwSkillID, dwSkillLevel)

	if tSkill then
		dwPracticeID = tSkill.dwPracticeID
	end

	return dwPracticeID
end

function Table_IsShowOnNewSkill(dwSkillID, dwSkillLevel)
	local bShow = false

	if not dwSkillLevel then
		dwSkillLevel = 0
	end

	local tSkill = Table_GetSkill(dwSkillID, dwSkillLevel)

	if tSkill then
		bShow = tSkill.IsShowOnNewSkill
	end

	return bShow
end

function Table_GetLearnSkillInfo(dwLevel, dwSchool)
	local szSkill = ""

	local tSkill = g_tTable.LearnSkill:Search(dwLevel, dwSchool)

	if tSkill then
		szSkill = tSkill.szSkill
	end

	return szSkill
end

function Table_IsShowRelayOn(tSkill)
	local player = g_pClientPlayer
	if not player then
		return
	end

	local t =  tSkill.tSkillRelyOnShow
	if not t or #t <= 0 then
		return true
	end

	for _, dwID in ipairs(t) do
		if player.GetSkillLevel(dwID) > 0 then
			return true
		end
	end

	return false
end

function Table_IsShowByRelayOnNot(tSkill)
	local player = g_pClientPlayer
	if not player then
		return
	end

	local t =  tSkill.tSkillRelyOnNotShow
	if not t or #t <= 0 then
		return true
	end

	for _, dwID in ipairs(t) do
		if player.GetSkillLevel(dwID) > 0 then
			return false
		end
	end

	return true
end

function Table_IsLegalSkill(dwID, dwLevel)
	local dwShowLevel = math.max(1, dwLevel)
	local tSkill = Table_GetSkill(dwID, dwShowLevel)
	if not tSkill then
		return
	end

	if not Table_IsShowRelayOn(tSkill) or not Table_IsShowByRelayOnNot(tSkill) then
		return
	end

	return true
end

function Table_GetSkillNouns(nNounID)
	local nCount = g_tTable.SkillNouns:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.SkillNouns:GetRow(i)
		if tLine and tLine.nNounID == nNounID then
			return tLine
		end
	end
end

local GetUTF8SkillName = function(dwSkillID, dwSkillLevel)
	local szName  = Table_GetSkillName(dwSkillID, dwSkillLevel)
	szName = szName and  UIHelper.GBKToUTF8(szName)
	return szName
end

g_SkillNameToID = {}
local function IsSkillNameExist(skill_name, dwSkillID)
	local t = g_SkillNameToID[skill_name]
	if not t then
		return
	end

	if type(t) == "number" then
		return (t == dwSkillID)
	else
		for _, dwID in ipairs(t) do
			if dwID == dwSkillID then
				return true
			end
		end
	end
end

local function RemoveSkillNameExist(skill_name, dwSkillID)
	local t = g_SkillNameToID[skill_name]
	if not t then
		return
	end

	if type(t) == "number" then
		if (t == dwSkillID) then
			g_SkillNameToID[skill_name] = nil
			return true
		end
	else
		for k, dwID in ipairs(t) do
			if dwID == dwSkillID then
				table.remove(t, k)
				return true
			end
		end
	end
end

local function AddSkillNameMap(skill_name, dwSkillID, bAddFirst)
	if not g_SkillNameToID[skill_name] then
		g_SkillNameToID[skill_name] = dwSkillID
	else
		local t = g_SkillNameToID[skill_name]
		if type(t) == "table" then
			if bAddFirst then
				table.insert(t, 1, dwSkillID)
			else
				table.insert(t, dwSkillID)
			end
		else
			if bAddFirst then
				g_SkillNameToID[skill_name] = {dwSkillID, t}
			else
				g_SkillNameToID[skill_name] = {t, dwSkillID}
			end
		end
	end
end

local function CorrectSkillNameToIDMap(dwID, dwLevel)
	local player = GetClientPlayer()
	if not player then
		return
	end

	local szName
	local bOrgVal = g_bSkillCacheOn;
	g_bSkillCacheOn = false
	if dwID and dwLevel and dwLevel > 0 and Table_IsLegalSkill(dwID, dwLevel) then
		szName = GetUTF8SkillName(dwID, dwLevel)
		if szName then
			local skill = GetSkill(dwID, dwLevel)
			if skill and not skill.bIsPassiveSkill then
				if not IsSkillNameExist(szName, dwID) then
					AddSkillNameMap(szName, dwID)
				end
			end
		end
	else
		local aSkill = player.GetAllSkillList() or {}
		for dwID, dwLevel in pairs(aSkill) do
			if Table_IsLegalSkill(dwID, dwLevel) then
				szName = GetUTF8SkillName(dwID, dwLevel)
				if szName then
					local skill = GetSkill(dwID, dwLevel)
					if skill and not skill.bIsPassiveSkill then
						if not IsSkillNameExist(szName, dwID) then
							AddSkillNameMap(szName, dwID)
						end
					end
				end
			end
		end
	end
	g_bSkillCacheOn = bOrgVal
end

function CorrectSkillName(dwID)
	local player = g_pClientPlayer
	if not player then
		return
	end
	local dwLevel = player.GetSkillLevel(dwID)
	local szName = GetUTF8SkillName(dwID, dwLevel)
	if szName then
		RemoveSkillNameExist(szName, dwID)
		AddSkillNameMap(szName, dwID, true)
	end
end

------------------------------Buff-------------------------------

local g_tBuffCache

local function _cache_update(cache)
	g_tBuffCache = cache
end

g_tBuffCache = cache_init(400, "buff", _cache_update)

function Debug_TableBuffCache()
	UILog("table buff cache:"..g_tBuffCache._useNum)
end

function Table_GetBuff(dwBuffID, dwLevel)
	if not dwBuffID then
		return
	end
	local szKey = dwBuffID.."_"..tostring(dwLevel)
	if not g_tBuffCache[szKey] then
		local value = g_tTable.Buff:Search(dwBuffID, dwLevel)
		if not value then
			value = g_tTable.Buff:Search(dwBuffID, 0)
		end

		if not value then
			value = -1
		end
		g_tBuffCache = cache_append(g_tBuffCache, szKey, value)
	end

	if g_tBuffCache[szKey] == -1 then
		return
	end

	return g_tBuffCache[szKey]
end

function Table_GetBuffTime(dwBuffID, dwLevel)
	local szKey = dwBuffID.."_"..tostring(dwLevel)
	if not g_tBuffCache[szKey] then
		return GetBuffTime(dwBuffID, dwLevel)
	end

	if not g_tBuffCache[szKey].nBuffTime then
		g_tBuffCache[szKey].nBuffTime = GetBuffTime(dwBuffID, dwLevel)
	end

	return g_tBuffCache[szKey].nBuffTime
end

function Table_GetBuffIconID(dwBuffID, dwLevel)
	local nIconID = -1

	local tBuff = Table_GetBuff(dwBuffID, dwLevel)

	if tBuff then
		nIconID = tBuff.dwIconID
	end

	return nIconID
end

function Table_GetBuffName(dwBuffID, dwLevel)
	local szName = ""

	local tBuff = Table_GetBuff(dwBuffID, dwLevel)

	if tBuff then
		szName = tBuff.szName
	end

	return szName
end

function Table_GetBuffDesc(dwBuffID, dwLevel)
	local szDesc = ""

	local tBuff = Table_GetBuff(dwBuffID, dwLevel)

	if tBuff then
		szDesc = tBuff.szDesc
	end

	return szDesc
end

function Table_BuffNeedSparking(dwBuffID, dwLevel)
	local bSparking = false

	local tBuff = Table_GetBuff(dwBuffID, dwLevel)

	if tBuff and tBuff.bSparking ~= 0 then
		bSparking = true
	end

	return bSparking
end

function Table_BuffNeedShowTime(dwBuffID, dwLevel)
	local bShowTime = false

	local tBuff = Table_GetBuff(dwBuffID, dwLevel)

	if tBuff and tBuff.bShowTime ~= 0 then
		bShowTime = true
	end

	return bShowTime
end

function Table_BuffNeedShow(dwBuffID, dwLevel)
	local bShow = false

	local tBuff = Table_GetBuff(dwBuffID, dwLevel)

	if tBuff then
		bShow = true
	end

	return bShow
end

function Table_BuffIsVisible(dwBuffID, dwLevel)
	local bShow = false
	local tBuff = Table_GetBuff(dwBuffID, dwLevel)

	if tBuff and tBuff.bShow ~= 0 then
		bShow = true
	end
	return bShow
end


function Table_IsBuffDescAddPeriod(dwBuffID, dwLevel)
	local tBuff = Table_GetBuff(dwBuffID, dwLevel)
	if tBuff then
		return tBuff.bAutoAddPeriod
	end

	return false
end

function Table_GetBuffTeamShowInfo(dwBuffID, dwLevel)
	local tBuff = Table_GetBuff(dwBuffID, dwLevel)
	if tBuff then
		return tBuff.bMbSpecialShow, tBuff.nMbSpecialShowPriority, tBuff.bMbCantRebirth
	end
	return false, 0, false
end

-------------------------BattleField---------------------------------------

function Table_IsBattleFieldMap(dwMapID)
	local bBattleFieldMap = false

	local tMap = g_tTable.BattleField:Search(dwMapID)

	if tMap and tMap.nType == BATTLEFIELD_MAP_TYPE.BATTLEFIELD then
		bBattleFieldMap = true
	end

	return bBattleFieldMap
end

function Table_IsTongBattleFieldMap(dwMapID)
	local bBattleFieldMap = false

	local tMap = g_tTable.BattleField:Search(dwMapID)

	if tMap and tMap.nType == BATTLEFIELD_MAP_TYPE.TONGBATTLE then
		bBattleFieldMap = true
	end

	return bBattleFieldMap
end

function Table_IsNewcomerBattleFieldMap(dwMapID)
	local bBattleFieldMap = false

	local tMap = g_tTable.BattleField:Search(dwMapID)

	if tMap and tMap.nType == BATTLEFIELD_MAP_TYPE.NEWCOMERBATTLE then
		bBattleFieldMap = true
	end

	return bBattleFieldMap
end

GetBattleFieldFatherID = BattleFieldData.GetBattleFieldFatherID

function Table_GetBattleFieldName(dwMapID)
	local dwMapID = GetBattleFieldFatherID(dwMapID)
	if not dwMapID then
		return
	end
	local tMap = g_tTable.BattleField:Search(dwMapID)
	assert(tMap)

	return tMap.szName
end

function Table_IsTreasureBattleFieldMap(dwMapID)
	local bBattleFieldMap = false
	local dwMapID = GetBattleFieldFatherID(dwMapID)
	if not dwMapID then
		return
	end

	local tMap = g_tTable.BattleField:Search(dwMapID)

	if tMap and tMap.nType == BATTLEFIELD_MAP_TYPE.TREASUREBATTLE or tMap.nType == BATTLEFIELD_MAP_TYPE.TREASURE_HUNT then
		bBattleFieldMap = true
	end

	return bBattleFieldMap
end

function Table_IsTreasureHuntMap(dwMapID)
    local bTreasureHuntMap = false
    local dwMapID = GetBattleFieldFatherID(dwMapID)
    if not dwMapID then
        return
    end

    local tMap = g_tTable.BattleField:Search(dwMapID)
    if tMap and tMap.nType == BATTLEFIELD_MAP_TYPE.TREASURE_HUNT then
        bTreasureHuntMap = true
    end

    if not bTreasureHuntMap then
        bTreasureHuntMap = dwMapID == 676 -- 乱武模式地图
    end

    return bTreasureHuntMap
end

function Table_IsMonopolyBattleFieldMap(dwMapID)
	local bBattleFieldMap = false

	local tMap = g_tTable.BattleField:Search(dwMapID)

	if tMap and tMap.nType == BATTLEFIELD_MAP_TYPE.MONOPOLY then
		bBattleFieldMap = true
	end

	return bBattleFieldMap
end

function Table_IsTongWarFieldMap(dwMapID)
	local bBattleFieldMap = false
	if not dwMapID then
		return bBattleFieldMap
	end

	local dwMapID = GetBattleFieldFatherID(dwMapID)
	if not dwMapID then
		return
	end

	local tMap = g_tTable.BattleField:Search(dwMapID)

	if tMap and tMap.nType == BATTLEFIELD_MAP_TYPE.TONGWAR then
		bBattleFieldMap = true
	end

	return bBattleFieldMap
end

function Table_IsZombieBattleFieldMap(dwMapID)
	local bBattleFieldMap = false
	local dwMapID = GetBattleFieldFatherID(dwMapID)
	if not dwMapID then
		return
	end

	local tMap = g_tTable.BattleField:Search(dwMapID)

	if tMap and tMap.nType == BATTLEFIELD_MAP_TYPE.ZOMBIEBATTLE then
		bBattleFieldMap = true
	end

	return bBattleFieldMap
end

function Table_IsMobaBattleFieldMap(dwMapID)
	local bMobaMap = false
	if not dwMapID then
		return
	end

	local tMap = g_tTable.BattleField:Search(dwMapID)

	if tMap and tMap.nType == BATTLEFIELD_MAP_TYPE.MOBABATTLE then
		bMobaMap = true
	end

	return bMobaMap
end

function Table_IsFBBattleFieldMap(dwMapID)
	local bBattleFieldMap = false
	local dwMapID = GetBattleFieldFatherID(dwMapID)
	if not dwMapID then
		return
	end

	local tMap = g_tTable.BattleField:Search(dwMapID)

	if tMap and tMap.nType == BATTLEFIELD_MAP_TYPE.FBBATTLE then
		bBattleFieldMap = true
	end

	return bBattleFieldMap
end

function Table_IsPleasantGoatBattleFieldMap(dwMapID)
	local bBattleFieldMap = false

	local tMap = g_tTable.BattleField:Search(dwMapID)

	if tMap and tMap.nType == BATTLEFIELD_MAP_TYPE.PLEASANTGOAT then
		bBattleFieldMap = true
	end

	return bBattleFieldMap
end

function Table_GetBattleFieldDesc(dwMapID)
	local dwMapID = GetBattleFieldFatherID(dwMapID)
	if not dwMapID then
		return
	end
	local tMap = g_tTable.BattleField:Search(dwMapID)
	assert(tMap)

	return tMap.szDesc
end

function Table_GetBattleFieldGroupInfo(dwMapID)
	local dwMapID = GetBattleFieldFatherID(dwMapID)
	if not dwMapID then
		return
	end
	local tMap = g_tTable.BattleField:Search(dwMapID)
	assert(tMap)

	local tGroupInfo = {}
	for i = 1, BATTLE_FIELD_GROUP_COUNT do
		table.insert(tGroupInfo, tMap["szGroup" .. i])
	end

	return tGroupInfo
end

function Table_GetBattleFieldPQOptionInfo(dwMapID)
	local dwMapID = GetBattleFieldFatherID(dwMapID)
	if not dwMapID then
		return
	end
	local tMap = g_tTable.BattleField:Search(dwMapID)
	assert(tMap)

	local tPQOptionInfo = {}
	for i = 1, BATTLE_FIELD_PQOPTIONICON_COUNT do
		tPQOptionInfo["szPQOptionName" .. i] = tMap["szPQOptionName" .. i]
		tPQOptionInfo["nPQOptionIcon" .. i] = tMap["nPQOptionIcon" .. i]
	end

	return tPQOptionInfo
end

function Table_GetBattleFieldRewardIconInfo(dwMapID)
	local dwMapID = GetBattleFieldFatherID(dwMapID)
	if not dwMapID then
		return
	end
	local tMap = g_tTable.BattleField:Search(dwMapID)
	assert(tMap)

	return tMap.nRewardIcon1, tMap.nRewardIcon2, tMap.nRewardIcon3, tMap.nRewardIcon4
end


function Table_GetBattleFieldHelpInfo(dwMapID)
	local dwMapID = GetBattleFieldFatherID(dwMapID)
	if not dwMapID then
		return
	end
	local tMap = g_tTable.BattleField:Search(dwMapID)
	assert(tMap)

	return tMap.szHelpImagePath, tMap.szHelpText
end

function Table_GetBattleFieldSubMapID()
	local tRet = {}
	local nCount = g_tTable.BattleField:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.BattleField:GetRow(i)
		if tLine.szSubMapID ~= "" then
			local tSubMapID = ParseIDList(tLine.szSubMapID)
			for k, v in ipairs(tSubMapID) do
				tRet[v] = tLine.dwMapID
			end
		end
		tRet[tLine.dwMapID] = tLine.dwMapID
	end
	return tRet
end

function Table_GetAllTreasureBattleFieldMapID()
	local tRet = {}
	local nCount = g_tTable.BattleField:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.BattleField:GetRow(i)
		if tLine.nType == BATTLEFIELD_MAP_TYPE.TREASUREBATTLE then
			table.insert(tRet, tLine.dwMapID)
			if tLine.szSubMapID ~= "" then
				local tSubMapID = ParseIDList(tLine.szSubMapID)
				for k, v in ipairs(tSubMapID) do
					table.insert(tRet, v)
				end
			end
		end
	end
	return tRet
end

function Table_GetBFCustomRoomMapInfo(dwMapID)
	local nCount = g_tTable.BattleField:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.BattleField:GetRow(i)
		if tLine.dwMapID == dwMapID then
			return tLine
		end
	end
end

function Table_IsSkillBuff(nBuffID, nLevel)
	local tLine = g_tTable.BuffSkill:Search(nBuffID, nLevel)
	return tLine
end

function Table_GetDesertEquipInfo(dwTabType, dwIndex)
	local tLine = g_tTable.DesertEquipInfo:Search(dwTabType, dwIndex)
	return tLine
end

function Table_GetDesertWeaponSkill()
    local nCount = g_tTable.DesertWeaponSkill:GetRowCount()
	local tRes = {}
	local tWeapon2Range = {}
	local tWeapon2ID = {}
    for i = 2, nCount do
        local tLine = g_tTable.DesertWeaponSkill:GetRow(i)
		local tResult = SplitString(tLine.szSkillID, "|")
		tLine.tSkill = tResult
		local tResult = SplitString(tLine.szWeaponID, "|")
		tLine.tWeaponID = tResult
		for k, v in pairs(tLine.tWeaponID) do
			tWeapon2Range[v] = tLine.nRange
			tWeapon2ID[v] = tLine.dwID
		end
		table.insert(tRes, tLine)
    end
	return tRes, tWeapon2Range, tWeapon2ID
end

function Tabel_GetDesertStormSkill()
    local tRes = {}
	local nRow = g_tTable.DesertStormSkill:GetRowCount()
	for i = 2, nRow do
		local tLine = g_tTable.DesertStormSkill:GetRow(i)
		if tLine then
            table.insert(tRes, tLine)
		end
	end
	return tRes
end

function Tabel_GetDesertStormSkillQuality()
    local tRes = {}
	local nRow = g_tTable.DesertStormSkillQuality:GetRowCount()
	for i = 2, nRow do
		local tLine = g_tTable.DesertStormSkillQuality:GetRow(i)
		if tLine then
            tRes[tLine.dwID] = tLine
		end
	end
	return tRes
end

function Tabel_GetDesertStormSkillEffect()
    local tRes = {}
	local nRow = g_tTable.DesertStormSkillEffect:GetRowCount()
	for i = 2, nRow do
		local tLine = g_tTable.DesertStormSkillEffect:GetRow(i)
		if tLine then
            tRes[tLine.dwID] = tLine
		end
	end
	return tRes
end

function Table_GetBattleFieldInfo(dwMapID)
	local dwMapID = GetBattleFieldFatherID(dwMapID)
	if not dwMapID then
		return
	end
	local tMap = g_tTable.BattleField:Search(dwMapID)
	assert(tMap)

	local nRewardIcon1, nRewardIcon2, nRewardIcon3, nRewardIcon4 = Table_GetBattleFieldRewardIconInfo(dwMapID)
	local tRewardPreview = {}
	if tMap.szRewards ~= "" then
		local tRewardList = SplitString(tMap.szRewards, ";")
		for _, szReward in ipairs(tRewardList) do
			local tRewardInfo = SplitString(szReward, "_")
			table.insert(tRewardPreview,
			{
				dwTabType = tonumber(tRewardInfo[1]),
				dwIndex = tonumber(tRewardInfo[2]),
				nCount = tonumber(tRewardInfo[3]) or 1,
			})
		end
	end
	
	tMap.tPQOptionInfo = Table_GetBattleFieldPQOptionInfo(dwMapID) or {}
	tMap.tGroupInfo = Table_GetBattleFieldGroupInfo(dwMapID) or {}
	tMap.tRewardIcon = { nRewardIcon1, nRewardIcon2, nRewardIcon3, nRewardIcon4 }
	tMap.tRewardPreview = tRewardPreview

	return tMap
end

-----------------------------Quest-------------------------------
local function IsQuestNameShield(szName)
	for _, szShield in ipairs(g_tStrings.tQuestShieldName) do
		if szName == szShield then
			return true
		end
	end
	return false
end

function Table_GetQuestPosInfo(dwQuestID, szType, nIndex)
	local tQuestPosInfo = g_tTable.Quest:Search(dwQuestID)
	if not tQuestPosInfo then
		return
	end

	local szQuestPos = nil
	if szType == "accept" then
		szQuestPos = tQuestPosInfo.szAccept
	elseif szType == "finish" then
		szQuestPos = tQuestPosInfo.szFinish
	elseif szType == "quest_state" then
		szQuestPos = tQuestPosInfo["szQuestState" .. nIndex + 1]
	elseif szType == "kill_npc" then
		szQuestPos = tQuestPosInfo["szKillNpc" .. nIndex + 1]
	elseif szType == "need_item" then
		szQuestPos = tQuestPosInfo["szNeedItem" .. nIndex + 1]
	elseif szType == "all" then
		return tQuestPosInfo
	end

	if szQuestPos == "" then
		szQuestPos = nil
	end

	return szQuestPos
end

function Table_GetBindNpcQuestList(dwTemplateID)
	if not tMapNPCToQuest then
		tMapNPCToQuest = {}
		Table_LoadNpcQuest()
	end
	if dwTemplateID then
		return tMapNPCToQuest[dwTemplateID]
	end
	return nil
end

function Table_LoadNpcQuest()
	local quest_tab = g_tTable.Quest
	local shieldquest_tab = g_tTable.ShieldQuest
	local quests_tab = g_tTable.Quests
	local nRow = quest_tab:GetRowCount()

	-- Row 1 for default Row
	for i = 2, nRow  do
		local tQuestPosInfo = quest_tab:GetRow(i)
		local dwQuestID = tQuestPosInfo.dwQuestID
		local tQuestStringInfo = quests_tab:Search(dwQuestID)
		if tQuestStringInfo then
			for nIndex = 1, 8 do
				local szNpcList = tQuestStringInfo[string.format("szBindNPCIDList%d", nIndex)]
				local tbNpcList = string.split(szNpcList, ";")
				for index, szTemplateID in ipairs(tbNpcList) do
					local nTemplateID = tonumber(szTemplateID)
					if not tMapNPCToQuest[nTemplateID] then
						tMapNPCToQuest[nTemplateID] = {}
					end
					table.insert(tMapNPCToQuest[nTemplateID], {nQuestID = tQuestStringInfo.nID, nIndex = nIndex})
				end
			end
		end
	end
end

function Table_GetAllSceneQuest(dwMapID)
	if not tAllSceneQuestFormated then
		local dirPath = GetTempDir(false)
		local s = Lib.GetStringFromFile(dirPath.."/all_scene_quest_tab.dat")
		if not s then
			return
		end

		tAllSceneQuestFormated = str2var(s, nil, true)
	end

	local tSceneQuest = {}
	if tAllSceneQuestFormated and tAllSceneQuestFormated[dwMapID] then
		tSceneQuest = tAllSceneQuestFormated[dwMapID]
	end

	return tSceneQuest
end

function Table_GenerateAllSceneQuest()
	if not tAllSceneQuest then
		tAllSceneQuest = {}
		Table_LoadSceneQuest()
	end

    local s = "return " .. var2str(tAllSceneQuest, "\t", nil, true)
	local dirPath = GetTempDir(true)
    cc.FileUtils:getInstance():writeStringToFile(s, dirPath.."/all_scene_quest_tab.dat")

	tAllSceneQuest = nil
end

function Table_LoadSceneQuest()
	local quest_tab = g_tTable.Quest
	local shieldquest_tab = g_tTable.ShieldQuest
	local quests_tab = g_tTable.Quests
	local nRow = quest_tab:GetRowCount()
	-- Row 1 for default Row
	for i = 2, nRow  do
		local tQuestPosInfo = quest_tab:GetRow(i)
		local dwQuestID = tQuestPosInfo.dwQuestID
		local tQuestStringInfo = quests_tab:Search(dwQuestID)
		if tQuestStringInfo then
			local bQuestNameShield = IsQuestNameShield(tQuestStringInfo.szName)
			if not bQuestNameShield then
				local tShield = shieldquest_tab:Search(dwQuestID)
				if not tShield then
					local szPosInfo = tQuestPosInfo.szAccept
					for szType, szData in string.gmatch(szPosInfo, "<(%a[%d|]*) ([%d,;|]+)>") do
						local szFrame, szSource = string.match(szData, "([%d]+)|([%d,;]+)")
						local nFrame
						if szFrame and szFrame ~= "" and szSource and szSource ~= "" then
							szData = szSource
							nFrame = tonumber(szFrame)
						end
						if szType == "N" or szType == "D" then	-- npc
							local tData = StringParse_Numbers(szData)
							for _, tInfo in ipairs(tData) do
								local dwQuestMapID = tInfo[1]
								local dwObject = tInfo[2]
								if not tAllSceneQuest[dwQuestMapID] then
									tAllSceneQuest[dwQuestMapID] = {}
								end
								if not tAllSceneQuest[dwQuestMapID][dwQuestID] then
									tAllSceneQuest[dwQuestMapID][dwQuestID] = {}
								end
								table.insert(tAllSceneQuest[dwQuestMapID][dwQuestID], {szType, dwObject})
							end
						elseif string.sub(szType, 1, 1) == "P" then
                            local tData = StringParse_Numbers(szData)
                            for _, tInfo in ipairs(tData) do
                                local dwQuestMapID = tInfo[1]
                                local x, y, z = tInfo[2], tInfo[3], tInfo[4]
                                if not tAllSceneQuest[dwQuestMapID] then
                                    tAllSceneQuest[dwQuestMapID] = {}
                                end
                                if not tAllSceneQuest[dwQuestMapID][dwQuestID] then
                                    tAllSceneQuest[dwQuestMapID][dwQuestID] = {}
                                end
                                table.insert(tAllSceneQuest[dwQuestMapID][dwQuestID], {szType, x, y, z})
                            end
						end
					end
				end
			end
		end
	end
end
-----------------------------Book--------------------------
function Table_GetBookSort(dwBookID, dwSegmentID)
	local nSort = -1

	local tBookSegment = g_tTable.BookSegment:Search(dwBookID, dwSegmentID)
	if tBookSegment then
		nSort = tBookSegment.nSort
	end

	return nSort
end

function Table_GetBookSubSort(dwBookID, dwSegmentID)
	local nSubSort = -1

	local tBookSegment = g_tTable.BookSegment:Search(dwBookID, dwSegmentID)
	if tBookSegment then
		nSubSort = tBookSegment.nSubSort
	end

	return nSubSort
end

function Table_GetBookMark(dwBookID, dwSegmentID)
	local nType = -1

	local tBookSegment = g_tTable.BookSegment:Search(dwBookID, dwSegmentID)
	if tBookSegment then
		nType = tBookSegment.nType
	end

	return nType
end

function Table_GetBookPageNumber(dwBookID, dwSegmentID)
	local dwPageCount = 0

	local tBookSegment = g_tTable.BookSegment:Search(dwBookID, dwSegmentID)
	if tBookSegment then
		dwPageCount = tBookSegment.dwPageCount
	end

	return dwPageCount
end


function Table_GetBookPageID(dwBookID, dwSegmentID, nPageIndex)
	local nPageID = -1

	local tBookSegment = g_tTable.BookSegment:Search(dwBookID, dwSegmentID)
	if tBookSegment then
		nPageID = tBookSegment["dwPageID_"..nPageIndex]
	end

	return nPageID
end

function Table_GetBookName(dwBookID, dwSegmentID)
	local szBookName = ""

	local tBookSegment = g_tTable.BookSegment:Search(dwBookID, dwSegmentID)
	if tBookSegment then
		szBookName = tBookSegment.szBookName
	end

	return szBookName
end

function Table_GetSegmentName(dwBookID, dwSegmentID)
	local szSegmentName = ""

	local tBookSegment = g_tTable.BookSegment:Search(dwBookID, dwSegmentID)
	if tBookSegment then
		szSegmentName = tBookSegment.szSegmentName
	end

	return szSegmentName
end

function Table_GetBookDesc(dwBookID, dwSegmentID)
	local szDesc = ""

	local tBookSegment = g_tTable.BookSegment:Search(dwBookID, dwSegmentID)
	if tBookSegment then
		szDesc = tBookSegment.szDesc
	end

	return szDesc
end

function Table_GetBookItemIndex(dwBookID, dwSegmentID)
	local dwBookItemIndex = 0

	local tBookSegment = g_tTable.BookSegment:Search(dwBookID, dwSegmentID)
	if tBookSegment then
		dwBookItemIndex = tBookSegment.dwBookItemIndex
	end

	return dwBookItemIndex
end

function Table_GetBookNumber(dwBookID, dwSegmentID)
	local dwBookNumber = 0

	local tBookSegment = g_tTable.BookSegment:Search(dwBookID, dwSegmentID)
	if tBookSegment then
		dwBookNumber = tBookSegment.dwBookNumber
	end

	return dwBookNumber
end

function Table_GetBookContent(dwPageID)
	local szContent = ""

	local tBookPage = g_tTable.BookPage:Search(dwPageID)
	if tBookPage then
		szContent = tBookPage.szContent
	end

	return szContent
end

function Table_GetPresentExamPrint(dwBookID)
	local dwExamPrint = 0

	local tTable = g_tTable.BookEx:Search(dwBookID)
	if tTable then
		dwExamPrint = tTable.dwPresentExamPrint
	end

	return dwExamPrint
end

------------------------------craft------------------------
function Table_GetCraft(dwProfessionID, dwCraftID)
	local tCraft = g_tTable.Craft:Search(dwProfessionID, dwCraftID)

	return tCraft
end

function Table_GetAllCraftDoodadInfo()
	local tAllDoodadInfos = {}

	local nRow = g_tTable.CraftDoodad:GetRowCount()
	for i = 2, nRow  do
		local tLine = g_tTable.CraftDoodad:GetRow(i)
		table.insert(tAllDoodadInfos, tLine)
	end

	return tAllDoodadInfos
end

function Table_GetCraftDoodadInfo(nID)
	local tLine = g_tTable.CraftDoodad:Search(nID)
	return tLine
end

function Table_GetCraftDoodadID(dwTemplateID)
	local nCraftID = 0

	local nRow = g_tTable.CraftDoodad:GetRowCount()
	for i = 2, nRow  do
		local tLine = g_tTable.CraftDoodad:GetRow(i)
		if tLine.dwTemplateID == dwTemplateID then
			nCraftID = tLine.nCraftID
			break
		end
	end

	return nCraftID
end

function Table_GetCraftID(dwProfessionID)
	local dwCraftID = 0
	local tCraft = g_tTable.Craft:Search(dwProfessionID)
	if tCraft then
		dwCraftID = tCraft.dwCraftID
	end
	return dwCraftID
end

function Table_GetCraftIconID(dwProfessionID, dwCraftID)
	local dwIconID = -1

	local tCraft = g_tTable.Craft:Search(dwProfessionID, dwCraftID)
	if tCraft then
		dwIconID = tCraft.dwIconID
	end

	return dwIconID
end

function Table_GetCraftDesc(dwProfessionID, dwCraftID)
	local szDesc = ""

	local tCraft = g_tTable.Craft:Search(dwProfessionID, dwCraftID)
	if tCraft then
		szDesc = tCraft.szDesc
	end

	return szDesc
end

function Table_GetEnchantIconID(dwProfessionID, dwCraftID, dwRecipeID)
	local dwIconID = -1

	local tCraft = g_tTable.CraftEnchant:Search(dwProfessionID, dwCraftID, dwRecipeID)
	if tCraft then
		dwIconID = tCraft.dwIconID
	end

	return dwIconID
end

function Table_GetEnchantQuality(dwProfessionID, dwCraftID, dwRecipeID)
	local nQuality = -1

	local tCraft = g_tTable.CraftEnchant:Search(dwProfessionID, dwCraftID, dwRecipeID)
	if tCraft then
		nQuality = tCraft.nQuality
	end

	return nQuality
end

function Table_GetEnchantName(dwProfessionID, dwCraftID, dwRecipeID)
	local szName = ""

	local tCraft = g_tTable.CraftEnchant:Search(dwProfessionID, dwCraftID, dwRecipeID)
	if tCraft then
		szName = tCraft.szName
	end
	return szName
end

function Table_GetEnchantDesc(dwProfessionID, dwCraftID, dwRecipeID)
	local szDesc = ""

	local tCraft = g_tTable.CraftEnchant:Search(dwProfessionID, dwCraftID, dwRecipeID)
	if tCraft then
		szDesc = tCraft.szDesc
	end
	return szDesc
end

function Table_GetCraftBelongName(dwProfessionID, dwBelongID)
	local szBelongName = ""

	local tCraft = g_tTable.CraftBelongName:Search(dwProfessionID, dwBelongID)
	if tCraft then
		szBelongName = tCraft.szBelongName
	end

	return szBelongName
end

function Table_GetCraftHoleIcon(nMask)
	local nIcon = 0

	local nRow = g_tTable.CraftHole:GetRowCount()
	for i = 2, nRow  do
		local tLine = g_tTable.CraftHole:GetRow(i)
		if tLine.dwHoleMask == nMask then
			nIcon = tLine.nIconID
			break
		end
	end

	return nIcon
end

function Table_GetCraftNpcInfo(dwID)
    local tLine = g_tTable.CraftNpc:Search(dwID)
    return tLine
end

-----------------------------------------------------------------
--Output( AttributeStringToID("atEnableDoubleRide") )
local _tAttributeIndex
function GetAttributeIndex()
	if not _tAttributeIndex then
		_tAttributeIndex = {}
		local nCount = g_tTable.Attribute:GetRowCount()

		for i = 1, nCount do
			local tAttribute = g_tTable.Attribute:GetRow(i)

			local nID = AttributeStringToID(tAttribute.szAttributeName)--AttributeStringToID 属性对应id

			_tAttributeIndex[nID] = i
			_tAttributeIndex[tAttribute.szAttributeName] = i
		end
	end

	return _tAttributeIndex
end

local _tRequireIndex
function GetRequireIndex()
	if not _tRequireIndex then
		_tRequireIndex = {}
		local nCount = g_tTable.Require:GetRowCount()

		for i = 1, nCount do
			local tRequire = g_tTable.Require:GetRow(i)
			local nID = RequireStringToID(tRequire.szRequireName)
			_tRequireIndex[nID] = i
		end
	end

	return _tRequireIndex
end

function GetAttribute(nAttributeID)
	local tAttributeIndex = GetAttributeIndex()
	local tAttribute = nil
	local nIndex = tAttributeIndex[nAttributeID]
	if nIndex then
		tAttribute = g_tTable.Attribute:GetRow(nIndex)
	end

	return tAttribute
end

function GetAttributeString(nAttributeID, ...)
	if type(nAttributeID) == "string" then
		nAttributeID = AttributeStringToID(nAttributeID)
	end
	if not nAttributeID then
		return ""
	end

	local szText
	local tArg = { ... }
	if type(tArg[1]) == "number" then
		szText = FormatString(Table_GetMagicAttributeInfo(nAttributeID, true), ...)
	else
		szText = g_tStrings.tDeactives[nAttributeID]
		if not szText then
			if select("#", ...) == 0 then
				szText = FormatString(
						Table_GetMagicAttributeInfo(nAttributeID, true),
						STR_QUESTION_M, STR_QUESTION_M
				)
			else
				szText = FormatString(
						Table_GetMagicAttributeInfo(nAttributeID, true),
						...
				)
			end

		end
	end
	return string.pure_text(szText)
end

function GetRequire(nRequireID)
	local tRequireIndex = GetRequireIndex()
	local tRequire = nil

	local nIndex = tRequireIndex[nRequireID]
	if nIndex then
		tRequire = g_tTable.Require:GetRow(nIndex)
	end

	return tRequire
end

function Table_GetBaseAttributeInfo(nID, bExist)
	local szBase = ""
	local tAttribute = GetAttribute(nID)
	if tAttribute then
		if bExist then
			szBase = tAttribute.szGeneratedBase
		else
			szBase = tAttribute.szPreviewBase
		end
	end

	return szBase
end

function Table_GetRequireAttributeInfo(nID, bExist)
	local szRequire = ""
	local tRequire = GetRequire(nID)
	if tRequire then
		if bExist then
			szRequire = tRequire.szGeneratedRequire
		else
			szRequire = tRequire.szPreviewRequire
		end
	end

	return szRequire
end

function Table_GetMagicAttriStrengthValue(nID)
	local szMagic = ""
	local tAttribute = GetAttribute(nID)
	if tAttribute then
		return tAttribute.szStrengthValue
	end

	return ""
end

function Table_GetMagicAttributeInfo(nID, bExist)
	local szMagic = ""
	local tAttribute = GetAttribute(nID)
	if tAttribute then
		if bExist then
			szMagic = tAttribute.szGeneratedMagic--激活后的
		else
			szMagic = tAttribute.szPreviewMagic--未激活的
		end
	end

	return szMagic
end

function Table_GetMagicAttributeIsMobile(nID, bExist)
	local bIsMobile = false
	local tAttribute = GetAttribute(nID)
	if tAttribute then
		bIsMobile = tAttribute.bIsMobile
	end

	return bIsMobile
end


function Table_GetHorseMagicAttributeInfo(nID)
	local szMagic = ""
	local tAttribute = GetAttribute(nID)
	if tAttribute then
		szMagic = tAttribute.szHorseMagic
	end

	return szMagic
end

function Table_GetHorseBasicAttributeInfo(nID)
	local szMagic = ""
	local tAttribute = GetAttribute(nID)
	if tAttribute then
		szMagic = tAttribute.szHorseBase
	end

	return szMagic
end

-----------------------------QuestSuggest, CopySuggest, BattleFieldSuggest----------------------------------------------

function Table_GetQuestSuggest(nLevel, dwForceID)
	local tSuggestQuest = {}

	local tSuggest = g_tTable.SuggestQuest:Search(nLevel, dwForceID)
	if tSuggest then
		for i = 1, SUGGEST_QUEST_AREA_COUNT do
			if tSuggest["dwMapID" .. i] > 0 then
				local tArea = {}
				tArea.dwMapID = tSuggest["dwMapID" .. i]
				tArea.dwAreaID = tSuggest["dwAreaID" .. i]
				tArea.szAreaName = tSuggest["szAreaName" .. i]
				table.insert(tSuggestQuest, tArea)
			end
		end
	end

	if dwForceID ~= 0 then
		dwForceID = 0
		tSuggest = g_tTable.SuggestQuest:Search(nLevel, dwForceID)
		if tSuggest then
			for i = 1, SUGGEST_QUEST_AREA_COUNT do
				if tSuggest["dwMapID" .. i] > 0 then
					local tArea = {}
					tArea.dwMapID = tSuggest["dwMapID" .. i]
					tArea.dwAreaID = tSuggest["dwAreaID" .. i]
					table.insert(tSuggestQuest, tArea)
				end
			end
		end
	end

	return tSuggestQuest
end

function Table_GetSuggestMap(dwForceID, nStartLevel, nEndLevel)
	local tMark = {}
	local tMap = {}

	for i = nStartLevel, nEndLevel do
		local tSuggestArea = Table_GetQuestSuggest(i, dwForceID)
		for _, tArea in ipairs(tSuggestArea) do
			if not tMark[tArea.dwMapID] then
				table.insert(tMap, tArea)
				tMark[tArea.dwMapID] = true
			end
		end
	end
	return tMap
end

function Table_GetCopyMap(nStartLevel, nEndLevel)
	local tMark = {}
	local tMap = {}

	for i = nStartLevel, nEndLevel do
		local tSuggestCopy = Table_GetCopySuggest(i)
		for _, dwMapID in ipairs(tSuggestCopy) do
			if not tMark[dwMapID] then
				table.insert(tMap, dwMapID)
				tMark[dwMapID] = true
			end
		end
	end
	return tMap
end

function Table_GetCopySuggest(nLevel)
	local tSuggestCopy = {}
	local tSuggest = g_tTable.SuggestCopy:Search(nLevel)
	if tSuggest then
		for i = 1, SUGGEST_COPY_COUNT do
			if tSuggest["dwID" .. i] > 0 then
				table.insert(tSuggestCopy, tSuggest["dwID" .. i])
			end
		end
	end

	return tSuggestCopy
end

function Table_GetBattleFieldSuggest(nLevel)
	local tSuggestBattleField = {}
	local tSuggest = g_tTable.SuggestBattlefield:Search(nLevel)
	if tSuggest then
		for i = 1, SUGGEST_BATTLE_FIELD_COUNT do
			if tSuggest["dwID" .. i] > 0 then
				table.insert(tSuggestBattleField, tSuggest["dwID" .. i])
			end
		end
	end

	return tSuggestBattleField
end

----------------------------------------------------------------------
function Table_GetDoodadTemplateName(dwTemplateID)
	local szName = ""
	local tDoodad = g_tTable.DoodadTemplate:Search(dwTemplateID)
	if tDoodad then
		szName = tDoodad.szName
	end

	return szName
end

function Table_GetDoodadTemplateType()
	local tRet = {}
	local nCount = g_tTable.DoodadTemplateType:GetRowCount()
	for i = 2, nCount do
		local  tLine = g_tTable.DoodadTemplateType:GetRow(i)
		table.insert(tRet, tLine)
	end

	return tRet
end

function Table_GetDoodadTemplateBarText(dwTemplateID)
	local szBarText = ""
	local tDoodad = g_tTable.DoodadTemplate:Search(dwTemplateID)
	if tDoodad then
		szBarText = tDoodad.szBarText
	end

	return szBarText
end

function Table_GetNpcTemplateName(dwTemplateID)
	local szName = ""
	local tNpc = g_tTable.NpcTemplate:Search(dwTemplateID)
	if tNpc then
		szName = tNpc.szName
	end

	return szName
end

function Table_GetNpcRecoverHP(dwTemplateID)
	local tNpc = g_tTable.NpcTemplate:Search(dwTemplateID)
	if tNpc then
		return tNpc.fRecoverHP
	end

	return 0
end

function Table_GetDoodadName(dwTemplateID, dwNpcTemplateID)
	local szName = ""
	if dwNpcTemplateID ~= 0 then
		szName = Table_GetNpcTemplateName(dwNpcTemplateID)
	else
		szName = Table_GetDoodadTemplateName(dwTemplateID)
	end

	return szName
end

function Table_GetMapName(dwMapID)
	local szName = ""
	local tMap = g_tTable.MapList:Search(dwMapID)
	if tMap then
		szName = tMap.szName
	end

	return szName
end

function Table_GetMiddleMap(dwMapID)
	local tNameList = {}
	local tMap = g_tTable.MapList:Search(dwMapID)
	if tMap then
		for szName in string.gmatch(tMap.szMiddleMap, "([^;]+)") do
			table.insert(tNameList, szName)
		end
	end

	return tNameList
end

function Table_GetMapTip(dwMapID)
	local szTip = ""
	local tMap = g_tTable.MapList:Search(dwMapID)
	if tMap then
		szTip = tMap.szTip
	end

	return szTip
end

function Table_GetMapGroupID(dwMapID)
	local tMap = g_tTable.MapList:Search(dwMapID)
	if not tMap then
		return
	end

	return tMap.nGroup
end

function Table_DoesMapHaveTreasure(dwMapID)
	local tMap = g_tTable.MapList:Search(dwMapID)
	if not tMap then
		return nil
	end

	return tMap.bHasTreasure
end

function Table_GetMapMovieID(dwMapID)
	local tMap = g_tTable.MapList:Search(dwMapID)
	if not tMap then
		return 0
	end

	return tMap.nMovieID
end

function Table_GetMapFontID(dwMapID)
	local tMap = g_tTable.MapList:Search(dwMapID)
	if not tMap then
		return
	end

	return tMap.nFontID
end

function Table_GetMap(dwMapID)
	local tLine = g_tTable.MapList:Search(dwMapID)
	return tLine
end

local _mapTypeCache = {}
function Table_GetMapType(dwMapID)
	assert(dwMapID)
	if not _mapTypeCache[dwMapID] then
		local tLine = g_tTable.MapList:Search(dwMapID)
		if tLine then
			_mapTypeCache[dwMapID] = {}
			for _, szType in ipairs(tLine.szType:split(";", true)) do
				_mapTypeCache[dwMapID][szType] = true
			end
		end
	end
	return _mapTypeCache[dwMapID]
end

function Table_GetAllMapIDsWithTreasure()
	local aMaps = {}
	for i = 2, g_tTable.MapList:GetRowCount() do
		local tLine = g_tTable.MapList:GetRow(i)
		if tLine.bHasTreasure then
			table.insert(aMaps, tLine.nID)
		end
	end
	return aMaps
end

function Table_GetAllMapIDs()
	local aMaps = {}
	for i = 2, g_tTable.MapList:GetRowCount() do
		local tLine = g_tTable.MapList:GetRow(i)
		table.insert(aMaps, tLine.nID)
	end
	return aMaps
end

local _mapBalloonShieldLevelCache = {}
function Table_GetMapBalloonShieldLevel(dwMapID)
	assert(dwMapID)
	if not _mapBalloonShieldLevelCache[dwMapID] then
		---local tLine = g_tTable.BallonShield:LinearSearch((dwMapID))
		---if not tLine then
		local tLine
			local tMapTypes = Table_GetMapType(dwMapID)
			if tMapTypes then
				for _, l in ilines(g_tTable.BallonShield) do
					if tMapTypes[l.szMapType] then
						tLine = l
						break
					end
				end
			end
		---end
		if tLine then
			_mapBalloonShieldLevelCache[dwMapID] = tLine.nShieldLevel
		end
	end
	return _mapBalloonShieldLevelCache[dwMapID]
end

---------------------------以下是帮助相关的所有内容--------------------------------------
----------------------CareerComment---------------------------
function Tagle_IsExitCareerEvent(nLevel)
	local bExit = false
	local tEvent = g_tTable.CareerEvent:Search(nLevel)
	if tEvent then
		bExit = true
	end
	return bExit
end

function ParseCareerEventTab(szTab)
	local tTab = {}
	for szTabID in string.gmatch(szTab, "([%d]+);?") do
		local nTabID = tonumber(szTabID)
		table.insert(tTab, nTabID)
	end
	return tTab
end

function Table_GetCareerEvent(nLevel)
	local tCareerEvent = {}
	local tEvent = g_tTable.CareerEvent:Search(nLevel)
	tCareerEvent.nLevel = nLevel
	tCareerEvent.szTitle = tEvent.szTitle
	tCareerEvent.tTab = ParseCareerEventTab(tEvent.szTab)
	tCareerEvent.bPopUp = tEvent.bPopUp

	return tCareerEvent
end

function Table_GetCareerInfo(nLevel)
	local tInfo = {}
	local tEvent = g_tTable.CareerEvent:Search(nLevel)

	if tEvent then
		local tTabs = ParseCareerEventTab(tEvent.szTab)
		tInfo.szIntroduction = tEvent.szIntroduction
		local tTabInfo = Table_GetCareerTab(tTabs[1])
		tInfo.szImage = tTabInfo.tContent[1].szImage  --江湖指南历程分页里的图用的是历程提示界面首页的图
	end

	return tInfo
end

function Table_GetCareerAllEventTitle()
	local tCareer = {}
	local nCount = g_tTable.CareerEvent:GetRowCount()

	--Row One for default value
	for i = 2, nCount do
		local tEvent = g_tTable.CareerEvent:GetRow(i)
		local tTitle = {["szName"] = tEvent.szName, ["nLevel"] = tEvent.nLevel}
		table.insert(tCareer, tTitle)
	end

	return tCareer
end

function Table_GetCareerMap(nLevel)
	local tCareerMap = {}
	local tEvent = g_tTable.CareerEvent:Search(nLevel)
	if tEvent then
		for i = 1, CAREER_MAP_LIMIT_COUNT do
			if tEvent["nMapID" .. i] >= 0 then
				table.insert(tCareerMap, tEvent["nMapID" .. i])
			end
		end
	end
	return tCareerMap
end

function Table_GetCareerTab(nTabID)
	local tCareerTab = {}
	local tTab = g_tTable.CareerTab:Search(nTabID)

	if tTab then
		tCareerTab.nTabID = nTabID
		tCareerTab.szName = tTab.szName
		tCareerTab.szTitle = tTab.szTitle
		tCareerTab.szDescription = tTab.szDescription
		tCareerTab.tContent = {}

		for i = 1, CAREER_IMAGE_COUNT do
			local tCon = {}
			tCon.szImage = tTab["szImage" .. i]
			tCon.szNote = tTab["szNote" .. i]
			if tCon.szImage ~= "" then
				table.insert(tCareerTab.tContent, tCon)
			end
		end
	end
	return tCareerTab
end

function Table_GetCareerTabTitle(nTabID)
	local szTitle = ""
	local tTab = g_tTable.CareerTab:Search(nTabID)

	if tTab then
		szTitle = tTab.szTitle
	end

	return szTitle
end

function Table_GetCareerTabName(nTabID)
	local szName = ""
	local tTab = g_tTable.CareerTab:Search(nTabID)

	if tTab then
		szName = tTab.szName
	end

	return szName
end

function Table_GetCareerGuideAllLink(nLinkID)
	local tResult = {}
	local nCount = g_tTable.CareerGuide:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.CareerGuide:GetRow(i)
		if tLine.nLinkID == nLinkID then
			table.insert(tResult, tLine)
		end
	end
	return tResult
end

function Table_GetCareerLinkNpcInfo(nLinkID, dwMapID)
	local dwNpcID = nil

	local tLink = nil
	if dwMapID then
		tLink = g_tTable.CareerGuide:Search(nLinkID, dwMapID)
	else
		local dwCurrentMapID = UI_GetCurrentMapID()
		tLink = g_tTable.CareerGuide:Search(nLinkID, dwCurrentMapID)
		if not tLink then
			tLink = g_tTable.CareerGuide:Search(nLinkID)
		end
	end

	return tLink
end

function Table_GetLinkCount()
	local nCount = g_tTable.CareerGuide:GetRowCount()
	local tCount = {}
	local tDefaultMap = {}

	--Row One for default value
	for i = 2, nCount do
		tLink = g_tTable.CareerGuide:GetRow(i)
		if not tCount[tLink.nLinkID] then
			tCount[tLink.nLinkID] = 0
		end
		tCount[tLink.nLinkID] = tCount[tLink.nLinkID] + 1
		if not tDefaultMap[tLink.nLinkID] then
			tDefaultMap[tLink.nLinkID] = tLink.dwMapID
		end
	end
	return tCount, tDefaultMap
end

function Table_GetCurrentCareer(nLevel)
	local tCareer
	local nCount = g_tTable.CareerEvent:GetRowCount()
	for i = nCount, 2 , -1 do
		local tEvent = g_tTable.CareerEvent:GetRow(i)
		if tEvent.nLevel <= nLevel then
			tCareer = tEvent
			break
		end
	end

	return tCareer
end


-------------------------JX3知道-----------------------------------

function Table_GetJX3LibraryList()
	local nCount = g_tTable.JX3Library:GetRowCount()
	local tJX3Library = {}

	-- Row 1 for default
	local tClass
	local tSubClass
	for i = 2, nCount do
		local tLine = g_tTable.JX3Library:GetRow(i)

		local dwClassID = tLine.dwClassID
		local dwSubClassID = tLine.dwSubClassID
		local dwID = tLine.dwID

		local tRecord = {}
		tRecord.tInfo = {}
		tRecord.tInfo.dwClassID = dwClassID
		tRecord.tInfo.dwSubClassID = dwSubClassID
		tRecord.tInfo.dwID = dwID
		tRecord.tList = {}
		if dwSubClassID == 0 and dwID == 0 then
			tRecord.tInfo.szName = tLine.szClassName

			tClass = tRecord
			table.insert(tJX3Library, tRecord)
		elseif dwID == 0 then
			tRecord.tInfo.szName = tLine.szSubClassName

			tSubClass = tRecord
			table.insert(tClass.tList, tRecord)
		else

			tRecord.tInfo.szName = tLine.szTitle

			table.insert(tSubClass.tList, tRecord)
		end
	end

	return tJX3Library
end

function Table_GetJX3LibraryContent(dwClassID, dwSubClassID, dwID)
	local tRecord = g_tTable.JX3Library:Search(dwClassID, dwSubClassID, dwID)
	return tRecord
end

----------------------------------活动--------------------------------------
function Table_GetActivityList()
	local nCount = g_tTable.ActivityInfo:GetRowCount()

	local tActivity = {}

	-- Row 1 for default
	for i = 2, nCount do
		local tLine = g_tTable.ActivityInfo:GetRow(i)
		if not tActivity.tInfo then
			tActivity.tInfo = {}
			tActivity.tInfo.szName = tLine.szClassName
			tActivity.tInfo.dwClassID = tLine.dwClassID
			tActivity.tInfo.dwID = tLine.dwActivityID
			tActivity.tInfo.bActivity = true
			tActivity.tList = {}
		elseif not tActivity.tList[tLine.dwClassID] then
			tActivity.tList[tLine.dwClassID] = {}
			local tClass = tActivity.tList[tLine.dwClassID]
			tClass.tInfo = {}
			tClass.tInfo.szName = tLine.szClassName
			tClass.tInfo.dwClassID = tLine.dwClassID
			tClass.tInfo.dwID = tLine.dwActivityID
			tClass.tInfo.bActivity = true
			tClass.tList = {}
		else
			tActivity.tList[tLine.dwClassID].tList[tLine.dwActivityID] = {}
			tRecord = tActivity.tList[tLine.dwClassID].tList[tLine.dwActivityID]
			tRecord.tInfo = {}
			tRecord.tInfo.szName = tLine.szTitle
			tRecord.tInfo.dwClassID = tLine.dwClassID
			tRecord.tInfo.dwID = tLine.dwActivityID
			tRecord.tInfo.bActivity = true
			tRecord.tList = {}
		end
	end

	return tActivity
end

function Table_GetActivityContent(dwClassID, dwActivityID)
	local tRecord = g_tTable.ActivityInfo:Search(dwClassID, dwActivityID)
	return tRecord
end

--------------------日常任务---------------------------------------
function Table_GetDailyQuestList()
	local tab = g_tTable.DailyQuestInfo
	local nCount = tab:GetRowCount()

	local tQuest = {}
	-- Row 1 for default
	for i = 2, nCount do
		local tLine = tab:GetRow(i)
		local dwClassID = tLine.dwTypeID
		local dwID = tLine.dwQuestID
		if not tQuest.tInfo then
			tQuest.tInfo = {}
			tQuest.tInfo.szName = tLine.szTypeName
			tQuest.tInfo.dwClassID = dwClassID
			tQuest.tInfo.dwID = dwID
			tQuest.tInfo.bDailyQuest = true
			tQuest.tList = {}
		elseif not tQuest.tList[dwClassID] then
			tQuest.tList[dwClassID] = {}
			local tClass = tQuest.tList[dwClassID]
			tClass.tInfo = {}
			tClass.tInfo.dwClassID = dwClassID
			tClass.tInfo.dwID = dwID
			tClass.tInfo.szName = tLine.szTypeName
			tClass.tInfo.bDailyQuest = true
			tClass.tList = {}
		else
			tQuest.tList[dwClassID].tList[dwID] = {}
			local tRecord = tQuest.tList[dwClassID].tList[dwID]
			tRecord.tInfo = {}
			tRecord.tInfo.dwClassID = dwClassID
			tRecord.tInfo.dwID = dwID
			local tQuestStringInfo = Table_GetQuestStringInfo(dwID)
			tRecord.tInfo.szName = tQuestStringInfo.szName

			tRecord.tInfo.bDailyQuest = true
			tRecord.tList = {}
		end
	end

	return tQuest
end

function Table_GetDailyQuestContent(dwTypeID, dwQuestID)
	local tRecord = g_tTable.DailyQuestInfo:Search(dwTypeID, dwQuestID)
	return tRecord
end

------------------------副本介绍---------------------------------
function Table_GetDungeonList()
	local tDungeon = {}

	local nCount = g_tTable.DungeonClass:GetRowCount()

	-- this tab file has no default row
	for i = 1, nCount do
		local tLine = g_tTable.DungeonClass:GetRow(i)
		if not tDungeon.tInfo then
			tDungeon.tInfo = {}
			tDungeon.tInfo.dwClassID = tLine.dwClassID
			tDungeon.tInfo.szName = tLine.szClassName
			tDungeon.tInfo.bDungeon = true
			tDungeon.tList = {}
		else
			tDungeon.tList[tLine.dwClassID] = {}
			local tClass = tDungeon.tList[tLine.dwClassID]
			tClass.tInfo = {}
			tClass.tInfo.dwClassID = tLine.dwClassID
			tClass.tInfo.szName = tLine.szClassName
			tClass.tInfo.bDungeon = true
			tClass.tList =  {}
		end
	end

	nCount = g_tTable.DungeonInfo:GetRowCount()

	--row 1 for default
	for i = 2, nCount do
		local tLine = g_tTable.DungeonInfo:GetRow(i)
		tDungeon.tList[tLine.dwClassID].tList[tLine.dwMapID] = {}
		local tRecord = tDungeon.tList[tLine.dwClassID].tList[tLine.dwMapID]
		tRecord.tInfo = {}
		tRecord.tInfo.dwClassID = tLine.dwClassID
		tRecord.tInfo.dwID = tLine.dwMapID
		tRecord.tInfo.szName = Table_GetMapName(tLine.dwMapID)
		tRecord.tInfo.bDungeon = true
		tRecord.tList = {}
	end

	return tDungeon
end

function Table_GetVersionName2DungeonList()
	local tDungeon = {}
	local tOrderNames = {}
	local nCount = g_tTable.DungeonInfo:GetRowCount()
	--row 1 for default
	for i = 2, nCount do
		local tLine = g_tTable.DungeonInfo:GetRow(i)
		local szVersionName = Table_GetDLCInfo(tLine.nDLCID).szDLCName
		if not tDungeon[szVersionName] then
			tDungeon[szVersionName] = {
				dwMapIDMap = {},
				tRecordList = {},
				tHeadInfoList = {},
				tHeadInfoMap = {} -- 用来展示同名副本
			}
			table.insert(tOrderNames, szVersionName)
		end

		local tRecord = {}
		tRecord.dwClassID = tLine.dwClassID
		tRecord.dwMapID = tLine.dwMapID
		tRecord.nEnterMapID = tLine.nEnterMapID
		tRecord.szName = tLine.szOtherName
		tRecord.szIntroduction = tLine.szIntroduction
		tRecord.bIsPast = tLine.bIsPast
		tRecord.bRushmode = tLine.bRushmode
		tRecord.szLayer3Name = tLine.szLayer3Name
		tRecord.nFitMinLevel = tLine.nFitMinLevel
		tRecord.nFitMaxLevel = tLine.nFitMaxLevel
		tRecord.bIsRecommend = tLine.bIsRecommend
		tRecord.bHideDetail = tLine.bHideDetail
		tRecord.szReward = tLine.szReward
		tRecord.szExtReward = tLine.szExtReward
		tRecord.dwQuestID = tLine.dwQuestID
		tRecord.szVersionName = szVersionName

		if not tDungeon[szVersionName].tHeadInfoMap[tRecord.szName] then
			tDungeon[szVersionName].tHeadInfoMap[tRecord.szName] = tRecord
			table.insert(tDungeon[szVersionName].tHeadInfoList, tRecord)
		end
		tDungeon[szVersionName].dwMapIDMap[tLine.dwMapID] = tRecord
		table.insert(tDungeon[szVersionName].tRecordList, tRecord)
	end

	local fnSortTDungeon = function(tLeft, tRight)
		return tLeft.dwMapID > tRight.dwMapID
	end
	for _, tDungeonInfo in pairs(tDungeon) do
		table.sort(tDungeonInfo.tRecordList, fnSortTDungeon)
		table.sort(tDungeonInfo.tHeadInfoList, fnSortTDungeon)
	end

	return tDungeon, tOrderNames
end

function Table_GetVersionName2DungeonHeadList()
	local tDungeon = {}
	local tOrderNames = {}
	local nCount = g_tTable.DungeonInfo:GetRowCount()
	--row 1 for default
	for i = 2, nCount do
		local tLine = g_tTable.DungeonInfo:GetRow(i)
		local szVersionName = Table_GetDLCInfo(tLine.nDLCID).szDLCName
		szVersionName = UIHelper.GBKToUTF8(szVersionName)
		if not tDungeon[szVersionName] then
			tDungeon[szVersionName] = {
				tHeadInfoMap = {}, -- 副本名 -> 副本数据
				tHeadInfoList = {},-- 副本数据顺序列表
			}
			table.insert(tOrderNames, 1, szVersionName)
		end

		local tRecord = {}
		tRecord.dwClassID = tLine.dwClassID
		tRecord.dwMapID = tLine.dwMapID
		tRecord.nEnterMapID = tLine.nEnterMapID
		tRecord.szName = UIHelper.GBKToUTF8(tLine.szOtherName)
		tRecord.szIntroduction = UIHelper.GBKToUTF8(tLine.szIntroduction)
		tRecord.bIsPast = tLine.bIsPast
		tRecord.bRushmode = tLine.bRushmode
		tRecord.szLayer3Name = UIHelper.GBKToUTF8(tLine.szLayer3Name)
		tRecord.nFitMinLevel = tLine.nFitMinLevel
		tRecord.nFitMaxLevel = tLine.nFitMaxLevel
		tRecord.bIsRecommend = tLine.bIsRecommend
		tRecord.bHideDetail = tLine.bHideDetail
		tRecord.szReward = UIHelper.GBKToUTF8(tLine.szReward)
		tRecord.szExtReward = UIHelper.GBKToUTF8(tLine.szExtReward)
		tRecord.dwQuestID = tLine.dwQuestID
		tRecord.szVersionName = szVersionName

		if not tDungeon[szVersionName].tHeadInfoMap[tRecord.szName] then
			tDungeon[szVersionName].tHeadInfoMap[tRecord.szName] = {
				dwFirstMapID = tRecord.dwMapID,
				szName = tRecord.szName,
				tRecordList = {}
			}
		end
		table.insert(tDungeon[szVersionName].tHeadInfoMap[tRecord.szName].tRecordList, tRecord)
	end

	local fnSortTDungeon = function(tLeft, tRight)
		return (tLeft.dwMapID or tLeft.dwFirstMapID) > (tRight.dwMapID or tRight.dwFirstMapID)
	end
	for _, tDungeonInfo in pairs(tDungeon) do
		for _, tHeadInfo in pairs(tDungeonInfo.tHeadInfoMap) do
			table.insert(tDungeonInfo.tHeadInfoList, tHeadInfo)
			table.sort(tHeadInfo.tRecordList, fnSortTDungeon)
		end
		table.sort(tDungeonInfo.tHeadInfoList, fnSortTDungeon)
	end

	return tDungeon, tOrderNames
end

function Table_GetCanTrackingMapIDWithName(szOtherName)

	local nCount = g_tTable.DungeonInfo:GetRowCount()


	for i = 2, nCount do
		local tLine = g_tTable.DungeonInfo:GetRow(i)
		local szName = UIHelper.GBKToUTF8(tLine.szOtherName)
		if szName == szOtherName then
			local bCanTracking = DungeonData.tCheckCanTrackingMap[tLine.dwMapID]
			if bCanTracking then
				return tLine.dwMapID
			end
		end
	end
	return nil
end

function Table_GetDungeonClass(dwClassID)
	local tLine = g_tTable.DungeonClass:Search(dwClassID)

	return tLine
end

function Table_GetDungeonInfo(dwMapID)
	local tLine = g_tTable.DungeonInfo:Search(dwMapID)
	return tLine
end

function Table_GetDungeonIsPast(dwMapID)
	local tLine = g_tTable.DungeonInfo:Search(dwMapID)
	return tLine.bIsPast
end

function Table_GetDungeonMapIDListWithWindowID(nWindowID)
	local nMapIDList = {}

	local tSwitchMapInfoList = SwitchMapList[nWindowID]
    for _, tSwitchMapInfo in pairs(tSwitchMapInfoList) do
		if tSwitchMapInfo.MapID then
			table.insert(nMapIDList, tSwitchMapInfo.MapID)
		end
		for _, tInfo in ipairs(tSwitchMapInfo.child or {}) do
			table.insert(nMapIDList, tInfo.MapID)
		end
	end

	return nMapIDList
end

function Table_GetSwitchMapInfo(dwMapID, nWindowID)
	for k, v in pairs(UISwitchMapListTab) do
		if nWindowID == v.nWindowID and dwMapID == v.dwMapID then
			return v
		end
	end
end

function Table_GetDungeonSwitchMapInfo(dwMapID)
	for k, v in pairs(UISwitchMapListTab) do
		if 1 == v.nMapType and dwMapID == v.dwMapID then
			return v
		end
	end
end

function Table_GetWishItemInfoByID(dwID)
	if not dwID or dwID == 0 then
		return
	end
    local tLine = g_tTable.SpecialWishItemInfo:Search(dwID)
	return tLine
end

function Table_GetWishItemInfoList()
    local tRes = {}
    local nCount = g_tTable.SpecialWishItemInfo:GetRowCount()
    for i = 2, nCount do
        local tLine = g_tTable.SpecialWishItemInfo:GetRow(i)
        if tLine then
			if tLine.szOrItem ~= "" then
				tLine.tOrItem = {}
				for dwTabType, dwIndex in string.gmatch(tLine.szOrItem, "([%d]+);([%d]+)|?") do
					local tTemp = {tonumber(dwTabType), tonumber(dwIndex)}
					table.insert(tLine.tOrItem, tTemp)
				end
			end
			if tLine.szAndItem ~= "" then
				tLine.tAndItem = {}
				for dwTabType, dwIndex in string.gmatch(tLine.szAndItem, "([%d]+);([%d]+)|?") do
					local tTemp = {tonumber(dwTabType), tonumber(dwIndex)}
					table.insert(tLine.tAndItem, tTemp)
				end
			end
			tRes[tLine.dwID] = tLine
        end
    end
    return tRes
end
-------------------------FAQ------------------------
function Table_GetFAQList()
	local tFAQ = {}

	local nCount = g_tTable.FAQ:GetRowCount()
	--row 1 for default
	for i = 3, nCount do
		local tLine = g_tTable.FAQ:GetRow(i)

		if not tFAQ[tLine.dwClassID] then
			tFAQ[tLine.dwClassID] = {}
		else
			table.insert(tFAQ[tLine.dwClassID], tLine.dwSubClassID)
		end
	end

	return tFAQ
end

function Table_GetFAQClassName(dwClassID)
	local szName = ""

	local tResult = g_tTable.FAQ:Search(dwClassID, 0)

	if tResult then
		szName = tResult.szClassName
	end

	return szName
end

function Table_GetFAQContent(dwClassID, dwSubClassID)
	local tResult = g_tTable.FAQ:Search(dwClassID, dwSubClassID)

	return tResult
end

----------------------------------------------------------------------------------------

function Table_GetQuestStringInfo(dwQuestID)
	local tQuestStringInfo = g_tTable.Quests:Search(dwQuestID)
	if not tQuestStringInfo then

		local tbInfo = QuestData.GetQuestInfo(dwQuestID)
		if tbInfo and (tbInfo.bHungUp or tbInfo.nLevel == 255) then return nil end--策划要求这种状态不报LOG

		local szLog = "在/ui/scheme/case/Quests.tab 中找不到 QuestID = " .. dwQuestID .. "的任务，快去找相关策划处理！！"
		UILog(szLog)
	else
		if tQuestStringInfo.szMobileAcceptDes ~= "" then
			tQuestStringInfo.szAcceptDes = tQuestStringInfo.szMobileAcceptDes
		end
		if tQuestStringInfo.szMobileFinishDes ~= "" then
			tQuestStringInfo.szFinishDes = tQuestStringInfo.szMobileFinishDes
		end
		if tQuestStringInfo.szMobileObjective ~= "" then
			tQuestStringInfo.szObjective = tQuestStringInfo.szMobileObjective
		end
		if tQuestStringInfo.szMobileDescription ~= "" then
			tQuestStringInfo.szDescription = tQuestStringInfo.szMobileDescription
		end
		if tQuestStringInfo.szMobileDunningDialogue ~= "" then
			tQuestStringInfo.szDunningDialogue = tQuestStringInfo.szMobileDunningDialogue
		end
		if tQuestStringInfo.szMobileUnfinishedDialogue ~= "" then
			tQuestStringInfo.szUnfinishedDialogue = tQuestStringInfo.szMobileUnfinishedDialogue
		end
		if tQuestStringInfo.szMobileFinishedDialogue ~= "" then
			tQuestStringInfo.szFinishedDialogue = tQuestStringInfo.szMobileFinishedDialogue
		end
		if tQuestStringInfo.szMobileQuestFinishedObjective ~= "" then
			tQuestStringInfo.szQuestFinishedObjective = tQuestStringInfo.szMobileQuestFinishedObjective
		end
		if tQuestStringInfo.szMobileQuestFailedObjective ~= "" then
			tQuestStringInfo.szQuestFailedObjective = tQuestStringInfo.szMobileQuestFailedObjective
		end
		if tQuestStringInfo.szMobileQuestValueStr1 ~= "" then
			tQuestStringInfo.szQuestValueStr1 = tQuestStringInfo.szMobileQuestValueStr1
		end
		if tQuestStringInfo.szMobileQuestValueStr2 ~= "" then
			tQuestStringInfo.szQuestValueStr2 = tQuestStringInfo.szMobileQuestValueStr2
		end
		if tQuestStringInfo.szMobileQuestValueStr3 ~= "" then
			tQuestStringInfo.szQuestValueStr3 = tQuestStringInfo.szMobileQuestValueStr3
		end
		if tQuestStringInfo.szMobileQuestValueStr4 ~= "" then
			tQuestStringInfo.szQuestValueStr4 = tQuestStringInfo.szMobileQuestValueStr4
		end
		if tQuestStringInfo.szMobileQuestValueStr5 ~= "" then
			tQuestStringInfo.szQuestValueStr5 = tQuestStringInfo.szMobileQuestValueStr5
		end
		if tQuestStringInfo.szMobileQuestValueStr6 ~= "" then
			tQuestStringInfo.szQuestValueStr6 = tQuestStringInfo.szMobileQuestValueStr6
		end
		if tQuestStringInfo.szMobileQuestValueStr7 ~= "" then
			tQuestStringInfo.szQuestValueStr7 = tQuestStringInfo.szMobileQuestValueStr7
		end
		if tQuestStringInfo.szMobileQuestValueStr8 ~= "" then
			tQuestStringInfo.szQuestValueStr8 = tQuestStringInfo.szMobileQuestValueStr8
		end

		tQuestStringInfo.tProgressBar = {}
		local tProgressBar = ParsePointList(tQuestStringInfo.szProgressBar)
		for _, nValue in ipairs(tProgressBar) do
			tQuestStringInfo.tProgressBar[nValue] = true
		end
	end
	return tQuestStringInfo
end

function Table_GetQuestTypeInfo(nType)
	local tResult = g_tTable.QuestType:Search(nType)
	return tResult
end

function Table_GetQuestAllType()
	local tResult = {}
	local nWeightMax = 0
	local nCount = g_tTable.QuestType:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.QuestType:GetRow(i)
		table.insert(tResult, tLine)
		if nWeightMax < tLine.nWeight then
			nWeightMax = tLine.nWeight
		end
	end
	table.sort(tResult, function(a, b) return a.nWeight < b.nWeight end)
	return tResult, nWeightMax + 1
end

function Table_GetQuestMarkID(nLevel, szState, nType)
	local nQuestMarkID = 0
	local tTypeInfo = {}
	if IsInLishijie() then
		tTypeInfo = g_tTable.QuestType:GetRow(1)
	else
		local nCount = g_tTable.QuestType:GetRowCount()
		for i = 2, nCount do
			local tLine = g_tTable.QuestType:GetRow(i)
			if tLine.nID == nType then
				tTypeInfo = tLine
				break
			end
		end
	end

	if szState == "unaccept" then
		if nLevel == QUEST_DIFFICULTY_LEVEL.HIGH_LEVEL then
			nQuestMarkID = tTypeInfo.high_level
		elseif nLevel == QUEST_DIFFICULTY_LEVEL.LOWER_LEVEL then
			nQuestMarkID = tTypeInfo.lower_level
		else
			nQuestMarkID = tTypeInfo.unaccept
		end
	elseif szState == "finished" then
		nQuestMarkID = tTypeInfo.finished
	elseif szState == "notneedaccept" then
		nQuestMarkID = tTypeInfo.notneedaccept
	end
	return nQuestMarkID
end

function Table_GetQuestClass(dwClassID)
	local szClass = ""
	local tQuestClass = g_tTable.QuestClass:Search(dwClassID)

	if tQuestClass then
		szClass = tQuestClass.szClass
	end

	return szClass
end

function Table_GetSectionList(nSeasonID, nChapterID)
	local tResult = {}
	local nCount = g_tTable.QuestSection:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.QuestSection:GetRow(i)
		if (not nSeasonID or tLine.nSeasonID == nSeasonID)
		and (not nChapterID or tLine.nChapterID == nChapterID) then
			table.insert(tResult, tLine)
		end
	end
	return tResult
end

function Table_GetSectionLayer()
	local tSection, tLayer = {}, {}
	local nSeasonCount = 0
	local nCount = g_tTable.QuestSection:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.QuestSection:GetRow(i)
		local nSeasonID = tLine.nSeasonID
		local nChapterID = tLine.nChapterID
		if not tSection[nSeasonID] then
			tSection[nSeasonID] = {}
			nSeasonCount = nSeasonCount + 1
			tLayer[nSeasonCount] = {nSeasonID = nSeasonID, tChapterID = {}}
		end
		if not tSection[nSeasonID][nChapterID] then
			tSection[nSeasonID][nChapterID] = {}
			table.insert(tLayer[nSeasonCount].tChapterID, nChapterID)
		end
		table.insert(tSection[nSeasonID][nChapterID], tLine)
	end
	return tSection, tLayer
end

function Table_GetSectionLayerInfo(nID, szType)
	local tResult = {}
	local nIndex, nTotal = 0, 0
	local nCount = g_tTable.QuestSectionLayer:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.QuestSectionLayer:GetRow(i)
		if tLine.szType == szType then
			nTotal = nTotal + 1
			 if tLine.nID == nID then
				tResult = tLine
				nIndex = nTotal
			 end
		end
	end
	return tResult, nIndex, nTotal
end

function Table_GetSmartDialog(dwDialogID, szKey)
	local szDialog = ""
	local tDialog = g_tTable.SmartDialog:Search(dwDialogID)
	if szKey and szKey ~= "" and tDialog["sz" .. szKey] then
		szDialog = tDialog["sz" .. szKey]
	end

	return szDialog
end

function Table_GetProfessionName(dwProfessionID)
	local szName = ""
	local tProfession = g_tTable.ProfessionName:Search(dwProfessionID)
	if tProfession then
		szName = tProfession.szName
	end

	return UIHelper.GBKToUTF8(szName)
end

function Table_GetCraftName(dwCraftID)
	local szName = ""
	local tCraft = g_tTable.UICraft:Search(dwCraftID)
	if tCraft then
		szName = tCraft.szName
	end

	return UIHelper.GBKToUTF8(szName)
end

function Table_GetBranchName(dwProfessionID, dwBranchID)
	local szName = ""
	local tBranch = g_tTable.BranchName:Search(dwProfessionID, dwBranchID)
	if tBranch then
		szName = tBranch.szName
	end

	return szName
end

function Table_GetPath(szPathID)
	local nCount = g_tTable.PathList:GetRowCount()
	for i = 1, nCount do
		local tPath = g_tTable.PathList:GetRow(i)
		if tPath.szID == szPathID then
			return tPath.szPath, tPath.szPathMobile, tPath.szDisableMapID
		end
	end
end

function Table_GetSfxSize(szSfxID)
	local nCount = g_tTable.SfxSize:GetRowCount()
	for i = 1, nCount do
		local tInfo = g_tTable.SfxSize:GetRow(i)
		if tInfo.szID == szSfxID then
			return tInfo.nWidth, tInfo.nHeight
		end
	end
end

-----------------配方----------------------------------------------------------------
-- 生活技能{ID->名字}
local tCraftNames = {}

local function getRecipeTab(nCraftID)
	local szName = tCraftNames[nCraftID]
	if szName then
		return szName ~= "" and g_tTable[szName]
	end

	local tCraft = g_tTable.UICraft:Search(nCraftID)
	local szPath = tCraft and tCraft.szPath
	if szPath == "" then
		tCraftNames[nCraftID] = ""
		LOG.ERROR("KLUA[ERROR] ui\\Script\\table.lua dwCraftID = %s craft Path is nil!!", nCraftID)
		return
	end

	szName = string.match(szPath, "([^/\\]+)%.")
	assert(szName)
	tCraftNames[nCraftID] = szName

	local tCfg = Lib.copyTab(tTableFile.RecipeName)
	tCfg.Path = szPath
	tTableFile[szName] = tCfg
	return g_tTable[szName]
end

function Table_InitRecipe()
end

function Table_GetRecipeName(dwCraftID, dwRecipeID)
	local szName = ""
	-- 阅读和抄录用Table_GetBookName接口
	local tCraft = GetCraft(dwCraftID)
	if tCraft.CraftType == ALL_CRAFT_TYPE.COPY or tCraft.CraftType == ALL_CRAFT_TYPE.READ then
		local dwBookID, dwSegmentID = GlobelRecipeID2BookID(dwRecipeID)
		szName = Table_GetBookName(dwBookID, dwSegmentID)
	else
		local pTab = getRecipeTab(dwCraftID)
		local tRecipe = pTab and pTab:Search(dwRecipeID)
		if tRecipe then
			szName = tRecipe.szName
		else
			Log("KLUA[ERROR] ui\\Script\\table.lua dwCraftID = " .. dwCraftID .. "dwRecipeID = ".. dwRecipeID .. " craft Path is nil!!\n")
		end
	end

	return UIHelper.GBKToUTF8(szName)
end

function Table_GetRecipeNameVer2(dwCraftID)
	local tRes = {}
	local pTab = getRecipeTab(dwCraftID)
	if not pTab then
		return tRes
	end

	for _, tLine in ipairs(pTab) do
		tRes[tLine.dwID] = {szName = tLine.szName, nLevel = tLine.nLevel}
	end
	return tRes
end

function Table_GetRecipeTip(dwCraftID, dwRecipeID)
	local szTip = ""

	local pTab = getRecipeTab(dwCraftID)
	local tRecipe = pTab and pTab:Search(dwRecipeID)
	if tRecipe then
		szTip = tRecipe.szTip
	else
		Log("KLUA[ERROR] ui\\Script\\table.lua dwCraftID = " .. dwCraftID .. "dwRecipeID = ".. dwRecipeID .. " craft Path is nil!!\n")
	end
	return szTip
end

function Table_GetRecipeInfo(dwCraftID, dwRecipeID)
	local szTip = ""

	local pTab = getRecipeTab(dwCraftID)
	local tRecipe = pTab and pTab:Search(dwRecipeID)
	return tRecipe
end

----------------货币界面------------------------
function Table_GetCurrencyList()
	local tCurrency = {}
	local nCount = g_tTable.Currency:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.Currency:GetRow(i)
		table.insert(tCurrency, tLine)
	end
	return tCurrency
end

----------------战阶排名TIP------------------------
function Table_GetTitleRankTip(dwRank)
	local szTip = ""
	local tTitleRank = g_tTable.TitleRank:Search(dwRank)
	if tTitleRank then
		szTip = tTitleRank.szTip
	end

	return szTip
end

function Table_GetNextTitleRankPoint(dwRank)
	local dwTitlePoint = 0
	local tTitleRank = g_tTable.TitleRank:Search(dwRank)
	if tTitleRank then
		dwTitlePoint = tTitleRank.dwTitlePoint
	end

	return dwTitlePoint
end

local function OnLoadingEnd()
	g_bSkillCacheOn = true
	g_tSkillCache = {}
	g_nSkillCacheCount = 0
end

Event.Reg(g_tTable.__tEvents, "RELOAD_GLOBAL_STRINGS", ResetGlobalString)
Event.Reg(g_tTable.__tEvents, "SKILL_UPDATE", function(arg0, arg1) CorrectSkillNameToIDMap(arg0, arg1) end)
Event.Reg(g_tTable.__tEvents, "LOADING_END", OnLoadingEnd)

local bRoleFirstLogin = false
Event.Reg(g_tTable.__tEvents, "UI_LUA_RESET",
		function()
			g_bSkillCacheOn = false
			g_tSkillCache = {}
			g_nSkillCacheCount = 0
		end
)

Event.Reg(g_tTable.__tEvents, EventType.OnClientPlayerEnter, function()
	if bRoleFirstLogin then
		CorrectSkillNameToIDMap()
		bRoleFirstLogin = false
	end
end)

Event.Reg(g_tTable.__tEvents, EventType.OnRoleLogin, function(arg0, arg1)
	bRoleFirstLogin = true
end)

-----------------------------日历系统----------------------------------
function GetJoinLevel(szLevel)
	local szStart, szEnd = string.match(szLevel, "([%d]+)~([%d]+)")
	local nSrartLevel, nEndLevel
	if szStart and szEnd then
		nSrartLevel = tonumber(szStart)
		nEndLevel = tonumber(szEnd)
	end
	return nSrartLevel, nEndLevel -- 第一个等级段的最低等级作为排序依据
end

local function GetAwardContent(szAwardType)
	local szAward = ""
	local nFirstAward = -1
	local tAward = {}

	for szID, szPercentage in string.gmatch(szAwardType, "([%d]+):([%d]+);?") do--Award列 2:100;3:100;6:100;
		local dwID = tonumber(szID)
		local nPercentage = tonumber(szPercentage)
		if nFirstAward < 0 then
			nFirstAward = dwID
		else
			szAward = szAward .. g_tStrings.STR_COMMA--逗号
		end
		local tLine = g_tTable.CalenderAward:Search(dwID)
		szAward = szAward .. tLine.szName
		tAward[dwID] = nPercentage
		bFirst = false
	end

	return nFirstAward, szAward, tAward
end

local function GetAdvancedTime(szAdvancedTime)
	local tAdvancedTime = {}
	for szTime in string.gmatch(szAdvancedTime, "([%d]+);?") do
		local nTime = tonumber(szTime)
		table.insert(tAdvancedTime, nTime)
	end
	return tAdvancedTime
end

function Table_ParseCalenderActivity(tActive)
	tActive.nSortAward, tActive.szAward, tActive.tAward = GetAwardContent(tActive.szAwardType)
	tActive.szClass = g_tStrings.tActiveClass[tActive.nClass]
	tActive.tAdvancedTime = GetAdvancedTime(tActive.szAdvancedTime)
	tActive.nStartLevel, tActive.nEndLevel = GetJoinLevel(tActive.szShowLevel)
	tActive.tMap = GetAdvancedTime(tActive.szMap)
	return tActive
end

local function IsActivityFitLevel(tLine)
	local hPlayer = GetClientPlayer()
	if not hPlayer then
		return false
	end
	local nLevel = hPlayer.nLevel
	if nLevel >= tLine.nStartLevel and nLevel <= tLine.nEndLevel then
		return true
	end

	return false
end

function Table_GetCalenderOfDay(nYear, nMonth, nDay, nPosition)
	if not nPosition then
		nPosition = 1
	end
	local tDailyCalender = {}
	local nCount = g_tTable.CalenderActivity:GetRowCount()
	local nTime = DateToTime(nYear, nMonth, nDay, 7, 0, 0)
	for i = 2, nCount do -- row 1 for default
		local tLine = g_tTable.CalenderActivity:GetRow(i)
		if tLine.nEvent == CALENDER_EVENT_ALLDAY and BitwiseAnd(tLine.nShowPosition, nPosition) > 0 then
			tLine = Table_ParseCalenderActivity(tLine)
			tLine.nStartTime = nTime
			if IsActivityFitLevel(tLine) then
				table.insert(tDailyCalender, tLine)
			end
		elseif tLine.nEvent == CALENDER_EVENT_DYNAMIC and BitwiseAnd(tLine.nShowPosition, nPosition) > 0 and
			UI_IsActivityOn(tLine.dwID)
		then

			tLine = Table_ParseCalenderActivity(tLine)
			if IsActivityFitLevel(tLine) then
				tLine.nStartTime = nTime
				table.insert(tDailyCalender, tLine)
			end
		end
	end
	local hCalendar = GetActivityMgrClient()
	local tActivityList = hCalendar.GetActivityOfDay(nYear, nMonth, nDay)
	for _, tActivity in ipairs(tActivityList) do
		local tLine = g_tTable.CalenderActivity:Search(tActivity.dwID)
		if not tLine then
			Log("ui\\Scheme\\Case\\cyclopaedia\\ActicityUI.tab have no Activity for active id = " .. tActivity.dwID)
		end
		if BitwiseAnd(tLine.nShowPosition, nPosition) > 0 then
			tLine = Table_ParseCalenderActivity(tLine)
			tLine.nStartTime = tActivity.nStartTime
			tLine.nEndTime = tActivity.nEndTime
			if IsActivityFitLevel(tLine) then
				table.insert(tDailyCalender, tLine)
			end
		end
	end
	return tDailyCalender
end

function Table_GetActivityOfDay(nYear, nMonth, nDay, nPosition)
	if not nPosition then
		nPosition = 1
	end
	local tDailyActivity = {}
	local nCount = g_tTable.CalenderActivity:GetRowCount()
	local nTime = DateToTime(nYear, nMonth, nDay, 7, 0, 0)
	for i = 2, nCount do -- row 1 for default
		local tLine = g_tTable.CalenderActivity:GetRow(i)
		if tLine.nEvent == CALENDER_EVENT_ALLDAY and BitwiseAnd(tLine.nShowPosition, nPosition) > 0 then
			tLine = Table_ParseCalenderActivity(tLine)

			local tTimeInfo = {}
			tTimeInfo.nStartTime = nTime
			tTimeInfo.nEndTime = nTime + 24 * 60 * 60 - 1
			tLine.tTimeInfo = tTimeInfo
			if IsActivityFitLevel(tLine) then
				table.insert(tDailyActivity, tLine)
			end
		elseif tLine.nEvent == CALENDER_EVENT_DYNAMIC and BitwiseAnd(tLine.nShowPosition, nPosition) > 0 and
			UI_IsActivityOn(tLine.dwID)
		then

			tLine = Table_ParseCalenderActivity(tLine)
			if IsActivityFitLevel(tLine) then
				tLine.nStartTime = nTime
				table.insert(tDailyActivity, tLine)
			end
		end
	end
	local hCalendar = GetActivityMgrClient()
	local tActivityList = hCalendar.GetActivityOfDayEx(nYear, nMonth, nDay)
	if tActivityList then
		for _, tActivity in ipairs(tActivityList) do
			local tLine = g_tTable.CalenderActivity:Search(tActivity.dwID)

			if not tLine then
				Log("ui\\Scheme\\Case\\cyclopaedia\\ActicityUI.tab have no Activity for active id = " .. tActivity.dwID)
			end
			if BitwiseAnd(tLine.nShowPosition, nPosition) > 0 then
				tLine = Table_ParseCalenderActivity(tLine)
				tLine.tTimeInfo = tActivity.TimeInfo
				if IsActivityFitLevel(tLine) then
					table.insert(tDailyActivity, tLine)
				end
			end
		end
	end
	return tDailyActivity
end

function Table_GetActivityOfPeriod(nStartTime, nEndTime, nPosition)
	if not nPosition then
		nPosition = 1
	end
	local tDailyActivity = {}
	local nCount = g_tTable.CalenderActivity:GetRowCount()
	local tTime = TimeToDate(nStartTime)
	local nTime = DateToTime(tTime.year, tTime.month, tTime.day, 7, 0, 0)
	for i = 2, nCount do -- row 1 for default
		local tLine = g_tTable.CalenderActivity:GetRow(i)
		if tLine.nEvent == CALENDER_EVENT_ALLDAY and BitwiseAnd(tLine.nShowPosition, nPosition) > 0 then
			tLine = Table_ParseCalenderActivity(tLine)
			local tTimeInfo = {}
			tTimeInfo.nStartTime = nTime
			tTimeInfo.nEndTime = nTime + 24 * 60 * 60 - 1
			tLine.tTimeInfo = tTimeInfo
			if IsActivityFitLevel(tLine) then
				table.insert(tDailyActivity, tLine)
			end
		elseif tLine.nEvent == CALENDER_EVENT_DYNAMIC and BitwiseAnd(tLine.nShowPosition, nPosition) > 0 and
			UI_IsActivityOn(tLine.dwID)
		then
			tLine = Table_ParseCalenderActivity(tLine)
			if IsActivityFitLevel(tLine) then
				tLine.nStartTime = nTime
				table.insert(tDailyActivity, tLine)
			end
		end
	end
	local hCalendar = GetActivityMgrClient()
	local tActivityList = hCalendar.GetActivityOfPeriod(nStartTime, nEndTime)
	if tActivityList then
		for _, tActivity in ipairs(tActivityList) do
			local tLine = g_tTable.CalenderActivity:Search(tActivity.dwID)
			if not tLine then
				Log("ui\\Scheme\\Case\\cyclopaedia\\ActicityUI.tab have no Activity for active id = " .. tActivity.dwID)
			end
			if BitwiseAnd(tLine.nShowPosition, nPosition) > 0 then
				tLine = Table_ParseCalenderActivity(tLine)
				tLine.tTimeInfo = tActivity.TimeInfo
				if IsActivityFitLevel(tLine) then
					table.insert(tDailyActivity, tLine)
				end
			end
		end
	end
	return tDailyActivity
end

function  Table_GetCalenderActivity(dwID)
	local tLine = g_tTable.CalenderActivity:Search(dwID)
	if tLine then
		tLine = Table_ParseCalenderActivity(tLine)
		return tLine
	end
end

function  Table_GetCalenderActivityAward(dwID)
	local tLine = g_tTable.CalenderActivityAward:Search(dwID)
	if tLine then
		return tLine
	end
end

function Table_GetCalenderActivityAwardIcon(szName)
	local tIcon = {}
	local nCount = g_tTable.CalenderActivityAwardIcon:GetRowCount()

	for i = 1, nCount do
		local tLine = g_tTable.CalenderActivityAwardIcon:GetRow(i)
		if tLine.szName == szName then
			tIcon = tLine
			break
		end
	end
	return tIcon
end

function Table_GetCalenderActivityQuest(nQuestID)
	local tLine = g_tTable.CalenderActivityQuest:Search(nQuestID)
	if tLine then
		return tLine
	end
end

function Table_GetCalenderActivityName(dwID)
	local tLine = Table_GetCalenderActivity(dwID)
	if tLine then
		return tLine.szName
	end
end

----------------------------Avatar-----------------------------
function Table_GetPlayerMiniAvatars()
	local tAvatar = {}
	local nCount = g_tTable.PlayerAvatar:GetRowCount()

	for i = 1, nCount do
		local tLine = g_tTable.PlayerAvatar:GetRow(i)
		local dwIndex = tLine.dwPlayerMiniAvatarID
		tAvatar[dwIndex] = {}
		tAvatar[dwIndex]["dwType"] = tLine.dwType
		tAvatar[dwIndex]["dwKindID"] = tLine.dwKindID
		tAvatar[dwIndex]["szFileName"] = tLine.szFileName
	end

	return tAvatar
end

function Table_GetPlayerMiniAvatarsFromType(dwType)
	local tAvatar = {}
	local nCount = g_tTable.PlayerAvatar:GetRowCount()
	local dwIndex = 1

	for i = 1, nCount do
		local tLine = g_tTable.PlayerAvatar:GetRow(i)
		if tLine.dwType == dwType then
			tAvatar[dwIndex] = {}
			tAvatar[dwIndex]["dwID"] = tLine.dwPlayerMiniAvatarID
			tAvatar[dwIndex]["dwKindID"] = tLine.dwKindID
			tAvatar[dwIndex]["szFileName"] = tLine.szFileName
			dwIndex = dwIndex + 1
		end
	end

	return tAvatar
end

function Table_GetPlayerMiniAvatarsFromKindID(dwKindID)
	local tAvatar = {}
	local nCount = g_tTable.PlayerAvatar:GetRowCount()
	local dwIndex = 1

	for i = 1, nCount do
		local tLine = g_tTable.PlayerAvatar:GetRow(i)
		if tLine.dwKindID == dwKindID then
			tAvatar[dwIndex] = {}
			tAvatar[dwIndex]["dwID"] = tLine.dwPlayerMiniAvatarID
			tAvatar[dwIndex]["dwType"] = tLine.dwType
			tAvatar[dwIndex]["szFileName"] = tLine.szFileName
			dwIndex = dwIndex + 1
		end
	end

	return tAvatar
end

function Table_GetPlayerMiniAvatarsFromTypeAndKindID(dwType, dwKindID)
	local tAvatar = {}
	local nCount = g_tTable.PlayerAvatar:GetRowCount()
	local dwIndex = 1

	for i = 1, nCount do
		local tLine = g_tTable.PlayerAvatar:GetRow(i)

		if tLine.dwKindID == dwKindID and tLine.dwType == dwType then
			tAvatar[dwIndex] = {}
			tAvatar[dwIndex]["dwID"] = tLine.dwPlayerMiniAvatarID
			tAvatar[dwIndex]["szFileName"] = tLine.szFileName
			dwIndex = dwIndex + 1
		end
	end

	return tAvatar
end

-- local tSchoolColor =
-- {
-- 	[0] = { R = 255, G = 255, B = 255 },
-- 	[1] = { R = 203, G = 54, B = 54 },
-- 	[2] = { R = 196, G = 152, B = 255 },
-- 	[3] = { R = 83, G = 224, B = 232 },
-- 	[4] = { R = 255, G = 129, B = 176 },
-- 	[5] = { R = 249, G = 164, B = 73 },
-- 	[6] = { R = 214, G = 249, B = 93 },
-- 	[7] = { R = 251, G = 192, B = 132 },
-- 	[8] = { R = 255, G = 111, B = 83 },
-- 	[9] = { R = 120, G = 149, B = 226 },
-- 	[10] = { R = 56, G = 130, B = 163 },
-- 	[18] = { R = 220, G = 30, B = 0 },
-- 	[19] = { R = 0, G = 180, B = 190 },
-- 	[20] = { R = 106, G = 108, B = 189 },
-- }

-- function Table_GetSchoolColor(dwSchoolID)
-- 	if not tSchoolColor[dwSchoolID] then
-- 		dwSchoolID = 0
-- 	end
-- 	return tSchoolColor[dwSchoolID].R, tSchoolColor[dwSchoolID].G, tSchoolColor[dwSchoolID].B
-- end

-----------------宠物技能-----------

function Table_GetPetSkill(dwNpcTemplateID)
	local tPetSkill = g_tTable.PetSkill:Search(dwNpcTemplateID)
	if not tPetSkill then
		return
	end
	local tSkill = {}
	for i = 1, PET_SKILL_COUNT do
		if tPetSkill["nSkillID" .. i] <= 0 then
			break
		end
		table.insert(tSkill, {tPetSkill["nSkillID" .. i], tPetSkill["nLevel" .. i]})
	end
	return tSkill
end

function Table_GetPetAvatar(dwNpcTemplateID)
	local tPet = g_tTable.PetSkill:Search(dwNpcTemplateID)
	if not tPet then
		return
	end
	return tPet.szAvatarPath
end

function Table_GetPetSkillChange(dwNpcTemplateID)
	local tRetList = {}
	local nCount = g_tTable.PetSkillChange:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.PetSkillChange:GetRow(i)
		if tLine.dwNpcTemplateID == dwNpcTemplateID then
			local tSkill = {}
			tSkill.dwNpcTemplateID = tLine.dwNpcTemplateID
			tSkill.nOldSkillID = tLine.nOldSkillID
			tSkill.nOldSkillLevel = tLine.nOldSkillLevel
			tSkill.nNewSkillID = tLine.nNewSkillID
			tSkill.nNewSkillLevel = tLine.nNewSkillLevel
			tSkill.tQixueSkillList = StringParse_Numbers(tLine.szQixueSkillList)
			table.insert(tRetList, tSkill)
		end
	end
	return tRetList
end

-----------------宠物动作-----------
function Table_GetAnimalAction(dwAnimalID)
	local tAnimalAction = {}

	local nCount = g_tTable.AnimalAction:GetRowCount()

	for i = 1, nCount do
		local tLine = g_tTable.AnimalAction:GetRow(i)

		if tLine.dwID == dwAnimalID then
			table.insert(tAnimalAction, {tLine.szDesc, tLine.nCommand})
		end
	end

	if not tAnimalAction then
		return
	end

	return tAnimalAction
end

----------------------FieldPQ------------------------------
function Table_GetFieldPQ(dwPQTemplateID)
	local tFieldPQ = g_tTable.FieldPQ:Search(dwPQTemplateID)
	tFieldPQ.tIdentityVisibleID = ParsePointList(tFieldPQ.szIdentityVisibleID)

	return tFieldPQ
end

function Table_GetFieldPQString(dwPQTemplateID, nStep)
	local tPQString = g_tTable.FieldPQSetp:Search(dwPQTemplateID, nStep)

	return tPQString
end

function Table_GetFieldPQList()
	local tFieldPQ = {}

	local nCount = g_tTable.FieldPQ:GetRowCount()

	--row 1 for default
	for i = 2, nCount do
		local tLine = g_tTable.FieldPQ:GetRow(i)
		if not tFieldPQ.tInfo then
			tFieldPQ.tInfo = {}
			tFieldPQ.tInfo.dwClassID = tLine.dwPQTemplateID
			tFieldPQ.tInfo.szName = tLine.szName
			tFieldPQ.tInfo.bFieldPQ = true
			tFieldPQ.tList = {}
		else
			tFieldPQ.tList[tLine.dwPQTemplateID] = {}
			local tClass = tFieldPQ.tList[tLine.dwPQTemplateID]
			tClass.tInfo = {}
			tClass.tInfo.dwClassID = tLine.dwPQTemplateID
			tClass.tInfo.szName = tLine.szName
			tClass.tInfo.bFieldPQ = true
			tClass.tList =  {}
		end
	end

	nCount = g_tTable.FieldPQSetp:GetRowCount()

	--row 1 for default
	for i = 2, nCount do
		local tLine = g_tTable.FieldPQSetp:GetRow(i)
		tFieldPQ.tList[tLine.dwPQTemplateID].tList[tLine.nSetpID] = {}
		local tRecord = tFieldPQ.tList[tLine.dwPQTemplateID].tList[tLine.nSetpID]
		tRecord.tInfo = {}
		tRecord.tInfo.dwClassID = tLine.dwPQTemplateID
		tRecord.tInfo.dwID = tLine.nSetpID
		tRecord.tInfo.szName = tLine.szName
		tRecord.tInfo.bFieldPQ = true
		tRecord.tList = {}
	end

	return tFieldPQ
end

function Table_LoadSceneFieldPQ()
	local nCount = g_tTable.FieldPQ:GetRowCount()

	-- 第三行开始才是真正的PQ，第一行是默认值，第二行是对PQ的介绍
	for i = 3, nCount do
		local tLine = g_tTable.FieldPQ:GetRow(i)
		if not tAllSceneFieldPQ[tLine.dwMapID] then
			tAllSceneFieldPQ[tLine.dwMapID] = {}
		end
		table.insert(tAllSceneFieldPQ[tLine.dwMapID], tLine.dwPQTemplateID)
	end
end

function Table_GetSceneFieldPQ(dwMapID)
	if IsTableEmpty(tAllSceneFieldPQ) then
		Table_LoadSceneFieldPQ()
	end
	local tSceneFieldPQ = {}
	if tAllSceneFieldPQ[dwMapID] then
		tSceneFieldPQ = tAllSceneFieldPQ[dwMapID]
	end

	return tSceneFieldPQ
end


---------------------------------------------------------------------------
local function GetCyclopaediaSkills(szSkill)
	local tSkill = {}
	for nSkillID, nLevel in string.gmatch(szSkill, "([%d]+),([%d]+);?") do
		table.insert(tSkill, {nSkillID, nLevel})
	end
	return tSkill
end
function Table_GetCyclopaediaSkill()
	local nCount = g_tTable.CyclopaediaSkill:GetRowCount()
	local tCyclopaediaSkill = {}
	--row 1 for default
	for i = 2, nCount do
		local tLine = g_tTable.CyclopaediaSkill:GetRow(i)
		if not tCyclopaediaSkill[tLine.nSectionID] then
			tCyclopaediaSkill[tLine.nSectionID] = {}
		end
		local tSkill = GetCyclopaediaSkills(tLine.szSkill)
		tCyclopaediaSkill[tLine.nSectionID][tLine.nForceID] = tSkill
	end
	return tCyclopaediaSkill
end


------------------------------------------------------
-------------------------------------天工树--------------------------------

function Table_GetTongTechTreeNodeInfo(nNodeID, nLevel)
	local tNode = g_tTable.TongTechTreeNode:Search(nNodeID, nLevel)

	return tNode
end

---------------------------------活动标记--------------------
local function GetSymbolList(szPosition)
	local tPointList = {}
	for nX, nY in string.gmatch(szPosition, "([%d]+),([%d]+);?") do
		table.insert(tPointList, {nX, nY})
	end
	return tPointList
end

function Table_GetActivitySymbol(dwMapID, nSymbolID)
	local tLine = g_tTable.ActivitySymbolInfo:Search(dwMapID, nSymbolID)
	local tPointList = {}
	if tLine then
		tLine.tPointList = GetSymbolList(tLine.szPositions)
	end

	return tLine
end


---------------------------CG选择列表------------------
function Table_GetCGList()
	local nCount = g_tTable.CGList:GetRowCount()
	--row 1 for default
	local tList = {}
	for i = 2, nCount do
		local tLine = g_tTable.CGList:GetRow(i)
		tLine.bDisable = false
		if tLine.szCGPath == "" and tLine.szDowloadUrl == "" then
			tLine.bDisable = true
		end
		table.insert(tList, tLine)
	end

	return tList
end

------------------------帮会活动---------------------------------
function Table_GetTongActivityList()
	local nCount = g_tTable.TongActivity:GetRowCount()
	local tTongActivity = {}

	-- Row 1 for default
	local tClass
	local tSubClass
	for i = 2, nCount do
		local tLine = g_tTable.TongActivity:GetRow(i)

		local dwClassID = tLine.dwClassID
		local dwSubClassID = tLine.dwSubClassID
		local dwID = tLine.dwID

		local tRecord = {}
		tRecord.tInfo = {}
		tRecord.tInfo.dwClassID = dwClassID
		tRecord.tInfo.dwSubClassID = dwSubClassID
		tRecord.tInfo.dwID = dwID
		tRecord.tList = {}
		tRecord.tInfo.szName = tLine.szName
		if dwSubClassID == 0 and dwID == 0 then
			tClass = tRecord
			tTongActivity[dwClassID] = tRecord
		elseif dwID == 0 then
			tSubClass = tRecord
			table.insert(tClass.tList, tRecord)
		else
			table.insert(tSubClass.tList, tRecord)
		end
	end

	return tTongActivity
end

function Table_GetTongActivityContent(dwClassID, dwSubClassID, dwID)
	local tRecord = g_tTable.TongActivity:Search(dwClassID, dwSubClassID, dwID)
	return tRecord
end

function Table_GetActiviyTipDesc(dwActivityID)
	local tLine = g_tTable.ActivityTip:Search(dwActivityID)
	if not tLine then
		Log("ActivityTip no tip dwActivityID " .. dwActivityID)
	end

	return tLine
end

function Table_GetActiviyTimeDesc(dwActivityID)
	local tLine = g_tTable.ActivityTip:Search(dwActivityID)
	if not tLine then
		UILog("ActivityTip no tip dwActivityID " .. dwActivityID)
	end

	return tLine.szTimeDesc
end

-----------------机关技能-----------

local function ParsePuppetGroup(szGroup)
	local tGroup
	for szCount in string.gmatch(szGroup, "([%w]+);?") do
		local nCount = tonumber(szCount)
		if not tGroup then
			tGroup = {}
		end
		table.insert(tGroup, nCount)
	end
	return tGroup
end

function Table_GetPuppetSkill(dwNpcTemplateID)
	local tPuppetSkill = g_tTable.PuppetSkill:Search(dwNpcTemplateID)
	if not tPuppetSkill then
		return
	end
	local tSkill = {}
	for i = 1, PUPPET_SKILL_COUNT do
		if tPuppetSkill["nSkillID" .. i] <= 0 then
			break
		end
		table.insert(tSkill, {tPuppetSkill["nSkillID" .. i], tPuppetSkill["nLevel" .. i]})
	end

	local tGroup = ParsePuppetGroup(tPuppetSkill.szGroup)
	if not tGroup then
		tGroup = {}
		table.insert(tGroup, #tSkill)
	end
	return tSkill, tGroup
end

function Table_GetPlayerAwardRemind()
	local tRemind = {}
	local hPlayer = GetClientPlayer()
	if not hPlayer then
		return tRemind
	end

	local nCount = g_tTable.AwardRemind:GetRowCount()
	for i = 2 , nCount do
		local tLine = g_tTable.AwardRemind:GetRow(i)
		if hPlayer.GetQuestState(tLine.dwQuestID) ~= QUEST_STATE.FINISHED then
			table.insert(tRemind, tLine)
		end
	end

	return tRemind
end

local function ParseCombatType(szCombatType)
	local tList = {}
	for s in string.gmatch(szCombatType, "%d+") do
		local dwID = tonumber(s)
		if dwID then
			tList[dwID] = true
		end
	end
	return tList
end

function Table_GetCreateRoleParam()
	local tResult = {}
	local nRow = g_tTable.CreateRole_Param:GetRowCount()
	for i = 2, nRow do
		local tLine = g_tTable.CreateRole_Param:GetRow(i)
		tResult[tLine.szSchoolType] = tLine
	end
	return tResult
end

function Table_GetCreateRoleTable(dwKungfu)
	local tResult = {}
	local nRow = g_tTable.CreateRole_Param:GetRowCount()
	for i = 2, nRow do
		local tLine = g_tTable.CreateRole_Param:GetRow(i)
		if tLine.dwKungfuIndex == dwKungfu then
			tLine.tCombatType = ParseCombatType(tLine.szCombatType)
			return tLine
		end
	end
end

function Table_GetAllKungfuID()
	local tResult = {}
	local nRow = g_tTable.CreateRole_Param:GetRowCount()
	for i = 2, nRow do
		local tLine = g_tTable.CreateRole_Param:GetRow(i)
		table.insert(tResult, tLine.dwKungfuIndex)
	end
	return tResult
end

function Table_GetMapGroup(dwID)
	local tLine = g_tTable.MapGroup:Search(dwID)

	return tLine
end

function Table_GetFirstLoginSkill(dwKungfuID)
	local tLine = g_tTable.FirstLoginSkill:Search(dwKungfuID)

	return tLine
end
-----------------------------------------------

local tExteriorMap = {}

function LoadExteriorMap()
	if tExteriorMap.tSetArray then
		return
	end
	local nCount = g_tTable.ExteriorBox:GetRowCount()
	local tGenreMap = {}
	local tSubGenreMap = {}
	local tSetMap = {}
	local tSetArray = {}
	local tSub = {}
	local tClassMap = {}
	for i = 2, nCount do
		local tLine = g_tTable.ExteriorBox:GetRow(i)
		if tLine.szGenreName ~= "" then
			tGenreMap[tLine.nGenre] = tLine.szGenreName
		end

		if tLine.szSubGenreName ~= "" then
			tSubGenreMap[tLine.nSubGenre] = tLine.szSubGenreName
		end

		if tLine.nClass then
			tClassMap[tLine.nClass] = tClassMap[tLine.nClass] or {}
			table.insert(tClassMap[tLine.nClass], tLine)
		end

		tSub = {}
		for i = 1, 5 do
			local dwExteriorID = tLine["nSub" .. i]
			if dwExteriorID > 0 then
				table.insert(tSub, dwExteriorID)
			end
		end
		tLine.tSub = tSub
		table.insert(tSetArray, tLine)
		tSetMap[tLine.nSet] = #tSetArray
	end
	tExteriorMap.tGenreMap = tGenreMap
	tExteriorMap.tSubGenreMap = tSubGenreMap
	tExteriorMap.tSetMap = tSetMap
	tExteriorMap.tSetArray = tSetArray
	tExteriorMap.tClassMap = tClassMap
end

function Table_GetExteriorGenreName(nGenre)
	LoadExteriorMap()
	local tGenreMap = tExteriorMap.tGenreMap
	local szGenreName = ""
	if tGenreMap[nGenre] then
		szGenreName = tGenreMap[nGenre]
	end
	return szGenreName
end

function Table_GetExteriorSubGenreName(nSubGenre)
	LoadExteriorMap()
	local tSubGenreMap = tExteriorMap.tSubGenreMap
	local szSubGenreName = ""
	if tSubGenreMap[nSubGenre] then
		szSubGenreName = tSubGenreMap[nSubGenre]
	end
	return szSubGenreName
end

function Table_GetExteriorSetName(nGenre, nSet)
	LoadExteriorMap()
	local tSetMap = tExteriorMap.tSetMap
	local szSetName = ""
	local nIndex = tSetMap[nSet]
	if nIndex then
		local tLine = tExteriorMap.tSetArray[nIndex]
		szSetName = tLine.szSetName
	end
	return szSetName
end

function Table_GetExteriorSet(nSet)
	LoadExteriorMap()
	local tSetMap = tExteriorMap.tSetMap
	local nIndex = tSetMap[nSet]
	local tLine
	if nIndex then
		tLine = tExteriorMap.tSetArray[nIndex]
	end
	return tLine
end

function Table_GetExteriorArray()
	LoadExteriorMap()
	return tExteriorMap.tSetArray
end

function Table_GetExteriorClass(nClass)
	LoadExteriorMap()
	local tClassMap = tExteriorMap.tClassMap
	local tClass = {}
	if tClassMap[nClass] then
		tClass = tClassMap[nClass]
	end
	return tClass
end
---------------------------------------------------------------

function Table_GetChaptersInfo(dwChapterID)
	local tLine = g_tTable.Chapters:Search(dwChapterID)
	return tLine
end

function Table_GetCanExteriorDesc(dwCanExterior)
	local szDesc = ""
	local tLine = g_tTable.CanExterior:Search(dwCanExterior)
	if tLine then
		szDesc = tLine.szDesc
	end

	return szDesc
end

function Table_GetShowWord(nCubSubType)
	local tLine = g_tTable.ShowWord:Search(nCubSubType)

	return tLine
end

function Table_GetDomesticateEvent(nEventID)
	local tLine = g_tTable.DomesticateEvent:Search(nEventID)

	return tLine
end

function Table_GetCubInfo(dwAdultTabIndex)
	local tLine = g_tTable.CubInfo:Search(dwAdultTabIndex)

	return tLine
end

local _tCubAttributeIndex
function GetCubAttributeIndex()
	if not _tCubAttributeIndex then
		_tCubAttributeIndex = {}
		local nCount = g_tTable.CubAttribute:GetRowCount()

		for i = 1, nCount do
			local tAttribute = g_tTable.CubAttribute:GetRow(i)
			local nID = AttributeStringToID(tAttribute.szAttributeName)
			_tCubAttributeIndex[nID] = i
		end
	end

	return _tCubAttributeIndex
end

function Table_GetCubAttribute(nAttributeID)
	local tCubAttributeIndex = GetCubAttributeIndex()
	local tAttribute = nil
	local nIndex = tCubAttributeIndex[nAttributeID]
	local tLine
	if nIndex then
		tLine = g_tTable.CubAttribute:GetRow(nIndex)
		tLine.nAttributeID = nAttributeID
	end

	return tLine
end

function Table_GetFellowPet(dwIndex)
	local tLine = g_tTable.FellowPet:Search(dwIndex)
	return tLine
end

function Table_GetFellowPetIconID(dwIndex)
	local nIconID = -1
	local tLine = g_tTable.FellowPet:Search(dwIndex)
	if tLine then
		nIconID = tLine.nIconID
	end
	return nIconID
end

function Table_GetAllFellowPet()
	local tPetList = {}
	local nCount = g_tTable.FellowPet:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.FellowPet:GetRow(i)
		if tLine.bShow then
			table.insert(tPetList, tLine)
		end
	end

	return tPetList
end

function Table_GetFellowPet_SearchList()
	local tSearch = {}
	local nCount = g_tTable.FellowPetSearch:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.FellowPetSearch:GetRow(i)
		local nType = tLine.nType
		if not tSearch[nType] then
			tSearch[nType] = {}
		end

		local dwID = tLine.dwID
		local szName = tLine.szTypeName
		table.insert(tSearch[nType], {dwID, szName})
	end

	return tSearch
end

function Table_GetFellowPet_Class(dwID)
	local tLine = {}
	local nCount = g_tTable.FellowPetClass:GetRowCount()
	for i = 2, nCount do
		local t = g_tTable.FellowPetClass:GetRow(i)
		if dwID == t.dwID then
			tLine = t
			break
		end
	end
	return tLine
end

function Table_GetFellowPet_Medal(dwID)
	local tMedal = {}
	local nCount = g_tTable.FellowPetMedal:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.FellowPetMedal:GetRow(i)
		if tLine.dwID == dwID then
			tMedal = tLine
			break
		end
	end

	return tMedal
end

function Table_GetAchievement(dwAchievement)
	local aAchievement 	= g_tTable.Achievement:Search(dwAchievement)
	if not aAchievement then
		local szLog = "在\\ui\\Scheme\\Case\\achievement.txt 中找不到 dwAchievementID = " .. dwAchievement .. "的成就，快去找相关策划处理！！"
		UILog(szLog)
	end
	return aAchievement
end

function Table_GetAchievementName(dwAchievement)
	local aAchievement 	= Table_GetAchievement(dwAchievement)
	if not aAchievement then
		return ""
	end
	return aAchievement.szName
end

function Table_GetFellowPet_Achievement(nScore)
	local szName
	local nCount = g_tTable.FellowPetAchievement:GetRowCount()
	for i = 1, nCount do--无默认列; i=1开始
		local tLine = g_tTable.FellowPetAchievement:GetRow(i)
		if nScore >= tLine.nStartScore and nScore <= tLine.nEndScore then
			szName = tLine.szName
			break
		end
	end
	return szName
end

function Table_GetFellowPetSkill(dwPetIndex)
	local tPetSkill = g_tTable.FellowPetSkill:Search(dwPetIndex)
	if not tPetSkill then
		return
	end
	local tSkill = {}
	for i = 1, 15 do
		if tPetSkill["nSkillID" .. i] <= 0 then
			break
		end
		table.insert(tSkill, {tPetSkill["nSkillID" .. i], tPetSkill["nLevel" .. i]})
	end
	return tSkill
end

function Table_GetMapListByKungfu(dwKungfuID)
	local tMapList = {}
	local nCount = g_tTable.MPakByKungfu:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.MPakByKungfu:GetRow(i)

		if tLine.dwKungfuID == dwKungfuID then
			table.insert(tMapList, tLine.dwMapID)
		end
	end

	return tMapList
end

---连击配置的读表---
function Table_GetSkillGuideList(dwKungFuID, nLevel)
	local tDefault = {}
	local nStart, nEnd
	local  nCount = g_tTable.SkillGuide:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.SkillGuide:GetRow(i)
		nStart, nEnd = GetJoinLevel(tLine.szLevel)
		if tLine.dwKungFuID == dwKungFuID and tLine.bDefault and
			nLevel >= nStart and nLevel <= nEnd
		then
			tDefault = ParseIDList(tLine.szSkillList)
			break
		end
	end
	return tDefault, nStart
end

function Table_GetGuideSoultion(dwKungFuID, nLevel)
	local tSolutions = {}
	local  nCount = g_tTable.SkillGuide:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.SkillGuide:GetRow(i)
		local nStart, nEnd = GetJoinLevel(tLine.szLevel)
		if tLine.dwKungFuID == dwKungFuID and
			nLevel >= nStart and nLevel <= nEnd
		then
			if not tLine.bDefault then
				local tSolution = {}
				tSolution.tSkillList = ParseIDList(tLine.szSkillList)
				tSolution.szName = tLine.szName
				tSolution.tQixueList = StringParse_Numbers(tLine.szQixueList)
				table.insert(tSolutions, tSolution)
			end
		end
	end

	return tSolutions
end

function Table_GetSkillLimitList(dwKungFuID)
	local tSkillLimitList = {}

	local  nCount = g_tTable.SkillGuide:GetRowCount()

	for i = 2, nCount do
		local tLine = g_tTable.SkillGuide:GetRow(i)
		if tLine.dwKungFuID == dwKungFuID and tLine.bDefault then
			tSkillLimitList = ParseIDList(tLine.szSkillLimitList)
			break
		end
	end

	return tSkillLimitList
end

function Table_GetSkillGuideNext(dwSkillID)
	local tLine = g_tTable.SkillGuideNext:Search(dwSkillID)
	if tLine and tLine.dwSkillNext > 0 then
		return tLine.dwSkillNext
	end
end
----------------------------------------------------

function Table_GetSkillSchoolKungfu(dwSchoolID)
	local tKungFungList = {}

	local tLine = g_tTable.SkillSchoolKungfu:Search(dwSchoolID)
	if tLine then
		local szKungfu = tLine.szKungfu
		for s in string.gmatch(szKungfu, "%d+") do
			local dwID = tonumber(s)
			if dwID then
				table.insert(tKungFungList, dwID)
			end
		end
	end

	return tKungFungList
end

function Table_GetDefaultLine(dwForceID, dwKungfuID)
	local dwID = ""
	local tLine = nil

	tLine = g_tTable.ZhenPaiLine:Search(dwForceID, dwKungfuID)
	if not tLine then
		tLine = g_tTable.ZhenPaiLine:Search(dwForceID, 0)
	end

	if tLine and tLine.dwDefaultLineID then
		dwID = tLine.dwDefaultLineID
	end

	return dwID
end

function Table_GetZhenPaiLines(dwForceID, dwKungfuID)
	local szLine = ""
	local tLine = nil
	local t = {}

	tLine = g_tTable.ZhenPaiLine:Search(dwForceID, dwKungfuID)

	if not tLine then
		tLine = g_tTable.ZhenPaiLine:Search(dwForceID, 0)
	end

	if tLine and tLine.szTotalLine then
		szLine = tLine.szTotalLine
		for s in string.gmatch(szLine, "%d+") do
			local nLine = tonumber(s)
			if nLine then
				table.insert(t, nLine)
			end
		end
	end

	return t
end

function Table_GetZhenPaiLinesInfo(dwLineID)
	local szLineInfo = ""
	local t = {}

	local tLine = g_tTable.ZhenPaiLineInfo:Search(dwLineID)

	if tLine and tLine.szLineInfo then
		szLineInfo = tLine.szLineInfo
		for dwId, nLevel in string.gmatch(szLineInfo, "([%d]+),([%d]+);?") do
			table.insert(t, {dwId, nLevel})
		end
	end

	return t
end

function Table_GetZhenPaiLinesName(dwLineID)
	local szLineName = ""

	local tLine = g_tTable.ZhenPaiLineInfo:Search(dwLineID)

	if tLine and tLine.szLineName then
		szLineName = tLine.szLineName
	end

	return szLineName
end

function Table_GetProtocolToAviPath(nID)
	local szPath = ""

	local tLine = g_tTable.ProtocolToAvi:Search(nID)
	if tLine then
		szPath = tLine.szAviPath
	end

	return szPath
end


function Table_GetRideModelInfo(dwRepresentID)
	return g_tTable.RideModelView:Search(dwRepresentID)
end

function Table_GetAwardFurnitureModelInfo(dwFurnitureID)
	return g_tTable.AwardFurnitureModelInfo:Search(dwFurnitureID)
end

function Table_GetNewDungeonList()
	local hPlayer = GetClientPlayer()
	if not hPlayer then
		return
	end

	local tTeamDMap = {}
	local tRaidDMap = {}
	local tDivideMap = {}

	local nCount = g_tTable.DungeonInfo:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.DungeonInfo:GetRow(i)
		local _, _, nMaxPlayerCount = GetMapParams(tLine.dwMapID)
		tLine.nMaxPlayerCount = nMaxPlayerCount

		local tDungeon
		if tLine.dwClassID == 1 or tLine.dwClassID == 2 then
			if not tTeamDMap[tLine.szOtherName] then
				tTeamDMap[tLine.szOtherName] = {}
				tTeamDMap[tLine.szOtherName].dwMapID = tLine.dwMapID
			end

			table.insert(tTeamDMap[tLine.szOtherName], tLine)
			tDungeon = tTeamDMap[tLine.szOtherName]
			tDungeon.bRaid = false

		elseif tLine.dwClassID == 3 then
			if not tRaidDMap[tLine.szOtherName] then
				tRaidDMap[tLine.szOtherName] = {}
				tRaidDMap[tLine.szOtherName].dwMapID = tLine.dwMapID
			end

			tRaidDMap[tLine.szOtherName][tLine.szLayer3Name] =  tLine
			tDungeon = tRaidDMap[tLine.szOtherName]
			tDungeon.bRaid = true
		end

		if tDungeon then
			local nState
			if hPlayer.nLevel < tLine.nMinLevel then
				nState = DUNGEON_LEVEL_HIGH
			elseif hPlayer.nLevel <= tLine.nFitMaxLevel then
				tDungeon.nState = DUNGEON_LEVEL_FIT
			else
				tDungeon.nState = DUNGEON_LEVEL_LOW
			end

			if not tDungeon.nState or tDungeon.nState > nState then
				tDungeon.nState = nState
			end

			if not tDungeon.nMinLevel or tDungeon.nMinLevel > tLine.nMinLevel then
				tDungeon.nMinLevel = tLine.nMinLevel
			end


			tDungeon.szName = tLine.szOtherName
			tDungeon.szDungeonImage1 = tLine.szDungeonImage1
			tDungeon.nDungeonFrame1 = tLine.nDungeonFrame1
			tDungeon.szDungeonImage2 = tLine.szDungeonImage2
			tDungeon.nDungeonFrame2 = tLine.nDungeonFrame2
			tDungeon.szDungeonImage3 = tLine.szDungeonImage3
			tDungeon.nDungeonFrame3 = tLine.nDungeonFrame3
			tDungeon.nEnterMapID = tLine.nEnterMapID
		end
		if not tDivideMap[tLine.nDLCID] then
			tDivideMap[tLine.nDLCID] = {tLine.nDLCID, Table_GetDLCInfo(tLine.nDLCID).szDLCName}
		end
	end

	local tTeamDList = {}
	local tRaidDList = {}
	local tDivideList = {}

	local fnSortByLevel = function(tLeft, tRight)
		return tLeft.nMinLevel < tRight.nMinLevel
	end

	for szOtherName, tDungeon in pairs(tTeamDMap) do
		table.sort(tDungeon, fnSortByLevel)
		table.insert(tTeamDList, tDungeon)
	end

	for szOtherName, tDungeon in pairs(tRaidDMap) do
		table.insert(tRaidDList, tDungeon)
	end

	for nDivideLevel, tDevide in pairs(tDivideMap) do
		table.insert(tDivideList, tDevide)
	end

	local fnSortDivide = function(tLeft, tRight)
		return tLeft[1] >= tRight[1]
	end
	table.sort(tDivideList, fnSortDivide)

	return tTeamDList, tRaidDList, tDivideList, Table_GetDLCMapID()
end

local function ParseBossNpcList(szNpcList)
	local tList
	for szIndex in string.gmatch(szNpcList, "([%d]+)") do
		local nNpcIndex = tonumber(szIndex)
		if not tList then
			tList = {}
		end
		table.insert(tList, nNpcIndex)
	end
	return tList
end

function Table_GetDungeonBoss(dwMapID)
	local tBossList = {}

	local nCount = g_tTable.DungeonBoss:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.DungeonBoss:GetRow(i)
		if tLine.dwMapID == dwMapID then
			local tNpcList = ParseBossNpcList(tLine.szNpcList)
			tLine.tNpcList = tNpcList
			table.insert(tBossList, tLine)
		end
	end
	return tBossList
end

function Table_GetDungeonBossNpcListByBossIndex(dwBossIndex)
	for i = 2, g_tTable.DungeonBoss:GetRowCount() do
		local tLine = g_tTable.DungeonBoss:GetRow(i)
		if tLine.dwIndex == dwBossIndex then
			local aNpcList = ParseBossNpcList(tLine.szNpcList)
			return aNpcList
		end
	end
	return nil
end

function Table_GetSkillQuestList(dwSkillID)
	local tLine = g_tTable.SkillQuestList:Search(dwSkillID)
	if tLine then
		return tLine.szQuestList
	end
end

function Table_GetDungeonBossByBossIndex(dwBossIndex)
	local tLine = g_tTable.DungeonBoss:LinearSearch({dwIndex = dwBossIndex})

	return tLine
end

function Table_GetDungeonBossModel(dwNpcIndex)
	local tLine = g_tTable.DungeonNpc:Search(dwNpcIndex)

	return tLine
end

function Table_GetDungeonNpcCV(dwNpcIndex)
	local tCV = g_tTable.DungeonNpcCV:Search(dwNpcIndex)
	if not tCV then
		return
	end

	local nUsed = 0
	for i = 1, 8 do
		if tCV["szCVPath"..i] ~= "" then
			nUsed = nUsed + 1
		end
	end
	tCV.nUsed = nUsed
	return tCV
end

function Table_GetFBCDBossAvatar(dwNpcID)
	local szAvatarPath, nAvatarFrame, tResult
	for i = 1, g_tTable.FBCDBossImage:GetRowCount() do
		local tLine = g_tTable.FBCDBossImage:GetRow(i)
		if tLine.dwNpcID == dwNpcID then
			tResult = clone(tLine)
			break
		end
	end
	if not tResult then
		tResult = g_tTable.FBCDBossImage:GetRow(1)
	end

	return tResult.szAvatarPath, tResult.nAvatarFrame
end

function Table_GetDungeonBoss_StepSkill(dwSkillID)
	local tLine = g_tTable.DungeonSkill:Search(dwSkillID)

	return tLine
end

function Table_GetDungeonSkillIcon(nIconType)
	 local tLine = g_tTable.DungeonSkillIcon:Search(nIconType)

	return tLine
end

function Table_GetRecommendID(dwForceID, dwKungFuID, dwLevelID)
	local tRecomment = {}
	local hPlayer = GetClientPlayer()
	local nMaxLevel = hPlayer.nMaxLevel

	local nCount = g_tTable.Channels:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.Channels:GetRow(i)
		if tLine.dwForceID == dwForceID and tLine.dwKungFuID == dwKungFuID then
			if dwLevelID < nMaxLevel then
				table.insert(tRecomment, tLine.dwLowLevelPath)

			elseif dwLevelID == nMaxLevel then
				local szMaxLevelPath = tLine.szMaxLevelPath
				tRecomment = ParseIDList(szMaxLevelPath)
			end
		end
	end
	return tRecomment
end

function Table_GetAsuraBossInfo(dwBossID)
	local tResult = {}
	local nCount = g_tTable.AsuraBoss:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.AsuraBoss:GetRow(i)
		local dwBossID = tLine.dwBossID
		local nIndexID = tLine.nIndex
		if not tResult[dwBossID] and nIndexID == 1 then
			tResult[dwBossID] = {["dwMapID"] = tLine.dwMapID}
		end
		tResult[dwBossID][nIndexID] =
		{
			["nLimit"] = tLine.nLimit,
			["szTip"] = tLine.szTip,
			["szDetail"] = tLine.szDetail,
		}
	end

	if dwBossID then
		return tResult[dwBossID]
	else
		return tResult
	end
end

function Table_GetAsuraBossMap()
	local tResult = {}
	local nCount = g_tTable.AsuraBoss:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.AsuraBoss:GetRow(i)
		if tLine.nIndex == 1 and tLine.dwBossID then
			tResult[tLine.dwBossID] = tLine.dwMapID
		end
	end
	return tResult
end

function Table_GetAsuraRewardInfo()
	local tResult = {}
	local nCount = g_tTable.AsuraReward:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.AsuraReward:GetRow(i)
		tResult[tLine.dwID] = tLine
	end
	return tResult
end

function Table_GetForceList()
	local tResult = {}
	local tTemp = {}
	local nCount = g_tTable.MainKungfuInfo:GetRowCount()
	for i = 1, nCount do
		local tLine = g_tTable.MainKungfuInfo:GetRow(i)
		local nForceID = tLine.nForceID
		if type(nForceID) == "number" then
			tTemp[nForceID] = true
		end
	end
	for nForceID, _ in pairs(tTemp) do
		table.insert(tResult, nForceID)
	end
	table.sort(tResult)
	return tResult
end

function Table_GetKungFuIDByForce(dwForceID, bDxSkill)
	local nDeprecatedCangJianKungFuID = 100726

	local tTabTitle = {
		{f = "i", t = "dwKungfuID"},
		{f = "i", t = "nKungfuIndex"},
		{f = "i", t = "nForceID"},
		{f = "i", t = "nTalentGroup"},
		{f = "s", t = "KungfuType"},
		{f = "s", t = "name"},
		{f = "s", t = "AdaptiveType"},
		{f = "s", t = "NonadaptiveType"},
		{f = "i", t = "NoneSchoolKungfu"},
	}
	local szPath = bDxSkill and "settings\\skill\\MainKungfuInfo.tab" or "settings\\skill_mobile\\MainKungfuInfo.tab"
	local tIndexTab = KG_Table.Load(szPath, tTabTitle, 0)

	local tResult = {}
	local tTemp = {}
	local nCount = tIndexTab:GetRowCount()
	for i = 1, nCount do
		local tLine = tIndexTab:GetRow(i)
		local nForceID = tLine.nForceID
		local dwKungfuID = tLine.dwKungfuID
		local nTalentGroup = tLine.nTalentGroup
		if dwForceID == nForceID then
			tTemp[dwKungfuID] = {dwKungfuID = dwKungfuID,nTalentGroup = nTalentGroup}
		end
	end
	for dwKungFuID, tInfo in pairs(tTemp) do
		if dwKungFuID ~= nDeprecatedCangJianKungFuID then
			table.insert(tResult, tInfo)
		end
	end

	return tResult
end

function Table_GetKungFuIDBySchool(dwSchoolID, bDxSkill)
	local nForceID = SchoolTypeToForceID[dwSchoolID] or 0 --获取不到ForceID的为流派
	local tKungFuList = Table_GetKungFuIDByForce(nForceID, bDxSkill)
	return tKungFuList
end

function Table_GetSpacebarMiniGameInfo(nType)
	return g_tTable.SpacebarMiniGame:Search(nType)
end

function Table_GetChanelName(dwPathID)
	local szName = nil
	local tChannels = g_tTable.ChannelsRecommend:Search(dwPathID) or {}
	if tChannels then
		szName = tChannels.szPathName
	end

	return szName
end

function Table_GetChanelList(dwPathID)
	local tList = {}
	local tChannels = g_tTable.ChannelsRecommend:Search(dwPathID) or {}
	if tChannels then
		local szChannel = tChannels.szRecommendList

		for szId, szLevel in string.gmatch(szChannel, "([%d]+),([%d]+);?") do
			local dwId = tonumber(szId)
			local nLevel = tonumber(szLevel)
			table.insert(tList, {dwId, nLevel})
		end
	end

	return tList
end

function Table_GetChannelKey(dwPathID)
	local tList = {}
	local tChannels = g_tTable.ChannelsRecommend:Search(dwPathID) or {}
	if tChannels then
		local szKey = tChannels.szImporantKey
		for szId, szLevel in string.gmatch(szKey, "([%d]+),([%d]+);?") do
			local dwId = tonumber(szId)
			local nLevel = tonumber(szLevel)
			table.insert(tList, {dwId, nLevel})
		end
	end

	return tList
end

function Table_GetWantedRoleavatar(dwForceID)
	local tRoleavatarLine = {}

	local nCount = g_tTable.WantedRoleavatar:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.WantedRoleavatar:GetRow(i)
		if tLine.dwForceID == dwForceID then
			tRoleavatarLine = tLine
			-- 之前资源导出时没有按规范设置文件路径，这里做个映射
			tRoleavatarLine.szF1Image = string.gsub(tRoleavatarLine.szF1Image, "PlayerAvatar/", "PlayerAvatar/")
			tRoleavatarLine.szF2Image = string.gsub(tRoleavatarLine.szF2Image, "PlayerAvatar/", "PlayerAvatar/")
			tRoleavatarLine.szM1Image = string.gsub(tRoleavatarLine.szM1Image, "PlayerAvatar/", "PlayerAvatar/")
			tRoleavatarLine.szM2Image = string.gsub(tRoleavatarLine.szM2Image, "PlayerAvatar/", "PlayerAvatar/")
			break
		end
	end
	return tRoleavatarLine
end

local tRoleFileSuffix =
{
    [ROLE_TYPE.STANDARD_MALE]   = "M2",
    [ROLE_TYPE.STANDARD_FEMALE] = "F2",
    [ROLE_TYPE.LITTLE_BOY]      = "M1",
    [ROLE_TYPE.LITTLE_GIRL]     = "F1",
}

function Table_GetRoleavatar(dwMiniAvatarID, nRoleType, bOnlyAvatar)
	local tImage = g_tTable.RoleAvatar:Search(dwMiniAvatarID)

	local szImage, nImgFrame, szSfx = "", 0, ""
	if tImage then
		local szKey = tRoleFileSuffix[nRoleType]
		szImage = tImage["sz" .. szKey .. "Image"]
		nImgFrame = tImage["n" .. szKey .. "ImgFrame"]
		local szImgPathKey = string.format("sz%sOnlyAvatarImg", szKey)
		local szImgFrameKey = string.format("n%sOnlyAvatarFrame", szKey)
		if bOnlyAvatar then
			if tImage[szImgPathKey] ~= "" then
				szImage = tImage[szImgPathKey]
				nImgFrame = tImage[szImgFrameKey]
			end
		end

		local szSfxKey = string.format("sz%sOnlyAvatarSfx", szKey)
		szSfx = tImage["sz" .. szKey .. "Sfx"]
		if bOnlyAvatar then
			if tImage[szSfxKey] ~= "" then
				szSfx = tImage[szSfxKey]
			end
		end
	end

	return szImage,nImgFrame,szSfx
end

function Table_GetHelpSoundName(szSound)
	local szName = ""
	local dwID = tonumber(szSound)

	local tLine = g_tTable.HelpSoundTip:Search(dwID)
	if tLine then
		szName = tLine.szName
	end

	return szName
end

function Table_GetWantedLimitMap(dwMapID)
	local dwMask = 0

	local nCount = g_tTable.WantedLimitMap:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.WantedLimitMap:GetRow(i)
		if tLine and tLine.dwMapID == dwMapID then
			dwMask = tLine.dwMask
			break
		end
	end

	return dwMask
end

function Table_GetRideSubDisplay(dwSub)
	local tLine = g_tTable.RideSubDisplay:Search(dwSub)

	return tLine
end

function Table_ForceToSchool(dwForceID)
	local tLine = g_tTable.ForceToSchool:Search(dwForceID)

	return tLine.dwSchoolID
end

function Table_SchoolToForce(dwSchoolID)
	local nCount = g_tTable.ForceToSchool:GetRowCount()

	local dwForceID = 0
	for i = 1, nCount do
		tLine = g_tTable.ForceToSchool:GetRow(i)
		if dwSchoolID == tLine.dwSchoolID then
			dwForceID = tLine.dwForceID
		end
	end

	return dwForceID
end


function Table_GetSurTip(dwKungfuID)
	local tLine = g_tTable.ForceSurTip:Search(dwKungfuID)
	if not tLine then
		tLine = g_tTable.ForceSurTip:Search(0)
	end
	return tLine.szTip
end

function Table_GetKungfuSkillList(dwKungfuID, dwMKungfuID)
	local tSkill = {}
	local tLine = g_tTable.KungfuSkill:Search(dwKungfuID, dwMKungfuID) --为了兼容长歌门派的套路显示，根据心法显示套路里的不同技能
	if not tLine then
		tLine = g_tTable.KungfuSkill:Search(dwKungfuID, 0)
	end

	if tLine then
		local szSkill = tLine.szSkill
		for s in string.gmatch(szSkill, "%d+") do
			local dwID = tonumber(s)
			if dwID then
				table.insert(tSkill, dwID)
			end
		end
	end

	return tSkill
end

function Table_GetKungfuSkillListEx(dwKungfuID, dwMKungfuID, bSection)
	local tList = {}

	if not bSection then
		local tSkill = Table_GetKungfuSkillList(dwKungfuID, dwMKungfuID)
		table.insert(tList, tSkill)
		return tList
	end

	local tLine = g_tTable.KungfuSkill:Search(dwKungfuID, dwMKungfuID) --为了兼容长歌门派的套路显示，根据心法显示套路里的不同技能
	if not tLine then
		tLine = g_tTable.KungfuSkill:Search(dwKungfuID, 0)
	end

	if tLine then
		local szSkill = tLine.szSkill
		local tResult = SplitString(szSkill, "|")
		for nIndex, szKungfu in ipairs(tResult) do
			tList[nIndex] = {}
			for s in string.gmatch(szKungfu, "%d+") do
				local dwID = tonumber(s)
				if dwID and dwID > 0 then
					table.insert(tList[nIndex], dwID)
				end
			end
		end
	end

	return tList
end

function Table_GetMKungfuBg(dwMKungfuID)
	local tLine = g_tTable.MKungfuKungfu:Search(dwMKungfuID)
	if tLine then
		return {tLine.szBgPath1, tLine.szBgPath2, tLine.szBgPath3, tLine.szBgPath4, tLine.szBgPath5, tLine.nAlpha}
	end
end

function Table_OpenSkillLevel(dwSkillID, dwSkillLevel)
	local tLine = g_tTable.OpenSkillLevel:Search(dwSkillID, dwSkillLevel)
	if tLine then
		return tLine.dwLevel
	end
end

function Table_GetMKungfuList(dwKungfuID)
	local tLine = g_tTable.MKungfuKungfu:Search(dwKungfuID)
	local tKungfu = {}
	if tLine and tLine.szKungfu then
		local szKungfu = tLine.szKungfu
		for s in string.gmatch(szKungfu, "%d+") do
			local dwID = tonumber(s)
			if dwID then
				table.insert(tKungfu, dwID)
			end
		end
	end

	return tKungfu
end

function Table_MKungfuIsSection(dwKungfuID)
	local tLine = g_tTable.MKungfuKungfu:Search(dwKungfuID)
	return tLine.bSection
end

function Table_GetMKungfuFightBGColor(dwKungfuID)
	local tLine = g_tTable.MKungfuKungfu:Search(dwKungfuID)
	if tLine then
		return tLine.szMobileFightBGColor
	end
end

function Table_GetMKungfuFightColor(dwKungfuID)
	local tLine = g_tTable.MKungfuKungfu:Search(dwKungfuID)
	if tLine then
		return tLine.szMobileFightColor
	end
end

function Table_GetSkillQixueName(dwPointID)
	local szName = ""
	local tLine = g_tTable.SkillQixue:Search(dwPointID)
	if tLine then
		szName = tLine.szName
	end

	return szName
end

function Table_GetMonsterBossByIndex()
	local tList = {}
	local nCount = g_tTable.MonsterBoss:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.MonsterBoss:GetRow(i)
		local dwIndex = tLine.dwIndex
		if dwIndex > 0 then
			if not tList[dwIndex] then
				tList[dwIndex] = {}
			end
			tLine.tSkill = ParsePointList(tLine.szSkill)
			table.insert(tList[dwIndex], tLine)
		end
	end
	return tList
end

function Table_GetMonsterBossByGroup()
	local tList = {}
	local nCount = g_tTable.MonsterBoss:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.MonsterBoss:GetRow(i)
		local nGroup = tLine.nGroup
		if nGroup > 0 then
			if not tList[nGroup] then
				tList[nGroup] = {}
			end
			tLine.tSkill = ParsePointList(tLine.szSkill)
			table.insert(tList[nGroup], tLine)
		end
	end
	return tList
end

function Table_GetMonsterBossBySteps()
	local tList = {}
	local nCount = g_tTable.MonsterBoss:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.MonsterBoss:GetRow(i)
		local nSteps = tLine.nSteps
		if tLine.nGroup == 10001 or tLine.nGroup == 10002 then
			nSteps = tLine.nGroup
		end
		if nSteps > 0 then
			if not tList[nSteps] then
				tList[nSteps] = {}
			end
			tLine.tSkill = ParsePointList(tLine.szSkill)
			table.insert(tList[nSteps], tLine)
		end
	end
	return tList
end

function Table_GetMonsterBossByNpcID()
	local tList = {}
	local nCount = g_tTable.MonsterBoss:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.MonsterBoss:GetRow(i)
		local dwNpcID = tLine.dwNpcID
		if dwNpcID > 0 then
			tLine.tSkill = ParsePointList(tLine.szSkill)
			tList[dwNpcID] = tLine
		end
	end
	return tList
end

function Table_GetMonsterBossInfo(dwNpcID)
	local tLine = {}
	local nCount = g_tTable.MonsterBoss:GetRowCount()
	for i = 2, nCount do
		tLine = g_tTable.MonsterBoss:GetRow(i)
		if dwNpcID == tLine.dwNpcID then
			tLine.tSkill = ParsePointList(tLine.szSkill)
			break
		end
	end
	return tLine
end

function Table_GetMonsterBoss(nIndex, nStep)
    local tRes = {}
    local nCount = g_tTable.MonsterBoss:GetRowCount()
    for i = 2, nCount do
        local tLine = g_tTable.MonsterBoss:GetRow(i)
        if tLine and tLine.dwIndex == nIndex and tLine.nSteps == nStep then
            table.insert(tRes, tLine)
        end
    end
    return tRes
end

function Table_GetMonsterEffectInfo(nID)
    local tLine = g_tTable.MonsterEffect:Search(nID)
    return tLine
end

function Table_GetMonsterBookInfo(dwIndex)
	local tLine = g_tTable.MonsterBook:Search(dwIndex)
	return tLine
end
function Table_GetMonsterCommonBookInfo(nLevel)
	local tLine = g_tTable.MonsterCommonBook:Search(nLevel)
	return tLine
end

function Table_GetAllMonsterCommonBookInfo()
	local tResult = {}
	local nCount = g_tTable.MonsterCommonBook:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.MonsterCommonBook:GetRow(i)
		table.insert(tResult, tLine)
	end
	return tResult
end

function Table_GetAllMonsterSkill()
	local tResult = {}
	local nCount = g_tTable.MonsterSkill:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.MonsterSkill:GetRow(i)
		table.insert(tResult, tLine)
	end
	return tResult
end

function Table_GetMonsterSkillInfo(dwSkillID)
	local tResult = {}
	local nCount = g_tTable.MonsterSkill:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.MonsterSkill:GetRow(i)
		if tLine.dwInSkillID == dwSkillID or tLine.dwOutSkillID == dwSkillID then
			tResult = tLine
		end
	end
	return tResult
end

function Table_GetMonsterSkillSearchList()
	local tSearch = {}
	local nCount = g_tTable.MonsterSkillSearch:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.MonsterSkillSearch:GetRow(i)
		local nType = tLine.nType
		if not tSearch[nType] then
			tSearch[nType] = {}
		end
		local dwID = tLine.dwID
		local szName = tLine.szTypeName
		table.insert(tSearch[nType], {dwID, szName})
	end
	return tSearch
end

function Table_GetMonsterBossIntroduce(dwIndex)
    local tLine = g_tTable.MonsterBossIntroduce:Search(dwIndex)
    return tLine
end

function Table_GetMonsterBossIntroduceInfo(nSex)
	local tList = {}
    local nCount = g_tTable.MonsterBossIntroduce:GetRowCount()
    for i = 2, nCount do
        local tLine = g_tTable.MonsterBossIntroduce:GetRow(i)
		if tLine.nSex == 0 or tLine.nSex == nSex then
			table.insert(tList, tLine)
		end
    end
    return tList
end

function Table_GetMonsterSkillBossDic(nSex)
    local tResult = {}
    local nCount = g_tTable.MonsterSkill:GetRowCount()
    for i = 2, nCount do
        local tLine = g_tTable.MonsterSkill:GetRow(i)
		if (not tLine.bDeprecated) and  tLine.szBoss ~= "" and (tLine.nSex == 0 or tLine.nSex == nSex) then
			local tBossID = SplitString(tLine.szBoss, ";")
			for _, szBossID in pairs(tBossID) do
				local dwBossID = tonumber(szBossID) or 0
				if not tResult[dwBossID] then
					tResult[dwBossID] = {}
				end
				table.insert(tResult[dwBossID], tLine)
			end
		end
    end
    return tResult
end

local tMonsterBossSpringEndurance = nil
function Table_GetMonsterBossSpringEndurance(dwIndex, nLevel, nSex)
	if not tMonsterBossSpringEndurance then
		tMonsterBossSpringEndurance = {}
		local nCount = g_tTable.MonsterBossSpiritEndurance:GetRowCount()
		for i = 2, nCount do
			local tLine = g_tTable.MonsterBossSpiritEndurance:GetRow(i)
			if not tMonsterBossSpringEndurance[tLine.dwIndex] then
				tMonsterBossSpringEndurance[tLine.dwIndex] = {}
			end
			if not tMonsterBossSpringEndurance[tLine.dwIndex][tLine.nLevel] then
				tMonsterBossSpringEndurance[tLine.dwIndex][tLine.nLevel] = {}
			end
			tMonsterBossSpringEndurance[tLine.dwIndex][tLine.nLevel][tLine.nSex] = tLine
		end
	end

	if tMonsterBossSpringEndurance[dwIndex] then
		if tMonsterBossSpringEndurance[dwIndex][nLevel] then
			local tLine = tMonsterBossSpringEndurance[dwIndex][nLevel][nSex]
			if not tLine then
				tLine = tMonsterBossSpringEndurance[dwIndex][nLevel][0]
			end
			if tLine then
				return tLine.nSpirit, tLine.nEndurance
			end
		end
	end
	return 0, 0
end

function Table_GetConcatedMonsterBossName(szBoss)
	local szBossName = ""
	local tBossID = SplitString(szBoss, ";")
	for _, szBossID in pairs(tBossID) do
		local tItem = Table_GetMonsterBossIntroduce(tonumber(szBossID))
		local szName = tItem and tItem.szName
		szName = szName or ""
		if szBossName == "" then
			szBossName = szName or ""
		else
			szBossName = szBossName..UIHelper.UTF8ToGBK("、")..szName
		end
	end

	return szBossName
end

function Table_GetSkillNouns(nNounID)
	local nCount = g_tTable.SkillNouns:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.SkillNouns:GetRow(i)
		if tLine and tLine.nNounID == nNounID then
			return tLine
		end
	end
end

function Table_GetAllSkillNouns()
	local tRes = {}
	local nCount = g_tTable.SkillNouns:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.SkillNouns:GetRow(i)
		if tLine then
			table.insert(tRes, tLine)
		end
	end
	return tRes
end

function Table_GetNpcCallMe(nCallID)
	local szName = ""
	local tCallBack =
	{
		nRoleType = function(pPlayer, nRoleType) return pPlayer.nRoleType == nRoleType end,
		nForceID = function(pPlayer, nForceID) return pPlayer.dwForceID == nForceID end,
		nBuffID = function(pPlayer, nBuffID, nBuffLevel) return pPlayer.IsHaveBuff(nBuffID, nBuffLevel) end,
		nQuestID = function(pPlayer, dwQuestID, nQuestState) return pPlayer.GetQuestPhase(dwQuestID) >= nQuestState end,
		nReputeID = function(pPlayer, nReputeID, nReputeLevel) return pPlayer.GetReputeLevel(pPlayer.dwForceID) >= nReputeLevel end,
		nAchieveRecord = function(pPlayer, nAchieveRecord) return pPlayer.GetAchievementRecord() >= nAchieveRecord end,
		nCamp = function(pPlayer, nCamp) return pPlayer.nCamp == nCamp end,
	}
	local pPlayer = GetClientPlayer()
	if pPlayer then
		local nCount = g_tTable.NpcCallMe:GetRowCount()
		for i = 2, nCount do
			local tLine = g_tTable.NpcCallMe:GetRow(i)
			if nCallID == tLine.nCallID then
				local bCheck = true
				for key, func in pairs(tCallBack) do
					if tLine[key] ~= -1 then
						bCheck = func(pPlayer, tLine[key], tLine)
					end
					if not bCheck then
						break
					end
				end
				if bCheck then
					szName = tLine.szName
					break
				end
			end
		end
	end
	if szName == "" then
		local tLine = g_tTable.NpcCallMe:GetRow(1)
		szName = tLine.szName
	end
	return szName
end

function Table_GetExteriorHome()
	local tList = {}

	local nCount = g_tTable.ExteriorHome:GetRowCount()

	for i = 2, nCount do
		local tLine = g_tTable.ExteriorHome:GetRow(i)
		if not tList[tLine.nClass] then
			tList[tLine.nClass] = {}
		end

		table.insert(tList[tLine.nClass], tLine)
	end

	return tList
end

function Table_GetComboSkillInfo()
	local tComboPreviewList = {}
	local tComboNextList = {}
	local tMemberNum = {}

	local nCount = g_tTable.SkillCombo:GetRowCount()

	for i = 2, nCount do
		local tLine = g_tTable.SkillCombo:GetRow(i)
		tComboNextList[tLine.dwComboPreview] = tLine
		tComboPreviewList[tLine.dwSkillID] = tLine.dwComboPreview
		if tLine.nMemberNum > 1 then
			tMemberNum[tLine.dwSkillID] = tLine.nMemberNum
		end
	end

	return tComboPreviewList, tComboNextList, tMemberNum
end

function Table_GetCountComboInfo(dwSkillID)
	local tLine = g_tTable.SkillCountCombo:Search(dwSkillID)
	return tLine
end

function Table_GetSoundSetting(szVersionName)
	local tSound = {}

	local nCount = g_tTable.SoundSetting:GetRowCount()
	for i = 1, nCount do
		local tLine = g_tTable.SoundSetting:GetRow(i)
		if i == 1 or szVersionName == tLine.szVersionName then
			tSound = tLine
		end

		if szVersionName == tLine.szVersionName then
			break
		end
	end

	return tSound
end

function Table_GetAllKBWeekReward()
	local tRewardList = {}

	local nCount = g_tTable.AllKBWeekReward:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.AllKBWeekReward:GetRow(i)
		table.insert(tRewardList, tLine)
	end

	return tRewardList
end

function Table_GetAllKBSeasonReward()
	local tRewardList = {}

	local nCount = g_tTable.AllKBSeasonReward:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.AllKBSeasonReward:GetRow(i)
		table.insert(tRewardList, tLine)
	end

	return tRewardList
end

function Table_GetBidNpcName(dwNpcTemplateID)
	local szNpcName = ""

	local nCount = g_tTable.GoldTeamBoss:GetRowCount()
	for i = 1, nCount do
		local tLine = g_tTable.GoldTeamBoss:GetRow(i)
		if dwNpcTemplateID == tLine.dwNpcID then
			szNpcName = tLine.szName
			break
		end
	end

	return szNpcName
end


local _cache_npc
local function _cache_npc_update(cache)
	_cache_npc = cache
end

_cache_npc = cache_init(100, "npc", _cache_npc_update)

npccache_debug=function()
	UILog("npc cache use num "..tostring(_cache_npc._useNum))
end

function Table_GetNpc(dwTemplateID)
	local tNpc = _cache_npc[dwTemplateID]
	if not tNpc then
		tNpc = g_tTable.Npc:Search(dwTemplateID)
		tNpc = tNpc or -1
		_cache_npc = cache_append(_cache_npc, dwTemplateID, tNpc)
	end

	if tNpc == -1 then
		return
	end

	return tNpc
end

local _cache_npctype
local function _cache_npctype_update(cache)
	_cache_npctype = cache
end

_cache_npctype = cache_init(20, "npctype", _cache_npctype_update)

--npctypecache_debug=function()
	--UILog("npc type cache use num "..tostring(_cache_npctype._useNum))
--end

function Table_GetNpcType(dwNpcTypeID)
	local tType = _cache_npctype[dwNpcTypeID]
	if not tType then
		tType = g_tTable.NpcType:Search(dwNpcTypeID)
		tType = tType or -1
		_cache_npctype = cache_append(_cache_npctype, dwNpcTypeID, tType)
	end

	if tType == -1 then
		return
	end

	return tType
end


function Table_GetNpcTypeInfoMap()
	local tTypeInfoMap = {}
	local nCount = g_tTable.NpcGuildTypeInfo:GetRowCount()
	for i = 1, nCount do
		local tLine = g_tTable.NpcGuildTypeInfo:GetRow(i)
		if not tTypeInfoMap[tLine.nID] then
			tLine.tNpcList = {}
			tTypeInfoMap[tLine.nID] = tLine
		else
			tLine.tPoint = ParsePointList(tLine.szPosition)
			table.insert(tTypeInfoMap[tLine.nID].tNpcList, tLine)
		end
	end
	return tTypeInfoMap
end

function Table_GetNpcGuild(dwMapID, dwIndex)
	local tTypeInfoMap = Table_GetNpcTypeInfoMap()
	local tGuildClassList = {}
	local nCount = g_tTable.NpcGuildTypeClass:GetRowCount()
	for i = 1, nCount do
		local tLine = g_tTable.NpcGuildTypeClass:GetRow(i)
		if dwMapID == tLine.dwMapID and dwIndex == tLine.dwIndex then

			local tPoint = ParsePointList(tLine.szNpcTypeList)
			tLine.tSublist = {}
			for _, nTypeID in ipairs(tPoint) do
				table.insert(tLine.tSublist, tTypeInfoMap[nTypeID])
			end
			table.insert(tGuildClassList, tLine)
		end
	end

	return tGuildClassList
end

function Table_GetMiddleMapSelectNpc()
	local tSelectNpc = {}

	local nCount = g_tTable.Middlemap_SelectNpc:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.Middlemap_SelectNpc:GetRow(i)
		tSelectNpc[tLine.nNpcTypeID] = 1
	end

	return tSelectNpc
end


function Table_GetDisCoupon(dwID)
	local tLine = g_tTable.DisCoupon:Search(dwID)

	return tLine
end

function Table_GetCastleInfo(dwCastleID)
	local tLine = {}
	local nCount = g_tTable.CastleInfo:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.CastleInfo:GetRow(i)
		if dwCastleID == tLine.dwCastleID then
			return tLine
		end
	end
end

function Table_GetCastleByMapID(dwMapID)
	local tRet = {}
	local nCount = g_tTable.CastleInfo:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.CastleInfo:GetRow(i)
		if dwMapID == tLine.dwMapID then
			table.insert(tRet, tLine.dwCastleID)
		end
	end

	return tRet
end

function Table_GetFaceBoneList()
	local nCount = g_tTable.FaceBones:GetRowCount()
	local tClassMap = {}
	local tClassList = {}
	for i = 2, nCount do
		local tLine = g_tTable.FaceBones:GetRow(i)
		if not tClassMap[tLine.dwClassID] then
			table.insert(tClassList, {})
			tClassMap[tLine.dwClassID]  = tClassList[#tClassList]
		end
		local tClass = tClassMap[tLine.dwClassID]
		if tLine.szClassName ~= "" then
			tClass.szName = tLine.szClassName
			tClass.dwClassID = tLine.dwClassID
		end
		table.insert(tClass, {tLine.eBoneType, tLine.szBoneName, tLine.bDivide, tLine.nStep})
	end

	return  tClassList
end

function Table_GetOfficalFaceList(nRoleType, bPrice)
	local tFaceList = {}
	local tDefault = {}
	local nCount = g_tTable.FaceDefault:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.FaceDefault:GetRow(i)
		if tLine.nRoleType == nRoleType and
			(bPrice or tLine.bCanUseInCreate)
		then
			table.insert(tFaceList, tLine)
			if tLine.bDefault then
				tDefault = tLine
			end
		end
	end
	return tFaceList, tDefault
end

local tFaceDecalsList = nil
local tFaceDecalsMap = nil
local tDecalsFLipMap = nil
local function LoadFaceDecals()
	local  nCount = g_tTable.FaceDecals:GetRowCount()
	tFaceDecalsList = {}
	tFaceDecalsMap = {}
	tDecalsFLipMap = {}
	for i = 2, nCount do
		local tLine = g_tTable.FaceDecals:GetRow(i)
		if not tFaceDecalsList[tLine.nRoleType] then
			tFaceDecalsList[tLine.nRoleType] = {}
			tFaceDecalsMap[tLine.nRoleType] = {}
			tDecalsFLipMap[tLine.nRoleType] = {}
		end

		local tRoleMap = tFaceDecalsList[tLine.nRoleType]
		if not tRoleMap[tLine.nType] then
			tRoleMap[tLine.nType] = {}
			tFaceDecalsMap[tLine.nRoleType][tLine.nType] = {}
			tDecalsFLipMap[tLine.nRoleType][tLine.nType] = {}
		end
		table.insert(tRoleMap[tLine.nType], tLine.nShowID)
		tFaceDecalsMap[tLine.nRoleType][tLine.nType][tLine.nShowID] = tLine
		if tLine.nFlipID >= 0 then
			tDecalsFLipMap[tLine.nRoleType][tLine.nType][tLine.nFlipID] = tLine.nShowID
		end
	end
end

function Table_GetTypeDecalList(nRoleType, nType)
	if not tFaceDecalsList then
		LoadFaceDecals()
	end
	return tFaceDecalsList[nRoleType][nType]
end

function Table_GetDecal(nRoleType, nType, nShowID)
	if not tFaceDecalsMap then
		LoadFaceDecals()
	end
	if not tFaceDecalsMap[nRoleType][nType] then
		UILog("Table_GetDecal not find tFaceDecalsMap[nRoleType][nType] when nRoleType = " .. nRoleType .. ", nType = " .. nType .. ", nShowID = " .. nShowID)
	end
	local tLine = tFaceDecalsMap[nRoleType][nType][nShowID]
	if not tLine then
		UILog("Table_GetDecal not find tFaceDecalsMap[nRoleType][nType][nShowID] when nRoleType = " .. nRoleType .. ", nType = " .. nType .. ", nShowID = " .. nShowID)
	end

	tLine.tRGBA = ParsePointList(tLine.szDefaultRGBA)
	return tLine
end

function Table_BeFliped(nRoleType, nType, nShowID)
	if not tDecalsFLipMap then
		LoadFaceDecals()
	end

	return tDecalsFLipMap[nRoleType][nType][nShowID]
end

function Table_GetFaceMeshInfo(nRoleType)
	local tLine = g_tTable.FaceDefaultMesh:Search(nRoleType)
	return tLine
end

local tFaceDecoration = nil
local tFaceDecMap = nil
local function LoadFaceDecoration()
	local  nCount = g_tTable.FaceDecoration:GetRowCount()
	tFaceDecoration = {}
	tFaceDecMap = {}
	for i = 2, nCount do
		local tLine = g_tTable.FaceDecoration:GetRow(i)
		if not tFaceDecoration[tLine.nRoleType] then
			tFaceDecoration[tLine.nRoleType] = {}
			tFaceDecMap[tLine.nRoleType] = {}
		end

		local tRoleMap = tFaceDecoration[tLine.nRoleType]
		table.insert(tRoleMap, tLine.nDecorationID)
		tFaceDecMap[tLine.nRoleType][tLine.nDecorationID] = tLine
	end
end

function Table_GetDecalsAdjust(nType)
	local tLine = g_tTable.FaceDecalsAdjust:LinearSearch({nType = nType})
	return tLine
end

function Table_GetShareStationTagList(nDataType)
    local tRes = {}
    local nCount = g_tTable.ShareStationTag:GetRowCount()
	for i = 1, nCount do
		local tLine = g_tTable.ShareStationTag:GetRow(i)
        if tLine.nDataType == nDataType then
            table.insert(tRes, tLine)
        end
	end
	return tRes
end

function Table_GetShareStationTagInfo(nTag)
    local tLine = g_tTable.ShareStationTag:Search(nTag)
    return tLine
end

function Table_GetEffectToItemList(nEffectID)
    local tItemList = {}
    local tLine = g_tTable.EffectToItem:Search(nEffectID)
    if tLine then
        local szItemList = tLine.szItemList
        local tList = string.split(szItemList, "|")
        for _, szItem in ipairs(tList) do
            local v = StringParse_IDList(szItem)
            local nItemType = v[1]
            local dwItemIndex = v[2]
            if nItemType > 0 and dwItemIndex > 0 then
                table.insert(tItemList, {nItemType, dwItemIndex})
            end
        end
    end
	return tItemList
end

function Table_GetExteriorToItemList(nExteriorID, eGoodsType)
	local tItemList = {}
    local tLine = g_tTable.ExteriorToItem:Search(eGoodsType, nExteriorID)
    if tLine and tLine.eGoodsType == eGoodsType then
        local tIndexList = StringParse_IDList(tLine.szIndexList)
        for _, dwItemIndex in ipairs(tIndexList) do
            if dwItemIndex > 0 then
                table.insert(tItemList, {5, dwItemIndex})
            end
        end
    end
	return tItemList
end

function Table_GetItemToItemPackList(nItemType, dwItemIndex)
    local tItemList = {}
    local tLine = g_tTable.ItemToItemPack:Search(nItemType, dwItemIndex)
    if tLine then
        for i = 1, 8 do
            local dwIndex = tLine["dwIndex" .. i]
            if dwIndex > 0 then
                table.insert(tItemList, {5, dwIndex})
            end
        end
    end
	return tItemList
end

function Table_GetFaceDecalsClass(nClassID)
	local tLine = g_tTable.FaceDecalsClass:Search(nClassID)
	return tLine
end

function Table_GetDecorationList(nRoleType)
	if not tFaceDecoration then
		LoadFaceDecoration()
	end
	return tFaceDecoration[nRoleType]
end

function Table_GettDecoration(nRoleType, nDecorationID)
	if not tFaceDecMap then
		LoadFaceDecoration()
	end

	local tLine = tFaceDecMap[nRoleType][nDecorationID]
	if not tLine then
		UILog("Table_GettDecoration not find tFaceDecMap[nRoleType][nType][nDecorationID] when nRoleType = " .. nRoleType .. ", nDecorationID = " .. nDecorationID)
	end

	return tLine
end

function Table_GetScriptFromCommonTab(szKey)
	local nCount = g_tTable.Common:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.Common:GetRow(i)
		if tLine.szKey == szKey then
			return tLine.szScript
		end
	end
end

function Table_GetSkillTeach(nForceID, nKungfuID, nLevel)
	local tTeach = {}
	local nCount = g_tTable.SkillTeach:GetRowCount()
	for i = 2, nCount do
		local  tLine = g_tTable.SkillTeach:GetRow(i)
		local nStart, nEnd = GetJoinLevel(tLine.szLevel)
		-- if nForceID == tLine.nForceID and
		-- 	nKungfuID == tLine.nKungfuID and
		if	nKungfuID == tLine.nKungfuID and
				nLevel >= nStart and
				nLevel <= nEnd
		then
			tLine.tSkillList = ParseIDList(tLine.szSkillList)
			tLine.tQixueList = StringParse_Numbers(tLine.szQixueList)
			tLine.tRecipeSkillList = ParseIDList(tLine.szRecipeSkillList)
			table.insert(tTeach, tLine)
		end
	end

	return tTeach
end

function Table_GetSkillTeachQixueRecommend(nForceID, nKungfuID)
	local tGroup = {}
	local tLine = {}
	local tTeachRecommendList = {}
	local nRecommendCount = 0
	local nCount = g_tTable.SkillTeach_Qixue_Recommend:GetRowCount()
	for i = 2, nCount do
		local nRecommendCount = 0
		tLine = g_tTable.SkillTeach_Qixue_Recommend:GetRow(i)
		-- if nForceID == tLine.nForceID and nKungfuID == tLine.nKungfuID then
		if nKungfuID == tLine.nKungfuID then
			local tQixueList = {}
			tQixueList.nID = tLine.nID
			tQixueList.szSolution = tLine.szSolution
			for j = 1, TEACH_SKILL_QIXUE_RECOMMEND do
				if not (tLine["szQixue" .. j] == "") then
					tQixueList["szQixue" .. j] = tLine["szQixue" .. j]
					tQixueList["tQixueList" .. j] = StringParse_Numbers(tLine["szQixueList" .. j])
					nRecommendCount = nRecommendCount + 1
				end
			end
			tQixueList.nGroup = nRecommendCount
			table.insert(tTeachRecommendList, tQixueList)
		end
	end
	return tTeachRecommendList
end

function Table_GetCommonEnchantDesc(enchant_id)
	local res = g_tTable.CommonEnchant:Search(enchant_id)
	if res then
		return res.desc
	end
end

function Table_GetActivityHome()
	local res = {}
	local nCount = g_tTable.ActivityHome:GetRowCount()
	for i = 2, nCount do
		local  tLine = g_tTable.ActivityHome:GetRow(i)
		table.insert(res, tLine)
	end
	return res
end

function Table_GetActivityNoneML()
	local res = {}
	local nCount = g_tTable.ActivityNoneML:GetRowCount()
	for i = 2, nCount do
		local  tLine = g_tTable.ActivityNoneML:GetRow(i)
		table.insert(res, tLine)
	end
	return res
end

function Table_GetDialogBtn(nBtnID)
	local tLine = g_tTable.DialogBtn:Search(nBtnID)
	return tLine
end

--TeamRecruit
function Table_GetTeamRecruit()
	local res = {}
	local nCount = g_tTable.TeamRecruit:GetRowCount()
	local tRecommendList = TeamBuilding.OnGetRecruitDynamic()
	for i = 2, nCount do
		local tLine = g_tTable.TeamRecruit:GetRow(i)
		local dwType = tLine.dwType
		local szTypeName = tLine.szTypeName

		if dwType > 0 then
			res[dwType] = res[dwType] or {Type=dwType, TypeName=szTypeName}
			res[dwType].bParent = true
			local dwSubType = tLine.dwSubType
			local szSubTypeName = tLine.szSubTypeName
			tLine.bMark = tLine.bMark or DectTableValue(tRecommendList, tLine.dwID)
			local bMark = tLine.bMark
			if dwSubType > 0 then
				res[dwType][dwSubType] = res[dwType][dwSubType] or {SubType=dwSubType, SubTypeName=szSubTypeName}
				res[dwType][dwSubType].bParent = true
				res[dwType][dwSubType].bMark = res[dwType][dwSubType].bMark or bMark
				res[dwType].bMark = res[dwType].bMark or bMark
				table.insert(res[dwType][dwSubType], tLine)
			else
				res[dwType].bMark = res[dwType].bMark or bMark
				table.insert(res[dwType], tLine)
			end
		end
	end
	return res
end

function Table_GetTeamInfo(dwID)
	local tLine
	if type(dwID) == "number" then
		tLine = g_tTable.TeamRecruit:Search(dwID)
	end
	return tLine
end

function Table_GetTeamInfoByQuestID(dwQuestID)
	local nCount = g_tTable.TeamRecruit:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.TeamRecruit:GetRow(i)
		if dwQuestID == tLine.dwQuestID then
			return tLine
		end
	end
end

function Table_GetTeamInfoByMapID(dwMapID)
	local nCount = g_tTable.TeamRecruit:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.TeamRecruit:GetRow(i)
		if dwMapID == tLine.dwMapID then
			return tLine
		end
	end
end

function Table_GetGlobalTeamRecruit()
	local res = {}
	local nCount = g_tTable.TeamRecruit:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.TeamRecruit:GetRow(i)
		if tLine.bSwitchServer then
			if tLine.dwType == 1 or tLine.dwType == 2 then
				table.insert(res, tLine)
			elseif tLine.dwType == 3 and tLine.dwID == 222 then --百战异闻录只留一个
				local  tTemp = clone(tLine)
				tTemp.szName = tTemp.szTypeName
				table.insert(res, tTemp)
			end
		end
	end
	local fnSort = function (a, b)
		if a.dwType == b.dwType then
			return a.dwID > b.dwID
		else
			return a.dwType > b.dwType
		end
	end
	table.sort(res, fnSort)
	return res
end

function Table_GetTeamRecruitPosMask(szType)
	local nCount = g_tTable.TeamPositionMask:GetRowCount()
	for i = 1, nCount do
		local tLine = g_tTable.TeamPositionMask:GetRow(i)
		local szPosition = tLine.szPosition
		if szPosition == szType then
			return tLine.dwMaskID
		end
	end
end

function Table_GetTeamRecruitForceMask(dwForceID, dwMask)
	local MAX = 9
	local nCount = g_tTable.TeamPosition:GetRowCount()
	for i = 1, nCount do
		local tLine = g_tTable.TeamPosition:GetRow(i)
		if tLine.dwForceID == dwForceID then
			for i = 1, MAX do
				if tLine["dwMask"..i] == dwMask then
					return true
				end
			end
		end
	end

	return false
end

function Table_GetTeamRecruitMask(dwID)
	local tLine = g_tTable.TeamPositionMask:Search(dwID)
	if tLine then
		return tLine
	end
end

function Table_GetTeamPosition_KungFu(dwKungFuID)
	local nMask = 0

	local nCount = g_tTable.TeamPosition_KungFu:GetRowCount()
	for i = 1, nCount do
		local tLine = g_tTable.TeamPosition_KungFu:GetRow(i)
		if tLine.dwKungFuID == dwKungFuID then
			nMask = tLine.nMask
		end
	end
	return nMask
end

function Table_GetTeamSpecialBuff()
	local tLine = g_tTable.TeamSpecialBuff:Search(1)
	return tLine
end

local function OperActyAddTimeZone(tTime)
	for nIndex in ipairs(tTime) do
		tTime[nIndex] = Time_AddZone(tTime[nIndex])
	end
end

local function ParseOperActyTime(tLine)
	local nPreTime = Time_AddZone(tLine.nPreTime)
	local nResTime = Time_AddZone(tLine.nResTime)
	if tLine.szStartTime ~= "" then
		local tStartTime = ParseIDList(tLine.szStartTime)
		OperActyAddTimeZone(tStartTime)
		tLine.nStartTime = tStartTime[1]
		tLine.tStartTime = tStartTime
	end
	if tLine.szEndTime ~= "" then
		local tEndTime = ParseIDList(tLine.szEndTime)
		OperActyAddTimeZone(tEndTime)
		tLine.nEndTime =  tEndTime[1]
		tLine.tEndTime = tEndTime
	end

	HuaELouData.tActiveTime[tLine.dwID] = {
		nPreTime = nPreTime,
		nResTime = nResTime,
	}
end

local function ParseOperactyType(tLine)
	tLine.bNeedRemoteCall = GetNumberBit(tLine.nOperatType, 1)
	tLine.bUseExtPoint = GetNumberBit(tLine.nOperatType, 2)
	tLine.bNeedCustomDataRemoteCall = GetNumberBit(tLine.nOperatType, 3)
end

function Table_GetOperationActivity()
	local res = {}

	local nCount = g_tTable.OperatAct:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.OperatAct:GetRow(i)
		if tLine.bShow then
			ParseOperActyTime(tLine)
			ParseOperactyType(tLine)
			table.insert(res, tLine)
		end
	end

	return res
end

-- 账号安全面板项目列表，按 dwID 递增
-- 每行含 nTab, szKey, szDsc, bShowMark, nMarkFrame, szItems
function Table_GetSafePanelInfo()
	local tRes = {}
	local nCount = g_tTable.SafePanelInfo:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.SafePanelInfo:GetRow(i)
		if tLine then
			local tRewards = {}
			if tLine.szItems and tLine.szItems ~= "" then
				local tInfoList = string.split(tLine.szItems, ";")
				for _, szItem in ipairs(tInfoList) do
					szItem = string.trim(szItem, " ")
					if szItem ~= "" then
						local tBoxInfo = string.split(szItem, "_")
						table.insert(tRewards, {tonumber(tBoxInfo[2]), tonumber(tBoxInfo[3]), tonumber(tBoxInfo[4])})
					end
				end
			end
			tLine.tRewards = tRewards
			table.insert(tRes, tLine)
		end
	end
	return tRes
end

function Table_GetFameAndPunishEvilInfo()
	local tRes = {}
	local nCount = g_tTable.FameAndPunishEvilInfo:GetRowCount()
	for i = 1, nCount do
		local tLine = g_tTable.FameAndPunishEvilInfo:GetRow(i)
		if tLine then
			tRes[tLine.dwTab] = tLine
		end
	end
	return tRes
end

function Table_GetOperatActShopByID(dwID)
	local tLine = g_tTable.OperatActShop:Search(dwID)
	return tLine
end

function Table_GetOnePhotoRewards(szRewards)
	local res = {}

	local  tRewards = ParseIDList(szRewards)
	for k, v in pairs(tRewards) do
		local tLine = g_tTable.OnePhotoRewards:Search(v)
		local tItem = SplitString(tLine.szItem, "|")
		tLine.tItem = {}
		for _, szItem in pairs(tItem) do
			local t = SplitString(szItem, ";")
			table.insert(tLine.tItem, {dwType = tonumber(t[1]), dwIndex = tonumber(t[2]), nCount = tonumber(t[3])})
		end
		tLine.tSpecial = nil
		if tLine.szSpecial and tLine.szSpecial ~= "" then
			local t = SplitString(tLine.szSpecial, ";")
			tLine.tSpecial = {dwType = tonumber(t[1]), dwIndex = tonumber(t[2]), nCount = tonumber(t[3])}
		end
		res[k] = tLine
	end
	return res
end

function Table_GetTopmenuButton()
	local res = {}

	local nCount = g_tTable.TopmenuButton:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.TopmenuButton:GetRow(i)
		table.insert(res, tLine)
	end

	return res
end

function Table_GetOperationActUserData(dwID)
	local tInfo = Table_GetOperActyInfo(dwID)
	if not tInfo then
		return
	end

	return tInfo.szUserData
end

function Table_GetOperationActCounterID(dwID)
	local tInfo = Table_GetOperActyInfo(dwID)
	if not tInfo then
		return
	end

	return tInfo.dwCounterID, tInfo.nCount
end


function Table_GetRewardLevelInfo()
	local res = {}

	local nCount = g_tTable.RewardLevelInfo:GetRowCount()
	for i = 1, nCount do
		local tLine = g_tTable.RewardLevelInfo:GetRow(i)
		if not res[tLine.dwActivityID] then
			res[tLine.dwActivityID] = {}
		end
		res[tLine.dwActivityID][tLine.nLevel] = tLine
	end

	return res
end

function Table_GetBattlePassQuestInfo()
	local res = {}

	local nCount = g_tTable.BattlePassQuestInfo:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.BattlePassQuestInfo:GetRow(i)
		if not res[tLine.szPageName] then
			res[tLine.szPageName] = {}
		end
		table.insert(res[tLine.szPageName], tLine)
	end

	return res
end

function Table_GetBattlePassRewardInfo()
	local res = {}

	local nCount = g_tTable.BattlePassRewardInfo:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.BattlePassRewardInfo:GetRow(i)
		res[tLine.dwID] = tLine
	end

	return res
end

function Table_GetActivityBattlePassQuest()
	local tResult = {}
	local nCount = g_tTable.ActivityBattlePassQuest:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.ActivityBattlePassQuest:GetRow(i)
		if not tResult[tLine.szModuleName] then
			tResult[tLine.szModuleName] = {}
		end
		if tLine.nClass == 1 then
			local nActivityID = tonumber(string.match(tLine.szLink, "LinkActivity/(.*)"))
			if ActivityData.IsActivityOn(nActivityID) then
				table.insert(tResult[tLine.szModuleName], tLine)
			end
		else
			table.insert(tResult[tLine.szModuleName], tLine)
		end
	end
	return tResult
end

function Table_GetActivityBattlePassReward()
	local tReward, tValue = {}, {}
	local nPicCount = 0
	local nCount = g_tTable.ActivityBattlePassReward:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.ActivityBattlePassReward:GetRow(i)
		tReward[tLine.nLevel] = tLine

		if tLine.szRewardPicPath ~= "" then
			nPicCount = nPicCount + 1
			tValue[nPicCount] = tLine.nLevel
		end
	end
	return tReward, tValue
end

function Table_GetOperActyInfo(dwID)
	local tLine = g_tTable.OperatAct:Search(dwID)
	if not tLine then
		return nil
	end

	ParseOperActyTime(tLine)
	ParseOperactyType(tLine)

	return tLine
end

function Table_GetOperActyTitle(dwID)
	local tLine = g_tTable.OperatAct:Search(dwID)
	if tLine then
		return tLine.szTitle
	end

	return nil
end

function Table_GetOperActyDes(dwID)
	local tLine = g_tTable.OperatAct:Search(dwID)
	if tLine then
		return tLine.szDes
	end

	return nil
end

function Table_GetOperationActCard()
	local res = {}

	local nCount = g_tTable.OperatActCard:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.OperatActCard:GetRow(i)
		table.insert(res, tLine)
	end

	return res
end

function Table_GetOperaionActUrl(szName)
	local nCount = g_tTable.OperatActUrl:GetRowCount()

	for i = 2, nCount do
		local tLine = g_tTable.OperatActUrl:GetRow(i)
		if tLine.szButtonName == szName then
			return tLine.szUrl
		end
	end
end

function Table_GetOperatActFRecall()
	local res = {}

	local nCount = g_tTable.OperatActFRecall:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.OperatActFRecall:GetRow(i)
		table.insert(res, tLine)
	end

	return res
end

function Table_GetChongXiaoMonthlyByMonth(nMonth)
	local tRes = {}
	local bIsDataGeted = false
	local nCount = g_tTable.ChongXiaoMonthly:GetRowCount()
	for i = 2,nCount do
		local tLine = g_tTable.ChongXiaoMonthly:GetRow(i)
		if nMonth == tLine.dwID then
			table.insert(tRes,tLine)
			bIsDataGeted = true
		end
		if  bIsDataGeted and nMonth ~= tLine.dwID then
			break
		end
	end
	return tRes
end

function Table_GetChongXiaoMonthly()
	local tRes = {}
	local bIsDataGeted = false
	local nMaxIssue = 0
	local nCount = g_tTable.ChongXiaoMonthly:GetRowCount()
	for i = 2,nCount do
		local tLine = g_tTable.ChongXiaoMonthly:GetRow(i)
		if not tRes[tLine.dwID] then
			tRes[tLine.dwID] = {}
		end
		table.insert(tRes[tLine.dwID], tLine)
		nMaxIssue = math.max(nMaxIssue, tLine.dwID)
	end
	return tRes, nMaxIssue
end

function Table_GetOperatFRecallImg()
	local res = {}

	local nCount = g_tTable.OperatFRecallImg:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.OperatFRecallImg:GetRow(i)
		table.insert(res, tLine)
	end

	return res
end

--------------------------------ForceUI--------
local m_tForceUI = nil
function Table_GetForceUI(force_id)
	local tForceUI = Table_GetAllForceUI()

	return tForceUI[ force_id ]
end

function Table_GetAllForceUI()
	if not m_tForceUI then
		m_tForceUI = {}
		local tab 	= g_tTable.ForceUI
		local count = tab:GetRowCount()

		for i = 1, count do
			local tLine = tab:GetRow(i)
			tLine.szName = UIHelper.GBKToUTF8(tLine.szName)
			tLine.szFullName = UIHelper.GBKToUTF8(tLine.szFullName)
			m_tForceUI[ tLine.force_id ] = tLine
		end
	end
	return m_tForceUI
end

function Table_GetForceName(dwForceID, bWithoutJianghu)
	local tLine = Table_GetForceUI(dwForceID)
	if not tLine then
		dwForceID = 0
		tLine = Table_GetForceUI(dwForceID)
	end

	if bWithoutJianghu and dwForceID == 0 then
		return nil
	end

	return tLine.szName
end

function Table_GetForceFullName(dwForceID, bWithoutJianghu)
	local tLine = Table_GetForceUI(dwForceID)
	if not tLine then
		dwForceID = 0
		tLine = Table_GetForceUI(dwForceID)
	end

	if bWithoutJianghu and dwForceID == 0 then
		return nil
	end

	return tLine.szFullName
end

--------------------------------ForceUI--------
function Table_GetProgressBar(nID)
	local tLine = g_tTable.ProgressBar:Search(nID)
	return tLine
end

function Table_GetAutoProgressBarInfo(nID)
	local tLine = g_tTable.AutoProgressBarInfo:Search(nID)
	return tLine
end

function Table_GetPersonLabel(id)
	local tLine = g_tTable.PersonLabel:Search(id)
	return tLine
end

function Table_GetAllPersonLabel()
	local tRes  = {}
	local tLine
	local tab   = g_tTable.PersonLabel
	local count = tab:GetRowCount()
	for i = 1, count do
		tLine = tab:GetRow(i)
		table.insert(tRes, tLine)
	end
	return tRes
end

function Table_GetMiniAvatarID(id)
	local tLine = g_tTable.GetMiniAvatarID:Search(id)
	return tLine
end


function Table_GetNewPQ(dwPQID)
	local nCount = g_tTable.NewPQ:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.NewPQ:GetRow(i)
		if tLine.dwPQID == dwPQID then
			return tLine
		end
	end
end

function Table_GetMapEventCondition(nConditionID)
	local nCount = g_tTable.MapEventCondition:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.MapEventCondition:GetRow(i)
		if tLine.nConditionID == nConditionID then
			return tLine
		end
	end
end

function Table_GetNewPQ_NPC_Template()
	local tRes = {}
	local nCount = g_tTable.NewPQ:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.NewPQ:GetRow(i)
		tRes[tLine.dwPQID] = tLine.dwWatchNpcTemplateID
	end

	return tRes
end

function Table_GetNewPQId(nType)
	local nCount = g_tTable.NewPQ:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.NewPQ:GetRow(i)
		if tLine.nType == nType then
			return tLine.dwPQID
		end
	end
end

function Table_GetNewPQ_ByNPCTemplate(dwNpcTemplateID)
	local tRet = {}
	local nCount = g_tTable.NewPQ:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.NewPQ:GetRow(i)
		if tLine.dwWatchNpcTemplateID == dwNpcTemplateID then
			tRet = tLine
			break
		end
	end

	return tRet
end

function Table_GetPQStage(dwID)
	local nCount = g_tTable.NewPQStage:GetRowCount()

	for i = 2, nCount do
		local tLine = g_tTable.NewPQStage:GetRow(i)
		if tLine.dwID == dwID then
			return tLine
		end
	end
end

function Table_GetNewPQ_AllPos()
	local tRes = {}
	local nCount = g_tTable.Minimap_Taiyuan:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.Minimap_Taiyuan:GetRow(i)
		table.insert(tRes, tLine.dwDynamicDataType)
	end

	return tRes
end

function Table_GetNewPQ_Npc(nType)
	local nCount = g_tTable.Minimap_Taiyuan:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.Minimap_Taiyuan:GetRow(i)
		if tLine.dwDynamicDataType == nType then
			return tLine
		end
	end
end

function Table_GetHorseEquipGainWay()
	local tList = {}
	local nCount = g_tTable.HorseEquipGainWay:GetRowCount()
	for i = 1, nCount do
		local tLine = g_tTable.HorseEquipGainWay:GetRow(i)
		table.insert(tList, tLine)
	end
	return tList
end

local tHorseExteriorMap = nil
function Table_GetHorseEquipExteriorByIndex(dwExteriorID)
	if not tHorseExteriorMap then
		tHorseExteriorMap = {}
		local nCount = g_tTable.CoinShop_HorseAdornment:GetRowCount()
		for i = 2, nCount do
			local tLine = g_tTable.CoinShop_HorseAdornment:GetRow(i)
			if not tHorseExteriorMap[tLine.dwExteriorID] then
				tHorseExteriorMap[tLine.dwExteriorID] = {}
			end
			table.insert(tHorseExteriorMap[tLine.dwExteriorID], tLine)
		end
	end
	return tHorseExteriorMap[dwExteriorID]
end

function Table_GetHorseAdornment(dwItemIndex)
	local nSetID,tbSetID = 0,{}
	local nCount = g_tTable.HorseAdornment:GetRowCount()

	for i = 2,nCount do
		local tLine = g_tTable.HorseAdornment:GetRow(i)
		if tLine.dwItemIndex == dwItemIndex then
			nSetID = tLine.nSetID
		end
	end
	for i = 2,nCount do
		local tLine = g_tTable.HorseAdornment:GetRow(i)
		if tLine.nSetID == nSetID then
			table.insert(tbSetID,tLine)
		end
	end
	return tbSetID
end

function Table_GetHorseAttrs()
	local tBasic, tMagic= {}, {}

	local nCount = g_tTable.NewHorseAttr:GetRowCount()

	for i = 2, nCount do
		local tLine = g_tTable.NewHorseAttr:GetRow(i)
		if tLine.bShow then
			local dwID = tLine.dwID
			if tLine.nLevel == 0 and tLine.nType == 0 then
				tBasic[dwID] = {}
				table.insert(tBasic[dwID], tLine)
			elseif tLine.nLevel == 0 and tLine.nType == 1 then
				tMagic[dwID] = {}
				table.insert(tMagic[dwID], tLine)
			else
				if tBasic[dwID] then
					table.insert(tBasic[dwID], tLine)
				elseif tMagic[dwID] then
					table.insert(tMagic[dwID], tLine)
				end
			end
		end
	end

	return tBasic, tMagic
end

function Table_GetHorseTuJianAttr(dwID, dwLevel)
	local nCount = g_tTable.NewHorseAttr:GetRowCount()

	for i = 2, nCount do
		local tLine = g_tTable.NewHorseAttr:GetRow(i)
		if tLine.dwID == dwID and tLine.nLevel == dwLevel then
			return tLine
		end
	end
end

function Table_GetHorseChildAttr(dwID, dwLevel)
	local nCount = g_tTable.NewHorseAttr:GetRowCount()

	for i = 2, nCount do
		local tLine = g_tTable.NewHorseAttr:GetRow(i)
		if tLine.dwID == dwID and tLine.nLevel == dwLevel then
			return clone(tLine)
		end
	end

	for i = 2, nCount do
		local tLine = g_tTable.NewHorseAttr:GetRow(i)
		if tLine.dwID == dwID and tLine.nLevel == 0 then
			return clone(tLine)
		end
	end
end

function Table_GetShopMultiBuyLimit(dwTabType, dwIndex)
	local tLine = g_tTable.ShopMultiBuyLimit:Search(dwTabType, dwIndex)
	if not tLine then
		return
	end

	return tLine.nLimit, tLine.nStep
end

function Table_GetShopPanelSelector(nShopID)
	local tLine = g_tTable.ShopPanelSelector:Search(nShopID)
	return tLine
end

function Table_GetShopPanelInfo(nShopID)
	local tLine = g_tTable.ShopList:Search(nShopID)
	return tLine
end

function Table_GetShopGroup(dwNpcID)
	local tShopMap = {}
	local tShopClass = {}
	local tLine = g_tTable.ShopGroup:Search(dwNpcID)
	if not tLine then
		return
	end
	tShopClass.szName = tLine.szGroupName
	for i = 1, 5 do
		local szShopList = tLine["szShopList" .. i]
		if szShopList ~= "" then
			table.insert(tShopClass, {szName = tLine["szShopClass" .. i]})
			local tList = string.split(szShopList, ";")
			for _, ShopID in ipairs(tList) do
				if ShopID ~= "" then
					local tShop = {bShow = false}
					table.insert(tShopClass[#tShopClass], tShop)
					tShopMap[tonumber(ShopID)] = tShop
				end
			end
		end
	end
	return tShopClass, tShopMap
end


local m_tAttributeToCategoryCache
function Table_GetCategoryByAttributeID(nID)
	if not m_tAttributeToCategoryCache then
		m_tAttributeToCategoryCache = {}
		local nCount = g_tTable.AttributeToCategory:GetRowCount()
		for i = 2, nCount do
			local tLine = g_tTable.AttributeToCategory:GetRow(i)
			local dwID = AttributeStringToID(tLine.AttributeID)
			if dwID then
				m_tAttributeToCategoryCache[dwID] = tLine.CategoryTitle
			end
		end
	end

	return m_tAttributeToCategoryCache[nID]
end

function Table_GetChooseStep(dwStep)
	local nCount = g_tTable.ChooseStep:GetRowCount()
	if not dwStep then
		dwStep = 0
	end
	for i = 2, nCount do
		local tLine = g_tTable.ChooseStep:GetRow(i)
		if tLine.dwStep == dwStep then
			return tLine
		end
	end
end


function Table_GetDungeonEnterTip(szName)
	local nCount = g_tTable.DungeonEnterTip:GetRowCount()

	for i = 2, nCount do
		local tLine = g_tTable.DungeonEnterTip:GetRow(i)
		if tLine.szName == szName then
			return tLine
		end
	end
end

function Table_GetCDProcessBoss(dwMapID)
	local tBossList = GetCDProcessInfo(dwMapID)
	for _, tBoss in ipairs(tBossList) do -- 端游接口改了字段名，不确定是否会改回来先统一处理一下
		tBoss.dwMapID = tBoss.dwMapID or tBoss.MapID
		tBoss.dwBossIndex = tBoss.dwBossIndex or tBoss.BossIndex
		tBoss.dwProgressID = tBoss.dwProgressID or tBoss.ProgressID
		tBoss.szName = tBoss.szName or tBoss.Name
	end
	return tBossList
end


function Table_GetBoss(dwMapID, dwProgressID)
	local tBossList = Table_GetCDProcessBoss(dwMapID) or {}

	for _, tBoss in ipairs(tBossList) do
		if dwProgressID == tBoss.dwProgressID then
			return tBoss
		end
	end
	return nil
end

function Table_FindBoss(dwIndex)
	local nCount = g_tTable.DungeonBoss:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.DungeonBoss:GetRow(i)
		if tLine.dwIndex == dwIndex then
			return true
		end
	end
	return nil
end

local m_EquipRecommendKungfus = {}
function Table_GetEquipRecommendKungfus(nRecommendID, bIgnoreDesc)
	local t = m_EquipRecommendKungfus[nRecommendID]
	local szDesc = ""

	if not bIgnoreDesc or not t then
		local tLine = g_tTable.EquipRecommend:Search(nRecommendID)
		if tLine then
			szDesc = tLine.szDesc
			if not t then
				t = {}
				for _, dwKungfu in ipairs(ParseIDList(tLine.kungfu_ids)) do
					if dwKungfu then
						t[dwKungfu] = true
					end
				end

				m_EquipRecommendKungfus[nRecommendID] = t
			end
		end
	end
	return t, szDesc
end

function Table_GetTrolltechHorse()
	local tRes = {}
	local nCount = g_tTable.TrolltechHorse:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.TrolltechHorse:GetRow(i)
		table.insert(tRes, tLine)
	end

	return tRes
end

function Table_GetFancySkatingInfo(szTableName, Path, Title)
	if not IsUITableRegister(szTableName) then
		RegisterUITable(szTableName, Path, Title)
	end
	local tRes = {}
	local nCount = g_tTable[szTableName]:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable[szTableName]:GetRow(i)
		table.insert(tRes, tLine)
	end
	return tRes
end

function Table_GetFancySkatingMusicInfo(dwID)
	local nCount = g_tTable.FancySkatingMusicInfo:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.FancySkatingMusicInfo:GetRow(i)
		if tLine.dwID == dwID then
			return tLine
		end
	end
end

function Table_GetGrowInfo(dwIndex)
	local tRes = {}
	local nCount = g_tTable.TrolltechHorse:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.TrolltechHorse:GetRow(i)
		if tLine.nItemTabIndex == dwIndex then
			return tLine
		end
	end

	return nil
end

function Table_GetAdventure()
	local tRes = {}
	local nCount = g_tTable.Adventure:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.Adventure:GetRow(i)
		local tBuffList = StringParse_Numbers(tLine.szBuffList)
		tLine.tBuffList = tBuffList
		table.insert(tRes, tLine)
	end

	return tRes
end

function Table_GetAdventureByID(dwAdvID)
	local tLine = g_tTable.Adventure:Search(dwAdvID)
	return tLine
end

function Table_GetAdventureName(dwAdvID)
	local szName = ""
	local tLine = g_tTable.Adventure:Search(dwAdvID)
	if tLine and tLine.szName then
		szName = tLine.szName
	end

	return szName
end

function Table_GetAdventureTask()
	local tRes = {}
	local nCount = g_tTable.AdventureTask:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.AdventureTask:GetRow(i)
		table.insert(tRes, tLine)
	end

	return tRes
end

function Table_GetOneKindAdventure(dwAdvID)
	local tRes = {}
	local nCount = g_tTable.AdventureTask:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.AdventureTask:GetRow(i)
		if tLine.dwAdventureID == dwAdvID then
			table.insert(tRes, tLine)
		end
	end

	return tRes
end

function Table_GetAdventureTryBook(dwAdvID)
	local tRes = {}
	local nCount = g_tTable.AdventureTryBook:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.AdventureTryBook:GetRow(i)
		if tLine.dwAdvID == dwAdvID and not tLine.bHide then
			table.insert(tRes, tLine)
		end
	end
	return tRes
end

function Table_GetAchievementProgress(nID)
	local tLine = g_tTable.AchievementProgress:Search(nID)
	return tLine
end

function Table_FindAchievementProgress(nFinishPoint)
	local nCount = g_tTable.AchievementProgress:GetRowCount()
	for i = 1, nCount do
		local tLine = g_tTable.AchievementProgress:GetRow(i)
		if nFinishPoint >= tLine.nTop and nFinishPoint <= tLine.nLast then
			return tLine
		end
	end
end

function Table_GetTaskToAdvID(dwTaskID)
	local nCount = g_tTable.AdventureTask:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.AdventureTask:GetRow(i)
		if tLine.nQuestID ~= 0 then
			if tLine.nQuestID == dwTaskID then
				return tLine.dwAdventureID
			end
		elseif dwTaskID == tLine.dwAcceptID or dwTaskID == tLine.dwFinishID then
			return tLine.dwAdventureID
		end
	end

	return nil
end

do
local m_tSkillEffectByBuff = {}
function Table_GetSkillEffectByBuff(dwBuffID)
	local szKey = dwBuffID
	if m_tSkillEffectByBuff[szKey] == nil then
		local tLine = g_tTable.SkillEffect:Search(dwBuffID)
		if tLine then
			m_tSkillEffectByBuff[szKey] = tLine
		else
			m_tSkillEffectByBuff[szKey] = false
		end
	end
	return m_tSkillEffectByBuff[szKey]
end

local m_tSkillEffectBySkill = {}
function Table_GetSkillEffectBySkill(dwSkillID)
	local szKey = dwSkillID
	if m_tSkillEffectBySkill[szKey] == nil then
		m_tSkillEffectBySkill[szKey] = false
		for _, line in ilines(g_tTable.SkillEffect) do
			if line.dwSkillID == dwSkillID then
				m_tSkillEffectBySkill[szKey] = line
			end
		end
	end
	return m_tSkillEffectBySkill[szKey]
end
end

function Table_GetCharInfoShow(dwMountKungfu)
	local tLine = g_tTable.CharInfoAttack:Search(dwMountKungfu)
	return tLine
end

function Table_GetCharInfoMainAttrShow(dwMountKungfu)
	local tLine = g_tTable.CharInfoMainAttrShow:Search(dwMountKungfu)
	return tLine
end

function Table_GetMapGuideCity(dwMapID)
	local tLine = g_tTable.MapGuide_TrafficSkill:Search(dwMapID)
	if tLine then
		return tLine.dwCityID
	end
end

function Table_GetDesignationGeneration(dwForce, dwGeneration)
	local tLine = g_tTable.Designation_Generation:Search(dwForce, dwGeneration)
	if tLine then
		return tLine.szName
	end
	return ""
end

function Table_GetEnchantTipShow()
	if not tEnchantTipShow then
		tEnchantTipShow = {}
		local nCount = g_tTable.EnchantTipShow:GetRowCount()
		for i = 1, nCount do
			local tLine = g_tTable.EnchantTipShow:GetRow(i)
			tEnchantTipShow[tLine.nEquipmentSub] = tLine
		end
	end

	return tEnchantTipShow
end

function Table_IsSkillShieldLevelUp(skill_id)
	local tLine = g_tTable.SkillShield:Search(skill_id)
	if tLine and tLine.type == "level_up" then
		return true
	end
	return false
end

function Table_GetGrowthEquitLevel(dwTabType, dwIndex)
	local tLine = g_tTable.GrowthEquipLevel:Search(dwTabType, dwIndex)
	if tLine then
		return tLine.nLevel, tLine.nMaxLevel
	end

	return 1, 10
end

function Table_IsSimplePlayer(dwTemplateID)
	local tLine = g_tTable.SimplePlayer:Search(dwTemplateID)
	if tLine then
		return true
	end
	return false
end

function Table_GetArtistReward()
	local tRes = {}
	local nCount = g_tTable.ArtistReward:GetRowCount()
	for i = 1, nCount do
		local tLine = g_tTable.ArtistReward:GetRow(i)
		table.insert(tRes, tLine)
	end

	return tRes
end

function Table_GetHomelandOverviewInfo()
	local tInfo = {}
	local nCount = g_tTable.HomelandOverview:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.HomelandOverview:GetRow(i)
		local tMenuInfo = {}
		if tLine.szMenu ~= "" then
			local tTemp = string.split(tLine.szMenu, "|")
			local tLevel = string.split(tLine.szMenuLevel, "|")
			local tCommunityLimit = string.split(tLine.szCommunityLimit, "|")
			local tMax = string.split(tLine.szMenuMax, "|")
			local tNpcID = string.split(tLine.szNpcInfo, "|")
			local tFurnitureType = string.split(tLine.szFurnitureType, "|")
			local tCalendarID = string.split(tLine.szCalendarID, "|")
			local tGuide = string.split(tLine.szGuide, "|")
			local tCatg = string.split(tLine.szCatg, "|")
			for k, v in ipairs(tTemp) do
				local tNpcInfo = {0, 0}
				if tNpcID[k] and tNpcID[k] ~= "" then
					tNpcInfo = string.split(tNpcID[k], ";")
				end
				local tCatgInfo = {1, 1, 0}
				if tCatg[k] and tCatg[k] ~= "" then
					tCatgInfo = string.split(tCatg[k], ";")
				end
				table.insert(tMenuInfo, {szName = v, nLevel = tonumber(tLevel[k]), nCommunityLimit = tonumber(tCommunityLimit[k]),
					nMax = tonumber(tMax[k]), nLinkID = tonumber(tNpcInfo[1]) or 0, nMapID = tonumber(tNpcInfo[2]) or 0,
					nFurnitureType = tonumber(tFurnitureType[k]) or 0, nCalendarID = tonumber(tCalendarID[k]) or 0,
					nGuide = tonumber(tGuide[k]) or 0, nCatg1 = tonumber(tCatgInfo[1]) or 1, nCatg2 = tonumber(tCatgInfo[2]) or 1, nSubgroup = tonumber(tCatgInfo[3]) or 0})
			end
		end
		tLine.tMenuInfo = tMenuInfo
		table.insert(tInfo, tLine)
	end
	return tInfo
end

function Table_GetHomelandOverviewRewardInfo()
	local tInfo = {}
	local nCount = g_tTable.HomelandOverviewReward:GetRowCount()
	for i = 2, nCount do
		local tLine = clone(g_tTable.HomelandOverviewReward:GetRow(i))
		local tReward = {}
		if tLine.szReward ~= "" then
			local tTemp = string.split(tLine.szReward, ";")
			for _, v in ipairs(tTemp) do
				if v and v ~= "" then
					local tFields = string.split(v, "_")
					if tFields[1] == "COIN" then
						table.insert(tReward, {
							bIsCoin = true,
							nCurrencyID = tonumber(tFields[2]),
							nCount = tonumber(tFields[3]) or 0,
						})
					else
						table.insert(tReward, {
							bIsCoin = false,
							nItemType = tonumber(tFields[1]),
							nItemID = tonumber(tFields[2]),
							nCount = tonumber(tFields[3]) or 1,
						})
					end
				end
			end
		end
		tLine.tReward = tReward
		table.insert(tInfo, tLine)
	end
	return tInfo
end

function Table_GetDesertStormSkinType()
	local tRes = {}
	local nCount = g_tTable.DesertStormSkinType:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.DesertStormSkinType:GetRow(i)
		if tLine then
			table.insert(tRes, tLine)
		end
	end
	return tRes
end

function Table_GetDesertStormSkinInfo()
	local tRes = {}
	local nCount = g_tTable.DesertStormSkin:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.DesertStormSkin:GetRow(i)
		if tLine then
			table.insert(tRes, tLine)
		end
	end
	return tRes
end

function Table_GetCueWords(dwID)
	return g_tTable.CueWords:Search(dwID)
end

function Table_GetIdentityInfo()
	local tRes = {}
	local nCount = g_tTable.IdentityInfo:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.IdentityInfo:GetRow(i)
		table.insert(tRes, tLine)
	end

	return tRes
end

function Table_GetOneIdentityInfo(nIdentity)
	local tLine = g_tTable.IdentityInfo:Search(nIdentity)
	if tLine then
		return tLine
	end
end

function Table_GetIdentityOtherInfo()
	local tRes = {}
	local nCount = g_tTable.IdentityOtherInfo:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.IdentityOtherInfo:GetRow(i)
		table.insert(tRes, tLine)
	end

	return tRes
end

function Table_GetAnnounceImage(nID)
	local tLine = g_tTable.AnnounceImage:Search(nID)
	local szAdd = ""
	if tLine then
		szAdd = "path=\"" .. tLine.szPath .. "\""
	end
	return szAdd
end

function Table_GetIdentityPetWord(nModelID)
	local nCount = g_tTable.IdentityPet:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.IdentityPet:GetRow(i)
		if nModelID == tLine.nModelID then
			return tLine
		end
	end

	return nil
end

function Table_IsArtistWriteExist(nID)
	local nCount = g_tTable.ArtistWriteList:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.ArtistWriteList:GetRow(i)
		if nID == tLine.nShowItemID then
			return true
		end
	end

	return false
end

function Table_GetFBCountDown(nID)
	local tLine = g_tTable.FBCountDown:Search(nID)
	return tLine
end

function Table_GetFireBookInfoInfo()
	local tRes = {}
	local nCount = g_tTable.FireBookInfo:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.FireBookInfo:GetRow(i)
		table.insert(tRes, tLine)
	end

	return tRes
end

function Table_GetSpecialTimeToItemCount(nTime)
	local tLine = g_tTable.FireBookSpecialInfo:Search(nTime)
	if tLine then
		return tLine
	end
end


function Table_GetFireBookTypeName(nID)
	local tLine = g_tTable.FireBookType:Search(nID)
	if tLine then
		return tLine.szTypeName
	end
end

function ParseNumbers(szNumbers)
	local tNumbers = {}
	for szNumber1, szNumber2 in string.gmatch(szNumbers, "([%d]+):([%d]+);?") do
		local nNumber1 = tonumber(szNumber1)
		local nNumber2 = tonumber(szNumber2)
		table.insert(tNumbers, {nNumber1, nNumber2})
	end
	return tNumbers
end

local tViewReplace = nil
local function LoadViewReplace()
	tViewReplace = {}
	local nCount = g_tTable.ViewReplace:GetRowCount()
	for i = 1, nCount do
		local tLine = g_tTable.ViewReplace:GetRow(i)
		local tKey = ParseNumbers(tLine.szRepresentKey)
		local tReplace = ParseNumbers(tLine.szRepresentReplace)
		local tView = {}
		tView.tKey = tKey
		tView.tReplace = tReplace
		table.insert(tViewReplace, tView)
	end
end

function Table_ViewReplace()
	if not tViewReplace then
		LoadViewReplace()
	end
	return tViewReplace
end

function Table_GetKungFuName(dwKungFuID)
	local nCount = g_tTable.TeamPosition_KungFu:GetRowCount()
	for i = 1, nCount do
		local tLine = g_tTable.TeamPosition_KungFu:GetRow(i)
		if tLine.dwKungFuID == dwKungFuID then
			return tLine.szKungfuName
		end
	end
end

function Table_GetMiddleMapCommandInfo()
	local tRes = {}
	local nCount = g_tTable.MiddleMapCommand:GetRowCount()
	for i = 1, nCount do
		local tLine = g_tTable.MiddleMapCommand:GetRow(i)
		tRes[tLine.szMarkBtnName] = tLine
	end

	return tRes
end

function Table_GetMiddleMapCommandNpc()
	local tRes = {}
	local nCount = g_tTable.MiddleMapCommandNpc:GetRowCount()
	for i = 1, nCount do
		local tLine = g_tTable.MiddleMapCommandNpc:GetRow(i)
		table.insert(tRes, tLine)
	end

	return tRes
end

function Table_GetMapMarkForIdentity(nType)
	local tLine = g_tTable.MapMarkForIdentity:Search(nType)
	return tLine
end

function Table_GetQuestIdentityExp(nType)
	local tLine = g_tTable.QuestIdentityExp:Search(nType)
	return tLine
end

function Table_GetArtistSkillsInfo(nTabType, nTabIndex)
	local nCount = g_tTable.ArtistSkills:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.ArtistSkills:GetRow(i)
		if tLine.nTabType == nTabType and tLine.nTabIndex == nTabIndex then
			return tLine.nLevel, tLine.nSkillID
		end
	end
end

do local cache = {}
function Table_GetSkillExtCDID(dwID)
	if cache[dwID] == nil then
		local tLine = g_tTable.SkillExtCDID:Search(dwID)
		cache[dwID] = tLine and tLine.dwExtID or false
	end
	return cache[dwID] and cache[dwID] or nil
end
end

function Table_GetUpSkillEffect(dwSkillID, nMaxRadius)
	local nCount = g_tTable.UpSkillEffect:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.UpSkillEffect:GetRow(i)
		if tLine.dwSkillID == dwSkillID and
			(tLine.nMaxRadius == 0 or tLine.nMaxRadius == nMaxRadius) then
			return tLine
		end
	end
	return nil
end

function Table_GetFilterInviteInfo(nType)
	local tLine = g_tTable.FilterInviteMsg:Search(nType)
	return tLine
end

function Table_GetPlayerReturnShowTable(nGradeID)
	local tTable = {}
	local nCount = g_tTable.PlayerReturnShow:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.PlayerReturnShow:GetRow(i)
		if tLine.nGradeID == nGradeID then
			table.insert(tTable, tLine)
		end
	end
	return tTable
end

function Table_GetPlayerReturnBoxInfo(nIndex)
	local tLine = g_tTable.PlayerReturnBox:Search(nIndex)
	return tLine
end

function Table_GetQixueTeachByList(dwKungfuID)
	local tTeach = {}
	local tLine = g_tTable.QixueTeachBy:Search(dwKungfuID)
	if tLine then
		local tQixueList = StringParse_Numbers(tLine.szQixueList)
		return tQixueList
	end

	return {}
end

function Table_GetFBCountNum(dwID)
	local tLine = g_tTable.FBCountNum:Search(dwID)
	return tLine
end

function Table_GetAllMasterBunusItem()
	local tItemList = {}
	local nCount = g_tTable.MasterBonusItem:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.MasterBonusItem:GetRow(i)
		table.insert(tItemList, tLine)
	end
	return tItemList
end

function Table_GetMasterBonusRank()
	local tRankList = {}
	local nCount = g_tTable.MasterBonus:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.MasterBonus:GetRow(i)
		table.insert(tRankList, tLine)
	end
	return tRankList
end

function Table_GetArenaSkillAdjust(dwKungfuID)
	local tDynamic = {}
	local tDisable = {}
	local tLine = g_tTable.ArenaSkillAdjust:Search(dwKungfuID)
	if tLine then
		for szBuffID, szLevel in string.gmatch(tLine.szDynamicBuff, "([%d]+)_([%d]+);?") do
			local nBuffID = tonumber(szBuffID)
			local nLevel = tonumber(szLevel)
			table.insert(tDynamic, {nBuffID, nLevel})
		end

		for szSkillID, szLevel in string.gmatch(tLine.szDisableSkills, "([%d]+)_([%d]+);?") do
			local nSkillID = tonumber(szSkillID)
			local nLevel = tonumber(szLevel)
			table.insert(tDisable, {nSkillID, nLevel})
		end
	end
	return tDynamic, tDisable
end

function Table_GetServerName(dwServerID)
	local szName = ""
	local tLine = g_tTable.ServerName:Search(dwServerID)
	if tLine then
		szName = tLine.szName
	end
	return szName
end

function Table_GetAllDanmakuColor()
	local tTable = {}
	local nCount = g_tTable.DanmakuColor:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.DanmakuColor:GetRow(i)
		table.insert(tTable, tLine)
	end
	return tTable
end

function Table_GetDanmakuColor(dwID)
	local tLine = g_tTable.DanmakuColor:Search(dwID)
	return tLine
end

function Table_GetPVPLinkDate()
	local tTable = {}
	local nCount = g_tTable.PVPLinkDate:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.PVPLinkDate:GetRow(i)
		table.insert(tTable, tLine)
	end
	return tTable
end

function Table_GetArenaLiveMap()
	local tTable = {}
	local nCount = g_tTable.ArenaLiveMap:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.ArenaLiveMap:GetRow(i)
		table.insert(tTable, tLine)
	end
	return tTable
end

function Table_GetForceSmallIcon()
	local tTable = {}
	local nCount = g_tTable.Force_small_icon:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.Force_small_icon:GetRow(i)
		tTable[tLine.dwID] = tLine
	end
	return tTable
end

function Table_GetAllSelfieLightParams()
	local aAllParams = {}
	local nCount = g_tTable.SelfieLightParams:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.SelfieLightParams:GetRow(i)
		local tInfo = {}  --- 认为它是数组中的位置就代表对应光源的index
		tInfo.fIntensityMin = tLine.fIntensityMin
		tInfo.fIntensityMax = tLine.fIntensityMax
		tInfo.fSaturationMin = tLine.fSaturationMin
		tInfo.fSaturationMax = tLine.fSaturationMax
		tInfo.aColorList = {}
		for j = 1, 16 do
			local szColor = tLine["szColor" .. j]
			if szColor ~= "" then
				local tRGB = ParsePointList(szColor)
				for k = #tRGB + 1, 3 do
					table.insert(tRGB, 0)
				end
				table.insert(tInfo.aColorList, tRGB)
			else
				break
			end
		end

		table.insert(aAllParams, tInfo)
	end
	return aAllParams
end

function Table_GetSelfieResolution()
	local tList = {}
	local nCount = g_tTable.SelfieResolution:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.SelfieResolution:GetRow(i)
		table.insert(tList, tLine)
	end
	return tList
end

local l_aSelfieFilterParamList, l_aOutsideFilterParamList = {}, {}
local function l_InitAllFilterParams()
	local nCount = g_tTable.SelfieFilter:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.SelfieFilter:GetRow(i)
		local nForOutside = tLine.nForOutside
		if nForOutside > 0 then
			table.insert(l_aOutsideFilterParamList, tLine)
		elseif nForOutside == 0 then
			table.insert(l_aSelfieFilterParamList, tLine)
		else
			table.insert(l_aOutsideFilterParamList, tLine)
			table.insert(l_aSelfieFilterParamList, tLine)
		end
	end
end

function Table_GetAllSelfieFilterParams()
	if #l_aSelfieFilterParamList + #l_aOutsideFilterParamList == 0 then
		l_InitAllFilterParams()
	end
	return l_aSelfieFilterParamList
end

function Table_GetAllOutsideFilterParams()
	if #l_aSelfieFilterParamList + #l_aOutsideFilterParamList == 0 then
		l_InitAllFilterParams()
	end
	return l_aOutsideFilterParamList
end

function Table_GetSelfieFilterParamsByLogicIndex(nFilterIndex)
	local nCount = g_tTable.SelfieFilter:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.SelfieFilter:GetRow(i)
		if tLine.nLogicIndex == nFilterIndex then
			return tLine
		end
	end
	return nil
end

function Table_GetAutoCorpsNameList()
	local tList = {}
	local nCount = g_tTable.AutoCorpsName:GetRowCount()
	for i = 1, nCount do
		local tLine = g_tTable.AutoCorpsName:GetRow(i)
		tList[tLine.ForceID] = tLine
	end
	return tList
end

function Table_GetTongTechNodeList()
	local tList = {}
	local nCount = g_tTable.TongTechTreeList:GetRowCount()
	for i = 1, nCount do
		local tLine = g_tTable.TongTechTreeList:GetRow(i)
		if not tList[tLine.nType] then
			tList[tLine.nType] = {}
		end
		local t = tList[tLine.nType]
		table.insert(t, tLine.nNodeID)
	end
	return tList
end

function Table_GetTongTechNodeMap()
    local tList = {}
    local nCount = g_tTable.TongTechTreeList:GetRowCount()
    for i = 1, nCount do
        local tLine = g_tTable.TongTechTreeList:GetRow(i)
        tList[tLine.nNodeID] = true
    end
    return tList
end

function Table_GetTeachingAim(dwID)
	local tLine = g_tTable.Teaching_Aim:Search(dwID)
	return tLine
end

function Table_AutoQuestList(dwMapID, nForceID, nCamp)
	local nCount = g_tTable.AutoQuestList:GetRowCount()
	for i = 1, nCount do
		local tLine = g_tTable.AutoQuestList:GetRow(i)
		if tLine.dwMapID == dwMapID and
			(tLine.nForceID == -1 or nForceID == tLine.nForceID) and
			(tLine.nCamp == -1 or nCamp == tLine.nCamp) then
			return tLine
		end
	end
end


function Table_GetVideoSetting(nLevel)
	local tSettings = g_tTable.VideoSetting:Search(nLevel)
	return tSettings
end

function Table_GetTreasureInfoTitle(nRanking)
	local nCount = g_tTable.TreasureInfo:GetRowCount()
	local hPlayer = GetClientPlayer()
	local hScene = hPlayer.GetScene()
	local dwMapID = hScene.dwMapID--UI_GetCurrentMapID()
	for i = 1, nCount do
		local tLine = g_tTable.TreasureInfo:GetRow(i)
		if nRanking >= tLine.nRanking then
			local tMap = ParseIDList(tLine.szMap)
			for k, v in pairs(tMap) do
				if v == dwMapID then
					return tLine
				end
			end
		end
	end
end

--
function Table_GetMiddleMapLineConfig(dwID)
	local tLine = g_tTable.MiddleMapLineConfig:Search(dwID)
	return tLine
end

function Table_GetTreasureTeamInfoTitle(dwTeamID)
	local tLine = g_tTable.TreasureTeamInfo:Search(dwTeamID)
	return tLine
end

function Table_GetLocalActionBarData(szActionBarName)
	local nCount = g_tTable.ExtendActionBarData:GetRowCount()
	for i = 1, nCount do
		local tLine = g_tTable.ExtendActionBarData:GetRow(i)
		if string.find(tLine.szActionBarName, szActionBarName) then
			return tLine.dwCount, tLine.dwMobileCount, tLine.bMobileShowInPage
		end
	end
	return nil
end

function Table_GetLocalActionBarParam(szActionBarName, dwIndex, bMobile)
	bMobile = bMobile or false
	local nCount = g_tTable.ExtendActionBarData:GetRowCount()
	for i = 1, nCount do
		local tLine = g_tTable.ExtendActionBarData:GetRow(i)
		if string.find(tLine.szActionBarName, szActionBarName) then
			if bMobile then
				return tLine["szMobileParam" .. dwIndex]
			else
				return tLine["szParam" .. dwIndex]
			end
		end
	end
	return nil
end

function Table_GetMultiStageSkill(dwSkillID)
	local tLine = g_tTable.MultiStageSkill:Search(dwSkillID)
	return tLine
end

function Table_IsAutoSearchShield(dwType, dwID)
	local tLine = g_tTable.AutoSearchShield:Search(dwType, dwID)
	if tLine then
		return true
	end

	return false
end

------------------------花招节---------------------------------
function Table_GetHuaZhaoJieImageInfo(nImageID)
	local tLine = g_tTable.HuaZhaoJieImage:Search(nImageID)
	return tLine
end

function Table_GetLogoInfo(szServer)
	local nCount = g_tTable.PVPLogoInfo:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.PVPLogoInfo:GetRow(i)
		if StringFindW(szServer, tLine.szServer:trim()) then
			return tLine
		end
	end
end

function Table_GetMapInfoIdxByMapID()
	local tList = {}
	local nCount = g_tTable.PVPMapInfo:GetRowCount()
	for i = 1, nCount do
		local tLine = g_tTable.PVPMapInfo:GetRow(i)
		tList[tLine.nMapID] = tLine
	end
	return tList
end

function Table_GetPVPMapInfo(dwMapID)
	local tLine = g_tTable.PVPMapInfo:Search(dwMapID)
	return tLine
end

--大师赛观战头像
function Table_GetKungfuData()
	local tab	= g_tTable.MasterPVPKungfuFrame
	local count = tab:GetRowCount()
	local tRes	= {}
	local t
	for i= 2, count, 1 do
		t = tab:GetRow(i)
		tRes[t.dwKungFuID] = t
	end
	return tRes
end

function Table_GetBigKungfuInfo(dwKungFuID)
	local tLine	= g_tTable.MasterPVPKungfuFrame:Search(dwKungFuID)
	return tLine
end

---- BEGIN: 大侠之路
local function ParseItemString(szQuestItems)
	local tItemList		= {}
	local tQuestItems 	= SplitString(szQuestItems, ";")
	local nNumOfItems	= #tQuestItems
	for j = 1, nNumOfItems do
		local tItemInfo = {}
		local tItem = ParseIDList(tQuestItems[j])
		tItemInfo.nItemType  = tItem[1]
		tItemInfo.nItemIndex = tItem[2]
		tItemInfo.nItemNum   = tItem[3]
		table.insert(tItemList, tItemInfo)
	end
	return tItemList
end

function Table_GetRoadChivalrousInfo()
	local tList = {}
	local nCount = g_tTable.RoadChivalrous:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.RoadChivalrous:GetRow(i)
		if not tList[tLine.dwID] then
			tList[tLine.dwID] 					= tLine
			tList[tLine.dwID].tAllQuestsInfo 	= {}
			tList[tLine.dwID].tItemList			= ParseItemString(tLine.szQuestItems)
		else
			local tQuestInfo		= {}
			tQuestInfo.szQuestNameUITex = tLine.szQuestNameUITex
			tQuestInfo.nQuestNameFrame  = tLine.nQuestNameFrame
			tQuestInfo.dwQuestID 	= tLine.dwQuestID
			tQuestInfo.nLevel		= tLine.nLevel
			tQuestInfo.szQuestUITex = tLine.szQuestUITex
			tQuestInfo.nQuestFrame	= tLine.nQuestFrame
			tQuestInfo.szQuestIntro	= tLine.szQuestIntro
			tQuestInfo.szActivityID = tLine.szActivityID
			tQuestInfo.szDay		= tLine.szDay
			tQuestInfo.nStartTime	= tLine.nStartTime
			tQuestInfo.nLastTime	= tLine.nLastTime

			tQuestInfo.tItemList = ParseItemString(tLine.szQuestItems)
			table.insert(tList[tLine.dwID].tAllQuestsInfo, tQuestInfo)
		end
	end

	return tList
end

function Table_GetShareOneBillionRoadChivalrousQuestInfo()
	local tQuestInfoList = {}
	local nCount = g_tTable.RoadChivalrous:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.RoadChivalrous:GetRow(i)
		if tLine.bForShareOneBillion then
			local tQuestInfo = {}
			tQuestInfo.dwQuestID = tLine.dwQuestID
			tQuestInfo.szQuestNameUITex = tLine.szQuestNameUITex
			tQuestInfo.nQuestNameFrame = tLine.nQuestNameFrame
			tQuestInfo.szQuestName = tLine.szPageTitle
			tQuestInfo.nLevel = tLine.nLevel
			tQuestInfo.szQuestUITex = tLine.szQuestUITex
			tQuestInfo.nQuestFrame = tLine.nQuestFrame
			tQuestInfo.szQuestIntro = tLine.szQuestIntro
			tQuestInfo.szActivityID = tLine.szActivityID
			tQuestInfo.szDay = tLine.szDay
			tQuestInfo.nStartTime = tLine.nStartTime
			tQuestInfo.nLastTime = tLine.nLastTime

			tQuestInfo.tItemList = ParseItemString(tLine.szQuestItems)

			table.insert(tQuestInfoList, tQuestInfo)
		end
	end

	return tQuestInfoList
end

---- END: 大侠之路

function Table_GetWarningType()
	local tList = {}
	local nCount = g_tTable.WarningType:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.WarningType:GetRow(i)
		tList[tLine.szType] = tLine
	end

	return tList
end

function Table_GetSpecailGift(dwID)
	local tLine = g_tTable.SpecailGift:Search(dwID)
	return tLine
end

function Table_GetPlayerZombieLevel(hPlayer)
	if not hPlayer then
		return
	end
	local nCount = g_tTable.ZombieLevel:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.ZombieLevel:GetRow(i)
		if hPlayer.IsHaveBuff(tLine.nBuffID, tLine.nBuffLevel) then
			return tLine
		end
	end
end

function Table_IsShieldedNpc(dwTemplateID)
	local tLine = g_tTable.ShieldNpc:Search(dwTemplateID)
	if tLine then
		return tLine.bFocus, tLine.bSpeak
	end
	return false, false
end

function Table_GetMoviePath(dwID)
	local tLine = g_tTable.MoviePath:Search(dwID)
	return tLine
end

function Table_GetNewMovieInfo(dwID)
	local tLine = g_tTable.NewMovieInfo:Search(dwID)
	return tLine
end

--- 只返回第一个匹配的
function Table_GetNewMovieIDByProtocolID(dwProtocolID)
	local nRowCnt = g_tTable.NewMovieInfo:GetRowCount()
	for i = 2, nRowCnt do
		local tLine = g_tTable.NewMovieInfo:GetRow(i)
		if tLine.dwProtocolID == dwProtocolID then
			return tLine.dwID
		end
	end
	return 0
end

function Table_GetGrouponTemplate(dwTemplate)
	local tLine = g_tTable.GrouponTemplateName:Search(dwTemplate)
	if tLine then
		return tLine
	end
end

function Table_GetAchievementInfo(dwID)
    return GetAchievementInfo(dwID)
end

-- 声望势力相关
local l_tAllReputationGroupInfo = {}
local l_aDlcList = {}
function Table_GetAllRepuForceGroupInfo()
	if table_is_empty(l_tAllReputationGroupInfo) then
		local tTab	= g_tTable.ReputationForceGroup
		for i = 1, tTab:GetRowCount() do
			local tRow = tTab:GetRow(i)
			local nDlcID = tRow.nDlcID
			if nDlcID > 0 then
				local szGroupName = tRow.szGroupName
				local dwForceID = tRow.dwForceID

				if not l_tAllReputationGroupInfo[nDlcID] then
					l_tAllReputationGroupInfo[nDlcID] = {[szGroupName] ={dwForceID}}
				elseif not l_tAllReputationGroupInfo[nDlcID][szGroupName] then
					l_tAllReputationGroupInfo[nDlcID][szGroupName] = {dwForceID}
				else
					table.insert(l_tAllReputationGroupInfo[nDlcID][szGroupName], dwForceID)
				end

				if not CheckIsInTable(l_aDlcList, nDlcID) then
					table.insert(l_aDlcList, nDlcID)
				end
			end
		end

		table.sort(l_aDlcList, function(a, b) return a < b end)
	end

	return l_tAllReputationGroupInfo, l_aDlcList
end

function Table_GetDlcIDByForceID(dwForceID)
	local tTab	= g_tTable.ReputationForceGroup
	for i = 1, tTab:GetRowCount() do
		local tRow = tTab:GetRow(i)
		if dwForceID == tRow.dwForceID then
			return tRow.nDlcID
		end
	end
	return nil
end

function Table_GetSortedDlcList()
	local _, aDlcList = Table_GetAllRepuForceGroupInfo()
	return aDlcList
end

function Table_GetReputationLevelInfo(nLevel)
	local tLine = g_tTable.ReputationLevel:Search(nLevel)
	return tLine
end

function Table_GetMinMaxReputationLevel()
	local tTab	= g_tTable.ReputationLevel
	return tTab:GetRow(1).nLevel, tTab:GetRow(tTab:GetRowCount()).nLevel
end

function Table_GetReputationForceInfo(dwForceID)
	local tLine = g_tTable.ReputationForceInfo:Search(dwForceID)
	if tLine then
		tLine.szIconPath = string.gsub(tLine.szIconPath, "ui\\Image", "Resource")
		tLine.szIconPath = string.gsub(tLine.szIconPath, "ui/Image", "Resource")
		tLine.szIconPath = string.gsub(tLine.szIconPath, ".tga", ".png")
		tLine.szIconPath = string.gsub(tLine.szIconPath, ".Tga", ".png")
	end
	return tLine
end

function Table_GetReputationForceMaps(dwForceID)
	local tLine = g_tTable.ReputationForceInfo:Search(dwForceID)
	if tLine then
		local aMapIDStrings = ParseIDList(tLine.szMapIDs)
		local aMapIDs = {}
		for i, v in ipairs(aMapIDStrings) do
			table.insert(aMapIDs, tonumber(v))
		end
		return aMapIDs
	end
	return nil
end

local l_AllReputationGainDesc = {}
function Table_GetAllReputationGainDesc()  --- 可能以后不需要这个了
	if table_is_empty(l_AllReputationGainDesc) then
		local tTab	= g_tTable.ReputationGainDesc
		for i = 1, tTab:GetRowCount() do
			local tRow = tTab:GetRow(i)
			local dwForceID = tRow.dwForceID
			if not l_AllReputationGainDesc[dwForceID] then
				l_AllReputationGainDesc[dwForceID] = {}
			end

			table.insert(l_AllReputationGainDesc[dwForceID], {dwFromLevel=tRow.dwFromLevel, dwToLevel=tRow.dwToLevel, szDesc=tRow.szDesc})
		end
	end

	return l_AllReputationGainDesc
end

function Table_GetReputationGainDescByForceID(dwForceID)
	local tAllGainDesc = Table_GetAllReputationGainDesc()
	return tAllGainDesc[dwForceID]
end

local l_AllReputationRewardItemInfo = {}
function Table_GetAllReputationRewardItemInfo()
	if table_is_empty(l_AllReputationRewardItemInfo) then
		local tTab	= g_tTable.ReputationRewardItems
		for i = 1, tTab:GetRowCount() do
			local tRow = tTab:GetRow(i)
			local dwForceID = tRow.dwForceID
			local nReputationLevel = tRow.nReputationLevel
			if not l_AllReputationRewardItemInfo[dwForceID] then
				l_AllReputationRewardItemInfo[dwForceID] = {[nReputationLevel] = {{dwItemTabType = tRow.dwItemTabType, dwItemTabIndex = tRow.dwItemTabIndex}}}
			else
				if not l_AllReputationRewardItemInfo[dwForceID][nReputationLevel] then
					l_AllReputationRewardItemInfo[dwForceID][nReputationLevel] = {{dwItemTabType = tRow.dwItemTabType, dwItemTabIndex = tRow.dwItemTabIndex}}
				else
					table.insert(l_AllReputationRewardItemInfo[dwForceID][nReputationLevel], {dwItemTabType = tRow.dwItemTabType, dwItemTabIndex = tRow.dwItemTabIndex})
				end
			end
		end
	end

	return l_AllReputationRewardItemInfo
end

function Table_GetReputationRewardItemInfoByForceID(dwForceID)
	local tAllRewardItemInfo = Table_GetAllReputationRewardItemInfo()
	return tAllRewardItemInfo[dwForceID]
end

-- 家将相关
function Table_GetServantInfo(dwNpcIndex)
	local tLine = g_tTable.Servant:Search(dwNpcIndex)
	if tLine then
		tLine.szImagePath = string.gsub(tLine.szImagePath, "ui\\Image", "Resource")
		tLine.szImagePath = string.gsub(tLine.szImagePath, "ui/Image", "Resource")
		tLine.szImagePath = string.gsub(tLine.szImagePath, ".tga", ".png")
	end
	return tLine
end

local l_aServantAllCommonActionInfos = {}
function Table_GetServantAllCommonActionInfos()
	if table_is_empty(l_aServantAllCommonActionInfos) then
		local tTab	= g_tTable.ServantCommonActions
		for i = 2, tTab:GetRowCount() do
			local tRow = tTab:GetRow(i)
			table.insert(l_aServantAllCommonActionInfos, tRow)
		end
	end

	return l_aServantAllCommonActionInfos
end

function Table_GetServantCommonActionInfoByActionID(dwActionID)
	local tTab	= g_tTable.ServantCommonActions
	for i = 2, tTab:GetRowCount() do
		local tRow = tTab:GetRow(i)
		if tRow.dwActionID == dwActionID then
			return tRow
		end
	end
	return nil
end

function Table_GetServantSpecialActionInfoByNpcIndex(dwNpcIndex)
	local tLine = g_tTable.ServantSpecialAction:Search(dwNpcIndex)
	return tLine
end

function Table_GetNPCSpeechSounds(dwID)
	local tLine = g_tTable.NPCSpeechSounds:Search(dwID)
	if tLine then
		return tLine
	end
end

function Table_GetNPCSpeechSoundsBg(dwID)
	local tLine = g_tTable.NPCSpeechSoundsBg:Search(dwID)
	if tLine then
		return tLine
	end
end

function Table_GetVoiceTypeData()
	local tList = {}
	local nCount = g_tTable.VoiceType:GetRowCount()
	for i = 1, nCount do
		local tLine = g_tTable.VoiceType:GetRow(i)
		tList[tLine.dwID] = tLine
	end

	return tList
end

function Table_GetSpecialHorseOnJump()
	local tList = {}
	local nCount = g_tTable.SpecialHorseOnJump:GetRowCount()
	for i = 1, nCount do
		local tLine = g_tTable.SpecialHorseOnJump:GetRow(i)
		tList[tLine.dwItemIndex] = true
	end
	return tList
end

--帮战
function Table_GetCmdHistoryData(  )
	local tList = {}
	local nCount = g_tTable.CmdHistoryData:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.CmdHistoryData:GetRow(i)
		table.insert(tList, tLine)
	end

	return tList
end

function Table_GetQuestRpg(dwQuestID, dwTargetType, dwTargetID, dwOperation)
	local tQuestStringInfo 	= g_tTable.Quests:Search(dwQuestID)
	local pPlayer			= GetClientPlayer()
	if not pPlayer then
		return
	end
	local dwAcceptRpgID 	= tQuestStringInfo.dwAcceptRpgID
	local dwFinishRpgID 	= tQuestStringInfo.dwFinishRpgID
	if dwOperation == 1 then
		if dwAcceptRpgID and dwAcceptRpgID ~= 0 then
			local tLine = g_tTable.QuestRpg:Search(dwAcceptRpgID)
			return tLine, true
		end
	else
		local questInfo = GetQuestInfo(dwQuestID)
		local dwTID, target = nil, nil
		if dwTargetType == TARGET.NPC then
			dwTID, target = questInfo.dwEndNpcTemplateID, GetNpc(dwTargetID)
		elseif dwTargetType == TARGET.DOODAD then
			dwTID, target = questInfo.dwEndDoodadTemplateID, GetDoodad(dwTargetID)
		end
		if target and target.dwTemplateID == dwTID and pPlayer.CanFinishQuest(dwQuestID) == QUEST_RESULT.SUCCESS then
			if dwFinishRpgID and dwFinishRpgID ~= 0 then
				local tLine = g_tTable.QuestRpg:Search(dwFinishRpgID)
				return tLine
			end
		end
	end
end

function Table_GetDLCMapID()
	local tEnterMapList = {}
	local nCount = g_tTable.DLCInfo:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.DLCInfo:GetRow(i)
		tEnterMapList[tLine.dwDLCID] = {}
		local tMapID = ParseIDList(tLine.szDLCMapID)
		for _, v in ipairs(tMapID) do
			table.insert(tEnterMapList[tLine.dwDLCID], v)
		end
	end
	return tEnterMapList
end

function Table_GetDLCInfo(dwDLCID)
	local tLine = g_tTable.DLCInfo:Search(dwDLCID)
	if tLine then
		return tLine
	end
end

local l_tDLCRewardQuestIDs
function Table_GetDLCRewardQuestIDs()
	if not l_tDLCRewardQuestIDs then
		l_tDLCRewardQuestIDs = {}
		local nCount = g_tTable.DLCInfo:GetRowCount()
		for i = 2, nCount do
			local tLine = g_tTable.DLCInfo:GetRow(i)
			l_tDLCRewardQuestIDs[tLine.dwDLCID] =
			{
				tLine.nRewardQuestID1,
				tLine.nRewardQuestID2,
				tLine.nRewardQuestID3,
				tLine.nRewardQuestID4,
			}
		end
	end
	return l_tDLCRewardQuestIDs
end

function Table_GetDLCList()
	local tList = {}
	local nCount = g_tTable.DLCInfo:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.DLCInfo:GetRow(i)
		tList[tLine.dwDLCID] = tLine.szShortName
	end
	return tList
end

function Table_GetDLCName()
	local tList = {}
	local nCount = g_tTable.DLCInfo:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.DLCInfo:GetRow(i)
		tList[tLine.dwDLCID] = tLine.szDLCName
	end
	return tList
end

function Table_GetDLCMainPanelMapInfo(dwDLCID, dwMapID)
	local tLine = g_tTable.DLCMainPanelMapInfo:Search(dwDLCID, dwMapID)
	if tLine then
		return tLine
	end
end

function Table_GetDLCQuestMapInfo(dwDLC, dwMapID)
	local tLine = g_tTable.DLCQuestMapInfo:Search(dwDLC, dwMapID)
	return tLine
end

function Table_GetPLActionBarSkill()
	local tSkillList = {}
	local nCount = g_tTable.PLActionBarSkill:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.PLActionBarSkill:GetRow(i)
		table.insert(tSkillList, tLine)
	end

	local fnSortSkill = function(tLeft, tRight)
		if tLeft.nSortLevel == tRight.nSortLevel then
			return tLeft.nSkillID < tRight.nSkillID
		else
			return tLeft.nSortLevel > tRight.nSortLevel
		end
	end
	table.sort(tSkillList, fnSortSkill)

	return tSkillList
end

function Table_GetDLCAchievementInfo(dwDLCID)
	local tLine = g_tTable.DLCAchievementInfo:Search(dwDLCID)
	return tLine
end

function Table_GetCastleImgInfo()
	local tInfo = {}
	local nCount = g_tTable.CastleImgInfo:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.CastleImgInfo:GetRow(i)
		table.insert(tInfo, tLine)
	end
	return tInfo
end

function Table_GetCampBossInfo()
	local tInfo = {}
	local nCount = g_tTable.CampBossInfo:GetRowCount()
	for i = 1, nCount do
		local tLine = g_tTable.CampBossInfo:GetRow(i)
		tInfo[tLine.dwID] = tLine
	end
	return tInfo
end

function Table_GetCampAuctionInfo()
	local tInfo = {}
	local nCount = g_tTable.CampAuctionInfo:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.CampAuctionInfo:GetRow(i)
		local szKey = tLine.nItemType .. tLine.nItemIndex

		tInfo[szKey] = tLine
	end
	return tInfo
end

function Table_IsActivityPanelQuest(dwQuestID)
	local tLine = g_tTable.Quests:Search(dwQuestID)
	return tLine.bActivityPanel
end

function Table_GetSFXInfo(dwID)
	local tLine = g_tTable.SFXInfo:Search(dwID)
	return tLine
end

function Table_GetSFXPath(dwID)
    local szPath
    local tLine = g_tTable.SFXInfo:Search(dwID)
    if tLine then
        szPath = tLine.szSFXPath
    end
    return szPath
end

function Table_GetChannelInfo(nIndex, nLevel)
	local tLine = g_tTable.ChannelInfo:Search(nIndex, nLevel)
	return tLine
end

function Table_GetCampSkill()
	local tInfo = {}
	local nCount = g_tTable.CampSkill:GetRowCount()
	for i = 1, nCount do
		local tLine = g_tTable.CampSkill:GetRow(i)
		table.insert(tInfo, tLine)
	end
	return tInfo
end

function Table_GetAutoOpenPanelInfo()
	local tInfo = {}
	local nCount = g_tTable.OpenPanelAtEnterGame:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.OpenPanelAtEnterGame:GetRow(i)
		table.insert(tInfo, tLine)
	end

	local fnSortByPriority = function(left, right)
		return left.nPriority > right.nPriority
	end

	table.sort(tInfo, fnSortByPriority)
	return tInfo
end

function Table_IsPVPArenaLiveBan(szServer)
	local nCount = g_tTable.PVPArenaLiveBan:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.PVPArenaLiveBan:GetRow(i)
		if szServer == tLine.szServer then
			return true
		end
	end
	return false
end

function Table_GetReadMailPanelInfo(nForceID)
	local nCount = g_tTable.ReadMailPanelInfo:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.ReadMailPanelInfo:GetRow(i)
		if nForceID == tLine.nForceID then
			return tLine
		end
	end
end

---@return MobaShopItemInfo
function Table_GetMobaShopItemUIInfoByID(dwID)
	return g_tTable.MobaShopItemInfo:Search(dwID)
end

local l_tAllMobaShopItemInfos
---@return MobaShopItemInfo
function Table_GetMobaShopItemInfo(nItemType, nItemID)
	if not l_tAllMobaShopItemInfos then
		l_tAllMobaShopItemInfos = {}
		local nCount = g_tTable.MobaShopItemInfo:GetRowCount()
		for i = 2, nCount do
			local tLine = g_tTable.MobaShopItemInfo:GetRow(i)
			l_tAllMobaShopItemInfos[tLine.nItemType] = l_tAllMobaShopItemInfos[tLine.nItemType] or {}
			l_tAllMobaShopItemInfos[tLine.nItemType][tLine.nItemID] = tLine
		end
	end
	if l_tAllMobaShopItemInfos[nItemType] then
		return l_tAllMobaShopItemInfos[nItemType][nItemID]
	end
end

local l_nPlayerKungfuMountID, l_tMobaShopItemInfos
---@return MobaShopItemInfo[]
function Table_GetMobaShopItemInfos(nKungfuMountID)
	local fnCheckKungfuMountID = function(nKungfuMountID, szKungfuMountID)
		local tKungfuMountID = ParseIDList(szKungfuMountID)
		for _, dwID in ipairs(tKungfuMountID) do
			if dwID == nKungfuMountID then
				return true
			end
		end
		return false
	end

	if l_nPlayerKungfuMountID ~= nKungfuMountID then
		l_nPlayerKungfuMountID = nKungfuMountID
		l_tMobaShopItemInfos = {}
		local nCount = g_tTable.MobaShopItemInfo:GetRowCount()
		for i = 2, nCount do
			local tLine = g_tTable.MobaShopItemInfo:GetRow(i)
			if tLine.szKungfuMountID == "0" or fnCheckKungfuMountID(nKungfuMountID, tLine.szKungfuMountID) then
				l_tMobaShopItemInfos[tLine.nEquipmentSub] = l_tMobaShopItemInfos[tLine.nEquipmentSub] or {}
				table.insert(l_tMobaShopItemInfos[tLine.nEquipmentSub], tLine)
			end
		end
	end
	return l_tMobaShopItemInfos
end

function TableGetMobaShopPrePurchase(nKungfuMountID)
	local tPrePurchase = {}
	local nCount = g_tTable.MobaShopPrePurchase:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.MobaShopPrePurchase:GetRow(i)
		if tLine.nKungfuMountID == nKungfuMountID then
			table.insert(tPrePurchase, tLine)
		end
	end
	return tPrePurchase
end

function Table_GetMobaBattleNonPlayerInfo(nIndex)
	local tLine = g_tTable.MOBABattleNonPlayerInfo:Search(nIndex)
	if not tLine then
		Log("ERROR！(" .. tostring(nIndex) .. ")不是合法的MOBA战场非玩家对象index！")
		tLine = g_tTable.MOBABattleNonPlayerInfo:Search(0)
	end
	return tLine
end

function Table_GetMobaBattleVoiceFilePath(szID)
	local nRowCount = g_tTable.MOBABattleVoice:GetRowCount()
	for i = 2, nRowCount do
		local tLine = g_tTable.MOBABattleVoice:GetRow(i)
		if tLine.szID == szID then
			return tLine.szSoundFilePath
		end
	end
	Log("ERROR！(" .. tostring(szID) .. ")不是合法的MOBA战场语音文件ID！")
	return ""
end

function Table_GetBattleMarkState()
	local tTable = {}
	local nCount = g_tTable.BattleMarkState:GetRowCount()
	for i = 1, nCount do
		local tLine = g_tTable.BattleMarkState:GetRow(i)
		tTable[tLine.nID] = tLine
	end
	return tTable
end

function Table_GetWulinShenghuiDuizhenNpcInfo(dwNpcID)
	local t = g_tTable.WulinShenghuiDuizhenTip
	local nCount = t:GetRowCount()
	for i = 2, nCount do
		local tLine = t:GetRow(i)
		if tLine.dwNpcID == dwNpcID then
			local tNpcInfo = {}
			tNpcInfo.szName = tLine.szName
			tNpcInfo.szNickname = tLine.szNickname
			tNpcInfo.szBasicTip = tLine.szBasicTip
			tNpcInfo.aTipList = {}
			for j = 2, 5 do
				local szTip = tLine["szTipPhase" .. j]
				if szTip ~= "" then
					table.insert(tNpcInfo.aTipList, szTip)
				else
					break
				end
			end

			return tNpcInfo
		end
	end

	return nil
end

function Table_GetMentorPanelInfo()
	local tRes = {}
	tRes.tActivityMsg = {}
	tRes.tFindTeacherMsg = {}
	tRes.tFindAppMsg = {}
	tRes.tTeacherTypeIndex = {}
	tRes.tAppTypeIndex = {}
	local t = g_tTable.MentorPanelInfo
	local nCount = t:GetRowCount()
	for i = 1, nCount do
		local tLine = t:GetRow(i)
		if tLine.nType == 0 then
			local szLabelType = tLine.szLabelType
			if not tRes.tFindTeacherMsg[szLabelType] then
				tRes.tFindTeacherMsg[szLabelType] = {}
				table.insert(tRes.tTeacherTypeIndex, szLabelType)
			end
			table.insert(tRes.tFindTeacherMsg[szLabelType], tLine.szMsg)
		elseif tLine.nType == 4 then
			local szLabelType = tLine.szLabelType
			if not tRes.tFindAppMsg[szLabelType] then
				tRes.tFindAppMsg[szLabelType] = {}
				table.insert(tRes.tAppTypeIndex, szLabelType)
			end
			table.insert(tRes.tFindAppMsg[szLabelType], tLine.szMsg)
		else
			if not tRes.tActivityMsg[tLine.dwActivityID] then
				tRes.tActivityMsg[tLine.dwActivityID] = {}
			end
			tRes.tActivityMsg[tLine.dwActivityID][tLine.nType] = tLine.szMsg
		end
	end
	return tRes
end

function Table_GetMentorPanelLuckyMeet()
	local tRes = {}
	local t = g_tTable.MentorPanelLuckyMeet
	local nCount = t:GetRowCount()
	for i = 2, nCount do
		local tLine = t:GetRow(i)
		tRes[tLine.dwID] = tLine
	end
	return tRes
end

function Table_GetMentorPanelValueGift()
	local tRes = {}
	local t = g_tTable.MentorPanelValueGift
	local nCount = t:GetRowCount()
	for i = 2, nCount do
		local tLine = t:GetRow(i)
		tRes[tLine.dwID] = tLine
	end
	return tRes
end

function Table_GetSimpleTipInfo()
	local tRes = {}

	local t = g_tTable.SimpleTip
	local nCount = t:GetRowCount()
	for i = 2, nCount do
		local tLine = t:GetRow(i)
		tRes[tLine.dwID] = tLine
	end

	return tRes
end

local tTempCustomBuffList = {}
function Table_GetCustomBuffList(nID)
	if tTempCustomBuffList[nID] then
		return tTempCustomBuffList[nID]
	end

	local tLine = g_tTable.CustomBuffList:Search(nID)
	if tLine then
		local tBuffList, tSplit = {}, ParseIDList(tLine.szBuffID)
		for i, dwBuffID in ipairs(tSplit) do
			tBuffList[i] = dwBuffID
		end
		tTempCustomBuffList[nID] = tBuffList
		return tBuffList
	end
end

function Table_GetVagabondStartInfo(nID)
	local tLine = g_tTable.VagabondStartInfo:Search(nID)
	if tLine then
		tLine.tLimit = SplitString(tLine.szLimit, ';')
		tLine.szLimit = nil
		local tAward = SplitString(tLine.szAward, '|')
		tLine.tAward = {}
		tLine.szAward = nil
		for _, szAward in ipairs(tAward) do
			local tResult, tAwardArg = SplitString(szAward, ';'), {}
			for _, szArg in ipairs(tResult) do
				table.insert(tAwardArg, tonumber(szArg))
			end
			table.insert(tLine.tAward, tAwardArg)
		end
		return tLine
	end
end

function Table_GetVagabondCrossMapInfo(nID)
	local tLine = g_tTable.VagabondCrossMapInfo:Search(nID)
	if tLine then
		return tLine
	end
end

function Table_GetVagabondCrossMapTip(nID)
	local tLine = g_tTable.VagabondCrossMapTip:Search(nID)
	if tLine then
		return tLine
	end
end

function Table_GetVagabondCraftInfo(nClassificationID)
	local tResult = {}
	local nCount = g_tTable.VagabondCraftInfo:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.VagabondCraftInfo:GetRow(i)
		if tLine.nClassificationID == nClassificationID then
			table.insert(tResult, tLine)
		end
	end
	return tResult
end

function Table_GetPanelForbidMap(szPanelName)
	local nCount = g_tTable.PanelForbidMap:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.PanelForbidMap:GetRow(i)
		if tLine.szPanelName == szPanelName then
			return tLine.szForbidMap
		end
	end
end

function Table_IsInForbidMap(szPanelName, dwMapID)
	local szForbidMap = Table_GetPanelForbidMap(szPanelName)
	if not szForbidMap then
		return
	end
	local tForbidMap = ParseIDList(szForbidMap)
	for k, v in ipairs(tForbidMap) do
		if dwMapID == v then
			return true
		end
	end
end

function Table_GetPanelFilter()
	local tResult = {}
	local nCount = g_tTable.PanelFilter:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.PanelFilter:GetRow(i)
		local nType = tLine.nType
		if tLine.nOrder > 0 and nType > 0 then
			if not tResult[nType] then
				tResult[nType] = {}
			end
			table.insert(tResult[nType], tLine)
		end
	end

	local fnSortByOrder = function(tLeft, tRight)
		return tLeft.nOrder < tRight.nOrder
	end
	for _, v in pairs(tResult) do
		table.sort(v, fnSortByOrder)
	end

	return tResult
end

function Table_GetHLIdentity(dwID)
	local nCount = g_tTable.HLIdentity:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.HLIdentity:GetRow(i)
		if tLine and tLine.dwID == dwID then
			return tLine
		end
	end
end

function Table_GetAllHLIdentity()
	local tRes = {}
	local nCount = g_tTable.HLIdentity:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.HLIdentity:GetRow(i)
		if tLine then
			table.insert(tRes, tLine)
		end
	end
	return tRes
end

function Table_GetAllHLIdentityPriorityType()
	local tRes = {}
	local nCount = g_tTable.HLIdentityPriorityType:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.HLIdentityPriorityType:GetRow(i)
		if tLine then
			table.insert(tRes, tLine)
		end
	end
	return tRes
end

function Table_GetAllHLIdentityPriority()
	local tRes = {}
	local nCount = g_tTable.HLIdentityPriority:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.HLIdentityPriority:GetRow(i)
		if tLine then
			table.insert(tRes, tLine)
		end
	end
	return tRes
end

function Table_GetHLIdentityPriorityByID(dwID)
	local nCount = g_tTable.HLIdentityPriority:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.HLIdentityPriority:GetRow(i)
		if tLine and tLine.dwID == dwID then
			return tLine
		end
	end
end

function Table_GetHLRewardType(nType)
	local nCount = g_tTable.IdentityRewardType:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.IdentityRewardType:GetRow(i)
		if tLine and tLine.dwID == nType then
			return tLine
		end
	end
end

function Table_GetAllHLReward(nType)
	local tRes = {}
	local nCount = g_tTable.IdentityReward:GetRowCount()
	for i = 1, nCount do
		local tLine = g_tTable.IdentityReward:GetRow(i)
		if tLine and tLine.nType == nType then
			table.insert(tRes, tLine)
		end
	end
	return tRes
end

function Table_GetAllHLTask()
	local tRes = {}
	local nCount = g_tTable.HLTask:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.HLTask:GetRow(i)
		if tLine then
			table.insert(tRes, tLine)
		end
	end
	return tRes
end

function Table_GetPerfumeItemInfo(dwTabType, dwIndex)
	local tLine = g_tTable.PerfumeItemList:Search(dwTabType, dwIndex)
	return tLine
end

function Table_GetPerfumeItemList()
	local tInfo = {}
	local nCount = g_tTable.PerfumeItemList:GetRowCount()
	for i = 1, nCount do
		local tLine = g_tTable.PerfumeItemList:GetRow(i)
		table.insert(tInfo, tLine)
	end
	return tInfo
end

function Table_GetAllHLCookFood()
	local tRes = {}
	local nCount = g_tTable.HLCookFood:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.HLCookFood:GetRow(i)
		if tLine then
			table.insert(tRes, tLine)
		end
	end
	return tRes
end

function Table_GetHLCookFood(dwID)
	local nCount = g_tTable.HLCookFood:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.HLCookFood:GetRow(i)
		if tLine and tLine.dwID == dwID then
			return tLine
		end
	end
end

function Table_GetAllFishInfo()
	local tRes = {}
	local nCount = g_tTable.GetFish:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.GetFish:GetRow(i)
		if tLine then
			table.insert(tRes, tLine)
		end
	end
	return tRes
end

function Table_GetFishInfo(dwID)
	local nCount = g_tTable.GetFish:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.GetFish:GetRow(i)
		if tLine and tLine.dwID == dwID then
			return tLine
		end
	end
end

function Table_GetDodgeSkill(dwKungfuID)
	local nCount = g_tTable.DodgeActionBar:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.DodgeActionBar:GetRow(i)
		if tLine.dwKungfuID == dwKungfuID then
			local tSkillID = {}
			for i = 1, DODGE_SKILL_COUNT do
				local szKey = "dwSkillID" .. i
				if tLine[szKey] > 0 then
					table.insert(tSkillID, tLine[szKey])
				end
			end
			return tSkillID
		end
	end
	return nil
end

function Table_GetVideoSettingScene(nLevel)
	local tLine = g_tTable.VideoSettingScene:Search(nLevel)
	return tLine
end

function Table_GetVideoSettingSceneDefault(nLevel)
	local tDefault = VideoBase.GetLevelSettingEX(nLevel)
	local tLine = {}
	for k, v in ipairs(tTableFile["VideoSettingScene"].Title) do
		if v.t ~= "dwID" then
			tLine[v.t] = tDefault[v.t]
		end
	end
	return tLine
end

function Table_GetAssassinationTaskScrollInfo(nID)
	local tLine = g_tTable.AssassinationTaskScroll:Search(nID)
	return tLine
end

function Table_GetCubEmotion(dwEmotion)
	local tLine = g_tTable.CubEmotion:Search(dwEmotion)
	return tLine
end

function Table_GetDomesticatePetModel(dwID)
	local tLine = g_tTable.DomesticatePetModel:Search(dwID)
	return tLine
end

function Table_IsDomesticatePet(dwID)
	local tLine = g_tTable.DomesticatePetModel:Search(dwID)
	if tLine then
		return true
	end
	return false
end

function Table_GetLimitedSale(dwID)
	local tLine = g_tTable.LimitedSale:Search(dwID)
	if tLine then
		local tszGoods = SplitString(tLine.szGoods, ";")
		local nTotalPrice, nTotalOriginalPrice = 0, 0
		local tGoods = {}
		for k, szGood in ipairs(tszGoods) do
			local t 			= SplitString(szGood, ":")
			local eGoodsType 	= tonumber(t[1])
			local dwGoodsID  	= tonumber(t[2])
			table.insert(tGoods, {eGoodsType = eGoodsType, dwGoodsID = dwGoodsID})
		end
		tLine.tGoods = tGoods
		return tLine
	end
end

---- 特殊道具相关
--- szType 可取的值： "Material"
function Table_IsSpecialItem(dwTabType, dwTabIndex, szType)
	szType = szType or "Material"
	local tLine = g_tTable.SpecialItem:LinearSearch({dwTabType=dwTabType, dwTabIndex=dwTabIndex})
	if tLine then
		if szType == "Material" then
			return tLine.bForLootMaterial
		end
	end
	return false
end

---- 消息频道默认字体
---- szPlatform: "PC"/"Phone"
function Table_GetMsgChannelDefaultFontsForPlatform()
	local tDefaultFonts = {}

	local nCount = g_tTable.MsgChannelDefaultFont:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.MsgChannelDefaultFont:GetRow(i)
		local t = {}
		local tRGB
		t.nFont = tLine.nFont
		tRGB = ParsePointList(tLine.szRGB)
		t.r = tRGB[1] or 0
		t.g = tRGB[2] or 0
		t.b = tRGB[3] or 0
		tDefaultFonts[tLine.szChannel] = t
	end
	return tDefaultFonts
end

--卷轴展示相关
function Table_GetScrollDisplay(dwImgID)
	local nCount = g_tTable.ScrollDisplay:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.ScrollDisplay:GetRow(i)
		if tLine.dwImgID == dwImgID then
			return  tLine.szImgPath
		end
	end
	return
end

function Table_GetScrollBackground(dwBGID)
	local nCount = g_tTable.ScrollBackground:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.ScrollBackground:GetRow(i)
		if tLine.dwBGID == dwBGID then
			return tLine
		end
	end
	return
end


--- BEGIN: 家园相关

--- 具体数据获取参见 HomelandBuilding_FurnitureData.lua
function Table_GetTableHomelandFurnitureCatg()
	return g_tTable.HomelandFurnitureCatg
end


function Table_GetHomelandAllBlueprints(bOnlyIndex)
	local t = g_tTable.HomelandBlueprints
	local aResult = {}
	local nRowCount = t:GetRowCount()
	for i = 2, nRowCount do
		local tLine = t:GetRow(i)
		if bOnlyIndex then
			table.insert(aResult, tLine.nIndex)
		else
			table.insert(aResult, tLine)
		end
	end
	return aResult
end

function Table_GetHomelandBlueprintInfoByIndex(nIndex)
	local t = g_tTable.HomelandBlueprints:Search(nIndex)
	return t
end

-- 具体数据获取参见 HomelandBuilding_FurnitureData.lua
function Table_GetTableHomelandFurnitureInfo()
	return g_tTable.HomelandFurnitureInfo
end

-- 具体数据获取参见 HomelandBuilding_FurnitureData.lua
function Table_GetHomelandInteractModelList()
	return g_tTable.HomelandInteractModel
end

function Table_GetFurnitureAddInfo(dwID)
	local tLine = g_tTable.FurnitureAddInfo:Search(dwID)
	if tLine then
		return tLine
	end
	if IsDebugClient() then
		Log("【ERROR】 Can't get furniture add info for furniture (id: " .. tostring(dwID) .. ")")
		return g_tTable.FurnitureAddInfo:GetRow(2)
	end
end

-- 具体数据获取参见 FurnitureSetCollect.lua
function Table_GetAllFurnitureSetInfo()
	return g_tTable.FurnitureSetInfo
end

function Table_GetFurnitureSetInfoByID(dwSetID)
	local tLine = g_tTable.FurnitureSetInfo:LinearSearch({dwSetID=dwSetID})
	if tLine then
		return tLine
	end
	return nil
end

-- 具体数据获取参见 FurnitureSetCollect.lua
function Table_GetAllFurnitureSetCollectPointsLevelInfo()
	return g_tTable.FurnitureSetCollectPointsLevel
end

function Table_GetFurnitureSetCollectPointsLevelInfo(nLevel)
	local tLine = g_tTable.FurnitureSetCollectPointsLevel:Search(nLevel)
	if tLine then
		return tLine
	end
	return nil
end

function Table_GetDlcInfoForFurnitureSet(nDlcID)
	local tLine = g_tTable.DlcForFurnitureSet:Search(nDlcID)
	if tLine then
		return tLine
	end
	return nil
end

function Table_GetMoreDlcInfoForFurnitureSet()
	local tLine = g_tTable.DlcForFurnitureSet:GetRow(1)
	return tLine
end

function Table_GetLandInfo(nMapID)
	local tLandInfo = {}
	local nCount = g_tTable.LandInfo:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.LandInfo:GetRow(i)
		if tLine.nMapID == nMapID then
			tLandInfo[tLine.nLandIndex] = tLine
		end
	end
	return tLandInfo
end

function Table_GetMapLandInfo(nMapID, nLandIndex)
	local tLine = g_tTable.LandInfo:Search(nMapID, nLandIndex)
	if tLine then
		return tLine
	end
end

local tHomelandMapList
function Table_GetHomelandMapList()
	if tHomelandMapList then
		return tHomelandMapList
	end

	local tMapIDFlag = {}
	local nCount = g_tTable.LandInfo:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.LandInfo:GetRow(i)
		tMapIDFlag[tLine.nMapID] = true
	end
	tHomelandMapList = {}
	for nMapID, _ in pairs(tMapIDFlag) do
		if IsHomelandCommunityMap(nMapID) then
			table.insert(tHomelandMapList, nMapID)
		end
	end
	return tHomelandMapList
end

local tCommunityMapList
function Table_GetCommunityMapList()
	if tCommunityMapList then
		return tCommunityMapList
	end

	local tMapIDFlag = {}
	local pHlMgr = GetHomelandMgr()
	local nCount = g_tTable.LandInfo:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.LandInfo:GetRow(i)
		tMapIDFlag[tLine.nMapID] = true
	end
	tCommunityMapList = {}
	for nMapID, _ in pairs(tMapIDFlag) do
		if HomelandData.IsHomelandCommunityMap(nMapID) and not pHlMgr.IsPrivateHomeMap(nMapID) then
			table.insert(tCommunityMapList, nMapID)
		end
	end
	return tCommunityMapList
end

local _tHomelandMiniGameCache = {}
function Table_GetTableHomelandMiniGameInfo(nGameID, nState)
	if _tHomelandMiniGameCache[nGameID] and _tHomelandMiniGameCache[nGameID][nState] then
		return _tHomelandMiniGameCache[nGameID][nState]
	end

	local nCount = g_tTable.HomelandMiniGame:GetRowCount()
	local tTemp = {}
	for i = 2, nCount do
		local tLine = g_tTable.HomelandMiniGame:GetRow(i)
		if nGameID == tLine.nGameID and nState == tLine.nState then
			if not _tHomelandMiniGameCache[nGameID] then
				_tHomelandMiniGameCache[nGameID] = {}
			end
			tTemp.nGameID = tLine.nGameID
			tTemp.nState = tLine.nState
			tTemp.szTitle = tLine.szTitle
			tTemp.bOpenView = tLine.bOpenView
			tTemp.tModuleID = {}
			for k, v in pairs(tLine.szModuleID:split(";", true)) do
				table.insert(tTemp.tModuleID, tonumber(v))
			end

			tTemp.tBtnID = {}
			for k, v in pairs(tLine.szBtnID:split(";", true)) do
				table.insert(tTemp.tBtnID, tonumber(v))
			end

			tTemp.tDisableBtn = {} -- 1
			for k, v in pairs(tLine.szDisableBtn:split(";", true)) do
				tTemp.tDisableBtn[tonumber(v)] = true
			end

			tTemp.nCountdownType = tLine.nCountdownType
			tTemp.szCountdownTip = tLine.szCountdownTip
			tTemp.nProgressMin = tLine.nProgressMin
			tTemp.nProgressMax = tLine.nProgressMax
			tTemp.bSaveHistory = tLine.bSaveHistory
			tTemp.szTip = tLine.szTip
			_tHomelandMiniGameCache[nGameID][nState] = tTemp
			return tTemp
		end
	end
end

function Table_GetTableHomelandMiniGameMode(nModuleID)
	local tLine = g_tTable.HomelandMiniGameMode:Search(nModuleID)
	if tLine then
		local tTemp = {}
		tTemp.nID =  tLine.nID
		tTemp.szName = tLine.szName
		tTemp.tSlotID = {}
		for k, v in pairs(tLine.szSlotID:split(";", true)) do
			table.insert(tTemp.tSlotID, tonumber(v))
		end
		return tTemp
	end
end

function Table_GetTableHomelandMiniGameBtn(nBtnID)
	local tLine = g_tTable.HomelandMiniGameBtn:Search(nBtnID)
	if tLine then
		local tTemp = clone(tLine)
		tTemp.aConditionSlots = {}
		for k, v in pairs(tTemp.szCondition:split(";", true)) do
			table.insert(tTemp.aConditionSlots, tonumber(v))
		end
		tTemp.szCondition = nil
		if tTemp.szShortcutKey == "" then
			tTemp.szShortcutKey = nil
		end

		return tTemp
	end
end

function Table_GetTableHomelandMiniGameSlot(nID)
	local tLine = g_tTable.HomelandMiniGameSlot:Search(nID)
	if tLine then
		local tTemp = {}
		tTemp.nID =  tLine.nID
		tTemp.nType = tLine.nType
		tTemp.nFilterID = tLine.nFilterID
		tTemp.szName = tLine.szName
		tTemp.nItemMinNum = tLine.nItemMinNum
		tTemp.nItemMaxNum = tLine.nItemMaxNum
		tTemp.szTip = tLine.szTip
		tTemp.dwClassType = tLine.dwClassType
		tTemp.tItemType = {}
		for k, v in pairs(tLine.szItemType:split(";", true)) do
			local nItemType = tonumber(v)
			tTemp.tItemType[nItemType] = true
		end
		return tTemp
	end
end

local _tHomelandUpgradeInfoCache
function Table_GetTableHomelandUpgradeInfos()
	if _tHomelandUpgradeInfoCache then
		return _tHomelandUpgradeInfoCache
	end
	_tHomelandUpgradeInfoCache = {}
	local nCount = g_tTable.HomelandUpgradeInfo:GetRowCount()
	local tLine = nil
	for i = 1, nCount do
		tLine = g_tTable.HomelandUpgradeInfo:GetRow(i)
		if tLine then
			_tHomelandUpgradeInfoCache[tLine.nLevel] = tLine
		end
	end
	return _tHomelandUpgradeInfoCache
end

function Table_GetTableHomelandIcon(nLevel)
	local tLine = g_tTable.HomelandIcon:Search(nLevel)
	if tLine then
		return tLine
	end
end

function Table_GetHomelandEnvironment(nTime, nWeather)
	local tLine = g_tTable.HomelandWeather:Search(nTime, nWeather)
	if tLine then
		return tLine.szEnvironment
	end
end

function Table_GetGroundArea()
	local tResult = {}
	local nCount = g_tTable.GroundArea:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.GroundArea:GetRow(i)
		table.insert(tResult, tLine)
	end
	local fnSortByOrder = function(left, right)
		return left.nOrder < right.nOrder
	end
	table.sort(tResult, fnSortByOrder)
	return tResult
end

function Table_GetTableHouseKeeper()
	local nCount = g_tTable.HouseKeeper:GetRowCount()
	local tTemp = {}
	for i = 1, nCount do
		local tLine = g_tTable.HouseKeeper:GetRow(i)
		tTemp[tLine.dwID] = tLine
	end

	return tTemp
end

function Table_GetTableHouseKeeperSkill()
	local nCount = g_tTable.HouseKeeperSkill:GetRowCount()
	local tTemp = {}
	for i = 2, nCount do
		local tLine = g_tTable.HouseKeeperSkill:GetRow(i)
		tTemp[tLine.dwID] = tLine
	end

	return tTemp
end

local _tMahjongTileInfoCache = {}
function Table_GetMahjongTileInfo(nSkinID, szDirection, nType, nNumber)
	if _tMahjongTileInfoCache[nSkinID] and _tMahjongTileInfoCache[nSkinID][szDirection] and
		_tMahjongTileInfoCache[nSkinID][szDirection][nType] and
		_tMahjongTileInfoCache[nSkinID][szDirection][nType][nNumber] then
		return _tMahjongTileInfoCache[nSkinID][szDirection][nType][nNumber]
	end

	local nCount = g_tTable.MahjongTileInfo:GetRowCount()
	for i = 1, nCount do
		local tLine = g_tTable.MahjongTileInfo:GetRow(i)
		if tLine then
			if not _tMahjongTileInfoCache[tLine.nSkinID] then
				_tMahjongTileInfoCache[tLine.nSkinID] = {}
			end
			if not _tMahjongTileInfoCache[tLine.nSkinID][tLine.szDirection] then
				_tMahjongTileInfoCache[tLine.nSkinID][tLine.szDirection] = {}
			end
			if not _tMahjongTileInfoCache[tLine.nSkinID][tLine.szDirection][tLine.nType] then
				_tMahjongTileInfoCache[tLine.nSkinID][tLine.szDirection][tLine.nType] = {}
			end
			if not _tMahjongTileInfoCache[tLine.nSkinID][tLine.szDirection][tLine.nType][tLine.nNumber] then
				_tMahjongTileInfoCache[tLine.nSkinID][tLine.szDirection][tLine.nType][tLine.nNumber] = {}
			end
			_tMahjongTileInfoCache[tLine.nSkinID][tLine.szDirection][tLine.nType][tLine.nNumber] = tLine
		end
	end
	return _tMahjongTileInfoCache[nSkinID][szDirection][nType][nNumber]
end

function Table_GetAccountFriendAvatar(nID)
	local tLine = g_tTable.AccountFriendAvatar:Search(nID)
	return tLine
end

function Table_GetMahjongTitleInfo(nSkinID, nID)
	local nCount = g_tTable.MahjongTitleInfo:GetRowCount()
	for i = 1, nCount do
		local tLine = g_tTable.MahjongTitleInfo:GetRow(i)
		if tLine.nSkinID == nSkinID and tLine.nID == nID then
			return tLine
		end
	end
end

function Table_GetMahjongSkinID(nSkinID, szType)
	local nCount = g_tTable.MahjongSkinInfo:GetRowCount()
	for i = 1, nCount do
		local tLine = g_tTable.MahjongSkinInfo:GetRow(i)
		if tLine.nSkinID == nSkinID and tLine.szType == szType then
			return tLine.nMobileSkinID
		end
	end
	assert(false, "未找到nSkinID为" .. nSkinID .. "szTyp为" .. szType .. "的皮肤")
end

local _tMahjongDiscardPosCache = {}
function Table_GetMahjongDiscardPos(szDirection, nDiscardIndex)
	if _tMahjongDiscardPosCache[szDirection] and _tMahjongDiscardPosCache[szDirection][nDiscardIndex] then
		return _tMahjongDiscardPosCache[szDirection][nDiscardIndex]
	end

	local nCount = g_tTable.MahjongDiscardPos:GetRowCount()
	for i = 1, nCount do
		local tLine = g_tTable.MahjongDiscardPos:GetRow(i)
		if tLine then
			if not _tMahjongDiscardPosCache[tLine.szDirection] then
				_tMahjongDiscardPosCache[tLine.szDirection] = {[tLine.nDiscardIndex] = {}}
			end
			_tMahjongDiscardPosCache[tLine.szDirection][tLine.nDiscardIndex] = tLine.nPosIndex
		end
	end
	return _tMahjongDiscardPosCache[szDirection][nDiscardIndex]
end

function Table_GetMahjongHintInfo()
	local nCount = g_tTable.MahjongHintInfo:GetRowCount()
	local t = {}
	for i = 2, nCount do
		local tLine = g_tTable.MahjongHintInfo:GetRow(i)
		table.insert(t, tLine)
	end
	return t
end

function Table_GetMahjongSkinIniPath(nSkinID, szType)
	local nCount = g_tTable.MahjongSkinInfo:GetRowCount()
	for i = 1, nCount do
		local tLine = g_tTable.MahjongSkinInfo:GetRow(i)
		if tLine.nSkinID == nSkinID and tLine.szType == szType then
			return tLine.szIniPath
		end
	end
	assert(false, "未找到nSkinID为" .. nSkinID .. "szTyp为" .. szType .. "的皮肤")
end

function Table_GetHomelandWelfareInfo()
	local nCount = g_tTable.HomelandWelfare:GetRowCount()
	local t = {}
	for i = 2, nCount do
		local tLine = g_tTable.HomelandWelfare:GetRow(i)
		table.insert(t, tLine)
	end

	return t
end

function Table_GetHomelandGameplayInfo()
	local nCount = g_tTable.HomelandGameplay:GetRowCount()
	local t = {}
	for i = 2, nCount do
		local tLine = g_tTable.HomelandGameplay:GetRow(i)
		table.insert(t, tLine)
	end

	return t
end

function Table_GetHomelandLockerInfo()
	local nCount = g_tTable.HomelandLocker:GetRowCount()
	local t = {}
	for i = 2, nCount do
		local tLine = g_tTable.HomelandLocker:GetRow(i)
		table.insert(t, tLine)
	end
	return t
end

function Table_GetHomelandLockerInfoByItem(dwItemID)
	local nCount = g_tTable.HomelandLocker:GetRowCount()
	local t = {}
	for i = 2, nCount do
		local tLine = g_tTable.HomelandLocker:GetRow(i)
		if dwItemID and dwItemID == tLine.dwItemID then
			return tLine
		end
	end
end

function Table_GetHomelandLockerInfoByClass(dwClassType)
	local nCount = g_tTable.HomelandLocker:GetRowCount()
	local t = {}
	for i = 2, nCount do
		local tLine = g_tTable.HomelandLocker:GetRow(i)
		if dwClassType and dwClassType == tLine.dwClassType then
			table.insert(t, tLine)
		end
	end
	return t
end

function Table_GetAllHLOrder()
	local tRes = {}
	local nCount = g_tTable.HLOrder:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.HLOrder:GetRow(i)
		if tLine then
			table.insert(tRes, tLine)
		end
	end
	return tRes
end

function Table_GetHLOrderByType(nType)
	local tRes = {}
	local nCount = g_tTable.HLOrder:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.HLOrder:GetRow(i)
		if tLine and tLine.nType == nType then
			table.insert(tRes, tLine)
		end
	end
	return tRes
end

function Table_GetPrivateHomeSkin(nMapID, dwSkinID)
	local tLine = g_tTable.PrivateHomeSkin:Search(nMapID, dwSkinID)
	if tLine then
		return tLine
	end
end

function Table_GetPrivateHomeSkinCfg(nMapID, dwSkinID, nArea)
	local tLine = g_tTable.PrivateHomeSkinConfig:Search(nMapID, dwSkinID, nArea)
	if tLine then
		return tLine
	end
end

function Table_GetPrivateHomeSkinList(nMapID)
	local tSkinList = {}
	local nCount = g_tTable.PrivateHomeSkin:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.PrivateHomeSkin:GetRow(i)
		if tLine.nMapID == nMapID then
			-- tSkinList[tLine.dwSkinID] = tLine
			table.insert(tSkinList, tLine)
		end
	end
	return tSkinList
end

function Table_GetPrivateHomeArea(nMapID, nLandIndex, nAreaIndex)
	local tLine = g_tTable.PrivateHomeAreas:Search(nMapID, nLandIndex, nAreaIndex)
	if tLine then
		return tLine
	end
end
--- END: 家园相关

local tFullScreenSFXInfo = {}
function Table_GetFullScreenSFXInfo()
	local nCount = g_tTable.FullScreenSFXInfo:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.FullScreenSFXInfo:GetRow(i)
		local Key = tonumber(tLine.szKey) or tLine.szKey
		local szFile, szFileMobile = tLine.szPath, tLine.szMobilePath
		if szFile == "" and szFileMobile == "" then
			szFile, szFileMobile = Table_GetPath(tLine.szSFXPath)
		end
		tFullScreenSFXInfo[Key] = {
			Name = tLine.szSFXName,
			File = szFile,
			FileMobile = szFileMobile,
			Translation = {x = tLine.nX, y = tLine.nY},
			Scaling = tLine.fScaling,
			nLayer = tLine.nLayer,
		}
	end
	return tFullScreenSFXInfo
end

function Table_GetSituationMapInfoById(dwId)
	local nCount = g_tTable.SituationMapInfo:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.SituationMapInfo:GetRow(i)
		if tLine.dwId == dwId then
			return tLine
		end
	end
	return {}
end

function Table_GetCopyMapTrackPoints(dwMapID)
	local nCount = g_tTable.WorldMapCopy:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.WorldMapCopy:GetRow(i)
		if tLine.dwMapID == dwMapID then
			return tLine.dwParentMapID, tLine.nPosX, tLine.nPosY, tLine.nPosZ
		end

		local tOther = StringParse_PointList(tLine.szOtherMapID)

		for _, nOtherMapID in pairs(tOther) do
			if nOtherMapID == dwMapID then
				return tLine.dwParentMapID, tLine.nPosX, tLine.nPosY, tLine.nPosZ
			end
		end
	end
end

function Table_GetMinimapHover(dwHoverID)
	local tLine = g_tTable.Minimap_Hover:Search(dwHoverID)
	return tLine
end

function Table_GetToyBoxCount()
	local t = g_tTable.ToyBox
	local nCount = t:GetRowCount()
	return nCount - 1
end

function Table_GetToyBox(dwID)
	local tLine = g_tTable.ToyBox:Search(dwID)
	return tLine
end

function Table_GetToyBoxInfo()
	local tRes = {}

	local nCount = g_tTable.ToyBox:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.ToyBox:GetRow(i)
		tRes[tLine.dwID] = tLine
	end

	return tRes
end

function Table_GetToyBoxByItem(dwItemIndex)
	local tLine = g_tTable.ToyBox:LinearSearch({dwItemIndex = dwItemIndex})
	return tLine
end

function Table_IsProtectSkill(dwSkillID)
	local tLine = g_tTable.SkillProtect:Search(dwSkillID)
	return tLine
end

function Table_GetSkillMsgInfo(dwID)
	local tLine = g_tTable.SkillMsg:Search(dwID)
	return tLine
end

function Table_GetNPCInfo(dwID)
	local tLine = g_tTable.NpcInfo:Search(dwID)
	return tLine
end

function Table_GetNPCEnchantInfo(dwEnchantID)
	local tLine = g_tTable.NPCEnchantInfo:Search(dwEnchantID)
	return tLine
end

function Table_GetButlerNPCInfo(dwID)
	local tLine = g_tTable.ButlerNPCInfo:Search(dwID)
	return tLine
end

function Table_GetSeasonFurnitureInfo(nIndex)
	local tLine = g_tTable.SeasonFurnitureInfo:Search(nIndex)
	return tLine
end

function Table_GetSeasonFurnitureActivity(nIndex)
	local tLine = g_tTable.SeasonFurnitureActivity:Search(nIndex)
	return tLine
end

function Table_GetSeasonFurnitureAttribute(nAttributeID)
	local tLine = g_tTable.SeasonFurnitureAttribute:Search(nAttributeID)
	return tLine
end

function Table_GetBrightMarkIcon(dwID)
	local tLine = g_tTable.BrightMarkIcon:Search(dwID)
	return tLine
end

function Table_IsSpecialNeedViewEquipMap(dwMapID)
	if not dwMapID then
		return
	end
	local bIsNeedView = false
	local nCount = g_tTable.SpecialNeedViewEquipMap:GetRowCount()
	for i = 1, nCount do
		local tLine = g_tTable.SpecialNeedViewEquipMap:GetRow(i)
		local dwNeedViewMapID = tLine.dwMapID
		if dwNeedViewMapID == dwMapID then
			bIsNeedView = true
		end
	end
	return bIsNeedView
end

function Table_GetPointsDrawAllPoolInfo()
	local nCount = g_tTable.PointsDrawPool:GetRowCount()
	local tTab = {}
	for i = 2, nCount do
		local tLine = g_tTable.PointsDrawPool:GetRow(i)
		table.insert(tTab, tLine)
	end
	return tTab
end

function Table_GetPointsDrawPoolInfo(nIndex)
	local tLine = g_tTable.PointsDrawPool:Search(nIndex)
	return tLine
end

function Table_GetPointsDrawPreviewGift(nPoolIndex)
    local tRes = {}
    local nCount = g_tTable.PointsDrawPreviewGift:GetRowCount()
    for i = 2, nCount do
        local tLine = g_tTable.PointsDrawPreviewGift:GetRow(i)
        if tLine.nPoolIndex == nPoolIndex then
            table.insert(tRes, tLine)
        end
    end
	return tRes
end

function Table_GetPointsDrawGiftInfo(nPoolIndex)
    local tCommonGiftList = {}
    local tPoolGiftList = {}
    local nCount = g_tTable.PointsDrawGiftInfo:GetRowCount()
    for i = 2, nCount do
        local tLine = g_tTable.PointsDrawGiftInfo:GetRow(i)
        if tLine.nPoolIndex == 0 then
            table.insert(tCommonGiftList, tLine)
        elseif tLine.nPoolIndex == nPoolIndex then
            table.insert(tPoolGiftList, tLine)
        end
    end
    if #tPoolGiftList > 0 then
        return tPoolGiftList
    end
	return tCommonGiftList
end

function Table_GetFriendSkin(dwID)
	local tLine = g_tTable.FriendSkin:Search(dwID)
	return tLine
end

function Table_GetAllFriendSkin()
	local nCount = g_tTable.FriendSkin:GetRowCount()
	local tTab = {}
	for i = 1, nCount do
		local tLine = g_tTable.FriendSkin:GetRow(i)
		table.insert(tTab, tLine)
	end
	return tTab
end

function Table_GetPZZBuildingInfo(dwID)
	local tLine = g_tTable.PZZBuildings:Search(dwID)
	return tLine
end

function Table_GetPZZBuildStatusInfo(dwID)
	local tLine = g_tTable.PZZBuildingStatus:Search(dwID)
	return tLine
end

function Table_GetPZZString(dwID)
	local tLine = g_tTable.PZZString:Search(dwID)
	if tLine then
		return tLine.szString
	end
end

function Table_GetDesignationPrefixByForce(dwID, dwForceID)
	local nCount = g_tTable.Designation_Prefix_Force:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.Designation_Prefix_Force:GetRow(i)
		if tLine.dwID == dwID and tLine.dwForceID == dwForceID then
			return tLine
		end
	end
end

function Table_GetDesignationPrefix()
	local player = GetClientPlayer()
	if not player then
		return
	end

	local tRes = {}
	local tab = g_tTable.Designation_Prefix
	local nCount = tab:GetRowCount()
	for i = 2, nCount do
		local tLine = tab:GetRow(i)
		tRes[tLine.dwID] = tLine
		if tLine.bForce then
			local tForceLine = Table_GetDesignationPrefixByForce(tLine.dwID, player.dwForceID)
			if tForceLine then
				tRes[tLine.dwID] = tForceLine
			end
		end
	end
	return tRes
end

function Table_GetDesignationPrefixByID(dwID, dwForceID)
	local tLine = g_tTable.Designation_Prefix:Search(dwID)
	if tLine and tLine.bForce and dwForceID then
		local tForceLine = Table_GetDesignationPrefixByForce(tLine.dwID, dwForceID)
		if tForceLine then
			tLine = tForceLine
		end
	end
	return tLine
end

function Table_GetDesignationPostfix()
	local tRes = {}
	local tab = g_tTable.Designation_Postfix
	local nCount = tab:GetRowCount()
	for i = 2, nCount do
		local tLine = tab:GetRow(i)
		tRes[tLine.dwID] = tLine
	end
	return tRes
end

function Table_GetDesignationForce(dwForceID)
	local tRes = {}
	local tab = g_tTable.Designation_Generation
	local nCount = tab:GetRowCount()
	for i = 2, nCount do
		local tLine = tab:GetRow(i)
		if tLine.dwForce == dwForceID then
			table.insert(tRes, tLine)
		end
	end
	return tRes
end

function Table_GetDesignationGainWayList()
	local tRes = {}
	local nCount = g_tTable.DesignationGainWayList:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.DesignationGainWayList:GetRow(i)
		table.insert(tRes, tLine)
	end
	return tRes
end

function Table_GetDesignationVersionInfo()
	local tRes = {}
	local nCount = g_tTable.DesignationVersionInfo:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.DesignationVersionInfo:GetRow(i)
		tRes[tLine.nIndex] = tLine
	end
	return tRes
end

function Table_GetPendantListByType(szType)
	local nCount = g_tTable.PendantNew:GetRowCount()
	local tRes = {}
	for i = 2, nCount do
		local tLine = g_tTable.PendantNew:GetRow(i)
		if tLine.szType == szType then
			table.insert(tRes, tLine)
		end
	end
	return tRes
end

function Table_GetPendantEffectListByType(szType, nRoleType)
    local nCount = g_tTable.PendantEffect:GetRowCount()
    local tRes = {}
    for i = 2, nCount do
        local tLine = g_tTable.PendantEffect:GetRow(i)
        if not tLine.bHide and tLine.szType == szType then
            if tLine.szRoleType == "" then
                table.insert(tRes, tLine)
            else
                local tRoleType = SplitString(tLine.szRoleType, ';')
                for _, v in pairs(tRoleType) do
                    if tonumber(v) == nRoleType then
                        table.insert(tRes, tLine)
                        break
                    end
                end
            end
        end
    end
    return tRes
end

function Table_GetPendantEffectInfo(dwEffectID)
    local nCount = g_tTable.PendantEffect:GetRowCount()
    for i = 2, nCount do
        local tLine = g_tTable.PendantEffect:GetRow(i)
        if tLine.dwEffectID == dwEffectID then
            return tLine
        end
    end
end

function Table_GetArenaVotingInfo(dwID)
	local tLine = g_tTable.ArenaVotingPanel:Search(dwID)
	if tLine then
		return tLine
	end
end

function Table_GetArenaVotingList()
	local nCount = g_tTable.ArenaVotingPanel:GetRowCount()
	local tRes = {}
	for i = 2, nCount do
		local tLine = g_tTable.ArenaVotingPanel:GetRow(i)
		table.insert(tRes, tLine)
	end
	return tRes
end

---@class PartnerNpcInfo 侠客信息
---@field dwID number ID
---@field szName string 名称
---@field nKungfuIndex number 侠客心法类型
---@field szImgUnknownPath string 未结识时的图片
---@field dwOrigModelID number 原始模型ID
---@field fScale number 模型缩放系数
---@field szCamera string 镜头参数
---@field szSmallAvatarPath string 小头像图片
---@field nSmallAvatarFrame number 小头像图片frame
---@field szMeetAvatarPath string 结识提示的图片
---@field nMeetAvatarFrame number 结识提示的图片frame
---@field szUnlockAvatarPath string 结识后的图片
---@field nUnlockAvatarFrame number 结识后的图片frame
---@field szBgPath string 背景图
---@field szEquipAvatarPath string 装备小头像图片
---@field nEquipAvatarFrame number 装备小头像图片frame
---@field bCanMorph boolean 是否可以共鸣
---@field nRoleType number ?
---@field nDefaultActID number ?
---@field bSheath boolean ?
---@field bOutOfPrint boolean ?
---@field bTryOut boolean 是否是试用侠客
---@field szAvatarImg string 卡牌立绘
---@field szBigAvatarImg string 获得立绘
---@field szSmallAvatarImg string 共鸣立绘
---@field szEquipmentOwnerName string 装备拥有者缩写
---@field nRarity number 稀有度（之前vk添加的，现已废弃，改为与dx一起使用下面的nQuality）
---@field szIntroduce string 侠客介绍
---@field szNickName string 昵称
---@field nPrice number 雇佣所需园宅币（管家侠客专有，bCanMorph为false）
---@field nFilterWay number vk过滤筛选项 - 获取途径
---@field szDrawItemList string 可用的喝茶道具列表
---@field nQuality number 侠客出行品质
---@field szLimitTip string 限定tips

---@return PartnerNpcInfo[]
function Table_GetAllPartnerNpcInfo()
	local nCount = g_tTable.PartnerNpcInfo:GetRowCount()
	local tRes = {}
	for i = 2, nCount do
		local tLine = g_tTable.PartnerNpcInfo:GetRow(i)
		table.insert(tRes, tLine)
	end
	return tRes
end

---@return PartnerNpcInfo
function Table_GetPartnerNpcInfo(dwID)
	local tLine = g_tTable.PartnerNpcInfo:Search(dwID)
	return tLine
end

---@class PartnerQuality 侠客品质
---@field nQuality number 品质
---@field szImgPath string dx的品质背景图
---@field nFrame number dx的品质背景图frame
---@return PartnerQuality
function Table_GetPartnerQuality(nQuality)
    local tLine = g_tTable.PartnerQuality:Search(nQuality)
    return tLine
end

---@class PartnerTravelClass 侠客出行类别
---@field nDataIndex number index
---@field szClassName string 大类名称
---@field nLimitType number 次数限制类别
---@field nLimitNum number 次数限制上限
---@field szGiftItem string 奖励道具列表
---@field szGiftMessage string 奖励描述
---@field szImgTeamBgPath string 队伍背景图
---@field nTeamBgFrame string 队伍背景图frame
---@field szCostItemMultiCount string 出行大类次数达到指定次数后，路菜消耗的翻倍情况
---
---@field nClass number 大类，该字段已废弃，加载后默认填充0来减少改动
---@field nSub number 子类，该字段已废弃，加载后默认填充0来减少改动
---@field szSubName string 小类名称，该字段已废弃

--- 上面三个字段已不再配置，但为了减少上层改动，这里设置其默认值
---@param tLine PartnerTravelClass
local function _CompatibleWithOldVersionConfig(tLine)
    if not tLine.nClass then
        tLine.nClass = tLine.nDataIndex
    end
    if not tLine.nSub then
        tLine.nSub = 0
    end
    if not tLine.szSubName then
        tLine.szSubName = ""
    end
end

---@return PartnerTravelClass
function Table_GetPartnerTravelClassByIndex(nDataIndex)
    local tLine = g_tTable.PartnerTravelClass:Search(nDataIndex)
    _CompatibleWithOldVersionConfig(tLine)
    return tLine
end

--- 获取侠客出行大类的配置
---@return PartnerTravelClass
function Table_GetPartnerTravelClass(nClass)
    local nCount = g_tTable.PartnerTravelClass:GetRowCount()
    for i = 2, nCount do
        ---@type PartnerTravelClass
        local tLine = g_tTable.PartnerTravelClass:GetRow(i)
        _CompatibleWithOldVersionConfig(tLine)

        if tLine.nClass == nClass and tLine.nSub == 0 then
            return tLine
        end
    end

    return nil
end

---@return table<number, table<number, PartnerTravelClass>>
function Table_GetPartnerTravelClassToSubToInfo()
    local tClassToSubToInfo = {}

    local nCount = g_tTable.PartnerTravelClass:GetRowCount()
    for i = 2, nCount do
        ---@type PartnerTravelClass
        local tLine = g_tTable.PartnerTravelClass:GetRow(i)
        _CompatibleWithOldVersionConfig(tLine)

        local nClass = tLine.nClass
        local nSub = tLine.nSub

        if not tClassToSubToInfo[nClass] then
            tClassToSubToInfo[nClass] = {}
        end

        tClassToSubToInfo[nClass][nSub] = tLine
    end

    return tClassToSubToInfo
end

---@return table<number, PartnerTravelClass>
function Table_GetPartnerTravelDataIndexToInfo()
    local tDataIndexToInfo = {}

    local nCount = g_tTable.PartnerTravelClass:GetRowCount()
    for i = 2, nCount do
        ---@type PartnerTravelClass
        local tLine = g_tTable.PartnerTravelClass:GetRow(i)
        _CompatibleWithOldVersionConfig(tLine)

        tDataIndexToInfo[tLine.nDataIndex] = tLine
    end

    return tDataIndexToInfo
end

---@class PartnerTravelTask 侠客出行事件
---@field dwID number 事件id
---@field szName string 名称
---@field szDesc string 描述
---@field nDataIndex number 类别信息的Index，对应class表
---@field dwAdventureID number 奇遇ID，目前应该仅摸宠奇遇事件会配置
---@field dwMapID number 副本地图ID，目前应该仅秘境事件会配置
---@field szCostList string 消耗列表（货币/道具）
---@field nTime number 需要消耗时间（分钟）
---@field nNeedPartnerNum number 需要的侠客数目
---@field szPreAchievement string 前置成就
---@field szPreQuest string 前置任务
---@field szPreFame string 前置名望
---@field szLink string 未解锁时的跳转链接？
---@field szPartnerQuality string 需求的侠客品质
---@field szGiftItem string 必得奖励列表（道具、货币）
---@field szRandomGiftItem string 概率获得奖励列表（道具、货币）
---@field szReputation string 奖励声望列表
---@field szFame string 奖励名望列表
---@field szAchievement string 奖励成就列表
---@field szTryAdventure string 可触发的奇遇事件列表，形如 21;22;
---@field szImgSmallBgPath string _dx使用字段_
---@field nSmallBgFrame string _dx使用字段_
---@field szImgBigBgPath string _dx使用字段_
---@field nBigBgFrame string _dx使用字段_
---
---@field nClass number 大类，该字段已废弃，加载后默认填充0来减少改动
---@field nSub number 子类，该字段已废弃，加载后默认填充0来减少改动

---@param tLine PartnerTravelTask
local function _LoadClassAndSub(tLine)
    local tClass = Table_GetPartnerTravelClassByIndex(tLine.nDataIndex)

    tLine.nClass = tClass.nClass
    tLine.nSub = tClass.nSub
end

---@return PartnerTravelTask
function Table_GetPartnerTravelTask(dwID)
    local tLine = g_tTable.PartnerTravelTask:Search(dwID)
    _LoadClassAndSub(tLine)

    return tLine
end

---@return table<number, table<number, PartnerTravelTask[]>>
function Table_GetPartnerTravelTaskClassToSubToInfoList()
    local tClassToSubToInfoList = {}

    local nCount = g_tTable.PartnerTravelTask:GetRowCount()
    for i = 2, nCount do
        ---@type PartnerTravelTask
        local tLine = g_tTable.PartnerTravelTask:GetRow(i)
        _LoadClassAndSub(tLine)

        local nClass = tLine.nClass
        local nSub = tLine.nSub

        if not tClassToSubToInfoList[nClass] then
            tClassToSubToInfoList[nClass] = {}
        end

        if not tClassToSubToInfoList[nClass][nSub] then
            tClassToSubToInfoList[nClass][nSub] = {}
        end

        table.insert(tClassToSubToInfoList[nClass][nSub], tLine)
    end

    return tClassToSubToInfoList
end

---@class PartnerTravelTeam 侠客出行牌
---@field nIndex number 序号
---@field dwQuestID number 解锁需要的任务
---@field szUnlockTip string 未解锁时的提示

---@return PartnerTravelTeam
function Table_GetPartnerTravelTeamInfo(nIndex)
    local tLine = g_tTable.PartnerTravelTeam:Search(nIndex)
    return tLine
end

---@return PartnerTravelTeam[]
function Table_GetPartnerTravelTeamList()
    local nCount = g_tTable.PartnerTravelTeam:GetRowCount()
    local tRes = {}
    for i = 2, nCount do
        local tLine = g_tTable.PartnerTravelTeam:GetRow(i)
        table.insert(tRes, tLine)
    end
    return tRes
end

function Table_GetPartnerSkillInfo(dwPartnerID)
	local nCount = g_tTable.PartnerSkill:GetRowCount()
	local tRes = {}
	for i = 2, nCount do
		local tLine = g_tTable.PartnerSkill:GetRow(i)
		if tLine.dwPartnerID == dwPartnerID then
			table.insert(tRes, tLine)
		end
	end
	return tRes
end

function Table_GetPartnerVoiceInfo(nIndex)
	local tLine = g_tTable.PartnerVoice:Search(nIndex)
	return tLine
end

function Table_GetPartnerVoice(dwPartnerID)
	local nCount = g_tTable.PartnerVoice:GetRowCount()
	local tRes = {}
	for i = 2, nCount do
		local tLine = g_tTable.PartnerVoice:GetRow(i)
		if tLine.dwPartnerID == dwPartnerID then
			table.insert(tRes, tLine)
		end
	end
	return tRes
end

function Table_GetPartnerStoryInfo(nIndex)
	local tLine = g_tTable.PartnerStory:Search(nIndex)
	return tLine
end

function Table_GetPartnerStory(dwPartnerID)
	local nCount = g_tTable.PartnerStory:GetRowCount()
	local tRes = {}
	for i = 2, nCount do
		local tLine = g_tTable.PartnerStory:GetRow(i)
		if tLine.dwPartnerID == dwPartnerID then
			table.insert(tRes, tLine)
		end
	end
	return tRes
end

function Table_GetPartnerStageInfo(dwPartnerID)
	local nCount = g_tTable.PartnerStageInfo:GetRowCount()
	local tRes = {}
	for i = 2, nCount do
		local tLine = g_tTable.PartnerStageInfo:GetRow(i)
		if tLine.dwPartnerID == dwPartnerID then
			table.insert(tRes, tLine)
		end
	end
	return tRes
end

function Table_GetPartnerActVoiceInfo(nIndex)
	local tLine = g_tTable.PartnerActVoice:Search(nIndex)
	return tLine
end

function Table_GetPartnerActSetting(dwPartnerID, dwEventID)
	local tLine = g_tTable.PartnerActSetting:Search(dwPartnerID, dwEventID)
	return tLine
end

function Table_GetPartnerGiftInfo(dwPartnerID)
	local nCount = g_tTable.PartnerGiftInfo:GetRowCount()
	local tRes = {}
	for i = 2, nCount do
		local tLine = g_tTable.PartnerGiftInfo:GetRow(i)
		if tLine.dwPartnerID == dwPartnerID then
			table.insert(tRes, tLine)
		end
	end
	return tRes
end

function Table_GetPartnerTrackInfo(dwPartnerID)
	local nCount = g_tTable.PartnerTrackInfo:GetRowCount()
	local tRes = {}
	for i = 2, nCount do
		local tLine = g_tTable.PartnerTrackInfo:GetRow(i)
		if tLine.dwPartnerID == dwPartnerID then
			table.insert(tRes, tLine)
		end
	end
	return tRes
end

function Table_GetPartnerMorphSkill(dwIndex)
	local tLine = g_tTable.PartnerMorphSkill:Search(dwIndex)
	return tLine
end

function Table_GetPartnerCombatInfo(dwNpcID)
	local tLine = g_tTable.PartnerCombatInfo:Search(dwNpcID)
	return tLine
end

function Table_GetPartnerByTemplateID(dwTemplateID)
	local nCount = g_tTable.PartnerCombatInfo:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.PartnerCombatInfo:GetRow(i)
		if tLine.dwTemplateID == dwTemplateID then
			return tLine
		end
	end
end

function Table_GetPartnerMessage(dwID)
	local tLine = g_tTable.PartnerMessage:Search(dwID)
	return tLine
end

function Table_GetPartnerSkillEffect(dwSkillID)
	local tLine = g_tTable.PartnerSkillEffect:Search(dwSkillID)
	return tLine
end

function Table_GetPartnerDrawStory(dwPartnerID)
    local tRes = {}
    local nCount = g_tTable.PartnerDrawStory:GetRowCount()
    for i = 2, nCount do
        local tLine = g_tTable.PartnerDrawStory:GetRow(i)
        if tLine.dwPartnerID == dwPartnerID then
            table.insert(tRes, tLine)
        end
    end
    return tRes
end

function Table_GetDramaInfo(dwID)
	local tLine = g_tTable.Drama:Search(dwID)
	if tLine and tLine.bOpen then
		local tType = SplitString(tLine.szType, "|")
		tLine.tType = tType
		return tLine
	end
end

function Table_GetDramaList()
	local nCount = g_tTable.Drama:GetRowCount()
	local tRes = {}
	for i = 2, nCount do
		local tLine = g_tTable.Drama:GetRow(i)
		if tLine.bOpen then
			local tType = SplitString(tLine.szType, "|")
			tLine.tType = tType
			table.insert(tRes, tLine)
		end
	end
	return tRes
end

function Table_GetDramaMapAndMeta(dwID)
	local tLine = g_tTable.Drama:Search(dwID)
	return tLine.dwMapID, tLine.dwMetaID
end

function Table_GetAllDramaID()
	local nCount = g_tTable.Drama:GetRowCount()
	local tRes = {}
	for i = 2, nCount do
		local tLine = g_tTable.Drama:GetRow(i)
		if tLine.bOpen then
			table.insert(tRes, tLine.dwID)
		end
	end
	return tRes
end

function Table_GetDramaClue(dwDramaID, dwClueID)
	local tLine = g_tTable.DramaClue:Search(dwDramaID, dwClueID)
	if tLine then
		return tLine
	end
end

function Table_GetDramaFlow(dwDramaID, dwFlowID)
	local tLine = g_tTable.DramaFlow:Search(dwDramaID, dwFlowID)
	if tLine then
		return tLine
	end
end

function Table_GetDramaRole(dwDramaID, dwRoleID)
	local tLine = g_tTable.DramaRole:Search(dwDramaID, dwRoleID)
	if tLine then
		return tLine
	end
end

function Table_GetRolesInOneDrama(dwDramaID)
	local nCount = g_tTable.DramaRole:GetRowCount()
	local tRes = {}
	for i = 2, nCount do
		local tLine = g_tTable.DramaRole:GetRow(i)
		if tLine.dwDramaID == dwDramaID then
			table.insert(tRes, tLine)
		end
	end
	return tRes
end

function Table_GetDramaQA(dwDramaID, dwQAID)
	local tLine = g_tTable.DramaQA:Search(dwDramaID, dwQAID)
	if tLine then
		return tLine
	end
end

function Table_GetSeasonDistanceQuestInfo()
	local nCount = g_tTable.SeasonDistanceQuestInfo:GetRowCount()
	local tRes = {}
	for i = 2, nCount do
		local tLine = g_tTable.SeasonDistanceQuestInfo:GetRow(i)
		table.insert(tRes, tLine)
	end
	return tRes
end

function Table_GetSwitchServerInfo(nIndex)
	local tLine = g_tTable.SwitchServerInfo:Search(nIndex)
	return tLine
end

function Table_GetAllSwitchServerInfo()
	local nCount = g_tTable.SwitchServerInfo:GetRowCount()
	local tRes = {}
	for i = 1, nCount do
		local tLine = g_tTable.SwitchServerInfo:GetRow(i)
		table.insert(tRes, tLine)
	end
	return tRes
end

function Table_GetSwitchServerFieldInfo(nIndex)
	local tLine = g_tTable.SwitchServerFieldInfo:Search(nIndex)
	return tLine
end

function Table_GetAllSwitchServerFieldInfo()
	local nCount = g_tTable.SwitchServerFieldInfo:GetRowCount()
	local tRes = {}
	for i = 1, nCount do
		local tLine = g_tTable.SwitchServerFieldInfo:GetRow(i)
		table.insert(tRes, tLine)
	end
	return tRes
end

function Table_GetAllStringLoginCusomRoleInfo()
	local nCount = g_tTable.StringLoginCusomRole:GetRowCount()
	local tRes = {}
	for i = 1, nCount do
		local tLine = g_tTable.StringLoginCusomRole:GetRow(i)
		table.insert(tRes, tLine)
	end
	return tRes
end

function Table_GetFameInfo()
    local tRes = {}
    local nCount = g_tTable.FameInfo:GetRowCount()
    for i = 2, nCount do
        local tLine = g_tTable.FameInfo:GetRow(i)
        table.insert(tRes, tLine)
    end
    return tRes
end

function Table_GetFameName(nFameID)
	local tLine = g_tTable.FameInfo:Search(nFameID)
	if tLine then
		return tLine.szName
	end

	return ""
end

function Table_IsSystemShopBanMapID(nMapID)
	local tLine = g_tTable.SystemShopBanMapID:Search(nMapID)
	return tLine ~= nil
end


function Table_GetSystemShopGroup(dwGroup)
	local tLine = g_tTable.SystemShopGroup:Search(dwGroup)
	if not tLine then
		return
	end

	local pPlayer = GetClientPlayer()
	if not pPlayer then
		return
	end

	local nCamp = pPlayer.nCamp

	local tSystemShopInfo = {}
	tSystemShopInfo.szName = tLine.szGroupName
	for i = 1, 10 do
		local szGroupName = tLine["szGroupName" .. i]
		if szGroupName ~= "" then
			tSystemShopInfo[i] = {}
			tSystemShopInfo[i]["szGroupName"] = szGroupName
			local szClassList = tLine["szShopClass" .. i]
			local tClassInfo = SplitString(szClassList, "|")
			local tList = SplitString(tLine["szShopList" .. i], "|")
			for nIndex, tShopInfo in ipairs(tList) do
				local tClass = {}
				tClass.szClassName = tClassInfo[nIndex]
				local tInfo = SplitString(tShopInfo, ":")
				for _, szDetailID in ipairs(tInfo) do
					local dwDetailIndex = tonumber(szDetailID)
					local tShop = Table_GetSystemShopDetail(dwDetailIndex)
					local bShow = CheckSystemShopCanShow(tShop, nCamp)
					if bShow then
						table.insert(tClass, tShop)
					end
				end
				if #tClass > 0 then
					table.insert(tSystemShopInfo[i], tClass)
				end
			end
		end
	end
	tSystemShopInfo.dwGroupID = tLine.dwGroupID
	tSystemShopInfo.nFullScreen = tLine.nFullScreen
	return tSystemShopInfo
end

function Table_GetSystemShopDetail(dwIndex)
	local tLine = g_tTable.SystemShopDetail:Search(dwIndex)
	if not tLine then
		return
	end
	return tLine
end

function Table_GetSystemShopByID(dwGroup, dwShopID)
	local nCount = g_tTable.SystemShopGroup:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.SystemShopGroup:GetRow(i)
		for ii = 1, 10 do
			local tList = SplitString(tLine["szShopList" .. ii], "|")
			for nIndex, tShopInfo in ipairs(tList) do
				local tInfo = SplitString(tShopInfo, ":")
				for _, szDetailID in ipairs(tInfo) do
					local dwDetailIndex = tonumber(szDetailID)
					local tShop = Table_GetSystemShopDetail(dwDetailIndex)
					if tShop.nShopID == dwShopID then
						return tShop
					end
				end
			end
		end
	end
end

function Table_GetSystemShopTime(dwShopID)
	local nCount = g_tTable.SystemShopGroup:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.SystemShopGroup:GetRow(i)
		for ii = 1, 10 do
			local tList = SplitString(tLine["szShopList" .. ii], "|")
			for nIndex, tShopInfo in ipairs(tList) do
				local tInfo = SplitString(tShopInfo, ":")
				for iii, szDetailID in ipairs(tInfo) do
					local dwDetailIndex = tonumber(szDetailID)
					local tShop = Table_GetSystemShopDetail(dwDetailIndex)
					if tShop.nShopID == dwShopID then
						return tShop.nTime
					end
				end
			end
		end
	end
	return 0
end

function Table_GetSystemShopGroupName(dwGroup, dwShopID)
	if not dwGroup then
		return
	end
	local tLine = g_tTable.SystemShopGroup:Search(dwGroup)
	if not tLine then
		return
	end
	local szRes = ""
	for i = 1, 10 do
		local szGroupName = tLine["szGroupName" .. i]
		if szGroupName ~= "" then
			local tList = SplitString(tLine["szShopList" .. i], "|")
			for _, tShopInfo in ipairs(tList) do
				local tInfo = SplitString(tShopInfo, ":")
				for _, szDetailID in ipairs(tInfo) do
					local dwDetailIndex = tonumber(szDetailID)
					local tShop = Table_GetSystemShopDetail(dwDetailIndex)
					if tShop.nShopID == dwShopID then
						szRes = szGroupName
						break
					end
				end
			end
		end
	end
	return szRes
end

function Table_GetDiamondCost()
	local tRes   = {}
	local nCount = g_tTable.DiamondCost:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.DiamondCost:GetRow(i)
		if tLine.nLevel and tLine.fCost > 0 then
			tRes[tLine.nLevel] = tLine.fCost
		end
	end
	return tRes
end

function Table_GetAllSeasonTagInfo()
	local tRes = {}
	local nCount = g_tTable.SeasonTag:GetRowCount()
	for i = 1, nCount do
		local tLine = g_tTable.SeasonTag:GetRow(i)
		if tLine and tLine.dwID then
			tRes[tLine.dwID] = tLine
		end
	end
	return tRes
end

function Table_GetFellowPet_SortList()
	local tRes = {}
	local nCount = g_tTable.FellowPetSort:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.FellowPetSort:GetRow(i)
		table.insert(tRes, tLine)
	end
	return tRes
end


function Table_GetSoundInfo(nIndex)
	local tLine = g_tTable.PlotSoundInfo:Search(nIndex)
    if not tLine then
        return
    end
    return tLine
end

function Table_GetBodyBoneList(nRoleType)
	local hBodyLiftManager = GetBodyReshapingManager()
	if not hBodyLiftManager then
		return
	end
	local tBoneInfo = hBodyLiftManager.GetAllBoneInfo(nRoleType)
	local nCount = g_tTable.BodyBones:GetRowCount()
	local tClassMap = {}
	local tClassList = {}
	for i = 2, nCount do
		local tLine = g_tTable.BodyBones:GetRow(i)
		local tRoleType = {}
		if not string.is_nil(tLine.szRoleType) and tLine.szRoleType ~= "0" then
			local tTemp = string.split(tLine.szRoleType, ";")
			for _, value in pairs(tTemp) do
				tRoleType[tonumber(value)] = true
			end
		end
		if (table.is_empty(tRoleType) or tRoleType[nRoleType]) and tBoneInfo[tLine.nBodyType] then
			if not tClassMap[tLine.dwClassID] then
				table.insert(tClassList, {})
				tClassMap[tLine.dwClassID]  = tClassList[#tClassList]
			end
			local tClass = tClassMap[tLine.dwClassID]
			if tLine.szClassName ~= "" then
				tClass.szName = tLine.szClassName
				tClass.dwClassID = tLine.dwClassID
			end
			table.insert(tClass, {
				nBodyType = tLine.nBodyType,
				szBodyName = tLine.szBodyName,
				nStep = tLine.nStep,
				szTip = tLine.szTip})
		end
	end

	return  tClassList
end

function Table_GetOfficalBodyList(nRoleType, bPrice)
	local tBodyList = {}
	local tDefault = {}
	local nCount = g_tTable.BodyDefault:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.BodyDefault:GetRow(i)
		if tLine.nRoleType == nRoleType and
			(bPrice or tLine.bCanUseInCreate)
		then
			table.insert(tBodyList, tLine)
			if tLine.bDefault then
				tDefault = tLine
			end
		end
	end
	return tBodyList, tDefault
end

function Table_GetDefaultBodyInfo(nRoleType)
	local nCount = g_tTable.BodyDefault:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.BodyDefault:GetRow(i)
		if tLine.nRoleType == nRoleType and tLine.bDefault then
			return tLine
		end
	end
end

function Table_GetBodyClothList(nRoleType)
	local tBodyCloth = {}
	local nCount = g_tTable.BodyCloth:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.BodyCloth:GetRow(i)
		if tLine.nRoleType == 0 or tLine.nRoleType == nRoleType then
			table.insert(tBodyCloth, tLine)
		end
	end
	return tBodyCloth
end

function Table_GetOfficalFaceV2List(nRoleType, bPrice)
	local tFaceList = {}
	local tDefault = {}
	local nCount = g_tTable.FaceDefaultV2:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.FaceDefaultV2:GetRow(i)
		if tLine.nRoleType == nRoleType and
			(bPrice or tLine.bCanUseInCreate)
		then
			table.insert(tFaceList, tLine)
			if tLine.bDefault then
				tDefault = tLine
			end
		end
	end
	return tFaceList, tDefault
end

function Table_GetFaceBoneV2List()
	local nCount = g_tTable.FaceBonesV2:GetRowCount()
	local tList = {}
	local tArea, tClass
	for i = 2, nCount do
		local tLine = g_tTable.FaceBonesV2:GetRow(i)
		tArea = tList[tLine.nAreaID]
		if not tArea then
			tList[tLine.nAreaID]  = {}
			tArea = tList[tLine.nAreaID]
			tArea.szAreaName = tLine.szAreaName
			tArea.szAreaDefault = tLine.szAreaDefault
			tArea.szAreaPath = tLine.szAreaPath
			tArea.szAreaAni = tLine.szAreaAni
			tArea.szDefaultName = tLine.szDefaultName
		end

		tClass = tArea[tLine.nClassID]
		if not tClass then
			tArea[tLine.nClassID]  = {}
			tClass = tArea[tLine.nClassID]
			tClass.szClassName = tLine.szClassName
			tClass.dwClassID = tLine.nClassID
		end

		table.insert(tClass, {
			nBoneType 		= tLine.nBoneType,
			szBoneName 		= tLine.szBoneName,
			szBoneTip 		= tLine.szBoneTip,
			szDivideName 	= tLine.szDivideName,
			nStep 			= tLine.nStep,
		})
	end

	return  tList
end

function Table_GetFaceBoneDefault(nBoneDefault, nRoleType)
	local tLine = g_tTable.FaceBoneDefault:Search(nBoneDefault, nRoleType)
	return tLine
end

function Table_GetDecalsAdjustV2(nType)
	local tLine = g_tTable.FaceDecalsAdjustV2:LinearSearch({nType = nType})
	return tLine
end

function Table_GetFaceAniList(nRoleType)
	local tFaceAni = {}
	local nCount = g_tTable.FaceAni:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.FaceAni:GetRow(i)
		if tLine.nRoleType == 0 or tLine.nRoleType == nRoleType then
			table.insert(tFaceAni, tLine)
		end
	end
	return tFaceAni
end

function Table_GetFeedItemList()
	local tInfo = {}
	local nCount = g_tTable.FeedItemList:GetRowCount()
	for i = 1, nCount do
		local tLine = g_tTable.FeedItemList:GetRow(i)
		table.insert(tInfo, tLine)
	end
	return tInfo
end

function Table_GetFeedItemInfo(dwTabType, dwIndex)
	local tLine = g_tTable.FeedItemList:Search(dwTabType, dwIndex)
	return tLine
end

function Table_GetAuctionActivityList()
	local tRes = {}
	local nCount = g_tTable.AuctionActivity:GetRowCount()
	for i = 1, nCount do
		local tLine = g_tTable.AuctionActivity:GetRow(i)
		if tLine then
			table.insert(tRes, tLine.dwActivityID)
		end
	end
	return tRes
end

function Table_GetAuctionActivityInfo(nActivityID)
	local tLine = g_tTable.AuctionActivity:Search(nActivityID)
	return tLine
end

function Table_GetLoginSceneList()
	local tLoginScene = {}
	local nCount = g_tTable.LoginScene:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.LoginScene:GetRow(i)
		table.insert(tLoginScene, tLine)
	end
	return tLoginScene
end

function Table_GetLoginSceneInfo(nID)
	local tLine = g_tTable.LoginScene:Search(nID)
	return tLine
end

function Table_GetSwitchServerBossInfo(nPage)
	local nCount = g_tTable.SwitchServerBossInfo:GetRowCount()
	local tRes = {}
	for i = 2, nCount do
		local tLine = g_tTable.SwitchServerBossInfo:GetRow(i)
		if tLine.nPage == nPage then
			table.insert(tRes, tLine)
		end
	end
	return tRes
end

function Table_GetInterludeInfo(nIndex)
    local tLine = g_tTable.Interlude:Search(nIndex)
    if not tLine then
        return
    end
    return tLine
end

function Table_GetMarkNPCList()
	local tbRes = {}
	local nCount = g_tTable.Npc:GetRowCount()
	for i = 1, nCount do
		local tLine = g_tTable.Npc:GetRow(i)
		if tLine.dwAimMarkPriority ~= -1 then
			tbRes[tLine.dwTemplateID] = tLine
		end
	end
	return tbRes
end

function Table_GetHouseInteractionList()
	local tRes = {}
	local nCount = g_tTable.HouseInteraction:GetRowCount()
	for i = 1, nCount do
		local tLine = g_tTable.HouseInteraction:GetRow(i)
		if tLine then
			table.insert(tRes, tLine)
		end
	end
	return tRes
end

function Table_GetTreasureHuntEffect(dwID)
	local nCount = g_tTable.TreasureHuntEffect:GetRowCount()
	for i = 1, nCount do
		local tLine = g_tTable.TreasureHuntEffect:GetRow(i)
		if tLine.dwID == dwID then
			return tLine
		end
	end
end

function Table_GetMiniGameShopList()
	local tInfo = {}
	local nCount = g_tTable.HomelandMiniGameShop:GetRowCount()
	for i = 1, nCount do
		local tLine = g_tTable.HomelandMiniGameShop:GetRow(i)
		table.insert(tInfo, tLine)
	end
	return tInfo
end

function Table_GetGameGuideInfo()
	local tRes = {}
	local nCount = g_tTable.GameGuide:GetRowCount()
	for i = 1, nCount do
		local tLine = g_tTable.GameGuide:GetRow(i)
		if tLine then
			local tActivity = SplitString(tLine.szActivity, ";")
			tLine.tActivity = tActivity
			table.insert(tRes, tLine)
		end
	end
	table.sort(tRes, function (a, b)
		return a.nPriority < b.nPriority
	end)
	return tRes
end

function Table_GetGameGuideByID(dwID)
	local nCount = g_tTable.GameGuide:GetRowCount()
	for i = 1, nCount do
		local tLine = g_tTable.GameGuide:GetRow(i)
		if tLine and tLine.dwID == dwID then
			return tLine
		end
	end
end

function Table_GetNPCNameVisibleList(nMapID)
	if not tNPCNameVisible then
		tNPCNameVisible = {}
		local nCount = g_tTable.NPCNameVisible:GetRowCount()
		for i = 2, nCount do
			local tLine = g_tTable.NPCNameVisible:GetRow(i)
			if not tNPCNameVisible[tLine.nMapID] then
				tNPCNameVisible[tLine.nMapID] = {}
			end

			if not tNPCNameVisible[tLine.nMapID][tLine.nType] then
				tNPCNameVisible[tLine.nMapID][tLine.nType] = {}
			end
			table.insert(tNPCNameVisible[tLine.nMapID][tLine.nType],tLine)
		end
	end

	return tNPCNameVisible[nMapID]
end

function Table_GetAllCollectionDLCInfo()
	local tRes = {}
	local nCount = g_tTable.CollectionDLCInfo:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.CollectionDLCInfo:GetRow(i)
		table.insert(tRes, tLine)
	end
	return tRes
end

function Table_GetCollectionDLCInfo(nDLCIndex)
	local tRes
	local nCount = g_tTable.CollectionDLCInfo:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.CollectionDLCInfo:GetRow(i)
		if tLine.nIndex == nDLCIndex then
			tRes = tLine
			break
		end
	end
	return tRes
end

function Table_GetCollectionBoxList(nDLCIndex)
	local tRes = {}
	local nCount = g_tTable.CollectionBoxInfo:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.CollectionBoxInfo:GetRow(i)
		if tLine.nDLCIndex == nDLCIndex then
			table.insert(tRes, tLine)
		end
	end
	return tRes
end

function Table_GetCollectionBox(nBoxIndex)
	local tRes
	local nCount = g_tTable.CollectionBoxInfo:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.CollectionBoxInfo:GetRow(i)
		if tLine and tLine.nIndex == nBoxIndex then
			tRes = tLine
			break
		end
	end
	return tRes
end

function Table_GetCollectionPreviewPendantList(nBoxIndex)
	local tRes = {}
	local nCount = g_tTable.CollectionPendantInfo:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.CollectionPendantInfo:GetRow(i)
		if tLine.nBelongBox == nBoxIndex then
			table.insert(tRes, tLine)
		end
	end
	return tRes
end

function Table_GetCollectionOrangePendantList(nDLCIndex)
	local tRes = {}
	local nCount = g_tTable.CollectionOrangePendantInfo:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.CollectionOrangePendantInfo:GetRow(i)
		if tLine.nDLCIndex == nDLCIndex then
			table.insert(tRes, tLine)
		end
	end
	return tRes
end

function Table_GetCollectionOrangePendantInfo(dwItemIndex)
	local tRes
	local nCount = g_tTable.CollectionOrangePendantInfo:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.CollectionOrangePendantInfo:GetRow(i)
		if tLine.dwItemIndex == dwItemIndex then
			tRes = tLine
			break
		end
	end
	return tRes
end

function Table_GetCollectionFilterList()
	local tRes = {}
	local nCount = g_tTable.CollectionFilterInfo:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.CollectionFilterInfo:GetRow(i)
		local nIndex = tLine.nIndex
		if not tRes[nIndex] then
			tRes[nIndex] = {}
		end
		table.insert(tRes[nIndex], tLine)
	end
	return tRes
end

function Table_GetCollectionPendantInfo(dwItemIndex)
	local tRes
	local nCount = g_tTable.CollectionPendantInfo:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.CollectionPendantInfo:GetRow(i)
		if tLine.dwItemIndex == dwItemIndex then
			tRes = tLine
			break
		end
	end
	return tRes
end

function Table_GetCollectionColorInfo(nColorID)
	local tLine = g_tTable.CollectionColorInfo:Search(nColorID)
	return tLine
end


function Table_GetMonsterLockerItem()
	local tRes = {}
	local nCount = g_tTable.MonsterLocker:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.MonsterLocker:GetRow(i)
		if tLine and tLine.dwID then
			tRes[tLine.dwID] = tLine
		end
	end
	return tRes
end

function Table_GetPersonalCardByDecorationID(dwDecorationID)
	local tLine = g_tTable.PersonalCard:Search(dwDecorationID)

	return tLine
end

function Table_GetPersonalCardInfo(nDecorationType, dwDecorationID)
	local tLine = g_tTable.PersonalCard:Search(dwDecorationID, nDecorationType)

	return tLine
end

function Table_GetPersonalCardInfoByID(dwDecorationID)
	local tLine = g_tTable.PersonalCard:Search(dwDecorationID)

	return tLine
end

function Table_GetPersonalCardByDecorationType(nDecorationType)
	local tRes = {}
	local nCount = g_tTable.PersonalCard:GetRowCount()
	for i = 1, nCount do
		local tLine = g_tTable.PersonalCard:GetRow(i)
		if nDecorationType == tLine.nDecorationType then
			table.insert(tRes, tLine)
		end
	end

	return tRes
end

function Table_GetPersonalCardTab()
	local tRes = {}
	local nCount = g_tTable.PersonalCard:GetRowCount()
	for i = 1, nCount do
		local tLine = g_tTable.PersonalCard:GetRow(i)
		table.insert(tRes, tLine)
	end

	return tRes
end

function Table_GetAllCampBossDetail()
	local tRes = {}
	local nCount = g_tTable.CampBossDetail:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.CampBossDetail:GetRow(i)
		if tLine then
			table.insert(tRes, tLine)
		end
	end
	return tRes
end

function Table_GetAllPersonalCardData()
	local tRes = {}
	local nCount = g_tTable.PersonalCardData:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.PersonalCardData:GetRow(i)
		if tLine then
			table.insert(tRes, tLine)
		end
	end
	return tRes
end

function Table_GetPersonalCardData(dwKey)
    local tLine = g_tTable.PersonalCardData:Search(dwKey)
    if not tLine then
        return
    end
    return tLine
end

function Table_GetGoldTeamAddPrice()
	local tRes = {}
	local nCount = g_tTable.GoldTeamAddPrice:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.GoldTeamAddPrice:GetRow(i)
		if tLine then
			table.insert(tRes, tLine)
		end
	end
	return tRes
end

function Table_GetDailyQuestInfo()
	local tRes = {}
	local nCount = g_tTable.GameGuideDailyQuest:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.GameGuideDailyQuest:GetRow(i)
		if tLine then
			tRes[tLine.dwID] = tLine
		end
	end
	return tRes
end

function Table_GetVideoCardScoreInfo()
	local tRes = {}
	local nCount = g_tTable.VideoCardScore:GetRowCount()
	for i = 1, nCount do
		local tLine = g_tTable.VideoCardScore:GetRow(i)
		if tLine then
			table.insert(tRes, tLine)
		end
	end
	return tRes
end

function Table_GetGameGuideDailyRewardList()
	local tRes = {}
	local nCount = g_tTable.GameGuideDailyReward:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.GameGuideDailyReward:GetRow(i)
		if tLine then
			local tbInfo = {}
			local tbItem = string.split(tLine.szReward, "_")
			tbInfo.nTabType, tbInfo.nTabID, tbInfo.nStackNum = tbItem[1], tbItem[2], tbItem[3]
			tbInfo.nLevel = tLine.nLevel
			table.insert(tRes, tbInfo)
		end
	end
	return tRes
end

function Table_GetQuickTeamRecruit(dwID)
	local tLine = g_tTable.QuickTeamRecruit:Search(dwID)
	if not tLine then
		return
	end
	return tLine
end

function Table_GetActivityProgressInfo(dwID)
	local tRes = {}
	local nCount = g_tTable.OperatActProgress:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.OperatActProgress:GetRow(i)
		if tLine and tLine.dwID == dwID then
			table.insert(tRes, tLine)
		end
	end
	return tRes
end

function Table_GetPopupRemindInfo(dwID)
	local tLine = g_tTable.PopupRemind:Search(dwID)
	return tLine
end

function Table_GetBirthdayCarInfo(nYear)
	local nCount = g_tTable.BirthdayCardInfo:GetRowCount()
    for i = 2, nCount do
        local tLine = g_tTable.BirthdayCardInfo:GetRow(i)
        if tLine and tLine.nYear == nYear then
            return tLine
        end
    end
	return
end

function Table_GetNPCRoster()
	local tRes = {}
	local nCount = g_tTable.NPCRoster:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.NPCRoster:GetRow(i)
		if tLine then
			table.insert(tRes, tLine)
		end
	end
	return tRes
end

function Table_GetConflatePanelInfo(dwID)
	local tLine = g_tTable.ConflatePanel:Search(dwID)
	return tLine
end

function Table_GetMapDynamicData()
	local tResult = {}
	local nCount = g_tTable.Map_DynamicData:GetRowCount()

	--Row One for default value
	for i = 2, nCount do
		local tData = g_tTable.Map_DynamicData:GetRow(i)
		tResult[tData.nType] = tData
	end
	return tResult
end

function Table_GetMapDynamicDataByID(nPQID)
	local nCount = g_tTable.Map_DynamicData:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.Map_DynamicData:GetRow(i)
		if tLine and tLine.nType == nPQID then
			return tLine
		end
	end
end

function Table_GetAPSectionLayer(szPlotKey)
    local tSection, tLayer = {}, {}
    local nSeasonCount = 0
    local nCount = g_tTable.ActivityPlotSection:GetRowCount()
    for i = 2, nCount do
        local tLine = g_tTable.ActivityPlotSection:GetRow(i)
        if tLine.szPlotKey == szPlotKey then
            local nSeasonID = tLine.nSeasonID
            local nChapterID = tLine.nChapterID
            if not tSection[nSeasonID] then
                tSection[nSeasonID] = {}
                nSeasonCount = nSeasonCount + 1
                tLayer[nSeasonCount] = {nSeasonID = nSeasonID, tChapterID = {}}
            end
            if not tSection[nSeasonID][nChapterID] then
                tSection[nSeasonID][nChapterID] = {}
                table.insert(tLayer[nSeasonCount].tChapterID, nChapterID)
            end
            table.insert(tSection[nSeasonID][nChapterID], tLine)
        end
    end
    return tSection, tLayer
end

function Table_GetAPSectionLayerInfo(szPlotKey, nID, szType)
    local tResult = {}
    local nIndex, nTotal = 0, 0
    local nCount = g_tTable.ActivityPlotSectionLayer:GetRowCount()
    for i = 2, nCount do
        local tLine = g_tTable.ActivityPlotSectionLayer:GetRow(i)
        if tLine.szPlotKey == szPlotKey and tLine.szType == szType then
            nTotal = nTotal + 1
             if tLine.nID == nID then
                tResult = tLine
                nIndex = nTotal
             end
        end
    end
    return tResult, nIndex, nTotal
end

function Table_GetAllOrangeWeaponInfo()
	local tRes = {}
	local nCount = g_tTable.OrangeWeaponInfo:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.OrangeWeaponInfo:GetRow(i)
		if tLine then
			table.insert(tRes, tLine)
		end
	end
	return tRes
end

function Table_GetOrangeWeaponInfoByForceID(dwForceID)
	local tRes = {}
	local nCount = g_tTable.OrangeWeaponInfo:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.OrangeWeaponInfo:GetRow(i)
		if tLine and tLine.dwForceID == dwForceID then
			table.insert(tRes, tLine)
		end
	end
	return tRes
end

function Table_GetLoginAnimationList(nRoleType, dwForceID)
	local tLoginAnimation = {}
	local nCount = g_tTable.LoginAnimation:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.LoginAnimation:GetRow(i)
		if (tLine.nRoleType == 0 or tLine.nRoleType == nRoleType) and
			(tLine.dwForceID == 0 or tLine.dwForceID == dwForceID) then
			table.insert(tLoginAnimation, tLine)
		end
	end
	return tLoginAnimation
end

function Table_GetLoginPresetList(nRoleType, dwForceID)
	local tLoginPreset = {}
	local nCount = g_tTable.LoginPreset:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.LoginPreset:GetRow(i)
		if (tLine.nRoleType == 0 or tLine.nRoleType == nRoleType) and
			(tLine.dwForceID == 0 or tLine.dwForceID == dwForceID) then
			table.insert(tLoginPreset, tLine)
		end
	end
	return tLoginPreset
end

function Table_GetAllHomelandBlueprintsChoice()
	local tBlueprintsChoice = {}
	local nCount = g_tTable.HomelandBlueprintsChoice:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.HomelandBlueprintsChoice:GetRow(i)
		table.insert(tBlueprintsChoice, tLine)
	end
	return tBlueprintsChoice
end

function Table_GetCalenderActivityAwardIconByID(dwID)
	local nCount = g_tTable.CalenderActivityAwardIcon:GetRowCount()
	for i = 1, nCount do
		local tLine = g_tTable.CalenderActivityAwardIcon:GetRow(i)
		if tLine.ID == dwID then
			return tLine
		end
	end
end

function Table_GetAllRecommendEquipInfo(dwKungfuID)
	local tItemList = {}
	local nCount = g_tTable.RecommendEquipInfo:GetRowCount()

	for i = 2, nCount do
		local tLine = g_tTable.RecommendEquipInfo:GetRow(i)
		local itemInfo = ItemData.GetItemInfo(tLine.dwTabType, tLine.dwIndex)
		if itemInfo.nRecommendID and g_tTable.EquipRecommend then
			local bFind = false
			local tbIDs = Table_GetEquipRecommendKungfus(itemInfo.nRecommendID, true)
			for nID, _ in pairs(tbIDs) do
				if nID == 0 or nID == dwKungfuID then
					bFind = true
					break
				end
			end

			if bFind then
				table.insert(tItemList, {
					itemInfo = itemInfo,
					tbConfig = tLine,
				})
			end
		end
	end
	return tItemList
end

local tbRecommendEquipInfo = nil
function Table_GetRecommendEquipInfo(dwTabType, dwIndex)
	local tItemList = {}
	if not tbRecommendEquipInfo then
		tbRecommendEquipInfo = {}

		local nCount = g_tTable.RecommendEquipInfo:GetRowCount()
		for i = 2, nCount do
			local tLine = g_tTable.RecommendEquipInfo:GetRow(i)
			tbRecommendEquipInfo[tLine.dwTabType] = tbRecommendEquipInfo[tLine.dwTabType] or {}
			tbRecommendEquipInfo[tLine.dwTabType][tLine.dwIndex] = {
				tbConfig = tLine,
			}
		end
	end
	return tbRecommendEquipInfo[dwTabType] and tbRecommendEquipInfo[dwTabType][dwIndex]
end

function Table_GetPQTeachInfo(dwPQID)
	local nCount = g_tTable.PQTeachInfo:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.PQTeachInfo:GetRow(i)
		if tLine and tLine.dwPQID == dwPQID then
			return tLine
		end
	end
end

function Table_GetGoldTeamItemMatchName()
	local tMatchName = {}
	local nRow = g_tTable.GoldTeamMatchName:GetRowCount()
    for i = 1, nRow do
        local tLine = g_tTable.GoldTeamMatchName:GetRow(i)
		table.insert(tMatchName, tLine.szName)
    end
	return tMatchName
end

function Table_GetJoinCampReward()
	local tRes = {}
	local nRow = g_tTable.JoinCampReward:GetRowCount()
	for i = 1, nRow do
		local tLine = g_tTable.JoinCampReward:GetRow(i)
		if tLine then
			table.insert(tRes, tLine)
		end
	end
	return tRes
end

function Table_GetAllRoleAvatarList()
	local tList = {}
	local nCount = g_tTable.RoleAvatar:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.RoleAvatar:GetRow(i)
		table.insert(tList, tLine)
	end
	return tList
end

function Table_GetRoleAvatarInfo(dwID)
	local tLine = g_tTable.RoleAvatar:Search(dwID)
	return tLine
end

function Table_GetAllMapAppointmentInfo()
	local tRes = {}
	local nRow = g_tTable.MapAppointmentInfo:GetRowCount()
	for i = 1, nRow do
		local tLine = g_tTable.MapAppointmentInfo:GetRow(i)
		if tLine then
			table.insert(tRes, tLine)
		end
	end
	return tRes
end

function Table_GetEnchantScore(dwID)
	local nScore = 0
	local tLine = g_tTable.EnchantScore:Search(dwID)
	if tLine then
		nScore = tLine.nScore
	end
	return nScore
end

function Table_GetEnchantAttributeName(dwID)
	local nScore = 0
	local tLine = g_tTable.EnchantScore:Search(dwID)
	if tLine then
		nScore = tLine.szAttribute
	end
	return nScore
end

function Table_GetAllColorDiamondList()
	local tList = {}
	local nCount = g_tTable.ColorDiamond:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.ColorDiamond:GetRow(i)
		local szAttribute1 = UIHelper.GBKToUTF8(tLine.szAttribute1)
		local szAttribute2 = UIHelper.GBKToUTF8(tLine.szAttribute2)
		local szAttribute3 = UIHelper.GBKToUTF8(tLine.szAttribute3)

		tList[szAttribute3] = tList[szAttribute3] or {}
		tList[szAttribute3][szAttribute2] = tList[szAttribute3][szAttribute2] or {}
		tList[szAttribute3][szAttribute2][szAttribute1] = tList[szAttribute3][szAttribute2][szAttribute1] or {}
		table.insert(tList[szAttribute3][szAttribute2][szAttribute1], {
			szName = UIHelper.GBKToUTF8(tLine.szName),
			dwItemID = tLine.dwItemID,
			nEnchantID = tLine.nEnchantID,
		})
	end
	return tList
end

function Table_GetIdleAction(dwID)
    local tLine = g_tTable.IdleAction:Search(dwID)
    return tLine
end

function Table_GetIdleActionEx(dwID)
	if dwID == 0 then
		-- return IdleActionBase.GetDefaultInfo()
		return {}
	end
    local tLine = g_tTable.IdleAction:Search(dwID)
    return tLine
end

function Table_GetStorySeasonList()
	local tList = {}
	local nCount = g_tTable.MainStorySeason:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.MainStorySeason:GetRow(i)
		tList[tLine.dwID] = tLine
	end
	return tList
end

function Table_GetStorySectionList()
	local tList = {}
	local nCount = g_tTable.MainStorySection:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.MainStorySection:GetRow(i)
		tList[tLine.dwID] = tLine
	end
	return tList
end

function Table_GetStoryChapterList()
	local tList = {}
	local nCount = g_tTable.MainStoryChapter:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.MainStoryChapter:GetRow(i)
		tList[tLine.dwID] = tLine
	end
	return tList
end

function Tabel_GetTongBattleTipsInfo(dwID)
    local tLine = g_tTable.TongBattleTips:Search(dwID)
    return tLine
end

function Tabel_GetTongBattledragonTipsInfo(dwID)
    local tLine = g_tTable.TongBattledragonTips:Search(dwID)
    return tLine
end

function Table_GetSwitchServerMapName()
    local szMapName = ""
    local tLine = g_tTable.SwitchServerFieldInfo:GetRow(1)
	if tLine then
        szMapName = UIHelper.GBKToUTF8(Table_GetMapName(tLine.dwMapID)) or ""
    end
	return szMapName
end

function Table_GetCaptionIconToTitleEffect(nCaptionIconType)
    local tLine = g_tTable.CaptionIconToTitleEffect:Search(nCaptionIconType)
	return tLine
end

local tFilterAtmosphere
local tFilterAtmosphereTimeList
function Table_GetFilterAtmosphere(nMapID)
	if not tFilterAtmosphere then
		tFilterAtmosphere = {}
		tFilterAtmosphereTimeList = {}
		local nCount = g_tTable.FilterAtmosphere:GetRowCount()
		for i = 1, nCount do
			local tLine = g_tTable.FilterAtmosphere:GetRow(i)
			local szTime = UIHelper.GBKToUTF8(tLine.szTime)
			local szWeather = UIHelper.GBKToUTF8(tLine.szWeather)
			tFilterAtmosphere[tLine.nMapID] = tFilterAtmosphere[tLine.nMapID] or {}
			tFilterAtmosphere[tLine.nMapID][szTime] = tFilterAtmosphere[tLine.nMapID][szTime] or {}
			tFilterAtmosphere[tLine.nMapID][szTime][szWeather] = tLine.szEnvPreset


			tFilterAtmosphereTimeList[tLine.nMapID] = tFilterAtmosphereTimeList[tLine.nMapID] or {}
			table.insert(tFilterAtmosphereTimeList[tLine.nMapID], szTime)
		end
	end
	return tFilterAtmosphere[nMapID]
end

function Table_GetFilterAtmosphereTimeList(nMapID)
	if not tFilterAtmosphereTimeList then
		Table_GetFilterAtmosphere(nMapID) -- Init
	end
	return tFilterAtmosphereTimeList[nMapID]
end

function Table_GetTreasureBoxList()
    local tList = {}
	local nCount = g_tTable.TreasureBoxInfo:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.TreasureBoxInfo:GetRow(i)
		tList[tLine.dwID] = tLine
	end
	return tList
end

function Table_GetTreasureBoxInfoByIndex(dwTabType, dwIndex)
	local nCount = g_tTable.TreasureBoxInfo:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.TreasureBoxInfo:GetRow(i)
		if tLine and tLine.szBoxItem then
			for szTabType, szIndex in string.gmatch(tLine.szBoxItem, "([%d]+);([%d]+)|?") do
				tLine.dwTabType = tonumber(szTabType)
				tLine.dwIndex = tonumber(szIndex)
			end
			if tLine.dwTabType == dwTabType and tLine.dwIndex == dwIndex then
				return tLine
			end
		end
	end
end

function Tabel_GetTreasureBoxListByID(dwID)
	local tList = Table_GetTreasureBoxList()
	return tList and tList[dwID]
	-- local tLine = g_tTable.TreasureBoxInfo:GetRow(dwID + 1)
    -- return tLine
end

function Table_GetTreasureAwardList()
    local tList = {}
	local nCount = g_tTable.TreasureBoxContent:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.TreasureBoxContent:GetRow(i)
		table.insert(tList, tLine)
	end
	return tList
end

function Table_GetTreasureBoxItemInfo()
	local tRes = {}
	local nCount = g_tTable.TreasureBoxContent:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.TreasureBoxContent:GetRow(i)
		if tLine and tLine.szOtherItem then
			tLine.tOtherItem = {}
			for dwTabType, dwIndex in string.gmatch(tLine.szOtherItem, "([%d]+);([%d]+)|?") do
				local tTemp = {nOtherType = tonumber(dwTabType), nOtherIndex = tonumber(dwIndex)}
				table.insert(tLine.tOtherItem, tTemp)
			end
		end

		if tLine and tLine.szAndItem then
			tLine.tAndItem = {}
			for dwTabType, dwIndex in string.gmatch(tLine.szAndItem, "([%d]+);([%d]+)|?") do
				local tTemp = {nAndType = tonumber(dwTabType), nAndIndex = tonumber(dwIndex)}
				table.insert(tLine.tAndItem, tTemp)
			end
		end

		if tLine and tLine.szItem then
			for dwTabType, dwIndex in string.gmatch(tLine.szItem, "([%d]+);([%d]+)|?") do
				tLine.dwTabType = tonumber(dwTabType)
				tLine.dwIndex = tonumber(dwIndex)
			end
		end
		table.insert(tRes, tLine)
	end
	return tRes
end

function Table_GetCustomInvitation(dwID)
	local nCount = g_tTable.CustomInvitation:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.CustomInvitation:GetRow(i)
		if tLine and tLine.dwID == dwID then
			return tLine
		end
	end
end

function Table_IsNoAnnounceAchievement(dwID)
    local tLine = g_tTable.NoAnnounceAchievement:Search(dwID)
    if tLine then
        return true
    end
    return false
end

function Table_GetArenaCropRewardInfo()
	local tRes = {}
	local nCount = g_tTable.ArenaCropReward:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.ArenaCropReward:GetRow(i)
		if tLine and tLine.szReward then
			tLine.tItem = {}
			for dwTabType, dwIndex , nCount in string.gmatch(tLine.szReward, "([%d]+);([%d]+);([%d]+)|?") do
				local tTemp = {
					dwTabType = tonumber(dwTabType),
					dwIndex = tonumber(dwIndex),
					nCount = tonumber(nCount)
				}
				table.insert(tLine.tItem, tTemp)
			end
		end
		table.insert(tRes, tLine)
	end
	return tRes
end

---@class RegionMapInfo 区域地图信息
---@field dwRegionID number id
---@field szRegionName string 区域名称
---@field nX number _
---@field nY number _
---@field fScale number _

---@return RegionMapInfo[]
function WorldMap_GetRegionOfWorldmap()
    local tRegionList = {}
    local nCount = g_tTable.RegionMap:GetRowCount()
    for i = 2, nCount do
        local tLine = g_tTable.RegionMap:GetRow(i)
        table.insert(tRegionList, tLine)
    end
    return tRegionList
end

---@class RegionMapListInfo 区域地图内的地图ID列表信息
---@field tRaid number[] 团队秘境的地图ID列表
---@field tDungeon number[] 五人秘境的地图ID列表
---
--- 区域内的非副本地图直接作为列表元素

--- 副本地图
local GROUP_TYPE_COPY 		= 4
local GROUP_TYPE_RAID 		= "RAID"
local GROUP_TYPE_DUNGEON 	= "DUNGEON"

---@return table<number, RegionMapListInfo>
--- 区域id => 区域内的地图列表信息
function Table_GetMapRegion()
    local tMapRegion = {}
    local nCount = g_tTable.MapList:GetRowCount()
    for i = 2, nCount do
        local tLine = g_tTable.MapList:GetRow(i)
        if tLine.dwRegionID > 0 then
            local dwRegionID = tLine.dwRegionID
            if not tMapRegion[dwRegionID] then
                tMapRegion[dwRegionID] = {}
            end
            local tRegion = tMapRegion[dwRegionID]
            if tLine.nGroup == GROUP_TYPE_COPY then
                if tLine.szType == GROUP_TYPE_RAID then
                    if not tRegion.tRaid then
                        tRegion.tRaid = {}
                    end
                    table.insert(tRegion.tRaid, tLine.nID)
                else
                    if not tRegion.tDungeon then
                        tRegion.tDungeon = {}
                    end
                    table.insert(tRegion.tDungeon, tLine.nID)
                end
            else
                table.insert(tRegion, tLine.nID)
            end
        end
    end
    return tMapRegion
end

function Table_GetFilterParamSetting()
    local tSettings = {}
    local nCount = g_tTable.FilterSetting:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.FilterSetting:GetRow(i)
        local nClass = tLine.nClass
        local nSub = tLine.nSub
		if nSub == 0 then
			if not tSettings[nClass] then
                tSettings[nClass] = CopyTable(tLine)
            end
        elseif tSettings[nClass] then
            local tClass = tSettings[nClass]
            tClass.tSub = tClass.tSub or {}
            table.insert(tClass.tSub, tLine)
		end
	end
    return tSettings
end

function Table_GetFilterParamByID(nParamID)
    local tLine = g_tTable.FilterSetting:Search(nParamID)
	return tLine
end

function Table_GetFilterColorParamSetting(nColorClass)
    local tRes = {}
	local nCount = g_tTable.FilterColorParamSetting:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.FilterColorParamSetting:GetRow(i)
		if tLine and tLine.nColorClass == nColorClass then
			table.insert(tRes, tLine)
		end
	end
	return tRes
end

function Table_GetFilterColorClassByID(nColorID)
    local tLine = g_tTable.FilterColorParamSetting:Search(nColorID)
    if tLine then
        return tLine.nColorClass
    end
end

function Table_GetSelfieStudioInfo(dwID)
    local tLine = g_tTable.SelfieStudio:Search(dwID)
    return tLine
end

function Table_GetAllSelfieStudio()
    local tRes = {}
    local nCount = g_tTable.SelfieStudio:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.SelfieStudio:GetRow(i)
		table.insert(tRes, tLine)
	end
    return tRes
end

function Table_GetASelfieStudioPreset(dwID)
    local tLine = g_tTable.SelfieStudio:Search(dwID)
    if tLine then
		local tPreset = SplitString(tLine.szPreset, ";")
        return tPreset
    end
end

function Table_GetSelfieStudioPresetInfo(dwID)
    local tLine = g_tTable.SelfieStudioPreset:Search(dwID)
    return tLine
end

function Table_GetActivityFilterPresetList(dwMapID)
    local tRes = {}
    local nCount = g_tTable.ActivityFilterPreset:GetRowCount()
    for i = 2, nCount do
		local tLine = g_tTable.ActivityFilterPreset:GetRow(i)
        if tLine and tLine.dwMapID == dwMapID then
            table.insert(tRes, tLine)
        end
	end
    return tRes
end

function Table_IsActivityNeedPreset(dwMapID, dwActivityID)
    local nCount = g_tTable.ActivityFilterPreset:GetRowCount()
    for i = 2, nCount do
		local tLine = g_tTable.ActivityFilterPreset:GetRow(i)
        if tLine and tLine.dwMapID == dwMapID and tLine.dwActivityID == dwActivityID then
            return true
        end
	end
    return false
end

function Table_GetHeatMapAreaInfoByPQ(nPQID)
    local nCount = g_tTable.HeatMapArea:GetRowCount()
    for i = 1, nCount do
        local tLine = g_tTable.HeatMapArea:GetRow(i)
        if tLine.nPQID == nPQID then
            return tLine
        end
    end
end

--大攻防据点区域
--tRegionPoint 为左下角坐标，nRegionW为宽度，nRegionH为高度，热力图一个Region是实际逻辑2*2个Region，所以算区域时nRegionW和nRegionH都要乘以2
function Table_GetHeatMapAreaInfo(dwMapID)
    local tRes = {}
    local nCount = g_tTable.HeatMapArea:GetRowCount()
    for i = 1, nCount do
        local tLine = g_tTable.HeatMapArea:GetRow(i)
        if tLine.dwMapID == dwMapID then
            table.insert(tRes, tLine)
        end
    end
    return tRes
end

function Table_IsPriorityInAutoSearch(nObjType, dwID)
	local nType = 0
	if nObjType ==  OBJ_TYPE.DOODAD then
		nType = 1
	elseif nObjType == OBJ_TYPE.NPC then
		nType = 2
	end
	if nType == 0 then return false end
	local tLine = g_tTable.AutoSearchPriority:Search(nType, dwID)
	if tLine then
		return true
	else
		return false
	end
end

function Table_GetMessageBoxProInfo(dwID)
    local tLine = g_tTable.MessageBoxPro:Search(dwID)
    return tLine
end

function Table_GetActivityCollectInfoByID(nActivityID)
    local tLine = g_tTable.ActivityCollectInfo:Search(nActivityID)
    return tLine
end

function Table_GetActivityGetRewardlInfoByID(nActivityID)
    local tLine = g_tTable.ActivityGetRewardlInfo:Search(nActivityID)
    return tLine
end

function Table_GetActivityCollectInfoList(nActivityID)
	local tbList = {}
    local nCount = g_tTable.ActivityCollectItem:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.ActivityCollectItem:GetRow(i)
		if tLine and nActivityID == tLine.nActivityID then
			table.insert(tbList, tLine)
		end
	end
	return tbList
end

function Table_GetEatingQuickKungFuListByID(dwID)
	local tLine = g_tTable.EatingQuick_Item:Search(dwID)
	if tLine then
		tLine.tKungFu = {}
		for k, v in pairs(tLine.szKungFu:split(";", true)) do
			table.insert(tLine.tKungFu, tonumber(v))
		end

		return tLine.tKungFu
	end
end

local _EatingItems
function Table_GetEatingItem(dwType, dwIndex)
	if not _EatingItems then
		_EatingItems = {}
		local nCount = g_tTable.EatingQuick_Item:GetRowCount()
		for i = 2, nCount do
			local tLine = g_tTable.EatingQuick_Item:GetRow(i)
			if tLine then
				_EatingItems[tLine.dwTabType] = _EatingItems[tLine.dwTabType] or {}
				_EatingItems[tLine.dwTabType][tLine.dwIndex] = tLine
			end
		end
	end
	return _EatingItems[dwType] and _EatingItems[dwType][dwIndex]
end

function Table_GetMountKungfuByForce(dwForceID)
    local tRes = {}
    local nCount = g_tTable.MainKungfuInfo:GetRowCount()
    for i = 1, nCount do
        local tLine = g_tTable.MainKungfuInfo:GetRow(i)
        if tLine and tLine.nForceID == dwForceID then
            table.insert(tRes, tLine)
        end
    end
    return tRes
end

function Table_GetEatingQuickSlotInfo()
    local tRes = {}
    local nCount = g_tTable.EatingQuick_Slot:GetRowCount()
    for i = 2, nCount do
        local tLine = g_tTable.EatingQuick_Slot:GetRow(i)
		table.insert(tRes, tLine)
    end
    return tRes
end

function Table_GetEatingQuickItemInfo()
    local tRes = {}
    local nCount = g_tTable.EatingQuick_Item:GetRowCount()
    for i = 2, nCount do
        local tLine = g_tTable.EatingQuick_Item:GetRow(i)
        if tLine then
			tLine.tSlot = {}
			tLine.tKungFu = {}
			for k, v in pairs(tLine.szSlot:split(";", true)) do
				table.insert(tLine.tSlot, tonumber(v))
			end
			for k, v in pairs(tLine.szKungFu:split(";", true)) do
				table.insert(tLine.tKungFu, tonumber(v))
			end
			if tLine.szShowBuff ~= "" then
				tLine.tShowBuff = {}
				for nBuffID, nLevel in string.gmatch(tLine.szShowBuff, "([%d]+);([%d]+)|?") do
					local tTemp = {dwID = tonumber(nBuffID), nLevel = tonumber(nLevel)}
					table.insert(tLine.tShowBuff, tTemp)
				end
			end
			table.insert(tRes, tLine)
        end
    end
    return tRes
end

function Table_GetEatingQuickItemByID(dwID)
	local tLine = g_tTable.EatingQuick_Item:Search(dwID)
	if tLine then
		tLine.tSlot = {}
		tLine.tKungFu = {}
		for k, v in pairs(tLine.szSlot:split(";", true)) do
			table.insert(tLine.tSlot, tonumber(v))
		end
		for k, v in pairs(tLine.szKungFu:split(";", true)) do
			table.insert(tLine.tKungFu, tonumber(v))
		end
		if tLine.szShowBuff ~= "" then
			tLine.tShowBuff = {}
			for nBuffID, nLevel in string.gmatch(tLine.szShowBuff, "([%d]+);([%d]+)|?") do
				local tTemp = {dwID = tonumber(nBuffID), nLevel = tonumber(nLevel)}
				table.insert(tLine.tShowBuff, tTemp)
			end
		end

		return tLine
	end
end

function Table_GetTreasureBalanceBuff(dwMKungfuID)
    local nCount = g_tTable.TreasureBalanceBuff:GetRowCount()
    for i = 2, nCount do
        local tLine = g_tTable.TreasureBalanceBuff:GetRow(i)
        if tLine.dwMKungfuID == dwMKungfuID then
            return tLine
        end
    end
end

function Table_GetInstrumentKeyInfo(szType)
	local tRes = {}
	local nCount = g_tTable.InstrumentKey:GetRowCount()
	for i = 1, nCount do
		local tLine = g_tTable.InstrumentKey:GetRow(i)
		if tLine.szType == szType and tLine.bShow then
			if not tRes[tLine.szWndType] then
				tRes[tLine.szWndType] = {}
			end
			table.insert(tRes[tLine.szWndType], tLine)
		end
	end
	return tRes
end

function Table_GetInstrumentPlayInfo(szType)
	local tRes = {}
	local nCount = g_tTable.InstrumentPlay:GetRowCount()
	for i = 1, nCount do
		local tLine = g_tTable.InstrumentPlay:GetRow(i)
		if tLine.szType == szType then
			table.insert(tRes, tLine)
		end
	end
	return tRes
end

function Table_GetInstrumentPathInfo(szType)
	local tRes = {}
	local nCount = g_tTable.InstrumentPath:GetRowCount()
	for i = 1, nCount do
		local tLine = g_tTable.InstrumentPath:GetRow(i)
		if tLine.szType == szType then
			tRes[tLine.szIni] = tLine.szPath
		end
	end
	return tRes
end

function Table_GetInstrumentName(szType)
	local nCount = g_tTable.InstrumentName:GetRowCount()
	for i = 1, nCount do
		local tLine = g_tTable.InstrumentName:GetRow(i)
		if tLine.szType == szType then
			return tLine.szName
		end
	end
	return ""
end


function Table_GetShareStationReportReason()
    local tRes = {}
    local nCount = g_tTable.ShareStationReportReason:GetRowCount()
	for i = 1, nCount do
		local tLine = g_tTable.ShareStationReportReason:GetRow(i)
		table.insert(tRes, tLine)
	end
	return tRes
end

function Table_GetTipItemList()
	local tRes = {}
	local nCount = g_tTable.TipItem:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.TipItem:GetRow(i)
		table.insert(tRes, tLine)
	end
	return tRes
end

function Table_GetTipItemInfo(nItemID)
    local tLine = g_tTable.TipItem:Search(nItemID)
    return tLine
end

function Table_GetWXPuppetList()
    local tRes = {}
    local nCount = g_tTable.WXPuppet:GetRowCount()
    for i = 2, nCount do
        local tLine = g_tTable.WXPuppet:GetRow(i)
        table.insert(tRes, tLine)
    end
    return tRes
end

function Table_GetSelfieActionInfo(dwAnimationID)
	local tRes = {}
    local tLine = g_tTable.SelfieActionFilter:Search(dwAnimationID)
	if not tLine then
		return
	end
	tRes = {
		dwAnimationID = tLine.dwAnimationID,
		szAnimationFile = tLine.szAnimationFile,
		bSkillSkin = tLine.bSkillSkin,
	}

	local tLogicID = {}
	for i = 1, 3 do
		local szType = "nType" .. i
		local szLogic = "szLogicID" .. i
		if tLine[szType] and tLine[szLogic] and tLine[szType] ~= 0 and tLine[szLogic] ~= "" then
			local nType = tLine[szType]
			if not tLogicID[nType] then
				tLogicID[nType] = {}
			end
			local t = SplitString(tLine[szLogic], ";")
			for k, v in ipairs(t) do
				table.insert(tLogicID[nType], tonumber(v))
			end
		end
	end
	tRes.tLogicID = tLogicID

	local tAndLogic = {}
	if tLine.szAndLogicIDGroup and tLine.szAndLogicIDGroup ~= "" then
		local t = SplitString(tLine.szAndLogicIDGroup, "|")
		for k, szGroup in ipairs(t) do
			local tGroup = {}
			for nType, dwLogicID in string.gmatch(szGroup, "([%d]+):([%d]+);?") do
				local nType = tonumber(nType)
				local dwLogicID = tonumber(dwLogicID)
				tGroup[nType] = tGroup[nType] or {}
				table.insert(tGroup[nType], dwLogicID)
			end
			table.insert(tAndLogic, tGroup)
		end
	end
	tRes.tAndLogic = tAndLogic
    return tRes
end

function Table_GetSellDyeingItemInfo(dwCostType)
    local tLine = g_tTable.SellDyeingItem:Search(dwCostType)
    return tLine
end

function Table_GetDyeingHairColorInfo(dwColorID)
    local tLine = g_tTable.DyeingHairColor:Search(dwColorID)
    return tLine
end

function Table_GetDyeingHairCostTypeInfo(dwCostType)
	local nCount = g_tTable.DyeingHairColor:GetRowCount()
    for i = 2, nCount do
        local tLine = g_tTable.DyeingHairColor:GetRow(i)
        if tLine.dwCostType == dwCostType then
            return tLine
        end
    end
    return nil
end

function Table_GetDyeingDecorationColorInfo(dwColorID)
    local tLine = g_tTable.DyeingDecorationColor:Search(dwColorID)
    return tLine
end

function Table_GetHorseExteriorList()
	local tRes = {}
	local nCount = g_tTable.HorseExterior:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.HorseExterior:GetRow(i)
		local tszItem = SplitString(tLine.szSourceItemInfo, "|")
		local tItem = {}
		for k, v in pairs(tszItem) do
			local tTemp = SplitString(v, ";")
			local tItemTemp = {nType = tonumber(tTemp[1]), dwIndex = tonumber(tTemp[2])}
			table.insert(tItem, tItemTemp)
		end
		tLine.tItem = tItem
		table.insert(tRes, tLine)
	end
	return tRes
end

function Table_GetHorseExteriorByIndex(nIndex)
	if nIndex == 0 then
		return nil
	end
	local tLine = g_tTable.HorseExterior:Search(nIndex)
	local tszItem = SplitString(tLine.szSourceItemInfo, "|")
	local tItem = {}
	for k, v in pairs(tszItem) do
		local tTemp = SplitString(v, ";")
		local tItemTemp = {nType = tonumber(tTemp[1]), dwIndex = tonumber(tTemp[2])}
		table.insert(tItem, tItemTemp)
	end
	tLine.tItem = tItem
	return tLine
end

function Table_GetWLBeastClassByID(dwClassID)
	local tLine = g_tTable.WLBeastClass:Search(dwClassID)
	return tLine
end

function Table_GetWLBeastClass()
	local tRes = {}
	local nCount = g_tTable.WLBeastClass:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.WLBeastClass:GetRow(i)
		if tLine and tLine.dwID then
			tRes[tLine.dwID] = tLine
		end
	end
	return tRes
end

function Table_GetWLBeastInfoByClassID(dwClassID)
	local tRes = {}
	local nCount = g_tTable.WLBeastInfo:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.WLBeastInfo:GetRow(i)
		if tLine.dwClass == dwClassID then
			table.insert(tRes, tLine)
		end
	end
	return tRes
end

function Table_GetCDMonitorForce(dwKungfuType)
	local nCount = g_tTable.CDMonitorForce:GetRowCount()
	local tRes = {}
	for i = 2, nCount do
		local tLine = g_tTable.CDMonitorForce:GetRow(i)
		if tLine.dwKungfuType == dwKungfuType then
			table.insert(tRes, tLine)
		end
	end
	return tRes
end

function Table_GetMiniGameInfo(dwGameID)
	if not dwGameID then
		return
	end
	local tInfo = g_tTable.MiniGameInfo:Search(dwGameID)
	return tInfo
end

function Table_GetMapExploreInfo(dwMapID)
	local tRes = {}
	local nCount = g_tTable.MapExplore:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.MapExplore:GetRow(i)
		if tLine.dwMapID == dwMapID then
			table.insert(tRes, tLine)
		end
	end
	return tRes
end

function Table_GetMapExploreTypeByID(dwID)
	local nCount = g_tTable.MapExplore:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.MapExplore:GetRow(i)
		if tLine and tLine.dwID == dwID then
			return tLine
		end
	end
end

function Table_GetAllMapExploreType()
	local tRes = {}
	local nCount = g_tTable.MapExploreType:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.MapExploreType:GetRow(i)
		if tLine and tLine.nType then
			tRes[tLine.nType] = tLine
		end
	end
	return tRes
end

function Table_GetMapExploreReward(dwMapID)
	local tRes = {}
	local nCount = g_tTable.MapExploreReward:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.MapExploreReward:GetRow(i)
		if tLine.dwMapID == dwMapID then
			if not tRes[tLine.nType] then
				tRes[tLine.nType] = {}
			end
			table.insert(tRes[tLine.nType], tLine)
		end
	end
	return tRes
end

function Table_GetJigsawInfo(nType)
	local tRes = {}
	local tInfo = g_tTable.JigsawConfig:Search(nType)
	tRes.tUIInfo = tInfo
	tRes.tPieces = {}

	local nCount = g_tTable.JigsawPiecesConfig:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.JigsawPiecesConfig:GetRow(i)
		if tLine.nType == nType then
			table.insert(tRes.tPieces, tLine)
		end
	end
	return tRes
end

function Table_GetAllPoetry()
	local tRes = {}
	local nCount = g_tTable.PoetryConfig:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.PoetryConfig:GetRow(i)
		table.insert(tRes, tLine)
	end
	return tRes
end

function Table_GetPoetryContent(nLevel)
	local tLine = g_tTable.PoetryContentConfig:Search(nLevel)
	return tLine
end

function Table_GetForceToSchoolList()
	local tRes = {}

	local nCount = g_tTable.ForceToSchool:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.ForceToSchool:GetRow(i)
		table.insert(tRes, clone(tLine))
	end

	return tRes
end

function Table_GetBuffMonitorBuffSkinInfo(dwBuffID)
    local nCount = g_tTable.BuffMonitorBuffSkin:GetRowCount()
    for i = 2, nCount do
        local tLine = g_tTable.BuffMonitorBuffSkin:GetRow(i)
        if tLine and tLine.dwBuffID == dwBuffID then
            return tLine
        end
    end
end

function Table_GetGasConfig()
	local tRes = {}
	local nCount = g_tTable.GasConfig:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.GasConfig:GetRow(i)
		if tLine then
			if not tRes[tLine.dwMKungfuID] then
				tRes[tLine.dwMKungfuID] = {}
			end
			table.insert(tRes[tLine.dwMKungfuID], tLine)
		end
	end
	return tRes
end

function Table_GetFaceDecalsAdjustExpandV2Info(nRoleType, nType, nID)
    local tLine = g_tTable.FaceDecalsAdjustExpandV2:Search(nRoleType, nType, nID)
    return tLine
end

function Table_GetAllKillFeed()
    local tRes = {}
    local nCount = g_tTable.KillFeedConfig:GetRowCount()
    for i = 2, nCount do
        local tLine = g_tTable.KillFeedConfig:GetRow(i)
        table.insert(tRes, tLine)
    end
    return tRes
end

function Table_GetKillFeedConfig(dwEffectID)
    local nCount = g_tTable.KillFeedConfig:GetRowCount()
    for i = 2, nCount do
        local tLine = g_tTable.KillFeedConfig:GetRow(i)
        if tLine and tLine.dwEffectID == dwEffectID then
            return tLine
        end
    end
end

function Table_GetSpecialActivityType()
	local tRes = {}
	local nCount = g_tTable.SpecialActivityType:GetRowCount()
	for i = 2, nCount do
		local tLine = clone(g_tTable.SpecialActivityType:GetRow(i))
		if tLine then
			tLine.nStartTime = Time_AddZone(tLine.nStartTime)
			tLine.nEndTime = Time_AddZone(tLine.nEndTime)
			table.insert(tRes, tLine)
		end
	end
	return tRes
end

function Table_GetSpecialActivityInfo()
	local tRes = {}
	local nCount = g_tTable.SpecialActivityInfo:GetRowCount()
	for i = 2, nCount do
		local tLine = clone(g_tTable.SpecialActivityInfo:GetRow(i))
		if tLine then
			tLine.nStartTime = Time_AddZone(tLine.nStartTime)
			tLine.nEndTime = Time_AddZone(tLine.nEndTime)
			table.insert(tRes, tLine)
		end
	end
	return tRes
end

function Table_GetSelfieCameraAniList()
    local tRes = {}
    local nCount = g_tTable.SelfieCameraAniData:GetRowCount()
    for i = 2, nCount do
		local tLine = g_tTable.SelfieCameraAniData:GetRow(i)
        table.insert(tRes, tLine)
	end
    return tRes
end

function Table_GetSelfieCameraAniData(nCameraAniID)
    local nCount = g_tTable.SelfieCameraAniData:GetRowCount()
    for i = 2, nCount do
		local tLine = g_tTable.SelfieCameraAniData:GetRow(i)
        if tLine.nCameraAniID == nCameraAniID then
            return tLine
        end
	end
end

function Table_GetFullScreenShopPic(nItemType, nItemIndex)
	local tLine = g_tTable.FullScreenShopPic:Search(nItemType, nItemIndex)
	if not tLine then
		return g_tTable.FullScreenShopPic:Search(8, 36201)
	end
	return tLine
end

function Table_GetPendantEffectRepresentID(dwEffectID)
    local tLine = g_tTable.PendantEffect:Search(dwEffectID)
	if not tLine then
		return
	end
    return tLine.dwRepresentID
end

function Table_GetFullScreenShopSkin(nSkinID)
	local tLine = g_tTable.FullScreenShopSkin:Search(nSkinID)
	if not tLine then
		return
	end
	local tShopMenu = SplitString(tLine["ShopMenuAnimation"], "|")
	for i = 1, #tShopMenu do
		tShopMenu[i] = tonumber(tShopMenu[i])
	end
	tLine.tShopMenu = tShopMenu
	local tShopCBox = SplitString(tLine["ShopCBoxAnimation"], "|")
	for i = 1, #tShopCBox do
		tShopCBox[i] = tonumber(tShopCBox[i])
	end
	tLine.tShopCBox = tShopCBox
	local tLogoInfo = SplitString(tLine["szLogoInfo"], "|")
	tLogoInfo[2] = tonumber(tLogoInfo[2])
	tLine.tLogoInfo = tLogoInfo
	local tTitleInfo = SplitString(tLine["szTitleInfo"], "|")
	tTitleInfo[2] = tonumber(tTitleInfo[2])
	tLine.tTitleInfo = tTitleInfo
	return tLine
end

function Table_GetFullScreenShopCBox(dwID)
	local tLine = g_tTable.FullScreenShopCBox:Search(dwID)
	if not tLine then
		return
	end
	return tLine
end

function Table_GetFullScreenShopBtn(dwID)
	local tLine = g_tTable.FullScreenShopBtn:Search(dwID)
	if not tLine then
		return
	end
	return tLine
end

local function ParseNumberValueList(szPoint)
	local tList = {}
	if not szPoint or szPoint == "" then
		return tList
	end
	for szIndex in string.gmatch(szPoint, "([%-%d%.]+)") do
		local nPoint = tonumber(szIndex)
		if nPoint then
			table.insert(tList, nPoint)
		end
	end
	return tList
end

local function FormatFullScreenCameraLine(tLine)
	if not tLine or tLine.bFormatFullScreenCamera then
		return tLine
	end

	tLine.tPos = ParseNumberValueList(tLine.szPos)
	tLine.tLookAt = ParseNumberValueList(tLine.szLookAt)
	tLine.tCenter = ParseNumberValueList(tLine.szCenter)
	tLine.tRadius = ParseNumberValueList(tLine.szRadius)
	return tLine
end

function Table_GetFullScreenCamera(dwCamID)
	local tLine = g_tTable.FullScreenCamera:Search(dwCamID)
	if not tLine then
		return
	end
	return FormatFullScreenCameraLine(tLine)
end

local function FormatFullScreenSceneLine(tLine)
	if not tLine or tLine.bFormatFullScreenScene then
		return tLine
	end

	tLine.fPrefabScale = tLine.fPrefabScale
	tLine.fRideScale = tLine.fRideScale
	tLine.fSinglePendantScale = tLine.fSinglePendantScale
	tLine.tPrefabPos = ParseNumberValueList(tLine.szPrefabPos)
	tLine.tHorAngle = ParseNumberValueList(tLine.szHorAngle)
	tLine.tVerAngle = ParseNumberValueList(tLine.szVerAngle)
	tLine.tRolePos = ParseNumberValueList(tLine.szRolePos)
	tLine.tRidePos = ParseNumberValueList(tLine.szRidePos)
	tLine.tSinglePendantPos = ParseNumberValueList(tLine.szSinglePendantPos)
	tLine.tStandareMaleCam = Table_GetFullScreenCamera(tLine.dwStandareMaleCamID)
	tLine.tStandareFemaleCam = Table_GetFullScreenCamera(tLine.dwStandareFemaleCamID)
	tLine.tStrongMaleCam = Table_GetFullScreenCamera(tLine.dwStrongMaleCamID)
	tLine.tSexyFemaleCam = Table_GetFullScreenCamera(tLine.dwSexyFemaleCamID)
	tLine.tLittleBoyCam = Table_GetFullScreenCamera(tLine.dwLittleBoyCamID)
	tLine.tLittleGirlCam = Table_GetFullScreenCamera(tLine.dwLittleGirlCamID)
	tLine.tRideCam = Table_GetFullScreenCamera(tLine.dwRideCamID)
	tLine.tSinglePendantCam = Table_GetFullScreenCamera(tLine.dwSinglePendantCamID)
	tLine.tStandareMaleHairCam = Table_GetFullScreenCamera(tLine.dwStandareMaleHairCamID)
	tLine.tStandareFemaleHairCam = Table_GetFullScreenCamera(tLine.dwStandareFemaleHairCamID)
	tLine.tStrongMaleHairCam = Table_GetFullScreenCamera(tLine.dwStrongMaleHairCamID)
	tLine.tSexyFemaleHairCam = Table_GetFullScreenCamera(tLine.dwSexyFemaleHairCamID)
	tLine.tLittleBoyHairCam = Table_GetFullScreenCamera(tLine.dwLittleBoyHairCamID)
	tLine.tLittleGirlHairCam = Table_GetFullScreenCamera(tLine.dwLittleGirlHairCamID)
	return tLine
end

function Table_GetFullScreenScene(dwID)
	local tLine = g_tTable.FullScreenScene:Search(dwID)
	if not tLine then
		return
	end
	return FormatFullScreenSceneLine(tLine)
end

function Table_GetArenaTowerRound(nIndex)
    local tLine = g_tTable.ArenaTowerRoundList:Search(nIndex)
    if not tLine then
        return
    end
    return tLine
end

function Table_GetArenaTowerCard(nCardID)
    local tLine = g_tTable.ArenaTowerCardList:Search(nCardID)
    if not tLine then
        return
    end
    return tLine
end

function Table_GetArenaTowerOtherCard(nCardID)
    local tLine = g_tTable.ArenaTowerOtherCardList:Search(nCardID)
    if not tLine then
        return
    end
    return tLine
end

function Table_GetArenaTowerElementInfo(nIndex)
    local tLine = g_tTable.ArenaTowerElementInfo:Search(nIndex)
    if not tLine then
        return
    end
    return tLine
end

function Table_GetQMSoulInfoByNpcID(dwNpcID)
	local tLine = g_tTable.QMSoul:Search(dwNpcID)
	return tLine
end

function Table_GetSkillQixueDouqiInfo(nKungfuID)
	local tLine = g_tTable.SkillQixueDouqi:Search(nKungfuID)
	return tLine
end

function Table_GetAllDesignationDecorationList()
    local tList = {}
    local nCount = g_tTable.DesignationDecoration:GetRowCount()
    for i = 2, nCount do
        local tLine = g_tTable.DesignationDecoration:GetRow(i)
        table.insert(tList, tLine)
    end
    return tList
end

function Table_GetDesignationDecorationInfo(dwID)
    local tLine = g_tTable.DesignationDecoration:Search(dwID)
    return tLine
end

function Table_GetSelfieBGMList()
    local tRes = {}
	local nCount = g_tTable.SelfieBGM:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.SelfieBGM:GetRow(i)
		table.insert(tRes, tLine)
	end
	return tRes
end

function Table_GetSelfieBGMInfo(nBGMID)
    local tLine = g_tTable.SelfieBGM:Search(nBGMID)
    return tLine
end

function Table_GetSelfieBGMEvent(nBGMID)
    local tLine = g_tTable.SelfieBGM:Search(nBGMID)
	return tLine.szBgmEvent
end

function Table_GetSelfieBGMTime(nBGMID)
    local tLine = g_tTable.SelfieBGM:Search(nBGMID)
    if tLine then
        return tLine.nTime
    end
end

function Table_GetCurrencyInfo()
	local tRes = {}
	local nCount = g_tTable.CurrencyInfo:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.CurrencyInfo:GetRow(i)
		if tLine then
			table.insert(tRes, tLine)
		end
	end
	return tRes
end

function Table_GetCurrencyInfoByIndex(szCurrencyIndex)
	if not szCurrencyIndex then
		return
	end

	local nCount = g_tTable.CurrencyInfo:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.CurrencyInfo:GetRow(i)
		if tLine and tLine.szName == szCurrencyIndex then
			return tLine
		end
	end
end

function Table_GetCurrencySourceList(szCurrencyIndex)
	if not szCurrencyIndex then
		return
	end

	local nCount = g_tTable.CurrencyInfo:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.CurrencyInfo:GetRow(i)
		if tLine and tLine.szName == szCurrencyIndex then
			if tLine then
				local tSource = Table_GetItemSourceList(nil, nil, nil, tLine)
				return tSource
			end
		end
	end
end

-- 解析 CurrencyInfo.szShopUseLink（格式："groupID;default|groupID;default"）
-- 返回 {{dwGroupID, dwDefault, szGroupName}, ...}，供货币tip使用途径显示
function Table_GetCurrencyShopUseList(szCurrencyIndex)
	if not szCurrencyIndex then
		return
	end

	local nCount = g_tTable.CurrencyInfo:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.CurrencyInfo:GetRow(i)
		if tLine and tLine.szName == szCurrencyIndex then
			if not tLine.szShopUseLink or tLine.szShopUseLink == "" then
				return
			end
			local tResult = {}
			for _, szGroup in ipairs(SplitString(tLine.szShopUseLink, "|")) do
				local tParts = SplitString(szGroup, ";")
				local dwGroupID = tonumber(tParts[1])
				local dwDefault = tonumber(tParts[2]) or 0
				if dwGroupID then
					-- 优先用 SystemShopDetail 的精确商店名，找不到时回退到 GroupName
					local szShopName = ""
					if dwDefault > 0 then
						local tShop = Table_GetSystemShopByID(dwGroupID, dwDefault)
						if tShop then
							szShopName = tShop.szShopName or ""
						end
					end
					if szShopName == "" then
						local tGroupLine = g_tTable.SystemShopGroup:Search(dwGroupID)
						szShopName = tGroupLine and tGroupLine.szGroupName1 or ""
					end
					table.insert(tResult, {
						dwGroupID   = dwGroupID,
						dwDefault   = dwDefault,
						szShopName  = szShopName,
					})
				end
			end
			return #tResult > 0 and tResult or nil
		end
	end
end

function Table_GetOperationCategory()
    local tTab    = g_tTable.OperationCategory
    local nCount  = tTab:GetRowCount()
    local tResult = {}
    for i = 2, nCount do
        local tLine = tTab:GetRow(i)
        table.insert(tResult, tLine)
    end
    return tResult
end

function Table_GetSimpleOperationConfigByID(dwID)
	local nCount = g_tTable.SimpleOperationConfig:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.SimpleOperationConfig:GetRow(i)
		if tLine and tLine.dwID == dwID then
			return tLine
		end
	end
end

function Table_GetPersonalCardBoxMoney(nIndex)
	local tLine = g_tTable.PersonalCardBoxMoney:Search(nIndex)
	return tLine
end

function Table_GetSignInReward(dwID)
	local tRes = {}
	local nCount = g_tTable.SignInReward:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.SignInReward:GetRow(i)
		if tLine.dwID == dwID then
			local t = {}
			local tItemList = SplitString(tLine.szReward, ";")
			for _, v in pairs(tItemList) do
				local tt = SplitString(v, "_")
				table.insert(t, {dwType = tonumber(tt[1]), dwIndex = tonumber(tt[2]), nCount = tonumber(tt[3])})
			end
			tLine.tRewardList = t
			table.insert(tRes, tLine)
		end
	end
	return tRes
end

function Table_GetOperationShop()
	local res = {}

	local nCount = g_tTable.OperationShop:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.OperationShop:GetRow(i)
		table.insert(res, tLine)
	end

	return res
end

function Table_GetOperationShopByID(dwID)
	return g_tTable.OperationShop:Search(dwID)
end

function Table_GetOperationRewardPreview()
	local tRes = {}
	local nCount = g_tTable.OperationRewardPreview:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.OperationRewardPreview:GetRow(i)
		if tLine then
			table.insert(tRes, tLine)
		end
	end
	return tRes
end

function Table_GetTopmenuButton()
	local res = {}

	local nCount = g_tTable.TopmenuButton:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.TopmenuButton:GetRow(i)
		table.insert(res, tLine)
	end

	return res
end

function Table_GetGongZhanActInfo()
	local tResult = {}
	local nCount = g_tTable.GongZhanActInfo:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.GongZhanActInfo:GetRow(i)
		if tLine.nCategory and tLine.nCategory ~= 0 then
			if not tResult[tLine.nCategory] then
				tResult[tLine.nCategory] = {}
			end
			if tLine.szGuildID and tLine.szGuildID ~= "" then
				local tGuildID = {}
				for szID in string.gmatch(tLine.szGuildID, "[^;]+") do
					table.insert(tGuildID, tonumber(szID))
				end
				tLine.tGuildID = tGuildID
			else
				tLine.tGuildID = {}
			end
			tResult[tLine.nCategory][tLine.nType] = tLine
		end
	end
	return tResult
end

function Table_GetOperationCheckBox(dwID)
	local nCount = g_tTable.OperationCheckBox:GetRowCount()
	local nCheckBoxNum = 0
	local tComponent = {}
	for i = 2, nCount do
		local tLine = g_tTable.OperationCheckBox:GetRow(i)
		if tLine and tLine.dwID == dwID and tLine.nTabIndex > 0 then
			nCheckBoxNum = nCheckBoxNum + 1
			local szComponent = tLine.szComponent
			if szComponent and szComponent ~= "" then
				local tWidgets = SplitString(szComponent, ";")
				local tValid = {}
				for _, szWidget in ipairs(tWidgets) do
					szWidget = string.trim(szWidget, " ")
					if szWidget ~= "" then
						table.insert(tValid, szWidget)
					end
				end
				tComponent[tLine.nTabIndex] = tValid
			end
		end
	end
	if nCheckBoxNum == 0 then
		return nil
	end
	return {
		nCheckBoxNum = nCheckBoxNum,
		tComponent = tComponent,
	}
end

function Table_GetCheckBoxContent(dwID, nTabIndex)
	return g_tTable.OperationCheckBox:Search(dwID, nTabIndex)
end

function Table_GetSeasonUpdateOverview(dwID)
	local nCount = g_tTable.SeasonUpdateOverview:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.SeasonUpdateOverview:GetRow(i)
		if tLine and tLine.dwID == dwID then
			return tLine
		end
	end
end

function Table_GetFaceMotionInfo(dwID)
	local tLine = g_tTable.FaceMotion:Search(dwID)
	return tLine
end

function Table_GetRankInfoByLevel(nLevel)
	local nCount = g_tTable.RankInfo:GetRowCount()
	for i = 1, nCount do
		local tLine = g_tTable.RankInfo:GetRow(i)
		if tLine and tLine.nRankLv == nLevel then
			return tLine
		end
	end
end

function Table_GetRankInfo()
	local tRes = {}
	local nCount = g_tTable.RankInfo:GetRowCount()
	for i = 1, nCount do
		local tLine = g_tTable.RankInfo:GetRow(i)
		table.insert(tRes, tLine)
	end
	return tRes
end

function Table_GetDailyRewardInfo()
	local tRes = {}
	local nCount = g_tTable.GameGuideDailyReward:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.GameGuideDailyReward:GetRow(i)
		if tLine then
			table.insert(tRes, tLine)
		end
	end
	return tRes
end

function Table_GetSpecialItemPreview(nType, dwIndex)
	local tLine = g_tTable.SpecialItemPreview:Search(nType, dwIndex)
	if not tLine then
		return
	end
	return tLine
end

function Table_GetSeasonLevelActiveTaskConfig(nClass)
	local tRes = {}
	local nCount = g_tTable.SeasonLevelActiveTaskConfig:GetRowCount()
	for i = 1, nCount do
		local tLine = g_tTable.SeasonLevelActiveTaskConfig:GetRow(i)
		if tLine and (not nClass or tLine.nClass == nClass) then
			table.insert(tRes, tLine)
		end
	end
	table.sort(tRes, function(a, b)
		if a.nClass ~= b.nClass then
			return a.nClass < b.nClass
		end
		return a.nTaskID < b.nTaskID
	end)
	return tRes
end

function Table_GetSeasonHonorTaskConfig(nClass)
	local tRes = {}
	local nCount = g_tTable.SeasonHonorTaskConfig:GetRowCount()
	for i = 1, nCount do
		local tLine = g_tTable.SeasonHonorTaskConfig:GetRow(i)
		if tLine and (not nClass or tLine.nClass == nClass) then
			table.insert(tRes, tLine)
		end
	end
	table.sort(tRes, function(a, b)
		if a.nClass ~= b.nClass then
			return a.nClass < b.nClass
		end
		if a.nSort ~= b.nSort then
			return a.nSort < b.nSort
		end
		return a.nTaskID < b.nTaskID
	end)
	return tRes
end

function Table_GetSeasonHonorRewardConfig(nClass)
	local tRes = {}
	local nCount = g_tTable.SeasonHonorRewardConfig:GetRowCount()
	for i = 1, nCount do
		local tLine = g_tTable.SeasonHonorRewardConfig:GetRow(i)
		if tLine and (not nClass or tLine.nClass == nClass) then
			if tLine.szReward and tLine.szReward ~= "" then
				tLine.tReward = {}
				for dwTabType, dwIndex, nCount in string.gmatch(tLine.szReward, "([%d]+);([%d]+);([%d]+)|?") do
					tLine.tReward = {tonumber(dwTabType), tonumber(dwIndex), tonumber(nCount)}
				end
			end
			table.insert(tRes, tLine)
		end
	end
	table.sort(tRes, function(a, b)
		if a.nClass ~= b.nClass then
			return a.nClass < b.nClass
		end
		return a.nStage < b.nStage
	end)
	return tRes
end

function Table_GetBaizhanDbmByGroupID(nGroupID)
	local tRes = {}
	local nCount = g_tTable.BaiZhanDbmTab:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.BaiZhanDbmTab:GetRow(i)
		if tLine then
			local szGroupID = tLine.tbGroupID
			local tbGroupID = {}
			for numStr in string.gmatch(szGroupID, "%d+") do
    			local nId = tonumber(numStr)
				if nGroupID == nId then
					table.insert(tRes, tLine)
					break
				end
			end
		end
	end
	return tRes
end

function Table_GetBaizhanDbmByID(nID)
	local tLine = g_tTable.BaiZhanDbmTab:Search(nID)
	return tLine
end

function Table_GetRangeHoardSkill(dwSkillID)
	local tLine = g_tTable.Skill_Hoard_Range:Search(dwSkillID)
	return tLine
end

function Table_GetTaskInfoByKey(szKey)
	local nCount = g_tTable.SeasonLevelActiveTaskConfig:GetRowCount()
	for i = 1, nCount do
		local tLine = g_tTable.SeasonLevelActiveTaskConfig:GetRow(i)
		if tLine and tLine.szKey == szKey then
			return tLine
		end
	end
end

function Table_GetSeasonHonorInfoByKey(szKey)
	local nCount = g_tTable.SeasonHonorTaskConfig:GetRowCount()
	for i = 1, nCount do
		local tLine = g_tTable.SeasonHonorTaskConfig:GetRow(i)
		if tLine and tLine.szTaskKey == szKey then
			return tLine
		end
	end
end

-- 大富翁：读取初始身份配置表
function Table_GetMonopolyInitIdentityConfig()
	local res = {}

	local nCount = g_tTable.MonopolyInitIdentityConfig:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.MonopolyInitIdentityConfig:GetRow(i)
		table.insert(res, tLine)
	end

	return res
end

-- 大富翁：按身份 ID 查一行初始身份配置
function Table_GetMonopolyInitIdentityConfigByID(nIdentityID)
	return g_tTable.MonopolyInitIdentityConfig:Search(nIdentityID)
end

-- 大富翁：读取角色状态配置表
function Table_GetMonopolyStatusConfig()
	local res = {}

	local nCount = g_tTable.MonopolyStatusConfig:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.MonopolyStatusConfig:GetRow(i)
		table.insert(res, tLine)
	end

	return res
end

-- 大富翁：按类型和状态 ID 查一行状态配置
function Table_GetMonopolyStatusConfigByTypeID(nType, nID)
	return g_tTable.MonopolyStatusConfig:Search(nType, nID)
end

-- 大富翁：按状态 ID 查一行神仙时间小通知特效配置
function Table_GetMonopolyGodSFXByID(nGodID)
	return g_tTable.MonopolyGodSFX:Search(nGodID)
end

-- 大富翁：读取附属物配置表
function Table_GetMonopolyGridLayerConfig()
	local res = {}

	local nCount = g_tTable.MonopolyGridLayerConfig:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.MonopolyGridLayerConfig:GetRow(i)
		table.insert(res, tLine)
	end

	return res
end

-- 大富翁：按附属物 ID 查一行附属物配置
function Table_GetMonopolyGridLayerConfigByID(nLayerID)
	return g_tTable.MonopolyGridLayerConfig:Search(nLayerID)
end

-- 大富翁：读取地块信息配置表
function Table_GetMonopolyGridConfig()
	local res = {}

	local nCount = g_tTable.MonopolyGridConfig:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.MonopolyGridConfig:GetRow(i)
		table.insert(res, tLine)
	end

	return res
end

-- 大富翁：按地块 ID 查一行地块信息配置
function Table_GetMonopolyGridConfigByID(nGridID)
	return g_tTable.MonopolyGridConfig:Search(nGridID)
end

function Table_GetMonopolyCardInfoByID(dwID)
	return g_tTable.MonopolyCardInfo:Search(dwID)
end

function Table_GetMonopolyFateEventByID(dwID)
	return g_tTable.MonopolyFateEvent:Search(dwID)
end

function Table_GetMonopolyFateResultByID(dwEventID, dwResultID)
	return g_tTable.MonopolyFateEventResult:Search(dwEventID, dwResultID)
end

function Table_GetMonopolyGridInfo(dwLevel)
	return g_tTable.MonopolyGridInfo:Search(dwLevel)
end

function Table_GetSeasonReward(szShowType)
	local tList = {}

	local nCount = g_tTable.SeasonReward:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.SeasonReward:GetRow(i)
		if tLine.szShowType == szShowType then
			table.insert(tList, tLine)
		end
	end

	return tList
end

function Table_GetOperationOrangeWeaponInfo(dwID)
	local tRes = {}
	local nCount = g_tTable.OperationOrangeWeapon:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.OperationOrangeWeapon:GetRow(i)
		if tLine and tLine.dwID == dwID then
			table.insert(tRes, tLine)
		end
	end
	return tRes
end
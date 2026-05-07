local UIDungeonDetailView = class("UIDungeonDetailView")

local FILTER_TYPE = {
	FORCE = 1,
	KUNGFU = 2,
}

function UIDungeonDetailView:OnEnter(tRecord)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo(tRecord)
end

function UIDungeonDetailView:OnExit()
    self.bInit = false

	if self.hModelView then
		self.hModelView:release()
		self.hModelView = nil
	end
	FilterDef.BossDropDetail.Reset()
	UITouchHelper.UnBindModel()
end

function UIDungeonDetailView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
		UIMgr.Close(VIEW_ID.PanelDungeonInfo)
	end)

	UIHelper.BindUIEvent(self.TogArticle, EventType.OnSelectChanged, function (_, bSelected)
		UIHelper.SetVisible(self.BtnFilter, bSelected)
		if not bSelected then UIHelper.SetVisible(self.WidgetItemTipShell, false) end
	end)

	UIHelper.BindUIEvent(self.BtnFilter, EventType.OnClick, function()
		local _, scriptView = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetFiltrateTip, self.BtnFilter, FilterDef.BossDropDetail)
		self.scriptFilter = scriptView
		self:RefreshFilter()
		self.scriptFilter:Refresh()
	end)

	UIHelper.BindUIEvent(self.BtnBossHeadPointLeft, EventType.OnClick, function()
		local nSize = #self.tCurBoss.tNpcList
		local nLastNpcIndex = self.tCurBoss.tNpcList[nSize]
		for _,nNpcIndex in ipairs(self.tCurBoss.tNpcList) do			
			if self.nCurNpcIndex == nNpcIndex then
				break
			end
			nLastNpcIndex = nNpcIndex
		end
		if not nLastNpcIndex then
			return
		end

		if nLastNpcIndex == self.nCurNpcIndex then
			return
		end
		self.nCurNpcIndex = nLastNpcIndex
		self:UpdateBossHeadPoint()
		self:UpdateNPCInfo()
		self:UpdateNPCModel()
	end)

	UIHelper.BindUIEvent(self.BtnBossHeadPointRight, EventType.OnClick, function()
		local nNextNpcIndex
		local bFound = false
		for _,nNpcIndex in ipairs(self.tCurBoss.tNpcList) do
			if bFound then
				nNextNpcIndex = nNpcIndex
				break
			end
			if self.nCurNpcIndex == nNpcIndex then
				bFound = true
			end
		end

		local nSize = #self.tCurBoss.tNpcList
		if not nNextNpcIndex then
			nNextNpcIndex = self.tCurBoss.tNpcList[nSize]
		end

		if nNextNpcIndex == self.nCurNpcIndex then
			if nNextNpcIndex == self.tCurBoss.tNpcList[1] then
				nNextNpcIndex = self.tCurBoss.tNpcList[nSize]
			elseif nNextNpcIndex == self.tCurBoss.tNpcList[nSize] then
				nNextNpcIndex = self.tCurBoss.tNpcList[1]
			end
		end

		if nNextNpcIndex == self.nCurNpcIndex then
			return
		end
		self.nCurNpcIndex = nNextNpcIndex
		self:UpdateBossHeadPoint()
		self:UpdateNPCInfo()
		self:UpdateNPCModel()
	end)
end

function UIDungeonDetailView:RegEvent()
    Event.Reg(self, EventType.OnDungeonBossItemSelectChanged, function (tBoss)
        self.tCurBoss = tBoss
		self.nCurNpcIndex = self.tCurBoss.tNpcList[1]
		self.tDropList = nil
        self:UpdateBossDetailInfo()
		UIHelper.SetVisible(self.WidgetItemTipShell, false)
    end)

	Event.Reg(self, EventType.OnTouchViewBackGround, function()
		if self.scriptItemTip then
			self.scriptItemTip:OnInit()
		end
    end)

	Event.Reg(self, "ON_HIDEMINISCENE_UNTILNEWVIEWCLOSE", function()
        UIHelper.TempHideMiniSceneUntilNewViewClose(self, self.MiniScene, self.hModelView, VIEW_ID.PanelOutfitPreview, function()
            UITouchHelper.BindModel(self.TouchBackground, self.hModelView)
        end)
    end)

	Event.Reg(self, "ON_HIDEMINISCENE_UNTILNEWPETVIEWCLOSE", function()
        UIHelper.TempHideMiniSceneUntilNewViewClose(self, self.MiniScene, self.hModelView, VIEW_ID.PanelPetMap, function()
            UITouchHelper.BindModel(self.TouchBackground, self.hModelView)
        end)
    end)

	Event.Reg(self, EventType.OnFilter, function (szKey, tbFilter , nLastChoosedIndex, nLastChoosedSubIndex)
		if szKey == FilterDef.BossDropDetail.Key then
			self.tbSelected = tbFilter
			self:UpdateBossDropPage()
        end
    end)

	Event.Reg(self, EventType.OnFilterSelectChanged, function (szKey, tbFilter)
		if szKey == FilterDef.BossDropDetail.Key then
			self.tbSelected = tbFilter
			self:RefreshFilter()
			if self.scriptFilter then
				self.scriptFilter:Refresh()
			end
        end
    end)
end

function UIDungeonDetailView:UpdateInfo(tRecord)
    self.tRecord = tRecord
    local szName = tRecord.szName
    UIHelper.SetString(self.LabelTitle, szName)

    self:UpdateBossList()
end

function UIDungeonDetailView:UpdateBossList()
    local tRecord = self.tRecord

    UIHelper.RemoveAllChildren(self.LayoutBossList)
    local tBossList = Table_GetDungeonBoss(tRecord.dwMapID)

	for i, tBoss in ipairs(tBossList) do
		local bSelected = tRecord.dwDefaultBossIndex and tRecord.dwDefaultBossIndex == tBoss.dwIndex
		bSelected = bSelected or (not tRecord.dwDefaultBossIndex and i == 1)
		UIHelper.AddPrefab(PREFAB_ID.WidgetDungeonBossItem, self.LayoutBossList, tBoss, bSelected)
	end

    UIHelper.ScrollViewDoLayout(self.ScrollViewBossList)
    UIHelper.ScrollToTop(self.ScrollViewBossList, 0)
	UIHelper.SetSwallowTouches(self.ScrollViewBossList, false)
end

function UIDungeonDetailView:UpdateBossDetailInfo()
	self:UpdateBossHeadPoint()
    self:UpdateNPCInfo()
    self:UpdateNPCModel()
	self:GenerateFilter()
    self:UpdateBossDropPage()
    self:UpdateBossSkillPage()
    self:UpdateBossStoryPage()
end

function UIDungeonDetailView:UpdateBossHeadPoint()
	UIHelper.SetVisible(self.WidgetAnchorBoss, #self.tCurBoss.tNpcList > 1)
	UIHelper.SetVisible(self.ScrollViewBoss, #self.tCurBoss.tNpcList > 6)
	UIHelper.SetVisible(self.LayoutBossHeadPoint, #self.tCurBoss.tNpcList <= 6)
	
	if #self.tCurBoss.tNpcList > 6 then
		UIHelper.RemoveAllChildren(self.ScrollViewBoss)

		local nFirstNpcIndex
		for _,nNpcIndex in ipairs(self.tCurBoss.tNpcList) do
			local bSelected = (not self.nCurNpcIndex and not nFirstNpcIndex) or (self.nCurNpcIndex and self.nCurNpcIndex == nNpcIndex)
			UIHelper.AddPrefab(PREFAB_ID.WidgetBossHeadPoint, self.ScrollViewBoss, bSelected, function ()
				self.nCurNpcIndex = nNpcIndex
				self:UpdateBossHeadPoint()
				self:UpdateNPCInfo()
				self:UpdateNPCModel()
			end)
			if not nFirstNpcIndex then
				nFirstNpcIndex = nNpcIndex
			end
		end
		if not self.nCurNpcIndex then
			self.nCurNpcIndex = nFirstNpcIndex
		end
		UIHelper.ScrollViewDoLayout(self.ScrollViewBoss)
		UIHelper.ScrollToLeft(self.ScrollViewBoss, 0)
	else
		UIHelper.RemoveAllChildren(self.LayoutBossHeadPoint)

		local nFirstNpcIndex
		for _,nNpcIndex in ipairs(self.tCurBoss.tNpcList) do
			local bSelected = (not self.nCurNpcIndex and not nFirstNpcIndex) or (self.nCurNpcIndex and self.nCurNpcIndex == nNpcIndex)
			local scriptPoint = UIHelper.AddPrefab(PREFAB_ID.WidgetBossHeadPoint, self.LayoutBossHeadPoint, bSelected, function ()
				self.nCurNpcIndex = nNpcIndex
				self:UpdateBossHeadPoint()
				self:UpdateNPCInfo()
				self:UpdateNPCModel()
			end)
			if not nFirstNpcIndex then
				nFirstNpcIndex = nNpcIndex
			end
			if scriptPoint then
				UIHelper.SetAnchorPoint(scriptPoint._rootNode, 0.5, 0.5)
			end
		end
		if not self.nCurNpcIndex then
			self.nCurNpcIndex = nFirstNpcIndex
		end
		UIHelper.LayoutDoLayout(self.LayoutBossHeadPoint)
	end
end

function UIDungeonDetailView:UpdateNPCInfo()
    local tNpcInfo = Table_GetDungeonBossModel(self.nCurNpcIndex)

    local szName = UIHelper.GBKToUTF8(tNpcInfo.szName)
    UIHelper.SetString(self.LabelBossName, szName)
	UIHelper.LayoutDoLayout(self.ImgBossNameBg)
end

function UIDungeonDetailView:UpdateNPCModel()
	local tNpcInfo = Table_GetDungeonBossModel(self.nCurNpcIndex)
    local tbConfig = Const.MiniScene.DungeonDetailView

	if not self.hModelView then
		self.hModelView = NpcModelView.CreateInstance(NpcModelView)
		self.hModelView:ctor()
		self.hModelView:init(nil, false, true, Const.COMMON_SCENE, "DungeonDetail")
		self.hModelView:SetCamera(tbConfig.CameraConfig)
		self.MiniScene:SetScene(self.hModelView.m_scene)
		if not QualityMgr.bDisableCameraLight then
			self.hModelView.m_scene:OpenCameraLight(QualityMgr.szCameraLightForUI)
		end
		self.hModelView.m_scene:SetMainPlayerPosition(unpack(tbConfig.ModelPos))
	end

	self.hModelView:LoadNpcRes(tNpcInfo.dwModelID, false)
	self.hModelView:UnloadModel()
	self.hModelView:LoadModel()
	self.hModelView:PlayAnimation("Idle", "loop")
	self.hModelView:SetTranslation(table.unpack(tbConfig.ModelPos))
	self.hModelView:SetYaw(tbConfig.fYaw)
	self.hModelView:SetScaling(tNpcInfo.fModelScaleMB)

	UITouchHelper.BindModel(self.TouchBackground, self.hModelView)
end

function UIDungeonDetailView:UpdateBossDropPage()
	local nForceIndex = self.tbSelected[FILTER_TYPE.FORCE][1]
	local nKungfuIndex = self.tbSelected[FILTER_TYPE.KUNGFU][1]
	local dwCurForceID = FilterDef.BossDropDetail[FILTER_TYPE.FORCE].tbValList[nForceIndex]
	local dwCurKungfuID = FilterDef.BossDropDetail[FILTER_TYPE.KUNGFU].tbValList[nKungfuIndex]
    UIHelper.RemoveAllChildren(self.ScrollViewArticle)
    local tDropList = self:GetBossEquip(self.tCurBoss.szName, self.tRecord.dwMapID, {},{})
    for nIndex, tDrop in ipairs(tDropList) do
        if #tDrop > 0 then
            local szTitle = g_tStrings.Dungeon.tEquipTitle[nIndex]
            UIHelper.AddPrefab(PREFAB_ID.WidgetDungeonNormalBar,self.ScrollViewArticle, szTitle)
			local scriptClass = UIHelper.AddPrefab(PREFAB_ID.WidgetDropItemClass, self.ScrollViewArticle,
				function(nTabType, nTabID, nItemParam) self:OnItemSelectChanged(nTabType, nTabID, nItemParam) end)
			if scriptClass then
				for _, tItem in ipairs(tDrop) do
					local tItemInfo = GetItemInfo(tItem[1], tItem[2])
					if tItemInfo then
						local szItemName = Table_GetItemName(tItemInfo.nUiId)
						if tItemInfo.nGenre == ITEM_GENRE.BOOK then
							local nBookInfo = tItem[3]
							if nBookInfo and nBookInfo ~= -1 then
								local nBookID, nSegID = GlobelRecipeID2BookID(nBookInfo)
								szItemName = Table_GetSegmentName(nBookID, nSegID) or g_tStrings.BOOK
							end
						end
						szItemName = UIHelper.GBKToUTF8(szItemName)
						-- 标记标签
						local t = TabHelper.GetEquipRecommend(tItemInfo.nRecommendID)
						local bCheckFilter = dwCurForceID == 0
						if t and t.desc and t.desc ~= "" then
							for _, v in ipairs(string.split(t.kungfu_ids, "|")) do
								local dwKungfuID = tonumber(v)
								if dwKungfuID == 0 then break end
								local dwForceID = Kungfu_GetType(dwKungfuID) or 0
								bCheckFilter = bCheckFilter or ((dwCurForceID == 0 or dwCurForceID == dwForceID) and (dwCurKungfuID == 0 or dwCurKungfuID == dwKungfuID))
							end
						end
						if bCheckFilter then
							scriptClass:AppendDropItem(szItemName, 1, tItem[1], tItem[2], tItem[3])
						end
					end
				end
				scriptClass:UpdateDropInfo()
			end
        end
	end
    UIHelper.ScrollViewDoLayout(self.ScrollViewArticle)
    UIHelper.ScrollToTop(self.ScrollViewArticle, 0)
end

function UIDungeonDetailView:GenerateFilter()
	self.tSelector = {
		[FILTER_TYPE.FORCE] = {},
		[FILTER_TYPE.KUNGFU] = {}
	}

	self.tbSelected = FilterDef.BossDropDetail.GetRunTime()
	if not self.tbSelected then
		self.tbSelected = {
			[FILTER_TYPE.FORCE] = {1},
			[FILTER_TYPE.KUNGFU] = {1}
		}
	end
	local tDropList = self:GetBossEquip(self.tCurBoss.szName, self.tRecord.dwMapID, {},{})
    for nIndex, tDrop in ipairs(tDropList) do
        if #tDrop > 0 then
			for _, tItem in ipairs(tDrop) do
				local tItemInfo = GetItemInfo(tItem[1], tItem[2])
				if tItemInfo then
					-- 标记标签
					local t = TabHelper.GetEquipRecommend(tItemInfo.nRecommendID)
					if t and t.desc and t.desc ~= "" then
						for _, v in ipairs(string.split(t.kungfu_ids, "|")) do
							local dwKungfuID = tonumber(v)
							if dwKungfuID then
								if dwKungfuID == 0 then
									self.tSelector[FILTER_TYPE.FORCE][0] = true  -- 通用心法
									self.tSelector[FILTER_TYPE.KUNGFU][0] = true -- 通用门派
									break
								else
									self.tSelector[FILTER_TYPE.KUNGFU][dwKungfuID] = true
								end
							end
							local dwForceID = Kungfu_GetType(dwKungfuID)
							if dwForceID then
								self.tSelector[FILTER_TYPE.FORCE][dwForceID] = true
							end
						end
					end
				end
			end
        end
	end

	local tForceClass = {
		szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = false,
        bDispatchChangedEvent = true,
        szTitle = "门派",
        tbList = {"全部"},
		tbValList = {0},
        tbDefault = {1},
	}
	local tForceList = {}
	for dwForceID, bEnable in pairs(self.tSelector[FILTER_TYPE.FORCE]) do
		if bEnable then table.insert(tForceList, dwForceID) end
	end
	table.sort(tForceList)
	for _, dwForceID in ipairs(tForceList) do
		local szForceName = Table_GetForceName(dwForceID)
		table.insert(tForceClass.tbList, szForceName)
		table.insert(tForceClass.tbValList, dwForceID)
	end
	FilterDef.BossDropDetail[FILTER_TYPE.FORCE] = tForceClass

	-- 内功筛选
	local tKungfuClass = {
		szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = false,
        bDispatchChangedEvent = false,
        szTitle = "内功",
        tbList = {"全部"},
		tbValList = {0},
        tbDefault = {1},
		tbDisableList = {},
	}
	local tKungfuList = {}
	for dwKungfuID, bEnable in pairs(self.tSelector[FILTER_TYPE.KUNGFU]) do
		if bEnable then table.insert(tKungfuList, dwKungfuID) end
	end
	table.sort(tKungfuList)
	for _, dwKungfuID in ipairs(tKungfuList) do
		local szSkillName = Table_GetSkillName(dwKungfuID, 1)
		szSkillName = UIHelper.GBKToUTF8(szSkillName)
		table.insert(tKungfuClass.tbList, szSkillName)
		table.insert(tKungfuClass.tbValList, dwKungfuID)
	end
	FilterDef.BossDropDetail[FILTER_TYPE.KUNGFU] = tKungfuClass
end

function UIDungeonDetailView:RefreshFilter()
	if not self.tbSelected then return end

	local nForceIndex = self.tbSelected[FILTER_TYPE.FORCE][1]
	local dwCurForceID = FilterDef.BossDropDetail[FILTER_TYPE.FORCE].tbValList[nForceIndex]
	FilterDef.BossDropDetail[FILTER_TYPE.KUNGFU].tbDisableList = {}
	for nKungfuIndex, dwKungfuID in pairs(FilterDef.BossDropDetail[FILTER_TYPE.KUNGFU].tbValList) do
		local dwForceID = Kungfu_GetType(dwKungfuID) or 0
		local bEnable = dwCurForceID ~= 0 and (dwForceID == 0 or dwForceID == dwCurForceID)
		FilterDef.BossDropDetail[FILTER_TYPE.KUNGFU].tbDisableList[nKungfuIndex] = not bEnable or dwCurForceID == 0
	end
end

function UIDungeonDetailView:UpdateBossSkillPage()
    local tInfo = self.tCurBoss
    local nCount = 0
	local MAXSTEP = 10
	for i = 1, MAXSTEP do
		local szSkill = "szStep"..i.."Skill"
		if tInfo[szSkill] and tInfo[szSkill] ~= "" then
			nCount = nCount + 1
		end
	end
	if nCount == 0 then
		nCount = 3 --如果表里没填,显示3个空阶段
	end

    UIHelper.RemoveAllChildren(self.ScrollViewSkill)
    for i = 1, nCount do
        local szSkill = "szStep"..i.."Skill"
		local szDes = "szStep"..i.."Des"
        local szPartName = g_tStrings.Dungeon.tBossFightStep[i]
        UIHelper.AddPrefab(PREFAB_ID.WidgetDungeonNormalBar,self.ScrollViewSkill, szPartName)
        if tInfo[szDes] and tInfo[szDes] ~= "" then
            local szStageDes = UIHelper.GBKToUTF8(tInfo[szDes])
            UIHelper.AddPrefab(PREFAB_ID.WidgetDungeonBossSkillStage,self.ScrollViewSkill, szStageDes)
        end

        if tInfo[szSkill] and tInfo[szSkill] ~= "" then
			local tSkillList = SplitString(tInfo[szSkill], ";")
			for k, v in pairs(tSkillList) do
				local nSkillID = tonumber(v)
				local tSkill = Table_GetDungeonBoss_StepSkill(nSkillID)
				UIHelper.AddPrefab(PREFAB_ID.WidgetDungeonSkillDetail, self.ScrollViewSkill, tSkill)
			end
		end
    end
	Timer.AddFrame(self, 1, function ()
		UIHelper.ScrollViewDoLayout(self.ScrollViewSkill)
		UIHelper.ScrollToTop(self.ScrollViewSkill, 0)
	end)

end

function UIDungeonDetailView:UpdateBossStoryPage()
    local szStory = UIHelper.GBKToUTF8(self.tCurBoss.szIntroduce)
	szStory = string.gsub(szStory, " ", "")
    szStory = "\t\t"..szStory
    UIHelper.SetString(self.LabeStoryCentre, szStory)
    UIHelper.ScrollViewDoLayout(self.ScrollViewStory)
    UIHelper.ScrollToTop(self.ScrollViewStory, 0)
end

function UIDungeonDetailView:GetBossEquip(szBossName, dwMapID, tCheckSchool, tCheckKungfu)
	local tBossWeapon = {}
	local tBossEquip = {}
	local tBossItem = {}

	local fnRangeEquip = function(tDropList)
		for _, tItem in ipairs(tDropList) do
			local hItemInfo = GetItemInfo(tItem[1], tItem[2])
			if hItemInfo and hItemInfo.nGenre == ITEM_GENRE.EQUIPMENT then
				if hItemInfo.nSub == EQUIPMENT_SUB.MELEE_WEAPON or
						hItemInfo.nSub == EQUIPMENT_SUB.RANGE_WEAPON or
						hItemInfo.nSub == EQUIPMENT_SUB.ARROW or
						hItemInfo.nSub == EQUIPMENT_SUB.BULLET
				then
					table.insert(tBossWeapon, tItem)
				else
					table.insert(tBossEquip, tItem)
				end

			else
				table.insert(tBossItem, tItem)
			end
		end
	end
	local szSchool = tCheckSchool[1]
	local szMagicKind = nil
	if not tCheckSchool[2] then
		szSchool = nil
	end

	local tDropList = self.tDropList or DungeonDrop_SearchByMapAndBossName(szBossName, dwMapID)
	self.tDropList = tDropList
	fnRangeEquip(tDropList)

	return {tBossWeapon, tBossEquip, tBossItem}
end

function UIDungeonDetailView:OnItemSelectChanged(nTabType, nTabID, nItemParam)
	if not nTabType or not nTabID then
		return
	end
	self.scriptItemTip = self.scriptItemTip or UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetItemTipShell)
	if self.scriptItemTip then
		UIHelper.SetVisible(self.WidgetItemTipShell, true)
		local hItemInfo = GetItemInfo(nTabType, nTabID)
		if hItemInfo.nGenre == ITEM_GENRE.BOOK then
			self.scriptItemTip:SetBookID(nItemParam)
		end
		self.scriptItemTip:OnInitWithTabID(nTabType, nTabID)
		self.scriptItemTip:SetBtnState({})
	end
end



----------------------数据处理工具函数--------------------------
local function JudgeType(SrcType, DstType, TypeAll)
	if not TypeAll then
		TypeAll = g_tStrings.Dungeon.STR_TYPE_ALL
	end

	if SrcType == TypeAll or DstType == TypeAll then
		return true;
	end
	return (SrcType == DstType)
end

local function JudgeSchool(tSrcSchool, DstSchool, TypeAll)
	local szSchool
	for _, szSchoolID in ipairs(tSrcSchool) do
		local dwSchoolID = tonumber(szSchoolID)
		if dwSchoolID then
			szSchool = Table_GetSkillSchoolName(dwSchoolID)
			if szSchool and JudgeType(szSchool, DstSchool, TypeAll) then
				return true
			end
		elseif DstSchool == g_tStrings.Dungeon.STR_TYPE_ALL then
			return true
		end
	end
end

function DungeonDrop_SearchByMapAndBossName(szBossName, dwMapID)
	local tDropList = {}
	local tEnv 		= {}
	local szPath 	= "ui\\Scheme\\Case\\DungeonBossItem\\MapID" .. dwMapID .. ".lua"
	LoadScriptFile(szPath, tEnv)
	for k, tLine in pairs(tEnv.g_MapList) do
		if tLine[4] == szBossName then
			table.insert(tDropList, tLine)
		end
	end
	tEnv = nil
	return tDropList
end

function DungeonDrop_FromListSearch(tDropList, szSchool, szMagicKind)
	if not szSchool then
		szSchool = g_tStrings.Dungeon.STR_TYPE_ALL
	end

	if not szMagicKind then
		szMagicKind = g_tStrings.Dungeon.STR_TYPE_ALL
	end
	local tList = {}
	for _, tItem in ipairs(tDropList) do
		if  JudgeSchool(tItem[5]:split("|"), szSchool, g_tStrings.Dungeon.STR_TYPE_ALL)
		and JudgeType(tItem[6], szMagicKind, g_tStrings.Dungeon.STR_TYPE_ALL) then
			table.insert(tList, tItem)
		end
	end

	local SortByIndex = function(tLeft, tRight)
		if (tLeft[1] == tRight[1]) and (tLeft[2] == tRight[2]) then
			return tLeft[3] < tRight[3]
		elseif tLeft[1] == tRight[1] then
			return tLeft[2] < tRight[2]
		else
			return tLeft[1] < tRight[1]
		end
    end
	table.sort(tList, SortByIndex)
	return tList
end

return UIDungeonDetailView
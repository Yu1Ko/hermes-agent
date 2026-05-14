-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandBuildItemListView
-- Date: 2023-05-24 16:16:30
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandBuildItemListView = class("UIHomelandBuildItemListView")
local MAX_SHOW_COUNT = 20
local GET_FILE_LIMIT_CD_TIME = 30
local DataModel = {}

function DataModel.Init()
	DataModel.nItemCount = 0
	DataModel.nGroupCount = 0
	DataModel.tSearch = -- 前两个元素表示一级和二级分类（都为nil表示所有分类；第一个大于0、第二个为0表示对应一级分类；都为0表示错误分类；都为-1表示打组分类）
	{[1] = nil, [2] = nil, [3] = g_tStrings.STR_FURNITURE_LIST_ALL_TYPE}
	DataModel.tSearchList = FurnitureData.GetPopupMenuCatgName()
	DataModel.aModelGroupIDs = {}
    DataModel.UpdateSomeInfo()
end

function DataModel.UnInit()
	DataModel.nItemCount = 0
	DataModel.tSearch = {[1] = nil, [2] = nil, [3] = g_tStrings.STR_FURNITURE_LIST_ALL_TYPE}
	DataModel.tSearchList = {}
	DataModel.aModelGroupIDs = {}
end

function DataModel.UpdateSomeInfo()
	local tAllObject = HLBOp_Amount.GetAllObjIDInfo()
	DataModel.nItemCount = 0
	if not tAllObject then
		return
	end
	for dwObjID, dwModelID in pairs(tAllObject) do
		local tInfo = FurnitureData.GetFurnInfoByModelID(dwModelID)
		if tInfo then
			DataModel.nItemCount = DataModel.nItemCount + 1
		end
	end

	local tFloorBrushInfo = HLBOp_Amount.GetFloorBrushInfo()
	local tFlowerBrushInfo = HLBOp_Amount.GetFlowerBrushInfo()
	for k, v in pairs(tFloorBrushInfo) do
		local nModelID = v.nModelID
		local tInfo = clone(FurnitureData.GetFurnInfoByModelID(nModelID))
		if tInfo then
			DataModel.nItemCount = DataModel.nItemCount + 1
		end
	end
	for k, v in pairs(tFlowerBrushInfo) do
		local nModelID = v.nModelID
		local tInfo = clone(FurnitureData.GetFurnInfoByModelID(nModelID))
		if tInfo then
			DataModel.nItemCount = DataModel.nItemCount + 1
		end
	end

	DataModel.aModelGroupIDs = HLBOp_Group.GetAllGroupIDs()
	table.sort(DataModel.aModelGroupIDs, function(a, b)
		return a < b
	end)
	DataModel.nGroupCount = #DataModel.aModelGroupIDs
end

function DataModel.GetCatgName(nCatg1, nCatg2)
	local szCatgName = ""
	if not nCatg1 and not nCatg2 then
		szCatgName = g_tStrings.STR_FURNITURE_LIST_ALL_TYPE
	elseif nCatg1 == 0 and nCatg2 == 0 then
		szCatgName = g_tStrings.STR_FURNITURE_LIST_ERROR_TYPE
	elseif nCatg1 == -1 and nCatg2 == -1 then
		szCatgName = g_tStrings.STR_FURNITURE_LIST_MODEL_GROUP_TYPE
	else
		local tCatg2 = DataModel.tSearchList[nCatg1]
		if tCatg2 then
			for _, v in pairs(tCatg2) do
				if v[1] == nCatg2 then
					szCatgName = v[2]
					break
				end
			end
		end
	end
	return szCatgName
end

function UIHomelandBuildItemListView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    DataModel.Init()
	HLBOp_Amount.RefreshLandData()

	if GetCurrentTime() - HLBOp_Save.GetLastGetLimitTime() >= GET_FILE_LIMIT_CD_TIME then
		-- 每次打开后更新一次当前蓝图信息
		HLBOp_Save.DoGetSDKFileLimit()
	end

	self:InitClassInfo()
    self:UpdateInfo()
end

function UIHomelandBuildItemListView:OnExit()
    self.bInit = false
    DataModel.UnInit()
end

function UIHomelandBuildItemListView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

	UIHelper.BindUIEvent(self.BtnOutput, EventType.OnClick, function ()
        local tSearch = DataModel.tSearch
		if tSearch[3] == g_tStrings.STR_FURNITURE_LIST_MODEL_GROUP_TYPE then
			return
		end
		local nCatg1, nCatg2 = tSearch[1], tSearch[2]
		if tSearch[3] == g_tStrings.STR_FURNITURE_LIST_ALL_TYPE then
			nCatg1, nCatg2 = -1, -1
		end
		if nCatg2 <= 0 then nCatg2 = -1 end
		HLBOp_Other.ExportObjectList(nCatg1, nCatg2)
    end)

	UIHelper.BindUIEvent(self.TogStats, EventType.OnClick, function ()
		if UIHelper.GetSelected(self.TogStats) then
			self:UpdateSaveUsageInfo()
		end
    end)

	UIHelper.BindUIEvent(self.TogPrimaryCategory, EventType.OnClick, function ()
		UIHelper.SetSelected(self.TogSecondaryCategory, false)
		self:UpdateClass1Info()
    end)

	UIHelper.BindUIEvent(self.TogSecondaryCategory, EventType.OnClick, function ()
		UIHelper.SetSelected(self.TogPrimaryCategory, false)
		self:UpdateClass2Info()
    end)

	UIHelper.BindUIEvent(self.BtnReturn, EventType.OnClick, function ()
		local scriptTableView = UIHelper.GetBindScript(self.WidgetSingleView)
		scriptTableView:Init()
		UIHelper.SetVisible(self.WidgetSingleView, false)
		UIHelper.SetVisible(self.WidgetContentPlacedItems, true)
    end)
	UIHelper.SetTouchDownHideTips(self.TogStats, false)
	UIHelper.SetTouchDownHideTips(self.TogPrimaryCategory, false)
	UIHelper.SetTouchDownHideTips(self.TogSecondaryCategory, false)
	UIHelper.SetTouchDownHideTips(self.ScrollViewSecondaryTips, false)
end

function UIHomelandBuildItemListView:RegEvent()
    local function UpdateInfo()
        DataModel.UpdateSomeInfo()
    end
    Event.Reg(self, "LUA_HOMELAND_UPDATE_LANDDATA", UpdateInfo)

	Event.Reg(self, EventType.HideAllHoverTips, function ()
		UIHelper.SetSelected(self.TogStats, false)
		UIHelper.SetSelected(self.TogPrimaryCategory, false)
		UIHelper.SetSelected(self.TogSecondaryCategory, false)
	end)

	Event.Reg(self, "OnHomelandBulidOpenItemTableview", function (tbItemList, szTitle)
		local scriptTableView = UIHelper.GetBindScript(self.WidgetSingleView)
		scriptTableView:Init(tbItemList, szTitle)
		UIHelper.SetVisible(self.WidgetSingleView, tbItemList and #tbItemList > 0)
		UIHelper.SetVisible(self.WidgetContentPlacedItems, not tbItemList or #tbItemList <= 0)
	end)
end

function UIHomelandBuildItemListView:InitClassInfo()
	self.tCatgMenu = {}
	for nCatg1, tCatg1 in pairs(DataModel.tSearchList) do
		local tCatg1Menu = {}
		for _, v in pairs(tCatg1) do
			if v[1] == 0 then
				tCatg1Menu.szOption = UIHelper.GBKToUTF8(v[2])
			end
			local tCatg2Menu =
			{
				szOption = v[1] == 0 and g_tStrings.STR_ALL or UIHelper.GBKToUTF8(v[2]),
				UserData = { nCatg1, v[1], UIHelper.GBKToUTF8(v[2]) },
			}
			table.insert(tCatg1Menu, tCatg2Menu)
		end
		self.tCatgMenu[nCatg1] = tCatg1Menu
	end
end

function UIHomelandBuildItemListView:UpdateInfo()
	self:UpdateItemInfo()
	self:UpdateSaveUsageInfo()
end

function UIHomelandBuildItemListView:UpdateClass1Info()
	UIHelper.HideAllChildren(self.LayoutPrimaryTips)
	self.tbClass1Cells = self.tbClass1Cells or {}

	if not self.tbClass1Cells[0] then
		self.tbClass1Cells[0] = UIHelper.AddPrefab(PREFAB_ID.WidgetPlacedItemFilterCell, self.LayoutPrimaryTips)
		UIHelper.ToggleGroupAddToggle(self.TogGroupClass1, self.tbClass1Cells[0].TogType)
	end

	local cell = self.tbClass1Cells[0]
	UIHelper.SetVisible(cell._rootNode, true)
	UIHelper.SetString(cell.LabelDesc, g_tStrings.STR_FURNITURE_LIST_ALL_TYPE)
	UIHelper.BindUIEvent(cell.TogType, EventType.OnClick, function(btn)
		UIHelper.SetString(self.LabelPrimaryCategory, g_tStrings.STR_FURNITURE_LIST_ALL_TYPE)
		UIHelper.SetString(self.LabelSecondaryCategory, "全部")
		UIHelper.SetToggleGroupSelected(self.TogGroupClass2, 0)
		DataModel.tSearch = {[1] = nil, [2] = nil, [3] = g_tStrings.STR_FURNITURE_LIST_ALL_TYPE}
		self:UpdateItemInfo()
		Event.Dispatch(EventType.HideAllHoverTips)
	end)

	for nIndex, tbInfo in pairs(self.tCatgMenu) do
		if not self.tbClass1Cells[nIndex] then
			self.tbClass1Cells[nIndex] = UIHelper.AddPrefab(PREFAB_ID.WidgetPlacedItemFilterCell, self.LayoutPrimaryTips)
			UIHelper.ToggleGroupAddToggle(self.TogGroupClass1, self.tbClass1Cells[nIndex].TogType)
		end

		local cell = self.tbClass1Cells[nIndex]
		UIHelper.SetVisible(cell._rootNode, true)
		UIHelper.SetString(cell.LabelDesc, tbInfo.szOption)
		UIHelper.BindUIEvent(cell.TogType, EventType.OnClick, function(btn)
			UIHelper.SetString(self.LabelPrimaryCategory, tbInfo.szOption)
			UIHelper.SetString(self.LabelSecondaryCategory, "全部")
			UIHelper.SetToggleGroupSelected(self.TogGroupClass2, 0)
			DataModel.tSearch = tbInfo[1].UserData
			self:UpdateItemInfo()
			Event.Dispatch(EventType.HideAllHoverTips)
		end)
	end

	if not self.tbClass1Cells[20] then
		self.tbClass1Cells[20] = UIHelper.AddPrefab(PREFAB_ID.WidgetPlacedItemFilterCell, self.LayoutPrimaryTips)
		UIHelper.ToggleGroupAddToggle(self.TogGroupClass1, self.tbClass1Cells[20].TogType)
	end

	local cell = self.tbClass1Cells[20]
	UIHelper.SetVisible(cell._rootNode, true)
	UIHelper.SetString(cell.LabelDesc, g_tStrings.STR_FURNITURE_LIST_MODEL_GROUP_TYPE)
	UIHelper.BindUIEvent(cell.TogType, EventType.OnClick, function(btn)
		UIHelper.SetString(self.LabelPrimaryCategory, g_tStrings.STR_FURNITURE_LIST_MODEL_GROUP_TYPE)
		UIHelper.SetString(self.LabelSecondaryCategory, "全部")
		UIHelper.SetToggleGroupSelected(self.TogGroupClass2, 0)
		DataModel.tSearch = {[1] = -1, [2] = -1, [3] = g_tStrings.STR_FURNITURE_LIST_MODEL_GROUP_TYPE}
		self:UpdateItemInfo()
		Event.Dispatch(EventType.HideAllHoverTips)
	end)

	UIHelper.LayoutDoLayout(self.LayoutPrimaryTips)
end

function UIHomelandBuildItemListView:UpdateClass2Info()
	UIHelper.HideAllChildren(self.ScrollViewSecondaryTips)
	self.tbClass2Cells = self.tbClass2Cells or {}

	local tbSubInfo = {}
	if not DataModel.tSearch[1] then
		-- 全部分类
		table.insert(tbSubInfo, {
			szOption = "全部",
			UserData = {[1] = DataModel.tSearch[1], [2] = 0, [3] = "全部"}
		})
	end

	if DataModel.tSearch[1] and self.tCatgMenu[DataModel.tSearch[1]] then
		for nIndex, tbInfo in ipairs(self.tCatgMenu[DataModel.tSearch[1]]) do
			table.insert(tbSubInfo, tbInfo)
		end
	end

	for nIndex, tbInfo in ipairs(tbSubInfo) do
		if not self.tbClass2Cells[nIndex] then
			self.tbClass2Cells[nIndex] = UIHelper.AddPrefab(PREFAB_ID.WidgetPlacedItemFilterCell, self.ScrollViewSecondaryTips)
			UIHelper.ToggleGroupAddToggle(self.TogGroupClass2, self.tbClass2Cells[nIndex].TogType)
			UIHelper.SetNodeSwallowTouches(self.tbClass2Cells[nIndex].TogType, false)
		end

		local cell = self.tbClass2Cells[nIndex]
		UIHelper.SetVisible(cell._rootNode, true)
		UIHelper.SetString(cell.LabelDesc, tbInfo.szOption)
		UIHelper.BindUIEvent(cell.TogType, EventType.OnClick, function(btn)
			UIHelper.SetString(self.LabelSecondaryCategory, tbInfo.szOption)
			DataModel.tSearch = tbInfo.UserData
			self:UpdateItemInfo()
			Event.Dispatch(EventType.HideAllHoverTips)
		end)
	end

	UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewSecondaryTips)
end

function UIHomelandBuildItemListView:UpdateItemInfo()
	if DataModel.tSearch[1] == -1 and DataModel.tSearch[2] == -1 then
		self:UpdateGroupItemInfo()
		return
	end

    local tAllObject = HLBOp_Amount.GetAllObjIDInfo()
	if not tAllObject then
		return
	end

    UIHelper.SetString(self.LabelTitle, string.format("已摆放物件(%d)", DataModel.nItemCount))

    local tbData = {}
    local tbTempData = {}
	for dwObjID, dwModelID in pairs(tAllObject) do
		local tInfo = FurnitureData.GetFurnInfoByModelID(dwModelID)
		if tInfo and self:IsSearchType(tInfo.nCatg1Index, tInfo.nCatg2Index) then
			local szName = UIHelper.GBKToUTF8(DataModel.GetCatgName(tInfo.nCatg1Index, tInfo.nCatg2Index))
            local nUsedCount, nLimitAmount = self:GetModelConsumptionInCatg(tInfo.nCatg1Index, tInfo.nCatg2Index)
            szName = string.format("%s(%d/%d)", szName, nUsedCount, nLimitAmount)
            tbTempData[szName] = tbTempData[szName] or {}
            table.insert(tbTempData[szName], {
				tArgs = {
					tbInfo = tInfo,
                    dwObjID = dwObjID,
                    dwModelID = dwModelID,
                }
            })
			if #tbTempData[szName] > MAX_SHOW_COUNT then
				tbTempData[szName].bMulti = true
			end
		end
	end

	for szName, tbList in pairs(tbTempData) do
		if tbList.bMulti then
			tbTempData[szName] = {
				{
					tArgs = {
						bMulti = true,
						szTitle = szName,
						tbInfos = tbList,
					}
				}
			}
			tbList.bMulti = nil
		end
	end

	local tFloorBrushInfo = HLBOp_Amount.GetFloorBrushInfo()
	local tFlowerBrushInfo = HLBOp_Amount.GetFlowerBrushInfo()
	for k, v in pairs(tFloorBrushInfo) do
		local nModelID = v.nModelID
		local tInfo = clone(FurnitureData.GetFurnInfoByModelID(nModelID))
		if tInfo and self:IsSearchType(tInfo.nCatg1Index, tInfo.nCatg2Index) then
			local szName = UIHelper.GBKToUTF8(DataModel.GetCatgName(tInfo.nCatg1Index, tInfo.nCatg2Index))
            local nUsedCount, nLimitAmount = self:GetModelConsumptionInCatg(tInfo.nCatg1Index, tInfo.nCatg2Index)
            szName = string.format("%s", szName)
            tbTempData[szName] = tbTempData[szName] or {}
            table.insert(tbTempData[szName], {
                tArgs = {
                    tbInfo = tInfo,
                    dwObjID = dwObjID,
                    dwModelID = dwModelID,
                }
            })
		end
	end
	for k, v in pairs(tFlowerBrushInfo) do
		local nModelID = v.nModelID
		local tInfo = clone(FurnitureData.GetFurnInfoByModelID(nModelID))
		if tInfo and self:IsSearchType(tInfo.nCatg1Index, tInfo.nCatg2Index) then
			local szName = UIHelper.GBKToUTF8(DataModel.GetCatgName(tInfo.nCatg1Index, tInfo.nCatg2Index))
            local nUsedCount, nLimitAmount = self:GetModelConsumptionInCatg(tInfo.nCatg1Index, tInfo.nCatg2Index)
            szName = string.format("%s", szName)
            tbTempData[szName] = tbTempData[szName] or {}
            table.insert(tbTempData[szName], {
                tArgs = {
                    tbInfo = tInfo,
                    dwObjID = dwObjID,
                    dwModelID = dwModelID,
                }
            })
		end
	end

	UIHelper.ToggleGroupRemoveAllToggle(self.TogGroupItem)

    for key, tItemList in pairs(tbTempData) do
        table.insert(tbData, {
            tArgs = { szTitle = key },
            tItemList = tItemList,
            fnSelectedCallback = function(bSelected, scriptContainer)
                -- scriptContainer:UpdateInfo(true)
				if bSelected then
					local tbCells = scriptContainer:GetItemScript()
					for index, scriptCell in ipairs(tbCells) do
						scriptCell:AddToggleGroup(self.TogGroupItem)
					end
				end
            end,
        })
    end

    if not self.scriptAllScrollList then
        self.scriptAllScrollList = UIHelper.GetBindScript(self.WidgetContentPlacedItems)
    end

    local func = function(scriptContainer, tArgs)
        UIHelper.SetString(scriptContainer.LabelTitle, tArgs.szTitle)
        UIHelper.SetString(scriptContainer.LabelSelect, tArgs.szTitle)
    end

    self.scriptAllScrollList:ClearContainer()
    UIHelper.SetupScrollViewTree(self.scriptAllScrollList,
        PREFAB_ID.WidgetPlacedItemListSubTitle,
        PREFAB_ID.WidgetPlacedItemCell,
        func, tbData, true)
end

function UIHomelandBuildItemListView:UpdateGroupItemInfo()
	if DataModel.tSearch[1] ~= -1 or DataModel.tSearch[2] ~= -1 then
		return
	end

    UIHelper.SetString(self.LabelTitle, string.format("物件组(%d)", DataModel.nGroupCount))

    local tItemList = {}
	for i, dwModelGroupID in ipairs(DataModel.aModelGroupIDs) do
		local aObjIDs = HLBOp_Group.GetGroupInfo(dwModelGroupID)
		if aObjIDs and #aObjIDs > 0 then
			local dwModelID = HLBOp_Amount.GetModelIDByObjID(aObjIDs[1])
			local tInfo = FurnitureData.GetFurnInfoByModelID(dwModelID)
			if dwModelID and tInfo then
				local szName = string.format("组%d", i)
				table.insert(tItemList, {
					tArgs = {
						szName = szName,
						dwModelGroupID = dwModelGroupID,
						tbInfo = tInfo,
						dwObjID = aObjIDs[1],
						dwModelID = dwModelID,
					}
				})
			end
		end
	end

	UIHelper.ToggleGroupRemoveAllToggle(self.TogGroupItem)

	local tbData = {{
		tArgs = { szTitle = "物件组" },
		tItemList = tItemList,
		fnSelectedCallback = function(bSelected, scriptContainer)
			-- scriptContainer:UpdateInfo(true)
			if bSelected then
				local tbCells = scriptContainer:GetItemScript()
				for index, scriptCell in ipairs(tbCells) do
					scriptCell:AddToggleGroup(self.TogGroupItem)
				end
			end
		end,
	}}

    if not self.scriptAllScrollList then
        self.scriptAllScrollList = UIHelper.GetBindScript(self.WidgetContentPlacedItems)
    end

    local func = function(scriptContainer, tArgs)
        UIHelper.SetString(scriptContainer.LabelTitle, tArgs.szTitle)
        UIHelper.SetString(scriptContainer.LabelSelect, tArgs.szTitle)
    end

    self.scriptAllScrollList:ClearContainer()
    UIHelper.SetupScrollViewTree(self.scriptAllScrollList,
        PREFAB_ID.WidgetPlacedItemListSubTitle,
        PREFAB_ID.WidgetPlacedItemCell,
        func, tbData, true)
end

function UIHomelandBuildItemListView:UpdateSaveUsageInfo()
    local tbPerc = {
        HomelandBuildData.GetSDKFileLimitPercentage(),
        HomelandBuildData.GetLandObjectPercentage(),
        HomelandBuildData.GetSaveFurniturePercentage()
    }

    for i, label in ipairs(self.tbLabelSaveUsage) do
        local fPerc = tbPerc[i]
        UIHelper.SetString(label, string.format("%.2f%%", fPerc * 100))
        UIHelper.SetProgressBarPercent(self.tbSliderSaveUsage[i], fPerc * 100)
    end
end

function UIHomelandBuildItemListView:GetModelConsumptionInCatg(nCatg1Index, nCatg2Index)
	local hlMgr = GetHomelandMgr()
	local nUsedCount = hlMgr.BuildGetCategoryCount(nCatg1Index, nCatg2Index)
	local tLevelConfig = hlMgr.GetLevelFurnitureConfig(nCatg1Index, nCatg2Index, HLBOp_Enter.GetLevel())
	local nLimitAmount = tLevelConfig and tLevelConfig.LimCount
	return nUsedCount, nLimitAmount
end

function UIHomelandBuildItemListView:IsSearchType(nCatg1, nCatg2)
	if not DataModel.tSearch[1] then -- 全部分类
		return true
	else
		if DataModel.tSearch[2] == 0 then
			return nCatg1 == DataModel.tSearch[1]
		else
			return nCatg1 == DataModel.tSearch[1] and nCatg2 == DataModel.tSearch[2]
		end
	end
end

return UIHomelandBuildItemListView
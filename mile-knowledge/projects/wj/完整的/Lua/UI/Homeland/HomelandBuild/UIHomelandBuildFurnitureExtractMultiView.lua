-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandBuildFurnitureExtractMultiView
-- Date: 2023-12-19 10:46:58
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandBuildFurnitureExtractMultiView = class("UIHomelandBuildFurnitureExtractMultiView")

local MAX_ITEM_COUNT = 6
local MAX_SELECTED = 20

-----------------------------DataModel------------------------------
local DataModel = {}

function DataModel.Init()
	DataModel.tList = DataModel.GetList()
	DataModel.tSelected = {}
	for i = 1, #DataModel.tList do
		DataModel.tSelected[i] = false
	end
	DataModel.nNowPage = 0
	DataModel.nMaxPage = math.ceil(#DataModel.tList / MAX_ITEM_COUNT)
	if DataModel.nMaxPage >= 1 then
		DataModel.nNowPage = 1
	end
end

function DataModel.UnInit()
	DataModel.tList = nil
	DataModel.tSelectedList = nil
	DataModel.nNowPage = 0
end

function DataModel.GetList()
	local hlMgr = GetHomelandMgr()
	local tTable = hlMgr.BuildGetPlayerWareHouseCanUse()
	if not tTable then
		return {}
	end
	for i = 1, #tTable do
		local nType, nFurnitureID = tTable[i].nFurnitureType, tTable[i].nID
		local tInfo = FurnitureData.GetFurnInfoByTypeAndID(nType, nFurnitureID)
		tTable[i].szName = tInfo.szName
		local bOrdinaryFurniture = (nType == HS_FURNITURE_TYPE.FURNITURE)
		local nMyContributedCountInWarehouse = hlMgr.GetWareHouseCount(UI_GetClientPlayerID(), bOrdinaryFurniture, nFurnitureID)
		tTable[i].nNum = math.min(nMyContributedCountInWarehouse, tTable[i].nAmount)
	end
	return tTable
end

function UIHomelandBuildFurnitureExtractMultiView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    DataModel.Init()
    self:UpdateInfo()
end

function UIHomelandBuildFurnitureExtractMultiView:OnExit()
    self.bInit = false
    DataModel.UnInit()
end

function UIHomelandBuildFurnitureExtractMultiView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.TogCheck, EventType.OnClick, function(btn)
        local bSelected = UIHelper.GetSelected(self.TogCheck)

        for i = 1, #DataModel.tSelected do
            DataModel.tSelected[i] = false
        end

        if bSelected then
            for i = 1, #DataModel.tSelected do
                if i <= MAX_SELECTED then
                    DataModel.tSelected[i] = true
                end
            end
        end

        self:UpdateInfo()
    end)

    UIHelper.BindUIEvent(self.BtnLeft, EventType.OnClick, function(btn)
        if DataModel.nNowPage > 1 then
			DataModel.nNowPage = DataModel.nNowPage - 1
			self:UpdateListInfo()
		end
    end)

    UIHelper.BindUIEvent(self.BtnRight, EventType.OnClick, function(btn)
        if DataModel.nNowPage < DataModel.nMaxPage then
			DataModel.nNowPage = DataModel.nNowPage + 1
			self:UpdateListInfo()
		end
    end)

    UIHelper.BindUIEvent(self.BtnReceivePage, EventType.OnClick, function(btn)
        local tList = {}
		for i = 1, MAX_ITEM_COUNT do
			local nIndex = (DataModel.nNowPage - 1) * MAX_ITEM_COUNT + i
			local tItem = DataModel.tList[nIndex]
			if tItem then
				table.insert(tList, {tItem.nFurnitureType, tItem.nID, -tItem.nNum})
			end
		end
		if #tList > 0 and #tList <= MAX_SELECTED then
			GetHomelandMgr().ChangeWarehouse(HLBOp_Enter.GetLandIndex(), tList)
			UIMgr.Close(self)
		end
    end)

    UIHelper.BindUIEvent(self.BtnReceiveChosen, EventType.OnClick, function(btn)
        local tList = {}
		for i = 1, #DataModel.tList do
			local tItem = DataModel.tList[i]
			if DataModel.tSelected[i] then
				table.insert(tList, {tItem.nFurnitureType, tItem.nID, -tItem.nNum})
			end
		end
		if #tList > 0 and #tList <= MAX_SELECTED then
			GetHomelandMgr().ChangeWarehouse(HLBOp_Enter.GetLandIndex(), tList)
			UIMgr.Close(self)
		end
    end)

    if Platform.IsWindows() or Platform.IsMac() then
        UIHelper.RegisterEditBoxEnded(self.EditPaginate, function()
            local szPage = UIHelper.GetText(self.EditPaginate)
			local nPage = tonumber(szPage)
            if nPage then
                local nMaxPage = math.ceil(#DataModel.tList / MAX_ITEM_COUNT)
                DataModel.nNowPage = math.min(nMaxPage, nPage)
                DataModel.nNowPage = math.max(1, DataModel.nNowPage)
            else
                UIHelper.SetText(self.EditPaginate, DataModel.nNowPage)
                return
            end
            self:UpdateInfo()
        end)
    else
        UIHelper.RegisterEditBoxReturn(self.EditPaginate, function()
			local szPage = UIHelper.GetText(self.EditPaginate)
			local nPage = tonumber(szPage)
            if nPage then
                local nMaxPage = math.ceil(#DataModel.tList / MAX_ITEM_COUNT)
                DataModel.nNowPage = math.min(nMaxPage, nPage)
                DataModel.nNowPage = math.max(1, DataModel.nNowPage)
            else
                UIHelper.SetText(self.EditPaginate, DataModel.nNowPage)
                return
            end
            self:UpdateInfo()
        end)
    end

    UIHelper.SetEditboxTextHorizontalAlign(self.EditPaginate, TextHAlignment.CENTER)
end

function UIHomelandBuildFurnitureExtractMultiView:RegEvent()
    Event.Reg(self, "HOMELANDBUILDING_ON_CLOSE", function ()
        UIMgr.Close(self)
    end)
end

function UIHomelandBuildFurnitureExtractMultiView:UpdateInfo()
    self:UpdateListInfo()
    self:UpdateSelectInfo()
end

function UIHomelandBuildFurnitureExtractMultiView:UpdateListInfo()
    UIHelper.HideAllChildren(self.LayoutFurnitureStorageCell)
    self.tbCells = self.tbCells or {}

    for i = 1, MAX_ITEM_COUNT do
		local nIndex = (DataModel.nNowPage - 1) * MAX_ITEM_COUNT + i
		local tbInfo = DataModel.tList[nIndex]
		if tbInfo then
            if not self.tbCells[i] then
                self.tbCells[i] = self.tbCells[i] or UIHelper.AddPrefab(PREFAB_ID.WidgetExtractMultiCell, self.LayoutFurnitureStorageCell)
            end
            UIHelper.SetVisible(self.tbCells[i]._rootNode, true)
            local bSelected = DataModel.tSelected[nIndex]
            self.tbCells[i]:OnEnter(nIndex, tbInfo, bSelected, function (nClickIndex, bNewSelected)
                self:SetSelectedCell(nClickIndex, bNewSelected)
            end)
		end
	end

    local nMaxPage = math.ceil(#DataModel.tList / MAX_ITEM_COUNT)
    UIHelper.LayoutDoLayout(self.LayoutFurnitureStorageCell)
    UIHelper.SetString(self.LabelPaginate, string.format("/%d", nMaxPage))
    UIHelper.SetText(self.EditPaginate, DataModel.nNowPage)
    UIHelper.SetVisible(self.WidgetEmpty, #DataModel.tList == 0)
    UIHelper.SetVisible(self.WidgetAccessoryPaginate, #DataModel.tList > 0)
end

function UIHomelandBuildFurnitureExtractMultiView:UpdateSelectInfo()
    local nCount = 0
    for i = 1, #DataModel.tSelected do
        if DataModel.tSelected[i] then
            nCount = nCount + 1
        end
    end

    UIHelper.SetString(self.LabelTotalCount, string.format("已选：%d/%d", nCount, MAX_SELECTED))
    -- UIHelper.SetString(self.LabelLeftNum, string.format("剩余数量：%d", #DataModel.tList - nCount))
    UIHelper.SetSelected(self.TogCheck, (MAX_SELECTED == nCount or #DataModel.tList == nCount) and #DataModel.tList > 0)
end

function UIHomelandBuildFurnitureExtractMultiView:SetSelectedCell(nIndex, bSelected)
    if bSelected then
        local nCount = 0
        for i = 1, #DataModel.tSelected do
            if DataModel.tSelected[i] then
                nCount = nCount + 1
            end
        end
        if nCount >= MAX_SELECTED then
            TipsHelper.ShowNormalTip(g_tStrings.STR_HOMELAND_EXTRACT_BEYOND)
            self:UpdateInfo()
            return
        end
        DataModel.tSelected[nIndex] = true
        self:UpdateInfo()
    else
        DataModel.tSelected[nIndex] = false
        self:UpdateInfo()
    end
end


return UIHomelandBuildFurnitureExtractMultiView
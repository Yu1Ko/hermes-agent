-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandBuildInteractionListView
-- Date: 2024-01-24 19:57:40
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandBuildInteractionListView = class("UIHomelandBuildInteractionListView")

local FilterIndex2Type = {1,2,3,4,5,6,7,12,13,14,16,17,18,19,20,21}

-----------------------------DataModel------------------------------
local DataModel = {}

function DataModel.Init(nLandIndex, bVistor, bPrivate)
    DataModel.nLandIndex = nLandIndex or 0
    DataModel.tInfo = {}
    DataModel.tInstID2Enum = {}
    DataModel.tInstID2Info = {}
    local tConfigTable = Table_GetHouseInteractionList()
    local pHlMgr = GetHomelandMgr()
    for k, v in pairs(tConfigTable) do
        local eType = v.eType
        local bMaster = not bVistor
        local bShow = (bMaster and v.bMasterShow) or (bVistor and v.bVistorShow)
        if bShow then
            local bCommunity = not bPrivate
            bShow = (bCommunity and v.bCommunityShow) or (bPrivate and v.bPrivateShow)
        end
        if bShow then
            local tFurn = {}
            local nCount = pHlMgr.GetCategoryCount(DataModel.nLandIndex, eType)
            for i = 1, nCount do
                tFurn[i] = pHlMgr.GetLOByCategory(DataModel.nLandIndex, eType, i)
                DataModel.GetInstObjInfo(DataModel.nLandIndex, tFurn[i].nInstanceID)
                DataModel.tInstID2Enum[tFurn[i].nInstanceID] = eType
            end
            DataModel.tInfo[eType] = {szName = UIHelper.GBKToUTF8(v.szName), tFurn = tFurn}
        end
    end
    DataModel.nChooseInstID = 0
    DataModel.bAllExpand = false
end

function DataModel.UpdateInstInfo(nInstID, nModelID, nX, nY, nZ)
    local tFurnInfo = FurnitureData.GetFurnInfoByModelID(nModelID)
    if tFurnInfo then
        DataModel.tInstID2Info[nInstID] = {nInstanceID = nInstID, nFurnitureType = tFurnInfo.nFurnitureType,
        dwFurnitureID = tFurnInfo.dwFurnitureID, dwModelID = tFurnInfo.dwModelID,
        nQuality = tFurnInfo.nQuality, szName = tFurnInfo.szName, nX = nX, nY = nY, nZ = nZ}
    end
end

function DataModel.GetInstObjInfo(nLandIndex, nInstID)
	local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.GET_INTERACTION_OBJECT_INFO, nLandIndex, nInstID, nInstID) --临时与其他界面做区分 用负号 收到事件后再取正
	Homeland_Log("HOMELAND_BUILD_OP.GET_INTERACTION_OBJECT_INFO", nLandIndex, nInstID)
end

function DataModel.OnGetInstObjInfo()
	local bResult = arg2
	local nInstID = arg1
    local nModelID = arg3
    local dwGroupID = arg4
    local eTransCheckCode = arg14
    local dwObjPosX, dwObjPosY, dwObjPosZ = arg5, arg6, arg7
	Homeland_Log("收到HOMELAND_BUILD_OP.GET_INTERACTION_OBJECT_INFO", bResult, nInstID, nModelID, dwGroupID, eTransCheckCode)

    if dwGroupID ~= 0 then
        nModelID = dwGroupID
    end

    if nInstID > 0 and nModelID > 0 and (eTransCheckCode == 2 or eTransCheckCode == 0) then
        if not DataModel.tInstID2Info[nInstID] then
            DataModel.UpdateInstInfo(nInstID, nModelID, dwObjPosX, dwObjPosY, dwObjPosZ)
            -- UpdateItem(nInstID)
            Event.Dispatch(EventType.OnUpdateHomelandBuildInteractionListData, nInstID)
        end
    end
end

function DataModel.UnInit()
    DataModel.nIndex = 0
    DataModel.tInfo = {}
    DataModel.tInstID2Enum = {}
    DataModel.tInstID2Info = {}
    DataModel.nChooseInstID = 0
    DataModel.bAllExpand = false
end

function UIHomelandBuildInteractionListView:OnEnter(nLandIndex, bVistor, bPrivate)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nLandIndex = nLandIndex
    self.bVistor = bVistor
    self.bPrivate = bPrivate
    DataModel.Init(nLandIndex, bVistor, bPrivate)

    self:UpdateInfo()
end

function UIHomelandBuildInteractionListView:OnExit()
    self.bInit = false
end

function UIHomelandBuildInteractionListView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnClose1, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnFilter, EventType.OnClick, function(btn)
        TipsHelper.DeleteAllHoverTips()
		TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.WidgetItemTipsShell, TipsLayoutDir.TOP_CENTER, FilterDef.HomelandBuildInteractionListType)
    end)

end

function UIHomelandBuildInteractionListView:RegEvent()
    Event.Reg(self, EventType.OnSelectedHomelandBuildInteractionListCell, function (nInstID)
        if not DataModel.tInstID2Info[nInstID] then
            return
        end

        TipsHelper.DeleteAllHoverTips()

        local tbData = DataModel.tInstID2Info[nInstID]
        local tips, scriptTips = TipsHelper.ShowItemTips(self.BtnConstructionItem)
		scriptTips:OnInitFurniture(tbData.nFurnitureType, tbData.dwFurnitureID)
        scriptTips:SetBtnState({})
    end)

    Event.Reg(self, "HOMELAND_CALL_RESULT", function ()
        local eOperationType = arg0
        if eOperationType == HOMELAND_BUILD_OP.GET_INTERACTION_OBJECT_INFO then
            DataModel.OnGetInstObjInfo()
        end
    end)

    Event.Reg(self, EventType.OnFilter, function(szKey, tbSelected)
        if szKey == FilterDef.HomelandBuildInteractionListType.Key then
            self:UpdateInfo()
        end
    end)
end

function UIHomelandBuildInteractionListView:UpdateInfo()
    local tAllObject = DataModel.tInfo or {}

    local tbData = {}
    for eType, tbInfo in pairs(tAllObject) do
        local tItemList = {}
        for i, tbFurnInfo in ipairs(tbInfo.tFurn) do
            table.insert(tItemList, {
                tArgs = {
                    tbBaseInfo = tbFurnInfo,
                    DataModel = DataModel,
                }
            })
        end

        if self:CheckCanShow(eType, #tItemList) then
            table.insert(tbData, {
                tArgs = { szTitle = string.format("%s(%d)", tbInfo.szName, #tItemList) },
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
    end

    if not self.scriptAllScrollList then
        self.scriptAllScrollList = UIHelper.GetBindScript(self.WidgetContentPlacedItems)
    end

    local func = function(scriptContainer, tArgs)
        UIHelper.SetString(scriptContainer.LabelTitle, tArgs.szTitle)
        UIHelper.SetString(scriptContainer.LabelSelect, tArgs.szTitle)
    end

    self.scriptAllScrollList:ClearContainer()
    self.scriptAllScrollList:SetOuterInitSelect()
    UIHelper.SetupScrollViewTree(self.scriptAllScrollList,
        PREFAB_ID.WidgetInteractionListSubTitle,
        PREFAB_ID.WidgetInteractionListCell,
        func, tbData, true)
end

function UIHomelandBuildInteractionListView:CheckCanShow(eType, nCount)
    local tbFilterConfig = FilterDef.HomelandBuildInteractionListType.GetRunTime()
    if not tbFilterConfig then
        return true
    end

    if tbFilterConfig[1] and #tbFilterConfig[1] > 0 and nCount <= 0 then
        return false
    end

    if tbFilterConfig[2] then
        for _, nFilterIndex in ipairs(tbFilterConfig[2]) do
            local eFilterType = FilterIndex2Type[nFilterIndex]
            if eFilterType == eType then
                return true
            end
        end
    end

    return false
end

return UIHomelandBuildInteractionListView
-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIBookItem
-- Date: 2022-12-09 10:31:03
-- Desc: ?
-- ---------------------------------------------------------------------------------

local ALL_QUALITY = 0
local PENDANT_ITEM_TYPE = 16
local tbQualityFilter = {
    [1] = ALL_QUALITY,
    [2] = 1,
    [3] = 2,
    [4] = 3,
    [5] = 4,
    [6] = 5,
}

local UIWidgetMysteryStorage = class("UIWidgetMysteryStorage")

---@param parentScript UIPanelMysteryItemMain
function UIWidgetMysteryStorage:OnEnter(parentScript)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        self.parentScript = parentScript
    end

    self.bBatch = false
    self.tbSelected = {
        tbBatch = {},
        tbPos = {}
    }
    self.nSelectedQuality = ALL_QUALITY
    self.szSearchText = ""
    self.nModelCategory = PendantModelCategory.Pendant

    --local size1 = g_pClientPlayer.GetMysteryPendantBoxSize(MYSTERY_PENDANT_TYPE.WAIST)
    --local size2 = g_pClientPlayer.GetMysteryPendantBoxSize(MYSTERY_PENDANT_TYPE.TOTAL)
    --local size3 = g_pClientPlayer.GetMysteryPendantBoxSize(MYSTERY_PENDANT_TYPE.BACK)
    --local size4 = g_pClientPlayer.GetMysteryPendantItemBoxSize() -- 获得盲盒挂件道具专属背包的⼤⼩
    --local size5 = g_pClientPlayer.GetSelectMysteryPendant(MYSTERY_PENDANT_TYPE.WAIST)

    self:UpdateInfo()
end

function UIWidgetMysteryStorage:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetMysteryStorage:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnTackOut, EventType.OnClick, function()
        self:TakeOut()
    end)

    UIHelper.BindUIEvent(self.BtnDelete, EventType.OnClick, function()
        self:Delete()
    end)

    UIHelper.BindUIEvent(self.BtnUse, EventType.OnClick, function()
        self:Use()
    end)

    UIHelper.BindUIEvent(self.BtnManage, EventType.OnClick, function()
        self:StartBatchManage()
    end)

    UIHelper.BindUIEvent(self.TogFilter, EventType.OnClick, function()
        local tbConfig = FilterDef.Pendant
        _, self.scriptFilter = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.TogFilter, TipsLayoutDir.BOTTOM_RIGHT, tbConfig)
    end)

    UIHelper.BindUIEvent(self.BtnClean, EventType.OnClick, function()
        self.szSearchText = ""
        UIHelper.SetString(self.EditBoxSearch, "")
        self:UpdateInfo()
    end)

    UIHelper.BindUIEvent(self.BtnClean, EventType.OnClick, function()
        self.szSearchText = ""
        UIHelper.SetString(self.EditBoxSearch, "")
        self:UpdateInfo()
    end)

    UIHelper.BindUIEvent(self.TogShowItem, EventType.OnSelectChanged, function(tpg, bSelected)
        if bSelected then
            self.nModelCategory = PendantModelCategory.Pendant
            self:ShowScene()
        end
    end)

    UIHelper.BindUIEvent(self.TogShowCharacter, EventType.OnSelectChanged, function(tpg, bSelected)
        if bSelected then
            self.nModelCategory = PendantModelCategory.Character
            self:ShowScene()
        end
    end)
end

function UIWidgetMysteryStorage:RegEvent()
    Event.Reg(self, "ON_CHANGE_MYSTERY_PENDANT_ITEM_NOTIFY", function()
        self:UpdateInfo()
    end)

    UIHelper.RegisterEditBoxEnded(self.EditBoxSearch, function()
        self.szSearchText = UIHelper.GetText(self.EditBoxSearch)
        self:UpdateInfo()
    end)

    Event.Reg(self, EventType.OnFilter, function(szKey, tbSelected)
        if szKey == FilterDef.Pendant.Key then
            self.nSelectedQuality = tbQualityFilter[tbSelected[1][1]]
            self:UpdateInfo()
        end
    end)
end

function UIWidgetMysteryStorage:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetMysteryStorage:UpdateInfo()
    local tAllItems = g_pClientPlayer.GetAllMysteryPendantItem()
    local tFilteredList = self:GetFilteredPendantItems(tAllItems)
    
    self.dwPendantIndex = nil
    self.tScripts = {} ---@type UIWidgetMysteryItemCell[]
    local nOriginalToggleIndex = UIHelper.GetToggleGroupSelectedIndex(self.ToggleGroup)
    nOriginalToggleIndex = nOriginalToggleIndex ~= -1 and nOriginalToggleIndex or 0
    nOriginalToggleIndex = nOriginalToggleIndex >= #tFilteredList and #tFilteredList - 1 or nOriginalToggleIndex
    UIHelper.RemoveAllChildren(self.ScrollStorageList)
    UIHelper.ToggleGroupRemoveAllToggle(self.ToggleGroup)
    
    for nIndex, tInfo in ipairs(tFilteredList) do
        local mysteryItem = UIHelper.AddPrefab(PREFAB_ID.WidgetMysteryItemCell, self.ScrollStorageList)
        mysteryItem:Init(PENDANT_ITEM_TYPE, tInfo.dwItemTabIndex, tInfo.dwPendantIndex)
        mysteryItem:SetToggleGroup(self.ToggleGroup)
        mysteryItem:SetSelectChangeCallback(function(dwItemID, bSelected)
            self:OnItemSelectChange(PENDANT_ITEM_TYPE, tInfo.dwItemTabIndex, tInfo.dwPendantIndex, bSelected)
        end)
        table.insert(self.tScripts, mysteryItem)

        if nOriginalToggleIndex + 1 == nIndex then
            self:OnItemSelectChange(PENDANT_ITEM_TYPE, tInfo.dwItemTabIndex, tInfo.dwPendantIndex, true)
        end
    end

    self:UpdateNodeVisible(#tFilteredList > 0, #tAllItems > 0)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollStorageList)

    if nOriginalToggleIndex ~= -1 then
        UIHelper.SetToggleGroupSelected(self.ToggleGroup, nOriginalToggleIndex)
    end
end

function UIWidgetMysteryStorage:GetFilteredPendantItems(tAllItems)
    local tFilteredList = {}
    local szSearchText = self.szSearchText
    for nIndex, tInfo in ipairs(tAllItems) do
        local tItemInfo = ItemData.GetItemInfo(PENDANT_ITEM_TYPE, tInfo.dwItemTabIndex)
        local bMatchSearch = szSearchText == "" or string.find(UIHelper.GBKToUTF8(tItemInfo.szName), szSearchText)
        local bMatchQuality = self.nSelectedQuality == ALL_QUALITY or tItemInfo.nQuality == self.nSelectedQuality
        if bMatchSearch and bMatchQuality then
            table.insert(tFilteredList, tInfo)
        end
    end

    return tFilteredList
end

function UIWidgetMysteryStorage:ShowItemTip(dwItemType, dwItemID)
    self.scriptItemTip = self.scriptItemTip or UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetItemDetail)
    self.scriptItemTip:SetFunctionButtons({})
    self.scriptItemTip:SetForbidAutoShortTip(true)
    self.scriptItemTip:OnInitWithTabID(dwItemType, dwItemID)
end

function UIWidgetMysteryStorage:UpdateNodeVisible(bHasFilterCell, bHasPendant)
    UIHelper.SetVisible(self.WidgetSearchSift, bHasPendant)
    UIHelper.SetVisible(self.TogShowCharacter, bHasFilterCell)
    UIHelper.SetVisible(self.TogShowItem, bHasFilterCell)
    UIHelper.SetVisible(self.BtnUse, bHasFilterCell)
    UIHelper.SetVisible(self.BtnManage, bHasPendant)
    UIHelper.SetVisible(self.BtnDelete, bHasFilterCell)
    UIHelper.SetVisible(self.BtnTackOut, bHasFilterCell)

    UIHelper.SetVisible(self.BtnClean, self.szSearchText ~= "")

    if not bHasFilterCell and self.scriptItemTip then
        self:ShowItemTip() -- hide tip
    end

    UIHelper.SetVisible(self.WidgetEmptySearch, bHasPendant and not bHasFilterCell)
    UIHelper.SetVisible(self.WidgetEmpty, not bHasPendant)
    UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, false)
end

function UIWidgetMysteryStorage:OnItemSelectChange(dwTabType, dwTabIndex, dwPendantIndex, bSelected)
    if not self.bBatch then
        if bSelected then
            self.dwPendantIndex = dwPendantIndex
        end
    else
        if bSelected then
            self.tbSelected.tbBatch[dwPendantIndex] = {
                dwTabType = dwTabType,
                dwTabIndex = dwTabIndex
            }
            Event.Dispatch(EventType.OnSetUIItemIconChoose, true, dwPendantIndex, 1)
        else
            self.tbSelected.tbBatch[dwPendantIndex] = nil
            Event.Dispatch(EventType.OnSetUIItemIconChoose, false, dwPendantIndex, 0)
        end
        self.parentScript:UpdateSelectedNum(string.format("%d", table.get_len(self.tbSelected.tbBatch)))
    end

    if bSelected then
        self:ShowItemTip(dwTabType, dwTabIndex)
    end
end

function UIWidgetMysteryStorage:TakeOut()
    if self.dwPendantIndex and g_pClientPlayer and not self.bBatch then
        local nResult = g_pClientPlayer.PutMysteryPendantItemToPackage(self.dwPendantIndex)
        if nResult == MYSTERY_ITEM_ERROR_CODE.SUCCESS then
            TipsHelper.ShowImportantYellowTip("chenggong")
        else
            TipsHelper.ShowImportantRedTip("shibai")
        end
    end
end

function UIWidgetMysteryStorage:Delete()
    if self.dwPendantIndex and g_pClientPlayer and not self.bBatch then
        local nResult = g_pClientPlayer.DeleteMysteryPendantItem(self.dwPendantIndex)
        if nResult then
            TipsHelper.ShowImportantYellowTip("chenggong")
        else
            TipsHelper.ShowImportantRedTip("shibai")
        end
    end
end

function UIWidgetMysteryStorage:Use()
    if self.dwPendantIndex and g_pClientPlayer and not self.bBatch then
        local nResult = g_pClientPlayer.EquipMysteryPendant(self.dwPendantIndex)
        if nResult == MYSTERY_ITEM_ERROR_CODE.SUCCESS then
            TipsHelper.ShowImportantYellowTip("chenggong")
        else
            TipsHelper.ShowImportantRedTip("shibai")
        end
    end
end

function UIWidgetMysteryStorage:BatchDelete()
    local pPlayer = g_pClientPlayer
    if not pPlayer then
        return
    end

    local lst = {}
    local bHasHigherThanViolet = false
    for dwPendantIndex, tInfo in pairs(self.tbSelected.tbBatch) do
        local tItemInfo = ItemData.GetItemInfo(tInfo.dwTabType, tInfo.dwTabIndex)
        if tItemInfo.nQuality >= 4 then
            bHasHigherThanViolet = true
        end
        table.insert(lst, dwPendantIndex)
    end

    local fnDelete = function()
        if #lst > 0 then
            local bFlag = pPlayer.BatchDeleteMysteryPendantItem(lst)
            if bFlag then
                TipsHelper.ShowImportantYellowTip("成功啦")
            else
                TipsHelper.ShowImportantRedTip("失败了")
            end
        end

        self.parentScript:CancelBatch()
    end

    if bHasHigherThanViolet then
        UIHelper.ShowConfirm("当前勾选有紫色品质以上藏品，请谨慎删除！", fnDelete)
    else
        fnDelete()
    end
end

function UIWidgetMysteryStorage:BatchTakeOut()
    local pPlayer = g_pClientPlayer
    if not pPlayer then
        return
    end

    local bSuccess = true
    for dwPendantIndex, nStackNum in pairs(self.tbSelected.tbBatch) do
        local nRetCode = pPlayer.PutMysteryPendantItemToPackage(dwPendantIndex)
        if nRetCode ~= ADD_ITEM_RESULT_CODE.SUCCESS then
            bSuccess = false
            OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.tCollectionResult[nRetCode])
            --OutputMessage("MSG_SYS", g_tStrings.tCollectionResult[nRetCode])
            break
        end
    end
    if bSuccess then
        OutputMessage("MSG_ANNOUNCE_YELLOW", g_tStrings.tCollectionResult[MYSTERY_ITEM_ERROR_CODE.SUCCESS])
        --OutputMessage("MSG_SYS", g_tStrings.tCollectionResult[MYSTERY_ITEM_ERROR_CODE.SUCCESS])
    end

    self.parentScript:CancelBatch()
end

function UIWidgetMysteryStorage:StartBatchManage()
    for _, script in ipairs(self.tScripts) do
        script:SetSelectMode(true, true)
    end

    local fnBatchTake = function()
        self:BatchTakeOut()
    end

    local fnBatchDiscard = function()
        self:BatchDelete()
    end

    local fnCancel = function()
        self:CancelBatchManage()
    end

    UIHelper.SetVisible(self.BtnDelete, false)
    self.bBatch = true
    self.tbSelected.tbBatch = {}
    self.parentScript:StartBatch(fnBatchTake, fnBatchDiscard, fnCancel)
    self.parentScript:UpdateSelectedNum(string.format("%d", table.get_len(self.tbSelected.tbBatch)))
end

function UIWidgetMysteryStorage:CancelBatchManage()
    UIHelper.SetVisible(self.BtnDelete, true)
    self.bBatch = false
    for _, script in ipairs(self.tScripts) do
        script:SetSelectMode(false, true)
        script:HideBatchNum()
    end
end

function UIWidgetMysteryStorage:ShowScene()
    if self.dwPendantIndex then
        self.parentScript:ShowScene(self.nModelCategory)
    else
        self.parentScript:HideScene()
    end
end

function UIWidgetMysteryStorage:OnEnterTab()
    if self.bInit then
        self:ShowScene()
    end
end

return UIWidgetMysteryStorage
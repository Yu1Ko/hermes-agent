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

local UIWidgetMysteryMyCollection = class("UIWidgetMysteryMyCollection")

function UIWidgetMysteryMyCollection:OnEnter(parentScript)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.bFirstEnter = true
    self.parentScript = parentScript
    self.bBatch = false
    self.tbSelected = {
        tbBatch = {},
        dwPendantIndex = nil,
        nType = nil,
    }
    self.nSelectedQuality = ALL_QUALITY
    self.szSearchText = ""
    self.nSelType = MYSTERY_PENDANT_TYPE.TOTAL
    self.nModelCategory = PendantModelCategory.Character
    
    self:UpdateInfo()
end

function UIWidgetMysteryMyCollection:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetMysteryMyCollection:BindUIEvent()
    UIHelper.BindUIEvent(self.TogFilter, EventType.OnClick, function()
        local tbConfig = FilterDef.Pendant
        _, self.scriptFilter = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.TogFilter, TipsLayoutDir.BOTTOM_RIGHT, tbConfig)
    end)

    UIHelper.BindUIEvent(self.BtnClean, EventType.OnClick, function()
        self.szSearchText = ""
        UIHelper.SetString(self.EditBoxSearch, "")
        self:UpdateInfo()
    end)

    UIHelper.BindUIEvent(self.BtnDelete, EventType.OnClick, function()
        self:Delete()
    end)

    UIHelper.BindUIEvent(self.BtnPreserve, EventType.OnClick, function()
        self:PreservePendant()
    end)
end

function UIWidgetMysteryMyCollection:RegEvent()
    Event.Reg(self, "ON_CHANGE_MYSTERY_PENDANT_NOTIFY", function()
        self:UpdateInfo()
    end)

    Event.Reg(self, "ON_SELECT_MYSTERY_PENDANT", function()
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

    Event.Reg(self, EventType.HideAllHoverTips, function(nBox, nIndex, bNewAdd)
        if self.scriptItemTip then
            self.scriptItemTip:OnInit()
            return
        end
    end)

    UIHelper.BindUIEvent(self.BtnManage, EventType.OnClick, function()
        self:StartBatchManage()
    end)
end

function UIWidgetMysteryMyCollection:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetMysteryMyCollection:UpdateInfo()
    local tAllItems = self:GetSelectedPendantList()
    self:UpdatePendantCell(tAllItems)
    self:UpdateSelectedPendant()
    self:UpdateButtonState()
end

function UIWidgetMysteryMyCollection:UpdatePendantCell(tAllItems)
    self.tScripts = {} ---@type UIWidgetMysteryItemCell[]
    local tSelID = {}
    local nSelType = MYSTERY_PENDANT_TYPE.BACK
    self.nSelType = nSelType
    local tSelWaistInfo = g_pClientPlayer.GetSelectMysteryPendant(MYSTERY_PENDANT_TYPE.WAIST)
    local tSelBackInfo = g_pClientPlayer.GetSelectMysteryPendant(MYSTERY_PENDANT_TYPE.BACK)

    if tSelWaistInfo and nSelType == MYSTERY_PENDANT_TYPE.TOTAL or nSelType == MYSTERY_PENDANT_TYPE.WAIST then
        tSelID[MYSTERY_PENDANT_TYPE.WAIST] = tSelWaistInfo
    end
    if tSelBackInfo and nSelType == MYSTERY_PENDANT_TYPE.TOTAL or nSelType == MYSTERY_PENDANT_TYPE.BACK then
        tSelID[MYSTERY_PENDANT_TYPE.BACK] = tSelBackInfo
    end

    local tFilteredList = self:GetFilteredPendants(tAllItems)
    local nOriginalToggleIndex = UIHelper.GetToggleGroupSelectedIndex(self.ToggleGroup)
    nOriginalToggleIndex = nOriginalToggleIndex >= #tFilteredList and #tFilteredList - 1 or nOriginalToggleIndex
    local fnSelectFunc
    UIHelper.RemoveAllChildren(self.ScrollStorageList)
    UIHelper.ToggleGroupRemoveAllToggle(self.ToggleGroup)
    
    for nIndex, tInfo in ipairs(tFilteredList) do

        local nType = MYSTERY_PENDANT_TYPE.BACK
        local bEquipped = tSelID[nType].dwPendantIndex == tInfo.dwPendantIndex
        local mysteryItem = UIHelper.AddPrefab(PREFAB_ID.WidgetMysteryItemCell, self.ScrollStorageList)
        mysteryItem:Init(PENDANT_ITEM_TYPE, tInfo.dwItemTabIndex, tInfo.dwPendantIndex)
        mysteryItem:SetToggleGroup(self.ToggleGroup)
        mysteryItem:SetEquipped(bEquipped)

        local fnFunc = function(dwItemID, bSelected)
            self:OnItemSelectChange(PENDANT_ITEM_TYPE, tInfo.dwItemTabIndex, tInfo.dwPendantIndex, nType, bSelected)
        end
        mysteryItem:SetSelectChangeCallback(fnFunc)

        if self.bFirstEnter and bEquipped then
            nOriginalToggleIndex = nIndex - 1
            self.bFirstEnter = false
        end

        if nOriginalToggleIndex == nIndex - 1 then
            fnSelectFunc = fnFunc
        end

        table.insert(self.tScripts, mysteryItem)
    end

    self:UpdateNodeVisible(#tFilteredList > 0, #tAllItems > 0)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollStorageList)

    if nOriginalToggleIndex ~= -1 then
        UIHelper.SetToggleGroupSelected(self.ToggleGroup, nOriginalToggleIndex)
        fnSelectFunc(nil, true)
    end
end

function UIWidgetMysteryMyCollection:UpdateSelectedPendant()
    self.itemScript = self.itemScript or UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.WidgetPropBox06) ---@type UIItemIcon

    if self.tbSelected.dwPendantIndex then
        self.itemScript:OnInitWithTabID(PENDANT_ITEM_TYPE, self.tbSelected.dwItemTabIndex)
        self.itemScript:SetRecallVisible(true)
        self.itemScript:SetRecallCallback(function()
            UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroup, nil)
            self:OnItemSelectChange(PENDANT_ITEM_TYPE, self.tbSelected.dwItemTabIndex, self.tbSelected.dwPendantIndex, self.tbSelected.nType, false)
        end)
    end

    UIHelper.SetVisible(self.itemScript._rootNode, self.tbSelected.dwPendantIndex ~= nil)
end

function UIWidgetMysteryMyCollection:UpdateNodeVisible(bHasFilterCell, bHasPendant)
    UIHelper.SetVisible(self.TogShowCharacter, bHasFilterCell)
    UIHelper.SetVisible(self.TogShowItem, bHasFilterCell)
    UIHelper.SetVisible(self.BtnDelete, bHasFilterCell)
    UIHelper.SetVisible(self.BtnDIY, bHasFilterCell)
    UIHelper.SetVisible(self.BtnPreserve, bHasFilterCell)

    UIHelper.SetVisible(self.WidgetSearchSift, bHasPendant)
    UIHelper.SetVisible(self.BtnManage, bHasPendant)
    UIHelper.SetVisible(self.TogAccessory06, bHasPendant)

    UIHelper.SetVisible(self.BtnClean, self.szSearchText ~= "")

    UIHelper.SetVisible(self.WidgetEmptySearch, bHasPendant and not bHasFilterCell)
    UIHelper.SetVisible(self.WidgetEmpty, not bHasPendant)
    UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, false)
end

function UIWidgetMysteryMyCollection:StartBatchManage()
    for _, script in ipairs(self.tScripts) do
        script:SetSelectMode(true, true)
    end

    local fnBatchDiscard = function()
        self:BatchDelete()
    end

    local fnCancel = function()
        self:CancelBatchManage()
    end

    self.bBatch = true
    self.tbSelected.tbBatch = {}
    self.parentScript:StartBatch(nil, fnBatchDiscard, fnCancel)
    self.parentScript:UpdateSelectedNum(string.format("%d", table.get_len(self.tbSelected.tbBatch)))
end

function UIWidgetMysteryMyCollection:BatchDelete()
    local pPlayer = g_pClientPlayer
    if not pPlayer then
        return
    end

    for dwPendantIndex, _ in pairs(self.tbSelected.tbBatch) do
        local nSelType = MYSTERY_PENDANT_TYPE.BACK
        pPlayer.DeleteMysteryPendant(nSelType, dwPendantIndex)
    end

    self.parentScript:CancelBatch()
end

function UIWidgetMysteryMyCollection:CancelBatchManage()
    self.bBatch = false
    for _, script in ipairs(self.tScripts) do
        script:SetSelectMode(false, true)
        script:HideBatchNum()
    end
end

function UIWidgetMysteryMyCollection:OnItemSelectChange(dwTabType, dwTabIndex, dwPendantIndex, nType, bSelected)
    if not self.bBatch then
        if bSelected then
            self.tbSelected.dwPendantIndex = dwPendantIndex
            self.tbSelected.dwItemTabIndex = dwTabIndex
            self.tbSelected.nType = nType
        elseif self.tbSelected.dwPendantIndex == dwPendantIndex then
            self.tbSelected.dwPendantIndex = nil
            self.tbSelected.dwItemTabIndex = nil
            self.tbSelected.nType = nil
        end
    else
        if bSelected then
            self.tbSelected.tbBatch[dwPendantIndex] = 1
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

    self:UpdateButtonState()
    self:UpdateSelectedPendant()
end

function UIWidgetMysteryMyCollection:GetFilteredPendants(tAllItems)
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

function UIWidgetMysteryMyCollection:GetSelectedPendantList()
    local pPlayer = g_pClientPlayer
    local tAllList

    if self.nSelType ~= MYSTERY_PENDANT_TYPE.TOTAL then
        tAllList = pPlayer.GetAllMysteryPendant(self.nSelType)
    else
        local tWaistList = pPlayer.GetAllMysteryPendant(MYSTERY_PENDANT_TYPE.WAIST)
        local tBackList = pPlayer.GetAllMysteryPendant(MYSTERY_PENDANT_TYPE.BACK)
        table.insert_tab(tWaistList, tBackList)
        tAllList = tWaistList
    end

    return tAllList
end

function UIWidgetMysteryMyCollection:ShowItemTip(dwItemType, dwItemID)
    self.scriptItemTip = self.scriptItemTip or UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetItemDetail)
    self.scriptItemTip:SetFunctionButtons({})
    self.scriptItemTip:SetForbidAutoShortTip(true)
    self.scriptItemTip:OnInitWithTabID(dwItemType, dwItemID)
end

function UIWidgetMysteryMyCollection:PreservePendant()
    local bSelectedPendant = self.tbSelected.dwPendantIndex ~= nil
    if bSelectedPendant then
        g_pClientPlayer.SelectMysteryPendant(self.tbSelected.nType, self.tbSelected.dwPendantIndex)
    else

    end
end

function UIWidgetMysteryMyCollection:Delete()
    if self.tbSelected.dwPendantIndex and g_pClientPlayer and not self.bBatch then
        local nResult = g_pClientPlayer.DeleteMysteryPendant(self.tbSelected.nType, self.tbSelected.dwPendantIndex)
        if nResult then
            TipsHelper.ShowImportantYellowTip("chenggong")
        else
            TipsHelper.ShowImportantRedTip("shibai")
        end
    end
end

function UIWidgetMysteryMyCollection:UpdateButtonState()
    local bSelectedPendant = self.tbSelected.dwPendantIndex ~= nil
    UIHelper.SetVisible(self.BtnDelete, bSelectedPendant)

    local tSelInfo = g_pClientPlayer.GetSelectMysteryPendant(self.tbSelected.nType)
    local nButtonState = tSelInfo.dwPendantIndex == self.tbSelected.dwPendantIndex and BTN_STATE.Disable or BTN_STATE.Normal
    UIHelper.SetButtonState(self.BtnPreserve, nButtonState)
end

function UIWidgetMysteryMyCollection:OnEnterTab()
    if self.bInit then
        self.parentScript:ShowScene(self.nModelCategory)
    end
end

return UIWidgetMysteryMyCollection
-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelWarehouse
-- Date: 2023-04-18 19:26:33
-- Desc: ?
-- ---------------------------------------------------------------------------------
local WarehouseItemType = 
{
    {szName = "所有", funcDeposit = function() RemoteCallToServer("On_LangKeXing_StoreAll") end, funcTakeOut = function() end},
    {szName = "装备和武器", funcDeposit = function() RemoteCallToServer("On_LangKeXing_StoreEquip") end, funcTakeOut = function() end},
    {szName = "基础材料", funcDeposit = function() RemoteCallToServer("On_LangKeXing_StoreCaiLiao") end, funcTakeOut = function() end},
    {szName = "可用道具", funcDeposit = function() RemoteCallToServer("On_LangKeXing_StoreFood") end, funcTakeOut = function() end},
}

local FuncWareHouseCheck = {
    [1] = function(item)
        return true
    end, -- 全部
    [2] = function(item)
        return item.nGenre == ITEM_GENRE.POTION or item.nGenre == ITEM_GENRE.FOOD
    end, -- 药品
    [3] = function(item)
        return item.nGenre == ITEM_GENRE.MATERIAL
    end, -- 材料
    [4] = function(item)
        return item.nGenre == ITEM_GENRE.EQUIPMENT
    end, -- 装备
}

local IMG_FILTER = {
    "UIAtlas2_Public_PublicButton_PublicButton1_icon_screen",
    "UIAtlas2_Public_PublicButton_PublicButton1_icon_screen_ing",
}


local UIPanelWarehouse = class("UIPanelWarehouse")

function UIPanelWarehouse:OnEnter(tbWareHouseList)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:Init(tbWareHouseList)
end

function UIPanelWarehouse:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelWarehouse:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.TogTravelingBagUnfold, EventType.OnClick, function()
        self:UpdateTravelingBagScreen()
    end)

    UIHelper.BindUIEvent(self.BtnLeaveWith, EventType.OnClick, function()
        if self.funcDeposit then
            self.funcDeposit()
        end
    end)

    UIHelper.BindUIEvent(self.BtnTakeOut, EventType.OnClick, function()
        self:EnterBulkRetore()
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function()
        self:ExitBulkReStore(true)
    end)

    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function()
        self:BulkReStore()
        self:ExitBulkReStore()
    end)

    UIHelper.BindUIEvent(self.BtnScreen, EventType.OnClick, function()
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.BtnScreen, TipsLayoutDir.RIGHT_CENTER, FilterDef.LKXWareHouse)
    end)
end

function UIPanelWarehouse:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, EventType.HideAllHoverTips, function()
        self:CloseTip()
        UIHelper.SetSelected(self.TogTravelingBagUnfold, false)
        UIHelper.SetSelected(self.TogUnfold, false)
    end)

    Event.Reg(self, "On_LangkexingM_RefreshStore", function(tbWareHouseList)
        self.tbWareHouseList = tbWareHouseList
        self:UpdateInfo()
    end)

    Event.Reg(self, EventType.OnFilter, function(szKey, tbInfo)
        if szKey ~= FilterDef.LKXWareHouse.Key then
            return
        end
        self:SetWareHouseCheckFunc(tbInfo[1][1])
    end)
end

function UIPanelWarehouse:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


function UIPanelWarehouse:Init(tbWareHouseList)
    self.tbWareHouseList = tbWareHouseList
    self:SetDepositFunc(WarehouseItemType[1])
    local tbTemp = FilterDef.LKXWareHouse.GetRunTime()
    local tbDefault = FilterDef.LKXWareHouse[1].tbDefault
    self:SetWareHouseCheckFunc(tbTemp and tbTemp[1][1] or tbDefault[1])
    self:UpdateTravelingBagList()
end



-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelWarehouse:UpdateInfo()
    self:UpdateWareHouseList()
    self:UpdateTravelingBagList()
end

function UIPanelWarehouse:UpdateTravelingBagScreen()
    if UIHelper.GetVisible(self.LayoutTravelingBagContent) then
        if UIHelper.GetChildrenCount(self.LayoutTravelingBagContent) == 0 then
            self.tbScriptTravelingBagScreen = {}
            for index, tbData in ipairs(WarehouseItemType) do
                tbData.ToggleGroup = self.ToggleGroupTravelingBagScreen
                local scriptView = UIHelper.AddPrefab(PREFAB_ID.WidgetWarehouseScreen, self.LayoutTravelingBagContent, tbData, function(tbData)
                    self:SetDepositFunc(tbData)
                end)
                table.insert(self.tbScriptTravelingBagScreen, scriptView)
            end
            Timer.AddFrame(self, 1, function()
                UIHelper.SetToggleGroupSelected(self.ToggleGroupTravelingBagScreen, 0)
            end)
        end
        UIHelper.LayoutDoLayout(self.LayoutTravelingBagContent)
    end
end

function UIPanelWarehouse:UpdateImgIconScreen()
    local szImg = self.nFuncIndex == 1 and IMG_FILTER[1] or IMG_FILTER[2]
    UIHelper.SetSpriteFrame(self.ImgIconScreen, szImg)
end

function UIPanelWarehouse:UpdateWareHouseList()
    self.tbWareHouseScript = {}
    UIHelper.RemoveAllChildren(self.ScrollViewWareHouse)
    for index, tbItemList in ipairs(self.tbWareHouseList) do
        local tbItemInfo = ItemData.GetItemInfo(tbItemList.nType, tbItemList.nID)
        if self.funcCheck(tbItemInfo) then
            local cellScript = UIHelper.AddPrefab(PREFAB_ID.WidgetBagBottom, self.ScrollViewWareHouse)
            cellScript:OnInitWithTabID(tbItemList.nType, tbItemList.nID, tbItemList.nCount)
            local itemScript = cellScript:GetItemScript()
            if itemScript then
                itemScript:SetToggleGroupIndex(ToggleGroupIndex.BagItem)
                itemScript:SetSelectMode(self.bBatchSelect)
                itemScript:SetSelectChangeCallback(function(nItemID, bSelected, nTabType, nTabID) 
                    self:OnSelectWareHouseItem(nTabType, nTabID, cellScript._rootNode, itemScript, index, bSelected)
                end)
            end
            table.insert(self.tbWareHouseScript, cellScript)
        end
    end
    UIHelper.ScrollViewDoLayout(self.ScrollViewWareHouse)
    UIHelper.ScrollToTop(self.ScrollViewWareHouse)
end

function UIPanelWarehouse:UpdateTravelingBagList()
    UIHelper.RemoveAllChildren(self.ScrollViewBag)
    local tbItemList = TravellingBagData.GetTravellingBagItems()
    for index, tbItemInfo in ipairs(tbItemList) do
        if tbItemInfo.hItem then
            local cellScript = UIHelper.AddPrefab(PREFAB_ID.WidgetBagBottom, self.ScrollViewBag)
            cellScript:OnEnter(tbItemInfo.nBox, tbItemInfo.nIndex)
            local itemScript = cellScript:GetItemScript()
            if itemScript then
                itemScript:SetToggleGroupIndex(ToggleGroupIndex.BagItem)
                itemScript:SetSelectMode(false)
                itemScript:SetSelectChangeCallback(function(dwItemID, bSelected) self:OnSelectTravelingBagItem(dwItemID, bSelected, cellScript._rootNode, itemScript) end)
            end
        end
    end
    UIHelper.ScrollViewDoLayout(self.ScrollViewBag)
    UIHelper.ScrollToTop(self.ScrollViewBag)
    local nItemNum = UIHelper.GetChildrenCount(self.ScrollViewBag)
    UIHelper.SetString(self.LabelBagSize, "（"..nItemNum.."/".."32".."）")
end

function UIPanelWarehouse:UpdateLabelTtrace(szName)
    UIHelper.SetString(self.LabelTtrace01, "寄存"..szName)
    UIHelper.SetString(self.LabelShowText, szName)
end

function UIPanelWarehouse:UpdateLabelTraceWareHouse(szName)
    UIHelper.SetString(self.LabelTtrace02, "取出"..szName)
end

function UIPanelWarehouse:OnSelectWareHouseItem(nTabType, nTabID, nodeBagCell, itemIconScript, nIndex, bSelected)
    if self.bInBulkReStore then
        if bSelected then
            self:AddBulkDisCard(nIndex)
        else
            self:DelBulkDisCard(nIndex)
        end
        self:UpdateDisCardNum()
        return
    end
    if bSelected then
        self:ShowTipBynTabType(nTabType, nTabID, nodeBagCell, itemIconScript, nIndex)
    else
        self:CloseTip()
    end
end

function UIPanelWarehouse:OnSelectTravelingBagItem(dwItemID, bSelected, nodeBagCell, itemIconScript)
    if bSelected then
        self:ShowTipByItemID(dwItemID, nodeBagCell, itemIconScript)
    else
        self:CloseTip()
    end
end

function UIPanelWarehouse:ShowTipByItemID(dwItemID, parent, itemIconScript)
    self:CloseTip()
    self.nCurIconScript = itemIconScript
    self.tips, self.tipsScriptView = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetItemTip, parent)

    local tbButton = {{ szName = "寄存", OnClick = function() 
        local item = ItemData.GetItem(dwItemID)
        RemoteCallToServer("On_LangKeXing_SingleStore", item.dwIndex)
        self:CloseTip()
    end}}
    self.tipsScriptView:SetFunctionButtons(tbButton)
    self.tipsScriptView:OnInitWithItemID(dwItemID)
end

function UIPanelWarehouse:ShowTipBynTabType(nTabType, nTabID, parent, itemIconScript, nIndex)
    self:CloseTip()
    self.nCurIconScript = itemIconScript
    self.tips, self.tipsScriptView = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetItemTip, parent)
    local tbButton = {{ szName = "取出", OnClick = function() 
        local item = ItemData.GetItem(dwItemID)
        RemoteCallToServer("On_LangKeXing_SingleRestore", nIndex)
        self:CloseTip()
    end}}
    self.tipsScriptView:SetFunctionButtons(tbButton)
    self.tipsScriptView:OnInitWithTabID(nTabType, nTabID)
end

function UIPanelWarehouse:UpdateDisCardNum()
    UIHelper.SetString(self.LabelSelectNum, #self.tbRestore)
end

function UIPanelWarehouse:CloseTip()
    if self.tipsScriptView then 
        self.nCurIconScript:RawSetSelected(false)
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetItemTip)
        self.tipsScriptView = nil
    end
end

function UIPanelWarehouse:SetDepositFunc(tbData)
    self.funcDeposit = tbData.funcDeposit
    self:UpdateLabelTtrace(tbData.szName)
end

function UIPanelWarehouse:SetSelectMode(bBatch, bHideCheck)
    if not self.tbWareHouseScript then return end
    for nIndex, script in ipairs(self.tbWareHouseScript) do
        local itemScript = script:GetItemScript()
        if itemScript then
            itemScript:SetSelectMode(bBatch, bHideCheck)
        end 
    end
end

function UIPanelWarehouse:AddBulkDisCard(nIndex)
    if not self.tbRestore then self.tbRestore = {} end
    table.insert(self.tbRestore, nIndex)
end

function UIPanelWarehouse:DelBulkDisCard(nIndex)
    if not self.tbRestore then return end
    for index, value in ipairs(self.tbRestore) do
        if value == nIndex then
            table.remove(self.tbRestore, index)
            break
        end
    end
end

--开始批量丢弃
function UIPanelWarehouse:EnterBulkRetore()
    self.bInBulkReStore = true
    self.tbRestore = {}
    UIHelper.SetVisible(self.WidgetAnchorBottom, true)
    self:SetSelectMode(true, false)
    self:UpdateDisCardNum()
end

--退出批量丢弃
function UIPanelWarehouse:ExitBulkReStore(bClearData)
    self.bInBulkReStore = false
    if bClearData then
        self.tbRestore = {}
    end
    UIHelper.SetVisible(self.WidgetAnchorBottom, false)
    self:SetSelectMode(false, false)
    self:UpdateDisCardNum()
end

function UIPanelWarehouse:BulkReStore()

    if not self.tbRestore then return end

    table.sort(self.tbRestore, function(l ,r)
        return l > r
    end)

    local function ReStore()
        if #self.tbRestore == 0 then 
            WaitingTipsData.RemoveWaitingTips("RefreshImage")
            return 
        end
        local nIndex = table.remove(self.tbRestore, 1)
        RemoteCallToServer("On_LangKeXing_SingleRestore", nIndex)
        if self.nReStoreTimer then
            Timer.DelTimer(self, self.nReStoreTimer)
            self.nReStoreTimer = nil
        end
        self.nReStoreTimer = Timer.AddFrame(self, 5, function()
            ReStore()
            self.nReStoreTimer = nil
        end)
    end

    local tMsg = {
        szType = "RefreshImage",
        szWaitingMsg = "正在取出，请稍后...",
        nPriority = 1,
        bHidePage = false,
        bSwallow = true,
    }
    WaitingTipsData.PushWaitingTips(tMsg)

    ReStore()

end

function UIPanelWarehouse:SetWareHouseCheckFunc(nIndex)
    self.nFuncIndex = nIndex
    self.funcCheck = FuncWareHouseCheck[nIndex]
    self:UpdateWareHouseList()
    self:UpdateImgIconScreen()
end

return UIPanelWarehouse
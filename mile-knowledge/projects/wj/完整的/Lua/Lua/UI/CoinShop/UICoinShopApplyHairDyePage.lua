-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICoinShopApplyHairDyePage
-- Date: 2025-10-16 16:54:20
-- Desc: ?
-- ---------------------------------------------------------------------------------
local INDEX_TO_COST_TYPE = {
    [1] = HAIR_CUSTOM_DYEING_TYPE.BASE_COLOR,
    [2] = HAIR_CUSTOM_DYEING_TYPE.HAIR_COLOR,
    [3] = HAIR_CUSTOM_DYEING_TYPE.DECORATION_COLOR,
}

local UICoinShopApplyHairDyePage = class("UICoinShopApplyHairDyePage")

function UICoinShopApplyHairDyePage:OnEnter(bDefaultIndex, tNowData, nNowHair, nNowDyeingIndex)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.bDefaultIndex = bDefaultIndex
    self.bSaveNewCase = true

    self.tNowData = tNowData
    self.nNowHair = nNowHair
    self.nNowDyeingIndex = nNowDyeingIndex

    self:UpdateInfo()
    self:UpdateCostItemList()
    self:UpdateBuyBtn()
end

function UICoinShopApplyHairDyePage:OnExit()
    self.bInit = false
    self:UnRegEvent()
    UIMgr.ShowView(VIEW_ID.PanelCoinShopBuildDyeing)
end

function UICoinShopApplyHairDyePage:BindUIEvent()
    UIHelper.SetToggleGroupAllowedNoSelection(self.TogGroupSaveWay, false)
    UIHelper.ToggleGroupAddToggle(self.TogGroupSaveWay, self.TogSaveNewCase)
    UIHelper.ToggleGroupAddToggle(self.TogGroupSaveWay, self.TogEditCase)

    UIHelper.BindUIEvent(self.TogSaveNewCase, EventType.OnSelectChanged, function(tog, bSelected)
        self.bSaveNewCase = bSelected
        self:UpdateCostItemList()
        self:UpdateBuyBtn()
    end)

    UIHelper.BindUIEvent(self.TogEditCase, EventType.OnSelectChanged, function(tog, bSelected)
        self.bSaveNewCase = not bSelected
        self:UpdateCostItemList()
        self:UpdateBuyBtn()
    end)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnBuy, EventType.OnClick, function(btn)
        self:BuyHairDye()
    end)
end

function UICoinShopApplyHairDyePage:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UICoinShopApplyHairDyePage:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICoinShopApplyHairDyePage:UpdateInfo()
    local hPlayer       = GetClientPlayer()
    if not hPlayer then
        return
    end
    local hDyeingManager = GetHairCustomDyeingManager()
    if not hDyeingManager then
        return
    end
    local nCount        = hPlayer.GetHairCustomDyeingCount(self.nNowHair)
    local nBoxSize      = hPlayer.GetHairCustomDyeingBoxSize()
	local bCanNew       = nCount < nBoxSize
    local tCost 		= hDyeingManager.GetDyeingDataCost(self.tNowData, self.nNowHair, self.nNowDyeingIndex)
    UIHelper.SetNodeGray(self.TogSaveNewCase, not bCanNew, true)
    UIHelper.SetNodeGray(self.TogEditCase, not tCost or #tCost == 0, true)
    UIHelper.SetEnable(self.TogSaveNewCase, bCanNew)
    UIHelper.SetEnable(self.TogEditCase, tCost and #tCost ~= 0)
    if not bCanNew then
        self.bSaveNewCase = false
        UIHelper.SetToggleGroupSelectedToggle(self.TogGroupSaveWay, self.TogEditCase)
    end

    for index, nCostType in ipairs(INDEX_TO_COST_TYPE) do
        local dwColorID = self.tNowData[nCostType]
        local bDecoration = nCostType == HAIR_CUSTOM_DYEING_TYPE.DECORATION_COLOR
        if dwColorID then
            local tColorInfo = bDecoration and Table_GetDyeingDecorationColorInfo(dwColorID) or Table_GetDyeingHairColorInfo(dwColorID)
            local szCostTypeName = bDecoration and "" or "（"..UIHelper.GBKToUTF8(tColorInfo.szCostTypeName).."系）"
            local LabelColor = self.tbDyeColorTypeLabel[index]
            local ImgColor = self.tbDyeColorImg[index]
            UIHelper.SetColor(ImgColor, cc.c3b(tColorInfo.nR, tColorInfo.nG, tColorInfo.nB))
            UIHelper.SetString(LabelColor, szCostTypeName)
        end
    end
end

function UICoinShopApplyHairDyePage:UpdateCostItemList()
    UIHelper.RemoveAllChildren(self.LayoutItem)

    local bEdit = not self.bSaveNewCase
    local nDyeingIndex = bEdit and self.nNowDyeingIndex or 0

    local tCostItem, tSellItem = self:GetCostList(nDyeingIndex)
    for _, tCostInfo in ipairs(tCostItem) do
        local dwBox = tCostInfo.dwBox
        local dwX = tCostInfo.dwX
        local scriptItem = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, self.LayoutItem)
        scriptItem:SetClickNotSelected(true)
        scriptItem:OnInit(dwBox, dwX)
        scriptItem:HideLabelCount()
        UIHelper.SetVisible(scriptItem.LabelCount, false)
        scriptItem:SetClickCallback(function()
            TipsHelper.ShowItemTips(scriptItem._rootNode, dwBox, dwX, true)
        end)
    end

    for _, tSellInfo in ipairs(tSellItem) do
        local dwTabType = tSellInfo.dwItemType
        local dwIndex = tSellInfo.dwItemIndex
        local scriptItem = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, self.LayoutItem)
        scriptItem:SetClickNotSelected(true)
        scriptItem:OnInitWithTabID(dwTabType, dwIndex)
        scriptItem:SetClickCallback(function()
            TipsHelper.ShowItemTips(scriptItem._rootNode, dwTabType, dwIndex, false)
        end)
    end

    UIHelper.LayoutDoLayout(self.LayoutItem)
    UIHelper.LayoutDoLayout(self.LayoutPrice)
end

function UICoinShopApplyHairDyePage:UpdateBuyBtn()
    local bSaveNewCase = self.bSaveNewCase ~= nil
    UIHelper.SetButtonState(self.BtnBuy, bSaveNewCase and BTN_STATE.Normal or BTN_STATE.Disable)
end

function UICoinShopApplyHairDyePage:GetCostList(nDyeingIndex)
    local hDyeingManager = GetHairCustomDyeingManager()
    if not hDyeingManager then
        return
    end
    local tCost = hDyeingManager.GetDyeingDataCost(self.tNowData, self.nNowHair, nDyeingIndex)
    local tSellItem = {}
    local tCostItem = {}
    if tCost then
        for _, dwCostType in ipairs(tCost) do
            if dwCostType == 0 then
                break
            end
            local dwCostBox, dwCostX = hDyeingManager.GetCostColorItemInPackage(dwCostType)
            if dwCostBox == INVENTORY_INDEX.INVALID then
                local tSellInfo = Table_GetSellDyeingItemInfo(dwCostType)
                table.insert(tSellItem, tSellInfo)
            else
                table.insert(tCostItem, {dwBox = dwCostBox, dwX = dwCostX})
            end
        end
    end
    return tCostItem, tSellItem
end

function UICoinShopApplyHairDyePage:BuyHairDye()
    local bSaveNewCase = self.bSaveNewCase
    local nDyeingIndex = bSaveNewCase and 0 or self.nNowDyeingIndex
    UIMgr.OpenSingle(false, VIEW_ID.PanelDyeingSettleAccounts, self.tNowData, self.nNowHair, nDyeingIndex)
end

return UICoinShopApplyHairDyePage
-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandOrderAwardCard
-- Date: 2024-01-12 16:22:24
-- Desc: ?
-- ---------------------------------------------------------------------------------
local tbFurnitureType = {
    ["Flower"] = 12,
    ["Cook"] = 4,
    ["Brew"] = 18,
}
local UIHomelandOrderAwardCard = class("UIHomelandOrderAwardCard")

function UIHomelandOrderAwardCard:OnEnter(DataModel)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.DataModel = DataModel
    self.bOwner = DataModel.bOwner
    self.tbInfo = {}
    self.tData = {}
    self.bCanSubmit = false
    UIHelper.SetVisible(self.BtnAssist, self.bOwner and self.nType == HLORDER_TYPE.FLOWER)
    UIHelper.SetVisible(self.BtnRenovate, self.bOwner and self.nType == HLORDER_TYPE.FLOWER)
    UIHelper.SetVisible(self._rootNode, false)
end

function UIHomelandOrderAwardCard:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHomelandOrderAwardCard:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnSubmit, EventType.OnClick, function ()
        if not self.bCanSubmit then
            if self.nType == HLORDER_TYPE.FLOWER then
                HomelandData.OpenHomeOverviewPanel({"2", "1"})
            elseif self.nType == HLORDER_TYPE.COOK then
                --打开家园总览界面
                HomelandData.OpenHomeOverviewPanel({"8", "4"})
            end
            UIMgr.Close(VIEW_ID.PanelRoadCollection)
            UIMgr.Close(VIEW_ID.PanelHomeOrder)
            UIMgr.Close(VIEW_ID.PanelHomeIdentity)
            return
        end
        Event.Dispatch(EventType.OnSubmitHomelandOrder, self.tInfo.dwID, self.nIndex)
    end)

    UIHelper.BindUIEvent(self.BtnRenovate, EventType.OnClick, function ()
        local nOrderType = self.nType
        if nOrderType == HLORDER_TYPE.FLOWER then
            RemoteCallToServer("On_HomeLand_RefreshOrder", self.tInfo.dwID, self.nIndex)
        elseif nOrderType == HLORDER_TYPE.COOK then
            RemoteCallToServer("On_HomeLand_RefreshSellOrder", self.tInfo.dwID, self.nIndex)
        end
    end)

    UIHelper.BindUIEvent(self.BtnAssist, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelOrderAssistPop, self.tInfo.dwID, self.nIndex, self.DataModel)
    end)
end

function UIHomelandOrderAwardCard:RegEvent()
    Event.Reg(self, EventType.OnHomeOrderSelectedCell, function (dwID, nType, nIndex)
        self.dwID = dwID
        self.nType = nType
        self.nIndex = nIndex
        self.tInfo = self.DataModel.GetOrderInfo(dwID, nType)
        self.tData = self.DataModel.GetOrderData(nType, nIndex)
        if self.tInfo then
            UIHelper.SetVisible(self._rootNode, true)
            self:UpdateInfo()
        end
    end)
end

function UIHomelandOrderAwardCard:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHomelandOrderAwardCard:UpdateInfo()
    local tInfo = self.tInfo
    if table.is_empty(tInfo) then
        return
    end
    if tInfo then
        self:UpdataOrderItemInfo(tInfo)
        self:UpdataRewardItemInfo(tInfo)
        self:UpdataAssistInfo()
    end
end

function UIHomelandOrderAwardCard:UpdataOrderItemInfo(tInfo)
    self.bCanSubmit = false
    UIHelper.RemoveAllChildren(self.WidgetItem80)
    if tInfo and tInfo.szImagePath ~= "" then
        local szBgPath = UIHelper.FixDXUIImagePath(tInfo.szImagePath)
        local szPattern = "_"..string.match(szBgPath, "_([^%.]+)%.")
        szBgPath = string.gsub(szBgPath, szPattern, "")
        UIHelper.SetTexture(self.ImgRightBg, szBgPath)
    end
    for _, v in pairs(tInfo.tItemList) do
        local dwTabType         = v.dwTabType
        local dwIndex           = v.dwIndex
        local dwPackItemIndex   = HomelandIdentity.GetPackItem(dwIndex)
        local nTotalCount       = v.nCount
        local nInBagCount       = ItemData.GetItemAmountInPackage(dwTabType, dwIndex)
        local nInLockerCount    = GDAPI_GetLockerItemCount(tInfo.nType, dwTabType, dwIndex)
        local nPackCount        = 0

        if dwPackItemIndex then
            nPackCount = ItemData.GetItemAmountInPackage(dwTabType, dwPackItemIndex)
        end
        local nAllCount    = nInBagCount + nInLockerCount + nPackCount
        local tItemInfo    = ItemData.GetItemInfo(dwTabType, dwIndex)

        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.WidgetItem80)
        script:OnInitWithTabID(dwTabType, dwIndex, nTotalCount)
        script:SetClickCallback(function ()
            TipsHelper.ShowItemTips(script._rootNode, dwTabType, dwIndex)
			script:SetClearSeletedOnCloseAllHoverTips(true)
        end)
        if tItemInfo then
            local szNum = string.format("%s/%s", nAllCount, nTotalCount)
            UIHelper.SetString(self.LabelItemItem, szNum)
            UIHelper.SetString(self.LabelItemName, UIHelper.GBKToUTF8(ItemData.GetItemNameByItemInfo(tItemInfo)))
            UIHelper.SetTextColor(script.LabelCount, cc.c3b(255, 125, 125))
        end
        if nAllCount >= nTotalCount then
            self.bCanSubmit = true
            UIHelper.SetTextColor(script.LabelCount, cc.c3b(255, 255, 255))
        end
    end
    if self.bCanSubmit then
        UIHelper.SetString(self.LabelSubmit, "上交")
    else
        UIHelper.SetString(self.LabelSubmit, self.nType == HLORDER_TYPE.FLOWER and "前往种植" or "前往制作")
    end
    UIHelper.SetVisible(self.BtnSubmit, not self.tData.bFinish)
    UIHelper.SetVisible(self.WidgetFinish, self.tData.bFinish)
    UIHelper.SetVisible(self.BtnAssist, self.bOwner and self.nType == HLORDER_TYPE.FLOWER and not self.tData.bFinish)
    UIHelper.SetVisible(self.BtnRenovate, not self.tData.bFinish and self.bOwner and
                            (self.nType == HLORDER_TYPE.FLOWER or self.nType == HLORDER_TYPE.COOK))
    UIHelper.SetTexture(self.ImgFg, HomelandOrderIcon[self.nType])
end

function UIHomelandOrderAwardCard:UpdataRewardItemInfo(tInfo)
    UIHelper.RemoveAllChildren(self.LayoutReward)
    for i, v in pairs(tInfo.tRewardList) do
        local dwTabType = v.dwTabType
        local dwIndex   = v.dwIndex
        local nCount    = v.nCount
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.LayoutReward)
        script:SetClearSeletedOnCloseAllHoverTips(true)
        script:OnInitWithTabID(dwTabType, dwIndex, nCount)
        script:SetToggleGroupIndex(ToggleGroupIndex.HomelandOrderRewardItem)
        script:SetClickCallback(function(nTabType, nTabID)
			TipsHelper.ShowItemTips(script._rootNode, dwTabType, dwIndex)
		end)
    end

    if self.tInfo.nMoney and self.tInfo.nMoney > 0 then
        local scriptMoneyIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.LayoutReward)
        scriptMoneyIcon:SetClearSeletedOnCloseAllHoverTips(true)
        scriptMoneyIcon:OnInitCurrency(CurrencyType.Money, self.tInfo.nMoney)
        scriptMoneyIcon:SetIconBySpriteFrameName("UIAtlas2_Public_PublicMoney_PublicMoney_Big_img_Jin_Big.png")
        scriptMoneyIcon:SetLabelCount(self.tInfo.nMoney)
        scriptMoneyIcon:SetToggleGroupIndex(ToggleGroupIndex.HomelandOrderRewardItem)
        scriptMoneyIcon:SetClickCallback(function(nTabType, nTabID)
            TipsHelper.ShowCurrencyTips(scriptMoneyIcon._rootNode, CurrencyType.Money, self.tInfo.nMoney)
        end)
    end

    local scriptExpIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.LayoutReward)
    scriptExpIcon:SetClearSeletedOnCloseAllHoverTips(true)
    scriptExpIcon:OnInitCurrency(CurrencyType[HLORDER_EXP_NAME[self.nType]], self.tInfo.nExp)
    scriptExpIcon:SetToggleGroupIndex(ToggleGroupIndex.HomelandOrderRewardItem)
    scriptExpIcon:SetClickCallback(function(nTabType, nTabID)
        TipsHelper.ShowCurrencyTips(scriptExpIcon._rootNode, CurrencyType[HLORDER_EXP_NAME[self.nType]], self.tInfo.nExp)
    end)

    local scriptArchitectureIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.LayoutReward)
    scriptArchitectureIcon:SetClearSeletedOnCloseAllHoverTips(true)
    scriptArchitectureIcon:OnInitCurrency(CurrencyType.Architecture, self.tInfo.nArchitecture)
    scriptArchitectureIcon:SetToggleGroupIndex(ToggleGroupIndex.HomelandOrderRewardItem)
    scriptArchitectureIcon:SetClickCallback(function(nTabType, nTabID)
        TipsHelper.ShowCurrencyTips(scriptArchitectureIcon._rootNode, CurrencyType.Architecture, self.tInfo.nArchitecture)
    end)
    UIHelper.LayoutDoLayout(self.LayoutReward)
end

function UIHomelandOrderAwardCard:UpdataAssistInfo()
    UIHelper.SetVisible(self.WidgetAssistMoney01, false)
    if not self.tData or not self.tData.bAssist then
        return
    end
    UIHelper.SetVisible(self.WidgetAssistMoney01, true)
    UIHelper.SetString(self.LabelMoneyToatal01, self.tData.nMoney)
    UIHelper.LayoutDoLayout(self.LayoutMoney01)
end

function UIHomelandOrderAwardCard:TryTransfer()
    local bMyCommunityHome = HomelandData.CheckIsMyCommunityHome()
    local bMyPriviteHome = HomelandData.CheckIsMyPriviteHome()
    if bMyCommunityHome or bMyPriviteHome then
        if self.nType == HLORDER_TYPE.FLOWER then
            HomelandData.TryTransferToFurniture(tbFurnitureType["Flower"])
            UIMgr.Close(VIEW_ID.PanelHomeOrder)
            UIMgr.Close(VIEW_ID.PanelHomeIdentity)
        elseif self.nType == HLORDER_TYPE.COOK then
            local script = UIHelper.ShowConfirm(g_tStrings.tbHomelandOrderToFurniture[self.nType], nil, function ()
                HomelandData.TryTransferToFurniture(tbFurnitureType["Cook"])
                UIMgr.Close(VIEW_ID.PanelHomeIdentity)
                UIMgr.Close(VIEW_ID.PanelHomeOrder)
            end)
            script:HideConfirmButton()
            script:ShowOtherButton()
            script:SetCancelButtonContent("前往烹饪")
            script:SetOtherButtonContent("前往酿造")
            script:SetOtherButtonClickedCallback(function ()
                HomelandData.TryTransferToFurniture(tbFurnitureType["Brew"])
                UIMgr.Close(VIEW_ID.PanelHomeOrder)
                UIMgr.Close(VIEW_ID.PanelHomeIdentity)
            end)
        end
    else
        -- TipsHelper.ShowNormalTip(g_tStrings.STR_HOMELAND_OVERVIEW_NEED_BACK)
        UIMgr.Close(VIEW_ID.PanelHomeOrder)
        UIMgr.Close(VIEW_ID.PanelHomeIdentity)
        UIMgr.Close(VIEW_ID.PanelHome)
        if self.nType == HLORDER_TYPE.FLOWER then
            RemoteCallToServer("On_HomeLand_GoHomeSmart", 2, 1, tbFurnitureType["Flower"])
        end
    end
end

return UIHomelandOrderAwardCard
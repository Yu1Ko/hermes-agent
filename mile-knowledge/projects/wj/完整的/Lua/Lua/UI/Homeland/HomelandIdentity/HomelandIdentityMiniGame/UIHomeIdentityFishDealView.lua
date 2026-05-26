-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomeIdentityFishDealView
-- Date: 2024-01-25 19:57:10
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomeIdentityFishDealView = class("UIHomeIdentityFishDealView")
local MEAT_TABTYPE = 5
local MEAT_INDEX   = 30827
local nHightQuality = 3 -- 蓝色
local DataModel = {}
local SELL_MODE = {
    MONEY = 1,
    MEAT  = 2,
}
function DataModel.Init()
    DataModel.tBagData    = GDAPI_GetFishBagData()
    DataModel.tFishInfo   = Table_GetAllFishInfo()
    DataModel.nFliterMode = 0
    DataModel.nSellMode   = SELL_MODE.MONEY
    DataModel.bFishBag    = true
end

function DataModel.Update()
    DataModel.tBagData = GDAPI_GetFishBagData()
end

function DataModel.GetFishInfo(dwID)
    for _, v in pairs(DataModel.tFishInfo) do
        if v.dwID == dwID then
            return v
        end
    end
end

function DataModel.GetFishPrice(dwID, nCount)
    local nMoney        = 0
    local nMeat         = 0
    local nArchitecture = 0
    local tInfo         = DataModel.GetFishInfo(dwID)

    if tInfo then
        nMoney = nCount * tInfo.nMoney
        nMeat  = nCount * tInfo.nMeat
        nArchitecture = nCount * tInfo.nArchitecture
    end

    return nMoney, nMeat, nArchitecture
end

function DataModel.UnInit()
    for i, v in pairs(DataModel) do
        if type(v) ~= "function" then
            DataModel[i] = nil
        end
    end
end

function UIHomeIdentityFishDealView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        DataModel.Init()
        self.bInit = true
    end
    self:Init()
end

function UIHomeIdentityFishDealView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHomeIdentityFishDealView:BindUIEvent()
    UIHelper.SetToggleGroupAllowedNoSelection(self.ToggleGroupCreel, true)
    UIHelper.SetToggleGroupAllowedNoSelection(self.ToggleGroupSell, true)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnSell, EventType.OnClick, function()
        local tRes     = {}
        local bFishBag = DataModel.bFishBag
        local bForMeat = DataModel.nSellMode == SELL_MODE.MEAT
        local bHaveHightQuality = false
        for _, v in pairs(self.tbSelectedFish) do
            bHaveHightQuality = bHaveHightQuality or (v.tInfo and v.tInfo.nQuality >= nHightQuality)
            table.insert(tRes, {nFishIndex = v.dwID, num = v.nCount})
        end

        if bForMeat and bHaveHightQuality then
            UIHelper.ShowConfirm(g_tStrings.STR_HOMELAND_FISH_DEAL_MEAT_CONFIRM, function ()
                RemoteCallToServer("On_HomeLand_SellFish", tRes, bFishBag, bForMeat)
            end)
        else
            RemoteCallToServer("On_HomeLand_SellFish", tRes, bFishBag, bForMeat)
        end
    end)

    UIHelper.BindUIEvent(self.BtnSelect, EventType.OnClick, function()
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.BtnSelect, TipsLayoutDir.BOTTOM_RIGHT, FilterDef.IdentityFishSell)
    end)

    for index, tog in ipairs(self.tbTogAoutSell) do
        UIHelper.SetToggleGroupIndex(tog, ToggleGroupIndex.ItemTipsRingSwitch)
        UIHelper.BindUIEvent(tog, EventType.OnClick, function(btn)
            DataModel.nSellMode = index
            self:UpdatePriceInfo()
        end)
    end
end

function UIHomeIdentityFishDealView:RegEvent()
    Event.Reg(self, EventType.HideAllHoverTips, function ()
        Event.Dispatch(EventType.OnClearUICommonItemSelect)
        self:OpenFishTips()
    end)

    Event.Reg(self, EventType.OnUpdateFishBagInfo, function ()
        self.tbSelectedFish = {}
        UIHelper.RemoveAllChildren(self.ScrollViewSell)
        self:UpdateInfo()
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewSell)
    end)

    Event.Reg(self, EventType.OnFilter, function (szKey, tbSelected)
        if szKey == FilterDef.IdentityFishSell.Key then
            DataModel.nFliterMode = tbSelected[1][1] - 1 or 0
            self.tbSelectedFish = {}
            UIHelper.RemoveAllChildren(self.ScrollViewSell)
            self:UpdateFishBagInfo()
            self:UpdateSellFishInfo()
            self:UpdatePriceInfo()
            UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewSell)
        end
    end)

    Event.Reg(self, EventType.OnFishDealOpenFishTips, function (tbFishInfo, nMaxNum)
        self:OpenFishTips(tbFishInfo, nMaxNum)
    end)
end

function UIHomeIdentityFishDealView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIHomeIdentityFishDealView:Init()
    self.tbSelectedFish = {}
    UIHelper.RemoveAllChildren(self.ScrollViewSell)

    self:UpdateFishBagInfo()
    self:UpdateSellFishInfo()
    self:UpdatePriceInfo()
    self:UpdateMeatItemIcon()
end

function UIHomeIdentityFishDealView:UpdateInfo()
    DataModel.Update()
    self:UpdateFishBagInfo()
    self:UpdateSellFishInfo()
    self:UpdatePriceInfo()
end

function UIHomeIdentityFishDealView:UpdateFishBagInfo()
    UIHelper.RemoveAllChildren(self.ScrollViewCreel)
    local tBagData = DataModel.tBagData
    if not tBagData then
        return
    end
    local bEmpty = true
    local nFliterMode = DataModel.nFliterMode
    for _, v in pairs(tBagData) do
        local tInfo = DataModel.GetFishInfo(v.dwID)
        if tInfo and (nFliterMode == 0 or nFliterMode == tInfo.nQuality) then
            bEmpty = false
            local szName = UIHelper.GBKToUTF8(tInfo.szName)
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetItemWithName, self.ScrollViewCreel)
            UIHelper.SetFontSize(script.LabelNum, 18)
            self:AddFishToSell(script, tInfo, v.dwID, v.nCount)    --默认全选
            script:SetLabelItemName(szName)
            script:SetLableCount(v.nCount)
            script:SetImgIconByIconID(tInfo.dwIconID)
            script:SetItemQualityBg(tInfo.nQuality)
            script:ToggleGroupAddToggle(self.ToggleGroupCreel)
            script:RegisterSelectEvent(function (bSelected)
                if not UIHelper.GetVisible(script.WidgetNum) then
                    UIHelper.ScrollToTop(self.ScrollViewSell)
                    self:AddFishToSell(script, tInfo, v.dwID, v.nCount, true)
                    -- UI需求：手动点击图标添加鱼时才播动画
                    UIHelper.PlayAni(self.tbSelectedFish[1].scriptSell, self.tbSelectedFish[1].scriptSell.AinAll, "AniPropItemCell")
                end
            end)
            UIHelper.SetVisible(script.ImgSelectBG , false)
        end
    end
    UIHelper.SetVisible(self.WidgetEmptyLeft, bEmpty)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewCreel)
end

function UIHomeIdentityFishDealView:UpdateSellFishInfo()
    local bEmpty = true
    self.tbSelectedFish = self.tbSelectedFish or {}
    for _, v in pairs(self.tbSelectedFish) do
        local tInfo = v.tInfo
        if tInfo and v.bAdd then
            bEmpty = false
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetDealSellCell, self.ScrollViewSell)
            script:OnEnter(tInfo, v.nCount)
            script:ToggleGroupAddToggle(self.ToggleGroupSell)
            script:SetOnClickCancelCallBack(function ()
                self:RemoveFishToSell(v.dwID)
            end)
            script:OnChangeEditCount(function (nCount)
                self:OnChangeFishCount(v.dwID, nCount)
            end)
            v.scriptSell = script
            v.bAdd = nil
        end
    end
    UIHelper.ScrollViewDoLayout(self.ScrollViewSell)
    UIHelper.SetVisible(self.WidgetEmptyRight, bEmpty)
    UIHelper.SetVisible(self.WidgetSellPrice, not bEmpty)
end

function UIHomeIdentityFishDealView:AddFishToSell(script, tbFishInfo, dwID, nCount, bUpdate)
    self.tbSelectedFish = self.tbSelectedFish or {}
    if dwID <= 0 then
        return
    end
    table.insert(self.tbSelectedFish, 1, {script = script, tInfo = tbFishInfo, dwID = dwID, nCount = nCount, bAdd = true})
    UIHelper.SetVisible(script.WidgetNum , true)
    UIHelper.SetString(script.LabelNum , nCount)

    if bUpdate then
        self:UpdatePriceInfo()
        local nCurPresent = UIHelper.GetScrollPercent(self.ScrollViewSell)
        self:UpdateSellFishInfo()
        UIHelper.ScrollToPercent(self.ScrollViewSell, nCurPresent)
    end
end

function UIHomeIdentityFishDealView:OnChangeFishCount(dwID, nCount)
    for _, tbInfo in ipairs(self.tbSelectedFish) do
        if tbInfo.dwID == dwID then
            tbInfo.nCount = nCount
            UIHelper.SetString(tbInfo.script.LabelNum , nCount)
            break
        end
    end
    self:UpdatePriceInfo()
end

function UIHomeIdentityFishDealView:UpdatePriceInfo()
    UIHelper.SetVisible(self.LayoutCurrency, DataModel.nSellMode == SELL_MODE.MONEY)
    UIHelper.SetVisible(self.WidgetReward, DataModel.nSellMode == SELL_MODE.MEAT)

    local nMoney, nMeatCount, nArchitecture = self:GetTotalFishPrice()
    local szMeatCount = string.format("鱼肉X%s", nMeatCount)

    local tbMoney = {UIHelper.MoneyToBullionGoldSilverAndCopper(nMoney)}
    for index, label in ipairs(self.tbMoneyLabel) do
        UIHelper.SetString(label, tbMoney[index])
    end
    UIHelper.SetString(self.tbMoneyLabel[4], nArchitecture)
    UIHelper.SetString(self.LabelItem, szMeatCount)

    UIHelper.CascadeDoLayoutDoWidget(self.LayoutGet, true, false)
end

function UIHomeIdentityFishDealView:UpdateMeatItemIcon()
    self.scriptMeatItem = self.scriptMeatItem or UIHelper.AddPrefab(PREFAB_ID.WidgetItem_44, self.WidgetItem40)
    self.scriptMeatItem:OnInitWithTabID(MEAT_TABTYPE, MEAT_INDEX)
    self.scriptMeatItem:SetClickNotSelected(true)
    self.scriptMeatItem:SetClickCallback(function ()
        TipsHelper.ShowItemTips(self.scriptMeatItem._rootNode, MEAT_TABTYPE, MEAT_INDEX, false)
    end)
end

function UIHomeIdentityFishDealView:RemoveFishToSell(dwID)
    self.tbSelectedFish = self.tbSelectedFish or {}
    if dwID <= 0 then
        return
    end
    for index, tbInfo in ipairs(self.tbSelectedFish) do
        if tbInfo.dwID == dwID then
            UIHelper.RemoveFromParent(tbInfo.scriptSell._rootNode, self.ScrollViewSell)
            UIHelper.SetVisible(tbInfo.script.WidgetNum , false)
            table.remove(self.tbSelectedFish, index)
            break
        end
    end

    -- self:UpdateSellFishInfo()
    local nCurPresent = UIHelper.GetScrollPercent(self.ScrollViewSell)
    local bCheckIsEmpty = table.is_empty(self.tbSelectedFish)
    UIHelper.SetVisible(self.WidgetEmptyRight, bCheckIsEmpty)
    UIHelper.SetVisible(self.WidgetSellPrice, not bCheckIsEmpty)
    UIHelper.ScrollViewDoLayout(self.ScrollViewSell)
    UIHelper.ScrollToPercent(self.ScrollViewSell, nCurPresent)
    self:UpdatePriceInfo()
end

function UIHomeIdentityFishDealView:GetTotalFishPrice()
    local nMoney             = 0
    local nMeat              = 0
    local nArchitecture      = 0
    local nTotalMoney        = 0
    local nTotalMeat         = 0
    local nTotalArchitecture = 0
    local tAllFish      = self.tbSelectedFish

    for _, v in pairs(tAllFish) do
        nMoney, nMeat, nArchitecture = DataModel.GetFishPrice(v.dwID, v.nCount or 0)
        nTotalMeat  = nTotalMeat + nMeat
        nTotalMoney = nTotalMoney + nMoney
        nTotalArchitecture = nTotalArchitecture + nArchitecture
    end
    return nTotalMoney, nTotalMeat, nTotalArchitecture
end

function UIHomeIdentityFishDealView:OpenFishTips(tbFishInfo, nMaxNum)
    if not self.scriptFishTips then
        self.scriptFishTips = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetTip)
    end

    if not tbFishInfo or table.is_empty(tbFishInfo) then
        UIHelper.SetVisible(self.WidgetTip, false)
        return
    end
    UIHelper.SetVisible(self.WidgetTip, true)
    self.scriptFishTips:OnInitWithFishInfo(tbFishInfo, nMaxNum)
end

return UIHomeIdentityFishDealView
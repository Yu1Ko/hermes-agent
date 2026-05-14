-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICustomizedSetPowerUpSelectMaterialView
-- Date: 2024-07-29 10:41:04
-- Desc: PanelPowerUpMaterialList
-- ---------------------------------------------------------------------------------

local UICustomizedSetPowerUpSelectMaterialView = class("UICustomizedSetPowerUpSelectMaterialView")

local tbTypeConfig = {
    ["ColorMount"] = {
        szTitle = "选择五彩石",
    },
    ["Enchant"] = {
        szTitle = "选择附魔",
    },
    ["BigEnchant"] = {
        szTitle = "选择附魔",
    },
}

local tbNavTitles = {"选择属性3", "选择属性2", "选择属性1", "选择五彩石"}

function UICustomizedSetPowerUpSelectMaterialView:OnEnter(szType, itemInfo, nCurSelectItemID, funcCallback, tbCurClassTitle)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.szType = szType
    self.nCurSelectItemID = nCurSelectItemID
    self.tbConfig = tbTypeConfig[szType]

    self.itemInfo = itemInfo
    self.funcCallback = funcCallback
    self.tbCurClassTitle = tbCurClassTitle or {}
    self:UpdateInfo()
end

function UICustomizedSetPowerUpSelectMaterialView:OnExit()
    self.bInit = false
end

function UICustomizedSetPowerUpSelectMaterialView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnCloseRight, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnReset, EventType.OnClick, function(btn)
        Event.Dispatch(EventType.OnSelectCustomizedSetMaterialCell, nil)
    end)
end

function UICustomizedSetPowerUpSelectMaterialView:RegEvent()
    Event.Reg(self, EventType.OnSelectCustomizedSetMaterialCell, function (nItemTabID)
        if self.funcCallback then
            self.funcCallback(nItemTabID)
        end
    end)

    Event.Reg(self, EventType.OnSelectCustomizedSetWuCaiCell, function (tbInfo, bAttri)
        if bAttri then
            table.insert(self.tbCurClassTitle, tbInfo.szName)
            self:UpdateColorMountInfo()
            Event.Dispatch(EventType.OnClassTitleChanged, self.tbCurClassTitle)
        else
            if self.funcCallback then
                self.funcCallback(tbInfo)
            end
            UIMgr.Close(self)
        end
    end)

    UIHelper.SetScrollViewCombinedBatchEnabled(self.ScrollViewFilterListOther, false)
end

function UICustomizedSetPowerUpSelectMaterialView:UpdateInfo()
    if self.szType == "ColorMount" then
        self:UpdateColorMountInfo()
    elseif self.szType == "Enchant" or self.szType == "BigEnchant" then
        self:UpdateEnchantInfo()
    end

    UIHelper.SetString(self.LabelTitle, self.tbConfig.szTitle)
end

function UICustomizedSetPowerUpSelectMaterialView:UpdateColorMountInfo()
    UIHelper.SetVisible(self.WidgetContentWuCai, true)
    UIHelper.SetVisible(self.WidgetContentOther, false)

    self.tbNavCells = {}
    self.tbCurClassTitle = self.tbCurClassTitle or {}

    UIHelper.RemoveAllChildren(self.ScrollViewBreadNaviScreen)
    for i, szTitle in ipairs(tbNavTitles) do
        local nIndex = i
        if #self.tbCurClassTitle >= nIndex - 1 then
            local szOption = self.tbCurClassTitle[nIndex] or szTitle
            local nCellPrefabID = PREFAB_ID.WidgetPublicBreadNaviCell

            if #szOption > 24 then
                nCellPrefabID = PREFAB_ID.WidgetPublicBreadNaviCellLong
            end

            if not self.tbNavCells[i] then
                self.tbNavCells[i] = UIHelper.AddPrefab(nCellPrefabID, self.ScrollViewBreadNaviScreen)
            end

            UIHelper.SetVisible(self.tbNavCells[i]._rootNode, true)
            self.tbNavCells[i]:OnEnter({szOption = szOption}, nIndex == 1, function ()
                self:RemoveClassTitle(nIndex)
            end)
            self.tbNavCells[i]:SetChecked(#self.tbCurClassTitle > nIndex - 1 or #self.tbCurClassTitle == 0)
        end
    end

    if self.nTimer then
        Timer.DelTimer(self, self.nTimer)
        self.nTimer = nil
    end

    self.nTimer = Timer.AddFrame(self, 1 ,function()
        UIHelper.ScrollViewDoLayout(self.ScrollViewBreadNaviScreen)
        UIHelper.ScrollToLeft(self.ScrollViewBreadNaviScreen, 0, false)
        if #self.tbCurClassTitle > 2 then
            UIHelper.ScrollToRight(self.ScrollViewBreadNaviScreen, 0, false)
        end
    end)

    local tbList = self.tbColorDiamondList or Table_GetAllColorDiamondList()
    self.tbData = {}
    if self.tbCurClassTitle[#self.tbCurClassTitle] then
        szCurTitle = self.tbCurClassTitle[#self.tbCurClassTitle]
    end

    for i, szCurTitle in ipairs(self.tbCurClassTitle) do
        tbList = tbList[szCurTitle]
    end

    local bShowTitle = #self.tbCurClassTitle < #tbNavTitles - 1
    for szClass, value in pairs(tbList) do
        if bShowTitle then
            table.insert(self.tbData, szClass)
        else
            table.insert(self.tbData, value)
        end
    end

    if bShowTitle then
        table.sort(self.tbData, function (a, b)
            return table.get_key(PlayerAttributeNameSort, a) < table.get_key(PlayerAttributeNameSort, b)
        end)
    end

    UIHelper.HideAllChildren(self.ScrollViewFilterList)
    self.tbCells = self.tbCells or {}
    for i, v in ipairs(self.tbData) do
        if not self.tbCells[i] then
            self.tbCells[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetMaterialCellWuCai, self.ScrollViewFilterList)
        end

        if bShowTitle then
            self.tbCells[i]:OnEnter({szName = v}, true)
        else
            local tInfo = clone(v)
            tInfo.nCurSelectItemID = self.nCurSelectItemID
            self.tbCells[i]:OnEnter(tInfo, false)
        end
        UIHelper.SetVisible(self.tbCells[i]._rootNode, true)
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewFilterList)
end

function UICustomizedSetPowerUpSelectMaterialView:UpdateEnchantInfo()
    UIHelper.SetVisible(self.WidgetContentWuCai, false)
    UIHelper.SetVisible(self.WidgetContentOther, true)

    local nEnchantCategory = EnchantCategory.Normal
    if self.szType == "BigEnchant" then
        nEnchantCategory = EnchantCategory.Season
    end
    local tbList = EnchantData.GetRecommendEnchantWithItemInfo(self.itemInfo, nEnchantCategory, EquipCodeData.dwCurKungfuID)
    UIHelper.HideAllChildren(self.ScrollViewFilterListOther)

    self.tbCells = self.tbCells or {}
    local nIndex = 1
    for nItemTabID, _ in pairs(tbList) do
        if not self.tbCells[nIndex] then
            self.tbCells[nIndex] = UIHelper.AddPrefab(PREFAB_ID.WidgetMaterialCellFuMo, self.ScrollViewFilterListOther)
        end

        UIHelper.SetVisible(self.tbCells[nIndex]._rootNode, true)
        self.tbCells[nIndex]:OnEnter(nItemTabID)
        self.tbCells[nIndex]:SetSelectedTabID(self.nCurSelectItemID)
        nIndex = nIndex + 1
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewFilterListOther)
end

function UICustomizedSetPowerUpSelectMaterialView:SetResetVis(bShow)
    UIHelper.SetVisible(self.BtnReset, bShow)
end

function UICustomizedSetPowerUpSelectMaterialView:SetColorMountList(tbColorDiamondList)
    self.tbColorDiamondList = tbColorDiamondList
end

function UICustomizedSetPowerUpSelectMaterialView:RemoveClassTitle(nIndex)
    for j = #self.tbCurClassTitle, nIndex, -1 do
        table.remove(self.tbCurClassTitle, j)
    end
    self:UpdateColorMountInfo()
    Event.Dispatch(EventType.OnClassTitleChanged, self.tbCurClassTitle)
end

return UICustomizedSetPowerUpSelectMaterialView
-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelSearchItem
-- Date: 2023-03-27 10:50:36
-- Desc: ?
-- ---------------------------------------------------------------------------------
local SORT_TYPE ={
    Official = 0,--品级
    Price = 1,--单价
}
local UIPanelSearchItem = class("UIPanelSearchItem")

function UIPanelSearchItem:OnEnter(szItemName)
    if not self.bInit then
        self.nShowType = -1
        for _, toggle in ipairs(self.TogPVP) do
            UIHelper.ToggleGroupAddToggle(self.ToggleGroupPVP, toggle)
        end
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:InitData(szItemName)
    self:InitUI()
end

function UIPanelSearchItem:OnExit()
    Event.Dispatch(EventType.OnSearchItemClose)
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelSearchItem:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnSort, EventType.OnClick, function()
        local nDescendingOrder = (self.nDescendingOrder + 1) % 2
        self:SetDescendingOrder(nDescendingOrder)
    end)

    UIHelper.BindUIEvent(self.BtnRefresh, EventType.OnClick, function()
        TradingData.ApplyNormalLookUp(true, self.nCurPage, self.nSortID, 0, self.nQuality, self.szSaleName, self.nDescendingOrder, self.nKungfuMask)
    end)


    UIHelper.BindUIEvent(self.BtnSearch, EventType.OnClick, function()
        TradingData.ApplyNormalLookUp(true, self.nCurPage, self.nSortID, 0, self.nQuality, self.szSaleName, self.nDescendingOrder, self.nKungfuMask)
        UIHelper.SetVisible(self.WidgetQualityFilter, false)
        UIHelper.SetVisible(self.WidgetTypeFilter, false)
        UIHelper.SetTextColor(self.LabelTypeFilter, cc.c4b(215, 246, 255, 255))
        UIHelper.SetTextColor(self.LabelQualityFilter, cc.c4b(215, 246, 255, 255))
    end)

    UIHelper.BindUIEvent(self.BtnSearchItem, EventType.OnClick, function()
        local tbCurClassTitle = nil
        if self.tbCurClassTitle then
            tbCurClassTitle = #self.tbCurClassTitle == 3 and self.tbCurClassTitle or nil--上一次选到了五彩石，这次打开还是同样的界面
        end
        local scriptView = UIMgr.Open(VIEW_ID.PanelPowerUpMaterialList, "ColorMount", nil, nil, function (tbInfo)
            if not tbInfo then
                local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelPowerUpMaterialList)
                scriptView:RemoveClassTitle(1)
                return
            end
            self:SetItemName(tbInfo.szName)
            TradingData.ApplyNormalLookUp(true, self.nCurPage, self.nSortID, 0, self.nQuality, self.szSaleName, self.nDescendingOrder, self.nKungfuMask)
        end, tbCurClassTitle)
    end)

    UIHelper.BindUIEvent(self.BtnTypeFilter, EventType.OnClick, function()
        local bVisible = UIHelper.GetVisible(self.WidgetTypeFilter)
        UIHelper.SetVisible(self.WidgetTypeFilter, not bVisible)
        UIHelper.SetVisible(self.WidgetQualityFilter, false)
        UIHelper.SetRotation(self.ImgDownTypeFilter, bVisible and -90 or 0)
        UIHelper.SetTextColor(self.LabelTypeFilter, bVisible and cc.c4b(215, 246, 255, 255) or cc.c4b(255, 255, 255, 255))
        UIHelper.SetTextColor(self.LabelQualityFilter, cc.c4b(215, 246, 255, 255))
    end)

    UIHelper.BindUIEvent(self.BtnQualityFilter, EventType.OnClick, function()
        local bVisible = UIHelper.GetVisible(self.WidgetQualityFilter)
        UIHelper.SetVisible(self.WidgetQualityFilter, not bVisible)
        UIHelper.SetVisible(self.WidgetTypeFilter, false)
        UIHelper.SetRotation(self.ImgDownQualityFilter, bVisible and -90 or 0)
        UIHelper.SetTextColor(self.LabelQualityFilter, bVisible and cc.c4b(215, 246, 255, 255) or cc.c4b(255, 255, 255, 255))
        UIHelper.SetTextColor(self.LabelTypeFilter, cc.c4b(215, 246, 255, 255))
    end)
    UIHelper.BindUIEvent(self.BtnClose01, EventType.OnClick, function()
        self:SetItemName("")
    end)

    UIHelper.BindUIEvent(self.BtnReset, EventType.OnClick, function()
        self.bReset = true
        self:InitData()
        self:SetTotalPage(0)
        self:SetSearchRes({})
        self.bReset = false
        -- self:UpdateInfo_History()
    end)

    UIHelper.BindUIEvent(self.BtnBack, EventType.OnClick, function()
        self:UpdateInfo_History()
    end)

    UIHelper.BindUIEvent(self.TogQualityFilterAll, EventType.OnSelectChanged, function(toggle, bSelect)
        if bSelect then
            self:SetCurQuality(-1)
        end
    end)

    UIHelper.BindUIEvent(self.TogQualityFilterGray, EventType.OnSelectChanged, function(toggle, bSelect)
        if bSelect then
            self:SetCurQuality(0)
        end
    end)

    UIHelper.BindUIEvent(self.TogQualityFilterWhite, EventType.OnSelectChanged, function(toggle, bSelect)
        if bSelect then
            self:SetCurQuality(1)
        end
    end)

    UIHelper.BindUIEvent(self.TogQualityFilterGreen, EventType.OnSelectChanged, function(toggle, bSelect)
        if bSelect then
            self:SetCurQuality(2)
        end
    end)

    UIHelper.BindUIEvent(self.TogQualityFilterBlue, EventType.OnSelectChanged, function(toggle, bSelect)
        if bSelect then
            self:SetCurQuality(3)
        end
    end)

    UIHelper.BindUIEvent(self.TogQualityFilterPurple, EventType.OnSelectChanged, function(toggle, bSelect)
        if bSelect then
            self:SetCurQuality(4)
        end
    end)

    UIHelper.BindUIEvent(self.TogQualityFilterOrange, EventType.OnSelectChanged, function(toggle, bSelect)
        if bSelect then
            self:SetCurQuality(5)
        end
    end)

    UIHelper.BindUIEvent(self.BtnDelete, EventType.OnClick, function()
        TradingData.ClearHistory()
        self:UpdateInfo_History()
    end)

    UIHelper.BindUIEvent(self.BtnLeft, EventType.OnClick, function()
        local nPage = self.nCurPage - 1
        nPage = math.max(1, nPage)
        if TradingData.ApplyNormalLookUp(true, nPage, self.nSortID, 0, self.nQuality, self.szSaleName, self.nDescendingOrder, self.nKungfuMask) then
            self:SetCurPage(nPage)
        end
    end)

    UIHelper.BindUIEvent(self.BtnRight, EventType.OnClick, function()
        local nPage = self.nCurPage + 1
        nPage = math.min(nPage, self.nTotalPage)
        if TradingData.ApplyNormalLookUp(true, nPage, self.nSortID, 0, self.nQuality, self.szSaleName, self.nDescendingOrder, self.nKungfuMask) then
            self:SetCurPage(nPage)
        end
    end)

    if Platform.IsWindows() or Platform.IsMac() then

        UIHelper.RegisterEditBox(self.EditBox, function(szType, _editbox)
            if szType == "changed" then
                local szText = UIHelper.GetText(self.EditBox)
                self:SetItemName(szText, true)
            elseif szType == "ended" then
                TradingData.ApplyNormalLookUp(true, self.nCurPage, self.nSortID, 0, self.nQuality, self.szSaleName, self.nDescendingOrder, self.nKungfuMask)
            end
        end)

        UIHelper.RegisterEditBoxChanged(self.EditPaginate, function()
            local szText = UIHelper.GetText(self.EditPaginate)
            local nPage = tonumber(szText)
            if TradingData.ApplyNormalLookUp(true, nPage, self.nSortID, 0, self.nQuality, self.szSaleName, self.nDescendingOrder, self.nKungfuMask) then
                self:SetCurPage(nPage)
            end
        end)
    else

        UIHelper.RegisterEditBox(self.EditBox, function(szType, _editbox)
            if szType == "return" then
                local szText = UIHelper.GetText(self.EditBox)
                self:SetItemName(szText, true)
                TradingData.ApplyNormalLookUp(true, self.nCurPage, self.nSortID, 0, self.nQuality, self.szSaleName, self.nDescendingOrder, self.nKungfuMask)
            end
        end)
        UIHelper.RegisterEditBoxReturn(self.EditPaginate, function()
            local szText = UIHelper.GetText(self.EditPaginate)
            local nPage = tonumber(szText)
            if TradingData.ApplyNormalLookUp(true, nPage, self.nSortID, 0, self.nQuality, self.szSaleName, self.nDescendingOrder, self.nKungfuMask) then
                self:SetCurPage(nPage)
            end
        end)

    end

    UIHelper.BindUIEvent(self.BtnPVP, EventType.OnClick, function()
        UIHelper.AddPrefab(PREFAB_ID.WidgetFiltrateTip, self.WidgetFiltrateTip, FilterDef.TradingSearchItem)
    end)

    for index, toggle in ipairs(self.TogPVP) do
        UIHelper.BindUIEvent(toggle, EventType.OnSelectChanged, function(_, bSelect)
            if bSelect then
                self.nShowType = index - 2
                -- 全部 -1 ；PVP 0 ; PVE 1 ;PVX 2
                self:UpdateType()
                UIHelper.RemoveAllChildren(self.WidgetFiltrateTip)
            end
        end)
    end

    UIHelper.BindUIEvent(self.BtnClosePVP, EventType.OnClick, function()
        UIHelper.RemoveAllChildren(self.WidgetFiltrateTip)
    end)


    UIHelper.BindUIEvent(self.BtnMail, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelEmail)
    end)

    UIHelper.BindUIEvent(self.BtnSortLevel, EventType.OnClick, function()
        local bLevelDesc = not self.bLevelDesc
        self:SetLevelDesc(bLevelDesc)
    end)

end

function UIPanelSearchItem:RegEvent()
    Event.Reg(self, EventType.ON_NORMAL_LOOK_UP_RES, function(nTotalPage, tbInfo)
        self:SetTotalPage(nTotalPage)
        self:SetSearchRes(tbInfo)
        self:UpdateInfo_History()
    end)

    -- Event.Reg(self, EventType.OnBuyItemClose, function()
    --     local szText = UIHelper.GetText(self.EditPaginate)
    --     local nPage = tonumber(szText)
    --     TradingData.ApplyNormalLookUp(false, nPage, self.nSortID, 0, self.nQuality, self.szSaleName, self.nDescendingOrder)
    -- end)


    Event.Reg(self, EventType.HideAllHoverTips, function()
        if self.scriptItemTip then
            UIHelper.RemoveAllChildren(self.WidgetItemTip1)
            self.scriptItemTip = nil
            self.nCurSelectIconView:RawSetSelected(false)
        end
        UIHelper.SetVisible(self.WidgetQualityFilter, false)
        UIHelper.SetVisible(self.WidgetTypeFilter, false)
        UIHelper.SetRotation(self.ImgDownQualityFilter, -90)
        UIHelper.SetRotation(self.ImgDownTypeFilter, -90)
        UIHelper.SetTextColor(self.LabelTypeFilter, cc.c4b(215, 246, 255, 255))
        UIHelper.SetTextColor(self.LabelQualityFilter, cc.c4b(215, 246, 255, 255))
        UIHelper.RemoveAllChildren(self.WidgetFiltrateTip)
    end)

    Event.Reg(self, EventType.ON_SHOW_TRADE_ITEM_CELL_TIP, function(nTabType, nTabID, scriptView, dwID)
        if nTabType and nTabID and UIHelper.GetVisible(self._rootNode) then
            if not self.scriptItemTip then
                self.tipNode, self.scriptItemTip = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetItemTip, scriptView._rootNode)
            end

            if nTabType and nTabID then
                local tbPreviewBtn = {}
                local tbButton = {}
                if OutFitPreviewData.CanPreview(nTabType, nTabID) then
                    tbPreviewBtn = OutFitPreviewData.SetPreviewBtn(nTabType, nTabID)
                end
                if #tbPreviewBtn > 0 then
                    table.insert(tbButton, tbPreviewBtn[1])
                end
                self.scriptItemTip:SetFunctionButtons(tbButton)
            else
                self.scriptItemTip:SetFunctionButtons({})
            end

            if dwID then
                self.scriptItemTip:OnInitWithItemID(dwID)
            else
                self.scriptItemTip:OnInitWithTabID(nTabType, nTabID)
            end

            self.nCurSelectIconView = scriptView
        else
            UIHelper.RemoveAllChildren(self.WidgetItemTip1)
            self.scriptItemTip = nil
        end
    end)

    Event.Reg(self, EventType.OnClassTitleChanged, function(tbCurClassTitle)
        self.tbCurClassTitle = tbCurClassTitle
    end)

    Event.Reg(self, EventType.OnFilter, function(szKey, tbInfo)
        if szKey ~= FilterDef.TradingSearchItem.Key then
            return
        end

        -- local bSetKungfuMask = false
        if tbInfo[1] then
            self:SetWeaponType(tbInfo[1][1] - 2)
        end

        local nKungfuMask = self:GetKungfuMask(tbInfo[2])
        if nKungfuMask ~= self.nKungfuMask then
            self:SetKungfuMask(nKungfuMask)
            -- bSetKungfuMask = true
        end

        -- if not bSetKungfuMask then return end--既没设置品质也没设置心法时，不拉取数据
        -- TradingData.ApplyNormalLookUp(true, self.nCurPage, self.nSortID, 0, self.nQuality, nil, self.nDescendingOrder, self.nKungfuMask)
    end)
end

function UIPanelSearchItem:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


function UIPanelSearchItem:InitData(szItemName)
    FilterDef.TradingSearchItem.Reset()
    self.tbBusinessTypeInfo = TradingData.GetBusinessTypeInfo()
    self:SetLevelDesc(false)
    self:SetWeaponType(-1, true)
    self:UpdateQualityInfo()
    self:SetCurQuality(-1)
    self:SetKungfuMask(0)
    self:SetSortID(0)
    self:SetTotalPage(1)
    self:SetItemName(szItemName or "")
    self:SetCurPage(1)
    self:SetDescendingOrder(0, self.szSaleName == "")
end

function UIPanelSearchItem:InitUI()
    UIHelper.AddPrefab(PREFAB_ID.WidgetCurrency, self.LayoutRightTop2 , function()
        UIHelper.LayoutDoLayout(self.LayoutRightTop2)
        UIHelper.LayoutDoLayout(self.LayoutRightTop)
    end)
    UIHelper.SetTouchDownHideTips(self.BtnTypeFilter, false)
    UIHelper.SetTouchDownHideTips(self.BtnQualityFilter, false)

    UIHelper.SetTouchDownHideTips(self.ScrollViewDateFilter, false)
    UIHelper.SetTouchDownHideTips(self.LayoutQualityFilter, false)

    UIHelper.SetSwallowTouches(self.ScrollViewDateFilter, true)
    UIHelper.SetSwallowTouches(self.LayoutQualityFilter, true)
    self:UpdateInfo_WidgetTypeFilter()
    self:UpdateInfo_History()
end




-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelSearchItem:UpdateInfo()

end

function UIPanelSearchItem:UpdateQualityInfo()
    self.tbQualityToggleInfo = {}
    self.tbQualityToggleInfo[-1] = self.TogQualityFilterAll
    self.tbQualityToggleInfo[0] = self.TogQualityFilterGray
    self.tbQualityToggleInfo[1] = self.TogQualityFilterWhite
    self.tbQualityToggleInfo[2] = self.TogQualityFilterGreen
    self.tbQualityToggleInfo[3] = self.TogQualityFilterBlue
    self.tbQualityToggleInfo[4] = self.TogQualityFilterPurple
    self.tbQualityToggleInfo[5] = self.TogQualityFilterOrange
end

function UIPanelSearchItem:UpdateInfo_WidgetTypeFilter()
    self.tbTypeToggleInfo = {}
    for index, tbInfo in ipairs(self.tbBusinessTypeInfo) do
        local scriptView = UIHelper.AddPrefab(PREFAB_ID.WidgetTradeTypeFilter, self.ScrollViewDateFilter, tbInfo, self, self.tbTypeToggleInfo)
    end
    UIHelper.ScrollViewDoLayout(self.ScrollViewDateFilter)
    UIHelper.ScrollToTop(self.ScrollViewDateFilter)
    Timer.AddFrame(self, 1, function ()
        self:UpdateInfo_Type()
    end)
end

function UIPanelSearchItem:UpdateInfo_History()


    UIHelper.RemoveAllChildren(self.ScrolHistoryItem)
    local tbHistory = TradingData.GetHistoryList()
    for index = #tbHistory, 1, -1 do
        UIHelper.AddPrefab(PREFAB_ID.WidgetHistoryResultCell, self.ScrolHistoryItem, tbHistory[index], self)
    end
    UIHelper.SetVisible(self.WidgetEmptyHistory, #tbHistory == 0)
    UIHelper.ScrollViewDoLayout(self.ScrolHistoryItem)
    UIHelper.ScrollToTop(self.ScrolHistoryItem)
    UIHelper.SetSwallowTouches(self.ScrolHistoryItem, false)
end

function UIPanelSearchItem:UpdateInfo_Result()
    local tbResultData = self.tbCurBusinessResultData
    if not tbResultData then return end

    UIHelper.SetVisible(self.WidgetEmptyItem, #tbResultData ==0)
    UIHelper.SetVisible(self.WidgetPaginate, #tbResultData ~=0)

    local szItemName = UIHelper.GetText(self.EditBox)
    szItemName = szItemName ~= "" and szItemName or "全部物品"
    if self.bReset then
        szItemName = ""
    end
    UIHelper.SetString(self.LabelSearchResultTitle_copy, szItemName)

    table.sort(tbResultData, function(l, r)
        if not l or not r then return false end
        if self.nSortType == SORT_TYPE.Official then
            if not l.Item or not r.Item then return false end
            local nLeftLevel = l.Item.nLevel
            local nRightLevel = r.Item.nLevel
            if nLeftLevel == 0 and not self.bLevelDesc then--没品级的永远排在最后
                nLeftLevel = nRightLevel + 1
            end
            if nRightLevel == 0 and not self.bLevelDesc then
                nRightLevel = nLeftLevel + 1
            end
            if nLeftLevel ~= nRightLevel then
                if self.bLevelDesc then
                    return nLeftLevel > nRightLevel
                else
                    return nLeftLevel < nRightLevel
                end
            end
        else
            local nLMoney = CovertMoneyToCopper(l.Price)
            local nRMoney = CovertMoneyToCopper(r.Price)
            if self.nDescendingOrder == 1 then
                return nLMoney > nRMoney
            else
                return nLMoney < nRMoney
            end
        end
    end)
    UIHelper.RemoveAllChildren(self.ScrolItem)
    local tbInfo = {}
    for index, tbData in ipairs(tbResultData) do
        tbData.bSell = false
        table.insert(tbInfo, tbData)
        if index%2 == 0 or (index%2 ~= 0 and index == #tbResultData) then
            UIHelper.AddPrefab(PREFAB_ID.WidgetTradeItemClass, self.ScrolItem, tbInfo, self.ToggleGroupSearch)
            tbInfo = {}
        end
    end
    UIHelper.ScrollViewDoLayout(self.ScrolItem)
    UIHelper.ScrollToTop(self.ScrolItem)
    UIHelper.SetSwallowTouches(self.ScrolItem, false)
end

function UIPanelSearchItem:UpdateInfo_CurPage()
    UIHelper.SetText(self.EditPaginate, self.nCurPage)
end

function UIPanelSearchItem:UpdateLevelSortDesc()

    UIHelper.SetOpacity(self.ImgUpLevel, self.bLevelDesc == false and self.nSortType == SORT_TYPE.Official and 255 or 70)
    UIHelper.SetOpacity(self.ImgDownLevel, self.bLevelDesc and true and self.nSortType == SORT_TYPE.Official and 255 or 70)
end


function UIPanelSearchItem:UpdateInfo_TotalPage()
    UIHelper.SetString(self.LabelPaginate, "/"..self.nTotalPage)
end

function UIPanelSearchItem:UpdateInfo_Type()
    UIHelper.SetString(self.LabelTypeFilter, "种类" .. "（" .. self:GetTypeNameBySortID(self.nSortID) .. "）")
    if self.tbTypeToggleInfo then
        for key, toggle in pairs(self.tbTypeToggleInfo) do
           UIHelper.SetSelected(toggle, key == self.nSortID + 1, false)
        end
    end
end


function UIPanelSearchItem:UpdateInfo_Quality()
    UIHelper.SetString(self.LabelQualityFilter, "品质" .. "（" .. g_tStrings.STR_PARTNER_BAG_QUALITY[self.nQuality] .. "）")
    if self.tbQualityToggleInfo then
        for key, toggle in pairs(self.tbQualityToggleInfo) do
            UIHelper.SetSelected(toggle, key == self.nQuality, false)
            UIHelper.SetTouchDownHideTips(toggle, false)
         end
    end
end

function UIPanelSearchItem:UpdateSortUI()
    if not self.nDescendingOrder or not self.nSortType then return end
    UIHelper.SetString(self.LabelDescibe01_copy, "单价")
    UIHelper.SetOpacity(self.ImgUp, self.nDescendingOrder == 0 and self.nSortType == SORT_TYPE.Price and 255 or 70)
    UIHelper.SetOpacity(self.ImgDown, self.nDescendingOrder == 1 and self.nSortType == SORT_TYPE.Price and 255 or 70)
end

function UIPanelSearchItem:UpdateSortLevelVis()
    UIHelper.SetVisible(self.BtnSortLevel, TradingData.IsFliterWeaponType(self.nSortID) or self.nSortID == 0)
    UIHelper.LayoutDoLayout(self.LayoutBtn)
end

function UIPanelSearchItem:SetWeaponType(nShowType, bForbidUpdateUI)
    if self.nShowType == nShowType then return false end
    self.nShowType = nShowType
    if bForbidUpdateUI then return true end
    self:SetBusinessResultData()
    return true
end

function UIPanelSearchItem:SetBusinessResultData()
    if not self.tbSearchRes then return end
    if self:IsFliterType() then
        self.tbCurBusinessResultData = TradingData.GetBusinessResultData(self.tbSearchRes, self.nShowType)
    else
        self.tbCurBusinessResultData = TradingData.GetBusinessResultData(self.tbSearchRes)
    end
    self:UpdateInfo_Result()
end

function UIPanelSearchItem:SetCurQuality(nQuality)
    self.nQuality = nQuality
    self:UpdateInfo_Quality()

end

function UIPanelSearchItem:SetSortID(nSortID)
    self.nSortID = nSortID
    self:UpdateInfo_Type()
    self:SetFliterTypeButtonState()
    self:UpdateSortLevelVis()
end

function UIPanelSearchItem:SetSortType(nSortType)
    self.nSortType = nSortType
end

function UIPanelSearchItem:SetCurPage(nPage)
    self.nCurPage = nPage
    self:UpdateInfo_CurPage()
end

function UIPanelSearchItem:SetItemName(szName, bNotSetText)
    self.szSaleName = szName
    if not bNotSetText then
        UIHelper.SetText(self.EditBox, self.szSaleName)
    end
end

function UIPanelSearchItem:SetTotalPage(nTotalPage)
    nTotalPage = math.max(nTotalPage, 1)
    self.nTotalPage = nTotalPage
    self:UpdateInfo_TotalPage()
end

function UIPanelSearchItem:SetSearchRes(tbInfo)
    self.tbSearchRes = tbInfo
    self:SetBusinessResultData()
end

function UIPanelSearchItem:SetDescendingOrder(nDescendingOrder, bNotApply)
    self:SetSortType(SORT_TYPE.Price)
    self.nDescendingOrder = nDescendingOrder

    if bNotApply then
        self:UpdateSortUI()
        self:UpdateLevelSortDesc()
        return
    end

    if TradingData.ApplyNormalLookUp(true, self.nCurPage, self.nSortID, 0, self.nQuality, self.szSaleName, self.nDescendingOrder) then
        self:UpdateSortUI()
    else
        self.nDescendingOrder = (self.nDescendingOrder + 1) % 2
    end
    self:UpdateLevelSortDesc()
end

function UIPanelSearchItem:GetTypeNameBySortID(nSortID)
    local szName = ""
    for index, tbInfo in ipairs(self.tbBusinessTypeInfo) do
        if tbInfo.nSortID == nSortID then
            szName = tbInfo.szName
            break
        end
    end
    return szName
end

-- 查找筛选 begin ----------------------------------------------
function UIPanelSearchItem:SetFliterTypeButtonState()
    UIHelper.RemoveAllChildren(self.WidgetFiltrateTip)


    if self:CanShowWeaponType() then
        UIHelper.SetVisible(self.BtnPVP, true)
    else
        UIHelper.SetVisible(self.BtnPVP, false)
    end

    UIHelper.LayoutDoLayout(self.LayoutBtn)
end

-- 更新装备类型旁的筛选图标
function UIPanelSearchItem:UpdateType()
    UIHelper.SetVisible(self.ImgTypeScreen, self.nShowType == -1)
    UIHelper.SetVisible(self.ImgTypeScreened, self.nShowType ~= -1)
end

-- 查找筛选 end ----------------------------------------------

function UIPanelSearchItem:SetLevelDesc(bDesc)
    self:SetSortType(SORT_TYPE.Official)
    self.bLevelDesc = bDesc
    self:UpdateInfo_Result()
    self:UpdateLevelSortDesc()
    self:UpdateSortUI()
end

function UIPanelSearchItem:CanShowWeaponType()
    local bShowFliterType = false
    local nSortID = self.nSortID
    if nSortID and nSortID >= 1 and nSortID <= 4 then
        bShowFliterType = true
    end
    return bShowFliterType
end

function UIPanelSearchItem:IsFliterType()
    return TradingData.IsFliterWeaponType(self.nSortID)
end


function UIPanelSearchItem:SetKungfuMask(nKungfuMask)
    self.nKungfuMask = nKungfuMask
end

function UIPanelSearchItem:GetKungfuMask(tbKungfu)
    local nKungfuMask = 0
    for nIndex, nKungfu in ipairs(tbKungfu) do
        nKungfuMask = nKungfuMask + 2^(nKungfu - 1)
    end
    return nKungfuMask
end

return UIPanelSearchItem
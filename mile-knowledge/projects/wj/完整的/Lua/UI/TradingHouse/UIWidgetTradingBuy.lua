-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetTradingBuy
-- Date: 2023-03-06 20:58:53
-- Desc: 交易行购买界面
-- ---------------------------------------------------------------------------------
local tbSpecialSortID = {
    1, 2, 3, 4
}

local SORT_TYPE = {
    Official = 0, --品级
    Price = 1,    --单价
}

local UIWidgetTradingBuy = class("UIWidgetTradingBuy")

function UIWidgetTradingBuy:OnEnter()
    if not self.bInit then
        self:InitData()
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIWidgetTradingBuy:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetTradingBuy:OnViewClose()

end

function UIWidgetTradingBuy:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnLeft, EventType.OnClick, function()
        local nCurPage = self.nCurPage - 1
        self:SetCurPage(nCurPage)
    end)

    UIHelper.BindUIEvent(self.BtnRight, EventType.OnClick, function()
        local nCurPage = self.nCurPage + 1
        self:SetCurPage(nCurPage)
    end)

    UIHelper.BindUIEvent(self.BtnSort, EventType.OnClick, function()
        local nDescendingOrder = (self.nDescendingOrder + 1) % 2
        self:SetDescendingOrder(nDescendingOrder)
    end)

    UIHelper.BindUIEvent(self.BtnSortLevel, EventType.OnClick, function()
        local bLevelDesc = not self.bLevelDesc
        self:SetLevelDesc(bLevelDesc)
    end)


    UIHelper.BindUIEvent(self.BtnScreen, EventType.OnClick, function()
        -- local bVisible = UIHelper.GetVisible(self.WidgetQualityFilter)
        -- UIHelper.SetVisible(self.WidgetQualityFilter, not bVisible)
        -- TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.BtnScreen, TipsLayoutDir.LEFT_CENTER, FilterDef.TradingBuyHouse)
        UIHelper.AddPrefab(PREFAB_ID.WidgetFiltrateTip, self.WidgetFiltrateTip, FilterDef.TradingBuyHouse)
    end)

    UIHelper.BindUIEvent(self.BtnRefresh, EventType.OnClick, function()
        TradingData.ApplyNormalLookUp(true, self.nCurPage, self.nSortID, self.nSubSortID, self.nShowQuality, nil, self.nDescendingOrder, self:GetKungfuMaskVal())
    end)


    if Platform.IsWindows() or Platform.IsMac() then
        UIHelper.RegisterEditBoxEnded(self.EditPaginate, function(_editbox)
            local nPage = UIHelper.GetText(_editbox)
            self:SetCurPage(nPage)
        end)
    else
        UIHelper.RegisterEditBoxReturn(self.EditPaginate, function(_editbox)
            local nPage = UIHelper.GetText(_editbox)
            self:SetCurPage(nPage)
        end)
    end

    UIHelper.BindUIEvent(self.BtnType, EventType.OnClick, function()
        local bVisible = UIHelper.GetVisible(self.WidgetTypeFilter)
        UIHelper.SetVisible(self.WidgetTypeFilter, not bVisible)
    end)

    UIHelper.BindUIEvent(self.BtnCloseTypeFliter, EventType.OnClick, function()
        UIHelper.SetVisible(self.WidgetTypeFilter, false)
    end)
end

function UIWidgetTradingBuy:RegEvent()
    Event.Reg(self, EventType.OnBusinessTypeInfoUpdate, function(tbBusinessTypeInfo)
        self.tbBusinessTypeInfo = tbBusinessTypeInfo
        self:UpdateBusinessTypeInfo()
    end)

    Event.Reg(self, EventType.ON_NORMAL_LOOK_UP_RES, function(nTotalCount, tbInfo)
        if not UIMgr.IsViewOpened(VIEW_ID.PanelSearchItem) then
            if nTotalCount ~= 0 then
                self:SetMaxPage(nTotalCount)
            end

            -- 当总页数小于当前页时，重置为第一页，且只做客户端刷新，不涉及服务器拉数据
            if self.nCurPage > nTotalCount then
                self:SetCurPage(1, true)
            end

            self:SetAllBusinessResultData(tbInfo)
        end
    end)

    Event.Reg(self, EventType.ON_AUCTION_BID_RESPOND, function()
        -- TradingData.ApplyNormalLookUp(false, self.nCurPage)--拉取新的能购买的物品数据会清掉之前的物品数据，所以购买成功后不拉取数据，防止购买物品界面缓存的物品数据失效，需要重新进入购买界面才能购买物品
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function()
        if self.scriptItemTip then
            UIHelper.RemoveAllChildren(self.WidgetItemTip1)
            self.scriptItemTip = nil
            self.nCurSelectIconView:RawSetSelected(false)
        end
        local bVisible = UIHelper.GetVisible(self.WidgetQualityFilter)
        UIHelper.SetVisible(self.WidgetQualityFilter, false)
        UIHelper.RemoveAllChildren(self.WidgetFiltrateTip)
    end)

    Event.Reg(self, EventType.ON_SHOW_TRADE_ITEM_CELL_TIP, function(nTabType, nTabID, scriptView, dwID)
        if nTabType and nTabID and UIHelper.GetVisible(self._rootNode) then
            if not self.scriptItemTip then
                self.scriptItemTip = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetItemTip1)
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

    Event.Reg(self, EventType.ON_AUCTION_SELL_SUCCESS, function()
        -- if not UIMgr.IsViewOpened(VIEW_ID.PanelEditItemPrice) then
            TradingData.ApplyNormalLookUp(false, self.nCurPage, self.nSortID, self.nSubSortID, self.nShowQuality, nil, self.nDescendingOrder, self:GetKungfuMaskVal())
        -- end
    end)

    Event.Reg(self, EventType.OnSearchItemClose, function()
        -- if not UIHelper.GetVisible(self.WidgetEmpty) then
            TradingData.ApplyNormalLookUp(false, self.nCurPage, self.nSortID, self.nSubSortID, self.nShowQuality, nil, self.nDescendingOrder, self:GetKungfuMaskVal())
        -- end
    end)

    Event.Reg(self, EventType.OnGameNumKeyboardOpen, function(editbox)
        if editbox ~= self.EditPaginate then return end
        UIHelper.SetEditBoxGameKeyboardRange(self.EditPaginate, 1, self.nMaxPage)
    end)

    Event.Reg(self, EventType.OnGameNumKeyboardChanged, function(editbox, num)
        if editbox ~= self.EditPaginate then return end
        local nPage = UIHelper.GetText(self.EditPaginate)
        self:SetCurPage(nPage)
    end)

    Event.Reg(self, EventType.OnFilter, function(szKey, tbInfo)
        if szKey ~= FilterDef.TradingBuyHouse.Key then
            return
        end

        local bSetWeaponType = false
        local bSetShowQuality = false
        local bSetKungfuMask = false

        if tbInfo[1] and tbInfo[1][1] then
            local nQuality = tbInfo[1][1] - 2
            if nQuality ~= self.nShowQuality then
                self:SetShowQuality(nQuality)
                bSetShowQuality = true
            end
        end

        if tbInfo[2] then
            bSetWeaponType = self:SetWeaponType(tbInfo[2][1] - 2)
        end

        if tbInfo[3] then
            local nKungfuMask = self:GetKungfuMask(tbInfo[3])
            if nKungfuMask ~= self.nKungfuMask then
                self:SetKungfuMask(nKungfuMask)
                bSetKungfuMask = true
            end
        end

        -- 门派/流派 如果有，就把这个转为心法
        if tbInfo[4] then
            local tbShoolType = {}
            for _, nIndex in ipairs(tbInfo[4]) do
                local nSchoolType = FilterDef.GetSchoolTypeByIndex(nIndex)
                table.insert(tbShoolType, nSchoolType)
            end

            local nSchoolMask = self:GetSchoolMask(tbShoolType)
            local nKungfuMask = 0

            if IsFunction(GetAuctionMountMaskByBitOpSchoolIDMask) then
                nKungfuMask = tonumber(GetAuctionMountMaskByBitOpSchoolIDMask(nSchoolMask))
            else
                --LOG.INFO("QH, C++ = %s", tostring(GetAuctionMountMaskByBitOpSchoolIDMask(nSchoolMask)))
                nKungfuMask = self:GetAuctionMountMaskByBitOpSchoolMask(nSchoolMask)
                --LOG.INFO("QH, LUA = %s", tostring(nKungfuMask))
            end

            if nKungfuMask ~= self.nKungfuMask then
                self:SetKungfuMask(nKungfuMask)
                bSetKungfuMask = true
            end
        end

        if not bSetKungfuMask then
            self:SetKungfuMask(0)
        end

        if not bSetShowQuality and not bSetKungfuMask then return end --既没设置品质也没设置心法时，不拉取数据
        TradingData.ApplyNormalLookUp(true, self.nCurPage, self.nSortID, self.nSubSortID, self.nShowQuality, nil, self.nDescendingOrder, self.nKungfuMask)
    end)
end

function UIWidgetTradingBuy:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end



function UIWidgetTradingBuy:InitData()
    FilterDef.TradingBuyHouse.Reset()
    self:SetLevelDesc(false)
    self:SetWeaponType(-1, true)
    self:SetShowQuality(-1)
    self:SetKungfuMask(0)
    self:SetMaxPage(1)
    self:SetCurPage(1, true)
    self:SetDescendingOrder(0)

    UIHelper.SetVisible(self.WidgetArrowLeft, true)
    UIHelper.AddPrefab(PREFAB_ID.WidgetArrow, self.WidgetArrowLeft)
    local scriptScrollViewTree = UIHelper.GetBindScript(self.WidgetAnchorLeft)
    scriptScrollViewTree:SetScrollViewMovedCallback(function(eventType)
        if eventType == ccui.ScrollviewEventType.scrollToBottom then
            UIHelper.SetVisible(self.WidgetArrowLeft, false)
        end
    end)
end


-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetTradingBuy:UpdateInfo()

end

function UIWidgetTradingBuy:UpdateBusinessTypeInfo()

    UIHelper.SetToggleGroupAllowedNoSelection(self.ToggleGroupSubNav, false)
    local function SelectContainer(scriptContainer, tbClassify)
        self.nSortID = tbClassify.nSortID
        self.nSubSortID = 0
        UIHelper.SetVisible(self.CurScriptContain.WidgettImgFoldTree, false)
        UIHelper.SetVisible(self.CurScriptContain.ImgNormalIconTree, self.tbCurClassify and #self.tbCurClassify.tbSub ~= 0)

        self.CurScriptContain = scriptContainer
        self.tbCurClassify = tbClassify
        self:OnSelectLeftNavSuccess(tbClassify)
    end

    local func = function(scriptContainer, tArgs)
        UIHelper.SetString(scriptContainer.LabelNormalAll01, tArgs.szName)
        UIHelper.SetString(scriptContainer.LabelUpAll01, tArgs.szName)
        UIHelper.SetVisible(scriptContainer.WidgetSelecctImgTree, tArgs.nChildCount ~= 0)
        UIHelper.SetVisible(scriptContainer.ImgNormalIconTree, tArgs.nChildCount ~= 0)
        UIHelper.SetVisible(scriptContainer.WidgetSelecctImg, tArgs.nChildCount == 0)
        UIHelper.SetVisible(scriptContainer.ImgNormalIcon, tArgs.nChildCount == 0)
    end

    local tbData = {}
    for index, tbClassify in ipairs(self.tbBusinessTypeInfo) do
        local Info = {}
        Info.tArgs = { szName = tbClassify.szName, nChildCount = #tbClassify.tbSub }
        if #tbClassify.tbSub > 0 then
            Info.tItemList = {}
        end
        for Index, tbData in ipairs(tbClassify.tbSub) do
            table.insert(Info.tItemList, {tArgs = {szName = tbData.szSubName, toggleGroup = self.ToggleGroupSubNav, bLast = Index == #tbClassify.tbSub, funcCallBack = function(scriptSubNav, scriptContain, bSelect)
                if bSelect then
                    self.nSortID = tbClassify.nSortID
                    self.nSubSortID = tbData.nSubSortID
                    self:OnSelectSubNavSuccess(tbData, scriptContain)
                end
            end}})
        end

        Info.fnOnCickCallBack = function(bSelect, scriptContainer)
            if bSelect then
                SelectContainer(scriptContainer, tbClassify)
            else
                self:OnCanCelLeftNavSuccess(tbClassify)
            end
        end
        table.insert(tbData, Info)
    end

    local scriptScrollViewTree = UIHelper.GetBindScript(self.WidgetAnchorLeft)
    UIHelper.SetupScrollViewTree(scriptScrollViewTree, PREFAB_ID.WidgetLeftNavTabList, PREFAB_ID.WidgetSubNav, func, tbData)

    local scriptContainer = scriptScrollViewTree.tContainerList[1].scriptContainer
    Timer.AddFrame(self, 1, function()
        self.CurScriptContain = scriptContainer--因为注册的是Onclick事件,SetSelected并不会触发fnOnCickCallBack执行SelectContainer维持当前选中的Container，所以手动赋值
        self:OnSelectLeftNavSuccess(self.tbBusinessTypeInfo[1])
        self:SetScriptContainer()
    end)
end

function UIWidgetTradingBuy:SetScriptContainer()
    local scriptScrollViewTree = UIHelper.GetBindScript(self.WidgetAnchorLeft)
    for index, tbInfo in ipairs(scriptScrollViewTree.tContainerList) do
        local tbItemScript = tbInfo.scriptContainer:GetItemScript()
        for index, scriptSubNav in ipairs(tbItemScript) do
            scriptSubNav:SetScriptContainer(tbInfo.scriptContainer)
        end
    end
end

function UIWidgetTradingBuy:OnSelectLeftNavSuccess(tbClassify)
    local scriptScrollViewTree = UIHelper.GetBindScript(self.WidgetAnchorLeft)
    local bShow = #tbClassify.tbSub == 0
    UIHelper.SetVisible(scriptScrollViewTree.scriptTopContainer.WidgettImgFoldTree, bShow)
    UIHelper.SetVisible(self.CurScriptContain.WidgettImgFoldTree, bShow)
    UIHelper.SetVisible(self.BtnSortLevel, TradingData.IsFliterWeaponType(self.nSortID))
    UIHelper.LayoutDoLayout(self.LayoutBtn)


    local tbItemScript = self.CurScriptContain:GetItemScript()
    if #tbItemScript ~= 0 then
        tbItemScript[1]:SetSelected(true)
        self:UpdateTargetTitle(tbItemScript[1]:GetName())
    else
        self:UpdateTargetTitle(tbClassify.szName)
    end

    self:OpenRefreshTip()
    self:SetCurPage(1, true)
end

function UIWidgetTradingBuy:OnCanCelLeftNavSuccess(tbClassify)
    local scriptScrollViewTree = UIHelper.GetBindScript(self.WidgetAnchorLeft)
    local bShow = #tbClassify.tbSub ~= 0
    UIHelper.SetVisible(scriptScrollViewTree.scriptTopContainer.WidgettImgFoldTree, bShow)
    UIHelper.SetVisible(scriptScrollViewTree.scriptTopContainer.ImgNormalIconTree, not bShow)
    UIHelper.SetVisible(self.CurScriptContain.WidgettImgFoldTree, bShow)
    UIHelper.SetVisible(self.CurScriptContain.ImgNormalIconTree, not bShow)
end

function UIWidgetTradingBuy:OnSelectSubNavSuccess(tbData, scriptContainer)
    self:OpenRefreshTip()
    self:UpdateTargetTitle(tbData.szSubName)
    self:SetCurPage(1, true)
end

function UIWidgetTradingBuy:OpenRefreshTip()
    UIHelper.SetVisible(self.WidgetEmpty, true)
    UIHelper.SetString(self.LabelEmptyDescibe, "点击刷新后查看符合条件的物品")
    UIHelper.SetVisible(self.ScrolItem, false)
    UIHelper.SetVisible(self.WidgetPaginate, false)
    UIHelper.SetVisible(self.WidgetArrow, false)
end


function UIWidgetTradingBuy:UpdateBusinessResultData()
    local tbCurBusinessResultData = self.tbCurBusinessResultData
    UIHelper.SetVisible(self.WidgetEmpty, tbCurBusinessResultData == nil or #tbCurBusinessResultData == 0)
    UIHelper.SetString(self.LabelEmptyDescibe, "暂无内容")
    UIHelper.SetVisible(self.WidgetPaginate, tbCurBusinessResultData and #tbCurBusinessResultData ~= 0)
    UIHelper.SetVisible(self.ScrolItem, tbCurBusinessResultData and #tbCurBusinessResultData > 0)
    UIHelper.SetVisible(self.WidgetArrow, true)
    UIHelper.RemoveAllChildren(self.ScrolItem)

    if not tbCurBusinessResultData then return end
    --品级排序
    table.sort(tbCurBusinessResultData, function(l, r)
        if not l or not r then return false end
        if self.nSortType == SORT_TYPE.Official then
            if not l.Item or not r.Item then return false end
            local nLeftLevel = l.Item.nLevel
            local nRightLevel = r.Item.nLevel
            if nLeftLevel ~= nRightLevel then
                if self.bLevelDesc then
                    return nLeftLevel > nRightLevel
                else
                    return nLeftLevel < nRightLevel
                end
            end
        else
            local nLeftMoney = UIHelper.GoldSilverAndCopperToMoney(l.Price.nGold, l.Price.nSilver, l.Price.nCopper)
            local nRightMoney = UIHelper.GoldSilverAndCopperToMoney(r.Price.nGold, r.Price.nSilver, r.Price.nCopper)
            if self.nDescendingOrder == 0 then
                return nLeftMoney < nRightMoney
            else
                return nLeftMoney > nRightMoney
            end
        end
    end)

    local tbInfo = {}
    for index, tbData in ipairs(tbCurBusinessResultData) do
        tbData.bSell = false
        table.insert(tbInfo, tbData)
        if (index % 2 == 0) or (index % 2 ~= 0 and index == #tbCurBusinessResultData) then
            UIHelper.AddPrefab(PREFAB_ID.WidgetTradeItemClass, self.ScrolItem, tbInfo, self.ToggleGroupBuy)
            tbInfo = {}
        end
    end
    UIHelper.ScrollViewDoLayout(self.ScrolItem)
    UIHelper.ScrollToTop(self.ScrolItem)
    UIHelper.ScrollViewSetupArrow(self.ScrolItem, self.WidgetArrow)
    UIHelper.SetSwallowTouches(self.ScrolItem, true)
end




function UIWidgetTradingBuy:UpdateCurPage()
    UIHelper.SetText(self.EditPaginate, self.nCurPage)
end

function UIWidgetTradingBuy:UpdateBtnPage()
    local nLeftState = self.nCurPage == 1 and BTN_STATE.Disable or BTN_STATE.Normal
    local nRightState = self.nCurPage == self.nMaxPage and BTN_STATE.Disable or BTN_STATE.Normal
    UIHelper.SetButtonState(self.BtnLeft, nLeftState)
    UIHelper.SetButtonState(self.BtnRight, nRightState)
end

function UIWidgetTradingBuy:UpdateTargetTitle(szTitle)
    UIHelper.SetString(self.LabelTargetTitle, szTitle)
end

function UIWidgetTradingBuy:UpdateSortDesc()
    UIHelper.SetString(self.LabelEmptyDescibe_copy, "单价")
    -- UIHelper.SetScaleY(self.ImgSort, self.nDescendingOrder and 1 or -1)

    UIHelper.SetOpacity(self.ImgUp, self.nDescendingOrder == 0 and self.nSortType == SORT_TYPE.Price and 255 or 70)
    UIHelper.SetOpacity(self.ImgDown, self.nDescendingOrder == 1 and self.nSortType == SORT_TYPE.Price and 255 or 70)
end

function UIWidgetTradingBuy:UpdateLevelSortDesc()
    UIHelper.SetOpacity(self.ImgUpLevel, self.bLevelDesc == false and self.nSortType == SORT_TYPE.Official and 255 or 70)
    UIHelper.SetOpacity(self.ImgDownLevel, self.bLevelDesc == true and self.nSortType == SORT_TYPE.Official and 255 or 70)
end

function UIWidgetTradingBuy:UpdateQuality()
    UIHelper.SetVisible(self.ImgScreen, self.nShowQuality == -1)
    UIHelper.SetVisible(self.ImgScreened, self.nShowQuality ~= -1)
end

function UIWidgetTradingBuy:SetCurPage(nCurPage, bNotApply)
    if self.nCurPage == nCurPage then return end
    nCurPage = nCurPage ~= "" and nCurPage or 1
    nCurPage = math.max(nCurPage, 1)
    nCurPage = math.min(nCurPage, self.nMaxPage)

    if not bNotApply and TradingData.ApplyNormalLookUp(true, nCurPage, self.nSortID, self.nSubSortID, self.nShowQuality, nil, self.nDescendingOrder, self:GetKungfuMaskVal()) then
        self.nCurPage = nCurPage
        self:UpdateCurPage()
    elseif bNotApply then --不拉取数据，只更新页面信息
        self.nCurPage = nCurPage
        self:UpdateCurPage()
    end
    self:UpdateBtnPage()
end

function UIWidgetTradingBuy:SetSortType(nSortType)
    self.nSortType = nSortType
end

function UIWidgetTradingBuy:SetMaxPage(nMaxPage)
    self.nMaxPage = nMaxPage
    UIHelper.SetString(self.LabelPaginate, "/" .. self.nMaxPage)
    self:UpdateBtnPage()
end

--是否为降序
function UIWidgetTradingBuy:SetDescendingOrder(nDescendingOrder)
    self:SetSortType(SORT_TYPE.Price)
    self.nDescendingOrder = nDescendingOrder

    if TradingData.ApplyNormalLookUp(true, self.nCurPage, self.nSortID, self.nSubSortID, self.nShowQuality, nil, self.nDescendingOrder, self:GetKungfuMaskVal()) then
        self:UpdateSortDesc()
    else
        self.nDescendingOrder = (self.nDescendingOrder + 1) % 2
    end
    self:UpdateLevelSortDesc()
end

function UIWidgetTradingBuy:SetBusinessResultData()
    if not self.tbBusinessResultData then return end
    if self:IsFliterWeaponType() then
        self.tbCurBusinessResultData = TradingData.GetBusinessResultData(self.tbBusinessResultData, self.nShowType)
    else
        self.tbCurBusinessResultData = TradingData.GetBusinessResultData(self.tbBusinessResultData)
    end
    self:UpdateBusinessResultData()
end

function UIWidgetTradingBuy:SetAllBusinessResultData(tbBusinessResultData)
    self.tbBusinessResultData = tbBusinessResultData
    self:SetBusinessResultData()
end


function UIWidgetTradingBuy:SetShowQuality(nQuality)
    self.nShowQuality = nQuality
end

function UIWidgetTradingBuy:SetKungfuMask(nKungfuMask)
    self.nKungfuMask = nKungfuMask
end

function UIWidgetTradingBuy:GetKungfuMaskVal()
    return self:IsFliterSchoolType() and self.nKungfuMask or 0
end

function UIWidgetTradingBuy:GetKungfuMask(tbKungfu)
    local nKungfuMask = 0
    for nIndex, nKungfu in ipairs(tbKungfu) do
        nKungfuMask = nKungfuMask + 2 ^ (nKungfu - 1)
    end
    return nKungfuMask
end

function UIWidgetTradingBuy:GetSchoolMask(tbShool)
    local nSchoolMask = 0
    for nIndex, nSchool in ipairs(tbShool) do
        nSchoolMask = nSchoolMask + 2 ^ nSchool
    end
    return nSchoolMask
end

-- 交易行筛选 begin ----------------------------------------------
function UIWidgetTradingBuy:SetWeaponType(nShowType, bForbidUpdateUI)
    if self.nShowType == nShowType then return false end
    self.nShowType = nShowType
    if bForbidUpdateUI then return true end
    self:SetBusinessResultData()
    return true
end

function UIWidgetTradingBuy:IsFliterWeaponType()
    return TradingData.IsFliterWeaponType(self.nSortID)
end

function UIWidgetTradingBuy:IsFliterSchoolType()
    return TradingData.IsFliterSchoolType(self.nSortID, self.nSubSortID)
end

-- 交易行筛选 end ----------------------------------------------

function UIWidgetTradingBuy:SetLevelDesc(bDesc)
    self:SetSortType(SORT_TYPE.Official)
    self.bLevelDesc = bDesc
    self:UpdateBusinessResultData()
    self:UpdateLevelSortDesc()
    self:UpdateSortDesc()
end

function UIWidgetTradingBuy:GetAuctionMountMaskByBitOpSchoolMask(ullSchoolMask)
    local tbBitOpSchoolIDMountMaskMap =
    {
        [SCHOOL_TYPE.TIAN_CE]            = 48,
        [SCHOOL_TYPE.CHUN_YANG]          = 192,
        [SCHOOL_TYPE.SHAO_LIN]           = 3,
        [SCHOOL_TYPE.WAN_HUA]            = 12,
        [SCHOOL_TYPE.QI_XIU]             = 768,
        [SCHOOL_TYPE.CANG_JIAN_WEN_SHUI] = 49152,
        [SCHOOL_TYPE.WU_DU]              = 3072,
        [SCHOOL_TYPE.TANG_MEN]           = 12288,
        [SCHOOL_TYPE.MING_JIAO]          = 393216,
        [SCHOOL_TYPE.GAI_BANG]           = 65536,
        [SCHOOL_TYPE.CANG_YUN]           = 1572864,
        [SCHOOL_TYPE.CHANG_GE]           = 6291456,
        [SCHOOL_TYPE.BA_DAO]             = 8388608,
        [SCHOOL_TYPE.PENG_LAI]           = 16777216,
        [SCHOOL_TYPE.LING_XUE]           = 33554432,
        [SCHOOL_TYPE.YAN_TIAN]           = 67108864,
        [SCHOOL_TYPE.YAO_ZONG]           = 402653184,
        [SCHOOL_TYPE.DAO_ZONG]           = 536870912,
        [SCHOOL_TYPE.WAN_LING]           = 1073741824,
        [SCHOOL_TYPE.DUAN_SHI]           = 2147483648,
        [SCHOOL_TYPE.WU_XIANG]           = 4294967296,
    }

    local ullResult = 0
    for schoolID, mountMask in pairs(tbBitOpSchoolIDMountMaskMap) do
        if GetNumberBit(ullSchoolMask, schoolID + 1) then
            ullResult = bit.bit_or_64(ullResult, mountMask) --BitwiseOr(ullResult, mountMask)
        end
    end
    return ullResult
end

return UIWidgetTradingBuy

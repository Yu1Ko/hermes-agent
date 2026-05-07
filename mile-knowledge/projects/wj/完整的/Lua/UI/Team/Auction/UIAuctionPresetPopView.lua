-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIAuctionPresetPopView
-- Date: 2023-02-14 20:15:33
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIAuctionPresetPopView = class("UIAuctionPresetPopView")

function UIAuctionPresetPopView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:Init()
    self:UpdateInfo()
    self:OnSelectPresetChanged(self.nPricePresetID)
    Timer.AddFrame(self, 1, function ()
        UIHelper.ScrollToIndex(self.ScrollViewTog, self.nPricePresetID - 1, 0)
    end)
end

function UIAuctionPresetPopView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Storage.Auction.Flush()
end

function UIAuctionPresetPopView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnAdd, EventType.OnClick, function ()
        self:OnClickAddPresetButton()
    end)

    UIHelper.BindUIEvent(self.BtnDelete, EventType.OnClick, function ()
        self:OnClickDeletePresetButton()
    end)

    UIHelper.BindUIEvent(self.BtnEdit, EventType.OnClick, function ()
        self:OnEditStateChanged(true)
        self:RefreshPresetDetail()
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function ()
        self:OnClickCancelPresetButton()
    end)

    UIHelper.BindUIEvent(self.BtnSave, EventType.OnClick, function ()
        self:OnClickSavePresetButton()
    end)

    UIHelper.BindUIEvent(self.BtnApply, EventType.OnClick, function ()
        self:OnClickApplyPresetButton()
    end)

    UIHelper.RegisterEditBox(self.EditBoxTagName, function ()
        self:OnPresetNameChanged()
    end)
end

function UIAuctionPresetPopView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIAuctionPresetPopView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIAuctionPresetPopView:Init()
    if not Storage.Auction.bPricePresetInit then
        Storage.Auction.bPricePresetInit = true
        Storage.Auction.tPricePreset[1] = {szType = "官方"}
        for i = 2, 4 do
            Storage.Auction.tPricePreset[i] = self:CreateNewPreset("预设"..g_tStrings.STR_NUMBER[i-1])
        end
    end
    self.nPricePresetID = Storage.Auction.nPricePresetID or 1
end

function UIAuctionPresetPopView:CreateNewPreset(szType)
    local tPreset = {
        szType = szType or "新预设",
        {szName = "普通武器", nStartPrice = 0, nStepPrice = 100},
        {szName = "小铁", nStartPrice = 0, nStepPrice = 100},
        {szName = "小附魔", nStartPrice = 0, nStepPrice = 100},
        {szName = "藏剑武器盒", nStartPrice = 0, nStepPrice = 100},
        {szName = "精简", nStartPrice = 0, nStepPrice = 100},
        {szName = "散件", nStartPrice = 0, nStepPrice = 100},
        {szName = "普通武器盒", nStartPrice = 0, nStepPrice = 100},
        {szName = "牌子", nStartPrice = 0, nStepPrice = 100},
        {szName = "大附魔", nStartPrice = 0, nStepPrice = 100},
        {szName = "水特效武器", nStartPrice = 0, nStepPrice = 100},
		{szName = "百战秘籍", nStartPrice = 0, nStepPrice = 100},
    }
    return tPreset
end

function UIAuctionPresetPopView:UpdateInfo()
    -- 初始化预设列表
    UIHelper.RemoveAllChildren(self.ScrollViewTog)
    self.tScriptTabList = {}
    for nIndex = 1, AuctionData.MAX_PRESET_COUNT do
        local scriptCell = UIHelper.AddPrefab(PREFAB_ID.WidgetAuctionPresetTogCell, self.ScrollViewTog)
        self.tScriptTabList[nIndex] = scriptCell
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewTog)
    -- 初始化预设详情
    local tPreset = self:CreateNewPreset()
    UIHelper.SetString(self.LabelTagName, tPreset.szType)
    UIHelper.RemoveAllChildren(self.ScrollViewTypeList)
    self.tScriptCellList = {}
    for nIndex, tCellInfo in ipairs(tPreset) do
        local scriptCell = UIHelper.AddPrefab(PREFAB_ID.WidgetAuctionPresetTypeCell, self.ScrollViewTypeList, tCellInfo)
        self.tScriptCellList[nIndex] = scriptCell
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewTypeList)

    self:RefreshPresetList(true)
end

function UIAuctionPresetPopView:RefreshPresetList(bNeedRebound)
    if Storage.Auction.nPricePresetID > #Storage.Auction.tPricePreset then 
        Storage.Auction.nPricePresetID = #Storage.Auction.tPricePreset
    end

    UIHelper.HideAllChildren(self.ScrollViewTog)
    for nIndex, tPreset in ipairs(Storage.Auction.tPricePreset) do
        local scriptTab = self.tScriptTabList[nIndex]
        scriptTab:OnEnter(tPreset.szType, nIndex, function ()
            self:OnSelectPresetChanged(nIndex)
        end)
        UIHelper.SetVisible(scriptTab._rootNode, true)
    end
    UIHelper.ScrollViewDoLayout(self.ScrollViewTog)
    if bNeedRebound then UIHelper.ScrollToTop(self.ScrollViewTog, 0) end

    local szTitle = string.format("拍卖标签预设(%d/%d)", #Storage.Auction.tPricePreset, AuctionData.MAX_PRESET_COUNT)
    UIHelper.SetString(self.LabelTitle, szTitle)

    self:RefreshButtons()
end

function UIAuctionPresetPopView:RefreshPresetDetail()
    local tPreset = Storage.Auction.tPricePreset[self.nPricePresetID]
    local bEmpty = tPreset == nil
    if not bEmpty then
        UIHelper.SetString(self.LabelTagName, tPreset.szType)
        UIHelper.SetText(self.EditBoxTagName, tPreset.szType)
        for nIndex, tCellInfo in ipairs(tPreset) do
            local scriptCell = self.tScriptCellList[nIndex]
            scriptCell:OnEnter(tCellInfo)
        end
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewTypeList)
    end

    local bDefaultPreset = self.nPricePresetID == 1
    UIHelper.SetVisible(self.WidgetEmpty, bDefaultPreset)
    UIHelper.SetVisible(self.WidgetTitle, not bDefaultPreset)
    UIHelper.SetVisible(self.ScrollViewTypeList, not bDefaultPreset)

    self:RefreshButtons()
end

function UIAuctionPresetPopView:OnSelectPresetChanged(nPricePresetID)
    self.nPricePresetID = nPricePresetID
    for nIndex, scriptTab in ipairs(self.tScriptTabList) do
        UIHelper.SetSelected(scriptTab.ToggleSelect, nIndex == self.nPricePresetID, false)
    end

    self:RefreshPresetDetail()
end

function UIAuctionPresetPopView:OnClickAddPresetButton()
    if #Storage.Auction.tPricePreset >= AuctionData.MAX_PRESET_COUNT then return end

    table.insert(Storage.Auction.tPricePreset, self:CreateNewPreset())
    self:RefreshPresetList(true)
    self:OnSelectPresetChanged(#Storage.Auction.tPricePreset)
end

function UIAuctionPresetPopView:OnClickDeletePresetButton()
    if self.nPricePresetID == 1 then return end
    local tPreset = Storage.Auction.tPricePreset[self.nPricePresetID]
    if not tPreset then return end

    table.remove(Storage.Auction.tPricePreset, self.nPricePresetID)
    if self.nPricePresetID > #Storage.Auction.tPricePreset then self.nPricePresetID = #Storage.Auction.tPricePreset end

    self:RefreshPresetList(true)
    self:OnSelectPresetChanged(self.nPricePresetID)
end

function UIAuctionPresetPopView:OnClickCancelPresetButton()
    self:OnEditStateChanged(false)
    self:RefreshPresetDetail()
end

function UIAuctionPresetPopView:OnClickSavePresetButton()
    self:OnEditStateChanged(false)

    local tPreset = Storage.Auction.tPricePreset[self.nPricePresetID]
    local bEmpty = tPreset == nil
    if not bEmpty then
        local szType = UIHelper.GetText(self.EditBoxTagName)
        if szType == "" then szType = nil end

        tPreset.szType = szType or tPreset.szType
        for nIndex, _ in ipairs(tPreset) do
            local scriptCell = self.tScriptCellList[nIndex]
            tPreset[nIndex].nStartPrice, tPreset[nIndex].nStepPrice = scriptCell:GetPrice()
        end
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewTypeList)
        Storage.Auction.tPricePreset[self.nPricePresetID] = tPreset
        Storage.Auction.Flush()
    end

    self:RefreshPresetList()
    self:RefreshPresetDetail()
end

function UIAuctionPresetPopView:OnClickApplyPresetButton()
    if not Storage.Auction.tPricePreset[self.nPricePresetID] then return end

    Storage.Auction.nPricePresetID = self.nPricePresetID
    self:RefreshPresetList()
end

function UIAuctionPresetPopView:OnEditStateChanged(bEdit)
    self.bEdit = bEdit
    UIHelper.SetVisible(self.LayoutBtnsEdit, self.bEdit)
    UIHelper.SetVisible(self.LayoutBtnsNormal, not self.bEdit)
    UIHelper.SetVisible(self.EditTagName, self.bEdit)
    UIHelper.SetVisible(self.WidgetName, not self.bEdit)

    for _, scriptCell in ipairs(self.tScriptCellList) do
        scriptCell:SetEditState(self.bEdit)
    end

    for nIndex, scriptTab in ipairs(self.tScriptTabList) do
        UIHelper.SetTouchEnabled(scriptTab.ToggleSelect, not bEdit)
        UIHelper.SetNodeGray(scriptTab.ToggleSelect, bEdit, true)
        UIHelper.SetSwallowTouches(scriptTab.ToggleSelect, false)
    end

    self:RefreshButtons()
end

function UIAuctionPresetPopView:OnPresetNameChanged()
    local szType = UIHelper.GetText(self.EditBoxTagName)
    local nStrCount = GetStringCharCount(szType)
    UIHelper.SetString(self.LabelTagNameLimit, string.format("%d/3", nStrCount))
end

function UIAuctionPresetPopView:RefreshButtons()
    local bDefaultPreset = self.nPricePresetID == 1
    UIHelper.SetVisible(self.BtnAdd, not self.bEdit)
    UIHelper.SetVisible(self.BtnDelete, not self.bEdit and not bDefaultPreset)
    UIHelper.SetVisible(self.BtnEdit, not bDefaultPreset)

    if #Storage.Auction.tPricePreset < AuctionData.MAX_PRESET_COUNT then
        UIHelper.SetButtonState(self.BtnAdd, BTN_STATE.Normal)
    else
        UIHelper.SetButtonState(self.BtnAdd, BTN_STATE.Disable, "预设数量已达上限")
    end

    if Storage.Auction.nPricePresetID ~= self.nPricePresetID then
        UIHelper.SetString(self.LabelApply, "应用")
        UIHelper.SetButtonState(self.BtnApply, BTN_STATE.Normal)
    else
        UIHelper.SetString(self.LabelApply, "已应用")
        UIHelper.SetButtonState(self.BtnApply, BTN_STATE.Disable, "该预设正在使用中")
    end

    UIHelper.LayoutDoLayout(self.LayoutBtnsNormal)
end

return UIAuctionPresetPopView
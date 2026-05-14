-- ---------------------------------------------------------------------------------
-- 自选宝箱页面
-- PanelOptionalTreasureBox
-- ---------------------------------------------------------------------------------

local UIPanelOptionalTreasureBox = class("UIPanelOptionalTreasureBox")
local OptionalState = {
    ALL = 1,
    HAVE = 2,
    NOT = 3
}

function UIPanelOptionalTreasureBox:_LuaBindList()
    self.ScrollLeft              = self.ScrollLeft --- 加载WidgetTreasureBox的scroll 左侧
    self.WidgetArrow             = self.WidgetArrow
    self.WidgetAnchorLeft        = self.WidgetAnchorLeft --- ScrollLeft 和 WidgetArrow 的上层

    self.ScrollViewRewardList    = self.ScrollViewRewardList --- 加载 WidgetTreasureBoxRewardCell
    self.BtnConfirm              = self.BtnConfirm --- 开启btn
    self.LabelConfirm            = self.LabelConfirm --- 开启btn label
    self.LabelCost               = self.LabelCost --- 花费
    self.ImgItem                 = self.ImgItem --- 花费图标
    self.BtnDes2                 = self.BtnDes2 --- 花费btn

    self.TogSift                 = self.TogSift --- 筛选 已拥有 未拥有 全部

    self.LabelTitle              = self.LabelTitle --- 页面标题
    self.BtnClose                = self.BtnClose

    self.WidgetAnchorRight       = self.WidgetAnchorRight --- 加载详情tip
end

function UIPanelOptionalTreasureBox:OnEnter(dwChoiceBoxID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.dwChoiceBoxID = dwChoiceBoxID
    self.tBtn = {}
    self:UpdateInfo()
end

function UIPanelOptionalTreasureBox:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelOptionalTreasureBox:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.TogSift, EventType.OnClick, function()
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.TogSift, TipsLayoutDir.BOTTOM_CENTER, FilterDef.OptionalBox)
    end)

    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function()
        if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.EQUIP, "useitem") then
            return
        end
        RemoteCallToServer("On_BoxOpenUI_QYOpen", self.dwBoxID, self.tBtn.dwItemIndex, self.nOptionalType,
            self.tBtn.nItemSequence, self.tBtn.nLuckyID or 0, self.tBtn.nRewardType or 0, self.tBtn.nRewardIndex or 0)

        UIMgr.Close(self)
    end)
end

function UIPanelOptionalTreasureBox:RegEvent()
    Event.Reg(self, EventType.OnFilter, function(szKey, tbInfo)
        if szKey ~= FilterDef.OptionalBox.Key then
            return
        end
        self.nOptionalState = tbInfo[1][1]
        self:ShowAwardView()
    end)

    Event.Reg(self, EventType.OnWindowsSizeChanged, function()
        UIHelper.ScrollViewDoLayout(self.ScrollViewRewardList)
        UIHelper.ScrollViewDoLayout(self.ScrollLeft)
    end)
end

function UIPanelOptionalTreasureBox:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelOptionalTreasureBox:UpdateInfo()
    UIHelper.RemoveAllChildren(self.ScrollLeft)

    TreasureBoxData.InitOptionalBox()
    local tRowOptioanlList = TreasureBoxData.GetOptionalBox()
    local tOptioanlList = {}
    local nSelectBoxItemType, nSelectBoxItemIndex = nil, nil
    if self.dwChoiceBoxID then
        local tInfo = Tabel_GetTreasureBoxListByID(self.dwChoiceBoxID)
        nSelectBoxItemType, nSelectBoxItemIndex = TreasureBoxData.SplitItemID(tInfo.szOtherCheck)

        local iteminfo = ItemData.GetItemInfo(nSelectBoxItemType, nSelectBoxItemIndex)
        local nBagNum = iteminfo and select(2, ItemData.GetItemAllStackNum(iteminfo, false)) or nil
        if not nBagNum or nBagNum <= 0 then
            nSelectBoxItemType, nSelectBoxItemIndex = nil, nil
        end
    end

    for _, tInfo in ipairs(tRowOptioanlList) do
        local bShow = false
        if self.dwChoiceBoxID and tInfo.dwID == self.dwChoiceBoxID then
            bShow = true
        elseif tInfo.bOwnToShow == true and tInfo.dwID ~= self.dwChoiceBoxID then
            local dwType, dwIndex = TreasureBoxData.SplitItemID(tInfo.szBoxItem)
            local BoxItem = ItemData.GetItemInfo(dwType, dwIndex)

            local _, nBagNum, _, _ = ItemData.GetItemAllStackNum(BoxItem, false)
            if nBagNum and nBagNum > 0 then
                bShow = true
            end
        else
            bShow = true
        end

        if not bShow and nSelectBoxItemType and nSelectBoxItemIndex then
            local nItemType, nItemIndex = TreasureBoxData.SplitItemID(tInfo.szOtherCheck)
            if nItemType == nSelectBoxItemType and nItemIndex == nSelectBoxItemIndex then
                bShow = true
            end
        end

        if bShow then
            table.insert(tOptioanlList, tInfo)
        end
    end

    self.tOptioanlCell = {}
    local szFirstShowBoxName
    for _, tInfo in ipairs(tOptioanlList) do
        local szBoxName = UIHelper.GBKToUTF8(tInfo.szItemName)
        local scriptCell = UIHelper.AddPrefab(PREFAB_ID.WidgetTreasureBox, self.ScrollLeft) assert(scriptCell)
        scriptCell:UpdateInfo(tInfo)
        scriptCell:SetCallBack(function()
            self.dwBoxID = tInfo.dwID
            self.tBtn.nType, self.tBtn.dwItemIndex = TreasureBoxData.SplitItemID(tInfo.szBoxItem)
            self:UpdateAward(szBoxName)
        end)
        if self.dwChoiceBoxID and self.dwChoiceBoxID == tInfo.dwID then
            self.dwBoxID = self.dwChoiceBoxID
            self.dwChoiceBoxID = nil
            self.tBtn.nType, self.tBtn.dwItemIndex = TreasureBoxData.SplitItemID(tInfo.szBoxItem)
            UIHelper.SetSelected(scriptCell.ToggleTreasureSeries, true, false)
            szFirstShowBoxName = szBoxName
        else
            UIHelper.SetSelected(scriptCell.ToggleTreasureSeries, false, false)
        end
        table.insert(self.tOptioanlCell, scriptCell)
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollLeft)

    if not szFirstShowBoxName then
        self.dwBoxID = tOptioanlList and tOptioanlList[1] and tOptioanlList[1].dwID
        szFirstShowBoxName = tOptioanlList and tOptioanlList[1] and tOptioanlList[1].szItemName
        UIHelper.SetSelected(self.tOptioanlCell[1].ToggleTreasureSeries, true, false)
    end

    self:UpdateAward(szFirstShowBoxName)
end

function UIPanelOptionalTreasureBox:UpdateAward(szBoxName)
    self.szBoxName = szBoxName
    self:RevertFliter()

    self:InitAwardData()
    self:ShowTypeView()
    self:ShowAwardView()
    self:UpdateBtnState()
end

function UIPanelOptionalTreasureBox:RevertFliter()
    FilterDef.OptionalBox.Reset()
    self.nOptionalState = OptionalState.ALL
end

function UIPanelOptionalTreasureBox:UpdateBtnState()
    local tInfo = Tabel_GetTreasureBoxListByID(self.dwBoxID)
    local nType, dwItemIndex = TreasureBoxData.SplitItemID(tInfo.szBoxItem)
    local bSelectedAward = false
    if self.tBtn and self.tBtn.nRewardType and self.tBtn.nRewardIndex then
        bSelectedAward = true
    end

    local BoxItem = ItemData.GetItemInfo(nType, dwItemIndex)
    local _, nBagNum, _, _ = ItemData.GetItemAllStackNum(BoxItem, false)

    if nBagNum == 0 or not bSelectedAward then
        UIHelper.SetButtonState(self.BtnConfirm, BTN_STATE.Disable)
    else
        UIHelper.SetButtonState(self.BtnConfirm, BTN_STATE.Normal)
    end
end

function UIPanelOptionalTreasureBox:InitAwardData()
    local szBoxName = self.szBoxName
    if not szBoxName then
        return
    end

    TreasureBoxData.InitAward()
    self.tAward, self.tszType = TreasureBoxData.GetOptionalAwardList(self.dwBoxID)

    for _, ttInfo in ipairs (self.tAward) do
        for indexID , tInfo in ipairs(ttInfo) do
            -- 更新已拥有状态
            tInfo.bHave = TreasureBoxData.CheckCollected(tInfo)
        end
    end
end

function UIPanelOptionalTreasureBox:ShowTypeView()
    self.nOptionalType = 1
    local nParentY = UIHelper.GetHeight(self.ScrollviewType)
    UIHelper.RemoveAllChildren(self.ScrollviewType)
    for index, szName in ipairs(self.tszType) do
        local nCollect = 0
        local nTotal = 0
        local tbAward = self.tAward[index]
        for _, tbItem in ipairs (tbAward) do
            if tbItem.bHave then
                nCollect = nCollect + 1
            end

            if not tbItem.bNotCollect then
                nTotal = nTotal + 1
            end
        end

        local szProcess = nTotal > 0 and ("("..nCollect.."/"..nTotal..")") or ""
        local szTitle = szName..szProcess
        local scriptTypeCell = UIHelper.AddPrefab(PREFAB_ID.WidgetTogRewardType, self.ScrollviewType) assert(scriptTypeCell)
        scriptTypeCell:UpdateInfo(szTitle)
        scriptTypeCell:ShowColltImg(nCollect > 0 and nCollect == nTotal)
        UIHelper.SetAnchorPoint(scriptTypeCell._rootNode, 0, 0)
        UIHelper.SetHeight(scriptTypeCell._rootNode, nParentY)
        UIHelper.CascadeDoLayoutDoWidget(scriptTypeCell._rootNode, true, true)

        UIHelper.SetToggleGroupIndex(scriptTypeCell.TogRewardType, ToggleGroupIndex.OptionalBox)
        UIHelper.BindUIEvent(scriptTypeCell.TogRewardType, EventType.OnSelectChanged, function(_, bSelected)
            if bSelected then
                self.nOptionalType = index
                FilterDef.OptionalBox.Reset()
                self.nOptionalState = OptionalState.ALL
                self:ShowAwardView()
                self:UpdateBtnState()
            end
        end)

        if index == 1 then
            UIHelper.SetSelected(scriptTypeCell.TogRewardType, true, false)
        else
            UIHelper.SetSelected(scriptTypeCell.TogRewardType, false)
        end
    end

    UIHelper.ScrollViewDoLayout(self.ScrollviewType)
    UIHelper.ScrollToPercent(self.ScrollviewType, 0)
end

function UIPanelOptionalTreasureBox:ShowAwardView()
    UIHelper.ToggleGroupRemoveAllToggle(self.ToggleGroupReward)
    UIHelper.RemoveAllChildren(self.ScrollViewRewardList)

    if self.tBtn then
        self.tBtn.nRewardType = nil
        self.tBtn.nRewardIndex = nil
    end

    local bFirst = true
    local tList = self.tAward[self.nOptionalType]
    for _, tInfo in ipairs(tList) do
        local bCollt = tInfo.bHave
        local bShow = (self.nOptionalState == OptionalState.ALL) or (self.nOptionalState == OptionalState.HAVE and bCollt)
            or (self.nOptionalState == OptionalState.NOT and not bCollt)

        if bShow then
            local nPrefab = PREFAB_ID.WidgetOptionalBoxRewardCell
            if tInfo.nImageStyle == 2 then -- 坐骑
                nPrefab = PREFAB_ID.WidgetOptionalBoxRewardCell3
            elseif tInfo.nImageStyle == 1 then
                nPrefab = PREFAB_ID.WidgetOptionalBoxRewardCell2
            end
            local scriptCell = UIHelper.AddPrefab(nPrefab, self.ScrollViewRewardList) assert(scriptCell)
            UIHelper.ToggleGroupAddToggle(self.ToggleGroupReward, scriptCell.TogSelect)
            scriptCell:UpdateInfo(tInfo)
            scriptCell:SetCallBack(function(bSelected)
                if not bSelected then
                    return
                end

                local dwType, dwIndex = TreasureBoxData.SplitItemID(tInfo.szItem)
                self.tBtn = self.tBtn or {}
                self.tBtn.nItemSequence = tInfo.nContentID
                self.tBtn.nLuckyID = tInfo.nLuckyID or 0
                self.tBtn.nRewardType = dwType or 0
                self.tBtn.nRewardIndex = dwIndex or 0
                self:UpdateBtnState()
            end)

            if bFirst then
                local dwType, dwIndex = TreasureBoxData.SplitItemID(tInfo.szItem)
                self.tBtn = self.tBtn or {}
                self.tBtn.nItemSequence = tInfo.nContentID
                self.tBtn.nLuckyID = tInfo.nLuckyID or 0
                self.tBtn.nRewardType = dwType or 0
                self.tBtn.nRewardIndex = dwIndex or 0
                bFirst = false
                self:UpdateBtnState()
            end
        end
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewRewardList)
end


return UIPanelOptionalTreasureBox
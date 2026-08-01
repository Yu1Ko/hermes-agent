-- ---------------------------------------------------------------------------------
-- 随机宝箱页面
-- PanelRandomTreasureBox
-- ---------------------------------------------------------------------------------
local INDEX_TO_BOXTYPE = {
    [1] = 1, -- 竞技类
    [2] = 2, -- 阵营类
    [3] = 3, -- 家园类
    [4] = 4, -- 百战类
    [5] = 6, -- 名望类
}
local BOXTYPE_TO_INDEX = {}
for index, nType in ipairs(INDEX_TO_BOXTYPE) do
    BOXTYPE_TO_INDEX[nType] = index
end

local UIPanelRandomTreasureBox = class("UIPanelRandomTreasureBox")

function UIPanelRandomTreasureBox:_LuaBindList()
    self.ScrollLeft              = self.ScrollLeft --- 加载WidgetTreasureBox的scroll 左侧
    self.WidgetArrow             = self.WidgetArrow
    self.WidgetAnchorLeft        = self.WidgetAnchorLeft --- ScrollLeft 和 WidgetArrow 的上层

    self.WidgetItemCountController = self.WidgetItemCountController --- 数量编辑

    self.BtnYunShiDetai          = self.BtnYunShiDetai --- 运势btn
    self.LabelYunShiZhi          = self.LabelYunShiZhi --- 运势值

    self.LabelTitle              = self.LabelTitle --- 页面标题
    self.ToggleGroup             = self.ToggleGroup --- 底层tog group
    self.BtnClose                = self.BtnClose

    self.WidgetMiddle            = self.WidgetMiddle --- 加载奖励数组 WidgetTreasureBoxRewardCell
    self.TogBottom               = self.TogBottom --- 底层tog
    self.ScrollViewContent       = self.ScrollViewContent ---加载系列
end

-- 参数相关
-- self.nBoxType -- 竞技类、战场类
-- self.dwBoxID -- 当前宝箱对应表格的id

function UIPanelRandomTreasureBox:OnEnter(dwChoiceBoxID, dwChoiceTypeID, dwAwardSeriesID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        local AvatarMgr = g_pClientPlayer.GetMiniAvatarMgr()
        if not AvatarMgr.bDataSynced then
            AvatarMgr.ApplyMiniAvatarData()
        end
    end
    UIHelper.SetString(self.LabelTitle, "宝箱稀世奖励预览")
    self.dwChoiceBoxID = dwChoiceBoxID
    self.dwChoiceTypeID = dwChoiceTypeID
    self.dwAwardSeriesID = dwAwardSeriesID
    self.scriptBtn = UIHelper.GetBindScript(self.WidgetItemCountController)
    self:InitAwardView()
    self:UpdateChoiceType()
end

function UIPanelRandomTreasureBox:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelRandomTreasureBox:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    for index, tog in ipairs(self.TogBottom) do
        UIHelper.BindUIEvent(tog, EventType.OnSelectChanged, function(_,bSelected)
            if bSelected then
                self.nBoxType = INDEX_TO_BOXTYPE[index]
                self:UpdateType()
            end
        end)
    end
end

function UIPanelRandomTreasureBox:RegEvent()
    Event.Reg(self, "UPDATE_YUNSHI_VALUE", function(nLuckyValue, nID)
        self:SetYunShi(nLuckyValue, nID)
    end)

    -- Event.Reg(self, "BAG_ITEM_UPDATE", function(nBox, nIndex, _)
    --     local item = ItemData.GetItemByPos(nBox, nIndex)
    --     if (item and item.dwTabType == self.dwBtnType) and (item.dwIndex == self.dwBtnIndex) then
    --         self.dwBtnType = nil
    --         self.dwBtnIndex = nil
    --         self:UpdateView()
    --     end
    -- end)

    Event.Reg(self, "TreasureBoxViewUpdate", function(nBox, nIndex, _)
        self:UpdateView()
    end)
end

function UIPanelRandomTreasureBox:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIPanelRandomTreasureBox:UpdateChoiceType()
    TreasureBoxData.InitRandomBox()

    local nType = 1
    local ttBoxList = TreasureBoxData.GetRandomBox()
    local bFind = false
    if self.dwChoiceBoxID then
        for _, ttInfo in pairs(ttBoxList) do
            for _, tInfo in pairs(ttInfo) do
                if self.dwChoiceBoxID == tInfo.dwID then
                    nType = tInfo.nTypeID
                    break
                end
            end
            if bFind then
                break
            end
        end
    end
    self.nBoxType = nType

    self:UpdateType()
    for index, tog in ipairs(self.TogBottom) do
        UIHelper.SetSelected(tog, BOXTYPE_TO_INDEX[nType] == index, false)
    end
end

function UIPanelRandomTreasureBox:UpdateType()
    UIHelper.RemoveAllChildren(self.ScrollLeft)

    local tRowBoxList = TreasureBoxData.GetRandomBox(self.nBoxType)
    local tBoxList = {}
    self.tBoxCell = {}
    local szFirstShowBoxName
    for _, tInfo in ipairs(tRowBoxList) do
        local bShow = false
        if tInfo.bOwnToShow == true then
            local dwType, dwIndex = TreasureBoxData.SplitItemID(tInfo.szBoxItem, false)
            local BoxItem = ItemData.GetItemInfo(dwType, dwIndex)

            local nTotlaNum, _, _, _ = ItemData.GetItemAllStackNum(BoxItem, false)
            if nTotlaNum and nTotlaNum > 0 then
                bShow = true
            end
        else
            bShow = true
        end
        if bShow then
            table.insert(tBoxList, tInfo)
        end
    end

    for _, tInfo in ipairs(tBoxList) do
        local szBoxName = UIHelper.GBKToUTF8(tInfo.szItemName)
        local scriptCell = UIHelper.AddPrefab(PREFAB_ID.WidgetTreasureBox, self.ScrollLeft) assert(scriptCell)
        scriptCell:UpdateInfo(tInfo)
        scriptCell:SetCallBack(function()
            self.dwBoxID = tInfo.dwID
            self:UpdateAward(szBoxName)
        end)
        if self.dwChoiceBoxID and self.dwChoiceBoxID == tInfo.dwID then
            self.dwBoxID = self.dwChoiceBoxID
            self.dwChoiceBoxID = nil
            UIHelper.SetSelected(scriptCell.ToggleTreasureSeries, true, false)
            szFirstShowBoxName = szBoxName
        else
            UIHelper.SetSelected(scriptCell.ToggleTreasureSeries, false, false)
        end
        table.insert(self.tBoxCell, scriptCell)
    end

    if not szFirstShowBoxName then
        szFirstShowBoxName = tBoxList and tBoxList[1] and UIHelper.GBKToUTF8(tBoxList[1].szItemName)
        UIHelper.SetSelected(self.tBoxCell[1].ToggleTreasureSeries, true, false)
        self.dwBoxID = tBoxList and tBoxList[1] and tBoxList[1].dwID
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollLeft)

    self:UpdateAward(szFirstShowBoxName)
end

function UIPanelRandomTreasureBox:UpdateAward(szBoxName, nContentType, nFixNum)
    self:UpdateYunShi()
    self:UpdateBtnState(nFixNum)
    self:UpdatePreview()

    self.szBoxName = szBoxName
    local bHaveTable = self:IsAwardDataTable()
    self:ShowAwardView(bHaveTable, nContentType)
end

function UIPanelRandomTreasureBox:IsAwardDataTable()
    local szBoxName = self.szBoxName
    if not szBoxName then
        return
    end

    TreasureBoxData.InitAward()
    local tAward = TreasureBoxData.GetAwardList(self.dwBoxID)
    for _, ttInfo in pairs(tAward) do
        if ttInfo.bTable then
            return true
        end
    end

    return false
end

function UIPanelRandomTreasureBox:ShowAwardView(bHaveTable, nContentType)
    if bHaveTable then
        UIHelper.SetVisible(self.ScrollViewContent, true)
        self:ShowAwardRight(nContentType)
    else
        UIHelper.SetVisible(self.ScrollViewContent, false)
        local tAward = TreasureBoxData.GetAwardList(self.dwBoxID)
        self:ShowAwardMiddle(tAward)
    end
end

function UIPanelRandomTreasureBox:InitAwardView()
    self.scriptAwardCell = {}
    for index, widget in ipairs(self.WidgetMiddle) do
        local scriptCell = UIHelper.AddPrefab(PREFAB_ID.WidgetTreasureBoxRewardCell, widget) assert(scriptCell)
        UIHelper.SetVisible(scriptCell._rootNode, false)
        self.scriptAwardCell[index] = scriptCell
        self.scriptAwardCell[index]:SetBeAllHaveFalse(function()
            self.bAllHave = false
        end)
    end
end

function UIPanelRandomTreasureBox:ShowAwardRight(nContentType)
    UIHelper.RemoveAllChildren(self.ScrollViewContent)
    local ttAward = TreasureBoxData.GetAwardList(self.dwBoxID)
    local ttOrderAward = {}
    for _, tAward in pairs(ttAward) do
        table.insert(ttOrderAward, tAward)
    end
    ttAward = nil
    ttOrderAward = TreasureBoxData.Sort(ttOrderAward)

    local nFirstNotAllHaveIndex
    for nIndex, tAward in ipairs(ttOrderAward) do
        local nHave = 0
        for _, tInfo in ipairs(tAward.tInfo) do
            local bHave = TreasureBoxData.IsHaveItem(tInfo)
            if bHave then
                nHave = nHave + 1
            elseif not nFirstNotAllHaveIndex then
                nFirstNotAllHaveIndex = nIndex
            end
        end
        ttOrderAward[nIndex].nHave = nHave
    end

    local nSelectedContentType = nContentType or self.dwAwardSeriesID or nFirstNotAllHaveIndex or 1
    self.dwAwardSeriesID = nil

    for nIndex, tAward in ipairs(ttOrderAward) do
        local scriptCell = UIHelper.AddPrefab(PREFAB_ID.WidgetTreasureSeries, self.ScrollViewContent) assert(scriptCell)
        scriptCell:UpdateInfo(tAward.tInfo, tAward.nHave)
        scriptCell:SetCallBack(function()
            self:ShowAwardMiddle(tAward.tInfo)
        end)

        if nIndex == nSelectedContentType then
            UIHelper.SetSelected(scriptCell.ToggleTreasureSeries, true)
            self:ShowAwardMiddle(tAward.tInfo)
        else
            UIHelper.SetSelected(scriptCell.ToggleTreasureSeries, false)
        end
    end

    UIHelper.ScrollViewDoLayout(self.ScrollViewContent)
    UIHelper.ScrollToIndex(self.ScrollViewContent, nSelectedContentType - 1)
    Timer.AddFrame(self, 5, function()
        UIHelper.ScrollToIndex(self.ScrollViewContent, nSelectedContentType - 1)
    end)
end

function UIPanelRandomTreasureBox:ShowAwardMiddle(ttAward)
    for _, scriptCell in ipairs(self.scriptAwardCell) do
        UIHelper.SetVisible(scriptCell._rootNode, false)
    end

    local ttOrderAward = {}
    for _, tAward in pairs(ttAward) do
        table.insert(ttOrderAward, tAward)
    end
    ttOrderAward = TreasureBoxData.Sort(ttOrderAward)

    self.bAllHave = true
    for nIndex, tInfo in ipairs(ttOrderAward) do
        if nIndex > 4 then
            break
        end
        UIHelper.SetVisible(self.scriptAwardCell[nIndex]._rootNode, true)
        local scriptCell = self.scriptAwardCell[nIndex]
        UIHelper.SetVisible(scriptCell._rootNode, true)
        if tInfo.tInfo then
            scriptCell:UpdateInfo(tInfo.tInfo)
        else
            scriptCell:UpdateInfo(tInfo)
        end
        scriptCell:SetCallBack(function()
            self:UpdateBtnItem()
        end)
        UIHelper.SetSelected(scriptCell.ToggleTreasureSeries, false)
    end
    UIHelper.SetVisible(self.WidgetAllGet, self.bAllHave)

    if ttOrderAward[1].tInfo then
        self.nContentType = ttOrderAward[1].tInfo.nContentType
        self.scriptBtn:SetContentType(self.nContentType)
    else
        self.nContentType = ttOrderAward[1].nContentType
        self.scriptBtn:SetContentType(self.nContentType)
    end
end

function UIPanelRandomTreasureBox:UpdateBtnState(nFixNum)
    -- if self.nBoxType == 3 then
    --     self.scriptBtn:SetHomeLand(true)
    -- else
    --     self.scriptBtn:SetHomeLand(false)
    -- end
    self.scriptBtn:SetHomeLand(false)

    self.scriptBtn:UpdateRandomTreasureBox(self.dwBoxID, nFixNum)
    -- local tBox = Tabel_GetTreasureBoxListByID(self.dwBoxID)
    -- local dwType, dwIndex = TreasureBoxData.SplitItemID(tBox.szBoxItem)
    -- self.dwBtnType = dwType
    -- self.dwBtnIndex = dwIndex
    -- self.scriptBtn:SetCallBack(function(dwBoxID, nContentType, nFixNum)
    --     self:OldUpdateView(dwBoxID, nContentType, nFixNum)
    -- end)
end

function UIPanelRandomTreasureBox:OldUpdateView(dwBoxID, nContentType, nFixNum)
    -- nFixNum 加了时延之后发现数量仍然会存在刷新不到的情况 废弃
    local tBoxList = TreasureBoxData.GetRandomBox(self.nBoxType)
    for index, tInfo in ipairs(tBoxList) do
        if dwBoxID == tInfo.dwID then
            local szBoxName = UIHelper.GBKToUTF8(tInfo.szItemName)
            self.tBoxCell[index]:UpdateNum(nFixNum)
            self:UpdateAward(szBoxName, nContentType, nFixNum)
        end
    end
end

function UIPanelRandomTreasureBox:UpdateView()
    local tBoxList = TreasureBoxData.GetRandomBox(self.nBoxType)
    for index, tInfo in ipairs(tBoxList) do
        if self.dwBoxID == tInfo.dwID then
            self.tBoxCell[index]:UpdateInfo(tInfo)
            local szBoxName = UIHelper.GBKToUTF8(tInfo.szItemName)
            self:UpdateAward(szBoxName, self.nContentType)
        end
    end
end

function UIPanelRandomTreasureBox:UpdateYunShi()
    RemoteCallToServer("On_BoxOpenUI_GetBoxLuckyValue", self.dwBoxID)

    -- if self.nBoxType == 3 then
    --     UIHelper.SetVisible(self.BtnYunShiDetai, false)
    --     return
    -- else
    --     UIHelper.SetVisible(self.BtnYunShiDetai, true)
    -- end
end

function UIPanelRandomTreasureBox:SetYunShi(nLuckyValue, nType)
    if nType == self.dwBoxID then
        local tInfo = Tabel_GetTreasureBoxListByID(self.dwBoxID)
        local szYunShi = nLuckyValue .. "/" .. tInfo.nMaxTime
        UIHelper.SetString(self.LabelYunShiZhi, szYunShi)
    end
end

function UIPanelRandomTreasureBox:UpdatePreview()
    local tBox = Tabel_GetTreasureBoxListByID(self.dwBoxID)
    if not tBox then
        return
    end

    local bPreview = tBox and tBox.bPreviewOnly
    if not bPreview then
        UIHelper.SetVisible(self.LabelNormalGuidelines, false)
        UIHelper.SetVisible(self.WidgetItemCountController, true)
        UIHelper.SetVisible(self.BtnConfirm, true)
        UIHelper.LayoutDoLayout(self.LayoutOperation)
        return
    end

    local szContent = tBox.szPreviewOnlyDsc or ""
    if not string.is_nil(szContent) then
        UIHelper.SetString(self.LabelNormalGuidelines, UIHelper.GBKToUTF8(szContent))
        UIHelper.SetVisible(self.LabelNormalGuidelines, true)
    end
    UIHelper.SetVisible(self.WidgetItemCountController, false)
    UIHelper.SetVisible(self.BtnConfirm, false)
    UIHelper.LayoutDoLayout(self.LayoutOperation)
end


return UIPanelRandomTreasureBox
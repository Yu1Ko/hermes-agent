-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelSaleListDetailPop
-- Date: 2023-03-20 17:10:39
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPanelSaleListDetailPop = class("UIPanelSaleListDetailPop")

function UIPanelSaleListDetailPop:OnEnter(tbItem)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:Init(tbItem)
end

function UIPanelSaleListDetailPop:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelSaleListDetailPop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnLeft, EventType.OnClick, function()
        local nCurPage = self.nCurPage - 1 
        nCurPage = math.max(nCurPage, 1)
        self:SetCurPage(nCurPage)
    end)
    
    UIHelper.BindUIEvent(self.BtnRight, EventType.OnClick, function()
        local nCurPage = self.nCurPage + 1 
        nCurPage = math.min(nCurPage, self.nMaxPage)
        self:SetCurPage(nCurPage)
    end)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnSinglePrice, EventType.OnClick, function()
        self:SetDescendingOrder((self.nDescendingOrder + 1) % 2)
    end)

    UIHelper.RegisterEditBoxChanged(self.EditPaginate, function()
        self:OnEditPaginateChanged()
    end)
end

function UIPanelSaleListDetailPop:RegEvent()
    Event.Reg(self, EventType.ON_DETAIL_LOOK_UP, function(nMaxPage, tbDetailInfo)
        tbDetailInfo = TradingData.GetDetailList()
        if tbDetailInfo then 
            self:SetCurDetailInfo(tbDetailInfo)
        end 
        self:SetMaxPage(nMaxPage)
    end)
end

function UIPanelSaleListDetailPop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIPanelSaleListDetailPop:Init(tbItem)
    self:SetItem(tbItem)
    self:SetDescendingOrder(0, true)
    self:SetCurPage(1, true)
end

function UIPanelSaleListDetailPop:OnEditPaginateChanged()   
    local szText = UIHelper.GetText(self.EditPaginate) 
    local nNum = tonumber(szText) or 0
    nNum = math.min(nNum, self.nMaxPage)
    self:SetCurPage(nNum)
end




-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelSaleListDetailPop:UpdateInfo()
    
end

function UIPanelSaleListDetailPop:UpdateInfo_CurPage()
    UIHelper.SetText(self.LabelPaginate, self.nCurPage)
end

function UIPanelSaleListDetailPop:UpdateInfo_MaxPage()
    UIHelper.SetString(self.LabelPaginate, self.nMaxPage)
end


function UIPanelSaleListDetailPop:UpdateInfo_DetailList()
    UIHelper.RemoveAllChildren(self.ScrollViewSaleList)
    for index, tbInfo in ipairs(self.tbDetailInfo) do
        UIHelper.AddPrefab(PREFAB_ID.WidgetSaleListDetail, self.ScrollViewSaleList, tbInfo)
    end
    UIHelper.ScrollViewDoLayout(self.ScrollViewSaleList)
    UIHelper.ScrollToTop(self.ScrollViewSaleList)
end

function UIPanelSaleListDetailPop:UpdateInfo_TogSinglePriceSate()
    UIHelper.SetVisible(self.ImgTitleUP, self.nDescendingOrder == 0)
    UIHelper.SetVisible(self.ImgTitleDown,  self.nDescendingOrder == 1)
end


function UIPanelSaleListDetailPop:SetCurPage(nCurPage, bSkipApplyData)
    if bSkipApplyData or (not bSkipApplyData and TradingData.ApplyDetailLookUp(true, nCurPage, self.tbItem, self.nDescendingOrder)) then
        self.nCurPage = nCurPage
        self:UpdateInfo_CurPage()
    end
end

function UIPanelSaleListDetailPop:SetMaxPage(nMaxPage)
    self.nMaxPage = nMaxPage
    self:UpdateInfo_MaxPage()
end

function UIPanelSaleListDetailPop:SetItem(tbItem)
    self.tbItem = tbItem
end

function UIPanelSaleListDetailPop:SetCurDetailInfo(tbDetailInfo)
    self.tbDetailInfo = tbDetailInfo
    self:UpdateInfo_DetailList()
end

function UIPanelSaleListDetailPop:SetDescendingOrder(nDescendingOrder, bNotApply)
    self.nDescendingOrder = nDescendingOrder
    if bNotApply then
        local tbDetailInfo = TradingData.GetDetailList()
        if tbDetailInfo then 
            self:SetCurDetailInfo(tbDetailInfo)
        end 
        self:UpdateInfo_TogSinglePriceSate()
    else
        if TradingData.ApplyDetailLookUp(true, self.nCurPage, self.tbItem, self.nDescendingOrder) then 
            local tbDetailInfo = TradingData.GetDetailList()
            if tbDetailInfo then 
                self:SetCurDetailInfo(tbDetailInfo)
            end 
            self:UpdateInfo_TogSinglePriceSate()
        else
            self.nDescendingOrder = (self.nDescendingOrder + 1) % 2
        end
    end
end



return UIPanelSaleListDetailPop
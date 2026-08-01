-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetSaleListDetail
-- Date: 2023-03-20 17:46:20
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetSaleListDetail = class("UIWidgetSaleListDetail")

function UIWidgetSaleListDetail:OnEnter(tbInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbInfo = tbInfo
    self:UpdateInfo()
end

function UIWidgetSaleListDetail:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetSaleListDetail:BindUIEvent()
    
end

function UIWidgetSaleListDetail:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetSaleListDetail:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetSaleListDetail:UpdateInfo()
    local scriptView = UIHelper.GetBindScript(self.LayoutSinglePrice)
    scriptView:OnEnter(CovertMoneyToCopper(self.tbInfo.Price))

    UIHelper.SetString(self.LabelTrader, UIHelper.GBKToUTF8(self.tbInfo.SellerName))
    UIHelper.SetString(self.LabelSaleNum, self.tbInfo.StackNum)
    UIHelper.SetString(self.LabelLastingTime, TradingData.FormatAuctionLeftTime(self.tbInfo.LeftTime))
end


return UIWidgetSaleListDetail
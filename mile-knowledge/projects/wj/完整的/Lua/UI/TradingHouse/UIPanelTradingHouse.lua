-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelTradingHouse
-- Date: 2023-03-06 19:36:57
-- Desc: 交易行主界面
-- ---------------------------------------------------------------------------------

local UIPanelTradingHouse = class("UIPanelTradingHouse")

function UIPanelTradingHouse:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:InitData()

    Event.Dispatch("OPEN_AUCTION")
end

function UIPanelTradingHouse:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelTradingHouse:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.TogNavigationBuy, EventType.OnSelectChanged, function(toggle, bSelect)
        if bSelect then
            self:SetCurPage(1)
        end
    end)

    UIHelper.BindUIEvent(self.TogNavigationSell, EventType.OnSelectChanged, function(toggle, bSelect)
        if bSelect then
            self:SetCurPage(2)
        end
    end)

    UIHelper.BindUIEvent(self.TogNavigationAuction, EventType.OnSelectChanged, function(toggle, bSelect)
        if bSelect then
            self:SetCurPage(3)
        end
    end)
end

function UIPanelTradingHouse:RegEvent()
    Event.Reg(self, EventType.ON_AUCTION_SELL_SUCCESS, function()
        UIHelper.SetSelected(self.TogNavigationSell, true)
    end)
end

function UIPanelTradingHouse:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


function UIPanelTradingHouse:InitData()
    self:SetCurPage(1)
end




-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelTradingHouse:UpdateInfo()

end

function UIPanelTradingHouse:UpdateCurPage()
    UIHelper.SetVisible(self.WidgetTradeBuy, self.nCurPage == 1)
    UIHelper.SetVisible(self.WidgetTradeSell, self.nCurPage == 2)
    UIHelper.SetVisible(self.WidgetTradeAuction, self.nCurPage == 3)
    local tbView = {}
    local scripteBuyView = UIHelper.GetBindScript(self.WidgetTradeBuy)
    table.insert(tbView, scripteBuyView)
    local scripteSellView = UIHelper.GetBindScript(self.WidgetTradeSell)
    table.insert(tbView, scripteSellView)
    local scriptContrabandView = UIHelper.GetBindScript(self.WidgetTradeAuction)
    table.insert(tbView, scriptContrabandView)

    for index, View in ipairs(tbView) do
        if index == self.nCurPage then
            if index == 3 then
                View:OnEnter(BLACK_MARKET_TYPE.NEUTRAL)
            else
                View:OnEnter()
            end
        else
            View:OnViewClose()
        end
    end
end






function UIPanelTradingHouse:SetCurPage(nCurPage)
    self.nCurPage = nCurPage
    self:UpdateCurPage()
end

function UIPanelTradingHouse:CanShowWeaponType()
    if self.nCurPage ~= 1 then return false end
    local scripteBuyView = UIHelper.GetBindScript(self.WidgetTradeBuy)
    return scripteBuyView:IsFliterWeaponType()
end

function UIPanelTradingHouse:CanShowSchoolType()
    if self.nCurPage ~= 1 then return false end
    local scripteBuyView = UIHelper.GetBindScript(self.WidgetTradeBuy)
    return scripteBuyView:IsFliterSchoolType()
end

return UIPanelTradingHouse
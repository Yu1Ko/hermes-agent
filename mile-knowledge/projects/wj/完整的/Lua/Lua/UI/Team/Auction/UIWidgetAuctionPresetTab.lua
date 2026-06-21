-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetAuctionPresetTab
-- Date: 2023-02-14 20:15:33
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetAuctionPresetTab = class("UIWidgetAuctionPresetTab")

function UIWidgetAuctionPresetTab:OnEnter(szType, nPricePresetID, fCallBack)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.fCallBack = fCallBack
    self.nPricePresetID = nPricePresetID
    self:UpdateInfo(szType, nPricePresetID)
end

function UIWidgetAuctionPresetTab:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetAuctionPresetTab:BindUIEvent()
    UIHelper.BindUIEvent(self.ToggleSelect, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected and self.fCallBack then self.fCallBack(self.nPricePresetID) end
    end)
end

function UIWidgetAuctionPresetTab:RegEvent()

end

function UIWidgetAuctionPresetTab:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetAuctionPresetTab:UpdateInfo(szType, nPricePresetID)
    UIHelper.SetString(self.LabelNormal, szType)
    UIHelper.SetString(self.LabelUp, szType)
    UIHelper.SetVisible(self.WidgetUsing, nPricePresetID == Storage.Auction.nPricePresetID)
end

return UIWidgetAuctionPresetTab
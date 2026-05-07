-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIAuctionQuickFilter
-- Date: 2023-02-14 20:15:33
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIAuctionQuickFilter = class("UIAuctionQuickFilter")

function UIAuctionQuickFilter:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UIAuctionQuickFilter:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UIAuctionQuickFilter:BindUIEvent()
    UIHelper.BindUIEvent(self.TogShow, EventType.OnSelectChanged, function (_, bSelected)
        if self.fOnFilter then
            self.fOnFilter(bSelected)
        end
    end)
end

function UIAuctionQuickFilter:RegEvent()

end

function UIAuctionQuickFilter:UnRegEvent()

end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIAuctionQuickFilter:UpdateInfo()
    
end

function UIAuctionQuickFilter:SetOnFilterCallBack(fOnFilter)
    self.fOnFilter = fOnFilter
end

return UIAuctionQuickFilter
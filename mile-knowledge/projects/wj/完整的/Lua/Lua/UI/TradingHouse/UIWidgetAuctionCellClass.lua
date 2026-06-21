-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: WidgetAuctionCellClass
-- Date: 2023-07-05 16:12:07
-- Desc: ?
-- ---------------------------------------------------------------------------------

local WidgetAuctionCellClass = class("WidgetAuctionCellClass")

function WidgetAuctionCellClass:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbFlag = {}
    self.tbFlag[1] = true
    self.tbFlag[2] = true
    self:UpdateInfo()
end

function WidgetAuctionCellClass:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function WidgetAuctionCellClass:BindUIEvent()

end

function WidgetAuctionCellClass:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function WidgetAuctionCellClass:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function WidgetAuctionCellClass:UpdateInfo()
    UIHelper.SetVisible(self.WidgetAuctionItemCell1, false)
    UIHelper.SetVisible(self.WidgetAuctionItemCell2, false)
end

function WidgetAuctionCellClass:GetAuctionCell()
    if self.tbFlag[1] then
        self.tbFlag[1] = false
        return self.WidgetAuctionItemCell1
    end
    if self.tbFlag[2] then
        self.tbFlag[2] = false
        return self.WidgetAuctionItemCell2
    end

end

function WidgetAuctionCellClass:HasCell()
    return self.tbFlag[1] or self.tbFlag[2]
end

return WidgetAuctionCellClass
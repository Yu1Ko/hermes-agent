-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetPriceChartCell
-- Date: 2023-06-06 09:52:57
-- Desc: ?
-- ---------------------------------------------------------------------------------

local nMaxHeight = 280
local nMinHeight = 10

local UIWidgetPriceChartCell = class("UIWidgetPriceChartCell")

function UIWidgetPriceChartCell:OnEnter(nPercent, color, funcShowPrice)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nPercent = nPercent
    self.color = color
    self.funcShowPrice = funcShowPrice
    self:UpdateInfo()
end

function UIWidgetPriceChartCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetPriceChartCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnDots, EventType.OnClick, function()
        self.funcShowPrice()
    end)
end

function UIWidgetPriceChartCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetPriceChartCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetPriceChartCell:UpdateInfo()
    local nHeight = self.nPercent * (nMaxHeight - nMinHeight) + nMinHeight
    UIHelper.SetHeight(self.ImgBar, nHeight)
    UIHelper.SetColor(self.ImgDots, self.color)
    UIHelper.LayoutDoLayout(self._rootNode)
end


return UIWidgetPriceChartCell
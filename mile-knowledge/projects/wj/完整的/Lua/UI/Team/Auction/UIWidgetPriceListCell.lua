-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetPriceListCell
-- Date: 2023-02-14 20:15:33
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetPriceListCell = class("UIWidgetPriceListCell")

function UIWidgetPriceListCell:OnEnter(nPrice, fCallBack)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.fCallBack = fCallBack
    self:UpdateInfo(nPrice)
end

function UIWidgetPriceListCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UIWidgetPriceListCell:BindUIEvent()
    UIHelper.BindUIEvent(self.ToggleSelect, EventType.OnSelectChanged, function (_, bSelected)
        self.fCallBack()
    end)
end

function UIWidgetPriceListCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetPriceListCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetPriceListCell:UpdateInfo(nPrice)
    UIHelper.SetString(self.LabelNum, tostring(nPrice))
    UIHelper.LayoutDoLayout(self.LayoutCoin)
    UIHelper.SetTouchDownHideTips(self.ToggleSelect, false)    
end

return UIWidgetPriceListCell
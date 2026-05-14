-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIOtherCurrency
-- Date: 2022-11-24 20:12:54
-- Desc: ?
-- ---------------------------------------------------------------------------------

---@class UIOtherCurrency
local UIOtherCurrency = class("UIOtherCurrency")

function UIOtherCurrency:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIOtherCurrency:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIOtherCurrency:BindUIEvent()
    UIHelper.BindUIEvent(self.LayoutCost, EventType.OnClick, function()
        CurrencyData.ShowCurrencyHoverTipsInDir(self.LayoutCost, TipsLayoutDir.BOTTOM_LEFT, self.currencyType)
    end)
    UIHelper.SetTouchEnabled(self.LayoutCost, true)
end

function UIOtherCurrency:RegEvent()
end

function UIOtherCurrency:UnRegEvent()
end

function UIOtherCurrency:UpdateInfo()

end

function UIOtherCurrency:BindTipCallBack(btn)
    UIHelper.BindUIEvent(btn, EventType.OnClick, function()
        CurrencyData.ShowCurrencyHoverTipsInDir(self.LayoutCost, TipsLayoutDir.BOTTOM_LEFT, self.currencyType)
    end)
    UIHelper.SetTouchEnabled(self.LayoutCost, false)
end

function UIOtherCurrency:SetLableCount(value)
    if value then
        UIHelper.SetString(self.LabelCount, value)
        UIHelper.LayoutDoLayout(self.LayoutCost)
        local nWidth, nHeight = UIHelper.GetContentSize(self.LayoutCost)
        UIHelper.SetContentSize(self._rootNode, nWidth, nHeight)
    end
end

function UIOtherCurrency:SetCurrencyType(currencyType)
    self:SetSpriteFrame(currencyType)
    self:UpdateLabel()
end

function UIOtherCurrency:SetSpriteFrame(currencyType)
    self.currencyType = currencyType
    UIHelper.SetSpriteFrame(self.ImgCost, CurrencyData.tbImageSmallIcon[currencyType])
end

function UIOtherCurrency:UpdateLabel()
    if self.currencyType == CurrencyType.Vigor then
        local nCur,nLimit = CurrencyData.GetCurCurrencyLimit(self.currencyType)
        self:SetLableCount(nCur.."/"..nLimit)
    else
        self:SetLableCount(CurrencyData.GetCurCurrencyCount(self.currencyType))
    end
    UIHelper.CascadeDoLayoutDoWidget(UIHelper.GetParent(self._rootNode), true)
end

function UIOtherCurrency:HandleEvent()
    local fnUpdateFunc = function(bFirstInit) 
        Timer.AddFrame(self,1,function()
            self:UpdateLabel()
        end)
    end

    local tCurrencyUpdateEvent = Currency_Base.GetCurrencyList()
    for _, szCurrency in ipairs(tCurrencyUpdateEvent) do
        local szEvent = ("UPDATE_" .. szCurrency):upper()
        if szEvent then
            Event.Reg(self, szEvent, function()
                fnUpdateFunc()
            end)
        end
    end

    Event.Reg(self, "UPDATE_VIGOR", function()
        fnUpdateFunc()
    end)
    Event.Reg(self, "UPDATE_TONG_INFO_FINISH", function()
        fnUpdateFunc()
    end)
    Event.Reg(self, "UI_TRAIN_VALUE_UPDATE", function()
        fnUpdateFunc()
    end)
    Event.Reg(self, "TITLE_POINT_UPDATE", function (nNewTitlePoint, nAdd)
        fnUpdateFunc()
    end)
end

return UIOtherCurrency
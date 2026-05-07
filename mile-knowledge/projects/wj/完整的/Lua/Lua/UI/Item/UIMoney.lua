-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIMoney
-- Date: 2022-11-14 16:56:55
-- Desc: ?
-- Prefab: WidgetCurrency
-- ---------------------------------------------------------------------------------

---@class UIMoney
local UIMoney = class("UIMoney")

function UIMoney:OnEnter(OnMoneyChangeFunc, bShowHighestTwo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.OnMoneyChangeFunc = OnMoneyChangeFunc

    self.bShowHighestTwo = bShowHighestTwo
    self:UpdateInfo()
end

function UIMoney:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIMoney:BindUIEvent()
    UIHelper.BindUIEvent(self.LayoutCurrency, EventType.OnClick, function ()
        if self:IsShowHighestTwo() then

            local tip, script = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetItemTip, self.LayoutCurrency, TipsLayoutDir.BOTTOM_LEFT, CurrencyType.Money)
            script:OnInitCurrency(CurrencyType.Money)
            --local nx, ny = UIHelper.GetContentSize(script._rootNode)
            --tip:SetSize(nx, ny)
            --tip:SetOffset(-nx  , nil)
            --tip:Update()
        else
            CurrencyData.ShowCurrencyHoverTips( self.LayoutCurrency, CurrencyType.Money)
        end

    end)
    UIHelper.SetTouchEnabled(self.LayoutCurrency , true)
end

function UIMoney:RegEvent()
    Event.Reg(self, "MONEY_UPDATE", function ()
        self:UpdateInfo()

        if self.OnMoneyChangeFunc then
            self.OnMoneyChangeFunc()
        end
    end)
end

function UIMoney:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIMoney:BindTipCallBack(btn)
    UIHelper.BindUIEvent(btn, EventType.OnClick, function()
        if self:IsShowHighestTwo() then
            local tip, script = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetItemTip, btn, TipsLayoutDir.BOTTOM_LEFT, CurrencyType.Money)
            script:OnInitCurrency(CurrencyType.Money)
        else
            CurrencyData.ShowCurrencyHoverTips(btn, CurrencyType.Money)
        end
    end)
end

function UIMoney:UpdateInfo()
    if self:IsShowHighestTwo() then
        self:UpdateBagMoneyInfo()
        return
    end

    local tbMoney = ItemData.GetMoney()
    local bUpperDigitExist = false

    if bUpperDigitExist or tbMoney.nBullion > 0 then
        UIHelper.SetString(self.LabelMoney_Zhuan, tbMoney.nBullion)
        UIHelper.SetVisible(self.WidgetMoney1, true)
        UIHelper.LayoutDoLayout(self.WidgetMoney1)
        bUpperDigitExist = true
    else
        UIHelper.SetVisible(self.WidgetMoney1, false)
    end

    if bUpperDigitExist or tbMoney.nGold > 0 then
        UIHelper.SetString(self.LabelMoney_Jin, tbMoney.nGold)
        UIHelper.SetVisible(self.WidgetMoney2, true)
        UIHelper.LayoutDoLayout(self.WidgetMoney2)
        bUpperDigitExist = true
    else
        UIHelper.SetVisible(self.WidgetMoney2, false)
    end

    if bUpperDigitExist or tbMoney.nSilver > 0 then
        UIHelper.SetString(self.LabelMoney_Yin, tbMoney.nSilver)
        UIHelper.SetVisible(self.WidgetMoney3, true)
        UIHelper.LayoutDoLayout(self.WidgetMoney3)
        bUpperDigitExist = true
    else
        UIHelper.SetVisible(self.WidgetMoney3, false)
    end

    UIHelper.SetString(self.LabelMoney_Tong, tbMoney.nCopper)
    UIHelper.LayoutDoLayout(self.WidgetMoney4)

    UIHelper.LayoutDoLayout(self.LayoutCurrency)
    UIHelper.SetContentSize(self._rootNode, UIHelper.GetContentSize(self.LayoutCurrency))
    local parent = UIHelper.GetParent(self._rootNode)
    UIHelper.LayoutDoLayout(parent)
end

function UIMoney:UpdateBagMoneyInfo()
    local tbMoney = ItemData.GetMoney()

    UIHelper.SetVisible(self.WidgetMoney1, false)
    UIHelper.SetVisible(self.WidgetMoney2, false)
    UIHelper.SetVisible(self.WidgetMoney3, false)
    UIHelper.SetVisible(self.WidgetMoney4, false)
    if tbMoney.nBullion > 0 then
        UIHelper.SetString(self.LabelMoney_Zhuan, tbMoney.nBullion)
        UIHelper.SetVisible(self.WidgetMoney1, true)
        UIHelper.LayoutDoLayout(self.WidgetMoney1)

        UIHelper.SetString(self.LabelMoney_Jin, tbMoney.nGold)
        UIHelper.SetVisible(self.WidgetMoney2, true)
        UIHelper.LayoutDoLayout(self.WidgetMoney2)
    elseif tbMoney.nGold > 0 then
        UIHelper.SetString(self.LabelMoney_Jin, tbMoney.nGold)
        UIHelper.SetVisible(self.WidgetMoney2, true)
        UIHelper.LayoutDoLayout(self.WidgetMoney2)

        UIHelper.SetString(self.LabelMoney_Yin, tbMoney.nSilver)
        UIHelper.SetVisible(self.WidgetMoney3, true)
        UIHelper.LayoutDoLayout(self.WidgetMoney3)
    elseif tbMoney.nSilver > 0 then
        UIHelper.SetString(self.LabelMoney_Yin, tbMoney.nSilver)
        UIHelper.SetVisible(self.WidgetMoney3, true)
        UIHelper.LayoutDoLayout(self.WidgetMoney3)

        UIHelper.SetString(self.LabelMoney_Tong, tbMoney.nCopper)
        UIHelper.SetVisible(self.WidgetMoney4, true)
        UIHelper.LayoutDoLayout(self.WidgetMoney4)
    else
        UIHelper.SetString(self.LabelMoney_Tong, tbMoney.nCopper)
        UIHelper.SetVisible(self.WidgetMoney4, true)
        UIHelper.LayoutDoLayout(self.WidgetMoney4)
    end

    UIHelper.LayoutDoLayout(self.LayoutCurrency)
    UIHelper.SetContentSize(self._rootNode, UIHelper.GetContentSize(self.LayoutCurrency))
    local parent = UIHelper.GetParent(self._rootNode)
    UIHelper.LayoutDoLayout(parent)
end

function UIMoney:UpdateAllTypeMoney()
    local tbMoney = ItemData.GetMoney()
    UIHelper.SetString(self.LabelMoney_Zhuan, tbMoney.nBullion)
    UIHelper.SetVisible(self.WidgetMoney1, true)
    UIHelper.LayoutDoLayout(self.WidgetMoney1)
    UIHelper.SetString(self.LabelMoney_Jin, tbMoney.nGold)
    UIHelper.SetVisible(self.WidgetMoney2, true)
    UIHelper.LayoutDoLayout(self.WidgetMoney2)
    UIHelper.SetString(self.LabelMoney_Yin, tbMoney.nSilver)
    UIHelper.SetVisible(self.WidgetMoney3, true)
    UIHelper.LayoutDoLayout(self.WidgetMoney3)

    UIHelper.SetString(self.LabelMoney_Tong, tbMoney.nCopper)
    UIHelper.SetVisible(self.WidgetMoney4, true)
    UIHelper.LayoutDoLayout(self.WidgetMoney4)

    UIHelper.LayoutDoLayout(self.LayoutCurrency)
    UIHelper.SetContentSize(self._rootNode, UIHelper.GetContentSize(self.LayoutCurrency))
    local parent = UIHelper.GetParent(self._rootNode)
    UIHelper.LayoutDoLayout(parent)
end

function UIMoney:SetShowHighestTwo(bShowHighestTwo)
    self.bShowHighestTwo = bShowHighestTwo
end

function UIMoney:IsShowHighestTwo()
    return self.bShowHighestTwo or CurrencyData.bCurrentBagView
end


return UIMoney

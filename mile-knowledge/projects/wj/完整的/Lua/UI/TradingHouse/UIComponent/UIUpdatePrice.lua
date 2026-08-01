-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIUpdatePrice
-- Date: 2023-03-13 19:35:04
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIUpdatePrice = class("UIUpdatePrice")

function UIUpdatePrice:OnEnter(nMoney, szTitle, bShowEmpty)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    if nMoney then
        self.nMoney = nMoney
        self.szTitle = szTitle
        self.bShowEmpty = bShowEmpty
        self:UpdateInfo()
    end
end

function UIUpdatePrice:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIUpdatePrice:BindUIEvent()
    
end

function UIUpdatePrice:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIUpdatePrice:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIUpdatePrice:UpdateInfo()
    if self.szTitle and self.Title then
        UIHelper.SetString(self.Title, self.szTitle)
    end

    local nBullion, nGold, nSilver, nCopper = UIHelper.MoneyToBullionGoldSilverAndCopper(self.nMoney)
    -- local nGold, nSilver, nCopper = UIHelper.MoneyToGoldSilverAndCopper(self.nMoney)
    UIHelper.SetString(self.LabelMoney_Zhuan, nBullion)
    UIHelper.SetString(self.LabelMoney_Jin, nGold)
    UIHelper.SetString(self.LabelMoney_Yin, nSilver)
    if self.LabelMoney_Tong then
        UIHelper.SetString(self.LabelMoney_Tong, nCopper)
    end

    -- UIHelper.SetVisible(self.WidgetMoneyZhuan, nBullion ~= 0)
    -- UIHelper.SetVisible(self.WidgetMoneyJin, nGold ~= 0)
    -- UIHelper.SetVisible(self.WidgetMoneyYin, nSilver ~= 0)
    if self.WidgetMoneyTong then
        UIHelper.SetVisible(self.WidgetMoneyTong, nCopper ~= 0)
    end

    UIHelper.CascadeDoLayoutDoWidget(self.Layout, true, true)

    UIHelper.SetVisible(self.Layout, not self.bShowEmpty)
    UIHelper.SetVisible(self.LabelEmpty, self.bShowEmpty)
end


return UIUpdatePrice
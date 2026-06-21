-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICurrencyCell
-- Date: 2022-12-30 15:55:09
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICurrencyCell = class("UICurrencyCell")

function UICurrencyCell:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UICurrencyCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UICurrencyCell:BindUIEvent()
    UIHelper.BindUIEvent(self.ToggleMoneyCell , EventType.OnClick , function ()
        if self.clickCallback then
            self.clickCallback(self.nMoneyType,self)
        end
    end)
end

function UICurrencyCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UICurrencyCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICurrencyCell:UpdateInfo(nMoneyType  , callback)
    self.nMoneyType = nMoneyType
    self.clickCallback = callback
    UIHelper.SetVisible(self.LayoutCoinNormal , nMoneyType ~= CurrencyType.Money)
    UIHelper.SetVisible(self.LayoutCurrencyNormal , nMoneyType == CurrencyType.Money)
    UIHelper.SetVisible(self.LayoutCoinUp , nMoneyType ~= CurrencyType.Money)
    UIHelper.SetVisible(self.LayoutCurrencyUp , nMoneyType == CurrencyType.Money)
    if nMoneyType == CurrencyType.Money then
        UIHelper.GetBindScript(self.LayoutCurrencyNormal):UpdateInfo(nMoneyType)
        UIHelper.GetBindScript(self.LayoutCurrencyUp):UpdateInfo(nMoneyType)
        UIHelper.LayoutDoLayout(self.LayoutCurrencyNormal)
        UIHelper.LayoutDoLayout(self.LayoutCurrencyUp)
    else
        UIHelper.GetBindScript(self.LayoutCoinNormal):UpdateInfo(nMoneyType)
        UIHelper.GetBindScript(self.LayoutCoinUp):UpdateInfo(nMoneyType)
        UIHelper.LayoutDoLayout(self.LayoutCoinNormal)
        UIHelper.LayoutDoLayout(self.LayoutCoinUp)
    end
    
    local szCurrencyName = CurrencyData.GetCurrencyName(nMoneyType)
    UIHelper.SetString(self.LabelMoneyTypeNormal, szCurrencyName)
    UIHelper.SetString(self.LabelMoneyTypeUp, szCurrencyName)
    self:UpdateSelectState(false)
end

function UICurrencyCell:UpdateSelectState(isSelect)
    UIHelper.SetVisible( self.WidgetUp ,  isSelect)
    UIHelper.SetVisible( self.WidgetNormal , not isSelect)
end


return UICurrencyCell
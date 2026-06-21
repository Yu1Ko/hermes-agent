-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICurrencyMoney
-- Date: 2022-12-30 15:38:34
-- Desc: 货币金钱- 主要运用于金砖，金，银，铜，以及其他货币 可以复用
-- ---------------------------------------------------------------------------------

local UICurrencyMoney = class("UICurrencyMoney")

function UICurrencyMoney:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UICurrencyMoney:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UICurrencyMoney:BindUIEvent()
    
end

function UICurrencyMoney:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UICurrencyMoney:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICurrencyMoney:UpdateInfo(nMoneyType)
    if nMoneyType == CurrencyType.Money then
        local nGoldB,nGold,nSilver,nCopper = CurrencyData.GetCurCurrencyCount(nMoneyType)
        UIHelper.SetString(self.LabelMoney_Zhuan , nGoldB)
        UIHelper.SetString(self.LabelMoney_Jin , nGold)
        UIHelper.SetString(self.LabelMoney_Yin , nSilver)
        UIHelper.SetString(self.LabelMoney_Tong , nCopper)
        UIHelper.LayoutDoLayout(self.WidgetMoney1)
        UIHelper.LayoutDoLayout(self.WidgetMoney2)
        UIHelper.LayoutDoLayout(self.WidgetMoney3)
        UIHelper.LayoutDoLayout(self.WidgetMoney4)
    else
        if nMoneyType == CurrencyType.Vigor then
            local nCur,nLimit = CurrencyData.GetCurCurrencyLimit(nMoneyType)
            UIHelper.SetString(self.LabelCoin , nCur.."/"..nLimit)
            UIHelper.SetSpriteFrame(self.ImgCoin, CurrencyData.tbImageSmallIcon[nMoneyType])
        else
            UIHelper.SetString(self.LabelCoin , CurrencyData.GetCurCurrencyCount(nMoneyType))
            UIHelper.SetSpriteFrame(self.ImgCoin, CurrencyData.tbImageSmallIcon[nMoneyType])
        end
    end
end


return UICurrencyMoney
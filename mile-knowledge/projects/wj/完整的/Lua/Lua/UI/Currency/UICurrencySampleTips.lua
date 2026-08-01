-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICurrencySampleTips
-- Date: 2023-02-21 16:35:04
-- Desc: 货币提示
-- ---------------------------------------------------------------------------------

local UICurrencySampleTips = class("UICurrencySampleTips")

function UICurrencySampleTips:OnEnter(currencyType, szTitle, szContent)
    self.currencyType = currencyType
    self.szTitle = szTitle
    self.szContent = szContent

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UICurrencySampleTips:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UICurrencySampleTips:BindUIEvent()
    Event.Reg(self, EventType.HideAllHoverTips, function ()
        UIHelper.SetActiveAndCache(self , self._rootNode , false)
    end)
end

function UICurrencySampleTips:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UICurrencySampleTips:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICurrencySampleTips:UpdateInfo()
    UIHelper.SetActiveAndCache(self , self._rootNode , true)

    if string.is_nil(self.currencyType) then
        self.normalScript = UIHelper.AddPrefab(PREFAB_ID.WidgetTipsWithSubtitleContentCell, self.WidgetMoneyDescription)
        self.normalScript:UpdateTitle(self.szTitle)
        self.normalScript:UpdateContent(self.szContent)
    else
        if self.currencyType == CurrencyType.Money and CurrencyData.bCurrentBagView then
            local tbScript = UIHelper.AddPrefab(PREFAB_ID.WidgetCurrency, self.WidgetMoneyDescription)
            Timer.AddFrame(self, 1, function ()
                tbScript:UpdateAllTypeMoney()
            end)
        end
        if not self.getLimitCell then
            self.getLimitCell = UIHelper.AddPrefab(PREFAB_ID.WidgetTipsWithSubtitleContentCell, self.WidgetMoneyDescription)
        end

        if not self.sourceScript then
            self.sourceScript = UIHelper.AddPrefab(PREFAB_ID.WidgetTipsWithSubtitleContentCell, self.WidgetMoneyDescription)
        end

        if not self.purposeScript then
            self.purposeScript = UIHelper.AddPrefab(PREFAB_ID.WidgetTipsWithSubtitleContentCell, self.WidgetMoneyDescription)
        end

        UIHelper.SetVisible(self.getLimitCell._rootNode ,CurrencyData.tbGetLimit[self.currencyType] ~= nil)
        if CurrencyData.tbGetLimit[self.currencyType] then
            self.getLimitCell:UpdateTitle("获取")

            if self.currencyType == CurrencyType.FeiShaWand then
                self.getLimitCell:UpdateContent(string.format(CurrencyData.tbGetLimit[self.currencyType],CurrencyData.GetCurCurrencyCount(self.currencyType),CurrencyData.GetCurCurrencyLimit(self.currencyType)))
            else
                self.getLimitCell:UpdateContent(string.format(CurrencyData.tbGetLimit[self.currencyType],CurrencyData.GetCurCurrencyLimit(self.currencyType)))
            end
        end

        if CurrencyData.tbSourceDesc[self.currencyType] then
            self.sourceScript:UpdateTitle(CurrencyData.szSourceDesc)
            self.sourceScript:UpdateContent(CurrencyData.tbSourceDesc[self.currencyType])
        else
            UIHelper.SetVisible(self.sourceScript._rootNode, false)
        end

        self.purposeScript:UpdateTitle(CurrencyData.szPurposeDesc)
        self.purposeScript:UpdateContent(CurrencyData.tbPurposeDesc[self.currencyType])
    end

    UIHelper.LayoutDoLayout(self.WidgetMoneyDescription)
    local nWidth, nHeight = UIHelper.GetContentSize(self.WidgetMoneyDescription)
    UIHelper.SetContentSize(self._rootNode, nWidth, nHeight)
end

return UICurrencySampleTips
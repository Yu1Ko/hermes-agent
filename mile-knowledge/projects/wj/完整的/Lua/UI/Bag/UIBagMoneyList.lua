-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIBagMoneyList
-- Date: 2024-06-25 19:21:08
-- Desc: ?
-- ---------------------------------------------------------------------------------

local MAX_COUNT = 2

local UIBagMoneyList = class("UIBagMoneyList")

function UIBagMoneyList:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true 
        self.bSetting = false
    end
    self:UpdateInfo()
end

function UIBagMoneyList:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIBagMoneyList:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function(btn)
        self:ShowSetting(false)
    end)

    UIHelper.BindUIEvent(self.BtnMoneySetting, EventType.OnClick, function(btn)
        self:ShowSetting(not self.bSetting)
    end)
end

function UIBagMoneyList:RegEvent()

end

function UIBagMoneyList:UnRegEvent()
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIBagMoneyList:UpdateInfo()
    local tAllInfo = Table_GetCurrencyInfo()
    if not tAllInfo then
        return
    end
    
    table.insert(tAllInfo,1, {szName = CurrencyType.Money})
    table.insert(tAllInfo,2, {szName = CurrencyType.Coin})
    table.insert(tAllInfo,3, {szName = CurrencyType.Train})
    table.insert(tAllInfo,4, {szName = CurrencyType.Vigor})
    table.insert(tAllInfo,5, {szName = CurrencyType.TitlePoint})
    self.tCellScripts = {}
    for k, v in ipairs(tAllInfo) do
        local nMoneyType = v.szName
        local bShow = nMoneyType == CurrencyType.Money or nMoneyType == CurrencyType.Coin or Currency_Base.IsCurrencyVisible(v)
        if bShow then
            local cell = UIMgr.AddPrefab(PREFAB_ID.WidgetBagMoneyListCell, self.ScrollViewMoneyList)
            UIHelper.SetAnchorPoint(cell._rootNode, 0, 0.5)
            cell.nMoneyType = nMoneyType

            if nMoneyType == CurrencyType.Money then
                local script = UIHelper.GetBindScript(cell.WidgetCurrency)
                script:OnEnter()
                script:UpdateBagMoneyInfo()
                script:BindTipCallBack(cell.BtnCurrency)
            elseif nMoneyType == CurrencyType.Coin then
                local script = UIHelper.AddPrefab(PREFAB_ID.WidgetCoin, cell.WidgetCoinParent, CurrencyType.Coin, false, nil, false)
                script.LayoutCoin:removeBackGroundImage()
            else
                local script = UIHelper.GetBindScript(cell.WidgetOtherCurrency)
                script:OnEnter()
                script:SetCurrencyType(nMoneyType)
                script:HandleEvent()
                script:BindTipCallBack(cell.BtnCurrency)
            end

            UIHelper.SetVisible(cell.WidgetCurrency, nMoneyType == CurrencyType.Money)
            UIHelper.SetVisible(cell.WidgetCoinParent, nMoneyType == CurrencyType.Coin)
            UIHelper.SetVisible(cell.WidgetOtherCurrency, (nMoneyType ~= CurrencyType.Money and nMoneyType ~= CurrencyType.Coin))
            table.insert(self.tCellScripts, cell)
        end
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewMoneyList)
    UIHelper.ScrollViewSetupArrow(self.ScrollViewMoneyList, self.WidgetArrowParent)
end

function UIBagMoneyList:ShowSetting(bSetting)
    if bSetting ~= self.bSetting then
        self.bSetting = bSetting
        for _, script in ipairs(self.tCellScripts) do
            UIHelper.SetVisible(script.ToggleMultiSelect, bSetting)
        end
        UIHelper.SetVisible(self.BtnMoneySetting, not bSetting)
        UIHelper.SetVisible(self.BtnConfirm, bSetting)
        UIHelper.SetString(self.LabelBagName, bSetting and "货币显示设置" or "我的货币")
        UIHelper.LayoutDoLayout(self.LayoutMoneyContent)
        if bSetting then
            self:UpdateSettingState()
        end
    end
end

function UIBagMoneyList:UpdateSettingState()
    local tbSelected = clone(Storage.Bag.tbSelectedCurrencyNew)
    local bMaxLen = table.get_len(tbSelected) >= MAX_COUNT
    for _, script in ipairs(self.tCellScripts) do
        local bInList = tbSelected[script.nMoneyType]
        local fnSelected = function(tog, bSelected)
            if bSelected then
                tbSelected[script.nMoneyType] = true
            else
                tbSelected[script.nMoneyType] = nil
            end

            if table.get_len(tbSelected) > 0 and table.get_len(tbSelected) <= MAX_COUNT then
                Storage.Bag.tbSelectedCurrencyNew = tbSelected
                Storage.Bag.Flush()
                self:UpdateSettingState()
                Event.Dispatch(EventType.OnCurrencyChange)
            else
                Timer.AddFrame(self, 1, function()
                    TipsHelper.ShowNormalTip("请选择一到两种货币")
                end)
            end
        end

        local bDisable = not bInList and bMaxLen

        UIHelper.SetVisible(script.ImgForbidden, bDisable)
        UIHelper.SetEnable(script.ToggleMultiSelect, not bDisable)

        UIHelper.SetSelected(script.ToggleMultiSelect, bInList, false)
        UIHelper.BindUIEvent(script.ToggleMultiSelect, EventType.OnSelectChanged, fnSelected)
    end
end

return UIBagMoneyList
-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetManualDropItem
-- Date: 2023-02-14 20:15:33
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetManualDropItem = class("UIWidgetManualDropItem")

function UIWidgetManualDropItem:OnEnter(Param1, Param2, fnSelect)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.fnSelect = fnSelect
    self.bItem = type(Param1) ~= "string"
    if self.bItem then
        self:UpdateItemInfo(Param1)
    else
        self:UpdateCurrencyInfo(Param1, Param2)
    end
end

function UIWidgetManualDropItem:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UIWidgetManualDropItem:BindUIEvent()
    UIHelper.BindUIEvent(self.ToggleSelect, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected and self.fnSelect then self.fnSelect(self) end
    end)
end

function UIWidgetManualDropItem:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetManualDropItem:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetManualDropItem:UpdateCurrencyInfo(szCurrencyType, nValue)
    self.szCurrencyType = szCurrencyType
    self.nValue = self.nValue
    if szCurrencyType == CurrencyType.Money then
        UIHelper.SetMoneyIcon(self.ImgItemIcon, nValue)
        local nPrice = nValue
        local nBrick = math.floor(nPrice / 10000 / 10000)
        nPrice = nPrice - nBrick * 10000 * 10000
        local nGold = math.floor(nPrice / 10000)
        nPrice = nPrice - nGold * 10000
        local nSilver = math.floor(nPrice / 100)
        local nCopper = nPrice - nSilver * 100
    
        UIHelper.SetString(self.LabelMoney_Zhuan, tostring(nBrick))
        UIHelper.SetString(self.LabelMoney_Jin, tostring(nGold))
        UIHelper.SetString(self.LabelMoney_Yin, tostring(nSilver))
        UIHelper.SetString(self.LabelMoney_Tong, tostring(nCopper))
    
        UIHelper.SetVisible(self.WidgetMoney_Zhuan, nBrick > 0)
        UIHelper.SetVisible(self.WidgetMoney_Jin, nGold > 0)
        UIHelper.SetVisible(self.WidgetMoney_Yin, nSilver > 0)
        UIHelper.SetVisible(self.WidgetMoney_Tong, nCopper > 0)
        UIHelper.SetVisible(self.LayoutCurrency, true)
        UIHelper.SetVisible(self.RichTextItemName, false)
        UIHelper.LayoutDoLayout(self.LayoutCurrency)
    else
        local szImagePath = CurrencyData.tbImageBigIcon[szCurrencyType]
        UIHelper.SetSpriteFrame(self.ImgItemIcon, szImagePath)
        UIHelper.SetString(self.LabelCount, nValue)
        UIHelper.SetRichText(self.RichTextItemName, szCurrencyType)
        UIHelper.SetVisible(self.RichTextItemName, true)
    end
    UIHelper.SetSpriteFrame(self.ImgPolishCountBG, ItemQualityBGColor[6])
end

function UIWidgetManualDropItem:UpdateItemInfo(tDropInfo)
    self.tDropInfo = tDropInfo
    local tItemInfo = GetItemInfo(tDropInfo.dwType, tDropInfo.dwIndex)
    if not tItemInfo then return end
    local nIconID = Table_GetItemIconID(tItemInfo.nUiId)
    local szImgPath = UIHelper.GetIconPathByIconID(nIconID)
    UIHelper.SetTexture(self.ImgItemIcon, szImgPath)
    UIHelper.SetSpriteFrame(self.ImgPolishCountBG, ItemQualityBGColor[tItemInfo.nQuality+1])

    local szName = ItemData.GetItemNameByItemInfo(tItemInfo)
    szName = UIHelper.GBKToUTF8(szName)

    local nDiamondR, nDiamondG, nDiamondB = GetItemFontColorByQuality(tItemInfo.nQuality)
    szName = GetFormatText(szName, nil, nDiamondR, nDiamondG, nDiamondB)
    UIHelper.SetRichText(self.RichTextItemName, szName)
    UIHelper.SetVisible(self.RichTextItemName, true)
    UIHelper.SetString(self.LabelCount, tDropInfo.nCount)
    UIHelper.SetSwallowTouches(self.ToggleSelect, false)
end

function UIWidgetManualDropItem:ShowDropItemTips()
    TipsHelper.DeleteAllHoverTips(true)
    if not self.bItem then
        local tips, scriptItemTip = TipsHelper.ShowCurrencyTips(self.ToggleSelect, self.szCurrencyType, self.nValue)
        tips:SetDisplayLayoutDir(TipsLayoutDir.TOP_LEFT)
        tips:Update()
    else
        TipsHelper.ShowItemTips(self.ToggleSelect, self.tDropInfo.dwType, self.tDropInfo.dwIndex, false, TipsLayoutDir.TOP_LEFT)
    end
end

return UIWidgetManualDropItem
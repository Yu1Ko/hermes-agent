-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICommonItem
-- Date: 2022-11-30 19:12:51
-- Desc: WidgetItemWithName
-- ---------------------------------------------------------------------------------

local UICommonItem = class("UICommonItem")

function UICommonItem:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UICommonItem:OnExit()
    self.bInit = false
    self:UnRegEvent()

    self.SelectCallBack = nil
    self.RecallCallBack = nil
end

function UICommonItem:BindUIEvent()
    UIHelper.BindUIEvent(self.ToggleSelect, EventType.OnClick, function ()
        if self.SelectCallBack then
            self.SelectCallBack(UIHelper.GetSelected(self.ToggleSelect))
        end
    end)
    UIHelper.BindUIEvent(self.ToggleAddSelect, EventType.OnClick, function ()
        if self.SelectCallBack then
            self.SelectCallBack(UIHelper.GetSelected(self.ToggleAddSelect))
        end
    end)
    UIHelper.BindUIEvent(self.BtnRecall, EventType.OnClick, function ()
        if self.RecallCallBack then
            self.RecallCallBack()
        end
    end)
end

function UICommonItem:RegEvent()
    Event.Reg(self, EventType.OnClearUICommonItemSelect, function()
        self:SetSelected(false)
        self:SetAddToggleSelected(false)
    end)
end

function UICommonItem:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UICommonItem:SetSelected(bSelected)
    UIHelper.SetSelected(self.ToggleSelect, bSelected)
end

function UICommonItem:SetAddToggleSelected(bSelected)
    UIHelper.SetSelected(self.ToggleAddSelect, bSelected)
end

function UICommonItem:RawSetSelected(bSelected)
    UIHelper.SetSelected(self.ToggleSelect, bSelected, false)
end

function UICommonItem:ToggleGroupAddToggle(ToggleGroup)
    UIHelper.ToggleGroupAddToggle(ToggleGroup, self.ToggleSelect)
end

function UICommonItem:SetLableCount(value)
    UIHelper.SetString(self.LabelCount, value)
end

function UICommonItem:SetLabelItemName(value)
    UIHelper.SetString(self.LabelItemName, value, 4)
end

function UICommonItem:SetItemGray(bGray)
    UIHelper.SetNodeGray(self.ImgIcon, bGray, true)
    UIHelper.SetOpacity(self.ImgIcon, bGray and 120 or 255)
    UIHelper.SetOpacity(self.ImgPolishCountBG, bGray and 120 or 255)
end

function UICommonItem:SetImgIcon(szFileName)
    UIHelper.SetTexture(self.ImgIcon, szFileName)
end

function UICommonItem:SetItemQualityBg(nQuality)
    UIHelper.SetSpriteFrame(self.ImgPolishCountBG, ItemQualityBGColor[nQuality + 1])
end

function UICommonItem:SetImgIconByIconID(nIconID)
    UIHelper.SetItemIconByIconID(self.ImgIcon, nIconID)
end

function UICommonItem:OnInitWithTabID(nTabType, nTabID, nStackNum)
    if not nTabID then
        return
    end
    local ItemInfo = GetItemInfo(nTabType, nTabID)
    local szItemName = UIHelper.GBKToUTF8(Table_GetItemName(ItemInfo.nUiId))

    UIHelper.SetSpriteFrame(self.ImgPolishCountBG, ItemQualityBGColor[ItemInfo.nQuality + 1])
    UIHelper.SetString(self.LabelItemName, szItemName, 4)
    UIHelper.SetItemIconByItemInfo(self.ImgIcon, ItemInfo)

    if nStackNum then
        UIHelper.SetString(self.LabelCount, nStackNum)
    end
end

function UICommonItem:SetTextColor(color)
    UIHelper.SetTextColor(self.LabelItemName, color)
    --UIHelper.SetTextColor(self.LabelCount, color)
end

function UICommonItem:SetLabelCountColor(color)
    UIHelper.SetTextColor(self.LabelCount, color)
end

function UICommonItem:RegisterSelectEvent(func)
    self.SelectCallBack = func
end

function UICommonItem:RegisterRecallEvent(func)
    self.RecallCallBack = func
    UIHelper.SetVisible(self.BtnRecall, func ~= nil)
end

function UICommonItem:SetRecallVisible(bVisible)
    UIHelper.SetVisible(self.BtnRecall, bVisible)
end

function UICommonItem:SetAddBtnVisible(bVisible)
    UIHelper.SetVisible(self.ImgIcon, not bVisible)
    UIHelper.SetVisible(self.ImgBlack, not bVisible)
    UIHelper.SetVisible(self.WidgetAdd, bVisible)
end

function UICommonItem:UpdateInfo()

end


return UICommonItem
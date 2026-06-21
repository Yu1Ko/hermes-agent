-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIAutoFeedView
-- Date: 2024-07-01 14:56:58
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIAutoFeedView = class("UIAutoFeedView")

local tQuality ={
    [1] = "普通",
    [2] = "<color=#70ffbb>精巧</color>",
    [3] = "<color=#abeeff>卓越</color>",
    [4] = "<color=#ffc4f6>珍奇</color>",
    [5] = "<color=#ffcf65>稀世</color>",
}

function UIAutoFeedView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:InitAutoFeedInfo()
    self:InitPageView()
    self:UpdateInfo()
end

function UIAutoFeedView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIAutoFeedView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.TogSettingsMultipleChoice, EventType.OnSelectChanged, function ()
        self:UpdateInfo()
    end)

    UIHelper.BindUIEvent(self.ToggleHideNpc, EventType.OnSelectChanged, function (_, bSelected)
        self.bAutoFeed = bSelected
    end)

    UIHelper.BindUIEvent(self.TogTypeBind, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected then
            self.bBindLimit = true
        end
    end)

    UIHelper.BindUIEvent(self.TogTypeUnBind, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected then
            self.bBindLimit = false
        end
    end)

    UIHelper.BindUIEvent(self.BtnCalloff, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnDes, EventType.OnClick, function ()
        TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetPublicLabelTips, self.BtnDes, g_tStrings.STR_AUTO_FEED_TIPS)
    end)

    UIHelper.BindUIEvent(self.BtnOk, EventType.OnClick, function ()
        Storage.HorseFeed.tBanFeedItem = self.tBanFeedItem
        Storage.HorseFeed.bAutoFeed = self.bAutoFeed
        Storage.HorseFeed.nQuality = self.nQuality
        Storage.HorseFeed.nPercent = UIHelper.GetProgressBarPercent(self.SliderVolumeAdjustment) / 100
        Storage.HorseFeed.bBindLimit = self.bBindLimit

        Storage.HorseFeed.Flush()
        UIMgr.Close(self)
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function()
        if UIHelper.GetSelected(self.TogSettingsMultipleChoice) then
            UIHelper.SetSelected(self.TogSettingsMultipleChoice, false)
        end
    end)

    UIHelper.BindUIEvent(self.SliderVolumeAdjustment, EventType.OnChangeSliderPercent, function(SliderEventType, nSliderEvent)
        local nPercent = UIHelper.GetProgressBarPercent(self.SliderVolumeAdjustment)
        UIHelper.SetString(self.LabelVolumeNum, nPercent .. "%")
        UIHelper.SetProgressBarPercent(self.BarVolumeAdjustment, nPercent)
    end)
end

function UIAutoFeedView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIAutoFeedView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIAutoFeedView:InitAutoFeedInfo()
    self.tBanFeedItem = {}
    if table_is_empty(Storage.HorseFeed.tBanFeedItem) then
        for _, v in ipairs(HorseMgr.tForage) do
            HorseMgr.tForage_KV[v.dwIndex] = true
            if v.bDefaultBan then
                self.tBanFeedItem[v.dwIndex] = true
            end
        end
    else
        self.tBanFeedItem = Storage.HorseFeed.tBanFeedItem
    end

    self.bAutoFeed = Storage.HorseFeed.bAutoFeed
    self.nQuality = Storage.HorseFeed.nQuality
    self.nPercent = Storage.HorseFeed.nPercent
    self.bBindLimit = Storage.HorseFeed.bBindLimit
end

function UIAutoFeedView:InitPageView()
    UIHelper.SetSelected(self.ToggleHideNpc, self.bAutoFeed)
    UIHelper.SetProgressBarPercent(self.SliderVolumeAdjustment, self.nPercent * 100)
    UIHelper.SetProgressBarPercent(self.BarVolumeAdjustment, self.nPercent * 100)
    UIHelper.SetString(self.LabelVolumeNum, self.nPercent * 100 .. "%")
    UIHelper.SetRichText(self.RichTextSettingsMultipleChoice, tQuality[self.nQuality])

    if self.bBindLimit then
        UIHelper.SetSelected(self.TogTypeBind, true)
    else
        UIHelper.SetSelected(self.TogTypeUnBind, true)
    end

    UIHelper.RemoveAllChildren(self.Layout3)
    for k, v in ipairs(HorseMgr.tForage) do
        local KItemInfo = ItemData.GetItemInfo(v.dwTabType, v.dwIndex)
        local szOption = UIHelper.GBKToUTF8(KItemInfo.szName)
        if KItemInfo.nBindType == 3 then
            szOption = szOption .. "·绑"
        end
        local ItemCellScript = UIHelper.AddPrefab(PREFAB_ID.WidgetAutoFeedItemCell, self.Layout3, szOption, self.tBanFeedItem[v.dwIndex])
        if ItemCellScript then
            UIHelper.SetSwallowTouches(ItemCellScript.TogType, false)
            local ItemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_44, ItemCellScript.WidgetItem44)
            if ItemScript then
                ItemScript:OnInitWithTabID(v.dwTabType, v.dwIndex)
                ItemScript:SetClickCallback(function ()
                    if UIHelper.GetSelected(ItemScript.ToggleSelect) then
                        UIHelper.SetSelected(ItemScript.ToggleSelect, false)
                    end
                    TipsHelper.ShowItemTips(nil, v.dwTabType, v.dwIndex)
                end)
                UIHelper.SetTouchEnabled(ItemScript.ToggleSelect, false)
                UIHelper.SetSwallowTouches(ItemScript.ToggleSelect, false)
            end

            -- UIHelper.SetString(ItemCellScript.LabelAllSuit, szOption, 7)
            UIHelper.BindUIEvent(ItemCellScript.TogType, EventType.OnClick, function ()
                self.tBanFeedItem[v.dwIndex] = UIHelper.GetSelected(ItemCellScript.TogType)
            end)
        end
    end

    UIHelper.LayoutDoLayout(self.Layout3)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewBasicContent)
end

function UIAutoFeedView:UpdateInfo()
    UIHelper.RemoveAllChildren(self.LayoutMultipleChoice)

    for k, v in ipairs(tQuality) do
        local TogTypeScript = UIHelper.AddPrefab(PREFAB_ID.WidgetTogTypeSingle_RichText, self.LayoutMultipleChoice)
        if TogTypeScript then
            if self.nQuality == k then
                UIHelper.SetSelected(TogTypeScript.TogType, true)
            end
            UIHelper.SetRichText(TogTypeScript.LabelQuality, v)
            UIHelper.BindUIEvent(TogTypeScript.TogType, EventType.OnClick, function ()
                self.nQuality = k
                UIHelper.SetRichText(self.RichTextSettingsMultipleChoice, tQuality[self.nQuality])
            end)
        end
    end

    UIHelper.LayoutDoLayout(self.LayoutMultipleChoice)
end


return UIAutoFeedView
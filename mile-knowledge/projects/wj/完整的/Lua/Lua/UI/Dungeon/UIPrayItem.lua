local UIPrayItem = class("UIPrayItem")

function UIPrayItem:OnEnter(tWishItem, fCallBack)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tWishItem = tWishItem
    self.fCallBack = fCallBack
    self.bLongType = self.LabelWishItemName ~= nil
    self:UpdateInfo()
end

function UIPrayItem:OnExit()
    self.bInit = false
end

function UIPrayItem:BindUIEvent()
    UIHelper.BindUIEvent(self.ToggleSelect, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected and self.fCallBack then self.fCallBack() end
    end)
end

function UIPrayItem:RegEvent()
    Event.Reg(self, EventType.OnHoverTipsDeleted, function ()
        UIHelper.SetSelected(self.scriptItem.ToggleSelect, false, false)
    end)
end

function UIPrayItem:UpdateInfo()
    local tWishItem = self.tWishItem
    local tCollectList = GDAPI_GetSpecialWishCollectList()

    self.scriptItem = self.scriptItem or UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.WidgetItem_80)
    self.scriptItem:OnInitWithTabID(tWishItem.dwTabType, tWishItem.dwIndex)
    self.scriptItem:SetSelectChangeCallback(function(nItemID, bSelected, nTabType, nTabID)
        if bSelected then
            local tips, scriptTip = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetItemTip, self.WidgetItem_80, TipsLayoutDir.LEFT_CENTER)
            local tbFunctions = {}
            if OutFitPreviewData.CanPreview(nTabType, nTabID) then
                tbFunctions = OutFitPreviewData.SetPreviewBtn(nTabType, nTabID)
            end
            
            if not table.contain_value(tCollectList, tWishItem.dwID) then
                table.insert(tbFunctions, {
                    szName = "收藏",
                    OnClick = function()
                        DungeonData.DoCollectItem(tWishItem.dwID, true)
                        TipsHelper.DeleteAllHoverTips()
                    end
                })
            else
                table.insert(tbFunctions, {
                    szName = "取消收藏",
                    OnClick = function()
                        DungeonData.DoCollectItem(tWishItem.dwID, false)
                        TipsHelper.DeleteAllHoverTips()
                    end
                })
            end
            scriptTip:SetFunctionButtons(tbFunctions)
            scriptTip:OnInitWithTabID(tWishItem.dwTabType, tWishItem.dwIndex)
        end
    end)
    
    UIHelper.SetToggleGroupIndex(self.scriptItem.ToggleSelect, ToggleGroupIndex.WishItemList)
    UIHelper.SetSwallowTouches(self.scriptItem.ToggleSelect, false)
    UIHelper.SetCanSelect(self.scriptItem.ToggleSelect, self.bLongType, nil, false)

    UIHelper.SetVisible(self.ImgItemTip, DungeonData.IsWishItem(tWishItem.dwID))    
    UIHelper.SetVisible(self.ImgItemlike, table.contain_value(tCollectList, tWishItem.dwID))

    -- 维护长类型预制
    if self.bLongType then
        local tItemInfo = GetItemInfo(tWishItem.dwTabType, tWishItem.dwIndex)
        local szItemName = ItemData.GetItemNameByItemInfo(tItemInfo)
        szItemName = UIHelper.GBKToUTF8(szItemName)

        local szDesc = UIHelper.GBKToUTF8(tWishItem.szTips)
        local szCollected = "未收集"
        if DungeonData.GetWishItemCollectState(tWishItem) then szCollected = "已收集" end
        szCollected = string.format("<color=#d7f6ff>%s</color>", szCollected)

        local szColorWhite = "D7F6FF"
        local szColorRed = "FF8288"
        local szColor = szColorWhite
        if DungeonData.tWishInfo.nWishCoin < tWishItem.nCostWish then szColor = szColorRed end

        UIHelper.SetString(self.LabelWishItemName, szItemName)
        UIHelper.SetString(self.LabelWishItemDesc, szDesc)
        UIHelper.SetRichText(self.RichTextPrayerValue, string.format("<color=#%s>%d </color><color=#d7f6ff>祈愿值</color>", szColor, tWishItem.nCostWish))
        UIHelper.SetRichText(self.RichTextPrayerStatus, szCollected)
    end
end

return UIPrayItem
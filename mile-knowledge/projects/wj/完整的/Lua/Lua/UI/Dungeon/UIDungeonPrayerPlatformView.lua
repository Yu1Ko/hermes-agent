local UIDungeonPrayerPlatformView = class("UIDungeonPrayerPlatformView")

local CATEGORY_STRING_MAP = {
    "全部","背部挂件","腰部挂件","面部挂件","头饰","眼饰","手饰","外观","披风","特效称号","宠物","坐骑","奇趣坐骑","马具","玩具","其他"
}

local function GetCategoryByID(nIndex)
    local szName = FilterDef.WishItem[1].tbList[nIndex]
    for nID, szKey in ipairs(CATEGORY_STRING_MAP) do
        if szKey == szName then return nID - 1 end
    end

    return 0
end 

function UIDungeonPrayerPlatformView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    FilterDef.WishItem.Reset()
    self:InitView()
    self:UpdateInfo()
end

function UIDungeonPrayerPlatformView:OnExit()
    self.bInit = false
end

function UIDungeonPrayerPlatformView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnWish, EventType.OnClick, function ()
        self:DoWishItem()
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function ()
        self:DoCancelWish()
    end)

    UIHelper.BindUIEvent(self.BtnJump, EventType.OnClick, function ()
        self:DoOpenDungeon()
    end)

    UIHelper.BindUIEvent(self.BtnScreen, EventType.OnClick, function ()
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.BtnScreen, TipsLayoutDir.BOTTOM_CENTER, FilterDef.WishItem)
    end)

    UIHelper.BindUIEvent(self.BtnPrayerMore, EventType.OnClick, function ()
        UIMgr.OpenSingle(true, VIEW_ID.PanelBenefits, 2, true)
    end)

    UIHelper.BindUIEvent(self.BtnItemEmpty, EventType.OnClick, function ()
        self:SwitchItemListMode(false)
    end)

    UIHelper.BindUIEvent(self.BtnSwitchToLong, EventType.OnClick, function ()
        self:SwitchItemListMode(false)
    end)

    UIHelper.BindUIEvent(self.BtnSwitchToShort, EventType.OnClick, function ()
        self:SwitchItemListMode(true)
    end)

    UIHelper.RegisterEditBoxEnded(self.EditBoxSearch, function ()
        local szOldKey = self.szSearchkey
        self.szSearchkey = UIHelper.GetText(self.EditBoxSearch) or ""

        if szOldKey == self.szSearchkey then return end
        self:UpdateWishItemList()
    end)

    UIHelper.TableView_addCellAtIndexCallback(self.TableViewSingleItemList, function (tableView, nIndex, script, node, cell)
        self:UpdateSingleItem(nIndex, script)
        self.tShortScriptCellList[nIndex] = script
    end)

    UIHelper.TableView_addCellAtIndexCallback(self.TableViewDoubleItemList, function (tableView, nIndex, script, node, cell)
        self:UpdateSingleItem(nIndex, script)
        self.tLongScriptCellList[nIndex] = script
    end)
end

function UIDungeonPrayerPlatformView:RegEvent()
    Event.Reg(self, EventType.OnFilter, function(szKey, tSelected)
        if szKey ~= FilterDef.WishItem.Key then
            return
        end

        self.nCategory = GetCategoryByID(tSelected[1][1])
        self.nCanWishFlag = tSelected[2][1] - 1
        self:UpdateWishItemList()
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function()
        UIHelper.SetVisible(self.WidgetAnchorLeaveFor, false)
    end)

    Event.Reg(self, EventType.OnHoverTipsDeleted, function ()
        UIHelper.SetSelected(self.scriptItem.ToggleSelect, false, false)
    end)

    Event.Reg(self, "UPDATE_WISH_ITEM", function()
        self:InitView()
        self:UpdateInfo()
    end)

    Event.Reg(self, "On_UpdateFinishWishPanel", function()
        self:InitView()
        self:UpdateInfo()
    end)
    
    Event.Reg(self, "UPDATE_WISH_COLLECT_ITEM_LIST", function()
        self:UpdateInfo()
    end)
end

function UIDungeonPrayerPlatformView:InitView()
    local tSelected = FilterDef.WishItem.GetRunTime()
    if not tSelected then tSelected = {{1},{1}} end

    self.nCategory = GetCategoryByID(tSelected[1][1])
    self.nCanWishFlag = tSelected[2][1] - 1
    self.nCurIndex = 0
    self.tShortScriptCellList = {}
    self.tLongScriptCellList = {}

    DungeonData.tWishInfo = GDAPI_GetSpecialWishInfo()   

    self.tCollectMap = {}
    local tItem = {}
    local tAllItem = Table_GetWishItemInfoList()
    for dwID, tLine in pairs(tAllItem) do
        if not tItem[tLine.nCategory] then
            tItem[tLine.nCategory] = {}
        end
        
        local bCollect = DungeonData.GetWishItemCollectState(tLine)
        self.tCollectMap[tLine.dwID] = bCollect
        table.insert(tItem[tLine.nCategory], tLine)
    end
    DungeonData.tAllItemInfo = tAllItem
    DungeonData.tMapItemList = tItem

    FilterDef.WishItem[1].tbList = {"全部"}
    for nIndex, szName in ipairs(CATEGORY_STRING_MAP) do
        if tItem[nIndex-1] then
            table.insert(FilterDef.WishItem[1].tbList, szName)
        end
    end

    UIHelper.SetSwallowTouches(self.BtnMask, true)
    UIHelper.SetSwallowTouches(self.BtnRightTopSingleItemListMask, true)
    --UIHelper.SetProgressBarStarPercentPt(self.ImgSliderExperience, 0.5, 0)
    UIHelper.SetProgressBarPercent(self.ImgSliderExperience, 0)

    UIHelper.SetVisible(self.WidgetAnchorLeaveFor, false)
end

function UIDungeonPrayerPlatformView:UpdateInfo()
    self:UpdateWishItemList()
end

function UIDungeonPrayerPlatformView:UpdateWishItemList()
    local tItemList = DungeonData.GetWishItemListByCategory(self.nCategory, self.nCanWishFlag)

    if self.szSearchkey ~= nil and #self.szSearchkey > 0 then
        local tSearchList = {}
        for _, tWishItem in pairs(tItemList) do
            local tItemInfo = GetItemInfo(tWishItem.dwTabType, tWishItem.dwIndex)
            local szItemName = ItemData.GetItemNameByItemInfo(tItemInfo)
            szItemName = UIHelper.GBKToUTF8(szItemName)

            if MonsterBookData.MatchString(szItemName, self.szSearchkey) then
                table.insert(tSearchList, tWishItem)
            end
        end
        tItemList = tSearchList
    end

    local tCollectList = GDAPI_GetSpecialWishCollectList()
    local fnSort = function(L, R)
        if not table.contain_value(tCollectList, L.dwID) ~= not table.contain_value(tCollectList, R.dwID) then
            return table.contain_value(tCollectList, L.dwID)
        elseif not self.tCollectMap[L.dwID] ~= not self.tCollectMap[R.dwID] then
            return not self.tCollectMap[L.dwID]
        elseif L.nPriority ~= R.nPriority then
            return L.nPriority > R.nPriority
        elseif not self:CheckWishItem(L) ~= not self:CheckWishItem(R) then
            return self:CheckWishItem(L)
        elseif L.nCostWish ~= R.nCostWish then
            return L.nCostWish > R.nCostWish
        else
            return L.dwID > R.dwID
        end
    end

    table.sort(tItemList, fnSort)
    self.tSortedItemList = tItemList

    self:UdpateWishItemDetail()

    UIHelper.TableView_init(self.TableViewSingleItemList, #self.tSortedItemList, PREFAB_ID.WidgetPrayItem)
    UIHelper.TableView_init(self.TableViewDoubleItemList, #self.tSortedItemList, PREFAB_ID.WidgetPrayItemLong)

    UIHelper.TableView_reloadData(self.TableViewSingleItemList)
    UIHelper.TableView_reloadData(self.TableViewDoubleItemList)

    Timer.AddFrame(self, 10, function ()
        self:RedirectToCurItem()
    end)
end

function UIDungeonPrayerPlatformView:UdpateWishItemDetail()
    local szItemName = "祈愿物品"
    
    UIHelper.RemoveAllChildren(self.WidgetItem_80)
    local nTargetID = self.nCurIndex and self.nCurIndex
    if DungeonData.tWishInfo and DungeonData.tWishInfo.nWishIndex > 0 then nTargetID = DungeonData.tWishInfo.nWishIndex end

    if nTargetID and nTargetID > 0 then
        local tWishItem = Table_GetWishItemInfoByID(nTargetID)
        if tWishItem then
            local tCollectList = GDAPI_GetSpecialWishCollectList()
            local tItemInfo = GetItemInfo(tWishItem.dwTabType, tWishItem.dwIndex)
            szItemName = ItemData.GetItemNameByItemInfo(tItemInfo)
            szItemName = UIHelper.GBKToUTF8(szItemName)
        
            self.scriptItem = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.WidgetItem_80)
            
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
                            end
                        })
                    else
                        table.insert(tbFunctions, {
                            szName = "取消收藏",
                            OnClick = function()
                                DungeonData.DoCollectItem(tWishItem.dwID, false)
                            end
                        })
                    end
                    scriptTip:SetFunctionButtons(tbFunctions)
                    scriptTip:OnInitWithTabID(tWishItem.dwTabType, tWishItem.dwIndex)
                end
            end)
        end
    end

    UIHelper.SetString(self.LabelWishItemName, szItemName)

    self:RefreshButtons()
end

function UIDungeonPrayerPlatformView:UpdateSingleItem(nIndex, scriptCell)
    local tWishItem = self.tSortedItemList[nIndex]
    scriptCell:OnEnter(tWishItem, function ()
        self.nCurIndex = tWishItem.dwID
        if not UIHelper.GetVisible(self.WidgetSingleItemList) then UIHelper.TableView_scrollToCellFitTop(self.TableViewSingleItemList, #self.tSortedItemList, nIndex) end
        if not UIHelper.GetVisible(self.WidgetDoubleItemList) then UIHelper.TableView_scrollToCellFitTop(self.TableViewDoubleItemList, #self.tSortedItemList, nIndex) end
        
        self:SwitchItemListMode(false)
        self:UdpateWishItemDetail()

        self:RefreshAllVisiableCells(self.tShortScriptCellList)
        self:RefreshAllVisiableCells(self.tLongScriptCellList)
    end)

    if DungeonData.tWishInfo.nWishIndex > 0 then
        UIHelper.SetSelected(scriptCell.ToggleSelect, false, false)
    elseif self.nCurIndex and self.nCurIndex > 0 then
        UIHelper.SetSelected(scriptCell.ToggleSelect, self.nCurIndex == tWishItem.dwID, false)
    end
    UIHelper.SetCanSelect(scriptCell.ToggleSelect, DungeonData.tWishInfo.nWishIndex == 0, "同一时间只能祈愿一个目标", false)
end

function UIDungeonPrayerPlatformView:CheckWishItem(tWishItem)
    return not self.tCollectMap[tWishItem.dwID] and DungeonData.tWishInfo.nWishCoin >= tWishItem.nCostWish
end

function UIDungeonPrayerPlatformView:RefreshButtons()
    local tInfo = GDAPI_GetSpecialWishInfo()
    DungeonData.tWishInfo = tInfo

    local szMessage = string.format("<color=#d7f6ff>已获得</color><color=#ffea88>%.f%%</color><color=#d7f6ff>概率提升\n(再击败对应首领</color><color=#ffea88>%d次</color><color=#d7f6ff>以内必得</color>）", tInfo.nWishProbability*100, tInfo.nRemainTryCount)
    local nPercent = tInfo.nWishCoin/tInfo.nMaxWishCoinLimit
    
    if tInfo.nWishIndex == 0 or self.nCurIndex ~= 0 then
        local tWishItem = Table_GetWishItemInfoByID(self.nCurIndex)
        if tWishItem then
            local szColorWhite = "FFEA88"
            local szColorRed = "FF8288"
            local szColor = szColorWhite
            local bNeedMoreWishCoin = DungeonData.tWishInfo.nWishCoin < tWishItem.nCostWish
            if bNeedMoreWishCoin then szColor = szColorRed end

            szMessage = string.format("<color=#d7f6ff>消耗</color><color=#%s> %d </color><color=#d7f6ff>祈愿值，\n获得个人掉落概率提升和保底机制</color>", szColor, tWishItem.nCostWish)
            if self.tCollectMap[tWishItem.dwID] then
                UIHelper.SetButtonState(self.BtnWish, BTN_STATE.Disable, "当前物品已收集")
            elseif bNeedMoreWishCoin then
                UIHelper.SetButtonState(self.BtnWish, BTN_STATE.Disable, "祈愿值不足")
            else
                UIHelper.SetButtonState(self.BtnWish, BTN_STATE.Normal)
            end
        end
    end

    UIHelper.SetString(self.LabelPrayerValueLimit, string.format("本周还可获得祈愿值：%d", tInfo.nWeeklyRemainLimit))
    UIHelper.SetString(self.LabelCurPrayerValue, string.format("当前祈愿值：%d/%d", tInfo.nWishCoin, tInfo.nMaxWishCoinLimit))
    UIHelper.SetRichText(self.RichTextPrayerMessage, szMessage)
    UIHelper.SetProgressBarPercent(self.ImgSliderExperience, nPercent * 100)

    UIHelper.SetVisible(self.BtnWish, tInfo.nWishIndex == 0 and self.nCurIndex > 0)
    UIHelper.SetVisible(self.BtnCancel, tInfo.nWishIndex ~= 0)
    UIHelper.SetVisible(self.BtnJump, tInfo.nWishIndex ~= 0)
    UIHelper.SetVisible(self.RichTextPrayerMessage, tInfo.nWishIndex ~= 0 or self.nCurIndex ~= 0)
    UIHelper.SetVisible(self.Eff_QiYuanChengGong, tInfo.nWishIndex ~= 0)

    local bIsDefaultFilter = self:IsDefaultFilter()
    UIHelper.SetVisible(self.ImgScreen, bIsDefaultFilter)
    UIHelper.SetVisible(self.ImgScreen_ing, not bIsDefaultFilter)

    UIHelper.LayoutDoLayout(self.LayoutBottomBtnList)
end

function UIDungeonPrayerPlatformView:RefreshAllVisiableCells(tScriptCellList)
    for _, scriptCell in pairs(tScriptCellList) do
        if DungeonData.tWishInfo.nWishIndex > 0 then
            UIHelper.SetSelected(scriptCell.ToggleSelect, false, false)
        elseif self.nCurIndex and self.nCurIndex > 0 then
            UIHelper.SetSelected(scriptCell.ToggleSelect, self.nCurIndex == scriptCell.tWishItem.dwID, false)
        end
    end
end

function UIDungeonPrayerPlatformView:RedirectToCurItem()
    local nTargetID = self.nCurIndex and self.nCurIndex
    if DungeonData.tWishInfo and DungeonData.tWishInfo.nWishIndex > 0 then nTargetID = DungeonData.tWishInfo.nWishIndex end

    if nTargetID and nTargetID > 0 then
        local _, nIndex = table.find_if(self.tSortedItemList, function (tWishItem)
            return tWishItem.dwID == nTargetID
        end)
        if nIndex then
            UIHelper.TableView_scrollToCellFitTop(self.TableViewSingleItemList, #self.tSortedItemList, nIndex)
            UIHelper.TableView_scrollToCellFitTop(self.TableViewDoubleItemList, #self.tSortedItemList, nIndex)
        end
    end
end

function UIDungeonPrayerPlatformView:SwitchItemListMode(bFold)
    UIHelper.SetVisible(self.WidgetSingleItemList, bFold)
    UIHelper.SetVisible(self.WidgetDoubleItemList, not bFold)

    UIHelper.SetVisible(self.BtnPrayerMore, bFold)
    UIHelper.SetVisible(self.LabelPrayerValueLimit, bFold)
    UIHelper.SetVisible(self.ImgBtnCloseLine, bFold)
end

function UIDungeonPrayerPlatformView:DoWishItem()
    if self.nCurIndex and self.nCurIndex > 0 then
        local tWishItem = Table_GetWishItemInfoByID(self.nCurIndex)
        if tWishItem then
            local tItemInfo = GetItemInfo(tWishItem.dwTabType, tWishItem.dwIndex)
            local szItemName = ItemData.GetItemNameByItemInfo(tItemInfo)
            szItemName = UIHelper.GBKToUTF8(szItemName)

            local szMessage = string.format(g_tStrings.Dungeon.STR_WISH_SPECIAL_ITEM, tWishItem.nCostWish, szItemName)
            UIHelper.ShowConfirm(szMessage, function ()
                RemoteCallToServer("On_SpecialWish_Wish", tWishItem.dwID, tWishItem.dwTabType, tWishItem.dwIndex, tWishItem.nCostWish)
                UIHelper.SetVisible(self.Eff_DingXiangQiYuan, true)
            end)
        end
    end    
end

function UIDungeonPrayerPlatformView:DoCancelWish()
    if DungeonData.tWishInfo.nWishIndex == 0 then return end
    local tWishItem = Table_GetWishItemInfoByID(DungeonData.tWishInfo.nWishIndex)
    if not tWishItem then return end

    local nTryCount = DungeonData.MAX_WISH_ITEM_RETRY_COUNT
    local nRemainTry = DungeonData.tWishInfo.nRemainTryCount
    if DungeonData.tWishInfo.nVersion and DungeonData.tWishInfo.nVersion == 0 then
        OutputMessage("MSG_SYS", "2025年10月30日7:00前定向的祈愿将按照保底20次计算返还值\n")
        OutputMessage("MSG_ANNOUNCE_YELLOW", "2025年10月30日7:00前定向的祈愿将按照保底20次计算返还值")
        nTryCount = DungeonData.MAX_WISH_ITEM_RETRY_COUNT_OLD_VERSION
        nRemainTry = DungeonData.MAX_WISH_ITEM_RETRY_COUNT_OLD_VERSION - DungeonData.tWishInfo.nTryCount
    end
    local nWishCoinIfCancel = math.floor(tWishItem.nCostWish * nRemainTry / nTryCount / 10) * 10
    local szMessage = string.format(g_tStrings.Dungeon.STR_WISH_CANCEL_ITEM, nWishCoinIfCancel)
    local scriptConfirm = UIHelper.ShowConfirm(szMessage, function ()
        RemoteCallToServer("On_SpecialWish_CancelWish", DungeonData.tWishInfo.nWishIndex)
    end)
    scriptConfirm:SetButtonCountDown(5)
end

function UIDungeonPrayerPlatformView:DoOpenDungeon()
    local tSource = DungeonData.GetWishItemSourceList()
    if #tSource == 0 then return end

    if #tSource > 1 then
        local tbInfoList = {}
        local tMarkMap = {}
        for _, tData in ipairs(tSource) do
            local dwMapID = tData[1]
            if not tMarkMap[dwMapID] then
                tMarkMap[dwMapID] = true
                local szMapName = Table_GetMapName(dwMapID)
                szMapName = UIHelper.GBKToUTF8(szMapName)
                table.insert(tbInfoList, {
                    szName = szMapName,
                    OnClick = function()
                        UIMgr.OpenSingle(true, VIEW_ID.PanelDungeonEntrance, {dwTargetMapID = dwMapID})
                    end,
                })
            end
        end
        UIHelper.SetVisible(self.WidgetAnchorLeaveFor, true)
    
        local scriptTravelView = UIHelper.GetBindScript(self.WidgetAnchorLeaveFor)
        scriptTravelView:UpdateByFunc(tbInfoList, 6)
    else
        UIMgr.OpenSingle(true, VIEW_ID.PanelDungeonEntrance, {dwTargetMapID = tSource[1][1]})
    end
end

function UIDungeonPrayerPlatformView:IsDefaultFilter()
    return self.nCategory == 0 and self.nCanWishFlag == 0
end

return UIDungeonPrayerPlatformView
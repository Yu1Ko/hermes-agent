local UIWidgetRefineUpgrade = class("UIWidgetRefineUpgrade")

local MAX_MATERIAL_NUM = 16
local MILLION_NUMBER = 1048576 --百分率基数

local PANEL_TYPE = {
    NORMAL = 1,
    COLOR = 2,
    FAST = 3
}

local szGreen = "#95FF95"
local szYellow = "#FFE26E"

function UIWidgetRefineUpgrade:OnEnter()
    if not self.bInit then
        JX_RefineDiamond.Init()

        self.LeftBagScript = UIMgr.AddPrefab(PREFAB_ID.WidgetRefineBag, self._rootNode) ---@type UICharacterLeftBag

        self.totalChosenMaterialNum = 0
        self.chosenMaterialCountDict = {}
        self.chosenMaterialList = {}
        self.selectedMaterialCellScript = {}

        self.nPanelType = PANEL_TYPE.NORMAL
        self.chosenItem = nil
        self:RegEvent()

        self.bInit = true

        self.bSplitStage = false

        self.minSize = 1
        self.nQRAmount = 1

        local togList = { self.TogTabMaterial, self.TogTabColor, self.TogTabWuXingFast }
        local typeList = { PANEL_TYPE.NORMAL, PANEL_TYPE.COLOR, PANEL_TYPE.FAST }
        for i = 1, #togList do
            local tog = togList[i]
            UIHelper.ToggleGroupAddToggle(self.ToggleGroupTab, tog)
            UIHelper.BindUIEvent(tog, EventType.OnSelectChanged, function(toggle, bSelected)
                if bSelected then
                    self.nPanelType = typeList[i]
                    self:ClearData()
                    self:UpdateInfo()
                end
            end)
            if self.nPanelType == typeList[i] then
                Timer.AddFrame(self,1,function()
                    UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroupTab, tog)
                end)
            end
        end

        local compLuaBind = self.UIFastPanel:getComponent("LuaBind")
        self.fastPanelScript = compLuaBind and compLuaBind:getScriptObject() ---@type UIWidgetFastRefine
        self.fastPanelScript:SetParentScript(self)

        self.refineResultScripts = {} ---@type UIWidgetRefineInfoCell[]
        for i = 1, 2 do
            local itemScript = UIHelper.GetBindScript(self.tResultItems[i])
            UIHelper.SetVisible(itemScript._rootNode, false)
            self.refineResultScripts[i] = itemScript
        end

        for i = 1, MAX_MATERIAL_NUM, 1 do
            local slotType = EQUIP_REFINE_SLOT_TYPE.ADD_MATERIAL
            local itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetRefineMaterial_80, self.LayoutProductPreview, slotType)
            self.selectedMaterialCellScript[i] = itemScript
        end
        UIHelper.LayoutDoLayout(self.LayoutProductPreview)

        self.itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetRefineMaterial_80, self.WidgetItemGem) ---@type UICharacterRefineMaterialCell
        self.itemScript:BindCancelFunc(function()
            if self.chosenItem then
                self.LeftBagScript:CloseLeftPanel()
                self:MergeItem()
                self:ClearData()
                self:UpdateInfo()
                JX_RefineDiamond.StopRefine()
            end
        end)
        self:BindUIEvent()

        self:RefreshProgressBarPercent()
        self:UpdateInfo()
    end
    UIHelper.SetVisible(self.WidgetAnchorMaterial, false)

    UIHelper.SetTouchDownHideTips(self.ScrollViewStoneList, false)
    UIHelper.SetTouchDownHideTips(self.BtnCleanUp, false)

    UIHelper.SetSelected(self.TogAutoUpgrade, JX_RefineDiamond.bAutoContinue)
end

function UIWidgetRefineUpgrade:OnExit()
    self.bInit = false

    self.LeftBagScript:CloseLeftPanel()

    self:MergeItem()
    Event.UnRegAll(self)
    JX_RefineDiamond.StopRefine()
    JX_RefineDiamond.UnInit()
end

function UIWidgetRefineUpgrade:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnEmptyMaterial, EventType.OnClick, function()
        self:OpenBothStonePanel()
    end)
    self.itemScript:BindAddFunc(function()
        self:OpenBothStonePanel()
    end)

    UIHelper.BindUIEvent(self.BtnCleanUp, EventType.OnClick, function()
        local nCount, aMaterial = self:GetRefineExpendMaterial()
        if nCount > 0 then
            self:ClearRefineExpend()
            self:UpdateInfo()
        end
    end)

    UIHelper.BindUIEvent(self.BtnRefine, EventType.OnClick, function()
        self:StartRefine()
    end)

    UIHelper.BindUIEvent(self.BtnAddAmountScript, EventType.OnClick, function()
        self:AdjustRefineAmount(1)
    end)

    UIHelper.BindUIEvent(self.BtnSubAmountScript, EventType.OnClick, function()
        self:AdjustRefineAmount(-1)
    end)

    UIHelper.BindUIEvent(self.SliderScriptNum, EventType.OnChangeSliderPercent, function(SliderEventType, nSliderEvent)
        if nSliderEvent == ccui.SliderEventType.slideBallDown then
            self.bSliding = true
        elseif nSliderEvent == ccui.SliderEventType.slideBallUp then
            self.bSliding = false
            self:RefreshProgressBarPercent() -- 强制修正滑块进度
        end

        if self.bSliding then
            local percent = UIHelper.GetProgressBarPercent(self.SliderScriptNum) / 100
            local maxAmount = self:GetMaxAmount()

            self.nQRAmount = self.minSize + math.floor(percent * (maxAmount - self.minSize))

            self.nQRAmount = self.nQRAmount < 1 and 1 or self.nQRAmount
            self.nQRAmount = self.nQRAmount > maxAmount and maxAmount or self.nQRAmount

            UIHelper.SetProgressBarPercent(self.ProgressBarScriptNum, percent * 100)
            self:UpdateInfo()
        end
    end)

    UIHelper.BindUIEvent(self.TogAutoUpgrade, EventType.OnSelectChanged, function(toggle, bVal)
        JX_RefineDiamond.bAutoContinue = bVal
        self:UpdateRightPanel()
        self:RefreshProgressBarPercent()
    end)
end

function UIWidgetRefineUpgrade:RegEvent()
    Event.Reg(self, "BAG_ITEM_UPDATE", function(arg0, arg1, arg2)
        if arg0 == self.splitDwBox and arg1 == self.splitDwX and self.bSplitStage then
            self.bSplitStage = false
            self.LeftBagScript:UpdateMaterialList()
            self.LeftBagScript.chosenMaterialCountDict = self.chosenMaterialCountDict
            self.LeftBagScript:RefreshBagCell()
            self:UpdateInfo()
        end
    end)

    Event.Reg(self, "DIAMON_UPDATE", function(arg0, arg1, arg2)
        if arg0 == DIAMOND_RESULT_CODE.SUCCESS and JX_RefineDiamond.IsStop() then
            if self.splitDwBox and self.splitDwX > 0 then
                local KItem = ItemData.GetPlayerItem(g_pClientPlayer, self.splitDwBox, self.splitDwX)
                if KItem then
                    local dwIndex = KItem.dwIndex
                    if KItem.nDetail > self.nRefineLevel then
                        self:PlayRefineDuang(true)
                        --OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tDiamondResultCode[DIAMOND_RESULT_CODE.SUCCESS])
                    else
                        self:PlayRefineDuang(false)
                        --OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tDiamondResultCode[DIAMOND_RESULT_CODE.FAILED])
                    end

                    self.chosenItem = nil
                    self.LeftBagScript:UpdateMaterialList()
                    self:SelectMainStoneForRefine(dwIndex)
                    self:UpdateInfo()
                end
            end
        end

        if JX_RefineDiamond.bAutoContinue then
            local nCount, nTotal = JX_RefineDiamond.GetRefineCount()
            TipsHelper.ShowNormalTip(string.format("自动精炼进行中 %d/%d", nCount, nTotal + 1))
        end
    end)

    Event.Reg(self, "UPDATE_COLOR_DIAMOND_RESPOND", function(arg0)
        if arg0 == DIAMOND_RESULT_CODE.SUCCESS then
            if self.splitDwBox and self.splitDwX > 0 then
                local KItem = ItemData.GetPlayerItem(g_pClientPlayer, self.splitDwBox, self.splitDwX)
                if KItem then
                    local dwIndex = KItem.dwIndex
                    if KItem.nDetail > self.nRefineLevel then
                        --D.PlayCommonRefineDuang(true)
                        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tFEProduce.UPDATE_COLOE_DIAMOND_SUCCEED)
                    else
                        --D.PlayCommonRefineDuang(false)
                        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tFEProduce.UPADTE_COLOR_DIAMOND_FAILED)
                    end

                    self.chosenItem = nil
                    self.LeftBagScript:UpdateMaterialList()
                    self:SelectMainStoneForRefine(dwIndex)
                    self:UpdateInfo()
                end
            end
        else
            local szMsg = g_tStrings.tDiamondResultCode[arg0] or g_tStrings.tFEProduce.UPADTE_COLOR_DIAMOND_FAILED
            OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
        end
    end)
end

function UIWidgetRefineUpgrade:SelectMainStoneForRefine(dwIndex)
    self:MergeItem()
    self:ClearData()
    self.chosenItem = DataModel.GetFirstAvailableItemInList(dwIndex, self.chosenMaterialCountDict)
    self:SplitChosenItem() --特殊处理，因为端游脚本要求当前选择的精炼材料堆叠数为1，我们为此特别做一个拆分
    self.chosenMaterialCountDict[dwIndex] = 1
    Event.Dispatch(EventType.EquipRefineSelectChanged, dwIndex, 1)
    --print(self.splitDwBox, self.splitDwX)
    if self.splitDwBox == nil or self.splitDwX == nil then
        self:ClearData()
        self:UpdateInfo()
        return TipsHelper.ShowImportantRedTip("该操作需要材料在背包中单独放置在格子，请保证背包至少有一格空间")
    end
end

function UIWidgetRefineUpgrade:AddRefineStoneExpend(dwIndex)
    if self.totalChosenMaterialNum >= MAX_MATERIAL_NUM then
        return OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_REFINE_EXPEND_AMOUNT_REACH_UBOUND) and false
    end

    local itemCount = DataModel.GetItemCount(dwIndex)
    if itemCount and itemCount > 0 then
        local KItem = DataModel.GetFirstAvailableItemInList(dwIndex, self.chosenMaterialCountDict)
        if KItem then
            -- 边界处理
            if KItem.nGenre ~= ITEM_GENRE.COLOR_DIAMOND
                    and KItem.nGenre ~= ITEM_GENRE.DIAMOND then
                return OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_REFINE_EXPEND_ONLY_DIAMOND_OR_COLOR_DIAMOND) and
                        false
            end

            ------ 开始添加
            local nStackNum = 1
            self.chosenMaterialCountDict[dwIndex] = self.chosenMaterialCountDict[dwIndex] or 0
            self.chosenMaterialCountDict[dwIndex] = self.chosenMaterialCountDict[dwIndex] + nStackNum
            self.totalChosenMaterialNum = self.totalChosenMaterialNum + 1

            local nBox, nIndex = ItemData.GetItemPos(KItem.dwID)
            table.insert(self.chosenMaterialList, {
                dwBox = nBox,
                dwX = nIndex,
                nUiId = KItem.nUiId,
                nGenre = KItem.nGenre,
                dwTabType = KItem.dwTabType,
                dwIndex = KItem.dwIndex,
                nStackNum = nStackNum,
                bBind = KItem.bBind,
                nIcon = Table_GetItemIconID(KItem.nUiId),
            })

            Event.Dispatch(EventType.EquipRefineSelectChanged, dwIndex, 1)
            return true
        else
            return OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_REFINE_EXPEND_AMOUNT_REACH_UBOUND) and false
        end
    end
end

function UIWidgetRefineUpgrade:ClearRefineExpend()
    for i = #self.chosenMaterialList, 1, -1 do
        local dwIndex = self.chosenMaterialList[i].dwIndex
        self:_RemoveFromChosenListByIndex(i)
        Event.Dispatch(EventType.EquipRefineSelectChanged, dwIndex, -1)
    end
    self:RefreshProgressBarPercent()
end

function UIWidgetRefineUpgrade:_RemoveFromChosenListByIndex(index)
    if index == nil or index < 1 or index > #self.chosenMaterialList then
        LOG.ERROR("UICharacterWidgetEquipRefine:_RemoveFromChosenListByIndex index invalid")
        return
    end

    local itemInfo = self.chosenMaterialList[index]
    self.totalChosenMaterialNum = self.totalChosenMaterialNum - 1
    self.chosenMaterialCountDict[itemInfo.dwIndex] = self.chosenMaterialCountDict[itemInfo.dwIndex] - 1
    if self.chosenMaterialCountDict[itemInfo.dwIndex] == 0 then
        self.chosenMaterialCountDict[itemInfo.dwIndex] = nil
    end
    table.remove(self.chosenMaterialList, index)
end

function UIWidgetRefineUpgrade:UpdateChosenMaterialView()
    local bHasCell = false
    for i = 1, MAX_MATERIAL_NUM, 1 do
        local itemInfo = self.chosenMaterialList[i]
        local itemScript = self.selectedMaterialCellScript[i]

        if itemInfo then
            bHasCell = true
            local item = ItemData.GetItemByPos(itemInfo.dwBox, itemInfo.dwX)
            itemScript:RefreshInfo(EQUIP_REFINE_SLOT_TYPE.MATERIAL_CHOSEN, itemInfo.dwIndex, item.nUiId, item.nQuality, 1)
            itemScript:SetBind(item.bBind)

            UIHelper.BindUIEvent(itemScript.BtnRecall, EventType.OnClick, function()
                self:_RemoveFromChosenListByIndex(i)
                itemScript.chosenCount = 0
                Event.Dispatch(EventType.EquipRefineSelectChanged, itemInfo.dwIndex, -1)
                self:RefreshProgressBarPercent()
                self:UpdateInfo()
            end)
        else
            local slotType = EQUIP_REFINE_SLOT_TYPE.ADD_MATERIAL
            itemScript:RefreshInfo(slotType)

            if slotType == EQUIP_REFINE_SLOT_TYPE.ADD_MATERIAL then
                UIHelper.BindUIEvent(itemScript.BtnAdd, EventType.OnClick, function()
                    local fnAction = function(dwIndex)
                        self:AddRefineStoneExpend(dwIndex)
                        self:RefreshProgressBarPercent()
                        self:UpdateInfo()
                    end
                    if self.chosenItem == nil then
                        return OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_REFINE_CHOOSE_BEFORE_ADD)
                    else
                        local tabType = self.chosenItem.nGenre == ITEM_GENRE.DIAMOND and LeftTabType.WuXingStone
                                or LeftTabType.WuCaiStone
                        self:OpenLeftPanel(tabType, fnAction, self.chosenMaterialCountDict)
                    end
                end)
            end
        end
    end
    UIHelper.SetVisible(self.BtnCleanUp, bHasCell)
end

function UIWidgetRefineUpgrade:UpdateRightPanel()
    UIHelper.SetVisible(self.WidgetLimit, false)
    UIHelper.SetVisible(self.WidgetInfo, true)

    for i = 1, 2 do
        self.refineResultScripts[i]:SetVisible(false)
    end

    UIHelper.SetActiveAndCache(self, self.LayoutResource, false)
    UIHelper.SetRichText(self.RichTextSuccessRateNum, "0%")
    UIHelper.SetString(self.LabelScriptUpgradeNum, self.nQRAmount .. "次")

    local nCount, aMaterial = self:GetRefineExpendMaterial()
    local bHasItem = self.chosenItem and self.splitDwBox ~= nil and self.splitDwX ~= nil
    if bHasItem then
        local KItem = self.chosenItem
        local KItemInfo = GetItemInfo(KItem.dwTabType, KItem.dwIndex)

        local splitItem = ItemData.GetItemByPos(self.splitDwBox, self.splitDwX)
        --print(self.splitDwBox,self.splitDwX)
        local nLevel, bMaxLevel
        local dwBox, dwX = self.splitDwBox, self.splitDwX

        if splitItem.nGenre == ITEM_GENRE.DIAMOND then
            nLevel = self.chosenItem.nDetail
            bMaxLevel = nLevel >= DIAMOND_MAX_STRENGTHEN_LEVEL
        elseif splitItem.nGenre == ITEM_GENRE.COLOR_DIAMOND then
            nLevel = self.chosenItem.nDetail
            bMaxLevel = nLevel >= COLOR_DIAMOND_MAX_STRENGTHEN_LEVEL
            bMaxLevel = bMaxLevel or IsColorDiamondCanNotUp(KItem)
        end
        UIHelper.SetVisible(self.TogAutoUpgrade, splitItem.nGenre == ITEM_GENRE.DIAMOND) -- 五彩石无法配方升级

        local bCanProduce = false
        local nCostMoney, nCostVigor, nCostTrain = 0, 0, 0
        local nUpgradeTotalRate, nUpgradeOneLevelRate, nUpgradeTwoLevelRate = 0, 0, false
        if not bMaxLevel and #aMaterial > 0 then
            if splitItem.nGenre == ITEM_GENRE.DIAMOND then
                nUpgradeOneLevelRate, nUpgradeTwoLevelRate = select(2, GetDiamondUpdateRate(dwBox, dwX, aMaterial))
                bCanProduce, nCostMoney, nCostVigor = GetDiamondUpdateCost(dwBox, dwX, aMaterial)
                if nLevel >= DIAMOND_MAX_STRENGTHEN_LEVEL - 1 then
                    nUpgradeTwoLevelRate = nil
                end
            elseif splitItem.nGenre == ITEM_GENRE.COLOR_DIAMOND then
                bCanProduce, nCostVigor, nCostMoney, nUpgradeOneLevelRate, nUpgradeTwoLevelRate = GetUpdateColorDiamondInfo(dwBox, dwX, aMaterial)

                if bCanProduce then
                    nUpgradeOneLevelRate = math.min(nUpgradeOneLevelRate, 100) * MILLION_NUMBER / 100
                end
                if nUpgradeTwoLevelRate then
                    if KItem.nDetail >= COLOR_DIAMOND_MAX_STRENGTHEN_LEVEL - 1 then
                        nUpgradeOneLevelRate, nUpgradeTwoLevelRate = MILLION_NUMBER, nil
                    else
                        nUpgradeOneLevelRate, nUpgradeTwoLevelRate = MILLION_NUMBER - nUpgradeOneLevelRate,
                        nUpgradeOneLevelRate
                    end
                end
            end
        end

        if splitItem.nGenre == ITEM_GENRE.DIAMOND and JX_RefineDiamond.bAutoContinue then
            nCostMoney = nCostMoney * self.nQRAmount -- 五行石 配方时 计算金钱
            nCostVigor = nCostVigor * self.nQRAmount -- 五行石 配方时 计算金钱
        end

        nUpgradeTotalRate = ((nUpgradeOneLevelRate or 0) + (nUpgradeTwoLevelRate or 0)) / MILLION_NUMBER * 100
        local tEnough, szCannotProduce = PowerUpView.CheckRefineCost(nCostMoney, nCostVigor, nCostTrain)
        bCanProduce = bCanProduce and nCount > 0 and tEnough.Vigor and tEnough.Money and tEnough.Train

        --UIHelper.SetString(self.LabelGenerate, bMaxLevel and g_tStrings.STR_REFINE_ALREADY_MAXLEVEL or "有概率生成")
        if bMaxLevel then
            UIHelper.SetVisible(self.WidgetLimit, true)
            UIHelper.SetVisible(self.WidgetInfo, false)
        else
            local KItemInfoOne, KItemInfoTwo
            if splitItem.nGenre == ITEM_GENRE.DIAMOND then
                KItemInfoOne = GetDiamondInfo(nLevel + 1, false)
                KItemInfoTwo = GetDiamondInfo(nLevel + 2, false)
            elseif splitItem.nGenre == ITEM_GENRE.COLOR_DIAMOND then
                local oneLevelInfo = GetEnchantProduceItemInfo(KItemInfo.dwEnchantID)
                KItemInfoOne = ItemData.GetItemInfo(oneLevelInfo.dwTabType, oneLevelInfo.dwTabIndex)
                if KItemInfoOne and not IsColorDiamondCanNotUp(KItemInfoOne) then
                    local twoLevelInfo = GetEnchantProduceItemInfo(KItemInfoOne.dwEnchantID)
                    KItemInfoTwo = ItemData.GetItemInfo(twoLevelInfo.dwTabType, twoLevelInfo.dwTabIndex)
                    assert(KItemInfoTwo, "Item获取失败，请检查跳级Item类型和ID表单是否有误！("
                            .. oneLevelInfo.dwTabType .. "," .. oneLevelInfo.dwTabIndex .. " => "
                            .. twoLevelInfo.dwTabType .. "," .. twoLevelInfo.dwTabIndex .. ")")
                end
            end

            if nUpgradeTwoLevelRate and not KItemInfoTwo then
                nUpgradeOneLevelRate = nUpgradeTwoLevelRate + nUpgradeOneLevelRate
                nUpgradeTwoLevelRate = nil
            end

            local bIsProductBind = self:_IsProductBind()
            -- 绘制侧面板成功率
            if nUpgradeOneLevelRate and nUpgradeTwoLevelRate then
                assert(KItemInfoTwo, "跳级Item获取失败，当前为：" ..
                        ITEM_TABLE_TYPE.OTHER .. "," .. KItemInfo.dwID
                        .. " 跳级概率：" .. KeepDecimalPoint(nUpgradeTwoLevelRate / MILLION_NUMBER * 100, 2) .. "%")
                assert(KItemInfoOne, "高等级Item获取失败，当前为：" ..
                        ITEM_TABLE_TYPE.OTHER .. "," .. KItemInfo.dwID
                        .. " 概率：" .. KeepDecimalPoint(nUpgradeOneLevelRate / MILLION_NUMBER * 100, 2) .. "%")

                local fRateOne = KeepTwoByteFloat(KeepDecimalPoint(nUpgradeOneLevelRate / MILLION_NUMBER * 100, 2))
                local fRateTwo = 0

                if nUpgradeTwoLevelRate > 0 then
                    -- 防止加起来被吃了0.01% 用减法算概率
                    fRateTwo = KeepTwoByteFloat(100 - KeepDecimalPoint(nUpgradeOneLevelRate / MILLION_NUMBER * 100, 2))
                    -- 五行石补丁，修复升级概率+跳级概率<100 跳级概率 >0 显示异常
                    if splitItem.nGenre == ITEM_GENRE.DIAMOND and nUpgradeTotalRate < 100 then
                        fRateTwo = KeepTwoByteFloat(KeepDecimalPoint(nUpgradeTwoLevelRate / MILLION_NUMBER * 100, 2))
                    end
                else
                    fRateTwo = KeepTwoByteFloat(KeepDecimalPoint(nUpgradeTwoLevelRate / MILLION_NUMBER * 100, 2))
                end

                self.refineResultScripts[1]:SetVisible(true)
                self.refineResultScripts[1]:OnInit(KItemInfoOne, fRateOne, bIsProductBind)
                self.refineResultScripts[2]:SetVisible(nUpgradeTwoLevelRate > 0)
                self.refineResultScripts[2]:OnInit(KItemInfoTwo, fRateTwo, bIsProductBind)
                UIHelper.SetVisible(self.LabelBarName, nUpgradeTwoLevelRate > 0)
            elseif nUpgradeOneLevelRate then
                assert(KItemInfoOne, "高等级Item获取失败，当前为：" ..
                        ITEM_TABLE_TYPE.OTHER .. "," .. KItemInfo.dwID
                        .. " 概率：" .. KeepDecimalPoint(nUpgradeOneLevelRate / MILLION_NUMBER * 100, 2) .. "%")

                local fRateOne = KeepTwoByteFloat(KeepDecimalPoint(nUpgradeOneLevelRate / MILLION_NUMBER * 100, 2))
                self.refineResultScripts[1]:SetVisible(true)
                self.refineResultScripts[1]:OnInit(KItemInfoOne, fRateOne, bIsProductBind)
                self.refineResultScripts[2]:SetVisible(false)
                UIHelper.SetVisible(self.LabelBarName, false)
            end
        end

        local nExpendGold, nExpendSilver, nExpendCopper = UIHelper.MoneyToGoldSilverAndCopper(nCostMoney)
        local szMoney = UIHelper.GetMoneyText(PackMoney(nExpendGold, nExpendSilver, nExpendCopper), 24, nil, nil)
        local colMoney = tEnough.Money and NORMAL_COLOR or UNSATISFIED_COLOR
        szMoney = GetFormatText(szMoney, nil, table.unpack(colMoney))
        szMoney = szMoney .. "\n" .. nCostVigor .. "<img src='UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_JingLi' width='36' height='36' />"
        --LOG.WARN(szMoney)
        UIHelper.SetRichText(self.RichTextMoney, szMoney)
        UIHelper.SetRichText(self.RichTextSuccessRateNum, KeepDecimalPoint(nUpgradeTotalRate, 2) .. "%")

        self.nUpgradeTotalRate = nUpgradeTotalRate
        self.nCostMoney = nCostMoney
        self.nCostVigor = nCostVigor

        UIHelper.SetString(self.LabelInsertedNum, string.format("%d/%d", #aMaterial, MAX_MATERIAL_NUM))
        UIHelper.SetVisible(self.WidgetCost, #aMaterial > 0)
        UIHelper.SetVisible(self.LabelSuccessRateHint, #aMaterial <= 0)
        UIHelper.SetButtonState(self.BtnRefine, bCanProduce and BTN_STATE.Normal or BTN_STATE.Disable, function()
            TipsHelper.ShowNormalTip(szCannotProduce)
        end)

        UIHelper.CascadeDoLayoutDoWidget(self.LayoutProductList, true)
    end
    UIHelper.SetVisible(self.LayoutProductList, bHasItem)
end

function UIWidgetRefineUpgrade:UpdateInfo()
    local bShowFast = self.nPanelType == PANEL_TYPE.FAST
    UIHelper.SetVisible(self.WidgetAnchorWuXingFast, bShowFast)
    UIHelper.SetVisible(self.WidgetAnchorBarWuXingFast, bShowFast)
    UIHelper.SetVisible(self.WidgetAnchorMaterial, not bShowFast)
    UIHelper.SetVisible(self.WidgetAnchorBarMaterial, not bShowFast)

    if self.nPanelType ~= PANEL_TYPE.FAST then
        self:UpdateNormalUpgrade()
    else
        self.fastPanelScript:UpdateInfo()
    end

    local bShowRight = bShowFast or self.chosenItem ~= nil
    if bShowRight ~= self.bShowRight then
        self:PlayAnim(bShowRight and "AniToLeft" or "AniToRight")
        self.bShowRight = bShowRight
    end
end

function UIWidgetRefineUpgrade:UpdateNormalUpgrade()
    local szTitle = self.nPanelType == PANEL_TYPE.COLOR and "请置入需要升级的五彩石" or "请置入需要升级的五行石"
    local szMainStoneName = ""

    if self.chosenItem ~= nil then
        local item = self.chosenItem
        self.itemScript:RefreshInfo(EQUIP_REFINE_SLOT_TYPE.MATERIAL_CHOSEN, item.dwIndex, item.nUiId, item.nQuality, 1)
        self.itemScript:SetBind(item.bBind)

        --local pItemInfo = ItemData.GetItemInfo(self.chosenItem.dwTabType, self.chosenItem.dwIndex)
        local nDiamondR, nDiamondG, nDiamondB = GetItemFontColorByQuality(item.nQuality)
        szMainStoneName = GetFormatText(UIHelper.GBKToUTF8(item.szName), nil, nDiamondR, nDiamondG, nDiamondB)
        szTitle = "当前需要升级的材料"
    end

    UIHelper.SetRichText(self.LabelMaterialName, szMainStoneName)
    UIHelper.SetRichText(self.LabelMaterialTitle, szTitle)
    UIHelper.SetVisible(self.itemScript._rootNode, self.chosenItem ~= nil)
    UIHelper.SetVisible(self.WidgetAnchorMaterial, self.chosenItem ~= nil)

    --self:RefreshProgressBarPercent()
    self:UpdateChosenMaterialView()
    self:UpdateRightPanel()
end

function UIWidgetRefineUpgrade:OpenLeftPanel(tabType, fnAction)
    self.LeftBagScript:OpenLeftPanel(tabType, fnAction, self.chosenMaterialCountDict)
end

function UIWidgetRefineUpgrade:OpenBothStonePanel()
    local fnSelectMainStone = function(dwIndex)
        self:SelectMainStoneForRefine(dwIndex)
        --self.LeftBagScript:CloseLeftPanel()
    end

    local nTabType = self.nPanelType == PANEL_TYPE.COLOR and LeftTabType.WuCaiStone or LeftTabType.WuXingStone
    self.LeftBagScript:OpenLeftPanel(nTabType, fnSelectMainStone, self.chosenMaterialCountDict)
end

function UIWidgetRefineUpgrade:ClearData()
    self:ClearRefineExpend()
    if self.chosenItem and self.chosenItem.dwIndex then
        local dwIndex = self.chosenItem.dwIndex
        Event.Dispatch(EventType.EquipRefineSelectChanged, dwIndex, -1)
    end

    self.totalChosenMaterialNum = 0
    self.chosenMaterialCountDict = {}
    self.chosenMaterialList = {}
    self.chosenItem = nil
    self.splitDwBox = nil
    self.splitDwX = nil

    self.nUpgradeTotalRate = 0
    self.nCostMoney = 0
    self.nCostVigor = 0
end

function UIWidgetRefineUpgrade:StartRefine()
    if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.OPERATE_DIAMOND, "OPERATE_DIAMOND") then
        return
    end

    local nFreeSize = ItemData.GetBagFreeCellSize()
    if JX_RefineDiamond.bAutoContinue and nFreeSize < 2 then
        return TipsHelper.ShowImportantRedTip("配方精炼所需包裹空间不足，请至少留出2个包裹空位。")
    end

    local szMessage, fnAction
    local nCount, aMaterial = self:GetRefineExpendMaterial()
    if self.splitDwBox and self.splitDwX then
        local splitItem = ItemData.GetItemByPos(self.splitDwBox, self.splitDwX)
        if splitItem.nGenre == ITEM_GENRE.DIAMOND then
            local szColor = self.nUpgradeTotalRate >= 90 and szGreen or szYellow
            local szSuccessRate = UIHelper.AttachTextColor(("%.1f%%"):format(self.nUpgradeTotalRate), szColor)
            local szFailRate = UIHelper.AttachTextColor(("%.1f%%"):format(100 - self.nUpgradeTotalRate), szColor)

            szMessage = FormatString(g_tStrings.tFEProduce.SURE_STRING, szSuccessRate, szFailRate, UIHelper.AttachTextColor(self.nCostVigor, UI_SUCCESS_COLOR))
            fnAction = function()
                self:UpdateRefineItemLevel()
                RemoteCallToServer("OnUpdateDiamond", self.splitDwBox, self.splitDwX, aMaterial)
                JX_RefineDiamond.StartRefineDiamond(self.splitDwBox, self.splitDwX, aMaterial, self.nQRAmount - 1)
                UIHelper.SetButtonState(self.BtnRefine, BTN_STATE.Disable) -- 置灰按钮 防止弱网落下多次操作
            end
        elseif splitItem.nGenre == ITEM_GENRE.COLOR_DIAMOND then
            local nExpendGold, nExpendSilver, nExpendCopper = UIHelper.MoneyToGoldSilverAndCopper(self.nCostMoney)
            szMessage = FormatString(g_tStrings.tFEProduce.UPDATE_COLOR_MSG, nExpendGold, nExpendSilver, nExpendCopper,
                    self.nCostVigor)
            fnAction = function()
                self:UpdateRefineItemLevel()
                RemoteCallToServer("OnUpdateColorDiamond", self.splitDwBox, self.splitDwX, aMaterial)
                UIHelper.SetButtonState(self.BtnRefine, BTN_STATE.Disable) -- 置灰按钮 防止弱网落下多次操作
                --JX_RefineDiamond.StartRefineDiamond(self.splitDwBox, self.splitDwX, aMaterial, self.nQRAmount - 1,true) --五彩石不可以批量
            end
        end

        if szMessage and fnAction then
            szMessage = ParseTextHelper.ParseNormalText(szMessage)
            UIHelper.ShowConfirm(szMessage, fnAction, nil, true)
        end
    end
end

function UIWidgetRefineUpgrade:UpdateRefineItemLevel()
    if self.splitDwBox and self.splitDwBox >= 0
            and self.splitDwX and self.splitDwX >= 0 then
        local KItem = ItemData.GetPlayerItem(g_pClientPlayer, self.splitDwBox, self.splitDwX)
        if KItem then
            self.nRefineLevel = KItem.nDetail
        end
    end
end

function UIWidgetRefineUpgrade:GetRefineExpendMaterial()
    local nCount, t = 0, {}
    for _, p in ipairs(self.chosenMaterialList) do
        nCount = nCount + p.nStackNum
        for _ = 1, p.nStackNum do
            table.insert(t, { p.dwBox, p.dwX })
        end
    end
    return nCount, t
end

function UIWidgetRefineUpgrade:RefreshProgressBarPercent()
    local minSize = self.minSize
    local totalSize = self:GetMaxAmount()
    local percent = 100
    if totalSize - minSize ~= 0 then
        percent = (self.nQRAmount - minSize) / (totalSize - minSize) * 100
    end

    self.nQRAmount = self.nQRAmount < 1 and 1 or self.nQRAmount
    self.nQRAmount = self.nQRAmount > totalSize and totalSize or self.nQRAmount
    UIHelper.SetProgressBarPercent(self.SliderScriptNum, percent)
    UIHelper.SetProgressBarPercent(self.ProgressBarScriptNum, percent)
end

function UIWidgetRefineUpgrade:AdjustRefineAmount(nVal)
    local newVal = nVal + self.nQRAmount
    local maxAmount = self:GetMaxAmount()

    if newVal < 1 or newVal > maxAmount then
        return
    end

    self.nQRAmount = newVal
    self:RefreshProgressBarPercent()
    self:UpdateInfo()
end

function UIWidgetRefineUpgrade:GetMaxAmount()
    local nMin
    if self.chosenItem and self.chosenItem.dwIndex then
        for dwIndex, nCount in pairs(self.chosenMaterialCountDict) do
            if DataModel.materialDict[dwIndex] then
                local nTotal = DataModel.materialDict[dwIndex].totalCount
                --if self.chosenItem.dwIndex == dwIndex then
                --    nTotal = nTotal - 1 -- 排除主精炼物品
                --    nCount = nCount - 1
                --end
                if nCount > 0 then
                    local nAvailable = math.floor(nTotal / nCount)
                    if not nMin then
                        nMin = nAvailable
                    else
                        nMin = math.min(nMin, nAvailable)
                    end
                end
            end
        end
    end
    if nMin then
        return math.min(nMin, 100)
    end
    return 100
end

function UIWidgetRefineUpgrade:SplitChosenItem()
    if self.chosenItem ~= nil then
        local player = g_pClientPlayer
        local dwBox, dwX = ItemData.GetItemPos(self.chosenItem.dwID)

        if self.chosenItem.nStackNum > 1 then
            for _, nBox in ipairs(ItemData.BoxSet.Bag) do
                for index = 0, player.GetBoxSize(nBox) - 1 do
                    local hItem = player.GetItem(nBox, index)
                    if hItem == nil and ItemData.CanExchangeItem(dwBox, dwX, nBox, index) then
                        ItemData.ExchangeItemByNum(dwBox, dwX, nBox, index, 1)
                        self.splitDwBox = nBox
                        self.splitDwX = index
                        self.bSplitStage = true
                        return -- 物品需要拆分，等待事件BAG_ITEM_UPDATE到达后更新面板信息
                    end
                end
            end
        else
            self.splitDwBox = dwBox
            self.splitDwX = dwX
            self:UpdateInfo() --直接更新信息
        end
    end
end

function UIWidgetRefineUpgrade:PlayRefineDuang(bSuccess)
    if bSuccess then
        UIHelper.PlayAni(self, self.AniAll, "AniSuccess")
        UIHelper.SetVisible(self.WidgetSuccess, true)
        Timer.Add(self, 2, function()
            UIHelper.SetVisible(self.WidgetSuccess, false)
        end)
        --PlaySound(SOUND.UI_SOUND, g_sound.ElementalStoneSuccess)
    else
        UIHelper.PlayAni(self, self.AniAll, "AniLose")
        UIHelper.SetVisible(self.WidgetFail, true)
        Timer.Add(self, 2, function()
            UIHelper.SetVisible(self.WidgetFail, false)
        end)
        --PlaySound(SOUND.UI_SOUND, g_sound.ElementalStoneFailed)
    end
end

function UIWidgetRefineUpgrade:PlayAnim(szAnimeName)
    UIHelper.PlayAni(self, self.AniAll, szAnimeName)
end

-- Deprecated
function UIWidgetRefineUpgrade:MergeItem()
    -- if self.splitDwBox and self.splitDwX and self.chosenItem then
    --     local dwBox, dwX = ItemData.GetItemPos(self.chosenItem.dwID)
    --     local splitItem = ItemData.GetItemByPos(self.splitDwBox, self.splitDwX)
    --     if splitItem then
    --         --ItemData.StackItem(self.splitDwBox, self.splitDwX) -- 将物品堆叠至其他可能的同类物品槽位
    --          if (self.splitDwBox ~= dwBox or self.splitDwX ~= dwX) and self.chosenItem.dwIndex == splitItem.dwIndex
    --                  and ItemData.GetItemMaxStackNum(self.chosenItem) > ItemData.GetItemStackNum(self.chosenItem) then
    --              ItemData.ExchangeItemByNum(self.splitDwBox, self.splitDwX, dwBox, dwX, 1) -- 将物品堆叠至原位
    --          else
    --              ItemData.StackItem(self.splitDwBox, self.splitDwX) -- 将物品堆叠至其他可能的同类物品槽位
    --          end
    --     end

    --     self.splitDwBox = nil
    --     self.splitDwX = nil
    -- end
end

function UIWidgetRefineUpgrade:_IsProductBind()
    if self.chosenItem then
        local bIsMainBind = self.chosenItem.bBind
        local bIsAnyMaterialBind = false

        for i = 1, MAX_MATERIAL_NUM, 1 do
            local itemInfo = self.chosenMaterialList[i]
            if itemInfo and itemInfo.bBind then
                bIsAnyMaterialBind = true
                break
            end
        end

        return bIsMainBind or bIsAnyMaterialBind
    end

    return false
end

function UIWidgetRefineUpgrade:ResetState()
    self:ClearData()
    self:UpdateInfo()
end

return UIWidgetRefineUpgrade

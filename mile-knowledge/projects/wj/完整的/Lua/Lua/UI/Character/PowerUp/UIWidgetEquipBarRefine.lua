local UIWidgetEquipBarRefine = class("UIWidgetEquipBarRefine")

local MAX_MATERIAL_NUM = 16
local MAX_MATERIAL_NUM_HIGH_LEVEL = 128
local SZ_ORANGE_HINT = "注：仅橙色品质武器/戒指可精炼到8级"

local szNoRefine = "#FFFFFF"
local szGreen = "#95FF95"
local szYellow = "#FFE26E"
local HIGH_REFINE_LEVEL = 8

-- 判断特殊槽位的当前精炼是否合法
local function CheckRefineAvailable(dwEquipX)
    if not g_pClientPlayer then
        return false
    end

    local nOldLevel, _ = g_pClientPlayer.GetEquipBoxStrength(dwEquipX)
    local item = g_pClientPlayer.GetItem(INVENTORY_INDEX.EQUIP, dwEquipX)

    if dwEquipX == EQUIPMENT_INVENTORY.MELEE_WEAPON then
        if item == nil and nOldLevel >= 6 then
            return false
        elseif item ~= nil and item.nQuality ~= 5 and nOldLevel >= 6 then
            return false
        end
    elseif dwEquipX == EQUIPMENT_INVENTORY.LEFT_RING then
        if item == nil and nOldLevel >= 6 then
            return false
        elseif item ~= nil and item.nQuality ~= 5 and nOldLevel >= 6 then
            return false
        end
    elseif dwEquipX == EQUIPMENT_INVENTORY.RIGHT_RING then
        if item == nil and nOldLevel >= 6 then
            return false
        elseif item ~= nil and item.nQuality ~= 5 and nOldLevel >= 6 then
            return false
        end
    end

    return true
end

----------------------------端游配置------------------------------

local MILLION_NUMBER = 1048576 --百分率基数

local C = {}

function UIWidgetEquipBarRefine:GetRefineExpendMaterial()
    if self.bHighLevelRefine then
        return self.ChooseWuXingTipScript:GetRefineExpendMaterial()
    end

    local nCount, t = 0, {}
    for _, p in ipairs(self.chosenMaterialList) do
        nCount = nCount + p.nStackNum
        for _ = 1, p.nStackNum do
            table.insert(t, { p.dwBox, p.dwX })
        end
    end
    return nCount, t
end

-- 1.4、清空精炼道具列表
function UIWidgetEquipBarRefine:ClearRefineExpend()
    if self.chosenMaterialList then
        for i = #self.chosenMaterialList, 1, -1 do
            local dwIndex = self.chosenMaterialList[i].dwIndex
            self:_RemoveFromChosenListByIndex(i)
            Event.Dispatch(EventType.EquipRefineSelectChanged, dwIndex, -1)
        end
    end

    if self.bHighLevelRefine then
        self.ChooseWuXingTipScript:ClearMaterial()
    end

    self:ClearChosenMaterial()
end

function UIWidgetEquipBarRefine:StartRefineEquipBox()
    if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.OPERATE_DIAMOND, "OPERATE_DIAMOND") then
        return
    end

    local nEquip = DataModel.GetSelect(1)
    if not nEquip then
        return
    end
    if nEquip == EQUIPMENT_INVENTORY.BIG_SWORD then
        --藏剑重剑对应轻剑装备栏
        nEquip = EQUIPMENT_INVENTORY.MELEE_WEAPON
    end

    local nCount, aMaterial = self:GetRefineExpendMaterial()
    local szSuccessRate = ("%.1f%%"):format(C.nUpgradeTotalRate)
    local szFailRate = ("%.1f%%"):format(100 - C.nUpgradeTotalRate)
    local szColor = C.nUpgradeTotalRate >= 90 and szGreen or szYellow
    local szMessage = FormatString(g_tStrings.tFEProduce.SURE_STRING2, UIHelper.AttachTextColor(szSuccessRate, szColor),
            UIHelper.AttachTextColor(szFailRate, szColor), UIHelper.AttachTextColor(C.nCostVigor, UI_SUCCESS_COLOR),
            UIHelper.AttachTextColor(C.nCostTrain, UI_SUCCESS_COLOR))

    local fnAction = function()
        DataModel.tEquipBoxLevelRecord[nEquip] = g_pClientPlayer.GetEquipBoxStrength(nEquip)
        RemoteCallToServer("OnStrengthEquipBox", nEquip, aMaterial)
        if CheckRefineAvailable(nEquip) then
            UIHelper.ShowTouchMaskWithTips("正在精炼中，请稍候", 10) -- 精炼非法时不显示遮罩
        end
    end

    szMessage = ParseTextHelper.ParseNormalText(szMessage)
    UIHelper.ShowConfirm(szMessage, fnAction, nil, true)
end

function UIWidgetEquipBarRefine:UpdateEquipBoxDetail()
    UIHelper.SetVisible(self.LabelEmptyTips, false)
    UIHelper.SetVisible(self.WidgetRefineClassTooHigh, false)
    UIHelper.SetVisible(self.WidgetRefineClassNormal, false)
    UIHelper.SetVisible(self.LabelRefineShouldStrip, false)
    UIHelper.SetVisible(self.WidgetNoEquip, false)
    UIHelper.SetVisible(self.WidgetRefineLevelChange, false)
    UIHelper.SetVisible(self.RichTextSuccessRateNum, false)
    UIHelper.SetVisible(self.WidgetCost, false)
    --UIHelper.SetVisible(self.WidgetInfo, true)
    UIHelper.SetVisible(self.WidgetInput, true)
    UIHelper.SetVisible(self.BtnRefine, true)
    UIHelper.SetVisible(self.WidgetInfo, true)
    UIHelper.SetVisible(self.WidgetLimit, false)
    UIHelper.SetVisible(self.LabelRefineLevel, true)
    UIHelper.SetVisible(self.WidgetLevel, true)

    UIHelper.RemoveAllChildren(self.ScrollViewAttriList)

    local nEquip, szName = DataModel.GetSelect(1), DataModel.GetSelect(2)
    local pItem = DataModel.GetEquipItem(nEquip)
    UIHelper.SetString(self.LabelBarName, string.format(MAIN_SLOT_NAME_FORMAT, szName))
    UIHelper.SetSpriteFrame(self.ImgDefaultIcon, EquipToDefaultIcon[nEquip])

    if nEquip == EQUIPMENT_INVENTORY.BIG_SWORD then
        nEquip = EQUIPMENT_INVENTORY.MELEE_WEAPON
    end

    local tEquipBoxInfo = DataModel.GetRefineBoxInfo(nEquip)
    local nBoxLevel = tEquipBoxInfo.nLevel
    local nBoxMaxLevel = tEquipBoxInfo.nMaxLevel
    local nBoxQuality = tEquipBoxInfo.nQuality
    local nBoxMaxQuality = tEquipBoxInfo.nMaxQuality
    local bNeedUnstrength = nBoxQuality < nBoxMaxQuality and nBoxQuality > 0

    if nBoxLevel >= nBoxMaxLevel then
        UIHelper.SetVisible(self.WidgetInput, false)
        UIHelper.SetVisible(self.BtnRefine, false)
        UIHelper.SetVisible(self.WidgetCost, false)
        UIHelper.SetVisible(self.WidgetLimit, true)
    end

    UIHelper.SetVisible(self.WidgetRefine01, not self.bHighLevelRefine) -- 精炼等级大于等于6级时显示特殊精炼信息
    UIHelper.SetVisible(self.WidgetRefine02, self.bHighLevelRefine) -- 精炼等级大于6级时显示特殊精炼信息

    UIHelper.SetVisible(self.ImgArrow, nBoxLevel < nBoxMaxLevel) -- 满级时隐藏该label
    UIHelper.SetVisible(self.RichTextNum02, nBoxLevel < nBoxMaxLevel) -- 满级时隐藏该label
    UIHelper.LayoutDoLayout(self.LayoutNum)

    UIHelper.SetVisible(self.Eff_UIrefined, nBoxLevel > 0)
    UIHelper.SetVisible(self.ImgMaxFrame, nBoxLevel >= MAX_FRAME_VISIBLE_LEVEL)

    local szColor = szNoRefine
    if tEquipBoxInfo.nLevel == tEquipBoxInfo.nMaxLevel then
        szColor = szYellow
    elseif tEquipBoxInfo.nLevel > 0 then
        szColor = szGreen
    end

    UIHelper.SetRichText(self.LabelRefineLevel, string.format("<color=%s>%d/%d</color>", szColor, tEquipBoxInfo.nLevel, tEquipBoxInfo.nMaxLevel))

    UIHelper.RemoveAllChildren(self.LayoutStar)
    for i = 1, nBoxMaxLevel do
        local script = UIHelper.AddPrefab(PREFAB_ID.WIdgetRefineStar, self.LayoutStar)
        UIHelper.SetVisible(script.ImgStar01, i <= nBoxLevel)
        UIHelper.SetVisible(script.ImgStarLight, i == nBoxLevel + 1)
    end

    local tStrengthInfo = DataModel.GetStrength(pItem, true, { dwX = nEquip })

    --- 根据槽位是否有装备，进行相应的显示隐藏
    local bCanUpgrade = true
    if pItem then
        local nTempBoxQuality = nBoxQuality == 0 and nBoxMaxQuality or nBoxQuality -- 槽位品质为0时视为最高品质状态
        if pItem.nLevel <= nTempBoxQuality then
            UIHelper.SetVisible(self.WidgetRefineClassNormal, true)
            UIHelper.SetString(self.LabelRefineClassNormal1, string.format(MAIN_SLOT_LEVEL_FORMAT, pItem.nLevel))
            UIHelper.SetString(self.LabelRefineClassNormal2, string.format(MAIN_SLOT_QUALITY_FORMAT, nTempBoxQuality))
        else
            UIHelper.SetVisible(self.WidgetRefineClassTooHigh, true)
            UIHelper.SetString(self.LabelRefineClassTooHigh1, string.format(MAIN_SLOT_LEVEL_FORMAT, pItem.nLevel))
            UIHelper.SetString(self.LabelRefineClassTooHigh2, string.format(MAIN_SLOT_QUALITY_INVALID_FORMAT, nTempBoxQuality))
        end
        UIHelper.SetVisible(self.LabelRefineShouldStrip, bNeedUnstrength)

        if nEquip == EQUIPMENT_INVENTORY.MELEE_WEAPON or nEquip == EQUIPMENT_INVENTORY.LEFT_RING or nEquip == EQUIPMENT_INVENTORY.RIGHT_RING then
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetPowerUpAttriCell, self.ScrollViewAttriList, UIHelper.AttachTextColor(SZ_ORANGE_HINT, UI_SUCCESS_COLOR)) -- 显示橙色品质8级提示
            script:ShowSpecialBg(true)
        end

        if DataModel.IsShowEquipAttri(tStrengthInfo) then
            self:UpdateProperty(pItem, nBoxLevel, nBoxMaxLevel)
        else
            local szTip = ""
            --LOG.TABLE(tStrengthInfo)
            if tStrengthInfo.nBoxLevel >= tStrengthInfo.nBoxMaxLevel then
                self:UpdatePropertyMaxLevel(pItem, nBoxLevel, nBoxMaxLevel)
                bCanUpgrade = false

            elseif tStrengthInfo.nBoxLevel >= tStrengthInfo.nEquipMaxLevel then
                self:UpdateProperty(nil, nBoxLevel, nBoxMaxLevel)
                szTip = string.format("<color=%s>%s</c>", UI_SUCCESS_COLOR, "装备栏精炼等级已达装备精炼等级上限")

                UIHelper.AddPrefab(PREFAB_ID.WidgetPowerUpAttriCell, self.ScrollViewAttriList, szTip)
                UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewAttriList)
            end
        end
    else
        self:UpdateProperty(nil, nBoxLevel, nBoxMaxLevel)
        UIHelper.SetVisible(self.WidgetNoEquip, true)
        UIHelper.SetVisible(self.LabelEmptyTips, true)
    end

    --- 根据槽位是否有装备，进行相应的显示隐藏
    local nCount, aMaterial = self:GetRefineExpendMaterial()
    local bCanProduce = false
    local tEnough = ""
    local fNormalRate = 0
    local nNeedGold, nNeedSilver, nNeedCopper, nDiscountSuccessRate
    local bDiscountStrength = false
    self.szCannotProduce = ""
    C.nUpgradeTotalRate = 0
    if nEquip and bCanUpgrade then
        UIHelper.SetVisible(self.RichTextSuccessRateNum, true)

        if not IsEmpty(aMaterial) then
            UIHelper.SetVisible(self.WidgetCost, true)

            local bResult, nCostMoney, nSuccessRate, nCostVigor, nCostTrain, nDiscount, bDiscount = GetStrengthEquipBoxInfo(nEquip, aMaterial)
            nDiscountSuccessRate = nDiscount / MILLION_NUMBER * 100
            nDiscountSuccessRate = KeepTwoByteFloat(KeepDecimalPoint(nDiscountSuccessRate, 2))
            bDiscountStrength = bDiscount
            nNeedGold, nNeedSilver, nNeedCopper = UIHelper.MoneyToGoldSilverAndCopper(nCostMoney)
            tEnough, self.szCannotProduce = PowerUpView.CheckRefineCost(nCostMoney, nCostVigor, nCostTrain)
            bCanProduce = bResult and nCount > 0 and tEnough.Vigor and tEnough.Money and tEnough.Train

            C.nCostTrain = nCostTrain
            C.nCostVigor = nCostVigor
            C.nUpgradeTotalRate = nSuccessRate / MILLION_NUMBER * 100
            fNormalRate = KeepTwoByteFloat(KeepDecimalPoint(C.nUpgradeTotalRate, 2))
            if bDiscount then
                C.nUpgradeTotalRate = nDiscount / MILLION_NUMBER * 100
            end

            local szTrain = C.nCostTrain .. "<img src='UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_XiuWei' width='36' height='36' />"
            local colTrain = tEnough.Train and NORMAL_COLOR or UNSATISFIED_COLOR
            szTrain = GetFormatText(szTrain, nil, table.unpack(colTrain))

            local szVigor = C.nCostVigor .. "<img src='UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_JingLi' width='36' height='36' />"
            local colVigor = tEnough.Vigor and NORMAL_COLOR or UNSATISFIED_COLOR
            szVigor = GetFormatText(szVigor, nil, table.unpack(colVigor))

            UIHelper.SetRichText(self.RichTextTrain, szTrain .. " " .. szVigor)

            local szMoney = UIHelper.GetMoneyText(PackMoney(nNeedGold, nNeedSilver, nNeedCopper), 24, nil, nil)
            local colMoney = tEnough.Money and NORMAL_COLOR or UNSATISFIED_COLOR
            szMoney = GetFormatText(szMoney, nil, table.unpack(colMoney))
            UIHelper.SetRichText(self.RichTextMoney, szMoney)
        end

        local szColor = fNormalRate == 0 and UI_FAILED_COLOR or UI_SUCCESS_COLOR
        if bDiscountStrength then
            UIHelper.SetRichText(self.RichTextSuccessRateNum, string.format("%s → <color=%s>%s</c>", fNormalRate .. "%", szColor, nDiscountSuccessRate .. "%"))
        else
            UIHelper.SetRichText(self.RichTextSuccessRateNum, string.format("<color=%s>%s</c>", szColor, fNormalRate .. "%"))
        end
    end

    UIHelper.SetVisible(self.LabelSuccessRateHint, fNormalRate == 0)
    UIHelper.SetVisible(self.BtnBenefit, bDiscountStrength and DataModel.HaveNewPlayerStrengthDiscount(g_pClientPlayer, nEquip))
    UIHelper.SetString(self.LabelInsertedNum, string.format("%d/%d", #aMaterial, MAX_MATERIAL_NUM))

    UIHelper.SetButtonState(self.BtnRefine, (not bNeedUnstrength and bCanProduce) and BTN_STATE.Normal or BTN_STATE.Disable, function()
        TipsHelper.ShowImportantRedTip(bNeedUnstrength and "请先进行剥离" or self.szCannotProduce)
    end)
    UIHelper.SetButtonState(self.BtnAutoPlacement, not bNeedUnstrength and BTN_STATE.Normal or BTN_STATE.Disable, function()
        TipsHelper.ShowImportantRedTip("请先进行剥离")
    end)

    UIHelper.SetVisible(self.LayoutResource, nEquip and not IsEmpty(aMaterial))
    UIHelper.LayoutDoLayout(self.LayoutProperty)
end

function UIWidgetEquipBarRefine:UpdateProperty(pItem, nBoxLevel, nBoxMaxLevel)
    UIHelper.SetVisible(self.WidgetRefineLevelChange, true)
    UIHelper.SetString(self.LabelPreviousLevel, nBoxLevel)
    UIHelper.SetString(self.LabelCurrentLevel, nBoxLevel + 1)
    UIHelper.SetString(self.LabelLevelNum, nBoxMaxLevel)

    if not pItem then
        return
    end

    local tAttrib1 = pItem.GetMagicAttribByStrengthLevel(nBoxLevel)
    local tAttrib2 = pItem.GetMagicAttribByStrengthLevel(nBoxLevel + 1)
    local nTipTop = 0
    if tAttrib1 then
        nTipTop = #tAttrib1
    end

    local nCount = 1
    local function AppendContent(nID, szName, nVal, nDiff, bQuality)
        if nDiff == 0 then
            return
        end

        local szPattern = "<color=#79EAB4>%s</c>"  -- 新增属性

        local tbConfig = GetAttribute(nID)
        if tbConfig and tbConfig.bIsNormal then
            szPattern = "<color=#ffffff>%s</c>" -- 普通属性
        end

        local szText = string.format(szPattern, szName)
        if bQuality then
            szText = UIHelper.AttachTextColor(szName, UI_SUCCESS_COLOR)
        end

        UIHelper.AddPrefab(PREFAB_ID.WidgetPowerUpAttriCell, self.ScrollViewAttriList, szText, nVal, nDiff, nCount, bQuality)
        nCount = nCount + 1
    end

    for i = 1, nTipTop, 1 do
        local szName = Table_GetMagicAttributeInfo(tAttrib1[i].nID, true)
        szName = string.gsub(szName, "{(.-)}", function()
            return ""
        end)

        local nVal = tAttrib1[i].nValue1
        if szName ~= "" then
            szName = UIHelper.GBKToUTF8(string.pure_text(szName))
            local szValue = FormatString(Table_GetMagicAttriStrengthValue(tAttrib1[i].nID), tAttrib1[i].nValue1, tAttrib1[i].nValue2, tAttrib2[i].nValue1, tAttrib2[i].nValue2, 0)
            local nDiff = tonumber(szValue)
            if szValue ~= "0" then
                AppendContent(tAttrib1[i].nID, szName, nVal, nDiff)
            end
        end
    end

    local nQuality = pItem.nLevel
    local nQualityAdd1 = ItemData.GetStrengthQualityLevel(nQuality, nBoxLevel)
    local nQualityAdd2 = ItemData.GetStrengthQualityLevel(nQuality, nBoxLevel + 1)

    --local szQuality = string.format("<color=%s>%s +%d</c>", UI_SUCCESS_COLOR, FormatString(g_tStrings.STR_ITEM_H_ITEM_LEVEL
    --, nQuality + nQualityAdd1), nQualityAdd2 - nQualityAdd1)
    --UIHelper.AddPrefab(PREFAB_ID.WidgetPowerUpAttriCell, self.ScrollViewAttriList, szQuality, nCount)

    AppendContent(1, g_tStrings.STR_ITEM_H_ITEM_LEVEL, nQuality + nQualityAdd1, nQualityAdd2 - nQualityAdd1, true)

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewAttriList)
end

function UIWidgetEquipBarRefine:UpdatePropertyMaxLevel(pItem, nBoxLevel, nBoxMaxLevel)
    UIHelper.SetVisible(self.WidgetRefineLevelChange, true)
    UIHelper.SetString(self.LabelPreviousLevel, nBoxLevel)
    UIHelper.SetString(self.LabelCurrentLevel, nBoxLevel)
    UIHelper.SetString(self.LabelLevelNum, nBoxMaxLevel)

    if not pItem then
        return
    end

    local tAttrib1 = pItem.GetMagicAttribByStrengthLevel(nBoxLevel)
    local nTipTop = 0
    if tAttrib1 then
        nTipTop = #tAttrib1
    end

    local nCount = 1
    local function AppendContent(nID, szName, nVal, nDiff, bQuality)
        local szPattern = "<color=#79EAB4>%s</c>"  -- 新增属性

        local tbConfig = GetAttribute(nID)
        if tbConfig and tbConfig.bIsNormal then
            szPattern = "<color=#ffffff>%s</c>" -- 普通属性
        end

        local szText = string.format(szPattern, szName)
        if bQuality then
            szText = UIHelper.AttachTextColor(szName, UI_SUCCESS_COLOR)
        end

        UIHelper.AddPrefab(PREFAB_ID.WidgetPowerUpAttriCell, self.ScrollViewAttriList, szText, nVal, nDiff, nCount, bQuality)
        nCount = nCount + 1
    end

    for i = 1, nTipTop, 1 do
        local szName = Table_GetMagicAttributeInfo(tAttrib1[i].nID, true)
        szName = string.gsub(szName, "{(.-)}", function()
            return ""
        end)

        local nVal = tAttrib1[i].nValue1
        if szName ~= "" then
            szName = UIHelper.GBKToUTF8(string.pure_text(szName))
            AppendContent(tAttrib1[i].nID, szName, nVal, 0)
        end
    end

    local nQuality = pItem.nLevel
    local nQualityAdd1 = ItemData.GetStrengthQualityLevel(nQuality, nBoxLevel)

    AppendContent(1, g_tStrings.STR_ITEM_H_ITEM_LEVEL, nQuality + nQualityAdd1, 0, true)

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewAttriList)
end

----------------------------------------------------------

function UIWidgetEquipBarRefine:OnEnter(nEquip)
    if not self.bInit then
        self.tbTabCfg = {
            [MaterialType.WuXingStone] = { bShowEmptyCell = true, filterFunc = function(item)
                return item.nGenre == ITEM_GENRE.DIAMOND
            end },
            [MaterialType.WuCaiStone] = { bShowEmptyCell = true, filterFunc = function(item)
                return item.nGenre == ITEM_GENRE.COLOR_DIAMOND
            end },
        }

        self.LeftBagScript = UIMgr.AddPrefab(PREFAB_ID.WidgetRefineBag, self.WidgetAniLeft)

        self.totalChosenMaterialNum = 0
        self.chosenMaterialCountDict = {}
        self.chosenMaterialList = {}
        self.chosenList_128 = {}
        self.bHighLevelRefine = false

        self.inventoryMaterialCellScript = {} ---@type UICharacterRefineMaterialCell[]
        self.selectedMaterialCellScript = {} ---@type UICharacterRefineMaterialCell[]

        self.ChooseWuXingTipScript = UIHelper.GetBindScript(self.WidgetChooseWuXingTips) ---@type UIWidgetChooseWuXingTips
        self.ChooseWuXingTipScript:OnEnter(function()
            self:UpdateInfo()
        end)
        self.ChooseWuXingTipScript:UpdateInfo()
        UIHelper.SetVisible(self.ChooseWuXingTipScript._rootNode, false)

        self.fnAction = function(dwIndex)
            self:AddRefiningExpend(dwIndex)
            self:UpdateInfo()
        end

        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        UIHelper.SetVisible(self.WidgetRefineLevelChange, false)
        UIHelper.SetVisible(self.RichTextSuccessRateNum, false)
        UIHelper.SetVisible(self.WidgetCost, false)
        UIHelper.SetVisible(self.WidgetAnchorRight, false)

        UIHelper.SetTouchDownHideTips(self.BtnAutoPlacement, false)
        UIHelper.SetTouchDownHideTips(self.ScrollViewStoneList, false)
        UIHelper.SetTouchDownHideTips(self.BtnCleanUp, false)
        self:Init()

        if nEquip then
            self.WidgetEquipSlotList:SetSelected(nEquip)
            self:SelectEquipSlot(nEquip)
        end
    end
end

function UIWidgetEquipBarRefine:OnExit()
    self.bInit = false
    self.totalChosenMaterialNum = 0
    self.chosenMaterialList = nil

    self.inventoryMaterialCellScript = nil
    self.selectedMaterialCellScript = nil

    self:CloseLeftPanel()

    self:ClearChosenMaterial()
end

function UIWidgetEquipBarRefine:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnRefine, EventType.OnClick, function()
        self:StartRefineEquipBox()
    end)

    UIHelper.BindUIEvent(self.BtnIcon, EventType.OnClick, function()
        local pItem = DataModel.GetEquipItem()
        if self.nEquip and pItem then
            local tip, script = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetItemTip, self.BtnIcon, TipsLayoutDir.LEFT_CENTER)
            script:HidePreviewBtn(true)
            script:SetForbidShowEquipCompareBtn(true)
            script:OnInit(ItemData.GetItemPos(pItem.dwID))
            script:SetBtnState({ })

            tip:Update()
        end
    end)

    UIHelper.BindUIEvent(self.BtnAutoPlacement, EventType.OnClick, function()
        self:AutoFillDiamond()
    end)

    local fnClean = function()
        self:ClearRefineExpend()
        self:UpdateInfo()
    end
    UIHelper.BindUIEvent(self.BtnCleanUp, EventType.OnClick, fnClean)
    UIHelper.BindUIEvent(self.BtnCleanUp02, EventType.OnClick, fnClean)

    UIHelper.BindUIEvent(self.TogChooseWuXing, EventType.OnClick, function()
        if UIHelper.GetVisible(self.WidgetChooseWuXingTips) then
            UIHelper.SetVisible(self.WidgetChooseWuXingTips, false)
        else
            self.ChooseWuXingTipScript:ShowPanel()
        end
    end)

    UIHelper.BindUIEvent(self.TogFastInputTips, EventType.OnClick, function()
        local szDesc = "点击可使用背包中6级及以下的五行石自动填充，最高可达成功率100%"
        local tips, tipsScript = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips
        , self.TogFastInputTips, TipsLayoutDir.TOP_LEFT, szDesc)

        local x, y = UIHelper.GetContentSize(tipsScript.ImgPublicLabelTips)
        tips:SetSize(x, y)
        tips:Update()
    end)

    UIHelper.BindUIEvent(self.BtnBenefit, EventType.OnClick, function()
        local szDesc = "装备精炼成功率萌新福利:\n萌新侠士每个装备部位首次精炼的过程中，1到6级均可享受专属精炼福利，成功率大幅度提升，助力侠士稳步成长闯荡江湖！\n精炼剥离后该部位精炼成功率恢复为常规概率。"
        local tips, tipsScript = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips
        , self.BtnBenefit, TipsLayoutDir.LEFT_CENTER, szDesc)

        local x, y = UIHelper.GetContentSize(tipsScript.ImgPublicLabelTips)
        tips:SetSize(x, y)
        tips:Update()
    end)

    UIHelper.BindUIEvent(self.BtnRefineStrip, EventType.OnClick, function()
        local script = UIMgr.GetViewScript(VIEW_ID.PanelPowerUp)
        script:OpenStrip(self.nEquip)
    end)
end

function UIWidgetEquipBarRefine:RegEvent()
    Event.Reg(self, "FE_STRENGTH_EQUIP", function(arg0)
        local nResult = arg0
        if nResult == DIAMOND_RESULT_CODE.SUCCESS then
            local nEquip = DataModel.GetSelect(1)
            if nEquip == EQUIPMENT_INVENTORY.BIG_SWORD then
                nEquip = EQUIPMENT_INVENTORY.MELEE_WEAPON  --藏剑重剑对应轻剑装备栏
            end
            local nNewEquipBoxLevel = DataModel.GetRefineBoxInfo(nEquip).nLevel
            local nOldEquipBoxLevel = DataModel.tEquipBoxLevelRecord[nEquip] or 9
            if nNewEquipBoxLevel > nOldEquipBoxLevel then
                self:PlayRefineDuang(true, nNewEquipBoxLevel)
            else
                self:PlayRefineDuang(false)
                --OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tFEEquip.FAILED)
            end

            self:ClearRefineExpend()
            self:UpdateInfo()
        else
            local szMsg = g_tStrings.tDiamondResultCode[nResult] or g_tStrings.tFEEquip.FAILED
            PlaySound(SOUND.UI_SOUND, g_sound.FEProduceEquipFail)
            OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
        end
        UIHelper.HideTouchMaskWithTips()
    end)

    Event.Reg(self, "EQUIP_UNSTRENGTH", function(arg0)
        if self.nEquip then
            self:UpdateInfo()
        end
    end)
end

function UIWidgetEquipBarRefine:Init()
    UIHelper.RemoveAllChildren(self.ScrollViewStoneList)

    for i = 1, MAX_MATERIAL_NUM, 1 do
        local slotType = EQUIP_REFINE_SLOT_TYPE.ADD_MATERIAL
        local itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetRefineMaterial_80, self.ScrollViewStoneList, slotType)
        self.selectedMaterialCellScript[i] = itemScript
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewStoneList)

    self:InitEquipSlot()
end

function UIWidgetEquipBarRefine:ResetState()
    DataModel.UpdateEquipList(false)
    self:ClearRefineExpend()
    if self.nEquip then
        DataModel.SetSelect(self.nEquip)
        self:UpdateInfo()
    end
end

function UIWidgetEquipBarRefine:AddRefiningExpend(dwIndex)
    if C.nUpgradeTotalRate and C.nUpgradeTotalRate >= 100 then
        return TipsHelper.ShowImportantBlueTip(g_tStrings.STR_MAX_RATE)
    end

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
                return OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_REFINE_EXPEND_ONLY_DIAMOND_OR_COLOR_DIAMOND) and false
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
                nIcon = Table_GetItemIconID(KItem.nUiId),
            })
            --LOG.TABLE(self.chosenMaterialList[#self.chosenMaterialList])
            Event.Dispatch(EventType.EquipRefineSelectChanged, dwIndex, 1)
            return true
        else
            return OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_REFINE_EXPEND_AMOUNT_REACH_UBOUND) and false
        end
    end
end

function UIWidgetEquipBarRefine:AutoFillDiamond()
    local nEquipInv = DataModel.GetSelect(1)
    if nEquipInv == EQUIPMENT_INVENTORY.BIG_SWORD then
        nEquipInv = EQUIPMENT_INVENTORY.MELEE_WEAPON
    end
    local tMaterial, bFailed = AutoSelectDiamond.Start(nEquipInv)
    if IsTableEmpty(tMaterial) then
        TipsHelper.ShowNormalTip(g_tStrings.STR_AUTO_FILL_DIAMOND_NOT_ENOUGH)
        return
    elseif bFailed then
        TipsHelper.ShowNormalTip(g_tStrings.STR_AUTO_FILL_DIAMOND_FAILED)
    end
    self:ClearRefineExpend()

    if self.bHighLevelRefine then
        self.ChooseWuXingTipScript:AutoFillDiamond(tMaterial)
    else
        for k, v in pairs(tMaterial) do
            local KItem = ItemData.GetItemByPos(v.dwBox, v.dwX)
            local dwIndex = KItem.dwIndex
            for i = 1, v.nStackNum, 1 do
                self:AddRefiningExpend(dwIndex)
            end
        end
        self:UpdateInfo()
        UIHelper.ScrollToIndex(self.ScrollViewStoneList, 0)
    end
end

function UIWidgetEquipBarRefine:UpdateChosenMaterialView()
    if self.bHighLevelRefine then
        local nSelectedNum = self:GetRefineExpendMaterial()
        UIHelper.SetRichText(self.LabelSelectedNum, string.format("<color=#95ff95>%d</color>/%d", nSelectedNum
        , MAX_MATERIAL_NUM_HIGH_LEVEL))
        UIHelper.SetVisible(self.BtnCleanUp02, nSelectedNum > 0)
        return
    end

    if not self.selectedMaterialCellScript then
        return
    end

    local nEquip = DataModel.GetSelect(1)
    local tEquipBoxInfo = DataModel.GetRefineBoxInfo(nEquip)
    local nBoxQuality = tEquipBoxInfo.nQuality
    local nBoxMaxQuality = tEquipBoxInfo.nMaxQuality
    local bNeedUnstrength = nBoxQuality < nBoxMaxQuality and nBoxQuality > 0

    local bHasCell = false
    for i = 1, MAX_MATERIAL_NUM, 1 do
        local itemInfo = self.chosenMaterialList[i]
        local itemScript = self.selectedMaterialCellScript[i]
        --LOG.INFO("UICharacterWidgetEquipRefine:UpdateChosenMaterialView %d", i)
        if itemInfo then
            bHasCell = true
            local item = ItemData.GetItemByPos(itemInfo.dwBox, itemInfo.dwX)

            itemScript:RefreshInfo(EQUIP_REFINE_SLOT_TYPE.MATERIAL_CHOSEN, itemInfo.dwIndex, item.nUiId, item.nQuality, 1)
            itemScript:SetBind(item.bBind)
            itemScript:BindCancelFunc(function()
                --LOG.INFO("Recall function called %d", i)
                self:_RemoveFromChosenListByIndex(i)
                itemScript.nChosenCount = 0
                Event.Dispatch(EventType.EquipRefineSelectChanged, itemInfo.dwIndex, -1)
                self:UpdateInfo()
            end)
        else
            itemScript:RefreshInfo(EQUIP_REFINE_SLOT_TYPE.ADD_MATERIAL)
            UIHelper.BindUIEvent(itemScript.BtnAdd, EventType.OnClick, function()
                LOG.INFO("itemScript.BtnAdd called")
                self:OpenLeftPanel(LeftTabType.WuXingStone)
            end)
        end
        itemScript:SetEnable(not bNeedUnstrength, "请先进行剥离")
    end

    UIHelper.SetVisible(self.BtnCleanUp, bHasCell)
end

function UIWidgetEquipBarRefine:UpdateInfo()
    local tEquipBoxInfo = DataModel.GetRefineBoxInfo(self.nEquip)
    local nBoxLevel = tEquipBoxInfo.nLevel
    
    if self.nEquip == EQUIPMENT_INVENTORY.BIG_SWORD or self.nEquip == EQUIPMENT_INVENTORY.MELEE_WEAPON then
        self.bHighLevelRefine = nBoxLevel >= 5 and tEquipBoxInfo.nMaxLevel == HIGH_REFINE_LEVEL
    else
        self.bHighLevelRefine = nBoxLevel >= 6 and tEquipBoxInfo.nMaxLevel == HIGH_REFINE_LEVEL
    end
    
    if nBoxLevel >= tEquipBoxInfo.nMaxLevel and nBoxLevel == 8 then
        UIHelper.SetVisible(self.ChooseWuXingTipScript._rootNode, false) -- 升到满级时关闭特殊面板
    end

    if not UIHelper.GetVisible(self.WidgetAnchorRight) then
        UIHelper.SetVisible(self.WidgetAnchorRight, true)
        self:PlayAnim("AniToLeft")
    end

    self:UpdateChosenMaterialView()
    self:UpdateEquipBoxDetail()
end

function UIWidgetEquipBarRefine:ClearChosenMaterial()
    self.totalChosenMaterialNum = 0
    self.chosenMaterialCountDict = {}
    self.chosenMaterialList = {}
    C = {}
end

function UIWidgetEquipBarRefine:OpenLeftPanel()
    TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetItemTip)
    self.LeftBagScript:OpenLeftPanel(LeftTabType.WuXingStone, self.fnAction, self.chosenMaterialCountDict)
end

function UIWidgetEquipBarRefine:CloseLeftPanel()
    self.LeftBagScript:CloseLeftPanel()
end

function UIWidgetEquipBarRefine:SelectEquipSlot(nEquip)
    UIHelper.SetVisible(self.WidgetChooseWuXingTips, false)
    self.nEquip = nEquip
    DataModel.SetSelect(nEquip)
    self:ClearRefineExpend()
    self:UpdateInfo()
end

----------------------Helper Method-----------------------------

function UIWidgetEquipBarRefine:_RemoveFromChosenListByIndex(index)
    if index == nil or index < 1 or index > #self.chosenMaterialList then
        LOG.ERROR("UICharacterWidgetEquipRefine:_RemoveFromChosenListByIndex index invalid")
        return
    end

    local itemInfo = self.chosenMaterialList[index]
    self.totalChosenMaterialNum = self.totalChosenMaterialNum - 1
    self.chosenMaterialCountDict[itemInfo.dwIndex] = self.chosenMaterialCountDict[itemInfo.dwIndex] - 1
    table.remove(self.chosenMaterialList, index)
end

function UIWidgetEquipBarRefine:InitEquipSlot()
    self.WidgetEquipSlotList = UIMgr.AddPrefab(PREFAB_ID.WidgetEquipSlotList, self.WidgetAnchorEquipAll, false) ---@type UIWidgetEquipBarList
    self.WidgetEquipSlotList:Init(false, function(nEquip, dwTabType, dwIndex)
        if self.nEquip ~= nEquip then
            self:SelectEquipSlot(nEquip)
        end
    end)
end

function UIWidgetEquipBarRefine:PlayRefineDuang(bSuccess, nNewEquipBoxLevel)
    if bSuccess then
        local szName = DataModel.GetSelect(2)
        --TipsHelper.ShowImportantBlueTip(string.format("【%s】已精炼至【%d级】", szName, nNewEquipBoxLevel))
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

function UIWidgetEquipBarRefine:PlayAnim(szAnimeName)
    UIHelper.PlayAni(self, self.AniAll, szAnimeName)
end

return UIWidgetEquipBarRefine
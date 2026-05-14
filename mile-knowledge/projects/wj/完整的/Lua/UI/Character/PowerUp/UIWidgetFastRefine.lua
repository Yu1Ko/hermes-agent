---@class UIWidgetFastRefine
local UIWidgetFastRefine = class("UIWidgetFastRefine")

local m_tStoneLevel2Index = { 24428, 24427, 24426, 24425, 24424 }
local m_tQRLevelToRealLevel = { 6, 5, 4, 3, 2 }
local nStoneLevelOneDwIndex = 24423

function UIWidgetFastRefine:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()

        self.nQRLevel = 1
        self.nQRAmount = 1
        self.minSize = 1
        self.nMaxCount = self:GetMaxDiamondAmount()

        self.bUseBind = false

        self:RefreshProgressBarPercent()

        for index = 1, 5, 1 do
            local materialImg = self.fastImgs[index]
            local materialBtn = self.fastToggles[index]

            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_44, materialImg)
            script:OnInitWithTabID(ITEM_TABLE_TYPE.OTHER, m_tStoneLevel2Index[index])
            script:HideButton()

            UIHelper.ToggleGroupAddToggle(self.ToggleGroupFast, materialBtn)
            UIHelper.BindUIEvent(materialBtn, EventType.OnSelectChanged, function(toggle, bSelected)
                if bSelected then
                    self.nQRLevel = index
                    self:RefreshProgressBarPercent()
                    self:UpdateInfo()
                    UIHelper.SetSelected(self.TogGemList, false)
                end
            end)
        end

        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewGemList)
        --self:UpdateInfo()
    end
end

function UIWidgetFastRefine:OnExit()
    self.bInit = false
    Event.UnRegAll(self)
end

function UIWidgetFastRefine:BindUIEvent()
    UIHelper.BindUIEvent(self.ButtonGemClose, EventType.OnClick, function()
        UIHelper.SetSelected(self.TogGemList, false)
    end)

    UIHelper.BindUIEvent(self.BtnTips01, EventType.OnClick, function()
        local szDesc = "快速精炼五行石(六级)，有几率直接获得五行石(七级)和五行石(八级)！"
        local tips, tipsScript = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips
        , self.BtnTips01, TipsLayoutDir.BOTTOM_LEFT, szDesc)

        local x, y = UIHelper.GetContentSize(tipsScript.ImgPublicLabelTips)
        tips:SetSize(x, y)
        tips:Update()
    end)

    UIHelper.BindUIEvent(self.BtnTips02, EventType.OnClick, function()
        local szDesc = "勾选后，将仅选择已绑定的五行石(一级)作为消耗材料，产出的五行石也将变为已绑定。"
        local tips, tipsScript = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips
        , self.BtnTips02, TipsLayoutDir.BOTTOM_LEFT, szDesc)

        local x, y = UIHelper.GetContentSize(tipsScript.ImgPublicLabelTips)
        tips:SetSize(x, y)
        tips:Update()
    end)

    UIHelper.BindUIEvent(self.BtnFastRefine, EventType.OnClick, function()
        self:StartFastRefine()
    end)

    UIHelper.BindUIEvent(self.BtnAddAmount, EventType.OnClick, function()
        self:AdjustRefineAmount(1)
    end)

    UIHelper.BindUIEvent(self.BtnSubAmount, EventType.OnClick, function()
        self:AdjustRefineAmount(-1)
    end)

    UIHelper.BindUIEvent(self.Slider, EventType.OnChangeSliderPercent, function(SliderEventType, nSliderEvent)
        if nSliderEvent == ccui.SliderEventType.slideBallDown then
            self.bSliding = true
        elseif nSliderEvent == ccui.SliderEventType.slideBallUp then
            self.bSliding = false
            self:RefreshProgressBarPercent()  -- 强制修正滑块进度
        end

        if self.bSliding then
            local percent = UIHelper.GetProgressBarPercent(self.Slider) / 100
            local maxAmount = self:GetMaxDiamondAmount()

            self.nQRAmount = self.minSize + math.floor(percent * (maxAmount - self.minSize))

            self.nQRAmount = self.nQRAmount < 1 and 1 or self.nQRAmount
            self.nQRAmount = self.nQRAmount > maxAmount and maxAmount or self.nQRAmount

            UIHelper.SetProgressBarPercent(self.ProgressBarCurrentNum, percent * 100)
            self:UpdateInfo()
        end
    end)

    UIHelper.BindUIEvent(self.TogBind, EventType.OnSelectChanged, function(toggle, bVal)
        if self.bUseBind ~= bVal then
            local szContent = "选择优先使用绑定五行石，会优先消耗绑定五行石进行合成，数量不足时会消耗不绑定五行石\n（单块五行石合成中如果只消耗了不绑定五行石，则产物也是不绑定）"
            local fnConfirm = function()
                self.bUseBind = bVal
                self:RefreshProgressBarPercent()
                self:UpdateInfo()
            end
            local fnCancel = function()
                Timer.AddFrame(self, 1, function()
                    UIHelper.SetSelected(self.TogBind, self.bUseBind)
                end)
            end
            if bVal then
                UIHelper.ShowConfirm(szContent, fnConfirm, fnCancel) -- 希望优先使用绑定时弹出二次确认弹窗
            else
                fnConfirm()
            end
        end
    end)
end

function UIWidgetFastRefine:RegEvent()
    Event.Reg(self, "BAG_ITEM_UPDATE", function(arg0, arg1, arg2)
        if arg0 == self.splitDwBox and arg1 == self.splitDwX and self.bSplitStage then
            self.bSplitStage = false
            self:UpdateInfo()
        end
    end)

    Event.Reg(self, "QUICK_UPDATE_DIAMOND", function(arg0, arg1, arg2)
        if arg0 == DIAMOND_RESULT_CODE.SUCCESS then
            self.parentScript:PlayRefineDuang(true)
            OutputMessage("MSG_ANNOUNCE_YELLOW", g_tStrings.tFEProduce.SUCCEED)
        else
            local szMsg = g_tStrings.tDiamondResultCode[arg0] or g_tStrings.tFEProduce.FAILED
            OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
        end
        self:LockOperation(false)
        self:UpdateInfo()
    end)
end

function UIWidgetFastRefine:GetMaxDiamondAmount()
    --local dwTabIndex = m_tStoneLevel2Index[self.nQRLevel]
    --local itemInfo = GetItemInfo(ITEM_TABLE_TYPE.OTHER, dwTabIndex)
    --
    --local tInfo = GetQuickUpdateDiamondInfo(m_tQRLevelToRealLevel[self.nQRLevel], 1)
    --
    --local nNeedMaterialDiamond = tInfo.nNeedMaterialDiamond
    --local nHaveMaterialUnBindDiamond = tInfo.nHaveMaterialDiamond
    --local nHaveMaterialBindDiamond = tInfo.nHaveMaterialBindDiamond
    --local nAvailableTotal = self.bUseBind and nHaveMaterialUnBindDiamond + nHaveMaterialBindDiamond or nHaveMaterialUnBindDiamond
    --
    --local nCalculateMax = math.floor(nAvailableTotal / nNeedMaterialDiamond)
    --local nCalculateMax = math.max(1, nCalculateMax)
    --local UI_MAX_AMOUNT = math.min(100, nCalculateMax)
    --
    --local nMaxCount = 1
    --if itemInfo.bCanStack then
    --    nMaxCount = itemInfo.nMaxDurability
    --end
    --return math.min(UI_MAX_AMOUNT, nMaxCount)
    return 100
end

function UIWidgetFastRefine:UpdateInfo(bShowTips)
    local player = g_pClientPlayer
    local nNeedMaterialDiamond, nHaveMaterialBindDiamond, nHaveMaterialUnBindDiamond, nNeedVigor, nHaveVigor
    local nNeedGold, nNeedSilver, nNeedCopper, nHaveGold, nHaveSilver, nHaveCopper, nAvailableTotal
    local bEnoughMoney, bEnoughDiamond, bEnoughVigor, bCanProduce, szCannotProduce

    assert(self.nQRLevel)
    assert(self.nQRAmount)
    local dwIndex = m_tStoneLevel2Index[self.nQRLevel]
    assert(dwIndex, "Can not get diamond index.")
    local KItemInfo = GetItemInfo(ITEM_TABLE_TYPE.OTHER, dwIndex)
    assert(KItemInfo, "Failed to get iteminfo.")
    self.szDiamondName = KItemInfo.szName

    local KItemInfoMaterial = GetItemInfo(ITEM_TABLE_TYPE.OTHER, nStoneLevelOneDwIndex)
    assert(KItemInfoMaterial, "Cannot get basic diamond.")
    self.szNeedDiamondName = KItemInfoMaterial.szName

    local szNeedDiamondName = UIHelper.GBKToUTF8(self.szNeedDiamondName)
    UIHelper.SetString(self.LabelBarName, UIHelper.GBKToUTF8(self.szNeedDiamondName))

    local szDiamondName = UIHelper.GBKToUTF8(self.szDiamondName)
    UIHelper.SetString(self.LabelBarName, UIHelper.GBKToUTF8(self.szDiamondName))

    local tInfo = GetQuickUpdateDiamondInfo(m_tQRLevelToRealLevel[self.nQRLevel], self.nQRAmount)
    if tInfo then
        local money = player.GetMoney()
        nNeedGold, nNeedSilver, nNeedCopper = UIHelper.MoneyToGoldSilverAndCopper(tInfo.nNeedMoney)
        nHaveGold, nHaveSilver, nHaveCopper = money.nGold, money.nSilver, money.nCopper
        if nNeedCopper == 0 then
            nHaveCopper = 0
        end
        nNeedMaterialDiamond = tInfo.nNeedMaterialDiamond
        nHaveMaterialUnBindDiamond = tInfo.nHaveMaterialDiamond
        nHaveMaterialBindDiamond = tInfo.nHaveMaterialBindDiamond

        nAvailableTotal = self.bUseBind and nHaveMaterialUnBindDiamond + nHaveMaterialBindDiamond or nHaveMaterialUnBindDiamond

        nNeedVigor = tInfo.nNeedVigor
        nHaveVigor = GetPlayerVigorAndStamina(g_pClientPlayer)
        bEnoughVigor = g_pClientPlayer.IsVigorAndStaminaEnough(nNeedVigor)
        bEnoughDiamond = nNeedMaterialDiamond <= nAvailableTotal
        bEnoughMoney = MoneyOptCmp(
                { nGold = nHaveGold, nSilver = nHaveSilver, nCopper = nHaveCopper },
                { nGold = nNeedGold, nSilver = nNeedSilver, nCopper = nNeedCopper }
        ) >= 0
        if not bEnoughMoney then
            szCannotProduce = g_tStrings.STR_REFINE_NOT_ENOUGH_MONEY
        elseif not bEnoughVigor then
            szCannotProduce = g_tStrings.STR_REFINE_NOT_ENOUGH_VIGOR
        elseif not bEnoughDiamond then
            szCannotProduce = g_tStrings.STR_REFINE_NOT_ENOUGH_MATERIAL
        end
        bCanProduce = bEnoughVigor and bEnoughDiamond and bEnoughMoney

        self.szDiamondName = szDiamondName
        self.nNeedMaterialDiamond, self.szNeedDiamondName = nNeedMaterialDiamond, szNeedDiamondName
        self.nNeedVigor, self.nNeedGold, self.nNeedSilver, self.nNeedCopper = nNeedVigor, nNeedGold, nNeedSilver, nNeedCopper
        self.nHaveMaterialUnBindDiamond, self.nHaveMaterialBindDiamond = nHaveMaterialUnBindDiamond, nHaveMaterialBindDiamond
    end

    self.mainGoodScript = self.mainGoodScript or UIHelper.AddPrefab(PREFAB_ID.WidgetRefineMaterial_80, self.WidgetItemFast) ---@type UICharacterRefineMaterialCell
    self.mainGoodScript:RefreshInfo(EQUIP_REFINE_SLOT_TYPE.MATERIAL_IN_BAG, nil, KItemInfo.nUiId, KItemInfo.nQuality)
    self.mainGoodScript:SetBind(self.bUseBind)
    self.mainGoodScript:BindCellFunc(function()
        local tip, script = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetItemTip, self.mainGoodScript._rootNode, TipsLayoutDir.LEFT_CENTER)
        script:OnInitWithTabID(ITEM_TABLE_TYPE.OTHER, dwIndex)
        script:SetBtnState({ })
        tip:Update()
    end)

    local KItemInfoLevelOne = GetItemInfo(ITEM_TABLE_TYPE.OTHER, nStoneLevelOneDwIndex)
    self.consumeGoodScript = self.consumeGoodScript or UIHelper.AddPrefab(PREFAB_ID.WidgetRefineMaterial_80, self.WidgetWuXingLevel1) ---@type UICharacterRefineMaterialCell
    self.consumeGoodScript:RefreshInfo(EQUIP_REFINE_SLOT_TYPE.MATERIAL_IN_BAG, nil, KItemInfoLevelOne.nUiId, KItemInfoLevelOne.nQuality)
    self.consumeGoodScript:BindCellFunc(function()
        local tip, script = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetItemTip, self.consumeGoodScript._rootNode, TipsLayoutDir.LEFT_CENTER)
        script:OnInitWithTabID(ITEM_TABLE_TYPE.OTHER, nStoneLevelOneDwIndex)
        script:SetBtnState({ })
        tip:Update()
    end)
    self.consumeGoodScript:SetBind(self.bUseBind)

    local szAvailable = string.format("<color=%s>%s</c>", bEnoughDiamond and UI_SUCCESS_COLOR or UI_FAILED_COLOR, nAvailableTotal)
    UIHelper.SetRichText(self.RichTextStoneNeedNum, szAvailable)
    UIHelper.SetRichText(self.RichTextStoneAcquiredNum, nNeedMaterialDiamond)

    local szVigor = nNeedVigor .. "<img src='UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_JingLi' width='36' height='36' />"
    local color = bEnoughVigor and NORMAL_COLOR or UNSATISFIED_COLOR
    szVigor = GetFormatText(szVigor, nil, table.unpack(color))
    UIHelper.SetRichText(self.RichTextFastVigor, szVigor)

    local text = UIHelper.GetMoneyText(PackMoney(nNeedGold, nNeedSilver, nNeedCopper), 24, nil, nil)
    color = bEnoughMoney and NORMAL_COLOR or UNSATISFIED_COLOR
    text = GetFormatText(text, nil, table.unpack(color))
    UIHelper.SetRichText(self.RichTextFastMoney, text)

    UIHelper.SetButtonState(self.BtnFastRefine, bCanProduce and BTN_STATE.Normal or BTN_STATE.Disable)
    UIHelper.SetString(self.LabelFastNum01, self.nQRAmount)

    if szCannotProduce and bShowTips then
        OutputMessage("MSG_ANNOUNCE_NORMAL", szCannotProduce)
    end
end

function UIWidgetFastRefine:StartFastRefine()
    if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.OPERATE_DIAMOND, "OPERATE_DIAMOND") then
        return
    end
    local nFreeSize = ItemData.GetBagFreeCellSize()
    if nFreeSize < 2 then
        return TipsHelper.ShowImportantRedTip("包裹空间不足，请至少留出2个包裹空位。")
    end

    local nQRLevel, nQRAmount = m_tQRLevelToRealLevel[self.nQRLevel], self.nQRAmount

    local szMessage = nil
    local nQRUnBindAmount = 0

    if self.bUseBind then
        if self.nNeedMaterialDiamond <= self.nHaveMaterialBindDiamond then
            -- 全部消耗绑定， 产出绑定
            szMessage = FormatString(g_tStrings.STR_QUICKREFINE_BIND_CONFIRM,
                    nQRAmount, self.szDiamondName,
                    self.nNeedMaterialDiamond, self.szNeedDiamondName,
                    self.nNeedVigor, self.nNeedGold, self.nNeedSilver, self.nNeedCopper)
        else
            -- 组合
            local nNeedMaterialBindDiamond = self.nHaveMaterialBindDiamond
            local nNeedMaterialUnBindDiamond = self.nNeedMaterialDiamond - self.nHaveMaterialBindDiamond
            nQRUnBindAmount = math.floor((nNeedMaterialUnBindDiamond / self.nNeedMaterialDiamond * nQRAmount))

            if nQRUnBindAmount == 0 then
                -- 产出的全是绑定， 消耗一部分未绑定
                szMessage = FormatString(g_tStrings.STR_QUICKREFINE_COMBINECONFIRM1,
                        nQRAmount, self.szDiamondName,
                        self.nNeedMaterialDiamond, nNeedMaterialBindDiamond, self.szNeedDiamondName,
                        self.nNeedVigor, self.nNeedGold, self.nNeedSilver, self.nNeedCopper)
            else
                -- 产出 绑定和未绑定， 消耗绑定和未绑定
                szMessage = FormatString(g_tStrings.STR_QUICKREFINE_COMBINECONFIRM2,
                        nQRAmount, (nQRAmount - nQRUnBindAmount), self.szDiamondName,
                        self.nNeedMaterialDiamond, nNeedMaterialBindDiamond, self.szNeedDiamondName,
                        self.nNeedVigor, self.nNeedGold, self.nNeedSilver, self.nNeedCopper)
            end
        end
    else
        nQRUnBindAmount = nQRAmount
        -- 全部消耗未绑定 产出未绑定
        szMessage = FormatString(g_tStrings.STR_QUICKREFINE_UNBIND_CONFIRM,
                nQRAmount, self.szDiamondName,
                self.nNeedMaterialDiamond, self.szNeedDiamondName,
                self.nNeedVigor, self.nNeedGold, self.nNeedSilver, self.nNeedCopper)
    end

    local fnAction = function()
        self:LockOperation(true)
        if nQRUnBindAmount == nQRAmount then
            RemoteCallToServer("OnQuickUpdateDiamond", nQRLevel, nQRAmount)
        elseif nQRUnBindAmount == 0 then
            local nNeedUnBindMaterial = math.floor((nQRAmount * self.nNeedMaterialDiamond / nQRAmount)) - self.nHaveMaterialBindDiamond
            nNeedUnBindMaterial = nNeedUnBindMaterial < 0 and 0 or nNeedUnBindMaterial
            RemoteCallToServer("OnQuickUpdateBindDiamond", nQRLevel, nQRAmount, nNeedUnBindMaterial)
        else
            RemoteCallToServer("OnQuickUpdateDiamond", nQRLevel, nQRUnBindAmount)
            local nNeedUnBindMaterial = math.floor(((nQRAmount - nQRUnBindAmount) * self.nNeedMaterialDiamond / nQRAmount)) - self.nHaveMaterialBindDiamond
            RemoteCallToServer("OnQuickUpdateBindDiamond", nQRLevel, nQRAmount - nQRUnBindAmount, nNeedUnBindMaterial)
        end
    end

    if szMessage and fnAction then
        szMessage = ParseTextHelper.ParseNormalText(szMessage)
        UIHelper.ShowConfirm(szMessage, fnAction, nil, true)
    end
end

function UIWidgetFastRefine:RefreshProgressBarPercent()
    local minSize = self.minSize
    local totalSize = self:GetMaxDiamondAmount()
    local percent = 100
    if totalSize - minSize ~= 0 then
        percent = (self.nQRAmount - minSize) / (totalSize - minSize) * 100
    end

    self.nQRAmount = self.nQRAmount < 1 and 1 or self.nQRAmount
    self.nQRAmount = self.nQRAmount > totalSize and totalSize or self.nQRAmount
    UIHelper.SetProgressBarPercent(self.Slider, percent)
    UIHelper.SetProgressBarPercent(self.ProgressBarCurrentNum, percent)
end

function UIWidgetFastRefine:AdjustRefineAmount(nVal)
    local newVal = nVal + self.nQRAmount
    local maxAmount = self:GetMaxDiamondAmount()

    if newVal < 1 or newVal > maxAmount then
        return
    end

    self.nQRAmount = newVal
    self:RefreshProgressBarPercent()
    self:UpdateInfo(true)
end

function UIWidgetFastRefine:SetParentScript(script)
    self.parentScript = script
end

function UIWidgetFastRefine:LockOperation(bState)
    UIHelper.SetButtonState(self.BtnFastRefine, not bState and BTN_STATE.Normal or BTN_STATE.Disable)
end
return UIWidgetFastRefine
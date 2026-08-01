-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICustomizedSetPowerUpPage
-- Date: 2024-07-15 14:54:04
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICustomizedSetPowerUpPage = class("UICustomizedSetPowerUpPage")

function UICustomizedSetPowerUpPage:OnEnter(nType)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nType = nType
    self.tbData = EquipCodeData.GetCustomizedSetEquip(nType)
    self.tbPowerUpInfo = EquipCodeData.GetCustomizedSetEquipPowerUpInfo(nType) or {}

    self:UpdateInfo()
end

function UICustomizedSetPowerUpPage:OnExit()
    self.bInit = false
end

function UICustomizedSetPowerUpPage:BindUIEvent()
    -- UIHelper.SetSelected(self.TogRefineLevel, false)
    -- UIHelper.SetSelected(self.TogFuMoSwitchSmall, false)
    -- UIHelper.SetSelected(self.TogFuMoSwitchBig, false)
    -- for _, tog in ipairs(self.tbTogSlots) do
    --     UIHelper.SetSelected(tog, false)
    -- end

    UIHelper.BindUIEvent(self.TogRefineLevel, EventType.OnClick, function(btn)
        if UIHelper.GetSelected(self.TogRefineLevel) then
            for _, tog in ipairs(self.tbTogSlots) do
                UIHelper.SetSelected(tog, false)
            end
            local tbEquipStrengthInfo = EquipData.GetStrength(self.tbData.item, false)
            tbEquipStrengthInfo.nCurStrengthLevel = self.tbPowerUpInfo.nStrengthLevel or 0
            local tips, scriptTips = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetRefineInsertFilterList, self.TogRefineLevel, TipsLayoutDir.BOTTOM_CENTER, 1, tbEquipStrengthInfo)
            tips:SetAnchor(0.6, 1)
            tips:Update()
        else
            TipsHelper.DeleteAllHoverTips()
        end
    end)
    UIHelper.SetSwallowTouches(self.TogRefineLevel, true)
    UIHelper.SetTouchDownHideTips(self.TogRefineLevel, false)

    UIHelper.BindUIEvent(self.TogWuCaiSwitch, EventType.OnClick, function(btn)
        local tbColorStone = self.tbPowerUpInfo.tbColorStone or {}
        local nCurSelectItemID
        if tbColorStone.nID then
            local _, dwIndex = GetColorDiamondInfoFromEnchantID(tbColorStone.nID)
            nCurSelectItemID = dwIndex
        end

        UIMgr.Open(VIEW_ID.PanelPowerUpMaterialList, "ColorMount", self.tbData.item, nCurSelectItemID, function (tbInfo)
            self.tbPowerUpInfo.tbColorStone = self.tbPowerUpInfo.tbColorStone or {}
            if tbInfo then
                local nID = tbInfo.nEnchantID
                local dwTabType, dwIndex = GetColorDiamondInfoFromEnchantID(nID)
                local itemInfo = ItemData.GetItemInfo(dwTabType, dwIndex)

                self.tbPowerUpInfo.tbColorStone.nID = tbInfo.nEnchantID
                self.tbPowerUpInfo.tbColorStone.nLevel = itemInfo.nDetail
            else
                self.tbPowerUpInfo.tbColorStone = nil
            end

            EquipCodeData.SetCustomizedSetEquipPowerUpInfo(self.nType, self.tbPowerUpInfo)

            self:UpdateColorMountAttribInfo()
            UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewPowerUpList)
        end)
    end)

    UIHelper.BindUIEvent(self.BtnSyncRefine1, EventType.OnClick, function(btn)
        EquipCodeData.SyncCustomizedSetEquipPowerUpStrengthInfo(self.nType)
    end)

    UIHelper.BindUIEvent(self.BtnSyncRefine2, EventType.OnClick, function(btn)
        EquipCodeData.SyncCustomizedSetEquipPowerUpMountInfo(self.nType)
    end)

    UIHelper.BindUIEvent(self.TogFuMoSwitchSmall, EventType.OnClick, function(btn)
        local tbEnchant = self.tbPowerUpInfo.tbEnchant or {}

        local nCurSelectItemID
        if tbEnchant.nID then
            local item = self.tbData.item
            local tbList = EnchantData.GetRecommendEnchantWithItemInfo(item, EnchantCategory.Normal, EquipCodeData.dwCurKungfuID)
            for nItemIndex, _ in pairs(tbList) do
                local tbEnchantInfo = EnchantData.GetEnchantInfo(nItemIndex)
                if tbEnchantInfo.EnchantID == tbEnchant.nID then
                    nCurSelectItemID = nItemIndex
                end
            end
        end

        UIMgr.Open(VIEW_ID.PanelPowerUpMaterialList, "Enchant", self.tbData.item, nCurSelectItemID, function (nItemTabID)
            local nNewEnchantID
            if nItemTabID and EnchantData.GetEnchantInfo(nItemTabID) then
                local tbEnchantInfo = EnchantData.GetEnchantInfo(nItemTabID)
                nNewEnchantID = tbEnchantInfo.EnchantID
            end

            self.tbPowerUpInfo.tbEnchant = self.tbPowerUpInfo.tbEnchant or {}
            self.tbPowerUpInfo.tbEnchant.nID = nNewEnchantID
            EquipCodeData.SetCustomizedSetEquipPowerUpInfo(self.nType, self.tbPowerUpInfo)

            self:UpdateEnchantAttribInfo()
            UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewPowerUpList)
        end)
    end)

    UIHelper.BindUIEvent(self.TogFuMoSwitchBig, EventType.OnClick, function(btn)
        local tbBigEnchant = self.tbPowerUpInfo.tbBigEnchant or {}

        local nCurSelectItemID
        if tbBigEnchant.nID then
            local item = self.tbData.item
            local tbList = EnchantData.GetRecommendEnchantWithItemInfo(item, EnchantCategory.Season, EquipCodeData.dwCurKungfuID)
            for nItemIndex, _ in pairs(tbList) do
                local tbEnchantInfo = EnchantData.GetEnchantInfo(nItemIndex)
                if tbEnchantInfo.EnchantID == tbBigEnchant.nID then
                    nCurSelectItemID = nItemIndex
                end
            end
        end

        UIMgr.Open(VIEW_ID.PanelPowerUpMaterialList, "BigEnchant", self.tbData.item, nCurSelectItemID, function (nItemTabID)
            local nNewEnchantID
            if nItemTabID and EnchantData.GetEnchantInfo(nItemTabID) then
                local tbEnchantInfo = EnchantData.GetEnchantInfo(nItemTabID)
                nNewEnchantID = tbEnchantInfo.EnchantID
            end

            self.tbPowerUpInfo.tbBigEnchant = self.tbPowerUpInfo.tbBigEnchant or {}
            self.tbPowerUpInfo.tbBigEnchant.nID = nNewEnchantID
            EquipCodeData.SetCustomizedSetEquipPowerUpInfo(self.nType, self.tbPowerUpInfo)

            self:UpdateEnchantAttribInfo()
            UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewPowerUpList)
        end)
    end)

    for i, tog in ipairs(self.tbTogSlots) do
        UIHelper.BindUIEvent(tog, EventType.OnClick, function(btn)
            if UIHelper.GetSelected(tog) then
                UIHelper.SetSelected(self.TogRefineLevel, false)
                for _, tog1 in ipairs(self.tbTogSlots) do
                    if tog1 ~= tog then
                        UIHelper.SetSelected(tog1, false)
                    end
                end

                local tbData = {
                    nSlot = i,
                }
                tbData.nCurSlot = self.tbPowerUpInfo and self.tbPowerUpInfo.tbSlotInfo and self.tbPowerUpInfo.tbSlotInfo[tbData.nSlot] or 0
                local tips, scriptTips = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetRefineInsertFilterList, tog, TipsLayoutDir.BOTTOM_CENTER, 2, tbData)
                tips:SetAnchor(0.6, 1)
                tips:Update()
            else
                TipsHelper.DeleteAllHoverTips()
            end
        end)

        UIHelper.SetSwallowTouches(tog, true)
        UIHelper.SetTouchDownHideTips(tog, false)
    end

end

function UICustomizedSetPowerUpPage:RegEvent()
    Event.Reg(self, EventType.OnWindowsSizeChanged, function ()
        self:UpdateInfo()
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function ()
        self:ClearSelect()
    end)

    Event.Reg(self, EventType.OnHoverTipsDeleted, function (nPrefabID)
        if nPrefabID == PREFAB_ID.WidgetRefineInsertFilterList then
            self:ClearSelect()
        end
    end)

    Event.Reg(self, EventType.OnSelectCustomizedSetPowerUpSelectItemTipsCell, function (nSelectItemType, tbData)
        if nSelectItemType == 1 then
            self.tbPowerUpInfo.nStrengthLevel = tbData.nStrengthLevel
            self.tbPowerUpInfo.nMaxStrengthLevel = tbData.nMaxStrengthLevel
            self.tbPowerUpInfo.nMaxEquipBoxStrengthLevel = tbData.nMaxEquipBoxStrengthLevel
            self:UpdateStrengthInfo()
        elseif nSelectItemType == 2 then
            self.tbPowerUpInfo.tbSlotInfo = self.tbPowerUpInfo.tbSlotInfo or {}
            self.tbPowerUpInfo.tbSlotInfo[tbData.nSlot] = tbData.nStoneLevel
            self:UpdateMountAttribInfo()
        elseif nSelectItemType == 3 then

        end

        EquipCodeData.SetCustomizedSetEquipPowerUpInfo(self.nType, self.tbPowerUpInfo)
    end)
end
function UICustomizedSetPowerUpPage:UpdateInfo()
    if not self.tbData then
        UIHelper.SetVisible(self.WidgetTipsEmpty, true)
        UIHelper.SetVisible(self.ScrollViewPowerUpList, false)
        return
    end

    self:UpdateStrengthInfo()
    self:UpdateMountAttribInfo()
    self:UpdateColorMountAttribInfo()
    self:UpdateEnchantAttribInfo()

    UIHelper.SetVisible(self.WidgetTipsEmpty, false)
    UIHelper.SetVisible(self.ScrollViewPowerUpList, true)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewPowerUpList)
end

function UICustomizedSetPowerUpPage:UpdateStrengthInfo()
    local nStrengthLevel = self.tbPowerUpInfo.nStrengthLevel or 0
    self.tbStrengStarCells = self.tbStrengStarCells or {}
    UIHelper.HideAllChildren(self.LayoutRefineStarShell)
    for i = 1, nStrengthLevel, 1 do
        if not self.tbStrengStarCells[i] then
            self.tbStrengStarCells[i] = UIHelper.AddPrefab(PREFAB_ID.WIdgetRefineStar, self.LayoutRefineStarShell)
            UIHelper.SetVisible(self.tbStrengStarCells[i].ImgStarLightEff, false)
        end
        UIHelper.SetVisible(self.tbStrengStarCells[i]._rootNode, true)
    end
    UIHelper.LayoutDoLayout(self.LayoutRefineStarShell)
    UIHelper.LayoutDoLayout(self.WidgetWuXingRefine)
    UIHelper.SetString(self.LabelRefineHint, string.format("注：装备品级≤%d时，精炼属性方会生效", EquipToBoxMaxQuality[self.nType]))
end

function UICustomizedSetPowerUpPage:UpdateMountAttribInfo()
    UIHelper.SetTabVisible(self.tbTogSlots, false)

    local tbSlotInfo = self.tbPowerUpInfo.tbSlotInfo or {}
    local tbMountAttribInfos = EquipData.GetEquipSlotTip(self.tbData.item, false, { bCmp = false, bLink = true })
    if tbMountAttribInfos then
        for i, tbInfo in ipairs(tbMountAttribInfos) do
            UIHelper.SetVisible(self.tbTogSlots[i], true)
            local script = UIHelper.GetBindScript(self.tbTogSlots[i])

            self.tbSlotIcon = self.tbSlotIcon or {}
            self.tbSlotIcon[i] = self.tbSlotIcon[i] or UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, script.WidgetItem80)

            local szAttr = tbInfo.szAttr
            local nLevel = tbSlotInfo[i] or 0
            if nLevel and WU_XING_STONE_ITEM_ID[nLevel] then
                local nItemTabID = WU_XING_STONE_ITEM_ID[nLevel]
                self.tbSlotIcon[i]:OnInitWithTabID(ITEM_TABLE_TYPE.OTHER, nItemTabID)
                self.tbSlotIcon[i]:SetSelectEnable(false)
                UIHelper.SetVisible(self.tbSlotIcon[i]._rootNode, true)
                UIHelper.SetString(script.LabelWuXingLevel, string.format("（%s级）", UIHelper.NumberToChinese(nLevel)))

                szAttr = EquipData.GetSlotAttr(self.tbData.item, i - 1, false, true, { bCmp = false, bLink = true }, nLevel)
            else
                UIHelper.SetVisible(self.tbSlotIcon[i]._rootNode, false)
                UIHelper.SetString(script.LabelWuXingLevel, "未选择")
            end

            szAttr = string.gsub(szAttr, "镶嵌孔：", string.format("<color=#AED9E0>孔位%d：</c>", i))
            szAttr = string.format("<color=#D7F6FF>%s</c>", szAttr)
            UIHelper.SetRichText(script.RichTextSlotAttri01, szAttr)
            UIHelper.SetRichText(script.RichTextSlotAttri02, szAttr)
            UIHelper.LayoutDoLayout(self.LayoutWuXingShell)
        end
    end

    UIHelper.SetVisible(self.WidgetWuXingInsert, tbMountAttribInfos and #tbMountAttribInfos > 0)
    UIHelper.LayoutDoLayout(self.WidgetWuXingInsert)
end

function UICustomizedSetPowerUpPage:UpdateColorMountAttribInfo()
    if self.tbData.item.nSub ~= EQUIPMENT_SUB.MELEE_WEAPON and self.tbData.item.nSub ~= EQUIPMENT_SUB.BIG_SWORD then
        UIHelper.SetVisible(self.WidgetWuCaiInsert, false)
        return
    end

    UIHelper.SetVisible(self.WidgetWuCaiInsert, true)
    UIHelper.SetVisible(self.WidgetWuCaiItemSmall, false)

    local nEnchantID = 0
    local tbColorStone = self.tbPowerUpInfo.tbColorStone or {}
    if not tbColorStone.nID then
        UIHelper.SetVisible(self.LayoutAttriWuCai, false)
        UIHelper.SetString(self.LabelWuCaiNameSmall1, "未镶嵌")
        UIHelper.SetString(self.LabelWuCaiNameSmall2, "未镶嵌")
    else
        nEnchantID = tbColorStone.nID

        local dwTabType, dwIndex = GetColorDiamondInfoFromEnchantID(nEnchantID)
        local itemInfo = ItemData.GetItemInfo(dwTabType, dwIndex)

        local tbInfo = {}
        tbInfo.diamon, tbInfo.nType, tbInfo.nTabIndex = itemInfo, dwTabType, dwIndex
        tbInfo.bActived = true
        tbInfo.szAttr = ""

        local aAttr = GetFEAInfoByEnchantID(nEnchantID)
        local skillEvent_tab = g_tTable.SkillEvent
        for k, v in pairs(aAttr) do
            EquipData.FormatAttributeValue(v)
            local szPText = ""
            if v.nID == ATTRIBUTE_TYPE.SKILL_EVENT_HANDLER then
                local skillEvent = skillEvent_tab:Search(v.nValue1)
                if skillEvent then
                    szPText = FormatString(skillEvent.szDesc, v.nValue1, v.nValue2)
                else
                    szPText = "unknown skill event id:"..v.nValue1
                end
            else
                szPText = FormatString(Table_GetMagicAttributeInfo(v.nID, true), v.nValue1, v.nValue2, MAGIC_ATTRI_DEF, MAGIC_ATTRI_DEF)
            end

            szPText = UIHelper.GBKToUTF8(szPText)
            szPText = string.pure_text(szPText)

            szPText = string.format("<color=#AED9E0>属性%d：</c><color=#D7F6FF>%s</c>", k, szPText)

            if tbInfo.szAttr ~= "" then
                tbInfo.szAttr = tbInfo.szAttr .. "\n"
            end
            tbInfo.szAttr = tbInfo.szAttr .. szPText
        end

        if not self.scriptWuCaiSmallItem then
            self.scriptWuCaiSmallItem = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.WidgetWuCaiItemSmall)
        end

        UIHelper.SetVisible(self.WidgetWuCaiItemSmall, true)
        self.scriptWuCaiSmallItem:OnInitWithTabID(dwTabType, dwIndex)
        self.scriptWuCaiSmallItem:SetSelectEnable(false)

        szName = ItemData.GetItemNameByItem(itemInfo)
        szName = UIHelper.GBKToUTF8(szName)
        UIHelper.SetString(self.LabelWuCaiNameSmall1, szName)
        UIHelper.SetString(self.LabelWuCaiNameSmall2, szName)

        -- local szItemDesc = ItemData.GetItemDesc(itemInfo.nUiId)
        -- szDesc = ParseTextHelper.ParseNormalText(szItemDesc, true)

        UIHelper.SetRichText(self.RichTextWuCai, tbInfo.szAttr)
        UIHelper.SetVisible(self.LayoutAttriWuCai, true)
    end

    UIHelper.LayoutDoLayout(self.LayoutAttriWuCai)
    UIHelper.LayoutDoLayout(self.WidgetWuCai)
    UIHelper.LayoutDoLayout(self.WidgetWuCaiInsert)
end

function UICustomizedSetPowerUpPage:UpdateEnchantAttribInfo()
    local tbAttribInfos = EquipData.GetEnchantAttribTipWithItemInfo(self.tbData.item)

    UIHelper.SetVisible(self.WidgetFuMoSmall, not not (tbAttribInfos and tbAttribInfos[1]))
    UIHelper.SetVisible(self.WidgetFuMoBig, false)
    UIHelper.SetVisible(self.WidgetFuMoItemSmall, false)
    UIHelper.SetVisible(self.WidgetFuMoItemBig, false)

    local tbEnchant = self.tbPowerUpInfo.tbEnchant or {}
    if not tbEnchant.nID or tbEnchant.nID <= 0 then
        UIHelper.SetVisible(self.LayoutAttriFuMoSmall, false)
        UIHelper.SetString(self.LabelFuMoNameSmall1, g_tStrings.ITEM_TIP_NO_ENCHANT_PERMANENT)
        UIHelper.SetString(self.LabelFuMoNameSmall2, g_tStrings.ITEM_TIP_NO_ENCHANT_PERMANENT)
    else
		local nItemTabID = EnchantData.GetItemIndexWithEnchantID(tbEnchant.nID)
        local szName = g_tStrings.ITEM_TIP_NO_ENCHANT_PERMANENT
        local szDesc

        if not self.scriptEnchantSmallItem then
            self.scriptEnchantSmallItem = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.WidgetFuMoItemSmall)
        end

        if nItemTabID then
            UIHelper.SetVisible(self.WidgetFuMoItemSmall, true)
            self.scriptEnchantSmallItem:OnInitWithTabID(5, nItemTabID)
            self.scriptEnchantSmallItem:SetSelectEnable(false)

            local itemInfo = ItemData.GetItemInfo(5, nItemTabID)
            szName = ItemData.GetItemNameByItem(itemInfo)
            szName = UIHelper.GBKToUTF8(szName)

            local szItemDesc = ItemData.GetItemDesc(itemInfo.nUiId)
            szDesc = ParseTextHelper.ParseNormalText(szItemDesc, true)
        end


        UIHelper.SetString(self.LabelFuMoNameSmall1, szName)
        UIHelper.SetString(self.LabelFuMoNameSmall2, szName)

        if szDesc then
            szDesc = string.format("<color=#D7F6FF>%s</c>", szDesc)
            szDesc = string.gsub(szDesc, "使用：", "<color=#AED9E0>使用：</c>")

            UIHelper.SetRichText(self.RichTextFuMoAttriSmall, szDesc)
            UIHelper.SetVisible(self.LayoutAttriFuMoSmall, true)
        else
            UIHelper.SetVisible(self.LayoutAttriFuMoSmall, false)
        end
    end

    if not self.scriptEnchantBigItem then
        self.scriptEnchantBigItem = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.WidgetFuMoItemBig)
    end

    -- 大附魔
    local item = self.tbData.item
    local bMatchSub = (item.nSub == EQUIPMENT_SUB.HELM or item.nSub == EQUIPMENT_SUB.CHEST or item.nSub == EQUIPMENT_SUB.WAIST
                    or item.nSub == EQUIPMENT_SUB.BANGLE or item.nSub == EQUIPMENT_SUB.BOOTS)
    local bUsage = self.tbData.tbConfig and (self.tbData.tbConfig.nEquipUsage == EQUIPMENT_USAGE_TYPE.IS_PVE_EQUIP or self.tbData.tbConfig.nEquipUsage == EQUIPMENT_USAGE_TYPE.IS_PVP_EQUIP)

    local bMatchLevel = item.nLevel >= 5600
    if bMatchSub and bMatchLevel and bUsage then
        UIHelper.SetVisible(self.WidgetFuMoBig, true)

        -- if self.tbData.tbConfig.nEquipUsage == EQUIPMENT_USAGE_TYPE.IS_PVE_EQUIP then
        --     local tbBigEnchantItemIndex = EnchantData.GetRecommendEnchantWithItemInfo(item, 2, EquipCodeData.dwCurKungfuID, EQUIPMENT_USAGE_TYPE.IS_PVE_EQUIP)
        --     local szDesc, szName, nLastItemTabID
        --     for nItemTabID, _ in pairs(tbBigEnchantItemIndex) do
        --         if not nLastItemTabID or nLastItemTabID < nItemTabID then
        --             nLastItemTabID = nItemTabID
        --         end
        --     end

        --     if nLastItemTabID then
        --         UIHelper.SetVisible(self.WidgetFuMoItemBig, true)
        --         self.scriptEnchantBigItem:OnInitWithTabID(5, nLastItemTabID)
        --         self.scriptEnchantBigItem:SetSelectEnable(false)

        --         local itemInfo = ItemData.GetItemInfo(5, nLastItemTabID)
        --         szName = ItemData.GetItemNameByItem(itemInfo)
        --         szName = UIHelper.GBKToUTF8(szName)

        --         local szItemDesc = ItemData.GetItemDesc(itemInfo.nUiId)
        --         szDesc = ParseTextHelper.ParseNormalText(szItemDesc, true)
        --     end

        --     UIHelper.SetString(self.LabelFuMoNameBig1, szName)
        --     UIHelper.SetString(self.LabelFuMoNameBig2, szName)

        --     if szDesc then
        --         szDesc = string.format("<color=#D7F6FF>%s</c>", szDesc)
        --         szDesc = string.gsub(szDesc, "使用：", "<color=#AED9E0>使用：</c>")
        --         UIHelper.SetRichText(self.RichTextFuMoAttriBig, szDesc)
        --         UIHelper.SetVisible(self.LayoutAttriFuMoBig, true)
        --     else
        --         UIHelper.SetVisible(self.LayoutAttriFuMoBig, false)
        --     end
        --     UIHelper.SetTouchEnabled(self.TogFuMoSwitchBig, false)
        -- else
        local tbBigEnchant = self.tbPowerUpInfo.tbBigEnchant or {}
        if not tbBigEnchant.nID or tbBigEnchant.nID <= 0 then
            UIHelper.SetVisible(self.LayoutAttriFuMoBig, false)
            UIHelper.SetString(self.LabelFuMoNameBig1, g_tStrings.ITEM_TIP_NO_ENCHANT_PERMANENT)
            UIHelper.SetString(self.LabelFuMoNameBig2, g_tStrings.ITEM_TIP_NO_ENCHANT_PERMANENT)
        else
            local nItemTabID = EnchantData.GetItemIndexWithEnchantID(tbBigEnchant.nID)
            local szName = g_tStrings.ITEM_TIP_NO_ENCHANT_PERMANENT
            local szDesc

            if not self.scriptEnchantBigItem then
                self.scriptEnchantBigItem = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.WidgetFuMoItemBig)
            end

            if nItemTabID then
                UIHelper.SetVisible(self.WidgetFuMoItemBig, true)
                self.scriptEnchantBigItem:OnInitWithTabID(5, nItemTabID)
                self.scriptEnchantBigItem:SetSelectEnable(false)

                local itemInfo = ItemData.GetItemInfo(5, nItemTabID)
                szName = ItemData.GetItemNameByItem(itemInfo)
                szName = UIHelper.GBKToUTF8(szName)

                local szItemDesc = ItemData.GetItemDesc(itemInfo.nUiId)
                szDesc = ParseTextHelper.ParseNormalText(szItemDesc, true)
            end


            UIHelper.SetString(self.LabelFuMoNameBig1, szName)
            UIHelper.SetString(self.LabelFuMoNameBig2, szName)

            if szDesc then
                szDesc = string.format("<color=#D7F6FF>%s</c>", szDesc)
                szDesc = string.gsub(szDesc, "使用：", "<color=#AED9E0>使用：</c>")

                UIHelper.SetRichText(self.RichTextFuMoAttriBig, szDesc)
                UIHelper.SetVisible(self.LayoutAttriFuMoBig, true)
            else
                UIHelper.SetVisible(self.LayoutAttriFuMoBig, false)
            end
        end
        UIHelper.SetTouchEnabled(self.TogFuMoSwitchBig, true)
        -- end
    end

    UIHelper.LayoutDoLayout(self.LayoutAttriFuMoSmall)
    UIHelper.LayoutDoLayout(self.LayoutAttriFuMoBig)
    UIHelper.LayoutDoLayout(self.WidgetFuMoSmall)
    UIHelper.LayoutDoLayout(self.WidgetFuMoBig)
    UIHelper.LayoutDoLayout(self.WidgetFuMo)
end

function UICustomizedSetPowerUpPage:ClearSelect()
    UIHelper.SetSelected(self.TogRefineLevel, false)
    UIHelper.SetSelected(self.TogFuMoSwitchSmall, false)
    UIHelper.SetSelected(self.TogFuMoSwitchBig, false)
    UIHelper.SetSelected(self.TogWuCaiSwitch, false)

    for _, tog in ipairs(self.tbTogSlots) do
        UIHelper.SetSelected(tog, false)
    end
end



return UICustomizedSetPowerUpPage
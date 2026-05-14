local UIWidgetEnchant = class("UIWidgetEnchant")

local szGreen = "#95ff95"
local szInActivated = "#94ACB9"
local ITEM_TAP_TYPE = 5

function ItemData.GetEnchantAttrib(nItemIndex)
    local function GetPureEnchantDesc(dwID)
        local szDesc = UIHelper.GBKToUTF8(Table_GetCommonEnchantDesc(dwID))
        if szDesc then
            szDesc = string.pure_text(szDesc)
        else
            local aAttr, dwTime, nSubType = GetEnchantAttribute(dwID)
            if not aAttr or #aAttr == 0 then
                return ""
            end
            szDesc = ""
            local bFirst = true
            for k, v in pairs(aAttr) do
                EquipData.FormatAttributeValue(v)
                local szText = FormatString(Table_GetMagicAttributeInfo(v.nID, true), v.nValue1, v.nValue2, MAGIC_ATTRI_DEF, MAGIC_ATTRI_DEF)
                local szPText = ParseTextHelper.ParseNormalText(szText)
                szPText = UIHelper.GBKToUTF8(szPText)
                if szPText ~= "" then
                    if bFirst then
                        bFirst = false
                    else
                        szPText = "\n" .. szPText
                    end
                end
                szDesc = szDesc .. szPText
            end
            if dwTime == 0 then
                --szDesc = szDesc .. g_tStrings.STR_FULL_STOP
            else
                local tEnchantTipShow = Table_GetEnchantTipShow()
                local tShow = tEnchantTipShow[nSubType]
                local bSurvival = tShow and tShow.bSurvivalEnchant
                if not bSurvival then
                    szDesc = szDesc .. g_tStrings.STR_COMMA .. g_tStrings.STR_TIME_DURATION .. UIHelper.GetTimeText(dwTime)
                end
            end
        end

        return szDesc
    end
    local dwEnchantID = CraftData.g_EnchantInfo[nItemIndex].EnchantID
    return GetPureEnchantDesc(dwEnchantID)
end

function UIWidgetEnchant:OnEnter(dwBox, dwX)
    if not self.bInit then
        UIHelper.SetVisible(self.WidgetAnchorRight, false)

        self.LeftBagScript = UIMgr.AddPrefab(PREFAB_ID.WidgetRefineBag, self.WidgetAniLeft) ---@type UICharacterLeftBag

        self.WidgetTotalEquipListScript = UIMgr.AddPrefab(PREFAB_ID.WidgetTotalEquipList, self.WidgetAnchorTotalEquipList) ---@type UIWidgetTotalEquipList
        self.WidgetTotalEquipListScript:Init("置入", function(nBox, nIndex)
            self:SetEquipmentToEnchant(nBox, nIndex)
            self:UpdateInfo()
        end)

        self.tEnchantCellScripts = {}
        for nIndex, node in ipairs(self.widgetEnchants) do
            local script = UIHelper.GetBindScript(node)
            script:OnEnter()
            self.tEnchantCellScripts[nIndex] = script
        end

        self.nSlotIndex = nil
        self.dwID = nil
        self.chosenMaterialCountDict = {}

        -- 初始值为装备 选中该装备置入槽位
        if dwBox and dwX and ItemData.GetItemByPos(dwBox, dwX) then
            Timer.AddFrame(self, 1, function()
                self:SetEquipmentToEnchant(dwBox, dwX)
                self:UpdateInfo()
                self.WidgetTotalEquipListScript:SetSelected(dwBox, dwX)
            end) -- 延后一帧 确保挂靠正确
        elseif dwBox and not IsNumber(dwBox) and dwBox.nGenre == ITEM_GENRE.ENCHANT_ITEM then
            self:InitWithEnchantItem(dwBox)   -- 初始值为附魔物品 选中玩家身上可使用该附魔的物品 并直接置入附魔
        end

        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIWidgetEnchant:InitWithEnchantItem(tEnchantItem)
    local player = g_pClientPlayer
    if not player then
        return
    end

    --- 遍历身上的装备
    local nTargetBox, nTargetIndex
    for _, nEquipEnum in ipairs(EquipSlotEnum) do
        local nBox, nIndex = INVENTORY_INDEX.EQUIP, nEquipEnum
        local item = ItemData.GetItemByPos(nBox, nIndex)
        if item then
            if EnchantData.CanUseEnchantSimple(player, tEnchantItem, nBox, nIndex) then
                nTargetBox, nTargetIndex = nBox, nIndex
                break
            end
        end
    end

    if nTargetBox and nTargetIndex then
        self:SetEquipmentToEnchant(nTargetBox, nTargetIndex)
        self.WidgetTotalEquipListScript:SetSelected(nTargetBox, nTargetIndex)
        self:ChoseEnchant(tEnchantItem.dwID, tEnchantItem.dwIndex)
        self.nSlotIndex = EnchantData.GetEnchantCategory(tEnchantItem.dwIndex) > 1 and 2 or 1
        self:UpdateInfo()
    end
end

function UIWidgetEnchant:OnExit()
    self.bInit = false

    self.LeftBagScript:CloseLeftPanel()

    self.nBox = nil
    self.nIndex = nil
    self.dwID = nil
end

function UIWidgetEnchant:BindUIEvent()
    for i = 1, 2 do
        self.tEnchantCellScripts[i]:BindCancelFunc(function()
            self:ClearEnchant()
            self:UpdateInfo()
            TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetItemTip)
        end)

        UIHelper.BindUIEvent(self.tEnchantCellScripts[i].BtnAdd, EventType.OnClick, function()
            local setEnchant = function(dwID, dwItemIndex)
                self:ChoseEnchant(dwID, dwItemIndex)
                self.nSlotIndex = i -- chose 之后设置nSlotIndex，避免被清除
                self:UpdateInfo()
            end

            self:OpenEnchantPanel(setEnchant, i)
        end)
    end

    UIHelper.BindUIEvent(self.BtnEnchant, EventType.OnClick, function()
        self:StartEnchant()
    end)
end

function UIWidgetEnchant:RegEvent()
    local fnUpdate = function()
        self:PlayAnim("AniFuMo")
        self:ClearEnchant()
        self:UpdateInfo()
    end
    --- 附魔背包的装备
    Event.Reg(self, "ADD_ENCHANT_SUCCESS", function(arg0, arg1, arg2)
        if arg0 == self.nBox and arg1 == self.nIndex then
            fnUpdate()
        end
    end)

    Event.Reg(self, "REMOVE_ENCHANT_SUCCESS", function(arg0, arg1, arg2)
        if arg0 == self.nBox and arg1 == self.nIndex then
            fnUpdate()
        end
    end)

    Event.Reg(self, "EQUIP_CHANGE", function(result)
        if result == ITEM_RESULT_CODE.SUCCESS then
            self:DeselectEquip()
        end
    end)
end

function UIWidgetEnchant:UpdateInfo()
    local bShowRight = self.nBox ~= nil and self.nIndex ~= nil
    if bShowRight ~= UIHelper.GetVisible(self.WidgetAnchorRight) then
        UIHelper.SetVisible(self.WidgetAnchorRight, bShowRight)
        self:PlayAnim(bShowRight and "AniMiddleToLeft" or "AniMiddleToRight")
    end

    local item
    if self.nBox and self.nIndex then
        item = ItemData.GetItemByPos(self.nBox, self.nIndex)

        if self.itemScript == nil then
            self.itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetRefineMaterial_80, self.WidgetItem) ---@type UICharacterRefineMaterialCell
        end

        self.itemScript:RefreshInfo(EQUIP_REFINE_SLOT_TYPE.MATERIAL_CHOSEN, item.dwIndex, item.nUiId, item.nQuality, 1)
        self.itemScript:BindCancelFunc(function()
            self:DeselectEquip()
            self.WidgetTotalEquipListScript:DeselectToggle()
        end)
        self.itemScript:UpdatePVPImg(item)
        self.itemScript:BindAddFunc(function()
            local tip, script = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetItemTip, self.itemScript._rootNode, TipsLayoutDir.LEFT_CENTER)
            script:HidePreviewBtn(true)
            script:SetForbidShowEquipCompareBtn(true)
            script:OnInit(self.nBox, self.nIndex)
            script:SetBtnState({ })

            tip:Update()
        end)

        local szTips = string.format(ENCHANT_LEVEL_FORMAT, item.nLevel)
        UIHelper.SetString(self.LabelRefineClassNormal1, szTips)
        UIHelper.SetString(self.LabelEquipName, UIHelper.GBKToUTF8(item.szName))

        local nRecommendKungfu = EquipData.GetItemMatchKungfu(item)
        UIHelper.SetVisible(self.LabelKungFuNotMatched, nRecommendKungfu ~= nil and
                nRecommendKungfu ~= g_pClientPlayer.GetKungfuMountID()) -- 推荐心法不是玩家当前装备的心法
        UIHelper.SetVisible(self.LabelCannotRecommend, nRecommendKungfu == nil) -- 可用的推荐心法为空
    else
        UIHelper.SetString(self.LabelEquipName, "从左侧置入一件装备")
    end
    UIHelper.SetVisible(self.WidgetRefineClassNormal, item ~= nil)

    self:UpdateEquipEnchantInfo()
    self:UpdateEnchantMaterialInfo()

    UIHelper.SetButtonState(self.BtnEnchant, (self.dwID and self.nBox and self.nIndex) and BTN_STATE.Normal or BTN_STATE.Disable,
            function()
                OutputMessage("MSG_ANNOUNCE_NORMAL", "请选择附魔")
            end)
end

function UIWidgetEnchant:UpdateEquipEnchantInfo()
    if self.nBox and self.nIndex then
        local item = ItemData.GetItemByPos(self.nBox, self.nIndex)
        local tbAttribInfos, nNeedUpdate = EquipData.GetEnchantAttribTip(item)

        for i = 1, 2 do
            local tInfo = tbAttribInfos[i]
            if item.nSub == EQUIPMENT_SUB.PANTS and i == 2 then
                tInfo = nil --下装裤子不显示第二个附魔槽位
            end
            local bMatchSub = (item.nSub == EQUIPMENT_SUB.HELM or item.nSub == EQUIPMENT_SUB.CHEST or item.nSub == EQUIPMENT_SUB.WAIST
                    or item.nSub == EQUIPMENT_SUB.BANGLE or item.nSub == EQUIPMENT_SUB.BOOTS)
            local bUsage = item.nEquipUsage == EQUIPMENT_USAGE_TYPE.IS_PVE_EQUIP or item.nEquipUsage == EQUIPMENT_USAGE_TYPE.IS_PVP_EQUIP -- PVP也有大附魔
            local bMatchLevel = item.nLevel >= 5600
            if i == 2 and bMatchSub and bMatchLevel and bUsage and tInfo == nil then
                tInfo = {
                    szEnchantIconImg = "UIAtlas2_Character_Character2_img_Enchant_Empty.png",
                    szAttr = g_tStrings.ITEM_TIP_NO_ENCHANT_PERMANENT,
                    bActived = false,
                } -- 显示大附魔槽位
            end

            UIHelper.SetVisible(self.tEnchantCellScripts[i]._rootNode, tInfo ~= nil)

            if tInfo then
                local bActived = tInfo.bActived
                local szDesc = tInfo.szAttr
                local szDescCol = bActived and szGreen or szInActivated
                local szIconImg = tInfo.szEnchantIconImg
                local szAddImg = bActived and "UIAtlas2_Public_PublicItem_PublicItem1_img_Change" or "UIAtlas2_Public_PublicItem_PublicItem1_img_jia"

                if self.nSlotIndex == i and self.dwID then
                    self.tEnchantCellScripts[i]:UpdateInfo(self.dwID)
                    szDescCol = szGreen
                    szDesc = ItemData.GetEnchantAttrib(self.dwItemIndex, item)
                else
                    self.tEnchantCellScripts[i]:UpdateInfo()
                end

                UIHelper.SetRichText(self.tEnchantCellScripts[i].LabelActivated, UIHelper.AttachTextColor(szDesc, szDescCol))
                UIHelper.SetSpriteFrame(self.tEnchantCellScripts[i].ImgEnchantIcon, szIconImg)
                UIHelper.SetSpriteFrame(self.tEnchantCellScripts[i].ImgAddTop, szAddImg)

                local btnStrip = self.tEnchantCellScripts[i].BtnStrip
                local btnTips = self.tEnchantCellScripts[i].BtnTips
                local bPermanent = i == 1
                local dwEnchantID = bPermanent and item.dwPermanentEnchantID or item.dwTemporaryEnchantID
                local bCanStrip = EnchantData.CanStripEnchant(dwEnchantID)
                UIHelper.SetVisible(btnStrip, bCanStrip)
                UIHelper.BindUIEvent(btnTips, EventType.OnClick, function()
                    local szMsg = EnchantData.GetRemovableEnchantTip(bPermanent)
                    local tips, script = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips, btnTips, TipsLayoutDir.BOTTOM_LEFT, szMsg)
                    tips:SetOffset(0, 0)
                    tips:Update()
                end)

                UIHelper.BindUIEvent(btnStrip, EventType.OnClick, function()
                    self:ShowStripConfirm(dwEnchantID, item, bPermanent)
                end)
            end
        end

        if nNeedUpdate then
            self.nTimerID = Timer.Add(self, 0.5, function()
                self:UpdateEquipEnchantInfo()
            end)
        end
    end

    UIHelper.CascadeDoLayoutDoWidget(self.ScrollViewEnchantAttri, true, true)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewEnchantAttri)
end

function UIWidgetEnchant:UpdateEnchantMaterialInfo()
    local nCost = 0
    local nHave, nCostItemIndex
    if self.dwItemIndex then
        nCost, nHave, nCostItemIndex = EnchantData.GetEnchantCost(self.dwItemIndex)
        if nCostItemIndex > 0 then
            local itemInfo = ItemData.GetItemInfo(ITEM_TAP_TYPE, nCostItemIndex)
            local szCost = string.format("%s： %d/%d", UIHelper.GBKToUTF8(itemInfo.szName), nHave, nCost)
            local tCol = nHave >= nCost and NORMAL_COLOR or UNSATISFIED_COLOR
            szCost = GetFormatText(szCost, nil, table.unpack(tCol))
            UIHelper.SetRichText(self.RichTextCoin, szCost)

            UIHelper.RemoveAllChildren(self.WidgetItemCost)
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_44, self.WidgetItemCost)
            script:OnInitWithTabID(ITEM_TAP_TYPE, nCostItemIndex)
            script:SetClickNotSelected(true)

            script:SetClickCallback(function()
                local tip, script = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetItemTip, self.WidgetItemCost, TipsLayoutDir.LEFT_CENTER)
                script:HidePreviewBtn(true)
                script:SetForbidShowEquipCompareBtn(true)
                script:OnInitWithTabID(ITEM_TAP_TYPE, nCostItemIndex)
                script:SetBtnState({ })
                tip:Update()
            end)
        end
    end
    UIHelper.SetVisible(self.LayoutCost, nCostItemIndex and nCostItemIndex > 0)
end

function UIWidgetEnchant:OpenEnchantPanel(fnAction, nSlotIndex)
    if self.nBox == nil or self.nIndex == nil then
        return OutputMessage("MSG_ANNOUNCE_NORMAL", "请先选择需要附魔的装备")
    else
        local nEnchantCategory = 1 -- nSlotIndex为1时
        if nSlotIndex == 2 then
            local item = ItemData.GetItemByPos(self.nBox, self.nIndex)
            nEnchantCategory = (item.nSub == EQUIPMENT_SUB.MELEE_WEAPON) and 3 or 2
        end
        self.LeftBagScript:SetEnchantItem(self.nBox, self.nIndex)
        self.LeftBagScript:OpenLeftPanel(LeftTabType.Enchant, fnAction, self.chosenMaterialCountDict, nEnchantCategory)
    end
end

function UIWidgetEnchant:SetEquipmentToEnchant(nBox, nIndex)
    if self.nTimerID then
        Timer.DelTimer(self, self.nTimerID)
    end
    self:ClearEnchant()
    self.nBox, self.nIndex = nBox, nIndex
end

function UIWidgetEnchant:StartEnchant()
    if self.dwID and self.nBox and self.nIndex then
        if g_pClientPlayer and g_pClientPlayer.nMoveState == MOVE_STATE.ON_SIT then
            g_pClientPlayer.Stand()  --打坐中站起
        end

        local nEnchantBox, nEnchantIndex = g_pClientPlayer.GetItemPos(self.dwID)
        ItemData.UseEnchantItem(nEnchantBox, nEnchantIndex, self.nBox, self.nIndex)
    end
end

function UIWidgetEnchant:DeselectEquip()
    UIHelper.RemoveAllChildren(self.WidgetItem)
    self.itemScript = nil
    self.nBox = nil
    self.nIndex = nil
    self:ClearEnchant()
    self:UpdateInfo()
    Event.Dispatch(EventType.HideAllHoverTips)
end

function UIWidgetEnchant:ClearEnchant()
    self.nSlotIndex = nil
    if self.dwID and self.dwItemIndex then
        Event.Dispatch(EventType.EnchantItemSelectChanged, self.dwID, -1) -- 清除已选择信息
        self.chosenMaterialCountDict[self.dwID] = nil
    end
    self.chosenMaterialCountDict = {}
    self.dwID = nil
    self.dwItemIndex = nil
end

function UIWidgetEnchant:ChoseEnchant(dwID, dwItemIndex)
    self:ClearEnchant()
    self.dwID = dwID
    self.dwItemIndex = dwItemIndex
    Event.Dispatch(EventType.EnchantItemSelectChanged, dwID, 1)
    self.chosenMaterialCountDict[dwID] = 1
end

function UIWidgetEnchant:ShowStripConfirm(nEnchantIDToStrip, item, bPermanent)
    local tEnchantInfo = CraftData.g_EnchantInfo_Inverse[nEnchantIDToStrip]
    local nCost, nHave, nCostItemIndex = EnchantData.GetEnchantCost(tEnchantInfo.ItemIndex)

    local tList = {}
    table.insert(tList, {
        dwIndex = tEnchantInfo.ItemIndex,
        nStackNum = 1,
        dwTabType = ITEM_TAP_TYPE
    })

    --if tEnchantInfo.EquipmentType == EQUIPMENT_USAGE_TYPE.IS_PVE_EQUIP and nCost > 0 then
    --    table.insert(tList, {
    --        dwIndex = tEnchantInfo.ItemID,
    --        nStackNum = nCost,
    --        dwTabType = ITEM_TAP_TYPE -- 目前只有PVE大附魔会返还材料
    --    })
    --end

    local tEnchantItemInfo = ItemData.GetItemInfo(5, tEnchantInfo.ItemIndex)
    local r, g, b = GetItemFontColorByQuality(tEnchantItemInfo.nQuality)
    local szEnchantName = string.format("[%s]", UIHelper.GBKToUTF8(tEnchantItemInfo.szName))
    szEnchantName = GetFormatText(szEnchantName, nil, r, g, b)

    local nStripCost = bPermanent and 3000 or 2000
    local nDiamondR, nDiamondG, nDiamondB = GetItemFontColorByQuality(item.nQuality, false)
    local szName = string.format("[%s]", UIHelper.GBKToUTF8(item.szName))
    local nBox, nIndex = ItemData.GetItemPos(item.dwID)
    szName = GetFormatText(szName, nil, nDiamondR, nDiamondG, nDiamondB)
    local szMsg = "确认花费%d<img src='UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_Jin' width='40' height='40'/>剥离%s的附魔%s吗？\n 可退还："
    local szFinalContent = string.format(szMsg, nStripCost, szName, szEnchantName)
    UIHelper.ShowConfirmWithItemList(szFinalContent, tList, function()
        RemoteCallToServer("On_Craft_RemoveEnchant", nEnchantIDToStrip, nBox, nIndex)
    end, nil, nil)
end

function UIWidgetEnchant:PlayAnim(szAnimeName)
    UIHelper.PlayAni(self, self.AniAll, szAnimeName)
end

return UIWidgetEnchant
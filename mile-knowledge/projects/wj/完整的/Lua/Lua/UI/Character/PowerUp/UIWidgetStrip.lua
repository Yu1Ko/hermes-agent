local UIWidgetStrip = class("UIWidgetStrip")

local BOX_COUNT = 16
local tEquipKind = {
    "MELEE_WEAPON",
    "RANGE_WEAPON",
    "CHEST",
    "HELM",
    "AMULET",
    "RING",
    "WAIST",
    "PENDANT",
    "PANTS",
    "BOOTS",
    "BANGLE",
}

local StripType = {
    EquipSlot = 1,
    Equip = 2
}

-----------------------------DataModel------------------------------
local DataModel = {}

function DataModel.Init(stripType, bRare)
    DataModel.dwTargetType = TARGET.NPC
    DataModel.dwTargetID = 8808
    DataModel.nStripType = stripType
    DataModel.bRare = bRare or false
    DataModel.tEquipBoxSelect = nil
    --DataModel.tEquipBoxSelect = DataModel.GetEquipList()[1]
end

function DataModel.UnInit()
    DataModel.dwTargetType = nil
    DataModel.dwTargetID = nil
    DataModel.bRare = nil
    DataModel.nStripType = nil
    DataModel.tEquipBoxSelect = nil
    DataModel.SetBox()
end

function DataModel.SetSelectBox(nEquipInv)
    local bFind = false

    for _, v in pairs(DataModel.GetEquipList()) do
        local nEquip = v[1]
        local szTypeName = v[2]
        local nIconFrame = v[3]

        if nEquip == nEquipInv then
            DataModel.tEquipBoxSelect = { nEquip, szTypeName, nIconFrame }
            bFind = true
            break
        end
    end

    if not bFind then
        DataModel.tEquipBoxSelect = DataModel.GetEquipList()[1]
    end
end

function DataModel.SetBox(dwBox, dwX)
    if dwBox and dwX then
        DataModel.dwBox = dwBox
        DataModel.dwX = dwX

        local pItem = ItemData.GetPlayerItem(g_pClientPlayer, DataModel.dwBox, DataModel.dwX)
        DataModel.bRare = pItem.nGenre == ITEM_GENRE.EQUIPMENT and pItem.nSub == EQUIPMENT_SUB.MELEE_WEAPON and pItem.nQuality == 5
    else
        DataModel.dwBox = nil
        DataModel.dwX = nil
        DataModel.bRare = false
    end
end

function DataModel.GetEquipList()
    local dwForceID = g_pClientPlayer.dwForceID
    if dwForceID == FORCE_TYPE.CANG_JIAN then
        return g_tStrings.tEquipBoxCasting_CangJian
    else
        return g_tStrings.tEquipBoxCasting
    end
end

function DataModel.GetEquipItem(nEquip)
    if not nEquip then
        if DataModel.tEquipBoxSelect == nil then
            DataModel.SetSelectBox()
        end
        nEquip = DataModel.tEquipBoxSelect[1]
    end
    return g_pClientPlayer.GetEquipItem(nEquip)
end

function DataModel.GetLevel()
    local nStrengthLevel = 0
    if DataModel.nStripType == StripType.EquipSlot then
        local nBoxLevel, _ = g_pClientPlayer.GetEquipBoxStrength(DataModel.tEquipBoxSelect[1])
        nStrengthLevel = nBoxLevel
    elseif DataModel.dwBox and DataModel.dwX then
        local pItem = ItemData.GetPlayerItem(g_pClientPlayer, DataModel.dwBox, DataModel.dwX)
        if pItem then
            nStrengthLevel = pItem.nStrengthLevel or 0
        end
    end
    return nStrengthLevel
end

function DataModel.CheckUnstrength()
    local bCanUnstrength = false
    local nCost = 0
    local tDiamond = {}
    local bDiscount = false
    local pPlayer = g_pClientPlayer
    if not pPlayer or (DataModel.nStripType == StripType.EquipSlot and not DataModel.tEquipBoxSelect) then
        return false
    end

    if DataModel.nStripType == StripType.Equip and DataModel.dwBox and DataModel.dwX then
        local pItem = pPlayer.GetItem(DataModel.dwBox, DataModel.dwX)
        if pItem and DataModel.bRare then
            if pItem.nQuality == 5 and pItem.nStrengthLevel < 8 then
                tDiamond = GDAPI_UnstrengthOrangeWeapon(pItem) --"scripts/Include/UIscript/UIscript_DiamondCount.lua"
                if #tDiamond > 0 then
                    bCanUnstrength = true
                end
            end
        else
            local bRet, nTmpCost = GetUnStrengthEquipCost(DataModel.dwBox, DataModel.dwX)
            if bRet then
                nCost = nTmpCost
            end
            local ret = pPlayer.UnStrengthEquip(DataModel.dwBox, DataModel.dwX)
            if ret == DIAMOND_RESULT_CODE.SUCCESS then
                bCanUnstrength = true
                tDiamond = GetDisplayDiamonds()
            end
        end
    elseif DataModel.nStripType == StripType.EquipSlot then
        local nEquip = DataModel.tEquipBoxSelect[1]
        -- 藏剑重剑对应轻剑装备栏
        if nEquip == EQUIPMENT_INVENTORY.BIG_SWORD then
            nEquip = EQUIPMENT_INVENTORY.MELEE_WEAPON
        end
        local bResult, nTmpCost = GetUnStrengthEquipBoxCost(nEquip)
        if bResult then
            nCost = nTmpCost
        end
        local ret, bFlag = pPlayer.UnStrengthEquipBox(nEquip)
        if ret == DIAMOND_RESULT_CODE.SUCCESS then
            bCanUnstrength = true
            tDiamond = GetDisplayDiamonds()
            bDiscount = bFlag
        end
    end
    return bCanUnstrength, nCost, tDiamond, bDiscount
end

function DataModel.GetRefineBoxInfo(nEquip)
    local nBoxLevel, nBoxQuality = g_pClientPlayer.GetEquipBoxStrength(nEquip)
    local nBoxMaxLevel, nBoxMaxQuality = GetEquipBoxMaxStrengthInfo(nEquip)
    return {
        nLevel = nBoxLevel,
        nMaxLevel = nBoxMaxLevel,
        nQuality = nBoxQuality,
        nMaxQuality = nBoxMaxQuality,
    }
end

--------------------------------------------------------------------

function UIWidgetStrip:OnEnter(nEquip)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()

        UIHelper.ToggleGroupAddToggle(self.ToggleGroup, self.TogBar)
        UIHelper.ToggleGroupAddToggle(self.ToggleGroup, self.TogEquip)

        self.bInit = true
        self.materialScripts = {}
        self.bShowRight = false

        DataModel.Init(StripType.EquipSlot, false)
        self:Init()
    end
    if nEquip then
        DataModel.SetSelectBox(nEquip)
        self:UpdateInfo()
        self.WidgetEquipSlotList:SetSelected(nEquip)
    end
end

function UIWidgetStrip:OnExit()
    self.bInit = false
    DataModel.UnInit()
end

function UIWidgetStrip:BindUIEvent()
    UIHelper.BindUIEvent(self.TogBar, EventType.OnSelectChanged, function(toggle, bValue)
        if bValue then
            DataModel.nStripType = StripType.EquipSlot
            self:ClearData()
            self:UpdateInfo()
        end
    end)

    --UIHelper.BindUIEvent(self.TogEquip, EventType.OnSelectChanged, function(toggle, bValue)
    --    if bValue then
    --        DataModel.nStripType = StripType.Equip
    --        self:ClearData()
    --        self:UpdateInfo()
    --    end
    --end)

    UIHelper.BindUIEvent(self.BtnIcon, EventType.OnClick, function()
        local nEquip = DataModel.tEquipBoxSelect and DataModel.tEquipBoxSelect[1]
        if not nEquip then
            return
        end

        local pItem = DataModel.GetEquipItem(nEquip)
        if pItem then
            local tip, script = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetItemTip, self.BtnIcon, TipsLayoutDir.LEFT_CENTER)
            script:HidePreviewBtn(true)
            script:SetForbidShowEquipCompareBtn(true)
            script:OnInit(ItemData.GetItemPos(pItem.dwID))
            script:SetBtnState({ })

            tip:Update()
        end
    end)

    UIHelper.BindUIEvent(self.BtnStrip, EventType.OnClick, function()
        self:StartStrip()
    end)

    UIHelper.BindUIEvent(self.BtnTips, EventType.OnClick, function()
        local szDesc = "该装备栏精炼时已享受精炼萌新福利,因此本次剥离所得五行石为正常剥离所得价值的%.0f%%。"
        szDesc = string.format(szDesc, self.nDiscountPercent)
        local tips, tipsScript = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips
        , self.BtnTips, TipsLayoutDir.BOTTOM_CENTER, szDesc)

        local x, y = UIHelper.GetContentSize(tipsScript.ImgPublicLabelTips)
        tips:SetSize(x, y)
        tips:Update()
    end)
end

function UIWidgetStrip:RegEvent()
    Event.Reg(self, "EQUIP_UNSTRENGTH", function(arg0, arg1)
        local nResult = arg0
        if nResult == DIAMOND_RESULT_CODE.SUCCESS then
            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tFEExtract.UNSTRENGTH_SUCCESS)
            --PlaySound(SOUND.UI_SOUND, g_sound.FEExtractSuccess)
        elseif nResult == DIAMOND_RESULT_CODE.NEED_EQUIPMENT then
            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tFEExtract.NEED_EQUIP)
        elseif nResult == DIAMOND_RESULT_CODE.NEED_IN_PACKAGE then
            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tFEExtract.NEED_IN_PACKAGE)
        elseif nResult == DIAMOND_RESULT_CODE.NOT_ENOUGH_FREE_ROOM then
            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tFECommon.NO_ENOUGH_ROOM)
        elseif nResult == DIAMOND_RESULT_CODE.CAN_NOT_OPERATE_IN_FIGHT then
            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tFEExtract.CAN_NOT_OPERATE_IN_FIGHT)
        elseif nResult == DIAMOND_RESULT_CODE.NOT_ENOUGH_MONEY_FOR_COST then
            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tFECommon.NOT_ENOUGH_MONEY_FOR_COST)
        elseif nResult == DIAMOND_RESULT_CODE.SCENE_FORBID then
            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tFECommon.SCENE_FORBID)
        else
            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tFEExtract.UNSTRENGTH_FAILED)
        end
        self:PlayAnim("AniStrip")
        self:UpdateInfo()
    end)

    Event.Reg(self, "FE_STRENGTH_EQUIP", function(arg0)
        local nResult = arg0
        if nResult == DIAMOND_RESULT_CODE.SUCCESS then
            self:UpdateInfo()
        end
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function(arg0)
        if self.scriptItemTip then
            UIHelper.SetVisible(self.scriptItemTip._rootNode, false)
        end
    end)
end

function UIWidgetStrip:Init()
    self.WidgetEquipSlotList = UIMgr.AddPrefab(PREFAB_ID.WidgetEquipSlotList, self.WidgetAnchorEquipBar) ---@type UIWidgetEquipBarList
    self.WidgetEquipSlotList:Init(false, function(nEquip, dwTabType, dwIndex)
        DataModel.SetSelectBox(nEquip)
        self:UpdateInfo()
    end)

    --self.WidgetTotalEquipList = UIMgr.AddPrefab(PREFAB_ID.WidgetTotalEquipList, self.WidgetAnchorTotalEquipList) ---@type UIWidgetTotalEquipList
    --self.WidgetTotalEquipList:Init("置入", function(nBox, nIndex)
    --    DataModel.SetBox(nBox, nIndex)
    --    self:UpdateInfo()
    --end)

    for i = 1, BOX_COUNT, 1 do
        local slotType = EQUIP_REFINE_SLOT_TYPE.EMPTY
        local itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetRefineMaterial_80, self.LayoutProductPreview, nil, nil, nil, nil, slotType)
        self.materialScripts[i] = itemScript
    end

    UIHelper.LayoutDoLayout(self.LayoutProductPreview)
end

function UIWidgetStrip:UpdateInfo()
    UIHelper.SetVisible(self.WidgetAnchorEquipBar, DataModel.nStripType == StripType.EquipSlot)
    UIHelper.SetVisible(self.WidgetAnchorTotalEquipList, DataModel.nStripType ~= StripType.EquipSlot)

    UIHelper.SetVisible(self.WidgetEmptyBar, false)
    UIHelper.SetVisible(self.WidgetEmptyEquip, false)
    UIHelper.SetVisible(self.WidgetFilledEquipBar, false)
    UIHelper.SetVisible(self.WidgetEquip, false)

    if DataModel.nStripType == StripType.EquipSlot then
        self:UpdateEquipSlot()
        --else
        --    self:UpdateEquip()
    end

    local bShowRight = DataModel.tEquipBoxSelect ~= nil
            or (DataModel.dwBox ~= nil and DataModel.dwX ~= nil)
    if bShowRight ~= self.bShowRight then
        self:PlayAnim(bShowRight and "AniToLeft" or "AniToRight")
        self.bShowRight = bShowRight
    end

    local bCanUnstrength, nCost, tDiamond, bDiscount = DataModel.CheckUnstrength()
    self:UpdateMoney(bCanUnstrength, nCost)
    self:UpdateDiamondBox(bCanUnstrength, tDiamond)
    UIHelper.SetString(self.LabelStrippable, bCanUnstrength and "剥离后精炼效果消失" or "当前暂时无法剥离")
    UIHelper.SetVisible(self.Eff_UIrefined, bCanUnstrength)

    UIHelper.SetVisible(self.WidgetSpecial, bDiscount)
    UIHelper.SetVisible(self.LabelStrippable, not bDiscount)

    if bDiscount then
        local nEquip = DataModel.tEquipBoxSelect and DataModel.tEquipBoxSelect[1]
        local bFlag1, fOriginal = g_pClientPlayer.GetStrengthEquipBoxValue(nEquip, false)
        local bFlag2, fDiscount = g_pClientPlayer.GetStrengthEquipBoxValue(nEquip, true)
        self.nDiscountPercent = fDiscount / fOriginal * 100
        UIHelper.SetString(self.LabelDiscount, string.format("(已折算%.0f%%)", self.nDiscountPercent))
    end
end

function UIWidgetStrip:UpdateEquipSlot()
    UIHelper.SetVisible(self.WidgetFilledEquipBar, DataModel.tEquipBoxSelect ~= nil)
    UIHelper.SetVisible(self.WidgetEmptyBar, DataModel.tEquipBoxSelect == nil)

    local nEquip = DataModel.tEquipBoxSelect and DataModel.tEquipBoxSelect[1]
    if not nEquip then
        return
    end

    local pItem = DataModel.GetEquipItem(nEquip)
    if nEquip == EQUIPMENT_INVENTORY.BIG_SWORD then
        nEquip = EQUIPMENT_INVENTORY.MELEE_WEAPON
    end
    local nBoxLevel, nBoxQuality = g_pClientPlayer.GetEquipBoxStrength(nEquip)
    UIHelper.SetString(self.LabelBarName, DataModel.tEquipBoxSelect[2] .. "栏")

    if nBoxLevel > 0 then
        UIHelper.SetString(self.LabelRefineClassNormal, "当前精炼等级：" .. nBoxLevel)
    end

    UIHelper.SetVisible(self.LabelRefineClassNormal, nBoxLevel > 0)
    UIHelper.SetVisible(self.LabelRefineClassZero, nBoxLevel == 0)
    UIHelper.SetVisible(self.ImgMaxFrame, nBoxLevel >= MAX_FRAME_VISIBLE_LEVEL)

    UIHelper.SetVisible(self.WidgetAniRight, true)
    UIHelper.SetSpriteFrame(self.ImgBar, EquipToDefaultIcon[nEquip])

    UIHelper.SetVisible(self.WidgetRefineClassTooHigh, false)
    UIHelper.SetVisible(self.WidgetRefineClassNormal, false)
    UIHelper.SetVisible(self.WidgetNoEquip, false)
    UIHelper.SetVisible(self.LabelRefineShouldStrip, false)

    local tEquipBoxInfo = DataModel.GetRefineBoxInfo(nEquip)
    local nBoxLevel = tEquipBoxInfo.nLevel
    local nBoxMaxLevel = tEquipBoxInfo.nMaxLevel
    local nBoxQuality = tEquipBoxInfo.nQuality
    local nBoxMaxQuality = tEquipBoxInfo.nMaxQuality
    local bNeedUnstrength = nBoxQuality < nBoxMaxQuality and nBoxQuality > 0

    -- 更新品级文字描述
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
    else
        UIHelper.SetVisible(self.WidgetNoEquip, true)
        UIHelper.SetVisible(self.LabelEmptyTips, true)
    end
end

--function UIWidgetStrip:UpdateEquip()
--    local bHasItem = DataModel.dwBox ~= nil and DataModel.dwX ~= nil
--    local pItem
--    if bHasItem then
--        pItem = ItemData.GetItemByPos(DataModel.dwBox, DataModel.dwX)
--        if pItem then
--            if self.itemScript == nil then
--                self.itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetRefineMaterial_80, self.WidgetItemEquip)
--            end
--            self.itemScript:RefreshInfo(EQUIP_REFINE_SLOT_TYPE.MATERIAL_CHOSEN, pItem.dwIndex, pItem.nUiId, pItem.nQuality, 1)
--            self.itemScript:BindCancelFunc(function()
--                DataModel.SetBox()
--                self:UpdateInfo()
--                Event.Dispatch(EventType.HideAllHoverTips)
--                self.WidgetTotalEquipList:DeselectToggle()
--            end)
--
--            UIHelper.SetString(self.LabelEquipName, UIHelper.GBKToUTF8(pItem.szName))
--        end
--    end
--
--    UIHelper.SetVisible(self.WidgetItemEquip, bHasItem)
--    UIHelper.SetVisible(self.WidgetEmptyEquip, not bHasItem)
--    UIHelper.SetVisible(self.WidgetEquip, bHasItem)
--    UIHelper.SetVisible(self.WidgetAniRight, bHasItem)
--end

function UIWidgetStrip:UpdateMoney(bCanUnstrength, nCost)
    local btnState = bCanUnstrength and BTN_STATE.Normal or BTN_STATE.Disable
    local msg = "不满足剥离条件"

    UIHelper.SetVisible(self.RichTextMoney, bCanUnstrength and nCost and nCost > 0)
    if bCanUnstrength and nCost and nCost > 0 then
        local nGold, nSilver, nCooper = UIHelper.MoneyToGoldSilverAndCopper(nCost)
        local tEnough, szCannotProduce = PowerUpView.CheckRefineCost(nCost, 0, 0)
        msg = szCannotProduce

        local szMoney = "金钱: " .. UIHelper.GetMoneyText(PackMoney(nGold, nSilver, nCooper), 24, nil, nil)
        local colMoney = tEnough.Money and NORMAL_COLOR or UNSATISFIED_COLOR
        szMoney = GetFormatText(szMoney, nil, table.unpack(colMoney))
        UIHelper.SetRichText(self.RichTextMoney, szMoney)
    end

    UIHelper.SetButtonState(self.BtnStrip, btnState, function()
        OutputMessage("MSG_ANNOUNCE_NORMAL", msg)
    end)
end

function UIWidgetStrip:UpdateDiamondBox(bCanUnstrength, tDiamond)
    if not bCanUnstrength then
        self:ClearDiamond()
    else
        local nIndex = 1

        for _, pDiamond in ipairs(tDiamond) do
            local dwTabType, dwIndex
            local nCount = 0

            if type(pDiamond) == "table" then
                dwTabType, dwIndex, nCount = pDiamond[1], pDiamond[2], pDiamond[3]
            else
                dwTabType = pDiamond.dwTabType
                dwIndex = pDiamond.dwIndex
                nCount = pDiamond.bCanStack and pDiamond.nStackNum or 0
            end

            for i = 1, nCount do
                self.materialScripts[nIndex]:RefreshInfo(EQUIP_REFINE_SLOT_TYPE.DISPLAY, nil, pDiamond.nUiId, pDiamond.nQuality)
                UIHelper.SetVisible(self.materialScripts[nIndex].BtnCell, true)
                UIHelper.BindUIEvent(self.materialScripts[nIndex].BtnCell, EventType.OnClick, function()
                    if not self.scriptItemTip then
                        self.scriptItemTip = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetItemTipsShell)
                    end
                    self.scriptItemTip:OnInitWithTabID(dwTabType, dwIndex)
                    self. scriptItemTip:SetBtnState({})
                end)
                nIndex = nIndex + 1
            end
        end

        for i = nIndex, BOX_COUNT, 1 do
            local itemScript = self.materialScripts[i]
            local slotType = EQUIP_REFINE_SLOT_TYPE.EMPTY
            itemScript:RefreshInfo(slotType)
        end
    end
end

function UIWidgetStrip:ClearData()
    self:ClearDiamond()
    UIHelper.SetVisible(self.WidgetGoods, false)
    UIHelper.SetVisible(self.ImgDefaultSlot, false)
end

function UIWidgetStrip:ClearDiamond()
    for i = 1, BOX_COUNT, 1 do
        local itemScript = self.materialScripts[i]
        local slotType = EQUIP_REFINE_SLOT_TYPE.EMPTY
        itemScript:RefreshInfo(slotType)
    end
end

function UIWidgetStrip:StartStrip()
    if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.OPERATE_DIAMOND, "OPERATE_DIAMOND") then
        return
    end
    if DataModel.nStripType == StripType.EquipSlot and DataModel.tEquipBoxSelect and DataModel.tEquipBoxSelect[1] then
        local nEquipInv = DataModel.tEquipBoxSelect[1]
        local szEquipSlotName = DataModel.tEquipBoxSelect[2]
        if nEquipInv == EQUIPMENT_INVENTORY.BIG_SWORD then
            nEquipInv = EQUIPMENT_INVENTORY.MELEE_WEAPON
        end

        UIHelper.ShowConfirm(FormatString(g_tStrings.STR_EQUIPBOX_EXTRACT_CONFIRM, szEquipSlotName), function()
            RemoteCallToServer("OnUnStrengthEquipbox", nEquipInv)
        end)
    elseif DataModel.nStripType == StripType.Equip and DataModel.dwBox and DataModel.dwX then
        local pItem = ItemData.GetPlayerItem(g_pClientPlayer, DataModel.dwBox, DataModel.dwX)
        if pItem then
            if DataModel.bRare then
                RemoteCallToServer("OnUnstrengthOrangeWeapon", DataModel.dwTargetID, DataModel.dwBox, DataModel.dwX, pItem.dwID)
            else
                RemoteCallToServer("OnUnStrengthEquip", DataModel.dwBox, DataModel.dwX, pItem.dwID)
            end
        end
    end
end

function UIWidgetStrip:PlayAnim(szAnimeName)
    UIHelper.PlayAni(self, self.AniAll, szAnimeName)
end

function UIWidgetStrip:ResetState(nEquip)
    if nEquip then
        DataModel.SetSelectBox(nEquip)
        self:UpdateInfo()
        self.WidgetEquipSlotList:SetSelected(nEquip)
    end
end


return UIWidgetStrip
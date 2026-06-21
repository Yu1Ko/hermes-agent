local UIPanelPowerUp = class("UIPanelPowerUp")

local nViewIdToTab = {
    [PREFAB_ID.WidgetEquipBarRefine] = 1,
    [PREFAB_ID.WidgetFusionInsert] = 2,
    [PREFAB_ID.WidgetEnchant] = 3,
    [PREFAB_ID.WidgetStrip] = 4,
    [PREFAB_ID.WidgetRefineUpgrade] = 5,
}

local nViewIdToAnimShow = {
    [PREFAB_ID.WidgetEquipBarRefine] = "AniEquipBarRefineShow",
    [PREFAB_ID.WidgetFusionInsert] = "AniFusionInsertShow",
    [PREFAB_ID.WidgetEnchant] = "AniEnchantShow",
    [PREFAB_ID.WidgetStrip] = "AniStripShow",
    [PREFAB_ID.WidgetRefineUpgrade] = "AniRefineUpgradeShow",
}

DataModel = {
    materialDict = {}
}

LoadScriptFile(UIHelper.UTF8ToGBK("scripts/player/include/NewPlayerStrength.lua"), DataModel)

PowerUpView = {}

local nMaxWeaponBindNum = 6

function DataModel.Init()
    DataModel.UpdateEquipList()
    DataModel.UpdateBindWeaponInfo()
    DataModel.SetSelect(EQUIPMENT_INVENTORY.HELM)
    DataModel.tEquipBoxLevelRecord = {}
end

function DataModel.UnInit()
    DataModel.tEquipBoxList = nil
    DataModel.tEquipBoxSelect = nil
    DataModel.tEquipBoxLevelRecord = nil
    DataModel.tBindWeaponInfo = nil
end

function DataModel.UpdateEquipList(bIsInfusionInlay)
    local dwForceID = GetClientPlayer().dwForceID
    local tList = {}
    if dwForceID == FORCE_TYPE.CANG_JIAN then
        tList = clone(g_tStrings.tEquipBoxCasting_CangJian)
    else
        tList = clone(g_tStrings.tEquipBoxCasting)
    end

    --if bIsInfusionInlay then
    --    ---如果是装备栏融嵌则去掉戒指槽位
    --    --LOG.WARN("bIsInfusionInlay")
    --    for i = #tList, 1, -1 do
    --        local v = tList[i]
    --        if v[1] == EQUIPMENT_INVENTORY.LEFT_RING or v[1] == EQUIPMENT_INVENTORY.RIGHT_RING then
    --            table.remove(tList, i)
    --        end
    --    end
    --end

    DataModel.tEquipBoxList = tList
end

function DataModel.GetSelect(nIndex)
    if nIndex then
        return DataModel.tEquipBoxSelect[nIndex]
    else
        return DataModel.tEquipBoxSelect
    end
end

function DataModel.SetSelect(nEquipInv)
    local bFind = false
    for _, v in ipairs(DataModel.tEquipBoxList) do
        if v[1] == nEquipInv then
            DataModel.tEquipBoxSelect = v
            bFind = true
            break
        end
    end
    if not bFind then
        DataModel.tEquipBoxSelect = DataModel.tEquipBoxList[1]
    end
end

function DataModel.GetRefineBoxInfo(nEquip)
    if nEquip == EQUIPMENT_INVENTORY.BIG_SWORD then
        --藏剑重剑对应轻剑装备栏
        nEquip = EQUIPMENT_INVENTORY.MELEE_WEAPON
    end

    local nBoxLevel, nBoxQuality = g_pClientPlayer.GetEquipBoxStrength(nEquip)
    local nBoxMaxLevel, nBoxMaxQuality = GetEquipBoxMaxStrengthInfo(nEquip)
    return {
        nLevel = nBoxLevel,
        nMaxLevel = nBoxMaxLevel,
        nQuality = nBoxQuality,
        nMaxQuality = nBoxMaxQuality,
    }
end

function DataModel.GetEquipItem(nEquip)
    if not nEquip then
        nEquip = DataModel.GetSelect(1)
    end
    return g_pClientPlayer.GetEquipItem(nEquip)
end

function DataModel.IsShowEquipAttri(tInfo)
    local bShow = false
    if tInfo and tInfo.nBoxLevel < tInfo.nBoxMaxLevel then
        if tInfo.nEquipLevel <= tInfo.nEquipMaxLevel and tInfo.nBoxLevel <= tInfo.nEquipMaxLevel then
            bShow = true
        end
    end
    return bShow
end

function DataModel.GetStrength(pItem, bItem, tSource)
    local tInfo = {   -- Equip:装备属性  Box:装备栏属性  Quality:品质等级
        nEquipLevel = 0,
        nEquipMaxLevel = 0,
        nBoxLevel = 0,
        nBoxMaxLevel = 0,
        nBoxQuality = 0,
        nTrueLevel = 0,
        bBoxAttr = 0,
        szTip = ""
    }
    local nEquipQuality = 0
    local nEquipInv
    if pItem then
        nEquipInv = tSource and tSource.dwX or GetEquipInventory(pItem.nSub, pItem.nDetail)
        if nEquipInv == EQUIPMENT_INVENTORY.BIG_SWORD then
            nEquipInv = EQUIPMENT_INVENTORY.MELEE_WEAPON
        end

        nEquipQuality = pItem.nLevel
        if bItem then
            tInfo.nEquipLevel = pItem.nStrengthLevel or 0
            tInfo.nEquipMaxLevel = GetItemInfo(pItem.dwTabType, pItem.dwIndex).nMaxStrengthLevel or 0
        else
            -- ItemInfo走这里
            tInfo.nEquipLevel = 0
            tInfo.nEquipMaxLevel = pItem.nMaxStrengthLevel or 0
        end
    end

    local pPlayer = g_pClientPlayer
    if pPlayer and nEquipInv then
        -- 藏剑重剑对应轻剑装备栏
        if nEquipInv == EQUIPMENT_INVENTORY.BIG_SWORD then
            nEquipInv = EQUIPMENT_INVENTORY.MELEE_WEAPON
        end

        local nBoxLevel, nBoxQuality = pPlayer.GetEquipBoxStrength(nEquipInv)
        tInfo.nBoxLevel = nBoxLevel or 0
        tInfo.nBoxQuality = nBoxQuality or 0
        tInfo.nBoxMaxLevel = GetEquipBoxMaxStrengthInfo(nEquipInv)

        if nEquipQuality <= tInfo.nBoxQuality then
            -- 检查品质等级
            if tInfo.nBoxLevel >= tInfo.nEquipLevel then
                -- 检查装备栏等级
                if tInfo.nBoxLevel <= tInfo.nEquipMaxLevel then
                    -- 检查装备等级上限
                    tInfo.nTrueLevel = tInfo.nBoxLevel
                    tInfo.bBoxAttr = true
                else
                    -- 装备栏等级溢出
                    tInfo.nTrueLevel = tInfo.nEquipMaxLevel
                    tInfo.bBoxAttr = true
                    --tInfo.szTip = g_tStrings.EQUIPBOX_ERROR_LEVEL_HIGH
                end
            else
                -- 装备栏等级偏低
                tInfo.nTrueLevel = tInfo.nEquipLevel
                tInfo.bBoxAttr = false
                --tInfo.szTip = g_tStrings.EQUIPBOX_ERROR_LEVEL_LOW
            end
        else
            -- 装备栏品质不足
            tInfo.nTrueLevel = tInfo.nEquipLevel
            tInfo.bBoxAttr = false
            if tInfo.nBoxLevel > 0 then
                tInfo.szTip = g_tStrings.EQUIPBOX_ERROR_QUALITY_LOW
            end
        end
    else
        -- 此部位尚未穿戴
        tInfo.nTrueLevel = tInfo.nEquipLevel
        tInfo.bBoxAttr = false
        tInfo.szTip = g_tStrings.EQUIPBOX_ERROR_NO_EQUIP
    end
    return tInfo
end

function DataModel.GetSlotBoxInfo(nEquip, nSlotIndex, pPlayer)
    if not pPlayer then
        pPlayer = g_pClientPlayer
    end
    if nEquip == EQUIPMENT_INVENTORY.BIG_SWORD then
        --藏剑重剑对应轻剑装备栏
        nEquip = EQUIPMENT_INVENTORY.MELEE_WEAPON
    end
    local dwEnchantID, nBoxQuality = pPlayer.GetEquipBoxMountDiamondEnchantID(nEquip, nSlotIndex)
    local nMaxQuality, bCanMount = GetEquipBoxDiamondSlotInfo(nEquip, nSlotIndex)
    return {
        dwEnchantID = dwEnchantID,
        nQuality = nBoxQuality,
        nMaxQuality = nMaxQuality,
        bCanMount = bCanMount,
    }
end

function DataModel.AddItem(item)
    if item then
        local dwIndex = item.dwIndex
        local nTargetStackNum = ItemData.GetItemStackNum(item)
        --LOG.INFO("UICharacterWidgetEquipRefine itemID %d %d %d", item.dwID, item.nUiId, item.dwIndex)
        DataModel.materialDict[dwIndex] = DataModel.materialDict[dwIndex] or { totalCount = 0, list = {} }
        DataModel.materialDict[dwIndex].totalCount = DataModel.materialDict[dwIndex].totalCount + nTargetStackNum

        local list = DataModel.materialDict[dwIndex].list
        local nIndex = #list + 1

        ---队列按道具数量升序排列，以插入的方式添加道具
        for i = #list, 1, -1 do
            local nStack = ItemData.GetItemStackNum(list[i])
            if nStack >= nTargetStackNum then
                nIndex = i
            else
                break
            end
        end

        table.insert(DataModel.materialDict[dwIndex].list, nIndex, item)
    end
end

function DataModel.GetFirstAvailableItemInList(dwIndex, tChosenMaterialCountDict)
    local itemList = DataModel.GetItemList(dwIndex)
    local currentUsedItemCount = tChosenMaterialCountDict[dwIndex] or 0
    if itemList then
        for i = 1, #itemList, 1 do
            local item = itemList[i]
            local remaining = ItemData.GetItemStackNum(item) - currentUsedItemCount
            if remaining > 0 then
                return item
            else
                currentUsedItemCount = currentUsedItemCount - ItemData.GetItemStackNum(item)
            end
        end
    end
    return nil
end

function DataModel.GetItemList(dwIndex)
    if DataModel.materialDict[dwIndex] then
        return DataModel.materialDict[dwIndex].list
    else
        LOG.ERROR("UICharacterWidgetEquipRefine GetItemList dwIndex invalid")
    end
end

function DataModel.GetItemCount(dwIndex)
    if DataModel.materialDict[dwIndex] then
        return DataModel.materialDict[dwIndex].totalCount
    else
        LOG.ERROR("UICharacterWidgetEquipRefine GetItemCount dwIndex invalid")
    end
end

function DataModel.ClearMaterial()
    DataModel.materialDict = {}
end

function DataModel.UpdateBindWeaponInfo()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    DataModel.tBindWeaponInfo = hPlayer.GetColorDiamondSlotBindWeaponInfo()
end

function DataModel.GetBindWeaponInfo(nWeaponIndex)
    if DataModel.tBindWeaponInfo then
        return DataModel.tBindWeaponInfo[nWeaponIndex]
    end
end

function DataModel.GetBindWeaponCount()
    local nCount = 0
    for nIndex = 1, nMaxWeaponBindNum, 1 do
        local tBindInfo = DataModel.GetBindWeaponInfo(nIndex)
        if tBindInfo and tBindInfo[1] ~= 0 and tBindInfo[2] ~= 0 then
            nCount = nCount + 1
        end
    end
    return nCount
end

function DataModel.CheckIsRefineOrFusionIneffective(nEquip)
    local MAX_SLOT_NUM = 3
    local tEquipBoxInfo = DataModel.GetRefineBoxInfo(nEquip)
    local pItem = DataModel.GetEquipItem(nEquip)

    if not tEquipBoxInfo then
        return false
    end

    -- 查看装备栏精炼等级是否生效
    local nBoxQuality = tEquipBoxInfo.nQuality
    local nBoxMaxQuality = tEquipBoxInfo.nMaxQuality
    local nTempBoxQuality = nBoxQuality == 0 and nBoxMaxQuality or nBoxQuality -- 槽位品质为0时视为最高品质状态
    local bNotRefineEffective = not pItem or pItem.nLevel > nTempBoxQuality -- 未穿戴装备或装备品级大于槽位品质时显示未生效文字

    -- 查看装备栏熔嵌石头是否生效
    local bNotFusionEffective = false
    for i = 1, MAX_SLOT_NUM, 1 do
        local tInfo = DataModel.GetSlotBoxInfo(nEquip, i - 1)
        if tInfo and tInfo.bCanMount then
            local nQuality = tInfo.nQuality
            if pItem and nQuality ~= 0 and pItem.nLevel > nQuality then
                bNotFusionEffective = true
                break
            end
        end
    end

    return bNotRefineEffective, bNotFusionEffective
end

--藏剑当前装备栏上五彩石是否生效
function DataModel.IsEquipBoxColorDiamondApply()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local nEquipIndex = DataModel.GetSelect(1)
    if (nEquipIndex ~= EQUIPMENT_INVENTORY.BIG_SWORD and hPlayer.bBigSwordSelected) or
            (nEquipIndex == EQUIPMENT_INVENTORY.BIG_SWORD and not hPlayer.bBigSwordSelected) then
        return false
    end
    return true
end

function PowerUpView.CheckRefineCost(nCostMoney, nCostVigor, nCostTrain)
    local bEnoughMoney, bEnoughTrain, bEnoughVigor = true, true, true
    local szCannotProduce = ""
    local nGold, nSilver, nCopper = UIHelper.MoneyToGoldSilverAndCopper(nCostMoney)

    local pPlayer = g_pClientPlayer
    bEnoughVigor = pPlayer.IsVigorAndStaminaEnough(nCostVigor)
    if not bEnoughVigor then
        szCannotProduce = g_tStrings.STR_REFINE_NOT_ENOUGH_VIGOR
    end
    if MoneyOptCmp(pPlayer.GetMoney(), { nGold = nGold, nSilver = nSilver, nCopper = nCopper }) < 0 then
        bEnoughMoney = false
        szCannotProduce = g_tStrings.STR_REFINE_NOT_ENOUGH_MONEY
    end
    if pPlayer.nCurrentTrainValue < nCostTrain then
        bEnoughTrain = false
        szCannotProduce = g_tStrings.tDiamondResultCode[DIAMOND_RESULT_CODE.NOT_ENOUGH_TRAIN_FOR_COST]
    end

    return {
        Money = bEnoughMoney,
        Train = bEnoughTrain,
        Vigor = bEnoughVigor,
    }, szCannotProduce
end

local m_tEquipSubToInventory = {
    [EQUIPMENT_SUB.HELM] = EQUIPMENT_INVENTORY.HELM,
    [EQUIPMENT_SUB.CHEST] = EQUIPMENT_INVENTORY.CHEST,
    [EQUIPMENT_SUB.WAIST] = EQUIPMENT_INVENTORY.WAIST,
    [EQUIPMENT_SUB.BANGLE] = EQUIPMENT_INVENTORY.BANGLE,
    [EQUIPMENT_SUB.PANTS] = EQUIPMENT_INVENTORY.PANTS,
    [EQUIPMENT_SUB.BOOTS] = EQUIPMENT_INVENTORY.BOOTS,
    [EQUIPMENT_SUB.AMULET] = EQUIPMENT_INVENTORY.AMULET,
    [EQUIPMENT_SUB.PENDANT] = EQUIPMENT_INVENTORY.PENDANT,
    [EQUIPMENT_SUB.RING] = EQUIPMENT_INVENTORY.LEFT_RING, -- 戒指默认用戒指一的装备栏属性
    [EQUIPMENT_SUB.MELEE_WEAPON] = EQUIPMENT_INVENTORY.MELEE_WEAPON, -- EQUIPMENT_INVENTORY.BIG_SWORD特殊处理
    [EQUIPMENT_SUB.RANGE_WEAPON] = EQUIPMENT_INVENTORY.RANGE_WEAPON,
}

function GetEquipInventory(nSub, nDetail)
    local nEquipInv = m_tEquipSubToInventory[nSub]
    if nDetail and nDetail == WEAPON_DETAIL.BIG_SWORD and nSub == EQUIPMENT_SUB.MELEE_WEAPON then
        nEquipInv = EQUIPMENT_INVENTORY.BIG_SWORD
    end
    return nEquipInv
end

local MAX_WEAPON_PLAN = 6
function GetBindWeapon(nWeaponIndex, nEquipIndex)
    local tInfo = {}
    local tEmptyInfo = nil

    if nWeaponIndex ~= 0 then
        --绑定方案中
        local t = DataModel.GetBindWeaponInfo(nWeaponIndex)
        tInfo.dwItemType = t[1]
        tInfo.dwItemIndex = t[2]
        tInfo.nBindIndex = nWeaponIndex
        return tInfo
    end

    local KItemWeapon = DataModel.GetEquipItem(nEquipIndex)
    if not KItemWeapon then
        return tInfo
    end

    for k, v in pairs(DataModel.tBindWeaponInfo) do
        if v[1] == KItemWeapon.dwTabType and v[2] == KItemWeapon.dwIndex then
            tInfo.dwItemType = v[1]
            tInfo.dwItemIndex = v[2]
            tInfo.nBindIndex = k
            return tInfo
        end
    end

    for i = 1, MAX_WEAPON_PLAN do
        local v = DataModel.tBindWeaponInfo[i]
        if not tEmptyInfo and v[1] == 0 and v[2] == 0 then
            --空位置
            tInfo.dwItemType = KItemWeapon.dwTabType
            tInfo.dwItemIndex = KItemWeapon.dwIndex
            tInfo.nBindIndex = i
            tInfo.nStoneIndex = v[3]
            break
        end
    end

    return tInfo
end

local szColorActivated = "#95FF95"
local szAttrActivated = "#70FFBB"
local szColorInactivated = "#94ACB9"
function GetColorDiamondInfo(nEnchantID)
    local dwWeaponBox, dwWeaponX
    if g_pClientPlayer.bBigSwordSelected then
        dwWeaponBox, dwWeaponX = INVENTORY_INDEX.EQUIP, EQUIPMENT_INVENTORY.BIG_SWORD
    else
        dwWeaponBox, dwWeaponX = INVENTORY_INDEX.EQUIP, EQUIPMENT_INVENTORY.MELEE_WEAPON
    end

    local szContent = " "
    local szTmp = ""
    local bCurrentEnchant = false
    if nEnchantID > 0 then
        local KItemWeapon = DataModel.GetEquipItem(dwWeaponX)
        if KItemWeapon then
            for k, v in pairs(DataModel.tBindWeaponInfo) do
                if v[1] == KItemWeapon.dwTabType and v[2] == KItemWeapon.dwIndex then
                    if v[3] > 0 then
                        local dwEnchantID, nCurLevel = g_pClientPlayer.GetColorDiamondSlotInfo(v[3])
                        bCurrentEnchant = dwEnchantID == nEnchantID
                    else
                        local dwEnchantID = KItemWeapon.GetMountFEAEnchantID()
                        bCurrentEnchant = dwEnchantID == nEnchantID
                    end
                    break
                end
            end
        end

        local aAttr = GetFEAInfoByEnchantID(nEnchantID)
        for k, v in pairs(aAttr) do
            --LOG.TABLE(v)
            if v.nID ~= ATTRIBUTE_TYPE.SKILL_EVENT_HANDLER then
                EquipData.FormatAttributeValue(v)
                local szAttributeColor, szConditionColor = szColorInactivated, szColorInactivated
                if bCurrentEnchant and GetFEAActiveFlag(g_pClientPlayer.dwID, dwWeaponBox, dwWeaponX, tonumber(k) - 1) then
                    szAttributeColor = szAttrActivated
                    szConditionColor = szColorActivated
                end

                local szText = FormatString(g_tStrings.tActivation.COLOR_ATTRIBUTE, k)
                if v.nID == ATTRIBUTE_TYPE.SKILL_EVENT_HANDLER then
                    local skillEvent = g_tTable.SkillEvent:Search(v.nValue1)
                    if skillEvent then
                        szTmp = FormatString(skillEvent.szDesc, v.nValue1, v.nValue2)
                    else
                        szTmp = "<text>text=\"unknown skill event id:" .. v.nValue1 .. "\"</text>"
                    end
                else
                    szTmp = UIHelper.GBKToUTF8(FormatString(Table_GetMagicAttributeInfo(v.nID, true), v.nValue1, v.nValue2, MAGIC_ATTRI_DEF, MAGIC_ATTRI_DEF))
                end
                local szPText = szText .. string.pure_text(szTmp)
                local szDesc = szPText
                szDesc = string.format("<color=%s>%s</color>", szAttributeColor, szDesc)

                local szName = g_tStrings.STR_DIAMOND
                szText = FormatString(g_tStrings.tActivation.COLOR_CONDITION, k)

                szTmp = FormatString(g_tStrings.tActivation.COLOR_CONDITION1, szName, g_tStrings.tActivation.COLOR_COMPARE[v.nCompare], v.nDiamondCount)
                szText = szText .. szTmp

                szTmp = FormatString(g_tStrings.tActivation.COLOR_CONDITION2, szName, v.nDiamondIntensity) ---第二行
                szText = szText .. "\n" .. szTmp

                szText = string.format("<color=%s>%s</color>", szConditionColor, szText)

                szDesc = szDesc .. "\n" .. szText

                szContent = szContent ~= " " and table.concat({ szContent, "\n\n", szDesc }) or szDesc
            end
        end
    end
    return szContent
end

function GetColorDiamondInfoTable(nEnchantID)
    local res = {}
    local dwWeaponBox, dwWeaponX
    if g_pClientPlayer.bBigSwordSelected then
        dwWeaponBox, dwWeaponX = INVENTORY_INDEX.EQUIP, EQUIPMENT_INVENTORY.BIG_SWORD
    else
        dwWeaponBox, dwWeaponX = INVENTORY_INDEX.EQUIP, EQUIPMENT_INVENTORY.MELEE_WEAPON
    end

    local bCurrentEnchant = false
    if nEnchantID > 0 then
        local KItemWeapon = DataModel.GetEquipItem(dwWeaponX)
        if KItemWeapon then
            for k, v in pairs(DataModel.tBindWeaponInfo) do
                if v[1] == KItemWeapon.dwTabType and v[2] == KItemWeapon.dwIndex then
                    if v[3] > 0 then
                        local dwEnchantID, nCurLevel = g_pClientPlayer.GetColorDiamondSlotInfo(v[3])
                        bCurrentEnchant = dwEnchantID == nEnchantID
                    else
                        local dwEnchantID = KItemWeapon.GetMountFEAEnchantID()
                        bCurrentEnchant = dwEnchantID == nEnchantID
                    end
                    break
                end
            end
        end

        local aAttr = GetFEAInfoByEnchantID(nEnchantID)
        for k, v in pairs(aAttr) do
            if v.nID ~= ATTRIBUTE_TYPE.SKILL_EVENT_HANDLER then
                EquipData.FormatAttributeValue(v)
                local bActivated = false
                if bCurrentEnchant and GetFEAActiveFlag(g_pClientPlayer.dwID, dwWeaponBox, dwWeaponX, tonumber(k) - 1) then
                    bActivated = true
                end

                local szTmp = ""
                if v.nID == ATTRIBUTE_TYPE.SKILL_EVENT_HANDLER then
                    local skillEvent = g_tTable.SkillEvent:Search(v.nValue1)
                    if skillEvent then
                        szTmp = FormatString(skillEvent.szDesc, v.nValue1, v.nValue2)
                    else
                        szTmp = "<text>text=\"unknown skill event id:" .. v.nValue1 .. "\"</text>"
                    end
                else
                    szTmp = UIHelper.GBKToUTF8(FormatString(Table_GetMagicAttributeInfo(v.nID, true), v.nValue1, v.nValue2, MAGIC_ATTRI_DEF, MAGIC_ATTRI_DEF))
                end

                local temp = {
                    szAttributeName = string.pure_text(szTmp),
                    nDiamondCount = v.nDiamondCount,
                    nDiamondIntensity = v.nDiamondIntensity,
                    bActivated = bActivated,
                }
                table.insert(res, temp)
            end
        end
    end
    return res
end

-- OnRemoteCall.OnWeaponBindColorDiamond
function AppendWeapon(nIndex, dwBox, dwX)
    if dwBox == -1 or dwX == -1 then
        return
    end

    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local tItem = hPlayer.GetItem(dwBox, dwX)
    if not tItem or tItem.nSub ~= EQUIPMENT_SUB.MELEE_WEAPON then
        return
    end

    RemoteCallToServer("OnSetColorDiamondBind", tItem.dwTabType, tItem.dwIndex, 0, nIndex)
end

function RemoveWeapon(dwItemType, dwItemIndex)
    if not dwItemType or dwItemType == 0 or not dwItemIndex or dwItemIndex == 0 then
        return
    end
    RemoteCallToServer("OnDeleteColorDiamondBind", dwItemType, dwItemIndex)
end

local tTabName = {
    [1] = "装备栏精炼",
    [2] = "装备栏熔嵌",
    [3] = "装备附魔",
    [4] = "精炼剥离",
    [5] = "材料升级",
}

MAX_FRAME_VISIBLE_LEVEL = 6

function UIPanelPowerUp:OnEnter(nSubViewID, dwBox, dwX)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        self.equipRefineScript = nil
        self.equipFusionInlayScript = nil
        self.tEnchantItem = nil
        self.dwBox = nil
        self.dwX = nil
        self.bColor = false
        self.tSubViewScripts = {}

        self.nViewIdToContentNode = {
            [PREFAB_ID.WidgetEquipBarRefine] = self.EquipRefineContent,
            [PREFAB_ID.WidgetFusionInsert] = self.EquipFusionInlayContent,
            [PREFAB_ID.WidgetEnchant] = self.EquipEnchantContent,
            [PREFAB_ID.WidgetStrip] = self.EquipStripContent,
            [PREFAB_ID.WidgetRefineUpgrade] = self.RefineStoneContent,
        }

        DataModel.Init()

        for index, tog in ipairs(self.tbPageToggle) do
            UIHelper.SetToggleGroupIndex(tog, ToggleGroupIndex.EquipPowerUp)
        end

        UIHelper.AddPrefab(PREFAB_ID.WidgetCurrency, self.LayoutCurrency)

        self.vigorScript = UIHelper.AddPrefab(PREFAB_ID.WidgetOtherCurrency, self.LayoutCurrency)
        self.vigorScript:SetCurrencyType(CurrencyType.Vigor)
        self.vigorScript:HandleEvent(CurrencyType.Vigor)
        UIHelper.SetAnchorPoint(self.vigorScript._rootNode, 0, 0.5)

        self.trainScript = UIHelper.AddPrefab(PREFAB_ID.WidgetOtherCurrency, self.LayoutCurrency)
        self.trainScript:SetCurrencyType(CurrencyType.Train)
        self.trainScript:HandleEvent()
        UIHelper.SetAnchorPoint(self.trainScript._rootNode, 0, 0.5)

        UIHelper.LayoutDoLayout(self.LayoutCurrency)
    end

    local nEquip = nil
    if dwBox and dwX then
        if IsNumber(dwBox) and IsNumber(dwX) then
            local pItem = ItemData.GetItemByPos(dwBox, dwX) -- 可能为五彩石或装备
            if dwBox == INVENTORY_INDEX.EQUIP then
                nEquip = dwX
            elseif pItem.nGenre == ITEM_GENRE.COLOR_DIAMOND then
                nEquip = EQUIPMENT_INVENTORY.MELEE_WEAPON
                self.bColor = true
            else
                nEquip = GetEquipInventory(pItem.nSub, pItem.nDetail)
            end
            self.nInitEquip = nEquip
        end

        self.dwBox = dwBox
        self.dwX = dwX
        DataModel.SetSelect(nEquip)
    elseif dwBox and not IsNumber(dwBox) and dwBox.nGenre == ITEM_GENRE.ENCHANT_ITEM then
        self.dwBox = dwBox -- 传入的参数为附魔item
    end

    nSubViewID = nSubViewID or PREFAB_ID.WidgetEquipBarRefine
    if not self.nSelectedView or self.nSelectedView ~= nSubViewID then
        local tabID = nSubViewID and nViewIdToTab[nSubViewID] or 1
        if tabID ~= 1 then
            UIHelper.SetSelected(self.tbPageToggle[tabID], true)
        else
            UIHelper.SetSelected(self.tbPageToggle[1], true, true)
        end
    end
    self:UpdateIneffectiveLabel()
end

function UIPanelPowerUp:OnExit()
    self.bInit = false
    UIHelper.RemoveAllChildren(self.LayoutSalesmanList)
end

function UIPanelPowerUp:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.TogEquipBarRefine, EventType.OnSelectChanged, function(toggle, bState)
        self:OnSelected(PREFAB_ID.WidgetEquipBarRefine, bState, self.nInitEquip)
    end)

    UIHelper.BindUIEvent(self.TogFusionInsert, EventType.OnSelectChanged, function(toggle, bState)
        self:OnSelected(PREFAB_ID.WidgetFusionInsert, bState, self.nInitEquip, self.bColor)
    end)

    UIHelper.BindUIEvent(self.TogEnchant, EventType.OnSelectChanged, function(toggle, bState)
        self:OnSelected(PREFAB_ID.WidgetEnchant, bState, self.dwBox, self.dwX)
    end)

    UIHelper.BindUIEvent(self.TogStrip, EventType.OnSelectChanged, function(toggle, bState)
        self:OnSelected(PREFAB_ID.WidgetStrip, bState, self.nStripEquip or self.nInitEquip)
    end)

    UIHelper.BindUIEvent(self.TogRefineUpgrade, EventType.OnSelectChanged, function(toggle, bState)
        self:OnSelected(PREFAB_ID.WidgetRefineUpgrade, bState)
    end)
end

function UIPanelPowerUp:RegEvent()
    Event.Reg(self, "DO_CUSTOM_OTACTION_PROGRESS", function(nTotalFrame, szActionName, nType)
        if (not UIMgr.IsViewOpened(VIEW_ID.PanelSystemPrograssBar)) and nTotalFrame and nTotalFrame > 0 then
            local tParam = {
                szType = "Normal",
                szFormat = UIHelper.GBKToUTF8(szActionName),
                bNotShowDescribe = true,
                szIconPath = "UIAtlas2_Public_PublicSystemProgress_PublicSystemProgress_Equipment",
                nDuration = nTotalFrame / GLOBAL.GAME_FPS,
                fnCancel = function()
                    GetClientPlayer().StopCurrentAction()
                end
            }
            UIMgr.Open(VIEW_ID.PanelSystemPrograssBar, tParam)
        end
    end)

    Event.Reg(self, "FE_STRENGTH_EQUIP", function(arg0)
        if arg0 == DIAMOND_RESULT_CODE.SUCCESS then
            self:UpdateIneffectiveLabel()
        end
    end)

    Event.Reg(self, "MOUNT_DIAMON", function(arg0)
        if arg0 == DIAMOND_RESULT_CODE.SUCCESS then
            self:UpdateIneffectiveLabel()
        end
    end)

    Event.Reg(self, "EQUIP_UNSTRENGTH", function(arg0, arg1)
        if arg0 == DIAMOND_RESULT_CODE.SUCCESS then
            self:UpdateIneffectiveLabel()
        end
    end)
end

function UIPanelPowerUp:OnSelected(nSubViewID, bState, ...)
    local nTabIndex = nViewIdToTab[nSubViewID]
    local tContentNode = self.nViewIdToContentNode[nSubViewID]
    if bState and self.nSelectedView ~= nSubViewID then
        local script = self.tSubViewScripts[nSubViewID]
        if script == nil then
            script = UIHelper.AddPrefab(nSubViewID, tContentNode, ...)
            self.tSubViewScripts[nSubViewID] = script
        elseif script.ResetState then
            script:ResetState(...)
        end

        self.nSelectedView = nSubViewID
        self:SetTitleName(nTabIndex)
        JX_RefineDiamond.StopRefine()
        UIHelper.PlayAni(script, script._rootNode, nViewIdToAnimShow[nSubViewID])
    end
    UIHelper.SetVisible(tContentNode, bState)
end

function UIPanelPowerUp:SetTitleName(nIndex)
    UIHelper.SetString(self.LabelTitle, tTabName[nIndex])
end

function UIPanelPowerUp:OpenStrip(nEquip)
    self.nStripEquip = nEquip
    UIHelper.SetSelected(self.TogStrip, true)
end

function UIPanelPowerUp:UpdateIneffectiveLabel()
    local bShowRefineHint, bShowFusionHint = false, false
    for _, v in ipairs(DataModel.tEquipBoxList) do
        local bEquipRefineNotEffective, bFusionNotEffective = DataModel.CheckIsRefineOrFusionIneffective(v[1])
        bShowRefineHint = bShowRefineHint or bEquipRefineNotEffective
        bShowFusionHint = bShowFusionHint or bFusionNotEffective
    end

    UIHelper.SetVisible(self.WidgetTipEquipBarRefine, bShowRefineHint)
    UIHelper.SetVisible(self.WidgetTipFusionInsert, bShowFusionHint)
end

return UIPanelPowerUp
-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIArenaMasterDIYEquipView
-- Date: 2025-02-12 16:14:40
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIArenaMasterDIYEquipView = class("UIArenaMasterDIYEquipView")
local Equip1Enum = {
    -- 头部
    EQUIPMENT_INVENTORY.HELM,
    -- 上衣
    EQUIPMENT_INVENTORY.CHEST,
    -- 腰带
    EQUIPMENT_INVENTORY.WAIST,
    -- 护腕
    EQUIPMENT_INVENTORY.BANGLE,
    -- 下装
    EQUIPMENT_INVENTORY.PANTS,
    -- 鞋子
    EQUIPMENT_INVENTORY.BOOTS,
}

local Equip2Enum = {
    -- 项链
    EQUIPMENT_INVENTORY.AMULET,
    -- 腰坠
    EQUIPMENT_INVENTORY.PENDANT,
    -- 戒指
    EQUIPMENT_INVENTORY.LEFT_RING,
    -- 戒指
    EQUIPMENT_INVENTORY.RIGHT_RING,
}

local WeaponEnum = {
    -- 普通近战武器
    EQUIPMENT_INVENTORY.MELEE_WEAPON,
    -- 重剑
    EQUIPMENT_INVENTORY.BIG_SWORD,
    -- 远程武器
    EQUIPMENT_INVENTORY.RANGE_WEAPON,
}

local tJJCDIYSuit = {4, 5}

function UIArenaMasterDIYEquipView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:InitCurEquipSelectedData(EQUIPMENT_INVENTORY.HELM)
    self:UpdateInfo()
end

function UIArenaMasterDIYEquipView:OnExit()
    self.bInit = false
end

function UIArenaMasterDIYEquipView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.TogWuCaiSwitch, EventType.OnClick, function(btn)
        local tbList = Table_GetAllColorDiamondList()
        local tbNewList = {}
	    self.tColorDiamond = self.tColorDiamond or ArenaEquipDIYData.GetColorDiamond()

        local tbColorDiamond = {}
        for _, tbInfo in ipairs(self.tColorDiamond) do
            tbColorDiamond[tbInfo.dwIndex] = true
        end

        for szAttribute3, tb1 in pairs(tbList) do
            for szAttribute2, tb2 in pairs(tb1) do
                for szAttribute1, tb3 in pairs(tb2) do
                    for _, tb4 in ipairs(tb3) do
                        if tbColorDiamond[tb4.dwItemID] then
                            tbNewList[szAttribute3] = tbNewList[szAttribute3] or {}
                            tbNewList[szAttribute3][szAttribute2] = tbNewList[szAttribute3][szAttribute2] or {}
                            tbNewList[szAttribute3][szAttribute2][szAttribute1] = tbNewList[szAttribute3][szAttribute2][szAttribute1] or {}
                            table.insert(tbNewList[szAttribute3][szAttribute2][szAttribute1], tb4)
                        end
                    end
                end
            end
        end
        local scriptView = UIMgr.Open(VIEW_ID.PanelPowerUpMaterialList, "ColorMount", nil, nil, function (tbInfo)
            local dwTabType, dwIndex = 0, 0
            if tbInfo then
                local nID = tbInfo.nEnchantID
                dwTabType, dwIndex = GetColorDiamondInfoFromEnchantID(nID)
            end

            local tCurSelectColorDiamond = {
                dwTabType = dwTabType,
                dwIndex = dwIndex,
            }
            ArenaEquipDIYData.ReqEquip(self.nCurSelectedEquipType, self.tCurSelectEquip, self.tCurSelectEnchant, tCurSelectColorDiamond)
            self:UpdateSelectedState()
        end)

        scriptView:SetResetVis(false)
        scriptView:SetColorMountList(tbNewList)
        scriptView:UpdateColorMountInfo()
    end)

    for i, tog in ipairs(self.tbTogglePreset) do
        UIHelper.BindUIEvent(tog, EventType.OnClick, function(btn)
            self.nCurSuitIndex = tJJCDIYSuit[i]
            RemoteCallToServer("OnExchangeEquipBackUp", self.nCurSuitIndex)
        end)
    end

    local player = PlayerData.GetClientPlayer()
    if player then
        local nIndex = player.GetEquipIDArray(0)
        local nKeyIndex = table.get_key(tJJCDIYSuit, nIndex)
        if nKeyIndex then
            UIHelper.SetToggleGroupSelected(self.WidgetToggleGroupPreset, nKeyIndex - 1)
        end
    end
end

function UIArenaMasterDIYEquipView:RegEvent()
    Event.Reg(self, EventType.HideAllHoverTips, function ()
        self:ClearSelected()
    end)

    Event.Reg(self, "EQUIP_ITEM_UPDATE", function ()
        if self.nEquipUpdateTimerID then
            Timer.DelTimer(self, self.nEquipUpdateTimerID)
            self.nEquipUpdateTimerID = nil
        end

        self.nEquipUpdateTimerID = Timer.Add(self, 0.2, function ()
            self:UpdateAttribInfo()
        end)
    end)

    Event.Reg(self, "EQUIP_CHANGE", function ()
        if self.nEquipChangeTimerID then
            Timer.DelTimer(self, self.nEquipChangeTimerID)
            self.nEquipChangeTimerID = nil
        end

        self.nEquipChangeTimerID = Timer.Add(self, 0.2, function ()
            self:InitCurEquipSelectedData(self.nCurSelectedEquipType)
            self:UpdateInfo()
        end)
    end)

    Event.Reg(self, "ON_JJC_EQUIP_CHANGE", function ()
        if self.nEquipChangeTimerID then
            Timer.DelTimer(self, self.nEquipChangeTimerID)
            self.nEquipChangeTimerID = nil
        end

        self.nEquipChangeTimerID = Timer.Add(self, 0.2, function ()
            self:InitCurEquipSelectedData(self.nCurSelectedEquipType)
            self:UpdateInfo()
        end)
    end)
end

function UIArenaMasterDIYEquipView:UpdateInfo()
    self:UpdateEquipInfo()
    self:UpdateEquipEditInfo()
    self:UpdateAttribInfo()
    self:UpdateSelectedState()
end

function UIArenaMasterDIYEquipView:InitCurEquipSelectedData(nType)
    self.nCurSelectedEquipType = nType
    self.tCurSelectEquip = {}
    self.tCurSelectEnchant = {}
    self.tCurSelectColorDiamond = {}

    self.tEnchant = self.tEnchant or ArenaEquipDIYData.GetEnchant()

    local item = ItemData.GetItemByPos(INVENTORY_INDEX.EQUIP, nType)
    if item then
        self.tCurSelectEquip = {
            dwTabType = item.dwTabType,
            dwIndex = item.dwIndex,
        }

        if item.dwPermanentEnchantID and item.dwPermanentEnchantID > 0 then
            local nEnchantType = nType
            if nEnchantType == EQUIPMENT_INVENTORY.RIGHT_RING then
                nEnchantType = EQUIPMENT_INVENTORY.LEFT_RING
            end
            if nEnchantType == EQUIPMENT_INVENTORY.BIG_SWORD then
                nEnchantType = EQUIPMENT_INVENTORY.MELEE_WEAPON
            end
            local tbEnchant = self.tEnchant[nEnchantType]
            for _, tbInfo in pairs(tbEnchant) do
                local tbEnchantInfo = EnchantData.GetEnchantInfo(tbInfo.dwIndex)
                if tbEnchantInfo.EnchantID == item.dwPermanentEnchantID then
                    self.tCurSelectEnchant = {
                        dwTabType = tbInfo.dwTabType,
                        dwIndex = tbInfo.dwIndex,
                    }
                    break
                end
            end
        end

        local nColorEnchantID = item.GetMountFEAEnchantID()
        if nColorEnchantID and nColorEnchantID > 0 then
            local dwTabType, dwIndex = GetColorDiamondInfoFromEnchantID(nColorEnchantID)
            self.tCurSelectColorDiamond = {
                nEnchantID = nColorEnchantID,
                dwTabType = dwTabType,
                dwIndex = dwIndex,
            }
        end
    else
	    self.tColorDiamond = self.tColorDiamond or ArenaEquipDIYData.GetColorDiamond()
        local tbInfo = self.tColorDiamond[1]
        if tbInfo then
            self.tCurSelectColorDiamond = {
                nEnchantID = tbInfo.nID,
                dwTabType = tbInfo.dwTabType,
                dwIndex = tbInfo.dwIndex,
            }
        end
    end
end

function UIArenaMasterDIYEquipView:UpdateEquipInfo()
    self.tbEquipCell = {}

    local player = PlayerData.GetClientPlayer()
    if not player then
        return
    end

    -- UIHelper.ToggleGroupRemoveAllToggle(self.ToggleGroupEquip)
    for i, nType in ipairs(Equip1Enum) do
        UIHelper.RemoveAllChildren(self.tbWidgetEquip1[i])
		self.tbEquipCell[nType] = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, self.tbWidgetEquip1[i])
        self.tbEquipCell[nType]:OnInit(INVENTORY_INDEX.EQUIP, nType)
        self.tbEquipCell[nType]:UpdatePVPImg()
        self.tbEquipCell[nType]:SetLabelCountVisible(false)
        -- UIHelper.ToggleGroupAddToggle(self.ToggleGroupEquip, self.tbEquipCell[nType].ToggleSelect)
        self.tbEquipCell[nType]:SetClickCallback(function(nBox, nIndex)
            if not self.scriptItemTip then
                self.scriptItemTip = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetItemTips)
                self.scriptItemTip:SetForbidShowEquipCompareBtn(true)
            end
            self.scriptItemTip:SetHideEquipBoxTipsInfo(true)
            self.scriptItemTip:HidePreviewBtn(true)
            if self.nCurSelectedEquipType ~= nType then
                self:InitCurEquipSelectedData(nType)
                self:UpdateEquipEditInfo()
            end
            self:UpdateSelectedState()

            if self.nCurSelectedEquipType == nType then
                self.scriptItemTip:OnInit(INVENTORY_INDEX.EQUIP, nType)
                self.scriptItemTip:SetBtnState({})
            end
        end)

        self.tbEquipCell[nType]:ShowLabelTip(false)

        local item = ItemData.GetItemByPos(INVENTORY_INDEX.EQUIP, nType)
        if item then
            local tbEquipStrengthInfo = EquipData.GetEquipStrengthInfo(player, item, true, nType)
            if tbEquipStrengthInfo and tbEquipStrengthInfo.nEquipMaxLevel > 0 then
                UIHelper.SetVisible(self.tbImgMaxFrameEquip1[i], tbEquipStrengthInfo.nEquipLevel >= tbEquipStrengthInfo.nEquipMaxLevel)
            elseif tbEquipStrengthInfo and tbEquipStrengthInfo.nBoxMaxLevel > 0 then
                UIHelper.SetVisible(self.tbImgMaxFrameEquip1[i], tbEquipStrengthInfo.nBoxLevel == tbEquipStrengthInfo.nBoxMaxLevel)
            else
                UIHelper.SetVisible(self.tbImgMaxFrameEquip1[i], false)
            end
        else
            UIHelper.SetVisible(self.tbImgMaxFrameEquip1[i], false)
        end
	end

    for i, nType in ipairs(Equip2Enum) do
        UIHelper.RemoveAllChildren(self.tbWidgetEquip2[i])
		self.tbEquipCell[nType] = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, self.tbWidgetEquip2[i])
        self.tbEquipCell[nType]:OnInit(INVENTORY_INDEX.EQUIP, nType)
        self.tbEquipCell[nType]:UpdatePVPImg()
        self.tbEquipCell[nType]:SetLabelCountVisible(false)
        -- UIHelper.ToggleGroupAddToggle(self.ToggleGroupEquip, self.tbEquipCell[nType].ToggleSelect)
        self.tbEquipCell[nType]:SetClickCallback(function(nBox, nIndex)
            if not self.scriptItemTip then
                self.scriptItemTip = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetItemTips)
                self.scriptItemTip:SetForbidShowEquipCompareBtn(true)
            end
            self.scriptItemTip:SetHideEquipBoxTipsInfo(true)
            self.scriptItemTip:HidePreviewBtn(true)
            if self.nCurSelectedEquipType ~= nType then
                self:InitCurEquipSelectedData(nType)
                self:UpdateEquipEditInfo()
            end
            self:UpdateSelectedState()

            if self.nCurSelectedEquipType == nType then
                self.scriptItemTip:OnInit(INVENTORY_INDEX.EQUIP, nType)
                self.scriptItemTip:SetBtnState({})
            end
        end)

        self.tbEquipCell[nType]:ShowLabelTip(false)

        local item = ItemData.GetItemByPos(INVENTORY_INDEX.EQUIP, nType)
        if item then
            local tbEquipStrengthInfo = EquipData.GetEquipStrengthInfo(player, item, true, nType)
            if tbEquipStrengthInfo and tbEquipStrengthInfo.nEquipMaxLevel > 0 then
                UIHelper.SetVisible(self.tbImgMaxFrameEquip2[i], tbEquipStrengthInfo.nEquipLevel >= tbEquipStrengthInfo.nEquipMaxLevel)
            elseif tbEquipStrengthInfo and tbEquipStrengthInfo.nBoxMaxLevel > 0 then
                UIHelper.SetVisible(self.tbImgMaxFrameEquip2[i], tbEquipStrengthInfo.nBoxLevel == tbEquipStrengthInfo.nBoxMaxLevel)
            else
                UIHelper.SetVisible(self.tbImgMaxFrameEquip2[i], false)
            end
        else
            UIHelper.SetVisible(self.tbImgMaxFrameEquip2[i], false)
        end
	end

    for i, nType in ipairs(WeaponEnum) do
        local nPrefabID = PREFAB_ID.WidgetItem_100
        if nType == EQUIPMENT_INVENTORY.ARROW then
            nPrefabID = PREFAB_ID.WidgetItem_80
        end
        UIHelper.RemoveAllChildren(self.tbWidgetWeapon[i])
        self.tbEquipCell[nType] = UIHelper.AddPrefab(nPrefabID, self.tbWidgetWeapon[i])
        self.tbEquipCell[nType]:SetLabelCountVisible(nType == EQUIPMENT_INVENTORY.ARROW)
        self.tbEquipCell[nType]:OnInit(INVENTORY_INDEX.EQUIP, nType)
        self.tbEquipCell[nType]:UpdatePVPImg()
        -- UIHelper.ToggleGroupAddToggle(self.ToggleGroupEquip, self.tbEquipCell[nType].ToggleSelect)
        self.tbEquipCell[nType]:SetClickCallback(function(nBox, nIndex)
            if not self.scriptItemTip then
                self.scriptItemTip = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetItemTips)
                self.scriptItemTip:SetForbidShowEquipCompareBtn(true)
            end
            self.scriptItemTip:SetHideEquipBoxTipsInfo(true)
            self.scriptItemTip:HidePreviewBtn(true)
            if self.nCurSelectedEquipType ~= nType then
                self:InitCurEquipSelectedData(nType)
                self:UpdateEquipEditInfo()
            end
            self:UpdateSelectedState()

            if self.nCurSelectedEquipType == nType then
                self.scriptItemTip:OnInit(INVENTORY_INDEX.EQUIP, nType)
                self.scriptItemTip:SetBtnState({})
            end
        end)

        self.tbEquipCell[nType]:ShowLabelTip(false)

        local item = ItemData.GetItemByPos(INVENTORY_INDEX.EQUIP, nType)
        if item then
            local tbEquipStrengthInfo = EquipData.GetEquipStrengthInfo(player, item, true, nType)
            if tbEquipStrengthInfo and tbEquipStrengthInfo.nEquipMaxLevel > 0 then
                UIHelper.SetVisible(self.tbImgMaxFrameWeapon[i], tbEquipStrengthInfo.nEquipLevel >= tbEquipStrengthInfo.nEquipMaxLevel)
            elseif tbEquipStrengthInfo and tbEquipStrengthInfo.nBoxMaxLevel and tbEquipStrengthInfo.nBoxMaxLevel > 0 then
                UIHelper.SetVisible(self.tbImgMaxFrameWeapon[i], tbEquipStrengthInfo.nBoxLevel == tbEquipStrengthInfo.nBoxMaxLevel)
            else
                UIHelper.SetVisible(self.tbImgMaxFrameWeapon[i], false)
            end
        else
            UIHelper.SetVisible(self.tbImgMaxFrameWeapon[i], false)
        end
	end

    local equip = ItemData.GetItemByPos(INVENTORY_INDEX.EQUIP, EQUIPMENT_INVENTORY.BIG_SWORD)
    local bCanUseBigSword = player.bCanUseBigSword
    if equip then
        bCanUseBigSword = true
    end
    -- 藏剑门派使用无相楼心法时，隐藏重剑栏
    local tbKungfu = player.GetActualKungfuMount()
    if tbKungfu and tbKungfu.dwBelongSchool == BELONG_SCHOOL_TYPE.WU_XIANG then
        bCanUseBigSword = false
    end
    UIHelper.SetVisible(self.WidgetWeaponSecondary, bCanUseBigSword)
end

function UIArenaMasterDIYEquipView:UpdateEquipEditInfo()
    self.tEquip = self.tEquip or ArenaEquipDIYData.GetEquip()
	self.tEnchant = self.tEnchant or ArenaEquipDIYData.GetEnchant()
	self.tColorDiamond = self.tColorDiamond or ArenaEquipDIYData.GetColorDiamond()

    local nType = self.nCurSelectedEquipType
    if nType == EQUIPMENT_INVENTORY.RIGHT_RING then
		nType = EQUIPMENT_INVENTORY.LEFT_RING
	end

    -- 可穿装备
    local tbEquipInfo = self.tEquip[nType] or {}
    local nIndex = 1
    self.tbEditEquipCell = self.tbEditEquipCell or {}
    for i, widgetShell1 in ipairs(self.tbEquipDoubleCell) do
        local scriptShell = UIHelper.GetBindScript(widgetShell1)
        for j, widgetShell2 in ipairs(scriptShell.tbWidgetShell) do
            local tbInfo = tbEquipInfo[nIndex]
            if tbInfo then
		        local itemInfo = ItemData.GetItemInfo(tbInfo.dwTabType, tbInfo.dwIndex)
                local tbConfig = Table_GetRecommendEquipInfo(tbInfo.dwTabType, tbInfo.dwIndex)
                local tbEquipInfo1 = {
                    item = itemInfo,
                    tbConfig = tbConfig and tbConfig.tbConfig or {},
                    dwTabType = tbInfo.dwTabType,
                    dwIndex = tbInfo.dwIndex,
                    funcOnClickCallback = function ()
                        self.tCurSelectEquip = {
                            dwTabType = tbInfo.dwTabType,
                            dwIndex = tbInfo.dwIndex,
                        }
                        ArenaEquipDIYData.ReqEquip(self.nCurSelectedEquipType, self.tCurSelectEquip, self.tCurSelectEnchant, self.tCurSelectColorDiamond)
                        self:UpdateSelectedState()
                    end,
                }

                if not self.tbEditEquipCell[nIndex] then
                    self.tbEditEquipCell[nIndex] = UIHelper.AddPrefab(PREFAB_ID.WidgetEquipCompareItemCell, widgetShell2)
                end

                self.tbEditEquipCell[nIndex]:OnInit(tbEquipInfo1, false)
                self.tbEditEquipCell[nIndex]:HideRecommend()
                self.tbEditEquipCell[nIndex]:ShowEquipLevel()

                nIndex = nIndex + 1
            end

            UIHelper.SetVisible(widgetShell2, (i - 1) * 2 + j < nIndex)
        end

        UIHelper.SetVisible(widgetShell1, i * 2 - 1 < nIndex)
    end
    UIHelper.LayoutDoLayout(self.WidgetEquipSelect)

    -- 附魔
    local nEnchantType = nType
    if nEnchantType == EQUIPMENT_INVENTORY.BIG_SWORD then
		nEnchantType = EQUIPMENT_INVENTORY.MELEE_WEAPON
	end
    local tbEnchant = self.tEnchant[nEnchantType]
    if tbEnchant then
        self.tbFumoCells = self.tbFumoCells or {}
        self.tbFumoDoubleCells = self.tbFumoDoubleCells or {}

        local nEnchantCount = #tbEnchant
        local nNeedDoubleCellCount = math.ceil(nEnchantCount / 2)

        for i = 1, nNeedDoubleCellCount do
            if not self.tbFumoDoubleCells[i] then
                self.tbFumoDoubleCells[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetDoubleCell, self.LayoutItemShellList)
            end
        end

        for i = nNeedDoubleCellCount + 1, #self.tbFumoDoubleCells do
            UIHelper.SetVisible(self.tbFumoDoubleCells[i]._rootNode, false)
        end

        nIndex = 1
        for i = 1, nNeedDoubleCellCount do
            local widgetShell1 = self.tbFumoDoubleCells[i]._rootNode
            UIHelper.SetVisible(widgetShell1, true)
            local scriptShell = UIHelper.GetBindScript(widgetShell1)
            for j, widgetShell2 in ipairs(scriptShell.tbWidgetShell) do
                local tbInfo = tbEnchant[nIndex]
                if tbInfo then
                    local itemInfo = ItemData.GetItemInfo(tbInfo.dwTabType, tbInfo.dwIndex)
                    local tbEquipInfo1 = {
                        item = itemInfo,
                        dwTabType = tbInfo.dwTabType,
                        dwIndex = tbInfo.dwIndex,
                        funcOnClickCallback = function ()
                            self.tCurSelectEnchant = {
                                dwTabType = tbInfo.dwTabType,
                                dwIndex = tbInfo.dwIndex,
                            }
                            ArenaEquipDIYData.ReqEquip(self.nCurSelectedEquipType, self.tCurSelectEquip, self.tCurSelectEnchant, self.tCurSelectColorDiamond)
                            self:UpdateSelectedState()
                        end,
                    }

                    if not self.tbFumoCells[nIndex] then
                        self.tbFumoCells[nIndex] = UIHelper.AddPrefab(PREFAB_ID.WidgetEquipCompareItemCell, widgetShell2)
                    end

                    self.tbFumoCells[nIndex]:OnInit(tbEquipInfo1, false)
                    self.tbFumoCells[nIndex]:HideRecommend()
                    self.tbFumoCells[nIndex]:ShowItemDesc()

                    UIHelper.SetVisible(widgetShell2, true)
                    nIndex = nIndex + 1
                else
                    UIHelper.SetVisible(widgetShell2, false)
                end
            end
        end
        UIHelper.LayoutDoLayout(self.LayoutItemShellList)
        UIHelper.SetVisible(self.WidgetFumoSelect, true)
    else
        UIHelper.SetVisible(self.WidgetFumoSelect, false)
    end
    UIHelper.LayoutDoLayout(self.WidgetFumoSelect)


    -- 五彩石
    if self.nCurSelectedEquipType ~= EQUIPMENT_INVENTORY.BIG_SWORD and self.nCurSelectedEquipType ~= EQUIPMENT_INVENTORY.MELEE_WEAPON then
        UIHelper.SetVisible(self.WidgetWuCaiInsert, false)
    else
        UIHelper.SetVisible(self.WidgetWuCaiInsert, true)
        UIHelper.SetVisible(self.WidgetWuCaiItemSmall, false)
        if self.tCurSelectColorDiamond and  self.tCurSelectColorDiamond.nEnchantID and self.tCurSelectColorDiamond.nEnchantID > 0 then
            local dwTabType, dwIndex, nEnchantID = self.tCurSelectColorDiamond.dwTabType, self.tCurSelectColorDiamond.dwIndex, self.tCurSelectColorDiamond.nEnchantID
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
        else
            UIHelper.SetVisible(self.LayoutAttriWuCai, false)
            UIHelper.SetString(self.LabelWuCaiNameSmall1, "未镶嵌")
            UIHelper.SetString(self.LabelWuCaiNameSmall2, "未镶嵌")
        end
    end
    UIHelper.LayoutDoLayout(self.WidgetWuCai)
    UIHelper.LayoutDoLayout(self.WidgetWuCaiInsert)

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewPowerUpList)
end

function UIArenaMasterDIYEquipView:UpdateAttribInfo()
    local player = PlayerData.GetClientPlayer()
    if not player then
        return
    end

    local tbShowConfig = {}
    local tbKungfu = player.GetActualKungfuMount()
    if tbKungfu and tbKungfu.dwSkillID then
        tbShowConfig = TabHelper.GetUICharacterInfoMainAttribShowTab(tbKungfu.dwSkillID)
        if table_is_empty(tbShowConfig) then
            tbShowConfig = TabHelper.GetUICharacterInfoMainAttribShowTab(0)
        end
    end

    local tbInfo = PlayerData.GetAttribInfo(player)
    local nIndex = 2

    self.tbAttrCell = self.tbAttrCell or {}
    UIHelper.HideAllChildren(self.LayoutMainAttriList)
    UIHelper.HideAllChildren(self.ScrollViewSubAttriList)

    if not self.tbAttrCell[1] then
        self.tbAttrCell[1] = UIHelper.AddPrefab(PREFAB_ID.WidgetCustomAttriCell, self.LayoutMainAttriList)
    end

    UIHelper.SetVisible(self.tbAttrCell[1]._rootNode, true)
    local nMaxLife = player.nMaxLife or 1
    self.tbAttrCell[1]:OnEnter("气血", nMaxLife, true)

    for i, tbAttribInfo in ipairs(tbInfo) do
        if tbShowConfig[table.get_key(g_tStrings.PLAYER_ATTRIB_NAME, tbAttribInfo.szName)] then
            local widgetParent = self.LayoutMainAttriList
            if nIndex > 4 then
                widgetParent = self.ScrollViewSubAttriList
            end

            if not self.tbAttrCell[nIndex] then
                self.tbAttrCell[nIndex] = UIHelper.AddPrefab(PREFAB_ID.WidgetCustomAttriCell, widgetParent)
            end

            UIHelper.SetVisible(self.tbAttrCell[nIndex]._rootNode, true)
            self.tbAttrCell[nIndex]:OnEnter(tbAttribInfo.szName, tbAttribInfo.szValue, nIndex <= 4)
            nIndex = nIndex + 1
        end
    end

    UIHelper.LayoutDoLayout(self.LayoutMainAttriList)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewSubAttriList)

    local nBaseScores, nStrengthScores, nStoneScores =  GetDaShiSaiEquipScore(player)
	nBaseScores = nBaseScores or 0
	nStrengthScores = nStrengthScores or 0
	nStoneScores = nStoneScores or 0
	local nScores =  nBaseScores + nStrengthScores + nStoneScores
    UIHelper.SetString(self.LabelRankNum, nScores)
end

function UIArenaMasterDIYEquipView:UpdateSelectedState()
    for nType, scriptIcon in pairs(self.tbEquipCell) do
        if nType == self.nCurSelectedEquipType then
            scriptIcon:SetSelected(true)
        else
            scriptIcon:SetSelected(false)
        end
    end

    local nType = self.nCurSelectedEquipType
    if nType == EQUIPMENT_INVENTORY.RIGHT_RING then
		nType = EQUIPMENT_INVENTORY.LEFT_RING
	end
    local tbEquipInfo = self.tEquip[nType] or {}
    for nIndex, scriptCell in pairs(self.tbEditEquipCell) do
        local tbInfo = tbEquipInfo[nIndex]
        if tbInfo and self.tCurSelectEquip and tbInfo.dwTabType == self.tCurSelectEquip.dwTabType and tbInfo.dwIndex == self.tCurSelectEquip.dwIndex then
            scriptCell:SetSelected(true)
            scriptCell:SetEquipped(true)
        else
            scriptCell:SetSelected(false)
            scriptCell:SetEquipped(false)
        end
    end

    local nEnchantType = nType
    if nEnchantType == EQUIPMENT_INVENTORY.BIG_SWORD then
		nEnchantType = EQUIPMENT_INVENTORY.MELEE_WEAPON
	end
    local tbEnchant = self.tEnchant[nEnchantType]
    for nIndex, scriptCell in pairs(self.tbFumoCells) do
        local tbInfo = tbEnchant and tbEnchant[nIndex]
        if tbInfo and self.tCurSelectEnchant then
            local tInfo1 = EnchantData.GetEnchantInfo(tbInfo.dwIndex)
            local tInfo2 = EnchantData.GetEnchantInfo(self.tCurSelectEnchant.dwIndex)
            scriptCell:SetSelected(tInfo1 and tInfo2 and tInfo1.EnchantID == tInfo2.EnchantID)
            scriptCell:SetEquipped(tInfo1 and tInfo2 and tInfo1.EnchantID == tInfo2.EnchantID)
        else
            scriptCell:SetSelected(false)
            scriptCell:SetEquipped(false)
        end
    end
end

function UIArenaMasterDIYEquipView:ClearSelected()
    if self.scriptItemTip then
        self.scriptItemTip:OnInit()
    end
end


return UIArenaMasterDIYEquipView
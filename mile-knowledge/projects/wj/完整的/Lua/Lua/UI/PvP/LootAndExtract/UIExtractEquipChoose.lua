-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIExtractEquipChoose
-- Date: 2025-03-27 14:55:54
-- Desc: ?
-- ---------------------------------------------------------------------------------
local nCountOfRow = 2
local nDefultQuality = 1
local UIExtractEquipChoose = class("UIExtractEquipChoose")
local SLOT_TO_EQUIPMENT = {
    [1] = {szTitle = "武器", szIconPath = "UIAtlas2_Public_PublicItem_PublicItem_Icon_Img_equip_weapon_primary"},
    [2] = {szTitle = "暗器", szIconPath = "UIAtlas2_Public_PublicItem_PublicItem_Icon_Img_equip_weapon_remote"},
    [3] = {szTitle = "上衣", szIconPath = "UIAtlas2_Public_PublicItem_PublicItem_Icon_Img_equip_topwear"},
    [4] = {szTitle = "帽子", szIconPath = "UIAtlas2_Public_PublicItem_PublicItem_Icon_Img_equip_hat.png"},
    [5] = {szTitle = "项链", szIconPath = "UIAtlas2_Public_PublicItem_PublicItem_Icon_Img_equip_necklace"},
    [6] = {szTitle = "戒指栏位一", szIconPath = "UIAtlas2_Public_PublicItem_PublicItem_Icon_Img_equip_ring1"},
    [7] = {szTitle = "戒指栏位二", szIconPath = "UIAtlas2_Public_PublicItem_PublicItem_Icon_Img_equip_ring2"},
    [8] = {szTitle = "腰带", szIconPath = "UIAtlas2_Public_PublicItem_PublicItem_Icon_Img_equip_belt"},
    [9] = {szTitle = "腰坠", szIconPath = "UIAtlas2_Public_PublicItem_PublicItem_Icon_Img_equip_jadedeco"},
    [10] = {szTitle = "下装", szIconPath = "UIAtlas2_Public_PublicItem_PublicItem_Icon_Img_equip_bottomwear"},
    [11] = {szTitle = "鞋子", szIconPath = "UIAtlas2_Public_PublicItem_PublicItem_Icon_Img_equip_shoes"},
    [12] = {szTitle = "护腕", szIconPath = "UIAtlas2_Public_PublicItem_PublicItem_Icon_Img_equip_wristguard"},
}

local QUICK_SET_QUALITY = {
    [1] = "蓝色",
    [2] = "紫色",
}

local CONFIG_WEAPON_FILTER = {
    [1] = {1, 2}, -- 类型
    [2] = {1, 2}, -- 武器品质
}
function UIExtractEquipChoose:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    if FilterDef.ExtractWeaponPerset.GetRunTime() == nil then
        local tbRuntime = CONFIG_WEAPON_FILTER
        FilterDef.ExtractWeaponPerset.SetRunTime(tbRuntime)
    end

    self:InitWeaponList()
    self:InitScrollList()
end

function UIExtractEquipChoose:OnExit()
    self.bInit = false
    self:UnRegEvent()
    self:UnInitScrollList()
end

function UIExtractEquipChoose:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnBack, EventType.OnClick, function(btn)
        Event.Dispatch(EventType.OnExtractOpenEquipChoosePage, false)
    end)

    UIHelper.BindUIEvent(self.BtnSort, EventType.OnClick, function(btn)
        local _, scriptFilter = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.BtnSort, TipsLayoutDir.BOTTOM_LEFT, FilterDef.ExtractWeaponPerset)
    end)

    UIHelper.BindUIEvent(self.TogHintNormal, EventType.OnSelectChanged, function(_, bSelected)
        if not self.bQuickEquipment then
            return
        end

        self.tbQuickSet = {}
        if bSelected then
            for nPos, tbInfo in pairs(self.tbEquipList) do
                local bEquip = tbInfo.bEquip
                if not bEquip then
                    local nCoin = tbInfo.nCoin
                    local nMoney = tbInfo.nMoney
                    self.tbQuickSet[nPos] = {dwTabType = tbInfo.dwTabType, dwIndex = tbInfo.dwIndex, nCoin = nCoin, nMoney = nMoney}
                end
            end
        end

        self:UpdateQuickEquipCost()
        self:RefreshScrollList(SCROLL_LIST_UPDATE_TYPE.UPDATE_CELL)
    end)

    UIHelper.BindUIEvent(self.BtnQuickEquipment, EventType.OnClick, function(btn)
        self:DoQuickEquip()
    end)

    UIHelper.BindUIEvent(self.BtnSkillPop, EventType.OnClick, function(btn)
        UIMgr.Open(VIEW_ID.PanelXunBaoEquipSkillPop, self.tbLastClickItem)
    end)

    UIHelper.BindUIEvent(self.BtnWear, EventType.OnClick, function(btn)
        local item = self.tbLastClickItem
        if not item or table.is_empty(item) then
            return
        end
        local dwTabType, dwIndex, nCoin, nMoney = item[1], item[2], item[3], item[5]
        local bHave, nWareType, nWareSlot, nBox, nIndex = ExtractWareHouseData.EquipIsHave(dwTabType, dwIndex)
        if bHave then
            if nWareSlot then
                RemoteCallToServer("On_JueJing_MoveItem", nWareType, nWareSlot, ExtractItemType.Equip, self.nCurSelectedEquipType)
            else
                RemoteCallToServer("On_JueJing_SaveItemB2W", dwTabType, dwIndex, 1, ExtractItemType.Equip, self.nCurSelectedEquipType)
            end
        else
            self:BuyEquipConfirm(dwTabType, dwIndex, nCoin, nMoney)
        end
    end)
end

function UIExtractEquipChoose:RegEvent()
    -- Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, EventType.UpdateTBFWareHouse, function ()
        self.tbLastClickItem = nil
        self:UpdateList()
    end)

    Event.Reg(self, EventType.OnWindowsSizeChanged, function ()
        Timer.Add(self, 0.1, function()
            self:UpdateList()
        end)
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function ()
        UIHelper.SetSelected(self.TogType, false)
    end)

    Event.Reg(self, EventType.OnFilter, function(szKey, tbSelected)
        if szKey == FilterDef.ExtractWeaponPerset.Key then
            self.tbWeaponFilter = tbSelected
            self:UpdateInfo(true, self.nCurSelectedEquipType)
        end
    end)
end

function UIExtractEquipChoose:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIExtractEquipChoose:InitScrollList()
    self.ScrollList = UIScrollList.Create({
        listNode = self.LayoutScrollList_EquipChoose,
        nReboundScale = 1,
        bSlowRebound = true,
        fnGetCellType = function(nIndex)
            return PREFAB_ID.WidgetTreasureItem
        end,
        nSpace = 10,
        fnUpdateCell = function(cell, nIndex)
            self:UpdateRow(cell, nIndex)
        end,
    })
end

function UIExtractEquipChoose:UnInitScrollList()
    if self.ScrollList then
        self.ScrollList:Destroy()
        self.ScrollList = nil
    end
end

function UIExtractEquipChoose:InitTypeSelect()
    UIHelper.RemoveAllChildren(self.LayoutTypeFilter)
    for i = 1, #QUICK_SET_QUALITY do
        local szName = QUICK_SET_QUALITY[i]
        local fnAction = function (bSelected)
            if bSelected then
                self:UpdateQuickEquipment(i)
            end
        end

        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetSimpleFilterTipCell, self.LayoutTypeFilter)
        UIHelper.SetString(script.LabelContentText, szName)
        UIHelper.SetSwallowTouches(script.TogType, true)
        UIHelper.SetSelected(script.TogType, i == nDefultQuality, false)
        UIHelper.BindUIEvent(script.TogType, EventType.OnSelectChanged, function(_, bSelected)
            if bSelected then
                fnAction(bSelected)
                UIHelper.SetSelected(self.TogType, false)
            end
        end)
    end
    UIHelper.CascadeDoLayoutDoWidget(self.WidgetTypeFilter, true, true)
end

function UIExtractEquipChoose:InitWeaponList()
    self.tWeaponTable, self.tWeapon2Range, self.tWeapon2ID = Table_GetDesertWeaponSkill()
end

function UIExtractEquipChoose:UpdateInfo(bOpen, nEquipIndex)
    if not bOpen then
        self.nCurSelectedEquipType = nil
        UIHelper.SetVisible(self._rootNode, false)
        return
    end
    self.bQuickEquipment = false
    self.nCurSelectedEquipType = nEquipIndex
    self.tbLastClickItem = nil
    self.tbEquipList = {}
    self.tbWeaponFilter = FilterDef.ExtractWeaponPerset.GetRunTime()
    local szTitle = SLOT_TO_EQUIPMENT[nEquipIndex].szTitle.."推荐装备"
    UIHelper.SetString(self.LabelTtleTreasure, szTitle)
    UIHelper.SetSpriteFrame(self.ImgIcon, SLOT_TO_EQUIPMENT[nEquipIndex].szIconPath)
    UIHelper.SetVisible(self.BtnWear, true)
    UIHelper.SetVisible(self.WidgetQuickEquipment, false)
    UIHelper.SetVisible(self._rootNode, true)
    UIHelper.SetVisible(self.TogType, false)
    UIHelper.SetVisible(self.BtnSort, nEquipIndex == 1) -- 武器显示排序和技能按钮
    UIHelper.SetVisible(self.BtnSkillPop, nEquipIndex == 1) -- 武器显示排序和技能按钮

    self:UpdateList()
end

function UIExtractEquipChoose:UpdateQuickEquipment(nQuality)
    self.bQuickEquipment = true
    self.nCurSelectedEquipType = nQuality or nDefultQuality
    self.tbLastClickItem = nil
    self.tbQuickSet = {}
    self.tbEquipList = {}
    local szTitle = "快捷配装"
    UIHelper.SetString(self.LabelTtleTreasure, szTitle)
    UIHelper.SetString(self.LabelType, QUICK_SET_QUALITY[self.nCurSelectedEquipType])
    UIHelper.SetString(self.LabelType_Up, QUICK_SET_QUALITY[self.nCurSelectedEquipType])

    UIHelper.SetVisible(self._rootNode, true)
    UIHelper.SetVisible(self.TogType, true)
    UIHelper.SetVisible(self.BtnWear, false)
    UIHelper.SetVisible(self.BtnSort, false) -- 武器显示排序和技能按钮
    UIHelper.SetVisible(self.BtnSkillPop, false) -- 武器显示排序和技能按钮
    UIHelper.SetVisible(self.WidgetQuickEquipment, true)
    self:UpdateList()
    self:UpdateQuickEquipCost()
end

local function _GetEquipList(bQuickEquipment, nIndex)
    if bQuickEquipment then
        return GDAPI_TbfWareGetEquipSetList(nIndex)
    else
        return GDAPI_TbfWareGetEquipByType(nIndex)
    end
end

function UIExtractEquipChoose:CheckWeaponFilter(item)
    if self.nCurSelectedEquipType ~= 1 or self.bQuickEquipment then
        return true
    end

    local bShow = false
    -- local nDetail = item.nDetail
    local nQuality = item.nQuality
    local tbFilter = self.tbWeaponFilter

    local nRange = self.tWeapon2Range[tostring(item.dwID)] or 0
    if table.contain_value(tbFilter[1], nRange + 1) then
        bShow = true
    end

    if bShow and table.contain_value(tbFilter[2], nQuality - 2) then
        return true
    end

    return false
end

function UIExtractEquipChoose:UpdateList()
    if not self.nCurSelectedEquipType then
        return
    end

    self.tbEquipList = {}
    local tbInfo = _GetEquipList(self.bQuickEquipment, self.nCurSelectedEquipType)
    if not tbInfo then
        return
    end

    for nPos, v in ipairs(tbInfo) do
        local nType, dwIndex = v[1], v[2]
        local nCoin, nMoney = v[3], self.bQuickEquipment and v[4] or v[5]

        if v and nType and dwIndex then
            local item = GetItemInfo(nType, dwIndex)
            local tbConfig = Table_GetDesertEquipInfo(nType, dwIndex)

            local bEquip = self.bQuickEquipment and ExtractWareHouseData.IsEquiped(nPos, nType, dwIndex)
                                or ExtractWareHouseData.IsEquiped(self.nCurSelectedEquipType, nType, dwIndex)
            local bHave = select(1, ExtractWareHouseData.EquipIsHave(nType, dwIndex)) or bEquip
            local bShow = self:CheckWeaponFilter(item)

            local function funcOnClickCallback(tItem, script)
                if tItem.dwIndex ~= dwIndex then
                    self.tbLastClickItem = nil
                    return
                elseif self.bQuickEquipment then
                    local bSelected = script and script:GetSelected() or false
                    if bSelected then
                        self.tbQuickSet[nPos] = {dwTabType = nType, dwIndex = dwIndex, nCoin = nCoin, nMoney = nMoney}
                    else
                        self.tbQuickSet[nPos] = nil
                    end
                    self:UpdateQuickEquipCost()
                    return
                end
                self.tbLastClickItem = v
                self:UpdateBtnState()
            end

            if bShow then
                local tItem = {dwTabType = nType, dwIndex = dwIndex, nCoin = nCoin, nMoney = nMoney,
                                    item = item, funcOnClickCallback = funcOnClickCallback,
                                    bHave = bHave, bEquip = bEquip,
                                    tbConfig = tbConfig,}
                table.insert(self.tbEquipList, tItem)
                -- self.tbEquipList[nPos] = tItem
            end
        end
    end
    self.nCountOfRow = math.ceil((#self.tbEquipList) / nCountOfRow)
    self.ScrollList:SetCellTotal(self.nCountOfRow)

    self:RefreshScrollList(SCROLL_LIST_UPDATE_TYPE.RESET)
    self:UpdateBtnState()
end

function UIExtractEquipChoose:RefreshScrollList(nUpdateType)
    local nCountOfRow = self.nCountOfRow
    local min, max = self.ScrollList:GetIndexRangeOfLoadedCells()
    nUpdateType = nUpdateType or SCROLL_LIST_UPDATE_TYPE.RELOAD

    if nUpdateType == SCROLL_LIST_UPDATE_TYPE.RESET then
        self.ScrollList:Reset(nCountOfRow) --完全重置，包括速度、位置
    elseif nUpdateType == SCROLL_LIST_UPDATE_TYPE.RELOAD then
        self.ScrollList:ReloadWithStartIndex(nCountOfRow, min) --刷新数量
    elseif nUpdateType == SCROLL_LIST_UPDATE_TYPE.UPDATE_CELL then
        self.ScrollList:UpdateAllCell() --仅更新当前所有的Cell
    end
end

function UIExtractEquipChoose:UpdateRow(cell, nIndex)
    if not cell then
        return
    end
    cell._keepmt = true
    UIHelper.SetName(cell._rootNode, "WidgetTreasureItem" .. nIndex)

    local nItemCountOfEachRow = nCountOfRow
    local cellNodes = UIHelper.GetChildren(cell.LayoutBagItem)
    local nStartIndex = nItemCountOfEachRow * (nIndex - 1) + 1
    local nEndIndex = nItemCountOfEachRow * nIndex
    for i = nStartIndex, nEndIndex do
        local nNodeIndex = i - nStartIndex + 1
        local targetNode = cellNodes[nNodeIndex]
        local tbPos = self.tbEquipList[i]

        if tbPos then
            local cellScript = UIHelper.GetBindScript(targetNode) or UIHelper.AddPrefab(PREFAB_ID.WidgetEquipCompareItemCell, cell.LayoutBagItem)
            UIHelper.SetName(cellScript._rootNode, "WidgetEquipCompareItemCell" .. i)

            if cellScript then
                local scriptItemIcon = nil
                cellScript:OnInit(tbPos, false)
                cellScript:SetSelectEnable(tbPos and not tbPos.bEquip)
                scriptItemIcon = cellScript.scriptIcon
                if scriptItemIcon then
                    scriptItemIcon:SetClearSeletedOnCloseAllHoverTips(true)
                    scriptItemIcon:SetToggleSwallowTouches(true)
                    scriptItemIcon:SetSelectEnable(true)
                    scriptItemIcon:SetSpecialLabel("")
                    scriptItemIcon:SetClickCallback(function ()
                        local scriptDrag = UIHelper.GetBindScript(self.WidgetDrag)
                        local scriptItemTips = scriptDrag:OpenItemTip(2)
                        scriptItemTips:OnInitWithTabID(tbPos.dwTabType, tbPos.dwIndex)
                    end)
                end

                local bHave = tbPos.bHave
                local bEquip = tbPos.bEquip
                local szImg = ""
                local szContent = ""
                if bEquip then
                    szImg = "UIAtlas2_Public_PublicIcon_PublicIcon1_Img_SealStatus02"
                    szContent = "已装备"
                elseif bHave then
                    szImg = "UIAtlas2_Public_PublicIcon_PublicIcon1_Img_SealStatus01"
                    szContent = "已获得"
                end
                cellScript:SetEquipState(bHave or bEquip, szImg, szContent)

                if self.bQuickEquipment and self.tbQuickSet then
                    local bSelected = not not self.tbQuickSet[i]
                    cellScript:SetSelected(bSelected)
                    cellScript:SetToggleGroupIndex(-1)
                else
                    cellScript:SetToggleGroupIndex(ToggleGroupIndex.BagItem)
                    cellScript:SetSelected(self.tbLastClickItem and self.tbLastClickItem[2] == tbPos.dwIndex)
                end

                local szText = ""
                if tbPos.nCoin then
                    local szIcon = CurrencyData.tbImageSmallIcon[CurrencyType.ExamPrint]
                    szIcon = string.gsub(szIcon, ".png", "")
                    local szContent = UIHelper.GetCurrencyText(tbPos.nCoin, szIcon, 26)
                    local bEnough = tbPos.nCoin <= CurrencyData.GetCurCurrencyCount(CurrencyType.ExamPrint)
                    if not bEnough then
                        szContent = "<color=#ff7676>" .. szContent .."</color>"
                    end
                    szText = szText..szContent
                end

                if tbPos.nMoney then
                    local szContent = UIHelper.GetGoldText(tbPos.nMoney)
                    local tPrice = PackMoney(UIHelper.MoneyToGoldSilverAndCopper(tbPos.nMoney * 10000))
                    local bEnough = MoneyOptCmp(g_pClientPlayer.GetMoney(), tPrice) > 0
                    if not bEnough then
                        szContent = "<color=#ff7676>" .. szContent .."</color>"
                    end
                    szText = szText..(szText ~= "" and "+" or "")..szContent
                end

                cellScript:SetCurrency(szText)
            end
            UIHelper.CascadeDoLayoutDoWidget(cell._rootNode, true, true)
        elseif targetNode then
            UIHelper.RemoveFromParent(targetNode, true)
        end
    end
    UIHelper.CascadeDoLayoutDoWidget(cell.LayoutBagItem, true, true)
end

function UIExtractEquipChoose:BuyEquipConfirm(nType, nIndex, nCoin, nMoney)
    nType = nType or 0
    nIndex = nIndex or 0
    local player = GetClientPlayer()
    if not player then
        return
    end
    if nType <= 0 and nIndex <= 0 then
        return
    end

    local function funcConfirm()
        RemoteCallToServer("On_JueJing_QuickBuyEquip", nType, nIndex, self.nCurSelectedEquipType)
    end

    local tPrice = PackMoney(UIHelper.MoneyToGoldSilverAndCopper(nMoney * 10000))
    local bCoinEnough = player.nExamPrint >= nCoin
	local bMoneyEnough = MoneyOptCmp(player.GetMoney(), tPrice) > 0

    local iteminfo = GetItemInfo(nType, nIndex)
    local szEquip = UIHelper.GBKToUTF8(iteminfo.szName)
    local szMoneyTip = ""

    local szIcon = CurrencyData.tbImageSmallIcon[CurrencyType.ExamPrint]
    szIcon = string.gsub(szIcon, ".png", "")
    szMoneyTip = szMoneyTip..UIHelper.GetCurrencyText(nCoin, szIcon, 26)

    if not bCoinEnough then
        szMoneyTip = "<color=#ff7676>" .. szMoneyTip .."</color>"
    end

    if nMoney and nMoney > 0 then
        local szGold = UIHelper.GetGoldText(nMoney)
        if not bMoneyEnough then
            szGold = "<color=#ff7676>" .. szGold .."</color>"
        end
        szMoneyTip = szMoneyTip.."+"..szGold
    end

    local nR, nG, nB = GetItemFontColorByQuality(iteminfo.nQuality)
    local szItemName = GetFormatText("[" .. szEquip .. "]", nil, nR, nG, nB)

    local szContent = string.format("你确定花费%s购买%s吗？", szMoneyTip, szItemName)
    local scriptTips = UIHelper.ShowConfirm(szContent, funcConfirm, nil, true)
end

function UIExtractEquipChoose:DoQuickEquip()
    if not self.bQuickEquipment or not self.tbQuickSet or table.is_empty(self.tbQuickSet) then
        return
    end

    local player = GetClientPlayer()
    if not player then
        return
    end

    local function funcConfirm()
        local tbList = {}
        local nSetIndex = self.nCurSelectedEquipType
        for nPos, v in pairs(self.tbEquipList) do
            if self.tbQuickSet[nPos] and not v.bEquip then
                tbList[nPos] = true
            else
                tbList[nPos] = false
            end
        end

        RemoteCallToServer("On_JueJing_QuickBuyEquipSet", nSetIndex, tbList)
        Event.Dispatch(EventType.OnExtractOpenEquipChoosePage, false)
    end

    local nCost = 0
    local nMoney = 0
    for _, tbInfo in pairs(self.tbQuickSet) do
        nCost = nCost + (tbInfo.nCoin or 0)
        nMoney = nMoney + (tbInfo.nMoney or 0)
    end

    local tPrice = PackMoney(UIHelper.MoneyToGoldSilverAndCopper(nMoney * 10000))
    local bCoinEnough = nCost <= CurrencyData.GetCurCurrencyCount(CurrencyType.ExamPrint)
	local bMoneyEnough = MoneyOptCmp(player.GetMoney(), tPrice) > 0

    local szText = ""
    if nCost and nCost > 0 then
        local szIcon = CurrencyData.tbImageSmallIcon[CurrencyType.ExamPrint]
        szIcon = string.gsub(szIcon, ".png", "")
        local szContent = UIHelper.GetCurrencyText(nCost, szIcon, 26)
        if not bCoinEnough then
            szContent = "<color=#ff7676>" .. szContent .."</color>"
        end
        szText = szText..szContent
    end

    if nMoney and nMoney > 0 then
        local szContent = UIHelper.GetGoldText(nMoney)
        if not bMoneyEnough then
            szContent = "<color=#ff7676>" .. szContent .."</color>"
        end
        szText = szText..(szText ~= "" and "+" or "")..szContent
    end

    local szContent = string.format("你确定花费%s购买剩余装备吗？", szText)
    local scriptTips = UIHelper.ShowConfirm(szContent, funcConfirm, nil, true)
end

function UIExtractEquipChoose:UpdateBtnState()
    local szBtnWare = "穿戴"
    local bApplyWare = true

    if not self.bQuickEquipment and self.tbLastClickItem then
        local bHave = select(1, ExtractWareHouseData.EquipIsHave(self.tbLastClickItem[1], self.tbLastClickItem[2]))
        local bEquip = ExtractWareHouseData.IsEquiped(self.nCurSelectedEquipType, self.tbLastClickItem[1], self.tbLastClickItem[2])
        if bEquip then
            szBtnWare = "已穿戴"
            bApplyWare = false
        elseif not bHave then
            szBtnWare = "购买并穿戴"
        end
    elseif not self.tbLastClickItem or table.is_empty(self.tbLastClickItem) then
        bApplyWare = false
    end

    UIHelper.SetString(self.LabelWear, szBtnWare)
    UIHelper.SetButtonState(self.BtnWear, bApplyWare and BTN_STATE.Normal or BTN_STATE.Disable)

    UIHelper.SetVisible(self.ImgSort_On, not table.deepCompare(CONFIG_WEAPON_FILTER, self.tbWeaponFilter))
end

function UIExtractEquipChoose:UpdateQuickEquipCost()
    if not self.bQuickEquipment then
        return
    end

    local nCost = 0
    local nMoney = 0
    local nSelectCount = 0
    local nTotalCount = 0
    if self.tbQuickSet then
        for _, tbInfo in pairs(self.tbQuickSet) do
            nCost = nCost + (tbInfo.nCoin or 0)
            nMoney = nMoney + (tbInfo.nMoney or 0)
            nSelectCount = nSelectCount + 1
        end
    end

    for i, v in ipairs(self.tbEquipList) do
        if not v.bEquip then
            nTotalCount = nTotalCount + 1
        end
    end

    local tPrice = PackMoney(UIHelper.MoneyToGoldSilverAndCopper(nMoney * 10000))
    local bCoinEnough = nCost <= CurrencyData.GetCurCurrencyCount(CurrencyType.ExamPrint)
	local bMoneyEnough = MoneyOptCmp(g_pClientPlayer.GetMoney(), tPrice) > 0

    UIHelper.SetString(self.LabelCoinNum, nCost)
    UIHelper.SetString(self.LabelMoney, nMoney)

    UIHelper.SetColor(self.LabelCoinNum, bCoinEnough and cc.WHITE or cc.c3b(255, 118, 118))
    UIHelper.SetColor(self.LabelMoney, bMoneyEnough and cc.WHITE or cc.c3b(255, 118, 118))

    UIHelper.SetVisible(self.LabelMoney, nMoney > 0)
    UIHelper.SetVisible(self.LabelConiTip, nMoney > 0)
    UIHelper.SetVisible(self.WidgetMoney, nMoney > 0)

    UIHelper.SetButtonState(self.BtnQuickEquipment, (nSelectCount > 0 and bCoinEnough and bMoneyEnough) and BTN_STATE.Normal or BTN_STATE.Disable)

    UIHelper.LayoutDoLayout(self.LayoutCost)
    UIHelper.SetSelected(self.TogHintNormal, nTotalCount > 0 and nSelectCount == nTotalCount, false)
end

return UIExtractEquipChoose
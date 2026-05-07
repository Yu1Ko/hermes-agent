local UIPanelWuCaiPresetManage = class("UIPanelWuCaiPresetManage")

local nMaxWeaponBindNum = 6

local function GetFirstEmptyWeaponIndex()
    for nIndex = 1, nMaxWeaponBindNum, 1 do
        local tBindInfo = DataModel.GetBindWeaponInfo(nIndex)
        if not tBindInfo or (tBindInfo[1] == 0 and tBindInfo[2] == 0) then
            return nIndex
        end
    end

    return nil
end

function UIPanelWuCaiPresetManage:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self:UpdateInfo()

        UIHelper.HidePageBottomBar()
    end
end

function UIPanelWuCaiPresetManage:OnExit()
    self.bInit = false
    UIHelper.ShowPageBottomBar()
end

function UIPanelWuCaiPresetManage:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnCloseRight, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)
end

function UIPanelWuCaiPresetManage:RegEvent()
    Event.Reg(self, "WEAPON_BIND_COLOR_DIAMOND", function(arg0, arg1)
        DataModel.UpdateBindWeaponInfo()

        if self.nWeaponCount ~= DataModel.GetBindWeaponCount() then
            self:UpdateInfo()
        end
    end)

    Event.Reg(self, "DELETE_WEAPON_BIND_COLOR_DIAMOND", function(arg0, arg1)
        DataModel.UpdateBindWeaponInfo()
        self:UpdateInfo()
    end)
end

function UIPanelWuCaiPresetManage:UpdateInfo()
    UIHelper.RemoveAllChildren(self.ScrollViewContentSelect)
    LOG.TABLE(DataModel.tBindWeaponInfo)

    local nCount = 0
    for nIndex = 1, nMaxWeaponBindNum, 1 do
        local tBindInfo = DataModel.GetBindWeaponInfo(nIndex)
        if tBindInfo and tBindInfo[1] ~= 0 and tBindInfo[2] ~= 0 then
            local nWeaponIndex = nIndex
            local n = nCount
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetWuCaiPresetManageItem, self.ScrollViewContentSelect, nWeaponIndex)
            script:BindScrollViewRefresh(function()
                UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContentSelect)
                UIHelper.ScrollToIndex(self.ScrollViewContentSelect, n)
            end)
            nCount = nCount + 1
        end
    end

    self.nWeaponCount = nCount

    if nCount ~= nMaxWeaponBindNum then
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetWuCaiPresetManageItem, self.ScrollViewContentSelect, nil, true)
        script:BindAddFunc(function()
            self:OpenBag()
        end)

        if UIMgr.IsViewOpened(VIEW_ID.PanelLeftBag) then
            -- 背包打开时刷新背包内容
            self:OpenBag()
        end
    else
        if self.scriptBag then
            UIMgr.Close(self.scriptBag)
            self.scriptBag = nil
        end
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContentSelect)
    UIHelper.SetLabel(self.LabelLimitNum, string.format("(%d/%d)",nCount, nMaxWeaponBindNum))
end

function UIPanelWuCaiPresetManage:OpenBag()
    local tItemTabTypeAndIndexList = {}
    local tBindWeaponIndex = {}

    for k, v in pairs(DataModel.tBindWeaponInfo) do
        if v and v[1] ~= 0 and v[2] ~= 0 then
            table.insert(tBindWeaponIndex, v[2])
        end
    end

    --- 遍历背包武器装备
    for _, tbItemInfo in ipairs(ItemData.GetItemList(ItemData.BoxSet.Bag)) do
        local item = tbItemInfo.hItem
        if item and item.nGenre == ITEM_GENRE.EQUIPMENT and item.nSub == EQUIPMENT_SUB.MELEE_WEAPON
                and not table.contain_value(tBindWeaponIndex, item.dwIndex) then
            table.insert(tItemTabTypeAndIndexList, { nBox = tbItemInfo.nBox, nIndex = tbItemInfo.nIndex, nSelectedQuantity = 0, hItem = item })
        end
    end

    --- 遍历身上的武器装备
    for nIndex, nMainEnum in ipairs(EquipMainEnumList) do
        for _, nEquipEnum in ipairs(EquipSlotEnum) do
            local item = ItemData.GetItemByPos(nMainEnum, nEquipEnum)
            if item and item.nSub == EQUIPMENT_SUB.MELEE_WEAPON and not table.contain_value(tBindWeaponIndex, item.dwIndex) then
                table.insert(tItemTabTypeAndIndexList, { nBox = nMainEnum, nIndex = nEquipEnum, nSelectedQuantity = 0, hItem = item })
            end
        end
    end

    local tbFilterInfo = {}
    tbFilterInfo.Def = FilterDef.HorseLeftBag
    tbFilterInfo.tbfuncFilter = { {
                                      function(_)
                                          return true
                                      end,
                                      function(item)
                                          return item.nQuality == 2
                                      end,
                                      function(item)
                                          return item.nQuality == 3
                                      end,
                                      function(item)
                                          return item.nQuality == 4
                                      end,
                                      function(item)
                                          return item.nQuality == 5
                                      end,
                                  } }
    if not UIMgr.IsViewOpened(VIEW_ID.PanelLeftBag) then
        self.scriptBag = UIMgr.Open(VIEW_ID.PanelLeftBag)
    end
    self.scriptBag:OnInitWithBox(tItemTabTypeAndIndexList, tbFilterInfo)
    self.scriptBag:SetClickCallback(function(bSelect, nBox, nIndex)
        if bSelect then
            AppendWeapon(GetFirstEmptyWeaponIndex(), nBox, nIndex)
        end
    end)
end

-- OnRemoteCall.OnWeaponBindColorDiamond
function AppendWeapon(nIndex, dwBox, dwX)
    if dwBox == -1 or dwX == -1 or nIndex == nil then
        return
    end

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

local MAX_COLOR_DIAMOND_NUM = 4         --五彩石镶嵌数量
function UpdateStonePlan(nWeaponIndex)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local nEquipIndex = DataModel.GetSelect(1)
    local tBindInfo = DataModel.GetBindWeaponInfo(nWeaponIndex)
    local nCurSlotIndex = hPlayer.GetColorDiamondCurrentConfigIndex()
    local KItemWeapon = DataModel.GetEquipItem(nEquipIndex)
    local nCurWeaponSlot = 0
    if KItemWeapon then
        for k, v in pairs(DataModel.tBindWeaponInfo) do
            if v[1] == KItemWeapon.dwTabType and v[2] == KItemWeapon.dwIndex then
                nCurWeaponSlot = v[3]
                break
            end
        end
    end

    --藏剑当前装备栏上五彩石未生效
    if not DataModel.IsEquipBoxColorDiamondApply() then
        nCurSlotIndex = 0
    end

    for i = 1, MAX_COLOR_DIAMOND_NUM do
        local dwEnchantID, nCurLevel = hPlayer.GetColorDiamondSlotInfo(i)
        local nStoneIndex = i
        if dwEnchantID > 0 then
            local dwTabType, dwTabIndex = GetColorDiamondInfoFromEnchantID(dwEnchantID)
            if dwTabType and dwTabIndex then
                local pItemInfo = GetItemInfo(dwTabType, dwTabIndex)
                if pItemInfo then
                    --UpdateItemInfoBoxObject(hBox, nil, dwTabType, dwTabIndex, 1)
                end
            end
        else
            --hBox:Hide()
        end
        if (tBindInfo and tBindInfo[3] == i) or (nWeaponIndex == 0 and ((nCurWeaponSlot == i) or (nCurWeaponSlot == 0 and nCurSlotIndex == i))) then
            --hStone.bSel = true
            if nWeaponIndex == 0 then
                --View.nSelectIndex = i
            end
        end
        if nWeaponIndex == 0 then
            if dwEnchantID > 0 and nCurLevel > 0 and KItemWeapon and KItemWeapon.nLevel > nCurLevel then
                --hStone:ToGray()
            else
                --hStone:ToNormal()
            end
        end
        --View.UpdateStoneState(hStone)
    end
end

function StartSlotColorDiamond(nSelectIndex)
    local dwSlotBox = 5
    local dwSlotX = 13

    if not nSelectIndex or nSelectIndex == 0 then
        OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.tActivation.NO_SELECT_BOX)
        return
    end

    local fnAction = function()
        RemoteCallToServer("OnMountEquipBoxColorDiamond", nSelectIndex, dwSlotBox, dwSlotX)
        --View.DrawColorDiamond(hFrame)
    end

    local szMessage = GetFormatText(FormatString(g_tStrings.tActivation.MOUNT_COLOR_DIAMOND, nSelectIndex))
    UIHelper.ShowConfirm(szMessage, function()
        fnAction()
    end, nil, true)
end

function DrawColorDiamond(nStoneIndex)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local nEquipIndex = DataModel.GetSelect(1)
    local nConfigIndex = hPlayer.GetColorDiamondCurrentConfigIndex()
    local pItemWeapon = DataModel.GetEquipItem(nEquipIndex)
    local szDiamondName = ""
    local nR, nG, nB = 0, 0, 0
    local dwEnchantID = 0
    local nCurLevel = 0

    if nStoneIndex and nStoneIndex > 0 then
        --手动选了装备栏五彩石
        dwEnchantID, nCurLevel = hPlayer.GetColorDiamondSlotInfo(nStoneIndex)
    elseif nConfigIndex > 0 and DataModel.IsEquipBoxColorDiamondApply() then
        --自身武器应用了装备栏的五彩石
        dwEnchantID, nCurLevel = hPlayer.GetColorDiamondSlotInfo(nConfigIndex)
    else
        --武器上的五彩石
        dwEnchantID = pItemWeapon and pItemWeapon.GetMountFEAEnchantID() or 0
    end

    --五彩石格子
    if dwEnchantID > 0 then
        local dwTabType, dwIndex = GetColorDiamondInfoFromEnchantID(dwEnchantID)
        local tDiamondInfo = GetItemInfo(dwTabType, dwIndex)
        if tDiamondInfo then
            szDiamondName = tDiamondInfo.szName
            nR, nG, nB = GetItemFontColorByQuality(tDiamondInfo.nQuality)
            --UpdateItemInfoBoxObject(hBoxCurDiamond, nil, dwTabType, dwIndex, 1)
        end
    end


    --五彩石生效品级
    --if dwEnchantID > 0 and nCurLevel > 0 then
    --    if pItemWeapon and pItemWeapon.nLevel > nCurLevel then
    --        hAttrList:Hide()
    --        hTextLowTips:Show()
    --    else
    --        hAttrList:Show()
    --        hTextQuality:Hide()
    --        hTextLowTips:Hide()
    --    end
    --    hTextQuality:Show()
    --    hTextQuality:SetText(FormatString(g_tStrings.STR_SLOT_QUALITY_LEVEL, nCurLevel))
    --else
    --    hAttrList:Show()
    --    hTextQuality:Hide()
    --    hTextLowTips:Hide()
    --    hTextQuality:Hide()
    --end

    --五彩石属性
    --hAttrList:Clear()
    --if dwEnchantID > 0 then
    --    local tAttr = GetFEAInfoByEnchantID(dwEnchantID)
    --    for k, v in pairs(tAttr) do
    --        if v.nID ~= ATTRIBUTE_TYPE.SKILL_EVENT_HANDLER then
    --            FormatAttributeValue(v)
    --            local szText = GetAttributeString(v.nID, v.nValue1, v.nValue2, MAGIC_ATTRI_DEF, MAGIC_ATTRI_DEF)
    --            local hItem = hAttrList:AppendItemFromIni(INI_PATH, "Handle_DiamondAttr")
    --            local hTextAttr = hItem:Lookup("Text_DiamondAttr")
    --            hTextAttr:SetText(szText)
    --            if GetFEAActiveFlag(hPlayer.dwID, INVENTORY_INDEX.EQUIP, nEquipIndex, tonumber(k) - 1) then
    --                hTextAttr:SetFontColor(0, 200, 0)
    --            else
    --                hTextAttr:SetFontColor(192, 192, 192)
    --            end
    --        end
    --    end
    --end
end

return UIPanelWuCaiPresetManage
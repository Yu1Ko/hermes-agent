-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIExtrtactWeaponSwitchTip
-- Date: 2025-06-24 11:24:27
-- Desc: ?
-- ---------------------------------------------------------------------------------
local tEquipTypeList = {
    [2] = EQUIPMENT_INVENTORY.AMULET,
    [1] = EQUIPMENT_INVENTORY.PENDANT,
    [3] = EQUIPMENT_INVENTORY.MELEE_WEAPON,
}

local tEquipSubFilter = {
    [EQUIPMENT_SUB.AMULET]       = true,
    [EQUIPMENT_SUB.PENDANT]      = true,
    [EQUIPMENT_SUB.MELEE_WEAPON] = true,
}

local tEquipPosData = {
    [EQUIPMENT_INVENTORY.AMULET]       = {nIconFrame = 66, nCDID = 735},
    [EQUIPMENT_INVENTORY.PENDANT]      = {nIconFrame = 57, nCDID = 735},
    [EQUIPMENT_INVENTORY.MELEE_WEAPON] = {nIconFrame = 64, nCDID = 735},
}

local MIN_COUNT = 5
local BOX_CD_LAYER = 3
local BOX_EXTCD_BG = 5
local FONT_RED = 235
local FONT_YELLOW = 23

local UIExtrtactWeaponSwitchTip = class("UIExtrtactWeaponSwitchTip")
-----------------------------DataModel------------------------------
local DataModel = {}

function DataModel.Init()
    local _, _, t = Table_GetDesertWeaponSkill()
    DataModel.tWeapon2ID = t
    DataModel.UpdateData()
end

function DataModel.AppendEquip(hPlayer, dwBox, dwX)
    if not hPlayer then
        return
    end

    local tItem = GetPlayerItem(hPlayer, dwBox, dwX)

    if tItem and tItem.nGenre == ITEM_GENRE.EQUIPMENT and tEquipSubFilter[tItem.nSub] then
        local dwTabType  = tItem.dwTabType
        local dwIndex    = tItem.dwIndex
        local nLevel     = tItem.nLevel
        local nBox, nPos = ItemData.GetEquipItemEquiped(hPlayer, tItem.nSub, tItem.nDetail)
        local subtype    = nil

        if not nPos or not DectTableValue(tEquipTypeList, nPos) then
            return
        end

        if not DataModel.tTempList[nPos] then
            DataModel.tTempList[nPos] = {}
        end
        if nPos == EQUIPMENT_INVENTORY.MELEE_WEAPON then
            subtype = DataModel.tWeapon2ID[tostring(dwIndex)] or "default"
        elseif nPos == EQUIPMENT_INVENTORY.PENDANT or nPos == EQUIPMENT_INVENTORY.AMULET then
            local tItemInfo = GetItemInfo(dwTabType, dwIndex)
            local szName    = UIHelper.GBKToUTF8(tItemInfo.szName)
            local tString   = SplitString(szName, g_tStrings.STR_SPLIT_DOT)
            local szSuffix  = tString[3] or "default"
            subtype = szSuffix
        end
        if subtype then
            if not DataModel.tTempList[nPos][subtype] then
                DataModel.tTempList[nPos][subtype] = {}
            end
            table.insert(DataModel.tTempList[nPos][subtype], {dwBox = dwBox, dwX = dwX, dwItemType = dwTabType, dwItemIndex = dwIndex, nLevel = nLevel, nPos = nPos, subtype = subtype})
        end
    end
end

function DataModel.UpdateData()
    DataModel.tTempList   = {}
    DataModel.tWeaponList = {}
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    --取背包物品
    local dwSize = hPlayer.GetBoxSize(INVENTORY_INDEX.LIMITED_PACKAGE)
    for dwX = 0, dwSize - 1, 1 do
        if hPlayer.CheckBoxCanUse(INVENTORY_INDEX.LIMITED_PACKAGE) then
            for i = 0, dwSize - 1 do
                DataModel.AppendEquip(hPlayer, INVENTORY_INDEX.LIMITED_PACKAGE, dwX)
            end
        end
    end

    --取身上已经装备的物品
    for i = 1, #tEquipTypeList do
        local nPos = tEquipTypeList[i]
        DataModel.AppendEquip(hPlayer, INVENTORY_INDEX.EQUIP, nPos)
    end

    --筛选:武器只显示同类型品质等级最高的，饰品显示同技能后缀下品质等级最高的
    local function cmp(a, b)
        return a.nLevel > b.nLevel
    end

    local function cmp2(a, b)
        local aIsString = type(a.subtype) == "string"
        local bIsString = type(b.subtype) == "string"
        -- 字符串类型优先置顶
        if aIsString and not bIsString then
            return true
        elseif not aIsString and bIsString then
            return false
        end
        -- 同类型时正常比较（字符串按字母序，数字按数值）
        return a.subtype < b.subtype
    end

    DataModel.nMaxCount = MIN_COUNT
    local nCount = 0
    for i, v in pairs(DataModel.tTempList) do
        nCount = 0
        for j, tList in pairs(v) do
            table.sort(tList, cmp)
            local tItem = tList[1]
            if not DataModel.tWeaponList[i] then
                DataModel.tWeaponList[i] = {}
            end
            table.insert(DataModel.tWeaponList[i], tItem)
            nCount = nCount + 1
        end
        table.sort(DataModel.tWeaponList[i], cmp2)
        DataModel.nMaxCount = math.max(DataModel.nMaxCount, nCount)
    end
end

function DataModel.UnInit()
    for i, v in pairs(DataModel) do
        if type(v) ~= "function" then
            DataModel[i] = nil
        end
    end
end

function UIExtrtactWeaponSwitchTip:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    DataModel.Init()
    self:UpdateInfo()
end

function UIExtrtactWeaponSwitchTip:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIExtrtactWeaponSwitchTip:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        local parent = UIHelper.GetParent(self._rootNode)
        UIHelper.SetVisible(parent, false)
    end)
end

function UIExtrtactWeaponSwitchTip:RegEvent()
    for _, scrollview in pairs(self.tbSwitchScrollView) do
        UIHelper.SetTouchDownHideTips(scrollview, false)
    end

    Event.Reg(self, "BAG_ITEM_UPDATE", function ()
        local dwBox, dwX, bNew = arg0, arg1, arg2
        if dwBox == INVENTORY_INDEX.LIMITED_PACKAGE then
            local hPlayer = GetClientPlayer()
            if hPlayer and bNew then
                local tItem = GetPlayerItem(hPlayer, dwBox, dwX)
                if tItem then
                    local nBox, nPos = ItemData.GetEquipItemEquiped(hPlayer, tItem.nSub, tItem.nDetail)
                    if DectTableValue(tEquipTypeList, nPos) then
                        DataModel.UpdateData()
                        self:UpdateInfo()
                    end
                end
            else
                DataModel.UpdateData()
                self:UpdateInfo()
            end
        end
    end)

    Event.Reg(self, "EQUIP_ITEM_UPDATE", function ()
        local dwBox, dwX = arg0, arg1
        if dwBox == INVENTORY_INDEX.EQUIP and DectTableValue(tEquipTypeList, dwX) then
            DataModel.UpdateData()
            self:UpdateInfo()
        end
    end)

    Event.Reg(self, EventType.OnSceneTouchNothing, function ()
        local parent = UIHelper.GetParent(self._rootNode)
        UIHelper.SetVisible(parent, false)
    end)
end

function UIExtrtactWeaponSwitchTip:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIExtrtactWeaponSwitchTip:UpdateInfo()
    local tWeaponList     = DataModel.tWeaponList
    for i = 1, #tEquipTypeList do
        UIHelper.RemoveAllChildren(self.tbSwitchScrollView[i])
        local nPos      = tEquipTypeList[i]
        local tList     = tWeaponList[nPos] or {}
        local nCount    = #tList
        for j = 1, nCount do
            local scriptItem = UIHelper.AddPrefab(PREFAB_ID.WidgetXunBaoItemCell, self.tbSwitchScrollView[i])
            self:InitItem(scriptItem, tList[j])
        end

        for j = nCount + 1, DataModel.nMaxCount do
            local scriptItem = UIHelper.AddPrefab(PREFAB_ID.WidgetXunBaoItemCell, self.tbSwitchScrollView[i])
            self:InitItem(scriptItem)
        end
        UIHelper.ScrollViewDoLayoutAndToTop(self.tbSwitchScrollView[i])
    end
end

function UIExtrtactWeaponSwitchTip:InitItem(scriptItem, tInfo)
    UIHelper.SetAnchorPoint(scriptItem._rootNode, 0, 0)

    if not tInfo or table.is_empty(tInfo) then
        UIHelper.SetVisible(scriptItem.BtnLock, true)
        UIHelper.SetEnable(scriptItem.BtnLock, false)
        return
    end

    scriptItem:OnEnter(tInfo)

    local tCurEquip = GetPlayerItem(GetClientPlayer(), INVENTORY_INDEX.EQUIP, tInfo.nPos)
    local scriptCell = scriptItem:GetItemScript()
    scriptCell:SetTouchDownHideTips(false)
    scriptCell:SetToggleSwallowTouches(true)
    scriptCell:SetClearSeletedOnCloseAllHoverTips(true)
    scriptCell:SetToggleSwallowTouches(false)
    scriptCell:SetRecallVisible(tCurEquip and tCurEquip.dwTabType == tInfo.dwItemType and tCurEquip.dwIndex == tInfo.dwItemIndex )
    scriptCell:SetRecallCallback(function ()
        ItemData.UnEquipItem(tInfo.dwBox, tInfo.dwX)
    end)

    scriptCell:SetClickCallback(function()
        local hPlayer = GetClientPlayer()
        if not hPlayer then
            return
        end

        if not tInfo then
            return
        end

        local dwBox, dwX = tInfo.dwBox, tInfo.dwX
        ItemData.EquipItem(dwBox, dwX)
    end)

    scriptCell:SetLongPressCallback(function ()
        TipsHelper.ShowItemTips(scriptCell.__rootNode, tInfo.dwBox, tInfo.dwX, true, TipsLayoutDir.BOTTOM_LEFT)
    end)
end

return UIExtrtactWeaponSwitchTip
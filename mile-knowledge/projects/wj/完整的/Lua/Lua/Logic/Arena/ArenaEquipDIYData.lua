ArenaEquipDIYData = ArenaEquipDIYData or {className = "ArenaEquipDIYData"}

local self = ArenaEquipDIYData
function ArenaEquipDIYData.Init()
    ArenaEquipDIYData.RegEvent()
end

function ArenaEquipDIYData.RegEvent()

end

function ArenaEquipDIYData.UnInit()
    Event.UnRegAll(self)
end

local function IsEquipFit(hItemInfo)
    if not IsItemFitKungfu(hItemInfo) then
        return false
    end

    if not IsItemFitByCamp(hItemInfo) then
        return false
    end

    return true
end

function ArenaEquipDIYData.ReqEquip(nIndex, tSelectEquip, tSelectEnchant, tSelectColorDiamond)
	local dwEquipType = 0
	local dwEquipIndex = 0
	if tSelectEquip then
		dwEquipType = tSelectEquip.dwTabType or dwEquipType
		dwEquipIndex = tSelectEquip.dwIndex or dwEquipIndex
	end
	local dwEnchantType = 0
	local dwEnchantIndex = 0
	if tSelectEnchant then
		dwEnchantType = tSelectEnchant.dwTabType or dwEnchantType
		dwEnchantIndex = tSelectEnchant.dwIndex or dwEnchantIndex
	end
	local dwColorDiamondType = 0
	local dwColorDiamondIndex = 0
	if tSelectColorDiamond then
		dwColorDiamondType = tSelectColorDiamond.dwTabType or dwColorDiamondType
		dwColorDiamondIndex = tSelectColorDiamond.dwIndex or dwColorDiamondIndex
	end
	RemoteCallToServer("On_JJCEquipment_DIY", INVENTORY_INDEX.EQUIP, nIndex,
              dwEquipType, dwEquipIndex, dwEnchantType, dwEnchantIndex, dwColorDiamondType, dwColorDiamondIndex)

    Timer.Add(ArenaEquipDIYData, 0.5, function ()
        Event.Dispatch("ON_JJC_EQUIP_CHANGE")
    end)
end

function ArenaEquipDIYData.GetEquip()
    local tEquip = {}
    local nCount = g_tTable.JJCDIYEquip:GetRowCount()
    for i = 2, nCount do
        local tLine = g_tTable.JJCDIYEquip:GetRow(i)
        local hItemInfo = GetItemInfo(tLine.dwTabType, tLine.dwIndex)
        if hItemInfo and hItemInfo.nGenre == ITEM_GENRE.EQUIPMENT then
            if IsEquipFit(hItemInfo) then
                local _, nPos = ItemData.GetEquipItemEquiped(GetClientPlayer(), hItemInfo.nSub, hItemInfo.nDetail)
                if nPos == EQUIPMENT_INVENTORY.RIGHT_RING then
                    nPos = EQUIPMENT_INVENTORY.LEFT_RING
                end
                if not tEquip[nPos] then
                    tEquip[nPos] = {}
                end

                table.insert(tEquip[nPos], tLine)
            end
        else
            print("ArenaEquipDIYData.GetEquip no this item %d %d", tLine.dwTabType, tLine.dwIndex)
        end
    end
    return tEquip
end

local function GetEnchantSub(dwEnchantID)
    local _, _, nSubType = GetEnchantAttribute(dwEnchantID)
    return nSubType
end

local function IsFitKungfu(szKungfu)
    local dwKungfuID = PlayerData.GetPlayerMountKungfuID()
    local tKungfu = SplitString(szKungfu, ";")
    for _, v in ipairs(tKungfu) do
        if dwKungfuID == tonumber(v) then
            return true
        end
    end
    return false
end

function ArenaEquipDIYData.GetEnchant()
    local tEnchant = {}
    local nCount = g_tTable.JJCDIYEnchant:GetRowCount()
    for i = 2, nCount do
        local tLine = g_tTable.JJCDIYEnchant:GetRow(i)
        local hItemInfo = GetItemInfo(tLine.dwTabType, tLine.dwIndex)
        if hItemInfo and CraftData.g_EnchantInfo[tLine.dwIndex] then
            if IsFitKungfu(tLine.szKungfuID) then
                local nSub = GetEnchantSub(CraftData.g_EnchantInfo[tLine.dwIndex].EnchantID)
                local _, nPos = ItemData.GetEquipItemEquiped(GetClientPlayer(), nSub, -1)
                if nPos == EQUIPMENT_INVENTORY.RIGHT_RING then
                    nPos = EQUIPMENT_INVENTORY.LEFT_RING
                end
                if not tEnchant[nPos] then
                    tEnchant[nPos] = {}
                end
                tLine.dwEnchantID = CraftData.g_EnchantInfo[tLine.dwIndex].EnchantID
                table.insert(tEnchant[nPos], tLine)
            end
        else
            print("ArenaEquipDIYData.GetEnchant no this item or no enchantid %d %d", tLine.dwTabType, tLine.dwIndex)
        end
    end
    return tEnchant
end

function ArenaEquipDIYData.GetColorDiamond()
    local tColorDiamond = {}
    local nCount = g_tTable.JJCDIYColorDiamond:GetRowCount()
    for i = 2, nCount do
        local tLine = g_tTable.JJCDIYColorDiamond:GetRow(i)
        local hItemInfo = GetItemInfo(tLine.dwTabType, tLine.dwIndex)
        if hItemInfo then
            if IsFitKungfu(tLine.szKungfuID) then
                table.insert(tColorDiamond, tLine)
            end
        else
            print("ArenaEquipDIYData.GetColorDiamond no this item %d %d", tLine.dwTabType, tLine.dwIndex)
        end
    end
    return tColorDiamond
end
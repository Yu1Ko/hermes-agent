Adapter = Adapter or {}
local self = Adapter

function RegisterEvent(szEventName, fnCallback)
    Event.Reg(self, szEventName, function(...)
        fnCallback(szEventName, ...)
    end)
end

function GetBagContainType(dwBox)
    local player = GetClientPlayer()
    local dwGener, dwSub = player.GetContainType(dwBox)
    if dwGener == ITEM_GENRE.BOOK then
        return 4
    end
    if dwGener == ITEM_GENRE.MATERIAL then
        return dwSub
    end
    return 0
end

function GetPlayerItem(player, dwBox, dwX, szPackageType, dwASPSource)
    return ItemData.GetPlayerItem(player, dwBox, dwX, szPackageType, dwASPSource)
end
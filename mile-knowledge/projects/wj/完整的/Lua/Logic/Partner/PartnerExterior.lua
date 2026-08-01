PartnerExterior = PartnerExterior or {}

local self = PartnerExterior

---@param tRepresentID table<number, number> EQUIPMENT_REPRESENT -> 外观id
---@param nType number 外观类型，枚举参考 NPC_EXTERIOR_TYPE
---@param tInfo PreviewNpcExteriorInfo 预览外观信息
function PartnerExterior.UpdateRepresentID(tRepresentID, nType, tInfo)
    local nSource = tInfo.nSource

    if nSource == NPC_EXTERIOR_SOURCE_TYPE.NPC_HAVE then
        local tData        = tInfo.tData
        local dwExteriorID = tData.dwID
        if dwExteriorID ~= 0 then
            Partner_UpdatePreviewRepresentID(tRepresentID, nType, dwExteriorID)
        end
    elseif nSource == NPC_EXTERIOR_SOURCE_TYPE.PLAYER_GOODS then
        self.GetPlayerExteriorRepresentID(tRepresentID, nType, tInfo)
    elseif nSource == NPC_EXTERIOR_SOURCE_TYPE.PLAYER_ITEM then
        self.GetPlayerItemRepresentID(tRepresentID, tInfo)
    end
end

---@param tRepresentID table<number, number> EQUIPMENT_REPRESENT -> 外观id
---@param nType number 外观类型，枚举参考 NPC_EXTERIOR_TYPE
---@param tInfo PreviewNpcExteriorInfo 预览外观信息
function PartnerExterior.GetPlayerExteriorRepresentID(tRepresentID, nType, tInfo)
    local tData = tInfo.tData
    if nType == NPC_EXTERIOR_TYPE.HAIR then
        local nHairID = tData.dwID
        PartnerView.PreviewHair(tRepresentID, nHairID)
    elseif nType == NPC_EXTERIOR_TYPE.CHEST then
        local tSub = tData.tSub
        PartnerView.PreviewExterior(tRepresentID, tSub)
    end
end

---@param tRepresentID table<number, number> EQUIPMENT_REPRESENT -> 外观id
---@param tInfo PreviewNpcExteriorInfo 预览外观信息
function PartnerExterior.GetPlayerItemRepresentID(tRepresentID, tInfo)
    local tData = tInfo.tData
    local dwID  = tData.dwID
    local pItem = GetItem(dwID)
    if pItem then
        PartnerView.PreviewItem(tRepresentID, pItem)
    end
end
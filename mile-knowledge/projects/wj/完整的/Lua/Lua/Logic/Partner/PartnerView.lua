PartnerView = PartnerView or {}

-- note: 搬运自 ui/Config/Default/Partner/PartnerView.lua 可能需要定期与其保持同步
--module("PartnerView", ExportExternalLib)

local tViewClear =
{
    --EQUIPMENT_REPRESENT.HELM_STYLE, -- 本来侠客帽子是默认屏蔽的，由于出了有帽子的侠客，需要根据有没有发型判断一下是否显示
    EQUIPMENT_REPRESENT.CHEST_STYLE,
    EQUIPMENT_REPRESENT.BANGLE_STYLE,
    EQUIPMENT_REPRESENT.WAIST_STYLE,
    EQUIPMENT_REPRESENT.BOOTS_STYLE,
    EQUIPMENT_REPRESENT.FACE_EXTEND,
    EQUIPMENT_REPRESENT.BACK_EXTEND,
    EQUIPMENT_REPRESENT.WAIST_EXTEND,
    EQUIPMENT_REPRESENT.WEAPON_STYLE,
    EQUIPMENT_REPRESENT.BIG_SWORD_STYLE,
    EQUIPMENT_REPRESENT.GLASSES_EXTEND,
    EQUIPMENT_REPRESENT.L_GLOVE_EXTEND,
    EQUIPMENT_REPRESENT.R_GLOVE_EXTEND,
    EQUIPMENT_REPRESENT.HEAD_EXTEND,
    EQUIPMENT_REPRESENT.HEAD_EXTEND1,
    EQUIPMENT_REPRESENT.HEAD_EXTEND2,
}

function PartnerView.GetPlayerEmptyRepresent()
    local tRepresentID = {}
    for i = 0, EQUIPMENT_REPRESENT.TOTAL - 1 do
        tRepresentID[i] = 0
    end
    return tRepresentID
end

--预览衣服的tRepresentID
function PartnerView.PreviewExterior(tRepresentID, tSub)
    for _, nRepresentSub in ipairs(tViewClear) do -- 侠客外观预览时需要屏蔽武器等等不想展示的部位
        tRepresentID[nRepresentSub] = 0
    end

    local dwHairStyle = tRepresentID[EQUIPMENT_REPRESENT.HAIR_STYLE]
    if dwHairStyle and dwHairStyle ~= 0 then
        tRepresentID[EQUIPMENT_REPRESENT.HELM_STYLE] = 0
    end

    for _, dwID in ipairs(tSub) do
        local tExteriorInfo = GetExterior().GetExteriorInfo(dwID)
        local nRepresentSub = Exterior_SubToRepresentSub(tExteriorInfo.nSubType)
        local nRepresentColor = Exterior_RepresentSubToColor(nRepresentSub)
        tRepresentID[nRepresentSub] = tExteriorInfo.nRepresentID
        tRepresentID[nRepresentColor] = tExteriorInfo.nColorID
    end
end

--预览头发的tRepresentID
function PartnerView.PreviewHair(tRepresentID, dwHairID)
    tRepresentID[EQUIPMENT_REPRESENT.HAIR_STYLE] = dwHairID
end

local function ResUpdate_Exterior(tRepresentID, dwExteriorID, nIndex)
    local tExteriorInfo = GetExterior().GetExteriorInfo(dwExteriorID)

    local nRepresentSub = Exterior_BoxIndexToRepresentSub(nIndex)
    local nRepresentColor = Exterior_RepresentSubToColor(nRepresentSub)

    tRepresentID[nRepresentSub] = tExteriorInfo.nRepresentID
    tRepresentID[nRepresentColor] = tExteriorInfo.nColorID
end

--预览道具
function PartnerView.PreviewItem(tRepresentID, hItem)
    if not (hItem.nGenre == ITEM_GENRE.COIN_SHOP_QUANTITY_LIMIT_ITEM and
            (hItem.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.EXTERIOR or hItem.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.HAIR)) then
        return
    end

    if hItem.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.EXTERIOR then --预览成衣
        local dwID = hItem.nDetail
        local nIndex = Exterior_GetSubIndex(hItem.nDetail)
        ResUpdate_Exterior(tRepresentID, hItem.nDetail, nIndex)
    elseif hItem.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.HAIR then --预览发型
        local dwID = hItem.nDetail
        tRepresentID[EQUIPMENT_REPRESENT.HAIR_STYLE] = dwID
    end
end

local tNpcToPlayerIndex =
{
    [NPC_EQUIP_REPRESENT.FACE_STYLE]        = EQUIPMENT_REPRESENT.FACE_STYLE,
    [NPC_EQUIP_REPRESENT.HAIR_STYLE]        = EQUIPMENT_REPRESENT.HAIR_STYLE,
    [NPC_EQUIP_REPRESENT.HELM_STYLE]        = EQUIPMENT_REPRESENT.HELM_STYLE,
    [NPC_EQUIP_REPRESENT.CHEST_STYLE]       = EQUIPMENT_REPRESENT.CHEST_STYLE,
    [NPC_EQUIP_REPRESENT.CHEST_COLOR]       = EQUIPMENT_REPRESENT.CHEST_COLOR,
    [NPC_EQUIP_REPRESENT.WAIST_STYLE]       = EQUIPMENT_REPRESENT.WAIST_STYLE,
    [NPC_EQUIP_REPRESENT.BANGLE_STYLE]      = EQUIPMENT_REPRESENT.BANGLE_STYLE,
    [NPC_EQUIP_REPRESENT.BOOTS_STYLE]       = EQUIPMENT_REPRESENT.BOOTS_STYLE,
    [NPC_EQUIP_REPRESENT.WEAPON_STYLE]      = EQUIPMENT_REPRESENT.WEAPON_STYLE,
}

--从npc表现表转成player的
function PartnerView.NPCRepresentToPlayerRepresent(tRepresentID)
    local tNewRepresentID = {}
    for nIndex, nRepresentID in pairs(tRepresentID) do
        local nNewIndex = tNpcToPlayerIndex[nIndex]
        tNewRepresentID[nNewIndex] = nRepresentID
    end
    return tNewRepresentID
end
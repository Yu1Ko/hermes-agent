-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: CoinShopEffectCustom
-- Date: 2026-02-05 15:48:27
-- Desc: ?
-- ---------------------------------------------------------------------------------

CoinShopEffectCustom = CoinShopEffectCustom or {className = "CoinShopEffectCustom"}
local self = CoinShopEffectCustom

local DEFAULT_CUSTOM_DATA = {
    fScale = 1,
    nOffsetX = 0, nOffsetY = 0, nOffsetZ = 0,
    fRotationX = 0, fRotationY = 0, fRotationZ = 0,
}

function CoinShopEffectCustom.Init()
    CoinShopEffectCustom.szType = "CircleBody"
    CoinShopEffectCustom.nType = PLAYER_SFX_REPRESENT.SURROUND_BODY
    CoinShopEffectCustom.bChoosePendant = false

    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    CoinShopEffectCustom.nRoleType = hPlayer.nRoleType
    CoinShopEffectCustom.LoadPendantPos()
    CoinShopEffectCustom.UpdateMyChoose()
end

function CoinShopEffectCustom.UnInit()
    CoinShopEffectCustom.dwEffectID = nil
    CoinShopEffectCustom.nRoleType = nil
    CoinShopEffectCustom.tPendantPos = nil
    CoinShopEffectCustom.tCustomInfo = nil
    CoinShopEffectCustom.bChoosePendant = false
    CoinShopEffectCustom.tCustomEffectData = nil
    CoinShopEffectCustom.tNowCustomEffectData = nil
end

function CoinShopEffectCustom.LoadPendantPos()
    local  nCount = g_tTable.PendantPos:GetRowCount()
	CoinShopEffectCustom.tPendantPos = {}
	for i = 2, nCount do
        local tLine = g_tTable.PendantPos:GetRow(i)
		if not CoinShopEffectCustom.tPendantPos[tLine.dwClassID] then
			CoinShopEffectCustom.tPendantPos[tLine.dwClassID] = {}
		end
        table.insert(CoinShopEffectCustom.tPendantPos[tLine.dwClassID], tLine)
    end
end

function CoinShopEffectCustom.UpdateMyChoose()
    local tInfo = ExteriorCharacter.GetPreviewEffect(CoinShopEffectCustom.nType)
    local dwEffectID = tInfo and tInfo.nEffectID
    if not dwEffectID then
        CoinShopEffectCustom.bChoosePendant = false
        return
    end

    local tInfo = Table_GetPendantEffectInfo(dwEffectID)
    CoinShopEffectCustom.dwEffectID = dwEffectID
    CoinShopEffectCustom.dwRepresentID = tInfo.dwRepresentID
    CoinShopEffectCustom.tEffectInfo = tInfo
    CoinShopEffectCustom.bChoosePendant = true

    CoinShopEffectCustom.tCustomInfo   = GetSFXCustomInfo(CoinShopEffectCustom.nRoleType, dwEffectID)

    local tCustomData = CharacterEffectData.GetLocalCustomEffectDataEx(CoinShopEffectCustom.nType, dwEffectID)
    CoinShopEffectCustom.tCustomEffectData = clone(tCustomData)
    CoinShopEffectCustom.tNowCustomEffectData = clone(tCustomData)
end

function CoinShopEffectCustom.GetScrollPos(nValue, nMin, nStep)
	local nPos = math.floor((nValue -  nMin) / nStep)
	return nPos
end

function CoinShopEffectCustom.UpdateNowData(szKey, nValue)
    CoinShopEffectCustom.tNowCustomEffectData[szKey] = nValue
end

function CoinShopEffectCustom.ResetData(szKey)
    CoinShopEffectCustom.tNowCustomEffectData[szKey] = CoinShopEffectCustom.tCustomEffectData[szKey]
end

function CoinShopEffectCustom.ResetAll()
    CoinShopEffectCustom.tNowCustomEffectData = clone(CoinShopEffectCustom.tCustomEffectData)
end

function CoinShopEffectCustom.GetData(nType)
    if nType ~= CoinShopEffectCustom.nType then
        return
    end
    if not CoinShopEffectCustom.tNowCustomEffectData then
        return
    end
    return CoinShopEffectCustom.tNowCustomEffectData
end

function CoinShopEffectCustom.ResetModel()
    local tCustomData = CharacterEffectData.GetLocalCustomEffectDataEx(CoinShopEffectCustom.nType, CoinShopEffectCustom.dwEffectID)
    CoinShopEffectCustom.tNowCustomEffectData = clone(tCustomData)
    ExteriorCharacter.UpdateEffectPos(CoinShopEffectCustom.nType)
end

local function OnPlayDataToLocal()
    local szType = "CircleBody"
    local dwEffectID = CharacterEffectData.GetEffectEquipByType(szType)
    if dwEffectID then
        CharacterEffectData.CustomEffectPlayerDataToLocal(PLAYER_SFX_REPRESENT.SURROUND_BODY, dwEffectID)
    end
end

Event.Reg(self, "ON_CUSTOM_SFX_DATA_CHANGE", function()
    if arg0 == PLAYER_SFX_REPRESENT.SURROUND_BODY then
        OnPlayDataToLocal()
        FireUIEvent("COINSHOPVIEW_ROLE_DATA_UPDATE")
    end
end)
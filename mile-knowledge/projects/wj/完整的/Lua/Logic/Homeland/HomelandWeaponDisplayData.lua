HomelandWeaponDisplayData = HomelandWeaponDisplayData or {}
local self = HomelandWeaponDisplayData

function HomelandWeaponDisplayData.Init(tData)
    self.tData = tData
    local nForce = UI_GetPlayerForceID()
    self.bCJ = nForce == FORCE_TYPE.CANG_JIAN
end

function HomelandWeaponDisplayData.UnInit()
    self.tData = nil
    self.bCJ = nil
end

function HomelandWeaponDisplayData.GetWeaponInfo(dwWeaponExteriorID)
    local tWeaponInfo = g_tTable.CoinShop_Weapon:Search(dwWeaponExteriorID)
    return tWeaponInfo
end

function HomelandWeaponDisplayData.FilterWeapons(nDetail)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return {}
    end
    local hExteriorClient = GetExterior()
    if not hExteriorClient then
        return {}
    end
    local tWeaponList = hPlayer.GetAllWeaponExterior()
    local tList = {}
    for _, tWeapon in ipairs(tWeaponList) do
        local tWeaponInfo = self.GetWeaponInfo(tWeapon.dwWeaponExteriorID)
        if tWeaponInfo then
            if nDetail then
                local tInfo = CoinShop_GetWeaponExteriorInfo(tWeapon.dwWeaponExteriorID, hExteriorClient)
                if nDetail == tInfo.nDetailType then
                    table.insert(tList, {dwIndex = tWeapon.dwWeaponExteriorID, szName = tWeaponInfo.szName})
                end
            else
                table.insert(tList, {dwIndex = tWeapon.dwWeaponExteriorID, szName = tWeaponInfo.szName})
            end
        end
    end
    return tList
end

function HomelandWeaponDisplayData.GameProtocol(dwID, dwID2, nBtnID)
	local tData = self.tData
	if not tData then
		return
	end
	local dwValue1, dwValue2, dwValue3, dwValue4, dwValue5, dwValue6, dwValue7, dwValue8
	local pHlMgr = GetHomelandMgr()
    if not pHlMgr then
        return
    end
	dwValue1 = pHlMgr.SetDWORDValueByuint8(dwValue1, 1, tData.nGameID) --游戏类型ID
	dwValue1 = pHlMgr.SetDWORDValueByuint8(dwValue1, 2, nBtnID) --按钮
    dwValue2 = dwID --武器ID1

    if dwID2 then
        dwValue3 = dwID2 --武器ID2
    end

	pHlMgr.CallSDFourDwordScript(tData.nFurnitureInstanceID, tData.nDataPos, dwValue1, dwValue2, dwValue3, dwValue4, dwValue5, dwValue6, dwValue7, dwValue8)

    UIMgr.Close(VIEW_ID.PanelHomeInteract)
end
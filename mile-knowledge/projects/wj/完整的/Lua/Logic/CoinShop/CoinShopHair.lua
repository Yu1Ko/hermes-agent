-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: CoinShopHair
-- Date: 2023-04-13 10:10:30
-- Desc: ?
-- ---------------------------------------------------------------------------------

CoinShopHair = CoinShopHair or {className = "CoinShopHair"}
local self = CoinShopHair
-------------------------------- 消息定义 --------------------------------
CoinShopHair.Event = {}
CoinShopHair.Event.XXX = "CoinShopHair.Msg.XXX"

function CoinShopHair.Init()
	Event.Reg(self, EventType.OnRoleLogin, function()
		CoinShopHair.tMyHairList = nil
	end)
end

function CoinShopHair.UnInit()

end

function CoinShopHair.OnLogin()

end

function CoinShopHair.OnFirstLoadEnd()

end

function CoinShopHair.GetHairBodyText(hHairShopClient, nHair, szType)
	local tHairIndex = {hHairShopClient.GetHairIndex(nHair)}

	local tBodyIndex =
	{
		["Hair"]  =  1,
		["Bang"]  =  2,
		["Plait"] =  3,
	}
	local nIndex = tBodyIndex[szType]
	local nRepresentID = tHairIndex[nIndex]
	local nID, szHairName = self.GetHairUIID(szType, nRepresentID)
	return szHairName, nID
end

function CoinShopHair.GetHairText(nHairID)
	local hHairShopClient = GetHairShop()
	if not hHairShopClient then
		return
	end

	local nHeadID, nBangID, nPlaitID = hHairShopClient.GetHairIndex(nHairID)
	if not nHeadID or not nBangID or not nPlaitID then
		return ""
	end
	local nHeadUIID = self.GetHairUIID("Hair", nHeadID)
	local nBangUIID = self.GetHairUIID("Bang", nBangID)
	local nPlaitUIID = self.GetHairUIID("Plait", nPlaitID)
	if not nHeadUIID or not nBangUIID or not nPlaitUIID then
		return ""
	end
	local szText = self.GetHairBodyText(hHairShopClient, nHairID, "Hair")
	if nBangID ~= 0 then
		szText = szText .. "+" .. self.GetHairBodyText(hHairShopClient, nHairID, "Bang")
	end
	if nPlaitID ~= 0 then
		szText = szText .. "+" ..  self.GetHairBodyText(hHairShopClient, nHairID, "Plait")
	end

	return szText, nHeadUIID .. "+" .. nBangUIID .. "+" .. nPlaitUIID
end

function CoinShopHair.GetHairInfo(szType, nRepresentID)
	local tHairMap = CoinShopData.GetHairMap()
	local tInfo = tHairMap["re" .. szType][nRepresentID]
	return tInfo
end

function CoinShopHair.GetHairUIID(szType, nRepresentID)
	if nRepresentID == 0 then
		return 0, g_tStrings.STR_NAME_HAIR_BASE
	end

	local tHairMap = CoinShopData.GetHairMap()

	if not tHairMap["re" .. szType] or not tHairMap["re" .. szType][nRepresentID] then
		return 0, g_tStrings.STR_NAME_HAIR_BASE
	end

	local nID = tHairMap["re" .. szType][nRepresentID][1]
	local szHairName = tHairMap["re" .. szType][nRepresentID][3]
	return nID, szHairName
end

function CoinShopHair.GetHairShowType(nHairID)
	local hHairShopClient = GetHairShop()
	if not hHairShopClient then
		return
	end

	local nHeadID, nBangID, nPlaitID = hHairShopClient.GetHairIndex(nHairID)
	local tInfo = CoinShopHair.GetHairInfo("Hair", nHeadID)
	if tInfo then
		return tInfo[4]
	end
end

function CoinShopHair.GetMyHairList(bReload)
	if not CoinShopHair.tMyHairList or bReload then
		local hPlayer = GetClientPlayer()
		if not hPlayer then
			return
		end

		CoinShopHair.tMyHairList = {}
		local tHairList = hPlayer.GetAllHair(HAIR_STYLE.HAIR)

		local tbFilterDefSelected = FilterDef.CoinShowHairType.tbRuntime
        local nFilterType = HAIR_SHOW_TYPE.ALL
        if tbFilterDefSelected then
            nFilterType = tbFilterDefSelected[1][1]
        end

		local nCount = #tHairList
		for i = nCount, 1, -1 do
			if nFilterType == HAIR_SHOW_TYPE.DYEING then
				local tList = hPlayer.GetHairCustomDyeingList(tHairList[i].dwID)
				local bDyeing = tList and not IsTableEmpty(tList)
				if bDyeing then
					table.insert(CoinShopHair.tMyHairList, tHairList[i].dwID)
				end
			else
				local nShowType = CoinShopHair.GetHairShowType(tHairList[i].dwID)
				if nFilterType == HAIR_SHOW_TYPE.ALL or nShowType == nFilterType then
					table.insert(CoinShopHair.tMyHairList, tHairList[i].dwID)
				end
			end
		end
	end

    return CoinShopHair.tMyHairList
end

function CoinShopHair.SetRename(nIndex, szText)
    if not TextFilterCheck(UIHelper.UTF8ToGBK(szText)) then --过滤文字
        TipsHelper.ShowNormalTip(g_tStrings.STR_BODY_RENAME_ERROR)
        return
    end
    if szText == "" then
        szText = nil
    end

    for k, v in pairs(Storage.Character.tbHairName) do
        if v == szText then
            TipsHelper.ShowNormalTip(g_tStrings.STR_BODY_RENAME_ERROR2)
            return
        end
    end
    Storage.Character.tbHairName[nIndex] = szText
    Storage.Character.Flush()

    TipsHelper.ShowNormalTip("已成功修改备注")
end

function CoinShopHair.GetHairName(nIndex)
    if not Storage.Character or not Storage.Character.tbHairName then
        return
    end
    return Storage.Character.tbHairName[nIndex]
end

function CoinShopHair.GetTime(nType, nID)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local hHairShopClient = GetHairShop()
    if not hHairShopClient then
        return
    end

    local tHairPrice = hHairShopClient.GetHairPrice(hPlayer.nRoleType, nType, nID)
    return CoinShop_GetTime(tHairPrice)
end

function CoinShopHair.GetCountDownInfo(nType, nID)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local hHairShopClient = GetHairShop()
    if not hHairShopClient then
        return
    end

    local tHairPrice = hHairShopClient.GetHairPrice(hPlayer.nRoleType, nType, nID)
    return CoinShop_GetCountDownInfo(tHairPrice)
end

Event.Reg(CoinShopExterior, "ADD_HAIR", function (nHairType, dwID)
	if nHairType == HAIR_STYLE.HAIR then
    	RedpointHelper.Hair_SetNew(dwID, true)
	end
end)

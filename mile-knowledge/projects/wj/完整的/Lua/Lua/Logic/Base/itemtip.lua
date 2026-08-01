local function GetBuyIndexTip(nBuyIndex)
	local szText = CoinShop_GetBuyIndexTip(nBuyIndex)

	return szText
end

local function GetRewardsTip(dwTabType, dwIndex)
	local nRewards = GetFinalItemRewards(dwTabType, dwIndex)
	if nRewards == 0 then
		return ""
	else
		local szTip = GetFormatText(FormatString(g_tStrings.STR_ITEM_GET_REWARDS, nRewards), 18)
		szTip = szTip .."<image>path=" .. EncodeComponentsString("ui\\Image\\UICommon\\ExteriorBox3.UITex")
		.. " frame=16 </image>"
		return szTip
	end
end

local function GetItemRewardsTip(item)
	local dwTabType, dwIndex = item.dwTabType, item.dwIndex
	return GetRewardsTip(dwTabType, dwIndex)
end

local function GetGoodsRewardsTip(dwGoodsType, dwGoodsID, tPrice)
	local bDis = CoinShop_IsDis(tPrice, dwGoodsType, dwGoodsID)
	local nDis = tPrice.nDiscount or 100
	local nRewards = GetGoodsRewards_UI(dwGoodsType, dwGoodsID, bDis, nDis)
	if nRewards == 0 then
		return ""
	else
		local szTip = GetFormatText(FormatString(g_tStrings.STR_ITEM_BUY_GET_REWARDS, nRewards), 18)
		szTip = szTip .."<image>path=" .. EncodeComponentsString("ui\\Image\\UICommon\\ExteriorBox3.UITex")
		.. " frame=16 </image>"
		return szTip
	end
end

function GetGoodsRewards_UI(eGoodsType, dwID, bDis, nDis, nRewards)
	if not nRewards then
		local hPlayer = GetClientPlayer()
        if not hPlayer then
            return
        end
		if hPlayer.dwForceID == FORCE_TYPE.CANG_JIAN then
            nRewards = GetFinalGoodsRewardsForCangjian(eGoodsType, dwID)
        else
            nRewards = GetFinalGoodsRewards(eGoodsType, dwID)
        end
	end
	if not nRewards then
		return 0
	end
	if bDis then
		nRewards = math.floor(nRewards * nDis / 100 + 0.5)
	end
	return nRewards
end

local function SetRewardsTip(hSubInfo, fY, nRewards, tInfo, eGoodsType, dwID)
	local bDis, szDisCount, _, nDisCount = CoinShop_GetDisInfo(tInfo)
	local nRewards = GetGoodsRewards_UI(eGoodsType, dwID, bDis, nDisCount, nRewards)

	local hCurrency = hSubInfo:Lookup("Handle_Currency")
	if nRewards and nRewards ~= 0 then
		local hText = hCurrency:Lookup("Text_Currency")
		hText:SetText(nRewards)
		hCurrency:SetRelY(fY)
		hText:AutoSize()
		hCurrency:FormatAllItemPos()
		hSubInfo:FormatAllItemPos()
		hCurrency:Show()
		local hText = hCurrency:Lookup("Text_Currency_Title")
		if tInfo.bIsReal then
			hText:SetText(g_tStrings.STR_COINSHOP_RMB_BUY_TIP)
		else
			hText:SetText(g_tStrings.STR_COINSHOP_COIN_BUY_TIP)
		end
		return true
	else
		hCurrency:Hide()
	end
	return false
end

local CRAFT_ID_READ_COPY = 12
local CRAFT_ID_READ = 8

-------七夕------
--获取铭刻名字的Tip的通用函数，有特殊需求可以另外写
local function GetCustomNameTip(pPlayer, nDataPos, szTipGroupName)
	local szTip = ""
	local nQixiRingOwnerID = GetQixiRingOwnerID()
	local tInscriptionInfo = GetQiXiInscriptionInfo(nQixiRingOwnerID)
	if nQixiRingOwnerID and tInscriptionInfo and not IsRemotePlayer(pPlayer.dwID) and not IsRemotePlayer(nQixiRingOwnerID) then
		if tInscriptionInfo[1] and tInscriptionInfo[1].szName and tInscriptionInfo[nDataPos] and tInscriptionInfo[nDataPos].szName then
			szTip = "<Text>text=" .. EncodeComponentsString(g_tStrings[szTipGroupName].TITLE) .. " font=100 </text>" ..
					"<Text>text=" .. EncodeComponentsString(g_tStrings[szTipGroupName].MARK[1]) .. " font=105 </text>" ..
					"<Text>text=" .. EncodeComponentsString("%s") .. " font=112 </text>" ..
					"<Text>text=" .. EncodeComponentsString(g_tStrings[szTipGroupName].AND) .. " font=105 </text>" ..
					"<Text>text=" .. EncodeComponentsString("%s") .. " font=112 </text>" ..
					"<Text>text=" .. EncodeComponentsString(g_tStrings[szTipGroupName].TAIL) .. " font=105 </text>"
			--szTip = szTip:format(tInscriptionInfo[1].szName, tInscriptionInfo[nDataPos].szName)
			if nDataPos == 11 then  -- 师徒武器特殊处理
				szTip = szTip:format(tInscriptionInfo[nDataPos].szName, tInscriptionInfo[1].szName)
			else
				szTip = szTip:format(tInscriptionInfo[1].szName, tInscriptionInfo[nDataPos].szName)
			end
		end
	end
	return szTip
end

local function GetQiXiTip( player, item )
	local szTip = ""
	------- 七夕配对玩家名字 ------
	local tQixiRings = {[1899] = true, [1900] = true, [1901] = true, [1902] = true, [1903] = true, [1904] = true, [1905] = true, [1906] = true, [1907] = true, [1908] = true, [1909] = true, [1910] = true, [1911] = true, [1912] = true, [1913] = true, [1914] = true, [1915] = true, }
	if not IsRemotePlayer(player.dwID) and GetQixiRingOwnerID() and not IsRemotePlayer(GetQixiRingOwnerID()) and GetQiXiInscriptionInfo(GetQixiRingOwnerID()) and item.nGenre == ITEM_GENRE.EQUIPMENT and item.nSub == EQUIPMENT_SUB.RING and tQixiRings[item.dwIndex] then
		local tInfo = GetQiXiInscriptionInfo(GetQixiRingOwnerID())
		if (tInfo and tInfo[1] and tInfo[1].szName) then
			local szTipQixiRing = ""
			if tInfo[2] and tInfo[2].szName and tInfo[3] and tInfo[3].szName then
				szTipQixiRing = "<Text>text=" .. EncodeComponentsString(g_tStrings.QIXI_TIPS.TITLE) .. " font=100 </text>" ..
					"<Text>text=" .. EncodeComponentsString(g_tStrings.QIXI_TIPS.MARK[1]) .. " font=105 </text>" ..
					"<Text>text=" .. EncodeComponentsString("%s") .. " font=112 </text>" ..
					"<Text>text=" .. EncodeComponentsString(g_tStrings.QIXI_TIPS.AND) .. " font=105 </text>" ..
					"<Text>text=" .. EncodeComponentsString("%s") .. " font=112 </text>" ..
					"<Text>text=" .. EncodeComponentsString(g_tStrings.QIXI_TIPS.MARK[2]) .. " font=105 </text>" ..
					"<Text>text=" .. EncodeComponentsString("%s") .. " font=112 </text>" ..
					"<Text>text=" .. EncodeComponentsString(g_tStrings.QIXI_TIPS.TAIL) .. " font=105 </text>"
				szTipQixiRing = szTipQixiRing:format(tInfo[1].szName, tInfo[2].szName, tInfo[3].szName)
			elseif tInfo[2] and tInfo[2].szName then
				szTipQixiRing = "<Text>text=" .. EncodeComponentsString(g_tStrings.QIXI_TIPS.TITLE) .. " font=100 </text>" ..
					"<Text>text=" .. EncodeComponentsString(g_tStrings.QIXI_TIPS.MARK[1]) .. " font=105 </text>" ..
					"<Text>text=" .. EncodeComponentsString("%s") .. " font=112 </text>" ..
					"<Text>text=" .. EncodeComponentsString(g_tStrings.QIXI_TIPS.AND) .. " font=105 </text>" ..
					"<Text>text=" .. EncodeComponentsString("%s") .. " font=112 </text>" ..
					"<Text>text=" .. EncodeComponentsString(g_tStrings.QIXI_TIPS.TAIL) .. " font=105 </text>"
				szTipQixiRing = szTipQixiRing:format(tInfo[1].szName, tInfo[2].szName)
			elseif tInfo[3] and tInfo[3].szName then
				szTipQixiRing = "<Text>text=" .. EncodeComponentsString(g_tStrings.QIXI_TIPS.TITLE) .. " font=100 </text>" ..
					"<Text>text=" .. EncodeComponentsString(g_tStrings.QIXI_TIPS.MARK[1]) .. " font=105 </text>" ..
					"<Text>text=" .. EncodeComponentsString("%s") .. " font=112 </text>" ..
					"<Text>text=" .. EncodeComponentsString(g_tStrings.QIXI_TIPS.AND) .. " font=105 </text>" ..
					"<Text>text=" .. EncodeComponentsString("%s") .. " font=112 </text>" ..
					"<Text>text=" .. EncodeComponentsString(g_tStrings.QIXI_TIPS.TAIL) .. " font=105 </text>"
				szTipQixiRing = szTipQixiRing:format(tInfo[1].szName, tInfo[3].szName)
			end
			szTip = szTip .. szTipQixiRing
		end
	end
	--七夕连理枝
	local tQixiPendants = {[4196] = true, [4197] = true, [4198] = true, [4199] = true, [4200] = true, [4201] = true, [4202] = true, [4203] = true, [4204] = true, [4205] = true, [4206] = true, [4207] = true, [4208] = true,}
	if item.nGenre == ITEM_GENRE.EQUIPMENT and item.nSub == EQUIPMENT_SUB.PENDANT and tQixiPendants[item.dwIndex] then
		szTip = szTip .. GetCustomNameTip(player, 4, "QIXI_TIPS2")
	end
	--七夕同心锁
	local tQixiTongXinSuo = {[5848] = true, [5849] = true, [5850] = true, [5851] = true, [5852] = true, [5853] = true, [5854] = true, [5855] = true, [5856] = true, [5857] = true, [5858] = true, [5859] = true, [5860] = true, [5861] = true, [5862] = true,}
	if item.nGenre == ITEM_GENRE.EQUIPMENT and item.nSub == EQUIPMENT_SUB.AMULET and tQixiTongXinSuo[item.dwIndex] then
		szTip = szTip .. GetCustomNameTip(player, 5, "QIXI_TIPS3")
	end
	--七夕无棱
	local tQixiTongXinSuo = {[10320] = true, [10321] = true, [10322] = true, [10323] = true, [10324] = true, [10325] = true,}
	if item.nGenre == ITEM_GENRE.EQUIPMENT and item.nSub == EQUIPMENT_SUB.RING and tQixiTongXinSuo[item.dwIndex] then
		szTip = szTip .. GetCustomNameTip(player, 6, "QIXI_TIPS3")
	end
		-- 师徒武器
	local tShiTuWuQi = {
		[15413] = true,
		[15414] = true,
		[15415] = true,
		[15416] = true,
		[15417] = true,
		[15418] = true,
		[15419] = true,
		[15420] = true,
		[15421] = true,
		[15422] = true,
		[15423] = true,
		[15424] = true,
		[15425] = true,
		[15426] = true,
		[15427] = true,
		[15428] = true,
		[15429] = true,
		[15430] = true,
		[15431] = true,
		[15432] = true,
		[15433] = true,
		[15434] = true,
		[15435] = true,
		[15436] = true,
}
	if item.nGenre == ITEM_GENRE.EQUIPMENT and item.nSub == EQUIPMENT_SUB.MELEE_WEAPON and tShiTuWuQi[item.dwIndex] then
		szTip = szTip .. GetCustomNameTip(player, 11, "SHITU")
	end
	return szTip
end

local function GetEquipRecipeDesc(Value1, Value2)
	local szText = ""
	local tRecipeSkillAtrri = g_tTable.EquipmentRecipe:Search(Value1, Value2)
	if tRecipeSkillAtrri then
		szText = tRecipeSkillAtrri.szDesc
	end
	return szText;
end

local function GetFreeTryonTip(dwGoodType, dwGoodID)
	if not dwGoodID or dwGoodID == 0 then
		return ""
	end

	local szTip = ""
	local client = GetCoinShopClient()
	if client.IsGoodsPlayerTryOn(dwGoodType, dwGoodID) then
		local endtime = client.GetFreeTryOnEndTime()
		local time = GetCurrentTime()
		local delta = endtime - time
		if delta > 0 then
			szTip = GetFormatText( FormatString(g_tStrings.STR_FREE_TIME, GetTimeText(delta, nil, true)), nil, 255, 0, 0 )
		else
			szTip = GetFormatText(g_tStrings.STR_EXPIRED, nil, 255, 0, 0)
		end
	end
	return szTip
end

local _Item2GoodID = {}
function GetItemGoodID(dwTabType, dwIndex)
	local key = dwTabType.."_"..dwIndex
	if not _Item2GoodID[key] then
		_Item2GoodID[key] = Table_GetRewardsGoodID(dwTabType, dwIndex) or 0
	end
	return _Item2GoodID[key]
end

function GetItemFontColorByStrengthLevel(nLevel)
	local r, g, b = 0, 255, 0
	return " r="..r.." g="..g.." b="..b.." "
end


function GetEnchantDesc(dwID)
	local aAttr, dwTime, nSubType = GetEnchantAttribute(dwID)
	if not aAttr or #aAttr == 0 then
		return ""
	end
	local szDesc = UIHelper.UTF8ToGBK(g_tStrings.tEquipTypeNameTable[nSubType])
	local bFirst = true
	for k, v in pairs(aAttr) do
		EquipData.FormatAttributeValue(v)
		local szText = FormatString(Table_GetMagicAttributeInfo(v.nID, true), v.nValue1, v.nValue2, MAGIC_ATTRI_DEF, MAGIC_ATTRI_DEF)
		local szPText = UIHelper.GetPureText(szText)
		if szPText ~= "" then
			if bFirst then
				bFirst = false
			else
				szPText = "\n"..szPText
			end
		end
		szDesc = szDesc..szPText
	end
	if dwTime == 0 then
		szDesc = szDesc..g_tStrings.STR_FULL_STOP
	else
		local tEnchantTipShow = Table_GetEnchantTipShow()
		local tShow = tEnchantTipShow[nSubType]
		local bSurvival = tShow and tShow.bSurvivalEnchant
		szDesc = szDesc
		if not bSurvival then
			szDesc = szDesc ..g_tStrings.STR_COMMA .. g_tStrings.STR_TIME_DURATION .. GetTimeText(dwTime)..g_tStrings.STR_FULL_STOP
		end

	end
	return szDesc
end

function GetEnchantTip(nUiId, bCmp)
	local szTip = ""

	-----------当前装备---------------
	if bCmp then
		szTip = "<Text>text="..EncodeComponentsString(g_tStrings.TIP_CURRENT_EQUIP).."font=163 </text>"
	end

	-----------名字-------------------
	szTip = szTip.."<Text>text="..EncodeComponentsString(Table_GetItemName(nUiId).."\n")..
		" font=60 "..GetItemFontColorByQuality(1, true).." </text>"

	local szImg = "\\ui\\image\\item_pic\\"..nUiId..".UITex"
	if IsFileExist(szImg) then
		szTip = szTip.."<image>path="..EncodeComponentsString(szImg).." frame=0 </image><text>text=\"\\\n\"</text>"
	end

	local szItemDesc = GetItemDesc(nUiId)
	if szItemDesc and szItemDesc ~= "" then
		szTip = szTip..szItemDesc.."<text>text=\"\\\n\"</text>"
	end

	return szTip
end

local function GetPendantBuyIndexTip(dwItemIndex, tInfo)
	local nBuyIndex = 0
	if tInfo then
		nBuyIndex = tInfo.nBuyIndex
	end

	if nBuyIndex <= 0 then
		local hPlayer = GetClientPlayer()
		if hPlayer then
			if tInfo and IsPendantPetSub(tInfo.nSub) then
				nBuyIndex = hPlayer.GetPendentPetBuyIndex(dwItemIndex)
			else
				nBuyIndex = hPlayer.GetPendentBuyIndex(dwItemIndex)
			end
		end
	end

	return GetBuyIndexTip(nBuyIndex)
end

function OutputPendantTip(dwItemIndex, Rect, tInfo, bLink, szGuide)
	local itemInfo = GetItemInfo(ITEM_TABLE_TYPE.CUST_TRINKET, dwItemIndex)
	if not itemInfo then
		return
	end

	local szTip = "<text>text="..EncodeComponentsString(GetItemNameByItemInfo(itemInfo, nBookInfo).."\n")..
		" font=60"..GetItemFontColorByQuality(itemInfo.nQuality, true).." </text>"
	local szItemDesc = GetItemDesc(itemInfo.nUiId)
	if szItemDesc and szItemDesc ~= "" then
		szTip = szTip..szItemDesc.."<text>text=\"\\\n\"</text>"
	end
	local player = GetClientPlayer()
		--七夕君心问情--3年
	if dwItemIndex == 13937 and not IsRemotePlayer(player.dwID) and GetQixiRingOwnerID() and not IsRemotePlayer(GetQixiRingOwnerID()) and GetQiXiInscriptionInfo(GetQixiRingOwnerID()) then
			local tInfo = GetQiXiInscriptionInfo(GetQixiRingOwnerID())
			if tInfo and tInfo[1] and tInfo[1].szName and tInfo.t3Year and tInfo.t3Year.szName then
					local szTipQixiRing = ""
						szTipQixiRing = "<Text>text=" .. EncodeComponentsString(g_tStrings.QIXI_TIPS3YEAR.TITLE) .. " font=100 </text>" ..
						"<Text>text=" .. EncodeComponentsString(g_tStrings.QIXI_TIPS3YEAR.MARK[1]) .. " font=105 </text>" ..
						"<Text>text=" .. EncodeComponentsString("%s") .. " font=112 </text>" ..
						"<Text>text=" .. EncodeComponentsString(g_tStrings.QIXI_TIPS3YEAR.AND) .. " font=105 </text>" ..
							"<Text>text=" .. EncodeComponentsString("%s") .. " font=112 </text>" ..
						"<Text>text=" .. EncodeComponentsString(g_tStrings.QIXI_TIPS3YEAR.TAIL) .. " font=105 </text>"
					szTipQixiRing = szTipQixiRing:format(tInfo[1].szName, tInfo.t3Year.szName)
					szTip = szTip..szTipQixiRing
			end
	else
	--	szTip = ""
	end
	--七夕香雪流霞2015
	if dwItemIndex == 13938 then
		szTip = szTip .. GetCustomNameTip(player, 9, "QIXI_TIPS2015")
	end
	--2016桃华夭夭
	if dwItemIndex == 18348 then
		szTip = szTip .. GetCustomNameTip(player, 10, "QIXI_TIPS2016")
	end
	--2017夜雨沁荷
	if dwItemIndex == 19533 then
		szTip = szTip .. GetCustomNameTip(player, 12, "QIXI_TIPS2017")
	end
	--2018伶雀飞花
	--[[要修改的内容说明：
		1. dwItemIndex，这是每年的挂件ID
		2. tInfo[i]中的i，这个i与scripts/Map/节日七夕/include/QiXi_GetLianLiID.lua中的tLoverIDPos、tName、tLoverItem_Year、tIgnoreLoverPos有关联，它们通用一套顺序
			*这一套顺序是所有刻字的挂件按制作先后顺序排列的，因此本脚本上边2016年用的是tInfo[10]而2017年用的是tInfo[12]，中间跳过的11是刻字挂件但不是七夕情缘挂件
			*为什么数字对不上？因为tInfo最前面有一个玩家ID等其他占位占位，但没有写在QiXi_GetLianLiID.lua的tLoverIDPos、tName表里，所以正常情况下按该顺序顺延序号即可
		3. g_tStrings.QIXI_TIPS2018，其具体内容是在\client\ui\String\string.lua中定义的]]
	if dwItemIndex == 19837 then
		szTip = szTip .. GetCustomNameTip(player, 13, "QIXI_TIPS2018")
	end
    --2019佳偶天成
	if dwItemIndex == 25237 or dwItemIndex == 25238 then
		szTip = szTip .. GetCustomNameTip(player, 14, "QIXI_TIPS2019")
	end
    --2020蝶恋花
	if dwItemIndex == 25494 then
		szTip = szTip .. GetCustomNameTip(player, 15, "QIXI_TIPS2020")
	end
	--2021玲珑相思子
	if dwItemIndex == 25768 then
		szTip = szTip .. GetCustomNameTip(player, 16, "QIXI_TIPS2021")
	end
		--七夕银心铃
--	local tQixiTongXinSuo = {[11800] = true,}
	if dwItemIndex == 11800 then
		szTip = szTip .. GetCustomNameTip(player, 7, "QIXI_TIPS4")
	end
	--三尺青锋
	local tQiYuSanChiQingFeng = {[13796] = true,}
	if tQiYuSanChiQingFeng[dwItemIndex] then
		szTip = szTip .. GetCustomNameTip(player, 8, "QY_SCQF")
	end
	--2022年情人节
	if dwItemIndex == 25894 then
		szTip = szTip .. GetCustomNameTip(player, 17, "QIXI_TIPS2022QRJ")
	end
	--2022年七夕背挂
	if dwItemIndex == 26017 then
		szTip = szTip .. GetCustomNameTip(player, 18, "QIXI_TIPS2022")
	end
	-- 限时显示----

	if itemInfo.nExistType == ITEM_EXIST_TYPE.OFFLINE then
		local nLeftTime = player.GetPendentLeftExistTime(dwItemIndex) or 0
		if nLeftTime > 0 then
			local szTime = GetTimeText(nLeftTime)
			szTip = szTip..FormatString(g_tStrings.STR_ITEM_OFF_LINE_TIME_OVER, szTime)
		else
			szTip = szTip.."<Text>text="..EncodeComponentsString(g_tStrings.STR_ITEM_TIME_TYPE1.."\n").." font=107</text>"
		end
	elseif itemInfo.nExistType == ITEM_EXIST_TYPE.ONLINE then
		local nLeftTime = player.GetPendentLeftExistTime(dwItemIndex) or 0
		if nLeftTime > 0 then
			local szTime = GetTimeText(nLeftTime)
			szTip = szTip..FormatString(g_tStrings.STR_ITEM_ON_LINE_TIME_OVER, szTime)
		else
			szTip = szTip.."<Text>text="..EncodeComponentsString(g_tStrings.STR_ITEM_TIME_TYPE2.."\n").." font=107</text>"
		end
	elseif itemInfo.nExistType == ITEM_EXIST_TYPE.ONLINEANDOFFLINE or itemInfo.nExistType == ITEM_EXIST_TYPE.TIMESTAMP then
		local nLeftTime = player.GetPendentLeftExistTime(dwItemIndex) or 0
		if nLeftTime > 0 then
			local szTime = GetTimeText(nLeftTime)
			szTip = szTip..FormatString(g_tStrings.STR_ITEM_TIME_OVER, szTime)
		else
			szTip = szTip.."<Text>text="..EncodeComponentsString(g_tStrings.STR_ITEM_TIME_TYPE3.."\n").." font=107</text>"
		end
	end
	------------------
	local goodid = GetItemGoodID(ITEM_TABLE_TYPE.CUST_TRINKET, dwItemIndex)
	if goodid and goodid ~= 0 then
		szTip = szTip .. GetFreeTryonTip(COIN_SHOP_GOODS_TYPE.ITEM, goodid)
	end

	szTip = szTip .. GetPendantBuyIndexTip(dwItemIndex, tInfo)

	szTip = szTip .. GetRewardsTip(ITEM_TABLE_TYPE.CUST_TRINKET, dwItemIndex)

	if szGuide and szGuide ~= "" then
		szTip = szTip .. "<Text>text="..EncodeComponentsString(g_tStrings.STR_PENDANT_GUIDETIP).." font=168</text>" .. szGuide
	end

	OutputTip(szTip, 345, Rect, nil, bLink)
end


function OutputExteriorTip(dwExteriorID, Rect, bLink)
	local hExteriorClient = GetExterior()
	if not hExteriorClient then
		return
	end
	if dwExteriorID > 0 then
		local tExteriorInfo = hExteriorClient.GetExteriorInfo(dwExteriorID)
		local szTip = Table_GetExteriorGenreName(tExteriorInfo.nGenre) .. "\n"
		szTip = szTip .. Table_GetExteriorSetName(tExteriorInfo.nGenre, tExteriorInfo.nSet)
		szTip = szTip .. g_tStrings.STR_CONNECT .. g_tStrings.tExteriorSubName[tExteriorInfo.nSubType]
		szTip = GetFormatText(szTip)
		szTip = szTip .. GetFormatText("\n\n") .. GetFreeTryonTip(COIN_SHOP_GOODS_TYPE.EXTERIOR, dwExteriorID)

		if IsCtrlKeyDown() and not IsShiftKeyDown() and not IsAltKeyDown() then
			local szText = GetExteriorDebugText(dwExteriorID)
			szTip = szTip .. GetFormatText("\n" .. g_tStrings.DEBUG_INFO_ITEM_TIP, 102)
			szTip = szTip .. GetFormatText(szText, 102)
		end

		OutputTip(szTip, 400, Rect, nil, bLink)
	end
end

local SHOP_PRICE_TYPE_MAX_SIZE = 2

local function UpdateCoinShopPrice(hSubInfo, tInfo, tPriceInfo)
	local hShopPrice = hSubInfo:Lookup("Handle_ShopPrice")
	local bDis = CoinShop_IsPriceDis(tInfo)
	hSubInfo:Lookup("Image_EnjoyOff"):Show(bDis)
	local nPriceIndex = 1
	local hOffPrice = hShopPrice:Lookup("Handle_OffPrice")
	hOffPrice:Hide()
	for _, tPrice in ipairs(tPriceInfo) do
		if nPriceIndex > SHOP_PRICE_TYPE_MAX_SIZE then
			break
		end
		local hPrice = hShopPrice:Lookup("Handle_Price" .. nPriceIndex)
		local hTextTime = hPrice:Lookup("Text_ShopTime" .. nPriceIndex)
		local hTextMoney = hPrice:Lookup("Text_ShopMoney" .. nPriceIndex)
		local hMoney = hPrice:Lookup("Image_ShopMoney" .. nPriceIndex)
		hTextTime:SetText(tPrice.szPriceDesc)
		local nPrice = tPrice.nPrice
		if tPrice.nShowPrice then
			nPrice = tPrice.nShowPrice
		end
		hTextMoney:SetText(nPrice)
		hTextMoney:Show(tPrice.szImagePath and tPrice.nFrame)
		hMoney:Show(tPrice.szImagePath and tPrice.nFrame)
		if tPrice.szImagePath and tPrice.nFrame then
			hMoney:FromUITex(tPrice.szImagePath, tPrice.nFrame)
			hMoney:AutoSize()
		end

		hPrice:Lookup("Image_OffLine" .. nPriceIndex):Show(tPrice.bDis)
		if tPrice.bDis then
			hOffPrice:Show()
			local hOffMoney = hOffPrice:Lookup("Image_OffPriceMoney")
			if tPrice.szImagePath and tPrice.nFrame then
				hOffMoney:FromUITex(tPrice.szImagePath, tPrice.nFrame)
				hOffMoney:AutoSize()
			end
			local szDisCount = CoinShop_GetDisText(tPrice, tPrice.bSecondDis)
			local nDisPrice = tPrice.nDisPrice
			if tPrice.nShowDisPrice then
				nDisPrice = tPrice.nShowDisPrice
			end
			hOffPrice:Lookup("Text_OffPrice"):SetText(szDisCount)
			hOffPrice:Lookup("Text_OffPrice2"):SetText(nDisPrice)
		end
		nPriceIndex = nPriceIndex + 1
	end

	for i = nPriceIndex, SHOP_PRICE_TYPE_MAX_SIZE do
		local hPrice = hShopPrice:Lookup("Handle_Price" .. i)
		hPrice:Hide()
	end
	hShopPrice:FormatAllItemPos()
end

function OutputExteriorTipEx(dwID, Rect, bLink, bShop, dwPlayerID)
	if dwID <= 0 then
		return
	end

	local eGoodsType = COIN_SHOP_GOODS_TYPE.EXTERIOR
	local bCollect = CoinShop_GetCollectInfo(eGoodsType, dwID)
	if not bCollect then
		OutputCollectExteriorTip(eGoodsType, dwID, Rect, bLink)
		return
	end

	local hExterior = GetExterior()
	if not hExterior then
		return
	end

	local hCoinShopClient = GetCoinShopClient()
	if not hCoinShopClient then
		return
	end

	local hPlayer = GetClientPlayer()
	if not hPlayer then
		return hPlayer
	end

	--[[
	local szFrame = "ExteriorTip_" .. dwID
	OutputTip("", 400, Rect, nil, bLink, szFrame)
	local hHandle = GetTipHandle(bLink, szFrame)

	local szIniFile = ""
	local hSubInfo = hHandle:AppendItemFromIni(szIniFile, "Handle_SubTip")
	local tInfo = hExterior.GetExteriorInfo(dwID)
	local tSet = Table_GetExteriorSet(tInfo.nSet)
	local szName = tSet.szSetName
	szName = szName .. g_tStrings.STR_CONNECT .. g_tStrings.tExteriorSubName[tInfo.nSubType]
	hSubInfo:Lookup("Text_ShopName"):SetText(szName)
	local hBox = hSubInfo:Lookup("Box_ShopItem")
	local hSetHot = hSubInfo:Lookup("Image_Hot")
	local hSetNew = hSubInfo:Lookup("Image_New")
	local hLeftTime = hSubInfo:Lookup("Text_Day")
	local hTimeLimit = hSubInfo:Lookup("Image_EnjoyTimeLimit")
	local hImageFree = hSubInfo:Lookup("Handle_FreeTime")
	local hShopPrice = hSubInfo:Lookup("Handle_ShopPrice")
	local hHad = hSubInfo:Lookup("Text_Had")
	local hOthers = hSubInfo:Lookup("Handle_Others")

	local szLeftTime = CoinShop_GetExteriorTime(dwID)
	local bFreeTryOn = CoinShop_CanFreeTryOn(tInfo)

	hSetHot:Show(tSet.nLabel == EXTERIOR_LABEL.HOT)
	hSetNew:Show(tSet.nLabel == EXTERIOR_LABEL.NEW)
	UpdateExteriorBoxObject(hBox, dwID)
	hLeftTime:SetText(szLeftTime)
	hLeftTime:Show(szLeftTime ~= "" and not bHave)
	hTimeLimit:Show(szLeftTime ~= "")
	hImageFree:Show(bFreeTryOn)

	if bFreeTryOn then
		local szFreeTime = CoinShop_GetFreeTryOnTime()
		hLeftTime:Show(bFreeTryOn)
		hLeftTime:SetText(szFreeTime)
	end

	local nTimeType, nTime = hPlayer.GetExteriorTimeLimitInfo(dwID)
	local szHad = ""
	local bShowPrice = true
	if nTimeType then
		if nTimeType == COIN_SHOP_TIME_LIMIT_TYPE.PERMANENT then
			szHad = g_tStrings.EXTERIOR_HAVE_PERMANENT
			bShowPrice = false
		else
			if nTimeType == COIN_SHOP_TIME_LIMIT_TYPE.FREE_TRY_ON then
				nTime =  GetCoinShopClient().GetFreeTryOnEndTime()
			end
			local nLeftTime = nTime - GetCurrentTime()
			if nLeftTime < 0 then
				nLeftTime = 0
			end
			szHad = GetTimeText(nLeftTime, nil, true)
			szHad = FormatString(g_tStrings.EXTERIOR_HAVE, szHad)
		end
	else
		local nOwnType = GetCoinShopClient().CheckAlreadyHave(COIN_SHOP_GOODS_TYPE.EXTERIOR, dwID)
		szHad = g_tStrings.tCoinShopOwnType[nOwnType]
	end
	hHad:SetText(szHad)
	bShowPrice = bShowPrice or bShop

	local hShopPrice = hSubInfo:Lookup("Handle_ShopPrice")
	local fH = hShopPrice:GetRelY() --以下是变长
	if bShowPrice then
		local tPriceInfo = CoinShop_GetExteriorPriceInfo(dwID)
		UpdateCoinShopPrice(hSubInfo, tInfo, tPriceInfo)
		local _, fPriceH = hShopPrice:GetAllItemSize()
		fH = fH + fPriceH
	end
	hShopPrice:Show(bShowPrice)

	local hNo = hSubInfo:Lookup("Handle_No")
	hNo:Hide()
	if dwPlayerID ~= -1 then -- -1代表不需要显示铭牌信息
		local hPlayer
		if not dwPlayerID then
			hPlayer = GetClientPlayer()
		else
			hPlayer = GetPlayer(dwPlayerID)
		end

		if hPlayer then
			local nBuyIndex = hPlayer.GetExteriorBuyIndex(dwID)
			local szText = CoinShop_GetBuyIndexText(nBuyIndex)
			hNo:Lookup("Text_No"):SetText(szText)
			local bShow = szText ~= ""
			hNo:Show(bShow)
			fH = fH + 5
			hNo:SetRelY(fH)
			hSubInfo:FormatAllItemPos()
			if bShow then
				fH = hNo:GetRelY() + hNo:GetH()
			end
		end
	end

	if bShowPrice and SetRewardsTip(hOthers, fH, nil, tInfo, eGoodsType, dwID) then
		--fH = fH + 22
	end

	local hDbTips = hOthers:Lookup("Handle_DbTips")
	local dwVoucherID = GetCurrentCoinShopVoucherID()
	hDbTips:Hide()
	if dwVoucherID then
		local bResult = hCoinShopClient.CheckCanUseVoucher(dwVoucherID, eGoodsType, dwID)
		if bResult then
			hDbTips:Show()
		end
	end

	local hTextDebug = hOthers:Lookup("Text_DebugInfo")
	hTextDebug:Hide()
	if IsCtrlKeyDown() and not IsShiftKeyDown() and not IsAltKeyDown() then
		local szText = "\n" .. g_tStrings.DEBUG_INFO_ITEM_TIP
		szText = szText .. GetExteriorDebugText(dwID)

		hTextDebug:SetText(szText)
		hTextDebug:Show()
		--hTextDebug:AutoSize()
		--hTextDebug:SetRelY(fH)
		--hSubInfo:FormatAllItemPos()
		--fH = fH + 120
		--hTextDebug:Set
	end
	hOthers:FormatAllItemPos()
    local _, fOthersH = hOthers:GetAllItemSize()
    fH = fH + fOthersH + 5
	hSubInfo:SetH(fH)
    hSubInfo:FormatAllItemPos()
	OutputTip("", 400, Rect, ALW.LEFT_RIGHT, bLink, szFrame, true)
	]]
end

function OutputCoinShopGoodsTip(eGoodsType, dwGoodsID, Rect)
    if eGoodsType == COIN_SHOP_GOODS_TYPE.ITEM then
        OutputRewardsTip(dwGoodsID, Rect)
    elseif eGoodsType == COIN_SHOP_GOODS_TYPE.EXTERIOR then
        OutputExteriorTipEx(dwGoodsID, Rect, nil, true)
    elseif eGoodsType == COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR then
        OutputWeaponTip(dwGoodsID, Rect)
    elseif eGoodsType == COIN_SHOP_GOODS_TYPE.HAIR or eGoodsType == COIN_SHOP_GOODS_TYPE.FACE then
        OutputHairTip(eGoodsType, dwGoodsID, Rect)
    end
end

function OutputHairTip(eGoodsType, dwGoodsID, Rect)
    local szName = CoinShop_GetGoodsName(eGoodsType, dwGoodsID)
    local szTip = GetFormatText(szName)
	if IsCtrlKeyDown() and dwGoodsID  then
		if eGoodsType == COIN_SHOP_GOODS_TYPE.HAIR then
			szTip = szTip .. GetFormatText("\n HairID = " .. dwGoodsID)
		else
			szTip = szTip .. GetFormatText("\n FaceID = " .. dwGoodsID)
		end
    end
    OutputTip(szTip, 400, Rect)
end


function OutputRewardsTip(dwLogicID, Rect, bLink)
	if dwLogicID <= 0 then
		return
	end

	local hPlayer = GetClientPlayer()
	if not hPlayer then
		return
	end

	local hRewardsShop = GetRewardsShop()
	if not hRewardsShop then
		return
	end

	local hCoinShopClient = GetCoinShopClient()
	if not hCoinShopClient then
		return
	end

	--[[
	local szFrame = "RewardsItemTip_" .. dwLogicID
	OutputTip("", 400, Rect, nil, bLink, szFrame)
	local hHandle = GetTipHandle(bLink, szFrame)
	local szIniFile = ""
	local hCardInfo = hHandle:AppendItemFromIni(szIniFile, "Handle_SubTip")

	local tInfo = hRewardsShop.GetRewardsShopInfo(dwLogicID)
	local tCardItem = Table_GetRewardsItem(dwLogicID)

	local hItemInfo = GetItemInfo(tInfo.dwItemTabType, tInfo.dwItemTabIndex)
	if not hItemInfo then
		return
	end
	local szName =  GetItemNameByItemInfo(hItemInfo)
	hCardInfo:Lookup("Text_ShopName"):SetText(szName)

	local hSetHot = hCardInfo:Lookup("Image_Hot")
	local hSetNew = hCardInfo:Lookup("Image_New")
	local hBox = hCardInfo:Lookup("Box_ShopItem")
	local hShopPrice = hCardInfo:Lookup("Handle_ShopPrice")
	local hHad = hCardInfo:Lookup("Text_Had")
	local hLeftTime = hCardInfo:Lookup("Text_Day")
	local hTimeLimit = hCardInfo:Lookup("Image_EnjoyTimeLimit")
	local hImageFree = hCardInfo:Lookup("Handle_FreeTime")
	local hOthers = hCardInfo:Lookup("Handle_Others")
	local hCurrency = hOthers:Lookup("Handle_Currency")

	hCurrency:Hide()
	hSetHot:Show(tCardItem.nLabel == EXTERIOR_LABEL.HOT)
	hSetNew:Show(tCardItem.nLabel == EXTERIOR_LABEL.NEW)
	hCardInfo:Lookup("Handle_Memorial"):Show(tInfo.nGameWorldStartInDuration > 0)
    hCardInfo:Lookup("Handle_PVP"):Show(tCardItem.nLabel == EXTERIOR_LABEL.PVP)
	UpdataItemInfoBoxObject(hBox, 0, tCardItem.dwTabType, tCardItem.dwIndex, 1)
	local nHaveType = hCoinShopClient.CheckAlreadyHave(COIN_SHOP_GOODS_TYPE.ITEM, dwLogicID)
	local bHave = nHaveType ~= COIN_SHOP_OWN_TYPE.NOT_HAVE and nHaveType ~= COIN_SHOP_OWN_TYPE.FREE_TRY_ON
	local szHaveString = g_tStrings.tCoinShopOwnType[nHaveType]
	local szLeftTime = CoinShop_GetRewardsTime(dwLogicID)
	local bFreeTryOn = CoinShop_CanFreeTryOn(tInfo)

	hShopPrice:Show(not bHave)
	hHad:SetText(szHaveString)
	hHad:Hide(COIN_SHOP_OWN_TYPE.NOT_HAVE == nHaveType and tInfo.dwItemTabType == ITEM_TABLE_TYPE.HOMELAND)
	hLeftTime:SetText(szLeftTime)
	hLeftTime:Show(szLeftTime ~= "" and not bHave)
	hTimeLimit:Show(szLeftTime ~= "")
	hImageFree:Show(bFreeTryOn)

	if bFreeTryOn then
		local szFreeTime = CoinShop_GetFreeTryOnTime()
		hLeftTime:Show(bFreeTryOn)
		hLeftTime:SetText(szFreeTime)
	end

	local tPriceInfo = CoinShop_GetRewardsPriceInfo(tCardItem.dwLogicID)
	UpdateCoinShopPrice(hCardInfo, tInfo, tPriceInfo)

	local szInfo = ""
	if tCardItem.szTip ~= "" then
		szInfo = GetFormatText(tCardItem.szTip .. "\n", 27)
	end

	hShopPrice:FormatAllItemPos()
	local fY = hShopPrice:GetRelY()
	local fH = 0
	if not bHave then
		_, fH = hShopPrice:GetAllItemSize()
		hShopPrice:SetH(fH)
	end

	local hInfo = hCardInfo:Lookup("Handle_Info")
	hInfo:Clear()
	hInfo:AppendItemFromString(szInfo)
	hInfo:FormatAllItemPos()
	hInfo:SetRelY(fY + fH)
	fY = fY + fH
	_, fH = hInfo:GetAllItemSize()
	hInfo:SetH(fH)

	fY = fY + fH
	hOthers:SetRelY(fY)
	if (not bHave) and SetRewardsTip(hOthers, fY, nil, tInfo, COIN_SHOP_GOODS_TYPE.ITEM, dwLogicID) then
		--fY = fY + 22
	end

	local hDbTips = hOthers:Lookup("Handle_DbTips")
    local dwVoucherID = GetCurrentCoinShopVoucherID()
    hDbTips:Hide()
    if dwVoucherID then
        local bResult = hCoinShopClient.CheckCanUseVoucher(dwVoucherID, COIN_SHOP_GOODS_TYPE.ITEM, dwLogicID)
        if bResult then
            hDbTips:Show()
        end
    end

	--hCardInfo:Lookup("Text_DebugInfo"):Hide()
	local hDebugInfo = hOthers:Lookup("Text_DebugInfo")
	if IsCtrlKeyDown() and not IsShiftKeyDown() and not IsAltKeyDown() then
		local szText = "\n" .. g_tStrings.DEBUG_INFO_ITEM_TIP
		szText = szText .. "\n" .. "dwID: " .. dwLogicID
		szText = szText .. "\n" .. "nGlobalCounterID: " .. tInfo.nGlobalCounterID

		szInfo = szInfo .. GetFormatText(szText, 102)
		hDebugInfo:SetText(szText)
		hDebugInfo:Show()
		-- hCardInfo:SetH(231)
	end
	hOthers:FormatAllItemPos()
	local _, fH = hOthers:GetAllItemSize()
	fY = fY + fH + 5

	hCardInfo:FormatAllItemPos()
	hCardInfo:Lookup("Image_Bg"):SetH(fY)
	hCardInfo:SetH(fY)
	OutputTip("", 400, Rect, ALW.LEFT_RIGHT, bLink, szFrame, true)
	]]
end

function OutputWeaponTip(dwWeaponID, Rect, bLink)
	if dwWeaponID <= 0 then
		return
	end
	local eGoodsType = COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR
	local bCollect = CoinShop_GetCollectInfo(eGoodsType, dwWeaponID)
	if not bCollect then
		OutputCollectExteriorTip(eGoodsType, dwWeaponID, Rect, bLink)
		return
	end

	local hPlayer = GetClientPlayer()
	if not hPlayer then
		return
	end

	local hExterior = GetExterior()
	if not hExterior then
		return
	end

	local hCoinShopClient = GetCoinShopClient()
	if not hCoinShopClient then
		return
	end
end

function GetExteriorDebugText(dwID)
	local tInfo = GetExterior().GetExteriorInfo(dwID)
	local szText = ""
	szText = szText .. "\n" .. "LogicID: " .. dwID
	szText = szText .. "\n" .. "SetID: " .. tInfo.nSet
	szText = szText .. "\n" .. "RepresentID: " .. tInfo.nRepresentID
	szText = szText .. "\n" .. "ColorID: " .. tInfo.nColorID
	szText = szText .. "\n" .. "SubType: " .. tInfo.nSubType
	return szText
end

function GetWeaponDebugText(dwID)
	local tInfo = CoinShop_GetWeaponExteriorInfo(dwID)
	local szText = ""
	szText = szText .. "\n" .. "LogicID: " .. dwID
	szText = szText .. "\n" .. "nDetailType: " .. tInfo.nDetailType
	szText = szText .. "\n" .. "RepresentID: " .. tInfo.nRepresentID
	szText = szText .. "\n" .. "ColorID: " .. tInfo.nColorID
	szText = szText .. "\n" .. "nEnchantRepresentID1: " .. tInfo.nEnchantRepresentID1
	szText = szText .. "\n" .. "nEnchantRepresentID2: " .. tInfo.nEnchantRepresentID2
	return szText
end

function OutputCollectExteriorTip(eGoodsType, dwGoodsID, Rect, bLink)
	if dwGoodsID <= 0 then
		return
	end

	local hPlayer = GetClientPlayer()
	if not hPlayer then
		return
	end

	local hExterior = GetExterior()
	if not hExterior then
		return
	end

	--[[
	local szFrame = "CollectTip_" .. eGoodsType .. "_" .. dwGoodsID
	OutputTip("", 400, Rect, nil, bLink, szFrame)
	local hHandle = GetTipHandle(bLink, szFrame)
	local szIniFile = ""

	local hCollect = hHandle:AppendItemFromIni(szIniFile, "Handle_Collect")
	local hBox = hCollect:Lookup("Box_Item")
	local szName = CoinShop_GetGoodsName(eGoodsType, dwGoodsID)
	hCollect:Lookup("Text_Name"):SetText(szName)
	local dwTabType = nil
	if eGoodsType == COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR then
		UpdateExteriorWeaponBox(hBox, dwGoodsID)
		dwTabType = ITEM_TABLE_TYPE.CUST_WEAPON
	else
		UpdateExteriorBoxObject(hBox, dwGoodsID)
		dwTabType = ITEM_TABLE_TYPE.CUST_ARMOR
	end
	local bCollect, nPiece, nGold = CoinShop_GetCollectInfo(eGoodsType, dwGoodsID)
	hCollect:Lookup("Handle_OneWay"):Show(nPiece < 0)
	hCollect:Lookup("Handle_TwoWay"):Show(nPiece >= 0)
	if nPiece >= 0 then
		local hPrice = hCollect:Lookup("Handle_TwoWay")
		hPrice:Lookup("Text_Way3"):SetText(nPiece)
		hPrice:Lookup("Text_Way4"):SetText(nGold)
		hPrice:Lookup("Handle_Piece"):Show()
	end
	local hContent = hCollect:Lookup("Handle_Content")
	local tSrc = CoinShop_GetSrc(eGoodsType, dwGoodsID)
	local szContent = ""
	for _, tInfo in ipairs(tSrc) do
		local tResult = EquipInquire_FormatData(tInfo)
		local szSource = EquipInquire_GetItemSourceDesc(tResult, true)
		local hItemInfo = GetItemInfo(dwTabType, tInfo.dwItemIndex)
		local r, g, b = GetItemFontColorByQuality(hItemInfo.nQuality)
		local szText =  GetFormatText(tInfo.szItemName .."\n", 0, r, g, b)
		szText = szText ..  szSource .. GetFormatText("\n\n")
		szContent = szContent .. szText
	end
	if #tSrc <= 0 then
		szContent = GetFormatText(g_tStrings.COINSHOP_SOURCE_NULL)
	end

	if IsCtrlKeyDown() and not IsShiftKeyDown() and not IsAltKeyDown() then
		szContent = szContent .. GetFormatText("\n" .. g_tStrings.DEBUG_INFO_ITEM_TIP, 102)
		local szText = ""
		if eGoodsType == COIN_SHOP_GOODS_TYPE.EXTERIOR then
			szText = GetExteriorDebugText(dwGoodsID)
		else
			szText = GetWeaponDebugText(dwGoodsID)
		end
		szContent = szContent .. GetFormatText(szText, 102)
	end

	hContent:AppendItemFromString(szContent)
	hContent:FormatAllItemPos()

	local _, fH = hContent:GetAllItemSize()
	hContent:SetH(fH)
	local fX, fY = hContent:GetRelPos()
	hCollect:SetH(fY + fH)
	OutputTip("", 400, Rect, nil, bLink, szFrame, true)
	]]
end

function GetItemLeftTimeTip(item, player)
	if not player then
		player = GetClientPlayer()
	end
	local bRefresh = false
	local szTip= ""
	local szTime = ""
	local nLeftTime = player.GetTradeItemLeftTime(item.dwID)
	if nLeftTime > 0 then
		local szTime = GetTimeText(nLeftTime)
		szTip = szTip .. FormatString(g_tStrings.STR_TRADE_LTIME, szTime)
		bRefresh = true
	end

	nLeftTime = player.GetTimeLimitSoldListInfoLeftTime(item.dwID)
	if nLeftTime > 0 then
		szTime = GetTimeText(nLeftTime)
		szTip = szTip .. FormatString(g_tStrings.STR_BUY_LTIME, szTime)
		bRefresh = true
	end

	nLeftTime = player.GetTimeLimitReturnItemLeftTime(item.dwID)
	if nLeftTime > 0 then
		szTime = GetTimeText(nLeftTime)
		szTip = szTip .. FormatString(g_tStrings.STR_RETURN_LTIME, szTime)
		bRefresh = true
	end
	return szTip, bRefresh
end

function IsCanTimeReturnItem(item)
	if not item then
		return false
	end

	local player = GetClientPlayer()
	local nLeftTime = player.GetTimeLimitReturnItemLeftTime(item.dwID)
	return (nLeftTime > 0)
end

function IsCanTimeTradeItem(item)
	if not item then
		return false
	end

	local player = GetClientPlayer()
	local nLeftTime = player.GetTradeItemLeftTime(item.dwID)
	return (nLeftTime > 0)
end

function GetTimeOperateItemTip(item)
	local szText = ""
	if IsCanTimeReturnItem(item) then
		-- szText = szText .. GetFormatText("\n"..g_tStrings.STR_EN_PREV_PANT)..
		-- 	FormatString(g_tStrings.STR_RETURE_BIND, 71) ..
		-- 	GetFormatText(g_tStrings.STR_EN_END_PANT)
		szText = szText .. GetFormatText(g_tStrings.TIME_RETURN_MSG)
	end

	if IsCanTimeTradeItem(item) then
		szText = szText .. GetFormatText("\n"..g_tStrings.STR_EN_PREV_PANT)..
			FormatString(g_tStrings.STR_TRADE_BIND, 71) ..
			GetFormatText(g_tStrings.STR_EN_END_PANT)
	end
	return szText
end

local function GetSetSchoolInfo(dwSchoolMask, dwSchoolID)
	local bEnable = false
	if dwSchoolMask == 0 then
		bEnable = true
	elseif dwSchoolID and dwSchoolID ~= 0 then
		bEnable = GetNumberBit(dwSchoolMask, dwSchoolID + 1)
	end

	local szTip = ""
	if dwSchoolMask ~= 0 then
		local bHaveCangjian = false
		for k, v in pairs(g_tStrings.tSchoolTitle) do
			if k ~= 0 and GetNumberBit(dwSchoolMask, GetBitOPSchoolID(k) + 1) then
				local szText = ""
				if szTip ~= "" then
					szText = g_tStrings.STR_PAUSE
				end
				szText = szText .. string.format("%s%s", v, g_tStrings.STR_SKILL_NG)
				if k == SCHOOL_TYPE.CANG_JIAN_WEN_SHUI or k == SCHOOL_TYPE.CANG_JIAN_SHAN_JU then --藏剑内功只显示一个
					if bHaveCangjian then
						szText = ""
					end
					bHaveCangjian = true
				end
				szTip = szTip .. szText
			end
		end
	end
	return bEnable, szTip
end

local function GetEquipUnActiveItem(player)
	if not player or not player.bCanUseBigSword then
		return
	end

	local item
	if player.bBigSwordSelected then
		item = GetPlayerItem(player, INVENTORY_INDEX.EQUIP, EQUIPMENT_INVENTORY.MELEE_WEAPON)
	else
		item = GetPlayerItem(player, INVENTORY_INDEX.EQUIP, EQUIPMENT_INVENTORY.BIG_SWORD)
	end
	return item
end

local function IsItemEquiped(player, nUiId, nEquipPos)
	local item = GetPlayerItem(player, INVENTORY_INDEX.EQUIP, nEquipPos)
	if item and item.nUiId == nUiId then
		return true
	end
end

local _tUISet
local _dwSetID
local function GetUISetInfo(dwSetID)
	if _dwSetID == dwSetID and _tUISet then
		return _tUISet
	end

	local tab = g_tTable.Set
	local nrow = tab:GetRowCount()
	local tLine
	local tRes
	for i = 2, nrow, 1 do
		tLine = tab:GetRow(i)
		if dwSetID == tLine.setid then
			tRes = tRes or {}
			table.insert(tRes, tLine)
		elseif tRes then
			break
		end
	end

	if tRes then
		_tUISet = tRes
		_dwSetID = dwSetID
	end
	return tRes
end

local function GetSetAttriValueTip(setAttrib, bSetAttriEnable, nHave, setUiId)
	local bFirst = true
	local szTip = ""
	for k, tSet in pairs(setAttrib) do
		local szAt = ""
		for _, v in pairs(tSet.Attrib) do
			if szAt ~= "" then
				szAt = szAt .. "<text>text=\""..g_tStrings.STR_COMMA.."\" font=18 </text>"
			end

			if v.nID == ATTRIBUTE_TYPE.SKILL_EVENT_HANDLER then
				local skillEvent = g_tTable.SkillEvent:Search(v.nValue1)
				if skillEvent then
					szAt = szAt .. FormatString(skillEvent.szDesc, v.nValue1, v.nValue2)
				else
					szAt = szAt .. "<text>text=\"unknown skill event id:"..v.nValue1.."\"</text>"
				end
			elseif v.nID == ATTRIBUTE_TYPE.SET_EQUIPMENT_RECIPE then
				szAt = szAt .. GetEquipRecipeDesc(v.nValue1, v.nValue2)
			else
				EquipData.FormatAttributeValue(v)
				szAt = szAt .. FormatString(Table_GetMagicAttributeInfo(v.nID, true), v.nValue1, v.nValue2, MAGIC_ATTRI_DEF, MAGIC_ATTRI_DEF)
			end
		end

		if szAt ~= "" then
			local nF = 108
			if nHave >= tSet.nCount and bSetAttriEnable then --tSet.bEquiped and bSetAttriEnable then
				nF = 105
			end
			szAt = string.gsub(szAt, "font=%d+", "font="..nF)
			if bFirst then
				bFirst = false
				szTip = szTip.."<text>text=\"\\\n\"</text>"
			end
			szTip = szTip.."<text>text=\"["..tSet.nCount.."]\"font="..nF.."</text>"..szAt.."<text>text=\"\\\n\"</text>"
		end
	end
	szTip = szTip..Table_GetItemDesc(setUiId).."<text>text=\"\\\n\"</text>"
	return szTip
end


local function GetSetAttriTipFromUI(tUISet, dwSetID, dwPlayerID, dwSchoolID, bItemInfo)
	local setUiId, _, _, _, setAttrib, dwSchoolMask = GetItemSetAttrib(dwSetID, dwPlayerID);
	local player = GetPlayer(dwPlayerID)
	local nF = 108
	local activecount = 0
	local szTip = ""
	local szTip1 = ""

	local bSetAttriEnable, szEnableInfo = GetSetSchoolInfo(dwSchoolMask, dwSchoolID)
	if szEnableInfo ~= "" then
		szTip = szTip..GetFormatText("\n")
			.. GetFormatText(FormatString(g_tStrings.STR_SET_ATTRI_SCHOOL, szEnableInfo), 100)
	end

	szTip = szTip..GetFormatText("\n")

	for _, v in ipairs(tUISet) do
		nF = 108
		if not bItemInfo and IsItemEquiped(player, v.uiid, EQUIPMENT_INVENTORY[v.pos]) then
			nF = 100
			activecount = activecount + 1
		end
		szTip1 = szTip1 .. GetFormatText(GetItemNameByUIID(v.uiid).."\n", nF)
	end
	szTip = szTip .. "<text>text="..EncodeComponentsString(FormatString(g_tStrings.STR_ITEM_H_SET_NAME, GetItemNameByUIID(setUiId), activecount, #tUISet)).."font=100</text>"
	szTip = szTip .. szTip1

	szTip = szTip .. GetSetAttriValueTip(setAttrib, bSetAttriEnable, activecount, setUiId)

	return szTip
end

local tEquipRelpace = nil
local function LoadEquipRelpace()
	tEquipRelpace = {}
	local nCount = g_tTable.EquipSet:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.EquipSet:GetRow(i)
		local tReplace = SplitString(tLine.szReplaceUIID, ";")
		for _, szUIID in ipairs(tReplace) do
			local nUIID = tonumber(szUIID)
			tEquipRelpace[nUIID] = tLine.nUIID
		end
	end
end

local function GetReplaceTipInfo(dwSetID, nUIID, bEquiped)
	local nF = 108	--未穿戴装备字体
	if bEquiped then
		nF = 100 --已穿戴装备名字体
	end
	local tLine = g_tTable.EquipSet:Search(dwSetID, nUIID)
	if not tLine then
		return GetFormatText(GetItemNameByUIID(nUIID) .. "\n", nF)
	end

	if tLine then
		if tLine.szDesc ~= "" then
			return GetFormatText(tLine.szDesc .. "\n", nF)
		end
		local szDesc = GetFormatText(GetItemNameByUIID(nUIID), nF)
		local tReplace = SplitString(tLine.szReplaceUIID, ";")
		for k, szUIID in ipairs(tReplace) do
			local nUIID = tostring(szUIID)
			szDesc = szDesc ..GetFormatText(" / "..GetItemNameByUIID(nUIID), nF)
		end
		szDesc = szDesc .. GetFormatText("\n", nF)
		return szDesc
	end
end

local function GetSetAttriTip(dwSetID, dwPlayerID, dwSchoolID, bItemInfo)
	local szTip = ""

	local tUISet = GetUISetInfo(dwSetID)
	if tUISet then
		return GetSetAttriTipFromUI(tUISet, dwSetID, dwPlayerID, dwSchoolID, bItemInfo)
	end

	local setUiId, setTableOrg, nTotal, nHave, setAttrib, dwSchoolMask = GetItemSetAttrib(dwSetID, dwPlayerID);
	if not setUiId then
		return
	end

	if not tEquipRelpace then
		LoadEquipRelpace()
	end

	local player = GetPlayer(dwPlayerID)

	local unActiveItem
	if not bItemInfo then
		unActiveItem = GetEquipUnActiveItem(player)
	end

	local bSetAttriEnable, szEnableInfo = GetSetSchoolInfo(dwSchoolMask, dwSchoolID)
	if szEnableInfo ~= "" then
		szTip = szTip..GetFormatText("\n")
			.. GetFormatText(FormatString(g_tStrings.STR_SET_ATTRI_SCHOOL, szEnableInfo), 100)
	end

	local nNewTotal = 0
	local nNewHave  = 0
	local setTable = {}
	local ReplaceTable = {}
	for k, v in pairs(setTableOrg) do
		local nUsefulUiID = v.nUiId
		if tEquipRelpace[nUsefulUiID] then
			nUsefulUiID = tEquipRelpace[nUsefulUiID]
		end

		if setTable[nUsefulUiID] == nil then

			setTable[nUsefulUiID] = v.bEquiped
			nNewTotal = nNewTotal + 1
		else
			setTable[nUsefulUiID] = setTable[nUsefulUiID] or v.bEquiped
		end

		if unActiveItem and unActiveItem.nUiId == nUsefulUiID then -- cang jian two sowrd3 only active one
			setTable[nUsefulUiID] = false;
		end
	end

	if not bItemInfo then
		for k, v in pairs(setTable) do
			if v then
				nNewHave = nNewHave + 1
			end
		end
		nTotal = nNewTotal
		nHave  = nNewHave
	end
	szTip = szTip..GetFormatText("\n")
	szTip = szTip.."<text>text="..EncodeComponentsString(FormatString(g_tStrings.STR_ITEM_H_SET_NAME, GetItemNameByUIID(setUiId), nHave, nTotal)).."font=100</text>"

	for k, v in pairs(setTable) do
		szTip = szTip .. GetReplaceTipInfo(dwSetID, k, v)
	end

	szTip = szTip .. GetSetAttriValueTip(setAttrib, bSetAttriEnable, nHave, setUiId)
	return szTip
end

function GetItemDesc(nUiId)
	local szDesc = Table_GetItemDesc(nUiId)
	szDesc = string.gsub(szDesc, "<SKILL (%d+) (%d+)>", function(dwID, dwLevel) return GetSubSkillDesc(dwID, dwLevel) end)
	szDesc = string.gsub(szDesc, "<BUFF (%d+) (%d+) (%w+)>", function(dwID, nLevel, szKey)  return GetBuffDesc(dwID, nLevel, szKey) end)
	szDesc = string.gsub(szDesc, "<ENCHANT (%d+)>", function(dwID) return GetEnchantDesc(dwID) end)
	szDesc = string.gsub(szDesc, "<SpiStone (%d+)>", function(dwID) return GetSpiStoneDesc(dwID) end)
	return szDesc
end

local function GetAvatarImageTip(dwAvatarID)
	--nRepresentID
	local tLine = g_tTable.RoleAvatar:Search(dwAvatarID)
	if not tLine then
		return ""
	end
	local szTip = ""
	local player = GetClientPlayer()

	local szAvatarTip = ""
	local szFile, nFrame, szSfx = RoleChange.GetImageFile(tLine, player.nRoleType)
	if szFile ~= "" or szSfx ~= "" then
		local x = 25
		local y = 5
		local szBGTip = ""
		local tImage = RoleChange.GetHUDImageInfo( dwAvatarID )

		if tImage and tImage.szWholeAnimatePath ~= "" and tImage.nWholeAnimateFrame ~= -1 then
			szBGTip = "<animate> name=\"Animate_Whole\" path=\""..tImage.szWholeAnimatePath.."\" group="..tImage.nWholeAnimateFrame .. " x=9 y=0 w=340 h=80 </animate>"
		elseif tImage and tImage.szWholeSfx ~= "" then
			szBGTip = "<sfx> name=\"SFX_Whole\" file=\""..tImage.szWholeSfx.."\" loop=1 w=340 h=80 scale = 1.0 x= 9, y= 0 </sfx>"
		elseif tImage and tImage.szLeftHUDImage ~= "" then
			if tImage.szLeftSfx ~= "" then
				szBGTip = "<sfx> name=\"SFX_BuyBG1\" file=\""..tImage.szLeftSfx.."\" loop=1 w=75 h=84 scale = 1.0 x= 11, y= 7 </sfx>"
			elseif tImage.nLeftHUDFrame == -1 then
				szBGTip = "<image> name=\"Image_BuyBG1\" path=\""..tImage.szLeftHUDImage.."\" x= 10, y= 7 </image>"
			else
				szBGTip = "<image> name=\"Image_BuyBG1\" path=\""..tImage.szLeftHUDImage.."\" frame="..tImage.nLeftHUDFrame.." x= 10, y= 7 </image>"
			end

			if tImage.nMidHUDFrame == -1 then
				szBGTip = szBGTip.."<image> name=\"Image_BuyBG2\" path=\""..tImage.szMidHUDImage.."\" w=158 h=57 x=134 y=12 </image>"
			else
				szBGTip = szBGTip.."<image> name=\"Image_BuyBG2\" path=\""..tImage.szMidHUDImage.."\" frame="..tImage.nMidHUDFrame.." w=158 h=57 x=134 y=12 </image>"
			end

			if tImage.szRightSfx ~= "" then
				szBGTip = szBGTip.."<sfx> name=\"SFX_BuyBG3\" file=\""..tImage.szRightSfx.."\" loop=1 scale = 1.0 x=292, y=10 </sfx>"
			elseif tImage.nRightHUDFrame == -1 then
				szBGTip = szBGTip.."<image> name=\"Image_BuyBG3\" path=\""..tImage.szRightHUDImage.."\" w=58 h=63 x=292 y=10 </image>"
			else
				szBGTip = szBGTip.."<image> name=\"Image_BuyBG3\" path=\""..tImage.szRightHUDImage.."\" frame="..tImage.nRightHUDFrame.." w=58 h=63 x=292 y=10 </image>"
			end
		else
			x, y = 0, 5
		end

		if szSfx ~= "" then
			szAvatarTip = "<sfx>file=\""..szSfx.."\" loop=1 x=" .. x .. " y=6 w=75 h=84 scale=0.78 </sfx>"
		elseif tLine.bAnimate then
			szAvatarTip = "<animate>path=\""..szFile.."\" group="..nFrame .. " x=" .. x .. " y=" .. y .. " w=75 h=84 animatetype=2 </animate>"
		else
			if nFrame == -1 then
				szAvatarTip = "<image>path=\""..szFile.. "\" x=" .. x .. " y=" .. y .. " imagetype=8 w=75 h=84 </image>"
			else
				szAvatarTip = "<image>path=\""..szFile.."\" frame="..nFrame .. " x=" .. x .. " y=" .. y .. " imagetype=8 w=75 h=84 </image>"
			end
		end
		szBGTip = "<handle> firstpostype=0 w=350 h=80 x=-10 y=21 name=\"Handle_Bg\" " .. szBGTip .. " </handle>"
		szTip = "<handle> firstpostype=0 w=350 h=93 name=\"Handle_szTip\" " .. szBGTip .. szAvatarTip   .. "</handle>"
	end
	return szTip
end

-----------阵营需求---------------
function GetItemInfoCampInfoTip(hItemInfo, hPlayer, nIndex)
	if hItemInfo.bCanGoodCampUse and hItemInfo.bCanEvilCampUse and hItemInfo.bCanNeutralCampUse then
		----------三个阵营均可用,不显示----
		return ""
	end

	if not hItemInfo.bCanGoodCampUse and not hItemInfo.bCanEvilCampUse and not  hItemInfo.bCanNeutralCampUse then
		----------三个阵营都不可用,目前定了不显示----
		Log("物品nIndex = " .. nIndex .. "三个阵营均不可用")
		return ""
	end

	local nFont = 166
	local szCampTip = g_tStrings.NEED
	local t = {}
	if hItemInfo.bCanGoodCampUse then
		table.insert(t, g_tStrings.TIP_CAMP_GOOD)
		if hPlayer.nCamp == CAMP.GOOD then
			nFont = 162
		end
	end

	if hItemInfo.bCanEvilCampUse then
		table.insert(t, g_tStrings.TIP_CAMP_EVIL)
		if hPlayer.nCamp == CAMP.EVIL then
			nFont = 162
		end
	end

	if hItemInfo.bCanNeutralCampUse then
		table.insert(t, g_tStrings.TIP_CAMP_NEUTRAL)
		if hPlayer.nCamp == CAMP.NEUTRAL  then
			nFont = 162
		end
	end

	szCampTip = g_tStrings.NEED.. table.concat(t, g_tStrings.TIP_COMMAND_OR) ..  "\n"
	szCampTip = GetFormatText(szCampTip, nFont)
	return szCampTip
end

----------等级，性别------------
function GetRequireGenderLevel(hItemInfo, hPlayer)
	if hItemInfo.nRequireLevel == 0 and hItemInfo.nRequireGender == 0 then
		return ""
	end
	local nNeedFont = 166
	local nLevelFont = 166
	local nGenderFont = 166
	local t = {}

	if hItemInfo.nRequireLevel ~= 0 then
		if hPlayer.nLevel >= hItemInfo.nRequireLevel then
			nNeedFont = 162
			nLevelFont = 162
		end
		table.insert(t, GetFormatText(FormatString(g_tStrings.TIP_LEVEL_WHAT, hItemInfo.nRequireLevel), nLevelFont))
	end
	if hItemInfo.nRequireGender ~= 0 then
		if hPlayer.nGender == hItemInfo.nRequireGender then
			nNeedFont = 162
			nGenderFont = 162
		end

		if hItemInfo.nRequireLevel ~= 0 then
			table.insert(t, GetFormatText(g_tStrings.STR_COMMA, nNeedFont))
		end
		table.insert(t, GetFormatText(g_tStrings.tGender[hItemInfo.nRequireGender], nGenderFont))
	end

	table.insert(t, GetFormatText("\n", 162))
	table.insert(t, 1, GetFormatText(g_tStrings.NEED, nNeedFont))
	local szLevelGenderTip =  table.concat(t)
	return szLevelGenderTip
end

-----------物品使用的生活技能限制-----------
function GetRequireProfessionTip(hItemInfo, hPlayer, nIndex)
	if hItemInfo.dwRequireProfessionID == 0 or g_LearnInfo[nIndex] then
		return ""

	end

	local t = {}
	local nFont = 162
	local hProfession = GetProfession(hItemInfo.dwRequireProfessionID)

	table.insert(g_tStrings.NEED)
	table.insert(Table_GetProfessionName(hItemInfo.dwRequireProfessionID))

	if hItemInfo.dwRequireProfessionBranch ~= 0 then
		local dwProfessionBranch = hPlayer.GetProfessionBranch(hItemInfo.dwRequireProfessionID)
		if dwProfessionBranch ~= hItemInfo.dwRequireProfessionBranch then
			nFont = 166;
		end

		local szBranchName = Table_GetBranchName(hItemInfo.dwRequireProfessionID, hItemInfo.dwRequireProfessionBranch)

		table.insert(FormstString(g_tStrings.STR_ALL_PARENTHESES, szBranchName))
	end

	local nProfessionLevel = hPlayer.GetProfessionLevel(hItemInfo.dwRequireProfessionID)
	if (nProfessionLevel < hItemInfo.nRequireProfessionLevel) then
		nFont = 166
	end

	if hItemInfo.nRequireProfessionLevel ~= 0 then
		table.insert(FormatString(g_tStrings.STR_PLAYER_H_WHAT_LEVEL, hItemInfo.nRequireProfessionLevel))
	else
		table.insert("\n")
	end

	local szProfessionTip = table.concat(t)
	return GetFromatText(szProfessionTip, nFont)
end

--------输出物品的提示-----------------
function GetOtherItemInfoTip(hItemInfo, hPlayer, nIndex)
	----------等级，性别------------
	local szLevelGenderTip = GetRequireGenderLevel(hItemInfo, hPlayer)

	-----------物品使用的生活技能限制-----------
	local szProfessionTip = GetRequireProfessionTip(hItemInfo, hPlayer, nIndex)

	-----------阵营需求---------------
	local szCampTip = GetItemInfoCampInfoTip(hItemInfo, hPlayer, nIndex)
	local szTip = szLevelGenderTip .. szProfessionTip .. szCampTip
	return szTip
end

local function OutputQixiItemTip(item, dwBox, dwX, Rect, nPosType, bLink, dwCmpPlayerID, bNoCmp, szTipName, bVisibleWhenHideUI, szPackageType)
	if not bNoCmp and item.nGenre == ITEM_GENRE.EQUIPMENT then
        local pPlayer = GetClientPlayer()
        local dwEquipBox, dwEquipX = GetEquipItemEquiped(pPlayer, item.nSub, item.nDetail)
		local itemC, itemCAdd = GetEquipItemCompaireItem(item.nSub, item.nDetail)
		if itemC then
			-- 七夕戒指处理不同的额外TIP
			SetQixiRingOwnerID(nil)
			if not IsRemotePlayer(pPlayer.dwID) then
				SetQixiRingOwnerID(pPlayer.dwID)
			end
			local szTip = GetItemTip(itemC, dwEquipBox, dwEquipX, nil, nil, true, dwCmpPlayerID, nil, bLink, szPackageType)
			local hFrame = OutputTip(szTip, 400, Rect, nPosType, bLink, szTipName, false, true, nil, nil, nil, nil, nil, bVisibleWhenHideUI)
			FormatHorseTip(hFrame, itemC)

			if itemCAdd then
                if item.nSub == EQUIPMENT_SUB.RING then
                    dwEquipX = EQUIPMENT_INVENTORY.RIGHT_RING
                end
				szTip = GetItemTip(itemCAdd, dwEquipBox, dwEquipX, nil, nil, true, dwCmpPlayerID, nil, bLink, szPackageType)
				OutputTip(szTip, 400, Rect, nPosType, bLink, szTipName, false, true, true, nil, nil, nil, nil, bVisibleWhenHideUI)
			end
			SetQixiRingOwnerID(nil)
		end
	end
end

local function OutputHoresEnchantTip(item, Rect, nPosType, bNoCmp, bVisibleWhenHideUI)
	if not bNoCmp and item.nGenre == ITEM_GENRE.MOUNT_ITEM and item.nSub == EQUIPMENT_SUB.HORSE then
		local nMountIndex = item.GetMountIndex()
		local horse = GetClientPlayer().GetEquippedHorse()
		if horse then
			local nUiId = GetItemEnchantUIID(horse.GetMountEnchantID(nMountIndex));
			if nUiId > 0 then
				local szTip = GetEnchantTip(nUiId, true)
				OutputTip(szTip, 345, Rect, nPosType, false, nil, false, true, nil, nil, nil, nil, nil, bVisibleWhenHideUI)
			end
		end
	end
end

local function IsItemTipUpdate(item, bLink)
	local userdata 	= GetTipUserData()
	if not bLink and userdata then
		if userdata.dwID == item.dwID and not userdata.bRefresh then
			return false
		end
	end
	return true
end

local function IsSameItemInfoTip(dwTab, dwIndex)
	local userdata 	= GetTipUserData()
	if  userdata and  userdata.dwTab == dwTab and userdata.dwIndex == dwIndex then
		return true
	end
end

local _tip_userdata = {}
function OutputItemTip(nType, ag1, ag2, ag3, Rect, bLink, szFromLootOrShop, aShopInfo, bNoCmp, nBookInfo, dwPlayerID, dwCmpPlayerID, nPosType, bVisibleWhenHideUI, szPackageType)
	local hFrame = nil
	if nType == UI_OBJECT_ITEM  then
        local dwBox, dwX = ag1, ag2
		local item = GetPlayerItem(GetClientPlayer(), dwBox, dwX, szPackageType, GetShareBagASPSource())
		if item then
			if not IsItemTipUpdate(item, bLink) then
				return
			end

			local szTip, _, bRefresh = GetItemTip(item, dwBox, dwX, szFromLootOrShop, aShopInfo, nil, dwPlayerID, not bNoCmp, bLink, szPackageType)
			_tip_userdata.dwID = item.dwID
			_tip_userdata.bRefresh = bRefresh
			if IsMobileStreamingEnable() then
				nPosType = ALW.TOP_CENTER
			end
			hFrame = OutputTip(szTip, 380, Rect, nPosType, bLink, "item"..item.dwID, nil, nil, nil, nil, _tip_userdata, nil, nil, bVisibleWhenHideUI)
			FormatHorseTip(hFrame, item)

			OutputQixiItemTip(item, dwBox, dwX, Rect, nPosType, bLink, dwCmpPlayerID, bNoCmp, "item"..item.dwID, bVisibleWhenHideUI, szPackageType)
			OutputHoresEnchantTip(item, Rect, nPosType, bNoCmp, bVisibleWhenHideUI)
		end
	elseif nType == UI_OBJECT_ITEM_ONLY_ID then
        local dwID = ag1
        local dwBox, dwX = ag2, ag3
		local item = GetItem(dwID)
		if item then
			if not IsItemTipUpdate(item, bLink) then
				return
			end

			local szTip, _, bRefresh = GetItemTip(item, dwBox, dwX, szFromLootOrShop, aShopInfo, nil, dwPlayerID, not bNoCmp, bLink, szPackageType)
			_tip_userdata.dwID = item.dwID
			_tip_userdata.bRefresh = bRefresh
			if IsMobileStreamingEnable() then
				nPosType = ALW.TOP_CENTER
			end
			hFrame = OutputTip(szTip, 345, Rect, nPosType, bLink, "item"..item.dwID, nil, nil, nil, nil, _tip_userdata, nil, nil, bVisibleWhenHideUI)
			FormatHorseTip(hFrame, item)

			OutputQixiItemTip(item, dwBox, dwX, Rect, nPosType, bLink, dwCmpPlayerID, bNoCmp, "item"..item.dwID, bVisibleWhenHideUI, szPackageType)
			OutputHoresEnchantTip(item, Rect, nPosType, bNoCmp, bVisibleWhenHideUI)
		end
	elseif nType == UI_OBJECT_ITEM_INFO then
        local nVer, dwTabType, dwIndex = ag1, ag2, ag3
		if not bLink and IsSameItemInfoTip(dwTabType, dwIndex) then
			return
		end

		local szTip, itemInfo, bRefresh = GetItemInfoTip(nVer, dwTabType, dwIndex, szFromLootOrShop, aShopInfo, nBookInfo, dwPlayerID, not hNoCmp, bLink)
		_tip_userdata.dwTab = dwTabType
		_tip_userdata.dwIndex = dwIndex

		if IsMobileStreamingEnable() then
			nPosType = ALW.TOP_CENTER
		end
		hFrame = OutputTip(szTip, 345, Rect, nPosType, bLink, "iteminfo"..nVer.."x"..dwTabType.."x"..dwIndex, nil, nil, nil, nil, _tip_userdata, nil, nil, bVisibleWhenHideUI)
		FormatHorseTip(hFrame, itemInfo)

		OutputQixiItemTip(itemInfo, nil, nil, Rect, nPosType, bLink, dwCmpPlayerID, bNoCmp, "iteminfo"..nVer.."x"..dwTabType.."x"..dwIndex, bVisibleWhenHideUI, szPackageType)
	elseif nType == UI_OBJECT_MOUNT then
        local nUiId = ag1
		local szTip = GetEnchantTip(nUiId)
		if szTip and szTip ~= "" then
			if IsMobileStreamingEnable() then
				nPosType = ALW.TOP_CENTER
			end
			OutputTip(szTip, 345, Rect, nPosType, nil, nil, nil, nil, nil, nil, nil, nil, nil,  bVisibleWhenHideUI)
		end
	end
end

local function fnFormatHorseTip(hFrame)
	local hMsg = GetTipHandleByFrame(hFrame)
	local nW, nH = hMsg:GetSize()

	local nCount = hMsg:GetItemCount() - 1
	for i = 0, nCount do
		local hItem = hMsg:Lookup(i)
		if hItem:GetName() == "horseattr" then
			local hItem1 = hItem:Lookup(0)
			local hItem2 = hItem:Lookup(1)
			hItem2:SetW(nW - 40)
			hItem2:FormatAllItemPos()
			hItem2:SetSizeByAllItemSize()
			hItem1:SetH(hItem2:GetH())

			hItem:FormatAllItemPos()
			hItem:SetSizeByAllItemSize()
			hItem:SetH(hItem:GetH() + 3)
		end
	end
	hMsg:FormatAllItemPos()
	AdjustTipPanelSize(hFrame)
end

function FormatHorseTip(hFrame, item)
	if not hFrame then
		return
	end

	if item and item.nGenre == ITEM_GENRE.EQUIPMENT and item.nSub == EQUIPMENT_SUB.HORSE then
		fnFormatHorseTip(hFrame)
	end
end

local function GetToyCollectTip(dwItemIndex)
	local szTip = ""
	local hPlayer = GetClientPlayer()
	if not hPlayer or not hPlayer.RemoteDataAutodownFinish() then
		return szTip
	end

	local tToy = Table_GetToyBoxByItem(dwItemIndex)
	if not tToy then
		return szTip
	end

	szTip = GetFormatText("\t")

	local nStatus = GET_STATUS.NOT_COLLECTED
	local nFont = 108
	if hPlayer.GetRemoteBitArray(REMOTE_DATA.TOY_BOX, tToy.dwID) then
		nStatus = GET_STATUS.COLLECTED
		nFont = 106
	end
	local szCollect = g_tStrings.tCoinshopGet[nStatus]
	szTip = szTip .. GetFormatText(szCollect .. "\n", nFont)
	return szTip
end

local function GetItemNameAndStrengthTip(item, nBookInfo, bItem, nIndex, tSource)
	local szTip = ""
	szTip = szTip.."<Text>text="..EncodeComponentsString(GetItemNameByItemInfo(item, nBookInfo))..
			" font=60 "..GetItemFontColorByQuality(item.nQuality, true).." </text>"

	-----------强化等级–-------------------
	if IsItemCanBeEquip(item.nGenre, item.nSub) then
        local tStrengthInfo = CastingPanel.GetStrength(item, bItem, tSource)
        for i = 1, tStrengthInfo.nTrueLevel do
            szTip = szTip .. "<image>w=16 h=16 path=\"ui/Image/UICommon/FEPanel.UITex\" frame=39 </image>"
        end
        for i = tStrengthInfo.nTrueLevel + 1, tStrengthInfo.nEquipMaxLevel do
            szTip = szTip .. "<image>w=16 h=16 path=\"ui/Image/UICommon/FEPanel.UITex\" frame=49 </image>"
        end

        local bLink = tSource and tSource.bLink
        if tStrengthInfo.nBoxLevel and tStrengthInfo.nBoxMaxLevel and not bLink then
            szTip = szTip .. GetFormatText("\t")
            szTip = szTip .. GetFormatText(FormatString(g_tStrings.STR_ITEM_H_STRENGTH_LEVEL_NEW, tStrengthInfo.nBoxLevel, tStrengthInfo.nBoxMaxLevel), 192)
        end
        szTip = szTip .. GetFormatText("\n")
	elseif item.nGenre == ITEM_GENRE.EQUIPMENT and item.nSub == EQUIPMENT_SUB.HORSE then
		if bItem then
			-----------马匹饱食程度-----------------
			local tDisplay = Table_GetRideSubDisplay(item.nDetail)
			local nFullLevel = item.GetHorseFullLevel()
			local szFullMeasureState = tDisplay["szFullMeasure" .. (nFullLevel + 1)]
			local nFont
			if nFullLevel == FULL_LEVEL.FULL then
				nFont = 165
			elseif nFullLevel == FULL_LEVEL.HALF_HUNGRY then
				nFont = 163
			elseif nFullLevel == FULL_LEVEL.HUNGRY then
				nFont = 164
			end
			szTip = szTip..GetFormatText(g_tStrings.STR_ONE_CHINESE_SPACE .. szFullMeasureState.."\n", nFont)
		else
			szTip = szTip .. GetFormatText("\n")
		end
	elseif item.nGenre == ITEM_GENRE.EQUIPMENT and IsPendantPetItem(item) then
		local hPlayer = GetClientPlayer()
		if hPlayer then
			szTip = szTip .. GetFormatText("\t")
			local bExit = hPlayer.IsHavePendentPet(nIndex)
			local nStatus = GET_STATUS.NOT_COLLECTED
			local nFont = 108
			if bExit then
				nStatus = GET_STATUS.COLLECTED
				nFont = 106
			end
			local szCollect = g_tStrings.tCoinshopGet[nStatus]
			szTip = szTip .. GetFormatText(szCollect .. "\n", nFont)
		end
	elseif item.nGenre == ITEM_GENRE.EQUIPMENT and IsPendantItem(item) then
		local hPlayer = GetClientPlayer()
		if hPlayer then
			szTip = szTip .. GetFormatText("\t")
			local bExit = hPlayer.IsPendentExist(nIndex)
			local nStatus = GET_STATUS.NOT_COLLECTED
			local nFont = 108
			if bExit then
				nStatus = GET_STATUS.COLLECTED
				nFont = 106
			end
			local szCollect = g_tStrings.tCoinshopGet[nStatus]
			szTip = szTip .. GetFormatText(szCollect .. "\n", nFont)
		end
	elseif item.nGenre == ITEM_GENRE.EQUIPMENT and item.nSub == EQUIPMENT_SUB.PET then
		local hPlayer = GetClientPlayer()
		if hPlayer then
			szTip = szTip .. GetFormatText("\t")
			local nPetIndex = GetFellowPetIndexByItemIndex(ITEM_TABLE_TYPE.CUST_TRINKET, nIndex)
			local bHave = hPlayer.IsFellowPetAcquired(nPetIndex)
			local nStatus = GET_STATUS.NOT_COLLECTED
			local nFont = 108
			if bHave then
				nStatus = GET_STATUS.COLLECTED
				nFont = 106
			end
			local szCollect = g_tStrings.tCoinshopGet[nStatus]
			szTip = szTip .. GetFormatText(szCollect .. "\n", nFont)
		end
	elseif item.nGenre == ITEM_GENRE.TOY then
		szTip = szTip .. GetToyCollectTip(nIndex)
	else
		szTip = szTip .. GetFormatText("\n")
	end

	return szTip
end

----绑定信息----------------
local function GetItemInfoBindTip(itemInfo)
	local szTip = ""
	if itemInfo.nGenre == ITEM_GENRE.DESIGNATION then
		szTip = szTip.."<Text>text="..EncodeComponentsString(g_tStrings.DESGNATION_ITEM.."\n").." font=106 </text>"
	end
	if itemInfo.nGenre == ITEM_GENRE.TASK_ITEM then
		szTip = szTip.."<Text>text="..EncodeComponentsString(g_tStrings.STR_ITEM_H_QUEST_ITEM.."\n").." font=106 </text>"
	elseif itemInfo.nBindType == ITEM_BIND.INVALID then
	elseif itemInfo.nBindType == ITEM_BIND.NEVER_BIND then
	elseif itemInfo.nBindType == ITEM_BIND.BIND_ON_EQUIPPED then
		szTip = szTip.."<Text>text="..EncodeComponentsString(g_tStrings.STR_ITEM_H_BIND_AFTER_EQUIP).." font=106 </text>"
	elseif itemInfo.nBindType == ITEM_BIND.BIND_ON_PICKED then
		szTip = szTip.."<Text>text="..EncodeComponentsString(g_tStrings.STR_ITEM_H_BIND_AFTER_PICK).." font=106 </text>"
	elseif itemInfo.nBindType == ITEM_BIND.BIND_ON_TIME_LIMITATION then
		szTip = szTip.."<Text>text="..EncodeComponentsString(g_tStrings.STR_ITEM_H_BIND_TIME_LIMITATION1.."\n").." font=107 </text>"
		szTip = szTip.."<Text>text="..EncodeComponentsString(g_tStrings. STR_BIND_TIME_LIMITATION_DESC.."\n").." font=107</text>"
	end
	return szTip
end

local function GetItemPVPPVETip(item)
	local szTip = ""
	if item.nGenre == ITEM_GENRE.EQUIPMENT and (item.nSub >= EQUIPMENT_SUB.MELEE_WEAPON and item.nSub <= EQUIPMENT_SUB.BANGLE) then
		if item.nEquipUsage == 1 then
			szTip = szTip .. "<image>w=16 h=16 path=\"ui/Image/UICommon/CommonPanel8.UITex\" frame=5 </image>"
			.. "<Text>text=" .. EncodeComponentsString(g_tStrings.STR_ITEM_EQUIP_PVE) .. " font=163 r=154 g=200 b=204 </text>"
		elseif item.nEquipUsage == 0 then
			szTip = szTip .. "<image>w=16 h=16 path=\"ui/Image/UICommon/CommonPanel8.UITex\" frame=4 </image>"
			.. "<Text>text=" .. EncodeComponentsString(g_tStrings.STR_ITEM_EQUIP_PVP) .. " font=163 r=154 g=200 b=204 </text>"
		else
			szTip = szTip .. "<image>w=16 h=16 path=\"ui/Image/UICommon/CommonPanel8.UITex\" frame=4 </image>"
			.. "<Text>text=" .. EncodeComponentsString(g_tStrings.STR_ITEM_EQUIP_PVX) .. " font=163 r=154 g=200 b=204 </text>"
		end

        if item.nStrengthLevel > 0 then
            szTip = szTip .. GetFormatText("\t")
            local nMaxLevel = GetItemInfo(item.dwTabType, item.dwIndex).nMaxStrengthLevel
            szTip = szTip .. GetFormatText(FormatString(g_tStrings.STR_ITEM_H_STRENGTH_LEVEL, item.nStrengthLevel, nMaxLevel), 192)
        end

		szTip = szTip .. GetFormatText("\n")
	end

	return szTip
end

local function GetItemBindTip(item, player, szFromLootOrShop)
	local szTip = ""
	local bNeedRefresh = false
	-----------绑定属性----------------
	if item.nGenre == ITEM_GENRE.DESIGNATION then
		szTip = szTip.."<Text>text="..EncodeComponentsString(g_tStrings.DESGNATION_ITEM.."\n").." font=106 </text>"
	end
	if item.nGenre == ITEM_GENRE.TASK_ITEM then
		szTip = szTip.."<Text>text="..EncodeComponentsString(g_tStrings.STR_ITEM_H_QUEST_ITEM.."\n").." font=106 </text>"

	elseif item.nBindType == ITEM_BIND.BIND_ON_TIME_LIMITATION then
		local scene = player.GetScene()
		local nLeftTime = scene.TimeLimitationBindItemGetLeftTime(item.dwID)
		if nLeftTime == 0 and item.bBind and not szFromLootOrShop then
			szTip = szTip.."<Text>text="..EncodeComponentsString(g_tStrings.STR_ITEM_H_HAS_BEEN_BIND).." font=107 </text>"
		elseif nLeftTime ~= 0 then
			bNeedRefresh = true
			local nM = math.floor(nLeftTime / 60)
			local szTime = nM..g_tStrings.STR_BUFF_H_TIME_M_SHORT
			szTime = szTime..(nLeftTime - nM * 60)..g_tStrings.STR_BUFF_H_TIME_S
			szTip = szTip.."<Text>text="..EncodeComponentsString(g_tStrings.STR_ITEM_H_BIND_TIME_LIMITATION..": "..szTime.."\n").." font=107</text>"
			szTip = szTip.."<Text>text="..EncodeComponentsString(g_tStrings. STR_BIND_TIME_LIMITATION_DESC.."\n").." font=107</text>"
		else
			szTip = szTip.."<Text>text="..EncodeComponentsString(g_tStrings.STR_ITEM_H_BIND_TIME_LIMITATION1.."\n").." font=107 </text>"
			szTip = szTip.."<Text>text="..EncodeComponentsString(g_tStrings. STR_BIND_TIME_LIMITATION_DESC.."\n").." font=107</text>"
		end

	elseif item.bBind and not szFromLootOrShop then
		szTip = szTip.."<Text>text="..EncodeComponentsString(g_tStrings.STR_ITEM_H_HAS_BEEN_BIND).." font=107 </text>"
	else
		if item.nBindType == ITEM_BIND.INVALID then
		elseif item.nBindType == ITEM_BIND.NEVER_BIND then
		elseif item.nBindType == ITEM_BIND.BIND_ON_EQUIPPED then
			szTip = szTip.."<Text>text="..EncodeComponentsString(g_tStrings.STR_ITEM_H_BIND_AFTER_EQUIP).." font=107 </text>"
		elseif item.nBindType == ITEM_BIND.BIND_ON_PICKED then
			if szFromLootOrShop == "shop" then
				szTip = szTip.."<Text>text="..EncodeComponentsString(g_tStrings.STR_ITEM_H_BIND_AFTER_BUY).." font=107</text>"
			else
				szTip = szTip.."<Text>text="..EncodeComponentsString(g_tStrings.STR_ITEM_H_BIND_AFTER_PICK).." font=107</text>"
			end
		end
	end

	if item.CheckIgnoreBindMask(ITEM_IGNORE_BIND_TYPE.MENTOR) then
		local nLeftTime = item.GetLeftExistTime()
		nLeftTime = nLeftTime or 0
		if nLeftTime > 0 then
			szTip = szTip..g_tStrings.STR_TRADE_MENTOR1..GetFormatText("\n")
		else
			szTip = szTip..g_tStrings.STR_TRADE_MENTOR..GetFormatText("\n")
		end
	end

	if item.CheckIgnoreBindMask(ITEM_IGNORE_BIND_TYPE.TONG) then
		local nLeftTime = item.GetLeftExistTime()
		nLeftTime = nLeftTime or 0
		if nLeftTime > 0 then
			szTip = szTip..g_tStrings.STR_TRADE_TONG1..GetFormatText("\n")
		else
			szTip = szTip..g_tStrings.STR_TRADE_TONG..GetFormatText("\n")
		end
	end
	--[[
	if itemc.CheckIgnoreBindMask(ITEM_IGNORE_BIND_TYPE.DUNGEON) then
		szTip = szTip..g_tStrings.STR_TRADE_MENTOR..GetFormatText("\n")
	end
	]]

	return szTip, bNeedRefresh
end


local function GetItemExistAmountTip(iteminfo)
	local szText = ""
	if iteminfo.nMaxExistAmount ~= 0 then
		if iteminfo.nMaxExistAmount == 1 then
			szText = GetFormatText(g_tStrings.STR_ITEM_H_UNIQUE, 106)
		else
			szText = GetFormatText(FormatString(g_tStrings.STR_ITEM_H_UNIQUE_MULTI, iteminfo.nMaxExistAmount), 106)
		end
	end
	return szText
end
----存在类型----------------
local function GetItemExitTypeTip(itemInfo, nLeftTime)
	local szTip = ""
	local nExistType = itemInfo.nExistType
	nLeftTime = nLeftTime or 0

	if nExistType == ITEM_EXIST_TYPE.OFFLINE then
		if nLeftTime > 0 then
			local szTime = UIHelper.GetTimeText(nLeftTime)
			szTip = szTip..FormatString(g_tStrings.STR_ITEM_OFF_LINE_TIME_OVER, szTime)
		else
			szTip = szTip.."<Text>text="..UIHelper.EncodeComponentsString(g_tStrings.STR_ITEM_TIME_TYPE1.."\n").." font=107</text>"
		end
	elseif nExistType == ITEM_EXIST_TYPE.ONLINE then
		if nLeftTime > 0 then
			local szTime = UIHelper.GetTimeText(nLeftTime)
			szTip = szTip..FormatString(g_tStrings.STR_ITEM_ON_LINE_TIME_OVER, szTime)
		else
			szTip = szTip.."<Text>text="..UIHelper.EncodeComponentsString(g_tStrings.STR_ITEM_TIME_TYPE2.."\n").." font=107</text>"
		end
	elseif nExistType == ITEM_EXIST_TYPE.ONLINEANDOFFLINE or nExistType == ITEM_EXIST_TYPE.TIMESTAMP then
		if nLeftTime > 0 then
			local szTime = UIHelper.GetTimeText(nLeftTime)
			szTip = szTip..FormatString(g_tStrings.STR_ITEM_TIME_OVER, szTime)
		else
			szTip = szTip.."<Text>text="..UIHelper.EncodeComponentsString(g_tStrings.STR_ITEM_TIME_TYPE3.."\n").." font=107</text>"
		end
	end
	return szTip
end
-------------装备类型-----------------
local function GetEquipType(itemInfo)
	local szTip = ""

	local szText = GetEquipTypeName(itemInfo)
	if itemInfo.nGenre == ITEM_GENRE.NPC_EQUIPMENT then
		szText = g_tStrings.tNpcEquipTypeNameTable[itemInfo.nSub]
	else
		szText = g_tStrings.tEquipTypeNameTable[itemInfo.nSub]
		if itemInfo.nSub == EQUIPMENT_SUB.MELEE_WEAPON or
			itemInfo.nSub == EQUIPMENT_SUB.RANGE_WEAPON or
			itemInfo.nSub == EQUIPMENT_SUB.ARROW then
			szText = szText.."\t"..GetWeapenType(itemInfo.nDetail)
		elseif itemInfo.nSub == EQUIPMENT_SUB.AMULET or
			itemInfo.nSub == EQUIPMENT_SUB.RING or
			itemInfo.nSub == EQUIPMENT_SUB.PENDANT then
			--饰品
		elseif itemInfo.nSub == EQUIPMENT_SUB.PACKAGE then
			--包裹
		elseif itemInfo.nSub == EQUIPMENT_SUB.BULLET then
			szText = szText.."\t"..g_tStrings.tBulletDetail[itemInfo.nDetail] or g_tStrings.UNKNOWN_WEAPON
		else
			--防具
		end
	end
	szTip = szTip.."<Text>text="..EncodeComponentsString(szText.."\n").." font=106" .. " </text>"
	return szTip
end

-------------基本属性-----------------
local function GetEquipBaseAttri(item, bItem)
	local szTip = ""
	local szText = ""
	local nFont = 106
	local baseAttib = item.GetBaseAttrib()
	local nWeaponDamageMin, nWeaponDamageMax, fWeaponSpeed
	for k, v in pairs(baseAttib) do
		szText=""
		if v.nID == ATTRIBUTE_TYPE.MELEE_WEAPON_ATTACK_SPEED_BASE or v.nID == ATTRIBUTE_TYPE.RANGE_WEAPON_ATTACK_SPEED_BASE then
			if bItem then	--如果是武器速度,则转换参数
				v.nValue1, v.nValue2 = (v.nValue1 / GLOBAL.GAME_FPS), (v.nValue2 / GLOBAL.GAME_FPS)
				fWeaponSpeed = v.nValue1
			else
				v.nMin, v.nMax = (v.nMin / GLOBAL.GAME_FPS), (v.nMax / GLOBAL.GAME_FPS)
				fWeaponSpeed = v.nMin
			end
		elseif v.nID == ATTRIBUTE_TYPE.MELEE_WEAPON_DAMAGE_BASE or v.nID == ATTRIBUTE_TYPE.RANGE_WEAPON_DAMAGE_BASE then
			if bItem then
				nWeaponDamageMin, nWeaponDamageMax = v.nValue1, v.nValue2
			else
				nWeaponDamageMin, nWeaponDamageMax = v.nMin, (v.nMin + v.nMin1)
			end
		end

		v.nMin1 = v.nMin1 or 0
		v.nMax1 = v.nMax1 or 0
		if v.nID == ATTRIBUTE_TYPE.SKILL_EVENT_HANDLER then
			local value = v.nMin
			if bItem then
				value = v.nValue1
			end

			local skillEvent = g_tTable.SkillEvent:Search(value)
			if skillEvent then
				if bItem then
					szText = FormatString(skillEvent.szDesc, v.nValue1, v.nValue2)
				else
					szText = FormatString(skillEvent.szDesc, v.nMin, v.nMax, v.nMin + v.nMin1, v.nMax + v.nMax1)
				end
			else
				szText = "<text>text=\"unknown skill event id:"..value.."\"</text>"
			end
		elseif v.nID == ATTRIBUTE_TYPE.SET_EQUIPMENT_RECIPE then
			if bItem then
				szText = GetEquipRecipeDesc(v.nValue1, v.nValue2)
			else
				szText = GetEquipRecipeDesc(v.nMin, v.nMin1)
			end
		else
			if bItem then -- 小附魔
				szText = FormatString(Table_GetBaseAttributeInfo(v.nID, true), v.nValue1, v.nValue2)
			else
				szText = FormatString(Table_GetBaseAttributeInfo(v.nID, false), v.nMin, v.nMax, v.nMin + v.nMin1, v.nMax + v.nMax1)
			end
		end

		if item.nGenre ~= ITEM_GENRE.NPC_EQUIPMENT and
			(item.nSub == EQUIPMENT_SUB.MELEE_WEAPON or
			item.nSub == EQUIPMENT_SUB.RANGE_WEAPON)then
			if v.nID == ATTRIBUTE_TYPE.MELEE_WEAPON_ATTACK_SPEED_BASE or v.nID == ATTRIBUTE_TYPE.RANGE_WEAPON_ATTACK_SPEED_BASE then
				szText = "<text>text=\"\\\t\"</text>"..szText
			end
		elseif szText ~= "" then
			szText = szText.."<text>text=\"\\\n\"</text>"
		end
		szTip = szTip..szText
	end

	-------------武器DPS-----------------
	if item.nGenre ~= ITEM_GENRE.NPC_EQUIPMENT and (item.nSub == EQUIPMENT_SUB.MELEE_WEAPON or
		item.nSub == EQUIPMENT_SUB.RANGE_WEAPON) then
		local fDps = 0
		if nWeaponDamageMin and nWeaponDamageMax and fWeaponSpeed then
			fDps = (nWeaponDamageMin + nWeaponDamageMax) / 2 / fWeaponSpeed
			fDps = FixFloat(fDps, 1)
		end
		szTip = szTip.."<text>text="..EncodeComponentsString(g_tStrings.STR_ITEM_H_WEAPON_DPS..fDps.."\n").." font="..nFont.." </text>"
	end

	return szTip
end

----item 魔法属性----------------------------
local function GetMagicAttriTip(item, bItem, tSource)
	local szTip  = ""
	local szText = ""

	local nSrcAttri, nDstAttri, nSrcPer, nDstPer = item.GetChangeInfo()
    local nStrengthLevel = CastingPanel.GetStrength(item, bItem, tSource).nTrueLevel
	local magicAttrib = item.GetMagicAttrib()

	local magicStrengthAttribOrg = {}
	local magicStrengthAttrib = {}
	if item.nGenre ~= ITEM_GENRE.NPC_EQUIPMENT then
		magicStrengthAttribOrg= item.GetMagicAttribByStrengthLevel(0)
		magicStrengthAttrib = item.GetMagicAttribByStrengthLevel(nStrengthLevel)
	end

	for k, v in pairs(magicAttrib) do
		szTip = szTip .. GetMagicAttriText(item, v, true, magicStrengthAttribOrg, magicStrengthAttrib, tSource)
		if nSrcAttri == v.nID then
			szTip = szTip .. "<text>text=\" \"</text><image>w=12 h=15 path=\"ui/Image/UICommon/RankingPanel.UITex\" frame=21 </image>"
		end
		szTip = szTip .. "<text>text=\"\\\n\"</text>"
	end

	local fChangePer = item.GetChangeCof()
	local changeAttrib = item.GetChangeAttrib()
	local changeStrengthAttribOrg = {}
	local changeStrengthAttrib = {}
	if item.nGenre ~= ITEM_GENRE.NPC_EQUIPMENT then
		changeStrengthAttribOrg = item.GetChangeAttribByStrengthLevel(0)
		changeStrengthAttrib = item.GetChangeAttribByStrengthLevel(nStrengthLevel)
	end
	for k, v in pairs(changeAttrib) do
		szTip = szTip .. GetMagicAttriText(item, v, true, changeStrengthAttribOrg, changeStrengthAttrib, tSource)
		if nDstAttri == v.nID then
			local _, _, level, r, g, b = EquipMagicChange_GetLevel( fChangePer )
			local szLevel = FormatString(g_tStrings.CHANGE_LEVEL, g_tStrings.STR_NUMBER[level])
			local szColor = string.format(" r=%d, g=%d, b=%d ", r, g, b)
			local szImage = "<image>w=12 h=17 path=\"ui/Image/UICommon/RankingPanel.UITex\" frame=22 </image>"
			szTip = szTip .. FormatString(g_tStrings.CHANGE_LEVEL_TIP, szColor, szImage, szLevel)
		end
		szTip = szTip .. "<text>text=\"\\\n\"</text>"
	end
	return szTip
end

----魔法属性----------------------------
function GetItemInfoMagicAttriTip(itemInfo, tSource)
	local szTip = ""
    local nStrengthLevel = CastingPanel.GetStrength(itemInfo, false, tSource).nTrueLevel
	local magicAttrib = GetItemMagicAttrib(itemInfo.GetMagicAttribIndexList())
    local magicStrengthAttribOrg = itemInfo.GetMagicAttribByStrengthLevel(0)
	local magicStrengthAttrib = itemInfo.GetMagicAttribByStrengthLevel(nStrengthLevel)
	for k, v in pairs(magicAttrib) do
		szTip = szTip .. GetMagicAttriText(itemInfo, v, false, magicStrengthAttribOrg, magicStrengthAttrib)
		szTip = szTip .. "<text>text=\"\\\n\"</text>"
	end
	return szTip
end

-----马的基本属性和魔法属性------------
local function GetHorseAttriBasicTip(tAllAttr)
	local szBasicTip = ""
	local nIndex = 0
	for k, v in pairs(tAllAttr) do
		local dwID, nLevel, nValue = v[1], v[2], v[3]
		local tAttr = Table_GetHorseChildAttr(dwID, nLevel)

		if tAttr and tAttr.nType == 0 then
			nIndex = nIndex + 1

			local szTip =  string.gsub(tAttr.szTip, "font=%d+", "font=162")
			local szAttr = FormatString(szTip, nValue) or ""
			szAttr = szAttr .. GetFormatText("\n")

			local szTip ="<text>text="..EncodeComponentsString(szAttr).."font=162</text>"
			szBasicTip = szBasicTip .. szAttr
		end
	end

	return szBasicTip
end

local function GetHorseAttriSpecialTip(tAllAttr)
	local szMagicTip = ""
	local szLine
	for k, v in pairs(tAllAttr) do
		local dwID, nLevel, nValue = v[1], v[2], v[3]
		local tAttr = Table_GetHorseChildAttr(dwID, nLevel)

		if tAttr and tAttr.nType == 1 then
			local nIconID 	= tAttr.nIconID
			local szAttr 	= tAttr.szName
			if nLevel > 0 then
				szAttr = szAttr .. nLevel .. g_tStrings.STR_LEVEL
			end

			local szTip = string.gsub(tAttr.szTip, "font=%d+", "font=162")
			szTip = FormatString(szTip, nValue) or ""

			szLine = "<handle>firstpostype=0 w=24 h=55 x=0 y=0 <box>w=24 h=24 y=1 iconid="..nIconID.."eventid=256</box></handle>"
			szLine = szLine .. "<handle>handletype=3 w=300 h=55 <text>text="..EncodeComponentsString(szAttr).."font=165</text>"..GetFormatText("\n") .. szTip .."</handle>"
			szLine = "<handle>name=\"horseattr\" firstpostype=0 handletype=3 " .. szLine .. " </handle>"
			szMagicTip = szMagicTip ..szLine..GetFormatText("\n")
		end
	end

	return szMagicTip
end

local function GetHorseAttri(item, itemInfo)
	local tAllAttr = HorsePanel.GetLogicAttr(item, itemInfo)

	local szBasicTip = GetHorseAttriBasicTip(tAllAttr)
	local szMagicTip = GetHorseAttriSpecialTip(tAllAttr)

	return szBasicTip .. szMagicTip
end

local function GetAttriInfo(nIndex, item, bItem, nLevel, tSource)
    local dwEnchantID = 0
    dwEnchantID = CastingPanel.GetEnchantID(nIndex, item, bItem, tSource)
    return dwEnchantID > 0, item.GetSlotAttrib(nIndex, nLevel) or {}
end

local function GetEquipSlotDiamon(nIndex, item, bItem, tSource)
	local diamon
    local dwEnchantID = CastingPanel.GetEnchantID(nIndex, item, bItem, tSource)
    if dwEnchantID > 0 then
        local nType, nTabIndex = GetDiamondInfoFromEnchantID(dwEnchantID)
        if nType and nTabIndex then
            diamon = GetItemInfo(nType, nTabIndex)
        end
    end
	return diamon
end

local function GetSlotAttr(item, nSlot, bItem, force_active, tSource)
	local nLevel = 0
	local diamon = GetEquipSlotDiamon(nSlot, item, bItem, tSource)
	if diamon then
		nLevel = diamon.nDetail
	end

	local bActived, equipAttrib = GetAttriInfo(nSlot, item, bItem, nLevel, tSource)
	if force_active ~= nil then
		bActived = force_active
	end

	if not bActived then
		equipAttrib.Param0 = g_tStrings.STR_QUESTION_M
		equipAttrib.Param1 = g_tStrings.STR_QUESTION_M
	end
	local szTmpText = nil
	if not bActived then
		szTmpText = g_tStrings.tDeactives[equipAttrib.nID]
	end

	if not szTmpText then
		szTmpText = FormatString(Table_GetMagicAttributeInfo(equipAttrib.nID, true), equipAttrib.Param0, equipAttrib.Param1, MAGIC_ATTRI_DEF, MAGIC_ATTRI_DEF)
		szTmpText = GetPureText(szTmpText)
	end
	szTmpText = g_tStrings.STR_ITEM_SLOT .. szTmpText
	return szTmpText, bActived
end

----五行石 孔属性------------------------------
local function GetEquipSlotTip(item, bItem, tSource)
	local szTip  = ""
	local szText = ""
	local szTmpText, currentAttr
	local org_text, bActived
	local nSlots = item.GetSlotCount()
	local font = 161
	for i = 1, nSlots, 1 do
		local nLevel = 0
		local diamon = GetEquipSlotDiamon(i - 1, item, bItem, tSource)
		if diamon then
			szText = "<image>w=24 h=24 path=\"fromiconid\" frame=" .. Table_GetItemIconID(diamon.nUiId) .. "</image>"
		else
			szText = "<image>w=24 h=24 path=\"ui/Image/UICommon/FEPanel.UITex\" frame=5 </image>"
		end

		font = 161
		org_text = nil
		currentAttr, bActived = GetSlotAttr(item, i - 1, bItem, nil, tSource)
		currentAttr = currentAttr or ""
		if bItem then
			local itemInfo = GetItemInfo(item.dwTabType, item.dwIndex)
			local orgAttr = GetSlotAttr(item, i - 1, true, false, tSource)
			local oldAttr = GetSlotAttr(itemInfo, i - 1, false, false, tSource)
			if orgAttr ~= oldAttr then
				font = 161
				org_text = "<image>w=24 h=24 path=\"ui/Image/UICommon/FEPanel.UITex\" frame=5 lockshowhide=1 </image>"
				org_text = org_text .. "<text>text=" .. EncodeComponentsString(oldAttr .. g_tStrings.STR_ORG_ATTRI )  .. " font=161 </text>"
				if org_text ~= "" then
					org_text = org_text .. GetFormatText("\n")
				end
			end
		end

		if not bActived then
			szTmpText = "<text>text=" .. EncodeComponentsString(currentAttr) .. " font=" .. font .. "</text>"
		else
			szTmpText = "<text>text=" .. EncodeComponentsString(currentAttr) .. " font=105 </text>"
		end
		szText = szText .. szTmpText

		if szText ~= "" then
			szText = szText .. GetFormatText("\n")
		end
		szTip = szTip .. szText

		if org_text then
			szTip = szTip .. org_text
		end
	end
	return szTip
end

----五彩石属性--------------------------------
local function GetColorDiamondTip(dwPlayerID, item, bItem, nBoxIndex, nBoxItemIndex)
	local function GetIntroduceTip()
        local szText = GetFormatImage("ui/Image/UICommon/FEPanel.UITex", 5, 24, 24)
		szText = szText .. "<text>text=" .. EncodeComponentsString(g_tStrings.STR_ITEM_H_COLOR_DIAMOND) .. " font=161 </text>"
		szText = szText.."<text>text=\"\\\n\"</text>"
		return szText
	end

	if not bItem then
		return GetIntroduceTip()
	end

	local nEnchantID = item.GetMountFEAEnchantID()
	if nEnchantID == 0 then
		return GetIntroduceTip()
	end

	local szTip = ""
	local dwTabType, dwIndex = GetColorDiamondInfoFromEnchantID(nEnchantID)
	local itemInfo = GetItemInfo(dwTabType, dwIndex)
	local szText = "<image>w=24 h=24 path=\"fromiconid\" frame=" .. Table_GetItemIconID(itemInfo.nUiId) .. "</image>"
	szTip = szTip .. szText

	szText = ""
	local aAttr = GetFEAInfoByEnchantID(nEnchantID)
	local skillEvent_tab = g_tTable.SkillEvent
	local bFirst = true
	for k, v in pairs(aAttr) do
		EquipData.FormatAttributeValue(v)
		local szPText = ""
		if v.nID == ATTRIBUTE_TYPE.SKILL_EVENT_HANDLER then
			local skillEvent = skillEvent_tab:Search(v.nValue1)
			if skillEvent then
				szPText = FormatString(skillEvent.szDesc, v.nValue1, v.nValue2)
			else
				szPText = "<text>text=\"unknown skill event id:"..v.nValue1.."\"</text>"
			end
		else
			szPText = FormatString(Table_GetMagicAttributeInfo(v.nID, true), v.nValue1, v.nValue2, MAGIC_ATTRI_DEF, MAGIC_ATTRI_DEF)
		end

		szPText = GetPureText(szPText)
		if not bFirst then
			szPText = "      " .. szPText
		end

		local bActive = GetFEAActiveFlag(dwPlayerID, nBoxIndex, nBoxItemIndex, tonumber(k) - 1)
        if bActive then
            szText = "<text>text=\"" .. szPText .. "\" font=105 </text>"
        else
            szText = "<text>text=\"" .. szPText .. "\" font=161 </text>"
        end

		szText = szText .. "<text>text=\"\\\n\"</text>"
		szTip = szTip .. szText
        bFirst = false
	end

	return szTip
end

----需求属性--------------------------
local function GetRequireTip(player, item, bItem, bGenerated)
	local szTip  = ""
	local szText = ""
	local nFont  = 106
	local aValue

	local requireAttrib = item.GetRequireAttrib()
	for k, v in pairs(requireAttrib) do
		nFont = 106
		if bItem then
			aValue = { v.nValue1, v.nValue2 }
		else
			aValue = { v.nValue }
		end

		if player and not player.SatisfyRequire(v.nID, unpack(aValue)) then
			nFont = 102
		end

		if v.nID == 7 then		-- 需求的是性别
			aValue[ 1 ] = g_tStrings.tGender[ aValue[ 1 ] ]
		elseif v.nID == 6 then		-- 需求的是门派
			aValue[ 1 ] = Table_GetForceName( aValue[ 1 ] )
		end

		table.insert(aValue, nFont)
		szText = FormatString(Table_GetRequireAttributeInfo(v.nID, bGenerated), unpack(aValue))
		if szText ~= "" then
			szText = szText.."<text>text=\"\\\n\"</text>"
		end
		szTip = szTip..szText
	end
	return szTip
end

----耐久度-------------------------------------
local function GetDurabilityTip(item, bItem)
	local szTip = ""
	if IsPendantItem(item) or
		item.nSub == EQUIPMENT_SUB.AMULET or
		item.nSub == EQUIPMENT_SUB.RING or
		item.nSub == EQUIPMENT_SUB.PENDANT or
		item.nSub == EQUIPMENT_SUB.BULLET or
		item.nSub == EQUIPMENT_SUB.HORSE or
		item.nSub == EQUIPMENT_SUB.MINI_AVATAR or
		item.nSub == EQUIPMENT_SUB.PET or
		item.nSub == EQUIPMENT_SUB.HORSE_EQUIP or
		item.nSub == EQUIPMENT_SUB.NAME_CARD_SKIN or
		item.nSub == EQUIPMENT_SUB.PENDENT_PET
	then
		--饰品(挂件),饰品没有耐久度
	elseif item.nSub == EQUIPMENT_SUB.PACKAGE then
		 --包裹,包裹的耐久度用作格子大小

		local value = 0
		if bItem then
			value = item.nCurrentDurability
		else
			value = item.nMaxDurability
		end
		szTip = szTip.."<Text>text="..EncodeComponentsString(FormatString(g_tStrings.STR_ITEM_H_BAG_SIZE, value)).." font=106 </text>"

	elseif item.nSub == EQUIPMENT_SUB.ARROW then
		--如果是远程武器弹药，则耐久度为数量
	else
		--武器、防具
		if bItem then
			if item.nCurrentDurability == 0 then
				szTip = szTip.."<Text>text="..EncodeComponentsString(FormatString(g_tStrings.STR_ITEM_H_DURABILITY, item.nCurrentDurability, item.nMaxDurability)).." font=102 </text>"
			else
				szTip = szTip.."<Text>text="..EncodeComponentsString(FormatString(g_tStrings.STR_ITEM_H_DURABILITY, item.nCurrentDurability, item.nMaxDurability)).." font=106 </text>"
			end
		else
			szTip = szTip.."<Text>text="..EncodeComponentsString(FormatString(g_tStrings.STR_ITEM_H_MAX_DURABILITY, item.nMaxDurability)).." font=106 </text>"
		end
	end
	return szTip
end

----附魔属性--------------------------
local function GetEnchantAttribTip( item, player )
	player = player or GetClientPlayer()

	local tEnchantTipShow = Table_GetEnchantTipShow()
	local tShow = tEnchantTipShow[item.nSub]

	local szTip  = ""
	local fnAction = function (v)
		if v.nID == ATTRIBUTE_TYPE.SKILL_EVENT_HANDLER then
			local skillEvent = g_tTable.SkillEvent:Search(v.nValue1)
			if skillEvent then
				return FormatString(skillEvent.szDesc, v.nValue1, v.nValue2)
			else
				return "<text>text=\"unknown skill event id:"..v.nValue1.."\"</text>"
			end
		elseif v.nID == ATTRIBUTE_TYPE.SET_EQUIPMENT_RECIPE then
			return GetEquipRecipeDesc(v.nValue1, v.nValue2)
		else
			EquipData.FormatAttributeValue(v)
			return FormatString(Table_GetMagicAttributeInfo(v.nID, true), v.nValue1, v.nValue2, MAGIC_ATTRI_DEF, MAGIC_ATTRI_DEF)
		end
	end

	local szText
	local szImagePath = "ui/Image/UICommon/FEPanel.UITex"
	local nFrame = 41
	local nUnEnchantFrame = 42

	local nSruvivalFrame = 41
	local nUnSruvivalFrame = 42
	local nSpecialFrame = 44
	if item.dwPermanentEnchantID ~= 0 then
		local desc = Table_GetCommonEnchantDesc(item.dwPermanentEnchantID) -- 大附魔
		if desc then
			desc = string.gsub(desc, "font=%d+", "font=113")
			szTip = szTip .. GetFormatImage(szImagePath, nFrame, 24, 24)
			szTip = szTip .. desc  .. GetFormatText("\n")
		else
			local enchantAttrib = GetItemEnchantAttrib(item.dwPermanentEnchantID);
			if enchantAttrib then
				for k, v in pairs(enchantAttrib) do
					szText = fnAction(v)
					szText = string.gsub(szText, "font=%d+", "font=113")
					if szText ~= "" then
						szText = szText  .. GetFormatText("\n")
					end
					szTip = szTip .. GetFormatImage(szImagePath, nFrame, 24, 24)
					szTip = szTip .. szText
				end
			end
		end
	else
		if tShow and tShow.bPermanentEnchant then
			szTip = szTip .. GetFormatImage(szImagePath, nUnEnchantFrame, 24, 24)
			szTip = szTip .. GetFormatText(g_tStrings.ITEM_TIP_NO_ENCHANT_PERMANENT .. "\n", 161)
		end
	end
	local bSurvival = tShow and tShow.bSurvivalEnchant
	if item.dwTemporaryEnchantID ~= 0 then
		local bValid = player.IsTempEnchantValid(item.dwTemporaryEnchantID)
		local desc = Table_GetCommonEnchantDesc(item.dwTemporaryEnchantID)
		local szFont = "font=108"
		local nImageFrame = nFrame
		if bValid then
			if bSurvival then
				szFont = "font=101"
				nImageFrame = nSruvivalFrame
			else
				szFont = "font=113"
			end
		end
		if desc then
			desc = string.gsub(desc, "font=%d+", szFont)
			if desc ~= "" and not bSurvival then
                if item.nSub == EQUIPMENT_SUB.MELEE_WEAPON or item.nSub == EQUIPMENT_SUB.PANTS then
                    local szTime = FormatString(g_tStrings.STR_ITEM_TEMP_ECHANT_LEFT_TIME, GetTimeText(item.GetTemporaryEnchantLeftSeconds()))
                    desc = desc .. GetFormatText(szTime, 102)
                else
					nImageFrame = nSpecialFrame
				end
			end
			szTip = szTip .. GetFormatImage(szImagePath, nImageFrame, 24, 24)
			szTip = szTip.. desc .. GetFormatText("\n")
		else
			local tempEnchantAttrib = GetItemEnchantAttrib(item.dwTemporaryEnchantID);
			if tempEnchantAttrib then
				for k, v in pairs(tempEnchantAttrib) do
					szText = fnAction(v)
					szText = string.gsub(szText, "font=%d+", szFont)
					if szText ~= "" and not bSurvival then
                        if item.nSub == EQUIPMENT_SUB.MELEE_WEAPON or item.nSub == EQUIPMENT_SUB.PANTS then
                            local szTime = FormatString(g_tStrings.STR_ITEM_TEMP_ECHANT_LEFT_TIME, GetTimeText(item.GetTemporaryEnchantLeftSeconds()))
                            szText = szText .. GetFormatText(szTime, 102)
                        else
                            nImageFrame = nSpecialFrame
						end
					end
					szTip = szTip .. GetFormatImage(szImagePath, nImageFrame, 24, 24)
					szTip = szTip .. szText ..  GetFormatText("\n")
				end
			end
		end
	else
		if bSurvival then
			szTip = szTip .. GetFormatImage(szImagePath, nUnSruvivalFrame, 24, 24)
			szTip = szTip .. GetFormatText(g_tStrings.ITEM_TIP_NO_ENCHANT_SURVIVAL .. "\n", 161)
		elseif tShow and tShow.bTemporaryEnchant then
			szTip = szTip .. GetFormatImage(szImagePath, nUnEnchantFrame, 24, 24)
			szTip = szTip .. GetFormatText(g_tStrings.ITEM_TIP_NO_ENCHANT_TEMPORARY .. "\n", 161)
		end
	end

	return szTip
end

-----------装备类型 基本属性 魔法属性 五行石 孔属性 五彩石属性 需求属性 耐久度-------------
local function GetEquipItemInfoTip(itemInfo, player, nIndex, tSource)
	local szTip = ""

	-----------阵营需求---------------
	szTip = szTip .. GetItemInfoCampInfoTip(itemInfo, player, nIndex)

	-------------装备类型-----------------
	szTip = szTip .. GetEquipType(itemInfo)

	if itemInfo.nSub == EQUIPMENT_SUB.HORSE then
		szTip = szTip .. GetHorseAttri(nil, itemInfo)
	else
		-------------基本属性-----------------
		szTip = szTip .. GetEquipBaseAttri(itemInfo)

		----魔法属性----------------------------
		szTip = szTip .. GetItemInfoMagicAttriTip(itemInfo, tSource)
	end

	----五行石 孔属性------------------------------
	if itemInfo.nGenre == ITEM_GENRE.EQUIPMENT then
		szTip = szTip .. GetEquipSlotTip(itemInfo, false, tSource)

		if itemInfo.nSub == EQUIPMENT_SUB.MELEE_WEAPON then
		----五彩石属性--------------------------------
			szTip = szTip .. GetColorDiamondTip(tSource.dwPlayerID, itemInfo, false)
		end

		------------需求属性------------------
		if nTabType ~= ITEM_TABLE_TYPE.OTHER then
			szTip =  szTip .. GetRequireTip(player, itemInfo, false, false)
		end

		-------------耐久度------------------
		szTip = szTip .. GetDurabilityTip(itemInfo, false)
	end

	return szTip
end

-----------装备类型 基本属性 魔法属性 五行石 孔属性 五彩石属性 需求属性 耐久度-------------
local function GetEquipItemTip(item, player, nBoxIndex, nBoxItemIndex, tSource)
	local szTip = ""

	local itemInfo = GetItemInfo(item.dwTabType, item.dwIndex)
	szTip = szTip .. GetItemInfoCampInfoTip(itemInfo, player, item.dwIndex)

	-------------装备类型-----------------
	szTip = szTip .. GetEquipType(item)

	-------------基本属性-----------------
	-------------魔法属性-----------------
	if item.nSub == EQUIPMENT_SUB.HORSE then
		szTip = szTip .. GetHorseAttri(item, nil)
	else
		szTip = szTip .. GetEquipBaseAttri(item, true)
        if item.nSub ~= EQUIPMENT_SUB.ARROW then
		    szTip = szTip .. GetMagicAttriTip(item, true, tSource)
        end
	end

	----五行石 孔属性------------------------------
	if item.nGenre == ITEM_GENRE.EQUIPMENT then
		szTip = szTip .. GetEquipSlotTip(item, true, tSource)

		if item.CanMountColorDiamond() then
		----五彩石属性--------------------------------
			szTip = szTip .. GetColorDiamondTip(tSource.dwPlayerID, item, true,  nBoxIndex, nBoxItemIndex)
		end


		if item.dwTabType ~= ITEM_TABLE_TYPE.OTHER then
			------------需求属性------------------
			szTip =  szTip .. GetRequireTip(player, item, true, true)
		end

		-------------耐久度------------------
		szTip = szTip .. GetDurabilityTip( item, true )

		----附魔属性--------------------------
		szTip = szTip .. GetEnchantAttribTip( item, player )
	end
	return szTip
end

----材料---------------------------------
local function GetMateralTip(item)
	local szTip = ""
	if item.nSub == ITEM_SUBTYPE_RECIPE then
		szTip = szTip .. GetFormatText(g_tStrings.STR_SKILL_RECIPE .. "\n", 162)
		local bRead = IsMystiqueRecipeRead(item)
		if bRead then
			szTip = szTip .. GetFormatText(g_tStrings.TIP_ALREADY_READ, 108)
		else
			szTip = szTip .. GetFormatText(g_tStrings.TIP_UNREAD, 105)
		end
	elseif item.nSub == ITEM_SUBTYPE_SKILL_RECIPE then
		szTip = szTip .. GetFormatText(g_tStrings.STR_SKILL_RECIPE .. "\n", 162)
		local bRead, bExpMystique = IsMystiqueSkillRead(item)
		if not bExpMystique then -- 不是熟练度秘籍
			if bRead then
				szTip = szTip .. GetFormatText(g_tStrings.TIP_LEARNED, 108)
			else
				szTip = szTip .. GetFormatText(g_tStrings.TIP_UNLEARNED, 105)
			end
		end
	end
	return szTip
end


----称号----------------------
local function GetTitleTip(player, itemInfo )
	local szTip = ""
	if itemInfo.nPrefix ~= 0 then
		local dwForceID = player and player.dwForceID or 0
		local aPrefix = Table_GetDesignationPrefixByID(itemInfo.nPrefix, dwForceID)
		if aPrefix then
			local szFinish = g_tStrings.DESGNATION_POSTFIX_UNGET
			if player.IsDesignationPrefixAcquired(itemInfo.nPrefix) then
				szFinish = g_tStrings.DESGNATION_POSTFIX_HAS_GET
			end

			local t = GetDesignationPrefixInfo(itemInfo.nPrefix)
			if t and t.nType == DESIGNATION_PREFIX_TYPE.WORLD_DESIGNATION then
				szTip = szTip..GetFormatText(FormatString(g_tStrings.USE_TO_GET_DESGNATION_WORLD, aPrefix.szName, szFinish), 105)
			elseif t and t.nType == DESIGNATION_PREFIX_TYPE.MILITARY_RANK_DESIGNATION then
				szTip = szTip..GetFormatText(FormatString(g_tStrings.USE_TO_GET_DESGNATION_MILITARY, aPrefix.szName, szFinish), 105)
			else
				szTip = szTip..GetFormatText(FormatString(g_tStrings.USE_TO_GET_DESGNATION_PREFIX, aPrefix.szName, szFinish), 105)
			end
		end
	end

	if itemInfo.nPostfix ~= 0 then
		local aPostfix = g_tTable.Designation_Postfix:Search(itemInfo.nPostfix)
		if aPostfix then
			local szFinish = g_tStrings.DESGNATION_POSTFIX_UNGET
			if player.IsDesignationPostfixAcquired(itemInfo.nPostfix) then
				szFinish = g_tStrings.DESGNATION_POSTFIX_HAS_GET
			end
			szTip = szTip..GetFormatText(FormatString(g_tStrings.USE_TO_GET_DESGNATION_POSTFIX, aPostfix.szName, szFinish), 105)
		end
	end
	return szTip
end

local function GetOtherTypeTip( player, item, bItem, szFromLootOrShop, nBookInfo )
	local itemInfo
	local szTip = ""

	if bItem then
		itemInfo = GetItemInfo(item.dwTabType, item.dwIndex)
	else
		itemInfo = item
	end

	if item.nGenre == ITEM_GENRE.POTION then
		--药品
		local szType = g_tStrings.POISON_TYPE[item.nSub] or g_tStrings.STR_COMMON_POISON
		szTip = szTip.."<Text>text="..EncodeComponentsString(szType.."\n").." font=106 </text>"

	elseif item.nGenre == ITEM_GENRE.FOOD then
		--食品
		local szType = g_tStrings.FOOD_TYPE[ item.nSub ] or g_tStrings.STR_COMMON_FOOD
		szTip = szTip.."<Text>text="..EncodeComponentsString(szType.."\n").." font=106 </text>"

	elseif item.nGenre == ITEM_GENRE.TASK_ITEM then
		--任务道具
	elseif item.nGenre == ITEM_GENRE.BOX then
		szTip = szTip.."<Text>text="..EncodeComponentsString(g_tStrings.ITEM_TREASURE_BOX.."\n").."font=106</text>"
		if item.nSub == BOX_SUB_TYPE.NEED_KEY then
			local itemInfokey = GetItemAdvanceBoxKeyInfo(itemInfo.dwBoxTemplateID);
			if itemInfokey then
				szTip = szTip.."<Text>text="..EncodeComponentsString(FormatString(g_tStrings.ITEM_TREASURE_BOX_NEED_KEY.."\n", GetItemNameByItemInfo(itemInfokey))).."font=106</text>"
			end
		end
	elseif item.nGenre == ITEM_GENRE.BOX_KEY then
		szTip = szTip.."<Text>text="..EncodeComponentsString(g_tStrings.ITEM_TREASURE_BOX_KEY.."\n").."font=106</text>"

	elseif item.nGenre == ITEM_GENRE.MATERIAL then
		  --材料
		if bItem then
			szTip = szTip .. GetMateralTip( item )
		end

	elseif item.nGenre == ITEM_GENRE.DESIGNATION then
	----称号----------------------
		szTip = szTip .. GetTitleTip( player, itemInfo )
	elseif item.nGenre == ITEM_GENRE.TOY then
		szTip = szTip .. "<Text>text="..EncodeComponentsString(g_tStrings.STR_TOY_TIP_NAME.."\n").." font=106 </text>"
	end
	return szTip
end

---修理费用，卖店费用-------------------------------
local function GetShopMoneyTip(item, nBoxIndex, nBoxItemIndex)
	local szTip = ""
	if Cursor.GetCurrentIndex() == CURSOR.REPAIRE or Cursor.GetCurrentIndex() == CURSOR.UNABLEREPAIRE then
		local nPrice = GetRepairItemPrice(nBoxIndex, nBoxItemIndex)
		if nPrice then
			szTip = szTip.."<text>text="..EncodeComponentsString(g_tStrings.STR_REPAIR_MONEY).." font=107 </text>"..
				GetMoneyTipText(nPrice, 106).."<text>text=\"\\\n\"</text>"
		end
	else
		if not item.bCanTrade then
			szTip = szTip.."<text>text="..EncodeComponentsString(g_tStrings.STR_SELL_CAN_NOT_SELL).."font=107 </text>"
		else
			local nPrice = GetShopSingleItemSellPrice(ShopPanel.GetShopID(), nBoxIndex, nBoxItemIndex)
			if nPrice then
				if item.bCanStack then
					nPrice = MoneyOptMult(nPrice, item.nStackNum)
				end

				szTip = szTip.."<text>text="..EncodeComponentsString(g_tStrings.STR_SELL_OUT_MONEY).." font=107 </text>"..
					GetMoneyTipText(nPrice, 106).."<text>text=\"\\\n\"</text>"
			end
		end
	end
	return szTip
end

----配方需求tip------------------------
local function GetRecipeRequireTip(player, dwCraftID, dwRecipeID)
	local recipe = GetRecipe(dwCraftID, dwRecipeID)
	if not recipe then
		return ""
	end

	local szTip = ""
	local profession 		= GetProfession(recipe.dwProfessionID);
	local bLearned	 		= player.IsRecipeLearned(dwCraftID, dwRecipeID)

	--local nMaxLevel		= player.GetProfessionMaxLevel(recipe.dwProfessionID)
	local nLevel			= player.GetProfessionLevel(recipe.dwProfessionID)
	local nAdjustLevel		= player.GetProfessionAdjustLevel(recipe.dwProfessionID) or 0
	--local nExp			= player.GetProfessionProficiency(recipe.dwProfessionID)

	local IsExpertised 		= player.IsProfessionExpertised(recipe.dwProfessionID)
	local nBranchID 		= player.GetProfessionBranch(recipe.dwProfessionID)

	if bLearned then
		szTip = szTip.."<Text>text="..EncodeComponentsString(g_tStrings.TIP_LEARNED1).."font=108</text>"
		if recipe.bNeedExpertise then
			szTip = szTip.." ".. "<Text>text="..EncodeComponentsString(g_tStrings.CRAFT_EXPERTISE).."font=108</text>"
		end
		szTip = szTip.."<Text>text="..EncodeComponentsString("\n").." </text>"
	else
		local nFont = 105
		if (nLevel + nAdjustLevel) < recipe.dwRequireProfessionLevel then
			nFont = 102
		end
		szTip = szTip.."<Text>text="..EncodeComponentsString(FormatString(g_tStrings.STR_MSG_NEED_CRAFT1, Table_GetProfessionName(recipe.dwProfessionID))).." font="..nFont.." </text>"
		if recipe.bNeedExpertise then
			nFont = 105
			if not IsExpertised then
				nFont = 102
			end
			szTip = szTip.." ".. "<Text>text="..EncodeComponentsString(g_tStrings.CRAFT_EXPERTISE).."font="..nFont.." </text>"
		end
		szTip = szTip.."<Text>text="..EncodeComponentsString("\n").. " </text>"

		if recipe.dwRequireBranchID ~= 0 then
			local nFont = 105
			if nBranchID ~= recipe.dwRequireBranchID then
				nFont = 102
			end
			szTip = szTip.."<Text>text="..EncodeComponentsString(FormatString(g_tStrings.STR_MSG_NEED_BRANCH, Table_GetBranchName(recipe.dwProfessionID, recipe.dwRequireBranchID))).." font="..nFont.." </text>"
		end
	end
	return szTip
end

----配方材料---------------------------
local function GetRecipeMerterailTip(player, dwCraftID, dwRecipeID)
	local recipe = GetRecipe(dwCraftID, dwRecipeID)
	if not recipe then
		return ""
	end

	local szTip = ""
	szTip = szTip.."<text>text=\"\\\n\"</text>"..GetItemInfoTip(0, recipe.dwCreateItemType1, recipe.dwCreateItemIndex1)

	local bFirst = true
	for nIndex = 1, 6, 1 do
		local nType  = recipe["dwRequireItemType"..nIndex]
		local nID	 = recipe["dwRequireItemIndex"..nIndex]
		local nNeed  = recipe["dwRequireItemCount"..nIndex]
		local szText = ""

		if nNeed > 0 then
			local szComma = g_tStrings.STR_COMMA
			if bFirst then
				szTip = szTip.."<Text>text="..EncodeComponentsString("\n"..g_tStrings.STR_CRAFT_TIP_RECIPE_REQUIRE).."font=163</text>"
				szComma = ""
				bFirst = false
			end

			local ItemInfo = GetItemInfo(nType, nID)
			local szItemName = GetItemNameByItemInfo(ItemInfo)
			local nCount   = player.GetItemAmount(nType, nID)
			local nFont = 163
			if nCount < nNeed then
				nFont = 102
			end
			szTip = szTip.."<Text>text="..EncodeComponentsString(szComma.. szItemName .."("..nNeed..")").." font="..nFont.." </text>"
		end
	end
	if not bFirst then
		szTip = szTip.."<Text>text="..EncodeComponentsString("\n").." font=105 </text>"
	end
	return szTip
end

function GetSourcePlayer(tSource)
    local pPlayer
    if tSource then
        local bCmp       = tSource.bCmp
        local bLink      = tSource.bLink
        local dwPlayerID = tSource.dwPlayerID
        if bLink then
            pPlayer = nil
        else
            if bCmp then
                pPlayer = GetClientPlayer()
            elseif dwPlayerID then
                pPlayer = GetPlayer(dwPlayerID)
            else
                pPlayer = GetClientPlayer()
            end
        end
    else
        pPlayer = GetClientPlayer()
    end
    return pPlayer
end

local function GetBquipScoreTip(item, bItem, tSource)
	local szTip = ""
    local tInfo = CastingPanel.GetStrength(item, bItem, tSource)
    local nEquipInv = CastingPanel.GetEquipInventory(item.nSub, item.nDetail)
    local pPlayer = GetSourcePlayer(tSource)
    local nBaseScore 		= item.nBaseScore
    local nStrengthScore 	= item.CalculateStrengthScore(tInfo.nTrueLevel, item.nLevel)
    local nStoneScore = 0
    if pPlayer then
        nStoneScore = item.CalculateMountsScore(pPlayer.GetEquipBoxAllMountDiamondEnchantID(nEquipInv))
    end
    if nBaseScore > 0 then
        szTip = szTip..GetFormatText(FormatString(g_tStrings.STR_ITEM_H_ITEM_SCORE, nBaseScore), 101)
        if nStrengthScore > 0 or nStoneScore > 0 then
            local szContent = g_tStrings.STR_EN_PREV_PANT..
                FormatString(g_tStrings.STR_ADD_VALUE, nStrengthScore) ..
                FormatString(g_tStrings.STR_ADD_VALUE, nStoneScore) .. g_tStrings.STR_EN_END_PANT
            szTip = szTip .. GetFormatText(" ".. szContent , 192)
        end
        szTip = szTip..GetFormatText("\n")
	end
	return szTip
end

------------------品质等级 装备分数-------------------
local function GetQualityInfoTip(item, bItem, tSource)
	if not IsItemCharacterEquip(item.nGenre) then
		return ""
	end

	local szTip = ""

	------------------品质等级-------------------
	szTip = szTip.."<text>text="..EncodeComponentsString(FormatString(g_tStrings.STR_ITEM_H_ITEM_LEVEL, item.nLevel)).." font=163 </text>"
    if IsItemCanBeEquip(item.nGenre, item.nSub) then
        local tInfo = CastingPanel.GetStrength(item, bItem, tSource)
        local nStrengthQuality = GetStrengthQualityLevel(item.nLevel, tInfo.nTrueLevel)
        if nStrengthQuality and nStrengthQuality > 0 then
            local szContent = g_tStrings.STR_EN_PREV_PANT..FormatString(g_tStrings.STR_ADD_VALUE, nStrengthQuality) .. g_tStrings.STR_EN_END_PANT
            szTip = szTip..GetFormatText(" "..szContent , 192)
        end
    end
	szTip = szTip..GetFormatText("\n")

    if bItem then
        local szCText = item.GetCustomText()
        if szCText and szCText ~= "" then
            szTip = szTip .. FormatString(g_tStrings.STR_SIGNATURE, szCText) .. GetFormatText("\n")
        end
    end
	------------------装备分数-------------------
    if IsItemCanBeEquip(item.nGenre, item.nSub) then
        szTip = szTip .. GetBquipScoreTip(item, bItem, tSource)
    end
	return szTip
end

----门派推荐，外观--------------------
local function GetEquipRecommendAndExteriorTip( itemInfo )
	if not IsItemCharacterEquip(itemInfo.nGenre) then
		return ""
	end

	local szTip = ""
	---门派推荐--------------------
	if itemInfo.nRecommendID and g_tTable.EquipRecommend then
		local t = g_tTable.EquipRecommend:Search(itemInfo.nRecommendID)
		if t and t.szDesc and t.szDesc ~= "" then
			szTip = szTip.."<text>text="..EncodeComponentsString(FormatString(g_tStrings.RECOMMEND_SCHOOL.."\n", t.szDesc)).." font=106 </text>"
		end
	end

	----外观--------------------
	if itemInfo.nCanExteriorSchool then
		local szExteriorName = ""
		local eGoodsType = nil
		local dwGoodsID = nil
		if itemInfo.nSub == EQUIPMENT_SUB.MELEE_WEAPON then
			local dwWeaponID = CoinShop_GetWeaponIDByItemInfo(itemInfo)
			eGoodsType = COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR
			dwGoodsID = dwWeaponID
		else
			local dwExteriorID = CoinShop_GetExteriorIDByItemInfo(itemInfo)
			eGoodsType = COIN_SHOP_GOODS_TYPE.EXTERIOR
			dwGoodsID = dwExteriorID
		end

		if eGoodsType and dwGoodsID and dwGoodsID > 0 then
			szExteriorName = CoinShop_GetGoodsName(eGoodsType, dwGoodsID)
		end

		if szExteriorName and szExteriorName ~= "" then
			local nHaveType = GetCoinShopClient().CheckAlreadyHave(eGoodsType, dwGoodsID)
			local bHave = nHaveType ~= COIN_SHOP_OWN_TYPE.NOT_HAVE
			local bCollect = CoinShop_GetCollectInfo(eGoodsType, dwGoodsID)
			local szText = FormatString(g_tStrings.ITEM_TIP_EXTERIOR_NAME, szExteriorName)
			szTip = szTip .. GetFormatText(szText, 106)
			local nStatus = GET_STATUS.NOT_COLLECTED
			local nFont = 108
			if bCollect or bHave then
				nStatus = GET_STATUS.COLLECTED
				nFont = 106
			end
			local szCollect = g_tStrings.tCoinshopGet[nStatus]
			szTip = szTip .. GetFormatText(FormatString(g_tStrings.STR_ITEM_TEMP_ECHANT_LEFT_TIME, szCollect) .. "\n", nFont)
		end
		local szDesc = Table_GetCanExteriorDesc(itemInfo.nCanExteriorSchool)
		if szDesc ~= "" then
			szTip = szTip..GetFormatText(FormatString(g_tStrings.RECOMMEND_EXTEROPR_SCHOOL.."\n", szDesc), 106)
		end
	end
	return szTip
end

local function _Tip_GetPlayerInfo( player, dwPlayerID)
	local dwSchoolID = player.dwBitOPSchoolID -- player.dwSchoolID
	if not dwPlayerID then
		dwPlayerID = player.dwID
	elseif dwPlayerID ~= player.dwID then
		local playerT = GetPlayer(dwPlayerID)
		dwSchoolID = nil
		if playerT then
			dwSchoolID = playerT.dwBitOPSchoolID	--playerT.dwSchoolID
		end
	end
	return dwPlayerID, dwSchoolID
end

local function GetBuyItemStartTime(aShopInfo)
	local nCurrentTime = GetCurrentTime()
	if aShopInfo and aShopInfo.nBeginSellTime and aShopInfo.nBeginSellTime > nCurrentTime then
		local szTip = FormatString(g_tStrings.SHOP_ITEM_WILL_SELL_AT, GetDateTextHour(aShopInfo.nBeginSellTime))
		return "<text>text=" .. EncodeComponentsString(szTip) .. " font=102 </text>"
	end
end

local tRequireArenaLevel ={ARENA_TYPE.ARENA_2V2, ARENA_TYPE.ARENA_3V3, ARENA_TYPE.ARENA_5V5}
local tRequireExcept2v2 ={ARENA_TYPE.ARENA_3V3, ARENA_TYPE.ARENA_5V5}

local function GetShopBuyInfoTip(aShopInfo)
	local FONT_SATISFY = 2
	local FONT_NOT_SATISFY = 102
	local szTip = ""
	if aShopInfo.dwNeedLevel > 3 then
		local tRepuForceInfo = Table_GetReputationForceInfo(aShopInfo.dwNeedForce)
		local tRepuLevelInfo = Table_GetReputationLevelInfo(aShopInfo.dwNeedLevel)
		if tRepuForceInfo and tRepuLevelInfo then
			local szText = FormatString(g_tStrings.STR_LEARN_NEED_REPUT_BUY, tRepuForceInfo.szName, tRepuLevelInfo.szName)
			local nFont = FONT_NOT_SATISFY
			if aShopInfo.bSatisfy then
				nFont = FONT_SATISFY
			end
			szTip = szTip.."<text>text="..EncodeComponentsString(szText).."font="..nFont.."</text>"
		end
	end

	if aShopInfo.nRequireAchievementRecord and aShopInfo.nRequireAchievementRecord > 0 then
		local szText = FormatString(g_tStrings.STR_NEED_ACHIVEMENT_RECORD_BUY, aShopInfo.nRequireAchievementRecord)
		local nFont = FONT_NOT_SATISFY
		if aShopInfo.bSatisfyAchievementRecord then
			nFont = FONT_SATISFY
		end
		szTip = szTip.."<text>text="..EncodeComponentsString(szText).."font="..nFont.."</text>"
	end

	if aShopInfo.bLimit then --全服限量
		if aShopInfo.bCustomLimit then
			local szLimit = FormatString(g_tStrings.SHOP_ITEM_GLOBAL_CUSTOM_LIMT, aShopInfo.nGobalLimitCount)
			szTip = szTip.. GetFormatText("\n") .. GetFormatText(szLimit, FONT_SATISFY)
		else
			local szLimit = FormatString(g_tStrings.SHOP_ITEM_GLOBAL_LIMT, aShopInfo.nBuyCount, aShopInfo.nGlobalLimt)
			szTip = szTip.. GetFormatText("\n") .. GetFormatText(szLimit, FONT_SATISFY)
		end
	end

	if aShopInfo.nPlayerBuyCount >= 0 then --个人限量
		local szLimit = FormatString(g_tStrings.SHOP_ITEM_PLAYER_LIMT, aShopInfo.nPlayerBuyCount, aShopInfo.nPlayerLimit)
		szTip = szTip.. GetFormatText("\n") .. GetFormatText(szLimit, FONT_SATISFY)
	end

	if aShopInfo.nCampTitle and aShopInfo.nCampTitle > 0 then
		local szTitleLevel = FormatString(g_tStrings.STR_CAMP_TITLE_LEVEL, g_tStrings.STR_CAMP_TITLE_NUMBER[aShopInfo.nCampTitle])
		local szText = FormatString(g_tStrings.STR_NEED_CAMP_TITLE_BUY, szTitleLevel)
		local nFont = FONT_NOT_SATISFY
        if aShopInfo.bShareCampTitle then
            szText = FormatString(g_tStrings.STR_SHARE_CAMP_TITLE_BUY, szTitleLevel)
            nFont = 198
		elseif aShopInfo.bSatisfyCampTitle then
			nFont = FONT_SATISFY
		end
		szTip = szTip.."<text>text="..EncodeComponentsString(szText).."font="..nFont.."</text>"
	end

	if aShopInfo.nRequireCorpsValue and aShopInfo.nRequireCorpsValue > 0 then
		local dwMask = aShopInfo.dwMaskCorpsNeedToCheck % (2 ^ ARENA_TYPE.ARENA_END)
		local szCorpsText = nil
		for i = ARENA_TYPE.ARENA_END - 1, ARENA_TYPE.ARENA_BEGIN, -1 do
			if dwMask >= 2 ^ i then
				if szCorpsText then
					szCorpsText = g_tStrings.tCorpsType[i] .. g_tStrings.TIP_COMMAND_OR .. szCorpsText
				else
					szCorpsText = g_tStrings.tCorpsType[i]
				end

				dwMask = dwMask - 2 ^ i;
			end
		end

		local szText = FormatString(g_tStrings.STR_NEED_COPRS_VALUE_BUY, szCorpsText, aShopInfo.nRequireCorpsValue)
		local nFont = FONT_NOT_SATISFY
		if aShopInfo.bSatisfyCorpsValue then
			nFont = FONT_SATISFY
		end
		szTip = szTip.."<text>text="..EncodeComponentsString(szText).."font="..nFont.."</text>"
	end

	if aShopInfo.nRequireArenaLevel and aShopInfo.nRequireArenaLevel > 0 then
		local szCorpsText = nil
		for i = #tRequireArenaLevel, 1, -1 do
			local nType = tRequireArenaLevel[i]
			if szCorpsText then
				szCorpsText = g_tStrings.tCorpsType[nType] .. g_tStrings.TIP_COMMAND_OR .. szCorpsText
			else
				szCorpsText = g_tStrings.tCorpsType[nType]
			end
		end

		local szText = FormatString(g_tStrings.STR_NEED_ARENA_LEVEL_BUY, szCorpsText, aShopInfo.nRequireArenaLevel)
		local nFont = FONT_NOT_SATISFY
		if aShopInfo.bSatisfyArenaLevel then
			nFont = FONT_SATISFY
		end
		szTip = szTip.."<text>text="..EncodeComponentsString(szText).."font="..nFont.."</text>"
	end

	if aShopInfo.nRequireArenaLevelExcept2v2 and aShopInfo.nRequireArenaLevelExcept2v2 > 0 then
		local szCorpsText = nil
		for i = #tRequireExcept2v2, 1, -1 do
			local nType = tRequireExcept2v2[i]
			if szCorpsText then
				szCorpsText = g_tStrings.tCorpsType[i] .. g_tStrings.TIP_COMMAND_OR .. szCorpsText
			else
				szCorpsText = g_tStrings.tCorpsType[i]
			end
		end

		local szText = FormatString(g_tStrings.STR_NEED_ARENA_LEVEL_BUY, szCorpsText, aShopInfo.nRequireArenaLevelExcept2v2)
		local nFont = FONT_NOT_SATISFY
		if aShopInfo.bSatisfyArenaLevelE2v2 then
			nFont = FONT_SATISFY
		end
		szTip = szTip.."<text>text="..EncodeComponentsString(szText).."font="..nFont.."</text>"
	end

	if aShopInfo.bNeedFame then
		local szText = FormatString(g_tStrings.STR_SHOP_NEED_FAME, aShopInfo.nFameNeedLevel)
		local nFont = FONT_NOT_SATISFY
		if aShopInfo.bFameSatisfy then
			nFont = FONT_SATISFY
		end
		szTip = szTip .. GetFormatText(szText, nFont)
	end

	return szTip
end

local function GetShopShared(item)
	local szTip = ""
	if item.bCanShared then
		if item.nGenre == ITEM_GENRE.EQUIPMENT then
			szTip = GetFormatText(g_tStrings.STR_EQUIP_SHARE, 198)
		else
			szTip = GetFormatText(g_tStrings.STR_ITEM_SHARE, 198)
		end
	end
	return szTip
end

-------装备分解，洗练--------
local function GetEquipBreakAndChangeTip(player, item, itemInfo)
	local szTip = ""
	local dwBox, dwX = player.GetItemPos(item.dwID)
	if item and itemInfo and item.nGenre == ITEM_GENRE.EQUIPMENT and item.nSub ~= EQUIPMENT_SUB.PACKAGE and item.nSub ~= EQUIPMENT_SUB.HORSE
	and (not itemInfo.bCanBreak or not itemInfo.bCanTrade ) then
		szTip = szTip .. "<text>text=" .. UIHelper.EncodeComponentsString( g_tStrings.STR_ITEM_H_CAN_NOT_BREAK ) .. " font=102 </text>"
	end
	return szTip
end

local function GetItemInfoBuyIndexTip(itemInfo, dwPlayerID)
	local szText = ""
	if not dwPlayerID then
		return szText
	end

	local hPlayer = GetPlayer(dwPlayerID)
	local nBuyIndex = 0
	if itemInfo.nGenre == ITEM_GENRE.EQUIPMENT and IsPendantPetItem(itemInfo) then
		nBuyIndex = hPlayer.GetPendentPetBuyIndex(itemInfo.dwID)
	elseif itemInfo.nGenre == ITEM_GENRE.EQUIPMENT and IsPendantItem(itemInfo) then
		nBuyIndex = hPlayer.GetPendentBuyIndex(itemInfo.dwID)
	end

	szText = GetBuyIndexTip(nBuyIndex)

	return szText
end

function GetFurnitureItemInfoTip(dwGoodID, nTabType, nIndex, szFromLootOrShop, aShopInfo, nBookInfo, dwPlayerID, bHaveCmp)
	local itemInfo = GetItemInfo(nTabType, nIndex)
	local pHlMgr = GetHomelandMgr()
	if not itemInfo then
		Log("[UI ItemTip] error get GetFurnitureItemInfoTip failed when OutputItemTipByInfo!\n")
		return ""
	end
	local nFurnitureType, dwFurnitureID, dwModelID
	if itemInfo then
		nFurnitureType = itemInfo.nFurnitureType or HS_FURNITURE_TYPE.FURNITURE
		dwFurnitureID = itemInfo.dwFurnitureID
		if not itemInfo then
			Log("[UI ItemTip] error get itemInfo failed when GetFurnitureItemTip!\n")
			return ""
		end
		if not dwFurnitureID then
			Log("[UI ItemTip] error get dwFurnitureID failed when GetFurnitureItemTip!\n")
			return ""
		end
	end

	local tFurnitureConfig
	if nFurnitureType == HS_FURNITURE_TYPE.FURNITURE then
		tFurnitureConfig = pHlMgr.GetFurnitureConfig(dwFurnitureID)
	elseif nFurnitureType == HS_FURNITURE_TYPE.PENDANT then
		tFurnitureConfig = pHlMgr.GetPendantConfig(dwFurnitureID)
	elseif nFurnitureType == HS_FURNITURE_TYPE.APPLIQUE_BRUSH then
		tFurnitureConfig = pHlMgr.GetAppliqueBrushConfig(dwFurnitureID)
	elseif nFurnitureType == HS_FURNITURE_TYPE.FOLIAGE_BRUSH then
		tFurnitureConfig = pHlMgr.GetFoliageBrushConfig(dwFurnitureID)
	end

	local szTip = ""
	local tUIInfo = FurnitureData.GetFurnInfoByTypeAndID(nFurnitureType, dwFurnitureID)
	-----------名字 加 拥有状态 -------------------
	local nQuality, szName
	dwModelID = tUIInfo.dwModelID
	if itemInfo then
		nQuality = itemInfo.nQuality
		szName = GetItemNameByItemInfo(itemInfo)
	else
		nQuality = tUIInfo.nQuality
		szName = tUIInfo and tUIInfo.szName or "???"
	end
	local r, g, b = GetPetFontColorByQuality(nQuality)
	szTip = GetFormatText(szName, 18, r, g, b)

	local dwSetID = tFurnitureConfig.nSetID
	local dwSetIndex = tFurnitureConfig.nSetIndex
	if nFurnitureType == HS_FURNITURE_TYPE.FURNITURE then
		local bCollected = HomelandEventHandler.IsFurnitureCollected(dwFurnitureID)
		local szCollected, nFont
		if bCollected then
			szCollected = g_tStrings.STR_FURNITURE_TIP_OWN_STATE_COLLECTED
			nFont = 106
		elseif bCollected == false then
			szCollected = g_tStrings.STR_FURNITURE_TIP_OWN_STATE_NOT_COLLECTED
			nFont = 108
		end
		if szCollected then
			szTip = szTip .. GetFormatText("\t" .. szCollected .. "\n", nFont)
		else
			szTip = szTip .. GetFormatText("\n", 18)
		end
	else
		szTip = szTip .. GetFormatText("\n", 18)
	end

	-----------图标和家具字样 -------------------
	szTip = szTip .. "<image>w=16 h=16 path=\"ui/Image/UICommon/CommonPanel8.UITex\" frame=44 </image>"
			.. GetFormatText(g_tStrings.STR_FURNITURE_TIP_NAME, 163, 154, 200, 204)
	local tCatg1UIInfo = FurnitureData.GetCatg1Info(tUIInfo.nCatg1Index)
	local tCatg2UIInfo = FurnitureData.GetCatg2Info(tUIInfo.nCatg1Index, tUIInfo.nCatg2Index)
	szTip = szTip .. GetFormatText("-" .. tCatg1UIInfo.szName .. "-" .. tCatg2UIInfo.szName, 163, 154, 200, 204)
	szTip = szTip .. GetFormatText("\n")

	-----------绑定信息----------------
	szTip = szTip .. GetItemInfoBindTip(itemInfo)

	if bRefresh then -- ??
		bNeedRefresh = bRefresh
	end

	-----------唯一性------------------
	szTip = szTip .. GetItemExistAmountTip(itemInfo)

	---------存在类型----------------
	szTip = szTip .. GetItemExitTypeTip(itemInfo)

	-- ------需求信息----------
	-- --if item.dwTabType == ITEM_TABLE_TYPE.OTHER then --？
	-- 	szTip = szTip..GetOtherItemInfoTip(itemInfo, player, dwIndex)
	-- --end

	---------观赏、实用 那些属性----------------
	local tFrame = {27, 30, 28, 26, 29}
	for i = 1, 5 do
		local nValue = tFurnitureConfig["dwAttribute" .. i]
		if nValue and nValue > 0 then
			szTip = szTip ..  "<image>w=20 h=20 path=" .. EncodeComponentsString("ui\\Image\\HomelandBuilding\\HomelandBuilding01.UITex") .. " frame=" .. tFrame[i] .. " </image>" ..
					GetFormatText(FormatString(g_tStrings.STR_FURNITURE_TIP_SCORE[i], nValue), 105)
		end
	end

	---------需求家园等级---------
	szTip = szTip .. GetFormatText(FormatString(g_tStrings.STR_FURNITURE_TIP_ILLUSTRATE0, tFurnitureConfig.nLevelLimit))

	---------风格----------------
	local dwLabelMask = tFurnitureConfig.dwLabelMask
	if dwLabelMask then
		local szFurnitureStyleImagePath, tFurnitureStyleImageFrame, nMaxStyleNum = Homeland_GetFurnitureLabelImageFrame()
		for _, t in ipairs(Homeland_GetFurnitureLabelMask()) do
			local nLabel = t[1]
			if kmath.bit_and(dwLabelMask, nLabel) > 0 then
				szTip = szTip .. "<image>w=20 h=16 path=" .. EncodeComponentsString(szFurnitureStyleImagePath) ..
						" frame=" .. tFurnitureStyleImageFrame[nLabel] .. " </image>"
				szTip = szTip.."<null> w=30 h=1 </null>"
			end
		end
	end

	--[[
	if item then
		szTip = szTip .. GetFormatText(g_tStrings.STR_FURNITURE_TIP_ILLUSTRATE1, 105)
		-- szTip = szTip ..  GetFormatText(g_tStrings.STR_FURNITURE_TIP_ILLUSTRATE2, font=105)
	end
	--]]

	------------------家具图片信息-------------------
	local dwUIFurnitureID = GetHomelandMgr().MakeFurnitureUIID(nFurnitureType, dwFurnitureID)
	local tItemAddInfo = Table_GetFurnitureAddInfo(dwUIFurnitureID)

	if tItemAddInfo.nFrame then
		szTip = szTip .. "<image>w=200 h=200 path=" .. EncodeComponentsString(tItemAddInfo.szPath) .. " frame=" .. tItemAddInfo.nFrame .. " </image>"
	else
		szTip = szTip .. "<image>w=200 h=200 path=" .. EncodeComponentsString(tItemAddInfo.szPath) ..  " </image>"
	end

	szTip = szTip ..  GetFormatText( "\n" .. tItemAddInfo.szTip .. "\n", 100)

	------------------品质等级-------------------
	szTip = szTip .. GetFormatText(FormatString(g_tStrings.STR_FURNITURE_TIP_H_LEVEL, tFurnitureConfig.nQualityLevel), 163)

	---------家具套装信息---------
	local dwSetID = tFurnitureConfig.nSetID
	if dwSetID > 0 then
		local tSetInfo = Table_GetFurnitureSetInfoByID(dwSetID)
		if tSetInfo then
			szTip = szTip .. GetFormatText(g_tStrings.STR_HOMELAND_FURNITURE_SET_PREFIX_IN_TIP .. tSetInfo.szName ..
					g_tStrings.STR_ONE_CHINESE_SPACE, 163)
			for k = 1, tSetInfo.nStars do
				szTip = szTip .. "<image>w=20 h=20 path=" .. EncodeComponentsString("ui\\Image\\UITga\\FurnitureCollection.UITex") .. " frame=21</image>"
			end
			szTip = szTip .. GetFormatText("\n")
		end
	end

	------------------可染色-------------------
	 if FurnitureData.FurnCanDye(dwModelID) then
	 	szTip = szTip .. "<image> w=20 h=20 path=" .. EncodeComponentsString("ui\\Image\\HomelandBuilding\\HomelandBuilding03.UITex") .. " frame=52 </image>" ..
	 			GetFormatText(g_tStrings.STR_FURNITURE_TIP_ILLUSTRATE5 .. "\n")
	 end
	------------------可交互-------------------
	if tUIInfo and tUIInfo.bInteract then
		szTip = szTip .. "<image> w=20 h=20 path=" .. EncodeComponentsString("ui\\Image\\HomelandBuilding\\HomelandBuilding03.UITex") .. " frame=51 </image>" ..
				"<Text> text=" .. EncodeComponentsString(g_tStrings.STR_FURNITURE_TIP_ILLUSTRATE6 .. "\n" ) .. "</text>"
	end

	------------------物品来源-------------------
	szTip = szTip ..  GetFormatText(FormatString(g_tStrings.STR_FURNITURE_TIP_ILLUSTRATE4, tItemAddInfo.szSource))

	------------------最多摆放-------------------
	if nFurnitureType <= HS_FURNITURE_TYPE.PENDANT then
		szTip = szTip .. GetFormatText(FormatString(g_tStrings.STR_FURNITURE_TIP_ILLUSTRATE7, tFurnitureConfig.nMaxAmountPerLand or 1))
	end

	------------------价格------------------
	local nArchitecture = tFurnitureConfig.nArchitecture
	if nArchitecture and nArchitecture > 0 then --> 挂件家具没有资源点字段
		szTip = szTip .. GetFormatText(FormatString(g_tStrings.STR_FURNITURE_TIP_UNIT_PRICE, nArchitecture)) ..
				"<image>w=20 h=20 path=" .. EncodeComponentsString("ui/Image/Common/Money.UITex") .. " frame=44 </image>"
	end

	szTip = szTip .. GetFormatText("\n") .. GetRewardsTip(nTabType, nIndex)

	if nFurnitureType == HS_FURNITURE_TYPE.FURNITURE and FurnitureBuy.IsSpecialFurnitrueCanBuy(dwFurnitureID) then
		szTip = szTip .. GetFormatText(g_tStrings.STR_FURNITURE_TIP_SPECIAL_CANBUY_AFTER_COLLECTED)
	elseif nFurnitureType == HS_FURNITURE_TYPE.FURNITURE and FurnitureBuy.IsSpecialFurnitrueCanBuyNotHave(dwFurnitureID) then
		szTip = szTip .. GetFormatText(g_tStrings.STR_FURNITURE_TIP_SPECIAL_CANBUY_NEED_COLLECTED)
	end

	--以下为测试代码
	if IsCtrlKeyDown() and not IsShiftKeyDown() and not IsAltKeyDown() then
		szTip = szTip..GetFormatText("\n"..g_tStrings.DEBUG_INFO_ITEM_TIP.."\n".."ID: "..nTabType..", "..nIndex.."\n".."ItemLevel: "..itemInfo.nLevel.."\n".."UIID: "..itemInfo.nUiId.."\n".."setid: "..itemInfo.nSetID.."\n", 102)
		szTip = szTip..GetFormatText("IconID:"..Table_GetItemIconID(itemInfo.nUiId), 102)
		szTip = szTip..GetFormatText("\nnFurnitureType:" .. nFurnitureType, 102)
		szTip = szTip..GetFormatText("\ndwFurnitureID:" .. dwFurnitureID, 102)
		if dwModelID then
			szTip = szTip..GetFormatText("\ndwModelID:" .. dwModelID, 102)
		end
		szTip = szTip .. GetFormatText("\ndwUIFurnitureID:" .. dwUIFurnitureID, 102)
		if dwSetID then
			szTip = szTip..GetFormatText("\ndwSetID:" .. dwSetID, 102)
		end
		if dwSetIndex then
			szTip = szTip..GetFormatText("\ndwSetIndex:" .. dwSetIndex, 102)
		end
	end

	return szTip, itemInfo, bNeedRefresh
end

function GetItemInfoTip(dwGoodID, nTabType, nIndex, szFromLootOrShop, aShopInfo, nBookInfo, dwPlayerID, bHaveCmp, bLink)
	local itemInfo = GetItemInfo(nTabType, nIndex)
	if not itemInfo then
		Log("[UI ItemTip] error get itemInfo failed when OutputItemTipByInfo!\n")
		return ""
	end

	local player = GetClientPlayer()
	local dwSchoolID = 0
	local bNeedRefresh = false
	dwPlayerID, dwSchoolID = _Tip_GetPlayerInfo( player, dwPlayerID )
    local tSource = {dwPlayerID = dwPlayerID, bLink = bLink}

	if nTabType == ITEM_TABLE_TYPE.HOMELAND then
		return GetFurnitureItemInfoTip(dwGoodID, nTabType, nIndex, szFromLootOrShop, aShopInfo, nBookInfo, dwPlayerID, bHaveCmp)
	end

	local szTip = ""

	-----------名字 强化等级-------------------
	szTip = szTip ..  GetItemNameAndStrengthTip( itemInfo, nBookInfo, false, nIndex, tSource)

	-----------绑定信息----------------
	szTip = szTip .. GetItemInfoBindTip( itemInfo )

	-----------唯一性------------------
	szTip = szTip .. GetItemExistAmountTip(itemInfo)

	---------存在类型----------------
	szTip = szTip .. GetItemExitTypeTip( itemInfo )

	--------输出物品的提示-----------------
	if nTabType == ITEM_TABLE_TYPE.OTHER then
		szTip = szTip .. GetOtherItemInfoTip(itemInfo, player, nIndex)
	end

	if IsItemCharacterEquip(itemInfo.nGenre) then
		-----------装备类型 基本属性 魔法属性 五行石 孔属性 五彩石属性 需求属性 耐久度-------------
		szTip = szTip .. GetEquipItemInfoTip(itemInfo, player, nIndex, tSource)

		----------套装属性-------------------
		if itemInfo.nSetID and itemInfo.nSetID > 0 then
			local szSetAttriTip = GetSetAttriTip(itemInfo.nSetID, dwPlayerID, dwSchoolID, true)
			if szSetAttriTip then
				szTip = szTip .. szSetAttriTip
			end
		end
	elseif itemInfo.nGenre == ITEM_GENRE.BOOK then
		--书籍
		local nBookID, nSegID = GlobelRecipeID2BookID(nBookInfo)
		szTip = GetBookTipByItemInfo(itemInfo, nBookID, nSegID, true)
	else
		szTip = szTip .. GetOtherTypeTip(player, itemInfo, false, szFromLootOrShop, nBookInfo )
	end

	if nTabType == ITEM_TABLE_TYPE.OTHER and g_LearnInfo[nIndex] then
		----配方需求tip------------------------
		szTip = szTip .. GetRecipeRequireTip(player, g_LearnInfo[nIndex].dwCraftID, g_LearnInfo[nIndex].dwRecipeID)
	end

	----道具示意图-------------------------------------
	local szImg = "\\ui\\image\\item_pic\\"..itemInfo.nUiId..".UITex"
	if IsFileExist(szImg) then
		szTip = szTip.."<image>path="..EncodeComponentsString(szImg).." frame=0 </image><text>text=\"\\\n\"</text>"
	end

	----成长道具示意图-------------------------------------
	szTip = szTip .. GetGrowthEquitInfoTip(nil, nTabType, nIndex, itemInfo, dwPlayerID)

	----小头像示意图-------------------------------------
	if itemInfo.nGenre == ITEM_GENRE.EQUIPMENT and itemInfo.nSub == EQUIPMENT_SUB.MINI_AVATAR then
		local dwAvatarID = itemInfo.nRepresentID
		szTip = szTip .. GetAvatarImageTip(dwAvatarID).."<text>text=\"\\\n\"</text>"
	end

	local szItemDesc = GetItemDesc(itemInfo.nUiId)
	if szItemDesc and szItemDesc ~= "" then
		szTip = szTip..szItemDesc.."<text>text=\"\\\n\"</text>"
	end

	if nTabType == ITEM_TABLE_TYPE.OTHER and g_LearnInfo[nIndex] then
		----配方材料---------------------------
		szTip = szTip .. GetRecipeMerterailTip(player, g_LearnInfo[nIndex].dwCraftID, g_LearnInfo[nIndex].dwRecipeID)
	end

	if IsItemCharacterEquip(itemInfo.nGenre) then
		------------------品质等级 装备分数-------------------
		szTip = szTip .. GetQualityInfoTip(itemInfo, false, tSource)
	end

	if itemInfo.nGenre == ITEM_GENRE.EQUIPMENT then
		----门派推荐，外观--------------------
		szTip = szTip .. GetEquipRecommendAndExteriorTip( itemInfo )
	end

	----道具使用间隔
	local nRestTime = GetItemCoolDown(itemInfo.dwSkillID, itemInfo.dwSkillLevel, itemInfo.dwCoolDownID);
	if nRestTime and nRestTime ~= 0 and nRestTime ~= 16 then
		szTip = szTip .. GetFormatText(FormatString(g_tStrings.STR_ITEM_USE_TIME, GetTimeText(nRestTime, true)), 106)
	end
	if dwGoodID and dwGoodID > 0 then
		local szFreeTryonTip = GetFreeTryonTip(COIN_SHOP_GOODS_TYPE.ITEM, dwGoodID)
		if szFreeTryonTip ~= "" then
			szTip = szTip .. GetFormatText("\n") .. szFreeTryonTip
		end
	end

	-- local szCmpTip = GetEquipCmpTip(itemInfo, false, bHaveCmp)
	-- if szCmpTip then
	-- 	szTip = szTip .. szCmpTip .. GetFormatText("\n")
	-- end

	szTip = szTip .. GetItemInfoBuyIndexTip(itemInfo, dwPlayerID)

	szTip = szTip .. GetRewardsTip(nTabType, nIndex)

	--以下为测试代码
	if IsCtrlKeyDown() and not IsShiftKeyDown() and not IsAltKeyDown() then
		szTip = szTip..GetFormatText("\n"..g_tStrings.DEBUG_INFO_ITEM_TIP.."\n".."ID: "..nTabType..", "..nIndex.."\n".."ItemLevel: "..itemInfo.nLevel.."\n".."UIID: "..itemInfo.nUiId.."\n".."setid: "..itemInfo.nSetID.."\n", 102)
		szTip = szTip..GetFormatText("IconID:"..Table_GetItemIconID(itemInfo.nUiId), 102)
		szTip = szTip .. GetFormatText("\n" .. "nGenre:" .. itemInfo.nGenre .. "\n" .. "nSub:" .. itemInfo.nSub .. "\n" .. "nDetail:" .. itemInfo.nDetail, 102)
	end

	return szTip, itemInfo, bNeedRefresh
end

-- tFurnitureData: {nType=HS_FURNITURE_TYPE.FURNITURE/PENDANT, dwID=dwID, nLandLevel=nLandLevel, bFromBuilding=true/false}
function GetFurnitureItemTip(item, nBoxIndex, nBoxItemIndex, tFurnitureData, player, szFromLootOrShop, aShopInfo, bCmp, dwPlayerID, bHaveCmp)
	--local bNeedRefresh = false 考虑传进来
	local pHlMgr = GetHomelandMgr()
	local itemInfo, nFurnitureType, dwFurnitureID, dwModelID
	local nLandLevel = tFurnitureData and tFurnitureData.nLandLevel
	local bFromBuilding = tFurnitureData and tFurnitureData.bFromBuilding
	if item then
		itemInfo = GetItemInfo(item.dwTabType, item.dwIndex)
		nFurnitureType = itemInfo.nFurnitureType or HS_FURNITURE_TYPE.FURNITURE
		dwFurnitureID = item.dwFurnitureID
		if not itemInfo then
			Log("[UI ItemTip] error get itemInfo failed when GetFurnitureItemTip!\n")
			return ""
		end
		if not dwFurnitureID then
			Log("[UI ItemTip] error get dwFurnitureID failed when GetFurnitureItemTip!\n")
			return ""
		end
	else
		nFurnitureType, dwFurnitureID = tFurnitureData.nType, tFurnitureData.dwID
	end

	local tFurnitureConfig
	if nFurnitureType == HS_FURNITURE_TYPE.FURNITURE then
		tFurnitureConfig = pHlMgr.GetFurnitureConfig(dwFurnitureID)
	elseif nFurnitureType == HS_FURNITURE_TYPE.PENDANT then
		tFurnitureConfig = pHlMgr.GetPendantConfig(dwFurnitureID)
	elseif nFurnitureType == HS_FURNITURE_TYPE.APPLIQUE_BRUSH then
		tFurnitureConfig = pHlMgr.GetAppliqueBrushConfig(dwFurnitureID)
	elseif nFurnitureType == HS_FURNITURE_TYPE.FOLIAGE_BRUSH then
		tFurnitureConfig = pHlMgr.GetFoliageBrushConfig(dwFurnitureID)
	end

	local szTip = ""
	local tUIInfo = FurnitureData.GetFurnInfoByTypeAndID(nFurnitureType, dwFurnitureID)
	-----------名字 加 拥有状态 -------------------
	local nQuality, szName
	dwModelID = tUIInfo.dwModelID
	if item then
		nQuality = item.nQuality
		szName = GetItemNameByItemInfo(itemInfo)
	else
		szName = tUIInfo and tUIInfo.szName or "???"
		nQuality = tUIInfo and tUIInfo.nQuality or 1
	end
	local r, g, b = GetPetFontColorByQuality(nQuality)
	szTip = GetFormatText(szName, 18, r, g, b)

	if nFurnitureType == HS_FURNITURE_TYPE.FURNITURE then
		local bCollected = HomelandEventHandler.IsFurnitureCollected(dwFurnitureID)
		local szCollected, nFont
		if bCollected then
			szCollected = g_tStrings.STR_FURNITURE_TIP_OWN_STATE_COLLECTED
			nFont = 106
		elseif bCollected == false then
			szCollected = g_tStrings.STR_FURNITURE_TIP_OWN_STATE_NOT_COLLECTED
			nFont = 108
		end
		if szCollected then
			szTip = szTip .. GetFormatText("\t" .. szCollected .. "\n", nFont)
		else
			szTip = szTip .. GetFormatText("\n", 18)
		end
	else
		szTip = szTip .. GetFormatText("\n", 18)
	end

	-----------图标和家具字样 -------------------
	szTip = szTip .. "<image>w=16 h=16 path=\"ui/Image/UICommon/CommonPanel8.UITex\" frame=44 </image>"
			.. "<Text>text=" .. EncodeComponentsString(g_tStrings.STR_FURNITURE_TIP_NAME) .. " font=163 r=154 g=200 b=204 </text>"

			local tCatg1UIInfo = FurnitureData.GetCatg1Info(tUIInfo.nCatg1Index)
			local tCatg2UIInfo = FurnitureData.GetCatg2Info(tUIInfo.nCatg1Index, tUIInfo.nCatg2Index)
	szTip = szTip .. GetFormatText("-" .. tCatg1UIInfo.szName .. "-" .. tCatg2UIInfo.szName, 163, 154, 200, 204)
	szTip = szTip .. GetFormatText("\n")

	-----------绑定属性----------------
	if item then
		player = player or GetClientPlayer()
		local szText, bRefresh = GetItemBindTip(item, player, szFromLootOrShop)
		szTip = szTip .. szText
	end

	if bRefresh then -- ??
		bNeedRefresh = bRefresh
	end
	-----------唯一性------------------
	if item then
		szTip = szTip .. GetItemExistAmountTip(itemInfo)
	end

	---------存在类型----------------
	if item then
		szTip = szTip .. GetItemExitTypeTip(itemInfo, item.GetLeftExistTime())
	end

	------需求信息----------
	if item then
		szTip = szTip .. GetOtherItemInfoTip(itemInfo, player, item.dwIndex)
	end

	---------观赏、实用 那些属性----------------
	local tFrame = {27, 30, 28, 26, 29}
	for i = 1, 5 do
		local nValue = tFurnitureConfig["dwAttribute" .. i]
		if nValue and nValue > 0 then
			szTip = szTip ..  "<image>w=20 h=20 path=" .. EncodeComponentsString("ui\\Image\\HomelandBuilding\\HomelandBuilding01.UITex") .. " frame=" .. tFrame[i] .. " </image>" ..
					GetFormatText(FormatString(g_tStrings.STR_FURNITURE_TIP_SCORE[i], nValue), 105)
		end
	end

	---------评审分--------------
	if bFromBuilding and nFurnitureType == HS_FURNITURE_TYPE.FURNITURE then
		local nDecorateScore = pHlMgr.GetFurnitureRankDecorate(dwFurnitureID)
		if nDecorateScore > 0 then
			szTip = szTip .. GetFormatText(FormatString(g_tStrings.STR_FURNITURE_TIP_DECORATE_SCORE, nDecorateScore))
		end
	end

	---------需求家园等级---------
	local bLockedForLevel = false
	local nRequiredLevel = tFurnitureConfig.nLevelLimit
	if nRequiredLevel > 0 then
		local nFont = 18
		if nLandLevel and nLandLevel < nRequiredLevel then
			nFont = 102
			bLockedForLevel = true
		end
		szTip = szTip .. GetFormatText(FormatString(g_tStrings.STR_FURNITURE_TIP_ILLUSTRATE0, nRequiredLevel), nFont)
	end

	---修理费用，卖店费用-------------------------------
	if nBoxIndex and nBoxItemIndex and IsShopOpened() then
		szTip = szTip .. GetShopMoneyTip(item, nBoxIndex, nBoxItemIndex)
	end

	---------风格----------------
	local dwLabelMask = tFurnitureConfig.dwLabelMask
	if dwLabelMask then
		local szFurnitureStyleImagePath, tFurnitureStyleImageFrame, nMaxStyleNum = Homeland_GetFurnitureLabelImageFrame()
		for _, t in ipairs(Homeland_GetFurnitureLabelMask()) do
			local nLabel = t[1]
			if kmath.bit_and(dwLabelMask, nLabel) > 0 then
				szTip = szTip .. "<image>w=20 h=16 path=" .. EncodeComponentsString(szFurnitureStyleImagePath) ..
						" frame=" .. tFurnitureStyleImageFrame[nLabel] .. " </image>"
				szTip = szTip.."<null> w=30 h=1 </null>"
			end
		end
	end

	if item then
		szTip = szTip .. GetFormatText(g_tStrings.STR_FURNITURE_TIP_ILLUSTRATE1, 105)
		-- szTip = szTip ..  "GetFormatText(g_tStrings.STR_FURNITURE_TIP_ILLUSTRATE2, 105)
	end

	------------------家具图片信息-------------------
	local dwUIFurnitureID = pHlMgr.MakeFurnitureUIID(nFurnitureType, dwFurnitureID)
	local tItemAddInfo = Table_GetFurnitureAddInfo(dwUIFurnitureID)

	if item then
		if tItemAddInfo.nFrame and tItemAddInfo.nFrame ~= -1 then
			szTip = szTip .. "<image>w=200 h=200 path=" .. EncodeComponentsString(tItemAddInfo.szPath) .. " frame=" .. tItemAddInfo.nFrame .. " </image>"
		else
			szTip = szTip .. "<image>w=200 h=200 path=" .. EncodeComponentsString(tItemAddInfo.szPath) ..  " </image>"
		end
		szTip = szTip .. GetFormatText("\n")
	end

	szTip = szTip ..  GetFormatText(tItemAddInfo.szTip .. "\n" , 100)

	---------家具套装信息---------
	local dwSetID = tFurnitureConfig.nSetID
	local dwSetIndex = tFurnitureConfig.nSetIndex
	if dwSetID > 0 then
		local tSetInfo = Table_GetFurnitureSetInfoByID(dwSetID)
		if tSetInfo then
			szTip = szTip .. GetFormatText(g_tStrings.STR_HOMELAND_FURNITURE_SET_PREFIX_IN_TIP .. tSetInfo.szName ..
					g_tStrings.STR_ONE_CHINESE_SPACE, 163)
			for k = 1, tSetInfo.nStars do
				szTip = szTip .. "<image>w=20 h=20 path=" .. EncodeComponentsString("ui\\Image\\UITga\\FurnitureCollection.UITex") .. " frame=21</image>"
			end
			szTip = szTip .. GetFormatText("\n")
		end
	end

	------------------品质等级-------------------
	szTip = szTip .. GetFormatText(FormatString(g_tStrings.STR_FURNITURE_TIP_H_LEVEL, tFurnitureConfig.nQualityLevel), 163)

	------------------可染色-------------------
	if FurnitureData.FurnCanDye(dwModelID) then
		szTip = szTip .. "<image> w=20 h=20 path=" .. EncodeComponentsString("ui\\Image\\HomelandBuilding\\HomelandBuilding03.UITex") .. " frame=52 </image>" ..
				"<Text> text=" .. EncodeComponentsString(g_tStrings.STR_FURNITURE_TIP_ILLUSTRATE5 .. "\n" ) .. "</text>"
	end
	------------------可交互-------------------
	if tUIInfo and tUIInfo.bInteract then
		szTip = szTip .. "<image> w=20 h=20 path=" .. EncodeComponentsString("ui\\Image\\HomelandBuilding\\HomelandBuilding03.UITex") .. " frame=51 </image>" ..
				GetFormatText(g_tStrings.STR_FURNITURE_TIP_ILLUSTRATE6 .. "\n" )
	end

	------------------物品来源-------------------
	szTip = szTip .. GetFormatText(FormatString(g_tStrings.STR_FURNITURE_TIP_ILLUSTRATE4, tItemAddInfo.szSource))
	if item then
		local szText, bRefresh = GetItemLeftTimeTip(item, player)
		szTip = szTip ..  szText
	end

	------------------最多摆放-------------------
	--挂件没有nMaxAmountPerLand,默认1
	if nFurnitureType <= HS_FURNITURE_TYPE.PENDANT then
		szTip = szTip .. GetFormatText(FormatString(g_tStrings.STR_FURNITURE_TIP_ILLUSTRATE7, tFurnitureConfig.nMaxAmountPerLand or 1))
	end

	------------------价格------------------
	local tCoinInfo = nil
	if nFurnitureType == HS_FURNITURE_TYPE.FURNITURE then
		tCoinInfo = FurnitureBuy.GetFurnitureInfo(dwFurnitureID)
		local nArchitecture = tFurnitureConfig.nArchitecture
		local nDisCoincount, bInCoinDiscount = FurnitureBuy.GetCoinBuyFurnitureDiscount(dwFurnitureID)
		local nDisArchcount, bInArchDiscount = FurnitureBuy.GetArchBuyFurnitureDiscount(dwFurnitureID)
		if tCoinInfo then
			szTip = szTip .. GetFormatText("\n" .. FormatString(g_tStrings.STR_FURNITURE_TIP_UNIT_PRICE, tCoinInfo.nFinalCoin)) ..
				"<image>w=20 h=20 path=" .. EncodeComponentsString("ui/Image/Common/Money.UITex") .. " frame=257 </image>"
			if bInCoinDiscount then
				local szEndTime = ""
				if tCoinInfo.tPrice.nDisEndTime ~= -1 then
					szEndTime = FormatLinkString(g_tStrings.STR_BUY_FURNITURE_DISCOUNT_END, "font=18",
						GetFormatText(CoinShop_GetTimeText(tCoinInfo.tPrice.nDisEndTime), 27))
				end
				szTip = szTip .. FormatLinkString(g_tStrings.STR_BUY_FURNITURE_DISCOUNT_TIP, "font=18",
				GetFormatText(tCoinInfo.nCoin) ..
				"<image>w=20 h=20 path=" .. EncodeComponentsString("ui/Image/Common/Money.UITex") .. " frame=257 </image>",
				GetFormatText(FormatString(g_tStrings.STR_BUY_FURNITURE_DISCOUNT, FurnitureBuy.GetDiscountNum(nDisCoincount)), 27), szEndTime)
			end
			if tCoinInfo.nEndTime ~= -1 and tCoinInfo.bSell then
				szTip = szTip .. GetFormatText("\n") .. FormatString(g_tStrings.STR_BUY_FURNITURE_SELL_TIME, CoinShop_GetTimeText(tCoinInfo.nEndTime))
			end
			if not tCoinInfo.bSell then
				szTip = szTip .. GetFormatText("\n" .. g_tStrings.STR_BUY_FURNITURE_SELL_END, 102)
			end
		elseif nArchitecture and nArchitecture > 0 then --> 挂件家具没有资源点字段
			if bInArchDiscount then
				szTip = szTip .. GetFormatText("\n" .. FormatString(g_tStrings.STR_FURNITURE_TIP_UNIT_PRICE, tFurnitureConfig.nFinalArchitecture)) ..
				"<image>w=20 h=20 path=" .. EncodeComponentsString("ui/Image/Common/Money.UITex") .. " frame=44 </image>"

				local szEndTime = ""
				if tFurnitureConfig.nDiscountEndTime ~= -1 then
					szEndTime = FormatLinkString(g_tStrings.STR_BUY_FURNITURE_DISCOUNT_END, "font=18",
						GetFormatText(CoinShop_GetTimeText(tFurnitureConfig.nDiscountEndTime), 27))
				end
				szTip = szTip .. FormatLinkString(g_tStrings.STR_BUY_FURNITURE_DISCOUNT_TIP, "font=18",
				GetFormatText(tFurnitureConfig.nArchitecture) ..
				"<image>w=20 h=20 path=" .. EncodeComponentsString("ui/Image/Common/Money.UITex") .. " frame=44 </image>",
				GetFormatText(FormatString(g_tStrings.STR_BUY_FURNITURE_DISCOUNT, FurnitureBuy.GetDiscountNum(nDisArchcount)), 27), szEndTime)
			else
				szTip = szTip .. GetFormatText("\n" .. FormatString(g_tStrings.STR_FURNITURE_TIP_UNIT_PRICE, nArchitecture)) ..
				"<image>w=20 h=20 path=" .. EncodeComponentsString("ui/Image/Common/Money.UITex") .. " frame=44 </image>"
			end
		end
	end

	szTip = GetShopTip(szTip, aShopInfo, item, bHaveCmp)

	if bFromBuilding then
		if tCoinInfo then
			if not bLockedForLevel and tCoinInfo.bSell then
				szTip = szTip .. GetFormatText("\n" .. g_tStrings.STR_HOMELAND_FURNITURE_TIP_CAN_BUY_WITH_COIN, 163)
			end
		elseif nFurnitureType == HS_FURNITURE_TYPE.FURNITURE then
			if not bLockedForLevel and HomelandEventHandler.CanBuyFurnitureWithArchitecture(dwFurnitureID, false, 1) then
				szTip = szTip .. GetFormatText("\n" .. g_tStrings.STR_HOMELAND_FURNITURE_TIP_CAN_BUY_WITH_ARCHITECTURE, 163)
			end
		elseif nFurnitureType == HS_FURNITURE_TYPE.PENDANT then
			if HomelandEventHandler.CanIsotypePendant(dwFurnitureID) then
				szTip = szTip .. GetFormatText("\n" .. g_tStrings.STR_HOMELAND_PENDANT_TIP_CAN_ISOTYPE, 163)
			end
		end
	end

	if item then
		szTip = szTip .. GetFormatText("\n") .. GetItemRewardsTip(item)
	elseif tCoinInfo and tCoinInfo.eGoodsType and tCoinInfo.dwGoodsID then
		szTip = szTip .. GetGoodsRewardsTip(tCoinInfo.eGoodsType, tCoinInfo.dwGoodsID, tCoinInfo.tPrice)
	end

	if nFurnitureType == HS_FURNITURE_TYPE.FURNITURE and  FurnitureBuy.IsSpecialFurnitrueCanBuy(dwFurnitureID) then
		szTip = szTip .. GetFormatText(g_tStrings.STR_FURNITURE_TIP_SPECIAL_CANBUY_AFTER_COLLECTED)
	elseif nFurnitureType == HS_FURNITURE_TYPE.FURNITURE and FurnitureBuy.IsSpecialFurnitrueCanBuyNotHave(dwFurnitureID) then
		szTip = szTip .. GetFormatText(g_tStrings.STR_FURNITURE_TIP_SPECIAL_CANBUY_NEED_COLLECTED)
	end

	--以下为测试代码
	if IsCtrlKeyDown() and not IsShiftKeyDown() and not IsAltKeyDown() then
		if item then
			szTip = szTip..GetFormatText("\n"..g_tStrings.DEBUG_INFO_ITEM_TIP .. "\n".."ID: "..item.dwTabType..", "..item.dwIndex.."\n".."ItemLevel: "..item.nLevel.."\n".."RepresentID: "..item.nRepresentID.."\n".."UIID: "..item.nUiId.."\nsetid: "..item.dwSetID.."\n", 102)
			szTip = szTip..GetFormatText("IconID:"..Table_GetItemIconID(item.nUiId), 102)
		end
		szTip = szTip..GetFormatText("\nnFurnitureType:" .. nFurnitureType, 102)
		szTip = szTip..GetFormatText("\ndwFurnitureID:" .. dwFurnitureID, 102)

		szTip = szTip .. GetFormatText("\ndwUIFurnitureID:" .. dwUIFurnitureID, 102)
		if dwModelID then
			szTip = szTip..GetFormatText("\ndwModelID:" .. dwModelID, 102)
		end
		if dwSetID then
			szTip = szTip..GetFormatText("\ndwSetID:" .. dwSetID, 102)
		end
		if dwSetIndex then
			szTip = szTip..GetFormatText("\ndwSetIndex:" .. dwSetIndex, 102)
		end
	end

	return szTip, item, bNeedRefresh -- 重要
end

-- tBlueprintUiInfo: 对应UI配置表的一行
function GetBlueprintTip(tBlueprintUiInfo, nLandLevel)
	local szTip = ""

	------ 图片 -------------------
	szTip = szTip .. "<image>w=256 h=160 path=\"" .. tostring(tBlueprintUiInfo.szTipImgPath) .. "\"</image>"

	------ 大小和需求等级 ----------
	if tBlueprintUiInfo.szSizeText ~= "" then
		szTip = szTip .. GetFormatText("\n" .. g_tStrings.STR_BLUEPRINT_TIP_SIZE .. tBlueprintUiInfo.szSizeText)
	end

	local nRequiredLevel = tBlueprintUiInfo.nRequiredLevel
	szTip = szTip .. GetFormatText("\n" .. g_tStrings.STR_BLUEPRINT_TIP_REQUIRED_LEVEL_T .. FormatString(g_tStrings.STR_BLUEPRINT_TIP_REQUIRED_LEVEL, nRequiredLevel),
			nLandLevel >= nRequiredLevel and 18 or 102)

	------ 其他文字 ----------
	szTip = szTip .. GetFormatText("\n") .. tBlueprintUiInfo.szTipText

	return szTip
end

local function GetItemBuyIndexTip(item)
	local nBuyIndex = item.nBuyIndex
	return GetBuyIndexTip(nBuyIndex)
end

function GetItemTip(item, nBoxIndex, nBoxItemIndex, szFromLootOrShop, aShopInfo, bCmp, dwPlayerID, bHaveCmp, bLink, szPackageType)
	local itemInfo = GetItemInfo(item.dwTabType, item.dwIndex)
	if not itemInfo then
		Log("[UI ItemTip] error get itemInfo failed when OutputItemTip!\n")
		return ""
	end

	local bNeedRefresh = false
	local player = GetClientPlayer()
	if item.nGenre == ITEM_GENRE.HOMELAND and item.dwTabType == ITEM_TABLE_TYPE.HOMELAND then
		return GetFurnitureItemTip(item, nBoxIndex, nBoxItemIndex, nil, player, szFromLootOrShop, aShopInfo, bCmp, dwPlayerID, bHaveCmp)
	end

	local dwSchoolID = 0
	dwPlayerID, dwSchoolID = _Tip_GetPlayerInfo( player, dwPlayerID)

	local szTip = ""
	if bCmp then -- 跟身上的装备比较时 如果是身上穿的 显示：当前装备
		szTip = "<Text>text="..EncodeComponentsString(g_tStrings.TIP_CURRENT_EQUIP).."font=163 </text>"
	end
    local tSource = {bCmp = bCmp, dwPlayerID = dwPlayerID, bLink = bLink}
    if IsItemCanBeEquip(item.nGenre, item.nSub) and nBoxIndex == INVENTORY_INDEX.EQUIP and szPackageType ~= UI_BOX_TYPE.SHAREPACKAGE then
        tSource.dwX = nBoxItemIndex
    end

	-----------名字 加强化等级-------------------
	szTip = szTip .. GetItemNameAndStrengthTip(item, item.nBookID, true, item.dwIndex, tSource)

	-----------竞技对抗、秘境挑战----------------
	szTip = szTip .. GetItemPVPPVETip(item)

	-----------绑定属性----------------
	local szText, bRefresh = GetItemBindTip(item, player, szFromLootOrShop)
	szTip = szTip .. szText

	if bRefresh then
		bNeedRefresh = bRefresh
	end
	-----------唯一性------------------
	szTip = szTip .. GetItemExistAmountTip(itemInfo)

	---------存在类型----------------
	szTip = szTip .. GetItemExitTypeTip(itemInfo, item.GetLeftExistTime())

	------需求信息----------
	if item.dwTabType == ITEM_TABLE_TYPE.OTHER then
		szTip = szTip..GetOtherItemInfoTip(itemInfo, player, item.dwIndex)
	end

	local szText = ""
	if IsItemCharacterEquip(item.nGenre) then
		-----------装备类型 基本属性 魔法属性 五行石 孔属性 五彩石属性 需求属性 耐久度-------------
		szTip = szTip .. GetEquipItemTip(item, player, nBoxIndex, nBoxItemIndex, tSource)

		----------套装属性-------------------
		if item.dwSetID and item.dwSetID > 0 then
			local szSetTip = GetSetAttriTip(item.dwSetID, dwPlayerID, dwSchoolID);
			if szSetTip then
				szTip = szTip..szSetTip
			end
		end
	elseif item.nGenre == ITEM_GENRE.BOOK then
		--书籍
		szTip = GetBookTipByItem(item, szFromLootOrShop)
	else
		szTip = szTip .. GetOtherTypeTip( player, item, true, szFromLootOrShop )
	end

	if (item.nGenre == ITEM_GENRE.EQUIPMENT and (item.GetSlotCount() > 0)) or
		item.nGenre == ITEM_GENRE.DIAMOND or
		item.nGenre == ITEM_GENRE.COLOR_DIAMOND then
		szTip = szTip .. GetFormatText(g_tStrings.STR_ITEM_H_MOUNT_INFO, 105)
		szTip = szTip .. GetFormatText("\n")
	end

	if CanRepairItem(item) then
		szTip = szTip .. GetFormatText(g_tStrings.STR_ITEM_H_REPAIRE_INFO .. "\n", 105)
	end

	if nBoxIndex and nBoxItemIndex and IsShopOpened() then
	---修理费用，卖店费用-------------------------------
		szTip = szTip .. GetShopMoneyTip(item, nBoxIndex, nBoxItemIndex)
	end

	if item.dwTabType == ITEM_TABLE_TYPE.OTHER and g_LearnInfo[item.dwIndex] then
		----配方需求tip------------------------
		szTip = szTip .. GetRecipeRequireTip(player, g_LearnInfo[item.dwIndex].dwCraftID, g_LearnInfo[item.dwIndex].dwRecipeID)
	end

	----道具示意图-------------------------------------
	local szImg = "\\ui\\image\\item_pic\\"..itemInfo.nUiId..".UITex"
	if IsFileExist(szImg) then
		szTip = szTip.."<image>path="..EncodeComponentsString(szImg).." frame=0 </image><text>text=\"\\\n\"</text>"
	end

	----成长道具示意图-------------------------------------
	szTip = szTip .. GetGrowthEquitInfoTip(item, item.dwTabType, item.dwIndex, itemInfo, dwPlayerID)

	----小头像示意图-------------------------------------
	if item.nGenre == ITEM_GENRE.EQUIPMENT and item.nSub == EQUIPMENT_SUB.MINI_AVATAR then
		local dwAvatarID = item.nRepresentID
		szTip = szTip .. GetAvatarImageTip(dwAvatarID).."<text>text=\"\\\n\"</text>"
	end

	local szItemDesc = GetItemDesc(item.nUiId)
	if szItemDesc and szItemDesc ~= "" then
		szTip = szTip..szItemDesc
		if CanRepairItem(item) then
			local nDurability = DiamondRepairDurabilitySingle(item.nDetail)
			local szText = FormatString(g_tStrings.REPAIRE_ITEM_BY_DIAMOND_TIP, nDurability)
			szTip = szTip .. GetFormatText(szText, 105)
		end
		szTip = szTip .. GetFormatText("\n")
	end

	if item.nGenre == ITEM_GENRE.COLOR_DIAMOND and IsColorDiamondCanNotUp(item) then
		szTip = szTip .. GetFormatText("\n") .. GetFormatText(g_tStrings.tFEProduce.COLOR_DIAMOND_TIP, 102)
	end

	if item.dwTabType == ITEM_TABLE_TYPE.OTHER and g_LearnInfo[item.dwIndex] then
		----配方材料---------------------------
		szTip = szTip .. GetRecipeMerterailTip(player, g_LearnInfo[item.dwIndex].dwCraftID, g_LearnInfo[item.dwIndex].dwRecipeID)
	end

	if item.nGenre == ITEM_GENRE.NPC_EQUIPMENT then
		szTip = szTip .. "<text>text=" .. EncodeComponentsString(g_tStrings.STR_USE_NPC_EQUIPMENT_TIP) .. " font=105 </text>"
	end

	if IsItemCharacterEquip(item.nGenre) then
		------------------品质等级 装备分数-------------------
		szTip = szTip .. GetQualityInfoTip(item, true, tSource)
	end

	if item.nGenre == ITEM_GENRE.EQUIPMENT then
		----门派推荐，外观--------------------
		szTip = szTip .. GetEquipRecommendAndExteriorTip( itemInfo )
	end
	if itemInfo then
		----道具使用间隔
		local nRestTime = GetItemCoolDown(itemInfo.dwSkillID, itemInfo.dwSkillLevel, itemInfo.dwCoolDownID);
		if nRestTime and nRestTime ~= 0 and nRestTime ~= 16 then
			szTip = szTip.."<text>text="..EncodeComponentsString(FormatString(g_tStrings.STR_ITEM_USE_TIME, GetTimeText(nRestTime, true))).." font=106 </text>"
		end
	end

	szText, bRefresh = GetItemLeftTimeTip(item, player)
	szTip = szTip ..  szText
	if bRefresh then
		bNeedRefresh = bRefresh
	end

	szTip = GetShopTip(szTip, aShopInfo, item, bHaveCmp)

	-------装备分解，洗练--------
	szTip = szTip .. GetEquipBreakAndChangeTip(player, item, itemInfo)

	szTip = szTip .. GetQiXiTip(player, item)

	szTip = szTip .. GetItemBuyIndexTip(item)

	szTip = szTip .. GetItemRewardsTip(item)

	--以下为测试代码
	if IsCtrlKeyDown() and not IsShiftKeyDown() and not IsAltKeyDown() then
		szTip = szTip..GetFormatText("\n"..g_tStrings.DEBUG_INFO_ITEM_TIP .. "\n".."ID: "..item.dwTabType..", "..item.dwIndex.."\n".."ItemLevel: "..item.nLevel.."\n".."RepresentID: "..item.nRepresentID.."\n".."UIID: "..item.nUiId.."\nsetid: "..item.dwSetID.."\n", 102)
		szTip = szTip..GetFormatText("IconID:"..Table_GetItemIconID(item.nUiId), 102)
		szTip = szTip..GetFormatText("\nEnchantID:"..item.dwEnchantID, 102)
	end

	return szTip, item, bNeedRefresh
end

function GetShopTip(szTip, aShopInfo, item, bHaveCmp)
	local szStartTime = GetBuyItemStartTime(aShopInfo)
	if szStartTime then
		szTip = szTip .. szStartTime
	end

	if aShopInfo then
		szTip = szTip .. GetShopBuyInfoTip(aShopInfo)
	end

	if not item then
		return szTip
	end
	szTip = szTip .. GetShopShared(item)

	-- local szCmpTip = GetEquipCmpTip(item, true, bHaveCmp) -- 删除秘境和对抗评分
	-- if szCmpTip then
	-- 	szTip = szTip .. szCmpTip .. GetFormatText("\n")
	-- end
	return szTip
end

local function IsShowGrowth(itemInfo)
	local nNeedExp 		= itemInfo.dwNeedGrowthExp
	local nGrowthIndex  = itemInfo.dwGrowthTabIndex
	if nNeedExp and nGrowthIndex and nGrowthIndex ~= 0 then
		return true
	end

 	return false
end

local function GetGrowthEquitFullTip(itemInfo, dwPlayerID)
	local player 			= GetPlayer(dwPlayerID)
	local szTip 			= ""
	local szFullImgPath 	= "ui/image/item_pic/" .. itemInfo.nUiId ..".tga"
	local szSFX 			= Table_GetPath("GROWTH_EQUIT_FULL_TIP") .. player.nCamp .. ".pss"

	if IsFileExist(szFullImgPath) then
		local szImg = GetFormatImage(szFullImgPath, 0)
		local sfx 	= GetFormatSFX(1, 1.3, szSFX, 65, 65)
		szImg = szImg .. sfx
		szTip = szTip .. FormatHandle(szImg, 0, 128, 128) .. GetFormatText("\n")
	end

	return szTip
end

local function GetGrowthEquitINGTip(item, itemInfo, itemNextInfo, dwPlayerID)
	local player 			= GetPlayer(dwPlayerID)
	local nWeekLimit        = GetEquipGrowthExpLimit() or 0
	local nWeekStillAdd     = player.GetEquipGrowthExpRemainSpace() or 0
	local nNeedExp 			= itemInfo.dwNeedGrowthExp
	local nCurrGrowthExp 	= 0
	local nPreocessW		= 116
	local szTip 			= ""
	local szCurrImgPath 	= "ui/image/item_pic/" .. itemInfo.nUiId .. ".tga"
	local szNextImgPath 	= "ui/image/item_pic/" .. itemNextInfo.nUiId ..".tga"
	local szToImgPath 		= "ui/Image/UICommon/PVPUI3.UITex"
	local szSFX 			= Table_GetPath("GROWTH_EQUIT_FULL_TIP") .. player.nCamp .. ".pss"

	if item then
		nCurrGrowthExp = item.dwCurrentGrowthExp or 0
	end
	local nCurrProcessW = math.min(nCurrGrowthExp / nNeedExp * nPreocessW, nPreocessW)
	local szProcessBg = "<image>path=" .. EncodeComponentsString("ui\\Image\\UICommon\\PVPUI3.UITex")
							.. "w=128 h=16 x=0 y=114 frame=21 alpha=200 </image>"
	local szProcessImg = "<image>path=" .. EncodeComponentsString("ui\\Image\\UICommon\\PVPUI3.UITex")
							.. "w=" .. nCurrProcessW .. " h=4 x=6 y=120 frame=23 </image>"

	local szText = GetFormatText(nCurrGrowthExp .. "/" .. nNeedExp, 241, nil, nil, nil, nil, nil, nil, nil, nil, nil, 128, 226, 1, 1, 0)

	if IsImageFileExist(szCurrImgPath) and IsImageFileExist(szNextImgPath) then
		local szImg = GetFormatImage(szCurrImgPath, 0)
		szTip = szTip .. FormatHandle(szImg, 0, 128, 133)

		szImg = GetFormatImage(szToImgPath, 20)
		szTip = szTip .. FormatHandle(szImg, 0, 54, 133) --img size128*20

		local sfx = GetFormatSFX(1, 1.24, szSFX, 64, 65)
		szImg = GetFormatImage(szNextImgPath, 0)
		szImg = szImg .. sfx .. szProcessBg .. szProcessImg .. szText
		szTip = szTip .. FormatHandle(szImg, 0, 128, 133)

		szTip = szTip .. GetFormatText("\n")
	end

	szTip  = szTip .. GetFormatText(g_tStrings.STR_GROWTH_EQUIP_GET_FORM) .. GetFormatText("\n")
	szTip  = szTip .. FormatString(g_tStrings.STR_GROWTH_EQUIP_WEEK_LIMIT, nWeekStillAdd)

	return szTip
end

function GetGrowthEquitInfoTip(item, dwTabType, dwIndex, itemInfo, dwPlayerID)
	if not IsShowGrowth(itemInfo) then
		return ""
	end

	local szTip 		= ""
	local itemNextInfo 	= GetItemInfo(dwTabType, itemInfo.dwGrowthTabIndex)

	if not itemNextInfo then
		Log("[UI ItemTip] error get itemInfo failed when OutputItemTip!\n")
		return ""
	end

	local nCurrL, nNextL = Table_GetGrowthEquitLevel(dwTabType, dwIndex)
	szTip = szTip .. GetFormatText("\n") .. FormatString(g_tStrings.STR_GROWTH_EQUIP_LEVEL, nCurrL, nNextL)

	if dwIndex == itemInfo.dwGrowthTabIndex and itemInfo.dwNeedGrowthExp == 0 then
		szTip = szTip .. GetGrowthEquitFullTip(itemInfo, dwPlayerID)
	else
		szTip = szTip .. GetGrowthEquitINGTip(item, itemInfo, itemNextInfo, dwPlayerID)
	end

	szTip = szTip .. GetFormatText("\n")
	return szTip
end

function GetEquipCmpTip(item, bItem, bHaveCmp)
	if not bHaveCmp then
		return
	end
	if not IsShowEquipCmpTip(item) then
		return
	end
	local itemC, itemCAdd = GetEquipItemCompaireItem(item.nSub, item.nDetail)
	if not itemC then
		return
	end
	local bAlt = IsAltKeyDown()
	local nAttackScorePVE, nTherapyScorePVE, nToughScorePVE, nAttackScorePVP, nTherapyScorePVP, nToughScorePVP = GetEquipCmpScore(item, bItem, itemC, bAlt)
	local tInfo = GetShowInfo()
	local bTherapyMainly = tInfo.bTherapyMainly

	local szPath = "ui/Image/UICommon/CommonPanel7.UITex"
	local szTip = GetFormatImage(szPath, 27, 378, 17)
	local fnFormatScore = function(nScore, szTitle)
		local nFont = 47
		if nScore < 0 then
			nFont = 102
		end
		if nScore >= 0 then
			nScore = "+" .. nScore
		end
		local szText = GetFormatText(nScore .. "%", nFont, nil, nil, nil, nil, nil, nil, nil, nil, nil, 55, 20, 2, 2, 8)
					.. GetFormatText(" " .. szTitle, 18 , nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, 50, 20, 2, 8)
		szText = FormatHandle(szText, 0, 150, 20)
		return szText
	end
	szTip = szTip .. GetFormatText("\n")
	local szTitle = GetFormatText(g_tStrings.STR_EQUIP_CMP_SCORE_PVE, 177)
	szTip = szTip .. FormatHandle(szTitle, 0, 150, 20)
	szTitle = GetFormatText(g_tStrings.STR_EQUIP_CMP_SCORE_PVP, 177)
	szTip = szTip .. FormatHandle(szTitle, 0, 150, 20) .. GetFormatText("\n")

	local tScoreList =
	{
		{nAttackScorePVE, nAttackScorePVP, not bTherapyMainly},
		{nTherapyScorePVE, nTherapyScorePVP, bTherapyMainly},
		{nToughScorePVE, nToughScorePVP, true},
	}

	for i, tScore in ipairs(tScoreList) do
		local bShow = tScore[3]
		if bShow then
			local nScorePVE = tScore[1]
			local nScorePVP = tScore[2]
			local szTextPVE = fnFormatScore(nScorePVE, g_tStrings.tEquipCmpScoreTitle[i])
			local szTextPVP = fnFormatScore(nScorePVP, g_tStrings.tEquipCmpScoreTitle[i])
			szTip = szTip .. szTextPVE .. szTextPVP
		end
	end

	return szTip
end

function GetSpiStoneDesc(dwID)
	local aAttr = GetFEAInfoByEnchantID(dwID)
	if not aAttr or #aAttr == 0 then
		return ""
	end

	local szDesc = "\"</text>"
	local szTmp = ""
	local bFirst = true

	for k, v in pairs(aAttr) do
		if not bFirst then
			szDesc = szDesc .. "<text>text=\"\\\n\"</text>"
		end
		if bFirst then
			bFirst = false
		end

		EquipData.FormatAttributeValue(v)

		local szText = FormatString(g_tStrings.tActivation.COLOR_ATTRIBUTE, k)

		if v.nID == ATTRIBUTE_TYPE.SKILL_EVENT_HANDLER then
			local skillEvent = g_tTable.SkillEvent:Search(v.nValue1)
			if skillEvent then
				szTmp = FormatString(skillEvent.szDesc, v.nValue1, v.nValue2)
			else
				szTmp = "<text>text=\"unknown skill event id:"..v.nValue1.."\"</text>"
			end
		else
			szTmp = FormatString(Table_GetMagicAttributeInfo(v.nID, true), v.nValue1, v.nValue2, MAGIC_ATTRI_DEF, MAGIC_ATTRI_DEF)
		end

		local szPText = szText .. GetPureText(szTmp)
		szDesc = szDesc .. "<Text>text=\"" .. szPText .. "\n" .. "\" font=100 </text>"
		szText = FormatString(g_tStrings.tActivation.COLOR_CONDITION, k)

		local szName = g_tStrings.STR_DIAMOND
		szTmp = FormatString(g_tStrings.tActivation.COLOR_CONDITION1, szName, g_tStrings.tActivation.COLOR_COMPARE[v.nCompare], v.nDiamondCount)
		szText = szText .. szTmp .. "\n"

		szTmp = FormatString(g_tStrings.tActivation.COLOR_CONDITION2, szName, v.nDiamondIntensity)
		szText = szText .. szTmp
		szDesc = szDesc .. "<Text>text=\"" .. szText .. "\" font=177 </text>"
	end
	szDesc = szDesc .. "<Text>text=\""
	return szDesc
end

local function GetPetBuyIndexTip(dwItemIndex, tInfo)
	local nBuyIndex = 0
	if tInfo then
		nBuyIndex = tInfo.nBuyIndex
	end

	if nBuyIndex <= 0 then
		local hPlayer = GetClientPlayer()
		if hPlayer then
			nBuyIndex = hPlayer.GetPetBuyIndex(dwItemIndex)
		end
	end

	return GetBuyIndexTip(nBuyIndex)
end

function OutputPetTip(nPetIndex, Rect, bLink)
	local hPlayer = GetClientPlayer()
	if not hPlayer or not nPetIndex then
		return
	end
	local tPet = Table_GetFellowPet(nPetIndex)
	local r, g, b = GetPetFontColorByQuality(tPet.nQuality)
	local szTip = GetFormatText(tPet.szName .. "\n", 18, r, g, b)

	local nClass = tPet.nClass
	local tLine = Table_GetFellowPet_Class(nClass)
	szTip = szTip .. GetFormatText(tLine.szName .. "\n", 164)

	szTip = szTip .. GetFormatText(FormatString(g_tStrings.CHARACTER_PET_STAR, tPet.nStar) .. "\n", 18)
	local nScore = GetFellowPetScore(nPetIndex)
	szTip = szTip .. GetFormatText(g_tStrings.STR_SCORE .. g_tStrings.STR_COLON .. nScore ..  "\n",  18)

	szTip = szTip .. tPet.szDesc .. GetFormatText("\n", 18)

	local bHave = NewPet.IsHavePet(nPetIndex)
	local tTimeLimit = nil
	if bHave then
		tTimeLimit = hPlayer.GetFellowPetTimeLimit(nPetIndex)--判断是否限时（没有拥有的宠物会报错）
	end
	if tTimeLimit then
		local nExistTime = BigIntSub(GetCurrentTime(), tTimeLimit.nGenTime)
		if tTimeLimit.nExistType == ITEM_EXIST_TYPE.OFFLINE then
			local nLeftTime = tTimeLimit.nMaxExistTime
			szTip = szTip .. GetFormatText("\n")
			if nLeftTime > 0 then
				local szTime = GetTimeText(nLeftTime)
				szTip = szTip .. FormatString(g_tStrings.STR_ITEM_OFF_LINE_TIME_OVER, szTime)
			else
				szTip = szTip .. GetFormatText(g_tStrings.STR_ITEM_TIME_TYPE1.."\n", 107)
			end
		elseif tTimeLimit.nExistType == ITEM_EXIST_TYPE.ONLINE then
			szTip = szTip .. GetFormatText("\n")
			local nLeftTime = BigIntSub(tTimeLimit.nMaxExistTime , nExistTime)
			if nLeftTime > 0 then
				local szTime = GetTimeText(nLeftTime)
				szTip = szTip..FormatString(g_tStrings.STR_ITEM_ON_LINE_TIME_OVER, szTime)
			else
				szTip = szTip..GetFormatText(g_tStrings.STR_ITEM_TIME_TYPE2.."\n", 107)
			end
		elseif tTimeLimit.nExistType ==  ITEM_EXIST_TYPE.ONLINEANDOFFLINE or tTimeLimit.nExistType == ITEM_EXIST_TYPE.TIMESTAMP then
			local nLeftTime
			if tTimeLimit.nExistType == ITEM_EXIST_TYPE.ONLINEANDOFFLINE then
				nLeftTime = BigIntSub(tTimeLimit.nMaxExistTime, nExistTime)
			else
				nLeftTime = BigIntSub(tTimeLimit.nMaxExistTime, tTimeLimit.nGenTime)
				nLeftTime = BigIntSub(nLeftTime, nExistTime)
			end
			szTip = szTip .. GetFormatText("\n")
			if nLeftTime > 0 then
				local szTime = GetTimeText(nLeftTime)
				szTip = szTip..FormatString(g_tStrings.STR_ITEM_TIME_OVER, szTime)
			else
				szTip = szTip..GetFormatText(g_tStrings.STR_ITEM_TIME_TYPE3.."\n", 107)
			end
		end
	end

	szTip = szTip .. tPet.szOutputDes .. GetFormatText("\n")
	-- szTip = szTip .. GetPetBuyIndexTip(nPetIndex)

	--以下为测试代码
	if IsCtrlKeyDown() and not IsShiftKeyDown() and not IsAltKeyDown() then
		local nTabType, nTabIndex = GetItemIndexByFellowPetIndex(nPetIndex)
		local dwNpcID = GetNpcTemplateIDByFellowPetIndex(nPetIndex)
		szTip = szTip..GetFormatText("\n"..g_tStrings.DEBUG_INFO_ITEM_TIP.."\n".."ID: "..nTabType..", "..nTabIndex.."\n", 102)
		szTip = szTip..GetFormatText("NpcId: "..dwNpcID .."\n", 102)
		szTip = szTip..GetFormatText("PetIndex: "..nPetIndex .."\n", 102)
	end

	local tImage = {
		szType 		= "Pet",
		dwPetIndex 	= nPetIndex,
		w 			= 46,
		h 			= 46,
	}
	OutputTip(szTip, 400, Rect, nil, bLink, "Pet" .. nPetIndex, nil, nil, nil, nil, nil, nil, tImage)
end

function OutputMedalTip(tMedal, Rect)
	local hPlayer = GetClientPlayer()
	if not hPlayer then
		return
	end
	local dwMedalIndex = tMedal.nMedalIndex
	local dwMedalType = tMedal.dwMedalType
	local dwMedalScore = tMedal.dwMedalScore
	local bMedalAcquired = tMedal.bMedalAcquired

	tInfo = Table_GetFellowPet_Medal(dwMedalIndex)
	local szName = tInfo.szName
	local szTip = GetFormatText(szName .. "\n", 18)
	if bMedalAcquired then
		szTip = szTip .. GetFormatText(g_tStrings.DESGNATION_POSTFIX_HAS_GET .. "\n", 164)
	else
		szTip = szTip .. GetFormatText(g_tStrings.DESGNATION_POSTFIX_UNGET .. "\n", 102)
	end
	szTip = szTip .. GetFormatText(g_tStrings.tMedalType[dwMedalType] ..  "\n",  27)
	szTip = szTip .. GetFormatText(g_tStrings.STR_SCORE .. g_tStrings.STR_COLON .. dwMedalScore ..  "\n",  18)
	szTip = szTip .. tInfo.szDes .. GetFormatText("\n")
	szTip = szTip .. tInfo.szReward

	OutputTip(szTip, 400, Rect)
end

function OutputHorseTuJianAttrTip(tInfo, Rect)
	local hPlayer = GetClientPlayer()
	if not hPlayer then
		return
	end

	local szName = tInfo.szName
	local szTuJianTip = tInfo.szTuJianTip or ""

	local szTip = GetFormatText(szName .. "\n", 18)
	szTip = szTip .. szTuJianTip

	OutputTip(szTip, 400, Rect)
end

local fnGetQualityFont = function(nQuality)
	local r, g, b = 255, 255, 255
	if nQuality == 1  then 		--白色
		r, g, b = 255, 255, 255
	elseif nQuality == 2 then 	--绿色
		r, g, b = 0, 200, 72
	elseif nQuality == 3 then	--蓝色
		r, g, b = 0, 126, 255
	elseif nQuality ==4 then 	--紫色
		r, g, b = 255, 40, 255
	elseif nQuality == 5 then 	--橙色
		r, g, b = 255, 165, 0
	end
	return r, g, b
end

function OutputHorseChildAttrTip(tInfo, Rect)
	local hPlayer = GetClientPlayer()
	if not hPlayer then
		return
	end
	local szName = tInfo.szName

	local szChildTip = FormatString(tInfo.szTip, tInfo.nValue) or ""

	local nLevel = tInfo.nLevel
	local tGener = SplitString(tInfo.szGener, ",")
	local nWhite, nGreen, nBlue, nPurple, nOrange = tonumber(tGener[1]), tonumber(tGener[2]), tonumber(tGener[3]), tonumber(tGener[4]), tonumber(tGener[5])
	local r, g, b = 0, 0, 0
	if nLevel >= nWhite and nLevel < nGreen then
		r, g, b = fnGetQualityFont(1)
	elseif nLevel >= nGreen and nLevel < nBlue then
		r, g, b = fnGetQualityFont(2)
	elseif nLevel >= nBlue and nLevel < nPurple then
		r, g, b = fnGetQualityFont(3)
	elseif nLevel >= nPurple and nLevel < nOrange then
		r, g, b = fnGetQualityFont(4)
	elseif nLevel >= nOrange then
		r, g, b = fnGetQualityFont(5)
	end

	local szTip = GetFormatText(szName .. "\n", 18, r, g, b)
	if nLevel > 0 then
		szTip = szTip .. GetFormatText(FormatString(g_tStrings.STR_FRIEND_WTHAT_LEVEL .. "\n", nLevel), 18)
	end
	szTip = szTip .. szChildTip

	if tInfo.bHurry and not tInfo.bIgnoreHungry then
		szTip = szTip .. GetFormatText("\n") .. tInfo.szFeedTip
	end

	OutputTip(szTip, 400, Rect)
end

function OutputReceipeTip(hReceipe, Rect)
	local tInfo = hReceipe.tInfo
	local szTitle = tInfo.szName
	local bHas = tInfo.bHas
	local szTip = tInfo.szTip

	local szReceipeTip = GetFormatText(g_tStrings.STR_RECEIPE_NAME .. g_tStrings.STR_COLON, 27)
	szReceipeTip = szReceipeTip .. GetFormatText(szTitle .. "\n", 18)
	szReceipeTip = szReceipeTip .. GetFormatText(g_tStrings.STR_IS_LEARN .. g_tStrings.STR_COLON, 27)
	if bHas then
		szReceipeTip = szReceipeTip .. GetFormatText(g_tStrings.TIP_LEARNED1 .. "\n", 18)
	else
		szReceipeTip = szReceipeTip .. GetFormatText(g_tStrings.TIP_UNLEARNED, 102)
	end
	szReceipeTip = szReceipeTip .. GetFormatText(g_tStrings.STR_RECEIPE_SOURCE .. g_tStrings.STR_COLON, 27)
	szReceipeTip = szReceipeTip .. szTip

	OutputTip(szReceipeTip, 400, Rect)
end

-- tFurnitureData: {nType=HS_FURNITURE_TYPE.FURNITURE/PENDANT, dwID=dwID, nLandLevel=nLandLevel, bFromBuilding=true/false}
function OutputFurnitureTip(tFurnitureData, tRect)
	local szTip = GetFurnitureItemTip(nil, nil, nil, tFurnitureData, nil)
	OutputTip(szTip, 400, tRect, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, true)
end

-- tBlueprintUiInfo: 对应UI配置表的一行
function OutputBlueprintTip(tBlueprintUiInfo, nLandLevel, tRect)
	local szTip = GetBlueprintTip(tBlueprintUiInfo, nLandLevel)
	OutputTip(szTip, 256, tRect, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, true)
end


local function IsMagicAttriStrength(item, id, AttribOrg, Attrib, tSource)-- AttribOrg, Attrib can ignore
	AttribOrg 	= AttribOrg or {}
	Attrib 		= Attrib or {}
	if item.nGenre ~= ITEM_GENRE.NPC_EQUIPMENT then
		AttribOrg 	= AttribOrg or item.GetMagicAttribByStrengthLevel(0)
		Attrib 		= Attrib or item.GetMagicAttribByStrengthLevel(CastingPanel.GetStrength(item, nil, tSource).nTrueLevel)
	end

	local nTop = #AttribOrg
	local index, value1, value2 = 0, 0, 0
	for i = 1, nTop, 1 do
		if id == AttribOrg[i].nID then
            local bStrength = AttribOrg[i].nValue1 ~= Attrib[i].nValue1 or AttribOrg[i].nValue2 ~= Attrib[i].nValue2
			return bStrength, AttribOrg[i].nValue1, AttribOrg[i].nValue2, Attrib[i].nValue1, Attrib[i].nValue2
		end
	end
end

function GetMagicAttriText(item, attri, bItem, AttribOrgs, Attribs, tSource)
	local id = attri.nID
	local aValue
	if id == ATTRIBUTE_TYPE.SET_EQUIPMENT_RECIPE then
		if attri.Param0 then
			return GetEquipRecipeDesc( attri.Param0, attri.Param2 )
		else
			return GetEquipRecipeDesc( attri.nValue1, attri.nValue2 )
		end
	end

	if id == ATTRIBUTE_TYPE.SKILL_EVENT_HANDLER then
		if attri.Param0 then
			aValue = { attri.Param0, attri.Param1, attri.Param2, attri.Param3 }
		else
			aValue = { attri.nValue1, attri.nValue2 }
		end

		local skillEvent = g_tTable.SkillEvent:Search(aValue[1])
		if skillEvent then
			return FormatString(skillEvent.szDesc, unpack(aValue))
		else
			return "<text>text=\"unknown skill event id:"..aValue[1].."\"</text>"
		end
	end

    EquipData.FormatAttributeValue(attri)

    local bStrengthAttrib, org_value1, org_value2, new_value1, new_value2 = IsMagicAttriStrength(item, id, AttribOrgs, Attribs, tSource)

    if attri.Param0 then
        aValue = { tonumber(attri.Param0), tonumber(attri.Param1), tonumber(attri.Param2), tonumber(attri.Param3) }
    elseif bItem and bStrengthAttrib then
        aValue = { org_value1, org_value2, new_value1, new_value2 }
    else
        aValue = { tonumber(attri.nValue1), tonumber(attri.nValue2), MAGIC_ATTRI_DEF, MAGIC_ATTRI_DEF }
    end

    local szText = FormatString(Table_GetMagicAttributeInfo(id, bItem), unpack(aValue))

	if bStrengthAttrib then
		local szValue = FormatString(Table_GetMagicAttriStrengthValue(id), org_value1, org_value2, new_value1, new_value2, 0)
		szText = szText .. GetFormatText(FormatString(g_tStrings.STR_ADD_VALUE2, szValue), 192)
	end

	return szText
end

function OutputToyTip(dwToyID, Rect, bLink)
	local tLine = Table_GetToyBox(dwToyID)
	if not tLine then
		return
	end
	if dwToyID > 0 then
		local szTip = ""
		szTip = szTip .. GetFormatText(tLine.szName .. "\n", 31)
		local szEffect = not string.is_nil(tLine.szMobileEffect) and tLine.szMobileEffect or tLine.szEffect
		szTip = szTip .. GetFormatText(g_tStrings.STR_TOYBOX_TIP_EFFECT, 287) .. GetFormatText(g_tStrings.STR_COLON .. szEffect .. "\n", 287)

		if tLine.dwQuestID > 0 then
			local tQuestInfo = Table_GetQuestStringInfo(tLine.dwQuestID)
			szTip = szTip .. GetFormatText(g_tStrings.STR_TOYBOX_TIP_QUEST, 18) .. GetFormatText(g_tStrings.STR_COLON .. tQuestInfo.szName .. "\n", 18)
		end

		if tLine.dwMapID > 0 then
			local szMapName = Table_GetMapName(tLine.dwMapID)
			szTip = szTip .. GetFormatText(g_tStrings.STR_TOYBOX_TIP_MAP, 18) .. GetFormatText(g_tStrings.STR_COLON .. szMapName .. "\n", 18)
		end

		if tLine.dwAchievementID > 0 then
			local tAchievement = Table_GetAchievement(tLine.dwAchievementID)
			szTip = szTip .. GetFormatText(g_tStrings.STR_TOYBOX_TIP_ACHIEVEMENT, 18) .. GetFormatText(g_tStrings.STR_COLON .. tAchievement.szName .. "\n", 18)
		end

		if tLine.szShop ~= "" then
			szTip = szTip .. GetFormatText(tLine.szShop .. "\n", 18)
		end

		if tLine.szDesc ~= "" then
			szTip = szTip .. GetFormatText(tLine.szDesc .. "\n", 101)
		end
		OutputTip(szTip, 400, Rect, nil, bLink, "toybox"..dwToyID)
	end
end

function GetNpcEquipMagicAttriText(attri, AttribOrg)
	local szText = ""
	local id = attri.nID
	local org_value1
	local org_value2

	local bStrength = false
	for i = 1, #AttribOrg do
		if id == AttribOrg[i].nID then
			bStrength = AttribOrg[i].nValue1 ~= attri.nValue1 or AttribOrg[i].nValue2 ~= attri.nValue2
			org_value1 = AttribOrg[i].nValue1
			org_value2 = AttribOrg[i].nValue2
		end
	end
	szText = szText .. GetFormatText(ParseTextHelper.ParseNormalText(FormatString(Table_GetMagicAttributeInfo(id, true), org_value1, org_value2)), 106)
	if bStrength then
		local szValue = FormatString(Table_GetMagicAttriStrengthValue(id), org_value1, org_value2, attri.nValue1, attri.nValue2, 0)
		szText = szText .. GetFormatText(FormatString(g_tStrings.STR_ADD_VALUE2, szValue), 192)
	end

	return szText, bStrength
end

local tAttributeIndex = {
    [ATTRIBUTE_TYPE.MAX_LIFE_BASE] = 1, --血量
    [ATTRIBUTE_TYPE.ALL_TYPE_ATTACK_POWER_BASE] = 2, --攻击
    [ATTRIBUTE_TYPE.THERAPY_POWER_BASE] = 3, --治疗
    [ATTRIBUTE_TYPE.ALL_TYPE_CRITICAL_STRIKE] = 4, --会心
    [ATTRIBUTE_TYPE.ALL_TYPE_CRITICAL_DAMAGE_POWER_BASE] = 5, --会效等级
    [ATTRIBUTE_TYPE.ALL_TYPE_OVERCOME_BASE] = 6, --破防
    [ATTRIBUTE_TYPE.PHYSICS_SHIELD_BASE] = 7, --外防
    [ATTRIBUTE_TYPE.MAGIC_SHIELD] = 8, --内防
    [ATTRIBUTE_TYPE.TOUGHNESS_BASE] = 9, --御劲
    [ATTRIBUTE_TYPE.GLOBAL_DAMAGE_FIXED_ADD] = 10, --技能伤害提高
    [ATTRIBUTE_TYPE.ASSISTED_POWER_EXT_ADD] = 11, --凝神等级（百分比）
    [ATTRIBUTE_TYPE.ALL_SHIELD_IGNORE_ADD] = 13, --无视防御点数
    [ATTRIBUTE_TYPE.STRAIN_RATE] = 14, --无双
}

function GetMergeNpcEquipChangeAttib(tChangeAttib)
    local tMerge = {}
    for _, v in ipairs(tChangeAttib) do
        local bMatch = false
        for k, tAttib in ipairs(tMerge) do
            if v.nID == tAttib.nID then
                tAttib.nValue1 = tAttib.nValue1 + v.nValue1
                tAttib.nValue2 = tAttib.nValue2 + v.nValue2
                tAttib.nCount  = tAttib.nCount + 1
                bMatch         = true
            end
        end
        if not bMatch then
            v.nCount = 1
            table.insert(tMerge, v)
        end
    end
    local function fnCmp(a, b)
        return tAttributeIndex[a.nID] < tAttributeIndex[b.nID]
    end
    table.sort(tMerge, fnCmp)
    return tMerge
end

function GetShopItemDesc(item)
	local szDesc = ""
	local pPlayer = GetClientPlayer()
	local tItemInfo = GetItemInfo(item.dwTabType, item.dwIndex)

	--唯一
	local szOnlyOne = GetItemExistAmountTip(tItemInfo)
	if szOnlyOne ~= "" then
		szDesc = szDesc .. "<text>text=\"" .. szOnlyOne.. "\" font=163 </text>"
	end

	if EquipData.IsItemCharacterEquip(item.nGenre) then
		szDesc = szDesc .. "<text>text=".. UIHelper.EncodeComponentsString(FormatString(g_tStrings.STR_ITEM_H_ITEM_LEVEL .. "\n", item.nLevel)).." font=163 </text>"
	end

	local nLevelFont = 166
	if tItemInfo.nRequireLevel ~= 0 then
		if pPlayer.nLevel >= tItemInfo.nRequireLevel then
			nLevelFont = 162
		end
		szDesc = szDesc .. GetFormatText(FormatString(g_tStrings.NEED .. g_tStrings.TIP_LEVEL_WHAT .. "\n", tItemInfo.nRequireLevel), nLevelFont)
	end

	--if item.dwTabType == ITEM_TABLE_TYPE.OTHER and g_LearnInfo[item.dwIndex] then
	--	local bLearned = pPlayer.IsRecipeLearned(g_LearnInfo[item.dwIndex].dwCraftID, g_LearnInfo[item.dwIndex].dwRecipeID)
	--	if bLearned then
	--		szDesc = szDesc .. "<Text>text="..UIHelper.EncodeComponentsString(g_tStrings.TIP_LEARNED1 .. "\n")  .."font=108</text>"
	--	end
	--end

	if item.nGenre == ITEM_GENRE.DESIGNATION then
		szDesc = szDesc .. GetTitleTip(pPlayer, tItemInfo)
	end

	if item.nSub == EQUIPMENT_SUB.PACKAGE then
		local value = 0
		value = item.nCurrentDurability
		szDesc = szDesc .. "<Text>text=".. UIHelper.EncodeComponentsString(FormatString(g_tStrings.STR_ITEM_H_BAG_SIZE, value)).." font=106 </text>"
	end

	if item.nGenre == ITEM_GENRE.BOOK then
		local nBookID, nSegmentID = GlobelRecipeID2BookID(item.nBookID)
		local recipe = GetRecipe(CRAFT_ID_READ, nBookID, nSegmentID)
		local nRequireLevel = recipe.dwRequireProfessionLevel
		local xml = {}
		if item.nMaxExistAmount ~= 0 then
			if item.nMaxExistAmount == 1 then
				table.insert(xml, GetFormatText(g_tStrings.STR_ITEM_H_UNIQUE, 106))
			else
				table.insert(xml, GetFormatText(g_tStrings.STR_ITEM_H_UNIQUE_MULTI, 106))
			end
		end
		local nSort = Table_GetBookSort(nBookID, nSegmentID)
		table.insert(xml, GetFormatText(g_tStrings.STR_CRAFT_READ_BOOK_SORT_NAME_TABLE[nSort].."\n", 106))
		local nLevel = pPlayer.GetProfessionLevel(CRAFT_ID_READ)
		table.insert(xml, GetFormatText(FormatString(g_tStrings.CRAFT_READING_REQUIRE_LEVEL1, nRequireLevel), 106))
		local nFontVigor = 166
		if pPlayer.IsVigorAndStaminaEnough(recipe.nVigor)  then
			nFontVigor = 106
		end
		table.insert(xml, GetFormatText(FormatString(g_tStrings.STR_CRAFT_COST_VIGOR_ENTER, recipe.nVigor), nFontVigor))
		if pPlayer.IsBookMemorized(nBookID, nSegmentID) then
			table.insert(xml, GetFormatText(g_tStrings.TIP_ALREADY_READ, 108))
		else
			table.insert(xml, GetFormatText(g_tStrings.TIP_UNREAD, 105))
		end

		table.insert(xml, GetFormatText(Table_GetBookDesc(nBookID, nSegmentID).."\n", 105))
		szDesc = szDesc .. table.concat(xml)
	end

	if item.dwTabType == ITEM_TABLE_TYPE.HOMELAND then
		local pHlMgr = GetHomelandMgr()
		local nFurnitureType = tItemInfo.nFurnitureType or HS_FURNITURE_TYPE.FURNITURE
		local dwFurnitureID = item.dwFurnitureID
		local tFurnitureConfig
		if nFurnitureType == HS_FURNITURE_TYPE.FURNITURE then
			tFurnitureConfig = pHlMgr.GetFurnitureConfig(dwFurnitureID)
		elseif nFurnitureType == HS_FURNITURE_TYPE.PENDANT then
			tFurnitureConfig = pHlMgr.GetPendantConfig(dwFurnitureID)
		elseif nFurnitureType == HS_FURNITURE_TYPE.APPLIQUE_BRUSH then
			tFurnitureConfig = pHlMgr.GetAppliqueBrushConfig(dwFurnitureID)
		elseif nFurnitureType == HS_FURNITURE_TYPE.FOLIAGE_BRUSH then
			tFurnitureConfig = pHlMgr.GetFoliageBrushConfig(dwFurnitureID)
		end
		szDesc = szDesc .. GetFormatText(FormatString(g_tStrings.STR_FURNITURE_TIP_H_LEVEL, tFurnitureConfig.nQualityLevel), 163)
		szDesc = szDesc .. GetFormatText(FormatString(g_tStrings.STR_FURNITURE_TIP_ILLUSTRATE0, tFurnitureConfig.nLevelLimit))
		local dwSetID = tFurnitureConfig.nSetID or 0
		if dwSetID > 0 then
			local tSetInfo = Table_GetFurnitureSetInfoByID(dwSetID)
			if tSetInfo then
				szDesc = szDesc .. GetFormatText(g_tStrings.STR_HOMELAND_FURNITURE_SET_PREFIX_IN_TIP .. tSetInfo.szName .. "\n", 163)
			end
		end

		local nRecord = tFurnitureConfig.uRecord
		if nRecord and nRecord > 0 then
			szDesc = szDesc .. GetFormatText(FormatString(g_tStrings.STR_FURNITURE_TIP_SCORE, nRecord), 105)
		end

		local nArchitecture = tFurnitureConfig.nArchitecture
		local nReBuyCost = tFurnitureConfig.nReBuyCost
		if nArchitecture and nArchitecture > 0 then --> 挂件家具没有资源点字段
			szDesc = szDesc .. GetFormatText("\n") .. GetFormatText(FormatString(g_tStrings.STR_FURNITURE_TIP_UNIT_PRICE .. " ", nArchitecture)) ..
					"<image>w=30 h=30 path=" .. UIHelper.EncodeComponentsString("ui/Image/Common/Money.UITex") .. " frame=44 </image>"
		end
		if nReBuyCost and nReBuyCost > 0 then --> 挂件家具没有资源点字段
			szDesc = szDesc .. GetFormatText("\n") .. GetFormatText(FormatString(g_tStrings.STR_FURNITURE_TIP_UNIT_PRICE .. " ", nReBuyCost)) ..
					"<image>w=30 h=30 path=" .. UIHelper.EncodeComponentsString("ui/Image/Common/Money.UITex") .. " frame=44 </image>"
		end

		szDesc = szDesc .. GetFormatText("\n") .. GetRewardsTip(item.dwTabType, item.dwIndex)

		if nFurnitureType == HS_FURNITURE_TYPE.FURNITURE and FurnitureBuy.IsSpecialFurnitrueCanBuy(dwFurnitureID) then
			szDesc = szDesc .. GetFormatText(g_tStrings.STR_FURNITURE_TIP_SPECIAL_CANBUY_AFTER_COLLECTED)
		elseif nFurnitureType == HS_FURNITURE_TYPE.FURNITURE and FurnitureBuy.IsSpecialFurnitrueCanBuyNotHave(dwFurnitureID) then
			szDesc = szDesc .. GetFormatText(g_tStrings.STR_FURNITURE_TIP_SPECIAL_CANBUY_NEED_COLLECTED)
		end
		szDesc = szDesc .. GetFormatText(g_tStrings.STR_FURNITURE_TIP_ILLUSTRATE1, 105)
	end

	--local szItemDesc = GetItemDesc(item.nUiId)

	local szItemDesc = Table_GetItemDesc(item.nUiId)
	-- szItemDesc = string.gsub(szItemDesc, "<SKILL (%d+) (%d+)>", function(dwID, dwLevel) return GetSubSkillDesc(dwID, dwLevel) end)
	-- szItemDesc = string.gsub(szItemDesc, "<BUFF (%d+) (%d+) (%w+)>", function(dwID, nLevel, szKey)  return GetBuffDesc(dwID, nLevel, szKey) end)
	szItemDesc = string.gsub(szItemDesc, "<ENCHANT (%d+)>", function(dwID) return GetEnchantDesc(dwID) end)
	-- szItemDesc = string.gsub(szItemDesc, "<SpiStone (%d+)>", function(dwID) return GetSpiStoneDesc(dwID) end)
	print(item.nUiId, szItemDesc)
	
	szItemDesc = UIHelper.GBKToUTF8(szItemDesc)
	szDesc = szDesc .. szItemDesc
	if item.nGenre == ITEM_GENRE.EQUIPMENT and item.nSub == EQUIPMENT_SUB.MINI_AVATAR then
		local dwAvatarID = item.nRepresentID
		szDesc = szDesc .. GetAvatarImageTip(dwAvatarID).."<text>text=\"\\\n\"</text>"
	end

	-- 限时显示----
	local szText = GetItemExitTypeTip(tItemInfo, item.GetLeftExistTime(), true)
	szDesc = szDesc .. GetEquipBreakAndChangeTip(pPlayer, item, tItemInfo)
	local nRestTime = GetItemCoolDown(tItemInfo.dwSkillID, tItemInfo.dwSkillLevel, tItemInfo.dwCoolDownID);
	if nRestTime and nRestTime ~= 0 and nRestTime ~= 16 then
		szDesc = szDesc .. GetFormatText(FormatString("\n" .. g_tStrings.STR_ITEM_USE_TIME, UIHelper.GetTimeText(nRestTime, true)), 106)
	end
	return szDesc, szText
end

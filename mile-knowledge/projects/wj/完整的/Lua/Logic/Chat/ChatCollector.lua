ChatCollector = ChatCollector or {className = "ChatCollector"}
local self = ChatCollector


Event.Reg(self, EventType.OnClientPlayerEnter, function()
    ChatCollector.nPlayerLastExp = nil
    ChatCollector.nLastCoin = CurrencyData.GetCurCurrencyCount(CurrencyType.Coin)
    ChatCollector.nLastVoucher = CurrencyData.GetCurCurrencyCount(CurrencyType.CoinShopVoucher)
end)


-- -----------------------------------------------------------------------------
-- Msg Collector with chat setting
-- -----------------------------------------------------------------------------

-- 金钱
Event.Reg(self, "MONEY_UPDATE", function(nDeltaGold, nDeltaSilver, nDeltaCopper)
    if not ChatData.CheckSystemChannelCanRecvReward("MSG_MONEY") then return end
    if nDeltaGold <= 0 and nDeltaSilver <= 0 and nDeltaCopper <= 0 then return end

    local tMoney = PackMoney(nDeltaGold, nDeltaSilver, nDeltaCopper)
    local szMoney = UIHelper.GetMoneyText(tMoney)

    local szMsg = nil
    -- if nDeltaGold > 0 then
    --     szMsg = szMsg or ""
    --     szMsg = szMsg..string.format("%d<img src='UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_Jin' width='30' height='30'/>", nDeltaGold)
    -- end

    -- if nDeltaSilver > 0 then
    --     szMsg = szMsg or ""
    --     szMsg = szMsg..string.format("%d<img src='UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_Yin' width='30' height='30'/>", nDeltaSilver)
    -- end

    -- if nDeltaCopper > 0 then
    --     szMsg = szMsg or ""
    --     szMsg = szMsg..string.format("%d<img src='UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_Tong' width='30' height='30'/>", nDeltaCopper)
    -- end

    -- if not szMsg then return end

    szMsg = "你获得：".. szMoney
    ChatData.Append(szMsg, 0, PLAYER_TALK_CHANNEL.SYSTEM_NOTICE, false, "")
end)

-- 修为
Event.Reg(self, "UI_TRAIN_VALUE_UPDATE", function(nAddTrain)
    if nAddTrain <= 0 then return end
    if not ChatData.CheckSystemChannelCanRecvReward("MSG_TRAIN") then return end

    local szMsg = "你获得：修为"
    szMsg = szMsg .. string.format("<img src='UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_XiuWei' width='30' height='30'/>%d", nAddTrain)
    ChatData.Append(szMsg, 0, PLAYER_TALK_CHANNEL.SYSTEM_NOTICE, false, "")
end)

-- 阅历 经验
Event.Reg(self, "PLAYER_EXPERIENCE_UPDATE", function(dwPlayerID)
    if not g_pClientPlayer then return end
    if g_pClientPlayer.dwID ~= dwPlayerID then return end

    if not ChatData.CheckSystemChannelCanRecvReward("MSG_EXP") then return end

    local nDeltaExp = g_pClientPlayer.nExperience - (self.nPlayerLastExp or g_pClientPlayer.nExperience)
    self.nPlayerLastExp = g_pClientPlayer.nExperience

    if nDeltaExp <=0 then return end

    local szMsg = "你获得：阅历"
    szMsg = szMsg .. string.format("<img src='UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_YueLi' width='30' height='30'/>%d", nDeltaExp)
    ChatData.Append(szMsg, 0, PLAYER_TALK_CHANNEL.SYSTEM_NOTICE, false, "")
end)

-- 声望
Event.Reg(self, "REPUTATION_LEVEL_UPDATE", function(dwForceID, nNumber)
    if nNumber == 0 then return end
    if not ChatData.CheckSystemChannelCanRecvReward("MSG_REPUTATION") then return end

    local szMsg = nil

    local tRepuForceInfo = Table_GetReputationForceInfo(dwForceID)
	if not tRepuForceInfo then
		return
	end

    local szName = GBKToUTF8(tRepuForceInfo.szName)
    if nNumber > 0 then
        szMsg = FormatString(g_tStrings.STR_MSG_REPUTE_ADD, szName, nNumber)
    else
        szMsg = FormatString(g_tStrings.STR_MSG_REPUTE_DEL, szName, -nNumber)
    end

    ChatData.Append(szMsg, 0, PLAYER_TALK_CHANNEL.SYSTEM_NOTICE, false, "")
end)

-- 声望等级
Event.Reg(self, "REPUTATION_LEVEL_UP", function(dwForceID, nOldLevel)
    if not g_pClientPlayer then return end
    if not ChatData.CheckSystemChannelCanRecvReward("MSG_REPUTATION") then return end

    local nCurRepuLevel = g_pClientPlayer.GetReputeLevel(dwForceID)
    local tForceUIInfo = Table_GetReputationForceInfo(dwForceID)
    local szForceType = UIHelper.GBKToUTF8(tForceUIInfo.szName)
    local tRepuLevelInfo = Table_GetReputationLevelInfo(nCurRepuLevel)
    if not tRepuLevelInfo then return end

    local szMsg = FormatString(g_tStrings.STR_MSG_REPUTE_CHANGED, szForceType, GBKToUTF8(tRepuLevelInfo.szName))
    ChatData.Append(szMsg, 0, PLAYER_TALK_CHANNEL.SYSTEM_NOTICE, false, "")
end)

-- 获得道具
Event.Reg(self, "LOOT_ITEM", function(dwPlayerID, dwItemID, dwCount)
    if not dwCount or dwCount <= 0 then return end
    if not ChatData.CheckSystemChannelCanRecvReward("MSG_ITEM") then return end

    local player = GetPlayer(dwPlayerID)
    if not player then return end

    local item = GetItem(dwItemID)
    if not item then return end

    local szColor = item and ItemQualityColor[item.nQuality + 1] or "#FFFFFF"
    local szName = ItemData.GetItemNameByItem(item) or ""
    local szLink = ChatHelper.MakeLink_item(dwItemID)
    local szItem = string.format("<href=%s><color=%s>[%s]</color></href>", szLink, szColor, GBKToUTF8(szName))
    local szPlayerName = (g_pClientPlayer.dwID == dwPlayerID) and g_tStrings.STR_NAME_YOU or GBKToUTF8(player.szName)

    local szMsg = string.format("%s获得：%s x%d", szPlayerName, szItem, dwCount)
    ChatData.Append(szMsg, 0, PLAYER_TALK_CHANNEL.SYSTEM_NOTICE, false, "")
end)

-- 精力值
Event.Reg(self, "SELF_ST_CHANGE", function(nDeltaStamina, nDeltaThew)
	if not ChatData.CheckSystemChannelCanRecvReward("MSG_THEW_STAMINA") then return end

    if nDeltaStamina < 0 then
		local szMsg = FormatString(g_tStrings.STR_CRAFT_COST_STAMINA_ENTER, -nDeltaStamina)
        ChatData.Append(szMsg, 0, PLAYER_TALK_CHANNEL.SYSTEM_NOTICE, false, "")
	elseif nDeltaStamina > 0 then
		local szMsg = FormatString(g_tStrings.STR_CRAFT_ADD_STAMINA_ENTER, nDeltaStamina)
        ChatData.Append(szMsg, 0, PLAYER_TALK_CHANNEL.SYSTEM_NOTICE, false, "")
	end

	if nDeltaThew < 0 then
		local szMsg = FormatString(g_tStrings.STR_CRAFT_COST_THEW_ENTER, -nDeltaThew)
        ChatData.Append(szMsg, 0, PLAYER_TALK_CHANNEL.SYSTEM_NOTICE, false, "")
	elseif nDeltaThew > 0 then
		local szMsg =  FormatString(g_tStrings.STR_CRAFT_ADD_THEW_ENTER, nDeltaThew)
        ChatData.Append(szMsg, 0, PLAYER_TALK_CHANNEL.SYSTEM_NOTICE, false, "")
	end
end)

-- 精力
Event.Reg(self, "UPDATE_VIGOR", function(nOldVigor)
	if not g_pClientPlayer then return end
    if not ChatData.CheckSystemChannelCanRecvReward("MSG_THEW_STAMINA") then return end

	local nDeltaVigor = g_pClientPlayer.nVigor - nOldVigor
	if nDeltaVigor < 0 then
		local szMsg = FormatString(g_tStrings.STR_CRAFT_COST_VIGOR_ENTER, -nDeltaVigor)
        ChatData.Append(szMsg, 0, PLAYER_TALK_CHANNEL.SYSTEM_NOTICE, false, "")
	elseif nDeltaVigor > 0 then
		local szMsg = FormatString(g_tStrings.STR_CRAFT_ADD_VIGOR_ENTER, nDeltaVigor)
		ChatData.Append(szMsg, 0, PLAYER_TALK_CHANNEL.SYSTEM_NOTICE, false, "")
	end
end)

-- 好感度变化
Event.Reg(self, "PLAYER_ADD_FELLOWSHIP_ATTRACTION", function(szAlliedPlayerName, nAttaction)
    if not szAlliedPlayerName then return end
    if not nAttaction or nAttaction == 0 then return end
    if not ChatData.CheckSystemChannelCanRecvReward("MSG_ATTRACTION") then return end

    local szMsg = nil

    if nAttaction > 0 then
        szMsg = FormatString(g_tStrings.ADD_FELLOWSHIP_ATTRACTION, GBKToUTF8(szAlliedPlayerName), nAttaction)
    elseif nAttaction < 0 then
        szMsg = FormatString(g_tStrings.REDUCE_FELLOWSHIP_ATTRACTION, GBKToUTF8(szAlliedPlayerName), -nAttaction)
    end

    if szMsg then
        ChatData.Append(szMsg, 0, PLAYER_TALK_CHANNEL.SYSTEM_NOTICE, false, "")
    end
end)

-- 好感度 下降
Event.Reg(self, "PLAYER_FELLOWSHIP_ATTRACTION_FALL_OFF", function()
    if not ChatData.CheckSystemChannelCanRecvReward("MSG_ATTRACTION") then return end

    local szMsg = g_tStrings.FELLOWSHIP_ATTRACTION_FALL_OFF
    ChatData.Append(szMsg, 0, PLAYER_TALK_CHANNEL.SYSTEM_NOTICE, false, "")
end)

-- 称号 获得
Event.Reg(self, "DESIGNATION_ANNOUNCE", function(szRoleName, nPrefix, nPostfix, nByType)
    if not g_pClientPlayer then return end
    if not ChatData.CheckSystemChannelCanRecvReward("MSG_DESGNATION") then return end

    local szMsg = nil
    local bIsSelf = g_pClientPlayer.szName == szRoleName
    local szName = bIsSelf and g_tStrings.STR_YOU or string.format("[%s]", GBKToUTF8(szRoleName))
    local dwForceID = bIsSelf and g_pClientPlayer.dwForceID or nil

	if nPrefix ~= 0 then
		local aDesignation = Table_GetDesignationPrefixByID(nPrefix, dwForceID)
		if aDesignation then
			local aInfo = GetDesignationPrefixInfo(nPrefix)
			local bWorld = aInfo.nType == DESIGNATION_PREFIX_TYPE.WORLD_DESIGNATION
			local bCampTitle = aInfo.nType == DESIGNATION_PREFIX_TYPE.MILITARY_RANK_DESIGNATION
            local szColor = ItemQualityColor[aDesignation.nQuality + 1] or "#FFFFFF"

            local szLink = ChatHelper.MakeLink_designation(nPrefix, true, dwForceID)
            local szDesignation = string.format("<href=%s><color=%s>[%s]</color></href>", szLink, szColor, GBKToUTF8(aDesignation.szName))

            if bWorld then
                szMsg = string.format("%s获得世界称号%s", szName, szDesignation)
			elseif bCampTitle then
				szMsg = string.format("%s获得战阶称号%s", szName, szDesignation)
			else
				szMsg = string.format("%s获得称号前缀%s", szName, szDesignation)
			end
		end
	end

	if nPostfix ~= 0 then
		local aDesignation = g_tTable.Designation_Postfix:Search(nPostfix)
		if aDesignation then
            local szColor = ItemQualityColor[aDesignation.nQuality + 1] or "#FFFFFF"
            local szLink = ChatHelper.MakeLink_designation(nPostfix, false, dwForceID)
            local szDesignation = string.format("<href=%s><color=%s>[%s]</color></href>", szLink, szColor, GBKToUTF8(aDesignation.szName))

            szMsg = string.format("%s获得称号后缀%s", szName, szDesignation)
		end
	end

    if szMsg then
        ChatData.Append(szMsg, 0, PLAYER_TALK_CHANNEL.SYSTEM_NOTICE, false, "")

        if bIsSelf then
            TipsHelper.ShowNormalTip(szMsg, true)
        end
    end
end)

-- 称号 失去
Event.Reg(self, "REMOVE_DESIGNATION", function(nPrefix, nPostfix)
    if not g_pClientPlayer then return end
    if not ChatData.CheckSystemChannelCanRecvReward("MSG_DESGNATION") then return end

    local szMsg = nil
    local szName = g_tStrings.STR_YOU
    local dwForceID = g_pClientPlayer.dwForceID

    if nPrefix ~= 0 then
        local aDesignation = Table_GetDesignationPrefixByID(nPrefix, dwForceID)
		if aDesignation then
			local aInfo = GetDesignationPrefixInfo(nPrefix)
			local bWorld = aInfo.nType == DESIGNATION_PREFIX_TYPE.WORLD_DESIGNATION
			local bCampTitle = aInfo.nType == DESIGNATION_PREFIX_TYPE.MILITARY_RANK_DESIGNATION
            local szColor = ItemQualityColor[aDesignation.nQuality + 1] or "#FFFFFF"

            local szLink = ChatHelper.MakeLink_designation(nPrefix, true, dwForceID)
            local szDesignation = string.format("<href=%s><color=%s>[%s]</color></href>", szLink, szColor, GBKToUTF8(aDesignation.szName))

			if bWorld then
                szMsg = string.format("%s失去了世界称号%s", szName, szDesignation)
			elseif bCampTitle then
				szMsg = string.format("%s失去了战阶称号%s", szName, szDesignation)
			else
				szMsg = string.format("%s失去了称号前缀%s", szName, szDesignation)
			end
		end
	end

	if nPostfix ~= 0 then
		local aDesignation = g_tTable.Designation_Postfix:Search(nPostfix)
		if aDesignation then
            local szColor = ItemQualityColor[aDesignation.nQuality + 1] or "#FFFFFF"
            local szLink = ChatHelper.MakeLink_designation(nPostfix, false, dwForceID)
            local szDesignation = string.format("<href=%s><color=%s>[%s]</color></href>", szLink, szColor, GBKToUTF8(aDesignation.szName))
			szMsg = string.format("%s失去了称号后缀%s", szName, szDesignation)
		end
	end

    if szMsg then
        ChatData.Append(szMsg, 0, PLAYER_TALK_CHANNEL.SYSTEM_NOTICE, false, "")
    end
end)

-- 成就
Event.Reg(self, "ACHIEVEMENT_ANNOUNCE", function(szRoleName, nByType, nAchievementID)
    if not g_pClientPlayer then return end
    if not ChatData.CheckSystemChannelCanRecvReward("MSG_ACHIEVEMENT") then return end
    if g_pClientPlayer.szName ~= szRoleName and nAchievementID >= 5085 and nAchievementID <= 5108 then return end
    if Table_IsNoAnnounceAchievement(nAchievementID) then return end

    local aAchievement = g_tTable.Achievement:Search(nAchievementID)
	if aAchievement and aAchievement.nVisible ~= 0 then
		local szName = GBKToUTF8(aAchievement.szName)
        local szColor = UI_Chat_Color.Achievement
        local szLink = ChatHelper.MakeLink_achievement(nAchievementID)
        szAchievement = string.format("<href=%s><color=%s>[%s]</color></href>", szLink, szColor, szName)
        local szNameLink = (g_pClientPlayer.szName == szRoleName) and "你" or GBKToUTF8(ChatHelper.DecodeTalkData_name({name = szRoleName}))
        local szMsg = string.format("%s 完成了隐元秘鉴 %s", szNameLink, szAchievement)
        ChatData.Append(szMsg, 0, PLAYER_TALK_CHANNEL.SYSTEM_NOTICE, false, "")
	end
end)

--成就进度提示
local function ShowAchievementProgress(nAchievementID)
    local hPlayer = GetClientPlayer()

    if not hPlayer then
        return
    end

    local nAchiID      = nAchievementID
    local tAchievement = g_tTable.Achievement:Search(nAchiID)

    if not tAchievement then
        return
    end

    if not tAchievement.bShowGetNew then
        return
    end

    local szSeries = tAchievement.szSeries
    if szSeries and szSeries ~= "" then
        local tList        = SplitString(szSeries, "|")
        local nNotFinishID = 0
        for j, s in ipairs(tList) do
            local bFinish = hPlayer.IsAchievementAcquired(s)
            if not bFinish then
                nNotFinishID = tonumber(s)
                break
            end
        end
        if not nNotFinishID then
            nNotFinishID = tonumber(tList[#tList])
        end
        nAchiID      = nNotFinishID
        tAchievement = g_tTable.Achievement:Search(nNotFinishID)
    end

    local szCounters = tAchievement.szCounters
    local tList      = SplitString(szCounters, "|")
    if szCounters and szCounters ~= "" then
        local dwCounter = tonumber(tList[1])
        local tCounter  = g_tTable.AchievementCounter:Search(dwCounter)
        if tCounter then
            local nTotalValue = Table_GetAchievementInfo(dwCounter) or 0
            local nCurValue   = AchievementData.GetAchievementCount(dwCounter)
            if nCurValue ~= nTotalValue then
                --local szFont    = GetMsgFontString("MSG_SYS")
                --local szLink    = MakeAchievementLink("[" .. tAchievement.szName .. "]", szFont, nAchiID)
                --local szLinkMsg = FormatLinkString(g_tStrings.STR_ACHIEVEMENT_NOTICE, szFont, szLink, nCurValue, nTotalValue)
                local szName        = UIHelper.GBKToUTF8(tAchievement.szName)
                local szColor       = UI_Chat_Color.Achievement
                local szLink        = ChatHelper.MakeLink_achievement(nAchievementID)
                local szAchievement = string.format("<href=%s><color=%s>[%s]</color></href>", szLink, szColor, szName)
                local szLinkMsg     = string.format("%s：%d/%d\n", szAchievement, nCurValue, nTotalValue)

                ChatData.Append(ParseTextHelper.ParseNormalText(szLinkMsg), 0, PLAYER_TALK_CHANNEL.SYSTEM_NOTICE, false, "")--策划要求只发聊天，不弹tip
            end
        end
    end
end

Event.Reg(self, "UPDATE_ACHIEVEMENT_COUNT", ShowAchievementProgress)

-- 新增子成就完成提示
Event.Reg(self, "NEW_ACHIEVEMENT", function(nAchiID)
    local hPlayer = GetClientPlayer()
	if not hPlayer then
		return
	end

	if hPlayer.nLevel <= 101 then
		return
	end

	local tAchievement = g_tTable.Achievement:Search(nAchiID)
	if not tAchievement then
		return
	end

	if not tAchievement.bShowGetNew then
		return
	end

	local szSeries = tAchievement.szSeries
	if szSeries and szSeries ~= "" then
		local tList = SplitString(szSeries, "|")
		local nNotFinishID = 0
		for j, s in ipairs(tList) do
			local bFinish 	= hPlayer.IsAchievementAcquired(s)
			if not bFinish then
				nNotFinishID = tonumber(s)
				break
			end
		end
		if not nNotFinishID then
			nNotFinishID = tonumber(tList[#tList])
		end
		nAchiID 		= nNotFinishID
		tAchievement 	= g_tTable.Achievement:Search(nNotFinishID)
	end

	--子成就
	local _, _, _, _ ,_ , dwShiftID = Table_GetAchievementInfo(nAchiID)
	if dwShiftID and dwShiftID ~= 0 then
		local tParentAchievement = g_tTable.Achievement:Search(dwShiftID)
		if not tParentAchievement then
			return
		end

		local szSubAchievements = tParentAchievement.szSubAchievements
		if szSubAchievements and szSubAchievements ~= "" then
			local nFinshed = 0
			local nTotal = 0
			for s in string.gmatch(szSubAchievements, "%d+") do
				local dwSubAchievement 	= tonumber(s)
				local aSubAchievement 	= Table_GetAchievement(dwSubAchievement)
				if aSubAchievement then
					nTotal = nTotal + 1
					if hPlayer.IsAchievementAcquired(dwSubAchievement) then
						nFinshed = nFinshed + 1
					end
				end
			end

            local szName        = UIHelper.GBKToUTF8(tParentAchievement.szName)
            local szColor       = UI_Chat_Color.Achievement
            local szLink        = ChatHelper.MakeLink_achievement(dwShiftID)
            local szAchievement = string.format("<href=%s><color=%s>[%s]</color></href>", szLink, szColor, szName)
            local szLinkMsg     = string.format("%s：%d/%d, %s(完成)", szAchievement, nFinshed, nTotal, UIHelper.GBKToUTF8(tAchievement.szName))
			OutputMessage("MSG_SYS", szLinkMsg, true)
			--OutputMessage("MSG_ANNOUNCE_YELLOW", szLinkMsg, true)
		end
	end
end)

function ChatCollector.Init()
    local tCurrencyUpdateEvent = Currency_Base.GetCurrencyList()
    for _, szCurrency in ipairs(tCurrencyUpdateEvent) do
        local szEvent = ("UPDATE_" .. szCurrency):upper()
        if szEvent then
            Event.Reg(self, szEvent, function(nOldValue)
                if not g_pClientPlayer then return end
                if not nOldValue then return end

                local szKey = string.format("MSG_%s", string.upper(szCurrency))
                if not ChatData.CheckSystemChannelCanRecvReward(szKey) then return end

                local tCurrencyInfo = Table_GetCurrencyInfoByIndex(szCurrency)
                local szCurrencyName = tCurrencyInfo and UIHelper.GBKToUTF8(tCurrencyInfo.szDescription)

                local nMaxValue = Currency_Base.GetCurrencyMaxNumber(szCurrency)
                local nLimit = Currency_Base.GetCurrencyWeekRemain(szCurrency)
                local nCurrentValue = Currency_Base.GetCurrencyNumber(szCurrency)

                if nCurrentValue > nOldValue and szCurrency == CurrencyType.Contribution then
                    FireUIEvent("CURRENCY_GET", "OnFirstGetContribution")
                end

                if szCurrencyName then
                    OutputCurrencyMessage("MSG_CONTRIBUTE", nOldValue, nCurrentValue, nLimit, nMaxValue, szCurrencyName, 2)
                end
            end)
        end

        szEvent = ("MAX_" .. szCurrency.."_NOTIFY"):upper()
        if szEvent then
            Event.Reg(self, szEvent, function()
                local szKey = string.format("MSG_%s", string.upper(szCurrency))
                if not ChatData.CheckSystemChannelCanRecvReward(szKey) then return end
                
                local tCurrencyInfo = Table_GetCurrencyInfoByIndex(szCurrency)
                local szCurrencyName = tCurrencyInfo and UIHelper.GBKToUTF8(tCurrencyInfo.szDescription)
                local szMsg = FormatString(g_tStrings.STR_CURRENCY_UPDATE_TIP6, szCurrencyName)
                ChatData.Append(szMsg, 0, PLAYER_TALK_CHANNEL.SYSTEM_NOTICE, false, "")
            end)
        end
    end
end





-- -----------------------------------------------------------------------------
-- Msg Collector without chat setting
-- -----------------------------------------------------------------------------
-- 佟仁银票
Event.Reg(self, "ON_COIN_SHOP_VOUCHER_CHANGED", function(dwVoucherID, nCreateTime, nCount)
    local nNow = CurrencyData.GetCurCurrencyCount(CurrencyType.CoinShopVoucher) or 0
    local nDelta = nNow - (ChatCollector.nLastVoucher or nNow)
    local szMsg = ""

    if nDelta > 0 then
        szMsg = string.format("你获得：佟仁银票 %d", nDelta)
        ChatData.Append(szMsg, 0, PLAYER_TALK_CHANNEL.SYSTEM_NOTICE, false, "")
    end

    ChatCollector.nLastVoucher = nNow
end)

-- 通宝
Event.Reg(self, "SYNC_COIN", function()
    local nNow = CurrencyData.GetCurCurrencyCount(CurrencyType.Coin)
    local nDelta = nNow - (ChatCollector.nLastCoin or nNow)
    local szMsg = ""

    if nDelta > 0 then
        szMsg = string.format("你获得：通宝 %d", nDelta)
        ChatData.Append(szMsg, 0, PLAYER_TALK_CHANNEL.SYSTEM_NOTICE, false, "")
    end

    ChatCollector.nLastCoin = nNow
end)

-- 战阶积分
Event.Reg(self, "TITLE_POINT_UPDATE", function(nNewTitlePoint, nAddTitlePoint)
    local szMsg = FormatString(g_tStrings.TITLE_POINT_ADD, nAddTitlePoint)
    ChatData.Append(szMsg, 0, PLAYER_TALK_CHANNEL.SYSTEM_NOTICE, false, "")
end)

-- 好友上线 下线
Event.Reg(self, "PLAYER_FELLOWSHIP_LOGIN", function(bOnLine, szName, bFoe, bFeud)
    if szName == "----" then
		return
	end

    local szNameLink = "<text>text=\"["..GBKToUTF8(szName).."]\"</text>"

	if bFoe then
		if bOnLine then
            local szMsg = FormatString(g_tStrings.SRT_MSG_ENEMY_ONLINE, szNameLink)
            szMsg = ParseTextHelper.ParseNormalText(szMsg, true)
            ChatData.Append(szMsg, 0, PLAYER_TALK_CHANNEL.SYSTEM_NOTICE, false, "")
		else
            local szMsg = FormatString(g_tStrings.SRT_MSG_ENEMY_OFFLINE, szNameLink)
            szMsg = ParseTextHelper.ParseNormalText(szMsg, true)
            ChatData.Append(szMsg, 0, PLAYER_TALK_CHANNEL.SYSTEM_NOTICE, false, "")
		end
	elseif bFeud then
		if bOnLine then
            local szMsg = FormatString(g_tStrings.SRT_MSG_FEUD_ONLINE, szNameLink)
            szMsg = ParseTextHelper.ParseNormalText(szMsg, true)
            ChatData.Append(szMsg, 0, PLAYER_TALK_CHANNEL.SYSTEM_NOTICE, false, "")
		else
            local szMsg = FormatString(g_tStrings.SRT_MSG_FEUD_OFFLINE, szNameLink)
            szMsg = ParseTextHelper.ParseNormalText(szMsg, true)
            ChatData.Append(szMsg, 0, PLAYER_TALK_CHANNEL.SYSTEM_NOTICE, false, "")
		end
	else
		if bOnLine then
            local szMsg = FormatString(g_tStrings.STR_MSG_PARTYMEMBER_ONLINE, szNameLink)
            szMsg = ParseTextHelper.ParseNormalText(szMsg, true)
            ChatData.Append(szMsg, 0, PLAYER_TALK_CHANNEL.SYSTEM_NOTICE, false, "")
            PlaySound(SOUND.UI_SOUND, g_sound.Friend)
		else
            local szMsg = FormatString(g_tStrings.STR_MSG_PARTYMEMBER_OFFLINE, szNameLink)
            szMsg = ParseTextHelper.ParseNormalText(szMsg, true)
            ChatData.Append(szMsg, 0, PLAYER_TALK_CHANNEL.SYSTEM_NOTICE, false, "")
		end
	end
end)


-- ------------------- 帮会相关消息 - 开始 -------------------

local g2u = UIHelper.GBKToUTF8

local _sendTongMessage = function(szMessage)
    ChatData.Append(szMessage, 0, PLAYER_TALK_CHANNEL.SYSTEM_NOTICE, false, "")
end

Event.Reg(self, "TONG_STATE_CHANGE", function(nTongState)
    --！！这里请自行改成枚举变量检查，对应枚举已经导出了
    local szMessage
    if nTongState == TONG_STATE.DISBAND then
        szMessage = g_tStrings.STR_GUILD_STATE_DISBAND
    elseif nTongState == TONG_STATE.NORMAL then
        szMessage = g_tStrings.STR_GUILD_STATE_NORMAL
    elseif nTongState == TONG_STATE.TRIAL then
        szMessage = g_tStrings.STR_GUILD_STATE_TRIAL
    end
    if szMessage then
        _sendTongMessage(szMessage)
    end
end)

Event.Reg(self, "TONG_GROUP_RIGHT_CHANGE", function(szGroupName)
    _sendTongMessage(FormatString(g_tStrings.STR_GUILD_ACCESS_CHANGED, g2u(szGroupName)))
end)

Event.Reg(self, "TONG_GROUP_NAME_CHANGE", function(szOldGroupName, szNewGroupName)
    _sendTongMessage(FormatString(g_tStrings.STR_GUILD_NAME_CHANGED, g2u(szOldGroupName), g2u(szNewGroupName)))
end)

Event.Reg(self, "TONG_GROUP_WAGE_CHANGE", function()
    -- note: dx这个事件对应的处理函数实际不存在，这里备注下
    --self.OnTongGroupWageChange(arg0, arg1)
end)

Event.Reg(self, "TONG_MEMBER_JOIN", function(szMemberName)
    --OutputMessage("MSG_SYS", FormatLinkString(g_tStrings.STR_GUILD_OTHER_JION, szFont, MakeNameLink("["..szMemberName.."]", szFont)), true)
    _sendTongMessage(string.format("[帮会][%s]加入了本帮会。", g2u(szMemberName)))
end)

Event.Reg(self, "TONG_MEMBER_QUIT", function(szMemberName)
    --OutputMessage("MSG_SYS", FormatLinkString(g_tStrings.STR_GUILD_OTHER_QUIT, szFont, MakeNameLink("["..szMemberName.."]", szFont)), true)
    _sendTongMessage(string.format("[帮会][%s]退出了本帮会。", g2u(szMemberName)))
end)

Event.Reg(self, "TONG_MEMBER_CHANGE_GROUP", function(szMemberName, szOldGroupName, szNewGroupName)
    --OutputMessage("MSG_SYS", FormatLinkString(g_tStrings.STR_GUILD_CHANGE_GROUP, szFont, MakeNameLink("["..szMemberName.."]", szFont), szOldGroupName, szNewGroupName), true)
    _sendTongMessage(string.format("[帮会][%s]由[%s]转为[%s]。", g2u(szMemberName), g2u(szOldGroupName), g2u(szNewGroupName)))
end)

for _, szEvent in ipairs({"TONG_MASTER_CHANGE", "TONG_MASTER_CHANGE_START", "TONG_MASTER_CHANGE_CANCEL"}) do
    Event.Reg(self, szEvent, function(szOldMasterName, szNewMasterName)
        local hTongClient = GetTongClient()
        hTongClient.ApplyTongInfo()
        local szMsg = ""
        if szEvent == "TONG_MASTER_CHANGE_START" then
            --szMsg = FormatLinkString(
            --        g_tStrings.STR_GUILD_CHANGE_MASTER_START,
            --        szFont,
            --        MakeNameLink("["..szOldMasterName.."]", szFont),
            --        MakeNameLink("["..szNewMasterName.."]", szFont)
            --)
            szMsg = string.format(
                    "[帮会]帮主[%s]已发起帮主权限转交申请，七日后[%s]将正式成为帮主。",
                    g2u(szOldMasterName),
                    g2u(szNewMasterName)
            )
        elseif szEvent == "TONG_MASTER_CHANGE_CANCEL" then
            --szMsg = FormatLinkString(
            --        g_tStrings.STR_GUILD_CHANGE_MASTER_CANCEL,
            --        szFont,
            --        MakeNameLink("["..szOldMasterName.."]", szFont)
            --)
            szMsg = string.format(
                    "[帮会]帮主权限转交申请已被取消，现在帮主为[%s]",
                    g2u(szOldMasterName)
            )
        elseif szEvent == "TONG_MASTER_CHANGE" then
            --szMsg = FormatLinkString(
            --        g_tStrings.STR_GUILD_CHANGE_MASTER,
            --        szFont,
            --        MakeNameLink("["..szOldMasterName.."]", szFont),
            --        MakeNameLink("["..szNewMasterName.."]", szFont)
            --)
            szMsg = string.format(
                    "[帮会][%s]的帮主权限转交成功，[%s]正式成为帮主。",
                    g2u(szOldMasterName),
                    g2u(szNewMasterName)
            )
        end

        _sendTongMessage(szMsg)
    end)
end

Event.Reg(self, "TONG_CAMP_CHANGE", function(nCamp)
    local szCamp = g_tStrings.STR_CAMP_TITLE[nCamp]
    if szCamp then
        _sendTongMessage(FormatString(g_tStrings.STR_GUILD_CAMP_CHANGED, szCamp))
    end
end)

Event.Reg(self, "CHANGE_TONG_NOTIFY", function(szName, nReason)
    if nReason == TONG_CHANGE_REASON.JOIN then
        OnCheckAddAchievement(836, "TONG|JOIN")
    elseif nReason == TONG_CHANGE_REASON.CREATE then
        OnCheckAddAchievement(837, "TONG|CREATE")
    end

    local szMsg = g_tStrings.STR_TONG_CHANGE_REASON[nReason]
    if szMsg and szMsg ~= "" then
        local szTips = FormatString(szMsg, g2u(szName))
        _sendTongMessage(szTips)
    end

    if nReason == TONG_CHANGE_REASON.CREATE then
        local szTips = g_tStrings.STR_GUILD_STATE_TRIAL
        _sendTongMessage(szTips)
    end
end)

Event.Reg(self, "TONG_MEMBER_FIRED", function(szMemberName)
    --OutputMessage("MSG_SYS", FormatLinkString(g_tStrings.STR_GUILD_OTHER_FIRED, szFont, MakeNameLink("["..szMemberName.."]", szFont)), true)
    _sendTongMessage(string.format("[帮会][%s]被踢出了本帮会。", g2u(szMemberName)))
end)

-- 帮会成员上线
Event.Reg(self, "TONG_MEMBER_LOGIN", function(szMemberName)
    local szMsg = string.format("[帮会][%s]上线了。", g2u(szMemberName))
    _sendTongMessage(szMsg)
end)

-- 帮会成员下线
Event.Reg(self, "TONG_MEMBER_LEAVE", function(szMemberName)
    local szMsg = string.format("[帮会][%s]下线了。", g2u(szMemberName))
    _sendTongMessage(szMsg)
end)

Event.Reg(self, "TONG_GROUP_ENABLED", function(szName)
    _sendTongMessage(FormatString(g_tStrings.STR_GUILD_GROUP_ENABLE, g2u(szName)))
end)

Event.Reg(self, "TONG_MAX_MEMBER_COUNT_CHANGE", function(nCount)
    _sendTongMessage(FormatString(g_tStrings.STR_GUILD_UPDATE_MAX_MEMBER_COUNT, nCount))
end)

-- 帮会资金
Event.Reg(self, "ON_ADD_TONG_FUND_NOTIFY", function(nFund, nAddResource)
    if not ChatData.CheckSystemChannelCanRecvReward("MSG_TONG_FUND") then return end

    if nFund and nFund > 0 then
        local szMsg = g_tStrings.STR_QUEST_CAN_GET_GUILD_MONEY .. nFund
        _sendTongMessage(szMsg)
    end

    if nAddResource and nAddResource > 0 then
        local szMsg = FormatString(g_tStrings.STR_QUEST_CAN_GET_GUILD_RESOURCE, nAddResource)
        _sendTongMessage(szMsg)
    end
end)

-- ------------------- 帮会相关消息 - 结束 -------------------

-- 阵营模式变化
-- Event.Reg(self, "CHANGE_CAMP_FLAG", function(dwPlayerID)
-- 	if not g_pClientPlayer then
-- 	    return
-- 	end

-- 	if g_pClientPlayer.dwID == dwPlayerID then
-- 		if g_pClientPlayer.bCampFlag then
--             ChatData.Append(FormatString(g_tStrings.STR_SYS_MSG_OPEN_CAMP_FALG, g_tStrings.STR_NAME_YOU), 0, PLAYER_TALK_CHANNEL.GM_ANNOUNCE, false, "")
--             OutputMessage("MSG_ANNOUNCE_YELLOW", FormatString(g_tStrings.STR_SYS_MSG_OPEN_CAMP_FALG, g_tStrings.STR_NAME_YOU))
-- 		else
--             ChatData.Append(FormatString(g_tStrings.STR_SYS_MSG_CLOSE_CAMP_FALG, g_tStrings.STR_NAME_YOU), 0, PLAYER_TALK_CHANNEL.GM_ANNOUNCE, false, "")
--             OutputMessage("MSG_ANNOUNCE_YELLOW", FormatString(g_tStrings.STR_SYS_MSG_CLOSE_CAMP_FALG, g_tStrings.STR_NAME_YOU))
-- 		end
-- 	else
-- 		local hPlayer = GetPlayer(dwPlayerID)
-- 		if hPlayer and hPlayer.bCampFlag then
--             ChatData.Append(FormatString(g_tStrings.STR_SYS_MSG_OPEN_CAMP_FALG, UIHelper.GBKToUTF8(hPlayer.szName)), 0, PLAYER_TALK_CHANNEL.GM_ANNOUNCE, false, "")
-- 		else
--             ChatData.Append(FormatString(g_tStrings.STR_SYS_MSG_CLOSE_CAMP_FALG, UIHelper.GBKToUTF8(hPlayer.szName)), 0, PLAYER_TALK_CHANNEL.GM_ANNOUNCE, false, "")
-- 		end
-- 	end
-- end)

-- 任务 接受
Event.Reg(self, "QUEST_ACCEPTED", function(nQuestIndex, dwQuestID)
    if not dwQuestID then
        return
    end

    local tQuestStringInfo = Table_GetQuestStringInfo(dwQuestID)
    if tQuestStringInfo.IsAdventure == 1 then
        return
    end

    local szQuestName = GBKToUTF8(ChatHelper.DecodeTalkData_quest({questid = dwQuestID}, nil))
    local szMsg = g_tStrings.MSG_ACCEPT_QUEST..szQuestName..g_tStrings.STR_FULL_STOP
    ChatData.Append(szMsg, 0, PLAYER_TALK_CHANNEL.SYSTEM_NOTICE, false, "")
end)

-- 任务 接受援助
Event.Reg(self, "QUEST_ASSISTED", function(nQuestID, szNewbieName)
    if not nQuestID or not szNewbieName then
        return
    end

    local szTitle = FormatString(g_tStrings.MSG_ASSIST_QUEST, szNewbieName)
    local szQuestName = GBKToUTF8(ChatHelper.DecodeTalkData_quest({questid = nQuestID}, nil))
    local szMsg = szTitle..szQuestName..g_tStrings.STR_FULL_STOP
	ChatData.Append(szMsg, 0, PLAYER_TALK_CHANNEL.SYSTEM_NOTICE, false, "")
end)

-- 任务 失败
Event.Reg(self, "QUEST_FAILED", function(nQuestIndex)
    if not g_pClientPlayer then
        return
    end

    local dwQuestID = g_pClientPlayer.GetQuestID(nQuestIndex)
    if not dwQuestID then
        return
    end

    local szQuestName = GBKToUTF8(ChatHelper.DecodeTalkData_quest({questid = dwQuestID}, nil))
    local szMsg = g_tStrings.MSG_QUEST_YOU..szQuestName..g_tStrings.MSG_QUEST_FAIL
    OutputMessage("MSG_SYS", szMsg, true)

    local tQuestStringInfo = Table_GetQuestStringInfo(dwQuestID)
    OutputMessage("MSG_ANNOUNCE_RED", FormatString(g_tStrings.MSG_QUEST_FAILED, UIHelper.GBKToUTF8(tQuestStringInfo.szName)))
end)

-- 任务 取消
Event.Reg(self, "QUEST_CANCELED", function(dwQuestID)
    if not dwQuestID then
        return
    end

    local szQuestName = GBKToUTF8(ChatHelper.DecodeTalkData_quest({questid = dwQuestID}, nil))
    local szMsg = g_tStrings.MSG_QUEST_ABANDON..szQuestName..g_tStrings.STR_FULL_STOP
    ChatData.Append(szMsg, 0, PLAYER_TALK_CHANNEL.SYSTEM_NOTICE, false, "")
end)

-- 任务 完成
Event.Reg(self, "QUEST_FINISHED", function(dwQuestID, bForceFinish, bAssist, nAddStamina, nAddThew)
    if bForceFinish == 0 then
        local tQuestStringInfo = Table_GetQuestStringInfo(dwQuestID)
        if tQuestStringInfo.IsAdventure == 1 or tQuestStringInfo.bShieldFinishEffect then
            return
        end

        local szQuestName = GBKToUTF8(ChatHelper.DecodeTalkData_quest({questid = dwQuestID}, nil))

        if bAssist then
            --ShowFullScreenSFX("FinishAssistQuest")
            local szMsg = g_tStrings.FINISH_ASSIST_QUEST..szQuestName..g_tStrings.STR_FULL_STOP
            OutputMessage("MSG_SYS", szMsg, true)
        else
            --ShowFullScreenSFX("FinishQuest")
            local szMsg = g_tStrings.MSG_QUEST_FINISH..szQuestName..g_tStrings.STR_FULL_STOP
            OutputMessage("MSG_SYS", szMsg, true)
        end
    end
end)



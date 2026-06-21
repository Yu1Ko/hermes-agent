ChatHelper = ChatHelper or {className = "ChatHelper"}
local self = ChatHelper


-- 密聊
function ChatHelper.WhisperTo(szName, tbData, bRecent)
    if string.is_nil(szName) then
        return
    end

    if not bRecent then
        szName = UTF8ToGBK(szName)
        szName = RoomData.GetGlobalName(szName, tbData and tbData.dwCenterID)
        szName = GBKToUTF8(szName)
    end

    ChatRecentMgr.SetCurWhisperPlayerName(szName)

    tbData.szName = szName
    ChatData.AddWhisper(szName, tbData)

    UIMgr.Close(VIEW_ID.PanelFriendRecommendPop)
    UIMgr.Close(VIEW_ID.PanelChatSocialWhisper)

    ChatHelper.Chat(UI_Chat_Channel.Whisper)
end

-- 侠缘，AI NPC 对话
function ChatHelper.ChatAINpcTo(dwID)
    if not dwID then
        return
    end

    ChatAINpcMgr.PrivacyPop(function()
        ChatAINpcMgr.SetCurAINpcID(dwID)
        ChatAINpcMgr.AddToRecentList(dwID)

        ChatHelper.Chat(UI_Chat_Channel.AINpc)
    end)
end

function ChatHelper.Chat(szUIChannel, szSendContent)
    local nChatIndex = 1
    local script = UIMgr.GetViewScript(VIEW_ID.PanelChatSocial)
    if script then
        script:Select(nChatIndex)
        local chatScript = script.tbScripts[nChatIndex]
        if chatScript then
            if szUIChannel == nil then
                szUIChannel = chatScript:GetCurUIChannel()
            end
            chatScript:SelectChannel(szUIChannel, szSendContent)
            if szUIChannel == UI_Chat_Channel.Whisper then
                chatScript:EnterInputMode()
            end
        end
    else
        local script = UIMgr.Open(VIEW_ID.PanelChatSocial, nChatIndex, szUIChannel, szSendContent)
        if script then
            local chatScript = script.tbScripts[nChatIndex]
            if chatScript then
                if szUIChannel == UI_Chat_Channel.Whisper then
                    chatScript:EnterInputMode()
                end
            end
        end
    end

end

function ChatHelper.ConvertChatTime(nTime, bOnlyTime, bWithBrackets)
    local szTime = ""
    local tTime = TimeToDate(nTime)
    if tTime then
        if bOnlyTime then
            szTime = string.format("%02d:%02d:%02d", tTime["hour"], tTime["minute"], tTime["second"])
        else
            szTime = string.format("%d/%d/%s %02d:%02d:%02d", tTime["year"], tTime["month"], tTime["day"], tTime["hour"], tTime["minute"], tTime["second"])
        end

        if bWithBrackets then
            szTime = string.format("[%s]", szTime)
        end
    end
    return szTime
end



function OutputCurrencyMessage(szMsgType, nOldValue, nCurrentValue, nLimit, nMaxValue, szCurrency, tipType)
	--FireUIEvent("CURRENCY_VALUE_UPDATE")
    local szMsg = nil

	if nOldValue > nCurrentValue then
		if tipType == 1 then
			szMsg = FormatString(g_tStrings.STR_CURRENCY_UPDATE_TIP1, nOldValue - nCurrentValue, szCurrency)
		elseif tipType == 2 then
			szMsg = FormatString(g_tStrings.STR_CURRENCY_UPDATE_TIP2, nOldValue - nCurrentValue, szCurrency)
		end

	elseif nOldValue < nCurrentValue then
		if tipType == 1 then
			szMsg = FormatString(g_tStrings.STR_CURRENCY_UPDATE_TIP3, nCurrentValue - nOldValue, szCurrency)
		elseif tipType == 2 then
			szMsg = FormatString(g_tStrings.STR_CURRENCY_UPDATE_TIP4, nCurrentValue - nOldValue, szCurrency)
		end
	end

	if nLimit == 0 and nOldValue <= nCurrentValue then
		szMsg = FormatString(g_tStrings.STR_CURRENCY_UPDATE_TIP5, szCurrency)
	end

    if szMsg then
        ChatData.Append(szMsg, 0, PLAYER_TALK_CHANNEL.SYSTEM_NOTICE, false, "")
    end
end















Event.Reg(self, EventType.OnRichTextOpenUrl, function(szUrl, node)
    if UIMgr.IsOpening() then return end
    if string.is_nil(szUrl) then return end

    -- print("QH, szUrl = "..szUrl)
    -- 原来是Bae64，但是发现Base64有如下这种字符串，cocos的richtext显示不了，所以改成UrlDecode
    -- "<href=eyJuYW1lIjoi6JOd6Zif6Zif6ZW/5ZWK5ZWKMUDpvpnkuonomY7mlpciLCJ0eXBlIjoibmFtZSJ9><color=#ffe26e>[蓝队队长啊啊1@龙争虎斗]</color></href>"
    szUrl = UrlDecode(szUrl)

    if szUrl then
        local tbLinkData = JsonDecode(szUrl)
        if not tbLinkData then return end

        local szType = tbLinkData.type or ""
        local szFuncName = "HandleLink_"..szType
        local func = ChatHelper[szFuncName]
        if IsFunction(func) then
            -- 点击响应之后，应该删掉之前的tips
            TipsHelper.DeleteAllHoverTips()

            func(tbLinkData, node)

            ChatData.SetCanShowChatCopyTips(false)
            Timer.DelTimer(self, self.nLinkClickTimerID)
            self.nLinkClickTimerID = Timer.Add(self, 0.2, function()
                ChatData.SetCanShowChatCopyTips(true)
            end)
        end
    end
end)

function ChatHelper._getChatPanelTipsNode(node)
    local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelChatSocial)
    return scriptView and scriptView.BtnClose or node
end

--------------------------------------------------------------------------------
-- Decode
--------------------------------------------------------------------------------
function ChatHelper.DecodeTalkData(tbData, dwTalkerID, nChannel)
    local bResult = false
    local szResult = ""
    local szType = tbData.type or ""
    local szFuncName = "DecodeTalkData_"..szType
    local func = ChatHelper[szFuncName]
    if IsFunction(func) then
        szResult = func(tbData, dwTalkerID, nChannel)
        bResult = true
    else
        szResult = tbData.text or ""
    end
    return bResult, szResult
end


function ChatHelper.DecodeTalkData_text(tbData, dwTalkerID)
    -- 端游自动回复的前缀
    if tbData.text == "afk" or tbData.text == "atr" then
        tbData.text = ""
    end

    -- 2024-12-21 过滤富文本
    tbData.text = UIHelper.RichTextEscape(tbData.text)

    -- 2024-12-21 临时处理过滤size，避免宕机
    -- local tbParser = labelparser.parse(tbData.text)
    -- if tbParser then
    --     for k, v in ipairs(tbParser) do
    --         if v.size or v.color then
    --             return ""
    --         end
    --     end
    -- end

    return tbData.text
end

-- GCCommand("SendGmAnnounce('GM公告：天啦噜，运营同学开始发钱啦！<HyperLink>点击查看详情\\\\thttps://jx3.xoyo.com/master2018/live.html</HyperLink>快来看看啊！', 1)")
function ChatHelper.DecodeTalkData_HyperLink(tbData, dwTalkerID, nChannel)
    local szResult = ""

    if not tbData or string.is_nil(tbData.text) then
        return
    end

    local tbParser = labelparser.parse(tbData.text)
    if tbParser then
        for k, v in ipairs(tbParser) do
            if v.labelname == "hyperlink" or v.labelname == "<hyperlink>" or string.match(v.labelname, "<hyperlink>") then
                local tbArgs = string.split(v.content, "\\t") or {}
                local szColor = UI_Chat_Color.Hyperlink
                local szLink = ChatHelper.MakeLink_hyperlink(tbArgs and tbArgs[2] or "")
                szResult = szResult .. string.format("<href=%s><color=%s>[%s]</color></href>", szLink, szColor, (tbArgs[1] or ""))
            else
                szResult = szResult .. v.content
            end
        end
    end

    return szResult
end

function ChatHelper.DecodeTalkData_name(tbData)
    if not tbData then return end

    local szName = tbData.name
    local szLink = ChatHelper.MakeLink_name(tbData)
    local szColor = UI_Chat_Color.Name
    local szResult = string.format("<href=%s><color=%s>[%s]</color></href>", szLink, szColor, szName)

    return szResult
end

function ChatHelper.DecodeTalkData_item(tbData, dwTalkerID)
    local dwItemID = tbData.item
    local item = g_pClientPlayer and g_pClientPlayer.GetTalkLinkItem(dwItemID)
    local szColor = item and ItemQualityColor[item.nQuality + 1] or "#FFFFFF"
    local szItemName = item and ItemData.GetItemNameByItem(item) or ""
    local szLink = ChatHelper.MakeLink_item(dwItemID)

    local szResult = string.format("<href=%s><color=%s>[%s]</color></href>", szLink, szColor, szItemName)
    if string.is_nil(szItemName) then
        szResult = string.format("<href=%s><color=%s>%s</color></href>", szLink, szColor, tbData.text)
    end

    return szResult
end

function ChatHelper.DecodeTalkData_iteminfo(tbData, dwTalkerID)
    local nVersion = tbData.version
    local nTabtype = tonumber(tbData.tabtype)
    local nIndex = tonumber(tbData.index)

    local itemInfo = ItemData.GetItemInfo(nTabtype, nIndex)
    local szItemName = ItemData.GetItemNameByItemInfo(itemInfo)
    local szColor = itemInfo and ItemQualityColor[itemInfo.nQuality + 1] or "#FFFFFF"
    local szLink = ChatHelper.MakeLink_iteminfo(nVersion, nTabtype, nIndex)
    local szResult = string.format("<href=%s><color=%s>[%s]</color></href>", szLink, szColor, szItemName)

    return szResult
end

function ChatHelper.DecodeTalkData_quest(tbData, dwTalkerID)
    local nQuestID = tbData.questid

    local tbQuestConf = QuestData.GetQuestConfig(nQuestID)
    local szQuestName = tbQuestConf and tbQuestConf.szName or ""
    local szColor = "#FFFFFF"
    local szLink = ChatHelper.MakeLink_quest(nQuestID)
    local szResult = string.format("<href=%s><color=%s>[%s]</color></href>", szLink, szColor, szQuestName)

    return szResult
end

function ChatHelper.DecodeTalkData_recipe(tbData, dwTalkerID)
    local nCraftID = tbData.craftid
    local nRecipeID = tbData.recipeid

    local recipe = GetRecipe(nCraftID, nRecipeID)
	local szRecipeName = Table_GetRecipeName(nCraftID, nRecipeID)
    local szColor = "#FFFFFF"
    local szLink = ChatHelper.MakeLink_recipe(nQuestID)
    local szResult = string.format("<href=%s><color=%s>[%s]</color></href>", szLink, szColor, szRecipeName)

    return szResult
end

function ChatHelper.DecodeTalkData_enchant(tbData, dwTalkerID)
    local nProID = tbData.proid
    local nCraftID = tbData.craftid
    local nRecipeID = tbData.recipeid

    local szResult = ""
    local szName = Table_GetEnchantName(nProID, nCraftID, nRecipeID)
	local nQuality = Table_GetEnchantQuality(nProID, nCraftID, nRecipeID)
    if szName then
        local szColor = "#FFFFFF" -- GetItemFontColorByQuality(nQuality, true)
        local szLink = ChatHelper.MakeLink_enchant(nProID, nCraftID, nRecipeID)
        szResult = string.format("<href=%s><color=%s>[%s]</color></href>", szLink, szColor, szName)
    end

    return szResult
end

function ChatHelper.DecodeTalkData_skill(tbData, dwTalkerID)
    local nSkillID = tbData.skill_id
    local nSkillLevel = tbData.skill_level

    local szSkillName = Table_GetSkillName(nSkillID, nSkillLevel)
    local szColor = "#FFFFFF"
    local szLink = ChatHelper.MakeLink_skill(nSkillID, nSkillLevel)
    local szResult = string.format("<href=%s><color=%s>[%s]</color></href>", szLink, szColor, szSkillName)

    return szResult
end

function ChatHelper.DecodeTalkData_skillrecipe(tbData, dwTalkerID)
    local nID = tbData.id
    local nLevel = tbData.level

    local tSkillRecipe = Table_GetSkillRecipe(nID, nLevel) or {}
	local szSkillRecipeName = tostring(tSkillRecipe.szName)
    local szColor = "#FFFFFF"
    local szLink = ChatHelper.MakeLink_skillrecipe(nID, nLevel)
    local szResult = string.format("<href=%s><color=%s>[%s]</color></href>", szLink, szColor, szSkillRecipeName)

    return szResult
end

function ChatHelper.DecodeTalkData_book(tbData, dwTalkerID)
    local nVersion = tbData.version
    local nTabType = tbData.tabtype
    local nIndex = tbData.index
    local nBookInfo = tbData.bookinfo

    local szResult = ""
    local iteminfo = GetItemInfo(nTabType, nIndex)
    if iteminfo then
        local nBookID, nSegmentID = GlobelRecipeID2BookID(nBookInfo)
        local szBookName = Table_GetSegmentName(nBookID, nSegmentID)
        local nQuality = iteminfo and iteminfo.nQuality or 1
        local szColor = ItemQualityColor[nQuality + 1] or "#FFFFFF"
        local szLink = ChatHelper.MakeLink_book(nVersion, nTabType, nIndex, nBookInfo)
        szResult = string.format("<href=%s><color=%s>[%s]</color></href>", szLink, szColor, szBookName)
    end

    return szResult
end

function ChatHelper.DecodeTalkData_achievement(tbData, dwTalkerID)
    local nAchievementID = tbData.id

    local szResult = ""
    local aAchievement = g_tTable.Achievement:Search(nAchievementID)
    if aAchievement then
        local szName = aAchievement.szName
        local szColor = UI_Chat_Color.Achievement
        local szLink = ChatHelper.MakeLink_achievement(nAchievementID)
        szResult = string.format("<href=%s><color=%s>[%s]</color></href>", szLink, szColor, szName)
    end

    return szResult
end

function ChatHelper.DecodeTalkData_designation(tbData, dwTalkerID)
    local nDesignation = tbData.id
    local bPrefix = tbData.prefix
    local dwForceID = tbData.forceid

    local szResult = ""
    local aDesignation
    if bPrefix then
        aDesignation = Table_GetDesignationPrefixByID(nDesignation, dwForceID)
    else
        aDesignation = g_tTable.Designation_Postfix:Search(nDesignation)
    end
    if aDesignation then
        local szName = aDesignation.szName
        local szColor = ItemQualityColor[aDesignation.nQuality + 1] or "#FFFFFF"
        local szLink = ChatHelper.MakeLink_designation(nDesignation, bPrefix, dwForceID)
        szResult = string.format("<href=%s><color=%s>[%s]</color></href>", szLink, szColor, szName)
    end

    return szResult
end

function ChatHelper.DecodeTalkData_eventlink(tbData, dwTalkerID)
    local szName = tbData.name
    local szLinkInfo = tbData.linkinfo

    local szLink = ChatHelper.MakeLink_eventlink(szName, szLinkInfo)
    local szColor = "#FFFFFF"
    if string.find(szLinkInfo, "TeamBuild/") then
        szColor = UI_Chat_Color.Team
    end
    if string.find(szLinkInfo, "RoomBuild/") or string.find(szLinkInfo, "GlobalRoom/") then
        szColor = UI_Chat_Color.Room
    end
    if string.find(szLinkInfo, "VoiceRoom/") then
        szColor = UI_Chat_Color.VoiceRoom
    end

    local szResult = string.format("<href=%s><color=%s>%s</color></href>", szLink, szColor, szName)

    return szResult
end

function ChatHelper.DecodeTalkData_pet(tbData, dwTalkerID)
    local nPetIndex = tbData.id

    local szResult = ""
    local tPet = Table_GetFellowPet(nPetIndex)
    if tPet then
        local szName = tPet.szName
        local nQuality = tPet.nQuality
        local szColor = ItemQualityColor[nQuality + 1] or "#FFFFFF"
        local szLink = ChatHelper.MakeLink_pet(nPetIndex)
        szResult = string.format("<href=%s><color=%s>[%s]</color></href>", szLink, szColor, szName)
    end

    return szResult
end

function ChatHelper.DecodeTalkData_land(tbData, dwTalkerID)
    local nIndex = tbData.index
    local nMapID = tbData.mapid
    local nCopyIndex = tbData.copyindex
    local nLandIndex = tbData.landindex

    local szName = ""
    if nLandIndex == 0 and GetHomelandMgr() and GetHomelandMgr().IsPrivateHomeMap(nMapID) then
        local tLine = Table_GetPrivateHomeSkin(nMapID, nIndex)
        if tLine and tLine.szSkinName then
            szName = FormatString(g_tStrings.STR_LINK_PRIVATE, GBKToUTF8(tLine.szSkinName))
        end
    else
        szName = Homeland_GetHomeName(nMapID, nLandIndex)
        if szName then
            szName = FormatString(g_tStrings.STR_LINK_LAND, GBKToUTF8(szName), nIndex)
        end
    end

    szName = UTF8ToGBK(szName)

    local szColor = UI_Chat_Color.Land
    local szLink = ChatHelper.MakeLink_land(nIndex, nMapID, nCopyIndex, nLandIndex)
    local szResult = string.format("<href=%s><color=%s>[%s]</color></href>", szLink, szColor, szName)

    return szResult
end

function ChatHelper.DecodeTalkData_gamegift(tbData, dwTalkerID)
    local szOwnerName = tbData.ownername
    local nGiftID = tbData.giftid

    szOwnerName = GBKToUTF8(szOwnerName)

    local szName = FormatString(g_tStrings.STR_RED_GIFT_LINK, szOwnerName)
    local szColor = "#FF0000"
    local szLink = ChatHelper.MakeLink_gamegift(szOwnerName, nGiftID)
    local szResult = string.format("<href=%s><color=%s>%s</color></href>", szLink, szColor, UTF8ToGBK(szName))

    return szResult
end

function ChatHelper.DecodeTalkData_toybox(tbData, dwTalkerID)
    local nID = tbData.id

    local tLine = Table_GetToyBox(nID)
    local szName = tLine.szName
    local szColor = "#FFFFFF"
    local szLink = ChatHelper.MakeLink_toybox(nID)
    local szResult = string.format("<href=%s><color=%s>[%s]</color></href>", szLink, szColor, szName)

    return szResult
end

function ChatHelper.DecodeTalkData_website(tbData, dwTalkerID)
    local szWebsite = tbData.szWebsite
    if string.is_nil(szWebsite) then
        return
    end

    local szName = szWebsite
    local szColor = "#FFFFFF"
    local szLink = ChatHelper.MakeLink_website(nID)
    local szResult = string.format("<href=%s><color=%s>[%s]</color></href>", szLink, szColor, szName)

    return szResult
end

function ChatHelper.DecodeTalkData_landorder(tbData, dwTalkerID)
    local dwID = tbData.id
    local nMoney = tbData.money
    local szPlayerName = tbData.name
    if dwID == 0 then
        return
    end
    local tbOrderInfo = {szName = szPlayerName, dwID = dwID, nMoney = nMoney}
    HomelandIdentity.MarkChatOrder(tbOrderInfo, dwTalkerID)

    local szName = g_tStrings.STR_HOMELAND_ASSIST_ORDER
    local szColor = "#FFFFFF"
    local szLink = ChatHelper.MakeLink_landorder(dwTalkerID)
    local szResult = string.format("<href=%s><color=%s>[%s]</color></href>", szLink, szColor, UTF8ToGBK(szName))

    return szResult
end






--------------------------------------------------------------------------------
-- make&handle link
--------------------------------------------------------------------------------

-- name
function ChatHelper.MakeLink_name(tbData)
    local tbLinkData = {type = "name", name = GBKToUTF8(tbData.name)}
    local szLink = JsonEncode(tbLinkData)
    szLink = UrlEncode(szLink)
    return szLink
end

function ChatHelper.HandleLink_name(tbLinkData, node)
    if not tbLinkData then return end

    local szName = tbLinkData.name

    if not string.is_nil(szName) then
        if g_pClientPlayer and g_pClientPlayer.szName == UTF8ToGBK(szName) then
            return
        end

        ChatTips.ShowSimplePlayerTips(node, szName)

        --TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetCopy, self.BtnTouch, TipsLayoutDir.TOP_CENTER, self.tbChatData)
        -- ChatHelper._getChatPanelTipsNode(node)
        -- ChatTips.ShowPlayerTips(self.scriptHead._rootNode, self.tbChatData)
    end
end


-- hyperlink
function ChatHelper.MakeLink_hyperlink(szUrl)
    local tbLinkData = {type = "hyperlink", url = szUrl}
    local szLink = JsonEncode(tbLinkData)
    szLink = UrlEncode(szLink)
    return szLink
end

function ChatHelper.HandleLink_hyperlink(tbLinkData, node)
    if not tbLinkData then return end

    local szUrl = tbLinkData.url
    if not string.is_nil(szUrl) then
        UIHelper.OpenWebWithDefaultBrowser(szUrl)
    end
end

-- item
function ChatHelper.MakeLink_item(dwItemID)
    local tbLinkData = {type = "item", dwItemID = dwItemID}
    local szLink = JsonEncode(tbLinkData)
    szLink = UrlEncode(szLink)
    return szLink
end

function ChatHelper.HandleLink_item(tbLinkData, node)
    if not tbLinkData then return end

    local dwItemID = tbLinkData.dwItemID
    local item = GetItem(dwItemID)
    if item then
        TipsHelper.ShowItemTipsWithItemID(ChatHelper._getChatPanelTipsNode(node), dwItemID, TipsLayoutDir.RIGHT_CENTER, TipsLayoutDir.RIGHT_CENTER)
    end
end

-- iteminfo
function ChatHelper.MakeLink_iteminfo(nVersion, nTabtype, nIndex)
    local tbLinkData = {type = "iteminfo", nVersion = nVersion, nTabtype = nTabtype, nIndex = nIndex}
    local szLink = JsonEncode(tbLinkData)
    szLink = UrlEncode(szLink)
    return szLink
end

function ChatHelper.HandleLink_iteminfo(tbLinkData, node)
    if not tbLinkData then return end

    local nVersion = tbLinkData.nVersion
    local nTabtype = tbLinkData.nTabtype
    local nIndex = tbLinkData.nIndex

    TipsHelper.ShowItemTips(ChatHelper._getChatPanelTipsNode(node), nTabtype, nIndex, false, TipsLayoutDir.RIGHT_CENTER)
end

-- quest
function ChatHelper.MakeLink_quest(nQuestID)
    local tbLinkData = {type = "quest", nQuestID = nQuestID}
    local szLink = JsonEncode(tbLinkData)
    szLink = UrlEncode(szLink)
    return szLink
end

function ChatHelper.HandleLink_quest(tbLinkData)
    if not tbLinkData then return end

    local nQuestID = tbLinkData.nQuestID
    if nQuestID then
        UIMgr.OpenSingleWithOnEnter(false, VIEW_ID.PanelSentTaskDetails, nQuestID)
    end

    LOG.INFO("HandleLink_quest, nQuestID = "..nQuestID)
end

-- activity
function ChatHelper.MakeLink_activity(nActivityID)
    local tbLinkData = {type = "activity", nActivityID = nActivityID}
    local szLink = JsonEncode(tbLinkData)
    szLink = UrlEncode(szLink)
    return szLink
end

function ChatHelper.HandleLink_activity(tbLinkData)
    if not tbLinkData then return end

    local nActivityID = tbLinkData.nActivityID
    -- LOG.INFO("HandleLink_quest, nQuestID = "..nQuestID)
    ActivityData.LinkToActiveByID(nActivityID)
    UIMgr.Close(VIEW_ID.PanelChatMonitor)
    UIMgr.Close(VIEW_ID.PanelChatSocial)
end

-- recipe
function ChatHelper.MakeLink_recipe(nCraftID, nRecipeID)
    local tbLinkData = {type = "recipe", nCraftID = nCraftID, nRecipeID = nRecipeID}
    local szLink = JsonEncode(tbLinkData)
    szLink = UrlEncode(szLink)
    return szLink
end

function ChatHelper.HandleLink_recipe(tbLinkData)
    if not tbLinkData then return end

    local nCraftID = tbLinkData.nCraftID
    local nRecipeID = tbLinkData.nRecipeID
    LOG.INFO("HandleLink_recipe, nCraftID = %d, nRecipeID = %d", nCraftID, nRecipeID)
end

-- enchant
function ChatHelper.MakeLink_enchant(nProID, nCraftID, nRecipeID)
    local tbLinkData = {type = "enchant", nProID = nProID, nCraftID = nCraftID, nRecipeID = nRecipeID}
    local szLink = JsonEncode(tbLinkData)
    szLink = UrlEncode(szLink)
    return szLink
end

function ChatHelper.HandleLink_enchant(tbLinkData)
    if not tbLinkData then return end

    local nProID = tbLinkData.nProID
    local nCraftID = tbLinkData.nCraftID
    local nRecipeID = tbLinkData.nRecipeID
    LOG.INFO("HandleLink_enchant, nProID = %d, nCraftID = %d, nRecipeID = %d", nProID, nCraftID, nRecipeID)
end

-- skill
function ChatHelper.MakeLink_skill(nSkillID, nSkillLevel)
    local tbLinkData = {type = "skill", nSkillID = nSkillID, nSkillLevel = nSkillLevel}
    local szLink = JsonEncode(tbLinkData)
    szLink = UrlEncode(szLink)
    return szLink
end

function ChatHelper.HandleLink_skill(tbLinkData)
    if not tbLinkData then return end

    local nSkillID = tbLinkData.nSkillID
    local nSkillLevel = tbLinkData.nSkillLevel
    LOG.INFO("HandleLink_skill, nSkillID = %d, nSkillLevel = %d", nSkillID, nSkillLevel)
end

-- skillrecipe
function ChatHelper.MakeLink_skillrecipe(nID, nLevel)
    local tbLinkData = {type = "skillrecipe", nID = nID, nLevel = nLevel}
    local szLink = JsonEncode(tbLinkData)
    szLink = UrlEncode(szLink)
    return szLink
end

function ChatHelper.HandleLink_skillrecipe(tbLinkData)
    if not tbLinkData then return end

    local nID = tbLinkData.nID
    local nLevel = tbLinkData.nLevel
    LOG.INFO("HandleLink_skillrecipe, nID = %d, nLevel = %d", nID, nLevel)
end

-- book
function ChatHelper.MakeLink_book(nVersion, nTabType, nIndex, nBookInfo)
    local tbLinkData = {type = "book", nVersion = nVersion, nTabType = nTabType, nIndex = nIndex, nBookInfo = nBookInfo}
    local szLink = JsonEncode(tbLinkData)
    szLink = UrlEncode(szLink)
    return szLink
end

function ChatHelper.HandleLink_book(tbLinkData, node)
    if not tbLinkData then return end
    if not g_pClientPlayer then return end

    local nVersion = tbLinkData.nVersion
    local nTabType = tbLinkData.nTabType
    local nIndex = tbLinkData.nIndex
    local nBookInfo = tbLinkData.nBookInfo

    if not nBookInfo then return end

    local _, scriptItemTips = TipsHelper.ShowItemTips(ChatHelper._getChatPanelTipsNode(node), nTabType, nIndex, false, TipsLayoutDir.RIGHT_CENTER)
    scriptItemTips:SetBookID(nBookInfo)
    scriptItemTips:OnInitWithTabID(nTabType, nIndex)
    scriptItemTips:SetBtnState({})

    LOG.INFO("HandleLink_book, nVersion = %d, nTabType = %d, nIndex = %d, nBookInfo = %d", nVersion, nTabType, nIndex, nBookInfo)
end

-- achievement
function ChatHelper.MakeLink_achievement(nAchievementID)
    local tbLinkData = {type = "achievement", nAchievementID = nAchievementID}
    local szLink = JsonEncode(tbLinkData)
    szLink = UrlEncode(szLink)
    return szLink
end

function ChatHelper.HandleLink_achievement(tbLinkData)
    if not tbLinkData then return end
    if not g_pClientPlayer then return end

    local nAchievementID = tbLinkData.nAchievementID
    local aAchievement = Table_GetAchievement(nAchievementID)

    if not aAchievement then return end

    local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelAchievementContent)
    if not scriptView then
        UIMgr.Open(VIEW_ID.PanelAchievementContent, aAchievement.dwGeneral, aAchievement.dwSub, aAchievement.dwDetail, aAchievement.dwID, g_pClientPlayer.dwID)
    else
        scriptView:OnEnter(aAchievement.dwGeneral, aAchievement.dwSub, aAchievement.dwDetail, aAchievement.dwID, g_pClientPlayer.dwID)
    end

    UIMgr.Close(VIEW_ID.PanelChatMonitor)
    UIMgr.Close(VIEW_ID.PanelChatSocial)
end

-- designation
function ChatHelper.MakeLink_designation(nDesignation, bPrefix, dwForceID)
    local tbLinkData = {type = "designation", nDesignation = nDesignation, bPrefix = bPrefix, dwForceID = dwForceID}
    local szLink = JsonEncode(tbLinkData)
    szLink = UrlEncode(szLink)
    return szLink
end

function ChatHelper.HandleLink_designation(tbLinkData)
    if not tbLinkData then return end

    local nDesignation = tbLinkData.nDesignation
    local bPrefix = tbLinkData.bPrefix
    local dwForceID = tbLinkData.dwForceID

    if not nDesignation then return end

    UIMgr.CloseImmediately(VIEW_ID.PanelPersonalTitle)
    UIMgr.Open(VIEW_ID.PanelPersonalTitle, nDesignation, bPrefix)
    UIMgr.Close(VIEW_ID.PanelChatMonitor)
    UIMgr.Close(VIEW_ID.PanelChatSocial)
    LOG.INFO("HandleLink_designation, nDesignation = %d, bPrefix = %s, dwForceID = %s", nDesignation, tostring(bPrefix), tostring(dwForceID))
end

-- eventlink
function ChatHelper.MakeLink_eventlink(szName, szLinkInfo)
    --local tbLinkData = {type = "eventlink", szName = szName, szLinkInfo = szLinkInfo}
    local tbLinkData = {type = "eventlink", szLinkInfo = szLinkInfo}
    local szLink = JsonEncode(tbLinkData)
    szLink = UrlEncode(szLink)
    return szLink
end

function ChatHelper.HandleLink_eventlink(tbLinkData, node)
    if not tbLinkData then return end

    local szName = tbLinkData.szName
    local szLinkInfo = tbLinkData.szLinkInfo

	local szLinkEvent, szLinkArg = szLinkInfo:match("(%w+)/(.*)")
	szLinkEvent = szLinkEvent or szLinkInfo

    local szFuncName = "HandleLink_eventlink_"..szLinkEvent
    local func = ChatHelper[szFuncName]
    if IsFunction(func) then
        func(szLinkArg, node)
    end

    LOG.INFO("HandleLink_eventlink, szLinkInfo = %s", szLinkInfo)
end

-- pet
function ChatHelper.MakeLink_pet(nPetIndex)
    local tbLinkData = {type = "pet", nPetIndex = nPetIndex}
    local szLink = JsonEncode(tbLinkData)
    szLink = UrlEncode(szLink)
    return szLink
end

function ChatHelper.HandleLink_pet(tbLinkData)
    if not tbLinkData then return end

    local nPetIndex = tbLinkData.nPetIndex
    if not IsNumber(nPetIndex) then return end

    local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelPetMap)
    if not scriptView then
        UIMgr.Open(VIEW_ID.PanelPetMap, nil, nPetIndex)
    else
        scriptView:OnEnter(nil, nPetIndex)
    end

    UIMgr.Close(VIEW_ID.PanelChatMonitor)
    UIMgr.Close(VIEW_ID.PanelChatSocial)

    LOG.INFO("HandleLink_pet, nPetIndex = %d", nPetIndex)
end

-- land
function ChatHelper.MakeLink_land(nIndex, nMapID, nCopyIndex, nLandIndex)
    local tbLinkData = {type = "land", nIndex = nIndex, nMapID = nMapID, nCopyIndex = nCopyIndex, nLandIndex = nLandIndex}
    local szLink = JsonEncode(tbLinkData)
    szLink = UrlEncode(szLink)
    return szLink
end

function ChatHelper.HandleLink_land(tbLinkData)
    if not tbLinkData then return end

    local nIndex = tbLinkData.nIndex
    local nMapID = tbLinkData.nMapID
    local nCopyIndex = tbLinkData.nCopyIndex
    local nLandIndex = tbLinkData.nLandIndex
    LOG.INFO("HandleLink_land, nIndex = %d, nMapID = %d, nCopyIndex = %d, nLandIndex = %d", nIndex, nMapID, nCopyIndex, nLandIndex)

    if HomelandData.IsPrivateHome(nMapID) then
        local function _goPrivateLand()
            local nFlag = 3
            HomelandData.GoPrivateLand(nMapID, nCopyIndex, nIndex, nFlag, nLandIndex)
        end
        if PakDownloadMgr.UserCheckDownloadHomelandRes(nMapID, nIndex, _goPrivateLand) then
            _goPrivateLand()
        end
    else
        UIMgr.CloseImmediately(VIEW_ID.PanelHome)
        UIMgr.Open(VIEW_ID.PanelHome, 1, nMapID, nCopyIndex, nLandIndex)
        UIMgr.Close(VIEW_ID.PanelChatMonitor)
        UIMgr.Close(VIEW_ID.PanelChatSocial)
    end
end

-- gamegift
function ChatHelper.MakeLink_gamegift(szOwnerName, nGiftID)
    local tbLinkData = {type = "gamegift", szOwnerName = szOwnerName, nGiftID = nGiftID}
    local szLink = JsonEncode(tbLinkData)
    szLink = UrlEncode(szLink)
    return szLink
end

function ChatHelper.HandleLink_gamegift(tbLinkData)
    if not tbLinkData then return end

    local szOwnerName = UTF8ToGBK(tbLinkData.szOwnerName)
    local nGiftID = tbLinkData.nGiftID
    LOG.INFO("HandleLink_gamegift, szOwnerName = %s, nGiftID = %d", szOwnerName, nGiftID)

    if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TALK, "GameGift") then
		return
	end

	if not g_pClientPlayer then
		return
	end

	if g_pClientPlayer.nLevel < 100 then
		--OutputMessage("MSG_SYS", g_tStrings.STR_RED_GIFT_GET_ERROR)
		OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_RED_GIFT_GET_ERROR)
		return
	end

	local nTime = GetTickCount()
	if self.nLastRedPacketTime and nTime - self.nLastRedPacketTime < 5000 then
		--OutputMessage("MSG_SYS", g_tStrings.STR_HAVE_CD)
		OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_HAVE_CD)
		return
	end

	self.nLastRedPacketTime = nTime
	--OutputMessage("MSG_SYS", g_tStrings.STR_RED_GIFT_GET_INFO)
	OutputMessage("MSG_ANNOUNCE_YELLOW", g_tStrings.STR_RED_GIFT_GET_INFO)
	g_pClientPlayer.GetChatGiftRequest(nGiftID, szOwnerName)

    --UIMgr.Open(VIEW_ID.PanelGetRedPacket , nil, nCoinType, nCurrency, szOwnerName, szDesc, true)
end

-- toybox
function ChatHelper.MakeLink_toybox(nID)
    local tbLinkData = {type = "toybox", nID = nID}
    local szLink = JsonEncode(tbLinkData)
    szLink = UrlEncode(szLink)
    return szLink
end

function ChatHelper.HandleLink_toybox(tbLinkData)
    if not tbLinkData then return end

    local nID = tbLinkData.nID
    if not IsNumber(nID) then return end

    UIMgr.CloseImmediately(VIEW_ID.PanelHalfBag)
    --UIMgr.Open(VIEW_ID.PanelQuickOperationBagNormal, false, nID)
    UIMgr.Close(VIEW_ID.PanelChatMonitor)
    UIMgr.Close(VIEW_ID.PanelChatSocial)
    UIMgr.Open(VIEW_ID.PanelHalfBag, nID)

    LOG.INFO("HandleLink_toybox, nID = %d", nID)
end

-- website
function ChatHelper.MakeLink_website(szWebsite)
    local tbLinkData = {type = "website", szWebsite = szWebsite}
    local szLink = JsonEncode(tbLinkData)
    szLink = UrlEncode(szLink)
    return szLink
end

function ChatHelper.HandleLink_website(tbLinkData)
    if not tbLinkData then return end

    local szWebsite = tbLinkData.szWebsite
    if string.is_nil(szWebsite) then return end

    UIHelper.OpenWeb(szWebsite)
end

-- landorder
function ChatHelper.MakeLink_landorder(dwTalkerID)
    local tbLinkData = { type = "landorder", dwTalkerID = dwTalkerID}
    local szLink = JsonEncode(tbLinkData)
    szLink = UrlEncode(szLink)
    return szLink
end

function ChatHelper.HandleLink_landorder(tbLinkData)
    if not tbLinkData then return end

    local dwTalkerID = tbLinkData.dwTalkerID
    LOG.INFO("HandleLink_landorder, dwTalkerID = %s", dwTalkerID)

    HomelandIdentity.OpenAssistOrderDetails(dwTalkerID)
end

-- -----------------------------------------------------------------------------
-- eventlink
-- -----------------------------------------------------------------------------
Event.Reg(self, "ON_PUSH_TEAM_NOTIFY", function()
    if arg0 ~= "single" then
		return
	end
    if not self.dwTeamBuildLinkID then
        return
    end

    local tInfo = GetTeamPushInfoSingle(self.dwTeamBuildLinkID)
	if tInfo then
        TeamBuilding.LocateApply(self.dwTeamBuildLinkID)
    else
        TipsHelper.ShowNormalTip("此招募已不存在")
	end
    self.dwTeamBuildLinkID = nil
end)

Event.Reg(self, "ON_PUSH_ROOM_PUSH_NOTIFY", function()
	if arg0 ~= "single" then
		return
	end

	if not self.szRoomBuildLinkID then
		return
	end

	local tInfo = GetGlobalRoomPushClient().GetRoomPushInfoSingle(self.szRoomBuildLinkID)
	if tInfo then
        TeamBuilding.LocateApply(self.szRoomBuildLinkID)
    else
        TipsHelper.ShowNormalTip("此招募已不存在")
	end
    self.szRoomBuildLinkID = nil
end)

-- eventlink 组队
function ChatHelper.HandleLink_eventlink_TeamBuild(szLinkArg)
    self.dwTeamBuildLinkID = tonumber(szLinkArg)
    if self.dwTeamBuildLinkID then
        ApplyTeamPushSingle(self.dwTeamBuildLinkID)
        -- ApplyTeamList()
        UIMgr.Close(VIEW_ID.PanelChatMonitor)
        UIMgr.Close(VIEW_ID.PanelChatSocial)
    end
end

-- eventlink 房间
function ChatHelper.HandleLink_eventlink_RoomBuild(szLinkArg)
    self.szRoomBuildLinkID = szLinkArg
    if self.szRoomBuildLinkID then
        -- GetGlobalRoomPushClient().SyncPlayerApplyRoomPushList()
		GetGlobalRoomPushClient().ApplyRoomPushSingle(self.szRoomBuildLinkID)
        UIMgr.Close(VIEW_ID.PanelChatMonitor)
        UIMgr.Close(VIEW_ID.PanelChatSocial)
    end
end

-- eventlink 副本/秘境
function ChatHelper.HandleLink_eventlink_FBlist(szLinkArg)
    local dwMapID = tonumber(szLinkArg)
    if not IsNumber(dwMapID) then return end

    CraftData.OpenDungeonEntranceView(szLinkArg)

    UIMgr.Close(VIEW_ID.PanelChatMonitor)
    UIMgr.Close(VIEW_ID.PanelChatSocial)

    LOG.INFO("HandleLink_eventlink_FBlist, szLinkArg = ".. szLinkArg)
end

-- eventlink 打开指定界面
function ChatHelper.HandleLink_eventlink_PanelLink(szLinkArg)
    Global.OpenViewByLink(szLinkArg)

    UIMgr.Close(VIEW_ID.PanelChatMonitor)
    UIMgr.Close(VIEW_ID.PanelChatSocial)

    LOG.INFO("HandleLink_eventlink_PanelLink, szLinkArg = ".. szLinkArg)
end

-- eventlink 运营活动/花萼楼
function ChatHelper.HandleLink_eventlink_OperationCenter(szLinkArg)
    local nOperationActivityID = tonumber(szLinkArg)
    if nOperationActivityID then
        OperationCenterData.OpenCenterView(nOperationActivityID)
        UIMgr.Close(VIEW_ID.PanelChatMonitor)
        UIMgr.Close(VIEW_ID.PanelChatSocial)
    end
    LOG.INFO("HandleLink_eventlink_OperationCenter, szLinkArg = ".. szLinkArg)
end

-- eventlink 江湖行记
function ChatHelper.HandleLink_eventlink_RealBP(szLinkArg)
    if UIMgr.IsViewOpened(VIEW_ID.PanelBenefits, true) then
        UIMgr.CloseWithCallBack(VIEW_ID.PanelBenefits, function ()
            UIMgr.Open(VIEW_ID.PanelBenefits, 2, true)
        end)
    else
        UIMgr.Open(VIEW_ID.PanelBenefits, 2, true)
    end
    LOG.INFO("HandleLink_eventlink_RealBP, szLinkArg = ".. szLinkArg)
end

-- eventlink 商店
function ChatHelper.HandleLink_eventlink_ShopPanel(szLinkArg)
    local nShopID = tonumber(szLinkArg)
    if nShopID then
        UIMgr.CloseImmediately(VIEW_ID.PanelPlayStore)
        ShopData.OpenSystemShopGroup(1, nShopID)
        UIMgr.Close(VIEW_ID.PanelChatMonitor)
        UIMgr.Close(VIEW_ID.PanelChatSocial)
    end

    LOG.INFO("HandleLink_eventlink_ShopPanel, szLinkArg = ".. szLinkArg)
end

-- eventlink 活动
function ChatHelper.HandleLink_eventlink_LinkActivity(szLinkArg)
    local nActivityID = tonumber(szLinkArg)
    if nActivityID then
        ActivityData.LinkToActiveByID(nActivityID)
        UIMgr.Close(VIEW_ID.PanelChatMonitor)
        UIMgr.Close(VIEW_ID.PanelChatSocial)
    end
    LOG.INFO("HandleLink_eventlink_LinkActivity, szLinkArg = ".. szLinkArg)
end

-- VoiceRoom
function ChatHelper.HandleLink_eventlink_VoiceRoom(szRoomID, node)
    TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetVioceRoomTips, node, szRoomID)
    LOG.INFO("HandleLink_eventlink_LinkVoiceRoom, szRoomID = ".. szRoomID)
end

-- eventlink 房间
function ChatHelper.HandleLink_eventlink_GlobalRoom(szLinkArg)
    LOG.INFO("HandleLink_eventlink_GlobalRoom, szLinkArg = ".. szLinkArg)

    local szGlobalRoomID = szLinkArg--tonumber(szLinkArg)
    if szGlobalRoomID then

        if not g_pClientPlayer then
            return
        end

        if RoomData.IsHaveRoom() then
            if g_pClientPlayer.GetGlobalRoomID() == szGlobalRoomID then
                if not UIMgr.IsViewOpened(VIEW_ID.PanelTeam) then
                    UIMgr.Close(VIEW_ID.PanelChatMonitor)
                    UIMgr.Close(VIEW_ID.PanelChatSocial)
                    UIMgr.Open(VIEW_ID.PanelTeam, 4)
                else
                    TipsHelper.ShowNormalTip("你已经在房间中")
                end
            else
                TipsHelper.ShowNormalTip("你已经在一个房间中")
            end
            return
        end

        RoomData.ApplyGlobalRoomByRoomID(szGlobalRoomID)
    end
end

-- eventlink 大侠之路
function ChatHelper.HandleLink_eventlink_GameGuide(szLinkArg)
    LOG.INFO("HandleLink_eventlink_GameGuide, szLinkArg = ".. szLinkArg)

    local dwID = tonumber(szLinkArg)
    if dwID then
        UIMgr.CloseImmediately(VIEW_ID.PanelRoadCollection)
        Timer.AddFrame(ChatHelper, 5, function()
            UIMgr.Open(VIEW_ID.PanelRoadCollection, COLLECTION_PAGE_TYPE.DAY, dwID)
            CollectionData.LinkToNormalCardByID(dwID)
            Event.Dispatch(EventType.OnChatGameGuideSelected, dwID)
        end)
    end
    UIMgr.Close(VIEW_ID.PanelChatMonitor)
    UIMgr.Close(VIEW_ID.PanelChatSocial)
end

-- eventlink 大侠之路 日常
function ChatHelper.HandleLink_eventlink_GameGuideDaily(szLinkArg)
    LOG.INFO("HandleLink_eventlink_GameGuideDaily, szLinkArg = ".. szLinkArg)

    local dwID = tonumber(szLinkArg)
    if dwID then
        UIMgr.CloseImmediately(VIEW_ID.PanelRoadCollection)
        Timer.AddFrame(ChatHelper, 5, function()
            UIMgr.Open(VIEW_ID.PanelRoadCollection, COLLECTION_PAGE_TYPE.DAY, dwID)
            CollectionData.LinkToDailyCardByID(dwID)
            Event.Dispatch(EventType.OnChatGameGuideSelected, dwID)
        end)
    end
    UIMgr.Close(VIEW_ID.PanelChatMonitor)
    UIMgr.Close(VIEW_ID.PanelChatSocial)
end

function ChatHelper.HandleLink_eventlink_QuickEating(szLinkArg)
    LOG.INFO("HandleLink_eventlink_QuickEating, szLinkArg = ".. szLinkArg)

    local tLinkIndex = SplitString(szLinkArg, "/")
    UIMgr.Open(VIEW_ID.PanelWuWeiJueOthersPop, tLinkIndex)
end

function ChatHelper.HandleLink_eventlink_ShareCodeLinkTip(szLinkArg)
    LOG.INFO("HandleLink_eventlink_ShareCodeLinkTip, szLinkArg = ".. szLinkArg)

    local tLinkArg = SplitString(szLinkArg, "/")
    local nDataType = tonumber(tLinkArg[1])
    local szShareCode = tLinkArg[2]
    local szName = UIHelper.GBKToUTF8(tLinkArg[3])
    local nSubType
    if tLinkArg[4] then
        nSubType = tonumber(tLinkArg[4])
    end
    ShareStationData.OnClickEventLink(nDataType, szShareCode, szName, nSubType)
end

function ChatHelper.HandleLink_eventlink_OrangeWeaponUpg(szLinkArg)
    if szLinkArg then
        local tLinkArg = SplitString(szLinkArg, "/")
        local nLevel = tonumber(tLinkArg[1])
    end

    UIMgr.Open(VIEW_ID.PanelShenBingUpgrade, nil, nLevel)
end

function ChatHelper.HandleLink_eventlink_ArenaTower(szLinkArg)
    UIMgr.OpenSingle(true, VIEW_ID.PanelYangDaoMain)
    UIMgr.Close(VIEW_ID.PanelChatMonitor)
    UIMgr.Close(VIEW_ID.PanelChatSocial)
end










-- -----------------------------------------------------------------------------
-- Other
-- -----------------------------------------------------------------------------
function ChatHelper.GetMiniChatRichText(szContent, nChannel)
    local tbConf = ChatData.GetChatFlagConfByChannelID(nChannel) or {}
    return string.format("<img src='%s' width='54' height='28' />%s", tbConf.szChannelIcon or "", szContent)
end

-- 登录后在聊天框显示包月、点卡、登录信息
function ChatHelper.AppendLoginInfo()
    -- 点卡月卡
    if not IsVersionTW() then
        if Login_GetZoneChargeFlag() and Login_GetChargeFlag() then
            local nMonthEndTime, nPointLeftTime, nDayLeftTime = Login_GetTimeOfFee()

            -- 月卡
            if nMonthEndTime > 1229904000 then
                local szEndTime = g_tStrings.STR_MONTH_END_TIME..FormatTime("%Y/%m/%d %H:%M", nMonthEndTime)
                ChatData.Append(szEndTime, 0, PLAYER_TALK_CHANNEL.SYSTEM_NOTICE, false, "")
            end

            -- 天卡
            if nDayLeftTime > 0 then
                local szEndTime = g_tStrings.STR_DAY_LEFT_TIME..math.ceil(nDayLeftTime / 86400)..g_tStrings.STR_TIME_DAY
                ChatData.Append(szEndTime, 0, PLAYER_TALK_CHANNEL.SYSTEM_NOTICE, false, "")

                ChatData.Append(g_tStrings.STR_DAY_COMPUTING_METHOD, 0, PLAYER_TALK_CHANNEL.SYSTEM_NOTICE, false, "")
            end

            -- 点卡
            if nPointLeftTime ~= 0 then
                if nPointLeftTime > 0 then
                    local szEndTime = g_tStrings.STR_POINT_LEFT_TIME..
                                math.floor(nPointLeftTime / 3600)..g_tStrings.STR_TIME_HOUR..
                                math.floor((nPointLeftTime % 3600) / 60)..g_tStrings.STR_TIME_MINUTE..
                                (nPointLeftTime % 60)..g_tStrings.STR_TIME_SECOND
                    ChatData.Append(szEndTime, 0, PLAYER_TALK_CHANNEL.SYSTEM_NOTICE, false, "")
                elseif nPointLeftTime < 0 then
                    local nAbsLeftPoint = -nPointLeftTime
                    local szEndTime = g_tStrings.STR_POINT_LEFT_TIME.."-"..
                                math.floor(nAbsLeftPoint / 3600)..g_tStrings.STR_TIME_HOUR..
                                math.floor((nAbsLeftPoint % 3600) / 60)..g_tStrings.STR_TIME_MINUTE..
                                (nAbsLeftPoint % 60)..g_tStrings.STR_TIME_SECOND
                    ChatData.Append(szEndTime, 0, PLAYER_TALK_CHANNEL.SYSTEM_NOTICE, false, "")
                end
            end
        else
            -- 试玩账号 免费
            ChatData.Append(g_tStrings.STR_DEMO_ACCOUNT, 0, PLAYER_TALK_CHANNEL.SYSTEM_NOTICE, false, "")
        end
    end

    -- 上次登录
    local nYear, nMonth, nDay, nHour, nMinute = Login_GetLastLoginTime()
    local szLastLoginTime = string.format("%s%d/%02d/%02d %02d:%02d", g_tStrings.STR_LAST_LOGIN_TIME, nYear, nMonth, nDay, nHour, nMinute)
    ChatData.Append(szLastLoginTime, 0, PLAYER_TALK_CHANNEL.SYSTEM_NOTICE, false, "")

    -- 本次登录
    local nCurrLoginTime = Login_GetLoginTime()
	local tCurrLoginTime = TimeToDate(nCurrLoginTime)
	local szCurrLoginTime = string.format("%s%d/%02d/%02d %02d:%02d", g_tStrings.STR_CURRENT_LOGIN_TIME, tCurrLoginTime.year, tCurrLoginTime.month, tCurrLoginTime.day, tCurrLoginTime.hour, tCurrLoginTime.minute)
    ChatData.Append(szCurrLoginTime, 0, PLAYER_TALK_CHANNEL.SYSTEM_NOTICE, false, "")
end






















































-- -----------------------------------------------------------------------------
-- send to chat
-- -----------------------------------------------------------------------------

function ChatHelper.AppendToChat(szContent, bFormat)
    if string.is_nil(szContent) then
        return
    end

    if bFormat == nil then
        bFormat = true
    end

    if bFormat then
        szContent = "["..szContent.."]"
    end

    --教学 分享到聊天
    FireHelpEvent("OnShareChat", szContent)

    -- 开了的话就先关掉
    if UIMgr.IsViewOpened(VIEW_ID.PanelChatSocial) then
        UIMgr.CloseImmediately(VIEW_ID.PanelChatSocial)
    end

    if UIMgr.IsViewOpened(VIEW_ID.PanelVoiceRoomSearchMenberPop) then
        UIMgr.CloseImmediately(VIEW_ID.PanelVoiceRoomSearchMenberPop)
    end

    ChatHelper.Chat(nil, szContent)
end

-- 组队
function ChatHelper.SendTeamBuildToChat(dwID, szComment, bDirectWorld)
    if not g_pClientPlayer then return end

    local tInfo = Table_GetTeamInfo(dwID)
    local szName = FormatString(g_tStrings.STR_TEAMBUILD_EDIT_LINK, GBKToUTF8(tInfo.szName) or "")
    local szLinkInfo = "TeamBuild/" .. g_pClientPlayer.dwID

    if bDirectWorld then
        local szFixName = UTF8ToGBK("[" .. szName .. "]")
        local tbMsg =
        {
            {type = "eventlink", name = szFixName, linkinfo = szLinkInfo},
            {type = "text", text = szComment}
        }
        ChatData.Send(PLAYER_TALK_CHANNEL.WORLD, "", tbMsg)
    else
        ChatHelper.SendEventLinkToChat(szName, szLinkInfo)
    end
end

-- 房间
function ChatHelper.SendRoomBuildToChat(dwID, szRoomID, szComment, bDirectWorld)
    if not g_pClientPlayer then return end

    local tInfo = Table_GetTeamInfo(dwID)
    local szName = FormatString(g_tStrings.STR_TEAMBUILD_ROOM_EDIT_LINK, GBKToUTF8(tInfo.szName) or "")
    local szLinkInfo = "RoomBuild/" .. szRoomID

    if bDirectWorld then
        local szFixName = UTF8ToGBK("[" .. szName .. "]")
        local tbMsg =
        {
            {type = "eventlink", name = szFixName, linkinfo = szLinkInfo},
            {type = "text", text = szComment}
        }
        ChatData.Send(PLAYER_TALK_CHANNEL.WORLD, "", tbMsg)
    else
        ChatHelper.SendEventLinkToChat(szName, szLinkInfo)
    end
end

-- 道具
function ChatHelper.SendItemToChat(dwItemIDOrdwBox, dwX, szPackageType, dwASPSource)
    local item = nil
	if dwX then
		item = ItemData.GetPlayerItem(GetClientPlayer(), dwItemIDOrdwBox, dwX, szPackageType, dwASPSource)
	else
		item = GetItem(dwItemIDOrdwBox)
	end

	if not item then
		return
	end

    local szItemName = GBKToUTF8(ItemData.GetItemNameByItem(item))

    ChatArgs.Append_item(szItemName, dwItemIDOrdwBox)
    ChatHelper.AppendToChat(szItemName)
end

-- 道具信息
function ChatHelper.SendItemInfoToChat(nVersion, nTabType, nIndex)
    local itemInfo = ItemData.GetItemInfo(nTabType, nIndex)
	if not itemInfo then
		return
	end

    local szItemName = GBKToUTF8(ItemData.GetItemNameByItemInfo(itemInfo))

    ChatArgs.Append_iteminfo(szItemName, nVersion or GLOBAL.CURRENT_ITEM_VERSION, nTabType, nIndex)
    ChatHelper.AppendToChat(szItemName)
end

-- 任务
function ChatHelper.SendQuestToChat(dwQuestID)
    local szQuestName = QuestData.GetQuestName(dwQuestID) or ""

    ChatArgs.Append_quest(szQuestName, dwQuestID)
    ChatHelper.AppendToChat(szQuestName)
end

-- Book
function ChatHelper.SendBookToChat(nBookInfo)
    if not nBookInfo then
        return
    end

    local nBookID, nSegmentID = GlobelRecipeID2BookID(nBookInfo)
	local nVersion, nTabType = GLOBAL.CURRENT_ITEM_VERSION, 5
	local nIndex = Table_GetBookItemIndex(nBookID, nSegmentID)

	local itemInfo = GetItemInfo(nTabType, nIndex)
	if not itemInfo or itemInfo.nGenre ~= ITEM_GENRE.BOOK then
		return
	end

    local szSegmentName = GBKToUTF8(Table_GetSegmentName(nBookID, nSegmentID))

    ChatArgs.Append_book(szSegmentName, nVersion, nTabType, nIndex, nBookInfo)
    ChatHelper.AppendToChat(szSegmentName)
end

-- Player
function ChatHelper.SendPlayerToChat(szPlayerName)
    ChatArgs.Append_name(szPlayerName)
    ChatHelper.AppendToChat(szPlayerName)
end

-- Recipe
function ChatHelper.SendRecipeToChat(dwCraftID, dwRecipeID)
    local recipe = GetRecipe(dwCraftID, dwRecipeID)
	if not recipe then
		return
	end

	local szRecipeName = GBKToUTF8(Table_GetRecipeName(dwCraftID, dwRecipeID))

    ChatArgs.Append_recipe(szRecipeName, dwCraftID, dwRecipeID)
    ChatHelper.AppendToChat(szRecipeName)
end

-- Enchant
function ChatHelper.SendEnchantToChat(dwProID, dwCraftID, dwRecipeID)
	local szEnchantName = GBKToUTF8(Table_GetEnchantName(dwProID, dwCraftID, dwRecipeID))

    ChatArgs.Append_enchant(szEnchantName, dwProID, dwCraftID, dwRecipeID)
    ChatHelper.AppendToChat(szEnchantName)
end

-- Skill
function ChatHelper.SendSkillToChat(nSkillID, nSkillLevel)
    if not g_pClientPlayer then
		return
	end

    local skillKey = g_pClientPlayer.GetSkillRecipeKey(nSkillID, nSkillLevel)
    if not skillKey then
        return
    end

	local szSkillName = GBKToUTF8(Table_GetSkillName(nSkillID, nSkillLevel))

    ChatArgs.Append_skill(szSkillName, nSkillID, nSkillLevel)
    ChatHelper.AppendToChat(szSkillName)
end

-- Skill CD
function ChatHelper.SendSkillCDToChat(nSkillID, nSkillLevel)
    if not g_pClientPlayer then
		return
	end

	local szSkillName = GBKToUTF8(Table_GetSkillName(nSkillID, nSkillLevel))

    local szText = ""
	local szName = "["..szSkillName.."]"
	local bCooldown, nLeft, nTotal = Skill_GetCDProgress(nSkillID, nSkillLevel, Skill_GetCongNengCDID(dwID, g_pClientPlayer), g_pClientPlayer)
	if bCooldown and nLeft > 0 then
		local szLeftTime = TimeLib.GetTimeText(nLeft, true, false, true)
		szText = FormatString(g_tStrings.EDITBOX_SKILL_TEXT_CD, szName, szLeftTime)
	else
		szText = FormatString(g_tStrings.EDITBOX_SKILL_TEXT_CD_OK, szName)
	end

    ChatHelper.AppendToChat(szText, false)
end

-- Skill Recipe
function ChatHelper.SendSkillRecipeToChat(nSkillID, nSkillLevel)
    local tbSkillRecipe = Table_GetSkillRecipe(nSkillID, nSkillLevel)
    if not tbSkillRecipe then
        return
    end

	local szSkillRecipeName = GBKToUTF8(tbSkillRecipe.szName)

    ChatArgs.Append_skillrecipe(szSkillRecipeName, nSkillID, nSkillLevel)
    ChatHelper.AppendToChat(szSkillRecipeName)
end

-- Achievement
function ChatHelper.SendAchievementToChat(dwAchievementID)
    local aAchievement = g_tTable.Achievement:Search(dwAchievementID)
	if not aAchievement then
		return
	end

	local szAchievementName = GBKToUTF8(aAchievement.szName)

    ChatArgs.Append_achievement(szAchievementName, dwAchievementID)
    ChatHelper.AppendToChat(szAchievementName)
end

-- Designation
function ChatHelper.SendDesignationToChat(dwDesignation, bPrefix, dwForceID)
    local aDesignation
	if bPrefix then
		aDesignation = Table_GetDesignationPrefixByID(dwDesignation, dwForceID)
	else
		aDesignation = g_tTable.Designation_Postfix:Search(dwDesignation)
	end

	if not aDesignation then
		return
	end

	local szDesignationName = GBKToUTF8(aDesignation.szName)

    ChatArgs.Append_designation(szDesignationName, dwDesignation, bPrefix, dwForceID)
    ChatHelper.AppendToChat(szDesignationName)
end

-- EventLink
function ChatHelper.SendEventLinkToChat(szName, szLinkInfo)
    if string.is_nil(szName) then
        return
    end

    ChatArgs.Append_eventlink(szName, szLinkInfo)
    ChatHelper.AppendToChat(szName)
end

-- Pet
function ChatHelper.SendPetToChat(nPetIndex)
    local tbPet = Table_GetFellowPet(nPetIndex)
	if not tbPet then
		return
	end

    local szPetName = GBKToUTF8(tbPet.szName)

    ChatArgs.Append_pet(szPetName, nPetIndex)
    ChatHelper.AppendToChat(szPetName)
end

-- Land
function ChatHelper.SendLandToChat(nIndex, nMapID, nCopyIndex, nLandIndex)
    local szLandName = Homeland_GetHomeName(nMapID, nLandIndex)
    szLandName = GBKToUTF8(szLandName)
	if not szLandName then
		return
	end

    szLandName = FormatString(g_tStrings.STR_LINK_LAND, szLandName, nIndex)

    ChatArgs.Append_land(szLandName, nIndex, nMapID, nCopyIndex, nLandIndex)
    ChatHelper.AppendToChat(szLandName)
end

-- PrivateLand , 解析和 Land是同样的
function ChatHelper.SendPrivateLandToChat(dwSkinID, nMapID, nCopyIndex)
    local tbLine = Table_GetPrivateHomeSkin(nMapID, dwSkinID)
	if not tbLine then
		return
	end

    local szPrivateLandName = GBKToUTF8(tbLine.szSkinName)
    szPrivateLandName = FormatString(g_tStrings.STR_LINK_PRIVATE, szPrivateLandName)

    ChatArgs.Append_land(szPrivateLandName, dwSkinID, nMapID, nCopyIndex, 0)
    ChatHelper.AppendToChat(szPrivateLandName)
end

-- ToyBox
function ChatHelper.SendToyBoxToChat(dwID)
    local tbToyBox = Table_GetToyBox(dwID)
	if not tbToyBox then
		return
	end

    local szToyBoxName = GBKToUTF8(tbToyBox.szName)

    ChatArgs.Append_toybox(szToyBoxName, dwID)
    ChatHelper.AppendToChat(szToyBoxName)
end

-- Website
function ChatHelper.SendWebsiteToChat(szUrl)
	if string.is_nil(szUrl) then
		return
	end

    ChatArgs.Append_website(szUrl)
    ChatHelper.AppendToChat(szUrl)
end

-- HomelandOrder
function ChatHelper.SendHomelandOrderToChat(dwID, nMoney, szPlayerName)
    local szName = g_tStrings.STR_HOMELAND_ASSIST_ORDER

    ChatArgs.Append_landorder(dwID, nMoney, szPlayerName, szName)
    ChatHelper.AppendToChat(szName)
end





















-- -------------------------------------------------------------------------
-- other APIs
-- -------------------------------------------------------------------------
function ChatHelper.Update_MiniChatSyncState(btnSync, imgSync, imgUnSync, bBindUIEvent, funcBind)
    local bSync = ChatData.IsSyncMiniChat()
    UIHelper.SetVisible(imgSync, bSync)
    UIHelper.SetVisible(imgUnSync, not bSync)

    if not bBindUIEvent then
        return
    end

    UIHelper.BindUIEvent(btnSync, EventType.OnClick, function()
        local szContet = ""
        local szConfirmText = ""
        local szCancelText = ""
        local bSync = ChatData.IsSyncMiniChat()
        if bSync then
            szContet = "你确定要将聊天频道分页和主界面快捷聊天<color=#ffe26e>取消绑定</color>吗？<br>取消绑定后，聊天界面频道分页和主界面快捷聊天显示将不做绑定切换。"
            szConfirmText = "取消绑定"
            szCancelText = "继续绑定"
        else
            szContet = "你确定要将聊天频道分页和主界面快捷聊天<color=#ffe26e>绑定</color>吗？<br>绑定后，聊天界面频道分页切换，主界面快捷聊天显示也会一起切换。"
            szConfirmText = "绑定"
            szCancelText = "暂不绑定"
        end

        local dialog = UIHelper.ShowConfirm(szContet, function()
            if IsFunction(funcBind) then
                funcBind()
            end

            ChatData.SyncMiniChat(not bSync)
        end, nil, true)
        if dialog then
            dialog:SetConfirmButtonContent(szConfirmText)
            dialog:SetCancelButtonContent(szCancelText)
        end
    end)
end

function ChatHelper.SetCanToggleSitDown(bVal)
    ChatHelper.bCanToggleSitDown = bVal
end

function ChatHelper.GetCanToggleSitDown()
    if ChatHelper.bCanToggleSitDown == nil then
        ChatHelper.bCanToggleSitDown = true
    end

    return ChatHelper.bCanToggleSitDown
end









































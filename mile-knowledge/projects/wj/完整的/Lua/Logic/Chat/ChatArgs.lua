ChatArgs = ChatArgs or {className = "ChatArgs"}


-- 回到角色或者登录要清空
Event.Reg(ChatArgs, EventType.OnAccountLogout, function(bReLogin)
    ChatArgs.ClearEmoji()
end)

Event.Reg(ChatArgs, EventType.OnChatEmojiSelected, function(tbEmojiConf)
    ChatArgs.AppendEmoji(tbEmojiConf)
end)

function ChatArgs.ClearEmoji()
    ChatArgs.tbEmojiList = {}
end

function ChatArgs.GetEmoji(nIndex, szName)
    local tbEmojiConf = nil
    if ChatArgs.tbEmojiList then
        if IsNumber(nIndex) then
            tbEmojiConf = ChatArgs.tbEmojiList[nIndex]
        end

        if tbEmojiConf and tbEmojiConf.szName ~= szName then
            tbEmojiConf = nil
            for k, v in ipairs(ChatArgs.tbEmojiList) do
                if v.szName == szName then
                    tbEmojiConf = v
                    break
                end
            end
        end
    end
    return tbEmojiConf
end

function ChatArgs.AppendEmoji(tbEmojiConf)
    if table.is_empty(tbEmojiConf) then
        return
    end

    if not ChatArgs.tbEmojiList then
        ChatArgs.tbEmojiList = {}
    end

    table.insert(ChatArgs.tbEmojiList, tbEmojiConf)
end

function ChatArgs.Clear(szUIChannel)
    -- ChatArgs.tbList = {}
    if ChatArgs.tbList then
        ChatArgs.tbList[szUIChannel] = nil
    end

    ChatArgs.ClearEmoji()
end

function ChatArgs.Append(tbArg)
    if table.is_empty(tbArg) then
        return
    end

    if not ChatArgs.tbList then
        ChatArgs.tbList = {}
    end

    local szUIChannel = ChatData.GetRuntimeSelectDisplayChannel()
    -- table.insert(ChatArgs.tbList, tbArg)
    if not ChatArgs.tbList[szUIChannel] then
        ChatArgs.tbList[szUIChannel] = {}
    end
    table.insert(ChatArgs.tbList[szUIChannel], tbArg)

end

-- Event.Reg(ChatArgs, EventType.OnViewClose, function(nViewID)
--     if nViewID == VIEW_ID.PanelChatSocial then
--         ChatArgs.Clear()
--     end
-- end)


function ChatArgs.Append_item(szItemName, dwItemIDOrdwBox)
    local tbArg =
    {
        szSendType = "item",
        szText     = szItemName,
        szItemName = szItemName,
        nItemID    = dwItemIDOrdwBox,
    }

    ChatArgs.Append(tbArg)
end

function ChatArgs.Append_iteminfo(szItemName, nVersion, nTabType, nIndex)
    local tbArg =
    {
        szSendType = "iteminfo",
        szText     = szItemName,
        szItemName = szItemName,
        nVersion   = nVersion or GLOBAL.CURRENT_ITEM_VERSION,
        nTabType   = nTabType,
        nIndex     = nIndex,
    }

    ChatArgs.Append(tbArg)
end

function ChatArgs.Append_quest(szQuestName, nQuestID)
    local tbArg =
    {
        szSendType  = "quest",
        szText      = szQuestName,
        szQuestName = szQuestName,
        nQuestID    = nQuestID,
    }

    ChatArgs.Append(tbArg)
end

function ChatArgs.Append_book(szSegmentName, nVersion, nTabType, nIndex, nBookInfo)
    local tbArg =
    {
        szSendType    = "book",
        szText        = szSegmentName,
        szSegmentName = szSegmentName,
        nVersion      = nVersion,
        nTabType      = nTabType,
        nIndex        = nIndex,
        nBookInfo     = nBookInfo,
    }

    ChatArgs.Append(tbArg)
end

function ChatArgs.Append_name(szPlayerName)
    local tbArg =
    {
        szSendType   = "name",
        szText       = szPlayerName,
        szPlayerName = szPlayerName,
    }

    ChatArgs.Append(tbArg)
end

function ChatArgs.Append_recipe(szRecipeName, dwCraftID, dwRecipeID)
    local tbArg =
    {
        szSendType   = "recipe",
        szText       = szRecipeName,
        szRecipeName = szRecipeName,
        nCraftID     = dwCraftID,
        nRecipeID    = dwRecipeID,
    }

    ChatArgs.Append(tbArg)
end

function ChatArgs.Append_enchant(szEnchantName, dwProID, dwCraftID, dwRecipeID)
    local tbArg =
    {
        szSendType    = "enchant",
        szText        = szEnchantName,
        szEnchantName = szEnchantName,
        nProID        = dwProID,
        nCraftID      = dwCraftID,
        nRecipeID     = dwRecipeID,
    }

    ChatArgs.Append(tbArg)
end

function ChatArgs.Append_skill(szSkillName, nSkillID, nSkillLevel)
    local tbArg =
    {
        szSendType  = "skill",
        szText      = szSkillName,
        szSkillName = szSkillName,
        nSkillID    = nSkillID,
        nSkillLevel = nSkillLevel,
    }

    ChatArgs.Append(tbArg)
end

function ChatArgs.Append_skillrecipe(szSkillRecipeName, nSkillID, nSkillLevel)
    local tbArg =
    {
        szSendType        = "skillrecipe",
        szText            = szSkillRecipeName,
        szSkillRecipeName = szSkillRecipeName,
        nSkillID          = nSkillID,
        nSkillLevel       = nSkillLevel,
    }

    ChatArgs.Append(tbArg)
end

function ChatArgs.Append_achievement(szAchievementName, dwAchievementID)
    local tbArg =
    {
        szSendType        = "achievement",
        szText            = szAchievementName,
        szAchievementName = szAchievementName,
        nAchievementID    = dwAchievementID,
    }

    ChatArgs.Append(tbArg)
end

function ChatArgs.Append_designation(szDesignationName, dwDesignation, bPrefix, dwForceID)
    local tbArg =
    {
        szSendType        = "designation",
        szText            = szDesignationName,
        szDesignationName = szDesignationName,
        nDesignationID    = dwDesignation,
        bPrefix           = bPrefix,
        dwForceID         = dwForceID,
    }

    ChatArgs.Append(tbArg)
end

function ChatArgs.Append_eventlink(szName, szLinkInfo)
    local tbArg =
    {
        szSendType      = "eventlink",
        szText          = szName,
        szEventLinkName = szName,
        szLinkInfo      = szLinkInfo,
    }

    ChatArgs.Append(tbArg)
end

function ChatArgs.Append_pet(szPetName, nPetIndex)
    local tbArg =
    {
        szSendType = "pet",
        szText     = szPetName,
        szPetName  = szPetName,
        nPetIndex  = nPetIndex,
    }

    ChatArgs.Append(tbArg)
end

function ChatArgs.Append_land(szLandName, nIndex, nMapID, nCopyIndex, nLandIndex)
    local tbArg =
    {
        szSendType = "land",
        szText     = szLandName,
        szLandName = szLandName,
        nIndex     = nIndex,
        nMapID     = nMapID,
        nCopyIndex = nCopyIndex,
        nLandIndex = nLandIndex,
    }

    ChatArgs.Append(tbArg)
end

function ChatArgs.Append_toybox(szToyBoxName, dwID)
    local tbArg =
    {
        szSendType   = "toybox",
        szText       = szToyBoxName,
        szToyBoxName = szToyBoxName,
        nToyBoxID    = dwID,
    }

    ChatArgs.Append(tbArg)
end

function ChatArgs.Append_website(szUrl)
    local tbArg =
    {
        szSendType = "website",
        szText     = szUrl,
        szWebsite  = szUrl,
    }

    ChatArgs.Append(tbArg)
end

function ChatArgs.Append_landorder(dwID, nMoney, szPlayerName, szName)
    local tbArg =
    {
        szSendType   = "landorder",
        szText       = szName,
        dwID         = dwID,
        nMoney       = nMoney,
        szPlayerName = szPlayerName,
        szMsg        = szName,
    }

    ChatArgs.Append(tbArg)
end





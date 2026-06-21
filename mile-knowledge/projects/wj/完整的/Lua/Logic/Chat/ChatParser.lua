ChatParser = ChatParser or {}




function ChatParser.Parse(szMsg)
    local tbMsg = {}

    -- 7878[画楼衫]12[拂晓][拂晓][[[]][]][#媚眼]888中国[11]xxx[]
    local tbSplit = {}
    if not string.is_nil(szMsg) then
        local nIndex = 0
        local nLastEndIndex = 0
        local nLen = string.len(szMsg)
        for nBeginIndex, nEndIndex in function() return string.find(szMsg, "%b[]", nIndex) end do
            -- 先找出标签所在位置
            local szLabel = string.sub(szMsg, nBeginIndex + 1, nEndIndex - 1)

            -- 再找出非标签
            if nLastEndIndex ~= (nBeginIndex - 1) then
                local szPureText = string.sub(szMsg, nLastEndIndex + 1, nBeginIndex - 1)
                if not string.is_nil(szPureText) then
                    table.insert(tbSplit, {szText = szPureText, bIsLabel = false})
                end
            end

            if not string.is_nil(szLabel) then
                table.insert(tbSplit, {szText = szLabel, bIsLabel = true}) -- bIsLabel = true -- 表示是带[]标签的
            else
                table.insert(tbSplit, {szText = "[]", bIsLabel = false})
            end

            nLastEndIndex = nEndIndex
            nIndex = nEndIndex + 1
        end

        -- 最后面还有
        if nLastEndIndex < nLen then
            local szPureText = string.sub(szMsg, nLastEndIndex + 1, nLen)
            if not string.is_nil(szPureText) then
                table.insert(tbSplit, {szText = szPureText, bIsLabel = false})
            end
        end

        -- 解析
        if not table.is_empty(tbSplit) then
            ChatParser._parse(tbMsg, tbSplit)
        end
    end

    return tbMsg
end

function ChatParser._parse(tbMsg, tbSplit)
    local nArgIndex = 1
    local nEmojiIndex = 1
    local szUIChannel = ChatData.GetRuntimeSelectDisplayChannel()
    for k, v in ipairs(tbSplit) do
        local szText = v.szText -- UTF8
        local bIsLabel = v.bIsLabel
        if bIsLabel then
            local tbArg = ChatArgs.tbList and ChatArgs.tbList[szUIChannel] and ChatArgs.tbList[szUIChannel][nArgIndex]
            local szSendType = tbArg and tbArg.szSendType
            local szArgText = tbArg and tbArg.szText or ""
            local szArgGBKText = UTF8ToGBK(szText)
            local szDisplayText = string.format("[%s]", szArgGBKText)

            if string.find(szText, "#", 1, true) == 1 then -- 表情
                local tbOneMsg = ChatParser._parse_emoji(szText, szDisplayText, nEmojiIndex)
                table.insert(tbMsg, tbOneMsg)

                nEmojiIndex = nEmojiIndex + 1
            else
                if tbArg and szArgText == szText then
                    if not string.is_nil(szSendType) and IsFunction(ChatParser["_parse_"..szSendType]) then
                        local tbOneMsg = ChatParser["_parse_"..szSendType](szText, szDisplayText, tbArg)
                        table.insert(tbMsg, tbOneMsg)
                    else
                        if not string.is_nil(szText) then
                            table.insert(tbMsg, {type = "text", text = szDisplayText})
                        end
                    end

                    nArgIndex = nArgIndex + 1
                else
                    if not string.is_nil(szText) then
                        table.insert(tbMsg, {type = "text", text = szDisplayText})
                    end
                end
            end
        else
            if not string.is_nil(szText) then
                table.insert(tbMsg, {type = "text", text = UTF8ToGBK(szText)})
            end
        end
    end


    --[[
    local nHeadStart, nHeadEnd = string.find(szMsg, "[", 1, true)
    if nHeadStart == nil then
        if not string.is_nil(szMsg) then
            table.insert(tbMsg, {type = "text", text = UTF8ToGBK(szMsg)})
        end
    else
        local nTailStart, nTailEnd = string.find(szMsg, "]", 1, true)
        if nTailStart == nil then
            if not string.is_nil(szMsg) then
                table.insert(tbMsg, {type = "text", text = UTF8ToGBK(szMsg)})
            end
        else

            if nHeadStart < nTailStart then
                local szPre = string.sub(szMsg, 1, nHeadStart - 1)
                if not string.is_nil(szPre) then
                    table.insert(tbMsg, {type = "text", text = UTF8ToGBK(szPre)})
                end

                local szContent = string.sub(szMsg, nHeadStart + 1, nTailStart - 1)
                if string.is_nil(szContent) then
                    table.insert(tbMsg, {type = "text", text = "[]"})
                else
                    local szGBKText = "["..UTF8ToGBK(szContent).."]"
                    local szSendType = ChatArgs.szSendType

                    -- 表情
                    if string.find(szContent, "#", 1, true) == 1 then
                        local tbOneMsg = ChatParser._parse_emoji(szContent, szGBKText)
                        table.insert(tbMsg, tbOneMsg)
                    elseif not string.is_nil(szSendType) and IsFunction(ChatParser["_parse_"..szSendType]) then
                        local tbOneMsg = ChatParser["_parse_"..szSendType](szContent, szGBKText)
                        table.insert(tbMsg, tbOneMsg)
                    else
                        table.insert(tbMsg, {type = "text", text = szGBKText})
                    end
                end

                szMsg = string.sub(szMsg, nTailStart + 1)
                ChatParser._parse(tbMsg, szMsg)
            end

        end
    end
    ]]
end

-- 表情
function ChatParser._parse_emoji(szEmojiName, szGBKText, nEmojiIndex)
    local tbOneMsg = {}
    local tbEmojiConf = ChatArgs.GetEmoji(nEmojiIndex, szEmojiName) or ChatData.GetEmojiConfByName(szEmojiName)
    if tbEmojiConf then
        tbOneMsg = {type = "emotion", text = szGBKText, id = tbEmojiConf.nID}
    else
        tbOneMsg = {type = "text", text = szGBKText}
    end
    return tbOneMsg
end

-- 道具
function ChatParser._parse_item(szItemName, szGBKText, tbArg)
    local tbOneMsg = {}

    if tbArg.nItemID and szItemName == tbArg.szItemName then
        tbOneMsg = {type = "item", text = szGBKText, item = tbArg.nItemID}
    else
        tbOneMsg = {type = "text", text = szGBKText}
    end

    return tbOneMsg
end

-- 道具信息
function ChatParser._parse_iteminfo(szItemName, szGBKText, tbArg)
    local tbOneMsg = {}

    if szItemName == tbArg.szItemName then
        tbOneMsg = {type = "iteminfo", text = szGBKText, version = tbArg.nVersion, tabtype = tbArg.nTabType, index = tbArg.nIndex}
    else
        tbOneMsg = {type = "text", text = szGBKText}
    end

    return tbOneMsg
end

-- 任务
function ChatParser._parse_quest(szQuestName, szGBKText, tbArg)
    local tbOneMsg = {}

    if tbArg.nQuestID and szQuestName == tbArg.szQuestName then
        tbOneMsg = {type = "quest", text = szGBKText, questid = tbArg.nQuestID}
    else
        tbOneMsg = {type = "text", text = szGBKText}
    end

    return tbOneMsg
end

-- Book
function ChatParser._parse_book(szSegmentName, szGBKText, tbArg)
    local tbOneMsg = {}

    if szSegmentName == tbArg.szSegmentName then
        tbOneMsg = {type = "book", text = szGBKText, version = tbArg.nVersion, tabtype = tbArg.nTabType, index = tbArg.nIndex, bookinfo = tbArg.nBookInfo}
    else
        tbOneMsg = {type = "text", text = szGBKText}
    end

    return tbOneMsg
end

-- Player
function ChatParser._parse_name(szPlayerName, szGBKText, tbArg)
    local tbOneMsg = {}

    if szPlayerName == tbArg.szPlayerName then
        tbOneMsg = {type = "name", text = szGBKText, name = UTF8ToGBK(szPlayerName)}
    else
        tbOneMsg = {type = "text", text = szGBKText}
    end

    return tbOneMsg
end

-- Recipe
function ChatParser._parse_recipe(szRecipeName, szGBKText, tbArg)
    local tbOneMsg = {}

    if szRecipeName == tbArg.szRecipeName then
        tbOneMsg = {type = "recipe", text = szGBKText, craftid = tbArg.nCraftID, recipeid = tbArg.nRecipeID}
    else
        tbOneMsg = {type = "text", text = szGBKText}
    end

    return tbOneMsg
end

-- Enchant
function ChatParser._parse_enchant(szEnchantName, szGBKText, tbArg)
    local tbOneMsg = {}

    if szEnchantName == tbArg.szEnchantName then
        tbOneMsg = {type = "enchant", text = szGBKText, proid = tbArg.nProID,  craftid = tbArg.nCraftID, recipeid = tbArg.nRecipeID}
    else
        tbOneMsg = {type = "text", text = szGBKText}
    end

    return tbOneMsg
end

-- Skill
function ChatParser._parse_skill(szSkillName, szGBKText, tbArg)
    local tbOneMsg = {}

    if szSkillName == tbArg.szSkillName and g_pClientPlayer then
        local skillKey = g_pClientPlayer.GetSkillRecipeKey(tbArg.nSkillID, tbArg.nSkillLevel)
        if not skillKey then
            return
        end

        skillKey.type = "skill"
	    skillKey.text = szGBKText

        tbOneMsg = skillKey
    else
        tbOneMsg = {type = "text", text = szGBKText}
    end

    return tbOneMsg
end

-- Skill Recipe
function ChatParser._parse_skillrecipe(szSkillRecipeName, szGBKText, tbArg)
    local tbOneMsg = {}

    if szSkillRecipeName == tbArg.szSkillRecipeName then
        tbOneMsg = {type = "skillrecipe", text = szGBKText, id = tbArg.nSkillID,  level = tbArg.nSkillLevel}
    else
        tbOneMsg = {type = "text", text = szGBKText}
    end

    return tbOneMsg
end

-- Achievement
function ChatParser._parse_achievement(szAchievementName, szGBKText, tbArg)
    local tbOneMsg = {}

    if szAchievementName == tbArg.szAchievementName then
        tbOneMsg = {type = "achievement", text = szGBKText, id = tbArg.nAchievementID}
    else
        tbOneMsg = {type = "text", text = szGBKText}
    end

    return tbOneMsg
end

-- Designation
function ChatParser._parse_designation(szDesignationName, szGBKText, tbArg)
    local tbOneMsg = {}

    if szDesignationName == tbArg.szDesignationName then
        tbOneMsg = {type = "designation", text = szGBKText, id = tbArg.nDesignationID, prefix = tbArg.bPrefix, forceid = tbArg.dwForceID}
    else
        tbOneMsg = {type = "text", text = szGBKText}
    end

    return tbOneMsg
end

-- EventLink
function ChatParser._parse_eventlink(szEventLinkName, szGBKText, tbArg)
    local tbOneMsg = {}

    if szEventLinkName == tbArg.szEventLinkName then
        tbOneMsg = {type = "eventlink", text = szGBKText, name = szGBKText, linkinfo = tbArg.szLinkInfo or ""}
    else
        tbOneMsg = {type = "text", text = szGBKText}
    end

    return tbOneMsg
end

-- Pet
function ChatParser._parse_pet(szPetName, szGBKText, tbArg)
    local tbOneMsg = {}

    if szPetName == tbArg.szPetName then
        tbOneMsg = {type = "pet", text = szGBKText, id = tbArg.nPetIndex}
    else
        tbOneMsg = {type = "text", text = szGBKText}
    end

    return tbOneMsg
end

-- Land
function ChatParser._parse_land(szLandName, szGBKText, tbArg)
    local tbOneMsg = {}

    if szLandName == tbArg.szLandName then
        tbOneMsg = {type = "land", text = szGBKText, index = tbArg.nIndex,  mapid = tbArg.nMapID, copyindex = tbArg.nCopyIndex, landindex = tbArg.nLandIndex}
    else
        tbOneMsg = {type = "text", text = szGBKText}
    end

    return tbOneMsg
end

-- ToyBox
function ChatParser._parse_toybox(szToyBoxName, szGBKText, tbArg)
    local tbOneMsg = {}

    if szToyBoxName == tbArg.szToyBoxName then
        tbOneMsg = {type = "toybox", text = szGBKText, id = tbArg.nToyBoxID}
    else
        tbOneMsg = {type = "text", text = szGBKText}
    end

    return tbOneMsg
end

-- Website
function ChatParser._parse_website(szWebsite, szGBKText, tbArg)
    local tbOneMsg = {}

    if szWebsite == tbArg.szWebsite then
        tbOneMsg = {type = "website", text = szGBKText, szWebsite = tbArg.szWebsite}
    else
        tbOneMsg = {type = "text", text = szGBKText}
    end

    return tbOneMsg
end

-- HomelandOrder
function ChatParser._parse_landorder(szHomeOrder, szGBKText, tbArg)
    local tbOneMsg = {}

    if szHomeOrder == g_tStrings.STR_HOMELAND_ASSIST_ORDER then
        tbOneMsg = {type = "landorder", text = szGBKText, id = tbArg.dwID, money = tbArg.nMoney, name = tbArg.szPlayerName}
    else
        tbOneMsg = {type = "text", text = szGBKText}
    end

    return tbOneMsg
end
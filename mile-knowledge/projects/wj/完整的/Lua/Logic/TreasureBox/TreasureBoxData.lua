TreasureBoxData          = TreasureBoxData or {}


--  奖励内容 名字为索引
function TreasureBoxData.InitAward()
    if TreasureBoxData.tAward and not table.is_empty(TreasureBoxData.tAward) then
        return
    end
    local tAwardBase = Table_GetTreasureAwardList()
    TreasureBoxData.tAward = {}
    for _, tInfo in pairs(tAwardBase) do
        local dwBoxID = tInfo.dwID
        local szBoxName = UIHelper.GBKToUTF8(tInfo.szBoxName)
        if not TreasureBoxData.tAward[dwBoxID] then
            TreasureBoxData.tAward[dwBoxID] = {}
        end
        if not tInfo.szContentType or tInfo.szContentType == "" then
            local szAwardName = UIHelper.GBKToUTF8(tInfo.szName)
            TreasureBoxData.tAward[dwBoxID][szAwardName] = {}
            TreasureBoxData.tAward[dwBoxID][szAwardName].tInfo = tInfo
            TreasureBoxData.tAward[dwBoxID][szAwardName].bTable = false
        else
            local szContentName = UIHelper.GBKToUTF8(tInfo.szContentType)
            if not TreasureBoxData.tAward[dwBoxID][szContentName] then
                TreasureBoxData.tAward[dwBoxID][szContentName] = {}
                TreasureBoxData.tAward[dwBoxID][szContentName].bTable = true
                TreasureBoxData.tAward[dwBoxID][szContentName].tInfo = {}
            end
            table.insert(TreasureBoxData.tAward[dwBoxID][szContentName].tInfo, tInfo)
        end
    end
end

function TreasureBoxData.GetAwardList(dwBoxID)
    if dwBoxID then
        return TreasureBoxData.tAward[dwBoxID] or nil
    else
        return TreasureBoxData.tAward
    end
end

function TreasureBoxData.GetQiYuAwardType(dwBoxID)
    local tAward = TreasureBoxData.GetAwardList(dwBoxID)
    local tReturn = {}
    local szName2Index = {
        ["绝世奇遇"] = 2,
        ["普通奇遇"] = 3,
        ["宠物奇遇"] = 4,
        ["烟花"] = 5,
    }
    for szName, _ in pairs(tAward) do
        if szName2Index[szName] then
            local index = szName2Index[szName]
            tReturn[index] = true
        end
    end
    return tReturn
end

function TreasureBoxData.GetQiYuAwardList(dwBoxID)
    local tAward = TreasureBoxData.GetAwardList(dwBoxID)
    local tReturn = {}

    local function Extract(tInfo)
        local tTmp = {}
        if tInfo.nLuckyID and tInfo.nLuckyID ~= 0 then
            tTmp.bItem = false
            tTmp.szName = UIHelper.GBKToUTF8(tInfo.szName)
            tTmp.nLuckyID = tInfo.nLuckyID
            if tInfo.szItem and tInfo.szItem ~= "" then
                tTmp.dwType, tTmp.dwIndex = TreasureBoxData.SplitItemID(tInfo.szItem)
            end
        else
            tTmp.bItem = true
            tTmp.szName = UIHelper.GBKToUTF8(tInfo.szName)
            tTmp.dwType, tTmp.dwIndex = TreasureBoxData.SplitItemID(tInfo.szItem)
        end

        if tInfo.szImageType == "" then
            tTmp.szImgFile = tInfo.szVKImagePath
        else
            local nSchool = GetClientPlayer().dwForceID
            local nCamp   = GetClientPlayer().nCamp
            local szType  = tInfo.szImageType
            local szPath  = tInfo.szVKImagePath
            if szType == "school" then
                tTmp.szImgFile = szPath .. "/" .. szType .. "_" .. nSchool .. "_Open.png"
            elseif szType == "camp" then
                tTmp.szImgFile = szPath .. "/" .. szType .. "_" .. nCamp .. "_Open.png"
            end
        end

        -- tTmp.szImgFile = tInfo.szVKImagePath
        tTmp.nContentType = tInfo.nContentType
        tTmp.nContentID = tInfo.nContentID
        tTmp.nLuckyCamp = tInfo.nLuckyCamp
        return tTmp
    end

    for _, tList in pairs(tAward) do
        if tList.bTable then
            for _, tInfo in ipairs(tList.tInfo) do
                local tTmp = Extract(tInfo)
                table.insert(tReturn, tTmp)
            end
        else
            local tTmp = Extract(tList.tInfo)
            table.insert(tReturn, tTmp)
        end
    end

    tReturn = TreasureBoxData.Sort(tReturn)
    return tReturn
end

function TreasureBoxData.GetOptionalAwardList(dwBoxID)
    local tAward = TreasureBoxData.GetAwardList(dwBoxID)

    local tReturn = {}
    local tType = {}
    for szName, tList in pairs(tAward) do
        local nContentType = tList.tInfo[1].nContentType
        tReturn[nContentType] = tList.tInfo
        tType[nContentType] = szName
    end
    
    return tReturn, tType
end


-- 奇遇box
function TreasureBoxData.InitQiYuBox()
    if TreasureBoxData.tQiYuBox and not table.is_empty(TreasureBoxData.tQiYuBox) then
        return
    end
    local tTreasureBox = Table_GetTreasureBoxList()
    TreasureBoxData.tQiYuBox = {}
    for _, tInfo in pairs(tTreasureBox) do
        if tInfo.nGroupID == TREASURE_BOX_TYPE.QIYU then
            local tTmp = {}
            tTmp.dwID = tInfo.dwID
            tTmp.dwType, tTmp.dwIndex = TreasureBoxData.SplitItemID(tInfo.szBoxItem)
            tTmp.szItemName = UIHelper.GBKToUTF8(tInfo.szItemName)
            tTmp.bOwnToShow = tInfo.bOwnToShow
            table.insert(TreasureBoxData.tQiYuBox, tTmp)
        end
    end
end

function TreasureBoxData.GetQiYuBox()
    return TreasureBoxData.tQiYuBox
end

-- 自选box
function TreasureBoxData.InitOptionalBox()
    if TreasureBoxData.tOptionalBox and not table.is_empty(TreasureBoxData.tOptionalBox) then
        return
    end
    local tTreasureBox = Table_GetTreasureBoxList()
    TreasureBoxData.tOptionalBox = {}
    for _, tInfo in pairs(tTreasureBox) do
        if tInfo.nGroupID == TREASURE_BOX_TYPE.OPTIONAL then
            table.insert(TreasureBoxData.tOptionalBox, tInfo)
        end
    end
end

function TreasureBoxData.GetOptionalBox()
    return TreasureBoxData.tOptionalBox
end

-- 随机box
function TreasureBoxData.InitRandomBox()
    if TreasureBoxData.tRandomBox and not table.is_empty(TreasureBoxData.tRandomBox) then
        return
    end
    local tTreasureBox = Table_GetTreasureBoxList()
    TreasureBoxData.tRandomBox = {}
    for _, tInfo in pairs(tTreasureBox) do
        if tInfo.nGroupID == TREASURE_BOX_TYPE.RANDOM then
            if not TreasureBoxData.tRandomBox[tInfo.nTypeID] then
                TreasureBoxData.tRandomBox[tInfo.nTypeID] = {}
            end
            table.insert(TreasureBoxData.tRandomBox[tInfo.nTypeID], tInfo)
        end
    end
end

function TreasureBoxData.GetRandomBox(nType)
    if nType then
        return TreasureBoxData.tRandomBox[nType] or TreasureBoxData.tRandomBox
    else
        return TreasureBoxData.tRandomBox
    end
end

--

function TreasureBoxData.InitBoxTab2IDList()
    if TreasureBoxData.tTab2ID and not table.is_empty(TreasureBoxData.tTab2ID) then
        return
    end

    TreasureBoxData.tTab2ID = {}
    local tTreasureBox = Table_GetTreasureBoxList()
    for _, tInfo in pairs(tTreasureBox) do
        local dwType, dwIndex = TreasureBoxData.SplitItemID(tInfo.szBoxItem)
        local skey = dwType .. "_" .. dwIndex
        TreasureBoxData.tTab2ID[skey] = tInfo.dwID
    end
end

function TreasureBoxData.GetBoxIDByTab(nTabType, nTabID)
    TreasureBoxData.InitBoxTab2IDList()
    if nTabType and nTabID then
        local skey = nTabType .. "_" .. nTabID
        return TreasureBoxData.tTab2ID[skey]
    else
        return
    end
end

function TreasureBoxData.GetRewardItemInfo(nTabType, nTabID)
    if nTabType and nTabID then
        local tAward = Table_GetTreasureAwardList()
        for _, tInfo in ipairs(tAward) do
            local dwType, dwIndex = TreasureBoxData.SplitItemID(tInfo.szItem)
            if dwType == nTabType and dwIndex == nTabID then
                return tInfo
            end
        end
    end
end

function TreasureBoxData.GetPreviewBtn(tbBtn, nTabType, nTabID)
    tbBtn = tbBtn or {}
    local nBoxID = TreasureBoxData.GetBoxIDByTab(nTabType, nTabID)
    if nBoxID then
        local tBoxInfo = Tabel_GetTreasureBoxListByID(nBoxID)
        if tBoxInfo and tBoxInfo.nGroupID then
            if tBoxInfo.nGroupID == TREASURE_BOX_TYPE.RANDOM then
                table.insert(tbBtn, {
                    szName = "查看奖励",
                    OnClick = function ()
                        UIMgr.Open(VIEW_ID.PanelRandomTreasureBox, nBoxID)
                    end
                })
            elseif tBoxInfo.nGroupID == TREASURE_BOX_TYPE.OPTIONAL then
                table.insert(tbBtn, {
                    szName = "查看奖励",
                    OnClick = function ()
                        UIMgr.Open(VIEW_ID.PanelOptionalTreasureBox, nBoxID)
                    end
                }) 
            end
        end
    end
    return tbBtn
end

-- 
function TreasureBoxData.SplitItemID(szBoxItem, bReturnAll)
    local tItemList = {}
    if string.is_nil(szBoxItem) then
        return bReturnAll and tItemList or nil
    end

    local szItemList = SplitString(szBoxItem, "|")
    for _, szItem in ipairs(szItemList) do
        local tItem = {}
        for s in string.gmatch(szItem, "%d+") do
            local n = tonumber(s)
            table.insert(tItem, n)
        end
        table.insert(tItemList, tItem)
    end

    if not bReturnAll then
        local dwType = tItemList[1] and tItemList[1][1]
        local dwIndex = tItemList[1] and tItemList[1][2]
        return dwType, dwIndex
    else
        return tItemList
    end
end

function TreasureBoxData.CheckCollected(tInfo)
    local bCollt = false
    if not tInfo or table.is_empty(tInfo) then
        return
    end

    if tInfo and not string.is_nil(tInfo.szAndItem) then
        for index, szItem in ipairs(SplitString(tInfo.szAndItem, "|")) do
            local tTemp = {szItem = szItem}
            bCollt = TreasureBoxData.IsHaveItem(tTemp)
            if not bCollt then
                break
            end
        end

        if not bCollt and tInfo.szOtherItem and tInfo.szOtherItem ~= "" then
            for index, szItem in ipairs(SplitString(tInfo.szOtherItem, "|")) do
                local tTemp = {szItem = szItem}
                bCollt = TreasureBoxData.IsHaveItem(tTemp)
                if bCollt then
                    break
                end
            end
        end
        return bCollt
    end

    bCollt = bCollt or TreasureBoxData.IsHaveItem(tInfo)
    return bCollt
end

function TreasureBoxData.IsHaveItem(tInfo)
    local bHave = false
    local bRet = false

    -- if tInfo.nPetID and tInfo.nPetID ~= 0 then -- 宠物
    --     bRet = g_pClientPlayer.IsFellowPetAcquired(tInfo.nPetID) 
    --     if bRet then
    --         return true
    --     end
    -- end

    -- if tInfo.nAvatarID and tInfo.nAvatarID ~= 0 then
    --     local AvatarMgr = g_pClientPlayer.GetMiniAvatarMgr()
    --     if not AvatarMgr.bDataSynced then
    --         AvatarMgr.ApplyMiniAvatarData()
    --     end
    --     bRet = AvatarMgr.IsMiniAvatarAcquired(tInfo.nAvatarID)
    --     if bRet then
    --         return true
    --     end
    -- end

    if tInfo.nFaceID and tInfo.nFaceID ~= 0 then
        bRet = g_pClientPlayer.IsHaveBrightMark(tInfo.nFaceID)
        if bRet then
            return true
        end
    end

    -- if tInfo.nPrefixID and tInfo.nPrefixID ~= 0 then -- 脚印称号（前缀）
    --     bRet = g_pClientPlayer.IsDesignationPrefixAcquired(tInfo.nPrefixID)
    --     if bRet then
    --         return true
    --     end
    -- end
    
    -- if tInfo.nPostfixID and tInfo.nPostfixID ~= 0 then -- 脚印称号（后缀）
    --     bRet = g_pClientPlayer.IsDesignationPostfixAcquired(tInfo.nPostfixID)
    --     if bRet then
    --         return true
    --     end
    -- end

    if tInfo.dwSkinID and tInfo.dwSkinID ~= 0 then -- 武技殊影图
        if g_pClientPlayer.IsHaveSkillSkin(tInfo.dwSkinID) then
            bHave = true
        end
    end

    if tInfo.nFaceID and tInfo.nFaceID ~= 0 then -- 头顶表情
        if g_pClientPlayer.IsHaveBrightMark(tInfo.nFaceID) then
            bHave = true
        end
    end

    if tInfo.nExteriorID and tInfo.nExteriorID ~= 0 then
        bRet = g_pClientPlayer.IsHaveExterior(tInfo.nExteriorID) or TreasureBoxData.CheckNPCIsHaveExterior(g_pClientPlayer, tInfo.nExteriorID)
        if bRet then
            return true
        end
    end

    if tInfo.nPendentID and tInfo.nPendentID ~= 0 then
        bRet = g_pClientPlayer.IsPendentExist(tInfo.nPendentID)
        if bRet then
            return true
        end
    end

    if tInfo.nQuestID and tInfo.nQuestID ~= 0 then  -- 任务判定收集
        local nAccQuest = g_pClientPlayer.GetQuestPhase(tInfo.nQuestID)
        if nAccQuest == QUEST_PHASE.FINISH then
            return true
        end
    end

    -- if tInfo.bScriptCollect then   -- 需要策划脚本判特殊情况
    --     local tInfo = {dwIndex = tInfo.dwIndex, dwTabType = tInfo.dwTabType}
    --     if GDAPI_SpecialRuleContent(tInfo) then
    --         bHave = true
    --     end
    -- end

    local tItemList = TreasureBoxData.SplitItemID(tInfo.szItem, true)
    for _, tList in ipairs(tItemList) do
        local dwType = tList[1]
        local dwIndex = tList[2]
        if tInfo.bScriptCollect then   -- 需要策划脚本判特殊情况
            local tInfo = {dwIndex = dwIndex, dwTabType = dwType}
            if GDAPI_SpecialRuleContent(tInfo) then
                bHave = true
            end
        end
        bHave = bHave or ItemData.GetGeneralItemCollectState(dwType, dwIndex)
    end

    if tInfo.szOtherItem and tInfo.szOtherItem ~= "" then
        tItemList = TreasureBoxData.SplitItemID(tInfo.szOtherItem, true)
        for _, tList in ipairs(tItemList) do
            local dwType = tList[1]
            local dwIndex = tList[2]
            local nAllBag = g_pClientPlayer.GetItemAmountInAllPackages(dwType, dwIndex)
            if nAllBag and nAllBag ~= 0 then
                return true
            elseif ItemData.GetGeneralItemCollectState(dwType, dwIndex) then
                return true
            end
        end
    end

    return bHave
end

function TreasureBoxData.CheckItemIsHave(dwType, dwIndex)
    -- 参考 UIItemTip:UpdateCollectedInfo
    if not dwType or not dwIndex then
        return false
    end
    local item = ItemData.GetItemInfo(dwType, dwIndex)
    if not item then
        return false
    end
    local nAllBag = g_pClientPlayer.GetItemAmountInAllPackages(dwType, dwIndex)
    if nAllBag and nAllBag ~= 0 then
        return true
    end

    local bCollected = false
    if item.nGenre == ITEM_GENRE.EQUIPMENT and ItemData.IsPendantItem(item) then
        --挂件
        bCollected = g_pClientPlayer.IsPendentExist(dwIndex)
    elseif item.nGenre == ITEM_GENRE.EQUIPMENT and ItemData.IsPendantPetItem(item) then
        --挂宠
        bCollected = g_pClientPlayer.IsHavePendentPet(dwIndex)
    elseif item.nGenre == ITEM_GENRE.TOY then
        --玩具
        local tToy = Table_GetToyBoxByItem(dwIndex)
        if tToy then
            bCollected = bCollected or GDAPI_IsToyHave(g_pClientPlayer, tToy.dwID, tToy.nCountDataIndex)
        end
    elseif item.nGenre == ITEM_GENRE.EQUIPMENT and item.nSub == EQUIPMENT_SUB.PET then
        -- 宠物
        local nPetIndex = GetFellowPetIndexByItemIndex(ITEM_TABLE_TYPE.CUST_TRINKET, dwIndex)
        bCollected      = g_pClientPlayer.IsFellowPetAcquired(nPetIndex)
    elseif item.nGenre == ITEM_GENRE.HOMELAND then
		-- 家具
        bCollected = HomelandEventHandler.IsFurnitureCollected(item.dwFurnitureID)
    elseif item.nSub == EQUIPMENT_SUB.HORSE_EQUIP then
        -- 马具
        local tList = g_pClientPlayer.GetAllHorseEquip()
        for _, tItem in ipairs(tList) do
            if tItem.dwItemIndex == dwIndex then
                bCollected = true
                break
            end
        end
    end

    if item.nPrefixID and item.nPrefixID ~= 0 then -- 称号（前缀、世界）
		bCollected = bCollected or g_pClientPlayer.IsDesignationPrefixAcquired(item.nPrefix)
	end

	if item.nPostfix and item.nPostfix ~= 0 then -- 称号（后缀)
        bCollected = bCollected or g_pClientPlayer.IsDesignationPostfixAcquired(item.nPostfix)
	end

    return bCollected
end

local function CheckGoodsNPCAlreadyHave (nNpcType, dwGoodsID)
    local hPlayer = GetClientPlayer()
	if not hPlayer then
		return
	end
	local hNpcExteriorMgr = GetNpcExteriorManager()
	if not hNpcExteriorMgr then
		return
	end
	local tNpcAssisted = hPlayer.GetAllNpcAssisted()
	if not tNpcAssisted then
		return false
	end
	for _, dwAssistedID in ipairs(tNpcAssisted) do
		local bHave = hNpcExteriorMgr.CheckAlreadyHave(hPlayer.dwID, dwAssistedID, nNpcType, dwGoodsID)
		if bHave then
			return true
		end
	end
	return false
end

function TreasureBoxData.CheckNPCIsHaveExterior(player, dwExteriorID)
    if CheckGoodsNPCAlreadyHave(NPC_EXTERIOR_TYPE.CHEST, dwExteriorID) then
        return true
    end

	return false
end

function TreasureBoxData.Sort(tInfo)
    local function fnADegree(a, b)
        if a.nContentType == b.nContentType then
            return a.nContentID < b.nContentID
        else
            return a.nContentType < b.nContentType
        end
	end

    local function fnBDegree(a, b)
        if a.tInfo.nContentType == b.tInfo.nContentType then
            return a.tInfo.nContentID < b.tInfo.nContentID
        else
            return a.tInfo.nContentType < b.tInfo.nContentType
        end
	end

    local function fnCDegree(a, b)
        if a.tInfo[1].nContentType == b.tInfo[1].nContentType then
            return a.tInfo[1].nContentID < b.tInfo[1].nContentID
        else
            return a.tInfo[1].nContentType < b.tInfo[1].nContentType
        end
    end

    if tInfo[1].bTable == true then
        table.sort(tInfo, fnCDegree)
    elseif tInfo[1].bTable == false then
        table.sort(tInfo, fnBDegree)
    else
        table.sort(tInfo, fnADegree)
    end

    return tInfo
end

function TreasureBoxData.OpenByLinkEvent(szLinkArg)
    local tLinkArg = SplitString(szLinkArg, "/")
    if not tLinkArg or #tLinkArg < 1 then
        return
    end

    local nBoxID = tonumber(tLinkArg[1])
    if not nBoxID then
        return
    end

    local tBoxInfo = Tabel_GetTreasureBoxListByID(nBoxID)
    if tBoxInfo and tBoxInfo.nGroupID then
        if tBoxInfo.nGroupID == TREASURE_BOX_TYPE.RANDOM then
            UIMgr.Open(VIEW_ID.PanelRandomTreasureBox, nBoxID)
            return
        elseif tBoxInfo.nGroupID == TREASURE_BOX_TYPE.QIYU then
            UIMgr.Open(VIEW_ID.PanelQiYuTreasureBox, nBoxID)
            return
        elseif tBoxInfo.nGroupID == TREASURE_BOX_TYPE.OPTIONAL then
            UIMgr.Open(VIEW_ID.PanelOptionalTreasureBox, nBoxID)
            return
        end
    end
    UIMgr.Open(VIEW_ID.PanelRandomTreasureBox, nBoxID)
end

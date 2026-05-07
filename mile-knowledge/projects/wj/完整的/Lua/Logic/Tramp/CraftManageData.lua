-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: CraftManageData
-- Date: 2023-04-14 10:26:03
-- Desc: ?
-- ---------------------------------------------------------------------------------

CraftManageData = CraftManageData or {}
local self = CraftManageData
-------------------------------- 消息定义 --------------------------------
CraftManageData.Event = {}
CraftManageData.Event.XXX = "CraftManageData.Msg.XXX"

function CraftManageData.Init(nClassificationID, tCraftLevel, nTargetType, nTargetID)
    self.nClassificationID = nClassificationID
    self.nTargetType = nTargetType
    self.nTargetID = nTargetID
    self.tCraftLevel = {}
    for _, nCraftLevel in ipairs(tCraftLevel) do
        self.tCraftLevel[nCraftLevel] = true
    end
    self.UpadateCraftInfos(nClassificationID)
    self.UpdatePlayerItemNum()
    UIMgr.Open(VIEW_ID.PanelePharmacyMain)
end

function CraftManageData.UpadateCraftInfos(nClassificationID)
    self.tCraftInfos = {}
    self.tFilterName = {}
    local tCraftInfos = Table_GetVagabondCraftInfo(nClassificationID)
    for _, tCraftInfo in ipairs(tCraftInfos) do
        self.tFilterName[tCraftInfo.szRareName] = true
        self.tCraftInfos[tCraftInfo.szTypeName] = self.tCraftInfos[tCraftInfo.szTypeName] or {}
        local tFormatInfo = {}
        tFormatInfo.nID = tCraftInfo.nID
        tFormatInfo.nCraftLevel = tCraftInfo.nCraftLevel
        tFormatInfo.szRareName = tCraftInfo.szRareName
        tFormatInfo.szUnlockTip = tCraftInfo.szUnlockTip
        local tSplit = SplitString(tCraftInfo.szItemInfo, ';')
        tFormatInfo.nItemType = tonumber(tSplit[1])
        tFormatInfo.nItemID = tonumber(tSplit[2])
        tFormatInfo.tRecipe = {}
        tSplit = SplitString(tCraftInfo.szRecipe, '|')
        for _, szSub in ipairs(tSplit) do
            local tRecipeItem = {}
            local tSubSplit = SplitString(szSub, ';')
            tRecipeItem.nItemType = tonumber(tSubSplit[1])
            tRecipeItem.nItemID = tonumber(tSubSplit[2])
            tRecipeItem.nNum = tonumber(tSubSplit[3])
            table.insert(tFormatInfo.tRecipe, tRecipeItem)
        end
        if tCraftInfo.nUseBuffID and tCraftInfo.nUseBuffID ~= 0 then
            tFormatInfo.nUseBuffID = tCraftInfo.nUseBuffID
            tFormatInfo.nBuffStackCost = tCraftInfo.nBuffStackCost
            tFormatInfo.nBuffImgFrame = tCraftInfo.nBuffImgFrame
        end
        table.insert(self.tCraftInfos[tCraftInfo.szTypeName], tFormatInfo)
    end

    for szTypeName, tCraftInfos in pairs(self.tCraftInfos) do
        if tCraftInfos[1] then
            self.tCurrentCraftInfo = tCraftInfos[1]
            break
        end
    end
end


function CraftManageData.UpdatePlayerItemNum()
    self.tPlayerItemNum = TravellingBagData.GetAllItemStackNum()
    for szTypeName, tCraftInfos in pairs(self.tCraftInfos) do
        for _, tCraftInfo in ipairs(tCraftInfos) do
            tCraftInfo.nMaxMakeNum = self.GetMaxMakeNumber(tCraftInfo)
        end
    end
end

function CraftManageData.GetPlayerItemNum(nItemType, nItemID)
    if self.tPlayerItemNum[nItemType] and self.tPlayerItemNum[nItemType][nItemID] then
        return self.tPlayerItemNum[nItemType][nItemID]
    end
    return 0
end

function CraftManageData.GetMaxMakeNumber(tCraftInfo)
    local nMaxMakeNum
    for _, tRecipeItem in ipairs(tCraftInfo.tRecipe) do
        local nItemType, nItemID, nNum = tRecipeItem.nItemType, tRecipeItem.nItemID, tRecipeItem.nNum
        local nMakeNum = math.floor(self.GetPlayerItemNum(nItemType, nItemID) / nNum)
        if not nMaxMakeNum or nMakeNum < nMaxMakeNum then
            nMaxMakeNum = nMakeNum
        end
    end

    if tCraftInfo.nUseBuffID then
        local nStackNum = Buffer_GetStackNum(tCraftInfo.nUseBuffID)
        local nMakeNum = math.floor(nStackNum / tCraftInfo.nBuffStackCost)
        if not nMaxMakeNum or nMakeNum < nMaxMakeNum then
            nMaxMakeNum = nMakeNum
        end
    end
    return nMaxMakeNum
end

function CraftManageData.GetCraftInfos()
    return self.tCraftInfos
end

function CraftManageData.GetClassificationID()
    return self.nClassificationID
end

function CraftManageData.GetCraftLevel()
    return self.tCraftLevel
end

function CraftManageData.IsLocked(tCraftInfo)
    if tCraftInfo and not self.tCraftLevel[tCraftInfo.nCraftLevel] then
        return true
    end 
    return false
end

function CraftManageData.Produce(nID, nMakeNum)
    RemoteCallToServer("On_LangKeXing_Produce", nID, nMakeNum, self.nTargetType, self.nTargetID)
end

function CraftManageData.UnInit()
    
end

function CraftManageData.OnLogin()
    
end

function CraftManageData.OnFirstLoadEnd()
    
end
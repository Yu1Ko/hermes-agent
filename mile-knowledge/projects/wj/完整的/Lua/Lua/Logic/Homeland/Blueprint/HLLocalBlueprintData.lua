HLLocalBlueprintData = HLLocalBlueprintData or {}

local ITEM_PRE_PAGE = 6
local REMOTE_BLUEPRINT_PRO_DATA = 1142

function HLLocalBlueprintData.Init()
    HLLocalBlueprintData.nCurCatgIndex = 1
    HLLocalBlueprintData.nCurPage = 1
    HLLocalBlueprintData.nMaxPage = 1
    HLLocalBlueprintData.tCurItemList = {}
    HLLocalBlueprintData.tCatgInfo = {}
    HLLocalBlueprintData.tPopupCatg = {}
    HLLocalBlueprintData.szSearchKey = ""

    local bPrivate, nArea = HLBOp_Enter.GetArea()
    local tBlueprintCatgInfos = FurnitureData.GetBlueprintCatgInfo()
    for k, v in pairs(tBlueprintCatgInfos) do
        if v.nArea == nArea or (v.bPrivate == bPrivate and bPrivate) then
            HLLocalBlueprintData.nCurCatgIndex = k
            break
        end
    end

    HLLocalBlueprintData.InitCatgInfo()
    HLLocalBlueprintData.UpdateCurItemList()
end

function HLLocalBlueprintData.UnInit()
    HLLocalBlueprintData.nCurCatgIndex = 1
    HLLocalBlueprintData.nCurPage = 1
    HLLocalBlueprintData.nMaxPage = 1
    HLLocalBlueprintData.tCurItemList = {}
    HLLocalBlueprintData.tCatgInfo = {}
    HLLocalBlueprintData.tPopupCatg = {}
    HLLocalBlueprintData.szSearchKey = ""
end

function HLLocalBlueprintData.SetListInfo(tInfo)
    HLLocalBlueprintData.tCurItemList = tInfo
    HLLocalBlueprintData.nCurPage = 1
    HLLocalBlueprintData.nMaxPage = math.max(math.ceil(#tInfo / ITEM_PRE_PAGE), 1)
end

function HLLocalBlueprintData.UpdateCurItemList()
    local tBlueprintInfo = FurnitureData.GetBluepListByCatg(HLLocalBlueprintData.nCurCatgIndex)
    if not tBlueprintInfo then
        HLLocalBlueprintData.SetListInfo({})
        return
	end

    local fnCmp = function(tL, tR)
        local bLQuestCompleted = false
        local bRQuestCompleted = false
        if tL.nQuestID > 0 then
            bLQuestCompleted = QuestData.IsCompleted(tL.nQuestID)
        end

        if tR.nQuestID > 0 then
            bRQuestCompleted = QuestData.IsCompleted(tR.nQuestID)
        end

        if not tL.bTeach ~= not tR.bTeach then
            return tL.bTeach
        elseif not bLQuestCompleted ~= not bRQuestCompleted then
            return bLQuestCompleted
        elseif not tL.bNew ~= not tR.bNew then
            return tL.bNew
        elseif tL.nRequiredLevel ~= tR.nRequiredLevel then
            return tL.nRequiredLevel < tR.nRequiredLevel
        else
            return tL.nIndex < tR.nIndex
        end
    end
    table.sort(tBlueprintInfo, fnCmp)
    HLLocalBlueprintData.SetListInfo(tBlueprintInfo)
end

function HLLocalBlueprintData.InitCatgInfo()
    HLLocalBlueprintData.tCatgInfo = FurnitureData.GetBlueprintCatgInfo()
    local tTemp = {}
    local nCount = 1
    for _, tInfo in pairs(HLLocalBlueprintData.tCatgInfo) do
        tTemp[nCount] = tInfo
        nCount = nCount + 1
    end
    local function fnCmp(tA, tB)
        return tA.nIndex < tB.nIndex
    end
    table.sort(tTemp, fnCmp)
    HLLocalBlueprintData.tPopupCatg = tTemp
end

function HLLocalBlueprintData.UpdateSearchItemList()
    local tItemList = {}

    if HLLocalBlueprintData.szSearchKey == "" then
        HLLocalBlueprintData.UpdateCurItemList()
        return
    else
        for nIndex, tInfo in pairs(HLLocalBlueprintData.tCurItemList) do
            local szName = UIHelper.GBKToUTF8(tInfo.szName)
            if string.find(szName, HLLocalBlueprintData.szSearchKey, 1, true) then
                table.insert(tItemList, tInfo)
            end
        end
    end

    HLLocalBlueprintData.SetListInfo(tItemList)
end

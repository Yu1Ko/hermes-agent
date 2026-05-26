FurnitureData = FurnitureData or {}
local self = FurnitureData

local m_tFurnitureCatgInfos = nil
--[[
    {
        [nCatg1] = {[nCatg2] = {...}}
    }
]]

local m_tBlueprintCatgInfos = nil
--[[
    {
        [nCatg] = {...}
    }
]]
local m_tFurnitureInfosByTypeAndID = nil
--[[
    {
        [nType] = {[ID] = {...}}
    }
]]
local m_tFurnitureInfosByModelID = nil --表现ID
--[[
    {
        [nModelID] = {...}
    }
]]
local m_tFurnitureInfosByCatg = nil
--[[
    {
        [nCatg1] = {[nCatg2] = {...}
    }
]]
local m_tBlueprintInfos = nil
--[[
    {
        [nCatg] = {{...}}
    }
]]
local m_tBlueprintFileInfos = nil
--[[
    {
        [szPath] = {...}
    }
]]
local m_tFurnitureColorInfos = nil
--[[
    {
        [nModelID] = {...}
    }
]]
local m_tFurnitureAddInfos = nil
--[[
    {
        [nUiIndex] = {...}
    }
]]
local m_tPendantInfo = nil
--[[
    {
        [nCatg1] = {[nCatg2] = {...}}
    }
]]

local m_BlueprintTagInfo = nil
--[[
    {
        [nCatg] = {[1] = szName, [2] = szName ...}
    }
]]
local m_BlueprintCatgTagInfo = nil
--[[
    {
        [nCatg] = {..}
    }
]]

local tbLoadExtensionsScript = {
    "scripts/Map/家园系统客户端/Include/HomelandCommon.lua",
    "scripts/Map/家园系统客户端/Include/Home_BuildReplaceableModels.lua",
}

function FurnitureData.Init()
    for _, szPath in ipairs(tbLoadExtensionsScript) do
	    LoadScriptFile(UIHelper.UTF8ToGBK(szPath), FurnitureData)
    end
end

function FurnitureData.UnInit()
    Event.UnRegAll(self)

    m_tFurnitureCatgInfos = nil
    m_tBlueprintCatgInfos = nil
    m_tFurnitureInfosByTypeAndID = nil
    m_tFurnitureInfosByModelID = nil
    m_tFurnitureInfosByCatg = nil
    m_tBlueprintInfos = nil
    m_tBlueprintFileInfos = nil
    m_tFurnitureColorInfos = nil
    m_tFurnitureAddInfos = nil
    m_tPendantInfo = nil
    m_BlueprintTagInfo = nil
    m_BlueprintCatgTagInfo = nil
end

function FurnitureData.GetAllCatgInfos()
    if m_tFurnitureCatgInfos then
        return m_tFurnitureCatgInfos
    end
    m_tFurnitureCatgInfos = {}

    local function AddLine(tTable, nCatg1, nCatg2, tLine)
        if not tTable[nCatg1] then
            tTable[nCatg1] = {}
        end
        tTable[nCatg1][nCatg2] = tLine
    end

    local nCount = g_tTable.HomelandFurnitureCatg:GetRowCount()
    local nCatg1, nCatg2, tLine
    for i = 2, nCount do
        tLine = g_tTable.HomelandFurnitureCatg:GetRow(i)
        nCatg1, nCatg2 = tLine.nCatg1Index, tLine.nCatg2Index
        AddLine(m_tFurnitureCatgInfos, nCatg1, nCatg2, tLine)
    end

    return m_tFurnitureCatgInfos
end

function FurnitureData.GetBlueprintCatgInfo()
    if m_tBlueprintCatgInfos then
        return m_tBlueprintCatgInfos
    end
    m_tBlueprintCatgInfos = {}

    local function AddLine(tTable, nCatg, tLine)
        if not tTable[nCatg] then
            tTable[nCatg] = {}
        end
        tTable[nCatg] = tLine
    end

    local nCount = g_tTable.HomelandBlueprintCatg:GetRowCount()
    local nCat, tLine
    for i = 2, nCount do
        tLine = g_tTable.HomelandBlueprintCatg:GetRow(i)
        nCatg = tLine.nCatg
        AddLine(m_tBlueprintCatgInfos, nCatg, tLine)
    end

    return m_tBlueprintCatgInfos
end

function FurnitureData.GetAllFurnitureColorInfos()
    if m_tFurnitureColorInfos then
        return m_tFurnitureColorInfos
    end
    m_tFurnitureColorInfos = {}

    local nCount = g_tTable.HomelandFurnitureColor:GetRowCount()
    local tLine, nModelID
    for i = 2, nCount do
        tLine = g_tTable.HomelandFurnitureColor:GetRow(i)
        nModelID = tLine.dwModelID
        m_tFurnitureColorInfos[nModelID] = tLine
    end

    return m_tFurnitureColorInfos
end

function FurnitureData.GetAllFurniturnInfos()
    if m_tFurnitureInfosByTypeAndID then
        return m_tFurnitureInfosByTypeAndID, m_tFurnitureInfosByModelID, m_tFurnitureInfosByCatg
    end
    m_tFurnitureInfosByTypeAndID = {}
    m_tFurnitureInfosByModelID = {}
    m_tFurnitureInfosByCatg = {}

    local function AddCatgLine(tTable, nCatg1, nCatg2, tLine)
        if not tTable[nCatg1] then
            tTable[nCatg1] = {}
        end
        if not tTable[nCatg1][nCatg2] then
            tTable[nCatg1][nCatg2] = {}
        end
        table.insert(tTable[nCatg1][nCatg2], tLine)
    end

    local function AddModelLine(tTable, nModelID, tLine)
        tTable[nModelID] = tLine
    end

    local function AddTypeAndIDLine(tTable, nType, nID, tLine)
        if not tTable[nType] then
            tTable[nType] = {}
        end
        tTable[nType][nID] = tLine
    end

    local nCount = g_tTable.HomelandFurnitureInfo:GetRowCount()
    local tLine, nCatg1, nCatg2, nModelID, nType, nID
    for i = 2, nCount do
        tLine = g_tTable.HomelandFurnitureInfo:GetRow(i)
        local szXYZScale = tLine.szXYZScale
        local tTemp = string.split(szXYZScale, "|")
        if #tTemp > 2 then
            tLine.tXRange = Homeland_GetRange(tTemp[1])
            tLine.tYRange = Homeland_GetRange(tTemp[2])
            tLine.tZRange = Homeland_GetRange(tTemp[3])
        end
        nCatg1, nCatg2 = tLine.nCatg1Index, tLine.nCatg2Index
        AddCatgLine(m_tFurnitureInfosByCatg, nCatg1, nCatg2, tLine)
        nModelID = tLine.dwModelID
        AddModelLine(m_tFurnitureInfosByModelID, nModelID, tLine)
        nType, nID = tLine.nFurnitureType, tLine.dwFurnitureID
        AddTypeAndIDLine(m_tFurnitureInfosByTypeAndID, nType, nID, tLine)
    end

    return m_tFurnitureInfosByTypeAndID, m_tFurnitureInfosByModelID, m_tFurnitureInfosByCatg
end

function FurnitureData.GetAllBlueprintInfos()
    if m_tBlueprintInfos then
        return m_tBlueprintInfos, m_tBlueprintFileInfos
    end
    m_tBlueprintInfos = {}
    m_tBlueprintFileInfos = {}

    local function AddCatgLine(tTable, nCatg, tLine)
        if not tTable[nCatg] then
            tTable[nCatg] = {}
        end
        table.insert(tTable[nCatg], tLine)
    end

    local nCount = g_tTable.HomelandBlueprints:GetRowCount()
    local nCatg, tLine
    for i = 2, nCount do
        tLine = g_tTable.HomelandBlueprints:GetRow(i)
        nCatg = tLine.nCatg
        AddCatgLine(m_tBlueprintInfos, nCatg, tLine)
        m_tBlueprintFileInfos[tLine.szFilepath] = tLine
    end

    return m_tBlueprintInfos, m_tBlueprintFileInfos
end

function FurnitureData.GetAllFurnitureColorInfos()
    if m_tFurnitureColorInfos then
        return m_tFurnitureColorInfos
    end
    m_tFurnitureColorInfos = {}

    local nCount = g_tTable.HomelandFurnitureColor:GetRowCount()
    local tLine, nModelID
    for i = 2, nCount do
        tLine = g_tTable.HomelandFurnitureColor:GetRow(i)
        nModelID = tLine.dwModelID
        m_tFurnitureColorInfos[nModelID] = tLine
    end

    return m_tFurnitureColorInfos
end

function FurnitureData.GetAllFurnitureAddInfos()
    if m_tFurnitureAddInfos then
        return m_tFurnitureAddInfos
    end
    m_tFurnitureAddInfos = {}

    local nCount = g_tTable.FurnitureAddInfo:GetRowCount()
    local tLine, dwID
    for i = 2, nCount do
        tLine = g_tTable.FurnitureAddInfo:GetRow(i)
        dwID = tLine.dwID
        m_tFurnitureAddInfos[dwID] = tLine
    end

    return m_tFurnitureAddInfos
end

function FurnitureData.GetPendantInfo(nCatg1, nCatg2)
    if m_tPendantInfo and m_tPendantInfo[nCatg1] then
        return m_tPendantInfo[nCatg1][nCatg2]
    end

    m_tPendantInfo = {}
    local nCount = g_tTable.HomelandPendantInfo:GetRowCount()
    local tLine
    for i = 2, nCount do
        tLine = g_tTable.HomelandPendantInfo:GetRow(i)
        if not m_tPendantInfo[tLine.nCatg1Index] then
            m_tPendantInfo[tLine.nCatg1Index] = {}
        end
        m_tPendantInfo[tLine.nCatg1Index][tLine.nCatg2Index] = tLine
    end

    if m_tPendantInfo[nCatg1] then
        return m_tPendantInfo[nCatg1][nCatg2]
    end
end

function FurnitureData.GetAllBlueprintTagInfos()
    if m_BlueprintTagInfo then
        return m_BlueprintTagInfo
    end
    m_BlueprintTagInfo = {}

    local function AddCatgLine(tTable, nCatg, tLine)
        if not tTable[nCatg] then
            tTable[nCatg] = {}
        end
        table.insert(tTable[nCatg], tLine)
    end

    local nCount = g_tTable.Homeland_Tags:GetRowCount()
    local tLine, nCatg
    for i = 1, nCount do
        tLine = g_tTable.Homeland_Tags:GetRow(i)
        nCatg = tLine.nCatg
        AddCatgLine(m_BlueprintTagInfo, nCatg, tLine)
    end

    return m_BlueprintTagInfo
end

function FurnitureData.GetAllBlueprintTagCatgInfo(nCatg)
    if m_BlueprintCatgTagInfo then
        return m_BlueprintCatgTagInfo[nCatg]
    end
    m_BlueprintCatgTagInfo = {}

    local nCount = g_tTable.Homeland_TagsCatg:GetRowCount()
    local tLine, nCatgID
    for i = 1, nCount do
        tLine = g_tTable.Homeland_TagsCatg:GetRow(i)
        nCatgID = tLine.nCatgID
        m_BlueprintCatgTagInfo[nCatgID] = tLine
    end

    return m_BlueprintCatgTagInfo[nCatg]
end

function FurnitureData.GetCatg1Info(nCatg1Index)
    local tCatgInfos = self.GetAllCatgInfos()
    local tTable = tCatgInfos[nCatg1Index]
    assert(tTable, "Homeland_FurnitureCatg表未找到nCatg1Index为" .. nCatg1Index .. "的信息")
    local tLine = tTable[0]
    assert(tLine, "Homeland_FurnitureCatg表未找到nCatg1Index为" .. nCatg1Index .. "nCatg2Index为0的信息")
    return tLine
end

function FurnitureData.GetCatg2Info(nCatg1Index, nCatg2Index)
    local tCatgInfos = self.GetAllCatgInfos()
    local tTable = tCatgInfos[nCatg1Index]
    assert(tTable, "Homeland_FurnitureCatg表未找到nCatg1Index为" .. nCatg1Index .. "的信息")
    local tLine = tTable[nCatg2Index]
    assert(tLine, "Homeland_FurnitureCatg表未找到nCatg1Index为" .. nCatg1Index .. "nCatg2Index为" .. nCatg2Index .. "的信息")
    return tLine
end

function FurnitureData.GetPopupMenuCatgName()
	local t = g_tTable.HomelandFurnitureCatg
	local tTable = {}
	local nRowCount = t:GetRowCount()
	for i = 2, nRowCount do
		local tLine = t:GetRow(i)
		if not tTable[tLine.nCatg1Index] then
			tTable[tLine.nCatg1Index] = {}
		end
		table.insert(tTable[tLine.nCatg1Index], {tLine.nCatg2Index, tLine.szName})
	end
	return tTable
end

function FurnitureData.GetCatg1List()
    local tCatgInfos = self.GetAllCatgInfos()
    local tTable = {}
    for nCatg1Index, tLine in pairs(tCatgInfos) do
        tTable[nCatg1Index] = tLine[Homeland_GetNullCatg2Index()]
    end
    return tTable
end

function FurnitureData.GetCatg2List(nCatg1Index)
    local tCatgInfos = self.GetAllCatgInfos()
    local tTable = {}
    local tTemp = tCatgInfos[nCatg1Index]
    for nCatg2Index, tLine in pairs(tTemp) do
        if nCatg2Index ~= 0 then
            tTable[nCatg2Index] = tLine
        end
    end
    return tTable
end

function FurnitureData.GetFurnInfoByModelID(nModelID)
    local _, tFurnInfos, _ = self.GetAllFurniturnInfos()
    local tLine = tFurnInfos[nModelID]
    if not tLine then
        --JustLog("Homeland_FurnitureInfo表未找到nModelID为" .. nModelID .. "的信息")
        return nil
    end
    return tLine
end

function FurnitureData.GetInstFurnInfoByModelID(nModelID) --去除Log
    local _, tFurnInfos, _ = self.GetAllFurniturnInfos()
    local tLine = tFurnInfos[nModelID]
    return tLine
end

function FurnitureData.GetFurnTypeAndIDByModelID(nModelID)
    local _, tFurnInfos, _ = self.GetAllFurniturnInfos()
    local tLine = tFurnInfos[nModelID]
    if not tLine then
        --JustLog("Homeland_FurnitureInfo表未找到nModelID为" .. nModelID .. "的信息")
        return nil, nil
    end
    return tLine.nFurnitureType, tLine.dwFurnitureID
end

function FurnitureData.GetFurnInfoByTypeAndID(nType, nID)
    local tFurnInfos, _, _ = self.GetAllFurniturnInfos()
    local tTable = tFurnInfos[nType]
    assert(tTable, "Homeland_FurnitureInfo表未找到nType为" .. nType .. "的信息")
    local tLine = tTable[nID]
    assert(tLine, "Homeland_FurnitureInfo表未找到nType为" .. nType .. "nID为" .. nID .. "的信息")
    return tLine
end

function FurnitureData.GetModelIDByTypeAndID(nType, nID)
    local tInfo = self.GetFurnInfoByTypeAndID(nType, nID)
    return tInfo.dwModelID
end

function FurnitureData.GetFurnListByCatg(nCatg1, nCatg2)
    local _, _, tFurnInfos = self.GetAllFurniturnInfos()
    if not tFurnInfos[nCatg1] then
        return nil
    end
    return tFurnInfos[nCatg1][nCatg2]
end

function FurnitureData.GetFurnListByCatg1(nCatg1)
    local _, _, tFurnInfos = self.GetAllFurniturnInfos()
    return tFurnInfos[nCatg1]
end

function FurnitureData.GetFurnNameByTypeAndID(nType, nID)
    local tInfo = self.GetFurnInfoByTypeAndID(nType, nID)
    return tInfo.szName
end

function FurnitureData.GetFurnCatgByTypeAndID(nType, nID)
    local tLine = self.GetFurnInfoByTypeAndID(nType, nID)
    return tLine.nCatg1Index, tLine.nCatg2Index
end

function FurnitureData.FurnCanDye(nModelID)
    local tColorInfos = self.GetAllFurnitureColorInfos()
    if tColorInfos[nModelID] then
        return true
    end
    return false
end

function FurnitureData.GetFurnColorInfos(nModelID)
    local tColorInfos = self.GetAllFurnitureColorInfos()

    local tLine = tColorInfos[nModelID]
	local aColorInfos = {}
	local MAX_COLOR_COUNT = 8
	if tLine then
		local aColorIndices = tLine.szColorIndices:split(";", true)
		local nIndices = #aColorIndices
		if nIndices > MAX_COLOR_COUNT then
			nIndices = MAX_COLOR_COUNT
			LOG.ERROR("模型(id: " .. tostring(dwModelID) .. ")的偏色列表过长")
		end
		for i = 1, nIndices do
			local nColorIndex = tonumber(aColorIndices[i])
			local szDetailColor = tLine["szDetailIndex" .. (i-1)]
			if szDetailColor == "" then
				break
			else
				local aRGB = szDetailColor:split(";", true)
				table.insert(aColorInfos, {nColorIndex, tonumber(aRGB[1]) or 0, tonumber(aRGB[2]) or 0, tonumber(aRGB[3]) or 0})
			end
		end
	end

	return aColorInfos
end

function FurnitureData.GetFurnAddInfo(dwFurnitureUiId)
    local tAddInfos = self.GetAllFurnitureAddInfos()
    local tLine = tAddInfos[dwFurnitureUiId]
    if not tLine then
        LOG.ERROR("FurnitureAddInfo表未找到dwFurnitureUiId为" .. dwFurnitureUiId .. "的信息")
        return nil
    end
    return tLine
end

function FurnitureData.GetBluepListByCatg(nCatg)
    local tBlueprintInfos = self.GetAllBlueprintInfos()
    if not tBlueprintInfos[nCatg] then
        return nil
    end
    return tBlueprintInfos[nCatg]
end

function FurnitureData.IsBrushForAutoBottomBrush(dwModelID)
    local aModelIDsForBasement = FurnitureData.Homeland_GetModelIDsForBasement() -- from scripts\Map\家园系统客户端\Include\HomelandCommon.lua
	return CheckIsInTable(aModelIDsForBasement, dwModelID)
end

function FurnitureData.IsReplaceable(dwModelID)
    local tReplaceableModels = FurnitureData.Home_GetAllReplaceableModelsInfo() -- 来自 \scripts\Map\家园系统客户端\include\Home_BuildReplaceableModels.lua
	for _, aModels in pairs(tReplaceableModels) do
		local nPos = FindTableValue(aModels, dwModelID)
        if nPos then
            return true
        end
	end
    return false
end

function FurnitureData.GetReplaceableModelIDs(dwModelID)
	local t = FurnitureData.Home_GetAllReplaceableModelsInfo() -- 来自 \scripts\Map\家园系统客户端\include\Home_BuildReplaceableModels.lua
	local aRetModels
	for _, aModels in pairs(t) do
		local nPos = FindTableValue(aModels, dwModelID)
		if nPos then
			aRetModels = clone(aModels)
			table.remove(aRetModels, nPos)
			break
		end
	end
	if aRetModels and #aRetModels > 0 then
		return aRetModels
	else
		return nil
	end
end

function FurnitureData.IsDefaultSmartBrush(dwModelID)
    local tInfo = self.GetFurnInfoByModelID(dwModelID)
    local aDefaultSmartBrushCatgs = {}
    local aDefaultSmartBrushCatgs = FurnitureData.Homeland_GetDefaultSmartBrushCatgs() -- 来自 \scripts\Map\家园系统客户端\include\Home_BuildReplaceableModels.lua
    local nCatg1Index, nCatg2Index = tInfo.nCatg1Index, tInfo.nCatg2Index
    for _, t in ipairs(aDefaultSmartBrushCatgs) do
		if nCatg1Index == t[1] and nCatg2Index == t[2] then
			return true
		end
	end
    return false
end

function FurnitureData.IsAutoBottomBrush(dwModelID)
    local aModelIDsForBasement = FurnitureData.Homeland_GetModelIDsForBasement() -- from scripts\Map\家园系统客户端\Include\HomelandCommon.lua
    return CheckIsInTable(aModelIDsForBasement, dwModelID)
end

function FurnitureData.IsCatgForBaseboard(nCatg1Index, nCatg2Index)
    if nCatg1Index == Homeland_GetFunctionCatg1Index() and nCatg2Index == Homeland_GetBaseboardCatg2Index() then
        return true
    end
    return false
end

function FurnitureData.IsCatgForMechanism(nCatg1Index, nCatg2Index)
    if nCatg1Index == Homeland_GetFunctionCatg1Index() and nCatg2Index == Homeland_GetMechanismCatg2Index() then
        return true
    end
    return false
end

function FurnitureData.GetTypeAndIDWithItem(item, bItem)
    local pHlMgr = GetHomelandMgr()
    local nFurnitureType, dwFurnitureID
	local itemInfo

    if self.bItem then
        itemInfo = GetItemInfo(item.dwTabType, item.dwIndex)
        nFurnitureType = itemInfo.nFurnitureType or HS_FURNITURE_TYPE.FURNITURE or tFurnitureData.nType
        dwFurnitureID = item.dwFurnitureID or tFurnitureData.dwID
    else
        itemInfo = item
		nFurnitureType = itemInfo.nFurnitureType or HS_FURNITURE_TYPE.FURNITURE
		dwFurnitureID = itemInfo.dwFurnitureID
    end

    return nFurnitureType, dwFurnitureID
end


function FurnitureData.GetFurnitureConfig(nFurnitureType, dwFurnitureID)
    local pHlMgr = GetHomelandMgr()
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

    return tFurnitureConfig
end
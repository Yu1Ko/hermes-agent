-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: ResCleanData
-- Date: 2024-02-02 16:39:57
-- Desc: 资源清理
-- ---------------------------------------------------------------------------------

ResCleanData = ResCleanData or {className = "ResCleanData"}
local self = ResCleanData

local m_nDynCleanTimeStamp = nil
local m_nMapCleanTimeStamp = nil

local tCleanTime = {
    [GameSettingType.DynamicResources.OneMonth.szDec] = 30 * (24 * 60 * 60),
    [GameSettingType.DynamicResources.ThreeMonth.szDec] = 90 * (24 * 60 * 60),
    [GameSettingType.MapResources.TwoWeek.szDec] = 14 * (24 * 60 * 60),
    [GameSettingType.MapResources.OneMonth.szDec] = 30 * (24 * 60 * 60),
}

function ResCleanData.Init()
    self.RegEvent()

    self.UpdateDynTimeStamp()
    self.UpdateMapTimeStamp()

    if GameSettingData.GetNewValue(UISettingKey.AutoCleanDynamicResource) then
        self.CleanDynDLC()
    end
    if GameSettingData.GetNewValue(UISettingKey.AutoCleanMapResource) then
        self.CleanMapDLC()
    end
end

function ResCleanData.UnInit()
    Event.UnRegAll(self)
    Timer.DelAllTimer(self)
end

function ResCleanData.RegEvent()
    Event.Reg(self, EventType.OnCleanResourcesUpdate, function()
        ResCleanData.UpdateDynTimeStamp()
        ResCleanData.UpdateMapTimeStamp()
    end)
    Event.Reg(self, "SCENE_BEGIN_LOAD", function(nMapID)
        self.RecordLoadCurrentMap(nMapID)
    end)
    Event.Reg(self, EventType.OnClientPlayerLeave, function()
        self.RecordLoadCurrentMap()
	end)
    Event.Reg(self, EventType.PakDownload_OnComplete, function(nPackID, nResult)
        if nResult ~= DOWNLOAD_OBJECT_RESULT.SUCCESS then
            return
        end

        --下载完成时记录一次已加载
        if PakDownloadMgr.IsMapRes(nPackID) then
            LOG.INFO("[PakDownloadMgr] RecordLoadDLC, %s", tostring(nPackID))
            local bResult = PakDownload_RecordLoadDLC(nPackID)
        elseif PakDownloadMgr.IsEquipRes(nPackID) then
            LOG.INFO("[PakDownloadMgr] RecordLoadDLC, %s", tostring(nPackID))
            local bResult = PakDownload_RecordLoadDLC(nPackID)
        elseif PakDownloadMgr.IsDynamicPack(nPackID) then
            local tPakInfo = PakDownloadMgr.GetPackInfo(nPackID)
            if tPakInfo and tPakInfo.bEquipRes then
                local nRoleType, tLackEquipList, tLackEquipApexList, tLackEquipSfxList = tPakInfo.nRoleType, tPakInfo.tLackEquipList, tPakInfo.tLackEquipApexList, tPakInfo.tLackEquipSfxList
                ResCleanData.RecordLoadEquipRes(nRoleType, tLackEquipList, tLackEquipApexList, tLackEquipSfxList)
            end
        end
    end)
end

function ResCleanData.UpdateDynTimeStamp()
    local nCurTimeStamp = Timer.GetTime() --os.time()
    local tDynamicOption = GameSettingData.GetNewValue(UISettingKey.CleanEquipResourceInterval)
    if not tDynamicOption then
        return
    end

    m_nDynCleanTimeStamp = tCleanTime[tDynamicOption.szDec] and nCurTimeStamp - tCleanTime[tDynamicOption.szDec]
    LOG.INFO("[PakDownloadMgr] UpdateDynTimeStamp(%s): %s", tostring(tDynamicOption.szDec), tostring(m_nDynCleanTimeStamp))
end

function ResCleanData.UpdateMapTimeStamp()
    local nCurTimeStamp = Timer.GetTime() --os.time()
    local tMapOption = GameSettingData.GetNewValue(UISettingKey.CleanMapResourceInterval)
    if not tMapOption then
        return
    end

    m_nMapCleanTimeStamp = tCleanTime[tMapOption.szDec] and nCurTimeStamp - tCleanTime[tMapOption.szDec]
    LOG.INFO("[PakDownloadMgr] UpdateMapTimeStamp(%s): %s", tostring(tMapOption.szDec), tostring(m_nMapCleanTimeStamp))
end

function ResCleanData.GetExpiredDynDLCSize()
    local dwSize = 0
    if m_nDynCleanTimeStamp then
        dwSize = PakDownload_GetExpiredDynDLCSize(m_nDynCleanTimeStamp)
        LOG.INFO("[PakDownloadMgr] GetExpiredDynDLCSize(%s): %s", tostring(m_nDynCleanTimeStamp), tostring(dwSize))
    end
    return dwSize
end

function ResCleanData.GetExpiredMapDLCSize()
    local dwSize = 0
    if m_nMapCleanTimeStamp then
        dwSize = PakDownload_GetExpiredDLCSize(m_nMapCleanTimeStamp)
        LOG.INFO("[PakDownloadMgr] GetExpiredDLCSize(%s): %s", tostring(m_nMapCleanTimeStamp), tostring(dwSize))
    end
    return dwSize
end

function ResCleanData.CleanDynDLC()
    if not PakDownloadMgr.IsEnabled() then return end
    if PakDownload_HasMultiInstance() then return end
    if not m_nDynCleanTimeStamp then return end

    LOG.INFO("[PakDownloadMgr] LockModify")
    local bRet = PakDownload_LockModify()
    if not bRet then
        LOG.INFO("[PakDownloadMgr] LockModify Failed")
        return
    end

    local tPackIDList = self.GetExistPackIDList()

    LOG.INFO("[PakDownloadMgr] DelExpiredDynDLC, %s", tostring(m_nDynCleanTimeStamp))
    PakDownload_DelExpiredDynDLC(m_nDynCleanTimeStamp)

    self.ClearNotExistPack(tPackIDList)
    Event.Dispatch(EventType.PakDownload_OnResClean)

    LOG.INFO("[PakDownloadMgr] UnlockModify")
    PakDownload_UnlockModify()
end

function ResCleanData.CleanMapDLC()
    if not PakDownloadMgr.IsEnabled() then return end
    if PakDownload_HasMultiInstance() then return end
    if not m_nMapCleanTimeStamp then return end

    LOG.INFO("[PakDownloadMgr] LockModify")
    local bRet = PakDownload_LockModify()
    if not bRet then
        LOG.INFO("[PakDownloadMgr] LockModify Failed")
        return
    end

    local tPackIDList = self.GetExistPackIDList()

    LOG.INFO("[PakDownloadMgr] DelExpiredDLC, %s", tostring(m_nMapCleanTimeStamp))
    PakDownload_DelExpiredDLC(m_nMapCleanTimeStamp)

    self.ClearNotExistPack(tPackIDList)
    Event.Dispatch(EventType.PakDownload_OnResClean)

    LOG.INFO("[PakDownloadMgr] UnlockModify")
    PakDownload_UnlockModify()
end

function ResCleanData.RecordLoadCurrentMap(nMapID)
    if not PakDownloadMgr.IsEnabled() then
        return
    end

    nMapID = nMapID or MapHelper.GetMapID()
    if not nMapID or nMapID <= 0 then
        return
    end

    local nPackID = PakDownloadMgr.GetMapResPackID(nMapID)
    if PakDownloadMgr.GetPackInfo(nPackID) then
        LOG.INFO("[PakDownloadMgr] RecordLoadDLC, %s", tostring(nPackID))
        local bResult = PakDownload_RecordLoadDLC(nPackID)
    end
end

function ResCleanData.RecordLoadEquipRes(nRoleType, tEquipList, tEquipApexList, tEquipSfxList)
    if not PakDownloadMgr.IsEnabled() then
        return
    end

    for _, tEquip in ipairs(tEquipList) do
        local nState = PakDownload_IsExistEquipResource(nRoleType, tEquip)
        if nState == RESOURCE_EXIST_STATE.LOCAL_EXIST then
            local bResult = PakDownload_RecordLoadDynamicDLC(nRoleType, tEquip, nil, nil)
            LOG.INFO("[PakDownloadMgr] RecordLoadEquipRes, %d %d", tEquip.nFileType, tEquip.dwRepresentID)
        end
    end

    if QualityMgr.CanEnableClothSimulation() and GameSettingData.GetNewValue(UISettingKey.ClothSimulation) then
        for _, tEquipApex in ipairs(tEquipApexList) do
            local nState = PakDownload_IsExistEquipApexResource(nRoleType, tEquipApex)
            if nState == RESOURCE_EXIST_STATE.LOCAL_EXIST then
                local bResult = PakDownload_RecordLoadDynamicDLC(nRoleType, nil, tEquipApex, nil)
                LOG.INFO("[PakDownloadMgr] RecordLoadEquipApexRes, %d %d", tEquipApex.nFileType, tEquipApex.dwRepresentID)
            end
        end
    end

    for _, tEquipSfx in ipairs(tEquipSfxList) do
        local nState = PakDownload_IsExistEquipSfxResource(nRoleType, tEquipSfx)
        if nState == RESOURCE_EXIST_STATE.LOCAL_EXIST then
            local bResult = PakDownload_RecordLoadDynamicDLC(nRoleType, nil, nil, tEquipSfx)
            LOG.INFO("[PakDownloadMgr] RecordLoadEquipSfxRes, %d %d %d", tEquipSfx.nFileType, tEquipSfx.dwRepresentID, tEquipSfx.dwEnchantID)
        end
    end
end

--清理前获取下载任务中已经开始下载的资源
function ResCleanData.GetExistPackIDList()
    local tPackIDList = {}
    local tPackIDMap = {} --用于去重，避免table.contain_value耗性能太大
    for _, tTaskList in pairs(Storage.Download.tbTaskTable) do
        for nIndex, tTask in ipairs(tTaskList) do
            local nPackID = tTask.nPackID
            local nState, dwTotalSize, dwDownloadedSize = PakDownloadMgr.GetPackState(nPackID)
            if nState ~= DOWNLOAD_OBJECT_STATE.NOTEXIST or dwDownloadedSize > 0 and not tPackIDMap[nPackID] then
                table.insert(tPackIDList, nPackID)
                tPackIDMap[nPackID] = true
            end
        end
    end
    return tPackIDList
end

--清理后将下载任务中被清理掉的资源移除
function ResCleanData.ClearNotExistPack(tPackIDList)
    for _, nPackID in ipairs(tPackIDList) do
        local nState, dwTotalSize, dwDownloadedSize = PakDownloadMgr.GetPackState(nPackID)
        if nState == DOWNLOAD_OBJECT_STATE.NOTEXIST and dwDownloadedSize <= 0 then
            PakDownloadMgr.CancelPack(nPackID)
        end
    end
end

function ResCleanData.GM_SetCleanTime(nTimeDyn1M, nTimeDyn3M, nTimeMap2W, nTimeMap1M)
    if nTimeDyn1M then tCleanTime[GameSettingType.DynamicResources.OneMonth.szDec] = nTimeDyn1M end
    if nTimeDyn3M then tCleanTime[GameSettingType.DynamicResources.ThreeMonth.szDec] = nTimeDyn3M end
    if nTimeMap2W then tCleanTime[GameSettingType.MapResources.TwoWeek.szDec] = nTimeMap2W end
    if nTimeMap1M then tCleanTime[GameSettingType.MapResources.OneMonth.szDec] = nTimeMap1M end
end
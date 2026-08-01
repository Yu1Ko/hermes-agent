-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: RecommendPakMutexMgr
-- Date: 2024-03-27 20:17:19
-- Desc: 推荐下载互斥管理器
-- ---------------------------------------------------------------------------------

RecommendPakMutexMgr = RecommendPakMutexMgr or {className = "RecommendPakMutexMgr"}
local self = RecommendPakMutexMgr

function RecommendPakMutexMgr.Init()
    self.RegEvent()

    Storage.Download.tbMutexIDTable = Storage.Download.tbMutexIDTable or {}
    self.InitMutexGroup()
    self.UpdateMutexState()
end

function RecommendPakMutexMgr.UnInit()
    Event.UnRegAll(self)
    Timer.DelAllTimer(self)
end

function RecommendPakMutexMgr.RegEvent()
    Event.Reg(self, EventType.PakDownload_OnStateUpdate, function(nPackID)
        self.UpdateMutexState(nPackID)
    end)
end

function RecommendPakMutexMgr.InitMutexGroup()
    self.tPackIDListMap = {}
    self.tMutexGroup = {}

    local tPackTree = PakDownloadMgr.GetPackTree()
    for _, tInfo in ipairs(tPackTree or {}) do
        if tInfo.nType == 3 then --nType=3表示推荐资源
            local tChildList = PakDownloadMgr.GetChildIDListInPackTree(tInfo.nID)
            for _, nChildID in ipairs(tChildList) do
                local tPackIDList = PakDownloadMgr.GetPackIDListInPackTree(nChildID)
                self.tPackIDListMap[nChildID] = tPackIDList
            end
        end
    end

    for nPackTreeID, tPackIDList in pairs(self.tPackIDListMap) do
        local tGroup = {}
        for nOtherPackTreeID, tOtherPackIDList in pairs(self.tPackIDListMap) do
            if nPackTreeID ~= nOtherPackTreeID then
                for _, nPackID in ipairs(tPackIDList) do
                    if table.contain_value(tOtherPackIDList, nPackID) then
                        table.insert(tGroup, nOtherPackTreeID)
                        break
                    end
                end
            end
        end
        self.tMutexGroup[nPackTreeID] = tGroup
    end

    --print_table(self.tMutexGroup)
end

function RecommendPakMutexMgr.GetPackIDListInPackTree(nPackTreeID)
    return self.tPackIDListMap and self.tPackIDListMap[nPackTreeID] or PakDownloadMgr.GetPackIDListInPackTree(nPackTreeID)
end

function RecommendPakMutexMgr.UpdateMutexState(nUpdatedPackID)
    local tEndMutexIDList = {}

    for nMutexPackTreeID, _ in pairs(Storage.Download.tbMutexIDTable) do
        local tPackIDList = self.GetPackIDListInPackTree(nMutexPackTreeID)
        if not nUpdatedPackID or table.contain_value(tPackIDList, nUpdatedPackID) then
            local tStateInfo = PakDownloadMgr.GetStateInfoByPackIDList(tPackIDList)
            local tGroup = self.tMutexGroup[nMutexPackTreeID]

            if tStateInfo.nState == DOWNLOAD_STATE.COMPLETE or tStateInfo.nState == DOWNLOAD_STATE.NONE then
                --清理已下载完成的nPackTreeID
                table.insert(tEndMutexIDList, nMutexPackTreeID)
            elseif tGroup then
                --清理已为互斥的nPackTreeID（如PackTree.tab内容有更新）
                for nOtherMutexPackTreeID, _ in pairs(Storage.Download.tbMutexIDTable) do
                    if nMutexPackTreeID ~= nOtherMutexPackTreeID and table.contain_value(tGroup, nOtherMutexPackTreeID) then
                        table.insert(tEndMutexIDList, nMutexPackTreeID)
                    end
                end
            end
        end
    end

    for _, nMutexPackTreeID in ipairs(tEndMutexIDList) do
        Storage.Download.tbMutexIDTable[nMutexPackTreeID] = nil
    end
    if #tEndMutexIDList > 0 then
        Storage.Download.Flush()
    end
end

function RecommendPakMutexMgr.StartMutexDownload(nPackTreeID, fnCallback)
    if not nPackTreeID or Storage.Download.tbMutexIDTable[nPackTreeID] then
        if fnCallback then
            fnCallback()
        end
        return
    end

    --将其它互斥的nPackTreeID暂停
    local tEndMutexIDList = {}
    local tPausePackIDList = {}
    for nMutexPackTreeID, _ in pairs(Storage.Download.tbMutexIDTable) do
        local tGroup = self.tMutexGroup[nMutexPackTreeID]
        if tGroup and table.contain_value(tGroup, nPackTreeID) then
            table.insert(tEndMutexIDList, nMutexPackTreeID)
            local tPackIDList = self.GetPackIDListInPackTree(nMutexPackTreeID)
            for _, nPackID in ipairs(tPackIDList) do
                if not table.contain_value(tPausePackIDList, nPackID) then
                    table.insert(tPausePackIDList, nPackID)
                end
            end
        end
    end

    for _, nMutexPackTreeID in ipairs(tEndMutexIDList) do
        Storage.Download.tbMutexIDTable[nMutexPackTreeID] = nil
    end
    Storage.Download.tbMutexIDTable[nPackTreeID] = true
    Storage.Download.Flush()
    PakDownloadMgr.PausePackInPackIDList(tPausePackIDList, fnCallback)
end

function RecommendPakMutexMgr.CheckShowMutex(nPackTreeID)
    if not nPackTreeID or Storage.Download.tbMutexIDTable[nPackTreeID] then
        return
    end

    --判断当前有无其它互斥
    for nMutexPackTreeID, _ in pairs(Storage.Download.tbMutexIDTable) do
        local tGroup = self.tMutexGroup[nMutexPackTreeID]
        if tGroup and table.contain_value(tGroup, nPackTreeID) then
            return
        end
    end

    --判断当前nPackTreeID中是否所有资源都开始下载了
    local bAllStart = true
    local tPackIDList = self.GetPackIDListInPackTree(nPackTreeID)
    for _, nPackID in pairs(tPackIDList) do
        local nState, dwTotalSize, dwDownloadedSize = PakDownloadMgr.GetPackState(nPackID)
        if nState == DOWNLOAD_OBJECT_STATE.NOTEXIST or nState == DOWNLOAD_OBJECT_STATE.PAUSE then
            local tDownloadInfo = PakDownloadMgr.GetDownloadingInfo(nPackID)
            if not tDownloadInfo or tDownloadInfo.nState == DOWNLOAD_STATE.NONE or tDownloadInfo.nState == DOWNLOAD_STATE.PAUSE then
                return
            end
        end
    end

    Storage.Download.tbMutexIDTable[nPackTreeID] = true
    Storage.Download.Flush()
end

function RecommendPakMutexMgr.IsMutex(nPackTreeID)
    if not nPackTreeID then
        return false
    end

    --不在tbMutexIDTable表里的不能显示
    return not Storage.Download.tbMutexIDTable[nPackTreeID]
end
-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: PakSizeQueryMgr
-- Date: 2024-05-15 12:24:11
-- Desc: 资源大小查询管理器
-- ---------------------------------------------------------------------------------

PakSizeQueryMgr = PakSizeQueryMgr or {className = "PakSizeQueryMgr"}
local self = PakSizeQueryMgr

local m_bEnabled = true

QUERY_TYPE = {
    REAL_SIZE = 1,
    DELETE_SIZE = 2,
}

function PakSizeQueryMgr.Init()
    self.RegEvent()

    self.tQueryInfo = {}
end

function PakSizeQueryMgr.UnInit()
    Event.UnRegAll(self)
    Timer.DelAllTimer(self)
end

function PakSizeQueryMgr.RegEvent()
    Event.Reg(self, EventType.PakDownload_OnGetMultiDlcRealSize, function(nEntryID, bSuccess, dwTotalSize, dwDownloadedSize)
        if PakDownloadMgr.IsDebug() then
            LOG.INFO("[PakDownloadMgr] PakDownload_OnGetMultiDlcRealSize, %s, %s, %s, %s", tostring(nEntryID), tostring(bSuccess), tostring(dwTotalSize), tostring(dwDownloadedSize))
        end
        self._OnGetMultiDlcSize(nEntryID, bSuccess, dwTotalSize, dwDownloadedSize)
    end)
    Event.Reg(self, EventType.PakDownload_OnGetMultiDlcDeleteSize, function(nEntryID, bSuccess, dwDeleteSize)
        if PakDownloadMgr.IsDebug() then
            LOG.INFO("[PakDownloadMgr] PakDownload_OnGetMultiDlcDeleteSize, %s, %s, %s", tostring(nEntryID), tostring(bSuccess), tostring(dwDeleteSize))
        end
        self._OnGetMultiDlcSize(nEntryID, bSuccess, dwDeleteSize)
    end)
end

---@param tPackIDList number|table nPackID/tPackIDList
---@param fnCallback function fnCallback(bSuccess, dwTotalSize, dwDownloadedSize)|fnCallback(bSuccess, deDeleteSize)
---@param nType number|nil QUERY_TYPE，默认为QUERY_TYPE.REAL_SIZE
---@return number|nil nEntryID
function PakSizeQueryMgr.QuerySize(tPackIDList, fnCallback, nType)
    if not tPackIDList or not fnCallback then return end

    tPackIDList = IsTable(tPackIDList) and tPackIDList or {tPackIDList}
    nType = nType or QUERY_TYPE.REAL_SIZE

    --禁用时，直接用老接口返回
    if not m_bEnabled then
        local tStateInfo = PakDownloadMgr.GetStateInfoByPackIDList(tPackIDList)
        if nType == QUERY_TYPE.REAL_SIZE then
            fnCallback(true, tStateInfo.dwTotalSize, tStateInfo.dwDownloadedSize)
        elseif nType == QUERY_TYPE.DELETE_SIZE then
            fnCallback(true, tStateInfo.dwDownloadedSize)
        end
        return
    end

    local tIDList = {}
    local tPackIDMap = {} --用于去重，避免table.contain_value耗性能太大
    local szPackIDList
    for _, nPackID in ipairs(tPackIDList) do
        if not tPackIDMap[nPackID] then
            table.insert(tIDList, nPackID)
            tPackIDMap[nPackID] = true
            szPackIDList = szPackIDList and (szPackIDList .. "/" .. tostring(nPackID)) or tostring(nPackID)
        end
    end

    --若当前有同样的tPackIDList在查询，则仅添加到回调列表，避免重复查询
    for _, tInfo in pairs(self.tQueryInfo) do
        if tInfo.szPackIDList == szPackIDList and tInfo.nType == nType then
            table.insert(tInfo.tCallbackList, fnCallback)
            return
        end
    end

    local nEntryID
    if nType == QUERY_TYPE.REAL_SIZE then
        nEntryID = PakDownload_GetMultiDlcRealSize(tIDList)
        if PakDownloadMgr.IsDebug() then
            LOG.INFO("[PakDownloadMgr] GetMultiDlcRealSize, %s, %s", tostring(nEntryID), tostring(szPackIDList))
        end
    elseif nType == QUERY_TYPE.DELETE_SIZE then
        nEntryID = PakDownload_GetMultiDlcDeleteSize(tIDList)
        if PakDownloadMgr.IsDebug() then
            LOG.INFO("[PakDownloadMgr] GetMultiDlcDeleteSize, %s, %s", tostring(nEntryID), tostring(szPackIDList))
        end
    end
    if not nEntryID then return end

    self.tQueryInfo[nEntryID] = {
        tCallbackList = {fnCallback},
        --tPackIDList = tIDList,
        szPackIDList = szPackIDList,
        nType = nType,
    }

    return nEntryID
end

---@param nEntryID number
---@return boolean|nil bResult
function PakSizeQueryMgr.CancelQuery(nEntryID)
    if not m_bEnabled then return end
    if not nEntryID or not self.tQueryInfo[nEntryID] then return end

    if PakDownloadMgr.IsDebug() then
        LOG.INFO("[PakDownloadMgr] CancelGetMultiDlcSize, %s", tostring(nEntryID))
    end
    PakDownload_CancelGetMultiDlcSize(nEntryID)
    self.tQueryInfo[nEntryID] = nil

    return true
end

---@param script table
---@param tPackIDList number|table nPackID/tPackIDList
---@param fnCallback function fnCallback(bSuccess, dwTotalSize, dwDownloadedSize)|fnCallback(bSuccess, deDeleteSize)
---@param bWaitingTips boolean 显示“正在计算资源大小...”等待提示tips
---@param nType number|nil QUERY_TYPE，默认为QUERY_TYPE.REAL_SIZE
---@return number|nil nEntryID
function PakSizeQueryMgr.RegQuerySize(script, tPackIDList, fnCallback, bWaitingTips, nType)
    if not script or not tPackIDList or not fnCallback then return end

    if bWaitingTips then
        --若正在计算大小，则直接返回
        if WaitingTipsData.GetMsgByType("QuerySize") then
            return
        end

        local tMsg = {
            szType = "QuerySize",
            szWaitingMsg = "正在计算资源大小...",
            bSwallow = true,
        }
        WaitingTipsData.PushWaitingTips(tMsg)

        local fnTempCallback = fnCallback
        fnCallback = function(...)
            WaitingTipsData.RemoveWaitingTips("QuerySize")
            if fnTempCallback then
                fnTempCallback(...)
            end
        end
    end

    local nEntryID = self.QuerySize(tPackIDList, fnCallback, nType)
    if not nEntryID then
        if bWaitingTips then
            WaitingTipsData.RemoveWaitingTips("QuerySize")
        end
        return
    end

    local tInfo = self.tQueryInfo[nEntryID]
    if tInfo then
        tInfo.script = script
    end

    script._tbQuerySize = script._tbQuerySize or {}
    script._tbQuerySize[nEntryID] = true

    return nEntryID
end

---@param script table
---@param nEntryID number nEntryID
---@return boolean|nil bResult
function PakSizeQueryMgr.UnRegQuerySize(script, nEntryID)
    if not script or not nEntryID then return end
    if not script._tbQuerySize then return end

    local bResult = false
    if script._tbQuerySize[nEntryID] then
        bResult = self.CancelQuery(nEntryID)
        script._tbQuerySize[nEntryID] = nil
        WaitingTipsData.RemoveWaitingTips("QuerySize")
    end
    return bResult
end

---@param script table
---@return boolean|nil bResult
function PakSizeQueryMgr.UnRegAllQuerySize(script)
    if not script then return end

    local bResult = false
    if script._tbQuerySize then
        for nEntryID, _ in pairs(script._tbQuerySize) do
            if self.CancelQuery(nEntryID) then
                bResult = true
            end
        end
        script._tbQuerySize = nil
    end
    return bResult
end

---@param script table
---@param fnDownload function fnDownload()
---@param tPackIDList number|table nPackID/tPackIDList
---@param szContent string 确认弹窗文本
---@return number|nil nEntryID
function PakSizeQueryMgr.RegQuerySizeCheckNetDownload(script, fnDownload, tPackIDList, szContent)
    tPackIDList = IsTable(tPackIDList) and tPackIDList or {tPackIDList}

    local nNetMode = App_GetNetMode()
    if nNetMode == NET_MODE.WIFI or #tPackIDList <= 0 then
        if fnDownload then
            fnDownload()
        end
        return
    end

    if #tPackIDList == 1 then
        local nPackID = tPackIDList[1]
        local nState, dwTotalSize, dwDownloadedSize = PakDownloadMgr.GetPackState(nPackID)
        local dwLeftDownloadSize = dwTotalSize - dwDownloadedSize
        PakDownloadMgr.CheckNetDownload(fnDownload, dwLeftDownloadSize, szContent)
        return
    end

    local nEntryID = self.RegQuerySize(script, tPackIDList, function(bSuccess, dwTotalSize, dwDownloadedSize)
        if bSuccess then
            local dwLeftDownloadSize = dwTotalSize - dwDownloadedSize
            PakDownloadMgr.CheckNetDownload(fnDownload, dwLeftDownloadSize, szContent)
        end
    end, true)
    return nEntryID
end

function PakSizeQueryMgr._OnGetMultiDlcSize(nEntryID, bSuccess, ...)
    local tInfo = self.tQueryInfo[nEntryID]
    if tInfo then
        if tInfo.tCallbackList then
            local tArgs = {...}
            if tInfo.nType == QUERY_TYPE.REAL_SIZE then
                local dwTotalSize, dwDownloadedSize = tArgs[1], tArgs[2]
                for _, fnCallback in ipairs(tInfo.tCallbackList) do
                    fnCallback(bSuccess, dwTotalSize, dwDownloadedSize)
                end
            elseif tInfo.nType == QUERY_TYPE.DELETE_SIZE then
                local dwDeleteSize = tArgs[1]
                for _, fnCallback in ipairs(tInfo.tCallbackList) do
                    fnCallback(bSuccess, dwDeleteSize)
                end
            end
        end
        if tInfo.script and tInfo.script._tbQuerySize then
            tInfo.script._tbQuerySize[nEntryID] = nil
        end
    end
    self.tQueryInfo[nEntryID] = nil
end

function PakSizeQueryMgr.SetEnabled(bEnabled)
    m_bEnabled = bEnabled
end
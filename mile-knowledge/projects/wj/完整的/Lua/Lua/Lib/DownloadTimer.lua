DownloadTimer = DownloadTimer or {}

-- =============================================================================
-- 下载专用的定时器，会在后台更新
-- =============================================================================

local tTimerList = {}
local nAllocatedEntryID = 0
local nLastTime = GetTickCount()

local function OnUpdate(nDeltaTime)
    local nCount = #tTimerList
    for i = 1, nCount do
        local tInfo = tTimerList[i]
        if not tInfo.bRemoved then
            tInfo.nLeftTime = tInfo.nLeftTime - nDeltaTime
            if tInfo.nLeftTime <= 0 then
                if tInfo.fnCallback then
                    tInfo.fnCallback()
                end
                tInfo.nLeftTime = tInfo.nLeftTime + tInfo.nInterval
            end
        end
    end

    for i = #tTimerList, 1, -1 do
        local tInfo = tTimerList[i]
        if tInfo.bRemoved then
            table.remove(tTimerList, i)
        end
    end
end

local function RegFunc(fnCallback, nInterval)
    nAllocatedEntryID = nAllocatedEntryID + 1
    local tInfo = {
        nEntryID = nAllocatedEntryID,
        fnCallback = fnCallback,
        nInterval = nInterval,
        nLeftTime = nInterval,
        bRemoved = false,
    }
    table.insert(tTimerList, tInfo)
    return nAllocatedEntryID
end

local function UnRegFunc(nEntryID)
    for _, tInfo in ipairs(tTimerList) do
        if tInfo.nEntryID == nEntryID then
            tInfo.bRemoved = true
        end
    end
end

---comment 下载模块有自己独立的Tick入口，以支持Android平台上后台更新逻辑（由C++调用）
function DownloadTimer.Tick()
    local nCurTime = GetTickCount()
    local nDeltaTime = (nCurTime - nLastTime) / 1000
    OnUpdate(nDeltaTime)
    nLastTime = nCurTime
end

-- function DownloadTimer._debugPrint()
--     print_table("[DownloadTimer]", tTimerList)
-- end

function DownloadTimer.Add(script, nTime, func)
    if not script or not nTime or not func then return end

    if nTime <= 0 then
        LOG.ERROR(string.format("BackgroundTimer.Add, error nTime = %s", tostring(nTime)))
        return
    end

    local nEntryID = nil
    nEntryID = RegFunc(function(nTotalTime)
        xpcall(func, function(err) LOG.ERROR("BackgroundTimer.Add, error nEntryID = %s.\nError = %s", tostring(nEntryID), err) end)
        DownloadTimer.DelTimer(script, nEntryID)
    end, nTime, false)

    script._tbDownloadTimer = script._tbDownloadTimer or {}
    script._tbDownloadTimer[nEntryID] = func

    return nEntryID
end

function DownloadTimer.AddCycle(script, nCycleTime, func)
    if not script or not nCycleTime or not func then return end

    if nCycleTime <= 0 then
        LOG.ERROR(string.format("BackgroundTimer.AddCycle, error nCycleTime = %s", tostring(nCycleTime)))
        return
    end

    local nEntryID = nil
    nEntryID = RegFunc(function(nTotalTime)
        xpcall(func, function(err) LOG.ERROR("BackgroundTimer.AddCycle, error nEntryID = %s.\nError = %s", tostring(nEntryID), err) end)
    end, nCycleTime, false)

    script._tbDownloadTimer = script._tbDownloadTimer or {}
    script._tbDownloadTimer[nEntryID] = func

    return nEntryID
end

function DownloadTimer.AddFrame(script, nFrame, func)
    if not script or not nFrame or not func then return end

    if nFrame <= 0 then
        LOG.ERROR(string.format("BackgroundTimer.AddFrame, error nFrame = %s", tostring(nFrame)))
        return
    end

    nFrame = math.floor(nFrame)

    local nEntryID = nil
    nEntryID = RegFunc(function(nFrameTime)
        nFrame = nFrame - 1
        if nFrame <= 0 then
            xpcall(func, function(err) LOG.ERROR("BackgroundTimer.AddFrame, error nEntryID = %s.\nError = %s", tostring(nEntryID), err) end)
            DownloadTimer.DelTimer(script, nEntryID)
        end
    end, 0, false)

    script._tbDownloadTimer = script._tbDownloadTimer or {}
    script._tbDownloadTimer[nEntryID] = func

    return nEntryID
end

function DownloadTimer.AddFrameCycle(script, nCycleFrame, func)
    if not script or not nCycleFrame or not func then return end

    if nCycleFrame <= 0 then
        LOG.ERROR(string.format("BackgroundTimer.AddFrameCycle, error nCycleFrame = %s", tostring(nCycleFrame)))
        return
    end

    nCycleFrame = math.floor(nCycleFrame)

    local nTotalFrame = 0
    local nEntryID = nil
    nEntryID = RegFunc(function(nFrameTime)
        nTotalFrame = nTotalFrame + 1
        if nTotalFrame % nCycleFrame == 0 then
            xpcall(func, function(err) LOG.ERROR("BackgroundTimer.AddFrameCycle, error nEntryID = %s.\nError = %s", tostring(nEntryID), err) end)
        end
    end, 0, false)

    script._tbDownloadTimer = script._tbDownloadTimer or {}
    script._tbDownloadTimer[nEntryID] = func

    return nEntryID
end

function DownloadTimer.DelTimer(script, nEntryID)
    if not script or not nEntryID then return end
    if not script._tbDownloadTimer then return end

    if script._tbDownloadTimer[nEntryID] then
        UnRegFunc(nEntryID)
        script._tbDownloadTimer[nEntryID] = nil
    end
end

function DownloadTimer.DelAllTimer(script)
    if not script then return end

    if script._tbDownloadTimer then
        for nEntryID, _ in pairs(script._tbDownloadTimer) do
            DownloadTimer.DelTimer(script, nEntryID)
        end
        script._tbDownloadTimer = nil
    end
end

return DownloadTimer
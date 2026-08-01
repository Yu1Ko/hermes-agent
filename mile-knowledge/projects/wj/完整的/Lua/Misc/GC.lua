-- ---------------------------------------------------------------------------------
-- Author: huqing
-- Name: GC
-- Date: 2022-12-12 16:25:58
-- Desc: Lua GC 、 图集释放
-- ---------------------------------------------------------------------------------

GC = GC or {className = "GC"}
local self = GC

local GC_STEP = true
local LUA_GC_INTERVAL = 10      -- 单位 秒
local LUA_GC_MAX = Platform.IsIos() and 90 or 135           -- 单位 M
local LUA_GC_MEM_FLOAT= 0.2     -- 内存浮动

if GC_STEP then
    LUA_GC_INTERVAL = 0.2      -- 单位 秒

    self.bRunningGC = true
    self.nLastLuaMemKB = 0
    self.nLastGcMemKB = 0
    self.bRunningGC = false
    self.nGCRoundFrameCount = 0
else
    LUA_GC_INTERVAL = 10      -- 单位 秒

    self.nMemGCMax = LUA_GC_MAX
    self.nMemLast = 0
end

function GC.Start()
    Event.Reg(self, EventType.OnViewClose, function(nViewID)
        -- UIHelper.RemoveUnusedTexture()
    end)

    Event.Reg(self, EventType.OnViewDestroy, function(nViewID)
        local szLayer = UIMgr.GetViewLayerByViewID(nViewID)
        if szLayer ~= UILayer.Page then
            return
        end

        Timer.DelTimer(self, self.nOnViewDestroyTimerID)
        self.nOnViewDestroyTimerID = Timer.Add(self, 3, function()
            if Config.bOptickLuaSample then BeginSample("OnViewDestroy.RemoveUnusedTexture") end
            UIHelper.RemoveUnusedTexture()
            if Config.bOptickLuaSample then EndSample() end
        end)

        if Config.bOptickLuaSample then BeginSample("OnViewDestroy.collectgarbage") end
        GC.FullGC()
        if Config.bOptickLuaSample then EndSample() end
    end)

    Event.Reg(self, "SCENE_BEGIN_LOAD", function(nSceneID)
        PrefabPool.ClearAllPoorCache()
        if Config.bOptickLuaSample then BeginSample("SCENE_BEGIN_LOAD.RemoveUnusedTexture") end
        UIHelper.RemoveUnusedTexture()
        if Config.bOptickLuaSample then EndSample() end

        GC.CollectDynTabs()          -- 清理DynTab表的缓存
        Event.Reg(self, EventType.OnViewClose, function(viewID)
            if viewID == VIEW_ID.PanelLoading then
                cc.Director:getInstance():purgeCachedData()
            end
        end,true)
    end)


    

    Event.Reg(self, EventType.OnAccountLogout, function()
        if Config.bOptickLuaSample then BeginSample("OnAccountLogout.RemoveUnusedTexture") end
        UIHelper.RemoveUnusedTexture()
        cc.Director:getInstance():purgeCachedData()
        if Config.bOptickLuaSample then EndSample() end

        if Config.bOptickLuaSample then BeginSample("OnAccountLogout.collectgarbage") end
            GC.FullGC(true)
        if Config.bOptickLuaSample then EndSample() end
    end)


    if GC_STEP then
        Timer.AddCycle(self, LUA_GC_INTERVAL, function()
            GC._stepGC()
        end)
    else
        Timer.AddCycle(self, LUA_GC_INTERVAL, function()
            GC._fullGC()
        end)
    end

end

---comment 清理动态txt表
function GC.CollectDynTabs()
    if Config.bOptickLuaSample then BeginSample("GC.CollectDynTabs()") end
    g_tTable.ClearDynTabCache()
    if Config.bOptickLuaSample then EndSample() end
end

function GC.FullGC(bForce)
    if Config.bOptickLuaSample then BeginSample("GC.FullGC()") end
    local bOpen = false
    if bOpen or bForce then
        collectgarbage("collect")
    end
    if Config.bOptickLuaSample then EndSample() end
end

function GC._stepGC()
    -- 战斗中不GC (非iOS才做这个事情，因为iOS内存比较紧缺，还是需要去实时GC的)
    if not Platform.IsIos() then
        if g_pClientPlayer and g_pClientPlayer.bFightState then
            return
        end
    end

    local memKB = collectgarbage("count")
    local diffKB = memKB - self.nLastLuaMemKB

    if math.abs(diffKB) > 200 then -- 200kb变化量打印一次
        --LOG.INFO("[LuaGC] Lua Mem：%.3f KB,  Diff: %.3f KB", memKB, memKB - self.nLastLuaMemKB)
    end

    self.nLastLuaMemKB = memKB

    if self.bRunningGC then
        self.nGCRoundFrameCount = self.nGCRoundFrameCount + 1

        if Config.bOptickLuaSample then BeginSample("Lua.GC") end
        if collectgarbage("step", 200) then
            self.bRunningGC = false
            memKB = collectgarbage("count")
            LOG.INFO("[LuaGC] lua stack memory: %.3f M, GC: %.3f KB, Round: %d", memKB / 1024, self.nLastGcMemKB - memKB, self.nGCRoundFrameCount)
            self.nLastGcMemKB = memKB --这里有待商榷，因为gc过程中增加的量，是否应该导致触发新gc。
        end
        if Config.bOptickLuaSample then EndSample() end

    elseif (memKB - self.nLastGcMemKB > 1024) then -- 1M
        self.bRunningGC = true
        self.nGCRoundFrameCount = 0
    end
end

function GC._fullGC()
    -- 战斗中不GC (非iOS才做这个事情，因为iOS内存比较紧缺，还是需要去实时GC的)
    if not Platform.IsIos() then
        if g_pClientPlayer and g_pClientPlayer.bFightState then
            return
        end
    end

    local nCurrMem = collectgarbage("count") / 1024
    local nAfterGCMem = 0
    local nDiffMem = nCurrMem - self.nMemLast

    if nCurrMem >= self.nMemGCMax then
        --回收
        if Config.bOptickLuaSample then BeginSample("Lua.GC") end
            collectgarbage("collect")
        if Config.bOptickLuaSample then EndSample() end
        --
        nAfterGCMem = collectgarbage("count") / 1024

        --增涨
        if nAfterGCMem >= self.nMemGCMax then
            self.nMemGCMax = nAfterGCMem * (1 + LUA_GC_MEM_FLOAT) --内存增长20%
        --缩减
        elseif nAfterGCMem <= (self.nMemGCMax * (1-LUA_GC_MEM_FLOAT) / (1+LUA_GC_MEM_FLOAT)) then --内存下降20%
            self.nMemGCMax = nAfterGCMem / (1 + LUA_GC_MEM_FLOAT)
        end

        --维持在一定水平
        if self.nMemGCMax < LUA_GC_MAX then
            self.nMemGCMax = LUA_GC_MAX
        end

        nDiffMem = nAfterGCMem - nCurrMem

        print(string.format("lua stack memory [GC], prv=%.3fM, cur=%.3fM, max=%.3fM, diff=%.3fM", self.nMemLast, nCurrMem, self.nMemGCMax, nDiffMem))
        self.nMemLast = nAfterGCMem
    else
        print(string.format("lua stack memory, prv=%.3fM, cur=%.3fM, max=%.3fM, diff=%.3fM", self.nMemLast, nCurrMem, self.nMemGCMax, nDiffMem))
        self.nMemLast = nCurrMem
    end
end

GC.Start()

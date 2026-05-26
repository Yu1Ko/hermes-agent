PrefabPool = class("PrefabPool")

local DEFAULT_MAX_CACHE_COUNT = 10

local m_tbPoolMap = {}
local m_bDebug = false

local m_nAllocatedPoolID = 0
local function _getNewPoolID()
    m_nAllocatedPoolID = m_nAllocatedPoolID + 1
    return m_nAllocatedPoolID
end

function PrefabPool.Init()
    --程序退出释放所有池子
    Event.Reg(PrefabPool, EventType.OnAppPreQuit, PrefabPool.DisposeAllPool)
end

function PrefabPool.UnInit()
    PrefabPool.DisposeAllPool()
end

--使用完成后要调用prefabPool:Dispose()释放
function PrefabPool.New(nPrefabID, nMaxCacheCount)
    local config = TabHelper.GetUIPrefabTab(nPrefabID)
    if not config then
        LOG.ERROR("[PrefabPool] PrefabID config does not exist.")
        return
    end

    local prefabPool = PrefabPool.CreateInstance(PrefabPool)

    local nID = _getNewPoolID()

    prefabPool.m_tbPool = {}
    prefabPool.m_tbPoolNodeMap = {}
    prefabPool.m_tbNodeScriptMap = {}
    prefabPool.m_nID = nID
    prefabPool.m_nPrefabID = nPrefabID
    prefabPool.m_nMaxCacheCount = nMaxCacheCount or DEFAULT_MAX_CACHE_COUNT
    prefabPool.m_bDisposed = false
    prefabPool.m_nInternalID = 0

    m_tbPoolMap[nPrefabID] = m_tbPoolMap[nPrefabID] or {}
    m_tbPoolMap[nPrefabID][nID] = prefabPool

    return prefabPool
end

function PrefabPool.DisposeAllPool()
    LOG.INFO("[PrefabPool] DisposeAllPool")
    local tPoolList = {}
    for _, v in pairs(m_tbPoolMap) do
        for _, prefabPool in pairs(v) do
            table.insert(tPoolList, prefabPool)
        end
    end

    for _, prefabPool in ipairs(tPoolList) do
        prefabPool:Dispose()
    end
    m_tbPoolMap = {}
end

function PrefabPool.ClearAllPoorCache()
    LOG.INFO("[PrefabPool] ClearAllPoorCache")
    for _, v in pairs(m_tbPoolMap) do
        for _, prefabPool in pairs(v) do
            prefabPool:ClearCache()
        end
    end
end

function PrefabPool.GM_PrintPoolInfo()
    local szInfo = "[PrefabPool]\n"
    local nPoolCount = 0
    local nTotalCreatedCount = 0
    local nTotalCachedCount = 0
    local tPoolInfoList = {}

    for _, v in pairs(m_tbPoolMap) do
        for _, prefabPool in pairs(v) do
            local szPrefabKey = table.get_key(PREFAB_ID, prefabPool.m_nPrefabID)
            local nCreateCount = table.get_len(prefabPool.m_tbNodeScriptMap)
            local nCacheCount = #prefabPool.m_tbPool
            nPoolCount = nPoolCount + 1
            nTotalCreatedCount = nTotalCreatedCount + nCreateCount
            nTotalCachedCount = nTotalCachedCount + nCacheCount

            table.insert(tPoolInfoList, {
                nID = prefabPool.m_nID,
                szInfo = string.format("[%d - %s] created:%d, cached:%d/%d\n",
                prefabPool.m_nID, szPrefabKey, nCreateCount, nCacheCount, prefabPool.m_nMaxCacheCount)
            })
        end
    end

    table.sort(tPoolInfoList, function(a, b) return a.nID < b.nID end)
    for _, v in ipairs(tPoolInfoList) do
        szInfo = szInfo .. v.szInfo
    end

    szInfo = szInfo .. string.format("[Total] pool:%d, created:%d, cached:%d", nPoolCount, nTotalCreatedCount, nTotalCachedCount)
    print(szInfo)
    --OutputMessage("MSG_SYS", szInfo)
end

function PrefabPool.GM_PrintPoolDetailInfo(nID)
    local prefabPool
    for _, v in pairs(m_tbPoolMap) do
        for _, pool in pairs(v) do
            if pool.m_nID == nID then
                prefabPool = pool
                break
            end
        end
    end

    if not prefabPool then
        return
    end

    local tNodeInfoList = {}

    local szPrefabKey = table.get_key(PREFAB_ID, prefabPool.m_nPrefabID)
    local nCreateCount = table.get_len(prefabPool.m_tbNodeScriptMap)
    local nCacheCount = #prefabPool.m_tbPool
    local szInfo = string.format("[PrefabPool] [%d - %s] created:%d, cached:%d/%d\n",
    prefabPool.m_nID, szPrefabKey, nCreateCount, nCacheCount, prefabPool.m_nMaxCacheCount)
    for node, scriptView in pairs(prefabPool.m_tbNodeScriptMap) do
        local nID = scriptView._nPoolCreatedID
        local szName = tostring(UIHelper.GetName(node))
        if prefabPool.m_tbPoolNodeMap[node] then
            table.insert(tNodeInfoList, {
                nID = nID,
                szInfo = string.format("[%d - %s] state:cached\n", nID, szName)
            })
        else
            local szPath = UIHelper.GetParent(node) and UIHelper.GetNodePath(node) or "(nil)"
            table.insert(tNodeInfoList, {
                nID = nID,
                szInfo = string.format("[%d - %s] state:allocated, path:%s\n", nID, szName, szPath)
            })
        end
    end

    table.sort(tNodeInfoList, function(a, b) return a.nID < b.nID end)
    for _, v in ipairs(tNodeInfoList) do
        szInfo = szInfo .. v.szInfo
    end

    print(szInfo)
    --OutputMessage("MSG_SYS", szInfo)
end

function PrefabPool.GM_SetDebugEnable(bEnabled)
    m_bDebug = bEnabled
end

----------------------------------------------------------------

function PrefabPool:Allocate(parent, ...)
    if self.m_bDisposed then
        return
    end

    if not parent then
        LOG.ERROR("[PrefabPool] Please set a prefab parent.")
        return
    end

    local node, scriptView
    if #self.m_tbPool > 0 then
        node = table.remove(self.m_tbPool)
        self.m_tbPoolNodeMap[node] = false
        scriptView = self.m_tbNodeScriptMap[node]
        if scriptView._bFirstOnEnter then
			local tbOnEnterParams = {...}
			scriptView._tbOnEnterParams = (table.get_len(tbOnEnterParams) > 0) and tbOnEnterParams or nil
		end

        parent:addChild(node)
        UIHelper.SetPosition(node, 0, 0)
    else
        scriptView = UIHelper.AddPrefab(self.m_nPrefabID, parent, ...)
        if scriptView then
            self.m_nInternalID = self.m_nInternalID + 1
            scriptView._nPoolCreatedID = self.m_nInternalID
            scriptView._keepmt = true
            node = scriptView._rootNode or scriptView
            node:retain() --引用计数+1
            self.m_tbNodeScriptMap[node] = scriptView
        end
    end

    if m_bDebug then
        local szPrefabKey = table.get_key(PREFAB_ID, self.m_nPrefabID)
        print(string.format("[PrefabPool] [%d - %s] Allocate (id:%d, parent:%s)", self.m_nID, szPrefabKey, scriptView._nPoolCreatedID, tostring(UIHelper.GetName(parent))))
    end

    if scriptView and scriptView.OnPoolAllocated then
        scriptView:OnPoolAllocated(...)
    end

    return node, scriptView
end

function PrefabPool:Recycle(node, ...)
    if self.m_bDisposed then
        return
    end

    if not node then
        LOG.ERROR("[PrefabPool] Can't recycle a nil node.")
        return
    end

    local scriptView = self.m_tbNodeScriptMap[node]
    if not scriptView then
        LOG.ERROR("[PrefabPool] The node is not created from current pool.")
        return
    end

    if m_bDebug then
        local szPrefabKey = table.get_key(PREFAB_ID, self.m_nPrefabID)
        print(string.format("[PrefabPool] [%d - %s] Recycle (id:%d)", self.m_nID, szPrefabKey, scriptView._nPoolCreatedID))
    end

    if scriptView.OnPoolRecycled then
        scriptView:OnPoolRecycled(...)
    end

    if #self.m_tbPool < self.m_nMaxCacheCount then
        UIHelper.RemoveFromParent(node)
        table.insert(self.m_tbPool, node)
        self.m_tbPoolNodeMap[node] = true
    else
        scriptView._keepmt = false
        if scriptView.OnExit then
            scriptView:OnExit()
        end
        self.m_tbNodeScriptMap[node] = nil
        UIHelper.RemoveFromParent(node, true)
        node:release() --引用计数-1
    end
end

--回收所有不在池子中的节点
function PrefabPool:RecycleAll()
    local tbAllocatedNode = {}
    for node, script in pairs(self.m_tbNodeScriptMap) do
        if not self.m_tbPoolNodeMap[node] then
            table.insert(tbAllocatedNode, node)
        end
    end
    for _, node in ipairs(tbAllocatedNode) do
        self:Recycle(node)
    end
end

--清理整个池子以及其中创建的所有节点
function PrefabPool:Clear()
    if m_bDebug then
        local szPrefabKey = table.get_key(PREFAB_ID, self.m_nPrefabID)
        print(string.format("[PrefabPool] [%d - %s] Clear", self.m_nID, szPrefabKey))
    end

    for node, scriptView in pairs(self.m_tbNodeScriptMap) do
        if scriptView then
            scriptView._keepmt = false
        end
        if node then
            node:release()
        end
    end

    self.m_tbPool = {}
    self.m_tbPoolNodeMap = {}
    self.m_tbNodeScriptMap = {}
end

--仅清理未分配的缓存节点
function PrefabPool:ClearCache()
    if m_bDebug then
        local szPrefabKey = table.get_key(PREFAB_ID, self.m_nPrefabID)
        print(string.format("[PrefabPool] [%d - %s] ClearCache", self.m_nID, szPrefabKey))
    end

    for _, node in pairs(self.m_tbPool) do
        local scriptView = self.m_tbNodeScriptMap[node]
        scriptView._keepmt = false
        if scriptView.OnExit then
            scriptView:OnExit()
        end
        self.m_tbNodeScriptMap[node] = nil
        node:release() --引用计数-1
    end
    self.m_tbPool = {}
    self.m_tbPoolNodeMap = {}
end

--释放对象池
function PrefabPool:Dispose()
    self:Clear()

    if m_bDebug then
        local szPrefabKey = table.get_key(PREFAB_ID, self.m_nPrefabID)
        print(string.format("[PrefabPool] [%d - %s] Dispose", self.m_nID, szPrefabKey))
    end

    if m_tbPoolMap[self.m_nPrefabID] and m_tbPoolMap[self.m_nPrefabID][self.m_nID] then
        m_tbPoolMap[self.m_nPrefabID][self.m_nID] = nil
    end
    self.m_bDisposed = true
end

return PrefabPool

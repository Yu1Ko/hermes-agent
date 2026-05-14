-- UI配置表管理器
local tTableFile = g_tTableFile
local tMetatable = {}
local getTickCount = GetTickCount
local kCacheTime = 300 * 1000   -- 缓存多长时间(毫秒)
local registerTab

-- 全局table表
g_tTable = g_tTable or {
    __tWeakRefs = setmetatable({}, {__mode='v'}),   -- 弱引用表{szKey = pTable, ...}
    __tMultiTab = setmetatable({}, {__mode='k'}),
    __tLoaded = {},         -- 已加载的列表{szKey = pTable, ...}
    __tFreeTabs = {},       -- 待释放的列表{szKey = {pTable, nTimeStamp}, ...}
    __tEvents = {},         -- 注册事件
    __tNil = {},            -- 标记空table
    __nGcTimerID = 0,       -- GC定时器ID
}
setmetatable(g_tTable, tMetatable)  -- 设置元表
local this = g_tTable

---comment 正向遍历tab表每行数据，从第2行开始
---@param tab KLuaTab tab表的c++对象
---@return function iter 迭代器
---@return userdata KLuaTab
---@return integer index
function ilines(tab)
    assert(type(tab) == "userdata" and tab.GetRowCount, "Table expected, got " .. type(tab))
    local nCount = tab:GetRowCount()
    return function(tab, index)
        index = index + 1
        if index <= nCount then
            return index, tab:GetRow(index)
        end
    end, tab, 1
end

---comment 反向编译tab表的每行，到第二行结束
---@param tab KLuaTab tab表的c++对象
---@return function iter 迭代器
---@return KLuaTab tab
---@return integer rindex
function ilines_r(tab)
    assert(type(tab) == "userdata" and tab.GetRowCount, "tab expected, got " .. type(tab))
    return function (pTab, index)
        index = index - 1
        if index > 1 then
            return index, pTab:GetRow(index)
        end
    end, tab, tab:GetRowCount() + 1
end

---comment 根据键值遍历符合行数据
---@param pTab KLuaTab tab表的c++对象
---@param key1 any 键值1
---@param key2 any|nil 键值2
---@return function iter 迭代器函数
function tab_range(pTab, key1, key2)
    local nFirst, nLast = pTab:Range(key1, key2)
    if not nFirst then
        return function () end
    end

    return function ()
        local index = nFirst
        if index <= nLast then
            nFirst = nFirst + 1
            return pTab:GetSorted(index)
        end
    end
end

-- 重载
function g_tTable.OnReload()
end

---comment 加载启动阶段需要加载的配置表
function g_tTable.LoadStartupTabs()
    local loader = KG_Table.CreateParallelLoader()

    if Const.kEnableDynTab then
        for szName, tDef in pairs(tTableFile) do
            if tDef.DynTab and not this.__tWeakRefs[szName] then
                loader:AddDyn(szName, tDef.KeyNum or 1, tDef.Path, tDef.Title)
            end
        end
    end

    local tTableNames = {"Quest", "Quests", "ShieldQuest"}
    for _, szName in ipairs(tTableNames) do
        local tDef = tTableFile[szName]
        if not this.__tWeakRefs[szName] and (not tDef.DynTab and not tDef.bCache or not Const.kEnableDynTab) then
            loader:AddTab(szName, tDef.KeyNum or 1, tDef.Path, tDef.Title)
        end
    end

    local tRets = loader:Load()
    for szName, pTab in pairs(tRets) do
        registerTab(szName, tTableFile[szName], pTab)
    end

    for szName, pTab in pairs(tRets) do
        if tTableFile[szName].MultiTab then
            local tMultiTab = MultiTab:new(nil)
            tMultiTab:AddTab(pTab)
            for _, szTabName in ipairs(tTableFile[szName].MultiTab) do
                tMultiTab:AddTab(g_tTable[szTabName])
            end
            this.__tMultiTab[pTab] = tMultiTab
        end
    end
end

---comment 清理动态加载表的缓存数据
function g_tTable.ClearDynTabCache()
    GC.FullGC(true)       -- gc, 以便清理DynTab中缓存的引用关系

    if not Const.kEnableDynTab then
        return
    end

    for szName, tDef in pairs(tTableFile) do
        if tDef.DynTab then
            local tab = this.__tLoaded[szName]
            if tab then
                tab:ClearCache()
            end
        end
    end
    GC.FullGC()           -- 再次垃圾收集
end

--Event.Reg(g_tTable.__tEvents, "RELOAD_GLOBAL_STRINGS", ResetGlobalString)

---comment 定时清除长时间没有访问的table
local function onTimerGc()
    local nMaxTime = kCacheTime
    local nTimeNow = getTickCount()
    local tFrees = this.__tFreeTabs
    for szKey, tPair in pairs(tFrees) do
        if nTimeNow - tPair[2] > nMaxTime then
            tFrees[szKey] = nil
        end
    end
end

---comment 将已加载的tab表对象注册到内部容器
---@param szKey string name
---@param tDef table tab define
---@param pTab KLuaTab C++ tab表
function registerTab(szKey, tDef, pTab)
    this.__tWeakRefs[szKey] = pTab
    if tDef.bCache or tDef.DynTab then
        this.__tLoaded[szKey] = pTab
    else
        this.__tFreeTabs[szKey] = { pTab, getTickCount() }
        if this.__nGcTimerID == 0 then
            this.__nGcTimerID = Timer.AddCycle(this.__tEvents, kCacheTime / 1000, onTimerGc)
        end
    end
end

---comment UI配置表延迟到第一次访问时加载
---@param tTable table
---@param szKey string table name
---@return KLuaTab|nil
function tMetatable.__index(tTable, szKey)
    local pTab = tTable.__tWeakRefs[szKey]
    if pTab then
        if pTab == tTable.__tNil then
            return  -- invalid table
        end

        local tFree = tTable.__tFreeTabs[szKey]
        if tFree then
            tFree[2] = getTickCount()   -- update last visit time
        end

        if tTable.__tMultiTab[pTab] then
            return tTable.__tMultiTab[pTab]
        end

        return pTab
    end

    -- 赋默认值, 避免错误配置重复加载
    tTable.__tLoaded[szKey] = tTable.__tNil
    tTable.__tWeakRefs[szKey] = tTable.__tNil

    local tTabDef = tTableFile[szKey]
    if not tTabDef then
        LOG.ERROR("[tab] is undefined {%s}", szKey)
        return
    end

    local szPath = tTabDef.Path
    --local szPath = GetAdjustTabPath(tTabDef.Path)
    pTab = KG_Table.LoadTab(tTabDef.KeyNum or 1, szPath, tTabDef.Title, TABLE_FILE_OPEN_MODE.NORMAL)
    if not pTab then
        LOG.ERROR("[tab] load failed {%s, %s}", szKey, tTabDef.Path)
        return
    end

    registerTab(szKey, tTabDef, pTab)

    if tTabDef.MultiTab then
        local tMultiTab = MultiTab:new(nil)
        tMultiTab:AddTab(pTab)
        for _, szName in ipairs(tTabDef.MultiTab) do
            tMultiTab:AddTab(g_tTable[szName])
        end
        tTable.__tMultiTab[pTab] = tMultiTab
        return tMultiTab
    end

    return pTab
end

--just for release table
tMetatable.__newindex = function(tTable, szKey, Value)
    if type(Value) ~= "nil" then
        assert(false)
    else
        tTable.__tLoaded[szKey] = nil
        tTable.__tWeakRefs[szKey] = nil
        tTable.__tFreeTabs[szKey] = nil
    end
end

MultiTab = {
}

function MultiTab:new(o)
    o = o or {}
    o.tbTab = {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function MultiTab:AddTab(tab)
    if not tab then return end
    table.insert(self.tbTab, tab)
end

function MultiTab:Search(...)
    for _, pTab in ipairs(self.tbTab) do
        local row = pTab:Search(...)
        if row then
            return row
        end
    end
end

function MultiTab:GetRowCount()
    local nCount = 0
    for _, pTab in ipairs(self.tbTab) do
        nCount = nCount + pTab:GetRowCount()
    end
    return nCount
end

function MultiTab:GetRow(index)
    for _, pTab in ipairs(self.tbTab) do
        local rowCount = pTab:GetRowCount()
        if index <= rowCount then
            return pTab:GetRow(index)
        else
            index = index - rowCount
        end
    end
end

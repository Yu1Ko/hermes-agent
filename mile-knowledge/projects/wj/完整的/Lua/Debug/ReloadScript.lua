--[[
    重载脚本
--]]

ReloadScript = ReloadScript or { tRequired = {} }

-- 覆盖require逻辑，处理重载时循环加载的问题
local function myRequire(szPath)
    local szPath = string.gsub(szPath, "\\", "/")
    if ReloadScript.tRequired[szPath] then  -- 处理循环Require的问题
        return package.loaded[szPath]
    end

    ReloadScript.tRequired[szPath] = true
    return ReloadScript.doReload(szPath)
end

local tReloadMeta = {
    __index = setmetatable(
        { g_bIsReloading = true, require = myRequire },
        { __index = _G }
    )
}

local function loadTextFile(szFile)
    local f = io.open(szFile, 'r')
    if not f then
        return nil
    end

    local text = f:read("*a")
    f:close()
    if not text or #text <= 3 then
        return text
    end

    -- 去除 utf8-bom
    local b = string.byte(text, 1)
    local o = string.byte(text, 2)
    local m = string.byte(text, 3)
    if b == 0xEF and o == 0xBB and m == 0xBF then
        return string.sub(text, 4)
    else
        return text
    end
end

local function tryLoadScript(szScriptName)
    for szPattern in string.gmatch(package.path, '[^;]+%?[^;]*') do
        local szPath = string.gsub(szPattern, '%?', szScriptName)
        local szScript = loadTextFile(szPath)
        if szScript then
           return szScript, szPath
        end
    end
end

function ReloadScript.Init()
    if Platform.IsWindows() then
        package.path = package.path .. ';mui/?;mui/?.lua' -- for loadfile
    end
end

function ReloadScript.Reload(szScriptName)
    --标准路径分隔符
    szScriptName = string.gsub(szScriptName, "\\", "/")
    ReloadScript.tRequired[szScriptName] = true
    local ret = ReloadScript.doReload(szScriptName)
    ReloadScript.tRequired = {}
    return ret
end

function ReloadScript.doReload(szScriptName)
    -- 在package.path中查找脚本
    local szScript, szFilePath = tryLoadScript(szScriptName)
    if not szScript then
        LOG.ERROR("----> fail to find script: %s", szScriptName)
        return
    end

    local fn, szError = loadstring(szScript, szFilePath)
    if not fn then
        LOG.ERROR("----> fail to load script: %s\n%s", szScriptName, szError)
        return
    end

    local prev = package.loaded[szScriptName]
    local env = {}
    setmetatable(env, tReloadMeta)
    setfenv(fn, env)                -- 在封闭环境内执行
    local isOk, ret = pcall(fn)
    if not isOk then
        LOG.ERROR("----> fail to load script: %s\n%s", szScriptName, ret)
        return
    end

    if type(prev) == "table" then
        -- 针对require返回的table，将新的方法函数覆盖旧的
        if type(ret) == "table" then
            local fnReload
            for k, v in pairs(ret) do
                if k == "OnReload" then
                    fnReload = v
                elseif type(v) == "function" then
                    prev[k] = v
                else
                    --TODO: 如何处理运行时数据
                end
            end

            --TODO: 重载接口的含义需要明确
            if fnReload then
                fnReload(prev, ret)
            end
        end
    else
        package.loaded[szScriptName] = ret or true
    end

    -- 处理封闭环境中的全局变量
    local tReloads = {}
    for k, new in pairs(env) do
        local old = _G[k]
        if type(new) == "table" then
            if new.OnReload then                -- 若有OnReload, 重载逻辑交由其处理
                table.insert(tReloads, {new, old})
            elseif type(old) == "table" then    -- 默认保存旧数据
                for key, value in pairs(old) do
                    if type(value) ~= "function" then
                        new[key] = value
                    end
                end
            end
        end

        -- 更新全局变量
        _G[k] = new
    end

    -- 执行重载
    for _, t in ipairs(tReloads) do
        t[1].OnReload(t[1], t[2])
    end
    return package.loaded[szScriptName]
end

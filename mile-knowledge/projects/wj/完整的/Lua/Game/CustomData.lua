-- 自定义本地存盘数据（存本地文件）
--[[ 使用案例
local tMyData = {
    isOk = false,
    szName = "",
}
-- 添加函数处理版本更新情况（改字段名称等）
function tMyData:OnLoaded(tLoad)
    if tLoad.name then
        self.szName = tLoad.name
    end
end

-- note: 加载数据时，不会直接整个覆盖到目标table中，而是将声明仅覆盖声明时指定的几个key的对应值过来。
--      所以如果这个存盘数据是个单纯的列表，直接定义一个table，将不能正常加载，需要通过以下两种方式确保正常加载数据
--  1. 实现OnLoaded接口，在其中将读取的数据复制到自身
--    OnLoaded = function(self, tLoad)
--        Lib.ShadowCopyTab(tLoad, self)
--    end
--  2. 额外加一层，从而加载时会将这个key的数据覆盖进去，从而正常加载数据
--    tMyData = {
--      tData = {1, 2, 3}
--    }

-- 注册到系统以后，当加载存盘文件时会更新tMyData中声明的字段，并调用OnLoaded
CustomData.Register(CustomDataType.Global, "myData", tMyData)

-- 当修改字段以后
tMyData.isOk = true
-- 标记需要存盘
tMyData.Dirty()
-- 如需立即存盘，则调用Flush立即写文件
tMyData.Flush()
]]

CustomData = CustomData or {
    className = "CustomData",
    szAccountName = nil,
    szSmAccountName = nil,
    szRealServerName = nil,
    szRoleName = nil,
    tCustomDatas = {}
}

local kDelaySaveFrame = 1   -- 延迟存文件时间（表现帧）
local self = CustomData
local registerEvents, makesureTypeData
local updateToConfig, doSaveFile, doLoadFile, unloadData

CustomDataType = {
    Global = 1,         -- 全局，启动游戏初始化
    Account = 2,        -- 账号，登录账号
    Role = 3,           -- 角色，登录游戏
    --Region = 4,         -- 区服，登录游戏
    --Server = 5,         -- 服务器，登录游戏
}

function CustomData.Init()
    local fileUtil = cc.FileUtils:getInstance()
    if not fileUtil:isDirectoryExist("customdata") then
        fileUtil:createDirectory("customdata")
    end

    registerEvents()
    doLoadFile(CustomDataType.Global)
end

-- 重载
function CustomData.OnReload()
    Event.UnRegAll(self)
    registerEvents()
end

-- 获取注册的缓存数据
-- 若没有注册对应键值的数据则返回nil
function CustomData.GetData(nType, szKey)
    local tTypeData = self.tCustomDatas[nType]
    if tTypeData then
        return tTypeData.tDatas[szKey]
    end
end

-- 将tConfig配置表注册到管理器
-- 并给tConfig添加元表方法{ Dirty(), Flush() }用于标记更改和立即写文件
-- 当指定类型的存盘数据加载后会自动更新到注册的配置表中
function CustomData.Register(nType, szKey, tConfig)
    assert(table.get_key(CustomDataType, nType))
    local tTypeData = makesureTypeData(nType)

    -- 备份初始值
    tTypeData.tConfigs[szKey] = Lib.copyTab(tConfig)

    -- 已经加载则更新配置
    if tTypeData.isLoaded then
        local tLoaded = tTypeData.tDatas[szKey]
        if tLoaded and tLoaded ~= tConfig then  -- 已经加载
            updateToConfig(tConfig, tLoaded)    -- 将存盘数据更新到配置table中
        end
    end
    tTypeData.tDatas[szKey] = tConfig

    -- 添加元表
    return setmetatable(tConfig, {
        __index = {
            Dirty = function() CustomData.Dirty(nType) end,
            Flush = function() CustomData.Flush(nType) end,
        }
    });
end

-- 标记某类型配置需要存盘
function CustomData.Dirty(nType)
    local tTypeData = self.tCustomDatas[nType]
    if not tTypeData or tTypeData.isDirty then
        return
    end

    tTypeData.isDirty = true
    if tTypeData.isLoaded then  -- 如果没有加载就要存盘？
        tTypeData.nTimerID = Timer.AddFrame(self, kDelaySaveFrame, function ()
            tTypeData.isDirty = false
            tTypeData.nTimerID = 0
            doSaveFile(nType)
        end)
    end
end

-- 立即将执行类型配置写文件
function CustomData.Flush(nType)
    local tTypeData = self.tCustomDatas[nType]
    if not tTypeData then
        return
    end

    if tTypeData.isDirty then
        Timer.DelTimer(self, tTypeData.nTimerID)
        tTypeData.isDirty = false
        tTypeData.nTimerID = 0
    end

    doSaveFile(nType)
end

-- 将所有数据写文件
function CustomData.FlushAll()
    for nType, tTypeData in pairs(self.tCustomDatas) do
        if tTypeData.isDirty then
            Timer.DelTimer(self, tTypeData.nTimerID)
            tTypeData.isDirty = false
            tTypeData.nTimerID = 0
        end

        doSaveFile(nType)
    end
end

local function finishRoleData()
    doSaveFile(CustomDataType.Role)
    unloadData(CustomDataType.Role)
end

local function finishAccountData()
    doSaveFile(CustomDataType.Role)
    unloadData(CustomDataType.Role)

    doSaveFile(CustomDataType.Account)
    unloadData(CustomDataType.Account)
end

function registerEvents()
    Event.Reg(self, "GAME_START", function ()
        doLoadFile(CustomDataType.Global)
    end)
    Event.Reg(self, "GAME_EXIT", function ()
        finishAccountData()
        doSaveFile(CustomDataType.Global)
        unloadData(CustomDataType.Global)
        self.szRealServerName = nil
        self.szAccountName = nil
        self.szSmAccountName = nil
        self.szRoleName = nil
    end)

    Event.Reg(self, EventType.OnAccountLogin, function ()
        unloadData(CustomDataType.Role)
        unloadData(CustomDataType.Account)

        local tServer = LoginMgr.GetModule(LoginModule.LOGIN_SERVERLIST).GetSelectServer()
        assert(tServer.szRealServer)
        self.szRealServerName = tServer.szRealServer
        self.szAccountName = Login_GetAccount() or g_tbLoginData.tbLoginInfo.szSDKLoginAccount or "_tempAccountName"
        self.szSmAccountName = SM_GetAccountName() or "_tempSmAccountName"
        doLoadFile(CustomDataType.Account)
        doSaveFile(CustomDataType.Global)
    end)
    Event.Reg(self, EventType.OnAccountLogout, function ()
        finishAccountData()
    end)

    Event.Reg(self, EventType.OnRoleLogin, function (szRoleName)
        self.szRoleName = UIHelper.GBKToUTF8(szRoleName)
        doLoadFile(CustomDataType.Role)
        doSaveFile(CustomDataType.Account)
    end)
    Event.Reg(self, "PLAYER_EXIT_GAME", function ()
        print("PLAYER_EXIT_GAME")
        finishRoleData()
        doSaveFile(CustomDataType.Account)
        doSaveFile(CustomDataType.Global)
        self.szRoleName = nil
    end)
    Event.Reg(self, "PLAYER_LEAVE_GAME", function ()
        print("PLAYER_LEAVE_GAME")
        finishRoleData()
        doSaveFile(CustomDataType.Account)
        doSaveFile(CustomDataType.Global)
        self.szRoleName = nil
    end)
end

function makesureTypeData(nType)
    local tTypeData = self.tCustomDatas[nType]
    if not tTypeData then
        tTypeData = {
            isLoaded = false,
            isDirty = false,
            szFile  = "",       -- 存盘文件
            nType = nType,      -- 分类
            nTimerID = 0,       -- 存盘定时器
            tConfigs = {},      -- 注册的配置文件
            tDatas = {},        -- {{szKey = {tConfig, tData}, ...}
        }
        self.tCustomDatas[nType] = tTypeData
    end
    return tTypeData
end

function updateToConfig(tConfig, tLoaded)
    for k, v in pairs(tConfig) do
        local l = tLoaded[k]
        if l ~= nil then
            tConfig[k] = l
        end
    end

    -- 通知到用户做自定义处理
    if tConfig.OnLoaded and IsFunction(tConfig.OnLoaded) then
        tConfig.OnLoaded(tConfig, tLoaded)
    end
end

-- TODO: 暂不能获取区服信息
-- local function getUserRealServerPath()
--     local real_region, real_server = select(5, GetUserServer())
--     return real_region .. "/" .. real_server
-- end

-- local function getUserRealRegionPath()
--     local real_region = select(5, GetUserServer())
--     return real_region
-- end

local function getFilePath(type)
    local p
    if type == CustomDataType.Global then
        p = string.format("customdata/%s", MD5("global"));
    elseif type == CustomDataType.Account then
        p = string.format("customdata/%s", MD5(SM_IsEnable() and self.szSmAccountName or self.szAccountName))
    -- elseif type == CustomDataType.Region then
    --     return string.format("customdata/%s/%s/custom.dat", Login_GetAccount(), getUserRealRegionPath())
    -- elseif type == CustomDataType.Server then
    --     return string.format("customdata/%s/%s/custom.dat", Login_GetAccount(), getUserRealServerPath())
    elseif type == CustomDataType.Role then
        p = string.format("customdata/%s",
            MD5(string.format("%s-%s-%s", self.szAccountName, self.szRealServerName, self.szRoleName))
        )
    end
    if not p then
        return
    end

    local wp = cc.FileUtils:getInstance():getWritablePath()
    if wp and wp ~= "" then
        if wp:sub(#wp, 1) == '/' or p:sub(1, 1) == '/' then
            return string.format("%s/%s", wp, p)
        end
        return string.format("%s%s", wp, p)
    end
    return p
end

function doSaveFile(nType)
    local tTypeData = self.tCustomDatas[nType]
    if not tTypeData or not tTypeData.isLoaded then
        return  -- 还未加载不能存盘
    end

    -- 创建目录
    local dirPath = string.sub(tTypeData.szFile, 1, string.find(tTypeData.szFile, "/[^/]*$"))
    local fileUtil = cc.FileUtils:getInstance()
    if dirPath and dirPath ~= "" and not fileUtil:isDirectoryExist(dirPath) then
        fileUtil:createDirectory(dirPath)
    end

    local s = "return " .. var2str(tTypeData.tDatas, "\t", nil, true)
    fileUtil:writeStringToFile(s, tTypeData.szFile)
end

function doLoadFile(nType)
    local tTypeData = makesureTypeData(nType)
    tTypeData.isLoaded = true
    tTypeData.szFile = getFilePath(nType)

    local s = Lib.GetStringFromFile(tTypeData.szFile)
    if not s then
        return  -- not saved
    end

    local data = str2var(s, nil, true)
    if not data then
        return
    end

    for k, v in pairs(data) do
        local c = tTypeData.tDatas[k]
        if c then
            updateToConfig(c, v)
        else
            tTypeData.tDatas[k] = v
        end
    end
end

function unloadData(nType)
    local tTypeData = self.tCustomDatas[nType]
    if not tTypeData then
        return
    end

    if tTypeData.isDirty then
        Timer.DelTimer(CustomData, tTypeData.nTimerID)
        tTypeData.nTimerID = 0
        tTypeData.isDirty = false
        LOG.ERROR("unexpect state at this time, nType:%s", nType)
    end

    if not tTypeData.isLoaded then
        return
    end

    tTypeData.isLoaded = false
    tTypeData.szFile = ""

    -- 重置配置项为默认值
    for k, c in pairs(tTypeData.tConfigs) do
        local d = tTypeData.tDatas[k]
        if d then
            -- 重置字段为默认
            for _k, _v in pairs(d) do
                local r = c[_k]     -- 初始值
                if r == nil then
                    if type(_v) ~= "function" then
                        d[_k] = nil -- 删除多余字段
                    end
                elseif type(r) == "table" then
                    d[_k] = Lib.copyTab(r)
                elseif type(r) ~= "function" then
                    d[_k] = r
                end
            end
        end
    end
end

--function CustomData.Load(nType)
--    doLoadFile(nType)
--end

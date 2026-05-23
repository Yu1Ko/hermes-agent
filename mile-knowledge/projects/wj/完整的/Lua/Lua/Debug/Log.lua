LOG = LOG or {}

LOG.bFlag = true -- 日志开关
LOG.bTraceback = true -- 是否打印栈信息的开关
LOG.bIsDebugClient = true -- 是否是Debug客户端
if IsFunction(IsDebug) then
    LOG.bIsDebugClient = IsDebug()
end

-- 编码转换
local s_bConvertGBK = Platform.IsWindows() or Platform.IsMac()
local convertStr = s_bConvertGBK and UTF8ToGBK or function (s) return s end
local LogInfo, LogDebug, LogWarning, LogError = LogInfo, LogDebug, LogWarning, LogError

function LOG.INFO(szFormat, ...)
    if not LOG.bFlag then
        return
    end

    local szLog = string.format(szFormat, ...)
    szLog = convertStr(szLog)

    --if LOG.bTraceback then
    --    LOG._doLogInfo(debug.traceback(szLog, 2))
    --else
        LOG._doLogInfo(szLog)
    --end
end

function LOG.DEBUG(szFormat, ...)
    if not LOG.bFlag then
        return
    end

    local szLog = string.format(szFormat, ...)
    szLog = convertStr(szLog)

    --if LOG.bTraceback then
    --    LOG._doLogDebug(debug.traceback(szLog, 2))
    --else
        LOG._doLogDebug(szLog)
    --end
end

function LOG.WARN(szFormat, ...)
    if not LOG.bFlag then
        return
    end

    local szLog = string.format(szFormat, ...)
    szLog = convertStr(szLog)

    if LOG.bTraceback then
        LOG._doLogWarning(debug.traceback(szLog, 2))
    else
        LOG._doLogWarning(szLog)
    end
end

function LOG.ERROR(szFormat, ...)
    if not LOG.bFlag then
        return
    end

    local szLog = string.format(szFormat, ...)
    szLog = convertStr(szLog)

    if LOG.bTraceback then
        LOG._doLogError(debug.traceback(szLog, 2))
    else
        LOG._doLogError(szLog)
    end
end

function LOG.TRACE(szFormat, ...)
    if not LOG.bFlag then
        return
    end

    local szLog = string.format(szFormat, ...)
    szLog = convertStr(szLog)

    if LOG.bTraceback then
        LOG._doLogDebug(debug.traceback(szLog, 2))
    else
        LOG._doLogDebug(szLog)
    end
end

function LOG.TABLE(t, tname, print_one_level)
    if not LOG.bFlag then return end

    if type(t) == "table" then
        LOG.INFO(debug.traceback("LOG.TABLE", 2))
        LOG._recursionTable(t, tname, print_one_level)
    else
        LOG.INFO("table.debug : invalid input type {0}, {1}", t or "nil", tname or "nil")
    end
end

function LOG._parse(value, is_int)
    if value == nil then return "nil" end
    local str_type = is_int or 1
    local str, value_type
    value_type = type(value)

    if is_int then
        if value_type == "number" then
            if str_type == 1 then
                str = string.format("%s", value)
            else
                str = string.format("%s", value)
            end
        elseif value_type == "string" then
            str = string.format("\"%s\"", value)
        elseif value_type == "table" then
            str = string.format("0x%s", string.sub(tostring(value), 8))
        elseif value_type == "function" then
            str = string.format("0x%s", string.sub(tostring(value), 11))
        elseif value_type == "userdata" then
            str = string.format("0x%s", string.sub(tostring(value), 11))
        else
            str = string.format("'%s'%s", tostring(value), type(value))
        end
    else
        if value_type == "number" then
            if str_type == 1 then
                str = string.format("[%s]", value)
            else
                str = string.format("[%s]", value)
            end
        elseif value_type == "string" then
            str = string.format("[\"%s\"]", value)
        elseif value_type == "table" then
            str = string.format("[0x%s]", string.sub(tostring(value), 8))
        elseif value_type == "function" then
            str = string.format("[0x%s]", string.sub(tostring(value), 11))
        elseif value_type == "userdata" then
            str = string.format("[0x%s]", string.sub(tostring(value), 11))
        else
            str = string.format("['%s']%s", tostring(value), type(value))
        end
    end
    return str
end

function LOG._recursionTable(t, tname, print_one_level)
    if not LOG.bFlag then return end

    local _deep_count = 0
    local print_one_table
    local printed_tables = {}
    local t_path = {}

    local szTableLog = string.format("\n%s = \n", tostring(t))

    print_one_table = function(tb, tb_name, print_one_level)
        tb_name = tb_name or "table"
        table.insert(t_path, tb_name)

        local tpath,  tname = ""
        for _ , pname in pairs(t_path) do
            tpath = tpath.."."..pname
        end

        printed_tables[tb] = tpath
        _deep_count = _deep_count + 1
        local str
        local tab = string.rep(" ", _deep_count*4)
        szTableLog = szTableLog .. string.format("%s[\n", tab)
        for k, v in pairs(tb) do
            if type(v) == "table" then
                if printed_tables[v] then
                    str = string.format("%s    %s = %s\n", tab, LOG._parse(k), printed_tables[v])
                    szTableLog = szTableLog .. str
                elseif not print_one_level then
                    str = string.format("%s    %s = \n", tab, LOG._parse(k))
                    szTableLog = szTableLog .. str
                    print_one_table(v, tostring(k))
                else
                    str = string.format("%s    %s = %s\n", tab, LOG._parse(k), LOG._parse(v, 2))
                    szTableLog = szTableLog .. str
                end
            else
                str = string.format("%s    %s = %s\n", tab, LOG._parse(k), LOG._parse(v, 2))
                szTableLog = szTableLog .. str
            end
        end

        if table.is_empty(tb) then
            szTableLog = szTableLog .. string.format("%s  \n", tab)
        end

        szTableLog = szTableLog .. tab.."]\n"
        table.remove(t_path)
        _deep_count = _deep_count - 1
    end

    print_one_table(t, tname, print_one_level)
    if tname then
        LogInfo(convertStr(tname))
    end
    LogInfo(convertStr(szTableLog))
end

function LOG._doLogInfo(szLog)
    -- if s_bConvertGBK and Config.bReleaseVerPrintUILog and not LOG.bIsDebugClient then
    --     SetConsoleColor(0x000A)
    --     print(szLog)
    --     SetConsoleColor(0x000A)
    -- end

    LogInfo(szLog)
end

function LOG._doLogDebug(szLog)
    -- if s_bConvertGBK and Config.bReleaseVerPrintUILog and not LOG.bIsDebugClient then
    --     SetConsoleColor(0x000D)
    --     print(szLog)
    --     SetConsoleColor(0x000A)
    -- end

    LogDebug(szLog)
end

function LOG._doLogWarning(szLog)
    -- if s_bConvertGBK and Config.bReleaseVerPrintUILog and not LOG.bIsDebugClient then
    --     SetConsoleColor(0x0006)
    --     print(szLog)
    --     SetConsoleColor(0x000A)
    -- end

    LogWarning(szLog)
end

function LOG._doLogError(szLog)
    -- if s_bConvertGBK and Config.bReleaseVerPrintUILog and not LOG.bIsDebugClient then
    --     SetConsoleColor(0x0004)
    --     print(szLog)
    --     SetConsoleColor(0x000A)
    -- end

    LogError(szLog)
end


function LOG.CloseTraceback()
    LOG.bTempTraceback = LOG.bTraceback
    LOG.bTraceback = false
end

function LOG.OpenTraceback()
    if IsBoolean(LOG.bTempTraceback) then
        LOG.bTraceback = LOG.bTempTraceback
    end
end

setmetatable(LOG, {
    -- 输出INFO级别日志但不带堆栈信息
    __call = function (_, fmt, ...)
        if not LOG.bFlag then
            return
        end

        local szLog = string.format(fmt, ...)
        szLog = convertStr(szLog)
        LogInfo(szLog)
    end,
})

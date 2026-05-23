-------------------------------------------------------
-- @File  : base.lua
-- @Desc  :
-- @Author: 未知
-- @Date  : 2015-03-18 14:02:17
-- @Email : admin@derzh.com
-- @Last modified by:   Zhai Yiming
-- @Last modified time: 2017-05-10 16:28:01
-- @Version: 1.0
-- @ChangeLog:
--  + v1.0 优化var2str函数执行效率提高80倍 -- via翟一鸣
--  +      大量字符串连接时绝对忌讳使用..连接字符串
--  +      使用table.concat可大大优化性能
-------------------------------------------------------

-------------------------------------------------------
-- 分为一下部分，后续增加函数前往对应部分增加
-- 1、客户端属性 2、table相关 3、完善/重载string库 4、Log相关 5、number相关 6、C函数重载 7、编码
-- 8、Event相关 9、界面辅助 10、model Outline 11、game money 12、TargetFace 13、hatstyle
-- 14、ModelShadow 15、时间相关 16、MobileStreaming 17、环境相关 18、其他
-------------------------------------------------------

local srep = string.rep
local tconcat = table.concat
local tinsert = table.insert
local tremove = table.remove
local type = type
local next = next
local print = print
local pairs = pairs
local ipairs = ipairs
local tostring = tostring
local string2byte = string.byte
local FACE_ONCE_SEND_MAX_COUNT = 10
local tLockCharacter = {}

------------------------客户端属性-----------------------------
function IsDebugClient()
    return (EnableDebugEnv ~= nil) or (g_tbLoginData and g_tbLoginData.bIsDevelop)
end

-- 公用脚本函数
-- 函数名：Is4KScreen
-- 函数描述：判断玩家当前显示器是否是4K屏幕
-- 参数列表：无
-- 返回值： 是否是4K屏
-- 备注：
-- 示例：

function Is4KScreen()
    local nScreenX, nScreenY = GetSystemCScreen()
    return nScreenX >= 3840
end

-- 公用脚本函数
-- 函数名 :IsVersionExp
-- 函数描述 : 当前客户端是否是体服
-- 参数列表 :
-- 返回值 :true或者false，是否体服
-- 备注 :
-- 示例 :
function IsVersionExp()
    local _, _, szVersionLineName, szVersionType = GetVersion()
    local szExp = GetVersionExp()
    if szVersionLineName == "zhcn" and szVersionType == szExp then
        return true
    end

    return false
end

function IsVersionTW()
    local _, _, szVersionLineName = GetVersion()
    if szVersionLineName == "zhtw" then
        return true
    end
    return false
end
--------------------end---------------------------------------

------------------------table相关-----------------------------
function clone(var, full)
    local szType = type(var)
    if szType == "nil"
            or szType == "boolean"
            or szType == "number"
            or szType == "string"
            or szType == "function" then
        return var
    elseif szType == "table" then
        local t = {}
        for key, val in pairs(var) do
            key = clone(key)
            val = clone(val)
            t[key] = val
        end
        if full then
            setmetatable(t, clone(debug.getmetatable(var)))
        end
        return t
    elseif full then
        return var
    end
    return nil
end

function empty(var)
    local szType = type(var)
    if szType == "nil" then
        return true
    elseif szType == "boolean" then
        return var
    elseif szType == "number" then
        return var == 0
    elseif szType == "string" then
        return var == ""
    elseif szType == "function" then
        return false
    elseif szType == "table" then
        for _, _ in pairs(var) do
            return false
        end
        return true
    else
        return false
    end
end

-- 公用脚本函数
-- 函数名 :table_is_empty
-- 函数描述 : 判断table是否是空表
-- 参数列表 : t:table
-- 返回值 :true或者false
-- 备注 :
-- 示例 :
function table_is_empty(t)
    return _G.next(t) == nil
end

function GetTableCount(table)
    local nCount = 0
    if not table then
        return nCount
    end
    for k, v in pairs(table) do
        nCount = nCount + 1
    end
    return nCount
end

-- 公用脚本函数
-- 函数名 :IsTableEqual
-- 函数描述 : 判断2个简单table的内容是否相等
-- 参数列表 : t1:表格1
--           t2:表格2
-- 返回值 :true或者false
-- 备注 :
-- 示例 :
function IsTableEqual(t1, t2)
    if type(t1) ~= "table" or type(t2) ~= "table" then
        return false
    end
    local tKeyList = {}
    for k, v in pairs(t1) do
        local szType = type(v)
        if (szType == "table" and not IsTableEqual(v, t2[k]))
                or (szType ~= "table" and v ~= t2[k]) then
            return false
        end
        tKeyList[k] = true
    end

    -- 补充t1为t2真子集的情况
    for k, _ in pairs(t2) do
        if not tKeyList[k] then
            return false
        end
    end
    return true
end

-- 返回tTable中任意等于给定value的元素的key
function FindTableValue(tTable, value)
    if (not tTable) or (not value) or (not (type(tTable) == "table")) then
        return nil
    end

    local l_fnCmp
    if type(value) == "table" then
        l_fnCmp = IsTableEqual
    else
        l_fnCmp = function(v1, v2)
            return v1 == v2
        end
    end

    for k, v in pairs(tTable) do
        if l_fnCmp(v, value) then
            return k
        end
    end
    return nil
end

function CheckIsInTable(tTable, value)
    return FindTableValue(tTable, value) ~= nil
end

-- find a table entry tEntry in tTable so that tEntry[key] == value
function FindTableValueByKey(tTable, key, value)
    if (not tTable) or (not key) or (value == nil) or (type(tTable) ~= "table") then
        return
    end

    local l_fnCmp
    if type(value) == "table" then
        l_fnCmp = IsTableEqual
    else
        l_fnCmp = function(v1, v2)
            return v1 == v2
        end
    end

    for k, tEntry in pairs(tTable) do
        if type(tEntry) == "table" and l_fnCmp(tEntry[key], value) then
            return tEntry, k
        end
    end
    return nil
end

function AppendWhenNotExist(aList, elem)
    if not CheckIsInTable(aList, elem) then
        table.insert(aList, elem)
    end
end

IsTableEmpty = table_is_empty
IsEmpty = table_is_empty

-- 公用脚本函数
-- 函数名 :ClearTable
-- 函数描述 : 清空Table的内容，针对变量形式的大table的子table、需重复利用它时有用
-- 参数列表 : t
-- 返回值 :true或者false
-- 备注 :
-- 示例 :
function ClearTable(t)
    if type(t) ~= "table" then
        return false
    end
    local tKeyList = {}
    for k in pairs(t) do
        t[k] = nil
    end
    return true
end

local function table_r(var, level, indent, skipFunction)
    local t = {}
    local szType = type(var)
    if szType == "nil" then
        tinsert(t, "nil")
    elseif szType == "number" then
        tinsert(t, tostring(var))
    elseif szType == "string" then
        tinsert(t, string.format("%q", var))
    elseif szType == "function" then
        if not skipFunction then
            local s = string.dump(var)
            tinsert(t, 'loadstring("')
            -- "string slice too long"
            for i = 1, #s, 2000 do
                tinsert(t, tconcat({ '', string2byte(s, i, i + 2000 - 1) }, "\\"))
            end
            tinsert(t, '")')
        end
    elseif szType == "boolean" then
        tinsert(t, tostring(var))
    elseif szType == "table" then
        tinsert(t, "{")
        local s_tab_equ = "="
        if indent then
            s_tab_equ = " = "
            if not empty(var) then
                tinsert(t, "\n")
            end
        end
        local nohash = true
        local key, val, lastkey, lastval, hasval
        local tlist, thash = {}, {}
        repeat
            key, val = next(var, lastkey)
            if key then
                -- judge if this is a pure list table
                if nohash and (
                        type(key) ~= "number"
                                or (lastval == nil and key ~= 1) -- first loop and index is not 1 : hash table
                                or (lastkey and lastkey + 1 ~= key)
                ) then
                    nohash = false
                end

                if type(val) ~= "function" or not skipFunction then
                    -- process to insert to table
                    -- insert indent
                    if indent then
                        tinsert(t, srep(indent, level + 1))
                    end
                    -- insert key
                    if nohash then
                        -- pure list: do not need a key
                    elseif type(key) == "string" and key:find("^[a-zA-Z_][a-zA-Z0-9_]*$") then
                        -- a = val
                        tinsert(t, key)
                        tinsert(t, s_tab_equ)
                    else
                        -- [10010] = val -- [".start with or contains special char"] = val
                        tinsert(t, "[")
                        tinsert(t, table_r(key, level + 1, indent, skipFunction))
                        tinsert(t, "]")
                        tinsert(t, s_tab_equ)
                    end
                    -- insert value
                    tinsert(t, table_r(val, level + 1, indent, skipFunction))
                    tinsert(t, ",")
                    if indent then
                        tinsert(t, "\n")
                    end
                end

                lastkey, lastval, hasval = key, val, true
            end
        until not key
        -- remove last `,` if no indent
        if not indent and hasval then
            tremove(t)
        end
        -- insert `}` with indent
        if indent and not empty(var) then
            tinsert(t, srep(indent, level))
        end
        tinsert(t, "}")
    else
        --if (szType == "userdata") then
        tinsert(t, '"')
        tinsert(t, tostring(var))
        tinsert(t, '"')
    end
    return tconcat(t)
end

--[[--
	自定义迭代器
 ]]
function custom_pairs(tbl, func)
    if func == nil then
        return pairs(tbl)
    end

    -- 为tbl创建一个对key排序的数组
    -- 自己实现插入排序，table.sort遇到nil时会失效
    local ary = {}
    local lastUsed = 0
    for key --[[, val--]] in pairs(tbl) do
        if (lastUsed == 0) then
            ary[1] = key
        else
            local done = false
            for j = 1, lastUsed do
                -- 进行插入排序
                if (func(key, ary[j]) == true) then
                    table.insert(ary, j, key)
                    done = true
                    break
                end
            end
            if (done == false) then
                ary[lastUsed + 1] = key
            end
        end
        lastUsed = lastUsed + 1
    end

    -- 定义并返回迭代器
    local i = 0
    local iter = function()
        i = i + 1
        if ary[i] == nil then
            return nil
        else
            return ary[i], tbl[ary[i]]
        end
    end
    return iter
end

--[[--
	判断table里面是否有这个值
 ]]
function DectTableValue(T, value)
    if type(T) ~= "table" then
        return
    end

    for _, v in pairs(T) do
        if value == v then
            return true
        end
    end
    return false
end

--[[--
	根据Value移除table中元素
 ]]
function RemoveTableValue(T, value)
    if type(T) ~= "table" then
        return
    end
    for i, v in pairs(T) do
        if v == value then
            table.remove(T, i)
        end
    end
end

--[[
	将表B中元素按顺序添加至表A中
]]

function AppendTable(tA, tB)
	if type(tA) ~= "table" or type(tB) ~= "table" then
		return
	end
	for _, v in pairs(tB) do
		table.insert(tA, v)
	end
end

--[[--
	移除，默认是移除最后一个元素
	pos,元素位置
 ]]
function table.RemoveByPos(T, value, pos)
    if not pos then
        table.remove(T, value)
    end

    if type(T) ~= "table" then
        return
    end

    for i, v in pairs(T) do
        if v == value then
            table.remove(T, i)
        end
    end
end


--[[--
	获取table中元素总数
 ]]
function table.GetCount(T)
    if type(T) ~= "table" then
        return 0
    end
    local count = 0;
    for _, v in pairs(T) do
        if v then
            count = count + 1;
        end
    end
    return count;
end

--[[--
	获取table中元素总数
 ]]
function table.AddRange(tbA, tbB)
    local tb = {};
    for _, v in pairs(tbA) do
        if not DectTableValue(tb, v) then
            table.insert(tb, v);
        end
    end

    for _, v in pairs(tbB) do
        if not DectTableValue(tb, v) then
            table.insert(tb, v);
        end
    end
    return tb;
end
--------------------end----------------------------------------------

------------------------完善/重载string库-----------------------------
function string.escape(s)
    return (s:gsub('([%(%)%.%%%+%-%*%?%[%^%$%]])', '%%%1'))
end

function string.trim(s, s1)
    s1 = s1 and s1:escape() or "%s"
    return (s:gsub("^[" .. s1 .. "]*(.-)[" .. s1 .. "]*$", "%1"))
end

--跟Lib.lua里的string.split冲突了，先注释掉（而且StringFindW是在KGUI里的用不了 2022.11.23 by luwenhao1
-- function string.split(szFull, szSep, bIgnoreEmpty) -- 从HM抄来的
-- 	local nOff, tResult = 1, {}
-- 	if szSep then
-- 		while true do
-- 			local nEnd = StringFindW(szFull, szSep, nOff)
-- 			if not nEnd then
-- 				tinsert(tResult, string.sub(szFull, nOff, string.len(szFull)))
-- 				break
-- 			else
-- 				tinsert(tResult, string.sub(szFull, nOff, nEnd - 1))
-- 				nOff = nEnd + string.len(szSep)
-- 			end
-- 		end
-- 	else
-- 		local nLen = wstring.len(szFull)
-- 		for i = 1, nLen do
-- 			tinsert(tResult, wstring.sub(szFull, i, i))
-- 		end
-- 	end
-- 	if bIgnoreEmpty then
-- 		for i, v in ipairs_r(tResult) do
-- 			if v == "" then
-- 				tremove(tResult, i)
-- 			end
-- 		end
-- 	end
-- 	return tResult
-- end

local m_simpleMatchCache = setmetatable({}, { __mode = "v" })
function string.simpleMatch(szText, szFind, bDistinctCase, bDistinctEnEm, bIgnoreSpace)
    if not bDistinctCase then
        szFind = StringLowerW(szFind)
        szText = StringLowerW(szText)
    end
    if not bDistinctEnEm then
        szText = StringEnerW(szText)
    end
    if bIgnoreSpace then
        szFind = StringReplaceW(szFind, ' ', '')
        szFind = StringReplaceW(szFind, g_tStrings.STR_ONE_CHINESE_SPACE, '')
        szText = StringReplaceW(szText, ' ', '')
        szText = StringReplaceW(szText, g_tStrings.STR_ONE_CHINESE_SPACE, '')
    end
    local me = GetClientPlayer()
    if me then
        szFind = szFind:gsub('$zj', me.szName)
        local szTongName = ''
        local tong = GetTongClient()
        if tong and me.dwTongID ~= 0 then
            szTongName = tong.ApplyGetTongName(me.dwTongID) or ''
        end
        szFind = szFind:gsub('$bh', szTongName)
        szFind = szFind:gsub('$gh', szTongName)
    end
    local tFind = m_simpleMatchCache[szFind]
    if not tFind then
        tFind = {}
        for _, szKeyWordsLine in ipairs(szFind:split(';', true)) do
            local tKeyWordsLine = {}
            for _, szKeyWords in ipairs(szKeyWordsLine:split(',', true)) do
                local tKeyWords = {}
                for _, szKeyWord in ipairs(szKeyWords:split('|', true)) do
                    local bNegative = szKeyWord:sub(1, 1) == '!'
                    if bNegative then
                        szKeyWord = szKeyWord:sub(2)
                    end
                    if not bDistinctEnEm then
                        szKeyWord = StringEnerW(szKeyWord)
                    end
                    tinsert(tKeyWords, { szKeyWord = szKeyWord, bNegative = bNegative })
                end
                tinsert(tKeyWordsLine, tKeyWords)
            end
            tinsert(tFind, tKeyWordsLine)
        end
        m_simpleMatchCache[szFind] = tFind
    end
    -- 10|十人,血战天策|XZTC,!小铁被吃了,!开宴黑铁;大战
    local bKeyWordsLine = false
    for _, tKeyWordsLine in ipairs(tFind) do
        -- 符合一个即可
        -- 10|十人,血战天策|XZTC,!小铁被吃了,!开宴黑铁
        local bKeyWords = true
        for _, tKeyWords in ipairs(tKeyWordsLine) do
            -- 必须全部符合
            -- 10|十人
            local bKeyWord = false
            for _, info in ipairs(tKeyWords) do
                -- 符合一个即可
                -- szKeyword = MY.String.PatternEscape(szKeyword) -- 用了wstring还Escape个捷豹
                if info.bNegative then
                    -- !小铁被吃了
                    if not wstring.find(szText, info.szKeyWord) then
                        bKeyWord = true
                    end
                else
                    -- 十人   -- 10
                    if wstring.find(szText, info.szKeyWord) then
                        bKeyWord = true
                    end
                end
                if bKeyWord then
                    break
                end
            end
            bKeyWords = bKeyWords and bKeyWord
            if not bKeyWords then
                break
            end
        end
        bKeyWordsLine = bKeyWordsLine or bKeyWords
        if bKeyWordsLine then
            break
        end
    end
    return bKeyWordsLine
end

-- 只读表创建
function SetmetaReadonly(t)
    for k, v in pairs(t) do
        if type(v) == 'table' then
            t[k] = SetmetaReadonly(v)
        end
    end
    return setmetatable({}, {
        __index = t,
        __newindex = function()
            assert(false, 'table is readonly\n')
        end,
        __metatable = {
            const_table = t,
        },
    })
end
-- 只读表字典枚举
function pairs_c(t, ...)
    if type(t) == "table" then
        local metatable = getmetatable(t)
        if type(metatable) == "table" and metatable.const_table then
            return pairs(metatable.const_table, ...)
        end
    end
    return pairs(t, ...)
end
-- 只读表数组枚举
function ipairs_c(t, ...)
    if type(t) == "table" then
        local metatable = getmetatable(t)
        if type(metatable) == "table" and metatable.const_table then
            return ipairs(metatable.const_table, ...)
        end
    end
    return ipairs(t, ...)
end
-- 只读表数组部分长度
function count_c(t)
    if type(t) == "table" then
        local metatable = getmetatable(t)
        if type(metatable) == "table" and metatable.const_table then
            return #metatable.const_table
        end
    end
    return #t
end

-- 选代器 倒序
local function fnBpairs(tab, nIndex)
    nIndex = nIndex - 1
    if nIndex > 0 then
        return nIndex, tab[nIndex]
    end
end

function ipairs_r(tab)
    return fnBpairs, tab, #tab + 1
end

function SplitString(szText, szSeparators)
    local nStart = 1
    local nLen = #szText
    local tResult = {}
    while nStart <= nLen do
        local nSt, nEnd = string.find(szText, szSeparators, nStart)
        if nSt and nEnd then
            local szResult = string.sub(szText, nStart, nSt - 1)
            table.insert(tResult, szResult)
            nStart = nEnd + 1
        else
            if nStart <= nLen then
                local szResult = string.sub(szText, nStart, nLen)
                table.insert(tResult, szResult)
            end
            nStart = nLen + 1
        end
    end
    return tResult
end

function var2str(var, indent, level, skipFunction)
    return table_r(var, level or 0, indent, skipFunction)
end

do
    local envmeta
    function str2var(str, env, hasRet)
        if not envmeta then
            local constenv = {}
            for _, name in ipairs(LUA_CONST_LIST) do
                constenv[name] = _G[name]
            end
            envmeta = { __index = constenv }
        end
        if type(str) ~= "string" then
            xpcall(
			function() LOG.ERROR('[LOADSTRING ERROR]bad argument #1 to str2var, string expected, got ' .. type(str) .. '.') end,
			function(err)
				LOG.ERROR(debug.traceback("str2var not string Error"))
			end)
            return
        end
        local fn = hasRet and loadstring(str) or loadstring("return " .. str)
        if not hasRet and not fn then
            fn = loadstring(str)
        end
        if not fn then
            xpcall(
			function() LOG.ERROR('[LOADSTRING ERROR]failed on decoding #1 of str2var, plain text is: ' .. str) end,
			function(err)
				LOG.ERROR(debug.traceback("str2var not fn Error"))
			end)

            return
        end
        local env, datalist = env or {}
        setmetatable(env, envmeta)
        setfenv(fn, env)
        datalist = { pcall(fn) }
        setmetatable(env, nil)
        if datalist[1] then
            tremove(datalist, 1)
        else
            xpcall(
            function() LOG.ERROR('[CALL ERROR]str2var("' .. str .. '"): \nERROR:' .. datalist[2]) end,
            function(err)
                LOG.ERROR(debug.traceback("str2var remove Error"))
            end)
        end
        return unpack(datalist)
    end
end

-- 公用脚本函数
-- 函数名 :StringParse_IDList
-- 函数描述 :将指定格式的字符串解析成一个ID列表
-- 参数列表 : szTime:时间字符串
-- 返回值 :ID的table
-- 备注 : 格式：1;2;3;
-- 示例 :
function StringParse_IDList(szList)
    -- x;y;z
    local tList = {}
    for s in string.gmatch(szList, "%d+") do
        local dwID = tonumber(s)
        if dwID then
            table.insert(tList, dwID)
        end
    end
    return tList
end

function StringParse_PointList(szPoint)
    local tList = {}
    for szIndex in string.gmatch(szPoint, "([%d-]+)") do
        local nPoint = tonumber(szIndex)
        table.insert(tList, nPoint)
    end
    return tList
end
--------------end------------------------------------------------------------------------

--------------Log相关--------------------------------------------------------------------
function JustLog_New(...)
    local szMsg = LuaTableToString({ ... })
    if Log then
        Log("[UI DEBUG]" .. szMsg)
    end
end

function JustLog(...)
    local argv = { ... }
    local argc = select("#", ...)

    local t = {}
    table.insert(t, "{")
    if argc > 0 then
        table.insert(t, "\n")
        for i = 1, argc do
            table.insert(t, "\t[")
            table.insert(t, i)
            table.insert(t, "] = ")
            table.insert(t, var2str(argv[i], "\t", 1))
            table.insert(t, ",\n")
        end
    end
    table.insert(t, "}")

    local szMsg = table.concat(t)
    if Log then
        Log("[UI DEBUG]" .. szMsg)
    end
end

function UILog_New(...)
    local szMsg = LuaTableToString({ ... })
    if Log then
        Log("[UI DEBUG]" .. szMsg)
    end
    if OutputMessage and IsDebugClient() then
        OutputMessage("MSG_SYS", 'New Debug Client Log.\n')
        OutputMessage("MSG_SYS", "\n" .. szMsg .. '\n')
    end
end

function UILog(...)
    local argv = { ... }
    local argc = select("#", ...)

    local t = {}
    table.insert(t, "{")
    if argc > 0 then
        table.insert(t, "\n")
        for i = 1, argc do
            table.insert(t, "\t[")
            table.insert(t, i)
            table.insert(t, "] = ")
            table.insert(t, var2str(argv[i], "\t", 1))
            table.insert(t, ",\n")
        end
    end
    table.insert(t, "}")

    local szMsg = table.concat(t)
    if Log then
        Log("[UI DEBUG]" .. szMsg)
    end
    -- if OutputMessage and IsDebugClient() then
    --     OutputMessage("MSG_SYS", 'The Message is Only Shown in Debug Client.\n')
    --     OutputMessage("MSG_SYS", szMsg .. '\n')
    -- end
end

UILog_Dev = UILog
UILog_Dev2 = JustLog

local oriLog = Log
local _fhs = {}
function Log(...)
    if select("#", ...) == 1 then
        return oriLog(...)
    else
        local szPath = select(1, ...)
        local szText = select(2, ...)
        local szPara = select(3, ...) or ""
        if type(szPath) ~= "string" then
            return "PARAM MISMATCH"
        end
        if szText == false then
            if _fhs[szPath] then
                io.close(_fhs[szPath])
                _fhs[szPath] = nil
            end
            return "SUCCEED"
        elseif type(szText) ~= "string" then
            return "PARAM MISMATCH"
        end

        szPath = szPath:gsub("\\", "/"):gsub("^/+", ""):gsub("/%s*%.%.%s*/", "/")
        local szPathL = StringLowerW(szPath)
        if (
                not szPathL:find("%.md$")
                        and not szPathL:find("%.txt$")
                        and not szPathL:find("%.csv$")
                        and not szPathL:find("%.xml$")
                        and not szPathL:find("%.log$")
                        and not szPathL:find("%.js$")
                        and not szPathL:find("%.css$")
                        and not szPathL:find("%.html$")
                        and not szPathL:find("%.json$")
        ) or (
                not szPathL:find("^interface/")
                        and not szPathL:find("^userdata/")
                        and not szPathL:find("^logs/")
                        and not szPathL:find("^/interface/")
                        and not szPathL:find("^/userdata/")
                        and not szPathL:find("^/logs/")
                        and not szPathL:find("^./interface/")
                        and not szPathL:find("^./userdata/")
                        and not szPathL:find("^./logs/")
        ) then
            return "PATH FORBIDDEN"
        end
        CPath.MakeDir(szPath:gsub("/[^/]*$", "") .. "/")

        szPath = ConvertCodePage(szPath, GetGameCodePage(), CODE_PAGE.ACP)
        local f = _fhs[szPath]
        if szPara:find("clear") then
            if f then
                io.close(f)
            end
            _fhs[szPath] = io.open(szPath, "w")
        elseif not f then
            _fhs[szPath] = io.open(szPath, "a")
        end
        f = _fhs[szPath]
        if f then
            f:write(szText)
            if szPara:find("close") then
                io.close(f)
                _fhs[szPath] = nil
            end
            return "SUCCEED"
        else
            return "ERROR OPEN FILE"
        end
    end
end

local _bOpenOutput = true
function SetOutputFlag(bFlag)
    _bOpenOutput = bFlag
end

function Output(...)
    if not _bOpenOutput then
        return
    end
    local argv = { ... }
    local argc = select("#", ...)

    local t = {}
    table.insert(t, "{")
    if argc > 0 then
        table.insert(t, "\n")
        for i = 1, argc do
            table.insert(t, "\t[")
            table.insert(t, i)
            table.insert(t, "] = ")
            table.insert(t, var2str(argv[i], "\t", 1))
            table.insert(t, ",\n")
        end
    end
    table.insert(t, "}")

    local szMsg = table.concat(t)
    if Log then
        Log("[UI DEBUG]" .. szMsg)
    end
    if OutputMessage then
        OutputMessage("MSG_SYS", szMsg .. '\n')
    end
    print(szMsg)
end

if IsDebugClient() then
    -- 测试用
    RegisterEvent("CALL_LUA_ERROR", function()
        Log(arg0)
        -- print(arg0)  -- KGUI::Exit流程中SO3World已经析构，这时候print会导致宕机，需谨慎使用
        if OutputMessage then
            OutputMessage("MSG_SYS", arg0)
        end
    end)
end
--------------end--------------------------------------------------------------------

--------------number相关-------------------------------------------------------------
function KeepOneByteFloat(f)
    return string.format("%g", string.format("%.1f", f))
end

function KeepTwoByteFloat(f)
    return string.format("%g", string.format("%.2f", f))
end

function FixFloat(fNum, nEPS)
    if not nEPS then
        nEPS = 0
    end
    assert(nEPS >= 0)
    return string.format("%g", string.format("%." .. nEPS .. "f", fNum))
end

function KeepDecimalPoint(value, n)
    if n < 0 then
        return value
    end

    local power = 10 ^ n
    return math.floor(value * power) / power;
end

function GetIntergerBit(nNumber)
    local fBit = math.log10(nNumber)
    local nLargest = math.floor(fBit)
    return nLargest + 1
end

function RangeNumber(Number, Min, Max)
    Number = math.min(Number, Max)
    Number = math.max(Number, Min)

    return Number
end

function GetRoundedNumber(fNum, nDecimal)
    --- 四舍五入
    nDecimal = nDecimal or 0
    nDecimal = math.max(nDecimal, 0)
    local nTimes = math.pow(10, nDecimal)
    return math.floor(fNum * nTimes + 0.5) / nTimes
end

function NumberToArray(fNumber, nEPS)
    if fNumber == 0 then
        return { 0 }
    end
    local bSign = fNumber > 0
    local fPoint = fNumber - math.floor(fNumber)
    local fNumber = math.floor(fNumber)
    local tArray = {}
    while fNumber > 0 do
        local i = fNumber % 10
        fNumber = math.floor(fNumber / 10)
        table.insert(tArray, i)
    end

    if not bSign then
        table.insert(tArray, "-")
    end
    local tPoint
    if nEPS and nEPS > 0 then
        tPoint = {}
        for i = 1, nEPS do
            local nPoint = ((fPoint * 10) % 10)
            fPoint = fPoint / 10
            table.insert(tPoint, nPoint)
        end
    end
    return tArray, tPoint
end

function GetPercent(a, b)
    if b == 0 then
        return 1
    else
        return a / b
    end
end

--- 得到数字区间 [nLowerBound, nUpperBound] 被打乱后的版本
function GetShuffledRange(nLowerBound, nUpperBound)
    nLowerBound, nUpperBound = math.min(nLowerBound, nUpperBound), math.max(nLowerBound, nUpperBound)

    math.randomseed(os.time())
    local aResList = {}
    for i = nLowerBound, nUpperBound do
        table.insert(aResList, i)
    end
    local nTmp, nTargetIndex
    local nCount = nUpperBound - nLowerBound + 1
    for j = 1, nCount do
        nTargetIndex = math.random(1, nCount)
        nTmp = aResList[j]
        aResList[j] = aResList[nTargetIndex]
        aResList[nTargetIndex] = nTmp
    end
    return aResList
end
--------------end--------------------------------------------------------------------

--------------C函数重载---------------------------------------------------------------
do
    local _rlcmd = rlcmd
    function rlcmd(...)
        --FireUIEvent("ON_RLCMD", ...)
        _rlcmd(...)
    end
end
--------------end--------------------------------------------------------------------

--------------编码-------------------------------------------------------------------
function gamecode_to_utf8(content)
    --gamecode 游戏内编码
    local nCodePage = GetGameCodePage()
    if nCodePage ~= CODE_PAGE.UTF8 then
        return ConvertCodePage(content, nCodePage, CODE_PAGE.UTF8);
    end
    return content
end

function utf8_to_gamecode(content)
    local nCodePage = GetGameCodePage()
    if nCodePage ~= CODE_PAGE.UTF8 then
        return ConvertCodePage(content, CODE_PAGE.UTF8, nCodePage);
    end
    return content
end
--------------end--------------------------------------------------------------------

--------------Event相关--------------------------------------------------------------
local function FireAddOnEvent(szEvent)
    FireEnvEvent(szEvent, 0, true)
end

function FireEvent(szEvent, ...)
    Event.Dispatch(szEvent, ...)
end

function FireUIEvent(szEvent, ...)
    local _TemporaryG = {}
    local l_max_argc = 10 -- protect 10 global arguments as default
    for i = 0, l_max_argc - 1 do
        _TemporaryG[i] = _G["arg" .. i]
		_G["arg" .. i] = nil
	end
    Event.Dispatch(szEvent, ...)
    for i = 0, l_max_argc - 1 do
		_G["arg" .. i] = _TemporaryG[i]
	end
end

function FireAddonUIEvent(szEvent, ...)
    Event.Dispatch(szEvent, ...)
end

function FireInUIEvent(szEvent, ...)
    Event.Dispatch(szEvent, ...)
end
--------------end--------------------------------------------------------------------

--------------------界面辅助---------------------------------------------------------------
--do
--local bOpened = IsUIEditorOpened()
--
---- if IsDebugClient() or bOpened or OpenUIEditor(true) then
----    if not bOpened then
----        CloseUIEditor()
----    end
--
--	local function IsAppKey(nKey)
--		return nKey == 0x5D
--	end
--
--	local function OnResponseSepcialKey(szEvent)
--		local nKey, bDown = arg0, arg1
--		if IsAppKey(nKey) then
--			local x, y = Cursor.GetPos()
--			local szTip = ""
--			local szItemPath, szFrameName = "", ""
--
--			if bDown then
--				if IsCtrlKeyDown() and IsAltKeyDown() then
--					if IsUIEditorOpened() then
--						CloseUIEditor()
--					else
--						OpenUIEditor(true)
--					end
--					return 1
--				end
--
--				DelayCall("item debug", false)
--				local frame, parent, bWndParent
--				local wnd, item  = Station.GetMouseOverWindow(IsAltKeyDown())
--				if wnd then
--					frame = wnd:GetRoot()
--				end
--				if item then
--					parent = item:GetParent()
--
--				end
--
--				if not parent and wnd then
--					parent = wnd:GetParent()
--					bWndParent = true
--				end
--
--				local bDebug = IsDebugClient()
--
--				if frame then
--					szFrameName = frame:GetName()
--					szTip = szTip .. GetFormatText(string.format("%s\n", frame:GetName()), nil, 255,125,0)
--					if bDebug then
--						szTip = szTip .. GetFormatText(string.format("layer: %s\nabs_pos: %-4d, %-4d\nrel_pos  : %-4d, %-4d\n\n", frame:GetParent():GetName(), frame:GetAbsX(), frame:GetAbsY(), frame:GetRelX(), frame:GetRelY()))
--					end
--				end
--
--				if bWndParent and parent ~= wnd and parent ~= frame then
--					szTip = szTip .. GetFormatText("parent: ") .. GetFormatText(string.format("%s\n", parent:GetName()), nil, 255,255,0)
--					if bDebug then
--						szTip = szTip .. GetFormatText(string.format("type: %s\nabs_pos: %-4d, %-4d\nrel_pos  : %-4d, %-4d\n\n", parent:GetType(), parent:GetAbsX(), parent:GetAbsY(), parent:GetRelX(), parent:GetRelY()))
--					end
--				end
--
--				if wnd and frame ~= wnd then
--					szItemPath = select(1, wnd:GetTreePath())
--					szTip = szTip .. GetFormatText("wnd: ") .. GetFormatText(string.format("%s\n", wnd:GetName()), nil, 255,255,0)
--					if bDebug then
--						szTip = szTip .. GetFormatText(string.format("type: %s\nabs_pos: %-4d, %-4d\nrel_pos  : %-4d, %-4d\n", wnd:GetType(), wnd:GetAbsX(), wnd:GetAbsY(), wnd:GetRelX(), wnd:GetRelY()))
--						szTip = szTip .. GetFormatText(select(1, wnd:GetTreePath()) .. "\n\n")
--					end
--				end
--
--				if not bWndParent and parent and parent ~= wnd and parent ~= item  and parent ~= frame then
--					szTip = szTip .. GetFormatText("parent: ") .. GetFormatText(string.format("%s\n", parent:GetName()), nil, 255,255,0)
--					if bDebug then
--						szTip = szTip .. GetFormatText(string.format("type: %s\nabs_pos: %-4d, %-4d\nrel_pos  : %-4d, %-4d\n\n", parent:GetType(), parent:GetAbsX(), parent:GetAbsY(), parent:GetRelX(), parent:GetRelY()))
--					end
--				end
--
--				if item and item ~= wnd then
--					szItemPath = table.concat({item:GetTreePath()}, "|")
--					szTip = szTip .. GetFormatText("item: ") .. GetFormatText(string.format("%s\n", item:GetName()), nil, 255,255,0)
--					if bDebug then
--						szTip = szTip .. GetFormatText(string.format("type: %s\nabs_pos: %-4d, %-4d\nrel_pos  : %-4d, %-4d\n", item:GetType(), item:GetAbsX(), item:GetAbsY(), item:GetRelX(), item:GetRelY()))
--						if item:GetType() == "Image" then
--							szTip = szTip .. GetFormatText(string.format("imagepath: %s\nimageframe：%d\n", item:GetImagePath(), item:GetFrame()))
--						elseif item:GetType() == "Box" and not item:IsEmpty() then
--							local szText = string.format("BoxIconID: %d\n IconPath：%s\n", item:GetObjectIcon(), item:GetObjectIconPath())
--							szTip = szTip .. GetFormatText(szText)
--						end
--						szTip = szTip .. GetFormatText(table.concat({item:GetTreePath()}, " => ") .. "\n\n")
--					end
--				end
--
--				local frameTip = OutputTip(szTip, 250, {x, y, 30, 30},nil, true, "item debug", nil, nil, nil, nil, nil, nil, nil, true)
--
--				if szFrameName then
--					frameTip.__szItemDebugName = szFrameName
--				end
--
--				if szItemPath then
--					frameTip.__szItemDebugPath = string.gsub(szItemPath, "/|", "|", 1)
--				end
--
--				Station.SetFocusWindow(frameTip)
--				frameTip:ChangeRelation("Topmost1")
--				return 1
--			else
--				DelayCall("item debug", 10000, CloseLinkTipPanel)
--				return 1
--			end
--		end
--	end
--
--	if g_nDbgOnRSK then
--		g_nDbgOnRSK = UnRegisterEvent("SPECIAL_KEY_MSG", g_nDbgOnRSK)
--	end
--	g_nDbgOnRSK = RegisterEvent("SPECIAL_KEY_MSG", OnResponseSepcialKey)
---- end
--
--end
--
--local g_szInputModule, g_InputUserData
--function SetInputModule(szModule, UserData)
--	g_szInputModule, g_InputUserData = szModule, UserData
--end
--
--function GetInputModule()
--	return g_szInputModule, g_InputUserData
--end
--
---- 公用脚本函数
---- 函数名: AdjustImageSizeByItemHeight
---- 函数描述: 图片尺寸根据控件高度自适应
---- 参数列表: hImage：图片所在的控件
---- 返回值： 无
---- 备注:
---- 示例: AdjustImageSizeByItemHeight(hName)
--function AdjustImageSizeByItemHeight(hImage)
--	local nItemH = hImage:GetH()
--	hImage:AutoSize()
--	local nImageW, nImageH = hImage:GetSize()
--	local nAutoW = nImageW * nItemH / nImageH
--	hImage:SetSize(nAutoW, nItemH)
--end
--
--function UIScaleCorrector()
--	--加上UI缩放系数矫正，保证在各个分辨率下图素大小合适
--   local nScreenX, nScreenY = GetSystemCScreen()
--   local nUIScaleCorrection = 1.0
--   if nScreenX >= 1920 then
--	   nUIScaleCorrection = (1.0 - 0.1 * ((nScreenX - 1920) / 1920)) --这个计算公式？？？！！！
--   end
--
--   return nUIScaleCorrection
--end
--
---- 公用脚本函数
---- 函数名 :UI_GetObject
---- 函数描述 : 通过给定的路径查找UI组件
---- 参数列表 :
---- 返回值 :szRoute路径
---- 备注 :
---- 示例 :UI_GetObject("Normal/TopMenu/WndContainer_List/Wnd_Daily/Btn_Daily")
--
--function UI_GetObject(szRoute)
--   local dwSt = string.find(szRoute, "|")
--   if dwSt and dwSt > 1 then
--	   local szWndRoute = string.sub(szRoute, 1, dwSt - 1 )
--	   local szHandRoute = string.sub(szRoute, dwSt + 1)
--	   local hHandle = Station.Lookup(szWndRoute,szHandRoute)
--	   return hHandle
--   else
--	   local hWnd = Station.Lookup(szRoute)
--	   return hWnd
--   end
--   return nil
--end
--
--Helper_GetUIObject = UI_GetObject
--
----增加部分Station显示模式的接口
----为什么不在C++里面实现这些功能?我的设计思想如下：C++的接口尽量保持单一功能原则，这样可以给脚本调用提供更高的自由度，改起来也更方便
--function Station.EnterShowMode(szName)
--	if not szName or szName == "" then
--		return false
--	end
--	local szOldName = Station.GetNameOfCurShowMode()
--	if szOldName ~= szName then
--		Station.SetCurrentShowModeByName(szName)
--		if Station.IsVisible() then
--			Station.Hide()
--		end
--	end
--end
--
----如果历史记录里面存在模式就回退到上一种模式，如果没有就直接退出界面组合显示模式
--function Station.BackOrExitShowMode()
--	local nRetCode = Station.Back2SpecShowModeViaStep()
--
--	if not nRetCode then
--		Station.Show()
--	end
--	return true
--end
--
--function GetUIObjectByPath(hObject, szRoute)
--	local dwSt = string.find(szRoute, "|")
--	if dwSt and dwSt >= 1 then
--		local szWndRoute = string.sub(szRoute, 1, dwSt - 1 )
--		local szHandRoute = string.sub(szRoute, dwSt + 1)
--		local hHandle
--		if hObject then
--			hHandle = hObject:Lookup(szWndRoute, szHandRoute)
--		else
--			hHandle = Station.Lookup(szWndRoute, szHandRoute)
--		end
--		return hHandle
--	else
--		if hObject then
--			return hObject:Lookup(szRoute)
--		else
--			return Station.Lookup(szRoute)
--		end
--	end
--end
----------------end--------------------------------------------------------------------

---------------model Outline---------------------------------------------------------------
local _aLineColor = {
    green = { 160, 150, 255, 180, },
    red = { 160, 255, 40, 40, },
    yellow = { 160, 240, 240, 50, },
    blue = { 160, 50, 210, 214, },
}

local _aOutline = {
    [0] = _aLineColor.green, -- sortNone
    [1] = _aLineColor.green, -- sortSelf
    [2] = _aLineColor.green, -- sortAlly
    [3] = _aLineColor.red, -- sortFoe
    [4] = _aLineColor.red, -- sortEnemy
    [5] = _aLineColor.yellow, --sortNeutrality
    [6] = _aLineColor.blue, --sortParty
}
local _tNpcOutline = {}
local _tDoodadOutline = {}
local _tFurnitureOutline = {}

local function Outline_FadeOut(userdata)
    userdata.alpha = userdata.alpha + userdata.delta
    local argb = userdata.argb
    if userdata.delta >= 0 then
        userdata.alpha = math.min(userdata.alpha, argb[1])
        if userdata.alpha >= argb[1] then
            local nTime = GetCurrentTime()
            if nTime >= userdata.nCloseTime then
                userdata.delta = -25
            else
                userdata.delta = 0
            end
        end
    else
        userdata.alpha = math.max(userdata.alpha, 0)
    end

    local targetid = userdata.targetid;
    userdata.setoutline(targetid, userdata.border, userdata.alpha, argb[2], argb[3], argb[4])

    if userdata.alpha == 0 then
        if tLockCharacter[userdata.targetid] then
            tLockCharacter[userdata.targetid] = nil
        end
        userdata.setoutline(userdata.targetid, 0, 0, 0, 0, 0)
        userdata.targetid = nil
        return 0
    end
end

local function Outline_initdata(dwTargetID, tUserData, fnSetOutline, argb, pausetime, border)
    if tLockCharacter[dwTargetID] and not pausetime then
        return
    end
    if tUserData.targetid == dwTargetID then
        tUserData.alpha = 1
        tUserData.delta = 80
        tUserData.argb = argb
        tUserData.border = border or 1
        tUserData.nCloseTime = (pausetime or 0) + GetCurrentTime()
    else
        local dwOrgTargetID = tUserData.targetid

        tUserData.targetid = dwTargetID
        tUserData.alpha = 1
        tUserData.argb = argb
        tUserData.delta = 80
        tUserData.setoutline = fnSetOutline
        tUserData.border = border or 1
        tUserData.nCloseTime = (pausetime or 0) + GetCurrentTime()

        if dwOrgTargetID then
            fnSetOutline(dwOrgTargetID, 0, 0, 0, 0, 0)
        else
            Addon_FrameCall(2, Outline_FadeOut, tUserData)
        end
    end
end

function Character_ShowOutline(dwTargetID, pausetime, border, tArgb)
    if not Outline_IsVisible() then
        return
    end

    local src = dwTargetID
    local dest = UI_GetClientPlayerID()
    if IsPlayer(dwTargetID) then
        src = dest
        dest = dwTargetID
    end

    local nForceRelationType = GetRelation(src, dest)
    local nCount = 0
    while nForceRelationType > 1 do
        nForceRelationType = math.floor(nForceRelationType / 2)
        nCount = nCount + 1
    end

    local argb = tArgb or _aOutline[nCount]
    if pausetime then
        tLockCharacter[dwTargetID] = 1
    end
    Outline_initdata(dwTargetID, _tNpcOutline, Character_SetOutline, argb, pausetime, border)
end

function Character_HideOutline(dwTargetID)
    if not Outline_IsVisible() then
        return
    end

    Character_SetOutline(dwTargetID, 0, 0, 0, 0, 0)
    if tLockCharacter[dwTargetID] then
        tLockCharacter[dwTargetID] = nil
    end
    _tNpcOutline.targetid = nil
end

function Doodad_ShowOutline(dwTargetID)
    if not Outline_IsVisible() then
        return
    end

    local argb = _aOutline[0]
    Outline_initdata(dwTargetID, _tDoodadOutline, Doodad_SetOutline, argb)
end

function Doodad_HideOutline(dwTargetID)
    if not Outline_IsVisible() then
        return
    end

    local argb = _aOutline[0]
    Doodad_SetOutline(dwTargetID, 0, 0, 0, 0, 0)
    _tDoodadOutline.targetid = nil
end

function Furniture_ShowOutline(dwTargetID)
    if not Outline_IsVisible() then
        return
    end

    local argb = _aLineColor.green

    local fnSetOutline = function(dwTargetID, nLength, a, r, g, b)
        local nBaseID, nInstID = LandObject_GetLandIndexAndInstIDFromObjID(dwTargetID)
        Furniture_SetOutline(nBaseID, nInstID, nLength, a, r, g, b)
    end
    Outline_initdata(dwTargetID, _tFurnitureOutline, fnSetOutline, argb)
end

function Furniture_HideOutline(dwTargetID)
    if not Outline_IsVisible() then
        return
    end

    Furniture_SetOutline(dwTargetID, 0, 0, 0, 0, 0)
    _tFurnitureOutline.targetid = nil
end

function DummyObject_ShowOutline(dwTargetID)
    if not Outline_IsVisible() then
        return
    end

    local argb = _aLineColor.green

    -- 待补充
    --[[
    local fnSetOutline = function(dwTargetID, nLength, a, r, g, b)
        local nBaseID, nInstID = LandObject_GetLandIndexAndInstIDFromObjID(dwTargetID)
        Furniture_SetOutline(nBaseID, nInstID, nLength, a, r, g, b)
    end
    Outline_initdata(dwTargetID, _tFurnitureOutline, fnSetOutline, argb)
    --]]
end

function DummyObject_HideOutline(dwTargetID)
    if not Outline_IsVisible() then
        return
    end

    -- 待补充
    --[[
    Furniture_SetOutline(dwTargetID, 0, 0, 0, 0, 0)
    _tFurnitureOutline.targetid = nil
    --]]
end

function InteractDummyObject(dwObjID)
	--print(dwObjID)
	RemoteCallToServer("On_Dummy_StartInteraction", dwObjID)
	return true
end

--------------end--------------------------------------------------------------------

---------------game money---------------------------------------------------------------
local tMoneyZero = { nGold = 0, nSilver = 0, nCopper = 0 }

function FormatMoneyTab(tLMoney)
    if type(tLMoney) ~= "table" then
        local nMoney = tonumber(tLMoney) or 0
        if nMoney == 0 then
            return tMoneyZero
        end
        tLMoney = {}
        local nBrics = 0
        nBrics, tLMoney.nGold, tLMoney.nSilver, tLMoney.nCopper = ItemData.GoldSilverAndCopperFromMoney(nMoney)
        tLMoney.nGold = nBrics * 10000 + tLMoney.nGold
    end

    tLMoney.nGold = tLMoney.nGold or 0
    if tLMoney.nBullion then
        tLMoney.nGold = tLMoney.nGold + tLMoney.nBullion * 10000
        tLMoney.nBullion = nil
    end
    tLMoney.nSilver = tLMoney.nSilver or 0
    tLMoney.nCopper = tLMoney.nCopper or 0 
    return tLMoney
end

function MoneyOptCmp(tLMoney, tRMoney)
    tLMoney = FormatMoneyTab(tLMoney)
    tRMoney = FormatMoneyTab(tRMoney)
    return CompareMoney(tLMoney.nGold, tLMoney.nSilver, tLMoney.nCopper, tRMoney.nGold, tRMoney.nSilver, tRMoney.nCopper)
end

function MoneyOptAdd(tLMoney, tRMoney)
    tLMoney = FormatMoneyTab(tLMoney)
    tRMoney = FormatMoneyTab(tRMoney)
    return MoneyAdd(tLMoney.nGold, tLMoney.nSilver, tLMoney.nCopper, tRMoney.nGold, tRMoney.nSilver, tRMoney.nCopper)
end

function MoneyOptSub(tLMoney, tRMoney)
    tLMoney = FormatMoneyTab(tLMoney)
    tRMoney = FormatMoneyTab(tRMoney)

    return MoneyAdd(tLMoney.nGold, tLMoney.nSilver, tLMoney.nCopper, -tRMoney.nGold, -tRMoney.nSilver, -tRMoney.nCopper)
end

function MoneyOptDiv(tLMoney, nDiv)
    tLMoney = FormatMoneyTab(tLMoney)
    return MoneyDivide(tLMoney.nGold, tLMoney.nSilver, tLMoney.nCopper, nDiv)
end

function MoneyOptDivMoney(tLMoney, tRMoney)
    return MoneyDivideMoney(tLMoney.nGold, tLMoney.nSilver, tLMoney.nCopper, tRMoney.nGold, tRMoney.nSilver, tRMoney.nCopper)
end

function MoneyOptMult(tLMoney, nMult)
    tLMoney = FormatMoneyTab(tLMoney)
    return MoneyMultiply(tLMoney.nGold, tLMoney.nSilver, tLMoney.nCopper, nMult)
end

function UnpackMoney(t)
    return (IsNumber(t.nGold) and t.nGold or 0), (IsNumber(t.nSilver) and t.nSilver or 0), (IsNumber(t.nCopper) and t.nCopper or 0)
end

function UnpackMoneyEx(t)
    local nGold = IsNumber(t.nGold) and t.nGold or 0
    local nGoldB = math.floor(nGold / 10000)
    return nGoldB, (nGold - nGoldB * 10000), (t.nSilver or 0), (t.nCopper or 0)
end

function PackMoney(nGold, nSilver, nCopper)
    local t = {}
    t.nGold = IsNumber(nGold) and nGold or 0
    t.nSilver = IsNumber(nSilver) and nSilver or 0
    t.nCopper = IsNumber(nCopper) and nCopper or 0
    return t
end

function ConvertGoldToGBrick(nGold)
    local nGoldB = math.floor(nGold / 10000)
    return nGoldB, (nGold - nGoldB * 10000)
end

function ConvertMoney(editGB, editG, editS, editC, bUnpack)
    local nGoldB, nGold, nSilver, nCopper = 0, 0, 0, 0
    if editGB then
        if type(editGB) == "number" then
            nGoldB = editGB
        elseif editGB.GetText then
            nGoldB = tonumber(editGB:GetText()) or 0
        elseif type(editGB) == "string" then
            nGoldB = tonumber(editGB) or 0
        end
    end

    if editG then
        if type(editG) == "number" then
            nGold = editG
        elseif editG.GetText then
            nGold = tonumber(editG:GetText()) or 0
        elseif type(editG) == "string" then
            nGold = tonumber(editG) or 0
        end
    end

    if editS then
        if type(editS) == "number" then
            nSilver = editS
        elseif editS.GetText then
            nSilver = tonumber(editS:GetText()) or 0
        elseif type(editS) == "string" then
            nSilver = tonumber(editS) or 0
        end
    end

    if editC then
        if type(editC) == "number" then
            nCopper = editC
        elseif editC.GetText then
            nCopper = tonumber(editC:GetText()) or 0
        elseif type(editC) == "string" then
            nCopper = tonumber(editS) or 0
        end
    end

    if bUnpack then
        return (nGoldB * 10000 + nGold), nSilver, nCopper
    end
    return PackMoney((nGoldB * 10000 + nGold), nSilver, nCopper)
end

function CovertMoneyToCopper(tMoney)
    if not tMoney then
        return 0
    end
    local nCopper = tMoney.nGold * 10000 + tMoney.nSilver * 100 + tMoney.nCopper
    return nCopper or 0
end

function CovertCopperToMoney(nCopper)
    return { nGold = math.floor(nCopper / 10000), nSilver = math.floor((nCopper % 10000) / 100), nCopper = nCopper % 100 }
end
--------------end--------------------------------------------------------------------

---------------cache---------------------------------------------------------------
local m_caches = {}
local function _clear_cache(cache)
    if cache._useNum == 0 then
        return
    end

    Log(string.format("%s cache clear num(%d)", cache._desc, cache._useNum))

    local maxNum = cache._maxNum
    local desc = cache._desc
    local update = cache._update
    local index = cache._index
    cache = {
        _maxNum = maxNum,
        _useNum = 0,
        _desc = desc,
        _update = update,
        _index = index,
    }
    m_caches[index] = cache
    cache._update(cache)

    return cache
end

function cache_init(maxNum, desc, update_fun)
    local cache = {}
    cache._maxNum = maxNum or 10
    cache._useNum = 0
    cache._desc = desc or ""
    cache._update = update_fun
    cache._index = #m_caches + 1

    table.insert(m_caches, cache)
    return cache
end

function cache_append(cache, key, value)
    key = key or ""
    if cache._useNum < cache._maxNum then
        cache[key] = value
        cache._useNum = cache._useNum + 1
    else
        cache = _clear_cache(cache)
        cache._useNum = 1
        cache[key] = value
    end
    return cache
end

function cache_reset()
    for k, cache in pairs(m_caches) do
        _clear_cache(cache)
    end
end
--------------end--------------------------------------------------------------------

---------------TargetFace---------------------------------------------------------------
local tAngle = { 30, 60, 90, 135, 180 }
local nDefaultAngle = 60
if IsMobileStreamingEnable then
    nDefaultAngle = 30
end
local TARGET_FACE_SIZE_MIN = 0.5
local TARGET_FACE_SIZE_MAX = 1.5

function GetTargetFaceAngleArray()
    return tAngle
end

function TargetFace_SetAngle(val)
    local nIndex = 1
    for k, v in ipairs(tAngle) do
        if v == val then
            nIndex = k
            break
        end
    end
    StorageServer.SetData("TargetFaceAngle", nIndex)
end

function TargetFace_GetAngle()
    local nIndex = StorageServer.GetData("TargetFaceAngle")
    return tAngle[nIndex] or nDefaultAngle
end

function TargetFace_GetAngleIndex()
    local tList = { 30, 60, 90, 135, 180 }
    local nStoredAngle = GameSettingData.GetNewValue(UISettingKey.EffectAngle).szDec
    nStoredAngle = tonumber(nStoredAngle)
    for index, nAngle in ipairs(tList) do
        if nAngle == nStoredAngle then
            return index
        end
    end
end

function TargetFace_SetSize(val)
    StorageServer.SetData("TargetFaceSize", val)
end

function TargetFace_SetSizeFromShow(val)
    val = math.floor((val - TARGET_FACE_SIZE_MIN) * 10 + 0.5)
    StorageServer.SetData("TargetFaceSize", val)
end

function TargetFace_GetSize()
    local val = StorageServer.GetData("TargetFaceSize")
    local nSize = TargetFace_GetSizeCount()
    val = RangeNumber(val, 0, nSize)
    return val
end

function TargetFace_GetSizeShow(val)
    if not val then
        val = GameSettingData.GetNewValue(UISettingKey.EffectSize)
    end
    --val = val / 10 + TARGET_FACE_SIZE_MIN
    return val
end

function TargetFace_GetSizeCount()
    local nCount = math.floor((TARGET_FACE_SIZE_MAX - TARGET_FACE_SIZE_MIN) * 10 + 0.5)
    return nCount
end

function TargetFace_SetAlpha(val)
    StorageServer.SetData("TargetFaceAlpha", val)
end

function TargetFace_GetAlpha()
    return GameSettingData.GetNewValue(UISettingKey.EffectTransparency)
end

function TargetFace_SetType(val)
    StorageServer.SetData("TargetFaceType", val)
end

function TargetFace_GetType()
    local t = GameSettingData.GetNewValue(UISettingKey.EffectStyle)
    return t.szDec == GameSettingType.FacingSFXType.Solid.szDec and 0 or 1
end

function ShowTargetFaceEnemy(bShow)
    StorageServer.SetData("UISetting_BoolValues2", "SHOW_TARGET_FACE_ENEMY", bShow)
    EnableTargetFace()
end

function ShowTargetFaceNotEnemy(bShow)
    StorageServer.SetData("UISetting_BoolValues2", "SHOW_TARGET_FACE_N_ENEMY", bShow)
    EnableTargetFace()
end

function ShowTargetFaceBoss(bShow)
    StorageServer.SetData("UISetting_BoolValues2", "SHOW_TARGET_FACE_BOSS", bShow)
    EnableTargetFace()
end

function EnableTargetFace()
    local nShowEnemy = 0
    if GameSettingData.GetNewValue(UISettingKey.HostileTarget) then
        nShowEnemy = 1
    end
    local nShowNotEnemy = 0

    if GameSettingData.GetNewValue(UISettingKey.NonHostileTarget) then
        nShowNotEnemy = 1
    end
    rlcmd("enable selection arrow " .. nShowEnemy .. " " .. nShowNotEnemy)
    --LOG.WARN("enable selection arrow " .. nShowEnemy .. " " .. nShowNotEnemy)

    local nShowBoss = 0

    if GameSettingData.GetNewValue(UISettingKey.NonTargetBoss) then
        nShowBoss = 1
    end
    rlcmd("enable direction sfx " .. tostring(nShowBoss))
    --LOG.WARN("enable direction sfx " .. tostring(nShowBoss))
end

function SetTargetFaceParam()
    local nAngle = TargetFace_GetAngleIndex() - 1
    local fSize = TargetFace_GetSizeShow()
    local nAlpha = TargetFace_GetAlpha()
    local nType = TargetFace_GetType()

    local fAlpha = nAlpha / 255
    local nAngleNum = 5
    rlcmd("set selection arrow state " .. (nType * nAngleNum + nAngle) .. " " .. fSize .. " " .. fAlpha)
    rlcmd("set direction sfx state " .. (nType * nAngleNum + nAngle) .. " " .. fSize .. " " .. fAlpha)
    --print("set direction sfx state " .. (nType * nAngleNum + nAngle) .. " " .. fSize .. " " .. fAlpha)
end

function SetTargetBraceParam()
    local nShowPlayer = 0
    if GameSettingData.GetNewValue(UISettingKey.ShowPlayerDirection) then
        nShowPlayer = 1
    end

    local nShowNPC = 0
    if GameSettingData.GetNewValue(UISettingKey.ShowNPCDirection) then
        nShowNPC = 1
    end

    local szCMD = string.format("enable target brace sfx %d %d 182", nShowPlayer, nShowNPC)
    --LOG.WARN(szCMD)
    rlcmd(szCMD)
end

function UpdateTargetFace()
    EnableTargetFace()
    SetTargetFaceParam()
end

local function OnUISettingVersionUpdate()
    local nVersion = arg0
    if nVersion < 13 then
        if IsMobileStreamingEnable() then
            TargetFace_SetAngle(30)
        else
            TargetFace_SetAngle(60)
        end
        TargetFace_SetAlpha(255)
        TargetFace_SetSizeFromShow(1)
    end
end

--RegisterEvent("UISETTING_VERSION_UPDATE", OnUISettingVersionUpdate)
--------------end--------------------------------------------------------------------

----------------hatstyle-----------------------------------------------------------------
function Role_GetHatStyle(bHideHair)
    ---由于博强担心策划需要多种stype，所以表现的是否隐藏帽子是个int 0：默认style 1：disable style，我们需要转换一下
    local nHatStyle = 0
    if bHideHair then
        nHatStyle = 1
    end
    return nHatStyle
end

function Role_DealWithCloak(player, aRepresentID)
	if player.GetRepresentHideFlag(PLAYER_REPRESENT_HIDE_TYPE.BACK_CLOAK_MODEL) then
        aRepresentID.bHideBackCloakModel = true
    end
end

function Role_GetRepresentID(hPlayer)
    local tRepresentID = hPlayer.GetRepresentID()
    tRepresentID.nHatStyle = Role_GetHatStyle(hPlayer.bHideHair)
    tRepresentID.bUseLiftedFace = hPlayer.bEquipLiftedFace and not IsRoleInFakeState(hPlayer)
    tRepresentID.tFaceData = hPlayer.GetEquipLiftedFaceData()
    tRepresentID.tBody = hPlayer.GetEquippedBodyBoneData()
    tRepresentID.tHairDyeingData = Role_GetHairDyeingData(hPlayer, tRepresentID)
    Role_DealWithCloak(hPlayer, tRepresentID)

    return tRepresentID
end

function Role_GetHairDyeingData(hPlayer, tRepresentID)
	local nHairID = tRepresentID[EQUIPMENT_REPRESENT.HAIR_STYLE]
	if nHairID ~= 0 then
		return hPlayer.GetEquippedHairCustomDyeingData(nHairID) or {}
	end
	return {}
end

local max, min = math.max, math.min
function ApplyUIScale(fNewValue, bForce)
    local fScale = Station.GetMaxUIScale()

    local nScreenX, nScreenY = GetSystemCScreen()
    local nUIScaleCorrection = UIScaleCorrector()

    if IsMobileStreamingEnable() then
        nUIScaleCorrection = 1
        fScale = fScale * nUIScaleCorrection
    else
        fScale = fScale * nUIScaleCorrection * 0.9
    end

    local fSetUIScale = fScale * fNewValue
    if nScreenX <= 1920 and fSetUIScale >= 1.0 and not bForce then
        fSetUIScale = 1.0
    end

    Station_SetUIScale(fSetUIScale)
end
--------------end--------------------------------------------------------------------


------------------------------CustomPendant------------------------------
local _tPendantTypeLogicToRes = nil
local _tCustomPendantType = nil
local function LoadPendantTab()
	_tPendantTypeLogicToRes =
	{
		["BACK_EXTEND"] = EQUIPMENT_REPRESENT.BACK_EXTEND, 		--背挂
		["WAIST_EXTEND"] = EQUIPMENT_REPRESENT.WAIST_EXTEND, 		--腰挂
		["BAG"] 		= EQUIPMENT_REPRESENT.BAG_EXTEND, 		--佩囊
		["CLOAK"] 		= EQUIPMENT_REPRESENT.BACK_CLOAK_EXTEND,	--披风
        ["FACE_EXTEND"] = EQUIPMENT_REPRESENT.FACE_EXTEND,
        ["GLASS"] = EQUIPMENT_REPRESENT.GLASSES_EXTEND,
        ["HEAD_EXTEND"] = EQUIPMENT_REPRESENT.HEAD_EXTEND,
        ["HEAD_EXTEND_ONE"] 	= EQUIPMENT_REPRESENT.HEAD_EXTEND1,		--头饰2
		["HEAD_EXTEND_TWO"] 	= EQUIPMENT_REPRESENT.HEAD_EXTEND2,		--头饰3

	}

	_tCustomPendantType =
	{
		[EQUIPMENT_REPRESENT.BACK_EXTEND] 		= "BACK_EXTEND",	--背挂
		[EQUIPMENT_REPRESENT.WAIST_EXTEND] 		= "WAIST_EXTEND", 	--腰挂
		[EQUIPMENT_REPRESENT.BAG_EXTEND] 		= "BAG", 			--佩囊
		[EQUIPMENT_REPRESENT.BACK_CLOAK_EXTEND] = "CLOAK",   		--披风
        [EQUIPMENT_REPRESENT.FACE_EXTEND] = "FACE_EXTEND",
        [EQUIPMENT_REPRESENT.GLASSES_EXTEND] = "GLASS",
        [EQUIPMENT_REPRESENT.HEAD_EXTEND] = "HEAD_EXTEND",
        [EQUIPMENT_REPRESENT.HEAD_EXTEND1] 	= "HEAD_EXTEND_ONE", --头饰2
		[EQUIPMENT_REPRESENT.HEAD_EXTEND2] 	= "HEAD_EXTEND_TWO", --头饰3
	}
end

function GetAllCustomPendantType()
	if not _tCustomPendantType then
		LoadPendantTab()
	end
	return _tCustomPendantType
end

--可以自定义挂件的部位
function IsCustomPendantType(nType)
	if not _tCustomPendantType then
		LoadPendantTab()
	end
	return _tCustomPendantType[nType] ~= nil
end

function GetCustomPendantType(nType)
	if not _tCustomPendantType then
		LoadPendantTab()
	end
	return _tCustomPendantType[nType]
end

--可以自定义挂件的部位和表现
function IsCustomPendantRepresentID(nType, dwRepresentID, nRoleType)
    if not IsCustomPendantType(nType) then
        return false
    end
	if nType == EQUIPMENT_REPRESENT.BACK_CLOAK_EXTEND then
		if not nRoleType then
			local hPlayer = GetClientPlayer()
			if not hPlayer then
				return false
			end
			nRoleType = hPlayer.nRoleType
		end
		return Player_GetEquipCanAdjustTransform(nRoleType, "CLOAK", dwRepresentID)
	else
		return true
	end
end

function GetPendantTypeByResEquipType(szType)
	if not _tPendantTypeLogicToRes then
		LoadPendantTab()
	end
	return _tPendantTypeLogicToRes[szType]
end

--可以自定义挂件的部位和表现Type
function IsCustomPendantRepresentType(szType, dwRepresentID, nRoleType)
	if not _tPendantTypeLogicToRes then
		LoadPendantTab()
	end
    local nType = _tPendantTypeLogicToRes[szType]
	return IsCustomPendantRepresentID(nType, dwRepresentID, nRoleType)
end

function GetEquipCustomRepresentData(pPlayer)
	local tData = {}
	for nIndex, v in pairs(_tCustomPendantType) do
		local t = pPlayer.GetEquipCustomRepresentData(nIndex)
		tData[nIndex] = t
	end
	return tData
end

------------------------------End------------------------------

----------------ModelShadow-------------------------------------------------------------
--GetModelShadowType() for coinshop and Logcumstom panel

function GetModelShadowType()
    local tGPU = GetDisplayCard()
    for k, v in ipairs(tGPU) do
        local nSize = v.GRam / 1024
        if nSize >= 1.5 then
            return 3, true
        end
    end
    return 2, false
end

function GetCoinShopModelShadowType()
    local tGPU = GetDisplayCard()
    for k, v in ipairs(tGPU) do
        local nSize = v.GRam / 1024
        if nSize >= 1.5 then
            return 4, true
        end
    end
    return 2, false
end
--------------end--------------------------------------------------------------------

----------------时间相关-------------------------------------------------------------
-- 公用脚本函数
-- 函数名 :Time_AddZone
-- 函数描述 : 给时间戳加上时区
-- 参数列表 : nTime：时间戳
-- 返回值 :返回加了时区的时间戳
-- 备注 :
-- 示例 :
function Time_AddZone(nTime)
    local nTimeZone = GetTimezone()
    return nTime + nTimeZone
end

-- 公用脚本函数
-- 函数名 :StringParse_Time
-- 函数描述 : 将指定格式的字符串解析成时间
-- 参数列表 : szTime:时间字符串
-- 返回值 :时间戳
-- 备注 : 时间格式：2010;1;11;19;0;0
-- 示例 :
function StringParse_Time(szTime)
    local t = SplitString(szTime, ";")
    if #t >= 6 then
        return DateToTime(t[1], t[2], t[3], t[4], t[5], t[6])
    end
end
--------------end--------------------------------------------------------------------

----------------MobileStreaming------------------------------------------------------
--判断是否为移动云端
function IsMobileStreamingEnable()
    local nPlatform = SM_GetPlatform()
    return SM_IsEnable() and (nPlatform == 1 or nPlatform == 2) -- android or ios, 展鸿导出枚举值后修改
end

-- 对文件夹路径进行云端适配，只适用于相对路径
function GetStreamAdaptiveDirPath(szDirPath)
    local szPath = szDirPath
    if SM_IsEnable() then
        szPath = GetUserDataPath() .. "\\" .. szDirPath
    end
    return szPath
end
--------------end----------------------------------------------------------------

----------------环境相关----------------------------------------------------------
function IsInLishijie()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return true
    end

    if hPlayer.dwIdentityVisiableID < 0 then
        return true
    end

    local dwType
    if GetIdentityVisibleType then
        dwType = GetIdentityVisibleType(hPlayer.dwIdentityVisiableID)
    end
    return dwType == IDENTITY_VISIBLE_LISHIJIE
end

--相关的掩码进行的交易筛选
-- 普通地图为1，JJC/BF为2，吃鸡为4
function IsEnableTradeMap(dwBanTradeItemMask)
    if dwBanTradeItemMask == 2 then
        return false
    else
        return true
    end
end

--掩码值与为0,能交易
function IsEnableTradeItem(dwBanTradeItemMask, dwMapBanTradeItemMask, item)
    local nRecode = kmath.andOperator(dwBanTradeItemMask, dwMapBanTradeItemMask)  -- 该地图可交易
    if nRecode == 0 then
        if not item.bBind then
            return true
        else
            if item.CheckIgnoreBindMask(ITEM_IGNORE_BIND_TYPE.MENTOR) then -- 师父可交易
                return true
            end
            if item.CheckIgnoreBindMask(ITEM_IGNORE_BIND_TYPE.TONG) then  -- 同帮会可交易
                return true
            end
            if item.CheckIgnoreBindMask(ITEM_IGNORE_BIND_TYPE.DUNGEON) then  -- 秘境内可交易
                local player = GetClientPlayer()
                local nLeftTime = player.GetTradeItemLeftTime(item.dwID)
                if nLeftTime > 0 then
                    return true
                end
            end
        end
    end
    return false
end

--- 用于判断是否要显示PakV4下载速度等
function IsRealPakV4Enabled()
    --[[
    return IsPakV4Enabled() and (not WG_IsEnable()) --- 以前要排除掉WeGame版
    --]]
    return IsPakV4Enabled()
end
--------------end----------------------------------------------------------------

--------------其他-------------------------------------------------------------------
function Global_GetValue(var_path)
    if not string.find(var_path, ".") then
        return _G[var_path]
    end

    local t = SplitString(var_path, ".")
    local value = _G
    for k, v in ipairs(t) do
        if value[v] then
            value = value[v]
        else
            return
        end
    end
    return value
end

function Global_SetValue(var_path, value)
    if not string.find(var_path, ".") then
        _G[var_path] = value
    end

    local vars = SplitString(var_path, ".")
    local lvar = _G
    local len = #vars
    local k = nil
    for i = 1, len - 1, 1 do
        k = vars[i]
        if not lvar[k] then
            return
        end
        lvar = lvar[k]
    end

    if lvar and type(lvar) == "table" then
        lvar[vars[len]] = value
    else
        Log(string.format("Global_SetValue(%g, %g) failed!", var_path, value))
    end
end

function TableSet(v, t, ...)
    if type(t) ~= "table" then
        return
    end
    local n = select("#", ...)
    local e, k
    for i = 1, n do
        k = select(i, ...)
        if k == nil then
            return
        end
        if i == n then
            t[k] = v
            return
        else
            e = t[k]
            if e == nil then
                e = {}
                t[k] = e
            end
            if type(e) == "table" then
                t = e
            else
                return
            end
        end
    end
end
function TableGet(t, ...)
    local n = select("#", ...)
    for i = 1, n do
        local k = select(i, ...)
        if nil == k then
            break
        end
        if type(t) ~= "table" then
            return nil
        end
        t = t[k]
    end
    return t
end

function CallGlobalFun(funname, ...)
    if not string.find(funname, ".") then
        return _G[funname](...)
    end

    local t = SplitString(funname, ".")
    local len = #t
    if len == 2 then
        return _G[t[1]][t[2]](...)
    end

    local fun = _G
    for k, v in ipairs(t) do
        if fun[v] then
            fun = fun[v]
        else
            return
        end
    end

    if fun then
        return fun(...)
    end
end

function ExecuteWithThis(element, fnAction, ...)
    if not (element and element:IsValid()) then
        Log("[UI ERROR]Invalid element on executing ui event!")
        return false
    end
    if type(fnAction) == "string" then
        if element[fnAction] then
            fnAction = element[fnAction]
        else
            local szFrame = element:GetRoot():GetName()
            if type(_G[szFrame]) == "table" then
                fnAction = _G[szFrame][fnAction]
            end
        end
    end
    if type(fnAction) ~= "function" then
        Log("[UI ERROR]Invalid function on executing ui event! # " .. element:GetTreePath())
        return false
    end
    local _this = this
    this = element
    fnAction(...)
    this = _this
    return true
end

-- 使data的数据结构和struct一样 不同的则覆盖
function FormatDataStructure(data, struct)
    local szType = type(struct)
    if szType == type(data) then
        if szType == 'table' then
            local t = {}
            for k, v in pairs(struct) do
                t[k] = FormatDataStructure(data[k], v)
            end
            return t
        end
    else
        data = clone(struct)
    end
    return data
end

local _nPCCapLevel
--  * 获取当前系统的配置等级
function GetPCCapLevel()
    if _nPCCapLevel == -1 then
        return
    end

    if _nPCCapLevel then
        return _nPCCapLevel
    end

    local IniFile = Ini.Open("BenchmarkResult.ini")
    if not IniFile then
        return
    end
    local nLevel = IniFile:ReadInteger("Result", "DisplayLevel", -1)
    IniFile:Close()

    _nPCCapLevel = nLevel
    if _nPCCapLevel ~= -1 then
        return _nPCCapLevel
    end
end

function IsImageFileExist(szFile)
    if not szFile then
        return
    end
    local suffix = szFile:sub(-4, -1)
    local res = false

    if suffix == ".tga" then
        res = IsFileExist(szFile:sub(1, -5) .. ".dds")
        if not res then
            res = IsFileExist(szFile)
        end
    else
        res = IsFileExist(szFile)
    end

    return res
end

function GetUserAccountFolderName(szAccount)
    local szAccountFolder = szAccount:gsub('%.$', '%%2E')
    return szAccountFolder
end

function GetJX3TempPath()
    local path = GetFullPath("temp")
    -- return GetFullPath("Temp").."\\"
    -- if SM_IsEnable() then
    --     local szAccount = Login_GetAccount() or ""
    --     if szAccount == "" then
    --         Log("[GetJX3TempPath] Streaming client cannot get the account!")
    --     else
    --         path = path .. "\\" .. GetUserAccountFolderName(szAccount)
    --     end
    -- end

    if not Lib.IsDirectoryExist(path) then
        CPath.MakeDir(path)
    end

    local szRetPath = UIHelper.GBKToUTF8(path) .. (Platform.IsWindows() and "\\" or "/")
    return szRetPath
end

function SetCaptionIconVisible(nVisible)
    rlcmd("show_caption_icon " .. nVisible)
    k3dcmd("show_caption_icon " .. nVisible)
end

function OnInitCaptionIconVisible()
    local ini
    if Lib.IsFileExist("caption.ini") then
        ini = Ini.Open("caption.ini")
    else
        ini = Ini.Open("data/public/caption.ini")
    end

    if not ini then
        return
    end

    local nVisible = ini:ReadInteger("FontConfig", "IconVisible", 0)
    SetCaptionIconVisible(nVisible)
    ini:Close()
end

-- 公用脚本函数
-- 函数名 : GetAccountType
-- 函数描述 : 获取账号类型，WEGAME,云端，或者普通账号
-- 参数列表 :无
-- 返回值 :账号类型
-- 备注 :
-- 示例 :
function GetAccountType()
    if WG_IsEnable() then
        return UNION_ACCOUNT_CHANNEL.UNION_ACCOUNT_CHANNEL_WEGAME
    end

    if SM_IsEnable() then
        return UNION_ACCOUNT_CHANNEL.UNION_ACCOUNT_CHANNEL_GENERAL    --云端目前的账号类型仍然是金山通行证，pf应该根据账号类型区分。如果云端使用金山通行证则返回0，使用wegame登录则返回10。目前先返回0，后面还需要再对。
    end

    return UNION_ACCOUNT_CHANNEL.UNION_ACCOUNT_CHANNEL_GENERAL
end

--逻辑导出的接口 .传入player.dwForceID
function TransformPlayerForceToPresentIndex(dwForceID)
    if dwForceID then
        return PlayerForceToPresentIndex(dwForceID)
    end
end

function FormatByteSize(nSize, szUnit, fDisplayMax)
    -- nSize肯定大于等于1
    local aUnitArray = { "B", "KB", "MB", "GB" }
    szUnit = szUnit or "B"
    local nOldIndex = FindTableValue(aUnitArray, szUnit)
    assert(nOldIndex)
    local nUnitBase = 1024
    fDisplayMax = fDisplayMax or nUnitBase
    local nUnit = 1
    local nIndex = nOldIndex

    while true do
        local nValue = nSize / nUnit

        if nIndex >= #aUnitArray then
            return nValue, aUnitArray[#aUnitArray], #aUnitArray - nOldIndex
        else
            if nValue < fDisplayMax then
                return nValue, aUnitArray[nIndex], nIndex - nOldIndex
            end

            nUnit = nUnit * nUnitBase
            nIndex = nIndex + 1
        end
    end
end

function LoadLangPack(szLangFolder)
    local _, _, szLang = GetVersion()
    local t0 = {}
    if type(szLangFolder) == "string" then
        szLangFolder = string.gsub(szLangFolder, "[/\\]+$", "")
        t0 = LoadLUAData(szLangFolder .. "\\default.lang") or {}
        local t1 = LoadLUAData(szLangFolder .. "\\" .. szLang .. '.lang') or {}
        for k, v in pairs(t1) do
            t0[k] = v
        end
    end
    setmetatable(t0, {
        __index = function(t, k)
            return k
        end,
        __call = function(t, k, ...)
            return string.format(t[k], ...)
        end,
    })
    return t0
end

function Conversion2ChineseNumber(num, szSeparator, tDigTable)
    local szNum = tostring(num)
    if not szNum then
        return
    end

    local Conversion = function(nLen, szSeparator)
        local bZero = false
        local szValidLevel = ""
        local tCharNum, tCharDiH, tCharDiL
        szSeparator = szSeparator or ""
        if tDigTable then
            tCharNum = tDigTable.tCharNum
            tCharDiH = tDigTable.tCharDiH
            tCharDiL = tDigTable.tCharDiL
        else
            tCharNum = g_tStrings.DIGTABLE.tCharNum
            tCharDiH = g_tStrings.DIGTABLE.tCharDiH
            tCharDiL = g_tStrings.DIGTABLE.tCharDiL
        end

        if num == 0 then
            return tCharNum[0]
        end

        return function(matched)
            local nQuotient, nRemainder = math.modf(nLen / #tCharDiL) + 1, nLen % #tCharDiL
            local nNumber = tonumber(matched)
            local szCharNum = tCharNum[nNumber]
            if nRemainder == 0 then
                nRemainder = #tCharDiL
                nQuotient = nQuotient - 1
            end

            if szCharNum == tCharNum[0] then
                bZero = true
                szCharNum = ""
            else
                if bZero then
                    bZero = false
                    szCharNum = tCharNum[0] .. szCharNum
                end
                if nNumber == 1 and nRemainder == 2 and nLen == #szNum then
                    -- 十万 十一 这种十开头的前面不加一【一十万 一十一】
                    szCharNum = ""
                end
                szCharNum = szCharNum .. tCharDiL[nRemainder]
                szValidLevel = tCharDiH[nQuotient]
            end

            if nRemainder == 1 then
                szCharNum = szCharNum .. szValidLevel .. szSeparator
                szValidLevel = ""
                bZero = false
            end

            nLen = nLen - 1
            return szCharNum
        end
    end
    return (szNum:gsub("%d", Conversion(#szNum, szSeparator)))
end

-- vPos1: {x1, y1, z1};
-- vPos2: {x2, y2, z2};
function GetLogicDist(vPos1, vPos2)
    return math.sqrt((vPos1[1] - vPos2[1]) * (vPos1[1] - vPos2[1]) + (vPos1[2] - vPos2[2]) * (vPos1[2] - vPos2[2])
            + (vPos1[3] - vPos2[3]) * (vPos1[3] - vPos2[3]) / 64)
end


-- RunMode Beg ---------------------
function RM_SetRunMode(tObj, szRunMode, bReset)
    assert(tObj)
    if DEBUG_ZJQ then
        LOG.INFO(string.format("----> RM_SetRunMode: %s(%s -> %s)", tObj._szObjName, tObj._szRunMode, szRunMode))
    end
    if tObj._szRunMode ~= szRunMode or bReset then
        local fnRunMode = tObj[szRunMode]
        assert(fnRunMode, string.format("No found: %s.%s", tObj._szObjName, "RunMode_" .. szRunMode))
        tObj._fnRunMode = fnRunMode
        tObj._szRunMode = szRunMode
        tObj._nRunModeCycle = 0
    end
end
function RM_InitRunMode(tObj, szObjName)
    assert(tObj)
    tObj._szObjName = szObjName or "Unknown"
    tObj._szRunMode = "Unknown"
    tObj._fnRunMode = nil
    tObj._nRunModeCycle = 0
end
function RM_UpdateRunMode(tObj)
    assert(tObj)
    if tObj._fnRunMode then
        tObj._nRunModeCycle = tObj._nRunModeCycle + 1
        tObj._fnRunMode(tObj)
    end
end
function RM_IsInThisRunMode(tObj, szRunMode)
    assert(tObj)
    if type(szRunMode) == "table" then
        for _, szMode in ipairs(szRunMode) do
            if tObj._szRunMode == szMode then
                return true
            end
        end
        return false
    else
        return tObj._szRunMode == szRunMode
    end
end
function RM_IsFirstCycle(tObj)
    assert(tObj)
    return tObj._nRunModeCycle == 1
end
function RM_GetRunMode(tObj)
    assert(tObj)
    return tObj._szRunMode
end
-- RunMode End ---------------------

function FormatLinkString(szMsg, szFont, ...)
	szMsg = FormatString(szMsg, ...)
	local szResult = ""
	local nFirst, nLast, szAdd = string.find(szMsg, "<link (.-)>")
	while nFirst do
		local szPrev = string.sub(szMsg, 1, nFirst - 1)
		if szPrev and szPrev ~= "" then
			szResult = szResult.."<text>text=\""..szPrev.."\""..szFont.." </text>"
		end
		if szAdd and szAdd ~= "" then
			local nIndex = tonumber(szAdd) + 1
			local szText = select(nIndex, ...)
			if szText then
				szResult = szResult..szText
			else
				szResult = szResult.."<text>text=\""..szAdd.."\""..szFont.." </text>"
			end
		end

		szMsg = string.sub(szMsg, nLast + 1, -1)
		nFirst, nLast, szAdd = string.find(szMsg, "<link (.-)>")
	end
	if szMsg and szMsg ~= "" then
		szResult = szResult.."<text>text=\""..szMsg.."\""..szFont.." </text>"
	end
	return szResult
end


--------------end--------------------------------------------------------------------

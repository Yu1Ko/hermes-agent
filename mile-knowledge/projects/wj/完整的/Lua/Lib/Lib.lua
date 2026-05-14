-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort

local _ipairs, _pairs, next, pcall, print = ipairs, pairs, next, pcall, print
local tinsert, tremove, tconcat = table.insert, table.remove, table.concat
local ssub, slen, schar, srep, sbyte, sformat, sgsub =
	  string.sub, string.len, string.char, string.rep, string.byte, string.format, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local floor, mmin, mmax, mceil = math.floor, math.min, math.max, math.ceil
local setmetatable, getmetatable = setmetatable, getmetatable

local string2byte = string.byte

Lib = Lib or {}

if not g_bIsReloading then
	local nMinor = tonumber(string.match(_VERSION, "Lua %d%.(%d)"))
	-- 重载系统函数, 以扩展部分5.3版本才有的部分功能
	if nMinor < 3 then
		---comment 替代全局的pairs,
		---@param t table
		function pairs(t)
			t = t or {}
			local mt = getmetatable(t)
			local f = (type(mt) == "table") and mt.__pairs or _pairs
			return f(t)
		end

		---comment 替代全局的ipairs
		---@param t table
		function ipairs(t)
			t = t or {}
			local mt = getmetatable(t)
			local f = mt and mt.__ipairs or _ipairs
			return f(t)
		end
	end
end

function Include(file)
	local script = Lib.GetStringFromFile(file)
	if not script then
		LOG.ERROR("include file is not exist, %s", file)
		return
	end

	local fn, szError = loadstring(script)
	if not fn then
		LOG.ERROR("load file is failed, %s\n%s", file, szError)
		return
	end

	local tbEnv = {}
	local meta = getmetatable(_G)
	setmetatable(_G, {
			__newindex = function(_, name, value)
				tbEnv[name] = value
			end,
			__index = function(_, name)
				return tbEnv[name]
			end
		}
	)

	local ok, ret = pcall(fn)
	if not ok then
		LOG.ERROR("load file is failed, %s\n%s", file, ret)
		tbEnv = nil
	end

	setmetatable(_G, meta)
	return tbEnv
end

---------------------------------------------------------------------
-- 一些table的操作集合 直接从剑三挪过来的 = =||
---------------------------------------------------------------------
-- 只读表创建
function SetmetaReadonly(t)
	for k, v in pairs(t) do
		if type(v) == 'table' then
			t[k] = SetmetaReadonly(v)
		end
	end
	return setmetatable({}, {
		__index     = t,
		__newindex  = function() assert(false, 'table is readonly\n') end,
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

EMPTY_TABLE = SetmetaReadonly({})

function pairsWithDefault(__default_values)
 	return function (tbl)
		local function in_array(list,val)
			if not list then return false end
			local k,v
			for k, v in ipairs(list) do
				if v == val then return true end
			end
			return false
		end

		local key_list = {};
		local k, v = next(tbl, nil)
		while v ~= nil do
			if in_array(key_list, k) == false then
				table.insert(key_list, k);
			end
			k, v = next(tbl, k)
		end

		k, v = next(__default_values, nil)
		while v ~= nil do
			if in_array(key_list, k) == false then
				table.insert(key_list, k);
			end
			k, v = next(__default_values, k)
		end

		local nIndex = 0;
		local function state_iter(tbl, k)
			nIndex = nIndex + 1;
			return key_list[nIndex], tbl[key_list[nIndex]]
		end
		return state_iter, tbl, nil
	end
end

-- 类型检查====================================================================
function IsNumber(t)
	return type(t) == "number"
end

function IsTable(t)
	return type(t) == "table"
end

function IsString(t)
	return type(t) == "string"
end

function IsNil(t)
	return type(t) == "nil"
end

function IsFunction(t)
	return type(t) == "function"
end

function IsBoolean(t)
	return type(t) == "boolean"
end
-- 类型检查====================================================================



--************************************string 扩展***************************************
--- 字符串拆分 string.split("1,2,3,4,5,6", ',')
function string.split(str, split_char)
	local result = {}
	if str == nil or str == '' or split_char == nil then
		return result
	end

	for match in (str..split_char):gmatch("(.-)"..split_char) do
		table.insert(result, match)
	end
	return result
end
-- 判断字符串是否为 nil 或 ""
function string.is_nil(str)
	if str == nil or string.len(str) <= 0 then return true end
	return false
end
-- 执行字符串
function string.execute(szFunc)
	if string.is_nil(szFunc) then return end
	local func = loadstring("return " .. szFunc)
	if not func then LOG.ERROR("string.execute 找不到函数{0}", szFunc) return end
	return func()
end
-- 转换颜色信息
function string.convert_color(szContext)
	szContext = szContext or ""
	-- 处理白色
	for _, v in pairs(TabHelper.GetUIColorTab()) do
		local szFlag =  "%[" .. v.szColorFlag .. "%]"
		local szReplace = "[" .. v.szColorValue .. "]"
		szContext = string.gsub(szContext, szFlag, szReplace)
	end
	return szContext
end
-- 清除颜色标记
function string.clear_color_flag(szContext)
	if not szContext then return "" end
	for _, v in pairs(TabHelper.GetUIColorTab()) do
		local szFlag =  "%[" .. v.szColorFlag .. "%]"
		szContext = string.gsub(szContext, szFlag, "")
	end
	return szContext
end

function string.RemoveAllColor(szContext)
	local pattern =  "%[%w%w%w%w%w%w%]"

	return (string.gsub(szContext, pattern, ""))
end
function string.to_table(szContext)
	szContext = szContext or "{}"
	szContext = "return" .. szContext
	local func = loadstring(szContext)
	if func then
		return func()
	else
		LOG.ERROR("string.to_table Failed")
		return {}
	end
end

string.is_less = function(a, b)
	local nLenA = string.len(a)
	local nLenB = string.len(b)
	if nLenA == nLenB then
		for i = 1, nLenA do
			local nA = string.byte(a, i)
			local nB = string.byte(b, i)
			if nA ~= nB then
				return nA < nB
			end
		end
		return false
	else
		return nLenA < nLenB
	end

end

string.getCharLen = function(str)
    local realByteCount=#str
    local length=0
    local curBytePos=1
    while(true) do
        local step=1 --遍历字节的递增值
        local byteVal=string.byte(str,curBytePos)
		if not byteVal then
			break
		end

        if byteVal>239 then
            step=4
        elseif byteVal>223 then
            step=3
        elseif byteVal>191 then
            step=2
        else
            step=1
        end
        curBytePos=curBytePos+step
        length=length+1
        if curBytePos>realByteCount then
            break
        end
    end
    return length
end

---------------------------------------------------------------------
-- 完善/重载string库 直接从剑三挪过来的 = =||
---------------------------------------------------------------------
function string.escape(s)
	return (s:gsub('([%(%)%.%%%+%-%*%?%[%^%$%]])', '%%%1'))
end

function string.trim(s, s1)
	s1 = s1 and s1:escape() or "%s"
	return (s:gsub("^[" .. s1 .. "]*(.-)[" .. s1 .. "]*$", "%1"))
end

do local m_simpleMatchCache = setmetatable({}, { __mode = "v" })
function string.simpleMatch(szText, szFind, bDistinctCase, bDistinctEnEm, bIgnoreSpace)
	if not bDistinctCase then
		szFind = szFind:lower()
		szText = szText:lower()
	end
	--if not bDistinctEnEm then
		-- szFind = StringEnerW(szFind)
		-- szText = StringEnerW(szText)
	--end
	if bIgnoreSpace then
		szFind = szFind:gsub(" ", "")
		szFind = szFind:gsub(UIStringHelper.GetString("ChineseSpace"), "")
		szText = szText:gsub(" ", "")
		szText = szText:gsub(UIStringHelper.GetString("ChineseSpace"), "")
	end
	local tFind = m_simpleMatchCache[szFind]
	if not tFind then
		tFind = {}
		for _, szKeyWordsLine in ipairs(szFind:split(';', true)) do
			local tKeyWordsLine = {}
			for _, szKeyWords in ipairs(szKeyWordsLine:split(',', true)) do
				local tKeyWords = {}
				for _, szKeyWord in ipairs(szKeyWords:split('|', true)) do
					tinsert(tKeyWords, szKeyWord)
				end
				tinsert(tKeyWordsLine, tKeyWords)
			end
			tinsert(tFind, tKeyWordsLine)
		end
		m_simpleMatchCache[szFind] = tFind
	end
	-- 10|十人,血战天策|XZTC,!小铁被吃了,!开宴黑铁;大战
	local bKeyWordsLine = false
	for _, tKeyWordsLine in ipairs(tFind) do         -- 符合一个即可
		-- 10|十人,血战天策|XZTC,!小铁被吃了,!开宴黑铁
		local bKeyWords = true
		for _, tKeyWords in ipairs(tKeyWordsLine) do -- 必须全部符合
			-- 10|十人
			local bKeyWord = false
			for _, szKeyWord in ipairs(tKeyWords) do  -- 符合一个即可
				-- szKeyWord = MY.String.PatternEscape(szKeyWord) -- 用了wstring还Escape个捷豹
				if szKeyWord:sub(1, 1) == "!" then              -- !小铁被吃了
					szKeyWord = szKeyWord:sub(2)
					if not wstring.find(szText, szKeyWord) then
						bKeyWord = true
					end
				else                                                    -- 十人   -- 10
					if wstring.find(szText, szKeyWord) then
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

function string.pure_text(sz)
	local t = {}
	sz = string.gsub(sz, "\\\n", "\n")	-- 策划要求兼容配置表中字符串"\\n"填成"\\\n"的情况
	--for v in string.gmatch(sz, "text=\"([^\"]+)") do
	for v in string.gmatch(sz, "text=\"(.-)\"") do
		table.insert(t, v)
	end
	local ret = table.concat(t)
	return ret
end

function string.starts(szStr, szStart)
	if szStr == nil or szStart == nil then
		return
	end

	return string.sub(szStr, 1, string.len(szStart)) == szStart
 end

 function string.ends(szStr, szEnd)
	if szStr == nil or szEnd == nil then
		return
	end

	return szEnd == '' or string.sub(szStr, -string.len(szEnd))==szEnd
 end

--************************************table 扩展***************************************
-- table 是否为{}
function table.is_empty(t)
	return _G.next(t) == nil
end
-- table 是否包含对应的key
function table.contain_key(tb, key)
	if not tb or not key then return false end
	for k, _ in pairs(tb) do
		if k == key then return true end
	end
	return false
end

function table.contain_value_CheckByFunction(tb,fn)
	if not tb or not fn then
		return
	end

	for _,v in pairs(tb) do
		if fn(v) then
			return true
		end
	end

end
-- table 是否包含一个 value
function table.contain_value(tb, value)
	if not tb or not value then return false end
	for i, v in pairs(tb) do
		if v == value then return true, i end
	end
	return false
end

function table.find_if(tb, func)
	if not tb or not func then return end
	for k, v in pairs(tb) do
		if func(v) then return v, k end
	end
end

-- 获取table中元素的个数
function table.get_len(t)
	if not t then return 0 end
	local nLen = 0
	for _, _ in pairs(t) do
		nLen = nLen + 1
	end
	return nLen
end
-- 在一个table后面添加另一个table中的元素
function table.insert_tab(tbDest, tbInsert)
	if not tbDest or not tbInsert then LOG.ERROR("table.insert_tab get nil param") return end
	for _, v in ipairs(tbInsert) do
		table.insert(tbDest, v)
	end
end

-- 在一个table后面添加另一个table中的元素 使用pairs
function table.insert_tab_pairs(tbDest, tbInsert)
	if not tbDest or not tbInsert then LOG.ERROR("table.insert_tab_pairs get nil param") return end
	for _, v in pairs(tbInsert) do
		table.insert(tbDest, v)
	end
end

-- 获取一个value在table中的key
function table.get_key(tb, value)
	if not tb or not value then LOG.ERROR("table.get_key get nil param") return end
	for k, v in pairs(tb) do
		if v == value then
			return k
		end
	end
end

--删除一个值为value的项，返回true表示由元素被删除
function table.remove_value(tb,value)
	if not tb or not value then LOG.ERROR("table.remove_value get nil param") return end
	for i,v in pairs(tb) do
		if v == value then
			table.remove(tb,i)
			return true
		end
	end
end

--对数组table的元素顺序随机打乱
function table.random_sort(tb)
	if not tb or #tb <= 0 then return end

	for i = 1, #tb do
		local v1 = tb[i]
		local index = math.random(1, #tb)
		if tb[index] then
			tb[i] = tb[index]
			tb[index] = v1
		end
	end
end

function table.Keys(tb)
	local tindex = {}
	for i,_ in pairs(tb) do
		tinsert(tindex,i)
	end
	return tindex
end

table.to_sort = function(t)
	local newTab = {}
	for k, v in pairs(t) do
		table.insert(newTab, {___key = k, ___value = v})
	end
	table.sort(newTab, function(a, b)
		return string.is_less(a.___key, b.___key)
	end)
	return newTab
end

function table.unpack(tb)
	return tb[1],tb[2],tb[3],tb[4],tb[5],tb[6],tb[7],tb[8],tb[9],tb[10],tb[11],tb[12],tb[13],tb[14],tb[15],tb[16],tb[17],tb[18],tb[19],tb[20]
end

function table.toString(tb)
	local str =  "{ "
	str = str.."\n"
	for k, v in pairs(tb) do
	   if type(v) ~= "table" then
		   str = str.."[\""..k.."\"]"
		   str = str.."="
		   str = str..v
		   str = str..","
		   str = str.."\n"
	   else
		   str = str.."[\""..k.."\"]"
		   str = str.."="
		   str = str..table.toString(v)
		   str = str..","
		   str = str.."\n"
	   end
	end
	str = string.sub(str, 1, -3)
	str = str.."\n"
	str = str .." }"
	return str
end

function table.deepCompare(t1, t2, visited)
	visited = visited or {}

    if t1 == nil and t2 == nil then
        return true
    end

    if t1 == nil or t2 == nil then
        return false
    end

    if type(t1) ~= type(t2) then
        return false
    end

    -- 如果是table，则进行深度比较
    if type(t1) == "table" then
        -- 防止循环引用
        if visited[t1] then
            return visited[t1] == t2
        end
        visited[t1] = t2

        local t1n = #t1
        local t2n = #t2
        if t1n ~= t2n then
            return false
        end

        -- 遍历table的键值对进行比较
        for k1, v1 in pairs(t1) do
            local v2 = t2[k1]
            if not table.deepCompare(v1, v2, visited) then
                return false
            end
        end

        return true
    else
        return t1 == t2
    end
end


--************************************os 扩展***************************************
function os.sleep(n)
	local t = os.clock()
	while os.clock() - t <= n do end
end
function os.date_utc(format, time)
	time = time - 3600 * 8
	return os.date(format, time)
end
--************************************math 扩展***************************************
function math.random_probability(tbProbability)
	local nTotalProb = 0
	for _, nProb in pairs(tbProbability) do
		nTotalProb = nTotalProb + nProb
	end

	local nRand = math.random(1, nTotalProb)
	local nCurProb = 0
	for i, nProb in pairs(tbProbability)  do
		nCurProb = nCurProb + nProb
		if nCurProb >= nRand then
			return i
		end
	end
	return 1
end
--***************************************************************************

-- 剔除特殊字符
function Lib.FilterSpecString(s)
	local ss = {}
	for k = 1, #s do
		local c = string.byte(s,k)
		if not c then break end
		if (c>=48 and c<=57) or (c>= 65 and c<=90) or (c>=97 and c<=122) then
			table.insert(ss, string.char(c))
		elseif c>=228 and c<=233 then
			local c1 = string.byte(s,k+1)
			local c2 = string.byte(s,k+2)
			if c1 and c2 then
				local a1,a2,a3,a4 = 128,191,128,191
				if c == 228 then a1 = 184
				elseif c == 233 then a2,a4 = 190,c1 ~= 190 and 191 or 165
				end
				if c1>=a1 and c1<=a2 and c2>=a3 and c2<=a4 then
					k = k + 2
					table.insert(ss, string.char(c,c1,c2))
				end
			end
		end
	end
	return table.concat(ss)
end

function Lib.IsNullOrZero(value)
	if not value or value == 0 then
		return true
	end
	return false
end
--Table的拷贝
function Lib.copyTab(st)
	local tab = {}
	for k, v in pairs(st or {}) do
		if type(v) ~= "table" then
			tab[k] = v
		else
			tab[k] = Lib.copyTab(v)
		end
	end
	return tab
end

function Lib.ShadowCopyTab(st,dst)

	local tab = dst
	if not tab then
		tab = {}
	end

	if st then
		for k,v in pairs(st) do
			tab[k] = v
		end
	end

	return tab
end

--***********************************时间相关***********************************

-- 获取当天的秒数 如今天0点0分1秒时返回1
function Lib.GetTodaySec(nTime)
	nTime = nTime or os.time()
	local date = os.date("*t", nTime)
	return date.hour * 3600 + date.min * 60 + date.sec
end

-- 获取上一个凌晨5点的时间戳
function Lib.GetLastResetTime(nTime)
	nTime = nTime or os.time()
	local nTodayPassTime = Lib.GetTodaySec(nTime)

	if nTodayPassTime < 18000 then
		nTime = nTime - nTodayPassTime - 68400
	else
		nTime = nTime - nTodayPassTime + 18000
	end

	return nTime
end

-- 获取星期几
function Lib.GetWeekday(nTime)
	nTime = nTime or os.time()
	local weekDay = os.date("*t", nTime).wday - 1
	if weekDay == 0 then
		weekDay = 7
	end
	return weekDay
end

-- 获取当周已过的秒数
function Lib.GetWeekSec(nTime)
	nTime = nTime or os.time()
	return (Lib.GetWeekday(nTime) - 1) * 86400 + Lib.GetTodaySec(nTime)
end

-- 获取本地时区
function Lib.GetLocalUTC()
	return 3600 * tonumber(os.date("%z", 0))/100
end

-- 获取从1970-01-01 开始到现在过了多少天 1970-01-01 是第1天
function Lib.GetDay(nTime)
	nTime = nTime or os.time()
	local sec = nTime + Lib.GetLocalUTC()
	return math.ceil((sec + 1) / 86400)
end

-- 获取从1970-01-01 开始到现在过了多少周 1970-01-01是第1周
function Lib.GetWeek(nTime)
	nTime = nTime or os.time()
	local day = Lib.GetDay(nTime)
	if day < 5 then
		return 1
	else
		return math.ceil((day + 3) / 7)
	end
end

-- 数组table反序
function Lib.ReverseTable(tab)
	local tmp = {}
	local nLen = tab and #tab or 0
	for i = 1, nLen do
		local key = nLen
		tmp[i] = table.remove(tab)
	end

	return tmp
end

--防止被0除的通用函数
function Lib.SafeDivision(numerator, denominator)
	local result = 0

	if numerator == nil or type(numerator) ~= "number" then
		return result
	end

	if denominator == nil or type(denominator) ~= "number" then
		return result
	end

	if denominator == 0 then
		return result
	end

	result = numerator / denominator

	return result
end

-- 从文件中加载文本
function Lib.GetStringFromFile(szFile)
	--NOTE: 不用getStringFromFile接口是因为该接口不能判断文件是否存在
	-- 文件不存在时仍返回""
	local text = cc.FileUtils:getInstance():getDataFromFile(szFile)
	if not text or #text < 3 then
		return text
	end

	-- 去除 utf8-bom
	if string.byte(text, 1) == 0xEF and
		string.byte(text, 2) == 0xBB and
		string.byte(text, 3) == 0xBF then
		text = string.sub(text, 4)
	end
	return text
end

function Lib.WriteStringToFile(szContent, szFullPath)
	if not szFullPath then
		LOG.ERROR("Lib.WriteStringToFile error!szFullPath is nil")
		return
	end
	szContent = szContent or ""
    cc.FileUtils:getInstance():writeStringToFile(szContent, szFullPath)
end

-- 判断文件是否存在
function Lib.IsFileExist(szFile, bPopupNotify)
	if bPopupNotify == false then
		cc.FileUtils:getInstance():setPopupNotify(false)
		local bResult = cc.FileUtils:getInstance():isFileExist(szFile)
		cc.FileUtils:getInstance():setPopupNotify(true)
		return bResult
	end

	return cc.FileUtils:getInstance():isFileExist(szFile)
end

function Lib.IsPNGFileExist(szFile)
	return cc.FileUtils:getInstance():isPNGFileExist(szFile)
end

-- 判断文件夹是否存在
function Lib.IsDirectoryExist(szFile, bPopupNotify)
	local bOriginal = cc.FileUtils:getInstance():isPopupNotify()
	local bNow = bOriginal
	if IsBoolean(bPopupNotify) then
		bNow = bPopupNotify
	end

	cc.FileUtils:getInstance():setPopupNotify(bNow)
	local bResult = cc.FileUtils:getInstance():isDirectoryExist(szFile)
	cc.FileUtils:getInstance():setPopupNotify(bOriginal)

	return bResult
end

-- 删除指定文件
function Lib.RemoveFile(szFile)
	szFile = szFile or ""
	szFile = string.gsub(szFile, "\\\\", "/")
	szFile = string.gsub(szFile, "\\", "/")
	cc.FileUtils:getInstance():removeFile(szFile)
end

-- 删除指定文件夹
function Lib.RemoveDirectory(szDir)
	szDir = szDir or ""
	szDir = string.gsub(szDir, "\\\\", "/")
	szDir = string.gsub(szDir, "\\", "/")
	local tbFiles = Lib.ListFiles(szDir , true)
	for _, szFile in ipairs(tbFiles) do
		Lib.RemoveFile(szFile)
	end
	return cc.FileUtils:getInstance():removeDirectory(szDir)
end

-- 遍历指定目录下的所有文件
function Lib.ListFiles(szDir , bRecursively)
	szDir = szDir or ""
	szDir = string.gsub(szDir, "\\\\", "/")
	szDir = string.gsub(szDir, "\\", "/")
	if bRecursively then
		return cc.FileUtils:getInstance():listFilesRecursively(szDir)
	else
		return cc.FileUtils:getInstance():listFiles(szDir)
	end
end

-- 获取目标文件的大小
function Lib.GetFileSize(szDir)
	szDir = szDir or ""
	szDir = string.gsub(szDir, "\\\\", "/")
	szDir = string.gsub(szDir, "\\", "/")

	if not Lib.IsFileExist(szDir, false) then
		return 0
	end

	return cc.FileUtils:getInstance():getFileSize(szDir)
end

function Lib.SafeCall(callback)
	if IsFunction(callback) then
		return callback()
	end
end

function Lib.StringFind(str1, str2)
	str2 = string.gsub(str2, "([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
	return string.find(str1, str2)
end

-- 小小补丁，Android 大小写敏感
function Lib.GetPersistancePath()
	if not Lib.szPersistentPath then
		local szmui = GetFullPath("mui")
		local pos = string.find(szmui, "mui", 1, true) 
		if pos then
			Lib.szPersistentPath = string.sub(szmui, 1, pos - 1)
		end
	end

    return Lib.szPersistentPath
end

function Lib.RemovePersistancePath(fullPath)
	
	local basePath = Lib.GetPersistancePath()
	if string.is_nil(basePath) then
		return fullPath
	end

    if string.sub(basePath, -1) ~= "/" then
        basePath = basePath .. "/"
    end
    
    if string.sub(fullPath, 1, #basePath) == basePath then
        return string.sub(fullPath, #basePath + 1)
    end

    return fullPath
end


---------------------------------CPath--------------------------------
CPath = CPath or {}

function CPath.GetFileName(szPath)
	if string.is_nil(szPath) then return "" end

	local tbStr = string.split(szPath, '\\')
	if #tbStr <= 1 then
		tbStr = string.split(szPath, '/')
	end
	local szFileName = tbStr[#tbStr]
	if string.match(szFileName, ".+()%.%w+$") > 0 then
		szFileName = string.sub(szFileName, 1, string.match(szFileName, ".+()%.%w+$") - 1)
	end

	return szFileName
end


function CPath.MakeDir(szPath)
	if string.is_nil(szPath) then return "" end

	if Platform.IsAndroid() then
		szPath = Lib.RemovePersistancePath(szPath)
    end
	if not Lib.IsDirectoryExist(szPath) then
		cc.FileUtils:getInstance():createDirectory(szPath)
	end
end

-----------------------------------------------------------------------------------
local function FormatPath(file)
	if file:find("${account}", nil, true) then
		file = file:gsub("%${account}", GetUserAccount() or "")
	end
	if file:find("${region}", nil, true) or file:find("${server}", nil, true) then
		local szRegion, szServer = select(5, GetUserServer())
		file = file:gsub("%${region}", (szRegion:gsub("[/\\]", "")))
		file = file:gsub("%${server}", (szServer:gsub("[/\\]", "")))
	end
	if file:find("${name}", nil, true) then
		file = file:gsub("%${name}", UI_GetClientPlayerName())
	end
	if file:find("${uid}", nil, true) then
		local me = GetClientPlayer()
		assert(me, "Client player not exist!")
		file = file:gsub("%${uid}", me.GetGlobalID())
	end
	return file
end

function LoadLUAData(szPath, options, crc, retenv, bUserParser)
	local OPTIONS = {
		indent = nil,
		crc = false,
		compress = false,
		passphrase = nil,
	}

	local OPTIONS_META = { __index = OPTIONS }

	szPath = FormatPath(szPath)

	if type(options) ~= 'table' then
		options = {
			pak = options,
			crc = crc,
			retenv = retenv,
		}
	end
	setmetatable(options, OPTIONS_META)

	local data = LoadDataFromFile(szPath)
	if data then
		if options.crc or crc or IsEncodedData(data) then
			data = DecodeData(data)
		end
		if data then
			if bUserParser then
				if data:find("return ") == 1 then
					data = data:gsub("return ", "")
				end
				data = parse_string_to_lua_table(data)
			else
				local env = options.env or {}
				data = str2var(data, env, true)
				if options.retenv then
					data = env
				elseif data == nil then
					data = env.data
				end
			end
		end
	else
		LOG.ERROR("LoadLUAData ERROR! szPath:%s", tostring(szPath))
	end
	return data
end

-- file需要UTF8
function SaveLUAData(file, data, options, crc)

	local OPTIONS = {
		indent = nil,
		crc = true,
		compress = false,
		passphrase = nil,
	}
	local OPTIONS_META = { __index = OPTIONS }

	file = FormatPath(file)
	if type(options) ~= 'table' then
		options = {
			indent = options,
			crc = crc,
		}
	end
	setmetatable(options, OPTIONS_META)
	data = 'return ' .. var2str(data, options.indent, nil)
	if options.crc or options.compress then
		data = EncodeData(data, options.crc, options.compress)
	end
	if options.passphrase then
		data = SaveDataToFile(data, file, options.passphrase)
	else
		data = SaveDataToFile(data, file)
	end
	setmetatable(options, nil)
	return data
end

function GetEditorString()
	return ""
end

function LoadScriptFile(szPath, tEnv)
    local luaCodeString = Lib.GetStringFromFile(szPath)

	if not luaCodeString then
		LOG.ERROR("LoadScriptFile loadstring failed: %s", tostring(szPath))
		return
	end

    local fn, szError = loadstring(luaCodeString)
    if not fn then
        LOG.ERROR("LoadScriptFile loadstring failed: %s\n%s", szPath, szError)
        return
    end
    -- 在封闭环境内执行
    setmetatable(tEnv, {__index = _G})
    setfenv(fn, tEnv)
    local isOk, ret = pcall(fn)
    if not isOk then
        LOG.ERROR("LoadScriptFile pcall failed: %s\n%s", szPath, ret)
        return
    end
end

function gettimezone()
	local now = os.time()
	return os.difftime(now, os.time(os.date("!*t", now)))
end

-- 替换文件名的后缀功能
-- filename: 原始文件名（如 "abc123.tag"）
-- newExt: 新后缀（如 "png" 或 ".png"，函数会自动处理）
function replaceExtension(filename, newExt)
    -- 处理新后缀，确保不以点开头
    if string.sub(newExt, 1, 1) == "." then
        newExt = string.sub(newExt, 2)
    end

    -- 找到最后一个点之前的部分（基本文件名）
    local base = filename:match("(.+)%.[^.]*$")
    if base then
        return base .. "." .. newExt
    else
        -- 如果文件名中没有点，则直接添加新后缀
        return filename .. "." .. newExt
    end
end



return Lib

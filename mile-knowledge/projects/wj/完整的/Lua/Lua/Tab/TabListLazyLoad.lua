
local tbSkipTab = {
	--["UIXXXTab"] = true,
}

local function InitModule(tm)
	BeginSample("TabListLazyLoad.InitModule")
	local szModule = tm._szModule
	_G[szModule] = nil

	require(tm._szPath)

	-- 临时屏蔽，后期纳入打包流程，手机版本采用优化过后的表
	-- local optimizedLua = string.format("%s_optimized.lua", string.sub(tm._szPath, 1, -5))
	-- if Lib.IsFileExist(optimizedLua) then
	-- 	require(optimizedLua)
	-- else
	-- 	require(tm._szPath)
	-- end

	tm._loaded = true
	EndSample()
	return _G[szModule] or {}
end

local TabMT =
{
	__index = function(tm, key)
		if not tm._loaded then
			tm._tab = InitModule(tm)
		end
		return tm._tab[key]
	end,
	__pairs = function(tm)
		local t = InitModule(tm)
		return pairs(t)
	end,

    __ipairs = function(tm)
		local t = InitModule(tm)
		return ipairs(t)
	end,

	__len = function(tm)
		if not tm._loaded then
			tm._tab = InitModule(tm)
		end
		return #tm._tab
	end
}

local function InitTab(tbList)
	for szModule, szPath in pairs(tbList) do
		if not tbSkipTab[szModule] then
			local t = {}
			_G[szModule] = t
			t._szModule = szModule
			t._szPath = szPath
			t._loaded = false
			setmetatable(t, TabMT)
		end
	end
end

require("Lua/Tab/TabList.lua")
require("Lua/Tab/CustomTabList.lua")

InitTab(TabList)
InitTab(CustomTabList)

-- for _, szTabPath in pairs(TabList) do
--     require(szTabPath)
-- end

-- for _, szTabPath in pairs(CustomTabList) do
--     require(szTabPath)
-- end
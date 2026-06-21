--------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 基础函数枚举
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------

local _NAME_SPACE_            = 'MY'

-------------------------------------------------------------------------------------------------------
-- 通用函数
-------------------------------------------------------------------------------------------------------
-----------------------------------------------
-- 判断是否为空
-----------------------------------------------
local function IsEmpty(var)
	local szType = type(var)
	if szType == 'nil' then
		return true
	elseif szType == 'boolean' then
		return var
	elseif szType == 'number' then
		return var == 0
	elseif szType == 'string' then
		return var == ''
	elseif szType == 'function' then
		return false
	elseif szType == 'table' then
		for _, _ in pairs(var) do
			return false
		end
		return true
	else
		return false
	end
end
-----------------------------------------------
-- 深度判断相等
-----------------------------------------------
local function IsEquals(o1, o2)
	if o1 == o2 then
		return true
	elseif type(o1) ~= type(o2) then
		return false
	elseif type(o1) == 'table' then
		local t = {}
		for k, v in pairs(o1) do
			if IsEquals(o1[k], o2[k]) then
				t[k] = true
			else
				return false
			end
		end
		for k, v in pairs(o2) do
			if not t[k] then
				return false
			end
		end
		return true
	end
	return false
end
-----------------------------------------------
-- 基础类型判断
-----------------------------------------------
local function IsArray(var)
	if type(var) ~= 'table' then
		return false
	end
	local i = 1
	for k, _ in pairs(var) do
		if k ~= i then
			return false
		end
		i = i + 1
	end
	return true
end
local function IsDictionary(var)
	if type(var) ~= 'table' then
		return false
	end
	local i = 1
	for k, _ in pairs(var) do
		if k ~= i then
			return true
		end
		i = i + 1
	end
	return false
end
local function IsNil     (var) return type(var) == 'nil'      end
local function IsTable   (var) return type(var) == 'table'    end
local function IsNumber  (var) return type(var) == 'number'   end
local function IsString  (var) return type(var) == 'string'   end
local function IsBoolean (var) return type(var) == 'boolean'  end
local function IsFunction(var) return type(var) == 'function' end
local function IsUserdata(var) return type(var) == 'userdata' end
local function IsHugeNumber(var) return IsNumber(var) and not (var < math.huge and var > -math.huge) end
local function IsElement(element) return type(element) == 'table' and element.IsValid and element:IsValid() or false end

---------------------------------------------------------------------------------------------
local X = {
	IsArray          = IsArray         ,
	IsDictionary     = IsDictionary    ,
	IsEquals         = IsEquals        ,
	IsNil            = IsNil           ,
	IsBoolean        = IsBoolean       ,
	IsNumber         = IsNumber        ,
	IsUserdata       = IsUserdata      ,
	IsHugeNumber     = IsHugeNumber    ,
	IsElement        = IsElement       ,
	IsEmpty          = IsEmpty         ,
	IsString         = IsString        ,
	IsTable          = IsTable         ,
	IsFunction       = IsFunction      ,
}
_G[_NAME_SPACE_] = X
---------------------------------------------------------------------------------------------

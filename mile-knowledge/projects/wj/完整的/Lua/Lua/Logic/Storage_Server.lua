------------------------------------------
-- 数据储存模块（存储在服务器上的数据）
------------------------------------------
Storage_Server = Storage_Server or {}
local fnOldGetUserPreferences = GetUserPreferences
local self = Storage_Server

local GetUserPreferences = function(pos, types, bPak)
	return fnOldGetUserPreferences(pos, types, bPak)
end

local DATA_TYPE_LEN = {
	['d'] = 4,
	['n'] = 4,
	['c'] = 1,
	['b'] = 1,
	['w'] = 2,
	['f'] = 4,
}

local USER_PREFERENCES_VERSION = 1
local l_ready = false

-------------------------------------------------
-- Name               Bit        Range
-------------------------------------------------
-- BitValue           1          0 - 1
-- MicroValue         2          0 - 3
-- MiniValue          4          0 - 15
-- XBitValue          X          0 - 2^X - 1
-- c                  8          0 - 255
-- w                  16         0 - 65535
-- n                  32         0 - 4294967295
-------------------------------------------------
local BIT_NUMBER = 8

local function GetBitValue(tData) -- 1 Bit (0 - 1)
	local pos = math.floor(tData.startPos)
	local offset = BIT_NUMBER - (tData.startPos - pos) * BIT_NUMBER
	local byte = GetUserPreferences(pos, "c", false, tData.bALLTerminal)
	return GetNumberBit(byte, offset)
end

local function SetBitValue(tData, value) -- 1 Bit (0 - 1)
	local pos = math.floor(tData.startPos)
	local offset = BIT_NUMBER - (tData.startPos - pos) * BIT_NUMBER
	local byte = GetUserPreferences(pos, "c")
	byte = SetNumberBit(byte, offset, value)
	return SetUserPreferences(pos, "c", byte)
end

local function GetMicroValue(tData) -- 2 Bit (0 - 3)
	local value = 0
	for i = 0, 1 do
		local startPos = tData.startPos + i / BIT_NUMBER
		local pos = math.floor(startPos)
		local offset = BIT_NUMBER - (startPos - pos) * BIT_NUMBER
		local byte = GetUserPreferences(pos, "c", false, tData.bALLTerminal)
		local bit = GetNumberBit(byte, offset)
		value = SetNumberBit(value, 2 - i, bit)
	end
	return value + tData.offset
end

local function SetMicroValue(tData, value) -- 2 Bit (0 - 3)
	value = value - tData.offset
	for i = 0, 1 do
		local startPos = tData.startPos + i / BIT_NUMBER
		local pos = math.floor(startPos)
		local offset = BIT_NUMBER - (startPos - pos) * BIT_NUMBER
		local byte = GetUserPreferences(pos, "c")
		local bit = GetNumberBit(value, 2 - i)
		byte = SetNumberBit(byte, offset, bit)
		SetUserPreferences(pos, "c", byte)
	end
end

local function GetMiniValue(tData) -- 4 Bit (0 - 15)
	local value = 0
	for i = 0, 3 do
		local startPos = tData.startPos + i / BIT_NUMBER
		local pos = math.floor(startPos)
		local offset = BIT_NUMBER - (startPos - pos) * BIT_NUMBER
		local byte = GetUserPreferences(pos, "c", false, tData.bALLTerminal)
		local bit = GetNumberBit(byte, offset)
		value = SetNumberBit(value, 4 - i, bit)
	end
	return value + tData.offset
end

local function SetMiniValue(tData, value) -- 4 Bit (0 - 15)
	value = value - tData.offset
	for i = 0, 3 do
		local startPos = tData.startPos + i / BIT_NUMBER
		local pos = math.floor(startPos)
		local offset = BIT_NUMBER - (startPos - pos) * BIT_NUMBER
		local byte = GetUserPreferences(pos, "c")
		local bit = GetNumberBit(value, 4 - i)
		byte = SetNumberBit(byte, offset, bit)
		SetUserPreferences(pos, "c", byte)
	end
end

local function GetXBitValue(tData) -- X Bit [0, 2 ^ X - 1]
	local value, xbit = 0, tData.bytes * 8
	for i = 0, xbit - 1 do
		local startPos = tData.startPos + i / BIT_NUMBER
		local pos = math.floor(startPos)
		local offset = BIT_NUMBER - (startPos - pos) * BIT_NUMBER
		local byte = GetUserPreferences(pos, "c" , false, tData.bALLTerminal)
		local bit = GetNumberBit(byte, offset)
		value = SetNumberBit(value, xbit - i, bit)
	end
	return value + tData.offset
end

local function SetXBitValue(tData, value) -- X Bit [0, 2 ^ X - 1]
	value = value - tData.offset
	local xbit = tData.bytes * 8
	for i = 0, xbit - 1 do
		local startPos = tData.startPos + i / BIT_NUMBER
		local pos = math.floor(startPos)
		local offset = BIT_NUMBER - (startPos - pos) * BIT_NUMBER
		local byte = GetUserPreferences(pos, "c")
		local bit = GetNumberBit(value, xbit - i)
		byte = SetNumberBit(byte, offset, bit)
		SetUserPreferences(pos, "c", byte)
	end
end

local function GetBoolArrayValue(tData, index)
	index = index - 1 
	local startPos = tData.startPos + index / BIT_NUMBER
	if startPos < tData.startPos or startPos - tData.startPos >= tData.bytes * tData.n then
		LOG.ERROR("[Storage_Server] Index out of bounds! " .. index)
		return
	end
	local pos = math.floor(startPos)
	local offset = BIT_NUMBER - (startPos - pos) * BIT_NUMBER
	local byte = GetUserPreferences(pos, "c", false, tData.bALLTerminal)
	return GetNumberBit(byte, offset)
end

local function SetBoolArrayValue(tData, index, value)
	index = index - 1 
	local startPos = tData.startPos + index / BIT_NUMBER
	if startPos < tData.startPos or startPos - tData.startPos >= tData.bytes * tData.n then
		LOG.ERROR("[Storage_Server] Index out of bounds! " .. index)
		return
	end
	local pos = math.floor(startPos)
	local offset = BIT_NUMBER - (startPos - pos) * BIT_NUMBER
	local byte = GetUserPreferences(pos, "c")
	byte = SetNumberBit(byte, offset, value)
	return SetUserPreferences(pos, "c", byte)
end

local function GetArrayValue(tData, index)
	index = index - 1 
	local startPos = tData.startPos
	local pos = startPos + tData.bytes * index

	if pos < startPos or pos - startPos >= tData.bytes * tData.n then
		LOG.ERROR("[Storage_Server] Index out of bounds! " .. index)
		return
	end

	return GetUserPreferences(pos, tData.type, false, tData.bALLTerminal)
end

local function SetArrayValue(tData, index, ...)
	index = index - 1 
	local startPos = tData.startPos
	local pos = startPos + tData.bytes * index

	if pos < startPos or pos - startPos >= tData.bytes * tData.n then
		LOG.ERROR("[Storage_Server] Index out of bounds! " .. index)
		return
	end

	return SetUserPreferences(pos, tData.type, ...)
end

local function GetChatSettingData(tData, index)
	local pos = tData.startPos + tData.bytes * (index - 1)
	assert(pos >= tData.startPos and pos - tData.startPos < tData.bytes * tData.n, "ChatSetting Index out of bounds!")
	local data = {GetUserPreferences(pos, "cccccccccccccccccccc")}
	local hash = table.remove(data, 1) --byte 1
	local inited = GetNumberBit(hash, 8)
	local enable = GetNumberBit(hash, 7)
	for i, v in ipairs(data) do
		hash = BitwiseXor(hash, v)
	end
	hash = SetNumberBit(hash, 8, false)
	hash = SetNumberBit(hash, 7, false)
	if not (inited and hash == 0) then
		return
	end

	local title
	do local titles = {}
		for i = 1, 9 do --byte 2-10
			local c = table.remove(data, 1)
			if c ~= 0 then
				table.insert(titles, c)
			end

		end
		title = string.char(unpack(titles))
	end

	local chs = {}
	do
		local chs_bits = {}
		for i = 1, 10 do --byte 11-20
			table.insert(chs_bits, table.remove(data, 1))
		end
		for i, c in ipairs(chs_bits) do
			for j = 1, 8 do
				table.insert(chs, GetNumberBit(c, j))
			end
		end
	end

	return enable, title, chs
end

local function SetChatSettingData(tData, index, enable, title, chs)
	local pos = tData.startPos + tData.bytes * (index - 1)
	assert(pos >= tData.startPos and pos - tData.startPos < tData.bytes * tData.n, "ChatSetting Index out of bounds!")
	local data = {}

	do local titles = {string.byte(title, 1, 9)}
		for i = 1, 9 do
			table.insert(data, titles[i] or 0)
		end
	end

	do
		local offset = #data + 1
		for i = 1, 10 do
			table.insert(data, 0)
		end

		for nIndex, bApply in pairs(chs) do
			local i = math.floor((nIndex - 1) / 8) + offset
			local j = nIndex % 8
			j = j == 0 and 8 or j

			if i <= 10 + offset then
				data[i] = SetNumberBit(data[i], j, bApply)
			end
		end
	end

	do local hash = 0
		for i, v in ipairs(data) do
			hash = BitwiseXor(hash, v)
		end
		hash = SetNumberBit(hash, 8, true)
		hash = SetNumberBit(hash, 7, enable)
		table.insert(data, 1, hash)
	end
	return SetUserPreferences(pos, "cccccccccccccccccccc", unpack(data))
end

local function GetActionBarBoxData(tData, index)
	local pos = tData.startPos + tData.bytes * (index - 1)
	assert(pos >= tData.startPos and pos - tData.startPos < tData.bytes * tData.n, "DXActionBar Index out of bounds!")
	local type = GetUserPreferences(pos, "c")
	if type == DX_ACTIONBAR_TYPE.SKILL then
		return DX_ACTIONBAR_TYPE.SKILL, GetUserPreferences(pos + 1, "d")
	elseif type == DX_ACTIONBAR_TYPE.EQUIP then
		return DX_ACTIONBAR_TYPE.EQUIP, GetUserPreferences(pos + 1, "ccc")
	elseif type == DX_ACTIONBAR_TYPE.MACRO then
		return DX_ACTIONBAR_TYPE.MACRO, GetUserPreferences(pos + 1, "d")
	elseif type == DX_ACTIONBAR_TYPE.ITEM_INFO then
		return DX_ACTIONBAR_TYPE.ITEM_INFO, GetUserPreferences(pos + 1, "cd")
	end
end

local function SetActionBarBoxData(tData, index, type, arg1, arg2, arg3)
	local pos = tData.startPos + tData.bytes * (index - 1)
	assert(pos >= tData.startPos and pos - tData.startPos < tData.bytes * tData.n, "DXActionBar Index out of bounds!")
	if type == nil then
		SetUserPreferences(pos, "c", 0)
	else
		if type == DX_ACTIONBAR_TYPE.SKILL then
			SetUserPreferences(pos, "cd", 1, arg1)
		elseif type == DX_ACTIONBAR_TYPE.EQUIP then
			SetUserPreferences(pos, "cccc", 2, arg1, arg2, arg3)
		elseif type == DX_ACTIONBAR_TYPE.MACRO then
			SetUserPreferences(pos, "cd", 3, arg1)
		elseif type == DX_ACTIONBAR_TYPE.ITEM_INFO then
			SetUserPreferences(pos, "ccd", 4, arg1, arg2)
		end
	end
end

------------------------------------------
-- 保存数据列表
------------------------------------------

STORAGE_KEY_ENUM = {
    DXActionBar = "DXActionBar",
    NotFirstEnterGame = "NotFirstEnterGame"
}

STORAGE_DXACTIONBAR_ENUM_LIST = {
	"DXActionBar1", "DXActionBar2", "DXActionBar3", 
	"DXActionBar4", "DXActionBar5", "DXActionBar6"
}


-- 模块批量起始位置索引
local ModelSetPos = 
{
	-- 1 ~ 99 备用
	TeachState    = 100, -- 新手教学状态，100 ~ 399
	TeachVariable = 400, -- 新手教学变量，400 ~ 499
	SkillEquipBinding_1 = 500, -- 心法1武学分页绑定设置变量，500 ~ 515
	SkillEquipBinding_2 = 516, -- 心法2武学分页绑定设置变量，516 ~ 531
	SprintSetting = 532, -- 轻功设置，532 ~ 551
	SprintSettingMaxIndex = 552, --轻功设置最大索引，552
	-- 553 ~ 599 备用
	ShortcutSetting = 600, -- 快捷键，600 ~ 1196
	ShortcutMaxIndex = 1197, -- 快捷键最大索引，1197
	ShortcutVersion = 1198, -- 快捷键版本号，1198
	ChatSetting = 1200, -- 聊天设置，1200 ~ 1599
	--SkillSetNames = 1600, -- 武学套路名称，1600 ~ 1899,已废弃
	SkillSkinLike = 1900, -- 武技图收藏，1900 ~ 1919
	BagBoxLock = 1920, --背包格子锁，1920~1969
	-- 1970 ~ 1999 备用
	DXActionBar1 = 2000, --DX技能存储1，2000~2399（10*40）
	DXActionBar2 = 2400, --DX技能存储2，2400~2799（10*40）
	DXActionBar3 = 2800, --DX技能存储3，2800~3199（10*40）
	DXActionBar4 = 3200, --DX技能存储4，3200~3599（10*40）
	DXActionBar5 = 3600, --DX技能存储5，3600~3999（10*40）
	DXActionBar6 = 4000, --DX技能存储6，4000~4399（10*40）
	
	SkillEquipBindingDX_1 = 4400, -- DX心法1武学分页绑定设置变量，4400~4409（1*10）
	SkillEquipBindingDX_2 = 4410, -- DX心法2武学分页绑定设置变量，4410~4419（1*10）
	SkillEquipBindingDX_3 = 4420, -- DX心法3武学分页绑定设置变量，4420~4429（1*10）
	SkillEquipBindingDX_4 = 4430, -- DX心法4武学分页绑定设置变量，4430~4439（1*10）
	SkillEquipBinding_3 = 4440,   -- vk心法2武学分页绑定设置变量，4440~4455（1*16）
	
	-- 4456
}

local m_dataList = {
	-- 所有的Get函数的输入和Set函数的输出必须一致（数组类Get函数参数与Set函数返回相差一个subkey）
	{ setpos = 1, bytes = 1 / 8, n = 1, key = "NotFirstEnterGame", set_func = SetBitValue, get_func = GetBitValue }, --是否第一次进游戏
	{ setpos = ModelSetPos.TeachState, bytes = 1 / 8, n = 2392, key = "TeachState", set_func = SetBoolArrayValue, get_func = GetBoolArrayValue }, --新手教学状态，每个教学占用1bit，预留2392bit(299bytes)
	{ setpos = ModelSetPos.TeachVariable, bytes = 1 / 8, n = 792, key = "TeachVariable", set_func = SetBoolArrayValue, get_func = GetBoolArrayValue }, --新手教学变量，预留792bit(99bytes)
	{ setpos = ModelSetPos.SkillEquipBinding_1, type = "c", bytes = 1, n = 16, key = "SkillEquipBinding_1", set_func = SetArrayValue, get_func = GetArrayValue }, --武学分页绑定设置变量，预留16bytes
	{ setpos = ModelSetPos.SkillEquipBinding_2, type = "c", bytes = 1, n = 16, key = "SkillEquipBinding_2", set_func = SetArrayValue, get_func = GetArrayValue }, --武学分页绑定设置变量，预留16bytes
	{ setpos = ModelSetPos.SprintSetting, type = "c", bytes = 1, n = 20, key = "SprintSetting", set_func = SetArrayValue, get_func = GetArrayValue }, --轻功设置，预留20bytes
	{ setpos = ModelSetPos.SprintSettingMaxIndex, type = "c", bytes = 1, n = 1, key = "SprintSettingMaxIndex" }, --轻功设置最大索引
	{ setpos = ModelSetPos.ShortcutSetting, type = "ccc", bytes = 3, n = 199, key = "ShortcutSetting", set_func = SetArrayValue, get_func = GetArrayValue }, --快捷键存盘，每个键占1bytes(cc.KeyCode)，按最多3个组合键算和最多199个快捷键计算，预留597bytes
	{ setpos = ModelSetPos.ShortcutMaxIndex, type = "c", bytes = 1, n = 1, key = "ShortcutMaxIndex" }, --快捷键最大索引
	{ setpos = ModelSetPos.ShortcutVersion, type = "c", bytes = 1, n = 1, key = "ShortcutVersion" }, --快捷键版本号
	{ setpos = ModelSetPos.ChatSetting, bytes = 20, n = 20, key = "ChatSetting", set_func = SetChatSettingData, get_func = GetChatSettingData }, -- 聊天设置，预留20个分页频道（ChatSetting现有15个），最多支持2个utf8字符改名+80个频道配置
	{ setpos = ModelSetPos.SkillSkinLike, type = "c", bytes = 1, n = 20, key = "SkillSkinLike", set_func = SetArrayValue, get_func = GetArrayValue }, --装扮秘鉴-武技殊影收藏，20个收藏位置20byte
	{ setpos = ModelSetPos.BagBoxLock, type = "cc", bytes = 2, n = 25, key = "BagBoxLock", set_func = SetArrayValue, get_func = GetArrayValue }, --背包格子锁，一共可以锁25个格子，预留2*25 = 50bytes
	{ setpos = ModelSetPos.DXActionBar1, bytes = 10, n = 40, key = "DXActionBar1", set_func = SetActionBarBoxData, get_func = GetActionBarBoxData}, --DX技能存储1，33个格子，占用10*33 = 330bytes （再多预留一点）预留10*40 = 400bytes
	{ setpos = ModelSetPos.DXActionBar2, bytes = 10, n = 40, key = "DXActionBar2", set_func = SetActionBarBoxData, get_func = GetActionBarBoxData}, --DX技能存储2，33个格子，占用10*33 = 330bytes （再多预留一点）预留10*40 = 400bytes
	{ setpos = ModelSetPos.DXActionBar3, bytes = 10, n = 40, key = "DXActionBar3", set_func = SetActionBarBoxData, get_func = GetActionBarBoxData}, --DX技能存储3，33个格子，占用10*33 = 330bytes （再多预留一点）预留10*40 = 400bytes
	{ setpos = ModelSetPos.DXActionBar4, bytes = 10, n = 40, key = "DXActionBar4", set_func = SetActionBarBoxData, get_func = GetActionBarBoxData}, --DX技能存储4，33个格子，占用10*33 = 330bytes （再多预留一点）预留10*40 = 400bytes
	{ setpos = ModelSetPos.DXActionBar5, bytes = 10, n = 40, key = "DXActionBar5", set_func = SetActionBarBoxData, get_func = GetActionBarBoxData}, --DX技能存储5，33个格子，占用10*33 = 330bytes （再多预留一点）预留10*40 = 400bytes
	{ setpos = ModelSetPos.DXActionBar6, bytes = 10, n = 40, key = "DXActionBar6", set_func = SetActionBarBoxData, get_func = GetActionBarBoxData}, --DX技能存储6，33个格子，占用10*33 = 330bytes （再多预留一点）预留10*40 = 400bytes
	{ setpos = ModelSetPos.SkillEquipBindingDX_1, type = "c", bytes = 1, n = 10, key = "SkillEquipBindingDX_1", set_func = SetArrayValue, get_func = GetArrayValue }, --DX武学方案绑定设置变量，预留10bytes
	{ setpos = ModelSetPos.SkillEquipBindingDX_2, type = "c", bytes = 1, n = 10, key = "SkillEquipBindingDX_2", set_func = SetArrayValue, get_func = GetArrayValue }, --DX武学方案绑定设置变量，预留10bytes
	{ setpos = ModelSetPos.SkillEquipBindingDX_3, type = "c", bytes = 1, n = 10, key = "SkillEquipBindingDX_3", set_func = SetArrayValue, get_func = GetArrayValue }, --DX武学方案绑定设置变量，预留10bytes
	{ setpos = ModelSetPos.SkillEquipBindingDX_4, type = "c", bytes = 1, n = 10, key = "SkillEquipBindingDX_4", set_func = SetArrayValue, get_func = GetArrayValue }, --DX武学方案绑定设置变量，预留10bytes
	{ setpos = ModelSetPos.SkillEquipBinding_3, type = "c", bytes = 1, n = 16, key = "SkillEquipBinding_3", set_func = SetArrayValue, get_func = GetArrayValue }, --武学分页绑定设置变量，预留16bytes

}


------------------------------------------
-- 业务逻辑调用方法
------------------------------------------
local function _Init()
	local pos = 0
	for _, v in ipairs(m_dataList) do
		-- 检查地址冲突
		if v.setpos then
			if v.setpos < pos then
				LOG.ERROR("[Storage_Server]  Setpos must larger than prev pos! setpos(" .. v.setpos .. ") prevpos(" .. pos .. ")")
				return
			else
				pos = v.setpos
			end
		end
        -- 校验数据长度（字符串类型永远默认通过）
		if v.type then
			local bytes = 0
			for i = 1, #v.type do
				local tp = string.char(string.byte(v.type, i))
				if tp == "s" then
					bytes = v.bytes
					break
				end
				local bt = DATA_TYPE_LEN[tp]
				if bt == nil then
					LOG.ERROR("[Storage_Server]  StorageServer@Init#Unknow type: " .. tp)
					return
				else
					bytes = bytes + bt
				end
			end
			if bytes ~= v.bytes then
				LOG.WARN("[Storage_Server]  Storage bytes miss match: key[" .. v.key .. "](" .. v.type .. ") " .. bytes .. " expected, got " .. v.bytes)
			end
		end
		if not v.subkeys and v.n > 1 then
			v.subkeys = {}
			for i = 1, v.n do
				v.subkeys[i] = i
			end
		end
		m_dataList[v.key] = v
		v.offset = v.offset or 0
		v.startPos = pos
		pos = pos + v.bytes * v.n
	end
end

local function _UpdateDataVersion()
	local version = GetUserPreferences(0, "c")
	if version == USER_PREFERENCES_VERSION then
		LOG.INFO("[StorageServer] Check data version finished. Current version is " .. version .. ".")
		if not l_ready then
			l_ready = true
			Event.Dispatch("FIRST_SYNC_USER_PREFERENCES_END")
		end
		Event.Dispatch("SYNC_USER_PREFERENCES_END")
		return
	else
		SetUserPreferences(0, "c", USER_PREFERENCES_VERSION) -- 设置版本号
	end
	_UpdateDataVersion()
end

local function _OnSyncUserPreferencesEnd()

end

function Storage_Server.Init()
    _Init()

    Event.Reg(Storage_Server, "SYNC_ROLE_DATA_END", function ()
        _UpdateDataVersion()
    end)

	Event.Reg(Storage_Server, "SYNC_USER_PREFERENCES_END", function ()
		_OnSyncUserPreferencesEnd()
    end)
end

function Storage_Server.UnInit()
	Event.UnRegAll(Storage_Server)
end

function Storage_Server.GetData(key , ...)
	if not l_ready then
		LOG.ERROR("[Storage_Server]   Not initialized yet! ")
		return
	end
	local tData = m_dataList[key]
	if not tData then
		return
	end

	if tData.get_func then
		return tData.get_func(tData, ...)
	else
		return GetUserPreferences(tData.startPos, tData.type, false, tData.bALLTerminal)
	end
end

function Storage_Server.SetData(key , ...)
	if not l_ready then
		LOG.ERROR("[Storage_Server]   Not initialized yet! ")
		return
	end
	local tData = m_dataList[key]
	if not tData then
		return
	end
	if tData.set_func then
		tData.set_func(tData, ...)
	else
		SetUserPreferences(tData.startPos, tData.type, ...)
	end
end

function Storage_Server.IsReady()
	return l_ready
end

--==== actionbar  =======================

local nUsingSlotNum = 33

--function GetActionBarKey(group, page)
--	local key_fmt = "ActionBar%d_Page%d"
--	return string.format(key_fmt, group, page)
--end

function Storage_Server.ActionBarTask(func, nSpecificIndex)
	local key_fmt = "DXActionBar%d"
	local key
	if nSpecificIndex then
		key = string.format(key_fmt, nSpecificIndex)
		for index = 1, nUsingSlotNum, 1 do
			func(key, index, self.GetData(key, index) )
		end
	else
		for page = 1, 6, 1 do
			key = string.format(key_fmt, page)
			for index = 1, nUsingSlotNum, 1 do
				func(key, index, self.GetData(key, index) )
			end
		end
	end
end

------------------------------------------
-- 测试调用方法
------------------------------------------

-- Storage_Server.HelperAFirstEventID = {
-- 	EnterGame = 1,
-- 	HealthLow = 2,
-- 	EnterFight = 3,
-- 	AcceptQuest = 4,
-- 	Death = 5,
-- }

-- function Storage_Server.TestTeachHelper_IsFirstTimeDo(szName)
-- 	local nEvent = Storage_Server.HelperAFirstEventID[szName]
-- 	LOG.ERROR("StorageServer Helper %s,data:%s",szName , tostring(Storage_Server.GetData("Helper", nEvent)))
-- 	LOG.ERROR("StorageServer Helper %s,data:%s","HealthLow" , tostring(Storage_Server.GetData("Helper", Storage_Server.HelperAFirstEventID["HealthLow"])))
-- 	LOG.ERROR("StorageServer Helper %s,data:%s","EnterFight" , tostring(Storage_Server.GetData("Helper", Storage_Server.HelperAFirstEventID["EnterFight"])))
-- 	LOG.ERROR("StorageServer Helper %s,data:%s","AcceptQuest" , tostring(Storage_Server.GetData("Helper", Storage_Server.HelperAFirstEventID["AcceptQuest"])))
-- 	return not Storage_Server.GetData("Helper", nEvent)
-- end

-- function Storage_Server.TestTeachHelper_SetHasDo(szName)
-- 	local nEvent = Storage_Server.HelperAFirstEventID[szName]
-- 	Storage_Server.SetData("Helper", nEvent, true)
-- end
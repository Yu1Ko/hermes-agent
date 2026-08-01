--------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 游戏环境库
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------

local X = MY

do
local S2L_CACHE = setmetatable({}, { __mode = 'k' })
local L2S_CACHE = setmetatable({}, { __mode = 'k' })
function X.ConvertNpcID(dwID, eType)
    if IsPlayer(dwID) then
        if not S2L_CACHE[dwID] then
            S2L_CACHE[dwID] = { dwID + 0x40000000 }
        end
        return eType == 'short' and dwID or S2L_CACHE[dwID][1]
    else
        if not L2S_CACHE[dwID] then
            L2S_CACHE[dwID] = { dwID - 0x40000000 }
        end
        return eType == 'long' and dwID or L2S_CACHE[dwID][1]
    end
end
end

local NEARBY_NPC = {}      -- 附近的NPC
local NEARBY_PET = {}      -- 附近的PET
local NEARBY_PLAYER = {}   -- 附近的物品
local NEARBY_DOODAD = {}   -- 附近的玩家
local NEARBY_FIGHT = {}    -- 附近玩家和NPC战斗状态缓存

-- 获取指定对象
-- (KObject, info, bIsInfo) X.GetObject([number dwType, ]number dwID)
-- (KObject, info, bIsInfo) X.GetObject([number dwType, ]string szName)
-- dwType: [可选]对象类型枚举 TARGET.*
-- dwID  : 对象ID
-- return: 根据 dwType 类型和 dwID 取得操作对象
--         不存在时返回nil, nil
function X.GetObject(arg0, arg1, arg2)
	local dwType, dwID, szName
	if X.IsNumber(arg0) then
		if X.IsNumber(arg1) then
			dwType, dwID = arg0, arg1
		elseif X.IsString(arg1) then
			dwType, szName = arg0, arg1
		elseif X.IsNil(arg1) then
			dwID = arg0
		end
	elseif X.IsString(arg0) then
		szName = arg0
	end
	if not dwID and not szName then
		return
	end

	if dwID and not dwType then
		if NEARBY_PLAYER[dwID] then
			dwType = TARGET.PLAYER
		elseif NEARBY_DOODAD[dwID] then
			dwType = TARGET.DOODAD
		elseif NEARBY_NPC[dwID] then
			dwType = TARGET.NPC
		end
	elseif not dwID and szName then
		local tSearch = {}
		if dwType == TARGET.PLAYER then
			tSearch[TARGET.PLAYER] = NEARBY_PLAYER
		elseif dwType == TARGET.NPC then
			tSearch[TARGET.NPC] = NEARBY_NPC
		elseif dwType == TARGET.DOODAD then
			tSearch[TARGET.DOODAD] = NEARBY_DOODAD
		else
			tSearch[TARGET.PLAYER] = NEARBY_PLAYER
			tSearch[TARGET.NPC] = NEARBY_NPC
			tSearch[TARGET.DOODAD] = NEARBY_DOODAD
		end
		for dwObjectType, NEARBY_OBJECT in pairs(tSearch) do
			for dwObjectID, KObject in pairs(NEARBY_OBJECT) do
				if X.GetObjectName(KObject) == szName then
					dwType, dwID = dwObjectType, dwObjectID
					break
				end
			end
		end
	end
	if not dwType or not dwID then
		return
	end

	local p, info, b
	if dwType == TARGET.PLAYER then
		local me = GetClientPlayer()
		if me and dwID == me.dwID then
			p, info, b = me, me, false
		elseif me and me.IsPlayerInMyParty(dwID) then
			p, info, b = GetPlayer(dwID), GetClientTeam().GetMemberInfo(dwID), true
		else
			p, info, b = GetPlayer(dwID), GetPlayer(dwID), false
		end
	elseif dwType == TARGET.NPC then
		p, info, b = GetNpc(dwID), GetNpc(dwID), false
	elseif dwType == TARGET.DOODAD then
		p, info, b = GetDoodad(dwID), GetDoodad(dwID), false
	elseif dwType == TARGET.ITEM then
		p, info, b = GetItem(dwID), GetItem(dwID), GetItem(dwID)
	end
	return p, info, b
end

-- 根据模板ID获取NPC真实名称
local NPC_NAME_CACHE, DOODAD_NAME_CACHE = {}, {}
function X.GetTemplateName(dwType, dwTemplateID)
	local CACHE = dwType == TARGET.NPC and NPC_NAME_CACHE or DOODAD_NAME_CACHE
	local szName
	if CACHE[dwTemplateID] then
		szName = CACHE[dwTemplateID]
	end
	if not szName then
		if dwType == TARGET.NPC then
			szName = Table_GetNpcTemplateName(dwTemplateID)
		else
			szName = Table_GetDoodadTemplateName(dwTemplateID)
		end
		if szName then
			szName = szName:gsub('^%s*(.-)%s*$', '%1')
		end
		CACHE[dwTemplateID] = szName or ''
	end
	if X.IsEmpty(szName) then
		szName = nil
	end
	return szName
end

-- 获取指定对象的名字
-- X.GetObjectName(obj, eRetID)
-- X.GetObjectName(dwType, dwID, eRetID)
-- (KObject) obj    要获取名字的对象
-- (string)  eRetID 是否返回对象ID信息
--    'auto'   名字为空时返回 -- 默认值
--    'always' 总是返回
--    'never'  总是不返回
local OBJECT_NAME = {
	['PLAYER'   ] = {},
	['NPC'      ] = {},
	['DOODAD'   ] = {},
	['ITEM'     ] = {},
	['ITEM_INFO'] = {},
	['UNKNOWN'  ] = {},
}
function X.GetObjectName(arg0, arg1, arg2, arg3, arg4)
	local KObject, szType, dwID, nExtraID, eRetID
	if X.IsNumber(arg0) then
		local dwType = arg0
		dwID, eRetID = arg1, arg2
		KObject = X.GetObject(dwType, dwID)
		if dwType == TARGET.PLAYER then
			szType = 'PLAYER'
		elseif dwType == TARGET.NPC then
			szType = 'NPC'
		elseif dwType == TARGET.DOODAD then
			szType = 'DOODAD'
		else
			szType = 'UNKNOWN'
		end
	elseif X.IsString(arg0) then
		if arg0 == 'PLAYER' or arg0 == 'NPC' or arg0 == 'DOODAD' then
			if X.IsUserdata(arg1) then
				KObject = arg1
				dwID, eRetID = KObject.dwID, arg2
			else
				local dwType = TARGET[arg0]
				dwID, eRetID = arg1, arg2
				KObject = X.GetObject(dwType, dwID)
				szType = arg0
			end
		elseif arg0 == 'ITEM' then
			if X.IsUserdata(arg1) then
				KObject = arg1
				dwID, eRetID = KObject.dwID, arg2
			elseif X.IsNumber(arg3) then
				local p = GetPlayer(arg1)
				if p then
					KObject = p.GetItem(arg2, arg3)
					if KObject then
						dwID = KObject.dwID
					end
					eRetID = arg4
				end
			elseif X.IsNumber(arg2) then
				local p = GetClientPlayer()
				if p then
					KObject = p.GetItem(arg1, arg2)
					if KObject then
						dwID = KObject.dwID
					end
					eRetID = arg3
				end
			else
				dwID, eRetID = arg1, arg2
				KObject = GetItem(dwID)
			end
			szType = 'ITEM'
		elseif arg0 == 'ITEM_INFO' then
			if X.IsUserdata(arg1) then
				KObject = arg1
				dwID, eRetID = KObject.dwID, arg2
			elseif X.IsNumber(arg3) then
				dwID = arg1 .. ':' .. arg2 .. ':' .. arg3
				nExtraID = arg3
				eRetID = arg4
			else
				dwID = arg1 .. ':' .. arg2
				eRetID = arg3
			end
			KObject = GetItemInfo(arg1, arg2)
			szType = 'ITEM_INFO'
		else
			szType = 'UNKNOWN'
		end
	else
		KObject, eRetID = arg0, arg1
		if KObject then
			szType = X.GetObjectType(KObject)
			if szType == 'ITEM_INFO' then
				dwID = KObject.nGenre .. ':' .. KObject.dwID
			else
				dwID = KObject.dwID
			end
		end
	end
	if not dwID then
		return
	end
	if not eRetID then
		eRetID = 'auto'
	end
	local cache = OBJECT_NAME[szType][dwID]
	if not cache or (KObject and not cache.bFull) then -- 计算获取名称缓存
		local szDispType, szDispID, szName = '?', '', ''
		if KObject then
			szName = KObject.szName
		end
		if not cache then
			cache = { bFull = false }
		end
		if szType == 'PLAYER' then
			szDispType = 'P'
			cache.bFull = not X.IsEmpty(szName)
		elseif szType == 'NPC' then
			szDispType = 'N'
			if KObject then
				if X.IsEmpty(szName) then
					szName = X.GetTemplateName(TARGET.NPC, KObject.dwTemplateID)
				end
				if KObject.dwEmployer and KObject.dwEmployer ~= 0 then
					if Table_IsSimplePlayer(KObject.dwTemplateID) then -- 长歌影子
						szName = X.GetObjectName(GetPlayer(KObject.dwEmployer), eRetID)
					elseif not X.IsEmpty(szName) then
						local szEmpName = X.GetObjectName(
							(IsPlayer(KObject.dwEmployer) and GetPlayer(KObject.dwEmployer)) or GetNpc(KObject.dwEmployer),
							'never'
						)
						if szEmpName then
							cache.bFull = true
						else
							szEmpName = g_tStrings.STR_SOME_BODY
						end
						szName =  szEmpName .. g_tStrings.STR_PET_SKILL_LOG .. szName
					end
				else
					cache.bFull = true
				end
			end
		elseif szType == 'DOODAD' then
			szDispType = 'D'
			if KObject and X.IsEmpty(szName) then
				szName = Table_GetDoodadTemplateName(KObject.dwTemplateID)
				if szName then
					szName = szName:gsub('^%s*(.-)%s*$', '%1')
				end
			end
			cache.bFull = true
		elseif szType == 'ITEM' then
			szDispType = 'I'
			if KObject then
				szName = ItemData.GetItemNameByItem(KObject)
			end
			cache.bFull = true
		elseif szType == 'ITEM_INFO' then
			szDispType = 'II'
			if KObject then
				szName = ItemData.GetItemNameByItemInfo(KObject, nExtraID)
			end
			cache.bFull = true
		else
			szDispType = '?'
			cache.bFull = false
		end
		if szType == 'NPC' then
			szDispID = X.ConvertNpcID(dwID)
			if KObject then
				szDispID = szDispID .. '@' .. KObject.dwTemplateID
			end
		else
			szDispID = dwID
		end
		if X.IsEmpty(szName) then
			szName = nil
		end
		cache['never'] = szName
		if szName then
			cache['auto'] = szName
			cache['always'] = szName .. '(' .. szDispType .. szDispID .. ')'
		else
			cache['auto'] = szDispType .. szDispID
			cache['always'] = szDispType .. szDispID
		end
		OBJECT_NAME[szType][dwID] = cache
	end
	return cache and cache[eRetID] or nil
end

do
local CACHE = {}
function X.GetObjectType(obj)
	if not CACHE[obj] then
		if NEARBY_PLAYER[obj.dwID] == obj then
			CACHE[obj] = 'PLAYER'
		elseif NEARBY_NPC[obj.dwID] == obj then
			CACHE[obj] = 'NPC'
		elseif NEARBY_DOODAD[obj.dwID] == obj then
			CACHE[obj] = 'DOODAD'
		else
			local szStr = tostring(obj)
			if szStr:find('^KGItem:%w+$') then
				CACHE[obj] = 'ITEM'
			elseif szStr:find('^KGLuaItemInfo:%w+$') then
				CACHE[obj] = 'ITEM_INFO'
			elseif szStr:find('^KDoodad:%w+$') then
				CACHE[obj] = 'DOODAD'
			elseif szStr:find('^KNpc:%w+$') then
				CACHE[obj] = 'NPC'
			elseif szStr:find('^KPlayer:%w+$') then
				CACHE[obj] = 'PLAYER'
			else
				CACHE[obj] = 'UNKNOWN'
			end
		end
	end
	return CACHE[obj]
end
end

-- 获取附近NPC列表
-- (table) X.GetNearNpc(void)
function X.GetNearNpc(nLimit)
	local aNpc = {}
	for k, _ in pairs(NEARBY_NPC) do
		local npc = GetNpc(k)
		if not npc then
			NEARBY_NPC[k] = nil
		else
			table.insert(aNpc, npc)
			if nLimit and #aNpc == nLimit then
				break
			end
		end
	end
	return aNpc
end

-- X.BreatheCall(X.NSFormatString('{$NS}#FIGHT_HINT_TRIGGER'), function()
-- 	for dwID, tar in pairs(NEARBY_NPC) do
-- 		if tar.bFightState ~= NEARBY_FIGHT[dwID] then
-- 			NEARBY_FIGHT[dwID] = tar.bFightState
-- 			FireUIEvent(X.NSFormatString('{$NS}_NPC_FIGHT_HINT'), dwID, tar.bFightState)
-- 		end
-- 	end
-- 	for dwID, tar in pairs(NEARBY_PLAYER) do
-- 		if tar.bFightState ~= NEARBY_FIGHT[dwID] then
-- 			NEARBY_FIGHT[dwID] = tar.bFightState
-- 			FireUIEvent(X.NSFormatString('{$NS}_PLAYER_FIGHT_HINT'), dwID, tar.bFightState)
-- 		end
-- 	end
-- end)
-- X.RegisterEvent('NPC_ENTER_SCENE', function()
-- 	local npc = GetNpc(arg0)
-- 	if npc and npc.dwEmployer ~= 0 then
-- 		NEARBY_PET[arg0] = npc
-- 	end
-- 	NEARBY_NPC[arg0] = npc
-- 	NEARBY_FIGHT[arg0] = npc and npc.bFightState or false
-- end)
-- X.RegisterEvent('NPC_LEAVE_SCENE', function()
-- 	NEARBY_PET[arg0] = nil
-- 	NEARBY_NPC[arg0] = nil
-- 	NEARBY_FIGHT[arg0] = nil
-- end)
-- X.RegisterEvent('PLAYER_ENTER_SCENE', function()
-- 	local player = GetPlayer(arg0)
-- 	NEARBY_PLAYER[arg0] = player
-- 	NEARBY_FIGHT[arg0] = player and player.bFightState or false
-- end)
-- X.RegisterEvent('PLAYER_LEAVE_SCENE', function()
-- 	if UI_GetClientPlayerID() == arg0 then
-- 		FireUIEvent(X.NSFormatString('{$NS}_CLIENT_PLAYER_LEAVE_SCENE'))
-- 	end
-- 	NEARBY_PLAYER[arg0] = nil
-- 	NEARBY_FIGHT[arg0] = nil
-- end)
-- X.RegisterEvent('DOODAD_ENTER_SCENE', function() NEARBY_DOODAD[arg0] = GetDoodad(arg0) end)
-- X.RegisterEvent('DOODAD_LEAVE_SCENE', function() NEARBY_DOODAD[arg0] = nil end)
Event.Reg(X, 'NPC_ENTER_SCENE', function()
	local npc = GetNpc(arg0)
	NEARBY_NPC[arg0] = npc
end)
Event.Reg(X, 'NPC_LEAVE_SCENE', function()
	NEARBY_NPC[arg0] = nil
end)

-- 交互一个拾取交互物件（当前帧重复调用仅交互一次防止庖丁）
function X.InteractDoodad(dwID)
	X.Throttle('InteractDoodad' .. dwID, 375, function()
		LOG.INFO('[MY_Game] Open Doodad ' .. dwID .. ' at ' .. GetLogicFrameCount() .. '.')
		InteractDoodad(dwID)
	end)
end

local O = {
    szDistanceType = 'gwwean', -- 'gwwean', 'euclidean', 'plane'
}
function X.GetGlobalDistanceType()
	return O.szDistanceType
end

-- OObject: KObject | {nType, dwID} | {dwID} | {nType, szName} | {szName}
-- X.GetDistance(OObject[, szType])
-- X.GetDistance(nX, nY)
-- X.GetDistance(nX, nY, nZ[, szType])
-- X.GetDistance(OObject1, OObject2[, szType])
-- X.GetDistance(OObject1, nX2, nY2)
-- X.GetDistance(OObject1, nX2, nY2, nZ2[, szType])
-- X.GetDistance(nX1, nY1, nX2, nY2)
-- X.GetDistance(nX1, nY1, nZ1, nX2, nY2, nZ2[, szType])
-- szType: 'euclidean': 欧氏距离 (default)
--         'plane'    : 平面距离
--         'gwwean'   : 郭氏距离
--         'global'   : 使用全局配置
-- OObject: KObject | {nType, dwID} | {dwID} | {nType, szName} | {szName}
-- X.GetDistance(OObject[, szType])
-- X.GetDistance(nX, nY)
-- X.GetDistance(nX, nY, nZ[, szType])
-- X.GetDistance(OObject1, OObject2[, szType])
-- X.GetDistance(OObject1, nX2, nY2)
-- X.GetDistance(OObject1, nX2, nY2, nZ2[, szType])
-- X.GetDistance(nX1, nY1, nX2, nY2)
-- X.GetDistance(nX1, nY1, nZ1, nX2, nY2, nZ2[, szType])
-- szType: 'euclidean': 欧氏距离 (default)
--         'plane'    : 平面距离
--         'gwwean'   : 郭氏距离
--         'global'   : 使用全局配置
function X.GetDistance(arg0, arg1, arg2, arg3, arg4, arg5, arg6)
	local szType
	local nX1, nY1, nZ1 = 0, 0, 0
	local nX2, nY2, nZ2 = 0, 0, 0
	if X.IsTable(arg0) then
		arg0 = X.GetObject(unpack(arg0))
		if not arg0 then
			return
		end
	end
	if X.IsTable(arg1) then
		arg1 = X.GetObject(unpack(arg1))
		if not arg1 then
			return
		end
	end
	if X.IsUserdata(arg0) then -- OObject -
		nX1, nY1, nZ1 = arg0.nX, arg0.nY, arg0.nZ
		if X.IsUserdata(arg1) then -- OObject1, OObject2
			nX2, nY2, nZ2, szType = arg1.nX, arg1.nY, arg1.nZ, arg2
		elseif X.IsNumber(arg1) and X.IsNumber(arg2) then -- OObject1, nX2, nY2
			if X.IsNumber(arg3) then -- OObject1, nX2, nY2, nZ2[, szType]
				nX2, nY2, nZ2, szType = arg1, arg2, arg3, arg4
			else -- OObject1, nX2, nY2[, szType]
				nX2, nY2, szType = arg1, arg2, arg3
			end
		else -- OObject[, szType]
			local me = GetClientPlayer()
			nX2, nY2, nZ2, szType = me.nX, me.nY, me.nZ, arg1
		end
	elseif X.IsNumber(arg0) and X.IsNumber(arg1) then -- nX1, nY1 -
		if X.IsNumber(arg2) then
			if X.IsNumber(arg3) then
				if X.IsNumber(arg4) and X.IsNumber(arg5) then -- nX1, nY1, nZ1, nX2, nY2, nZ2[, szType]
					nX1, nY1, nZ1, nX2, nY2, nZ2, szType = arg0, arg1, arg2, arg3, arg4, arg5, arg6
				else -- nX1, nY1, nX2, nY2[, szType]
					nX1, nY1, nX2, nY2, szType = arg0, arg1, arg2, arg3, arg4
				end
			else -- nX1, nY1, nZ1[, szType]
				local me = GetClientPlayer()
				nX1, nY1, nZ1, nX2, nY2, nZ2, szType = me.nX, me.nY, me.nZ, arg0, arg1, arg2, arg3
			end
		else -- nX1, nY1
			local me = GetClientPlayer()
			nX1, nY1, nX2, nY2 = me.nX, me.nY, arg0, arg1
		end
	end
	if not szType or szType == 'global' then
		szType = X.GetGlobalDistanceType()
	end
	if szType == 'plane' then
		return math.floor(((nX1 - nX2) ^ 2 + (nY1 - nY2) ^ 2) ^ 0.5) / 64
	end
	if szType == 'gwwean' then
		return math.max(math.floor(((nX1 - nX2) ^ 2 + (nY1 - nY2) ^ 2) ^ 0.5) / 64, math.floor(math.abs(nZ1 / 8 - nZ2 / 8)) / 64)
	end
	return math.floor(((nX1 - nX2) ^ 2 + (nY1 - nY2) ^ 2 + (nZ1 / 8 - nZ2 / 8) ^ 2) ^ 0.5) / 64
end
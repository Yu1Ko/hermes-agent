
Event = Event or {}
Event.listeners = Event.listeners or {}
Event.dropEvents = Event.dropEvents or {}
Event.nDispatchDepth = 0

local kArgNames = {}
for i = 1, 16 do
	kArgNames[i] = string.format("arg%d", i - 1)
end

local logError = LogError

local function ClearDropedEvent()
	if Event.nDispatchDepth > 0 then
		return
	end

	if Config.bOptickLuaSample then BeginSample("Event.ClearDropedEvent") end

	-- for szEventType, listener in pairs(Event.listeners) do
	-- 	for i = #listener, 1, -1 do
	-- 		if listener[i].bDroped then
	-- 			table.remove(listener, i)
	-- 		end
	-- 	end
	-- end

	for szEventType, indexArr in pairs(Event.dropEvents) do
		local listener = Event.listeners[szEventType]
		if listener then
			table.sort(indexArr)
			for i = #indexArr, 1, -1 do
				table.remove(listener, indexArr[i])
			end
		end
	end
	Event.dropEvents = {}

	if Config.bOptickLuaSample then EndSample() end
end

local function RegisterEvent(szEventType, func, szClassName)
	if not Event.listeners[szEventType] then
		Event.listeners[szEventType] = {}
	end

	table.insert(Event.listeners[szEventType], {fn = func, className = szClassName})

	return func
end

local function DropEvent(szEventType, func)
	if not Event.listeners[szEventType] then
		return
	end

	for i, v in pairs(Event.listeners[szEventType]) do
		if v.fn == func and not v.bDroped then
			if Event.nDispatchDepth > 0 then
				v.bDroped = true

				if not Event.dropEvents[szEventType] then
					Event.dropEvents[szEventType] = {}
				end
				table.insert(Event.dropEvents[szEventType], i)
			else
				table.remove(Event.listeners[szEventType], i)
			end
			break
		end
	end
end

local function DispatchEvent(szEventType, ...)
	local listener = Event.listeners[szEventType]
	if not listener then
		return
	end

	Event.nDispatchDepth = Event.nDispatchDepth + 1

	local tbArgs = {...}
	local nLen = #listener
	for i = 1, nLen do
		local v = listener[i]
		if not v.bDroped then
			local fn = v.fn
			local className = v.className

			if Config.bOptickLuaSample then BeginSample("Event.Dispatch."..tostring(szEventType).."."..tostring(className)) end

			xpcall(
				function() fn(unpack(tbArgs)) end,
				function(err)
					logError(debug.traceback(string.format("Event Dispatch Error, type = %s.\n%s", szEventType, err), 2))
				end
			)

			if Config.bOptickLuaSample then EndSample() end
		end
	end

	Event.nDispatchDepth = Event.nDispatchDepth - 1
	ClearDropedEvent()
end


local nextsn = 0
local function FecthNext()
	nextsn = nextsn + 1
	return nextsn
end

local function UnRegEvent(script, nEventID)
	local func = script._tbEvent[nEventID]
	local szEventType = script._tbEventName[nEventID]

	if func and szEventType then
		DropEvent(szEventType, func)
		script._tbEvent[nEventID] = nil
		script._tbEventName[nEventID] = nil
		script._tbEventID[szEventType] = nil
		return true
	end
end

local function RegEvent(script, szEventType, func)
	--remove old func
	local nEventID = script._tbEventID[szEventType]
	local szClassName = script and script.className or "NULL"

	if nEventID then
		UnRegEvent(script, nEventID)
	end

	--获取
	nEventID = FecthNext()

	script._tbEvent[nEventID] = RegisterEvent(szEventType, func, szClassName)
	script._tbEventName[nEventID] = szEventType
	script._tbEventID[szEventType] = nEventID	 --非单次的 ，记录消息ID

	return nEventID
end

local function RegOneShotEvent(script, szEventType, func)

	local nEventID = FecthNext()
	local szClassName = script and script.className or "NULL"

	script._tbEventName[nEventID] = szEventType
	script._tbEvent[nEventID] = RegisterEvent(szEventType, function(...)
		func(...)
		--remove OneShot
		DropEvent(szEventType, script._tbEvent[nEventID])

		script._tbEvent[nEventID] = nil
		script._tbEventName[nEventID] = nil
	end, szClassName)

	return nEventID
end

-- ======================================================================
-- public
-- ======================================================================
function Event.Reg(script, szEventType, func, bOneShot)
	if not script or not szEventType or not func then return end

	if not script._tbEvent then
		script._tbEvent = {}
		script._tbEventName = {}
		script._tbEventID = {}
	end

	local nEventID
	if bOneShot then
		nEventID = RegOneShotEvent(script, szEventType, func)
	else
		nEventID = RegEvent(script, szEventType, func)
	end
	return nEventID
end

function Event.UnReg(script, szEventType)
	if not script or not szEventType then return end
	if not script._tbEvent then return end

	local nEventID = script._tbEventID[szEventType]
	return UnRegEvent(script, nEventID)
end

function Event.UnRegAll(script)
	if not script or not script._tbEvent then return end
	for nEventID, _ in pairs(script._tbEvent) do
		UnRegEvent(script, nEventID)
	end
end

function Event.DoDispatch(szEventType, ...)
	-- print(string.format("EventName - [%s]", szEventType))

	local tbArgs = {...}
	local nArgsLen = select('#', ...)
	local bHasArgs = nArgsLen > 0
	local tbArgsTemp = nil

	if bHasArgs then
		tbArgsTemp = {}
		for i = 1, nArgsLen do
			local szName = kArgNames[i]
			tbArgsTemp[i] = _G[szName]
			_G[szName] = tbArgs[i]
		end
	end

	if nArgsLen == 0 then
		DispatchEvent(szEventType, arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15)
	elseif nArgsLen == 1 then
		DispatchEvent(szEventType, arg0)
	elseif nArgsLen == 2 then
		DispatchEvent(szEventType, arg0, arg1)
	elseif nArgsLen == 3 then
		DispatchEvent(szEventType, arg0, arg1, arg2)
	elseif nArgsLen == 4 then
		DispatchEvent(szEventType, arg0, arg1, arg2, arg3)
	elseif nArgsLen == 5 then
		DispatchEvent(szEventType, arg0, arg1, arg2, arg3, arg4)
	elseif nArgsLen == 6 then
		DispatchEvent(szEventType, arg0, arg1, arg2, arg3, arg4, arg5)
	elseif nArgsLen == 7 then
		DispatchEvent(szEventType, arg0, arg1, arg2, arg3, arg4, arg5, arg6)
	elseif nArgsLen == 8 then
		DispatchEvent(szEventType, arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7)
	elseif nArgsLen == 9 then
		DispatchEvent(szEventType, arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)
	elseif nArgsLen == 10 then
		DispatchEvent(szEventType, arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
	elseif nArgsLen == 11 then
		DispatchEvent(szEventType, arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10)
	elseif nArgsLen == 12 then
		DispatchEvent(szEventType, arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11)
	elseif nArgsLen == 13 then
		DispatchEvent(szEventType, arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12)
	elseif nArgsLen == 14 then
		DispatchEvent(szEventType, arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13)
	elseif nArgsLen == 15 then
		DispatchEvent(szEventType, arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14)
	elseif nArgsLen == 16 then
		DispatchEvent(szEventType, arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15)
	end

	if bHasArgs then
		tbArgsTemp = tbArgsTemp or {}
		for i = 1, nArgsLen do
			local szName = kArgNames[i]
			_G[szName] = tbArgsTemp[i]
		end
	end
end

function Event.Dispatch(szEventType, ...)
	Event.DoDispatch(szEventType, ...)
end
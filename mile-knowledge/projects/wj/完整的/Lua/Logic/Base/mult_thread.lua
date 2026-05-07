-- 多线程异步操作
-- 需要操作的场景对象可能在不同的线程，则需要将逻辑分步执行
-- 1. 发起请求，注册到执行模块执行请求
-- 2. 线程执行，目标线程中执行请求逻辑，并将结果压入队列中
-- 3. 回调执行，在主线程中执行请求回调

AsyncData = AsyncData or {className = "AsyncData"}
local self = AsyncData

local _t3DModel = {}
local _t3DModelParam = {}
local _t3DScene = {}
local _tCommon  = {}
local _tCommonParam = {}

local registerEvents

function AsyncData.Init()
	registerEvents()
end

function AsyncData.OnReload()
	Event.UnRegAll(self)
	registerEvents();
end

local function On3DModelThreadCall()
	local FunName 	= arg0
	local t 		= _t3DModel[FunName]
	local tParam    = _t3DModelParam[FunName]
	if not t then
		return
	end

	local res, dwModelID, fnAction, model
	if t.bUseCallID then
		local dwCallID = arg1
		if not t[dwCallID] then
			return
		end
		local UserData = tParam[dwCallID]

		dwModelID	= arg2
		fnAction 	= t[dwCallID]
		t[dwCallID] = nil
		model 		= KG3DEngine.IDToModel(dwModelID)
		res 		= pcall(fnAction, model, UserData, arg3, arg4, arg5, arg6, arg7, arg8)
	else
		if #t == 0 then
			return
		end
		dwModelID	= arg1
		model 		= KG3DEngine.IDToModel(dwModelID)
		fnAction 	= t[1]
		local UserData = tParam[1] == "nil" and nil or tParam[1]

		res 		= pcall(fnAction, model, UserData, arg2, arg3, arg4, arg5, arg6, arg7)
		table.remove(t, 1)
		table.remove(tParam, 1)

		if tParam and #tParam == 0 then
			_t3DModelParam[FunName] = nil
		end
	end


	return res
end

local function OnSceneThreadCall()
	local FunName 	= arg0
	local t 		= _t3DScene[FunName]
	if not t or table.get_len(t) == 0 then
		_t3DScene[FunName] = nil
		return
	end

	local res, dwSceneID, fnAction, scene
	if t.bUseCallID then
		local dwCallID = arg1

		dwSceneID	= arg2
		fnAction 	= t[dwCallID]
		t[dwCallID] = nil

		scene 		= KG3DEngine.SceneToID(dwSceneID)
		res 		= pcall(fnAction, scene, arg3, arg4, arg5, arg6, arg7, arg8)
	else
		fnAction 	= t[1]
		dwSceneID	= arg1
		scene = KG3DEngine.SceneToID(dwSceneID)
		res = pcall(fnAction, scene, arg2, arg3, arg4, arg5, arg6, arg7)
		table.remove(t, 1)
	end
	return res
end

local function OnCommonThreadCallUseID(nCallID, tFuncs, tParam, nArg)
	local fnAction = tFuncs[nCallID]
	if not fnAction then
		return
	end

	tFuncs[nCallID] = nil
	for i=1, 5, 1 do
		if not tFuncs[nCallID - i] then
			break
		end
		tFuncs[nCallID - i] = nil
		tParam[nCallID - i] = nil
	end

	local tArg = {}
	if tParam[nCallID] ~= nil then
		table.insert(tArg, tParam[nCallID])
		tParam[nCallID] = nil
	end

	for i =2, nArg, 1 do
		table.insert(tArg, _G[ ARG_STR[i + 1] ])
	end

	-- pcall(fnAction, unpack(tArg))
	xpcall(fnAction(unpack(tArg)), function(err)
		--LOG.ERROR(debug.traceback())
	end)
end

local function OnCommonThreadCall()
	local FunName 	= arg0
	local nArg		= arg1
	local t 		= _tCommon[FunName]
	local tParam    = _tCommonParam[FunName]

	if not t then
		_tCommon[FunName] = nil
		return
	end

	if t.bUseCallID then
		return OnCommonThreadCallUseID(arg2 or 0, t, tParam, nArg)
	end

	if #t == 0 then
		return
	end

	local tArg = {}
	if tParam and #tParam > 0 then
		if tParam[1] ~= "nil" then
			table.insert(tArg, tParam[1])
		end
		table.remove(tParam, 1)
	end

	for i =1, nArg, 1 do
		table.insert(tArg, _G[ ARG_STR[i + 1] ])
	end

	local fnAction = t[1]
	pcall(fnAction, unpack(tArg))
	table.remove(t, 1)

	if #t == 0 then
		_tCommon[FunName] = nil
	end

	if tParam and #tParam == 0 then
		_tCommonParam[FunName] = nil
	end
end

function Post3DModelThreadCall(fnCallBack, UserData, model, FunName, ...)
	local aArg = {model[FunName](model, ...)}
	if aArg[1] == "_call_id" then
		local dwCallID  = aArg[2]

		_t3DModel[FunName] = _t3DModel[FunName] or {bUseCallID = true}
		_t3DModel[FunName][dwCallID] = fnCallBack
		_t3DModelParam[FunName] = _t3DModelParam[FunName] or {}
		_t3DModelParam[FunName][dwCallID] = UserData
	elseif #aArg > 0 then
		return pcall(fnCallBack, model, UserData, unpack(aArg))
	else
		if UserData == nil then
			UserData = "nil"
		end
		_t3DModel[FunName] = _t3DModel[FunName] or {}
		table.insert(_t3DModel[FunName], fnCallBack)

		_t3DModelParam[FunName] = _t3DModelParam[FunName] or {}
		table.insert(_t3DModelParam[FunName], UserData)
	end
end

function PostSceneThreadCall(fnCallBack, scene, FunName, ...)
	local aArg = {scene[FunName](scene, ...)}
	if aArg[1] == "_call_id" then
		local dwCallID  = aArg[2]

		_t3DScene[FunName] = _t3DScene[FunName] or {bUseCallID = true}
		_t3DScene[FunName][dwCallID] = fnCallBack

	elseif #aArg > 0 then
		return pcall(fnCallBack, scene, unpack(aArg))
	else
		_t3DScene[FunName] = _t3DScene[FunName] or {}
		table.insert(_t3DScene[FunName], fnCallBack)
	end
end

local function AddCommonFun(fnCallBack, UserData, FunName, nCallID)
	local szKey = FunName

	_tCommon[szKey] = _tCommon[szKey] or {}
	_tCommonParam[szKey] = _tCommonParam[szKey] or {}

	if nCallID then
		_tCommon[szKey].bUseCallID = true
		_tCommon[szKey][nCallID] = fnCallBack
		_tCommonParam[szKey][nCallID] = UserData
	else
		if UserData == nil then
			UserData = "nil"
		end
		table.insert(_tCommon[szKey], fnCallBack)
		table.insert(_tCommonParam[szKey], UserData)
	end
end

function PostThreadCall(fnCallBack, UserData, FunName, ...)
	local fnAction = _G[FunName]
	if not fnAction then
		Log(string.format("function %s is not exist", tostring(FunName)))
		return
	end

	local aArg = {fnAction(...)}
	if aArg[1] == "_call_id" then
		AddCommonFun(fnCallBack, UserData, FunName, aArg[2])
	elseif #aArg > 0 then
		if aArg[1] == "_error0" then
			return pcall(fnCallBack, UserData)
		elseif UserData ~= nil then
			return pcall(fnCallBack, UserData, unpack(aArg))
		else
			return pcall(fnCallBack, unpack(aArg))
		end
	else
		AddCommonFun(fnCallBack, UserData, FunName)
	end
end

local _bAddonPostCall = nil

function Addon_IsPostThreadCall()
	return _bAddonPostCall
end

function Addon_PostThreadCall(fnCallBack, UserData, FunName, ...)
	local tEnv = GetAddonEnv()
	local fnAction = tEnv[FunName]
	if not fnAction then
		Log(string.format("addon function %s is not exist", tostring(FunName)))
		return
	end

	_bAddonPostCall = true

	local aArg = {fnAction(...)}

	_bAddonPostCall = nil

	if aArg[1] == "_call_id" then
		AddCommonFun(fnCallBack, UserData, FunName, aArg[2])
	elseif #aArg > 0 then
		if aArg[1] == "_error0" then
			return pcall(fnCallBack, UserData)
		elseif UserData ~= nil then
			return pcall(fnCallBack, UserData, unpack(aArg))
		else
			return pcall(fnCallBack, unpack(aArg))
		end
	else
		AddCommonFun(fnCallBack, UserData, FunName)
	end
end

function registerEvents()
	Event.Reg(AsyncData, "MODEL_CALL_BACK",  On3DModelThreadCall)
	Event.Reg(AsyncData, "SCENE_CALL_BACK",  OnSceneThreadCall)
	Event.Reg(AsyncData, "COMMON_CALL_BACK", OnCommonThreadCall)
end

--[[
CThreadCoor_Register(type, x/character_id [, y, z] ):
param:
	1.type:
		CTCT.CHARACTER_TOP_2_SCREEN_POS
		CTCT.SCENE_2_SCREEN_POS
		CTCT.GAME_WORLD_2_SCREEN_POS

	2.x or characterId
	3.y
	4.z

return:
	1.id

desc:
	when register the coor transform, the render thread will transform the coor and save the result to mem every frame

CThreadCoor_Unregister:
	param:
		1.id

CThreadCoor_Get:
	param:
		1.id

]]
local m_tCoorReg = {}
local m_tCoorIDFlag = {}
local ID_RANDE = 100000
local function CThreadCoor_MergeID(dwID, nCount)
	return dwID + nCount * ID_RANDE
end

local function CThreadCoor_GetID(dwMergeID)
	local nCount = math.floor(dwMergeID / ID_RANDE )
	local dwID = dwMergeID - nCount * ID_RANDE
	return dwID, nCount
end

local function CThreadCoor_Check(dwCharacterID)
	local dwMergeID = m_tCoorReg[dwCharacterID]
	if dwMergeID then
		return CThreadCoor_GetID(dwMergeID)
	end
end

local function CThreadCoor_Mark(dwID, dwCharacterID)
	if not dwCharacterID or dwCharacterID == false then
		dwCharacterID = m_tCoorIDFlag[dwID]
		if dwCharacterID then
			local _, nCount = CThreadCoor_GetID(m_tCoorReg[dwCharacterID])
			if nCount == 1 then
				m_tCoorReg[dwCharacterID] = nil
				m_tCoorIDFlag[dwID] = nil
				return true
			else
				m_tCoorReg[dwCharacterID] = CThreadCoor_MergeID(dwID, nCount - 1)
				return false
			end
		end
		return  true
	end

	local nCount = 1
	if m_tCoorReg[dwCharacterID] then
		_, nCount = CThreadCoor_GetID(m_tCoorReg[dwCharacterID])
	end

	m_tCoorReg[dwCharacterID] = CThreadCoor_MergeID(dwID, nCount)
	m_tCoorIDFlag[dwID] = dwCharacterID
end

--==== global func: get cross thread coor  ===============================================================
function CThreadCoor_Register(type, ...)
	local dwID
	if type == CTCT.CHARACTER_TOP_2_SCREEN_POS then
		dwID = CThreadCoor_Check(...)
	end

	if not dwID then
		dwID = CrossThreadCoor_Register(type, ...)
	end

	if type == CTCT.CHARACTER_TOP_2_SCREEN_POS and dwID and dwID ~= -1 then
		CThreadCoor_Mark(dwID, ...)
	end
	return dwID
end

function CThreadCoor_Unregister(dwID)
	local bUnreg = CThreadCoor_Mark(dwID, false)
	if bUnreg then
		CrossThreadCoor_Unregister(dwID)
	end
end

--function CThreadCoor_Get()
CThreadCoor_Get = CrossThreadCoor_Get

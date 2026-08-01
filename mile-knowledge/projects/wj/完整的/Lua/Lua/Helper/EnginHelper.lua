EnginHelper = EnginHelper or {}

EnginHelper.tbCommonList = {}
EnginHelper.tbModelList = {}
EnginHelper.tbSceneList = {}


--[[
    引擎异步接口封装

    EnginHelper.Call(Scene_GameWorldPositionToScreenPoint(0, 0, 0), callback)
    EnginHelper.Call(model.Find(szSocketName), callback)


    [COMMON_CALL_BACK]
        arg0 : 调用的函数名 如 "Scene_GameWorldPositionToScreenPoint"
        arg1 : 参数长度
        ...
        argn

    [MODEL_CALL_BACK]
        arg0 : 调用的函数名 如 "Find" 、"GetTranslation"
        arg1 : dwCallID或者dw3DObjID
        ...
        argn
]]
function EnginHelper.Call(szResult, callback)
    if szResult == "_error0" then  -- 正常的应该返回 szResult == _call_id
        return
    end

    if not IsFunction(callback) then return end

    table.insert(EnginHelper.tbCommonList, callback)
end

Event.Reg(EnginHelper, "COMMON_CALL_BACK", function(...) 
    local callback = table.remove(EnginHelper.tbCommonList, 1)
	pcall(callback, unpack({...}))
end)









-- Model
function EnginHelper.CallModel(szResult, callback)
    if szResult == "_error0" then  -- 正常的应该返回 szResult == _call_id
        return
    end

    if not IsFunction(callback) then return end
    
    table.insert(EnginHelper.tbModelList, callback)
end

Event.Reg(EnginHelper, "MODEL_CALL_BACK", function(...) 
    local callback = table.remove(EnginHelper.tbModelList, 1)
	pcall(callback, unpack({...}))
end)







-- Scene
function EnginHelper.CallScene(szResult, callback)
    if szResult == "_error0" then  -- 正常的应该返回 szResult == _call_id
        return
    end

    if not IsFunction(callback) then return end
    
    table.insert(EnginHelper.tbSceneList, callback)
end

Event.Reg(EnginHelper, "SCENE_CALL_BACK", function(...) 
    local callback = table.remove(EnginHelper.tbSceneList, 1)
	pcall(callback, unpack({...}))
end)

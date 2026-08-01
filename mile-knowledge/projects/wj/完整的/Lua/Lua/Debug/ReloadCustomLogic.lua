--[[
重载脚本自定义逻辑
1. 按F8执行重载
2. 可以在下面ReloadCustomLogic.OnReloadEnd中添加重载结束后执行的逻辑
3. 可以在下面tScripts中添加需要重载的脚本
4. 被重载的脚本中的全局变量中的值默认会被转存为重载前的旧值, 而全局变量中的函数会是重载后的新逻辑(包括其中的upvalue)
5. 被重载的脚本中的全局变量中若有OnReload函数, 则该函数会被调用且参数为(新变量, 旧变量), 本逻辑不再做旧值转存
6. 对于OnReload的参数, 若指定脚本为首次加载, 需要注意旧变量的值可能为nil
--]]
ReloadCustomLogic = ReloadCustomLogic or {}

-- 在指定的脚本都被重载后调用
function ReloadCustomLogic.OnReloadEnd()
    --TODO: 此处添加重载完成后逻辑
    
end

-- 指定需要重载的脚本
local tScripts = {
    --"Lua/Debug/TestReload",
    "Lua/Debug/Hotkey",
    "Lua/Logic/ItemData",
    "Lua/Framework/UIMgr",
    "Lua/Logic/TargetMgr.lua",
    "Lua/Logic/PlotMgr",
    "Lua/Logic/GameSettingData",
    "Lua/Helper/ParseTextHelper.lua",
    "Lua/Logic/KG3DEngine/ModelHelper",
    "Lua/Framework/ModelsView",
    "Lua/Logic/CameraMgr.lua",
    "Lua/Tab/UISettingStoreTab",
    "Lua/Tab/UIGameSettingConfigTab",
    "Lua/Logic/Quality/QualityMgr",

    "Lua/Def/UIDef",
    "Lua/Def/EventType",

    --"Lua/Helper/UIHelper.lua",
}

function ReloadCustomLogic.OnReload()
    print("==================== reload start ====================")
    for _, szScriptName in ipairs(tScripts) do
        local r = ReloadScript.Reload(szScriptName)
        if r then
            print("reload script:", szScriptName, r)
        end
    end
    ReloadCustomLogic.OnReloadEnd()
    print("==================== reload end  ====================")
end

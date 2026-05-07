LoginMgr.Log("StabilityController","StabilityController imported")
-- 稳定性主控插件
StabilityController = {}
StabilityController.bFlag = true
--读取配置文件中的插件
local szFilePath=SearchPanel.szCurrentInterfacePath.."StabilitySetting.ini"
print(szFilePath)
local iniFile = Ini.Open(szFilePath)
local StrOverall = iniFile:ReadString("Overall", "Type", "")
-- 分割字符串导入对应的插件
local tbInterface = {}
for task in string.gmatch(StrOverall, '([^,]+)') do
    table.insert(tbInterface, task)
end
-- 载入对应的稳定性插件
for _, szStabilityTask in ipairs(tbInterface) do
    local szInterfacePath="mui/Lua/Interface/StabilityTask/"
    local luaPath = string.format("%s%s/%s.lua", szInterfacePath, szStabilityTask, szStabilityTask)
    AutoTestLog.INFO(luaPath)
    require(luaPath)
    LoginMgr.Log("StabilityController", luaPath)
end

-- 设置人物登录
SearchPanel.tbModule['AutoLogin'].SetAutoLoginInfo(nil,nil,'段氏','成男')

-- 设置副本脚本
function StabilityController.SetDungeons(nDungeonMap)
    DungeonsRunMapTask(SearchPanel.szCurrentInterfacePath.."Dungeons/DungeonsTask/"..tostring(nDungeonMap)..".tab")
end

local list_RunMapCMD = {}
local list_RunMapTime = {}
local nCurrentTime = 0
local nNextTime=tonumber(20)
local nCurrentStep=1
--读取tab的内容
local tbRunMapData=SearchPanel.LoadRunMapFile(SearchPanel.szCurrentInterfacePath.."RunMap.tab",2)
list_RunMapCMD = tbRunMapData[1]
list_RunMapTime = tbRunMapData[2]

-- 导入的插件 如果要添加新的插件需要在此处添加 之后要改成载入通用类型
local cmd_map = {
    ["MainTask"]   = MainTask,
    ["UITraversal"]        = UITraversal,
    ["ShopErgodicTDR"]     = ShopErgodic,
    ["DungeonsTask"]       = Dungeons,
    ["BaseTrade"] = BaseTrade,
}


-- 主控RunMap.文件
function StabilityController.FrameUpdate()
    if StabilityController.bFlag and GetTickCount()-nCurrentTime>nNextTime*1000 then
        -- 是否从地图加载界面进入了游戏
        if not SearchPanel.IsFromLoadingEnterGame() then
            return
        end
        if nCurrentStep==#list_RunMapCMD then
            StabilityController.bFlag=false
        end
        --切图前后置操作
        local szCmd=list_RunMapCMD[nCurrentStep]
        pcall(function ()
            SearchPanel.RunCommand(szCmd)
        end)
        OutputMessage("MSG_SYS",szCmd)
        AutoTestLog.INFO(szCmd)
        nNextTime=tonumber(list_RunMapTime[nCurrentStep])
        --启动插件操作
        for key, obj in pairs(cmd_map) do
            if string.find(szCmd, key) then
                obj.Start()
                StabilityController.bFlag = false
                break
            end
        end
        if string.find(szCmd,"perfeye_start") then
            SearchPanel.bPerfeye_Start=true
        elseif string.find(szCmd,"perfeye_stop") then
            SearchPanel.bPerfeye_Stop=true
		end
		nCurrentTime=GetTickCount()
        nCurrentStep=nCurrentStep+1
    end
end

Timer.AddFrameCycle(StabilityController,1,function ()
    StabilityController.FrameUpdate()
end)


LoginMgr.Log("StabilityController","StabilityController End")
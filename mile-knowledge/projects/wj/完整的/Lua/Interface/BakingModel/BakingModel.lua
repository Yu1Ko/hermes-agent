BakingModel={}
local bFlag = true
BakingModel.nNextTime = 10
BakingModel.nStartTime =0
BakingModel.CircleStart = false

BakeMap ={}
local tbBakeMapData=SearchPanel.LoadRunMapFile(SearchPanel.szCurrentInterfacePath.."BakeMap.tab",3) -- 烘培模型原数据
BakeMap.nStart=0
BakeMap.bFlag= false
BakeMap.nEnd=0

--处理未知弹窗
Timer.AddCycle(SearchPanel.tbTips,1,SearchPanel.DealWithTips)

-- 处理数据
function BakingModel.GetStartEnd(szMapName)
    for index, value in ipairs(tbBakeMapData[2]) do
        if not BakeMap.bFlag then
            if tostring(value) == szMapName then
                BakeMap.nStart = index
                BakeMap.bFlag=true
            end
        else
            if tostring(value) ~= szMapName then
                print(index)
                BakeMap.nEnd =index
                break
            end
        end
    end
end
--  生成新的表格
BakeMap.szLogPath=SearchPanel.szInterfacePath.."BakeMap.txt"
function BakingModel.INFO(szLogInfo)
    BakeMap.file = io.open(BakeMap.szLogPath,'a+')
    BakeMap.file:write(szLogInfo)
    BakeMap.file:flush()
end

function BakingModel.FrameUpdate()
    if GetTickCount() - BakingModel.nStartTime >= BakingModel.nNextTime*1000 then --间隔10秒
        if not BakingModel.CircleStart then
            SearchPanel.CircleStart()
            BakingModel.CircleStart = true
            return
        end
        if BakeMap.nStart == BakeMap.nEnd+1 then
            Timer.DelAllTimer(BakingModel)
            bFlag = true
            return
        end
        local szData = tbBakeMapData[3][BakeMap.nStart]
        local tbBake = SearchPanel.StringSplit(szData,",")
        local x, y, z=Scene_ScenePositionToGameWorldPosition(tbBake[1],tbBake[2],tbBake[3]);
        local a = math.floor(tonumber(x) or 0)
        local b = math.floor(tonumber(y) or 0)
        local c = math.floor(tonumber(z) or 0)
        local szString = "当前坐标"..a..","..b..","..c
        local szResult = string.format("%s\t%s\t%s\t%s,%s,%s\n",tbBakeMapData[1][BakeMap.nStart],tbBakeMapData[2][BakeMap.nStart],szData,a,b,c)
        BakingModel.INFO(szResult)
        GMHelper.ShowNormalTip(szString)
        OutputMessage("MSG_SYS",szString)
        SendGMCommand(string.format("player.SetPosition(%d,%d,%d);player.BirdFlyTo(%d,%d,%d)",a,b,c,a,b,c))
        BakeMap.nStart = BakeMap.nStart + 1
        BakingModel.nStartTime = GetTickCount()
    end
end



--读取tab的内容 
local RunMap = {}
local list_RunMapCMD = {}
local list_RunMapTime = {}
local tbRunMapData=SearchPanel.LoadRunMapFile(SearchPanel.szCurrentInterfacePath.."RunMap.tab",2)
list_RunMapCMD = tbRunMapData[1]
list_RunMapTime = tbRunMapData[2]
local nCurrentTime = 0
local nNextTime=tonumber(30)
local nCurrentStep=1

-- 切图的前后置操作 这部分实现模块化后直接去除
function RunMap.FrameUpdate()
    if not SearchPanel.IsFromLoadingEnterGame() then
        return
    end
    if bFlag and GetTickCount()-nCurrentTime>nNextTime*1000 then
        if nCurrentStep==#list_RunMapCMD then
            bFlag=false
        end
        --切图前后置操作
        local szCmd=list_RunMapCMD[nCurrentStep]
        local nTime=tonumber(list_RunMapTime[nCurrentStep])
        AutoTestLog.INFO(szCmd)
        pcall(function ()
            SearchPanel.RunCommand(szCmd)
        end)
        AutoTestLog.INFO(szCmd.."===ok")
        OutputMessage("MSG_SYS",szCmd)
        nNextTime=nTime
        --切图操作
        if string.find(szCmd,"BakingMap") then
            --启动切图帧更新函数
            Timer.AddFrameCycle(BakingModel,1,function ()
                BakingModel.FrameUpdate()
            end)
            bFlag = false
        end
		nCurrentTime=GetTickCount()
        nCurrentStep=nCurrentStep+1 
    end
end

Timer.AddFrameCycle(RunMap,1,function ()
    RunMap.FrameUpdate()
end)

-- 机器人跑图召唤
local RobotCustom = {}
function RobotCustom.FrameUpdate()
    -- 是否在跑图
    local player=GetClientPlayer()
    if player then
        if player.nMoveState == 16 then
            -- 自身复活
            SearchPanel.RunCommand("/gm player.Revive()")
        end
    end
end

Timer.AddCycle(RobotCustom,1,function ()
    RobotCustom.FrameUpdate()
end)
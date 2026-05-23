CustomRunMap = {}
local RunMap = {}
LoginMgr.Log("CustomRunMap","CustomRunMap imported")
CustomRunMap.bSwitch = true                               -- 插件开关
CustomRunMap.nRunType=1 --设置跑图类型 1自定义 2自动寻路 默认1
CustomRunMap.bCamerafollow=false --相机是否跟随
local szFilePath=SearchPanel.szCurrentInterfacePath.."CustomRunMap.ini"
--跑图圈数 默认跑一次  A->B
CustomRunMap.nRunMapCount=1
function CustomRunMap.SetRunMapCount(nRunMapCount)
    CustomRunMap.nRunMapCount=nRunMapCount
end

CustomRunMap.bCircle=false --是否一边跑一边转圈
function CustomRunMap.SetRunCircle(nCircle)
    if nCircle then
        CustomRunMap.bCircle=true
    end
end
--设置跑图类型 1自定义 2自动寻路 默认1
function CustomRunMap.SetRunType(nType)
    if nType then
        CustomRunMap.nRunType=nType
    end
end

CustomRunMap.bVideoSwitch=false --是否一边跑一边切画质
function CustomRunMap.SetVideoSwitch(nVideoSwitch)
    if nVideoSwitch then
        CustomRunMap.bVideoSwitch=true
    end
end

--加载RunMap.tab文件的数据  格式 {{},{},{},{},{},{},{}}
local tbRunMapData=SearchPanel.LoadRunMapFile(SearchPanel.szCurrentInterfacePath.."RunMap.tab",6)
local list_RunMapCMD = {}                       -- CMD文件
local list_RunMapTime = {}                      -- 文件时间
CustomRunMap.list_RunMapData={}     --跑图点数据

SearchPanel.RemoveFile(SearchPanel.szRunMapResultPath.."perfeye_start")
SearchPanel.RemoveFile(SearchPanel.szRunMapResultPath.."perfeye_stop")
SearchPanel.RemoveFile(SearchPanel.szRunMapResultPath.."ExitGame")
--处理未知弹窗
Timer.AddCycle(SearchPanel.tbTips,1,SearchPanel.DealWithTips)

-- 提取跑图坐标 和CMD指令
local function GetPointsRunMap()
    local strInfo=''
    local nDataLen=#tbRunMapData
    --临时数据存放
    local tbDataTemp={}
    --用第1个{}作为数据的总长度
    for i=1,#tbRunMapData[1] do
        tbDataTemp={}
        strInfo=tbRunMapData[1][i]:sub(1,1)
        if strInfo=='/' then
            table.insert(list_RunMapCMD,tbRunMapData[1][i])
            table.insert(list_RunMapTime,tbRunMapData[2][i])
        elseif strInfo=='x' then
            LOG.INFO("CustomRunMap Start Read RunMapData")
        else
            --取坐标 格式 x,y,z,stay,mapid,action  stay:在该点停了时间 action:在该点执行什么行为,1 stay 2 转一圈
            for n=1,nDataLen do
                table.insert(tbDataTemp,tbRunMapData[n][i])
            end
            table.insert(CustomRunMap.list_RunMapData,tbDataTemp)
        end
    end
end
--初始化 CMD和跑图数据点
GetPointsRunMap()

local nCurrentTime = 0
local nNextTime=20
local nCurrentStep=1
--暂停帧更新标注
local bStopFrameFlag = true
function CustomRunMap.FrameUpdate()
    if not CustomRunMap.bSwitch then
        return
    end
    if not SearchPanel.IsFromLoadingEnterGame() then
        return
    end
    if bStopFrameFlag and GetTickCount()-nCurrentTime>nNextTime*1000 then
        if nCurrentStep==#list_RunMapCMD then
            --命令执行到最后一行
            bStopFrameFlag =false
        end
        --切图前后置操作
        local szCmd=list_RunMapCMD[nCurrentStep]
        pcall(function ()
            SearchPanel.RunCommand(szCmd)
        end)
        LOG.INFO(szCmd.."===ok")
        OutputMessage("MSG_SYS",szCmd)
        nNextTime=tonumber(list_RunMapTime[nCurrentStep])
        if string.find(szCmd,"perfeye_start") then
            SearchPanel.bPerfeye_Start=true
        elseif string.find(szCmd,"CustomRunMap_start") then
            --开启跑图 并帧更新判断跑图是否结束 将执行CMD的帧更新停止 开启跑图
            if CustomRunMap.nRunType==1 then
                CustomRunMapByData.Start(CustomRunMap.list_RunMapData,CustomRunMap.nRunMapCount,CustomRunMap.bCircle,CustomRunMap.bVideoSwitch,CustomRunMap.bCamerafollow)
            else
                CustomRunMapByAutoWay.Start(CustomRunMap.list_RunMapData,CustomRunMap.nRunMapCount,CustomRunMap.bCircle,CustomRunMap.bVideoSwitch,CustomRunMap.bCamerafollow)
            end
            Timer.AddFrameCycle(CustomRunMap,1,CustomRunMap.CheckRunMapEnd)
            bStopFrameFlag=false
        elseif string.find(szCmd,"perfeye_stop") then
            SearchPanel.bPerfeye_Stop=true
        end
        nCurrentTime=GetTickCount()
        nCurrentStep=nCurrentStep+1
    end
end

function CustomRunMap.SetCamera(nSetCamera)
    if tonumber(nSetCamera) == 1 then
        CustomRunMap.bCamerafollow = true
    end
end

function CustomRunMap.CheckRunMapEnd()
    if CustomRunMap.nRunType==1 then
        if CustomRunMapByData.IsEnd() then
            --跑图结束  重置跑图
            CustomRunMapByData.bRunMapEnd=false
            bStopFrameFlag=true
        end
    else
        if CustomRunMapByAutoWay.IsEnd() then
            --跑图结束  重置跑图
            CustomRunMapByAutoWay.bRunMapEnd=false
            bStopFrameFlag=true
        end
    end
end

Timer.AddFrameCycle(RunMap,1,function()
    CustomRunMap.FrameUpdate()
end)

LoginMgr.Log("CustomRunMap","CustomRunMap End")
return CustomRunMap
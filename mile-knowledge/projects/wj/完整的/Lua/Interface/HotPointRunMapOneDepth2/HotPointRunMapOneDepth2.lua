LoginMgr.Log("HotPointRunMapOneDepth","HotPointRunMapOneDepth imported")
HotPointRunMapOneDepth={}
local list_RunMapTime = {}
local list_RunMapCMD = {}
local bStopFrameFlag = true

HotPointRunMapOneDepth.nStepSize = 7200
HotPointRunMapOneDepth.IsRun = false
HotPointRunMapOneDepth.nMaxX = 0    --设置地图最大X
HotPointRunMapOneDepth.nMaxY = 0    --设置地图最大Y
HotPointRunMapOneDepth.nMaxZ = 0    --设置地图最大Z
HotPointRunMapOneDepth.nMinX = 0    --设置地图最小X
HotPointRunMapOneDepth.nMinY = 0    --设置地图最小Y
HotPointRunMapOneDepth.nMinZ = 0    --设置地图最小Z

HotPointRunMapOneDepth.nRecordX=0
HotPointRunMapOneDepth.nRecordY=0
HotPointRunMapOneDepth.nRecordZ=0

HotPointRunMapOneDepth.bSwitch=true
SearchPanel.RemoveFile(SearchPanel.szRunMapResultPath.."BeginRunMap")
SearchPanel.RemoveFile(SearchPanel.szRunMapResultPath.."HotPoint_Start")
SearchPanel.RemoveFile(SearchPanel.szRunMapResultPath.."HotPoint_End")
SearchPanel.RemoveFile(SearchPanel.szRunMapResultPath.."ExitGame")
SearchPanel.RemoveFile(SearchPanel.szCurrentInterfacePath.."Data.json")   --移除存储数据文件

function HotPointRunMapOneDepth.SetMapRange(nMinX,nMinY,nMaxX,nMaxY)
    HotPointRunMapOneDepth.nMinX=nMinX
    HotPointRunMapOneDepth.nMinY=nMinY
    HotPointRunMapOneDepth.nMaxX=nMaxX
    HotPointRunMapOneDepth.nMaxY=nMaxY
end

function HotPointRunMapOneDepth.SetStepSize(nStepSize)
    HotPointRunMapOneDepth.nStepSize=nStepSize
end

local tbSleep={}
local tbNextPoint={}
local tbNextCamera={}
local tbNextCull={}

HotPointRunMapOneDepth.list_CameraStatue = {
    [1] = "1083, 1, 1.570, -0.217", --东
    [2] = "1083, 1, 3.140, -0.217", --西
    [3] = "1083, 1, 4.710, -0.217", --南
    [4] = "1083, 1, 6.280, -0.217"  --北
}

--转动镜头触发裁剪后的sleep时间
local tbSleepType={
    NextPointSleep=1,
    CameraRotationSleep=2,
    CullSleep=3
}

local tbSleepTime={
    [tbSleepType.NextPointSleep]=1,
    [tbSleepType.CameraRotationSleep]=1,
    [tbSleepType.CullSleep]=4/#HotPointRunMapOneDepth.list_CameraStatue
}

function HotPointRunMapOneDepth.SetWaitTime(nNextPointSleep,nCameraRotationSleep)
    if nNextPointSleep>=0 then
        tbSleepTime[tbSleepType.NextPointSleep]=nNextPointSleep
    end

    if nCameraRotationSleep>=0 then
        tbSleepTime[tbSleepType.CameraRotationSleep]=nCameraRotationSleep
        --tbSleepTime[tbSleepType.CullSleep]=nCameraRotationSleep
    end
end

--处理未知弹窗
Timer.AddCycle(SearchPanel.tbTips,1,SearchPanel.DealWithTips)
local tbHotPointData={["performanceData"]={}}

local tbGetPlayerInfo={}
tbGetPlayerInfo.szKey=nil
tbGetPlayerInfo.szKeyGM=nil
tbGetPlayerInfo.szKeyGM3dPos=nil
function tbGetPlayerInfo.GetPlayerInfo()
    -- 角色朝向（东南西北）
    --XGame 需要将Y和Z对调
    local player=GetClientPlayer()
    HotPointRunMapOneDepth.nRecordZ=player.nZ --记录Z坐标 客户端会更新脚本
    tbGetPlayerInfo.szKey=string.format("(%d,%d,%d)",HotPointRunMapOneDepth.nRecordX,1000000,HotPointRunMapOneDepth.nRecordY)
    tbGetPlayerInfo.szKeyGM=string.format("(%d,%d,%d)",HotPointRunMapOneDepth.nRecordX,HotPointRunMapOneDepth.nRecordY,HotPointRunMapOneDepth.nRecordZ)
    tbGetPlayerInfo.szKeyGM3dPos=string.format("(%d,%d,%d)",Scene_GameWorldPositionToScenePosition(player.nX,player.nY,player.nZ))
    if not tbHotPointData.performanceData[tbGetPlayerInfo.szKey] then
        tbHotPointData.performanceData[tbGetPlayerInfo.szKey]={}
    end
    
    local fCameraToObjectEyeScale,fYaw ,fPitch = Camera_GetRTParams()
    local _, fMaxCameraDistance = Camera_GetParams()
    --local trueCamereDistance = fMaxCameraDistance * fCameraToObjectEyeScale
    -- fCameraToObjectEyeScale 滚轮比例
    -- fYaw 水平角
    -- fPitch 俯仰角
    --local szCamerInfo=string.format("(%0.3f,%0.3f,%0.3f),",fCameraToObjectEyeScale,fYaw,fPitch)
    local szCamerInfo=string.format("(0.00, %0.2f, 0.00),",(tbNextCamera.nRotationIndex-1)*90)
    local info=GetHotPointReader().GetFrameDataInfo()
    local nSetPassCall=info.setPass    --setPassCall
    local nDrawcall = info.DrawBatchCnt    --drawCall
    local nVertices=0    --顶点数
    local nTriangles=info.FaceCnt --面数
    local nMemory=info.vulkanMemory --内存
    local fps=info.FPS    --FPS
    local ms=1000/fps-1000/fps%0.1  --帧耗时
    local szCMD=string.format('SendGMCommand("player.SetPosition%s;player.BirdFlyTo%s");Camera_SetRTParams(%s);print%s;',tbGetPlayerInfo.szKeyGM,tbGetPlayerInfo.szKeyGM,HotPointRunMapOneDepth.list_CameraStatue[tbNextCamera.nRotationIndex]:sub(6, -1),tbGetPlayerInfo.szKeyGM3dPos)
    local szInfo=szCamerInfo..string.format("%d,%d,%d,%d,%d,%d,%0.1f,%s",nSetPassCall,nDrawcall,nVertices,nTriangles,nMemory,fps,ms,szCMD)
    table.insert(tbHotPointData.performanceData[tbGetPlayerInfo.szKey],szInfo)
end

local bCanGetData=false
--更新函数
local bFlag = true
local player=nil
--初始化
--移动坐标
--旋转
--采集数据

--移动坐标

-----init----------------
--初始化
HotPointRunMapOneDepth.Init = BaseState:New("Init")
function  HotPointRunMapOneDepth.Init:OnEnter()
    LOG.INFO("HotPointRunMapOneDepth init")
end

function  HotPointRunMapOneDepth.Init:OnUpdate()
    tbNextPoint.nDirection=tbNextPoint.DirectionType.Right --默认往右边跑
    tbNextCamera.nRotationIndex=1   --重置旋转方向
    local player = GetClientPlayer()
    local scene = player.GetScene()
    HotPointRunMapOneDepth.nRecordX=player.nX
    HotPointRunMapOneDepth.nRecordY=player.nY
    HotPointRunMapOneDepth.nRecordZ=player.nZ
    HotPointRunMapOneDepth.nMinX,HotPointRunMapOneDepth.nMinY,HotPointRunMapOneDepth.nMinZ=player.nX,player.nY,player.nZ
    if HotPointRunMapOneDepth.nMaxX==0 and HotPointRunMapOneDepth.nMaxY==0 then
        HotPointRunMapOneDepth.nMaxX,HotPointRunMapOneDepth.nMaxY,HotPointRunMapOneDepth.nMaxZ=scene.GetXYZMax()
    else
        
    end
    --根据地图大小设置跑图间距
    nMapMinLen=math.min(HotPointRunMapOneDepth.nMaxX-HotPointRunMapOneDepth.nMinX,HotPointRunMapOneDepth.nMaxY-HotPointRunMapOneDepth.nMinY)
    fStep=ReserveDecimalPlaces(nMapMinLen/2000/20,1)
    if fStep<1 then
        --控制最小间距2000
        fStep=1
    elseif fStep>=3.6 then
        --控制最大间距7200
        fStep=3.6
    end
    HotPointRunMapOneDepth.nStepSize=fStep*2000
    LOG.INFO("HotPointRunMapOneDepth.nStepSize :"..HotPointRunMapOneDepth.nStepSize)
    --HotPointRunMapOneDepth.nMaxX,HotPointRunMapOneDepth.nMaxY=7000,7000 --测试使用
    --初始化第一个视角
    LOG.INFO("HotPointRunMapOneDepth start")
    tbSleep.nSleepType=tbSleepType.CullSleep
    HotPointRunMapOneDepth.fsm:Switch("NextCull") --第一个点开启裁剪
    --HotPointRunMapOneDepth.fsm:Switch("NextCamera")                                                  --切换为跑图状态
end

function  HotPointRunMapOneDepth.Init:OnLeave()
end

function tbNextPoint.IsValidPosition(nX,nY)
    if nX>HotPointRunMapOneDepth.nMaxX or nY>HotPointRunMapOneDepth.nMaxY then
        return false
    else
        return true
    end
end


-----跳下一个地点----------------
tbNextPoint.DirectionType={
    Right=1,
    Up=2,
    Left=3,
    Down=4
}
tbNextPoint.nDirection=tbNextPoint.DirectionType.Right
HotPointRunMapOneDepth.bRunMapEnd=false
HotPointRunMapOneDepth.NextPoint = BaseState:New("NextPoint")
function  HotPointRunMapOneDepth.NextPoint:OnEnter()                                               -- 设置等待初始时间(单位:毫秒) 
end

function  HotPointRunMapOneDepth.NextPoint:OnUpdate()
    local nRecordXLeft=HotPointRunMapOneDepth.nRecordX-HotPointRunMapOneDepth.nStepSize
    local nRecordXRight=HotPointRunMapOneDepth.nRecordX+HotPointRunMapOneDepth.nStepSize
    local nRecordYUp=HotPointRunMapOneDepth.nRecordY+HotPointRunMapOneDepth.nStepSize
    if tbNextPoint.nDirection == tbNextPoint.DirectionType.Right then
        --上个操作往右走 这次只能往右和上
        if nRecordXRight<=HotPointRunMapOneDepth.nMaxX then
            HotPointRunMapOneDepth.nRecordX=nRecordXRight
        else
            tbNextPoint.nDirection=tbNextPoint.DirectionType.Up
            if nRecordYUp<=HotPointRunMapOneDepth.nMaxY then
                HotPointRunMapOneDepth.nRecordY=nRecordYUp
            else
                --跑图结束
                HotPointRunMapOneDepth.bRunMapEnd=true
            end
        end
    elseif tbNextPoint.nDirection==tbNextPoint.DirectionType.Up then
        --上个操作往上走 这次只能往左和右
        if nRecordXRight<=HotPointRunMapOneDepth.nMaxX then
            --右边合法(上次在左边尽头往上走)
            tbNextPoint.nDirection=tbNextPoint.DirectionType.Right
            HotPointRunMapOneDepth.nRecordX=nRecordXRight
        else
            --左边合法(上次在右边尽头往上走)
            tbNextPoint.nDirection=tbNextPoint.DirectionType.Left
            HotPointRunMapOneDepth.nRecordX=nRecordXLeft
        end
    elseif tbNextPoint.nDirection==tbNextPoint.DirectionType.Left then
        --上个操作往左走 这次只能往左和上
        if nRecordXLeft>=HotPointRunMapOneDepth.nMinX then
            HotPointRunMapOneDepth.nRecordX=nRecordXLeft
        else
            tbNextPoint.nDirection=tbNextPoint.DirectionType.Up
            if nRecordYUp<=HotPointRunMapOneDepth.nMaxY then
                HotPointRunMapOneDepth.nRecordY=nRecordYUp
            else
                --跑图结束
                HotPointRunMapOneDepth.bRunMapEnd=true
            end
        end
    end
    if HotPointRunMapOneDepth.bRunMapEnd then
        --跑图结束
        local szRet=JsonEncode(tbHotPointData)
        local file=io.open(SearchPanel.szCurrentInterfacePath.."Data.json","w")
        if file then
            file:write(szRet)
            file:close()
            LoginMgr.Log("HotPointRunMapOneDepth","RunMapEnd")
        end
        --将场景信息写入本地文件
        local player = GetClientPlayer()
        local scene = player.GetScene()
        local szFileName=tostring(scene.dwMapID)
        LoginMgr.Log("HotPointRunMapOneDepth",szFileName)
        file=io.open(SearchPanel.szCurrentInterfacePath..szFileName,"w")
        if file then
            local szContent=string.format("%d|%d\n",HotPointRunMapOneDepth.nMaxX,HotPointRunMapOneDepth.nMaxY)
            szContent=szContent..string.format("%d|%d,%d|%d\n",HotPointRunMapOneDepth.nMinX,HotPointRunMapOneDepth.nMinY,HotPointRunMapOneDepth.nRecordX,HotPointRunMapOneDepth.nRecordY)
            szContent=szContent..string.format("%d|%d",tbSleepTime[tbSleepType.NextPointSleep],tbSleepTime[tbSleepType.CameraRotationSleep])
            file:write(szContent)
            file:close()
        end
        OutputMessage("MSG_SYS","HotPointRunMapOneDepth end")
        bStopFrameFlag=true
        Timer.DelAllTimer(HotPointRunMapOneDepth)
    else
        SendGMCommand(string.format("player.SetPosition(%d,%d,0);player.BirdFlyTo(%d,%d,0)",HotPointRunMapOneDepth.nRecordX,HotPointRunMapOneDepth.nRecordY,HotPointRunMapOneDepth.nRecordX,HotPointRunMapOneDepth.nRecordY))
        --tbSleep.nSleepType=tbSleepType.NextPointSleep
        --HotPointRunMapOneDepth.fsm:Switch("Sleep")
        HotPointRunMapOneDepth.fsm:Switch("NextCull")
    end
end

function  HotPointRunMapOneDepth.NextPoint:OnLeave()
    
end

--传送点后 需要旋转镜头触发裁剪
HotPointRunMapOneDepth.NextCull = BaseState:New("NextCull")
function  HotPointRunMapOneDepth.NextCull:OnEnter()                                               -- 设置等待初始时间(单位:毫秒) 
    
end

function  HotPointRunMapOneDepth.NextCull:OnUpdate()
    if tbNextCamera.nRotationIndex == #HotPointRunMapOneDepth.list_CameraStatue+1 then      --四向转完成
        tbNextCamera.nRotationIndex=1
        tbSleep.nSleepType=tbSleepType.CameraRotationSleep
        HotPointRunMapOneDepth.fsm:Switch("NextCamera")
    else
        tbNextCamera.nRotationIndex=tbNextCamera.nRotationIndex+1
        tbNextCamera.RotationCamera()               --转向
        tbSleep.nSleepType=tbSleepType.CullSleep
        HotPointRunMapOneDepth.fsm:Switch("Sleep")
    end
end

function  HotPointRunMapOneDepth.NextCull:OnLeave()
    
end


-----跳下一个视角----------------
tbNextCamera.nRotationIndex=1
tbNextCamera.angle = {} --角度
function tbNextCamera.RotationCamera()
    local nRotationIndex=tbNextCamera.nRotationIndex%#HotPointRunMapOneDepth.list_CameraStatue
    if  nRotationIndex==0 then
        nRotationIndex=#HotPointRunMapOneDepth.list_CameraStatue
    end
    local szCmd = HotPointRunMapOneDepth.list_CameraStatue[nRotationIndex]
    print(nRotationIndex)
    tbNextCamera.angle = SearchPanel.StringSplit(szCmd,",")
    --SetCameraStatus(tbNextCamera.angle[1],tbNextCamera.angle[2],tbNextCamera.angle[3],tbNextCamera.angle[4])
    Camera_SetRTParams(tbNextCamera.angle[2],tbNextCamera.angle[3],tbNextCamera.angle[4])
end

HotPointRunMapOneDepth.NextCamera = BaseState:New("NextCamera")
function  HotPointRunMapOneDepth.NextCamera:OnEnter()
    
end

function  HotPointRunMapOneDepth.NextCamera:OnUpdate()
    if tbNextCamera.nRotationIndex == #HotPointRunMapOneDepth.list_CameraStatue+1 then      --四向转完成
        tbNextCamera.nRotationIndex=1
        HotPointRunMapOneDepth.fsm:Switch("NextPoint")
    else
        tbGetPlayerInfo.GetPlayerInfo()
        tbNextCamera.nRotationIndex=tbNextCamera.nRotationIndex+1
        tbNextCamera.RotationCamera()               --转向
        tbSleep.nSleepType=tbSleepType.CameraRotationSleep
        HotPointRunMapOneDepth.fsm:Switch("Sleep")
    end
end

function  HotPointRunMapOneDepth.NextCamera:OnLeave()
    
end

-----sleep----------------
tbSleep.nSleepType=tbSleepType.CameraRotationSleep
tbSleep.nStartTime=0
HotPointRunMapOneDepth.Sleep = BaseState:New("Sleep")

function  HotPointRunMapOneDepth.Sleep:OnEnter()
    tbSleep.nStartTime = GetTickCount()
end

function  HotPointRunMapOneDepth.Sleep:OnUpdate()
    local nCurrentTime = GetTickCount()                                          -- 当前时间(单位:毫秒)
    local nSleep = tbSleepTime[tbSleep.nSleepType]
    if nCurrentTime - tbSleep.nStartTime >= nSleep*1000 then                               -- 原地停 stay 秒
        if tbSleep.nSleepType==tbSleepType.CullSleep then
            HotPointRunMapOneDepth.fsm:Switch("NextCull")
        else
            HotPointRunMapOneDepth.fsm:Switch("NextCamera")                                                  -- 切换视角状态
        end
    end
end

function  HotPointRunMapOneDepth.Sleep:OnLeave()
    
end

-----创建状态机---------------
HotPointRunMapOneDepth.fsm = FsmMachine:New()
HotPointRunMapOneDepth.fsm:AddState(HotPointRunMapOneDepth.NextPoint)
HotPointRunMapOneDepth.fsm:AddState(HotPointRunMapOneDepth.NextCamera)
HotPointRunMapOneDepth.fsm:AddState(HotPointRunMapOneDepth.Sleep)
HotPointRunMapOneDepth.fsm:AddState(HotPointRunMapOneDepth.NextCull)
HotPointRunMapOneDepth.fsm:AddInitState(HotPointRunMapOneDepth.Init)
-----------------------------

function HotPointRunMapOneDepth.FrameUpdate()
    if not HotPointRunMapOneDepth.bSwitch then
        return
    end

    HotPointRunMapOneDepth.fsm.curState:OnUpdate()
end

local nCurrentTime = 0
local nNextTime=20
local nCurrentStep=1
--暂停帧更新标注
local HotPoint={}

local function FrameUpdate()
    if not HotPointRunMapOneDepth.bSwitch then
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
        elseif string.find(szCmd,"HotPoint_Start") then
            Timer.AddFrameCycle(HotPointRunMapOneDepth,1,HotPointRunMapOneDepth.FrameUpdate)
            bStopFrameFlag=false
        elseif string.find(szCmd,"perfeye_stop") then
            SearchPanel.bPerfeye_Stop=true
        end
        nCurrentTime=GetTickCount()
        nCurrentStep=nCurrentStep+1
    end
end

--加载tab文件
local tbRunMapData=SearchPanel.LoadRunMapFile(SearchPanel.szCurrentInterfacePath.."RunMap.tab",2)
list_RunMapCMD=tbRunMapData[1]
list_RunMapTime=tbRunMapData[2]
--启动帧更新函数
Timer.AddFrameCycle(HotPoint,1,function ()
    FrameUpdate()
end)

LoginMgr.Log("HotPointRunMapOneDepth","HotPointRunMapOneDepth End")

return HotPointRunMapOneDepth
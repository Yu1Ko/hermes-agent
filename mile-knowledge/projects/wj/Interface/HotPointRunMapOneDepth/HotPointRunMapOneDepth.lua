LoginMgr.Log("HotPointRunMapOneDepth","HotPointRunMapOneDepth imported")
HotPointRunMapOneDepth={}
local list_RunMapTime = {}
local list_RunMapCMD = {}
local bStopFrameFlag = true

HotPointRunMapOneDepth.nStepSize = 7200
HotPointRunMapOneDepth.IsRun = false
HotPointRunMapOneDepth.nMaxX = 0	--设置地图最大X
HotPointRunMapOneDepth.nMaxY = 0	--设置地图最大Y
HotPointRunMapOneDepth.nMaxZ = 0	--设置地图最大Z
HotPointRunMapOneDepth.nMinX = 0	--设置地图最小X
HotPointRunMapOneDepth.nMinY = 0	--设置地图最小Y
HotPointRunMapOneDepth.nMinZ = 0	--设置地图最小Z

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

HotPointRunMapOneDepth.nRunType=1
HotPointRunMapOneDepth.nDedupType=0   -- 0=保留全部数据(分支2) 1=每格只留最差数据(分支1)

--3套方案  1重高空往下接触的第一个位置(房顶问题)    2直接设置Z坐标为0(陷到地底的问题) 3自定义z坐标
function HotPointRunMapOneDepth.SetRunType(nRunType)
    HotPointRunMapOneDepth.nRunType=nRunType
end
--分支1/2：每个格子的数据保留策略 0=保留全部 1=只留最差
function HotPointRunMapOneDepth.SetDedupType(nDedupType)
    HotPointRunMapOneDepth.nDedupType=nDedupType
end
--第3套方案专用参数
HotPointRunMapOneDepth.nCustomRangeZ=0
function HotPointRunMapOneDepth.SetCustomRangeZ(nCustomRangeZ)
    HotPointRunMapOneDepth.nCustomRangeZ=nCustomRangeZ
end

function HotPointRunMapOneDepth.SetStepSize(nStepSize)
    HotPointRunMapOneDepth.nStepSize=nStepSize
end

local tbSleep={}
local tbNextPoint={}
local tbNextCamera={}
local tbNextCull={}
local tbCheckNextPoint={}

HotPointRunMapOneDepth.list_CameraStatue = {
	[1] = "1083, 1, 1.570, -0.217",	--东
	[2] = "1083, 1, 3.140, -0.217",	--西
	[3] = "1083, 1, 4.710, -0.217",	--南
	[4] = "1083, 1, 6.280, -0.217"	--北
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
    [tbSleepType.CullSleep]=0.5
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
tbGetPlayerInfo.Info=nil
function tbGetPlayerInfo.GetPlayerInfo()
	-- 角色朝向（东南西北）
	--XGame 需要将Y和Z对调
    local player=GetClientPlayer()
    HotPointRunMapOneDepth.nRecordZ=player.nZ --记录Z坐标 客户端会更新脚本
	tbGetPlayerInfo.szKey=string.format("(%d,%d,%d)",HotPointRunMapOneDepth.nRecordX,1000000,HotPointRunMapOneDepth.nRecordY)
    --tbGetPlayerInfo.szKeyGM=string.format("(%d,%d,%d)",HotPointRunMapOneDepth.nRecordX,HotPointRunMapOneDepth.nRecordY,HotPointRunMapOneDepth.nRecordZ)
    tbGetPlayerInfo.szKeyGM=string.format("(%d,%d,%d)",player.nX,player.nY,player.nZ)
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
    if tbGetPlayerInfo.Info==nil then
        tbGetPlayerInfo.Info=GetHotPointReader().GetFrameDataInfo()
    end
    local info=GetHotPointReader().GetFrameDataInfo()
    local nSetPassCall=info.setPass    --setPassCall
    local nDrawcall = info.DrawCallCnt    --drawCall  DrawCallCnt
    local nDrawBatch = info.DrawBatchCnt    --drawbatch  DrawBatchCnt
    local nVertices=0    --顶点数
    local nTriangles=info.FaceCnt --面数
    local nMemory=info.vulkanMemory --内存
    local fps=info.FPS    --FPS
    local ms=1000/fps-1000/fps%0.1  --帧耗时
	local szCMD=string.format('SendGMCommand("player.SetPosition%s;player.BirdFlyTo%s");Camera_SetRTParams(%s);print%s;',tbGetPlayerInfo.szKeyGM,tbGetPlayerInfo.szKeyGM,HotPointRunMapOneDepth.list_CameraStatue[tbNextCamera.nRotationIndex]:sub(6, -1),tbGetPlayerInfo.szKeyGM3dPos)
    local szInfo=szCamerInfo..string.format("%d,%d,%d,%d,%d,%d,%d,%0.1f,%s",nSetPassCall,nDrawcall,nDrawBatch,nVertices,nTriangles,nMemory,fps,ms,szCMD)
    table.insert(tbHotPointData.performanceData[tbGetPlayerInfo.szKey],szInfo)
end

function HotPointRunMapOneDepth.SetNullData(nX,nY)
    -- body
    --print("HotPointRunMapOneDepth.SetNullData")
    local szKey=string.format("(%d,%d,%d)",nX,1000000,nY)
    --print(szKey)
    if not tbHotPointData.performanceData[szKey] then
        tbHotPointData.performanceData[szKey]={}
    end
    local szInfo="(0.00, 0.00, 0.00),0,0,0,0,0,0,0,0,testGM"
    table.insert(tbHotPointData.performanceData[szKey],szInfo)
    szInfo="(0.00, 90.00, 0.00),0,0,0,0,0,0,0,0,testGM"
    table.insert(tbHotPointData.performanceData[szKey],szInfo)
    szInfo="(0.00, 180.00, 0.00),0,0,0,0,0,0,0,0,testGM"
    table.insert(tbHotPointData.performanceData[szKey],szInfo)
    szInfo="(0.00, 270.00, 0.00),0,0,0,0,0,0,0,0,testGM"
    table.insert(tbHotPointData.performanceData[szKey],szInfo)
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
	--有些坐标会强制角色位移
	HotPointRunMapOneDepth.nRecordX=HotPointRunMapOneDepth.nMinX
	HotPointRunMapOneDepth.nRecordY=HotPointRunMapOneDepth.nMinY
	HotPointRunMapOneDepth.nRecordZ=player.nZ
    --HotPointRunMapOneDepth.nMinX,HotPointRunMapOneDepth.nMinY,HotPointRunMapOneDepth.nMinZ=player.nX,player.nY,player.nZ
    if HotPointRunMapOneDepth.nMaxX==0 and HotPointRunMapOneDepth.nMaxY==0 then
        HotPointRunMapOneDepth.nMaxX,HotPointRunMapOneDepth.nMaxY,HotPointRunMapOneDepth.nMaxZ=scene.GetXYZMax()
    else
        nX,nY,HotPointRunMapOneDepth.nMaxZ=scene.GetXYZMax()
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
    if HotPointRunMapOneDepth.nStepSize==7200 then
        HotPointRunMapOneDepth.nStepSize=fStep*2000
    end
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

        --将场景信息写入本地文件
        local player = GetClientPlayer()
        local scene = player.GetScene()
        local szFileName=tostring(scene.dwMapID)
        LoginMgr.Log("HotPointRunMapOneDepth",szFileName)
        file=io.open(SearchPanel.szCurrentInterfacePath..szFileName,"w")
        if file then
            local nX,nY,nZ=scene.GetXYZMax()
            local szContent=string.format("%d|%d\n",nX,nY)
            local nMaxX=nX-nX%HotPointRunMapOneDepth.nStepSize
            local nMaxY=nY-nY%HotPointRunMapOneDepth.nStepSize
            --起点不为左下角
            if HotPointRunMapOneDepth.nMinX~=0 and HotPointRunMapOneDepth.nMinY~=0 then
                HotPointRunMapOneDepth.SetNullData(0,0)
            end
            --终点不为右上角
            if nMaxX~=HotPointRunMapOneDepth.nRecordX and nMaxY~=HotPointRunMapOneDepth.nRecordY then
                HotPointRunMapOneDepth.SetNullData(nMaxX,nMaxY)
            end
            szContent=szContent..string.format("%d|%d,%d|%d\n",0,0,nMaxX,nMaxY)
            --szContent=szContent..string.format("%d|%d,%d|%d\n",HotPointRunMapOneDepth.nMinX,HotPointRunMapOneDepth.nMinY,nRecordX,HotPointRunMapOneDepth.nRecordY)
            szContent=szContent..string.format("%d|%d\n",tbSleepTime[tbSleepType.NextPointSleep],tbSleepTime[tbSleepType.CameraRotationSleep])
            szContent=szContent..string.format("%d",HotPointRunMapOneDepth.nStepSize)
            file:write(szContent)
            file:close()
        end
        -- 分支1：每个格子只保留性能最差的一份数据（Ms最大） / 分支2：保留全部
        if HotPointRunMapOneDepth.nDedupType == 1 then
            for szKey, tbEntries in pairs(tbHotPointData.performanceData) do
                -- testGM 占位数据不处理
                local bTestGM = false
                for _, entry in ipairs(tbEntries) do
                    if string.find(entry, "testGM") then
                        bTestGM = true
                        break
                    end
                end
                if not bTestGM and #tbEntries > 1 then
                    local nMaxMs = 0
                    local nMaxIdx = 1
                    for i, entry in ipairs(tbEntries) do
                        local parts = SearchPanel.StringSplit(entry, ",")
                        local nMs = tonumber(parts[9]) or 0
                        if nMs > nMaxMs then
                            nMaxMs = nMs
                            nMaxIdx = i
                        end
                    end
                    tbHotPointData.performanceData[szKey] = {tbEntries[nMaxIdx]}
                end
            end
        end
        --将坐标记录至本地
        local szRet=JsonEncode(tbHotPointData)
        local file=io.open(SearchPanel.szCurrentInterfacePath.."Data.json","w")
        if file then
            file:write(szRet)
            file:close()
            LoginMgr.Log("HotPointRunMapOneDepth","RunMapEnd")
        end
        OutputMessage("MSG_SYS","HotPointRunMapOneDepth end")
        bStopFrameFlag=true
        Timer.DelAllTimer(HotPointRunMapOneDepth)
    else
        local player=GetClientPlayer()
        tbCheckNextPoint.nX=player.nX
        tbCheckNextPoint.nY=player.nY
        --2套方案  1重高空往下接触的第一个位置(房顶问题)    2直接设置Z坐标为0跑地宫和房子(陷到地底的问题)
        if HotPointRunMapOneDepth.nRunType==2 then
            SendGMCommand(string.format("player.SetPosition(%d,%d,%d);player.BirdFlyTo(%d,%d,%d)",HotPointRunMapOneDepth.nRecordX,HotPointRunMapOneDepth.nRecordY,0,HotPointRunMapOneDepth.nRecordX,HotPointRunMapOneDepth.nRecordY,0))
        elseif HotPointRunMapOneDepth.nRunType==3 then
            --local nX,nY,nZ=GetClientPlayer().GetScene().GetInterceptPoint(HotPointRunMapOneDepth.nRecordX,HotPointRunMapOneDepth.nRecordY,HotPointRunMapOneDepth.nCustomRangeZ+3000,HotPointRunMapOneDepth.nRecordX,HotPointRunMapOneDepth.nRecordY,0)
            SendGMCommand(string.format("player.SetPosition(%d,%d,%d);player.BirdFlyTo(%d,%d,%d)",HotPointRunMapOneDepth.nRecordX,HotPointRunMapOneDepth.nRecordY,HotPointRunMapOneDepth.nCustomRangeZ,HotPointRunMapOneDepth.nRecordX,HotPointRunMapOneDepth.nRecordY,HotPointRunMapOneDepth.nCustomRangeZ))
        else
            local nX,nY,nZ=GetClientPlayer().GetScene().GetInterceptPoint(HotPointRunMapOneDepth.nRecordX,HotPointRunMapOneDepth.nRecordY,HotPointRunMapOneDepth.nMaxZ,HotPointRunMapOneDepth.nRecordX,HotPointRunMapOneDepth.nRecordY,0)
            SendGMCommand(string.format("player.SetPosition(%d,%d,%d);player.BirdFlyTo(%d,%d,%d)",HotPointRunMapOneDepth.nRecordX,HotPointRunMapOneDepth.nRecordY,nZ,HotPointRunMapOneDepth.nRecordX,HotPointRunMapOneDepth.nRecordY,nZ))
        end
        --tbSleep.nSleepType=tbSleepType.NextPointSleep
        --HotPointRunMapOneDepth.fsm:Switch("Sleep")
        --验证是否传送成功
        HotPointRunMapOneDepth.fsm:Switch("CheckNextPoint")
	end
end

function  HotPointRunMapOneDepth.NextPoint:OnLeave()

end


--验证是否传送成功
HotPointRunMapOneDepth.bTest=false
tbCheckNextPoint.nIndex=2
tbCheckNextPoint.nWaitTime=1
tbCheckNextPoint.nTimer=0
tbCheckNextPoint.bWaitFlag=false
HotPointRunMapOneDepth.CheckNextPoint = BaseState:New("CheckNextPoint")
function  HotPointRunMapOneDepth.CheckNextPoint:OnEnter()
    
end

function  HotPointRunMapOneDepth.CheckNextPoint:OnUpdate()
    if tbCheckNextPoint.bWaitFlag then
        if GetTickCount()-tbCheckNextPoint.nTimer >= tbCheckNextPoint.nWaitTime*1000 then
            --时间到
            tbCheckNextPoint.bWaitFlag=false
            tbCheckNextPoint.nTimer=GetTickCount()
        else
            return
        end
    end

    local player=GetClientPlayer()
    --[[
    if player.nX==tbCheckNextPoint.nX and player.nY==tbCheckNextPoint.nY then
        --传送点位出现异常
        --HotPointRunMapOneDepth.bTest=false
        if tbCheckNextPoint.nIndex==0 then
            --多次检查失败 服务器报错,重新登录
            Global.BackToLogin(false)
            tbCheckNextPoint.nIndex=2
            --Timer.Add(HotPointRunMapOneDepth,10,function ()
                --AutoLogin.LoginStart()
                --g_tbLoginData.LoginView:Login()
            --end)
        else
            --尝试重新传送
            tbCheckNextPoint.bWaitFlag=true
            tbCheckNextPoint.nTimer=GetTickCount()
            tbCheckNextPoint.nIndex=tbCheckNextPoint.nIndex-1
            local nX,nY,nZ=player.GetScene().GetInterceptPoint(HotPointRunMapOneDepth.nRecordX,HotPointRunMapOneDepth.nRecordY,HotPointRunMapOneDepth.nMaxZ,HotPointRunMapOneDepth.nRecordX,HotPointRunMapOneDepth.nRecordY,0)
            SendGMCommand(string.format("player.SetPosition(%d,%d,%d);player.BirdFlyTo(%d,%d,%d)",HotPointRunMapOneDepth.nRecordX,HotPointRunMapOneDepth.nRecordY,nZ,HotPointRunMapOneDepth.nRecordX,HotPointRunMapOneDepth.nRecordY,nZ))
        end
    else
        --正常 记录点位
        tbCheckNextPoint.nIndex=2
        HotPointRunMapOneDepth.fsm:Switch("NextCull")
    end]]
    --正常 记录点位
    tbCheckNextPoint.nIndex=2
    HotPointRunMapOneDepth.fsm:Switch("NextCull")
end

function  HotPointRunMapOneDepth.CheckNextPoint:OnLeave()

end

--传送点后 需要旋转镜头触发裁剪
HotPointRunMapOneDepth.NextCull = BaseState:New("NextCull")
function  HotPointRunMapOneDepth.NextCull:OnEnter()                                               -- 设置等待初始时间(单位:毫秒)
    SendGMCommand("player.Revive()")
end

function  HotPointRunMapOneDepth.NextCull:OnUpdate()
    if tbNextCamera.nRotationIndex == #HotPointRunMapOneDepth.list_CameraStatue+1 then		--四向转完成
        tbNextCamera.nRotationIndex=1
        tbSleep.nSleepType=tbSleepType.CameraRotationSleep
        HotPointRunMapOneDepth.fsm:Switch("NextCamera")
    else
        tbNextCamera.nRotationIndex=tbNextCamera.nRotationIndex+1
        tbNextCamera.RotationCamera()				--转向
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
    if tbNextCamera.nRotationIndex == #HotPointRunMapOneDepth.list_CameraStatue+1 then		--四向转完成
		tbNextCamera.nRotationIndex=1
		HotPointRunMapOneDepth.fsm:Switch("NextPoint")
    else
        tbGetPlayerInfo.GetPlayerInfo()
        --print(string.format('采集 -- 方向:%d',  tbNextCamera.nRotationIndex))
        tbNextCamera.nRotationIndex=tbNextCamera.nRotationIndex+1
        tbNextCamera.RotationCamera()				--转向
        --print(string.format('转向 -- 由%d---%d',tbNextCamera.nRotationIndex-1,tbNextCamera.nRotationIndex))
        tbSleep.nSleepType=tbSleepType.CameraRotationSleep
        HotPointRunMapOneDepth.fsm:Switch("Sleep")
	end
end

function  HotPointRunMapOneDepth.NextCamera:OnLeave()
    
end

 --创建截图文件,通知自动化截图
 function  HotPointRunMapOneDepth.ScreenShot()
    --格式:地图id_坐标_朝向
    local player = GetClientPlayer()
    local scene = player.GetScene()
    local strPos=string.format("(%d,%d,%d)",HotPointRunMapOneDepth.nRecordX,1000000,HotPointRunMapOneDepth.nRecordY)
    local strRot=string.format("(0.0, %0.1f, 0.0)",((tbNextCamera.nRotationIndex-1)%(#HotPointRunMapOneDepth.list_CameraStatue))*90)
    local strFileName=string.format("%s_%s_%s",tostring(scene.dwMapID),strPos,strRot)
    HotPointRunMapOneDepth.CreateEmptyFile(strFileName)
 end

 function HotPointRunMapOneDepth.CreateEmptyFile(filename)
    local file = io.open(SearchPanel.szWorkPath.."hotpointscreen/" .. filename, "w")
    file:close()
end

-----sleep----------------
tbSleep.nSleepType=tbSleepType.CameraRotationSleep
tbSleep.nStartTime=0
HotPointRunMapOneDepth.Sleep = BaseState:New("Sleep")
tbSleep.nSleep=0

function  HotPointRunMapOneDepth.Sleep:OnEnter()
    tbSleep.nStartTime = GetTickCount()
    tbSleep.nSleep = tbSleepTime[tbSleep.nSleepType]
    --创建截图文件,通知自动化截图
    if tbSleep.nSleepType==tbSleepType.CullSleep then
        --最后一次cull时间加长 保证下一次取数据时的稳定性
        if tbNextCamera.nRotationIndex == #HotPointRunMapOneDepth.list_CameraStatue+1 then
            tbSleep.nSleep=tbSleepTime[tbSleepType.CameraRotationSleep]
            --打点1
            --HotPointRunMapOneDepth.ScreenShot()
        end
    elseif tbSleep.nSleepType==tbSleepType.CameraRotationSleep then
        --最后一次camer时间变短
        if tbNextCamera.nRotationIndex == #HotPointRunMapOneDepth.list_CameraStatue+1 then
            tbSleep.nSleep=tbSleepTime[tbSleepType.CullSleep]
        else
            --打点2,3,4
            --HotPointRunMapOneDepth.ScreenShot()
        end
    end
end

function  HotPointRunMapOneDepth.Sleep:OnUpdate()
    local nCurrentTime = GetTickCount()                                          -- 当前时间(单位:毫秒)
    --print(string.format('方向:%d--sleepTime:%d',tbNextCamera.nRotationIndex,nSleep))
    if nCurrentTime - tbSleep.nStartTime >= tbSleep.nSleep*1000 then                               -- 原地停 stay 秒
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
HotPointRunMapOneDepth.fsm:AddState(HotPointRunMapOneDepth.CheckNextPoint)
HotPointRunMapOneDepth.fsm:AddInitState(HotPointRunMapOneDepth.Init)

-----------------------------

function HotPointRunMapOneDepth.FrameUpdate()
    if not HotPointRunMapOneDepth.bSwitch then
        return
    end
    if not SearchPanel.IsFromLoadingEnterGame() then
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
        nCurrentTime=GetTickCount()
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
        --LOG.INFO(szCmd.."===ok")
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
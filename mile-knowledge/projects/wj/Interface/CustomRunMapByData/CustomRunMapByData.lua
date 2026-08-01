CustomRunMapByData = {}
CustomRunMapByData.tbRunMapData={}    --跑图点数据  x,y,z,stay,mapid,action  stay:在该点停了时间 action:在该点执行什么行为,1 stay 2 转一圈 
CustomRunMapByData.bSwitch=false
CustomRunMapByData.nRunMapCount=1 --默认单程
CustomRunMapByData.nLine=1    --当前跑图执行到哪一行 lua以1为索引
CustomRunMapByData.nStartTime=0
CustomRunMapByData.nStay=0     --tb表中的stay
CustomRunMapByData.nAction=0     --tb表中的action
CustomRunMapByData.nRowCount=0        --一共有多少个跑图点
CustomRunMapByData.nSleepType=0       --根据不同的sleep类型 决定sleep多少秒
CustomRunMapByData.bRunMapEnd=false   --是否跑图结束
CustomRunMapByData.bForwardRun=true    --是否正向跑
CustomRunMapByData.bCircle=false --是否开启原地转圈
CustomRunMapByData.bVideoSwitch=false --是否开启切画质
CustomRunMapByData.bCamerafollow=false --是否开启镜头跟随

--记录是否在RunToNextPoint:OnLeave时需要 更改CustomRunMapByData.nLine的值,卡住直接跳转的情况下不需要修改nLine
CustomRunMapByData.bNeedAddLine=true

local tbAction={
    stay=1,
    cycle=2,
    sfx=3,
}

local tbSleepType={
    setPostionSleep=0,
    staySleep=1
}

function CustomRunMapByData.SetCamera(nSetCamera)
    if tonumber(nSetCamera) == 1 then
        CustomRunMapByData.bCamerafollow = true
    end
end

--将tb转换成 {['x']=x,['y']=y,['z']=z,['stay']=stay,['mapid']=mapid,['action']=action}
local function ExchangeRunMapData(tbRunMapData)
    local nStay,nMapid,nAction=nil,nil,nil
    for __,tbData in ipairs(tbRunMapData) do
        nStay=tonumber(tbData[4])
        nMapid=tonumber(tbData[5])
        nAction=tonumber(tbData[6])
        if not nStay then
            nStay=0
            nMapid=0
            nAction=0
        end
        table.insert(CustomRunMapByData.tbRunMapData,{
            x=tonumber(tbData[1]),
            y=tonumber(tbData[2]),
            z=tonumber(tbData[3]),
            stay=nStay,
            mapid=nMapid,
            action=nAction
        })
    end
end

function CustomRunMapByData.Start(tbRunMapData,nRunMapCount,bCircle,bVideoSwitch,bCamerafollow)
    if not tbRunMapData then
        LOG.INFO("CustomRunMapByData not tbRunMapData")
        return
    end
    if bCircle~=nil then
        CustomRunMapByData.bCircle=bCircle
    end
    if bCamerafollow~=nil then
        CustomRunMapByData.bCamerafollow=bCamerafollow
    end
    if bVideoSwitch~=nil then
        CustomRunMapByData.bVideoSwitch=bVideoSwitch
    end
    --设置跑图次数
    if nRunMapCount~=nil and nRunMapCount>=0 then
        CustomRunMapByData.nRunMapCount=nRunMapCount
    else
        CustomRunMapByData.nRunMapCount=1
    end
    LOG.INFO("CustomRunMapByData.nRunMapCount start:"..tostring(CustomRunMapByData.nRunMapCount))
    --状态机切换到初始状态
    CustomRunMapByData.fsm:AddInitState(CustomRunMapByData.Init)
    --重置数据
    CustomRunMapByData.bNeedAddLine=true
    CustomRunMapByData.tbRunMapData={}
    CustomRunMapByData.bRunMapEnd=false
    CustomRunMapByData.nLine=1
    CustomRunMapByData.nRowCount=#tbRunMapData
    CustomRunMapByData.bForwardRun=true
    --开启跑图开关 跑图次数-1
    CustomRunMapByData.nRunMapCount=CustomRunMapByData.nRunMapCount-1
    CustomRunMapByData.bSwitch=true
    --处理跑图数据
    ExchangeRunMapData(tbRunMapData)
end

--获取 是否跑图完成
function CustomRunMapByData.IsEnd()
    return CustomRunMapByData.bRunMapEnd
end

-----init----------------
--初始化状态 传送到起一个点并进入Sleep状态
CustomRunMapByData.Init = BaseState:New("Init")

function  CustomRunMapByData.Init:OnEnter()
    MoveForWard_Stop()
end

function  CustomRunMapByData.Init:OnUpdate()
    --初始化时默认传送到第一个点
    local szCMD="/gm player.SetPosition(%s,%s,%s)"
    -- 防止卡住后下标越界
    if CustomRunMapByData.nLine>CustomRunMapByData.nRowCount then
        -- 人物卡死强制返回登录界面
        CustomRunMapByData.nLine=CustomRunMapByData.nRowCount-1
    end
    local tbData=CustomRunMapByData.tbRunMapData[CustomRunMapByData.nLine]
    AutoTestLog.INFO("error CustomRunMapByData.nLine:"..CustomRunMapByData.nLine)
    szCMD=string.format(szCMD,tbData['x'],tbData['y'],tbData['z'])
    SearchPanel.RunCommand(szCMD)
    CustomRunMapByData.nSleepType=tbSleepType.setPostionSleep       -- 传送点后设置SleepType
    CustomRunMapByData.bNeedAddLine=true --完成传送后正常进行nLine计数
    CustomRunMapByData.fsm:Switch("Sleep")
end

function  CustomRunMapByData.Init:OnLeave()
    --记录当前line的stay 和action  因为跑到当前目标点后,会根据action执行不同的状态
    CustomRunMapByData.nStay=CustomRunMapByData.tbRunMapData[CustomRunMapByData.nLine]['stay']
    CustomRunMapByData.nAction=CustomRunMapByData.tbRunMapData[CustomRunMapByData.nLine]['action']
    --CustomRunMapByData.nLine=CustomRunMapByData.nLine+1
end

-----Sleep----------------
--nSleepType=0 sleep:3秒,nSleepType=1 sleep:stay秒
local tbSleepTime={
    [tbSleepType.setPostionSleep]=3,
    [tbSleepType.staySleep]=nil
}
CustomRunMapByData.Sleep = BaseState:New("Sleep")
local nSleepStartTime=0
function  CustomRunMapByData.Sleep:OnEnter()
    nSleepStartTime=GetTickCount()   --初始化时间
    MoveForWard_Stop()  --进入Sleep状态后 玩家必须停止
end

function  CustomRunMapByData.Sleep:OnUpdate()
    --默认使用nSleepType进行配置
    local nSleepTime=tbSleepTime[CustomRunMapByData.nSleepType]
    --特殊的类型用staySleep
    if CustomRunMapByData.nSleepType==tbSleepType.staySleep then
        nSleepTime=CustomRunMapByData.nStay
    end

    if GetTickCount() - nSleepStartTime >= nSleepTime*1000 then    --计时器
        nSleepStartTime=GetTickCount()     --重置初始时间
        if CustomRunMapByData.nSleepType==tbSleepType.setPostionSleep then
            --传送到第一个点sleep完成 开始往下一个点跑图
            CustomRunMapByData.fsm:Switch("RunToNextPoint")
            SendGMCommand("player.Revive()")
        elseif CustomRunMapByData.nSleepType==tbSleepType.staySleep then
            --原地停留stay秒完成 开始往下一个点跑图
            CustomRunMapByData.fsm:Switch("RunToNextPoint")
        else
            LOG.INFO("CustomRunMapByData set nSleepType Error:"..tostring(CustomRunMapByData.nSleepType))
            return
        end
    end
end

function  CustomRunMapByData.Sleep:OnLeave()
end

-----RunToNextPoint----------------
--计算玩家当前坐标朝向目标点方向 x,y 并判断是否调整角色视角
local nLastTurnto=0
local function AdjustDirection(nPlayerX,nPlayerY,nTargetX,nTargetY)
    local nVectorX =  nTargetX - nPlayerX
    local nVectorY =  nTargetY - nPlayerY

    local nTurnto = GetLogicDirection(nVectorX,nVectorY)
    --LOG.INFO(string.format("[RunMapByPoint] TurnTo {%d}",nTurnto))
    SearchPanel.MyExecuteScriptCommand("TurnTo("..tostring(nTurnto)..")")
    --if math.abs(nTurnto-nLastTurnto) >=15 then
        --两次朝向大于15度时 条件镜头角度 重置记录的朝向
        --nLastTurnto=nTurnto
        if CustomRunMapByData.bCamerafollow then
            TurnToFaceDirection()
        end
    --end
end

--计算是否到达下一个点
local function JudgeArrive(nPlayerX,nPlayerY,nTargetX,nTargetY)
    --LOG.INFO("JudgeArrive"..tostring(CustomRunMapByData.nLine))
    --LOG.INFO(string.format("[JudgeArrive] {%d},{%d}  {%d},{%d}",nPlayerX,nPlayerY,nTargetX,nTargetY))
    local nVectorX=nTargetX-nPlayerX
    local nVectorY=nTargetY-nPlayerY
    --向量误差在10以内 默认到达该点
    --LOG.INFO("JudgeArrive pos :"..tostring(nVectorX*nVectorX+nVectorY*nVectorY))
    if nVectorX*nVectorX+nVectorY*nVectorY<=800 then
        --LOG.INFO("JudgeArrive true")
        return true
    else
        --LOG.INFO("JudgeArrive false")
        return false
    end
end

CustomRunMapByData.RunToNextPoint = BaseState:New("RunToNextPoint")
--记录进入当前状态的初始时间
local nRunToNextPointStartTime=0


--根据['action']参数 来判断进入哪个状态
local function EnterStateByAction(nState)
    if nState==tbAction.stay then
        --进入sleep状态  将nSleepType置为staySleep
        CustomRunMapByData.nSleepType=tbSleepType.staySleep
        CustomRunMapByData.fsm:Switch("Sleep")
    elseif nState==tbAction.cycle  then
        --进入Cycle状态
        CustomRunMapByData.fsm:Switch("Cycle")
    elseif nState==tbAction.sfx  then
        --进入sfx状态 释放外装特效
        CustomRunMapByData.fsm:Switch("sfx")
    else
        --进入RunToNextPoint
        CustomRunMapByData.fsm:Switch("RunToNextPoint")
        --LOG.INFO("action :"..tostring(nState))
    end
end

function  CustomRunMapByData.RunToNextPoint:OnEnter()
    --LOG.INFO("RunToNextPoint:OnEnter:"..tostring(CustomRunMapByData.nLine))
    --进入当前状态的初始时间
    nRunToNextPointStartTime=GetTickCount()
    MoveForWard_Start()
    --记录当前line的stay 和action  因为跑到当前目标点后,会根据action执行不同的状态
    CustomRunMapByData.nStay=CustomRunMapByData.tbRunMapData[CustomRunMapByData.nLine]['stay']
    CustomRunMapByData.nAction=CustomRunMapByData.tbRunMapData[CustomRunMapByData.nLine]['action']
end

function  CustomRunMapByData.RunToNextPoint:OnUpdate()
    local player=GetClientPlayer()
    local tbData=CustomRunMapByData.tbRunMapData[CustomRunMapByData.nLine]
    --根据MapID判断是否需要地图传送
    if tbData['mapid']~=0 and tbData['mapid']~=player.GetMapID() then
        --地图传送
        SendGMCommand(string.format("player.SwitchMap(%d,1,%d,%d,%d)",tbData['mapid'],tbData['x'],tbData['y'],tbData['z']))
        return
    end
    if GetTickCount()-nRunToNextPointStartTime >15000 then
        --当前状态15秒未结束(也许是卡住了) 执行传送到目标点,并Sleep(参照init状态)
        --重置时间
        nRunToNextPointStartTime=GetTickCount()
        AutoTestLog.INFO("JumpToNext"..tostring(CustomRunMapByData.nLine))
        --CustomRunMapByData.bNeedAddLine=false --完成传送前关闭nLine计数
        AutoTestLog.INFO("nRunMapCount"..tostring(CustomRunMapByData.nRunMapCount))
        CustomRunMapByData.fsm:Switch("Init")
        return
    end
    if JudgeArrive(player.nX,player.nY,tbData['x'],tbData['y']) then
        --到达目标点  输出一下坐标
        --OutputMessage("MSG_SYS",string.format("Id:%d,(%d,%d,%d)",player.GetMapID(),tbData['x'],tbData['y'],tbData['z']))
        LOG.INFO(string.format("Autotest Id:%d,(%d,%d,%d)",player.GetMapID(),tbData['x'],tbData['y'],tbData['z']))
        if CustomRunMapByData.bForwardRun then
            --正向跑
            if CustomRunMapByData.nLine==CustomRunMapByData.nRowCount then
                --到达最后一个点 判断跑图是否结束
                if CustomRunMapByData.nRunMapCount==0 then
                    --跑图次数为0 跑图结束
                    CustomRunMapByData.bRunMapEnd=true
                    --关闭跑图帧更新
                    CustomRunMapByData.bSwitch=false
                    MoveForWard_Stop()
                else
                    --跑图次数不为0 反向跑 跑图次数-1
                    CustomRunMapByData.bForwardRun=false
                    CustomRunMapByData.nRunMapCount=CustomRunMapByData.nRunMapCount-1
                    --LOG.INFO("CustomRunMapByData.nRunMapCount:"..tostring(CustomRunMapByData.nRunMapCount))
                end
            else
                --未到达最后一个点 根据['action']参数 来判断进入哪个状态
                EnterStateByAction(CustomRunMapByData.nAction)
            end
        else
            --反向跑
            if CustomRunMapByData.nLine==1 then
                --到达最后一个点 判断跑图是否结束
                if CustomRunMapByData.nRunMapCount==0 then
                    --跑图次数为0 跑图结束
                    CustomRunMapByData.bRunMapEnd=true
                    --关闭跑图帧更新
                    CustomRunMapByData.bSwitch=false
                    MoveForWard_Stop()
                else
                    --跑图次数不为0 正向跑 跑图次数-1
                    CustomRunMapByData.bForwardRun=true
                    CustomRunMapByData.nRunMapCount=CustomRunMapByData.nRunMapCount-1
                    --LOG.INFO("CustomRunMapByData.nRunMapCount:"..tostring(CustomRunMapByData.nRunMapCount))
                end
            else
                --未到达最后一个点 根据['action']参数 来判断进入哪个状态
                EnterStateByAction(CustomRunMapByData.nAction)
            end
        end
    else
        --未到达目标点
        AdjustDirection(player.nX,player.nY,tbData['x'],tbData['y'])
    end
end

function  CustomRunMapByData.RunToNextPoint:OnLeave()
    MoveForWard_Stop()
    if not CustomRunMapByData.bNeedAddLine then
        --卡住后 会直接传送到对应的点,在传送完成前不需要对nLine计数
        return 
    end
    if CustomRunMapByData.bForwardRun then
        --正向跑
        CustomRunMapByData.nLine=CustomRunMapByData.nLine+1
    else
        --反向跑
        CustomRunMapByData.nLine=CustomRunMapByData.nLine-1
    end
    --LOG.INFO("RunToNextPoint:OnLeave:"..tostring(CustomRunMapByData.nLine))
end

-----Cycle----------------
--转圈
CustomRunMapByData.Cycle = BaseState:New("Cycle")
local nCycleStartTime=0 --记录初始时间
local nCycleStep=0      --记录当前角色旋转角度
local fCameraToObjectEyeScale, fYaw, fPitch=nil,nil,nil
function  CustomRunMapByData.Cycle:OnEnter()
    nCycleStep=0
    nCycleStartTime=GetTickCount()
    fCameraToObjectEyeScale, fYaw, fPitch=Camera_GetRTParams()
    MoveForWard_Stop()
end

function  CustomRunMapByData.Cycle:OnUpdate()
    --初始化时默认传送到第一个点
    --每100毫秒旋转10度
    if GetTickCount()-nCycleStartTime>=100 then
        nCycleStartTime=GetTickCount()
        nCycleStep=nCycleStep+0.2
        Camera_SetRTParams(fCameraToObjectEyeScale,fYaw+nCycleStep,fPitch)
        if nCycleStep>=360 then
            --旋转满一圈 继续跑图
            CustomRunMapByData.fsm:Switch("RunToNextPoint")
        end
    end
end

function  CustomRunMapByData.Cycle:OnLeave()
end


-----sfx----------------
-- 释放特效
CustomRunMapByData.sfx = BaseState:New("sfx")
local nSfxStartTime=0 --记录初始时间
local nSfxNextTime=20 --等待特效释放时间(默认20秒)
local bSfxFlag = false -- 是否释放特效
local szSfxCmd = nil

-- 特效设置执行时间
function CustomRunMapByData.SetSfxTime(nTime)
    nSfxNextTime = nTime
end

-- 特效设置CMD指令
function CustomRunMapByData.SetSfxCmd(szCmd)
    szSfxCmd = szCmd
end

function  CustomRunMapByData.sfx:OnEnter()
    nSfxNextTime=CustomRunMapByData.nStay+nSfxNextTime
    nSfxStartTime=GetTickCount()
    MoveForWard_Stop()
end

function  CustomRunMapByData.sfx:OnUpdate()
    if GetTickCount()-nSfxStartTime>=nSfxNextTime*1000 then
        if bSfxFlag then
            -- 结束继续跑图
            CustomRunMapByData.fsm:Switch("RunToNextPoint")
            return
        end
        -- 执行特效
        SendGMCommand(szSfxCmd)
        bSfxFlag =true
        nSfxStartTime=GetTickCount()
    end
end

function  CustomRunMapByData.sfx:OnLeave()
    bSfxFlag = false
end




-----创建状态机---------------
CustomRunMapByData.fsm = FsmMachine:New()
CustomRunMapByData.fsm:AddState(CustomRunMapByData.Init)
CustomRunMapByData.fsm:AddState(CustomRunMapByData.Sleep)
CustomRunMapByData.fsm:AddState(CustomRunMapByData.RunToNextPoint)
CustomRunMapByData.fsm:AddState(CustomRunMapByData.Cycle)
CustomRunMapByData.fsm:AddState(CustomRunMapByData.sfx)
CustomRunMapByData.fsm:AddInitState(CustomRunMapByData.Init)
-----------------------------

--增加一个旋转的命令
tbCircle={}
tbCircle.fStartIndex=2.2
tbCircle.fEndIndex=8.4
tbCircle.nIndex=tbCircle.fStartIndex
tbCircle.fStep=tbCircle.fEndIndex-tbCircle.fStartIndex
tbCircle.fStep=-tbCircle.fStep/150 --90帧限制
function tbCircle.Circle()
    --if CustomRunMapByData.fsm.curState.stateName=="Sleep" then
        --return
    --end
    if tbCircle.nIndex>=tbCircle.fEndIndex or tbCircle.nIndex<=tbCircle.fStartIndex then
        tbCircle.fStep=-tbCircle.fStep
    end
    SetCameraStatus(1083,1,tbCircle.nIndex,-0.1369)
    tbCircle.nIndex=tbCircle.nIndex+tbCircle.fStep
end

function CustomRunMapByData.FrameUpdate()
	if not CustomRunMapByData.bSwitch then
		return
	end
	if not SearchPanel.IsFromLoadingEnterGame() then
        return
    end
	CustomRunMapByData.fsm:Update()
    if CustomRunMapByData.bCircle then
        tbCircle.Circle()
    end
    if CustomRunMapByData.bVideoSwitch then
        tbVideoSwitch.SwitchVideo()
    end
end

--启动跑图帧更新函数  通过CustomRunMapByData.bSwitch开启关闭
CustomRunMapByData.nEntryID=Timer.AddFrameCycle(CustomRunMapByData,1,function()
    CustomRunMapByData.FrameUpdate()
end)

--切画质选项
tbVideoSwitch={}
-- 4档画质
tbVideoSwitch.list_Video={
    [1] = GameQualityType.LOW,
    [2] = GameQualityType.MID,
    [3] = GameQualityType.HIGH,
    [4] = GameQualityType.EXTREME_HIGH
}
tbVideoSwitch.nSetpTime=10
tbVideoSwitch.nSwitchIndex=1
tbVideoSwitch.nTimer=0
function tbVideoSwitch.SwitchVideo()
    if GetTickCount()-tbVideoSwitch.nTimer>tbVideoSwitch.nSetpTime*1000 then
        tbVideoSwitch.nTimer=GetTickCount()
        if SearchPanel.CheckDevicesQuality(tbVideoSwitch.nSwitchIndex) then
            QualityMgr.SetQualityByType(tbVideoSwitch.nSwitchIndex)
        end
        tbVideoSwitch.nSwitchIndex=tbVideoSwitch.nSwitchIndex+1
        if tbVideoSwitch.nSwitchIndex==#tbVideoSwitch.list_Video+1 then
            tbVideoSwitch.nSwitchIndex=1
        end
    end
end

local CustomCamera = {}
-- 调高镜头
function CustomCamera.FrameUpdatefYaw()
    local _,fYaw  = Camera_GetRTParams()
    SetCameraStatus(1083,1,fYaw,0.1)
end

function CustomRunMapByData.SetCameraYaw(nCustomCamera)
    if tonumber(nCustomCamera) == 1 then
        Timer.AddCycle(CustomCamera,1,function ()
            CustomCamera.FrameUpdatefYaw()
        end)
    end
end

LOG.INFO("CustomRunMapByData end")

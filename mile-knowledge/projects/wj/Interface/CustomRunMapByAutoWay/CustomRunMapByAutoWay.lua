CustomRunMapByAutoWay = {}
CustomRunMapByAutoWay.tbRunMapData={}    --跑图点数据  x,y,z,stay,mapid,action  stay:在该点停了时间 action:在该点执行什么行为,1 stay 2 转一圈 
CustomRunMapByAutoWay.bSwitch=false
CustomRunMapByAutoWay.nRunMapCount=1 --默认单程
CustomRunMapByAutoWay.nLine=1    --当前跑图执行到哪一行 lua以1为索引
CustomRunMapByAutoWay.nStartTime=0
CustomRunMapByAutoWay.nStay=0     --tb表中的stay
CustomRunMapByAutoWay.nAction=0     --tb表中的action
CustomRunMapByAutoWay.nRowCount=0        --一共有多少个跑图点
CustomRunMapByAutoWay.nSleepType=0       --根据不同的sleep类型 决定sleep多少秒
CustomRunMapByAutoWay.bRunMapEnd=false   --是否跑图结束
CustomRunMapByAutoWay.bForwardRun=true    --是否正向跑
CustomRunMapByAutoWay.bCircle=false --是否开启原地转圈
CustomRunMapByAutoWay.bVideoSwitch=false --是否开启切画质
CustomRunMapByAutoWay.bCamerafollow=false --是否开启镜头跟随

--记录是否在RunToNextPoint:OnLeave时需要 更改CustomRunMapByAutoWay.nLine的值,卡住直接跳转的情况下不需要修改nLine
CustomRunMapByAutoWay.bNeedAddLine=true

local tbAction={
    stay=1,
    cycle=2
}

local tbSleepType={
    setPostionSleep=0,
    staySleep=1
}

function CustomRunMapByAutoWay.SetCamera(nSetCamera)
    if tonumber(nSetCamera) == 1 then
        CustomRunMapByAutoWay.bCamerafollow = true
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
        table.insert(CustomRunMapByAutoWay.tbRunMapData,{
            x=tonumber(tbData[1]),
            y=tonumber(tbData[2]),
            z=tonumber(tbData[3]),
            stay=nStay,
            mapid=nMapid,
            action=nAction
        })
    end
end

function CustomRunMapByAutoWay.Start(tbRunMapData,nRunMapCount,bCircle,bVideoSwitch,bCamerafollow)
    if not tbRunMapData then
        LOG.INFO("CustomRunMapByAutoWay not tbRunMapData")
        return
    end
    if bCircle~=nil then
        CustomRunMapByAutoWay.bCircle=bCircle
    end
    if bCamerafollow~=nil then
        CustomRunMapByAutoWay.bCamerafollow=bCamerafollow
    end
    if bVideoSwitch~=nil then
        CustomRunMapByAutoWay.bVideoSwitch=bVideoSwitch
    end
    --设置跑图次数
    if nRunMapCount~=nil and nRunMapCount>=0 then
        CustomRunMapByAutoWay.nRunMapCount=nRunMapCount
    else
        CustomRunMapByAutoWay.nRunMapCount=1
    end
    LOG.INFO("CustomRunMapByAutoWay.nRunMapCount start:"..tostring(CustomRunMapByAutoWay.nRunMapCount))
    --状态机切换到初始状态
    CustomRunMapByAutoWay.fsm:AddInitState(CustomRunMapByAutoWay.Init)
    --重置数据
    CustomRunMapByAutoWay.bNeedAddLine=true
    CustomRunMapByAutoWay.tbRunMapData={}
    CustomRunMapByAutoWay.bRunMapEnd=false
    CustomRunMapByAutoWay.nLine=1
    CustomRunMapByAutoWay.nRowCount=#tbRunMapData
    CustomRunMapByAutoWay.bForwardRun=true
    --开启跑图开关 跑图次数-1
    CustomRunMapByAutoWay.nRunMapCount=CustomRunMapByAutoWay.nRunMapCount-1
    CustomRunMapByAutoWay.bSwitch=true
    --处理跑图数据
    ExchangeRunMapData(tbRunMapData)
end

--获取 是否跑图完成
function CustomRunMapByAutoWay.IsEnd()
    return CustomRunMapByAutoWay.bRunMapEnd
end

-----init----------------
--初始化状态 传送到起一个点并进入Sleep状态
CustomRunMapByAutoWay.Init = BaseState:New("Init")

function  CustomRunMapByAutoWay.Init:OnEnter()
    AutoRoadWay.Stop()
end

function  CustomRunMapByAutoWay.Init:OnUpdate()
    --初始化时默认传送到第一个点
    local szCMD="/gm player.SetPosition(%s,%s,%s)"
    local tbData=CustomRunMapByAutoWay.tbRunMapData[CustomRunMapByAutoWay.nLine]
    szCMD=string.format(szCMD,tbData['x'],tbData['y'],tbData['z'])
    --不能频繁寻路 因此需要在第一个点sleep一下
    tbData['stay']=10
    tbData['action']=1
    SearchPanel.RunCommand(szCMD)
    CustomRunMapByAutoWay.nSleepType=tbSleepType.setPostionSleep       -- 传送点后设置SleepType
    CustomRunMapByAutoWay.bNeedAddLine=true --完成传送后正常进行nLine计数
    CustomRunMapByAutoWay.fsm:Switch("Sleep")
end

function  CustomRunMapByAutoWay.Init:OnLeave()
    --记录当前line的stay 和action  因为跑到当前目标点后,会根据action执行不同的状态
    CustomRunMapByAutoWay.nStay=CustomRunMapByAutoWay.tbRunMapData[CustomRunMapByAutoWay.nLine]['stay']
    CustomRunMapByAutoWay.nAction=CustomRunMapByAutoWay.tbRunMapData[CustomRunMapByAutoWay.nLine]['action']
    --CustomRunMapByAutoWay.nLine=CustomRunMapByAutoWay.nLine+1
end

-----Sleep----------------
--nSleepType=0 sleep:3秒,nSleepType=1 sleep:stay秒
local tbSleepTime={
    [tbSleepType.setPostionSleep]=3,
    [tbSleepType.staySleep]=nil
}
CustomRunMapByAutoWay.Sleep = BaseState:New("Sleep")
local nSleepStartTime=0
function  CustomRunMapByAutoWay.Sleep:OnEnter()
    nSleepStartTime=GetTickCount()   --初始化时间
    AutoRoadWay.Stop()  --进入Sleep状态后 玩家必须停止
end

function  CustomRunMapByAutoWay.Sleep:OnUpdate()
    --默认使用nSleepType进行配置
    local nSleepTime=tbSleepTime[CustomRunMapByAutoWay.nSleepType]
    --特殊的类型用staySleep
    if CustomRunMapByAutoWay.nSleepType==tbSleepType.staySleep then
        nSleepTime=CustomRunMapByAutoWay.nStay
    end

    if GetTickCount() - nSleepStartTime >= nSleepTime*1000 then    --计时器
        nSleepStartTime=GetTickCount()     --重置初始时间
        if CustomRunMapByAutoWay.nSleepType==tbSleepType.setPostionSleep then
            --传送到第一个点sleep完成 开始往下一个点跑图
            CustomRunMapByAutoWay.fsm:Switch("RunToNextPoint")
            SendGMCommand("player.Revive()")
            SendGMCommand("player.AddBuff(0,99,8233,10,7200)") --无限气力+加速buff
            SendGMCommand("player.AddBuff(0,99,8665,1,7200)")
        elseif CustomRunMapByAutoWay.nSleepType==tbSleepType.staySleep then
            --原地停留stay秒完成 开始往下一个点跑图
            CustomRunMapByAutoWay.fsm:Switch("RunToNextPoint")
        else
            LOG.INFO("CustomRunMapByAutoWay set nSleepType Error:"..tostring(CustomRunMapByAutoWay.nSleepType))
            return
        end
    end
end

function  CustomRunMapByAutoWay.Sleep:OnLeave()
end

-----RunToNextPoint----------------
--计算玩家当前坐标朝向目标点方向 x,y 并判断是否调整角色视角
local nLastTurnto=0
local function AdjustDirection(nPlayerX,nPlayerY,nTargetX,nTargetY)
    local nVectorX =  nTargetX - nPlayerX
    local nVectorY =  nTargetY - nPlayerY

    local nTurnto = GetLogicDirection(nVectorX,nVectorY)
    --LOG.INFO(string.format("[RunMapByPoint] TurnTo {%d}",nTurnto))
    --SearchPanel.MyExecuteScriptCommand("TurnTo("..tostring(nTurnto)..")")
    if math.abs(nTurnto-nLastTurnto) >=15 then
        --两次朝向大于15度时 条件镜头角度 重置记录的朝向
        nLastTurnto=nTurnto
        if CustomRunMapByAutoWay.bCamerafollow then
            TurnToFaceDirection()
        end
    end
end

--计算是否到达下一个点
local function JudgeArrive(nPlayerX,nPlayerY,nTargetX,nTargetY)
    --LOG.INFO("JudgeArrive"..tostring(CustomRunMapByAutoWay.nLine))
    --LOG.INFO(string.format("[JudgeArrive] {%d},{%d}  {%d},{%d}",nPlayerX,nPlayerY,nTargetX,nTargetY))
    local nVectorX=nTargetX-nPlayerX
    local nVectorY=nTargetY-nPlayerY
    --向量误差在10以内 默认到达该点
    --LOG.INFO("JudgeArrive pos :"..tostring(nVectorX*nVectorX+nVectorY*nVectorY))
    if nVectorX*nVectorX+nVectorY*nVectorY<=800 then
        --LOG.INFO("JudgeArrive true")
        return true
    else
        -- 是否在自动寻路 自动寻路是否断掉
        if not AutoRoadWay.IsRun() then
            local tbData=CustomRunMapByAutoWay.tbRunMapData[CustomRunMapByAutoWay.nLine]
            AutoRoadWay.Start(tbData['x'],tbData['y'],tbData['z'])
        end
        --LOG.INFO("JudgeArrive false")
        return false
    end
end

CustomRunMapByAutoWay.RunToNextPoint = BaseState:New("RunToNextPoint")
--记录进入当前状态的初始时间
local nRunToNextPointStartTime=0

--根据['action']参数 来判断进入哪个状态
local function EnterStateByAction(nState)
    if nState==tbAction.stay then
        --进入sleep状态  将nSleepType置为staySleep
        CustomRunMapByAutoWay.nSleepType=tbSleepType.staySleep
        CustomRunMapByAutoWay.fsm:Switch("Sleep")
    elseif nState==tbAction.cycle  then
        --进入Cycle状态
        CustomRunMapByAutoWay.fsm:Switch("Cycle")
    else
        --进入RunToNextPoint
        CustomRunMapByAutoWay.fsm:Switch("RunToNextPoint")
        --LOG.INFO("action :"..tostring(nState))
    end
end

function  CustomRunMapByAutoWay.RunToNextPoint:OnEnter()
    --LOG.INFO("RunToNextPoint:OnEnter:"..tostring(CustomRunMapByAutoWay.nLine))
    --进入当前状态的初始时间
    nRunToNextPointStartTime=GetTickCount()
    local tbData=CustomRunMapByAutoWay.tbRunMapData[CustomRunMapByAutoWay.nLine]
    AutoRoadWay.Start(tbData['x'],tbData['y'],tbData['z'])
    --记录当前line的stay 和action  因为跑到当前目标点后,会根据action执行不同的状态
    CustomRunMapByAutoWay.nStay=CustomRunMapByAutoWay.tbRunMapData[CustomRunMapByAutoWay.nLine]['stay']
    CustomRunMapByAutoWay.nAction=CustomRunMapByAutoWay.tbRunMapData[CustomRunMapByAutoWay.nLine]['action']
end

function  CustomRunMapByAutoWay.RunToNextPoint:OnUpdate()
    local player=GetClientPlayer()
    local tbData=CustomRunMapByAutoWay.tbRunMapData[CustomRunMapByAutoWay.nLine]
    --根据MapID判断是否需要地图传送
    if tbData['mapid']~=0 and tbData['mapid']~=player.GetMapID() then
        --地图传送
        SendGMCommand(string.format("player.SwitchMap(%d,1,%d,%d,%d)",tbData['mapid'],tbData['x'],tbData['y'],tbData['z']))
        return
    end
    --[[
    if GetTickCount()-nRunToNextPointStartTime >15000 then
        --当前状态15秒未结束(也许是卡住了) 执行传送到目标点,并Sleep(参照init状态)
        --重置时间
        nRunToNextPointStartTime=GetTickCount()
        AutoTestLog.INFO("JumpToNext"..tostring(CustomRunMapByAutoWay.nLine))
        CustomRunMapByAutoWay.bNeedAddLine=false --完成传送前关闭nLine计数
        AutoTestLog.INFO("nRunMapCount"..tostring(CustomRunMapByAutoWay.nRunMapCount))
        CustomRunMapByAutoWay.fsm:Switch("Init")
    end]]
    if JudgeArrive(player.nX,player.nY,tbData['x'],tbData['y']) then
        --到达目标点  输出一下坐标
        --OutputMessage("MSG_SYS",string.format("Id:%d,(%d,%d,%d)",player.GetMapID(),tbData['x'],tbData['y'],tbData['z']))
        LOG.INFO(string.format("Autotest Id:%d,(%d,%d,%d)",player.GetMapID(),tbData['x'],tbData['y'],tbData['z']))
        if CustomRunMapByAutoWay.bForwardRun then
            --正向跑
            if CustomRunMapByAutoWay.nLine==CustomRunMapByAutoWay.nRowCount then
                --到达最后一个点 判断跑图是否结束
                if CustomRunMapByAutoWay.nRunMapCount==0 then
                    --跑图次数为0 跑图结束
                    CustomRunMapByAutoWay.bRunMapEnd=true
                    --关闭跑图帧更新
                    CustomRunMapByAutoWay.bSwitch=false
                    AutoRoadWay.Stop()
                else
                    --跑图次数不为0 反向跑 跑图次数-1
                    CustomRunMapByAutoWay.bForwardRun=false
                    CustomRunMapByAutoWay.nRunMapCount=CustomRunMapByAutoWay.nRunMapCount-1
                    --LOG.INFO("CustomRunMapByAutoWay.nRunMapCount:"..tostring(CustomRunMapByAutoWay.nRunMapCount))
                end
            else
                --未到达最后一个点 根据['action']参数 来判断进入哪个状态
                EnterStateByAction(CustomRunMapByAutoWay.nAction)
            end
        else
            --反向跑
            if CustomRunMapByAutoWay.nLine==1 then
                --到达最后一个点 判断跑图是否结束
                if CustomRunMapByAutoWay.nRunMapCount==0 then
                    --跑图次数为0 跑图结束
                    CustomRunMapByAutoWay.bRunMapEnd=true
                    --关闭跑图帧更新
                    CustomRunMapByAutoWay.bSwitch=false
                    AutoRoadWay.Stop()
                else
                    --跑图次数不为0 正向跑 跑图次数-1
                    CustomRunMapByAutoWay.bForwardRun=true
                    CustomRunMapByAutoWay.nRunMapCount=CustomRunMapByAutoWay.nRunMapCount-1
                    --LOG.INFO("CustomRunMapByAutoWay.nRunMapCount:"..tostring(CustomRunMapByAutoWay.nRunMapCount))
                end
            else
                --未到达最后一个点 根据['action']参数 来判断进入哪个状态
                EnterStateByAction(CustomRunMapByAutoWay.nAction)
            end
        end
    else
        --未到达目标点
        AdjustDirection(player.nX,player.nY,tbData['x'],tbData['y'])
    end
end

function  CustomRunMapByAutoWay.RunToNextPoint:OnLeave()
    AutoRoadWay.Stop()
    if not CustomRunMapByAutoWay.bNeedAddLine then
        --卡住后 会直接传送到对应的点,在传送完成前不需要对nLine计数
        return 
    end
    if CustomRunMapByAutoWay.bForwardRun then
        --正向跑
        CustomRunMapByAutoWay.nLine=CustomRunMapByAutoWay.nLine+1
    else
        --反向跑
        CustomRunMapByAutoWay.nLine=CustomRunMapByAutoWay.nLine-1
    end
    --LOG.INFO("RunToNextPoint:OnLeave:"..tostring(CustomRunMapByAutoWay.nLine))
end

-----Cycle----------------
--转圈
CustomRunMapByAutoWay.Cycle = BaseState:New("Cycle")
local nCycleStartTime=0 --记录初始时间
local nCycleStep=0      --记录当前角色旋转角度
local fCameraToObjectEyeScale, fYaw, fPitch=nil,nil,nil
function  CustomRunMapByAutoWay.Cycle:OnEnter()
    nCycleStep=0
    nCycleStartTime=GetTickCount()
    fCameraToObjectEyeScale, fYaw, fPitch=Camera_GetRTParams()
    AutoRoadWay.Stop()
end

function  CustomRunMapByAutoWay.Cycle:OnUpdate()
    --初始化时默认传送到第一个点
    --每100毫秒旋转10度
    if GetTickCount()-nCycleStartTime>=100 then
        nCycleStartTime=GetTickCount()
        nCycleStep=nCycleStep+0.2
        Camera_SetRTParams(fCameraToObjectEyeScale,fYaw+nCycleStep,fPitch)
        if nCycleStep>=360 then
            --旋转满一圈 继续跑图
            CustomRunMapByAutoWay.fsm:Switch("RunToNextPoint")
        end
    end
end

function  CustomRunMapByAutoWay.Cycle:OnLeave()
end


-----创建状态机---------------
CustomRunMapByAutoWay.fsm = FsmMachine:New()
CustomRunMapByAutoWay.fsm:AddState(CustomRunMapByAutoWay.Init)
CustomRunMapByAutoWay.fsm:AddState(CustomRunMapByAutoWay.Sleep)
CustomRunMapByAutoWay.fsm:AddState(CustomRunMapByAutoWay.RunToNextPoint)
CustomRunMapByAutoWay.fsm:AddState(CustomRunMapByAutoWay.Cycle)
CustomRunMapByAutoWay.fsm:AddInitState(CustomRunMapByAutoWay.Init)
-----------------------------

--增加一个旋转的命令
tbCircle={}
tbCircle.fStartIndex=2.2
tbCircle.fEndIndex=8.4
tbCircle.nIndex=tbCircle.fStartIndex
tbCircle.fStep=tbCircle.fEndIndex-tbCircle.fStartIndex
tbCircle.fStep=-tbCircle.fStep/150 --90帧限制
function tbCircle.Circle()
    --if CustomRunMapByAutoWay.fsm.curState.stateName=="Sleep" then
        --return
    --end
    if tbCircle.nIndex>=tbCircle.fEndIndex or tbCircle.nIndex<=tbCircle.fStartIndex then
        tbCircle.fStep=-tbCircle.fStep
    end
    SetCameraStatus(1083,1,tbCircle.nIndex,-0.1369)
    tbCircle.nIndex=tbCircle.nIndex+tbCircle.fStep
end

function CustomRunMapByAutoWay.FrameUpdate()
	if not CustomRunMapByAutoWay.bSwitch then
		return
	end
	if not SearchPanel.IsFromLoadingEnterGame() then
        return
    end
	CustomRunMapByAutoWay.fsm:Update()
    if CustomRunMapByAutoWay.bCircle then
        tbCircle.Circle()
    end
    if CustomRunMapByAutoWay.bVideoSwitch then
        tbVideoSwitch.SwitchVideo()
    end
end

--启动跑图帧更新函数  通过CustomRunMapByAutoWay.bSwitch开启关闭
CustomRunMapByAutoWay.nEntryID=Timer.AddFrameCycle(CustomRunMapByAutoWay,1,function()
    CustomRunMapByAutoWay.FrameUpdate()
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
tbVideoSwitch.nSetpTime=5
tbVideoSwitch.nSwitchIndex=1
tbVideoSwitch.nTimer=0
function tbVideoSwitch.SwitchVideo()
    if GetTickCount()-tbVideoSwitch.nTimer>tbVideoSwitch.nSetpTime*1000 then
        tbVideoSwitch.nTimer=GetTickCount()
        QualityMgr.SetQualityByType(tbVideoSwitch.nSwitchIndex)
        tbVideoSwitch.nSwitchIndex=tbVideoSwitch.nSwitchIndex+1
        if tbVideoSwitch.nSwitchIndex==#tbVideoSwitch.list_Video+1 then
            tbVideoSwitch.nSwitchIndex=1
        end
    end
end
LOG.INFO("CustomRunMapByAutoWay end")

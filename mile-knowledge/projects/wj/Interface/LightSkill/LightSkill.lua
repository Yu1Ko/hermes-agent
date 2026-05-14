-- z跳跃高度
-- xy数据检测
-- 轻功 不能停止
-- 目前解决办法 先轻功起飞然后强制位移到坐标点 位移坐标不会中断轻功
LightSkill = {}
LightSkill.bSwitch = true -- 控件开关
LightSkill.nCount=1 -- 轻功飞行次数
LightSkill.nSkillCount=1 -- 轻功跑图总次数
--处理未知弹窗
Timer.AddCycle(SearchPanel.tbTips,1,SearchPanel.DealWithTips)
--加载RunMap.tab文件的数据  格式 {{},{},{},{},{},{},{}}
local tbRunMapData=SearchPanel.LoadRunMapFile(SearchPanel.szCurrentInterfacePath.."RunMap.tab",6)
local list_RunMapCMD = {}                       -- CMD文件
local list_RunMapTime = {}                      -- 文件时间
LightSkill.list_RunMapData={}     --跑图点数据
LightSkill.tbRunMapData={}
local bFlag = true
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
            LOG.INFO("FlyLightSkill Start Read RunMapData")
        else
            --取坐标 格式 x,y,z,stay,mapid,action  stay:在该点停了时间 action:在该点执行什么行为,1 stay 2 转一圈
            for n=1,nDataLen do
                table.insert(tbDataTemp,tbRunMapData[n][i])
            end
            table.insert(LightSkill.list_RunMapData,tbDataTemp)
        end
    end
end
--初始化 CMD和跑图数据点
GetPointsRunMap()

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
        table.insert(LightSkill.tbRunMapData,{
            x=tonumber(tbData[1]),
            y=tonumber(tbData[2]),
            z=tonumber(tbData[3]),
            stay=nStay,
            mapid=nMapid,
            action=nAction
        })
    end
end

-- 设置轻功跑图圈数
function LightSkill.SetCount(nSetCount)
    LightSkill.nSkillCount = tonumber(nSetCount)
end


AutoTestLog.Log("LightSkillData","LightSkillData Start")
LightSkillData={}
-- 调整坐标
function LightSkillData.TurnTo(nTurnto)
    SearchPanel.MyExecuteScriptCommand("TurnTo("..tostring(nTurnto)..")")
end

-- 轻功封装接口
FlyJump={}
-- 位移到指定位置和高度
-- 暂时使用
local nJumpCount = 1
function FlyJump.FrameUpdate(Pos_x,Pos_Y,Pos_z)
    -- 根据人物跳跃来判断是否进入4段轻功状态
    if nJumpCount ~= 5 then
        UIMgr.GetViewScript(VIEW_ID.PanelMainCity).scriptFuncSlot:OnSlotButtonEvent(5, nil, true)
        nJumpCount = nJumpCount + 1
        return
    else
        SendGMCommand("player.SetPosition("..Pos_x..", "..Pos_Y..","..Pos_z..")")
        Timer.DelAllTimer(FlyJump)
        nJumpCount= 1
    end
end



-- 启动轻功
function LightSkillData.StartFly(Pos_x,Pos_Y,Pos_z)
    -- 每隔一秒跳跃一次
    Timer.AddCycle(FlyJump,1,function ()
        FlyJump.FrameUpdate(Pos_x,Pos_Y,Pos_z)
    end)
end

-- 检测是否到目标点 x和y坐标
function LightSkillData.CheckTargetPoint(nTargetX,nTargetY)
    local player = GetClientPlayer()
    local nVectorX=nTargetX-player.nX
    local nVectorY=nTargetY-player.nY
    if nVectorX*nVectorX+nVectorY*nVectorY<=1000 then
        return true
    else
        return false
    end
end

-- 调整角色朝向
local nLastTurnto=0
function LightSkillData.AdjustDirection(nTargetX,nTargetY)
    local player = GetClientPlayer()
    local nVectorX=nTargetX-player.nX
    local nVectorY=nTargetY-player.nY

    local nTurnto = GetLogicDirection(nVectorX,nVectorY)
    if math.abs(nTurnto-nLastTurnto) >=5 then
        nLastTurnto=nTurnto
        SearchPanel.MyExecuteScriptCommand("TurnTo("..tostring(nTurnto)..")")
    end
end

AutoTestLog.Log("LightSkillData","LightSkillData End")


-- 状态机
-----init----------------
LightSkill.bStart = false
local Init = BaseState:New("Init")
function Init:OnEnter()

end

function Init:OnUpdate()
    if not LightSkill.bStart then
        ExchangeRunMapData(LightSkill.list_RunMapData)
        LightSkillData.StartFly(LightSkill.tbRunMapData[1]["x"],LightSkill.tbRunMapData[1]["y"],LightSkill.tbRunMapData[1]["z"])
        LightSkill.bStart = true
        return
    end
    fsm:Switch("FlySkill")
end

function Init:OnLeave()                               

end



-----Sleep----------------
local FlySkill = BaseState:New("FlySkill")
LightSkill.nStartTime = 0
LightSkill.nLine = 2    -- 移动的坐标点
LightSkill.nNextTime=tonumber(1) -- 下一次等待时间 没有默认为5秒一次
-- 每进行一个状态 进行一次睡眠
function FlySkill:OnEnter()
    LightSkill.nStartTime = GetTickCount()
end

function FlySkill:OnUpdate()
    if LightSkill.nLine == #LightSkill.tbRunMapData+1  then
        if LightSkill.nCount == LightSkill.nSkillCount then
            Timer.DelAllTimer(LightSkill)
            bFlag = true
            return
        end
        LightSkill.nCount = LightSkill.nCount + 1
        LightSkill.nLine = 1
    end
    local nLightSkill_X = LightSkill.tbRunMapData[LightSkill.nLine]["x"]
    local nLightSkill_Y = LightSkill.tbRunMapData[LightSkill.nLine]["y"]
    if LightSkillData.CheckTargetPoint(nLightSkill_X,nLightSkill_Y) then
        LightSkill.nLine = LightSkill.nLine + 1
    else
        LightSkillData.AdjustDirection(nLightSkill_X,nLightSkill_Y)
    end
    LightSkill.nStartTime = GetTickCount()
end

function FlySkill:OnLeave()                               

end

function LightSkill.FrameUpdate()
    if not SearchPanel.IsFromLoadingEnterGame() then
        return
    end
    fsm.curState:OnUpdate()
end


function LightSkill.Start()
    if not LightSkill.bSwitch then
        return
    end
    fsm = FsmMachine:New()
    fsm:AddState(FlySkill)
    fsm:AddInitState(Init)
    Timer.AddFrameCycle(LightSkill,1,function ()
        LightSkill.FrameUpdate()
    end)
end


local RunMap = {}
local nCurrentTime = 0
local nNextTime=tonumber(20)
local nCurrentStep=1

local function RunMapFrameUpdate()
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
        pcall(function ()
            SearchPanel.RunCommand(szCmd)
        end)
        AutoTestLog.INFO(szCmd.."===ok")
        OutputMessage("MSG_SYS",szCmd)
        nNextTime=nTime
        if string.find(szCmd,"perfeye_start") then
            SearchPanel.bPerfeye_Start=true
        end
        if string.find(szCmd,"LightSkill_Start") then
            --启动跑图帧更新函数
            LightSkill.Start()
            bFlag = false
        end
        if string.find(szCmd,"perfeye_stop") then
            SearchPanel.bPerfeye_Stop=true
        end
        nCurrentTime=GetTickCount()
        nCurrentStep=nCurrentStep+1
    end
end

Timer.AddFrameCycle(RunMap,1,function()
    RunMapFrameUpdate()
end)
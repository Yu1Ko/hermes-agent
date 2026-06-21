Log("[RagDollTest] RagDollTest imported")
RagDollTest={}
local bFlag = true
local RunMap = {}

RagDollTest.bSwitch=false
RagDollTest.bSaveData=false 
function RagDollTest.Switch(_select_)
    _select_ = tonumber(_select_)
    if _select_ == 0 then
        RagDollTest.bSwitch = false
        OutputMessage("MSG_SYS",'turn off'.."\n")
    elseif _select_ == 1 then
        RagDollTest.bSwitch = true
        OutputMessage("MSG_SYS",'turn on'.."\n")
    end
end


--执行次数--
RagDollTest.nCycleCnt=5
--执行
function RagDollTest.SetCycleCnt(nCnt)
    RagDollTest.nCycleCnt=nCnt
end



-----init----------------
--ini
RagDollTest.Init = BaseState:New("Init")
function  RagDollTest.Init:OnEnter()
    Log("RagDollTest init")
end


function  RagDollTest.Init:OnUpdate()
    RagDollTest.fsm:Switch("Start")
end

function  RagDollTest.Init:OnLeave()
end

--间隔时间
RagDollTest.nCycleTime=10
function RagDollTest.SetCycleTime(nCnt)
    RagDollTest.nCycleTime=nCnt
    Log(string.format("RagDollTest.nCycleTime=%d",nCnt))
end

-----Sleep----------------
--Sleep
local nLastCycleTime=0
RagDollTest.Sleep = BaseState:New("Sleep")
function  RagDollTest.Sleep:OnEnter()
    nLastCycleTime=GetTickCount()
    RagDollTest.nCycleCnt=RagDollTest.nCycleCnt-1
    --结束
    OutputMessage("MSG_SYS",RagDollTest.nCycleCnt)
    if RagDollTest.nCycleCnt<=0 then
        RagDollTest.bSwitch=false
        bFlag = true
    end
end


function  RagDollTest.Sleep:OnUpdate()
    if GetTickCount()-nLastCycleTime>RagDollTest.nCycleTime*1000 then
        nLastCycleTime=GetTickCount()
        OutputMessage("MSG_SYS","已执行")
        RagDollTest.fsm:Switch("Start")
    end
end

function  RagDollTest.Sleep:OnLeave()

end


RagDollTest.nNpcCnt=50
function RagDollTest.SetNpcCnt(nCnt)
    RagDollTest.nNpcCnt=nCnt
    Log(string.format("RagDollTest.nNpcCnt=%d",nCnt))
end

RagDollTest.nNpcIndex=1
RagDollTest.bCreatFlag=true
RagDollTest.nNpcKillIndex=0
RagDollTest.bKillFlag=false
-----Start----------------
RagDollTest.Start = BaseState:New("Start")
function  RagDollTest.Start:OnEnter()
    Log("RagDollTest Start")
    RagDollTest.nNpcIndex=1
    RagDollTest.bCreatFlag=true
    RagDollTest.nNpcKillIndex=0
    RagDollTest.bKillFlag=false
end


local nLastTickTime=0
local nGetDataTime=1
function  RagDollTest.Start:OnUpdate()
    --创建
    if GetTickCount()-nLastTickTime>2*1000 and RagDollTest.bCreatFlag then
        if RagDollTest.nNpcIndex<=RagDollTest.nNpcCnt then
            nLastTickTime=GetTickCount()
            RagDollTest.CreateNpc(RagDollTest.nNpcIndex)
            RagDollTest.nNpcIndex=RagDollTest.nNpcIndex+1
        else
            RagDollTest.nNpcKillIndex=3
            --RagDollTest.nNpcKillIndex=RagDollTest.nNpcIndex-1

            print(RagDollTest.bCreatFlag)
            print(RagDollTest.bKillFlag)
            RagDollTest.bCreatFlag=false
            RagDollTest.bKillFlag=true
        end
    end

    --击杀
    if RagDollTest.bKillFlag and GetTickCount()-nLastTickTime>1*1000 then
        if RagDollTest.nNpcKillIndex>0 then
            RagDollTest.KillNpc()
            nLastTickTime=GetTickCount()
            RagDollTest.nNpcKillIndex=RagDollTest.nNpcKillIndex-1
            print(RagDollTest.nNpcKillIndex)
        else
            RagDollTest.bKillFlag=true
            RagDollTest.fsm:Switch("Sleep")
        end
    end
end

function  RagDollTest.Start:OnLeave()
    
end

local function generate_points(center_x, center_y, rows, cols, step)
    local points = {}

    -- 计算左上角起点，使整个矩形以中心点为中心
    local start_x = center_x - (cols - 1) * step / 2
    local start_y = center_y - (rows - 1) * step / 2

    for i = 0, rows - 1 do
        for j = 0, cols - 1 do
            local x = start_x + j * step
            local y = start_y + i * step
            table.insert(points, {x = x, y = y})
        end
    end

    return points
end
-- 生成 50 个点：8行7列 间距80
local points = generate_points(0, 0, 8, 7, 40)

function RagDollTest.CreateNpc(nIndex)
    local direction=points[nIndex]
    local strInfo=string.format("player.GetScene().CreateNpc(136502, player.nX+%d, player.nY+%d, player.nZ, 0,-1,'buwawa%d')",direction.x,direction.y,nIndex)
    SendGMCommand(strInfo)
end

function RagDollTest.KillNpc()
    SendGMCommand('for i = 1, 300 do local npc1 = player.GetScene().GetNpcByNickName("buwawa" .. i) if npc1 then npc1.Die() end end')
end




RagDollTest.fsm = FsmMachine:New()
RagDollTest.fsm:AddState(RagDollTest.Start)
RagDollTest.fsm:AddState(RagDollTest.Sleep)
RagDollTest.fsm:AddInitState(RagDollTest.Init)

-----------------------------

function RagDollTest.OnFrameBreathe()
    if not RagDollTest.bSwitch then
        return
    end
	RagDollTest.fsm.curState:OnUpdate()
end


function RagDollTest.Start()
    Timer.AddFrameCycle(RagDollTest,1,function ()
        RagDollTest.OnFrameBreathe()
    end)
end


--读取tab的内容 
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
        if string.find(szCmd,"RagDollTest_start") then
            --启动切图帧更新函数
            RagDollTest.Start()
            bFlag = false
        end
		nCurrentTime=GetTickCount()
        nCurrentStep=nCurrentStep+1 
    end
end

Timer.AddFrameCycle(RunMap,1,function ()
    RunMap.FrameUpdate()
end)
local RunMap = {}
local bFlag = true
local pCurrentTime = 0
local nNextTime=tonumber(30)
local nCurrentStep=1
local tbRunMapData=SearchPanel.LoadRunMapFile(SearchPanel.szCurrentInterfacePath.."RunMap.tab",2)
local list_RunMapCMD = tbRunMapData[1]
local list_RunMapTime = tbRunMapData[2]


HangUpFight = {}
HangUpFight.bSwitch = true
HangUpFight.bStart = true   -- 默认不开启打斗
HangUpFight.tbNpcList = {18,19}
HangUpFight.nNpcLine = 1    -- 当前召唤的npc
HangUpFight.nNpcNumber = 1 -- 每次召唤的人数
HangUpFight.nFightStartTime = 0 -- 召唤时间
HangUpFight.nFightNextTime = 3  -- 每隔3秒召唤一个npc
HangUpFight.nFightTime = 20  -- 用例总时间
HangUpFight.nFightTimeLine = 0  -- 当前总时间
HangUpFight.bAutoStatus = false
HangUpFight.nStatus = 1 -- 当前状态

-- 添加Npc到队列参数
function HangUpFight.AddNPCID(nNpcId)
    local nNpcID = tonumber(nNpcId)
    table.insert(HangUpFight.tbNpcList,nNpcID)
end

-- 设置召唤的Npc参数
function HangUpFight.SetNpcParameter(nCount,nNumber)
    HangUpFight.nNpcNumber = nCount
    HangUpFight.nNpcCount = nNumber
end

-- 创建npc
function HangUpFight.SetCallNpc()
    local player = GetClientPlayer()
    local nFaceDirection = player.nFaceDirection
    if HangUpFight.nNpcLine == #HangUpFight.tbNpcList+1 then
        -- body
        HangUpFight.nNpcLine = 1
    end
    for i = 1, HangUpFight.nNpcNumber, 1 do
        SendGMCommand("player.GetScene().CreateNpc(" ..HangUpFight.tbNpcList[HangUpFight.nNpcLine].. "," .. player.nX .. "," .. player.nY .. "," .. player.nZ .. ", " .. nFaceDirection .. ", -1)")
    end
    HangUpFight.nNpcLine = HangUpFight.nNpcLine +1
end


-----init----------------
local Init = BaseState:New("Init")
function Init:OnEnter()

end

function Init:OnUpdate()
    fsm:Switch("Sleep")
end

function Init:OnLeave()                               

end

-- 
local AutoFight = BaseState:New("AutoFight")
local nAttackLine = 1 -- 当前技能
function AutoFight:OnEnter()
    
end

function AutoFight:OnUpdate()
    SearchPanel.RunCommand("/gm player.AddBuff(player.dwID,player.nLevel,203,1,3600)")
    if HangUpFight.bAutoStatus then
        local nSkillID = UIBattleSkillSlot.GetShowUI_Ver2(nAttackLine)
        -- 重置技能
        if nAttackLine == 6 then
            nAttackLine = 1
        end
        SkillData.SetCastPointToTargetPos()
        -- 进行释放
        OnUseSkill(nSkillID, 1)
        local PlayerState = SprintData.GetViewState()
        -- 如果为技能面板则不切换
        if PlayerState then
            SprintData.ToggleViewState()
            AutoBattle.Start()
        end
        nAttackLine = nAttackLine + 1
    else
        UINodeControl.BtnTrigger("BtnTargetSelect")
        SearchPanel.RunCommand("/gm if player.GetSelectCharacter() ~= nil then player.GetSelectCharacter().Die() end")
    end
    fsm:Switch("SummonNpc")
end

function AutoFight:OnLeave()                          
    
end

local SummonNpc = BaseState:New("SummonNpc")
function SummonNpc:OnEnter()
    
end

function SummonNpc:OnUpdate()
    HangUpFight.SetCallNpc()
    fsm:Switch("Sleep")
end

function SummonNpc:OnLeave()                          
    
end

-----Sleep----------------
local Sleep = BaseState:New("Sleep")
local nStartTime = 0
local nNextTime=tonumber(5) -- 下一次等待时间 没有默认为5秒一次
-- 每进行一个状态 进行一次睡眠
function Sleep:OnEnter()
    nStartTime = GetTickCount()
    if HangUpFight.nFightNextTime > 0 then
        nNextTime = HangUpFight.nFightNextTime
        if HangUpFight.nFightTimeLine >= HangUpFight.nFightTime*60 then
            Timer.DelAllTimer(HangUpFight)
            bFlag = true
            return
        end
        HangUpFight.nFightTimeLine = HangUpFight.nFightTimeLine + HangUpFight.nFightNextTime
    end
end

function Sleep:OnUpdate()
    if GetTickCount()-nStartTime >= nNextTime*1000 then
        fsm:Switch("AutoFight")
    end
end

function Sleep:OnLeave()                      

end

-- 切图切画质帧更新函数
function HangUpFight.FrameUpdate()
    if not SearchPanel.IsFromLoadingEnterGame() then
        return
    end
    fsm.curState:OnUpdate()
end


-- 开始
function HangUpFight.Start()
    fsm = FsmMachine:New()
    fsm:AddState(Sleep)
    fsm:AddState(AutoFight)
    fsm:AddState(SummonNpc)
    fsm:AddInitState(Init)
    Timer.AddFrameCycle(HangUpFight,1,function ()
        HangUpFight.FrameUpdate()
    end)
end


-- 前后置条件
function RunMap.FrameUpdate()
    local player=GetClientPlayer()
    if not player then
        return
    end
    if not SearchPanel.IsFromLoadingEnterGame() then
        return
    end
    if bFlag and GetTickCount()-pCurrentTime>nNextTime*1000 then
        if nCurrentStep==#list_RunMapCMD then
            bFlag=false
        end
        --切图前后置操作
        local szCmd=list_RunMapCMD[nCurrentStep]
        local nTime=tonumber(list_RunMapTime[nCurrentStep])
        print(szCmd)
        pcall(function ()
            SearchPanel.RunCommand(szCmd)
        end)
        print(szCmd.."ok")
        if string.find(szCmd,"perfeye_start") then
            SearchPanel.bPerfeye_Start=true
        end
        if string.find(szCmd,"perfeye_stop") then
            SearchPanel.bPerfeye_Stop=true
        end
        nNextTime=nTime
        --切图操作
        if string.find(szCmd,"HangUpFight") then
            HangUpFight.Start()
            bFlag=false
        end
		pCurrentTime=GetTickCount()
        nCurrentStep=nCurrentStep+1 
    end
end

Timer.AddFrameCycle(RunMap,1,function ()
    RunMap.FrameUpdate()
end)
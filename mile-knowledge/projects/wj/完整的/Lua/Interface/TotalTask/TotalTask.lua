TotalTask = {}
TotalTask.nTaskCount = 4 --需要执行的任务次数
-- 任务流程必须写到这..//TaskProcess
Timer.AddCycle(SearchPanel.tbTips,1,SearchPanel.DealWithTips)

local bFlag = true
local RunMap = {}

-- 获取当前任务id
function TotalTask.GetQuestID(nQuestIndex)
    return g_pClientPlayer.GetQuestID(nQuestIndex)
end


-- 获取任务列表
local Init = BaseState:New("Init")
function Init:OnEnter()

end

function Init:OnUpdate()
    -- 获取第一次的任务
    local nQuestID = TotalTask.GetQuestID(2)
    TaskRead.GetTaskID(nQuestID)
    TaskRead.SplitState(2)
    fsm:Switch("Sleep")
end

function Init:OnLeave()                             

end

-- PlayerMove
local bPlayerMove=false
local PlayerMove = BaseState:New("PlayerMove")
function  PlayerMove:OnEnter()
    
end

function  PlayerMove:OnUpdate()
    if not bPlayerMove then
        --开启跑图 并帧更新判断跑图是否结束 将执行CMD的帧更新停止
        CustomRunMapByData.Start(TaskRead.tbCustom)
        bPlayerMove = true
        return
    end
    if CustomRunMapByData.IsEnd() then
        -- 重置下次跑图的点数
        CustomRunMapByData.tbRunMapData={}
        fsm:Switch("Sleep")
    end
end

function  PlayerMove:OnLeave()    
    bPlayerMove = false
end


-- Dialogue 
local bDialogue = false
local nDialogueStartTime = 0
local nDialogueNextTime = 2
local Dialogue = BaseState:New("Dialogue")
function  Dialogue:OnEnter()
    if not bDialogue then
        -- 初始化点击 进入人物对话
        Event.Dispatch(EventType.OnSceneInteractByHotkey, false)
        nDialogueStartTime = GetTickCount()
    end
end

function  Dialogue:OnUpdate()
    if GetTickCount()-nDialogueStartTime > nDialogueNextTime*1000 then
        -- 点击进入按钮
        Event.Dispatch(EventType.OnSceneInteractByHotkey, true)
        -- 是否有对话框出现
        local bResult = UIMgr.IsViewOpened(VIEW_ID.PanelPlotDialogue)
        if not bResult then
            -- 进入下一个状态
            fsm:Switch("Sleep")
        end
        nDialogueStartTime = GetTickCount()
    end
end

function  Dialogue:OnLeave()
    bDialogue = false
end


-- Btn
local Btn = BaseState:New("Btn")
local BtnStartTime = 0
local BtnNextTime = 5
local bBtnOperate = false
function  Btn:OnEnter()
    BtnStartTime = GetTickCount()
end

function  Btn:OnUpdate()
    if GetTickCount()-BtnStartTime >= BtnNextTime*1000 then
        if bBtnOperate then
            fsm:Switch("Sleep")
        end
        local CMD = "/cmd "..TaskRead.szBtnCmd
        SearchPanel.RunCommand(CMD)
        bBtnOperate = true
        BtnStartTime = GetTickCount()
    end
end

function  Btn:OnLeave()                           
    bBtnOperate = false
end


-- TaskGM
local TaskGM = BaseState:New("TaskGM")
local TaskGMStartTime = 0
local TaskGMNextTime = 5
local bTaskGMOperate = false
function  TaskGM:OnEnter()
    TaskGMStartTime = GetTickCount()
end

function  TaskGM:OnUpdate()
    if GetTickCount()-TaskGMStartTime >= TaskGMNextTime*1000 then
        if bTaskGMOperate then
            fsm:Switch("Sleep")
            return
        end
        local CMD = "/gm "..TaskRead.szKeyGM
        SearchPanel.RunCommand(CMD)
        bTaskGMOperate = true
        TaskGMStartTime = GetTickCount()
    end
end

function  TaskGM:OnLeave()                           
    bTaskGMOperate = false
end


-- AutoFight
local PlayerRole={}
local AutoFightStartTimer = 0 -- 执行每个技能的时间
local AutoFightAttackTimer = 5 -- 技能释放间隔
local nAttackLineCount = 1 --释放技能的次数
local nAttackLine = 1 -- 当前技能
local nAutoFightCumulativeTime = 0  -- 战斗累计时间
local BtnTargetSelect = false
local AutoFight = BaseState:New("AutoFight")
-- 人物添加的Buff
function PlayerRole.AddBuff()
    -- 初始化操作
    SearchPanel.RunCommand("/gm player.nPhysicsReflection=10000000")
    -- 开启无敌 
    SearchPanel.RunCommand("/gm player.AddBuff(player.dwID,player.nLevel,203,1,3600)")
    -- Ap命中加成
    SearchPanel.RunCommand("/gm for i=1,20 do player.AddBuff(player.dwID,player.nLevel,5235,1,1) end")
    -- 加强回血回蓝
    SearchPanel.RunCommand("/gm player.nLifeReplenishExt=100000000;player.nManaReplenishExt=100000")
    -- true则为显示轻功面板，false则为显示技能面板
    local PlayerState = SprintData.GetViewState()
    -- 如果为技能面板则不切换
    if PlayerState then
        SprintData.ToggleViewState()
    end
end
function  AutoFight:OnEnter()
    -- 战斗前添加初始化buff
    PlayerRole.AddBuff()
    AutoFightStartTimer = GetTickCount()
end

function AutoFight:OnUpdate()
    local player=GetClientPlayer()
    if not player then
        return
    end
    -- 防止人物死亡被秒杀
    if GetTickCount() - AutoFightStartTimer >=  AutoFightAttackTimer*1000 then
        if not BtnTargetSelect then
            UINodeControl.BtnTrigger("BtnTargetSelect")
            BtnTargetSelect = true
            -- 启动武学助手
            AutoBattle.Start()
        end
        -- 是否遍历完技能
        if nAttackLine == 6 then
            nAttackLine = 1
        end
        -- 每释放一个技能累计5秒
        nAutoFightCumulativeTime = nAutoFightCumulativeTime + 5
        -- 超时强杀boss 大于4分钟
        -- 设置释放技能的坐标
        TargetMgr.TrySelectOneTarget()
        -- 获取技能id
        local nSkillID = UIBattleSkillSlot.GetShowUI_Ver2(nAttackLine)
        -- 进行释放
        OnUseSkill(nSkillID, 1)
        nAttackLineCount = nAttackLineCount + 1
        nAttackLine = nAttackLine + 1
        AutoFightStartTimer = GetTickCount()
        -- 至少释放两套技能 再判定是否有问题
        if nAttackLineCount >= 7 then
            -- 是否在战斗
            -- 重制回第一个技能
            nAttackLine = 1
            nAutoFightCumulativeTime = 0
            -- 切换状态
            BtnTargetSelect = false
            SprintData.ToggleViewState()
            nAttackLineCount = 1
            -- 关闭武学助手
            AutoBattle.Stop()
            -- 结束当前状态
            -- 打完后进行睡眠
            fsm:Switch("Sleep")
        end
    end
end


function  AutoFight:OnLeave()                               
end



-- 获取任务列表
local nSleepStartTime = 0
local nSleepCurrentTime=0
local Sleep = BaseState:New("Sleep")
local nQuestLine = 1  -- 做完整体任务的次数
local nTaskLine = 2
function Sleep:OnEnter()
    -- 默认睡眠5秒
    nSleepCurrentTime = 5
end

function Sleep:OnUpdate()
    -- 完成任务
    if TaskRead.nTaskLine == #TaskRead.tbTask+2 then
        -- 完成4次结束任务流程
        if nQuestLine == TotalTask.nTaskCount then
            -- 结束任务
            print("任务已经结束")
            Timer.DelAllTimer(TotalTask)
            bFlag = true
            return
        end
        print("任务还未结束")
        -- 重置任务流程
        TaskRead.Reset()
        local nQuestID = TotalTask.GetQuestID(2)
        TaskRead.GetTaskID(nQuestID)
        TaskRead.nTaskStateLine = 1
        TaskRead.SplitState(TaskRead.nTaskLine)
        nQuestLine = nQuestLine + 1
        return
    end
    -- 重制任务参数
    if TaskRead.nTaskStateLine == #TaskRead.tbTaskState+1 then
        -- 重载任务状态
        TaskRead.nTaskLine = TaskRead.nTaskLine + 1
        TaskRead.SplitState(TaskRead.nTaskLine)
        TaskRead.nTaskStateLine = 1
        return
    end
    if GetTickCount()-nSleepStartTime>nSleepCurrentTime*1000 then
        nSleepStartTime=GetTickCount()
        -- 执行人物操作
        local szTaskState = TaskRead.tbTaskState[TaskRead.nTaskStateLine]
        print("当前状态"..szTaskState)
        if szTaskState == "Sleep" then
            -- Sleep
            nSleepStartTime=GetTickCount()
            -- 根据表获取睡眠时间
            nSleepCurrentTime = TaskRead.nSleeTime
            TaskRead.nTaskStateLine = TaskRead.nTaskStateLine + 1
            return
        elseif szTaskState == "Move" then
            fsm:Switch("PlayerMove")
        elseif szTaskState == "Btn" then
            fsm:Switch("Btn")
        elseif szTaskState == "Dialogue" then
            fsm:Switch("Dialogue")
        elseif szTaskState == "Fight" then
            fsm:Switch("AutoFight")
        elseif szTaskState == "TaskGM" then
            fsm:Switch("TaskGM")
        else
            LoginMgr.Log("Status Error")
        end
    end
end

function Sleep:OnLeave()                             
    TaskRead.nTaskStateLine = TaskRead.nTaskStateLine + 1
end

-- 通过读取任务流程来进行测试



function TotalTask.FrameUpdate()
    -- 是否从地图加载界面进入了游戏
    if not SearchPanel.IsFromLoadingEnterGame() then
        return
    end
    fsm.curState:OnUpdate()
end


function TotalTask.Start()
    -----创建状态机---------------
    -- 六种状态 移动 战斗 对话 睡眠 使用特殊gm 流程Gm操作
    fsm = FsmMachine:New()
    fsm:AddState(AutoFight)
    fsm:AddState(Dialogue)
    fsm:AddState(PlayerMove)
    fsm:AddState(Btn)
    fsm:AddState(Sleep)
    fsm:AddState(TaskGM)
    fsm:AddInitState(Init)
    Timer.AddFrameCycle(TotalTask,1,function ()
        TotalTask.FrameUpdate()
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
        if string.find(szCmd,"TotalTask_start") then
            --启动切图帧更新函数
            TotalTask.Start()
            bFlag = false
        end
		nCurrentTime=GetTickCount()
        nCurrentStep=nCurrentStep+1 
    end
end

Timer.AddFrameCycle(RunMap,1,function ()
    RunMap.FrameUpdate()
end)

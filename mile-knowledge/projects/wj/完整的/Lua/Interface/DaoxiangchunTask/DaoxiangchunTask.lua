local Test = {}
local DaoxiangcunTask = {}
local CharacterMovement = {}  -- 人物移动
local TaskDialogue = {} -- 任务对话
local list_RunMapCMD = {}
local list_RunMapTime = {}
local FlySkill = {}
CharacterMovement.bSwitch = true
--读取tab的内容
local tbRunMapData=SearchPanel.LoadRunMapFile(SearchPanel.szCurrentInterfacePath.."RunMap.tab",2)
list_RunMapCMD = tbRunMapData[1]
list_RunMapTime = tbRunMapData[2]
-- 读取人物坐标
local tTask = {}
local tTargetPointTable = {}
for line in io.lines(SearchPanel.szCurrentInterfacePath.."RunMapTask.tab") do
    if not string.find(line,"%[") then
        local tData = SearchPanel.StringSplit(line,",")
        table.insert(tTargetPointTable,tData)
    else
        table.insert(tTask,tTargetPointTable)
        tTargetPointTable = {}
    end
end
-- 设置人物登录
SearchPanel.tbModule['AutoLogin'].SetAutoLoginInfo(nil,nil,'纯阳','成男')

local nStartTime = 0                            -- 初始化时间
local stay = 0                                  -- 默认立即往第一个目标点跑
local nRowcount =  #tTask[1]           -- 初始化总点数
local nTurnToCount = 1                          -- 第一次调整方向
local init_x = 0                                -- 初始化到目标点的方向向量坐标x
local init_y = 0                                -- 初始化到目标点的方向向量坐标y
local bisArrive = false                         -- 标记未到达目标点
local bisRunning = false                        -- 标记停止跑动
local one_coordinate = ""                       -- 初始化第一个点坐标
local bisStop =  false                          -- 标记结束原地停止
local nTimer=30                                 --计时器
local nCurrentTime=0
local bBack = false
local nLine = 0
local nRunMapCount = 1
tTargetPointTable = tTask[1]                   -- 初始化第一物人物坐标
local bFlag = true
local nTaskLine = 2                             -- 当前进行任务的下标

-- 人物移动
local function GetOnePoint_Coordinate()                                                 -- 获取第一个点坐标
    local tLine = tTargetPointTable[1]
    local one_x = tLine[1]
    local one_y = tLine[2]
    local one_z = tLine[3]
    one_coordinate = one_x..","..one_y..","..one_z
end

function CharacterMovement.SetPointsFile()                                           -- 修改地图文件
    GetOnePoint_Coordinate()                                                             -- 重新获取第一个点坐标
    OutputMessage("MSG_SYS",'set success'.."\n")
    CharacterMovement.reset()
end

-- 重置人物奔跑默认参数
function Resetting()
    nStartTime = 0                            -- 初始化时间
    stay = 0                                  -- 默认立即往第一个目标点跑
    nRowcount =  #tTargetPointTable           -- 初始化总点数
    nTurnToCount = 1                          -- 第一次调整方向
    init_x = 0                                -- 初始化到目标点的方向向量坐标x
    init_y = 0                                -- 初始化到目标点的方向向量坐标y
    bisArrive = false                         -- 标记未到达目标点
    bisRunning = false                        -- 标记停止跑动
    one_coordinate = ""                       -- 初始化第一个点坐标
    bisStop =  false                          -- 标记结束原地停止
    nTimer=30                                 --计时器
    nCurrentTime=0
    bBack = false
    nLine = 0
    nRunMapCount = 1
end

local function CalcDirection(vector_x,vector_y)                                          -- 计算朝向
    return GetLogicDirection(vector_x,vector_y)
end

local function SetOnePointTurnTo()

    local tLine = tTargetPointTable[1]
    local current_x = tLine[1]
    local current_y = tLine[2]

    local tLine = tTargetPointTable[2]
    local next_x = tLine[1]
    local next_y = tLine[1]

    local vector_x =  next_x - current_x
    local vector_y =  next_y - current_y

    local turnto = CalcDirection(vector_x,vector_y)
    TurnTo(turnto)                      -- 调整玩家当前面部朝向

end

function CharacterMovement.reset()                                                    -- 重置插件
    -- 判断玩家此时的状态
    if bisRunning then                                                            -- 如果 正在跑动
        MoveForWard_Stop()                                -- 停止自动跑
    end

    SetOnePointTurnTo()                                                           -- 去到第一个点，并且玩家朝向第2个点
    CharacterMovement.bSwitch = false                                                                   -- 除了为初始化的变量，其他变量恢复默认
    nLine = 0
    bisRunning = false
    nTurnToCount = 1
    bisStop =  false
end


local nLastCheckStopTime=0
local function JudgeArrive(vector_direction)                                       -- 判断是否到达目标点

    local player = GetClientPlayer()                                               -- 获取玩家当前坐标
    local current_x = player.nX
    local current_y = player.nY

    local tLine = tTargetPointTable[nLine]                                         -- 取得第i行点信息
    local next_x = tLine[1]
    local next_y = tLine[2]

    if nTurnToCount == 1 then
        init_x =  next_x - current_x
        init_y =  next_y - current_y
        nTurnToCount = 2
    else
        local vector_direction = (next_x - current_x) * init_x + (next_y - current_y) * init_y
        if vector_direction <= 0 then
            if bBack then
                nLine = nLine - 1
            else
                nLine = nLine + 1
            end
            bisArrive = true                                                         -- 到达
            bisRunning  = false                                                      -- 停止跑动
            nTurnToCount = 1                                                         -- 下一个目标点调整方向的次数
            nLastCheckStopTime=GetTickCount()
            return
        else
            if GetTickCount()-nLastCheckStopTime>30*1000 then    --nStopTime秒后未到达，默认被建筑物卡住了  跳跃一下
                Jump()
                nLastCheckStopTime=GetTickCount()
            end
        end
    end
    bisArrive = false                                                                -- 未到达
end

local nTurnCount = 0
local function AdjustDirection()                                                   -- 调整方向
    local player = GetClientPlayer()                                               -- 获取玩家当前坐标
    print(player.nFaceDirection)
    local current_x = player.nX
    local current_y = player.nY

    local tLine = tTargetPointTable[nLine]                                         -- 取得第i行点信息
    local next_x = tLine[1]
    local next_y = tLine[2]

    local vector_x =  next_x - current_x
    local vector_y =  next_y - current_y
    local turnto = CalcDirection(vector_x,vector_y)                                -- 计算朝向

    LoginMgr.Log("RunMapByPoint",string.format("[RunMapByPoint] TurnTo {%d}",turnto))
    TurnTo(turnto)                       -- 调整当前面部朝向
    nTurnCount = turnto
    if turnto-nTurnCount >= 15 then -- 大于20调整面部方向
        TurnToFaceDirection()   -- 再调节面部方向 
    end
end


if #tTargetPointTable == 0 then
    GetOnePoint_Coordinate()                                                  -- 获取第一个点坐标
end

local bStart=true
function CharacterMovement.FrameUpdate()
    if not CharacterMovement.bSwitch then
        return
    end
    local player = GetClientPlayer()
    if bStart then
        if GetTickCount()-nCurrentTime < nTimer*1000 then   --开始运行
            return
        end
        if GetTickCount()-nCurrentTime < (nTimer+20)*1000 then  --20s切图
            return
        else
            SetOnePointTurnTo()
            bStart=false
        end
    end

    if nLine==0 then
        if player.nMoveState==1 then
            MoveForWard_Start()                            -- 开始自动跑
        end
        nRunMapCount=nRunMapCount-1
        nLine = nLine+2
        bBack=false     --正向跑
        nCurrentTime=GetTickCount()
        nStartTime = nCurrentTime
    end

    if nLine == nRowcount+1 then                                              -- 跑到最后一个点
        MoveForWard_Stop() --停止跑动
        Timer.DelAllTimer(CharacterMovement)
        CharacterMovement.bIsRun = false
        CharacterMovement.bSwitch = false
        print("CharacterMovement Stop")
        return
    end

    JudgeArrive()                                                             -- 判断是否到达目标点

    if not bisArrive then                                                     -- 如果 未达到下一个目标点
        AdjustDirection()                                                     -- 调整方向
        if not bisRunning then                                                -- 如果 停止跑动状态
            MoveForWard_Start()
        end
    end
end

-- 装备触发后进行穿戴
local _EquipTips = TipsHelper.ShowQuickEquipTip
function EquipTips(dwBox, dwX)
    _EquipTips(dwBox, dwX)
    ItemData.EquipItem(dwBox, dwX)
    UIMgr.Close(VIEW_ID.PanelHint)
end
TipsHelper.ShowQuickEquipTip=EquipTips

-- 人物攻击
local bAttack = false
local BtnTargetSelect = false
local nSkillLine = 1    -- 当前技能
local nSkillCount = 0   -- 累计技能释放总数
function NormalAttack()
    -- GM提高伤害
    SearchPanel.RunCommand("/gm player.nPhysicsAttackPower=200000;player.nSolarAttackPower=200000;player.nNeutralAttackPower=200000;player.nLunarAttackPower=200000;player.nPoisonAttackPower=200000")
    -- 切换人物状态
    -- true则为显示轻功面板，false则为显示技能面板
    local PlayerState = SprintData.GetViewState()
    -- 如果为技能面板则不切换
    if PlayerState then
        SprintData.ToggleViewState()
    end
    -- 是否遍历完技能
    if nSkillLine == 6 then
        nSkillLine = 1
    end
    -- 锁定敌人
    if not BtnTargetSelect then
        UINodeControl.BtnTrigger("BtnTargetSelect")
        BtnTargetSelect = true
    end
    -- 设置释放技能的坐标
    SkillData.SetCastPointToTargetPos()
    -- 普通攻击
    OnUseSkill(UIBattleSkillSlot.GetShowUI_Ver2(nSkillLine), 1)
    nSkillLine = nSkillLine + 1
    nSkillCount = nSkillCount + 1
    if nSkillCount >= 5 then
        local player=GetClientPlayer()
        -- 是否在战斗
        if player.bFightState then
            bAttack = true
        else
            bAttack = false
            -- 结束后切换人物状态
            SprintData.ToggleViewState()
            BtnTargetSelect = false
            nSkillCount=0
        end
    end
end

-- 等待动画
local bAnimation = false
local nAnimation = tonumber(15)
local nCurrentAnimationTime = 0
local pCurrentTaskTime = 0
local nNextTaskTime=tonumber(1)
local bTask1 = false
local bResult = true
-- 判断人物任务是否完成 传入任务id
function TaskComplete(nTaskID)
    local taskResult = QuestData.IsProgressing(nTaskID)
    if not taskResult then
        bAttack = false
    end
end


local bFlyStart = false
local nFlyStartTime = 0
local bFlySkill = false
local nFlySkillCount = 0
-- 李复轻功部分
function FlySkill.FrameUpdate()
    -- 强制移动后 调整当前面部朝向和朝向启动轻功
    if not bFlyStart then
        SearchPanel.RunCommand("/gm player.SetPosition(19121, 24226, 1054144)")
        TurnTo(226)
        TurnToFaceDirection()
        nFlyStartTime = GetTickCount()
        bFlyStart = true
    end
    -- 等待2秒后启动轻功
    if GetTickCount()-nFlyStartTime >= 1*1000 then -- 关联到每两秒跳一次
        if nFlySkillCount == 5 then
            SearchPanel.MyExecuteScriptCommand("FuncSlotMgr.tbCommands.EndSprint()")
            SearchPanel.RunCommand("/gm player.Stop()")        -- 完成轻功后停止在原地
            Timer.DelAllTimer(FlySkill)
            bFlyStart = false
            FlySkill.bIsRun = false
        end
        if not bFlySkill then
            SearchPanel.MyExecuteScriptCommand("FuncSlotMgr.tbCommands.StartSprint()")
            Jump()
            bFlySkill = true
        else
            Jump()
            nFlySkillCount = nFlySkillCount + 1     -- 次数跳
        end
        nFlyStartTime = GetTickCount()
    end
end


local nPlotDialogue = false
local nSetPosition = false
-- 任务对话帧函数
function TaskDialogue.FrameUpdate()
    if GetTickCount()-pCurrentTaskTime>nNextTaskTime*1000 then
        if not nPlotDialogue then
            Event.Dispatch(EventType.OnSceneInteractByHotkey, false)
            nPlotDialogue = true
        else
            Event.Dispatch(EventType.OnSceneInteractByHotkey, true)
            bResult = UIMgr.IsViewOpened(VIEW_ID.PanelPlotDialogue)
            if not bResult then
                -- 任务流程
                -- 用人物坐标下标来判断移动到那个任务了
                -- 木童来试身手
                if nTaskLine == 4  then
                    -- 判断任务是否完成 任务id 801 
                    -- 关闭新手教程
                    UIMgr.Close(VIEW_ID.PanelTeach)
                    local taskResult = QuestData.IsProgressing(801)
                    if taskResult then
                        NormalAttack()
                        bAttack = true
                    else
                        bAttack = false
                    end
                -- 攻击混混   
                elseif nTaskLine == 8 or nTaskLine == 9 then
                    NormalAttack()
                    if nTaskLine == 9 then
                        bAttack = true
                        TaskComplete(825)
                    end
                -- 采集凝血草
                elseif nTaskLine == 12 or nTaskLine == 13 or nTaskLine == 14 then
                Event.Dispatch(EventType.OnSceneInteractByHotkey, false)
                    if not bAnimation then
                        nCurrentAnimationTime = GetTickCount()
                        bAnimation = true
                    end
                    if GetTickCount()-nCurrentAnimationTime>nAnimation*1000 then
                        if bAnimation then
                            bAnimation = false
                        end
                    end
                -- 王婆婆的杂粮
                elseif nTaskLine == 16 then
                    SearchPanel.RunCommand("/gm player.AddItem(5 ,21844)")
                -- 野林巡逻贼0/5
                elseif nTaskLine == 23 or nTaskLine  == 24 or nTaskLine == 25 or nTaskLine == 26 or nTaskLine == 27 then
                    NormalAttack()
                    if nTaskLine == 27 then
                        bAttack = true
                        TaskComplete(843)
                    end
                -- 二流杀手
                elseif nTaskLine == 30 or nTaskLine == 31 or nTaskLine == 32 then
                    NormalAttack()
                    if nTaskLine == 32 then
                        bAttack = true
                        TaskComplete(844)
                    end
                -- 小毛贼0/3 流氓 0/3
                elseif nTaskLine == 34 or nTaskLine == 35 or nTaskLine == 36 or nTaskLine == 37 or nTaskLine == 38 then
                    if nTaskLine == 35 then
                        TurnTo(41)
                    end
                    NormalAttack()
                    if nTaskLine == 38 then
                        bAttack = true
                        TaskComplete(1032)
                    end
                -- 烧草堆
                elseif nTaskLine == 42 then
                    Event.Dispatch(EventType.OnSceneInteractByHotkey, false)
                    if not bAnimation then
                        nCurrentAnimationTime = GetTickCount()
                        bAnimation = true
                    end
                    if GetTickCount()-nCurrentAnimationTime>nAnimation*1000 then
                        if bAnimation then
                            bAnimation = false
                        end
                    end
                -- 大侠墓
                elseif nTaskLine == 45 then
                    Event.Dispatch(EventType.OnSceneInteractByHotkey, false)
                    if not bAnimation then
                        nCurrentAnimationTime = GetTickCount()
                        bAnimation = true
                    end
                    if GetTickCount()-nCurrentAnimationTime>nAnimation*1000 then
                        if bAnimation then
                            bAnimation = false
                            -- 关闭界面
                            UIMgr.Close(VIEW_ID.PanelOldDialogue)
                        end
                    end
                -- 董龙boss战
                elseif nTaskLine == 52 then
                    NormalAttack()
                    bAttack = true
                    TaskComplete(873)
                elseif nTaskLine == 57 then
                    -- 结束主线用例
                    bTask1 = true
                    CharacterMovement.bSwitch = true
                    -- 点击一次前往师门
                    Event.Dispatch(EventType.OnSceneInteractByHotkey, false)
                    Timer.DelAllTimer(TaskDialogue)
                    Timer.DelAllTimer(DaoxiangcunTask)
                    bFlag = true
                end
                if not bAnimation then
                    if not bAttack then
                        if nTaskLine ~= #tTask+1 then
                            -- 重置人物移动
                            nPlotDialogue = false
                            tTargetPointTable = tTask[nTaskLine]
                            bStart=true
                            nSetPosition = false
                            bTask1 = false
                            nTaskLine = nTaskLine + 1
                            ToggleViewState = false
                            Resetting()
                            Timer.DelAllTimer(TaskDialogue)
                            TaskDialogue.bIsRun=false
                        end
                    end
                end
            end
        end
        pCurrentTaskTime = GetTickCount()
    end
 end

local nWaitTime = 0
local bWaitTime = false
local pCurrentTime1 = 0
local nNextTime1=tonumber(2)
local nSetPositionStartTime = 0
local bChangeState = false
function DaoxiangcunTask.FrameUpdate()
    local player=GetClientPlayer()
    if not SearchPanel.IsFromLoadingEnterGame() then
        return
    end
    if GetTickCount()-pCurrentTime1>nNextTime1*1000 then
        -- 启动任务
        -- 新手教学页面的处理 有改动再去除
        local bTeach = UIMgr.IsViewOpened(VIEW_ID.PanelTeach)
        if bTeach then
            UIMgr.Close(VIEW_ID.PanelTeach)
        end
        -- 剧情对话
        if not CharacterMovement.bSwitch then
            -- 在人物进行对话前进行 坐标的移动
            if GetTickCount()- nSetPositionStartTime > 5*1000 then
                if not nSetPosition then
                    local tLine = tTargetPointTable[nLine-1]                                         -- 取得第i行点信息
                    SearchPanel.RunCommand("/gm player.SetPosition("..tLine[1]..","..tLine[2]..","..tLine[3]..")")
                    nSetPosition = true
                    nSetPositionStartTime = GetTickCount()
                    return
                end
                Timer.AddFrameCycle(TaskDialogue,1,function()
                    TaskDialogue.FrameUpdate()
                end)
                CharacterMovement.bSwitch = true
            end
        end
        -- 人物移动
        if not bTask1 then
            -- 防止有怪跟过来导致移动速度变慢
            if nTaskLine == 52 or nTaskLine == 9 then
                if player.bFightState then
                    NormalAttack()
                    return
                end
                Timer.AddFrameCycle(CharacterMovement,1,function()
                    CharacterMovement.FrameUpdate()
                end)
                bTask1 = true
            -- 李复轻功部分
            elseif nTaskLine == 22  then
                if not bChangeState then
                    Timer.AddFrameCycle(FlySkill,1,function()
                        FlySkill.FrameUpdate()
                    end)
                    bChangeState = true
                    return
                end
                -- 当轻功停止后直接进行跑动状态
                if not bWaitTime and  not bFlyStart then
                    nWaitTime = GetTickCount()
                    bWaitTime = true
                end
                if GetTickCount()-nWaitTime>20*1000 then
                    Timer.AddFrameCycle(CharacterMovement,1,function()
                        CharacterMovement.FrameUpdate()
                    end)
                    bTask1 = true
                end
            else
                Timer.AddFrameCycle(CharacterMovement,1,function()
                    CharacterMovement.FrameUpdate()
                end)
                bTask1 = true
            end
        end
        pCurrentTime1=GetTickCount()
    end
end


local pCurrentTime = 0
local nNextTime=tonumber(20)
local nCurrentStep=1
function FrameUpdate()
    local player=GetClientPlayer()
    if not player then
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
        nNextTime=nTime
        --切图操作
        if string.find(szCmd,"DaoxiangchunTask") then
            -- 启动主线剧情
            Timer.AddFrameCycle(DaoxiangcunTask,1,function ()
                DaoxiangcunTask.FrameUpdate()
            end)
            bFlag = false
        end
        if string.find(szCmd,"perfeye_start") then
            SearchPanel.bPerfeye_Start=true
        end
        if string.find(szCmd,"perfeye_stop") then
            SearchPanel.bPerfeye_Stop=true
		end
		pCurrentTime=GetTickCount()
        nCurrentStep=nCurrentStep+1
    end
end


Timer.AddFrameCycle(Test,1,function ()
    FrameUpdate()
end)

return DaoxiangcunTask
LoginMgr.Log("MainTask","MainTask imported")
MainTask= {} 
MainTask.bSwitch=true -- 插件开关
-- 旧版读取tab的内容
local RunMap = {}
local list_RunMapCMD = {}
local list_RunMapTime = {}
local tbRunMapData=SearchPanel.LoadRunMapFile(SearchPanel.szCurrentInterfacePath.."RunMap.tab",2)
list_RunMapCMD = tbRunMapData[1]
list_RunMapTime = tbRunMapData[2]
local bFlag = true

-- 读取人物坐标 和 状态操作
TaskRead={}
TaskRead.tbTask = {}
TaskRead.tbTaskState = {}
TaskRead.tbCustom = {}
TaskRead.nTaskLine =  2 -- 当前执行的任务
TaskRead.nSleeTime = 0
TaskRead.nTaskStateLine = 1 -- 当前任务状态
TaskRead.nTaskMove = false
TaskRead.szBtnCmd = nil
TaskRead.szKeyGM = nil
local tbTargetPointTable = {}
for line in io.lines(SearchPanel.szCurrentInterfacePath.."RunMapTask.tab") do
    if not string.find(line,"%[") then
        local tData = SearchPanel.StringSplit(line," ")
        table.insert(tbTargetPointTable,tData)
    else
        table.insert(TaskRead.tbTask,tbTargetPointTable)
        tbTargetPointTable = {}
    end
end
-- 通用分割流程
function TaskRead.SplitState(nLine)
    TaskRead.tbTaskState = {}
    TaskRead.tbCustom = {}
    TaskRead.nTaskMove = false
    TaskRead.szBtnCmd = nil
    TaskRead.nSleeTime = 0
    local keywords = {
        Btn = "Btn",
        Sleep = "Sleep",
        Dialogue = "Dialogue",
        Fight = "Fight",
        TaskGM = "TaskGM"
    }

    for _, value in ipairs(TaskRead.tbTask[nLine] or {}) do
        for _, v in ipairs(value) do
            if not v:find("x") then
                local isSpecial = false
                for key, word in pairs(keywords) do
                    if v:find(word) then
                        isSpecial = true
                        if word == "Btn" then
                            table.insert(TaskRead.tbTaskState, "Btn")
                            TaskRead.szBtnCmd = v:sub(5)
                        elseif word == "Sleep" then
                            table.insert(TaskRead.tbTaskState, "Sleep")
                            TaskRead.nSleeTime = tonumber(v:sub(7))
                        elseif word == "Dialogue" then
                            table.insert(TaskRead.tbTaskState, "Dialogue")
                        elseif word == "Fight" then
                            table.insert(TaskRead.tbTaskState, "Fight")
                        end
                        break
                    end
                end
                if not isSpecial then
                    local coordinate = SearchPanel.StringSplit(v, "%s")
                    TaskRead.tbCoordinate = {coordinate[1], coordinate[2], coordinate[3]}
                    table.insert(TaskRead.tbCustom, TaskRead.tbCoordinate)
                    if not TaskRead.nTaskMove then
                        table.insert(TaskRead.tbTaskState, "Move")
                        TaskRead.nTaskMove = true
                    end
                end
            end
        end
    end
end


-----init----------------
Init = BaseState:New("Init")
function  Init:OnEnter()

end

function  Init:OnUpdate()
    fsm:Switch("Sleep")
end

function  Init:OnLeave()                               

end

-- 特殊按钮操作
BtnOperate = BaseState:New("BtnOperate")
local BtnStartTime = 0
local BtnNextTime = 5
local bBtnOperate = false
local nCopyLine = 1
function  BtnOperate:OnEnter()
    BtnStartTime = GetTickCount()
end

function  BtnOperate:OnUpdate()
    if GetTickCount()-BtnStartTime >= BtnNextTime*1000 then
        if bBtnOperate then
            fsm:Switch("Sleep")
            bBtnOperate = false
            return
        end
        local CMD
        if TaskRead.szBtnCmd:sub(1,6) == "player" then
            CMD = "/gm "..TaskRead.szBtnCmd
            SendGMCommand("for i=1,4 do player.DelBuff(28739,1) end")
        else
            print(TaskRead.szBtnCmd)
            CMD = "/cmd "..TaskRead.szBtnCmd
        end
        SearchPanel.RunCommand(CMD)
        bBtnOperate = true
        BtnStartTime = GetTickCount()
    end
end

function  BtnOperate:OnLeave()                           

end

-- AutoFight
local PlayerRole={}
local AutoFightStartTimer = 0 -- 执行每个技能的时间
local AutoFightAttackTimer = 5 -- 技能释放间隔
local nAttackLineCount = 1 --释放技能的次数
local nAttackLine = 1 -- 当前技能
local nAutoFightCumulativeTime = 0  -- 战斗累计时间
local BtnTargetSelect = false
AutoFight = BaseState:New("AutoFight")
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
local playerX = 0
local playerY = 0
local bCoordinate = false -- 坐标记录
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
    if not bCoordinate then
        playerX = player.nX
        playerY = player.nY
        bCoordinate= true
    end
    -- 防止人物死亡被秒杀
    -- 原地距离是否远离坐标500则传送回原来位置
    if player.nMoveState == 16 or (player.nX+player.nY) - (playerX+playerY) > 500 then
        -- 人物复活后直接重新进行buff添加 玩家人物死亡的同时 让死亡机器人复活 重新进行打斗
        -- 传送回原来的坐标
        -- SearchPanel.RunCommand("/gm player.SetPosition("..tbCustom[#tbCustom][1]..","..tbCustom[#tbCustom][2]..","..tbCustom[#tbCustom][3]..")")
        -- 重新添加角色buff
        PlayerRole.AddBuff()
        -- 重制回第一个技能
        nAttackLine = 1
        -- 重新锁定
        BtnTargetSelect = false
        -- 重启战斗
        nAttackLineCount = 1
        AutoFightStartTimer = GetTickCount()
    end
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
        if nAutoFightCumulativeTime >= 240  then
            -- 切换下一个锁定
            SearchPanel.RunCommand("/gm if player.GetSelectCharacter() ~= nil then player.GetSelectCharacter().Die() end")
        end
        -- 设置释放技能的坐标
        SkillData.SetCastPointToTargetPos()
        -- 获取技能id
        local nSkillID = UIBattleSkillSlot.GetShowUI_Ver2(nAttackLine)
        -- 进行释放
        OnUseSkill(nSkillID, 1)
        SendGMCommand("for i=1,1 do player.GetSelectCharacter().FireAIEvent(2002,0,0) end")
        nAttackLineCount = nAttackLineCount + 1
        nAttackLine = nAttackLine + 1
        AutoFightStartTimer = GetTickCount()
        -- 至少释放两套技能 再判定是否有问题
        if nAttackLineCount >= 7 then
            -- 是否在战斗
            if not GetClientPlayer().bFightState then
                -- 重制回第一个技能
                nAttackLine = 1
                nAutoFightCumulativeTime = 0
                -- 切换状态
                BtnTargetSelect = false
                SprintData.ToggleViewState()
                nAttackLineCount = 1
                -- 重制坐标
                -- 关闭武学助手
                AutoBattle.Stop()
                bCoordinate = false
                -- 结束当前状态
                -- 打完后进行睡眠
                fsm:Switch("Sleep")
            end
        end
    end
end


function  AutoFight:OnLeave()                               
end

-- 使用轻功为特殊状态 无论是否轻功飞过目标点在最后都 强制位移坐标 只有稻香村会用到暂时直接写死
local nFlySkillTime = 1 -- 每隔2秒跳跃一次
local nFlySkillStartTime = 0
local bFlySkill =false
local nFlySkill_x =56927
local nFlySkill_y =50266
local nFlySkill_z = 1052480
local bFlySkilJump =false
local nFlySkillLine = 1 -- 轻功的段数
FlySkill = BaseState:New("FlySkill")

-- 控制轻功接口
function FlySkillStart()
    SearchPanel.MyExecuteScriptCommand("FuncSlotMgr.tbCommands.StartSprint()")
end

function FlySkillStop()
    SearchPanel.MyExecuteScriptCommand("FuncSlotMgr.tbCommands.EndSprint()")
end

function FlySkillJump()
    Jump()
end

-- 面向调整
local function AdjustDirection()                                                   -- 调整方向
    TurnTo(240)
end

function  FlySkill:OnEnter()
    if not bFlySkill then
        -- 初始化轻功启动
        AdjustDirection()
        nFlySkillStartTime = GetTickCount()
        bFlySkill=true
    end
end

function  FlySkill:OnUpdate()
    if GetTickCount()-nFlySkillStartTime > nFlySkillTime*1000 then
        if nFlySkillLine == 4 then
            -- 结束轻功
            FlySkillStop()
            bFlySkilJump=false
            bFlySkill=false
            -- 进入下一个状态
            fsm:Switch("Sleep")
            return
        end
        if not bFlySkilJump then
            FlySkillStart()
            bFlySkilJump=true
        else
            FlySkillJump() -- 执行跳跃
            nFlySkillLine = nFlySkillLine + 1
        end
        nFlySkillStartTime = GetTickCount()
    end
end

function  FlySkill:OnLeave()

end

-- Dialogue 对话
local bDialogue = false
local nDialogueStartTime = 0
local nDialogueNextTime = 2
Dialogue = BaseState:New("Dialogue")
function  Dialogue:OnEnter()
    if not bDialogue then
        -- 初始化点击 进入人物对话
        Event.Dispatch(EventType.OnSceneInteractByHotkey, false)
        nDialogueStartTime = GetTickCount()
    end
end

function  Dialogue:OnUpdate()
    if GetTickCount()-nDialogueStartTime > nDialogueNextTime*1000 then
        -- 点击剧情
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

-- PlayerMove
local bPlayerMove=false
PlayerMove = BaseState:New("PlayerMove")
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


-- Sleep
local nSleepStartTime = 0
local nSleepCurrentTime=0
Sleep = BaseState:New("Sleep")
function  Sleep:OnEnter()
    -- 进入状态之前现重置睡眠时间
    nSleepCurrentTime = 5 -- 每个操作启动前都要进行等待秒数
    nSleepStartTime=GetTickCount()
end

function  Sleep:OnUpdate()
    -- 任务流程是否结束
    if TaskRead.nTaskLine == #TaskRead.tbTask+2 then
         -- 结束帧函数
        Timer.DelAllTimer(MainTask)
        bFlag = true
     end
    if TaskRead.nTaskStateLine == #TaskRead.tbTaskState+1 then
        TaskRead.nTaskLine = TaskRead.nTaskLine + 1
        -- 重制下个任务参数
        TaskRead.nTaskMove = false
        TaskRead.nTaskStateLine = 1
        TaskRead.SplitState(TaskRead.nTaskLine)
        return
    end
    if GetTickCount()-nSleepStartTime>nSleepCurrentTime*1000 then
        nSleepStartTime=GetTickCount()
        -- 执行人物操作 处理对应状态
        if TaskRead.tbTaskState[TaskRead.nTaskStateLine] == "Sleep" then
            -- Sleep
            nSleepStartTime=GetTickCount()
            -- 根据表获取睡眠时间
            nSleepCurrentTime = TaskRead.nSleeTime
            TaskRead.nTaskStateLine = TaskRead.nTaskStateLine + 1
        elseif TaskRead.tbTaskState[TaskRead.nTaskStateLine] == "Move" then
            fsm:Switch("PlayerMove")
        elseif TaskRead.tbTaskState[TaskRead.nTaskStateLine] == "Btn" then
            fsm:Switch("BtnOperate")
        elseif TaskRead.tbTaskState[TaskRead.nTaskStateLine] == "Dialogue" then
            fsm:Switch("Dialogue")
        elseif TaskRead.tbTaskState[TaskRead.nTaskStateLine] == "Fight" then
            fsm:Switch("AutoFight")
        elseif TaskRead.tbTaskState[TaskRead.nTaskStateLine] == "FlySkill" then
            fsm:Switch("FlySkill")
        else
            LoginMgr.Log("Status Error")
        end
    end
end

function  Sleep:OnLeave()
    -- 每当睡眠结束后自动推进下一个任务状态
    TaskRead.nTaskStateLine = TaskRead.nTaskStateLine + 1
end



function MainTask.Start()
    -----创建状态机---------------
    -- 六种状态 移动 战斗 对话 睡眠
    fsm = FsmMachine:New()
    fsm:AddState(AutoFight)
    fsm:AddState(Dialogue)
    fsm:AddState(PlayerMove)
    fsm:AddState(Sleep)
    fsm:AddState(FlySkill)
    fsm:AddState(BtnOperate)
    fsm:AddInitState(Init)
    Timer.AddFrameCycle(MainTask,1,function ()
        MainTask.FrameUpdate()
    end)
    return true
end


--帧更新函数
function MainTask.FrameUpdate()
    -- 是否从地图加载界面进入了游戏
    if not SearchPanel.IsFromLoadingEnterGame() then
        return
    end
    fsm.curState:OnUpdate()
end

-- 暂时代替
local pCurrentTime = 0
local nNextTime=tonumber(20)
local nCurrentStep=1
function FrameUpdate()
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
        nNextTime=nTime
        --切图操作
        if string.find(szCmd,"Dungeons") then
            TaskRead.SplitState(TaskRead.nTaskLine)
            -- 启动任务
            MainTask.Start()
            -- 初始化 参数
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

Timer.AddFrameCycle(RunMap,1,function ()
    FrameUpdate()
end)


-- 教学页面关闭
local ClsoeTeach = {}
function ClsoeTeach.FrameUpdate()
    if UIMgr.IsViewOpened(VIEW_ID.PanelTeach_UIMainLayer) then
        TeachEvent.TeachClose(1304)
    end
    if UIMgr.IsViewOpened(VIEW_ID.PanelNormalConfirmation) then
        UINodeControl.BtnTrigger("BtnOk")
    end
end
Timer.AddCycle(ClsoeTeach,1,function ()
    ClsoeTeach.FrameUpdate()
end)

-- 新功能重复点击按钮解决一些 中途需要点击的问题 一般都有技能id
RepeatButton={}
function RepeatButton.Start(nSkillId)
    -- 默认执行0.5秒点击一次
    Timer.AddCycle(RepeatButton,0.5,function () OnUseSkill(tonumber(nSkillId), 1) end)
end


function RepeatButton.Stop()
    Timer.DelAllTimer(RepeatButton)
end
-- 视频播放时间
--[[]]
local tbVideoPlayer = {}
local nVideoTimer = 15  -- 视频播放时间
local nVideoStartTimer = 0  -- 视频播放时间
local bVideo = false
local bVideoStart = true
function tbVideoPlayer.FrameUpdate()
    if bVideoStart then
        if UIMgr.IsViewOpened(VIEW_ID.PanelVideoPlayer) or  UIMgr.IsViewOpened(VIEW_ID.PanelStoryDisplay)  then
            bVideo = true
            nVideoStartTimer = GetTickCount()
            bVideoStart = false
            return
        end
    end
    if bVideo then
        if GetTickCount()- nVideoStartTimer >= nVideoTimer*1000 then
            UIMgr.Close(VIEW_ID.PanelVideoPlayer)
            UIMgr.Close(VIEW_ID.PanelStoryDisplay)
            bVideo = false
            bVideoStart = true
        end
    end
end
Timer.AddCycle(tbVideoPlayer,1,function ()
    tbVideoPlayer.FrameUpdate()
end)

-- 穿戴装备
-- 装备触发后进行穿戴
local _EquipTips = TipsHelper.ShowQuickEquipTip
function EquipTips(dwBox, dwX)
    _EquipTips(dwBox, dwX)
    ItemData.EquipItem(dwBox, dwX)
    UIMgr.Close(VIEW_ID.PanelHint)
end
TipsHelper.ShowQuickEquipTip=EquipTips

LoginMgr.Log("MainTask","MainTask End")

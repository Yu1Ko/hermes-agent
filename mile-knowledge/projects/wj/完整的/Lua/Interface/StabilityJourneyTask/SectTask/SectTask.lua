LoginMgr.Log("SectTask","SectTask imported")
SectTask= {} 
SectTask.bSwitch=true -- 插件开关
local nSleepTime -- 睡眠时间


-- 读取人物坐标 和 状态操作
local tbTaskSect = {}
local nTaskSectLine = 1 -- 默认为2
local tbSectTargetPointTable = {}
for line in io.lines(SearchPanel.szInterfacePath.."StabilityJourneyTask/SectTask/RunMapTask.tab") do
    if not string.find(line,"%[") then
        local tData = SearchPanel.StringSplit(line," ")
        table.insert(tbSectTargetPointTable,tData)
    else
        table.insert(tbTaskSect,tbSectTargetPointTable)
        tbSectTargetPointTable = {}
    end
end

-- 分割状态
local tbSectCustom = {}
local tbSectCoordinate = {}
local tbSectTaskState = {}  -- 获取状态表
local nTaskStateLine = 1
local nSectTaskMove = false
local szSectBtnCmd -- 特殊操作的语句
function SectSplitState(nLine)
    tbSectTaskState = {}
    tbSectCustom = {}
    tbSectCoordinate = {}
    for _, value in pairs(tbTaskSect[nLine]) do
        for _, v in pairs(value) do
            if not string.find(v,"Btn") and not string.find(v,"Sleep") and not string.find(v,"Dialogue") and not string.find(v,"Fight") then
                if not string.find(v,"x") then
                    local coordinate = SearchPanel.StringSplit(v,"%s")
                    tbSectCoordinate = {
                        coordinate[1],
                        coordinate[2],
                        coordinate[3], 
                    }
                    table.insert(tbSectCustom,tbSectCoordinate)
                    if not nSectTaskMove then
                        table.insert(tbSectTaskState,"Move")
                        nSectTaskMove = true
                    end
                end
            else
                if string.find(v,"Sleep") then
                    table.insert(tbSectTaskState,"Sleep")
                    nSleepTime = tonumber(v:sub(7))
                elseif string.find(v,"Dialogue") then
                    table.insert(tbSectTaskState,"Dialogue")
                elseif string.find(v,"Fight") then
                    table.insert(tbSectTaskState,"Fight")
                elseif string.find(v,"Btn") then
                    table.insert(tbSectTaskState,"Btn")
                    szSectBtnCmd = v:sub(5)
                else
                    print("Read Error")
                end
            end
        end
    end
end

-----init----------------
SectInit = BaseState:New("SectInit")
function  SectInit:OnEnter()

end

function  SectInit:OnUpdate()
    fsm:Switch("SleepSect")
end

function  SectInit:OnLeave()                               

end

-- 特殊按钮操作
BtnSectOperate = BaseState:New("BtnSectOperate")
local BtnSectStartTime = 0
local BtnSectNextTime = 5
local bBtnSectOperate = false
function  BtnSectOperate:OnEnter()
    BtnSectStartTime = GetTickCount()
end

function  BtnSectOperate:OnUpdate()
    if GetTickCount()-BtnSectStartTime >= BtnSectNextTime*1000 then
        if bBtnSectOperate then
            fsm:Switch("SleepSect")
        end
        local CMD
        if szSectBtnCmd:sub(1,6) == "player" then
            CMD = "/gm "..szSectBtnCmd
            SendGMCommand("for i=1,4 do player.DelBuff(28739,1) end")
        else
            CMD = "/cmd "..szSectBtnCmd
        end
        SearchPanel.RunCommand(CMD)
        bBtnSectOperate = true
        BtnStartTime = GetTickCount()
    end
end

function  BtnSectOperate:OnLeave()                           

end



-- AutoFightSect
local PlayerSectRole={}
local AutoFightSectStartTimer = 0 -- 执行每个技能的时间
local AutoFightSectAttackSectTimer = 5 -- 技能释放间隔
local nAttackSectLineCount = 1 --释放技能的次数
local nAttackSectLine = 1 -- 当前技能
local nAutoFightSectCumulativeTime = 0  -- 战斗累计时间
local BtnTargetSelect = false
AutoFightSect = BaseState:New("AutoFightSect")
-- 人物添加的Buff
function PlayerSectRole.AddBuff()
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
function  AutoFightSect:OnEnter()
    -- 战斗前添加初始化buff
    PlayerSectRole.AddBuff()
    AutoFightSectStartTimer = GetTickCount()
end

function AutoFightSect:OnUpdate()
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
        SearchPanel.RunCommand("/gm player.SetPosition("..tbCustom[#tbCustom][1]..","..tbCustom[#tbCustom][2]..","..tbCustom[#tbCustom][3]..")")
        -- 重新添加角色buff
        PlayerSectRole.AddBuff()
        -- 重制回第一个技能
        nAttackSectLine = 1
        -- 重新锁定
        BtnTargetSelect = false
        -- 重启战斗
        nAttackSectLineCount = 1
        AutoFightSectStartTimer = GetTickCount()
    end
    if GetTickCount() - AutoFightSectStartTimer >=  AutoFightSectAttackSectTimer*1000 then
        if not BtnTargetSelect then
            UINodeControl.BtnTrigger("BtnTargetSelect")
            BtnTargetSelect = true
            -- 启动武学助手
            AutoBattle.Start()
        end
        -- 是否遍历完技能
        if nAttackSectLine == 6 then
            nAttackSectLine = 1
        end
        -- 每释放一个技能累计5秒
        nAutoFightSectCumulativeTime = nAutoFightSectCumulativeTime + 5
        -- 超时强杀boss 大于4分钟
        if nAutoFightSectCumulativeTime >= 240  then
            -- 切换下一个锁定
            SearchPanel.RunCommand("/gm if player.GetSelectCharacter() ~= nil then player.GetSelectCharacter().Die() end")
        end
        -- 设置释放技能的坐标
        SkillData.SetCastPointToTargetPos()
        -- 获取技能id
        local nSkillID = UIBattleSkillSlot.GetShowUI_Ver2(nAttackSectLine)
        -- 进行释放
        OnUseSkill(nSkillID, 1)
        SendGMCommand("for i=1,1 do player.GetSelectCharacter().FireAIEvent(2002,0,0) end")
        nAttackSectLineCount = nAttackSectLineCount + 1
        nAttackSectLine = nAttackSectLine + 1
        AutoFightSectStartTimer = GetTickCount()
        -- 至少释放两套技能 再判定是否有问题
        if nAttackSectLineCount >= 7 then
            -- 是否在战斗
            if not GetClientPlayer().bFightState then
                -- 重制回第一个技能
                nAttackSectLine = 1
                nAutoFightSectCumulativeTime = 0
                -- 切换状态
                BtnTargetSelect = false
                SprintData.ToggleViewState()
                nAttackSectLineCount = 1
                -- 重制坐标
                -- 关闭武学助手
                AutoBattle.Stop()
                bCoordinate = false
                -- 结束当前状态
                -- 打完后进行睡眠
                fsm:Switch("SleepSect")
            end
        end
    end
end


function  AutoFightSect:OnLeave()                               
end

-- DialogueSect 对话
local bDialogueSect = false
local nDialogueSectStartTime = 0
local nDialogueSectNextTime = 2
DialogueSect = BaseState:New("DialogueSect")
function  DialogueSect:OnEnter()
    if not bDialogueSect then
        -- 初始化点击 进入人物对话
        Event.Dispatch(EventType.OnSceneInteractByHotkey, false)
        nDialogueSectStartTime = GetTickCount()
    end
end

function  DialogueSect:OnUpdate()
    if GetTickCount()-nDialogueSectStartTime > nDialogueSectNextTime*1000 then
        -- 点击剧情
        Event.Dispatch(EventType.OnSceneInteractByHotkey, true)
        -- 是否有对话框出现
        local bResult = UIMgr.IsViewOpened(VIEW_ID.PanelPlotDialogue)
        if not bResult then
            -- 进入下一个状态
            fsm:Switch("SleepSect")
        end
        nDialogueSectStartTime = GetTickCount()
    end
end

function  DialogueSect:OnLeave()
    bDialogueSect = false
end

-- PlayerMoveSect
local bPlayerMoveSect=false
PlayerMoveSect = BaseState:New("PlayerMoveSect")
function  PlayerMoveSect:OnEnter()
    
end

function  PlayerMoveSect:OnUpdate()
    if not bPlayerMoveSect then
        --开启跑图 并帧更新判断跑图是否结束 将执行CMD的帧更新停止
        CustomRunMapByData.Start(tbSectCustom)
        bPlayerMoveSect = true
        return
    end
    if CustomRunMapByData.IsEnd() then
        -- 重置下次跑图的点数
        CustomRunMapByData.tbRunMapData={}
        fsm:Switch("SleepSect")
    end
end

function  PlayerMoveSect:OnLeave()    
    bPlayerMoveSect = false
end


-- Sleep
local nSleepStartTime = 0
local nSleepCurrentTime=0
SleepSect = BaseState:New("SleepSect")
function  SleepSect:OnEnter()
    -- 进入状态之前现重置睡眠时间
    nSleepCurrentTime = 5 -- 每个操作启动前都要进行等待秒数
    nSleepStartTime=GetTickCount()
end

function  SleepSect:OnUpdate()
    -- 任务流程是否结束
    if nTaskSectLine == #tbTaskSect+1 then
         -- 结束帧函数
        Timer.DelAllTimer(SectTask)
        SectTask.bSwitch = false
     end
    if nTaskStateLine == #tbSectTaskState+1 then
        nTaskSectLine = nTaskSectLine + 1
        -- 重制下个任务参数
        nSectTaskMove = false
        nTaskStateLine = 1
        SectSplitState(nTaskSectLine)
        return
    end
    if GetTickCount()-nSleepStartTime>nSleepCurrentTime*1000 then
        nSleepStartTime=GetTickCount()
        -- 执行人物操作
        if tbSectTaskState[nTaskStateLine] == "Sleep" then
            -- Sleep
            nSleepStartTime=GetTickCount()
            -- 根据表获取睡眠时间
            nSleepCurrentTime = nSleepTime
            nTaskStateLine = nTaskStateLine + 1
        elseif tbSectTaskState[nTaskStateLine] == "Move" then
            fsm:Switch("PlayerMoveSect")
        elseif tbSectTaskState[nTaskStateLine] == "Btn" then
            fsm:Switch("BtnSectOperate")
        elseif tbSectTaskState[nTaskStateLine] == "Dialogue" then
            fsm:Switch("DialogueSect")
        elseif tbSectTaskState[nTaskStateLine] == "Fight" then
            fsm:Switch("AutoFightSect")
        elseif tbSectTaskState[nTaskStateLine] == "FlySkill" then
            fsm:Switch("FlySkill")
        else
            LoginMgr.Log("Status Error")
        end
    end
end

function  SleepSect:OnLeave() 
    nTaskStateLine = nTaskStateLine + 1
end



function SectTask.Start()
    -----创建状态机---------------
    -- 四种状态 移动 战斗 对话 睡眠
    fsm = FsmMachine:New()
    fsm:AddState(AutoFightSect)
    fsm:AddState(DialogueSect)
    fsm:AddState(PlayerMoveSect)
    fsm:AddState(SleepSect)
    fsm:AddState(BtnSectOperate)
    fsm:AddInitState(SectInit)
    Timer.AddFrameCycle(SectTask,1,function ()
        SectTask.FrameUpdate()
    end)
    return true
end


--帧更新函数
function SectTask.FrameUpdate()
    -- 是否从地图加载界面进入了游戏
    if not SearchPanel.IsFromLoadingEnterGame() then
        return
    end
    fsm.curState:OnUpdate()
end

SectTaskStart = {}
SectTaskStart.bSwitch = false
function SectTaskStart.FrameUpdate()
    if not SectTask.bSwitch then
        Timer.DelAllTimer(SectTaskStart)
        StabilityController.bFlag = true
    end
    if SectTaskStart.bSwitch then
        if SectTask.bSwitch then
            -- 启动副本
            SectTask.Start()
            -- 初始化 参数
            SectSplitState(nTaskSectLine)
            SectTaskStart.bSwitch = false
        end
    end
end

Timer.AddCycle(SectTaskStart,1,function ()
    SectTaskStart.FrameUpdate()
end)


LoginMgr.Log("SectTask","SectTask End")

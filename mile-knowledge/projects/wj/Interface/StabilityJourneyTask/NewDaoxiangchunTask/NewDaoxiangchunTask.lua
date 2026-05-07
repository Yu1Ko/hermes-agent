LoginMgr.Log("NewDaoxiangchunTask","NewDaoxiangchunTask imported")
NewDaoxiangchunTask= {} 
NewDaoxiangchunTask.bSwitch=true -- 插件开关
local nSleepTime -- 睡眠时间


-- 读取人物坐标 和 状态操作
local tbTask = {}
local nTaskLine = 2 -- 默认为2
local tbTargetPointTable = {}
for line in io.lines(SearchPanel.szInterfacePath.."StabilityJourneyTask/NewDaoxiangchunTask/RunMapTask.tab") do
    if not string.find(line,"%[") then
        local tData = SearchPanel.StringSplit(line," ")
        table.insert(tbTargetPointTable,tData)
    else
        table.insert(tbTask,tbTargetPointTable)
        tbTargetPointTable = {}
    end
end

-- 分割状态
local tbCustom = {}
local tbCoordinate = {}
local tbTaskState = {}  -- 获取状态表
local nTaskStateLine = 1
local nTaskMove = false
local szBtnCmd -- 特殊操作的语句
function SplitState(nLine)
    tbTaskState = {}
    tbCustom = {}
    tbCoordinate = {}
    for _, value in pairs(tbTask[nLine]) do
        for _, v in pairs(value) do
            if not string.find(v,"x") then
                if not string.find(v,"Btn") and not string.find(v,"Sleep") and not string.find(v,"Dialogue") and not string.find(v,"Fight") and not string.find(v,"FlySkill") then
                    local coordinate = SearchPanel.StringSplit(v,"%s")
                    tbCoordinate = {
                        coordinate[1],
                        coordinate[2],
                        coordinate[3], 
                    }
                    table.insert(tbCustom,tbCoordinate)
                    if not nTaskMove then
                        table.insert(tbTaskState,"Move")
                        nTaskMove = true
                    end
                else
                    if string.find(v,"Sleep") then
                        table.insert(tbTaskState,"Sleep")
                        nSleepTime = tonumber(v:sub(7))
                    elseif string.find(v,"Dialogue") then
                        table.insert(tbTaskState,"Dialogue")
                    elseif string.find(v,"Fight") then
                        table.insert(tbTaskState,"Fight")
                    elseif string.find(v,"Btn") then
                        table.insert(tbTaskState,"Btn")
                        szBtnCmd = v:sub(5)
                    elseif string.find(v,"FlySkill") then
                        table.insert(tbTaskState,"FlySkill")
                    else
                        print("Read Error")
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
        end
        local CMD = "/cmd "..szBtnCmd
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
local AutoFightAttackTimer = 2 -- 技能释放间隔
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
                -- 结束当前状态
                -- 打完后进行睡眠
                fsm:Switch("Sleep")
            end
        end
    end
end


function  AutoFight:OnLeave()                               
end

-- 使用轻功为特殊状态 无论是否轻功飞过目标点在最后都 强制位移坐标
local nFlySkillTime = 1 -- 每隔2秒跳跃一次
local nFlySkillStartTime = 0
local bFlySkill =false
local nFlySkill_x =56927
local nFlySkill_y =50266
local nFlySkill_z = 1052480
local bFlySkilJump =false
local nFlySkillLine = 1 -- 轻功的段数
local FlySkill = BaseState:New("FlySkill")

-- 控制轻功接口
local function FlySkillStart()
    SearchPanel.MyExecuteScriptCommand("FuncSlotMgr.tbCommands.StartSprint()")
end

local function FlySkillStop()
    SearchPanel.MyExecuteScriptCommand("FuncSlotMgr.tbCommands.EndSprint()")
end

local function FlySkillJump()
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
local nDialogueNextTime = 1
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
        CustomRunMapByData.Start(tbCustom)
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
    nSleepCurrentTime = 3 -- 每个操作启动前都要进行等待秒数
    nSleepStartTime=GetTickCount()
end

function  Sleep:OnUpdate()
    -- 任务流程是否结束
    if nTaskLine == #tbTask+2 then
         -- 结束帧函数
        Timer.DelAllTimer(NewDaoxiangchunTask)
        NewDaoxiangchunTask.bSwitch = false
     end
    if nTaskStateLine == #tbTaskState+1 then
        nTaskLine = nTaskLine + 1
        -- 重制下个任务参数
        nTaskMove = false
        nTaskStateLine = 1
        SplitState(nTaskLine)
        return
    end
    if GetTickCount()-nSleepStartTime>nSleepCurrentTime*1000 then
        nSleepStartTime=GetTickCount()
        -- 执行人物操作
        if tbTaskState[nTaskStateLine] == "Sleep" then
            -- Sleep
            nSleepStartTime=GetTickCount()
            -- 根据表获取睡眠时间
            nSleepCurrentTime = nSleepTime
            nTaskStateLine = nTaskStateLine + 1
        elseif tbTaskState[nTaskStateLine] == "Move" then
            fsm:Switch("PlayerMove")
        elseif tbTaskState[nTaskStateLine] == "Btn" then
            fsm:Switch("BtnOperate")
        elseif tbTaskState[nTaskStateLine] == "Dialogue" then
            fsm:Switch("Dialogue")
        elseif tbTaskState[nTaskStateLine] == "Fight" then
            fsm:Switch("AutoFight")
        elseif tbTaskState[nTaskStateLine] == "FlySkill" then
            fsm:Switch("FlySkill")
        else
            LoginMgr.Log("Status Error")
        end
    end
end

function  Sleep:OnLeave() 
    nTaskStateLine = nTaskStateLine + 1
end



function NewDaoxiangchunTask.Start()
    -----创建状态机---------------
    -- 四种状态 移动 战斗 对话 睡眠
    fsm = FsmMachine:New()
    fsm:AddState(AutoFight)
    fsm:AddState(Dialogue)
    fsm:AddState(PlayerMove)
    fsm:AddState(Sleep)
    fsm:AddState(FlySkill)
    fsm:AddState(BtnOperate)
    fsm:AddInitState(Init)
    Timer.AddFrameCycle(NewDaoxiangchunTask,1,function ()
        NewDaoxiangchunTask.FrameUpdate()
    end)
    return true
end


-- 是否从地图加载界面进入了游戏
local function IsFromLoadingEnterGame2()
    local player = GetClientPlayer()
    if player then
        local bOpened =  UIMgr.IsViewOpened(VIEW_ID.PanelLoading)
        if not bOpened then
            return true
        end
        return false
    end
    return false
end


--帧更新函数
function NewDaoxiangchunTask.FrameUpdate()
    -- 是否从地图加载界面进入了游戏
    if not IsFromLoadingEnterGame2() then
        return
    end
    fsm.curState:OnUpdate()
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
        if UIMgr.IsViewOpened(VIEW_ID.PanelVideoPlayer) then
            bVideo = true
            nVideoStartTimer = GetTickCount()
            bVideoStart = false
            return
        end
    end
    if bVideo then
        if GetTickCount()- nVideoStartTimer >= nVideoTimer*1000 then
            UIMgr.Close(VIEW_ID.PanelVideoPlayer)
            bVideo = false
            bVideoStart = true
        end
    end
end
Timer.AddCycle(tbVideoPlayer,1,function ()
    tbVideoPlayer.FrameUpdate()
end)

-- 弹窗关闭
--[[]]
local ClosePanel = {}
function ClosePanel.FrameUpdate()
    if UIMgr.IsViewOpened(VIEW_ID.PanelBenefits) then
        UIMgr.Close(VIEW_ID.PanelBenefits)
    end
    if UIMgr.IsViewOpened(VIEW_ID.PanelHotSpotBanner) then
        UIMgr.Close(VIEW_ID.PanelHotSpotBanner)
    end
end
Timer.AddCycle(ClosePanel,1,function ()
    ClosePanel.FrameUpdate()
end)


-- 穿戴装备
-- 装备触发后进行穿戴
-- local _EquipTips = TipsHelper.ShowQuickEquipTip
-- function EquipTips(dwBox, dwX)
--     _EquipTips(dwBox, dwX)
--     UIMgr.Close(VIEW_ID.PanelHint)
-- end
-- TipsHelper.ShowQuickEquipTip=EquipTips


NewDaoxiangchunTaskStart = {}
NewDaoxiangchunTaskStart.bSwitch = false
function NewDaoxiangchunTaskStart.FrameUpdate()
    if not NewDaoxiangchunTask.bSwitch then
        -- 关闭帧函数
        Timer.DelAllTimer(ClosePanel)
        Timer.DelAllTimer(tbVideoPlayer)
        Timer.DelAllTimer(NewDaoxiangchunTaskStart)
        StabilityController.bFlag = true
    end
    if NewDaoxiangchunTaskStart.bSwitch then
        if NewDaoxiangchunTask.bSwitch then
            -- 启动副本
            NewDaoxiangchunTask.Start()
            -- 初始化 参数
            SplitState(nTaskLine)
            TeachEvent.CloseAllTeach()
            NewDaoxiangchunTaskStart.bSwitch = false
        end
    end
end

Timer.AddCycle(NewDaoxiangchunTaskStart,1,function ()
    NewDaoxiangchunTaskStart.FrameUpdate()
end)

LoginMgr.Log("NewDaoxiangchunTask","NewDaoxiangchunTask End")

LoginMgr.Log("DesertJourneyTask","DesertJourneyTask imported")

-- 大漠之旅任务测试：纯阳成男 → GM120级 → 河西瀚漠 → 按历程完成任务
-- 约束：不穿戴外装、不使用疾跑和轻功、历程中穿戴获得装备、25分钟停止

DesertJourneyTask = {}
DesertJourneyTask.bSwitch = true
local RunMap = {}
local nSleepTime
local list_RunMapCMD = {}
local list_RunMapTime = {}

-- 设置角色：纯阳 + 成男
SearchPanel.tbModule['AutoLogin'].SetAutoLoginInfo(nil, nil, '纯阳', '成男')

-- 读取 RunMap.tab（GM指令序列）
local tbRunMapData = SearchPanel.LoadRunMapFile(SearchPanel.szCurrentInterfacePath .. "RunMap.tab", 2)
list_RunMapCMD = tbRunMapData[1]
list_RunMapTime = tbRunMapData[2]
local bFlag = true

-- 读取 RunMapTask.tab（坐标 + 状态标记）
local tbTask = {}
local nTaskLine = 2
local tbTargetPointTable = {}
for line in io.lines(SearchPanel.szCurrentInterfacePath .. "RunMapTask.tab") do
    if not string.find(line, "%[") then
        local tData = SearchPanel.StringSplit(line, "\t")
        table.insert(tbTargetPointTable, tData)
    else
        table.insert(tbTask, tbTargetPointTable)
        tbTargetPointTable = {}
    end
end

-- 状态解析：区分 Move / Dialogue / Fight / Sleep
local tbCustom = {}
local tbCoordinate = {}
local tbTaskState = {}
local nTaskStateLine = 1
local nTaskMove = false

function SplitState(nLine)
    tbTaskState = {}
    tbCustom = {}
    tbCoordinate = {}
    for _, value in pairs(tbTask[nLine]) do
        local v = value[1]
        if v then
            if string.find(v, "Sleep") then
                table.insert(tbTaskState, "Sleep")
                nSleepTime = tonumber(v:sub(7))
            elseif string.find(v, "Dialogue") then
                table.insert(tbTaskState, "Dialogue")
            elseif string.find(v, "Fight") then
                table.insert(tbTaskState, "Fight")
            elseif string.find(v, "FlySkill") then
                -- 本用例禁止轻功，但保留解析能力以防 RunMapTask.tab 误写
                table.insert(tbTaskState, "FlySkill")
            elseif not string.find(v, "x") then
                local coordinate = SearchPanel.StringSplit(v, "\t")
                tbCoordinate = {
                    coordinate[1],
                    coordinate[2],
                    coordinate[3],
                }
                table.insert(tbCustom, tbCoordinate)
                if not nTaskMove then
                    table.insert(tbTaskState, "Move")
                    nTaskMove = true
                end
            end
        end
    end
end

-- ============================================================
-- 25 分钟超时控制
-- ============================================================
local nMaxDuration = 25 * 60 * 1000  -- 25 分钟（毫秒）
local nTaskStartTime = 0
local bTimeout = false

-- ============================================================
-- 自动穿戴装备 Hook
-- ============================================================
local _EquipTips = TipsHelper.ShowQuickEquipTip
function EquipTips(dwBox, dwX)
    _EquipTips(dwBox, dwX)
    ItemData.EquipItem(dwBox, dwX)
    UIMgr.Close(VIEW_ID.PanelHint)
end
TipsHelper.ShowQuickEquipTip = EquipTips

-- ============================================================
-- 状态机定义
-- ============================================================

----- Init -----
Init = BaseState:New("Init")
function Init:OnEnter() end
function Init:OnUpdate()
    fsm:Switch("Sleep")
end
function Init:OnLeave() end

----- Dialogue -----
local bDialogue = false
local nDialogueStartTime = 0
local nDialogueNextTime = 2
Dialogue = BaseState:New("Dialogue")
function Dialogue:OnEnter()
    if not bDialogue then
        Event.Dispatch(EventType.OnSceneInteractByHotkey, false)
        nDialogueStartTime = GetTickCount()
    end
end
function Dialogue:OnUpdate()
    if GetTickCount() - nDialogueStartTime > nDialogueNextTime * 1000 then
        Event.Dispatch(EventType.OnSceneInteractByHotkey, true)
        local bResult = UIMgr.IsViewOpened(VIEW_ID.PanelPlotDialogue)
        if not bResult then
            fsm:Switch("Sleep")
        end
        nDialogueStartTime = GetTickCount()
    end
end
function Dialogue:OnLeave()
    bDialogue = false
end

----- AutoFight -----
local AutoFightStartTimer = 0
local AutoFightAttackTimer = 5
local nAttackLineCount = 1
local BtnTargetSelect = false
AutoFight = BaseState:New("AutoFight")

function AutoFight:OnEnter()
    -- 无敌 + 伤害加成
    SearchPanel.RunCommand("/gm player.nPhysicsReflection=10000000")
    SearchPanel.RunCommand("/gm player.AddBuff(player.dwID,player.nLevel,203,1,3600)")
    SearchPanel.RunCommand("/gm for i=1,20 do player.AddBuff(player.dwID,player.nLevel,5235,1,1) end")
    SearchPanel.RunCommand("/gm player.nLifeReplenishExt=100000000;player.nManaReplenishExt=100000")
    -- 确保是技能面板（不是轻功面板）
    if SprintData.GetViewState() then
        SprintData.ToggleViewState()
    end
    AutoFightStartTimer = GetTickCount()
end

function AutoFight:OnUpdate()
    local player = GetClientPlayer()
    if not player then return end

    if GetTickCount() - AutoFightStartTimer >= AutoFightAttackTimer * 1000 then
        if not BtnTargetSelect then
            UINodeControl.BtnTrigger("BtnTargetSelect")
            BtnTargetSelect = true
            AutoBattle.Start()
        end
        if nAttackLineCount == 6 then
            nAttackLineCount = 1
        end
        SkillData.SetCastPointToTargetPos()
        local nSkillID = UIBattleSkillSlot.GetShowUI_Ver2(nAttackLineCount)
        OnUseSkill(nSkillID, 1)
        nAttackLineCount = nAttackLineCount + 1
        AutoFightStartTimer = GetTickCount()

        -- 至少两套技能后判定战斗是否结束
        if nAttackLineCount >= 7 then
            if not GetClientPlayer().bFightState then
                nAttackLineCount = 1
                BtnTargetSelect = false
                SprintData.ToggleViewState()
                AutoBattle.Stop()
                fsm:Switch("Sleep")
            end
        end
    end
end
function AutoFight:OnLeave() end

----- PlayerMove（仅常规跑/跳，禁止疾跑和轻功） -----
local bPlayerMove = false
PlayerMove = BaseState:New("PlayerMove")
function PlayerMove:OnEnter() end
function PlayerMove:OnUpdate()
    if not bPlayerMove then
        CustomRunMapByData.Start(tbCustom)
        bPlayerMove = true
        return
    end
    if CustomRunMapByData.IsEnd() then
        CustomRunMapByData.tbRunMapData = {}
        fsm:Switch("Sleep")
    end
end
function PlayerMove:OnLeave()
    bPlayerMove = false
end

----- Sleep -----
local nSleepStartTime = 0
local nSleepCurrentTime = 0
Sleep = BaseState:New("Sleep")
function Sleep:OnEnter()
    nSleepCurrentTime = 5
    nSleepStartTime = GetTickCount()
end
function Sleep:OnUpdate()
    -- 25 分钟超时检查
    if GetTickCount() - nTaskStartTime > nMaxDuration then
        bTimeout = true
        bFlag = true  -- 回到主循环，触发 ExportGame
        Timer.DelAllTimer(DesertJourneyTask)
        SearchPanel.RunCommand("/cmd CreateEmptyFile(\"ExportGame\")")
        return
    end

    -- 任务流程结束
    if nTaskLine == #tbTask + 2 then
        Timer.DelAllTimer(DesertJourneyTask)
        bFlag = true
        return
    end

    if nTaskStateLine == #tbTaskState + 1 then
        nTaskLine = nTaskLine + 1
        nTaskMove = false
        nTaskStateLine = 1
        SplitState(nTaskLine)
        return
    end

    if GetTickCount() - nSleepStartTime > nSleepCurrentTime * 1000 then
        nSleepStartTime = GetTickCount()
        if tbTaskState[nTaskStateLine] == "Sleep" then
            nSleepCurrentTime = nSleepTime or 5
            nTaskStateLine = nTaskStateLine + 1
        elseif tbTaskState[nTaskStateLine] == "Move" then
            fsm:Switch("PlayerMove")
        elseif tbTaskState[nTaskStateLine] == "Dialogue" then
            fsm:Switch("Dialogue")
        elseif tbTaskState[nTaskStateLine] == "Fight" then
            fsm:Switch("AutoFight")
        elseif tbTaskState[nTaskStateLine] == "FlySkill" then
            -- 本用例禁止轻功——如果 RunMapTask.tab 误写了 FlySkill，直接跳过
            nTaskStateLine = nTaskStateLine + 1
        else
            LoginMgr.Log("DesertJourneyTask", "Status Error")
        end
    end
end
function Sleep:OnLeave()
    nTaskStateLine = nTaskStateLine + 1
end

-- ============================================================
-- 任务启动
-- ============================================================
function DesertJourneyTask.Start()
    fsm = FsmMachine:New()
    fsm:AddState(AutoFight)
    fsm:AddState(Dialogue)
    fsm:AddState(PlayerMove)
    fsm:AddState(Sleep)
    fsm:AddInitState(Init)
    SplitState(nTaskLine)
    nTaskStartTime = GetTickCount()
    Timer.AddFrameCycle(DesertJourneyTask, 1, function()
        DesertJourneyTask.FrameUpdate()
    end)
    return true
end

-- ============================================================
-- 帧更新
-- ============================================================
function DesertJourneyTask.FrameUpdate()
    if not SearchPanel.IsFromLoadingEnterGame() then
        return
    end
    fsm.curState:OnUpdate()
end

-- ============================================================
-- UpdateTask 命令执行循环
-- ============================================================
local pCurrentTime = 0
local nNextTime = tonumber(20)
local nCurrentStep = 1

function FrameUpdate()
    local player = GetClientPlayer()
    if not player then return end
    if not SearchPanel.IsFromLoadingEnterGame() then return end

    if bFlag and GetTickCount() - pCurrentTime > nNextTime * 1000 then
        if nCurrentStep == #list_RunMapCMD then
            bFlag = false
        end
        local szCmd = list_RunMapCMD[nCurrentStep]
        local nTime = tonumber(list_RunMapTime[nCurrentStep])
        pcall(function()
            SearchPanel.RunCommand(szCmd)
        end)
        nNextTime = nTime

        if string.find(szCmd, "DesertJourneyTask") then
            DesertJourneyTask.Start()
            bFlag = false
        end
        if string.find(szCmd, "perfeye_start") then
            SearchPanel.bPerfeye_Start = true
        end
        if string.find(szCmd, "perfeye_stop") then
            SearchPanel.bPerfeye_Stop = true
        end
        pCurrentTime = GetTickCount()
        nCurrentStep = nCurrentStep + 1
    end
end

Timer.AddFrameCycle(RunMap, 1, function()
    FrameUpdate()
end)

-- ============================================================
-- 新手教学弹窗自动关闭
-- ============================================================
local CloseTeach = {}
function CloseTeach.FrameUpdate()
    if UIMgr.IsViewOpened(VIEW_ID.PanelTeach_UIMainLayer) then
        TeachEvent.TeachClose(1304)
    end
    if UIMgr.IsViewOpened(VIEW_ID.PanelNormalConfirmation) then
        UINodeControl.BtnTrigger("BtnOk")
    end
end
Timer.AddCycle(CloseTeach, 10, function()
    CloseTeach.FrameUpdate()
end)

LoginMgr.Log("DesertJourneyTask", "DesertJourneyTask loaded")

return DesertJourneyTask

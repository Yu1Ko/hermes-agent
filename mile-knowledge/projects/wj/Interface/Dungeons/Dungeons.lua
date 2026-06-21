LoginMgr.Log("Dungeons","Dungeons imported")
Dungeons = {}
DungeonApi = {} -- 用于开放接口
local RunMap = {}
local szKeyGM -- 流程状态gm语句
local nSleepTime -- 睡眠时间
local list_RunMapCMD = {}
local list_RunMapTime = {}
DungeonApi.szMapName = nil -- 副本名字

-- 机器人跑动
local RobotCustom = {}
RobotCustom.bSwitch = false -- 跑动机器人默认开启
local AutoFightCount = 1
-- 机器人跑动开关接口
function DungeonApi.SetRobotCustomSwitch(nSwitch)
    local nRobotCustomCount = tonumber(nSwitch)
    if nRobotCustomCount == 1 then
        RobotCustom.bSwitch = false
    end
end
--  设置副本名称
function DungeonApi.SetMapName(szMapName)
    DungeonApi.szMapName = szMapName
end
-- 设置boss
function DungeonApi.SetAutoFightCount(nAutoFightCount)
    AutoFightCount = tonumber(nAutoFightCount)
end

--读取tab的内容
local tbRunMapData=SearchPanel.LoadRunMapFile(SearchPanel.szCurrentInterfacePath.."RunMap.tab",2)
list_RunMapCMD = tbRunMapData[1]
list_RunMapTime = tbRunMapData[2]
local bFlag = true

-- 读取人物坐标 和 状态操作
local tbTask = {}
local nTaskLine = 2 -- 默认为2
local tbTargetPointTable = {}
for line in io.lines(SearchPanel.szCurrentInterfacePath.."RunMapTask.tab") do
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
local tbTaskState = {}
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
                if not string.find(v,"NpcDie") and not string.find(v,"Btn") and not string.find(v,"SpecialGM") and not string.find(v,"Sleep") and not string.find(v,"Dialogue") and not string.find(v,"Fight") and not string.find(v,"FlowGM") then
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
                    if string.find(v,"Btn") then
                        table.insert(tbTaskState,"Btn")
                        szBtnCmd = v:sub(5)
                    elseif string.find(v,"Sleep") then
                        table.insert(tbTaskState,"Sleep")
                        nSleepTime = tonumber(v:sub(7))
                    elseif string.find(v,"Dialogue") then
                        table.insert(tbTaskState,"Dialogue")
                    elseif string.find(v,"Fight") then
                        table.insert(tbTaskState,"Fight")
                    elseif string.find(v,"FlowGM") then
                        szKeyGM = v:sub(8)
                        table.insert(tbTaskState,"FlowGM")
                    elseif string.find(v,"NpcDie") then
                        table.insert(tbTaskState,"NpcDie")
                        szKeyGM = v:sub(8)
                        PlayerAuto.nNpcDieTimeCount=tonumber(szKeyGM)
                    else
                        print("Read Error")
                    end
                end
            end
        end
    end
end

local nFlowEnd = #tbTask+1
-- 指定boss的接口
function DungeonApi.Specifyboss(nBossStart,nBossEnd)
    nTaskLine = nBossStart
    nFlowEnd = nBossEnd
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

-- AutoFight
AutoFight = BaseState:New("AutoFight")
local AutoFightFlag = false

function  AutoFight:OnEnter()

end

function AutoFight:OnUpdate()
    if not AutoFightFlag then
        -- 设置副本boss 获取对应buff
        PlayerAutoBufforGM.SetBossBuff(DungeonApi.szMapName,AutoFightCount)
        PlayerAuto.StartAutoFight()
        AutoFightFlag = true
        return
    end
    -- 是否在战斗
    if not PlayerAuto.IsAuto() then
        fsm:Switch("Sleep")
    end
end


function  AutoFight:OnLeave()
    AutoFightFlag = false
    AutoFightCount = AutoFightCount + 1
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
        -- 是否启动机器人跑图
        if RobotCustom.bSwitch then
            Timer.AddCycle(RobotCustom,1,function ()
                RobotCustom.FrameUpdate()
            end)
        end
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
    -- 关闭机器人跑图
    Timer.DelAllTimer(RobotCustom)
end

-- 特殊流程GM操作
local nflowGMStartTime = 0
local nflowGMNextTime = 5
local bflowGM = false
FlowGM = BaseState:New("FlowGM")
function  FlowGM:OnEnter()
    
end

function  FlowGM:OnUpdate()
    if GetTickCount()-nflowGMStartTime >= nflowGMNextTime*1000 then
        if bflowGM then
            bflowGM = false
            fsm:Switch("Sleep")
            return
        end
        local szflowGM = "/gm "..szKeyGM
        SearchPanel.RunCommand(szflowGM)
        bflowGM = true
        BtnStartTime = GetTickCount()
    end
end

function  FlowGM:OnLeave()    
   
end


-- 特殊按钮操作
BtnOperate = BaseState:New("BtnOperate")
local BtnStartTime = 0
local BtnNextTime = 5
local bBtnOperate = false
function  BtnOperate:OnEnter()
    BtnStartTime = GetTickCount()
end

function  BtnOperate:OnUpdate()
    if GetTickCount()-BtnStartTime >= BtnNextTime*1000 then
        if bBtnOperate then
            bBtnOperate= false
            fsm:Switch("Sleep")
            return
        end
        local CMD = "/cmd "..szBtnCmd
        SearchPanel.RunCommand(CMD)
        bBtnOperate = true
        BtnStartTime = GetTickCount()
    end
end

function  BtnOperate:OnLeave()                           

end


-- Dialogue 
local bDialogue = false
local nDialogueStartTime = 0
local nDialogueNextTime = 2
Dialogue = BaseState:New("Dialogue")
function  Dialogue:OnEnter()
    if not bDialogue then
        -- 初始化点击 进入人物对话
        UINodeControl.BtnTrigger("BtnInteractive","WidgetInteractive")
        nDialogueStartTime = GetTickCount()
    end
end

function  Dialogue:OnUpdate()
    if GetTickCount()-nDialogueStartTime > nDialogueNextTime*1000 then
        -- 点击进入按钮
        UINodeControl.BtnTrigger("BtnDialogue","WidgetDialogueCell")
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

-- Sleep
local nSleepStartTime = 0
local nSleepCurrentTime=0
local bDelBossStart = false
Sleep = BaseState:New("Sleep")
function  Sleep:OnEnter()
    -- 进入状态之前现重置睡眠时间
    nSleepCurrentTime = 5
    nSleepStartTime=GetTickCount()
end

function  Sleep:OnUpdate()
    -- 任务流程是否结束
    if nTaskLine == nFlowEnd then
        -- 结束帧函数
        Timer.DelAllTimer(Dungeons)
        bFlag = true
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
        AutoTestLog.Log("Dungeons nTaskLine:",tostring(nTaskLine))
        AutoTestLog.Log("Dungeons Status:",tostring(tbTaskState[nTaskStateLine]))
       
        nSleepStartTime=GetTickCount()
        -- 执行人物操作
        -- 暂时移除
        -- if tbTaskState[nTaskStateLine] == "SpecialGM" then
        --     -- 特殊操作
        --     nTaskStateLine = nTaskStateLine + 1
        -- end
        if tbTaskState[nTaskStateLine] == "Sleep" then
            -- Sleep
            nSleepStartTime=GetTickCount()
            -- 根据表获取睡眠时间
            nSleepCurrentTime = nSleepTime
            nTaskStateLine = nTaskStateLine + 1
        elseif tbTaskState[nTaskStateLine] == "Btn" then
            fsm:Switch("BtnOperate")
        elseif tbTaskState[nTaskStateLine] == "Move" then
            fsm:Switch("PlayerMove")
        elseif tbTaskState[nTaskStateLine] == "Dialogue" then
            fsm:Switch("Dialogue")
        elseif tbTaskState[nTaskStateLine] == "Fight" then
            fsm:Switch("AutoFight")
        elseif tbTaskState[nTaskStateLine] == "FlowGM" then
            fsm:Switch("FlowGM")
        elseif tbTaskState[nTaskStateLine] == "NpcDie" then
            -- 设置npc召唤物强杀
            PlayerAuto.bNpcIdDie = true
            nTaskStateLine = nTaskStateLine + 1
        else
            LoginMgr.Log("Status Error")
        end
    end
end

function  Sleep:OnLeave()    
    nTaskStateLine = nTaskStateLine + 1
end



function Dungeons.Start()
    -----创建状态机---------------
    -- 六种状态 移动 战斗 对话 睡眠 战斗使用特殊gm 流程Gm操作
    fsm = FsmMachine:New()
    fsm:AddState(AutoFight)
    fsm:AddState(Dialogue)
    fsm:AddState(PlayerMove)
    fsm:AddState(BtnOperate)
    fsm:AddState(Sleep)
    fsm:AddState(FlowGM)
    fsm:AddInitState(Init)
    Timer.AddFrameCycle(Dungeons,1,function ()
        Dungeons.FrameUpdate()
    end)
    return true
end


--帧更新函数
function Dungeons.FrameUpdate()
    -- 是否从地图加载界面进入了游戏
    if not SearchPanel.IsFromLoadingEnterGame() then
        return
    end
    fsm.curState:OnUpdate()
end

-- 副本关闭弹窗
local DungeonsCloseView = {}
DungeonsCloseView.VIEW_ID = {
    VIEW_ID.PanelQingGongModePop,
    VIEW_ID.PanelNormalConfirmation,
    VIEW_ID.PanelBlackScreen,
    VIEW_ID.PanelChatSocial,
    VIEW_ID.PanelSkillRecommend,
    VIEW_ID.PanelDungeonPersonalCardSettle
}

-- 特殊处理 轻功的弹窗 暂定
function DungeonsCloseView.FrameUpdate()
    for _, value in pairs(DungeonsCloseView.VIEW_ID) do
        if UIMgr.IsViewOpened(value) then
            -- 关闭弹窗
            UIMgr.Close(value)
        end
    end
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
    if TbSwitchMap.IsRun then
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
            -- 启动副本
            Dungeons.Start()
            -- 初始化 参数
            SplitState(nTaskLine)
            -- 每1秒执行一次
            Timer.AddCycle(DungeonsCloseView,1,function ()
                DungeonsCloseView.FrameUpdate()
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

Timer.AddFrameCycle(RunMap,1,function ()
    FrameUpdate()
end)

-- 视频播放时间
--[[]]
local tbVideoPlayer = {}
local nVideoTimer = 5  -- 视频播放时间
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


-- 机器人跑图召唤
function RobotCustom.FrameUpdate()
    -- 是否在跑图
    if bPlayerMove then
        -- 机器人召唤
        RobotControl.CMD("TeleportRobot")
        local player=GetClientPlayer()
        if player.nMoveState == 16 then
            -- 自身复活
            SearchPanel.RunCommand("/gm player.Revive()")
        end
    end
end

LoginMgr.Log("Dungeons","Dungeons End")
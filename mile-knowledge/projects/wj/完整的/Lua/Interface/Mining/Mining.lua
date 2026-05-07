Mining = {}
RunMap={}
local bFlag =true
-----init----------------
local Init = BaseState:New("Init")
function Init:OnEnter()

end

function Init:OnUpdate()
    fsm:Switch("AutoFight")
end

function Init:OnLeave()                               

end


local AutoFight = BaseState:New("AutoFight")

-- 每过两分钟就传送到下个位置挖矿
local OrePos = {
    "player.SetPosition(12158,41807,1317120)",
    "player.SetPosition(6647,39551,1315712)",
    "player.SetPosition(1488,34999,1303808)",
    "player.SetPosition(4828,29815,1313472)",
}
local nStartTime = 0
local nNextTime = 120
local nPosLine = 1
local nTargetNextTime = 15
local nTargetStartTime = 0
function AutoFight:OnEnter()

end
local nAttackLine = 1
function AutoFight:OnUpdate()
    if GetTickCount()-nStartTime>= nNextTime*1000 then
        if nPosLine == #OrePos+1 then
            Timer.DelAllTimer(Mining)
            bFlag = true
        end
        SendGMCommand(OrePos[nPosLine])
        nStartTime= GetTickCount()
        local PlayerState = SprintData.GetViewState()
        -- 如果为技能面板则不切换
        if PlayerState then
            SprintData.ToggleViewState()
        end
        AutoBattle.Start()
        nPosLine = nPosLine + 1
        return
    end
    SearchPanel.RunCommand("/gm player.AddBuff(player.dwID,player.nLevel,203,1,3600)")
    if nAttackLine == 6 then
        nAttackLine = 1
    end
    nAttackLine = nAttackLine + 1
    local nSkillID = UIBattleSkillSlot.GetShowUI_Ver2(nAttackLine);
    OnUseSkill(nSkillID, 1)
    if GetTickCount()-nTargetStartTime>= nTargetNextTime*1000 then
        TargetMgr.TrySelectOneTarget()
        TargetMgr.Attention(true)
        TargetMgr.SearchNextTarget()
        nTargetStartTime = GetTickCount()
    end
end

function AutoFight:OnLeave()

end


function Mining.FrameUpdate()
    if not SearchPanel.IsFromLoadingEnterGame() then
        return
    end
    fsm.curState:OnUpdate()
end



function Mining.Start()
    fsm = FsmMachine:New()
    fsm:AddState(AutoFight)
    fsm:AddInitState(Init)
    Timer.AddCycle(PlayerAutoDie,1,function ()
        PlayerAutoDie.FrameUpdate()
    end)
    Timer.AddCycle(Mining,1,function ()
        Mining.FrameUpdate()
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
        if string.find(szCmd,"Mining_start") then
            --启动切图帧更新函数
            Mining.Start()
            bFlag = false
        end
		nCurrentTime=GetTickCount()
        nCurrentStep=nCurrentStep+1 
    end
end

Timer.AddFrameCycle(RunMap,1,function ()
    RunMap.FrameUpdate()
end)
CloakSociety = {}
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

-- 3分钟过后打斗结束
local nStartTime = 0
local nNextTime = 180
local nTargetNextTime = 15
local nTargetStartTime = 0
function AutoFight:OnEnter()
    nStartTime =GetTickCount()
end
local nAttackLine = 1
function AutoFight:OnUpdate()
    if GetTickCount()-nStartTime>= nNextTime*1000 then
        Timer.DelAllTimer(CloakSociety)
        bFlag = true
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


function CloakSociety.FrameUpdate()
    if not SearchPanel.IsFromLoadingEnterGame() then
        return
    end
    fsm.curState:OnUpdate()
end



function CloakSociety.Start()
    fsm = FsmMachine:New()
    fsm:AddState(AutoFight)
    fsm:AddInitState(Init)
    Timer.AddCycle(CloakSociety,10,function ()
        CloakSociety.FrameUpdate()
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
        if string.find(szCmd,"CloakSociety_start") then
            --启动切图帧更新函数
            CloakSociety.Start()
            bFlag = false
        end
		nCurrentTime=GetTickCount()
        nCurrentStep=nCurrentStep+1 
    end
end

Timer.AddFrameCycle(RunMap,1,function ()
    RunMap.FrameUpdate()
end)
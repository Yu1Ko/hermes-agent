LoginMgr.Log("WorldBoss","WorldBoss imported")
WorldBoss = {}
WorldBoss.bSwitch = true
PlayerRole = {}
RunMap = {}
--读取tab的内容
local list_RunMapCMD = {}
local list_RunMapTime = {}
local tbRunMapData=SearchPanel.LoadRunMapFile(SearchPanel.szCurrentInterfacePath.."RunMap.tab",2)
list_RunMapCMD = tbRunMapData[1]
list_RunMapTime = tbRunMapData[2]
local bFlag = true
-- 设置人物登录
SearchPanel.tbModule['AutoLogin'].SetAutoLoginInfo(nil,RandomString(8),'纯阳','成男')

-----init----------------
Init = BaseState:New("Init")
function  Init:OnEnter()

end

function  Init:OnUpdate()
    fsm:Switch("AutoFight")
end

function  Init:OnLeave()                               

end

function WorldBoss.FrameUpdate()
    if not WorldBoss.bSwitch then
        return
    end
    fsm.curState:OnUpdate()
end


-- AutoFight
local AutoFightStartTimer = 0 -- 执行每个技能的时间
local AutoFightAttackTimer = 5 -- 技能释放间隔
local nAttackLineCount = 1 --释放技能的次数
local nAttackLine = 1 -- 当前技能
local nAutoFightCumulativeTime = 0  -- 战斗累计时间
local BtnTargetSelect = false
AutoFight = BaseState:New("AutoFight")
-- 人物添加的Buff
function PlayerRole.AddBuff()
    -- 开启无敌 
    SearchPanel.RunCommand("/gm player.AddBuff(player.dwID,player.nLevel,203,1,3600)")
    -- Ap命中加成
    SearchPanel.RunCommand("/gm for i=1,20 do player.AddBuff(player.dwID,player.nLevel,5235,1,1) end")
    -- 加强回血回蓝
    SearchPanel.RunCommand("/gm player.nLifeReplenishExt=100000000;player.nManaReplenishExt=100000")
    -- 超级血量buff
    local GM = "for i=1,50 do player.AddBuff(0,99,4136,1,7200) end;player.".._G.CurLife.."=player.".._G.MaxLife
    SearchPanel.RunCommand("/gm "..GM)
    -- Ap命中加成
    SearchPanel.RunCommand("/gm for i=1,20 do player.AddBuff(player.dwID,player.nLevel,5235,1,1) end")
    -- 提高攻击
    SearchPanel.RunCommand("/gm player.nPhysicsAttackPower=2000;player.nSolarAttackPower=200000;player.nNeutralAttackPower=200000;player.nLunarAttackPower=200000;player.nPoisonAttackPower=200000")
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
    -- 防止人物死亡被秒杀不死buff
    SearchPanel.RunCommand("/gm player.AddBuff(player.dwID,player.nLevel,203,1,3600)")
    if GetTickCount() - AutoFightStartTimer >=  AutoFightAttackTimer*1000 then
        if not BtnTargetSelect then
            UINodeControl.BtnTrigger("BtnTargetSelect")
            BtnTargetSelect = true
        end
        -- 是否遍历完技能
        if nAttackLine == 6 then
            nAttackLine = 1
        end
        -- 每释放一个技能累计5秒
        nAutoFightCumulativeTime = nAutoFightCumulativeTime + 5
        -- 超时强杀boss 大于4分钟
        if nAutoFightCumulativeTime >= 600  then
            -- 十分钟后结束用例
            -- 关闭帧函数
            OutputMessage("MSG_SYS","abc")
            Timer.DelAllTimer(WorldBoss)
            bFlag = true
        end
        -- 设置释放技能的坐标
        SkillData.SetCastPointToTargetPos()
        -- 获取技能id
        local nSkillID = UIBattleSkillSlot.GetShowUI_Ver2(nAttackLine)
        -- 进行释放
        OnUseSkill(nSkillID, 1)
        nAttackLineCount = nAttackLineCount + 1
        nAttackLine = nAttackLine + 1
        AutoFightStartTimer = GetTickCount()
    end
end


function  AutoFight:OnLeave()                               
end

function WorldBoss.Start()
    -----创建状态机---------------
    -- 四种状态 移动 战斗 对话 睡眠
    fsm = FsmMachine:New()
    fsm:AddState(AutoFight)
    fsm:AddInitState(Init)
    Timer.AddFrameCycle(WorldBoss,1,function ()
        WorldBoss.FrameUpdate()
    end)
    return true
end

local pCurrentTime = 0
local nNextTime=tonumber(20)
local nCurrentStep=1
function RunMap.FrameUpdate()
    local player=GetClientPlayer()
    if not player then
        return
    end
    if not SearchPanel.IsFromLoadingEnterGame() then
        return
    end
    if bFlag and GetTickCount()-pCurrentTime>nNextTime*1000 then
        if nCurrentStep==#list_RunMapCMD+1 then
            bFlag=false
        end
        --切图前后置操作
        local szCmd=list_RunMapCMD[nCurrentStep]
        local nTime=tonumber(list_RunMapTime[nCurrentStep])
        print(szCmd)
        pcall(function ()
            SearchPanel.RunCommand(szCmd)
        end)
        OutputMessage("MSG_SYS",szCmd.."ok")
        nNextTime=nTime
        --切图操作
        if string.find(szCmd,"WorldBoss") then
            -- 启动副本
            WorldBoss.Start()
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

local ClosePop = {}
-- 特殊处理 弹窗 暂定
function ClosePop.FrameUpdate()
    if UIMgr.IsViewOpened(VIEW_ID.PanelNormalConfirmation) then
        -- 关闭弹窗
        UINodeControl.BtnTrigger("BtnOk")
    end
end

Timer.AddCycle(ClosePop,1,function ()
    ClosePop.FrameUpdate()
end)

Timer.AddFrameCycle(RunMap,1,function ()
	RunMap.FrameUpdate()
end)
LoginMgr.Log("WorldBoss","WorldBoss End")
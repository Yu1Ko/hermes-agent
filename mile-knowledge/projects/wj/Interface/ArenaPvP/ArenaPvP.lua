LoginMgr.Log("ArenaPvP","ArenaPvP Start")
local ArenaPvP = {}
local PlayerRole = {}
local nArenaLine = 1 -- 当前流程 
local RunMap ={}
--读取tab的内容
local bFlag = true
-- 加载RunMap.tab文件的数据  格式 {{},{},{},{},{},{},{}}
local tbRunMapData=SearchPanel.LoadRunMapFile(SearchPanel.szCurrentInterfacePath.."RunMap.tab",6)
local list_RunMapCMD = {}                       -- CMD文件
local list_RunMapTime = {}                      -- 文件时间
ArenaPvP.list_RunMapData={}     --跑图点数据

SearchPanel.RemoveFile(SearchPanel.szRunMapResultPath.."perfeye_start")
SearchPanel.RemoveFile(SearchPanel.szRunMapResultPath.."perfeye_stop")
SearchPanel.RemoveFile(SearchPanel.szRunMapResultPath.."ExitGame")
--处理未知弹窗
Timer.AddCycle(SearchPanel.tbTips,1,SearchPanel.DealWithTips)
-- 设置人物登录
SearchPanel.tbModule['AutoLogin'].SetAutoLoginInfo(nil,nil,'纯阳','成男')

-- 提取跑图坐标 和CMD指令
local function GetPointsRunMap()
    local strInfo=''
    local nDataLen=#tbRunMapData
    --临时数据存放
    local tbDataTemp={}
    --用第1个{}作为数据的总长度
    for i=1,#tbRunMapData[1] do
        tbDataTemp={}
        strInfo=tbRunMapData[1][i]:sub(1,1)
        if strInfo=='/' then
            table.insert(list_RunMapCMD,tbRunMapData[1][i])
            table.insert(list_RunMapTime,tbRunMapData[2][i])
        elseif strInfo=='x' then
            LOG.INFO("ArenaPvP.list_RunMapData Read RunMapData")
        else
            --取坐标 格式 x,y,z,stay,mapid,action  stay:在该点停了时间 action:在该点执行什么行为,1 stay 2 转一圈
            for n=1,nDataLen do
                table.insert(tbDataTemp,tbRunMapData[n][i])
            end
            table.insert(ArenaPvP.list_RunMapData,tbDataTemp)
        end
    end
end
--初始化 CMD和跑图数据点
GetPointsRunMap()

-----init----------------
Init = BaseState:New("Init")
function  Init:OnEnter()
    
end

function  Init:OnUpdate()
    fsm:Switch("Sleep")
end

function  Init:OnLeave()                               

end

function PlayerRole.AddBuff()
    -- 加强回血回蓝
    SearchPanel.RunCommand("/gm player.nLifeReplenishExt=100000000;player.nManaReplenishExt=100000")
    -- 超级血量buff
    local GM = "for i=1,50 do player.AddBuff(0,99,4136,1,7200) end;player.".._G.CurLife.."=player.".._G.MaxLife
    SearchPanel.RunCommand("/gm "..GM)
    -- true则为显示轻功面板，false则为显示技能面板
    local PlayerState = SprintData.GetViewState()
    -- 如果为技能面板则不切换
    if PlayerState then
        SprintData.ToggleViewState()
    end
    -- 放置木桩
    SearchPanel.RunCommand("/gm player.GetScene().CreateNpc(15949, player.nX,  player.nY, player.nZ, player.nFaceDirection,-1,'PointNpc_1').SetDialogFlag(0);")
end

local function RobotControlSetBuff()
	   -- 召唤
	   RobotControl.CMD("TeleportRobot")
	   -- 跟随
	   RobotControl.CMD("StartFollow")
	   -- 设置目标
	   RobotControl.CMD("SetTarget")
	   -- -- 机器人启动开始战斗
	   RobotControl.CMD("StartFight")
end

local AutoFightStartTimer = 0 -- 执行每个技能的时间
local AutoFightAttackTimer = 5 -- 技能释放间隔
local nAttackLineCount = 1 --释放技能的次数
local nAttackLine = 1 -- 当前技能
local nAutoFightCumulativeTime = 0  -- 战斗累计时间
local BtnTargetSelect = false
-- AutoFight
AutoFight = BaseState:New("AutoFight")
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
    if GetTickCount() - AutoFightStartTimer >=  AutoFightAttackTimer*1000 then
        if not BtnTargetSelect then
            UINodeControl.BtnTrigger("BtnTargetSelect")
            BtnTargetSelect = true
			RobotControlSetBuff()
        end
        -- 是否遍历完技能
        if nAttackLine == 6 then
            nAttackLine = 1
        end
        -- 每释放一个技能累计5秒
        nAutoFightCumulativeTime = nAutoFightCumulativeTime + 5
        -- 技能释放暂时代替
        -- 设置释放技能的坐标
        SkillData.SetCastPointToTargetPos()
        -- 获取技能id
        local nSkillID = UIBattleSkillSlot.GetShowUI_Ver2(nAttackLine)
        -- 进行释放
        OnUseSkill(nSkillID, 1)
        nAttackLineCount = nAttackLineCount + 1
        nAttackLine = nAttackLine + 1
        AutoFightStartTimer = GetTickCount()
        -- 超过4分钟后进行强杀 结束战斗
        if nAutoFightCumulativeTime >= 240 then
            -- 杀死所有机器人结束战斗
            RobotControl.CMD("KillMySelf")
            -- 打完后进行睡眠
            fsm:Switch("Sleep")
        end
    end
end


function  AutoFight:OnLeave()                               
end


-- PlayerMove
local bPlayerMove=false
PlayerMove = BaseState:New("PlayerMove")
function  PlayerMove:OnEnter()
    
end

function  PlayerMove:OnUpdate()
    if not bPlayerMove then
        --开启跑图 并帧更新判断跑图是否结束 将执行CMD的帧更新停止
        CustomRunMapByData.Start(ArenaPvP.list_RunMapData)
        bPlayerMove = true
        return
    end
    if CustomRunMapByData.IsEnd() then
        fsm:Switch("Sleep")
    end
end

function  PlayerMove:OnLeave()

end

local nSleepStartTime = 0
local nSleepCurrentTime=0
Sleep = BaseState:New("Sleep")
function  Sleep:OnEnter()
    -- 进入状态之前现重置睡眠时间
    nSleepCurrentTime = 5
    nSleepStartTime=GetTickCount()
end

function  Sleep:OnUpdate()
    if nArenaLine == 3 then
        -- 结束帧函数
        bFlag = true
        Timer.DelAllTimer(ArenaPvP)
    end
    if GetTickCount()-nSleepStartTime>nSleepCurrentTime*1000 then
        if nArenaLine == 1 then
            fsm:Switch("PlayerMove")
        elseif nArenaLine == 2 then
            fsm:Switch("AutoFight")
        end
    end
end

function  Sleep:OnLeave()    
    nArenaLine = nArenaLine + 1
end

local nLineUp = false
--帧更新函数
function ArenaPvP.FrameUpdate()
    -- 是否从地图加载界面进入了游戏
    if not SearchPanel.IsFromLoadingEnterGame() then
        return
    end
    -- 先暂时使用手动采集
    if nLineUp then
        CreateEmptyFile("perfeye_start")
        SearchPanel.bPerfeye_Start=true
        nLineUp = false
    end
    fsm.curState:OnUpdate()
end

LineUp ={}
LineUp.nStart = false
-- 初始化执行
function LineUp.FrameUpdate()
    if not IsArenaPvPDowload() then
        return
    end
    if not LineUp.nStart then
        UINodeControl.BtnTriggerByLable("BtnTeamMatching","组队匹配")
        LineUp.nStart = true
        return
    end
    if UIMgr.IsViewOpened(VIEW_ID.PanelPvpEnterConfirmation) then
        UINodeControl.BtnTriggerByLable("BtnGo","确认进入")
        Timer.AddFrameCycle(ArenaPvP,1,function ()
            ArenaPvP.FrameUpdate()
        end)
        nLineUp= true
        -- 关闭帧函数
        Timer.DelAllTimer(LineUp)
    end
    -- 一直让机器人排队
    RobotControl.JoinArenaQueue()
end

function IsArenaPvPDowload()
    local tMapIDList = ArenaData.GetMapList()
    for _, nMapID in ipairs(tMapIDList) do
        local nPackID = PakDownloadMgr.GetMapResPackID(nMapID)
        -- 检查是否下载完成
        local nState, _, _ = PakDownloadMgr.GetPackState(nPackID)
		if nState ~= DOWNLOAD_OBJECT_STATE.DOWNLOADED then
            PakDownloadMgr.DownloadPack(nPackID)
			return false
		end
    end
    return true
end



-- 开启名剑大会
function ArenaPvP.Start()
        -- 三种状态 移动 战斗 睡眠
        fsm = FsmMachine:New()
        fsm:AddState(AutoFight)
        fsm:AddState(PlayerMove)
        fsm:AddState(Sleep)
        fsm:AddInitState(Init)
        Timer.AddCycle(LineUp,1,function ()
            LineUp.FrameUpdate()
        end)
end


-- 暂时代替
local pCurrentTime = 0
local nNextTime=tonumber(20)
local nCurrentStep=1
function RunMap.FrameUpdate()
    local player=GetClientPlayer()
    if not player then
        return
    end
    -- 是否从地图加载界面进入了游戏
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
        if string.find(szCmd,"ArenaPvP") then
            -- 启动pvp
            ArenaPvP.Start()
            bFlag = false
        end
        if string.find(szCmd,"perfeye_stop") then
            SearchPanel.bPerfeye_Stop=true
		end
		pCurrentTime=GetTickCount()
        nCurrentStep=nCurrentStep+1
    end
end

Timer.AddCycle(RunMap,1,function ()
    RunMap.FrameUpdate()
end)


LoginMgr.Log("ArenaPvP","ArenaPvP End")
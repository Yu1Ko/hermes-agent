-- 战斗中需要做的操作 太多单独起个脚本进行控制
-- 读取buff
require("mui/Lua/Interface/PlayerAuto/AutoBuff.lua")
-- PlayerAuto
PlayerAuto = {}
PlayerAuto.bCoordinate = false -- 记录人物坐标点
PlayerAuto.playerX = 0 -- 人物x坐标
PlayerAuto.playerY = 0 -- 人物Y坐标
PlayerAuto.playerZ = 0 -- 人物Z坐标
PlayerAuto.nAttackLine = 1 --人物技能
PlayerAuto.nAttackTimeCount = 5 --默认5分钟
PlayerAuto.nAttackTotal = 0 -- 战斗计数
PlayerAuto.nBloodDeductionCount = 0 -- 扣血计数
PlayerAuto.nBossLifeCount = 1 -- boss血量默认为1
PlayerAuto.nBossLifeLine = 1/(PlayerAuto.nAttackTimeCount * 60/ 5)  -- 根据时间调整血量
PlayerAuto.bFlag = false -- 是否在战斗
PlayerAuto.NpcId=0 -- 记录npc的id
PlayerAuto.nNpcDieTimeCount = 2  -- 如果不是对应的npc强杀时间默认2秒一次
PlayerAuto.bNpcIdDie = false -- 选择npc强杀功能
PlayerAuto.nPlayerFightStatus = 1 -- 主角打斗状态 ：1、与boss距离某些位置，2、人物跑动，3、站立不动
PlayerAuto.bNextTarget = false -- 在打斗是否切换目标 适配特别的boss

function PlayerAuto.PlayerSetRun(nPlayerFightStatus) --true:跑
    PlayerAuto.nPlayerFightStatus=nPlayerFightStatus
end

-- PlayerAutoInit
local PlayerAutoInit = {}
PlayerAutoInit.Line = 1
PlayerAutoInit.tbList={
    'RobotControl.CMD("StopFight")',  -- 结束战斗
    'RobotControl.CMD("TeleportRobot")', -- 召唤机器人
    'RobotControl.CMD("CampfightBuff")', -- 战斗buff
    'RobotControl.CMD("BloodBuff")', -- 超级血量
    'RobotControl.CMD("StopFollow")', -- 机器人停止跟随
    'PlayerAuto.AddBuff()', --添加玩家角色buff
    'PlayerAuto.SetbCoordinate()', -- 记录当前人物坐标点
    'PlayerAuto.SearchNextTarget()', --锁定敌人
    'PlayerAuto.Attention()', --自动调正视角锁死
    'PlayerAuto.SetNpcId()', -- 记录锁定npc的id
    'AutoBattle.Start()',
    'RobotControl.CMD("SetTarget")', -- 机器人设定目标
    'RobotControl.CMD("StartFight")'--开启战斗
}

-- PlayerAutoBufforGM
PlayerAutoBufforGM  ={}
PlayerAutoBufforGM.nTime = 3 -- 调整执行buff的时间 默认为3秒一次
PlayerAutoBufforGM.Line= 1
PlayerAutoBufforGM.tbList ={}

-- PlayerAutoDie
PlayerAutoDie= {}

-- PlayerNpcDie
PlayerNpcDie = {}

-- RobotRandomStand
local RobotRandomStand = {}

-- RobotRevive
local RobotRevive = {}
RobotRevive.nStartTimer = 0 -- 机器人复活开始时间
RobotRevive.nNextTimer = 15 -- 机器人复活时间 默认15s复活一次

--Combatarea
local Combatarea = {}

-- 是否在战斗
function PlayerAuto.IsAuto()
    return PlayerAuto.bFlag
end

-- 是否开启召唤物强杀
function PlayerAuto.SetNpcIdDie(bDie)
    PlayerAuto.bNpcIdDie = bDie
end

-- 设置血量
function PlayerAuto.SetAttackTimeCount(nAttackTimeCount)
    PlayerAuto.nAttackTimeCount = tonumber(nAttackTimeCount)
    -- 重新设置扣血
    PlayerAuto.nBossLifeLine = 1/(PlayerAuto.nAttackTimeCount * 60/ 5)
end

-- 根据对应的地图名称和boss选择对应buff
function PlayerAutoBufforGM.SetBossBuff(szMapName,nBoss)
    if not szMapName then
        return
    end
    if AutoBuff[szMapName][nBoss] ~= nil then
        for nBuff, value in pairs(AutoBuff[szMapName][nBoss]) do
            -- buff最后一位是时间不要加进表里
            if nBuff ~= #AutoBuff[szMapName][nBoss] then
                PlayerAutoBufforGM.Set(value)
            else
                PlayerAutoBufforGM.nTime = value
            end
        end
    end
end

-- 加入对应的buff
function PlayerAutoBufforGM.Set(szCmd)
    table.insert(PlayerAutoBufforGM.tbList,szCmd)
end


-- 是否每次释放技能都切换下个目标
function PlayerAuto.SetNextTarget()
    PlayerAuto.bNextTarget = true
end

-- 锁定对应的敌人 还是有问题等待修复
function PlayerAuto.TrySelectOneTarget()
    -- 锁定接口：前没有目标，则尝试自动选择一个 成功锁定会返回true
    local nSkillID = UIBattleSkillSlot.GetShowUI_Ver2(1);
    local TrySelectOneTarge  = TargetMgr.TrySelectOneTarget(nSkillID)
    return TrySelectOneTarge
end
-- 注视当前选中的目标 锁死目标 自动锁死调用镜头
function PlayerAuto.Attention()
    TargetMgr.Attention(true)
end
-- 选择选中下一个目标
function PlayerAuto.SearchNextTarget()
    TargetMgr.SearchNextTarget()
end

-- 记录锁定npc的id
function PlayerAuto.SetNpcId()
    local NpcID,_ = TargetMgr.GetSelect();
    PlayerAuto.NpcId = NpcID
end

-- 设置扣除boss血量点数
function PlayerAuto.SetBossLifeCount(BossLifeCount)
    PlayerAuto.nBossLifeLine = BossLifeCount
end

-- 设置扣除boss血量
-- 血量计算方式 满血为1 1/5
function PlayerAuto.SetBossLife()
    print("PlayerAuto.SetBossLife")
    local gm = "n=player.GetSelectCharacter();n.".._G.CurLife.."=n.".._G.MaxLife.."*"..tostring(PlayerAuto.nBossLifeCount);
    SearchPanel.RunCommand("/gm "..gm)
end


-- 锁定目标NPC血量和名称
function PlayerAuto.GetBossLife()
    -- 锁定NPCID
    local NpcID,_ = TargetMgr.GetSelect();
    -- 锁定敌人目标血量
    local NpcLife = NpcData.GetNpc(NpcID).fCurrentLife64
    -- -- 锁定敌人名称
    local NpcName = NpcData.GetNpc(NpcID).szName
    return NpcLife,NpcName
end


PlayerRun = {}
PlayerRun.bStartOne = true
PlayerRun.bState = true
local nBossX,nBossY= 0,0
local nDistance = 500      -- 离boss的距离
function PlayerRun.FrameUpdate()
    if PlayerRun.bState then
        local nBossNextX, nBossNextY = GetNpc(PlayerAuto.NpcId).nX, GetNpc(PlayerAuto.NpcId).nY   -- boss坐标
        local A1, B1 = PlayerAuto.playerX,PlayerAuto.playerY -- 中心区域坐标
        local nBossVectorX=nBossNextX-nBossX
        local nBossVectorY=nBossNextY-nBossY
        -- 如果移动距离过于500 则移动
        print("boss坐标",nBossVectorX*nBossVectorX+nBossVectorY*nBossVectorY)
        if nBossVectorX*nBossVectorX+nBossVectorY*nBossVectorY >= 100*100 or PlayerRun.bStartOne then
            -- 计算连线向量
            local dx = A1 - nBossNextX
            local dy = B1 - nBossNextY
            local length = math.sqrt(dx * dx + dy * dy)

            -- 单位方向向量
            local ux = dx / length
            local uy = dy / length

            -- 玩家坐标 = Boss坐标 + 方向向量*距离
            local px = nBossNextX + ux * nDistance
            local py = nBossNextY + uy * nDistance

            print(string.format("玩家坐标：(%.2f, %.2f)", px, py))
            print(string.format("Boss位置：(%.2f, %.2f)", A1, B1))
            local tbCustom ={}
            local player = GetClientPlayer()
            local tbPlayerPos ={player.nX,player.nY,player.nZ}
            local tbPlayerPosNext={px,py,player.nZ}
            table.insert(tbCustom,tbPlayerPos)
            table.insert(tbCustom,tbPlayerPosNext)
            CustomRunMapByData.Start(tbCustom)
            PlayerRun.bStartOne = false
            PlayerRun.bState = false
        end
    end
    if CustomRunMapByData.IsEnd() then
        PlayerRun.bState =true
        nBossX,nBossY=GetNpc(PlayerAuto.NpcId).nX, GetNpc(PlayerAuto.NpcId).nY
    end
end
function PlayerRun.Start()
    PlayerRun.bStartOne = true
    nBossX,nBossY=GetNpc(PlayerAuto.NpcId).nX, GetNpc(PlayerAuto.NpcId).nY
    Timer.AddCycle(PlayerRun,5,function ()
        PlayerRun.FrameUpdate()
    end)
end

-- 机器人复活
function RobotRevive.FrameUpdate()
    -- 是否在战斗
    if GetTickCount() - RobotRevive.nStartTimer  >= RobotRevive.nNextTimer*1000 then
        -- 机器人复活
        RobotControl.CMD("ReviveAndBloodBuff")
        RobotRevive.nStartTimer = GetTickCount()
    end
end

-- 机器人范围设置
function RobotRandomStand.FrameUpdate()
    RobotControl.RandomStand(PlayerAuto.playerX,PlayerAuto.playerY,PlayerAuto.playerZ,500,500)
end

-- boss打出场外问题
function Combatarea.FrameUpdate()
    local player=GetClientPlayer()
    if (player.nX+player.nY) ~= (PlayerAuto.playerX+PlayerAuto.playerY) then
        -- 传送回原来的坐标
        SearchPanel.RunCommand("/gm player.SetPosition("..PlayerAuto.playerX..","..PlayerAuto.playerY..","..PlayerAuto.playerZ..")")
    end
end

-- 记录人物坐标点

function PlayerAuto.SetbCoordinate(nX,nY,nZ)
    if nX~=nil then
        --自定义锁定boss位置 处理特殊区域
        PlayerAuto.playerX = nX
        PlayerAuto.playerY = nY
        PlayerAuto.playerZ = nZ
        PlayerAuto.bCoordinate= true
        return
    end
    local player=GetClientPlayer()
    if not player then
        return
    end
    if not PlayerAuto.bCoordinate then
        PlayerAuto.playerX = player.nX
        PlayerAuto.playerY = player.nY
        PlayerAuto.playerZ = player.nZ
        PlayerAuto.bCoordinate= true
    end
end

-- 人物初始化操作加各种buff
function PlayerAuto.AddBuff()
    -- 开启无敌 
    SearchPanel.RunCommand("/gm player.AddBuff(0,99,377,1,7200)")
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
    AutoBattle.Start()
end

-- 除去身上buff
function PlayerAutoBufforGM.FrameUpdate()
    if PlayerAutoBufforGM.Line == #PlayerAutoBufforGM.tbList+1 then
        PlayerAutoBufforGM.Line = 1
    end
    local szCmd = PlayerAutoBufforGM.tbList[PlayerAutoBufforGM.Line]
    print(szCmd)
    if szCmd ~= nil then
        SearchPanel.RunCommand(szCmd)
    end
    PlayerAutoBufforGM.Line = PlayerAutoBufforGM.Line + 1
end

-- 初始化
function PlayerAutoInit.InitFrameUpdate()
    if PlayerAutoInit.Line ~= #PlayerAutoInit.tbList+1 then
        local szCmd = PlayerAutoInit.tbList[PlayerAutoInit.Line]
        local CMD = "/cmd "..szCmd
        SearchPanel.RunCommand(CMD)
    else
        -- 机器人复活
        Timer.AddCycle(RobotRevive,1,function ()
            RobotRevive.FrameUpdate()
        end)

        if PlayerAuto.nPlayerFightStatus==1 then
            -- 与boss距离某些位置
            PlayerRun.Start()
        elseif PlayerAuto.nPlayerFightStatus==2 then
            -- 人物绕圈跑动
            Displacement.SetCenterPoint(PlayerAuto.playerX,PlayerAuto.playerY,PlayerAuto.playerZ)
            Displacement.GetPoint()
            Displacement.Start()
        else
            -- 定点站立打斗
            Timer.AddCycle(Combatarea,1,function ()
                Combatarea.FrameUpdate()
            end)
        end
        
        Timer.AddCycle(RobotRevive,30,function ()
            RobotRandomStand.FrameUpdate()
        end)
        --人物死亡
        Timer.AddCycle(PlayerAutoDie,1,function ()
            PlayerAutoDie.FrameUpdate()
        end)
        -- 并且结束帧函数
        Timer.DelAllTimer(PlayerAutoInit)
        -- 启动战斗
        Timer.AddCycle(PlayerAuto,1,function ()
            PlayerAuto.FrameUpdate()
        end)
        -- 除去buff等特殊操作
        Timer.AddCycle(PlayerAutoBufforGM,3,function ()
            PlayerAutoBufforGM.FrameUpdate()
        end)
        if PlayerAuto.bNpcIdDie then
            -- 强杀召唤物
            Timer.AddCycle(PlayerNpcDie,PlayerAuto.nNpcDieTimeCount,function ()
                PlayerNpcDie.FrameUpdate()
            end)
        end
    end
    PlayerAutoInit.Line = PlayerAutoInit.Line + 1
end

--结束操作 重置所有部分
function PlayerAuto.StopOperate()
    Displacement.Stop() -- 停止跑动
    PlayerAuto.bCoordinate = false -- 记录人物坐标点
    PlayerAuto.nAttackLine = 1 --人物技能
    PlayerAuto.nAttackTotal = 0 -- 战斗计数
    PlayerAuto.nBossLifeCount = 1 -- 重置boss血量
    PlayerAuto.nBloodDeductionCount = 0 -- 扣血计数
    PlayerAuto.nBossLifeLine = 1/(PlayerAuto.nAttackTimeCount * 60/ 5)  -- 调整血量
    PlayerAutoBufforGM.tbList = {} -- buff重置
    PlayerAuto.NpcId = 0 -- 重置npcId
    PlayerAutoInit.Line = 1 -- 初始化重置
    PlayerAuto.bFlag = false -- 结束战斗
    RobotControl.CMD("StopFight") -- 机器人结束战斗
    PlayerAuto.bNpcIdDie = false -- 重置npc强杀
    PlayerAuto.bNextTarget = false --关闭自动下个索敌
    AutoBattle.Stop() --关闭武学助手
    -- 释放所有帧函数
    Timer.DelAllTimer(PlayerRun)
    Timer.DelAllTimer(RobotRevive)
    Timer.DelAllTimer(Combatarea)
    Timer.DelAllTimer(PlayerAuto)
    Timer.DelAllTimer(PlayerAutoDie)
    Timer.DelAllTimer(PlayerAutoBufforGM)
    Timer.DelAllTimer(PlayerNpcDie)
end


-- 打斗帧函数
local nForcedkill = 1
function PlayerAuto.FrameUpdate()
    -- 防止人物死亡被秒杀不死buff
    SearchPanel.RunCommand("/gm player.AddBuff(player.dwID,player.nLevel,203,1,3600)")
    SearchPanel.RunCommand('/gm local scene = player.GetScene();local chengshang=scene.GetNpcByNickName("NPC_BoodCheck");chengshang.SetCustomUnsigned1(1,3)')
    -- 是否遍历完技能
    if PlayerAuto.nAttackLine == 6 then
        PlayerAuto.nAttackLine = 1
    end
    -- 释放技能
    local nSkillID = UIBattleSkillSlot.GetShowUI_Ver2(PlayerAuto.nAttackLine);
    OnUseSkill(nSkillID, 1)
    PlayerAuto.nAttackLine = PlayerAuto.nAttackLine + 1
    --重新锁定
    PlayerAuto.TrySelectOneTarget()
    PlayerAuto.Attention()
    -- 根据时间来控制boss血量
    -- 5秒设置一次
    if PlayerAuto.nBloodDeductionCount == 5 then
        -- 是否设置切换下个目标
        if PlayerAuto.bNextTarget then
            PlayerAuto.SearchNextTarget()
        end
        if PlayerAuto.nBossLifeCount >0 then
            PlayerAuto.nBossLifeCount = PlayerAuto.nBossLifeCount - PlayerAuto.nBossLifeLine
        else
            PlayerAuto.nBossLifeCount = 0
        end
        PlayerAuto.SetBossLife()
        PlayerAuto.nBloodDeductionCount = 0
    end
    -- 增加计数
    PlayerAuto.nBloodDeductionCount = PlayerAuto.nBloodDeductionCount + 1
    PlayerAuto.nAttackTotal = PlayerAuto.nAttackTotal + 1
    -- 根据时间来判断强杀boss
    if PlayerAuto.nAttackTotal >= PlayerAuto.nAttackTimeCount*60 then
        local player =GetClientPlayer()
        if player.nMoveState ~= 16 then
            SearchPanel.RunCommand("/gm if player.GetSelectCharacter() ~= nil then player.GetSelectCharacter().Die() end")
            PlayerAuto.SearchNextTarget()
            -- 强杀15秒后进行检查
            nForcedkill = nForcedkill  + 1
            if nForcedkill >= 10 then
                -- if not player.bFightState then
                    --结束所有函数
                    PlayerAuto.StopOperate()
                    return
                -- end
            end
        end
    end
end

-- 判断人物死亡函数
function PlayerAutoDie.FrameUpdate()
    local player =GetClientPlayer()
    if player.nMoveState == 16 then
        -- 复活
        SearchPanel.RunCommand("/gm player.Revive()")
        -- 添加buff
        PlayerAuto.AddBuff()
    end
end

-- 强杀召唤物
function PlayerNpcDie.FrameUpdate()
    local nNpcId =  TargetMgr.GetSelect()
    print(nNpcId,PlayerAuto.NpcId)
    if nNpcId ~= PlayerAuto.NpcId then
        SearchPanel.RunCommand("/gm if player.GetSelectCharacter() ~= nil then player.GetSelectCharacter().Die() end")
    end
end


-- 启动脚本
function PlayerAuto.StartAutoFight()
    Timer.AddCycle(PlayerAutoInit,8,function ()
        PlayerAutoInit.InitFrameUpdate()
    end)
    PlayerAuto.bFlag = true
end
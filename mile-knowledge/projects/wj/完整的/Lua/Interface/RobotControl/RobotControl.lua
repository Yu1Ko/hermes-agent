RobotControl = {}
local self=RobotControl
--控制服务端机器人
LoginMgr.Log("RobotControl","RobotControl imported")
RobotControl.bSwitch = true                               -- 插件开关
RobotControl.nIndex=0
RobotControl.nCount=0
RobotControl.szNameHead=''
RobotControl.nClosePanelTimer=5
RobotControl.script=nil
self.tbCMD={}
function RobotControl.IniRobot(nIndex,nCount,szNameHead)
    print("RobotControl.IniRobot")
    RobotControl.nIndex=nIndex
    RobotControl.nCount=nCount
    print(nCount)
    RobotControl.szNameHead=szNameHead
    self.tbCMD = {
        ['SetRobot']=self.SetRobot,     --连接机器人
        ['TeleportRobot']=self.TeleportRobot,     --召唤机器人
        ['InviteToTeam']=self.InviteToTeam,       --机器人入队
        ['GetTeamLeader']=self.GetTeamLeader,     --获取团队权限
        ['RequestLeaveTeam']=self.RequestLeaveTeam,       -- 通知退组
        ['CreateTeamByRobot']=self.CreateTeamByRobot,     -- 机器人间组队
        ['StartFollow']=self.StartFollow,     -- 请跟随我
        ['StopFollow']=self.StopFollow,     -- 停止跟随我
        ['SetTarget']=self.SetTarget,     -- 设置目标
        ['ReviveMySelf']=self.ReviveMySelf,       --复活
        ['CampfightBuff']=self.CampfightBuff,     -- 战斗常用BUFF
        ['BloodBuff']=self.BloodBuff,     -- 超级血量BUFF
        ['StartFight']=self.StartFight,       -- 开启战斗
        ['StopFight']=self.StopFight,     -- 结束战斗
        ['AddFriend']=self.AddFriend,     -- 添加好友
        ['KillMySelf']=self.KillMySelf,     -- 自杀
        ['Start']=self.Start,     -- 一键初始化打副本环境
        ['Arena']=self.Arena,     -- 一键初始化打PVP环境
        ['AddImmortal']=self.AddImmortal, --设置不死buff
        ['DelImmortal']=self.DelImmortal, --删除不死buff
        ['ReviveAndBloodBuff']=self.ReviveAndBloodBuff, --复活和超级血量buff
        ['StartCamp']=self.StartCamp,--开启阵营模式
        ['AverageCamp']=self.AverageCamp,--均分阵营
        ['StartBattlefield']=self.StartBattlefield -- 一键初始化打10V10战场环境
    }
end

function RobotControl.GetScript()
    print("RobotControl.GetScript")
    RobotControl.script=UIMgr.GetViewScript(VIEW_ID.PanelRobotItem)
    if not RobotControl.script then
        RobotControl.script=UIMgr.Open(VIEW_ID.PanelRobotItem, SearchRobot)
    end
end

function RobotControl.DelScript()
    print("RobotControl.DelScript")
    RobotControl.script=UIMgr.GetViewScript(VIEW_ID.PanelRobotItem)
    if RobotControl.script then
        RobotControl.script=nil
        UIMgr.Close(VIEW_ID.PanelRobotItem)
    end
end

function RobotControl.CMD(szCMD,...)
    --打开面板
    self.GetScript()
    LOG.INFO(szCMD)
    --链接机器人
    self.SetRobot()
    self.tbCMD[szCMD](...)
    --全部隐藏
    UINodeControl.FindChildByName("PanelRobotItem"):setVisible(false)

    --一键副本 不能关闭面板,否者会导致部分命令执行失败,因此只能隐藏
    --[[
    if szCMD=='Start' or szCMD=='Arena' then
        print(szCMD..'-----------------')
        UINodeControl.FindChildByName("PanelRobotItem"):setVisible(false)
    else
        Timer.Add(self,self.nClosePanelTimer,function ()
            self.DelScript()
        end)
    end]]
end


--连接机器人
function RobotControl.SetRobot(nIndex,nCount,szNameHead)
    SearchRobot.tbRobot={} --清除机器人选中数据
    if not nIndex then
        nIndex=RobotControl.nIndex
    end
    if not nCount then
        nCount=RobotControl.nCount
    end
    if not szNameHead then
        szNameHead=RobotControl.szNameHead
    end
     print('nIndex:'..tostring(nIndex)..'\tnCount:'..tostring(nCount))
    RobotControl.script:SetInitRobot(nIndex,nCount,szNameHead)
end

--一键准备打副本所需的机器人环境
function RobotControl.Start()
    local list_szFun=
    {
        'RobotControl.KillMySelf()', --先杀死机器人
        'RobotControl.TeleportRobot()',  --召唤机器人到身边
        'RobotControl.RequestLeaveTeam()',  --通知退组
        'RobotControl.InviteToTeam()',  --通知入队
        'RobotControl.InviteToTeam()',  --通知入队
        'RobotControl.GetTeamLeader()',  --获取团队权限
        'RobotControl.StartFollow()',  --跟随
        'RobotControl.BloodBuff()',  --超级血量buff
    }

    for nIndex,szFun in ipairs(list_szFun) do
        Timer.Add(self,self.nClosePanelTimer*nIndex,function ()
            SearchPanel.MyExecuteScriptCommand(szFun)
        end)
    end

end


--一键准备打稳定性副本所需的机器人环境
local StabilityRobotCount= 0
function RobotControl.StabilityStart(RobotCount)
    local StabilityRobotCount = RobotCount
    local list_szFun=
    {
        'RobotControl.SetRobot()', --初始化机器人
        'RobotControl.TeleportRobot()', --召唤机器人到身边
        'RobotControl.CampfightBuff()',  --战斗常用buff
        'RobotControl.SetRobot(RobotControl.nIndex,'..tostring(StabilityRobotCount)..',nil)',  --控制多少个个机器人
        'RobotControl.RequestLeaveTeam()',  --通知退组
        'RobotControl.InviteToTeam()',  --通知入队
        'RobotControl.InviteToTeam()',  --通知入队
        'RobotControl.GetTeamLeader()',  --获取团队权限
        'RobotControl.StartFollow()',  --跟随
        'RobotControl.CampfightBuff()',  --战斗常用buff
        'RobotControl.BloodBuff()',  --超级血量buff
    }

    for nIndex,szFun in ipairs(list_szFun) do
        Timer.Add(self,self.nClosePanelTimer*nIndex,function ()
            SearchPanel.MyExecuteScriptCommand(szFun)
        end)
    end

end


--10v10一键准备环境
function RobotControl.StartBattlefield()
     local list_szFun=
    {
        'RobotControl.SetRobot()', --初始化机器人
        'RobotControl.StopFight()', --结束战斗
        'RobotControl.TeleportRobot()', --召唤机器人到身边
        'RobotControl.RequestLeaveTeam()',  --通知退组
        'RobotControl.ReviveMySelf()',  --复活
        'RobotControl.CancelCamp()', --先取消阵营
        'RobotControl.SetRobot(RobotControl.nIndex,9,nil)',  --控制9个机器人
        'RobotControl.InviteToTeam()',  --邀请入队
        'RobotControl.SetHaoqiCamp()',-- 加入浩气
        'RobotControl.SetRobot(RobotControl.nIndex+9,10,nil)',  --控制10个机器人
        'RobotControl.CreateTeamByRobot()', -- 机器人组队
        'RobotControl.SetErenCamp()',-- 加入恶人
        'RobotControl.SetRobot(RobotControl.nIndex,19,nil)',  --控制所有机器人
        'RobotControl.StartCamp()', -- 开启阵营模式
        'RobotControl.ReviveAndBloodBuff()', --添加buff
        'RobotControl.RandomStand(7653,24931,1036992,600,600)', -- 根据点位设置站位(时间问题暂时写死
        'RobotControl.StartRandomStand()', --防止机器人走动
        'RobotControl.StartFight()',--开启战斗
    }
    for nIndex,szFun in ipairs(list_szFun) do
        Timer.Add(self,self.nClosePanelTimer*nIndex,function ()
            SearchPanel.MyExecuteScriptCommand(szFun)
            print('szCMD:'..szFun.."\tnLen:"..tostring(#SearchRobot.tbRobot))
        end)
    end
end

--3v3竞技场一键准备环境
function RobotControl.Arena()
    --初始化机器人
    --RobotControl.SetRobot()
    --控制5个机器人设置  召唤机器人到身边,退出组队,跟随,复活,buff
    --每一个步骤都要sleep 秒
    local list_szFun=
    {
        'RobotControl.SetRobot()', --初始化机器人
        'RobotControl.TeleportRobot()', --召唤机器人到身边
        'RobotControl.RequestLeaveTeam()',  --通知退组
        'RobotControl.ReviveMySelf()',  --复活
        'RobotControl.StartFollow()',  --跟随
        'RobotControl.CampfightBuff()',  --战斗常用buff
        'RobotControl.SetRobot(RobotControl.nIndex,3,nil)',  --控制3个机器人
        'RobotControl.Negative1()',  --消除buff
        'RobotControl.Negative2()', --消除buff
        'RobotControl.CreateTeamByRobot()',  --控制3个机器组队
        'RobotControl.LeaveArenaQueuee()',  --控制3个机器退出竞技场排队
        'RobotControl.JoinArenaQueue()',  --控制3个机器竞技场排队
        'RobotControl.JoinArenaQueue()',  --控制3个机器竞技场排队
        'RobotControl.SetRobot(RobotControl.nIndex+3,2,nil)', --控制两个机器人
        'RobotControl.Negative1()',  --消除buff
        'RobotControl.Negative2()', --消除buff
        'RobotControl.InviteToTeam()',  --控制两个机器人邀请入队
        'RobotControl.GetTeamLeader()',  --获取团队权限
        'RobotControl.SetRobot()'--控制5个机器人
    }
    for nIndex,szFun in ipairs(list_szFun) do
        Timer.Add(self,self.nClosePanelTimer*nIndex,function ()
            SearchPanel.MyExecuteScriptCommand(szFun)
            print('szCMD:'..szFun.."\tnLen:"..tostring(#SearchRobot.tbRobot))
        end)
    end
end

--召唤机器人
function RobotControl.TeleportRobot()
    RobotControl.script:TeleportRobot()
end

--机器人入队
function RobotControl.InviteToTeam()
    ServerRobotTeamManager.tbTeamSetting[2].fnCallBack()
end

--获取团队权限
function RobotControl.GetTeamLeader()
    ServerRobotTeamManager.tbTeamSetting[1].fnCallBack()
end

-- 通知退组
function RobotControl.RequestLeaveTeam()
    ServerRobotTeamManager.tbTeamSetting[3].fnCallBack()
end


-- 机器人间组队
function RobotControl.CreateTeamByRobot()
    ServerRobotTeamManager.tbTeamSetting[4].fnCallBack()
end

-- 不死buff
function RobotControl.AddImmortal()
    local szCmd = "for i=1,10 do player.AddBuff(player.dwID,player.nLevel,203,1,100) end";
    local szMsg  = string.format("g_m:%s", szCmd)
    OutputMessage("MSG_ANNOUNCE_RED", szMsg)
    SearchRobot:SendCustomMessage(szMsg, 2)
end

-- 删除不死buff
function RobotControl.DelImmortal()
    local szMsg = string.format("for i=1,340 do player.GetSelectCharacter().DelBuff(203,1) end")
    SearchRobot:SendCustomMessage(szMsg, 2)
end

-- 请跟随我
function RobotControl.StartFollow()
    RobotControl.script:StartFollow()
end

-- 停止跟随我
function RobotControl.StopFollow()
    RobotControl.script:StopFollow()
end

-- 设置目标
function RobotControl.SetTarget()
    ServerRobotFightSettings.tbFightSettingSetting[4].fnCallBack()
end


--复活
function RobotControl.ReviveMySelf()
    ServerRobotFightSettings.tbFightSettingSetting[7].fnCallBack()
end

-- Buff 增强
function RobotControl.EnchangeBuff()
    RobotControl.script:EnchangeBuff()
end

--战斗常用BUFF
function RobotControl.CampfightBuff()
    ServerRobotBufff.tbBuffSetting[1].fnCallBack()
end

--超级血量BUFF
function RobotControl.BloodBuff()
    ServerRobotBufff.tbBuffSetting[2].fnCallBack()
end

-- 开启战斗
function RobotControl.StartFight()
    ServerRobotFightSettings.tbFightSettingSetting[5].fnCallBack()
end



-- 结束战斗
function RobotControl.StopFight()
    ServerRobotFightSettings.tbFightSettingSetting[6].fnCallBack()
end


-- 添加好友
function RobotControl.AddFriend()
    RobotControl.script:AddFriend()
end

-- 复活并添加超级血量
function RobotControl.ReviveAndBloodBuff()
    local szMsg = string.format("g_m:player.Revive();for i=1,50 do player.AddBuff(0,99,4136,1,7200) end;player.fCurrentLife64=player.fMaxLife64;player.nLifeReplenishExt=player.fMaxLife64/2")
    print('test:'..szMsg)
    SearchRobot:SendCustomMessage(szMsg, 2)
end


--自杀
function RobotControl.KillMySelf()
    ServerRobotFightSettings.tbFightSettingSetting[9].fnCallBack()
end


--范围站立
function RobotControl.RandomStand(nXTop,nYTop,nZTop,nX,nY)
    if not nX then
        nX=100
    end
    if not nY then
        nY=100
    end
    local szMsg = string.format("custom:LY_RandomStandAccordToMe(%d,%d,%d,%d,%d)",nXTop,nYTop,nZTop, nX,nY)
    print('test:'..szMsg)
    SearchRobot:SendCustomMessage(szMsg, 2)
end

--竞技场排队
function RobotControl.JoinArenaQueue()
    local szMsg = string.format("custom:JoinArenaQueue(1, false, 1, false)")
    print('test:'..szMsg)
    SearchRobot:SendCustomMessage(szMsg, 2)
end

-- 竞技场清除消极buff1
function RobotControl.Negative1()
    local szMsg = string.format("for i=1,340 do player.GetSelectCharacter().DelBuff(11880,1) end")
    print('test:'..szMsg)
    SearchRobot:SendCustomMessage(szMsg, 2)
end

-- 竞技场清除消极buff2
function RobotControl.Negative2()
    local szMsg = string.format("for i=1,2129 do player.GetSelectCharacter().DelBuff(11881,1) end")
    print('test:'..szMsg)
    SearchRobot:SendCustomMessage(szMsg, 2)
end


--退出竞技场排队
function RobotControl.LeaveArenaQueuee()
    local szMsg = string.format("custom:LeaveArenaQueue()")
    SearchRobot:SendCustomMessage(szMsg, 2)
end

-- 检查组队人数
function RobotControl.CheckTeamCount()
    -- 组队后获取团队人数
    local hTeam = GetClientTeam()
    local nTeamSize = hTeam.GetTeamSize()
    if RobotControl.nCount == (nTeamSize-1) then
        return true
    end
    return false
end

-- 开启阵营模式
function RobotControl.StartCamp()
    local  szMsg = string.format("g_m:player.OpenCampFlag()")
    OutputMessage("MSG_ANNOUNCE_RED", szMsg)
    SearchRobot:SendCustomMessage(szMsg, 1)
end

function RobotControl.CancelCamp()
    local  szMsg = string.format("g_m:player.SetCamp(0)")
    OutputMessage("MSG_ANNOUNCE_RED", szMsg)
    SearchRobot:SendCustomMessage(szMsg, 1)
end

-- 设置浩气阵营
function RobotControl.SetHaoqiCamp()
    local szMsg = string.format("g_m:player.SetCamp(1)")
    SearchRobot:SendCustomMessage(szMsg, 1)
end

-- 设置恶人阵营
function RobotControl.SetErenCamp()
    local  szMsg = string.format("g_m:player.SetCamp(2)")
    SearchRobot:SendCustomMessage(szMsg, 1)
end


-- 均分阵营(浩气:恶人)
function RobotControl.AverageCamp()
    local  szMsg1 = string.format("g_m:player.SetCamp(1)")
    local  szMsg2 = string.format("g_m:player.SetCamp(2)")
    SearchRobot:SendCustomMessageAvg(szMsg1, szMsg2, 1)
end

function RobotControl.StartRandomStand()
    local RobotRandomStand ={}
    Timer.AddCycle(RobotRandomStand,30,function ()
        RobotControl.RandomStand(7653,24931,1036992,600,600)
        local nSkillID = UIBattleSkillSlot.GetShowUI_Ver2(1);
        OnUseSkill(nSkillID, 1)
    end)
end

LoginMgr.Log("RobotControl","RobotControl End")
return RobotControl
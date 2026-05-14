-- 队伍设置相关界面和逻辑
ServerRobotTeamManager = ServerRobotTeamManager or {className = "ServerRobotTeamManager"}

ServerRobotTeamManager.szTitle = "设置队伍"
ServerRobotTeamManager.tbTeamSetting = {
    {
        szlabel = "获取团队权限",
        fnCallBack = function ()
            local player 		= GetClientPlayer()
            local dwTeamLeader  = GetClientTeam().dwTeamLeader
            local CurrentLeader = GetClientTeam().GetMemberInfo(dwTeamLeader)
            if CurrentLeader and dwTeamLeader ~= player.dwID then
                local  szMsg = string.format("custom:ChangeTeamLeader(%d)", player.dwID)
                OutputMessage("MSG_ANNOUNCE_RED", szMsg)
                SearchRobot:SendCustomMessage(szMsg, 2)
            end
        end
    },
    {
        szlabel = "邀请入队",
        fnCallBack = function ()
            if SearchRobot.nChannel ~= PLAYER_TALK_CHANNEL.WHISPER then
                OutputMessage("MSG_ANNOUNCE_RED", "为防止误操作, 请选择指定机器人模式！")
                return
            end
            local nRobotCount = #SearchRobot.tbRobot
            local nIndex = 1
            local fnInviteJoinTeam = function ()
                local szName = SearchRobot.tbRobot[nIndex]
                local name = UIHelper.UTF8ToGBK(szName)
                local tTargetRole = JX.GetPlayerByName(name)
                if tTargetRole and not TeamData.IsPlayerInTeam(tTargetRole.dwID) then
                    GetClientTeam().InviteJoinTeam(name)
                end
                nIndex = nIndex + 1
                local nTeamSize = GetClientTeam().GetTeamSize() or 0
                if  nTeamSize < 25 then
                    local team = GetClientTeam()
                    team.LevelUpRaid()
                end
            end
            Timer.AddCountDown(ServerRobotTeamManager, nRobotCount, fnInviteJoinTeam)
        end
    },
    {
        szlabel = "通知退组",
        fnCallBack = function ()
            if SearchRobot.nChannel ~= PLAYER_TALK_CHANNEL.WHISPER then
                OutputMessage("MSG_ANNOUNCE_RED", "为防止误操作, 请选择指定机器人模式！")
                return
            end
            local  szMsg = string.format("custom:LY_RequestLeaveTeam()")
            OutputMessage("MSG_ANNOUNCE_RED", szMsg)
            SearchRobot:SendCustomMessage(szMsg,2)
        end
    },
    {
        szlabel = "机器人间组队",
        fnCallBack = function ()
            if SearchRobot.nChannel ~= PLAYER_TALK_CHANNEL.WHISPER then
                OutputMessage("MSG_ANNOUNCE_RED", "为防止误操作, 请选择指定机器人模式！")
                return
            end
            local  szMsg = string.format("custom:LY_CreateTeamByRobot()")
            OutputMessage("MSG_ANNOUNCE_RED", szMsg)
            SearchRobot:SendCustomMessage(szMsg, 2)
        end
    },
    {
        szlabel = "机器人组队配置",
        fnCallBack = function ()
            -- local  szMsg = string.format("custom:LY_SuperLife()")
            -- OutputMessage("MSG_ANNOUNCE_RED", szMsg)
            -- SearchRobot:SendCustomMessage(szMsg, 2)
        end
    },
}



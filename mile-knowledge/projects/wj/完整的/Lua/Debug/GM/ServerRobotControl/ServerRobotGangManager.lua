-- 帮会设置相关界面和逻辑
ServerRobotGangManager = ServerRobotGangManager or {className = "ServerRobotGangManager"}

ServerRobotGangManager.szTitle = "设置帮会"
ServerRobotGangManager.tbGangSetting = {
    {
        szlabel = "创建帮会",
        bNeedBtn = true,
        tbSubPanel = {
            szTitle = "创建帮会",
            tbPanelConfig = {
                {
                    szText = "帮会名:",
                    nBtnType = BtnType.EdixtBox,
                    szKey = "szCreateTongName",
                    szDefaultValue = ""
                },
            },

        },
        tbCMDParams = {
            szCreateTongName = "",
        },
        fnCallBack = function (Params)
            local szTongName 		= "player.szName"
            if Params.szCreateTongName and Params.szCreateTongName ~= "" then
                szTongName = "\"".. Params.szCreateTongName .. "\""
            end
            local szMsg = string.format("g_m:player.AddMoney(10000,0,0)")
            SearchRobot:SendCustomMessage(szMsg, 2)
            szMsg = string.format("g_m:ApplyCreateTong(player.dwID,%s)", szTongName)
            SearchRobot:SendCustomMessage(szMsg, 2)
        end
    },
    {
        szlabel = "帮主邀请入帮",
        fnCallBack = function ()
            local  szMsg = string.format("custom:LY_InvitePlayerJoinTongByTongerMaster(%s, %d, %d)",
            UIHelper.UTF8ToGBK(SearchRobot.szRobotSuffixName), SearchRobot.szRobotIndex, SearchRobot.szRobotCount)
            OutputMessage("MSG_ANNOUNCE_RED", szMsg)
            SearchRobot:SendCustomMessage(szMsg, 2)
        end
    },
    {
        szlabel = "退出帮会",
        fnCallBack = function ()
            local  szMsg = string.format("custom:LY_QuitTong()")
            OutputMessage("MSG_ANNOUNCE_RED", szMsg)
            SearchRobot:SendCustomMessage(szMsg, 2)
        end
    },
    {
        szlabel = "扩充帮会人数",
        fnCallBack = function ()
            local  szMsg = string.format("g_m:GCCommand(\"GetTong(\"..player.dwTongID..\").SetMaxMemberCount(150)\")")
            OutputMessage("MSG_ANNOUNCE_RED", szMsg)
            SearchRobot:SendCustomMessage(szMsg, 2)
        end
    },
    {
        szlabel = "分发帮会联赛权限",
        fnCallBack = function ()
            local  szMsg = string.format("custom:LY_ModifyBaseOperationMask(14, 28, true)")
            OutputMessage("MSG_ANNOUNCE_RED", szMsg)
            SearchRobot:SendCustomMessage(szMsg, 2)
        end
    },
    {
        szlabel = "帮会联赛核心成员",
        fnCallBack = function ()
            local  szMsg = string.format("custom:LY_ModifyBaseOperationMask(14, 29, true)")
            OutputMessage("MSG_ANNOUNCE_RED", szMsg)
            SearchRobot:SendCustomMessage(szMsg, 2)
        end
    },
    {
        szlabel = "解散帮会",
        fnCallBack = function ()
            local  szMsg = string.format("g_m:local tid=player.dwTongID;GCCommand('local tong=GetTong('..tid..');DisbandTong(tong.szName)')")
            OutputMessage("MSG_ANNOUNCE_RED", szMsg)
            SearchRobot:SendCustomMessage(szMsg, 2)
        end
    },
    {
        szlabel = "邀请入帮",
        fnCallBack = function ()
            if SearchRobot.nChannel ~= PLAYER_TALK_CHANNEL.WHISPER then
                OutputMessage("MSG_ANNOUNCE_RED", "为防止误操作, 请选择指定机器人模式！")
                return
            end
            local player = GetClientPlayer()
            local eTargetType, dwID = player.GetTarget()
			if eTargetType == TARGET.PLAYER then
				local p = GetPlayer(dwID)
				OutputMessage("MSG_SYS", "邀请：" .. p.szName .. "入帮！\n")
				GetTongClient().InvitePlayerJoinTong(p.szName)
			else
                for index, szName in ipairs(SearchRobot.tbRobot) do
                    Timer.Add(ServerRobotGangManager, index, function ()
                        OutputMessage("MSG_SYS", "邀请：" .. szName .. "入帮！\n")
                        GetTongClient().InvitePlayerJoinTong(UIHelper.UTF8ToGBK(szName))
                    end)
                end
			end
        end
    },
    {
        szlabel = "创建帮会领地",
        fnCallBack = function ()
            local  szMsg = "g_m:GCCommand(string.format('GetTong(%d).SetCustomInteger1(43, 1)', player.dwTongID))"
            OutputMessage("MSG_ANNOUNCE_RED", szMsg)
            SearchRobot:SendCustomMessage(szMsg, 2)
        end
    },
    {
        szlabel = "进入帮会领地",
        fnCallBack = function ()
            local  szMsg = string.format("g_m:player.SwitchMap(74, player.dwTongID, 14855, 4650, 1099840)")
            OutputMessage("MSG_ANNOUNCE_RED", szMsg)
            SearchRobot:SendCustomMessage(szMsg, 2)
        end
    },
}



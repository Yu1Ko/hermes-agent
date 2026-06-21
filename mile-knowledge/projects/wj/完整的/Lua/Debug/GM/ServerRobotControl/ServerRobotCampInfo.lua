-- 阵营设置相关界面和逻辑
ServerRobotCampInfo = ServerRobotCampInfo or {}

ServerRobotCampInfo.szTitle = "设置阵营"
ServerRobotCampInfo.tbCampSetting = {
    {
        szlabel = "设置中立阵营",
        fnCallBack = function ()
            local  szMsg = string.format("g_m:player.SetCamp(0)")
            OutputMessage("MSG_ANNOUNCE_RED", szMsg)
            SearchRobot:SendCustomMessage(szMsg, 1)
        end
    },
    {
        szlabel = "设置浩气阵营",
        fnCallBack = function ()
            local  szMsg = string.format("g_m:player.SetCamp(1)")
            OutputMessage("MSG_ANNOUNCE_RED", szMsg)
            SearchRobot:SendCustomMessage(szMsg, 1)
        end
    },
    {
        szlabel = "设置恶人阵营",
        fnCallBack = function ()
            local  szMsg = string.format("g_m:player.SetCamp(2)")
            OutputMessage("MSG_ANNOUNCE_RED", szMsg)
            SearchRobot:SendCustomMessage(szMsg, 1)
        end
    },
    {
        szlabel = "开启阵营模式",
        fnCallBack = function ()
            local  szMsg = string.format("g_m:player.OpenCampFlag()")
            OutputMessage("MSG_ANNOUNCE_RED", szMsg)
            SearchRobot:SendCustomMessage(szMsg, 1)
        end
    },
    {
        szlabel = "均分阵营(浩气:恶人)",
        fnCallBack = function ()
            local  szMsg1 = string.format("g_m:player.SetCamp(1)")
            local  szMsg2 = string.format("g_m:player.SetCamp(2)")
            SearchRobot:SendCustomMessageAvg(szMsg1, szMsg2, 1)
        end
    }
}

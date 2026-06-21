-- Buff设置相关界面和逻辑
ServerRobotBufff = ServerRobotBufff or {}

ServerRobotBufff.szTitle = "Buff设置"
ServerRobotBufff.tbBuffSetting = {
    {
        szlabel = "战斗常用BUFF",
        fnCallBack = function ()
            local  szMsg = string.format("custom:LY_AddFilghtBuff()")
            OutputMessage("MSG_ANNOUNCE_RED", szMsg)
            SearchRobot:SendCustomMessage(szMsg, 2)
        end
    },
    {
        szlabel = "超级血量BUFF",
        fnCallBack = function ()
            local  szMsg = string.format("custom:LY_SuperLife()")
            OutputMessage("MSG_ANNOUNCE_RED", szMsg)
            SearchRobot:SendCustomMessage(szMsg, 2)
        end
    },
    {
        szlabel = "添加指定buff",
        bNeedBtn = true,
        tbSubPanel = {
            szTitle = "添加指定buff",
            tbPanelConfig = {
                {
                    szText = "BuffID:",
                    nBtnType = BtnType.EdixtBox,
                    szKey = "dwBuffID",
                    szDefaultValue = "203"
                },
                {
                    szText = "BuffLevel:",
                    nBtnType = BtnType.EdixtBox,
                    szKey = "nBuffLevel",
                    szDefaultValue = "1,100"
                },
                {
                    szText = "Count:",
                    nBtnType = BtnType.EdixtBox,
                    szKey = "nCount",
                    szDefaultValue = "1"
                },
            },

        },
        tbCMDParams = {
            dwBuffID = "203",
            nBuffLevel = "1,100",
            nCount = "1"
        },
        fnCallBack = function (tbBuffSettings)
            local szCmd = "for i=1,"..tbBuffSettings.nCount.." do player.AddBuff(player.dwID,player.nLevel,"..tbBuffSettings.dwBuffID..','..tbBuffSettings.nBuffLevel..") end"
            local szMsg  = string.format("g_m:%s", szCmd)
            OutputMessage("MSG_ANNOUNCE_RED", szMsg)
            SearchRobot:SendCustomMessage(szMsg, 2)
        end
    },
    {
        szlabel = "目标添加指定buff",
        bNeedBtn = true,
        tbSubPanel = {
            szTitle = "目标添加指定buff",
            tbPanelConfig = {
                {
                    szText = "BuffID:",
                    nBtnType = BtnType.EdixtBox,
                    szKey = "dwBuffID",
                    szDefaultValue = "203"
                },
                {
                    szText = "BuffLevel:",
                    nBtnType = BtnType.EdixtBox,
                    szKey = "nBuffLevel",
                    szDefaultValue = "1,100"
                },
                {
                    szText = "Count:",
                    nBtnType = BtnType.EdixtBox,
                    szKey = "nCount",
                    szDefaultValue = "1"
                },
            },

        },
        tbCMDParams = {
            dwBuffID = "203",
            nBuffLevel = "1,100",
            nCount = "1"
        },
        fnCallBack = function (tbBuffSettings)
            local szCmd = "for i=1,"..tbBuffSettings.nCount.." do player.GetSelectCharacter().AddBuff(player.dwID,player.nLevel,"..tbBuffSettings.dwBuffID..','..tbBuffSettings.nBuffLevel..") end"
            local szMsg  = string.format("g_m:%s", szCmd)
            OutputMessage("MSG_ANNOUNCE_RED", szMsg)
            SearchRobot:SendCustomMessage(szMsg, 2)
        end
    },
    {
        szlabel = "删除指定buff",
        bNeedBtn = true,
        tbSubPanel = {
            szTitle = "删除指定buff",
            tbPanelConfig = {
                {
                    szText = "BuffID:",
                    nBtnType = BtnType.EdixtBox,
                    szKey = "dwBuffID",
                    szDefaultValue = "203"
                },
                {
                    szText = "BuffLevel:",
                    nBtnType = BtnType.EdixtBox,
                    szKey = "nBuffLevel",
                    szDefaultValue = "1"
                },
                {
                    szText = "Count:",
                    nBtnType = BtnType.EdixtBox,
                    szKey = "nCount",
                    szDefaultValue = "1"
                },
            },

        },
        tbCMDParams = {
            dwBuffID = "203",
            nBuffLevel = "1",
            nCount = "1"
        },
        fnCallBack = function (tbBuffSettings)
            local szCmd = "for i=1,"..tbBuffSettings.nCount.." do player.DelBuff("..tbBuffSettings.dwBuffID..','..tbBuffSettings.nBuffLevel..") end"
            local szMsg  = string.format("g_m:%s", szCmd)
            OutputMessage("MSG_ANNOUNCE_RED", szMsg)
            SearchRobot:SendCustomMessage(szMsg, 2)
        end
    },
    {
        szlabel = "目标删除指定buff",
        bNeedBtn = true,
        tbSubPanel = {
            szTitle = "删除目标指定buff",
            tbPanelConfig = {
                {
                    szText = "BuffID:",
                    nBtnType = BtnType.EdixtBox,
                    szKey = "dwBuffID",
                    szDefaultValue = "203"
                },
                {
                    szText = "BuffLevel:",
                    nBtnType = BtnType.EdixtBox,
                    szKey = "nBuffLevel",
                    szDefaultValue = "1"
                },
                {
                    szText = "Count:",
                    nBtnType = BtnType.EdixtBox,
                    szKey = "nCount",
                    szDefaultValue = "1"
                },
            },

        },
        tbCMDParams = {
            dwBuffID = "203",
            nBuffLevel = "1",
            nCount = "1"
        },
        fnCallBack = function (tbBuffSettings)
            local szCmd = "for i=1,"..tbBuffSettings.nCount.." do player.GetSelectCharacter().DelBuff("..tbBuffSettings.dwBuffID..','..tbBuffSettings.nBuffLevel..") end"
            local szMsg  = string.format("g_m:%s", szCmd)
            OutputMessage("MSG_ANNOUNCE_RED", szMsg)
            SearchRobot:SendCustomMessage(szMsg, 2)
        end
    },
}



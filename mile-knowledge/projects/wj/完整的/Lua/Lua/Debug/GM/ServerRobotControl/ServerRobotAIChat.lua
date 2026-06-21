-- 帮会设置相关界面和逻辑
ServerRobotAIChat = ServerRobotAIChat or {className = "ServerRobotAIChat"}

ServerRobotAIChat.szTitle = "NPC聊天设置"
ServerRobotAIChat.tbAIChatSetting = {
    {
        szlabel = "选择聊天对象",
        bNeedBtn = true,
        tbSubPanel = {
            szTitle = "聊天对象",
            tbPanelConfig = {
                {
                    szText = "AIAgentID:",
                    nBtnType = BtnType.EdixtBox,
                    szKey = "nAIAgentID",
                    szDefaultValue = "1"
                },
                {
                    szText = "NpcTemplateID:",
                    nBtnType = BtnType.EdixtBox,
                    szKey = "dwNpcTemplateID",
                    szDefaultValue = ""
                },
                {
                    szText = "NpcID:",
                    nBtnType = BtnType.EdixtBox,
                    szKey = "dwNpcID",
                    szDefaultValue = ""
                },
                {
                    szText = "NpcName:",
                    nBtnType = BtnType.EdixtBox,
                    szKey = "szNpcName",
                    szDefaultValue = ""
                },
                {
                    szText = "聊天内容:",
                    nBtnType = BtnType.EdixtBox,
                    szKey = "szMessage",
                    szDefaultValue = ""
                },
            },
        },
        -- 改为获取用户指定的聊天内容
        tbCMDParams = {
            nAIAgentID = 1,
            dwNpcTemplateID = 0,
            dwNpcID = 0,
            szNpcName = "",
            szMessage = "",
        },
        fnCallBack = function (Params)
            local szNpcName = UIHelper.UTF8ToGBK(Params.szNpcName)
            local szMessage = UIHelper.UTF8ToGBK(Params.szMessage)
            szMessage = szMessage:gsub("[\t\r\n]+", " ")
            local szMsg = string.format(
                "g_m:player.AIAgentChatRequest(%d,%d,%d,'%s','%s')",
                Params.nAIAgentID, Params.dwNpcTemplateID, Params.dwNpcID, szNpcName, szMessage
            )
            SearchRobot:SendCustomMessage(szMsg, 2)
            ServerRobotAIChat.tbAIChatSetting[1].tbCMDParams = Params
        end
    },
}
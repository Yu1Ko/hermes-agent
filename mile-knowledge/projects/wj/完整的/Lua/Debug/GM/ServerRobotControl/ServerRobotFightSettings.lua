-- 战斗设置相关界面和逻辑
ServerRobotFightSettings = ServerRobotFightSettings or {}

ServerRobotFightSettings.szTitle = "战斗设置"
ServerRobotFightSettings.tbFightSettingSetting = {
    {
        szlabel = "设置秘籍",
        fnCallBack = function ()
            local  szMsg = string.format("custom:LY_RecipeInfoSet()")
            OutputMessage("MSG_ANNOUNCE_RED", szMsg)
            SearchRobot:SendCustomMessage(szMsg, 2)
        end
    },
    {
        szlabel = "检查秘籍",
        fnCallBack = function ()
            local  szMsg = string.format("custom:LY_CheckActiveRecipeSkill()")
            OutputMessage("MSG_ANNOUNCE_RED", szMsg)
            SearchRobot:SendCustomMessage(szMsg, 2)
        end
    },
    {
        szlabel = "设置奇穴",
        fnCallBack = function ()
            local  szMsg = string.format("端游和手游奇穴设计不同, 暂不支持此功能")
            OutputMessage("MSG_ANNOUNCE_RED", szMsg)
            -- SearchRobot:SendCustomMessage(szMsg, 2)
        end
    },
    {
        szlabel = "设置目标",
        fnCallBack = function ()
            local player = player or GetClientPlayer()
            local eTargetType, dwID = player.GetTarget()
            local szMsg = string.format("custom:SetTarget(%d, %d)", eTargetType, dwID)
            OutputMessage("MSG_ANNOUNCE_RED", szMsg)
            SearchRobot:SendCustomMessage(szMsg, 2)
        end
    },
    {
        szlabel = "开启战斗",
        fnCallBack = function ()
            local  szMsg = string.format("custom:LY_ActiveFight(1)")
            OutputMessage("MSG_ANNOUNCE_RED", szMsg)
            SearchRobot:SendCustomMessage(szMsg, 2)
        end
    },
    {
        szlabel = "结束战斗",
        fnCallBack = function ()
            local  szMsg = string.format("custom:LY_ActiveFight(0)")
            OutputMessage("MSG_ANNOUNCE_RED", szMsg)
            SearchRobot:SendCustomMessage(szMsg, 2)
        end
    },
    -- {
    --     szlabel = "开启随机打怪模式",
    --     fnCallBack = function ()
    --         local  szMsg = string.format("g_m:player.SetCamp(0)")
    --         OutputMessage("MSG_ANNOUNCE_RED", szMsg)
    --         SearchRobot:SendCustomMessage(szMsg, 2)
    --     end
    -- },
    {
        szlabel = "复活",
        fnCallBack = function ()
            local  szMsg = string.format("g_m:player.Revive();player.nCurrentLife=player.nMaxLife;player.nCurrentMana=player.nMaxMana")
            OutputMessage("MSG_ANNOUNCE_RED", szMsg)
            SearchRobot:SendCustomMessage(szMsg, 2)
        end
    },
    {
        szlabel = "满血满蓝",
        fnCallBack = function ()
            local  szMsg = string.format("custom:LY_SetLifeAndManaFull()")
            OutputMessage("MSG_ANNOUNCE_RED", szMsg)
            SearchRobot:SendCustomMessage(szMsg, 2)
        end
    },
    {
        szlabel = "自杀",
        fnCallBack = function ()
            local  szMsg = string.format("g_m:player.Die()")
            OutputMessage("MSG_ANNOUNCE_RED", szMsg)
            SearchRobot:SendCustomMessage(szMsg, 2)
        end
    },
    {
        szlabel = "清除技能CD",
        fnCallBack = function ()
            local  szMsg = string.format("custom:LY_ClearSkillCD()")
            OutputMessage("MSG_ANNOUNCE_RED", szMsg)
            SearchRobot:SendCustomMessage(szMsg, 2)
        end
    },
}

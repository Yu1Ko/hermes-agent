
--[[
注意 (0)：绑定KeyU盘只允许注册一个键位
注意 (1)：绑定KeyDown时KeyCode列表是有顺序的
注意 (2)：KeyCodeKey的枚举 @see cc.KeyCodeKey

调用示例：
KeyBoard.BindKeyDown({cc.KeyCodeKey.KEY_F1}, "显示/隐藏 GM窗口", function() end)
KeyBoard.BindKeyDown({cc.KeyCodeKey.KEY_F2}, "显示/隐藏 lua执行窗口", function() end)
KeyBoard.BindKeyDown({cc.KeyCodeKey.KEY_CTRL, cc.KeyCodeKey.KEY_Q}, "退出登录", function() end)
KeyBoard.BindKeyDown({cc.KeyCodeKey.KEY_CTRL, cc.KeyCodeKey.KEY_SHIFT, cc.KeyCodeKey.KEY_F}, "隐藏 FPS", function() end)

-- 注意BindKeyUp 只需要绑定一个键位
KeyBoard.BindKeyUp(cc.KeyCodeKey.KEY_TAB, "TABTAB UP", function() end)

]]


-- ========================================================================
-- bind key down
-- ========================================================================

--UI Debug点击工具
KeyBoard.BindKeyDown({cc.KeyCode.KEY_LEFT_ALT, cc.KeyCode.KEY_U}, "UIClickDebugger", function()
    if UIClickDebugger.IsEnabled() then
        UIClickDebugger.Disable()
        print("----------------UIClickDebugger Disabled----------------")
    else
        UIClickDebugger.Enable()
        print("----------------UIClickDebugger Enabled----------------")
    end
end)

KeyBoard.BindKeyDown({cc.KeyCode.KEY_LEFT_ALT, cc.KeyCode.KEY_F1}, "Alt + F1 GM界面", function ()
    GMHelper.OpenGM()
end)

KeyBoard.BindKeyDown({cc.KeyCode.KEY_LEFT_ALT, cc.KeyCode.KEY_F2}, "Alt + F2 单元测试", function ()
    package.loaded["Lua/Debug/Test.lua"] = nil
    require("Lua/Debug/Test.lua")
end)

KeyBoard.BindKeyDown({cc.KeyCode.KEY_LEFT_ALT, cc.KeyCode.KEY_F6}, "Alt + F6 GM搜索面板", function ()
    if UIMgr.GetView(VIEW_ID.PanelSearchPanel) then
        UIMgr.Close(VIEW_ID.PanelSearchPanel)
    else
        UIMgr.Open(VIEW_ID.PanelSearchPanel)
    end
end)

KeyBoard.BindKeyDown({cc.KeyCode.KEY_LEFT_ALT, cc.KeyCode.KEY_F7}, "Alt + F7 GM小球", function ()
    if UIMgr.IsViewOpened(VIEW_ID.PanelGMBall) then
        UIMgr.Close(VIEW_ID.PanelGMBall)
    else
        if Config.bGM then
            UIMgr.Open(VIEW_ID.PanelGMBall)
        end
    end
end)

KeyBoard.BindKeyDown({cc.KeyCode.KEY_LEFT_ALT, cc.KeyCode.KEY_F8}, "Alt + F8 重载测试", function()
    ReloadScript.Reload("Lua/Debug/ReloadCustomLogic")
end)

KeyBoard.BindKeyUp(cc.KeyCode.KEY_F9, "开关节点浏览器", function()
    local nViewID = VIEW_ID.PanelNodeExplorer
    local fn = UIMgr.GetView(nViewID) and UIMgr.Close or UIMgr.Open
    fn(nViewID)
end)

--KeyBoard.BindKeyDown({cc.KeyCode.KEY_CTRL, cc.KeyCode.KEY_F4}, "打开奇遇界面", function ()
--    UIMgr.Open(VIEW_ID.PanelQiYu)
--end)

KeyBoard.BindKeyDown({cc.KeyCode.KEY_CTRL, cc.KeyCode.KEY_F6}, "打开战场数据UI", function ()
    local tBattleFieldInfo = {
    tPraiseList = {},
    nBanishTime = GetCurrentTime() + 60,
    nClientPlayerSide = 1,
    nRewardExp = 0,
    tStatistics = {
        {
            [1] = 0,[2] = 0,[3] = 0,[4] = 0,[5] = 0,[6] = 0,[7] = 0,[8] = 0,[9] = 0,[10] = 5,
            [11] = 236,[12] = 0,[13] = 0,[14] = 0,[15] = 0,[16] = 2772,[17] = 200,[18] = 0,[19] = 0,[20] = 0,
            [21] = 2,[22] = 0,[23] = 0,[24] = 1,[0] = 0,["nExcellentCount"] = 12,["BattleFieldSide"] = 1,
            ["ForceID"] = 3,["nBattleFieldSide"] = 2,["dwPlayerID"] = 5,["Name"] = UTF8ToGBK("测"),["GlobalID"] = GetClientPlayer().GetGlobalID()
        },
        {
            [1] = 0,[2] = 0,[3] = 0,[4] = 0,[5] = 0,[6] = 0,[7] = 0,[8] = 0,[9] = 0,[10] = 0,
            [11] = 0,[12] = 0,[13] = 0,[14] = 0,[15] = 0,[16] = 56,[17] = 200,[18] = 0,[19] = 0,[20] = 0,
            [21] = 2,[22] = 0,[23] = 0,[24] = 1,[0] = 0,["nExcellentCount"] = 1,["BattleFieldSide"] = 0,
            ["ForceID"] = 3,["nBattleFieldSide"] = 1,["dwPlayerID"] = GetClientPlayer().dwID,["Name"] = UTF8ToGBK("测试"),["GlobalID"] = GetClientPlayer().GetGlobalID()
        },
        {
            [1] = 0,[2] = 0,[3] = 0,[4] = 0,[5] = 0,[6] = 0,[7] = 0,[8] = 0,[9] = 0,[10] = 5,
            [11] = 236,[12] = 0,[13] = 0,[14] = 0,[15] = 0,[16] = 2772,[17] = 200,[18] = 0,[19] = 0,[20] = 0,
            [21] = 2,[22] = 0,[23] = 0,[24] = 1,[0] = 0,["nExcellentCount"] = 12,["BattleFieldSide"] = 1,
            ["ForceID"] = 3,["nBattleFieldSide"] = 2,["dwPlayerID"] = 101,["Name"] = UTF8ToGBK("测试测"),["GlobalID"] = GetClientPlayer().GetGlobalID()
        },
        {
            [1] = 0,[2] = 0,[3] = 0,[4] = 0,[5] = 0,[6] = 0,[7] = 0,[8] = 0,[9] = 0,[10] = 5,
            [11] = 236,[12] = 0,[13] = 0,[14] = 0,[15] = 0,[16] = 2772,[17] = 200,[18] = 0,[19] = 0,[20] = 0,
            [21] = 2,[22] = 0,[23] = 0,[24] = 1,[0] = 0,["nExcellentCount"] = 12,["BattleFieldSide"] = 1,
            ["ForceID"] = 3,["nBattleFieldSide"] = 2,["dwPlayerID"] = 102,["Name"] = UTF8ToGBK("测试测试"),["GlobalID"] = GetClientPlayer().GetGlobalID()
        },
        {
            [1] = 0,[2] = 0,[3] = 0,[4] = 0,[5] = 0,[6] = 0,[7] = 0,[8] = 0,[9] = 0,[10] = 5,
            [11] = 236,[12] = 0,[13] = 0,[14] = 0,[15] = 0,[16] = 2772,[17] = 200,[18] = 0,[19] = 0,[20] = 0,
            [21] = 2,[22] = 0,[23] = 0,[24] = 1,[0] = 0,["nExcellentCount"] = 12,["BattleFieldSide"] = 1,
            ["ForceID"] = 3,["nBattleFieldSide"] = 2,["dwPlayerID"] = 103,["Name"] = UTF8ToGBK("测试测试测"),["GlobalID"] = GetClientPlayer().GetGlobalID()
        },
        {
            [1] = 0,[2] = 0,[3] = 0,[4] = 0,[5] = 0,[6] = 0,[7] = 0,[8] = 0,[9] = 0,[10] = 5,
            [11] = 236,[12] = 0,[13] = 0,[14] = 0,[15] = 0,[16] = 2772,[17] = 200,[18] = 0,[19] = 0,[20] = 0,
            [21] = 2,[22] = 0,[23] = 0,[24] = 1,[0] = 0,["nExcellentCount"] = 12,["BattleFieldSide"] = 1,
            ["ForceID"] = 3,["nBattleFieldSide"] = 2,["dwPlayerID"] = 104,["Name"] = UTF8ToGBK("测试测试测试"),["GlobalID"] = GetClientPlayer().GetGlobalID()
        },
        {
            [1] = 0,[2] = 0,[3] = 0,[4] = 0,[5] = 0,[6] = 0,[7] = 0,[8] = 0,[9] = 0,[10] = 5,
            [11] = 236,[12] = 0,[13] = 0,[14] = 0,[15] = 0,[16] = 2772,[17] = 200,[18] = 0,[19] = 0,[20] = 0,
            [21] = 2,[22] = 0,[23] = 0,[24] = 1,[0] = 0,["nExcellentCount"] = 12,["BattleFieldSide"] = 1,
            ["ForceID"] = 3,["nBattleFieldSide"] = 2,["dwPlayerID"] = 105,["Name"] = UTF8ToGBK("测试测试测试测"),["GlobalID"] = GetClientPlayer().GetGlobalID()
        },
        {
            [1] = 0,[2] = 0,[3] = 0,[4] = 0,[5] = 0,[6] = 0,[7] = 0,[8] = 0,[9] = 0,[10] = 5,
            [11] = 236,[12] = 0,[13] = 0,[14] = 0,[15] = 0,[16] = 2772,[17] = 200,[18] = 0,[19] = 0,[20] = 0,
            [21] = 2,[22] = 0,[23] = 0,[24] = 1,[0] = 0,["nExcellentCount"] = 12,["BattleFieldSide"] = 1,
            ["ForceID"] = 3,["nBattleFieldSide"] = 2,["dwPlayerID"] = 106,["Name"] = UTF8ToGBK("测试测试测试测试"),["GlobalID"] = GetClientPlayer().GetGlobalID()
        },
        {
            [1] = 0,[2] = 0,[3] = 0,[4] = 0,[5] = 0,[6] = 0,[7] = 0,[8] = 0,[9] = 0,[10] = 5,
            [11] = 236,[12] = 0,[13] = 0,[14] = 0,[15] = 0,[16] = 2772,[17] = 200,[18] = 0,[19] = 0,[20] = 0,
            [21] = 2,[22] = 0,[23] = 0,[24] = 1,[0] = 0,["nExcellentCount"] = 12,["BattleFieldSide"] = 1,
            ["ForceID"] = 3,["nBattleFieldSide"] = 2,["dwPlayerID"] = 107,["Name"] = UTF8ToGBK("测试测试测试测试测"),["GlobalID"] = GetClientPlayer().GetGlobalID()
        },
        {
            [1] = 0,[2] = 0,[3] = 0,[4] = 0,[5] = 0,[6] = 0,[7] = 0,[8] = 0,[9] = 0,[10] = 5,
            [11] = 236,[12] = 0,[13] = 0,[14] = 0,[15] = 0,[16] = 2772,[17] = 200,[18] = 0,[19] = 0,[20] = 0,
            [21] = 2,[22] = 0,[23] = 0,[24] = 1,[0] = 0,["nExcellentCount"] = 12,["BattleFieldSide"] = 1,
            ["ForceID"] = 3,["nBattleFieldSide"] = 2,["dwPlayerID"] = 108,["Name"] = UTF8ToGBK("测试测试测试测试测试"),["GlobalID"] = GetClientPlayer().GetGlobalID()
        },
        {
            [1] = 0,[2] = 0,[3] = 0,[4] = 0,[5] = 0,[6] = 0,[7] = 0,[8] = 0,[9] = 0,[10] = 5,
            [11] = 236,[12] = 0,[13] = 0,[14] = 0,[15] = 0,[16] = 2772,[17] = 200,[18] = 0,[19] = 0,[20] = 0,
            [21] = 2,[22] = 0,[23] = 0,[24] = 1,[0] = 0,["nExcellentCount"] = 12,["BattleFieldSide"] = 0,
            ["ForceID"] = 3,["nBattleFieldSide"] = 1,["dwPlayerID"] = 109,["Name"] = "Player",["GlobalID"] = GetClientPlayer().GetGlobalID()
        },
        {
            [1] = 0,[2] = 0,[3] = 0,[4] = 0,[5] = 0,[6] = 0,[7] = 0,[8] = 0,[9] = 0,[10] = 5,
            [11] = 236,[12] = 0,[13] = 0,[14] = 0,[15] = 0,[16] = 2772,[17] = 200,[18] = 0,[19] = 0,[20] = 0,
            [21] = 2,[22] = 0,[23] = 0,[24] = 1,[0] = 0,["nExcellentCount"] = 12,["BattleFieldSide"] = 0,
            ["ForceID"] = 3,["nBattleFieldSide"] = 1,["dwPlayerID"] = 110,["Name"] = "Player1",["GlobalID"] = GetClientPlayer().GetGlobalID()
        },
        {
            [1] = 0,[2] = 0,[3] = 0,[4] = 0,[5] = 0,[6] = 0,[7] = 0,[8] = 0,[9] = 0,[10] = 5,
            [11] = 236,[12] = 0,[13] = 0,[14] = 0,[15] = 0,[16] = 2772,[17] = 200,[18] = 0,[19] = 0,[20] = 0,
            [21] = 2,[22] = 0,[23] = 0,[24] = 1,[0] = 0,["nExcellentCount"] = 12,["BattleFieldSide"] = 0,
            ["ForceID"] = 3,["nBattleFieldSide"] = 1,["dwPlayerID"] = 111,["Name"] = "Player12",["GlobalID"] = GetClientPlayer().GetGlobalID()
        },
        {
            [1] = 0,[2] = 0,[3] = 0,[4] = 0,[5] = 0,[6] = 0,[7] = 0,[8] = 0,[9] = 0,[10] = 5,
            [11] = 236,[12] = 0,[13] = 0,[14] = 0,[15] = 0,[16] = 2772,[17] = 200,[18] = 0,[19] = 0,[20] = 0,
            [21] = 2,[22] = 0,[23] = 0,[24] = 1,[0] = 0,["nExcellentCount"] = 12,["BattleFieldSide"] = 0,
            ["ForceID"] = 3,["nBattleFieldSide"] = 1,["dwPlayerID"] = 112,["Name"] = "Player13",["GlobalID"] = GetClientPlayer().GetGlobalID()
        },
        {
            [1] = 0,[2] = 0,[3] = 0,[4] = 0,[5] = 0,[6] = 0,[7] = 0,[8] = 0,[9] = 0,[10] = 5,
            [11] = 236,[12] = 0,[13] = 0,[14] = 0,[15] = 0,[16] = 2772,[17] = 200,[18] = 0,[19] = 0,[20] = 0,
            [21] = 2,[22] = 0,[23] = 0,[24] = 1,[0] = 0,["nExcellentCount"] = 12,["BattleFieldSide"] = 0,
            ["ForceID"] = 3,["nBattleFieldSide"] = 1,["dwPlayerID"] = 113,["Name"] = "Player14",["GlobalID"] = GetClientPlayer().GetGlobalID()
        },
    },
    dwLeaderID = 11,
    nRewardMoney = 0,
    tAddPreiseList = {},
    bWin = false,
    tMyData = {
        [1] = 0,
        [2] = 0,
        [3] = 0,
        [4] = 0,
        [5] = 0,
        [6] = 0,
        [7] = 0,
        [8] = 0,
        [9] = 0,
        [10] = 0,
        [11] = 0,
        [12] = 0,
        [13] = 0,
        [14] = 0,
        [15] = 0,
        [16] = 56,
        [17] = 200,
        [18] = 0,
        [19] = 0,
        [20] = 0,
        [21] = 3,
        [22] = 2,
        [23] = 0,
        [24] = 1,
        [0] = 0,
        ["nExcellentCount"] = 1,
        ["BattleFieldSide"] = 0,
        ["ForceID"] = 3,
        ["nBattleFieldSide"] = 1,
        ["dwPlayerID"] = GetClientPlayer().dwID,
        ["Name"] = "Player2"
    },
    dwMapID = 135,
    bOpenWinOrDefect = false,
    tExcellentData = {
        [GetClientPlayer().dwID] = {
            [1] = 3,
        },
        [5] = {3,4,5,6,7,8,10,11,12,13,14,15}
    },
    bUpdateRecord = false,
    bBattleFieldEnd = true,
    }

    --BattleFieldData.OnNewPlayerBFEnd(tStatistics, nBanishTime, tExcellentData, bWin)
    UIMgr.Open(VIEW_ID.PanelPVPFieldSettleData, true, tBattleFieldInfo, {[1]="Team1",[2]="Team2"})
end)

KeyBoard.BindKeyDown({cc.KeyCode.KEY_CTRL, cc.KeyCode.KEY_F7}, "进入拭剑园战场", function ()
    SendGMCommand("player.SwitchMap(293, 100, 100, 100)")
end)

KeyBoard.BindKeyDown({cc.KeyCode.KEY_CTRL, cc.KeyCode.KEY_F10}, "打开阵营结算界面", function ()
    local tRewardInfo = {[1] = {}, [2] = {}, nInfoID = 2}
    for i = 1, 2 do 
        local nCount = i == 1 and 10 or 20
        tRewardInfo[i].Score = {
            {nType = 11, szCount = nCount, nScore = nCount * 400},
            {nType = 12, szCount = nCount, nScore = nCount * 100},
            {nType = 13, szCount = nCount, nScore = nCount * 600},
            {nType = 14, szCount = nCount, nScore = nCount * 10000},
            {nType = 15, szCount = 1, nScore = i == 0 and 0 or - 1 * 11000},
            {nType = 16, szCount = i == 1 and UTF8ToGBK("达成") or UTF8ToGBK("未达成"), nScore = 0 * 5000},
            {nType = 17, szCount = i == 1 and UTF8ToGBK("达成") or UTF8ToGBK("未达成"), nScore =0 * 7000},
            {nType = 18, szCount = i == 1 and UTF8ToGBK("达成") or UTF8ToGBK("未达成"), nScore = 0 * 5000},
            {nType = 19, szCount = 0 == 1 and UTF8ToGBK("达成") or UTF8ToGBK("未达成"), nScore = nCount == 0 and 0 or - nCount * 1000},
            {nType = 20, szCount = 0 == 1 and UTF8ToGBK("达成") or UTF8ToGBK("未达成"), nScore = nCount == 0 and 0 or - nCount * 5000},
        }
        tRewardInfo[i].Reward = {
            Personal = {
                nPrestige = 10000, nTitlePoint = 1000,
                tItem = {{5, 30712, 20}, }
            },
            Tong = {tItem = {{5, 36996, 100}}}
        }
    end
    
    local tUIMsgInfo = {
        -- {11, 12, 13, 14, 15},
        -- {16, 17, 18, 19, 20},
        -- {11, 12, 13, 14},
        -- {16, 17, 18, 19},
        {11, 12, 13, 14, 15, 16},
        {17, 18, 19, 20},
    }

    local tSneakWarInfo = {[1] = {}, [2] = {}, nInfoID = 2}
    for i = 1, 2 do 
        local nCount = 11
        tSneakWarInfo[i].Score = {
            {nType = 11, szCount = nCount, nScore = nCount * 400},
            {nType = 12, szCount = nCount, nScore = nCount * 100},
            {nType = 13, szCount = nCount, nScore = nCount * 600},
            {nType = 14, szCount = nCount, nScore = nCount * 10000},
            {nType = 15, szCount = 1, nScore = i == 0 and 0 or - 1 * 11000},
            {nType = 16, szCount = i == 1 and UTF8ToGBK("达成") or UTF8ToGBK("未达成"), nScore = 0 * 5000},
            {nType = 17, szCount = i == 1 and UTF8ToGBK("达成") or UTF8ToGBK("未达成"), nScore =0 * 7000},
            {nType = 18, szCount = i == 1 and UTF8ToGBK("达成") or UTF8ToGBK("未达成"), nScore = 0 * 5000},
            {nType = 19, szCount = 0 == 1 and UTF8ToGBK("达成") or UTF8ToGBK("未达成"), nScore = nCount == 0 and 0 or - nCount * 1000},
            {nType = 20, szCount = 0 == 1 and UTF8ToGBK("达成") or UTF8ToGBK("未达成"), nScore = nCount == 0 and 0 or - nCount * 5000},
        }
        tSneakWarInfo[i].Reward = {
            Personal = {
                nPrestige = 0, nTitlePoint = 0,
                tItem = {}
            },
        }
    end
    
    local tSneakUIMsgInfo = {
        -- {11, 12, 13, 14, 15},
        -- {16, 17, 18, 19, 20},
        -- {11, 12, 13, 14},
        -- {16, 17, 18, 19},
        {11, 12, 13, 14, 15, 16},
        {17, 18, 19, 20},
    }

    local tTongMoney = {nGold = 1000, nSilver = 0, nCopper = 0}
    RemoteFunction.On_Castle_ActivityEnd(tUIMsgInfo, tRewardInfo, tSneakUIMsgInfo, tSneakWarInfo, true, 500, tTongMoney)
end)

KeyBoard.BindKeyDown({cc.KeyCode.KEY_CTRL, cc.KeyCode.KEY_Q}, "返回登录", function ()
    if g_pClientPlayer and g_pClientPlayer.bFightState then
        LOG.INFO("在战斗状态中, 不可退出")
    else
        Global.BackToLogin(false)
    end
end)

KeyBoard.BindKeyDown({cc.KeyCode.KEY_0}, "清除CD", function ()
    SendGMCommand("player.CastSkill(613,1)")
end)

KeyBoard.BindKeyDown({cc.KeyCode.KEY_LEFT_ALT, cc.KeyCode.KEY_K}, "杀死目标", function ()
    SendGMCommand("player.GetSelectCharacter().Die()")
end)

KeyBoard.BindKeyDown({cc.KeyCode.KEY_LEFT_ALT, cc.KeyCode.KEY_C}, "隐藏|显示镜头编辑工具", function ()
    if UIMgr.GetView(VIEW_ID.PanelCameraEditor) then
        UIMgr.Close(VIEW_ID.PanelCameraEditor)
        UITouchHelper.ExitEditMode()
        return
    end

    UIMgr.Open(VIEW_ID.PanelCameraEditor)
    UITouchHelper.EnterEditMode()
end)
-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: HotkeyCommand
-- Date: 2024-02-21 10:51:00
-- Desc: 全局热键功能
-- ---------------------------------------------------------------------------------

HotkeyCommand = HotkeyCommand or {className = "HotkeyCommand"}
local self = HotkeyCommand

HotkeyCommand.tCommandMap = {
    --ID对应UIShortcutInteractionTab中Hotkey类型的paramArgs
    [1] = {
        fnDown = function()
            if not SystemOpen.IsSystemOpen(SystemOpenDef.Walk, true) then
                return
            end

            --切换走路/跑步
            APIHelper.SwitchWalk()
        end,
    },
    [2] = {
        fnDown = function()
            --跟随目标
            FollowTarget()
        end,
    },
    [3] = {
        fnDown = function()
            --选择自己
            SelectPlayer()
        end,
    },
    [4] = {
        fnDown = function()
            --选择队友1
            TeamData.SelectTeammate(1)
        end,
    },
    [5] = {
        fnDown = function()
            --选择队友2
            TeamData.SelectTeammate(2)
        end,
    },
    [6] = {
        fnDown = function()
            --选择队友3
            TeamData.SelectTeammate(3)
        end,
    },
    [7] = {
        fnDown = function()
            --选择队友4
            TeamData.SelectTeammate(4)
        end,
    },
    [8] = {
        fnDown = function()
            --选择盟友
            SearchAllies()
        end,
    },
    [9] = {
        fnDown = function()
            --重置镜头
            CameraMgr.CamaraReset()
        end,
    },
    [10] = {
        fnDown = function()
            --显示/隐藏NPC
            APIHelper.SetNpcDisplay()
        end,
    },
    [11] = {
        fnDown = function()
            if not SystemOpen.IsSystemOpen(SystemOpenDef.WanJia, true) then
                return
            end

            --切换玩家显示模式
            local tPlayDisplaySetting = APIHelper.GetPlayDisplay()
            if tPlayDisplaySetting.szDec == GameSettingType.PlayDisplay.All.szDec then
                APIHelper.SetPlayDisplay(GameSettingType.PlayDisplay.OnlyPartyPlay, true)
            elseif tPlayDisplaySetting.szDec == GameSettingType.PlayDisplay.OnlyPartyPlay.szDec then
                APIHelper.SetPlayDisplay(GameSettingType.PlayDisplay.HideAll, true)
            elseif tPlayDisplaySetting.szDec == GameSettingType.PlayDisplay.HideAll.szDec then
                APIHelper.SetPlayDisplay(GameSettingType.PlayDisplay.All, true)
            end
        end,
    },
    [12] = {
        fnDown = function()
            --语音按键说话 按下
            --GVoiceMgr.OpenMic()
        end,
        fnUp = function()
            --语音按键说话 抬起
            --GVoiceMgr.CloseMic()
        end,
    },
    [13] = {
        fnDown = function()
            --侠客攻击
            --Partner_OrderAttack()
            SkillData.CastSkill(g_pClientPlayer, 31336, nil, 1)
        end,
    },
    [14] = {
        fnDown = function()
            --侠客跟随
            --Partner_OrderFollow()
            SkillData.CastSkill(g_pClientPlayer, 31337, nil, 1)
        end,
    },
    [15] = {
        fnDown = function()
            --侠客停留
            --Partner_OrderStop()
            SkillData.CastSkill(g_pClientPlayer, 31338, nil, 1)
        end,
    },
    [16] = {
        fnDown = function()
            --显示/隐藏界面
            if UIMgr.IsHideAllLayer() then
                UIHelper.ExitHideAllUIMode()
            else
                UIHelper.EnterHideAllUIMode()
            end
        end
    },
    [17] = {
        fnDown = function()
            --自动前进
            FuncSlotMgr.ExecuteCommand("AutoForward")
        end
    },
    [18] = {
        fnDown = function()
            --控制鼠标不可离开游戏窗口
            local bFlag = SetClipCursor()
            local szMsg = bFlag and "游戏鼠标已锁定在窗口内，无法移出游戏窗口" or "游戏鼠标可自由移动，可移出游戏窗口"
            TipsHelper.ShowNormalTip(szMsg)
        end
    },
    [19] = {
        fnDown = function()
            --侠客开战
            Event.Dispatch(EventType.On_Partner_TankAttack)
        end
    },
    [20] = {
        fnDown = function()
            --推进镜头
            local bHandled = cc.utils:getMouseWheelHandled()
            Event.Dispatch(EventType.OnHotkeyCameraZoom, 120, bHandled)
        end
    },
    [21] = {
        fnDown = function()
            --拉远镜头
            local bHandled = cc.utils:getMouseWheelHandled()
            Event.Dispatch(EventType.OnHotkeyCameraZoom, -120, bHandled)
        end
    },
    [22] = {
        fnDown = function()
            Camera_EnableControl(ControlDef.CONTROL_UP, true)
        end,
        fnUp = function()
            Camera_EnableControl(ControlDef.CONTROL_UP, false)
        end
    },
    [23] = {
        fnDown = function()
            Camera_EnableControl(ControlDef.CONTROL_DOWN, true)
        end,
        fnUp = function()
            Camera_EnableControl(ControlDef.CONTROL_DOWN, false)
        end
    },
}

function HotkeyCommand.ExecuteKeyDownCommand(nID, ...)
    local fn = self.GetKeyDownCommand(nID)
    if fn then
        fn(...)
    end
end

function HotkeyCommand.ExecuteKeyUpCommand(nID, ...)
    local fn = self.GetKeyUpCommand(nID)
    if fn then
        fn(...)
    end
end

function HotkeyCommand.GetKeyDownCommand(nID)
    return self.tCommandMap[nID] and self.tCommandMap[nID].fnDown
end

function HotkeyCommand.GetKeyUpCommand(nID)
    return self.tCommandMap[nID] and self.tCommandMap[nID].fnUp
end
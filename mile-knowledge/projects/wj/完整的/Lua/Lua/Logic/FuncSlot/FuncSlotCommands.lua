local FuncSlotCommands = { className = "FuncSlotCommands" }
local self = FuncSlotCommands

local BUFF_BUSINESS = 7732
local BUFF_BUSINESS_RIDE = 7682

function FuncSlotCommands.Init()

end

function FuncSlotCommands.UnInit()

end

--2023.9.4 轻功/技能界面相关逻辑已移至SprintData.lua中

-------------------------------- Commands --------------------------------

function FuncSlotCommands.StartSprint(bButton)
    if bButton and g_pClientPlayer and g_pClientPlayer.IsHaveBuff(BUFF_BUSINESS, 1) then
        if not UIMgr.IsViewOpened(VIEW_ID.PanelTradeMessagePop) then
            UIMgr.Open(VIEW_ID.PanelTradeMessagePop)
        end
        return
    end

    SprintData.StartSprint()
end

function FuncSlotCommands.EndSprint()
    SprintData.EndSprint()
end

function FuncSlotCommands.ForceEndSprint()
    SprintData.EndSprint(true)
end

function FuncSlotCommands.AutoForward()
    local bAutoForward = SprintData.GetAutoForward()
    SprintData.SetAutoForward(not bAutoForward)
end

function FuncSlotCommands.Transfer(bButton)
    if bButton and g_pClientPlayer and g_pClientPlayer.IsHaveBuff(BUFF_BUSINESS, 1) then
        if not UIMgr.IsViewOpened(VIEW_ID.PanelTradeMessagePop) then
            UIMgr.Open(VIEW_ID.PanelTradeMessagePop)
        end
        return
    end

    --退出轻功后过1s才能神行，防止误触
    if GetTickCount() - SprintData.GetExitSprintTime() < 1000 then
        return
    end

    if PVPFieldData.IsInPVPField() then
        PVPFieldData.LeavePVPField()
        return
    end

    if BattleFieldData.IsInBattleField() or ArenaData.IsInArena() then
        TipsHelper.ShowImportantRedTip("当前场景无法使用神行")
        return -- 无法使用神行
    end

    if OBDungeonData.IsPlayerInOBDungeon() then
        return -- 无法使用神行
    end

    if g_pClientPlayer and g_pClientPlayer.nLevel >= 108 then
        local fnCallback = function()
            if not UIMgr.GetView(VIEW_ID.PanelWorldMap) then
                local script = UIMgr.Open(VIEW_ID.PanelWorldMap)
                script:SetIsTrafficNodeSkill(true)
                TipsHelper.ShowNormalTip("请选择地图进行神行传送")
            end
        end

        MapMgr.CheckTransferCDExecute(fnCallback)
    else
        TipsHelper.ShowNormalTip("侠士达到108级后方可进行神行")
    end
end


--同时进入战斗界面
function FuncSlotCommands.Fight()
    if g_pClientPlayer.IsHaveBuff(12024, 1) then
        return
    end
    SprintData.SetViewState(false)
end

--切换轻功/技能面板（或七秀结束剑舞）
function FuncSlotCommands.SwitchSkill()
    Event.Dispatch(EventType.OnShortcutSwitchSkill)
end

--通用急降
function FuncSlotCommands.Drop()
    SprintData.Drop()
end

--续飞
function FuncSlotCommands.ReFly()
    SprintData.ReFly()
end

function FuncSlotCommands.Jump()
    --在马上自动寻路时，点跳跃退出寻路
    if g_pClientPlayer and g_pClientPlayer.bOnHorse and g_pClientPlayer.bInNav then
        AutoNav.StopNav()
    end

    Jump()
end

-- function FuncSlotCommands.EndJump()
--     EndJump()
-- end

--打坐/起身
function FuncSlotCommands.Meditation()
    ToggleSitDown()
end

--暗器
function FuncSlotCommands.Arrow()
    OnUseSkill(34, 1)
end

--上马
function FuncSlotCommands.RideHorse(bButton)
    if bButton and SelfieData.IsInFreeAnimation() then
        return
    end

    if bButton and g_pClientPlayer and g_pClientPlayer.IsHaveBuff(BUFF_BUSINESS_RIDE, 1) and g_pClientPlayer.IsHaveBuff(BUFF_BUSINESS, 1) then
        if not UIMgr.IsViewOpened(VIEW_ID.PanelTradeMessagePop) then
            UIMgr.Open(VIEW_ID.PanelTradeMessagePop)
        end
        return
    end
    
    RideHorse()
end

--下马
function FuncSlotCommands.DownHorse()
    -- 玩家有定格动画，则不作操作
    if SelfieData.IsInFreeAnimation() then
        return
    end
    RideHorse() --若玩家在马上，这个RideHorse()中的判断会让玩家下马
end

--翻身上马
function FuncSlotCommands.MountHorse()
    -- 玩家有定格动画，则不作操作
    if SelfieData.IsInFreeAnimation() then
        return
    end
    local dwSkillID = 21023
    OnUseSkill(dwSkillID, (dwSkillID * (dwSkillID % 10 + 1)))
end

--下马牵行
function FuncSlotCommands.HoldHorse()
    -- 玩家有定格动画，则不作操作
    if SelfieData.IsInFreeAnimation() then
        return
    end
    local dwSkillID = 21024
    OnUseSkill(dwSkillID, (dwSkillID * (dwSkillID % 10 + 1)))
end

--双人同骑
function FuncSlotCommands.RideTogether()
    -- 玩家有定格动画，则不作操作
    if SelfieData.IsInFreeAnimation() then
        return
    end
    local dwSkillID = 4104
    local nSkillResult = OnUseSkill(dwSkillID, (dwSkillID * (dwSkillID % 10 + 1)))
    if nSkillResult == SKILL_RESULT_CODE.SUCCESS then
        TipsHelper.ShowNormalTip("正在尝试邀请对方双人同骑")
    end
end

--传功
function FuncSlotCommands.TransmissionPower()
    local player = GetClientPlayer()
    if not player then
        return
    end

    local dwTargetType, dwTargetID = player.GetTarget()
    if dwTargetType ~= TARGET.PLAYER or dwTargetID == player.dwID then
        return
    end

    local targetPlayer = GetPlayer(dwTargetID)
    if not targetPlayer then
        return
    end

    if player.nLevel < 110 then
        TipsHelper.ShowNormalTip("侠士达到110级后方可传功")
    elseif targetPlayer.nLevel < 110 then
        TipsHelper.ShowNormalTip("对方等级低于110级，不能传功")
    -- elseif CrossMgr.IsCrossing(nil, true) then
    --     -- do nothing
    else
        local dwSkillID = 35
        OnUseSkill(dwSkillID, (dwSkillID * (dwSkillID % 10 + 1)))
    end
end

--浪客行上马
function FuncSlotCommands.LangKeXingRideHorse()
    local dwSkillID = 27419
    OnUseSkill(dwSkillID, (dwSkillID * (dwSkillID % 10 + 1)))
end

--浪客行回城
function FuncSlotCommands.LangKeXingReturnCity()
    local dwSkillID = 26572
    OnUseSkill(dwSkillID, (dwSkillID * (dwSkillID % 10 + 1)))
end

--马车下马
function FuncSlotCommands.StopAutoFly()
    ForceEndRoadTrack()
    if g_pClientPlayer.bInNav then
        g_pClientPlayer.NavStop()
    end
end

--明教上飞
function FuncSlotCommands.MingJiaoJumpUp()
    local player = GetClientPlayer()
    if not player then
        return
    end

    --方向范围[0,64],[192,256]，其中0和256是正前方，64是正上方，192是正下方
    player.SetNextSprintFlashPitchDirection(32);
    Jump()
end

--明教下飞
function FuncSlotCommands.MingJiaoJumpDown()
    local player = GetClientPlayer()
    if not player then
        return
    end

    player.SetNextSprintFlashPitchDirection(256 - 32);
    Jump()
end

--明教轻功-简化
function FuncSlotCommands.MingJiaoJump_Simple()
    local player = GetClientPlayer()
    if not player then
        return
    end

    --四段：上飞-上飞-平飞-下飞
    if player.nJumpCount == 1 then
        player.SetNextSprintFlashPitchDirection(32);
    elseif player.nJumpCount == 2 then
        player.SetNextSprintFlashPitchDirection(48);
    elseif player.nJumpCount == 3 then
        player.SetNextSprintFlashPitchDirection(8);
    elseif player.nJumpCount == 4 then

        local function _checkShowView()
            local player = GetClientPlayer()
            if not player or player.nMoveState == MOVE_STATE.ON_DEATH then
                return
            end
            if not player.bSprintFlag or player.nJumpCount == 0 then
                Event.Dispatch(EventType.OnSetBottomRightAnchorVisible, true)
                return
            end
            Timer.AddFrame(self, 1, _checkShowView)
        end

        player.SetNextSprintFlashPitchDirection(8);
        --Event.Dispatch(EventType.OnSetBottomRightAnchorVisible, false) --第四段后隐藏UI，类似通用急降
        --_checkShowView()
    end

    Jump()
end

--开始连冲
function FuncSlotCommands.StartDash()
    SprintData.EnterSpecialState(SPRINT_SPEICAL_STATE.Dash)
end

--开始明教前飘
function FuncSlotCommands.StartMingJiaoFloat()
    SprintData.EnterSpecialState(SPRINT_SPEICAL_STATE.MingJiao_Float)
end

--结束特殊轻功状态
function FuncSlotCommands.ExitSpecialState()
    SprintData.ExitSpecialState()
end

-- 帮会联赛 回城
function FuncSlotCommands.TongWar_BackToBase()
    RemoteCallToServer("On_TongWar_BackToBase")
end

function FuncSlotCommands.SwitchPageSkill()
    Event.Dispatch(EventType.OnShortcutSwitchPageSkill)
end

-------------------------------- 热键响应 --------------------------------
local tbHotkey = {
    --         szKey,       bDown, bDoubleClick
    Alt = { "ALT", true, false },
    AltUp = { "ALT", false, false },
    Shift = { "SHIFT", true, false },
    ShiftUp = { "SHIFT", false, false },
    Space = { "SPACE", true, false },
    SpaceUp = { "SPACE", false, false },
    W = { "FORWARD", true, false },
    WUp = { "FORWARD", false, false },
    WW = { "FORWARD", true, true },
    S = { "BACKWARD", true, false },
    SUp = { "BACKWARD", false, false },
    SS = { "BACKWARD", true, true },
    A = { "LEFT", true, false },
    AUp = { "LEFT", false, false },
    AA = { "LEFT", true, true },
    D = { "RIGHT", true, false },
    DUp = { "RIGHT", false, false },
    DD = { "RIGHT", true, true },
}

function FuncSlotCommands.KeyCommand(szKeyCommand)
    local tbKeyEvent = tbHotkey[szKeyCommand]
    if tbKeyEvent then
        ResponseDisplacementHotkey(tbKeyEvent[1], tbKeyEvent[2], tbKeyEvent[3])
        return true
    end
    return false
end

return FuncSlotCommands

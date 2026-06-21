-- ---------------------------------------------------------------------------------
-- Author: huqing
-- Name: PSMMgr
-- Date: 2024-01-17 21:38:49
-- Desc: power saving mode 省电模式
-- ---------------------------------------------------------------------------------

PSMMgr = PSMMgr or {className = "PSMMgr"}
local self = PSMMgr
local ENTER_PSM_DURATION = 180 -- 多长时间内没有有效点击就算暂离

local IgnoreViewIDs = {
    [VIEW_ID.PanelVideoPlayer] = true,
    [VIEW_ID.PanelEmbeddedWebPages] = true,
    [VIEW_ID.PanelH5GameView] = true,
    [VIEW_ID.PanelLoading] = true,
    [VIEW_ID.PanelFish] = true,
}

function PSMMgr.Init()
    if not Platform.IsMobile() then
        return
    end

    self.nLastTouchTime = os.time() -- 上次点击时间
    self.bIsEnterPSMMode = false    -- 是否已经进入省电模式

    Event.Reg(self, EventType.OnSceneTouchBegan, function()
        self.RecordTouchTimer()
        self.ExitPSMMode()
    end)

    Event.Reg(self, EventType.OnWidgetTouchDown, function()
        self.RecordTouchTimer()
        self.ExitPSMMode()
    end)

    Event.Reg(self, "FIGHT_HINT", function(bInFight)
        PSMMgr.bInFight = bInFight
        self.RecordTouchTimer()
        self.ExitPSMMode()
    end)

    Event.Reg(self, EventType.DoExitPowerSaveMode, function()
        self.RecordTouchTimer()
        self.ExitPSMMode()
    end)

    Event.Reg(self, EventType.OnClientPlayerEnter, function()
        self.StartTick()
    end)

    Event.Reg(self, EventType.OnAccountLogout, function()
        self.ExitPSMMode()
        self.StopTick()
    end)

    -- 移动端有键盘消息过来 也要退出省电模式
    Event.Reg(self, "OnCCKeyDown", function(nKeyCode)
        self.RecordTouchTimer()
        self.ExitPSMMode()
    end)

    -- 移动端有手柄按键消息过来 也要退出省电模式
    Event.Reg(self, "OnGamepadKeyDown", function(nKey)
        self.RecordTouchTimer()
        self.ExitPSMMode()
    end)

    -- 移动端有手柄摇杆消息过来 也要退出省电模式
    Event.Reg(self, "OnGamepadMove", function(nKey , normalX , normalY)
        self.RecordTouchTimer()
        self.ExitPSMMode()
    end)
end

function PSMMgr.UnInit()

end

function PSMMgr.EnterPSMMode()
    if self.bIsEnterPSMMode then
        return
    end

    if not Storage.Debug.bPSMFlag then
        return
    end

    if not g_pClientPlayer or PSMMgr.bInFight then
        return
    end

    if AutoBattle.IsInAutoBattle() then
        return
    end

    -- 竖屏不进入省电模式
    if UIHelper.GetScreenPortrait() then
        return
    end

    -- 判断某些界面打开时不进入
    for nViewID, _ in pairs(IgnoreViewIDs) do
        if UIMgr.IsViewOpened(nViewID) then
            return
        end
    end

    if QualityMgr.IsIRX120Fps() then
        KG3DEngine.SetGameFrcState(false) -- 省电模式时暂时关闭IRX渲染加速120帧
    end

    -- -- 进入省电模式的时候 关掉网页界面，因为网页的渲染再游戏前会挡住很奇怪
    -- UIMgr.Close(VIEW_ID.PanelEmbeddedWebPages)

    self.bIsEnterPSMMode = true

    UIMgr.HideAllLayer({UILayer.Tips})

    UIMgr.OpenSingle(true, VIEW_ID.PanelRestScreen)
    self.StopTick()

    Event.Dispatch(EventType.OnEnterPowerSaveMode)
end

function PSMMgr.ExitPSMMode()
    if not self.bIsEnterPSMMode then
        return
    end

    self.bIsEnterPSMMode = false

    UIMgr.ShowAllLayer()
    UIMgr.Close(VIEW_ID.PanelRestScreen) -- 省电模式退出时刷新IRX渲染加速120帧状态
    self.StartTick()

    Event.Dispatch(EventType.OnExitPowerSaveMode)
end

function PSMMgr.IsEnterPSMMode()
    return self.bIsEnterPSMMode
end

function PSMMgr.StartTick()
    self.RecordTouchTimer()
    self.StopTick()

    self.nTimerID = Timer.AddCycle(self, 1, function()
        if not g_pClientPlayer then
            return
        end

        if not self.nLastTouchTime then
            return
        end

        if self.bInFight then
            return
        end

        -- 判断某些界面打开时不进入
        for nViewID, _ in pairs(IgnoreViewIDs) do
            if UIMgr.IsViewOpened(nViewID) then
                return
            end
        end

        local nDeltaTime = os.time() - self.nLastTouchTime
        if nDeltaTime >= ENTER_PSM_DURATION then
            self.EnterPSMMode()
        end
    end)
end

function PSMMgr.StopTick()
    Timer.DelTimer(self, self.nTimerID)
end

function PSMMgr.RecordTouchTimer()
    self.nLastTouchTime = os.time()
end
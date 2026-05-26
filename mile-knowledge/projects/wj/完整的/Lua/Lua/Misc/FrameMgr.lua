-- ---------------------------------------------------------------------------------
-- Author: huqing
-- Name: FrameMgr
-- Date: 2024-03-27 22:57:57
-- Desc:
--      动态帧率
--      1、多久没有触碰手机 主动降帧，然后点击屏幕后，升，平滑处理
--      2、全屏界面开启 主动降帧 (做开关)
--      3、根据电池温度动态限帧（华为、主城&人数）
-- ---------------------------------------------------------------------------------

FrameMgr = FrameMgr or {className = "FrameMgr"}
local self = FrameMgr

local DYN_FPS_OPEN = true -- 动态帧率是否开启
local ENTER_DYN_FPS_DURATION = 5  -- 多久没操作就开启动态帧率调整功能 (单位：秒)
local DYN_FPS_TEMPERATURE = Device.IsHuaWei() and 38 or 40  -- 动态帧率的温度阈值
local DYN_FPS_MAIN_CITY_PLAYER_LIMIT = 100  -- 主城人数阈值
local DYN_FPS_TEMPERATURE_MAIN_CITY = {     -- 主城多人时温控设置
    {nTemperature = 38, nFps = 20},
    {nTemperature = 42, nFps = 15},
}

function FrameMgr.Init()
    if not Platform.IsMobile() then
        return
    end

    self.bJoystickIng = false
    self.nLastJoyStickTime = os.time()
    self.nDynamicFpsTimerID = nil   -- 动态帧率定时器

    self.StartDynamicFps()

    Event.Reg(self, EventType.OnEnterPowerSaveMode, function()
        self.SetFrameLimit(5)
        self.StopDynamicFps()
    end)

    Event.Reg(self, EventType.OnExitPowerSaveMode, function()
        self.SetFrameLimit(QualityMgr.GetCurrentFps())
        self.StartDynamicFps()
    end)

    Event.Reg(self, EventType.OnJoyStickStart, function()
        self.OnJoyStickStart()
    end)

    Event.Reg(self, EventType.OnJoyStickEnd, function()
        self.OnJoyStickEnd()
    end)

    Event.Reg(self, EventType.OnHomelandJoyStickStart, function()
        self.OnJoyStickStart()
    end)

    Event.Reg(self, EventType.OnHomelandJoyStickEnd, function()
        self.OnJoyStickEnd()
    end)

    Event.Reg(self, EventType.EnterSelfieMode, function (bEnter)
        self.bSelfieMode = bEnter
    end)

    Event.Reg(self, EventType.OnEnterFancySkating, function ()
        self.SetFrameLimit(QualityMgr.GetCurrentFps())
        self.StopDynamicFps()
    end)

    Event.Reg(self, EventType.OnExitFancySkating, function ()
        self.SetFrameLimit(QualityMgr.GetCurrentFps())
        self.StartDynamicFps()
    end)
end

---comment 开始操作摇杆
function FrameMgr.OnJoyStickStart()
    self.bJoystickIng = true
end

---comment 结束操作摇杆
function FrameMgr.OnJoyStickEnd()
    self.bJoystickIng = false
    self.nLastJoyStickTime = os.time()
end

---comment 开启动态帧率检测
function FrameMgr.StartDynamicFps()
    if not DYN_FPS_OPEN then return end
    self.StopDynamicFps()
    self.nDynamicFpsTimerID = Timer.AddCycle(self, 1, self.OnTimerDynamicFps)
end

---comment 关闭动态帧率
function FrameMgr.StopDynamicFps()
    if self.nDynamicFpsTimerID then
        Timer.DelTimer(self, self.nDynamicFpsTimerID)
        self.nDynamicFpsTimerID = nil
    end
end

local function sSelectMin(a, b)
    if a and b then
        return math.min(a, b)
    else
        return a or b
    end
end

function FrameMgr.CheckNeedLimitFps()
    local nDuration = ENTER_DYN_FPS_DURATION
    local nDefaultFrameLimit = 20
    local nFrameLimit

    -- 华为设备 温度超过阈值 限帧
    if Device.IsHuaWei() then
        local nTemperature = App_GetBatteryTemperature()
        if nTemperature > DYN_FPS_TEMPERATURE then  -- 温度超过阈值
            nFrameLimit = sSelectMin(nFrameLimit, nDefaultFrameLimit)
        end
    end

    if Global.bIsEnterGame then
        if Global.bInFaceState or self.bSelfieMode then -- 0档镜头
            nFrameLimit = sSelectMin(nFrameLimit, nDefaultFrameLimit)
        end

        -- 主城场景周围人数超过限制
        if PlayerData.GetPlayerNum() >= DYN_FPS_MAIN_CITY_PLAYER_LIMIT and APIHelper.IsMainCityScene() then
            local nTemperature = App_GetBatteryTemperature()
            for _, tCfg in pairs(DYN_FPS_TEMPERATURE_MAIN_CITY) do
                if nTemperature > tCfg.nTemperature then
                    nFrameLimit = sSelectMin(nFrameLimit, tCfg.nFps)
                end
            end
        end

        -- 多久没操作摇杆了 限帧
        local nNoJoyStickFrameLimit = nDefaultFrameLimit
        if not self.bJoystickIng and self.nLastJoyStickTime and os.time() - self.nLastJoyStickTime > nDuration then
            nFrameLimit = sSelectMin(nFrameLimit, nNoJoyStickFrameLimit)
        end
    else
        -- 手指多久没操作了 限帧
        local nNoTouchFrameLimit = nDefaultFrameLimit
        if PSMMgr and PSMMgr.nLastTouchTime and os.time() - PSMMgr.nLastTouchTime > nDuration then
            nFrameLimit = sSelectMin(nFrameLimit, nNoTouchFrameLimit)   -- 超过一定时间没有操作
        end
    end

    return nFrameLimit
end

function FrameMgr.OnTimerDynamicFps()
    if QualityMgr.IsIRX120Fps() then
        return  -- 开启硬件加速时不动态调整帧率
    end

    if QualityMgr.IsExtremeHighFrame() then
        return
    end

    local nFps = self.GetFrameLimit()
    local nLimitFrame = self.CheckNeedLimitFps()
    if nLimitFrame then
        if nFps > nLimitFrame then
            self.SetFrameLimit(nFps - 1)
        elseif nFps < nLimitFrame then
            self.SetFrameLimit(nFps + 1)
        end
    else
        if nFps < QualityMgr.GetCurrentFps() then
            self.SetFrameLimit(nFps + 1)
        end
    end
end

---comment 设置游戏帧率限制
---@param nFps integer
function FrameMgr.SetFrameLimit(nFps)
    LOG("FrameMgr.SetFrameLimit(%d)", nFps)
    self.nFpsLimit = nFps
    App_SetFrameLimitCount(nFps)
end

---comment 获取当前游戏帧率限制
---@return integer
function FrameMgr.GetFrameLimit()
    return self.nFpsLimit
end

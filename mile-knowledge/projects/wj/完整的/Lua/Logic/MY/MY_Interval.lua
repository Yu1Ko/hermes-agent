--------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 时间周期函数模块
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------

local X = MY

---------------------------------------------------------------------
-- 时钟函数管理中心
---------------------------------------------------------------------
-- 函数        名称        用处         时间单位    最小时间精度(ms)
-- DelayCall   延迟调用   倒计时         毫秒       1 / GLOBAL.GAME_FPS
-- BreatheCall 呼吸调用   每帧调用       毫秒       1 / GLOBAL.GAME_FPS
-- FrameCall   按帧调用   每帧调用       呼吸帧     1 / GLOBAL.GAME_FPS
-- RenderCall  渲染调用   每次渲染调用   毫秒       1 / 每秒渲染次数
-- Debounce    调用防抖   延迟调用一次   毫秒       1 / GLOBAL.GAME_FPS
-- Throttle    调用节流   分段频率限制   毫秒       1 / GLOBAL.GAME_FPS
---------------------------------------------------------------------

--=================================== throttle ================================================
-- Throttle(szKey, nTime, fnAction, oArg)
-- Throttle('CASTING') -- 获取名称为CASTING的Throttle的信息
-- Throttle('CASTING', false) -- 注销名称为CASTING的Throttle
-- Throttle('CASTING', 100, function() end, oArg) -- 注册名称为CASTING防抖时间为100的Throttle
-- Throttle('CASTING', 200) -- 把名称为CASTING的Throttle防抖时间改为200毫秒
--=============================================================================================
local _tThrottle = {}
function X.Throttle(szKey, nTime, fnAction, oArg)
    local bUnreg, bThrottle
    if type(szKey) == 'number' then
        -- Throttle(nTime, fnAction[, oArg])
        szKey, nTime, fnAction, oArg = nil, szKey, nTime, fnAction
    elseif type(nTime) == 'boolean' then
        -- Throttle(szKey, false)
        nTime, bUnreg = nil, true
    end
    if fnAction then -- reg
        if not szKey then -- 匿名rc调用
            szKey = GetTickCount()
            while _tThrottle[tostring(szKey)] do
                szKey = szKey + 0.1
            end
            szKey = tostring(szKey)
        end
        if _tThrottle[szKey] and _tThrottle[szKey].nNext > GetTime() then
            bThrottle = true
        else
            _tThrottle[szKey] = {
                nTime = nTime,
                nNext = GetTime() + nTime,
                fnAction = fnAction,
                oArg = oArg,
            }
            fnAction(oArg)
        end
    elseif nTime then -- modify
        if _tThrottle[szKey] then
            _tThrottle[szKey].nTime = nTime
            _tThrottle[szKey].nNext = GetTime() + nTime
        end
    elseif szKey and bUnreg then -- unreg
        _tThrottle[szKey] = nil
    elseif szKey then -- get registered rendercall info
        local d = _tThrottle[szKey]
        if d then
            return szKey, d.nTime, d.nNext - GetTime()
        end
        return
    end
    return szKey, bThrottle
end
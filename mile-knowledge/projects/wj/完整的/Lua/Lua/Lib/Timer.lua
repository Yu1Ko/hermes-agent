Timer = Timer or {}

local GetTickCount = GetTickCount
local GetLogicFrameCount = GetLogicFrameCount

-- =============================================================================
-- 定时器
-- =============================================================================
local ccScheduler = cc.Director:getInstance():getScheduler()

---comment 添加定时器
---@param script table
---@param nTime number 时间 单位为秒
---@param func function 回调函数
---@return integer
function Timer.Add(script, nTime, func)
	if not script or not nTime or not func then return end

	if nTime <= 0 then
		LOG.ERROR(string.format("Timer.Add, error nTime = %s", tostring(nTime)))
		return
	end

	local nEntryID = nil
	nEntryID = ccScheduler:scheduleScriptFunc(function(nTotalTime)
		if Config.bOptickLuaSample then BeginSample("Timer.Add.update"..Timer._getClassName(script)..Timer._getSampleID(script, nEntryID)) end
		xpcall(func, function(err) LOG.ERROR("Timer.Add, error nEntryID = %s.\nError = %s", tostring(nEntryID), err) end)
		Timer.DelTimer(script, nEntryID)
		if Config.bOptickLuaSample then EndSample() end
	end, nTime, false)

	script._tbTimer = script._tbTimer or {}
	script._tbTimer[nEntryID] = func

	return nEntryID
end

---comment 添加循环定时器
---@param script table
---@param nCycleTime number 周期时间 单位为秒
---@param func function 回调函数
---@return integer
function Timer.AddCycle(script, nCycleTime, func)
	if not script or not nCycleTime or not func then return end

	if nCycleTime <= 0 then
		LOG.ERROR(string.format("Timer.AddCycle, error nCycleTime = %s", tostring(nCycleTime)))
		return
	end

	local nEntryID = nil
	nEntryID = ccScheduler:scheduleScriptFunc(function(nTotalTime)
		if Config.bOptickLuaSample then BeginSample("Timer.AddCycle.update"..Timer._getClassName(script)..Timer._getSampleID(script, nEntryID)) end
		xpcall(func, function(err) LOG.ERROR("Timer.AddCycle, error nEntryID = %s.\nError = %s", tostring(nEntryID), err) end)
		if Config.bOptickLuaSample then EndSample() end
	end, nCycleTime, false)

	script._tbTimer = script._tbTimer or {}
	script._tbTimer[nEntryID] = func

	return nEntryID
end

---comment 添加带延时的循环定时器
---@param script table
---@param nDelay number 延时 单位为秒
---@param nCycleTime number 周期时间 单位为秒
---@param func function 回调函数
---@return integer
function Timer.AddDelayCycle(script, nDelay, nCycleTime, func)
	if not script or not nDelay or not nCycleTime or not func then return end

	local bFinishDelay = false

	Timer.Add(script, nDelay, function()
		bFinishDelay = true
	end)

	local nEntryID = nil
	nEntryID = Timer.AddCycle(script, nCycleTime, function()
		if bFinishDelay then
			xpcall(func, function(err) LOG.ERROR("Timer.AddDelayCycle, error nEntryID = %s.\nError = %s", tostring(nEntryID), err) end)
		end
	end)
	return nEntryID
end

---comment 添加倒数定时器 （每秒一次）
---@param script table
---@param nCountDown number 倒数秒数
---@param func function|nil
---@param endFunc function|nil
---@return number timerID
function Timer.AddCountDown(script, nCountDown, func, endFunc)
	if not script or not nCountDown or not func then return end

	if nCountDown <= 0 then
		LOG.ERROR(string.format("Timer.AddCountDown, error nCountDown = %s", tostring(nCountDown)))
		return
	end

	nCountDown = math.floor(nCountDown)

	local nEntryID = nil
	nEntryID = ccScheduler:scheduleScriptFunc(function(nTotalTime)
		if Config.bOptickLuaSample then BeginSample("Timer.AddCountDown.update"..Timer._getClassName(script)..Timer._getSampleID(script, nEntryID)) end
		local nRemain = nCountDown - 1
		xpcall(function() func(nRemain) end, function(err) LOG.ERROR("Timer.AddCountDown, error nEntryID = %s.\nError = %s", tostring(nEntryID), err) end)

		nCountDown = nRemain
		if nCountDown <= 0 then
			if endFunc then
				xpcall(endFunc, function(err) LOG.ERROR("Timer.AddCountDown, Error = %s", err) end)
			end

			Timer.DelTimer(script, nEntryID)
		end
		if Config.bOptickLuaSample then EndSample() end
	end, 1, false)

	script._tbTimer = script._tbTimer or {}
	script._tbTimer[nEntryID] = func

	return nEntryID
end

---comment 添加帧定时器
---@param script table
---@param nFrame number 帧
---@param func function 回调函数
---@return integer
function Timer.AddFrame(script, nFrame, func)
	if not script or not nFrame or not func then return end

	if nFrame <= 0 then
		LOG.ERROR(string.format("Timer.AddFrame, error nFrame = %s", tostring(nFrame)))
		return
	end

	nFrame = math.floor(nFrame)

	local nEntryID = nil
	nEntryID = ccScheduler:scheduleScriptFunc(function(nFrameTime)
		if Config.bOptickLuaSample then BeginSample("Timer.AddFrame.update"..Timer._getClassName(script)..Timer._getSampleID(script, nEntryID)) end
		nFrame = nFrame - 1
		if nFrame <= 0 then
			xpcall(func, function(err) LOG.ERROR("Timer.AddFrame, error nEntryID = %s.\nError = %s", tostring(nEntryID), err) end)
			Timer.DelTimer(script, nEntryID)
		end
		if Config.bOptickLuaSample then EndSample() end
	end, 0, false)

	script._tbTimer = script._tbTimer or {}
	script._tbTimer[nEntryID] = func

	return nEntryID
end

---comment 添加循环帧定时器
---@param script table
---@param nCycleTime number 多少帧循环一次
---@param func function 回调函数
---@return integer
function Timer.AddFrameCycle(script, nCycleFrame, func)
	if not script or not nCycleFrame or not func then return end

	if nCycleFrame <= 0 then
		LOG.ERROR(string.format("Timer.AddFrameCycle, error nCycleFrame = %s", tostring(nCycleFrame)))
		return
	end

	nCycleFrame = math.floor(nCycleFrame)

	local nTotalFrame = 0
	local nEntryID = nil
	nEntryID = ccScheduler:scheduleScriptFunc(function(nFrameTime)
		if Config.bOptickLuaSample then BeginSample("Timer.AddFrameCycle.update"..Timer._getClassName(script)..Timer._getSampleID(script, nEntryID)) end
		nTotalFrame = nTotalFrame + 1
		if nTotalFrame % nCycleFrame  == 0 then
			xpcall(func, function(err) LOG.ERROR("Timer.AddFrameCycle, error nEntryID = %s.\nError = %s", tostring(nEntryID), err) end)
		end
		if Config.bOptickLuaSample then EndSample() end
	end, 0, false)

	script._tbTimer = script._tbTimer or {}
	script._tbTimer[nEntryID] = func

	return nEntryID
end

---comment 添加带延时的循环帧定时器
---@param script table
---@param nDelay number 延迟时间 单位为秒
---@param nCycleFrame number 多少帧循环一次
---@param func function 回调函数
---@return integer
function Timer.AddDelayFrameCycle(script, nDelay, nCycleFrame, func)
	if not script or not nDelay or not nCycleFrame or not func then return end

	local bFinishDelay = false

	Timer.Add(script, nDelay, function()
		bFinishDelay = true
	end)

	local nEntryID = nil
	nEntryID = Timer.AddFrameCycle(script, nCycleFrame, function()
		if bFinishDelay then
			xpcall(func, function(err) LOG.ERROR("Timer.AddDelayFrameCycle, error nEntryID = %s.\nError = %s", tostring(nEntryID), err) end)
		end
	end)
	return nEntryID
end

---comment 删除定时器
---@param script table
---@param nEntryID number 定时器ID
---@return nil
function Timer.DelTimer(script, nEntryID)
	if not script or not nEntryID then return end
	if not script._tbTimer then return end

	if script._tbTimer[nEntryID] then
		ccScheduler:unscheduleScriptEntry(nEntryID)
		script._tbTimer[nEntryID] = nil
	end
end

---comment 删除所有定时器
---@param script table
---@return nil
function Timer.DelAllTimer(script)
	if not script then return end

	if script._tbTimer then
		for nEntryID, _ in pairs(script._tbTimer) do
			Timer.DelTimer(script, nEntryID)
		end
		script._tbTimer = nil
	end
end


function Timer._getSampleID(script, nEntryID)
	local szSampleID = ""
	local bIsUI = false
	if script then
		if IsNumber(script._nViewID) then
			szSampleID = "_V_"..script._nViewID
			bIsUI = true
		elseif IsNumber(script._nPrefabID) then
			szSampleID = "_P_"..script._nPrefabID
			bIsUI = true
		end
	end

	-- 如果不是UI开的定时器，那就直接打印 nEntryID
	if not bIsUI and IsNumber(nEntryID) then
		szSampleID = "_T_"..nEntryID
	end

	return szSampleID
end

function Timer._getClassName(script)
	return string.format("_%s", script and script.className or "NULL")
end













-- =============================================================================
-- 时间处理
-- =============================================================================

-- 获取游戏开始运行到现在的时间 单位为秒
-- The real time in seconds since the game started.
function Timer.RealtimeSinceStartup()
	return GetTickCount() * 0.001
end

-- 获取当前时间 单位为毫秒
-- The real time in milli seconds since the game started.
function Timer.RealMStimeSinceStartup()
	return GetTickCount()
end

-- 获取每一帧的时间，这里固定 1/30
function Timer.FixedDeltaTime()
	return 0.0333333
end









-- =============================================================================
-- 时间处理
-- =============================================================================

---comment 获取启动到当前流失的时间（秒）
---@return number passTime (秒)
function Timer.GetPassTime()
	return GetTickCount() / 1000
end

---comment 获取当前逻辑帧计数
---@return integer
function Timer.GetLogicFrameCount()
	return GetLogicFrameCount()
end

function Timer.GetTime()
	return os.time()
end

function Timer.GetDate(nTime)
	nTime = nTime or os.time()
	return os.date("*t", nTime)
end

local tb = {}
function Timer.GetTimeDetail(nTime)
	if not nTime then return end
	tb = tb or {}
	tb.nDay = 0
	tb.nHour = 0
	tb.nMin = 0
	tb.nSec = 0

	tb.nDay = math.floor(nTime/(3600*24))
	nTime = nTime - tb.nDay * (3600*24)
	tb.nHour = math.floor(nTime/3600)
	nTime = nTime - tb.nHour * 3600
	tb.nMin = math.floor(nTime/60)
	nTime = nTime - tb.nMin * 60
	tb.nSec = math.floor(nTime)

	return tb
end

function Timer.Format2Second(nTime)
	tb = Timer.GetTimeDetail(nTime)
	if not tb then return "" end
	return string.format("%02d", tb.nSec)
end

function Timer.Format2Minute(nTime)
	tb = Timer.GetTimeDetail(nTime)
	if not tb then return "" end
	return string.format("%02d:%02d", tb.nMin, tb.nSec)
end

function Timer.Format2Hour(nTime)
	tb = Timer.GetTimeDetail(nTime)
	if not tb then return "" end
	return string.format("%02d:%02d:%02d", tb.nHour + tb.nDay * 24, tb.nMin, tb.nSec)
end

function Timer.Format2HourAndMinute(nTime)
	tb = Timer.GetTimeDetail(nTime)
	if not tb then return "" end
	return string.format("%02d:%02d", tb.nHour, tb.nMin)
end

function Timer.Format2RemainMinute(nTime)
	if not nTime or nTime < 0 then return "" end
	local nMin = math.floor(nTime / 60)
	local nSec = math.floor(nTime % 60)
	return string.format("%02d:%02d", nMin, nSec)
end

function Timer.Format2RemainHourAndMinute(nTime)
	if not nTime or nTime < 0 then return "" end
	local nHour = math.floor(nTime / 3600)
	local nMin = math.floor((nTime % 3600) / 60)
	return string.format("%02d:%02d", nHour, nMin)
end

function Timer.Format2RemainHourAndMinuteAndSecond(nTime)
	if not nTime or nTime < 0 then return "" end
	local nHour = math.floor(nTime / 3600)
	local nMin = math.floor((nTime % 3600) / 60)
	local nSec = math.floor(nTime % 60)
	return string.format("%02d:%02d:%02d", nHour, nMin, nSec)
end

function Timer.Format(nTime)
	tb = Timer.GetTimeDetail(nTime)
	if not tb then return "" end
	if tb.nDay > 0 or tb.nHour > 0 then
		return Timer.Format2Hour(nTime)
	else
		return Timer.Format2Minute(nTime)
	end
end

function Timer.FormatMilliseconds(nMilliseconds, bShortMs, bHideMs)
    local nTotalSeconds = math.floor(nMilliseconds / 1000)
    local nJustMs = nMilliseconds % 1000
    
    local nMinutes = math.floor(nTotalSeconds / 60)
    local nSeconds = nTotalSeconds % 60
    
    if bShortMs then
        nJustMs = math.floor(nJustMs / 10)
        return string.format("%02d:%02d:%02d", nMinutes, nSeconds, nJustMs)
    elseif bHideMs then
        return string.format("%02d:%02d", nMinutes, nSeconds)
    else
        return string.format("%02d:%02d:%03d", nMinutes, nSeconds, nJustMs)
    end
end


function Timer.FormatInChineseComplete(nTime)
	tb = Timer.GetTimeDetail(nTime)
	if not tb then return "" end
	if tb.nDay > 0 or tb.nHour > 0 then
		return string.format("%d小时%d分%d秒", tb.nHour + tb.nDay * 24, tb.nMin, tb.nSec)
	elseif tb.nMin > 0 then
		return string.format("%d分%d秒", tb.nMin, tb.nSec)
	else
		return string.format("%d秒", tb.nSec)
	end
end

function Timer.FormatInChinese(nTime)
	tb = Timer.GetTimeDetail(nTime)
	if not tb then return "" end
	if tb.nDay > 0 or tb.nHour > 0 then
		return string.format("%d小时", tb.nHour + tb.nDay * 24)
	else
		return string.format("%d分", tb.nMin)
	end
end

---人类阅读时间转时间戳
-- 支持格式：
--		2012-09-28 10:50:51
--		2012.09.28 10:50:51
--		2012-09-28
--		2012.09.28
function Timer.ParseDateTime(szDateTime)
	local year, month, day, hour, minute, second = string.match(szDateTime, "(%d+)/(%d+)/(%d+) (%d+):(%d+):(%d+)");
	if not year then
		year, month, day, hour, minute, second = string.match(szDateTime, "(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)");
	end

	if not year then
		year, month, day = string.match(szDateTime, "(%d+)/(%d+)/(%d+)");
		hour, minute, second = 0, 0, 0;
	end

	if not year then
		year, month, day = string.match(szDateTime, "(%d+)-(%d+)-(%d+)");
		hour, minute, second = 0, 0, 0;
	end

	if not year then
		LOG.INFO("Lib:ParseDateTime 时间字符串格式不合法" .. szDateTime);
		return;
	end

	return os.time({year = year, month = month, day = day, hour = hour, min = minute, sec = second});
end

function Timer.FormatInChinese2(nTime)
	tb = Timer.GetTimeDetail(nTime)
	if not tb then return "" end
	if tb.nDay > 0 or tb.nHour > 0 then
		return string.format("%d小时%d分", tb.nHour + tb.nDay * 24, tb.nMin)
	else
		return string.format("%d分", tb.nMin)
	end
end

function Timer.FormatInChinese3(nTime)
	tb = Timer.GetTimeDetail(nTime)
	if not tb then return "" end
	if tb.nDay > 0 or tb.nHour > 0 then
		return string.format("%d小时%d分", tb.nHour + tb.nDay * 24, tb.nMin)
	elseif tb.nMin > 0 then
		return string.format("%d分", tb.nMin)
	else
		return string.format("%d秒", tb.nSec)
	end
end


function Timer.FormatInChinese4(nTime)
	tb = Timer.GetTimeDetail(nTime)
	if not tb then return "" end
	if tb.nDay > 0 then
		return string.format("%d天%d小时%d分%d秒", tb.nDay, tb.nHour, tb.nMin, tb.nSec)
	elseif tb.nHour > 0 then
		return string.format("%d小时%d分%d秒", tb.nHour + tb.nDay * 24, tb.nMin, tb.nSec)
	elseif tb.nMin > 0 then
		return string.format("%d分%d秒", tb.nMin , tb.nSec)
	else
		return string.format("%d秒", tb.nSec)
	end
end

function Timer.FormatInChinese5(nTime)
	tb = Timer.GetTimeDetail(nTime)
	if not tb then return "" end
	if tb.nDay > 0 then
		return string.format("%d天", tb.nDay + 1)
	elseif tb.nHour > 0 then
		return string.format("%d小时", tb.nHour + 1)
	elseif tb.nMin > 0 then
		return string.format("%d分钟", tb.nMin + 1)
	else
		return string.format("%d秒", tb.nSec)
	end
end

function Timer.FormatInChinese6(nTime)
	tb = Timer.GetTimeDetail(nTime)
	if not tb then return "" end
	if tb.nDay > 0 then
		return string.format("%d天", tb.nDay)
	elseif tb.nHour > 0 then
		return string.format("%d小时", tb.nHour)
	elseif tb.nMin > 0 then
		return string.format("%d分钟", tb.nMin)
	else
		return string.format("%d秒", tb.nSec)
	end
end

-- 毫秒转换成“秒(0.1)”显示文本，例如 70200ms -> "70.2秒"
function Timer.FormatMsToSecondsTenthText(nMilliseconds)
    nMilliseconds = nMilliseconds or 0
    if nMilliseconds < 0 then
        nMilliseconds = 0
    end

    local fCutSeconds = nMilliseconds / 1000
    local fCutSecondsTenth = math.floor(fCutSeconds * 10 + 0.5) / 10
    return string.format("%.1f", fCutSecondsTenth) .. g_tStrings.STR_BUFF_H_TIME_S
end


-- szFormat格式说明
-- 		#d0 d为天数 0表示为0天时不显示天数
-- 		#h1 h表示小时数 1表示为0时也显示为"0小时"
-- 以前后时间单位为主，强制显示中间的单位，比如小时为0时，会显示为1天0小时5分，而不是1天5分钟 即使设置了h0
-- #d0h0m1 显示格式为11天11小时11分 或11小时11分 或 11分
-- #h0m1 显示为1234小时11分 或 11分
-- #h1m1 显示为1234小时11分 或 0小时11分
function Timer.FormatInChineseByFormat(nTime, szFormat)
	local tb = Timer.GetTimeDetail(nTime)

	local tbFormat = {}
	local tbResult = {}
	for w in string.gmatch(szFormat, "%a%d") do
		local timeType = string.match(w, "%a")
		tbFormat[timeType] = {}
		tbFormat[timeType].bIsForce = tonumber(string.match(w, "%d")) == 1
		table.insert(tbResult, timeType)
	end

	local nAddHouse = 0
	if tbFormat["d"] then
		tbFormat["d"].count = tb.nDay
		tbFormat["d"].name = "天"
	else
		nAddHouse = tb.nDay * 24
	end

	local nAddMin = 0
	if tbFormat["h"] then
		tbFormat["h"].count = tb.nHour + math.max(nAddHouse, 0)
		tbFormat["h"].name = "小时"
	else
		nAddMin = (tb.nHour + nAddHouse) * 60
	end

	local nAddSec = 0
	if tbFormat["m"] then
		tbFormat["m"].count = tb.nMin + math.max(nAddMin, 0)
		tbFormat["m"].name = "分"
	else
		nAddSec = (tb.nMin + nAddMin) * 60
	end

	if tbFormat["s"] then
		tbFormat["s"].count = tb.nSec + math.max(nAddSec, 0)
		tbFormat["s"].name = "秒"
	end

	-- 检测一遍强行显示位于中间的时间单位
	for nIdx, v in ipairs(tbResult) do
		if nIdx > 1 and nIdx < #tbResult then
			if (tbFormat[tbResult[nIdx - 1]].bIsForce or tbFormat[tbResult[nIdx - 1]].count > 0) and
				(tbFormat[tbResult[nIdx + 1]].bIsForce or tbFormat[tbResult[nIdx + 1]].count > 0) then
				tbFormat[tbResult[nIdx]].bIsForce = true
			end
		end
	end

	local szResult = ""
	for _, v in ipairs(tbResult) do
		if tbFormat[v] and (tbFormat[v].bIsForce or tbFormat[v].count > 0) then
			szResult = string.format("%s%d%s", szResult, tbFormat[v].count, tbFormat[v].name)
		end
	end

	return szResult
end

-- 时间显示规则（跟系统时间比较）：
-- 	今天——只显示时间 17：00
--	昨日——显示昨日 昨日
-- 	其他——显示日期	3月20日
function Timer.FormatDesc1(nTime)
	local nowTime = os.time()
	local nYear, nMonth, nDay = tonumber(os.date("%Y", nowTime)),
								tonumber(os.date("%m", nowTime)),
								tonumber(os.date("%d", nowTime))

	local nTodayTime = os.time({day=nDay, month=nMonth, year=nYear, hour = 0})
	local nYesterdayTime = os.time({day=(nDay - 1), month=nMonth, year=nYear, hour = 0})

	if nTime >= nTodayTime then
		return os.date("%H:%M", nTime)
	elseif nTime >= nYesterdayTime then
		return "昨天"
	else
		return os.date("%Y年%m月%d日", nTime)
	end
end

-- 时间显示规则（跟服务器时间比较）：
-- 	今天——只显示时间 17：00
--	昨日——显示昨日 昨日
-- 	其他——显示日期	3月20日
function Timer.FormatDesc2(nTime)
	local nowTime = GameEnv.GetServerUTC()
	local nYear, nMonth, nDay = tonumber(os.date("%Y", nowTime)),
								tonumber(os.date("%m", nowTime)),
								tonumber(os.date("%d", nowTime))

	local nTodayTime = os.time({day=nDay, month=nMonth, year=nYear, hour = 0})
	local nYesterdayTime = os.time({day=(nDay - 1), month=nMonth, year=nYear, hour = 0})

	if nTime >= nTodayTime then
		return os.date("%H:%M", nTime)
	elseif nTime >= nYesterdayTime then
		return "昨天"
	else
		return os.date("%Y年%m月%d日", nTime)
	end
end

-- 	返回日期:	十二月三日
function Timer.GetDesc1()
	local nowTime = os.time()
	local nMonth, nDay = tonumber(os.date("%m", nowTime)),
						 tonumber(os.date("%d", nowTime))

	local szMonth =  Number2Chinese[nMonth]
	local szDay =  Number2Chinese[nDay]

	return string.format("%s月%s日", szMonth, szDay)
end

-- 	返回日期:	12月3日
function Timer.GetDesc2()
	local nowTime = GameEnv.GetServerUTC()
	local nMonth, nDay = tonumber(os.date("%m", nowTime)),
	tonumber(os.date("%d", nowTime))

	local szMonth =  nMonth
	local szDay =  nDay

	return string.format("%s月%s日", szMonth, szDay)
end

local tbGSResponseCallback = {}
local bRegWaitGSResponse = false
local nGlobalResponseIndex = 1
---comment
---会远程调用到gs，并在gs回复后触发回调。方便确保该调用之前触发的协议都已经被gs处理并回复。 （无法保证协议中异步操作的流程均已处理完）
---比如在需要发送大量协议时，发送一批协议后，调用该接口，确保服务器已经处理完这批协议再触发下一批协议，防止发送过多触发掉线。 比等待固定帧效率更好，也能有效防止网络波动造成的单帧协议堆积掉线。
---@param script 调用的界面脚本,关闭界面时候会自动删除界面上的Wait
---@param func 服务器返回时的回调
---@return 创建的wait的id，可以用于删除该wait
function Timer.AddWaitGSResponse(script, func, nDelayTime)
	if not bRegWaitGSResponse then
		Event.Reg(Timer, "WaitGSResponseDone", function (dwResponseIndex)
			if tbGSResponseCallback[dwResponseIndex] then
				local script = tbGSResponseCallback[dwResponseIndex]
				local func = script._tbWaitTimer and script._tbWaitTimer[dwResponseIndex] or nil
				if func then
					if nDelayTime then
						Timer.Add(Global, nDelayTime, function() 
							xpcall(func, function(err) LOG.ERROR("Timer.AddWaitGSResponse, Error = %s", err) end)
							script._tbWaitTimer[dwResponseIndex] = nil
						end)
					else
						xpcall(func, function(err) LOG.ERROR("Timer.AddWaitGSResponse, Error = %s", err) end)
						script._tbWaitTimer[dwResponseIndex] = nil
					end
				end
				tbGSResponseCallback[dwResponseIndex] = nil
			end
		end)
		bRegWaitGSResponse = true
	end

	local nRetIndex = nGlobalResponseIndex

	RemoteCallToServer("OnWaitGSResponse", nRetIndex)

	script._tbWaitTimer = script._tbWaitTimer or {}
	script._tbWaitTimer[nRetIndex] = func
	tbGSResponseCallback[nRetIndex] = script
	nGlobalResponseIndex = nGlobalResponseIndex + 1
	return nRetIndex
end

function Timer.DelWait(script, nResponseIndex)
	if not script then return end
	if not nResponseIndex then return end

	if script._tbWaitTimer and script._tbWaitTimer[nResponseIndex] then
		tbGSResponseCallback[nResponseIndex] = nil
		script._tbWaitTimer[nResponseIndex] = nil
	end
end

function Timer.DelAllWait(script)
	if not script then return end
	if not script._tbWaitTimer then return end

	for nResponseIndex, _ in ipairs(script._tbWaitTimer) do
		Timer.DelWait(script, nResponseIndex)
	end
	script._tbWaitTimer = nil
end

return Timer

--- 从端游 ui/Script/time_lib.lua 复制而来，按照项目风格进行微调（全部函数改为TimeLib的方法）
-----------------------------------------------------------------------------
-- time extensions
-----------------------------------------------------------------------------

TimeLib = TimeLib or {}

function TimeLib.GetCurrentHour( ... )
	local tTime = TimeLib.GetTodayTime()
	local nHour = tTime.hour
	return nHour
end

function TimeLib.GetTodayTime()
	local nTime = GetCurrentTime()
	local t = TimeToDate(nTime)

	return t
end

function TimeLib.GetCurrentWeekday( ... )
	local tTime = TimeLib.GetTodayTime()
	local nWeek = tTime.weekday
	if nWeek == 0 then
		nWeek = 7
	end

	return nWeek
end

function TimeLib.GetDateTextHour(nTime)
	local tTime = TimeToDate(nTime)
	local szText = FormatString(g_tStrings.STR_DATE_HOUR, tTime.year, tTime.month, tTime.day, tTime.hour)
	return szText
end

function TimeLib.GetDateTextMonthToMinute(nTime)
	local tTime = TimeToDate(nTime)
	local szHour = string.format("%02d", tTime.hour)
	local szMinute = string.format("%02d", tTime.minute)
	local szText = FormatString(g_tStrings.STR_TIME_9, tTime.month, tTime.day, szHour, szMinute)
	return szText
end

function TimeLib.GetDateText(nTime)
	local tTime = TimeToDate(nTime)
	local szHour = string.format("%02d", tTime.hour)
	local szMinute = string.format("%02d", tTime.minute)
	local szText = FormatString(g_tStrings.STR_TIME_4, tTime.year, tTime.month, tTime.day, szHour, szMinute)
	return szText
end

local _timeZero
function TimeLib.TimeToWeekCount(nTimestamp)
	if not _timeZero then
		_timeZero = TimeToDate(0)
	end
	-- 要计算的时间
	local t = TimeToDate(nTimestamp)
	-- 所在年第一天
	local nTimeYearDay0 = DateToTime(t.year, _timeZero.month, _timeZero.day, _timeZero.hour, _timeZero.minute, _timeZero.second)
	local dateYearDay0 = TimeToDate(nTimeYearDay0)
	-- 所在年的第一个周一
	local nTimeYearMonday0 = DateToTime(t.year, _timeZero.month, (8 - dateYearDay0.weekday) % 7, _timeZero.hour, _timeZero.minute, _timeZero.second)
	-- 计算时差
	return math.floor((nTimestamp - nTimeYearMonday0) / (7 * 24 * 60 * 60)) + 1
end

function TimeLib.GetTimeToHourMinuteSecond(nTime, bFrame)
	if bFrame then
		nTime = nTime / GLOBAL.GAME_FPS
	end
	local nHour   = math.floor(nTime / 3600)
	nTime = nTime - nHour * 3600
	local nMinute = math.floor(nTime / 60)
	nTime = nTime - nMinute * 60
	local nSecond = math.floor(nTime)
	return nHour, nMinute, nSecond
end

function TimeLib.GetTimeToHourMinuteSecondTenthSec(nTime, bFrame)
	if bFrame then
		nTime = nTime / GLOBAL.GAME_FPS
	end
	local nHour   = math.floor(nTime / 3600)
	nTime = nTime - nHour * 3600
	local nMinute = math.floor(nTime / 60)
	nTime = nTime - nMinute * 60
	local nSecond, nTenthSec = math.modf(nTime)
	--nTenthSec = string.format("%.1f", nTenthSec) * 10
	nTenthSec = math.floor(nTenthSec * 10 % 10)
	return nHour, nMinute, nSecond, nTenthSec
end

-- bContour:替换为更加明显的描边字体; bTenthSec:显示十分之一秒
function TimeLib.Time_GetTextData(nEndFrame, bLeftFrame, bContour, bTenthSec)
	local szResult = ""
	local nFont = 162
	local nLeft = 0
	if bLeftFrame then
		nLeft = nEndFrame
	else
		nLeft = nEndFrame - GetLogicFrameCount()
	end

	local r, g, b = 255, 255, 255
	local nH, nM, nS, nTS
	if bTenthSec then
		nH, nM, nS, nTS = TimeLib.GetTimeToHourMinuteSecondTenthSec(nLeft, true)
	else
		nH, nM, nS = TimeLib.GetTimeToHourMinuteSecond(nLeft, true)
	end
	local fontW, fontY, fontR = 162, 163, 166
	if bContour then
		fontW, fontY, fontR = 15, 16, 159
	end
	
	if nH >= 1 then
		if nM >= 1 or nS >= 1 then
			nH = nH + 1
		end
		szResult = nH .. ""
		nFont = fontW
	elseif nM >= 1 then
		if nS >= 1 then
			nM = nM + 1
		end
		szResult = nM .. "'"
		nFont = fontY
		r, g, b = 255, 255, 0
	elseif bTenthSec and nTS and nS < 10 then
		szResult = nS .."''" .. nTS
		nFont = fontR
		r, g, b = 255, 0, 0
	else
		szResult = nS .."''"
		nFont = fontR
		r, g, b = 255, 0, 0
	end
	return szResult, nFont, nLeft, r, g, b
end

function TimeLib.GetLocalTimeText()
	local nTime = GetCurrentTime()
	local t = TimeToDate(nTime)
	return FormatString(g_tStrings.STR_TIME, t.hour, t.minute, t.second, t.year, t.month, t.day)
end

function TimeLib.GetStandardTime()
    local nTime = GetCurrentTime()
	local t = TimeToDate(nTime)
	return string.format(g_tStrings.STR_TIME_STANDARD, t.year, t.month, t.day, t.hour, t.minute, t.second)
end

--  * short : 天， 时，分， 秒
--  * 天，小时，分钟，秒
local function GetTimeSuffix(bShortSuffix)
	if bShortSuffix then
		return g_tStrings.STR_BUFF_H_TIME_D_SHORT,  g_tStrings.STR_BUFF_H_TIME_H_SHORT, g_tStrings.STR_BUFF_H_TIME_M_SHORT, g_tStrings.STR_BUFF_H_TIME_S_SHORT
	else
		return g_tStrings.STR_BUFF_H_TIME_D,  g_tStrings.STR_BUFF_H_TIME_H, g_tStrings.STR_BUFF_H_TIME_M, g_tStrings.STR_BUFF_H_TIME_S
	end
end

local function GetShortTime(nD, nH, nM, nS, bCeil, bShortSuffix, bShortH)
	local szDSuf, szHSuf, szMSuf, szSSuf = GetTimeSuffix(bShortSuffix)
	if bShortH and nD ~= 0 then
		local szTime = nD..szDSuf
		if bCeil and (nM ~= 0 or nS ~= 0) then
			nH = nH + 1
		end

		if nH ~= 0 then
			szTime = szTime .. nH .. szHSuf
		end

		return  szTime
	end

	if nD ~= 0 then
		if bCeil and (nH ~= 0 or nM ~= 0 or nS ~= 0) then
			nD = nD + 1
		end
		return nD..szDSuf
	end
	if nH ~= 0 then
		if bCeil and (nM ~= 0 or nS ~= 0) then
			nH = nH + 1
		end
		return nH..szHSuf
	end
	if nM > 0 then
		if bCeil and nS ~= 0 then
			nM = nM + 1
		end
		return nM..szMSuf
	end
	return nS..szSSuf
end

local function GetNormalTime(nD, nH, nM, nS, szFormat, bShortSuffix)
	local szTimeText = ""
	local szDay, szHour, szMin, szSecond = "", "", "", ""
	local szDSuf, szHSuf, szMSuf, szSSuf = GetTimeSuffix(bShortSuffix)

	if nD ~= 0 then
		szDay = nD .. szDSuf
	end

	if nH ~= 0 then
		szHour = szHour .. nH .. szHSuf
	end

	if nM ~= 0 then
		szMin = szMin .. nM .. szMSuf
	end

	if nS ~= 0 or (nD == 0 and nH == 0 and nM == 0) then
		szSecond = szSecond .. nS .. szSSuf
	end

	if szFormat == "show three" then
		szTimeText = szHour .. szMin
		if szDay == "" then
			szTimeText = szTimeText .. szSecond
		else
			szTimeText = szDay ..  szTimeText
		end
	elseif szFormat == "Diable Second" then
		szTimeText = szDay .. szHour .. szMin
	else
		szTimeText = szDay .. szHour .. szMin ..szSecond
	end

	return szTimeText
end

function TimeLib.GetTimeText(nTime, bFrame, bShort, bInt, bCeil, szFormat, bShortSuffix, bShortH)
	if not nTime then
		Log("/ui/script/base.lua TimeLib.GetTimeText nTime is nil")
		Log(var2str(debug.traceback()))
		return ""
	end

	if bFrame then
		nTime = nTime / GLOBAL.GAME_FPS
	end

	local nD = math.floor(nTime / 3600 / 24)
	local nH = math.floor(nTime / 3600 % 24)
	local nM = math.floor((nTime % 3600) / 60)
	local nS = (nTime % 3600) % 60
	if bInt then
		if bCeil then
			nS = math.ceil(nS)
		else
			nS = math.floor(nS)
		end
	else
		nS = tonumber(FixFloat(nS, 2))
	end

	if bShort then
		return GetShortTime(nD, nH, nM, nS, bCeil, bShortSuffix, bShortH)
	else
		return GetNormalTime(nD, nH, nM, nS, szFormat, bShortSuffix)
	end
end

function TimeLib.GetLunarDate(nTime)
	nTime = nTime or GetCurrentTime()
	local t = TimeToDate(nTime)
	local tLunar = GetActivityMgrClient().SolarDateToLunar(t.year, t.month, t.day)
	return string.format("%s%s", g_tLunarString.tMonName[tLunar.nMonth], g_tLunarString.tDayName[tLunar.nDay])
end

function TimeLib.GetClockTimeText(nDelteTime)
	local nHour, nMinute, nSecond = TimeLib.GetTimeToHourMinuteSecond(nDelteTime)
	local szSecond = string.format("%02d", nSecond)
	local szMinute = string.format("%02d", nMinute)
	if nHour > 0 then
		return FormatString(g_tStrings.STR_TIME_12, nHour, szMinute, szSecond)
	else
		return FormatString(g_tStrings.STR_TIME_11, szMinute, szSecond)
	end
end

function TimeLib.ACCInfo_Base_GetFormatTime(nTime, bComplete)
    local nM = math.floor(nTime / 60)
    local nS = math.floor(nTime % 60)
    local szTimeText = ""

    if nM ~= 0 then
        szTimeText= szTimeText .. nM .. ":"
    elseif bComplete then
        szTimeText= szTimeText .. "00" ..":"
    end

    if nS < 10 and nM ~= 0 then
        szTimeText = szTimeText.."0"
    end

    szTimeText= szTimeText..nS

    return szTimeText
end

--根据剩余多长时间获取颜色
-->=10min： 白色
--5~10min： 绿色
--1~5min：  黄色
--<=1min：  红色
function TimeLib.GetTimeColor(nTime)
	-- UIHelper.AttachTextColor(szText, nFontColorID)
	local szColor = ""
	if nTime >= 600 then
		szColor = FontColorID.Text_Level1_Backup
	elseif nTime >= 300 then
		szColor = FontColorID.ImportantGreen
	elseif nTime >= 60 then
		szColor = FontColorID.ImportantYellow
	else
		szColor = FontColorID.ImportantRed
	end
	return szColor
end
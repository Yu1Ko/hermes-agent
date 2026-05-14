-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: ChallengeData
-- Date: 2023-04-06 16:51:15
-- Desc: ?
-- ---------------------------------------------------------------------------------

ChallengeData = ChallengeData or {}
local self = ChallengeData

self.LEI_TAI_BUFF_ID		= 12338
self.PK_BUFF_ID				= 12344
self.BREAK_BUFF_ID			= 12350
self.BAI_LEI_ID				= 1256
self.BREAK_CD_ID			= 1257
self.LEI_TAI_TOTAL_TIME	    = 30 * 60 * GLOBAL.GAME_FPS
self.BREAK_TOTAL_TIME		= 5 * 60

self.NUMBER_COUNT 			= 2
self.AUTO_CLOSE_DISTANCE	= 5 * 64 * 5 * 64
-------------------------------- 消息定义 --------------------------------
ChallengeData.Event = {}
ChallengeData.Event.XXX = "ChallengeData.Msg.XXX"

function ChallengeData.Init()
    
end

function ChallengeData.UnInit()
    
end

function ChallengeData.OnLogin()
    
end

function ChallengeData.OnFirstLoadEnd()
    
end

---------------------------------------------------------------------------
function ChallengeData.UpdateSloganInfo() --获取口号列表
    local tMenu = {}
    local tab = g_tTable.Challenge
    for i = 1, tab:GetRowCount() do
		local tChallenge = tab:GetRow(i)
		table.insert(tMenu, {szOption = tChallenge.szDesc})
	end

    return tMenu
end

function ChallengeData:GetBreakLeftTime(dwTime)
	local dwStartTime = dwTime
	return math.max(0, dwStartTime + self.BREAK_TOTAL_TIME - GetCurrentTime())
end

function ChallengeData:GetBreakBuffLeftTime(nBuffID)
	local tBuffInfo = Buffer_GetTimeData(nBuffID)
	if not tBuffInfo then return 0 end
	return Buffer_GetLeftFrame(tBuffInfo)
end

function ChallengeData:GetTimeToMinuteDesc(nTime, bFrame)
	local nH, nM, nS = TimeLib.GetTimeToHourMinuteSecond(nTime, bFrame)
    return nM*60 + nS
end
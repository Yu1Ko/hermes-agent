ArenaBonusData = ArenaBonusData or {className = "ArenaBonusData"}

local self = ArenaBonusData
local szSettingFile = "/ui/Scheme/Setting/ArenaBonusSetting.ini"

function ArenaBonusData.Init()
    self._tSetting = {}
    self._tGuessSetting = {}
    self._tbArenaBonusData =
    {
        nBonus = nil,
        nGuessBonus = nil
    }

    Event.Reg(ArenaBonusData, "FIRST_LOADING_END", function()
        ArenaBonusData.LoadSetting()
    end)

    -- 打开Hint面板
    Event.Reg(ArenaBonusData, EventType.OnViewClose, function(nViewID)
        if nViewID == VIEW_ID.PanelLoading then
            TipsHelper:Init()
            TipsHelper:Init(true) -- 事实上该界面应当常驻，不需要反复初始化

            -- 竞猜活动期间显示气泡入口
            local nCurrentTime = GetCurrentTime()
            local nStart = self._tGuessSetting.nStartTime
            local nEnd = self._tGuessSetting.nEndTime
            local bInTime = nStart and nEnd and nCurrentTime >= nStart and nCurrentTime <= nEnd
            if bInTime then
                local nBubbleType = "ArenaBonus"
                BubbleMsgData.PushMsgWithType(nBubbleType, {
                    szType = nBubbleType, -- 类型(用于排重)
                    nBarTime = 0, -- 显示在气泡栏的时长, 单位为秒
                    szContent = function()
                        local szContent = ""
                        return szContent, 0.5
                    end,
                    szAction = function()
                        UIMgr.Open(VIEW_ID.PanelArenaActivity)
                    end,
                })
            end
        end
    end)
end

function ArenaBonusData.UnInit()

end

function ArenaBonusData.GetBonus()
    return self._tbArenaBonusData.nBonus
end

function ArenaBonusData.SetBonus(nBonus)
    self._tbArenaBonusData.nBonus = nBonus
end

function ArenaBonusData.GetArenaBonusSetting()
    return self._tSetting
end

function ArenaBonusData.GetArenaBonusTime()
    return self._tSetting.nStartTime, self._tSetting.nEndTime
end

function ArenaBonusData.GetArenaHaiXunTime()
    return self._tSetting.nHaiXuanTimeStart, self._tSetting.nHaiXuanTimeEnd
end

function ArenaBonusData.GetArenaMasterActivityID()
    return self._tSetting.dwActivityID
end

function ArenaBonusData.IsInArenaBonusTime()
    local nStart, nEnd = ArenaBonusData.GetArenaBonusTime()
    if not nStart or not nEnd then
        return false
    end
    local nTime = GetCurrentTime()
    return nTime >= nStart and nTime <= nEnd
end

function ArenaBonusData.IsInArenaHaiXunTime()
    local nStart, nEnd = ArenaBonusData.GetArenaHaiXunTime()
    if not nStart or not nEnd then
        return false
    end
    local nTime = GetCurrentTime()
    return nTime >= nStart and nTime <= nEnd
end

function ArenaBonusData.GetGuessImage()
    local tList = {}
	local nCount = g_tTable.GuessImage:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.GuessImage:GetRow(i)
		table.insert(tList, tLine)
	end
	return tList
end

function ArenaBonusData.GetGuessTeamRank()
    local tList = {}
	local nCount = g_tTable.GuessTeamRank:GetRowCount()
	for i = 2, nCount do
        local tLine = g_tTable.GuessTeamRank:GetRow(i)
		table.insert(tList, tLine)
    end
	return tList
end

function ArenaBonusData.GetArenaGuessSetting()
    return self._tGuessSetting
end

function ArenaBonusData.GetGuessBonus()
    return self._tbArenaBonusData.nGuessBonus
end

function ArenaBonusData.SetGuessBonus(nBonus)
    self._tbArenaBonusData.nGuessBonus = nBonus
end

function ArenaBonusData.GetGuessTime()
    return self._tGuessSetting.nStartTime, self._tGuessSetting.nEndTime
end

function ArenaBonusData.IsInGuessTime()
    local nStart, nEnd = ArenaBonusData.GetGuessTime()
    if not nStart or not nEnd then
        return false
    end
    local nTime = GetCurrentTime()
    return nTime >= nStart and nTime <= nEnd
end

local function GetTime(szTime)
    local tTime = SplitString(szTime, "-")
    for i, v in ipairs(tTime) do
        tTime[i] = tonumber(v)
    end
    local nTime = DateToTime(tTime[1], tTime[2], tTime[3], tTime[4], tTime[5], tTime[6])
    return nTime
end

function ArenaBonusData.LoadSetting()
    local pFile = Ini.Open(szSettingFile)
    if not pFile then
        return
    end
    local szSection = "MasterBonus"
    self._tSetting = {}
    --_tSetting.nBase = pFile:ReadInteger(szSection, "Base" , 0)
    self._tSetting.fCurrentP = pFile:ReadFloat(szSection, "CurrentPercent" , 0)
    self._tSetting.nTotalGlobalCounter = pFile:ReadInteger(szSection, "TotalGlobalCounter" , 0)
    self._tSetting.nBonus = pFile:ReadInteger(szSection, "Bonus" , 0)
    self._tSetting.fItemPercent = pFile:ReadFloat(szSection, "ItemPercent" , 0)
    self._tSetting.nItemCount = pFile:ReadInteger(szSection, "nItemCount" , 0)
    local szStarTime = pFile:ReadString(szSection, "TimeStart" , "")
    self._tSetting.nStartTime = GetTime(szStarTime)
    local szEndTime = pFile:ReadString(szSection, "TimeEnd" , "")
    self._tSetting.nEndTime = GetTime(szEndTime)
    szStarTime = pFile:ReadString(szSection, "HaiXuanTimeStart" , "")
    self._tSetting.nHaiXuanTimeStart = GetTime(szStarTime)
    szEndTime = pFile:ReadString(szSection, "HaiXuanTimeEnd" , "")
    self._tSetting.nHaiXuanTimeEnd = GetTime(szEndTime)
    self._tSetting.dwActivityID = pFile:ReadInteger(szSection, "dwActivityID" , 0)

    szSection = "GuessBonus"
    self._tGuessSetting = {}
    self._tGuessSetting.fItemPercent = pFile:ReadFloat(szSection, "ItemPercent" , 0)
    self._tGuessSetting.nItemCount = pFile:ReadInteger(szSection, "nItemCount" , 0)
    local szStarTime = pFile:ReadString(szSection, "TimeStart" , "")
    self._tGuessSetting.nStartTime = GetTime(szStarTime)
    local szEndTime = pFile:ReadString(szSection, "TimeEnd" , "")
    self._tGuessSetting.nEndTime = GetTime(szEndTime)
    local szItemInfo = pFile:ReadString(szSection, "ItemInfo" , "")
    self._tGuessSetting.tItemInfo = string.split(szItemInfo, "|")
    pFile:Close()
end
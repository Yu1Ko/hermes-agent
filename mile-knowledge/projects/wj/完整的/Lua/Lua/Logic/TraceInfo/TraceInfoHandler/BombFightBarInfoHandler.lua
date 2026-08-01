local _M = {className = "BombFightBarInfoHandler"}
local self = _M

--飞火论锋
_M.szInfoType = TraceInfoType.BombFightBar

function _M.Init()
    self.RegEvent()

end

function _M.UnInit()
    Event.UnRegAll(self)
    Timer.DelAllTimer(self)

end

function _M.RegEvent()
    Event.Reg(self, EventType.On_Update_GeneralProgressBar, function(tbInfo)
        local bIsInFBBattleFieldMap = BattleFieldData.IsInFBBattleFieldMap() and (tbInfo.szName == "bomb_Score" or tbInfo.szName == "bomb_BestScore")
        if bIsInFBBattleFieldMap then
            self.tName2Info = self.tName2Info or {}
            self.tName2Info[tbInfo.szName] = tbInfo

            TraceInfoData.UpdateInfo(TraceInfoType.BombFightBar)
            Event.Dispatch(EventType.OnTogTraceInfo, TraceInfoType.BombFightBar, true, tbInfo)
        end
    end)

    Event.Reg(self, EventType.On_Delete_GeneralProgressBar, function(szName)
        local bIsInFBBattleFieldMap = BattleFieldData.IsInFBBattleFieldMap() and (szName == "bomb_Score" or szName == "bomb_BestScore")
        if bIsInFBBattleFieldMap then
            self.tName2Info = self.tName2Info or {}
            self.tName2Info[szName] = nil

            TraceInfoData.UpdateInfo(TraceInfoType.BombFightBar)
            Event.Dispatch(EventType.OnTogTraceInfo, TraceInfoType.BombFightBar, false)
        end
    end)
end

function _M.OnUpdateView(script, scrollViewParent, tData)
    self.UpdateBombFightBarInfo(script, scrollViewParent)
end

function _M.OnClear(script)
    Timer.DelTimer(script, script.nTimerID)
    script.cell_Time = nil
    script.nTimerID = nil
end

--------------------------------  --------------------------------

local function GetFormatTime(nTime, bComplete)
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

function _M.UpdateBombFightBarInfo(script, scrollViewParent)
    local szNameSelf = "bomb_Score"
    local szNameBest = "bomb_BestScore"

    if not self.tName2Info[szNameSelf] and not self.tName2Info[szNameBest] then
        return
    end

    local fnAddProgressBar = function(tInfo)
        local szTitle = UIHelper.GBKToUTF8(tInfo.szTitle)
        local szProgress = string.format("%d/%d", tInfo.nMolecular, tInfo.nDenominator)
        local szDesc = UIHelper.GBKToUTF8(tInfo.szDiscrible)

        UIHelper.AddPrefab(PREFAB_ID.WidgetTaskTeamSubtitle, scrollViewParent, szTitle, 5)
        UIHelper.AddPrefab(PREFAB_ID.WidgetRichTextOtherDescribe, scrollViewParent, szProgress)
        UIHelper.AddPrefab(PREFAB_ID.WidgetRichTextOtherDescribe, scrollViewParent, szDesc)
    end

    UIHelper.RemoveAllChildren(scrollViewParent)

    script.cell_Time = UIHelper.AddPrefab(PREFAB_ID.WidgetRichTextOtherDescribe, scrollViewParent, g_tStrings.STR_BATTLEFIELD_TIME_LEFT)
    script.nTimerID = script.nTimerID or Timer.AddCycle(script, 1, function()
        local _, _, _, nEndTime = GetBattleFieldPQInfo()

        local nTime = GetCurrentTime()
        local nPoor = math.max(0, nEndTime - nTime)
        local szText = GetFormatTime(nPoor)

        script.cell_Time:OnEnter(string.format("%s%s", g_tStrings.STR_BATTLEFIELD_TIME_LEFT, szText))
    end)

    -- 个人得分
    if self.tName2Info[szNameSelf] then
        local tInfo = self.tName2Info[szNameSelf]

        fnAddProgressBar(tInfo)
    end

    -- 全场最高分
    if self.tName2Info[szNameBest] then
        local tInfo = self.tName2Info[szNameBest]

        fnAddProgressBar(tInfo)
    end
end

return _M
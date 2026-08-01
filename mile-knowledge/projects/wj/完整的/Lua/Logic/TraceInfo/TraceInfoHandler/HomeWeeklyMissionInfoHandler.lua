local _M = {className = "HomeWeeklyMissionInfoHandler"}
local self = _M

--家园周常
_M.szInfoType = TraceInfoType.HomeWeeklyMission

function _M.Init()
    self.RegEvent()

end

function _M.UnInit()
    Event.UnRegAll(self)
    Timer.DelAllTimer(self)

end

function _M.RegEvent()
    Event.Reg(self, EventType.On_Update_GeneralProgressBar, function(tbInfo)
        if tbInfo.szName == "bar38" then
            self.tbPBInfo = tbInfo
            TraceInfoData.UpdateInfo(TraceInfoType.HomeWeeklyMission)
            Event.Dispatch(EventType.OnTogTraceInfo, TraceInfoType.HomeWeeklyMission, true)
        end
    end)
    Event.Reg(self, EventType.On_Delete_GeneralProgressBar, function(szName)
        if szName == "bar38" then
            if self.tbPBInfo then
                self.tbPBInfo = nil
            end
            Event.Dispatch(EventType.OnTogTraceInfo, TraceInfoType.HomeWeeklyMission, false)
        end
    end)
end

function _M.OnUpdateView(script, scrollViewParent, tData)
    self.UpdateProgressInfo(script, scrollViewParent)
end

function _M.OnClear(script)
    script.scriptProgress = nil
end


function _M.UpdateProgressInfo(script, scrollViewParent)

    local nPercent = 0
    local szValue = ""
    local nWay = self.tbPBInfo.nWay
    local nDenominator = self.tbPBInfo.nDenominator
    local nMolecular = self.tbPBInfo.nMolecular
    local szTitle = self.tbPBInfo.szTitle

    if nWay == 1 then
        nPercent = nMolecular / nDenominator * 100
        szValue = tostring(math.floor(nPercent)) .. "%"
    elseif nWay == 2 then
        if nDenominator then
            nPercent = nMolecular / nDenominator * 100
        end
        szValue = tostring(nMolecular) .. "/" .. tostring(nDenominator)
    elseif nWay == 3 then
        nPercent = nMolecular / nDenominator * 100
    elseif nWay == 4 then
        nPercent = 100
        szValue = tostring(nMolecular)
    end

    if not script.scriptProgress then
        script.scriptProgress = UIHelper.AddPrefab(PREFAB_ID.WidgetSliderOtherDescribe, scrollViewParent, szTitle, szValue, nPercent)
    else
        script.scriptProgress:OnEnter(szTitle, szValue, nPercent)
    end

end

return _M
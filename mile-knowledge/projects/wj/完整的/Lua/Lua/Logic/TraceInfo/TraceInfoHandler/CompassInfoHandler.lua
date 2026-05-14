local _M = {}
local self = _M

_M.szInfoType = TraceInfoType.Compass

function _M.Init()
    self.RegEvent()

end

function _M.UnInit()
    Event.UnRegAll(self)
    Timer.DelAllTimer(self)

end

function _M.RegEvent()
    Event.Reg(self, EventType.OnTogCompass, function(bOpen)
        Event.Dispatch(EventType.OnTogTraceInfo, TraceInfoType.Compass, bOpen, nil, true)
        if bOpen then
            Event.Dispatch(EventType.OnSetTraceInfoPriority, TraceInfoType.Compass)
        end

        if g_bCompassVisible ~= bOpen then
            g_bCompassVisible = bOpen
            Event.Dispatch(EventType.OnCompassStateChanged)
        end
        Event.Dispatch("OnTreasureHuntingDisplayChanged")
    end)
end

function _M.OnUpdateView(script, scrollViewParent, tData)
    self.UpdateCompassInfo(script, scrollViewParent)
end

function _M.OnClear(script)
    script.scriptCompass = nil
end

--------------------------------  --------------------------------

function _M.UpdateCompassInfo(script, scrollViewParent)
    if not script.scriptCompass then
        script.scriptCompass = UIHelper.AddPrefab(PREFAB_ID.WidgetMainCityCompass, scrollViewParent)
    end
end

return _M
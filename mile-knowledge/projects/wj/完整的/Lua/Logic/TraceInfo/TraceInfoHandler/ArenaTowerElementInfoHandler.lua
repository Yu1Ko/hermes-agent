local _M = {}
local self = _M

_M.szInfoType = TraceInfoType.ArenaTowerElement

function _M.Init()
    self.RegEvent()

end

function _M.UnInit()
    Event.UnRegAll(self)
    Timer.DelAllTimer(self)

end

function _M.RegEvent()
    Event.Reg(self, EventType.OnTogArenaTowerElementInfo, function(bOpen)
        local bShow = bOpen and true or nil
        Event.Dispatch(EventType.OnTogTraceInfo, TraceInfoType.ArenaTowerElement, bOpen, nil, bShow)
    end)
end

function _M.OnUpdateView(script, scrollViewParent, tData)
    self.UpdateElementInfo(script, scrollViewParent)
end

function _M.OnClear(script)
    script.scriptElement = nil
end

--------------------------------  --------------------------------

function _M.UpdateElementInfo(script, scrollViewParent)
    if not script.scriptElement then
        script.scriptElement = UIHelper.AddPrefab(PREFAB_ID.WidgetMainCityElementInfo, scrollViewParent)
    end
end

return _M
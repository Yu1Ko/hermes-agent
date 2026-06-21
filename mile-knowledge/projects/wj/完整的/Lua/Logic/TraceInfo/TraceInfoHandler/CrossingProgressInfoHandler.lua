local _M = {className = "CrossingProgressInfoHandler"}
local self = _M

--试炼之地
_M.szInfoType = TraceInfoType.CrossingProgress

function _M.Init()
    self.RegEvent()

end

function _M.UnInit()
    Event.UnRegAll(self)
    Timer.DelAllTimer(self)

end

function _M.RegEvent()
    --试炼之地 开
    Event.Reg(self, EventType.On_Trial_OpenCProcess, function(tbData)
        CrossingData:UpdateCrossingProgressInfo(tbData)
        Event.Dispatch(EventType.OnTogTraceInfo, TraceInfoType.CrossingProgress, true, tbData)
    end)

    --试炼之地 关
    Event.Reg(self, EventType.On_Trial_CloseCProcess, function()
        CrossingData:CloseCrossingProgressInfo()
        Event.Dispatch(EventType.OnTogTraceInfo, TraceInfoType.CrossingProgress, false)
    end)
end

function _M.OnUpdateView(script, scrollViewParent, tData)
    self.UpdateCrossingInfo(script, scrollViewParent)
end

function _M.OnClear(script)
    script.tbProgressInfo = nil
end

--------------------------------  --------------------------------

function _M.UpdateCrossingInfo(script, scrollViewParent)
    if not self.tbCrossingProgressInfo then
        return
    end

    local szMissionName = self.tbCrossingProgressInfo.szMissionName
    local szTipContent = self.tbCrossingProgressInfo.szTipContent

    if script.tbProgressInfo == nil then
        script.tbProgressInfo = {}
        UIHelper.RemoveAllChildren(scrollViewParent)
        script.tbProgressInfo.cell_title = UIHelper.AddPrefab(PREFAB_ID.WidgetTaskTeamSubtitle, scrollViewParent, szMissionName, 5)
        script.tbProgressInfo.cell_Time = UIHelper.AddPrefab(PREFAB_ID.WidgetRichTextOtherDescribe, scrollViewParent, g_tStrings.tCrossing.CROSSING_TIME_LEAVE)
        script.tbProgressInfo.cell_Describe = UIHelper.AddPrefab(PREFAB_ID.WidgetRichTextOtherDescribe, scrollViewParent, szTipContent)
    else
        -- 做一层判断，外围的任务栏也许会进行删除
        if not script.tbProgressInfo.cell_title:CheckIsValid() then
            UIHelper.RemoveAllChildren(scrollViewParent)
            script.tbProgressInfo.cell_title = UIHelper.AddPrefab(PREFAB_ID.WidgetTaskTeamSubtitle, scrollViewParent, szMissionName, 5)
            script.tbProgressInfo.cell_Time = UIHelper.AddPrefab(PREFAB_ID.WidgetRichTextOtherDescribe, scrollViewParent, g_tStrings.tCrossing.CROSSING_TIME_LEAVE)
            script.tbProgressInfo.cell_Describe = UIHelper.AddPrefab(PREFAB_ID.WidgetRichTextOtherDescribe, scrollViewParent, szTipContent)
        end
        script.tbProgressInfo.cell_title:OnEnter(szMissionName, 5)
        script.tbProgressInfo.cell_Describe:OnEnter(szTipContent)
    end
end

function _M.UpdateCrossingProgressInfo(szMissionName, szTipContent)
    self.tbCrossingProgressInfo = self.tbCrossingProgressInfo or {}

    self.tbCrossingProgressInfo.szMissionName = szMissionName
    self.tbCrossingProgressInfo.szTipContent = szTipContent

    TraceInfoData.UpdateInfo(TraceInfoType.CrossingProgress)
end

function _M.CloseCrossingProgressInfo()
    TraceInfoData.ForEach(TraceInfoType.CrossingProgress, function(script, scrollViewParent, tData)
        UIHelper.RemoveAllChildren(scrollViewParent)
        script.tbProgressInfo = nil
    end)
    self.tbCrossingProgressInfo = nil
end

function _M.UpdateCrossingTime(szTime)
    TraceInfoData.ForEach(TraceInfoType.CrossingProgress, function(script, scrollViewParent, tData)
        if script.tbProgressInfo and script.tbProgressInfo.cell_title:CheckIsValid() then
            script.tbProgressInfo.cell_Time:OnEnter(g_tStrings.tCrossing.CROSSING_TIME_LEAVE..szTime)
        end
    end)
end

return _M
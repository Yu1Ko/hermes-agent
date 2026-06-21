local _M = {className = "ActivityTipInfoHandler"}
local self = _M

--动态信息Tip
_M.szInfoType = TraceInfoType.ActivityTip

function _M.Init()
    self.RegEvent()

end

function _M.UnInit()
    Event.UnRegAll(self)
    Timer.DelAllTimer(self)

end

function _M.RegEvent()
    Event.Reg(self, EventType.OnActivityTipUpdate, function(dwActivityID)
        if dwActivityID ~= CampData.CAMP_ACTIVITY_TIP_ID then
            self.OnActivityTipUpdate(dwActivityID)
        end
    end)
end

function _M.OnUpdateView(script, scrollViewParent, tData)
    local bAddTitle = tData and tData.bAddTitle
    local dwActivityID = tData and tData.dwActivityID
    self.UpdateActivityTipInfo(script, scrollViewParent, dwActivityID, bAddTitle)
end

function _M.OnClear(script)

end

--------------------------------  --------------------------------

function _M.UpdateActivityTipInfo(script, scrollViewParent, dwActivityID, bAddTitle)
    local tTimer = script._tTraceInfoTimer
    Timer.DelAllTimer(tTimer)
    UIHelper.RemoveAllChildren(scrollViewParent)

    local tTip = ActivityTipData.GetActivityTip(dwActivityID)
    if not tTip then
        return
    end

    if bAddTitle then
        UIHelper.AddPrefab(PREFAB_ID.WidgetRichTextOtherDescribe, scrollViewParent, tTip.szName) --顶部Title
    end

    --Desc
    local szTimeDesc = ActivityTipData.GetActivityTipTimeDescText(dwActivityID)
    local scriptDesc = UIHelper.AddPrefab(PREFAB_ID.WidgetRichTextOtherDescribe, scrollViewParent, szTimeDesc) --描述

    --若存在计时
    local nLeftTime = ActivityTipData.GetLeftTime(dwActivityID)
    if nLeftTime and nLeftTime > 0 then
        Timer.AddCountDown(tTimer, (nLeftTime / 1000) + 1, function()
            local szTimeDesc = ActivityTipData.GetActivityTipTimeDescText(dwActivityID)
            scriptDesc:OnEnter(szTimeDesc)
        end, function()
            local szTimeDesc = ActivityTipData.GetActivityTipTimeDescText(dwActivityID)
            scriptDesc:OnEnter(szTimeDesc)
        end)
    end

    local nIndexTitle = 1
    for nIndexValue, tValueLine in ipairs(tTip.tValue or {}) do
        if tValueLine.szValue == "\n" then
            UIHelper.AddPrefab(PREFAB_ID.WidgetRichTextOtherDescribe, scrollViewParent, " ")
        else
            local szText, scriptValue
            local szTitle = tTip.tTitle[nIndexTitle]
            if szTitle == g_tStrings.STR_CAMP_CONTRIBUTION then
                szText = ActivityTipData.GetActivityTipLineText(dwActivityID, nIndexTitle, nIndexValue, nil, false)
                scriptValue = UIHelper.AddPrefab(PREFAB_ID.WidgetTaskTeamSubtitle, scrollViewParent, szText)
                ActivityTipData.SetupCampContribution(scriptValue, dwActivityID)
            else
                szText = ActivityTipData.GetActivityTipLineText(dwActivityID, nIndexTitle, nIndexValue)
                scriptValue = UIHelper.AddPrefab(PREFAB_ID.WidgetRichTextOtherDescribe, scrollViewParent, szText)
            end

            --若存在计时
            local nLeftTime = ActivityTipData.GetLeftTime(dwActivityID, nIndexValue)
            if nLeftTime and nLeftTime > 0 then
                local nCurIndexTitle = nIndexTitle
                local nCurIndexValue = nIndexValue
                Timer.AddCountDown(tTimer, (nLeftTime / 1000) + 1, function()
                    local szText = ActivityTipData.GetActivityTipLineText(dwActivityID, nCurIndexTitle, nCurIndexValue)
                    scriptValue:OnEnter(szText)
                end, function()
                    local szText = ActivityTipData.GetActivityTipLineText(dwActivityID, nCurIndexTitle, nCurIndexValue)
                    scriptValue:OnEnter(szText)
                end)
            end
            nIndexTitle = nIndexTitle + 1
        end
    end
end

function _M.OnActivityTipUpdate(dwActivityID)
    TraceInfoData.ForEach(TraceInfoType.ActivityTip, function(script, scrollViewParent, tData)
        if tData and tData.dwActivityID == dwActivityID then
            self.OnUpdateView(script, scrollViewParent, tData)
        end
    end)
end

return _M
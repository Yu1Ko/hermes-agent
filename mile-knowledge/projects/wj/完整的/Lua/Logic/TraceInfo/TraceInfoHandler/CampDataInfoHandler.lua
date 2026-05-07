local _M = {className = "CampDataInfoHandler"}
local self = _M

--阵营攻防信息
_M.szInfoType = TraceInfoType.CampData

function _M.Init()
    self.RegEvent()

end

function _M.UnInit()
    Event.UnRegAll(self)
    Timer.DelAllTimer(self)

end

function _M.RegEvent()
    Event.Reg(self, EventType.OnActivityTipUpdate, function(dwActivityID)
        if dwActivityID == CampData.CAMP_ACTIVITY_TIP_ID then
            TraceInfoData.UpdateInfo(TraceInfoType.CampData)
        end
    end)
    Event.Reg(self, EventType.OnTogActivityTip, function(bOpen, dwActivityID)
        if dwActivityID == CampData.CAMP_ACTIVITY_TIP_ID then
            local player = GetClientPlayer()
            if bOpen and player and player.nCamp == CAMP.NEUTRAL then --中立不显示
                return
            end
            Event.Dispatch(EventType.OnTogTraceInfo, TraceInfoType.CampData, bOpen)
        end
    end)

    Event.Reg(self, EventType.OnCampWarStateChanged, function(bOpen)
        local player = GetClientPlayer()
        if bOpen and player and player.nCamp == CAMP.NEUTRAL then --中立不显示
            return
        end
        Event.Dispatch(EventType.OnTogTraceInfo, TraceInfoType.CampData, bOpen)
    end)
    Event.Reg(self, "ON_ACTIVITY_PRESET_ENABLE_STATE_CHANGE", function()
        TraceInfoData.UpdateInfo(TraceInfoType.CampData)
    end)
end

function _M.OnUpdateView(script, scrollViewParent, tData)
    local bAddTitle = tData and tData.bAddTitle
    self.UpdateCampDataInfo(script, scrollViewParent, bAddTitle)
end

function _M.OnClear(script)

end

--------------------------------  --------------------------------

function _M.UpdateCampDataInfo(script, scrollViewParent, bAddTitle)
    local tTimer = script._tTraceInfoTimer
    Timer.DelAllTimer(tTimer)
    UIHelper.RemoveAllChildren(scrollViewParent)

    local bIsInActivityTime = CampData.IsInActivity()
    if bAddTitle then
        -- UIHelper.AddPrefab(PREFAB_ID.WidgetRichTextOtherDescribe, scrollViewParent, "阵营攻防战")
        local dwMapID = MapHelper.GetMapID()
        local bShowWeather, tPreset = CampData.IsActivityPresetOn(dwMapID)
        if bShowWeather then
            local szTip = UIHelper.GBKToUTF8(tPreset.szDesc)
            local bEnable = SelfieData.IsActivityPresetEnabled()
            -- local szIconPath = bEnable and tPreset.szMobileImgNormalPath or tPreset.szMobileImgDisablePath
            local szIconPath = tPreset.szMobileImgNormalPath
            local scriptView = UIHelper.AddPrefab(PREFAB_ID.WidgetTaskTeamSubtitle, scrollViewParent, "阵营攻防战")
            scriptView:SetWeatherBtnVis(true)
            scriptView:SetWeatherIcon(szIconPath)
            scriptView:SetWeatherClickCallBack(function()
                TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips, scriptView.BtnWeather, TipsLayoutDir.RIGHT_CENTER, UIHelper.GBKToUTF8(tPreset.szDesc))
            end)
        end
    end

    --倒计时
    local szTimeTitle = bIsInActivityTime and "结束倒计时: " or "开启倒计时: "
    szTimeTitle = UIHelper.AttachTextColor(szTimeTitle, FontColorID.ImportantYellow)

    local _getTimeText = function()
        local nHour, nMinute, nSecond = CampData.GetActiveTime()
        local nTime = nHour * 3600 + nMinute * 60 + nSecond
        local szTime = szTimeTitle .. ActivityTipData.FormatTime(nTime)
        return szTime
    end

    local szTime = _getTimeText()
    local scriptTime = UIHelper.AddPrefab(PREFAB_ID.WidgetRichTextOtherDescribe, scrollViewParent, szTime)
    Timer.AddCycle(tTimer, 1, function()
        local szTime = _getTimeText()
        scriptTime:OnEnter(szTime)
    end)

    UIHelper.AddPrefab(PREFAB_ID.WidgetTaskGongFang, scrollViewParent)
    self.UpdateCampActivityTip(scrollViewParent)
end

function _M.UpdateCampActivityTip(scrollViewParent)
    local dwActivityID = CampData.CAMP_ACTIVITY_TIP_ID
    local tTip = ActivityTipData.GetActivityTip(dwActivityID)
    if not tTip then
        return
    end

    local szTarget = ActivityTipData.GetActivityTipLineText(dwActivityID, 1, 1)
    UIHelper.AddPrefab(PREFAB_ID.WidgetRichTextOtherDescribe, scrollViewParent, szTarget)

    local szBossGood = tTip.tValue[2].szValue
    local szBossEvil = tTip.tValue[4].szValue
    local szBoss = UIHelper.AttachTextColor("首领 (浩气:恶人): ", FontColorID.ImportantYellow) .. szBossGood .. " : " .. szBossEvil
    UIHelper.AddPrefab(PREFAB_ID.WidgetRichTextOtherDescribe, scrollViewParent, szBoss)

    local szPointGood = tTip.tValue[3].szValue
    local szPointEvil = tTip.tValue[5].szValue
    local szPoint = UIHelper.AttachTextColor("据点 (浩气:恶人): ", FontColorID.ImportantYellow) .. szPointGood .. " : " .. szPointEvil
    UIHelper.AddPrefab(PREFAB_ID.WidgetRichTextOtherDescribe, scrollViewParent, szPoint)

    local szCarTime = ActivityTipData.GetActivityTipLineText(dwActivityID, 6, 6, true)
    -- local szContribute = ActivityTipData.GetActivityTipLineText(dwActivityID, 7, 7)
    UIHelper.AddPrefab(PREFAB_ID.WidgetRichTextOtherDescribe, scrollViewParent, szCarTime)
    -- UIHelper.AddPrefab(PREFAB_ID.WidgetRichTextOtherDescribe, scrollViewParent, szContribute)

    local szContribute = ActivityTipData.GetActivityTipLineText(dwActivityID, 7, 7, nil, false)
    local scriptView = UIHelper.AddPrefab(PREFAB_ID.WidgetTaskTeamSubtitle, scrollViewParent, szContribute)
    ActivityTipData.SetupCampContribution(scriptView, dwActivityID)
end

return _M
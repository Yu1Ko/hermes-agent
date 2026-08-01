local _M = {}
local self = _M

--信息追踪处理 模板
_M.szInfoType = TraceInfoType.HotSpring

function _M.Init()
    self.RegEvent()

end

function _M.UnInit()
    Event.UnRegAll(self)
    Timer.DelAllTimer(self)

end

function _M.RegEvent()
    Event.Reg(self, EventType.On_Update_GeneralProgressBar, function(tbInfo)
        if not ActivityData.IsHotSpringActivity() then
            return
        end

        self.tbPBInfo = self.tbPBInfo or {}
        self.tbPBInfo[tbInfo.szName] = tbInfo

        self.CheckHasHotSpringInfo()
        TraceInfoData.UpdateInfo(TraceInfoType.HotSpring)
    end)
    Event.Reg(self, EventType.On_Delete_GeneralProgressBar, function(szName)
        if not ActivityData.IsHotSpringActivity() then
            return
        end

        self.tbPBInfo = self.tbPBInfo or {}
        self.tbPBInfo[szName] = nil

        self.CheckHasHotSpringInfo()
        TraceInfoData.UpdateInfo(TraceInfoType.HotSpring)
    end)
    Event.Reg(self, EventType.On_PQ_RequestDataReturn, function(szName)
        if not ActivityData.IsHotSpringActivity() then
            return
        end

        self.CheckHasHotSpringInfo()
        TraceInfoData.UpdateInfo(TraceInfoType.HotSpring)
    end)
    Event.Reg(self, EventType.OnClientPlayerEnter, function()
        if not ActivityData.IsHotSpringActivity() then
            --换地图清状态
            self.tbPBInfo = {}
            self.bHasHotSpring = false
            Event.Dispatch(EventType.OnTogTraceInfo, TraceInfoType.HotSpring, false)
        end
    end)
end

-- 更新UI显示
function _M.OnUpdateView(script, scrollViewParent, tData)
    self.UpdateHotSpringInfo(script, scrollViewParent)
end

--清理
function _M.OnClear(script)
    local tPQHandler = TraceInfoData.GetInfoHandler(TraceInfoType.PublicQuest)
    if tPQHandler then
        tPQHandler.OnClear(script)
    end

    for szName, script in pairs(script.tbPBNodeInfo or {}) do
        UIHelper.RemoveFromParent(script._rootNode, true)
    end
    script.tbPBNodeInfo = nil
end

--------------------------------  --------------------------------

function _M.UpdateHotSpringInfo(script, scrollViewParent)
    local tPQHandler = TraceInfoData.GetInfoHandler(TraceInfoType.PublicQuest)
    if tPQHandler then
        tPQHandler.UpdatePublicQuestInfo(script, scrollViewParent, false)
    end

    local bScrollToTop = false
    if script.tbPBNodeInfo then
        local nNodeCount = 0
        for szName, script in pairs(script.tbPBNodeInfo) do
            UIHelper.RemoveFromParent(script._rootNode, true)
            nNodeCount = nNodeCount + 1
            if not self.tbPBInfo[szName] then
                bScrollToTop = true
            end
        end

        if not bScrollToTop and nNodeCount ~= table.get_len(self.tbPBInfo) then
            bScrollToTop = true
        end
    end

    script.tbPBNodeInfo = {}

    -- 按ID排序 bar31~bar37, bar51~bar53
    local tbPBInfo = {}
    for _, tbInfo in pairs(self.tbPBInfo) do
        table.insert(tbPBInfo, tbInfo)
    end

    local fnSort = function(a, b) return a.nID < b.nID end
    table.sort(tbPBInfo, fnSort)

    for _, tbInfo in ipairs(tbPBInfo) do
        local szTitle = UIHelper.GBKToUTF8(tbInfo.szTitle)
        local szDesc = UIHelper.GBKToUTF8(GeneralProgressBarData.GetStringValue(tbInfo))
        local nPercent
        if tbInfo.nDenominator then 
            nPercent = tbInfo.nMolecular / tbInfo.nDenominator * 100
        end

        local scriptSlider = UIHelper.AddPrefab(PREFAB_ID.WidgetSliderOtherDescribe, scrollViewParent, UIHelper.UTF8ToGBK(szTitle), szDesc, nPercent, 20)
        if scriptSlider then
            local szColor = tbInfo.tbLine.szMobileProgressColor
            if szColor then
                local color = cc.c3b(tonumber(string.sub(szColor,1,2),16), tonumber(string.sub(szColor,3,4),16), tonumber(string.sub(szColor,5,6),16))
                UIHelper.SetColor(scriptSlider.SliderTarget, color)
            end
            script.tbPBNodeInfo[tbInfo.szName] = scriptSlider
        end
    end

    if bScrollToTop then
        UIHelper.ScrollViewDoLayoutAndToTop(scrollViewParent)
    end

    UIHelper.SetTouchEnabled(scrollViewParent, true)
end

function _M.CheckHasHotSpringInfo()
    local bHasHotSpring = false

    if self.tbPBInfo and not table.is_empty(self.tbPBInfo) then
        bHasHotSpring = true
    end

    local tPQHandler = TraceInfoData.GetInfoHandler(TraceInfoType.PublicQuest)
    local bHasPQ = tPQHandler and tPQHandler.HasPQ()
    if not bHasHotSpring and bHasPQ and ActivityData.IsHotSpringActivity() then
        bHasHotSpring = true
    end

    if not self.bHasHotSpring and bHasHotSpring then
        Event.Dispatch(EventType.OnSetTraceInfoPriority, TraceInfoType.HotSpring) --温泉山庄信息从无到有，切到温泉山庄
        Event.Dispatch(EventType.OnTogTraceInfo, TraceInfoType.HotSpring, bHasHotSpring)
    end

    self.bHasHotSpring = bHasHotSpring
end

return _M
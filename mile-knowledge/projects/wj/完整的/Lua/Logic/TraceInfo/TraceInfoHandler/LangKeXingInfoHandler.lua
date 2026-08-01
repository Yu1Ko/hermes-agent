local _M = {className = "LangKeXingInfoHandler"}
local self = _M

--浪客行
_M.szInfoType = TraceInfoType.LangKeXing

function _M.Init()
    self.RegEvent()

end

function _M.UnInit()
    Event.UnRegAll(self)
    Timer.DelAllTimer(self)

end

function _M.RegEvent()
    Event.Reg(self, EventType.On_Update_GeneralProgressBar, function(tbInfo)
        if tbInfo.szName == "LKX_ShiChen" or tbInfo.szName == "LKX_XinQingZhi" or tbInfo.szName == "LKX_BaoShiDu" then
            self.tbPBInfo = self.tbPBInfo or {}
            self.tbPBInfo[tbInfo.szName] = tbInfo

            self.CheckHasLKXInfo()
            self.OnAddPBInfo(tbInfo)
        end
    end)

    Event.Reg(self, EventType.On_Delete_GeneralProgressBar, function(szName)
        if szName == "LKX_ShiChen" or szName == "LKX_XinQingZhi" or szName == "LKX_BaoShiDu" then
            if self.tbPBInfo then
                self.tbPBInfo[szName] = nil
            end

            self.CheckHasLKXInfo()
            self.OnDeletePBInfo(szName)
        end
    end)

    Event.Reg(self, EventType.On_PQ_RequestDataReturn, function(tbPQInfo, bFieldPQ)
        self.CheckHasLKXInfo()
        TraceInfoData.UpdateInfo(TraceInfoType.LangKeXing)
    end)

    Event.Reg(self, EventType.On_TimeBuffData_Update, function(tbBuffList)
        self.tbBuffList = tbBuffList
        self.CheckHasLKXInfo()
        TraceInfoData.UpdateInfo(TraceInfoType.LangKeXing)
    end)
end

function _M.OnUpdateView(script, scrollViewParent, tData)
    self.UpdateLKXInfo(script, scrollViewParent)
end

function _M.OnClear(script)
    script.scriptTaskLKX = nil
    script.tbPQScript = nil
    script.scriptBuff = nil
    local tPQHandler = TraceInfoData.GetInfoHandler(TraceInfoType.PublicQuest)
    if tPQHandler then
        tPQHandler.OnClear(script)
    end
end

--------------------------------  --------------------------------

function _M.UpdateLKXInfo(script, scrollViewParent)
    if not script.scriptTaskLKX then
        script.scriptTaskLKX = UIHelper.AddPrefab(PREFAB_ID.WidgetTaskLangKeXing, scrollViewParent)
        UIHelper.SetVisible(script.scriptTaskLKX._rootNode, false)

        if self.tbPBInfo and not table.is_empty(self.tbPBInfo) then
            for szName, tbInfo in pairs(self.tbPBInfo) do
                self.AddGeneralProgressBar(script, scrollViewParent, tbInfo)
            end
        end
        UIHelper.SetLocalZOrder(script.scriptTaskLKX._rootNode, -2)
        UIHelper.SetGlobalZOrder(script.scriptTaskLKX._rootNode, 1, true)
    end

    local tPQHandler = TraceInfoData.GetInfoHandler(TraceInfoType.PublicQuest)
    if tPQHandler then
        tPQHandler.UpdatePublicQuestInfo(script, scrollViewParent, false)
    end

    self.UpdateBuffInfo(script, scrollViewParent)
    UIHelper.SetSwallowTouches(scrollViewParent, true)
end

function _M.OnAddPBInfo(tbPBInfo)
    TraceInfoData.ForEach(TraceInfoType.LangKeXing, function(script, scrollViewParent, tData)
        self.AddGeneralProgressBar(script, scrollViewParent, tbPBInfo)
    end)
end

function _M.OnDeletePBInfo(szName)
    TraceInfoData.ForEach(TraceInfoType.LangKeXing, function(script, scrollViewParent, tData)
        self.DeleteGeneralProgressBar(script, scrollViewParent, szName)
    end)
end

--包含浪客行信息、PQ、Buff
function _M.CheckHasLKXInfo()
    local bHasLKX = false

    --LKX
    local nLKXCount = 0
    for k, v in pairs(self.tbPBInfo or {}) do
        if v then
            bHasLKX = true
            break
        end
    end

    --PQ
    local tPQHandler = TraceInfoData.GetInfoHandler(TraceInfoType.PublicQuest)
    local bHasPQ = tPQHandler and tPQHandler.HasPQ()
    if not bHasLKX and bHasPQ and TravellingBagData.IsInTravelingMap() then
        bHasLKX = true
    end

    --Buff
    if not bHasLKX and self.tbBuffList and #self.tbBuffList ~= 0 then
        bHasLKX = true
    end

    if not self.bHasLKX and bHasLKX then
        Event.Dispatch(EventType.OnSetTraceInfoPriority, TraceInfoType.LangKeXing)--浪客行信息从无到有，切到浪客行
    end

    self.bHasLKX = bHasLKX

    Event.Dispatch(EventType.OnTogTraceInfo, TraceInfoType.LangKeXing, bHasLKX)
end

function _M.AddGeneralProgressBar(script, scrollViewParent, tbPBInfo)
    script.scriptTaskLKX:UpdateInfo(tbPBInfo)
    UIHelper.ScrollViewDoLayout(scrollViewParent)
end

function _M.DeleteGeneralProgressBar(script, scrollViewParent, szName)
    script.scriptTaskLKX:DeleteUIInfo(szName)
    UIHelper.ScrollViewDoLayout(scrollViewParent)
end

function _M.UpdateBuffInfo(script, scrollViewParent)
    self.RemoveBuffInfo(script)
    if self.tbBuffList and #self.tbBuffList ~= 0 then
        script.scriptBuff = UIHelper.AddPrefab(PREFAB_ID.WidgetTaskBuff, scrollViewParent, self.tbBuffList)
        UIHelper.SetLocalZOrder(script.scriptBuff._rootNode, -1)
        UIHelper.SetGlobalZOrder(script.scriptBuff._rootNode, 1, true)--防止因locaZorder小于0，事件被ScrollView吞噬，点击buff图标没反应
    end
end

function _M.RemoveBuffInfo(script)
    if script.scriptBuff then
        UIHelper.RemoveFromParent(script.scriptBuff._rootNode, true)
    end
    script.scriptBuff = nil
end

return _M
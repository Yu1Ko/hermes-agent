local _M = {className = "PublicQuestInfoHandler"}
local self = _M

--公共任务
_M.szInfoType = TraceInfoType.PublicQuest

local MY_SELF_MAX_VALUE = 100

local tFBCountDownType = {2, 3, 6}

function _M.Init()
    self.cellTaskTeamPool = PrefabPool.New(PREFAB_ID.WidgetTaskTeamSubtitle, 2)
    self.cellDescPool = PrefabPool.New(PREFAB_ID.WidgetRichTextOtherDescribe)
    self.cellSliderPool = PrefabPool.New(PREFAB_ID.WidgetSliderOtherDescribe)
    self.cellQuestPool = PrefabPool.New(PREFAB_ID.WidgetMainCityTaskCell, 2)
    self.RegEvent()

end

function _M.UnInit()
    Event.UnRegAll(self)
    Timer.DelAllTimer(self)

    if self.cellTaskTeamPool then self.cellTaskTeamPool:Dispose() end
    if self.cellDescPool then self.cellDescPool:Dispose() end
    if self.cellSliderPool then self.cellSliderPool:Dispose() end
    self.cellTaskTeamPool = nil
    self.cellDescPool = nil
    self.cellSliderPool = nil
end

function _M.RegEvent()
    Event.Reg(self, EventType.On_PQ_RequestDataReturn, function(tbPQInfo, bFieldPQ)
        if bFieldPQ then
            self.tbFieldPQInfo = tbPQInfo
        else
            self.tbPQInfo = tbPQInfo
        end

        TraceInfoData.UpdateInfo(TraceInfoType.PublicQuest)

        local bHasPQ = self.HasPQ() and not TravellingBagData.IsInTravelingMap() and not ActivityData.IsHotSpringActivity()
        Event.Dispatch(EventType.OnTogTraceInfo, TraceInfoType.PublicQuest, bHasPQ)
    end)

    Event.Reg(self, EventType.On_Update_GeneralProgressBar, function(tbInfo)
        if table.contain_value(FestivalActivities.tbLongzhouName, tbInfo.szName) then
            TraceInfoData.UpdateInfo(TraceInfoType.PublicQuest)
        end
    end)

    Event.Reg(self, EventType.On_Delete_GeneralProgressBar, function(szName)
        if table.contain_value(FestivalActivities.tbLongzhouName, szName) then
            TraceInfoData.UpdateInfo(TraceInfoType.PublicQuest)
        end
    end)

    Event.Reg(self, EventType.UpdateFBCountDown, function()
        TraceInfoData.UpdateInfo(TraceInfoType.PublicQuest)
        local bHasPQ = self.HasPQ() and not TravellingBagData.IsInTravelingMap() and not ActivityData.IsHotSpringActivity()
        Event.Dispatch(EventType.OnTogTraceInfo, TraceInfoType.PublicQuest, bHasPQ)
    end)

    Event.Reg(self, "QUEST_FAILED", function(nQuestIndex)
        local nQuestID = g_pClientPlayer and g_pClientPlayer.GetQuestID(nQuestIndex)
        if nQuestID then
            self.UpdateTraceQuestInfo(nQuestID)
        end
    end)
	Event.Reg(self, "QUEST_CANCELED", function(nQuestID)
        self.UpdateTraceQuestInfo(nQuestID)
    end)
	Event.Reg(self, "QUEST_FINISHED", function(nQuestID, bForceFinish, bAssist, nAddStamina, nAddThew)
        self.UpdateTraceQuestInfo(nQuestID)
    end)
	Event.Reg(self, "SET_QUEST_STATE", function(nQuestID, byQuestState)
        self.UpdateTraceQuestInfo(nQuestID)
    end)
	Event.Reg(self, "QUEST_SHARED", function(dwSrcPlayerID, nQuestID)
        self.UpdateTraceQuestInfo(nQuestID)
    end)
	Event.Reg(self, "QUEST_DATA_UPDATE", function(nQuestIndex, eEventType)
        local nQuestID = g_pClientPlayer and g_pClientPlayer.GetQuestID(nQuestIndex)
        if nQuestID then
            self.UpdateTraceQuestInfo(nQuestID)
        end
    end)
    Event.Reg(self, "QUEST_TIME_UPDATE", function(nQuestIndex)
        local nQuestID = g_pClientPlayer and g_pClientPlayer.GetQuestID(nQuestIndex)
        if nQuestID then
            self.UpdateTraceQuestInfo(nQuestID)
        end
    end)
end

function _M.OnUpdateView(script, scrollViewParent, tData)
    local bAddTitle = tData and tData.bAddTitle
    self.UpdatePublicQuestInfo(script, scrollViewParent, bAddTitle)
end

function _M.OnClear(script)
    script.tbPQNodeInfo = nil
    script.tbLastNodeList = nil
end

--------------------------------  --------------------------------

function _M.UpdateTaskTeamInfo(script, scrollViewParent, bScrollToTop, szText, nFrame)
    local node, scriptView = nil, nil
     if bScrollToTop then
        node, scriptView = self.cellTaskTeamPool:Allocate(scrollViewParent, szText, nFrame)
        self.AddNodeInfo(script, node, self.cellTaskTeamPool, scriptView)
    else
        node, scriptView = self.GetNextScriptView(script)
        scriptView:OnEnter(szText, nFrame)
    end
    return node, scriptView
end

function _M.UpdateDescInfo(script, scrollViewParent, bScrollToTop, szText, nTime, nFontSize, bTimeStamp)
    local node, scriptView = nil, nil
     if bScrollToTop then
        node, scriptView = self.cellDescPool:Allocate(scrollViewParent, szText, nTime, nFontSize, bTimeStamp)
        self.AddNodeInfo(script, node, self.cellDescPool, scriptView)
    else
        node, scriptView = self.GetNextScriptView(script)
        scriptView:OnEnter(szText, nTime, nFontSize, bTimeStamp)
    end
    return node, scriptView
end

function _M.UpdateSliderInfo(script, scrollViewParent, bScrollToTop, szTitle, szValue, nPercent, nWordLimit, bShowProgress)
    local node, scriptView = nil, nil
    if bScrollToTop then
        node, scriptView = self.cellSliderPool:Allocate(scrollViewParent, szTitle, szValue, nPercent, nWordLimit, bShowProgress)
        self.AddNodeInfo(script, node, self.cellSliderPool, scriptView)
    else
        node, scriptView = self.GetNextScriptView(script)
        scriptView:OnEnter(szTitle, szValue, nPercent, nWordLimit, bShowProgress)
    end
    return node, scriptView
end

function _M.UpdateQuestInfo(script, scrollViewParent, bScrollToTop, nQuestID, bPublicQuest)
    local node, scriptView = nil, nil
     if bScrollToTop then
        node, scriptView = self.cellQuestPool:Allocate(scrollViewParent, nQuestID, bPublicQuest)
        self.AddNodeInfo(script, node, self.cellQuestPool, scriptView)
    else
        node, scriptView = self.GetNextScriptView(script)
        scriptView:OnEnter(nQuestID, bPublicQuest)
    end
    return node, scriptView
end

function _M.UpdatePublicQuestInfo(script, scrollViewParent, bAddTitle)
    local tbFBCntData = FestivalActivities.GetFBCountDownData()
    local nType = tbFBCntData and tbFBCntData.nType
    local tLine = self.IsSceneCloseCountDown(nType) and Table_GetFBCountDown(nType) -- "场景关闭倒计时"特殊处理
    local szTitle = tLine and UIHelper.GBKToUTF8(tLine.szTitle)

    local bScrollToTop = self.RemovePQInfo(script, bAddTitle)

    if bAddTitle then
        local node, scriptView = self.UpdateTaskTeamInfo(script, scrollViewParent, bScrollToTop, szTitle or "世界公共任务")
        UIHelper.SetHeight(node, 44)
        scriptView:SetFontSize(26)
        UIHelper.LayoutDoLayout(node)
    end

    self.UpdateNormalPQInfo(script, scrollViewParent, bScrollToTop)
    self.UpdateFieldPQInfo(script, scrollViewParent, bScrollToTop)
    self.UpdaFBCountDown(script, scrollViewParent, bScrollToTop)
    if bScrollToTop then
        if script.nPublicQuestInfoTimer then
            Timer.DelTimer(script, script.nPublicQuestInfoTimer)
        end
        script.nPublicQuestInfoTimer = Timer.AddFrame(script, 2, function()
            UIHelper.ScrollViewDoLayoutAndToTop(scrollViewParent)
            UIHelper.ScrollViewSetupArrow(scrollViewParent, script.WidgetArrow)
        end)
    end
end

function _M.UpdateTraceQuestInfo(nQuestID)
    if not self.tbQuestList then return end
    local tbQuestInfo = self.tbQuestList[nQuestID]
    if not tbQuestInfo then return end
    tbQuestInfo.script:OnEnter(nQuestID, true)
    if self.nUpdateQuestInfoTimer then
        Timer.DelTimer(self, self.nUpdateQuestInfoTimer)
    end
    self.nUpdateQuestInfoTimer = Timer.AddFrame(self, 2, function()
        UIHelper.ScrollViewDoLayout(tbQuestInfo.scrollViewParent)
    end)
end

function _M.UpdateNormalPQInfo(script, scrollViewParent, bAllocate)
    if not self.tbPQInfo or table.is_empty(self.tbPQInfo) then
        return
    end

    local tbQuestIDList = PublicQuestData.GetShowQuestList()
    if tbQuestIDList and #tbQuestIDList > 0 then
        for nIndex, nQuestID in ipairs(tbQuestIDList) do
            local node, scriptView = self.UpdateQuestInfo(script, scrollViewParent, bAllocate, nQuestID, true)
            UIHelper.SetPositionX(node, UIHelper.GetWidth(node) / 2)
            self.tbQuestList[nQuestID] = {script = scriptView, scrollViewParent = scrollViewParent}
        end

        local node, scriptView = self.UpdateTaskTeamInfo(script, scrollViewParent, bAllocate, "")
        UIHelper.SetHeight(node, 5)
        UIHelper.LayoutDoLayout(node)
    end

    local tbPQInfo = self.GetViewPQInfo()
    for index, tbInfo in ipairs(tbPQInfo) do
        local tbShow = UIPQAtrriubuteShowTab[tbInfo.nPQID]

        if tbInfo.szMainTitle ~= "" then
            local node, scriptView = self.UpdateTaskTeamInfo(script, scrollViewParent, bAllocate, UIHelper.GBKToUTF8(tbInfo.szMainTitle), tbInfo.nMainFrame)

            UIHelper.SetHeight(node, 44)
            scriptView:SetFontSize(26)

            --温泉山庄详情按钮
            if ActivityData.IsHotSpringActivity() then
                scriptView:SetDetailBtnVis(true)
                scriptView:SetDetailClickCallBack(function()
                    UIMgr.Open(VIEW_ID.PanelActivityTaskTarce, ActivityTraceInfoType.WenQuanShanZhuang)
                end)
            end

            UIHelper.LayoutDoLayout(node)
        end

        if tbInfo.szMainText ~= "" and ((tbShow and tbShow.ShowMainText) or (not tbShow)) then
            self.UpdateDescInfo(script, scrollViewParent, bAllocate, UIHelper.GBKToUTF8(tbInfo.szMainText), nil, 24)
        end

        if tbInfo.szSubTitle ~= "" and ((tbShow and tbShow.ShowSubTitle) or (not tbShow)) then
            local node, scriptView = self.UpdateTaskTeamInfo(script, scrollViewParent, bAllocate, UIHelper.GBKToUTF8(tbInfo.szSubTitle))
            UIHelper.SetHeight(node, 44)
            local tbTeachInfo = Table_GetPQTeachInfo(tbInfo.dwPQID)
            if tbTeachInfo then
                scriptView:SetBtnHintVis(true)
                scriptView:SetClickCallBack(function()
                    TeachBoxData.OpenTutorialPanel(tbTeachInfo.dwTeachID)
                end)
            end
            UIHelper.LayoutDoLayout(node)
        end

        if tbInfo.szSubText ~= "" and ((tbShow and tbShow.ShowSubText) or (not tbShow)) then
            local szSubText = UIHelper.AttachTextColor(UIHelper.GBKToUTF8(tbInfo.szSubText), FontColorID.Text_Level1_Backup)
            self.UpdateDescInfo(script, scrollViewParent, bAllocate, szSubText, nil, 24)
        end

        if tbInfo.nSelf then
            local szText = FormatString(g_tStrings.STR_NEW_PQ_MY_SELF_PROGRESS, tbInfo.nSelf, MY_SELF_MAX_VALUE)
            self.UpdateDescInfo(script, scrollViewParent, bAllocate, szText, nil, 24)
        end

        -- --数值1显示方式（1：分子/分母），2：进度条，3：boss血量（百分比），4倒计时，倒计时的单位是秒），5：倒计时，nValue为结束时间的时间戳，6单个数字
        local tbPQValues = tbInfo.tbPQValues
        for key, nValue in pairs(tbPQValues) do
            if tbInfo["nValueType"..key] == 1 then
                local szText = FormatString(g_tStrings.STR_NEW_PQ_TYPE1, UIHelper.GBKToUTF8(tbInfo["szValueText"..key]), nValue, tbInfo["dwValueMax"..key])
                self.UpdateDescInfo(script, scrollViewParent, bAllocate, szText, nil, 24)
            elseif tbInfo["nValueType"..key] == 2 then
                local szTitle = tbInfo["szValueText"..key]
                local szValue = FormatString(g_tStrings.STR_NEW_PQ_TYPE2, nValue, tbInfo["dwValueMax"..key])
                local nPercent = nValue / tbInfo["dwValueMax"..key] * 100
                self.UpdateSliderInfo(script, scrollViewParent, bAllocate, szTitle, szValue, nPercent)
            elseif tbInfo["nValueType"..key] == 3 then
                local szTitle = tbInfo["szValueText"..key]
                local szValue = string.format("%.0f%%", nValue / tbInfo["dwValueMax"..key] * 100)
                local nPercent = nValue / tbInfo["dwValueMax"..key] * 100
                self.UpdateSliderInfo(script, scrollViewParent, bAllocate, szTitle, szValue, nPercent)
            elseif tbInfo["nValueType"..key] == 4 then
                local szText = tbInfo["szValueText"..key]
                self.UpdateDescInfo(script, scrollViewParent, bAllocate, UIHelper.GBKToUTF8(szText), nValue, 24)
            elseif tbInfo["nValueType"..key] == 5 then
                local szText = tbInfo["szValueText"..key]
                self.UpdateDescInfo(script, scrollViewParent, bAllocate, UIHelper.GBKToUTF8(szText), nValue, 24, true)
            elseif tbInfo["nValueType"..key] == 6 then
                local szText = FormatString(g_tStrings.STR_NEW_PQ_TYPE4, UIHelper.GBKToUTF8(tbInfo["szValueText"..key]), nValue)
                self.UpdateDescInfo(script, scrollViewParent, bAllocate, szText, nil, 24)
            end
        end
    end


    if FestivalActivities.bLongZhou then
        self.UpdateLongZhouInfo(script, scrollViewParent, bAllocate)
    end
end

function _M.UpdateLongZhouInfo(script, scrollViewParent, bAllocate)
    for _, szName in ipairs(FestivalActivities.tbLongzhouName) do
        local tbInfo = FestivalActivities.tbProgressBarData[szName]
        self.UpdateSliderInfo(script, scrollViewParent, bAllocate, tbInfo.szDiscrible, tbInfo.nMolecular .. "/" .. tbInfo.nDenominator, tbInfo.nMolecular / tbInfo.nDenominator * 100, nil, true)
    end
end

--根据条件获取实际要显示的PQ信息
function _M.GetViewPQInfo()
    local tbPQInfo = self.tbPQInfo

    --温泉山庄显示顺序特殊处理
    if ActivityData.IsHotSpringActivity() then
        tbPQInfo = {}
        local tbMainInfo = nil
        for index, tbInfo in ipairs(self.tbPQInfo) do
            if tbInfo.dwPQID ~= 248 then
                table.insert(tbPQInfo, tbInfo)
            else
                tbMainInfo = tbInfo
            end
        end
        if tbMainInfo then
            if #tbPQInfo ~= 0 then
                local tbCloneInfo = clone(tbMainInfo)
                tbCloneInfo.tbPQValues = tbMainInfo.tbPQValues
                tbCloneInfo.szMainTitle = ""
                table.insert(tbPQInfo, tbCloneInfo)
            else
                table.insert(tbPQInfo, tbMainInfo)
            end
        end
    end

    for index, tbInfo in ipairs(tbPQInfo) do
        if tbInfo.dwPQID == 450 then--450春节活动排在最下面显示--策划需求鹏宇
            table.remove(tbPQInfo, index)
            table.insert(tbPQInfo, tbInfo)
            break
        end
    end

    return tbPQInfo
end

function _M.UpdateFieldPQInfo(script, scrollViewParent, bAllocate)
    local tbFieldPQInfo = self.tbFieldPQInfo
    if not tbFieldPQInfo or table.is_empty(tbFieldPQInfo) then
        return
    end

    if tbFieldPQInfo.szPQState then
        self.UpdateDescInfo(script, scrollViewParent, bAllocate, tbFieldPQInfo.szPQState, nil, 24)
    end

    if tbFieldPQInfo.szPQStep then
        self.UpdateDescInfo(script, scrollViewParent, bAllocate, tbFieldPQInfo.szPQStep, nil, 24)
    end

    if tbFieldPQInfo.szTraceTitle then
         self.UpdateDescInfo(script, scrollViewParent, bAllocate, tbFieldPQInfo.szTraceTitle, nil, 24)
    end

    for index, szText in ipairs(tbFieldPQInfo.tbPQValues or {}) do
        self.UpdateDescInfo(script, scrollViewParent, bAllocate, szText, nil, 24)
    end
end

function _M.UpdaFBCountDown(script, scrollViewParent, bScrollToTop)

    local tbData = FestivalActivities.GetFBCountDownData()
    if not tbData then
        return
    end
    local nType = tbData.nType
    local nStartTime = tbData.nStartTime
    local nEndTime = tbData.nEndTime
    local tLine = Table_GetFBCountDown(nType)
    if not tLine then
        return
    end

    script.FBSliderNode, script.scriptFBSlider = nil, nil
    if not table.contain_value(tFBCountDownType, nType) then
        local szText = UIHelper.GBKToUTF8(tLine.szTitle)
        self.UpdateDescInfo(script, scrollViewParent, bScrollToTop, szText, nil, 24)
    end

    local function UpdateSlider()
        local nTime = GetCurrentTime()
        if nEndTime < nTime then return end
        local szTimeText = nil
        local fProgress = nil
        if tLine.bLeft_Right then --正计时
            szTimeText = UIHelper.GetCoolTimeText(nTime - nStartTime)
            fProgress = (nTime - nStartTime) / (nEndTime - nStartTime)
            fProgress = fProgress * 100
        else
            local nLeft = nEndTime - nTime
            if nLeft < 0 then
                nLeft = 0
            end

            szTimeText = UIHelper.GetCoolTimeText(nLeft)
            fProgress = (nTime - nStartTime) / (nEndTime - nStartTime)
            if fProgress < 0 then
                fProgress = 0
            end
            fProgress = (1 - fProgress) * 100
        end
        if not script.scriptFBSlider then
            script.FBSliderNode, script.scriptFBSlider = self.UpdateSliderInfo(script, scrollViewParent, bScrollToTop, "", szTimeText, fProgress, 10, true)
        else
            if script.scriptFBSlider.OnEnter == nil then
                Timer.DelTimer(script, script.nTimer)
                local tbData = FestivalActivities.GetFBCountDownData()
                if tbData == nil then -- 做下清除，顺便刷一下UI
                    FestivalActivities.ClearFBCountDown()
                end

                return
            end

            script.scriptFBSlider:OnEnter("", szTimeText, fProgress, 10, true)
        end
    end

    if script.nTimer then
        Timer.DelTimer(script, script.nTimer)
        script.nTimer = nil
    end

    UpdateSlider()
    script.nTimer = Timer.AddCycle(script, 1, function ()
        UpdateSlider()
    end)
end

function _M.AddNodeInfo(script, node, pool, scriptView)
    table.insert(script.tbPQNodeInfo, {node = node, pool = pool, scriptView = scriptView})
end

function _M.RemovePQInfo(script, bAddTitle)
    self.tbQuestList = {}
    script.nScriptViewIndex = 1
    local tbPoolList = self.GetPrefabPoolList(script, bAddTitle)
    local tbNowPoolList = self.GetNowPrefabPoolList(script)
    if PublicQuestData.IsTableEqual(tbNowPoolList, tbPoolList) then return false end

    for index, tbInfo in ipairs(script.tbPQNodeInfo or {}) do
        tbInfo.pool:Recycle(tbInfo.node)
    end
    script.tbPQNodeInfo = {}
    return true
end

function _M.GetNextScriptView(script)
    if script.tbPQNodeInfo and #script.tbPQNodeInfo >= script.nScriptViewIndex then
        local tbInfo = script.tbPQNodeInfo[script.nScriptViewIndex]
        script.nScriptViewIndex = script.nScriptViewIndex + 1
        return tbInfo.node, tbInfo.scriptView
    end
    return nil
end

function _M.GetNowPrefabPoolList(script)
    local tbPrefabList = {}
    for index, tbInfo in ipairs(script.tbPQNodeInfo or {}) do
        table.insert(tbPrefabList, tbInfo.pool)
    end
    return tbPrefabList
end

function _M.GetPrefabPoolList(script, bAddTitle)
    local tbPoolList = {}
    if bAddTitle then
        table.insert(tbPoolList, self.cellTaskTeamPool)
    end

    local tbQuestIDList = PublicQuestData.GetShowQuestList()
    if tbQuestIDList and #tbQuestIDList > 0 then
        for nIndex, nQuestID in ipairs(tbQuestIDList) do
            table.insert(tbPoolList, self.cellQuestPool)
        end

        table.insert(tbPoolList, self.cellTaskTeamPool)
    end

    local tbPQInfo = self.GetViewPQInfo()

    if tbPQInfo then
        for index, tbInfo in ipairs(tbPQInfo) do
            local tbShow = UIPQAtrriubuteShowTab[tbInfo.nPQID]

            if tbInfo.szMainTitle ~= "" then
                table.insert(tbPoolList, self.cellTaskTeamPool)
            end

            if tbInfo.szMainText ~= "" and ((tbShow and tbShow.ShowMainText) or (not tbShow)) then
                table.insert(tbPoolList, self.cellDescPool)
            end

            if tbInfo.szSubTitle ~= "" and ((tbShow and tbShow.ShowSubTitle) or (not tbShow)) then
                table.insert(tbPoolList, self.cellTaskTeamPool)
            end

            if tbInfo.szSubText ~= "" and ((tbShow and tbShow.ShowSubText) or (not tbShow)) then
                table.insert(tbPoolList, self.cellDescPool)
            end

            if tbInfo.nSelf then
                table.insert(tbPoolList, self.cellDescPool)
            end

            -- --数值1显示方式（1：分子/分母），2：进度条，3：boss血量（百分比），4倒计时，倒计时的单位是秒），5：倒计时，nValue为结束时间的时间戳，6单个数字
            local tbPQValues = tbInfo.tbPQValues
            for key, nValue in pairs(tbPQValues) do
                if tbInfo["nValueType"..key] == 1 then
                    table.insert(tbPoolList, self.cellDescPool)
                elseif tbInfo["nValueType"..key] == 2 then
                    table.insert(tbPoolList, self.cellSliderPool)
                elseif tbInfo["nValueType"..key] == 3 then
                    table.insert(tbPoolList, self.cellSliderPool)
                elseif tbInfo["nValueType"..key] == 4 then
                    table.insert(tbPoolList, self.cellDescPool)
                elseif tbInfo["nValueType"..key] == 5 then
                    table.insert(tbPoolList, self.cellDescPool)
                elseif tbInfo["nValueType"..key] == 6 then
                    table.insert(tbPoolList, self.cellDescPool)
                end
            end
        end
    end


    if FestivalActivities.bLongZhou then
        for _, szName in ipairs(FestivalActivities.tbLongzhouName) do
            table.insert(tbPoolList, self.cellSliderPool)
        end
    end

    local tbFieldPQInfo = self.tbFieldPQInfo
    if tbFieldPQInfo and not table.is_empty(tbFieldPQInfo) then
        if tbFieldPQInfo.szPQState then
            table.insert(tbPoolList, self.cellDescPool)
        end

        if tbFieldPQInfo.szPQStep then
            table.insert(tbPoolList, self.cellDescPool)
        end

        if tbFieldPQInfo.szTraceTitle then
            table.insert(tbPoolList, self.cellDescPool)
        end

        for index, szText in ipairs(tbFieldPQInfo.tbPQValues or {}) do
            table.insert(tbPoolList, self.cellDescPool)
        end
    end

    local tbData = FestivalActivities.GetFBCountDownData()
    if tbData then
        table.insert(tbPoolList, self.cellDescPool)
        table.insert(tbPoolList, self.cellSliderPool)
    end


    return tbPoolList

end


function _M.HasPQ()
    if self.tbFieldPQInfo and not table.is_empty(self.tbFieldPQInfo) then
        return true
    end
    if self.tbPQInfo and #self.tbPQInfo > 0 then
        return true
    end
    local tbData = FestivalActivities.GetFBCountDownData()
    if tbData then
        return true
    end

    return false
end

-- 场景关闭倒计时
function _M.IsSceneCloseCountDown(nType)
    return table.contain_value(tFBCountDownType, nType)
end

-- 场景关闭倒计时
function _M.FBCountDownIsSceneClose()
    local tbFBCntData = FestivalActivities.GetFBCountDownData()
    local nType = tbFBCntData and tbFBCntData.nType or 0
    return table.contain_value(tFBCountDownType, nType)
end

return _M
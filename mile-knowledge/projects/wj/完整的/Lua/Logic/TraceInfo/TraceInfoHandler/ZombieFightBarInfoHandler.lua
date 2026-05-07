local _M      = { className = "ZombieFightBarInfoHandler" }
local self    = _M

--李渡鬼域
_M.szInfoType = TraceInfoType.ZombieFightBar

function _M.Init()
    self.RegEvent()

end

function _M.UnInit()
    Event.UnRegAll(self)
    Timer.DelAllTimer(self)

end

function _M.RegEvent()
    -- 刷新数据
    Event.Reg(self, "VampireInfoPanel_Open", function(tVampireUIInfo, bDisableSound)
        self.tInfo               = self.tInfo or {}
        self.tInfo.nNumOfHuman   = tVampireUIInfo.nNumOfHuman
        self.tInfo.nNumOfVampire = tVampireUIInfo.nNumOfVampire
        self.tInfo.dwStartTime   = tVampireUIInfo.dwStartTime
        self.tInfo.nSecPerGame   = tVampireUIInfo.nSecPerGame

        TraceInfoData.UpdateInfo(TraceInfoType.ZombieFightBar)
        Event.Dispatch(EventType.OnTogTraceInfo, TraceInfoType.ZombieFightBar, true)
    end)

    Event.Reg(self, "VampireInfoPanel_UpdateNumOfPlayer", function(nNumOfHuman, nNumOfVampire)
        self.tInfo               = self.tInfo or {}
        self.tInfo.nNumOfHuman   = nNumOfHuman
        self.tInfo.nNumOfVampire = nNumOfVampire

        TraceInfoData.UpdateInfo(TraceInfoType.ZombieFightBar)
        Event.Dispatch(EventType.OnTogTraceInfo, TraceInfoType.ZombieFightBar, true)
    end)

    Event.Reg(self, "VampireInfoPanel_UpdateScore", function(nSelfScore, nPeopleScore, nMaxPeopleScore)
        self.tScore                 = self.tScore or {}
        self.tScore.nSelfScore      = nSelfScore
        self.tScore.nPeopleScore    = nPeopleScore
        self.tScore.nMaxPeopleScore = nMaxPeopleScore

        TraceInfoData.UpdateInfo(TraceInfoType.ZombieFightBar)
        Event.Dispatch(EventType.OnTogTraceInfo, TraceInfoType.ZombieFightBar, true)
    end)

    Event.Reg(self, "VampireInfoPanel_UpdateSoul", function(nIndex, nNumerator, nDenominator, bHide)
        self.tSoul              = self.tSoul or {}
        self.tSoul.nIndex       = nIndex
        self.tSoul.nNumerator   = nNumerator
        self.tSoul.nDenominator = nDenominator
        self.tSoul.bHide        = bHide

        TraceInfoData.UpdateInfo(TraceInfoType.ZombieFightBar)
        Event.Dispatch(EventType.OnTogTraceInfo, TraceInfoType.ZombieFightBar, true)
    end)

    -- 退出玩法，到达其他新场景时移除数据，并取消显示
    Event.Reg(self, EventType.OnClientPlayerEnter, function()
        local bIsInZombieBattleFieldMap = BattleFieldData.IsInZombieBattleFieldMap()
        if not bIsInZombieBattleFieldMap and g_pClientPlayer then
            self.tInfo  = nil
            self.tScore = nil
            self.tSoul  = nil

            TraceInfoData.UpdateInfo(TraceInfoType.ZombieFightBar)
            Event.Dispatch(EventType.OnTogTraceInfo, TraceInfoType.ZombieFightBar, false)
        end
    end)
end

function _M.OnUpdateView(script, scrollViewParent, tData)
    self.UpdateZombieFightBarInfo(script, scrollViewParent)
end

function _M.OnClear(script)
    Timer.DelTimer(script, script.nRemainingTimeTimerID)
    script.nRemainingTimeTimerID  = nil
end

--------------------------------  --------------------------------
function _batchSetVisible(bVisible, ...)
    local tScriptList = { ... }
    for _, tScript in ipairs(tScriptList) do
        if tScript then
            UIHelper.SetVisible(tScript._rootNode, bVisible)
        end
    end
end

function _M.UpdateZombieFightBarInfo(script, scrollViewParent)
    if self.tScore == nil and self.tInfo == nil and self.tSoul == nil then
        return
    end

    -- 剩余时间
    local fnGetRemainingTime = function()
        if not self.tInfo or not self.tInfo.nSecPerGame then
            return "15:00"
        end

        local nDisplayTime = self.tInfo.nSecPerGame
        local nCurTime     = GetCurrentTime()
        if nCurTime > self.tInfo.dwStartTime then
            nDisplayTime = self.tInfo.nSecPerGame - (nCurTime - self.tInfo.dwStartTime)
        end
        if nDisplayTime < 0 then
            nDisplayTime = 0
        end

        local nDisplayMin = math.floor(nDisplayTime / 60)
        local nDisplaySec = nDisplayTime % 60

        return string.format("%02d:%02d", nDisplayMin, nDisplaySec)
    end


    -- 仅在首次显示时，添加各个组件，后续则仅更新对应的数据
    if not script.bInitWidgets then
        UIHelper.RemoveAllChildren(scrollViewParent)

        --- [[ self.tScore ]]
        -- 胜利条件
        script.tScript_Score_WinCondition             = UIHelper.AddPrefab(PREFAB_ID.WidgetTaskTeamSubtitle, scrollViewParent, "探秘者胜利条件", 5)
        script.tScript_Score_WinCondition_SampleTitle = UIHelper.AddPrefab(PREFAB_ID.WidgetRichTextOtherDescribe, scrollViewParent, "尸毒样本")
        ---@type UIWidgetRichTextOtherDescribe
        script.tScript_Score_WinCondition_SampleCount = UIHelper.AddPrefab(PREFAB_ID.WidgetRichTextOtherDescribe, scrollViewParent, "0/240")

        -- 个人得分
        script.tScript_Score_PersonalScore            = UIHelper.AddPrefab(PREFAB_ID.WidgetTaskTeamSubtitle, scrollViewParent, "个人得分", 5)
        ---@type UIWidgetRichTextOtherDescribe
        script.tScript_Score_PersonalScore_Count      = UIHelper.AddPrefab(PREFAB_ID.WidgetRichTextOtherDescribe, scrollViewParent, "0")

        --- [[ self.tInfo ]]
        script.tScript_Info_RemainingTime             = UIHelper.AddPrefab(PREFAB_ID.WidgetTaskTeamSubtitle, scrollViewParent, "剩余时间", 5)
        ---@type UIWidgetRichTextOtherDescribe
        script.tScript_Info_RemainingTime_CellTime    = UIHelper.AddPrefab(PREFAB_ID.WidgetRichTextOtherDescribe, scrollViewParent, "15:00")
        script.nRemainingTimeTimerID                  = script.nRemainingTimeTimerID or Timer.AddCycle(script, 0.5, function()
            script.tScript_Info_RemainingTime_CellTime:UpdateInfo(fnGetRemainingTime())
        end)

        -- 剩余人数
        script.tScript_Info_RemainingPeople           = UIHelper.AddPrefab(PREFAB_ID.WidgetTaskTeamSubtitle, scrollViewParent, "剩余人数", 5)
        ---@type UIWidgetRichTextOtherDescribe
        script.tScript_Info_RemainingPeople_Count     = UIHelper.AddPrefab(PREFAB_ID.WidgetRichTextOtherDescribe, scrollViewParent, "1")

        --- [[ self.tSoul ]]
        -- 魂铃
        script.tScript_Soul                           = UIHelper.AddPrefab(PREFAB_ID.WidgetTaskTeamSubtitle, scrollViewParent, "魂铃", 5)
        ---@type UIWidgetRichTextOtherDescribe
        script.tScript_Soul_Stage                     = UIHelper.AddPrefab(PREFAB_ID.WidgetRichTextOtherDescribe, scrollViewParent, "阶段1")
        ---@type UIWidgetRichTextOtherDescribe
        script.tScript_Soul_Progress                  = UIHelper.AddPrefab(PREFAB_ID.WidgetRichTextOtherDescribe, scrollViewParent, "1/30")

        script.bInitWidgets                           = true
    end

    -- 用于判断当前显示了那几个部分，当发生变动时，需要重新排版
    local nVisiblePartMask = 0

    _batchSetVisible(self.tScore ~= nil,
                     script.tScript_Score_WinCondition, script.tScript_Score_WinCondition_SampleTitle, script.tScript_Score_WinCondition_SampleCount,
                     script.tScript_Score_PersonalScore, script.tScript_Score_PersonalScore_Count
    )
    if self.tScore ~= nil then
        nVisiblePartMask = kmath.add_bit(nVisiblePartMask, 1)

        -- 胜利条件
        script.tScript_Score_WinCondition_SampleCount:UpdateInfo(string.format("%d/%d", self.tScore.nPeopleScore, self.tScore.nMaxPeopleScore))

        -- 个人得分
        script.tScript_Score_PersonalScore_Count:UpdateInfo(self.tScore.nSelfScore)
    end

    _batchSetVisible(self.tInfo ~= nil,
                     script.tScript_Info_RemainingTime, script.tScript_Info_RemainingTime_CellTime,
                     script.tScript_Info_RemainingPeople, script.tScript_Info_RemainingPeople_Count
    )
    if self.tInfo ~= nil then
        nVisiblePartMask = kmath.add_bit(nVisiblePartMask, 2)

        script.tScript_Info_RemainingTime_CellTime:UpdateInfo(fnGetRemainingTime())

        -- 剩余人数
        script.tScript_Info_RemainingPeople_Count:UpdateInfo(self.tInfo.nNumOfHuman)
    end

    _batchSetVisible(self.tSoul ~= nil and not self.tSoul.bHide,
                     script.tScript_Soul, script.tScript_Soul_Stage, script.tScript_Soul_Progress
    )
    if self.tSoul ~= nil and not self.tSoul.bHide then
        nVisiblePartMask = kmath.add_bit(nVisiblePartMask, 3)

        -- 魂铃
        script.tScript_Soul_Stage:UpdateInfo(string.format("阶段%d", self.tSoul.nIndex))
        script.tScript_Soul_Progress:UpdateInfo(string.format("%d/%d", self.tSoul.nNumerator, self.tSoul.nDenominator))
    end

    if script.nVisiblePartMask ~= nVisiblePartMask then
        script.nVisiblePartMask = nVisiblePartMask

        UIHelper.CascadeDoLayoutDoWidget(scrollViewParent)
        UIHelper.ScrollViewDoLayoutAndToTop(scrollViewParent)
    end
end

return _M
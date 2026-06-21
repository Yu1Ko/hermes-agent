-- ---------------------------------------------------------------------------------
-- Name: UIWidgetTimelyHintSmallCell
-- WidgetTimelyHintSmallCell
-- ---------------------------------------------------------------------------------

local UIWidgetTimelyHintSmallCell = class("UIWidgetTimelyHintSmallCell")
local nShowTime = 10

function UIWidgetTimelyHintSmallCell:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIWidgetTimelyHintSmallCell:OnExit()
    self.bInit = false
end

function UIWidgetTimelyHintSmallCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnTimelyHint, EventType.OnClick, function ()
        TipsHelper.SetSmallEvent(tEvent)
        self:SwitchToSmallOrBig(true, tEvent[1])
        TipsHelper.ClearCurEvent(TipsHelper.Def.Queue3)
        TimelyMessagesBtnData.OnClickBtn(TimelyMessagesType.Team)
    end)
end

function UIWidgetTimelyHintSmallCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetTimelyHintSmallCell:Change2Small(szEventName)
    self.szEventName = szEventName
    local tEvent = TipsHelper.GetSmallEvent(szEventName)
    self.nRemain = tEvent.nRemain
    self.tEvent = tEvent

-- 数字设置
    if szEventName == EventType.ShowTeamTip then
        local tbInfos = TimelyMessagesBtnData.GetBtnInfos(TimelyMessagesType.Team)
        UIHelper.SetString(self.LabelCount, #tbInfos)
    else
        UIHelper.SetString(self.LabelCount, #tEvent[2])
    end

-- 定时器设置
    if self.nSmallTimer then
        Timer.DelTimer(self, self.nSmallTimer)
        self.nSmallTimer = nil
    end

    if szEventName == EventType.ShowTeamTip then
        self.nSmallTimer = Timer.AddFrameCycle(self, 1, function ()
            local nLeftTime, nTotalTime = self:GetTeamLeftTime()
            UIHelper.SetProgressBarPercent(self.SilderTimely,  nLeftTime / nTotalTime * 100)

            if nLeftTime <= 0 then
                UIHelper.SetVisible(self._rootNode, false)
                Timer.DelTimer(self, self.nSmallTimer)
                self.nSmallTimer = nil
                TipsHelper.ClearSmallEvent(szEventName)
                TipsHelper.NextTip(TipsHelper.Def.Queue3)
            end
        end)
    else
        local nFrameTotal = nShowTime * 10
        local nFrameRemain = self.nRemain * 10
        UIHelper.SetProgressBarPercent(self.SilderTimely,  nFrameRemain / nFrameTotal * 100)

        self.nSmallTimer = Timer.AddFrameCycle(self, 3, function ()
            nFrameRemain = nFrameRemain - 1
            self.nRemain = math.floor(nFrameRemain / 10)
            UIHelper.SetProgressBarPercent(self.SilderTimely,  nFrameRemain / nFrameTotal * 100)

            if nFrameRemain <= 0 then
                UIHelper.SetVisible(self.SilderTimely, false)
                Timer.DelTimer(self, self.SilderTimely)
                self.nSmallTimer = nil
                TipsHelper.ClearSmallEvent(szEventName)
                if tEvent[2] and tEvent[2].fnCancelAction then
                    tEvent[2].fnCancelAction()
                end
                TipsHelper.NextTip(TipsHelper.Def.Queue3)
            end
        end)
    end

-- 事件
    if szEventName == EventType.ShowTeamTip then
        UIHelper.BindUIEvent(self.BtnTimelyHint, EventType.OnClick, function ()
            TimelyMessagesBtnData.OnClickBtn(TimelyMessagesType.Team)
        end)
    elseif szEventName == EventType.ShowLikeTip and #tEvent[2] > 1 then
        UIHelper.BindUIEvent(self.BtnTimelyHint, EventType.OnClick, function ()
            local scriptView = UIMgr.Open(VIEW_ID.PanelInvitationMessagePop)
            if scriptView then
                scriptView:UpdateLikeMore(tEvent[3], self.nRemain, tEvent[2])
            end
        end)
    else
        UIHelper.BindUIEvent(self.BtnTimelyHint, EventType.OnClick, function ()
            self:Change2Big()
        end)
    end

-- 图标
    --
end

function UIWidgetTimelyHintSmallCell:Change2Big()
    local beforeEvent = TipsHelper.GetCurEvent(TipsHelper.Def.Queue3)
    if beforeEvent then
        self:HideCurEvent(beforeEvent[1], true)
    end

    self.tEvent.nRemain = self.nRemain
    TipsHelper.SetCurEvent(TipsHelper.Def.Queue3, self.tEvent)
    TipsHelper.ClearSmallEvent(self.szEventName)
    Event.Dispatch(unpack(self.tEvent))

    if self.nSmallTimer then
        Timer.DelTimer(self, self.nSmallTimer)
        self.nSmallTimer = nil
    end
    UIHelper.SetVisible(self._rootNode, false)
end

function UIWidgetTimelyHintSmallCell:HideCurEvent(szEventName, bStore)
    if TipsHelper.CheckCanSmall(TipsHelper.Def.Queue3, szEventName) then
        if bStore then
            local tEvent = TipsHelper.GetCurEvent(TipsHelper.Def.Queue3)
            if tEvent then
                TipsHelper.SetSmallEvent(tEvent)
            end
        end
        -- todo  不能直接调用self的
        self:Change2Small(szEventName)
    else
        TipsHelper.DispatchCloseEvent(szEventName)
    end
end

function UIWidgetTimelyHintSmallCell:GetTeamLeftTime()
    local nLeftTime = 0
    local nTotalTime = 0

    local tbInfos = TimelyMessagesBtnData.GetBtnInfos(TimelyMessagesType.Team)
    for i, tbInfo in ipairs(tbInfos) do
        local nTempLeftTime = (tbInfo.nTotalTime - (GetTickCount() - tbInfo.nTimestamp) / 1000)
        if nTempLeftTime > nLeftTime then
            nLeftTime = nTempLeftTime
            nTotalTime = tbInfo.nTotalTime
        end
    end
    return nLeftTime, nTotalTime
end

return UIWidgetTimelyHintSmallCell
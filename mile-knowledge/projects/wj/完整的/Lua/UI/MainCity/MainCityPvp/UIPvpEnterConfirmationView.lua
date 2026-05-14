-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPvpEnterConfirmationView
-- Date: 2022-12-13 09:44:58
-- Desc: ?
-- Prefab: PanelPvpEnterConfirmation
-- ---------------------------------------------------------------------------------

local UIPvpEnterConfirmationView = class("UIPvpEnterConfirmationView")

-- tbInfo = {
--     szTitle = "",
--     onClickCancelQueue = function () end,
--     onClickGoOnQueue = function () end,
--     onClickEnter = function () end,
-- }
function UIPvpEnterConfirmationView:OnEnter(nPlayEnterConfirmationType, nPlayType, tbInfo)
    self.nPlayEnterConfirmationType = nPlayEnterConfirmationType
    self.nPlayType = nPlayType
    self.tbInfo = tbInfo

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    local tbData = PvpEnterConfirmationData.GetData(nPlayType)
    UIHelper.SetSelected(self.TogHintNormal, tbData.bAutoEnter, false)

    self:UpdateInfo()
end

function UIPvpEnterConfirmationView:OnExit()
    self.bInit = false
end

function UIPvpEnterConfirmationView:BindUIEvent()
    --取消匹配
    UIHelper.BindUIEvent(self.BtnCalloff, EventType.OnClick, function()
        if self.tbInfo and self.tbInfo.onClickCancelQueue then
            self.tbInfo.onClickCancelQueue()
        end
        PvpEnterConfirmationData.CloseView(self.nPlayType)
    end)

    --放弃
    UIHelper.BindUIEvent(self.BtnGiveUp, EventType.OnClick, function()
        if self.tbInfo and self.tbInfo.onClickGiveUp then
            self.tbInfo.onClickGiveUp()
        end
    end)

    --继续匹配
    UIHelper.BindUIEvent(self.BtnOk, EventType.OnClick, function()
        if self.tbInfo and self.tbInfo.onClickGoOnQueue then
            self.tbInfo.onClickGoOnQueue()
        end
        PvpEnterConfirmationData.CloseView(self.nPlayType)
    end)

    --确认进入
    UIHelper.BindUIEvent(self.BtnGo, EventType.OnClick, function()
        if self.tbInfo and self.tbInfo.onClickEnter then
            self.tbInfo.onClickEnter()
        end
        PvpEnterConfirmationData.CloseView(self.nPlayType)
    end)

    --隐藏
    UIHelper.BindUIEvent(self.BtnHide, EventType.OnClick, function()
        PvpEnterConfirmationData.HideView(self.nPlayType)
    end)

    UIHelper.BindUIEvent(self.TogHintNormal, EventType.OnSelectChanged, function(_, bSelected)
        PvpEnterConfirmationData.SetAutoEnter(self.nPlayType, bSelected)
    end)
end

function UIPvpEnterConfirmationView:RegEvent()
    Event.Reg(self, "ARENA_UPDATE_TIME", function()
        self:UpdateInfo()
    end)

    Event.Reg(self, "BATTLE_FIELD_UPDATE_TIME", function()
        self:UpdateInfo()
    end)

    Event.Reg(self, "TONG_BATTLE_FIELD_UPDATE_TIME", function()
        self:UpdateInfo()
    end)
end

function UIPvpEnterConfirmationView:UpdateInfo()
    if self.nPlayEnterConfirmationType == PlayEnterConfirmationType.InQueue then
        self:UpdateInQueueInfo()
    elseif self.nPlayEnterConfirmationType == PlayEnterConfirmationType.Enter then
        self:UpdateEnterInfo()
    end
end

function UIPvpEnterConfirmationView:UpdateInQueueInfo()
    UIHelper.SetVisible(self.WidgetContentQueue, true)
    UIHelper.SetVisible(self.WidgetContentEnter, false)
    UIHelper.SetVisible(self.BtnCalloff, true)
    UIHelper.SetVisible(self.BtnOk, true)
    UIHelper.SetVisible(self.BtnGo, false)
    UIHelper.SetVisible(self.BtnHide, false)
    UIHelper.SetVisible(self.BtnGiveUp, false)
    UIHelper.LayoutDoLayout(self.LayoutBtn)

    if self.nPlayType == PlayType.Arena then
        local nPassTime, nAvgQueueTime = ArenaData.GetQueueTime()
        UIHelper.SetString(self.LabelTitleQueue, self.tbInfo.szTitle or "")
        UIHelper.SetString(self.LabelContentTime1, ArenaData.FormatArenaTime(nAvgQueueTime))
        UIHelper.SetString(self.LabelContentTime2, ArenaData.FormatArenaTime(nPassTime))
    elseif self.nPlayType == PlayType.BattleField then
        local nPassTime, nAvgQueueTime = BattleFieldQueueData.GetQueueTime()
        UIHelper.SetString(self.LabelTitleQueue, self.tbInfo.szTitle or "")
        UIHelper.SetString(self.LabelContentTime1, BattleFieldQueueData.FormatBattleFieldTime(nAvgQueueTime))
        UIHelper.SetString(self.LabelContentTime2, BattleFieldQueueData.FormatBattleFieldTime(nPassTime))
    elseif self.nPlayType == PlayType.TongBattleField then
        local nPassTime = BattleFieldQueueData.GetTongBattleFieldQueueTime()
        UIHelper.SetString(self.LabelTitleQueue, self.tbInfo.szTitle or "")
        UIHelper.SetString(self.LabelContentTitle1, "已排队：")
        UIHelper.SetString(self.LabelContentTime1, BattleFieldQueueData.FormatBattleFieldTime(nPassTime))

        -- 帮会约战没有预计排队时间数据
        UIHelper.SetVisible(self.LabelContentTitle2, false)
        UIHelper.SetVisible(self.LabelContentTime2, false)
    end
end

function UIPvpEnterConfirmationView:UpdateEnterInfo()
    UIHelper.SetVisible(self.WidgetContentQueue, false)
    UIHelper.SetVisible(self.WidgetContentEnter, true)
    UIHelper.SetVisible(self.BtnCalloff, false)
    UIHelper.SetVisible(self.BtnOk, false)
    UIHelper.SetVisible(self.BtnGo, true)
    UIHelper.SetVisible(self.BtnHide, self.nPlayType == PlayType.Arena or self.nPlayType == PlayType.BattleField)
    UIHelper.SetVisible(self.BtnGiveUp, self.nPlayType == PlayType.Arena or self.nPlayType == PlayType.BattleField)
    UIHelper.LayoutDoLayout(self.LayoutBtn)

    Timer.DelAllTimer(self)
    if self.nPlayType == PlayType.Arena or self.nPlayType == PlayType.BattleField or self.nPlayType == PlayType.TongBattleField then
        UIHelper.SetString(self.LabelTitleEnter, self.tbInfo.szTitle or "")

        --实际计时和自动进入逻辑已移到PvpEnterConfirmationData.StartUpdateEnterLeftTime(nPlayType)中处理

        local tbData = PvpEnterConfirmationData.GetData(self.nPlayType)
        UIHelper.SetString(self.LabelEnterTime, string.format("%d秒", tbData.nLeftTime1))
        UIHelper.SetString(self.LabelHintNormal01, string.format("%d秒后自动进入", tbData.nLeftTime2))

        Timer.AddCycle(self, 0.1, function()
            local tbData = PvpEnterConfirmationData.GetData(self.nPlayType)
            if tbData and tbData.nLeftTime1 and tbData.nLeftTime2 then
                UIHelper.SetString(self.LabelEnterTime, string.format("%d秒", tbData.nLeftTime1))
                UIHelper.SetString(self.LabelHintNormal01, string.format("%d秒后自动进入", tbData.nLeftTime2))

                if tbData.nLeftTime2 <= 0 then
                    UIHelper.SetString(self.LabelHintNormal01, "勾选后自动进入")
                end
            end
        end)
    end
end

return UIPvpEnterConfirmationView
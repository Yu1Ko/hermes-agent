-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIWidgetTaskTarceSelectCard
-- Date: 2023-06-01 14:43:45
-- Desc: 目标栏追踪界面 每一项 WidgetTaskTarceSelectCard
-- ---------------------------------------------------------------------------------

local UIWidgetTaskTarceSelectCard = class("UIWidgetTaskTarceSelectCard")

function UIWidgetTaskTarceSelectCard:OnEnter(szInfoType, tData)
    self.szInfoType = szInfoType
    self.tData = tData

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIWidgetTaskTarceSelectCard:OnExit()
    self.bInit = false
    self:UnRegEvent()

    TraceInfoData.UnRegWidget(self)
end

function UIWidgetTaskTarceSelectCard:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnTrace, EventType.OnClick, function(btn)
        local dwActivityID = nil
        if self.szInfoType == TraceInfoType.ActivityTip then
            dwActivityID = self.tData and self.tData.dwActivityID
        end
        Event.Dispatch(EventType.OnSetTraceInfoPriority, self.szInfoType, dwActivityID)
        UIMgr.Close(VIEW_ID.PanelTaskTarceSelect)
    end)
end

function UIWidgetTaskTarceSelectCard:RegEvent()
    Event.Reg(self, EventType.OnSetTraceInfoPriority, function(szKey)
        self:UpdateBtnState()
    end)
end

function UIWidgetTaskTarceSelectCard:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetTaskTarceSelectCard:UpdateInfo()
    local szInfoType = self.szInfoType
    local tData = self.tData

    local szTitle = TraceInfoName[szInfoType]

    --特殊名称
    if szInfoType == TraceInfoType.ActivityTip then
        local dwActivityID = tData and tData.dwActivityID
        local tTip = ActivityTipData.GetActivityTip(dwActivityID)
        if tTip then
            szTitle = tTip.szName
        end
    elseif szInfoType == TraceInfoType.CrossingProgress then
        if CrossingData.nState == CrossingStateType.TestPlace then
            szTitle = CrossingData.CrossingTitleName --试炼之地
        elseif CrossingData.nState == CrossingStateType.SiShiLunWu then
            szTitle = CrossingData.SiShiTitleName --四时论武阵
        end
    elseif szInfoType == TraceInfoType.PublicQuest then
        local tbFBCntData = FestivalActivities.GetFBCountDownData()
        local nType = tbFBCntData and tbFBCntData.nType
        local tLine = (nType == 2 or nType == 3) and Table_GetFBCountDown(nType) -- "场景关闭倒计时"特殊处理
        if tLine then
            szTitle = UIHelper.GBKToUTF8(tLine.szTitle)
        end
    end

    UIHelper.SetString(self.LabelTaskTitleName, szTitle)
    self:UpdateBtnState()

    TraceInfoData.RegWidget(szInfoType, self, self.ScrollViewOther, tData, true)
end

function UIWidgetTaskTarceSelectCard:UpdateBtnState()
    local szInfoType = self.szInfoType
    local tData = self.tData
    local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelMainCity)
    local szCurrent, dwCurActivityID = scriptView:GetCurWidgetItem()

    local bTracing = szCurrent == szInfoType
    if bTracing and szInfoType == TraceInfoType.ActivityTip then
        local dwActivityID = tData and tData.dwActivityID
        bTracing = dwActivityID == dwCurActivityID
    end

    if bTracing then
        UIHelper.SetButtonState(self.BtnTrace, BTN_STATE.Disable)
        UIHelper.SetString(self.LabelTrace, "正在追踪")
    else
        UIHelper.SetButtonState(self.BtnTrace, BTN_STATE.Normal)
        UIHelper.SetString(self.LabelTrace, "追踪")
    end
end

return UIWidgetTaskTarceSelectCard
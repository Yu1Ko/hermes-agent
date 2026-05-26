-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPlotDialogueOldView
-- Date: 2022-11-23 19:40:08
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPlotDialogueOldView = class("UIPlotDialogueOldView")

function UIPlotDialogueOldView:OnEnter(dwTargetType, dwTargetId)
    self.dwTargetType = dwTargetType
    self.dwTargetId = dwTargetId

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo(true)

    if Platform.IsWindows() or Platform.IsMac() then
        Timer.DelTimer(self, self.nTimerID)
        Timer.AddFrameCycle(self, 3, function()
            self:_tryClose()
        end)
    end
end

function UIPlotDialogueOldView:OnExit()
    self.bInit = false
    self:UnRegEvent()

    -- PlotMgr.ClosePanel(PLOT_TYPE.OLD)
end

function UIPlotDialogueOldView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnCloseRight, EventType.OnClick, function()
        PlotMgr.ClosePanel(PLOT_TYPE.OLD)
    end)
end

function UIPlotDialogueOldView:RegEvent()
    Event.Reg(self, EventType.OnPlotChanged, function()
        self:UpdateInfo(false)
    end)


    -- Event.Reg(self, EventType.OnSceneTouchTarget, function()
    --     PlotMgr.ClosePanel(PLOT_TYPE.OLD)
    -- end)

    -- Event.Reg(self, EventType.OnSceneTouchNothing, function()
    --     PlotMgr.ClosePanel(PLOT_TYPE.OLD)
    -- end)

    Event.Reg(self, EventType.CloseDialoguePanel, function()
        -- PlotMgr.ClosePanel(PLOT_TYPE.OLD)
        PlotMgr.DelayClose(PLOT_TYPE.OLD)
    end)

    Event.Reg(self, EventType.OnStartNewQuestDialogue, function(nQuestID, tbQuestRpg, dwOperation)
        PlotMgr.EnterAccpetQuestState(nQuestID)
    end)
end

function UIPlotDialogueOldView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPlotDialogueOldView:UpdateInfo(bFirstUpdate)
    self.tbDialogueData = PlotMgr.GetDialogueData(PLOT_TYPE.OLD)
    if not self.tbDialogueData then return end

    local bMentorRanking = string.find(self.tbDialogueData.szText, "MENTOR_STONE_RANK")

    UIHelper.SetVisible(self.WidgetDetail, false)
    UIHelper.SetVisible(self.WidgetQuest, false)
    UIHelper.SetVisible(self.WidgetAnchorRanking, false)

    if PlotMgr.IsAccpetQuestState() then
        local nQuestID = PlotMgr.GetAccpetQuestID()
        UIHelper.SetVisible(self.WidgetQuest, true)
        local scriptView = UIHelper.GetBindScript(self.WidgetQuest)
        scriptView:OnEnter(nQuestID,self.tbDialogueData)
    elseif bMentorRanking then
        UIHelper.SetVisible(self.WidgetAnchorRanking, true)
        local scriptView = UIHelper.GetBindScript(self.WidgetAnchorRanking)
        scriptView:OnEnter(self.tbDialogueData)
    else
        UIHelper.SetVisible(self.WidgetDetail, true)
        local scriptView = UIHelper.GetBindScript(self.WidgetNormal)
        scriptView:OnEnter(self.tbDialogueData)
        if bFirstUpdate then
            Timer.AddFrame(self, 1, function()--刚打开界面，加载预制时，WidgetOldDialogueContent1的OnEnter会是下一帧调到(OnEnter里的SetRichText会影响WidgetOldDialogueContent1的size计算)，
                --因此延迟一帧Dolayout（打开界面时加载预制，addChild时会因为父节点_running值为true，因此同帧直接调用预制的OnEnter）
                UIHelper.CascadeDoLayoutDoWidget(self.WidgetNormal, true, true)
            end)
        else
            UIHelper.CascadeDoLayoutDoWidget(self.WidgetNormal, true, true)
        end
    end

    self:UpdateInfo_Title()
    self:UpdateInfo_BackButton()

    if bFirstUpdate then
        Timer.AddFrame(self, 1, function()--同CascadeDoLayoutDoWidget
            UIHelper.ScrollViewDoLayout(self.ScrollViewContent)
            UIHelper.ScrollToTop(self.ScrollViewContent)
        end)
    else
        UIHelper.ScrollViewDoLayout(self.ScrollViewContent)
        UIHelper.ScrollToTop(self.ScrollViewContent)
    end
end

function UIPlotDialogueOldView:UpdateInfo_Title()
    if PlotMgr.IsAccpetQuestState() then
        local nQuestID = PlotMgr.GetAccpetQuestID()
        local szName = QuestData.GetQuestName(nQuestID)
        UIHelper.SetString(self.LabelTitle, szName)
        UIHelper.SetVisible(self.ImgTitleIcon, true)
    else
        UIHelper.SetString(self.LabelTitle, self.tbDialogueData.tbData.szTitle)
        UIHelper.SetVisible(self.ImgTitleIcon, false)
    end

    UIHelper.LayoutDoLayout(self.LayoutTitle)
end

function UIPlotDialogueOldView:UpdateInfo_BackButton()
    if PlotMgr.IsAccpetQuestState() then
        UIHelper.SetVisible(self.BtnBack, true)
        UIHelper.SetVisible(self.ImgBtnLine, true)
        UIHelper.BindUIEvent(self.BtnBack, EventType.OnClick, function()
            PlotMgr.ExitAccpetQuestState()
        end)
    else
        local nCount = PlotMgr.GetDialogueDataCount(PLOT_TYPE.OLD)
        UIHelper.SetVisible(self.BtnBack, false)--nCount > 1)
        UIHelper.SetVisible(self.ImgBtnLine, false) -- 左侧没有按钮时分割线隐藏
        UIHelper.BindUIEvent(self.BtnBack, EventType.OnClick, function()
            PlotMgr.Back(PLOT_TYPE.OLD)
        end)
    end
end

function UIPlotDialogueOldView:_tryClose()
    local pPlayer = g_pClientPlayer
    if not pPlayer or pPlayer.nMoveState == MOVE_STATE.ON_DEATH then
        PlotMgr.ClosePanel(PLOT_TYPE.OLD)
        return
    end

    if self.dwTargetType then
        if self.dwTargetType == TARGET.NPC then
            local npc = GetNpc(self.dwTargetId)
            if not npc or not npc.CanDialog(pPlayer) then
                PlotMgr.ClosePanel(PLOT_TYPE.OLD)
            end
        elseif self.dwTargetType == TARGET.DOODAD then
            local doodad = GetDoodad(self.dwTargetId)
            if not doodad or not doodad.CanDialog(pPlayer) then
                PlotMgr.ClosePanel(PLOT_TYPE.OLD)
            end
        end
    end
end


return UIPlotDialogueOldView
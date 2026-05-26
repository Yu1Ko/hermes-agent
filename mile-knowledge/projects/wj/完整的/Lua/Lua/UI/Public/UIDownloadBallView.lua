-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIDownloadBallView
-- Date: 2023-11-29 10:10:17
-- Desc: PanelDownloadBall
-- ---------------------------------------------------------------------------------

local UIDownloadBallView = class("UIDownloadBallView")

local SHOW_STATE = {
    FULL = 1,   --完全显示
    HALF = 2,   --半隐
}

local HIDE_TIME = 3

function UIDownloadBallView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nWidth, self.nHeight = UIHelper.GetContentSize(self.BtnDownload)

    --若正在下载，固定每0.1s更新一次
    Timer.AddCycle(self, 0.1, function()
        if not PakDownloadMgr.IsUIUpdateEnabled() then
            return
        end
        
        if self.nSkipUpdate and self.nSkipUpdate > 0 then
            self.nSkipUpdate = self.nSkipUpdate - 1
        else
            if PakDownloadMgr.IsDownloading() then
                self:UpdateInfo()
            end
        end
        self:UpdateProgress()
    end)

    self:InitPosition()
    self:UpdateInfo()
    self:SetShowState(SHOW_STATE.FULL)
    self:RefreshHideTimer()
    self:UpdateVisible()
end

function UIDownloadBallView:OnExit()
    self.bInit = false
    self:UnRegEvent()

    Storage.Download.Flush()
end

function UIDownloadBallView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnDownload, EventType.OnClick, function()
        if self.nLastShowState == SHOW_STATE.FULL then
            if not PakDownloadMgr.IsDownloading() then
                UIMgr.Close(self)
            end
            local viewScript = UIMgr.GetViewScript(VIEW_ID.PanelResourcesDownload)
            if not viewScript then
                --跳转到资源管理界面-正在下载-主要
                UIMgr.Open(VIEW_ID.PanelResourcesDownload, RESOURCES_PAGE.DOWNLOADING, 1)
            elseif UIMgr.GetLayerTopViewID(UILayer.Page) ~= VIEW_ID.PanelResourcesDownload then
                UIMgr.OpenSingle(true, VIEW_ID.PanelResourcesDownload, RESOURCES_PAGE.DOWNLOADING, 1)
            else
                viewScript:SetPageSelect(RESOURCES_PAGE.DOWNLOADING, 1)
            end
        end
    end)
    UIHelper.BindUIEvent(self.BtnDownload, EventType.OnTouchBegan, function()
        self.bDrag = true
        self:SetShowState(SHOW_STATE.FULL)
        Timer.DelTimer(self, self.nHideTimer)
        self.nHideTimer = nil
    end)
    UIHelper.BindUIEvent(self.BtnDownload, EventType.OnTouchEnded, function()
        self.bDrag = false
        self:UpdatePositionLimit()
        self:SavePosition()
        self:RefreshHideTimer()
    end)
    UIHelper.BindUIEvent(self.BtnDownload, EventType.OnTouchCanceled, function()
        self.bDrag = false
        self:UpdatePositionLimit()
        self:SavePosition()
        self:RefreshHideTimer()
    end)
end

function UIDownloadBallView:RegEvent()
    Event.Reg(self, EventType.PakDownload_OnDownloadEnd, function(bCompleteEnd)
        if bCompleteEnd then
            --下载完成后弹出
            self:UpdateInfo(true)
            if not self.bDrag then
                self:SetShowState(SHOW_STATE.FULL)
                self:RefreshHideTimer()
            end
        else
            UIMgr.Close(self)
        end
    end)
    Event.Reg(self, EventType.PakDownload_OnComplete, function(nPackID, nResult)
        if nResult == DOWNLOAD_OBJECT_RESULT.SUCCESS then
            self.nSkipUpdate = 3
            self.nProgress = 1
            self:UpdateInfo(true) --强制显示完成图标并至少停留0.3s
        end
    end)
    Event.Reg(self, EventType.OnViewOpen, function(nViewID)
        self:UpdateVisible()
    end)
    Event.Reg(self, EventType.OnViewClose, function(nViewID)
        self:UpdateVisible()
    end)
    Event.Reg(self, EventType.OnClientPlayerEnter, function()
        self:UpdateVisible()
    end)
    Event.Reg(self, EventType.OnClientPlayerLeave, function()
        self:UpdateVisible()
    end)
    Event.Reg(self, EventType.OnWindowsSizeChanged, function()
        self:ResetWidget()
    end)
    Event.Reg(self, EventType.OnWindowsSetFocus, function()
        self:ResetWidget()
    end)
end

function UIDownloadBallView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIDownloadBallView:InitPosition()
    local tPos = Storage.Download.tbDownloadBallPos
    if tPos then
        UIHelper.SetWorldPosition(self.BtnDownload, tPos.nX, tPos.nY)
    end

    self:UpdatePositionLimit()
    self:SavePosition()
end

function UIDownloadBallView:SetShowState(nShowState)
    self.nLastShowState = self.nShowState or nShowState
    self.nShowState = nShowState
    if nShowState == SHOW_STATE.FULL then
        self:PlayAnim("AniDown")
    elseif nShowState == SHOW_STATE.HALF then
        self:PlayAnim("AniUp")
    end
end

function UIDownloadBallView:RefreshHideTimer()
    Timer.DelTimer(self, self.nHideTimer)
    self.nHideTimer = Timer.Add(self, HIDE_TIME, function()
        self.nHideTimer = nil
        if PakDownloadMgr.IsDownloading() then
            self:SetShowState(SHOW_STATE.HALF)
        else
            --弹出后若未开始新的下载等操作则关闭
            UIMgr.Close(self)
        end
    end)
end

function UIDownloadBallView:UpdatePositionLimit()
    local nXMin, nXMax, nYMin, nYMax = UIHelper.GetNodeEdgeXY(self.WidgetBtnBall)
    local nX, nY = UIHelper.GetWorldPosition(self.BtnDownload)
    local nAnch = 0.5

    if nX < nXMin + nAnch * self.nWidth then
        nX = nXMin + nAnch * self.nWidth
    end
    if nX > nXMax - nAnch * self.nWidth then
        nX = nXMax - nAnch * self.nWidth
    end
    if nY < nYMin + nAnch * self.nHeight then
        nY = nYMin + nAnch * self.nHeight
    end
    if nY > nYMax - nAnch * self.nHeight then
        nY = nYMax - nAnch * self.nHeight
    end
    UIHelper.SetWorldPosition(self.BtnDownload, nX, nY)
end

function UIDownloadBallView:SavePosition()
    local nX, nY = UIHelper.GetWorldPosition(self.BtnDownload)
    Storage.Download.tbDownloadBallPos = {nX = nX, nY = nY}
    Storage.Download.Dirty()
end

function UIDownloadBallView:UpdateInfo(bCompleted)
    if bCompleted then
        UIHelper.SetVisible(self.WidgetDownloading, false)
        UIHelper.SetVisible(self.WidgetPaused, false)
        UIHelper.SetVisible(self.WidgetFinished, true)
        return
    end

    local tTotalInfo = PakDownloadMgr.GetTotalDownloadInfo()
    local nCurPackID = tTotalInfo.nCurPackID
    local nState = tTotalInfo.nCurState
    local nProgress = tTotalInfo.nCurProgress * 100
    local szProgress = string.format("%0.1f%%", nProgress)

    UIHelper.SetVisible(self.WidgetDownloading, nState == DOWNLOAD_STATE.DOWNLOADING or nState == DOWNLOAD_STATE.QUEUE)
    UIHelper.SetVisible(self.WidgetPaused, nState == DOWNLOAD_STATE.PAUSE)
    UIHelper.SetVisible(self.WidgetFinished, nState == DOWNLOAD_STATE.COMPLETE)

    if nCurPackID ~= self.nCurPackID then
        UIHelper.SetProgressBarPercent(self.ImgProgress, nProgress)
        UIHelper.SetProgressBarPercent(self.ImgProgress2, nProgress)
        UIHelper.SetProgressBarPercent(self.ImgProgress3, nProgress)
    end
    self.nProgress = tTotalInfo.nCurProgress
    self.nCurPackID = nCurPackID
    
    UIHelper.SetString(self.LabelProgress, szProgress)
    UIHelper.SetString(self.LabelProgress2, szProgress)
end

function UIDownloadBallView:UpdateProgress()
    local nRealProgress = (self.nProgress or 0) * 100
    local nCurProgress = UIHelper.GetProgressBarPercent(self.ImgProgress)
    local nTargetProgress = nCurProgress + (nRealProgress - nCurProgress) * 0.3
    if nRealProgress == 100 and nCurProgress < 99 and nTargetProgress >= 99 then
        nTargetProgress = 100
    end

    UIHelper.SetProgressBarPercent(self.ImgProgress, nTargetProgress)
    UIHelper.SetProgressBarPercent(self.ImgProgress2, nTargetProgress)
    UIHelper.SetProgressBarPercent(self.ImgProgress3, nTargetProgress)
end

function UIDownloadBallView:UpdateVisible()
    local tViewIDList = {VIEW_ID.PanelLoading, VIEW_ID.PanelVideoPlayer}
    local bHasView = false
    for _, nViewID in ipairs(tViewIDList) do
        if UIMgr.IsViewOpened(nViewID) and UIMgr.IsViewVisible(nViewID) then
            bHasView = true
            break
        end
    end
    local bVisible = not bHasView and g_pClientPlayer ~= nil
    UIHelper.SetVisible(self._rootNode, bVisible)
end

function UIDownloadBallView:PlayAnim(szAnim, fnCallback, bToEndFrame)
    if szAnim and szAnim ~= self.szAnim then
        UIHelper.StopAni(self, self.AniAll, self.szAnim)
        UIHelper.PlayAni(self, self.AniAll, szAnim, fnCallback, nil, bToEndFrame)
        self.szAnim = szAnim
    end
end

--窗口尺寸变化或最小化后，由于在动画半隐状态下后台刷了Widget导致位置错乱，所以这里刷回来
function UIDownloadBallView:ResetWidget()
    UIHelper.StopAni(self, self.AniAll, self.szAnim)
    UIHelper.PlayAni(self, self.AniAll, "AniDown", function()
        self.szAnim = nil
        self.nShowState = nil
        self.nLastShowState = nil
        UIHelper.WidgetFoceDoAlign(self)
        self:SetShowState(SHOW_STATE.FULL)
        self:RefreshHideTimer()
    end, nil, true)
end


return UIDownloadBallView
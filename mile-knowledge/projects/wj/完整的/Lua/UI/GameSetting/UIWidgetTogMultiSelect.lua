-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIWidgetTogMultiSelect
-- Date: 2023-11-21 14:55:43
-- Desc: WidgetTogMultiSelect
-- ---------------------------------------------------------------------------------

local UIWidgetTogMultiSelect = class("UIWidgetTogMultiSelect")

function UIWidgetTogMultiSelect:OnInitWithPackID(nPackID)
    self:ClearData()
    self.nPackID = nPackID
    self:UpdateInfo()

    UIHelper.SetName(self._rootNode, "PackID_" .. nPackID) --Debug用
end

function UIWidgetTogMultiSelect:OnInitWithPackIDList(tPackIDList, szName)
    self:ClearData()
    self.tPackIDList = tPackIDList
    self.szName = szName

    self:UpdateInfo()

    UIHelper.SetString(self.LabelProgress, "正在计算大小...")
    PakSizeQueryMgr.RegQuerySize(self, tPackIDList, function(bSuccess, dwTotalSize, dwDownloadedSize)
        if bSuccess then
            self.dwTotalSize = dwTotalSize
            self:UpdateInfo()
        end
    end)
end

function UIWidgetTogMultiSelect:ClearData()
    self.nPackID = nil
    self.tPackIDList = nil
    self.szName = nil
    self:SetRecommend(false)

    PakSizeQueryMgr.UnRegAllQuerySize(self)
end

function UIWidgetTogMultiSelect:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        self.scriptResources = UIMgr.GetViewScript(VIEW_ID.PanelResourcesDownload)

        --若正在下载，固定每0.1s更新一次
        Timer.AddCycle(self, 0.1, function()
            if not PakDownloadMgr.IsUIUpdateEnabled() then
                return
            end

            if self:IsDownloading() then
                self:UpdateProgress()
            end
        end)
    end

    UIHelper.SetTouchDownHideTips(self.BtnDownload, false)
    UIHelper.SetTouchDownHideTips(self.ToggleMultiSelect, false)
end

function UIWidgetTogMultiSelect:OnExit()
    self.bInit = false
    self:UnRegEvent()

    PakSizeQueryMgr.UnRegAllQuerySize(self)
end

function UIWidgetTogMultiSelect:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnDownload, EventType.OnClick, function()
        local function _isDownloading(nPackID)
            local tDownloadInfo = PakDownloadMgr.GetDownloadingInfo(nPackID)
            return tDownloadInfo and (tDownloadInfo.nState == DOWNLOAD_STATE.QUEUE or tDownloadInfo.nState == DOWNLOAD_STATE.DOWNLOADING)
        end

        local bDownloading = false
        if self.nPackID then
            bDownloading = _isDownloading(self.nPackID)
        elseif self.tPackIDList then
            for _, nPackID in ipairs(self.tPackIDList or {}) do
                if _isDownloading(nPackID) then
                    bDownloading = true
                    break
                end
            end
        end

        if bDownloading then
            if self.nPackID then
                PakDownloadMgr.PausePack(self.nPackID)
            elseif self.tPackIDList then
                PakDownloadMgr.PausePackInPackIDList(self.tPackIDList)
            end
        else
            local bCanDownload, tNewPackIDList = PakDownloadMgr.CheckCanDownloadClothPack(self, self.nPackID or self.tPackIDList)
            if not bCanDownload then
                return
            end

            local function fnDownload()
                if self.nPackID then
                    PakDownloadMgr.DownloadPack(self.nPackID)
                elseif self.tPackIDList then
                    for _, nPackID in ipairs(self.tPackIDList or {}) do
                        PakDownloadMgr.DownloadPack(nPackID)
                    end
                end
            end

            local tPackIDList = tNewPackIDList or self.tPackIDList --根据排除部分不可下载任务的新列表来查询大小
            PakSizeQueryMgr.RegQuerySizeCheckNetDownload(self, fnDownload, self.nPackID or tPackIDList)
        end
    end)
    UIHelper.BindUIEvent(self.ToggleMultiSelect, EventType.OnSelectChanged, function(_, bSelected)
        if self.nPackID then
            local nDelState = PakDownloadMgr.GetDeleteState(self.nPackID)
            if nDelState == RESOURCE_DELETE_STATE.CAN_DELETE or not bSelected then
                Event.Dispatch(EventType.OnGameSettingDiscardResSelected, self.nPackID, bSelected)
            end
        elseif self.tPackIDList then
            for _, nPackID in ipairs(self.tPackIDList) do
                local nDelState = PakDownloadMgr.GetDeleteState(nPackID)
                if nDelState == RESOURCE_DELETE_STATE.CAN_DELETE or not bSelected then
                    Event.Dispatch(EventType.OnGameSettingDiscardResSelected, nPackID, bSelected)
                end
            end
        end
    end)
end

function UIWidgetTogMultiSelect:RegEvent()
    Event.Reg(self, EventType.PakDownload_OnStateUpdate, function(nPackID)
        if self.nPackID and nPackID ~= self.nPackID then
            return
        end

        if self.tPackIDList and not table.contain_value(self.tPackIDList, nPackID) then
            return
        end

        self:UpdateInfo()
    end)
    Event.Reg(self, EventType.OnGameSettingDiscardRes, function(bDiscard)
        self:SetDiscard(bDiscard)
        self:UpdateInfo()
    end)
    Event.Reg(self, EventType.OnGameSettingDiscardResSelected, function(nPackID, bSelected)
        if self.nPackID and nPackID ~= self.nPackID then
            return
        end

        if self.tPackIDList and not table.contain_value(self.tPackIDList, nPackID) then
            return
        end

        self:UpdateDelTogState()
    end)
end

function UIWidgetTogMultiSelect:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetTogMultiSelect:UpdateInfo()
    if self.nPackID then
        self:UpdatePackInfo()
    elseif self.tPackIDList then
        self:UpdatePackListInfo()
    end

    self:UpdateDelTogState()

    UIHelper.LayoutDoLayout(self.LayoutBtn)
    UIHelper.LayoutDoLayout(self.LayoutTitle)
    self:UpdateProgress()
end

function UIWidgetTogMultiSelect:UpdatePackInfo()
    local tInfo = PakDownloadMgr.GetPackInfo(self.nPackID)
    if not tInfo then
        LOG.ERROR("UIWidgetTogMultiSelect PackID Invalid: %s", tostring(self.nPackID))
        return
    end

    UIHelper.SetString(self.LabelTogName, tInfo.szName)

    local _, dwTotalSize, _ = PakDownloadMgr.GetPackState(self.nPackID)
    local nViewState = PakDownloadMgr.GetPackViewState(self.nPackID)
    local bQueuing = nViewState == DOWNLOAD_STATE.QUEUE
    local bDownloaded = nViewState == DOWNLOAD_STATE.COMPLETE
    local bStarted = nViewState ~= DOWNLOAD_STATE.NONE and nViewState ~= DOWNLOAD_STATE.COMPLETE
    local bPriorityState = PakDownloadMgr.IsPriorityPack(self.nPackID) and not Storage.PriorityDownload.tbPriority[self.nPackID]

    UIHelper.SetVisible(self.LabelProgress, not bDownloaded)
    UIHelper.SetVisible(self.ImgDone, bDownloaded)

    local bCanDownload = not bQueuing and (nViewState == DOWNLOAD_STATE.NONE or nViewState == DOWNLOAD_STATE.PAUSE)
    local bCanPause = nViewState == DOWNLOAD_STATE.DOWNLOADING or (bQueuing and not bPriorityState)
    local szAnim = bCanPause and "AniBtnDownloadContinue" or "AniBtnDownloadSuspend"

    UIHelper.SetVisible(self.BtnDownload, bCanDownload or bCanPause)
    self:PlayAnim(szAnim)

    if not bDownloaded then
        UIHelper.SetString(self.LabelProgress, PakDownloadMgr.FormatSize(dwTotalSize))
    end
end

function UIWidgetTogMultiSelect:UpdatePackListInfo()
    UIHelper.SetString(self.LabelTogName, self.szName)
    local tStateInfo = PakDownloadMgr.GetStateInfoByPackIDList(self.tPackIDList)

    local nState = tStateInfo.nState
    local bQueuing = nState == DOWNLOAD_STATE.QUEUE
    local bDownloaded = nState == DOWNLOAD_STATE.COMPLETE
    local bStarted = nState == DOWNLOAD_STATE.DOWNLOADING or nState == DOWNLOAD_STATE.PAUSE or (nState == DOWNLOAD_STATE.QUEUE and tStateInfo.nProgress > 0)

    UIHelper.SetVisible(self.LabelProgress, not bDownloaded)
    UIHelper.SetVisible(self.ImgDone, bDownloaded)

    local bCanDownload = not bQueuing and (nState == DOWNLOAD_STATE.NONE or nState == DOWNLOAD_STATE.PAUSE)
    local bCanPause = nState == DOWNLOAD_STATE.DOWNLOADING or bQueuing
    local szAnim = bCanPause and "AniBtnDownloadContinue" or "AniBtnDownloadSuspend"

    UIHelper.SetVisible(self.BtnDownload, bCanDownload or bCanPause)
    self:PlayAnim(szAnim)

    if not bDownloaded and self.dwTotalSize then
        UIHelper.SetString(self.LabelProgress, "预计:" .. PakDownloadMgr.FormatSize(self.dwTotalSize))
    end
end

function UIWidgetTogMultiSelect:UpdateProgress()
    local nProgress = 0
    local bStarted = false

    if self.nPackID then
        local nState, dwTotalSize, dwDownloadedSize, nTotalFile, nDownloadedFile = PakDownloadMgr.GetPackState(self.nPackID)
        bStarted = nState == DOWNLOAD_OBJECT_STATE.DOWNLOADING or nState == DOWNLOAD_OBJECT_STATE.PAUSE
        nProgress = PakDownloadMgr.CalcProgress(dwTotalSize, dwDownloadedSize, nTotalFile, nDownloadedFile)
    elseif self.tPackIDList then
        local tStateInfo = PakDownloadMgr.GetStateInfoByPackIDList(self.tPackIDList)
        local nState = tStateInfo.nState
        nProgress = tStateInfo.nProgress
        bStarted = nState == DOWNLOAD_STATE.DOWNLOADING or nState == DOWNLOAD_STATE.PAUSE or (nState == DOWNLOAD_STATE.QUEUE and nProgress > 0)
    end

    UIHelper.SetProgressBarPercent(self.ImgNormalProgress, nProgress * 100)
    UIHelper.SetVisible(self.WidgetProgress, bStarted)
end

function UIWidgetTogMultiSelect:PlayAnim(szAnim)
    if szAnim and szAnim ~= self.szAnim then
        UIHelper.StopAni(self, self.Ani, self.szAnim)
        UIHelper.PlayAni(self, self.Ani, szAnim)
        self.szAnim = szAnim
    end
end

function UIWidgetTogMultiSelect:IsDownloading()
    local bDownloading = false
    if self.nPackID then
        local tDownloadInfo = PakDownloadMgr.GetDownloadingInfo(self.nPackID)
        bDownloading = tDownloadInfo and tDownloadInfo.nState ~= DOWNLOAD_STATE.COMPLETE
    elseif self.tPackIDList then
        for _, nPackID in pairs(self.tPackIDList) do
            local tDownloadInfo = PakDownloadMgr.GetDownloadingInfo(nPackID)
            if tDownloadInfo and tDownloadInfo.nState ~= DOWNLOAD_STATE.COMPLETE then
                bDownloading = true
                break
            end
        end
    end
    return bDownloading
end

function UIWidgetTogMultiSelect:SetDiscard(bDiscard)
    self.bDiscard = bDiscard

    self:UpdateDelTogState()
    UIHelper.SetVisible(self.WidgetDownload, not bDiscard)
    UIHelper.LayoutDoLayout(self.LayoutTitle)
end

function UIWidgetTogMultiSelect:SetRecommend(bRecommend)
    UIHelper.SetVisible(self.ImgRecommend, bRecommend)
end

function UIWidgetTogMultiSelect:UpdateDelTogState()
    UIHelper.SetVisible(self.WidgetDelCheckBox, self.bDiscard)
    if not self.bDiscard then
        return
    end

    local bEnableTog = false
    if self.nPackID then
        local nDelState = PakDownloadMgr.GetDeleteState(self.nPackID)
        bEnableTog = nDelState == RESOURCE_DELETE_STATE.CAN_DELETE
    elseif self.tPackIDList then
        for _, nPackID in ipairs(self.tPackIDList) do
            local nDelState = PakDownloadMgr.GetDeleteState(nPackID)
            if nDelState == RESOURCE_DELETE_STATE.CAN_DELETE then
                bEnableTog = true
                break
            end
        end
    end

    UIHelper.SetEnable(self.ToggleMultiSelect, bEnableTog)
    UIHelper.SetVisible(self.ImgCheckForbidden, not bEnableTog)

    if bEnableTog then
        local nSelState = self.scriptResources and self.scriptResources:GetSelectState(self.tPackIDList or {self.nPackID})
        UIHelper.SetSelected(self.ToggleMultiSelect, nSelState ~= MultiSelectState.None, false)
        UIHelper.SetVisible(self.ImgCheckAll, nSelState == MultiSelectState.All)
        UIHelper.SetVisible(self.ImgCheckPart, nSelState == MultiSelectState.Part)
    else
        UIHelper.SetSelected(self.ToggleMultiSelect, true, false)
        UIHelper.SetVisible(self.ImgCheckAll, false)
        UIHelper.SetVisible(self.ImgCheckPart, false)
    end
end

return UIWidgetTogMultiSelect
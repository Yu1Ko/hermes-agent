-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIWidgetResourcesListCell
-- Date: 2023-04-03 14:25:37
-- Desc: WidgetResourcesListCell
-- ---------------------------------------------------------------------------------

local UIWidgetResourcesListCell = class("UIWidgetResourcesListCell")

local COLOR_NORMAL = cc.c3b(134, 174, 180) --#86aeb4
local COLOR_WARNING = cc.c3b(255, 118, 118) --#ff7676 常用警示色
local COLOR_NORMAL_RECOMMEND = cc.c3b(215, 246, 255) --#d7f6ff
local FONT_SIZE_NORMAL = 20
local FONT_SIZE_WARNING = 18

function UIWidgetResourcesListCell:OnEnter(nID, nType)
    Timer.DelAllTimer(self)
    if not nID or not nType then
        return
    end

    if not self.szOriginNodeName then
        self.szOriginNodeName = UIHelper.GetName(self._rootNode)
    end

    UIHelper.SetSwallowTouches(self.BtnDetail, true)

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        self.scriptDownload = UIHelper.GetBindScript(self.WidgetDownload)
        self.scriptResources = UIMgr.GetViewScript(VIEW_ID.PanelResourcesDownload)
    end

    --若正在下载，固定每0.1s更新一次
    Timer.AddCycle(self, 0.1, function()
        if not PakDownloadMgr.IsUIUpdateEnabled() then
            return
        end

        if self.nPackID then
            local tDownloadInfo = PakDownloadMgr.GetDownloadingInfo(self.nPackID)
            if tDownloadInfo and tDownloadInfo.nState ~= DOWNLOAD_STATE.COMPLETE then
                self:UpdateStateInfo()
            end
        elseif self.tPackIDList then
            for _, nPackID in pairs(self.tPackIDList) do
                local tDownloadInfo = PakDownloadMgr.GetDownloadingInfo(nPackID)
                if tDownloadInfo and tDownloadInfo.nState ~= DOWNLOAD_STATE.COMPLETE then
                    self:UpdateStateInfo()
                    break
                end
            end
        end
    end)

    if nID ~= self.nID or nType ~= self.nType then
        self.nID = nID
        self.nType = nType --ResourcesCellType

        if PakDownloadMgr.GetPackInfo(nID) then
            self.nPackID = nID
            self.nPackTreeID = nil
            self.tPackIDList = nil
            self.nMutexPackTreeID = nil
            self.scriptDownload:OnInitWithPackID(self.nPackID, {bCell = true})
        elseif g_tTable.PackTree and g_tTable.PackTree:Search(nID) then
            self.nPackID = nil
            self.nPackTreeID = nID
            self.tPackIDList = PakDownloadMgr.GetPackIDListInPackTree(nID)
            self.nMutexPackTreeID = self.nType == ResourcesCellType.Recommend and self.nPackTreeID
            self.dwTotalSize = nil
            PakSizeQueryMgr.UnRegAllQuerySize(self)
            local tLine = g_tTable.PackTree:Search(self.nPackTreeID)
            local szGroupName = tLine and UIHelper.GBKToUTF8(tLine.szName)
            self.scriptDownload:OnInitWithPackIDList(self.tPackIDList, {bCell = true, szGroupName = szGroupName, nMutexPackTreeID = self.nMutexPackTreeID})
        else
            LOG.ERROR("UIWidgetResourcesListCell ID Invalid: %s", tostring(nID))
        end

        self:SetRecommend(false)
        self:UpdateName()
        self:UpdateInfo()
    else
        if self.nPackID then
            self.scriptDownload:OnInitWithPackID(self.nPackID, {bCell = true, bInit = false})
        elseif self.tPackIDList then
            local tLine = g_tTable.PackTree:Search(self.nPackTreeID)
            local szGroupName = tLine and UIHelper.GBKToUTF8(tLine.szName)
            self.scriptDownload:OnInitWithPackIDList(self.tPackIDList, {bCell = true, bInit = false, szGroupName = szGroupName, nMutexPackTreeID = self.nMutexPackTreeID})
        end
        self:UpdateStateInfo()
    end
end

function UIWidgetResourcesListCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
    PakSizeQueryMgr.UnRegAllQuerySize(self)

    self.bUpdatingView = false
end

function UIWidgetResourcesListCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function()
        if self.nPackID then
            PakDownloadMgr.CancelPack(self.nPackID)
        elseif self.tPackIDList then
            for _, nPackID in ipairs(self.tPackIDList) do
                PakDownloadMgr.CancelPack(nPackID)
            end
        end
    end)
    UIHelper.BindUIEvent(self.BtnFirst, EventType.OnClick, function()
        if self.nPackID then
            PakDownloadMgr.DownloadPackImmediately(self.nPackID)
        end
    end)
    UIHelper.BindUIEvent(self.BtnHelp, EventType.OnClick, function()
        TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetPublicLabelTips, self.BtnHelp, self.szDesc)
    end)
    UIHelper.BindUIEvent(self.BtnDetail, EventType.OnClick, function()
        local tPackIDListInfo = self.tPackIDList
        if self.nType == ResourcesCellType.Recommend and self.nPackTreeID then
            tPackIDListInfo = PakDownloadMgr.GetChildIDListInPackTree(self.nPackTreeID)
        end
        local tips, scriptView = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetResourceDetailTip, self.BtnDetail, TipsLayoutDir.RIGHT_CENTER, tPackIDListInfo)
        scriptView:SetDiscard(self.bDiscard)
        tips:SetSize(UIHelper.GetContentSize(scriptView:GetContainer()))
        tips:Update()
    end)
    UIHelper.BindUIEvent(self.ToggleMultiSelect, EventType.OnSelectChanged, function(_, bSelected)
        if self.bUpdatingName then
            return
        end

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

            --删除时当前资源包处于下载/等待状态
            if bSelected then
                local tStateInfo = PakDownloadMgr.GetStateInfoByPackIDList(self.tPackIDList)
                if tStateInfo.nState == DOWNLOAD_STATE.DOWNLOADING or tStateInfo.nState == DOWNLOAD_STATE.QUEUE then
                    local tLine = g_tTable.PackTree:Search(self.nPackTreeID)
                    local szGroupName = tLine and UIHelper.GBKToUTF8(tLine.szName) or UIHelper.GetString(self.LabelTitle)
                    UIHelper.ShowConfirm(string.format("[%s]中资源正在下载，是否暂停下载？", szGroupName or "当前分类"), function()
                        PakDownloadMgr.PausePackInPackIDList(self.tPackIDList)
                    end)
                end
            end
        end
    end)
    UIHelper.BindUIEvent(self._rootNode, EventType.OnClick, function(_, bSelected)
        if not self.bDiscard or not self.nPackID then
            return
        end

        local nDelState = PakDownloadMgr.GetDeleteState(self.nPackID)
        if nDelState ~= RESOURCE_DELETE_STATE.CAN_DELETE then
            TipsHelper.ShowNormalTip(g_tStrings.tResourceDeleteState[nDelState])
        end
    end)
    UIHelper.SetTouchEnabled(self._rootNode, true)
    UIHelper.SetSwallowTouches(self._rootNode, false)
end

function UIWidgetResourcesListCell:RegEvent()
    Event.Reg(self, EventType.PakDownload_OnDelete, function(nPackID, bSuccess)
        if not bSuccess then
            return
        end

        if self.nPackID and nPackID ~= self.nPackID then
            return
        end

        if self.tPackIDList and not table.contain_value(self.tPackIDList, nPackID) then
            return
        end

        TipsHelper.ShowNormalTip("扩展包资源删除成功")
    end)
    Event.Reg(self, EventType.PakDownload_OnStateUpdate, function(nPackID)
        if self.nPackID and nPackID ~= self.nPackID then
            return
        end

        if self.tPackIDList and not table.contain_value(self.tPackIDList, nPackID) then
            return
        end

        --延迟更新，避免一帧内多次更新
        if self.bUpdatingView then
            return
        end

        self.bUpdatingView = true
        Timer.AddFrame(self, 1, function()
            self.bUpdatingView = false
            if self.nMutexPackTreeID then
                RecommendPakMutexMgr.CheckShowMutex(self.nMutexPackTreeID)
            end
            self:UpdateStateInfo()
        end)
    end)
    Event.Reg(self, EventType.OnGameSettingDiscardRes, function(bDiscard)
        self:SetDiscard(bDiscard)
    end)
end

function UIWidgetResourcesListCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetResourcesListCell:UpdateName()
    if not Config.bGM then
        return
    end

    local szName = self.szOriginNodeName
    self.bUpdatingName = true

    --便于调试，修改自身节点名字为对应ID
    --但如果改了自身节点名字，删除的Toggle的ActivateList或DeactivateList里控制的节点会在getChildByName时找不到，因此要改回来
    if not self.bDiscard then
        if self.nPackID then
            szName = "Pack_" .. self.nPackID
        elseif self.nPackTreeID then
            szName = "PackTree_" .. self.nPackTreeID
        end
    end

    UIHelper.SetName(self._rootNode, szName)

    --两次反选刷新选中状态
    UIHelper.SetSelected(self.ToggleMultiSelect, not UIHelper.GetSelected(self.ToggleMultiSelect))
    UIHelper.SetSelected(self.ToggleMultiSelect, not UIHelper.GetSelected(self.ToggleMultiSelect))

    self.bUpdatingName = false
end

function UIWidgetResourcesListCell:UpdateInfo()
    UIHelper.SetVisible(self.BtnFirst, false)
    UIHelper.SetVisible(self.BtnCancel, false)

    if self.nPackID then
        local tInfo = PakDownloadMgr.GetPackInfo(self.nPackID)
        local bPriority, nIndex = PakDownloadMgr.IsPriorityPack(self.nPackID)
        local szPriority = bPriority and "（优先-" .. nIndex .."）" or ""
        UIHelper.SetLabel(self.LabelTitle, tInfo.szName .. szPriority)
        UIHelper.SetVisible(self.BtnDetail, false)
        UIHelper.SetVisible(self.WidgetTag, false)

        local _, dwTotalSize, _ = PakDownloadMgr.GetPackState(self.nPackID)
        UIHelper.SetString(self.LabelInfo, PakDownloadMgr.FormatSize(dwTotalSize))
    elseif self.nPackTreeID and self.tPackIDList then
        local tLine = g_tTable.PackTree:Search(self.nPackTreeID)
        UIHelper.SetLabel(self.LabelTitle, UIHelper.GBKToUTF8(tLine.szName))
        UIHelper.SetLabel(self.LabelTag, UIHelper.GBKToUTF8(tLine.szTag))
        UIHelper.SetVisible(self.BtnDetail, #self.tPackIDList > 0)
        UIHelper.SetVisible(self.WidgetTag, not string.is_nil(tLine.szTag))
        self:SetDesc(UIHelper.GBKToUTF8(tLine.szDesc))

        local szImgPath = tLine.szImgPath
        if not string.is_nil(szImgPath) then
            UIHelper.SetTexture(self.ImgPic, szImgPath)
        end

        -- local tStateInfo = PakDownloadMgr.GetStateInfoByPackIDList(self.tPackIDList)
        -- UIHelper.SetString(self.LabelInfo, PakDownloadMgr.FormatSize(tStateInfo.dwTotalSize))

        UIHelper.SetString(self.LabelInfo, "正在计算大小...")
        UIHelper.SetString(self.LabelPercent, "正在计算大小...")

        PakSizeQueryMgr.RegQuerySize(self, self.tPackIDList, function(bSuccess, dwTotalSize, dwDownloadedSize)
            if bSuccess then
                self.dwTotalSize = dwTotalSize
                self:UpdateStateInfo()
            end
        end)
    end

    self:UpdateStateInfo()
    self:SetDiscard(false)
end

function UIWidgetResourcesListCell:UpdateStateInfo()
    if self.nPackID then
        self:UpdatePackStateInfo()
    elseif self.nPackTreeID and self.tPackIDList then
        self:UpdatePackTreeStateInfo()
    end

    self:UpdateDelTogState()

    UIHelper.LayoutDoLayout(self.LayoutBtn)
    UIHelper.LayoutDoLayout(self.LayoutTitle)
    UIHelper.LayoutDoLayout(self.LayoutSpeed)
end

function UIWidgetResourcesListCell:UpdatePackStateInfo()
    local nState, dwTotalSize, dwDownloadedSize = PakDownloadMgr.GetPackState(self.nPackID)
    local tDownloadInfo = PakDownloadMgr.GetDownloadingInfo(self.nPackID)
    local nViewState = PakDownloadMgr.GetPackViewState(self.nPackID)
    local bQueuing = nViewState == DOWNLOAD_STATE.QUEUE
    local bDownloaded = nViewState == DOWNLOAD_STATE.COMPLETE
    local bStarted = nState == DOWNLOAD_OBJECT_STATE.DOWNLOADING or nState == DOWNLOAD_OBJECT_STATE.PAUSE

    if self.nType == ResourcesCellType.Downloading then
        local bBasic = PakDownloadMgr.IsBasicPack(self.nPackID) or PakDownloadMgr.IsMapInBasicPack(self.nPackID)
        local bCore = PakDownloadMgr.IsCorePack(self.nPackID)
        local bPriorityState = PakDownloadMgr.IsPriorityPack(self.nPackID) and not Storage.PriorityDownload.tbPriority[self.nPackID]

        --立即下载 按钮，当基础包下载完成且无优先下载任务时时才可以点击
        local bCanFirst = bQueuing and PakDownloadMgr.IsAllBasicPackComplete() and PakDownloadMgr.IsAllPriorityPackComplete()
        local bCanCancel = not bBasic and not bCore and not bQueuing and not bDownloaded and not bPriorityState
        UIHelper.SetVisible(self.BtnFirst, bCanFirst)
        UIHelper.SetVisible(self.BtnCancel, bCanCancel)
    end

    UIHelper.SetVisible(self.WidgetFinish, bDownloaded)
    UIHelper.SetVisible(self.LabelDes, not bDownloaded)

    local szDownloadSize = ""
    local szDownloadState = ""

    if bStarted then
        szDownloadSize = PakDownloadMgr.FormatSize(dwDownloadedSize) .. "/" .. PakDownloadMgr.FormatSize(dwTotalSize)
    else
        szDownloadSize = PakDownloadMgr.FormatSize(dwTotalSize)
    end

    local color = self.nType ~= ResourcesCellType.Recommend and COLOR_NORMAL or COLOR_NORMAL_RECOMMEND
    local nFontSize = FONT_SIZE_NORMAL
    if tDownloadInfo and tDownloadInfo.bRetryFlag then
        szDownloadState = g_tStrings.tDownloadFailedCellTip[tDownloadInfo.nResult] or "下载失败，等待重试"
        color = COLOR_WARNING
        nFontSize = FONT_SIZE_WARNING
    elseif bQueuing then
        szDownloadState = "等待中"
    elseif nViewState == DOWNLOAD_STATE.PAUSE then
        szDownloadState = "已暂停"
    elseif tDownloadInfo then
        local dwDownloadSpeed = PakDownloadMgr.GetPackDownloadSpeed(self.nPackID)
        szDownloadState = "当前速度：" .. PakDownloadMgr.FormatSize(dwDownloadSpeed, 2) .. "/s"
    end
    UIHelper.SetString(self.LabelPercent, szDownloadSize)
    UIHelper.SetString(self.LabelDes, szDownloadState)
    UIHelper.SetColor(self.LabelDes, color)
    UIHelper.SetFontSize(self.LabelDes, nFontSize)
end

function UIWidgetResourcesListCell:UpdatePackTreeStateInfo()
    local tStateInfo = PakDownloadMgr.GetStateInfoByPackIDList(self.tPackIDList)

    local nState = tStateInfo.nState
    local nProgress = tStateInfo.nProgress
    if self.nType == ResourcesCellType.Recommend and RecommendPakMutexMgr.IsMutex(self.nMutexPackTreeID) and nState ~= DOWNLOAD_STATE.COMPLETE then
        nState = DOWNLOAD_STATE.NONE
        nProgress = 0
    end

    local bQueuing = nState == DOWNLOAD_STATE.QUEUE
    local bDownloaded = nState == DOWNLOAD_STATE.COMPLETE
    local bStarted = nState == DOWNLOAD_STATE.DOWNLOADING or nState == DOWNLOAD_STATE.PAUSE or (bQueuing and nProgress > 0)

    UIHelper.SetVisible(self.WidgetFinish, bDownloaded)
    UIHelper.SetVisible(self.LabelDes, not bDownloaded)

    local szDownloadSize = ""
    local szDownloadState = ""

    -- if bStarted then
    --     szDownloadSize = PakDownloadMgr.FormatSize(tStateInfo.dwDownloadedSize) .. "/" .. PakDownloadMgr.FormatSize(tStateInfo.dwTotalSize)
    -- elseif self.dwTotalSize then
    --     szDownloadSize = PakDownloadMgr.FormatSize(tStateInfo.dwTotalSize)
    -- end

    if self.dwTotalSize then
        UIHelper.SetString(self.LabelPercent, "预计：" .. PakDownloadMgr.FormatSize(self.dwTotalSize, 0))
    end

    if bQueuing then
        szDownloadState = "等待中"
    elseif nState == DOWNLOAD_STATE.PAUSE then
        szDownloadState = "已暂停"
    elseif nState == DOWNLOAD_STATE.DOWNLOADING then
        szDownloadState = "当前速度：" .. PakDownloadMgr.FormatSize(tStateInfo.dwDownloadSpeed, 2) .. "/s"
    end
    --UIHelper.SetString(self.LabelPercent, szDownloadSize)
    UIHelper.SetString(self.LabelDes, szDownloadState)
    UIHelper.SetColor(self.LabelDes, self.nType ~= ResourcesCellType.Recommend and COLOR_NORMAL or COLOR_NORMAL_RECOMMEND)
    UIHelper.SetFontSize(self.LabelDes, FONT_SIZE_NORMAL)
end

function UIWidgetResourcesListCell:SetDiscard(bDiscard)
    self.bDiscard = bDiscard

    self:UpdateName()
    self:UpdateDelTogState()
    self.scriptDownload:SetDiscard(bDiscard)
    UIHelper.SetVisible(self.WidgetDownload, not bDiscard)
    UIHelper.LayoutDoLayout(self.LayoutBtn)
    UIHelper.LayoutDoLayout(self.LayoutTitle)

    local tInfo = self.nPackID and PakDownloadMgr.GetPackInfo(self.nPackID)
    if bDiscard then
        if tInfo then
            self:SetDesc(tInfo.szDeleteDesc)
        end
    else
        UIHelper.SetSelected(self.ToggleMultiSelect, false, false)
        if tInfo then
            self:SetDesc(tInfo.szDownloadDesc)
        end
    end
end

function UIWidgetResourcesListCell:UpdateDelTogState()
    UIHelper.SetVisible(self.WidgetDelCheckBox, self.bDiscard)
    UIHelper.SetVisible(self.ToggleMultiSelect, self.bDiscard)
    UIHelper.SetVisible(self.LabelDelete, false)
    if not self.bDiscard then
        return
    end

    local bAllowDel, bEnableTog = false, false
    if self.nPackID then
        local nDelState = PakDownloadMgr.GetDeleteState(self.nPackID)
        bAllowDel = nDelState ~= RESOURCE_DELETE_STATE.BASIC_PACK and nDelState ~= RESOURCE_DELETE_STATE.CORE_PACK
        bEnableTog = nDelState == RESOURCE_DELETE_STATE.CAN_DELETE
    elseif self.nPackTreeID and self.tPackIDList then
        for _, nPackID in ipairs(self.tPackIDList) do
            local nDelState = PakDownloadMgr.GetDeleteState(nPackID)
            if nDelState == RESOURCE_DELETE_STATE.CAN_DELETE then
                bAllowDel = true
                bEnableTog = true
                break
            elseif nDelState ~= RESOURCE_DELETE_STATE.BASIC_PACK and nDelState ~= RESOURCE_DELETE_STATE.CORE_PACK then
                bAllowDel = true
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

    UIHelper.SetVisible(self.LabelDelete, not bAllowDel)
end

function UIWidgetResourcesListCell:SetDesc(szDesc)
    if szDesc and szDesc ~= "" then
        UIHelper.SetVisible(self.BtnHelp, true)
        self.szDesc = szDesc
    else
        UIHelper.SetVisible(self.BtnHelp, false)
    end
    UIHelper.LayoutDoLayout(self.LayoutTitle)
end

function UIWidgetResourcesListCell:SetRecommend(bRecommend)
    UIHelper.SetVisible(self.ImgRecommend, bRecommend)
end

return UIWidgetResourcesListCell
-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIWidegtAnchorResources
-- Date: 2023-10-07 10:34:16
-- Desc: WidegtAnchorResources
-- ---------------------------------------------------------------------------------

local UIWidegtAnchorResources = class("UIWidegtAnchorResources")

local RECOMMEND_TYPE = 3

function UIWidegtAnchorResources:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nPageIndex = 1

    if not self.tDataList then
        self:InitResourcesInfo()
    end

    self:InitScrollList()
    self:UpdateWarning()
    self:UpdateCanDownloadAll()
end

function UIWidegtAnchorResources:OnExit()
    self.bInit = false
    self:UnRegEvent()

    self.bUpdatingView = false
    self.bUpdatingDiscard = false
    self:SetResDiscardShow(false)
    self:UnInitScrollList()
    PakSizeQueryMgr.UnRegAllQuerySize(self)
end

function UIWidegtAnchorResources:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnBatchDiscard, EventType.OnClick, function()
        self:SetResDiscardShow(true)
    end)
    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function()
        self:SetResDiscardShow(false)
    end)
    UIHelper.BindUIEvent(self.BtnDelete, EventType.OnClick, function()
        local bMultiInstance = PakDownload_HasMultiInstance()
        if bMultiInstance then
            TipsHelper.ShowNormalTip("当前启动了多个客户端，无法进行删除操作")
            return
        end

        if table.is_empty(self.tSelected) then
            TipsHelper.ShowNormalTip("请先选中要删除的资源包")
            return
        end

        local tPackIDList = {}
        local tPackIDMap = {} --用于去重，避免table.contain_value耗性能太大
        for nPackID, bSelected in pairs(self.tSelected) do
            if bSelected and not tPackIDMap[nPackID] then
                table.insert(tPackIDList, nPackID)
                tPackIDMap[nPackID] = true
            end
        end
        PakSizeQueryMgr.RegQuerySize(self, tPackIDList, function(bSuccess, dwDeleteSize)
            UIHelper.ShowConfirm("是否确认删除选中的资源包？预计大小" .. PakDownloadMgr.FormatSize(dwDeleteSize) .. "\n如确认删除，将在下次启动游戏时执行删除资源操作！<color=#ffe26e><font size='20'>\n\n（由于存在重复资源，实际删除的大小会偏小）</font></color>", function()
                PakDownloadMgr.DeletePackInPackIDList(tPackIDList)
                self:SetResDiscardShow(false)
            end, nil, true)
        end, true, QUERY_TYPE.DELETE_SIZE)
    end)
    UIHelper.BindUIEvent(self.BtnAll, EventType.OnClick, function()
        if self.bCanPause then
            PakDownloadMgr.PauseAllPack()
        elseif self.bCanStart then
            local tPackIDList = {}
            for _, tTask in pairs(Storage.Download.tbTaskTable[DOWNLOAD_STATE.PAUSE]) do
                table.insert(tPackIDList, tTask.nPackID)
            end
            PakSizeQueryMgr.RegQuerySizeCheckNetDownload(self, PakDownloadMgr.ResumeAllPack, tPackIDList)
        end
    end)
    UIHelper.BindUIEvent(self.BtnCancelAll, EventType.OnClick, function()
        UIHelper.ShowConfirm("是否移除当前所有下载任务，清空下载列表？", function()
            PakDownloadMgr.CancelAllPack()
        end)
    end)
    UIHelper.BindUIEvent(self.BtnDeleteResources, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelCleanUpResources)
    end)
end

function UIWidegtAnchorResources:RegEvent()
    Event.Reg(self, EventType.OnGameSettingDiscardResSelected, function(nPackID, bSelected)
        self.tSelected[nPackID] = bSelected

        --延迟更新，避免一帧内多次更新
        if self.bUpdatingDiscard then
            return
        end

        self.bUpdatingDiscard = true
        Timer.AddFrame(self, 1, function()
            self.bUpdatingDiscard = false
            self:UpdateDiscardCount()
            self:UpdateViewList()
        end)
    end)
    Event.Reg(self, EventType.PakDownload_OnStateUpdate, function(nPackID)
        --延迟更新，避免一帧内多次更新
        if self.bUpdatingView then
            return
        end

        self.bUpdatingView = true
        Timer.AddFrame(self, 1, function()
            self.bUpdatingView = false
            self:UpdateWarning()
            self:UpdateCanDownloadAll()
            self:UpdateViewList()
        end)
    end)
    Event.Reg(self, EventType.PakDownload_OnResClean, function()
        self:UpdateWarning()
        self:UpdateCanDownloadAll()
        self:UpdateViewList()
    end)
    Event.Reg(self, EventType.OnWindowsSizeChanged, function()
        if self.nPageIndex == RESOURCES_PAGE.RECOMMEND and not self.bDownloading and self.scriptRecommendCell then
            self:OnUpdateCell(self.scriptRecommendCell, 1)
        end
    end)
end

function UIWidegtAnchorResources:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidegtAnchorResources:InitScrollList()
    self:UnInitScrollList()

    self.tScrollList = UIScrollList.Create({
        listNode = self.LayoutResources,
        nSpace = 10,
        fnGetCellType = function(nIndex)
            local tData = self.tViewList[nIndex]
            return tData and tData.nPrefabID
        end,
        fnUpdateCell = function(cell, nIndex)
            self:OnUpdateCell(cell, nIndex)
        end,
    })
    self.tScrollList:SetScrollBarEnabled(true)

    local nWidth, _ = UIHelper.GetContentSize(self.LayoutResources)
    UIHelper.SetContentSize(self.tScrollList.m.contentNode, nWidth, 0) --设置宽度，用于宽屏Layout适配
end

function UIWidegtAnchorResources:UnInitScrollList()
    if self.tScrollList then
        self.tScrollList:Destroy()
        self.tScrollList = nil
    end
end

function UIWidegtAnchorResources:OnUpdateCell(cell, nIndex)
    cell._keepmt = true
    local tView = self.tViewList[nIndex]
    if tView.nPrefabID == PREFAB_ID.WidgetSettingsWordageTitle then
        cell:SetTitle(tView.szName)
    elseif tView.nPrefabID == PREFAB_ID.WidgetSettingsTittle_PackUp then
        cell:OnEnter(tView.szName, tView.szDesc, tView.tIDList, tView.dwTotalSize)
        cell:SetSelectChangeCallback(function(bSelected)
            tView.bFold = bSelected
            self:UpdateViewList()
        end)
        cell:SetSelected(tView.bFold, false)
        cell:SetDiscard(self.bDiscard)
        cell:SetRecommend(tView.bRecommend)
    elseif tView.nPrefabID == PREFAB_ID.WidgetResourcesListCell then
        cell:UpdateInfo(self.nPageType, self.bDiscard, tView.nID, tView.nID2)
        cell:SetRecommend(tView.bRecommend, tView.bRecommend2)
    elseif tView.nPrefabID == PREFAB_ID.WidgetPlayerRecommendResources then
        self:UpdateRecommendCellList(cell, #tView.tIDArgs)
        cell:UpdateInfo(ResourcesCellType.Recommend, self.bDiscard, table.unpack(tView.tIDArgs))
        cell:SetRecommend(table.unpack(tView.tRecommendArgs))
    end
end

function UIWidegtAnchorResources:UpdateRecommendCellList(cellScript, nCellCount)
    cellScript.tWidgetResourcesList = cellScript.tWidgetResourcesList or {}
    local nHeight = UIHelper.GetHeight(self.ScrollViewPlayerRecommend)

    local bAdded = false
    for nIndex = 1, nCellCount do
        if not cellScript.tWidgetResourcesList[nIndex] then
            local scriptView = UIHelper.AddPrefab(PREFAB_ID.WidgetPlayerRecommenResourcesCell, cellScript.LayoutCell)
            cellScript.tWidgetResourcesList[nIndex] = scriptView._rootNode
            bAdded = true
        end
        local nCellHeight = UIHelper.GetHeight(cellScript.tWidgetResourcesList[nIndex])
        UIHelper.SetPositionY(cellScript.tWidgetResourcesList[nIndex], (nHeight - nCellHeight * 0.5) - 50)
    end

    cellScript:InitCellList()

    if bAdded then
        UIHelper.LayoutDoLayout(cellScript.LayoutCell)
    end
end

function UIWidegtAnchorResources:InitResourcesInfo()
    self.tDataList = {}
    self.tSelected = {}

    local tPackTree = PakDownloadMgr.GetPackTree()
    if not tPackTree then
        return
    end

    local nTitleIndex = nil

    -- nRootType: 0-非一级分类；1-普通一级分类；2-玩法资源；3-推荐下载
    local function _setData(tInfo, nIndex, nRootType, bClearRecommend)
        if not tInfo then
            return
        end

        local nPackID = tInfo.nPackID
        if nPackID and nPackID > 0 then
            --不存在或在白名单之外，排除
            if not PakDownloadMgr.GetPackInfo(nPackID) or not PakDownloadMgr.IsPackInWhiteList(nPackID) then
                return
            end
        else
            nPackID = nil
        end

        local bRecommend = tInfo.bRecommend and not bClearRecommend or false

        if not self.tDataList[nIndex] then
            nTitleIndex = nil
            self.tDataList[nIndex] = {}
        end

        if tInfo.nLevel == 2 then
            if nPackID then
                table.insert(self.tDataList[nIndex], {
                    nPrefabID = PREFAB_ID.WidgetResourcesListCell,
                    nID = nPackID,
                    bRecommend = bRecommend,
                })
            elseif nRootType == RECOMMEND_TYPE then
                table.insert(self.tDataList[nIndex], {
                    nPrefabID = PREFAB_ID.WidgetPlayerRecommendResources,
                    nID = tInfo.nID,
                    bRecommend = bRecommend,
                })
            else
                table.insert(self.tDataList[nIndex], {
                    nPrefabID = PREFAB_ID.WidgetSettingsTittle_PackUp,
                    szName = tInfo.szName,
                    szDesc = tInfo.szDesc,
                    bRecommend = bRecommend,
                    bFold = true,
                    tIDList = {},
                    dwTotalSize = nil,
                })
                nTitleIndex = #self.tDataList[nIndex]
            end
        elseif tInfo.nLevel == 3 and nRootType ~= RECOMMEND_TYPE then
            local nID
            if nPackID then
                nID = nPackID
            else
                --验证PackTreeID下是否存在有效nPackID
                local tPackIDList = PakDownloadMgr.GetPackIDListInPackTree(tInfo.nID)
                local bValid = false
                for _, nPackID in ipairs(tPackIDList) do
                    if nPackID > 0 and PakDownloadMgr.GetPackInfo(nPackID) and PakDownloadMgr.IsPackInWhiteList(nPackID) then
                        bValid = true
                        break
                    end
                end
                if bValid then
                    nID = tInfo.nID
                end
            end
            if nID then
                table.insert(self.tDataList[nIndex], {
                    nPrefabID = PREFAB_ID.WidgetResourcesListCell,
                    nID = nID,
                    bRecommend = bRecommend,
                    nTitleIndex = nTitleIndex,
                })

                --将自身ID插入到折叠标题栏的ID列表中
                local tTitleData = nTitleIndex and self.tDataList[nIndex][nTitleIndex]
                if tTitleData then
                    table.insert(tTitleData.tIDList, nID)
                end
            end
        end

        if tInfo.tChildList then
            --策划需求：若同层级下的所以Child都为推荐，则都不显示推荐图标
            local bAllRecommend = true
            for _, tChild in ipairs(tInfo.tChildList) do
                if not tChild.bRecommend then
                    bAllRecommend = false
                end
            end
            for _, tChild in ipairs(tInfo.tChildList) do
                _setData(tChild, nIndex, nRootType, bAllRecommend)
            end
        end
    end

    --将树状结构按顺序插入到tDataList
    for nIndex, tInfo in ipairs(tPackTree) do
        _setData(tInfo, nIndex, tInfo.nType)
    end

    for _, tDataList in ipairs(self.tDataList) do
        for i = #tDataList, 1, -1 do
            local tData = tDataList[i]
            if tData.tIDList then
                --移除无子项的折叠标题
                if #tData.tIDList <= 0 then
                    table.remove(tDataList, i)

                    --子项的nTitleIndex同步上移
                    for j = i, #tDataList do
                        if tDataList[j].nTitleIndex then
                            tDataList[j].nTitleIndex = tDataList[j].nTitleIndex - 1
                        end
                    end
                else
                    --提前计算dwTotalSize，避免切换时闪烁
                    local tPackIDList = {}
                    for _, nID in ipairs(tData.tIDList) do
                        if PakDownloadMgr.GetPackInfo(nID) then
                            table.insert(tPackIDList, nID)
                        else
                            for _, nPackID in ipairs(PakDownloadMgr.GetPackIDListInPackTree(nID)) do
                                table.insert(tPackIDList, nPackID)
                            end
                        end
                    end

                    PakSizeQueryMgr.RegQuerySize(self, tPackIDList, function(Success, dwTotalSize, dwDownloadedSize)
                        if Success and tData then
                            tData.dwTotalSize = dwTotalSize
                        end
                    end)
                end
            end
        end
    end

    --print_table_utf8(self.tDataList)
end

function UIWidegtAnchorResources:UpdateInfo(nPageIndex, bDownloading)
    if not self.bInit then
        return
    end

    self.nPageIndex = nPageIndex or 1
    self.bDownloading = bDownloading or false

    self:UpdateCanDownloadAll()
    self:UpdateViewList(true)

    if self.nPageType == ResourcesCellType.Downloading then
        self:SetResDiscardShow(false)
    else
        self:SetResDiscardShow(self.bDiscard or false)
    end
end

function UIWidegtAnchorResources:GetViewList(nPageIndex, bDownloading)
    if not self.tDataList then
        self:InitResourcesInfo()
        self:UpdateCanDownloadAll()
    end

    self.bCanPause = false
    self.bCanStart = false
    self.bCanCancel = false
    local tViewList = {}

    local function _insertData(tData)
        --因为ScrollList不支持一行显示多个，所以通过将一排多个Prefab组成一个Prefab的方式来实现需求
        --若上一个为WidgetResourcesListCell且没塞满则多塞一个，若为WidgetPlayerRecommendResources则用参数列表多塞N个

        local tLast = tViewList[#tViewList]
        if tData.nPrefabID == PREFAB_ID.WidgetPlayerRecommendResources then
            if tLast then
                table.insert(tLast.tIDArgs, tData.nID)
                table.insert(tLast.tRecommendArgs, tData.bRecommend)
                return
            else
                --创建新表防止污染原数据
                tData = {
                    nPrefabID = tData.nPrefabID,
                    tIDArgs = { tData.nID },
                    tRecommendArgs = { tData.bRecommend },
                }
            end
        elseif tData.nPrefabID == PREFAB_ID.WidgetResourcesListCell then
            if tData.nID and tLast and tLast.nID and not tLast.nID2 then
                if tLast.nID and not tLast.nID2 then
                    tViewList[#tViewList] = clone(tLast) --clone防止污染原数据
                    tViewList[#tViewList].nID2 = tData.nID
                    tViewList[#tViewList].bRecommend2 = tData.bRecommend
                    return
                end
            end
        end

        table.insert(tViewList, tData)
    end

    local tDataList = self.tDataList[nPageIndex]
    if tDataList and not bDownloading then
        for _, tData in ipairs(tDataList) do
            --若存在标题栏且标题栏未折叠，则显示
            if not tData.nTitleIndex or not tDataList[tData.nTitleIndex].bFold then
                _insertData(tData)
            end
        end
    else
        --正在下载
        local tBasicPackIDList = PakDownloadMgr.GetBasicPackIDList()
        local tPriorityList = {}
        local tCorePackIDList = {}
        if nPageIndex == 1 then
            --基础包
            local nState, dwTotalSize, dwDownloadedSize = PakDownloadMgr.GetBasicPackState()
            if nState ~= DOWNLOAD_OBJECT_STATE.DOWNLOADED then
                table.insert(tViewList, {
                    nPrefabID = PREFAB_ID.WidgetSettingsWordageTitle,
                    szName = "基础资源-" .. PakDownloadMgr.FormatSize(dwTotalSize) .. "（下载完成后可进入游戏）",
                })

                for _, nPackID in ipairs(tBasicPackIDList or {}) do
                    local tData = {
                        nPrefabID = PREFAB_ID.WidgetResourcesListCell,
                        nID = nPackID,
                    }
                    _insertData(tData)
                end
            end

            --核心包
            for _, nPackID in ipairs(PakDownloadMgr.GetCorePackIDList() or {}) do
                local tTask, _ = PakDownloadMgr.GetTask(nPackID)
                if tTask then
                    table.insert(tCorePackIDList, nPackID)
                end
            end
            if #tCorePackIDList > 0 then
                local tCoreStateInfo = PakDownloadMgr.GetStateInfoByPackIDList(tCorePackIDList)
                local szCoreTitle
                if AppReviewMgr.IsReview() then
                    szCoreTitle = "核心资源"
                else
                    szCoreTitle = "核心资源-" .. PakDownloadMgr.FormatSize(tCoreStateInfo.dwTotalSize) .. "（畅玩游戏必备资源）"
                end

                table.insert(tViewList, {
                    nPrefabID = PREFAB_ID.WidgetSettingsWordageTitle,
                    szName = szCoreTitle,
                })
                for _, nPackID in ipairs(tCorePackIDList) do
                    local tData = {
                        nPrefabID = PREFAB_ID.WidgetResourcesListCell,
                        nID = nPackID,
                    }
                    _insertData(tData)
                end
            end

            --优先包
            for _, nPackID in ipairs(PakDownloadMgr.GetPriorityList() or {}) do
                local tTask, _ = PakDownloadMgr.GetTask(nPackID)
                if tTask and tTask.nTriggerType == TASK_TRIGGER_TYPE.PRIORITY then
                    table.insert(tPriorityList, nPackID)
                end
            end

            if #tPriorityList > 0 then
                table.insert(tViewList, {
                    nPrefabID = PREFAB_ID.WidgetSettingsWordageTitle,
                    szName = "优先下载",
                })
                for _, nPackID in ipairs(tPriorityList) do
                    local tData = {
                        nPrefabID = PREFAB_ID.WidgetResourcesListCell,
                        nID = nPackID,
                    }
                    _insertData(tData)
                end
            end
        end

        local function _insertTask(nState, szName)
            local tList = Storage.Download.tbTaskTable[nState]
            if not tList or #tList <= 0 then
                return
            end

            local bInsertTitle = false
            for _, tTask in ipairs(tList) do
                local nPackID = tTask.nPackID
                local bCanInsert = (nPageIndex == 1 and not tTask.bDynamic) or (nPageIndex == 2 and tTask.bDynamic) --区分主要/商城分页
                if bCanInsert and not table.contain_value(tPriorityList, nPackID) and not table.contain_value(tBasicPackIDList, nPackID) and not table.contain_value(tCorePackIDList, nPackID) then
                    if not bInsertTitle then
                        --标题栏
                        table.insert(tViewList, {
                            nPrefabID = PREFAB_ID.WidgetSettingsWordageTitle,
                            szName = szName,
                        })
                        bInsertTitle = true
                    end

                    local tData = {
                        nPrefabID = PREFAB_ID.WidgetResourcesListCell,
                        nID = nPackID,
                    }
                    _insertData(tData)
                end

                --刷新是否可全部暂停/继续/删除状态
                if bCanInsert then
                    if nState == DOWNLOAD_STATE.DOWNLOADING or nState == DOWNLOAD_STATE.QUEUE then
                        self.bCanPause = true
                    elseif nState == DOWNLOAD_STATE.PAUSE then
                        self.bCanStart = true
                    end

                    local bBasic = PakDownloadMgr.IsBasicPack(nPackID) or PakDownloadMgr.IsMapInBasicPack(nPackID)
                    local bCore = PakDownloadMgr.IsCorePack(nPackID)
                    local bPriorityState = PakDownloadMgr.IsPriorityPack(nPackID) and not Storage.PriorityDownload.tbPriority[nPackID]
                    if not bBasic and not bCore and not bPriorityState then
                        self.bCanCancel = true
                    end
                end
            end
        end

        --普通包
        _insertTask(DOWNLOAD_STATE.DOWNLOADING, "下载中")
        _insertTask(DOWNLOAD_STATE.QUEUE, "等待中")
        _insertTask(DOWNLOAD_STATE.PAUSE, "已暂停")
        _insertTask(DOWNLOAD_STATE.COMPLETE, "已完成")
    end

    return tViewList
end

function UIWidegtAnchorResources:UpdateViewList(bReset)
    self.tViewList = self:GetViewList(self.nPageIndex, self.bDownloading)

    local tDataList = self.tDataList[self.nPageIndex]
    if tDataList and not self.bDownloading then
        self.nPageType = ResourcesCellType.Resource
        UIHelper.SetString(self.LabelDescibe01, "暂无下载内容")
    else
        self.nPageType = ResourcesCellType.Downloading
        UIHelper.SetString(self.LabelDescibe01, "暂无下载任务")
    end

    local nCellTotal = #self.tViewList
    UIHelper.SetVisible(self.WidgetDownloadEmpty, nCellTotal <= 0)

    if self.nPageIndex == RESOURCES_PAGE.RECOMMEND and not self.bDownloading then
        --推荐分页 使用横向ScrollView
        UIHelper.SetVisible(self.LayoutResources, false)
        UIHelper.SetVisible(self.ScrollViewPlayerRecommend, true)

        self.scriptRecommendCell = self.scriptRecommendCell or UIHelper.GetBindScript(self.ScrollViewPlayerRecommend)
        self:OnUpdateCell(self.scriptRecommendCell, 1)

        UIHelper.ScrollViewDoLayout(self.ScrollViewPlayerRecommend)
        if bReset then
            UIHelper.ScrollToLeft(self.ScrollViewPlayerRecommend, 0)
        end
    else
        UIHelper.SetVisible(self.LayoutResources, true)
        UIHelper.SetVisible(self.ScrollViewPlayerRecommend, false)

        if bReset then
            self.tScrollList:Reset(nCellTotal)
        else
            self.tScrollList:Reload(nCellTotal)
        end
    end

    self:UpdateButtonVisible()
end

function UIWidegtAnchorResources:SetResDiscardShow(bDiscard)
    self.bDiscard = bDiscard
    if not bDiscard then
        self.tSelected = {}
    end
    UIHelper.SetVisible(self.WidgetAniDiscard, bDiscard)
    self:UpdateDiscardCount()
    self:UpdateButtonVisible()

    Event.Dispatch(EventType.OnGameSettingDiscardRes, bDiscard)
end

function UIWidegtAnchorResources:UpdateDiscardCount()
    local nCount = 0
    local dwSize = 0
    for nPackID, bSelected in pairs(self.tSelected or {}) do
        if bSelected then
            nCount = nCount + 1
            local _, _, dwDownloadedSize = PakDownloadMgr.GetPackState(nPackID)
            dwSize = dwSize + dwDownloadedSize
        end
    end
    local szContent = tostring(nCount)
    -- if dwSize > 0 then
    --     szContent = nCount .. "（" .. PakDownloadMgr.FormatSize(dwSize) .. "）"
    -- else
    --     szContent = tostring(nCount)
    -- end
    UIHelper.SetString(self.LabelNum, szContent)
    UIHelper.LayoutDoLayout(self.LayoutContent)

    local nBtnState = nCount > 0 and BTN_STATE.Normal or BTN_STATE.Disable
    UIHelper.SetButtonState(self.BtnDelete, nBtnState)
end

function UIWidegtAnchorResources:GetSelectState(tPackIDList)
    if not tPackIDList then
        return
    end

    local bHasSelected = false
    local bAllSelected = true

    for _, nPackID in ipairs(tPackIDList) do
        if self.tSelected[nPackID] then
            bHasSelected = true
        else
            bAllSelected = false
        end
    end

    local nSelState
    if bAllSelected then
        nSelState = MultiSelectState.All
    elseif not bHasSelected then
        nSelState = MultiSelectState.None
    else
        nSelState = MultiSelectState.Part
    end

    return nSelState
end

function UIWidegtAnchorResources:UpdateWarning()
    for _, tDownloadInfo in pairs(PakDownloadMgr.GetDownloadingList() or {}) do
        if tDownloadInfo.nResult == DOWNLOAD_OBJECT_RESULT.NO_SPACE_FAIL then
            UIHelper.SetVisible(self.LabelWarning, true)
            UIHelper.SetString(self.LabelWarning, "存储空间不足无法下载，请尝试清理后继续")
            UIHelper.LayoutDoLayout(self.LayoutWarning)
            return
        end
    end
    UIHelper.SetVisible(self.LabelWarning, false)
    UIHelper.LayoutDoLayout(self.LayoutWarning)
end

function UIWidegtAnchorResources:UpdateCanDownloadAll()
    local bCanDownloadAll = false
    if (Platform.IsWindows() or Platform.IsMac() or Config.bShowDownloadAll) and not self.bDownloading then
        bCanDownloadAll = not PakDownloadMgr.IsAllExtensionPackStart()
    end
    Event.Dispatch(EventType.PakDownload_OnCanDownloadAllUpdate, bCanDownloadAll)
end

function UIWidegtAnchorResources:UpdateButtonVisible()
    local tDataList = self.tDataList[self.nPageIndex]
    if tDataList and not self.bDownloading then
        UIHelper.SetVisible(self.BtnAll, false)
        UIHelper.SetVisible(self.BtnCancelAll, false)
    else
        if self.bCanPause then
            UIHelper.SetVisible(self.BtnAll, true)
            UIHelper.SetVisible(self.WidgetPauseAll, true)
            UIHelper.SetVisible(self.WidgetStartAll, false)
        elseif self.bCanStart then
            UIHelper.SetVisible(self.BtnAll, true)
            UIHelper.SetVisible(self.WidgetPauseAll, false)
            UIHelper.SetVisible(self.WidgetStartAll, true)
        else
            UIHelper.SetVisible(self.BtnAll, false)
        end
        UIHelper.SetVisible(self.BtnCancelAll, self.bCanCancel)
    end

    local bBasicComplete = PakDownloadMgr.IsAllBasicPackComplete()
    UIHelper.SetVisible(self.BtnBatchDiscard, bBasicComplete and not self.bDiscard and self.nPageType == ResourcesCellType.Resource)
    UIHelper.SetVisible(self.BtnDeleteResources, bBasicComplete)

    UIHelper.LayoutDoLayout(self.LayoutBtn)
end

return UIWidegtAnchorResources
-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIResourcesDownloadView
-- Date: 2023-11-28 15:06:01
-- Desc: PanelResourcesDownload
-- ---------------------------------------------------------------------------------

local UIResourcesDownloadView = class("UIResourcesDownloadView")

function UIResourcesDownloadView:OnEnter(nSelectIndex, nSubSelectIndex)
    self.scriptScrollViewTree = UIHelper.GetBindScript(self.WidgetAnchorLeft)
    self.scriptResources = UIHelper.GetBindScript(self.WidegtAnchorResources)

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:InitUI()

    Timer.AddFrame(self, 2, function()
        self:SetPageSelect(nSelectIndex, nSubSelectIndex)
    end)

    if not AppReviewMgr.IsReview() then
        if not Storage.Download.bResourcesDeleteHint_AYQJ and PakDownloadMgr.CheckCanDeleteOldVersionRes() then
            Timer.Add(self, 1, function()
                local dialog = UIHelper.ShowConfirm("全新资料片“暗影千机”相关资源已开放下载，进入游戏后将自动添加到下载队列优先下载，侠士亦可在 [ 推荐下载 ] 中提前选择下载。<color=#ffe26e><font size='20'>\n\n温馨提示：因部分周常等任务目标调整，您无需再频繁前往上赛季的部分地图场景。为避免造成不必要的资源冗余，可前往资源管理中将对应地图场景进行清理，以释放更多空间。</font></color>", nil, nil, true)
                dialog:HideCancelButton()
            end)
        end
        Storage.Download.bResourcesDeleteHint_AYQJ = true
        Storage.Download.Flush()
    end
end

function UIResourcesDownloadView:OnExit()
    self.bInit = false
    self:UnRegEvent()

    --点入正在下载页面后，关闭资源管理界面才清理正在下载列表
    if self.bSelectDownloading then
        PakDownloadMgr.CheckClearTaskList()
    end
    PakSizeQueryMgr.UnRegAllQuerySize(self)
end

function UIResourcesDownloadView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
    UIHelper.BindUIEvent(self.BtnDownloadAll, EventType.OnClick, function()
        local tPackIDList = PakDownloadMgr.GetExtensionPackIDList()
        local szContent = "是否下载全部资源？\n全部资源下载后，预计总包大小：120GB"
        UIHelper.ShowConfirm(szContent, function()
            PakSizeQueryMgr.RegQuerySizeCheckNetDownload(self, function()
                for _, nPackID in ipairs(tPackIDList) do
                    PakDownloadMgr.DownloadPack(nPackID)
                end
                self:SetPageSelect(RESOURCES_PAGE.DOWNLOADING)
            end, tPackIDList)
        end, nil, true)
    end)
    UIHelper.BindUIEvent(self.TogNetworkDownLoad, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected then
            UIHelper.ShowConfirm("是否允许移动网络使用流量下载资源？勾选后不再弹窗提示", function()
                PakDownloadMgr.SetAllowNotWifiDownload(bSelected)
            end, function()
                UIHelper.SetSelected(self.TogNetworkDownLoad, false, false)
            end)
        else
            PakDownloadMgr.SetAllowNotWifiDownload(bSelected)
        end
    end)
    UIHelper.BindUIEvent(self.TogSwithDownloadBall, EventType.OnSelectChanged, function(_, bSelected)
        local bOpened = UIMgr.IsViewOpened(VIEW_ID.PanelDownloadBall)
        if bSelected and not bOpened and PakDownloadMgr.IsDownloading() then
            UIMgr.Open(VIEW_ID.PanelDownloadBall)
        elseif not bSelected and bOpened then
            UIMgr.Close(VIEW_ID.PanelDownloadBall)
        end

        Storage.Download.bShowDownloadBall = bSelected
        Storage.Download.Dirty()
    end)
end

function UIResourcesDownloadView:RegEvent()
    Event.Reg(self, EventType.PakDownload_OnCanDownloadAllUpdate, function(bCanDownloadAll)
        UIHelper.SetVisible(self.BtnDownloadAll, bCanDownloadAll)
    end)
    Event.Reg(self, EventType.OnWindowsSizeChanged, function()
        Timer.AddFrame(self, 5, function()
            UIHelper.LayoutDoLayout(self.LayoutWarning)
        end)
    end)
end

function UIResourcesDownloadView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIResourcesDownloadView:InitUI()
    self.tSubTogList = {}

    --NOTE 通过UIDef.lua中控制RESOURCES_PAGE.RECOMMEND = nil使推荐下载暂时隐藏

    local tData = {}
    local tPackTree = PakDownloadMgr.GetPackTree()

    local function _insertCatogory(nPageType, nPackTreeType, bRecommend)
        if not nPageType then return end
        for _, tInfo in pairs(tPackTree or {}) do
            if tInfo.nType == nPackTreeType then
                tData[nPageType] = {
                    tArgs = {szTitle = tInfo.szName, bHasChild = false, bRecommend = bRecommend}, --无tItemList表示无次级导航
                }
                return
            end
        end
    end

    for _, tInfo in ipairs(tPackTree or {}) do
        if tInfo.nLevel == 1 and tInfo.nType == 3 then
            _insertCatogory(RESOURCES_PAGE.RECOMMEND, tInfo.nType, tInfo.bRecommend)
        end
    end

    for _, tInfo in ipairs(tPackTree or {}) do
        if tInfo.nLevel == 1 and tInfo.nType == 2 then
            _insertCatogory(RESOURCES_PAGE.GAMEPLAY, tInfo.nType, tInfo.bRecommend)
        end
    end

    if RESOURCES_PAGE.MANAGER then
        tData[RESOURCES_PAGE.MANAGER] = {
            tArgs = {szTitle = "资源管理", bHasChild = true},
            tItemList = {},
        }
    end

    local tDynViewList = self.scriptResources:GetViewList(2, true) --获取外显分类的下载任务数量，若无则不显示次级导航
    local bDynHasChild = tDynViewList and #tDynViewList > 0
    if RESOURCES_PAGE.DOWNLOADING then
        tData[RESOURCES_PAGE.DOWNLOADING] = {
            tArgs = {szTitle = "正在下载", bHasChild = bDynHasChild},
            tItemList = bDynHasChild and {
                {tArgs = {szTitle = "主要"}},
                {tArgs = {szTitle = "外显"}},
            },
        }
    end

    --插入资源管理次级导航
    for _, tInfo in ipairs(tPackTree or {}) do
        if tInfo.nLevel == 1 and tInfo.nType == 1 then
            table.insert(tData[RESOURCES_PAGE.MANAGER].tItemList, {tArgs = {szTitle = tInfo.szName, bRecommend = tInfo.bRecommend}})
        end
    end

    UIHelper.SetupScrollViewTree(self.scriptScrollViewTree, PREFAB_ID.WidgetDownloadResourcesTitle, PREFAB_ID.WidgetSettingSubNav,
    function(scriptContainer, tArgs)
        UIHelper.SetString(scriptContainer.LabelTitle, tArgs.szTitle)
        UIHelper.SetString(scriptContainer.LabelSelect, tArgs.szTitle)
        UIHelper.SetVisible(scriptContainer.ImgRecommend, tArgs.bRecommend)
        UIHelper.SetVisible(scriptContainer.ImgNormalTree, tArgs.bHasChild)
        UIHelper.SetVisible(scriptContainer.WidgetSelectTree, tArgs.bHasChild)
        UIHelper.SetVisible(scriptContainer.ImgNormal, not tArgs.bHasChild)
        UIHelper.SetVisible(scriptContainer.WidgetSelect, not tArgs.bHasChild)
    end, tData)

    Timer.AddFrame(self, 1, function()
        --初始化选中事件和次级Toggle
        local tContainerList = self.scriptScrollViewTree.tContainerList
        for nIndex, tContainerInfo in ipairs(tContainerList) do

            local nSelectIndex = nIndex
            self.scriptScrollViewTree:SetContainerCallback(nSelectIndex, function(bSelected, scriptContainer)
                if bSelected then
                    if self.nSelectIndex ~= nSelectIndex then
                        if self.nSelectIndex and self.tSubTogList[self.nSelectIndex] then
                            UIHelper.SetSelected(self.tSubTogList[self.nSelectIndex][self.nSubSelectIndex], false, false)
                        end
                        self.nSelectIndex = nSelectIndex
                        self.nSubSelectIndex = 1
                    end

                    --触发特效播放
                    UIHelper.SetSelected(self.tSubTogList[self.nSelectIndex][self.nSubSelectIndex], false, false)
                    UIHelper.SetSelected(self.tSubTogList[self.nSelectIndex][self.nSubSelectIndex], true, false)

                    self:UpdateInfo()
                end
            end)

            self.tSubTogList[nSelectIndex] = {}
            local tItemScripts = tContainerInfo.scriptContainer:GetItemScript()
            for nSubIndex, itemScript in ipairs(tItemScripts) do
                local nSubSelectIndex = nSubIndex
                table.insert(self.tSubTogList[nSelectIndex], itemScript.ToggleChildNavigation)
                UIHelper.BindUIEvent(itemScript.ToggleChildNavigation, EventType.OnSelectChanged, function(_, bSelected)
                    if bSelected then
                        self.nSubSelectIndex = nSubSelectIndex
                        self:UpdateInfo()
                    end
                end)
            end
        end
    end)

    UIHelper.SetVisible(self.BtnDownloadAll, false)
    UIHelper.SetVisible(self.WidgetAnchorNetworkDownLoad, Platform.IsMobile())
    UIHelper.SetVisible(self.WidgetAnchorSwitchDownloadBall, g_pClientPlayer ~= nil)
    UIHelper.SetSelected(self.TogNetworkDownLoad, PakDownloadMgr.GetAllowNotWifiDownload(), false)
    UIHelper.SetSelected(self.TogSwithDownloadBall, Storage.Download.bShowDownloadBall, false)
    UIHelper.LayoutDoLayout(self.LayoutRT)

    UIHelper.SetVisible(self.ImgBtnLine, Platform.IsMobile() or g_pClientPlayer ~= nil)

    if Platform.IsWindows() or Platform.IsMac() then
        UIHelper.SetRichText(self.LabelCoreWarning, "<color=#E2F6FB>若未下载核心资源包，游玩过程中可能会因资源下载</c><color=#FFE26E>影响游戏体验</c>，<color=#E2F6FB>建议提前进行下载。</c>")
    else
        UIHelper.SetRichText(self.LabelCoreWarning, "<color=#E2F6FB>若未下载核心资源包，游玩过程中可能会因资源下载</c><color=#FFE26E>导致额外的流量消耗</c>，<color=#E2F6FB>建议提前进行下载。</c>")
    end
end

function UIResourcesDownloadView:UpdateInfo()
    if not self.scriptResources or not self.nSelectIndex then
        return
    end

    local tMainPageIndex = { RESOURCES_PAGE.RECOMMEND, RESOURCES_PAGE.GAMEPLAY }

    if table.contain_value(tMainPageIndex, self.nSelectIndex) then
        self.scriptResources:UpdateInfo(self.nSelectIndex) 
    elseif self.nSelectIndex == RESOURCES_PAGE.MANAGER then
        self.scriptResources:UpdateInfo(self.nSubSelectIndex + #tMainPageIndex)
    elseif self.nSelectIndex == RESOURCES_PAGE.DOWNLOADING then
        self.bSelectDownloading = true
        self.scriptResources:UpdateInfo(self.nSubSelectIndex, true)
    end

    UIHelper.SetVisible(self.LabelCoreWarning, self.nSelectIndex == RESOURCES_PAGE.RECOMMEND)
    UIHelper.LayoutDoLayout(self.LayoutWarning)
end

function UIResourcesDownloadView:SetPageSelect(nSelectIndex, nSubSelectIndex)
    nSelectIndex = nSelectIndex or 1
    nSubSelectIndex = nSubSelectIndex or 1
    if self.nSelectIndex == nSelectIndex and self.nSubSelectIndex == nSubSelectIndex then
        return
    end
    self.nSelectIndex = nSelectIndex
    self.nSubSelectIndex = nSubSelectIndex

    self.scriptScrollViewTree:SetContainerSelected(self.nSelectIndex, true, true)
        if self.tSubTogList[self.nSelectIndex] then
            UIHelper.SetSelected(self.tSubTogList[self.nSelectIndex][self.nSubSelectIndex], true, false)
        end
    self:UpdateInfo()
end

function UIResourcesDownloadView:GetSelectState(tPackIDList)
    return self.scriptResources and self.scriptResources:GetSelectState(tPackIDList)
end

return UIResourcesDownloadView
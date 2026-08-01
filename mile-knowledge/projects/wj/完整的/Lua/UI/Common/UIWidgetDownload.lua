-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIWidgetDownload
-- Date: 2023-04-10 11:27:26
-- Desc: WidgetDownloadBtn
-- ---------------------------------------------------------------------------------

local UIWidgetDownload = class("UIWidgetDownload")

local TIPS_SHOW_TIME = 3
local COMPLETE_SHOW_TIME = 3

local ANIM_TYPE = {
    CONTINUE = 1,
    SUSPEND = 2,
}

--[[
    @nPackID 资源ID
    @tConfig = {
        szName = XXX, --长按钮未下载状态下方显示的文本，若不填则显示默认内容
        nDungeonEnterPackID = XXX, --秘境入口资源ID，下载秘境时捆绑下载
        bShowBg = false, --显示底图
        fnOnComplete = XXX, --下载完成回调
        bCell = false, --是否资源管理界面Cell中使用
        bHideSize = false, --隐藏大小
        bInit = false, --是否初始化，不填则默认为true
        fnGetProgressText = XXX, --进度文本
        fnOnSetVisible = nil, --显示隐藏回调
    }
--]]
--管理单个资源的下载
function UIWidgetDownload:OnInitWithPackID(nPackID, tConfig)
    --检查
    assert(PakDownloadMgr.GetPackInfo(nPackID), tostring(nPackID))

    self:ClearData()
    self.nPackID = nPackID
    self.tConfig = tConfig
    self:SetVisible(true)

    local nState, _, _ = PakDownloadMgr.GetPackState(nPackID)
    if nState == DOWNLOAD_OBJECT_STATE.DOWNLOADED then
        self:SetVisible(false)
    end

    local bInit = true
    if self.tConfig and self.tConfig.bInit ~= nil then
        bInit = self.tConfig.bInit
    end

    self:UpdateInfo(bInit)
end

--[[
    @tPackIDList = {
        1, 2, ...
    }
    @tConfig = {
        szName = XXX, --长按钮未下载状态下方显示的文本，若不填则显示默认内容
        bShowBg = false, --显示底图
        bCell = false, --是否资源管理界面Cell中使用
        bInit = false, --是否初始化，不填则默认为true
        szGroupName = XXX, --弹窗时用于显示当前所属分类的名称
        nMutexPackTreeID = XXX, --作为推荐包的下载按钮时，记录自身所在推荐包的ID，管理推荐包互斥下载状态
        fnGetProgressText = XXX, --进度文本
        fnOnSetVisible = nil, --显示隐藏回调
    }
--]]
--管理一个资源列表的下载
function UIWidgetDownload:OnInitWithPackIDList(tPackIDList, tConfig)
    assert(tPackIDList)

    self:ClearData()
    self.tPackIDList = tPackIDList
    self.tConfig = tConfig
    self:SetVisible(true)

    --全部下载完成则隐藏自身
    local tStateInfo = PakDownloadMgr.GetStateInfoByPackIDList(self.tPackIDList)
    if tStateInfo.nState == DOWNLOAD_STATE.COMPLETE then
        self:SetVisible(false)
        return
    end

    local bInit = true
    if self.tConfig and self.tConfig.bInit ~= nil then
        bInit = self.tConfig.bInit
    end

    self:UpdateInfo(bInit)
end

--[[
    @tPackIDListInfo = {
        [1] = {
            szName = "所有资源挂件",
            tPackIDList = {1, 2, ...},
        },
        [2] = {
            szName = "拥有的资源挂件",
            tPackIDList = {1, 2, ...},
        },
    }
    若只有一项，可写成
    tPackIDListInfo = {
        szName = "所有资源挂件",
        tPackIDList = {1, 2, ...},
    }

    @tConfig = {
        nTipsDir = TipsLayoutDir.XXX --Tips弹出方向，不填则自动
    }
--]]
--管理多组不同资源列表的下载
function UIWidgetDownload:OnInitWithPackIDListInfo(tPackIDListInfo, tConfig)
    assert(tPackIDListInfo)

    if #tPackIDListInfo <= 0 and tPackIDListInfo.tPackIDList then
        tPackIDListInfo = {tPackIDListInfo}
    end

    --检查
    assert(IsTable(tPackIDListInfo))
    for nIndex, tInfo in ipairs(tPackIDListInfo) do
        --assert(IsTable(tInfo.szName), tostring(nIndex))
        assert(IsTable(tInfo.tPackIDList), tostring(nIndex))
    end

    self:ClearData()
    self.tPackIDListInfo = tPackIDListInfo
    self.tConfig = tConfig
    self:SetVisible(true)

    self.tPackIDList = {}
    for nIndex, tInfo in ipairs(tPackIDListInfo) do
        for _, nPackID in ipairs(tInfo.tPackIDList) do
            table.insert(self.tPackIDList, nPackID)
        end
    end

    --全部下载完成则隐藏自身
    local tStateInfo = PakDownloadMgr.GetStateInfoByPackIDList(self.tPackIDList)
    if tStateInfo.nState == DOWNLOAD_STATE.COMPLETE then
        self:SetVisible(false)
        return
    end

    self:UpdateInfo(true)
end

--基础资源
function UIWidgetDownload:OnInitBasic(tConfig)
    self:ClearData()
    self.bBasic = true
    self.tConfig = tConfig
    self:SetVisible(true)

    self:UpdateBasicTips()
    self:UpdateInfo(true)
end

--[[
    @tConfig = {
        szName = XXX --未开始下载时显示的文本
        bShowTips = false, --是否常驻显示“下载中”Tips
        fnOnSetVisible = nil, --显示隐藏回调
    }
--]]
function UIWidgetDownload:OnInitTotal(tConfig)
    self:ClearData()
    self.bTotal = true
    self.tConfig = tConfig
    self:SetVisible(true)

    self:UpdateBasicTips()
    self:UpdateInfo(true)
end

--下载完成提示，传入PackID列表，注意WidgetDownload的nType要设置为3才能显示对应的下载完成预制
function UIWidgetDownload:OnInitWithCompleteHintPackIDList(tCompleteHintPackIDList, tConfig)
    self:ClearData()
    self.tCompleteHintPackIDList = tCompleteHintPackIDList
    self.tConfig = tConfig

    self:SetVisible(false)
end

function UIWidgetDownload:OnInitWithHint(tConfig)
    self:ClearData()

    self.bHint = true
    self.tConfig = tConfig

    self:SetVisible(true)
    self:UpdateInfo(true)
end

function UIWidgetDownload:ClearData()
    Timer.DelTimer(self, self.nCompleteTimerID)
    self:CloseTips()
    self:StopAnim()
    self.nPackID = nil
    self.tConfig = nil
    self.tPackIDListInfo = nil
    self.tPackIDList = nil
    self.bBasic = false
    self.bTotal = false
    self.bHint = false
    self.tCompleteHintPackIDList = nil

    PakSizeQueryMgr.UnRegAllQuerySize(self)
    if self.bQuerySize then
        WaitingTipsData.RemoveWaitingTips("QuerySize")
        self.bQuerySize = false
    end
end

----------------------------------------------------------------------------------

function UIWidgetDownload:OnEnter(nType)
    self.nType = nType or 1 -- 预制绑定常量：self.nType, 1: Btn, 2: Img, 3: FinishHint

    Timer.DelAllTimer(self)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    local bType1 = self.nType == 1
    UIHelper.SetVisible(self.BtnDownload, bType1)
    UIHelper.SetVisible(self.LabelPrograss, bType1)
    UIHelper.SetVisible(self.LabelStatus, bType1)
    UIHelper.SetVisible(self.LayoutHint, bType1)

    UIHelper.SetVisible(self.ImgDownload, self.nType == 2)
    UIHelper.SetVisible(self.WidgetWorldMapFinished, self.nType == 3)

    UIHelper.SetTouchEnabled(self.LayoutDes, true)

    self:UpdateInfo(true)

    --若正在下载，固定每0.1s更新一次
    Timer.AddCycle(self, 0.1, function()
        if not PakDownloadMgr.IsUIUpdateEnabled() then
            return
        end

        if self.nSkipUpdate and self.nSkipUpdate > 0 then
            self.nSkipUpdate = self.nSkipUpdate - 1
        else
            local bVisible = UIHelper.GetVisible(self._rootNode)
            if bVisible and (self:IsDownloading() or not self.bVisible) then
                self:UpdateInfo()
            end
            self.bVisible = bVisible
        end
        self:UpdateProgress()
    end)
end

function UIWidgetDownload:OnExit()
    self.bInit = false
    self:UnRegEvent()

    PakSizeQueryMgr.UnRegAllQuerySize(self)
    if self.bQuerySize then
        WaitingTipsData.RemoveWaitingTips("QuerySize")
        self.bQuerySize = false
    end

    if g_btnDownloadLong == self.BtnDownload then
        g_btnDownloadLong = nil
    end
    if g_btnDownload == self.BtnDownload then
        g_btnDownload = nil
    end

    self.bUpdatingView = false

    self:ClearData()
end

function UIWidgetDownload:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnDownload, EventType.OnClick, function()
        Timer.DelTimer(self, self.nCompleteTimerID)
        if self.nPackID then
            if PakDownloadMgr.IsBasicPack(self.nPackID) then
                self:OnBasicBtnClick()
            else
                local nViewState = PakDownloadMgr.GetPackViewState(self.nPackID)
                self:OnBtnClick(nViewState)
            end
        elseif self.tPackIDListInfo then
            local nTipsDir = self.tConfig and self.tConfig.nTipsDir or TipsLayoutDir.AUTO
            --TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetDownloadMultiTips, self.BtnDownload, nTipsDir, self.tPackIDListInfo)
            local tips, scriptView = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetResourceDetailTip, self.BtnDownload, nTipsDir, self.tPackIDListInfo, true)
            tips:SetSize(UIHelper.GetContentSize(scriptView:GetContainer()))
            tips:Update()
        elseif self.tPackIDList then
            local tStateInfo = PakDownloadMgr.GetStateInfoByPackIDList(self.tPackIDList)
            local nState = tStateInfo.nState
            local nMutexPackTreeID = self.tConfig and self.tConfig.nMutexPackTreeID
            if nMutexPackTreeID and RecommendPakMutexMgr.IsMutex(nMutexPackTreeID) and nState ~= DOWNLOAD_STATE.COMPLETE then
                nState = DOWNLOAD_STATE.NONE
            end
            self:OnBtnClick(nState)
        elseif self.bBasic then
            self:OnBasicBtnClick()
        elseif self.bTotal then
            local tTotalInfo = PakDownloadMgr.GetTotalDownloadInfo()
            local nPage = tTotalInfo.nTotalTask > 0 and RESOURCES_PAGE.DOWNLOADING or RESOURCES_PAGE.RECOMMEND
            UIMgr.Open(VIEW_ID.PanelResourcesDownload, nPage)
        elseif self.bHint then
            local szHint = self.tConfig and self.tConfig.szHint or g_tStrings.STR_EQUIP_RES_REMOTE_NOT_EXIST
            TipsHelper.ShowNormalTip(szHint)
        end
        self:UpdateInfo()
    end)
    UIHelper.BindUIEvent(self.LayoutDes, EventType.OnClick, function()
        UIHelper.SimulateClick(self.BtnDownload)
    end)
end

function UIWidgetDownload:RegEvent()
    Event.Reg(self, EventType.PakDownload_OnStateUpdate, function(nPackID)
        if self.nPackID and self.nPackID ~= nPackID then
            return
        end

        if self.tPackIDList and not table.contain_value(self.tPackIDList, nPackID) then
            return
        end

        if self.nSkipUpdate and self.nSkipUpdate > 0 then
            return
        end

        if self.bTotal then
            --由于下载完成后会先收到当前任务完成的OnStateUpdate，再收到下一个任务开始的OnStateUpdate，最后收到OnComplete
            --所以为了避免下一任务开始时调用到UpdateInfo导致进度清零，所以在收到当前任务完成的OnStateUpdate后就立即处理而不在OnComplete里处理
            local tDownloadInfo = PakDownloadMgr.GetDownloadingInfo(nPackID)
            if tDownloadInfo and tDownloadInfo.nState == DOWNLOAD_STATE.COMPLETE then
                self.nSkipUpdate = 3
                self:SetProgress(1)
                self:SetString(string.format("%0.1f%%", self.nProgress * 100))
                return
            end
        end

        --延迟更新，避免一帧内多次更新
        if self.bUpdatingView then
            return
        end

        self.bUpdatingView = true
        Timer.AddFrame(self, 1, function()
            self.bUpdatingView = false
            self:UpdateInfo()
        end)
    end)
    Event.Reg(self, EventType.PakDownload_OnQueue, function(nPackID)
        if self.nPackID and nPackID ~= self.nPackID then
            return
        end

        if self.tPackIDList and not table.contain_value(self.tPackIDList, nPackID) then
            return
        end

        local tDownloadInfo = PakDownloadMgr.GetDownloadingInfo(nPackID)
        if tDownloadInfo and not tDownloadInfo.bRetryFlag then
            if not PakDownloadMgr.IsInBasicIDList(nPackID) and not PakDownloadMgr.IsAllBasicPackComplete() and not PakDownloadMgr.IsTopMostPack(nPackID) then
                TipsHelper.ShowNormalTip("已添加至下载队列，需要等待基础资源下载完成")
            elseif PakDownloadMgr.GetPriorityList() and not PakDownloadMgr.IsPriorityPack(nPackID) and not PakDownloadMgr.IsAllPriorityPackComplete() then
                TipsHelper.ShowNormalTip("已添加至下载队列，需要等待优先下载完成")
            end
        end
    end)
    Event.Reg(self, EventType.PakDownload_OnComplete, function(nPackID, nResult)
        local bCell = self.tConfig and self.tConfig.bCell

        --下载完成后一段时间隐藏
        if not bCell and self.nPackID and nPackID == self.nPackID and nResult == DOWNLOAD_OBJECT_RESULT.SUCCESS then
            self.nCompleteTimerID = Timer.Add(self, COMPLETE_SHOW_TIME, function()
                self:OnComplete()
            end)
            return
        end

        --下载完成后一段时间隐藏
        if not bCell and self.tPackIDList and table.contain_value(self.tPackIDList, nPackID) and nResult == DOWNLOAD_OBJECT_RESULT.SUCCESS then
            local tStateInfo = PakDownloadMgr.GetStateInfoByPackIDList(self.tPackIDList)
            if tStateInfo == DOWNLOAD_STATE.COMPLETE then
                self.nCompleteTimerID = Timer.Add(self, COMPLETE_SHOW_TIME, function()
                    self:OnComplete()
                end)
            end
            return
        end

        if self.bTotal then
            if nResult == DOWNLOAD_OBJECT_RESULT.SUCCESS then
                --所有任务完成后过一段时间刷新
                if not self:IsDownloading() then
                    self.nCompleteTimerID = Timer.Add(self, 2, function()
                        self:UpdateInfo()
                    end)
                end
            end

            --下载失败处理
            if nResult ~= DOWNLOAD_OBJECT_RESULT.SUCCESS then
                self.nErrorResult = nResult
            end
            return
        end

        if self.tCompleteHintPackIDList and table.contain_value(self.tCompleteHintPackIDList, nPackID) and nResult == DOWNLOAD_OBJECT_RESULT.SUCCESS then
            self:SetVisible(true)
            return
        end
    end)
    Event.Reg(self, EventType.OnGameSettingDiscardRes, function(bDiscard)
        self:SetDiscard(bDiscard)
    end)
    Event.Reg(self, EventType.OnRoleSelected, function(nRoleIndex)
        self:UpdateBasicTips(nRoleIndex)
    end)
end

function UIWidgetDownload:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetDownload:UpdateInfo(bInit)
    if self.nPackID then
        self:UpdatePackState()
    elseif self.tPackIDListInfo or self.tPackIDList then
        self:UpdatePackListState()
    elseif self.bBasic then
        self:UpdateBasicState()
    elseif self.bTotal then
        self:UpdateTotalState()
    elseif self.bHint then
        self:UpdateHintState()
    end

    if bInit and self.nProgress then
        UIHelper.SetProgressBarPercent(self.ImgProgress, self.nProgress * 100)
    end

    local tConfig = self.tConfig
    if bInit and tConfig and tConfig.nTouchWidth and tConfig.nTouchHeight then
        UIHelper.SetContentSize(self.BtnDownload, tConfig.nTouchWidth, tConfig.nTouchHeight)
    end
    if bInit and tConfig and IsBoolean(tConfig.bSwallowTouch) then
        UIHelper.SetSwallowTouches(self.BtnDownload, tConfig.bSwallowTouch)
    end

    local bShowBg = tConfig and tConfig.bShowBg or false
    UIHelper.SetVisible(self.ImgBg_Map, bShowBg)

    local bCell = tConfig and tConfig.bCell
    if bInit then
        -- UIHelper.SetVisible(self.ImgBg, bCell)
        -- UIHelper.SetVisible(self.ImgProgress, bCell)
        UIHelper.SetVisible(self.Eff_WenJuanTip, not bCell)
    end
end

function UIWidgetDownload:UpdatePackState()
    local nState, dwTotalSize, dwDownloadedSize, nTotalFile, nDownloadedFile = PakDownloadMgr.GetPackState(self.nPackID)
    local nViewState = PakDownloadMgr.GetPackViewState(self.nPackID)
    local nProgress = PakDownloadMgr.CalcProgress(dwTotalSize, dwDownloadedSize, nTotalFile, nDownloadedFile)
    self:SetViewByState(nViewState, dwTotalSize, nProgress)
end

function UIWidgetDownload:UpdatePackListState()
    local tStateInfo = PakDownloadMgr.GetStateInfoByPackIDList(self.tPackIDList)
    local nState = tStateInfo.nState
    local nProgress = tStateInfo.nProgress
    local nMutexPackTreeID = self.tConfig and self.tConfig.nMutexPackTreeID
    if nMutexPackTreeID and RecommendPakMutexMgr.IsMutex(nMutexPackTreeID) and nState ~= DOWNLOAD_STATE.COMPLETE then
        nState = DOWNLOAD_STATE.NONE
        nProgress = 0
    end
    self:SetViewByState(nState, tStateInfo.dwTotalSize, nProgress)
end

function UIWidgetDownload:UpdateBasicState()
    local nProgress = 0
    local szContent = ""

    if PakDownloadMgr.IsBasicDownloading() then
        local tTotalInfo = PakDownloadMgr.GetTotalDownloadInfo()
        local nTotalState = tTotalInfo.nTotalState

        nProgress = tTotalInfo.nProgress
        szContent = string.format("%0.1f%%", nProgress * 100)

        if nTotalState == TOTAL_DOWNLOAD_STATE.DOWNLOADING then
            szContent = "下载中\n" ..szContent
        elseif nTotalState == TOTAL_DOWNLOAD_STATE.PAUSING then
            szContent = "已暂停\n" ..szContent
        elseif nTotalState == TOTAL_DOWNLOAD_STATE.RETRYING then
            szContent = "重试中\n" ..szContent
        end

        UIHelper.SetVisible(self.WidgetDownloading, nTotalState == TOTAL_DOWNLOAD_STATE.DOWNLOADING)
        UIHelper.SetVisible(self.WidgetPaused, nTotalState == TOTAL_DOWNLOAD_STATE.PAUSING or nTotalState == TOTAL_DOWNLOAD_STATE.RETRYING)
        UIHelper.SetVisible(self.WidgetReadyToDownload, false)
        UIHelper.SetVisible(self.WidgetWaitingInLine, false)
        UIHelper.SetVisible(self.WidgetFinished, false)
    else
        local nState, _, _ = PakDownloadMgr.GetBasicPackState()
        if nState == DOWNLOAD_OBJECT_STATE.DOWNLOADED then
            szContent = "已完成"
            nProgress = 1
        else
            szContent = "未开始"
            nProgress = 0
        end
        UIHelper.SetVisible(self.WidgetReadyToDownload, nState ~= DOWNLOAD_OBJECT_STATE.DOWNLOADED)
        UIHelper.SetVisible(self.WidgetFinished, nState == DOWNLOAD_OBJECT_STATE.DOWNLOADED)
        UIHelper.SetVisible(self.WidgetDownloading, false)
        UIHelper.SetVisible(self.WidgetWaitingInLine, false)
        UIHelper.SetVisible(self.WidgetPaused, false)
    end

    self:SetProgress(nProgress)
    self:SetString(szContent)
    self:UpdateAnim()
end

function UIWidgetDownload:UpdateTotalState()
    local nProgress = 0
    local szContent = ""

    local tTotalInfo = PakDownloadMgr.GetTotalDownloadInfo()
    local nTotalState = tTotalInfo.nTotalState
    if nTotalState == TOTAL_DOWNLOAD_STATE.NONE then
        nProgress = 0
        szContent = self.tConfig and self.tConfig.szName or "资源"
    else
        nProgress = tTotalInfo.nCurProgress
        if nTotalState == TOTAL_DOWNLOAD_STATE.RETRYING then
            szContent = "重试中"
            nProgress = 0
        elseif nTotalState == TOTAL_DOWNLOAD_STATE.PAUSING then
            --暂停时，若只有一个任务时显示进度，否则显示暂停中
            local nCurTask = tTotalInfo.nTotalTask - tTotalInfo.nCompleteTask
            if nCurTask > 1 then
                szContent = "已暂停"
                nProgress = 0
            else
                szContent = string.format("%0.1f%%", nProgress * 100)
            end
        else
            szContent = string.format("%0.1f%%", nProgress * 100)
        end
    end

    UIHelper.SetVisible(self.WidgetDownloading, nTotalState == TOTAL_DOWNLOAD_STATE.DOWNLOADING)
    UIHelper.SetVisible(self.WidgetPaused, nTotalState == TOTAL_DOWNLOAD_STATE.PAUSING or nTotalState == TOTAL_DOWNLOAD_STATE.RETRYING)
    UIHelper.SetVisible(self.WidgetReadyToDownload, nTotalState == TOTAL_DOWNLOAD_STATE.NONE)
    UIHelper.SetVisible(self.WidgetWaitingInLine, false)
    UIHelper.SetVisible(self.WidgetFinished, false)

    self:SetProgress(nProgress)
    self:SetString(szContent)
    self:UpdateAnim()
    self:UpdateBasicTips()
end

function UIWidgetDownload:UpdateHintState()
    local nProgress = 0
    local szProgress = ""
    local szState = self.tConfig and self.tConfig.szStateHint or "下载资源"

    UIHelper.SetVisible(self.WidgetDownloading, false)
    UIHelper.SetVisible(self.WidgetPaused, false)
    UIHelper.SetVisible(self.WidgetReadyToDownload, true)
    UIHelper.SetVisible(self.WidgetWaitingInLine, false)
    UIHelper.SetVisible(self.WidgetFinished, false)

    self:SetProgress(nProgress)
    self:SetString(szProgress, szState)
    self:UpdateAnim()
end

function UIWidgetDownload:SetViewByState(nState, dwTotalSize, nProgress)
    local szProgress = ""
    local szState = ""

    local bCell = self.tConfig and self.tConfig.bCell or false
    local bHideSize = self.tConfig and self.tConfig.bHideSize
    local nMutexPackTreeID = self.tConfig and self.tConfig.nMutexPackTreeID
    local fnGetProgressText = self.tConfig and self.tConfig.fnGetProgressText

    if nState == DOWNLOAD_STATE.NONE then
        if bCell then
            --2024.2.23 策划需求，资源管理界面内的批量下载按钮，未下载时显示为0/N
            --若为推荐互斥，则不显示
            szProgress = (not nMutexPackTreeID and self.tPackIDList) and ("0/" .. #self.tPackIDList) or ""
        elseif not bHideSize then
            szProgress = PakDownloadMgr.FormatSize(dwTotalSize, 0) --保留整数
        end

        szState = self.tConfig and self.tConfig.szName or "下载资源"

    elseif nState ~= DOWNLOAD_STATE.COMPLETE then
        if nState == DOWNLOAD_STATE.DOWNLOADING then
            szState = "下载中"
        elseif nState == DOWNLOAD_STATE.PAUSE then
            szState = "暂停中"
        elseif nState == DOWNLOAD_STATE.QUEUE then
            szState = "等待中"
        end
        if self.tPackIDListInfo then
            local nDownloadedCount = 0
            for _, tInfo in ipairs(self.tPackIDListInfo) do
                local tStateInfo = PakDownloadMgr.GetStateInfoByPackIDList(tInfo.tPackIDList)
                if tStateInfo.nState == DOWNLOAD_STATE.COMPLETE then
                    nDownloadedCount = nDownloadedCount + 1
                end
            end
            szProgress = nDownloadedCount .. "/" .. #self.tPackIDListInfo
        else
            szProgress = string.format("%0.1f%%", nProgress * 100)
        end
    else
        szState = "下载完成"
    end

    local bStarted = nState == DOWNLOAD_STATE.DOWNLOADING or nState == DOWNLOAD_STATE.PAUSE or (nState == DOWNLOAD_STATE.QUEUE and nProgress > 0)

    --资源管理界面 按钮表示操作，即下载状态显示暂停图标，暂停状态显示下载图标，所以这里交换一下
    local widgetDownload = bCell and self.WidgetPaused or self.WidgetDownloading
    local widgetPaused = bCell and self.WidgetDownloading or self.WidgetPaused

    UIHelper.SetVisible(widgetDownload, nState == DOWNLOAD_STATE.DOWNLOADING or (bCell and nState == DOWNLOAD_STATE.QUEUE))
    UIHelper.SetVisible(self.WidgetReadyToDownload, nState == DOWNLOAD_STATE.NONE)
    UIHelper.SetVisible(self.WidgetWaitingInLine, nState == DOWNLOAD_STATE.QUEUE and not bCell)
    UIHelper.SetVisible(widgetPaused, nState == DOWNLOAD_STATE.PAUSE)
    UIHelper.SetVisible(self.WidgetFinished, nState == DOWNLOAD_STATE.COMPLETE)

    if fnGetProgressText then
        szProgress = fnGetProgressText() or szProgress
    end

    self:SetProgress(nProgress)
    self:SetString(szProgress, szState)
    self:UpdateAnim()
end

function UIWidgetDownload:OnBtnClick(nState)
    if nState == DOWNLOAD_STATE.NONE or nState == DOWNLOAD_STATE.QUEUE or nState == DOWNLOAD_STATE.PAUSE then
        local bCell = self.tConfig and self.tConfig.bCell
        if nState == DOWNLOAD_STATE.QUEUE and bCell then
            self:PausePack() --资源管理界面 排队时可点击暂停
        else
            self:DownloadPack()
        end
    elseif nState == DOWNLOAD_STATE.DOWNLOADING then
        self:PausePack()
    elseif nState == DOWNLOAD_STATE.COMPLETE then
        self:OnComplete()
    end
end

function UIWidgetDownload:OnBasicBtnClick()
    --UIMgr.Open(VIEW_ID.PanelResourcesDownloadPop)
    local nState, dwTotalSize, dwDownloadedSize = PakDownloadMgr.GetBasicPackState()
    local dwLeftDownloadSize = dwTotalSize - dwDownloadedSize
    if PakDownloadMgr.IsBasicDownloading() then
        if PakDownloadMgr.IsBasicPause() then
            PakDownloadMgr.CheckNetDownload(PakDownloadMgr.ResumeBasicPack, dwLeftDownloadSize)
        else
            PakDownloadMgr.PauseBasicPack()
        end
    elseif nState ~= DOWNLOAD_OBJECT_STATE.DOWNLOADED then
        PakDownloadMgr.CheckNetDownload(PakDownloadMgr.DownloadBasicPack, dwLeftDownloadSize)
    end
end

function UIWidgetDownload:DownloadPack()
    local bCanDownload, tNewPackIDList = self:CheckCanDownload()
    if not bCanDownload then
        return
    end

    local fnDownload

    --资源管理界面
    local bCell = self.tConfig and self.tConfig.bCell
    if bCell then
        fnDownload = function()
            if self.nPackID then
                PakDownloadMgr.DownloadPack(self.nPackID)
            elseif self.tPackIDList then
                local nMutexPackTreeID = self.tConfig and self.tConfig.nMutexPackTreeID
                if nMutexPackTreeID then
                    RecommendPakMutexMgr.StartMutexDownload(nMutexPackTreeID, function()
                        PakDownloadMgr.DownloadPackListImmediately(self.tPackIDList)
                    end)
                else
                    for _, nPackID in ipairs(self.tPackIDList) do
                        PakDownloadMgr.DownloadPack(nPackID)
                    end
                end
            end
        end
    else
        local function _checkDownloadDungeonEnterPack()
            --秘境入口资源ID，下载秘境时捆绑下载
            local nDungeonEnterPackID = self.tConfig and self.tConfig.nDungeonEnterPackID
            if not nDungeonEnterPackID then
                return
            end

            local nViewState = PakDownloadMgr.GetPackViewState(nDungeonEnterPackID)
            if nViewState ~= DOWNLOAD_STATE.COMPLETE then
                PakDownloadMgr.DownloadPack(nDungeonEnterPackID)
                local nCurViewState = PakDownloadMgr.GetPackViewState(nDungeonEnterPackID)
                if nViewState ~= DOWNLOAD_STATE.QUEUE and nViewState ~= DOWNLOAD_STATE.DOWNLOADING and nCurViewState == DOWNLOAD_STATE.DOWNLOADING then
                    TipsHelper.ShowNormalTip("前往秘境需要入口场景资源，已自动开始下载")
                end
                nViewState = PakDownloadMgr.GetPackViewState(nDungeonEnterPackID)  --若调用下载后，在等待队列中，则移到等待队列队首
                if nViewState == DOWNLOAD_STATE.QUEUE then
                    PakDownloadMgr._SetDownloadingState(nDungeonEnterPackID, DOWNLOAD_STATE.QUEUE, true)
                end
            end
        end

        fnDownload = function()
            local bAllPriorityPackComplete = PakDownloadMgr.IsAllPriorityPackComplete()
            local bAllBasicPackComplete = PakDownloadMgr.IsAllBasicPackComplete()
            if self.nPackID then
                local nViewState = PakDownloadMgr.GetPackViewState(self.nPackID)
                local bTopMost = self.tConfig and self.tConfig.bTopMost
                if bTopMost then
                    PakDownloadMgr.DownloadPackTopMost(self.nPackID)
                elseif bAllPriorityPackComplete and bAllBasicPackComplete then
                    _checkDownloadDungeonEnterPack()
                    PakDownloadMgr.DownloadPackImmediately(self.nPackID)
                else
                    _checkDownloadDungeonEnterPack()
                    PakDownloadMgr.DownloadPack(self.nPackID)
                    local nViewState = PakDownloadMgr.GetPackViewState(self.nPackID)
                    if nViewState == DOWNLOAD_STATE.QUEUE then
                        PakDownloadMgr._SetDownloadingState(self.nPackID, DOWNLOAD_STATE.QUEUE, true)
                        if not bAllPriorityPackComplete then
                            TipsHelper.ShowNormalTip("已添加至下载队列，需要等待优先下载完成")
                        elseif not bAllBasicPackComplete then
                            TipsHelper.ShowNormalTip("已添加至下载队列，需要等待基础资源下载完成")
                        end
                    end
                end
            elseif self.tPackIDList then
                PakDownloadMgr.DownloadPackListImmediately(self.tPackIDList)
            end
        end
    end

    if fnDownload then
        if bCell and self.tPackIDList and #self.tPackIDList > 1 then
            local szGroupName = self.tConfig and self.tConfig.szGroupName or "当前分类"
            if not self.bQuerySize then
                self.bQuerySize = true
                local tMsg = {
                    szType = "QuerySize",
                    szWaitingMsg = "正在计算资源大小...",
                    bSwallow = true,
                }
                WaitingTipsData.PushWaitingTips(tMsg)
                local tPackIDList = tNewPackIDList or self.tPackIDList --根据排除部分不可下载任务的新列表来查询大小
                PakSizeQueryMgr.RegQuerySize(self, tPackIDList, function(bSuccess, dwTotalSize, dwDownloadedSize)
                    self.bQuerySize = false
                    WaitingTipsData.RemoveWaitingTips("QuerySize")
                    if bSuccess then
                        local dwLeftDownloadSize = dwTotalSize - dwDownloadedSize
                        if dwLeftDownloadSize > 0 then
                            local nLeftDownloadCount = 0
                            local szLeftDownloadSize = PakDownloadMgr.FormatSize(dwLeftDownloadSize)
                            for _, nPackID in pairs(tPackIDList) do
                                local nState, dwTotalSize, dwDownloadedSize = PakDownloadMgr.GetPackState(nPackID)
                                if nState ~= DOWNLOAD_OBJECT_STATE.DOWNLOADED then
                                    nLeftDownloadCount = nLeftDownloadCount + 1
                                end
                            end
                            local szContent = string.format("是否下载[%s]的全部资源？\n剩余%d个，大小%s<color=#ffe26e><font size='20'>\n\n（由于存在重复资源，实际需要下载的大小会偏小）</font></color>", szGroupName, nLeftDownloadCount, szLeftDownloadSize)
                            UIHelper.ShowConfirm(szContent, function()
                                PakDownloadMgr.CheckNetDownload(fnDownload, dwLeftDownloadSize)
                            end, nil, true)
                        else
                            local szContent = string.format("本地已有重复资源，[%s]无需下载，点击确认刷新资源包下载状态", szGroupName)
                            local dialog = UIHelper.ShowConfirm(szContent, function()
                                PakDownloadMgr.RefreshPackListState(self.tPackIDList)
                            end)
                            dialog:HideCancelButton()
                        end
                    end
                end)
            end
        else
            PakSizeQueryMgr.RegQuerySizeCheckNetDownload(self, fnDownload, self.nPackID or self.tPackIDList)
        end
    end
end

function UIWidgetDownload:PausePack()
    if self.nPackID then
        PakDownloadMgr.PausePack(self.nPackID)
    elseif self.tPackIDList then
        PakDownloadMgr.PausePackInPackIDList(self.tPackIDList)
    end
end

function UIWidgetDownload:CheckCanDownload()
    local bCell = self.tConfig and self.tConfig.bCell
    if not bCell then
        return true
    end

    return PakDownloadMgr.CheckCanDownloadClothPack(self, self.nPackID or self.tPackIDList)
end

function UIWidgetDownload:OnComplete()
    self:SetVisible(false)

    -- local bCell = self.tConfig and self.tConfig.bCell
    -- if bCell then
    --     if self.nPackID then
    --         PakDownloadMgr.CancelPack(self.nPackID)
    --     elseif self.tPackIDList then
    --         for _, nPackID in ipairs(self.tPackIDList) do
    --             PakDownloadMgr.CancelPack(nPackID)
    --         end
    --     end
    -- end
end

function UIWidgetDownload:IsDownloading()
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
    elseif self.bBasic then
        bDownloading = PakDownloadMgr.IsBasicDownloading()
    elseif self.bTotal then
        local tTotalInfo = PakDownloadMgr.GetTotalDownloadInfo()
        bDownloading = tTotalInfo.nTotalState ~= TOTAL_DOWNLOAD_STATE.NONE
    end
    return bDownloading
end

-------------------------------- 表现相关 --------------------------------

function UIWidgetDownload:SetVisible(bVisible)
    if Channel.Is_WLColud() then
        bVisible = false
    end

    UIHelper.SetVisible(self._rootNode, bVisible)
    if bVisible then
        self:UpdateAnim()
    else
        self:StopAnim()
    end

    if self.tConfig and self.tConfig.fnOnSetVisible then
        self.tConfig.fnOnSetVisible(bVisible) --刷Layout
    end

    if self.tCompleteHintPackIDList then
        return
    end

    if self.tConfig and self.tConfig.bCell then
        return
    end

    --仅教学用，获取下载按钮
    if bVisible then
        if self.tConfig and self.tConfig.bLong and not g_btnDownloadLong then
            g_btnDownloadLong = self.BtnDownload
        elseif not g_btnDownload then
            g_btnDownload = self.BtnDownload
        end
    else
        if g_btnDownloadLong == self.BtnDownload then
            g_btnDownloadLong = nil
        end
        if g_btnDownload == self.BtnDownload then
            g_btnDownload = nil
        end
    end
end

function UIWidgetDownload:GetVisible()
    return UIHelper.GetVisible(self._rootNode)
end

function UIWidgetDownload:SetDiscard(bDiscard)
    local nBtnState = bDiscard and BTN_STATE.Disable or BTN_STATE.Normal
    UIHelper.SetButtonState(self.BtnDownload, nBtnState)
end

function UIWidgetDownload:UpdateBasicTips(nRoleIndex)
    local bShowTips = self.tConfig and self.tConfig.bShowTips
    if not self.bBasic and not bShowTips then
        self:CloseTips()
        return
    end

    local szContent
    local tTotalInfo = PakDownloadMgr.GetTotalDownloadInfo()
    local nTotalState = tTotalInfo.nTotalState
    local szDownloadSize = PakDownloadMgr.FormatSize(tTotalInfo.dwCurDownloadedSize) .. "/" .. PakDownloadMgr.FormatSize(tTotalInfo.dwCurTotalSize)

    if nTotalState == TOTAL_DOWNLOAD_STATE.DOWNLOADING then
        local dwDownloadSpeed = PakDownloadMgr.GetTotalDownloadSpeed()
        local szDownloadSpeed = PakDownloadMgr.FormatSize(dwDownloadSpeed, 2) .. "/s"
        szContent = "下载中，查看详情\n" .. szDownloadSize .. "（" .. szDownloadSpeed .. "）"
    elseif nTotalState == TOTAL_DOWNLOAD_STATE.PAUSING then
        local nCurTask = tTotalInfo.nTotalTask - tTotalInfo.nCompleteTask
        if nCurTask > 1 then
            szContent = "暂停中，查看详情"
        else
            szContent = "暂停中，查看详情\n" .. szDownloadSize
        end
    elseif nTotalState == TOTAL_DOWNLOAD_STATE.RETRYING then
        if self.nErrorResult then
            if self.nErrorResult == DOWNLOAD_OBJECT_RESULT.NET_ERROR then
                NetworkData.CheckNetworkConnection(nil, function()
                    local nNetMode = App_GetNetMode()
                    self:ShowTips(g_tStrings.tNetError[nNetMode])
                end)
                return
            else
                szContent = g_tStrings.tDownloadFailedCellTip[self.nErrorResult]
            end
        else
            szContent = "重试中，查看详情"
        end
    else
        local nBasicState, _, _ = PakDownloadMgr.GetBasicPackState()
        if nBasicState ~= DOWNLOAD_OBJECT_STATE.DOWNLOADED then
            --基础包未下载完成，核心包未下载完成
            szContent = "需下载基础资源"
        else
            local tBasicPackList = PakDownloadMgr.GetBasicPackIDList()
            local tCorePackIDList = PakDownloadMgr.GetCorePackIDList()

            local moduleRoleList = LoginMgr.GetModule(LoginModule.LOGIN_ROLELIST)
            nRoleIndex = nRoleIndex or moduleRoleList.GetSelRoleIndex()
            local tbRoleInfoList = moduleRoleList.GetRoleInfoList()
            local tRoleInfo = nRoleIndex and tbRoleInfoList and tbRoleInfoList[nRoleIndex]
            local bNeedDownloadCorePack = tRoleInfo and PakDownloadMgr.NeedDownloadCorePack(tRoleInfo.dwMapID, tRoleInfo.dwForceID)
            local tCoreStateInfo = PakDownloadMgr.GetStateInfoByPackIDList(tCorePackIDList)

            local bHasBasicTask = false
            for _, nPackID in ipairs(tBasicPackList or {}) do
                if PakDownloadMgr.GetTask(nPackID) then
                    bHasBasicTask = true
                    break
                end
            end

            if tCoreStateInfo.nState ~= DOWNLOAD_STATE.COMPLETE then
                --基础包下载完成，核心包未下载完成
                if bNeedDownloadCorePack then
                    szContent = "需下载核心资源"
                elseif bHasBasicTask then
                    szContent = "基础资源下载完成，可进入游戏"
                end
            else
                local bHasCoreTask = false
                for _, nPackID in ipairs(tCorePackIDList or {}) do
                    if PakDownloadMgr.GetTask(nPackID) then
                        bHasCoreTask = true
                        break
                    end
                end

                --基础包下载完成，核心包下载完成
                if bNeedDownloadCorePack and bHasCoreTask then
                    szContent = "核心资源下载完成，可进入游戏"
                elseif bHasBasicTask then
                    szContent = "基础资源下载完成，可进入游戏"
                end
            end
        end
    end

    if not string.is_nil(szContent) then
        self:ShowTips(szContent)
    else
        self:CloseTips()
    end
end

function UIWidgetDownload:ShowTips(szContent, nTime)
    UIHelper.SetVisible(self.WidgetDownloadDes, true)
    UIHelper.SetString(self.LabelPop, szContent)

    UIHelper.LayoutDoLayout(self.LayoutDes)

    Timer.DelTimer(self, self.nTipsTimerID)

    if nTime then
        self.nTipsTimerID = Timer.Add(self, nTime, function()
            self:CloseTips()
        end)
    end
end

function UIWidgetDownload:CloseTips(bForce)
    Timer.DelTimer(self, self.nTipsTimerID)
    UIHelper.SetVisible(self.WidgetDownloadDes, false)
end

function UIWidgetDownload:SetProgress(nProgress)
    -- local bCell = self.tConfig and self.tConfig.bCell
    -- local bShowProgress = nProgress > 0 and bCell or false
    local bShowProgress = nProgress > 0
    local bUpdateProgress = (not UIHelper.GetVisible(self.ImgProgress) and bShowProgress) or (self.nProgress and nProgress < self.nProgress)
    if bUpdateProgress then
        --进度条显示或进度倒退时刷新进度
        UIHelper.SetProgressBarPercent(self.ImgProgress, nProgress * 100)
    end
    UIHelper.SetVisible(self.ImgProgress, bShowProgress)

    self.nProgress = nProgress
end

function UIWidgetDownload:UpdateProgress()
    local nRealProgress = (self.nProgress or 0) * 100
    local nCurProgress = UIHelper.GetProgressBarPercent(self.ImgProgress)
    local nTargetProgress = nCurProgress + (nRealProgress - nCurProgress) * 0.3
    if nRealProgress == 100 and nCurProgress < 99 and nTargetProgress >= 99 then
        nTargetProgress = 100
    end
    if nTargetProgress < 0.01 then
        nTargetProgress = 0
    end
    UIHelper.SetProgressBarPercent(self.ImgProgress, nTargetProgress)
end

function UIWidgetDownload:UpdateAnim()
    local bCell = self.tConfig and self.tConfig.bCell
    if not bCell and UIHelper.GetVisible(self.WidgetDownloading) then
        if not self.bDownloadingAnim then
            self.bDownloadingAnim = true
            UIHelper.PlayAni(self, self.WidgetAniDownloading, "AniDownloading")
        end
    else
        self.bDownloadingAnim = false
        UIHelper.StopAni(self, self.WidgetAniDownloading, "AniDownloading")
    end

    if UIHelper.GetVisible(self.WidgetFinished) then
        if not self.bFinishedAnim then
            self.bFinishedAnim = true
            UIHelper.PlayAni(self, self.WidgetAniFinished, "AniFinished")
        end
    else
        self.bFinishedAnim = false
        UIHelper.StopAni(self, self.WidgetAniFinished, "AniFinished")
    end

    if UIHelper.GetVisible(self.WidgetWorldMapFinished) then
        if not self.bWorldMapFinishedAnim then
            self.bWorldMapFinishedAnim = true
            UIHelper.PlayAni(self, self.WidgetAniWorldMapFinished, "AniFinished")
        end
    else
        self.bWorldMapFinishedAnim = false
        UIHelper.StopAni(self, self.WidgetAniWorldMapFinished, "AniFinished")
    end
end

function UIWidgetDownload:StopAnim()
    self.bDownloadingAnim = false
    self.bFinishedAnim = false
    self.bWorldMapFinishedAnim = false
    UIHelper.StopAni(self, self.WidgetAniDownloading, "AniDownloading")
    UIHelper.StopAni(self, self.WidgetAniFinished, "AniFinished")
    UIHelper.StopAni(self, self.WidgetAniWorldMapFinished, "AniFinished")
end

function UIWidgetDownload:SetString(szProgress, szState)
    if not string.is_nil(szProgress) then
        UIHelper.SetVisible(self.LabelPrograss, true)
        UIHelper.SetString(self.LabelPrograss, szProgress)
    else
        UIHelper.SetVisible(self.LabelPrograss, false)
    end

    if not string.is_nil(szState)  then
        UIHelper.SetVisible(self.LabelStatus, true)
        UIHelper.SetString(self.LabelStatus, szState)
    else
        UIHelper.SetVisible(self.LabelStatus, false)
    end
    UIHelper.LayoutDoLayout(self.LayoutHint)
end

return UIWidgetDownload